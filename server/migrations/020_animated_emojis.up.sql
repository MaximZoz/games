-- Популярные анимированные смайлики (Noto / animated_emoji).
UPDATE shop_items SET active = FALSE WHERE kind = 'emoji';

INSERT INTO shop_items (code, kind, title, description, price_bronze, payload, stock_remaining, sort_order, active)
VALUES
    ('emoji_smile', 'emoji', 'Улыбка', 'Анимированный смайлик', 30,
     '{"emoji":"😀","animated_name":"smile","uses":30}'::jsonb, NULL, 10, TRUE),
    ('emoji_joy', 'emoji', 'Слёзы радости', 'Анимированный смайлик', 40,
     '{"emoji":"😂","animated_name":"joy","uses":30}'::jsonb, NULL, 20, TRUE),
    ('emoji_rofl', 'emoji', 'ROFL', 'Анимированный смайлик', 50,
     '{"emoji":"🤣","animated_name":"rofl","uses":30}'::jsonb, NULL, 30, TRUE),
    ('emoji_heart_eyes', 'emoji', 'Влюблённый', 'Анимированный смайлик', 50,
     '{"emoji":"😍","animated_name":"heartEyes","uses":30}'::jsonb, NULL, 40, TRUE),
    ('emoji_partying', 'emoji', 'Вечеринка', 'Анимированный смайлик', 60,
     '{"emoji":"🥳","animated_name":"partyingFace","uses":30}'::jsonb, NULL, 50, TRUE),
    ('emoji_thumbs_up', 'emoji', 'Лайк', 'Анимированный смайлик', 40,
     '{"emoji":"👍","animated_name":"thumbsUp","uses":30}'::jsonb, NULL, 60, TRUE),
    ('emoji_fire', 'emoji', 'Огонь', 'Анимированный смайлик', 50,
     '{"emoji":"🔥","animated_name":"fire","uses":30}'::jsonb, NULL, 70, TRUE),
    ('emoji_rocket', 'emoji', 'Ракета', 'Анимированный смайлик', 80,
     '{"emoji":"🚀","animated_name":"rocket","uses":30}'::jsonb, NULL, 80, TRUE),
    ('emoji_trophy', 'emoji', 'Кубок', 'Анимированный смайлик', 100,
     '{"emoji":"🏆","animated_name":"trophy","uses":30}'::jsonb, NULL, 90, TRUE),
    ('emoji_red_heart', 'emoji', 'Сердце', 'Анимированный смайлик', 50,
     '{"emoji":"❤️","animated_name":"redHeart","uses":30}'::jsonb, NULL, 100, TRUE),
    ('emoji_party_popper', 'emoji', 'Хлопушка', 'Анимированный смайлик', 70,
     '{"emoji":"🎉","animated_name":"partyPopper","uses":30}'::jsonb, NULL, 110, TRUE),
    ('emoji_sparkles', 'emoji', 'Блёстки', 'Анимированный смайлик', 40,
     '{"emoji":"✨","animated_name":"sparkles","uses":30}'::jsonb, NULL, 120, TRUE)
ON CONFLICT (code) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    price_bronze = EXCLUDED.price_bronze,
    payload = EXCLUDED.payload,
    stock_remaining = NULL,
    sort_order = EXCLUDED.sort_order,
    active = TRUE;
