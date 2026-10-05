package api

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"multigames/server/internal/store"

	"github.com/google/uuid"
)

// simple1v1 — общий каркас лобби/партии для 1×1 настолок (шашки, 4 в ряд).
type simple1v1 struct {
	gameType      string
	botID         string
	normalizeMode func(string) string
	newState      func(mode string) (encoded string, turn int, err error)
	isOver        func(encoded string) bool
	winner        func(encoded string) int
	isBotTurn     func(encoded string, players []string) bool
}

func (s simple1v1) lockKey(mode string, turnTimeSec, stakeBronze int) string {
	return fmt.Sprintf("%s_open_lock:%s:%d:%d", s.gameType, mode, turnTimeSec, stakeBronze)
}

type simple1v1CreateBody struct {
	Mode        string `json:"mode"`
	TurnTimeSec int    `json:"turn_time_sec"`
	StakeBronze int    `json:"stake_bronze"`
	GameMode    string `json:"game_mode"`
	VsBot       bool   `json:"vs_bot"`
}

type simple1v1HTTPError struct {
	status int
	msg    string
}

func (e *simple1v1HTTPError) Error() string { return e.msg }

func (h *GamesHandler) writeSimple1v1StartError(w http.ResponseWriter, r *http.Request, err error) {
	switch err {
	case store.ErrStakeNotAllowed:
		WriteErr(w, r, http.StatusForbidden, "stake not unlocked")
	case store.ErrInsufficientFunds:
		WriteErr(w, r, http.StatusPaymentRequired, "insufficient balance")
	default:
		WriteErr(w, r, http.StatusInternalServerError, "server error")
	}
}

func (h *GamesHandler) writeSimple1v1ActionError(w http.ResponseWriter, r *http.Request, err error) {
	if httpErr, ok := err.(*simple1v1HTTPError); ok {
		WriteErr(w, r, httpErr.status, httpErr.msg)
		return
	}
	WriteErr(w, r, http.StatusBadRequest, err.Error())
}

func (h *GamesHandler) createSimple1v1Lobby(s simple1v1, w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body simple1v1CreateBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	ctx := r.Context()
	if h.blockingActiveGameID(ctx, userID) != "" {
		WriteErr(w, r, http.StatusConflict, "finish your current game first")
		return
	}
	mode := strings.ToLower(strings.TrimSpace(body.Mode))
	if mode != "invite" && mode != "matchmake" {
		mode = "invite"
	}
	gameMode := s.normalizeMode(strings.ToLower(strings.TrimSpace(body.GameMode)))
	if !validTurnTimeSec[body.TurnTimeSec] {
		WriteErr(w, r, http.StatusBadRequest, "turn_time_sec must be 0, 20, 60 or 600")
		return
	}
	stakeBronze := body.StakeBronze
	if stakeBronze < 2 {
		stakeBronze = 2
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
		} else {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
		}
		return
	}

	if body.VsBot {
		lobbyID := uuid.New().String()
		h.rememberLobby(lobbyID)
		gameID, err := h.startSimple1v1Game(ctx, s, lobbyID, []string{userID.String(), s.botID}, []uuid.UUID{userID}, gameMode, body.TurnTimeSec, stakeBronze)
		if err != nil {
			h.writeSimple1v1StartError(w, r, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"lobby_id": lobbyID,
			"game_id":  gameID,
			"matched":  true,
		})
		return
	}

	if mode == "matchmake" {
		lockKey := s.lockKey(gameMode, body.TurnTimeSec, stakeBronze)
		if locked, _ := h.Rdb.SetNX(ctx, lockKey, "1", 5*time.Second).Result(); locked {
			defer h.Rdb.Del(ctx, lockKey)
		}
		if existing := h.findOpenSimple1v1Lobby(ctx, s, userID, gameMode, body.TurnTimeSec, stakeBronze); existing != "" {
			h.joinSimple1v1Lobby(s, w, r, existing)
			return
		}
	}

	lobbyID := uuid.New().String()
	h.rememberLobby(lobbyID)
	key := "lobby:" + lobbyID
	now := time.Now().UTC().Format(time.RFC3339Nano)
	status := lobbyStatusWaitingInvite
	if mode == "matchmake" {
		status = lobbyStatusWaitingMatchmake
	}
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key,
		"game_type", s.gameType,
		"creator_id", userID.String(),
		"status", status,
		"created_at", now,
		"mode", mode,
		"turn_time_sec", strconv.Itoa(body.TurnTimeSec),
		"max_players", "2",
		"game_mode", gameMode,
		"variant", gameMode,
		"player_ids", userID.String(),
		"stake_bronze", strconv.Itoa(stakeBronze),
	)
	pipe.Expire(ctx, key, lobbyTTL)
	if _, err := pipe.Exec(ctx); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)
	if mode == "matchmake" {
		h.notifyPublicLobbiesChanged()
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"lobby_id": lobbyID,
		"status":   status,
	})
}

