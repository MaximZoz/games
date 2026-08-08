#!/usr/bin/env bash
# Обновляет WHAT_NEW.md из git-коммитов (для диалога «Обновить приложение»).
# Пишет секцию ## ru; секцию ## en сохраняет из предыдущего файла (если была).
# Использование:
#   ./scripts/update_whats_new.sh              # vs origin/develop
#   ./scripts/update_whats_new.sh origin/main
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_REF="${1:-origin/develop}"
OUT="$ROOT_DIR/WHAT_NEW.md"
OUT_SERVER="$ROOT_DIR/server/cmd/server/whats_new.md"

cd "$ROOT_DIR"

# База может отсутствовать локально — подтянуть.
git rev-parse --verify "$BASE_REF" >/dev/null 2>&1 || \
  git fetch origin "$(echo "$BASE_REF" | sed 's#^origin/##')" 2>/dev/null || true

if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  BASE_REF="HEAD~15"
fi

# Сохранить прежний ## en (ручной перевод), если есть.
PREV_EN=""
if [[ -f "$OUT" ]]; then
  PREV_EN="$(awk '
    BEGIN { in_en=0 }
    /^##[ \t]+en[ \t]*$/ { in_en=1; next }
    /^##[ \t]+/ { in_en=0 }
    in_en { print }
  ' "$OUT")"
  # Убрать хвостовые пустые строки.
  while [[ "$PREV_EN" == *$'\n' ]]; do
    PREV_EN="${PREV_EN%$'\n'}"
  done
fi

# Сообщения коммитов без merge; без технических «Merge:» / chore.
mapfile -t LINES < <(
  git log --no-merges --pretty=format:'%s' "${BASE_REF}..HEAD" 2>/dev/null \
    | grep -viE '^(Merge|merge|WIP|wip|tmp|temp)' \
    | head -n 25 \
    || true
)

{
  echo "# Что нового"
  echo "# Секции ## ru / ## en — сервер отдаёт по Accept-Language."
  echo "# Автоиз git log (${BASE_REF}..HEAD). ## en можно править руками."
  echo ""
  echo "## ru"
  if [[ ${#LINES[@]} -eq 0 ]]; then
    echo "- Обновление приложения"
  else
    for line in "${LINES[@]}"; do
      clean="$(echo "$line" | sed -E 's/^(feat|fix|chore|docs|refactor|test|style|perf)(\([^)]+\))?:[[:space:]]*//I')"
      echo "- $clean"
    done
  fi
  echo ""
  echo "## en"
  if [[ -n "$(printf '%s' "$PREV_EN" | tr -d '[:space:]')" ]]; then
    printf '%s\n' "$PREV_EN"
  else
    echo "- App update"
  fi
  echo ""
} > "$OUT"

cp "$OUT" "$OUT_SERVER"
echo "Обновлено: $OUT (${#LINES[@]} пунктов ru)"
