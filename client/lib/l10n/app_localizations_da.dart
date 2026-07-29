import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Hjem';

  @override
  String get navProfile => 'Profil';

  @override
  String get navFriends => 'Venner';

  @override
  String get navChats => 'Chats';

  @override
  String get navGames => 'Spil';

  @override
  String get navSettings => 'Indstillinger';

  @override
  String get settingsTitle => 'Indstillinger';

  @override
  String get settingsLanguage => 'Sprog';

  @override
  String get settingsLanguageSystem => 'Systemstandard';

  @override
  String get settingsAddBotsTitle => 'Tilføj bots efter 30 s';

  @override
  String get settingsAddBotsSubtitle => 'Ved matchmaking: hvis der ikke findes en modstander inden for 30 sekunder, starter spillet med en bot (indsatsen nulstilles til 1 bronze)';

  @override
  String get settingsFriendsOnlyTitle => 'Beskeder kun fra venner';

  @override
  String get settingsFriendsOnlySubtitle => 'Ikke-venner kan kun sende emojis. Ved spam, bloker brugeren midlertidigt.';

  @override
  String get settingsNotifications => 'Notifikationer';

  @override
  String get settingsPushChat => 'Chat';

  @override
  String get settingsPushFriends => 'Venner';

  @override
  String get settingsPushGames => 'Spil';

  @override
  String get settingsPushRewards => 'Belønninger';

  @override
  String get loginTitle => 'Log ind';

  @override
  String get loginSubtitle => 'Indtast e-mail eller brugernavn og adgangskode';

  @override
  String get loginEmailLabel => 'E-mail eller brugernavn';

  @override
  String get loginPasswordLabel => 'Adgangskode';

  @override
  String get loginSubmit => 'Log ind';

  @override
  String get loginNoAccount => 'Ingen konto? Tilmeld dig';

  @override
  String get loginEmailRequired => 'Indtast e-mail eller brugernavn';

  @override
  String get loginPasswordRequired => 'Indtast adgangskode';

  @override
  String get loginTooltip => 'Log ind';

  @override
  String get logoutTooltip => 'Log ud';

  @override
  String get registerTitle => 'Tilmeld dig';

  @override
  String get registerSubtitle => 'Opret en konto for at spille';

  @override
  String get registerNameLabel => 'Navn (brugernavn)';

  @override
  String get registerEmailLabel => 'E-mail';

  @override
  String get registerPasswordLabel => 'Adgangskode';

  @override
  String get registerSubmit => 'Tilmeld dig';

  @override
  String get registerHaveAccount => 'Har du allerede en konto? Log ind';

  @override
  String get registerNameRequired => 'Indtast et navn';

  @override
  String get registerNameNoSpaces => 'Navnet må ikke indeholde mellemrum';

  @override
  String get registerNameMax => 'Maks. 20 tegn';

  @override
  String get registerNameHint => 'Op til 20 tegn';

  @override
  String get registerEmailRequired => 'Indtast e-mail';

  @override
  String get registerEmailInvalid => 'Ugyldig e-mail';

  @override
  String get registerPasswordHint => 'Mindst 6 tegn';

  @override
  String get registerPasswordMin => 'Adgangskoden skal være mindst 6 tegn';

  @override
  String get commonCancel => 'Annuller';

  @override
  String get commonSave => 'Gem';

  @override
  String get commonDelete => 'Slet';

  @override
  String get commonEdit => 'Rediger';

  @override
  String get commonReply => 'Svar';

  @override
  String get commonSend => 'Send';

  @override
  String get commonClose => 'Luk';

  @override
  String get commonRetry => 'Prøv igen';

  @override
  String get commonLoading => 'Indlæser…';

  @override
  String get commonError => 'Fejl';

  @override
  String get commonOnline => 'online';

  @override
  String get commonOffline => 'offline';

  @override
  String get commonOnlineCap => 'Online';

  @override
  String get commonUser => 'Bruger';

  @override
  String get commonPlayer => 'Spiller';

  @override
  String get commonAboutMe => 'Om mig';

  @override
  String get commonBack => 'Tilbage';

  @override
  String get commonAccept => 'Accepter';

  @override
  String get commonDecline => 'Afvis';

  @override
  String get commonCreating => 'Opretter…';

  @override
  String get commonSearching => 'Søger…';

  @override
  String get commonInsufficientCoins => 'Ikke nok mønter';

  @override
  String get commonNotFound => 'Ikke fundet';

  @override
  String get commonServerErrorShort => 'Serverfejl';

  @override
  String get commonForbidden => 'Adgang nægtet';

  @override
  String get commonUserBlocked => 'Brugeren er blokeret';

  @override
  String get commonUserNotFound => 'Brugeren blev ikke fundet';

  @override
  String get commonGenericError => 'Noget gik galt. Prøv igen.';

  @override
  String get timeJustNow => 'lige nu';

  @override
  String get timeYesterday => 'i går';

  @override
  String timeMinutesAgo(Object count) {
    return '$count min. siden';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count t. siden';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count d. siden';
  }

  @override
  String get timeWeekAgo => 'en uge siden';

  @override
  String timeWeeksAgo(Object count) {
    return '$count ug. siden';
  }

  @override
  String get timeMonthAgo => 'en måned siden';

  @override
  String timeMonthsAgo(Object count) {
    return '$count md. siden';
  }

  @override
  String get timeYearAgo => 'et år siden';

  @override
  String timeYearsAgo(Object count) {
    return '$count år siden';
  }

  @override
  String get weekdaySun => 'Søn';

  @override
  String get weekdayMon => 'Man';

  @override
  String get weekdayTue => 'Tir';

  @override
  String get weekdayWed => 'Ons';

  @override
  String get weekdayThu => 'Tor';

  @override
  String get weekdayFri => 'Fre';

  @override
  String get weekdaySat => 'Lør';

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
  String get homeAchievements => 'Præstationer';

  @override
  String get homeAchievementsSubtitle => 'Dine spilleresultater';

  @override
  String get homeAchievementsRewards => 'Belønninger klar til at hente';

  @override
  String get homeCoins => 'Mønter';

  @override
  String get homeCoinsSubtitle => 'Saldo og belønninger';

  @override
  String get homeCoinsDailyReward => 'Daglig loginbelønning tilgængelig';

  @override
  String get homeItems => 'Genstande';

  @override
  String get homeItemsInventory => 'Dit inventar';

  @override
  String get homeItemsGifted => 'Nogen har givet dig en samling';

  @override
  String get homeItemsIncome => 'Samlingsindtægt klar til at hente';

  @override
  String get homeShop => 'Butik';

  @override
  String get homeShopSubtitle => 'Emojis, indsatser, samlinger';

  @override
  String get gamesTitle => 'Spil';

  @override
  String get gamesFindMatch => 'Find et spil';

  @override
  String get gamesMyTurn => 'Din tur';

  @override
  String get gamesWaiting => 'Venter';

  @override
  String get gamesLobbyTab => 'Lobby';

  @override
  String get gamesTicTacToe => 'Kryds og bolle';

  @override
  String get gamesRules => 'Regler';

  @override
  String get gamesRulesTitle => 'Spilleregler';

  @override
  String get gamesCreate => 'Opret spil';

  @override
  String get gamesJoin => 'Deltag';

  @override
  String get gamesOpponentTurn => 'Modstanderens tur';

  @override
  String get gamesCurrentGame => 'Aktuelt spil';

  @override
  String get gamesInvitedYou => 'Du blev inviteret';

  @override
  String get gamesTurnTime => 'Tid pr. tur';

  @override
  String get gamesGridSize => 'Gitterstørrelse';

  @override
  String get gamesSwapSides => 'Sideskift';

  @override
  String get gamesNoCenter => 'Ingen start i midten';

  @override
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Privat spil';

  @override
  String get lobbySearchingOpponent => 'Leder efter modstander…';

  @override
  String get lobbyWaitingJoin => 'Venter på, at nogen trykker på »Find et spil« eller »Deltag«';

  @override
  String get lobbyInviteTitle => 'Spilinvitation';

  @override
  String get lobbyInvitedToPlay => 'Du blev inviteret til at spille';

  @override
  String get lobbyEnterGame => 'Gå ind i spillet';

  @override
  String get lobbyInvite => 'Inviter';

  @override
  String get lobbyInviteSent => 'Invitation sendt';

  @override
  String get lobbyCopyLink => 'Del spil-link';

  @override
  String get lobbyLinkCopied => 'Link kopieret';

  @override
  String get lobbyNoFriendsOnline => 'Ingen venner online. Del spil-linket ovenfor, eller vent til venner kommer online.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Modstander';

  @override
  String get gameYouWon => 'Du vandt!';

  @override
  String get gameYouWonOpponentLeft => 'Du vandt — modstanderen forlod';

  @override
  String get gameYouWonOpponentTimeout => 'Du vandt — modstanderen løb tør for tid';

  @override
  String get gameDraw => 'Uafgjort';

  @override
  String get gameExitTitle => 'Forlad spillet';

  @override
  String get gameExitConfirm => 'Hvis du forlader, taber du. Forlad alligevel?';

  @override
  String get gameStay => 'Bliv';

  @override
  String get gameLeave => 'Forlad';

  @override
  String get gameConnecting => 'Forbinder til spillet…';

  @override
  String get gameWaitingOpponent => 'Venter på modstander';

  @override
  String get gameRematchOffer => 'Modstanderen tilbyder revanche';

  @override
  String get gameRematchDeclined => 'Modstanderen afviste revanchen';

  @override
  String get gameRematch => 'Revanche';

  @override
  String get gameOtherOpponent => 'Anden modstander';

  @override
  String get gameSwapSidesAction => 'Skift side';

  @override
  String get gameWriteMessage => 'Skriv en besked';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get chatsEmpty => 'Ingen chats endnu.\nTryk på ikonet øverst til højre for at vælge en ven og starte en samtale.';

  @override
  String get chatsNewChat => 'Ny chat';

  @override
  String get chatsNoMessages => 'Ingen beskeder';

  @override
  String get chatsClearTitle => 'Ryd samtalen?';

  @override
  String get chatsClearDesc => 'Chatten slettes permanent.';

  @override
  String get chatsClearConfirm => 'Ryd';

  @override
  String get chatsBlockTitle => 'Blokér denne bruger?';

  @override
  String get chatsBlockDesc => 'I kan ikke længere sende beskeder til hinanden. Chat og venskab fjernes.';

  @override
  String get chatsBlockConfirm => 'Blokér';

  @override
  String get chatsBlockedUsers => 'Blokerede brugere';

  @override
  String get chatsUnblock => 'Fjern blokering';

  @override
  String get chatDialog => 'Chat';

  @override
  String get chatEmpty => 'Ingen beskeder endnu.\nSend den første.';

  @override
  String get chatMessageHint => 'Besked';

  @override
  String get chatEmoji => 'Emojis';

  @override
  String get chatBuyEmojiHint => 'Køb emojis i butikken på startskærmen';

  @override
  String get chatEditing => 'Redigerer';

  @override
  String get chatToday => 'I dag';

  @override
  String get chatYesterday => 'I går';

  @override
  String get chatFriendsOnly => 'Tekst kun for venner';

  @override
  String get emojiGroupEmotions => 'Følelser';

  @override
  String get emojiGroupGame => 'Spil';

  @override
  String get emojiGroupFlags => 'Flag';

  @override
  String get emojiGroupAnimals => 'Dyr';

  @override
  String get emojiGroupFood => 'Mad';

  @override
  String get emojiGroupTravel => 'Rejse';

  @override
  String get emojiGroupParty => 'Fest';

  @override
  String get emojiGroupObjects => 'Objekter';

  @override
  String get friendsTitle => 'Venner';

  @override
  String get friendsTabFriends => 'Venner';

  @override
  String get friendsTabIncoming => 'Indgående';

  @override
  String get friendsTabOutgoing => 'Udgående';

  @override
  String get friendsAdd => 'Tilføj ven';

  @override
  String get friendsRequestSent => 'Anmodning sendt';

  @override
  String get friendsFindTab => 'Find ven';

  @override
  String get friendsSearchHint => 'Søg efter brugernavn';

  @override
  String get friendsSearchPrompt => 'Brug søgning til at finde nye venner';

  @override
  String get friendsNothingFound => 'Intet fundet';

  @override
  String get friendsEmpty => 'Du har ingen venner endnu';

  @override
  String get friendsNoIncoming => 'Ingen indgående anmodninger';

  @override
  String get friendsNoOutgoing => 'Ingen udgående anmodninger';

  @override
  String get friendsAlreadyFriends => 'Allerede venner';

  @override
  String get friendsRemoveTitle => 'Fjern fra venner?';

  @override
  String get friendsRemoved => 'Fjernet fra venner';

  @override
  String get friendsRequestAccepted => 'Anmodning accepteret';

  @override
  String get friendsRequestDeclined => 'Anmodning afvist';

  @override
  String get friendsRequestCancelled => 'Anmodning annulleret';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSignInPrompt => 'Log ind på din konto';

  @override
  String get profileSignInHint => 'For at indstille din personlige profil';

  @override
  String get profileEdit => 'Rediger';

  @override
  String get profileCollections => 'Samlinger';

  @override
  String get profileAge => 'Alder';

  @override
  String get profileGender => 'Køn';

  @override
  String get profileGenderUnset => 'Ikke angivet';

  @override
  String get profileGenderMale => 'Mand';

  @override
  String get profileGenderFemale => 'Kvinde';

  @override
  String get profileAvatar => 'Avatar';

  @override
  String get profileUploadPhoto => 'Upload foto';

  @override
  String get profileChangePhoto => 'Skift foto';

  @override
  String get shopTitle => 'Butik';

  @override
  String get shopEmojis => 'Emojis';

  @override
  String get shopEmojisSubtitle => 'Animerede emojis til chat';

  @override
  String get shopCollections => 'Samlinger';

  @override
  String get shopCollectionsSubtitle => 'Profiludstilling, gaver og indtægt';

  @override
  String get shopStakes => 'Indsatser';

  @override
  String get shopStakesSubtitle => 'Lås sølvindsatser op';

  @override
  String get inventoryTitle => 'Genstande';

  @override
  String get inventoryEmpty => 'Intet her endnu — tjek butikken';

  @override
  String get inventoryFrames => 'Rammer';

  @override
  String get inventoryClaim => 'Hent';

  @override
  String get inventorySell => 'Sælg';

  @override
  String get inventoryGift => 'Giv';

  @override
  String get messageEdited => 'redigeret';

  @override
  String get messageDeleted => 'Besked slettet';

  @override
  String get photo => 'Foto';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galleri';

  @override
  String get connectionError => 'Kunne ikke oprette forbindelse til serveren.';

  @override
  String get serverError => 'Serverfejl. Prøv igen senere.';

  @override
  String get sessionExpired => 'Sessionen er udløbet. Log ind igen.';

  @override
  String get errNoInternet => 'Ingen internetforbindelse.';

  @override
  String get errTimeout => 'Anmodningen fik timeout. Prøv igen.';

  @override
  String get errGamesUnavailable => 'Spil er midlertidigt utilgængelige';

  @override
  String get errSettingsSaveFailed => 'Kunne ikke gemme indstillingen';

  @override
  String get errPushPermission => 'Tillad notifikationer i browser- eller systemindstillingerne.';
}
