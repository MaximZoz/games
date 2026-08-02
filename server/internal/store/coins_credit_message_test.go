package store

import (
	"testing"

	"github.com/google/uuid"
)

func TestEncodeParseCoinsCreditMessage(t *testing.T) {
	id := uuid.MustParse("11111111-1111-1111-1111-111111111111")
	body := EncodeCoinsCreditMessage(id, 230, "Компенсация|баг]")
	want := "[coins_credit:11111111-1111-1111-1111-111111111111|230|Компенсация/баг]"
	if body != want {
		t.Fatalf("encode: got %q want %q", body, want)
	}
	p, ok := ParseCoinsCreditMessage(body)
	if !ok {
		t.Fatal("parse failed")
	}
	if p.GrantID != id || p.AmountBronze != 230 || p.Reason != "Компенсация/баг" || p.Claimed {
		t.Fatalf("unexpected payload: %+v", p)
	}
	claimed := EncodeCoinsCreditMessageClaimed(id, 230, "Компенсация/баг")
	p2, ok := ParseCoinsCreditMessage(claimed)
	if !ok || !p2.Claimed {
		t.Fatalf("claimed parse: ok=%v %+v", ok, p2)
	}
}

func TestIsCoinsCreditMessage(t *testing.T) {
	if !IsCoinsCreditMessage("[coins_credit:11111111-1111-1111-1111-111111111111|10|hi]") {
		t.Fatal("expected true")
	}
	if IsCoinsCreditMessage("hello") {
		t.Fatal("expected false")
	}
}
