-- Compatibility no-op migration.
-- Keeps migration chain continuous for environments already at version 8.
DO $$
BEGIN
  NULL;
END $$;
