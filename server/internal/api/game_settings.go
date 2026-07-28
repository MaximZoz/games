package api

import (
	"encoding/json"
	"net/http"
	"strings"

	"multigames/server/internal/store"
)

type gameSettingsBody struct {
	GameType             string `json:"game_type"`
	TurnTimeSec          int    `json:"turn_time_sec"`
	GridSize             int    `json:"grid_size"`
	SwapRule             bool   `json:"swap_rule"`
	FirstMoveRestriction bool   `json:"first_move_restriction"`
	StakeBronze          int    `json:"stake_bronze"`
}

func gameSettingsToJSON(s store.UserGameSettings) map[string]any {
	return map[string]any{
		"game_type":              s.GameType,
		"turn_time_sec":          s.TurnTimeSec,
		"grid_size":              s.GridSize,
		"swap_rule":              s.SwapRule,
		"first_move_restriction": s.FirstMoveRestriction,
		"stake_bronze":           s.StakeBronze,
	}
}

func normalizeGameSettings(body gameSettingsBody) (store.UserGameSettings, string) {
	gameType := strings.TrimSpace(strings.ToLower(body.GameType))
	if gameType == "" {
		gameType = store.GameTypeTicTacToe
	}
	if gameType != store.GameTypeTicTacToe {
		return store.UserGameSettings{}, "unsupported game_type"
	}
	if !validTurnTimeSec[body.TurnTimeSec] {
		return store.UserGameSettings{}, "invalid turn_time_sec"
	}
	if !validGridSize[body.GridSize] {
		return store.UserGameSettings{}, "invalid grid_size"
	}
	stake := body.StakeBronze
	if stake < 1 {
		stake = 1
	}
	return store.UserGameSettings{
		GameType:             gameType,
		TurnTimeSec:          body.TurnTimeSec,
		GridSize:             body.GridSize,
		SwapRule:             body.SwapRule,
		FirstMoveRestriction: body.FirstMoveRestriction,
		StakeBronze:          stake,
	}, ""
}

// GameSettings — GET/PUT /api/games/settings (Postgres, без Redis).
func (h *GamesHandler) GameSettings(w http.ResponseWriter, r *http.Request) {
	if _, ok := currentUserIDFromGames(r); !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	switch r.Method {
	case http.MethodGet:
		h.getGameSettings(w, r)
	case http.MethodPut:
		h.putGameSettings(w, r)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func (h *GamesHandler) getGameSettings(w http.ResponseWriter, r *http.Request) {
	uid, ok := GetUserID(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	gameType := strings.TrimSpace(strings.ToLower(r.URL.Query().Get("game_type")))
	if gameType == "" {
		gameType = store.GameTypeTicTacToe
	}
	s, err := store.GetUserGameSettings(r.Context(), h.Pool, uid, gameType)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store, no-cache")
	_ = json.NewEncoder(w).Encode(gameSettingsToJSON(s))
}

func (h *GamesHandler) putGameSettings(w http.ResponseWriter, r *http.Request) {
	uid, ok := GetUserID(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	var body gameSettingsBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	s, errMsg := normalizeGameSettings(body)
	if errMsg != "" {
		http.Error(w, errMsg, http.StatusBadRequest)
		return
	}
	mayStake, err := store.UserMayStake(r.Context(), h.Pool, uid, s.StakeBronze)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	if !mayStake {
		// Не блокируем сохранение целиком — откатываем ставку на бесплатную.
		s.StakeBronze = 1
	}
	saved, err := store.UpsertUserGameSettings(r.Context(), h.Pool, uid, s)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(gameSettingsToJSON(saved))
}
