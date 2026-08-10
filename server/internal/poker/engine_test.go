package poker

import (
	"math/rand"
	"testing"
)

func newRNG() *rand.Rand { return rand.New(rand.NewSource(42)) }

func TestNewGameValidation(t *testing.T) {
	if _, err := NewGame([]string{"a"}, 1000, 5, 10, newRNG()); err == nil {
		t.Fatal("expected error for 1 player")
	}
	if _, err := NewGame([]string{"a", "b", "c", "d", "e", "f", "g"}, 1000, 5, 10, newRNG()); err == nil {
		t.Fatal("expected error for 7 players")
	}
	if _, err := NewGame([]string{"a", "b"}, 0, 5, 10, newRNG()); err == nil {
		t.Fatal("expected error for zero chips")
	}
	if _, err := NewGame([]string{"a", "b"}, 1000, 10, 5, newRNG()); err == nil {
		t.Fatal("expected error for bb<sb")
	}
	if _, err := NewGame([]string{"a", "b"}, 1000, 5, 10, nil); err == nil {
		t.Fatal("expected error for nil rng")
	}
}

func TestNewGameBlindsThreeHanded(t *testing.T) {
	g, err := NewGame([]string{"p0", "p1", "p2"}, 1000, 5, 10, newRNG())
	if err != nil {
		t.Fatal(err)
	}
	if g.SBIndex != 1 || g.BBIndex != 2 {
		t.Fatalf("blinds: sb=%d bb=%d", g.SBIndex, g.BBIndex)
	}
	if g.Players[1].Bet != 5 || g.Players[2].Bet != 10 {
		t.Fatalf("blind bets wrong: %d %d", g.Players[1].Bet, g.Players[2].Bet)
	}
	if g.Players[1].Chips != 995 || g.Players[2].Chips != 990 {
		t.Fatalf("blind chips wrong")
	}
	if g.CurrentBet != 10 {
		t.Fatalf("current bet=%d", g.CurrentBet)
	}
	if g.Pot != 15 {
		t.Fatalf("pot=%d", g.Pot)
	}
	if g.ActingIndex != 0 {
		t.Fatalf("UTG should be seat 0, got %d", g.ActingIndex)
	}
	for i := range g.Players {
		if g.Players[i].Hole[0] == (Card{}) || g.Players[i].Hole[1] == (Card{}) {
			t.Fatalf("player %d has no hole cards", i)
		}
	}
	if g.Street != StreetPreflop {
		t.Fatalf("street=%s", g.Street)
	}
}

func TestHeadsUpBlinds(t *testing.T) {
	g, _ := NewGame([]string{"p0", "p1"}, 1000, 5, 10, newRNG())
	if g.SBIndex != 0 || g.BBIndex != 1 {
		t.Fatalf("heads-up blinds sb=%d bb=%d", g.SBIndex, g.BBIndex)
	}
	if g.ActingIndex != 0 {
		t.Fatalf("heads-up preflop dealer/SB acts first, got %d", g.ActingIndex)
	}
}

func TestFoldAroundWins(t *testing.T) {
	g, _ := NewGame([]string{"p0", "p1", "p2"}, 1000, 5, 10, newRNG())
	// seat0 (UTG) folds
	if err := g.Apply(0, Action{Type: ActionFold}); err != nil {
		t.Fatal(err)
	}
	// seat1 (SB) folds -> seat2 (BB) wins uncontested
	if err := g.Apply(1, Action{Type: ActionFold}); err != nil {
		t.Fatal(err)
	}
	if !g.IsOver() {
		t.Fatal("game should be over")
	}
	if len(g.Winners) != 1 || g.Winners[0] != 2 {
		t.Fatalf("winner should be seat 2, got %v", g.Winners)
	}
	// seat2 posted 10, wins pot 15 -> 990+15 = 1005
	if g.Players[2].Chips != 1005 {
		t.Fatalf("winner chips=%d", g.Players[2].Chips)
	}
	if g.Street != StreetOver {
		t.Fatalf("street=%s", g.Street)
	}
}

func TestNotYourTurn(t *testing.T) {
	g, _ := NewGame([]string{"p0", "p1", "p2"}, 1000, 5, 10, newRNG())
	if err := g.Apply(2, Action{Type: ActionFold}); err == nil {
		t.Fatal("expected not-your-turn error")
	}
}

