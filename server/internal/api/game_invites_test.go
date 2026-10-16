package api

import "testing"

func TestLobbyIDFromInvitedKey(t *testing.T) {
	if got := lobbyIDFromInvitedKey("lobby:abc-123:invited"); got != "abc-123" {
		t.Fatalf("lobbyIDFromInvitedKey = %q", got)
	}
	if got := lobbyIDFromInvitedKey("lobby:"); got != "" {
		t.Fatalf("empty key gave %q", got)
	}
}

func TestMergePendingInviteLobbyIDs(t *testing.T) {
	got := mergePendingInviteLobbyIDs(
		[]string{"from-index", "both"},
		[]string{"lobby:from-scan:invited", "lobby:both:invited", "bad"},
	)
	want := []string{"from-index", "both", "from-scan"}
	if len(got) != len(want) {
		t.Fatalf("len=%d want %d (%v)", len(got), len(want), got)
	}
	for i, id := range want {
		if got[i] != id {
			t.Fatalf("got[%d]=%q want %q (%v)", i, got[i], id, got)
		}
	}
}

func TestUserInvitesRedisKey(t *testing.T) {
	if got := userInvitesRedisKey("u1"); got != "user:u1:invites" {
		t.Fatalf("key = %q", got)
	}
}

func TestLobbyDeclinedRedisKey(t *testing.T) {
	if got := lobbyDeclinedRedisKey("L1"); got != "lobby:L1:declined" {
		t.Fatalf("key = %q", got)
	}
}

func TestPendingInviteVisible(t *testing.T) {
	if !pendingInviteVisible(true, "", "u1", false) {
		t.Fatal("invited user should see the card")
	}
	if !pendingInviteVisible(false, "u1", "u1", false) {
		t.Fatal("invite target should see the card")
	}
	if pendingInviteVisible(true, "u1", "u1", true) {
		t.Fatal("declined invite must stay hidden")
	}
	if pendingInviteVisible(false, "other", "u1", false) {
		t.Fatal("stranger must not see the card")
	}
}
