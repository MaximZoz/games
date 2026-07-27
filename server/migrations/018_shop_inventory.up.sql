-- Магазин и инвентарь (#111).
CREATE TABLE IF NOT EXISTS shop_items (
    code TEXT PRIMARY KEY,
    kind TEXT NOT NULL
        CHECK (kind IN ('emoji', 'stake_unlock', 'frame')),
    title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    price_bronze INTEGER NOT NULL CHECK (price_bronze >= 0),
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    -- NULL = безлимит; иначе глобальный остаток.
    stock_remaining INTEGER
        CHECK (stock_remaining IS NULL OR stock_remaining >= 0),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS user_inventory (
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    item_code TEXT NOT NULL REFERENCES shop_items (code) ON DELETE CASCADE,
    acquired_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, item_code)
);

CREATE INDEX IF NOT EXISTS idx_user_inventory_user
    ON user_inventory (user_id);

-- Смайлики (лимитированный сток).
INSERT INTO shop_items (code, kind, title, description, price_bronze, payload, stock_remaining, sort_order)
VALUES
    ('emoji_fire', 'emoji', 'Огонь', 'Тематический смайлик', 50, '{"emoji":"🔥"}'::jsonb, 100, 10),
    ('emoji_star', 'emoji', 'Звезда', 'Тематический смайлик', 50, '{"emoji":"⭐"}'::jsonb, 100, 20),
    ('emoji_trophy', 'emoji', 'Кубок', 'Тематический смайлик', 80, '{"emoji":"🏆"}'::jsonb, 50, 30),
    ('emoji_crown', 'emoji', 'Корона', 'Тематический смайлик', 100, '{"emoji":"👑"}'::jsonb, 30, 40),
    ('emoji_rocket', 'emoji', 'Ракета', 'Тематический смайлик', 80, '{"emoji":"🚀"}'::jsonb, 50, 50),
    ('emoji_dragon', 'emoji', 'Дракон', 'Тематический смайлик', 150, '{"emoji":"🐉"}'::jsonb, 20, 60)
ON CONFLICT (code) DO NOTHING;

-- Право на серебряную ставку (цена в серебре → бронза ×100).
INSERT INTO shop_items (code, kind, title, description, price_bronze, payload, stock_remaining, sort_order)
VALUES
    ('stake_silver_2', 'stake_unlock', 'Ставка 2 серебра', 'Право ставить 2 серебра в играх', 100, '{"stake_bronze":200,"stake_silver":2}'::jsonb, NULL, 100),
    ('stake_silver_5', 'stake_unlock', 'Ставка 5 серебра', 'Право ставить 5 серебра в играх', 200, '{"stake_bronze":500,"stake_silver":5}'::jsonb, NULL, 110),
    ('stake_silver_10', 'stake_unlock', 'Ставка 10 серебра', 'Право ставить 10 серебра в играх', 500, '{"stake_bronze":1000,"stake_silver":10}'::jsonb, NULL, 120),
    ('stake_silver_25', 'stake_unlock', 'Ставка 25 серебра', 'Право ставить 25 серебра в играх', 1000, '{"stake_bronze":2500,"stake_silver":25}'::jsonb, NULL, 130),
    ('stake_silver_50', 'stake_unlock', 'Ставка 50 серебра', 'Право ставить 50 серебра в играх', 2000, '{"stake_bronze":5000,"stake_silver":50}'::jsonb, NULL, 140),
    ('stake_silver_100', 'stake_unlock', 'Ставка 100 серебра', 'Право ставить 100 серебра в играх', 3000, '{"stake_bronze":10000,"stake_silver":100}'::jsonb, NULL, 150)
ON CONFLICT (code) DO NOTHING;

-- Рамки аватара.
INSERT INTO shop_items (code, kind, title, description, price_bronze, payload, stock_remaining, sort_order)
VALUES
    ('frame_gold', 'frame', 'Золотая рамка', 'Обводка аватара золотом', 200, '{"color":"#D4A600"}'::jsonb, NULL, 200),
    ('frame_silver', 'frame', 'Серебряная рамка', 'Обводка аватара серебром', 150, '{"color":"#A0A0A0"}'::jsonb, NULL, 210),
    ('frame_neon', 'frame', 'Неоновая рамка', 'Яркая обводка аватара', 300, '{"color":"#00E5FF"}'::jsonb, 40, 220)
ON CONFLICT (code) DO NOTHING;
