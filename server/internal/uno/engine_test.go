package uno

import (
	"encoding/json"
	"fmt"
	"reflect"
	"testing"
)

func TestNewDeckStandardCompositionAndDeterminism(t *testing.T) {
	deck := NewDeck(42)
	if len(deck) != 108 {
		t.Fatalf("deck size = %d, want 108", len(deck))
	}
	if !reflect.DeepEqual(deck, NewDeck(42)) {
		t.Fatal("same seed produced different decks")
	}
	if reflect.DeepEqual(deck, NewDeck(43)) {
		t.Fatal("different seeds produced identical deck order")
	}

	ids := make(map[string]bool, len(deck))
	colorCounts := make(map[Color]int)
	kindCounts := make(map[Kind]int)
	numberCounts := make(map[Color]map[int]int)
	for _, card := range deck {
		if ids[card.ID] {
			t.Fatalf("duplicate card ID %q", card.ID)
		}
		ids[card.ID] = true
		colorCounts[card.Color]++
		kindCounts[card.Kind]++
		if card.Kind == KindNumber {
			if numberCounts[card.Color] == nil {
				numberCounts[card.Color] = make(map[int]int)
			}
			numberCounts[card.Color][card.Number]++
		}
	}

	for _, color := range []Color{ColorRed, ColorYellow, ColorGreen, ColorBlue} {
		if colorCounts[color] != 25 {
			t.Errorf("%s cards = %d, want 25", color, colorCounts[color])
		}
		if numberCounts[color][0] != 1 {
			t.Errorf("%s zero cards = %d, want 1", color, numberCounts[color][0])
		}
		for number := 1; number <= 9; number++ {
			if numberCounts[color][number] != 2 {
				t.Errorf("%s %d cards = %d, want 2", color, number, numberCounts[color][number])
			}
		}
	}
	if kindCounts[KindNumber] != 76 ||
		kindCounts[KindSkip] != 8 ||
		kindCounts[KindReverse] != 8 ||
		kindCounts[KindDrawTwo] != 8 ||
		kindCounts[KindWild] != 4 ||
		kindCounts[KindWildDrawFour] != 4 {
		t.Fatalf("unexpected kind counts: %#v", kindCounts)
	}
}

func TestCardMatchesAndPoints(t *testing.T) {
	top := testNumber("top", ColorRed, 5)
	tests := []struct {
		name  string
		card  Card
		match bool
	}{
		{"same color", testNumber("red-2", ColorRed, 2), true},
		{"same number", testNumber("blue-5", ColorBlue, 5), true},
		{"different", testNumber("blue-2", ColorBlue, 2), false},
		{"wild", testAction("wild", ColorWild, KindWild), true},
		{"wild draw four", testAction("wd4", ColorWild, KindWildDrawFour), true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.card.Matches(top, ColorRed); got != tt.match {
				t.Fatalf("Matches() = %v, want %v", got, tt.match)
			}
		})
	}

	skipTop := testAction("skip-top", ColorYellow, KindSkip)
	if !testAction("skip-blue", ColorBlue, KindSkip).Matches(skipTop, ColorYellow) {
		t.Fatal("same action kind should match")
	}
	if testAction("reverse-blue", ColorBlue, KindReverse).Matches(skipTop, ColorYellow) {
		t.Fatal("different action kind should not match")
	}

	points := map[Card]int{
		testNumber("n", ColorRed, 9):                  9,
		testAction("s", ColorRed, KindSkip):           20,
		testAction("r", ColorRed, KindReverse):        20,
		testAction("d2", ColorRed, KindDrawTwo):       20,
		testAction("w", ColorWild, KindWild):          50,
		testAction("w4", ColorWild, KindWildDrawFour): 50,
	}
	for card, want := range points {
		if got := card.Points(); got != want {
			t.Errorf("%s.Points() = %d, want %d", card.ID, got, want)
		}
	}
}

