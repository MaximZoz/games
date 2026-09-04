package api

import (
	"encoding/json"
	"net/http"
	"strings"

	"multigames/server/internal/store"

	"github.com/jackc/pgx/v5"
)

type UpdateProfileRequest struct {
	DisplayName       *string `json:"display_name"`
	Age               *int    `json:"age"`
	Gender            *string `json:"gender"`
	About             *string `json:"about"`
	AvatarKind        *string `json:"avatar_kind"`
	AvatarValue       *string `json:"avatar_value"`
	ShowStatsToOthers *bool   `json:"show_stats_to_others"`
}

func (h *AuthHandler) UpdateProfile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	var req UpdateProfileRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}

	// Проверяем уникальность display_name если он меняется.
	if req.DisplayName != nil {
		name := strings.TrimSpace(*req.DisplayName)
		req.DisplayName = &name
		if name != "" {
			existing, err := store.GetUserByDisplayName(r.Context(), h.Pool, name)
			if err != nil && err != pgx.ErrNoRows {
				WriteErr(w, r, http.StatusInternalServerError, "server error")
				return
			}
			if err == nil && existing.ID != userID {
				WriteErr(w, r, http.StatusConflict, "login already taken")
				return
			}
		}
	}

	u, err := store.UpdateUserProfile(r.Context(), h.Pool, store.UpdateProfileParams{
		ID:                userID,
		DisplayName:       req.DisplayName,
		Age:               req.Age,
		Gender:            req.Gender,
		About:             req.About,
		AvatarKind:        req.AvatarKind,
		AvatarValue:       req.AvatarValue,
		ShowStatsToOthers: req.ShowStatsToOthers,
	})
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	unlocked, _ := store.EvaluateAndUnlock(r.Context(), h.Pool, userID)
	notifyAchievementUnlocks(h.Hub, h.Push, userID, unlocked)

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"user": userToResponse(u),
	})
}
