package api

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestVerifyEmail_MethodNotAllowed(t *testing.T) {
	h := authHandlerForValidation(t)
	req := httptest.NewRequest(http.MethodGet, "/api/auth/verify-email", nil)
	rec := httptest.NewRecorder()
	h.VerifyEmail(rec, req)
	if rec.Code != http.StatusMethodNotAllowed {
		t.Errorf("status = %d, want %d", rec.Code, http.StatusMethodNotAllowed)
	}
}

func TestVerifyEmail_EmptyFields(t *testing.T) {
	h := authHandlerForValidation(t)
	body := []byte(`{"email":"","code":""}`)
	req := httptest.NewRequest(http.MethodPost, "/api/auth/verify-email", bytes.NewReader(body))
	rec := httptest.NewRecorder()
	h.VerifyEmail(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Errorf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestResendVerification_EmptyEmail(t *testing.T) {
	h := authHandlerForValidation(t)
	body := []byte(`{"email":""}`)
	req := httptest.NewRequest(http.MethodPost, "/api/auth/resend-verification", bytes.NewReader(body))
	rec := httptest.NewRecorder()
	h.ResendVerification(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Errorf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestOAuthProviders_Empty(t *testing.T) {
	h := authHandlerForValidation(t)
	req := httptest.NewRequest(http.MethodGet, "/api/auth/oauth/providers", nil)
	rec := httptest.NewRecorder()
	h.OAuthProviders(rec, req)
	if rec.Code != http.StatusOK {
		t.Errorf("status = %d, want %d", rec.Code, http.StatusOK)
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`"providers"`)) {
		t.Errorf("body = %s, want providers", rec.Body.String())
	}
}

func TestGenerateEmailCode(t *testing.T) {
	code, err := generateEmailCode()
	if err != nil {
		t.Fatal(err)
	}
	if len(code) != 6 {
		t.Fatalf("code len = %d, want 6", len(code))
	}
	for _, c := range code {
		if c < '0' || c > '9' {
			t.Fatalf("non-digit in code: %q", code)
		}
	}
}
