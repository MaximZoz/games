package api

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"

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

// ClaimAdminGrantRequest — тело POST /api/coins/claim-admin-grant.
type ClaimAdminGrantRequest struct {
	GrantID string `json:"grant_id"`
}

// ClaimAdminGrant забирает отложенное начисление из карточки поддержки.
func (h *CoinsHandler) ClaimAdminGrant(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var req ClaimAdminGrantRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	grantID, err := uuid.Parse(strings.TrimSpace(req.GrantID))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid grant_id")
		return
	}
	result, err := store.ClaimAdminCoinGrant(r.Context(), h.Pool, userID, grantID)
	if err != nil {
		switch {
		case errors.Is(err, store.ErrAdminGrantNotFound):
			WriteErr(w, r, http.StatusNotFound, "grant not found")
		case errors.Is(err, store.ErrAdminGrantClaimed):
			WriteErr(w, r, http.StatusConflict, "already claimed")
		case errors.Is(err, store.ErrAdminGrantInvalid):
			WriteErr(w, r, http.StatusBadRequest, "invalid grant")
		default:
			WriteErr(w, r, http.StatusInternalServerError, "server error")
		}
		return
	}

	if h.Hub != nil {
		h.Hub.PublishToUsers([]uuid.UUID{userID}, map[string]any{
			"type":    "coins_granted",
			"amount":  result.AmountBronze,
			"balance": result.BalanceBronze,
		})
		if result.MessageID != nil && result.ChatID != nil {
			// Обновить карточку у всех открытых клиентов (claimed).
			msg, mErr := store.GetChatMessageByID(
				r.Context(), h.Pool, *result.ChatID, userID, *result.MessageID,
			)
			if mErr == nil {
				item := chatMessageToItem(msg)
				// Подменить body на claimed-версию на случай гонки чтения.
				item.Body = result.MessageBody
				if low, high, pairErr := store.ChatParticipantIDs(r.Context(), h.Pool, *result.ChatID); pairErr == nil {
					h.Hub.PublishToUsers([]uuid.UUID{low, high}, map[string]any{
						"type":    "chat_message_updated",
						"chat_id": result.ChatID.String(),
						"message": item,
					})
				}
			}
		}
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"balance_bronze": result.BalanceBronze,
		"reward_bronze":  result.AmountBronze,
		"grant_id":       grantID.String(),
		"message_body":   result.MessageBody,
	})
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
