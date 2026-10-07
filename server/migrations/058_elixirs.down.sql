DELETE FROM user_inventory WHERE item_code LIKE 'elixir_%';
DELETE FROM shop_items WHERE kind = 'elixir';

ALTER TABLE user_inventory DROP COLUMN IF EXISTS vintage_at;
ALTER TABLE user_inventory DROP COLUMN IF EXISTS condition_shift;

ALTER TABLE shop_items DROP CONSTRAINT IF EXISTS shop_items_kind_check;
ALTER TABLE shop_items ADD CONSTRAINT shop_items_kind_check
    CHECK (kind IN ('emoji', 'emoji_pack', 'stake_unlock', 'frame', 'collection'));
