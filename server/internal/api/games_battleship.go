package api

import (
	"context"
	"encoding/json"
	"math/rand"
	"net/http"
	"strconv"
	"strings"
	"time"

	"multigames/server/internal/battleship"
	"multigames/server/internal/store"

	"github.com/google/uuid"
)

const (
	battleshipGameType   = "battleship"
	battleshipBotID      = "bot:battleship"
	battleshipPhaseSetup = "setup"
	battleshipPhaseBattle = "battle"
	battleshipStatusOver = "over"
	battleshipSetupSec   = 60 // расстановка по умолчанию — 1 минута
)

func battleshipMatchmakeKey(turnTimeSec, stakeBronze int) string {
	return "battleship:matchmake:" + strconv.Itoa(turnTimeSec) + ":" + strconv.Itoa(stakeBronze)
}

// serveBattleship — dispatcher для `/api/games/battleship/*`.
func (h *GamesHandler) serveBattleship(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/games/battleship/")
	parts := strings.Split(path, "/")

	switch {
	case path == "active" && r.Method == http.MethodGet:
		h.GetActive(w, r)
	case path == "lobby" && r.Method == http.MethodPost:
		h.CreateBattleshipLobby(w, r)
	case path == "lobbies" && r.Method == http.MethodGet:
		h.ListBattleshipLobbies(w, r)
	case path == "rematch" && r.Method == http.MethodPost:
		h.BattleshipRematch(w, r)
	case len(parts) >= 2 && parts[0] == "lobby":
		lobbyID := parts[1]
		if lobbyID == "" {
			WriteErr(w, r, http.StatusBadRequest, "lobby id required")
			return
		}
		switch {
		case len(parts) == 2 && r.Method == http.MethodGet:
			h.GetLobby(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "invite" && r.Method == http.MethodPost:
			h.InviteToLobby(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "join" && r.Method == http.MethodPost:
			h.JoinBattleshipLobby(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "leave" && r.Method == http.MethodPost:
			h.LeaveLobby(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "decline" && r.Method == http.MethodPost:
			h.DeclineInvite(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "cancel-invite" && r.Method == http.MethodPost:
			h.CancelInvite(w, r, lobbyID)
		default:
			WriteErr(w, r, http.StatusNotFound, "not found")
		}
	case len(parts) >= 2 && parts[0] == "game":
		gameID := parts[1]
		if gameID == "" {
			WriteErr(w, r, http.StatusBadRequest, "game id required")
			return
		}
		switch {
		case len(parts) == 2 && r.Method == http.MethodGet:
			h.GetBattleshipGame(w, r, gameID)
		case len(parts) == 3 && parts[2] == "place_ships" && r.Method == http.MethodPost:
			h.BattleshipPlaceShips(w, r, gameID)
		case len(parts) == 3 && parts[2] == "shoot" && r.Method == http.MethodPost:
			h.BattleshipShoot(w, r, gameID)
		case len(parts) == 3 && parts[2] == "forfeit" && r.Method == http.MethodPost:
			h.ForfeitBattleshipGame(w, r, gameID)
		case len(parts) == 3 && parts[2] == "draw-offer" && r.Method == http.MethodPost:
			h.BattleshipOfferDraw(w, r, gameID)
		case len(parts) == 3 && parts[2] == "draw-accept" && r.Method == http.MethodPost:
			h.BattleshipAcceptDraw(w, r, gameID)
		default:
			WriteErr(w, r, http.StatusNotFound, "not found")
		}
	default:
		WriteErr(w, r, http.StatusNotFound, "not found")
	}
}

type createBattleshipLobbyBody struct {
	Mode                 string `json:"mode"` // "invite" | "matchmake"
	TurnTimeSec          int    `json:"turn_time_sec"`
	StakeBronze          int    `json:"stake_bronze"`
	FirstMoveRestriction bool   `json:"first_move_restriction"`
	AddBotsAfter30s      bool   `json:"add_bots_after_30s"`
}

func (h *GamesHandler) CreateBattleshipLobby(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body createBattleshipLobbyBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	mode := strings.TrimSpace(strings.ToLower(body.Mode))
	if mode != "invite" && mode != "matchmake" {
		WriteErr(w, r, http.StatusBadRequest, "mode must be invite or matchmake")
		return
	}
	if !validTurnTimeSec[body.TurnTimeSec] {
		WriteErr(w, r, http.StatusBadRequest, "turn_time_sec must be 0, 20, 60 or 600")
		return
	}
	stakeBronze := body.StakeBronze
	if stakeBronze < 2 {
		stakeBronze = 2
	}
	ctx := r.Context()
	if h.blockingActiveGameID(ctx, userID) != "" {
		WriteErr(w, r, http.StatusConflict, "finish your current game first")
		return
	}
	mayStake, err := store.UserMayStake(ctx, h.Pool, userID, stakeBronze)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if !mayStake {
		WriteErr(w, r, http.StatusForbidden, "stake not unlocked")
		return
	}
	if err := h.checkStakeAffordable(ctx, userID, stakeBronze); err != nil {
		if err == store.ErrInsufficientFunds {
			WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
			return
		}
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	turnTimeSec := body.TurnTimeSec
	firstMoveRestriction := body.FirstMoveRestriction
	addBotsAfter30s := body.AddBotsAfter30s

	if mode == "matchmake" {
		otherEntry, err := h.Rdb.RPop(ctx, battleshipMatchmakeKey(turnTimeSec, stakeBronze)).Result()
		if err == nil && otherEntry != "" {
			parts := strings.SplitN(otherEntry, ":", 2)
			otherUserID := parts[0]
			otherLobbyID := ""
			if len(parts) > 1 {
				otherLobbyID = parts[1]
			}
			otherUUID, perr := uuid.Parse(otherUserID)
			if perr == nil && otherUUID != userID {
				reuseLobbyID := ""
				if otherLobbyID != "" {
					lm, lerr := h.Rdb.HGetAll(ctx, "lobby:"+otherLobbyID).Result()
					if lerr == nil && len(lm) > 0 && lm["status"] == lobbyStatusWaitingMatchmake &&
						lm["game_type"] == battleshipGameType {
						reuseLobbyID = otherLobbyID
					} else if otherLobbyID != "" {
						h.Rdb.Del(ctx, "lobby:"+otherLobbyID)
					}
				}
				gameID, lobbyID, cerr := h.createBattleshipGameFromMatch(
					ctx, userID, otherUUID, reuseLobbyID, turnTimeSec, stakeBronze, firstMoveRestriction,
				)
				if cerr != nil {
					if cerr == store.ErrStakeNotAllowed {
						WriteErr(w, r, http.StatusForbidden, "stake not unlocked")
						return
					}
					if cerr == store.ErrInsufficientFunds {
						WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
						return
					}
					WriteErr(w, r, http.StatusInternalServerError, "server error")
					return
				}
				clearUserActiveLobby(ctx, h.Rdb, userID)
				clearUserActiveLobby(ctx, h.Rdb, otherUUID)
				setUserActiveGame(ctx, h.Rdb, userID, gameID)
				setUserActiveGame(ctx, h.Rdb, otherUUID, gameID)
				h.publishGameStartedTyped([]uuid.UUID{userID, otherUUID}, gameID, lobbyID, battleshipGameType)
				writeJSON(w, http.StatusOK, map[string]any{
					"lobby_id": lobbyID,
					"game_id":  gameID,
					"matched":  true,
				})
				return
			}
		}
	}

	lobbyID := uuid.New().String()
	status := lobbyStatusWaitingInvite
	if mode == "matchmake" {
		status = lobbyStatusWaitingMatchmake
	}
	key := "lobby:" + lobbyID
	now := time.Now().UTC().Format(time.RFC3339Nano)
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key,
		"game_type", battleshipGameType,
		"creator_id", userID.String(),
		"status", status,
		"created_at", now,
		"mode", mode,
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"max_players", "2",
		"player_ids", userID.String(),
		"first_move_restriction", strconv.FormatBool(firstMoveRestriction),
		"stake_bronze", strconv.Itoa(stakeBronze),
		"add_bots_after_30s", strconv.FormatBool(addBotsAfter30s),
	)
	pipe.Expire(ctx, key, lobbyTTL)
	if mode == "matchmake" {
		mmKey := battleshipMatchmakeKey(turnTimeSec, stakeBronze)
		pipe.LPush(ctx, mmKey, userID.String()+":"+lobbyID)
		pipe.Expire(ctx, mmKey, 5*time.Minute)
	}
	if _, err := pipe.Exec(ctx); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)
	if mode == "matchmake" {
		h.notifyPublicLobbiesChanged()
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"lobby_id":   lobbyID,
		"status":     status,
		"created_at": now,
		"creator_id": userID.String(),
		"matched":    false,
	})
}

func (h *GamesHandler) ListBattleshipLobbies(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	_ = userID
	ctx := r.Context()
	keys, err := scanRedisKeys(ctx, h.Rdb, "lobby:*")
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	type item struct {
		ID                   string `json:"id"`
		CreatorID            string `json:"creator_id"`
		Status               string `json:"status"`
		GameType             string `json:"game_type"`
		MaxPlayers           int    `json:"max_players"`
		TurnTimeSec          int    `json:"turn_time_sec"`
		StakeBronze          int    `json:"stake_bronze"`
		FirstMoveRestriction bool   `json:"first_move_restriction"`
		Players              int    `json:"players"`
		CreatedAt            string `json:"created_at"`
	}
	var items []item
	for _, key := range keys {
		if strings.HasSuffix(key, ":invited") {
			continue
		}
		m, err := h.Rdb.HGetAll(ctx, key).Result()
		if err != nil || len(m) == 0 {
			continue
		}
		if m["game_type"] != battleshipGameType || m["mode"] != "matchmake" {
			continue
		}
		st := m["status"]
		if st != lobbyStatusWaitingInvite && st != lobbyStatusWaitingMatchmake {
			continue
		}
		if strings.TrimSpace(m["invite_target_id"]) != "" {
			continue
		}
		playerIDs := parsePlayerIDsCSV(m["player_ids"])
		turnT, _ := strconv.Atoi(m["turn_time_sec"])
		stake, _ := strconv.Atoi(m["stake_bronze"])
		if stake < 2 {
			stake = 2
		}
		items = append(items, item{
			ID:                   strings.TrimPrefix(key, "lobby:"),
			CreatorID:            m["creator_id"],
			Status:               st,
			GameType:             battleshipGameType,
			MaxPlayers:           2,
			TurnTimeSec:          turnT,
			StakeBronze:          stake,
			FirstMoveRestriction: m["first_move_restriction"] == "true",
			Players:              len(playerIDs),
			CreatedAt:            m["created_at"],
		})
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"lobbies": items})
}

func (h *GamesHandler) JoinBattleshipLobby(w http.ResponseWriter, r *http.Request, lobbyID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	ctx := r.Context()
	key := "lobby:" + lobbyID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		h.cleanupInviteLobbyChatMessages(ctx, lobbyID)
		WriteErr(w, r, http.StatusNotFound, "lobby not found")
		return
	}
	if m["game_type"] != battleshipGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	status := m["status"]
	if status == lobbyStatusInGame {
		h.cleanupInviteLobbyChatMessages(ctx, lobbyID)
		WriteErr(w, r, http.StatusConflict, "game already started with another opponent")
		return
	}
	if status != lobbyStatusWaitingInvite && status != lobbyStatusWaitingMatchmake {
		h.cleanupInviteLobbyChatMessages(ctx, lobbyID)
		WriteErr(w, r, http.StatusBadRequest, "lobby not joinable")
		return
	}
	if m["creator_id"] == userID.String() {
		WriteErr(w, r, http.StatusBadRequest, "cannot join own lobby")
		return
	}
	if h.blockingActiveGameID(ctx, userID) != "" {
		WriteErr(w, r, http.StatusConflict, "finish your current game first")
		return
	}
	if lid, lerr := h.Rdb.Get(ctx, userActiveLobbyKey(userID)).Result(); lerr == nil && lid != "" && lid != lobbyID {
		if lm, _ := h.Rdb.HGetAll(ctx, "lobby:"+lid).Result(); len(lm) > 0 {
			st := lm["status"]
			if st == lobbyStatusWaitingInvite || st == lobbyStatusWaitingMatchmake {
				WriteErr(w, r, http.StatusConflict, "finish your current game first")
				return
			}
		}
	}

	creatorUUID, _ := uuid.Parse(m["creator_id"])
	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	if stakeBronze < 2 {
		stakeBronze = 2
	}
	firstMoveRestriction := m["first_move_restriction"] == "true"

	mayStake, e := store.UserMayStake(ctx, h.Pool, userID, stakeBronze)
	if e != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if !mayStake {
		WriteErr(w, r, http.StatusForbidden, "stake not unlocked")
		return
	}
	if err := h.checkStakeAffordable(ctx, userID, stakeBronze); err != nil {
		if err == store.ErrInsufficientFunds {
			WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
			return
		}
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	if status == lobbyStatusWaitingMatchmake {
		h.Rdb.LRem(ctx, battleshipMatchmakeKey(turnTimeSec, stakeBronze), 0, m["creator_id"]+":"+lobbyID)
	}

	gameID, err := h.startBattleshipGame(ctx, lobbyID, creatorUUID, userID, turnTimeSec, stakeBronze, firstMoveRestriction)
	if err != nil {
		if err == store.ErrStakeNotAllowed {
			WriteErr(w, r, http.StatusForbidden, "stake not unlocked")
			return
		}
		if err == store.ErrInsufficientFunds {
			WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
			return
		}
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	clearUserActiveLobby(ctx, h.Rdb, userID)
	clearUserActiveLobby(ctx, h.Rdb, creatorUUID)
	setUserActiveGame(ctx, h.Rdb, userID, gameID)
	setUserActiveGame(ctx, h.Rdb, creatorUUID, gameID)
	h.publishGameStartedTyped([]uuid.UUID{userID, creatorUUID}, gameID, lobbyID, battleshipGameType)
	if m["mode"] == "matchmake" {
		h.notifyPublicLobbiesChanged()
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"joined":   true,
		"lobby_id": lobbyID,
		"game_id":  gameID,
		"matched":  true,
	})
}

func (h *GamesHandler) createBattleshipGameFromMatch(
	ctx context.Context,
	user1, user2 uuid.UUID,
	existingLobbyID string,
	turnTimeSec, stakeBronze int,
	firstMoveRestriction bool,
) (gameID, lobbyID string, err error) {
	lobbyID = existingLobbyID
	if lobbyID == "" {
		lobbyID = uuid.New().String()
		key := "lobby:" + lobbyID
		now := time.Now().UTC().Format(time.RFC3339Nano)
		h.Rdb.HSet(ctx, key,
			"game_type", battleshipGameType,
			"creator_id", user2.String(),
			"status", lobbyStatusWaitingMatchmake,
			"created_at", now,
			"mode", "matchmake",
			"turn_time_sec", strconv.Itoa(turnTimeSec),
			"max_players", "2",
			"player_ids", user2.String(),
			"first_move_restriction", strconv.FormatBool(firstMoveRestriction),
			"stake_bronze", strconv.Itoa(stakeBronze),
		)
		h.Rdb.Expire(ctx, key, lobbyTTL)
	}
	gameID, err = h.startBattleshipGame(ctx, lobbyID, user2, user1, turnTimeSec, stakeBronze, firstMoveRestriction)
	return gameID, lobbyID, err
}

func (h *GamesHandler) startBattleshipGame(
	ctx context.Context,
	lobbyID string,
	p1, p2 uuid.UUID,
	turnTimeSec, stakeBronze int,
	firstMoveRestriction bool,
) (string, error) {
	// Случайно кто p1/p2 (кроме явного порядка от создателя — creator = p1 в join).
	a, b := p1, p2
	if rand.Intn(2) == 1 {
		a, b = b, a
	}
	if stakeBronze > 0 {
		for _, u := range []uuid.UUID{a, b} {
			if isBot(u.String()) {
				continue
			}
			ok, e := store.UserMayStake(ctx, h.Pool, u, stakeBronze)
			if e != nil {
				return "", e
			}
			if !ok {
				return "", store.ErrStakeNotAllowed
			}
			if e := h.checkStakeAffordable(ctx, u, stakeBronze); e != nil {
				return "", e
			}
		}
		humans := make([]uuid.UUID, 0, 2)
		for _, u := range []uuid.UUID{a, b} {
			if !isBot(u.String()) {
				humans = append(humans, u)
			}
		}
		if len(humans) == 2 {
			if err := store.DeductCoinsTwo(ctx, h.Pool, humans[0], humans[1], stakeBronze); err != nil {
				return "", err
			}
		} else if len(humans) == 1 {
			if err := store.DeductCoins(ctx, h.Pool, humans[0], stakeBronze); err != nil {
				return "", err
			}
		}
	}

	gameID := uuid.New().String()
	gameKey := "game:" + gameID
	lobbyKey := "lobby:" + lobbyID
	now := time.Now().UTC()
	setupDeadline := now.Unix() + int64(battleshipSetupSec)
	if turnTimeSec > 0 {
		setupDeadline = now.Unix() + int64(turnTimeSec)
		if turnTimeSec < 60 {
			setupDeadline = now.Unix() + 60
		}
	}

	p1Ready, p2Ready := "false", "false"
	p1Ships, p2Ships := "[]", "[]"
	if isBot(a.String()) {
		ships := battleship.RandomShips(rand.New(rand.NewSource(now.UnixNano())))
		p1Ships = battleship.ShipsToJSON(ships)
		p1Ready = "true"
	}
	if isBot(b.String()) {
		ships := battleship.RandomShips(rand.New(rand.NewSource(now.UnixNano()+1)))
		p2Ships = battleship.ShipsToJSON(ships)
		p2Ready = "true"
	}

	fields := []any{
		"game_type", battleshipGameType,
		"phase", battleshipPhaseSetup,
		"status", gameStatusActive,
		"lobby_id", lobbyID,
		"p1_user_id", a.String(),
		"p2_user_id", b.String(),
		"p1_ready", p1Ready,
		"p2_ready", p2Ready,
		"p1_ships", p1Ships,
		"p2_ships", p2Ships,
		"p1_shots", "[]",
		"p2_shots", "[]",
		"turn", "",
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"setup_deadline", strconv.FormatInt(setupDeadline, 10),
		"first_move_restriction", strconv.FormatBool(firstMoveRestriction),
		"stake_bronze", strconv.Itoa(stakeBronze),
		"started_at", now.Format(time.RFC3339Nano),
		"winner", "",
	}

	// Если оба уже ready (бот vs бот / бот уже расставил) — сразу battle.
	phase := battleshipPhaseSetup
	turn := ""
	var turnDeadline int64
	if p1Ready == "true" && p2Ready == "true" {
		phase = battleshipPhaseBattle
		turn = a.String()
		if rand.Intn(2) == 1 {
			turn = b.String()
		}
		fields = append(fields, "phase", phase, "turn", turn)
		if turnTimeSec > 0 {
			turnDeadline = now.Unix() + int64(turnTimeSec)
			fields = append(fields, "turn_deadline", strconv.FormatInt(turnDeadline, 10))
		}
	}

	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, gameKey, fields...)
	pipe.Expire(ctx, gameKey, 24*time.Hour)
	pipe.HSet(ctx, lobbyKey,
		"opponent_id", b.String(),
		"status", lobbyStatusInGame,
		"game_id", gameID,
		"player_ids", a.String()+","+b.String(),
		"game_type", battleshipGameType,
	)
	pipe.Expire(ctx, lobbyKey, 24*time.Hour)
	if _, err := pipe.Exec(ctx); err != nil {
		return "", err
	}
	h.cleanupInviteLobbyChatMessages(ctx, lobbyID)
	_ = phase
	_ = turn
	_ = turnDeadline
	return gameID, nil
}

func (h *GamesHandler) createBattleshipGameWithBot(
	ctx context.Context,
	userID uuid.UUID,
	existingLobbyID string,
	turnTimeSec, stakeBronze int,
	firstMoveRestriction bool,
) (string, error) {
	if stakeBronze < 1 {
		stakeBronze = 1
	}
	ok, e := store.UserMayStake(ctx, h.Pool, userID, stakeBronze)
	if e != nil {
		return "", e
	}
	if !ok {
		return "", store.ErrStakeNotAllowed
	}
	if err := store.DeductCoins(ctx, h.Pool, userID, stakeBronze); err != nil {
		return "", err
	}
	lobbyID := existingLobbyID
	if lobbyID == "" {
		lobbyID = uuid.New().String()
	}
	// Не списываем повторно внутри start — передаём stake 0 и выставим вручную.
	gameID := uuid.New().String()
	gameKey := "game:" + gameID
	lobbyKey := "lobby:" + lobbyID
	now := time.Now().UTC()
	setupDeadline := now.Unix() + int64(battleshipSetupSec)
	if turnTimeSec > 0 {
		setupDeadline = now.Unix() + int64(maxInt(turnTimeSec, 60))
	}

	p1, p2 := userID.String(), battleshipBotID
	if rand.Intn(2) == 1 {
		p1, p2 = p2, userID.String()
	}
	botShips := battleship.ShipsToJSON(battleship.RandomShips(rand.New(rand.NewSource(now.UnixNano()))))
	p1Ready, p2Ready := "false", "false"
	p1Ships, p2Ships := "[]", "[]"
	if p1 == battleshipBotID {
		p1Ships = botShips
		p1Ready = "true"
	} else {
		p2Ships = botShips
		p2Ready = "true"
	}

	fields := []any{
		"game_type", battleshipGameType,
		"phase", battleshipPhaseSetup,
		"status", gameStatusActive,
		"lobby_id", lobbyID,
		"p1_user_id", p1,
		"p2_user_id", p2,
		"p1_ready", p1Ready,
		"p2_ready", p2Ready,
		"p1_ships", p1Ships,
		"p2_ships", p2Ships,
		"p1_shots", "[]",
		"p2_shots", "[]",
		"turn", "",
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"setup_deadline", strconv.FormatInt(setupDeadline, 10),
		"first_move_restriction", strconv.FormatBool(firstMoveRestriction),
		"stake_bronze", strconv.Itoa(stakeBronze),
		"started_at", now.Format(time.RFC3339Nano),
		"winner", "",
	}
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, gameKey, fields...)
	pipe.Expire(ctx, gameKey, 24*time.Hour)
	pipe.HSet(ctx, lobbyKey,
		"game_type", battleshipGameType,
		"creator_id", userID.String(),
		"opponent_id", battleshipBotID,
		"status", lobbyStatusInGame,
		"game_id", gameID,
		"mode", "matchmake",
		"player_ids", userID.String()+","+battleshipBotID,
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"stake_bronze", strconv.Itoa(stakeBronze),
		"first_move_restriction", strconv.FormatBool(firstMoveRestriction),
		"max_players", "2",
	)
	pipe.Expire(ctx, lobbyKey, 24*time.Hour)
	if _, err := pipe.Exec(ctx); err != nil {
		return "", err
	}
	h.cleanupInviteLobbyChatMessages(ctx, lobbyID)
	return gameID, nil
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}

