package store

import (
	"context"
	"crypto/subtle"
	"database/sql"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ErrRefreshTokenRejected — предъявленный refresh не текущий и не предыдущий
// в окне grace, либо сессия уже истекла.
var ErrRefreshTokenRejected = errors.New("refresh token rejected")

type Session struct {
	ID               uuid.UUID
	UserID           uuid.UUID
	RefreshTokenHash string
	ExpiresAt        time.Time
	CreatedAt        time.Time
}

func scanSession(row pgx.Row) (*Session, error) {
	var s Session
	err := row.Scan(
		&s.ID,
		&s.UserID,
		&s.RefreshTokenHash,
		&s.ExpiresAt,
		&s.CreatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &s, nil
}

func CreateSession(
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
	refreshTokenHash string,
	expiresAt time.Time,
) (*Session, error) {
	row := pool.QueryRow(ctx,
		`INSERT INTO sessions (user_id, refresh_token_hash, expires_at)
		 VALUES ($1, $2, $3)
		 RETURNING id, user_id, refresh_token_hash, expires_at, created_at`,
		userID, refreshTokenHash, expiresAt,
	)
	return scanSession(row)
}

func GetSessionByRefreshTokenHash(
	ctx context.Context,
	pool *pgxpool.Pool,
	refreshTokenHash string,
) (*Session, error) {
	row := pool.QueryRow(ctx,
		`SELECT id, user_id, refresh_token_hash, expires_at, created_at
		 FROM sessions
		 WHERE refresh_token_hash = $1`,
		refreshTokenHash,
	)
	return scanSession(row)
}

func RotateSessionRefreshToken(
	ctx context.Context,
	pool *pgxpool.Pool,
	sessionID uuid.UUID,
	nextRefreshTokenHash string,
	expiresAt time.Time,
) error {
	tag, err := pool.Exec(ctx,
		`UPDATE sessions
		 SET refresh_token_hash = $2, expires_at = $3
		 WHERE id = $1`,
		sessionID, nextRefreshTokenHash, expiresAt,
	)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

// DeleteSessionsByUserID удаляет все сессии пользователя (заморозка, бан).
func DeleteSessionsByUserID(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) error {
	_, err := pool.Exec(ctx, `DELETE FROM sessions WHERE user_id = $1`, userID)
	return err
}

// DeleteExpiredSessionsByUserID убирает протухшие строки, живые сессии не трогает.
func DeleteExpiredSessionsByUserID(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) error {
	_, err := pool.Exec(ctx,
		`DELETE FROM sessions WHERE user_id = $1 AND expires_at <= NOW()`,
		userID,
	)
	return err
}

func refreshHashEqual(a, b string) bool {
	if a == "" || len(a) != len(b) {
		return false
	}
	return subtle.ConstantTimeCompare([]byte(a), []byte(b)) == 1
}

// PresentedRefreshAccepted — текущий хеш или предыдущий, пока не вышло окно grace.
func PresentedRefreshAccepted(
	current, previous string,
	previousUntil time.Time,
	previousSet bool,
	presented string,
	now time.Time,
) bool {
	if presented == "" {
		return false
	}
	if refreshHashEqual(presented, current) {
		return true
	}
	if !previousSet || previous == "" || !refreshHashEqual(presented, previous) {
		return false
	}
	return now.Before(previousUntil)
}

// FindSessionIDByPresentedRefresh ищет сессию по текущему или ещё действующему
// предыдущему refresh. sid в JWT обычно известен, это запасной путь.
func FindSessionIDByPresentedRefresh(
	ctx context.Context,
	pool *pgxpool.Pool,
	presentedHash string,
	now time.Time,
) (uuid.UUID, error) {
	var id uuid.UUID
	err := pool.QueryRow(ctx, `
		SELECT id FROM sessions
		WHERE refresh_token_hash = $1
		   OR (previous_refresh_token_hash = $1 AND previous_refresh_valid_until > $2)
		LIMIT 1`,
		presentedHash, now,
	).Scan(&id)
	return id, err
}

// AcceptRefreshAndRotate под локом строки принимает текущий или предыдущий
// refresh и записывает новый хеш. Предыдущий остаётся действительным до
// previousValidUntil, чтобы повтор со старым токеном не разлогинивал клиента.
func AcceptRefreshAndRotate(
	ctx context.Context,
	pool *pgxpool.Pool,
	sessionID uuid.UUID,
	expectedUser uuid.UUID,
	presentedHash string,
	nextHash string,
	expiresAt time.Time,
	previousValidUntil time.Time,
	now time.Time,
) (*Session, error) {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var (
		id        uuid.UUID
		userID    uuid.UUID
		current   string
		expires   time.Time
		createdAt time.Time
		prev      sql.NullString
		prevUntil sql.NullTime
	)
	err = tx.QueryRow(ctx, `
		SELECT id, user_id, refresh_token_hash, expires_at, created_at,
		       previous_refresh_token_hash, previous_refresh_valid_until
		FROM sessions
		WHERE id = $1
		FOR UPDATE`,
		sessionID,
	).Scan(&id, &userID, &current, &expires, &createdAt, &prev, &prevUntil)
	if err != nil {
		return nil, err
	}
	if userID != expectedUser || !now.Before(expires) {
		return nil, ErrRefreshTokenRejected
	}
	var until time.Time
	if prevUntil.Valid {
		until = prevUntil.Time
	}
	if !PresentedRefreshAccepted(current, prev.String, until, prev.Valid, presentedHash, now) {
		return nil, ErrRefreshTokenRejected
	}

	tag, err := tx.Exec(ctx, `
		UPDATE sessions
		SET previous_refresh_token_hash = refresh_token_hash,
		    previous_refresh_valid_until = $2,
		    refresh_token_hash = $3,
		    expires_at = $4
		WHERE id = $1`,
		id, previousValidUntil, nextHash, expiresAt,
	)
	if err != nil {
		return nil, err
	}
	if tag.RowsAffected() == 0 {
		return nil, pgx.ErrNoRows
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return &Session{
		ID:               id,
		UserID:           userID,
		RefreshTokenHash: nextHash,
		ExpiresAt:        expiresAt,
		CreatedAt:        createdAt,
	}, nil
}

// SessionExists возвращает true, если сессия ещё в БД и не истекла.
// При кратковременных сбоях пула/соединения делает несколько попыток —
// иначе клиент на каждом деплое видит залипший 503 «temporarily unavailable».
func SessionExists(ctx context.Context, pool *pgxpool.Pool, sessionID uuid.UUID) (bool, error) {
	const attempts = 3
	var last error
	for i := 0; i < attempts; i++ {
		if i > 0 {
			delay := time.Duration(i) * 80 * time.Millisecond
			timer := time.NewTimer(delay)
			select {
			case <-ctx.Done():
				timer.Stop()
				if last != nil {
					return false, last
				}
				return false, ctx.Err()
			case <-timer.C:
			}
		}
		var ok bool
		err := pool.QueryRow(ctx,
			`SELECT EXISTS(
				SELECT 1 FROM sessions
				WHERE id = $1 AND expires_at > NOW()
			)`,
			sessionID,
		).Scan(&ok)
		if err == nil {
			return ok, nil
		}
		if errors.Is(err, context.Canceled) {
			return false, err
		}
		last = err
	}
	return false, last
}
