import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Belarusian (`be`).
class AppLocalizationsBe extends AppLocalizations {
  AppLocalizationsBe([String locale = 'be']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Галоўная';

  @override
  String get navProfile => 'Профіль';

  @override
  String get navFriends => 'Сябры';

  @override
  String get navChats => 'Чаты';

  @override
  String get navGames => 'Гульні';

  @override
  String get navSettings => 'Налады';

  @override
  String get settingsTitle => 'Налады';

  @override
  String get settingsLanguage => 'Мова';

  @override
  String get settingsLanguageSystem => 'Як у сістэме';

  @override
  String get settingsSoundTitle => 'Гук';

  @override
  String get settingsSoundSubtitle => 'Гульні і апавяшчэнні';

  @override
  String get settingsSoundGames => 'Гульні';

  @override
  String get settingsSoundNotifications => 'Апавяшчэнні';

  @override
  String get settingsSoundTurn => 'Ход';

  @override
  String get settingsHapticsTitle => 'Вібрацыя';

  @override
  String get settingsHapticsSubtitle => 'Толькі апавяшчэнні: паведамленні, заяўкі, ваш ход і таймер';

  @override
  String get settingsGamepadTitle => 'Кантролер';

  @override
  String get settingsGamepadSubtitle => 'Геймпад для меню і партый';

  @override
  String settingsGamepadConnected(String name) {
    return 'Падключаны: $name';
  }

  @override
  String get settingsGamepadDisconnected => 'Геймпад не знойдзены. Падключыце кантролер і націсніце любую кнопку.';

  @override
  String get settingsGamepadGenericName => 'Кантролер';

  @override
  String get settingsGamepadHelpNavigate => 'Навігацыя';

  @override
  String get settingsGamepadHelpConfirm => 'Выбраць';

  @override
  String get settingsGamepadHelpBack => 'Назад';

  @override
  String get settingsGamepadHelpTabs => 'Укладкі';

  @override
  String get settingsGamepadHelpPlay => 'Курсор на полі і ў руцэ: шашкі, крыжыкі-нулікі, марскі бой, дурань, уно, покер і нарды';

  @override
  String get settingsGamepadHelpCards => 'Карты';

  @override
  String get settingsGamepadHelpKeyboard => 'Клавіятура';

  @override
  String get settingsGamepadHelpBalance => 'Баланс';

  @override
  String get settingsGamepadHelpLogout => 'Выхад';

  @override
  String get settingsGamepadHelpPage => 'Старонка';

  @override
  String get settingsGamepadLayoutXbox => 'Раскладка Xbox';

  @override
  String get settingsGamepadLayoutPlayStation => 'Раскладка PlayStation';

  @override
  String get settingsGamepadLayoutNintendo => 'Раскладка Nintendo';

  @override
  String get gamepadKeyboardTitle => 'Клавіятура';

  @override
  String get gamepadKeyboardSpace => 'Прабел';

  @override
  String get gamepadLegendConfirm => 'Выбраць';

  @override
  String get gamepadLegendBack => 'Назад';

  @override
  String get gamepadLegendTabs => 'Укладкі';

  @override
  String get gamepadLegendCycle => 'Змяніць';

  @override
  String gamepadConnectedSnack(String name) {
    return 'Кантролер падключаны: $name';
  }

  @override
  String get settingsOfflineModeTitle => 'Рэжым сеткі';

  @override
  String get settingsOfflineModeSubtitle => 'Афлайн: гульня з ботам адразу, без ставак і ўзнагарод, без чатаў і сяброў. Пакупкі захоўваюцца і прымяняюцца ў рэжыме онлайн. Анлайн — калі ёсць інтэрнэт або па налададзе карыстальніка.';

  @override
  String get settingsModeOnline => 'Анлайн';

  @override
  String get settingsModeOffline => 'Афлайн';

  @override
  String get gamesAlternateStartsHint => 'Па чарзе хто пачынае партыю';

  @override
  String get rulesAlternateStarts => 'Хто ходзіць першым чаргуецца ад партыі да партыі.';

  @override
  String get offlineBadgeTooltip => 'Афлайн рэжым';

  @override
  String get offlineModePopupTitle => 'Афлайн рэжым';

  @override
  String get offlineModePopupBody => 'Уключаны афлайн рэжым. Гуляйце з ботам без ставак і ўзнагарод. Чаты, сябры і лобі схаваны. Пакупкі прымяняцца ў рэжыме анлайн.';

  @override
  String get offlineModePopupSettings => 'Налады';

  @override
  String get offlineModeOfferBody => 'Няма інтэрнэту або сувязь вельмі слабая. Можна ўключыць афлайн рэжым і гуляць з ботам.';

  @override
  String get offlineModeOfferAction => 'Уключыць афлайн';

  @override
  String get gamesPlay => 'Гуляць';

  @override
  String get offlineGameTitle => 'Гульня з ботам';

  @override
  String get offlineGameHint => 'Без ставак і ўзнагарод · толькі афлайн';

  @override
  String get offlineBotWon => 'Бот перамог';

  @override
  String get offlineBotThinking => 'Ход бота…';

  @override
  String get offlinePlayAgain => 'Яшчэ раз';

  @override
  String offlineBotName(int n) {
    return 'Бот $n';
  }

  @override
  String get durakActionTake => 'Узяць';

  @override
  String get durakActionAll => 'Усе';

  @override
  String get durakActionDone => 'Гатова';

  @override
  String get durakActionBito => 'Біта';

  @override
  String get durakHintDefend => 'Адбівайцеся';

  @override
  String get durakHintDefendOrTransfer => 'Адбівайцеся або перавядзіце';

  @override
  String get durakHintOpponentDefends => 'Супернік адбіваецца';

  @override
  String get durakHintThrowInFirst => 'Падкідайце карты (макс. 5 у першым адбоі)';

  @override
  String get durakHintThrowIn => 'Падкідайце карты або чакайце адбою';

  @override
  String get durakHintOpponentThrows => 'Супернік падкідае';

  @override
  String get durakHintTakeFollow => 'Падкідайце ўдогонку або націсніце «Гатова»';

  @override
  String get durakHintOpponentTakeFollow => 'Супернік можа падкінуць удогонку';

  @override
  String get durakHintBito => 'Падкідайце карту або скажыце «Біта»';

  @override
  String get durakHintOpponentBito => 'Супернік падкідае або кажа «Біта»';

  @override
  String get durakHintYourAttack => 'Ваш ход — атакуйце';

  @override
  String get durakHintOpponentAttack => 'Атакуе супернік';

  @override
  String get durakHintYouLost => 'Вы прайгралі — вы дурак';

  @override
  String get durakHintDrawAllOut => 'Нічыя — усе выйшлі';

  @override
  String get durakHintYouFinished => 'Вы выйшлі — чакаем канца партыі';

  @override
  String get durakFirstLeadYou => 'Вы ходзіце';

  @override
  String get durakFirstLeadOpponent => 'Супернік ходзіць';

  @override
  String get durakFirstLeadBot => 'Бот ходзіць';

  @override
  String durakFirstLeadOf(String name) {
    return 'Ходзіць $name';
  }

  @override
  String get durakFirstLeadReason => 'Малодшы казыр';

  @override
  String get shopPurchaseQueued => 'Пакупка захавана — прымяніцца ў рэжыме анлайн';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — пакупку прыменена';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — пакупку не прыменена: $reason';
  }

  @override
  String get settingsFriendsOnlyTitle => 'Паведамленні толькі ад сяброў';

  @override
  String get settingsFriendsOnlySubtitle => 'Хто не ў сябрах, зможа дасылаць толькі эмодзі. Калі перашкаджае спам — часова заблакіруйце карыстальніка.';

  @override
  String get settingsNotifications => 'Апавяшчэнні';

  @override
  String get settingsPushChat => 'Чат';

  @override
  String get settingsPushFriends => 'Сябры';

  @override
  String get settingsPushGames => 'Гульні';

  @override
  String get settingsPushRewards => 'Узнагароды';

  @override
  String settingsAppVersion(String version) {
    return 'Версія $version';
  }

  @override
  String get appUpdateTitle => 'Даступна абнаўленне';

  @override
  String get appUpdateBody => 'Выйшла новая версія праграмы. Абнавіцеся, каб працягваць.';

  @override
  String get appUpdateWhatsNew => 'Што новага';

  @override
  String get appUpdateOk => 'Абнавіць';

  @override
  String get appUpdateLaterBanner => 'Пасля партыі абнавіма праграму';

  @override
  String get loginTitle => 'Уваход';

  @override
  String get loginSubtitle => 'Увядзіце email або лагін і пароль';

  @override
  String get loginEmailLabel => 'Email або лагін';

  @override
  String get loginPasswordLabel => 'Пароль';

  @override
  String get loginSubmit => 'Увайсці';

  @override
  String get loginNoAccount => 'Няма акаўнта? Зарэгістравацца';

  @override
  String get loginEmailRequired => 'Увядзіце email або лагін';

  @override
  String get loginPasswordRequired => 'Увядзіце пароль';

  @override
  String get loginTooltip => 'Увайсці';

  @override
  String get logoutTooltip => 'Выйсці';

  @override
  String get registerTitle => 'Рэгістрацыя';

