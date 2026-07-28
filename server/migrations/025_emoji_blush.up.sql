-- One more emotion so catalog size is divisible by 9 (45).
INSERT INTO shop_items (code, kind, title, description, price_bronze, payload, stock_remaining, sort_order, active)
VALUES
('emoji_blush', 'emoji', 'Смущение', 'Анимированный смайлик · 10 использований', 30,
 '{"emoji":"😊","animated_name":"blush","group":"emotions","uses":10}'::jsonb, NULL, 450, TRUE)
ON CONFLICT (code) DO UPDATE SET
  kind = EXCLUDED.kind,
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  price_bronze = EXCLUDED.price_bronze,
  payload = EXCLUDED.payload,
  sort_order = EXCLUDED.sort_order,
  active = TRUE;
