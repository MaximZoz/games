-- Убрать ставку 100 серебра; добавить золотые ставки 2/5/10/25/50
-- по аналогии с серебром (цена: 1/2/5/10/20 золота).

UPDATE shop_items
SET active = FALSE
WHERE code = 'stake_silver_100';

INSERT INTO shop_items (code, kind, title, description, price_bronze, payload, stock_remaining, sort_order, active)
VALUES
('stake_gold_2', 'stake_unlock', 'Ставка 2 золота', 'Право ставить 2 золота в играх', 10000,
 '{"stake_bronze":20000,"stake_gold":2}'::jsonb, NULL, 200, TRUE),
('stake_gold_5', 'stake_unlock', 'Ставка 5 золота', 'Право ставить 5 золота в играх', 20000,
 '{"stake_bronze":50000,"stake_gold":5}'::jsonb, NULL, 210, TRUE),
('stake_gold_10', 'stake_unlock', 'Ставка 10 золота', 'Право ставить 10 золота в играх', 50000,
 '{"stake_bronze":100000,"stake_gold":10}'::jsonb, NULL, 220, TRUE),
('stake_gold_25', 'stake_unlock', 'Ставка 25 золота', 'Право ставить 25 золота в играх', 100000,
 '{"stake_bronze":250000,"stake_gold":25}'::jsonb, NULL, 230, TRUE),
('stake_gold_50', 'stake_unlock', 'Ставка 50 золота', 'Право ставить 50 золота в играх', 200000,
 '{"stake_bronze":500000,"stake_gold":50}'::jsonb, NULL, 240, TRUE)
ON CONFLICT (code) DO UPDATE SET
  kind = EXCLUDED.kind,
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  price_bronze = EXCLUDED.price_bronze,
  payload = EXCLUDED.payload,
  sort_order = EXCLUDED.sort_order,
  active = TRUE;
