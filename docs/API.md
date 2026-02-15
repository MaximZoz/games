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
