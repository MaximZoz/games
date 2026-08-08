#!/usr/bin/env python3
"""Переводит ключи правил/режимов Дурака во всех app_*.arb (вместо EN-заглушек)."""

from __future__ import annotations

import json
from pathlib import Path

L10N = Path(__file__).resolve().parents[1] / "client" / "lib" / "l10n"

KEYS = [
    "gamesDurakModePodkidnoi",
    "gamesDurakModePerevodnoi",
    "gamesDurakDeck24",
    "gamesDurakDeck36",
    "gamesDurakDeck52",
    "rulesDurakMode",
    "rulesDurakPlayersDeck",
    "rulesDurakOfflineBot",
    "rulesDurakAttack",
    "rulesDurakBeat",
    "rulesDurakLoser",
]

# Переводы по @@locale. en/ru уже корректны — не трогаем, если совпадают с целевыми.
TR: dict[str, dict[str, str]] = {
    "be": {
        "gamesDurakModePodkidnoi": "Падкідны",
        "gamesDurakModePerevodnoi": "Пераводны",
        "gamesDurakDeck24": "24 карты",
        "gamesDurakDeck36": "36 карт",
        "gamesDurakDeck52": "52 карты",
        "rulesDurakMode": "Рэжым: {mode}",
        "rulesDurakPlayersDeck": "Гульцы: {players}. Калода: {deck}.",
        "rulesDurakOfflineBot": "Гульня супраць бота, без ставак і ліміту часу.",
        "rulesDurakAttack": "Атакуючы кладзе карты, абаронца б’е (той жа масці старэйшай або казырам). Казыр б’ецца толькі старэйшым казырам.",
        "rulesDurakBeat": "Калі ўсе карты біты — атакуючы кажа «Біта», карты ідуць у адбой. Інакш абаронца бярэ ўсё са стала.",
        "rulesDurakLoser": "Прайграўшы — у каго ў канцы партыі засталіся карты, «дурак».",
    },
    "uk": {
        "gamesDurakModePodkidnoi": "Підкидний",
        "gamesDurakModePerevodnoi": "Переводний",
        "gamesDurakDeck24": "24 карти",
        "gamesDurakDeck36": "36 карт",
        "gamesDurakDeck52": "52 карти",
        "rulesDurakMode": "Режим: {mode}",
        "rulesDurakPlayersDeck": "Гравці: {players}. Колода: {deck}.",
        "rulesDurakOfflineBot": "Гра проти бота, без ставок і ліміту часу.",
        "rulesDurakAttack": "Атакувальник кладе карти, захисник б'є (тієї ж масті старшою або козирем). Козир б'ється лише старшим козирем.",
        "rulesDurakBeat": "Коли всі карти биті — атакувальник каже «Бито», карти йдуть у відбій. Інакше захисник бере все зі столу.",
        "rulesDurakLoser": "Програє той, у кого в кінці лишилися карти, — «дурак».",
    },
    "kk": {
        "gamesDurakModePodkidnoi": "Тастамалы",
        "gamesDurakModePerevodnoi": "Аударылмалы",
        "gamesDurakDeck24": "24 карта",
        "gamesDurakDeck36": "36 карта",
        "gamesDurakDeck52": "52 карта",
        "rulesDurakMode": "Режим: {mode}",
        "rulesDurakPlayersDeck": "Ойыншылар: {players}. Колода: {deck}.",
        "rulesDurakOfflineBot": "Ботқа қарсы ойын, ставка мен уақыт шектеуінсіз.",
        "rulesDurakAttack": "Шабуылшы карта салады, қорғаушы ұрады (сол масть жоғарырақ немесе козырь). Козырь тек жоғарырақ козырьмен ұрылады.",
        "rulesDurakBeat": "Барлық карта ұрылғанда шабуылшы «Бита» дейді, карталар отбойға кетеді. Әйтпесе қорғаушы үстелдегінің бәрін алады.",
        "rulesDurakLoser": "Жеңілген — партия соңында карталары қалған ойыншы, «дурак».",
    },
    "uz": {
        "gamesDurakModePodkidnoi": "Tashlama",
        "gamesDurakModePerevodnoi": "O‘tkazmali",
        "gamesDurakDeck24": "24 karta",
        "gamesDurakDeck36": "36 karta",
        "gamesDurakDeck52": "52 karta",
        "rulesDurakMode": "Rejim: {mode}",
        "rulesDurakPlayersDeck": "O‘yinchilar: {players}. Koloda: {deck}.",
        "rulesDurakOfflineBot": "Botga qarshi o‘yin, stavka va vaqt cheklovisiz.",
        "rulesDurakAttack": "Hujumchi kartalar qo‘yadi, himoyachi uradi (shu mast yuqoriroq yoki kozir). Kozir faqat yuqoriroq kozir bilan uriladi.",
        "rulesDurakBeat": "Barcha kartalar urilganda hujumchi «Bito» deydi, kartalar otboyga ketadi. Aks holda himoyachi stoldagi hammasini oladi.",
        "rulesDurakLoser": "Yutqazgan — partiya oxirida kartalari qolgan o‘yinchi, «durak».",
    },
    "de": {
        "gamesDurakModePodkidnoi": "Nachlegen",
        "gamesDurakModePerevodnoi": "Übergeben",
        "gamesDurakDeck24": "24 Karten",
        "gamesDurakDeck36": "36 Karten",
        "gamesDurakDeck52": "52 Karten",
        "rulesDurakMode": "Modus: {mode}",
        "rulesDurakPlayersDeck": "Spieler: {players}. Deck: {deck}.",
        "rulesDurakOfflineBot": "Gegen einen Bot spielen, ohne Einsatz und Zeitlimit.",
        "rulesDurakAttack": "Der Angreifer legt Karten; der Verteidiger schlägt sie (gleiche Farbe höher oder Trumpf). Trumpf nur durch höheren Trumpf.",
        "rulesDurakBeat": "Sind alle Karten geschlagen, sagt der Angreifer „Bito“, und die Karten gehen auf den Ablagestapel. Sonst nimmt der Verteidiger alles.",
        "rulesDurakLoser": "Verlierer ist, wer am Ende noch Karten hat — der „Narr“.",
    },
    "da": {
        "gamesDurakModePodkidnoi": "Efterslag",
        "gamesDurakModePerevodnoi": "Overførsel",
        "gamesDurakDeck24": "24 kort",
        "gamesDurakDeck36": "36 kort",
        "gamesDurakDeck52": "52 kort",
        "rulesDurakMode": "Tilstand: {mode}",
        "rulesDurakPlayersDeck": "Spillere: {players}. Kortspil: {deck}.",
        "rulesDurakOfflineBot": "Spil mod en bot uden indsats eller tid.",
        "rulesDurakAttack": "Angriberen lægger kort; forsvareren slår dem (samme farve højere, eller trumf). Trumf slås kun af højere trumf.",
        "rulesDurakBeat": "Når alle kort er slået, siger angriberen «Slået», og kortene går i bunken. Ellers tager forsvareren alt fra bordet.",
        "rulesDurakLoser": "Taberen er den, der har kort tilbage til sidst — «narren».",
    },
    "fr": {
        "gamesDurakModePodkidnoi": "Relance",
        "gamesDurakModePerevodnoi": "Transfert",
        "gamesDurakDeck24": "24 cartes",
        "gamesDurakDeck36": "36 cartes",
        "gamesDurakDeck52": "52 cartes",
        "rulesDurakMode": "Mode : {mode}",
        "rulesDurakPlayersDeck": "Joueurs : {players}. Jeu : {deck}.",
        "rulesDurakOfflineBot": "Jouez contre un bot, sans mise ni limite de temps.",
        "rulesDurakAttack": "L’attaquant pose des cartes ; le défenseur les bat (même couleur plus haute, ou un atout). Un atout ne se bat que par un atout plus haut.",
        "rulesDurakBeat": "Quand toutes les cartes sont battues, l’attaquant dit « Battu » et les cartes vont au discard. Sinon le défenseur prend tout sur la table.",
        "rulesDurakLoser": "Le perdant est celui qui a encore des cartes à la fin — le « durak ».",
    },
    "es": {
        "gamesDurakModePodkidnoi": "Apoyo",
        "gamesDurakModePerevodnoi": "Traspaso",
        "gamesDurakDeck24": "24 cartas",
        "gamesDurakDeck36": "36 cartas",
        "gamesDurakDeck52": "52 cartas",
        "rulesDurakMode": "Modo: {mode}",
        "rulesDurakPlayersDeck": "Jugadores: {players}. Baraja: {deck}.",
        "rulesDurakOfflineBot": "Juega contra un bot, sin apuestas ni límite de tiempo.",
        "rulesDurakAttack": "El atacante juega cartas; el defensor las cubre (mismo palo más alto, o un triunfo). Un triunfo solo se cubre con un triunfo mayor.",
        "rulesDurakBeat": "Cuando todas las cartas están cubiertas, el atacante dice «Bito» y van al descarte. Si no, el defensor se lleva todo de la mesa.",
        "rulesDurakLoser": "Pierde quien se queda con cartas al final: el «tonto».",
    },
    "it": {
        "gamesDurakModePodkidnoi": "Rinforzo",
        "gamesDurakModePerevodnoi": "Trasferimento",
        "gamesDurakDeck24": "24 carte",
        "gamesDurakDeck36": "36 carte",
        "gamesDurakDeck52": "52 carte",
        "rulesDurakMode": "Modalità: {mode}",
        "rulesDurakPlayersDeck": "Giocatori: {players}. Mazzo: {deck}.",
        "rulesDurakOfflineBot": "Gioca contro un bot, senza puntate né limite di tempo.",
        "rulesDurakAttack": "L’attaccante gioca le carte; il difensore le batte (stesso seme più alto, oppure un briscola). Una briscola si batte solo con una briscola più alta.",
        "rulesDurakBeat": "Quando tutte le carte sono battute, l’attaccante dice «Bito» e le carte vanno nello scarto. Altrimenti il difensore prende tutto dal tavolo.",
        "rulesDurakLoser": "Perde chi resta con le carte alla fine — il «durak».",
    },
    "pt": {
        "gamesDurakModePodkidnoi": "Apoio",
        "gamesDurakModePerevodnoi": "Transferência",
        "gamesDurakDeck24": "24 cartas",
        "gamesDurakDeck36": "36 cartas",
        "gamesDurakDeck52": "52 cartas",
        "rulesDurakMode": "Modo: {mode}",
        "rulesDurakPlayersDeck": "Jogadores: {players}. Baralho: {deck}.",
        "rulesDurakOfflineBot": "Jogue contra um bot, sem apostas nem limite de tempo.",
        "rulesDurakAttack": "O atacante joga cartas; o defensor cobre (mesmo naipe mais alto, ou um trunfo). Um trunfo só é coberto por um trunfo maior.",
        "rulesDurakBeat": "Quando todas as cartas estão cobertas, o atacante diz «Bito» e vão para o descarte. Senão o defensor leva tudo da mesa.",
        "rulesDurakLoser": "Perde quem fica com cartas no fim — o «durak».",
    },
    "pl": {
        "gamesDurakModePodkidnoi": "Dokładany",
        "gamesDurakModePerevodnoi": "Przerzutowy",
        "gamesDurakDeck24": "24 karty",
        "gamesDurakDeck36": "36 kart",
        "gamesDurakDeck52": "52 karty",
        "rulesDurakMode": "Tryb: {mode}",
        "rulesDurakPlayersDeck": "Gracze: {players}. Talia: {deck}.",
        "rulesDurakOfflineBot": "Gra przeciwko botowi, bez stawek i limitu czasu.",
        "rulesDurakAttack": "Atakujący kładzie karty; obrońca je bije (tym samym kolorem wyższą lub atutem). Atut bije tylko wyższy atut.",
        "rulesDurakBeat": "Gdy wszystkie karty są bite, atakujący mówi «Bito», a karty idą na stos. W przeciwnym razie obrońca bierze wszystko ze stołu.",
        "rulesDurakLoser": "Przegrywa ten, kto na końcu ma karty — «dureń».",
    },
    "nl": {
        "gamesDurakModePodkidnoi": "Bijleggen",
        "gamesDurakModePerevodnoi": "Doorschuiven",
        "gamesDurakDeck24": "24 kaarten",
        "gamesDurakDeck36": "36 kaarten",
        "gamesDurakDeck52": "52 kaarten",
        "rulesDurakMode": "Modus: {mode}",
        "rulesDurakPlayersDeck": "Spelers: {players}. Deck: {deck}.",
        "rulesDurakOfflineBot": "Speel tegen een bot, zonder inzet of tijdslimiet.",
        "rulesDurakAttack": "De aanvaller speelt kaarten; de verdediger slaat ze (zelfde kleur hoger, of een troef). Een troef wordt alleen geslagen door een hogere troef.",
        "rulesDurakBeat": "Als alle kaarten geslagen zijn, zegt de aanvaller «Bito» en gaan ze naar de aflegstapel. Anders neemt de verdediger alles van tafel.",
        "rulesDurakLoser": "Verliezer is wie aan het eind nog kaarten heeft — de «dwaas».",
    },
    "sv": {
        "gamesDurakModePodkidnoi": "Pålägg",
        "gamesDurakModePerevodnoi": "Överföring",
        "gamesDurakDeck24": "24 kort",
        "gamesDurakDeck36": "36 kort",
        "gamesDurakDeck52": "52 kort",
        "rulesDurakMode": "Läge: {mode}",
        "rulesDurakPlayersDeck": "Spelare: {players}. Kortlek: {deck}.",
        "rulesDurakOfflineBot": "Spela mot en bot, utan insatser eller tid.",
        "rulesDurakAttack": "Anfallaren lägger kort; försvararen slår dem (samma färg högre, eller trumf). Trumf slås bara av högre trumf.",
        "rulesDurakBeat": "När alla kort är slagna säger anfallaren «Bito» och korten går till högen. Annars tar försvararen allt från bordet.",
        "rulesDurakLoser": "Förloraren är den som har kort kvar i slutet — «dåren».",
    },
    "nb": {
        "gamesDurakModePodkidnoi": "Pålegg",
        "gamesDurakModePerevodnoi": "Overføring",
        "gamesDurakDeck24": "24 kort",
        "gamesDurakDeck36": "36 kort",
        "gamesDurakDeck52": "52 kort",
        "rulesDurakMode": "Modus: {mode}",
        "rulesDurakPlayersDeck": "Spillere: {players}. Kortstokk: {deck}.",
        "rulesDurakOfflineBot": "Spill mot en bot, uten innsats eller tid.",
        "rulesDurakAttack": "Angriperen legger kort; forsvareren slår dem (samme farge høyere, eller trumf). Trumf slås bare av høyere trumf.",
        "rulesDurakBeat": "Når alle kort er slått, sier angriperen «Bito», og kortene går i bunken. Ellers tar forsvareren alt fra bordet.",
        "rulesDurakLoser": "Taperen er den som har kort igjen til slutt — «narren».",
    },
    "fi": {
        "gamesDurakModePodkidnoi": "Lisäys",
        "gamesDurakModePerevodnoi": "Siirto",
        "gamesDurakDeck24": "24 korttia",
        "gamesDurakDeck36": "36 korttia",
        "gamesDurakDeck52": "52 korttia",
        "rulesDurakMode": "Tila: {mode}",
        "rulesDurakPlayersDeck": "Pelaajat: {players}. Pakka: {deck}.",
        "rulesDurakOfflineBot": "Pelaa bottia vastaan ilman panoksia ja aikarajaa.",
        "rulesDurakAttack": "Hyökkääjä laittaa kortteja; puolustaja lyö ne (samaa maata korkeammalla tai valttilla). Valtti lyödään vain korkeammalla valttilla.",
        "rulesDurakBeat": "Kun kaikki kortit on lyöty, hyökkääjä sanoo «Bito» ja kortit menevät poistopakkaan. Muuten puolustaja ottaa kaiken pöydästä.",
        "rulesDurakLoser": "Häviäjä on se, jolla on kortteja lopussa — «durak».",
    },
    "cs": {
        "gamesDurakModePodkidnoi": "Přihazovaný",
        "gamesDurakModePerevodnoi": "Převáděný",
        "gamesDurakDeck24": "24 karet",
        "gamesDurakDeck36": "36 karet",
        "gamesDurakDeck52": "52 karet",
        "rulesDurakMode": "Režim: {mode}",
        "rulesDurakPlayersDeck": "Hráči: {players}. Balíček: {deck}.",
        "rulesDurakOfflineBot": "Hra proti botovi, bez sázek a limitu času.",
        "rulesDurakAttack": "Útočník pokládá karty; obránce je bije (stejná barva vyšší, nebo trumf). Trumf se bije jen vyšším trumfem.",
        "rulesDurakBeat": "Když jsou všechny karty bity, útočník řekne «Bito» a karty jdou do odhozu. Jinak si obránce vezme všechno ze stolu.",
        "rulesDurakLoser": "Prohrává ten, komu na konci zůstanou karty — «hlupák».",
    },
    "el": {
        "gamesDurakModePodkidnoi": "Προσθήκη",
        "gamesDurakModePerevodnoi": "Μεταφορά",
        "gamesDurakDeck24": "24 φύλλα",
        "gamesDurakDeck36": "36 φύλλα",
        "gamesDurakDeck52": "52 φύλλα",
        "rulesDurakMode": "Λειτουργία: {mode}",
        "rulesDurakPlayersDeck": "Παίκτες: {players}. Τράπουλα: {deck}.",
        "rulesDurakOfflineBot": "Παίξτε εναντίον μποτ, χωρίς ποντάρισμα ή όριο χρόνου.",
        "rulesDurakAttack": "Ο επιτιθέμενος παίζει φύλλα· ο αμυνόμενος τα καλύπτει (ίδιο χρώμα πιο δυνατό ή ατού). Το ατού καλύπτεται μόνο με πιο δυνατό ατού.",
        "rulesDurakBeat": "Όταν όλα τα φύλλα καλυφθούν, ο επιτιθέμενος λέει «Bito» και πάνε στην απόρριψη. Αλλιώς ο αμυνόμενος παίρνει όλα από το τραπέζι.",
        "rulesDurakLoser": "Χάνει όποιος έχει φύλλα στο τέλος — ο «κάλπης».",
    },
    "tr": {
        "gamesDurakModePodkidnoi": "Atışlı",
        "gamesDurakModePerevodnoi": "Aktarmalı",
        "gamesDurakDeck24": "24 kart",
        "gamesDurakDeck36": "36 kart",
        "gamesDurakDeck52": "52 kart",
        "rulesDurakMode": "Mod: {mode}",
        "rulesDurakPlayersDeck": "Oyuncular: {players}. Deste: {deck}.",
        "rulesDurakOfflineBot": "Bot’a karşı oynayın; bahis ve süre sınırı yok.",
        "rulesDurakAttack": "Saldıran kart koyar; savunan onları döver (aynı renk daha yüksek veya koz). Koz yalnızca daha yüksek kozla dövülür.",
        "rulesDurakBeat": "Tüm kartlar dövülünce saldıran «Bito» der ve kartlar atığa gider. Yoksa savunan masadaki her şeyi alır.",
        "rulesDurakLoser": "Kaybeden, sonda kartı kalan kişidir — «durak».",
    },
    "ar": {
        "gamesDurakModePodkidnoi": "إضافة",
        "gamesDurakModePerevodnoi": "نقل",
        "gamesDurakDeck24": "24 ورقة",
        "gamesDurakDeck36": "36 ورقة",
        "gamesDurakDeck52": "52 ورقة",
        "rulesDurakMode": "الوضع: {mode}",
        "rulesDurakPlayersDeck": "اللاعبون: {players}. المجموعة: {deck}.",
        "rulesDurakOfflineBot": "العب ضد بوت بلا رهانات ولا مهلة زمنية.",
        "rulesDurakAttack": "المهاجم يلعب أوراقًا؛ والمدافع يرد (نفس النوع أعلى، أو ورقة رابحة). الورقة الرابحة تُرد فقط برابحة أعلى.",
        "rulesDurakBeat": "عندما تُرد كل الأوراق يقول المهاجم «بيتو» وتذهب إلى المهمل. وإلا يأخذ المدافع كل ما على الطاولة.",
        "rulesDurakLoser": "الخاسر من تبقى معه أوراق في النهاية — «الأحمق».",
    },
    "he": {
        "gamesDurakModePodkidnoi": "הוספה",
        "gamesDurakModePerevodnoi": "העברה",
        "gamesDurakDeck24": "24 קלפים",
        "gamesDurakDeck36": "36 קלפים",
        "gamesDurakDeck52": "52 קלפים",
        "rulesDurakMode": "מצב: {mode}",
        "rulesDurakPlayersDeck": "שחקנים: {players}. חפיסה: {deck}.",
        "rulesDurakOfflineBot": "שחקו נגד בוט, בלי הימורים ובלי מגבלת זמן.",
        "rulesDurakAttack": "התוקף מניח קלפים; המגן מכסה אותם (אותה סדרה גבוהה יותר, או קלף שליט). שליט מכוסה רק בשליט גבוה יותר.",
        "rulesDurakBeat": "כשכל הקלפים מכוסים, התוקף אומר «ביטו» והקלפים הולכים לערימת הפסילה. אחרת המגן לוקח הכול מהשולחן.",
        "rulesDurakLoser": "המפסיד הוא מי שנשאר עם קלפים בסוף — ה«טיפש».",
    },
    "hi": {
        "gamesDurakModePodkidnoi": "फेंक वाला",
        "gamesDurakModePerevodnoi": "ट्रांसफर",
        "gamesDurakDeck24": "24 पत्ते",
        "gamesDurakDeck36": "36 पत्ते",
        "gamesDurakDeck52": "52 पत्ते",
        "rulesDurakMode": "मोड: {mode}",
        "rulesDurakPlayersDeck": "खिलाड़ी: {players}. डेक: {deck}.",
        "rulesDurakOfflineBot": "बॉट के खिलाफ खेलें, बिना दांव और समय सीमा के।",
        "rulesDurakAttack": "आक्रमणकारी पत्ते खेलता है; रक्षक उन्हें काटता है (उसी सूट का ऊँचा, या ट्रंप)। ट्रंप केवल ऊँचे ट्रंप से कटता है।",
        "rulesDurakBeat": "जब सभी पत्ते कट जाएँ, आक्रमणकारी «बीटो» कहता है और पत्ते डिसकार्ड में जाते हैं। वरना रक्षक मेज़ से सब ले लेता है।",
        "rulesDurakLoser": "हारने वाला वही है जिसके पास अंत में पत्ते रह जाएँ — «मूर्ख».",
    },
    "ja": {
        "gamesDurakModePodkidnoi": "追加出し",
        "gamesDurakModePerevodnoi": "転送",
        "gamesDurakDeck24": "24枚",
        "gamesDurakDeck36": "36枚",
        "gamesDurakDeck52": "52枚",
        "rulesDurakMode": "モード: {mode}",
        "rulesDurakPlayersDeck": "人数: {players}。デッキ: {deck}。",
        "rulesDurakOfflineBot": "ボット対戦。賭け金も制限時間もありません。",
        "rulesDurakAttack": "攻撃側がカードを出し、守備側が打ちます（同スートのより強い札、または切り札）。切り札はより強い切り札でのみ打てます。",
        "rulesDurakBeat": "すべて打てたら攻撃側が「ビト」と言い、カードは捨て札へ。できなければ守備側が場の札をすべて取ります。",
        "rulesDurakLoser": "最後に手札が残った人が負け — 「愚か者」です。",
    },
    "ko": {
        "gamesDurakModePodkidnoi": "추가",
        "gamesDurakModePerevodnoi": "전달",
        "gamesDurakDeck24": "24장",
        "gamesDurakDeck36": "36장",
        "gamesDurakDeck52": "52장",
        "rulesDurakMode": "모드: {mode}",
        "rulesDurakPlayersDeck": "인원: {players}. 덱: {deck}.",
        "rulesDurakOfflineBot": "봇과 플레이합니다. 판돈과 시간 제한이 없습니다.",
        "rulesDurakAttack": "공격자가 카드를 내고, 수비자가 막습니다(같은 무늬의 더 높은 카드 또는 트럼프). 트럼프는 더 높은 트럼프로만 막습니다.",
        "rulesDurakBeat": "모든 카드가 막히면 공격자가 «비토»를 말하고 카드는 버림 더미로 갑니다. 아니면 수비자가 테이블의 카드를 모두 가져갑니다.",
        "rulesDurakLoser": "마지막에 카드가 남은 사람이 패배 — «바보»입니다.",
    },
    "zh": {
        "gamesDurakModePodkidnoi": "加牌",
        "gamesDurakModePerevodnoi": "转攻",
        "gamesDurakDeck24": "24 张",
        "gamesDurakDeck36": "36 张",
        "gamesDurakDeck52": "52 张",
        "rulesDurakMode": "模式：{mode}",
        "rulesDurakPlayersDeck": "玩家：{players}。牌组：{deck}。",
        "rulesDurakOfflineBot": "与机器人对战，无赌注、无回合时限。",
        "rulesDurakAttack": "进攻方出牌；防守方用同花色更大的牌或王牌盖住。王牌只能被更大的王牌盖住。",
        "rulesDurakBeat": "全部盖住后，进攻方说「打完」，牌进入弃牌堆；否则防守方收走桌上所有牌。",
        "rulesDurakLoser": "终局仍有手牌的人落败——「傻瓜」。",
    },
    "th": {
        "gamesDurakModePodkidnoi": "ทิ้งเพิ่ม",
        "gamesDurakModePerevodnoi": "ส่งต่อ",
        "gamesDurakDeck24": "24 ใบ",
        "gamesDurakDeck36": "36 ใบ",
        "gamesDurakDeck52": "52 ใบ",
        "rulesDurakMode": "โหมด: {mode}",
        "rulesDurakPlayersDeck": "ผู้เล่น: {players}. สำรับ: {deck}.",
        "rulesDurakOfflineBot": "เล่นกับบอท ไม่มีเดิมพันและไม่จำกัดเวลา",
        "rulesDurakAttack": "ฝ่ายรุกออกไพ่ ฝ่ายรับต้องทับ (ดอกเดียวกันที่สูงกว่า หรือไพ่ตาย) ไพ่ตายทับได้ด้วยไพ่ตายที่สูงกว่าเท่านั้น",
        "rulesDurakBeat": "เมื่อทับครบแล้วฝ่ายรุกพูด «บิโต» ไพ่ไปกองทิ้ง ไม่เช่นนั้นฝ่ายรับรับไพ่ทั้งหมดบนโต๊ะ",
        "rulesDurakLoser": "ผู้แพ้คือคนที่ยังมีไพ่ตอนจบ — «คนโง่»",
    },
    "vi": {
        "gamesDurakModePodkidnoi": "Đánh thêm",
        "gamesDurakModePerevodnoi": "Chuyển",
        "gamesDurakDeck24": "24 lá",
        "gamesDurakDeck36": "36 lá",
        "gamesDurakDeck52": "52 lá",
        "rulesDurakMode": "Chế độ: {mode}",
        "rulesDurakPlayersDeck": "Người chơi: {players}. Bộ bài: {deck}.",
        "rulesDurakOfflineBot": "Chơi với bot, không cược và không giới hạn thời gian.",
        "rulesDurakAttack": "Người tấn đánh bài; người thủ chắn (cùng chất cao hơn, hoặc át). Át chỉ bị chắn bởi át cao hơn.",
        "rulesDurakBeat": "Khi tất cả bài đã bị chắn, người tấn nói «Bito» và bài vào chồng bỏ. Nếu không, người thủ lấy hết bài trên bàn.",
        "rulesDurakLoser": "Người thua là người còn bài lúc kết thúc — «kẻ ngốc».",
    },
    "id": {
        "gamesDurakModePodkidnoi": "Tambah",
        "gamesDurakModePerevodnoi": "Alih",
        "gamesDurakDeck24": "24 kartu",
        "gamesDurakDeck36": "36 kartu",
        "gamesDurakDeck52": "52 kartu",
        "rulesDurakMode": "Mode permainan: {mode}",
        "rulesDurakPlayersDeck": "Pemain: {players}. Dek: {deck}.",
        "rulesDurakOfflineBot": "Main lawan bot, tanpa taruhan dan batas waktu.",
        "rulesDurakAttack": "Penyerang mengeluarkan kartu; bertahan mengalahkannya (warna sama lebih tinggi, atau truf). Truf hanya dikalahkan truf yang lebih tinggi.",
        "rulesDurakBeat": "Jika semua kartu dikalahkan, penyerang bilang «Bito» dan kartu ke buangan. Jika tidak, bertahan mengambil semua dari meja.",
        "rulesDurakLoser": "Yang kalah adalah yang masih punya kartu di akhir — «durak».",
    },
}


