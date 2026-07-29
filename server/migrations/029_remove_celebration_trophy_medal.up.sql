-- Убрать «Золото» и «Кубок» из коллекции «Праздник».
UPDATE shop_items
SET active = FALSE
WHERE code IN ('coll_gold_medal', 'coll_trophy');
