-- Revert to pack-based shop: deactivate individual emojis, reactivate packs.

UPDATE shop_items
SET active = FALSE
WHERE kind = 'emoji';

UPDATE shop_items
SET active = TRUE
WHERE kind = 'emoji_pack';
