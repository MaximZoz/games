import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Bosh sahifa';

  @override
  String get navProfile => 'Profil';

  @override
  String get navFriends => 'Do‘stlar';

  @override
  String get navChats => 'Chatlar';

  @override
  String get navGames => 'O‘yinlar';

  @override
  String get navSettings => 'Sozlamalar';

  @override
  String get settingsTitle => 'Sozlamalar';

  @override
  String get settingsLanguage => 'Til';

  @override
  String get settingsLanguageSystem => 'Tizim bo‘yicha';

  @override
  String get settingsSoundTitle => 'Ovoz';

  @override
  String get settingsSoundSubtitle => 'O‘yinlar va bildirishnomalar';

  @override
  String get settingsSoundGames => 'O‘yinlar';

  @override
  String get settingsSoundNotifications => 'Bildirishnomalar';

  @override
  String get settingsSoundTurn => 'Yurish';

  @override
  String get settingsHapticsTitle => 'Tebranish';

  @override
  String get settingsHapticsSubtitle => 'Faqat bildirishnomalar: xabarlar, so‘rovlar, yurishingiz va taymer';

  @override
  String get settingsGamepadTitle => 'Kontroller';

  @override
  String get settingsGamepadSubtitle => 'Menyu va o‘yinlar uchun geympad';

  @override
  String settingsGamepadConnected(String name) {
    return 'Ulangan: $name';
  }

  @override
  String get settingsGamepadDisconnected => 'Geympad topilmadi. Kontrollerni ulang va istalgan tugmani bosing.';

  @override
  String get settingsGamepadGenericName => 'Kontroller';

  @override
  String get settingsGamepadHelpNavigate => 'Navigatsiya';

  @override
  String get settingsGamepadHelpConfirm => 'Tanlash';

  @override
  String get settingsGamepadHelpBack => 'Orqaga';

  @override
  String get settingsGamepadHelpTabs => 'Ichki oynalar';

  @override
  String get settingsGamepadHelpPlay => 'Doska va qo‘l kursori: shashka, x-nol, dengiz jangi, durak, uno, poker va nard';

  @override
  String get settingsGamepadHelpCards => 'Kartalar';

  @override
  String get settingsGamepadHelpKeyboard => 'Klaviatura';

  @override
  String get settingsGamepadHelpBalance => 'Balans';

  @override
  String get settingsGamepadHelpLogout => 'Chiqish';

  @override
  String get settingsGamepadHelpPage => 'Sahifa';

  @override
  String get settingsGamepadLayoutXbox => 'Xbox joylashuvi';

  @override
  String get settingsGamepadLayoutPlayStation => 'PlayStation joylashuvi';

  @override
  String get settingsGamepadLayoutNintendo => 'Nintendo joylashuvi';

  @override
  String get gamepadKeyboardTitle => 'Klaviatura';

  @override
  String get gamepadKeyboardSpace => 'Probel';

  @override
  String get gamepadLegendConfirm => 'Tanlash';

  @override
  String get gamepadLegendBack => 'Orqaga';

  @override
  String get gamepadLegendTabs => 'Ichki oynalar';

  @override
  String get gamepadLegendCycle => 'O‘zgartirish';

  @override
  String gamepadConnectedSnack(String name) {
    return 'Kontroller ulandi: $name';
  }

  @override
  String get settingsOfflineModeTitle => 'Tarmoq rejimi';

  @override
  String get settingsOfflineModeSubtitle => 'Oflayn: bot bilan darhol o‘ynash, stavka va mukofotlarsiz, chat va do‘stlarsiz. Xaridlar saqlanadi va onlayn rejimda qo‘llanadi. Onlayn — internet bo‘lganda yoki foydalanuvchi sozlamasi bo‘yicha.';

  @override
  String get settingsModeOnline => 'Onlayn';

  @override
  String get settingsModeOffline => 'Oflayn';

  @override
  String get gamesAlternateStartsHint => 'Navbat bilan kim partiya boshlaydi';

  @override
  String get rulesAlternateStarts => 'Kim birinchi yurishi partiyadan partiyaga almashadi.';

  @override
  String get offlineBadgeTooltip => 'Oflayn rejim';

  @override
  String get offlineModePopupTitle => 'Oflayn rejim';

  @override
  String get offlineModePopupBody => 'Oflayn rejim yoqilgan. Stavka va mukofotlarsiz bot bilan o‘ynang. Chatlar, do‘stlar va lobbi yashirilgan. Xaridlar onlayn rejimda qo‘llanadi.';

  @override
  String get offlineModePopupSettings => 'Sozlamalar';

  @override
  String get offlineModeOfferBody => 'Internet yo‘q yoki aloqa juda sekin. Oflayn rejimni yoqib, bot bilan o‘ynashingiz mumkin.';

  @override
  String get offlineModeOfferAction => 'Oflaynni yoqish';

  @override
  String get gamesPlay => 'O‘ynash';

  @override
  String get offlineGameTitle => 'Bot bilan o‘yin';

  @override
  String get offlineGameHint => 'Stavka va mukofotlarsiz · faqat oflayn';

  @override
  String get offlineBotWon => 'Bot yutdi';

  @override
  String get offlineBotThinking => 'Bot yurishi…';

  @override
  String get offlinePlayAgain => 'Yana';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'Olish';

  @override
  String get durakActionAll => 'Hammasi';

  @override
  String get durakActionDone => 'Tayyor';

  @override
  String get durakActionBito => 'Bito';

  @override
  String get durakHintDefend => 'Himoyalaning';

  @override
  String get durakHintDefendOrTransfer => 'Himoyalaning yoki o‘tkazing';

  @override
  String get durakHintOpponentDefends => 'Raqib himoyalanmoqda';

  @override
  String get durakHintThrowInFirst => 'Karta tashlang (birinchi zarba: maks. 5)';

  @override
  String get durakHintThrowIn => 'Karta tashlang yoki himoyani kuting';

  @override
  String get durakHintOpponentThrows => 'Raqib tashlamoqda';

  @override
  String get durakHintTakeFollow => 'Olingandan keyin tashlang yoki «Tayyor» bosing';

  @override
  String get durakHintOpponentTakeFollow => 'Raqib olingandan keyin tashlashi mumkin';

  @override
  String get durakHintBito => 'Karta tashlang yoki «Bito» deng';

  @override
  String get durakHintOpponentBito => 'Raqib tashlaydi yoki «Bito» deydi';

  @override
  String get durakHintYourAttack => 'Sizning yurishingiz — hujum qiling';

  @override
  String get durakHintOpponentAttack => 'Raqib hujum qilmoqda';

  @override
  String get durakHintYouLost => 'Yutqazdingiz — siz duraksiz';

  @override
  String get durakHintDrawAllOut => 'Durang — hamma chiqdi';

  @override
  String get durakHintYouFinished => 'Siz chiqdingiz — oxirini kutamiz';

  @override
  String get durakFirstLeadYou => 'Siz yurasiz';

  @override
  String get durakFirstLeadOpponent => 'Raqib yuradi';

  @override
  String get durakFirstLeadBot => 'Bot yuradi';

  @override
  String durakFirstLeadOf(String name) {
    return '$name yuradi';
  }

  @override
  String get durakFirstLeadReason => 'Eng kichik kozir';

  @override
  String get shopPurchaseQueued => 'Xarid saqlandi — onlayn rejimda qo‘llanadi';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — xarid qo‘llandi';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — xarid qo‘llanmadi: $reason';
  }

  @override
  String get settingsFriendsOnlyTitle => 'Faqat do‘stlardan xabarlar';

  @override
  String get settingsFriendsOnlySubtitle => 'Do‘st bo‘lmaganlar faqat emoji yubora oladi. Spam xalaqit bersa, foydalanuvchini vaqtincha bloklang.';

  @override
  String get settingsNotifications => 'Bildirishnomalar';

  @override
  String get settingsPushChat => 'Chat';

  @override
  String get settingsPushFriends => 'Do‘stlar';

  @override
  String get settingsPushGames => 'O‘yinlar';

  @override
  String get settingsPushRewards => 'Mukofotlar';

  @override
  String settingsAppVersion(String version) {
    return 'Versiya $version';
  }

  @override
  String get appUpdateTitle => 'Yangilanish mavjud';

  @override
  String get appUpdateBody => 'Ilovaning yangi versiyasi mavjud. Davom etish uchun yangilang.';

  @override
  String get appUpdateWhatsNew => 'Yangiliklar';

  @override
  String get appUpdateOk => 'Yangilash';

  @override
  String get appUpdateLaterBanner => 'Bu o‘yindan keyin ilovani yangilaymiz';

  @override
  String get loginTitle => 'Kirish';

  @override
  String get loginSubtitle => 'Email yoki login va parolni kiriting';

  @override
  String get loginEmailLabel => 'Email yoki login';

  @override
  String get loginPasswordLabel => 'Parol';

  @override
  String get loginSubmit => 'Kirish';

  @override
  String get loginNoAccount => 'Hisobingiz yo‘qmi? Ro‘yxatdan o‘ting';

  @override
  String get loginEmailRequired => 'Email yoki login kiriting';

  @override
  String get loginPasswordRequired => 'Parolni kiriting';

  @override
  String get loginTooltip => 'Kirish';

  @override
  String get logoutTooltip => 'Chiqish';

  @override
  String get registerTitle => 'Ro‘yxatdan o‘tish';

  @override
  String get registerSubtitle => 'O‘ynash uchun hisob yarating';

  @override
  String get registerNameLabel => 'Ism (login)';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'Parol';

  @override
  String get registerSubmit => 'Ro‘yxatdan o‘tish';

  @override
  String get registerHaveAccount => 'Hisobingiz bormi? Kirish';

  @override
  String get registerNameRequired => 'Ism kiriting';

  @override
  String get registerNameNoSpaces => 'Ismda bo‘sh joy bo‘lmasligi kerak';

  @override
  String get registerNameMax => 'Maksimum 20 belgi';

  @override
  String get registerNameHint => '20 belgigacha';

  @override
  String get registerEmailRequired => 'Email kiriting';

  @override
  String get registerEmailInvalid => 'Noto‘g‘ri email';

  @override
  String get registerPasswordHint => 'Kamida 6 belgi';

  @override
  String get registerPasswordMin => 'Parol kamida 6 belgidan iborat bo‘lishi kerak';

  @override
  String get commonCancel => 'Bekor qilish';

  @override
  String get commonSave => 'Saqlash';

  @override
  String get commonDelete => 'O‘chirish';

  @override
  String get commonEdit => 'Tahrirlash';

  @override
  String get commonReply => 'Javob berish';

  @override
  String get commonSend => 'Yuborish';

  @override
  String get commonClose => 'Yopish';

  @override
  String get commonRetry => 'Qayta urinish';

  @override
  String get commonLoading => 'Yuklanmoqda…';

  @override
  String get commonError => 'Xato';

  @override
  String get commonOnline => 'onlayn';

  @override
  String get commonOffline => 'oflayn';

  @override
  String get commonOnlineCap => 'Onlayn';

  @override
  String get commonUser => 'Foydalanuvchi';

  @override
  String get commonPlayer => 'O‘yinchi';

  @override
  String get commonAboutMe => 'O‘zim haqimda';

  @override
  String get commonBack => 'Orqaga';

  @override
  String get commonAccept => 'Qabul qilish';

  @override
  String get commonDecline => 'Rad etish';

  @override
  String get commonCreating => 'Yaratilmoqda…';

  @override
  String get commonSearching => 'Qidirilmoqda…';

  @override
  String get commonInsufficientCoins => 'Tangalar yetarli emas';

  @override
  String get commonNotFound => 'Topilmadi';

  @override
  String get commonServerErrorShort => 'Server xatosi';

  @override
  String get commonForbidden => 'Ruxsat yo‘q';

  @override
  String get commonUserBlocked => 'Foydalanuvchi bloklangan';

  @override
  String get commonUserNotFound => 'Foydalanuvchi topilmadi';

  @override
  String get commonGenericError => 'Nimadir xato ketdi. Qayta urinib ko‘ring.';

  @override
  String get apiErrWrongGameType => 'Oʻyin turi notoʻgʻri';

  @override
  String get apiErrWrongGameTypeOrState => 'Oʻyin turi yoki holati notoʻgʻri';

  @override
  String get apiErrLobbyFull => 'Lobbi toʻlgan';

  @override
  String get apiErrBadState => 'Oʻyin holati notoʻgʻri';

  @override
  String get apiErrIllegalMove => 'Bunday yurish mumkin emas';

  @override
  String get apiErrUnknownMoveType => 'Nomaʼlum yurish turi';

  @override
  String get apiErrNoOpponents => 'Raqib yoʻq';

  @override
  String get apiErrNoOpponentsRematch => 'Revansh uchun raqib yoʻq';

  @override
  String get apiErrAlreadyInLobby => 'Siz allaqachon shu lobbidasiz';

  @override
  String get apiErrGameNotActive => 'Oʻyin faol emas';

  @override
  String get apiErrNotInBattle => 'Hozir jang bosqichi emas';

  @override
  String get apiErrNotInSetup => 'Hozir joylashtirish bosqichi emas';

  @override
  String get apiErrAlreadyReady => 'Siz allaqachon tayyorsiz';

  @override
  String get apiErrAlreadyForfeited => 'Siz allaqachon taslim boʻldingiz';

  @override
  String get apiErrYouHaveForfeited => 'Siz taslim boʻldingiz';

  @override
  String get apiErrNoDrawOffer => 'Durang taklifi yoʻq';

  @override
  String get apiErrDrawOnlyPvp => 'Durang faqat oʻyinchiga qarshi';

  @override
  String get apiErrDrawOnly1v1 => 'Durang faqat 1 ga 1 da';

  @override
  String get apiErrDrawVsBot => 'Botga qarshi durang yoʻq';

  @override
  String get apiErrDrawMultiplayer => 'Koʻp oʻyinchida durang yoʻq';

  @override
  String get apiErrDeck24TwoPlayers => '24 kartalik koloda faqat 2 kishiga';

  @override
  String get apiErrDeck52ThreeOrFour => '52 kartalik koloda 3 yoki 4 kishiga';

  @override
  String get apiErrAccountFrozen => 'Hisob muzlatilgan';

  @override
  String get apiErrTurnTimeInvalid => 'Yurish vaqti 0, 20, 60 yoki 600 soniya boʻlishi kerak';

  @override
  String get timeJustNow => 'hozirgina';

  @override
  String get timeYesterday => 'kecha';

  @override
  String timeMinutesAgo(int count) {
    return '$count daq oldin';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count soat oldin';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count kun oldin';
  }

  @override
  String get timeWeekAgo => 'bir hafta oldin';

  @override
  String timeWeeksAgo(int count) {
    return '$count hafta oldin';
  }

  @override
  String get timeMonthAgo => 'bir oy oldin';

  @override
  String timeMonthsAgo(int count) {
    return '$count oy oldin';
  }

  @override
  String get timeYearAgo => 'bir yil oldin';

  @override
  String timeYearsAgo(int count) {
    return '$count yil oldin';
  }

  @override
  String get weekdaySun => 'Yak';

  @override
  String get weekdayMon => 'Dush';

  @override
  String get weekdayTue => 'Sesh';

  @override
  String get weekdayWed => 'Chor';

  @override
  String get weekdayThu => 'Pay';

  @override
  String get weekdayFri => 'Jum';

  @override
  String get weekdaySat => 'Shan';

  @override
  String get monthJan => 'yan';

  @override
  String get monthFeb => 'fev';

  @override
  String get monthMar => 'mar';

  @override
  String get monthApr => 'apr';

  @override
  String get monthMay => 'may';

  @override
  String get monthJun => 'iyn';

  @override
  String get monthJul => 'iyl';

  @override
  String get monthAug => 'avg';

  @override
  String get monthSep => 'sen';

  @override
  String get monthOct => 'okt';

  @override
  String get monthNov => 'noy';

  @override
  String get monthDec => 'dek';

  @override
  String get homeAchievements => 'Yutuqlar';

  @override
  String get homeAchievementsSubtitle => 'O‘yin natijalaringiz';

  @override
  String get homeAchievementsRewards => 'Olish uchun mukofotlar bor';

  @override
  String get homeCoins => 'Tangalar';

  @override
  String get homeCoinsSubtitle => 'Balans va mukofotlar';

  @override
  String get homeCoinsDailyReward => 'Kirish mukofoti mavjud';

  @override
  String get homeItems => 'Buyumlar';

  @override
  String get homeItemsInventory => 'Inventaringiz';

  @override
  String get homeItemsGifted => 'Sizga kolleksiya sovg‘a qilindi';

  @override
  String get homeItemsIncome => 'Kolleksiya daromadini olish mumkin';

  @override
  String get homeShop => 'Do‘kon';

  @override
  String get homeShopSubtitle => 'Emoji, stavkalar, kolleksiyalar';

  @override
  String get gamesTitle => 'O‘yinlar';

  @override
  String get gamesFindMatch => 'O‘yin topish';

  @override
  String get gamesMyTurn => 'Sizning yurishingiz';

  @override
  String get gamesWaiting => 'Kutilmoqda';

  @override
  String get gamesLobbyTab => 'Lobi';

  @override
  String get gamesTicTacToe => 'X-O';

  @override
  String get gamesDurak => 'Durak';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => 'Aylantirish';

  @override
  String get gamesBattleshipSetupPhase => 'Setup';

  @override
  String get gamesBattleshipBattlePhase => 'Battle';

  @override
  String get gamesBattleshipWaitingOpponentSetup => 'Waiting for opponent…';

  @override
  String get gamesBattleshipYouWon => 'You won!';

  @override
  String get gamesBattleshipYouLost => 'You lost';

  @override
  String get gamesBattleshipShipsMustNotTouch => 'Ships must not touch';

  @override
  String get rulesBattleshipTitle => 'Battleship — rules';

  @override
  String get rulesBattleshipPlayers => 'Players: 2.';

  @override
  String rulesBattleshipSetupTime(String time) {
    return 'Setup time: $time.';
  }

  @override
  String get rulesBattleshipIntro => '10×10 grid. Fleet: one 4-deck, two 3-deck, three 2-deck and four 1-deck ships. Ships must not touch, including diagonally.';

  @override
  String get rulesBattleshipSetup => 'If setup time runs out, the current valid placement is kept; if it is invalid, a default layout is used.';

  @override
  String get rulesBattleshipPlay => 'After setup, a random player shoots first. Fire at the opponent’s cells: a hit grants another shot, a miss passes the turn. On your turn you see the opponent’s board; on theirs you see yours.';

  @override
  String get rulesBattleshipWin => 'The first to sink the entire enemy fleet wins.';

  @override
  String get gamesPoker => 'Poker';

  @override
  String get gamesUno => 'Uno';

  @override
  String get gamesNardy => 'Narda';

  @override
  String get gamesNardyModeShort => 'Qisqa';

  @override
  String get gamesNardyModeLong => 'Uzun';

  @override
  String get gamesCheckers => 'Shashka';

  @override
  String get gamesCheckersModeRussian => 'Rus';

  @override
  String get gamesCheckersModeEnglish => 'Ingliz';

  @override
  String get gamesCheckersModeGiveaway => 'Berilmali';

  @override
  String get gamesCheckersModeCorners => 'Burchaklar';

  @override
  String get gamesChess => 'Shaxmat';

  @override
  String get gamesDomino => 'Domino';

  @override
  String get gamesDominoModeKozel => 'Kozel';

  @override
  String get gamesDominoModeClassic => 'Klassika';

  @override
  String get gamesDominoModeSea => 'Dengiz';

  @override
  String get rulesDominoDeal => 'Har biriga 7 tosh. Ikki va uch kishida qolgani bozorda, to‘rt kishida bozor bo‘sh.';

  @override
  String get rulesDominoOpen => 'Birinchi konni 1-1 dan 6-6 gacha eng kichik dubl, so‘ng 0-0 boshlaydi. Dubl bo‘lmasa — eng katta tosh. Aynan shuni qo‘yish kerak.';

  @override
  String get rulesDominoPlay => 'Tosh ochiq uchdagi son bilan qo‘yiladi. Uchdagi dubl o‘sha sonni o‘zgartirmaydi.';

  @override
  String get rulesDominoDraw => 'Yura olmasangiz, mos tosh chiqquncha yoki bozor tugaguncha bittadan oling. Oxirgi toshni olish mumkin. Baribir yurish bo‘lmasa — pas.';

  @override
  String get rulesDominoScore => 'Kon oxirida har kim qo‘lidagi toshlar yig‘indisini yozadi. Chiqqan — 0. 101 gacha: kim yig‘sa, o‘sha kozel va yutqazadi.';

  @override
  String get rulesDominoFish => 'Baliq: bozor bo‘sh va hech kim qo‘ya olmaydi. Ochkoisi hammadan kam yagona o‘yinchi — 0, qolganlari o‘z yig‘indisini yozadi. Minimum hammada bir xil bo‘lsa, hammasi yozadi.';

  @override
  String get rulesDominoMatch => 'Bir konda bir necha kishi 101 dan o‘tsa, kozel — eng yuqori hisob. G‘oliblar — eng past hisob. Hammasi tenglashsa — durang.';

  @override
  String get rulesDominoOffline => 'Oflayn: siz va botlar. Bot mastlarni sanaydi va yashirin qo‘llarga qaramaydi.';

  @override
  String rulesDominoMode(String mode) {
    return 'Rejim: $mode';
  }

  @override
  String get rulesDominoClassicDeal => 'Ikki va uch kishiga 7 tadan, to‘rttaga 5 tadan tosh beriladi. Qolgani bozorda.';

  @override
  String get rulesDominoClassicOpen => 'Birinchi konni 6-6 dubl, so‘ng 0-0 va kichikroq dubllar boshlaydi. Dubl bo‘lmasa — eng katta tosh. Aynan shuni qo‘yish kerak.';

  @override
  String get rulesDominoClassicScore => 'Chiqqan o‘yinchi raqiblar toshlari yig‘indisini yozadi. 100 gacha: birinchi yig‘gan yutadi.';

  @override
  String get rulesDominoClassicFish => 'Baliq: ochkosi hammadan kam bo‘lgan har bir begona qo‘l bilan farqni yozadi. Minimum bir nechtada bo‘lsa, ochko yozilmaydi.';

  @override
  String get rulesDominoClassicMatch => 'Bir xil eng yuqori hisob g‘alabani bo‘lishadi. Hamma hisob teng bo‘lsa — durang.';

  @override
  String get rulesDominoSeaSame => 'Tarqatish, birinchi yurish va olish — «Kozel» rejimidagidek. Zanjir ikki uchli.';

  @override
  String get rulesDominoSeaScore => 'Ochkoni kon oxirida qo‘lida eng ko‘pi bor odam yozadi. 25 dan kam yozilmaydi.';

  @override
  String get rulesDominoSeaWipe => 'Ikki kishida birdaniga 25 va undan ko‘p bo‘lsa, bu kon hech kimga yozilmaydi.';

  @override
  String get rulesDominoSeaBlank => 'Qo‘yilgan 0-0 konni darhol tugatadi: eng og‘ir qo‘lga 75 yoziladi. Ikkitasi bo‘lsa — hech kimga yozilmaydi.';

  @override
  String get rulesDominoSeaSix => 'Kon oxirgi 6-6 tosh bilan yopilsa, yutqazganga 100 yoziladi, yopganning partiya hisobi nolga tushadi.';

  @override
  String get rulesDominoSeaMatch => 'Partiya 125 gacha. Yig‘gan yutqazadi.';

  @override
  String get dominoBoneyard => 'Bozor';

  @override
  String get dominoChooseEnd => 'Uchni tanlang';

  @override
  String get dominoFish => 'Baliq';

  @override
  String get dominoYouGoat => 'Siz kozelsiz';

  @override
  String dominoGoatNamed(String name) {
    return 'Kozel — $name';
  }

  @override
  String get dominoLeft => 'Chap';

  @override
  String get dominoRight => 'O‘ng';

  @override
  String get gamesChessModeClassic => 'Klassika';

  @override
  String get gamesChessModeRapid => 'Rapid';

  @override
  String get gamesChessModeBlitz => 'Blits';

  @override
  String get gamesChessModeBullet => 'O‘q';

  @override
  String get chessPieceQueen => 'Farzin';

  @override
  String get chessPieceRook => 'Rux';

  @override
  String get chessPieceBishop => 'Fil';

  @override
  String get chessPieceKnight => 'Ot';

  @override
  String get chessPromotionTitle => 'Piyodani almashtirish';

  @override
  String get chessDrawStalemate => 'Durrang: pat';

  @override
  String get chessDrawInsufficient => 'Durrang: mat uchun material yetarli emas';

  @override
  String get chessDrawRepetition => 'Durrang: pozitsiyaning uch marta takrorlanishi';

  @override
  String get chessDrawFiftyMove => 'Durrang: 50 yurish qoidasi';

  @override
  String get chessCheck => 'Shoh';

  @override
  String get rulesCheckersPlayers => 'O‘yinchilar: 2.';

  @override
  String rulesCheckersMode(String mode) {
    return 'Rejim: $mode.';
  }

  @override
  String rulesCheckersTime(String time) {
    return 'Время на ход: $time. Если время вышло — проигрыш.';
  }

  @override
  String get rulesCheckersIntro => 'Doska 8×8. Ikki o‘yinchi.';

  @override
  String get rulesCheckersPlay => 'Urish majburiy. Damka va oddiy tosh qo‘ngan katakdan yana ura olsa, to‘xtamasdan davom ettirishi shart. Yo‘nalishlar ko‘p bo‘lsa, istalganini tanlash mumkin, eng uzun yo‘l shart emas. Oxirgi qatorga yetgan oddiy tosh damkaga aylanadi.';

  @override
  String get rulesCheckersWin => 'В русских шашках побеждает тот, кто съел все шашки соперника или лишил его хода. В поддавках наоборот: кто не может ходить — выигрывает.';

  @override
  String get rulesCheckersOfflineBot => 'Офлайн: партия против бота.';

  @override
  String get rulesCheckersPlayRussian => 'Rus shashkasi: har kimda qora kataklarda 12 tosh. Oddiy toshlar oldinga diagonal yuradi, oldinga va orqaga ura oladi. Damka istalgan katakcha uchadi. Urish majburiy: davom ettirish mumkin bo‘lsa to‘xtab bo‘lmaydi, lekin yo‘nalishlar ko‘p bo‘lsa istalganini tanlaysiz, eng uzini shart emas. G‘olib — raqibning barcha toshini yegan yoki uni yurishsiz qoldirgan.';

  @override
  String get rulesCheckersPlayEnglish => 'Ingliz shashkasi: har kimda 12 tosh. Oddiy toshlar faqat oldinga diagonal yuradi va uradi. Damka istalgan tomonga bir katak yuradi. Urish majburiy. G‘olib — raqibning barcha toshini yegan yoki uni yurishsiz qoldirgan.';

  @override
  String get rulesCheckersPlayGiveaway => 'Berilmali: yurishlar rus shashkasidagidek, lekin maqsad teskarisi — barcha toshni berib qo‘yish yoki yurishsiz qolish. Urish baribir majburiy.';

  @override
  String get rulesCheckersPlayCorners => 'Burchaklar: toshlar qarama-qarshi burchaklarda turadi. Yonidagi bo‘sh katakcha gorizontal yoki vertikal yuradi yoki istalgan toshdan sakrab o‘tadi, uni olmaydi. Maqsad — barcha toshni raqib burchagiga o‘tkazish.';

  @override
  String get rulesCheckersPlayCornersNoReturn => 'Boshlang‘ich burchagini tark etgan tosh u yerga qayta olmaydi.';

  @override
  String get rulesCheckersPlayCornersLeaveHome => 'Hali uydagi toshlar o‘yinchining dastlabki 25 yurishida uydan chiqishi kerak.';

  @override
  String get rulesCheckersDrawRussian => 'Durang: pozitsiya uch marta takrorlansa yoki har tomonning 15 yurishi ilgarilamasdan o‘tsa: olish, oddiy yurish va farzinga aylanish yo‘q.';

  @override
  String get rulesCheckersDrawEnglish => 'Durang: pozitsiya uch marta takrorlansa, har tomonning 40 yurishida olish va oddiy yurish bo‘lmasa, yoki har tomonda bitta farzin qolsa.';

  @override
  String get rulesCheckersDrawGiveaway => 'Durang: pozitsiya uch marta takrorlansa yoki poddavkidagi har tomonning 15 yurishi ilgarilamasdan o‘tsa: olish, oddiy yurish va farzinga aylanish yo‘q.';

  @override
  String get rulesCheckersDrawCorners => 'Durang: pozitsiya uch marta takrorlansa yoki har tomonning 25 yurishi maqsad burchagiga tosh qo‘shmasa.';

  @override
  String get rulesChessPlayers => 'O‘yinchilar: 2.';

  @override
  String rulesChessMode(String mode) {
    return 'Rejim: $mode.';
  }

  @override
  String get rulesChessPlayClassic => 'Doska 8×8. Har tomonda shoh, vazir, ikki rux, ikki fil, ikki ot va sakkiz piyoda. Oqlar boshlaydi. Oddiy yurishlar, o‘tishda olish, o‘girish va rokirovka bor. Mat yoki taslim — g‘alaba.';

  @override
  String get rulesChessDrawClassic => 'Durang: pat, uch marta takror, 50 yurish, mat uchun dona yetmasa yoki kelishuv.';

  @override
  String get rulesChessClockClassic => 'Partiya nazorati: 60+0 — butun o‘yinga 60 daqiqa, qo‘shimcha yo‘q.';

  @override
  String get rulesChessClockRapid => 'Partiya nazorati: 10+0 — butun o‘yinga 10 daqiqa, qo‘shimcha yo‘q.';

  @override
  String get rulesChessClockBlitz => 'Partiya nazorati: 5+0 — butun o‘yinga 5 daqiqa, qo‘shimcha yo‘q.';

  @override
  String get rulesChessClockBullet => 'Partiya nazorati: 3+2 — 3 daqiqa plus har yurishga 2 soniya.';

  @override
  String get checkersDrawRepetition => 'Durang — pozitsiya uch marta takrorlandi';

  @override
  String get checkersDrawNoProgress => 'Durang — yurishlar g‘alabaga olib kelmaydi';

  @override
  String get checkersDrawInsufficient => 'Durang — g‘alaba uchun kuch yetarli emas';

  @override
  String get rulesNardyTitle => 'Narda — qoidalar';

  @override
  String get rulesNardyPlayers => 'O‘yinchilar: 2.';

  @override
  String rulesNardyMode(String mode) {
    return 'Rejim: $mode.';
  }

  @override
  String get rulesNardyIntro => 'Doskada 24 punkt, har kimda 15 tosh. Ikki zar: bitta tosh bilan yig‘indiga yoki ikkitasi bilan zarning ochkolariga yurasiz.';

  @override
  String get rulesNardyPlayShort => 'Qisqa narda: qarshi yurasiz va yolg‘iz toshlarni ura olasiz. Urilgan tosh barga chiqadi va qayta kirishi kerak. Hamma tosh uyda bo‘lsa, ularni doskadan olasiz.';

  @override
  String get rulesNardyPlayLong => 'Uzun narda: ikkalasi ham bir boshdan boshlab bir tomonga yuradi. Boshdan bir yurishda faqat bitta tosh chiqadi. Urish mumkin emas. Hammasi uyda bo‘lsa, toshlarni olasiz.';

  @override
  String get rulesNardyWin => 'Barcha toshlarini birinchi olgan g‘olib.';

  @override
  String get rulesNardySixPrime => 'Raqibning birorta toshi o‘tmaguncha, ketma-ket oltita punktni yopib bo‘lmaydi.';

  @override
  String get nardyRoll => 'Tashlash';

  @override
  String get nardySkipTurn => 'Yurishni o‘tkazish';

  @override
  String get nardyUndoMove => 'Qaytarish';

  @override
  String get nardyDoneTurn => 'Tayyor';

  @override
  String get nardyAutoConfirm => 'Avtotasdiqlash';

  @override
  String get nardyAutoConfirmHint => 'Barcha yurishlardan so‘ng navbat avtomatik o‘tadi';

  @override
  String get nardyLayoutToggle => 'Joylashuvni almashtirish';

  @override
  String get nardyNoMoves => 'Yurish yo‘q';

  @override
  String get nardyYourRoll => 'Sizning tashlashingiz';

  @override
  String get nardyPipsShort => 'Qoldi:';

  @override
  String get nardyYouWonMars => 'Siz yutdingiz — mars!';

  @override
  String get nardyYouLostMars => 'Mag‘lubiyat — mars';

  @override
  String get rulesNardyOfflineBot => 'Oflayn: bot bilan o‘yin.';

  @override
  String rulesUnoPlayers(int players) {
    return 'Oʻyinchilar: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'Botga qarshi o‘yin, yurish vaqti cheklanmagan.';

  @override
  String get rulesUnoIntro => 'Har kimga 7 ta karta tarqatiladi. Xuddi shu rang yoki xuddi shu qiymatdagi (raqam yoki bir xil maxsus) kartani yuring.';

  @override
  String get rulesUnoPlay => 'O‘tkazish — keyingi o‘yinchi yurishni yo‘qotadi. Ikki kishida yo‘nalishni o‘zgartirish o‘tkazishdek ishlaydi. +2 ni faqat +2 ustiga, +4 ni faqat +4 ustiga qo‘yish mumkin: jarima qo‘shiladi (ikkita +2 — keyingisi 4 ta oladi). +2 ni +4 ustiga qo‘yib bo‘lmaydi. Javob bermagan butun to‘plamni oladi va yurishni o‘tkazadi.Bir xil ikkita yovvoyi bo‘lmagan karta (masalan, ikkita sariq 8) birga tashlanadi: bittasini tashlasangiz, jufti o‘zi ketadi.';

  @override
  String get rulesUnoWild => 'Qora karta yangi rang belgilaydi. +4 ni faqat joriy rang kartasi bo‘lmasa tashlash mumkin. Raqib e’tiroz qilishi mumkin: +4 qonuniy bo‘lsa — e’tirozchi 6 oladi; aks holda +4 muallifi 4 oladi, e’tirozchi yuradi.';

  @override
  String get rulesUnoDraw => 'Mos karta bo‘lmasa — kolodadan bittasini oling. Mos kelsa, darhol yurish yoki qoldirib navbatni o‘tkazish mumkin. Yurish bor ekan, olish mumkin emas.';

  @override
  String get rulesUnoWin => 'Ikki kishida 100, 3+ o‘yinchida 200. Raundni barcha kartasini tashlagan yutadi.';

  @override
  String get rulesUnoCall => 'Bitta karta qolganda darhol «Uno!» ni bosing. Raqiblar Unosiz sizni faqat bir soniyadan keyin ushlashi mumkin — unda 2 karta olasiz.';

  @override
  String get rulesUnoScoring => 'Kartalarini birinchi tashlagan raundni yutadi va raqiblar qo‘lidagi ochkolarni oladi: raqamlar — qiymati, maxsuslar — 20, qoralar — 50. Ikki kishida 100, 3+ o‘yinchida 200.';

  @override
  String get unoColorRed => 'Qizil';

  @override
  String get unoColorYellow => 'Sariq';

  @override
  String get unoColorGreen => 'Yashil';

  @override
  String get unoColorBlue => 'Ko‘k';

  @override
  String get unoDraw => 'Olish';

  @override
  String get unoKeep => 'Qoldirish';

  @override
  String get unoSayUno => 'Uno!';

  @override
  String get unoChallengeUno => 'Uno e’tirozi';

  @override
  String get unoChallengeWd4 => '+4 e’tirozi';

  @override
  String get unoChooseColor => 'Rang tanlang';

  @override
  String get unoDrawPile => 'Koloda';

  @override
  String get unoDiscardPile => 'Tashlanganlar';

  @override
  String unoCardsCount(int count) {
    return 'Kartalar: $count';
  }

  @override
  String unoScore(int score) {
    return 'Ball: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return '$round-raund · $target gacha';
  }

  @override
  String get unoYourTurn => 'Sizning yurishingiz';

  @override
  String get unoWaitingTurn => 'Raqib yurishi';

  @override
  String get unoChooseColorHint => 'Qora karta uchun rang tanlang';

  @override
  String get unoWd4Hint => '4 karta oling yoki Wild +4 ga e’tiroz qiling';

  @override
  String get unoDrawnHint => 'Olingan kartani o‘ynang yoki qoldiring';

  @override
  String get unoPlayHint => 'Mos rang yoki qiymatni o‘ynang';

  @override
  String get unoDrawHint => 'Mos karta yo‘q — kolodadan oling';

  @override
  String unoPendingDraw(int count) {
    return '+$count karta';
  }

  @override
  String get unoYouWon => 'Siz o‘yinni yutdingiz!';

  @override
  String get unoYouLost => 'O‘yin tugadi';

  @override
  String get unoYouLostTimeout => 'Vaqt tugagani uchun yutqazdingiz';

  @override
  String unoWinner(String name) {
    return 'G‘olib: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name raundni yutadi';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'Keyingi';

  @override
  String get unoRoundScoresTitle => 'Raund ochkolari';

  @override
  String get unoDirectionClockwise => 'Soat yo‘nalishida';

  @override
  String get unoDirectionCounterclockwise => 'Soat yo‘nalishiga qarshi';

  @override
  String get unoErrStackSameOnly => '+2 ustiga faqat +2, +4 ustiga faqat +4 qo‘yiladi. +2 ni +4 ustiga qo‘yib bo‘lmaydi.';

  @override
  String get unoErrCatchTooEarly => 'Bir soniya kuting — ular hali «Uno» deyishlari mumkin.';

  @override
  String get unoErrCallTooLate => 'Endi «Uno» deyib bo‘lmaydi. Keyingi o‘yinchi yurib bo‘ldi.';

  @override
  String get gamesInDevelopment => 'Ishlanmoqda';

  @override
  String rulesPokerPlayers(int players) {
    return 'O‘yinchilar: $players.';
  }

  @override
  String get rulesPokerIntro => 'Texas Hold’em. Har bir o‘yinchiga 2 ta qo‘l kartasi beriladi; stolga 5 ta umumiy karta chiqadi.';

  @override
  String get rulesPokerPlay => 'Stavka raundlari: preflop, flop, turn va river. Fold, call, bet yoki raise qilish mumkin.';

  @override
  String get rulesPokerWin => 'G‘olib — beshta kartaning eng yaxshi kombinatsiyasi (qo‘l + umumiy) yoki foldlardan keyin yolg‘iz qolgan o‘yinchi.';

  @override
  String get pokerFold => 'Fold';

  @override
  String get pokerCheck => 'Check';

  @override
  String pokerCall(int amount) {
    return 'Call $amount';
  }

  @override
  String get pokerCallShort => 'Call';

  @override
  String get pokerRaise => 'Raise';

  @override
  String pokerRaiseTo(int amount) {
    return 'Raise to $amount';
  }

  @override
  String get pokerRaiseTitle => 'Raise';

  @override
  String get pokerAllIn => 'All-in';

  @override
  String get pokerAllInBadge => 'All-in';

  @override
  String get pokerFolded => 'Folded';

  @override
  String pokerPot(int amount) {
    return 'Pot: $amount';
  }

  @override
  String get pokerYourTurn => 'Your turn';

  @override
  String pokerToAct(String name) {
    return '$name to act';
  }

  @override
  String pokerWinner(String name) {
    return '$name wins';
  }

  @override
  String get pokerYouWonHand => 'You won the pot!';

  @override
  String pokerWinners(String names) {
    return '$names win';
  }

  @override
  String pokerYouWonHandWith(String names) {
    return 'You and $names won the pot!';
  }

  @override
  String get pokerListAnd => 'and';

  @override
  String get pokerHandOver => 'Hand over';

  @override
  String get pokerStreetPreflop => 'Pre-flop';

  @override
  String get pokerStreetFlop => 'Flop';

  @override
  String get pokerStreetTurn => 'Turn';

  @override
  String get pokerStreetRiver => 'River';

  @override
  String get pokerStreetShowdown => 'Showdown';

  @override
  String get pokerHandHighCard => 'High card';

  @override
  String get pokerHandOnePair => 'One pair';

  @override
  String get pokerHandTwoPair => 'Two pair';

  @override
  String get pokerHandThreeOfAKind => 'Three of a kind';

  @override
  String get pokerHandStraight => 'Straight';

  @override
  String get pokerHandFlush => 'Flush';

  @override
  String get pokerHandFullHouse => 'Full house';

  @override
  String get pokerHandFourOfAKind => 'Four of a kind';

  @override
  String get pokerHandStraightFlush => 'Straight flush';

  @override
  String get pokerHandRoyalFlush => 'Royal flush';

  @override
  String get pokerCombinationsTitle => 'Kombinatsiyalar';

  @override
  String pokerHandNumber(int n) {
    return 'Hand $n';
  }

  @override
  String pokerBlinds(int sb, int bb) {
    return 'Blinds $sb/$bb';
  }

  @override
  String get pokerTableYouWon => 'You won the table!';

  @override
  String get pokerNextHandSoon => 'Next hand…';

  @override
  String get pokerShowCards => 'Show cards';

  @override
  String get rulesPokerTable => 'The table plays until one player holds all the chips. Blinds rise every 6–8 hands (heads-up 8, 3-max 7, 4-max 6).';

  @override
  String get gamesRules => 'Qoidalar';

  @override
  String get gamesRulesTitle => 'O‘yin qoidalari';

  @override
  String get gamesCreate => 'O‘yin yaratish';

  @override
  String get gamesJoin => 'Qo‘shilish';

  @override
  String get gamesOpponentTurn => 'Raqib yurishi';

  @override
  String get gamesCurrentGame => 'Joriy o‘yin';

  @override
  String get gamesInvitedYou => 'Sizni taklif qilishdi';

  @override
  String get gamesTurnTime => 'Yurish vaqti';

  @override
  String get gamesGridSize => 'To‘r o‘lchami';

  @override
  String get gamesSwapSides => 'Tomonlarni almashtirish';

  @override
  String get gamesNoCenter => 'Markazdan boshlash yo‘q';

  @override
  String get gamesObservation => 'Kuzatish';

  @override
  String get gamesObservationHint => 'O‘yin tugaguncha kuzatishingiz mumkin';

  @override
  String get gamesFinishCurrentFirst => 'Avval joriy o‘yiningizni tugating';

  @override
  String get gamesVariantClassic => 'Klassik';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 o‘yinchi';

  @override
  String get gamesVariantMulti4 => '4 o‘yinchi';

  @override
  String get gamesDurakModePodkidnoi => 'Tashlama';

  @override
  String get gamesDurakModePerevodnoi => 'O‘tkazmali';

  @override
  String get gamesDurakDeck24 => '24 karta';

  @override
  String get gamesDurakDeck36 => '36 karta';

  @override
  String get gamesDurakDeck52 => '52 karta';

  @override
  String rulesDurakMode(String mode) {
    return 'Rejim: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'O‘yinchilar: $players. Koloda: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Botga qarshi o‘yin, stavka va vaqt cheklovisiz.';

  @override
  String get rulesDurakAttack => 'Hujumchi kartalar qo‘yadi, himoyachi uradi (shu mast yuqoriroq yoki kozir). Kozir faqat yuqoriroq kozir bilan uriladi.';

  @override
  String get rulesDurakBeat => 'Barcha kartalar urilganda hujumchi «Bito» deydi, kartalar otboyga ketadi. Aks holda himoyachi stoldagi hammasini oladi.';

  @override
  String get rulesDurakLoser => 'Yutqazgan — partiya oxirida kartalari qolgan o‘yinchi, «durak».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'O‘yinchilar $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Lobi $name';
  }

  @override
  String get lobbyMatchmake => 'Lobi';

  @override
  String get lobbyPrivateGame => 'Shaxsiy o‘yin';

  @override
  String get lobbySearchingOpponent => 'Raqib qidirilmoqda…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Bu o‘yinni qidiryapti: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Kimdir «O‘yin topish» yoki «Qo‘shilish»ni bosishini kutmoqdamiz';

  @override
  String get lobbyInviteTitle => 'O‘yinga taklif';

  @override
  String get lobbyInvitedToPlay => 'Sizni o‘ynashga taklif qilishdi';

  @override
  String get lobbyEnterGame => 'O‘yinga kirish';

  @override
  String get lobbyGone => 'Lobbi endi mavjud emas';

  @override
  String get lobbyInvite => 'Taklif qilish';

  @override
  String get lobbyInviteSent => 'Taklif yuborildi';

  @override
  String get lobbyCopyLink => 'O‘yin havolasini ulashish';

  @override
  String get lobbyLinkCopied => 'Havola nusxalandi';

  @override
  String get lobbyNoFriendsOnline => 'Onlayn do‘stlar yo‘q. Yuqoridagi o‘yin havolasini ulashing yoki do‘stlaringiz onlayn bo‘lishini kuting.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Raqib';

  @override
  String get gameYou => 'Siz';

  @override
  String get gameYouWon => 'Siz yutdingiz!';

  @override
  String get gameYouWonShort => 'Siz yutdingiz';

  @override
  String get gameYouLost => 'Yutqazdingiz';

  @override
  String get gameYouWonOpponentLeft => 'Siz yutdingiz — raqib chiqib ketdi';

  @override
  String get gameYouWonOpponentTimeout => 'Siz yutdingiz — raqib vaqti tugadi';

  @override
  String get gameDraw => 'Durrang';

  @override
  String get gameExitTitle => 'O‘yindan chiqish';

  @override
  String get gameExitConfirm => 'Chiqsangiz, mag‘lub bo‘lasiz. Baribir chiqasizmi?';

  @override
  String get gameStay => 'Qolish';

  @override
  String get gameLeave => 'Chiqish';

  @override
  String get gameSurrender => 'Taslim bo‘lish';

  @override
  String get gameSurrenderTitle => 'Taslim bo‘lasizmi?';

  @override
  String get gameSurrenderConfirm => 'Siz partiya va stavka tangalarini yo‘qotasiz.';

  @override
  String get gameOfferDraw => 'Durrang taklif qilish';

  @override
  String get gameFlipBoard => 'Taxtani aylantirish';

  @override
  String get gameReviewStart => 'O\'yin boshiga';

  @override
  String get gameReviewPrev => 'Bir yurish orqaga';

  @override
  String get gameReviewNext => 'Bir yurish oldinga';

  @override
  String get gameReviewEnd => 'Joriy holatga';

  @override
  String get gameOfferDrawTitle => 'Durrang taklif qilinsinmi?';

  @override
  String get gameOfferDrawConfirm => 'Raqib durrangni qabul qilishi yoki rad etishi mumkin.';

  @override
  String get gameAcceptDrawTitle => 'Durrang qabul qilinsinmi?';

  @override
  String get gameAcceptDrawConfirm => 'Partiya durrang bilan tugaydi.';

  @override
  String get gameDrawOffered => 'Raqib durrang taklif qilmoqda';

  @override
  String get gameConnecting => 'O‘yinga ulanilmoqda…';

  @override
  String get gameWaitingOpponent => 'Raqib kutilmoqda';

  @override
  String get gameRematchOffer => 'Raqib qayta o‘ynashni taklif qilmoqda';

  @override
  String get gameRematchDeclined => 'Raqib qayta o‘ynashni rad etdi';

  @override
  String get gameRematch => 'Qayta o‘ynash';

  @override
  String get gameOtherOpponent => 'Boshqa raqib';

  @override
  String get gameSwapSidesAction => 'Tomonlarni almashtirish';

  @override
  String get gameWriteMessage => 'Xabar yozish';

  @override
  String get chatsTitle => 'Chatlar';

  @override
  String get chatsEmpty => 'Hali chatlar yo‘q.\nYuqori o‘ngdagi belgini bosib, do‘st tanlang va suhbatni boshlang.';

  @override
  String get chatsNewChat => 'Yangi chat';

  @override
  String get chatsNoMessages => 'Xabarlar yo‘q';

  @override
  String get chatsClearTitle => 'Suhbat tozalansinmi?';

  @override
  String get chatsClearDesc => 'Chat butunlay o‘chiriladi.';

  @override
  String get chatsClearConfirm => 'Tozalash';

  @override
  String get chatsBlockTitle => 'Bu foydalanuvchi bloklansinmi?';

  @override
  String get chatsBlockDesc => 'Endi bir-biringizga yoza olmaysiz. Chat va do‘stlik o‘chiriladi.';

  @override
  String get chatsBlockConfirm => 'Bloklash';

  @override
  String get chatsBlockedUsers => 'Bloklangan foydalanuvchilar';

  @override
  String get chatsUnblock => 'Blokdan chiqarish';

  @override
  String get chatDialog => 'Chat';

  @override
  String get chatEmpty => 'Hali xabarlar yo‘q.\nBirinchisini yuboring.';

  @override
  String get chatMessageHint => 'Xabar';

  @override
  String get chatPaste => 'Qo‘yish';

  @override
  String get chatEmoji => 'Emoji';

  @override
  String get chatBuyEmojiHint => 'Bosh ekrandagi do‘kondan emoji sotib oling';

  @override
  String get chatEditing => 'Tahrirlash';

  @override
  String get chatToday => 'Bugun';

  @override
  String get chatYesterday => 'Kecha';

  @override
  String get chatFriendsOnly => 'Matn faqat do‘stlar uchun';

  @override
  String get emojiGroupEmotions => 'Hissiyotlar';

  @override
  String get emojiGroupGame => 'O‘yin';

  @override
  String get emojiGroupFlags => 'Bayroqlar';

  @override
  String get emojiGroupAnimals => 'Hayvonlar';

  @override
  String get emojiGroupFood => 'Ovqat';

  @override
  String get emojiGroupTravel => 'Sayohat';

  @override
  String get emojiGroupParty => 'Bayram';

  @override
  String get emojiGroupObjects => 'Buyumlar';

  @override
  String get friendsTitle => 'Do‘stlar';

  @override
  String get friendsTabFriends => 'Do‘stlar';

  @override
  String get friendsTabIncoming => 'Kiruvchi';

  @override
  String get friendsTabOutgoing => 'Chiquvchi';

  @override
  String get friendsAdd => 'Do‘st qo‘shish';

  @override
  String get friendsRequestSent => 'So‘rov yuborildi';

  @override
  String get friendsFindTab => 'Do‘st topish';

  @override
  String get friendsSearchHint => 'Login bo‘yicha qidirish';

  @override
  String get friendsSearchPrompt => 'Yangi do‘stlar topish uchun qidiruvdan foydalaning';

  @override
  String get friendsNothingFound => 'Hech narsa topilmadi';

  @override
  String get friendsEmpty => 'Hali do‘stlaringiz yo‘q';

  @override
  String get friendsSearchNoMatches => 'Qidiruvga mos do‘stlar yo‘q';

  @override
  String get friendsIncomingSearchNoMatches => 'Qidiruvga mos kiruvchi so‘rovlar yo‘q';

  @override
  String get friendsOutgoingSearchNoMatches => 'Qidiruvga mos chiquvchi so‘rovlar yo‘q';

  @override
  String get friendsNoIncoming => 'Kiruvchi so‘rovlar yo‘q';

  @override
  String get friendsNoOutgoing => 'Chiquvchi so‘rovlar yo‘q';

  @override
  String get friendsAlreadyFriends => 'Allaqachon do‘stsiz';

  @override
  String get friendsRemoveTitle => 'Do‘stlardan olib tashlansinmi?';

  @override
  String get friendsRemoved => 'Do‘stlardan olib tashlandi';

  @override
  String get friendsRequestAccepted => 'So‘rov qabul qilindi';

  @override
  String get friendsRequestDeclined => 'So‘rov rad etildi';

  @override
  String get friendsRequestCancelled => 'So‘rov bekor qilindi';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSignInPrompt => 'Hisobingizga kiring';

  @override
  String get profileSignInHint => 'Shaxsiy profilingizni sozlash uchun';

  @override
  String get profileEdit => 'Tahrirlash';

  @override
  String get profileCollections => 'Kolleksiyalar';

  @override
  String get profileAge => 'Yosh';

  @override
  String get profileGender => 'Jins';

  @override
  String get profileGenderUnset => 'Ko‘rsatilmagan';

  @override
  String get profileGenderMale => 'Erkak';

  @override
  String get profileGenderFemale => 'Ayol';

  @override
  String get profileAvatar => 'Avatar';

  @override
  String get profileUploadPhoto => 'Foto yuklash';

  @override
  String get profileChangePhoto => 'Avatarni o‘zgartirish';

  @override
  String get shopTitle => 'Do‘kon';

  @override
  String get shopEmojis => 'Emoji';

  @override
  String get shopEmojisSubtitle => 'Chat uchun animatsiyali emoji';

  @override
  String get shopCollections => 'Kolleksiyalar';

  @override
  String get shopCollectionsSubtitle => 'Profil vitrinasi, sovg‘alar va daromad';

  @override
  String get shopStakes => 'Stavkalar';

  @override
  String get shopStakesSubtitle => 'Yuqori stavkalarni ochish';

  @override
  String get shopEmojisHelp => 'Chat uchun animatsion smayliklar. To‘plamni sotib oling va do‘stlaringizga yuboring.';

  @override
  String get shopCollectionsHelp => 'Faqat yangi yoki vintaj kolleksiyani sotish mumkin: yangi narxning 80%i, vintaj narxning 300%i. Yeyilgan, charchagan va eskisini sotib bo‘lmaydi.\n\nBuyumlar to‘plamini yig‘ing: ular profil vitrinasida ko‘rinadi, sovg‘a qilish mumkin. Har bir buyum har kuni tanga beradi, to‘liq to‘plam esa alohida bonus ham beradi.\n\nBuyumning kunlik daromadi holatiga bog‘liq va odatdagi summadan hisoblanadi. Yangi 100% beradi. Yeyilgan — 60%. Charchagan — 40%. Eski — 100%. Vintaj buyum 200% beradi, ya’ni odatdagi kunlik daromaddan ikki baravar ko‘p.\n\nTo‘liq to‘plam bonusi to‘plamning o‘zi vintaj bo‘lguncha o‘zgarmaydi. To‘plam vintaj, agar undagi har bir buyum vintaj bo‘lsa: bonus shunda 300%, odatdagidan uch baravar ko‘p.\n\nHolat buyum sizda qancha bo‘lganiga bog‘liq. Yangi — dastlabki 7 kun. Yeyilgan — 8-kundan 2 oygacha. Charchagan — 2 oydan 6 oygacha. Eski — 6 oydan 1 yilgacha. Vintaj — 1 yildan keyin.';

  @override
  String get shopStakesHelp => 'O‘yinlarda yuqori stavkalarni oching. Stavka qanchalik yuqori bo‘lsa, bank va yutuq shunchalik katta.';

  @override
  String get inventoryTitle => 'Buyumlar';

  @override
  String get inventoryEmpty => 'Hali hech narsa yo‘q — do‘konga qarang';

  @override
  String get inventoryFrames => 'Ramkalar';

  @override
  String get inventoryClaim => 'Olish';

  @override
  String get inventorySell => 'Sotish';

  @override
  String get inventoryGift => 'Sovg‘a qilish';

  @override
  String get messageEdited => 'tahrirlandi';

  @override
  String get messageDeleted => 'Xabar o‘chirildi';

  @override
  String get photo => 'Foto';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galereya';

  @override
  String get connectionError => 'Serverga ulanib bo‘lmadi.';

  @override
  String get serverError => 'Server xatosi. Keyinroq qayta urinib ko‘ring.';

  @override
  String get sessionExpired => 'Sessiya muddati tugadi. Qayta kiring.';

  @override
  String get errNoInternet => 'Internet aloqasi yo‘q.';

  @override
  String get errTimeout => 'So‘rov vaqti tugadi. Qayta urinib ko‘ring.';

  @override
  String get errGamesUnavailable => 'O‘yinlar vaqtincha mavjud emas';

  @override
  String get errSettingsSaveFailed => 'Sozlamani saqlab bo‘lmadi';

  @override
  String get errPushPermission => 'Brauzer yoki tizim sozlamalarida bildirishnomalarga ruxsat bering.';

  @override
  String get balanceTitle => 'Balans';

  @override
  String get coinBronze => 'Bronza';

  @override
  String get coinSilver => 'Kumush';

  @override
  String get coinGold => 'Oltin';

  @override
  String get coinDiamond => 'Olmos';

  @override
  String get balanceZeroBronze => '0 bronza';

  @override
  String balanceBronzes(int count) {
    return '$count bronza';
  }

  @override
  String balanceSilvers(int count) {
    return '$count kumush';
  }

  @override
  String balanceGolds(int count) {
    return '$count oltin';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count olmos';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/kun';
  }

  @override
  String get balanceAbbrBronze => 'br';

  @override
  String get balanceAbbrSilver => 'k.';

  @override
  String get balanceAbbrGold => 'o.';

  @override
  String get commonBackHome => 'Bosh sahifaga qaytish';

  @override
  String get commonCopied => 'Nusxalandi';

  @override
  String get commonClear => 'Tozalash';

  @override
  String get commonTryLater => 'Keyinroq qayta urinib ko‘ring.';

  @override
  String get commonTryRefresh => 'Sahifani yangilab ko‘ring.';

  @override
  String get coinsTitle => 'Tangalar';

  @override
  String get coinsLoginReward => 'Kirish mukofoti';

  @override
  String get coinsLoginAvailableToday => 'Bugungi mukofot mavjud';

  @override
  String get coinsLoginStreak => 'Kundalik kirish seriyasi';

  @override
  String get coinsFriendReward => 'Do‘st mukofoti';

  @override
  String get coinsTasks => 'Vazifalar';

  @override
  String get coinsTasksSubtitle => 'Profil, do‘stlar va o‘yin mukofotlari';

  @override
  String get coinsTasksRewards => 'Olish uchun mukofotlar bor';

  @override
  String coinsFriendRewardHint(String amount) {
    return 'Havolangiz orqali ro‘yxatdan o‘tish uchun +$amount';
  }

  @override
  String get coinsLoadRewardsFailed => 'Mukofotlarni yuklab bo‘lmadi';

  @override
  String get coinsClaimReward => 'Mukofotni olish';

  @override
  String get coinsAlreadyClaimed => 'Allaqachon olingan';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · bugun';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · yana 1 kun';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · yana $remaining';
  }

  @override
  String get coinsInviteFriend => 'Do‘stni taklif qilish';

  @override
  String coinsInviteHint(String amount) {
    return 'Havolangiz orqali ro‘yxatdan o‘tgan har bir kishi uchun +$amount';
  }

  @override
  String get coinsCopyLink => 'Havolani nusxalash';

  @override
  String get coinsHowItWorks => 'Qanday ishlaydi';

  @override
  String get coinsHowStep1 => 'Havolani nusxalang va do‘stingizga yuboring';

  @override
  String get coinsHowStep2 => 'Do‘st shu havola orqali ro‘yxatdan o‘tadi';

  @override
  String coinsHowStep3(String amount) {
    return 'Sizga $amount beriladi';
  }

  @override
  String get achievementsTitle => 'Yutuqlar';

  @override
  String achievementsProgress(String progress) {
    return 'Progress: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Ramka olindi';

  @override
  String get achievementsClaimed => 'Olindi';

  @override
  String get achievementsOpenFrame => 'Ramkani ochish';

  @override
  String friendsRemoveConfirm(String name) {
    return '$name ni do‘stlardan olib tashlamoqchimisiz?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Olib tashlash';

  @override
  String get friendsRemove => 'Do‘stlardan o‘chirish';

  @override
  String get friendsAcceptRequest => 'So‘rovni qabul qilish';

  @override
  String get friendsDeclineRequest => 'So‘rovni rad etish';

  @override
  String get friendsCancelRequest => 'So‘rovni bekor qilish';

  @override
  String get friendsSendRequest => 'Do‘stlik so‘rovini yuborish';

  @override
  String get friendsRequestAlreadySent => 'So‘rov allaqachon yuborilgan';

  @override
  String get friendsIncomingStatus => 'Kiruvchi so‘rov';

  @override
  String get friendsOutgoingStatus => 'Chiquvchi so‘rov';

  @override
  String get friendsNotFriends => 'Do‘st emas';

  @override
  String get friendsCollapseSearch => 'Qidiruvni yig‘ish';

  @override
  String get friendsExpandSearch => 'Qidiruvni ko‘rsatish';

  @override
  String get friendsLoadFailed => 'Do‘stlarni yuklab bo‘lmadi';

  @override
  String friendsSince(String date) {
    return 'Do‘stlik boshlanishi: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Kiruvchi so‘rov: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Chiquvchi so‘rov: $date';
  }

  @override
  String get userInfoTitle => 'Foydalanuvchi ma’lumoti';

  @override
  String profileAgeYears(int age) {
    return '$age yosh';
  }

  @override
  String get shopBuy => 'Sotib olish';

  @override
  String get shopBuyTitle => 'Sotib olasizmi?';

  @override
  String get shopBuyStakeTitle => 'Tikishni sotib olasizmi?';

  @override
  String get shopBuyEmojiTitle => 'Smayl sotib olasizmi?';

  @override
  String get shopBuyCollectionTitle => 'Kolleksiyani sotib olasizmi?';

  @override
  String shopPrice(String price) {
    return 'Narxi: $price';
  }

  @override
  String get shopOwned => 'Sotib olingan';

  @override
  String get shopHave => 'Bor';

  @override
  String get shopEmpty => 'Hali bo‘sh';

  @override
  String shopPurchased(String title) {
    return '$title sotib olindi';
  }

  @override
  String get shopEmojiUses => 'Olasiz: 10 foydalanish';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 foydalanish';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 foydalanish';
  }

  @override
  String get shopBuyTen => 'Sotib olish · 10 dona';

  @override
  String shopDailyIncome(String amount) {
    return 'Daromad: $amount';
  }

  @override
  String get shopBuyOnce => 'Bir martalik xarid';

  @override
  String get shopSellRefund => 'Sotish kolleksiya holatiga bog‘liq';

  @override
  String get collectionConditionNew => 'Yangi';

  @override
  String get collectionConditionWorn => 'Yeyilgan';

  @override
  String get collectionConditionTired => 'Charchagan';

  @override
  String get collectionConditionShabby => 'Eski';

  @override
  String get collectionConditionVintage => 'Vintaj';

  @override
  String shopCollectionAdded(String title) {
    return '$title profilga qo‘shildi';
  }

  @override
  String shopSetBonus(int percent) {
    return 'to‘plam bonusi +$percent%';
  }

  @override
  String get shopSetComplete => 'Yig‘ildi';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Yig‘ildi · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Sotasizmi?';

  @override
  String inventorySellDesc(String amount) {
    return 'Siz $amount olasiz';
  }

  @override
  String get inventoryCollectionNotSellable => 'Faqat yangi yoki vintaj kolleksiyani sotish mumkin.';

  @override
  String get inventoryCollectionNotSellableTitle => 'Sotib bo‘lmaydi';

  @override
  String get inventoryCollectionNotSellableHint => 'Faqat yangi yoki vintaj buyumni sotish mumkin. Holatini o‘zgartirish uchun eliksirdan foydalaning.';

  @override
  String inventorySold(String amount) {
    return 'Sotildi: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Avval do‘stlar qo‘shing';

  @override
  String get inventoryGiftTitle => 'Kolleksiyani sovg‘a qilasizmi?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return '«$title» ni $name ga sovg‘a qilasizmi?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Sovg‘a qilindi: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'O‘yinchida bu narsa allaqachon bor';

  @override
  String get inventoryGiftSelf => 'O‘zingizga hadya qilib bo‘lmaydi';

  @override
  String get inventoryGiftNotOwned => 'Bu narsa inventaringizda yo‘q';

  @override
  String get inventoryLoadFailed => 'Buyumlarni yuklab bo‘lmadi';

  @override
  String get inventoryNoCollections => 'Kolleksiya yo‘q — do‘kondan sotib oling';

  @override
  String get inventoryNoEmojis => 'Smayl yo‘q — do‘kondan sotib oling';

  @override
  String get inventoryNoFrames => 'Ramka yo‘q — ligada 10 o‘yin yuting (yutuqlar)';

  @override
  String get inventoryNoStakes => 'Sotib olingan tikishlar yo‘q';

  @override
  String inventoryEmojiLeft(int count) {
    return '$count qoldi';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Daromad: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Ertangi daromad: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Tayyor';

  @override
  String get inventoryIncomeTomorrowLabel => 'Ertaga';

  @override
  String inventoryStakeGold(String amount) {
    return '$amount oltin tikish mumkin';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return '$amount kumush tikish mumkin';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return '+$amount olindi';
  }

  @override
  String get chatsLoadFailed => 'Chatlarni yuklab bo‘lmadi';

  @override
  String get chatsLoadListFailed => 'Ro‘yxatni yuklab bo‘lmadi';

  @override
  String get chatsBlockedEmpty => 'Ro‘yxat bo‘sh';

  @override
  String chatsBlockedAt(String date) {
    return 'Bloklangan: $date';
  }

  @override
  String get chatsCreateFailed => 'Chat yaratib bo‘lmadi';

  @override
  String get chatsNeedFriendsFirst => 'Avval do‘stlar qo‘shing, keyin chat ochishingiz mumkin.';

  @override
  String get chatsFriendsNotFound => 'Do‘stlar topilmadi';

  @override
  String get chatsFindFriendHint => 'Nik bo‘yicha do‘st topish';

  @override
  String get chatsSelectChat => 'Chatni tanlang';

  @override
  String get chatsSelectHint => 'Chapdagi ro‘yxatdan suhbatni tanlang';

  @override
  String get chatEditFailed => 'Xabarni o‘zgartirib bo‘lmadi';

  @override
  String get chatSendFailed => 'Xabarni yuborib bo‘lmadi';

  @override
  String get chatDeleteFailed => 'Xabarni o‘chirib bo‘lmadi';

  @override
  String get chatEmojiSendFailed => 'Smaylni yuborib bo‘lmadi';

  @override
  String get chatLoadFailed => 'Xabarlarni yuklab bo‘lmadi';

  @override
  String get chatBackToGame => 'O‘yinga qaytish';

  @override
  String get chatBackToChats => 'Chatlarga qaytish';

  @override
  String get chatActions => 'Chat amallari';

  @override
  String get chatAutoTranslate => 'Avtomatik tarjima';

  @override
  String get chatScrollToEnd => 'Suhbat oxiriga';

  @override
  String chatReplyingTo(String name) {
    return '$name ga javob';
  }

  @override
  String get chatGift => 'Sovg‘a';

  @override
  String get chatCollection => 'Kolleksiya';

  @override
  String get chatGiftCollection => 'Sovg‘a · kolleksiya';

  @override
  String get chatThisUser => 'bu foydalanuvchi';

  @override
  String get gamesLobbyLoadFailed => 'Lobbi yuklab bo‘lmadi.';

  @override
  String get gamesTapChangeStake => 'Tikishni o‘zgartirish uchun bosing';

  @override
  String get gamesTapChangeTurnTime => 'Yurish vaqtini o‘zgartirish uchun bosing';

  @override
  String get gamesTapChangeGrid => 'To‘r o‘lchamini o‘zgartirish uchun bosing';

  @override
  String get gamesSwapSidesHint => 'O 1-yurishdan keyin X bo‘lishi mumkin';

  @override
  String get gamesNoCenterHint => 'Birinchi yurish markazda bo‘lmasin';

  @override
  String get lobbyInviteSentShort => 'Yuborildi';

  @override
  String get lobbySearchShort => 'Qidiruv';

  @override
  String get lobbySearchPlayers => 'O‘yinchi qidirish';

  @override
  String get lobbyInviteDeclinedShort => 'Rad etildi';

  @override
  String get lobbyInvitesSentWaiting => 'Takliflar yuborildi. Javob kutilmoqda.';

  @override
  String get lobbyLinkCopiedHint => 'Uni chatga yoki do‘stga xabarga joylashtiring';

  @override
  String get lobbyCopyLinkHint => 'Havolani vaqtinchalik xotiraga nusxalash';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name sizni o‘ynashga taklif qiladi';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name g‘alaba qozondi';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Vaqt tugadi. $name g‘alaba qozondi';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String get adminTitle => 'Admin';

  @override
  String get tournamentsTitle => 'Turnirlar';

  @override
  String get profileAgeInvalid => '1 dan 111 gacha yosh kiriting';

  @override
  String get profileSaveFailed => 'Profilni saqlab bo‘lmadi';

  @override
  String get profileNameHint => 'Lotin harflari, raqamlar, _ 10 belgigacha';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => '1 dan 111 gacha';

  @override
  String get profileAboutHint => '100 belgigacha (ixtiyoriy)';

  @override
  String get profileProcessingPhoto => 'Foto qayta ishlanmoqda…';

  @override
  String get profileCropTitle => 'Avatar maydonini tanlang';

  @override
  String get profileCropHint => 'Fotoni kattalashtiring va siljiting';

  @override
  String get profileApply => 'Qo‘llash';

  @override
  String get profilePreparing => 'Tayyorlanmoqda…';

  @override
  String get profileGalleryTitle => 'Foto';

  @override
  String get profileGalleryAdd => 'Foto qo‘shish';

  @override
  String get profileMakePrimary => 'Asosiy qilish';

  @override
  String get profilePhotoDelete => 'Fotoni o‘chirish';

  @override
  String get profilePhotosLimit => '3 tadan ortiq foto yuklab bo‘lmaydi';

  @override
  String get profilePhotosEmpty => 'Hozircha foto yo‘q';

  @override
  String get profilePhotoUploadFailed => 'Foto yuklanmadi';

  @override
  String get profilePhotoDeleteFailed => 'Foto o‘chirilmadi';

  @override
  String get profilePhotoTooLarge => 'Foto juda katta';

  @override
  String get profileSetPrimaryFailed => 'Asosiy qilib bo‘lmadi';

  @override
  String timeSecondsShort(int seconds) {
    return '$seconds s';
  }

  @override
  String get timeOneMin => '1 daq';

  @override
  String get timeTenMin => '10 daq';

  @override
  String rulesIntro(String grid) {
    return 'X-O o‘yini $grid maydonda. Navbat bilan yuriladi, X boshlaydi.';
  }

  @override
  String rulesWin(int n) {
    return 'G‘alaba: gorizontal, vertikal yoki diagonal bo‘ylab $n qator qilish kerak.';
  }

  @override
  String get rulesNoTimeLimit => 'Yurish uchun vaqt cheklovi yo‘q.';

  @override
  String rulesTurnTime(String time) {
    return 'Yurish vaqti: $time. Vaqt tugasa — mag\'lubiyat.';
  }

  @override
  String rulesStake(String stake) {
    return 'Stavka: $stake. O‘yin shu qancha tangaga.';
  }

  @override
  String get rulesSwap => 'Tomonlar almashuvi: X ning birinchi yurishidan so‘ng O X bilan joy almashishi mumkin.';

  @override
  String get rulesNoCenter => 'Markaz taqiqi: X birinchi yurishda markazga yura olmaydi.';

  @override
  String get collectionSetLegends => 'Afsonalar';

  @override
  String get collectionSetSpace => 'Kosmos';

  @override
  String get collectionSetGems => 'Qimmatbaho toshlar';

  @override
  String get collectionSetParty => 'Bayram';

  @override
  String get collectionSetNature => 'Tabiat';

  @override
  String get collectionSetAdventures => 'Sarguzashtlar';

  @override
  String collectionCardMeta(String amount) {
    return 'Kolleksiya · vitrina · sovg‘a · sotish · +$amount';
  }

  @override
  String get coinsDayOne => 'kun';

  @override
  String get coinsDayFew => 'kun';

  @override
  String get coinsDayMany => 'kun';

  @override
  String get giftFriendTitle => 'Do‘stga sovg‘a qilish';

  @override
  String photoCount(int count) {
    return 'Foto ($count)';
  }

  @override
  String photoCountWithText(int count, String text) {
    return 'Foto ($count): $text';
  }

  @override
  String photoWithText(String text) {
    return 'Foto: $text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count emoji · $price';
  }

  @override
  String get chatsExpandPanel => 'Panelni yoyish';

  @override
  String get chatsCollapsePanel => 'Panelni yig‘ish';

  @override
  String get chatReplySourceMissing => 'Asl xabar topilmadi';

  @override
  String shopStakeTitleSilver(int n) {
    return '$n kumush stavka';
  }

  @override
  String shopStakeTitleGold(int n) {
    return '$n oltin stavka';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Oʻyinlarda $n kumush tikish huquqi';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Oʻyinlarda $n oltin tikish huquqi';
  }

  @override
  String get chatReplySelf => 'oʻzingizga';

  @override
  String get chatReplyPeer => 'suhbatdoshga';

  @override
  String get verifyEmailTitle => 'Verify email';

  @override
  String verifyEmailSubtitle(String email) {
    return 'We sent a code to $email';
  }

  @override
  String get verifyEmailCodeLabel => 'Code from email';

  @override
  String get verifyEmailCodeRequired => 'Enter the code';

  @override
  String get verifyEmailSubmit => 'Verify';

  @override
  String get verifyEmailResend => 'Resend code';

  @override
  String get verifyEmailResent => 'A new code was sent';

  @override
  String get oauthOrContinue => 'or continue with';

  @override
  String get oauthGoogle => 'Google';

  @override
  String get oauthApple => 'Apple';

  @override
  String get oauthYandex => 'Yandex';

  @override
  String get oauthVK => 'VK';

  @override
  String get oauthError => 'Could not sign in with this service';

  @override
  String get oauthCallbackTitle => 'Signing in…';

  @override
  String verifyEmailResendIn(String time) {
    return 'Resend code in $time';
  }

  @override
  String verifyEmailDevCodeHint(String code) {
    return 'Email is not configured on the server yet. Use this code: $code';
  }

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordSubtitle => 'Enter your email — we’ll send a code for a new password';

  @override
  String get forgotPasswordSubmit => 'Send code';

  @override
  String get forgotPasswordSent => 'If the account exists, a code was sent to your email';

  @override
  String get resetPasswordTitle => 'New password';

  @override
  String resetPasswordSubtitle(String email) {
    return 'We sent a code to $email';
  }

  @override
  String get resetPasswordCodeLabel => 'Code from email';

  @override
  String get resetPasswordCodeRequired => 'Enter the code';

  @override
  String get resetPasswordNewLabel => 'New password';

  @override
  String get resetPasswordNewRequired => 'Enter a new password';

  @override
  String get resetPasswordNewShort => 'At least 6 characters';

  @override
  String get resetPasswordConfirmLabel => 'Confirm password';

  @override
  String get resetPasswordConfirmMismatch => 'Passwords do not match';

  @override
  String get resetPasswordSubmit => 'Save password';

  @override
  String get resetPasswordResend => 'Resend code';

  @override
  String get resetPasswordResent => 'A new code was sent';

  @override
  String resetPasswordResendIn(String time) {
    return 'Resend code in $time';
  }

  @override
  String get resetPasswordBackToLogin => 'Back to sign in';

  @override
  String get statsTitle => 'Statistika';

  @override
  String get statsLoadFailed => 'Statistikani yuklab bo‘lmadi';

  @override
  String get statsAllGames => 'Barcha o‘yinlar';

  @override
  String get statsEmptyTitle => 'Hali o‘ynalgan partiyalar yo‘q';

  @override
  String get statsEmptyHint => 'Statistika paydo bo‘lishi uchun birinchi o‘yinni o‘ynang.';

  @override
  String get statsWins => 'G‘alabalar';

  @override
  String get statsDraws => 'Durranglar';

  @override
  String get statsLosses => 'Mag‘lubiyatlar';

  @override
  String get statsWinRate => 'G‘alaba foizi';

  @override
  String get statsTopWon => 'Eng ko‘p g‘alaba qilgan raqiblar';

  @override
  String get statsTopDrawn => 'Eng ko‘p durranglar';

  @override
  String get statsTopLost => 'Eng ko‘p mag‘lub bo‘lgan raqiblar';

  @override
  String get statsTimePlayed => 'O‘yin vaqti';

  @override
  String get statsYourScore => 'Hisobingiz';

  @override
  String get profileShowStats => 'Statistikani ko‘rsatish';

  @override
  String get statsDurationZeroMinutes => '0 daq';

  @override
  String get gameYouWonOpponentForfeit => 'Raqib taslim bo‘ldi. Siz yutdingiz!';

  @override
  String get lobbyLeaveTitle => 'Lobbidan chiqilsinmi?';

  @override
  String get lobbyLeaveConfirm => 'Chiqgandan keyin lobbi o‘chiriladi. Taklif qilingan do‘stlar rad javobini oladi.';

  @override
  String get lobbyLeave => 'Chiqish';

  @override
  String statsDurationHours(int hours) {
    return '$hours soat';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours soat $minutes daq';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes daq';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'Siz taslim bo‘ldingiz. $name yutdi';
  }

  @override
  String get supportTitle => 'Yordam';

  @override
  String get supportUnavailable => 'Yordam mavjud emas';

  @override
  String get supportOpenFailed => 'Yordam chatini ochib bo‘lmadi';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Sizga $amount tanga hisoblandi';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return '$amount tanga yechildi';
  }

  @override
  String get coinsCreditCardTitle => 'Sizga tangalar hisoblandi';

  @override
  String get coinsClaim => 'Olish';

  @override
  String get durakActionPass => 'Pas';

  @override
  String get durakRoleTook => 'Oldi';

  @override
  String get durakRoleBeats => 'Uradi';

  @override
  String get durakRoleThrowIn => 'Tashlash';

  @override
  String get durakRoleTurn => 'Yurish';

  @override
  String get durakRoleDefends => 'Himoyalanadi';

  @override
  String get durakStatusTaking => 'Olaman';

  @override
  String get durakHintDefenderTurn => 'Himoyachining yurishi';

  @override
  String get gameYouEliminated => 'Siz chiqdingiz';

  @override
  String gameYouPlaced(int place) {
    return 'Siz $place-o‘rinni egalladingiz';
  }

  @override
  String get gameOverNeutral => 'O‘yin tugadi';

  @override
  String gameTurnOf(String name) {
    return '$name yurishi';
  }

  @override
  String get chatGroupTooltip => 'Guruh chati';

  @override
  String get lobbyChatNotReady => 'Lobi chati hali yaratilmagan';

  @override
  String get chatsGroupChat => 'Guruh chati';

  @override
  String chatsMembersCount(int count) {
    return 'Ishtirokchilar: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count kishi';
  }

  @override
  String get chatsYouSuffix => '(siz)';

  @override
  String get chatTitleDurak3 => 'Durak · 3 o‘yinchi';

  @override
  String get chatTitleDurak4 => 'Durak · 4 o‘yinchi';

  @override
  String get rulesTttUltimate => 'Ultimate: to‘qqizta 3×3 mini-doska. Yurish raqibni shu mini-doskaga yuboradi. Meta-doskada chiziq yig‘gan g‘olib.';

  @override
  String get rulesTttMulti3 => '3 o‘yinchi: 3×3 doska, uch o‘yinchi (X, O, △). O‘z belgilaringiz bilan chiziq yig‘ing.';

  @override
  String get rulesTttMulti4 => '4 o‘yinchi: 4×4 doska, to‘rt o‘yinchi (X, O, △, □). O‘z belgilaringiz bilan chiziq yig‘ing.';

  @override
  String get adminUsersTab => 'Foydalanuvchilar';

  @override
  String get adminSupportTab => 'Yordam';

  @override
  String get adminSearchHint => 'Email yoki taxallus bo‘yicha qidirish';

  @override
  String get adminRoleAdmins => 'Adminlar';

  @override
  String get adminRoleUsers => 'Foydalanuvchilar';

  @override
  String get adminRoleAll => 'Barcha rollar';

  @override
  String get adminStatusFrozen => 'Muzlatilgan';

  @override
  String get adminStatusActive => 'Faol';

  @override
  String get adminStatusAny => 'Har qanday holat';

  @override
  String get adminOrderDesc => 'Kamayish bo‘yicha';

  @override
  String get adminOrderAsc => 'O‘sish bo‘yicha';

  @override
  String adminLoadFailed(String error) {
    return 'Yuklash xatosi: $error';
  }

  @override
  String get adminUsersEmpty => 'Foydalanuvchilar topilmadi';

  @override
  String get adminSortLastSeen => 'Oxirgi tashrif bo‘yicha';

  @override
  String get adminSortEmail => 'Email bo‘yicha';

  @override
  String get adminSortCreated => 'Ro‘yxat sanasi bo‘yicha';

  @override
  String adminBronzeBalance(int amount) {
    return '$amount br.';
  }

  @override
  String get adminRevokeAdmin => 'Adminni olish';

  @override
  String get adminGrantAdmin => 'Admin qilish';

  @override
  String get adminAdminRevoked => 'Admin huquqi olindi';

  @override
  String get adminAdminGranted => 'Admin huquqi berildi';

  @override
  String get adminGrantCoins => 'Tangalar qo‘shish';

  @override
  String get adminWriteSupport => 'Yordam nomidan yozish';

  @override
  String get adminUnfreeze => 'Muzdan tushirish';

  @override
  String get adminFreeze => 'Muzlatish';

  @override
  String get adminUnfrozen => 'Muzdan tushirildi';

  @override
  String get adminFrozenDone => 'Muzlatildi';

  @override
  String get adminResetPassword => 'Parolni tiklash';

  @override
  String get adminCoinsAmountHint => 'Miqdor (manfiy = yechish)';

  @override
  String get adminReasonOptional => 'Sabab (ixtiyoriy)';

  @override
  String get adminGrantSent => 'Kartochka yordam chatiga yuborildi';

  @override
  String adminCoinsDebited(int amount) {
    return '$amount bronza yechildi';
  }

  @override
  String get adminGrantVerb => 'Qo‘shish';

  @override
  String get adminNewPasswordHint => 'Yangi parol (kamida 6)';

  @override
  String get adminPasswordReset => 'Parol tiklandi';

  @override
  String get adminResetVerb => 'Tiklash';

  @override
  String adminShortError(String error) {
    return 'Xato: $error';
  }

  @override
  String get adminSupportEmpty => 'Yordam murojaatlari yo‘q';

  @override
  String get adminUserFallback => 'Foydalanuvchi';

  @override
  String get apiErrTooManyRequests => 'So‘rovlar juda ko‘p. Keyinroq urinib ko‘ring.';

  @override
  String get apiErrMoveConflict => 'Yurish to‘qnashdi. Qaytaring.';

  @override
  String get shopElixirs => 'Elixirs';

  @override
  String get shopElixirsSubtitle => 'Rejuvenate, age, or speed up collections';

  @override
  String get shopElixirsHelp => 'Three shelves: rejuvenation, aging, and acceleration. Each has six elixirs, one per collection set. An elixir works only on its own set.\n\nRejuvenation makes a collection one step newer, and never newer than new. Aging makes it one step older, and never older than shabby. Acceleration is only for a shabby item: three months left until vintage, once. An elixir never grants vintage by itself.\n\nA bought elixir stays in Items. Use it from the collection card or from the elixir card. Each use spends one.';

  @override
  String get elixirGroupRejuvenate => 'Yoshartirish';

  @override
  String get elixirGroupAge => 'Qaritish';

  @override
  String get elixirGroupAccelerate => 'Tezlashtirish';

  @override
  String get elixirEffectRejuvenate => 'yoshartirish';

  @override
  String get elixirEffectAge => 'qaritish';

  @override
  String get elixirEffectAccelerate => 'tezlashtirish';

  @override
  String get elixirAdjCelebration => 'Bayram';

  @override
  String get elixirAdjNature => 'Tabiat';

  @override
  String get elixirAdjLegends => 'Afsonaviy';

  @override
  String get elixirAdjCosmic => 'Kosmik';

  @override
  String get elixirAdjAdventure => 'Sarguzasht';

  @override
  String get elixirAdjJewels => 'Qimmatbaho';

  @override
  String elixirName(String adjective, String effect) {
    return '$adjective $effect eliksiri';
  }

  @override
  String get elixirHelpRejuvenate => 'Makes the collection one step newer. Not newer than new.';

  @override
  String get elixirHelpAge => 'Makes the collection one step older. Not older than shabby.';

  @override
  String get elixirHelpAccelerate => 'Shabby only. Three months left until vintage, once.';

  @override
  String get elixirUseRejuvenate => 'Yoshartirish';

  @override
  String get elixirUseAge => 'Qaritish';

  @override
  String get elixirUseAccelerate => 'Tezlashtirish';

  @override
  String get elixirUse => 'Ishlatish';

  @override
  String collectionLeftDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kun',
      one: '$count kun',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count soat',
      one: '$count soat',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count daqiqa',
      one: '$count daqiqa',
    );
    return '$_temp0';
  }

  @override
  String elixirSetOnly(String set) {
    return 'Only the $set set.';
  }

  @override
  String get elixirPickCollection => 'Choose a collection';

  @override
  String get elixirNoTarget => 'No collection in this set can take this elixir';

  @override
  String get elixirApplied => 'Elixir applied';

  @override
  String get elixirConfirmTitle => 'Use this elixir?';

  @override
  String elixirConfirmBody(String elixir, String collection) {
    return '$elixir\n$collection';
  }

  @override
  String get inventoryNoElixirs => 'No elixirs — buy them in the shop';

  @override
  String get elixirNotApplicable => 'This elixir cannot change that collection right now';

  @override
  String get elixirWrongSet => 'This elixir is for another set';

  @override
  String get elixirNotOwned => 'You do not have this elixir';

  @override
  String collectionUntil(String state, String left) {
    return 'Until $state: $left';
  }

  @override
  String get collectionLeftSoon => 'less than a minute';

  @override
  String get collectionCondGenNew => 'new';

  @override
  String get collectionCondGenWorn => 'worn';

  @override
  String get collectionCondGenTired => 'tired';

  @override
  String get collectionCondGenShabby => 'shabby';

  @override
  String get collectionCondGenVintage => 'vintage';
}
