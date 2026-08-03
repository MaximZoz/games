-- Групповые чаты лобби (multi3/multi4): kind=group, участники в chat_members.

ALTER TABLE chats ADD COLUMN IF NOT EXISTS kind TEXT NOT NULL DEFAULT 'direct';
ALTER TABLE chats ADD COLUMN IF NOT EXISTS lobby_id TEXT;
ALTER TABLE chats ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE chats ADD COLUMN IF NOT EXISTS game_type TEXT;

-- Для group user_low/user_high не обязательны.
ALTER TABLE chats ALTER COLUMN user_low DROP NOT NULL;
ALTER TABLE chats ALTER COLUMN user_high DROP NOT NULL;

-- Старый UNIQUE (user_low, user_high) мешает group-строкам — заменяем partial.
ALTER TABLE chats DROP CONSTRAINT IF EXISTS chats_user_low_user_high_key;
DROP INDEX IF EXISTS chats_user_low_user_high_key;

CREATE UNIQUE INDEX IF NOT EXISTS chats_direct_pair_uidx
  ON chats (user_low, user_high)
  WHERE kind = 'direct' AND user_low IS NOT NULL AND user_high IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS chats_lobby_uidx
  ON chats (lobby_id)
  WHERE lobby_id IS NOT NULL AND kind = 'group';

CREATE TABLE IF NOT EXISTS chat_members (
  chat_id UUID NOT NULL REFERENCES chats (id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (chat_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_chat_members_user ON chat_members (user_id);
