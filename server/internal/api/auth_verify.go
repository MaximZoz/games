package api

import (
	"crypto/rand"
	"encoding/json"
	"fmt"
	"log"
	"math/big"
	"net/http"
	"strings"
	"time"

	"multigames/server/internal/store"
)

type VerifyEmailRequest struct {
	Email string `json:"email"`
	Code  string `json:"code"`
}

type ResendVerificationRequest struct {
	Email string `json:"email"`
}

type VerificationRequiredResponse struct {
	RequiresVerification bool   `json:"requires_verification"`
	Email                string `json:"email"`
	Message              string `json:"message,omitempty"`
}

func writeVerificationRequired(w http.ResponseWriter, status int, email, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(VerificationRequiredResponse{
		RequiresVerification: true,
		Email:                email,
		Message:              message,
	})
}

func generateEmailCode() (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

func (h *AuthHandler) sendCodeForUser(r *http.Request, u *store.User) error {
	code, err := generateEmailCode()
	if err != nil {
		return err
	}
	if err := store.CreateEmailVerificationCode(r.Context(), h.Pool, u.ID, code); err != nil {
		return err
	}
	if h.Mailer == nil {
		log.Printf("[auth] verification code for %s: %s (mailer nil)", u.Email, code)
		return nil
	}
	if err := h.Mailer.SendVerificationCode(u.Email, code); err != nil {
		log.Printf("[auth] send verification email to %s failed: %v", u.Email, err)
		if h.Mailer.Enabled() {
			return err
		}
		log.Printf("[auth] verification code for %s: %s", u.Email, code)
	}
	return nil
}

func (h *AuthHandler) VerifyEmail(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	var req VerifyEmailRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	email := strings.TrimSpace(strings.ToLower(req.Email))
	code := strings.TrimSpace(req.Code)
	if email == "" || code == "" {
		WriteErr(w, r, http.StatusBadRequest, "email and code required")
		return
	}

	u, err := store.GetUserByEmail(r.Context(), h.Pool, email)
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid verification code")
		return
	}
	if u.EmailVerified() {
		accessToken, refreshToken, expiresIn, err := h.issueSessionTokens(r.Context(), u)
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		writeTokenResponse(w, accessToken, refreshToken, expiresIn, u)
		return
	}

	rec, err := store.GetLatestEmailVerificationCode(r.Context(), h.Pool, u.ID)
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid verification code")
		return
	}
	if rec.Attempts >= store.EmailCodeMaxAttempts {
		WriteErr(w, r, http.StatusTooManyRequests, "too many verification attempts")
		return
	}
	if time.Now().After(rec.ExpiresAt) {
		WriteErr(w, r, http.StatusBadRequest, "verification code expired")
		return
	}
	if store.HashEmailCode(code) != rec.CodeHash {
		_ = store.IncrementEmailCodeAttempts(r.Context(), h.Pool, rec.ID)
		WriteErr(w, r, http.StatusBadRequest, "invalid verification code")
		return
	}

	if err := store.MarkEmailVerified(r.Context(), h.Pool, u.ID); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	_ = store.DeleteEmailVerificationCodes(r.Context(), h.Pool, u.ID)

	fresh, err := store.GetUserByID(r.Context(), h.Pool, u.ID)
	if err != nil || fresh == nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	accessToken, refreshToken, expiresIn, err := h.issueSessionTokens(r.Context(), fresh)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	writeTokenResponse(w, accessToken, refreshToken, expiresIn, fresh)
}

func (h *AuthHandler) ResendVerification(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	var req ResendVerificationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	email := strings.TrimSpace(strings.ToLower(req.Email))
	if email == "" {
		WriteErr(w, r, http.StatusBadRequest, "email required")
		return
	}

	u, err := store.GetUserByEmail(r.Context(), h.Pool, email)
	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(map[string]any{
			"ok":      true,
			"message": "if the account exists, a new code was sent",
		})
		return
	}
	if u.EmailVerified() {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(map[string]any{
			"ok":      true,
			"message": "email already verified",
		})
		return
	}

	ok, err := store.CanResendEmailCode(r.Context(), h.Pool, u.ID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if !ok {
		WriteErr(w, r, http.StatusTooManyRequests, "please wait before requesting a new code")
		return
	}

	if err := h.sendCodeForUser(r, u); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "failed to send verification email")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"ok":      true,
		"message": "verification code sent",
	})
}
