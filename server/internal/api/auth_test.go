package api

import (
	"bytes"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

func authHandlerForValidation(t *testing.T) *AuthHandler {
	return &AuthHandler{
		Pool:      (*pgxpool.Pool)(nil),
		JWTSecret: []byte("test-secret"),
	}
}

func TestRegister_MethodNotAllowed(t *testing.T) {
	h := authHandlerForValidation(t)
	body := []byte(`{"email":"a@b.c","password":"123456"}`)
	req := httptest.NewRequest(http.MethodGet, "/api/auth/register", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	h.Register(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Errorf("status = %d, want %d", rec.Code, http.StatusMethodNotAllowed)
	}
}

func TestRegister_InvalidJSON(t *testing.T) {
	h := authHandlerForValidation(t)
	req := httptest.NewRequest(http.MethodPost, "/api/auth/register", bytes.NewReader([]byte("not json")))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	h.Register(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestRegister_EmptyEmail(t *testing.T) {
	h := authHandlerForValidation(t)
	body := []byte(`{"email":"","password":"123456"}`)
	req := httptest.NewRequest(http.MethodPost, "/api/auth/register", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	h.Register(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestRegister_ShortPassword(t *testing.T) {
	h := authHandlerForValidation(t)
	body := []byte(`{"email":"a@b.c","password":"12345"}`)
	req := httptest.NewRequest(http.MethodPost, "/api/auth/register", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	h.Register(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestLogin_MethodNotAllowed(t *testing.T) {
	h := authHandlerForValidation(t)
	body := []byte(`{"email":"a@b.c","password":"secret"}`)
	req := httptest.NewRequest(http.MethodGet, "/api/auth/login", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	h.Login(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Errorf("status = %d, want %d", rec.Code, http.StatusMethodNotAllowed)
	}
}

func TestLogin_InvalidJSON(t *testing.T) {
	h := authHandlerForValidation(t)
	req := httptest.NewRequest(http.MethodPost, "/api/auth/login", bytes.NewReader([]byte("{")))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	h.Login(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestLogin_EmptyCredentials(t *testing.T) {
	h := authHandlerForValidation(t)
	for _, body := range []string{`{"email":"","password":"x"}`, `{"email":"a@b.c","password":""}`} {
		req := httptest.NewRequest(http.MethodPost, "/api/auth/login", bytes.NewReader([]byte(body)))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		h.Login(rec, req)
		if rec.Code != http.StatusBadRequest {
			t.Errorf("body %q: status = %d, want %d", body, rec.Code, http.StatusBadRequest)
		}
	}
}

func TestRefresh_MethodNotAllowed(t *testing.T) {
	h := authHandlerForValidation(t)
	req := httptest.NewRequest(http.MethodGet, "/api/auth/refresh", nil)
	rec := httptest.NewRecorder()

	h.Refresh(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Errorf("status = %d, want %d", rec.Code, http.StatusMethodNotAllowed)
	}
}

func TestRefresh_InvalidJSON(t *testing.T) {
	h := authHandlerForValidation(t)
	req := httptest.NewRequest(http.MethodPost, "/api/auth/refresh", bytes.NewReader([]byte("{")))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	h.Refresh(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestRefresh_EmptyToken(t *testing.T) {
	h := authHandlerForValidation(t)
	req := httptest.NewRequest(http.MethodPost, "/api/auth/refresh", bytes.NewReader([]byte(`{"refresh_token":"  "}`)))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	h.Refresh(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestCreateUserConflictMessage_DisplayName(t *testing.T) {
	err := &pgconn.PgError{
		Code:           "23505",
		ConstraintName: "users_display_name_key",
	}
	msg, ok := createUserConflictMessage(err)
	if !ok || msg != "login already taken" {
		t.Fatalf("got (%q, %v), want (login already taken, true)", msg, ok)
	}
}

func TestCreateUserConflictMessage_Email(t *testing.T) {
	err := &pgconn.PgError{
		Code:           "23505",
		ConstraintName: "users_email_key",
	}
	msg, ok := createUserConflictMessage(err)
	if !ok || msg != "email already registered" {
		t.Fatalf("got (%q, %v), want (email already registered, true)", msg, ok)
	}
}

func TestCreateUserConflictMessage_FallbackText(t *testing.T) {
	err := errors.New(`ERROR: duplicate key value violates unique constraint "users_display_name_key"`)
	msg, ok := createUserConflictMessage(err)
	if !ok || msg != "login already taken" {
		t.Fatalf("got (%q, %v), want (login already taken, true)", msg, ok)
	}
}
