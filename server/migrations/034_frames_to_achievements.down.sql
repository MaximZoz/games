ALTER TABLE user_stats
    DROP COLUMN IF EXISTS wins_bronze,
    DROP COLUMN IF EXISTS wins_silver,
    DROP COLUMN IF EXISTS wins_gold;

UPDATE shop_items
SET active = TRUE,
    description = CASE code
        WHEN 'frame_bronze' THEN 'Обводка аватара бронзой'
        WHEN 'frame_silver' THEN 'Обводка аватара серебром'
        WHEN 'frame_gold' THEN 'Обводка аватара золотом'
        ELSE description
    END,
    payload = CASE code
        WHEN 'frame_bronze' THEN '{"color":"#B87333"}'::jsonb
        WHEN 'frame_silver' THEN '{"color":"#A0A0A0"}'::jsonb
        WHEN 'frame_gold' THEN '{"color":"#D4A600"}'::jsonb
        ELSE payload
    END
WHERE code IN ('frame_bronze', 'frame_silver', 'frame_gold');
