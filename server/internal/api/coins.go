package api

import (
	"encoding/json"
	"net/http"

	"multigames/server/internal/store"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type CoinsHandler struct {
	Pool *pgxpool.Pool
	Hub  *RealtimeHub
}

// GET /api/coins/daily-available → { "available": bool }
func (h *CoinsHandler) DailyAvailable(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	available, err := store.CanClaimDailyReward(r.Context(), h.Pool, userID)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store, no-cache")
	_ = json.NewEncoder(w).Encode(map[string]bool{"available": available})
}

// POST /api/coins/claim-daily → { "balance_bronze": int }
func (h *CoinsHandler) ClaimDaily(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	newBalance, err := store.ClaimDailyReward(r.Context(), h.Pool, userID)
	if err != nil {
		if err == store.ErrAlreadyClaimed {
			http.Error(w, "already claimed today", http.StatusConflict)
			return
		}
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]int{"balance_bronze": newBalance})

	if h.Hub != nil {
		h.Hub.PublishToUsers([]uuid.UUID{userID}, map[string]any{
			"type":      "daily_reward_claimed",
			"available": false,
		})
	}
}
