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
  String get settingsAddBotsTitle => 'Дадаваць ботаў праз 30 с';

  @override
  String get settingsAddBotsSubtitle => 'У рэжыме пошуку гульні: калі супернік не знойдзены за 30 секунд, гульня пачынаецца з ботам (стаўка скідаецца да 1 бронзы)';

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
  String get timeJustNow => 'толькі што';

  @override
  String get timeYesterday => 'учора';

  @override
  String timeMinutesAgo(Object count) {
    return '$count хв таму';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count гадз таму';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count дз. таму';
  }

  @override
  String get timeWeekAgo => 'тыдзень таму';

  @override
  String timeWeeksAgo(Object count) {
    return '$count тыд. таму';
  }

  @override
  String get timeMonthAgo => 'месяц таму';

  @override
  String timeMonthsAgo(Object count) {
    return '$count мес. таму';
  }

  @override
  String get timeYearAgo => 'год таму';

  @override
  String timeYearsAgo(Object count) {
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
  String get lobbyMatchmake => 'Лобі';

  @override
  String get lobbyPrivateGame => 'Прыватная гульня';

  @override
  String get lobbySearchingOpponent => 'Пошук суперніка…';

  @override
  String get lobbyWaitingJoin => 'Чакаем, пакуль хтосьці націсне «Знайсці гульню» або «Далучыцца»';

  @override
  String get lobbyInviteTitle => 'Запрашэнне ў гульню';

  @override
  String get lobbyInvitedToPlay => 'Вас запрасілі згуляць';

  @override
  String get lobbyEnterGame => 'Увайсці ў гульню';

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
  String get gameYouWon => 'Вы перамаглі!';

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
  String get profileChangePhoto => 'Змяніць фота';

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
  String get shopStakesSubtitle => 'Разблакіруйце срэбныя стаўкі';

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
}
