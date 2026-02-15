package main

import (
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
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
