-- По умолчанию статистика видна другим (новые пользователи).
ALTER TABLE users
    ALTER COLUMN show_stats_to_others SET DEFAULT true;
