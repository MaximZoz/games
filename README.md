# MultiGames

Монорепозиторий: Flutter-клиент (Web / Android / PWA) и Go API для онлайн-мини-игр.

```text
Flutter (Riverpod, go_router)
        │  REST /api/*  +  WebSocket /api/ws
        ▼
Go (net/http, pgx, JWT)
        ├── PostgreSQL — пользователи, чаты, друзья, магазин, логи
        └── Redis — лобби, партии, матчмейкинг (без Redis игры выключены)
```

Чаты и presence живут в Postgres. Подробности: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/DATABASE.md](docs/DATABASE.md).

---

## Что уже есть

**Аккаунт.** Регистрация и вход (email + refresh JWT), подтверждение почты, сброс пароля, OAuth Google / Apple / Yandex / VK, профиль (ник, возраст, пол, «о себе», аватар, до 3 фото). Заморозка проверяется на refresh, на каждом защищённом запросе и на WebSocket; сессии замороженного сбрасываются. Логин, регистрация, сброс пароля и подключение сокета ограничены по IP (общий счётчик в Redis, ответ `429`).

**Соцсеть.** Друзья и заявки, чаты (текст, фото, правки, ответы, блокировка), онлайн-статус, push (PWA + Android FCM). Рассылка чатов, друзей и presence, а также OAuth state, идут через Redis — несколько машин на Fly видят одно состояние.

**Партии.** Ход закрывается локом `gamelock:{id}` (в том числе ход бота), два запроса не перезаписывают доску. Список открытых лобби читается из индекса `idx:lobbies`.

**Экономика.** Монеты, ежедневная награда, магазин (смайлы, коллекции, рамки, ставки), инвентарь и подарки, доход коллекций, достижения и задания.

**Игры** — лобби, приглашения, поиск, бот/офлайн, ставки, реванш, статистика и head-to-head:

