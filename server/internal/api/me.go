package api

import (
	"encoding/json"
	"net/http"

	"multigames/server/internal/store"
)

func (h *AuthHandler) Me(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	u, err := store.GetUserByID(r.Context(), h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusNotFound, "user not found")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(userToResponse(u))
}
