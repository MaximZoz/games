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
  "display_name": "Игрок"
}
```

При отсутствии или невалидном токене — `401 Unauthorized`.
