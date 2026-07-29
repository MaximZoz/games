import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Главная';

  @override
  String get navProfile => 'Профиль';

  @override
  String get navFriends => 'Друзья';

  @override
  String get navChats => 'Чаты';

  @override
  String get navGames => 'Игры';

  @override
  String get navSettings => 'Настройки';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageSystem => 'Как в системе';

  @override
  String get settingsAddBotsTitle => 'Добавлять ботов через 30 с';

  @override
  String get settingsAddBotsSubtitle => 'В режиме «поиск игры»: если соперник не найден за 30 секунд, игра начинается с ботом (цена игры сбрасывается до 1-й бронзы)';

  @override
  String get settingsFriendsOnlyTitle => 'Сообщения только от друзей';

  @override
  String get settingsFriendsOnlySubtitle => 'Кто не в друзьях, сможет отправлять только смайлики. Если мешает спам — временно заблокируйте пользователя.';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsPushChat => 'Чат';

  @override
  String get settingsPushFriends => 'Друзья';

  @override
  String get settingsPushGames => 'Игры';

  @override
  String get settingsPushRewards => 'Награды';

  @override
  String get loginTitle => 'Вход';

  @override
  String get loginSubtitle => 'Введите email или логин и пароль';

  @override
  String get loginEmailLabel => 'Email или логин';

  @override
  String get loginPasswordLabel => 'Пароль';

  @override
  String get loginSubmit => 'Войти';

  @override
  String get loginNoAccount => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get loginEmailRequired => 'Введите email или логин';

  @override
  String get loginPasswordRequired => 'Введите пароль';

  @override
  String get loginTooltip => 'Войти';

  @override
  String get logoutTooltip => 'Выйти';

  @override
  String get registerTitle => 'Регистрация';

  @override
  String get registerSubtitle => 'Создайте аккаунт для игры';

  @override
  String get registerNameLabel => 'Имя (логин)';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'Пароль';

  @override
  String get registerSubmit => 'Зарегистрироваться';

  @override
  String get registerHaveAccount => 'Уже есть аккаунт? Войти';

  @override
  String get registerNameRequired => 'Введите имя';

  @override
  String get registerNameNoSpaces => 'Имя без пробелов';

  @override
  String get registerNameMax => 'Максимум 20 символов';

  @override
  String get registerNameHint => 'До 20 символов';

  @override
  String get registerEmailRequired => 'Введите email';

  @override
  String get registerEmailInvalid => 'Некорректный email';

  @override
  String get registerPasswordHint => 'Минимум 6 символов';

  @override
  String get registerPasswordMin => 'Пароль не короче 6 символов';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonEdit => 'Изменить';

  @override
  String get commonReply => 'Ответить';

  @override
  String get commonSend => 'Отправить';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonLoading => 'Загрузка…';

  @override
  String get commonError => 'Ошибка';

  @override
  String get commonOnline => 'в сети';

  @override
  String get commonOffline => 'не в сети';

  @override
  String get commonOnlineCap => 'Онлайн';

  @override
  String get commonUser => 'Пользователь';

  @override
  String get commonPlayer => 'Игрок';

  @override
  String get commonAboutMe => 'О себе';

  @override
  String get commonBack => 'Назад';

  @override
  String get commonAccept => 'Принять';

  @override
  String get commonDecline => 'Отклонить';

  @override
  String get commonCreating => 'Создание…';

  @override
  String get commonSearching => 'Поиск…';

  @override
  String get commonInsufficientCoins => 'Недостаточно монет';

  @override
  String get commonNotFound => 'Не найдено';

  @override
  String get commonServerErrorShort => 'Ошибка сервера';

  @override
  String get commonForbidden => 'Недостаточно прав';

  @override
  String get commonUserBlocked => 'Пользователь заблокирован';

  @override
  String get commonUserNotFound => 'Пользователь не найден';

  @override
  String get commonGenericError => 'Произошла ошибка. Попробуйте ещё раз.';

  @override
  String get timeJustNow => 'только что';

  @override
  String get timeYesterday => 'вчера';

  @override
  String timeMinutesAgo(Object count) {
    return '$count мин назад';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count ч назад';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count дн. назад';
  }

  @override
  String get timeWeekAgo => 'неделю назад';

  @override
  String timeWeeksAgo(Object count) {
    return '$count нед. назад';
  }

  @override
  String get timeMonthAgo => 'месяц назад';

  @override
  String timeMonthsAgo(Object count) {
    return '$count мес. назад';
  }

  @override
  String get timeYearAgo => 'год назад';

  @override
  String timeYearsAgo(Object count) {
    return '$count г. назад';
  }

  @override
  String get weekdaySun => 'вс';

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
  String get monthJan => 'янв';

  @override
  String get monthFeb => 'фев';

  @override
  String get monthMar => 'мар';

  @override
  String get monthApr => 'апр';

  @override
  String get monthMay => 'май';

  @override
  String get monthJun => 'июн';

  @override
  String get monthJul => 'июл';

  @override
  String get monthAug => 'авг';

  @override
  String get monthSep => 'сен';

  @override
  String get monthOct => 'окт';

  @override
  String get monthNov => 'ноя';

  @override
  String get monthDec => 'дек';

  @override
  String get homeAchievements => 'Достижения';

  @override
  String get homeAchievementsSubtitle => 'Ваши игровые результаты';

  @override
  String get homeAchievementsRewards => 'Есть награды к получению';

  @override
  String get homeCoins => 'Монеты';

  @override
  String get homeCoinsSubtitle => 'Баланс и награды';

  @override
  String get homeCoinsDailyReward => 'Доступна награда за вход';

  @override
  String get homeItems => 'Предметы';

  @override
  String get homeItemsInventory => 'Ваш инвентарь';

  @override
  String get homeItemsGifted => 'Вам подарили коллекцию';

  @override
  String get homeItemsIncome => 'Можно забрать доход коллекций';

  @override
  String get homeShop => 'Магазин';

  @override
  String get homeShopSubtitle => 'Смайлы, ставки, коллекции';

  @override
  String get gamesTitle => 'Игры';

  @override
  String get gamesFindMatch => 'Найти игру';

  @override
  String get gamesMyTurn => 'Ваш ход';

  @override
  String get gamesWaiting => 'Ожидание';

  @override
  String get gamesLobbyTab => 'Лобби';

  @override
  String get gamesTicTacToe => 'Крестики-нолики';

  @override
  String get gamesRules => 'Правила';

  @override
  String get gamesRulesTitle => 'Правила игры';

  @override
  String get gamesCreate => 'Создать игру';

  @override
  String get gamesJoin => 'Присоединиться';

  @override
  String get gamesOpponentTurn => 'Ход соперника';

  @override
  String get gamesCurrentGame => 'Текущая игра';

  @override
  String get gamesInvitedYou => 'Вас пригласили';

  @override
  String get gamesTurnTime => 'Время на ход';

  @override
  String get gamesGridSize => 'Размер сетки';

  @override
  String get gamesSwapSides => 'Смена сторон';

  @override
  String get gamesNoCenter => 'Запрет центра';

  @override
  String get lobbyMatchmake => 'Лобби';

  @override
  String get lobbyPrivateGame => 'Своя игра';

  @override
  String get lobbySearchingOpponent => 'Поиск соперника…';

  @override
  String get lobbyWaitingJoin => 'Ждём, пока кто-то нажмёт «Найти игру» или «Присоединиться»';

  @override
  String get lobbyInviteTitle => 'Приглашение в игру';

  @override
  String get lobbyInvitedToPlay => 'Вас пригласили сыграть';

  @override
  String get lobbyEnterGame => 'Войти в игру';

  @override
  String get lobbyInvite => 'Пригласить';

  @override
  String get lobbyInviteSent => 'Приглашение отправлено';

  @override
  String get lobbyCopyLink => 'Отправить ссылку на игру';

  @override
  String get lobbyLinkCopied => 'Ссылка скопирована';

  @override
  String get lobbyNoFriendsOnline => 'Нет друзей онлайн. Отправьте ссылку на игру выше или дождитесь, пока друзья появятся в сети.';

  @override
  String get gameBot => 'Бот';

  @override
  String get gameOpponent => 'Соперник';

  @override
  String get gameYouWon => 'Вы победили!';

  @override
  String get gameYouWonOpponentLeft => 'Вы победили, соперник вышел';

  @override
  String get gameYouWonOpponentTimeout => 'Вы победили, время соперника вышло';

  @override
  String get gameDraw => 'Ничья';

  @override
  String get gameExitTitle => 'Выход из игры';

  @override
  String get gameExitConfirm => 'Если вы выйдете, то вы проиграете. Выйти?';

  @override
  String get gameStay => 'Остаться';

  @override
  String get gameLeave => 'Выйти';

  @override
  String get gameConnecting => 'Подключение к игре…';

  @override
  String get gameWaitingOpponent => 'Ожидание соперника';

  @override
  String get gameRematchOffer => 'Соперник предлагает реванш';

  @override
  String get gameRematchDeclined => 'Соперник отклонил предложение поиграть';

  @override
  String get gameRematch => 'Повторить';

  @override
  String get gameOtherOpponent => 'Другой соперник';

  @override
  String get gameSwapSidesAction => 'Сменить стороны';

  @override
  String get gameWriteMessage => 'Написать сообщение';

  @override
  String get chatsTitle => 'Чаты';

  @override
  String get chatsEmpty => 'Пока нет чатов.\nНажмите на иконку справа сверху, чтобы выбрать друга и начать диалог.';

  @override
  String get chatsNewChat => 'Новый чат';

  @override
  String get chatsNoMessages => 'Нет сообщений';

  @override
  String get chatsClearTitle => 'Очистить переписку?';

  @override
  String get chatsClearDesc => 'Диалог будет удалён без возможности восстановления.';

  @override
  String get chatsClearConfirm => 'Очистить';

  @override
  String get chatsBlockTitle => 'Заблокировать пользователя?';

  @override
  String get chatsBlockDesc => 'Вы больше не сможете писать друг другу. Диалог и дружба будут удалены.';

  @override
  String get chatsBlockConfirm => 'Заблокировать';

  @override
  String get chatsBlockedUsers => 'Заблокированные пользователи';

  @override
  String get chatsUnblock => 'Разблокировать';

  @override
  String get chatDialog => 'Диалог';

  @override
  String get chatEmpty => 'Сообщений пока нет.\nНапишите первое сообщение.';

  @override
  String get chatMessageHint => 'Сообщение';

  @override
  String get chatEmoji => 'Смайлики';

  @override
  String get chatBuyEmojiHint => 'Купите смайлики в магазине на главной';

  @override
  String get chatEditing => 'Редактирование';

  @override
  String get chatToday => 'Сегодня';

  @override
  String get chatYesterday => 'Вчера';

  @override
  String get chatFriendsOnly => 'Текст только для друзей';

  @override
  String get emojiGroupEmotions => 'Эмоции';

  @override
  String get emojiGroupGame => 'Игровые';

  @override
  String get emojiGroupFlags => 'Флажки';

  @override
  String get emojiGroupAnimals => 'Животные';

  @override
  String get emojiGroupFood => 'Еда';

  @override
  String get emojiGroupTravel => 'Путешествия';

  @override
  String get emojiGroupParty => 'Праздник';

  @override
  String get emojiGroupObjects => 'Предметы';

  @override
  String get friendsTitle => 'Друзья';

  @override
  String get friendsTabFriends => 'Друзья';

  @override
  String get friendsTabIncoming => 'Входящие';

  @override
  String get friendsTabOutgoing => 'Исходящие';

  @override
  String get friendsAdd => 'Добавить в друзья';

  @override
  String get friendsRequestSent => 'Заявка отправлена';

  @override
  String get friendsFindTab => 'Найти друга';

  @override
  String get friendsSearchHint => 'Поиск по нику';

  @override
  String get friendsSearchPrompt => 'Используйте поиск, чтобы найти новых друзей';

  @override
  String get friendsNothingFound => 'Ничего не найдено';

  @override
  String get friendsEmpty => 'У вас пока нет друзей';

  @override
  String get friendsNoIncoming => 'Нет входящих заявок';

  @override
  String get friendsNoOutgoing => 'Нет исходящих заявок';

  @override
  String get friendsAlreadyFriends => 'Уже в друзьях';

  @override
  String get friendsRemoveTitle => 'Убрать из друзей?';

  @override
  String get friendsRemoved => 'Пользователь удалён из друзей';

  @override
  String get friendsRequestAccepted => 'Заявка принята';

  @override
  String get friendsRequestDeclined => 'Заявка отклонена';

  @override
  String get friendsRequestCancelled => 'Заявка отменена';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileSignInPrompt => 'Войдите в аккаунт';

  @override
  String get profileSignInHint => 'Чтобы настроить личный профиль';

  @override
  String get profileEdit => 'Редактировать';

  @override
  String get profileCollections => 'Коллекции';

  @override
  String get profileAge => 'Возраст';

  @override
  String get profileGender => 'Пол';

  @override
  String get profileGenderUnset => 'Не указан';

  @override
  String get profileGenderMale => 'Мужской';

  @override
  String get profileGenderFemale => 'Женский';

  @override
  String get profileAvatar => 'Аватар';

  @override
  String get profileUploadPhoto => 'Загрузить фото';

  @override
  String get profileChangePhoto => 'Поменять фото';

  @override
  String get shopTitle => 'Магазин';

  @override
  String get shopEmojis => 'Смайлики';

  @override
  String get shopEmojisSubtitle => 'Анимированные эмодзи для чата';

  @override
  String get shopCollections => 'Коллекции';

  @override
  String get shopCollectionsSubtitle => 'Витрина профиля, подарки и доход';

  @override
  String get shopStakes => 'Ставки';

  @override
  String get shopStakesSubtitle => 'Разблокировка серебряных ставок';

  @override
  String get inventoryTitle => 'Предметы';

  @override
  String get inventoryEmpty => 'Пока ничего нет — загляните в магазин';

  @override
  String get inventoryFrames => 'Рамки';

  @override
  String get inventoryClaim => 'Забрать';

  @override
  String get inventorySell => 'Продать';

  @override
  String get inventoryGift => 'Подарить';

  @override
  String get messageEdited => 'изменено';

  @override
  String get messageDeleted => 'Сообщение удалено';

  @override
  String get photo => 'Фото';

  @override
  String get camera => 'Камера';

  @override
  String get gallery => 'Галерея';

  @override
  String get connectionError => 'Не удалось подключиться к серверу.';

  @override
  String get serverError => 'Ошибка сервера. Попробуйте позже.';

  @override
  String get sessionExpired => 'Сессия истекла. Войдите заново.';

  @override
  String get errNoInternet => 'Нет подключения к интернету.';

  @override
  String get errTimeout => 'Превышено время ожидания. Попробуйте ещё раз.';

  @override
  String get errGamesUnavailable => 'Игры временно недоступны';

  @override
  String get errSettingsSaveFailed => 'Не удалось сохранить настройку';

  @override
  String get errPushPermission => 'Разрешите уведомления в настройках браузера или системы.';
}
