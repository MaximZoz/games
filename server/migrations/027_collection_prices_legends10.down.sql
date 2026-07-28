-- Revert collection price retune / legends padding.

UPDATE shop_items
SET active = FALSE
WHERE code IN (
  'coll_phoenix', 'coll_owl', 'coll_snake', 'coll_scorpion',
  'coll_skull', 'coll_bat', 'coll_tiger',
  'coll_dragon', 'coll_sparkles', 'coll_fireworks',
  'coll_trophy', 'coll_gold_medal', 'coll_coaster'
);

-- Restore prior approximate prices from 023 for remaining active collections.
UPDATE shop_items SET price_bronze = 400, payload = jsonb_set(payload, '{weekly_bronze}', '12') WHERE code = 'coll_unicorn';
UPDATE shop_items SET price_bronze = 320, payload = jsonb_set(payload, '{weekly_bronze}', '10') WHERE code = 'coll_ghost';
UPDATE shop_items SET price_bronze = 320, payload = jsonb_set(payload, '{weekly_bronze}', '10') WHERE code = 'coll_alien';
UPDATE shop_items SET price_bronze = 300, payload = jsonb_set(payload, '{weekly_bronze}', '10') WHERE code = 'coll_robot';
UPDATE shop_items SET price_bronze = 380, payload = jsonb_set(payload, '{weekly_bronze}', '12') WHERE code = 'coll_ufo';
UPDATE shop_items SET price_bronze = 360, payload = jsonb_set(payload, '{weekly_bronze}', '12') WHERE code = 'coll_rocket';
UPDATE shop_items SET price_bronze = 450, payload = jsonb_set(payload, '{weekly_bronze}', '14') WHERE code = 'coll_crystal';
UPDATE shop_items SET price_bronze = 520, payload = jsonb_set(payload, '{weekly_bronze}', '16') WHERE code = 'coll_gem';
UPDATE shop_items SET price_bronze = 340, payload = jsonb_set(payload, '{weekly_bronze}', '11') WHERE code = 'coll_ring';
UPDATE shop_items SET price_bronze = 420, payload = jsonb_set(payload, '{weekly_bronze}', '13') WHERE code = 'coll_fire_heart';
UPDATE shop_items SET price_bronze = 400, payload = jsonb_set(payload, '{weekly_bronze}', '12') WHERE code = 'coll_anatomical';
UPDATE shop_items SET price_bronze = 380, payload = jsonb_set(payload, '{weekly_bronze}', '12') WHERE code = 'coll_money_wings';
UPDATE shop_items SET price_bronze = 280, payload = jsonb_set(payload, '{weekly_bronze}', '9') WHERE code = 'coll_party';
UPDATE shop_items SET price_bronze = 280, payload = jsonb_set(payload, '{weekly_bronze}', '9') WHERE code = 'coll_confetti';
UPDATE shop_items SET price_bronze = 300, payload = jsonb_set(payload, '{weekly_bronze}', '10') WHERE code = 'coll_glowing_star';
UPDATE shop_items SET price_bronze = 250, payload = jsonb_set(payload, '{weekly_bronze}', '8') WHERE code = 'coll_gift';
UPDATE shop_items SET price_bronze = 260, payload = jsonb_set(payload, '{weekly_bronze}', '9') WHERE code = 'coll_butterfly';
UPDATE shop_items SET price_bronze = 340, payload = jsonb_set(payload, '{weekly_bronze}', '11') WHERE code = 'coll_eagle';
UPDATE shop_items SET price_bronze = 300, payload = jsonb_set(payload, '{weekly_bronze}', '10') WHERE code = 'coll_octopus';
UPDATE shop_items SET price_bronze = 330, payload = jsonb_set(payload, '{weekly_bronze}', '10') WHERE code = 'coll_ferris';
UPDATE shop_items SET price_bronze = 310, payload = jsonb_set(payload, '{weekly_bronze}', '10') WHERE code = 'coll_sailboat';
UPDATE shop_items SET price_bronze = 340, payload = jsonb_set(payload, '{weekly_bronze}', '11') WHERE code = 'coll_race_car';

UPDATE shop_items
SET description = 'Коллекция · витрина · подарок · продажа · +' ||
                  COALESCE(payload->>'weekly_bronze', '0') || ' бронзы/день'
WHERE kind = 'collection' AND active = TRUE;
