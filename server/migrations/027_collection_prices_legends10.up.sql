-- Retune collection prices/income + pad legends to 10 items.

-- Reactivate items that fit the new catalog mix.
UPDATE shop_items
SET active = TRUE
WHERE code IN (
  'coll_dragon',
  'coll_sparkles',
  'coll_fireworks',
  'coll_trophy',
  'coll_gold_medal',
  'coll_coaster'
);

-- New legends (total 10 with unicorn/dragon/ghost).
INSERT INTO shop_items (code, kind, title, description, price_bronze, payload, stock_remaining, sort_order, active)
VALUES
('coll_phoenix', 'collection', 'Феникс', 'Коллекция · витрина · подарок · продажа · +10 бронзы/день', 3000,
 '{"emoji":"🐦‍🔥","animated_name":"phoenix","set":"legends","weekly_bronze":10}'::jsonb, NULL, 2030, TRUE),
('coll_owl', 'collection', 'Сова', 'Коллекция · витрина · подарок · продажа · +10 бронзы/день', 3000,
 '{"emoji":"🦉","animated_name":"owl","set":"legends","weekly_bronze":10}'::jsonb, NULL, 2040, TRUE),
('coll_snake', 'collection', 'Змея', 'Коллекция · витрина · подарок · продажа · +10 бронзы/день', 3000,
 '{"emoji":"🐍","animated_name":"snake","set":"legends","weekly_bronze":10}'::jsonb, NULL, 2050, TRUE),
('coll_scorpion', 'collection', 'Скорпион', 'Коллекция · витрина · подарок · продажа · +10 бронзы/день', 3000,
 '{"emoji":"🦂","animated_name":"scorpion","set":"legends","weekly_bronze":10}'::jsonb, NULL, 2060, TRUE),
('coll_skull', 'collection', 'Череп', 'Коллекция · витрина · подарок · продажа · +10 бронзы/день', 3000,
 '{"emoji":"💀","animated_name":"skull","set":"legends","weekly_bronze":10}'::jsonb, NULL, 2070, TRUE),
('coll_bat', 'collection', 'Летучая мышь', 'Коллекция · витрина · подарок · продажа · +10 бронзы/день', 3000,
 '{"emoji":"🦇","animated_name":"bat","set":"legends","weekly_bronze":10}'::jsonb, NULL, 2080, TRUE),
('coll_tiger', 'collection', 'Тигр', 'Коллекция · витрина · подарок · продажа · +10 бронзы/день', 3000,
 '{"emoji":"🐅","animated_name":"tiger","set":"legends","weekly_bronze":10}'::jsonb, NULL, 2090, TRUE)
ON CONFLICT (code) DO UPDATE SET
  kind = EXCLUDED.kind,
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  price_bronze = EXCLUDED.price_bronze,
  payload = EXCLUDED.payload,
  sort_order = EXCLUDED.sort_order,
  active = EXCLUDED.active;

-- Legends: 30 серебра, +10 бронзы/день.
UPDATE shop_items
SET price_bronze = 3000,
    payload = jsonb_set(
      jsonb_set(payload, '{set}', '"legends"'),
      '{weekly_bronze}', '10'
    ),
    active = TRUE
WHERE code IN (
  'coll_unicorn', 'coll_dragon', 'coll_ghost',
  'coll_phoenix', 'coll_owl', 'coll_snake', 'coll_scorpion',
  'coll_skull', 'coll_bat', 'coll_tiger'
);

-- Cosmic: 50 серебра, +10 бронзы/день.
UPDATE shop_items
SET price_bronze = 5000,
    payload = jsonb_set(payload, '{weekly_bronze}', '10'),
    active = TRUE
WHERE code IN ('coll_alien', 'coll_robot', 'coll_ufo', 'coll_rocket');

-- Jewels (gold prices; income in silver/bronze as specified).
UPDATE shop_items
SET price_bronze = 500000,
    payload = jsonb_set(payload, '{weekly_bronze}', '1000'),
    active = TRUE
WHERE code = 'coll_ring';

UPDATE shop_items
SET price_bronze = 100000,
    payload = jsonb_set(payload, '{weekly_bronze}', '100'),
    active = TRUE
WHERE code = 'coll_money_wings';

UPDATE shop_items
SET price_bronze = 30000,
    payload = jsonb_set(payload, '{weekly_bronze}', '20'),
    active = TRUE
WHERE code = 'coll_anatomical';

