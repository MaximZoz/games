package store

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type User struct {
	ID           uuid.UUID
	Email        string
	PasswordHash string
	DisplayName  *string
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
		 RETURNING id, email, password_hash, display_name, created_at::text, updated_at::text`,
		email, passwordHash, displayNamePtr,
	).Scan(&id, &u.Email, &u.PasswordHash, &u.DisplayName, &createdAt, &updatedAt)
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
		`SELECT id, email, password_hash, display_name, created_at::text, updated_at::text
		 FROM users WHERE email = $1`,
		email,
	).Scan(&u.ID, &u.Email, &u.PasswordHash, &u.DisplayName, &u.CreatedAt, &u.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

func GetUserByID(ctx context.Context, pool *pgxpool.Pool, id uuid.UUID) (*User, error) {
	var u User
	err := pool.QueryRow(ctx,
		`SELECT id, email, password_hash, display_name, created_at::text, updated_at::text
		 FROM users WHERE id = $1`,
		id,
	).Scan(&u.ID, &u.Email, &u.PasswordHash, &u.DisplayName, &u.CreatedAt, &u.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return &u, nil
}
