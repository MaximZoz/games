package api

import (
	"context"
	"strconv"
	"time"

	"multigames/server/internal/domino"

	"github.com/google/uuid"
)

func (h *GamesHandler) scheduleDominoBotAct(gameID string) {
	if h.Rdb == nil {
		return
	}
	go func() {
		for {
			time.Sleep(dominoBotDelay)
			lockKey := "domino_bot_lock:" + gameID
			locked, _ := h.Rdb.SetNX(context.Background(), lockKey, "1", 4*time.Second).Result()
			if !locked {
				return
			}
			var stop bool
			err := h.withGameLock(context.Background(), gameID, func(ctx context.Context) error {
				m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
				if err != nil || len(m) == 0 || m["game_type"] != dominoGameType || m["status"] != gameStatusActive {
					stop = true
					return nil
				}
				state, err := domino.Decode(m["state"])
				if err != nil || !dominoCurrentIsBot(state) {
					stop = true
					return nil
				}
				action := domino.BestAction(state, state.Turn)
				if action.Type == "" {
					action = domino.Action{Type: domino.ActionPass}
				}
				if err := state.Apply(action); err != nil {
					botID := state.Players[state.Turn].UserID
					_ = state.Apply(domino.Action{Type: domino.ActionForfeit, Actor: botID})
				}
				h.saveDominoState(ctx, gameID, m, state)
				h.broadcastDominoState(gameID, m)
				if state.IsOver() {
					h.onDominoGameFinished(ctx, gameID, m, state, "normal")
					stop = true
					return nil
				}
				if state.Status == domino.StatusRoundEnd {
					h.scheduleDominoNextRound(gameID)
					stop = true
					return nil
				}
				if !dominoCurrentIsBot(state) {
					h.notifyDominoTurn(gameID, state)
					stop = true
				}
				return nil
			})
			h.Rdb.Del(context.Background(), lockKey)
			if err != nil || stop {
				return
			}
		}
	}()
}

func (h *GamesHandler) scheduleDominoNextRound(gameID string) {
	if h.Rdb == nil {
		return
	}
	go func() {
		time.Sleep(dominoRoundPause)
		lockKey := "domino_next_round_lock:" + gameID
		locked, _ := h.Rdb.SetNX(context.Background(), lockKey, "1", 5*time.Second).Result()
		if !locked {
			return
		}
		defer h.Rdb.Del(context.Background(), lockKey)
		_ = h.withGameLock(context.Background(), gameID, func(ctx context.Context) error {
			m, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
			if err != nil || len(m) == 0 || m["game_type"] != dominoGameType || m["status"] != gameStatusActive {
				return nil
			}
			state, err := domino.Decode(m["state"])
			if err != nil || state.Status != domino.StatusRoundEnd {
				return nil
			}
			if err := state.Apply(domino.Action{Type: domino.ActionNextRound}); err != nil {
				return nil
			}
			h.saveDominoState(ctx, gameID, m, state)
			h.broadcastDominoState(gameID, m)
			h.notifyDominoTurn(gameID, state)
			return nil
		})
	}()
}

func (h *GamesHandler) applyDominoTurnTimeout(ctx context.Context, gameID string, m map[string]string) {
	if m["status"] != gameStatusActive {
		return
	}
	deadline, err := strconv.ParseInt(m["turn_deadline"], 10, 64)
	if err != nil || deadline <= 0 || time.Now().UTC().Unix() < deadline {
		return
	}
	fresh, err := h.Rdb.HGetAll(ctx, "game:"+gameID).Result()
	if err != nil || len(fresh) == 0 || fresh["game_type"] != dominoGameType || fresh["status"] != gameStatusActive {
		return
	}
	freshDeadline, err := strconv.ParseInt(fresh["turn_deadline"], 10, 64)
	if err != nil || freshDeadline != deadline || time.Now().UTC().Unix() < freshDeadline {
		return
	}
	state, err := domino.Decode(fresh["state"])
	if err != nil || state.Status != domino.StatusPlaying {
		return
	}
	if state.Turn < 0 || state.Turn >= len(state.Players) {
		return
	}
	timedOutID := state.Players[state.Turn].UserID
	if err := state.Apply(domino.Action{Type: domino.ActionForfeit, Actor: timedOutID}); err != nil {
		return
	}
	h.saveDominoState(ctx, gameID, fresh, state)
	fresh["timeout"] = "1"
	h.Rdb.HSet(ctx, "game:"+gameID, "timeout", "1")
	if !isBot(timedOutID) && !state.IsOver() {
		if userID, err := uuid.Parse(timedOutID); err == nil {
			moveActiveToObserving(ctx, h.Rdb, userID, gameID)
		}
	}
	h.broadcastDominoState(gameID, fresh)
	if state.IsOver() {
		h.onDominoGameFinished(ctx, gameID, fresh, state, "timeout")
	} else {
		h.notifyDominoTurn(gameID, state)
	}
	for key, value := range fresh {
		m[key] = value
	}
}
