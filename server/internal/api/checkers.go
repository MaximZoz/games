package api

import (
	"context"
	"encoding/json"
	"math/rand"
	"net/http"
	"strconv"
	"strings"
	"time"

	"multigames/server/internal/checkers"
	"multigames/server/internal/store"

	"github.com/google/uuid"
)

func checkersSpec() simple1v1 {
	return simple1v1{
		gameType:      store.GameTypeCheckers,
		botID:         checkers.BotID,
		normalizeMode: checkers.NormalizeMode,
		newState: func(mode string) (string, int, error) {
			g := checkers.NewGame(mode)
			raw, err := checkers.Encode(g)
			return raw, g.Turn, err
		},
		isOver: func(encoded string) bool {
			g, err := checkers.Decode(encoded)
			return err == nil && g.IsOver()
		},
		winner: func(encoded string) int {
			g, err := checkers.Decode(encoded)
			if err != nil {
				return checkers.WinnerNone
			}
			return g.Winner
		},
		isBotTurn: func(encoded string, players []string) bool {
			g, err := checkers.Decode(encoded)
			if err != nil || g.IsOver() || g.Turn < 0 || g.Turn >= len(players) {
				return false
			}
			return isBot(players[g.Turn])
		},
	}
}

func (h *GamesHandler) serveCheckers(w http.ResponseWriter, r *http.Request) {
	s := checkersSpec()
	path := strings.TrimPrefix(r.URL.Path, "/api/games/checkers/")
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
				h.getCheckersGame(w, r, gameID)
			case len(parts) == 3 && parts[2] == "move" && r.Method == http.MethodPost:
				h.checkersMove(w, r, gameID)
			case len(parts) == 3 && parts[2] == "forfeit" && r.Method == http.MethodPost:
				h.checkersForfeit(w, r, gameID)
			case len(parts) == 3 && parts[2] == "draw" && r.Method == http.MethodPost:
				h.OfferDraw(w, r, gameID)
			case len(parts) == 3 && parts[2] == "accept-draw" && r.Method == http.MethodPost:
				h.acceptSimple1v1Draw(s, func(enc string) (string, error) {
					g, err := checkers.Decode(enc)
					if err != nil {
						return "", err
					}
					g.AgreeDraw()
					return checkers.Encode(g)
				}, w, r, gameID)
			default:
				WriteErr(w, r, http.StatusNotFound, "not found")
			}
		})
	default:
		WriteErr(w, r, http.StatusNotFound, "not found")
	}
}

func (h *GamesHandler) applyCheckersTimeout(ctx context.Context, gameID string, m map[string]string) bool {
	return h.applySimple1v1Timeout(ctx, checkersSpec(), gameID, m, func(enc string, seat int) (string, error) {
		g, err := checkers.Decode(enc)
		if err != nil {
			return "", err
		}
		g.Forfeit(seat)
		return checkers.Encode(g)
	})
}

func (h *GamesHandler) getCheckersGame(w http.ResponseWriter, r *http.Request, gameID string) {
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
	if m["game_type"] != store.GameTypeCheckers {
		WriteErr(w, r, http.StatusBadRequest, "wrong game type")
		return
	}
	s := checkersSpec()
	h.applySimple1v1Timeout(ctx, s, gameID, m, func(enc string, seat int) (string, error) {
		g, err := checkers.Decode(enc)
		if err != nil {
			return "", err
		}
		g.Forfeit(seat)
		return checkers.Encode(g)
	})
	m, _ = h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
	state, err := checkers.Decode(m["state"])
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "bad state")
		return
	}
	if m["status"] == gameStatusActive && s.isBotTurn(m["state"], parsePlayerIDsCSV(m["player_ids"])) {
		h.scheduleCheckersBot(gameID)
	}
	writeJSON(w, http.StatusOK, h.checkersView(ctx, state, userID.String(), m, gameID))
}

func (h *GamesHandler) checkersMove(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body checkers.Move
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	if err := h.applyCheckersAction(r.Context(), gameID, userID, "move", body); err != nil {
		h.writeSimple1v1ActionError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true})
}

func (h *GamesHandler) checkersForfeit(w http.ResponseWriter, r *http.Request, gameID string) {
	userID, ok := currentUserIDFromGames(r)
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	if err := h.applyCheckersAction(r.Context(), gameID, userID, "forfeit", checkers.Move{}); err != nil {
		h.writeSimple1v1ActionError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "forfeit": true})
}

