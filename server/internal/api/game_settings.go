package api

import (
	"encoding/json"
	"net/http"
	"strings"

	"multigames/server/internal/durak"
	"multigames/server/internal/gameengine"
	"multigames/server/internal/store"
)

type gameSettingsBody struct {
	GameType             string `json:"game_type"`
	TurnTimeSec          int    `json:"turn_time_sec"`
	GridSize             int    `json:"grid_size"`
	Variant              string `json:"variant"`
	SwapRule             bool   `json:"swap_rule"`
	FirstMoveRestriction bool   `json:"first_move_restriction"`
	StakeBronze          int    `json:"stake_bronze"`
	DeckSize             int    `json:"deck_size"`
	MaxPlayers           int    `json:"max_players"`
	GameMode             string `json:"game_mode"`
}

func gameSettingsToJSON(s store.UserGameSettings) map[string]any {
	out := map[string]any{
		"game_type":              s.GameType,
		"turn_time_sec":          s.TurnTimeSec,
		"grid_size":              s.GridSize,
		"variant":                s.Variant,
		"swap_rule":              false,
		"first_move_restriction": false,
		"stake_bronze":           s.StakeBronze,
	}
	if s.GameType == store.GameTypeBattleship {
		out["first_move_restriction"] = s.FirstMoveRestriction
		out["grid_size"] = 10
	}
	if s.GameType == store.GameTypeDurak || s.DeckSize > 0 {
		out["deck_size"] = s.DeckSize
		out["max_players"] = s.MaxPlayers
		out["game_mode"] = s.GameMode
	}
	if s.GameType == store.GameTypePoker || s.GameType == store.GameTypeUno {
		out["max_players"] = s.MaxPlayers
		out["game_mode"] = s.GameMode
		out["variant"] = s.Variant
	}
	return out
}

func normalizeGameSettings(body gameSettingsBody) (store.UserGameSettings, string) {
	gameType := strings.TrimSpace(strings.ToLower(body.GameType))
	if gameType == "" {
		gameType = store.GameTypeTicTacToe
	}
	switch gameType {
	case store.GameTypeTicTacToe:
		return normalizeTictactoeSettings(body)
	case store.GameTypeDurak:
		return normalizeDurakSettings(body)
	case store.GameTypeBattleship:
		return normalizeBattleshipSettings(body)
	case store.GameTypePoker:
		return normalizePokerSettings(body)
	case store.GameTypeUno:
		return normalizeUnoSettings(body)
	default:
		return store.UserGameSettings{}, "unsupported game_type"
	}
}

func normalizeTictactoeSettings(body gameSettingsBody) (store.UserGameSettings, string) {
	if !validTurnTimeSec[body.TurnTimeSec] {
		return store.UserGameSettings{}, "invalid turn_time_sec"
	}
	cfg, variant := resolveVariantConfig(body.Variant, body.GridSize)
	stake := body.StakeBronze
	if stake < 2 {
		stake = 2
	}
	_ = gameengine.Variant(variant)
	return store.UserGameSettings{
		GameType:             store.GameTypeTicTacToe,
		TurnTimeSec:          body.TurnTimeSec,
		GridSize:             cfg.GridSize,
		Variant:              string(variant),
		SwapRule:             false,
		FirstMoveRestriction: false,
		StakeBronze:          stake,
		DeckSize:             36,
		MaxPlayers:           cfg.MaxPlayers,
		GameMode:             "podkidnoi",
	}, ""
}

func normalizeDurakSettings(body gameSettingsBody) (store.UserGameSettings, string) {
	if !validTurnTimeSec[body.TurnTimeSec] {
		return store.UserGameSettings{}, "invalid turn_time_sec"
	}
	maxPlayers := body.MaxPlayers
	if maxPlayers < 2 || maxPlayers > 4 {
		maxPlayers = 2
	}
	deckSize := body.DeckSize
	if !validDurakDeckSize[deckSize] {
		deckSize = 36
	}
	// 24 только вдвоём; 52 — от троих.
	if deckSize == 24 && maxPlayers > 2 {
		deckSize = 36
	}
	if deckSize == 52 && maxPlayers < 3 {
		deckSize = 36
	}
	mode := string(durak.ParseMode(body.GameMode))
	if mode == "" {
		mode = "podkidnoi"
	}
	stake := body.StakeBronze
	if stake < 2 {
		stake = 2
	}
	return store.UserGameSettings{
		GameType:             store.GameTypeDurak,
		TurnTimeSec:          body.TurnTimeSec,
		GridSize:             3,
		Variant:              mode,
		SwapRule:             false,
		FirstMoveRestriction: false,
		StakeBronze:          stake,
		DeckSize:             deckSize,
		MaxPlayers:           maxPlayers,
		GameMode:             mode,
	}, ""
}

