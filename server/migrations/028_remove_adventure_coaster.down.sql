UPDATE shop_items
SET active = TRUE,
    price_bronze = 50000,
    payload = jsonb_set(payload, '{weekly_bronze}', '35'),
    description = 'Коллекция · витрина · подарок · продажа · +35 бронзы/день'
WHERE code = 'coll_coaster';