UPDATE shop_items
SET price_bronze = 60000,
    payload = jsonb_set(payload, '{weekly_bronze}', '40'),
    active = TRUE
WHERE code = 'coll_fire_heart';

UPDATE shop_items
SET price_bronze = 400000,
    payload = jsonb_set(payload, '{weekly_bronze}', '800'),
    active = TRUE
WHERE code = 'coll_gem';

UPDATE shop_items
SET price_bronze = 150000,
    payload = jsonb_set(payload, '{weekly_bronze}', '150'),
    active = TRUE
WHERE code = 'coll_crystal';

UPDATE shop_items
SET price_bronze = 20000,
    payload = jsonb_set(
      jsonb_set(payload, '{set}', '"jewels"'),
      '{weekly_bronze}', '15'
    ),
    active = TRUE
WHERE code = 'coll_sparkles';

-- Celebration: silver prices, proportional income.
UPDATE shop_items
SET price_bronze = 1500,
    payload = jsonb_set(payload, '{weekly_bronze}', '5'),
    active = TRUE
WHERE code = 'coll_gift';

UPDATE shop_items
SET price_bronze = 2000,
    payload = jsonb_set(payload, '{weekly_bronze}', '7'),
    active = TRUE
WHERE code = 'coll_party';

UPDATE shop_items
SET price_bronze = 2000,
    payload = jsonb_set(payload, '{weekly_bronze}', '7'),
    active = TRUE
WHERE code = 'coll_confetti';

UPDATE shop_items
SET price_bronze = 2500,
    payload = jsonb_set(payload, '{weekly_bronze}', '8'),
    active = TRUE
WHERE code = 'coll_glowing_star';

UPDATE shop_items
SET price_bronze = 3000,
    payload = jsonb_set(payload, '{weekly_bronze}', '10'),
    active = TRUE
WHERE code = 'coll_fireworks';

UPDATE shop_items
SET price_bronze = 4000,
    payload = jsonb_set(payload, '{weekly_bronze}', '12'),
    active = TRUE
WHERE code = 'coll_gold_medal';

UPDATE shop_items
SET price_bronze = 5000,
    payload = jsonb_set(payload, '{weekly_bronze}', '15'),
    active = TRUE
WHERE code = 'coll_trophy';

-- Nature: silver.
UPDATE shop_items
SET price_bronze = 2000,
    payload = jsonb_set(payload, '{weekly_bronze}', '7'),
    active = TRUE
WHERE code = 'coll_butterfly';

UPDATE shop_items
SET price_bronze = 2500,
    payload = jsonb_set(payload, '{weekly_bronze}', '8'),
    active = TRUE
WHERE code = 'coll_octopus';

UPDATE shop_items
SET price_bronze = 3500,
    payload = jsonb_set(payload, '{weekly_bronze}', '12'),
    active = TRUE
WHERE code = 'coll_eagle';

-- Adventure: gold.
UPDATE shop_items
SET price_bronze = 20000,
    payload = jsonb_set(payload, '{weekly_bronze}', '15'),
    active = TRUE
WHERE code = 'coll_sailboat';

UPDATE shop_items
SET price_bronze = 30000,
    payload = jsonb_set(payload, '{weekly_bronze}', '20'),
    active = TRUE
WHERE code = 'coll_ferris';

UPDATE shop_items
SET price_bronze = 40000,
    payload = jsonb_set(payload, '{weekly_bronze}', '28'),
    active = TRUE
WHERE code = 'coll_race_car';

UPDATE shop_items
SET price_bronze = 50000,
    payload = jsonb_set(payload, '{weekly_bronze}', '35'),
    active = TRUE
WHERE code = 'coll_coaster';

-- Human-readable descriptions with currency units.
UPDATE shop_items
SET description = 'Коллекция · витрина · подарок · продажа · +' ||
  CASE
    WHEN COALESCE((payload->>'weekly_bronze')::int, 0) >= 10000
         AND COALESCE((payload->>'weekly_bronze')::int, 0) % 10000 = 0
      THEN (COALESCE((payload->>'weekly_bronze')::int, 0) / 10000)::text || ' золота/день'
    WHEN COALESCE((payload->>'weekly_bronze')::int, 0) >= 100
         AND COALESCE((payload->>'weekly_bronze')::int, 0) % 100 = 0
      THEN (COALESCE((payload->>'weekly_bronze')::int, 0) / 100)::text || ' серебра/день'
    ELSE COALESCE(payload->>'weekly_bronze', '0') || ' бронзы/день'
  END
WHERE kind = 'collection';
