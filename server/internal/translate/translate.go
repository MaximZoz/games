package translate

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"
	"unicode"
	"unicode/utf8"
)

// Service переводит текст между языками приложения.
// По умолчанию — MyMemory (без ключа); при LIBRETRANSLATE_URL — LibreTranslate.
type Service struct {
	HTTPClient *http.Client
	LibreURL   string

	mu    sync.Mutex
	cache map[string]string
}

func NewService() *Service {
	return &Service{
		HTTPClient: &http.Client{Timeout: 12 * time.Second},
		LibreURL:   strings.TrimSpace(os.Getenv("LIBRETRANSLATE_URL")),
		cache:      make(map[string]string),
	}
}

// NormalizeLang приводит код языка к поддерживаемому (nb←no, zh и т.д.).
func NormalizeLang(code string) string {
	c := strings.ToLower(strings.TrimSpace(code))
	if i := strings.IndexByte(c, '-'); i > 0 {
		c = c[:i]
	}
	switch c {
	case "no", "nn":
		return "nb"
	case "iw":
		return "he"
	case "zh-cn", "zh-tw", "zh-hans", "zh-hant":
		return "zh"
	default:
		return c
	}
}

// ShouldSkip — спец. тела чата (смайлы, подарки, инвайты, монеты).
func ShouldSkip(text string) bool {
	t := strings.TrimSpace(text)
	if t == "" {
		return true
	}
	if strings.HasPrefix(t, "[animated_emoji:") ||
		strings.HasPrefix(t, "[gift_collection:") ||
		strings.HasPrefix(t, "[coins_credit:") {
		return true
	}
	lower := strings.ToLower(t)
	if strings.Contains(lower, "/invite/") || strings.Contains(lower, "invite_lobby") {
		return true
	}
	for _, r := range t {
		if unicode.IsLetter(r) {
			return false
		}
	}
	return true
}

func cacheKey(src, tgt, text string) string {
	return src + "|" + tgt + "|" + text
}

// Translate переводит text из sourceLang в targetLang.
func (s *Service) Translate(ctx context.Context, text, sourceLang, targetLang string) (string, error) {
	src := NormalizeLang(sourceLang)
	tgt := NormalizeLang(targetLang)
	text = strings.TrimSpace(text)
	if text == "" || src == "" || tgt == "" || src == tgt || ShouldSkip(text) {
		return text, nil
	}
	key := cacheKey(src, tgt, text)
	s.mu.Lock()
	if cached, ok := s.cache[key]; ok {
		s.mu.Unlock()
		return cached, nil
	}
	s.mu.Unlock()

	var (
		out string
		err error
	)
	if s.LibreURL != "" {
		out, err = s.translateLibre(ctx, text, src, tgt)
	} else {
		out, err = s.translateMyMemory(ctx, text, src, tgt)
	}
	if err != nil {
		return "", err
	}
	out = strings.TrimSpace(out)
	if out == "" {
		out = text
	}
	s.mu.Lock()
	if len(s.cache) > 4000 {
		s.cache = make(map[string]string)
	}
	s.cache[key] = out
	s.mu.Unlock()
	return out, nil
}

// Item — элемент пакетного перевода.
type Item struct {
	ID   string `json:"id"`
	Text string `json:"text"`
}

// TranslateBatch переводит список; при ошибке одного элемента оставляет оригинал.
func (s *Service) TranslateBatch(ctx context.Context, items []Item, sourceLang, targetLang string) []Item {
	out := make([]Item, len(items))
	for i, it := range items {
		out[i] = Item{ID: it.ID, Text: it.Text}
		tr, err := s.Translate(ctx, it.Text, sourceLang, targetLang)
		if err == nil && tr != "" {
			out[i].Text = tr
		}
	}
	return out
}

func (s *Service) translateMyMemory(ctx context.Context, text, src, tgt string) (string, error) {
	// Free tier: ~500 bytes per request.
	const maxRunes = 450
	if utf8.RuneCountInString(text) > maxRunes {
		var b strings.Builder
		rest := text
		for rest != "" {
			chunk, next := splitRunes(rest, maxRunes)
			rest = next
			part, err := s.myMemoryOnce(ctx, chunk, src, tgt)
			if err != nil {
				return "", err
			}
			b.WriteString(part)
		}
		return b.String(), nil
	}
	return s.myMemoryOnce(ctx, text, src, tgt)
}

func splitRunes(s string, n int) (head, tail string) {
	if utf8.RuneCountInString(s) <= n {
		return s, ""
	}
	i := 0
	for idx := range s {
		if i == n {
			return s[:idx], s[idx:]
		}
		i++
	}
	return s, ""
}

func (s *Service) myMemoryOnce(ctx context.Context, text, src, tgt string) (string, error) {
	u := "https://api.mymemory.translated.net/get?q=" + url.QueryEscape(text) +
		"&langpair=" + url.QueryEscape(src+"|"+tgt)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u, nil)
	if err != nil {
		return "", err
	}
	resp, err := s.HTTPClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return "", err
	}
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("mymemory status %d", resp.StatusCode)
	}
	var parsed struct {
		ResponseData struct {
			TranslatedText string `json:"translatedText"`
		} `json:"responseData"`
		ResponseStatus int `json:"responseStatus"`
	}
	if err := json.Unmarshal(body, &parsed); err != nil {
		return "", err
	}
	if parsed.ResponseStatus != 200 && parsed.ResponseStatus != 0 {
		return "", fmt.Errorf("mymemory response %d", parsed.ResponseStatus)
	}
	tr := parsed.ResponseData.TranslatedText
	// MyMemory иногда возвращает HTML-сущности / MYMEMORY WARNING…
	if strings.Contains(strings.ToUpper(tr), "MYMEMORY WARNING") {
		return "", fmt.Errorf("mymemory quota")
	}
	return tr, nil
}

func (s *Service) translateLibre(ctx context.Context, text, src, tgt string) (string, error) {
	endpoint := strings.TrimRight(s.LibreURL, "/") + "/translate"
	payload := fmt.Sprintf(
		`{"q":%q,"source":%q,"target":%q,"format":"text"}`,
		text, src, tgt,
	)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, strings.NewReader(payload))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := s.HTTPClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return "", err
	}
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("libretranslate status %d", resp.StatusCode)
	}
	var parsed struct {
		TranslatedText string `json:"translatedText"`
	}
	if err := json.Unmarshal(body, &parsed); err != nil {
		return "", err
	}
	return parsed.TranslatedText, nil
}