func TestNewGameDealsSevenAndNeverStartsWithWild(t *testing.T) {
	var game *Game
	for seed := int64(0); seed < 1000; seed++ {
		candidate, err := NewGame([]string{"a", "b", "c", "d"}, seed)
		if err != nil {
			t.Fatal(err)
		}
		top := candidate.DiscardPile[len(candidate.DiscardPile)-1]
		if top.Kind == KindNumber {
			game = candidate
			break
		}
	}
	if game == nil {
		t.Fatal("could not find deterministic number opening")
	}
	for _, player := range game.Players {
		if len(player.Hand) != 7 {
			t.Errorf("player %s hand = %d, want 7", player.UserID, len(player.Hand))
		}
	}
	if got := len(game.DrawPile); got != 108-4*7-1 {
		t.Fatalf("draw pile = %d, want %d", got, 108-4*7-1)
	}
	if game.DiscardPile[0].isWild() {
		t.Fatal("game started with a wild card")
	}
}

func TestOpeningActionEffects(t *testing.T) {
	found := map[Kind]bool{}
	for seed := int64(0); seed < 5000 && len(found) < 3; seed++ {
		game, err := NewGame([]string{"p0", "p1", "p2"}, seed)
		if err != nil {
			t.Fatal(err)
		}
		top := game.DiscardPile[len(game.DiscardPile)-1]
		if found[top.Kind] {
			continue
		}
		switch top.Kind {
		case KindSkip:
			found[top.Kind] = true
			if game.CurrentIndex != 2 {
				t.Fatalf("opening Skip current = %d, want 2", game.CurrentIndex)
			}
		case KindReverse:
			found[top.Kind] = true
			if game.Direction != -1 || game.CurrentIndex != 2 {
				t.Fatalf("opening Reverse direction=%d current=%d, want -1 and 2", game.Direction, game.CurrentIndex)
			}
		case KindDrawTwo:
			found[top.Kind] = true
			if len(game.Players[1].Hand) != 7 || game.CurrentIndex != 1 || game.PendingDraw != 2 {
				t.Fatalf("opening Draw Two hand=%d current=%d pending=%d, want 7, 1 and 2",
					len(game.Players[1].Hand), game.CurrentIndex, game.PendingDraw)
			}
		}
	}
	for _, kind := range []Kind{KindSkip, KindReverse, KindDrawTwo} {
		if !found[kind] {
			t.Errorf("did not find opening %s in deterministic seed range", kind)
		}
	}
}

func TestReverseActsAsSkipWithTwoPlayers(t *testing.T) {
	game := controlledGame(t, 2)
	reverse := testAction("reverse", ColorRed, KindReverse)
	game.Players[0].Hand = []Card{reverse, testNumber("remain", ColorBlue, 1)}

	if err := game.Apply(Action{Type: ActionPlay, CardID: reverse.ID}); err != nil {
		t.Fatal(err)
	}
	if game.Direction != 1 {
		t.Fatalf("direction = %d, want unchanged +1", game.Direction)
	}
	if game.CurrentIndex != 0 {
		t.Fatalf("current index = %d, want player 0 again", game.CurrentIndex)
	}
}

func TestDrawTwoStacksUntilTaken(t *testing.T) {
	game := controlledGame(t, 3)
	first := testAction("draw-two-a", ColorRed, KindDrawTwo)
	second := testAction("draw-two-b", ColorBlue, KindDrawTwo)
	game.Players[0].Hand = []Card{first, testNumber("remain-0", ColorBlue, 1)}
	game.Players[1].Hand = []Card{second, testNumber("remain-1", ColorYellow, 3)}
	before := len(game.Players[2].Hand)

	if err := game.Apply(Action{Type: ActionPlay, CardID: first.ID}); err != nil {
		t.Fatal(err)
	}
	if game.PendingDraw != 2 || game.CurrentIndex != 1 || len(game.Players[1].Hand) != 2 {
		t.Fatalf("after first +2: pending=%d current=%d hand=%d",
			game.PendingDraw, game.CurrentIndex, len(game.Players[1].Hand))
	}
	if err := game.Apply(Action{Type: ActionPlay, CardID: second.ID}); err != nil {
		t.Fatal(err)
	}
	if game.PendingDraw != 4 || game.CurrentIndex != 2 {
		t.Fatalf("after stacked +2: pending=%d current=%d", game.PendingDraw, game.CurrentIndex)
	}
	if err := game.Apply(Action{Type: ActionDraw}); err != nil {
		t.Fatal(err)
	}
	if got := len(game.Players[2].Hand); got != before+4 {
		t.Fatalf("stacked victim hand = %d, want %d", got, before+4)
	}
	if game.PendingDraw != 0 || game.CurrentIndex != 0 || game.LastDrawCount != 4 {
		t.Fatalf("after taking stack: pending=%d current=%d lastDraw=%d",
			game.PendingDraw, game.CurrentIndex, game.LastDrawCount)
	}
}

