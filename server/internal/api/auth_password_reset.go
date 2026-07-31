package api

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"
	"time"

	"multigames/server/internal/auth"
	"multigames/server/internal/store"

	"github.com/jackc/pgx/v5"
)

type ForgotPasswordRequest struct {
	Email string `json:"email"`
}

type SelfResetPasswordRequest struct {
	Email       string `json:"email"`
	Code        string `json:"code"`
	NewPassword string `json:"new_password"`
}

func looksLikeEmail(s string) bool {
	s = strings.TrimSpace(s)
	at := strings.IndexByte(s, '@')
	if at <= 0 || at == len(s)-1 {
		return false
	}
	return strings.Contains(s[at+1:], ".")
}

func (h *AuthHandler) sendPasswordResetMail(email, code string) (mailSent bool, err error) {
	if h.Mailer == nil || !h.Mailer.Enabled() {
		log.Printf("[auth] password reset code for %s: %s (mail provider not configured)", email, code)
		return false, nil
	}
	if err := h.Mailer.SendPasswordResetCode(email, code); err != nil {
		log.Printf("[auth] send password reset email to %s via %s failed: %v", email, h.Mailer.Provider(), err)
		return false, err
	}
	log.Printf("[auth] password reset email queued to %s via %s", email, h.Mailer.Provider())
	return true, nil
}

// ForgotPassword — запрос кода сброса.
// Email: неизвестный адрес — мягкий OK (anti-enumeration).
// Логин (не email): неизвестный — 404; известный — код на привязанный email.
func (h *AuthHandler) ForgotPassword(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	var req ForgotPasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	login := strings.TrimSpace(req.Email)
	if login == "" {
		WriteErr(w, r, http.StatusBadRequest, "email required")
		return
	}
	isEmail := looksLikeEmail(login)

	writeOK := func(resolvedEmail string, mailSent bool) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(map[string]any{
			"ok":        true,
			"email":     resolvedEmail,
			"message":   "if the account exists, a reset code was sent",
			"mail_sent": mailSent,
		})
	}

	u, err := store.GetUserByEmailOrDisplayName(r.Context(), h.Pool, login)
	if err == pgx.ErrNoRows {
		if !isEmail {
			WriteErr(w, r, http.StatusNotFound, "user not found")
			return
		}
		// Email-формат, аккаунта нет — не раскрываем.
		writeOK(strings.ToLower(login), false)
		return
	}
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	resolvedEmail := strings.TrimSpace(strings.ToLower(u.Email))
	if resolvedEmail == "" {
		if !isEmail {
			WriteErr(w, r, http.StatusNotFound, "user not found")
			return
		}
		writeOK(strings.ToLower(login), false)
		return
	}

	ok, err := store.CanResendPasswordReset(r.Context(), h.Pool, resolvedEmail)
	if err != nil && err != pgx.ErrNoRows {
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
	if err := store.UpsertPasswordResetCode(r.Context(), h.Pool, u.ID, code); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	mailSent, err := h.sendPasswordResetMail(resolvedEmail, code)
	if err != nil {
		_ = store.DeletePasswordResetCode(r.Context(), h.Pool, u.ID)
		WriteErr(w, r, http.StatusBadGateway, mailSendUserMessage(err))
		return
	}
	writeOK(resolvedEmail, mailSent)
}

// ResetPassword — проверка кода и установка нового пароля; выдаёт сессию.
func (h *AuthHandler) ResetPassword(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	var req SelfResetPasswordRequest
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
	if len(req.NewPassword) < 6 {
		WriteErr(w, r, http.StatusBadRequest, "password at least 6 characters")
		return
	}

	reset, err := store.GetPasswordResetCodeByEmail(r.Context(), h.Pool, email)
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid reset code")
		return
	}
	if reset.Attempts >= store.EmailCodeMaxAttempts {
		WriteErr(w, r, http.StatusTooManyRequests, "too many verification attempts")
		return
	}
	if time.Now().After(reset.ExpiresAt) {
		WriteErr(w, r, http.StatusBadRequest, "reset code expired")
		return
	}
	if store.HashEmailCode(code) != reset.CodeHash {
		_ = store.IncrementPasswordResetAttempts(r.Context(), h.Pool, reset.ID)
		WriteErr(w, r, http.StatusBadRequest, "invalid reset code")
		return
	}

	hash, err := auth.HashPassword(req.NewPassword)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if err := store.SetUserPassword(r.Context(), h.Pool, reset.UserID, hash); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	_ = store.DeletePasswordResetCode(r.Context(), h.Pool, reset.UserID)

	u, err := store.GetUserByID(r.Context(), h.Pool, reset.UserID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if !u.EmailVerified() {
		// Сброс с почты = подтверждение владения email.
		_ = store.MarkEmailVerified(r.Context(), h.Pool, u.ID)
		u, _ = store.GetUserByID(r.Context(), h.Pool, u.ID)
	}

	accessToken, refreshToken, expiresIn, err := h.issueSessionTokens(r.Context(), u)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	writeTokenResponse(w, accessToken, refreshToken, expiresIn, u)
}
