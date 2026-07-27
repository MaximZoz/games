-- Персональный расход вместо глобального стока магазина.
ALTER TABLE user_inventory
    ADD COLUMN IF NOT EXISTS quantity INTEGER NOT NULL DEFAULT 1
        CHECK (quantity >= 0);

-- Убираем глобальный сток у всех товаров.
UPDATE shop_items SET stock_remaining = NULL;

-- Смайлики: при покупке выдаём 30 использований.
UPDATE shop_items
SET payload = payload || '{"uses":30}'::jsonb,
    stock_remaining = NULL
WHERE kind = 'emoji';

-- Рамки: бронза / серебро / золото.
UPDATE shop_items SET active = FALSE WHERE code = 'frame_neon';

INSERT INTO shop_items (code, kind, title, description, price_bronze, payload, stock_remaining, sort_order, active)
VALUES
    ('frame_bronze', 'frame', 'Бронзовая рамка', 'Обводка аватара бронзой', 50,
     '{"color":"#B87333"}'::jsonb, NULL, 200, TRUE),
    ('frame_silver', 'frame', 'Серебряная рамка', 'Обводка аватара серебром', 5000,
     '{"color":"#A0A0A0"}'::jsonb, NULL, 210, TRUE),
    ('frame_gold', 'frame', 'Золотая рамка', 'Обводка аватара золотом', 500000,
     '{"color":"#D4A600"}'::jsonb, NULL, 220, TRUE)
ON CONFLICT (code) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    price_bronze = EXCLUDED.price_bronze,
    payload = EXCLUDED.payload,
    stock_remaining = NULL,
    sort_order = EXCLUDED.sort_order,
    active = TRUE;
