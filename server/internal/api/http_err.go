package api

import (
	"encoding/json"
	"net/http"

	"multigames/server/internal/i18n"
)

// WriteErr пишет JSON-ошибку: {"error":"<канонический ключ>","message":"<локаль>"}.
// Клиент может надёжно проверить error, не завися от перевода message.
func WriteErr(w http.ResponseWriter, r *http.Request, status int, key string) {
	msg := i18n.T(i18n.LangFromRequest(r), key)
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(map[string]string{
		"error":   key,
		"message": msg,
	})
}
