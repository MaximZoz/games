package main

import (
	"bytes"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
	"testing/fstest"
)

func TestHandleStart_GET(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/api/start", nil)
	rec := httptest.NewRecorder()

	handleStart(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("status = %d, want %d", rec.Code, http.StatusOK)
	}
	if got := rec.Header().Get("Content-Type"); got != "text/plain; charset=utf-8" {
		t.Errorf("Content-Type = %q, want text/plain; charset=utf-8", got)
	}
	if got := rec.Header().Get("Access-Control-Allow-Origin"); got != "*" {
		t.Errorf("CORS = %q, want *", got)
	}
	body, _ := io.ReadAll(rec.Body)
	if string(body) != serverMessage {
		t.Errorf("body = %q, want %q", string(body), serverMessage)
	}
}

func TestHandleStart_OPTIONS(t *testing.T) {
	req := httptest.NewRequest(http.MethodOptions, "/api/start", nil)
	rec := httptest.NewRecorder()

	handleStart(rec, req)

	if rec.Code != http.StatusNoContent {
		t.Errorf("status = %d, want %d", rec.Code, http.StatusNoContent)
	}
}

func TestHandleStart_MethodNotAllowed(t *testing.T) {
	for _, method := range []string{http.MethodPost, http.MethodPut, http.MethodDelete} {
		req := httptest.NewRequest(method, "/api/start", nil)
		rec := httptest.NewRecorder()

		handleStart(rec, req)

		if rec.Code != http.StatusMethodNotAllowed {
			t.Errorf("%s: status = %d, want %d", method, rec.Code, http.StatusMethodNotAllowed)
		}
	}
}

func TestSpaHandler_FaviconAndIconsNoCache(t *testing.T) {
	handler := spaHandler(webFS)

	for _, path := range []string{
		"/favicon.png",
		"/favicon.png?v=3",
		"/favicon.ico",
		"/icons/Icon-192.png",
		"/icons/Icon-512.png",
		"/icons/Icon-maskable-192.png",
		"/icons/Icon-maskable-512.png",
	} {
		req := httptest.NewRequest(http.MethodGet, path, nil)
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("%s: status = %d, want 200", path, rec.Code)
		}
		if got := rec.Header().Get("Cache-Control"); got != "no-cache" {
			t.Errorf("%s: Cache-Control = %q, want no-cache", path, got)
		}
		if rec.Body.Len() == 0 {
			t.Errorf("%s: empty body", path)
		}
	}
}

func TestSpaHandler_FaviconIcoFallbackToFaviconPng(t *testing.T) {
	pngBytes := []byte{0x89, 'P', 'N', 'G', '\r', '\n', 0x1a, '\n'}
	fakeFS := fstest.MapFS{
		"web/index.html":  {Data: []byte("<html></html>")},
		"web/favicon.png": {Data: pngBytes},
	}
	handler := spaHandler(fakeFS)

	req := httptest.NewRequest(http.MethodGet, "/favicon.ico", nil)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200", rec.Code)
	}
	if got := rec.Header().Get("Content-Type"); got != "image/png" {
		t.Errorf("Content-Type = %q, want image/png", got)
	}
	if got := rec.Header().Get("Cache-Control"); got != "no-cache" {
		t.Errorf("Cache-Control = %q, want no-cache", got)
	}
	if !bytes.Equal(rec.Body.Bytes(), pngBytes) {
		t.Errorf("body mismatch for fallback favicon.ico")
	}
}

