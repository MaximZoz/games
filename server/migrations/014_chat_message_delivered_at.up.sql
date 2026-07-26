-- Статус доставки сообщений (как в Telegram: отправлено / доставлено / прочитано).
ALTER TABLE chat_messages
    ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;

-- Уже прочитанные считаем доставленными.
UPDATE chat_messages
SET delivered_at = read_at
WHERE read_at IS NOT NULL
  AND delivered_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_chat_messages_chat_undelivered
    ON chat_messages (chat_id, delivered_at)
    WHERE delivered_at IS NULL;
