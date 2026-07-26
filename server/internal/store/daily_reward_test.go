package store

import (
	"testing"
	"time"
)

func TestDailyRewardBronzeForStreak(t *testing.T) {
	cases := map[int]int{
		1:  10,
		2:  10,
		3:  50,
		4:  10,
		7:  1000,
		8:  10,
		30: 3000,
		31: 10,
	}
	for streak, want := range cases {
		if got := DailyRewardBronzeForStreak(streak); got != want {
			t.Fatalf("streak %d: got %d, want %d", streak, got, want)
		}
	}
}

func TestNextDailyStreak(t *testing.T) {
	now := time.Date(2026, 7, 26, 15, 0, 0, 0, time.UTC)

	t.Run("first claim", func(t *testing.T) {
		if got := NextDailyStreak(nil, 0, now); got != 1 {
			t.Fatalf("got %d, want 1", got)
		}
	})

	t.Run("continue yesterday", func(t *testing.T) {
		yesterday := now.AddDate(0, 0, -1)
		if got := NextDailyStreak(&yesterday, 2, now); got != 3 {
			t.Fatalf("got %d, want 3", got)
		}
	})

	t.Run("break after gap", func(t *testing.T) {
		twoDaysAgo := now.AddDate(0, 0, -2)
		if got := NextDailyStreak(&twoDaysAgo, 5, now); got != 1 {
			t.Fatalf("got %d, want 1", got)
		}
	})

	t.Run("already claimed today keeps streak", func(t *testing.T) {
		if got := NextDailyStreak(&now, 7, now); got != 7 {
			t.Fatalf("got %d, want 7", got)
		}
	})

	t.Run("after day 30 cycle restarts", func(t *testing.T) {
		yesterday := now.AddDate(0, 0, -1)
		if got := NextDailyStreak(&yesterday, 30, now); got != 1 {
			t.Fatalf("got %d, want 1", got)
		}
	})
}
