package api

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestForgotPassword_MethodNotAllowed(t *testing.T) {
	h := &AuthHandler{}
	req := httptest.NewRequest(http.MethodGet, "/api/auth/forgot-password", nil)
	rr := httptest.NewRecorder()
	h.ForgotPassword(rr, req)
	if rr.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d", rr.Code)
	}
}

func TestForgotPassword_EmptyEmail(t *testing.T) {
	h := &AuthHandler{}
	body := []byte(`{"email":""}`)
	req := httptest.NewRequest(http.MethodPost, "/api/auth/forgot-password", bytes.NewReader(body))
	rr := httptest.NewRecorder()
	h.ForgotPassword(rr, req)
	if rr.Code != http.StatusBadRequest {
		t.Fatalf("status = %d body=%s", rr.Code, rr.Body.String())
	}
}

func TestResetPassword_MethodNotAllowed(t *testing.T) {
	h := &AuthHandler{}
	req := httptest.NewRequest(http.MethodGet, "/api/auth/reset-password", nil)
	rr := httptest.NewRecorder()
	h.ResetPassword(rr, req)
	if rr.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d", rr.Code)
	}
}

func TestResetPassword_ShortPassword(t *testing.T) {
	h := &AuthHandler{}
	body := []byte(`{"email":"a@b.c","code":"123456","new_password":"123"}`)
	req := httptest.NewRequest(http.MethodPost, "/api/auth/reset-password", bytes.NewReader(body))
	rr := httptest.NewRecorder()
	h.ResetPassword(rr, req)
	if rr.Code != http.StatusBadRequest {
		t.Fatalf("status = %d body=%s", rr.Code, rr.Body.String())
	}
}

func TestResetPassword_MissingFields(t *testing.T) {
	h := &AuthHandler{}
	body := []byte(`{"email":"a@b.c","code":"","new_password":"secret12"}`)
	req := httptest.NewRequest(http.MethodPost, "/api/auth/reset-password", bytes.NewReader(body))
	rr := httptest.NewRecorder()
	h.ResetPassword(rr, req)
	if rr.Code != http.StatusBadRequest {
		t.Fatalf("status = %d", rr.Code)
	}
}
