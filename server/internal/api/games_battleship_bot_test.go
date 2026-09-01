package api

import (
	"testing"
	"time"
)

func TestBattleshipBotActDelay(t *testing.T) {
	if got := battleshipBotActDelay(false); got != 700*time.Millisecond {
		t.Fatalf("first bot shot delay: got %s want 700ms", got)
	}
	if got := battleshipBotActDelay(true); got != 1100*time.Millisecond {
		t.Fatalf("bot hit-continue delay: got %s want 1100ms", got)
	}
	if battleshipBotActDelay(true) <= battleshipBotActDelay(false) {
		t.Fatal("hit-continue must be longer than the first shot pause")
	}
}
