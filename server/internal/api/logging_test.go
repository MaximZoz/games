package api

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"multigames/server/internal/applog"
)

func TestRequestLogger_WritesBackendEvent(t *testing.T) {
	tmpDir := t.TempDir()
	logPath := filepath.Join(tmpDir, "app.jsonl")
	writer, err := applog.NewFileWriter(logPath)
	if err != nil {
		t.Fatalf("NewFileWriter: %v", err)
	}
	defer writer.Close()

	next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusCreated)
	})
	handler := RequestLogger(nil, writer, next)

	req := httptest.NewRequest(http.MethodGet, "/api/test?x=1", nil)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusCreated)
	}

	raw, err := os.ReadFile(logPath)
	if err != nil {
		t.Fatalf("ReadFile: %v", err)
	}
	lines := strings.Split(strings.TrimSpace(string(raw)), "\n")
	if len(lines) != 1 {
		t.Fatalf("log lines = %d, want 1", len(lines))
	}

	var event applog.Event
	if err := json.Unmarshal([]byte(lines[0]), &event); err != nil {
		t.Fatalf("Unmarshal: %v", err)
	}
	if event.Source != "backend" {
		t.Errorf("source = %q, want backend", event.Source)
	}
	if event.HTTPMethod != http.MethodGet {
		t.Errorf("http_method = %q, want %q", event.HTTPMethod, http.MethodGet)
	}
	if event.Path != "/api/test" {
		t.Errorf("path = %q, want /api/test", event.Path)
	}
	if event.StatusCode == nil || *event.StatusCode != http.StatusCreated {
		t.Errorf("status_code = %v, want %d", event.StatusCode, http.StatusCreated)
	}
}

func TestFrontendLogHandler_IngestWritesFrontendEvent(t *testing.T) {
	tmpDir := t.TempDir()
	logPath := filepath.Join(tmpDir, "app.jsonl")
	writer, err := applog.NewFileWriter(logPath)
	if err != nil {
		t.Fatalf("NewFileWriter: %v", err)
	}
	defer writer.Close()

	h := &FrontendLogHandler{Writer: writer}
	reqBody := []byte(`{
		"method_name":"AuthRepository.login",
		"http_method":"POST",
		"path":"/api/auth/login",
		"status_code":200,
		"duration_ms":42
	}`)

	req := httptest.NewRequest(http.MethodPost, "/api/logs/frontend", bytes.NewReader(reqBody))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	h.Ingest(rec, req)

	if rec.Code != http.StatusAccepted {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusAccepted)
	}

	raw, err := os.ReadFile(logPath)
	if err != nil {
		t.Fatalf("ReadFile: %v", err)
	}
	lines := strings.Split(strings.TrimSpace(string(raw)), "\n")
	if len(lines) != 1 {
		t.Fatalf("log lines = %d, want 1", len(lines))
	}

	var event applog.Event
	if err := json.Unmarshal([]byte(lines[0]), &event); err != nil {
		t.Fatalf("Unmarshal: %v", err)
	}
	if event.Source != "frontend" {
		t.Errorf("source = %q, want frontend", event.Source)
	}
	if event.MethodName != "AuthRepository.login" {
		t.Errorf("method_name = %q, want AuthRepository.login", event.MethodName)
	}
	if event.HTTPMethod != http.MethodPost {
		t.Errorf("http_method = %q, want %q", event.HTTPMethod, http.MethodPost)
	}
	if event.Path != "/api/auth/login" {
		t.Errorf("path = %q, want /api/auth/login", event.Path)
	}
}

func TestFrontendLogHandler_IngestDisabledWriter_NoOp(t *testing.T) {
	h := &FrontendLogHandler{Writer: nil}
	reqBody := []byte(`{"method_name":"noop"}`)

	req := httptest.NewRequest(http.MethodPost, "/api/logs/frontend", bytes.NewReader(reqBody))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	h.Ingest(rec, req)

	if rec.Code != http.StatusAccepted {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusAccepted)
	}
}
