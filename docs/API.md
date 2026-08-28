# API

Базовый URL: `http://localhost:8080` (локально), на проде — домен приложения.
Все защищённые эндпоинты требуют заголовок `Authorization: Bearer <access_token>`.
Токен доступа (access) живёт 15 минут, обновляется через `/api/auth/refresh`.

> **Краткий список роутов** см. также в логах старта сервера (`cmd/server/main.go`).
> Реальное состояние игр/лобби — в Redis; поэтому эндпоинты `/api/games/*`
> (кроме `/api/games/settings`) требуют подключённого Redis, иначе возвращают ошибку.
> WebSocket: `GET /api/ws?access_token=<jwt>` — события реального времени.

---

## Авторизация

### Регистрация

```
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "не менее 6 символов",
  "display_name": "Игрок",   // опционально
  "ref": "..."               // опционально: реферальный код/ник пригласившего
}
```

После регистрации на email отправляется код подтверждения (если настроена
почта). Ответ `200 OK`:

```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "expires_in": 900,
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "display_name": "Игрок"
  }
}
```

### Подтверждение email

```
POST /api/auth/verify-email
{ "email": "user@example.com", "code": "123456" }
```

Повторно запросить код:

```
POST /api/auth/resend-verification
{ "email": "user@example.com" }
```

### Вход

```
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",   // логин по email ИЛИ display_name
  "password": "пароль"
}
```

Формат ответа такой же, как при регистрации.

### Обновление access-токена (refresh flow)

```
POST /api/auth/refresh
Content-Type: application/json

{
  "refresh_token": "eyJ..."
}
```

Ответ `200 OK`:

```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "expires_in": 900,
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "display_name": "Игрок",
    "is_admin": false
  }
}
```

Если refresh-токен невалидный/протух — `401 Unauthorized`.

### Восстановление пароля

Запросить код сброса (приходит на email):

```
POST /api/auth/forgot-password
{ "email": "user@example.com" }
```

Сбросить пароль кодом:

```
POST /api/auth/reset-password
{ "email": "user@example.com", "code": "123456", "new_password": "новый пароль" }
```

### Текущий пользователь (защищённый эндпоинт)

```
GET /api/me
Authorization: Bearer <access_token>
```

Ответ `200 OK`:

```json
{
  "id": "uuid",
  "email": "user@example.com",
  "display_name": "Игрок",
  "is_admin": false
}
```

При отсутствии или невалидном токене — `401 Unauthorized`.

### Профиль

```
PUT /api/profile
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "display_name": "Игрок",
  "age": 25,
  "gender": "male|female|other",
  "about": "текст о себе",
  "avatar_kind": "letter|image",
  "avatar_value": "..."
}
```

Галерея дополнительных фото (до 3 слотов `0..2`, каждое до 256 КБ). Список виден любому авторизованному; загружать и удалять может только владелец.

```
GET /api/profile/photos?user_id=<uuid>
GET /api/profile/photos/file?id=<photo_uuid>
POST /api/profile/photos
{
  "slot": 0,
  "image_base64": "...",
  "image_mime": "image/jpeg"
}
DELETE /api/profile/photos?id=<photo_uuid>
POST /api/profile/photos/delete
{ "id": "<photo_uuid>" }
```

### Вход через OAuth (Google / Apple / Yandex / VK)

```
GET /api/auth/oauth/providers        // список включённых провайдеров
GET /api/auth/oauth/{provider}/start   // редирект на авторизацию провайдера
GET /api/auth/oauth/{provider}/callback // обработка кода от провайдера
GET /api/auth/oauth/poll?state=<state>  // поллинг результата входа (для popup-флоу)
POST /api/auth/oauth/google/id-token    // вход по Google ID Token (GIS)
```

`{provider}` ∈ `google | apple | yandex | vk`. Кнопки скрыты, пока не заданы
соответствующие `*_CLIENT_ID` / `*_CLIENT_SECRET`. Redirect URI:
`{PUBLIC_BASE_URL}/api/auth/oauth/{provider}/callback`.

---

