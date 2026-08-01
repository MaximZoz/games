-- История завершённых партий: для статистики игрока (W/D/L, время в игре)
-- и head-to-head (счёт между двумя игроками). Счётчики user_stats остаются.
CREATE TABLE IF NOT EXISTS game_results (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id         TEXT NOT NULL,
    game_type       TEXT NOT NULL DEFAULT 'tictactoe',
    x_user_id       UUID REFERENCES users (id) ON DELETE SET NULL,
    o_user_id       UUID REFERENCES users (id) ON DELETE SET NULL,
    winner_user_id  UUID REFERENCES users (id) ON DELETE SET NULL, -- NULL = ничья
    result          TEXT NOT NULL,              -- 'x_won' | 'o_won' | 'draw'
    finish_reason   TEXT NOT NULL DEFAULT 'normal', -- 'normal' | 'forfeit' | 'timeout' | 'draw_agreement'
    grid_size       INTEGER NOT NULL,
    stake_bronze    INTEGER NOT NULL DEFAULT 0,
    duration_sec    INTEGER NOT NULL DEFAULT 0 CHECK (duration_sec >= 0),
    against_bot     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Быстрая агрегация по каждому игроку (он может быть как X, так и O).
CREATE INDEX IF NOT EXISTS idx_game_results_x_user ON game_results (x_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_game_results_o_user ON game_results (o_user_id, created_at DESC);
