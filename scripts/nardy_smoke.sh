#!/usr/bin/env bash
# Сквозная проверка нард через HTTP: регистрация, партия с ботом, ходы до конца.
set -euo pipefail

API="${API:-http://localhost:8080}"
MODE="${1:-short}"
SUFFIX="$(date +%s)$RANDOM"
EMAIL="nardy_${SUFFIX}@example.com"
PASS="Passw0rd!${SUFFIX}"

say() { printf '\n=== %s ===\n' "$1"; }

SERVER_LOG="${SERVER_LOG:-/tmp/server.log}"

say "Регистрация $EMAIL"
REG=$(curl -sS -X POST "$API/api/auth/register" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\",\"display_name\":\"nardy$SUFFIX\"}")
TOKEN=$(printf '%s' "$REG" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("access_token",""))')

if [ -z "$TOKEN" ]; then
  # Почтовик не настроен — код подтверждения пишется в лог сервера.
  CODE=""
  for _ in $(seq 1 20); do
    CODE=$(grep -aF "verification code for $EMAIL" "$SERVER_LOG" 2>/dev/null |
      tail -1 | sed -E 's/.*: ([0-9]{4,8}).*/\1/')
    [ -n "$CODE" ] && break
    sleep 0.5
  done
  if [ -z "$CODE" ]; then
    echo "register failed and no code in $SERVER_LOG: $REG" >&2
    exit 1
  fi
  echo "код подтверждения из лога: $CODE"
  VER=$(curl -sS -X POST "$API/api/auth/verify-email" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$EMAIL\",\"code\":\"$CODE\"}")
  TOKEN=$(printf '%s' "$VER" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("access_token",""))')
fi

if [ -z "$TOKEN" ]; then
  echo "auth failed: $REG" >&2
  exit 1
fi
AUTH=(-H "Authorization: Bearer $TOKEN")

say "Создание партии с ботом (режим $MODE)"
CREATE=$(curl -sS -X POST "$API/api/games/nardy/lobby" "${AUTH[@]}" \
  -H 'Content-Type: application/json' \
  -d "{\"mode\":\"invite\",\"game_mode\":\"$MODE\",\"turn_time_sec\":0,\"stake_bronze\":2,\"vs_bot\":true}")
GAME_ID=$(printf '%s' "$CREATE" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("game_id",""))')
if [ -z "$GAME_ID" ]; then
  echo "create failed: $CREATE" >&2
  exit 1
fi
echo "game_id=$GAME_ID"

state() { curl -sS "$API/api/games/nardy/game/$GAME_ID" "${AUTH[@]}"; }

say "Стартовое состояние"
state | python3 -c '
import json,sys
v=json.load(sys.stdin)
print("mode      :", v["game_mode"])
print("my_index  :", v["my_index"], "turn:", v["turn"])
print("dice      :", v["dice"], "rolled:", v["rolled"])
print("board sum :", sum(abs(x) for x in v["board"]))
print("legal     :", len(v["legal_moves"]), "moves")
print("players   :", [(p["user_id"][:12], p["pips"]) for p in v["players"]])
'

say "Играем до конца партии"
python3 - "$API" "$GAME_ID" "$TOKEN" <<'PY'
import json, sys, time, urllib.request

api, game_id, token = sys.argv[1], sys.argv[2], sys.argv[3]
headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}


def call(path, payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(f"{api}{path}", data=data, headers=headers,
                                 method="POST" if data else "GET")
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read() or b"{}")


moves_made = 0
rolls = 0
bot_waits = 0
for step in range(4000):
    view = call(f"/api/games/nardy/game/{game_id}")
    if view["is_over"]:
        print(f"finished: winner_index={view['winner_index']} "
              f"kind={view['win_kind']} off={view['off']}")
        print(f"stats: my_moves={moves_made} rolls={rolls} bot_waits={bot_waits}")
        # Ровно 15 шашек у победителя и целая доска.
        total = [view["off"][s] + view["bar"][s] for s in (0, 1)]
        for point in view["board"]:
            if point > 0:
                total[0] += point
            elif point < 0:
                total[1] += -point
        assert total == [15, 15], f"checker count broken: {total}"
        assert view["off"][view["winner_index"]] == 15
        print("checker counts intact:", total)
        sys.exit(0)
    if not view["is_my_turn"]:
        bot_waits += 1
        time.sleep(0.25)
        continue
    if view["needs_roll"]:
        call(f"/api/games/nardy/game/{game_id}/move", {"action": "roll"})
        rolls += 1
        continue
    legal = view["legal_moves"]
    if not legal:
        call(f"/api/games/nardy/game/{game_id}/move", {"action": "end_turn"})
        continue
    # Самая продвинутая шашка первой — партия быстрее доходит до конца.
    mv = max(legal, key=lambda m: m["from"] + m["die"])
    call(f"/api/games/nardy/game/{game_id}/move",
         {"action": "move", "from": mv["from"], "die": mv["die"]})
    moves_made += 1

print("game did not finish in time", file=sys.stderr)
sys.exit(1)
PY

say "Итоговое состояние"
state | python3 -c '
import json,sys
v=json.load(sys.stdin)
print("is_over   :", v["is_over"])
print("winner    :", v["winner_index"], v["win_kind"])
print("off       :", v["off"])
'

say "Статистика игр пользователя"
curl -sS "$API/api/games/stats" "${AUTH[@]}" | python3 -c '
import json,sys
data=json.load(sys.stdin)
rows=data if isinstance(data,list) else data.get("stats") or data.get("items") or data
print(json.dumps(rows, ensure_ascii=False)[:600])
'