def main() -> None:
    en = json.loads((L10N / "app_en.arb").read_text(encoding="utf-8"))
    # Метаданные плейсхолдеров из en — копируем при добавлении ключей.
    en_meta = {f"@{k}": en[f"@{k}"] for k in KEYS if f"@{k}" in en}
    updated_files = 0
    changed_keys = 0
    for path in sorted(L10N.glob("app_*.arb")):
        data = json.loads(path.read_text(encoding="utf-8"))
        locale = data.get("@@locale") or path.stem.split("_", 1)[-1]
        if locale == "en":
            continue
        tr = TR.get(locale)
        if locale == "ru":
            # RU уже эталон в app_ru.arb — не трогаем, если ключи есть.
            if all(k in data for k in KEYS):
                print(f"-- {path.name}: keep existing RU")
                continue
            tr = {k: en[k] for k in KEYS}  # fallback only if somehow missing
        if not tr:
            print(f"SKIP {path.name}: no translations table")
            continue
        file_changed = 0
        for key in KEYS:
            new_val = tr[key]
            if key not in data:
                data[key] = new_val
                meta = f"@{key}"
                if meta in en_meta and meta not in data:
                    data[meta] = en_meta[meta]
                file_changed += 1
            elif data[key] != new_val:
                data[key] = new_val
                file_changed += 1
        if file_changed:
            path.write_text(
                json.dumps(data, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            updated_files += 1
            changed_keys += file_changed
            print(f"OK {path.name}: {file_changed} keys")
        else:
            print(f"-- {path.name}: already up to date")
    print(f"Done: {updated_files} files, {changed_keys} key updates")


if __name__ == "__main__":
    main()
