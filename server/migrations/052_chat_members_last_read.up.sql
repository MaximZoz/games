-- Per-user last_read для групповых чатов (unread не общий на всех).
ALTER TABLE chat_members
  ADD COLUMN IF NOT EXISTS last_read_at TIMESTAMPTZ;
