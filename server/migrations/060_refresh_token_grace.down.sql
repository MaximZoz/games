DROP INDEX IF EXISTS idx_sessions_previous_refresh_hash;

ALTER TABLE sessions
    DROP COLUMN IF EXISTS previous_refresh_valid_until,
    DROP COLUMN IF EXISTS previous_refresh_token_hash;
