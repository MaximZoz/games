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
	b := DefaultUserGameSettings(GameTypeBattleship)
	if b.GameType != GameTypeBattleship || b.TurnTimeSec != 60 || b.GridSize != 10 {
		t.Fatalf("battleship defaults: %+v", b)
	}
	u := DefaultUserGameSettings(GameTypeUno)
	if u.GameType != GameTypeUno || u.TurnTimeSec != 60 || u.MaxPlayers != 2 ||
		u.GameMode != "classic" || u.Variant != "classic" {
		t.Fatalf("uno defaults: %+v", u)
	}
	n := DefaultUserGameSettings(GameTypeNardy)
	if n.GameType != GameTypeNardy || n.TurnTimeSec != 60 || n.MaxPlayers != 2 ||
		n.GameMode != "short" || n.Variant != "short" {
		t.Fatalf("nardy defaults: %+v", n)
	}
	c := DefaultUserGameSettings(GameTypeCheckers)
	if c.GameType != GameTypeCheckers || c.TurnTimeSec != 60 || c.MaxPlayers != 2 ||
		c.GameMode != "russian" || c.Variant != "russian" {
		t.Fatalf("checkers defaults: %+v", c)
	}
}
