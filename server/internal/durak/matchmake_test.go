package durak

import "testing"

// Проверяем, что параметры лобби, по которым схлопывается matchmake,
// однозначно определяют совместимость двух «Найти игру».
func TestModeParsingIsStable(t *testing.T) {
	cases := map[string]Mode{
		"":            ModePodkidnoi,
		"podkidnoi":   ModePodkidnoi,
		"perevodnoi":  ModePerevodnoi,
		"unknown-val": ModePodkidnoi,
	}
	for in, want := range cases {
		if got := ParseMode(in); got != want {
			t.Fatalf("ParseMode(%q) = %v, want %v", in, got, want)
		}
	}
}

func TestNewRejectsBadConfigs(t *testing.T) {
	if _, err := New([]string{"a"}, 36, ModePodkidnoi, 1); err == nil {
		t.Fatal("expected error for 1 player")
	}
	if _, err := New([]string{"a", "b", "c", "d", "e"}, 36, ModePodkidnoi, 1); err == nil {
		t.Fatal("expected error for 5 players")
	}
	if _, err := New([]string{"a", "b"}, 40, ModePodkidnoi, 1); err == nil {
		t.Fatal("expected error for deck 40")
	}
	if _, err := New([]string{"a", "b", "c"}, 24, ModePodkidnoi, 1); err == nil {
		t.Fatal("deck 24 must reject 3 players")
	}
}

func TestNewAcceptsSupportedConfigs(t *testing.T) {
	configs := []struct {
		players int
		deck    int
		mode    Mode
	}{
		{2, 24, ModePodkidnoi},
		{2, 36, ModePerevodnoi},
		{3, 36, ModePodkidnoi},
		{4, 52, ModePerevodnoi},
	}
	for _, c := range configs {
		ids := make([]string, c.players)
		for i := range ids {
			ids[i] = string(rune('a' + i))
		}
		st, err := New(ids, c.deck, c.mode, 7)
		if err != nil {
			t.Fatalf("New(%d players, deck %d): %v", c.players, c.deck, err)
		}
		if len(st.Hands) != c.players {
			t.Fatalf("hands = %d, want %d", len(st.Hands), c.players)
		}
		for i, h := range st.Hands {
			if len(h) != 6 {
				t.Fatalf("hand[%d] = %d cards, want 6", i, len(h))
			}
		}
		if st.Mode != c.mode {
			t.Fatalf("mode = %v, want %v", st.Mode, c.mode)
		}
	}
}
