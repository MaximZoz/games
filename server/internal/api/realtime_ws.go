package api

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"multigames/server/internal/applog"
	"multigames/server/internal/auth"
	"multigames/server/internal/i18n"
	"multigames/server/internal/store"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

// realtimeFanout публикует событие на другие инстансы.
// true — доставка локальным сокетам будет из подписчика Redis (эхо включено).
type realtimeFanout func(userIDs []uuid.UUID, all bool, payload any) bool

type RealtimeHub struct {
	mu      sync.RWMutex
	clients map[uuid.UUID]map[*websocket.Conn]*realtimeClient
	fanout  realtimeFanout
}

type realtimeClient struct {
	conn    *websocket.Conn
	writeMu sync.Mutex
}

func (c *realtimeClient) writeText(raw []byte) error {
	c.writeMu.Lock()
	defer c.writeMu.Unlock()

	_ = c.conn.SetWriteDeadline(time.Now().Add(4 * time.Second))
	return c.conn.WriteMessage(websocket.TextMessage, raw)
}

func (c *realtimeClient) writePing() error {
	c.writeMu.Lock()
	defer c.writeMu.Unlock()

	return c.conn.WriteControl(
		websocket.PingMessage,
		[]byte("ping"),
		time.Now().Add(5*time.Second),
	)
}

func NewRealtimeHub() *RealtimeHub {
	return &RealtimeHub{
		clients: make(map[uuid.UUID]map[*websocket.Conn]*realtimeClient),
	}
}

// SetFanout включает рассылку чатов, друзей и presence на все реплики.
func (h *RealtimeHub) SetFanout(fn realtimeFanout) {
	if h == nil {
		return
	}
	h.mu.Lock()
	h.fanout = fn
	h.mu.Unlock()
}

func (h *RealtimeHub) fanoutOK(userIDs []uuid.UUID, all bool, payload any) bool {
	if h == nil {
		return false
	}
	h.mu.RLock()
	fn := h.fanout
	h.mu.RUnlock()
	if fn == nil {
		return false
	}
	return fn(userIDs, all, payload)
}

func (h *RealtimeHub) Register(userID uuid.UUID, conn *websocket.Conn) *realtimeClient {
	h.mu.Lock()
	defer h.mu.Unlock()

	if h.clients[userID] == nil {
		h.clients[userID] = make(map[*websocket.Conn]*realtimeClient)
	}
	client := &realtimeClient{conn: conn}
	h.clients[userID][conn] = client
	return client
}

func (h *RealtimeHub) Unregister(userID uuid.UUID, conn *websocket.Conn) {
	h.mu.Lock()
	defer h.mu.Unlock()

	connections, ok := h.clients[userID]
	if !ok {
		return
	}
	delete(connections, conn)
	if len(connections) == 0 {
		delete(h.clients, userID)
	}
}

// IsUserOnline returns true if the user has at least one active WebSocket connection.
func (h *RealtimeHub) IsUserOnline(userID uuid.UUID) bool {
	h.mu.RLock()
	defer h.mu.RUnlock()
	conns, ok := h.clients[userID]
	return ok && len(conns) > 0
}

// DisconnectUser шлёт payload (если задан) и закрывает все WS пользователя.
func (h *RealtimeHub) DisconnectUser(userID uuid.UUID, payload any) {
	if h == nil {
		return
	}
	var raw []byte
	if payload != nil {
		raw, _ = json.Marshal(payload)
	}

	h.mu.Lock()
	conns := h.clients[userID]
	delete(h.clients, userID)
	h.mu.Unlock()

	for _, client := range conns {
		if len(raw) > 0 {
			_ = client.writeText(raw)
		}
		_ = client.conn.Close()
	}
}

// ConnectedUserIDs — id всех пользователей с активным WS на этом инстансе.
func (h *RealtimeHub) ConnectedUserIDs() []uuid.UUID {
	if h == nil {
		return nil
	}
	h.mu.RLock()
	defer h.mu.RUnlock()
	ids := make([]uuid.UUID, 0, len(h.clients))
	for id := range h.clients {
		ids = append(ids, id)
	}
	return ids
}

