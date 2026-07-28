UPDATE shop_items SET active = FALSE
WHERE code IN (
  'emoji_smile','emoji_joy','emoji_rofl','emoji_heart_eyes','emoji_partying',
  'emoji_thumbs_up','emoji_fire','emoji_rocket','emoji_trophy','emoji_red_heart',
  'emoji_party_popper','emoji_sparkles'
);
