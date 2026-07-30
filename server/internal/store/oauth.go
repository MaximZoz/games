package store

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type OAuthAccount struct {
	ID             uuid.UUID
	UserID         uuid.UUID
	Provider       string
	ProviderUserID string
	Email          *string
	CreatedAt      time.Time
}

func GetOAuthAccount(ctx context.Context, pool *pgxpool.Pool, provider, providerUserID string) (*OAuthAccount, error) {
	row := pool.QueryRow(ctx, `
		SELECT id, user_id, provider, provider_user_id, email, created_at
		FROM oauth_accounts
		WHERE provider = $1 AND provider_user_id = $2
	`, provider, providerUserID)
	var a OAuthAccount
	err := row.Scan(&a.ID, &a.UserID, &a.Provider, &a.ProviderUserID, &a.Email, &a.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &a, nil
}

func LinkOAuthAccount(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, provider, providerUserID string, email string) error {
	var emailPtr *string
	if email != "" {
		e := strings.ToLower(strings.TrimSpace(email))
		emailPtr = &e
	}
	_, err := pool.Exec(ctx, `
		INSERT INTO oauth_accounts (user_id, provider, provider_user_id, email)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (provider, provider_user_id) DO NOTHING
	`, userID, provider, providerUserID, emailPtr)
	return err
}

// FindOrCreateOAuthUser находит пользователя по OAuth или создаёт нового.
// Если email уже есть у локального аккаунта — привязывает OAuth к нему и подтверждает email.
func FindOrCreateOAuthUser(
	ctx context.Context,
	pool *pgxpool.Pool,
	provider, providerUserID, email, displayName string,
	referredBy *uuid.UUID,
) (*User, bool, error) {
	if acc, err := GetOAuthAccount(ctx, pool, provider, providerUserID); err == nil {
		u, err := GetUserByID(ctx, pool, acc.UserID)
		return u, false, err
	} else if err != pgx.ErrNoRows {
		return nil, false, err
	}

	email = strings.ToLower(strings.TrimSpace(email))
	tx, err := pool.Begin(ctx)
	if err != nil {
		return nil, false, err
	}
	defer tx.Rollback(ctx)

	var u *User
	created := false

	if email != "" {
		existing, err := GetUserByEmail(ctx, pool, email)
		if err == nil {
			u = existing
			if u.EmailVerifiedAt == nil {
				_, err = tx.Exec(ctx, `
					UPDATE users SET email_verified_at = now(), updated_at = now() WHERE id = $1
				`, u.ID)
				if err != nil {
					return nil, false, err
				}
				now := time.Now()
				u.EmailVerifiedAt = &now
			}
		} else if err != pgx.ErrNoRows {
			return nil, false, err
		}
	}

	if u == nil {
		var referrerID *uuid.UUID
		if referredBy != nil && *referredBy != uuid.Nil {
			var exists uuid.UUID
			err = tx.QueryRow(ctx, `SELECT id FROM users WHERE id = $1`, *referredBy).Scan(&exists)
			if err == nil {
				referrerID = referredBy
			}
		}

		displayNamePtr := (*string)(nil)
		name := strings.TrimSpace(displayName)
		if name != "" {
			displayNamePtr = &name
		} else if email != "" {
			local := strings.Split(email, "@")[0]
			local = strings.Map(func(r rune) rune {
				if (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') || r == '_' || r == '-' {
					return r
				}
				return -1
			}, local)
			if local != "" {
				displayNamePtr = &local
			}
		}

		oauthEmail := email
		if oauthEmail == "" {
			// Уникальный placeholder без @ реального провайдера — не для логина паролем.
			oauthEmail = provider + "_" + providerUserID + "@oauth.local"
		}

		row := tx.QueryRow(ctx, `
			INSERT INTO users (email, password_hash, display_name, balance_bronze, referred_by, email_verified_at)
			VALUES ($1, NULL, $2, $3, $4, now())
			RETURNING `+selectUserCols,
			oauthEmail, displayNamePtr, RegistrationBonusBronze, referrerID,
		)
		u, err = scanUser(row)
		if err != nil {
			// Конфликт display_name — повторим без имени.
			if displayNamePtr != nil {
				row = tx.QueryRow(ctx, `
					INSERT INTO users (email, password_hash, display_name, balance_bronze, referred_by, email_verified_at)
					VALUES ($1, NULL, NULL, $2, $3, now())
					RETURNING `+selectUserCols,
					oauthEmail, RegistrationBonusBronze, referrerID,
				)
				u, err = scanUser(row)
			}
			if err != nil {
				return nil, false, err
			}
		}
		created = true

		if referrerID != nil {
			_, err = tx.Exec(ctx, `
				UPDATE users
				SET balance_bronze = balance_bronze + $2, updated_at = now()
				WHERE id = $1
			`, *referrerID, ReferralBonusBronze)
			if err != nil {
				return nil, false, err
			}
		}
	}

	var emailPtr *string
	if email != "" {
		emailPtr = &email
	}
	_, err = tx.Exec(ctx, `
		INSERT INTO oauth_accounts (user_id, provider, provider_user_id, email)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (provider, provider_user_id) DO NOTHING
	`, u.ID, provider, providerUserID, emailPtr)
	if err != nil {
		return nil, false, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, false, err
	}

	// Перечитаем из пула после коммита.
	fresh, err := GetUserByID(ctx, pool, u.ID)
	if err != nil {
		return u, created, nil
	}
	return fresh, created, nil
}
