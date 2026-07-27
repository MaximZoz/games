UPDATE shop_items
SET active = TRUE,
    price_bronze = 4000,
    payload = jsonb_set(payload, '{weekly_bronze}', '12'),
    description = 'Коллекция · витрина · подарок · продажа · +12 бронзы/день'
WHERE code = 'coll_gold_medal';

UPDATE shop_items
SET active = TRUE,
    price_bronze = 5000,
    payload = jsonb_set(payload, '{weekly_bronze}', '15'),
    description = 'Коллекция · витрина · подарок · продажа · +15 бронзы/день'
WHERE code = 'coll_trophy';
