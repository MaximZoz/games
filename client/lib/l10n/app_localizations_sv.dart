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
  String timeMinutesAgo(Object count) {
    return '$count min sedan';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count h sedan';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count d sedan';
  }

  @override
  String get timeWeekAgo => 'en vecka sedan';

  @override
  String timeWeeksAgo(Object count) {
    return '$count v sedan';
  }

  @override
  String get timeMonthAgo => 'en månad sedan';

  @override
  String timeMonthsAgo(Object count) {
    return '$count mån sedan';
  }

  @override
  String get timeYearAgo => 'ett år sedan';

  @override
  String timeYearsAgo(Object count) {
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
  String get shopStakesSubtitle => 'Lås upp silverinsatser';

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
}
