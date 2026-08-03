package gameengine

import "testing"

func TestClassicWin(t *testing.T) {
	eng, err := New(VariantClassic)
	if err != nil {
		t.Fatal(err)
	}
	st := eng.NewState()
	// x x x on first row
	for _, cell := range []int{0, 1} {
		st.Board[cell] = "x"
	}
	st.Turn = "x"
	res, err := eng.ApplyMove(st, 2)
	if err != nil {
		t.Fatal(err)
	}
	if res.State.Status != "won" || res.State.Winner != "x" {
		t.Fatalf("got status=%s winner=%s", res.State.Status, res.State.Winner)
	}
	if len(res.WinningCells) != 3 {
		t.Fatalf("winning cells: %v", res.WinningCells)
	}
}

func TestGomokuConfig(t *testing.T) {
	cfg, err := ConfigFor(VariantGomoku)
	if err != nil {
		t.Fatal(err)
	}
	if cfg.GridSize != 15 || cfg.WinLength != 5 || cfg.CellCount != 225 {
		t.Fatalf("unexpected gomoku cfg: %+v", cfg)
	}
}

func TestUltimateForcesNextBoard(t *testing.T) {
	eng, err := New(VariantUltimate)
	if err != nil {
		t.Fatal(err)
	}
	st := eng.NewState()
	res, err := eng.ApplyMove(st, 4) // center of board 0 → next = 4
	if err != nil {
		t.Fatal(err)
	}
	if res.State.NextBoard != 4 {
		t.Fatalf("next board want 4 got %d", res.State.NextBoard)
	}
	// Illegal: play outside board 4
	_, err = eng.ApplyMove(res.State, 0)
	if err != ErrIllegalMove {
		t.Fatalf("want illegal, got %v", err)
	}
	// Legal inside board 4
	_, err = eng.ApplyMove(res.State, 4*9+0)
	if err != nil {
		t.Fatal(err)
	}
}

func TestMulti3Marks(t *testing.T) {
	cfg, _ := ConfigFor(VariantMulti3)
	if cfg.MaxPlayers != 3 || len(cfg.Marks) != 3 {
		t.Fatalf("%+v", cfg)
	}
	eng, _ := New(VariantMulti3)
	st := eng.NewState()
	res, err := eng.ApplyMove(st, 0)
	if err != nil {
		t.Fatal(err)
	}
	if res.State.Turn != "o" {
		t.Fatalf("turn=%s", res.State.Turn)
	}
	res, err = eng.ApplyMove(res.State, 1)
	if err != nil {
		t.Fatal(err)
	}
	if res.State.Turn != "t" {
		t.Fatalf("turn=%s", res.State.Turn)
	}
}

func TestParseVariant(t *testing.T) {
	if ParseVariant("gomoku") != VariantGomoku {
		t.Fatal()
	}
	if ParseVariant("nope") != VariantClassic {
		t.Fatal()
	}
}
