CREATE TABLE IF NOT EXISTS user_profile_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    slot SMALLINT NOT NULL CHECK (slot >= 0 AND slot <= 2),
    image_mime TEXT NOT NULL DEFAULT 'image/jpeg',
    image_data BYTEA NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, slot)
);

CREATE INDEX IF NOT EXISTS idx_user_profile_photos_user
    ON user_profile_photos (user_id, slot);
