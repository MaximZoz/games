-- Начислить пользователю iZozu 1 бриллиант (1_000_000 бронзы).
UPDATE users
SET balance_bronze = balance_bronze + 1000000,
    updated_at = now()
WHERE lower(display_name) = lower('iZozu')
   OR lower(email) LIKE '%izozo%';
