-- Несколько фото в одном сообщении чата (до 3).
CREATE TABLE IF NOT EXISTS chat_message_images (
    message_id UUID NOT NULL REFERENCES chat_messages (id) ON DELETE CASCADE,
    idx SMALLINT NOT NULL CHECK (idx >= 0 AND idx < 3),
    image_mime TEXT NOT NULL,
    image_data BYTEA NOT NULL,
    PRIMARY KEY (message_id, idx),
    CONSTRAINT chat_message_images_size CHECK (
        octet_length(image_data) > 0
        AND octet_length(image_data) <= 262144
    )
);

ALTER TABLE chat_messages
    ADD COLUMN IF NOT EXISTS image_count INTEGER NOT NULL DEFAULT 0;

UPDATE chat_messages
SET image_count = 1
WHERE has_image = TRUE
  AND image_count = 0
  AND image_data IS NOT NULL;

INSERT INTO chat_message_images (message_id, idx, image_mime, image_data)
SELECT id, 0, image_mime, image_data
FROM chat_messages
WHERE has_image = TRUE
  AND image_mime IS NOT NULL
  AND image_data IS NOT NULL
ON CONFLICT (message_id, idx) DO NOTHING;