// StartBattleshipBotTimeoutTicker — через 30 с без соперника добавляет бота.
func StartBattleshipBotTimeoutTicker(ctx context.Context, h *GamesHandler) {
	if h == nil || h.Rdb == nil {
		return
	}
	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			h.tickBattleshipBotTimeout(ctx)
		}
	}
}

func (h *GamesHandler) tickBattleshipBotTimeout(ctx context.Context) {
	keys, err := scanRedisKeys(ctx, h.Rdb, "lobby:*")
	if err != nil || len(keys) == 0 {
		return
	}
	now := time.Now().UTC()
	for _, key := range keys {
		m, err := h.Rdb.HGetAll(ctx, key).Result()
		if err != nil || m["game_type"] != battleshipGameType {
			continue
		}
		if m["status"] != lobbyStatusWaitingMatchmake || m["add_bots_after_30s"] != "true" {
			continue
		}
		createdAt, err := time.Parse(time.RFC3339Nano, m["created_at"])
		if err != nil {
			continue
		}
		if now.Sub(createdAt) < botTimeoutSeconds*time.Second {
			continue
		}
		lobbyID := strings.TrimPrefix(key, "lobby:")
		creatorID := m["creator_id"]
		creatorUUID, err := uuid.Parse(creatorID)
		if err != nil {
			continue
		}
		turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
		stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
		if stakeBronze < 1 {
			stakeBronze = 1
		}
		firstMoveRestriction := m["first_move_restriction"] == "true"
		h.Rdb.LRem(ctx, battleshipMatchmakeKey(turnTimeSec, stakeBronze), 0, creatorID+":"+lobbyID)
		gameID, err := h.createBattleshipGameWithBot(ctx, creatorUUID, lobbyID, turnTimeSec, 1, firstMoveRestriction)
		if err != nil {
			continue
		}
		clearUserActiveLobby(ctx, h.Rdb, creatorUUID)
		setUserActiveGame(ctx, h.Rdb, creatorUUID, gameID)
		h.publishGameStartedTyped([]uuid.UUID{creatorUUID}, gameID, lobbyID, battleshipGameType)
		return
	}
}

