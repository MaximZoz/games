package api

import (
	"encoding/json"
	"net/http"

	"multigames/server/internal/store"

	"github.com/jackc/pgx/v5/pgxpool"
)

// SettingsHandler — GET/PUT /api/settings.
type SettingsHandler struct {
	Pool *pgxpool.Pool
}

type settingsBody struct {
	MessagesFriendsOnly bool `json:"messages_friends_only"`
}

func settingsToJSON(s store.UserSettings) map[string]any {
	return map[string]any{
		"messages_friends_only": s.MessagesFriendsOnly,
	}
}

// ServeHTTP обслуживает GET и PUT настроек текущего пользователя.
func (h *SettingsHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	uid, ok := GetUserID(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	switch r.Method {
	case http.MethodGet:
		s, err := store.GetUserSettings(r.Context(), h.Pool, uid)
		if err != nil {
			http.Error(w, "server error", http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Cache-Control", "no-store, no-cache")
		_ = json.NewEncoder(w).Encode(settingsToJSON(s))
	case http.MethodPut:
		var body settingsBody
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			http.Error(w, "invalid JSON", http.StatusBadRequest)
			return
		}
		saved, err := store.UpsertUserSettings(r.Context(), h.Pool, uid, store.UserSettings{
			MessagesFriendsOnly: body.MessagesFriendsOnly,
		})
		if err != nil {
			http.Error(w, "server error", http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(settingsToJSON(saved))
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}
