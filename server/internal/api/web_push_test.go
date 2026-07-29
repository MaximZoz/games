package api

import "testing"

func TestNormalizeVapidSubscriber(t *testing.T) {
	cases := []struct {
		in, want string
	}{
		{"", "admin@zozu.games"},
		{"admin@zozu.games", "admin@zozu.games"},
		{"mailto:admin@zozu.games", "admin@zozu.games"},
		{"MAILTO:Admin@Zozu.Games", "Admin@Zozu.Games"},
		{"  mailto:ops@example.com  ", "ops@example.com"},
		{"https://zozu.games/contact", "https://zozu.games/contact"},
		{"mailto:", "admin@zozu.games"},
	}
	for _, tc := range cases {
		got := normalizeVapidSubscriber(tc.in)
		if got != tc.want {
			t.Fatalf("normalizeVapidSubscriber(%q)=%q, want %q", tc.in, got, tc.want)
		}
	}
}
