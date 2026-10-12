-- Эликсиры в 10 раз дешевле: 3% омоложение, 7% старение, 4% ускорение
-- от самого дорогого активного предмета набора.
-- Праздник 2500 → 75/175/100, легенды 3000 → 90/210/120,
-- природа 3500 → 105/245/140, космос 5000 → 150/350/200,
-- приключения 40000 → 1200/2800/1600, драгоценности 500000 → 15000/35000/20000.

UPDATE shop_items SET price_bronze = 75 WHERE code = 'elixir_celebration_rejuvenate';
UPDATE shop_items SET price_bronze = 175 WHERE code = 'elixir_celebration_age';
UPDATE shop_items SET price_bronze = 100 WHERE code = 'elixir_celebration_accelerate';

UPDATE shop_items SET price_bronze = 90 WHERE code = 'elixir_legends_rejuvenate';
UPDATE shop_items SET price_bronze = 210 WHERE code = 'elixir_legends_age';
UPDATE shop_items SET price_bronze = 120 WHERE code = 'elixir_legends_accelerate';

UPDATE shop_items SET price_bronze = 105 WHERE code = 'elixir_nature_rejuvenate';
UPDATE shop_items SET price_bronze = 245 WHERE code = 'elixir_nature_age';
UPDATE shop_items SET price_bronze = 140 WHERE code = 'elixir_nature_accelerate';

UPDATE shop_items SET price_bronze = 150 WHERE code = 'elixir_cosmic_rejuvenate';
UPDATE shop_items SET price_bronze = 350 WHERE code = 'elixir_cosmic_age';
UPDATE shop_items SET price_bronze = 200 WHERE code = 'elixir_cosmic_accelerate';

UPDATE shop_items SET price_bronze = 1200 WHERE code = 'elixir_adventure_rejuvenate';
UPDATE shop_items SET price_bronze = 2800 WHERE code = 'elixir_adventure_age';
UPDATE shop_items SET price_bronze = 1600 WHERE code = 'elixir_adventure_accelerate';

UPDATE shop_items SET price_bronze = 15000 WHERE code = 'elixir_jewels_rejuvenate';
UPDATE shop_items SET price_bronze = 35000 WHERE code = 'elixir_jewels_age';
UPDATE shop_items SET price_bronze = 20000 WHERE code = 'elixir_jewels_accelerate';
