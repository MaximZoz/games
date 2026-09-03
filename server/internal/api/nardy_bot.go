package api

import (
	"context"
	"strconv"
	"time"

	"multigames/server/internal/nardy"

	"github.com/google/uuid"
)

// scheduleNardyBotAct доигрывает ход бота: бросок и все шашки по одной.
func (h *GamesHandler) scheduleNardyBotAct(gameID string) {
	if h.Rdb == nil {
		return
	}
	go func() {
		for {
			time.Sleep(nardyBotDelay)
			ctx := context.Background()
			lockKey := "nardy_bot_lock:" + gameID
			locked, _ := h.Rdb.SetNX(ctx, lockKey, "1", 5*time.Second).Result()
			if !locked {
				return
			}
			m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
			if err != nil || len(m) == 0 || m["game_type"] != nardyGameType ||
				m["status"] != gameStatusActive {
				h.Rdb.Del(ctx, lockKey)
				return
			}
			state, err := nardy.Decode(m["state"])
			players := parsePlayerIDsCSV(m["player_ids"])
			if err != nil || !nardyCurrentPlayerIsBot(state, players) {
				h.Rdb.Del(ctx, lockKey)
				return
			}
			nardyPlayBotTurn(state)
			h.saveNardyState(ctx, gameID, m, state)
			h.broadcastNardyState(gameID, m)
			over := nardyIsOver(state)
			if over {
				h.onNardyGameFinished(ctx, gameID, m, state, "normal")
			}
			h.Rdb.Del(ctx, lockKey)
			if over {
				return
			}
			if !nardyCurrentPlayerIsBot(state, players) {
				h.notifyNardyTurn(gameID, state, players)
				return
			}
		}
	}()
}

// nardyPlayBotTurn играет ровно один ход бота целиком.
func nardyPlayBotTurn(state *nardy.Game) {
	if state == nil || nardyIsOver(state) {
		return
	}
	rng := nardyRNG()
	seat := state.Turn
	if len(state.Dice) == 0 {
		if err := state.Roll(rng); err != nil {
			return
		}
	}
	// Каждый ход снимает кубик, поэтому цикл конечен; лимит — страховка.
	for step := 0; step < 8; step++ {
		if nardyIsOver(state) || state.Turn != seat || len(state.Dice) == 0 {
			return
		}
		mv, ok := nardy.BotBestMove(state, rng)
		if !ok {
			state.EndTurn()
			return
		}
		if err := state.ApplyMove(seat, mv); err != nil {
			state.EndTurn()
			return
		}
	}
}

// applyNardyTurnTimeout — просроченный ход засчитывается как поражение.
func (h *GamesHandler) applyNardyTurnTimeout(
	ctx context.Context,
	gameID string,
	m map[string]string,
) {
	if m["status"] != gameStatusActive {
		return
	}
	deadline, err := strconv.ParseInt(m["turn_deadline"], 10, 64)
	if err != nil || deadline <= 0 || time.Now().UTC().Unix() < deadline {
		return
	}
	fresh, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
	if err != nil || len(fresh) == 0 || fresh["game_type"] != nardyGameType ||
		fresh["status"] != gameStatusActive {
		return
	}
	freshDeadline, err := strconv.ParseInt(fresh["turn_deadline"], 10, 64)
	if err != nil || freshDeadline != deadline || time.Now().UTC().Unix() < freshDeadline {
		return
	}
	state, err := nardy.Decode(fresh["state"])
	if err != nil || nardyIsOver(state) {
		return
	}
	players := parsePlayerIDsCSV(fresh["player_ids"])
	if state.Turn < 0 || state.Turn >= len(players) {
		return
	}
	timedOutID := players[state.Turn]
	state.Forfeit(state.Turn)
	h.saveNardyState(ctx, gameID, fresh, state)
	fresh["timeout"] = "1"
	h.Rdb.HSet(ctx, "game:"+gameID, "timeout", "1")
	if !isBot(timedOutID) && !nardyIsOver(state) {
		if userID, err := uuid.Parse(timedOutID); err == nil {
			moveActiveToObserving(ctx, h.Rdb, userID, gameID)
		}
	}
	h.broadcastNardyState(gameID, fresh)
	if nardyIsOver(state) {
		h.onNardyGameFinished(ctx, gameID, fresh, state, "timeout")
	} else {
		h.notifyNardyTurn(gameID, state, players)
	}
	for key, value := range fresh {
		m[key] = value
	}
}
