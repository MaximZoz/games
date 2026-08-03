package translate

import "testing"

func TestNormalizeLang(t *testing.T) {
	cases := map[string]string{
		"RU":   "ru",
		"en-US": "en",
		"no":   "nb",
		"nn":   "nb",
		"iw":   "he",
	}
	for in, want := range cases {
		if got := NormalizeLang(in); got != want {
			t.Fatalf("NormalizeLang(%q)=%q want %q", in, got, want)
		}
	}
}

func TestShouldSkip(t *testing.T) {
	if !ShouldSkip("[animated_emoji:smile]") {
		t.Fatal("emoji token")
	}
	if !ShouldSkip("[coins_credit:11111111-1111-1111-1111-111111111111|10|x]") {
		t.Fatal("coins")
	}
	if !ShouldSkip("👍🎉") {
		t.Fatal("emoji only")
	}
	if ShouldSkip("Hello") {
		t.Fatal("plain text")
	}
}
