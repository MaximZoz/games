-- Регистрация без создания user до подтверждения email (#107)

CREATE TABLE IF NOT EXISTS pending_registrations (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email         TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    display_name  TEXT,
    referred_by   UUID REFERENCES users (id) ON DELETE SET NULL,
    code_hash     TEXT NOT NULL,
    expires_at    TIMESTAMPTZ NOT NULL,
    attempts      INT NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pending_registrations_expires_at
    ON pending_registrations (expires_at);

-- Пользователи, созданные старым flow без подтверждения — удаляем (ещё не в системе «по смыслу»).
DELETE FROM users
WHERE email_verified_at IS NULL
  AND NOT EXISTS (
      SELECT 1 FROM oauth_accounts oa WHERE oa.user_id = users.id
  );
