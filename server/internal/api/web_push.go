package api

import (
	"context"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"

	"multigames/server/internal/i18n"
	"multigames/server/internal/store"

	webpush "github.com/SherClockHolmes/webpush-go"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// PushPayload — JSON в теле Web Push (читает service worker).
type PushPayload struct {
	Title  string `json:"title"`
	Body   string `json:"body"`
	URL    string `json:"url,omitempty"`
	Tag    string `json:"tag,omitempty"`
	Kind   string `json:"kind,omitempty"`
	ChatID string `json:"chat_id,omitempty"` // fallback deep-link на iOS
}

// WebPushSender рассылает уведомления подписчикам.
type WebPushSender struct {
	Pool       *pgxpool.Pool
	PublicKey  string
	PrivateKey string
	Subject    string // email, mailto:email или https://…
	TTLSeconds int
}

func (s *WebPushSender) Enabled() bool {
	return s != nil &&
		s.Pool != nil &&
		strings.TrimSpace(s.PublicKey) != "" &&
		strings.TrimSpace(s.PrivateKey) != ""
}

// normalizeVapidSubscriber готовит claim `sub` для webpush-go.
// Библиотека сама добавляет префикс "mailto:", если значение не https:// —
// поэтому "mailto:a@b.c" превращалось бы в "mailto:mailto:a@b.c", и Apple
// (web.push.apple.com) отвечает 403. Сюда передаём голый email или https URL.
func normalizeVapidSubscriber(raw string) string {
	s := strings.TrimSpace(raw)
	if s == "" {
		return "admin@zozu.games"
	}
	if strings.HasPrefix(strings.ToLower(s), "mailto:") {
		s = strings.TrimSpace(s[len("mailto:"):])
	}
	if s == "" {
		return "admin@zozu.games"
	}
	return s
}

// NotifyUsers шлёт push выбранным пользователям (асинхронно), с учётом категории prefs.
func (s *WebPushSender) NotifyUsers(userIDs []uuid.UUID, category string, payload PushPayload) {
	if !s.Enabled() || len(userIDs) == 0 {
		return
	}
	// Копия среза — вызывающий может переиспользовать буфер.
	ids := append([]uuid.UUID(nil), userIDs...)
	go s.send(ids, category, payload)
}

func (s *WebPushSender) send(userIDs []uuid.UUID, category string, payload PushPayload) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	filtered, err := store.FilterUserIDsForWebPushCategory(ctx, s.Pool, userIDs, category)
	if err != nil {
		log.Printf("web push: filter prefs: %v", err)
		return
	}
	if len(filtered) == 0 {
		return
	}

	subs, err := store.ListWebPushSubscriptionsForUsers(ctx, s.Pool, filtered)
	if err != nil {
		log.Printf("web push: list subscriptions: %v", err)
		return
	}
	if len(subs) == 0 {
		return
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return
	}

	subject := normalizeVapidSubscriber(s.Subject)
	ttl := s.TTLSeconds
	if ttl <= 0 {
		// Короткий TTL (секунды) часто роняет доставку на iOS, если устройство
		// кратко офлайн. Сутки — разумный дефолт для APNs Web Push.
		ttl = 86400
	}

	// Параллельная отправка с лимитом — иначе десятки Apple RTT блокируют
	// goroutine на секунды и под нагрузкой (multi) душат CPU/сеть.
	const maxParallel = 8
	sem := make(chan struct{}, maxParallel)
	var wg sync.WaitGroup
	for _, sub := range subs {
		sub := sub
		wg.Add(1)
		sem <- struct{}{}
		go func() {
			defer wg.Done()
			defer func() { <-sem }()
			subscription := &webpush.Subscription{
				Endpoint: sub.Endpoint,
				Keys: webpush.Keys{
					P256dh: sub.P256dh,
					Auth:   sub.Auth,
				},
			}
			resp, err := webpush.SendNotification(body, subscription, &webpush.Options{
				Subscriber:      subject,
				VAPIDPublicKey:  s.PublicKey,
				VAPIDPrivateKey: s.PrivateKey,
				TTL:             ttl,
				Urgency:         webpush.UrgencyHigh,
			})
			if err != nil {
				log.Printf("web push: send: %v", err)
				return
			}
			status := resp.StatusCode
			respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
			_ = resp.Body.Close()
			apple := strings.Contains(sub.Endpoint, "web.push.apple.com")
			if status == http.StatusGone || status == http.StatusNotFound {
				log.Printf("web push: drop stale subscription %s status=%d apple=%v body=%q",
					sub.ID, status, apple, string(respBody))
				_ = store.DeleteWebPushSubscriptionByID(ctx, s.Pool, sub.ID)
			} else if status < 200 || status >= 300 {
				log.Printf("web push: unexpected status %d for %s apple=%v body=%q",
					status, sub.ID, apple, string(respBody))
			}
		}()
	}
	wg.Wait()
}

