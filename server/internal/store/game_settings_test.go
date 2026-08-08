package store

import "testing"

func TestDefaultUserGameSettings(t *testing.T) {
	s := DefaultUserGameSettings("")
	if s.GameType != GameTypeTicTacToe {
		t.Fatalf("game_type=%q", s.GameType)
	}
	if s.TurnTimeSec != 0 || s.GridSize != 3 || s.StakeBronze != 2 {
		t.Fatalf("unexpected defaults: %+v", s)
	}
	if s.SwapRule || s.FirstMoveRestriction {
		t.Fatal("bool defaults must be false")
	}
	d := DefaultUserGameSettings(GameTypeDurak)
	if d.GameType != GameTypeDurak || d.TurnTimeSec != 60 || d.DeckSize != 36 || d.GameMode != "podkidnoi" {
		t.Fatalf("durak defaults: %+v", d)
	}
}
