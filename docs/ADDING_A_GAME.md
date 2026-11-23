# Как добавить новую игру

Цель: написать **только игру** (движок + экран партии + карточка режимов),
подключить её в реестр — и получить лобби, поиск, инвайты (в т.ч. по ссылке),
флажок сдачи, ничью (1×1), крестик выхода, таймер хода, ставки, статистику,
наблюдение, пуш «ваш ход», WS-навигацию.

## Уже общее (не копировать)

| Слой | Что |
|------|-----|
| Клиент UI | `GameLobbyWaitingLayout`, `LobbyMultiPlayersCard`, `handleGameScreenClose`, `GameRematchSection`, `GameStatusWithReward`, `GameCardShell`, `GameObservationCard` |
| Клиент хром партии | `GameScreenScaffold` + `GameChrome` (шапка, таймер своего хода перед правилами, столбик «сдаться / ничья»), `GameOpponentPanel` (карточка соперника: профиль, чат, друзья, рамка-таймер его хода), `forgetGameSession` (выход в каталог) — `client/lib/games/framework/` |
| Клиент UI-библиотека | пакет `client/packages/multigames_ui`: токены темы, адаптив, примитивы |
| Клиент игровой кит | пакет `client/packages/multigames_game_kit`: `GamePalette`, `GameMotion`, `GameFlightController` / `GameFlightStage`, `GameHandStrip`, `scatterSlots`, `GameTableSurface` |
| Клиент навигация | `GameRegistry` → пути лобби/партии/оффлайн; `active_game_guard`, `LobbyGameNavigationWatcher` |
| Клиент сессия | `GameSessionApi` (leave/forfeit/draw/resolve type) |
| Клиент настройки | `userGameSettingsProvider(gameType)` + `gameCardSettings(...)` / `GameCardStakeHelper` — кеш + БД |
| Клиент ставки | `game_stake.dart` (банк, места, clamp по балансу) |
| Сервер лобби | `LeaveLobby`, invite/decline/cancel, `GetLobby`, Redis `lobby:*` + `game_type` |
| Сервер итог | observation (`moveActiveToObserving`), WS `game_started` / `game_state`, stats API |
| Сервер ход | `notifyYourTurnUser(gameID, userID, gameType)` — пуш при смене хода |
| Ставки/статы | `/api/games/settings`, `/api/games/stats`, `store.RecordGameResult` |

## Шаги (клиент)

1. Пакет `client/lib/games/<id>/` — движок, repository, providers, rules.
2. Экраны `*_lobby_screen.dart`, `*_game_screen.dart` (+ offline при необходимости).
   - Лобби: собрать на `GameLobbyWaitingLayout`.
   - Шапка: `GameLobbyAppBarTitle` + `lobbyAppBarTitle` — везде «Своя игра» /
     «Лобби», не название игры.
   - Партия: экран — `GameScreenScaffold(chrome: GameChrome(...), body: ...)`.
     Свой `Scaffold` / `AppBar`, таймер хода, флаг и ничью не верстать: игра
     только описывает их в `GameChrome` (`onClose`, `onShowRules`, `turn`,
     `onSurrender`, `draw`), а каркас ставит всё на общие места — таймер
     своего хода перед кнопкой правил, под ней столбик «сдаться / ничья».

     ```dart
     GameScreenScaffold(
       chrome: GameChrome(
         onClose: _onClose,
         title: Text(context.l10n.gamesDurak), // название своей игры
         onShowRules: _showRules,
         turn: GameTurnClock(
           isMyTurn: game.isMyTurn,
           deadline: game.turnDeadline,
           turnTimeSec: game.turnTimeSec,
           onExpired: _onTurnExpired,
         ),
         onSurrender: game.isOver ? null : _confirmSurrender,
         draw: canDraw ? GameDrawOffer(onPressed: _offerDraw) : null,
       ),
       body: MyGameTable(game: game),
     )
     ```
   - Соперник 1×1 — `GameOpponentPanel(opponent: GameOpponent(...), gameType,
     gameId, isTheirTurn, turnDeadline, turnTimeSec)`: профиль по аватару, чат,
     заявка в друзья и рамка-таймер его хода подключаются сами. За столом на
     3+ игроков — тот же виджет с `layout: GameOpponentLayout.seat`.
     Ширину столбика действий отдаёт `GameChromeScope.railInsetOf(context)`.
   - Выход крестиком в каталог — `forgetGameSession(ref, gameId: ...)`, иначе
     вкладка «Игры» вернёт на сыгранный стол.
   - Цвета стола и фишек — из `GamePalette`, длительности — из `GameMotion`;
     своих литералов цвета и «сукна» игра не заводит.
   - Движение фишек — `GameFlightStage` + `GameFlightController`: полёт
     запускается при смене состояния партии (`didUpdateWidget`), место посадки
     уточняет `GameFlight.toResolver`. Рука — `GameHandStrip`, прикуп россыпью —
     `scatterSlots`, поверхность стола — `GameTableSurface`. Пример —
     `client/lib/games/domino/domino_table.dart`.
   - Экран партии оборачивать в `SwipeBackScope.gameBoard`, не в обычный
     `SwipeBackScope`. Непрозрачная полоса 48px у левого края перехватывает
     тап по крайней левой кости, карте или клетке. Если рука вдоль низа —
     передать `bottomInset` (как в дураке и Уно, около 42% высоты).
   - Выбывание multi: `enterGameObservation(ref, gameId, gameType: id)`.
