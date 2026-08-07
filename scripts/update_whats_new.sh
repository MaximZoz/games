#!/usr/bin/env bash
# Обновляет WHAT_NEW.md из git-коммитов (для диалога «Обновить приложение»).
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

# Сообщения коммитов без merge; без технических «Merge:» / chore.
mapfile -t LINES < <(
  git log --no-merges --pretty=format:'%s' "${BASE_REF}..HEAD" 2>/dev/null \
    | grep -viE '^(Merge|merge|WIP|wip|tmp|temp)' \
    | head -n 25 \
    || true
)

{
  echo "# Что нового"
  echo "# Автоиз git log (${BASE_REF}..HEAD). Можно править руками перед деплоем."
  echo ""
  if [[ ${#LINES[@]} -eq 0 ]]; then
    echo "- Обновление приложения"
  else
    for line in "${LINES[@]}"; do
      # Убрать префиксы conventional commits для читаемости.
      clean="$(echo "$line" | sed -E 's/^(feat|fix|chore|docs|refactor|test|style|perf)(\([^)]+\))?:[[:space:]]*//I')"
      echo "- $clean"
    done
  fi
  echo ""
} > "$OUT"

cp "$OUT" "$OUT_SERVER"
echo "Обновлено: $OUT (${#LINES[@]} пунктов)"