func (h *GamesHandler) findOpenSimple1v1Lobby(
	ctx context.Context,
	s simple1v1,
	userID uuid.UUID,
	gameMode string,
	turnTimeSec, stakeBronze int,
) string {
	keys, _ := h.lobbyHashKeys(ctx)
	for _, key := range keys {
		if strings.HasSuffix(key, ":invited") {
			continue
		}
		m, err := h.Rdb.HGetAll(ctx, key).Result()
		if err != nil || m["game_type"] != s.gameType || m["mode"] != "matchmake" {
			continue
		}
		st := m["status"]
		if st != lobbyStatusWaitingMatchmake && st != lobbyStatusWaitingInvite {
			continue
		}
		if s.normalizeMode(m["game_mode"]) != gameMode {
			continue
		}
		tt, _ := strconv.Atoi(m["turn_time_sec"])
		stakes, _ := strconv.Atoi(m["stake_bronze"])
		if tt != turnTimeSec || stakes != stakeBronze {
			continue
		}
		if m["creator_id"] == userID.String() {
			continue
		}
		players := parsePlayerIDsCSV(m["player_ids"])
		if len(players) >= 2 || stringSliceContains(players, userID.String()) {
			continue
		}
		return strings.TrimPrefix(key, "lobby:")
	}
	return ""
}

func (h *GamesHandler) joinSimple1v1Lobby(s simple1v1, w http.ResponseWriter, r *http.Request, lobbyID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	ctx := r.Context()
	if h.blockingActiveGameID(ctx, userID) != "" {
		WriteErr(w, r, http.StatusConflict, "finish your current game first")
		return
	}
	key := "lobby:" + lobbyID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "lobby not found")
		return
	}
	if m["game_type"] != s.gameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	players := parsePlayerIDsCSV(m["player_ids"])
	if stringSliceContains(players, userID.String()) {
		writeJSON(w, http.StatusOK, map[string]any{
			"lobby_id": lobbyID,
			"joined":   true,
			"game_id":  m["game_id"],
		})
		return
	}
	if len(players) >= 2 || m["status"] == lobbyStatusInGame {
		WriteErr(w, r, http.StatusConflict, "lobby full")
		return
	}
	players = append(players, userID.String())
	h.Rdb.HSet(ctx, key, "player_ids", formatPlayerIDsCSV(players), "opponent_id", userID.String())
	setUserActiveLobby(ctx, h.Rdb, userID, lobbyID)
	h.broadcast(simple1v1Humans(players), map[string]any{
		"type":      "lobby_updated",
		"lobby_id":  lobbyID,
		"game_type": s.gameType,
	})
	if len(players) < 2 {
		writeJSON(w, http.StatusOK, map[string]any{"lobby_id": lobbyID, "joined": true})
		return
	}
	gameMode := s.normalizeMode(m["game_mode"])
	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	humans := simple1v1Humans(players)
	gameID, err := h.startSimple1v1Game(ctx, s, lobbyID, players, humans, gameMode, turnTimeSec, stakeBronze)
	if err != nil {
		h.writeSimple1v1StartError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"lobby_id": lobbyID,
		"game_id":  gameID,
		"joined":   true,
		"matched":  true,
	})
}

