package api

import (
	"encoding/json"
	"net/http"
	"strings"
	"sync"
	"time"

	"multigames/server/internal/auth"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

type RealtimeHub struct {
	mu      sync.RWMutex
	clients map[uuid.UUID]map[*websocket.Conn]struct{}
}

func NewRealtimeHub() *RealtimeHub {
	return &RealtimeHub{
		clients: make(map[uuid.UUID]map[*websocket.Conn]struct{}),
	}
}

func (h *RealtimeHub) Register(userID uuid.UUID, conn *websocket.Conn) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if h.clients[userID] == nil {
		h.clients[userID] = make(map[*websocket.Conn]struct{})
	}
	h.clients[userID][conn] = struct{}{}
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

func (h *RealtimeHub) PublishToUsers(userIDs []uuid.UUID, payload any) {
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
		conn   *websocket.Conn
	}

	deliveries := make([]delivery, 0, 8)
	h.mu.RLock()
	for userID := range uniqueUsers {
		for conn := range h.clients[userID] {
			deliveries = append(deliveries, delivery{
				userID: userID,
				conn:   conn,
			})
		}
	}
	h.mu.RUnlock()

	for _, target := range deliveries {
		_ = target.conn.SetWriteDeadline(time.Now().Add(4 * time.Second))
		if err := target.conn.WriteMessage(websocket.TextMessage, raw); err != nil {
			_ = target.conn.Close()
			h.Unregister(target.userID, target.conn)
		}
	}
}

type RealtimeWSHandler struct {
	Hub       *RealtimeHub
	JWTSecret []byte
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
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	if h.Hub == nil {
		http.Error(w, "realtime hub is not initialized", http.StatusInternalServerError)
		return
	}

	token := wsAccessTokenFromRequest(r)
	if token == "" {
		http.Error(w, "missing access_token", http.StatusUnauthorized)
		return
	}
	claims, err := auth.ParseJWT(h.JWTSecret, token)
	if err != nil {
		http.Error(w, "invalid or expired token", http.StatusUnauthorized)
		return
	}
	userID, err := uuid.Parse(claims.UserID)
	if err != nil {
		http.Error(w, "invalid token", http.StatusUnauthorized)
		return
	}

	conn, err := wsUpgrader.Upgrade(w, r, nil)
	if err != nil {
		return
	}

	h.Hub.Register(userID, conn)
	defer func() {
		h.Hub.Unregister(userID, conn)
		_ = conn.Close()
	}()

	const readTimeout = 70 * time.Second
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
			if err := conn.WriteControl(
				websocket.PingMessage,
				[]byte("ping"),
				time.Now().Add(5*time.Second),
			); err != nil {
				return
			}
		}
	}
}
