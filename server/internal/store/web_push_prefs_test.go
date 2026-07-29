package store

import "testing"

func TestCategoryEnabled(t *testing.T) {
	p := WebPushPreferences{Chat: true, Friends: false, Games: true, Rewards: false}
	if !categoryEnabled(p, WebPushCategoryChat) {
		t.Fatal("chat should be on")
	}
	if categoryEnabled(p, WebPushCategoryFriends) {
		t.Fatal("friends should be off")
	}
	if !categoryEnabled(p, WebPushCategoryGames) {
		t.Fatal("games should be on")
	}
	if categoryEnabled(p, WebPushCategoryRewards) {
		t.Fatal("rewards should be off")
	}
	if !categoryEnabled(p, "unknown") {
		t.Fatal("unknown category defaults to on")
	}
}
