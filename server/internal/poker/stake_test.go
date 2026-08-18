package poker

import "testing"

func TestPlaceCreditConservation(t *testing.T) {
	for _, n := range []int{2, 3, 4, 5, 6} {
		for _, stake := range []int{2, 10, 50} {
			sum := 0
			for place := 1; place <= n; place++ {
				sum += PlaceCredit(stake, n, place)
			}
			want := stake * n
			if sum != want {
				t.Fatalf("n=%d stake=%d sum=%d want %d", n, stake, sum, want)
			}
		}
	}
}

func TestPlaceCreditShares(t *testing.T) {
	cases := []struct {
		n, stake, place, want int
	}{
		{2, 10, 1, 20},
		{2, 10, 2, 0},
		{3, 10, 1, 20},
		{3, 10, 2, 10},
		{3, 10, 3, 0},
		{4, 10, 1, 30},
		{4, 10, 2, 10},
		{4, 10, 3, 0},
		{5, 10, 1, 30},
		{5, 10, 2, 10},
		{5, 10, 3, 10},
		{5, 10, 4, 0},
		{6, 10, 1, 40},
		{6, 10, 2, 10},
		{6, 10, 3, 10},
		{6, 10, 6, 0},
	}
	for _, tc := range cases {
		if got := PlaceCredit(tc.stake, tc.n, tc.place); got != tc.want {
			t.Fatalf("PlaceCredit(%d,%d,%d)=%d want %d", tc.stake, tc.n, tc.place, got, tc.want)
		}
	}
}

func TestPlaceNetProfit(t *testing.T) {
	if PlaceNetProfit(10, 3, 1) != 10 {
		t.Fatalf("1st net want 10")
	}
	if PlaceNetProfit(10, 3, 2) != 0 {
		t.Fatalf("2nd net want 0")
	}
	if PlaceNetProfit(10, 3, 3) != 0 {
		t.Fatalf("3rd net want 0")
	}
}
