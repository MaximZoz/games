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

func TestEliminatedOrderPlaces(t *testing.T) {
	g, err := NewGame([]string{"a", "b", "c", "d"}, 100, 5, 10, newRNG())
	if err != nil {
		t.Fatal(err)
	}
	g.Players[0].Chips = 0
	g.Players[1].Chips = 0
	g.Players[2].Chips = 50
	g.Players[3].Chips = 150
	g.noteEliminations()
	if len(g.EliminatedOrder) != 2 || g.EliminatedOrder[0] != "a" || g.EliminatedOrder[1] != "b" {
		t.Fatalf("elim=%v", g.EliminatedOrder)
	}
	if g.PlaceOf("a") != 4 || g.PlaceOf("b") != 3 {
		t.Fatalf("places a=%d b=%d", g.PlaceOf("a"), g.PlaceOf("b"))
	}
	g.Players[2].Chips = 0
	g.Winners = []int{3}
	g.WinnerUserIDs = []string{"d"}
	g.TableOver = true
	g.noteEliminations()
	if g.PlaceOf("d") != 1 || g.PlaceOf("c") != 2 {
		t.Fatalf("final places d=%d c=%d", g.PlaceOf("d"), g.PlaceOf("c"))
	}
	places := g.FinishPlaces()
	if places["d"] != 1 || places["c"] != 2 || places["b"] != 3 || places["a"] != 4 {
		t.Fatalf("finish=%v", places)
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

func TestShowCardsAfterFoldWin(t *testing.T) {
	g, _ := NewGame([]string{"p0", "p1", "p2"}, 1000, 5, 10, newRNG())
	if err := g.Apply(0, Action{Type: ActionFold}); err != nil {
		t.Fatal(err)
	}
	if err := g.Apply(1, Action{Type: ActionFold}); err != nil {
		t.Fatal(err)
	}
	if !g.CanShowCards(2) {
		t.Fatal("winner should be able to show cards")
	}
	if g.CanShowCards(0) || g.CanShowCards(1) {
		t.Fatal("folded players cannot show")
	}
	if err := g.ShowCards(0); err == nil {
		t.Fatal("expected error for non-winner show")
	}
	if err := g.ShowCards(2); err != nil {
		t.Fatal(err)
	}
	if !g.Players[2].Shown {
		t.Fatal("winner should be marked shown")
	}
	if g.CanShowCards(2) {
		t.Fatal("cannot show twice")
	}
}

func TestShowCardsRejectedOnShowdown(t *testing.T) {
	// Heads-up check-down to showdown, then ShowCards must fail.
	g, _ := NewGame([]string{"p0", "p1"}, 1000, 5, 10, newRNG())
	// Preflop: SB/dealer acts first — call, BB check.
	if err := g.Apply(0, Action{Type: ActionCall}); err != nil {
		t.Fatal(err)
	}
	if err := g.Apply(1, Action{Type: ActionCheck}); err != nil {
		t.Fatal(err)
	}
	// Flop/turn/river: BB acts first postflop in HU? Actually first live from dealer+1.
	for g.Street != StreetShowdown && g.Street != StreetOver && !g.HandOver {
		idx := g.ActingIndex
		if idx < 0 {
			break
		}
		acts := g.LegalActions(idx)
		var a Action
		hasCheck := false
		for _, s := range acts {
			if s == "check" {
				hasCheck = true
			}
		}
		if hasCheck {
			a = Action{Type: ActionCheck}
		} else {
			a = Action{Type: ActionCall}
		}
		if err := g.Apply(idx, a); err != nil {
			t.Fatalf("street=%s act=%v: %v", g.Street, a, err)
		}
	}
	if g.Street != StreetShowdown {
		t.Fatalf("want showdown, got %s handOver=%v", g.Street, g.HandOver)
	}
	if g.CanShowCards(0) || g.CanShowCards(1) {
		t.Fatal("showdown should not offer ShowCards")
	}
	if err := g.ShowCards(g.Winners[0]); err == nil {
		t.Fatal("expected error showing at showdown")
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

// playHandToEnd проигрывает текущую раздачу пассивно (чек/колл) до конца.
func playHandToEnd(t *testing.T, g *Game) {
	t.Helper()
	for i := 0; i < 1000 && !g.HandOver; i++ {
		idx := g.ActingIndex
		if idx < 0 {
			t.Fatalf("no acting player but hand not over")
		}
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

func TestHandOverButTableContinues(t *testing.T) {
	g, _ := NewGame([]string{"p0", "p1", "p2"}, 1000, 5, 10, newRNG())
	if g.HandOver || g.TableOver {
		t.Fatal("fresh game should not be hand/table over")
	}
	if g.HandNumber != 1 || g.BlindLevel != 0 || g.HandsPerLevel != 6 || g.HandsThisLevel != 0 {
		t.Fatalf("cash-table defaults wrong: hand=%d level=%d hpl=%d htl=%d",
			g.HandNumber, g.BlindLevel, g.HandsPerLevel, g.HandsThisLevel)
	}
	if g.BaseSmallBlind != 5 || g.BaseBigBlind != 10 {
		t.Fatalf("base blinds wrong: sb=%d bb=%d", g.BaseSmallBlind, g.BaseBigBlind)
	}
	playHandToEnd(t, g)
	if !g.HandOver {
		t.Fatal("hand should be over")
	}
	if g.Status != StatusOver {
		t.Fatalf("status should be over, got %s", g.Status)
	}
	if g.TableOver {
		t.Fatal("table should not be over — every player still has chips")
	}
}

func TestTwoHandsCarryChips(t *testing.T) {
	g, _ := NewGame([]string{"p0", "p1", "p2"}, 1000, 5, 10, newRNG())
	playHandToEnd(t, g)
	if g.TableOver {
		t.Fatal("table should not be over after one hand")
	}
	total1 := 0
	for i := range g.Players {
		total1 += g.Players[i].Chips
	}
	if total1 != 3000 {
		t.Fatalf("chips not conserved after hand 1: %d", total1)
	}
	prevDealer := g.DealerIndex
	if err := g.StartNextHand(newRNG()); err != nil {
		t.Fatalf("StartNextHand: %v", err)
	}
	if g.HandNumber != 2 {
		t.Fatalf("hand number should be 2, got %d", g.HandNumber)
	}
	if g.HandOver || g.Status != StatusActive {
		t.Fatalf("new hand should be active, not over")
	}
	if g.DealerIndex == prevDealer {
		t.Fatalf("dealer should rotate, stayed at %d", prevDealer)
	}
	// Blinds already posted for hand 2.
	total2 := 0
	for i := range g.Players {
		total2 += g.Players[i].Chips + g.Players[i].TotalBet
	}
	if total2 != 3000 {
		t.Fatalf("chips not conserved into hand 2: %d", total2)
	}
	// New deck: hole cards dealt again.
	for i := range g.Players {
		if g.Players[i].Hole[0] == (Card{}) {
			t.Fatalf("player %d missing hole cards in hand 2", i)
		}
	}
	if len(g.Community) != 0 {
		t.Fatalf("community should be cleared, got %d", len(g.Community))
	}
	playHandToEnd(t, g)
	total3 := 0
	for i := range g.Players {
		total3 += g.Players[i].Chips
	}
	if total3 != 3000 {
		t.Fatalf("chips not conserved after hand 2: %d", total3)
	}
}

func TestTableOverWhenOneHasAllChips(t *testing.T) {
	// p0 already holds everything; p1/p2 are broke. The next hand can't start and
	// a finished hand must be table-over.
	g := &Game{
		Players: []Player{
			{UserID: "p0", Seat: 0, Chips: 300, TotalBet: 300, Hole: [2]Card{{Ace, Hearts}, {Ace, Spades}}},
			{UserID: "p1", Seat: 1, Chips: 0, TotalBet: 0, Folded: true},
			{UserID: "p2", Seat: 2, Chips: 0, TotalBet: 0, Hole: [2]Card{{King, Clubs}, {King, Diamonds}}},
		},
		Community:      cards(t, "2D", "7S", "9C", "JD", "4D"),
		DealerIndex:    0,
		Street:         StreetRiver,
		Status:         StatusActive,
		HandsPerLevel:  3,
		HandNumber:     4,
		BaseSmallBlind: 5,
		BaseBigBlind:   10,
	}
	g.showdown()
	if !g.HandOver {
		t.Fatal("hand should be over")
	}
	if !g.TableOver {
		t.Fatal("table should be over — only p0 has chips")
	}
	if err := g.StartNextHand(newRNG()); err == nil {
		t.Fatal("StartNextHand must fail when table is over")
	}
}

func TestHandsPerBlindLevel(t *testing.T) {
	cases := []struct {
		live int
		want int
	}{
		{1, 12}, {2, 12}, {3, 6}, {4, 8}, {5, 10}, {6, 12},
	}
	for _, tc := range cases {
		if got := HandsPerBlindLevel(tc.live); got != tc.want {
			t.Fatalf("live=%d: hpl=%d want %d", tc.live, got, tc.want)
		}
	}
}

func TestNewGameHandsPerLevelByTableSize(t *testing.T) {
	six, _ := NewGame([]string{"p0", "p1", "p2", "p3", "p4", "p5"}, 1000, 5, 10, newRNG())
	if six.HandsPerLevel != 12 {
		t.Fatalf("6-max hpl=%d want 12", six.HandsPerLevel)
	}
	hu, _ := NewGame([]string{"p0", "p1"}, 1000, 5, 10, newRNG())
	if hu.HandsPerLevel != 12 {
		t.Fatalf("heads-up hpl=%d want 12 (6 orbits)", hu.HandsPerLevel)
	}
}

func TestBlindsDoubleEveryOrbits(t *testing.T) {
	g, _ := NewGame([]string{"p0", "p1", "p2"}, 100000, 5, 10, newRNG())
	// 3 живых → 2 круга = 6 раздач на уровень.
	if g.HandsPerLevel != 6 {
		t.Fatalf("3-max hpl=%d want 6", g.HandsPerLevel)
	}
	if g.BigBlind != 10 || g.SmallBlind != 5 || g.BlindLevel != 0 {
		t.Fatalf("hand1 blinds wrong: sb=%d bb=%d lvl=%d", g.SmallBlind, g.BigBlind, g.BlindLevel)
	}
	wantBB := map[int]int{
		2: 10, 3: 10, 4: 10, 5: 10, 6: 10,
		7: 20, 8: 20, 9: 20, 10: 20, 11: 20, 12: 20,
		13: 40,
	}
	wantLvl := map[int]int{
		2: 0, 3: 0, 4: 0, 5: 0, 6: 0,
		7: 1, 8: 1, 9: 1, 10: 1, 11: 1, 12: 1,
		13: 2,
	}
	for hand := 2; hand <= 13; hand++ {
		playHandToEnd(t, g)
		if g.TableOver {
			t.Fatalf("table unexpectedly over before hand %d", hand)
		}
		if err := g.StartNextHand(newRNG()); err != nil {
			t.Fatalf("StartNextHand for hand %d: %v", hand, err)
		}
		if g.HandNumber != hand {
			t.Fatalf("hand number = %d, want %d", g.HandNumber, hand)
		}
		if g.BlindLevel != wantLvl[hand] {
			t.Fatalf("hand %d: blind level = %d, want %d", hand, g.BlindLevel, wantLvl[hand])
		}
		if g.BigBlind != wantBB[hand] {
			t.Fatalf("hand %d: BB = %d, want %d", hand, g.BigBlind, wantBB[hand])
		}
		if g.SmallBlind != wantBB[hand]/2 {
			t.Fatalf("hand %d: SB = %d, want %d", hand, g.SmallBlind, wantBB[hand]/2)
		}
	}
}

func TestHandsPerLevelFrozenUntilLevelUp(t *testing.T) {
	g, _ := NewGame([]string{"p0", "p1", "p2", "p3"}, 100000, 5, 10, newRNG())
	if g.HandsPerLevel != 8 {
		t.Fatalf("4-max hpl=%d want 8", g.HandsPerLevel)
	}
	playHandToEnd(t, g)
	g.Players[2].Chips = 0
	g.Players[3].Chips = 0
	if err := g.StartNextHand(newRNG()); err != nil {
		t.Fatal(err)
	}
	if g.HandsPerLevel != 8 {
		t.Fatalf("mid-level bust must not shrink hpl: %d", g.HandsPerLevel)
	}
	for hand := 3; hand <= 9; hand++ {
		playHandToEnd(t, g)
		if err := g.StartNextHand(newRNG()); err != nil {
			t.Fatalf("StartNextHand for hand %d: %v", hand, err)
		}
	}
	if g.HandNumber != 9 || g.BlindLevel != 1 {
		t.Fatalf("hand=%d level=%d, want 9 / 1", g.HandNumber, g.BlindLevel)
	}
	if g.HandsPerLevel != 12 {
		t.Fatalf("after level-up HU hpl=%d want 12", g.HandsPerLevel)
	}
	if g.HandsThisLevel != 0 {
		t.Fatalf("handsThisLevel after level-up = %d, want 0", g.HandsThisLevel)
	}
}

func TestDecodeInfersHandsThisLevel(t *testing.T) {
	raw := `{"players":[{"userId":"p0","chips":1000,"seat":0},{"userId":"p1","chips":1000,"seat":1}],"handNumber":3,"handsPerLevel":3,"blindLevel":0,"baseSmallBlind":5,"baseBigBlind":10,"street":"preflop","status":"active"}`
	g, err := Decode(raw)
	if err != nil {
		t.Fatal(err)
	}
	if g.HandsThisLevel != 2 {
		t.Fatalf("inferred handsThisLevel=%d want 2", g.HandsThisLevel)
	}
	rawNew := `{"players":[{"userId":"p0","chips":1000,"seat":0},{"userId":"p1","chips":1000,"seat":1}],"handNumber":7,"handsPerLevel":6,"handsThisLevel":0,"blindLevel":1,"baseSmallBlind":5,"baseBigBlind":10,"street":"preflop","status":"active"}`
	g2, err := Decode(rawNew)
	if err != nil {
		t.Fatal(err)
	}
	if g2.HandsThisLevel != 0 {
		t.Fatalf("explicit 0 must be kept, got %d", g2.HandsThisLevel)
	}
}

func TestStartNextHandRotatesDealer(t *testing.T) {
	g, _ := NewGame([]string{"p0", "p1", "p2", "p3"}, 1000, 5, 10, newRNG())
	dealers := []int{g.DealerIndex}
	for hand := 2; hand <= 5; hand++ {
		playHandToEnd(t, g)
		if g.TableOver {
			break
		}
		if err := g.StartNextHand(newRNG()); err != nil {
			t.Fatalf("StartNextHand: %v", err)
		}
		dealers = append(dealers, g.DealerIndex)
	}
	// Dealer must advance to a different seat each hand (all seats have chips).
	for i := 1; i < len(dealers); i++ {
		if dealers[i] == dealers[i-1] {
			t.Fatalf("dealer did not rotate at step %d: %v", i, dealers)
		}
	}
}

func TestForfeitEliminatesAndMayEndTable(t *testing.T) {
	g, _ := NewGame([]string{"p0", "p1"}, 1000, 5, 10, newRNG())
	// p1 forfeits mid-hand: folds, chips zeroed, p0 wins uncontested -> table over.
	g.ForfeitPlayer(1)
	if !g.HandOver {
		t.Fatal("hand should end when opponent forfeits")
	}
	if g.Players[1].Chips != 0 {
		t.Fatalf("forfeiting player should have 0 chips, got %d", g.Players[1].Chips)
	}
	if !g.TableOver {
		t.Fatal("heads-up forfeit should end the table")
	}
	if len(g.Winners) != 1 || g.Winners[0] != 0 {
		t.Fatalf("winner should be seat 0, got %v", g.Winners)
	}
}

func TestForfeitInMultiwayContinuesTable(t *testing.T) {
	g, _ := NewGame([]string{"p0", "p1", "p2"}, 1000, 5, 10, newRNG())
	// UTG (seat0) forfeits: folds + zeroed, but SB/BB still contest the hand.
	g.ForfeitPlayer(0)
	if g.Players[0].Chips != 0 || !g.Players[0].Folded {
		t.Fatal("forfeiting player should be folded with 0 chips")
	}
	if g.HandOver {
		t.Fatal("hand should continue with two live players")
	}
	playHandToEnd(t, g)
	if g.TableOver {
		t.Fatal("table should continue — two players still have chips")
	}
	// Next hand should exclude the forfeited player.
	if err := g.StartNextHand(newRNG()); err != nil {
		t.Fatalf("StartNextHand: %v", err)
	}
	if !g.Players[0].Folded {
		t.Fatal("eliminated player must stay folded in the next hand")
	}
	if g.Players[0].Hole[0] != (Card{}) {
		t.Fatal("eliminated player must not receive cards")
	}
}

func TestStartNextHandEncodeDecode(t *testing.T) {
	g, _ := NewGame([]string{"p0", "p1", "p2"}, 1000, 5, 10, newRNG())
	playHandToEnd(t, g)
	_ = g.StartNextHand(newRNG())
	raw, err := Encode(g)
	if err != nil {
		t.Fatal(err)
	}
	g2, err := Decode(raw)
	if err != nil {
		t.Fatal(err)
	}
	if g2.HandNumber != g.HandNumber || g2.BlindLevel != g.BlindLevel ||
		g2.HandsPerLevel != g.HandsPerLevel || g2.HandsThisLevel != g.HandsThisLevel ||
		g2.BaseSmallBlind != g.BaseSmallBlind ||
		g2.BaseBigBlind != g.BaseBigBlind || g2.HandOver != g.HandOver || g2.TableOver != g.TableOver {
		t.Fatalf("cash-table fields not preserved through encode/decode")
	}
}

func TestBestHandForNeedsEnoughCards(t *testing.T) {
	g, _ := NewGame([]string{"p0", "p1"}, 1000, 5, 10, newRNG())
	// Preflop: only 2 hole cards, no community -> not enough.
	if _, err := g.BestHandFor(0); err == nil {
		t.Fatal("expected error evaluating with < 5 cards")
	}
	g.Community = cards(t, "AH", "KH", "QH", "JH", "TH")
	g.Players[0].Hole = [2]Card{{Two, Clubs}, {Three, Clubs}}
	hv, err := g.BestHandFor(0)
	if err != nil {
		t.Fatal(err)
	}
	if hv.Rank != RoyalFlush {
		t.Fatalf("expected royal flush from the board, got %s", hv.Rank)
	}
	if len(hv.Cards) != 5 {
		t.Fatalf("best hand should have 5 cards, got %d", len(hv.Cards))
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