// PublishToAll — всем онлайн-клиентам. С fanout — на каждой реплике.
func (h *RealtimeHub) PublishToAll(payload any) {
	if h == nil {
		return
	}
	if h.fanoutOK(nil, true, payload) {
		return
	}
	h.DeliverLocalAll(payload)
}

// DeliverLocalAll пишет payload только сокетам этого процесса.
func (h *RealtimeHub) DeliverLocalAll(payload any) {
	if h == nil {
		return
	}
	h.DeliverLocal(h.ConnectedUserIDs(), payload)
}

func (h *RealtimeHub) PublishToUsers(userIDs []uuid.UUID, payload any) {
	if h == nil || len(userIDs) == 0 {
		return
	}
	if h.fanoutOK(userIDs, false, payload) {
		return
	}
	h.DeliverLocal(userIDs, payload)
}

// DeliverLocal пишет payload сокетам этого процесса, без Redis.
func (h *RealtimeHub) DeliverLocal(userIDs []uuid.UUID, payload any) {
	if h == nil || len(userIDs) == 0 {
		return
	}

	raw, err := json.Marshal(payload)
	if err != nil {
		return
	}

	uniqueUsers := make(map[uuid.UUID]struct{}, len(userIDs))
	for _, id := range userIDs {
		uniqueUsers[id] = struct{}{}
	}

	type delivery struct {
		userID uuid.UUID
		client *realtimeClient
	}

	deliveries := make([]delivery, 0, 8)
	h.mu.RLock()
	for userID := range uniqueUsers {
		for _, client := range h.clients[userID] {
			deliveries = append(deliveries, delivery{
				userID: userID,
				client: client,
			})
		}
	}
	h.mu.RUnlock()

	for _, target := range deliveries {
		if target.client == nil {
			continue
		}
		if err := target.client.writeText(raw); err != nil {
			_ = target.client.conn.Close()
			h.Unregister(target.userID, target.client.conn)
		}
	}
}

type RealtimeWSHandler struct {
	Hub           *RealtimeHub
	Pool          *pgxpool.Pool
	Rdb           *redis.Client
	JWTSecret     []byte
	LogWriter     *applog.FileWriter // файл (для импорта)
	AppLogEnabled bool               // если true — presence пишем ещё и напрямую в БД
	Push          *WebPushSender
	Limiter       *RateLimiter
}

var wsUpgrader = websocket.Upgrader{
	CheckOrigin: func(_ *http.Request) bool { return true },
}

func wsAccessTokenFromRequest(r *http.Request) string {
	if token := strings.TrimSpace(r.URL.Query().Get("access_token")); token != "" {
		return token
	}
	header := strings.TrimSpace(r.Header.Get("Authorization"))
	if header == "" {
		return ""
	}
	parts := strings.SplitN(header, " ", 2)
	if len(parts) != 2 || parts[0] != "Bearer" {
		return ""
	}
	return strings.TrimSpace(parts[1])
}

