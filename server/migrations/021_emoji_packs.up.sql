-- Паки тематических смайликов: покупка группы, по 10 использований на смайлик.
ALTER TABLE shop_items DROP CONSTRAINT IF EXISTS shop_items_kind_check;
ALTER TABLE shop_items ADD CONSTRAINT shop_items_kind_check
    CHECK (kind IN ('emoji', 'emoji_pack', 'stake_unlock', 'frame'));

-- Старые одиночные смайлики больше не продаём.
UPDATE shop_items SET active = FALSE WHERE kind = 'emoji';

-- Дочерние смайлики (не в витрине, нужны для inventory FK).
INSERT INTO shop_items (code, kind, title, description, price_bronze, payload, stock_remaining, sort_order, active)
VALUES
-- emotions
('emoji_smile', 'emoji', 'Улыбка', '', 0, '{"emoji":"😀","animated_name":"smile","group":"emotions"}'::jsonb, NULL, 0, FALSE),
('emoji_joy', 'emoji', 'Слёзы радости', '', 0, '{"emoji":"😂","animated_name":"joy","group":"emotions"}'::jsonb, NULL, 0, FALSE),
('emoji_rofl', 'emoji', 'ROFL', '', 0, '{"emoji":"🤣","animated_name":"rofl","group":"emotions"}'::jsonb, NULL, 0, FALSE),
('emoji_heart_eyes', 'emoji', 'Влюблённый', '', 0, '{"emoji":"😍","animated_name":"heartEyes","group":"emotions"}'::jsonb, NULL, 0, FALSE),
('emoji_partying', 'emoji', 'Вечеринка', '', 0, '{"emoji":"🥳","animated_name":"partyingFace","group":"emotions"}'::jsonb, NULL, 0, FALSE),
('emoji_thumbs_up', 'emoji', 'Лайк', '', 0, '{"emoji":"👍","animated_name":"thumbsUp","group":"emotions"}'::jsonb, NULL, 0, FALSE),
('emoji_fire', 'emoji', 'Огонь', '', 0, '{"emoji":"🔥","animated_name":"fire","group":"emotions"}'::jsonb, NULL, 0, FALSE),
('emoji_red_heart', 'emoji', 'Сердце', '', 0, '{"emoji":"❤️","animated_name":"redHeart","group":"emotions"}'::jsonb, NULL, 0, FALSE),
('emoji_sparkles', 'emoji', 'Блёстки', '', 0, '{"emoji":"✨","animated_name":"sparkles","group":"emotions"}'::jsonb, NULL, 0, FALSE),
('emoji_wink', 'emoji', 'Подмигивание', '', 0, '{"emoji":"😉","animated_name":"wink","group":"emotions"}'::jsonb, NULL, 0, FALSE),
('emoji_kissing_heart', 'emoji', 'Поцелуй', '', 0, '{"emoji":"😘","animated_name":"kissingHeart","group":"emotions"}'::jsonb, NULL, 0, FALSE),
('emoji_star_struck', 'emoji', 'Звёзды в глазах', '', 0, '{"emoji":"🤩","animated_name":"starStruck","group":"emotions"}'::jsonb, NULL, 0, FALSE),
-- animals
('emoji_dog', 'emoji', 'Собака', '', 0, '{"emoji":"🐶","animated_name":"dog","group":"animals"}'::jsonb, NULL, 0, FALSE),
('emoji_tiger', 'emoji', 'Тигр', '', 0, '{"emoji":"🐯","animated_name":"tiger","group":"animals"}'::jsonb, NULL, 0, FALSE),
('emoji_dragon', 'emoji', 'Дракон', '', 0, '{"emoji":"🐉","animated_name":"dragon","group":"animals"}'::jsonb, NULL, 0, FALSE),
('emoji_unicorn', 'emoji', 'Единорог', '', 0, '{"emoji":"🦄","animated_name":"unicorn","group":"animals"}'::jsonb, NULL, 0, FALSE),
('emoji_ghost', 'emoji', 'Привидение', '', 0, '{"emoji":"👻","animated_name":"ghost","group":"animals"}'::jsonb, NULL, 0, FALSE),
('emoji_alien', 'emoji', 'Пришелец', '', 0, '{"emoji":"👽","animated_name":"alien","group":"animals"}'::jsonb, NULL, 0, FALSE),
('emoji_robot', 'emoji', 'Робот', '', 0, '{"emoji":"🤖","animated_name":"robot","group":"animals"}'::jsonb, NULL, 0, FALSE),
('emoji_smiley_cat', 'emoji', 'Кот', '', 0, '{"emoji":"😺","animated_name":"smileyCat","group":"animals"}'::jsonb, NULL, 0, FALSE),
('emoji_frog', 'emoji', 'Лягушка', '', 0, '{"emoji":"🐸","animated_name":"frog","group":"animals"}'::jsonb, NULL, 0, FALSE),
('emoji_octopus', 'emoji', 'Осьминог', '', 0, '{"emoji":"🐙","animated_name":"octopus","group":"animals"}'::jsonb, NULL, 0, FALSE),
('emoji_butterfly', 'emoji', 'Бабочка', '', 0, '{"emoji":"🦋","animated_name":"butterfly","group":"animals"}'::jsonb, NULL, 0, FALSE),
('emoji_eagle', 'emoji', 'Орёл', '', 0, '{"emoji":"🦅","animated_name":"eagle","group":"animals"}'::jsonb, NULL, 0, FALSE),
-- food
('emoji_popcorn', 'emoji', 'Попкорн', '', 0, '{"emoji":"🍿","animated_name":"popcorn","group":"food"}'::jsonb, NULL, 0, FALSE),
('emoji_pizza_cook', 'emoji', 'Готовка', '', 0, '{"emoji":"🍳","animated_name":"cooking","group":"food"}'::jsonb, NULL, 0, FALSE),
('emoji_burrito', 'emoji', 'Буррито', '', 0, '{"emoji":"🌯","animated_name":"burrito","group":"food"}'::jsonb, NULL, 0, FALSE),
('emoji_spaghetti', 'emoji', 'Спагетти', '', 0, '{"emoji":"🍝","animated_name":"spaghetti","group":"food"}'::jsonb, NULL, 0, FALSE),
('emoji_ramen', 'emoji', 'Рамэн', '', 0, '{"emoji":"🍜","animated_name":"steamingBowl","group":"food"}'::jsonb, NULL, 0, FALSE),
('emoji_coffee', 'emoji', 'Кофе', '', 0, '{"emoji":"☕","animated_name":"hotBeverage","group":"food"}'::jsonb, NULL, 0, FALSE),
('emoji_beer', 'emoji', 'Пиво', '', 0, '{"emoji":"🍻","animated_name":"clinkingBeerMugs","group":"food"}'::jsonb, NULL, 0, FALSE),
('emoji_champagne', 'emoji', 'Шампанское', '', 0, '{"emoji":"🍾","animated_name":"bottleWithPoppingCork","group":"food"}'::jsonb, NULL, 0, FALSE),
('emoji_wine', 'emoji', 'Вино', '', 0, '{"emoji":"🍷","animated_name":"wineGlass","group":"food"}'::jsonb, NULL, 0, FALSE),
('emoji_tropical', 'emoji', 'Коктейль', '', 0, '{"emoji":"🍹","animated_name":"tropicalDrink","group":"food"}'::jsonb, NULL, 0, FALSE),
-- travel
('emoji_rocket', 'emoji', 'Ракета', '', 0, '{"emoji":"🚀","animated_name":"rocket","group":"travel"}'::jsonb, NULL, 0, FALSE),
('emoji_car', 'emoji', 'Авто', '', 0, '{"emoji":"🚗","animated_name":"automobile","group":"travel"}'::jsonb, NULL, 0, FALSE),
('emoji_race_car', 'emoji', 'Гоночная', '', 0, '{"emoji":"🏎️","animated_name":"racingCar","group":"travel"}'::jsonb, NULL, 0, FALSE),
('emoji_bike', 'emoji', 'Велосипед', '', 0, '{"emoji":"🚲","animated_name":"bicycle","group":"travel"}'::jsonb, NULL, 0, FALSE),
('emoji_sailboat', 'emoji', 'Парусник', '', 0, '{"emoji":"⛵","animated_name":"sailboat","group":"travel"}'::jsonb, NULL, 0, FALSE),
('emoji_ufo', 'emoji', 'НЛО', '', 0, '{"emoji":"🛸","animated_name":"flyingSaucer","group":"travel"}'::jsonb, NULL, 0, FALSE),
('emoji_plane', 'emoji', 'Самолёт', '', 0, '{"emoji":"🛫","animated_name":"airplaneDeparture","group":"travel"}'::jsonb, NULL, 0, FALSE),
('emoji_coaster', 'emoji', 'Американские горки', '', 0, '{"emoji":"🎢","animated_name":"rollerCoaster","group":"travel"}'::jsonb, NULL, 0, FALSE),
('emoji_ferris', 'emoji', 'Колесо обозрения', '', 0, '{"emoji":"🎡","animated_name":"ferrisWheel","group":"travel"}'::jsonb, NULL, 0, FALSE),
('emoji_taxi', 'emoji', 'Такси', '', 0, '{"emoji":"🚕","animated_name":"taxi","group":"travel"}'::jsonb, NULL, 0, FALSE),
-- party / activities
('emoji_party_popper', 'emoji', 'Хлопушка', '', 0, '{"emoji":"🎉","animated_name":"partyPopper","group":"party"}'::jsonb, NULL, 0, FALSE),
('emoji_balloon', 'emoji', 'Шарик', '', 0, '{"emoji":"🎈","animated_name":"balloon","group":"party"}'::jsonb, NULL, 0, FALSE),
('emoji_cake', 'emoji', 'Торт', '', 0, '{"emoji":"🎂","animated_name":"birthdayCake","group":"party"}'::jsonb, NULL, 0, FALSE),
('emoji_gift', 'emoji', 'Подарок', '', 0, '{"emoji":"🎁","animated_name":"wrappedGift","group":"party"}'::jsonb, NULL, 0, FALSE),
('emoji_fireworks', 'emoji', 'Фейерверк', '', 0, '{"emoji":"🎆","animated_name":"fireworks","group":"party"}'::jsonb, NULL, 0, FALSE),
('emoji_trophy', 'emoji', 'Кубок', '', 0, '{"emoji":"🏆","animated_name":"trophy","group":"party"}'::jsonb, NULL, 0, FALSE),
('emoji_gold_medal', 'emoji', 'Золото', '', 0, '{"emoji":"🥇","animated_name":"goldMedal","group":"party"}'::jsonb, NULL, 0, FALSE),
('emoji_soccer', 'emoji', 'Футбол', '', 0, '{"emoji":"⚽","animated_name":"soccerBall","group":"party"}'::jsonb, NULL, 0, FALSE),
('emoji_confetti', 'emoji', 'Конфетти', '', 0, '{"emoji":"🎊","animated_name":"confettiBall","group":"party"}'::jsonb, NULL, 0, FALSE),
('emoji_direct_hit', 'emoji', 'В яблочко', '', 0, '{"emoji":"🎯","animated_name":"directHit","group":"party"}'::jsonb, NULL, 0, FALSE),
('emoji_collision', 'emoji', 'Взрыв', '', 0, '{"emoji":"💥","animated_name":"collision","group":"party"}'::jsonb, NULL, 0, FALSE),
('emoji_glowing_star', 'emoji', 'Звезда', '', 0, '{"emoji":"🌟","animated_name":"glowingStar","group":"party"}'::jsonb, NULL, 0, FALSE),
-- objects
('emoji_gem', 'emoji', 'Алмаз', '', 0, '{"emoji":"💎","animated_name":"gemStone","group":"objects"}'::jsonb, NULL, 0, FALSE),
('emoji_coin', 'emoji', 'Монета', '', 0, '{"emoji":"🪙","animated_name":"coin","group":"objects"}'::jsonb, NULL, 0, FALSE),
('emoji_money_wings', 'emoji', 'Деньги', '', 0, '{"emoji":"💸","animated_name":"moneyWithWings","group":"objects"}'::jsonb, NULL, 0, FALSE),
('emoji_bulb', 'emoji', 'Лампочка', '', 0, '{"emoji":"💡","animated_name":"lightBulb","group":"objects"}'::jsonb, NULL, 0, FALSE),
('emoji_grad_cap', 'emoji', 'Шапочка', '', 0, '{"emoji":"🎓","animated_name":"graduationCap","group":"objects"}'::jsonb, NULL, 0, FALSE),
('emoji_ring', 'emoji', 'Кольцо', '', 0, '{"emoji":"💍","animated_name":"ring","group":"objects"}'::jsonb, NULL, 0, FALSE),
('emoji_battery', 'emoji', 'Батарея', '', 0, '{"emoji":"🔋","animated_name":"batteryFull","group":"objects"}'::jsonb, NULL, 0, FALSE),
('emoji_pencil', 'emoji', 'Карандаш', '', 0, '{"emoji":"✏️","animated_name":"pencil","group":"objects"}'::jsonb, NULL, 0, FALSE)
ON CONFLICT (code) DO UPDATE SET
    title = EXCLUDED.title,
    payload = EXCLUDED.payload,
    active = FALSE,
    price_bronze = 0,
    kind = 'emoji';

