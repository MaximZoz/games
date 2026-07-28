UPDATE users
SET balance_bronze = GREATEST(0, balance_bronze - 1000000),
    updated_at = now()
WHERE lower(display_name) = lower('iZozu')
   OR lower(email) LIKE '%izozo%';