## Друзья

Все эндпоинты ниже требуют:
`Authorization: Bearer <access_token>`.

### Список друзей и заявок

```
GET /api/friends
Authorization: Bearer <access_token>
```

Ответ `200 OK`:

```json
{
  "friends": [
    {
      "user": { "id": "uuid", "email": "a@b.c", "display_name": "Player" },
      "created_at": "2026-02-20T15:00:00Z"
    }
  ],
  "incoming": [
    {
      "request_id": "uuid",
      "user": { "id": "uuid", "email": "x@y.z" },
      "created_at": "2026-02-20T15:10:00Z"
    }
  ],
  "outgoing": []
}
```

Всего пользователей:

```
GET /api/friends/users-count      // { "count": 123 }
```

### Поиск пользователей для добавления

```
GET /api/friends/search?q=nick_or_email&limit=20&offset=0
Authorization: Bearer <access_token>
```

`relation_status` в ответе: `none | friend | incoming | outgoing`.

### Отправить заявку в друзья

```
POST /api/friends/request
Authorization: Bearer <access_token>
Content-Type: application/json

{ "target_user_id": "uuid" }
```

Ответ `201 Created`:
`{ "request_id": "uuid" }`

### Принять заявку

```
POST /api/friends/accept
Authorization: Bearer <access_token>
Content-Type: application/json

{ "request_id": "uuid" }
```

Ответ `204 No Content`.

### Отклонить заявку

```
POST /api/friends/reject
Authorization: Bearer <access_token>
Content-Type: application/json

{ "request_id": "uuid" }
```

Ответ `204 No Content`.

### Отменить исходящую заявку

```
POST /api/friends/cancel
Authorization: Bearer <access_token>
Content-Type: application/json

{ "request_id": "uuid" }
```

Ответ `204 No Content`.

### Удалить из друзей

```
POST /api/friends/remove
Authorization: Bearer <access_token>
Content-Type: application/json

{ "friend_user_id": "uuid" }
```

Ответ `204 No Content`.

---

## Чаты

Все эндпоинты требуют `Authorization: Bearer <access_token>`. События в
реальном времени приходят через WebSocket: `chat_message`,
`chat_list_changed`, `chat_read`, `chat_delivered`.

### Список диалогов

```
GET /api/chats
Authorization: Bearer <access_token>
```

Возвращает превью чатов (собеседник, последнее сообщение, число непрочитанных).

### Начать диалог

```
POST /api/chats/start
Content-Type: application/json
{ "target_user_id": "uuid" }
```

### Возможности чата (включены ли изображения и т.п.)

```
GET /api/chats/capabilities
```

### Сообщения

```
GET /api/chats/messages?chat_id=<uuid>&before=<message_id>&limit=50
POST /api/chats/messages
Content-Type: application/json
{ "chat_id": "uuid", "body": "текст" }
```

Изображение к сообщению:

```
POST /api/chats/messages/image
Content-Type: multipart/form-data
```

Редактирование / удаление / ответ:

```
POST /api/chats/messages/edit
{ "message_id": "uuid", "body": "новый текст" }

POST /api/chats/messages/delete
{ "message_id": "uuid" }
```

### Доставка и чтение

```
POST /api/chats/read       // { "chat_id": "uuid" }
POST /api/chats/delivered  // { "chat_id": "uuid" }
```

### Очистка и блокировка

```
POST /api/chats/clear      // { "chat_id": "uuid" }   — удалить диалог
POST /api/chats/block      // { "target_user_id": "uuid" }
POST /api/chats/unblock    // { "target_user_id": "uuid" }
GET  /api/chats/blocked    // список заблокированных
```

---

## Игры (крестики-нолики)

> Требуют Redis. Эндпоинт `/api/games/settings` работает без Redis (Postgres).

Все эндпоинты требуют `Authorization: Bearer <access_token>`. Роуты под
`/api/games/` диспетчеризуются внутри `GamesHandler.ServeHTTP`.

### Настройки игры (Postgres, без Redis)

