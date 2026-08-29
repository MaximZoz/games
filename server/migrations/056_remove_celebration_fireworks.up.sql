-- Убрать «Фейерверк» из коллекции «Праздник».
UPDATE shop_items
SET active = FALSE
WHERE code = 'coll_fireworks';

DELETE FROM user_inventory
WHERE item_code = 'coll_fireworks';
