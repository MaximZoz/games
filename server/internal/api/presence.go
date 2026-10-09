package api

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"strings"
	"time"

	"multigames/server/internal/store"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

const maxPresenceUserIDs = 50

type PresenceHandler struct {
	Pool *pgxpool.Pool
	Hub  *RealtimeHub
	Rdb  *redis.Client
}

const presenceTTL = 90 * time.Second

func presenceRedisKey(id uuid.UUID) string {
	return "presence:" + id.String()
}

// MarkOnline увеличивает счётчик соединений. Ключ общий для всех реплик.
func (h *RealtimeHub) MarkOnline(ctx context.Context, rdb *redis.Client, userID uuid.UUID) {
	if rdb == nil {
		return
	}
	key := presenceRedisKey(userID)
	if err := rdb.Incr(ctx, key).Err(); err != nil {
		log.Printf("presence incr: %v", err)
		return
	}
	_ = rdb.Expire(ctx, key, presenceTTL).Err()
}

// MarkOffline уменьшает счётчик. Ноль — пользователь ни на одной машине.
func (h *RealtimeHub) MarkOffline(ctx context.Context, rdb *redis.Client, userID uuid.UUID) {
	if rdb == nil {
		return
	}
	key := presenceRedisKey(userID)
	n, err := rdb.Decr(ctx, key).Result()
	if err != nil {
		return
	}
	if n <= 0 {
		_ = rdb.Del(ctx, key).Err()
	}
}

// RefreshOnline продлевает онлайн, пока сокет жив (пинг раз в 30 с).
func (h *RealtimeHub) RefreshOnline(ctx context.Context, rdb *redis.Client, userID uuid.UUID) {
	if h == nil || rdb == nil {
		return
	}
	_ = rdb.Expire(ctx, presenceRedisKey(userID), presenceTTL).Err()
}

// IsUserOnlineAnywhere — локальный сокет или ключ presence в Redis.
func (h *RealtimeHub) IsUserOnlineAnywhere(ctx context.Context, rdb *redis.Client, userID uuid.UUID) bool {
	if h != nil && h.IsUserOnline(userID) {
		return true
	}
	if rdb == nil {
		return false
	}
	n, err := rdb.Exists(ctx, presenceRedisKey(userID)).Result()
	return err == nil && n > 0
}

type PresenceUserResponse struct {
	Online     bool   `json:"online"`
	LastSeenAt string `json:"last_seen_at,omitempty"`
}

func (h *PresenceHandler) Get(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	raw := strings.TrimSpace(r.URL.Query().Get("user_ids"))
	if raw == "" {
		WriteErr(w, r, http.StatusBadRequest, "user_ids query parameter required")
		return
	}

	parts := strings.Split(raw, ",")
	if len(parts) > maxPresenceUserIDs {
		WriteErr(w, r, http.StatusBadRequest, "too many user_ids")
		return
	}

	var userIDs []uuid.UUID
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p == "" {
			continue
		}
		id, err := uuid.Parse(p)
		if err != nil {
			WriteErr(w, r, http.StatusBadRequest, "invalid user_id: "+p)
			return
		}
		userIDs = append(userIDs, id)
	}

	if len(userIDs) == 0 {
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{"users": map[string]PresenceUserResponse{}})
		return
	}

	lastSeen, err := store.GetLastSeenForUsers(r.Context(), h.Pool, userIDs)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	const recentActiveThreshold = 60 * time.Second
	now := time.Now().UTC()
	users := make(map[string]PresenceUserResponse)
	for _, id := range userIDs {
		online := h.Hub != nil && h.Hub.IsUserOnlineAnywhere(r.Context(), h.Rdb, id)
		if !online && lastSeen[id] != nil {
			// Считаем онлайн, если last_seen < 60 сек (activity от HTTP, WebSocket в фоне и т.п.)
			online = now.Sub(lastSeen[id].UTC()) < recentActiveThreshold
		}
		entry := PresenceUserResponse{Online: online}
		if t := lastSeen[id]; t != nil {
			entry.LastSeenAt = t.UTC().Format(time.RFC3339Nano)
		}
		users[id.String()] = entry
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"users": users})
}