func TestCannotStackWildDrawFourOnDrawTwo(t *testing.T) {
	game := controlledGame(t, 3)
	drawTwo := testAction("draw-two", ColorRed, KindDrawTwo)
	wd4 := testAction("wd4-stack", ColorWild, KindWildDrawFour)
	game.Players[0].Hand = []Card{drawTwo, testNumber("remain-0", ColorBlue, 1)}
	game.Players[1].Hand = []Card{wd4, testNumber("remain-1", ColorYellow, 3)}

	if err := game.Apply(Action{Type: ActionPlay, CardID: drawTwo.ID}); err != nil {
		t.Fatal(err)
	}
	if err := game.Apply(Action{Type: ActionPlay, CardID: wd4.ID, Color: string(ColorGreen)}); err == nil {
		t.Fatal("expected +4 on +2 to be rejected")
	}
	if game.PendingDraw != 2 || game.CurrentIndex != 1 {
		t.Fatalf("after illegal stack: pending=%d current=%d", game.PendingDraw, game.CurrentIndex)
	}
}

func TestWildDrawFourStacksOnWildDrawFour(t *testing.T) {
	game := controlledGame(t, 3)
	first := testAction("wd4-a", ColorWild, KindWildDrawFour)
	second := testAction("wd4-b", ColorWild, KindWildDrawFour)
	game.Players[0].Hand = []Card{first, testNumber("remain-0", ColorYellow, 1)}
	game.Players[1].Hand = []Card{second, testNumber("remain-1", ColorYellow, 3)}
	before := len(game.Players[2].Hand)

	if err := game.Apply(Action{Type: ActionPlay, CardID: first.ID, Color: string(ColorBlue)}); err != nil {
		t.Fatal(err)
	}
	if err := game.Apply(Action{Type: ActionPlay, CardID: second.ID, Color: string(ColorGreen)}); err != nil {
		t.Fatal(err)
	}
	if game.PendingDraw != 8 || game.Status != StatusAwaitingWD4Challenge || game.CurrentIndex != 2 {
		t.Fatalf("stacked +4: pending=%d status=%s current=%d",
			game.PendingDraw, game.Status, game.CurrentIndex)
	}
	if err := game.Apply(Action{Type: ActionDraw}); err != nil {
		t.Fatal(err)
	}
	if got := len(game.Players[2].Hand); got != before+8 {
		t.Fatalf("stacked +4 victim hand = %d, want %d", got, before+8)
	}
}

func TestDrawnPlayableCardMayBeKeptOrPlayed(t *testing.T) {
	t.Run("draw requires no legal play", func(t *testing.T) {
		game := controlledGame(t, 2)
		game.Players[0].Hand = []Card{
			testNumber("matching-red", ColorRed, 2),
			testNumber("other", ColorBlue, 1),
		}
		if err := game.Apply(Action{Type: ActionDraw}); err == nil {
			t.Fatal("draw should fail while the player has a legal play")
		}
	})

	t.Run("keep", func(t *testing.T) {
		game := controlledGame(t, 2)
		drawn := testNumber("drawn-red", ColorRed, 9)
		game.DrawPile = append(game.DrawPile, drawn)
		before := len(game.Players[0].Hand)

		if err := game.Apply(Action{Type: ActionDraw}); err != nil {
			t.Fatal(err)
		}
		if game.Status != StatusAwaitingDrawnPlay || game.DrawnCardID != drawn.ID {
			t.Fatalf("unexpected drawn-card state: status=%s id=%q", game.Status, game.DrawnCardID)
		}
		if len(game.Players[0].Hand) != before+1 {
			t.Fatal("drawn card was not added")
		}
		if err := game.Apply(Action{Type: ActionKeep}); err != nil {
			t.Fatal(err)
		}
		if game.CurrentIndex != 1 || game.Status != StatusActive {
			t.Fatalf("keep did not end turn: index=%d status=%s", game.CurrentIndex, game.Status)
		}
	})

	t.Run("play only drawn card", func(t *testing.T) {
		game := controlledGame(t, 2)
		other := testNumber("other-blue", ColorBlue, 2)
		drawn := testNumber("drawn-red", ColorRed, 9)
		game.Players[0].Hand = []Card{other, testNumber("remain", ColorBlue, 1)}
		game.DrawPile = append(game.DrawPile, drawn)

		if err := game.Apply(Action{Type: ActionDraw}); err != nil {
			t.Fatal(err)
		}
		if err := game.Apply(Action{Type: ActionPlay, CardID: other.ID}); err == nil {
			t.Fatal("playing a pre-existing hand card after drawing should fail")
		}
		if err := game.Apply(Action{Type: ActionPlay, CardID: drawn.ID}); err != nil {
			t.Fatal(err)
		}
		if game.DiscardPile[len(game.DiscardPile)-1].ID != drawn.ID {
			t.Fatal("drawn card was not played")
		}
	})
}

