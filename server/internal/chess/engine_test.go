package chess

import "testing"

func moveExists(moves []Move, fr, fc, tr, tc int) bool {
	for _, m := range moves {
		if m.From.R == fr && m.From.C == fc && m.To.R == tr && m.To.C == tc {
			return true
		}
	}
	return false
}

func clearBoard(g *Game) {
	for i := range g.Board {
		g.Board[i] = Empty
	}
}

func TestNewGameStartPosition(t *testing.T) {
	g := NewGame(ModeClassic)
	if g.Turn != 0 || g.IsOver() {
		t.Fatalf("new game turn/over: %+v", g.Turn)
	}
	if g.at(0, 4) != WhiteKing || g.at(7, 4) != BlackKing {
		t.Fatalf("kings misplaced")
	}
	moves := g.LegalMoves()
	if len(moves) != 20 {
		t.Fatalf("start position should have 20 moves, got %d", len(moves))
	}
}

func TestPawnDoubleStepAndEnPassant(t *testing.T) {
	g := NewGame(ModeClassic)
	// 1. e4
	if err := g.Apply(0, Move{From: Square{1, 4}, To: Square{3, 4}}); err != nil {
		t.Fatalf("e4: %v", err)
	}
	if g.EnPassant != g.idx(2, 4) {
		t.Fatalf("en passant target not set after double step: %d", g.EnPassant)
	}
	// 1... a6 (quiet)
	if err := g.Apply(1, Move{From: Square{6, 0}, To: Square{5, 0}}); err != nil {
		t.Fatalf("a6: %v", err)
	}
	if g.EnPassant != -1 {
		t.Fatalf("en passant should clear after non-double move")
	}
}

func TestEnPassantCapture(t *testing.T) {
	g := NewGame(ModeClassic)
	clearBoard(g)
	g.set(0, 4, WhiteKing)
	g.set(7, 4, BlackKing)
	g.set(4, 4, WhitePawn) // white pawn e5
	g.set(6, 3, BlackPawn) // black pawn d7
	g.Castle = [4]bool{}
	g.Turn = 1
	g.EnPassant = -1
	// black plays d7-d5 (double) allowing en passant on d6
	if err := g.Apply(1, Move{From: Square{6, 3}, To: Square{4, 3}}); err != nil {
		t.Fatalf("d5: %v", err)
	}
	if g.EnPassant != g.idx(5, 3) {
		t.Fatalf("ep target expected d6, got %d", g.EnPassant)
	}
	// white captures en passant e5xd6
	moves := g.LegalMoves()
	if !moveExists(moves, 4, 4, 5, 3) {
		t.Fatalf("en passant capture not generated: %+v", moves)
	}
	if err := g.Apply(0, Move{From: Square{4, 4}, To: Square{5, 3}}); err != nil {
		t.Fatalf("exd6 ep: %v", err)
	}
	if g.at(4, 3) != Empty {
		t.Fatalf("captured pawn should be removed by en passant")
	}
	if g.at(5, 3) != WhitePawn {
		t.Fatalf("white pawn should be on d6")
	}
}

func TestCastlingKingside(t *testing.T) {
	g := NewGame(ModeClassic)
	clearBoard(g)
	g.set(0, 4, WhiteKing)
	g.set(0, 7, WhiteRook)
	g.set(7, 4, BlackKing)
	g.Castle = [4]bool{true, false, false, false}
	g.Turn = 0
	g.EnPassant = -1
	moves := g.LegalMoves()
	if !moveExists(moves, 0, 4, 0, 6) {
		t.Fatalf("kingside castle not available: %+v", moves)
	}
	if err := g.Apply(0, Move{From: Square{0, 4}, To: Square{0, 6}}); err != nil {
		t.Fatalf("O-O: %v", err)
	}
	if g.at(0, 6) != WhiteKing || g.at(0, 5) != WhiteRook {
		t.Fatalf("castling did not move rook/king correctly")
	}
	if g.Castle[cWK] || g.Castle[cWQ] {
		t.Fatalf("castle rights should be gone after castling")
	}
}

func TestCastlingBlockedThroughCheck(t *testing.T) {
	g := NewGame(ModeClassic)
	clearBoard(g)
	g.set(0, 4, WhiteKing)
	g.set(0, 7, WhiteRook)
	g.set(7, 5, BlackRook) // controls f-file -> f1 attacked
	g.set(7, 4, BlackKing)
	g.Castle = [4]bool{true, false, false, false}
	g.Turn = 0
	g.EnPassant = -1
	moves := g.LegalMoves()
	if moveExists(moves, 0, 4, 0, 6) {
		t.Fatalf("castling through attacked square must be illegal")
	}
}

func TestCannotLeaveKingInCheck(t *testing.T) {
	g := NewGame(ModeClassic)
	clearBoard(g)
	g.set(0, 4, WhiteKing)
	g.set(1, 4, WhiteBishop) // pinned bishop on e2
	g.set(7, 4, BlackRook)   // rook pins along e-file
	g.set(7, 0, BlackKing)
	g.Castle = [4]bool{}
	g.Turn = 0
	g.EnPassant = -1
	moves := g.LegalMoves()
	// Bishop may not move off the e-file (would expose king).
	for _, m := range moves {
		if m.From.R == 1 && m.From.C == 4 && m.To.C != 4 {
			t.Fatalf("pinned bishop illegally moved off pin: %+v", m)
		}
	}
}

