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
	MailSent             bool   `json:"mail_sent"`
	// DevCode возвращается только если почтовый провайдер не настроен (log mode).
	DevCode string `json:"dev_code,omitempty"`
}

func writeVerificationRequired(w http.ResponseWriter, status int, email, message string, mailSent bool, devCode string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(VerificationRequiredResponse{
		RequiresVerification: true,
		Email:                email,
		Message:              message,
		MailSent:             mailSent,
		DevCode:              devCode,
	})
}

func generateEmailCode() (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

// sendCodeForUser возвращает код и флаг реальной отправки письма.
func (h *AuthHandler) sendCodeForUser(r *http.Request, u *store.User) (code string, mailSent bool, err error) {
	code, err = generateEmailCode()
	if err != nil {
		return "", false, err
	}
	if err := store.CreateEmailVerificationCode(r.Context(), h.Pool, u.ID, code); err != nil {
		return "", false, err
	}
	if h.Mailer == nil || !h.Mailer.Enabled() {
		log.Printf("[auth] verification code for %s: %s (mail provider not configured)", u.Email, code)
		return code, false, nil
	}
	if err := h.Mailer.SendVerificationCode(u.Email, code); err != nil {
		log.Printf("[auth] send verification email to %s via %s failed: %v", u.Email, h.Mailer.Provider(), err)
		return "", false, err
	}
	return code, true, nil
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

	code, mailSent, err := h.sendCodeForUser(r, u)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "failed to send verification email")
		return
	}

	resp := map[string]any{
		"ok":        true,
		"message":   "verification code sent",
		"mail_sent": mailSent,
	}
	if !mailSent {
		resp["dev_code"] = code
		resp["message"] = "mail provider not configured — use dev_code"
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(resp)
}