func (h *GamesHandler) startSimple1v1Game(
	ctx context.Context,
	s simple1v1,
	lobbyID string,
	playerIDs []string,
	humans []uuid.UUID,
	gameMode string,
	turnTimeSec, stakeBronze int,
) (string, error) {
	if len(playerIDs) != 2 {
		return "", fmt.Errorf("%s: need exactly 2 players", s.gameType)
	}
	if stakeBronze > 0 {
		for _, userID := range humans {
			ok, err := store.UserMayStake(ctx, h.Pool, userID, stakeBronze)
			if err != nil {
				return "", err
			}
			if !ok {
				return "", store.ErrStakeNotAllowed
			}
			if err := h.checkStakeAffordable(ctx, userID, stakeBronze); err != nil {
				return "", err
			}
		}
		if err := store.DeductCoinsMany(ctx, h.Pool, humans, stakeBronze); err != nil {
			return "", err
		}
	}
	refund := func() {
		for _, userID := range humans {
			_ = store.AddCoins(ctx, h.Pool, userID, stakeBronze)
		}
	}
	encoded, turn, err := s.newState(gameMode)
	if err != nil {
		refund()
		return "", err
	}
	gameID := uuid.New().String()
	gameKey := "game:" + gameID
	now := time.Now().UTC()
	turnDeadline := int64(0)
	if turnTimeSec > 0 {
		turnDeadline = now.Unix() + int64(turnTimeSec)
	}
	xID, oID := playerIDs[0], playerIDs[1]
	fields := []any{
		"game_type", s.gameType,
		"status", gameStatusActive,
		"lobby_id", lobbyID,
		"game_mode", gameMode,
		"variant", gameMode,
		"max_players", "2",
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"stake_bronze", strconv.Itoa(stakeBronze),
		"player_ids", strings.Join(playerIDs, ","),
		"x_user_id", xID,
		"o_user_id", oID,
		"state", encoded,
		"turn_deadline", strconv.FormatInt(turnDeadline, 10),
		"turn_actor_idx", strconv.Itoa(turn),
		"started_at", now.Format(time.RFC3339Nano),
	}
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, gameKey, fields...)
	pipe.Expire(ctx, gameKey, 24*time.Hour)
	pipe.HSet(ctx, "lobby:"+lobbyID,
		"status", lobbyStatusInGame,
		"game_id", gameID,
		"game_type", s.gameType,
		"game_mode", gameMode,
		"variant", gameMode,
		"player_ids", strings.Join(playerIDs, ","),
	)
	pipe.Expire(ctx, "lobby:"+lobbyID, 24*time.Hour)
	if _, err := pipe.Exec(ctx); err != nil {
		refund()
		return "", err
	}
	h.notifyAndClearLobbyInvites(ctx, lobbyID)
	h.cleanupInviteLobbyChatMessages(ctx, lobbyID)
	for _, userID := range humans {
		clearUserActiveLobby(ctx, h.Rdb, userID)
		setUserActiveGame(ctx, h.Rdb, userID, gameID)
	}
	h.publishGameStartedTyped(humans, gameID, lobbyID, s.gameType)
	return gameID, nil
}

