package api

import (
	"net/http"

	"multigames/server/internal/i18n"
)

// WriteErr пишет локализованную текстовую ошибку (text/plain), как http.Error.
// key — канонический английский (или legacy) текст; перевод по Accept-Language.
func WriteErr(w http.ResponseWriter, r *http.Request, status int, key string) {
	msg := i18n.T(i18n.LangFromRequest(r), key)
	http.Error(w, msg, status)
}