func normalizeBattleshipSettings(body gameSettingsBody) (store.UserGameSettings, string) {
	if !validTurnTimeSec[body.TurnTimeSec] {
		return store.UserGameSettings{}, "invalid turn_time_sec"
	}
	stake := body.StakeBronze
	if stake < 2 {
		stake = 2
	}
	return store.UserGameSettings{
		GameType:             store.GameTypeBattleship,
		TurnTimeSec:          body.TurnTimeSec,
		GridSize:             10,
		Variant:              "classic",
		SwapRule:             false,
		FirstMoveRestriction: body.FirstMoveRestriction,
		StakeBronze:          stake,
		DeckSize:             36,
		MaxPlayers:           2,
		GameMode:             "podkidnoi",
	}, ""
}

func normalizePokerSettings(body gameSettingsBody) (store.UserGameSettings, string) {
	if !validTurnTimeSec[body.TurnTimeSec] {
		return store.UserGameSettings{}, "invalid turn_time_sec"
	}
	maxPlayers := body.MaxPlayers
	// 1 = мгновенная партия с ботом на клиенте; 2–6 — стол.
	if maxPlayers < 1 || maxPlayers > 6 {
		maxPlayers = 2
	}
	stake := body.StakeBronze
	if stake < 2 {
		stake = 2
	}
	return store.UserGameSettings{
		GameType:             store.GameTypePoker,
		TurnTimeSec:          body.TurnTimeSec,
		GridSize:             3,
		Variant:              "holdem",
		SwapRule:             false,
		FirstMoveRestriction: false,
		StakeBronze:          stake,
		DeckSize:             52,
		MaxPlayers:           maxPlayers,
		GameMode:             "holdem",
	}, ""
}

func normalizeUnoSettings(body gameSettingsBody) (store.UserGameSettings, string) {
	if !validTurnTimeSec[body.TurnTimeSec] {
		return store.UserGameSettings{}, "invalid turn_time_sec"
	}
	maxPlayers := body.MaxPlayers
	// 1 = мгновенная партия с ботом; 2–4 — обычное лобби.
	if maxPlayers < 1 || maxPlayers > 4 {
		maxPlayers = 2
	}
	stake := body.StakeBronze
	if stake < 2 {
		stake = 2
	}
	return store.UserGameSettings{
		GameType:             store.GameTypeUno,
		TurnTimeSec:          body.TurnTimeSec,
		GridSize:             3,
		Variant:              "classic",
		SwapRule:             false,
		FirstMoveRestriction: false,
		StakeBronze:          stake,
		DeckSize:             108,
		MaxPlayers:           maxPlayers,
		GameMode:             "classic",
	}, ""
}

// GameSettings — GET/PUT /api/games/settings (Postgres, без Redis).
func (h *GamesHandler) GameSettings(w http.ResponseWriter, r *http.Request) {
	if _, ok := currentUserIDFromGames(r); !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	switch r.Method {
	case http.MethodGet:
		h.getGameSettings(w, r)
	case http.MethodPut:
		h.putGameSettings(w, r)
	default:
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

func (h *GamesHandler) getGameSettings(w http.ResponseWriter, r *http.Request) {
	uid, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	gameType := strings.TrimSpace(strings.ToLower(r.URL.Query().Get("game_type")))
	if gameType == "" {
		gameType = store.GameTypeTicTacToe
	}
	s, err := store.GetUserGameSettings(r.Context(), h.Pool, uid, gameType)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if gameType == store.GameTypeTicTacToe {
		cfg, v := resolveVariantConfig(s.Variant, s.GridSize)
		s.Variant = string(v)
		s.GridSize = cfg.GridSize
	} else if gameType == store.GameTypeDurak {
		if s.GameMode == "" {
			s.GameMode = "podkidnoi"
		}
		s.Variant = s.GameMode
	} else if gameType == store.GameTypeBattleship {
		s.GridSize = 10
		s.Variant = "classic"
	} else if gameType == store.GameTypePoker {
		if s.MaxPlayers < 1 || s.MaxPlayers > 6 {
			s.MaxPlayers = 2
		}
		s.GameMode = "holdem"
		s.Variant = "holdem"
	} else if gameType == store.GameTypeUno {
		if s.MaxPlayers < 1 || s.MaxPlayers > 4 {
			s.MaxPlayers = 2
		}
		s.GameMode = "classic"
		s.Variant = "classic"
	}
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store, no-cache")
	_ = json.NewEncoder(w).Encode(gameSettingsToJSON(s))
}

func (h *GamesHandler) putGameSettings(w http.ResponseWriter, r *http.Request) {
	uid, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body gameSettingsBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	s, errMsg := normalizeGameSettings(body)
	if errMsg != "" {
		WriteErr(w, r, http.StatusBadRequest, errMsg)
		return
	}
	mayStake, err := store.UserMayStake(r.Context(), h.Pool, uid, s.StakeBronze)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if !mayStake {
		// Не блокируем сохранение целиком — откатываем ставку на бесплатную.
		s.StakeBronze = 2
	}
	saved, err := store.UpsertUserGameSettings(r.Context(), h.Pool, uid, s)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(gameSettingsToJSON(saved))
}