func (h *GamesHandler) rematchSimple1v1(s simple1v1, w http.ResponseWriter, r *http.Request) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body struct {
		GameID string `json:"game_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	ctx := r.Context()
	m, err := h.Rdb.HGetAll(ctx, "game:"+body.GameID).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	if m["game_type"] != s.gameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	players := parsePlayerIDsCSV(m["player_ids"])
	if !stringSliceContains(players, userID.String()) {
		WriteErr(w, r, http.StatusForbidden, "not a player")
		return
	}
	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	if stakeBronze < 2 {
		stakeBronze = 2
	}
	gameMode := s.normalizeMode(m["game_mode"])
	invitees := make([]string, 0, 1)
	hasBot := false
	for _, playerID := range players {
		if isBot(playerID) {
			hasBot = true
		} else if playerID != userID.String() {
			invitees = append(invitees, playerID)
		}
	}
	if len(invitees) == 0 && hasBot {
		lobbyID := uuid.New().String()
		h.rememberLobby(lobbyID)
		gameID, err := h.startSimple1v1Game(ctx, s, lobbyID, []string{userID.String(), s.botID}, []uuid.UUID{userID}, gameMode, turnTimeSec, stakeBronze)
		if err != nil {
			h.writeSimple1v1StartError(w, r, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"lobby_id": lobbyID,
			"game_id":  gameID,
			"matched":  true,
		})
		return
	}
	if len(invitees) == 0 {
		WriteErr(w, r, http.StatusBadRequest, "no opponents")
		return
	}
	lobbyID, err := h.createSimple1v1InviteLobby(ctx, s, userID, invitees, gameMode, turnTimeSec, stakeBronze)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"lobby_id": lobbyID,
		"status":   lobbyStatusWaitingInvite,
		"matched":  false,
	})
}

func (h *GamesHandler) createSimple1v1InviteLobby(
	ctx context.Context,
	s simple1v1,
	creatorID uuid.UUID,
	invitees []string,
	gameMode string,
	turnTimeSec, stakeBronze int,
) (string, error) {
	lobbyID := uuid.New().String()
	h.rememberLobby(lobbyID)
	key := "lobby:" + lobbyID
	pipe := h.Rdb.Pipeline()
	pipe.HSet(ctx, key,
		"game_type", s.gameType,
		"creator_id", creatorID.String(),
		"status", lobbyStatusWaitingInvite,
		"created_at", time.Now().UTC().Format(time.RFC3339Nano),
		"mode", "invite",
		"turn_time_sec", strconv.Itoa(turnTimeSec),
		"max_players", "2",
		"game_mode", gameMode,
		"variant", gameMode,
		"player_ids", creatorID.String(),
		"stake_bronze", strconv.Itoa(stakeBronze),
		"invite_target_id", invitees[0],
	)
	pipe.Expire(ctx, key, lobbyTTL)
	for _, invitee := range invitees {
		pipe.SAdd(ctx, key+":invited", invitee)
	}
	pipe.Expire(ctx, key+":invited", lobbyTTL)
	if _, err := pipe.Exec(ctx); err != nil {
		return "", err
	}
	h.trackUserInvites(ctx, lobbyID, invitees)
	setUserActiveLobby(ctx, h.Rdb, creatorID, lobbyID)
	h.broadcastSimple1v1Invites(ctx, s, creatorID, invitees, lobbyID, gameMode, turnTimeSec, stakeBronze)
	return lobbyID, nil
}

func (h *GamesHandler) broadcastSimple1v1Invites(
	ctx context.Context,
	s simple1v1,
	creatorID uuid.UUID,
	invitees []string,
	lobbyID, gameMode string,
	turnTimeSec, stakeBronze int,
) {
	creator, _ := store.GetUserByID(ctx, h.Pool, creatorID)
	creatorName := "Игрок"
	creatorAvatarKind := ""
	creatorAvatarValue := ""
	if creator != nil {
		if creator.DisplayName != nil && *creator.DisplayName != "" {
			creatorName = *creator.DisplayName
		}
		creatorAvatarKind = creator.AvatarKind
		if creator.AvatarValue != nil {
			creatorAvatarValue = *creator.AvatarValue
		}
	}
	payload := map[string]any{
		"type":          "game_invite",
		"lobby_id":      lobbyID,
		"creator_id":    creatorID.String(),
		"creator_name":  creatorName,
		"game_type":     s.gameType,
		"game_mode":     gameMode,
		"variant":       gameMode,
		"turn_time_sec": turnTimeSec,
		"max_players":   2,
		"stake_bronze":  stakeBronze,
	}
	if creatorAvatarKind != "" {
		payload["creator_avatar_kind"] = creatorAvatarKind
	}
	if creatorAvatarValue != "" {
		payload["creator_avatar_value"] = creatorAvatarValue
	}
	h.broadcast(simple1v1Humans(invitees), payload)
}

func (h *GamesHandler) applySimple1v1Timeout(ctx context.Context, s simple1v1, gameID string, m map[string]string, forfeitSeat func(encoded string, seat int) (string, error)) bool {
	if m["status"] != gameStatusActive {
		return false
	}
	dl := m["turn_deadline"]
	if dl == "" {
		return false
	}
	deadline, err := strconv.ParseInt(dl, 10, 64)
	if err != nil || deadline <= 0 || time.Now().UTC().Unix() < deadline {
		return false
	}
	actor, _ := strconv.Atoi(m["turn_actor_idx"])
	next, err := forfeitSeat(m["state"], actor)
	if err != nil {
		return false
	}
	m["state"] = next
	m["status"] = "over"
	m["timeout"] = "1"
	m["turn_deadline"] = "0"
	h.Rdb.HSet(ctx, "game:"+gameID,
		"state", next,
		"status", "over",
		"timeout", "1",
		"turn_deadline", "0",
		"turn_actor_idx", "-1",
	)
	h.onSimple1v1Finished(ctx, s, gameID, m, "timeout")
	return true
}

func (h *GamesHandler) saveSimple1v1State(ctx context.Context, s simple1v1, gameID string, m map[string]string, encoded string, turn int, over bool) {
	fields := []any{"state", encoded}
	if over {
		fields = append(fields, "status", "over", "turn_deadline", "0", "turn_actor_idx", "-1")
		m["status"] = "over"
		m["turn_deadline"] = "0"
	} else {
		turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
		deadline := int64(0)
		if turnTimeSec > 0 {
			deadline = time.Now().UTC().Unix() + int64(turnTimeSec)
		}
		fields = append(fields,
			"status", gameStatusActive,
			"turn_deadline", strconv.FormatInt(deadline, 10),
			"turn_actor_idx", strconv.Itoa(turn),
		)
		m["status"] = gameStatusActive
		m["turn_deadline"] = strconv.FormatInt(deadline, 10)
		m["turn_actor_idx"] = strconv.Itoa(turn)
	}
	m["state"] = encoded
	h.Rdb.HSet(ctx, "game:"+gameID, fields...)
	h.Rdb.Expire(ctx, "game:"+gameID, 24*time.Hour)
}

func (h *GamesHandler) onSimple1v1Finished(ctx context.Context, s simple1v1, gameID string, m map[string]string, finishReason string) {
	if h.Rdb == nil {
		return
	}
	processed, err := h.Rdb.HSetNX(ctx, "game:"+gameID, "finished_processed", "1").Result()
	if err != nil || !processed {
		return
	}
	players := parsePlayerIDsCSV(m["player_ids"])
	humans := simple1v1Humans(players)
	clearUsersFinishedGame(ctx, h.Rdb, humans, gameID)
	lobbyID := strings.TrimSpace(m["lobby_id"])
	if lobbyID != "" {
		h.Rdb.Del(ctx, "lobby:"+lobbyID)
		h.forgetLobby(lobbyID)
		h.Rdb.Del(ctx, "lobby:"+lobbyID+":invited")
	}
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	winners := make([]string, 0, 1)
	if win := s.winner(m["state"]); win >= 0 && win < len(players) {
		winners = append(winners, players[win])
	}
	settled, _ := h.Rdb.HSetNX(ctx, "game:"+gameID, "coins_settled", "1").Result()
	if settled {
		_ = store.SettleStakePot(ctx, h.Pool, stakeBronze, players, winners, len(winners) == 0, isBot)
	}
	for _, userID := range humans {
		_ = store.IncrementGamesFinished(ctx, h.Pool, userID)
		unlocked, _ := store.EvaluateAndUnlock(ctx, h.Pool, userID)
		notifyAchievementUnlocks(h.Hub, h.Push, userID, unlocked)
	}
	for _, winnerID := range winners {
		if isBot(winnerID) {
			continue
		}
		if userID, err := uuid.Parse(winnerID); err == nil {
			_ = store.IncrementWinsByStake(ctx, h.Pool, userID, stakeBronze)
			unlocked, _ := store.EvaluateAndUnlock(ctx, h.Pool, userID)
			notifyAchievementUnlocks(h.Hub, h.Push, userID, unlocked)
		}
	}
	h.recordSimple1v1Result(ctx, s, gameID, m, players, winners, stakeBronze, finishReason)
}

func (h *GamesHandler) recordSimple1v1Result(
	ctx context.Context,
	s simple1v1,
	gameID string,
	m map[string]string,
	players, winners []string,
	stakeBronze int,
	finishReason string,
) {
	if len(players) < 2 {
		return
	}
	winnerID := ""
	if len(winners) > 0 {
		winnerID = winners[0]
	}
	durationSec := 0
	if startedAt, ok := parseGameStartedAt(m["started_at"]); ok {
		durationSec = clampNonNegative(int(time.Since(startedAt).Seconds()))
	}
	xID, oID := players[0], players[1]
	result := "draw"
	if winnerID == xID {
		result = "x_won"
	} else if winnerID == oID {
		result = "o_won"
	}
	gameResult := store.GameResult{
		GameID:       gameID,
		GameType:     s.gameType,
		Result:       result,
		FinishReason: finishReason,
		StakeBronze:  stakeBronze,
		DurationSec:  durationSec,
		AgainstBot:   isBot(xID) || isBot(oID),
	}
	if userID, err := uuid.Parse(xID); err == nil {
		gameResult.XUserID = userID
	}
	if userID, err := uuid.Parse(oID); err == nil {
		gameResult.OUserID = userID
	}
	if !isBot(winnerID) {
		if userID, err := uuid.Parse(winnerID); err == nil {
			gameResult.WinnerUserID = &userID
		}
	}
	_ = store.RecordGameResult(ctx, h.Pool, gameResult)
}

func (h *GamesHandler) acceptSimple1v1Draw(s simple1v1, applyDraw func(encoded string) (string, error), w http.ResponseWriter, r *http.Request, gameID string) {
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
	if m["game_type"] != s.gameType {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	players := parsePlayerIDsCSV(m["player_ids"])
	if !stringSliceContains(players, userID.String()) {
		WriteErr(w, r, http.StatusForbidden, "forbidden")
		return
	}
	if m["status"] != gameStatusActive {
		WriteErr(w, r, http.StatusBadRequest, "game is over")
		return
	}
	offerBy := strings.TrimSpace(m["draw_offer_by"])
	if offerBy == "" {
		WriteErr(w, r, http.StatusBadRequest, "no draw offer")
		return
	}
	if offerBy == userID.String() {
		WriteErr(w, r, http.StatusBadRequest, "cannot accept own draw offer")
		return
	}
	next, err := applyDraw(m["state"])
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, err.Error())
		return
	}
	m["state"] = next
	m["status"] = "over"
	h.Rdb.HSet(ctx, key, "state", next, "status", "over", "turn_deadline", "0", "draw_offer_by", "")
	h.onSimple1v1Finished(ctx, s, gameID, m, "draw_agreement")
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "draw": true})
}

func isSimpleBoardGame(gt string) bool {
	return gt == store.GameTypeCheckers
}

func simple1v1SeatOf(players []string, userID string) int {
	for i, p := range players {
		if p == userID {
			return i
		}
	}
	return -1
}

func simple1v1Humans(ids []string) []uuid.UUID {
	out := make([]uuid.UUID, 0, len(ids))
	for _, id := range ids {
		if isBot(id) {
			continue
		}
		if u, err := uuid.Parse(id); err == nil {
			out = append(out, u)
		}
	}
	return out
}

func simple1v1PlayerViews(ctx context.Context, h *GamesHandler, players []string) []map[string]any {
	userIDs := simple1v1Humans(players)
	users, _ := store.GetUsersByIDs(ctx, h.Pool, userIDs)
	frames, _ := store.EquippedFramesMap(ctx, h.Pool, userIDs)
	out := make([]map[string]any, 0, len(players))
	for i, playerID := range players {
		player := map[string]any{
			"user_id":      playerID,
			"seat":         i,
			"display_name": "",
		}
		if isBot(playerID) {
			player["display_name"] = "Бот"
			player["is_bot"] = true
			out = append(out, player)
			continue
		}
		userID, err := uuid.Parse(playerID)
		if err != nil {
			out = append(out, player)
			continue
		}
		if user := users[userID]; user != nil {
			if user.DisplayName != nil && *user.DisplayName != "" {
				player["display_name"] = *user.DisplayName
			}
			if user.AvatarKind != "" {
				player["avatar_kind"] = user.AvatarKind
			}
			if user.AvatarValue != nil {
				player["avatar_value"] = *user.AvatarValue
			}
		}
		if frame, ok := frames[userID]; ok {
			player["frame_code"] = frame.Code
			player["frame_color"] = frame.Color
		}
		out = append(out, player)
	}
	return out
}
