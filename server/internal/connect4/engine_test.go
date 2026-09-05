package connect4

import "testing"

func TestDropWinsHorizontal(t *testing.T) {
	g := NewGame(ModeClassic)
	// P0: 0,1,2 then 3 wins on row 0.
	for c := 0; c < 3; c++ {
		if err := g.Drop(0, c); err != nil {
			t.Fatal(err)
		}
		if err := g.Drop(1, c); err != nil {
			t.Fatal(err)
		}
	}
	if err := g.Drop(0, 3); err != nil {
		t.Fatal(err)
	}
	if g.Winner != 0 {
		t.Fatalf("winner=%d", g.Winner)
	}
}

func TestColumnFull(t *testing.T) {
	g := NewGame(ModeClassic)
	for r := 0; r < g.Rows; r++ {
		seat := r % 2
		if err := g.Drop(seat, 0); err != nil {
			t.Fatal(err)
		}
	}
	if err := g.Drop(g.Turn, 0); err != ErrColumnFull {
		t.Fatalf("want column full, got %v", err)
	}
}

func TestWideBoard(t *testing.T) {
	g := NewGame(ModeWide)
	if g.Cols != 9 || g.Rows != 7 {
		t.Fatalf("size %dx%d", g.Cols, g.Rows)
	}
	if err := g.Drop(0, 8); err != nil {
		t.Fatal(err)
	}
}

func TestBotPicksWinningColumn(t *testing.T) {
	g := NewGame(ModeClassic)
	for c := 0; c < 3; c++ {
		_ = g.Drop(0, c)
		_ = g.Drop(1, c)
	}
	col := PickColumn(g, nil)
	if col != 3 {
		t.Fatalf("bot col=%d want 3", col)
	}
}

func TestEncodeDecode(t *testing.T) {
	g := NewGame(ModeClassic)
	_ = g.Drop(0, 3)
	raw, err := Encode(g)
	if err != nil {
		t.Fatal(err)
	}
	got, err := Decode(raw)
	if err != nil {
		t.Fatal(err)
	}
	if got.Board[3] != 1 || got.Turn != 1 {
		t.Fatalf("roundtrip %+v", got)
	}
}