func battleshipHumans(m map[string]string) []uuid.UUID {
	out := make([]uuid.UUID, 0, 2)
	for _, id := range []string{m["p1_user_id"], m["p2_user_id"]} {
		if id == "" || isBot(id) {
			continue
		}
		if u, err := uuid.Parse(id); err == nil {
			out = append(out, u)
		}
	}
	return out
}

func battleshipSide(m map[string]string, userID string) string {
	if m["p1_user_id"] == userID {
		return "p1"
	}
	if m["p2_user_id"] == userID {
		return "p2"
	}
	return ""
}

func battleshipOpponentSide(side string) string {
	if side == "p1" {
		return "p2"
	}
	return "p1"
}

func (h *GamesHandler) GetBattleshipGame(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	ctx := r.Context()
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	if m["game_type"] != battleshipGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	if battleshipSide(m, userID.String()) == "" {
		WriteErr(w, r, http.StatusForbidden, "forbidden")
		return
	}
	if m["status"] == gameStatusActive {
		h.applyBattleshipTimeout(ctx, gameID, m)
		m, _ = h.Rdb.HGetAll(ctx, key).Result()
		h.maybeBattleshipBotAct(ctx, gameID, m)
		m, _ = h.Rdb.HGetAll(ctx, key).Result()
	}
	view := h.battleshipViewFor(ctx, m, gameID, userID.String())
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(view)
}