func TestWildRequiresAndAppliesColorChoice(t *testing.T) {
	game := controlledGame(t, 2)
	wild := testAction("wild", ColorWild, KindWild)
	game.Players[0].Hand = []Card{wild, testNumber("remain", ColorBlue, 1)}

	if err := game.Apply(Action{Type: ActionPlay, CardID: wild.ID}); err != nil {
		t.Fatal(err)
	}
	if game.Status != StatusAwaitingColor || game.CurrentIndex != 0 {
		t.Fatalf("status=%s current=%d, want awaiting color by player 0", game.Status, game.CurrentIndex)
	}
	if err := game.Apply(Action{Type: ActionChooseColor, Color: string(ColorGreen)}); err != nil {
		t.Fatal(err)
	}
	if game.CurrentColor != ColorGreen || game.Status != StatusActive || game.CurrentIndex != 1 {
		t.Fatalf("color=%s status=%s current=%d", game.CurrentColor, game.Status, game.CurrentIndex)
	}
}

func TestWildDrawFourChallenge(t *testing.T) {
	t.Run("legal play makes challenger draw six and skip", func(t *testing.T) {
		game := controlledGame(t, 3)
		wd4 := testAction("wd4-legal", ColorWild, KindWildDrawFour)
		// Matching the top number does not make WD4 illegal; only a card
		// matching the current color does.
		game.Players[0].Hand = []Card{wd4, testNumber("yellow-five", ColorYellow, 5)}
		before := len(game.Players[1].Hand)

		if err := game.Apply(Action{Type: ActionPlay, CardID: wd4.ID, Color: string(ColorBlue)}); err != nil {
			t.Fatal(err)
		}
		if game.Status != StatusAwaitingWD4Challenge || game.PendingDraw != 4 || game.CurrentIndex != 1 {
			t.Fatalf("unexpected pending challenge: status=%s draw=%d current=%d", game.Status, game.PendingDraw, game.CurrentIndex)
		}
		if err := game.Apply(Action{Type: ActionChallengeWD4}); err != nil {
			t.Fatal(err)
		}
		if got := len(game.Players[1].Hand); got != before+6 {
			t.Fatalf("challenger hand = %d, want %d", got, before+6)
		}
		if game.CurrentIndex != 2 {
			t.Fatalf("current index = %d, want challenger skipped to 2", game.CurrentIndex)
		}
	})

	t.Run("illegal play makes offender draw four", func(t *testing.T) {
		game := controlledGame(t, 3)
		wd4 := testAction("wd4-illegal", ColorWild, KindWildDrawFour)
		game.Players[0].Hand = []Card{wd4, testNumber("matching-red", ColorRed, 2)}
		beforeOffender := len(game.Players[0].Hand)
		beforeChallenger := len(game.Players[1].Hand)

		if err := game.Apply(Action{Type: ActionPlay, CardID: wd4.ID, Color: string(ColorBlue)}); err != nil {
			t.Fatal(err)
		}
		if game.Wild4WasLegal {
			t.Fatal("Wild Draw Four should be marked illegal when a matching-color card exists")
		}
		if err := game.Apply(Action{Type: ActionChallengeWD4}); err != nil {
			t.Fatal(err)
		}
		if got := len(game.Players[0].Hand); got != beforeOffender-1+4 {
			t.Fatalf("offender hand = %d, want %d", got, beforeOffender-1+4)
		}
		if got := len(game.Players[1].Hand); got != beforeChallenger {
			t.Fatalf("challenger hand changed to %d", got)
		}
		if game.CurrentIndex != 1 {
			t.Fatalf("challenger should retain turn, current=%d", game.CurrentIndex)
		}
		if game.LastEventType != "wd4_reveal" || game.LastEventCard == nil || game.LastEventCard.Color != ColorRed {
			t.Fatalf("expected red proof card, event=%s card=%#v", game.LastEventType, game.LastEventCard)
		}
		view := game.View("p1")
		if view.MyIndex != 1 || view.LastEventCard == nil || view.LastEventCard.Color != ColorRed {
			t.Fatalf("view should expose proof card to challenger: my=%d card=%#v", view.MyIndex, view.LastEventCard)
		}
	})

	t.Run("declined challenge draws four and skips", func(t *testing.T) {
		game := controlledGame(t, 3)
		wd4 := testAction("wd4-decline", ColorWild, KindWildDrawFour)
		game.Players[0].Hand = []Card{wd4, testNumber("remain", ColorYellow, 1)}
		before := len(game.Players[1].Hand)

		if err := game.Apply(Action{Type: ActionPlay, CardID: wd4.ID, Color: string(ColorGreen)}); err != nil {
			t.Fatal(err)
		}
		if err := game.Apply(Action{Type: ActionDraw}); err != nil {
			t.Fatal(err)
		}
		if len(game.Players[1].Hand) != before+4 || game.CurrentIndex != 2 {
			t.Fatalf("decline result: hand=%d current=%d", len(game.Players[1].Hand), game.CurrentIndex)
		}
	})
}

