UPDATE shop_items SET active = FALSE
WHERE kind = 'collection'
   OR code IN (
     'emoji_angry','emoji_cry','emoji_loudly_crying','emoji_frown','emoji_big_frown',
     'emoji_flushed','emoji_mind_blown','emoji_melting','emoji_hug_face','emoji_cool',
     'emoji_nerd','emoji_dizzy','emoji_hot_face','emoji_cold_face','emoji_broken_heart',
     'emoji_beating_heart','emoji_holding_tears','emoji_smirk','emoji_relieved','emoji_sleepy',
     'emoji_worried','emoji_pensive','emoji_unamused','emoji_grimacing','emoji_shushing',
     'emoji_upside_down','emoji_skull_emo','emoji_imp_frown','emoji_imp_smile','emoji_clown',
     'emoji_halo','emoji_eyes_emo'
   );

ALTER TABLE users DROP COLUMN IF EXISTS collection_income_claimed_at;

ALTER TABLE shop_items DROP CONSTRAINT IF EXISTS shop_items_kind_check;
ALTER TABLE shop_items ADD CONSTRAINT shop_items_kind_check
    CHECK (kind IN ('emoji', 'emoji_pack', 'stake_unlock', 'frame'));
