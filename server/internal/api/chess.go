package api

import (
	"context"
	"encoding/json"
	"math/rand"
	"net/http"
	"strconv"
	"strings"
	"time"

	"multigames/server/internal/chess"
	"multigames/server/internal/store"

	"github.com/google/uuid"
)

func chessSpec() simple1v1 {
	return simple1v1{
		gameType:      store.GameTypeChess,
		botID:         chess.BotID,
		normalizeMode: chess.NormalizeMode,
		newState: func(mode string) (string, int, error) {
			g := chess.NewGame(mode)
			raw, err := chess.Encode(g)
			return raw, g.Turn, err
		},
		isOver: func(encoded string) bool {
			g, err := chess.Decode(encoded)
			return err == nil && g.IsOver()
		},
		winner: func(encoded string) int {
			g, err := chess.Decode(encoded)
			if err != nil {
				return chess.WinnerNone
			}
			return g.Winner
		},
		isBotTurn: func(encoded string, players []string) bool {
			g, err := chess.Decode(encoded)
			if err != nil || g.IsOver() || g.Turn < 0 || g.Turn >= len(players) {
				return false
			}
			return isBot(players[g.Turn])
		},
		extraFields: chessClockInitFields,
	}
}

// chessClockBudgetMs — контроль времени по режиму: база и прибавка на ход (мс).
// classic 60+0, rapid 10+0, blitz 5+0, bullet 3+2.
func chessClockBudgetMs(mode string) (base int64, inc int64) {
	switch chess.NormalizeMode(mode) {
	case "rapid":
		return 10 * 60 * 1000, 0
	case "blitz":
		return 5 * 60 * 1000, 0
	case "bullet":
		return 3 * 60 * 1000, 2 * 1000
	default:
		return 60 * 60 * 1000, 0
	}
}

// chessClockInitFields — поля часов в игровом хеше при старте партии.
func chessClockInitFields(mode string) []any {
	base, inc := chessClockBudgetMs(mode)
	now := time.Now().UTC().UnixMilli()
	return []any{
		"clock_ms_0", strconv.FormatInt(base, 10),
		"clock_ms_1", strconv.FormatInt(base, 10),
		"clock_inc_ms", strconv.FormatInt(inc, 10),
		"clock_ts", strconv.FormatInt(now, 10),
	}
}

// chessClockPresent — у партии включены часы (новые партии).
func chessClockPresent(m map[string]string) bool {
	return m["clock_ts"] != ""
}

// chessApplyMoveClock обновляет в m часы ходившего игрока: вычитает затраченное
// время, добавляет прибавку и переносит отметку времени на начало хода соперника.
// Возвращает поля для записи в Redis.
func chessApplyMoveClock(m map[string]string, mover int, now int64) []any {
	if !chessClockPresent(m) {
		return nil
	}
	ts, _ := strconv.ParseInt(m["clock_ts"], 10, 64)
	inc, _ := strconv.ParseInt(m["clock_inc_ms"], 10, 64)
	key := "clock_ms_" + strconv.Itoa(mover)
	cur, _ := strconv.ParseInt(m[key], 10, 64)
	if ts == 0 {
		ts = now
	}
	rem := cur - (now - ts)
	if rem < 0 {
		rem = 0
	}
	rem += inc
	m[key] = strconv.FormatInt(rem, 10)
	m["clock_ts"] = strconv.FormatInt(now, 10)
	return []any{key, m[key], "clock_ts", m["clock_ts"]}
}

// applyChessClockTimeout — поражение по общему времени: если у игрока, чей ход,
// закончилось время, он проигрывает. Возвращает true, если партия завершена.
func (h *GamesHandler) applyChessClockTimeout(ctx context.Context, gameID string, m map[string]string) bool {
	if m["status"] != gameStatusActive || !chessClockPresent(m) {
		return false
	}
	state, err := chess.Decode(m["state"])
	if err != nil || state.IsOver() || state.Turn < 0 {
		return false
	}
	seat := state.Turn
	ts, _ := strconv.ParseInt(m["clock_ts"], 10, 64)
	cur, _ := strconv.ParseInt(m["clock_ms_"+strconv.Itoa(seat)], 10, 64)
	if ts == 0 {
		return false
	}
	now := time.Now().UTC().UnixMilli()
	if cur-(now-ts) > 0 {
		return false
	}
	state.Forfeit(seat)
	encoded, err := chess.Encode(state)
	if err != nil {
		return false
	}
	s := chessSpec()
	m["clock_ms_"+strconv.Itoa(seat)] = "0"
	m["timeout"] = "1"
	h.Rdb.HSet(ctx, "game:"+gameID, "clock_ms_"+strconv.Itoa(seat), "0", "timeout", "1")
	h.saveSimple1v1State(ctx, s, gameID, m, encoded, state.Turn, true)
	h.broadcastChess(gameID, m)
	h.onSimple1v1Finished(ctx, s, gameID, m, "timeout")
	return true
}

