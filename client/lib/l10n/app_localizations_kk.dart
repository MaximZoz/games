import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Басты бет';

  @override
  String get navProfile => 'Профиль';

  @override
  String get navFriends => 'Достар';

  @override
  String get navChats => 'Чаттар';

  @override
  String get navGames => 'Ойындар';

  @override
  String get navSettings => 'Параметрлер';

  @override
  String get settingsTitle => 'Параметрлер';

  @override
  String get settingsLanguage => 'Тіл';

  @override
  String get settingsLanguageSystem => 'Жүйе бойынша';

  @override
  String get settingsAddBotsTitle => '30 с кейін бот қосу';

  @override
  String get settingsAddBotsSubtitle => 'Ойын іздеуде: 30 секунд ішінде қарсылас табылмаса, ойын ботпен басталады (ставка 1 қолаға қайтарылады)';

  @override
  String get settingsOfflineModeTitle => 'Желі режимі';

  @override
  String get settingsOfflineModeSubtitle => 'Офлайн: ботпен бірден ойнау, ставкалар мен марапаттарсыз, чаттар мен достарсыз. Сатып алулар сақталады және онлайн режимде қолданылады. Онлайн — интернет бар кезде немесе пайдаланушы баптауы бойынша.';

  @override
  String get settingsModeOnline => 'Онлайн';

  @override
  String get settingsModeOffline => 'Офлайн';

  @override
  String get gamesAlternateStartsHint => 'Кезекпен кім партияны бастайды';

  @override
  String get rulesAlternateStarts => 'Кім бірінші жүретіні партиядан партияға ауысады.';

  @override
  String get offlineBadgeTooltip => 'Офлайн режим';

  @override
  String get offlineModePopupTitle => 'Офлайн режим';

  @override
  String get offlineModePopupBody => 'Офлайн режим қосулы. Ставкалар мен марапаттарсыз ботпен ойнаңыз. Чаттар, достар және лобби жасырылған. Сатып алулар онлайн режимде қолданылады.';

  @override
  String get offlineModePopupSettings => 'Баптаулар';

  @override
  String get gamesPlay => 'Ойнау';

  @override
  String get offlineGameTitle => 'Ботпен ойын';

  @override
  String get offlineGameHint => 'Ставкалар мен марапаттарсыз · тек офлайн';

  @override
  String get offlineBotWon => 'Бот жеңді';

  @override
  String get offlineBotThinking => 'Бот жүрісі…';

  @override
  String get offlinePlayAgain => 'Тағы';

  @override
  String offlineBotName(int n) {
    return 'Бот $n';
  }

  @override
  String get durakActionTake => 'Алу';

  @override
  String get durakActionAll => 'Барлығы';

  @override
  String get durakActionDone => 'Дайын';

  @override
  String get durakActionBito => 'Бита';

  @override
  String get durakHintDefend => 'Қорғаныңыз';

  @override
  String get durakHintDefendOrTransfer => 'Қорғаныңыз немесе ауыстырыңыз';

  @override
  String get durakHintOpponentDefends => 'Қарсылас қорғануда';

  @override
  String get durakHintThrowInFirst => 'Карта тастаңыз (бірінші соққыда макс. 5)';

  @override
  String get durakHintThrowIn => 'Карта тастаңыз немесе қорғанысты күтіңіз';

  @override
  String get durakHintOpponentThrows => 'Қарсылас тастайды';

  @override
  String get durakHintTakeFollow => 'Алғаннан кейін тастаңыз немесе «Дайын» басыңыз';

  @override
  String get durakHintOpponentTakeFollow => 'Қарсылас алғаннан кейін тастай алады';

  @override
  String get durakHintBito => 'Карта тастаңыз немесе «Бита» деңіз';

  @override
  String get durakHintOpponentBito => 'Қарсылас тастайды немесе «Бита» дейді';

  @override
  String get durakHintYourAttack => 'Сіздің жүріс — шабуылдаңыз';

  @override
  String get durakHintOpponentAttack => 'Қарсылас шабуылдауда';

  @override
  String get durakHintYouLost => 'Жеңілдіңіз — сіз дурак';

  @override
  String get durakHintDrawAllOut => 'Тең ойын — барлығы шықты';

  @override
  String get durakHintYouFinished => 'Сіз шықтыңыз — соңын күтеміз';

  @override
  String get durakFirstLeadYou => 'Сіз жүресіз';

  @override
  String get durakFirstLeadOpponent => 'Қарсылас жүреді';

  @override
  String get durakFirstLeadBot => 'Бот жүреді';

  @override
  String durakFirstLeadOf(String name) {
    return '$name жүреді';
  }

  @override
  String get durakFirstLeadReason => 'Кіші козырь';

  @override
  String get shopPurchaseQueued => 'Сатып алу сақталды — онлайн режимде қолданылады';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — сатып алу қолданылды';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — сатып алу қолданылмады: $reason';
  }

  @override
  String get settingsFriendsOnlyTitle => 'Тек достардан хабарлама';

  @override
  String get settingsFriendsOnlySubtitle => 'Достар емес адамдар тек эмодзи жібере алады. Спам кедергі жасаса, пайдаланушыны уақытша бұғаттаңыз.';

  @override
  String get settingsNotifications => 'Хабарландырулар';

  @override
  String get settingsPushChat => 'Чат';

  @override
  String get settingsPushFriends => 'Достар';

  @override
  String get settingsPushGames => 'Ойындар';

  @override
  String get settingsPushRewards => 'Марапаттар';

  @override
  String settingsAppVersion(String version) {
    return 'Нұсқа $version';
  }

  @override
  String get appUpdateTitle => 'Жаңарту қолжетімді';

  @override
  String get appUpdateBody => 'Қолданбаның жаңа нұсқасы қолжетімді. Жалғастыру үшін жаңартыңыз.';

  @override
  String get appUpdateWhatsNew => 'Жаңалықтар';

  @override
  String get appUpdateOk => 'Жаңарту';

  @override
  String get appUpdateLaterBanner => 'Осы ойыннан кейін қолданбаны жаңартамыз';

  @override
  String get loginTitle => 'Кіру';

  @override
  String get loginSubtitle => 'Email немесе логин мен құпия сөзді енгізіңіз';

  @override
  String get loginEmailLabel => 'Email немесе логин';

  @override
  String get loginPasswordLabel => 'Құпия сөз';

  @override
  String get loginSubmit => 'Кіру';

  @override
  String get loginNoAccount => 'Аккаунт жоқ па? Тіркелу';

  @override
  String get loginEmailRequired => 'Email немесе логин енгізіңіз';

  @override
  String get loginPasswordRequired => 'Құпия сөзді енгізіңіз';

  @override
  String get loginTooltip => 'Кіру';

  @override
  String get logoutTooltip => 'Шығу';

  @override
  String get registerTitle => 'Тіркелу';

  @override
  String get registerSubtitle => 'Ойнау үшін аккаунт жасаңыз';

  @override
  String get registerNameLabel => 'Аты (логин)';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'Құпия сөз';

  @override
  String get registerSubmit => 'Тіркелу';

  @override
  String get registerHaveAccount => 'Аккаунт бар ма? Кіру';

  @override
  String get registerNameRequired => 'Атын енгізіңіз';

  @override
  String get registerNameNoSpaces => 'Атта бос орын болмауы керек';

  @override
  String get registerNameMax => 'Ең көбі 20 таңба';

  @override
  String get registerNameHint => '20 таңбаға дейін';

  @override
  String get registerEmailRequired => 'Email енгізіңіз';

  @override
  String get registerEmailInvalid => 'Жарамсыз email';

  @override
  String get registerPasswordHint => 'Кемінде 6 таңба';

  @override
  String get registerPasswordMin => 'Құпия сөз кемінде 6 таңба болуы керек';

  @override
  String get commonCancel => 'Бас тарту';

  @override
  String get commonSave => 'Сақтау';

  @override
  String get commonDelete => 'Жою';

  @override
  String get commonEdit => 'Өңдеу';

  @override
  String get commonReply => 'Жауап беру';

  @override
  String get commonSend => 'Жіберу';

  @override
  String get commonClose => 'Жабу';

  @override
  String get commonRetry => 'Қайталау';

  @override
  String get commonLoading => 'Жүктелуде…';

  @override
  String get commonError => 'Қате';

  @override
  String get commonOnline => 'желіде';

  @override
  String get commonOffline => 'желіде емес';

  @override
  String get commonOnlineCap => 'Онлайн';

  @override
  String get commonUser => 'Пайдаланушы';

  @override
  String get commonPlayer => 'Ойыншы';

  @override
  String get commonAboutMe => 'Өзім туралы';

  @override
  String get commonBack => 'Артқа';

  @override
  String get commonAccept => 'Қабылдау';

  @override
  String get commonDecline => 'Қабылдамау';

  @override
  String get commonCreating => 'Жасалуда…';

  @override
  String get commonSearching => 'Іздеу…';

  @override
  String get commonInsufficientCoins => 'Монета жеткіліксіз';

  @override
  String get commonNotFound => 'Табылмады';

  @override
  String get commonServerErrorShort => 'Сервер қатесі';

  @override
  String get commonForbidden => 'Қолжетімділік жоқ';

  @override
  String get commonUserBlocked => 'Пайдаланушы бұғатталған';

  @override
  String get commonUserNotFound => 'Пайдаланушы табылмады';

  @override
  String get commonGenericError => 'Бірдеңе дұрыс болмады. Қайталап көріңіз.';

  @override
  String get timeJustNow => 'жаңа ғана';

  @override
  String get timeYesterday => 'кеше';

  @override
  String timeMinutesAgo(int count) {
    return '$count мин бұрын';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count сағ бұрын';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count күн бұрын';
  }

  @override
  String get timeWeekAgo => 'бір апта бұрын';

  @override
  String timeWeeksAgo(int count) {
    return '$count апт. бұрын';
  }

  @override
  String get timeMonthAgo => 'бір ай бұрын';

  @override
  String timeMonthsAgo(int count) {
    return '$count ай бұрын';
  }

  @override
  String get timeYearAgo => 'бір жыл бұрын';

  @override
  String timeYearsAgo(int count) {
    return '$count ж. бұрын';
  }

  @override
  String get weekdaySun => 'жс';

  @override
  String get weekdayMon => 'дс';

  @override
  String get weekdayTue => 'сс';

  @override
  String get weekdayWed => 'ср';

  @override
  String get weekdayThu => 'бс';

  @override
  String get weekdayFri => 'жм';

  @override
  String get weekdaySat => 'сб';

  @override
  String get monthJan => 'қаң';

  @override
  String get monthFeb => 'ақп';

  @override
  String get monthMar => 'нау';

  @override
  String get monthApr => 'сәу';

  @override
  String get monthMay => 'мам';

  @override
  String get monthJun => 'мау';

  @override
  String get monthJul => 'шіл';

  @override
  String get monthAug => 'там';

  @override
  String get monthSep => 'қыр';

  @override
  String get monthOct => 'қаз';

  @override
  String get monthNov => 'қар';

  @override
  String get monthDec => 'жел';

  @override
  String get homeAchievements => 'Жетістіктер';

  @override
  String get homeAchievementsSubtitle => 'Ойын нәтижелеріңіз';

  @override
  String get homeAchievementsRewards => 'Алынатын марапаттар бар';

  @override
  String get homeCoins => 'Монеталар';

  @override
  String get homeCoinsSubtitle => 'Баланс және марапаттар';

  @override
  String get homeCoinsDailyReward => 'Кіру марапаты қолжетімді';

  @override
  String get homeItems => 'Заттар';

  @override
  String get homeItemsInventory => 'Инвентарыңыз';

  @override
  String get homeItemsGifted => 'Сізге коллекция сыйлады';

  @override
  String get homeItemsIncome => 'Коллекция кірісін алуға болады';

  @override
  String get homeShop => 'Дүкен';

  @override
  String get homeShopSubtitle => 'Эмодзи, ставкалар, коллекциялар';

  @override
  String get gamesTitle => 'Ойындар';

  @override
  String get gamesFindMatch => 'Ойын табу';

  @override
  String get gamesMyTurn => 'Сіздің жүрісіңіз';

  @override
  String get gamesWaiting => 'Күту';

  @override
  String get gamesLobbyTab => 'Лобби';

  @override
  String get gamesTicTacToe => 'Крестики-нолики';

  @override
  String get gamesDurak => 'Дурак';

  @override
  String get gamesBattleship => 'Теңіз шайқасы';

  @override
  String get gamesBattleshipRandomPlace => 'Кездейсоқ орналастыру';

  @override
  String get gamesBattleshipConfirmPlace => 'Дайын';

  @override
  String get gamesBattleshipRotate => 'Бұру';

  @override
  String get gamesBattleshipSetupPhase => 'Орналастыру';

  @override
  String get gamesBattleshipBattlePhase => 'Шайқас';

  @override
  String get gamesBattleshipWaitingOpponentSetup => 'Қарсыласты күту…';

  @override
  String get gamesBattleshipYouWon => 'Сіз жеңдіңіз!';

  @override
  String get gamesBattleshipYouLost => 'Сіз жеңілдіңіз';

  @override
  String get gamesBattleshipShipsMustNotTouch => 'Кемелер бір-біріне тиіспеуі керек';

  @override
  String get rulesBattleshipTitle => 'Теңіз шайқасы — ережелер';

  @override
  String get rulesBattleshipPlayers => 'Ойыншылар: 2.';

  @override
  String rulesBattleshipSetupTime(String time) {
    return 'Орналастыру уақыты: $time.';
  }

  @override
  String get rulesBattleshipIntro => 'Өріс 10×10. Флот: бір 4 палубалы, екі 3 палубалы, үш 2 палубалы және төрт 1 палубалы. Кемелер бір-біріне тиіспеуі керек, диагональ бойынша да.';

  @override
  String get rulesBattleshipSetup => 'Орналастыру уақыты бітсе, ағымдағы жарамды орналасу сақталады; жарамсыз болса — әдепкі орналасу қолданылады.';

  @override
  String get rulesBattleshipPlay => 'Орналастырудан кейін бірінші болып кездейсоқ ойыншы жүреді. Қарсыластың ұяшықтарына атыңыз: тию қосымша жүріс береді, өткізу жүрісті ауыстырады. Өз жүрісіңізде қарсыластың өрісі, оның жүрісінде — сіздікі көрінеді.';

  @override
  String get rulesBattleshipWin => 'Қарсы флотты толығымен батырған бірінші ойыншы жеңеді.';

  @override
  String get gamesPoker => 'Покер';

  @override
  String get gamesUno => 'Уно';

  @override
  String rulesUnoPlayers(int players) {
    return 'Ойыншылар: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'Ботқа қарсы ойын, жүріс уақыты шектелмейді.';

  @override
  String get rulesUnoIntro => 'Әркімге 7 карта үлестіріледі. Сол түсті немесе сол номиналды (сан не сол спецкарта) картамен жүріңіз.';

  @override
  String get rulesUnoPlay => 'Өткізу — келесі ойыншы жүрісін жоғалтады. Екеу болғанда бағыт ауыстыру өткізу сияқты. +2-ні тек +2-нің үстіне, +4-ті тек +4-тің үстіне қоюға болады: айыппұл қосылады (екі +2 — келесісі 4 алады). +2-ні +4-тің үстіне қоюға болмайды. Жауап бермеген бүкіл үйіндіні алып, жүрісін өткізеді.Бірдей екі жабайы емес карта (мысалы, екі сары 8) бірге тасталады: біреуін тастасаңыз, екіншісі өзі кетеді.';

  @override
  String get rulesUnoWild => 'Қара карта жаңа түс тағайындайды. +4-ті тек ағымдағы түс картасы жоқ кезде қояды. Қарсылас даулауы мүмкін: +4 заңды болса — даулаушы 6 алады; болмаса +4 авторы 4 алады, даулаушы жүреді.';

  @override
  String get rulesUnoDraw => 'Сәйкес карта жоқ болса — колодадан біреуін алыңыз. Сәйкес келсе, бірден жүруге немесе қалдырып жүрісті беруге болады. Жүріс бар кезде алуға болмайды.';

  @override
  String get rulesUnoWin => 'Екеуара 100, 3+ ойыншыда 300. Раундты барлық картасын тастаған ұтады.';

  @override
  String get rulesUnoCall => 'Бір карта қалғанда бірден «Уно!» басыңыз. Қарсыластар сізді Уносыз тек бір секундтан кейін ұстай алады — сонда 2 карта аласыз.';

  @override
  String get rulesUnoScoring => 'Карталарын бірінші тастаған раундты ұтып, қарсыластар қолынан ұпай алады: сандар — номинал, арнайылар — 20, қаралар — 50. Екеуара 100, 3+ ойыншыда 300.';

  @override
  String get unoColorRed => 'Қызыл';

  @override
  String get unoColorYellow => 'Сары';

  @override
  String get unoColorGreen => 'Жасыл';

  @override
  String get unoColorBlue => 'Көк';

  @override
  String get unoDraw => 'Алу';

  @override
  String get unoKeep => 'Қалдыру';

  @override
  String get unoSayUno => 'Уно!';

  @override
  String get unoChallengeUno => 'Уноны даулау';

  @override
  String get unoChallengeWd4 => '+4 даулау';

  @override
  String get unoChooseColor => 'Түсті таңдаңыз';

  @override
  String get unoDrawPile => 'Колода';

  @override
  String get unoDiscardPile => 'Тастау';

  @override
  String unoCardsCount(int count) {
    return 'Карталар: $count';
  }

  @override
  String unoScore(int score) {
    return 'Ұпай: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return '$round-раунд · $target дейін';
  }

  @override
  String get unoYourTurn => 'Сіздің жүрісіңіз';

  @override
  String get unoWaitingTurn => 'Қарсыластың жүрісі';

  @override
  String get unoChooseColorHint => 'Қара карта үшін түс таңдаңыз';

  @override
  String get unoWd4Hint => '4 карта алыңыз немесе Wild +4-ті даулаңыз';

  @override
  String get unoDrawnHint => 'Алынған картаны ойнаңыз немесе қалдырыңыз';

  @override
  String get unoPlayHint => 'Сәйкес түс немесе мәнді ойнаңыз';

  @override
  String get unoDrawHint => 'Сәйкес карта жоқ — колодадан алыңыз';

  @override
  String unoPendingDraw(int count) {
    return '+$count карта';
  }

  @override
  String get unoYouWon => 'Сіз матчты жеңдіңіз!';

  @override
  String get unoYouLost => 'Матч аяқталды';

  @override
  String get unoYouLostTimeout => 'Уақыт біткендіктен ұтылдыңыз';

  @override
  String unoWinner(String name) {
    return 'Жеңімпаз: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name раундты ұтады';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'Келесі';

  @override
  String get unoRoundScoresTitle => 'Раунд ұпайы';

  @override
  String get unoDirectionClockwise => 'Сағат тілімен';

  @override
  String get unoDirectionCounterclockwise => 'Сағат тіліне қарсы';

  @override
  String get unoErrStackSameOnly => '+2-ге тек +2, +4-ке тек +4 қоюға болады. +2-ні +4-тің үстіне қоюға болмайды.';

  @override
  String get unoErrCatchTooEarly => 'Бір секунд күтіңіз — олар әлі «Uno» айта алады.';

  @override
  String get unoErrCallTooLate => '«Uno» айтуға енді болмайды. Келесі ойыншы жүріп қойды.';

  @override
  String get gamesInDevelopment => 'Әзірленуде';

  @override
  String rulesPokerPlayers(int players) {
    return 'Ойыншылар: $players.';
  }

  @override
  String get rulesPokerIntro => 'Texas Hold’em. Әр ойыншыға 2 қол картасы беріледі; үстелге 5 ортақ карта шығады.';

  @override
  String get rulesPokerPlay => 'Ставка раундтары: префлоп, флоп, терн және ривер. Фолд, колл, бет немесе рейз жасауға болады.';

  @override
  String get rulesPokerWin => 'Жеңімпаз — бес картаның ең жақсы комбинациясы (қол + ортақ) немесе фолдтан кейін жалғыз қалған ойыншы.';

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
  String get rulesPokerTable => 'The table plays until one player holds all the chips. Blinds rise every two dealer orbits; 3-max lasts 10 hands, heads-up lasts six orbits.';

  @override
  String get gamesRules => 'Ережелер';

  @override
  String get gamesRulesTitle => 'Ойын ережелері';

  @override
  String get gamesCreate => 'Ойын жасау';

  @override
  String get gamesJoin => 'Қосылу';

  @override
  String get gamesOpponentTurn => 'Қарсыластың жүрісі';

  @override
  String get gamesCurrentGame => 'Ағымдағы ойын';

  @override
  String get gamesInvitedYou => 'Сізді шақырды';

  @override
  String get gamesTurnTime => 'Жүріс уақыты';

  @override
  String get gamesGridSize => 'Тор өлшемі';

  @override
  String get gamesSwapSides => 'Жақтарды ауыстыру';

  @override
  String get gamesNoCenter => 'Ортадан бастау жоқ';

  @override
  String get gamesObservation => 'Бақылау';

  @override
  String get gamesObservationHint => 'Ойын соңына дейін бақылауға болады';

  @override
  String get gamesFinishCurrentFirst => 'Алдымен ағымдағы ойынды аяқтаңыз';

  @override
  String get gamesVariantClassic => 'Классикалық';

  @override
  String get gamesVariantGomoku => 'Гомоку';

  @override
  String get gamesVariantUltimate => 'Ультимейт';

  @override
  String get gamesVariantMulti3 => '3 ойыншы';

  @override
  String get gamesVariantMulti4 => '4 ойыншы';

  @override
  String get gamesDurakModePodkidnoi => 'Тастамалы';

  @override
  String get gamesDurakModePerevodnoi => 'Аударылмалы';

  @override
  String get gamesDurakDeck24 => '24 карта';

  @override
  String get gamesDurakDeck36 => '36 карта';

  @override
  String get gamesDurakDeck52 => '52 карта';

  @override
  String rulesDurakMode(String mode) {
    return 'Режим: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'Ойыншылар: $players. Колода: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Ботқа қарсы ойын, ставка мен уақыт шектеуінсіз.';

  @override
  String get rulesDurakAttack => 'Шабуылшы карта салады, қорғаушы ұрады (сол масть жоғарырақ немесе козырь). Козырь тек жоғарырақ козырьмен ұрылады.';

  @override
  String get rulesDurakBeat => 'Барлық карта ұрылғанда шабуылшы «Бита» дейді, карталар отбойға кетеді. Әйтпесе қорғаушы үстелдегінің бәрін алады.';

  @override
  String get rulesDurakLoser => 'Жеңілген — партия соңында карталары қалған ойыншы, «дурак».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Ойыншылар $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Лобби $name';
  }

  @override
  String get lobbyMatchmake => 'Лобби';

  @override
  String get lobbyPrivateGame => 'Жеке ойын';

  @override
  String get lobbySearchingOpponent => 'Қарсылас ізделуде…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Осы ойынды іздеп жүр: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Біреу «Ойын табу» немесе «Қосылу» басқанша күтеміз';

  @override
  String get lobbyInviteTitle => 'Ойынға шақыру';

  @override
  String get lobbyInvitedToPlay => 'Сізді ойнауға шақырды';

  @override
  String get lobbyEnterGame => 'Ойынға кіру';

  @override
  String get lobbyGone => 'Лобби енді қолжетімсіз';

  @override
  String get lobbyInvite => 'Шақыру';

  @override
  String get lobbyInviteSent => 'Шақыру жіберілді';

  @override
  String get lobbyCopyLink => 'Ойын сілтемесін бөлісу';

  @override
  String get lobbyLinkCopied => 'Сілтеме көшірілді';

  @override
  String get lobbyNoFriendsOnline => 'Онлайн достар жоқ. Жоғарыдағы ойын сілтемесін бөлісіңіз немесе достарыңыз желіге шыққанша күтіңіз.';

  @override
  String get gameBot => 'Бот';

  @override
  String get gameOpponent => 'Қарсылас';

  @override
  String get gameYouWon => 'Сіз жеңдіңіз!';

  @override
  String get gameYouLost => 'Сіз жеңілдіңіз';

  @override
  String get gameYouWonOpponentLeft => 'Сіз жеңдіңіз — қарсылас шығып кетті';

  @override
  String get gameYouWonOpponentTimeout => 'Сіз жеңдіңіз — қарсыластың уақыты бітті';

  @override
  String get gameDraw => 'Тең ойын';

  @override
  String get gameExitTitle => 'Ойыннан шығу';

  @override
  String get gameExitConfirm => 'Шықсаңыз, ұтыласыз. Бәрібір шығасыз ба?';

  @override
  String get gameStay => 'Қалу';

  @override
  String get gameLeave => 'Шығу';

  @override
  String get gameSurrender => 'Берілу';

  @override
  String get gameSurrenderTitle => 'Берілу керек пе?';

  @override
  String get gameSurrenderConfirm => 'Сіз партияны және ставка тиындарын жоғалтасыз.';

  @override
  String get gameOfferDraw => 'Тең ойын ұсыну';

  @override
  String get gameOfferDrawTitle => 'Тең ойын ұсыну керек пе?';

  @override
  String get gameOfferDrawConfirm => 'Қарсылас тең ойынды қабылдай немесе бас тарта алады.';

  @override
  String get gameAcceptDrawTitle => 'Тең ойынды қабылдау керек пе?';

  @override
  String get gameAcceptDrawConfirm => 'Партия тең ойынмен аяқталады.';

  @override
  String get gameDrawOffered => 'Қарсылас тең ойын ұсынады';

  @override
  String get gameConnecting => 'Ойынға қосылуда…';

  @override
  String get gameWaitingOpponent => 'Қарсылас күтілуде';

  @override
  String get gameRematchOffer => 'Қарсылас қайта ойнауды ұсынады';

  @override
  String get gameRematchDeclined => 'Қарсылас қайта ойнаудан бас тартты';

  @override
  String get gameRematch => 'Қайта ойнау';

  @override
  String get gameOtherOpponent => 'Басқа қарсылас';

  @override
  String get gameSwapSidesAction => 'Жақтарды ауыстыру';

  @override
  String get gameWriteMessage => 'Хабарлама жазу';

  @override
  String get chatsTitle => 'Чаттар';

  @override
  String get chatsEmpty => 'Әзірге чат жоқ.\nЖоғары оң жақтағы белгішені басып, дос таңдап сөйлесуді бастаңыз.';

  @override
  String get chatsNewChat => 'Жаңа чат';

  @override
  String get chatsNoMessages => 'Хабарлама жоқ';

  @override
  String get chatsClearTitle => 'Сөйлесуді тазалау керек пе?';

  @override
  String get chatsClearDesc => 'Чат біржола жойылады.';

  @override
  String get chatsClearConfirm => 'Тазалау';

  @override
  String get chatsBlockTitle => 'Бұл пайдаланушыны бұғаттау керек пе?';

  @override
  String get chatsBlockDesc => 'Енді бір-біріңізге жаза алмайсыз. Чат пен достық жойылады.';

  @override
  String get chatsBlockConfirm => 'Бұғаттау';

  @override
  String get chatsBlockedUsers => 'Бұғатталған пайдаланушылар';

  @override
  String get chatsUnblock => 'Бұғаттан шығару';

  @override
  String get chatDialog => 'Чат';

  @override
  String get chatEmpty => 'Әзірге хабарлама жоқ.\nБіріншісін жіберіңіз.';

  @override
  String get chatMessageHint => 'Хабарлама';

  @override
  String get chatPaste => 'Қою';

  @override
  String get chatEmoji => 'Эмодзи';

  @override
  String get chatBuyEmojiHint => 'Басты экрандағы дүкеннен эмодзи сатып алыңыз';

  @override
  String get chatEditing => 'Өңдеу';

  @override
  String get chatToday => 'Бүгін';

  @override
  String get chatYesterday => 'Кеше';

  @override
  String get chatFriendsOnly => 'Мәтін тек достарға';

  @override
  String get emojiGroupEmotions => 'Эмоциялар';

  @override
  String get emojiGroupGame => 'Ойындық';

  @override
  String get emojiGroupFlags => 'Тулар';

  @override
  String get emojiGroupAnimals => 'Жануарлар';

  @override
  String get emojiGroupFood => 'Тағам';

  @override
  String get emojiGroupTravel => 'Саяхат';

  @override
  String get emojiGroupParty => 'Мереке';

  @override
  String get emojiGroupObjects => 'Заттар';

  @override
  String get friendsTitle => 'Достар';

  @override
  String get friendsTabFriends => 'Достар';

  @override
  String get friendsTabIncoming => 'Кіріс';

  @override
  String get friendsTabOutgoing => 'Шығыс';

  @override
  String get friendsAdd => 'Дос қосу';

  @override
  String get friendsRequestSent => 'Өтінім жіберілді';

  @override
  String get friendsFindTab => 'Дос табу';

  @override
  String get friendsSearchHint => 'Ник бойынша іздеу';

  @override
  String get friendsSearchPrompt => 'Жаңа достар табу үшін іздеуді пайдаланыңыз';

  @override
  String get friendsNothingFound => 'Ештеңе табылмады';

  @override
  String get friendsEmpty => 'Әзірге достарыңыз жоқ';

  @override
  String get friendsNoIncoming => 'Кіріс өтінім жоқ';

  @override
  String get friendsNoOutgoing => 'Шығыс өтінім жоқ';

  @override
  String get friendsAlreadyFriends => 'Қазірдің өзінде доссыз';

  @override
  String get friendsRemoveTitle => 'Достардан алып тастау керек пе?';

  @override
  String get friendsRemoved => 'Достардан алынды';

  @override
  String get friendsRequestAccepted => 'Өтінім қабылданды';

  @override
  String get friendsRequestDeclined => 'Өтінім қабылданбады';

  @override
  String get friendsRequestCancelled => 'Өтінімден бас тартылды';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileSignInPrompt => 'Аккаунтыңызға кіріңіз';

  @override
  String get profileSignInHint => 'Жеке профиліңізді баптау үшін';

  @override
  String get profileEdit => 'Өңдеу';

  @override
  String get profileCollections => 'Коллекциялар';

  @override
  String get profileAge => 'Жасы';

  @override
  String get profileGender => 'Жынысы';

  @override
  String get profileGenderUnset => 'Көрсетілмеген';

  @override
  String get profileGenderMale => 'Ер';

  @override
  String get profileGenderFemale => 'Әйел';

  @override
  String get profileAvatar => 'Аватар';

  @override
  String get profileUploadPhoto => 'Фото жүктеу';

  @override
  String get profileChangePhoto => 'Аватарды өзгерту';

  @override
  String get shopTitle => 'Дүкен';

  @override
  String get shopEmojis => 'Эмодзи';

  @override
  String get shopEmojisSubtitle => 'Чатқа арналған анимациялық эмодзи';

  @override
  String get shopCollections => 'Коллекциялар';

  @override
  String get shopCollectionsSubtitle => 'Профиль витринасы, сыйлықтар және кіріс';

  @override
  String get shopStakes => 'Ставкалар';

  @override
  String get shopStakesSubtitle => 'Жоғары ставкаларды ашу';

  @override
  String get inventoryTitle => 'Заттар';

  @override
  String get inventoryEmpty => 'Әзірге ештеңе жоқ — дүкенге қараңыз';

  @override
  String get inventoryFrames => 'Жақтаулар';

  @override
  String get inventoryClaim => 'Алу';

  @override
  String get inventorySell => 'Сату';

  @override
  String get inventoryGift => 'Сыйлау';

  @override
  String get messageEdited => 'өзгертілді';

  @override
  String get messageDeleted => 'Хабарлама жойылды';

  @override
  String get photo => 'Фото';

  @override
  String get camera => 'Камера';

  @override
  String get gallery => 'Галерея';

  @override
  String get connectionError => 'Серверге қосылу мүмкін болмады.';

  @override
  String get serverError => 'Сервер қатесі. Кейінірек қайталап көріңіз.';

  @override
  String get sessionExpired => 'Сессия аяқталды. Қайта кіріңіз.';

  @override
  String get errNoInternet => 'Интернет байланысы жоқ.';

  @override
  String get errTimeout => 'Күту уақыты аяқталды. Қайталап көріңіз.';

  @override
  String get errGamesUnavailable => 'Ойындар уақытша қолжетімсіз';

  @override
  String get errSettingsSaveFailed => 'Параметрді сақтау мүмкін болмады';

  @override
  String get errPushPermission => 'Браузер немесе жүйе параметрлерінде хабарландыруларға рұқсат беріңіз.';

  @override
  String get balanceTitle => 'Баланс';

  @override
  String get coinBronze => 'Қола';

  @override
  String get coinSilver => 'Күміс';

  @override
  String get coinGold => 'Алтын';

  @override
  String get coinDiamond => 'Гауһар';

  @override
  String get balanceZeroBronze => '0 қола';

  @override
  String balanceBronzes(int count) {
    return '$count қола';
  }

  @override
  String balanceSilvers(int count) {
    return '$count күміс';
  }

  @override
  String balanceGolds(int count) {
    return '$count алтын';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count гауһар';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/күн';
  }

  @override
  String get balanceAbbrBronze => 'қл';

  @override
  String get balanceAbbrSilver => 'км.';

  @override
  String get balanceAbbrGold => 'ал.';

  @override
  String get commonBackHome => 'Басты бетке оралу';

  @override
  String get commonCopied => 'Көшірілді';

  @override
  String get commonClear => 'Тазалау';

  @override
  String get commonTryLater => 'Кейінірек қайта көріңіз.';

  @override
  String get commonTryRefresh => 'Бетті жаңартып көріңіз.';

  @override
  String get coinsTitle => 'Тиындар';

  @override
  String get coinsLoginReward => 'Кіру сыйлығы';

  @override
  String get coinsLoginAvailableToday => 'Бүгінгі сыйлық қолжетімді';

  @override
  String get coinsLoginStreak => 'Күнделікті кіру сериясы';

  @override
  String get coinsFriendReward => 'Дос сыйлығы';

  @override
  String coinsFriendRewardHint(String amount) {
    return 'Сілтемеңіз арқылы тіркелу үшін +$amount';
  }

  @override
  String get coinsLoadRewardsFailed => 'Сыйлықтарды жүктеу мүмкін болмады';

  @override
  String get coinsClaimReward => 'Сыйлықты алу';

  @override
  String get coinsAlreadyClaimed => 'Алынған';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · бүгін';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · тағы 1 күн';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · тағы $remaining';
  }

  @override
  String get coinsInviteFriend => 'Досты шақыру';

  @override
  String coinsInviteHint(String amount) {
    return 'Сілтемеңіз арқылы тіркелген әркім үшін +$amount';
  }

  @override
  String get coinsCopyLink => 'Сілтемені көшіру';

  @override
  String get coinsHowItWorks => 'Қалай жұмыс істейді';

  @override
  String get coinsHowStep1 => 'Сілтемені көшіріп, досыңызға жіберіңіз';

  @override
  String get coinsHowStep2 => 'Дос сол сілтеме арқылы тіркеледі';

  @override
  String coinsHowStep3(String amount) {
    return 'Сізге $amount есептеледі';
  }

  @override
  String get achievementsTitle => 'Жетістіктер';

  @override
  String achievementsProgress(String progress) {
    return 'Прогресс: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Жақтау алынды';

  @override
  String get achievementsClaimed => 'Алынды';

  @override
  String get achievementsOpenFrame => 'Жақтауды ашу';

  @override
  String friendsRemoveConfirm(String name) {
    return '$name пайдаланушысын достардан шынымен жойғыңыз келе ме?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Алып тастау';

  @override
  String get friendsRemove => 'Достардан жою';

  @override
  String get friendsAcceptRequest => 'Өтінімді қабылдау';

  @override
  String get friendsDeclineRequest => 'Өтінімді қабылдамау';

  @override
  String get friendsCancelRequest => 'Өтінімді болдырмау';

  @override
  String get friendsSendRequest => 'Достық өтінімін жіберу';

  @override
  String get friendsRequestAlreadySent => 'Өтінім жіберілген';

  @override
  String get friendsIncomingStatus => 'Кіріс өтінім';

  @override
  String get friendsOutgoingStatus => 'Шығыс өтінім';

  @override
  String get friendsNotFriends => 'Достар емес';

  @override
  String get friendsCollapseSearch => 'Іздеуді жию';

  @override
  String get friendsExpandSearch => 'Іздеуді көрсету';

  @override
  String get friendsLoadFailed => 'Достарды жүктеу мүмкін болмады';

  @override
  String friendsSince(String date) {
    return 'Дос болған күні: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Кіріс өтінім: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Шығыс өтінім: $date';
  }

  @override
  String get userInfoTitle => 'Пайдаланушы туралы';

  @override
  String profileAgeYears(int age) {
    return '$age жас';
  }

  @override
  String get shopBuy => 'Сатып алу';

  @override
  String get shopBuyTitle => 'Сатып алу?';

  @override
  String get shopBuyStakeTitle => 'Ставканы сатып алу?';

  @override
  String get shopBuyEmojiTitle => 'Смайлды сатып алу?';

  @override
  String get shopBuyCollectionTitle => 'Коллекцияны сатып алу?';

  @override
  String shopPrice(String price) {
    return 'Бағасы: $price';
  }

  @override
  String get shopOwned => 'Сатып алынған';

  @override
  String get shopEmpty => 'Әзірге бос';

  @override
  String shopPurchased(String title) {
    return '$title сатып алынды';
  }

  @override
  String get shopEmojiUses => 'Аласыз: 10 қолдану';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 қолдану';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 қолдану';
  }

  @override
  String get shopBuyTen => 'Сатып алу · 10 дана';

  @override
  String shopDailyIncome(String amount) {
    return 'Табыс: $amount';
  }

  @override
  String get shopBuyOnce => 'Бір рет сатып алу';

  @override
  String get shopSellRefund => 'Сату құнының 80%-ін қайтарады';

  @override
  String shopCollectionAdded(String title) {
    return '$title профильге қосылды';
  }

  @override
  String shopSetBonus(int percent) {
    return 'жинақ бонусы +$percent%';
  }

  @override
  String get shopSetComplete => 'Жиналды';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Жиналды · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Сату?';

  @override
  String inventorySellDesc(String amount) {
    return 'Сіз $amount аласыз';
  }

  @override
  String inventorySold(String amount) {
    return 'Сатылды: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Алдымен достар қосыңыз';

  @override
  String get inventoryGiftTitle => 'Коллекцияны сыйлау?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return '«$title» коллекциясын $name пайдаланушысына сыйлау?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Сыйланды: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'Ойыншыда бұл зат бар';

  @override
  String get inventoryGiftSelf => 'Өзіңізге сыйлауға болмайды';

  @override
  String get inventoryGiftNotOwned => 'Бұл зат сіздің инвентарыңызда жоқ';

  @override
  String get inventoryLoadFailed => 'Заттарды жүктеу мүмкін болмады';

  @override
  String get inventoryNoCollections => 'Коллекция жоқ — дүкеннен сатып алыңыз';

  @override
  String get inventoryNoEmojis => 'Смайл жоқ — дүкеннен сатып алыңыз';

  @override
  String get inventoryNoFrames => 'Жақтау жоқ — лигада 10 ойын ұтыңыз (жетістіктер)';

  @override
  String get inventoryNoStakes => 'Сатып алынған ставкалар жоқ';

  @override
  String inventoryEmojiLeft(int count) {
    return '$count қалды';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Табыс: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Ертеңгі табыс: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Дайын';

  @override
  String get inventoryIncomeTomorrowLabel => 'Ертең';

  @override
  String inventoryStakeGold(String amount) {
    return '$amount алтын қоюға болады';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return '$amount күміс қоюға болады';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return '+$amount алынды';
  }

  @override
  String get chatsLoadFailed => 'Чаттарды жүктеу мүмкін болмады';

  @override
  String get chatsLoadListFailed => 'Тізімді жүктеу мүмкін болмады';

  @override
  String get chatsBlockedEmpty => 'Тізім бос';

  @override
  String chatsBlockedAt(String date) {
    return 'Бұғатталған: $date';
  }

  @override
  String get chatsCreateFailed => 'Чат құру мүмкін болмады';

  @override
  String get chatsNeedFriendsFirst => 'Алдымен достар қосыңыз, содан кейін чат ашуға болады.';

  @override
  String get chatsFriendsNotFound => 'Достар табылмады';

  @override
  String get chatsFindFriendHint => 'Ник бойынша дос іздеу';

  @override
  String get chatsSelectChat => 'Чатты таңдаңыз';

  @override
  String get chatsSelectHint => 'Сол жақтағы тізімнен диалогты таңдаңыз';

  @override
  String get chatEditFailed => 'Хабарламаны өзгерту мүмкін болмады';

  @override
  String get chatSendFailed => 'Хабарламаны жіберу мүмкін болмады';

  @override
  String get chatDeleteFailed => 'Хабарламаны жою мүмкін болмады';

  @override
  String get chatEmojiSendFailed => 'Смайлды жіберу мүмкін болмады';

  @override
  String get chatLoadFailed => 'Хабарламаларды жүктеу мүмкін болмады';

  @override
  String get chatBackToGame => 'Ойынға оралу';

  @override
  String get chatBackToChats => 'Чаттарға оралу';

  @override
  String get chatActions => 'Чат әрекеттері';

  @override
  String get chatAutoTranslate => 'Автоаударма';

  @override
  String get chatScrollToEnd => 'Сөйлесу соңына';

  @override
  String chatReplyingTo(String name) {
    return '$name жауабы';
  }

  @override
  String get chatGift => 'Сыйлық';

  @override
  String get chatCollection => 'Коллекция';

  @override
  String get chatGiftCollection => 'Сыйлық · коллекция';

  @override
  String get chatThisUser => 'осы пайдаланушы';

  @override
  String get gamesLobbyLoadFailed => 'Лоббиді жүктеу мүмкін болмады.';

  @override
  String get gamesTapChangeStake => 'Ставканы өзгерту үшін басыңыз';

  @override
  String get gamesTapChangeTurnTime => 'Жүріс уақытын өзгерту үшін басыңыз';

  @override
  String get gamesTapChangeGrid => 'Тор өлшемін өзгерту үшін басыңыз';

  @override
  String get gamesSwapSidesHint => 'O 1-жүрістен кейін X болуы мүмкін';

  @override
  String get gamesNoCenterHint => 'Бірінші жүріс ортаға болмайды';

  @override
  String get lobbyInviteSentShort => 'Жіберілді';

  @override
  String get lobbyInvitesSentWaiting => 'Шақырулар жіберілді. Жауап күтілуде.';

  @override
  String get lobbyLinkCopiedHint => 'Оны чатқа немесе досқа хабарламаға қойыңыз';

  @override
  String get lobbyCopyLinkHint => 'Сілтемені алмасу буферіне көшіру';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name сізді ойнауға шақырады';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name жеңді';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Уақыт бітті. $name жеңді';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds с';
  }

  @override
  String get adminTitle => 'Әкімшілік';

  @override
  String get tournamentsTitle => 'Турнирлер';

  @override
  String get profileAgeInvalid => '1-ден 111-ге дейін жасты енгізіңіз';

  @override
  String get profileSaveFailed => 'Профильді сақтау мүмкін болмады';

  @override
  String get profileNameHint => 'Латын әріптері, цифрлар, _ 10 таңбаға дейін';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => '1-ден 111-ге дейін';

  @override
  String get profileAboutHint => '100 таңбаға дейін (қалауы бойынша)';

  @override
  String get profileProcessingPhoto => 'Фото өңделуде…';

  @override
  String get profileCropTitle => 'Аватар аймағын таңдаңыз';

  @override
  String get profileCropHint => 'Фотоны масштабтаңыз және жылжытыңыз';

  @override
  String get profileApply => 'Қолдану';

  @override
  String get profilePreparing => 'Дайындалуда…';

  @override
  String get profileGalleryTitle => 'Фото';

  @override
  String get profileGalleryAdd => 'Фото қосу';

  @override
  String get profileMakePrimary => 'Негізгі ету';

  @override
  String get profilePhotoDelete => 'Фотоны жою';

  @override
  String get profilePhotosLimit => 'Ең көбі 3 фото жүктеуге болады';

  @override
  String get profilePhotosEmpty => 'Әзірге фото жоқ';

  @override
  String get profilePhotoUploadFailed => 'Фото жүктелмеді';

  @override
  String get profilePhotoDeleteFailed => 'Фото жойылмады';

  @override
  String get profilePhotoTooLarge => 'Фото тым үлкен';

  @override
  String get profileSetPrimaryFailed => 'Негізгі ету мүмкін болмады';

  @override
  String timeSecondsShort(int seconds) {
    return '$seconds с';
  }

  @override
  String get timeOneMin => '1 мин';

  @override
  String get timeTenMin => '10 мин';

  @override
  String rulesIntro(String grid) {
    return 'X-O ойыны $grid өрісінде. Кезекпен жүреді, X бастайды.';
  }

  @override
  String rulesWin(int n) {
    return 'Жеңіс: көлденең, тік немесе диагональ бойынша $n қатарға тізу керек.';
  }

  @override
  String get rulesNoTimeLimit => 'Жүріске уақыт шектеуі жоқ.';

  @override
  String rulesTurnTime(String time) {
    return 'Жүріс уақыты: $time.';
  }

  @override
  String rulesStake(String stake) {
    return 'Ставка: $stake. Ойын осы монеталарға жүреді.';
  }

  @override
  String get rulesSwap => 'Жақтарды ауыстыру: X-тің бірінші жүрісінен кейін O X-пен орын алмасуы мүмкін.';

  @override
  String get rulesNoCenter => 'Ортаға тыйым: X бірінші жүрісте ортаға жүре алмайды.';

  @override
  String get collectionSetLegends => 'Аңыздар';

  @override
  String get collectionSetSpace => 'Ғарыш';

  @override
  String get collectionSetGems => 'Асыл тастар';

  @override
  String get collectionSetParty => 'Мейрам';

  @override
  String get collectionSetNature => 'Табиғат';

  @override
  String get collectionSetAdventures => 'Шытырман оқиғалар';

  @override
  String collectionCardMeta(String amount) {
    return 'Жинақ · витрина · сыйлық · сату · +$amount';
  }

  @override
  String get coinsDayOne => 'күн';

  @override
  String get coinsDayFew => 'күн';

  @override
  String get coinsDayMany => 'күн';

  @override
  String get giftFriendTitle => 'Досыңа сыйлау';

  @override
  String photoCount(int count) {
    return 'Фото ($count)';
  }

  @override
  String photoCountWithText(int count, String text) {
    return 'Фото ($count): $text';
  }

  @override
  String photoWithText(String text) {
    return 'Фото: $text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count эмодзи · $price';
  }

  @override
  String get chatsExpandPanel => 'Панельді жазу';

  @override
  String get chatsCollapsePanel => 'Панельді жию';

  @override
  String get chatReplySourceMissing => 'Бастапқы хабар табылмады';

  @override
  String shopStakeTitleSilver(int n) {
    return '$n күміс ставкасы';
  }

  @override
  String shopStakeTitleGold(int n) {
    return '$n алтын ставкасы';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Ойындарда $n күміс қою құқығы';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Ойындарда $n алтын қою құқығы';
  }

  @override
  String get chatReplySelf => 'өзіңізге';

  @override
  String get chatReplyPeer => 'әңгімелесушіге';

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
  String get statsTitle => 'Статистика';

  @override
  String get statsLoadFailed => 'Статистиканы жүктеу мүмкін болмады';

  @override
  String get statsAllGames => 'Барлық ойындар';

  @override
  String get statsEmptyTitle => 'Әзірге ойнаған партия жоқ';

  @override
  String get statsEmptyHint => 'Статистика көрінуі үшін алғашқы ойынды ойнаңыз.';

  @override
  String get statsWins => 'Жеңістер';

  @override
  String get statsDraws => 'Тең ойындар';

  @override
  String get statsLosses => 'Жеңілістер';

  @override
  String get statsWinRate => 'Жеңіс пайызы';

  @override
  String get statsTopWon => 'Ең көп жеңген ойыншылар';

  @override
  String get statsTopDrawn => 'Ең көп тең ойындар';

  @override
  String get statsTopLost => 'Ең көп жеңілген ойыншылар';

  @override
  String get statsTimePlayed => 'Ойын уақыты';

  @override
  String get statsYourScore => 'Сіздің есебіңіз';

  @override
  String get profileShowStats => 'Статистиканы көрсету';

  @override
  String get statsDurationZeroMinutes => '0 мин';

  @override
  String get gameYouWonOpponentForfeit => 'Қарсылас берілді. Сіз жеңдіңіз!';

  @override
  String get lobbyLeaveTitle => 'Лоббиден шығу?';

  @override
  String get lobbyLeaveConfirm => 'Шыққаннан кейін лобби жойылады. Шақырылған достар бас тарту алады.';

  @override
  String get lobbyLeave => 'Шығу';

  @override
  String statsDurationHours(int hours) {
    return '$hours сағ';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours сағ $minutes мин';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'Сіз берілдіңіз. $name жеңді';
  }

  @override
  String get supportTitle => 'Қолдау';

  @override
  String get supportUnavailable => 'Қолдау қолжетімсіз';

  @override
  String get supportOpenFailed => 'Қолдау чатын ашу мүмкін болмады';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Сізге $amount тиын есептелді';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return '$amount тиын шегерілді';
  }

  @override
  String get coinsCreditCardTitle => 'Сізге тиындар есептелді';

  @override
  String get coinsClaim => 'Алу';

  @override
  String get durakActionPass => 'Пас';

  @override
  String get durakRoleTook => 'Алды';

  @override
  String get durakRoleBeats => 'Ұрады';

  @override
  String get durakRoleThrowIn => 'Тастау';

  @override
  String get durakRoleTurn => 'Жүріс';

  @override
  String get durakRoleDefends => 'Қорғанады';

  @override
  String get durakStatusTaking => 'Аламын';

  @override
  String get durakHintDefenderTurn => 'Қорғаушының жүрісі';

  @override
  String get gameYouEliminated => 'Сіз шықтыңыз';

  @override
  String gameYouPlaced(int place) {
    return 'Сіз $place-орын алдыңыз';
  }

  @override
  String get gameOverNeutral => 'Ойын аяқталды';

  @override
  String gameTurnOf(String name) {
    return '$name жүрісі';
  }

  @override
  String get chatGroupTooltip => 'Топ чаты';

  @override
  String get lobbyChatNotReady => 'Лобби чаты әлі жасалмаған';

  @override
  String get chatsGroupChat => 'Топтық чат';

  @override
  String chatsMembersCount(int count) {
    return 'Қатысушылар: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count қат.';
  }

  @override
  String get chatsYouSuffix => '(сіз)';

  @override
  String get chatTitleDurak3 => 'Дурак · 3 ойыншы';

  @override
  String get chatTitleDurak4 => 'Дурак · 4 ойыншы';

  @override
  String get rulesTttUltimate => 'Ultimate: тоғыз 3×3 мини-тақта. Жүріс қарсыласты сол мини-тақтаға жібереді. Мета-тақтадағы сызық жеңеді.';

  @override
  String get rulesTttMulti3 => '3 ойыншы: 3×3 тақта, үш ойыншы (X, O, △). Өз белгілеріңізбен сызық жинасаңыз — жеңесіз.';

  @override
  String get rulesTttMulti4 => '4 ойыншы: 4×4 тақта, төрт ойыншы (X, O, △, □). Өз белгілеріңізбен сызық жинасаңыз — жеңесіз.';
}
