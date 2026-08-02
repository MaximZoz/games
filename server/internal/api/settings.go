package api

import (
	"encoding/json"
	"net/http"

	"multigames/server/internal/store"
	"multigames/server/internal/translate"

	"github.com/jackc/pgx/v5/pgxpool"
)

// SettingsHandler — GET/PUT /api/settings.
type SettingsHandler struct {
	Pool *pgxpool.Pool
}

type settingsBody struct {
	MessagesFriendsOnly *bool   `json:"messages_friends_only"`
	PreferredLanguage   *string `json:"preferred_language"`
}

func settingsToJSON(s store.UserSettings) map[string]any {
	return map[string]any{
		"messages_friends_only": s.MessagesFriendsOnly,
		"preferred_language":    s.PreferredLanguage,
	}
}

// ServeHTTP обслуживает GET и PUT настроек текущего пользователя.
func (h *SettingsHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	uid, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	switch r.Method {
	case http.MethodGet:
		s, err := store.GetUserSettings(r.Context(), h.Pool, uid)
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Cache-Control", "no-store, no-cache")
		_ = json.NewEncoder(w).Encode(settingsToJSON(s))
	case http.MethodPut:
		var body settingsBody
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
			return
		}
		if body.MessagesFriendsOnly == nil && body.PreferredLanguage == nil {
			WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
			return
		}
		if body.MessagesFriendsOnly != nil {
			if _, err := store.UpsertMessagesFriendsOnly(r.Context(), h.Pool, uid, *body.MessagesFriendsOnly); err != nil {
				WriteErr(w, r, http.StatusInternalServerError, "server error")
				return
			}
		}
		if body.PreferredLanguage != nil {
			lang := translate.NormalizeLang(*body.PreferredLanguage)
			if lang == "" {
				WriteErr(w, r, http.StatusBadRequest, "invalid language")
				return
			}
			if _, err := store.SetPreferredLanguage(r.Context(), h.Pool, uid, lang); err != nil {
				WriteErr(w, r, http.StatusInternalServerError, "server error")
				return
			}
		}
		s, err := store.GetUserSettings(r.Context(), h.Pool, uid)
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(settingsToJSON(s))
	default:
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

// LanguageSettingsHandler — PUT /api/settings/language.
type LanguageSettingsHandler struct {
	Pool *pgxpool.Pool
}

func (h *LanguageSettingsHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut && r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	uid, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body struct {
		PreferredLanguage string `json:"preferred_language"`
		Language          string `json:"language"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	lang := translate.NormalizeLang(body.PreferredLanguage)
	if lang == "" {
		lang = translate.NormalizeLang(body.Language)
	}
	if lang == "" {
		WriteErr(w, r, http.StatusBadRequest, "invalid language")
		return
	}
	saved, err := store.SetPreferredLanguage(r.Context(), h.Pool, uid, lang)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(settingsToJSON(saved))
}