type battleshipPlaceBody struct {
	Ships json.RawMessage `json:"ships"`
}

func (h *GamesHandler) BattleshipPlaceShips(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body battleshipPlaceBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	ships, err := battleship.ParseShipsJSON(string(body.Ships))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid ships")
		return
	}
	if err := battleship.ValidateShips(ships); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid ships")
		return
	}
	ctx := r.Context()
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	if m["game_type"] != battleshipGameType || m["status"] != gameStatusActive {
		WriteErr(w, r, http.StatusBadRequest, "game not active")
		return
	}
	// Принимаем расстановку даже после setup_deadline — это «текущая» при таймауте.
	// Сначала фиксируем ships текущего игрока, затем дожимаем таймаут для соперника.
	if m["phase"] != battleshipPhaseSetup {
		h.applyBattleshipTimeout(ctx, gameID, m)
		m, _ = h.Rdb.HGetAll(ctx, key).Result()
		if m["phase"] != battleshipPhaseSetup {
			WriteErr(w, r, http.StatusBadRequest, "not in setup phase")
			return
		}
	}
	side := battleshipSide(m, userID.String())
	if side == "" {
		WriteErr(w, r, http.StatusForbidden, "forbidden")
		return
	}
	if m[side+"_ready"] == "true" {
		WriteErr(w, r, http.StatusBadRequest, "already ready")
		return
	}
	shipsJSON := battleship.ShipsToJSON(ships)
	fields := []any{side + "_ships", shipsJSON, side + "_ready", "true"}
	h.Rdb.HSet(ctx, key, fields...)
	m[side+"_ships"] = shipsJSON
	m[side+"_ready"] = "true"

	// Соперник без ready после дедлайна → дефолтная/сохранённая расстановка.
	h.applyBattleshipTimeout(ctx, gameID, m)
	m, _ = h.Rdb.HGetAll(ctx, key).Result()

	if m["phase"] == battleshipPhaseSetup &&
		m["p1_ready"] == "true" && m["p2_ready"] == "true" {
		h.beginBattleshipBattle(ctx, gameID, m)
		m, _ = h.Rdb.HGetAll(ctx, key).Result()
	}
	h.broadcastBattleshipState(ctx, gameID, m)
	h.maybeBattleshipBotAct(ctx, gameID, m)
	m, _ = h.Rdb.HGetAll(ctx, key).Result()
	view := h.battleshipViewFor(ctx, m, gameID, userID.String())
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(view)
}

