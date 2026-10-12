-- Режим партии в истории: вариант крестиков, колода дурака, шашки, нарды, шахматы.
-- Пустая строка — режим не задан (старые записи и игры без вариантов).
ALTER TABLE game_results
    ADD COLUMN IF NOT EXISTS game_mode TEXT NOT NULL DEFAULT '';
