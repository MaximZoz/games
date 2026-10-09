-- Эликсиры коллекций: три эффекта, по флакону на каждый набор.

ALTER TABLE shop_items DROP CONSTRAINT IF EXISTS shop_items_kind_check;
ALTER TABLE shop_items ADD CONSTRAINT shop_items_kind_check
    CHECK (kind IN ('emoji', 'emoji_pack', 'stake_unlock', 'frame', 'collection', 'elixir'));

ALTER TABLE user_inventory
    ADD COLUMN IF NOT EXISTS condition_shift SMALLINT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS vintage_at TIMESTAMPTZ;

-- Цена — 30/70/40% от самого дорогого активного предмета набора.
-- Праздник 2500, легенды 3000, природа 3500, космос 5000,
-- приключения 40000, драгоценности 500000.
INSERT INTO shop_items (code, kind, title, description, price_bronze, payload, stock_remaining, sort_order, active)
VALUES
    ('elixir_celebration_rejuvenate', 'elixir', 'Праздничный эликсир омоложения', '', 750,
     '{"effect":"rejuvenate","set":"celebration"}'::jsonb, NULL, 4110, TRUE),
    ('elixir_legends_rejuvenate', 'elixir', 'Легендарный эликсир омоложения', '', 900,
     '{"effect":"rejuvenate","set":"legends"}'::jsonb, NULL, 4120, TRUE),
    ('elixir_nature_rejuvenate', 'elixir', 'Природный эликсир омоложения', '', 1050,
     '{"effect":"rejuvenate","set":"nature"}'::jsonb, NULL, 4130, TRUE),
    ('elixir_cosmic_rejuvenate', 'elixir', 'Космический эликсир омоложения', '', 1500,
     '{"effect":"rejuvenate","set":"cosmic"}'::jsonb, NULL, 4140, TRUE),
    ('elixir_adventure_rejuvenate', 'elixir', 'Приключенческий эликсир омоложения', '', 12000,
     '{"effect":"rejuvenate","set":"adventure"}'::jsonb, NULL, 4150, TRUE),
    ('elixir_jewels_rejuvenate', 'elixir', 'Драгоценный эликсир омоложения', '', 150000,
     '{"effect":"rejuvenate","set":"jewels"}'::jsonb, NULL, 4160, TRUE),

    ('elixir_celebration_age', 'elixir', 'Праздничный эликсир старения', '', 1750,
     '{"effect":"age","set":"celebration"}'::jsonb, NULL, 4210, TRUE),
    ('elixir_legends_age', 'elixir', 'Легендарный эликсир старения', '', 2100,
     '{"effect":"age","set":"legends"}'::jsonb, NULL, 4220, TRUE),
    ('elixir_nature_age', 'elixir', 'Природный эликсир старения', '', 2450,
     '{"effect":"age","set":"nature"}'::jsonb, NULL, 4230, TRUE),
    ('elixir_cosmic_age', 'elixir', 'Космический эликсир старения', '', 3500,
     '{"effect":"age","set":"cosmic"}'::jsonb, NULL, 4240, TRUE),
    ('elixir_adventure_age', 'elixir', 'Приключенческий эликсир старения', '', 28000,
     '{"effect":"age","set":"adventure"}'::jsonb, NULL, 4250, TRUE),
    ('elixir_jewels_age', 'elixir', 'Драгоценный эликсир старения', '', 350000,
     '{"effect":"age","set":"jewels"}'::jsonb, NULL, 4260, TRUE),

    ('elixir_celebration_accelerate', 'elixir', 'Праздничный эликсир ускорения', '', 1000,
     '{"effect":"accelerate","set":"celebration"}'::jsonb, NULL, 4310, TRUE),
    ('elixir_legends_accelerate', 'elixir', 'Легендарный эликсир ускорения', '', 1200,
     '{"effect":"accelerate","set":"legends"}'::jsonb, NULL, 4320, TRUE),
    ('elixir_nature_accelerate', 'elixir', 'Природный эликсир ускорения', '', 1400,
     '{"effect":"accelerate","set":"nature"}'::jsonb, NULL, 4330, TRUE),
    ('elixir_cosmic_accelerate', 'elixir', 'Космический эликсир ускорения', '', 2000,
     '{"effect":"accelerate","set":"cosmic"}'::jsonb, NULL, 4340, TRUE),
    ('elixir_adventure_accelerate', 'elixir', 'Приключенческий эликсир ускорения', '', 16000,
     '{"effect":"accelerate","set":"adventure"}'::jsonb, NULL, 4350, TRUE),
    ('elixir_jewels_accelerate', 'elixir', 'Драгоценный эликсир ускорения', '', 200000,
     '{"effect":"accelerate","set":"jewels"}'::jsonb, NULL, 4360, TRUE)
ON CONFLICT (code) DO UPDATE
SET kind = EXCLUDED.kind,
    title = EXCLUDED.title,
    price_bronze = EXCLUDED.price_bronze,
    payload = EXCLUDED.payload,
    sort_order = EXCLUDED.sort_order,
    active = EXCLUDED.active;
