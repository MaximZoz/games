DROP INDEX IF EXISTS idx_admin_coin_grants_unclaimed;
ALTER TABLE admin_coin_grants DROP COLUMN IF EXISTS chat_message_id;
ALTER TABLE admin_coin_grants DROP COLUMN IF EXISTS claimed_at;
