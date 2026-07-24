-- Баланс в бронзовых монетах (1 серебро=100, 1 золото=10000, 1 бриллиант=1000000)
ALTER TABLE users ADD COLUMN IF NOT EXISTS balance_bronze INTEGER NOT NULL DEFAULT 0;

-- Начальный бонус новым и существующим пользователям
UPDATE users SET balance_bronze = 100 WHERE balance_bronze = 0;
