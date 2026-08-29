package api

import (
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
