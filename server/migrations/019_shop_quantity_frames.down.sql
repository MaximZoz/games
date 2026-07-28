ALTER TABLE user_inventory DROP COLUMN IF EXISTS quantity;
UPDATE shop_items SET active = FALSE WHERE code = 'frame_bronze';