| Игра | Режимы |
|---|---|
| Крестики-нолики | 3×3–8×8, swap, бот |
| Дурак | онлайн и офлайн с ботами |
| Морской бой | расстановка, бой, бот |
| UNO | 2–4 игрока, офлайн-боты |
| Покер (Texas Hold'em) | стол 2–6, офлайн-боты |
| Нарды | короткие и длинные, кнопка смены раскладки фишек |
| Шашки | русские, английские, поддавки, уголки; правила в диалоге — только выбранный режим |

**Оболочка.** 29 языков, адаптив десктоп / телефон / landscape / iOS PWA, админка (пользователи, логи, поддержка), офлайн-режим по подтверждению. На карточках игр чипы режимов и кнопки одного размера.

**Геймпад** (веб: Gamepad API; Android: кнопки, стики, триггеры):

- `LB` / `RB` — вкладки меню
- левый стик и стрелки — карточки (достижения, монеты, магазин…)
- правый стик — страница или скролл
- `LT` — баланс (`A` открывает, любая кнопка закрывает окно); на «Друзья» — открыть/закрыть поиск
- на «Друзья» правый стик листает вкладки (сами табы без рамки); левый стик и стрелки — карточки; `A` на карточке открывает профиль; влево/вправо и `A` — кнопки «сообщение» / «удалить»; диалог «Убрать» — стик только по «Отмена» / «Убрать»
- в карточке пользователя стик ходит по аватару, сообщению, крестику, статистике и коллекциям; «Ваш счёт» — отдельная строка, игры листаются правым стиком или пальцем; в галерее фото и во всплывашке статистики стик скроллит список, любая кнопка закрывает, крестик без рамки; вкладки и список друзей за попапом не листаются
- в сообщениях клавиатура геймпада поднимает поле ввода, как системная; без мигания второй клавиатуры
- `RT` — кнопка «Выйти» (`A` выходит)
- в магазине `A` открывает превью, затем диалог покупки (`A` купить, любая другая — только закрыть диалог)
- в партиях — курсор по полю, картам и кнопкам; в поле ввода — экранная клавиатура
- в редакторе профиля — как на входе: стик ходит по полям и кнопкам, клавиатура геймпада только по `A`, `B` скрывает, «Назад» выходит из редактирования; во всплывашке пола стик только по пунктам (`A` выбирает и закрывает); влево/вправо по фото остаются в ряду

Подсказки кнопок зависят от Xbox / PlayStation / Nintendo. В Настройках раскладка (A/B или ✕/○, LB/RB или L1/R1, LT/RT) обновляется под подключённый контроллер.

---

## Стек

| | |
|---|---|
| Клиент | Flutter 3.27+, Dart ≥3.2, Riverpod, go_router, 29 `.arb` |
| Сервер | Go 1.24, `net/http`, pgx, JWT, Redis, WebSocket, Web Push |
| Данные | миграции `001`–`057` |
| Деплой | Docker, Fly.io (прод + DEV), Android Play Internal |

Клиент: `client/lib/` по доменам (`auth`, `chats`, `friends`, `games`, `shop`, `core/gamepad`, `screens`).  
Сервер: `server/cmd/server`, `internal/api`, `internal/store`, `migrations/`.

---

## API (кратко)

Полный список: [docs/API.md](docs/API.md). Игры (`/api/games/*`, кроме `settings` / `stats`) требуют Redis.

- Auth: `/api/auth/*`, `/api/me`, `/api/profile`, `/api/profile/photos`
- Друзья, чаты, presence: `/api/friends/*`, `/api/chats/*`, `/api/presence`
- Монеты, магазин, достижения: `/api/coins/*`, `/api/shop`, `/api/inventory/*`, `/api/achievements`, `/api/tasks`
- Игры: `/api/games/{tictactoe,durak,battleship,uno,poker,nardy,checkers}/*`, `/api/games/settings|stats|head-to-head|invites`
- Push: `/api/push/*`
- Админка: `/api/admin/*`
- Realtime: `GET /api/ws?access_token=`

---

## Быстрый старт

Нужны Flutter 3.27+, Go 1.24+, Docker.

```bash
docker compose up -d
cp .env.example .env          # и в server/.env
cd server && go run ./cmd/server
cd client && flutter run -d chrome
```

Главное в `.env`: `DATABASE_URL`, `REDIS_URL`, `JWT_SECRET`, `ADMIN_INIT_SECRET`.  
Почта — `RESEND_API_KEY` или `SMTP_*`. OAuth — `*_CLIENT_ID` / `*_CLIENT_SECRET`. Push — `VAPID_*`, на Android ещё `FCM_SERVICE_ACCOUNT_JSON`.

Без Redis сервер стартует, но лобби и партии недоступны.

---

## Тесты

```bash
cd server && go test ./... && go vet ./...
cd client && flutter analyze --no-fatal-infos && flutter test
./launcher/test.sh
```

---

## Деплой

Один сервис на Fly.io: Go на `/api/*`, Flutter Web как статика.

| Ветка | Куда |
|---|---|
| `develop` | https://multigameszozu-dev.fly.dev |
| `main` | https://multigameszozu.fly.dev |

```bash
./launcher/deploy_dev.sh          # DEV
./launcher/deploy_develop.sh      # origin/develop
```

Android Play Internal: `develop` → flavor **dev**, `main` → **prod**. См. [docs/ANDROID_PLAY_INTERNAL.md](docs/ANDROID_PLAY_INTERNAL.md).

Подробно: [DEPLOY.md](DEPLOY.md), [docs/DEPLOY_FLY.md](docs/DEPLOY_FLY.md), [docs/DEPLOY_FLY_DEV.md](docs/DEPLOY_FLY_DEV.md).

---

## Дальше

- [ ] Интеграционные тесты с живой БД (друзья, чаты, игры)
- [ ] Шире widget-тесты ключевых экранов
- [ ] Турниры и рейтинг
- [ ] Релизный чек-лист (мониторинг, бэкапы, алерты)

---

## Документация

- [Архитектура](docs/ARCHITECTURE.md)
- [API](docs/API.md)
- [Базы данных](docs/DATABASE.md)
- [Деплой](DEPLOY.md)
- [Скрипты](launcher/README.md)
