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
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity >= 0),
    acquired_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, item_code)
);

CREATE INDEX IF NOT EXISTS idx_user_inventory_user
    ON user_inventory (user_id);

-- Смайлики (при покупке — 30 использований; Noto animated_emoji).
INSERT INTO shop_items (code, kind, title, description, price_bronze, payload, stock_remaining, sort_order)
VALUES
    ('emoji_smile', 'emoji', 'Улыбка', 'Анимированный смайлик', 30, '{"emoji":"😀","animated_name":"smile","uses":30}'::jsonb, NULL, 10),
    ('emoji_joy', 'emoji', 'Слёзы радости', 'Анимированный смайлик', 40, '{"emoji":"😂","animated_name":"joy","uses":30}'::jsonb, NULL, 20),
    ('emoji_rofl', 'emoji', 'ROFL', 'Анимированный смайлик', 50, '{"emoji":"🤣","animated_name":"rofl","uses":30}'::jsonb, NULL, 30),
    ('emoji_heart_eyes', 'emoji', 'Влюблённый', 'Анимированный смайлик', 50, '{"emoji":"😍","animated_name":"heartEyes","uses":30}'::jsonb, NULL, 40),
    ('emoji_partying', 'emoji', 'Вечеринка', 'Анимированный смайлик', 60, '{"emoji":"🥳","animated_name":"partyingFace","uses":30}'::jsonb, NULL, 50),
    ('emoji_thumbs_up', 'emoji', 'Лайк', 'Анимированный смайлик', 40, '{"emoji":"👍","animated_name":"thumbsUp","uses":30}'::jsonb, NULL, 60),
    ('emoji_fire', 'emoji', 'Огонь', 'Анимированный смайлик', 50, '{"emoji":"🔥","animated_name":"fire","uses":30}'::jsonb, NULL, 70),
    ('emoji_rocket', 'emoji', 'Ракета', 'Анимированный смайлик', 80, '{"emoji":"🚀","animated_name":"rocket","uses":30}'::jsonb, NULL, 80),
    ('emoji_trophy', 'emoji', 'Кубок', 'Анимированный смайлик', 100, '{"emoji":"🏆","animated_name":"trophy","uses":30}'::jsonb, NULL, 90),
    ('emoji_red_heart', 'emoji', 'Сердце', 'Анимированный смайлик', 50, '{"emoji":"❤️","animated_name":"redHeart","uses":30}'::jsonb, NULL, 100),
    ('emoji_party_popper', 'emoji', 'Хлопушка', 'Анимированный смайлик', 70, '{"emoji":"🎉","animated_name":"partyPopper","uses":30}'::jsonb, NULL, 110),
    ('emoji_sparkles', 'emoji', 'Блёстки', 'Анимированный смайлик', 40, '{"emoji":"✨","animated_name":"sparkles","uses":30}'::jsonb, NULL, 120)
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

-- Рамки аватара: бронза / серебро / золото.
INSERT INTO shop_items (code, kind, title, description, price_bronze, payload, stock_remaining, sort_order)
VALUES
    ('frame_bronze', 'frame', 'Бронзовая рамка', 'Обводка аватара бронзой', 50, '{"color":"#B87333"}'::jsonb, NULL, 200),
    ('frame_silver', 'frame', 'Серебряная рамка', 'Обводка аватара серебром', 5000, '{"color":"#A0A0A0"}'::jsonb, NULL, 210),
    ('frame_gold', 'frame', 'Золотая рамка', 'Обводка аватара золотом', 500000, '{"color":"#D4A600"}'::jsonb, NULL, 220)
ON CONFLICT (code) DO NOTHING;
