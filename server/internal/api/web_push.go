package api

import (
	"context"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"strings"
	"time"

	"multigames/server/internal/store"

	webpush "github.com/SherClockHolmes/webpush-go"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// PushPayload — JSON в теле Web Push (читает service worker).
type PushPayload struct {
	Title string `json:"title"`
	Body  string `json:"body"`
	URL   string `json:"url,omitempty"`
	Tag   string `json:"tag,omitempty"`
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

// NotifyUsers шлёт push выбранным пользователям (асинхронно).
func (s *WebPushSender) NotifyUsers(userIDs []uuid.UUID, payload PushPayload) {
	if !s.Enabled() || len(userIDs) == 0 {
		return
	}
	// Копия среза — вызывающий может переиспользовать буфер.
	ids := append([]uuid.UUID(nil), userIDs...)
	go s.send(ids, payload)
}

func (s *WebPushSender) send(userIDs []uuid.UUID, payload PushPayload) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	subs, err := store.ListWebPushSubscriptionsForUsers(ctx, s.Pool, userIDs)
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

	for _, sub := range subs {
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
			continue
		}
		status := resp.StatusCode
		respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		_ = resp.Body.Close()
		apple := strings.Contains(sub.Endpoint, "web.push.apple.com")
		// Протухшая подписка — удаляем.
		if status == http.StatusGone || status == http.StatusNotFound {
			log.Printf("web push: drop stale subscription %s status=%d apple=%v body=%q",
				sub.ID, status, apple, string(respBody))
			_ = store.DeleteWebPushSubscriptionByID(ctx, s.Pool, sub.ID)
		} else if status < 200 || status >= 300 {
			log.Printf("web push: unexpected status %d for %s apple=%v body=%q",
				status, sub.ID, apple, string(respBody))
		} else if apple {
			log.Printf("web push: apple ok status=%d sub=%s", status, sub.ID)
		}
	}
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
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	if h == nil || h.Sender == nil || !h.Sender.Enabled() {
		writeJSONError(w, "web push disabled", http.StatusServiceUnavailable)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]string{
		"public_key": h.Sender.PublicKey,
	})
}

func (h *WebPushHandler) Subscribe(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	if h == nil || h.Sender == nil || !h.Sender.Enabled() {
		writeJSONError(w, "web push disabled", http.StatusServiceUnavailable)
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	var body webPushSubscribeBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	endpoint := strings.TrimSpace(body.Endpoint)
	p256dh := strings.TrimSpace(body.Keys.P256dh)
	auth := strings.TrimSpace(body.Keys.Auth)
	if endpoint == "" || p256dh == "" || auth == "" {
		http.Error(w, "endpoint and keys required", http.StatusBadRequest)
		return
	}
	ua := r.Header.Get("User-Agent")
	if len(ua) > 512 {
		ua = ua[:512]
	}
	if err := store.UpsertWebPushSubscription(r.Context(), h.Pool, userID, endpoint, p256dh, auth, ua); err != nil {
		log.Printf("web push subscribe: %v", err)
		http.Error(w, "failed to save subscription", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"ok":    true,
		"apple": strings.Contains(endpoint, "web.push.apple.com"),
	})
}

func (h *WebPushHandler) Unsubscribe(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := currentUserIDFromContext(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	var body struct {
		Endpoint string `json:"endpoint"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	endpoint := strings.TrimSpace(body.Endpoint)
	if endpoint == "" {
		http.Error(w, "endpoint required", http.StatusBadRequest)
		return
	}
	if h.Pool != nil {
		_ = store.DeleteWebPushSubscriptionByEndpoint(r.Context(), h.Pool, userID, endpoint)
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]bool{"ok": true})
}

func writeJSONError(w http.ResponseWriter, msg string, code int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(map[string]string{"error": msg})
}

func pushUserLabel(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) string {
	if pool == nil {
		return "Игрок"
	}
	u, err := store.GetUserByID(ctx, pool, userID)
	if err != nil || u == nil {
		return "Игрок"
	}
	if u.DisplayName != nil && strings.TrimSpace(*u.DisplayName) != "" {
		return strings.TrimSpace(*u.DisplayName)
	}
	return "Игрок"
}
