-- Фото, редактирование и ответы в чате (как в Telegram).
ALTER TABLE chat_messages
    ADD COLUMN IF NOT EXISTS edited_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS reply_to_message_id UUID REFERENCES chat_messages (id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS has_image BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS image_mime TEXT,
    ADD COLUMN IF NOT EXISTS image_data BYTEA;

ALTER TABLE chat_messages DROP CONSTRAINT IF EXISTS chat_messages_body_check;

-- Текст 1..2000, либо фото (подпись опциональна, до 2000).
ALTER TABLE chat_messages
    ADD CONSTRAINT chat_messages_body_or_image CHECK (
        (
            has_image = TRUE
            AND char_length(COALESCE(body, '')) <= 2000
        )
        OR (
            has_image = FALSE
            AND char_length(body) BETWEEN 1 AND 2000
        )
    );

ALTER TABLE chat_messages
    ADD CONSTRAINT chat_messages_image_consistent CHECK (
        (
            has_image = FALSE
            AND image_mime IS NULL
            AND image_data IS NULL
        )
        OR (
            has_image = TRUE
            AND image_mime IS NOT NULL
            AND image_data IS NOT NULL
            AND octet_length(image_data) > 0
            AND octet_length(image_data) <= 3145728
        )
    );

CREATE INDEX IF NOT EXISTS idx_chat_messages_reply_to
    ON chat_messages (reply_to_message_id)
    WHERE reply_to_message_id IS NOT NULL;