func TestLegalActionsPreflop(t *testing.T) {
	g, _ := NewGame([]string{"p0", "p1", "p2"}, 1000, 5, 10, newRNG())
	acts := g.LegalActions(0)
	has := map[string]bool{}
	for _, a := range acts {
		has[a] = true
	}
	if !has["fold"] || !has["call"] || !has["raise"] || !has["all_in"] {
		t.Fatalf("UTG legal actions wrong: %v", acts)
	}
	if has["check"] {
		t.Fatalf("UTG should not be able to check facing a bet: %v", acts)
	}
	// Not-acting player has no legal actions.
	if len(g.LegalActions(1)) != 0 {
		t.Fatalf("non-acting player should have no actions")
	}
}

// playPassive автоматически чекает/коллит до конца раздачи.
func playPassive(t *testing.T, g *Game) {
	t.Helper()
	for i := 0; i < 1000 && !g.IsOver(); i++ {
		idx := g.ActingIndex
		acts := g.LegalActions(idx)
		choice := ""
		for _, a := range acts {
			if a == string(ActionCheck) {
				choice = a
				break
			}
		}
		if choice == "" {
			for _, a := range acts {
				if a == string(ActionCall) {
					choice = a
					break
				}
			}
		}
		if choice == "" {
			t.Fatalf("no passive action available: %v", acts)
		}
		if err := g.Apply(idx, Action{Type: ActionType(choice)}); err != nil {
			t.Fatalf("apply %s: %v", choice, err)
		}
	}
}

func TestCheckCallToShowdown(t *testing.T) {
	g, _ := NewGame([]string{"p0", "p1"}, 1000, 5, 10, newRNG())
	playPassive(t, g)
	if !g.IsOver() {
		t.Fatal("game should reach showdown/over")
	}
	if g.Street != StreetShowdown {
		t.Fatalf("expected showdown street, got %s", g.Street)
	}
	if len(g.Community) != 5 {
		t.Fatalf("expected 5 community cards, got %d", len(g.Community))
	}
	total := 0
	for i := range g.Players {
		total += g.Players[i].Chips
	}
	if total != 2000 {
		t.Fatalf("chips not conserved: %d", total)
	}
	if len(g.Winners) == 0 {
		t.Fatal("expected at least one winner")
	}
}

func TestRaiseAndReraise(t *testing.T) {
	g, _ := NewGame([]string{"p0", "p1", "p2"}, 1000, 5, 10, newRNG())
	// UTG raises to 30 (min raise = bb=10, so min-to = 20; 30 is legal).
	if err := g.Apply(0, Action{Type: ActionRaise, Amount: 30}); err != nil {
		t.Fatal(err)
	}
	if g.CurrentBet != 30 {
		t.Fatalf("current bet=%d", g.CurrentBet)
	}
	if g.MinRaise != 20 {
		t.Fatalf("min raise should be 20, got %d", g.MinRaise)
	}
	// A raise below min should fail: SB (seat1) tries raise to 45 (< 30+20=50).
	if err := g.Apply(1, Action{Type: ActionRaise, Amount: 45}); err == nil {
		t.Fatal("expected below-min-raise error")
	}
	// SB makes a legal reraise to 50.
	if err := g.Apply(1, Action{Type: ActionRaise, Amount: 50}); err != nil {
		t.Fatal(err)
	}
	if g.CurrentBet != 50 {
		t.Fatalf("current bet=%d", g.CurrentBet)
	}
}

func TestSidePotsAllIn(t *testing.T) {
	// Строим раздачу вручную для детерминизма.
	g := &Game{
		Players: []Player{
			{UserID: "p0", Seat: 0, Chips: 0, TotalBet: 100, Hole: [2]Card{{Ace, Hearts}, {Ace, Diamonds}}},
			{UserID: "p1", Seat: 1, Chips: 0, TotalBet: 50, AllIn: true, Hole: [2]Card{{King, Hearts}, {King, Diamonds}}},
			{UserID: "p2", Seat: 2, Chips: 0, TotalBet: 100, Hole: [2]Card{{Two, Clubs}, {Three, Diamonds}}},
		},
		Community:   cards(t, "5H", "7S", "9C", "JD", "4D"),
		DealerIndex: 0,
		Street:      StreetRiver,
		Status:      StatusActive,
	}
	g.showdown()

	// Основной банк 150 (все трое по 50) + побочный 100 (p0,p2 по 50).
	// У p0 пара тузов — сильнейшая, забирает всё: 250.
	if g.Players[0].Chips != 250 {
		t.Fatalf("p0 should win 250, got %d", g.Players[0].Chips)
	}
	if g.Players[1].Chips != 0 || g.Players[2].Chips != 0 {
		t.Fatalf("p1/p2 should win nothing: %d %d", g.Players[1].Chips, g.Players[2].Chips)
	}
	if len(g.SidePots) != 2 {
		t.Fatalf("expected 2 pots, got %d: %+v", len(g.SidePots), g.SidePots)
	}
	if g.SidePots[0].Amount != 150 || g.SidePots[1].Amount != 100 {
		t.Fatalf("pot amounts wrong: %+v", g.SidePots)
	}
}

