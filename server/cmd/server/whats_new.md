# Что нового
# Секции ## ru / ## en — сервер отдаёт по Accept-Language.
# Автоиз git log (origin/develop..HEAD). ## en можно править руками.

## ru
- Инвайт после выхода: только новое лобби, не старая партия
- Тест правил: дефолтная ставка 2, не 1
- Фикс analyze: лишний ! у view в DurakGameScreen
- Офлайн: тот же UI и анимации, что в онлайне, с ботами
- Карточки лобби/инвайтов без appear-анимации при скролле
- Фикс скролла карточек игр и локализация офлайна
- Офлайн: Дурак и крестики как в онлайне, с ботами
- WHAT_NEW: полный EN и фикс сохранения секции в скрипте
- Локализация «Что нового» в диалоге обновления
- Настройки и ставка отдельно по играм; переводы; пустое лобби
- Дурак: observation без редиректа в крестики, лобби/инвайты, иконка
- Дурак: вчетвером иконки соперников в одну линию
- Дурак/UI: observation, ставки, статистика, таймер, ничья мест
- Дурак: mid-game победа сразу + пауза только перед «Беру»
- Дурак: ложный «Время вышло» — не гонять таймаут крестиков
- Дурак: сразу «Вы победили!» после выхода в ноль
- Дурак: пауза 2с после отбоя, если нечего подкинуть
- Дурак: добор втроём — все игроки получают карты
- Дурак: первый отбой 5, ход после выхода, свой добор
- Дурак: чипы без сброса, колоды по числу игроков
- Дурак: лимит 5 в первом отбое, «Победил {логин}» и награда с анимацией
- Дурак: банк по местам — 3п 2/3+1/3, 4п 2/4+1/4+1/4
- Дурак: первый отбой — пачка до 5 карт, потом «Все»
- Дурак: банк всем победителям, не только первому
- Дурак: банк победителю, сдача→наблюдатель, подкид «Все»

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

