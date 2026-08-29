CREATE TABLE IF NOT EXISTS device_push_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'android',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (token)
);

CREATE INDEX IF NOT EXISTS idx_device_push_tokens_user
  ON device_push_tokens (user_id);
