package nardy

import (
	"math/rand"
	"testing"
)

func TestBotBestMoveDoesNotMutate(t *testing.T) {
	g := NewGame(ModeShort)
	if err := g.RollWith(6, 5); err != nil {
		t.Fatal(err)
	}
	before := g.Clone()
	if _, ok := BotBestMove(g, rand.New(rand.NewSource(1))); !ok {
		t.Fatal("expected a move")
	}
	if g.Board != before.Board || g.Bar != before.Bar || g.Off != before.Off {
		t.Fatal("search mutated the position")
	}
	if len(g.Dice) != len(before.Dice) {
		t.Fatalf("dice = %v, want %v", g.Dice, before.Dice)
	}
	for i := range g.Dice {
		if g.Dice[i] != before.Dice[i] {
			t.Fatalf("dice = %v, want %v", g.Dice, before.Dice)
		}
	}
}

func TestBotHitsBlotInsteadOfShuffling(t *testing.T) {
	g := NewGame(ModeShort)
	g.Board = [Points]int{}
	g.setTrack(0, 10, 1)
	g.setTrack(0, 18, 2)
	g.setTrack(0, 19, 2)
	g.setTrack(0, 20, 2)
	g.setTrack(0, 21, 2)
	g.setTrack(0, 22, 3)
	g.setTrack(0, 23, 3)
	// Блот соперника на нашей дорожке 13 — бьётся тройкой с 10.
	g.setTrack(1, BoardToTrack(ModeShort, 1, TrackToBoard(ModeShort, 0, 13)), 1)
	g.setTrack(1, 0, 14)
	if err := g.RollWith(3, 1); err != nil {
		t.Fatal(err)
	}
	if g.OpponentAt(0, 13) != 1 {
		t.Fatalf("setup blot = %d", g.OpponentAt(0, 13))
	}
	playRemainingDice(t, g)
	if g.Bar[1] < 1 {
		t.Fatal("bot left the blot and did not hit")
	}
}

func TestBotBearsOffToSaveMars(t *testing.T) {
	g := NewGame(ModeShort)
	g.Board = [Points]int{}
	g.setTrack(0, 18, 14)
	g.setTrack(0, 23, 1)
	g.Off[1] = 10
	g.setTrack(1, 20, 5)
	if err := g.RollWith(1, 2); err != nil {
		t.Fatal(err)
	}
	playRemainingDice(t, g)
	if g.Off[0] == 0 {
		t.Fatal("bot refused to bear off while facing a mars")
	}
}

func TestShortBotResistsMars(t *testing.T) {
	// Бот играет и первым, и вторым против жадного гонщика.
	for _, botSeat := range []int{0, 1} {
		mars, losses := 0, 0
		for seed := int64(1); seed <= 4; seed++ {
			winner, kind := playRacerVsBot(t, ModeShort, botSeat, seed)
			if winner < 0 {
				t.Fatalf("short botSeat %d seed %d unfinished", botSeat, seed)
			}
			if winner != botSeat {
				losses++
				if kind == "mars" {
					mars++
				}
			}
		}
		t.Logf("short botSeat=%d losses=%d mars=%d", botSeat, losses, mars)
		if mars > 0 {
			t.Fatalf("short botSeat %d lost %d games by mars", botSeat, mars)
		}
	}
}

func TestLongBotResistsMars(t *testing.T) {
	for _, botSeat := range []int{0, 1} {
		mars, losses := 0, 0
		for seed := int64(1); seed <= 3; seed++ {
			winner, kind := playRacerVsBot(t, ModeLong, botSeat, seed)
			if winner < 0 {
				t.Fatalf("long botSeat %d seed %d unfinished", botSeat, seed)
			}
			if winner != botSeat {
				losses++
				if kind == "mars" {
					mars++
				}
			}
		}
		t.Logf("long botSeat=%d losses=%d mars=%d", botSeat, losses, mars)
		if mars > 0 {
			t.Fatalf("long botSeat %d lost %d games by mars", botSeat, mars)
		}
	}
}

func playRacerVsBot(t *testing.T, mode string, botSeat int, seed int64) (winner int, kind string) {
	t.Helper()
	g := NewGame(mode)
	rng := rand.New(rand.NewSource(seed))
	for step := 0; step < 12000 && g.Winner < 0; step++ {
		if len(g.Dice) == 0 {
			if len(g.History) > 0 {
				g.EndTurn()
				continue
			}
			if err := g.Roll(rng); err != nil {
				t.Fatal(err)
			}
			continue
		}
		var (
			mv Move
			ok bool
		)
		if g.Turn == botSeat {
			mv, ok = BotBestMove(g, rng)
		} else {
			mv, ok = racerMove(g)
		}
		if !ok {
			g.EndTurn()
			continue
		}
		if err := g.ApplyMove(g.Turn, mv); err != nil {
			t.Fatalf("%s seed %d move %+v: %v", mode, seed, mv, err)
		}
	}
	return g.Winner, g.WinKind
}

func playRemainingDice(t *testing.T, g *Game) {
	t.Helper()
	rng := rand.New(rand.NewSource(1))
	for len(g.Dice) > 0 && g.Winner < 0 {
		mv, ok := BotBestMove(g, rng)
		if !ok {
			t.Fatal("no move while dice remain")
		}
		if err := g.ApplyMove(g.Turn, mv); err != nil {
			t.Fatalf("move %+v: %v", mv, err)
		}
	}
}

// racerMove — жадный соперник: бьёт, снимает и сокращает путь.
func racerMove(g *Game) (Move, bool) {
	moves := g.LegalMoves()
	if len(moves) == 0 {
		return Move{}, false
	}
	seat := g.Turn
	opp := Opponent(seat)
	best := moves[0]
	bestScore := -1 << 30
	for _, mv := range moves {
		undo, ok := g.applySearch(mv)
		if !ok {
			continue
		}
		score := g.Off[seat]*1000 - g.Pips(seat)*4 + g.Bar[opp]*250 - g.Bar[seat]*300
		g.undoSearch(undo)
		if score > bestScore {
			bestScore = score
			best = mv
		}
	}
	return best, true
}