func TestPromotionGeneratesFour(t *testing.T) {
	g := NewGame(ModeClassic)
	clearBoard(g)
	g.set(0, 0, WhiteKing)
	g.set(6, 1, WhitePawn) // b7
	g.set(7, 7, BlackKing)
	g.Castle = [4]bool{}
	g.Turn = 0
	g.EnPassant = -1
	moves := g.LegalMoves()
	promos := 0
	for _, m := range moves {
		if m.From.R == 6 && m.From.C == 1 && m.To.R == 7 && m.To.C == 1 {
			promos++
		}
	}
	if promos != 4 {
		t.Fatalf("expected 4 promotion moves, got %d", promos)
	}
	if err := g.Apply(0, Move{From: Square{6, 1}, To: Square{7, 1}, Promo: WhiteKnight}); err != nil {
		t.Fatalf("promote knight: %v", err)
	}
	if g.at(7, 1) != WhiteKnight {
		t.Fatalf("pawn did not promote to knight")
	}
}

func TestFoolsMateCheckmate(t *testing.T) {
	g := NewGame(ModeClassic)
	// 1. f3 e5 2. g4 Qh4#
	seq := []struct {
		seat   int
		fr, fc int
		tr, tc int
	}{
		{0, 1, 5, 2, 5}, // f3
		{1, 6, 4, 4, 4}, // e5
		{0, 1, 6, 3, 6}, // g4
		{1, 7, 3, 3, 7}, // Qd8-h4
	}
	for i, s := range seq {
		if err := g.Apply(s.seat, Move{From: Square{s.fr, s.fc}, To: Square{s.tr, s.tc}}); err != nil {
			t.Fatalf("move %d: %v", i, err)
		}
	}
	if !g.IsOver() {
		t.Fatalf("fool's mate should end the game")
	}
	if g.Winner != 1 {
		t.Fatalf("black should win fool's mate, winner=%d", g.Winner)
	}
}

func TestStalemateIsDraw(t *testing.T) {
	g := NewGame(ModeClassic)
	clearBoard(g)
	g.set(7, 7, BlackKing) // h8
	g.set(5, 6, WhiteQueen) // g6 covers h7/g7/g8 but not h8
	g.set(5, 5, WhiteKing)  // f6 supports
	g.Castle = [4]bool{}
	g.Turn = 1
	g.EnPassant = -1
	g.resolveEnd()
	if !g.IsOver() || g.Winner != WinnerDraw || g.DrawReason != DrawReasonStalemate {
		t.Fatalf("expected stalemate draw, got winner=%d reason=%s", g.Winner, g.DrawReason)
	}
}

func TestInsufficientMaterial(t *testing.T) {
	g := NewGame(ModeClassic)
	clearBoard(g)
	g.set(0, 4, WhiteKing)
	g.set(7, 4, BlackKing)
	g.set(3, 3, WhiteKnight)
	g.Castle = [4]bool{}
	g.Turn = 1
	g.EnPassant = -1
	g.resolveEnd()
	if !g.IsOver() || g.DrawReason != DrawReasonInsufficient {
		t.Fatalf("K+N vs K should be insufficient material draw: %d/%s", g.Winner, g.DrawReason)
	}
}

func TestForfeitAndDraw(t *testing.T) {
	g := NewGame(ModeClassic)
	g.Forfeit(0)
	if g.Winner != 1 {
		t.Fatalf("forfeit by white should give black the win")
	}
	g2 := NewGame(ModeClassic)
	g2.AgreeDraw()
	if g2.Winner != WinnerDraw || g2.DrawReason != DrawReasonAgreed {
		t.Fatalf("agree draw failed: %d/%s", g2.Winner, g2.DrawReason)
	}
}

func TestEncodeDecodeRoundTrip(t *testing.T) {
	g := NewGame(ModeBlitz)
	_ = g.Apply(0, Move{From: Square{1, 4}, To: Square{3, 4}})
	raw, err := Encode(g)
	if err != nil {
		t.Fatalf("encode: %v", err)
	}
	g2, err := Decode(raw)
	if err != nil {
		t.Fatalf("decode: %v", err)
	}
	if g2.Mode != ModeBlitz || g2.Turn != g.Turn || len(g2.Board) != Size*Size {
		t.Fatalf("round trip mismatch: %+v", g2)
	}
	if g2.EnPassant != g.EnPassant {
		t.Fatalf("en passant not preserved: %d vs %d", g2.EnPassant, g.EnPassant)
	}
}

func TestThreefoldRepetition(t *testing.T) {
	g := NewGame(ModeClassic)
	// Shuffle knights back and forth: Nf3 Nf6 Ng1 Ng8 repeated.
	cycle := []struct {
		seat   int
		fr, fc int
		tr, tc int
	}{
		{0, 0, 6, 2, 5}, // Ng1-f3
		{1, 7, 6, 5, 5}, // Ng8-f6
		{0, 2, 5, 0, 6}, // Nf3-g1
		{1, 5, 5, 7, 6}, // Nf6-g8
	}
	for i := 0; i < 3; i++ {
		for _, s := range cycle {
			if g.IsOver() {
				break
			}
			if err := g.Apply(s.seat, Move{From: Square{s.fr, s.fc}, To: Square{s.tr, s.tc}}); err != nil {
				t.Fatalf("cycle move: %v", err)
			}
		}
	}
	if !g.IsOver() || g.DrawReason != DrawReasonRepetition {
		t.Fatalf("expected threefold repetition draw, got %d/%s", g.Winner, g.DrawReason)
	}
}
