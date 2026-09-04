package api

import (
	"math/rand"
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
	nardy.PlayBotTurn(state, nardyRNG())
	if state.Turn == 1 && !nardyIsOver(state) {
		t.Fatalf("bot must finish its turn, turn=%d dice=%v", state.Turn, state.Dice)
	}
	if state.TurnNo == before && !nardyIsOver(state) {
		t.Fatal("turn counter did not advance")
	}
}

func TestNardyBotFirstStepIsOnlyTheRoll(t *testing.T) {
	state := nardy.NewGame(nardy.ModeShort)
	if len(state.Dice) != 0 {
		t.Fatalf("fresh game must wait for a roll, dice=%v", state.Dice)
	}
	// Первый шаг — только бросок: клиент должен увидеть кубики до ходов.
	done := nardy.PlayBotStep(state, nardyRNG())
	if len(state.Rolled) == 0 {
		t.Fatal("first bot step must roll the dice")
	}
	if done && state.Turn == 0 && len(state.Dice) > 0 {
		t.Fatal("roll with legal moves must not end the turn")
	}
	if len(state.History) != 0 {
		t.Fatalf("no checker may move on the roll step: %+v", state.History)
	}
}

func TestNardyBotRunKeyIsPerGame(t *testing.T) {
	if nardyBotRunKey("a") == nardyBotRunKey("b") {
		t.Fatal("bot runner lock must be per game")
	}
	if !strings.Contains(nardyBotRunKey("g1"), "g1") {
		t.Fatalf("key %q must carry the game id", nardyBotRunKey("g1"))
	}
	if nardyBotRunTTL <= nardyBotStepDelay {
		t.Fatalf("runner lock (%v) must outlive a single step (%v)",
			nardyBotRunTTL, nardyBotStepDelay)
	}
}

func TestNardyBotTurnTakesSeveralSteps(t *testing.T) {
	state := nardy.NewGame(nardy.ModeShort)
	state.Turn = 1
	rng := rand.New(rand.NewSource(9))
	steps := 0
	for steps < 12 && !nardy.PlayBotStep(state, rng) {
		steps++
	}
	// Бросок и ходы — разные шаги: иначе на экране ход соперника мгновенный.
	if steps < 2 {
		t.Fatalf("bot turn collapsed into %d step(s)", steps+1)
	}
	if state.Turn != 0 && state.Winner < 0 {
		t.Fatalf("bot did not hand the turn back: turn=%d", state.Turn)
	}
}

func TestNardyDeadlineDoesNotResetDuringSameTurn(t *testing.T) {
	const oldDeadline int64 = 1000
	got := nardyNextTurnDeadline(
		60,
		0,
		oldDeadline,
		0,
		2000,
	)
	if got != oldDeadline {
		t.Fatalf("same turn deadline = %d, want %d", got, oldDeadline)
	}
}

func TestNardyDeadlineResetsWhenTurnChanges(t *testing.T) {
	got := nardyNextTurnDeadline(
		60,
		0,
		1000,
		1,
		2000,
	)
	if got != 2060 {
		t.Fatalf("new turn deadline = %d, want 2060", got)
	}
}

func TestNardyDeadlineNoLimitStaysZero(t *testing.T) {
	got := nardyNextTurnDeadline(
		0,
		0,
		1000,
		0,
		2000,
	)
	if got != 0 {
		t.Fatalf("no-limit deadline = %d, want 0", got)
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
