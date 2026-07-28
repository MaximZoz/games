-- Daily income copy + unified collection descriptions.
UPDATE shop_items
SET description = 'Коллекция · витрина · подарок · продажа · +' ||
                  COALESCE(payload->>'weekly_bronze', '0') || ' бронзы/день'
WHERE kind = 'collection' AND active = TRUE;
