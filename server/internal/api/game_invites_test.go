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
