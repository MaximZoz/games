package api

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"multigames/server/internal/auth"
	"multigames/server/internal/store"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	accessTokenExpire  = 15 * time.Minute
	refreshTokenExpire = 7 * 24 * time.Hour
)

type AuthHandler struct {
	Pool      *pgxpool.Pool
	JWTSecret []byte
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
	}
}

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	req.Email = strings.TrimSpace(strings.ToLower(req.Email))
	if req.Email == "" || len(req.Password) < 6 {
		http.Error(w, "email required, password at least 6 characters", http.StatusBadRequest)
		return
	}

	hash, err := auth.HashPassword(req.Password)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}

	var referredBy *uuid.UUID
	if refRaw := strings.TrimSpace(req.Ref); refRaw != "" {
		if id, parseErr := uuid.Parse(refRaw); parseErr == nil {
			referredBy = &id
		}
	}

	u, err := store.CreateUser(r.Context(), h.Pool, req.Email, hash, req.DisplayName, referredBy)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate key") || strings.Contains(err.Error(), "unique") {
			http.Error(w, "email already registered", http.StatusConflict)
			return
		}
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}

	accessToken, refreshToken, expiresIn, err := h.issueSessionTokens(r.Context(), u)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}

	writeTokenResponse(w, accessToken, refreshToken, expiresIn, u)
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	login := strings.TrimSpace(req.Email)
	if login == "" || req.Password == "" {
		http.Error(w, "email or login and password required", http.StatusBadRequest)
		return
	}

	u, err := store.GetUserByEmailOrDisplayName(r.Context(), h.Pool, login)
	if err != nil {
		http.Error(w, "invalid email or password", http.StatusUnauthorized)
		return
	}
	if !auth.CheckPassword(req.Password, u.PasswordHash) {
		http.Error(w, "invalid email or password", http.StatusUnauthorized)
		return
	}

	accessToken, refreshToken, expiresIn, err := h.issueSessionTokens(r.Context(), u)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}

	writeTokenResponse(w, accessToken, refreshToken, expiresIn, u)
}

func (h *AuthHandler) Refresh(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req RefreshRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	req.RefreshToken = strings.TrimSpace(req.RefreshToken)
	if req.RefreshToken == "" {
		http.Error(w, "refresh_token required", http.StatusBadRequest)
		return
	}

	claims, err := auth.ParseJWT(h.JWTSecret, req.RefreshToken)
	if err != nil {
		http.Error(w, "invalid or expired token", http.StatusUnauthorized)
		return
	}

	userID, err := UserFromClaims(claims)
	if err != nil {
		http.Error(w, "invalid or expired token", http.StatusUnauthorized)
		return
	}

	tokenHash := refreshTokenHash(req.RefreshToken)
	session, err := store.GetSessionByRefreshTokenHash(r.Context(), h.Pool, tokenHash)
	if err != nil {
		http.Error(w, "invalid or expired token", http.StatusUnauthorized)
		return
	}
	if session.UserID != userID || time.Now().After(session.ExpiresAt) {
		http.Error(w, "invalid or expired token", http.StatusUnauthorized)
		return
	}

	u, err := store.GetUserByID(r.Context(), h.Pool, userID)
	if err != nil || u == nil {
		http.Error(w, "invalid or expired token", http.StatusUnauthorized)
		return
	}

	accessToken, err := auth.NewJWT(h.JWTSecret, u.ID, u.Email, accessTokenExpire)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	nextRefreshToken, err := auth.NewJWT(h.JWTSecret, u.ID, u.Email, refreshTokenExpire)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
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
			http.Error(w, "invalid or expired token", http.StatusUnauthorized)
			return
		}
		http.Error(w, "server error", http.StatusInternalServerError)
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
