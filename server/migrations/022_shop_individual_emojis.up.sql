-- Individually purchasable animated emojis (grouped for display).
-- Packs are disabled; each emoji costs 30 bronze for 10 uses.

UPDATE shop_items
SET active = FALSE
WHERE kind = 'emoji_pack';

UPDATE shop_items
SET
  price_bronze = 30,
  description = 'Анимированный смайлик · 10 использований',
  payload = jsonb_set(COALESCE(payload, '{}'::jsonb), '{uses}', '10'::jsonb, true),
  active = TRUE
WHERE kind = 'emoji';

-- Stable sort within groups for shop UI.
UPDATE shop_items SET sort_order = 10 WHERE code = 'emoji_smile';
UPDATE shop_items SET sort_order = 20 WHERE code = 'emoji_joy';
UPDATE shop_items SET sort_order = 30 WHERE code = 'emoji_rofl';
UPDATE shop_items SET sort_order = 40 WHERE code = 'emoji_heart_eyes';
UPDATE shop_items SET sort_order = 50 WHERE code = 'emoji_partying';
UPDATE shop_items SET sort_order = 60 WHERE code = 'emoji_thumbs_up';
UPDATE shop_items SET sort_order = 70 WHERE code = 'emoji_fire';
UPDATE shop_items SET sort_order = 80 WHERE code = 'emoji_red_heart';
UPDATE shop_items SET sort_order = 90 WHERE code = 'emoji_sparkles';
UPDATE shop_items SET sort_order = 100 WHERE code = 'emoji_wink';
UPDATE shop_items SET sort_order = 110 WHERE code = 'emoji_kissing_heart';
UPDATE shop_items SET sort_order = 120 WHERE code = 'emoji_star_struck';

UPDATE shop_items SET sort_order = 210 WHERE code = 'emoji_dog';
UPDATE shop_items SET sort_order = 220 WHERE code = 'emoji_tiger';
UPDATE shop_items SET sort_order = 230 WHERE code = 'emoji_dragon';
UPDATE shop_items SET sort_order = 240 WHERE code = 'emoji_unicorn';
UPDATE shop_items SET sort_order = 250 WHERE code = 'emoji_ghost';
UPDATE shop_items SET sort_order = 260 WHERE code = 'emoji_alien';
UPDATE shop_items SET sort_order = 270 WHERE code = 'emoji_robot';
UPDATE shop_items SET sort_order = 280 WHERE code = 'emoji_smiley_cat';
UPDATE shop_items SET sort_order = 290 WHERE code = 'emoji_frog';
UPDATE shop_items SET sort_order = 300 WHERE code = 'emoji_octopus';
UPDATE shop_items SET sort_order = 310 WHERE code = 'emoji_butterfly';
UPDATE shop_items SET sort_order = 320 WHERE code = 'emoji_eagle';

UPDATE shop_items SET sort_order = 410 WHERE code = 'emoji_popcorn';
UPDATE shop_items SET sort_order = 420 WHERE code = 'emoji_pizza_cook';
UPDATE shop_items SET sort_order = 430 WHERE code = 'emoji_burrito';
UPDATE shop_items SET sort_order = 440 WHERE code = 'emoji_spaghetti';
UPDATE shop_items SET sort_order = 450 WHERE code = 'emoji_ramen';
UPDATE shop_items SET sort_order = 460 WHERE code = 'emoji_coffee';
UPDATE shop_items SET sort_order = 470 WHERE code = 'emoji_beer';
UPDATE shop_items SET sort_order = 480 WHERE code = 'emoji_champagne';
UPDATE shop_items SET sort_order = 490 WHERE code = 'emoji_wine';
UPDATE shop_items SET sort_order = 500 WHERE code = 'emoji_tropical';

UPDATE shop_items SET sort_order = 610 WHERE code = 'emoji_rocket';
UPDATE shop_items SET sort_order = 620 WHERE code = 'emoji_car';
UPDATE shop_items SET sort_order = 630 WHERE code = 'emoji_race_car';
UPDATE shop_items SET sort_order = 640 WHERE code = 'emoji_bike';
UPDATE shop_items SET sort_order = 650 WHERE code = 'emoji_sailboat';
UPDATE shop_items SET sort_order = 660 WHERE code = 'emoji_ufo';
UPDATE shop_items SET sort_order = 670 WHERE code = 'emoji_plane';
UPDATE shop_items SET sort_order = 680 WHERE code = 'emoji_coaster';
UPDATE shop_items SET sort_order = 690 WHERE code = 'emoji_ferris';
UPDATE shop_items SET sort_order = 700 WHERE code = 'emoji_taxi';

UPDATE shop_items SET sort_order = 810 WHERE code = 'emoji_party_popper';
UPDATE shop_items SET sort_order = 820 WHERE code = 'emoji_balloon';
UPDATE shop_items SET sort_order = 830 WHERE code = 'emoji_cake';
UPDATE shop_items SET sort_order = 840 WHERE code = 'emoji_gift';
UPDATE shop_items SET sort_order = 850 WHERE code = 'emoji_fireworks';
UPDATE shop_items SET sort_order = 860 WHERE code = 'emoji_trophy';
UPDATE shop_items SET sort_order = 870 WHERE code = 'emoji_gold_medal';
UPDATE shop_items SET sort_order = 880 WHERE code = 'emoji_soccer';
UPDATE shop_items SET sort_order = 890 WHERE code = 'emoji_confetti';
UPDATE shop_items SET sort_order = 900 WHERE code = 'emoji_direct_hit';
UPDATE shop_items SET sort_order = 910 WHERE code = 'emoji_collision';
UPDATE shop_items SET sort_order = 920 WHERE code = 'emoji_glowing_star';

UPDATE shop_items SET sort_order = 1010 WHERE code = 'emoji_gem';
UPDATE shop_items SET sort_order = 1020 WHERE code = 'emoji_coin';
UPDATE shop_items SET sort_order = 1030 WHERE code = 'emoji_money_wings';
UPDATE shop_items SET sort_order = 1040 WHERE code = 'emoji_bulb';
UPDATE shop_items SET sort_order = 1050 WHERE code = 'emoji_grad_cap';
UPDATE shop_items SET sort_order = 1060 WHERE code = 'emoji_ring';
UPDATE shop_items SET sort_order = 1070 WHERE code = 'emoji_battery';
UPDATE shop_items SET sort_order = 1080 WHERE code = 'emoji_pencil';
