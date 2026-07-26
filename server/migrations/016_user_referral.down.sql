DROP INDEX IF EXISTS idx_users_referred_by;
ALTER TABLE users DROP COLUMN IF EXISTS referred_by;