-- Паки (витрина).
INSERT INTO shop_items (code, kind, title, description, price_bronze, payload, stock_remaining, sort_order, active)
VALUES
(
  'pack_emotions', 'emoji_pack', 'Эмоции', '12 анимированных смайликов · по 10 шт.', 200,
  '{"uses_each":10,"group":"emotions","emojis":["emoji_smile","emoji_joy","emoji_rofl","emoji_heart_eyes","emoji_partying","emoji_thumbs_up","emoji_fire","emoji_red_heart","emoji_sparkles","emoji_wink","emoji_kissing_heart","emoji_star_struck"]}'::jsonb,
  NULL, 10, TRUE
),
(
  'pack_animals', 'emoji_pack', 'Животные', '12 анимированных смайликов · по 10 шт.', 250,
  '{"uses_each":10,"group":"animals","emojis":["emoji_dog","emoji_tiger","emoji_dragon","emoji_unicorn","emoji_ghost","emoji_alien","emoji_robot","emoji_smiley_cat","emoji_frog","emoji_octopus","emoji_butterfly","emoji_eagle"]}'::jsonb,
  NULL, 20, TRUE
),
(
  'pack_food', 'emoji_pack', 'Еда и напитки', '10 анимированных смайликов · по 10 шт.', 180,
  '{"uses_each":10,"group":"food","emojis":["emoji_popcorn","emoji_pizza_cook","emoji_burrito","emoji_spaghetti","emoji_ramen","emoji_coffee","emoji_beer","emoji_champagne","emoji_wine","emoji_tropical"]}'::jsonb,
  NULL, 30, TRUE
),
(
  'pack_travel', 'emoji_pack', 'Путешествия', '10 анимированных смайликов · по 10 шт.', 220,
  '{"uses_each":10,"group":"travel","emojis":["emoji_rocket","emoji_car","emoji_race_car","emoji_bike","emoji_sailboat","emoji_ufo","emoji_plane","emoji_coaster","emoji_ferris","emoji_taxi"]}'::jsonb,
  NULL, 40, TRUE
),
(
  'pack_party', 'emoji_pack', 'Праздник и спорт', '12 анимированных смайликов · по 10 шт.', 280,
  '{"uses_each":10,"group":"party","emojis":["emoji_party_popper","emoji_balloon","emoji_cake","emoji_gift","emoji_fireworks","emoji_trophy","emoji_gold_medal","emoji_soccer","emoji_confetti","emoji_direct_hit","emoji_collision","emoji_glowing_star"]}'::jsonb,
  NULL, 50, TRUE
),
(
  'pack_objects', 'emoji_pack', 'Предметы', '8 анимированных смайликов · по 10 шт.', 150,
  '{"uses_each":10,"group":"objects","emojis":["emoji_gem","emoji_coin","emoji_money_wings","emoji_bulb","emoji_grad_cap","emoji_ring","emoji_battery","emoji_pencil"]}'::jsonb,
  NULL, 60, TRUE
)
ON CONFLICT (code) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    price_bronze = EXCLUDED.price_bronze,
    payload = EXCLUDED.payload,
    kind = 'emoji_pack',
    active = TRUE,
    sort_order = EXCLUDED.sort_order,
    stock_remaining = NULL;
