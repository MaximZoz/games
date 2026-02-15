#!/usr/bin/env bash
# MultiGames Launcher — запуск тестов (Go + Flutter)
# Запуск из корня проекта: ./launcher/test.sh

set -e
cd "$(dirname "$0")/.."
PROJECT_ROOT="$(pwd)"

echo "MultiGames Tests"
echo ""

FAILED=0

echo "Go tests..."
(cd "$PROJECT_ROOT/server" && go test ./...) || FAILED=1

echo ""
echo "Flutter tests..."
if [ -d "$PROJECT_ROOT/client/test" ]; then
    (cd "$PROJECT_ROOT/client" && flutter test --no-pub) || FAILED=1
else
    echo "No test directory, skipping Flutter tests."
fi

echo ""
if [ "$FAILED" -ne 0 ]; then
    echo "Some tests failed."
    exit 1
fi
echo "All tests passed."
exit 0
