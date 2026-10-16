-- Предыдущий refresh ещё принимается, если клиент не сохранил новый
-- (ответ оборвался уже после записи в БД).
ALTER TABLE sessions
    ADD COLUMN IF NOT EXISTS previous_refresh_token_hash TEXT,
    ADD COLUMN IF NOT EXISTS previous_refresh_valid_until TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_sessions_previous_refresh_hash
    ON sessions (previous_refresh_token_hash)
    WHERE previous_refresh_token_hash IS NOT NULL;
