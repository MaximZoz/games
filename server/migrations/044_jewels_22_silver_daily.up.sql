-- Драгоценности: суммарный доход 22 серебра/день (2200 бронзы).
UPDATE shop_items
SET payload = jsonb_set(payload, '{weekly_bronze}', '1000')
WHERE code = 'coll_ring';

UPDATE shop_items
SET payload = jsonb_set(payload, '{weekly_bronze}', '800')
WHERE code = 'coll_gem';

UPDATE shop_items
SET payload = jsonb_set(payload, '{weekly_bronze}', '200')
WHERE code = 'coll_crystal';

UPDATE shop_items
SET payload = jsonb_set(payload, '{weekly_bronze}', '100')
WHERE code = 'coll_money_wings';

UPDATE shop_items
SET payload = jsonb_set(payload, '{weekly_bronze}', '50')
WHERE code = 'coll_fire_heart';

UPDATE shop_items
SET payload = jsonb_set(payload, '{weekly_bronze}', '25')
WHERE code = 'coll_anatomical';

UPDATE shop_items
SET payload = jsonb_set(payload, '{weekly_bronze}', '25')
WHERE code = 'coll_sparkles';

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
WHERE kind = 'collection'
  AND code IN (
    'coll_ring',
    'coll_gem',
    'coll_crystal',
    'coll_money_wings',
    'coll_fire_heart',
    'coll_anatomical',
    'coll_sparkles'
  );