  @override
  String get registerSubtitle => 'Стварыце акаўнт, каб гуляць';

  @override
  String get registerNameLabel => 'Імя (лагін)';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'Пароль';

  @override
  String get registerSubmit => 'Зарэгістравацца';

  @override
  String get registerHaveAccount => 'Ужо ёсць акаўнт? Увайсці';

  @override
  String get registerNameRequired => 'Увядзіце імя';

  @override
  String get registerNameNoSpaces => 'Імя не можа змяшчаць прабелаў';

  @override
  String get registerNameMax => 'Максімум 20 сімвалаў';

  @override
  String get registerNameHint => 'Да 20 сімвалаў';

  @override
  String get registerEmailRequired => 'Увядзіце email';

  @override
  String get registerEmailInvalid => 'Няправільны email';

  @override
  String get registerPasswordHint => 'Мінімум 6 сімвалаў';

  @override
  String get registerPasswordMin => 'Пароль павінен мець не менш за 6 сімвалаў';

  @override
  String get commonCancel => 'Скасаваць';

  @override
  String get commonSave => 'Захаваць';

  @override
  String get commonDelete => 'Выдаліць';

  @override
  String get commonEdit => 'Змяніць';

  @override
  String get commonReply => 'Адказаць';

  @override
  String get commonSend => 'Даслаць';

  @override
  String get commonClose => 'Закрыць';

  @override
  String get commonRetry => 'Паўтарыць';

  @override
  String get commonLoading => 'Загрузка…';

  @override
  String get commonError => 'Памылка';

  @override
  String get commonOnline => 'у сетцы';

  @override
  String get commonOffline => 'не ў сетцы';

  @override
  String get commonOnlineCap => 'Онлайн';

  @override
  String get commonUser => 'Карыстальнік';

  @override
  String get commonPlayer => 'Гулец';

  @override
  String get commonAboutMe => 'Пра сябе';

  @override
  String get commonBack => 'Назад';

  @override
  String get commonAccept => 'Прыняць';

  @override
  String get commonDecline => 'Адхіліць';

  @override
  String get commonCreating => 'Стварэнне…';

  @override
  String get commonSearching => 'Пошук…';

  @override
  String get commonInsufficientCoins => 'Недастаткова манет';

  @override
  String get commonNotFound => 'Не знойдзена';

  @override
  String get commonServerErrorShort => 'Памылка сервера';

  @override
  String get commonForbidden => 'Доступ забаронены';

  @override
  String get commonUserBlocked => 'Карыстальнік заблакіраваны';

  @override
  String get commonUserNotFound => 'Карыстальнік не знойдзены';

  @override
  String get commonGenericError => 'Нешта пайшло не так. Паспрабуйце яшчэ раз.';

  @override
  String get apiErrWrongGameType => 'Няправільны тып гульні';

  @override
  String get apiErrWrongGameTypeOrState => 'Няправільны тып або стан гульні';

  @override
  String get apiErrLobbyFull => 'Лобі запоўненае';

  @override
  String get apiErrBadState => 'Памылка стану гульні';

  @override
  String get apiErrIllegalMove => 'Такі ход нельга зрабіць';

  @override
  String get apiErrUnknownMoveType => 'Невядомы тып ходу';

  @override
  String get apiErrNoOpponents => 'Няма супернікаў';

  @override
  String get apiErrNoOpponentsRematch => 'Няма супернікаў для рэваншу';

  @override
  String get apiErrAlreadyInLobby => 'Вы ўжо ў гэтым лобі';

  @override
  String get apiErrGameNotActive => 'Гульня не актыўная';

  @override
  String get apiErrNotInBattle => 'Зараз не фаза бою';

  @override
  String get apiErrNotInSetup => 'Зараз не фаза расстаноўкі';

  @override
  String get apiErrAlreadyReady => 'Вы ўжо гатовыя';

  @override
  String get apiErrAlreadyForfeited => 'Вы ўжо здаліся';

  @override
  String get apiErrYouHaveForfeited => 'Вы здаліся';

  @override
  String get apiErrNoDrawOffer => 'Няма прапановы нічыі';

  @override
  String get apiErrDrawOnlyPvp => 'Нічыя толькі супраць гульца';

  @override
  String get apiErrDrawOnly1v1 => 'Нічыя толькі ў гульні 1 на 1';

  @override
  String get apiErrDrawVsBot => 'Нічыя недаступная супраць бота';

  @override
  String get apiErrDrawMultiplayer => 'Нічыя недаступная ў гульні на некалькіх';

  @override
  String get apiErrDeck24TwoPlayers => 'Калода 24 толькі для двух гульцоў';

  @override
  String get apiErrDeck52ThreeOrFour => 'Калода 52 толькі для 3 або 4 гульцоў';

  @override
  String get apiErrAccountFrozen => 'Акаўнт замарожаны';

  @override
  String get apiErrTurnTimeInvalid => 'Час ходу павінен быць 0, 20, 60 або 600 секунд';

  @override
  String get timeJustNow => 'толькі што';

  @override
  String get timeYesterday => 'учора';

  @override
  String timeMinutesAgo(int count) {
    return '$count хв таму';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count гадз таму';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count дз. таму';
  }

  @override
  String get timeWeekAgo => 'тыдзень таму';

  @override
  String timeWeeksAgo(int count) {
    return '$count тыд. таму';
  }

  @override
  String get timeMonthAgo => 'месяц таму';

  @override
  String timeMonthsAgo(int count) {
    return '$count мес. таму';
  }

  @override
  String get timeYearAgo => 'год таму';

  @override
  String timeYearsAgo(int count) {
    return '$count г. таму';
  }

  @override
  String get weekdaySun => 'нд';

  @override
  String get weekdayMon => 'пн';

  @override
  String get weekdayTue => 'аў';

  @override
  String get weekdayWed => 'ср';

  @override
  String get weekdayThu => 'чц';

  @override
  String get weekdayFri => 'пт';

  @override
  String get weekdaySat => 'сб';

  @override
  String get monthJan => 'сту';

  @override
  String get monthFeb => 'лют';

  @override
  String get monthMar => 'сак';

  @override
  String get monthApr => 'кра';

  @override
  String get monthMay => 'май';

  @override
  String get monthJun => 'чэр';

  @override
  String get monthJul => 'ліп';

  @override
  String get monthAug => 'жні';

  @override
  String get monthSep => 'вер';

  @override
  String get monthOct => 'кас';

  @override
  String get monthNov => 'ліс';

  @override
  String get monthDec => 'сне';

  @override
  String get homeAchievements => 'Дасягненні';

  @override
  String get homeAchievementsSubtitle => 'Вашы гульнявыя вынікі';

  @override
  String get homeAchievementsRewards => 'Ёсць узнагароды для атрымання';

  @override
  String get homeCoins => 'Манеты';

  @override
  String get homeCoinsSubtitle => 'Баланс і ўзнагароды';

  @override
  String get homeCoinsDailyReward => 'Даступна ўзнагарода за ўваход';

  @override
  String get homeItems => 'Прадметы';

  @override
  String get homeItemsInventory => 'Ваш інвентар';

  @override
  String get homeItemsGifted => 'Вам падарылі калекцыю';

  @override
  String get homeItemsIncome => 'Можна забраць даход з калекцый';

  @override
  String get homeShop => 'Крама';

  @override
  String get homeShopSubtitle => 'Эмодзі, стаўкі, калекцыі';

  @override
  String get gamesTitle => 'Гульні';

  @override
  String get gamesFindMatch => 'Знайсці гульню';

  @override
  String get gamesMyTurn => 'Ваш ход';

  @override
  String get gamesWaiting => 'Чаканне';

  @override
  String get gamesLobbyTab => 'Лобі';

  @override
  String get gamesTicTacToe => 'Крыжыкі-нулікі';

  @override
  String get gamesDurak => 'Дурак';

  @override
  String get gamesBattleship => 'Марскі бой';

  @override
  String get gamesBattleshipRandomPlace => 'Расставіць выпадкова';

  @override
  String get gamesBattleshipConfirmPlace => 'Гатова';

  @override
  String get gamesBattleshipRotate => 'Павярнуць';

  @override
  String get gamesBattleshipSetupPhase => 'Расстаноўка';

  @override
  String get gamesBattleshipBattlePhase => 'Бой';

  @override
  String get gamesBattleshipWaitingOpponentSetup => 'Чаканне суперніка…';

  @override
  String get gamesBattleshipYouWon => 'Вы перамаглі!';

  @override
  String get gamesBattleshipYouLost => 'Вы прайгралі';

  @override
  String get gamesBattleshipShipsMustNotTouch => 'Караблі не павінны датыкацца';

  @override
  String get rulesBattleshipTitle => 'Марскі бой — правілы';

  @override
  String get rulesBattleshipPlayers => 'Гульцы: 2.';

  @override
  String rulesBattleshipSetupTime(String time) {
    return 'Час на расстаноўку: $time.';
  }

  @override
  String get rulesBattleshipIntro => 'Поле 10×10. Флот: адзін чатырохпалубны, два трохпалубныя, тры двухпалубныя і чатыры аднапалубныя. Караблі нельга ставіць ушчыльную, у тым ліку па дыяганалі.';

