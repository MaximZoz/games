-- Вернуть прежние цены эликсиров: 30% / 70% / 40%.

UPDATE shop_items SET price_bronze = 750 WHERE code = 'elixir_celebration_rejuvenate';
UPDATE shop_items SET price_bronze = 1750 WHERE code = 'elixir_celebration_age';
UPDATE shop_items SET price_bronze = 1000 WHERE code = 'elixir_celebration_accelerate';

UPDATE shop_items SET price_bronze = 900 WHERE code = 'elixir_legends_rejuvenate';
UPDATE shop_items SET price_bronze = 2100 WHERE code = 'elixir_legends_age';
UPDATE shop_items SET price_bronze = 1200 WHERE code = 'elixir_legends_accelerate';

UPDATE shop_items SET price_bronze = 1050 WHERE code = 'elixir_nature_rejuvenate';
UPDATE shop_items SET price_bronze = 2450 WHERE code = 'elixir_nature_age';
UPDATE shop_items SET price_bronze = 1400 WHERE code = 'elixir_nature_accelerate';

UPDATE shop_items SET price_bronze = 1500 WHERE code = 'elixir_cosmic_rejuvenate';
UPDATE shop_items SET price_bronze = 3500 WHERE code = 'elixir_cosmic_age';
UPDATE shop_items SET price_bronze = 2000 WHERE code = 'elixir_cosmic_accelerate';

UPDATE shop_items SET price_bronze = 12000 WHERE code = 'elixir_adventure_rejuvenate';
UPDATE shop_items SET price_bronze = 28000 WHERE code = 'elixir_adventure_age';
UPDATE shop_items SET price_bronze = 16000 WHERE code = 'elixir_adventure_accelerate';

UPDATE shop_items SET price_bronze = 150000 WHERE code = 'elixir_jewels_rejuvenate';
UPDATE shop_items SET price_bronze = 350000 WHERE code = 'elixir_jewels_age';
UPDATE shop_items SET price_bronze = 200000 WHERE code = 'elixir_jewels_accelerate';
