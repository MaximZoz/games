# Деплой MultiGames на Fly.io

Краткое руководство: один сервис (Go API + Flutter Web), Postgres и секреты.

---

## Требования

- [Fly CLI](https://fly.io/docs/hands-on/install-flyctl/) установлен
- Выполнен вход: `fly auth login`
- В корне проекта есть `fly.toml` и `Dockerfile`

---

## Шаг 1. Создать приложение (если ещё нет)

Из **корня репозитория**:

```bash
fly launch --no-deploy
```

Укажи имя приложения (например `multigames`) и регион (например `arn` — Стокгольм, `ams` — Амстердам). Postgres и Redis на этом шаге не добавляй.

---

## Шаг 2. Postgres

```bash
fly postgres create --name multigames-db --region arn
```

Регион (`arn`) замени на тот, что выбрал для приложения. После создания:

```bash
fly postgres attach multigames-db --app <имя-твоего-приложения>
```

На вопрос «Set DATABASE_URL?» ответь **y**. Секрет `DATABASE_URL` установится автоматически.

---

## Шаг 3. Секреты

**Обязательно:**

```bash
fly secrets set JWT_SECRET="придумай-длинную-случайную-строку-32-символа" --app <имя-приложения>
```

**Для создания первого админа** (один раз):

```bash
fly secrets set ADMIN_INIT_SECRET="твой-секрет-для-админа" --app <имя-приложения>
```

**Redis** не обязателен: если `REDIS_URL` не задан, приложение запустится без Redis. Позже можно добавить Upstash и задать `REDIS_URL`.

---

## Шаг 4. Деплой

Из корня репозитория:

```bash
fly deploy --app <имя-приложения>
```

Сборка (Flutter Web + Go) займёт несколько минут. В конце будет ссылка вида `https://<имя-приложения>.fly.dev`.

---

## Шаг 5. Первый админ

Если задал `ADMIN_INIT_SECRET`, создай первого админа одним запросом.

**PowerShell** (каждую команду вводи с Enter отдельно):

```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-Admin-Init-Secret" = "твой-секрет-для-админа"
}
```

```powershell
$body = '{"email":"admin@example.com","password":"надёжный-пароль-6-символов"}'
```

```powershell
Invoke-RestMethod -Uri "https://<имя-приложения>.fly.dev/api/admin/init" -Method POST -Headers $headers -Body $body
```

Подставь своё имя приложения и тот же секрет, что в `ADMIN_INIT_SECRET`. После успешного ответа войди на сайт под этим email и паролем — в тулбаре появится иконка щита (админка).

**Bash / curl:**

```bash
curl -X POST "https://<имя-приложения>.fly.dev/api/admin/init" \
  -H "Content-Type: application/json" \
  -H "X-Admin-Init-Secret: твой-секрет-для-админа" \
  -d '{"email":"admin@example.com","password":"надёжный-пароль"}'
```

---

## Полезные команды

| Команда | Описание |
|--------|----------|
| `fly status --app <имя>` | Статус машин |
| `fly logs --app <имя>` | Логи приложения |
| `fly secrets list --app <имя>` | Список секретов |
| `fly scale count 1 --app <имя>` | Держать одну машину всегда включённой (без холодного старта) |

---

## Если что-то не так

- **Сайт не открывается** — см. [docs/DEPLOY_FLY_TROUBLESHOOTING.md](docs/DEPLOY_FLY_TROUBLESHOOTING.md) (статус, логи, доступ из РФ, редиректы).
- **Полная пошаговая инструкция** — [docs/DEPLOY_FLY.md](docs/DEPLOY_FLY.md).
