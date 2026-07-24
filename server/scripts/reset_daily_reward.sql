-- Сброс ежедневной награды, чтобы можно было забрать её снова «сегодня».
-- Подставьте свой email или display_name в условие WHERE.

UPDATE users
SET daily_reward_claimed_at = NULL
WHERE display_name = 'player1';
-- WHERE email = 'your@email.com';  -- альтернатива по email
