-- Рамки больше не продаются в магазине: открываются достижениями за победы.
UPDATE shop_items
SET active = FALSE,
    description = CASE code
        WHEN 'frame_bronze' THEN 'За 10 побед на бронзовых ставках'
        WHEN 'frame_silver' THEN 'За 10 побед на серебряных ставках'
        WHEN 'frame_gold' THEN 'За 10 побед на золотых ставках'
        ELSE description
    END,
    payload = CASE code
        WHEN 'frame_bronze' THEN '{"color":"#CD7F32","tier":"bronze"}'::jsonb
        WHEN 'frame_silver' THEN '{"color":"#C0C0C0","tier":"silver"}'::jsonb
        WHEN 'frame_gold' THEN '{"color":"#FFD700","tier":"gold"}'::jsonb
        ELSE payload
    END
WHERE code IN ('frame_bronze', 'frame_silver', 'frame_gold');

-- Победы по лигам ставок (бронза / серебро / золото).
ALTER TABLE user_stats
    ADD COLUMN IF NOT EXISTS wins_bronze INTEGER NOT NULL DEFAULT 0
        CHECK (wins_bronze >= 0),
    ADD COLUMN IF NOT EXISTS wins_silver INTEGER NOT NULL DEFAULT 0
        CHECK (wins_silver >= 0),
    ADD COLUMN IF NOT EXISTS wins_gold INTEGER NOT NULL DEFAULT 0
        CHECK (wins_gold >= 0);
