DROP TABLE IF EXISTS chat_members;
DROP INDEX IF EXISTS chats_lobby_uidx;
DROP INDEX IF EXISTS chats_direct_pair_uidx;

ALTER TABLE chats DROP COLUMN IF EXISTS game_type;
ALTER TABLE chats DROP COLUMN IF EXISTS title;
ALTER TABLE chats DROP COLUMN IF EXISTS lobby_id;
ALTER TABLE chats DROP COLUMN IF EXISTS kind;

-- Восстановить NOT NULL для direct-чатов (group должны быть удалены).
DELETE FROM chats WHERE user_low IS NULL OR user_high IS NULL;
ALTER TABLE chats ALTER COLUMN user_low SET NOT NULL;
ALTER TABLE chats ALTER COLUMN user_high SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS chats_user_low_user_high_key ON chats (user_low, user_high);
