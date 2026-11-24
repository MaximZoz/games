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

// Сервер зависал или связь рвалась: клиент шлёт один и тот же refresh, а
// ответы с новыми токенами до него не доходят. Сессия обязана пережить
// любое число таких потерь и дождаться клиента с тем токеном, что у него есть.
func TestRefreshSurvivesLostResponses(t *testing.T) {
	now := time.Date(2026, 11, 24, 12, 0, 0, 0, time.UTC)
	until := now.Add(time.Hour)

	current, previous, previousSet := "r1", "", false
	rotate := func(presented, next string) bool {
		if !PresentedRefreshAccepted(current, previous, until, previousSet, presented, now) {
			return false
		}
		previous = PreviousRefreshAfterRotation(current, presented)
		previousSet = true
		current = next
		return true
	}

	for i, next := range []string{"r2", "r3", "r4", "r5"} {
		if !rotate("r1", next) {
			t.Fatalf("lost response #%d: the token the client still holds must be accepted", i+1)
		}
		if previous != "r1" {
			t.Fatalf("lost response #%d: previous = %q, want the client's r1", i+1, previous)
		}
	}

	// Ответ наконец дошёл: клиент живёт с r5, старый r1 своё отслужил.
	if !rotate("r5", "r6") {
		t.Fatal("delivered token must be accepted")
	}
	if previous != "r5" {
		t.Fatalf("after a normal rotation previous = %q, want r5", previous)
	}
	if rotate("r1", "r7") {
		t.Fatal("r1 must stop working once the client moved on")
	}
	// Токены, которые клиент так и не получил, сессию не открывают.
	for _, lost := range []string{"r2", "r3", "r4"} {
		if rotate(lost, "r8") {
			t.Fatalf("undelivered %s must be rejected", lost)
		}
	}
}
