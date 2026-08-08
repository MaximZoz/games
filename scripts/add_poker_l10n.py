#!/usr/bin/env python3
"""Добавляет ключи Покера во все app_*.arb."""

from __future__ import annotations

import json
from pathlib import Path

L10N = Path(__file__).resolve().parents[1] / "client" / "lib" / "l10n"

# После gamesDurak — рядом с названиями игр.
AFTER_KEY = "gamesDurak"

KEYS: dict[str, dict[str, str]] = {
    "gamesPoker": {
        "ru": "Покер",
        "en": "Poker",
        "uk": "Покер",
        "be": "Покер",
        "kk": "Покер",
        "uz": "Poker",
        "de": "Poker",
        "da": "Poker",
        "fr": "Poker",
        "es": "Póker",
        "it": "Poker",
        "pt": "Pôquer",
        "pl": "Poker",
        "nl": "Poker",
        "sv": "Poker",
        "nb": "Poker",
        "fi": "Pokeri",
        "cs": "Poker",
        "el": "Πόκερ",
        "tr": "Poker",
        "ar": "بوكر",
        "he": "פוקר",
        "hi": "पोकर",
        "ja": "ポーカー",
        "ko": "포커",
        "zh": "扑克",
        "th": "โป๊กเกอร์",
        "vi": "Poker",
        "id": "Poker",
    },
    "gamesInDevelopment": {
        "ru": "В разработке",
        "en": "In development",
        "uk": "В розробці",
        "be": "У распрацоўцы",
        "kk": "Әзірленуде",
        "uz": "Ishlanmoqda",
        "de": "In Entwicklung",
        "da": "Under udvikling",
        "fr": "En développement",
        "es": "En desarrollo",
        "it": "In sviluppo",
        "pt": "Em desenvolvimento",
        "pl": "W trakcie tworzenia",
        "nl": "In ontwikkeling",
        "sv": "Under utveckling",
        "nb": "Under utvikling",
        "fi": "Kehityksessä",
        "cs": "Ve vývoji",
        "el": "Υπό ανάπτυξη",
        "tr": "Geliştiriliyor",
        "ar": "قيد التطوير",
        "he": "בפיתוח",
        "hi": "विकास में",
        "ja": "開発中",
        "ko": "개발 중",
        "zh": "开发中",
        "th": "กำลังพัฒนา",
        "vi": "Đang phát triển",
        "id": "Dalam pengembangan",
    },
    "rulesPokerPlayers": {
        "ru": "Игроки: {players}.",
        "en": "Players: {players}.",
        "uk": "Гравці: {players}.",
        "be": "Гульцы: {players}.",
        "kk": "Ойыншылар: {players}.",
        "uz": "O‘yinchilar: {players}.",
        "de": "Spieler: {players}.",
        "da": "Spillere: {players}.",
        "fr": "Joueurs : {players}.",
        "es": "Jugadores: {players}.",
        "it": "Giocatori: {players}.",
        "pt": "Jogadores: {players}.",
        "pl": "Gracze: {players}.",
        "nl": "Spelers: {players}.",
        "sv": "Spelare: {players}.",
        "nb": "Spillere: {players}.",
        "fi": "Pelaajat: {players}.",
        "cs": "Hráči: {players}.",
        "el": "Παίκτες: {players}.",
        "tr": "Oyuncular: {players}.",
        "ar": "اللاعبون: {players}.",
        "he": "שחקנים: {players}.",
        "hi": "खिलाड़ी: {players}.",
        "ja": "人数: {players}。",
        "ko": "인원: {players}.",
        "zh": "玩家：{players}。",
        "th": "ผู้เล่น: {players}.",
        "vi": "Người chơi: {players}.",
        "id": "Pemain: {players}.",
    },
    "rulesPokerIntro": {
        "ru": "Техасский холдем. Каждому раздают 2 карты в руку; на стол выходят 5 общих карт.",
        "en": "Texas Hold’em. Each player gets 2 hole cards; 5 community cards are dealt to the table.",
        "uk": "Техаський холдем. Кожному роздають 2 карти в руку; на стіл виходять 5 спільних карт.",
        "be": "Тэхаскі холдэм. Кожнаму раздаюць 2 карты ў руку; на стол выходзяць 5 агульных карт.",
        "kk": "Texas Hold’em. Әр ойыншыға 2 қол картасы беріледі; үстелге 5 ортақ карта шығады.",
        "uz": "Texas Hold’em. Har bir o‘yinchiga 2 ta qo‘l kartasi beriladi; stolga 5 ta umumiy karta chiqadi.",
        "de": "Texas Hold’em. Jeder erhält 2 Handkarten; 5 Gemeinschaftskarten liegen auf dem Tisch.",
        "da": "Texas Hold’em. Hver spiller får 2 hulkort; 5 fælleskort lægges på bordet.",
        "fr": "Texas Hold’em. Chaque joueur reçoit 2 cartes privées ; 5 cartes communes sont mises sur la table.",
        "es": "Texas Hold’em. Cada jugador recibe 2 cartas ocultas; en la mesa salen 5 cartas comunitarias.",
        "it": "Texas Hold’em. Ognuno riceve 2 carte private; sul tavolo escono 5 carte comuni.",
        "pt": "Texas Hold’em. Cada jogador recebe 2 cartas fechadas; 5 cartas comunitárias vão à mesa.",
        "pl": "Texas Hold’em. Każdy dostaje 2 karty własne; na stół wychodzi 5 kart wspólnych.",
        "nl": "Texas Hold’em. Iedereen krijgt 2 hole cards; er komen 5 community cards op tafel.",
        "sv": "Texas Hold’em. Varje spelare får 2 hålkort; 5 gemensamma kort läggs på bordet.",
        "nb": "Texas Hold’em. Hver spiller får 2 hullkort; 5 felleskort legges på bordet.",
        "fi": "Texas Hold’em. Jokainen saa 2 taskukorttia; pöytään jaetaan 5 yhteistä korttia.",
        "cs": "Texas Hold’em. Každý dostane 2 soukromé karty; na stůl přijde 5 společných karet.",
        "el": "Texas Hold’em. Κάθε παίκτης παίρνει 2 ιδιωτικά φύλλα· στο τραπέζι βγαίνουν 5 κοινά.",
        "tr": "Texas Hold’em. Her oyuncuya 2 kapalı kart verilir; masaya 5 ortak kart gelir.",
        "ar": "تكساس هولدم. يحصل كل لاعب على ورقتين خاصتين؛ وتُوضع 5 أوراق مشتركة على الطاولة.",
        "he": "טקסס הולדם. לכל שחקן 2 קלפים פרטיים; על השולחן יוצאים 5 קלפים קהילתיים.",
        "hi": "टेक्सास होल्ड’एम। हर खिलाड़ी को 2 होल कार्ड मिलते हैं; टेबल पर 5 कम्युनिटी कार्ड आते हैं।",
        "ja": "テキサスホールデム。各プレイヤーにホールカード2枚、場にコミュニティカード5枚。",
        "ko": "텍사스 홀덤. 각 플레이어는 홀 카드 2장, 테이블에 커뮤니티 카드 5장이 나옵니다.",
        "zh": "德州扑克。每人两张底牌；桌上发出五张公共牌。",
        "th": "เท็กซัสโฮลเด็ม ผู้เล่นได้ไพ่ส่วนตัว 2 ใบ และไพ่กลาง 5 ใบบนโต๊ะ",
        "vi": "Texas Hold’em. Mỗi người nhận 2 lá bài riêng; bàn có 5 lá bài chung.",
        "id": "Texas Hold’em. Setiap pemain mendapat 2 hole card; 5 community card di meja.",
    },
    "rulesPokerPlay": {
        "ru": "Раунды ставок: префлоп, флоп, тёрн и ривер. Можно фолд, колл, бет или рейз.",
        "en": "Betting rounds: preflop, flop, turn and river. You can fold, call, bet or raise.",
        "uk": "Раунди ставок: префлоп, флоп, терн і рівер. Можна фолд, колл, бет або рейз.",
        "be": "Раўнды ставак: прэфлоп, флоп, тэрн і рывер. Можна фолд, колл, бет ці рэйз.",
        "kk": "Ставка раундтары: префлоп, флоп, терн және ривер. Фолд, колл, бет немесе рейз жасауға болады.",
        "uz": "Stavka raundlari: preflop, flop, turn va river. Fold, call, bet yoki raise qilish mumkin.",
        "de": "Wettrunden: Preflop, Flop, Turn und River. Fold, Call, Bet oder Raise.",
        "da": "Indsatserunder: preflop, flop, turn og river. Fold, call, bet eller raise.",
        "fr": "Tours de mise : préflop, flop, turn et river. Fold, call, bet ou raise.",
        "es": "Rondas de apuestas: preflop, flop, turn y river. Puedes fold, call, bet o raise.",
        "it": "Giri di puntate: preflop, flop, turn e river. Puoi foldare, chiamare, puntare o rilanciare.",
        "pt": "Rodadas de apostas: pré-flop, flop, turn e river. Pode dar fold, call, bet ou raise.",
        "pl": "Rundy obstawiania: preflop, flop, turn i river. Fold, call, bet lub raise.",
        "nl": "Inzetrondes: preflop, flop, turn en river. Fold, call, bet of raise.",
        "sv": "Insatserundor: preflop, flop, turn och river. Fold, call, bet eller raise.",
        "nb": "Innsatsrunder: preflop, flop, turn og river. Fold, call, bet eller raise.",
        "fi": "Panoskierrokset: preflop, flop, turn ja river. Fold, call, bet tai raise.",
        "cs": "Sázková kola: preflop, flop, turn a river. Fold, call, bet nebo raise.",
        "el": "Γύροι πονταρίσματος: preflop, flop, turn και river. Fold, call, bet ή raise.",
        "tr": "Bahis turları: preflop, flop, turn ve river. Fold, call, bet veya raise yapabilirsiniz.",
        "ar": "جولات المراهنة: ما قبل الفلوب، الفلوب، الترن والريفر. يمكنك الطي أو المعادلة أو الرهان أو الرفع.",
        "he": "סבבי הימורים: פרה-פלופ, פלופ, טרן וריבר. אפשר לקפל, להשוות, להמר או להעלות.",
        "hi": "बेटिंग राउंड: प्रीफ्लॉप, फ्लॉप, टर्न और रिवर। फोल्ड, कॉल, बेट या रेज़ कर सकते हैं।",
        "ja": "ベッティングラウンドはプリフロップ・フロップ・ターン・リバー。フォールド、コール、ベット、レイズができます。",
        "ko": "베팅 라운드: 프리플롭, 플롭, 턴, 리버. 폴드, 콜, 벳, 레이즈를 할 수 있습니다.",
        "zh": "下注轮次：翻牌前、翻牌、转牌、河牌。可弃牌、跟注、下注或加注。",
        "th": "รอบเดิมพัน: พรีฟล็อป ฟล็อป เทิร์น และริเวอร์ โฟลด คอล เบท หรือเรสได้",
        "vi": "Vòng cược: preflop, flop, turn và river. Có thể fold, call, bet hoặc raise.",
        "id": "Ronde taruhan: preflop, flop, turn, dan river. Bisa fold, call, bet, atau raise.",
    },
    "rulesPokerWin": {
        "ru": "Побеждает лучшая комбинация из пяти карт (свои + общие) или тот, кто остался один после фолдов.",
        "en": "The best five-card hand (hole + community) wins, or the last player left after folds.",
        "uk": "Перемагає найкраща комбінація з п’яти карт (свої + спільні) або той, хто лишився один після фолдів.",
        "be": "Перамагае найлепшая камбінацыя з пяці карт (свае + агульныя) або той, хто застаўся адзін пасля фолдаў.",
        "kk": "Жеңімпаз — бес картаның ең жақсы комбинациясы (қол + ортақ) немесе фолдтан кейін жалғыз қалған ойыншы.",
        "uz": "G‘olib — beshta kartaning eng yaxshi kombinatsiyasi (qo‘l + umumiy) yoki foldlardan keyin yolg‘iz qolgan o‘yinchi.",
        "de": "Gewonnen wird mit der besten Fünf-Karten-Hand (Hand + Community) oder wenn alle anderen folden.",
        "da": "Den bedste femkorts-hånd (hul + fælles) vinder, eller den sidste spiller efter folds.",
        "fr": "Gagne la meilleure main de cinq cartes (privées + communes), ou le dernier joueur après les folds.",
        "es": "Gana la mejor mano de cinco cartas (ocultas + comunitarias), o el último tras los folds.",
        "it": "Vince la migliore mano di cinque carte (private + comuni), oppure l’ultimo dopo i fold.",
        "pt": "Vence a melhor mão de cinco cartas (fechadas + comunitárias), ou o último após folds.",
        "pl": "Wygrywa najlepszy układ z pięciu kart (własne + wspólne) albo ostatni po foldach.",
        "nl": "De beste vijfkaartshand (hole + community) wint, of de laatste speler na folds.",
        "sv": "Bästa femkorts-handen (hål + gemensamma) vinner, eller den siste efter folds.",
        "nb": "Beste femkorts-hånd (hull + felles) vinner, eller siste spiller etter folds.",
        "fi": "Paras viiden kortin käsi (tasku + yhteiset) voittaa, tai viimeinen foldien jälkeen.",
        "cs": "Vyhrává nejlepší pětikombinace (soukromé + společné), nebo poslední po foldech.",
        "el": "Κερδίζει ο καλύτερος συνδυασμός πέντε φύλλων (ιδιωτικά + κοινά) ή ο τελευταίος μετά από folds.",
        "tr": "En iyi beş kartlık el (kapalı + ortak) veya foldlardan sonra kalan son oyuncu kazanır.",
        "ar": "يفوز أفضل خمسة أوراق (خاصة + مشتركة) أو آخر لاعب يتبقى بعد الطي.",
        "he": "מנצחת היד הטובה ביותר מחמישה קלפים (פרטיים + קהילתיים), או השחקן האחרון אחרי קיפולים.",
        "hi": "सबसे अच्छा पाँच-पत्तों का हाथ (होल + कम्युनिटी) जीतता है, या फोल्ड के बाद बचा आखिरी खिलाड़ी।",
        "ja": "ホール＋コミュニティから作った最強の5枚、またはフォールド後に残った一人が勝ちです。",
        "ko": "홀+커뮤니티로 만든 최강 5장 핸드, 또는 폴드 후 남은 한 명이 승리합니다.",
        "zh": "用底牌与公共牌组成的最强五张牌获胜；或其余人弃牌后仅剩者获胜。",
        "th": "มือห้าใบที่ดีที่สุด (ส่วนตัว+กลาง) ชนะ หรือผู้ที่เหลือคนเดียวหลังโฟลด",
        "vi": "Thắng bằng bộ năm lá mạnh nhất (riêng + chung), hoặc người còn lại sau khi người khác fold.",
        "id": "Menang dengan kombinasi lima kartu terbaik (hole + community), atau pemain terakhir setelah fold.",
    },
}

META = {
    "rulesPokerPlayers": {
        "placeholders": {"players": {"type": "int"}},
    },
}


def main() -> None:
    updated = 0
    for path in sorted(L10N.glob("app_*.arb")):
        data = json.loads(path.read_text(encoding="utf-8"))
        locale = data.get("@@locale") or path.stem.split("_", 1)[-1]
        additions: dict[str, object] = {}
        for key, by_lang in KEYS.items():
            if key in data:
                continue
            additions[key] = by_lang.get(locale) or by_lang["en"]
            if key in META:
                additions[f"@{key}"] = META[key]
        if not additions:
            continue
        out: dict = {}
        inserted = False
        for k, v in data.items():
            out[k] = v
            if k == AFTER_KEY and not inserted:
                for ak, av in additions.items():
                    if ak not in out:
                        out[ak] = av
                inserted = True
        for ak, av in additions.items():
            if ak not in out:
                out[ak] = av
        path.write_text(
            json.dumps(out, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        updated += 1
        print(f"+ {path.name}: {len([k for k in additions if not k.startswith('@')])} keys")
    print(f"Done: {updated} files")


if __name__ == "__main__":
    main()