func TestUnoCallAndChallengePenalty(t *testing.T) {
	t.Run("caught before next action", func(t *testing.T) {
		game := controlledGame(t, 2)
		played := testNumber("red-play", ColorRed, 7)
		game.Players[0].Hand = []Card{played, testNumber("last", ColorBlue, 1)}
		before := len(game.Players[0].Hand)

		if err := game.Apply(Action{Type: ActionPlay, CardID: played.ID}); err != nil {
			t.Fatal(err)
		}
		if err := game.Apply(Action{Type: ActionChallengeUno, ActorUserID: "p1", TargetUserID: "p0"}); err == nil {
			t.Fatal("UNO challenge should wait one second")
		}
		game.NowMs = game.UnoVulnerableAtMs
		if err := game.Apply(Action{Type: ActionChallengeUno, ActorUserID: "p1", TargetUserID: "p0"}); err != nil {
			t.Fatal(err)
		}
		if got := len(game.Players[0].Hand); got != before-1+2 {
			t.Fatalf("challenged hand = %d, want %d", got, before-1+2)
		}
		if game.CurrentIndex != 1 {
			t.Fatal("UNO challenge should not consume challenger's turn")
		}
	})

	t.Run("any other player can catch after the grace", func(t *testing.T) {
		game := controlledGame(t, 3)
		played := testNumber("red-play-3p", ColorRed, 7)
		game.Players[0].Hand = []Card{played, testNumber("last-3p", ColorBlue, 1)}

		if err := game.Apply(Action{Type: ActionPlay, CardID: played.ID}); err != nil {
			t.Fatal(err)
		}
		game.NowMs = game.UnoVulnerableAtMs
		self := game.View("p0")
		next := game.View("p1")
		other := game.View("p2")
		if !self.CanCallUno {
			t.Fatal("vulnerable player should still be able to say UNO")
		}
		if self.CanChallengeUno {
			t.Fatal("vulnerable player cannot catch themselves")
		}
		if !next.CanChallengeUno || !other.CanChallengeUno {
			t.Fatalf("every other player should catch: next=%v other=%v current=%d", next.CanChallengeUno, other.CanChallengeUno, game.CurrentIndex)
		}
		if next.CanCallUno || other.CanCallUno {
			t.Fatal("only the one-card player can say UNO")
		}
		if err := game.Apply(Action{Type: ActionChallengeUno, ActorUserID: "p2", TargetUserID: "p0"}); err != nil {
			t.Fatal(err)
		}
		if got := len(game.Players[0].Hand); got != 3 {
			t.Fatalf("hand after catch by p2 = %d, want 3", got)
		}
	})

	t.Run("UNO button closes after the next player moves", func(t *testing.T) {
		game := controlledGame(t, 2)
		played := testNumber("red-play-late", ColorRed, 7)
		reply := testNumber("red-reply", ColorRed, 3)
		game.Players[0].Hand = []Card{played, testNumber("last-late", ColorBlue, 1)}
		game.Players[1].Hand = []Card{reply, testNumber("p1-keep-late", ColorBlue, 2)}

		if err := game.Apply(Action{Type: ActionPlay, CardID: played.ID}); err != nil {
			t.Fatal(err)
		}
		if !game.View("p0").CanCallUno {
			t.Fatal("UNO should be available before the next play")
		}
		if err := game.Apply(Action{Type: ActionPlay, CardID: reply.ID}); err != nil {
			t.Fatal(err)
		}
		late := game.View("p0")
		if late.CanCallUno || late.CanChallengeUno {
			t.Fatalf("window should close after next play: call=%v catch=%v", late.CanCallUno, late.CanChallengeUno)
		}
	})

	t.Run("successful call prevents challenge", func(t *testing.T) {
		game := controlledGame(t, 2)
		played := testNumber("red-play", ColorRed, 7)
		game.Players[0].Hand = []Card{played, testNumber("last", ColorBlue, 1)}

		if err := game.Apply(Action{Type: ActionPlay, CardID: played.ID}); err != nil {
			t.Fatal(err)
		}
		if err := game.Apply(Action{Type: ActionCallUno}); err != nil {
			t.Fatal(err)
		}
		if !game.Players[0].SaidUno {
			t.Fatal("SaidUno was not recorded")
		}
		if err := game.Apply(Action{Type: ActionChallengeUno, ActorUserID: "p1", TargetUserID: "p0"}); err == nil {
			t.Fatal("challenge should fail after UNO was called")
		}
	})
}

