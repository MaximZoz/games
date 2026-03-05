-- Дата последнего получения ежедневной награды (для проверки «раз в день»)
ALTER TABLE users ADD COLUMN IF NOT EXISTS daily_reward_claimed_at TIMESTAMPTZ;