// WebPushHandler — HTTP API подписок.
type WebPushHandler struct {
	Pool   *pgxpool.Pool
	Sender *WebPushSender
}

type webPushSubscribeBody struct {
	Endpoint string `json:"endpoint"`
	Keys     struct {
		P256dh string `json:"p256dh"`
		Auth   string `json:"auth"`
	} `json:"keys"`
}

func (h *WebPushHandler) VapidPublicKey(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	if h == nil || h.Sender == nil || !h.Sender.Enabled() {
		writeJSONError(w, r, "web push disabled", http.StatusServiceUnavailable)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]string{
		"public_key": h.Sender.PublicKey,
	})
}

func (h *WebPushHandler) Subscribe(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	if h == nil || h.Sender == nil || !h.Sender.Enabled() {
		writeJSONError(w, r, "web push disabled", http.StatusServiceUnavailable)
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body webPushSubscribeBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	endpoint := strings.TrimSpace(body.Endpoint)
	p256dh := strings.TrimSpace(body.Keys.P256dh)
	auth := strings.TrimSpace(body.Keys.Auth)
	if endpoint == "" || p256dh == "" || auth == "" {
		WriteErr(w, r, http.StatusBadRequest, "endpoint and keys required")
		return
	}
	ua := r.Header.Get("User-Agent")
	if len(ua) > 512 {
		ua = ua[:512]
	}
	if err := store.UpsertWebPushSubscription(r.Context(), h.Pool, userID, endpoint, p256dh, auth, ua); err != nil {
		log.Printf("web push subscribe: %v", err)
		WriteErr(w, r, http.StatusInternalServerError, "failed to save subscription")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"ok":    true,
		"apple": strings.Contains(endpoint, "web.push.apple.com"),
	})
}

func (h *WebPushHandler) Preferences(w http.ResponseWriter, r *http.Request) {
	if h == nil || h.Pool == nil {
		writeJSONError(w, r, "web push disabled", http.StatusServiceUnavailable)
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	switch r.Method {
	case http.MethodGet:
		prefs, err := store.GetWebPushPreferences(r.Context(), h.Pool, userID)
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(prefs)
	case http.MethodPut:
		var body store.WebPushPreferences
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
			return
		}
		if err := store.UpsertWebPushPreferences(r.Context(), h.Pool, userID, body); err != nil {
			log.Printf("web push prefs: %v", err)
			WriteErr(w, r, http.StatusInternalServerError, "failed to save preferences")
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(body)
	default:
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

func (h *WebPushHandler) Unsubscribe(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body struct {
		Endpoint string `json:"endpoint"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	endpoint := strings.TrimSpace(body.Endpoint)
	if endpoint == "" {
		WriteErr(w, r, http.StatusBadRequest, "endpoint required")
		return
	}
	if h.Pool != nil {
		_ = store.DeleteWebPushSubscriptionByEndpoint(r.Context(), h.Pool, userID, endpoint)
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]bool{"ok": true})
}

func writeJSONError(w http.ResponseWriter, r *http.Request, msg string, code int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(map[string]string{"error": i18n.T(i18n.LangFromRequest(r), msg)})
}

func pushUserLabel(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) string {
	if pool == nil {
		return i18n.Content(i18n.LangRU, "common.player")
	}
	u, err := store.GetUserByID(ctx, pool, userID)
	if err != nil || u == nil {
		return i18n.Content(i18n.LangRU, "common.player")
	}
	if u.DisplayName != nil && strings.TrimSpace(*u.DisplayName) != "" {
		return strings.TrimSpace(*u.DisplayName)
	}
	return i18n.Content(i18n.LangRU, "common.player")
}
