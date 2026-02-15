-- Логин по email или по display_name: делаем display_name уникальным
ALTER TABLE users ADD CONSTRAINT users_display_name_key UNIQUE (display_name);
