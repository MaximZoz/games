package api

import (
	"context"
	"testing"

	"multigames/server/internal/checkers"
	"multigames/server/internal/store"
)

func TestClassifyCheckersActiveIsNotTictactoe(t *testing.T) {
	g := checkers.NewGame(checkers.ModeRussian)
	raw, err := checkers.Encode(g)
	if err != nil {
		t.Fatal(err)
	}
	hash := map[string]string{
		"game_type":      store.GameTypeCheckers,
		"status":         gameStatusActive,
		"player_ids":     "user-a,user-b",
		"x_user_id":      "user-a",
		"o_user_id":      "user-b",
		"state":          raw,
		"turn_actor_idx": "0",
		"lobby_id":       "lob",
	}
	res, ok := classifyNonTictactoeActive(hash, "user-a")
	if !ok || res.Class != activeClassPlay || res.GameType != store.GameTypeCheckers || !res.MyTurn {
		t.Fatalf("white: ok=%v res=%+v", ok, res)
	}
	res, ok = classifyNonTictactoeActive(hash, "user-b")
	if !ok || res.Class != activeClassPlay || res.MyTurn {
		t.Fatalf("black: ok=%v res=%+v", ok, res)
	}
	res, ok = classifyNonTictactoeActive(hash, "stranger")
	if !ok || res.Class != activeClassClear || res.GameType != store.GameTypeCheckers {
		t.Fatalf("stranger: ok=%v res=%+v", ok, res)
	}
}

func TestClassifyFutureGameKeepsItsType(t *testing.T) {
	hash := map[string]string{
		"game_type":      "reversi",
		"status":         gameStatusActive,
		"player_ids":     "user-a,user-b",
		"turn_actor_idx": "1",
	}
	res, ok := classifyNonTictactoeActive(hash, "user-b")
	if !ok || res.Class != activeClassPlay || res.GameType != "reversi" || !res.MyTurn {
		t.Fatalf("reversi: ok=%v res=%+v", ok, res)
	}
	if _, ok := classifyNonTictactoeActive(map[string]string{
		"game_type": store.GameTypeTicTacToe,
		"status":    gameStatusActive,
	}, "user-a"); ok {
		t.Fatal("tictactoe must stay on the mark path")
	}
}

func TestApplyGameTimeoutSkipsForeignGame(t *testing.T) {
	h := &GamesHandler{}
	m := map[string]string{
		"game_type":     store.GameTypeCheckers,
		"status":        gameStatusActive,
		"turn_deadline": "1",
		"turn":          "",
	}
	if h.applyGameTimeout(context.Background(), "game:chk", m) {
		t.Fatal("checkers timeout must not run tictactoe logic")
	}
	if !tictactoeTimeoutApplies("") || !tictactoeTimeoutApplies(store.GameTypeTicTacToe) {
		t.Fatal("empty and tictactoe still use the tictactoe timeout")
	}
	if tictactoeTimeoutApplies("reversi") || tictactoeTimeoutApplies(store.GameTypeChess) {
		t.Fatal("foreign game_type must skip tictactoe timeout")
	}
}
