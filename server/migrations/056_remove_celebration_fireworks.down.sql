UPDATE shop_items
SET active = TRUE,
    price_bronze = 3000,
    payload = jsonb_set(payload, '{weekly_bronze}', '10'),
    description = 'Коллекция · витрина · подарок · продажа · +10 бронзы/день'
WHERE code = 'coll_fireworks';
