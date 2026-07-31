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
  String get gameSurrender => 'Сдаться';

  @override
  String get gameSurrenderTitle => 'Сдаться?';

  @override
  String get gameSurrenderConfirm => 'Если вы сдадитесь, вы проиграете. Сдаться?';

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
    return '$amount у дзень';
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
  String get shopSellRefund => 'Продаж верне частку кошту';

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
  String get inventoryGiftAlreadyOwns => 'У этого пользователя уже есть эта коллекция';

  @override
  String get inventoryGiftSelf => 'Нельзя подарить коллекцию самому себе';

  @override
  String get inventoryGiftNotOwned => 'У вас нет этого предмета';

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
    return 'Час на ход: $time.';
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
}
