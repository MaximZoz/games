package chess

import (
	"math/rand"
	"testing"
)

func TestBotPicksLegalMove(t *testing.T) {
	g := NewGame(ModeBlitz)
	rng := rand.New(rand.NewSource(42))
	mv, ok := PickMove(g, rng)
	if !ok {
		t.Fatalf("bot found no move in start position")
	}
	if err := g.Apply(g.Turn, mv); err != nil {
		t.Fatalf("bot picked illegal move: %v", err)
	}
}

func TestBotCapturesHangingQueen(t *testing.T) {
	g := NewGame(ModeBlitz)
	clearBoard(g)
	g.set(0, 4, WhiteKing)
	g.set(7, 4, BlackKing)
	g.set(3, 3, WhiteRook)  // d4 rook
	g.set(3, 6, BlackQueen) // g4 queen hanging on rank 4
	g.Castle = [4]bool{}
	g.Turn = 0
	g.EnPassant = -1
	rng := rand.New(rand.NewSource(7))
	mv, ok := PickMove(g, rng)
	if !ok {
		t.Fatalf("no move")
	}
	if !(mv.From.R == 3 && mv.From.C == 3 && mv.To.R == 3 && mv.To.C == 6) {
		t.Fatalf("bot failed to grab hanging queen, played %+v", mv)
	}
}

func TestPassedPawnOutranksBlockedPawn(t *testing.T) {
	passed := NewGame(ModeBlitz)
	clearBoard(passed)
	passed.set(0, 4, WhiteKing)
	passed.set(7, 4, BlackKing)
	passed.set(4, 0, WhitePawn) // a5, проходная
	blocked := passed.Clone()
	blocked.set(5, 0, BlackPawn) // a6 стопорит пешку
	if pawnStructure(passed, 0) <= pawnStructure(blocked, 0) {
		t.Fatalf("passed pawn structure %d, blocked %d",
			pawnStructure(passed, 0), pawnStructure(blocked, 0))
	}
}

func TestBotFindsMateInOne(t *testing.T) {
	g := NewGame(ModeBlitz)
	clearBoard(g)
	// Классический мат по последней горизонтали: король g8 заперт своими
	// пешками f7/g7/h7, ладья с a-линии даёт мат на a8.
	g.set(7, 6, BlackKing) // g8
	g.set(6, 5, BlackPawn) // f7
	g.set(6, 6, BlackPawn) // g7
	g.set(6, 7, BlackPawn) // h7
	g.set(0, 0, WhiteRook) // a1
	g.set(0, 4, WhiteKing) // e1
	g.Castle = [4]bool{}
	g.Turn = 0
	g.EnPassant = -1
	mv, ok := PickMove(g, rand.New(rand.NewSource(1)))
	if !ok {
		t.Fatalf("no move")
	}
	child := g.Clone()
	if err := child.Apply(0, mv); err != nil {
		t.Fatalf("illegal: %v", err)
	}
	if !child.IsOver() || child.Winner != 0 {
		t.Fatalf("bot missed back-rank mate, played %+v (over=%v winner=%d)", mv, child.IsOver(), child.Winner)
	}
}
