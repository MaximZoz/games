package api

import (
	"encoding/json"
	"net/http"
	"strings"

	"multigames/server/internal/store"

	"github.com/jackc/pgx/v5"
)

type UpdateProfileRequest struct {
	DisplayName *string `json:"display_name"`
	Age         *int    `json:"age"`
	Gender      *string `json:"gender"`
	About       *string `json:"about"`
	AvatarKind  *string `json:"avatar_kind"`
	AvatarValue *string `json:"avatar_value"`
}

func (h *AuthHandler) UpdateProfile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID, ok := GetUserID(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var req UpdateProfileRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	// Проверяем уникальность display_name если он меняется.
	if req.DisplayName != nil {
		name := strings.TrimSpace(*req.DisplayName)
		req.DisplayName = &name
		if name != "" {
			existing, err := store.GetUserByDisplayName(r.Context(), h.Pool, name)
			if err != nil && err != pgx.ErrNoRows {
				http.Error(w, "server error", http.StatusInternalServerError)
				return
			}
			if err == nil && existing.ID != userID {
				http.Error(w, "Такой логин уже занят", http.StatusConflict)
				return
			}
		}
	}

	u, err := store.UpdateUserProfile(r.Context(), h.Pool, store.UpdateProfileParams{
		ID:          userID,
		DisplayName: req.DisplayName,
		Age:         req.Age,
		Gender:      req.Gender,
		About:       req.About,
		AvatarKind:  req.AvatarKind,
		AvatarValue: req.AvatarValue,
	})
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	_ = store.EvaluateAndUnlock(r.Context(), h.Pool, userID)

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"user": userToResponse(u),
	})
}
