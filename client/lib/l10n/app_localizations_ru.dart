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
  String get settingsSoundTitle => 'Звук';

  @override
  String get settingsSoundSubtitle => 'Игры и уведомления';

  @override
  String get settingsSoundGames => 'Игры';

  @override
  String get settingsSoundNotifications => 'Уведомления';

  @override
  String get settingsSoundTurn => 'Ход';

  @override
  String get settingsHapticsTitle => 'Вибрация';

  @override
  String get settingsHapticsSubtitle => 'Только уведомления: сообщения, заявки, ваш ход и таймер';

  @override
  String get settingsOfflineModeTitle => 'Режим сети';

  @override
  String get settingsOfflineModeSubtitle => 'Офлайн: игра с ботом сразу, без ставок и наград, без чатов и друзей. Покупки сохраняются и применяются в режиме онлайн. Онлайн — когда есть интернет или по настройке пользователя.';

  @override
  String get settingsModeOnline => 'Онлайн';

  @override
  String get settingsModeOffline => 'Офлайн';

  @override
  String get gamesAlternateStartsHint => 'По очереди кто начинает партию';

  @override
  String get rulesAlternateStarts => 'Кто ходит первым чередуется от партии к партии.';

  @override
  String get offlineBadgeTooltip => 'Офлайн режим';

  @override
  String get offlineModePopupTitle => 'Офлайн режим';

  @override
  String get offlineModePopupBody => 'Включён офлайн режим. Играйте с ботом без ставок и наград. Чаты, друзья и лобби скрыты. Покупки применятся в режиме онлайн.';

  @override
  String get offlineModePopupSettings => 'Настройки';

  @override
  String get gamesPlay => 'Играть';

  @override
  String get offlineGameTitle => 'Игра с ботом';

  @override
  String get offlineGameHint => 'Без ставок и наград · только офлайн';

  @override
  String get offlineBotWon => 'Бот победил';

  @override
  String get offlineBotThinking => 'Ход бота…';

  @override
  String get offlinePlayAgain => 'Ещё раз';

  @override
  String offlineBotName(int n) {
    return 'Бот $n';
  }

  @override
  String get durakActionTake => 'Взять';

  @override
  String get durakActionAll => 'Все';

  @override
  String get durakActionDone => 'Готово';

  @override
  String get durakActionBito => 'Бито';

  @override
  String get durakHintDefend => 'Отбивайтесь';

  @override
  String get durakHintDefendOrTransfer => 'Отбивайтесь или переведите';

  @override
  String get durakHintOpponentDefends => 'Соперник отбивается';

  @override
  String get durakHintThrowInFirst => 'Подкиньте карты (макс. 5 в первом отбое)';

  @override
  String get durakHintThrowIn => 'Подкиньте карты или ждите отбоя';

  @override
  String get durakHintOpponentThrows => 'Соперник подкидывает';

  @override
  String get durakHintTakeFollow => 'Подкиньте вдогонку или нажмите «Готово»';

  @override
  String get durakHintOpponentTakeFollow => 'Соперник может подкинуть вдогонку';

  @override
  String get durakHintBito => 'Подкиньте карту или скажите «Бито»';

  @override
  String get durakHintOpponentBito => 'Соперник подкидывает или говорит «Бито»';

  @override
  String get durakHintYourAttack => 'Ваш ход — атакуйте';

  @override
  String get durakHintOpponentAttack => 'Атакует соперник';

  @override
  String get durakHintYouLost => 'Вы проиграли — вы дурак';

  @override
  String get durakHintDrawAllOut => 'Ничья — все вышли';

  @override
  String get durakHintYouFinished => 'Вы вышли — ждём конца партии';

  @override
  String get durakFirstLeadYou => 'Вы ходите';

  @override
  String get durakFirstLeadOpponent => 'Соперник ходит';

  @override
  String get durakFirstLeadBot => 'Бот ходит';

  @override
  String durakFirstLeadOf(String name) {
    return 'Ходит $name';
  }

  @override
  String get durakFirstLeadReason => 'Младший козырь';

  @override
  String get shopPurchaseQueued => 'Покупка сохранена — применится в режиме онлайн';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — покупка применена';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — покупка не применена: $reason';
  }

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
  String settingsAppVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get appUpdateTitle => 'Доступно обновление';

  @override
  String get appUpdateBody => 'Вышла новая версия приложения. Обновитесь, чтобы продолжить.';

  @override
  String get appUpdateWhatsNew => 'Что нового';

  @override
  String get appUpdateOk => 'Обновить';

  @override
  String get appUpdateLaterBanner => 'После партии обновим приложение';

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
  String get apiErrWrongGameType => 'Неверный тип игры';

  @override
  String get apiErrWrongGameTypeOrState => 'Неверный тип или состояние игры';

  @override
  String get apiErrLobbyFull => 'Лобби заполнено';

  @override
  String get apiErrBadState => 'Ошибка состояния игры';

  @override
  String get apiErrIllegalMove => 'Такой ход нельзя сделать';

  @override
  String get apiErrUnknownMoveType => 'Неизвестный тип хода';

  @override
  String get apiErrNoOpponents => 'Нет соперников';

  @override
  String get apiErrNoOpponentsRematch => 'Нет соперников для реванша';

  @override
  String get apiErrAlreadyInLobby => 'Вы уже в этом лобби';

  @override
  String get apiErrGameNotActive => 'Игра не активна';

  @override
  String get apiErrNotInBattle => 'Сейчас не фаза боя';

  @override
  String get apiErrNotInSetup => 'Сейчас не фаза расстановки';

  @override
  String get apiErrAlreadyReady => 'Вы уже готовы';

  @override
  String get apiErrAlreadyForfeited => 'Вы уже сдались';

  @override
  String get apiErrYouHaveForfeited => 'Вы сдались';

  @override
  String get apiErrNoDrawOffer => 'Нет предложения ничьей';

  @override
  String get apiErrDrawOnlyPvp => 'Ничья доступна только против игрока';

  @override
  String get apiErrDrawOnly1v1 => 'Ничья доступна только в игре 1 на 1';

  @override
  String get apiErrDrawVsBot => 'Ничья недоступна против бота';

  @override
  String get apiErrDrawMultiplayer => 'Ничья недоступна в игре на несколько игроков';

  @override
  String get apiErrDeck24TwoPlayers => 'Колода 24 только для двоих';

  @override
  String get apiErrDeck52ThreeOrFour => 'Колода 52 только для 3 или 4 игроков';

  @override
  String get apiErrAccountFrozen => 'Аккаунт заморожен';

  @override
  String get apiErrTurnTimeInvalid => 'Время на ход должно быть 0, 20, 60 или 600 секунд';

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
  String get gamesDurak => 'Дурак';

  @override
  String get gamesBattleship => 'Морской бой';

  @override
  String get gamesBattleshipRandomPlace => 'Расставить случайно';

  @override
  String get gamesBattleshipConfirmPlace => 'Готово';

  @override
  String get gamesBattleshipRotate => 'Повернуть';

  @override
  String get gamesBattleshipSetupPhase => 'Расстановка';

  @override
  String get gamesBattleshipBattlePhase => 'Бой';

  @override
  String get gamesBattleshipWaitingOpponentSetup => 'Ожидание соперника…';

  @override
  String get gamesBattleshipYouWon => 'Вы победили!';

  @override
  String get gamesBattleshipYouLost => 'Вы проиграли';

  @override
  String get gamesBattleshipShipsMustNotTouch => 'Корабли не должны соприкасаться';

  @override
  String get rulesBattleshipTitle => 'Морской бой — правила';

  @override
  String get rulesBattleshipPlayers => 'Игроки: 2.';

  @override
  String rulesBattleshipSetupTime(String time) {
    return 'Время на расстановку: $time.';
  }

  @override
  String get rulesBattleshipIntro => 'Поле 10×10. Флот: один четырёхпалубный, два трёхпалубных, три двухпалубных и четыре однопалубных. Корабли нельзя ставить вплотную, в том числе по диагонали.';

  @override
  String get rulesBattleshipSetup => 'Если время на расстановку вышло, остаётся текущая валидная расстановка; если она невалидна — используется стандартная.';

  @override
  String get rulesBattleshipPlay => 'После расстановки первым ходит случайный игрок. Стреляйте по клеткам соперника: попадание даёт ещё один ход, промах передаёт ход. На своём ходе видно поле соперника, на его ходе — ваше.';

  @override
  String get rulesBattleshipWin => 'Побеждает тот, кто первым потопит весь флот противника.';

  @override
  String get gamesPoker => 'Покер';

  @override
  String get gamesUno => 'Уно';

  @override
  String get gamesNardy => 'Нарды';

  @override
  String get gamesNardyModeShort => 'Короткие';

  @override
  String get gamesNardyModeLong => 'Длинные';

  @override
  String get rulesNardyTitle => 'Нарды — правила';

  @override
  String get rulesNardyPlayers => 'Игроки: 2.';

  @override
  String rulesNardyMode(String mode) {
    return 'Режим: $mode.';
  }

  @override
  String get rulesNardyIntro => 'Доска из 24 пунктов, у каждого по 15 шашек. Ходы по двум кубикам: можно сходить одной шашкой на сумму или двумя на очки кубиков.';

  @override
  String get rulesNardyPlayShort => 'Короткие нарды: игроки идут навстречу и могут бить одиночные шашки соперника. Сбитая встаёт на бар и должна войти снова. Когда все шашки в доме — снимаете их с доски.';

  @override
  String get rulesNardyPlayLong => 'Длинные нарды: оба начинают с одной головы и идут в одну сторону. С головы за ход выходит не больше одной шашки. Бить шашки нельзя. Когда все в доме — снимаете их с доски.';

  @override
  String get rulesNardyWin => 'Побеждает тот, кто первым снимет все свои шашки.';

  @override
  String get rulesNardySixPrime => 'Шесть своих пунктов подряд запирать нельзя, пока их не обошла хотя бы одна шашка соперника.';

  @override
  String get nardyRoll => 'Бросить';

  @override
  String get nardySkipTurn => 'Пропустить ход';

  @override
  String get nardyUndoMove => 'Вернуть';

  @override
  String get nardyDoneTurn => 'Готово';

  @override
  String get nardyAutoConfirm => 'Автоподтверждение';

  @override
  String get nardyAutoConfirmHint => 'После всех ходов сразу передать ход сопернику';

  @override
  String get nardyNoMoves => 'Ходов нет';

  @override
  String get nardyYourRoll => 'Ваш бросок';

  @override
  String get nardyPipsShort => 'Осталось:';

  @override
  String get nardyYouWonMars => 'Вы выиграли — марс!';

  @override
  String get nardyYouLostMars => 'Поражение — марс';

  @override
  String get rulesNardyOfflineBot => 'Офлайн: партия против бота.';

  @override
  String rulesUnoPlayers(int players) {
    return 'Игроки: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'Игра против бота, без лимита времени на ход.';

  @override
  String get rulesUnoIntro => 'Каждому раздают по 7 карт. Ходите картой того же цвета или того же номинала (цифра или такой же спецэффект).';

  @override
  String get rulesUnoPlay => 'Пропуск — следующий теряет ход. Смена направления вдвоём работает как пропуск. +2 можно класть только на +2, +4 — только на +4: штраф суммируется (две +2 — следующий берёт 4). +2 на +4 класть нельзя. Кто не отвечает, берёт всю стопку и пропускает ход. Две одинаковые цифровые карты (например, две жёлтые 8) сбрасываются вместе: достаточно кинуть одну — вторая уходит автоматически. +2, пропуск, реверс и чёрные карты парой не кидаются.';

  @override
  String get rulesUnoWild => 'Чёрная карта задаёт новый цвет. +4 кладут, только если нет карты текущего цвета. Соперник может оспорить: если +4 был законным — оспаривающий берёт 6, если нет — автор +4 берёт 4, а оспаривающий ходит.';

  @override
  String get rulesUnoDraw => 'Если подходящей карты нет — возьмите одну из колоды. Если она подходит, можно сразу сходить ею или оставить и передать ход. Пока есть ход, брать нельзя.';

  @override
  String get rulesUnoWin => 'Вдвоём матч до 100 очков, при трёх и более игроках — до 200. Раунд выигрывает игрок, сбросивший все карты.';

  @override
  String get rulesUnoCall => 'Когда остаётся одна карта, сразу нажмите «Уно!». Соперники могут поймать вас без «Уно» только через секунду — тогда вы берёте 2 карты.';

  @override
  String get rulesUnoScoring => 'Кто первым сбросил все карты, выигрывает раунд и получает очки за руки соперников: цифры — по номиналу, спецкарты — 20, чёрные — 50. Вдвоём матч до 100, при трёх и более игроках — до 200.';

  @override
  String get unoColorRed => 'Красный';

  @override
  String get unoColorYellow => 'Жёлтый';

  @override
  String get unoColorGreen => 'Зелёный';

  @override
  String get unoColorBlue => 'Синий';

  @override
  String get unoDraw => 'Взять';

  @override
  String get unoKeep => 'Оставить';

  @override
  String get unoSayUno => 'Уно!';

  @override
  String get unoChallengeUno => 'Поймать без Уно';

  @override
  String get unoChallengeWd4 => 'Оспорить +4';

  @override
  String get unoChooseColor => 'Выберите цвет';

  @override
  String get unoDrawPile => 'Колода';

  @override
  String get unoDiscardPile => 'Сброс';

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
  String get unoYourTurn => 'Ваш ход';

  @override
  String get unoWaitingTurn => 'Ход соперника';

  @override
  String get unoChooseColorHint => 'Выберите цвет для чёрной карты';

  @override
  String get unoWd4Hint => 'Возьмите 4 карты или оспорьте Wild +4';

  @override
  String get unoDrawnHint => 'Сыграйте взятую карту или оставьте её';

  @override
  String get unoPlayHint => 'Сыграйте карту по цвету или значению';

  @override
  String get unoDrawHint => 'Подходящей карты нет — возьмите из колоды';

  @override
  String unoPendingDraw(int count) {
    return '+$count карт';
  }

  @override
  String get unoYouWon => 'Вы выиграли матч!';

  @override
  String get unoYouLost => 'Матч окончен';

  @override
  String get unoYouLostTimeout => 'Вы проиграли по времени';

  @override
  String unoWinner(String name) {
    return 'Победитель: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name выигрывает раунд';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'Далее';

  @override
  String get unoRoundScoresTitle => 'Очки за раунд';

  @override
  String get unoDirectionClockwise => 'По часовой стрелке';

  @override
  String get unoDirectionCounterclockwise => 'Против часовой стрелки';

  @override
  String get unoErrStackSameOnly => 'На +2 можно ответить только +2, на +4 — только +4. +2 на +4 класть нельзя.';

  @override
  String get unoErrCatchTooEarly => 'Подождите секунду — они ещё могут сказать «Уно».';

  @override
  String get unoErrCallTooLate => 'Сказать «Уно» уже нельзя: следующий игрок уже сходил.';

  @override
  String get gamesInDevelopment => 'В разработке';

  @override
  String rulesPokerPlayers(int players) {
    return 'Игроки: $players.';
  }

  @override
  String get rulesPokerIntro => 'Техасский холдем. Каждому раздают 2 карты в руку; на стол выходят 5 общих карт.';

  @override
  String get rulesPokerPlay => 'Раунды ставок: префлоп, флоп, тёрн и ривер. Можно фолд, колл, бет или рейз.';

  @override
  String get rulesPokerWin => 'Побеждает лучшая комбинация из пяти карт (свои + общие) или тот, кто остался один после фолдов.';

  @override
  String get pokerFold => 'Фолд';

  @override
  String get pokerCheck => 'Чек';

  @override
  String pokerCall(int amount) {
    return 'Колл $amount';
  }

  @override
  String get pokerCallShort => 'Колл';

  @override
  String get pokerRaise => 'Рейз';

  @override
  String pokerRaiseTo(int amount) {
    return 'Рейз до $amount';
  }

  @override
  String get pokerRaiseTitle => 'Рейз';

  @override
  String get pokerAllIn => 'Ва-банк';

  @override
  String get pokerAllInBadge => 'Ва-банк';

  @override
  String get pokerFolded => 'Пас';

  @override
  String pokerPot(int amount) {
    return 'Банк: $amount';
  }

  @override
  String get pokerYourTurn => 'Ваш ход';

  @override
  String pokerToAct(String name) {
    return 'Ходит $name';
  }

  @override
  String pokerWinner(String name) {
    return 'Выиграл $name';
  }

  @override
  String get pokerYouWonHand => 'Вы забрали банк!';

  @override
  String pokerWinners(String names) {
    return 'Выиграли $names';
  }

  @override
  String pokerYouWonHandWith(String names) {
    return 'Вы и $names забрали банк!';
  }

  @override
  String get pokerListAnd => 'и';

  @override
  String get pokerHandOver => 'Раздача окончена';

  @override
  String get pokerStreetPreflop => 'Префлоп';

  @override
  String get pokerStreetFlop => 'Флоп';

  @override
  String get pokerStreetTurn => 'Тёрн';

  @override
  String get pokerStreetRiver => 'Ривер';

  @override
  String get pokerStreetShowdown => 'Вскрытие';

  @override
  String get pokerHandHighCard => 'Старшая карта';

  @override
  String get pokerHandOnePair => 'Пара';

  @override
  String get pokerHandTwoPair => 'Две пары';

  @override
  String get pokerHandThreeOfAKind => 'Тройка';

  @override
  String get pokerHandStraight => 'Стрит';

  @override
  String get pokerHandFlush => 'Флеш';

  @override
  String get pokerHandFullHouse => 'Фулл-хаус';

  @override
  String get pokerHandFourOfAKind => 'Каре';

  @override
  String get pokerHandStraightFlush => 'Стрит-флеш';

  @override
  String get pokerHandRoyalFlush => 'Роял-флеш';

  @override
  String get pokerCombinationsTitle => 'Комбинации';

  @override
  String pokerHandNumber(int n) {
    return 'Раздача $n';
  }

  @override
  String pokerBlinds(int sb, int bb) {
    return 'Блайнды $sb/$bb';
  }

  @override
  String get pokerTableYouWon => 'Вы выиграли стол!';

  @override
  String get pokerNextHandSoon => 'Следующая раздача…';

  @override
  String get pokerShowCards => 'Показать карты';

  @override
  String get rulesPokerTable => 'Стол играется до победителя — кто соберёт все фишки. Блайнды растут каждые 6–8 раздач: вдвоём — 8, втроём — 7, вчетвером — 6. Банк ставки делится по местам: втроём 1-й забирает 2/3, 2-е место ничего не теряет; вчетвером 1-й — 3/4; впятером 1-й — 3/5; вшестером 1-й — 4/6.';

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
  String get gamesObservation => 'Наблюдение';

  @override
  String get gamesObservationHint => 'Можно смотреть до конца партии';

  @override
  String get gamesFinishCurrentFirst => 'Сначала завершите текущую игру';

  @override
  String get gamesVariantClassic => 'Классика';

  @override
  String get gamesVariantGomoku => 'Гомоку';

  @override
  String get gamesVariantUltimate => 'Ультимейт';

  @override
  String get gamesVariantMulti3 => 'На троих';

  @override
  String get gamesVariantMulti4 => 'На четверых';

  @override
  String get gamesDurakModePodkidnoi => 'Подкидной';

  @override
  String get gamesDurakModePerevodnoi => 'Переводной';

  @override
  String get gamesDurakDeck24 => '24 карты';

  @override
  String get gamesDurakDeck36 => '36 карт';

  @override
  String get gamesDurakDeck52 => '52 карты';

  @override
  String rulesDurakMode(String mode) {
    return 'Режим: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'Игроки: $players. Колода: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Игра против бота, без ставок и лимита времени.';

  @override
  String get rulesDurakAttack => 'Атакующий кладёт карты, защитник бьёт (той же масти старше или козырем). Козырь бьётся только козырем старше.';

  @override
  String get rulesDurakBeat => 'Когда все карты биты — атакующий говорит «Бито», карты уходят в отбой. Иначе защитник берёт всё со стола.';

  @override
  String get rulesDurakLoser => 'Проигравший — у кого в конце партии остались карты, «дурак».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Игроки $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Лобби $name';
  }

  @override
  String get lobbyMatchmake => 'Лобби';

  @override
  String get lobbyPrivateGame => 'Своя игра';

  @override
  String get lobbySearchingOpponent => 'Поиск соперника…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Ищут эту игру: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Ждём, пока кто-то нажмёт «Найти игру» или «Присоединиться»';

  @override
  String get lobbyInviteTitle => 'Приглашение в игру';

  @override
  String get lobbyInvitedToPlay => 'Вас пригласили сыграть';

  @override
  String get lobbyEnterGame => 'Войти в игру';

  @override
  String get lobbyGone => 'Этой игры уже нет';

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
  String get gameYouLost => 'Вы проиграли';

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
  String get gameSurrender => 'Сдаться';

  @override
  String get gameSurrenderTitle => 'Сдаться?';

  @override
  String get gameSurrenderConfirm => 'Если вы сдадитесь, вы проиграете. Сдаться?';

  @override
  String get gameOfferDraw => 'Предложить ничью';

  @override
  String get gameOfferDrawTitle => 'Предложить ничью?';

  @override
  String get gameOfferDrawConfirm => 'Отправить сопернику предложение ничьей?';

  @override
  String get gameAcceptDrawTitle => 'Принять ничью?';

  @override
  String get gameAcceptDrawConfirm => 'Соперник предлагает ничью. Принять?';

  @override
  String get gameDrawOffered => 'Ожидание ответа';

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
  String get chatPaste => 'Вставить';

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
  String get friendsSearchNoMatches => 'Нет друзей, удовлетворяющих поиску';

  @override
  String get friendsIncomingSearchNoMatches => 'Нет входящих заявок по запросу';

  @override
  String get friendsOutgoingSearchNoMatches => 'Нет исходящих заявок по запросу';

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
  String get profileChangePhoto => 'Поменять аватар';

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
  String get shopStakesSubtitle => 'Разблокировка повышенных ставок';

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

  @override
  String get balanceTitle => 'Баланс';

  @override
  String get coinBronze => 'Бронза';

  @override
  String get coinSilver => 'Серебро';

  @override
  String get coinGold => 'Золото';

  @override
  String get coinDiamond => 'Бриллиант';

  @override
  String get balanceZeroBronze => '0 бронзовых';

  @override
  String balanceBronzes(int count) {
    return '$count бронзовых';
  }

  @override
  String balanceSilvers(int count) {
    return '$count серебряных';
  }

  @override
  String balanceGolds(int count) {
    return '$count золотых';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count бриллиантов';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/день';
  }

  @override
  String get balanceAbbrBronze => 'бр';

  @override
  String get balanceAbbrSilver => 'с.';

  @override
  String get balanceAbbrGold => 'з.';

  @override
  String get commonBackHome => 'Назад на главную';

  @override
  String get commonCopied => 'Скопировано';

  @override
  String get commonClear => 'Очистить';

  @override
  String get commonTryLater => 'Попробуйте позже.';

  @override
  String get commonTryRefresh => 'Попробуйте обновить страницу.';

  @override
  String get coinsTitle => 'Монеты';

  @override
  String get coinsLoginReward => 'Монеты за вход';

  @override
  String get coinsLoginAvailableToday => 'Доступна награда за сегодня';

  @override
  String get coinsLoginStreak => 'Ежедневная серия входов';

  @override
  String get coinsFriendReward => 'Монеты за друга';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount за регистрацию по ссылке';
  }

  @override
  String get coinsLoadRewardsFailed => 'Не удалось загрузить награды';

  @override
  String get coinsClaimReward => 'Забрать награду';

  @override
  String get coinsAlreadyClaimed => 'Уже получено';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · сегодня';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · ещё 1 день';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · ещё $remaining';
  }

  @override
  String get coinsInviteFriend => 'Пригласи друга';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount за каждого, кто зарегистрируется по вашей ссылке';
  }

  @override
  String get coinsCopyLink => 'Скопировать ссылку';

  @override
  String get coinsHowItWorks => 'Как это работает';

  @override
  String get coinsHowStep1 => 'Скопируйте ссылку и отправьте другу';

  @override
  String get coinsHowStep2 => 'Друг регистрируется по этой ссылке';

  @override
  String coinsHowStep3(String amount) {
    return 'Вам начисляется $amount';
  }

  @override
  String get achievementsTitle => 'Достижения';

  @override
  String achievementsProgress(String progress) {
    return 'Прогресс: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Рамка получена';

  @override
  String get achievementsClaimed => 'Получено';

  @override
  String get achievementsOpenFrame => 'Открыть рамку';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Вы уверены, что хотите удалить $name из друзей?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Убрать';

  @override
  String get friendsRemove => 'Удалить из друзей';

  @override
  String get friendsAcceptRequest => 'Принять заявку';

  @override
  String get friendsDeclineRequest => 'Отклонить заявку';

  @override
  String get friendsCancelRequest => 'Отменить заявку';

  @override
  String get friendsSendRequest => 'Отправить заявку в друзья';

  @override
  String get friendsRequestAlreadySent => 'Заявка уже отправлена';

  @override
  String get friendsIncomingStatus => 'Входящая заявка';

  @override
  String get friendsOutgoingStatus => 'Исходящая заявка';

  @override
  String get friendsNotFriends => 'Не в друзьях';

  @override
  String get friendsCollapseSearch => 'Свернуть поиск';

  @override
  String get friendsExpandSearch => 'Показать поиск';

  @override
  String get friendsLoadFailed => 'Не удалось загрузить друзей';

  @override
  String friendsSince(String date) {
    return 'Дружите с: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Входящая заявка: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Исходящая заявка: $date';
  }

  @override
  String get userInfoTitle => 'Информация о пользователе';

  @override
  String profileAgeYears(int age) {
    return '$age лет';
  }

  @override
  String get shopBuy => 'Купить';

  @override
  String get shopBuyTitle => 'Купить?';

  @override
  String get shopBuyStakeTitle => 'Купить ставку?';

  @override
  String get shopBuyEmojiTitle => 'Купить смайлик?';

  @override
  String get shopBuyCollectionTitle => 'Купить коллекцию?';

  @override
  String shopPrice(String price) {
    return 'Цена: $price';
  }

  @override
  String get shopOwned => 'Куплено';

  @override
  String get shopEmpty => 'Пока пусто';

  @override
  String shopPurchased(String title) {
    return '$title куплен';
  }

  @override
  String get shopEmojiUses => 'Получите: 10 использований';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 использований';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 использований';
  }

  @override
  String get shopBuyTen => 'Купить · 10 шт.';

  @override
  String shopDailyIncome(String amount) {
    return 'Доход: $amount';
  }

  @override
  String get shopBuyOnce => 'Покупка один раз';

  @override
  String get shopSellRefund => 'Продажа вернет 80% стоимости';

  @override
  String shopCollectionAdded(String title) {
    return '$title добавлен в профиль';
  }

  @override
  String shopSetBonus(int percent) {
    return 'бонус группы +$percent%';
  }

  @override
  String get shopSetComplete => 'Собрано';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Собрано · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Продать?';

  @override
  String inventorySellDesc(String amount) {
    return 'Вы получите $amount';
  }

  @override
  String inventorySold(String amount) {
    return 'Продано: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Сначала добавьте друзей';

  @override
  String get inventoryGiftTitle => 'Подарить коллекцию?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'Подарить «$title» пользователю $name?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Подарено: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'У этого пользователя уже есть эта коллекция';

  @override
  String get inventoryGiftSelf => 'Нельзя подарить коллекцию самому себе';

  @override
  String get inventoryGiftNotOwned => 'У вас нет этого предмета';

  @override
  String get inventoryLoadFailed => 'Не удалось загрузить предметы';

  @override
  String get inventoryNoCollections => 'Нет коллекций — купите в магазине';

  @override
  String get inventoryNoEmojis => 'Нет смайликов — купите в магазине';

  @override
  String get inventoryNoFrames => 'Нет рамок — выиграйте 10 игр в лиге (достижения)';

  @override
  String get inventoryNoStakes => 'Нет купленных ставок';

  @override
  String inventoryEmojiLeft(int count) {
    return 'Осталось $count';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Доход: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Доход завтра: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Доход:';

  @override
  String get inventoryIncomeTomorrowLabel => 'Доход завтра:';

  @override
  String inventoryStakeGold(String amount) {
    return 'Можно ставить $amount золота';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'Можно ставить $amount серебра';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'Получено +$amount';
  }

  @override
  String get chatsLoadFailed => 'Не удалось загрузить чаты';

  @override
  String get chatsLoadListFailed => 'Не удалось загрузить список';

  @override
  String get chatsBlockedEmpty => 'Список пуст';

  @override
  String chatsBlockedAt(String date) {
    return 'Заблокирован: $date';
  }

  @override
  String get chatsCreateFailed => 'Не удалось создать чат';

  @override
  String get chatsNeedFriendsFirst => 'Сначала добавьте друзей, потом можно открыть чат.';

  @override
  String get chatsFriendsNotFound => 'Друзья не найдены';

  @override
  String get chatsFindFriendHint => 'Найти друга по нику';

  @override
  String get chatsSelectChat => 'Выберите чат';

  @override
  String get chatsSelectHint => 'Выберите диалог из списка слева';

  @override
  String get chatEditFailed => 'Не удалось изменить сообщение';

  @override
  String get chatSendFailed => 'Не удалось отправить сообщение';

  @override
  String get chatDeleteFailed => 'Не удалось удалить сообщение';

  @override
  String get chatEmojiSendFailed => 'Не удалось отправить смайлик';

  @override
  String get chatLoadFailed => 'Не удалось загрузить сообщения';

  @override
  String get chatBackToGame => 'Назад в игру';

  @override
  String get chatBackToChats => 'Назад к чатам';

  @override
  String get chatActions => 'Действия с чатом';

  @override
  String get chatAutoTranslate => 'Автоперевод';

  @override
  String get chatScrollToEnd => 'В конец переписки';

  @override
  String chatReplyingTo(String name) {
    return 'В ответ $name';
  }

  @override
  String get chatGift => 'Подарок';

  @override
  String get chatCollection => 'Коллекция';

  @override
  String get chatGiftCollection => 'Подарок · коллекция';

  @override
  String get chatThisUser => 'этого пользователя';

  @override
  String get gamesLobbyLoadFailed => 'Не удалось загрузить лобби.';

  @override
  String get gamesTapChangeStake => 'Нажмите для смены ставки';

  @override
  String get gamesTapChangeTurnTime => 'Нажмите для смены времени на ход';

  @override
  String get gamesTapChangeGrid => 'Нажмите для смены размера сетки';

  @override
  String get gamesSwapSidesHint => 'O может стать X после 1-го хода';

  @override
  String get gamesNoCenterHint => 'Первый ход не в центр';

  @override
  String get lobbyInviteSentShort => 'Отправлено';

  @override
  String get lobbySearchShort => 'Поиск';

  @override
  String get lobbySearchPlayers => 'Поиск игроков';

  @override
  String get lobbyInviteDeclinedShort => 'Отказ';

  @override
  String get lobbyInvitesSentWaiting => 'Приглашения отправлены. Ожидайте ответа.';

  @override
  String get lobbyLinkCopiedHint => 'Вставьте её в чат или сообщение другу';

  @override
  String get lobbyCopyLinkHint => 'Скопировать ссылку в буфер обмена';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name приглашает вас сыграть';
  }

  @override
  String gameOpponentWon(String name) {
    return 'Победил $name';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Время вышло. Победил $name';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds с';
  }

  @override
  String get adminTitle => 'Админка';

  @override
  String get tournamentsTitle => 'Турниры';

  @override
  String get profileAgeInvalid => 'Введите возраст от 1 до 111';

  @override
  String get profileSaveFailed => 'Не удалось сохранить профиль';

  @override
  String get profileNameHint => 'Латиница, цифры, _ до 10 символов';

  @override
  String get profileNameLatinOnly => 'Только латинские символы';

  @override
  String get profileAgeHint => 'От 1 до 111';

  @override
  String get profileAboutHint => 'До 100 символов (по желанию)';

  @override
  String get profileProcessingPhoto => 'Обработка фото…';

  @override
  String get profileCropTitle => 'Выбери область аватара';

  @override
  String get profileCropHint => 'Масштабируй и двигай фото';

  @override
  String get profileApply => 'Применить';

  @override
  String get profilePreparing => 'Подготовка…';

  @override
  String get profileGalleryTitle => 'Фото';

  @override
  String get profileGalleryAdd => 'Добавить фото';

  @override
  String get profileMakePrimary => 'Сделать основным';

  @override
  String get profilePhotoDelete => 'Удалить фото';

  @override
  String get profilePhotosLimit => 'Можно загрузить не больше 3 фото';

  @override
  String get profilePhotosEmpty => 'Пока нет фото';

  @override
  String get profilePhotoUploadFailed => 'Не удалось загрузить фото';

  @override
  String get profilePhotoDeleteFailed => 'Не удалось удалить фото';

  @override
  String get profilePhotoTooLarge => 'Фото слишком большое';

  @override
  String get profileSetPrimaryFailed => 'Не удалось сделать основным';

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
    return 'Крестики-нолики на поле $grid. Ходят по очереди, X начинает.';
  }

  @override
  String rulesWin(int n) {
    return 'Победа: нужно выстроить $n в ряд по горизонтали, вертикали или диагонали.';
  }

  @override
  String get rulesNoTimeLimit => 'Без ограничения по времени на ход.';

  @override
  String rulesTurnTime(String time) {
    return 'Время на ход: $time. Если время вышло — проигрыш.';
  }

  @override
  String rulesStake(String stake) {
    return 'Ставка: $stake. На столько монет идёт игра.';
  }

  @override
  String get rulesSwap => 'Смена сторон: O может поменяться местами с X после первого хода X.';

  @override
  String get rulesNoCenter => 'Запрет центра: X не может ходить в центр первым ходом.';

  @override
  String get collectionSetLegends => 'Легенды';

  @override
  String get collectionSetSpace => 'Космос';

  @override
  String get collectionSetGems => 'Драгоценности';

  @override
  String get collectionSetParty => 'Праздник';

  @override
  String get collectionSetNature => 'Природа';

  @override
  String get collectionSetAdventures => 'Приключения';

  @override
  String collectionCardMeta(String amount) {
    return 'Коллекция · витрина · подарок · продажа · +$amount';
  }

  @override
  String get coinsDayOne => 'день';

  @override
  String get coinsDayFew => 'дня';

  @override
  String get coinsDayMany => 'дней';

  @override
  String get giftFriendTitle => 'Подарить другу';

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
    return '$count смайликов · по $price';
  }

  @override
  String get chatsExpandPanel => 'Развернуть панель';

  @override
  String get chatsCollapsePanel => 'Свернуть панель';

  @override
  String get chatReplySourceMissing => 'Исходное сообщение не найдено';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Ставка $n серебра';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Ставка $n золота';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Право ставить $n серебра в играх';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Право ставить $n золота в играх';
  }

  @override
  String get chatReplySelf => 'себе';

  @override
  String get chatReplyPeer => 'собеседнику';

  @override
  String get verifyEmailTitle => 'Подтверждение email';

  @override
  String verifyEmailSubtitle(String email) {
    return 'Мы отправили код на $email';
  }

  @override
  String get verifyEmailCodeLabel => 'Код из письма';

  @override
  String get verifyEmailCodeRequired => 'Введите код';

  @override
  String get verifyEmailSubmit => 'Подтвердить';

  @override
  String get verifyEmailResend => 'Отправить код ещё раз';

  @override
  String get verifyEmailResent => 'Новый код отправлен';

  @override
  String get oauthOrContinue => 'или войти через';

  @override
  String get oauthGoogle => 'Google';

  @override
  String get oauthApple => 'Apple';

  @override
  String get oauthYandex => 'Яндекс';

  @override
  String get oauthVK => 'VK';

  @override
  String get oauthError => 'Не удалось войти через сервис';

  @override
  String get oauthCallbackTitle => 'Вход…';

  @override
  String verifyEmailResendIn(String time) {
    return 'Отправить код ещё раз через $time';
  }

  @override
  String verifyEmailDevCodeHint(String code) {
    return 'Почта ещё не настроена на сервере. Код для входа: $code';
  }

  @override
  String get loginForgotPassword => 'Забыли пароль?';

  @override
  String get forgotPasswordTitle => 'Сброс пароля';

  @override
  String get forgotPasswordSubtitle => 'Введите email или логин — пришлём код на почту аккаунта';

  @override
  String get forgotPasswordSubmit => 'Отправить код';

  @override
  String get forgotPasswordSent => 'Если аккаунт существует, код отправлен на почту';

  @override
  String get resetPasswordTitle => 'Новый пароль';

  @override
  String resetPasswordSubtitle(String email) {
    return 'Код отправлен на $email';
  }

  @override
  String get resetPasswordCodeLabel => 'Код из письма';

  @override
  String get resetPasswordCodeRequired => 'Введите код';

  @override
  String get resetPasswordNewLabel => 'Новый пароль';

  @override
  String get resetPasswordNewRequired => 'Введите новый пароль';

  @override
  String get resetPasswordNewShort => 'Минимум 6 символов';

  @override
  String get resetPasswordConfirmLabel => 'Повторите пароль';

  @override
  String get resetPasswordConfirmMismatch => 'Пароли не совпадают';

  @override
  String get resetPasswordSubmit => 'Сохранить пароль';

  @override
  String get resetPasswordResend => 'Отправить код ещё раз';

  @override
  String get resetPasswordResent => 'Новый код отправлен';

  @override
  String resetPasswordResendIn(String time) {
    return 'Отправить код ещё раз через $time';
  }

  @override
  String get resetPasswordBackToLogin => 'Вернуться ко входу';

  @override
  String get statsTitle => 'Статистика';

  @override
  String get statsLoadFailed => 'Не удалось загрузить статистику';

  @override
  String get statsAllGames => 'Все игры';

  @override
  String get statsEmptyTitle => 'Пока нет сыгранных партий';

  @override
  String get statsEmptyHint => 'Сыграйте первую игру, чтобы здесь появилась статистика.';

  @override
  String get statsWins => 'Победы';

  @override
  String get statsDraws => 'Ничьи';

  @override
  String get statsLosses => 'Поражения';

  @override
  String get statsWinRate => 'Процент побед';

  @override
  String get statsTopWon => 'Больше всего выиграл у';

  @override
  String get statsTopDrawn => 'Больше всего ничьих с';

  @override
  String get statsTopLost => 'Больше всего проиграл';

  @override
  String get statsTimePlayed => 'Время в игре';

  @override
  String get statsYourScore => 'Ваш счёт';

  @override
  String get profileShowStats => 'Показывать статистику';

  @override
  String get statsDurationZeroMinutes => '0 мин';

  @override
  String get gameYouWonOpponentForfeit => 'Соперник сдался. Вы победили!';

  @override
  String get lobbyLeaveTitle => 'Покинуть лобби?';

  @override
  String get lobbyLeaveConfirm => 'Лобби будет удалено после выхода. Приглашённые друзья получат отказ.';

  @override
  String get lobbyLeave => 'Покинуть';

  @override
  String statsDurationHours(int hours) {
    return '$hours ч';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'Вы сдались. $name победил';
  }

  @override
  String get supportTitle => 'Поддержка';

  @override
  String get supportUnavailable => 'Поддержка недоступна';

  @override
  String get supportOpenFailed => 'Не удалось открыть чат с поддержкой';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Вам начислено $amount монет';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return 'Списано $amount монет';
  }

  @override
  String get coinsCreditCardTitle => 'Вам начислены монеты';

  @override
  String get coinsClaim => 'Забрать';

  @override
  String get durakActionPass => 'Пас';

  @override
  String get durakRoleTook => 'Забрал';

  @override
  String get durakRoleBeats => 'Бьёт';

  @override
  String get durakRoleThrowIn => 'Подкид';

  @override
  String get durakRoleTurn => 'Ход';

  @override
  String get durakRoleDefends => 'Отбивается';

  @override
  String get durakStatusTaking => 'Беру';

  @override
  String get durakHintDefenderTurn => 'Ход защитника';

  @override
  String get gameYouEliminated => 'Вы выбыли';

  @override
  String gameYouPlaced(int place) {
    return 'Вы заняли $place-е место';
  }

  @override
  String get gameOverNeutral => 'Партия окончена';

  @override
  String gameTurnOf(String name) {
    return 'Ход $name';
  }

  @override
  String get chatGroupTooltip => 'Чат группы';

  @override
  String get lobbyChatNotReady => 'Чат лобби ещё не создан';

  @override
  String get chatsGroupChat => 'Групповой чат';

  @override
  String chatsMembersCount(int count) {
    return 'Участники: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count уч.';
  }

  @override
  String get chatsYouSuffix => '(вы)';

  @override
  String get chatTitleDurak3 => 'Дурак на троих';

  @override
  String get chatTitleDurak4 => 'Дурак на четверых';

  @override
  String get rulesTttUltimate => 'Ультимейт: 9 мини-полей 3×3. Ход в клетку отправляет соперника в соответствующее мини-поле. Выигрывает тот, кто собрал линию на мета-поле.';

  @override
  String get rulesTttMulti3 => 'На троих: поле 3×3, трое игроков (X, O, △). Кто собрал линию из своих знаков — побеждает.';

  @override
  String get rulesTttMulti4 => 'На четверых: поле 4×4, четверо игроков (X, O, △, □). Кто собрал линию из своих знаков — побеждает.';
}
