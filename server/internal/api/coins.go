package api

import (
	"encoding/json"
	"net/http"
	"strconv"

	"multigames/server/internal/store"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type CoinsHandler struct {
	Pool *pgxpool.Pool
	Hub  *RealtimeHub
}

// GET /api/coins/daily-available → статус серии и следующей награды
func (h *CoinsHandler) DailyAvailable(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	info, err := store.GetDailyRewardInfo(r.Context(), h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store, no-cache")
	_ = json.NewEncoder(w).Encode(dailyRewardInfoJSON(info))
}

// POST /api/coins/claim-daily → баланс, награда и серия
func (h *CoinsHandler) ClaimDaily(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	result, err := store.ClaimDailyReward(r.Context(), h.Pool, userID)
	if err != nil {
		if err == store.ErrAlreadyClaimed {
			WriteErr(w, r, http.StatusConflict, "already claimed today")
			return
		}
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]int{
		"balance_bronze": result.BalanceBronze,
		"reward_bronze":  result.RewardBronze,
		"streak":         result.Streak,
	})

	if h.Hub != nil {
		h.Hub.PublishToUsers([]uuid.UUID{userID}, map[string]any{
			"type":      "daily_reward_claimed",
			"available": false,
			"streak":    result.Streak,
			"reward":    result.RewardBronze,
		})
	}
}

func dailyRewardInfoJSON(info store.DailyRewardInfo) map[string]any {
	milestones := make(map[string]int, len(info.MilestonesBronze))
	for day, bronze := range info.MilestonesBronze {
		milestones[strconv.Itoa(day)] = bronze
	}
	return map[string]any{
		"available":           info.Available,
		"streak":              info.Streak,
		"next_streak":         info.NextStreak,
		"next_reward_bronze":  info.NextRewardBronze,
		"milestones_bronze":   milestones,
	}
}