  @override
  String get rulesBattleshipSetup => 'Калі час на расстаноўку выйшаў, застаецца бягучая сапраўдная расстаноўка; калі яна няслушная — выкарыстоўваецца стандартная.';

  @override
  String get rulesBattleshipPlay => 'Пасля расстаноўкі першым ходзіць выпадковы гулец. Страляйце па клетках суперніка: трапленне дае яшчэ адзін ход, промах перадае ход. На сваім ходзе відаць поле суперніка, на ягоным — ваша.';

  @override
  String get rulesBattleshipWin => 'Перамагае той, хто першым патопіць увесь флот суперніка.';

  @override
  String get gamesPoker => 'Покер';

  @override
  String get gamesUno => 'Уно';

  @override
  String get gamesNardy => 'Нарды';

  @override
  String get gamesNardyModeShort => 'Кароткія';

  @override
  String get gamesNardyModeLong => 'Доўгія';

  @override
  String get gamesCheckers => 'Шашкі';

  @override
  String get gamesCheckersModeRussian => 'Рускія';

  @override
  String get gamesCheckersModeEnglish => 'Англійскія';

  @override
  String get gamesCheckersModeGiveaway => 'Паддаўкі';

  @override
  String get gamesCheckersModeCorners => 'Вуглікі';

  @override
  String get gamesChess => 'Шахматы';

  @override
  String get gamesChessModeClassic => 'Класіка';

  @override
  String get gamesChessModeRapid => 'Рапід';

  @override
  String get gamesChessModeBlitz => 'Бліц';

  @override
  String get gamesChessModeBullet => 'Куля';

  @override
  String get chessPieceQueen => 'Ферзь';

  @override
  String get chessPieceRook => 'Ладдзя';

  @override
  String get chessPieceBishop => 'Слон';

  @override
  String get chessPieceKnight => 'Конь';

  @override
  String get chessPromotionTitle => 'Ператварэнне пешкі';

  @override
  String get chessDrawStalemate => 'Нічыя: пат';

  @override
  String get chessDrawInsufficient => 'Нічыя: недастаткова матэрыялу для мата';

  @override
  String get chessDrawRepetition => 'Нічыя: трохразовае паўтарэнне пазіцыі';

  @override
  String get chessDrawFiftyMove => 'Нічыя: правіла 50 хадоў';

  @override
  String get chessCheck => 'Шах';

  @override
  String get rulesCheckersPlayers => 'Гульцы: 2.';

  @override
  String rulesCheckersMode(String mode) {
    return 'Рэжым: $mode.';
  }

  @override
  String rulesCheckersTime(String time) {
    return 'Время на ход: $time. Если время вышло — проигрыш.';
  }

  @override
  String get rulesCheckersIntro => 'Дошка 8×8. Гуляюць двое.';

  @override
  String get rulesCheckersPlay => 'Бой абавязковы. Дамка і простая абавязаны працягваць бой, пакуль з клеткі прызямлення можна біць далей — спыніцца пасярэдзіне нельга. Калі кірункаў некалькі, можна выбраць любы, не абавязкова самы доўгі. Простая, што дайшла да апошняй лініі, становіцца дамкаю.';

  @override
  String get rulesCheckersWin => 'В русских шашках побеждает тот, кто съел все шашки соперника или лишил его хода. В поддавках наоборот: кто не может ходить — выигрывает.';

  @override
  String get rulesCheckersOfflineBot => 'Офлайн: партия против бота.';

  @override
  String get rulesCheckersPlayRussian => 'Рускія шашкі: у кожнага 12 шашак на цёмных клетках. Простыя ходзяць па дыяганалі наперад, а б’юць наперад і назад. Дамка ляціць на любую колькасць клетак. Бой абавязковы: нельга спыніцца, калі ўзяцце можна працягнуць, але калі кірункаў некалькі — выбіраеце любы, не абавязкова самы доўгі. Перамагае той, хто з’еў усе шашкі суперніка або пазбавіў яго хадоў.';

  @override
  String get rulesCheckersPlayEnglish => 'Англійскія шашкі: у кожнага 12 шашак. Простыя ходзяць і б’юць толькі наперад па дыяганалі. Дамка ходзіць на адну клетку ў любы бок па дыяганалі. Бой абавязковы. Перамагае той, хто з’еў усе шашкі суперніка або пазбавіў яго хадоў.';

  @override
  String get rulesCheckersPlayGiveaway => 'Паддаўкі: тыя ж хады, што ў рускіх шашках, але мэта адваротная — аддаць усе свае шашкі або застацца без ходу. Бой усё роўна абавязковы.';

  @override
  String get rulesCheckersPlayCorners => 'Вуглікі: шашкі стаяць у супрацьлеглых вуглах. Ходзяць на суседнюю свабодную клетку па гарызанталі ці вертыкалі або пераскокваюць праз любую шашку, не здымаючы яе. Мэта — перавесці ўсе свае шашкі ў вугал суперніка.';

  @override
  String get rulesCheckersPlayCornersNoReturn => 'Фішка, якая ўжо пакінула свой стартавы вугал, не можа вярнуцца ў яго.';

  @override
  String get rulesCheckersPlayCornersLeaveHome => 'Фішкі, якія яшчэ не выйшлі з дома, павінны пакінуць яго за першыя 25 хадоў гульца.';

  @override
  String get rulesCheckersDrawRussian => 'Нічыя, калі пазіцыя паўтарылася тройчы або 15 хадоў запар хадзілі толькі дамкі без ўзяцця — у тым ліку па дзве дамкі.';

  @override
  String get rulesCheckersDrawEnglish => 'Нічыя, калі пазіцыя паўтарылася тройчы, калі 40 хадоў не было ўзяцця і ходу простай, або засталося па адной дамцы.';

  @override
  String get rulesCheckersDrawGiveaway => 'Нічыя, калі пазіцыя паўтарылася тройчы або 15 хадоў запар хадзілі толькі дамкі без ўзяцця.';

  @override
  String get rulesCheckersDrawCorners => 'Нічыя, калі пазіцыя паўтарылася тройчы або 25 хадоў кожнага не дадалі шашак у мэтавы кут.';

  @override
  String get rulesChessPlayers => 'Гульцы: 2.';

  @override
  String rulesChessMode(String mode) {
    return 'Рэжым: $mode.';
  }

  @override
  String get rulesChessPlayClassic => 'Дошка 8×8. У кожнага кароль, ферзь, дзве вежы, два сланы, два коні і восем пешак. Белыя ходзяць першымі. Ёсць узяцце на праходзе, пераўтварэнне і ракіроўка. Перамагае мат або здача суперніка.';

  @override
  String get rulesChessDrawClassic => 'Нічыя пры паце, патройным паўторы, правіле 50 хадоў, недахопе фігур або па згодзе.';

  @override
  String get rulesChessClockClassic => 'Кантроль партыі: 60+0 — 60 хвілін на ўсю партыю, без дадавання.';

  @override
  String get rulesChessClockRapid => 'Кантроль партыі: 10+0 — 10 хвілін на ўсю партыю, без дадавання.';

  @override
  String get rulesChessClockBlitz => 'Кантроль партыі: 5+0 — 5 хвілін на ўсю партыю, без дадавання.';

  @override
  String get rulesChessClockBullet => 'Кантроль партыі: 3+2 — 3 хвіліны на партыю плюс 2 секунды за кожны ход.';

  @override
  String get checkersDrawRepetition => 'Нічыя — пазіцыя паўтарылася тройчы';

  @override
  String get checkersDrawNoProgress => 'Нічыя — хады не вядуць да перамогі';

  @override
  String get checkersDrawInsufficient => 'Нічыя — недастаткова сіл для перамогі';

  @override
  String get rulesNardyTitle => 'Нарды — правілы';

  @override
  String get rulesNardyPlayers => 'Ігракі: 2.';

  @override
  String rulesNardyMode(String mode) {
    return 'Рэжым: $mode.';
  }

  @override
  String get rulesNardyIntro => 'Дошка з 24 пунктаў, у кожнага па 15 шашак. Хады па двух кубіках: можна схадзіць адной шашкай на суму або дзвюма на вочкі кубікаў.';

  @override
  String get rulesNardyPlayShort => 'Кароткія нарды: ігракі ідуць насустрач і могуць біць адзіночныя шашкі суперніка. Збітая становіцца на бар і павінна ўвайсці зноў. Калі ўсе шашкі ў доме — здымаеце іх з дошкі.';

  @override
  String get rulesNardyPlayLong => 'Доўгія нарды: абодва пачынаюць з адной галавы і ідуць у адзін бок. З галавы за ход выходзіць не больш за адну шашку. Біць шашкі нельга. Калі ўсе ў доме — здымаеце іх з дошкі.';

  @override
  String get rulesNardyWin => 'Перамагае той, хто першым здыме ўсе свае шашкі.';

  @override
  String get rulesNardySixPrime => 'Шэсць сваіх пунктаў запар замыкаць нельга, пакуль іх не абышла ніводная шашка суперніка.';

  @override
  String get nardyRoll => 'Кінуць';

  @override
  String get nardySkipTurn => 'Прапусціць ход';

  @override
  String get nardyUndoMove => 'Вярнуць';

