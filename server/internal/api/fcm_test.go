package api

import (
	"strings"
	"testing"
	"unicode/utf16"
)

func TestFcmDataFromPayload(t *testing.T) {
	data := fcmDataFromPayload(PushPayload{
		Title:  "Алиса",
		Body:   "Привет",
		URL:    "/chats/c1",
		Tag:    "chat_c1",
		Kind:   "chat",
		ChatID: "c1",
	})
	if data["url"] != "/chats/c1" || data["tag"] != "chat_c1" || data["chat_id"] != "c1" {
		t.Fatalf("deep-link fields: %#v", data)
	}
	if data["title"] != "Алиса" || data["body"] != "Привет" {
		t.Fatalf("title/body: %#v", data)
	}
	if data["kind"] != "chat" {
		t.Fatalf("kind: %#v", data)
	}
}

func TestFCMSecretStatus(t *testing.T) {
	const good = `{"type":"service_account","project_id":"zozu-games"}`
	if ok, reason := FCMSecretStatus(good); !ok || reason != "ok" {
		t.Fatalf("good: ok=%v reason=%s", ok, reason)
	}
	if ok, reason := FCMSecretStatus(""); ok || reason != "empty" {
		t.Fatalf("empty: ok=%v reason=%s", ok, reason)
	}
	if ok, reason := FCMSecretStatus("-"); ok || reason != "literal-dash (Windows stdin not read)" {
		t.Fatalf("dash: ok=%v reason=%s", ok, reason)
	}
	if ok, reason := FCMSecretStatus(`{"client":[]}`); ok || reason != "no-project_id" {
		t.Fatalf("nested: ok=%v reason=%s", ok, reason)
	}
	if ok, reason := FCMSecretStatus("not-json"); ok || !strings.Contains(reason, "invalid-json") {
		t.Fatalf("bad json: ok=%v reason=%s", ok, reason)
	}
	quoted := `"` + `{\"type\":\"service_account\",\"project_id\":\"zozu-games\"}` + `"`
	if got := parseFCMProjectID(quoted); got != "zozu-games" {
		t.Fatalf("quoted: %q", got)
	}
	bom := "\uFEFF" + good
	if got := parseFCMProjectID(bom); got != "zozu-games" {
		t.Fatalf("bom: %q", got)
	}

	u := utf16.Encode([]rune(good))
	le := []byte{0xFF, 0xFE}
	for _, r := range u {
		le = append(le, byte(r), byte(r>>8))
	}
	if got := parseFCMProjectID(string(le)); got != "zozu-games" {
		t.Fatalf("utf16: %q", got)
	}
}
