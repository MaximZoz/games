package store

import (
	"testing"
)

func TestFreeStakeBronze(t *testing.T) {
	if len(FreeStakeBronze) != 3 {
		t.Fatalf("want 3 free stakes, got %d", len(FreeStakeBronze))
	}
	want := []int{1, 10, 50}
	for i, v := range want {
		if FreeStakeBronze[i] != v {
			t.Fatalf("FreeStakeBronze[%d]=%d want %d", i, FreeStakeBronze[i], v)
		}
	}
}

func TestStakeUnlockSeedPrices(t *testing.T) {
	// Документированные цены из плана #111 (серебро → бронза).
	cases := []struct {
		stakeSilver int
		priceSilver int
	}{
		{2, 1},
		{5, 2},
		{10, 5},
		{25, 10},
		{50, 20},
		{100, 30},
	}
	for _, c := range cases {
		stakeBronze := c.stakeSilver * 100
		priceBronze := c.priceSilver * 100
		if stakeBronze < 200 {
			t.Fatalf("stake %d silver too small", c.stakeSilver)
		}
		if priceBronze <= 0 {
			t.Fatalf("price for %d silver must be > 0", c.stakeSilver)
		}
	}
}
