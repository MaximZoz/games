#!/usr/bin/env python3
"""Добавляет ключ «Поиск игроков» во все client/lib/l10n/app_*.arb.

Ключ вставляется после `lobbySearchShort`, чтобы блок лобби оставался цельным.
Уже существующие ключи не трогаем.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

ANCHOR = "lobbySearchShort"
KEY = "lobbySearchPlayers"

TRANSLATIONS: dict[str, str] = {
    "ru": "Поиск игроков",
    "en": "Find players",
    "uk": "Пошук гравців",
    "be": "Пошук гульцоў",
    "kk": "Ойыншы іздеу",
    "uz": "O‘yinchi qidirish",
    "de": "Spieler suchen",
    "fr": "Chercher des joueurs",
    "es": "Buscar jugadores",
    "it": "Cerca giocatori",
    "pt": "Procurar jogadores",
    "pl": "Szukaj graczy",
    "nl": "Spelers zoeken",
    "cs": "Hledat hráče",
    "sv": "Sök spelare",
    "nb": "Finn spillere",
    "da": "Find spillere",
    "fi": "Etsi pelaajia",
    "el": "Αναζήτηση παικτών",
    "tr": "Oyuncu ara",
    "he": "חיפוש שחקנים",
    "ar": "البحث عن لاعبين",
    "hi": "खिलाड़ी खोजें",
    "th": "ค้นหาผู้เล่น",
    "vi": "Tìm người chơi",
    "id": "Cari pemain",
    "zh": "寻找玩家",
    "ja": "プレイヤーを探す",
    "ko": "플레이어 찾기",
}


def indent_of(line: str) -> str:
    return line[: len(line) - len(line.lstrip())]


def main() -> int:
    l10n_dir = pathlib.Path("client/lib/l10n")
    files = sorted(l10n_dir.glob("app_*.arb"))
    if not files:
        print("no arb files found", file=sys.stderr)
        return 1
    fallback: list[str] = []
    for path in files:
        locale = path.stem.removeprefix("app_")
        value = TRANSLATIONS.get(locale) or TRANSLATIONS.get(locale.split("_")[0])
        if value is None:
            fallback.append(locale)
            value = TRANSLATIONS["en"]
        data = json.loads(path.read_text(encoding="utf-8"))
        if KEY in data:
            continue
        lines = path.read_text(encoding="utf-8").splitlines()
        placed = False
        for index, line in enumerate(lines):
            if not re.match(rf'\s*"{ANCHOR}"\s*:', line):
                continue
            pad = indent_of(line)
            if not lines[index].rstrip().endswith(","):
                lines[index] = lines[index].rstrip() + ","
            entry = (
                f"{pad}{json.dumps(KEY, ensure_ascii=False)}: "
                f"{json.dumps(value, ensure_ascii=False)},"
            )
            tail = lines[index + 1 :]
            if not any(item.strip() for item in tail if item.strip() != "}"):
                entry = entry.rstrip(",")
            lines.insert(index + 1, entry)
            placed = True
            break
        if not placed:
            print(f"{path}: anchor {ANCHOR} not found", file=sys.stderr)
            return 1
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"{path.name}: +1 key")
    if fallback:
        print(f"fallback to English for: {', '.join(fallback)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
