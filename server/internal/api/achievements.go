package api

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"multigames/server/internal/store"

	"github.com/jackc/pgx/v5/pgxpool"
)

type AchievementsHandler struct {
	Pool *pgxpool.Pool
}

type claimAchievementBody struct {
	Code string `json:"code"`
}

// GET /api/achievements
func (h *AchievementsHandler) List(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	items, err := store.ListAchievements(r.Context(), h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	out := make([]map[string]any, 0, len(items))
	for _, it := range items {
		m := map[string]any{
			"code":          it.Code,
			"title":         it.Title,
			"description":   it.Description,
			"reward_bronze": it.RewardBronze,
			"progress":      it.Progress,
			"target":        it.Target,
			"status":        it.Status,
		}
		if it.RewardItemCode != "" {
			m["reward_item_code"] = it.RewardItemCode
		}
		if it.UnlockedAt != nil {
			m["unlocked_at"] = it.UnlockedAt.UTC().Format(time.RFC3339)
		}
		if it.ClaimedAt != nil {
			m["claimed_at"] = it.ClaimedAt.UTC().Format(time.RFC3339)
		}
		out = append(out, m)
	}
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store, no-cache")
	_ = json.NewEncoder(w).Encode(map[string]any{"achievements": out})
}

// GET /api/achievements/unclaimed-count
func (h *AchievementsHandler) UnclaimedCount(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	n, err := store.CountUnclaimedAchievements(r.Context(), h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store, no-cache")
	_ = json.NewEncoder(w).Encode(map[string]int{"count": n})
}

// POST /api/achievements/claim  {"code":"..."}
func (h *AchievementsHandler) Claim(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body claimAchievementBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	code := strings.TrimSpace(body.Code)
	if code == "" {
		WriteErr(w, r, http.StatusBadRequest, "code required")
		return
	}
	result, err := store.ClaimAchievement(r.Context(), h.Pool, userID, code)
	if err != nil {
		switch err {
		case store.ErrAchievementUnknown:
			WriteErr(w, r, http.StatusBadRequest, "unknown achievement")
		case store.ErrAchievementNotUnlocked:
			WriteErr(w, r, http.StatusConflict, "not unlocked")
		case store.ErrAchievementAlreadyClaimed:
			WriteErr(w, r, http.StatusConflict, "already claimed")
		default:
			WriteErr(w, r, http.StatusInternalServerError, "server error")
		}
		return
	}
	w.Header().Set("Content-Type", "application/json")
	resp := map[string]any{
		"balance_bronze": result.BalanceBronze,
		"reward_bronze":  result.RewardBronze,
		"code":           result.Code,
	}
	if result.RewardItemCode != "" {
		resp["reward_item_code"] = result.RewardItemCode
	}
	_ = json.NewEncoder(w).Encode(resp)
}