func (h *GamesHandler) beginBattleshipBattle(ctx context.Context, gameID string, m map[string]string) {
	key := "game:" + gameID
	// После расстановки ход начинает случайный игрок.
	turn := m["p1_user_id"]
	if rand.Intn(2) == 1 {
		turn = m["p2_user_id"]
	}
	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	fields := []any{
		"phase", battleshipPhaseBattle,
		"turn", turn,
	}
	if turnTimeSec > 0 {
		dl := time.Now().UTC().Unix() + int64(turnTimeSec)
		fields = append(fields, "turn_deadline", strconv.FormatInt(dl, 10))
	}
	h.Rdb.HSet(ctx, key, fields...)
	m["phase"] = battleshipPhaseBattle
	m["turn"] = turn
}

type battleshipShootBody struct {
	Cell int `json:"cell"`
}

func (h *GamesHandler) BattleshipShoot(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body battleshipShootBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	if body.Cell < 0 || body.Cell >= battleship.CellCount {
		WriteErr(w, r, http.StatusBadRequest, "invalid cell")
		return
	}
	ctx := r.Context()
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	if m["game_type"] != battleshipGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	h.applyBattleshipTimeout(ctx, gameID, m)
	m, _ = h.Rdb.HGetAll(ctx, key).Result()
	if m["status"] != gameStatusActive || m["phase"] != battleshipPhaseBattle {
		WriteErr(w, r, http.StatusBadRequest, "not in battle")
		return
	}
	me := userID.String()
	if m["turn"] != me {
		WriteErr(w, r, http.StatusBadRequest, "not your turn")
		return
	}
	side := battleshipSide(m, me)
	if side == "" {
		WriteErr(w, r, http.StatusForbidden, "forbidden")
		return
	}
	if err := h.applyBattleshipShot(ctx, gameID, m, side, body.Cell, "normal"); err != nil {
		WriteErr(w, r, http.StatusBadRequest, err.Error())
		return
	}
	m, _ = h.Rdb.HGetAll(ctx, key).Result()
	h.maybeBattleshipBotAct(ctx, gameID, m)
	m, _ = h.Rdb.HGetAll(ctx, key).Result()
	view := h.battleshipViewFor(ctx, m, gameID, me)
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(view)
}

func (h *GamesHandler) applyBattleshipShot(
	ctx context.Context,
	gameID string,
	m map[string]string,
	side string,
	cell int,
	finishReason string,
) error {
	key := "game:" + gameID
	opp := battleshipOpponentSide(side)
	myShots, err := battleship.ParseShotsJSON(m[side+"_shots"])
	if err != nil {
		return err
	}
	shotSet := battleship.ShotsToHitSet(myShots)
	if _, ok := shotSet[cell]; ok {
		return errBattleshipAlreadyShot
	}
	oppShips, err := battleship.ParseShipsJSON(m[opp+"_ships"])
	if err != nil {
		return err
	}
	myShots = append(myShots, cell)
	hit := battleship.IsHit(oppShips, cell)
	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	fields := []any{
		side + "_shots", battleship.ShotsToJSON(myShots),
		"last_shot", strconv.Itoa(cell),
		"last_shot_hit", strconv.FormatBool(hit),
		"last_shot_by", m[side+"_user_id"],
	}
	m[side+"_shots"] = battleship.ShotsToJSON(myShots)
	m["last_shot"] = strconv.Itoa(cell)
	m["last_shot_hit"] = strconv.FormatBool(hit)
	m["last_shot_by"] = m[side+"_user_id"]
	// Любой выстрел снимает предложение ничьей.
	if strings.TrimSpace(m["draw_offer_by"]) != "" {
		h.Rdb.HDel(ctx, key, "draw_offer_by")
		delete(m, "draw_offer_by")
	}

	if battleship.AllSunk(oppShips, myShots) {
		winner := m[side+"_user_id"]
		fields = append(fields,
			"status", battleshipStatusOver,
			"winner", winner,
			"phase", battleshipPhaseBattle,
		)
		h.Rdb.HSet(ctx, key, fields...)
		h.Rdb.Expire(ctx, key, 24*time.Hour)
		m["status"] = battleshipStatusOver
		m["winner"] = winner
		h.finishBattleshipGame(ctx, gameID, m, finishReason)
		h.broadcastBattleshipState(ctx, gameID, m)
		return nil
	}

	if hit {
		// Попадание — ход остаётся, дедлайн сбрасывается.
		if turnTimeSec > 0 {
			dl := time.Now().UTC().Unix() + int64(turnTimeSec)
			fields = append(fields, "turn_deadline", strconv.FormatInt(dl, 10))
			m["turn_deadline"] = strconv.FormatInt(dl, 10)
		}
	} else {
		next := m[opp+"_user_id"]
		fields = append(fields, "turn", next)
		m["turn"] = next
		if turnTimeSec > 0 {
			dl := time.Now().UTC().Unix() + int64(turnTimeSec)
			fields = append(fields, "turn_deadline", strconv.FormatInt(dl, 10))
			m["turn_deadline"] = strconv.FormatInt(dl, 10)
		}
	}
	h.Rdb.HSet(ctx, key, fields...)
	h.broadcastBattleshipState(ctx, gameID, m)
	return nil
}

