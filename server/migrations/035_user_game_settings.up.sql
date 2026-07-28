CREATE TABLE IF NOT EXISTS user_game_settings (
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    game_type TEXT NOT NULL DEFAULT 'tictactoe',
    turn_time_sec INTEGER NOT NULL DEFAULT 0,
    grid_size INTEGER NOT NULL DEFAULT 3,
    swap_rule BOOLEAN NOT NULL DEFAULT FALSE,
    first_move_restriction BOOLEAN NOT NULL DEFAULT FALSE,
    stake_bronze INTEGER NOT NULL DEFAULT 1
        CHECK (stake_bronze >= 1),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, game_type),
    CONSTRAINT user_game_settings_game_type_nonempty CHECK (game_type <> ''),
    CONSTRAINT user_game_settings_grid_size_range CHECK (grid_size BETWEEN 3 AND 8)
);
