package auth

import (
	"testing"
)

func TestHashPassword(t *testing.T) {
	hash, err := HashPassword("secret123")
	if err != nil {
		t.Fatalf("HashPassword: %v", err)
	}
	if hash == "" || hash == "secret123" {
		t.Errorf("hash should be non-empty and not equal to plain password")
	}
	// разный соль — разные хеши
	hash2, _ := HashPassword("secret123")
	if hash == hash2 {
		t.Errorf("two hashes of same password should differ (different salt)")
	}
}

func TestCheckPassword(t *testing.T) {
	password := "mypassword"
	hash, err := HashPassword(password)
	if err != nil {
		t.Fatal(err)
	}
	if !CheckPassword(password, hash) {
		t.Error("CheckPassword: valid password should match")
	}
	if CheckPassword("wrong", hash) {
		t.Error("CheckPassword: wrong password should not match")
	}
	if CheckPassword(password, "") {
		t.Error("CheckPassword: empty hash should not match")
	}
}
