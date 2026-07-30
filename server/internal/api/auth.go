package api

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"

	"multigames/server/internal/auth"
	"multigames/server/internal/mailer"
	"multigames/server/internal/store"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	accessTokenExpire  = 15 * time.Minute
	refreshTokenExpire = 7 * 24 * time.Hour
)

type AuthHandler struct {
	Pool      *pgxpool.Pool
	JWTSecret []byte
	Push      *WebPushSender
	Mailer    *mailer.Mailer
	OAuth     *OAuthConfig
}

type RegisterRequest struct {
	Email       string `json:"email"`
	Password    string `json:"password"`
	DisplayName string `json:"display_name"`
	Ref         string `json:"ref,omitempty"` // user id пригласившего
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

type TokenResponse struct {
	AccessToken  string       `json:"access_token"`
	RefreshToken string       `json:"refresh_token,omitempty"`
	ExpiresIn    int          `json:"expires_in"`
	User         UserResponse `json:"user"`
}

type UserResponse struct {
	ID            string  `json:"id"`
	Email         string  `json:"email"`
	DisplayName   *string `json:"display_name,omitempty"`
	IsAdmin       bool    `json:"is_admin,omitempty"`
	Age           *int    `json:"age,omitempty"`
	Gender        *string `json:"gender,omitempty"`
	About         *string `json:"about,omitempty"`
	AvatarKind    string  `json:"avatar_kind,omitempty"`
	AvatarValue   *string `json:"avatar_value,omitempty"`
	BalanceBronze int     `json:"balance_bronze"`
	EmailVerified bool    `json:"email_verified"`
}

func userToResponse(u *store.User) UserResponse {
	return UserResponse{
		ID:            u.ID.String(),
		Email:         u.Email,
		DisplayName:   u.DisplayName,
		IsAdmin:       u.IsAdmin,
		Age:           u.Age,
		Gender:        u.Gender,
		About:         u.About,
		AvatarKind:    u.AvatarKind,
		AvatarValue:   u.AvatarValue,
		BalanceBronze: u.BalanceBronze,
		EmailVerified: u.EmailVerified(),
	}
}

// createUserConflictMessage различает unique по email и по логину (display_name).
// Раньше любой duplicate отдавался как "email already registered" (#145).
func createUserConflictMessage(err error) (string, bool) {
	if err == nil {
		return "", false
	}

	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == "23505" {
		switch pgErr.ConstraintName {
		case "users_display_name_key":
			return "login already taken", true
		case "users_email_key":
			return "email already registered", true
		}
	}

	msg := err.Error()
	if strings.Contains(msg, "users_display_name_key") {
		return "login already taken", true
	}
	if strings.Contains(msg, "users_email_key") {
		return "email already registered", true
	}
	if strings.Contains(msg, "duplicate key") || strings.Contains(msg, "unique") {
		// Неясный unique — безопаснее не врать про email.
		return "login or email already registered", true
	}
	return "", false
}

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	req.Email = strings.TrimSpace(strings.ToLower(req.Email))
	if req.Email == "" || len(req.Password) < 6 {
		WriteErr(w, r, http.StatusBadRequest, "email required, password at least 6 characters")
		return
	}

	displayName := strings.TrimSpace(req.DisplayName)

	taken, err := store.EmailTakenByUser(r.Context(), h.Pool, req.Email)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	if taken {
		WriteErr(w, r, http.StatusConflict, "email already registered")
		return
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

	hash, err := auth.HashPassword(req.Password)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	var referredBy *uuid.UUID
	if refRaw := strings.TrimSpace(req.Ref); refRaw != "" {
		if id, parseErr := uuid.Parse(refRaw); parseErr == nil {
			referredBy = &id
		}
	}

	code, err := generateEmailCode()
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	// Пользователь в users НЕ создаётся — только заявка до подтверждения кода.
	if _, err := store.UpsertPendingRegistration(
		r.Context(), h.Pool, req.Email, hash, displayName, code, referredBy,
	); err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	mailSent, err := h.sendVerificationMail(req.Email, code)
	if err != nil {
		_ = store.DeletePendingRegistration(r.Context(), h.Pool, req.Email)
		WriteErr(w, r, http.StatusBadGateway, mailSendUserMessage(err))
		return
	}

	_ = code // код только в письме / логе сервера, не отдаём клиенту
	writeVerificationRequired(w, http.StatusOK, req.Email, "verification code sent", mailSent)
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	login := strings.TrimSpace(req.Email)
	if login == "" || req.Password == "" {
		WriteErr(w, r, http.StatusBadRequest, "email or login and password required")
		return
	}

	u, err := store.GetUserByEmailOrDisplayName(r.Context(), h.Pool, login)
	if err != nil {
		WriteErr(w, r, http.StatusUnauthorized, "invalid email or password")
		return
	}
	if u.PasswordHash == "" || !auth.CheckPassword(req.Password, u.PasswordHash) {
		WriteErr(w, r, http.StatusUnauthorized, "invalid email or password")
		return
	}

	accessToken, refreshToken, expiresIn, err := h.issueSessionTokens(r.Context(), u)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	writeTokenResponse(w, accessToken, refreshToken, expiresIn, u)
}

func (h *AuthHandler) Refresh(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req RefreshRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}

	req.RefreshToken = strings.TrimSpace(req.RefreshToken)
	if req.RefreshToken == "" {
		WriteErr(w, r, http.StatusBadRequest, "refresh_token required")
		return
	}

	claims, err := auth.ParseJWT(h.JWTSecret, req.RefreshToken)
	if err != nil {
		WriteErr(w, r, http.StatusUnauthorized, "invalid or expired token")
		return
	}

	userID, err := UserFromClaims(claims)
	if err != nil {
		WriteErr(w, r, http.StatusUnauthorized, "invalid or expired token")
		return
	}

	tokenHash := refreshTokenHash(req.RefreshToken)
	session, err := store.GetSessionByRefreshTokenHash(r.Context(), h.Pool, tokenHash)
	if err != nil {
		WriteErr(w, r, http.StatusUnauthorized, "invalid or expired token")
		return
	}
	if session.UserID != userID || time.Now().After(session.ExpiresAt) {
		WriteErr(w, r, http.StatusUnauthorized, "invalid or expired token")
		return
	}

	u, err := store.GetUserByID(r.Context(), h.Pool, userID)
	if err != nil || u == nil {
		WriteErr(w, r, http.StatusUnauthorized, "invalid or expired token")
		return
	}

	accessToken, err := auth.NewJWT(h.JWTSecret, u.ID, u.Email, accessTokenExpire)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	nextRefreshToken, err := auth.NewJWT(h.JWTSecret, u.ID, u.Email, refreshTokenExpire)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	err = store.RotateSessionRefreshToken(
		r.Context(),
		h.Pool,
		session.ID,
		refreshTokenHash(nextRefreshToken),
		time.Now().Add(refreshTokenExpire),
	)
	if err != nil {
		if err == pgx.ErrNoRows {
			WriteErr(w, r, http.StatusUnauthorized, "invalid or expired token")
			return
		}
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	writeTokenResponse(
		w,
		accessToken,
		nextRefreshToken,
		int(accessTokenExpire.Seconds()),
		u,
	)
}

func writeTokenResponse(w http.ResponseWriter, accessToken, refreshToken string, expiresIn int, u *store.User) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(TokenResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    expiresIn,
		User:         userToResponse(u),
	})
}

func UserFromClaims(claims *auth.Claims) (userID uuid.UUID, err error) {
	return uuid.Parse(claims.UserID)
}

func (h *AuthHandler) issueSessionTokens(ctx context.Context, u *store.User) (
	accessToken string,
	refreshToken string,
	expiresIn int,
	err error,
) {
	accessToken, err = auth.NewJWT(h.JWTSecret, u.ID, u.Email, accessTokenExpire)
	if err != nil {
		return "", "", 0, err
	}

	refreshToken, err = auth.NewJWT(h.JWTSecret, u.ID, u.Email, refreshTokenExpire)
	if err != nil {
		return "", "", 0, err
	}

	_, err = store.CreateSession(
		ctx,
		h.Pool,
		u.ID,
		refreshTokenHash(refreshToken),
		time.Now().Add(refreshTokenExpire),
	)
	if err != nil {
		return "", "", 0, err
	}

	return accessToken, refreshToken, int(accessTokenExpire.Seconds()), nil
}

func refreshTokenHash(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}
