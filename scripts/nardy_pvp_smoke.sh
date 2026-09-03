#!/usr/bin/env bash
# Матч двух живых игроков в нарды: поиск соперника, партия, статистика.
set -euo pipefail

API="${API:-http://localhost:8080}"
MODE="${1:-short}"
SERVER_LOG="${SERVER_LOG:-/tmp/server.log}"

say() { printf '\n=== %s ===\n' "$1"; }

register() {
  local suffix="$1"
  local email="nardy_pvp_${suffix}@example.com"
  local pass="Passw0rd!${suffix}"
  local reg token code
  reg=$(curl -sS -X POST "$API/api/auth/register" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$email\",\"password\":\"$pass\",\"display_name\":\"pvp$suffix\"}")
  token=$(printf '%s' "$reg" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("access_token",""))')
  if [ -z "$token" ]; then
    for _ in $(seq 1 20); do
      code=$(grep -aF "verification code for $email" "$SERVER_LOG" 2>/dev/null |
        tail -1 | sed -E 's/.*: ([0-9]{4,8}).*/\1/')
      [ -n "${code:-}" ] && break
      sleep 0.5
    done
    token=$(curl -sS -X POST "$API/api/auth/verify-email" \
      -H 'Content-Type: application/json' \
      -d "{\"email\":\"$email\",\"code\":\"$code\"}" |
      python3 -c 'import json,sys;print(json.load(sys.stdin).get("access_token",""))')
  fi
  [ -n "$token" ] || { echo "auth failed for $email: $reg" >&2; exit 1; }
  printf '%s' "$token"
}

say "Регистрация двух игроков"
A=$(register "a$(date +%s)$RANDOM")
B=$(register "b$(date +%s)$RANDOM")
echo "оба игрока авторизованы"

say "Игрок A ищет соперника (режим $MODE)"
CREATE_A=$(curl -sS -X POST "$API/api/games/nardy/lobby" \
  -H "Authorization: Bearer $A" -H 'Content-Type: application/json' \
  -d "{\"mode\":\"matchmake\",\"game_mode\":\"$MODE\",\"turn_time_sec\":0,\"stake_bronze\":2}")
echo "$CREATE_A"

say "Игрок B ищет соперника — должен попасть в то же лобби"
CREATE_B=$(curl -sS -X POST "$API/api/games/nardy/lobby" \
  -H "Authorization: Bearer $B" -H 'Content-Type: application/json' \
  -d "{\"mode\":\"matchmake\",\"game_mode\":\"$MODE\",\"turn_time_sec\":0,\"stake_bronze\":2}")
echo "$CREATE_B"

GAME_ID=$(printf '%s' "$CREATE_B" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("game_id",""))')
if [ -z "$GAME_ID" ]; then
  echo "matchmaking did not start a game" >&2
  exit 1
fi
echo "game_id=$GAME_ID"

say "Играем партию за обоих"
python3 - "$API" "$GAME_ID" "$A" "$B" "$MODE" <<'PY'
import json, sys, urllib.request

api, game_id, token_a, token_b, mode = sys.argv[1:6]


def call(token, path, payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(
        f"{api}{path}",
        data=data,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        method="POST" if data else "GET",
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read() or b"{}")


view_a = call(token_a, f"/api/games/nardy/game/{game_id}")
print("mode      :", view_a["game_mode"], "expected:", mode)
assert view_a["game_mode"] == mode
print("seats     :", [p["user_id"][:8] for p in view_a["players"]])
view_b = call(token_b, f"/api/games/nardy/game/{game_id}")
assert view_a["my_index"] != view_b["my_index"], "players must sit on different seats"
assert view_a["is_my_turn"] != view_b["is_my_turn"], "exactly one player moves"
print("my_index A/B:", view_a["my_index"], view_b["my_index"])

# Ход соперника недоступен второму игроку — сервер не должен его принять.
waiting = token_a if not view_a["is_my_turn"] else token_b
idle_view = view_a if not view_a["is_my_turn"] else view_b
try:
    call(waiting, f"/api/games/nardy/game/{game_id}/move", {"action": "roll"})
    raise AssertionError("server accepted a move out of turn")
except urllib.error.HTTPError as err:
    print("out-of-turn move rejected:", err.code)

turns = 0
for step in range(6000):
    for token in (token_a, token_b):
        view = call(token, f"/api/games/nardy/game/{game_id}")
        if view["is_over"]:
            print(f"finished: winner_index={view['winner_index']} "
                  f"kind={view['win_kind']} off={view['off']} turns={turns}")
            total = [view["off"][s] + view["bar"][s] for s in (0, 1)]
            for point in view["board"]:
                if point > 0:
                    total[0] += point
                elif point < 0:
                    total[1] += -point
            assert total == [15, 15], f"checker count broken: {total}"
            sys.exit(0)
        if not view["is_my_turn"]:
            continue
        if view["needs_roll"]:
            call(token, f"/api/games/nardy/game/{game_id}/move", {"action": "roll"})
            turns += 1
            continue
        legal = view["legal_moves"]
        if not legal:
            call(token, f"/api/games/nardy/game/{game_id}/move", {"action": "end_turn"})
            continue
        mv = max(legal, key=lambda m: m["from"] + m["die"])
        call(token, f"/api/games/nardy/game/{game_id}/move",
             {"action": "move", "from": mv["from"], "die": mv["die"]})

print("game did not finish", file=sys.stderr)
sys.exit(1)
PY

say "Статистика игрока A"
curl -sS "$API/api/games/stats" -H "Authorization: Bearer $A" |
  python3 -c 'import json,sys;print(json.dumps(json.load(sys.stdin), ensure_ascii=False)[:700])'
