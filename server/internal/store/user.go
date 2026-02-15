package store

import (
	"context"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type User struct {
	ID           uuid.UUID
	Email        string
	PasswordHash string
	DisplayName  *string
	IsAdmin      bool
	CreatedAt    string
	UpdatedAt    string
}

func CreateUser(ctx context.Context, pool *pgxpool.Pool, email, passwordHash, displayName string) (*User, error) {
	var u User
	var id uuid.UUID
	var createdAt, updatedAt string
	displayNamePtr := (*string)(nil)
	if displayName != "" {
		displayNamePtr = &displayName
	}
	err := pool.QueryRow(ctx,
		`INSERT INTO users (email, password_hash, display_name)
		 VALUES ($1, $2, $3)
		 RETURNING id, email, password_hash, display_name, is_admin, created_at::text, updated_at::text`,
		email, passwordHash, displayNamePtr,
	).Scan(&id, &u.Email, &u.PasswordHash, &u.DisplayName, &u.IsAdmin, &createdAt, &updatedAt)
	if err != nil {
		return nil, err
	}
	u.ID = id
	u.CreatedAt = createdAt
	u.UpdatedAt = updatedAt
	return &u, nil
}

func GetUserByEmail(ctx context.Context, pool *pgxpool.Pool, email string) (*User, error) {
	var u User
	err := pool.QueryRow(ctx,
		`SELECT id, email, password_hash, display_name, is_admin, created_at::text, updated_at::text
		 FROM users WHERE email = $1`,
		email,
	).Scan(&u.ID, &u.Email, &u.PasswordHash, &u.DisplayName, &u.IsAdmin, &u.CreatedAt, &u.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

func GetUserByDisplayName(ctx context.Context, pool *pgxpool.Pool, displayName string) (*User, error) {
	var u User
	err := pool.QueryRow(ctx,
		`SELECT id, email, password_hash, display_name, is_admin, created_at::text, updated_at::text
		 FROM users WHERE display_name = $1`,
		displayName,
	).Scan(&u.ID, &u.Email, &u.PasswordHash, &u.DisplayName, &u.IsAdmin, &u.CreatedAt, &u.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

// GetUserByEmailOrDisplayName находит пользователя по email (с приведением к нижнему регистру) или по display_name.
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
	var u User
	err := pool.QueryRow(ctx,
		`SELECT id, email, password_hash, display_name, is_admin, created_at::text, updated_at::text
		 FROM users WHERE id = $1`,
		id,
	).Scan(&u.ID, &u.Email, &u.PasswordHash, &u.DisplayName, &u.IsAdmin, &u.CreatedAt, &u.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

func ListUsers(ctx context.Context, pool *pgxpool.Pool) ([]User, error) {
	rows, err := pool.Query(ctx,
		`SELECT id, email, password_hash, display_name, is_admin, created_at::text, updated_at::text
		 FROM users ORDER BY created_at DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []User
	for rows.Next() {
		var u User
		if err := rows.Scan(&u.ID, &u.Email, &u.PasswordHash, &u.DisplayName, &u.IsAdmin, &u.CreatedAt, &u.UpdatedAt); err != nil {
			return nil, err
		}
		list = append(list, u)
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
