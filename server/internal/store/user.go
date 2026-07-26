package store

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type User struct {
	ID            uuid.UUID
	Email         string
	PasswordHash  string
	DisplayName   *string
	IsAdmin       bool
	Age           *int
	Gender        *string
	About         *string
	AvatarKind    string
	AvatarValue   *string
	BalanceBronze int
	CreatedAt     string
	UpdatedAt     string
}

const selectUserCols = `id, email, password_hash, display_name, is_admin,
	age, gender, about, avatar_kind, avatar_value,
	balance_bronze,
	created_at::text, updated_at::text`

func scanUser(row pgx.Row) (*User, error) {
	var u User
	err := row.Scan(
		&u.ID, &u.Email, &u.PasswordHash, &u.DisplayName, &u.IsAdmin,
		&u.Age, &u.Gender, &u.About, &u.AvatarKind, &u.AvatarValue,
		&u.BalanceBronze,
		&u.CreatedAt, &u.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

func CreateUser(
	ctx context.Context,
	pool *pgxpool.Pool,
	email, passwordHash, displayName string,
	referredBy *uuid.UUID,
) (*User, error) {
	displayNamePtr := (*string)(nil)
	if displayName != "" {
		displayNamePtr = &displayName
	}

	tx, err := pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var referrerID *uuid.UUID
	if referredBy != nil && *referredBy != uuid.Nil {
		var exists uuid.UUID
		err = tx.QueryRow(ctx, `SELECT id FROM users WHERE id = $1`, *referredBy).Scan(&exists)
		if err == nil {
			referrerID = referredBy
		}
		// Невалидный ref игнорируем — регистрация всё равно проходит.
	}

	row := tx.QueryRow(ctx,
		`INSERT INTO users (email, password_hash, display_name, balance_bronze, referred_by)
		 VALUES ($1, $2, $3, $4, $5)
		 RETURNING `+selectUserCols,
		email, passwordHash, displayNamePtr, RegistrationBonusBronze, referrerID,
	)
	u, err := scanUser(row)
	if err != nil {
		return nil, err
	}

	if referrerID != nil {
		_, err = tx.Exec(ctx, `
			UPDATE users
			SET balance_bronze = balance_bronze + $2, updated_at = now()
			WHERE id = $1
		`, *referrerID, ReferralBonusBronze)
		if err != nil {
			return nil, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return u, nil
}

func GetUserByEmail(ctx context.Context, pool *pgxpool.Pool, email string) (*User, error) {
	row := pool.QueryRow(ctx,
		`SELECT `+selectUserCols+` FROM users WHERE email = $1`, email)
	return scanUser(row)
}

func GetUserByDisplayName(ctx context.Context, pool *pgxpool.Pool, displayName string) (*User, error) {
	row := pool.QueryRow(ctx,
		`SELECT `+selectUserCols+` FROM users WHERE display_name = $1`, displayName)
	return scanUser(row)
}

func GetUserByEmailOrDisplayName(ctx context.Context, pool *pgxpool.Pool, login string) (*User, error) {
	login = strings.TrimSpace(login)
	if login == "" {
		return nil, pgx.ErrNoRows
	}
	u, err := GetUserByEmail(ctx, pool, strings.ToLower(login))
	if err == nil {
		return u, nil
	}
	if err != pgx.ErrNoRows {
		return nil, err
	}
	return GetUserByDisplayName(ctx, pool, login)
}

func GetUserByID(ctx context.Context, pool *pgxpool.Pool, id uuid.UUID) (*User, error) {
	row := pool.QueryRow(ctx,
		`SELECT `+selectUserCols+` FROM users WHERE id = $1`, id)
	return scanUser(row)
}

func ListUsers(ctx context.Context, pool *pgxpool.Pool) ([]User, error) {
	rows, err := pool.Query(ctx,
		`SELECT `+selectUserCols+` FROM users ORDER BY created_at DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []User
	for rows.Next() {
		u, err := scanUser(rows)
		if err != nil {
			return nil, err
		}
		list = append(list, *u)
	}
	return list, rows.Err()
}

func SetUserAdmin(ctx context.Context, pool *pgxpool.Pool, id uuid.UUID, isAdmin bool) error {
	_, err := pool.Exec(ctx, `UPDATE users SET is_admin = $1, updated_at = now() WHERE id = $2`, isAdmin, id)
	return err
}

func SetUserPassword(ctx context.Context, pool *pgxpool.Pool, id uuid.UUID, passwordHash string) error {
	_, err := pool.Exec(ctx, `UPDATE users SET password_hash = $1, updated_at = now() WHERE id = $2`, passwordHash, id)
	return err
}

func DeleteUser(ctx context.Context, pool *pgxpool.Pool, id uuid.UUID) error {
	_, err := pool.Exec(ctx, `DELETE FROM users WHERE id = $1`, id)
	return err
}

func CountAdmins(ctx context.Context, pool *pgxpool.Pool) (int, error) {
	var n int
	err := pool.QueryRow(ctx, `SELECT COUNT(*) FROM users WHERE is_admin = true`).Scan(&n)
	return n, err
}

func CountUsers(ctx context.Context, pool *pgxpool.Pool) (int, error) {
	var n int
	err := pool.QueryRow(ctx, `SELECT COUNT(*)::int FROM users`).Scan(&n)
	return n, err
}

type UpdateProfileParams struct {
	ID          uuid.UUID
	DisplayName *string
	Age         *int
	Gender      *string
	About       *string
	AvatarKind  *string
	AvatarValue *string
}

func UpdateUserProfile(ctx context.Context, pool *pgxpool.Pool, p UpdateProfileParams) (*User, error) {
	row := pool.QueryRow(ctx,
		`UPDATE users SET
			display_name  = COALESCE($2, display_name),
			age           = $3,
			gender        = $4,
			about         = $5,
			avatar_kind   = COALESCE($6, avatar_kind),
			avatar_value  = $7,
			updated_at    = now()
		 WHERE id = $1
		 RETURNING `+selectUserCols,
		p.ID, p.DisplayName, p.Age, p.Gender, p.About, p.AvatarKind, p.AvatarValue,
	)
	return scanUser(row)
}

// UpdateUserLastSeen sets last_seen_at to now() for the given user.
func UpdateUserLastSeen(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) error {
	_, err := pool.Exec(ctx,
		`UPDATE users SET last_seen_at = now() WHERE id = $1`,
		userID,
	)
	return err
}

// PresenceEntry holds online status and last_seen_at for a user.
type PresenceEntry struct {
	Online     bool
	LastSeenAt *time.Time
}

// GetLastSeenForUsers returns last_seen_at for the given user IDs.
// Users not in the map have no last_seen_at recorded.
func GetLastSeenForUsers(ctx context.Context, pool *pgxpool.Pool, userIDs []uuid.UUID) (map[uuid.UUID]*time.Time, error) {
	result := make(map[uuid.UUID]*time.Time)
	for _, id := range userIDs {
		var t time.Time
		err := pool.QueryRow(ctx,
			`SELECT last_seen_at FROM users WHERE id = $1 AND last_seen_at IS NOT NULL`,
			id,
		).Scan(&t)
		if err == pgx.ErrNoRows {
			continue
		}
		if err != nil {
			return nil, err
		}
		result[id] = &t
	}
	return result, nil
}

// GetPresenceRecipientsForUser returns user IDs that should receive
// user_online/user_offline when the given user connects or disconnects:
// friends + chat peers.
func GetPresenceRecipientsForUser(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) ([]uuid.UUID, error) {
	rows, err := pool.Query(ctx, `
		(SELECT CASE WHEN user_low = $1 THEN user_high ELSE user_low END AS peer_id
		 FROM friendships WHERE user_low = $1 OR user_high = $1)
		UNION
		(SELECT CASE WHEN user_low = $1 THEN user_high ELSE user_low END AS peer_id
		 FROM chats WHERE user_low = $1 OR user_high = $1)
	`, userID, userID, userID, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	seen := make(map[uuid.UUID]struct{})
	var result []uuid.UUID
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		if id == userID {
			continue
		}
		if _, ok := seen[id]; ok {
			continue
		}
		seen[id] = struct{}{}
		result = append(result, id)
	}
	return result, rows.Err()
}
