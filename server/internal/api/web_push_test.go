package api

import (
	"encoding/json"
	"net/http"
	"testing"
)

func TestParseFCMProjectID(t *testing.T) {
	if got := parseFCMProjectID(`{"project_id":"zozu-prod"}`); got != "zozu-prod" {
		t.Fatalf("project_id=%q", got)
	}
	if got := parseFCMProjectID(`not-json`); got != "" {
		t.Fatalf("invalid json should be empty, got %q", got)
	}
}

func TestShouldDropFCMToken(t *testing.T) {
	if !shouldDropFCMToken(http.StatusNotFound, nil) {
		t.Fatal("404 should drop")
	}
	if shouldDropFCMToken(http.StatusInternalServerError, []byte(`{}`)) {
		t.Fatal("500 should keep")
	}
	body := []byte(`{"error":{"status":"NOT_FOUND","details":[{"errorCode":"UNREGISTERED"}]}}`)
	if !shouldDropFCMToken(http.StatusBadRequest, body) {
		t.Fatal("UNREGISTERED should drop")
	}
}

func TestBuildFCMMessageReachesIOS(t *testing.T) {
	raw, err := json.Marshal(buildFCMMessage("tok", PushPayload{
		Title: "Алёна",
		Body:  "Пойдём в домино",
		URL:   "/games/domino/lobby/1",
		Tag:   "lobby_1",
	}))
	if err != nil {
		t.Fatal(err)
	}
	var msg map[string]any
	if err := json.Unmarshal(raw, &msg); err != nil {
		t.Fatal(err)
	}
	apns, _ := msg["apns"].(map[string]any)
	if apns == nil {
		t.Fatal("нет apns")
	}
	headers, _ := apns["headers"].(map[string]any)
	if headers["apns-priority"] != "10" {
		t.Fatalf("priority=%v", headers["apns-priority"])
	}
	payload, _ := apns["payload"].(map[string]any)
	aps, _ := payload["aps"].(map[string]any)
	if aps["sound"] != "default" {
		t.Fatalf("sound=%v", aps["sound"])
	}
	if aps["thread-id"] != "lobby_1" {
		t.Fatalf("thread=%v", aps["thread-id"])
	}
	alert, _ := aps["alert"].(map[string]any)
	if alert["title"] != "Алёна" || alert["body"] != "Пойдём в домино" {
		t.Fatalf("alert=%v", alert)
	}
	android, _ := msg["android"].(map[string]any)
	note, _ := android["notification"].(map[string]any)
	if note["channel_id"] != "zozu_events" {
		t.Fatalf("android channel=%v", note["channel_id"])
	}
}

func TestNormalizeDevicePlatform(t *testing.T) {
	if normalizeDevicePlatform("") != "android" {
		t.Fatal("empty defaults to android")
	}
	if normalizeDevicePlatform("iOS") != "ios" {
		t.Fatal("ios")
	}
	if normalizeDevicePlatform("web") != "" {
		t.Fatal("unknown rejected")
	}
}

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
