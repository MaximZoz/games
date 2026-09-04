#!/usr/bin/env python3
"""Добавляет ключи «Поиск», «Отказ» и правило шести подряд в app_*.arb.

Каждый ключ вставляется после своего якоря, чтобы блоки лобби и правил нард
оставались цельными. Уже существующие ключи не трогаем.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

# key -> anchor key, после которого вставляем
ANCHORS = {
    "rulesNardySixPrime": "rulesNardyWin",
    "lobbyInviteDeclinedShort": "lobbyInviteSentShort",
    "lobbySearchShort": "lobbyInviteSentShort",
}

TRANSLATIONS: dict[str, dict[str, str]] = {
    "ru": {
        "rulesNardySixPrime": "Шесть своих пунктов подряд запирать нельзя, пока их не обошла хотя бы одна шашка соперника.",
        "lobbyInviteDeclinedShort": "Отказ",
        "lobbySearchShort": "Поиск",
    },
    "en": {
        "rulesNardySixPrime": "You may not seal six points in a row until at least one opposing checker has passed them.",
        "lobbyInviteDeclinedShort": "Declined",
        "lobbySearchShort": "Search",
    },
    "uk": {
        "rulesNardySixPrime": "Шість своїх пунктів поспіль замикати не можна, доки їх не обійшла жодна шашка суперника.",
        "lobbyInviteDeclinedShort": "Відмова",
        "lobbySearchShort": "Пошук",
    },
    "be": {
        "rulesNardySixPrime": "Шэсць сваіх пунктаў запар замыкаць нельга, пакуль іх не абышла ніводная шашка суперніка.",
        "lobbyInviteDeclinedShort": "Адмова",
        "lobbySearchShort": "Пошук",
    },
    "kk": {
        "rulesNardySixPrime": "Қарсыластың бірде-бір тасы өтпейінше, қатарынан алты пунктті бекітуге болмайды.",
        "lobbyInviteDeclinedShort": "Бас тарту",
        "lobbySearchShort": "Іздеу",
    },
    "uz": {
        "rulesNardySixPrime": "Raqibning birorta toshi o‘tmaguncha, ketma-ket oltita punktni yopib bo‘lmaydi.",
        "lobbyInviteDeclinedShort": "Rad etildi",
        "lobbySearchShort": "Qidiruv",
    },
    "de": {
        "rulesNardySixPrime": "Sechs Punkte in Folge darfst du erst sperren, wenn mindestens ein gegnerischer Stein daran vorbei ist.",
        "lobbyInviteDeclinedShort": "Abgelehnt",
        "lobbySearchShort": "Suche",
    },
    "fr": {
        "rulesNardySixPrime": "Vous ne pouvez pas verrouiller six cases d’affilée tant qu’aucun pion adverse ne les a dépassées.",
        "lobbyInviteDeclinedShort": "Refusé",
        "lobbySearchShort": "Recherche",
    },
    "es": {
        "rulesNardySixPrime": "No puedes cerrar seis casillas seguidas mientras ninguna ficha rival las haya pasado.",
        "lobbyInviteDeclinedShort": "Rechazado",
        "lobbySearchShort": "Buscar",
    },
    "it": {
        "rulesNardySixPrime": "Non puoi chiudere sei punti di fila finché nessuna pedina avversaria li ha superati.",
        "lobbyInviteDeclinedShort": "Rifiutato",
        "lobbySearchShort": "Cerca",
    },
    "pt": {
        "rulesNardySixPrime": "Não é permitido fechar seis pontos seguidos enquanto nenhuma peça adversária os tiver passado.",
        "lobbyInviteDeclinedShort": "Recusado",
        "lobbySearchShort": "Buscar",
    },
    "pl": {
        "rulesNardySixPrime": "Nie możesz zamknąć sześciu pól z rzędu, dopóki nie minie ich żaden pionek przeciwnika.",
        "lobbyInviteDeclinedShort": "Odrzucono",
        "lobbySearchShort": "Szukaj",
    },
    "nl": {
        "rulesNardySixPrime": "Je mag pas zes punten op rij sluiten als minstens één schijf van de tegenstander erlangs is.",
        "lobbyInviteDeclinedShort": "Geweigerd",
        "lobbySearchShort": "Zoeken",
    },
    "cs": {
        "rulesNardySixPrime": "Šest polí za sebou nesmíš uzavřít, dokud je nemine alespoň jeden soupeřův kámen.",
        "lobbyInviteDeclinedShort": "Odmítnuto",
        "lobbySearchShort": "Hledat",
    },
    "sv": {
        "rulesNardySixPrime": "Du får inte stänga sex punkter i rad förrän minst en av motståndarens brickor har passerat dem.",
        "lobbyInviteDeclinedShort": "Avböjt",
        "lobbySearchShort": "Sök",
    },
    "nb": {
        "rulesNardySixPrime": "Du kan ikke stenge seks punkter på rad før minst én av motstanderens brikker har passert dem.",
        "lobbyInviteDeclinedShort": "Avslått",
        "lobbySearchShort": "Søk",
    },
    "da": {
        "rulesNardySixPrime": "Du må ikke lukke seks felter i træk, før mindst én af modstanderens brikker er kommet forbi.",
        "lobbyInviteDeclinedShort": "Afvist",
        "lobbySearchShort": "Søg",
    },
    "fi": {
        "rulesNardySixPrime": "Kuutta peräkkäistä pistettä ei saa sulkea ennen kuin vähintään yksi vastustajan nappula on ohittanut ne.",
        "lobbyInviteDeclinedShort": "Hylätty",
        "lobbySearchShort": "Haku",
    },
    "el": {
        "rulesNardySixPrime": "Δεν μπορείτε να κλείσετε έξι συνεχόμενα σημεία όσο κανένα πούλι του αντιπάλου δεν τα έχει προσπεράσει.",
        "lobbyInviteDeclinedShort": "Απορρίφθηκε",
        "lobbySearchShort": "Αναζήτηση",
    },
    "tr": {
        "rulesNardySixPrime": "Rakibin hiçbir pulu geçmeden art arda altı haneyi kapatamazsınız.",
        "lobbyInviteDeclinedShort": "Reddedildi",
        "lobbySearchShort": "Ara",
    },
    "he": {
        "rulesNardySixPrime": "אי אפשר לחסום שש נקודות ברצף כל עוד אף כלי של היריב לא עבר אותן.",
        "lobbyInviteDeclinedShort": "נדחה",
        "lobbySearchShort": "חיפוש",
    },
    "ar": {
        "rulesNardySixPrime": "لا يمكنك إغلاق ست نقاط متتالية ما لم يتجاوزها حجر واحد للخصم على الأقل.",
        "lobbyInviteDeclinedShort": "مرفوض",
        "lobbySearchShort": "بحث",
    },
    "hi": {
        "rulesNardySixPrime": "जब तक विरोधी की कोई गोटी उन्हें पार न कर ले, लगातार छह बिंदु बंद नहीं किए जा सकते।",
        "lobbyInviteDeclinedShort": "अस्वीकृत",
        "lobbySearchShort": "खोज",
    },
    "th": {
        "rulesNardySixPrime": "ห้ามปิดหกช่องติดกันจนกว่าหมากของคู่แข่งอย่างน้อยหนึ่งตัวจะผ่านไปแล้ว",
        "lobbyInviteDeclinedShort": "ปฏิเสธ",
        "lobbySearchShort": "ค้นหา",
    },
    "vi": {
        "rulesNardySixPrime": "Bạn không được khóa sáu điểm liên tiếp khi chưa có quân nào của đối thủ vượt qua.",
        "lobbyInviteDeclinedShort": "Đã từ chối",
        "lobbySearchShort": "Tìm",
    },
    "id": {
        "rulesNardySixPrime": "Anda tidak boleh menutup enam titik berturut-turut selama belum ada bidak lawan yang melewatinya.",
        "lobbyInviteDeclinedShort": "Ditolak",
        "lobbySearchShort": "Cari",
    },
    "zh": {
        "rulesNardySixPrime": "在对手没有任何棋子越过之前，不能连续封锁六个点。",
        "lobbyInviteDeclinedShort": "已拒绝",
        "lobbySearchShort": "搜索",
    },
    "ja": {
        "rulesNardySixPrime": "相手の駒が一つも通過していないうちは、6 か所を連続で封鎖できません。",
        "lobbyInviteDeclinedShort": "辞退",
        "lobbySearchShort": "検索",
    },
    "ko": {
        "rulesNardySixPrime": "상대 말이 하나도 지나가지 않은 상태에서는 여섯 칸을 연속으로 막을 수 없습니다.",
        "lobbyInviteDeclinedShort": "거절함",
        "lobbySearchShort": "검색",
    },
}


def indent_of(line: str) -> str:
    return line[: len(line) - len(line.lstrip())]


def insert_after(lines: list[str], anchor: str, key: str, value: str) -> bool:
    for index, line in enumerate(lines):
        if not re.match(rf'\s*"{anchor}"\s*:', line):
            continue
        pad = indent_of(line)
        if not lines[index].rstrip().endswith(","):
            lines[index] = lines[index].rstrip() + ","
        entry = (
            f"{pad}{json.dumps(key, ensure_ascii=False)}: "
            f"{json.dumps(value, ensure_ascii=False)},"
        )
        tail = lines[index + 1 :]
        if not any(item.strip() for item in tail if item.strip() != "}"):
            entry = entry.rstrip(",")
        lines.insert(index + 1, entry)
        return True
    return False


def main() -> int:
    l10n_dir = pathlib.Path("client/lib/l10n")
    files = sorted(l10n_dir.glob("app_*.arb"))
    if not files:
        print("no arb files found", file=sys.stderr)
        return 1
    fallback: list[str] = []
    for path in files:
        locale = path.stem.removeprefix("app_")
        table = TRANSLATIONS.get(locale) or TRANSLATIONS.get(locale.split("_")[0])
        if table is None:
            fallback.append(locale)
            table = TRANSLATIONS["en"]
        data = json.loads(path.read_text(encoding="utf-8"))
        lines = path.read_text(encoding="utf-8").splitlines()
        added = 0
        for key, anchor in ANCHORS.items():
            if key in data:
                continue
            if not insert_after(lines, anchor, key, table[key]):
                print(f"{path}: anchor {anchor} not found", file=sys.stderr)
                return 1
            added += 1
        if added:
            path.write_text("\n".join(lines) + "\n", encoding="utf-8")
            print(f"{path.name}: +{added} keys")
    if fallback:
        print(f"fallback to English for: {', '.join(fallback)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
