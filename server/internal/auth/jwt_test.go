package auth

import (
	"testing"
	"time"

	"github.com/google/uuid"
)

var testSecret = []byte("test-secret-key")

func TestNewJWT_and_ParseJWT(t *testing.T) {
	userID := uuid.MustParse("550e8400-e29b-41d4-a716-446655440000")
	email := "user@test.com"
	expiresIn := 5 * time.Minute

	token, err := NewJWT(testSecret, userID, email, expiresIn)
	if err != nil {
		t.Fatalf("NewJWT: %v", err)
	}
	if token == "" {
		t.Fatal("token should not be empty")
	}

	claims, err := ParseJWT(testSecret, token)
	if err != nil {
		t.Fatalf("ParseJWT: %v", err)
	}
	if claims.UserID != userID.String() {
		t.Errorf("UserID = %q, want %q", claims.UserID, userID.String())
	}
	if claims.Email != email {
		t.Errorf("Email = %q, want %q", claims.Email, email)
	}
}

func TestParseJWT_invalid(t *testing.T) {
	tests := []struct {
		name string
		token string
	}{
		{"empty", ""},
		{"wrong secret", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMTIzIn0.xxx"},
		{"garbage", "not-a-jwt"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := ParseJWT(testSecret, tt.token)
			if err == nil {
				t.Error("expected error")
			}
		})
	}
}

func TestParseJWT_wrongSecret(t *testing.T) {
	userID := uuid.New()
	token, _ := NewJWT(testSecret, userID, "a@b.c", time.Minute)
	otherSecret := []byte("other-secret")
	_, err := ParseJWT(otherSecret, token)
	if err == nil {
		t.Error("ParseJWT with wrong secret should fail")
	}
}
