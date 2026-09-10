import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Головна';

  @override
  String get navProfile => 'Профіль';

  @override
  String get navFriends => 'Друзі';

  @override
  String get navChats => 'Чати';

  @override
  String get navGames => 'Ігри';

  @override
  String get navSettings => 'Налаштування';

  @override
  String get settingsTitle => 'Налаштування';

  @override
  String get settingsLanguage => 'Мова';

  @override
  String get settingsLanguageSystem => 'Як у системі';

  @override
  String get settingsSoundTitle => 'Звук';

  @override
  String get settingsSoundSubtitle => 'Ігри та сповіщення';

  @override
  String get settingsSoundGames => 'Ігри';

  @override
  String get settingsSoundNotifications => 'Сповіщення';

  @override
  String get settingsSoundTurn => 'Хід';

  @override
  String get settingsHapticsTitle => 'Вібрація';

  @override
  String get settingsHapticsSubtitle => 'Лише сповіщення: повідомлення, заявки, ваш хід і таймер';

  @override
  String get settingsGamepadTitle => 'Контролер';

  @override
  String get settingsGamepadSubtitle => 'Геймпад для меню і партій';

  @override
  String settingsGamepadConnected(String name) {
    return 'Підключено: $name';
  }

  @override
  String get settingsGamepadDisconnected => 'Геймпад не знайдено. Підключіть контролер і натисніть будь-яку кнопку.';

  @override
  String get settingsGamepadHelpNavigate => 'Хрест / стік — меню і курсор на полі';

  @override
  String get settingsGamepadHelpConfirm => 'A / Хрест — вибрати або сходити';

  @override
  String get settingsGamepadHelpBack => 'B / Коло — назад або зняти вибір';

  @override
  String get settingsGamepadHelpTabs => 'L1 / R1 — вкладки меню';

  @override
  String get settingsGamepadHelpPlay => 'Курсор на полі та в руці: шашки, хрестики-нулики, морський бій, дурень, уно, покер і нарди';

  @override
  String get settingsGamepadHelpCards => 'У картах: хрест — рука, A — хід, X — вибрати / Уно, Y — взяти, бито або добрати';

  @override
  String get settingsGamepadHelpKeyboard => 'У полі вводу A відкриває клавіатуру геймпада; X — розкладка, B — стерти або закрити';

  @override
  String get gamepadKeyboardTitle => 'Клавіатура';

  @override
  String get gamepadKeyboardSpace => 'Пробіл';

  @override
  String get gamepadLegendConfirm => 'Вибрати';

  @override
  String get gamepadLegendBack => 'Назад';

  @override
  String get gamepadLegendTabs => 'Вкладки';

  @override
  String get gamepadLegendCycle => 'Змінити';

  @override
  String gamepadConnectedSnack(String name) {
    return 'Контролер підключено: $name';
  }

  @override
  String get settingsOfflineModeTitle => 'Режим мережі';

  @override
  String get settingsOfflineModeSubtitle => 'Офлайн: гра з ботом одразу, без ставок і нагород, без чатів і друзів. Покупки зберігаються і застосовуються в режимі онлайн. Онлайн — коли є інтернет або за налаштуванням користувача.';

  @override
  String get settingsModeOnline => 'Онлайн';

  @override
  String get settingsModeOffline => 'Офлайн';

  @override
  String get gamesAlternateStartsHint => 'По черзі хто починає партію';

  @override
  String get rulesAlternateStarts => 'Хто ходить першим чергується від партії до партії.';

  @override
  String get offlineBadgeTooltip => 'Офлайн режим';

  @override
  String get offlineModePopupTitle => 'Офлайн режим';

  @override
  String get offlineModePopupBody => 'Увімкнено офлайн режим. Грайте з ботом без ставок і нагород. Чати, друзі та лобі приховані. Покупки застосуються в режимі онлайн.';

  @override
  String get offlineModePopupSettings => 'Налаштування';

  @override
  String get offlineModeOfferBody => 'Немає інтернету або зв’язок дуже слабкий. Можна увімкнути офлайн режим і грати з ботом.';

  @override
  String get offlineModeOfferAction => 'Увімкнути офлайн';

  @override
  String get gamesPlay => 'Грати';

  @override
  String get offlineGameTitle => 'Гра з ботом';

  @override
  String get offlineGameHint => 'Без ставок і нагород · лише офлайн';

  @override
  String get offlineBotWon => 'Бот переміг';

  @override
  String get offlineBotThinking => 'Хід бота…';

  @override
  String get offlinePlayAgain => 'Ще раз';

  @override
  String offlineBotName(int n) {
    return 'Бот $n';
  }

  @override
  String get durakActionTake => 'Взяти';

  @override
  String get durakActionAll => 'Усі';

  @override
  String get durakActionDone => 'Готово';

  @override
  String get durakActionBito => 'Бито';

  @override
  String get durakHintDefend => 'Відбивайтеся';

  @override
  String get durakHintDefendOrTransfer => 'Відбивайтеся або переведіть';

  @override
  String get durakHintOpponentDefends => 'Суперник відбивається';

  @override
  String get durakHintThrowInFirst => 'Підкиньте карти (макс. 5 у першому відбої)';

  @override
  String get durakHintThrowIn => 'Підкиньте карти або чекайте відбою';

  @override
  String get durakHintOpponentThrows => 'Суперник підкидає';

  @override
  String get durakHintTakeFollow => 'Підкиньте вдогонку або натисніть «Готово»';

  @override
  String get durakHintOpponentTakeFollow => 'Суперник може підкинути вдогонку';

  @override
  String get durakHintBito => 'Підкиньте карту або скажіть «Бито»';

  @override
  String get durakHintOpponentBito => 'Суперник підкидає або каже «Бито»';

  @override
  String get durakHintYourAttack => 'Ваш хід — атакуйте';

  @override
  String get durakHintOpponentAttack => 'Атакує суперник';

  @override
  String get durakHintYouLost => 'Ви програли — ви дурак';

  @override
  String get durakHintDrawAllOut => 'Нічия — усі вийшли';

  @override
  String get durakHintYouFinished => 'Ви вийшли — чекаємо кінця партії';

  @override
  String get durakFirstLeadYou => 'Ви ходите';

  @override
  String get durakFirstLeadOpponent => 'Суперник ходить';

  @override
  String get durakFirstLeadBot => 'Бот ходить';

  @override
  String durakFirstLeadOf(String name) {
    return 'Ходить $name';
  }

  @override
  String get durakFirstLeadReason => 'Молодший козир';

  @override
  String get shopPurchaseQueued => 'Покупку збережено — застосується в режимі онлайн';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — покупку застосовано';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — покупку не застосовано: $reason';
  }

  @override
  String get settingsFriendsOnlyTitle => 'Повідомлення лише від друзів';

  @override
  String get settingsFriendsOnlySubtitle => 'Хто не в друзях, зможе надсилати лише емодзі. Якщо заважає спам — тимчасово заблокуйте користувача.';

  @override
  String get settingsNotifications => 'Сповіщення';

  @override
  String get settingsPushChat => 'Чат';

  @override
  String get settingsPushFriends => 'Друзі';

  @override
  String get settingsPushGames => 'Ігри';

  @override
  String get settingsPushRewards => 'Нагороди';

  @override
  String settingsAppVersion(String version) {
    return 'Версія $version';
  }

  @override
  String get appUpdateTitle => 'Доступне оновлення';

  @override
  String get appUpdateBody => 'Вийшла нова версія застосунку. Оновіться, щоб продовжити.';

  @override
  String get appUpdateWhatsNew => 'Що нового';

  @override
  String get appUpdateOk => 'Оновити';

  @override
  String get appUpdateLaterBanner => 'Після партії оновимо застосунок';

  @override
  String get loginTitle => 'Вхід';

  @override
  String get loginSubtitle => 'Введіть email або логін і пароль';

  @override
  String get loginEmailLabel => 'Email або логін';

  @override
  String get loginPasswordLabel => 'Пароль';

  @override
  String get loginSubmit => 'Увійти';

  @override
  String get loginNoAccount => 'Немає акаунта? Зареєструватися';

  @override
  String get loginEmailRequired => 'Введіть email або логін';

  @override
  String get loginPasswordRequired => 'Введіть пароль';

  @override
  String get loginTooltip => 'Увійти';

  @override
  String get logoutTooltip => 'Вийти';

  @override
  String get registerTitle => 'Реєстрація';

  @override
  String get registerSubtitle => 'Створіть акаунт, щоб грати';

  @override
  String get registerNameLabel => 'Ім’я (логін)';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'Пароль';

  @override
  String get registerSubmit => 'Зареєструватися';

  @override
  String get registerHaveAccount => 'Уже є акаунт? Увійти';

  @override
  String get registerNameRequired => 'Введіть ім’я';

  @override
  String get registerNameNoSpaces => 'Ім’я не може містити пробілів';

  @override
  String get registerNameMax => 'Максимум 20 символів';

  @override
  String get registerNameHint => 'До 20 символів';

  @override
  String get registerEmailRequired => 'Введіть email';

  @override
  String get registerEmailInvalid => 'Некоректний email';

  @override
  String get registerPasswordHint => 'Мінімум 6 символів';

  @override
  String get registerPasswordMin => 'Пароль має містити щонайменше 6 символів';

  @override
  String get commonCancel => 'Скасувати';

  @override
  String get commonSave => 'Зберегти';

  @override
  String get commonDelete => 'Видалити';

  @override
  String get commonEdit => 'Змінити';

  @override
  String get commonReply => 'Відповісти';

  @override
  String get commonSend => 'Надіслати';

  @override
  String get commonClose => 'Закрити';

  @override
  String get commonRetry => 'Повторити';

  @override
  String get commonLoading => 'Завантаження…';

  @override
  String get commonError => 'Помилка';

  @override
  String get commonOnline => 'у мережі';

  @override
  String get commonOffline => 'не в мережі';

  @override
  String get commonOnlineCap => 'Онлайн';

  @override
  String get commonUser => 'Користувач';

  @override
  String get commonPlayer => 'Гравець';

  @override
  String get commonAboutMe => 'Про себе';

  @override
  String get commonBack => 'Назад';

  @override
  String get commonAccept => 'Прийняти';

  @override
  String get commonDecline => 'Відхилити';

  @override
  String get commonCreating => 'Створення…';

  @override
  String get commonSearching => 'Пошук…';

  @override
  String get commonInsufficientCoins => 'Недостатньо монет';

  @override
  String get commonNotFound => 'Не знайдено';

  @override
  String get commonServerErrorShort => 'Помилка сервера';

  @override
  String get commonForbidden => 'Доступ заборонено';

  @override
  String get commonUserBlocked => 'Користувача заблоковано';

  @override
  String get commonUserNotFound => 'Користувача не знайдено';

  @override
  String get commonGenericError => 'Щось пішло не так. Спробуйте ще раз.';

  @override
  String get apiErrWrongGameType => 'Невірний тип гри';

  @override
  String get apiErrWrongGameTypeOrState => 'Невірний тип або стан гри';

  @override
  String get apiErrLobbyFull => 'Лобі заповнене';

  @override
  String get apiErrBadState => 'Помилка стану гри';

  @override
  String get apiErrIllegalMove => 'Такий хід не можна зробити';

  @override
  String get apiErrUnknownMoveType => 'Невідомий тип ходу';

  @override
  String get apiErrNoOpponents => 'Немає суперників';

  @override
  String get apiErrNoOpponentsRematch => 'Немає суперників для реваншу';

  @override
  String get apiErrAlreadyInLobby => 'Ви вже в цьому лобі';

  @override
  String get apiErrGameNotActive => 'Гра не активна';

  @override
  String get apiErrNotInBattle => 'Зараз не фаза бою';

  @override
  String get apiErrNotInSetup => 'Зараз не фаза розстановки';

  @override
  String get apiErrAlreadyReady => 'Ви вже готові';

  @override
  String get apiErrAlreadyForfeited => 'Ви вже здалися';

  @override
  String get apiErrYouHaveForfeited => 'Ви здалися';

  @override
  String get apiErrNoDrawOffer => 'Немає пропозиції нічиєї';

  @override
  String get apiErrDrawOnlyPvp => 'Нічия лише проти гравця';

  @override
  String get apiErrDrawOnly1v1 => 'Нічия лише в грі 1 на 1';

  @override
  String get apiErrDrawVsBot => 'Нічия недоступна проти бота';

  @override
  String get apiErrDrawMultiplayer => 'Нічия недоступна в грі на кількох';

  @override
  String get apiErrDeck24TwoPlayers => 'Колода 24 лише для двох';

  @override
  String get apiErrDeck52ThreeOrFour => 'Колода 52 лише для 3 або 4 гравців';

  @override
  String get apiErrAccountFrozen => 'Акаунт заморожено';

  @override
  String get apiErrTurnTimeInvalid => 'Час на хід має бути 0, 20, 60 або 600 секунд';

  @override
  String get timeJustNow => 'щойно';

  @override
  String get timeYesterday => 'вчора';

  @override
  String timeMinutesAgo(int count) {
    return '$count хв тому';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count год тому';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count дн. тому';
  }

  @override
  String get timeWeekAgo => 'тиждень тому';

  @override
  String timeWeeksAgo(int count) {
    return '$count тиж. тому';
  }

  @override
  String get timeMonthAgo => 'місяць тому';

  @override
  String timeMonthsAgo(int count) {
    return '$count міс. тому';
  }

  @override
  String get timeYearAgo => 'рік тому';

  @override
  String timeYearsAgo(int count) {
    return '$count р. тому';
  }

  @override
  String get weekdaySun => 'нд';

  @override
  String get weekdayMon => 'пн';

  @override
  String get weekdayTue => 'вт';

  @override
  String get weekdayWed => 'ср';

  @override
  String get weekdayThu => 'чт';

  @override
  String get weekdayFri => 'пт';

  @override
  String get weekdaySat => 'сб';

  @override
  String get monthJan => 'січ';

  @override
  String get monthFeb => 'лют';

  @override
  String get monthMar => 'бер';

  @override
  String get monthApr => 'кві';

  @override
  String get monthMay => 'тра';

  @override
  String get monthJun => 'чер';

  @override
  String get monthJul => 'лип';

  @override
  String get monthAug => 'сер';

  @override
  String get monthSep => 'вер';

  @override
  String get monthOct => 'жов';

  @override
  String get monthNov => 'лис';

  @override
  String get monthDec => 'гру';

  @override
  String get homeAchievements => 'Досягнення';

  @override
  String get homeAchievementsSubtitle => 'Ваші ігрові результати';

  @override
  String get homeAchievementsRewards => 'Є нагороди для отримання';

  @override
  String get homeCoins => 'Монети';

  @override
  String get homeCoinsSubtitle => 'Баланс і нагороди';

  @override
  String get homeCoinsDailyReward => 'Доступна нагорода за вхід';

  @override
  String get homeItems => 'Предмети';

  @override
  String get homeItemsInventory => 'Ваш інвентар';

  @override
  String get homeItemsGifted => 'Вам подарували колекцію';

  @override
  String get homeItemsIncome => 'Можна забрати дохід з колекцій';

  @override
  String get homeShop => 'Магазин';

  @override
  String get homeShopSubtitle => 'Емодзі, ставки, колекції';

  @override
  String get gamesTitle => 'Ігри';

  @override
  String get gamesFindMatch => 'Знайти гру';

  @override
  String get gamesMyTurn => 'Ваш хід';

  @override
  String get gamesWaiting => 'Очікування';

  @override
  String get gamesLobbyTab => 'Лобі';

  @override
  String get gamesTicTacToe => 'Хрестики-нулики';

  @override
  String get gamesDurak => 'Дурак';

  @override
  String get gamesBattleship => 'Морський бій';

  @override
  String get gamesBattleshipRandomPlace => 'Розставити випадково';

  @override
  String get gamesBattleshipConfirmPlace => 'Готово';

  @override
  String get gamesBattleshipRotate => 'Повернути';

  @override
  String get gamesBattleshipSetupPhase => 'Розстановка';

  @override
  String get gamesBattleshipBattlePhase => 'Бій';

  @override
  String get gamesBattleshipWaitingOpponentSetup => 'Очікування суперника…';

  @override
  String get gamesBattleshipYouWon => 'Ви перемогли!';

  @override
  String get gamesBattleshipYouLost => 'Ви програли';

  @override
  String get gamesBattleshipShipsMustNotTouch => 'Кораблі не повинні торкатися';

  @override
  String get rulesBattleshipTitle => 'Морський бій — правила';

  @override
  String get rulesBattleshipPlayers => 'Гравці: 2.';

  @override
  String rulesBattleshipSetupTime(String time) {
    return 'Час на розстановку: $time.';
  }

  @override
  String get rulesBattleshipIntro => 'Поле 10×10. Флот: один чотирипалубний, два трипалубних, три двопалубних і чотири однопалубних. Кораблі не можна ставити впритул, зокрема по діагоналі.';

  @override
  String get rulesBattleshipSetup => 'Якщо час на розстановку вийшов, лишається поточна валідна розстановка; якщо вона невалідна — використовується стандартна.';

  @override
  String get rulesBattleshipPlay => 'Після розстановки першим ходить випадковий гравець. Стріляйте по клітинках суперника: влучання дає ще один хід, промах передає хід. На своєму ході видно поле суперника, на його — ваше.';

  @override
  String get rulesBattleshipWin => 'Перемагає той, хто першим потопить увесь флот противника.';

  @override
  String get gamesPoker => 'Покер';

  @override
  String get gamesUno => 'Уно';

  @override
  String get gamesNardy => 'Нарди';

  @override
  String get gamesNardyModeShort => 'Короткі';

  @override
  String get gamesNardyModeLong => 'Довгі';

  @override
  String get gamesCheckers => 'Шашки';

  @override
  String get gamesCheckersModeRussian => 'Російські';

  @override
  String get gamesCheckersModeEnglish => 'Англійські';

  @override
  String get gamesCheckersModeGiveaway => 'Піддавки';

  @override
  String get gamesCheckersModeCorners => 'Кутки';

  @override
  String get rulesCheckersPlayers => 'Гравці: 2.';

  @override
  String rulesCheckersMode(String mode) {
    return 'Режим: $mode.';
  }

  @override
  String rulesCheckersTime(String time) {
    return 'Время на ход: $time. Если время вышло — проигрыш.';
  }

  @override
  String get rulesCheckersIntro => 'Дошка 8×8. Грають двоє.';

  @override
  String get rulesCheckersPlay => 'Бій обов’язковий. Дамка і проста зобов’язані продовжувати бій, поки з клітини приземлення можна бити далі — зупинитися посередині не можна. Якщо напрямків кілька, можна обрати будь-який, не обов’язково найдовший. Проста, що дійшла до останньої лінії, стає дамкою.';

  @override
  String get rulesCheckersWin => 'В русских шашках побеждает тот, кто съел все шашки соперника или лишил его хода. В поддавках наоборот: кто не может ходить — выигрывает.';

  @override
  String get rulesCheckersOfflineBot => 'Офлайн: партия против бота.';

  @override
  String get rulesCheckersPlayRussian => 'Російські шашки: у кожного 12 шашок на темних клітинах. Прості ходять по діагоналі вперед, а б’ють уперед і назад. Дамка літає на будь-яке число клітин. Бій обов’язковий: не можна зупинитися, якщо взяття можна продовжити, але якщо напрямків кілька — обираєте будь-який, не обов’язково найдовший. Перемагає той, хто з’їв усі шашки суперника або позбавив його ходів.';

  @override
  String get rulesCheckersPlayEnglish => 'Англійські шашки: у кожного 12 шашок. Прості ходять і б’ють лише вперед по діагоналі. Дамка ходить на одну клітину в будь-який бік по діагоналі. Бій обов’язковий. Перемагає той, хто з’їв усі шашки суперника або позбавив його ходів.';

  @override
  String get rulesCheckersPlayGiveaway => 'Піддавки: ті самі ходи, що в російських шашках, але мета зворотна — віддати всі свої шашки або залишитися без ходу. Бій усе одно обов’язковий.';

  @override
  String get rulesCheckersPlayCorners => 'Кутки: шашки стоять у протилежних кутах. Ходять на сусідню вільну клітину по горизонталі чи вертикалі або перестрибують через будь-яку шашку, не знімаючи її. Мета — перевести всі свої шашки в кут суперника.';

  @override
  String get rulesCheckersPlayCornersNoReturn => 'Фішка, яка вже залишила свій стартовий кут, не може повернутися до нього.';

  @override
  String get rulesCheckersPlayCornersLeaveHome => 'Фішки, які ще не вийшли з дому, мають залишити його за перші 25 ходів гравця.';

  @override
  String get rulesNardyTitle => 'Нарди — правила';

  @override
  String get rulesNardyPlayers => 'Гравці: 2.';

  @override
  String rulesNardyMode(String mode) {
    return 'Режим: $mode.';
  }

  @override
  String get rulesNardyIntro => 'Дошка з 24 пунктів, у кожного по 15 шашок. Ходи за двома кубиками: можна сходити однією шашкою на суму або двома на очки кубиків.';

  @override
  String get rulesNardyPlayShort => 'Короткі нарди: гравці йдуть назустріч і можуть бити одиночні шашки суперника. Збита стає на бар і має увійти знову. Коли всі шашки в домі — знімаєте їх з дошки.';

  @override
  String get rulesNardyPlayLong => 'Довгі нарди: обидва починають з однієї голови й ідуть в один бік. З голови за хід виходить не більше однієї шашки. Бити шашки не можна. Коли всі в домі — знімаєте їх з дошки.';

  @override
  String get rulesNardyWin => 'Перемагає той, хто першим зніме всі свої шашки.';

  @override
  String get rulesNardySixPrime => 'Шість своїх пунктів поспіль замикати не можна, доки їх не обійшла жодна шашка суперника.';

  @override
  String get nardyRoll => 'Кинути';

  @override
  String get nardySkipTurn => 'Пропустити хід';

  @override
  String get nardyUndoMove => 'Повернути';

  @override
  String get nardyDoneTurn => 'Готово';

  @override
  String get nardyAutoConfirm => 'Автопідтвердження';

  @override
  String get nardyAutoConfirmHint => 'Після всіх ходів хід одразу перейде супернику';

  @override
  String get nardyNoMoves => 'Ходів немає';

  @override
  String get nardyYourRoll => 'Ваш кидок';

  @override
  String get nardyPipsShort => 'Залишилось:';

  @override
  String get nardyYouWonMars => 'Ви виграли — марс!';

  @override
  String get nardyYouLostMars => 'Поразка — марс';

  @override
  String get rulesNardyOfflineBot => 'Офлайн: партія проти бота.';

  @override
  String rulesUnoPlayers(int players) {
    return 'Гравці: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'Гра проти бота, без ліміту часу на хід.';

  @override
  String get rulesUnoIntro => 'Кожному роздають по 7 карт. Ходіть картою того самого кольору або того самого номіналу (цифра чи такий самий спецефект).';

  @override
  String get rulesUnoPlay => 'Пропуск — наступний втрачає хід. Зміна напрямку вдвох працює як пропуск. +2 можна класти лише на +2, +4 — лише на +4: штраф сумується (дві +2 — наступний бере 4). +2 на +4 класти не можна. Хто не відповідає, бере всю стопку і пропускає хід. Дві однакові недикі карти (наприклад, дві жовті 8) скидаються разом: досить кинути одну — друга йде автоматично.';

  @override
  String get rulesUnoWild => 'Чорна карта задає новий колір. +4 кладуть лише якщо немає карти поточного кольору. Суперник може оскаржити: якщо +4 був законним — оскаржувач бере 6, якщо ні — автор +4 бере 4, а оскаржувач ходить.';

  @override
  String get rulesUnoDraw => 'Якщо немає підхожої карти — візьміть одну з колоди. Якщо вона підходить, можна одразу зіграти нею або залишити й передати хід. Поки є хід, брати не можна.';

  @override
  String get rulesUnoWin => 'Удвох матч до 100 очок, за трьох і більше гравців — до 200. Раунд виграє гравець, який скинув усі карти.';

  @override
  String get rulesUnoCall => 'Коли лишається одна карта, одразу натисніть «Уно!». Суперники можуть зловити вас без «Уно» лише за секунду — тоді ви берете 2 карти.';

  @override
  String get rulesUnoScoring => 'Хто першим скинув усі карти, виграє раунд і отримує очки за руки суперників: цифри — за номіналом, спецкарти — 20, чорні — 50. Удвох матч до 100, за трьох і більше гравців — до 200.';

  @override
  String get unoColorRed => 'Червоний';

  @override
  String get unoColorYellow => 'Жовтий';

  @override
  String get unoColorGreen => 'Зелений';

  @override
  String get unoColorBlue => 'Синій';

  @override
  String get unoDraw => 'Взяти';

  @override
  String get unoKeep => 'Залишити';

  @override
  String get unoSayUno => 'Уно!';

  @override
  String get unoChallengeUno => 'Спіймати без Уно';

  @override
  String get unoChallengeWd4 => 'Оскаржити +4';

  @override
  String get unoChooseColor => 'Виберіть колір';

  @override
  String get unoDrawPile => 'Колода';

  @override
  String get unoDiscardPile => 'Скид';

  @override
  String unoCardsCount(int count) {
    return 'Карт: $count';
  }

  @override
  String unoScore(int score) {
    return 'Очки: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'Раунд $round · до $target';
  }

  @override
  String get unoYourTurn => 'Ваш хід';

  @override
  String get unoWaitingTurn => 'Хід суперника';

  @override
  String get unoChooseColorHint => 'Виберіть колір для чорної карти';

  @override
  String get unoWd4Hint => 'Візьміть 4 карти або оскаржте Wild +4';

  @override
  String get unoDrawnHint => 'Зіграйте взяту карту або залиште її';

  @override
  String get unoPlayHint => 'Зіграйте карту відповідного кольору чи значення';

  @override
  String get unoDrawHint => 'Немає відповідної карти — візьміть із колоди';

  @override
  String unoPendingDraw(int count) {
    return '+$count карт';
  }

  @override
  String get unoYouWon => 'Ви виграли матч!';

  @override
  String get unoYouLost => 'Матч завершено';

  @override
  String get unoYouLostTimeout => 'Ви програли за часом';

  @override
  String unoWinner(String name) {
    return 'Переможець: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name виграє раунд';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'Далі';

  @override
  String get unoRoundScoresTitle => 'Очки за раунд';

  @override
  String get unoDirectionClockwise => 'За годинниковою стрілкою';

  @override
  String get unoDirectionCounterclockwise => 'Проти годинникової стрілки';

  @override
  String get unoErrStackSameOnly => 'На +2 можна відповісти лише +2, на +4 — лише +4. +2 на +4 класти не можна.';

  @override
  String get unoErrCatchTooEarly => 'Зачекайте секунду — вони ще можуть сказати «Уно».';

  @override
  String get unoErrCallTooLate => 'Сказати «Уно» вже не можна: наступний гравець уже сходив.';

  @override
  String get gamesInDevelopment => 'В розробці';

  @override
  String rulesPokerPlayers(int players) {
    return 'Гравці: $players.';
  }

  @override
  String get rulesPokerIntro => 'Техаський холдем. Кожному роздають 2 карти в руку; на стіл виходять 5 спільних карт.';

  @override
  String get rulesPokerPlay => 'Раунди ставок: префлоп, флоп, терн і рівер. Можна фолд, колл, бет або рейз.';

  @override
  String get rulesPokerWin => 'Перемагає найкраща комбінація з п’яти карт (свої + спільні) або той, хто лишився один після фолдів.';

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
  String get pokerCombinationsTitle => 'Комбінації';

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
  String get gamesRules => 'Правила';

  @override
  String get gamesRulesTitle => 'Правила гри';

  @override
  String get gamesCreate => 'Створити гру';

  @override
  String get gamesJoin => 'Приєднатися';

  @override
  String get gamesOpponentTurn => 'Хід суперника';

  @override
  String get gamesCurrentGame => 'Поточна гра';

  @override
  String get gamesInvitedYou => 'Вас запросили';

  @override
  String get gamesTurnTime => 'Час на хід';

  @override
  String get gamesGridSize => 'Розмір сітки';

  @override
  String get gamesSwapSides => 'Зміна сторін';

  @override
  String get gamesNoCenter => 'Без старту в центрі';

  @override
  String get gamesObservation => 'Спостереження';

  @override
  String get gamesObservationHint => 'Можна дивитися до кінця партії';

  @override
  String get gamesFinishCurrentFirst => 'Спочатку завершіть поточну гру';

  @override
  String get gamesVariantClassic => 'Класика';

  @override
  String get gamesVariantGomoku => 'Гомоку';

  @override
  String get gamesVariantUltimate => 'Ультимейт';

  @override
  String get gamesVariantMulti3 => 'На трьох';

  @override
  String get gamesVariantMulti4 => 'На чотирьох';

  @override
  String get gamesDurakModePodkidnoi => 'Підкидний';

  @override
  String get gamesDurakModePerevodnoi => 'Переводний';

  @override
  String get gamesDurakDeck24 => '24 карти';

  @override
  String get gamesDurakDeck36 => '36 карт';

  @override
  String get gamesDurakDeck52 => '52 карти';

  @override
  String rulesDurakMode(String mode) {
    return 'Режим: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'Гравці: $players. Колода: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Гра проти бота, без ставок і ліміту часу.';

  @override
  String get rulesDurakAttack => 'Атакувальник кладе карти, захисник б\'є (тієї ж масті старшою або козирем). Козир б\'ється лише старшим козирем.';

  @override
  String get rulesDurakBeat => 'Коли всі карти биті — атакувальник каже «Бито», карти йдуть у відбій. Інакше захисник бере все зі столу.';

  @override
  String get rulesDurakLoser => 'Програє той, у кого в кінці лишилися карти, — «дурак».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Гравці $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Лобі $name';
  }

  @override
  String get lobbyMatchmake => 'Лобі';

  @override
  String get lobbyPrivateGame => 'Приватна гра';

  @override
  String get lobbySearchingOpponent => 'Пошук суперника…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Шукають цю гру: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Чекаємо, поки хтось натисне «Знайти гру» або «Приєднатися»';

  @override
  String get lobbyInviteTitle => 'Запрошення в гру';

  @override
  String get lobbyInvitedToPlay => 'Вас запросили зіграти';

  @override
  String get lobbyEnterGame => 'Увійти в гру';

  @override
  String get lobbyGone => 'Лобі більше недоступне';

  @override
  String get lobbyInvite => 'Запросити';

  @override
  String get lobbyInviteSent => 'Запрошення надіслано';

  @override
  String get lobbyCopyLink => 'Поділитися посиланням на гру';

  @override
  String get lobbyLinkCopied => 'Посилання скопійовано';

  @override
  String get lobbyNoFriendsOnline => 'Немає друзів онлайн. Надішліть посилання на гру вище або зачекайте, поки друзі з’являться в мережі.';

  @override
  String get gameBot => 'Бот';

  @override
  String get gameOpponent => 'Суперник';

  @override
  String get gameYouWon => 'Ви перемогли!';

  @override
  String get gameYouLost => 'Ви програли';

  @override
  String get gameYouWonOpponentLeft => 'Ви перемогли — суперник вийшов';

  @override
  String get gameYouWonOpponentTimeout => 'Ви перемогли — у суперника вийшов час';

  @override
  String get gameDraw => 'Нічия';

  @override
  String get gameExitTitle => 'Вихід з гри';

  @override
  String get gameExitConfirm => 'Якщо вийдете, програєте. Вийти все одно?';

  @override
  String get gameStay => 'Залишитися';

  @override
  String get gameLeave => 'Вийти';

  @override
  String get gameSurrender => 'Здатися';

  @override
  String get gameSurrenderTitle => 'Здатися?';

  @override
  String get gameSurrenderConfirm => 'Ви програєте партію і монети ставки.';

  @override
  String get gameOfferDraw => 'Запропонувати нічию';

  @override
  String get gameOfferDrawTitle => 'Запропонувати нічию?';

  @override
  String get gameOfferDrawConfirm => 'Суперник може прийняти або відхилити нічию.';

  @override
  String get gameAcceptDrawTitle => 'Прийняти нічию?';

  @override
  String get gameAcceptDrawConfirm => 'Партія завершиться нічиєю.';

  @override
  String get gameDrawOffered => 'Суперник пропонує нічию';

  @override
  String get gameConnecting => 'Підключення до гри…';

  @override
  String get gameWaitingOpponent => 'Очікування суперника';

  @override
  String get gameRematchOffer => 'Суперник пропонує реванш';

  @override
  String get gameRematchDeclined => 'Суперник відхилив реванш';

  @override
  String get gameRematch => 'Реванш';

  @override
  String get gameOtherOpponent => 'Інший суперник';

  @override
  String get gameSwapSidesAction => 'Змінити сторони';

  @override
  String get gameWriteMessage => 'Написати повідомлення';

  @override
  String get chatsTitle => 'Чати';

  @override
  String get chatsEmpty => 'Поки немає чатів.\nНатисніть іконку справа зверху, щоб обрати друга й почати розмову.';

  @override
  String get chatsNewChat => 'Новий чат';

  @override
  String get chatsNoMessages => 'Немає повідомлень';

  @override
  String get chatsClearTitle => 'Очистити переписку?';

  @override
  String get chatsClearDesc => 'Чат буде видалено назавжди.';

  @override
  String get chatsClearConfirm => 'Очистити';

  @override
  String get chatsBlockTitle => 'Заблокувати цього користувача?';

  @override
  String get chatsBlockDesc => 'Ви більше не зможете писати одне одному. Чат і дружбу буде видалено.';

  @override
  String get chatsBlockConfirm => 'Заблокувати';

  @override
  String get chatsBlockedUsers => 'Заблоковані користувачі';

  @override
  String get chatsUnblock => 'Розблокувати';

  @override
  String get chatDialog => 'Чат';

  @override
  String get chatEmpty => 'Повідомлень поки немає.\nНадішліть перше.';

  @override
  String get chatMessageHint => 'Повідомлення';

  @override
  String get chatPaste => 'Вставити';

  @override
  String get chatEmoji => 'Емодзі';

  @override
  String get chatBuyEmojiHint => 'Купуйте емодзі в магазині на головному екрані';

  @override
  String get chatEditing => 'Редагування';

  @override
  String get chatToday => 'Сьогодні';

  @override
  String get chatYesterday => 'Вчора';

  @override
  String get chatFriendsOnly => 'Текст лише для друзів';

  @override
  String get emojiGroupEmotions => 'Емоції';

  @override
  String get emojiGroupGame => 'Ігрові';

  @override
  String get emojiGroupFlags => 'Прапори';

  @override
  String get emojiGroupAnimals => 'Тварини';

  @override
  String get emojiGroupFood => 'Їжа';

  @override
  String get emojiGroupTravel => 'Подорожі';

  @override
  String get emojiGroupParty => 'Свято';

  @override
  String get emojiGroupObjects => 'Предмети';

  @override
  String get friendsTitle => 'Друзі';

  @override
  String get friendsTabFriends => 'Друзі';

  @override
  String get friendsTabIncoming => 'Вхідні';

  @override
  String get friendsTabOutgoing => 'Вихідні';

  @override
  String get friendsAdd => 'Додати в друзі';

  @override
  String get friendsRequestSent => 'Запит надіслано';

  @override
  String get friendsFindTab => 'Знайти друга';

  @override
  String get friendsSearchHint => 'Пошук за ніком';

  @override
  String get friendsSearchPrompt => 'Скористайтеся пошуком, щоб знайти нових друзів';

  @override
  String get friendsNothingFound => 'Нічого не знайдено';

  @override
  String get friendsEmpty => 'У вас поки немає друзів';

  @override
  String get friendsSearchNoMatches => 'Немає друзів, що відповідають пошуку';

  @override
  String get friendsIncomingSearchNoMatches => 'Немає вхідних заявок за запитом';

  @override
  String get friendsOutgoingSearchNoMatches => 'Немає вихідних заявок за запитом';

  @override
  String get friendsNoIncoming => 'Немає вхідних запитів';

  @override
  String get friendsNoOutgoing => 'Немає вихідних запитів';

  @override
  String get friendsAlreadyFriends => 'Уже в друзях';

  @override
  String get friendsRemoveTitle => 'Видалити з друзів?';

  @override
  String get friendsRemoved => 'Видалено з друзів';

  @override
  String get friendsRequestAccepted => 'Запит прийнято';

  @override
  String get friendsRequestDeclined => 'Запит відхилено';

  @override
  String get friendsRequestCancelled => 'Запит скасовано';

  @override
  String get profileTitle => 'Профіль';

  @override
  String get profileSignInPrompt => 'Увійдіть у свій акаунт';

  @override
  String get profileSignInHint => 'Щоб налаштувати особистий профіль';

  @override
  String get profileEdit => 'Редагувати';

  @override
  String get profileCollections => 'Колекції';

  @override
  String get profileAge => 'Вік';

  @override
  String get profileGender => 'Стать';

  @override
  String get profileGenderUnset => 'Не вказано';

  @override
  String get profileGenderMale => 'Чоловіча';

  @override
  String get profileGenderFemale => 'Жіноча';

  @override
  String get profileAvatar => 'Аватар';

  @override
  String get profileUploadPhoto => 'Завантажити фото';

  @override
  String get profileChangePhoto => 'Змінити аватар';

  @override
  String get shopTitle => 'Магазин';

  @override
  String get shopEmojis => 'Емодзі';

  @override
  String get shopEmojisSubtitle => 'Анімовані емодзі для чату';

  @override
  String get shopCollections => 'Колекції';

  @override
  String get shopCollectionsSubtitle => 'Вітрина профілю, подарунки та дохід';

  @override
  String get shopStakes => 'Ставки';

  @override
  String get shopStakesSubtitle => 'Розблокування підвищених ставок';

  @override
  String get inventoryTitle => 'Предмети';

  @override
  String get inventoryEmpty => 'Поки нічого немає — загляньте в магазин';

  @override
  String get inventoryFrames => 'Рамки';

  @override
  String get inventoryClaim => 'Забрати';

  @override
  String get inventorySell => 'Продати';

  @override
  String get inventoryGift => 'Подарувати';

  @override
  String get messageEdited => 'змінено';

  @override
  String get messageDeleted => 'Повідомлення видалено';

  @override
  String get photo => 'Фото';

  @override
  String get camera => 'Камера';

  @override
  String get gallery => 'Галерея';

  @override
  String get connectionError => 'Не вдалося підключитися до сервера.';

  @override
  String get serverError => 'Помилка сервера. Спробуйте пізніше.';

  @override
  String get sessionExpired => 'Сесію завершено. Увійдіть знову.';

  @override
  String get errNoInternet => 'Немає підключення до інтернету.';

  @override
  String get errTimeout => 'Час очікування вичерпано. Спробуйте ще раз.';

  @override
  String get errGamesUnavailable => 'Ігри тимчасово недоступні';

  @override
  String get errSettingsSaveFailed => 'Не вдалося зберегти налаштування';

  @override
  String get errPushPermission => 'Дозвольте сповіщення в налаштуваннях браузера або системи.';

  @override
  String get balanceTitle => 'Баланс';

  @override
  String get coinBronze => 'Бронза';

  @override
  String get coinSilver => 'Срібло';

  @override
  String get coinGold => 'Золото';

  @override
  String get coinDiamond => 'Діамант';

  @override
  String get balanceZeroBronze => '0 бронзових';

  @override
  String balanceBronzes(int count) {
    return '$count бронзових';
  }

  @override
  String balanceSilvers(int count) {
    return '$count срібних';
  }

  @override
  String balanceGolds(int count) {
    return '$count золотих';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count діамантів';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/день';
  }

  @override
  String get balanceAbbrBronze => 'бр';

  @override
  String get balanceAbbrSilver => 'ср.';

  @override
  String get balanceAbbrGold => 'зл.';

  @override
  String get commonBackHome => 'Назад на головну';

  @override
  String get commonCopied => 'Скопійовано';

  @override
  String get commonClear => 'Очистити';

  @override
  String get commonTryLater => 'Спробуйте пізніше.';

  @override
  String get commonTryRefresh => 'Спробуйте оновити сторінку.';

  @override
  String get coinsTitle => 'Монети';

  @override
  String get coinsLoginReward => 'Монети за вхід';

  @override
  String get coinsLoginAvailableToday => 'Доступна нагорода за сьогодні';

  @override
  String get coinsLoginStreak => 'Щоденна серія входів';

  @override
  String get coinsFriendReward => 'Монети за друга';

  @override
  String get coinsTasks => 'Завдання';

  @override
  String get coinsTasksSubtitle => 'Нагороди за профіль, друзів і ігри';

  @override
  String get coinsTasksRewards => 'Є нагороди для отримання';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount за реєстрацію за посиланням';
  }

  @override
  String get coinsLoadRewardsFailed => 'Не вдалося завантажити нагороди';

  @override
  String get coinsClaimReward => 'Забрати нагороду';

  @override
  String get coinsAlreadyClaimed => 'Уже отримано';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · сьогодні';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · ще 1 день';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · ще $remaining';
  }

  @override
  String get coinsInviteFriend => 'Запроси друга';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount за кожного, хто зареєструється за вашим посиланням';
  }

  @override
  String get coinsCopyLink => 'Скопіювати посилання';

  @override
  String get coinsHowItWorks => 'Як це працює';

  @override
  String get coinsHowStep1 => 'Скопіюйте посилання й надішліть другу';

  @override
  String get coinsHowStep2 => 'Друг реєструється за цим посиланням';

  @override
  String coinsHowStep3(String amount) {
    return 'Вам нараховується $amount';
  }

  @override
  String get achievementsTitle => 'Досягнення';

  @override
  String achievementsProgress(String progress) {
    return 'Прогрес: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Рамку отримано';

  @override
  String get achievementsClaimed => 'Отримано';

  @override
  String get achievementsOpenFrame => 'Відкрити рамку';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Ви впевнені, що хочете видалити $name з друзів?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Прибрати';

  @override
  String get friendsRemove => 'Видалити з друзів';

  @override
  String get friendsAcceptRequest => 'Прийняти заявку';

  @override
  String get friendsDeclineRequest => 'Відхилити заявку';

  @override
  String get friendsCancelRequest => 'Скасувати заявку';

  @override
  String get friendsSendRequest => 'Надіслати заявку в друзі';

  @override
  String get friendsRequestAlreadySent => 'Заявку вже надіслано';

  @override
  String get friendsIncomingStatus => 'Вхідна заявка';

  @override
  String get friendsOutgoingStatus => 'Вихідна заявка';

  @override
  String get friendsNotFriends => 'Не в друзях';

  @override
  String get friendsCollapseSearch => 'Згорнути пошук';

  @override
  String get friendsExpandSearch => 'Показати пошук';

  @override
  String get friendsLoadFailed => 'Не вдалося завантажити друзів';

  @override
  String friendsSince(String date) {
    return 'Дружите з: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Вхідна заявка: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Вихідна заявка: $date';
  }

  @override
  String get userInfoTitle => 'Інформація про користувача';

  @override
  String profileAgeYears(int age) {
    return '$age років';
  }

  @override
  String get shopBuy => 'Купити';

  @override
  String get shopBuyTitle => 'Купити?';

  @override
  String get shopBuyStakeTitle => 'Купити ставку?';

  @override
  String get shopBuyEmojiTitle => 'Купити смайлик?';

  @override
  String get shopBuyCollectionTitle => 'Купити колекцію?';

  @override
  String shopPrice(String price) {
    return 'Ціна: $price';
  }

  @override
  String get shopOwned => 'Куплено';

  @override
  String get shopEmpty => 'Поки порожньо';

  @override
  String shopPurchased(String title) {
    return '$title куплено';
  }

  @override
  String get shopEmojiUses => 'Отримаєте: 10 використань';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 використань';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 використань';
  }

  @override
  String get shopBuyTen => 'Купити · 10 шт.';

  @override
  String shopDailyIncome(String amount) {
    return 'Дохід: $amount';
  }

  @override
  String get shopBuyOnce => 'Покупка один раз';

  @override
  String get shopSellRefund => 'Продаж поверне 80% вартості';

  @override
  String shopCollectionAdded(String title) {
    return '$title додано до профілю';
  }

  @override
  String shopSetBonus(int percent) {
    return 'бонус групи +$percent%';
  }

  @override
  String get shopSetComplete => 'Зібрано';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Зібрано · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Продати?';

  @override
  String inventorySellDesc(String amount) {
    return 'Ви отримаєте $amount';
  }

  @override
  String inventorySold(String amount) {
    return 'Продано: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Спочатку додайте друзів';

  @override
  String get inventoryGiftTitle => 'Подарувати колекцію?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'Подарувати «$title» користувачу $name?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Подаровано: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'Гравець уже має цей предмет';

  @override
  String get inventoryGiftSelf => 'Не можна дарувати собі';

  @override
  String get inventoryGiftNotOwned => 'Цього предмета немає у вашому інвентарі';

  @override
  String get inventoryLoadFailed => 'Не вдалося завантажити предмети';

  @override
  String get inventoryNoCollections => 'Немає колекцій — купіть у магазині';

  @override
  String get inventoryNoEmojis => 'Немає смайликів — купіть у магазині';

  @override
  String get inventoryNoFrames => 'Немає рамок — виграйте 10 ігор у лізі (досягнення)';

  @override
  String get inventoryNoStakes => 'Немає куплених ставок';

  @override
  String inventoryEmojiLeft(int count) {
    return 'Залишилось $count';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Дохід: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Дохід завтра: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Готово';

  @override
  String get inventoryIncomeTomorrowLabel => 'Завтра';

  @override
  String inventoryStakeGold(String amount) {
    return 'Можна ставити $amount золота';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'Можна ставити $amount срібла';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'Отримано +$amount';
  }

  @override
  String get chatsLoadFailed => 'Не вдалося завантажити чати';

  @override
  String get chatsLoadListFailed => 'Не вдалося завантажити список';

  @override
  String get chatsBlockedEmpty => 'Список порожній';

  @override
  String chatsBlockedAt(String date) {
    return 'Заблоковано: $date';
  }

  @override
  String get chatsCreateFailed => 'Не вдалося створити чат';

  @override
  String get chatsNeedFriendsFirst => 'Спочатку додайте друзів, потім можна відкрити чат.';

  @override
  String get chatsFriendsNotFound => 'Друзів не знайдено';

  @override
  String get chatsFindFriendHint => 'Знайти друга за ніком';

  @override
  String get chatsSelectChat => 'Оберіть чат';

  @override
  String get chatsSelectHint => 'Оберіть діалог зі списку ліворуч';

  @override
  String get chatEditFailed => 'Не вдалося змінити повідомлення';

  @override
  String get chatSendFailed => 'Не вдалося надіслати повідомлення';

  @override
  String get chatDeleteFailed => 'Не вдалося видалити повідомлення';

  @override
  String get chatEmojiSendFailed => 'Не вдалося надіслати смайлик';

  @override
  String get chatLoadFailed => 'Не вдалося завантажити повідомлення';

  @override
  String get chatBackToGame => 'Назад до гри';

  @override
  String get chatBackToChats => 'Назад до чатів';

  @override
  String get chatActions => 'Дії з чатом';

  @override
  String get chatAutoTranslate => 'Автопереклад';

  @override
  String get chatScrollToEnd => 'В кінець переписки';

  @override
  String chatReplyingTo(String name) {
    return 'У відповідь $name';
  }

  @override
  String get chatGift => 'Подарунок';

  @override
  String get chatCollection => 'Колекція';

  @override
  String get chatGiftCollection => 'Подарунок · колекція';

  @override
  String get chatThisUser => 'цього користувача';

  @override
  String get gamesLobbyLoadFailed => 'Не вдалося завантажити лобі.';

  @override
  String get gamesTapChangeStake => 'Натисніть, щоб змінити ставку';

  @override
  String get gamesTapChangeTurnTime => 'Натисніть, щоб змінити час на хід';

  @override
  String get gamesTapChangeGrid => 'Натисніть, щоб змінити розмір сітки';

  @override
  String get gamesSwapSidesHint => 'O може стати X після 1-го ходу';

  @override
  String get gamesNoCenterHint => 'Перший хід не в центр';

  @override
  String get lobbyInviteSentShort => 'Надіслано';

  @override
  String get lobbySearchShort => 'Пошук';

  @override
  String get lobbySearchPlayers => 'Пошук гравців';

  @override
  String get lobbyInviteDeclinedShort => 'Відмова';

  @override
  String get lobbyInvitesSentWaiting => 'Запрошення надіслано. Очікуйте відповіді.';

  @override
  String get lobbyLinkCopiedHint => 'Вставте її в чат або повідомлення другу';

  @override
  String get lobbyCopyLinkHint => 'Скопіювати посилання в буфер обміну';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name запрошує вас зіграти';
  }

  @override
  String gameOpponentWon(String name) {
    return 'Переміг $name';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Час вийшов. Переміг $name';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds с';
  }

  @override
  String get adminTitle => 'Адмінка';

  @override
  String get tournamentsTitle => 'Турніри';

  @override
  String get profileAgeInvalid => 'Введіть вік від 1 до 111';

  @override
  String get profileSaveFailed => 'Не вдалося зберегти профіль';

  @override
  String get profileNameHint => 'Латиниця, цифри, _ до 10 символів';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'Від 1 до 111';

  @override
  String get profileAboutHint => 'До 100 символів (за бажанням)';

  @override
  String get profileProcessingPhoto => 'Обробка фото…';

  @override
  String get profileCropTitle => 'Оберіть область аватара';

  @override
  String get profileCropHint => 'Масштабуйте й рухайте фото';

  @override
  String get profileApply => 'Застосувати';

  @override
  String get profilePreparing => 'Підготовка…';

  @override
  String get profileGalleryTitle => 'Фото';

  @override
  String get profileGalleryAdd => 'Додати фото';

  @override
  String get profileMakePrimary => 'Зробити основним';

  @override
  String get profilePhotoDelete => 'Видалити фото';

  @override
  String get profilePhotosLimit => 'Можна завантажити не більше 3 фото';

  @override
  String get profilePhotosEmpty => 'Поки немає фото';

  @override
  String get profilePhotoUploadFailed => 'Не вдалося завантажити фото';

  @override
  String get profilePhotoDeleteFailed => 'Не вдалося видалити фото';

  @override
  String get profilePhotoTooLarge => 'Фото занадто велике';

  @override
  String get profileSetPrimaryFailed => 'Не вдалося зробити основним';

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
    return 'Хрестики-нулики на полі $grid. Ходять по черзі, X починає.';
  }

  @override
  String rulesWin(int n) {
    return 'Перемога: потрібно вибудувати $n в ряд по горизонталі, вертикалі або діагоналі.';
  }

  @override
  String get rulesNoTimeLimit => 'Без обмеження часу на хід.';

  @override
  String rulesTurnTime(String time) {
    return 'Час на хід: $time. Якщо час вийшов — поразка.';
  }

  @override
  String rulesStake(String stake) {
    return 'Ставка: $stake. На стільки монет іде гра.';
  }

  @override
  String get rulesSwap => 'Зміна сторін: O може помінятися місцями з X після першого ходу X.';

  @override
  String get rulesNoCenter => 'Заборона центру: X не може ходити в центр першим ходом.';

  @override
  String get collectionSetLegends => 'Легенди';

  @override
  String get collectionSetSpace => 'Космос';

  @override
  String get collectionSetGems => 'Коштовності';

  @override
  String get collectionSetParty => 'Свято';

  @override
  String get collectionSetNature => 'Природа';

  @override
  String get collectionSetAdventures => 'Пригоди';

  @override
  String collectionCardMeta(String amount) {
    return 'Колекція · вітрина · подарунок · продаж · +$amount';
  }

  @override
  String get coinsDayOne => 'день';

  @override
  String get coinsDayFew => 'дні';

  @override
  String get coinsDayMany => 'днів';

  @override
  String get giftFriendTitle => 'Подарувати другу';

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
    return '$count смайликів · по $price';
  }

  @override
  String get chatsExpandPanel => 'Розгорнути панель';

  @override
  String get chatsCollapsePanel => 'Згорнути панель';

  @override
  String get chatReplySourceMissing => 'Вихідне повідомлення не знайдено';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Ставка $n срібла';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Ставка $n золота';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Право ставити $n срібла в іграх';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Право ставити $n золота в іграх';
  }

  @override
  String get chatReplySelf => 'собі';

  @override
  String get chatReplyPeer => 'співрозмовнику';

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
  String get statsLoadFailed => 'Не вдалося завантажити статистику';

  @override
  String get statsAllGames => 'Усі ігри';

  @override
  String get statsEmptyTitle => 'Поки немає зіграних партій';

  @override
  String get statsEmptyHint => 'Зіграйте першу гру, щоб тут з’явилася статистика.';

  @override
  String get statsWins => 'Перемоги';

  @override
  String get statsDraws => 'Нічиї';

  @override
  String get statsLosses => 'Поразки';

  @override
  String get statsWinRate => 'Відсоток перемог';

  @override
  String get statsTopWon => 'Найбільше перемог проти';

  @override
  String get statsTopDrawn => 'Найбільше нічиїх з';

  @override
  String get statsTopLost => 'Найбільше поразок від';

  @override
  String get statsTimePlayed => 'Час у грі';

  @override
  String get statsYourScore => 'Ваш рахунок';

  @override
  String get profileShowStats => 'Показувати статистику';

  @override
  String get statsDurationZeroMinutes => '0 хв';

  @override
  String get gameYouWonOpponentForfeit => 'Суперник здався. Ви перемогли!';

  @override
  String get lobbyLeaveTitle => 'Покинути лобі?';

  @override
  String get lobbyLeaveConfirm => 'Лобі буде видалено після виходу. Запрошені друзі отримають відмову.';

  @override
  String get lobbyLeave => 'Покинути';

  @override
  String statsDurationHours(int hours) {
    return '$hours год';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours год $minutes хв';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes хв';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'Ви здалися. $name переміг';
  }

  @override
  String get supportTitle => 'Підтримка';

  @override
  String get supportUnavailable => 'Підтримка недоступна';

  @override
  String get supportOpenFailed => 'Не вдалося відкрити чат із підтримкою';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Вам нараховано $amount монет';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return 'Списано $amount монет';
  }

  @override
  String get coinsCreditCardTitle => 'Вам нараховано монети';

  @override
  String get coinsClaim => 'Забрати';

  @override
  String get durakActionPass => 'Пас';

  @override
  String get durakRoleTook => 'Забрав';

  @override
  String get durakRoleBeats => 'Б\'є';

  @override
  String get durakRoleThrowIn => 'Підкид';

  @override
  String get durakRoleTurn => 'Хід';

  @override
  String get durakRoleDefends => 'Відбивається';

  @override
  String get durakStatusTaking => 'Беру';

  @override
  String get durakHintDefenderTurn => 'Хід захисника';

  @override
  String get gameYouEliminated => 'Ви вибули';

  @override
  String gameYouPlaced(int place) {
    return 'Ви посіли $place-е місце';
  }

  @override
  String get gameOverNeutral => 'Партію завершено';

  @override
  String gameTurnOf(String name) {
    return 'Хід $name';
  }

  @override
  String get chatGroupTooltip => 'Чат групи';

  @override
  String get lobbyChatNotReady => 'Чат лобі ще не створено';

  @override
  String get chatsGroupChat => 'Груповий чат';

  @override
  String chatsMembersCount(int count) {
    return 'Учасники: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count уч.';
  }

  @override
  String get chatsYouSuffix => '(ви)';

  @override
  String get chatTitleDurak3 => 'Дурак на трьох';

  @override
  String get chatTitleDurak4 => 'Дурак на чотирьох';

  @override
  String get rulesTttUltimate => 'Ультимейт: 9 міні-полів 3×3. Хід у клітинку надсилає суперника на відповідне міні-поле. Перемагає той, хто зібрав лінію на мета-полі.';

  @override
  String get rulesTttMulti3 => 'На трьох: поле 3×3, троє гравців (X, O, △). Хто зібрав лінію зі своїх знаків — перемагає.';

  @override
  String get rulesTttMulti4 => 'На чотирьох: поле 4×4, четверо гравців (X, O, △, □). Хто зібрав лінію зі своїх знаків — перемагає.';
}
