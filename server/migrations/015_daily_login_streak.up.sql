-- Серия ежедневных входов для ступенчатых наград.
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS daily_login_streak INTEGER NOT NULL DEFAULT 0;

ALTER TABLE users
    DROP CONSTRAINT IF EXISTS users_daily_login_streak_nonneg;

ALTER TABLE users
    ADD CONSTRAINT users_daily_login_streak_nonneg
    CHECK (daily_login_streak >= 0);
