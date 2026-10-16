package applinks

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestParseSHA256List(t *testing.T) {
	got := ParseSHA256List(" aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99 , AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99\nbad not-a-hash")
	if len(got) != 1 {
		t.Fatalf("len = %d, want 1 unique fingerprint, got %v", len(got), got)
	}
	want := "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99"
	if got[0] != want {
		t.Fatalf("fingerprint = %s", got[0])
	}
	if ParseSHA256List("") != nil && len(ParseSHA256List("")) != 0 {
		t.Fatalf("empty list = %v", ParseSHA256List(""))
	}
}

func TestAssetLinksAndAASA(t *testing.T) {
	sha := "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99"
	cfg := Config{
		AppleTeamID:    "AB12CD34EF",
		AppleBundleID:  "com.zozugames.app",
		AndroidPackage: "com.zozugames.app",
		AndroidSHA256:  []string{sha},
	}
	raw, ok := cfg.AssetLinksJSON()
	if !ok {
		t.Fatal("assetlinks not ready")
	}
	var links []map[string]any
	if err := json.Unmarshal(raw, &links); err != nil {
		t.Fatal(err)
	}
	if len(links) != 1 {
		t.Fatalf("links = %d", len(links))
	}
	target := links[0]["target"].(map[string]any)
	if target["package_name"] != "com.zozugames.app" {
		t.Fatalf("package = %v", target["package_name"])
	}

	aasa, ok := cfg.AppleAppSiteAssociationJSON()
	if !ok {
		t.Fatal("aasa not ready")
	}
	if !strings.Contains(string(aasa), `"appID":"AB12CD34EF.com.zozugames.app"`) {
		t.Fatalf("aasa = %s", aasa)
	}
	if !strings.Contains(string(aasa), "/games/*/lobby/*") {
		t.Fatalf("aasa paths = %s", aasa)
	}
	if !strings.Contains(string(aasa), `"apps":[]`) {
		t.Fatalf("apps must be an empty array: %s", aasa)
	}

	off := Config{}
	if _, ok := off.AssetLinksJSON(); ok {
		t.Fatal("empty config must not publish assetlinks")
	}
	if _, ok := off.AppleAppSiteAssociationJSON(); ok {
		t.Fatal("empty config must not publish AASA")
	}
	badTeam := cfg
	badTeam.AppleTeamID = "short"
	if _, ok := badTeam.AppleAppSiteAssociationJSON(); ok {
		t.Fatal("short team id must not publish AASA")
	}
}

func TestServeWellKnown(t *testing.T) {
	sha := "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99"
	cfg := Config{
		AppleTeamID:    "AB12CD34EF",
		AppleBundleID:  "com.zozugames.app",
		AndroidPackage: "com.zozugames.app",
		AndroidSHA256:  []string{sha},
	}
	for _, path := range []string{
		"/.well-known/assetlinks.json",
		"/.well-known/apple-app-site-association",
		"/apple-app-site-association",
	} {
		req := httptest.NewRequest(http.MethodGet, path, nil)
		rec := httptest.NewRecorder()
		if !Serve(rec, req, cfg) {
			t.Fatalf("%s: not handled", path)
		}
		if rec.Code != http.StatusOK {
			t.Fatalf("%s: status %d", path, rec.Code)
		}
		if got := rec.Header().Get("Content-Type"); got != "application/json" {
			t.Fatalf("%s: content-type %q", path, got)
		}
		if strings.Contains(rec.Body.String(), "<html") {
			t.Fatalf("%s: body looks like HTML", path)
		}
	}

	req := httptest.NewRequest(http.MethodGet, "/games/tictactoe/lobby/x", nil)
	rec := httptest.NewRecorder()
	if Serve(rec, req, cfg) {
		t.Fatal("lobby path must fall through to the SPA")
	}

	missing := httptest.NewRequest(http.MethodGet, "/.well-known/assetlinks.json", nil)
	missRec := httptest.NewRecorder()
	if !Serve(missRec, missing, Config{}) {
		t.Fatal("unconfigured assetlinks must still be handled")
	}
	if missRec.Code != http.StatusNotFound {
		t.Fatalf("unconfigured status %d", missRec.Code)
	}

	post := httptest.NewRequest(http.MethodPost, "/.well-known/assetlinks.json", nil)
	postRec := httptest.NewRecorder()
	if !Serve(postRec, post, cfg) || postRec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("POST status %d handled=%v", postRec.Code, true)
	}
}
