ALTER TABLE users DROP CONSTRAINT IF EXISTS users_daily_login_streak_nonneg;
ALTER TABLE users DROP COLUMN IF EXISTS daily_login_streak;