  @override
  String get nardyDoneTurn => 'Гатова';

  @override
  String get nardyAutoConfirm => 'Аўтапацвярджэнне';

  @override
  String get nardyAutoConfirmHint => 'Пасля ўсіх хадоў адразу перадаць ход суперніку';

  @override
  String get nardyLayoutToggle => 'Змяніць раскладку';

  @override
  String get nardyNoMoves => 'Хадоў няма';

  @override
  String get nardyYourRoll => 'Ваш кідок';

  @override
  String get nardyPipsShort => 'Засталося:';

  @override
  String get nardyYouWonMars => 'Вы выйгралі — марс!';

  @override
  String get nardyYouLostMars => 'Паражэнне — марс';

  @override
  String get rulesNardyOfflineBot => 'Афлайн: партыя супраць бота.';

  @override
  String rulesUnoPlayers(int players) {
    return 'Гульцы: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'Гульня супраць бота, без ліміту часу на ход.';

  @override
  String get rulesUnoIntro => 'Кожнаму раздаюць па 7 карт. Хадзіце картай таго ж колеру або таго ж наміналу (лічба або такі ж спецэфект).';

  @override
  String get rulesUnoPlay => 'Пропуск — наступны губляе ход. Змена кірунку ўдваіх працуе як пропуск. +2 можна класці толькі на +2, +4 — толькі на +4: штраф складаецца (дзве +2 — наступны бярэ 4). +2 на +4 класці нельга. Хто не адказвае, бярэ ўсю стопку і прапускае ход. Дзве аднолькавыя недзікія карты (напрыклад, дзве жоўтыя 8) скідваюцца разам: дастаткова кінуць адну — другая сыходзіць аўтаматычна.';

  @override
  String get rulesUnoWild => 'Чорная карта задае новы колер. +4 кладуць толькі калі няма карты бягучага колеру. Супернік можа аспрэчыць: калі +4 быў законным — аспрэчвальнік бярэ 6, калі не — аўтар +4 бярэ 4, а аспрэчвальнік ходзіць.';

  @override
  String get rulesUnoDraw => 'Калі няма падыходнай карты — вазьміце адну з калоды. Калі яна падыходзіць, можна адразу сысці ёй або пакінуць і перадаць ход. Пакуль ёсць ход, браць нельга.';

  @override
  String get rulesUnoWin => 'Удваіх матч да 100 ачкоў, пры трох і больш гульцах — да 200. Раунд выйграе гулец, які скінуў усе карты.';

  @override
  String get rulesUnoCall => 'Калі застаецца адна карта, адразу націсніце «Уно!». Супернікі могуць злавіць вас без «Уно» толькі праз секунду — тады вы бярэце 2 карты.';

  @override
  String get rulesUnoScoring => 'Хто першым скінуў усе карты, выйграе раунд і атрымлівае ачкі за рукі супернікаў: лічбы — па намінале, спецкарты — 20, чорныя — 50. Удваіх матч да 100, пры трох і больш гульцах — да 200.';

  @override
  String get unoColorRed => 'Red';

  @override
  String get unoColorYellow => 'Yellow';

  @override
  String get unoColorGreen => 'Green';

  @override
  String get unoColorBlue => 'Blue';

  @override
  String get unoDraw => 'Draw';

  @override
  String get unoKeep => 'Keep';

  @override
  String get unoSayUno => 'Uno!';

  @override
  String get unoChallengeUno => 'Challenge Uno';

  @override
  String get unoChallengeWd4 => 'Challenge +4';

  @override
  String get unoChooseColor => 'Choose a color';

  @override
  String get unoDrawPile => 'Draw pile';

  @override
  String get unoDiscardPile => 'Discard';

  @override
  String unoCardsCount(int count) {
    return 'Cards: $count';
  }

  @override
  String unoScore(int score) {
    return 'Score: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'Round $round · first to $target';
  }

  @override
  String get unoYourTurn => 'Your turn';

  @override
  String get unoWaitingTurn => 'Opponent’s turn';

  @override
  String get unoChooseColorHint => 'Choose a color for the wild card';

  @override
  String get unoWd4Hint => 'Draw 4 cards or challenge the Wild +4';

  @override
  String get unoDrawnHint => 'Play the drawn card or keep it';

  @override
  String get unoPlayHint => 'Play a matching color or value';

  @override
  String get unoDrawHint => 'No matching card — draw from the deck';

  @override
  String unoPendingDraw(int count) {
    return '+$count cards';
  }

  @override
  String get unoYouWon => 'You won the match!';

  @override
  String get unoYouLost => 'Match over';

  @override
  String get unoYouLostTimeout => 'Вы прайгралі па часе';

  @override
  String unoWinner(String name) {
    return 'Winner: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name выйграе раунд';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'Далей';

  @override
  String get unoRoundScoresTitle => 'Ачкі за раунд';

  @override
  String get unoDirectionClockwise => 'Clockwise';

  @override
  String get unoDirectionCounterclockwise => 'Counterclockwise';

  @override
  String get unoErrStackSameOnly => 'На +2 можна адказаць толькі +2, на +4 — толькі +4. +2 на +4 класці нельга.';

  @override
  String get unoErrCatchTooEarly => 'Пачакайце секунду — яны яшчэ могуць сказаць «Уно».';

  @override
  String get unoErrCallTooLate => 'Сказаць «Уно» ўжо нельга: наступны гулец ужо зрабіў ход.';

  @override
  String get gamesInDevelopment => 'У распрацоўцы';

  @override
  String rulesPokerPlayers(int players) {
    return 'Гульцы: $players.';
  }

  @override
  String get rulesPokerIntro => 'Тэхаскі холдэм. Кожнаму раздаюць 2 карты ў руку; на стол выходзяць 5 агульных карт.';

  @override
  String get rulesPokerPlay => 'Раўнды ставак: прэфлоп, флоп, тэрн і рывер. Можна фолд, колл, бет ці рэйз.';

  @override
  String get rulesPokerWin => 'Перамагае найлепшая камбінацыя з пяці карт (свае + агульныя) або той, хто застаўся адзін пасля фолдаў.';

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
  String get pokerCombinationsTitle => 'Камбінацыі';

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
  String get gamesRules => 'Правілы';

  @override
  String get gamesRulesTitle => 'Правілы гульні';

  @override
  String get gamesCreate => 'Стварыць гульню';

  @override
  String get gamesJoin => 'Далучыцца';

  @override
  String get gamesOpponentTurn => 'Ход суперніка';

  @override
  String get gamesCurrentGame => 'Бягучая гульня';

  @override
  String get gamesInvitedYou => 'Вас запрасілі';

  @override
  String get gamesTurnTime => 'Час на ход';

  @override
  String get gamesGridSize => 'Памер сеткі';

  @override
  String get gamesSwapSides => 'Змена бакоў';

  @override
  String get gamesNoCenter => 'Без старту па цэнтры';

  @override
  String get gamesObservation => 'Назіранне';

  @override
  String get gamesObservationHint => 'Можна глядзець да канца партыі';

  @override
  String get gamesFinishCurrentFirst => 'Спачатку завяршыце бягучую гульню';

  @override
  String get gamesVariantClassic => 'Класіка';

  @override
  String get gamesVariantGomoku => 'Гомоку';

  @override
  String get gamesVariantUltimate => 'Ультымейт';

  @override
  String get gamesVariantMulti3 => 'На траіх';

  @override
  String get gamesVariantMulti4 => 'На чацвярых';

  @override
  String get gamesDurakModePodkidnoi => 'Падкідны';

  @override
  String get gamesDurakModePerevodnoi => 'Пераводны';

  @override
  String get gamesDurakDeck24 => '24 карты';

  @override
  String get gamesDurakDeck36 => '36 карт';

  @override
  String get gamesDurakDeck52 => '52 карты';

  @override
  String rulesDurakMode(String mode) {
    return 'Рэжым: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'Гульцы: $players. Калода: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Гульня супраць бота, без ставак і ліміту часу.';

  @override
  String get rulesDurakAttack => 'Атакуючы кладзе карты, абаронца б’е (той жа масці старэйшай або казырам). Казыр б’ецца толькі старэйшым казырам.';

  @override
  String get rulesDurakBeat => 'Калі ўсе карты біты — атакуючы кажа «Біта», карты ідуць у адбой. Інакш абаронца бярэ ўсё са стала.';

  @override
  String get rulesDurakLoser => 'Прайграўшы — у каго ў канцы партыі засталіся карты, «дурак».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Гульцы $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Лобі $name';
  }

  @override
  String get lobbyMatchmake => 'Лобі';

  @override
  String get lobbyPrivateGame => 'Прыватная гульня';

  @override
  String get lobbySearchingOpponent => 'Пошук суперніка…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Шукаюць гэту гульню: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Чакаем, пакуль хтосьці націсне «Знайсці гульню» або «Далучыцца»';

  @override
  String get lobbyInviteTitle => 'Запрашэнне ў гульню';

  @override
  String get lobbyInvitedToPlay => 'Вас запрасілі згуляць';

  @override
  String get lobbyEnterGame => 'Увайсці ў гульню';

  @override
  String get lobbyGone => 'Лобі больш недаступнае';

  @override
  String get lobbyInvite => 'Запрасіць';

  @override
  String get lobbyInviteSent => 'Запрашэнне даслана';

  @override
  String get lobbyCopyLink => 'Падзяліцца спасылкай на гульню';

  @override
  String get lobbyLinkCopied => 'Спасылка скапіявана';

  @override
  String get lobbyNoFriendsOnline => 'Няма сяброў онлайн. Дашліце спасылку на гульню вышэй або пачакайце, пакуль сябры з’явяцца ў сетцы.';

  @override
  String get gameBot => 'Бот';

  @override
  String get gameOpponent => 'Супернік';

  @override
  String get gameYou => 'Вы';

  @override
  String get gameYouWon => 'Вы перамаглі!';

  @override
  String get gameYouLost => 'Вы прайгралі';

  @override
  String get gameYouWonOpponentLeft => 'Вы перамаглі — супернік выйшаў';

  @override
  String get gameYouWonOpponentTimeout => 'Вы перамаглі — у суперніка скончыўся час';

  @override
  String get gameDraw => 'Нічыя';

  @override
  String get gameExitTitle => 'Выхад з гульні';

  @override
  String get gameExitConfirm => 'Калі выйдзеце, прайграеце. Усё роўна выйсці?';

  @override
  String get gameStay => 'Застацца';

  @override
  String get gameLeave => 'Выйсці';

  @override
  String get gameSurrender => 'Здацца';

  @override
  String get gameSurrenderTitle => 'Здацца?';

  @override
  String get gameSurrenderConfirm => 'Вы прайграеце партыю і манеты стаўкі.';

  @override
  String get gameOfferDraw => 'Прапанаваць нічыю';

  @override
  String get gameFlipBoard => 'Перавярнуць дошку';

  @override
  String get gameReviewStart => 'У пачатак партыі';

  @override
  String get gameReviewPrev => 'Ход назад';

  @override
  String get gameReviewNext => 'Ход наперад';

  @override
  String get gameReviewEnd => 'Да бягучай пазіцыі';

  @override
  String get gameOfferDrawTitle => 'Прапанаваць нічыю?';

  @override
  String get gameOfferDrawConfirm => 'Супернік можа прыняць або адхіліць нічыю.';

  @override
  String get gameAcceptDrawTitle => 'Прыняць нічыю?';

  @override
  String get gameAcceptDrawConfirm => 'Партыя скончыцца нічыёй.';

  @override
  String get gameDrawOffered => 'Супернік прапануе нічыю';

  @override
  String get gameConnecting => 'Падключэнне да гульні…';

  @override
  String get gameWaitingOpponent => 'Чаканне суперніка';

  @override
  String get gameRematchOffer => 'Супернік прапануе рэванш';

  @override
  String get gameRematchDeclined => 'Супернік адхіліў рэванш';

  @override
  String get gameRematch => 'Рэванш';

  @override
  String get gameOtherOpponent => 'Іншы супернік';

  @override
  String get gameSwapSidesAction => 'Змяніць бакі';

  @override
  String get gameWriteMessage => 'Напісаць паведамленне';

  @override
  String get chatsTitle => 'Чаты';

  @override
  String get chatsEmpty => 'Пакуль няма чатаў.\nНацісніце значок справа ўверсе, каб абраць сябра і пачаць размову.';

  @override
  String get chatsNewChat => 'Новы чат';

  @override
  String get chatsNoMessages => 'Няма паведамленняў';

  @override
  String get chatsClearTitle => 'Ачысціць перапіску?';

  @override
  String get chatsClearDesc => 'Чат будзе выдалены назаўсёды.';

  @override
  String get chatsClearConfirm => 'Ачысціць';

  @override
  String get chatsBlockTitle => 'Заблакіраваць гэтага карыстальніка?';

  @override
  String get chatsBlockDesc => 'Вы больш не зможаце пісаць адно аднаму. Чат і сяброўства будуць выдалены.';

  @override
  String get chatsBlockConfirm => 'Заблакіраваць';

  @override
  String get chatsBlockedUsers => 'Заблакіраваныя карыстальнікі';

  @override
  String get chatsUnblock => 'Разблакіраваць';

  @override
  String get chatDialog => 'Чат';

  @override
  String get chatEmpty => 'Паведамленняў пакуль няма.\nДашліце першае.';

  @override
  String get chatMessageHint => 'Паведамленне';

  @override
  String get chatPaste => 'Уставіць';

  @override
  String get chatEmoji => 'Эмодзі';

  @override
  String get chatBuyEmojiHint => 'Купіце эмодзі ў краме на галоўным экране';

  @override
  String get chatEditing => 'Рэдагаванне';

  @override
  String get chatToday => 'Сёння';

  @override
  String get chatYesterday => 'Учора';

  @override
  String get chatFriendsOnly => 'Тэкст толькі для сяброў';

  @override
  String get emojiGroupEmotions => 'Эмоцыі';

  @override
  String get emojiGroupGame => 'Гульнявыя';

  @override
  String get emojiGroupFlags => 'Сцягі';

  @override
  String get emojiGroupAnimals => 'Жывёлы';

  @override
  String get emojiGroupFood => 'Ежа';

  @override
  String get emojiGroupTravel => 'Падарожжы';

  @override
  String get emojiGroupParty => 'Свята';

  @override
  String get emojiGroupObjects => 'Прадметы';

  @override
  String get friendsTitle => 'Сябры';

  @override
  String get friendsTabFriends => 'Сябры';

  @override
  String get friendsTabIncoming => 'Уваходныя';

  @override
  String get friendsTabOutgoing => 'Выходныя';

  @override
  String get friendsAdd => 'Дадаць у сябры';

  @override
  String get friendsRequestSent => 'Запыт дасланы';

  @override
  String get friendsFindTab => 'Знайсці сябра';

  @override
  String get friendsSearchHint => 'Пошук па ніку';

  @override
  String get friendsSearchPrompt => 'Скарыстайцеся пошукам, каб знайсці новых сяброў';

  @override
  String get friendsNothingFound => 'Нічога не знойдзена';

  @override
  String get friendsEmpty => 'У вас пакуль няма сяброў';

  @override
  String get friendsSearchNoMatches => 'Няма сяброў, якія адпавядаюць пошуку';

  @override
  String get friendsIncomingSearchNoMatches => 'Няма ўваходных заявак па запыце';

  @override
  String get friendsOutgoingSearchNoMatches => 'Няма выходных заявак па запыце';

  @override
  String get friendsNoIncoming => 'Няма ўваходных запытаў';

  @override
  String get friendsNoOutgoing => 'Няма выходных запытаў';

  @override
  String get friendsAlreadyFriends => 'Ужо ў сябрах';

  @override
  String get friendsRemoveTitle => 'Выдаліць з сяброў?';

  @override
  String get friendsRemoved => 'Выдалена з сяброў';

  @override
  String get friendsRequestAccepted => 'Запыт прыняты';

  @override
  String get friendsRequestDeclined => 'Запыт адхілены';

  @override
  String get friendsRequestCancelled => 'Запыт скасаваны';

  @override
  String get profileTitle => 'Профіль';

  @override
  String get profileSignInPrompt => 'Увайдзіце ў свой акаўнт';

  @override
  String get profileSignInHint => 'Каб наладзіць асабісты профіль';

  @override
  String get profileEdit => 'Рэдагаваць';

  @override
  String get profileCollections => 'Калекцыі';

  @override
  String get profileAge => 'Узрост';

  @override
  String get profileGender => 'Пол';

  @override
  String get profileGenderUnset => 'Не пазначана';

  @override
  String get profileGenderMale => 'Мужчынскі';

  @override
  String get profileGenderFemale => 'Жаночы';

  @override
  String get profileAvatar => 'Аватар';

  @override
  String get profileUploadPhoto => 'Загрузіць фота';

  @override
  String get profileChangePhoto => 'Змяніць аватар';

  @override
  String get shopTitle => 'Крама';

  @override
  String get shopEmojis => 'Эмодзі';

  @override
  String get shopEmojisSubtitle => 'Анімаваныя эмодзі для чата';

  @override
  String get shopCollections => 'Калекцыі';

  @override
  String get shopCollectionsSubtitle => 'Вітрына профілю, падарункі і даход';

  @override
  String get shopStakes => 'Стаўкі';

  @override
  String get shopStakesSubtitle => 'Разблакоўка павышаных ставак';

  @override
  String get shopEmojisHelp => 'Анімаваныя смайлікі для чата. Купіце набор і адпраўляйце іх у паведамленнях сябрам.';

  @override
  String get shopCollectionsHelp => 'Прадаць можна толькі новую або вінтажную калекцыю: 80% кошту для новай і 300% кошту для вінтажу. Пацёртую, стомленую і старую прадаць нельга.\n\nЗбярыце набор прадметаў: яны з’яўляюцца ў вітрыне профілю, іх можна дарыць. Кожны прадмет штодня прыносіць манеты, а поўны набор — яшчэ і асобны бонус.\n\nДзённы прыбытак прадмета залежыць ад стану і лічыцца ад звычайнай сумы. Новае прыносіць 100%. Пацёртае — 60%. Стомленае — 40%. Старое — 100%. Вінтажны прадмет прыносіць 200%, гэта значыць удвая больш за звычайны прыбытак.\n\nБонус поўнага набору не мяняецца, пакуль набор не стане вінтажным. Набор вінтажны, калі вінтажны кожны яго прадмет: тады бонус складае 300%, утрая больш за звычайны.\n\nСтан залежыць ад таго, як даўно прадмет у вас. Новае — першыя 7 дзён. Пацёртае — з 8-га дня да 2 месяцаў. Стомленае — з 2 да 6 месяцаў. Старое — з 6 месяцаў да года. Вінтаж — ад года.';

  @override
  String get shopStakesHelp => 'Разблакуйце вышэйшыя стаўкі ў гульнях. Чым вышэйшая стаўка, тым большы банк і выйгрыш.';

  @override
  String get inventoryTitle => 'Прадметы';

  @override
  String get inventoryEmpty => 'Пакуль нічога няма — заглядзіце ў краму';

  @override
  String get inventoryFrames => 'Рамкі';

  @override
  String get inventoryClaim => 'Забраць';

  @override
  String get inventorySell => 'Прадаць';

  @override
  String get inventoryGift => 'Падарыць';

  @override
  String get messageEdited => 'зменена';

  @override
  String get messageDeleted => 'Паведамленне выдалена';

  @override
  String get photo => 'Фота';

  @override
  String get camera => 'Камера';

  @override
  String get gallery => 'Галерэя';

  @override
  String get connectionError => 'Не ўдалося падключыцца да сервера.';

  @override
  String get serverError => 'Памылка сервера. Паспрабуйце пазней.';

  @override
  String get sessionExpired => 'Сесія скончылася. Увайдзіце зноў.';

  @override
  String get errNoInternet => 'Няма падключэння да інтэрнэту.';

  @override
  String get errTimeout => 'Час чакання выйшаў. Паспрабуйце яшчэ раз.';

  @override
  String get errGamesUnavailable => 'Гульні часова недаступныя';

  @override
  String get errSettingsSaveFailed => 'Не ўдалося захаваць наладу';

  @override
  String get errPushPermission => 'Дазвольце апавяшчэнні ў наладах браўзера або сістэмы.';

  @override
  String get balanceTitle => 'Баланс';

  @override
  String get coinBronze => 'Бронза';

  @override
  String get coinSilver => 'Серабро';

  @override
  String get coinGold => 'Золата';

  @override
  String get coinDiamond => 'Брыльянт';

  @override
  String get balanceZeroBronze => '0 бронзавых';

  @override
  String balanceBronzes(int count) {
    return '$count бронзавых';
  }

  @override
  String balanceSilvers(int count) {
    return '$count серабраных';
  }

  @override
  String balanceGolds(int count) {
    return '$count залатых';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count брыльянтаў';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/дзень';
  }

  @override
  String get balanceAbbrBronze => 'бр';

  @override
  String get balanceAbbrSilver => 'с.';

  @override
  String get balanceAbbrGold => 'з.';

  @override
  String get commonBackHome => 'Назад на галоўную';

  @override
  String get commonCopied => 'Скапіявана';

  @override
  String get commonClear => 'Ачысціць';

  @override
  String get commonTryLater => 'Паспрабуйце пазней.';

  @override
  String get commonTryRefresh => 'Паспрабуйце абнавіць старонку.';

  @override
  String get coinsTitle => 'Манеты';

  @override
  String get coinsLoginReward => 'Манеты за ўваход';

  @override
  String get coinsLoginAvailableToday => 'Даступна ўзнагарода за сёння';

  @override
  String get coinsLoginStreak => 'Штодзённая серыя ўваходаў';

  @override
  String get coinsFriendReward => 'Манеты за сябра';

  @override
  String get coinsTasks => 'Заданні';

  @override
  String get coinsTasksSubtitle => 'Узнагароды за профіль, сяброў і гульні';

  @override
  String get coinsTasksRewards => 'Ёсць узнагароды да атрымання';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount за рэгістрацыю па спасылцы';
  }

  @override
  String get coinsLoadRewardsFailed => 'Не ўдалося загрузіць узнагароды';

  @override
  String get coinsClaimReward => 'Забраць узнагароду';

  @override
  String get coinsAlreadyClaimed => 'Ужо атрымана';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · сёння';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · яшчэ 1 дзень';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · яшчэ $remaining';
  }

