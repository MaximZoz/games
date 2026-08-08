#!/usr/bin/env bash
# Включает post-commit: после каждого коммита обновляется WHAT_NEW.md.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chmod +x "$ROOT/scripts/update_whats_new.sh" "$ROOT/.githooks/post-commit"
git -C "$ROOT" config core.hooksPath .githooks
echo "Git hooks: core.hooksPath=.githooks (WHAT_NEW обновляется после commit)"
