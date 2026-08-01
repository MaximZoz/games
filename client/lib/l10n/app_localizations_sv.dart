import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Hem';

  @override
  String get navProfile => 'Profil';

  @override
  String get navFriends => 'Vänner';

  @override
  String get navChats => 'Chattar';

  @override
  String get navGames => 'Spel';

  @override
  String get navSettings => 'Inställningar';

  @override
  String get settingsTitle => 'Inställningar';

  @override
  String get settingsLanguage => 'Språk';

  @override
  String get settingsLanguageSystem => 'Systemets standard';

  @override
  String get settingsAddBotsTitle => 'Lägg till bottar efter 30 s';

  @override
  String get settingsAddBotsSubtitle => 'Vid matchning: om ingen motståndare hittas inom 30 sekunder startar spelet med en bot (insatsen återställs till 1 brons)';

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
  String get settingsFriendsOnlyTitle => 'Meddelanden endast från vänner';

  @override
  String get settingsFriendsOnlySubtitle => 'Icke-vänner kan bara skicka emojis. Vid spam, blockera användaren tillfälligt.';

  @override
  String get settingsNotifications => 'Aviseringar';

  @override
  String get settingsPushChat => 'Chatt';

  @override
  String get settingsPushFriends => 'Vänner';

  @override
  String get settingsPushGames => 'Spel';

  @override
  String get settingsPushRewards => 'Belöningar';

  @override
  String get loginTitle => 'Logga in';

  @override
  String get loginSubtitle => 'Ange e-post eller användarnamn och lösenord';

  @override
  String get loginEmailLabel => 'E-post eller användarnamn';

  @override
  String get loginPasswordLabel => 'Lösenord';

  @override
  String get loginSubmit => 'Logga in';

  @override
  String get loginNoAccount => 'Inget konto? Registrera dig';

  @override
  String get loginEmailRequired => 'Ange e-post eller användarnamn';

  @override
  String get loginPasswordRequired => 'Ange lösenord';

  @override
  String get loginTooltip => 'Logga in';

  @override
  String get logoutTooltip => 'Logga ut';

  @override
  String get registerTitle => 'Registrera dig';

  @override
  String get registerSubtitle => 'Skapa ett konto för att spela';

  @override
  String get registerNameLabel => 'Namn (användarnamn)';

  @override
  String get registerEmailLabel => 'E-post';

  @override
  String get registerPasswordLabel => 'Lösenord';

  @override
  String get registerSubmit => 'Registrera dig';

  @override
  String get registerHaveAccount => 'Har du redan ett konto? Logga in';

  @override
  String get registerNameRequired => 'Ange ett namn';

  @override
  String get registerNameNoSpaces => 'Namnet får inte innehålla mellanslag';

  @override
  String get registerNameMax => 'Högst 20 tecken';

  @override
  String get registerNameHint => 'Upp till 20 tecken';

  @override
  String get registerEmailRequired => 'Ange e-post';

  @override
  String get registerEmailInvalid => 'Ogiltig e-post';

  @override
  String get registerPasswordHint => 'Minst 6 tecken';

  @override
  String get registerPasswordMin => 'Lösenordet måste vara minst 6 tecken';

  @override
  String get commonCancel => 'Avbryt';

  @override
  String get commonSave => 'Spara';

  @override
  String get commonDelete => 'Radera';

  @override
  String get commonEdit => 'Redigera';

  @override
  String get commonReply => 'Svara';

  @override
  String get commonSend => 'Skicka';

  @override
  String get commonClose => 'Stäng';

  @override
  String get commonRetry => 'Försök igen';

  @override
  String get commonLoading => 'Laddar…';

  @override
  String get commonError => 'Fel';

  @override
  String get commonOnline => 'online';

  @override
  String get commonOffline => 'offline';

  @override
  String get commonOnlineCap => 'Online';

  @override
  String get commonUser => 'Användare';

  @override
  String get commonPlayer => 'Spelare';

  @override
  String get commonAboutMe => 'Om mig';

  @override
  String get commonBack => 'Tillbaka';

  @override
  String get commonAccept => 'Acceptera';

  @override
  String get commonDecline => 'Avböj';

  @override
  String get commonCreating => 'Skapar…';

  @override
  String get commonSearching => 'Söker…';

  @override
  String get commonInsufficientCoins => 'Inte tillräckligt med mynt';

  @override
  String get commonNotFound => 'Hittades inte';

  @override
  String get commonServerErrorShort => 'Serverfel';

  @override
  String get commonForbidden => 'Åtkomst nekad';

  @override
  String get commonUserBlocked => 'Användaren är blockerad';

  @override
  String get commonUserNotFound => 'Användaren hittades inte';

  @override
  String get commonGenericError => 'Något gick fel. Försök igen.';

  @override
  String get timeJustNow => 'just nu';

  @override
  String get timeYesterday => 'igår';

  @override
  String timeMinutesAgo(int count) {
    return '$count min sedan';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count h sedan';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count d sedan';
  }

  @override
  String get timeWeekAgo => 'en vecka sedan';

  @override
  String timeWeeksAgo(int count) {
    return '$count v sedan';
  }

  @override
  String get timeMonthAgo => 'en månad sedan';

  @override
  String timeMonthsAgo(int count) {
    return '$count mån sedan';
  }

  @override
  String get timeYearAgo => 'ett år sedan';

  @override
  String timeYearsAgo(int count) {
    return '$count år sedan';
  }

  @override
  String get weekdaySun => 'Sön';

  @override
  String get weekdayMon => 'Mån';

  @override
  String get weekdayTue => 'Tis';

  @override
  String get weekdayWed => 'Ons';

  @override
  String get weekdayThu => 'Tor';

  @override
  String get weekdayFri => 'Fre';

  @override
  String get weekdaySat => 'Lör';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'Maj';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Okt';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get homeAchievements => 'Prestationer';

  @override
  String get homeAchievementsSubtitle => 'Dina spelresultat';

  @override
  String get homeAchievementsRewards => 'Belöningar att hämta';

  @override
  String get homeCoins => 'Mynt';

  @override
  String get homeCoinsSubtitle => 'Saldo och belöningar';

  @override
  String get homeCoinsDailyReward => 'Daglig inloggningsbelöning tillgänglig';

  @override
  String get homeItems => 'Föremål';

  @override
  String get homeItemsInventory => 'Din inventarie';

  @override
  String get homeItemsGifted => 'Någon gav dig en samling';

  @override
  String get homeItemsIncome => 'Samlingsintäkter klara att hämta';

  @override
  String get homeShop => 'Butik';

  @override
  String get homeShopSubtitle => 'Emojis, insatser, samlingar';

  @override
  String get gamesTitle => 'Spel';

  @override
  String get gamesFindMatch => 'Hitta ett spel';

  @override
  String get gamesMyTurn => 'Din tur';

  @override
  String get gamesWaiting => 'Väntar';

  @override
  String get gamesLobbyTab => 'Lobby';

  @override
  String get gamesTicTacToe => 'Luffarschack';

  @override
  String get gamesRules => 'Regler';

  @override
  String get gamesRulesTitle => 'Spelregler';

  @override
  String get gamesCreate => 'Skapa spel';

  @override
  String get gamesJoin => 'Gå med';

  @override
  String get gamesOpponentTurn => 'Motståndarens tur';

  @override
  String get gamesCurrentGame => 'Pågående spel';

  @override
  String get gamesInvitedYou => 'Du blev inbjuden';

  @override
  String get gamesTurnTime => 'Tid per tur';

  @override
  String get gamesGridSize => 'Rutnätsstorlek';

  @override
  String get gamesSwapSides => 'Sidbyte';

  @override
  String get gamesNoCenter => 'Ingen start i mitten';

  @override
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Privat spel';

  @override
  String get lobbySearchingOpponent => 'Söker motståndare…';

  @override
  String get lobbyWaitingJoin => 'Väntar på att någon trycker på ”Hitta ett spel” eller ”Gå med”';

  @override
  String get lobbyInviteTitle => 'Spelinbjudan';

  @override
  String get lobbyInvitedToPlay => 'Du har blivit inbjuden att spela';

  @override
  String get lobbyEnterGame => 'Gå in i spelet';

  @override
  String get lobbyGone => 'Этой игры уже нет';

  @override
  String get lobbyInvite => 'Bjud in';

  @override
  String get lobbyInviteSent => 'Inbjudan skickad';

  @override
  String get lobbyCopyLink => 'Dela spellänk';

  @override
  String get lobbyLinkCopied => 'Länk kopierad';

  @override
  String get lobbyNoFriendsOnline => 'Inga vänner online. Dela spellänken ovan eller vänta tills vänner kommer online.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Motståndare';

  @override
  String get gameYouWon => 'Du vann!';

  @override
  String get gameYouWonOpponentLeft => 'Du vann — motståndaren lämnade';

  @override
  String get gameYouWonOpponentTimeout => 'Du vann — motståndarens tid tog slut';

  @override
  String get gameDraw => 'Oavgjort';

  @override
  String get gameExitTitle => 'Lämna spelet';

  @override
  String get gameExitConfirm => 'Om du lämnar förlorar du. Lämna ändå?';

  @override
  String get gameStay => 'Stanna';

  @override
  String get gameLeave => 'Lämna';

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
  String get gameConnecting => 'Ansluter till spelet…';

  @override
  String get gameWaitingOpponent => 'Väntar på motståndare';

  @override
  String get gameRematchOffer => 'Motståndaren erbjuder returmatch';

  @override
  String get gameRematchDeclined => 'Motståndaren avböjde returmatchen';

  @override
  String get gameRematch => 'Returmatch';

  @override
  String get gameOtherOpponent => 'Annan motståndare';

  @override
  String get gameSwapSidesAction => 'Byt sida';

  @override
  String get gameWriteMessage => 'Skriv ett meddelande';

  @override
  String get chatsTitle => 'Chattar';

  @override
  String get chatsEmpty => 'Inga chattar ännu.\nTryck på ikonen uppe till höger för att välja en vän och börja chatta.';

  @override
  String get chatsNewChat => 'Ny chatt';

  @override
  String get chatsNoMessages => 'Inga meddelanden';

  @override
  String get chatsClearTitle => 'Rensa konversationen?';

  @override
  String get chatsClearDesc => 'Chatten raderas permanent.';

  @override
  String get chatsClearConfirm => 'Rensa';

  @override
  String get chatsBlockTitle => 'Blockera den här användaren?';

  @override
  String get chatsBlockDesc => 'Ni kan inte längre skicka meddelanden till varandra. Chatten och vänskapen tas bort.';

  @override
  String get chatsBlockConfirm => 'Blockera';

  @override
  String get chatsBlockedUsers => 'Blockerade användare';

  @override
  String get chatsUnblock => 'Avblockera';

  @override
  String get chatDialog => 'Chatt';

  @override
  String get chatEmpty => 'Inga meddelanden ännu.\nSkicka det första.';

  @override
  String get chatMessageHint => 'Meddelande';

  @override
  String get chatPaste => 'Вставить';

  @override
  String get chatEmoji => 'Emojis';

  @override
  String get chatBuyEmojiHint => 'Köp emojis i butiken på startskärmen';

  @override
  String get chatEditing => 'Redigerar';

  @override
  String get chatToday => 'Idag';

  @override
  String get chatYesterday => 'Igår';

  @override
  String get chatFriendsOnly => 'Text endast för vänner';

  @override
  String get emojiGroupEmotions => 'Känslor';

  @override
  String get emojiGroupGame => 'Spel';

  @override
  String get emojiGroupFlags => 'Flaggor';

  @override
  String get emojiGroupAnimals => 'Djur';

  @override
  String get emojiGroupFood => 'Mat';

  @override
  String get emojiGroupTravel => 'Resor';

  @override
  String get emojiGroupParty => 'Fest';

  @override
  String get emojiGroupObjects => 'Föremål';

  @override
  String get friendsTitle => 'Vänner';

  @override
  String get friendsTabFriends => 'Vänner';

  @override
  String get friendsTabIncoming => 'Inkommande';

  @override
  String get friendsTabOutgoing => 'Utgående';

  @override
  String get friendsAdd => 'Lägg till vän';

  @override
  String get friendsRequestSent => 'Förfrågan skickad';

  @override
  String get friendsFindTab => 'Hitta vän';

  @override
  String get friendsSearchHint => 'Sök på användarnamn';

  @override
  String get friendsSearchPrompt => 'Använd sökningen för att hitta nya vänner';

  @override
  String get friendsNothingFound => 'Inget hittades';

  @override
  String get friendsEmpty => 'Du har inga vänner ännu';

  @override
  String get friendsNoIncoming => 'Inga inkommande förfrågningar';

  @override
  String get friendsNoOutgoing => 'Inga utgående förfrågningar';

  @override
  String get friendsAlreadyFriends => 'Redan vänner';

  @override
  String get friendsRemoveTitle => 'Ta bort från vänner?';

  @override
  String get friendsRemoved => 'Borttagen från vänner';

  @override
  String get friendsRequestAccepted => 'Förfrågan accepterad';

  @override
  String get friendsRequestDeclined => 'Förfrågan avböjd';

  @override
  String get friendsRequestCancelled => 'Förfrågan avbruten';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSignInPrompt => 'Logga in på ditt konto';

  @override
  String get profileSignInHint => 'För att ställa in din personliga profil';

  @override
  String get profileEdit => 'Redigera';

  @override
  String get profileCollections => 'Samlingar';

  @override
  String get profileAge => 'Ålder';

  @override
  String get profileGender => 'Kön';

  @override
  String get profileGenderUnset => 'Ej angivet';

  @override
  String get profileGenderMale => 'Man';

  @override
  String get profileGenderFemale => 'Kvinna';

  @override
  String get profileAvatar => 'Avatar';

  @override
  String get profileUploadPhoto => 'Ladda upp foto';

  @override
  String get profileChangePhoto => 'Byt foto';

  @override
  String get shopTitle => 'Butik';

  @override
  String get shopEmojis => 'Emojis';

  @override
  String get shopEmojisSubtitle => 'Animerade emojis för chatt';

  @override
  String get shopCollections => 'Samlingar';

  @override
  String get shopCollectionsSubtitle => 'Profilutställning, presenter och intäkter';

  @override
  String get shopStakes => 'Insatser';

  @override
  String get shopStakesSubtitle => 'Lås upp högre insatser';

  @override
  String get inventoryTitle => 'Föremål';

  @override
  String get inventoryEmpty => 'Inget här ännu — kolla butiken';

  @override
  String get inventoryFrames => 'Ramar';

  @override
  String get inventoryClaim => 'Hämta';

  @override
  String get inventorySell => 'Sälj';

  @override
  String get inventoryGift => 'Ge bort';

  @override
  String get messageEdited => 'redigerat';

  @override
  String get messageDeleted => 'Meddelandet raderades';

  @override
  String get photo => 'Foto';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galleri';

  @override
  String get connectionError => 'Kunde inte ansluta till servern.';

  @override
  String get serverError => 'Serverfel. Försök igen senare.';

  @override
  String get sessionExpired => 'Sessionen har gått ut. Logga in igen.';

  @override
  String get errNoInternet => 'Ingen internetanslutning.';

  @override
  String get errTimeout => 'Begäran tog för lång tid. Försök igen.';

  @override
  String get errGamesUnavailable => 'Spel är tillfälligt otillgängliga';

  @override
  String get errSettingsSaveFailed => 'Kunde inte spara inställningen';

  @override
  String get errPushPermission => 'Tillåt aviseringar i webbläsarens eller systemets inställningar.';

  @override
  String get balanceTitle => 'Saldo';

  @override
  String get coinBronze => 'Brons';

  @override
  String get coinSilver => 'Silver';

  @override
  String get coinGold => 'Guld';

  @override
  String get coinDiamond => 'Diamant';

  @override
  String get balanceZeroBronze => '0 brons';

  @override
  String balanceBronzes(int count) {
    return '$count brons';
  }

  @override
  String balanceSilvers(int count) {
    return '$count silver';
  }

  @override
  String balanceGolds(int count) {
    return '$count guld';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count diamanter';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/dag';
  }

  @override
  String get balanceAbbrBronze => 'br';

  @override
  String get balanceAbbrSilver => 's.';

  @override
  String get balanceAbbrGold => 'g.';

  @override
  String get commonBackHome => 'Tillbaka till startsidan';

  @override
  String get commonCopied => 'Kopierat';

  @override
  String get commonClear => 'Rensa';

  @override
  String get commonTryLater => 'Försök igen senare.';

  @override
  String get commonTryRefresh => 'Prova att uppdatera sidan.';

  @override
  String get coinsTitle => 'Mynt';

  @override
  String get coinsLoginReward => 'Inloggningsbelöning';

  @override
  String get coinsLoginAvailableToday => 'Dagens belöning tillgänglig';

  @override
  String get coinsLoginStreak => 'Daglig inloggningsstreak';

  @override
  String get coinsFriendReward => 'Vänbelöning';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount för registrering via din länk';
  }

  @override
  String get coinsLoadRewardsFailed => 'Kunde inte ladda belöningar';

  @override
  String get coinsClaimReward => 'Hämta belöning';

  @override
  String get coinsAlreadyClaimed => 'Redan hämtad';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · idag';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · 1 dag kvar';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · $remaining kvar';
  }

  @override
  String get coinsInviteFriend => 'Bjud in en vän';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount för varje som registrerar sig via din länk';
  }

  @override
  String get coinsCopyLink => 'Kopiera länk';

  @override
  String get coinsHowItWorks => 'Så fungerar det';

  @override
  String get coinsHowStep1 => 'Kopiera länken och skicka till en vän';

  @override
  String get coinsHowStep2 => 'Vännen registrerar sig via länken';

  @override
  String coinsHowStep3(String amount) {
    return 'Du får $amount';
  }

  @override
  String get achievementsTitle => 'Prestationer';

  @override
  String achievementsProgress(String progress) {
    return 'Framsteg: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Ram hämtad';

  @override
  String get achievementsClaimed => 'Hämtad';

  @override
  String get achievementsOpenFrame => 'Öppna ram';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Är du säker på att du vill ta bort $name från vänner?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Ta bort';

  @override
  String get friendsRemove => 'Ta bort från vänner';

  @override
  String get friendsAcceptRequest => 'Acceptera förfrågan';

  @override
  String get friendsDeclineRequest => 'Avvisa förfrågan';

  @override
  String get friendsCancelRequest => 'Avbryt förfrågan';

  @override
  String get friendsSendRequest => 'Skicka vänförfrågan';

  @override
  String get friendsRequestAlreadySent => 'Förfrågan redan skickad';

  @override
  String get friendsIncomingStatus => 'Inkommande förfrågan';

  @override
  String get friendsOutgoingStatus => 'Utgående förfrågan';

  @override
  String get friendsNotFriends => 'Inte vänner';

  @override
  String get friendsCollapseSearch => 'Dölj sökning';

  @override
  String get friendsExpandSearch => 'Visa sökning';

  @override
  String get friendsLoadFailed => 'Kunde inte ladda vänner';

  @override
  String friendsSince(String date) {
    return 'Vänner sedan: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Inkommande förfrågan: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Utgående förfrågan: $date';
  }

  @override
  String get userInfoTitle => 'Användarinfo';

  @override
  String profileAgeYears(int age) {
    return '$age år';
  }

  @override
  String get shopBuy => 'Köp';

  @override
  String get shopBuyTitle => 'Köp?';

  @override
  String get shopBuyStakeTitle => 'Köp insat?';

  @override
  String get shopBuyEmojiTitle => 'Köp emoji?';

  @override
  String get shopBuyCollectionTitle => 'Köp samling?';

  @override
  String shopPrice(String price) {
    return 'Pris: $price';
  }

  @override
  String get shopOwned => 'Köpt';

  @override
  String get shopEmpty => 'Tomt än så länge';

  @override
  String shopPurchased(String title) {
    return '$title köpt';
  }

  @override
  String get shopEmojiUses => 'Du får: 10 användningar';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 användningar';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 användningar';
  }

  @override
  String get shopBuyTen => 'Köp · 10 st';

  @override
  String shopDailyIncome(String amount) {
    return 'Inkomst: $amount';
  }

  @override
  String get shopBuyOnce => 'Engångsköp';

  @override
  String get shopSellRefund => 'Försäljning återbetalar 80% av kostnaden';

  @override
  String shopCollectionAdded(String title) {
    return '$title tillagd i profilen';
  }

  @override
  String shopSetBonus(int percent) {
    return 'setbonus +$percent%';
  }

  @override
  String get shopSetComplete => 'Komplett';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Samlat · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Sälj?';

  @override
  String inventorySellDesc(String amount) {
    return 'Du får $amount';
  }

  @override
  String inventorySold(String amount) {
    return 'Sålt: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Lägg till vänner först';

  @override
  String get inventoryGiftTitle => 'Ge samling i present?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'Ge ”$title” till $name?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Givit: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'У этого пользователя уже есть эта коллекция';

  @override
  String get inventoryGiftSelf => 'Нельзя подарить коллекцию самому себе';

  @override
  String get inventoryGiftNotOwned => 'У вас нет этого предмета';

  @override
  String get inventoryLoadFailed => 'Kunde inte ladda föremål';

  @override
  String get inventoryNoCollections => 'Inga samlingar — köp i butiken';

  @override
  String get inventoryNoEmojis => 'Inga emojis — köp i butiken';

  @override
  String get inventoryNoFrames => 'Inga ramar — vinn 10 ligamatcher (prestationer)';

  @override
  String get inventoryNoStakes => 'Inga köpta insatser';

  @override
  String inventoryEmojiLeft(int count) {
    return '$count kvar';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Inkomst: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Inkomst imorgon: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Доход:';

  @override
  String get inventoryIncomeTomorrowLabel => 'Доход завтра:';

  @override
  String inventoryStakeGold(String amount) {
    return 'Du kan satsa $amount guld';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'Du kan satsa $amount silver';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'Hämtat +$amount';
  }

  @override
  String get chatsLoadFailed => 'Kunde inte ladda chattar';

  @override
  String get chatsLoadListFailed => 'Kunde inte ladda listan';

  @override
  String get chatsBlockedEmpty => 'Listan är tom';

  @override
  String chatsBlockedAt(String date) {
    return 'Blockerad: $date';
  }

  @override
  String get chatsCreateFailed => 'Kunde inte skapa chatt';

  @override
  String get chatsNeedFriendsFirst => 'Lägg till vänner först, sedan kan du öppna en chatt.';

  @override
  String get chatsFriendsNotFound => 'Inga vänner hittades';

  @override
  String get chatsFindFriendHint => 'Hitta vän via smeknamn';

  @override
  String get chatsSelectChat => 'Välj en chatt';

  @override
  String get chatsSelectHint => 'Välj en konversation från listan till vänster';

  @override
  String get chatEditFailed => 'Kunde inte redigera meddelandet';

  @override
  String get chatSendFailed => 'Kunde inte skicka meddelandet';

  @override
  String get chatDeleteFailed => 'Kunde inte ta bort meddelandet';

  @override
  String get chatEmojiSendFailed => 'Kunde inte skicka emoji';

  @override
  String get chatLoadFailed => 'Kunde inte ladda meddelanden';

  @override
  String get chatBackToGame => 'Tillbaka till spelet';

  @override
  String get chatBackToChats => 'Tillbaka till chattar';

  @override
  String get chatActions => 'Chattåtgärder';

  @override
  String get chatScrollToEnd => 'Till slutet av konversationen';

  @override
  String chatReplyingTo(String name) {
    return 'Svar till $name';
  }

  @override
  String get chatGift => 'Present';

  @override
  String get chatCollection => 'Samling';

  @override
  String get chatGiftCollection => 'Present · samling';

  @override
  String get chatThisUser => 'den här användaren';

  @override
  String get gamesLobbyLoadFailed => 'Kunde inte ladda lobbyn.';

  @override
  String get gamesTapChangeStake => 'Tryck för att byta insats';

  @override
  String get gamesTapChangeTurnTime => 'Tryck för att byta tid per drag';

  @override
  String get gamesTapChangeGrid => 'Tryck för att byta rutnätsstorlek';

  @override
  String get gamesSwapSidesHint => 'O kan bli X efter 1:a draget';

  @override
  String get gamesNoCenterHint => 'Första draget får inte vara i mitten';

  @override
  String get lobbyInviteSentShort => 'Skickat';

  @override
  String get lobbyInvitesSentWaiting => 'Inbjudningar skickade. Väntar på svar.';

  @override
  String get lobbyLinkCopiedHint => 'Klistra in den i en chatt eller ett meddelande till en vän';

  @override
  String get lobbyCopyLinkHint => 'Kopiera länk till urklipp';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name bjuder in dig att spela';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name vann';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Tiden är ute. $name vann';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String get adminTitle => 'Admin';

  @override
  String get tournamentsTitle => 'Turneringar';

  @override
  String get profileAgeInvalid => 'Ange en ålder mellan 1 och 111';

  @override
  String get profileSaveFailed => 'Kunde inte spara profilen';

  @override
  String get profileNameHint => 'Latinska bokstäver, siffror, _ upp till 10 tecken';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'Från 1 till 111';

  @override
  String get profileAboutHint => 'Upp till 100 tecken (valfritt)';

  @override
  String get profileProcessingPhoto => 'Bearbetar foto…';

  @override
  String get profileCropTitle => 'Välj avatarområde';

  @override
  String get profileCropHint => 'Zooma och flytta fotot';

  @override
  String get profileApply => 'Använd';

  @override
  String get profilePreparing => 'Förbereder…';

  @override
  String timeSecondsShort(int seconds) {
    return '$seconds s';
  }

  @override
  String get timeOneMin => '1 min';

  @override
  String get timeTenMin => '10 min';

  @override
  String rulesIntro(String grid) {
    return 'Luffarschack på $grid-bräde. Turvis; X börjar.';
  }

  @override
  String rulesWin(int n) {
    return 'Vinst: få $n i rad horisontellt, vertikalt eller diagonalt.';
  }

  @override
  String get rulesNoTimeLimit => 'Ingen tidsgräns per drag.';

  @override
  String rulesTurnTime(String time) {
    return 'Tid per drag: $time.';
  }

  @override
  String rulesStake(String stake) {
    return 'Insats: $stake. Spelet gäller så många mynt.';
  }

  @override
  String get rulesSwap => 'Sidbyte: O kan byta med X efter X:s första drag.';

  @override
  String get rulesNoCenter => 'Inget mittfält: X får inte spela i mitten på första draget.';

  @override
  String get collectionSetLegends => 'Legender';

  @override
  String get collectionSetSpace => 'Rymden';

  @override
  String get collectionSetGems => 'Ädelstenar';

  @override
  String get collectionSetParty => 'Fest';

  @override
  String get collectionSetNature => 'Natur';

  @override
  String get collectionSetAdventures => 'Äventyr';

  @override
  String collectionCardMeta(String amount) {
    return 'Samling · skyltfönster · present · sälj · +$amount';
  }

  @override
  String get coinsDayOne => 'dag';

  @override
  String get coinsDayFew => 'dagar';

  @override
  String get coinsDayMany => 'dagar';

  @override
  String get giftFriendTitle => 'Ge till en vän';

  @override
  String photoCount(int count) {
    return 'Foto ($count)';
  }

  @override
  String photoCountWithText(int count, String text) {
    return 'Foto ($count): $text';
  }

  @override
  String photoWithText(String text) {
    return 'Foto: $text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count emojis · $price';
  }

  @override
  String get chatsExpandPanel => 'Expandera panel';

  @override
  String get chatsCollapsePanel => 'Fäll ihop panel';

  @override
  String get chatReplySourceMissing => 'Ursprungligt meddelande hittades inte';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Insats $n silver';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Insats $n guld';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Låser upp insats på $n silver';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Låser upp insats på $n guld';
  }

  @override
  String get chatReplySelf => 'dig själv';

  @override
  String get chatReplyPeer => 'motparten';

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
  String get statsTitle => 'Statistik';

  @override
  String get statsLoadFailed => 'Kunde inte läsa in statistik';

  @override
  String get statsAllGames => 'Alla spel';

  @override
  String get statsEmptyTitle => 'Inga spel spelade ännu';

  @override
  String get statsEmptyHint => 'Spela ditt första spel för att se statistik här.';

  @override
  String get statsWins => 'Vinster';

  @override
  String get statsDraws => 'Oavgjorda';

  @override
  String get statsLosses => 'Förluster';

  @override
  String get statsWinRate => 'Vinstprocent';

  @override
  String get statsTopWon => 'Flest vinster mot';

  @override
  String get statsTopDrawn => 'Flest oavgjorda med';

  @override
  String get statsTopLost => 'Flest förluster mot';

  @override
  String get statsTimePlayed => 'Speltid';

  @override
  String get statsYourScore => 'Din ställning';

  @override
  String get profileShowStats => 'Visa statistik';

  @override
  String get statsDurationZeroMinutes => '0 min';

  @override
  String get gameYouWonOpponentForfeit => 'Motståndaren gav upp. Du vann!';

  @override
  String get lobbyLeaveTitle => 'Lämna lobby?';

  @override
  String get lobbyLeaveConfirm => 'Lobbyn raderas när du lämnar. Inbjudna vänner får ett avslag.';

  @override
  String get lobbyLeave => 'Lämna';

  @override
  String statsDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'Du gav upp. $name vann';
  }
}
