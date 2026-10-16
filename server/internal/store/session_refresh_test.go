package store

import (
	"testing"
	"time"
)

func TestPresentedRefreshAccepted(t *testing.T) {
	now := time.Date(2026, 10, 16, 12, 0, 0, 0, time.UTC)
	until := now.Add(time.Hour)

	if !PresentedRefreshAccepted("current", "prev", until, true, "current", now) {
		t.Fatal("current hash must be accepted")
	}
	if !PresentedRefreshAccepted("current", "prev", until, true, "prev", now) {
		t.Fatal("previous hash inside grace must be accepted")
	}
	if PresentedRefreshAccepted("current", "prev", until, true, "prev", until) {
		t.Fatal("previous hash at grace deadline must be rejected")
	}
	if PresentedRefreshAccepted("current", "prev", until, true, "older", now) {
		t.Fatal("unknown hash must be rejected")
	}
	if PresentedRefreshAccepted("current", "prev", until, false, "prev", now) {
		t.Fatal("previous hash without a stored value must be rejected")
	}
	if PresentedRefreshAccepted("current", "", until, true, "prev", now) {
		t.Fatal("empty previous hash must be rejected")
	}
	if PresentedRefreshAccepted("current", "prev", until, true, "", now) {
		t.Fatal("empty presented hash must be rejected")
	}
}
