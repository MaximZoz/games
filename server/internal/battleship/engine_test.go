package battleship

import (
	"math/rand"
	"testing"
)

func TestValidateShipsOK(t *testing.T) {
	ships := Ships{
		{0, 1, 2, 3},
		{5, 6, 7},
		{20, 21, 22},
		{40, 41},
		{43, 44},
		{46, 47},
		{60},
		{62},
		{64},
		{66},
	}
	if err := ValidateShips(ships); err != nil {
		t.Fatalf("valid fleet: %v", err)
	}
}

func TestValidateShipsTouchDiagonal(t *testing.T) {
	// 11=(1,1) касается 0=(0,0) по диагонали.
	ships := Ships{
		{0, 1, 2, 3},
		{5, 6, 7},
		{20, 21, 22},
		{40, 41},
		{43, 44},
		{46, 47},
		{9},
		{11},
		{60},
		{62},
	}
	if err := ValidateShips(ships); err == nil {
		t.Fatal("expected touch error")
	}
}

func TestValidateShipsNotStraight(t *testing.T) {
	ships := Ships{
		{0, 1, 12, 13}, // not a line
		{5, 6, 7},
		{20, 21, 22},
		{40, 41},
		{43, 44},
		{46, 47},
		{60},
		{62},
		{64},
		{66},
	}
	if err := ValidateShips(ships); err == nil {
		t.Fatal("expected not-straight error")
	}
}

func TestValidateShipsWrongFleet(t *testing.T) {
	ships := Ships{
		{0, 1, 2, 3, 4}, // 5 — wrong
		{5, 6, 7},
		{20, 21, 22},
		{40, 41},
		{43, 44},
		{46, 47},
		{60},
		{62},
		{64},
		{66},
	}
	if err := ValidateShips(ships); err == nil {
		t.Fatal("expected fleet mismatch")
	}
}

func TestJSONRoundTrip(t *testing.T) {
	ships := fallbackShips()
	raw := ShipsToJSON(ships)
	got, err := ParseShipsJSON(raw)
	if err != nil {
		t.Fatal(err)
	}
	if len(got) != len(ships) {
		t.Fatalf("len %d", len(got))
	}
	shots := []int{0, 5, 99}
	sraw := ShotsToJSON(shots)
	sgot, err := ParseShotsJSON(sraw)
	if err != nil || len(sgot) != 3 {
		t.Fatalf("shots %v %v", sgot, err)
	}
}

func TestHitSunk(t *testing.T) {
	ships := fallbackShips()
	if IsHit(ships, 0) != true || IsHit(ships, 8) != false {
		t.Fatal("IsHit")
	}
	if AllSunk(ships, []int{0, 1, 2, 3}) {
		t.Fatal("not all sunk yet")
	}
	all := make([]int, 0, 20)
	for _, s := range ships {
		all = append(all, s...)
	}
	if !AllSunk(ships, all) {
		t.Fatal("should be all sunk")
	}
	hits := CollectHitCells(ships, []int{0, 1, 99})
	if len(hits) != 2 || hits[0] != 0 || hits[1] != 1 {
		t.Fatalf("CollectHitCells: %v", hits)
	}
	sunkShips := CollectSunkShips(ships, []int{0, 1, 2, 3, 99})
	if len(sunkShips) != 1 || len(sunkShips[0]) != 4 {
		t.Fatalf("CollectSunkShips: %v", sunkShips)
	}
	sunk := CollectSunkCells(ships, []int{0, 1, 2, 3, 99})
	if len(sunk) != 4 {
		t.Fatalf("sunk cells %v", sunk)
	}
}

func TestRandomShipsValid(t *testing.T) {
	rng := rand.New(rand.NewSource(42))
	for i := 0; i < 20; i++ {
		ships := RandomShips(rng)
		if err := ValidateShips(ships); err != nil {
			t.Fatalf("attempt %d: %v ships=%v", i, err, ships)
		}
	}
}

func TestBotPickShotPrefersNeighbors(t *testing.T) {
	ships := Ships{
		{0, 1, 2, 3},
		{5, 6, 7},
		{20, 21, 22},
		{40, 41},
		{43, 44},
		{46, 47},
		{60},
		{62},
		{64},
		{66},
	}
	shots := []int{0} // hit
	cands := BotNeighborCandidates(ships, shots)
	if len(cands) == 0 {
		t.Fatal("expected neighbors")
	}
	// Only orthogonal: 1 (right) and 10 (down).
	found1, found10 := false, false
	for _, c := range cands {
		if c == 1 {
			found1 = true
		}
		if c == 10 {
			found10 = true
		}
	}
	if !found1 || !found10 {
		t.Fatalf("cands=%v", cands)
	}
	rng := rand.New(rand.NewSource(1))
	cell, err := BotPickShot(ships, shots, rng)
	if err != nil {
		t.Fatal(err)
	}
	ok := false
	for _, c := range cands {
		if c == cell {
			ok = true
		}
	}
	if !ok {
		t.Fatalf("pick %d not in %v", cell, cands)
	}
}

func TestBotPickShotExtendsHitLine(t *testing.T) {
	ships := Ships{
		{0, 1, 2, 3},
		{5, 6, 7},
		{20, 21, 22},
		{40, 41},
		{43, 44},
		{46, 47},
		{60},
		{62},
		{64},
		{66},
	}
	cell, err := BotPickShot(ships, []int{0, 1}, rand.New(rand.NewSource(1)))
	if err != nil {
		t.Fatal(err)
	}
	if cell != 2 {
		t.Fatalf("must continue the hit line, got %d", cell)
	}
}

func TestBotPickShotExhausted(t *testing.T) {
	ships := fallbackShips()
	shots := make([]int, CellCount)
	for i := range shots {
		shots[i] = i
	}
	_, err := BotPickShot(ships, shots, rand.New(rand.NewSource(1)))
	if err == nil {
		t.Fatal("expected error when board full")
	}
}

func TestParseEmpty(t *testing.T) {
	s, err := ParseShipsJSON("")
	if err != nil || s != nil {
		t.Fatalf("%v %v", s, err)
	}
	sh, err := ParseShotsJSON("null")
	if err != nil || sh != nil {
		t.Fatalf("%v %v", sh, err)
	}
}