3. `GameDescriptor` в `client/lib/games/framework/<id>_game.dart`
   (`id`, `localizedName`, `visibleModeLabel`, экраны).
   - `localizedName` — тот же `.arb`-ключ, что на карточке игры. Статистика,
     список лобби, инвайты и чат берут имя через `localizedGameTypeName`.
   - `visibleModeLabel` — чип режима на карточке лобби. По умолчанию пусто:
     не подставлять «Классика». Переопределять, только если у игры есть
     реальные пользовательские режимы (как короткие/длинные нарды).
4. Зарегистрировать в `GameRegistry` (`_builtinGames` в `game_registry.dart`).
   Имя и режим подхватятся везде, где уже стоит `localizedGameTypeName` /
   `localizedGameModeLabel`.
5. Карточку на «Игры»:
   - hydrate из `userGameSettingsProvider('<id>')`;
   - persist через `gameCardSettings(gameType: '<id>', …)` + `updateLocal`;
   - ставки — `GameCardStakeHelper.availableStakes` / `clampOrKeep`.
6. В `GameSessionApi` — ветки leave/forfeit/draw (или общий HTTP-контракт).
7. В лобби «Своя игра» передать `LobbyShareLinkCard` с `gameType: id` —
   парсер ссылок (`parseInviteLobbyShareUrl`) уже смотрит в `GameRegistry`.

Роутер **уже** строится из реестра (`_gameRoutesFromRegistry`).
Карточка «Наблюдение» уже на вкладке **Лобби** (`GameObservationCard`).

## Шаги (сервер)

1. Движок: `server/internal/<id>/` (как `durak` / `gameengine`).
2. Модуль `server/internal/gameregistry/<id>.go` — `ID`, `Modes`,
   `SupportsOffline`, `SupportsDrawOffer`, `DefaultSettings`.
3. `Registry.Register` в `gameregistry.Default()`.
4. HTTP: handlers Create/Join/Move/Forfeit/Timeout (пока рядом с
   `api/games.go` / отдельный файл; маршрутизация по `/api/games/<id>/…`).
5. В Redis всегда писать `"game_type", "<id>"` на lobby и game.
6. После хода человека/бота/таймаута: `h.notifyYourTurnUser(gameID, nextUserID, "<id>")`.
7. Возврат на вкладку «Игры» (GetActive) не должен попадать в ветку крестиков.
   Игра с `player_ids` и `turn_actor_idx` подхватывается сама: `game_type` из Redis
   сохраняется. Если ход или выбывание сложнее списка мест — в `init()` вызвать
   `RegisterActiveReturn(id, fn)`. Таймаут крестиков к чужому `game_type` не применяется.
   На клиенте экран партии вызывает `pinBlockingGame(ref, gameId, gameType: id)`:
   возврат с «Сообщений» берёт тип из пина и пути реестра (`/games/<id>/game/...`),
   а не из дефолта `tictactoe`.
8. Выбывание multi: `moveActiveToObserving` + observation в GetActive.
   В `ActiveReturn` для выбывшего вернуть `Observe: true`, не `Play`.
9. Финиш: монеты + `store.RecordGameResult` с нужным `GameType`.
10. Settings: ветка в `normalizeGameSettings` / `gameSettingsToJSON`.

## Контракт партии (минимум)

- Участник / выбыл / ход мой — чтобы работали крестик и флажки.
- Таймаут хода (или `turn_time_sec=0`).
- Forfeit; draw только если `SupportsDrawOffer(n)`.
- JSON view для клиента + broadcast `game_state`.

## Чего не обобщать

Движок, payload хода, стол/поле, оффлайн-бот, формулы выплат мест —
остаются в пакете игры.

## Проверка

```bash
cd server && go test ./internal/gameregistry/... ./internal/api/ -count=1
cd client && flutter test test/game_registry_test.dart test/game_stake_test.dart \
  test/game_chrome_test.dart test/game_kit_test.dart
```
