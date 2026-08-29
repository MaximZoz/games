package api

import "testing"

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
