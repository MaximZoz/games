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
		{"", false},
	}
	for _, tc := range cases {
		got := IsRestrictedChatMessageAllowed(tc.body)
		if got != tc.ok {
			t.Fatalf("%q: got %v, want %v", tc.body, got, tc.ok)
		}
	}
}
