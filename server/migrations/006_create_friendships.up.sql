CREATE TABLE IF NOT EXISTS friendships (
    user_low  UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    user_high UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_low, user_high),
    CHECK (user_low <> user_high),
    CHECK (user_low < user_high)
);

CREATE INDEX IF NOT EXISTS idx_friendships_user_low ON friendships (user_low);
CREATE INDEX IF NOT EXISTS idx_friendships_user_high ON friendships (user_high);

CREATE TABLE IF NOT EXISTS friend_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_user_id   UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    receiver_user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (sender_user_id <> receiver_user_id),
    UNIQUE (sender_user_id, receiver_user_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_friend_requests_pair_unique
    ON friend_requests (LEAST(sender_user_id, receiver_user_id), GREATEST(sender_user_id, receiver_user_id));

CREATE INDEX IF NOT EXISTS idx_friend_requests_receiver_created
    ON friend_requests (receiver_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_friend_requests_sender_created
    ON friend_requests (sender_user_id, created_at DESC);