var errBattleshipAlreadyShot = &battleshipShotError{msg: "already shot"}

type battleshipShotError struct{ msg string }

func (e *battleshipShotError) Error() string { return e.msg }

func (h *GamesHandler) maybeBattleshipBotAct(ctx context.Context, gameID string, m map[string]string) {
	if m == nil || m["status"] != gameStatusActive {
		return
	}
	key := "game:" + gameID
	// Setup: бот уже ready при старте; если нет — доставить.
	if m["phase"] == battleshipPhaseSetup {
		changed := false
		for _, side := range []string{"p1", "p2"} {
			uid := m[side+"_user_id"]
			if !isBot(uid) || m[side+"_ready"] == "true" {
				continue
			}
			ships := battleship.RandomShips(rand.New(rand.NewSource(time.Now().UnixNano())))
			sj := battleship.ShipsToJSON(ships)
			h.Rdb.HSet(ctx, key, side+"_ships", sj, side+"_ready", "true")
			m[side+"_ships"] = sj
			m[side+"_ready"] = "true"
			changed = true
		}
		if changed && m["p1_ready"] == "true" && m["p2_ready"] == "true" {
			h.beginBattleshipBattle(ctx, gameID, m)
			m, _ = h.Rdb.HGetAll(ctx, key).Result()
			h.broadcastBattleshipState(ctx, gameID, m)
		}
	}
	if m["phase"] != battleshipPhaseBattle || m["status"] != gameStatusActive {
		return
	}
	// Бот может ходить несколько раз подряд при попаданиях.
	for step := 0; step < 25; step++ {
		turn := m["turn"]
		if !isBot(turn) {
			return
		}
		side := battleshipSide(m, turn)
		if side == "" {
			return
		}
		opp := battleshipOpponentSide(side)
		oppShips, err := battleship.ParseShipsJSON(m[opp+"_ships"])
		if err != nil {
			return
		}
		myShots, _ := battleship.ParseShotsJSON(m[side+"_shots"])
		cell, err := battleship.BotPickShot(oppShips, myShots, rand.New(rand.NewSource(time.Now().UnixNano()+int64(step))))
		if err != nil {
			return
		}
		if err := h.applyBattleshipShot(ctx, gameID, m, side, cell, "normal"); err != nil {
			return
		}
		m, _ = h.Rdb.HGetAll(ctx, key).Result()
		if m["status"] != gameStatusActive {
			return
		}
	}
}

func (h *GamesHandler) ForfeitBattleshipGame(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	ctx := r.Context()
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	if m["game_type"] != battleshipGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	if m["status"] != gameStatusActive {
		WriteErr(w, r, http.StatusBadRequest, "game is over")
		return
	}
	side := battleshipSide(m, userID.String())
	if side == "" {
		WriteErr(w, r, http.StatusForbidden, "forbidden")
		return
	}
	opp := battleshipOpponentSide(side)
	winner := m[opp+"_user_id"]
	h.Rdb.HSet(ctx, key,
		"status", battleshipStatusOver,
		"winner", winner,
		"forfeit", "1",
	)
	m["status"] = battleshipStatusOver
	m["winner"] = winner
	m["forfeit"] = "1"
	h.finishBattleshipGame(ctx, gameID, m, "forfeit")
	h.broadcastBattleshipState(ctx, gameID, m)
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"ok": true, "status": battleshipStatusOver, "forfeit": true})
}

func (h *GamesHandler) BattleshipOfferDraw(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	ctx := r.Context()
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 || m["game_type"] != battleshipGameType {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	if m["status"] != gameStatusActive || m["phase"] != battleshipPhaseBattle {
		WriteErr(w, r, http.StatusBadRequest, "not in battle")
		return
	}
	if battleshipSide(m, userID.String()) == "" {
		WriteErr(w, r, http.StatusForbidden, "forbidden")
		return
	}
	if isBot(m["p1_user_id"]) || isBot(m["p2_user_id"]) {
		WriteErr(w, r, http.StatusBadRequest, "draw only in pvp")
		return
	}
	h.Rdb.HSet(ctx, key, "draw_offer_by", userID.String())
	m["draw_offer_by"] = userID.String()
	h.broadcastBattleshipState(ctx, gameID, m)
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"offered": true})
}

func (h *GamesHandler) BattleshipAcceptDraw(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	ctx := r.Context()
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 || m["game_type"] != battleshipGameType {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	if m["status"] != gameStatusActive {
		WriteErr(w, r, http.StatusBadRequest, "game is over")
		return
	}
	offeredBy := strings.TrimSpace(m["draw_offer_by"])
	if offeredBy == "" || offeredBy == userID.String() {
		WriteErr(w, r, http.StatusBadRequest, "no draw offer")
		return
	}
	if battleshipSide(m, userID.String()) == "" {
		WriteErr(w, r, http.StatusForbidden, "forbidden")
		return
	}
	h.Rdb.HSet(ctx, key,
		"status", battleshipStatusOver,
		"winner", "",
		"draw", "1",
	)
	h.Rdb.HDel(ctx, key, "draw_offer_by")
	m["status"] = battleshipStatusOver
	m["winner"] = ""
	m["draw"] = "1"
	delete(m, "draw_offer_by")
	h.finishBattleshipGame(ctx, gameID, m, "draw")
	h.broadcastBattleshipState(ctx, gameID, m)
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"draw": true})
}