func (h *GamesHandler) serveChess(w http.ResponseWriter, r *http.Request) {
	s := chessSpec()
	path := strings.TrimPrefix(r.URL.Path, "/api/games/chess/")
	parts := strings.Split(path, "/")
	switch {
	case path == "active" && r.Method == http.MethodGet:
		h.GetActive(w, r)
	case path == "lobby" && r.Method == http.MethodPost:
		h.createSimple1v1Lobby(s, w, r)
	case path == "lobbies" && r.Method == http.MethodGet:
		h.ListLobbies(w, r)
	case path == "rematch" && r.Method == http.MethodPost:
		h.rematchSimple1v1(s, w, r)
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
			h.joinSimple1v1Lobby(s, w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "leave" && r.Method == http.MethodPost:
			h.LeaveLobby(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "decline" && r.Method == http.MethodPost:
			h.DeclineInvite(w, r, lobbyID)
		case len(parts) == 3 && parts[2] == "matchmake" && r.Method == http.MethodPost:
			h.StartLobbyMatchmake(w, r, lobbyID)
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
		h.callGame(w, r, gameID, func(w http.ResponseWriter, r *http.Request) {
			switch {
			case len(parts) == 2 && r.Method == http.MethodGet:
				h.getChessGame(w, r, gameID)
			case len(parts) == 3 && parts[2] == "move" && r.Method == http.MethodPost:
				h.chessMove(w, r, gameID)
			case len(parts) == 3 && parts[2] == "forfeit" && r.Method == http.MethodPost:
				h.chessForfeit(w, r, gameID)
			case len(parts) == 3 && parts[2] == "draw" && r.Method == http.MethodPost:
				h.OfferDraw(w, r, gameID)
			case len(parts) == 3 && parts[2] == "accept-draw" && r.Method == http.MethodPost:
				h.acceptSimple1v1Draw(s, func(enc string) (string, error) {
					g, err := chess.Decode(enc)
					if err != nil {
						return "", err
					}
					g.AgreeDraw()
					return chess.Encode(g)
				}, w, r, gameID)
			default:
				WriteErr(w, r, http.StatusNotFound, "not found")
			}
		})
	default:
		WriteErr(w, r, http.StatusNotFound, "not found")
	}
}

func (h *GamesHandler) applyChessTimeout(ctx context.Context, gameID string, m map[string]string) bool {
	done := h.applySimple1v1Timeout(ctx, chessSpec(), gameID, m, func(enc string, seat int) (string, error) {
		g, err := chess.Decode(enc)
		if err != nil {
			return "", err
		}
		g.Forfeit(seat)
		return chess.Encode(g)
	})
	if done {
		return true
	}
	return h.applyChessClockTimeout(ctx, gameID, m)
}

func (h *GamesHandler) getChessGame(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	ctx := r.Context()
	m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
	if err != nil || len(m) == 0 {
		WriteErr(w, r, http.StatusNotFound, "game not found")
		return
	}
	if m["game_type"] != store.GameTypeChess {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	s := chessSpec()
	h.applyChessTimeout(ctx, gameID, m)
	m, _ = h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
	state, err := chess.Decode(m["state"])
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "bad state")
		return
	}
	if m["status"] == gameStatusActive && s.isBotTurn(m["state"], parsePlayerIDsCSV(m["player_ids"])) {
		h.scheduleChessBot(gameID)
	}
	writeJSON(w, http.StatusOK, h.chessView(ctx, state, userID.String(), m, gameID))
}

func (h *GamesHandler) chessMove(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body chess.Move
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	if err := h.applyChessAction(r.Context(), gameID, userID, "move", body); err != nil {
		h.writeSimple1v1ActionError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true})
}

