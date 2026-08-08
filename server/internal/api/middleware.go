package api

import (
	"context"
	"log"
	"net/http"
	"strings"

	"multigames/server/internal/auth"
	"multigames/server/internal/store"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type contextKey string

const UserIDKey contextKey = "user_id"

func CORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, Accept-Language")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

// RequireAuth проверяет JWT. Если pool != nil — сессия должна существовать в БД
// (один активный вход; вход с другого устройства инвалидирует прошлые токены).
func RequireAuth(secret []byte, pool *pgxpool.Pool, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		header := r.Header.Get("Authorization")
		if header == "" {
			WriteErr(w, r, http.StatusUnauthorized, "missing Authorization header")
			return
		}
		parts := strings.SplitN(header, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			WriteErr(w, r, http.StatusUnauthorized, "invalid Authorization header")
			return
		}
		claims, err := auth.ParseJWT(secret, parts[1])
		if err != nil {
			WriteErr(w, r, http.StatusUnauthorized, "invalid or expired token")
			return
		}
		userID, err := uuid.Parse(claims.UserID)
		if err != nil {
			WriteErr(w, r, http.StatusUnauthorized, "invalid token")
			return
		}
		if pool != nil {
			sid, sidErr := uuid.Parse(strings.TrimSpace(claims.SessionID))
			if sidErr != nil {
				WriteErr(w, r, http.StatusUnauthorized, "invalid or expired token")
				return
			}
			ok, existsErr := store.SessionExists(r.Context(), pool, sid)
			if existsErr != nil {
				// Сбой БД ≠ «сессия истекла»: иначе клиент разлогинивает всех
				// при рестарте/деплое (EOF/timeout → 401 → logout).
				log.Printf("auth: SessionExists failed: %v", existsErr)
				WriteErr(w, r, http.StatusServiceUnavailable, "temporarily unavailable")
				return
			}
			if !ok {
				WriteErr(w, r, http.StatusUnauthorized, "invalid or expired token")
				return
			}
		}
		ctx := context.WithValue(r.Context(), UserIDKey, userID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func GetUserID(ctx context.Context) (uuid.UUID, bool) {
	id, ok := ctx.Value(UserIDKey).(uuid.UUID)
	return id, ok
}

// RequireAdmin проверяет, что текущий пользователь — админ. Использовать после RequireAuth.
func RequireAdmin(pool *pgxpool.Pool, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userID, ok := GetUserID(r.Context())
		if !ok {
			WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
			return
		}
		u, err := store.GetUserByID(r.Context(), pool, userID)
		if err != nil || u == nil {
			WriteErr(w, r, http.StatusNotFound, "user not found")
			return
		}
		if !u.IsAdmin {
			WriteErr(w, r, http.StatusForbidden, "admin only")
			return
		}
		next.ServeHTTP(w, r)
	})
}