func (h *GamesHandler) BattleshipRematch(w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body RematchBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	gameID := strings.TrimSpace(body.GameID)
	if gameID == "" {
		WriteErr(w, r, http.StatusBadRequest, "game_id required")
		return
	}
	ctx := r.Context()
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	if m["game_type"] != battleshipGameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	me := userID.String()
	if battleshipSide(m, me) == "" {
		WriteErr(w, r, http.StatusForbidden, "forbidden")
		return
	}
	// Если status ещё active, но флот уже потоплен — сначала завершаем.
	if m["status"] == gameStatusActive {
		h.healBattleshipIfAllSunk(ctx, gameID, m)
		m, _ = h.Rdb.HGetAll(ctx, key).Result()
	}
	if m["status"] == gameStatusActive {
		WriteErr(w, r, http.StatusBadRequest, "game is not over")
		return
	}
	oppID := m["p1_user_id"]
	if oppID == me {
		oppID = m["p2_user_id"]
	}
	if oppID == "" || isBot(oppID) {
		WriteErr(w, r, http.StatusBadRequest, "no opponents to rematch")
		return
	}
	invitee, err := uuid.Parse(oppID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "invalid opponent")
		return
	}
	lobbyID := uuid.New().String()
	lkey := "lobby:" + lobbyID
	invitedKey := lkey + ":invited"
	now := time.Now().UTC().Format(time.RFC3339Nano)
	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	if stakeBronze < 2 {
		stakeBronze = 2
	}
	firstMoveRestriction := m["first_move_restriction"] == "true"
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, lkey,
		"game_type", battleshipGameType,
		"creator_id", me,
		"status", lobbyStatusWaitingInvite,
		"invite_target_id", oppID,
		"created_at", now,
		"mode", "invite",
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"max_players", "2",
		"player_ids", me,
		"first_move_restriction", strconv.FormatBool(firstMoveRestriction),
		"stake_bronze", strconv.Itoa(stakeBronze),
	)
	pipe.Expire(ctx, lkey, lobbyTTL)
	pipe.SAdd(ctx, invitedKey, oppID)
	pipe.Expire(ctx, invitedKey, lobbyTTL)
	if _, err := pipe.Exec(ctx); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)

	creator, _ := store.GetUserByID(ctx, h.Pool, userID)
	creatorName := "Игрок"
	creatorAvatarKind := ""
	creatorAvatarValue := ""
	if creator != nil {
		if creator.DisplayName != nil && *creator.DisplayName != "" {
			creatorName = *creator.DisplayName
		}
		if creator.AvatarKind != "" {
			creatorAvatarKind = creator.AvatarKind
		}
		if creator.AvatarValue != nil && *creator.AvatarValue != "" {
			creatorAvatarValue = *creator.AvatarValue
		}
	}
	invite := map[string]any{
		"type":                   "game_invite",
		"lobby_id":               lobbyID,
		"creator_id":             me,
		"creator_name":           creatorName,
		"game_type":              battleshipGameType,
		"turn_time_sec":          turnTimeSec,
		"max_players":            2,
		"stake_bronze":           stakeBronze,
		"first_move_restriction": firstMoveRestriction,
	}
	if creatorAvatarKind != "" {
		invite["creator_avatar_kind"] = creatorAvatarKind
	}
	if creatorAvatarValue != "" {
		invite["creator_avatar_value"] = creatorAvatarValue
	}
	h.broadcast([]uuid.UUID{invitee}, invite)
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"lobby_id": lobbyID,
		"status":   lobbyStatusWaitingInvite,
		"matched":  false,
	})
}

func (h *GamesHandler) healBattleshipIfAllSunk(ctx context.Context, gameID string, m map[string]string) {
	if m["status"] != gameStatusActive {
		return
	}
	p1Ships, _ := battleship.ParseShipsJSON(m["p1_ships"])
	p2Ships, _ := battleship.ParseShipsJSON(m["p2_ships"])
	p1Shots, _ := battleship.ParseShotsJSON(m["p1_shots"])
	p2Shots, _ := battleship.ParseShotsJSON(m["p2_shots"])
	winner := ""
	if battleship.AllSunk(p2Ships, p1Shots) && len(p2Ships) > 0 {
		winner = m["p1_user_id"]
	} else if battleship.AllSunk(p1Ships, p2Shots) && len(p1Ships) > 0 {
		winner = m["p2_user_id"]
	}
	if winner == "" {
		return
	}
	key := "game:" + gameID
	h.Rdb.HSet(ctx, key, "status", battleshipStatusOver, "winner", winner)
	m["status"] = battleshipStatusOver
	m["winner"] = winner
	h.finishBattleshipGame(ctx, gameID, m, "normal")
}

// applyBattleshipTimeout — setup: авто-расстановка; battle: проигрыш по таймеру.
func (h *GamesHandler) applyBattleshipTimeout(ctx context.Context, gameID string, m map[string]string) bool {
	if m == nil || m["status"] != gameStatusActive || m["game_type"] != battleshipGameType {
		return false
	}
	key := "game:" + gameID
	now := time.Now().UTC().Unix()

	if m["phase"] == battleshipPhaseSetup {
		dlRaw := m["setup_deadline"]
		if dlRaw == "" {
			return false
		}
		dl, err := strconv.ParseInt(dlRaw, 10, 64)
		if err != nil || dl <= 0 || now < dl {
			return false
		}
		changed := false
		for _, side := range []string{"p1", "p2"} {
			if m[side+"_ready"] == "true" {
				continue
			}
			if isBot(m[side+"_user_id"]) {
				continue
			}
			// Текущая (уже сохранённая) валидная расстановка — иначе дефолтная.
			ships, err := battleship.ParseShipsJSON(m[side+"_ships"])
			if err != nil || battleship.ValidateShips(ships) != nil {
				ships = battleship.DefaultShips()
			}
			sj := battleship.ShipsToJSON(ships)
			h.Rdb.HSet(ctx, key, side+"_ships", sj, side+"_ready", "true")
			m[side+"_ships"] = sj
			m[side+"_ready"] = "true"
			changed = true
		}
		if !changed {
			return false
		}
		if m["p1_ready"] == "true" && m["p2_ready"] == "true" {
			h.beginBattleshipBattle(ctx, gameID, m)
			m, _ = h.Rdb.HGetAll(ctx, key).Result()
		}
		h.broadcastBattleshipState(ctx, gameID, m)
		return true
	}

	if m["phase"] != battleshipPhaseBattle {
		return false
	}
	dlRaw := m["turn_deadline"]
	if dlRaw == "" {
		return false
	}
	dl, err := strconv.ParseInt(dlRaw, 10, 64)
	if err != nil || dl <= 0 || now < dl {
		return false
	}
	turn := m["turn"]
	side := battleshipSide(m, turn)
	if side == "" {
		return false
	}
	opp := battleshipOpponentSide(side)
	winner := m[opp+"_user_id"]
	h.Rdb.HSet(ctx, key,
		"status", battleshipStatusOver,
		"winner", winner,
		"timeout", "1",
	)
	m["status"] = battleshipStatusOver
	m["winner"] = winner
	m["timeout"] = "1"
	h.finishBattleshipGame(ctx, gameID, m, "timeout")
	h.broadcastBattleshipState(ctx, gameID, m)
	return true
}

