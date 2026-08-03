ALTER TABLE user_settings
    ADD COLUMN IF NOT EXISTS preferred_language TEXT NOT NULL DEFAULT '';
