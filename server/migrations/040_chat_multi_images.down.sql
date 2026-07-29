DROP TABLE IF EXISTS chat_message_images;

ALTER TABLE chat_messages
    DROP COLUMN IF EXISTS image_count;
