#!/usr/bin/env python3
"""Добавляет ключи нард во все client/lib/l10n/app_*.arb.

Ключи вставляются сразу после "rulesNardyWin", чтобы блок нард оставался
цельным. Уже существующие ключи не трогаем.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

ANCHOR = "rulesNardyWin"

TRANSLATIONS: dict[str, dict[str, str]] = {
    "ru": {
        "nardyRoll": "Бросить",
        "nardySkipTurn": "Пропустить ход",
        "nardyNoMoves": "Ходов нет — пропустите ход",
        "nardyYourRoll": "Ваш бросок",
        "nardyPipsShort": "Осталось:",
        "nardyYouWonMars": "Вы выиграли — марс!",
        "nardyYouLostMars": "Поражение — марс",
        "rulesNardyOfflineBot": "Офлайн: партия против бота.",
    },
    "en": {
        "nardyRoll": "Roll",
        "nardySkipTurn": "Skip turn",
        "nardyNoMoves": "No moves — skip the turn",
        "nardyYourRoll": "Your roll",
        "nardyPipsShort": "Left:",
        "nardyYouWonMars": "You won — gammon!",
        "nardyYouLostMars": "You lost — gammon",
        "rulesNardyOfflineBot": "Offline: a game against the bot.",
    },
    "uk": {
        "nardyRoll": "Кинути",
        "nardySkipTurn": "Пропустити хід",
        "nardyNoMoves": "Ходів немає — пропустіть хід",
        "nardyYourRoll": "Ваш кидок",
        "nardyPipsShort": "Залишилось:",
        "nardyYouWonMars": "Ви виграли — марс!",
        "nardyYouLostMars": "Поразка — марс",
        "rulesNardyOfflineBot": "Офлайн: партія проти бота.",
    },
    "be": {
        "nardyRoll": "Кінуць",
        "nardySkipTurn": "Прапусціць ход",
        "nardyNoMoves": "Хадоў няма — прапусціце ход",
        "nardyYourRoll": "Ваш кідок",
        "nardyPipsShort": "Засталося:",
        "nardyYouWonMars": "Вы выйгралі — марс!",
        "nardyYouLostMars": "Паражэнне — марс",
        "rulesNardyOfflineBot": "Афлайн: партыя супраць бота.",
    },
    "kk": {
        "nardyRoll": "Лақтыру",
        "nardySkipTurn": "Жүрісті өткізу",
        "nardyNoMoves": "Жүріс жоқ — жүрісті өткізіңіз",
        "nardyYourRoll": "Сіздің лақтыруыңыз",
        "nardyPipsShort": "Қалды:",
        "nardyYouWonMars": "Сіз жеңдіңіз — марс!",
        "nardyYouLostMars": "Жеңіліс — марс",
        "rulesNardyOfflineBot": "Офлайн: ботпен ойын.",
    },
    "uz": {
        "nardyRoll": "Tashlash",
        "nardySkipTurn": "Yurishni o‘tkazish",
        "nardyNoMoves": "Yurish yo‘q — yurishni o‘tkazing",
        "nardyYourRoll": "Sizning tashlashingiz",
        "nardyPipsShort": "Qoldi:",
        "nardyYouWonMars": "Siz yutdingiz — mars!",
        "nardyYouLostMars": "Mag‘lubiyat — mars",
        "rulesNardyOfflineBot": "Oflayn: bot bilan o‘yin.",
    },
    "az": {
        "nardyRoll": "At",
        "nardySkipTurn": "Gedişi ötür",
        "nardyNoMoves": "Gediş yoxdur — gedişi ötürün",
        "nardyYourRoll": "Sizin atışınız",
        "nardyPipsShort": "Qalıb:",
        "nardyYouWonMars": "Qazandınız — mars!",
        "nardyYouLostMars": "Məğlubiyyət — mars",
        "rulesNardyOfflineBot": "Oflayn: botla oyun.",
    },
    "hy": {
        "nardyRoll": "Նետել",
        "nardySkipTurn": "Բաց թողնել քայլը",
        "nardyNoMoves": "Քայլ չկա — բաց թողեք",
        "nardyYourRoll": "Ձեր նետումը",
        "nardyPipsShort": "Մնացել է՝",
        "nardyYouWonMars": "Դուք հաղթեցիք — մարս:",
        "nardyYouLostMars": "Պարտություն — մարս",
        "rulesNardyOfflineBot": "Օֆլայն՝ խաղ բոտի դեմ:",
    },
    "ka": {
        "nardyRoll": "სროლა",
        "nardySkipTurn": "სვლის გამოტოვება",
        "nardyNoMoves": "სვლა არ არის — გამოტოვეთ",
        "nardyYourRoll": "თქვენი სროლა",
        "nardyPipsShort": "დარჩა:",
        "nardyYouWonMars": "თქვენ მოიგეთ — მარსი!",
        "nardyYouLostMars": "წაგება — მარსი",
        "rulesNardyOfflineBot": "ოფლაინი: თამაში ბოტთან.",
    },
    "tr": {
        "nardyRoll": "Zar at",
        "nardySkipTurn": "Sırayı geç",
        "nardyNoMoves": "Hamle yok — sırayı geçin",
        "nardyYourRoll": "Zarınız",
        "nardyPipsShort": "Kalan:",
        "nardyYouWonMars": "Kazandınız — mars!",
        "nardyYouLostMars": "Kaybettiniz — mars",
        "rulesNardyOfflineBot": "Çevrimdışı: bota karşı oyun.",
    },
    "de": {
        "nardyRoll": "Würfeln",
        "nardySkipTurn": "Zug überspringen",
        "nardyNoMoves": "Kein Zug möglich — überspringen",
        "nardyYourRoll": "Dein Wurf",
        "nardyPipsShort": "Rest:",
        "nardyYouWonMars": "Gewonnen — Gammon!",
        "nardyYouLostMars": "Verloren — Gammon",
        "rulesNardyOfflineBot": "Offline: Partie gegen den Bot.",
    },
    "fr": {
        "nardyRoll": "Lancer",
        "nardySkipTurn": "Passer le tour",
        "nardyNoMoves": "Aucun coup — passez le tour",
        "nardyYourRoll": "Votre lancer",
        "nardyPipsShort": "Reste :",
        "nardyYouWonMars": "Vous gagnez — gammon !",
        "nardyYouLostMars": "Défaite — gammon",
        "rulesNardyOfflineBot": "Hors ligne : partie contre le bot.",
    },
    "es": {
        "nardyRoll": "Tirar",
        "nardySkipTurn": "Pasar turno",
        "nardyNoMoves": "Sin jugadas — pasa el turno",
        "nardyYourRoll": "Tu tirada",
        "nardyPipsShort": "Quedan:",
        "nardyYouWonMars": "¡Ganaste — gammon!",
        "nardyYouLostMars": "Derrota — gammon",
        "rulesNardyOfflineBot": "Sin conexión: partida contra el bot.",
    },
    "pt": {
        "nardyRoll": "Lançar",
        "nardySkipTurn": "Passar a vez",
        "nardyNoMoves": "Sem jogadas — passe a vez",
        "nardyYourRoll": "Seu lançamento",
        "nardyPipsShort": "Faltam:",
        "nardyYouWonMars": "Você venceu — gammon!",
        "nardyYouLostMars": "Derrota — gammon",
        "rulesNardyOfflineBot": "Offline: partida contra o bot.",
    },
    "it": {
        "nardyRoll": "Lancia",
        "nardySkipTurn": "Salta il turno",
        "nardyNoMoves": "Nessuna mossa — salta il turno",
        "nardyYourRoll": "Il tuo lancio",
        "nardyPipsShort": "Restano:",
        "nardyYouWonMars": "Hai vinto — gammon!",
        "nardyYouLostMars": "Sconfitta — gammon",
        "rulesNardyOfflineBot": "Offline: partita contro il bot.",
    },
    "pl": {
        "nardyRoll": "Rzuć",
        "nardySkipTurn": "Pomiń turę",
        "nardyNoMoves": "Brak ruchów — pomiń turę",
        "nardyYourRoll": "Twój rzut",
        "nardyPipsShort": "Zostało:",
        "nardyYouWonMars": "Wygrana — gammon!",
        "nardyYouLostMars": "Porażka — gammon",
        "rulesNardyOfflineBot": "Offline: gra z botem.",
    },
    "nl": {
        "nardyRoll": "Gooien",
        "nardySkipTurn": "Beurt overslaan",
        "nardyNoMoves": "Geen zetten — sla de beurt over",
        "nardyYourRoll": "Jouw worp",
        "nardyPipsShort": "Resterend:",
        "nardyYouWonMars": "Gewonnen — gammon!",
        "nardyYouLostMars": "Verloren — gammon",
        "rulesNardyOfflineBot": "Offline: partij tegen de bot.",
    },
    "cs": {
        "nardyRoll": "Hodit",
        "nardySkipTurn": "Přeskočit tah",
        "nardyNoMoves": "Žádné tahy — přeskočte tah",
        "nardyYourRoll": "Váš hod",
        "nardyPipsShort": "Zbývá:",
        "nardyYouWonMars": "Vyhráli jste — gammon!",
        "nardyYouLostMars": "Prohra — gammon",
        "rulesNardyOfflineBot": "Offline: hra proti botovi.",
    },
    "sv": {
        "nardyRoll": "Slå",
        "nardySkipTurn": "Hoppa över turen",
        "nardyNoMoves": "Inga drag — hoppa över turen",
        "nardyYourRoll": "Ditt slag",
        "nardyPipsShort": "Kvar:",
        "nardyYouWonMars": "Du vann — gammon!",
        "nardyYouLostMars": "Förlust — gammon",
        "rulesNardyOfflineBot": "Offline: parti mot boten.",
    },
    "ro": {
        "nardyRoll": "Aruncă",
        "nardySkipTurn": "Sari tura",
        "nardyNoMoves": "Nicio mutare — sari tura",
        "nardyYourRoll": "Aruncarea ta",
        "nardyPipsShort": "Rămas:",
        "nardyYouWonMars": "Ai câștigat — marț!",
        "nardyYouLostMars": "Înfrângere — marț",
        "rulesNardyOfflineBot": "Offline: partidă cu botul.",
    },
    "el": {
        "nardyRoll": "Ρίξε",
        "nardySkipTurn": "Παράλειψη σειράς",
        "nardyNoMoves": "Καμία κίνηση — παραλείψτε τη σειρά",
        "nardyYourRoll": "Η ζαριά σας",
        "nardyPipsShort": "Απομένουν:",
        "nardyYouWonMars": "Κερδίσατε — μαρς!",
        "nardyYouLostMars": "Ήττα — μαρς",
        "rulesNardyOfflineBot": "Εκτός σύνδεσης: παιχνίδι με το bot.",
    },
    "he": {
        "nardyRoll": "הטל",
        "nardySkipTurn": "דלג על התור",
        "nardyNoMoves": "אין מהלכים — דלג על התור",
        "nardyYourRoll": "ההטלה שלך",
        "nardyPipsShort": "נותרו:",
        "nardyYouWonMars": "ניצחת — מארס!",
        "nardyYouLostMars": "הפסד — מארס",
        "rulesNardyOfflineBot": "לא מקוון: משחק מול הבוט.",
    },
    "ar": {
        "nardyRoll": "ارمِ النرد",
        "nardySkipTurn": "تخطَّ الدور",
        "nardyNoMoves": "لا توجد نقلات — تخطَّ الدور",
        "nardyYourRoll": "رميتك",
        "nardyPipsShort": "المتبقي:",
        "nardyYouWonMars": "فزت — مارس!",
        "nardyYouLostMars": "خسارة — مارس",
        "rulesNardyOfflineBot": "دون اتصال: مباراة ضد البوت.",
    },
    "fa": {
        "nardyRoll": "تاس بینداز",
        "nardySkipTurn": "رد کردن نوبت",
        "nardyNoMoves": "حرکتی نیست — نوبت را رد کنید",
        "nardyYourRoll": "تاس شما",
        "nardyPipsShort": "باقی‌مانده:",
        "nardyYouWonMars": "بردید — مارس!",
        "nardyYouLostMars": "باخت — مارس",
        "rulesNardyOfflineBot": "آفلاین: بازی با ربات.",
    },
    "hi": {
        "nardyRoll": "पासा फेंकें",
        "nardySkipTurn": "बारी छोड़ें",
        "nardyNoMoves": "कोई चाल नहीं — बारी छोड़ें",
        "nardyYourRoll": "आपका पासा",
        "nardyPipsShort": "शेष:",
        "nardyYouWonMars": "आप जीते — गैमन!",
        "nardyYouLostMars": "हार — गैमन",
        "rulesNardyOfflineBot": "ऑफ़लाइन: बॉट के साथ खेल।",
    },
    "zh": {
        "nardyRoll": "掷骰",
        "nardySkipTurn": "跳过回合",
        "nardyNoMoves": "无棋可走 — 跳过回合",
        "nardyYourRoll": "你的掷骰",
        "nardyPipsShort": "剩余：",
        "nardyYouWonMars": "你赢了 — 双倍胜！",
        "nardyYouLostMars": "失败 — 双倍负",
        "rulesNardyOfflineBot": "离线：与机器人对战。",
    },
    "ja": {
        "nardyRoll": "サイコロを振る",
        "nardySkipTurn": "手番をパス",
        "nardyNoMoves": "動かせません — 手番をパス",
        "nardyYourRoll": "あなたの出目",
        "nardyPipsShort": "残り:",
        "nardyYouWonMars": "勝利 — ギャモン！",
        "nardyYouLostMars": "敗北 — ギャモン",
        "rulesNardyOfflineBot": "オフライン: ボットとの対戦。",
    },
    "ko": {
        "nardyRoll": "주사위 굴리기",
        "nardySkipTurn": "차례 넘기기",
        "nardyNoMoves": "둘 수 없음 — 차례를 넘기세요",
        "nardyYourRoll": "당신의 주사위",
        "nardyPipsShort": "남음:",
        "nardyYouWonMars": "승리 — 개먼!",
        "nardyYouLostMars": "패배 — 개먼",
        "rulesNardyOfflineBot": "오프라인: 봇과의 대국.",
    },
    "id": {
        "nardyRoll": "Lempar dadu",
        "nardySkipTurn": "Lewati giliran",
        "nardyNoMoves": "Tidak ada langkah — lewati giliran",
        "nardyYourRoll": "Lemparan Anda",
        "nardyPipsShort": "Sisa:",
        "nardyYouWonMars": "Anda menang — gammon!",
        "nardyYouLostMars": "Kalah — gammon",
        "rulesNardyOfflineBot": "Offline: bermain melawan bot.",
    },
    "vi": {
        "nardyRoll": "Gieo xúc xắc",
        "nardySkipTurn": "Bỏ lượt",
        "nardyNoMoves": "Không có nước đi — bỏ lượt",
        "nardyYourRoll": "Lượt gieo của bạn",
        "nardyPipsShort": "Còn lại:",
        "nardyYouWonMars": "Bạn thắng — gammon!",
        "nardyYouLostMars": "Thua — gammon",
        "rulesNardyOfflineBot": "Ngoại tuyến: chơi với bot.",
    },
}


def locale_of(path: pathlib.Path) -> str:
    return path.stem.removeprefix("app_")


def indent_of(line: str) -> str:
    return line[: len(line) - len(line.lstrip())]


def main() -> int:
    l10n_dir = pathlib.Path("client/lib/l10n")
    files = sorted(l10n_dir.glob("app_*.arb"))
    if not files:
        print("no arb files found", file=sys.stderr)
        return 1
    missing_locales: list[str] = []
    for path in files:
        locale = locale_of(path)
        table = TRANSLATIONS.get(locale) or TRANSLATIONS.get(locale.split("_")[0])
        if table is None:
            missing_locales.append(locale)
            table = TRANSLATIONS["en"]
        data = json.loads(path.read_text(encoding="utf-8"))
        pending = {k: v for k, v in table.items() if k not in data}
        if not pending:
            continue
        lines = path.read_text(encoding="utf-8").splitlines()
        anchor_index = None
        for index, line in enumerate(lines):
            if re.match(rf'\s*"{ANCHOR}"\s*:', line):
                anchor_index = index
                break
        if anchor_index is None:
            print(f"{path}: anchor {ANCHOR} not found", file=sys.stderr)
            return 1
        pad = indent_of(lines[anchor_index])
        if not lines[anchor_index].rstrip().endswith(","):
            lines[anchor_index] = lines[anchor_index].rstrip() + ","
        block = [
            f"{pad}{json.dumps(key, ensure_ascii=False)}: "
            f"{json.dumps(value, ensure_ascii=False)},"
            for key, value in pending.items()
        ]
        # Последний ключ файла не должен остаться с висящей запятой.
        tail = lines[anchor_index + 1 :]
        if not any(stripped.strip() for stripped in tail if stripped.strip() != "}"):
            block[-1] = block[-1].rstrip(",")
        lines[anchor_index + 1 : anchor_index + 1] = block
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"{path.name}: +{len(pending)} keys")
    if missing_locales:
        print(f"fallback to English for: {', '.join(missing_locales)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
