package api

import (
	"testing"

	"multigames/server/internal/store"
)

func TestApplyPokerPublicProfile(t *testing.T) {
	age := 27
	gender := " female "
	about := "  играю по вечерам  "
	entry := map[string]any{}
	applyPokerPublicProfile(entry, &store.User{
		Age:    &age,
		Gender: &gender,
		About:  &about,
	})
	if entry["age"] != 27 {
		t.Fatalf("age = %v", entry["age"])
	}
	if entry["gender"] != "female" {
		t.Fatalf("gender = %v", entry["gender"])
	}
	if entry["about"] != "играю по вечерам" {
		t.Fatalf("about = %v", entry["about"])
	}

	blank := "  "
	zero := 0
	empty := map[string]any{}
	applyPokerPublicProfile(empty, &store.User{
		Age:    &zero,
		Gender: &blank,
		About:  &blank,
	})
	if len(empty) != 0 {
		t.Fatalf("empty profile leaked: %v", empty)
	}
	applyPokerPublicProfile(empty, nil)
}
