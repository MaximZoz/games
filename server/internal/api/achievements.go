package api

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"multigames/server/internal/i18n"
	"multigames/server/internal/store"

	"github.com/jackc/pgx/v5/pgxpool"
)

type AchievementsHandler struct {
	Pool *pgxpool.Pool
}

type claimAchievementBody struct {
	Code string `json:"code"`
}

func writeRewardItems(w http.ResponseWriter, r *http.Request, items []store.AchievementItem, key string) {
	lang := i18n.LangFromRequest(r)
	out := make([]map[string]any, 0, len(items))
	for _, it := range items {
		title := i18n.AchievementTitle(lang, it.Code)
		if title == "" {
			title = it.Title
		}
		desc := i18n.AchievementDescription(lang, it.Code)
		if desc == "" {
			desc = it.Description
		}
		m := map[string]any{
			"code":          it.Code,
			"title":         title,
			"description":   desc,
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
	_ = json.NewEncoder(w).Encode(map[string]any{key: out})
}

func writeUnclaimedCount(w http.ResponseWriter, r *http.Request, n int) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store, no-cache")
	_ = json.NewEncoder(w).Encode(map[string]int{"count": n})
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
	writeRewardItems(w, r, items, "achievements")
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
	writeUnclaimedCount(w, r, n)
}

// GET /api/tasks
func (h *AchievementsHandler) ListTasks(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	items, err := store.ListTasks(r.Context(), h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	writeRewardItems(w, r, items, "tasks")
}

// GET /api/tasks/unclaimed-count
func (h *AchievementsHandler) UnclaimedTasksCount(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	n, err := store.CountUnclaimedTasks(r.Context(), h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	writeUnclaimedCount(w, r, n)
}

// POST /api/tasks/claim  {"code":"..."}
func (h *AchievementsHandler) ClaimTask(w http.ResponseWriter, r *http.Request) {
	h.Claim(w, r)
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