func TestUnoAutoPlaysIdenticalNonWildPair(t *testing.T) {
	t.Run("two yellow eights leave together", func(t *testing.T) {
		game := controlledGame(t, 2)
		first := testNumber("yellow-8-a", ColorYellow, 8)
		second := testNumber("yellow-8-b", ColorYellow, 8)
		game.Players[0].Hand = []Card{first, second, testNumber("keep", ColorBlue, 1)}
		game.DiscardPile = []Card{testNumber("top-yellow-3", ColorYellow, 3)}
		game.CurrentColor = ColorYellow

		if err := game.Apply(Action{Type: ActionPlay, CardID: first.ID}); err != nil {
			t.Fatal(err)
		}
		if len(game.Players[0].Hand) != 1 {
			t.Fatalf("hand = %d, want 1 after pair dump", len(game.Players[0].Hand))
		}
		top := game.DiscardPile[len(game.DiscardPile)-1]
		if top.ID != second.ID {
			t.Fatalf("top = %s, want twin %s", top.ID, second.ID)
		}
		if game.CurrentIndex != 1 {
			t.Fatalf("current = %d, want 1 after one number play", game.CurrentIndex)
		}
		if len(game.LastPlayedCards) != 2 {
			t.Fatalf("played cards = %d, want 2", len(game.LastPlayedCards))
		}
	})

	t.Run("two +2 add four to the stack", func(t *testing.T) {
		game := controlledGame(t, 2)
		first := testAction("red-dt-a", ColorRed, KindDrawTwo)
		second := testAction("red-dt-b", ColorRed, KindDrawTwo)
		game.Players[0].Hand = []Card{first, second, testNumber("keep", ColorBlue, 1)}

		if err := game.Apply(Action{Type: ActionPlay, CardID: first.ID}); err != nil {
			t.Fatal(err)
		}
		if game.PendingDraw != 4 {
			t.Fatalf("pending = %d, want 4", game.PendingDraw)
		}
		if len(game.Players[0].Hand) != 1 {
			t.Fatalf("hand = %d, want 1", len(game.Players[0].Hand))
		}
	})

	t.Run("wilds are not paired", func(t *testing.T) {
		game := controlledGame(t, 2)
		first := testAction("wild-a", ColorWild, KindWild)
		second := testAction("wild-b", ColorWild, KindWild)
		game.Players[0].Hand = []Card{first, second, testNumber("keep", ColorBlue, 1)}

		if err := game.Apply(Action{Type: ActionPlay, CardID: first.ID, Color: string(ColorGreen)}); err != nil {
			t.Fatal(err)
		}
		if len(game.Players[0].Hand) != 2 {
			t.Fatalf("hand = %d, want 2 (second wild stays)", len(game.Players[0].Hand))
		}
	})
}