func (h *GamesHandler) finishBattleshipGame(ctx context.Context, gameID string, m map[string]string, finishReason string) {
	// Останавливаем таймеры хода/расстановки — клиент сразу скрывает countdown.
	key := "game:" + gameID
	h.Rdb.HSet(ctx, key, "turn_deadline", "0", "setup_deadline", "0")
	m["turn_deadline"] = "0"
	m["setup_deadline"] = "0"

	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	h.settleBattleshipCoins(ctx, m, stakeBronze)
	for _, uid := range []string{m["p1_user_id"], m["p2_user_id"]} {
		if uid == "" || isBot(uid) {
			continue
		}
		if u, err := uuid.Parse(uid); err == nil {
			_ = store.IncrementGamesFinished(ctx, h.Pool, u)
			unlocked, _ := store.EvaluateAndUnlock(ctx, h.Pool, u)
			notifyAchievementUnlocks(h.Push, u, unlocked)
		}
	}
	winner := m["winner"]
	if winner != "" && !isBot(winner) {
		if u, err := uuid.Parse(winner); err == nil {
			_ = store.IncrementWinsByStake(ctx, h.Pool, u, stakeBronze)
			unlocked, _ := store.EvaluateAndUnlock(ctx, h.Pool, u)
			notifyAchievementUnlocks(h.Push, u, unlocked)
		}
	}
	h.recordBattleshipResult(ctx, gameID, m, stakeBronze, finishReason)
	clearUsersFinishedGame(ctx, h.Rdb, battleshipHumans(m), gameID)
}

func (h *GamesHandler) settleBattleshipCoins(ctx context.Context, m map[string]string, stakeBronze int) {
	if stakeBronze <= 0 {
		return
	}
	p1, p2 := m["p1_user_id"], m["p2_user_id"]
	if p1 == "" || p2 == "" {
		return
	}
	status := ""
	winner := m["winner"]
	switch winner {
	case p1:
		status = gameStatusXWon
	case p2:
		status = gameStatusOWon
	default:
		status = gameStatusDraw
	}
	h.settleGameCoins(ctx, p1, p2, stakeBronze, status)
}

func (h *GamesHandler) recordBattleshipResult(ctx context.Context, gameID string, m map[string]string, stakeBronze int, finishReason string) {
	p1, p2 := m["p1_user_id"], m["p2_user_id"]
	result := "draw"
	var winnerID string
	switch m["winner"] {
	case p1:
		result = "x_won"
		winnerID = p1
	case p2:
		result = "o_won"
		winnerID = p2
	}
	gr := store.GameResult{
		GameID:       gameID,
		GameType:     battleshipGameType,
		Result:       result,
		FinishReason: finishReason,
		GridSize:     battleship.BoardSize,
		StakeBronze:  stakeBronze,
		AgainstBot:   isBot(p1) || isBot(p2),
	}
	if u, err := uuid.Parse(p1); err == nil {
		gr.XUserID = u
	}
	if u, err := uuid.Parse(p2); err == nil {
		gr.OUserID = u
	}
	if winnerID != "" && !isBot(winnerID) {
		if w, err := uuid.Parse(winnerID); err == nil {
			gr.WinnerUserID = &w
		}
	}
	if t, ok := parseGameStartedAt(m["started_at"]); ok {
		gr.DurationSec = clampNonNegative(int(time.Since(t).Seconds()))
	}
	_ = store.RecordGameResult(ctx, h.Pool, gr)
}

func (h *GamesHandler) broadcastBattleshipState(ctx context.Context, gameID string, m map[string]string) {
	humans := battleshipHumans(m)
	for _, u := range humans {
		view := h.battleshipViewFor(ctx, m, gameID, u.String())
		payload := map[string]any{
			"type":      "game_state",
			"game_id":   gameID,
			"game_type": battleshipGameType,
		}
		for k, v := range view {
			payload[k] = v
		}
		h.broadcast([]uuid.UUID{u}, payload)
	}
}

func (h *GamesHandler) battleshipViewFor(ctx context.Context, m map[string]string, gameID, viewer string) map[string]any {
	side := battleshipSide(m, viewer)
	opp := battleshipOpponentSide(side)
	myShips, _ := battleship.ParseShipsJSON(m[side+"_ships"])
	myShots, _ := battleship.ParseShotsJSON(m[side+"_shots"])
	oppShots, _ := battleship.ParseShotsJSON(m[opp+"_shots"])
	oppShips, _ := battleship.ParseShipsJSON(m[opp+"_ships"])

	status := m["status"]
	if status == battleshipStatusOver {
		status = battleshipStatusOver
	}
	isMyTurn := status == gameStatusActive &&
		m["phase"] == battleshipPhaseBattle &&
		m["turn"] == viewer
	out := map[string]any{
		"id":                     gameID,
		"game_type":              battleshipGameType,
		"phase":                  m["phase"],
		"status":                 status,
		"p1_user_id":             m["p1_user_id"],
		"p2_user_id":             m["p2_user_id"],
		"p1_ready":               m["p1_ready"] == "true",
		"p2_ready":               m["p2_ready"] == "true",
		"turn":                   m["turn"],
		"is_my_turn":             isMyTurn,
		"turn_time_sec":          atoiDefault(m["turn_time_sec"], 0),
		"stake_bronze":           atoiDefault(m["stake_bronze"], 0),
		"first_move_restriction": m["first_move_restriction"] == "true",
		"my_side":                side,
		"my_ships":               myShips,
		"my_shots":               myShots,
		"my_hits":                battleship.CollectHitCells(oppShips, myShots),
		"opponent_shots":         oppShots,
		"lobby_id":               m["lobby_id"],
		"last_shot":              atoiDefault(m["last_shot"], -1),
		"last_shot_hit":          m["last_shot_hit"] == "true",
		"last_shot_by":           m["last_shot_by"],
		"draw_offer_by":          strings.TrimSpace(m["draw_offer_by"]),
		"draw":                   m["draw"] == "1",
	}
	if status == battleshipStatusOver {
		out["turn_deadline"] = 0
		out["setup_deadline"] = 0
	} else {
		if dl := m["turn_deadline"]; dl != "" {
			if n, e := strconv.ParseInt(dl, 10, 64); e == nil {
				out["turn_deadline"] = n
			}
		}
		if dl := m["setup_deadline"]; dl != "" {
			if n, e := strconv.ParseInt(dl, 10, 64); e == nil {
				out["setup_deadline"] = n
			}
		}
	}
	if m["winner"] != "" {
		out["winner"] = m["winner"]
	}
	if m["forfeit"] == "1" {
		out["forfeit"] = true
	}
	if m["timeout"] == "1" {
		out["timeout"] = true
	}
	// Потопленные клетки/корабли соперника видны всегда; полный флот — только после конца.
	out["opponent_ships_hit"] = battleship.CollectSunkCells(oppShips, myShots)
	out["opponent_sunk_ships"] = battleship.CollectSunkShips(oppShips, myShots)
	if status == battleshipStatusOver {
		out["opponent_ships"] = oppShips
	}
	h.addGamePlayerMetadataFromMap(ctx, out, map[string]string{
		"p1": m["p1_user_id"],
		"p2": m["p2_user_id"],
	})
	return out
}

func atoiDefault(s string, def int) int {
	if s == "" {
		return def
	}
	n, err := strconv.Atoi(s)
	if err != nil {
		return def
	}
	return n
}
