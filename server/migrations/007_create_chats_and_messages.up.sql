CREATE TABLE IF NOT EXISTS chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_low  UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    user_high UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (user_low <> user_high),
    CHECK (user_low < user_high),
    UNIQUE (user_low, user_high)
);

CREATE INDEX IF NOT EXISTS idx_chats_user_low ON chats (user_low);
CREATE INDEX IF NOT EXISTS idx_chats_user_high ON chats (user_high);

CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL REFERENCES chats (id) ON DELETE CASCADE,
    sender_user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    read_at TIMESTAMPTZ,
    CHECK (char_length(body) BETWEEN 1 AND 2000)
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_chat_created_desc
    ON chat_messages (chat_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_chat_unread
    ON chat_messages (chat_id, read_at)
    WHERE read_at IS NULL;
