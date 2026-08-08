# Что нового
# Секции ## ru / ## en — сервер отдаёт по Accept-Language.
# Автоиз git log (origin/develop..HEAD). ## en можно править руками.

## ru
- i18n: переводы правил Дурака во всех локалях
- Дурак: колода и бита больше не прыгают при таймере/доборе
- Дурак: «Соперник сдался» только в реальном 1×1
- Лобби: название игры на карточке (l10n)
- Дурак: «Беру»/«Бито» снова обычным текстом без сдвига
- Чат: клавиатура без моргания, стиль композера как был
- Чат: отправка без моргания клавиатуры на iPhone
- UI: карточки монет/магазина по центру сверху
- Каркас игр: реестр + фикс клавиатуры чата на iPhone
- Чат: крупнее композер, клавиатура не прячется при отправке
- UI: монеты/магазин — список сверху слева, не по центру
- Дурак: при 2-м месте не показывать «Время вышло»
- Дурак: «Беру»/«Бито» в слоте кнопки действия, без прыжка вёрстки
- Тест правил Ultimate: ожидания под локализованный текст
- Дурак: фиксированный блок соперника — без прыжков от рамки хода
- i18n: переводы Дурака/режимов во все локали и хардкод UI
- Дурак: observation не в крестики; награды 1/2 места после сдачи
- Инвайт после выхода: только новое лобби, не старая партия
- Тест правил: дефолтная ставка 2, не 1
- Фикс analyze: лишний ! у view в DurakGameScreen
- Офлайн: тот же UI и анимации, что в онлайне, с ботами
- Карточки лобби/инвайтов без appear-анимации при скролле
- Фикс скролла карточек игр и локализация офлайна
- Офлайн: Дурак и крестики как в онлайне, с ботами
- WHAT_NEW: полный EN и фикс сохранения секции в скрипте

## en
- After leaving, invites go to a new lobby only — not the opponent’s old game
- Offline: same UI/animations as online — Durak and tic-tac-toe, all modes
- Localized “What’s new” in the update dialog
- Per-game settings and stakes; translations; empty lobby
- Durak: spectating no longer opens tic-tac-toe; lobby/invites; icon
- Durak: four-player opponent icons in one row
- Durak/UI: spectating, stakes, stats, timer, tied placements
- Durak: mid-game win right away + pause only before “Take”
- Durak: false “Time’s up” — don’t run tic-tac-toe timeouts
- Durak: show “You won!” immediately after going out
- Durak: 2s pause after a beat when there’s nothing to throw in
- Durak: three-player draw — every player gets cards
- Durak: first beat limit 5, turn after going out, own draw
- Durak: chips keep state; decks match player count
- Durak: first-beat limit 5, “{login} won” and animated reward
- Durak: pot by place — 3p 2/3+1/3, 4p 2/4+1/4+1/4
- Durak: first beat — up to 5 cards, then “All”
- Durak: pot shared among all winners, not only first
- Durak: pot to winner, forfeit→spectator, throw-in “All”
- Durak: “Took” after take and auto-beat when nothing to add
- Durak: discard animation only after a real beat
- Durak: clockwise seating for all spectators
- Durak: remove extra null check on forfeit overlay
- Durak: close button aligned with rules; forfeit under them
- Durak 3–4: clockwise throw-in order and clear turn
- Durak 3–4: avatars, neighbor throw-in, shared pot like tic-tac-toe
- Durak: transfer slot aligned with the table card

