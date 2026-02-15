# 📋 План интеграции с GitHub

## 1. Создание репозитория

### Вариант A: Новый репозиторий на GitHub

1. Перейди на [github.com/new](https://github.com/new)
2. Название: `multigames` или `myProject` (по желанию)
3. Описание: `Multiplatform online mini-games • Flutter + Go`
4. **Public** или **Private** — на выбор
5. Не добавляй README, .gitignore, License — они уже в проекте
6. Нажми **Create repository**

### Вариант B: Существующий репозиторий

Если репозиторий уже создан — просто добавь remote.

---

## 2. Первый пуш в GitHub

```bash
# В корне проекта (c:\myProject)
git init
git add .
git commit -m "Initial: project scaffold, README, docs"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

---

## 3. Структура веток

| Ветка | Назначение |
|-------|------------|
| `main` | Продакшен, стабильный код |
| `develop` | Разработка, интеграция фич |
| `feature/game-chess` | Новая игра (шахматы) |
| `feature/elo-system` | Система рейтинга |
| `fix/websocket-reconnect` | Исправления |
| `release/v0.1.0` | Релизная ветка |

### Рекомендуемый flow

```
main ─────●──────────────────────────●────────────
           \                        /
develop ───●──●──●──●──●──●──●──●──●
                 \        /
feature/xxx ──────●──●──●
```

---

## 4. Структура коммитов (Conventional Commits)

```
feat: добавлена игра шашки
fix: реконнект WebSocket при потере сети
docs: обновлён README
chore: обновлены зависимости
refactor: вынесена логика ELO в отдельный пакет
```

---

## 5. GitHub Actions (CI)

Создай `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  flutter:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: client
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test

  go:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: server
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - run: go mod download
      - run: go build ./...
      - run: go test ./...
```

---

## 6. Структура Issues и Projects

### Labels

- `bug` — баги
- `enhancement` — улучшения
- `game` — новая игра
- `animation` — анимации
- `platform` — платформо-специфика
- `backend` — Go/API
- `frontend` — Flutter

### Milestones

- **v0.1.0** — MVP: 1 игра, базовая авторизация, рейтинг
- **v0.2.0** — 2–3 игры, WebSocket
- **v0.3.0** — Мобильные приложения
- **v1.0.0** — Полный набор платформ

---

## 7. Чек-лист перед первым пушем

- [ ] Создан репозиторий на GitHub
- [ ] `.gitignore` настроен
- [ ] README актуален
- [ ] `git init` выполнен
- [ ] Первый коммит создан
- [ ] Remote добавлен
- [ ] `git push` выполнен

---

## 8. Дальнейшие шаги

1. Создать `develop` ветку
2. Добавить `.github/workflows/ci.yml`
3. Настроить branch protection для `main`
4. Создать первый Issue / Milestone
5. (Опционально) Добавить CODEOWNERS
