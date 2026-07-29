import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Start';

  @override
  String get navProfile => 'Profil';

  @override
  String get navFriends => 'Freunde';

  @override
  String get navChats => 'Chats';

  @override
  String get navGames => 'Spiele';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'Systemstandard';

  @override
  String get settingsAddBotsTitle => 'Bots nach 30 s hinzufügen';

  @override
  String get settingsAddBotsSubtitle => 'Im Matchmaking: Wird in 30 Sekunden kein Gegner gefunden, startet das Spiel mit einem Bot (Einsatz fällt auf 1 Bronze zurück)';

  @override
  String get settingsFriendsOnlyTitle => 'Nachrichten nur von Freunden';

  @override
  String get settingsFriendsOnlySubtitle => 'Nicht-Freunde können nur Emojis senden. Bei Spam den Nutzer vorübergehend blockieren.';

  @override
  String get settingsNotifications => 'Benachrichtigungen';

  @override
  String get settingsPushChat => 'Chat';

  @override
  String get settingsPushFriends => 'Freunde';

  @override
  String get settingsPushGames => 'Spiele';

  @override
  String get settingsPushRewards => 'Belohnungen';

  @override
  String get loginTitle => 'Anmelden';

  @override
  String get loginSubtitle => 'E-Mail oder Benutzername und Passwort eingeben';

  @override
  String get loginEmailLabel => 'E-Mail oder Benutzername';

  @override
  String get loginPasswordLabel => 'Passwort';

  @override
  String get loginSubmit => 'Anmelden';

  @override
  String get loginNoAccount => 'Kein Konto? Registrieren';

  @override
  String get loginEmailRequired => 'E-Mail oder Benutzername eingeben';

  @override
  String get loginPasswordRequired => 'Passwort eingeben';

  @override
  String get loginTooltip => 'Anmelden';

  @override
  String get logoutTooltip => 'Abmelden';

  @override
  String get registerTitle => 'Registrierung';

  @override
  String get registerSubtitle => 'Konto erstellen, um zu spielen';

  @override
  String get registerNameLabel => 'Name (Benutzername)';

  @override
  String get registerEmailLabel => 'E-Mail';

  @override
  String get registerPasswordLabel => 'Passwort';

  @override
  String get registerSubmit => 'Registrieren';

  @override
  String get registerHaveAccount => 'Bereits ein Konto? Anmelden';

  @override
  String get registerNameRequired => 'Namen eingeben';

  @override
  String get registerNameNoSpaces => 'Name darf keine Leerzeichen enthalten';

  @override
  String get registerNameMax => 'Maximal 20 Zeichen';

  @override
  String get registerNameHint => 'Bis zu 20 Zeichen';

  @override
  String get registerEmailRequired => 'E-Mail eingeben';

  @override
  String get registerEmailInvalid => 'Ungültige E-Mail';

  @override
  String get registerPasswordHint => 'Mindestens 6 Zeichen';

  @override
  String get registerPasswordMin => 'Passwort muss mindestens 6 Zeichen haben';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonReply => 'Antworten';

  @override
  String get commonSend => 'Senden';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonRetry => 'Erneut';

  @override
  String get commonLoading => 'Laden…';

  @override
  String get commonError => 'Fehler';

  @override
  String get commonOnline => 'online';

  @override
  String get commonOffline => 'offline';

  @override
  String get commonOnlineCap => 'Online';

  @override
  String get commonUser => 'Benutzer';

  @override
  String get commonPlayer => 'Spieler';

  @override
  String get commonAboutMe => 'Über mich';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonAccept => 'Annehmen';

  @override
  String get commonDecline => 'Ablehnen';

  @override
  String get commonCreating => 'Erstellen…';

  @override
  String get commonSearching => 'Suche…';

  @override
  String get commonInsufficientCoins => 'Nicht genug Münzen';

  @override
  String get commonNotFound => 'Nicht gefunden';

  @override
  String get commonServerErrorShort => 'Serverfehler';

  @override
  String get commonForbidden => 'Zugriff verweigert';

  @override
  String get commonUserBlocked => 'Benutzer ist blockiert';

  @override
  String get commonUserNotFound => 'Benutzer nicht gefunden';

  @override
  String get commonGenericError => 'Etwas ist schiefgelaufen. Bitte erneut versuchen.';

  @override
  String get timeJustNow => 'gerade eben';

  @override
  String get timeYesterday => 'gestern';

  @override
  String timeMinutesAgo(Object count) {
    return 'vor $count Min.';
  }

  @override
  String timeHoursAgo(Object count) {
    return 'vor $count Std.';
  }

  @override
  String timeDaysAgo(Object count) {
    return 'vor $count T.';
  }

  @override
  String get timeWeekAgo => 'vor einer Woche';

  @override
  String timeWeeksAgo(Object count) {
    return 'vor $count Wo.';
  }

  @override
  String get timeMonthAgo => 'vor einem Monat';

  @override
  String timeMonthsAgo(Object count) {
    return 'vor $count Mon.';
  }

  @override
  String get timeYearAgo => 'vor einem Jahr';

  @override
  String timeYearsAgo(Object count) {
    return 'vor $count J.';
  }

  @override
  String get weekdaySun => 'So';

  @override
  String get weekdayMon => 'Mo';

  @override
  String get weekdayTue => 'Di';

  @override
  String get weekdayWed => 'Mi';

  @override
  String get weekdayThu => 'Do';

  @override
  String get weekdayFri => 'Fr';

  @override
  String get weekdaySat => 'Sa';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mär';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'Mai';

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
  String get monthDec => 'Dez';

  @override
  String get homeAchievements => 'Erfolge';

  @override
  String get homeAchievementsSubtitle => 'Deine Spielergebnisse';

  @override
  String get homeAchievementsRewards => 'Belohnungen zum Abholen';

  @override
  String get homeCoins => 'Münzen';

  @override
  String get homeCoinsSubtitle => 'Guthaben und Belohnungen';

  @override
  String get homeCoinsDailyReward => 'Tägliche Login-Belohnung verfügbar';

  @override
  String get homeItems => 'Gegenstände';

  @override
  String get homeItemsInventory => 'Dein Inventar';

  @override
  String get homeItemsGifted => 'Dir wurde eine Sammlung geschenkt';

  @override
  String get homeItemsIncome => 'Sammlungsertrag bereit zum Abholen';

  @override
  String get homeShop => 'Shop';

  @override
  String get homeShopSubtitle => 'Emojis, Einsätze, Sammlungen';

  @override
  String get gamesTitle => 'Spiele';

  @override
  String get gamesFindMatch => 'Spiel finden';

  @override
  String get gamesMyTurn => 'Du bist dran';

  @override
  String get gamesWaiting => 'Warten';

  @override
  String get gamesLobbyTab => 'Lobby';

  @override
  String get gamesTicTacToe => 'Tic-Tac-Toe';

  @override
  String get gamesRules => 'Regeln';

  @override
  String get gamesRulesTitle => 'Spielregeln';

  @override
  String get gamesCreate => 'Spiel erstellen';

  @override
  String get gamesJoin => 'Beitreten';

  @override
  String get gamesOpponentTurn => 'Gegner ist dran';

  @override
  String get gamesCurrentGame => 'Aktuelles Spiel';

  @override
  String get gamesInvitedYou => 'Du wurdest eingeladen';

  @override
  String get gamesTurnTime => 'Zugzeit';

  @override
  String get gamesGridSize => 'Feldgröße';

  @override
  String get gamesSwapSides => 'Seitenwechsel';

  @override
  String get gamesNoCenter => 'Kein Zentrumsstart';

  @override
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Privates Spiel';

  @override
  String get lobbySearchingOpponent => 'Gegner wird gesucht…';

  @override
  String get lobbyWaitingJoin => 'Warte, bis jemand auf „Spiel finden“ oder „Beitreten“ tippt';

  @override
  String get lobbyInviteTitle => 'Spieleinladung';

  @override
  String get lobbyInvitedToPlay => 'Du wurdest zum Spielen eingeladen';

  @override
  String get lobbyEnterGame => 'Spiel betreten';

  @override
  String get lobbyInvite => 'Einladen';

  @override
  String get lobbyInviteSent => 'Einladung gesendet';

  @override
  String get lobbyCopyLink => 'Spiellink teilen';

  @override
  String get lobbyLinkCopied => 'Link kopiert';

  @override
  String get lobbyNoFriendsOnline => 'Keine Freunde online. Teile den Link oben oder warte, bis Freunde online sind.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Gegner';

  @override
  String get gameYouWon => 'Du hast gewonnen!';

  @override
  String get gameYouWonOpponentLeft => 'Du hast gewonnen — Gegner hat verlassen';

  @override
  String get gameYouWonOpponentTimeout => 'Du hast gewonnen — Zeit des Gegners ist abgelaufen';

  @override
  String get gameDraw => 'Unentschieden';

  @override
  String get gameExitTitle => 'Spiel verlassen';

  @override
  String get gameExitConfirm => 'Wenn du gehst, verlierst du. Trotzdem verlassen?';

  @override
  String get gameStay => 'Bleiben';

  @override
  String get gameLeave => 'Verlassen';

  @override
  String get gameConnecting => 'Verbindung zum Spiel…';

  @override
  String get gameWaitingOpponent => 'Warte auf Gegner';

  @override
  String get gameRematchOffer => 'Gegner bietet Revanche an';

  @override
  String get gameRematchDeclined => 'Gegner hat die Revanche abgelehnt';

  @override
  String get gameRematch => 'Revanche';

  @override
  String get gameOtherOpponent => 'Anderer Gegner';

  @override
  String get gameSwapSidesAction => 'Seiten tauschen';

  @override
  String get gameWriteMessage => 'Nachricht schreiben';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get chatsEmpty => 'Noch keine Chats.\nTippe oben rechts auf das Symbol, um einen Freund zu wählen und zu chatten.';

  @override
  String get chatsNewChat => 'Neuer Chat';

  @override
  String get chatsNoMessages => 'Keine Nachrichten';

  @override
  String get chatsClearTitle => 'Chat löschen?';

  @override
  String get chatsClearDesc => 'Der Chat wird dauerhaft gelöscht.';

  @override
  String get chatsClearConfirm => 'Löschen';

  @override
  String get chatsBlockTitle => 'Diesen Nutzer blockieren?';

  @override
  String get chatsBlockDesc => 'Ihr könnt euch nicht mehr schreiben. Chat und Freundschaft werden entfernt.';

  @override
  String get chatsBlockConfirm => 'Blockieren';

  @override
  String get chatsBlockedUsers => 'Blockierte Nutzer';

  @override
  String get chatsUnblock => 'Entblocken';

  @override
  String get chatDialog => 'Chat';

  @override
  String get chatEmpty => 'Noch keine Nachrichten.\nSchreib die erste.';

  @override
  String get chatMessageHint => 'Nachricht';

  @override
  String get chatEmoji => 'Emojis';

  @override
  String get chatBuyEmojiHint => 'Kaufe Emojis im Shop auf dem Startbildschirm';

  @override
  String get chatEditing => 'Bearbeitung';

  @override
  String get chatToday => 'Heute';

  @override
  String get chatYesterday => 'Gestern';

  @override
  String get chatFriendsOnly => 'Text nur für Freunde';

  @override
  String get emojiGroupEmotions => 'Emotionen';

  @override
  String get emojiGroupGame => 'Spiele';

  @override
  String get emojiGroupFlags => 'Flaggen';

  @override
  String get emojiGroupAnimals => 'Tiere';

  @override
  String get emojiGroupFood => 'Essen';

  @override
  String get emojiGroupTravel => 'Reisen';

  @override
  String get emojiGroupParty => 'Feier';

  @override
  String get emojiGroupObjects => 'Objekte';

  @override
  String get friendsTitle => 'Freunde';

  @override
  String get friendsTabFriends => 'Freunde';

  @override
  String get friendsTabIncoming => 'Eingehend';

  @override
  String get friendsTabOutgoing => 'Ausgehend';

  @override
  String get friendsAdd => 'Freund hinzufügen';

  @override
  String get friendsRequestSent => 'Anfrage gesendet';

  @override
  String get friendsFindTab => 'Freund finden';

  @override
  String get friendsSearchHint => 'Nach Benutzername suchen';

  @override
  String get friendsSearchPrompt => 'Nutze die Suche, um neue Freunde zu finden';

  @override
  String get friendsNothingFound => 'Nichts gefunden';

  @override
  String get friendsEmpty => 'Du hast noch keine Freunde';

  @override
  String get friendsNoIncoming => 'Keine eingehenden Anfragen';

  @override
  String get friendsNoOutgoing => 'Keine ausgehenden Anfragen';

  @override
  String get friendsAlreadyFriends => 'Bereits befreundet';

  @override
  String get friendsRemoveTitle => 'Aus Freunden entfernen?';

  @override
  String get friendsRemoved => 'Aus Freunden entfernt';

  @override
  String get friendsRequestAccepted => 'Anfrage angenommen';

  @override
  String get friendsRequestDeclined => 'Anfrage abgelehnt';

  @override
  String get friendsRequestCancelled => 'Anfrage abgebrochen';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSignInPrompt => 'Melde dich an';

  @override
  String get profileSignInHint => 'Um dein persönliches Profil einzurichten';

  @override
  String get profileEdit => 'Bearbeiten';

  @override
  String get profileCollections => 'Sammlungen';

  @override
  String get profileAge => 'Alter';

  @override
  String get profileGender => 'Geschlecht';

  @override
  String get profileGenderUnset => 'Nicht angegeben';

  @override
  String get profileGenderMale => 'Männlich';

  @override
  String get profileGenderFemale => 'Weiblich';

  @override
  String get profileAvatar => 'Avatar';

  @override
  String get profileUploadPhoto => 'Foto hochladen';

  @override
  String get profileChangePhoto => 'Foto ändern';

  @override
  String get shopTitle => 'Shop';

  @override
  String get shopEmojis => 'Emojis';

  @override
  String get shopEmojisSubtitle => 'Animierte Emojis für den Chat';

  @override
  String get shopCollections => 'Sammlungen';

  @override
  String get shopCollectionsSubtitle => 'Profilvitrine, Geschenke und Ertrag';

  @override
  String get shopStakes => 'Einsätze';

  @override
  String get shopStakesSubtitle => 'Silber-Einsätze freischalten';

  @override
  String get inventoryTitle => 'Gegenstände';

  @override
  String get inventoryEmpty => 'Noch nichts hier — schau im Shop vorbei';

  @override
  String get inventoryFrames => 'Rahmen';

  @override
  String get inventoryClaim => 'Abholen';

  @override
  String get inventorySell => 'Verkaufen';

  @override
  String get inventoryGift => 'Verschenken';

  @override
  String get messageEdited => 'bearbeitet';

  @override
  String get messageDeleted => 'Nachricht gelöscht';

  @override
  String get photo => 'Foto';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galerie';

  @override
  String get connectionError => 'Verbindung zum Server fehlgeschlagen.';

  @override
  String get serverError => 'Serverfehler. Bitte später erneut versuchen.';

  @override
  String get sessionExpired => 'Sitzung abgelaufen. Bitte erneut anmelden.';

  @override
  String get errNoInternet => 'Keine Internetverbindung.';

  @override
  String get errTimeout => 'Zeitüberschreitung. Bitte erneut versuchen.';

  @override
  String get errGamesUnavailable => 'Spiele sind vorübergehend nicht verfügbar';

  @override
  String get errSettingsSaveFailed => 'Einstellung konnte nicht gespeichert werden';

  @override
  String get errPushPermission => 'Erlaube Benachrichtigungen in den Browser- oder Systemeinstellungen.';
}
