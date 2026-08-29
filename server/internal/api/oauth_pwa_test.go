package api

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestOAuthDonePageAddsPwaQuery(t *testing.T) {
	h := &AuthHandler{
		OAuth: &OAuthConfig{FrontendURL: "https://zozugames.com"},
	}
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	h.oauthDonePage(rec, req, "abc123", "", true)
	if rec.Code != http.StatusFound {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusFound)
	}
	loc := rec.Header().Get("Location")
	if !strings.Contains(loc, "/oauth_done.html") {
		t.Fatalf("location %q missing oauth_done.html", loc)
	}
	if !strings.Contains(loc, "pwa=1") {
		t.Fatalf("location %q missing pwa=1", loc)
	}
	if !strings.Contains(loc, "state=abc123") {
		t.Fatalf("location %q missing state", loc)
	}
}

func TestOAuthDonePageOmitsPwaForBrowser(t *testing.T) {
	h := &AuthHandler{
		OAuth: &OAuthConfig{FrontendURL: "https://zozugames.com"},
	}
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	h.oauthDonePage(rec, req, "abc123", "", false)
	loc := rec.Header().Get("Location")
	if strings.Contains(loc, "pwa=1") {
		t.Fatalf("browser flow should not set pwa=1: %q", loc)
	}
}

func TestPutStateFromPWA(t *testing.T) {
	c := &OAuthConfig{}
	state, err := c.putState("google", "/games", "", true)
	if err != nil {
		t.Fatal(err)
	}
	if !c.peekFromPWA(state) {
		t.Fatal("expected FromPWA")
	}
	st, ok := c.takeState(state)
	if !ok || !st.FromPWA {
		t.Fatalf("takeState FromPWA = %v ok=%v", st.FromPWA, ok)
	}
}
