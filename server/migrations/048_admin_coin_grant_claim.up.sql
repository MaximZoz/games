-- Отложенное получение админского начисления: claimed_at NULL = ещё не забрано.
ALTER TABLE admin_coin_grants
    ADD COLUMN IF NOT EXISTS claimed_at TIMESTAMPTZ;

ALTER TABLE admin_coin_grants
    ADD COLUMN IF NOT EXISTS chat_message_id UUID REFERENCES chat_messages (id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_admin_coin_grants_unclaimed
    ON admin_coin_grants (user_id)
    WHERE claimed_at IS NULL AND amount_bronze > 0;