func (h *GamesHandler) applyCheckersAction(ctx context.Context, gameID string, userID uuid.UUID, action string, mv checkers.Move) error {
	s := checkersSpec()
	key := "game:" + gameID
	m, err := h.Rdb.HGetAll(ctx, key).Result()
	if err != nil || len(m) == 0 {
		return &simple1v1HTTPError{status: http.StatusNotFound, msg: "game not found"}
	}
	if m["game_type"] != store.GameTypeCheckers {
		return &simple1v1HTTPError{status: http.StatusBadRequest, msg: "wrong game type"}
	}
	h.applySimple1v1Timeout(ctx, s, gameID, m, func(enc string, seat int) (string, error) {
		g, err := checkers.Decode(enc)
		if err != nil {
			return "", err
		}
		g.Forfeit(seat)
		return checkers.Encode(g)
	})
	m, _ = h.Rdb.HGetAll(ctx, key).Result()
	if m["status"] != gameStatusActive {
		return &simple1v1HTTPError{status: http.StatusBadRequest, msg: "game is over"}
	}
	state, err := checkers.Decode(m["state"])
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
	encoded, err := checkers.Encode(state)
	if err != nil {
		return err
	}
	h.saveSimple1v1State(ctx, s, gameID, m, encoded, state.Turn, state.IsOver())
	if action == "forfeit" {
		h.Rdb.HSet(ctx, key, "forfeit", "1")
	}
	h.broadcastCheckers(gameID, m)
	if state.IsOver() {
		reason := "normal"
		if action == "forfeit" {
			reason = "forfeit"
		}
		h.onSimple1v1Finished(ctx, s, gameID, m, reason)
	} else if state.Turn != turnBefore || isBot(players[state.Turn]) {
		h.notifyCheckersTurn(gameID, state, players)
	}
	return nil
}

func (h *GamesHandler) notifyCheckersTurn(gameID string, state *checkers.Game, players []string) {
	if state == nil || state.IsOver() {
		return
	}
	if state.Turn < 0 || state.Turn >= len(players) {
		return
	}
	if isBot(players[state.Turn]) {
		h.scheduleCheckersBot(gameID)
		return
	}
	h.notifyYourTurnUser(gameID, players[state.Turn], store.GameTypeCheckers)
}

func (h *GamesHandler) scheduleCheckersBot(gameID string) {
	go func() {
		time.Sleep(500 * time.Millisecond)
		_ = h.withGameLock(context.Background(), gameID, func(ctx context.Context) error {
			m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
			if err != nil || m["status"] != gameStatusActive {
				return nil
			}
			state, err := checkers.Decode(m["state"])
			if err != nil || state.IsOver() {
				return nil
			}
			players := parsePlayerIDsCSV(m["player_ids"])
			if !isBot(players[state.Turn]) {
				return nil
			}
			mv, ok := checkers.PickMove(state, rand.New(rand.NewSource(time.Now().UnixNano())))
			if !ok {
				return nil
			}
			if err := state.Apply(state.Turn, mv); err != nil {
				return nil
			}
			encoded, err := checkers.Encode(state)
			if err != nil {
				return nil
			}
			s := checkersSpec()
			h.saveSimple1v1State(ctx, s, gameID, m, encoded, state.Turn, state.IsOver())
			h.broadcastCheckers(gameID, m)
			if state.IsOver() {
				h.onSimple1v1Finished(ctx, s, gameID, m, "normal")
				return nil
			}
			if isBot(players[state.Turn]) {
				h.scheduleCheckersBot(gameID)
				return nil
			}
			h.notifyCheckersTurn(gameID, state, players)
			return nil
		})
	}()
}

func (h *GamesHandler) broadcastCheckers(gameID string, m map[string]string) {
	ctx := context.Background()
	if fresh, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result(); err == nil && len(fresh) > 0 {
		m = fresh
	}
	state, err := checkers.Decode(m["state"])
	if err != nil {
		return
	}
	for _, u := range simple1v1Humans(parsePlayerIDsCSV(m["player_ids"])) {
		view := h.checkersView(ctx, state, u.String(), m, gameID)
		view["type"] = "game_state"
		h.broadcast([]uuid.UUID{u}, view)
	}
}

func (h *GamesHandler) checkersView(ctx context.Context, state *checkers.Game, viewer string, m map[string]string, gameID string) map[string]any {
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
				"from":   mv.From,
				"to":     mv.To,
				"jumped": mv.Jumped,
			})
		}
	}
	return map[string]any{
		"id":             gameID,
		"game_id":        gameID,
		"game_type":      store.GameTypeCheckers,
		"lobby_id":       m["lobby_id"],
		"game_mode":      checkers.NormalizeMode(state.Mode),
		"board":          state.Board,
		"turn":           state.Turn,
		"seq":            state.Seq,
		"must_continue":  state.MustContinue,
		"cont_r":         state.ContR,
		"cont_c":         state.ContC,
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
		"stake_bronze":   stakeBronze,
		"status":         status,
		"is_over":        over,
		"winner_index":   state.Winner,
		"winner_user_id": winnerID,
		"is_draw":        state.Winner == checkers.WinnerDraw,
		"draw_reason":    state.DrawReason,
		"is_forfeit":     m["forfeit"] == "1" && over,
		"is_timeout":     m["timeout"] == "1",
		"draw_offer_by":  m["draw_offer_by"],
	}
}
