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
  String get settingsAddBotsTitle => 'Додавати ботів через 30 с';

  @override
  String get settingsAddBotsSubtitle => 'У режимі пошуку гри: якщо суперника не знайдено за 30 секунд, гра починається з ботом (ставка скидається до 1 бронзи)';

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
  String get timeJustNow => 'щойно';

  @override
  String get timeYesterday => 'вчора';

  @override
  String timeMinutesAgo(Object count) {
    return '$count хв тому';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count год тому';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count дн. тому';
  }

  @override
  String get timeWeekAgo => 'тиждень тому';

  @override
  String timeWeeksAgo(Object count) {
    return '$count тиж. тому';
  }

  @override
  String get timeMonthAgo => 'місяць тому';

  @override
  String timeMonthsAgo(Object count) {
    return '$count міс. тому';
  }

  @override
  String get timeYearAgo => 'рік тому';

  @override
  String timeYearsAgo(Object count) {
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
  String get lobbyMatchmake => 'Лобі';

  @override
  String get lobbyPrivateGame => 'Приватна гра';

  @override
  String get lobbySearchingOpponent => 'Пошук суперника…';

  @override
  String get lobbyWaitingJoin => 'Чекаємо, поки хтось натисне «Знайти гру» або «Приєднатися»';

  @override
  String get lobbyInviteTitle => 'Запрошення в гру';

  @override
  String get lobbyInvitedToPlay => 'Вас запросили зіграти';

  @override
  String get lobbyEnterGame => 'Увійти в гру';

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
  String get profileChangePhoto => 'Змінити фото';

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
  String get shopStakesSubtitle => 'Розблокуйте срібні ставки';

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
}
