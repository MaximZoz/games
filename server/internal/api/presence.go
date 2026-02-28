package api

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"multigames/server/internal/store"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

const maxPresenceUserIDs = 50

type PresenceHandler struct {
	Pool *pgxpool.Pool
	Hub  *RealtimeHub
}

type PresenceUserResponse struct {
	Online     bool   `json:"online"`
	LastSeenAt string `json:"last_seen_at,omitempty"`
}

func (h *PresenceHandler) Get(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	raw := strings.TrimSpace(r.URL.Query().Get("user_ids"))
	if raw == "" {
		http.Error(w, "user_ids query parameter required", http.StatusBadRequest)
		return
	}

	parts := strings.Split(raw, ",")
	if len(parts) > maxPresenceUserIDs {
		http.Error(w, "too many user_ids", http.StatusBadRequest)
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
			http.Error(w, "invalid user_id: "+p, http.StatusBadRequest)
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
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}

	const recentActiveThreshold = 60 * time.Second
	now := time.Now().UTC()
	users := make(map[string]PresenceUserResponse)
	for _, id := range userIDs {
		online := h.Hub != nil && h.Hub.IsUserOnline(id)
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
