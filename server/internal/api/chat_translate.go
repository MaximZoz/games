package api

import (
	"encoding/json"
	"net/http"
	"strings"

	"multigames/server/internal/store"
	"multigames/server/internal/translate"

	"github.com/jackc/pgx/v5/pgxpool"
)

// ChatTranslateHandler — POST /api/chats/translate.
type ChatTranslateHandler struct {
	Pool      *pgxpool.Pool
	Translate *translate.Service
}

type chatTranslateRequest struct {
	Items      []translate.Item `json:"items"`
	TargetLang string           `json:"target_lang"`
	SourceLang string           `json:"source_lang"`
	ChatID     string           `json:"chat_id"`
}

type chatTranslateResponse struct {
	Items []translate.Item `json:"items"`
}

func (h *ChatTranslateHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	uid, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	if h.Translate == nil {
		WriteErr(w, r, http.StatusServiceUnavailable, "translate unavailable")
		return
	}
	var body chatTranslateRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	target := translate.NormalizeLang(body.TargetLang)
	if target == "" {
		// fallback: язык текущего пользователя из настроек
		if s, err := store.GetUserSettings(r.Context(), h.Pool, uid); err == nil {
			target = translate.NormalizeLang(s.PreferredLanguage)
		}
	}
	if target == "" {
		WriteErr(w, r, http.StatusBadRequest, "invalid language")
		return
	}
	source := translate.NormalizeLang(body.SourceLang)
	if len(body.Items) == 0 {
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(chatTranslateResponse{Items: []translate.Item{}})
		return
	}
	if len(body.Items) > 80 {
		WriteErr(w, r, http.StatusBadRequest, "too many items")
		return
	}
	// Ограничиваем размер текста.
	trimmed := make([]translate.Item, 0, len(body.Items))
	for _, it := range body.Items {
		text := strings.TrimSpace(it.Text)
		if text == "" {
			continue
		}
		if len(text) > 2000 {
			text = text[:2000]
		}
		trimmed = append(trimmed, translate.Item{ID: it.ID, Text: text})
	}
	_ = uid
	out := make([]translate.Item, 0, len(trimmed))
	for _, it := range trimmed {
		src := source
		tr, err := h.Translate.Translate(r.Context(), it.Text, src, target)
		if err != nil || strings.TrimSpace(tr) == "" {
			tr = it.Text
		}
		out = append(out, translate.Item{ID: it.ID, Text: tr})
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(chatTranslateResponse{Items: out})
}
