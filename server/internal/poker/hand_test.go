package poker

import "testing"

// cards парсит список строк вида "AH","10S" в карты (для краткости в тестах).
func cards(t *testing.T, ss ...string) []Card {
	t.Helper()
	out := make([]Card, len(ss))
	for i, s := range ss {
		c, err := ParseCardString(s)
		if err != nil {
			t.Fatalf("parse %q: %v", s, err)
		}
		out[i] = c
	}
	return out
}

func TestEvaluateBestCategories(t *testing.T) {
	tests := []struct {
		name string
		cs   []string
		want HandRank
	}{
		{"royal flush", []string{"AH", "KH", "QH", "JH", "TH", "2S", "3D"}, RoyalFlush},
		{"straight flush", []string{"9H", "8H", "7H", "6H", "5H", "2S", "AD"}, StraightFlush},
		{"wheel straight flush", []string{"AH", "2H", "3H", "4H", "5H", "KS", "QD"}, StraightFlush},
		{"four of a kind", []string{"9H", "9D", "9C", "9S", "5H", "2S", "AD"}, FourOfAKind},
		{"full house", []string{"9H", "9D", "9C", "5S", "5H", "2S", "AD"}, FullHouse},
		{"flush", []string{"AH", "JH", "9H", "5H", "2H", "9S", "KD"}, Flush},
		{"straight", []string{"9H", "8D", "7C", "6S", "5H", "2S", "AD"}, Straight},
		{"wheel straight", []string{"AH", "2D", "3C", "4S", "5H", "KS", "QD"}, Straight},
		{"three of a kind", []string{"9H", "9D", "9C", "5S", "3H", "2S", "AD"}, ThreeOfAKind},
		{"two pair", []string{"9H", "9D", "5C", "5S", "3H", "2S", "AD"}, TwoPair},
		{"one pair", []string{"9H", "9D", "KC", "5S", "3H", "2S", "AD"}, OnePair},
		{"high card", []string{"9H", "7D", "KC", "5S", "3H", "2S", "AD"}, HighCard},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			v, err := EvaluateBest(cards(t, tt.cs...))
			if err != nil {
				t.Fatalf("eval: %v", err)
			}
			if v.Rank != tt.want {
				t.Fatalf("got %v, want %v", v.Rank, tt.want)
			}
			if len(v.Cards) != 5 {
				t.Fatalf("expected 5 best cards, got %d", len(v.Cards))
			}
		})
	}
}

func TestCompareOrdering(t *testing.T) {
	eval := func(ss ...string) HandValue {
		v, err := EvaluateBest(cards(t, ss...))
		if err != nil {
			t.Fatalf("eval: %v", err)
		}
		return v
	}
	// Стрит-флеш бьёт каре.
	sf := eval("9H", "8H", "7H", "6H", "5H")
	quads := eval("9H", "9D", "9C", "9S", "5H")
	if sf.Compare(quads) <= 0 {
		t.Fatalf("straight flush should beat four of a kind")
	}
	// Старший фулл-хаус бьёт младший.
	fhBig := eval("9H", "9D", "9C", "5S", "5H")
	fhSmall := eval("8H", "8D", "8C", "5S", "5H")
	if fhBig.Compare(fhSmall) <= 0 {
		t.Fatalf("nines full should beat eights full")
	}
	// Кикер решает при равной паре.
	pairAceKick := eval("9H", "9D", "AC", "5S", "3H")
	pairKingKick := eval("9S", "9C", "KC", "5D", "3D")
	if pairAceKick.Compare(pairKingKick) <= 0 {
		t.Fatalf("ace kicker should beat king kicker")
	}
	// Полное равенство рук.
	a := eval("9H", "9D", "AC", "5S", "3H", "2C", "4D")
	b := eval("9S", "9C", "AH", "5D", "3S", "2H", "4C")
	if a.Compare(b) != 0 {
		t.Fatalf("identical hands should tie, got %d", a.Compare(b))
	}
}

func TestWheelNotBeatingSix(t *testing.T) {
	wheel, _ := EvaluateBest(cards(t, "AH", "2D", "3C", "4S", "5H"))
	sixHigh, _ := EvaluateBest(cards(t, "2H", "3D", "4C", "5S", "6H"))
	if wheel.Compare(sixHigh) >= 0 {
		t.Fatalf("6-high straight should beat the wheel")
	}
}
