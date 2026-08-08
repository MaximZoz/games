# Как добавить новую игру

Цель: написать **только игру** (движок + экран партии + карточка режимов),
подключить её в реестр — и получить лобби, поиск, инвайты, флажок сдачи,
ничью (1×1), крестик выхода, таймер хода, ставки, статистику, WS-навигацию.

## Уже общее (не копировать)

| Слой | Что |
|------|-----|
| Клиент UI | `GameLobbyWaitingLayout`, `LobbyMultiPlayersCard`, `GameActionsOverlay` (флаг/ничья), `handleGameScreenClose`, таймеры хода, `GameRematchSection`, `GameStatusWithReward`, `GameCardShell` |
| Клиент навигация | `GameRegistry` → пути лобби/партии/оффлайн; `active_game_guard`, `LobbyGameNavigationWatcher` |
| Клиент сессия | `GameSessionApi` (leave/forfeit/draw/resolve type) |
| Сервер лобби | `LeaveLobby`, invite/decline/cancel, `GetLobby`, Redis `lobby:*` + `game_type` |
| Сервер итог | observation (`moveActiveToObserving`), WS `game_started` / `game_state`, stats API |
| Ставки/статы | `game_stake.dart`, `/api/games/settings`, `/api/games/stats` |

## Шаги (клиент)

1. Пакет `client/lib/games/<id>/` — движок, repository, providers, rules.
2. Экраны `*_lobby_screen.dart`, `*_game_screen.dart` (+ offline при необходимости).
   - Лобби: собрать на `GameLobbyWaitingLayout`.
   - Партия: хром через `GameActionsOverlay` + `handleGameScreenClose` + таймеры.
3. `GameDescriptor` в `client/lib/games/framework/<id>_game.dart`
   (`id`, `buildLobbyScreen`, `buildGameScreen`, `buildOfflineScreen`).
4. Зарегистрировать в `GameRegistry` (`_builtinGames` в `game_registry.dart`).
5. Карточку на «Игры» — пока добавить рядом с `_TictactoeGameCard` /
   `_DurakGameCard` (вынос карточек в дескриптор — следующий шаг).
6. В `GameSessionApi` — ветки leave/forfeit/draw (или общий HTTP-контракт).

Роутер **уже** строится из реестра (`_gameRoutesFromRegistry`).

## Шаги (сервер)

1. Движок: `server/internal/<id>/` (как `durak` / `gameengine`).
2. Модуль `server/internal/gameregistry/<id>.go` — `ID`, `Modes`,
   `SupportsOffline`, `SupportsDrawOffer`, `DefaultSettings`.
3. `Registry.Register` в `gameregistry.Default()`.
4. HTTP: handlers Create/Join/Move/Forfeit/Timeout (пока рядом с
   `api/games.go` / отдельный файл; маршрутизация по `/api/games/<id>/…`).
5. В Redis всегда писать `"game_type", "<id>"` на lobby и game.
6. Финиш: монеты + `store.RecordGameResult` с нужным `GameType`.

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
cd server && go test ./internal/gameregistry/...
cd client && flutter test test/game_registry_test.dart
```
