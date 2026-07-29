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
  String get settingsLanguageRu => 'Русский';

  @override
  String get settingsLanguageEn => 'English';

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
  String get timeJustNow => 'только что';

  @override
  String get timeYesterday => 'вчера';

  @override
  String timeMinutesAgo(int count) {
    return '$count мин назад';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count ч назад';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count дн. назад';
  }

  @override
  String get timeWeekAgo => 'неделю назад';

  @override
  String timeWeeksAgo(int count) {
    return '$count нед. назад';
  }

  @override
  String get timeMonthAgo => 'месяц назад';

  @override
  String timeMonthsAgo(int count) {
    return '$count мес. назад';
  }

  @override
  String get timeYearAgo => 'год назад';

  @override
  String timeYearsAgo(int count) {
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
  String get gamesTitle => 'Игры';

  @override
  String get gamesFindMatch => 'Найти игру';

  @override
  String get gamesMyTurn => 'Ваш ход';

  @override
  String get gamesWaiting => 'Ожидание';

  @override
  String get chatsTitle => 'Чаты';

  @override
  String get chatsEmpty => 'Пока нет чатов.\nНажмите на иконку справа сверху, чтобы выбрать друга и начать диалог.';

  @override
  String get chatsNewChat => 'Новый чат';

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
  String get profileTitle => 'Профиль';

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
}
