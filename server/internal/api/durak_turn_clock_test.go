package api

import (
	"testing"

	"multigames/server/internal/durak"
)

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
