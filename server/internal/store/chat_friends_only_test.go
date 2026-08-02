package store

import "testing"

func TestIsRestrictedChatMessageAllowed(t *testing.T) {
	cases := []struct {
		body string
		ok   bool
	}{
		{"[ae:smile]", true},
		{"[ae:kissingHeart]", true},
		{"  [ae:rocket]  ", true},
		{"[ae:bad-name]", false},
		{"[ae:smile] hello", false},
		{"hello", false},
		{"[gift_coll:c1|Title|🎁|sparkles]", true},
		{"[gift_coll:a/b|Hi/there|x/y|name/z]", true},
		{"gift_coll:c1|Title|🎁|sparkles", false},
		{"[coins_credit:11111111-1111-1111-1111-111111111111|230|reason]", true},
		{"[coins_credit:11111111-1111-1111-1111-111111111111|230|reason|claimed]", true},
		{"", false},
	}
	for _, tc := range cases {
		got := IsRestrictedChatMessageAllowed(tc.body)
		if got != tc.ok {
			t.Fatalf("%q: got %v, want %v", tc.body, got, tc.ok)
		}
	}
}

func TestIsInviteLobbyShareBody(t *testing.T) {
	cases := []struct {
		body string
		ok   bool
	}{
		{"https://example.com/games/tictactoe/lobby/abc-123?mode=invite", true},
		{"/games/tictactoe/lobby/abc-123?mode=invite", true},
		{"  https://x.test/games/tictactoe/lobby/uuid  ", true},
		{"https://example.com/games/tictactoe/game/abc", false},
		{"hello https://example.com/games/tictactoe/lobby/abc", false},
		{"", false},
	}
	for _, tc := range cases {
		got := IsInviteLobbyShareBody(tc.body)
		if got != tc.ok {
			t.Fatalf("%q: got %v, want %v", tc.body, got, tc.ok)
		}
	}
}

func TestInviteLobbyIDFromBody(t *testing.T) {
	id, ok := InviteLobbyIDFromBody(
		"https://example.com/games/tictactoe/lobby/abc-123?mode=invite",
	)
	if !ok || id != "abc-123" {
		t.Fatalf("got (%q, %v), want (abc-123, true)", id, ok)
	}
	if _, ok := InviteLobbyIDFromBody("not a link"); ok {
		t.Fatal("expected false for plain text")
	}
}
