package api

import (
	"testing"
	"time"
)

func TestBattleshipBotActDelay(t *testing.T) {
	if got := battleshipBotActDelay(false); got != time.Second {
		t.Fatalf("first bot shot delay: got %s want 1s", got)
	}
	if got := battleshipBotActDelay(true); got != time.Second {
		t.Fatalf("bot hit-continue delay: got %s want 1s", got)
	}
	if battleshipBotActDelay(true) != battleshipBotActDelay(false) {
		t.Fatal("bot pauses after a miss and after a hit must both be 1s")
	}
}
