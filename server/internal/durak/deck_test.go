package durak

import (
	"encoding/json"
	"testing"
)

func TestSuitJSONRoundTrip(t *testing.T) {
	for _, s := range []Suit{Hearts, Diamonds, Clubs, Spades} {
		b, err := json.Marshal(s)
		if err != nil {
			t.Fatalf("marshal %v: %v", s, err)
		}
		want := `"` + s.String() + `"`
		if string(b) != want {
			t.Fatalf("suit %v: got %s want %s", s, b, want)
		}
		var back Suit
		if err := json.Unmarshal(b, &back); err != nil {
			t.Fatalf("unmarshal %s: %v", b, err)
		}
		if back != s {
			t.Fatalf("roundtrip %v -> %v", s, back)
		}
	}
}

func TestSuitJSONLegacyNumber(t *testing.T) {
	var s Suit
	if err := json.Unmarshal([]byte(`2`), &s); err != nil {
		t.Fatal(err)
	}
	if s != Clubs {
		t.Fatalf("got %v want Clubs", s)
	}
}

func TestCardJSONSuitLetter(t *testing.T) {
	c := Card{Rank: 11, Suit: Diamonds}
	b, err := json.Marshal(c)
	if err != nil {
		t.Fatal(err)
	}
	var m map[string]any
	if err := json.Unmarshal(b, &m); err != nil {
		t.Fatal(err)
	}
	if m["suit"] != "D" {
		t.Fatalf("suit field = %#v, want \"D\"", m["suit"])
	}
}
