-- Настройки Дурака + ослабление CHECK grid_size (gomoku=15, ultimate=9).
ALTER TABLE user_game_settings
    DROP CONSTRAINT IF EXISTS user_game_settings_grid_size_range;

ALTER TABLE user_game_settings
    ADD CONSTRAINT user_game_settings_grid_size_range
        CHECK (grid_size BETWEEN 3 AND 15);

ALTER TABLE user_game_settings
    ADD COLUMN IF NOT EXISTS deck_size INTEGER NOT NULL DEFAULT 36;

ALTER TABLE user_game_settings
    ADD COLUMN IF NOT EXISTS max_players INTEGER NOT NULL DEFAULT 2;

ALTER TABLE user_game_settings
    ADD COLUMN IF NOT EXISTS game_mode TEXT NOT NULL DEFAULT 'podkidnoi';