func (h *GamesHandler) chessForfeit(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	if err := h.applyChessAction(r.Context(), gameID, userID, "forfeit", chess.Move{}); err != nil {
		h.writeSimple1v1ActionError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "forfeit": true})
}

func (h *GamesHandler) applyChessAction(ctx context.Context, gameID string, userID uuid.UUID, action string, mv chess.Move) error {
	s := chessSpec()
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		return &simple1v1HTTPError{status: http.StatusNotFound, msg: "game not found"}
	}
	if m["game_type"] != store.GameTypeChess {
		return &simple1v1HTTPError{status: http.StatusBadRequest, msg: "wrong game type"}
	}
	h.applyChessTimeout(ctx, gameID, m)
	m, _ = h.Rdb.HGetAll(ctx, key).Result()
	if m["status"] != gameStatusActive {
		return &simple1v1HTTPError{status: http.StatusBadRequest, msg: "game is over"}
	}
	state, err := chess.Decode(m["state"])
	if err != nil {
		return &simple1v1HTTPError{status: http.StatusInternalServerError, msg: "bad state"}
	}
	players := parsePlayerIDsCSV(m["player_ids"])
	seat := simple1v1SeatOf(players, userID.String())
	if seat < 0 {
		return &simple1v1HTTPError{status: http.StatusForbidden, msg: "not a player"}
	}
	turnBefore := state.Turn
	switch action {
	case "forfeit":
		state.Forfeit(seat)
	case "move":
		if err := state.Apply(seat, mv); err != nil {
			return &simple1v1HTTPError{status: http.StatusBadRequest, msg: err.Error()}
		}
		h.Rdb.HSet(ctx, key, "draw_offer_by", "")
	default:
		return &simple1v1HTTPError{status: http.StatusBadRequest, msg: "unknown action"}
	}
	encoded, err := chess.Encode(state)
	if err != nil {
		return err
	}
	if action == "move" {
		if fields := chessApplyMoveClock(m, seat, time.Now().UTC().UnixMilli()); fields != nil {
			h.Rdb.HSet(ctx, key, fields...)
		}
	}
	h.saveSimple1v1State(ctx, s, gameID, m, encoded, state.Turn, state.IsOver())
	if action == "forfeit" {
		h.Rdb.HSet(ctx, key, "forfeit", "1")
	}
	h.broadcastChess(gameID, m)
	if state.IsOver() {
		reason := "normal"
		if action == "forfeit" {
			reason = "forfeit"
		}
		h.onSimple1v1Finished(ctx, s, gameID, m, reason)
	} else if state.Turn != turnBefore || isBot(players[state.Turn]) {
		h.notifyChessTurn(gameID, state, players)
	}
	return nil
}

func (h *GamesHandler) notifyChessTurn(gameID string, state *chess.Game, players []string) {
	if state == nil || state.IsOver() {
		return
	}
	if state.Turn < 0 || state.Turn >= len(players) {
		return
	}
	if isBot(players[state.Turn]) {
		h.scheduleChessBot(gameID)
		return
	}
	h.notifyYourTurnUser(gameID, players[state.Turn], store.GameTypeChess)
}

func (h *GamesHandler) scheduleChessBot(gameID string) {
	go func() {
		time.Sleep(500 * time.Millisecond)
		_ = h.withGameLock(context.Background(), gameID, func(ctx context.Context) error {
			m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
			if err != nil || m["status"] != gameStatusActive {
				return nil
			}
			state, err := chess.Decode(m["state"])
			if err != nil || state.IsOver() {
				return nil
			}
			players := parsePlayerIDsCSV(m["player_ids"])
			if !isBot(players[state.Turn]) {
				return nil
			}
			mv, ok := chess.PickMove(state, rand.New(rand.NewSource(time.Now().UnixNano())))
			if !ok {
				return nil
			}
			botSeat := state.Turn
			if err := state.Apply(state.Turn, mv); err != nil {
				return nil
			}
			encoded, err := chess.Encode(state)
			if err != nil {
				return nil
			}
			s := chessSpec()
			if fields := chessApplyMoveClock(m, botSeat, time.Now().UTC().UnixMilli()); fields != nil {
				h.Rdb.HSet(ctx, "game:"+gameID, fields...)
			}
			h.saveSimple1v1State(ctx, s, gameID, m, encoded, state.Turn, state.IsOver())
			h.broadcastChess(gameID, m)
			if state.IsOver() {
				h.onSimple1v1Finished(ctx, s, gameID, m, "normal")
				return nil
			}
			if isBot(players[state.Turn]) {
				h.scheduleChessBot(gameID)
				return nil
			}
			h.notifyChessTurn(gameID, state, players)
			return nil
		})
	}()
}

