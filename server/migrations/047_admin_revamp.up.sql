-- Заморозка пользователя: NULL = активен.
ALTER TABLE users ADD COLUMN IF NOT EXISTS frozen_at TIMESTAMPTZ;

-- Системный аккаунт поддержки: через него идут диалоги user↔поддержка.
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_support BOOLEAN NOT NULL DEFAULT FALSE;

-- Аудит начисления монет админом.
CREATE TABLE IF NOT EXISTS admin_coin_grants (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    admin_id      UUID REFERENCES users (id) ON DELETE SET NULL,
    amount_bronze INTEGER NOT NULL CHECK (amount_bronze <> 0),
    reason        TEXT NOT NULL DEFAULT '',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_admin_coin_grants_user ON admin_coin_grants (user_id, created_at DESC);

-- Bootstrap системного аккаунта «Поддержка».
-- is_admin=true — чтобы обычные admin-проверки не мешали; вход невозможен
-- (пустой password_hash, верификация только по флагу is_support).
INSERT INTO users (email, password_hash, display_name, is_admin, is_support, avatar_kind)
VALUES ('support@zozu', '', 'Поддержка', true, true, 'letter')
ON CONFLICT (email) DO UPDATE SET is_support = true, is_admin = true;
