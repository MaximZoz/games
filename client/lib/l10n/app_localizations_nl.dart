import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Home';

  @override
  String get navProfile => 'Profiel';

  @override
  String get navFriends => 'Vrienden';

  @override
  String get navChats => 'Chats';

  @override
  String get navGames => 'Spellen';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get settingsLanguage => 'Taal';

  @override
  String get settingsLanguageSystem => 'Systeemstandaard';

  @override
  String get settingsAddBotsTitle => 'Bots toevoegen na 30 s';

  @override
  String get settingsAddBotsSubtitle => 'Bij matchmaking: als er binnen 30 seconden geen tegenstander is, start het spel met een bot (inzet terug naar 1 brons)';

  @override
  String get settingsFriendsOnlyTitle => 'Berichten alleen van vrienden';

  @override
  String get settingsFriendsOnlySubtitle => 'Niet-vrienden kunnen alleen emoji’s sturen. Bij spam blokkeer je de gebruiker tijdelijk.';

  @override
  String get settingsNotifications => 'Meldingen';

  @override
  String get settingsPushChat => 'Chat';

  @override
  String get settingsPushFriends => 'Vrienden';

  @override
  String get settingsPushGames => 'Spellen';

  @override
  String get settingsPushRewards => 'Beloningen';

  @override
  String get loginTitle => 'Inloggen';

  @override
  String get loginSubtitle => 'Voer e-mail of gebruikersnaam en wachtwoord in';

  @override
  String get loginEmailLabel => 'E-mail of gebruikersnaam';

  @override
  String get loginPasswordLabel => 'Wachtwoord';

  @override
  String get loginSubmit => 'Inloggen';

  @override
  String get loginNoAccount => 'Geen account? Registreren';

  @override
  String get loginEmailRequired => 'Voer e-mail of gebruikersnaam in';

  @override
  String get loginPasswordRequired => 'Voer wachtwoord in';

  @override
  String get loginTooltip => 'Inloggen';

  @override
  String get logoutTooltip => 'Uitloggen';

  @override
  String get registerTitle => 'Registreren';

  @override
  String get registerSubtitle => 'Maak een account om te spelen';

  @override
  String get registerNameLabel => 'Naam (gebruikersnaam)';

  @override
  String get registerEmailLabel => 'E-mail';

  @override
  String get registerPasswordLabel => 'Wachtwoord';

  @override
  String get registerSubmit => 'Registreren';

  @override
  String get registerHaveAccount => 'Heb je al een account? Inloggen';

  @override
  String get registerNameRequired => 'Voer een naam in';

  @override
  String get registerNameNoSpaces => 'Naam mag geen spaties bevatten';

  @override
  String get registerNameMax => 'Maximaal 20 tekens';

  @override
  String get registerNameHint => 'Tot 20 tekens';

  @override
  String get registerEmailRequired => 'Voer e-mail in';

  @override
  String get registerEmailInvalid => 'Ongeldig e-mailadres';

  @override
  String get registerPasswordHint => 'Minimaal 6 tekens';

  @override
  String get registerPasswordMin => 'Wachtwoord moet minstens 6 tekens zijn';

  @override
  String get commonCancel => 'Annuleren';

  @override
  String get commonSave => 'Opslaan';

  @override
  String get commonDelete => 'Verwijderen';

  @override
  String get commonEdit => 'Bewerken';

  @override
  String get commonReply => 'Beantwoorden';

  @override
  String get commonSend => 'Versturen';

  @override
  String get commonClose => 'Sluiten';

  @override
  String get commonRetry => 'Opnieuw';

  @override
  String get commonLoading => 'Laden…';

  @override
  String get commonError => 'Fout';

  @override
  String get commonOnline => 'online';

  @override
  String get commonOffline => 'offline';

  @override
  String get commonOnlineCap => 'Online';

  @override
  String get commonUser => 'Gebruiker';

  @override
  String get commonPlayer => 'Speler';

  @override
  String get commonAboutMe => 'Over mij';

  @override
  String get commonBack => 'Terug';

  @override
  String get commonAccept => 'Accepteren';

  @override
  String get commonDecline => 'Weigeren';

  @override
  String get commonCreating => 'Aanmaken…';

  @override
  String get commonSearching => 'Zoeken…';

  @override
  String get commonInsufficientCoins => 'Niet genoeg munten';

  @override
  String get commonNotFound => 'Niet gevonden';

  @override
  String get commonServerErrorShort => 'Serverfout';

  @override
  String get commonForbidden => 'Toegang geweigerd';

  @override
  String get commonUserBlocked => 'Gebruiker is geblokkeerd';

  @override
  String get commonUserNotFound => 'Gebruiker niet gevonden';

  @override
  String get commonGenericError => 'Er ging iets mis. Probeer het opnieuw.';

  @override
  String get timeJustNow => 'zojuist';

  @override
  String get timeYesterday => 'gisteren';

  @override
  String timeMinutesAgo(Object count) {
    return '$count min geleden';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count u geleden';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count d geleden';
  }

  @override
  String get timeWeekAgo => 'een week geleden';

  @override
  String timeWeeksAgo(Object count) {
    return '$count wkn geleden';
  }

  @override
  String get timeMonthAgo => 'een maand geleden';

  @override
  String timeMonthsAgo(Object count) {
    return '$count mnd geleden';
  }

  @override
  String get timeYearAgo => 'een jaar geleden';

  @override
  String timeYearsAgo(Object count) {
    return '$count jr geleden';
  }

  @override
  String get weekdaySun => 'Zo';

  @override
  String get weekdayMon => 'Ma';

  @override
  String get weekdayTue => 'Di';

  @override
  String get weekdayWed => 'Wo';

  @override
  String get weekdayThu => 'Do';

  @override
  String get weekdayFri => 'Vr';

  @override
  String get weekdaySat => 'Za';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mrt';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'Mei';

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
  String get homeAchievements => 'Prestaties';

  @override
  String get homeAchievementsSubtitle => 'Jouw speelresultaten';

  @override
  String get homeAchievementsRewards => 'Beloningen klaar om te claimen';

  @override
  String get homeCoins => 'Munten';

  @override
  String get homeCoinsSubtitle => 'Saldo en beloningen';

  @override
  String get homeCoinsDailyReward => 'Dagelijkse inlogbeloning beschikbaar';

  @override
  String get homeItems => 'Items';

  @override
  String get homeItemsInventory => 'Jouw inventaris';

  @override
  String get homeItemsGifted => 'Iemand heeft je een collectie gegeven';

  @override
  String get homeItemsIncome => 'Collectie-inkomsten klaar om te claimen';

  @override
  String get homeShop => 'Winkel';

  @override
  String get homeShopSubtitle => 'Emoji’s, inzetten, collecties';

  @override
  String get gamesTitle => 'Spellen';

  @override
  String get gamesFindMatch => 'Spel zoeken';

  @override
  String get gamesMyTurn => 'Jouw beurt';

  @override
  String get gamesWaiting => 'Wachten';

  @override
  String get gamesLobbyTab => 'Lobby';

  @override
  String get gamesTicTacToe => 'Boter-kaas-eieren';

  @override
  String get gamesRules => 'Regels';

  @override
  String get gamesRulesTitle => 'Spelregels';

  @override
  String get gamesCreate => 'Spel maken';

  @override
  String get gamesJoin => 'Meedoen';

  @override
  String get gamesOpponentTurn => 'Beurt van tegenstander';

  @override
  String get gamesCurrentGame => 'Huidig spel';

  @override
  String get gamesInvitedYou => 'Je bent uitgenodigd';

  @override
  String get gamesTurnTime => 'Beurtijd';

  @override
  String get gamesGridSize => 'Rastergrootte';

  @override
  String get gamesSwapSides => 'Kant wisselen';

  @override
  String get gamesNoCenter => 'Geen start in het midden';

  @override
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Privéspel';

  @override
  String get lobbySearchingOpponent => 'Tegenstander zoeken…';

  @override
  String get lobbyWaitingJoin => 'Wachten tot iemand op «Spel zoeken» of «Meedoen» tikt';

  @override
  String get lobbyInviteTitle => 'Speluitnodiging';

  @override
  String get lobbyInvitedToPlay => 'Je bent uitgenodigd om te spelen';

  @override
  String get lobbyEnterGame => 'Spel betreden';

  @override
  String get lobbyInvite => 'Uitnodigen';

  @override
  String get lobbyInviteSent => 'Uitnodiging verstuurd';

  @override
  String get lobbyCopyLink => 'Spellink delen';

  @override
  String get lobbyLinkCopied => 'Link gekopieerd';

  @override
  String get lobbyNoFriendsOnline => 'Geen vrienden online. Deel de spellink hierboven of wacht tot vrienden online komen.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Tegenstander';

  @override
  String get gameYouWon => 'Je hebt gewonnen!';

  @override
  String get gameYouWonOpponentLeft => 'Je hebt gewonnen — tegenstander is weggegaan';

  @override
  String get gameYouWonOpponentTimeout => 'Je hebt gewonnen — tijd van tegenstander is op';

  @override
  String get gameDraw => 'Gelijkspel';

  @override
  String get gameExitTitle => 'Spel verlaten';

  @override
  String get gameExitConfirm => 'Als je weggaat, verlies je. Toch verlaten?';

  @override
  String get gameStay => 'Blijven';

  @override
  String get gameLeave => 'Verlaten';

  @override
  String get gameConnecting => 'Verbinden met spel…';

  @override
  String get gameWaitingOpponent => 'Wachten op tegenstander';

  @override
  String get gameRematchOffer => 'Tegenstander biedt een herkansing aan';

  @override
  String get gameRematchDeclined => 'Tegenstander heeft de herkansing geweigerd';

  @override
  String get gameRematch => 'Opnieuw';

  @override
  String get gameOtherOpponent => 'Andere tegenstander';

  @override
  String get gameSwapSidesAction => 'Van kant wisselen';

  @override
  String get gameWriteMessage => 'Schrijf een bericht';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get chatsEmpty => 'Nog geen chats.\nTik op het pictogram rechtsboven om een vriend te kiezen en te beginnen.';

  @override
  String get chatsNewChat => 'Nieuwe chat';

  @override
  String get chatsNoMessages => 'Geen berichten';

  @override
  String get chatsClearTitle => 'Gesprek wissen?';

  @override
  String get chatsClearDesc => 'De chat wordt permanent verwijderd.';

  @override
  String get chatsClearConfirm => 'Wissen';

  @override
  String get chatsBlockTitle => 'Deze gebruiker blokkeren?';

  @override
  String get chatsBlockDesc => 'Jullie kunnen elkaar niet meer berichten. Chat en vriendschap worden verwijderd.';

  @override
  String get chatsBlockConfirm => 'Blokkeren';

  @override
  String get chatsBlockedUsers => 'Geblokkeerde gebruikers';

  @override
  String get chatsUnblock => 'Deblokkeren';

  @override
  String get chatDialog => 'Chat';

  @override
  String get chatEmpty => 'Nog geen berichten.\nStuur de eerste.';

  @override
  String get chatMessageHint => 'Bericht';

  @override
  String get chatEmoji => 'Emoji’s';

  @override
  String get chatBuyEmojiHint => 'Koop emoji’s in de winkel op het startscherm';

  @override
  String get chatEditing => 'Bewerken';

  @override
  String get chatToday => 'Vandaag';

  @override
  String get chatYesterday => 'Gisteren';

  @override
  String get chatFriendsOnly => 'Tekst alleen voor vrienden';

  @override
  String get emojiGroupEmotions => 'Emoties';

  @override
  String get emojiGroupGame => 'Gaming';

  @override
  String get emojiGroupFlags => 'Vlaggen';

  @override
  String get emojiGroupAnimals => 'Dieren';

  @override
  String get emojiGroupFood => 'Eten';

  @override
  String get emojiGroupTravel => 'Reizen';

  @override
  String get emojiGroupParty => 'Feest';

  @override
  String get emojiGroupObjects => 'Objecten';

  @override
  String get friendsTitle => 'Vrienden';

  @override
  String get friendsTabFriends => 'Vrienden';

  @override
  String get friendsTabIncoming => 'Inkomend';

  @override
  String get friendsTabOutgoing => 'Uitgaand';

  @override
  String get friendsAdd => 'Vriend toevoegen';

  @override
  String get friendsRequestSent => 'Verzoek verstuurd';

  @override
  String get friendsFindTab => 'Vriend zoeken';

  @override
  String get friendsSearchHint => 'Zoeken op gebruikersnaam';

  @override
  String get friendsSearchPrompt => 'Gebruik zoeken om nieuwe vrienden te vinden';

  @override
  String get friendsNothingFound => 'Niets gevonden';

  @override
  String get friendsEmpty => 'Je hebt nog geen vrienden';

  @override
  String get friendsNoIncoming => 'Geen inkomende verzoeken';

  @override
  String get friendsNoOutgoing => 'Geen uitgaande verzoeken';

  @override
  String get friendsAlreadyFriends => 'Al vrienden';

  @override
  String get friendsRemoveTitle => 'Uit vrienden verwijderen?';

  @override
  String get friendsRemoved => 'Uit vrienden verwijderd';

  @override
  String get friendsRequestAccepted => 'Verzoek geaccepteerd';

  @override
  String get friendsRequestDeclined => 'Verzoek geweigerd';

  @override
  String get friendsRequestCancelled => 'Verzoek geannuleerd';

  @override
  String get profileTitle => 'Profiel';

  @override
  String get profileSignInPrompt => 'Log in op je account';

  @override
  String get profileSignInHint => 'Om je persoonlijke profiel in te stellen';

  @override
  String get profileEdit => 'Bewerken';

  @override
  String get profileCollections => 'Collecties';

  @override
  String get profileAge => 'Leeftijd';

  @override
  String get profileGender => 'Geslacht';

  @override
  String get profileGenderUnset => 'Niet ingesteld';

  @override
  String get profileGenderMale => 'Man';

  @override
  String get profileGenderFemale => 'Vrouw';

  @override
  String get profileAvatar => 'Avatar';

  @override
  String get profileUploadPhoto => 'Foto uploaden';

  @override
  String get profileChangePhoto => 'Foto wijzigen';

  @override
  String get shopTitle => 'Winkel';

  @override
  String get shopEmojis => 'Emoji’s';

  @override
  String get shopEmojisSubtitle => 'Geanimeerde emoji’s voor chat';

  @override
  String get shopCollections => 'Collecties';

  @override
  String get shopCollectionsSubtitle => 'Profielvitrine, cadeaus en inkomsten';

  @override
  String get shopStakes => 'Inzetten';

  @override
  String get shopStakesSubtitle => 'Zilveren inzetten ontgrendelen';

  @override
  String get inventoryTitle => 'Items';

  @override
  String get inventoryEmpty => 'Nog niets hier — bekijk de winkel';

  @override
  String get inventoryFrames => 'Kaders';

  @override
  String get inventoryClaim => 'Claimen';

  @override
  String get inventorySell => 'Verkopen';

  @override
  String get inventoryGift => 'Cadeau';

  @override
  String get messageEdited => 'bewerkt';

  @override
  String get messageDeleted => 'Bericht verwijderd';

  @override
  String get photo => 'Foto';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Galerij';

  @override
  String get connectionError => 'Kon geen verbinding maken met de server.';

  @override
  String get serverError => 'Serverfout. Probeer het later opnieuw.';

  @override
  String get sessionExpired => 'Sessie verlopen. Log opnieuw in.';

  @override
  String get errNoInternet => 'Geen internetverbinding.';

  @override
  String get errTimeout => 'Verzoek time-out. Probeer het opnieuw.';

  @override
  String get errGamesUnavailable => 'Games zijn tijdelijk niet beschikbaar';

  @override
  String get errSettingsSaveFailed => 'Kon instelling niet opslaan';

  @override
  String get errPushPermission => 'Sta meldingen toe in je browser- of systeeminstellingen.';
}
