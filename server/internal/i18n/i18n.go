package i18n

import (
	"net/http"
	"strings"
)

const (
	LangRU = "ru"
	LangEN = "en"
)

// LangFromRequest читает Accept-Language (или ?lang=) и возвращает ru|en.
func LangFromRequest(r *http.Request) string {
	if r == nil {
		return LangRU
	}
	if q := strings.TrimSpace(r.URL.Query().Get("lang")); q != "" {
		return Normalize(q)
	}
	if al := strings.TrimSpace(r.Header.Get("Accept-Language")); al != "" {
		return Normalize(al)
	}
	return LangRU
}

// Normalize: "ru-RU,ru;q=0.9,en;q=0.8" → ru; иначе en.
func Normalize(raw string) string {
	s := strings.ToLower(strings.TrimSpace(raw))
	if s == "" {
		return LangRU
	}
	first := s
	if i := strings.IndexAny(s, ",;"); i >= 0 {
		first = s[:i]
	}
	first = strings.TrimSpace(first)
	if strings.HasPrefix(first, "ru") {
		return LangRU
	}
	return LangEN
}

// T переводит канонический ключ (обычно английский текст ошибки API).
func T(lang, key string) string {
	key = strings.TrimSpace(key)
	if key == "" {
		return key
	}
	if Normalize(lang) == LangEN {
		if v, ok := messagesEN[key]; ok && v != "" {
			return v
		}
		return key
	}
	if v, ok := messagesRU[key]; ok && v != "" {
		return v
	}
	for _, p := range prefixesRU {
		if strings.HasPrefix(key, p.en) {
			return p.ru + strings.TrimPrefix(key, p.en)
		}
	}
	return key
}
