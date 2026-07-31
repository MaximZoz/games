DROP TABLE IF EXISTS oauth_accounts;
DROP TABLE IF EXISTS email_verification_codes;

ALTER TABLE users
    ALTER COLUMN password_hash SET NOT NULL;

ALTER TABLE users
    DROP COLUMN IF EXISTS email_verified_at;
