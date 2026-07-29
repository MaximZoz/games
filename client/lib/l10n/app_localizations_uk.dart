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
    return '$amount на день';
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
  String get shopSellRefund => 'Продаж поверне частину вартості';

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
  String timeSecondsShort(int seconds) {
    return '$seconds с';
  }

  @override
  String get timeOneMin => '1 хв';

  @override
  String get timeTenMin => '10 хв';
}
