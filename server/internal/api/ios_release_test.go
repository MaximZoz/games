package api

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/alicebob/miniredis/v2"
	"github.com/redis/go-redis/v9"
)

func TestLoopbackRequest(t *testing.T) {
	if !LoopbackRequest("127.0.0.1:1234") {
		t.Fatal("ipv4 loopback")
	}
	if !LoopbackRequest("[::1]:1234") {
		t.Fatal("ipv6 loopback")
	}
	if LoopbackRequest("172.19.0.1:443") {
		t.Fatal("fly proxy is not loopback")
	}
	if LoopbackRequest("8.8.8.8:80") {
		t.Fatal("public ip")
	}
}

func TestParseIOSTestFlightRelease(t *testing.T) {
	rel, err := ParseIOSTestFlightRelease([]byte(`{"build_id":"abc1234","build_number":10042,"apple_id":"6822534284"}`))
	if err != nil {
		t.Fatal(err)
	}
	if rel.BuildID != "abc1234" || rel.BuildNumber != 10042 || rel.AppleID != "6822534284" {
		t.Fatalf("rel = %+v", rel)
	}
	if _, err := ParseIOSTestFlightRelease([]byte(`{"build_id":"","build_number":1}`)); err == nil {
		t.Fatal("empty build id")
	}
	if _, err := ParseIOSTestFlightRelease([]byte(`{"build_id":"abc","build_number":0}`)); err == nil {
		t.Fatal("zero build number")
	}
	if _, err := ParseIOSTestFlightRelease([]byte(`{"build_id":"ab c","build_number":1}`)); err == nil {
		t.Fatal("build id with space")
	}
}

func TestIOSTestFlightReleaseRoundTrip(t *testing.T) {
	mr := miniredis.RunT(t)
	rdb := redis.NewClient(&redis.Options{Addr: mr.Addr()})
	t.Cleanup(func() { _ = rdb.Close() })

	ctx := context.Background()
	if _, ok := LoadIOSTestFlightRelease(ctx, rdb); ok {
		t.Fatal("empty redis")
	}
	rel := IOSTestFlightRelease{BuildID: "abc1234", BuildNumber: 10042, AppleID: "6822534284"}
	if err := SaveIOSTestFlightRelease(ctx, rdb, rel); err != nil {
		t.Fatal(err)
	}
	got, ok := LoadIOSTestFlightRelease(ctx, rdb)
	if !ok || got != rel {
		t.Fatalf("got %+v ok=%v", got, ok)
	}

	var notified bool
	h := &IOSTestFlightReleaseHandler{Rdb: rdb, Notify: func() { notified = true }}
	req := httptest.NewRequest(http.MethodPost, "/api/internal/ios-testflight", strings.NewReader(`{"build_id":"def5678","build_number":10043,"apple_id":"1"}`))
	req.RemoteAddr = "127.0.0.1:9"
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("status %d body %s", rec.Code, rec.Body.String())
	}
	if !notified {
		t.Fatal("expected notify")
	}
	got, ok = LoadIOSTestFlightRelease(ctx, rdb)
	if !ok || got.BuildNumber != 10043 {
		t.Fatalf("stored %+v", got)
	}

	req = httptest.NewRequest(http.MethodPost, "/api/internal/ios-testflight", strings.NewReader(`{"build_id":"fff","build_number":9,"apple_id":"1"}`))
	req.RemoteAddr = "172.19.0.1:443"
	rec = httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if rec.Code != http.StatusForbidden {
		t.Fatalf("public post status %d", rec.Code)
	}
}