  @override
  String get coinsInviteFriend => 'Запрасі сябра';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount за кожнага, хто зарэгіструецца па вашай спасылцы';
  }

  @override
  String get coinsCopyLink => 'Скапіяваць спасылку';

  @override
  String get coinsHowItWorks => 'Як гэта працуе';

  @override
  String get coinsHowStep1 => 'Скапіюйце спасылку і адпраўце сябру';

  @override
  String get coinsHowStep2 => 'Сябар рэгіструецца па гэтай спасылцы';

  @override
  String coinsHowStep3(String amount) {
    return 'Вам нарахоўваецца $amount';
  }

  @override
  String get achievementsTitle => 'Дасягненні';

  @override
  String achievementsProgress(String progress) {
    return 'Прагрэс: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Рамку атрымана';

  @override
  String get achievementsClaimed => 'Атрымана';

  @override
  String get achievementsOpenFrame => 'Адкрыць рамку';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Вы ўпэўнены, што хочаце выдаліць $name з сяброў?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Прыбраць';

  @override
  String get friendsRemove => 'Выдаліць з сяброў';

  @override
  String get friendsAcceptRequest => 'Прыняць заяўку';

  @override
  String get friendsDeclineRequest => 'Адхіліць заяўку';

  @override
  String get friendsCancelRequest => 'Адмяніць заяўку';

  @override
  String get friendsSendRequest => 'Адправіць заяўку ў сябры';

  @override
  String get friendsRequestAlreadySent => 'Заяўка ўжо адпраўлена';

  @override
  String get friendsIncomingStatus => 'Уваходная заяўка';

  @override
  String get friendsOutgoingStatus => 'Выходная заяўка';

  @override
  String get friendsNotFriends => 'Не ў сябрах';

  @override
  String get friendsCollapseSearch => 'Згарнуць пошук';

  @override
  String get friendsExpandSearch => 'Паказаць пошук';

  @override
  String get friendsLoadFailed => 'Не ўдалося загрузіць сяброў';

  @override
  String friendsSince(String date) {
    return 'Сябруеце з: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Уваходная заяўка: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Выходная заяўка: $date';
  }

  @override
  String get userInfoTitle => 'Інфармацыя пра карыстальніка';

  @override
  String profileAgeYears(int age) {
    return '$age гадоў';
  }

  @override
  String get shopBuy => 'Купіць';

  @override
  String get shopBuyTitle => 'Купіць?';

  @override
  String get shopBuyStakeTitle => 'Купіць стаўку?';

  @override
  String get shopBuyEmojiTitle => 'Купіць смайлік?';

  @override
  String get shopBuyCollectionTitle => 'Купіць калекцыю?';

  @override
  String shopPrice(String price) {
    return 'Цана: $price';
  }

  @override
  String get shopOwned => 'Куплена';

  @override
  String get shopHave => 'Ёсць';

  @override
  String get shopEmpty => 'Пакуль пуста';

  @override
  String shopPurchased(String title) {
    return '$title куплены';
  }

  @override
  String get shopEmojiUses => 'Атрымаеце: 10 выкарыстанняў';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 выкарыстанняў';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 выкарыстанняў';
  }

  @override
  String get shopBuyTen => 'Купіць · 10 шт.';

  @override
  String shopDailyIncome(String amount) {
    return 'Даход: $amount';
  }

  @override
  String get shopBuyOnce => 'Пакупка адзін раз';

  @override
  String get shopSellRefund => 'Продаж залежыць ад стану калекцыі';

  @override
  String get collectionConditionNew => 'Новае';

  @override
  String get collectionConditionWorn => 'Пацёртае';

  @override
  String get collectionConditionTired => 'Стомленае';

  @override
  String get collectionConditionShabby => 'Старое';

  @override
  String get collectionConditionVintage => 'Вінтаж';

  @override
  String shopCollectionAdded(String title) {
    return '$title дададзены ў профіль';
  }

  @override
  String shopSetBonus(int percent) {
    return 'бонус групы +$percent%';
  }

  @override
  String get shopSetComplete => 'Сабрана';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Сабрана · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Прадаць?';

  @override
  String inventorySellDesc(String amount) {
    return 'Вы атрымаеце $amount';
  }

  @override
  String get inventoryCollectionNotSellable => 'Прадаць можна толькі новую або вінтажную калекцыю.';

  @override
  String get inventoryCollectionNotSellableTitle => 'Нельга прадаць';

  @override
  String get inventoryCollectionNotSellableHint => 'Прадаць можна толькі новы прадмет або вінтажны. Скарыстайцеся эліксірам, каб змяніць стан.';

  @override
  String inventorySold(String amount) {
    return 'Прадана: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Спачатку дадайце сяброў';

  @override
  String get inventoryGiftTitle => 'Падарыць калекцыю?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'Падарыць «$title» карыстальніку $name?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Падарана: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'Гулец ужо мае гэты прадмет';

  @override
  String get inventoryGiftSelf => 'Нельга дарыць сабе';

  @override
  String get inventoryGiftNotOwned => 'Гэтага прадмета няма ў вашым інвентары';

  @override
  String get inventoryLoadFailed => 'Не ўдалося загрузіць прадметы';

  @override
  String get inventoryNoCollections => 'Няма калекцый — купіце ў краме';

  @override
  String get inventoryNoEmojis => 'Няма смайлікаў — купіце ў краме';

  @override
  String get inventoryNoFrames => 'Няма рамак — выйграйце 10 гульняў у лізе (дасягненні)';

  @override
  String get inventoryNoStakes => 'Няма купленых ставак';

  @override
  String inventoryEmojiLeft(int count) {
    return 'Засталося $count';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Даход: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Даход заўтра: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Гатова';

  @override
  String get inventoryIncomeTomorrowLabel => 'Заўтра';

  @override
  String inventoryStakeGold(String amount) {
    return 'Можна ставіць $amount золата';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'Можна ставіць $amount серабра';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'Атрымана +$amount';
  }

  @override
  String get chatsLoadFailed => 'Не ўдалося загрузіць чаты';

  @override
  String get chatsLoadListFailed => 'Не ўдалося загрузіць спіс';

  @override
  String get chatsBlockedEmpty => 'Спіс пусты';

  @override
  String chatsBlockedAt(String date) {
    return 'Заблакаваны: $date';
  }

  @override
  String get chatsCreateFailed => 'Не ўдалося стварыць чат';

  @override
  String get chatsNeedFriendsFirst => 'Спачатку дадайце сяброў, потым можна адкрыць чат.';

  @override
  String get chatsFriendsNotFound => 'Сябры не знойдзены';

  @override
  String get chatsFindFriendHint => 'Знайсці сябра па ніку';

  @override
  String get chatsSelectChat => 'Выберыце чат';

  @override
  String get chatsSelectHint => 'Выберыце дыялог са спісу злева';

  @override
  String get chatEditFailed => 'Не ўдалося змяніць паведамленне';

  @override
  String get chatSendFailed => 'Не ўдалося адправіць паведамленне';

  @override
  String get chatDeleteFailed => 'Не ўдалося выдаліць паведамленне';

  @override
  String get chatEmojiSendFailed => 'Не ўдалося адправіць смайлік';

  @override
  String get chatLoadFailed => 'Не ўдалося загрузіць паведамленні';

  @override
  String get chatBackToGame => 'Назад у гульню';

  @override
  String get chatBackToChats => 'Назад да чатаў';

  @override
  String get chatActions => 'Дзеянні з чатам';

  @override
  String get chatAutoTranslate => 'Аўтапераклад';

  @override
  String get chatScrollToEnd => 'У канец перапіскі';

  @override
  String chatReplyingTo(String name) {
    return 'У адказ $name';
  }

  @override
  String get chatGift => 'Падарунак';

  @override
  String get chatCollection => 'Калекцыя';

  @override
  String get chatGiftCollection => 'Падарунак · калекцыя';

  @override
  String get chatThisUser => 'гэтага карыстальніка';

  @override
  String get gamesLobbyLoadFailed => 'Не ўдалося загрузіць лобі.';

  @override
  String get gamesTapChangeStake => 'Націсніце, каб змяніць стаўку';

  @override
  String get gamesTapChangeTurnTime => 'Націсніце, каб змяніць час на ход';

  @override
  String get gamesTapChangeGrid => 'Націсніце, каб змяніць памер сеткі';

  @override
  String get gamesSwapSidesHint => 'O можа стаць X пасля 1-га ходу';

  @override
  String get gamesNoCenterHint => 'Першы ход не ў цэнтр';

  @override
  String get lobbyInviteSentShort => 'Адпраўлена';

  @override
  String get lobbySearchShort => 'Пошук';

  @override
  String get lobbySearchPlayers => 'Пошук гульцоў';

  @override
  String get lobbyInviteDeclinedShort => 'Адмова';

  @override
  String get lobbyInvitesSentWaiting => 'Запрашэнні адпраўлены. Чакайце адказу.';

  @override
  String get lobbyLinkCopiedHint => 'Устаўце яе ў чат або паведамленне сябру';

  @override
  String get lobbyCopyLinkHint => 'Скапіяваць спасылку ў буфер абмену';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name запрашае вас пагуляць';
  }

  @override
  String gameOpponentWon(String name) {
    return 'Перамог $name';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Час выйшаў. Перамог $name';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds с';
  }

  @override
  String get adminTitle => 'Адмінка';

  @override
  String get tournamentsTitle => 'Турніры';

  @override
  String get profileAgeInvalid => 'Увядзіце ўзрост ад 1 да 111';

  @override
  String get profileSaveFailed => 'Не ўдалося захаваць профіль';

  @override
  String get profileNameHint => 'Лацініца, лічбы, _ да 10 сімвалаў';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'Ад 1 да 111';

  @override
  String get profileAboutHint => 'Да 100 сімвалаў (па жаданні)';

  @override
  String get profileProcessingPhoto => 'Апрацоўка фота…';

  @override
  String get profileCropTitle => 'Выберыце вобласць аватара';

  @override
  String get profileCropHint => 'Маштабуйце і рухайце фота';

  @override
  String get profileApply => 'Ужыць';

  @override
  String get profilePreparing => 'Падрыхтоўка…';

  @override
  String get profileGalleryTitle => 'Фота';

  @override
  String get profileGalleryAdd => 'Дадаць фота';

  @override
  String get profileMakePrimary => 'Зрабіць асноўным';

  @override
  String get profilePhotoDelete => 'Выдаліць фота';

  @override
  String get profilePhotosLimit => 'Можна загрузіць не больш за 3 фота';

  @override
  String get profilePhotosEmpty => 'Пакуль няма фота';

  @override
  String get profilePhotoUploadFailed => 'Не атрымалася загрузіць фота';

  @override
  String get profilePhotoDeleteFailed => 'Не атрымалася выдаліць фота';

  @override
  String get profilePhotoTooLarge => 'Фота занадта вялікае';

  @override
  String get profileSetPrimaryFailed => 'Не атрымалася зрабіць асноўным';

  @override
  String timeSecondsShort(int seconds) {
    return '$seconds с';
  }

  @override
  String get timeOneMin => '1 хв';

  @override
  String get timeTenMin => '10 хв';

  @override
  String rulesIntro(String grid) {
    return 'Крыжыкі-нулікі на полі $grid. Ходзяць па чарзе, X пачынае.';
  }

  @override
  String rulesWin(int n) {
    return 'Перамога: трэба выбудаваць $n у шэраг па гарызанталі, вертыкалі ці дыяганалі.';
  }

  @override
  String get rulesNoTimeLimit => 'Без абмежавання часу на ход.';

  @override
  String rulesTurnTime(String time) {
    return 'Час на ход: $time. Калі час выйшаў — параза.';
  }

  @override
  String rulesStake(String stake) {
    return 'Стаўка: $stake. На столькі манет ідзе гульня.';
  }

  @override
  String get rulesSwap => 'Змена бакоў: O можа памяняцца месцамі з X пасля першага ходу X.';

  @override
  String get rulesNoCenter => 'Забарона цэнтра: X не можа хадзіць у цэнтр першым ходам.';

  @override
  String get collectionSetLegends => 'Легенды';

  @override
  String get collectionSetSpace => 'Космас';

  @override
  String get collectionSetGems => 'Каштоўнасці';

  @override
  String get collectionSetParty => 'Свята';

  @override
  String get collectionSetNature => 'Прырода';

  @override
  String get collectionSetAdventures => 'Прыгоды';

  @override
  String collectionCardMeta(String amount) {
    return 'Калекцыя · вітрына · падарунак · продаж · +$amount';
  }

  @override
  String get coinsDayOne => 'дзень';

  @override
  String get coinsDayFew => 'дні';

  @override
  String get coinsDayMany => 'дзён';

  @override
  String get giftFriendTitle => 'Падарыць сябру';

  @override
  String photoCount(int count) {
    return 'Фота ($count)';
  }

  @override
  String photoCountWithText(int count, String text) {
    return 'Фота ($count): $text';
  }

  @override
  String photoWithText(String text) {
    return 'Фота: $text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count смайлікаў · па $price';
  }

  @override
  String get chatsExpandPanel => 'Разгарнуць панэль';

  @override
  String get chatsCollapsePanel => 'Згарнуць панэль';

  @override
  String get chatReplySourceMissing => 'Зыходнае паведамленне не знойдзена';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Стаўка $n срэбра';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Стаўка $n золата';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Права ставіць $n срэбра ў гульнях';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Права ставіць $n золата ў гульнях';
  }

  @override
  String get chatReplySelf => 'сабе';

  @override
  String get chatReplyPeer => 'суразмоўцу';

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
  String get statsTitle => 'Статыстыка';

  @override
  String get statsLoadFailed => 'Не ўдалося загрузіць статыстыку';

  @override
  String get statsAllGames => 'Усе гульні';

  @override
  String get statsEmptyTitle => 'Пакуль няма згуляных партый';

  @override
  String get statsEmptyHint => 'Згуляйце першую гульню, каб тут з’явілася статыстыка.';

  @override
  String get statsWins => 'Перамогі';

  @override
  String get statsDraws => 'Нічыі';

  @override
  String get statsLosses => 'Паражэнні';

  @override
  String get statsWinRate => 'Адсотак перамог';

  @override
  String get statsTopWon => 'Найбольш перамог супраць';

  @override
  String get statsTopDrawn => 'Найбольш нічыіх з';

  @override
  String get statsTopLost => 'Найбольш паражэнняў ад';

  @override
  String get statsTimePlayed => 'Час у гульні';

  @override
  String get statsYourScore => 'Ваш лік';

  @override
  String get profileShowStats => 'Паказваць статыстыку';

  @override
  String get statsDurationZeroMinutes => '0 хв';

  @override
  String get gameYouWonOpponentForfeit => 'Супернік здаўся. Вы перамаглі!';

  @override
  String get lobbyLeaveTitle => 'Пакінуць лобі?';

  @override
  String get lobbyLeaveConfirm => 'Лобі будзе выдалена пасля выхаду. Запрошаныя сябры атрымаюць адмову.';

  @override
  String get lobbyLeave => 'Пакінуць';

  @override
  String statsDurationHours(int hours) {
    return '$hours гадз';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours гадз $minutes хв';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes хв';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'Вы здаліся. $name перамог';
  }

  @override
  String get supportTitle => 'Падтрымка';

  @override
  String get supportUnavailable => 'Падтрымка недаступная';

  @override
  String get supportOpenFailed => 'Не ўдалося адкрыць чат з падтрымкай';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Вам налічана $amount манет';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return 'Спісана $amount манет';
  }

  @override
  String get coinsCreditCardTitle => 'Вам налічаны манеты';

  @override
  String get coinsClaim => 'Забраць';

  @override
  String get durakActionPass => 'Пас';

  @override
  String get durakRoleTook => 'Забраў';

  @override
  String get durakRoleBeats => 'Б\'е';

  @override
  String get durakRoleThrowIn => 'Падкід';

  @override
  String get durakRoleTurn => 'Ход';

  @override
  String get durakRoleDefends => 'Адбіваецца';

  @override
  String get durakStatusTaking => 'Бяру';

  @override
  String get durakHintDefenderTurn => 'Ход абаронцы';

  @override
  String get gameYouEliminated => 'Вы выбылі';

  @override
  String gameYouPlaced(int place) {
    return 'Вы занялі $place-е месца';
  }

  @override
  String get gameOverNeutral => 'Партыя завершана';

  @override
  String gameTurnOf(String name) {
    return 'Ход $name';
  }

  @override
  String get chatGroupTooltip => 'Чат групы';

  @override
  String get lobbyChatNotReady => 'Чат лобі яшчэ не створаны';

  @override
  String get chatsGroupChat => 'Групавы чат';

  @override
  String chatsMembersCount(int count) {
    return 'Удзельнікі: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count уч.';
  }

  @override
  String get chatsYouSuffix => '(вы)';

  @override
  String get chatTitleDurak3 => 'Дурак на траіх';

  @override
  String get chatTitleDurak4 => 'Дурак на чацвярых';

  @override
  String get rulesTttUltimate => 'Ультымейт: 9 міні-палёў 3×3. Ход у клетку адпраўляе суперніка на адпаведнае міні-поле. Перамагае той, хто сабраў лінію на мета-полі.';

  @override
  String get rulesTttMulti3 => 'На траіх: поле 3×3, трое гульцоў (X, O, △). Хто сабраў лінію са сваіх знакаў — перамагае.';

  @override
  String get rulesTttMulti4 => 'На чацвярых: поле 4×4, чацвёра гульцоў (X, O, △, □). Хто сабраў лінію са сваіх знакаў — перамагае.';

  @override
  String get adminUsersTab => 'Карыстальнікі';

  @override
  String get adminSupportTab => 'Падтрымка';

  @override
  String get adminSearchHint => 'Пошук па email або ніку';

  @override
  String get adminRoleAdmins => 'Адміны';

  @override
  String get adminRoleUsers => 'Карыстальнікі';

  @override
  String get adminRoleAll => 'Усе ролі';

  @override
  String get adminStatusFrozen => 'Замарожаныя';

  @override
  String get adminStatusActive => 'Актыўныя';

  @override
  String get adminStatusAny => 'Любы статус';

  @override
  String get adminOrderDesc => 'Па змяншэнні';

  @override
  String get adminOrderAsc => 'Па ўзрастанні';

  @override
  String adminLoadFailed(String error) {
    return 'Памылка загрузкі: $error';
  }

  @override
  String get adminUsersEmpty => 'Карыстальнікі не знойдзены';

  @override
  String get adminSortLastSeen => 'Па апошнім візіце';

  @override
  String get adminSortEmail => 'За email';

  @override
  String get adminSortCreated => 'Па даце рэг.';

  @override
  String adminBronzeBalance(int amount) {
    return '$amount бр.';
  }

  @override
  String get adminRevokeAdmin => 'Прыбраць адміна';

  @override
  String get adminGrantAdmin => 'Зрабіць адмінам';

  @override
  String get adminAdminRevoked => 'Правы адміна зняты';

  @override
  String get adminAdminGranted => 'Правы адміна выдадзены';

  @override
  String get adminGrantCoins => 'Налічыць манеты';

  @override
  String get adminWriteSupport => 'Напісаць ад падтрымкі';

  @override
  String get adminUnfreeze => 'Размарозіць';

  @override
  String get adminFreeze => 'Замарозіць';

  @override
  String get adminUnfrozen => 'Размарожаны';

  @override
  String get adminFrozenDone => 'Замарожаны';

  @override
  String get adminResetPassword => 'Скінуць пароль';

  @override
  String get adminCoinsAmountHint => 'Колькасць (адмоўнае = спісанне)';

  @override
  String get adminReasonOptional => 'Прычына (неабавязкова)';

  @override
  String get adminGrantSent => 'Картка адпраўлена ў чат падтрымкі';

  @override
  String adminCoinsDebited(int amount) {
    return 'Спісана $amount бронзавых';
  }

  @override
  String get adminGrantVerb => 'Налічыць';

  @override
  String get adminNewPasswordHint => 'Новы пароль (мін. 6)';

  @override
  String get adminPasswordReset => 'Пароль скінуты';

  @override
  String get adminResetVerb => 'Скінуць';

  @override
  String adminShortError(String error) {
    return 'Памылка: $error';
  }

  @override
  String get adminSupportEmpty => 'Няма зваротаў у падтрымку';

  @override
  String get adminUserFallback => 'Карыстальнік';

  @override
  String get apiErrTooManyRequests => 'Зашмат запытаў. Паспрабуйце пазней.';

  @override
  String get apiErrMoveConflict => 'Ход канфліктуе. Паўтарыце.';

  @override
  String get shopElixirs => 'Elixirs';

  @override
  String get shopElixirsSubtitle => 'Rejuvenate, age, or speed up collections';

  @override
  String get shopElixirsHelp => 'Three shelves: rejuvenation, aging, and acceleration. Each has six elixirs, one per collection set. An elixir works only on its own set.\n\nRejuvenation makes a collection one step newer, and never newer than new. Aging makes it one step older, and never older than shabby. Acceleration is only for a shabby item: three months left until vintage, once. An elixir never grants vintage by itself.\n\nA bought elixir stays in Items. Use it from the collection card or from the elixir card. Each use spends one.';

  @override
  String get elixirGroupRejuvenate => 'Амаладжэнне';

  @override
  String get elixirGroupAge => 'Старэнне';

  @override
  String get elixirGroupAccelerate => 'Паскарэнне';

  @override
  String get elixirEffectRejuvenate => 'амаладжэння';

  @override
  String get elixirEffectAge => 'старэння';

  @override
  String get elixirEffectAccelerate => 'паскарэння';

  @override
  String get elixirAdjCelebration => 'Святочны';

  @override
  String get elixirAdjNature => 'Прыродны';

  @override
  String get elixirAdjLegends => 'Легендарны';

  @override
  String get elixirAdjCosmic => 'Касмічны';

  @override
  String get elixirAdjAdventure => 'Прыгодніцкі';

  @override
  String get elixirAdjJewels => 'Каштоўны';

  @override
  String elixirName(String adjective, String effect) {
    return '$adjective эліксір $effect';
  }

  @override
  String get elixirHelpRejuvenate => 'Makes the collection one step newer. Not newer than new.';

  @override
  String get elixirHelpAge => 'Makes the collection one step older. Not older than shabby.';

  @override
  String get elixirHelpAccelerate => 'Shabby only. Three months left until vintage, once.';

  @override
  String get elixirUseRejuvenate => 'Амалоджваць';

  @override
  String get elixirUseAge => 'Састарыць';

  @override
  String get elixirUseAccelerate => 'Паскорыць';

  @override
  String get elixirUse => 'Выкарыстаць';

  @override
  String collectionLeftDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дзён',
      many: '$count дзён',
      few: '$count дні',
      one: '$count дзень',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count гадзін',
      many: '$count гадзін',
      few: '$count гадзіны',
      one: '$count гадзіна',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хвілін',
      many: '$count хвілін',
      few: '$count хвіліны',
      one: '$count хвіліна',
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
