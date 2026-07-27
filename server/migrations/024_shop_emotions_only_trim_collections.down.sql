UPDATE shop_items
SET active = TRUE
WHERE code IN (
  'coll_dragon',
  'coll_sparkles',
  'coll_fireworks',
  'coll_trophy',
  'coll_gold_medal',
  'coll_coaster'
);

UPDATE shop_items
SET active = TRUE
WHERE kind = 'emoji'
  AND COALESCE(payload->>'group', '') <> 'emotions'
  AND code LIKE 'emoji_%';