func (h *GamesHandler) broadcastChess(gameID string, m map[string]string) {
	ctx := context.Background()
	if fresh, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result(); err == nil && len(fresh) > 0 {
		m = fresh
	}
	state, err := chess.Decode(m["state"])
	if err != nil {
		return
	}
	for _, u := range simple1v1Humans(parsePlayerIDsCSV(m["player_ids"])) {
		view := h.chessView(ctx, state, u.String(), m, gameID)
		view["type"] = "game_state"
		h.broadcast([]uuid.UUID{u}, view)
	}
}

func (h *GamesHandler) chessView(ctx context.Context, state *chess.Game, viewer string, m map[string]string, gameID string) map[string]any {
	players := parsePlayerIDsCSV(m["player_ids"])
	seat := simple1v1SeatOf(players, viewer)
	turnDeadline, _ := strconv.ParseInt(m["turn_deadline"], 10, 64)
	turnTimeSec, _ := strconv.Atoi(m["turn_time_sec"])
	stakeBronze, _ := strconv.Atoi(m["stake_bronze"])
	over := state.IsOver()
	status := gameStatusActive
	if over {
		status = "over"
	}
	winnerID := ""
	if state.Winner >= 0 && state.Winner < len(players) {
		winnerID = players[state.Winner]
	}
	legal := []map[string]any{}
	if seat == state.Turn && !over {
		for _, mv := range state.LegalMoves() {
			legal = append(legal, map[string]any{
				"from":  mv.From,
				"to":    mv.To,
				"promo": mv.Promo,
			})
		}
	}
	// Шахматные часы: остаток времени на каждого игрока (мс) на момент снимка.
	hasClock := chessClockPresent(m)
	clock0 := int64(-1)
	clock1 := int64(-1)
	clockInc := int64(0)
	clockRunning := -1
	if hasClock {
		clock0, _ = strconv.ParseInt(m["clock_ms_0"], 10, 64)
		clock1, _ = strconv.ParseInt(m["clock_ms_1"], 10, 64)
		clockInc, _ = strconv.ParseInt(m["clock_inc_ms"], 10, 64)
		if !over && state.Turn >= 0 {
			ts, _ := strconv.ParseInt(m["clock_ts"], 10, 64)
			if ts > 0 {
				elapsed := time.Now().UTC().UnixMilli() - ts
				if state.Turn == 0 {
					clock0 -= elapsed
				} else {
					clock1 -= elapsed
				}
			}
			clockRunning = state.Turn
		}
		if clock0 < 0 {
			clock0 = 0
		}
		if clock1 < 0 {
			clock1 = 0
		}
	}
	return map[string]any{
		"id":             gameID,
		"game_id":        gameID,
		"game_type":      store.GameTypeChess,
		"lobby_id":       m["lobby_id"],
		"game_mode":      chess.NormalizeMode(state.Mode),
		"board":          state.Board,
		"turn":           state.Turn,
		"seq":            state.Seq,
		"in_check":       state.InCheck(),
		"last_from_r":    state.LastFromR,
		"last_from_c":    state.LastFromC,
		"last_to_r":      state.LastToR,
		"last_to_c":      state.LastToC,
		"players":        simple1v1PlayerViews(ctx, h, players),
		"player_ids":     players,
		"legal_moves":    legal,
		"my_index":       seat,
		"is_my_turn":     seat >= 0 && seat == state.Turn && !over,
		"turn_time_sec":  turnTimeSec,
		"turn_deadline":  turnDeadline,
		"has_clock":      hasClock,
		"clock_ms_0":     clock0,
		"clock_ms_1":     clock1,
		"clock_inc_ms":   clockInc,
		"clock_running":  clockRunning,
		"stake_bronze":   stakeBronze,
		"status":         status,
		"is_over":        over,
		"winner_index":   state.Winner,
		"winner_user_id": winnerID,
		"is_draw":        state.Winner == chess.WinnerDraw,
		"draw_reason":    state.DrawReason,
		"is_forfeit":     m["forfeit"] == "1" && over,
		"is_timeout":     m["timeout"] == "1",
		"draw_offer_by":  m["draw_offer_by"],
	}
}