func TestSplitPot(t *testing.T) {
	// Доска-фулхаус: оба игрока играют борд -> делёж.
	g := &Game{
		Players: []Player{
			{UserID: "p0", Seat: 0, Chips: 0, TotalBet: 100, Hole: [2]Card{{Two, Clubs}, {Three, Diamonds}}},
			{UserID: "p1", Seat: 1, Chips: 0, TotalBet: 100, Hole: [2]Card{{Four, Clubs}, {Five, Diamonds}}},
		},
		Community:   cards(t, "AH", "AD", "AC", "KH", "KD"),
		DealerIndex: 0,
		Street:      StreetRiver,
		Status:      StatusActive,
	}
	g.showdown()
	if g.Players[0].Chips != 100 || g.Players[1].Chips != 100 {
		t.Fatalf("split should be 100/100, got %d/%d", g.Players[0].Chips, g.Players[1].Chips)
	}
	if len(g.Winners) != 2 {
		t.Fatalf("expected 2 winners, got %v", g.Winners)
	}
}

func TestOddChipToDealerLeft(t *testing.T) {
	// Единый банк 99 (три вклада по 33). p0 и p1 делят пару валетов, p2 проигрывает.
	// 99/2 = 49 остаток 1; лишняя фишка — ближайшему слева от дилера (seat1).
	g := &Game{
		Players: []Player{
			{UserID: "p0", Seat: 0, Chips: 0, TotalBet: 33, Hole: [2]Card{{Jack, Hearts}, {Jack, Spades}}},
			{UserID: "p1", Seat: 1, Chips: 0, TotalBet: 33, Hole: [2]Card{{Jack, Clubs}, {Jack, Diamonds}}},
			{UserID: "p2", Seat: 2, Chips: 0, TotalBet: 33, Hole: [2]Card{{Three, Clubs}, {Four, Diamonds}}},
		},
		Community:   cards(t, "AH", "KD", "QC", "7S", "2H"),
		DealerIndex: 0,
		Street:      StreetRiver,
		Status:      StatusActive,
	}
	g.showdown()
	if g.Players[0].Chips != 49 || g.Players[1].Chips != 50 || g.Players[2].Chips != 0 {
		t.Fatalf("odd chip distribution wrong: p0=%d p1=%d p2=%d",
			g.Players[0].Chips, g.Players[1].Chips, g.Players[2].Chips)
	}
	if len(g.Winners) != 2 {
		t.Fatalf("expected 2 winners, got %v", g.Winners)
	}
}

func TestEncodeDecodeRoundTrip(t *testing.T) {
	g, _ := NewGame([]string{"p0", "p1", "p2"}, 1000, 5, 10, newRNG())
	_ = g.Apply(0, Action{Type: ActionRaise, Amount: 30})
	raw, err := Encode(g)
	if err != nil {
		t.Fatal(err)
	}
	g2, err := Decode(raw)
	if err != nil {
		t.Fatal(err)
	}
	if g2.CurrentBet != g.CurrentBet || g2.Pot != g.Pot || g2.ActingIndex != g.ActingIndex {
		t.Fatalf("roundtrip mismatch")
	}
	if g2.Players[0].Hole != g.Players[0].Hole {
		t.Fatalf("hole cards not preserved")
	}
	if _, err := Decode(""); err == nil {
		t.Fatal("expected error decoding empty string")
	}
}

func TestAllInShowdownConservesChips(t *testing.T) {
	g, _ := NewGame([]string{"p0", "p1", "p2"}, 100, 5, 10, newRNG())
	// Все идут all-in по очереди; раздача докручивается до вскрытия.
	for i := 0; i < 100 && !g.IsOver(); i++ {
		idx := g.ActingIndex
		if err := g.Apply(idx, Action{Type: ActionAllIn}); err != nil {
			t.Fatalf("all-in apply: %v", err)
		}
	}
	if !g.IsOver() {
		t.Fatal("game should be over after all-ins")
	}
	total := 0
	for i := range g.Players {
		total += g.Players[i].Chips
	}
	if total != 300 {
		t.Fatalf("chips not conserved after all-in: %d", total)
	}
}
