-- Remove selected collections from shop catalog.
UPDATE shop_items
SET active = FALSE
WHERE code IN (
  'coll_dragon',
  'coll_sparkles',
  'coll_fireworks',
  'coll_trophy',
  'coll_gold_medal',
  'coll_coaster'
);

-- Shop sells only emotion emojis.
UPDATE shop_items
SET active = FALSE
WHERE kind = 'emoji'
  AND COALESCE(payload->>'group', '') <> 'emotions';