func (h *RealtimeWSHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	if h.Hub == nil {
		WriteErr(w, r, http.StatusInternalServerError, "realtime hub is not initialized")
		return
	}
	if h.Limiter != nil {
		ip := clientIP(r)
		if ip == "" {
			ip = "unknown"
		}
		ok, retry := h.Limiter.Allow(r.Context(), "ws:"+ip, RateWSConnectPerMinute, time.Minute)
		if !ok {
			sec := int(retry.Seconds())
			if sec < 1 {
				sec = 1
			}
			w.Header().Set("Retry-After", strconv.Itoa(sec))
			WriteErr(w, r, http.StatusTooManyRequests, "too many requests")
			return
		}
	}

	token := wsAccessTokenFromRequest(r)
	if token == "" {
		WriteErr(w, r, http.StatusUnauthorized, "missing access_token")
		return
	}
	claims, err := auth.ParseJWT(h.JWTSecret, token)
	if err != nil {
		WriteErr(w, r, http.StatusUnauthorized, "invalid or expired token")
		return
	}
	userID, err := uuid.Parse(claims.UserID)
	if err != nil {
		WriteErr(w, r, http.StatusUnauthorized, "invalid token")
		return
	}
	if h.Pool != nil {
		sid, sidErr := uuid.Parse(strings.TrimSpace(claims.SessionID))
		if sidErr != nil {
			WriteErr(w, r, http.StatusUnauthorized, "invalid or expired token")
			return
		}
		ok, existsErr := store.SessionExists(r.Context(), h.Pool, sid)
		if existsErr != nil {
			log.Printf("realtime: SessionExists failed: %v", existsErr)
			WriteErr(w, r, http.StatusServiceUnavailable, "temporarily unavailable")
			return
		}
		if !ok {
			if rejectIfFrozen(w, r, h.Pool, userID) {
				return
			}
			WriteErr(w, r, http.StatusUnauthorized, "invalid or expired token")
			return
		}
		if rejectIfFrozen(w, r, h.Pool, userID) {
			return
		}
	}

	conn, err := wsUpgrader.Upgrade(w, r, nil)
	if err != nil {
		return
	}

	client := h.Hub.Register(userID, conn)
	h.Hub.MarkOnline(r.Context(), h.Rdb, userID)
	log.Printf("realtime: user %s connected", userID)

	// Update last_seen and notify presence on connect
	if h.Pool != nil {
		ctx := r.Context()
		// Клиент снова онлайн — недоставленные входящие считаем доставленными.
		syncIncomingDelivered(ctx, h.Pool, h.Hub, userID)
		_ = store.UpdateUserLastSeen(ctx, h.Pool, userID)
		now := time.Now().UTC().Format(time.RFC3339Nano)
		recipients, recErr := store.GetPresenceRecipientsForUser(ctx, h.Pool, userID)
		if recErr == nil && len(recipients) > 0 {
			h.Hub.PublishToUsers(recipients, map[string]any{
				"type":         "user_online",
				"user_id":      userID.String(),
				"online":       true,
				"last_seen_at": now,
			})
		}
		if available, err := store.CanClaimDailyReward(ctx, h.Pool, userID); err == nil {
			h.Hub.PublishToUsers([]uuid.UUID{userID}, map[string]any{
				"type":      "daily_reward_available",
				"available": available,
			})
			if available && h.Push != nil {
				if ok, markErr := store.TryMarkDailyRewardPush(ctx, h.Pool, userID); markErr == nil && ok {
					lang := i18n.LangRU
					h.Push.NotifyUsers([]uuid.UUID{userID}, store.WebPushCategoryRewards, PushPayload{
						Title: i18n.Content(lang, "push.daily_reward_title"),
						Body:  i18n.Content(lang, "push.daily_reward_body"),
						URL:   "/coins/login",
						Tag:   "daily_reward",
					})
				}
			}
		}
		if h.LogWriter != nil {
			meta := map[string]interface{}{
				"recipients_count": len(recipients),
				"last_seen_at":     now,
			}
			if recErr == nil && len(recipients) > 0 {
				ids := make([]string, 0, len(recipients))
				for _, r := range recipients {
					ids = append(ids, r.String())
				}
				meta["recipient_ids"] = ids
			} else if recErr != nil {
				meta["error"] = recErr.Error()
			}
			_ = h.LogWriter.Append(applog.Event{
				Source:     "backend",
				MethodName: "realtime.presence_online",
				UserID:     userID.String(),
				Level:      "info",
				Message:    "user connected, user_online sent to " + strconv.Itoa(len(recipients)) + " recipients",
				Metadata:   meta,
			})
		}
		if h.AppLogEnabled && h.Pool != nil {
			meta := map[string]interface{}{
				"recipients_count": len(recipients),
				"last_seen_at":     now,
			}
			if recErr == nil && len(recipients) > 0 {
				ids := make([]string, 0, len(recipients))
				for _, r := range recipients {
					ids = append(ids, r.String())
				}
				meta["recipient_ids"] = ids
			}
			uid := userID
			pool := h.Pool
			msg := "user connected, user_online sent to " + strconv.Itoa(len(recipients)) + " recipients"
			go func() {
				_ = store.InsertAppLog(context.Background(), pool, store.InsertAppLogParams{
					Source:     "backend",
					MethodName: "realtime.presence_online",
					UserID:     &uid,
					Level:      "info",
					Message:    msg,
					Metadata:   meta,
				})
			}()
		}
	}

	defer func() {
		log.Printf("realtime: user %s disconnected", userID)
		// Update last_seen and notify presence on disconnect
		if h.Pool != nil {
			ctx := context.Background()
			_ = store.UpdateUserLastSeen(ctx, h.Pool, userID)
			now := time.Now().UTC().Format(time.RFC3339Nano)
			recipients, recErr := store.GetPresenceRecipientsForUser(ctx, h.Pool, userID)
			if recErr == nil && len(recipients) > 0 {
				h.Hub.PublishToUsers(recipients, map[string]any{
					"type":         "user_offline",
					"user_id":      userID.String(),
					"online":       false,
					"last_seen_at": now,
				})
			}
			if h.LogWriter != nil {
				meta := map[string]interface{}{
					"recipients_count": len(recipients),
					"last_seen_at":     now,
				}
				if recErr == nil && len(recipients) > 0 {
					ids := make([]string, 0, len(recipients))
					for _, r := range recipients {
						ids = append(ids, r.String())
					}
					meta["recipient_ids"] = ids
				} else if recErr != nil {
					meta["error"] = recErr.Error()
				}
				_ = h.LogWriter.Append(applog.Event{
					Source:     "backend",
					MethodName: "realtime.presence_offline",
					UserID:     userID.String(),
					Level:      "info",
					Message:    "user disconnected, user_offline sent to " + strconv.Itoa(len(recipients)) + " recipients",
					Metadata:   meta,
				})
			}
			if h.AppLogEnabled && h.Pool != nil {
				meta := map[string]interface{}{
					"recipients_count": len(recipients),
					"last_seen_at":     now,
				}
				if recErr == nil && len(recipients) > 0 {
					ids := make([]string, 0, len(recipients))
					for _, r := range recipients {
						ids = append(ids, r.String())
					}
					meta["recipient_ids"] = ids
				}
				uid := userID
				pool := h.Pool
				msg := "user disconnected, user_offline sent to " + strconv.Itoa(len(recipients)) + " recipients"
				go func() {
					_ = store.InsertAppLog(context.Background(), pool, store.InsertAppLogParams{
						Source:     "backend",
						MethodName: "realtime.presence_offline",
						UserID:     &uid,
						Level:      "info",
						Message:    msg,
						Metadata:   meta,
					})
				}()
			}
		}
		h.Hub.Unregister(userID, conn)
		h.Hub.MarkOffline(context.Background(), h.Rdb, userID)
		_ = conn.Close()
	}()

	const readTimeout = 60 * time.Second // Неактивен 1 мин → disconnect → user_offline друзьям и чатам
	const pingInterval = 30 * time.Second

	conn.SetReadLimit(4096)
	_ = conn.SetReadDeadline(time.Now().Add(readTimeout))
	conn.SetPongHandler(func(string) error {
		return conn.SetReadDeadline(time.Now().Add(readTimeout))
	})

	done := make(chan struct{})
	go func() {
		defer close(done)
		for {
			if _, _, err := conn.ReadMessage(); err != nil {
				return
			}
		}
	}()

	ticker := time.NewTicker(pingInterval)
	defer ticker.Stop()

	for {
		select {
		case <-done:
			return
		case <-ticker.C:
			if client != nil {
				if err := client.writePing(); err != nil {
					return
				}
				h.Hub.RefreshOnline(context.Background(), h.Rdb, userID)
				continue
			}
			if err := conn.WriteControl(websocket.PingMessage, []byte("ping"), time.Now().Add(5*time.Second)); err != nil {
				return
			}
		}
	}
}
