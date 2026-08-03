ALTER TABLE user_game_settings
  ADD COLUMN IF NOT EXISTS variant TEXT NOT NULL DEFAULT 'classic';

UPDATE user_game_settings
SET variant = CASE
  WHEN grid_size = 15 THEN 'gomoku'
  ELSE 'classic'
END
WHERE variant = 'classic' OR variant IS NULL OR variant = '';
