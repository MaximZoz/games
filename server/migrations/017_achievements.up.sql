-- Статистика для достижений (игры живут в Redis, счётчик — в Postgres).
CREATE TABLE IF NOT EXISTS user_stats (
    user_id UUID PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    games_finished INTEGER NOT NULL DEFAULT 0
        CHECK (games_finished >= 0)
);

-- Разблокированные / забранные достижения.
CREATE TABLE IF NOT EXISTS user_achievements (
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    code TEXT NOT NULL,
    reward_bronze INTEGER NOT NULL CHECK (reward_bronze >= 0),
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    claimed_at TIMESTAMPTZ,
    PRIMARY KEY (user_id, code)
);

CREATE INDEX IF NOT EXISTS idx_user_achievements_unclaimed
    ON user_achievements (user_id)
    WHERE claimed_at IS NULL;