func TestRoundScoringEndsMatchAtOneHundred(t *testing.T) {
	game := controlledGame(t, 2)
	winningCard := testNumber("winning", ColorRed, 9)
	game.Players[0].Hand = []Card{winningCard}
	game.Players[0].Score = 75
	game.Players[1].Hand = []Card{
		testAction("skip", ColorBlue, KindSkip),
		testNumber("five", ColorYellow, 5),
	}

	if err := game.Apply(Action{Type: ActionPlay, CardID: winningCard.ID}); err != nil {
		t.Fatal(err)
	}
	if game.Players[0].Score != 100 {
		t.Fatalf("score = %d, want 100", game.Players[0].Score)
	}
	if game.Status != StatusOver || !reflect.DeepEqual(game.WinnerUserIDs, []string{"p0"}) {
		t.Fatalf("status=%s winners=%v", game.Status, game.WinnerUserIDs)
	}
}

func TestRoundBelowTargetStartsNextRound(t *testing.T) {
	game := controlledGame(t, 2)
	winningCard := testNumber("winning", ColorRed, 9)
	game.Players[0].Hand = []Card{winningCard}
	game.Players[1].Hand = []Card{testNumber("five", ColorYellow, 5)}
	game.Direction = -1

	if err := game.Apply(Action{Type: ActionPlay, CardID: winningCard.ID}); err != nil {
		t.Fatal(err)
	}
	if game.Players[0].Score != 5 || game.RoundNumber != 1 || game.Status != StatusBetweenRounds {
		t.Fatalf("score=%d round=%d status=%s", game.Players[0].Score, game.RoundNumber, game.Status)
	}
	if game.LastRoundPoints != 5 || game.LastRoundWinnerUserID != "p0" {
		t.Fatalf("last round winner=%s points=%d", game.LastRoundWinnerUserID, game.LastRoundPoints)
	}
	if err := game.Apply(Action{Type: ActionNextRound}); err != nil {
		t.Fatal(err)
	}
	if game.Players[0].Score != 5 || game.RoundNumber != 2 || game.Status == StatusOver {
		t.Fatalf("after next: score=%d round=%d status=%s", game.Players[0].Score, game.RoundNumber, game.Status)
	}
	if game.DealerIndex != 1 {
		t.Fatalf("dealer index = %d, want clockwise rotation to 1", game.DealerIndex)
	}
	for _, player := range game.Players {
		if len(player.Hand) < 7 {
			t.Fatalf("new round did not deal player %s", player.UserID)
		}
	}
}

func TestTargetScoreDependsOnPlayerCount(t *testing.T) {
	two, err := NewGame([]string{"a", "b"}, 1)
	if err != nil {
		t.Fatal(err)
	}
	three, err := NewGame([]string{"a", "b", "c"}, 1)
	if err != nil {
		t.Fatal(err)
	}
	if two.TargetScore != DefaultTargetScore {
		t.Fatalf("1v1 target = %d, want %d", two.TargetScore, DefaultTargetScore)
	}
	if three.TargetScore != MultiplayerTargetScore {
		t.Fatalf("3p target = %d, want %d", three.TargetScore, MultiplayerTargetScore)
	}
}

func TestForfeitEndsTwoPlayerMatch(t *testing.T) {
	game := controlledGame(t, 2)
	if err := game.Apply(Action{Type: ActionForfeit}); err != nil {
		t.Fatal(err)
	}
	if game.Status != StatusOver {
		t.Fatalf("status = %s, want over", game.Status)
	}
	if !reflect.DeepEqual(game.WinnerUserIDs, []string{"p1"}) {
		t.Fatalf("winners = %v, want [p1]", game.WinnerUserIDs)
	}
	if !reflect.DeepEqual(game.EliminatedOrder, []string{"p0"}) {
		t.Fatalf("eliminated = %v, want [p0]", game.EliminatedOrder)
	}
	if len(game.Players[0].Hand) != 0 {
		t.Fatal("forfeited player's hand should be removed")
	}
}