```
GET /api/games/settings     // настройки текущего пользователя
PUT /api/games/settings
Content-Type: application/json
{
  "game_type": "tictactoe",
  "turn_time_sec": 0,
  "grid_size": 3,
  "swap_rule": false,
  "first_move_restriction": false,
  "stake_bronze": 1
}
```

### Лобби и матчмейкинг

```
GET  /api/games/tictactoe/active                  // активная игра/лобби пользователя
POST /api/games/tictactoe/lobby                   // создать лобби (mode: invite | matchmaking)
GET  /api/games/tictactoe/lobbies                 // список открытых лобби
POST /api/games/tictactoe/rematch                 // реванш
GET  /api/games/tictactoe/lobby/:id               // просмотр лобби
POST /api/games/tictactoe/lobby/:id/invite        // пригласить друга
POST /api/games/tictactoe/lobby/:id/join          // войти
POST /api/games/tictactoe/lobby/:id/leave         // выйти
POST /api/games/tictactoe/lobby/:id/decline       // отклонить приглашение
```

### Игра

```
GET  /api/games/tictactoe/game/:id                 // состояние партии
POST /api/games/tictactoe/game/:id/move            // ход
POST /api/games/tictactoe/game/:id/swap            // правило swap
POST /api/games/tictactoe/game/:id/forfeit         // сдаться
POST /api/games/tictactoe/game/:id/draw-offer      // предложить ничью
POST /api/games/tictactoe/game/:id/draw-accept     // принять ничью
```

---

## Presence (онлайн-статус)

```
GET /api/presence?user_ids=id1,id2,...   // не более 50
Authorization: Bearer <access_token>
```

Онлайн = есть активное WS-соединение **или** `last_seen_at` < 60 сек.

---

## Монеты и ежедневная награда

```
GET  /api/coins/daily-available      // доступна ли награда, серия
POST /api/coins/claim-daily          // получить награду
```

Валюта — бронза (`balance_bronze`); 1 серебро = 100 бронзы.

---

## Достижения

```
GET  /api/achievements                       // список достижений пользователя
GET  /api/achievements/unclaimed-count       // число невостребованных наград
POST /api/achievements/claim                 // { "code": "..." }
```

Каталог достижений (рамки/награды) вычисляется сервером; разблокировка
происходит автоматически при достижении условия (`EvaluateAndUnlock`).

---

## Магазин и инвентарь

Все эндпоинты требуют `Authorization: Bearer <access_token>`.

```
GET  /api/shop                          // каталог
POST /api/shop/buy                      // { "item_code": "...", "quantity": 1 }

GET  /api/inventory                     // инвентарь пользователя
GET  /api/inventory/capabilities        // доступные ставки/возможности
POST /api/inventory/consume             // { "item_code": "..." }
POST /api/inventory/sell                // продажа коллекции (возврат 80%)
POST /api/inventory/gift                // подарок другу (создаёт системное сообщение в чате)

GET  /api/inventory/collections?user_id=<uuid>      // витрина коллекций
GET  /api/inventory/collection-income              // доход с коллекций
POST /api/inventory/claim-collection-income        // забрать дневной доход
```

---

## Push-уведомления (Web Push / PWA + Android FCM)

> Web Push: `VAPID_PUBLIC_KEY` / `VAPID_PRIVATE_KEY`; иначе PWA-push отключён.
> Android (закрытое приложение): `FCM_SERVICE_ACCOUNT_JSON`.

```
GET  /api/push/vapid-key       // публичный VAPID-ключ для подписки
POST /api/push/subscribe       // подписка браузера (endpoint, p256dh, auth)
POST /api/push/unsubscribe     // { "endpoint": "..." }
POST /api/push/device          // FCM-токен: { "token": "...", "platform": "android" }
POST /api/push/device/unregister // снять токен: { "token": "..." }
GET  /api/push/preferences     // категории уведомлений (chat/friends/games/rewards)
PUT  /api/push/preferences     // обновление категорий
```

---

## Настройки пользователя

```
GET  /api/settings             // { "messages_friends_only": false }
PUT  /api/settings
Content-Type: application/json
{ "messages_friends_only": true }
```

