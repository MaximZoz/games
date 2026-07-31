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

	"github.com/jackc/pgx/v5"
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
}

func writeVerificationRequired(w http.ResponseWriter, status int, email, message string, mailSent bool) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(VerificationRequiredResponse{
		RequiresVerification: true,
		Email:                email,
		Message:              message,
		MailSent:             mailSent,
	})
}

func generateEmailCode() (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

// sendVerificationMail отправляет код. mailSent=false если провайдер не настроен (dev).
func (h *AuthHandler) sendVerificationMail(email, code string) (mailSent bool, err error) {
	if h.Mailer == nil || !h.Mailer.Enabled() {
		log.Printf("[auth] verification code for %s: %s (mail provider not configured)", email, code)
		return false, nil
	}
	if err := h.Mailer.SendVerificationCode(email, code); err != nil {
		log.Printf("[auth] send verification email to %s via %s failed: %v", email, h.Mailer.Provider(), err)
		return false, err
	}
	log.Printf("[auth] verification email queued to %s via %s", email, h.Mailer.Provider())
	return true, nil
}

func mailSendUserMessage(err error) string {
	if err == nil {
		return "failed to send verification email"
	}
	msg := strings.ToLower(err.Error())
	if strings.Contains(msg, "testing mode") ||
		strings.Contains(msg, "testing emails") ||
		strings.Contains(msg, "verify a domain") {
		return "cannot deliver to this email yet: verify your domain in Resend (MAIL_FROM must use that domain)"
	}
	return "failed to send verification email"
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

	// Уже полноценный пользователь — просто выдаём сессию.
	if u, err := store.GetUserByEmail(r.Context(), h.Pool, email); err == nil && u.EmailVerified() {
		accessToken, refreshToken, expiresIn, err := h.issueSessionTokens(r.Context(), u)
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		writeTokenResponse(w, accessToken, refreshToken, expiresIn, u)
		return
	}

	pending, err := store.GetPendingRegistrationByEmail(r.Context(), h.Pool, email)
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid verification code")
		return
	}
	if pending.Attempts >= store.EmailCodeMaxAttempts {
		WriteErr(w, r, http.StatusTooManyRequests, "too many verification attempts")
		return
	}
	if time.Now().After(pending.ExpiresAt) {
		WriteErr(w, r, http.StatusBadRequest, "verification code expired")
		return
	}
	if store.HashEmailCode(code) != pending.CodeHash {
		_ = store.IncrementPendingRegistrationAttempts(r.Context(), h.Pool, pending.ID)
		WriteErr(w, r, http.StatusBadRequest, "invalid verification code")
		return
	}

	displayName := ""
	if pending.DisplayName != nil {
		displayName = *pending.DisplayName
	}
	if displayName != "" {
		nameTaken, err := store.DisplayNameTakenByUser(r.Context(), h.Pool, displayName)
		if err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
		if nameTaken {
			WriteErr(w, r, http.StatusConflict, "login already taken")
			return
		}
	}

	u, err := store.CreateUser(
		r.Context(),
		h.Pool,
		pending.Email,
		pending.PasswordHash,
		displayName,
		pending.ReferredBy,
	)
	if err != nil {
		if msg, ok := createUserConflictMessage(err); ok {
			WriteErr(w, r, http.StatusConflict, msg)
			return
		}
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	_ = store.DeletePendingRegistration(r.Context(), h.Pool, email)

	accessToken, refreshToken, expiresIn, err := h.issueSessionTokens(r.Context(), u)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	writeTokenResponse(w, accessToken, refreshToken, expiresIn, u)
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

	// Уже зарегистрирован и подтверждён.
	if u, err := store.GetUserByEmail(r.Context(), h.Pool, email); err == nil && u.EmailVerified() {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(map[string]any{
			"ok":      true,
			"message": "email already verified",
		})
		return
	}

	ok, err := store.CanResendPendingRegistration(r.Context(), h.Pool, email)
	if err == pgx.ErrNoRows {
		// Не раскрываем наличие email.
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(map[string]any{
			"ok":      true,
			"message": "if the account exists, a new code was sent",
		})
		return
	}
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if !ok {
		WriteErr(w, r, http.StatusTooManyRequests, "please wait before requesting a new code")
		return
	}

	code, err := generateEmailCode()
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if _, err := store.RefreshPendingRegistrationCode(r.Context(), h.Pool, email, code); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	mailSent, err := h.sendVerificationMail(email, code)
	if err != nil {
		WriteErr(w, r, http.StatusBadGateway, mailSendUserMessage(err))
		return
	}

	_ = code
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"ok":        true,
		"message":   "verification code sent",
		"mail_sent": mailSent,
	})
}
