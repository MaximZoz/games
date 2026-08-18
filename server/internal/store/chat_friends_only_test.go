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
	cases := []struct {
		body string
		id   string
		ok   bool
	}{
		{"https://example.com/games/tictactoe/lobby/abc-123?mode=invite", "abc-123", true},
		{"/games/durak/lobby/dur-1?mode=invite", "dur-1", true},
		{"https://example.com/games/battleship/lobby/bs-9?mode=invite", "bs-9", true},
		{"not a link", "", false},
		{"/games/poker/lobby/x?mode=invite", "x", true},
	}
	for _, tc := range cases {
		id, ok := InviteLobbyIDFromBody(tc.body)
		if ok != tc.ok || id != tc.id {
			t.Fatalf("body %q: got (%q, %v), want (%q, %v)", tc.body, id, ok, tc.id, tc.ok)
		}
	}
}
