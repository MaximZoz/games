# API

## Авторизация

### Регистрация

```
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "не менее 6 символов",
  "display_name": "Игрок"   // опционально
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
    "display_name": "Игрок"
  }
}
```

### Вход

```
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "пароль"
}
```

Формат ответа такой же, как при регистрации.

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

---

## Админка

Все эндпоинты `/api/admin/*` (кроме init) требуют заголовок `Authorization: Bearer <access_token>` и что пользователь является админом (`is_admin: true`).

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

Ответ `201 Created` — пользователь создан с правами админа. Далее входи через обычный `POST /api/auth/login`. Если админ уже есть в БД, вернётся `409 Conflict`.

### Список пользователей

```
GET /api/admin/users
Authorization: Bearer <access_token>
```

Ответ `200 OK`: `{ "users": [ { "id", "email", "display_name", "is_admin", "created_at" }, ... ] }`

### Список логов (админка)

Логи сначала пишутся в файл (`APP_LOG_FILE`), затем импортируются в БД и читаются этим endpoint.

```
GET /api/admin/logs?limit=100&offset=0
Authorization: Bearer <access_token>
```

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

События не выдаются напрямую этим endpoint — они попадают в админку через `/api/admin/logs`.