---

## Админка

Все эндпоинты `/api/admin/*` (кроме init) требуют заголовок
`Authorization: Bearer <access_token>` и что пользователь является админом
(`is_admin: true`).

### Создание первого админа (однократно)

Задай в окружении переменную `ADMIN_INIT_SECRET`. Затем один раз вызови:

```
POST /api/admin/init
Content-Type: application/json
X-Admin-Init-Secret: <значение ADMIN_INIT_SECRET>

{
  "email": "admin@example.com",
  "password": "не менее 6 символов"
}
```

Ответ `201 Created` — пользователь создан с правами админа. Далее входи через
обычный `POST /api/auth/login`. Если админ уже есть в БД, вернётся `409 Conflict`.

### Список пользователей

```
GET /api/admin/users
Authorization: Bearer <access_token>
```

Ответ `200 OK`: `{ "users": [ { "id", "email", "display_name", "is_admin", "created_at" }, ... ] }`

### Список логов (админка)

Логи сначала пишутся в файл (`APP_LOG_FILE`), затем импортируются в БД и
читаются этим endpoint.

```
GET /api/admin/logs?limit=100&offset=0&user_id=<uuid>&source=frontend|backend&from=<RFC3339>&to=<RFC3339>
Authorization: Bearer <access_token>
```

Параметры `user_id`, `source`, `from`, `to` опциональны.
Пример: `from=2026-02-20T09:00:00Z`.

Ответ `200 OK`:

```json
{
  "logs": [
    {
      "event_id": "uuid-or-text",
      "event_time": "2026-02-20T12:34:56.123Z",
      "source": "frontend|backend",
      "method_name": "AuthRepository.login|http.request",
      "http_method": "GET|POST|PUT",
      "path": "/api/auth/login",
      "status_code": 200,
      "duration_ms": 42
    }
  ],
  "limit": 100,
  "offset": 0
}
```

Очистка логов:

```
POST /api/admin/logs/clear      // очистка таблицы app_logs
```

### Назначить/снять админа

```
POST /api/admin/users/set-admin
Authorization: Bearer <access_token>
Content-Type: application/json

{ "user_id": "uuid", "is_admin": true }
```

Ответ `204 No Content`.

### Сбросить пароль пользователю

```
POST /api/admin/users/reset-password
Authorization: Bearer <access_token>
Content-Type: application/json

{ "user_id": "uuid", "new_password": "не менее 6 символов" }
```

Ответ `204 No Content`.

### Удалить пользователя

```
POST /api/admin/users/delete
Authorization: Bearer <access_token>
Content-Type: application/json

{ "user_id": "uuid" }
```

Ответ `204 No Content`. Удалить самого себя нельзя (`400`).

---

## WebSocket (realtime)

```
GET /api/ws?access_token=<jwt>
```

Апгрейд до WebSocket. Единственный канал событий реального времени для всего
клиента. Типы событий (поле `type`), среди прочего: `user_online`,
`user_offline`, `friends_updated`, `chat_message`, `chat_list_changed`,
`chat_read`, `chat_delivered`, `game_invite`, `lobby_updated`, `game_started`.
Пинг каждые 30 сек, read-deadline 60 сек (неактив → отключение → `user_offline`).

---

## Логирование методов фронтенда

Клиент отправляет события (методы API фронта) в endpoint:

```
POST /api/logs/frontend
Content-Type: application/json
Authorization: Bearer <access_token>   // опционально

{
  "event_time": "2026-02-20T12:34:56.123Z",
  "method_name": "AuthRepository.login",
  "http_method": "POST",
  "path": "/api/auth/login",
  "status_code": 200,
  "duration_ms": 42,
  "message": "ошибка (если есть)",
  "metadata": { "url": "http://localhost:8080/api/auth/login" }
}
```

События не выдаются напрямую этим endpoint — они попадают в админку через
`/api/admin/logs`.

---

## Service

```
GET /api/start      // → "go start"   (healthcheck для Fly.io)
```
