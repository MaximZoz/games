package api

import (
	"strings"
	"testing"

	"multigames/server/internal/nardy"
)

func TestNardyMatchmakeKeySplitsModes(t *testing.T) {
	short := nardyMatchmakeLockKey(nardy.ModeShort, 60, 2)
	long := nardyMatchmakeLockKey(nardy.ModeLong, 60, 2)
	if short == long {
		t.Fatalf("short and long lobbies must not share a matchmake key: %q", short)
	}
	if !strings.Contains(short, nardy.ModeShort) {
		t.Fatalf("key %q must carry the game mode", short)
	}
	if nardyMatchmakeLockKey(nardy.ModeShort, 20, 2) == short {
		t.Fatal("turn time must be part of the matchmake key")
	}
	if nardyMatchmakeLockKey(nardy.ModeShort, 60, 10) == short {
		t.Fatal("stake must be part of the matchmake key")
	}
}

func TestNardySeatOf(t *testing.T) {
	players := []string{"alice", nardyBotID}
	if got := nardySeatOf(players, "alice"); got != 0 {
		t.Fatalf("seat of alice = %d", got)
	}
	if got := nardySeatOf(players, nardyBotID); got != 1 {
		t.Fatalf("seat of bot = %d", got)
	}
	if got := nardySeatOf(players, "bob"); got != -1 {
		t.Fatalf("seat of a stranger = %d, want -1", got)
	}
}

func TestNardyCurrentPlayerIsBot(t *testing.T) {
	players := []string{"alice", nardyBotID}
	state := nardy.NewGame(nardy.ModeShort)
	if nardyCurrentPlayerIsBot(state, players) {
		t.Fatal("first turn belongs to the human")
	}
	state.Turn = 1
	if !nardyCurrentPlayerIsBot(state, players) {
		t.Fatal("second seat is the bot")
	}
	state.Winner = 0
	if nardyCurrentPlayerIsBot(state, players) {
		t.Fatal("finished game has no bot turn")
	}
}

func TestNardyHumanUUIDsSkipsBot(t *testing.T) {
	humans := nardyHumanUUIDs([]string{
		"6f1e2f88-0b71-4a35-8f34-2b3f1a0f0001",
		nardyBotID,
		"not-a-uuid",
	})
	if len(humans) != 1 {
		t.Fatalf("humans = %v, want a single parsed user", humans)
	}
}

func TestNardyBotPlaysWholeTurn(t *testing.T) {
	state := nardy.NewGame(nardy.ModeLong)
	state.Turn = 1
	before := state.TurnNo
	nardyPlayBotTurn(state)
	if state.Turn == 1 && !nardyIsOver(state) {
		t.Fatalf("bot must finish its turn, turn=%d dice=%v", state.Turn, state.Dice)
	}
	if state.TurnNo == before && !nardyIsOver(state) {
		t.Fatal("turn counter did not advance")
	}
}

func TestNardyBotTurnRollsWhenDiceEmpty(t *testing.T) {
	state := nardy.NewGame(nardy.ModeShort)
	if len(state.Dice) != 0 {
		t.Fatalf("fresh game must wait for a roll, dice=%v", state.Dice)
	}
	nardyPlayBotTurn(state)
	if len(state.Rolled) == 0 {
		t.Fatal("bot turn must roll the dice")
	}
}

func TestNardyIsOverTracksWinner(t *testing.T) {
	state := nardy.NewGame(nardy.ModeShort)
	if nardyIsOver(state) {
		t.Fatal("fresh game is not over")
	}
	state.Forfeit(0)
	if !nardyIsOver(state) {
		t.Fatal("forfeit must finish the game")
	}
}
