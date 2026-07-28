-- Убрать американские горки из коллекции «Приключения».
UPDATE shop_items
SET active = FALSE
WHERE code = 'coll_coaster';
