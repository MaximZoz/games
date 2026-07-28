UPDATE shop_items SET active = FALSE WHERE code LIKE 'stake_gold_%';

UPDATE shop_items
SET active = TRUE
WHERE code = 'stake_silver_100';