func TestViewHidesOtherHandsAndExposesActionFlags(t *testing.T) {
	game := controlledGame(t, 2)
	game.Status = StatusAwaitingDrawnPlay
	game.DrawnCardID = game.Players[0].Hand[0].ID
	view := game.View("p0")

	if len(view.Players[0].Hand) != len(game.Players[0].Hand) {
		t.Fatal("own hand is not visible")
	}
	if view.Players[1].Hand != nil {
		t.Fatalf("opponent hand leaked: %#v", view.Players[1].Hand)
	}
	if view.Players[1].HandCount != len(game.Players[1].Hand) {
		t.Fatal("opponent hand count is wrong")
	}
	if !view.CanKeepOrPlayDrawn || view.DrawnCardID != game.DrawnCardID {
		t.Fatal("drawn-card action flag is missing for current player")
	}

	opponentView := game.View("p1")
	if opponentView.DrawnCardID != "" || opponentView.CanKeepOrPlayDrawn {
		t.Fatal("drawn card information leaked to opponent")
	}
}

func TestPendingStateSurvivesJSONRoundTrip(t *testing.T) {
	game := controlledGame(t, 3)
	wd4 := testAction("wd4-round-trip", ColorWild, KindWildDrawFour)
	game.Players[0].Hand = []Card{wd4, testNumber("remain", ColorYellow, 2)}
	if err := game.Apply(Action{Type: ActionPlay, CardID: wd4.ID}); err != nil {
		t.Fatal(err)
	}

	data, err := json.Marshal(game)
	if err != nil {
		t.Fatal(err)
	}
	var restored Game
	if err := json.Unmarshal(data, &restored); err != nil {
		t.Fatal(err)
	}
	if err := restored.Apply(Action{Type: ActionChooseColor, Color: string(ColorBlue)}); err != nil {
		t.Fatal(err)
	}
	if err := restored.Apply(Action{Type: ActionChallengeWD4}); err != nil {
		t.Fatal(err)
	}
	if restored.Status != StatusActive || restored.CurrentIndex != 2 {
		t.Fatalf("restored challenge status=%s current=%d", restored.Status, restored.CurrentIndex)
	}
}

func controlledGame(t *testing.T, playerCount int) *Game {
	t.Helper()
	ids := make([]string, playerCount)
	for i := range ids {
		ids[i] = fmt.Sprintf("p%d", i)
	}
	game, err := NewGame(ids, 1)
	if err != nil {
		t.Fatal(err)
	}
	game.DrawPile = make([]Card, 20)
	for i := range game.DrawPile {
		game.DrawPile[i] = testNumber(fmt.Sprintf("draw-%d", i), ColorYellow, i%10)
	}
	game.DiscardPile = []Card{testNumber("top-red-5", ColorRed, 5)}
	game.CurrentColor = ColorRed
	game.Direction = 1
	game.CurrentIndex = 0
	game.Status = StatusActive
	game.PendingDraw = 0
	game.DrawnCardID = ""
	game.LastPlayedBy = ""
	game.Wild4PlayerIndex = -1
	game.ColorChooserIndex = -1
	game.UnoVulnerableIndex = -1
	game.PendingRoundWinnerIndex = -1
	game.Wild4WasLegal = false
	for i := range game.Players {
		game.Players[i].Hand = []Card{
			testNumber(fmt.Sprintf("p%d-blue-1", i), ColorBlue, 1),
			testNumber(fmt.Sprintf("p%d-green-2", i), ColorGreen, 2),
		}
		game.Players[i].Score = 0
		game.Players[i].SaidUno = false
		game.Players[i].Forfeited = false
	}
	return game
}

func testNumber(id string, color Color, number int) Card {
	return Card{ID: id, Color: color, Kind: KindNumber, Number: number}
}

func testAction(id string, color Color, kind Kind) Card {
	return Card{ID: id, Color: color, Kind: kind}
}
