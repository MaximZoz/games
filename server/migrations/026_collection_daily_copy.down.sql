UPDATE shop_items
SET description = 'Коллекция · витрина профиля · +' ||
                  COALESCE(payload->>'weekly_bronze', '0') || ' бронзы/нед.'
WHERE kind = 'collection';
