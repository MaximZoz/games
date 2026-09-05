package checkers

import "testing"

func TestStartPosition(t *testing.T) {
	g := NewGame(ModeRussian)
	white, black := 0, 0
	for _, p := range g.Board {
		if p == WhiteMan {
			white++
		}
		if p == BlackMan {
			black++
		}
	}
	if white != 12 || black != 12 {
		t.Fatalf("start %d/%d", white, black)
	}
	if len(g.LegalMoves()) == 0 {
		t.Fatal("white must have quiet moves")
	}
}

func TestManCapture(t *testing.T) {
	g := NewGame(ModeRussian)
	for i := range g.Board {
		g.Board[i] = Empty
	}
	g.set(2, 1, WhiteMan)
	g.set(3, 2, BlackMan)
	moves := g.LegalMoves()
	if len(moves) != 1 {
		t.Fatalf("captures=%d %+v", len(moves), moves)
	}
	if err := g.Apply(0, moves[0]); err != nil {
		t.Fatal(err)
	}
	if g.at(3, 2) != Empty || g.at(4, 3) != WhiteMan {
		t.Fatalf("after capture board wrong")
	}
	if g.Turn != 1 {
		t.Fatalf("turn=%d", g.Turn)
	}
}

func TestPromotion(t *testing.T) {
	g := NewGame(ModeRussian)
	for i := range g.Board {
		g.Board[i] = Empty
	}
	g.set(6, 1, WhiteMan)
	mv := Move{From: Square{R: 6, C: 1}, To: Square{R: 7, C: 0}}
	if err := g.Apply(0, mv); err != nil {
		t.Fatal(err)
	}
	if g.at(7, 0) != WhiteKing {
		t.Fatalf("piece=%d", g.at(7, 0))
	}
}

func TestGiveawayNoMovesWins(t *testing.T) {
	g := NewGame(ModeGiveaway)
	for i := range g.Board {
		g.Board[i] = Empty
	}
	g.set(0, 1, WhiteMan)
	g.set(7, 0, BlackMan)
	g.set(6, 1, WhiteMan) // блокирует чёрную? нет — чёрная на 7,0 ходит на 6,1 занято и 6,-1 нет
	// Чёрные без тихих ходов и боёв: белая на 6,1 рядом по диагонали — бой есть.
	// Сделаем чёрную запертой без боя.
	for i := range g.Board {
		g.Board[i] = Empty
	}
	g.set(0, 1, WhiteMan)
	g.set(7, 0, BlackKing)
	g.set(6, 1, WhiteMan)
	g.set(5, 2, WhiteMan)
	g.Turn = 1
	g.resolveEnd()
	if g.Winner != 1 {
		t.Fatalf("giveaway winner=%d want black (loser of mobility)", g.Winner)
	}
}

func TestKingMustContinueAnyDirection(t *testing.T) {
	setup := func() *Game {
		g := NewGame(ModeRussian)
		for i := range g.Board {
			g.Board[i] = Empty
		}
		g.set(2, 1, WhiteKing)
		g.set(3, 2, BlackMan)
		g.set(5, 4, BlackMan)
		g.set(1, 2, BlackMan)
		g.Turn = 0
		return g
	}

	g := setup()
	moves := g.LegalMoves()
	hasLong, hasShort := false, false
	for _, m := range moves {
		if m.To == (Square{R: 4, C: 3}) {
			hasLong = true
		}
		if m.To == (Square{R: 0, C: 3}) {
			hasShort = true
		}
	}
	if !hasLong || !hasShort {
		t.Fatalf("expected both capture directions, got %+v", moves)
	}

	short := setup()
	if err := short.Apply(0, Move{
		From:   Square{R: 2, C: 1},
		To:     Square{R: 0, C: 3},
		Jumped: []Square{{R: 1, C: 2}},
	}); err != nil {
		t.Fatal(err)
	}
	if short.MustContinue || short.Turn != 1 {
		t.Fatalf("short path must end turn: continue=%v turn=%d", short.MustContinue, short.Turn)
	}

	if err := g.Apply(0, Move{
		From:   Square{R: 2, C: 1},
		To:     Square{R: 4, C: 3},
		Jumped: []Square{{R: 3, C: 2}},
	}); err != nil {
		t.Fatal(err)
	}
	if !g.MustContinue || g.Turn != 0 || g.ContR != 4 || g.ContC != 3 {
		t.Fatalf("must continue after first king capture: %+v", g)
	}
	cont := g.LegalMoves()
	if len(cont) == 0 {
		t.Fatal("king must have a follow-up capture")
	}
	for _, m := range cont {
		if m.From != (Square{R: 4, C: 3}) || len(m.Jumped) == 0 {
			t.Fatalf("illegal follow-up %+v", m)
		}
	}
	if err := g.Apply(0, Move{From: Square{R: 4, C: 3}, To: Square{R: 5, C: 2}}); err == nil {
		t.Fatal("quiet stop in a capture sequence must be illegal")
	}
	if err := g.Apply(0, cont[0]); err != nil {
		t.Fatal(err)
	}
	if g.at(5, 4) != Empty || g.MustContinue {
		t.Fatalf("second capture must finish sequence")
	}
}

func TestEncodeDecode(t *testing.T) {
	g := NewGame(ModeRussian)
	raw, err := Encode(g)
	if err != nil {
		t.Fatal(err)
	}
	got, err := Decode(raw)
	if err != nil {
		t.Fatal(err)
	}
	if len(got.LegalMoves()) != len(g.LegalMoves()) {
		t.Fatal("roundtrip legal mismatch")
	}
}
