DROP INDEX IF EXISTS idx_chat_messages_reply_to;

ALTER TABLE chat_messages DROP CONSTRAINT IF EXISTS chat_messages_image_consistent;
ALTER TABLE chat_messages DROP CONSTRAINT IF EXISTS chat_messages_body_or_image;

ALTER TABLE chat_messages
    ADD CONSTRAINT chat_messages_body_check CHECK (char_length(body) BETWEEN 1 AND 2000);

ALTER TABLE chat_messages
    DROP COLUMN IF EXISTS image_data,
    DROP COLUMN IF EXISTS image_mime,
    DROP COLUMN IF EXISTS has_image,
    DROP COLUMN IF EXISTS reply_to_message_id,
    DROP COLUMN IF EXISTS edited_at;
