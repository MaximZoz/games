CREATE TABLE IF NOT EXISTS web_push_preferences (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  chat BOOLEAN NOT NULL DEFAULT true,
  friends BOOLEAN NOT NULL DEFAULT true,
  games BOOLEAN NOT NULL DEFAULT true,
  rewards BOOLEAN NOT NULL DEFAULT true,
  last_daily_reward_push_date DATE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
