package api

import (
	"testing"

	"multigames/server/internal/durak"
)

func TestDurakViewMyTurnFollowsActor(t *testing.T) {
	state := &durak.State{
		PlayerIDs:     []string{"a", "b"},
		Hands:         [][]durak.Card{{}, {}},
		AttackerIndex: 1,
		ThrowerIndex:  1,
		Phase:         durak.PhaseAttack,
		Status:        durak.StatusActive,
		LoserIndex:    -1,
		Mode:          durak.ModePodkidnoi,
	}
	mine := durakViewFor(state, "b", map[string]string{}, "g1")
	if mine["is_my_turn"] != true {
		t.Fatalf("attacker turn: %#v", mine["is_my_turn"])
	}
	other := durakViewFor(state, "a", map[string]string{}, "g1")
	if other["is_my_turn"] != false {
		t.Fatalf("opponent: %#v", other["is_my_turn"])
	}
	state.Status = durak.StatusOver
	over := durakViewFor(state, "b", map[string]string{}, "g1")
	if over["is_my_turn"] != false {
		t.Fatalf("over: %#v", over["is_my_turn"])
	}
}

func TestDurakMayArmTurnClock(t *testing.T) {
	now := int64(1_700_000_000)
	if durakMayArmTurnClock(durak.PhaseTakeReveal, 0, 0, now) {
		t.Fatal("take_reveal must not start a turn clock")
	}
	if durakMayArmTurnClock(durak.PhaseBitoReveal, 0, 0, now) {
		t.Fatal("bito_reveal must not start a turn clock")
	}
	if durakMayArmTurnClock(durak.PhaseDefend, 50, 0, now) {
		t.Fatal("existing deadline must stay")
	}
	if durakMayArmTurnClock(durak.PhaseAttack, 0, now+10, now) {
		t.Fatal("opening deal grace must hold the clock")
	}
	if !durakMayArmTurnClock(durak.PhaseDefend, 0, 0, now) {
		t.Fatal("defend with no deadline should arm")
	}
	if !durakMayArmTurnClock(durak.PhaseTakeFollow, 0, 0, now) {
		t.Fatal("take_follow should arm for the thrower")
	}
}
