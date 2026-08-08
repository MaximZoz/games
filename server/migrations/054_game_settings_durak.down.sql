ALTER TABLE user_game_settings
    DROP COLUMN IF EXISTS game_mode;

ALTER TABLE user_game_settings
    DROP COLUMN IF EXISTS max_players;

ALTER TABLE user_game_settings
    DROP COLUMN IF EXISTS deck_size;

ALTER TABLE user_game_settings
    DROP CONSTRAINT IF EXISTS user_game_settings_grid_size_range;

ALTER TABLE user_game_settings
    ADD CONSTRAINT user_game_settings_grid_size_range
        CHECK (grid_size BETWEEN 3 AND 8);
