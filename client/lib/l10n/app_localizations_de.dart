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
  String get settingsOfflineModeTitle => 'Netzwerkmodus';

  @override
  String get settingsOfflineModeSubtitle => 'Offline: sofort gegen einen Bot spielen, ohne Einsätze und Belohnungen, ohne Chats und Freunde. Käufe werden gespeichert und im Online-Modus angewendet. Online — wenn Internet verfügbar ist oder nach Benutzereinstellung.';

  @override
  String get settingsModeOnline => 'Online';

  @override
  String get settingsModeOffline => 'Offline';

  @override
  String get gamesAlternateStartsHint => 'Abwechselnd wer die Partie beginnt';

  @override
  String get rulesAlternateStarts => 'Wer zuerst zieht, wechselt von Partie zu Partie.';

  @override
  String get offlineBadgeTooltip => 'Offline-Modus';

  @override
  String get offlineModePopupTitle => 'Offline-Modus';

  @override
  String get offlineModePopupBody => 'Der Offline-Modus ist aktiv. Spiele gegen einen Bot ohne Einsätze und Belohnungen. Chats, Freunde und Lobby sind ausgeblendet. Käufe werden im Online-Modus angewendet.';

  @override
  String get offlineModePopupSettings => 'Einstellungen';

  @override
  String get gamesPlay => 'Spielen';

  @override
  String get offlineGameTitle => 'Spiel gegen Bot';

  @override
  String get offlineGameHint => 'Ohne Einsätze und Belohnungen · nur offline';

  @override
  String get offlineBotWon => 'Bot hat gewonnen';

  @override
  String get offlineBotThinking => 'Bot denkt nach…';

  @override
  String get offlinePlayAgain => 'Nochmal';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'Nehmen';

  @override
  String get durakActionAll => 'Alle';

  @override
  String get durakActionDone => 'Fertig';

  @override
  String get durakActionBito => 'Bito';

  @override
  String get durakHintDefend => 'Verteidigen';

  @override
  String get durakHintDefendOrTransfer => 'Verteidigen oder übergeben';

  @override
  String get durakHintOpponentDefends => 'Gegner verteidigt';

  @override
  String get durakHintThrowInFirst => 'Karten nachlegen (max. 5 im ersten Schlag)';

  @override
  String get durakHintThrowIn => 'Karten nachlegen oder auf die Abwehr warten';

  @override
  String get durakHintOpponentThrows => 'Gegner legt nach';

  @override
  String get durakHintTakeFollow => 'Nach dem Nehmen nachlegen oder „Fertig“';

  @override
  String get durakHintOpponentTakeFollow => 'Gegner kann nach dem Nehmen nachlegen';

  @override
  String get durakHintBito => 'Karte nachlegen oder „Bito“ sagen';

  @override
  String get durakHintOpponentBito => 'Gegner legt nach oder sagt „Bito“';

  @override
  String get durakHintYourAttack => 'Dein Zug — angreifen';

  @override
  String get durakHintOpponentAttack => 'Gegner greift an';

  @override
  String get durakHintYouLost => 'Du hast verloren — du bist der Narr';

  @override
  String get durakHintDrawAllOut => 'Unentschieden — alle sind raus';

  @override
  String get durakHintYouFinished => 'Du bist raus — warte aufs Ende';

  @override
  String get shopPurchaseQueued => 'Kauf gespeichert — wird im Online-Modus angewendet';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — Kauf angewendet';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — Kauf nicht angewendet: $reason';
  }

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
  String settingsAppVersion(String version) {
    return 'Version $version';
  }

  @override
  String get appUpdateTitle => 'Update verfügbar';

  @override
  String get appUpdateBody => 'Eine neue Version der App ist verfügbar. Bitte aktualisieren.';

  @override
  String get appUpdateWhatsNew => 'Neuigkeiten';

  @override
  String get appUpdateOk => 'Aktualisieren';

  @override
  String get appUpdateLaterBanner => 'Wir aktualisieren die App nach diesem Spiel';

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
  String timeMinutesAgo(int count) {
    return 'vor $count Min.';
  }

  @override
  String timeHoursAgo(int count) {
    return 'vor $count Std.';
  }

  @override
  String timeDaysAgo(int count) {
    return 'vor $count T.';
  }

  @override
  String get timeWeekAgo => 'vor einer Woche';

  @override
  String timeWeeksAgo(int count) {
    return 'vor $count Wo.';
  }

  @override
  String get timeMonthAgo => 'vor einem Monat';

  @override
  String timeMonthsAgo(int count) {
    return 'vor $count Mon.';
  }

  @override
  String get timeYearAgo => 'vor einem Jahr';

  @override
  String timeYearsAgo(int count) {
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
  String get gamesDurak => 'Durak';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => 'Drehen';

  @override
  String get gamesBattleshipSetupPhase => 'Setup';

  @override
  String get gamesBattleshipBattlePhase => 'Battle';

  @override
  String get gamesBattleshipWaitingOpponentSetup => 'Waiting for opponent…';

  @override
  String get gamesBattleshipYouWon => 'You won!';

  @override
  String get gamesBattleshipYouLost => 'You lost';

  @override
  String get rulesBattleshipTitle => 'Battleship — rules';

  @override
  String get rulesBattleshipBody => 'Place your ships on a 10×10 grid, then fire at the opponent’s cells. Sink the entire enemy fleet to win.';

  @override
  String get gamesPoker => 'Poker';

  @override
  String get gamesInDevelopment => 'In Entwicklung';

  @override
  String rulesPokerPlayers(int players) {
    return 'Spieler: $players.';
  }

  @override
  String get rulesPokerIntro => 'Texas Hold’em. Jeder erhält 2 Handkarten; 5 Gemeinschaftskarten liegen auf dem Tisch.';

  @override
  String get rulesPokerPlay => 'Wettrunden: Preflop, Flop, Turn und River. Fold, Call, Bet oder Raise.';

  @override
  String get rulesPokerWin => 'Gewonnen wird mit der besten Fünf-Karten-Hand (Hand + Community) oder wenn alle anderen folden.';

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
  String get gamesObservation => 'Zuschauen';

  @override
  String get gamesObservationHint => 'Du kannst bis zum Ende zuschauen';

  @override
  String get gamesFinishCurrentFirst => 'Beende zuerst dein aktuelles Spiel';

  @override
  String get gamesVariantClassic => 'Klassisch';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 Spieler';

  @override
  String get gamesVariantMulti4 => '4 Spieler';

  @override
  String get gamesDurakModePodkidnoi => 'Nachlegen';

  @override
  String get gamesDurakModePerevodnoi => 'Übergeben';

  @override
  String get gamesDurakDeck24 => '24 Karten';

  @override
  String get gamesDurakDeck36 => '36 Karten';

  @override
  String get gamesDurakDeck52 => '52 Karten';

  @override
  String rulesDurakMode(String mode) {
    return 'Modus: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'Spieler: $players. Deck: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Gegen einen Bot spielen, ohne Einsatz und Zeitlimit.';

  @override
  String get rulesDurakAttack => 'Der Angreifer legt Karten; der Verteidiger schlägt sie (gleiche Farbe höher oder Trumpf). Trumpf nur durch höheren Trumpf.';

  @override
  String get rulesDurakBeat => 'Sind alle Karten geschlagen, sagt der Angreifer „Bito“, und die Karten gehen auf den Ablagestapel. Sonst nimmt der Verteidiger alles.';

  @override
  String get rulesDurakLoser => 'Verlierer ist, wer am Ende noch Karten hat — der „Narr“.';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Spieler $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Lobby $name';
  }

  @override
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Privates Spiel';

  @override
  String get lobbySearchingOpponent => 'Gegner wird gesucht…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Suchen dieses Spiel: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Warte, bis jemand auf „Spiel finden“ oder „Beitreten“ tippt';

  @override
  String get lobbyInviteTitle => 'Spieleinladung';

  @override
  String get lobbyInvitedToPlay => 'Du wurdest zum Spielen eingeladen';

  @override
  String get lobbyEnterGame => 'Spiel betreten';

  @override
  String get lobbyGone => 'Lobby nicht mehr verfügbar';

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
  String get gameYouLost => 'Du hast verloren';

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
  String get gameSurrender => 'Aufgeben';

  @override
  String get gameSurrenderTitle => 'Aufgeben?';

  @override
  String get gameSurrenderConfirm => 'Du verlierst die Partie und die Einsatzmünzen.';

  @override
  String get gameOfferDraw => 'Remis anbieten';

  @override
  String get gameOfferDrawTitle => 'Remis anbieten?';

  @override
  String get gameOfferDrawConfirm => 'Dein Gegner kann das Remis annehmen oder ablehnen.';

  @override
  String get gameAcceptDrawTitle => 'Remis annehmen?';

  @override
  String get gameAcceptDrawConfirm => 'Die Partie endet unentschieden.';

  @override
  String get gameDrawOffered => 'Gegner bietet Remis an';

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
  String get chatPaste => 'Einfügen';

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
  String get shopStakesSubtitle => 'Höhere Einsätze freischalten';

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

  @override
  String get balanceTitle => 'Guthaben';

  @override
  String get coinBronze => 'Bronze';

  @override
  String get coinSilver => 'Silber';

  @override
  String get coinGold => 'Gold';

  @override
  String get coinDiamond => 'Diamant';

  @override
  String get balanceZeroBronze => '0 Bronze';

  @override
  String balanceBronzes(int count) {
    return '$count Bronze';
  }

  @override
  String balanceSilvers(int count) {
    return '$count Silber';
  }

  @override
  String balanceGolds(int count) {
    return '$count Gold';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count Diamanten';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/Tag';
  }

  @override
  String get balanceAbbrBronze => 'Br';

  @override
  String get balanceAbbrSilver => 'S.';

  @override
  String get balanceAbbrGold => 'G.';

  @override
  String get commonBackHome => 'Zurück zur Startseite';

  @override
  String get commonCopied => 'Kopiert';

  @override
  String get commonClear => 'Leeren';

  @override
  String get commonTryLater => 'Bitte später erneut versuchen.';

  @override
  String get commonTryRefresh => 'Versuchen Sie, die Seite zu aktualisieren.';

  @override
  String get coinsTitle => 'Münzen';

  @override
  String get coinsLoginReward => 'Login-Belohnung';

  @override
  String get coinsLoginAvailableToday => 'Heutige Belohnung verfügbar';

  @override
  String get coinsLoginStreak => 'Tägliche Login-Serie';

  @override
  String get coinsFriendReward => 'Freundesbelohnung';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount für die Registrierung über Ihren Link';
  }

  @override
  String get coinsLoadRewardsFailed => 'Belohnungen konnten nicht geladen werden';

  @override
  String get coinsClaimReward => 'Belohnung abholen';

  @override
  String get coinsAlreadyClaimed => 'Bereits erhalten';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · heute';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · noch 1 Tag';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · noch $remaining';
  }

  @override
  String get coinsInviteFriend => 'Freund einladen';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount für jeden, der sich über Ihren Link registriert';
  }

  @override
  String get coinsCopyLink => 'Link kopieren';

  @override
  String get coinsHowItWorks => 'So funktioniert’s';

  @override
  String get coinsHowStep1 => 'Link kopieren und an einen Freund senden';

  @override
  String get coinsHowStep2 => 'Der Freund registriert sich über diesen Link';

  @override
  String coinsHowStep3(String amount) {
    return 'Sie erhalten $amount';
  }

  @override
  String get achievementsTitle => 'Erfolge';

  @override
  String achievementsProgress(String progress) {
    return 'Fortschritt: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Rahmen erhalten';

  @override
  String get achievementsClaimed => 'Erhalten';

  @override
  String get achievementsOpenFrame => 'Rahmen öffnen';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Möchten Sie $name wirklich aus den Freunden entfernen?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Entfernen';

  @override
  String get friendsRemove => 'Aus Freunden entfernen';

  @override
  String get friendsAcceptRequest => 'Anfrage annehmen';

  @override
  String get friendsDeclineRequest => 'Anfrage ablehnen';

  @override
  String get friendsCancelRequest => 'Anfrage abbrechen';

  @override
  String get friendsSendRequest => 'Freundschaftsanfrage senden';

  @override
  String get friendsRequestAlreadySent => 'Anfrage bereits gesendet';

  @override
  String get friendsIncomingStatus => 'Eingehende Anfrage';

  @override
  String get friendsOutgoingStatus => 'Ausgehende Anfrage';

  @override
  String get friendsNotFriends => 'Keine Freunde';

  @override
  String get friendsCollapseSearch => 'Suche einklappen';

  @override
  String get friendsExpandSearch => 'Suche anzeigen';

  @override
  String get friendsLoadFailed => 'Freunde konnten nicht geladen werden';

  @override
  String friendsSince(String date) {
    return 'Befreundet seit: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Eingehende Anfrage: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Ausgehende Anfrage: $date';
  }

  @override
  String get userInfoTitle => 'Benutzerinfo';

  @override
  String profileAgeYears(int age) {
    return '$age Jahre';
  }

  @override
  String get shopBuy => 'Kaufen';

  @override
  String get shopBuyTitle => 'Kaufen?';

  @override
  String get shopBuyStakeTitle => 'Einsatz kaufen?';

  @override
  String get shopBuyEmojiTitle => 'Emoji kaufen?';

  @override
  String get shopBuyCollectionTitle => 'Sammlung kaufen?';

  @override
  String shopPrice(String price) {
    return 'Preis: $price';
  }

  @override
  String get shopOwned => 'Gekauft';

  @override
  String get shopEmpty => 'Noch leer';

  @override
  String shopPurchased(String title) {
    return '$title gekauft';
  }

  @override
  String get shopEmojiUses => 'Sie erhalten: 10 Nutzungen';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 Nutzungen';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 Nutzungen';
  }

  @override
  String get shopBuyTen => 'Kaufen · 10 Stk.';

  @override
  String shopDailyIncome(String amount) {
    return 'Einkommen: $amount';
  }

  @override
  String get shopBuyOnce => 'Einmaliger Kauf';

  @override
  String get shopSellRefund => 'Verkauf erstattet 80% des Preises';

  @override
  String shopCollectionAdded(String title) {
    return '$title zum Profil hinzugefügt';
  }

  @override
  String shopSetBonus(int percent) {
    return 'Set-Bonus +$percent%';
  }

  @override
  String get shopSetComplete => 'Vollständig';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Gesammelt · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Verkaufen?';

  @override
  String inventorySellDesc(String amount) {
    return 'Sie erhalten $amount';
  }

  @override
  String inventorySold(String amount) {
    return 'Verkauft: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Fügen Sie zuerst Freunde hinzu';

  @override
  String get inventoryGiftTitle => 'Sammlung verschenken?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return '„$title“ an $name verschenken?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Verschenkt: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'Der Spieler besitzt diesen Gegenstand bereits';

  @override
  String get inventoryGiftSelf => 'Du kannst dir selbst nichts schenken';

  @override
  String get inventoryGiftNotOwned => 'Dieser Gegenstand ist nicht in deinem Inventar';

  @override
  String get inventoryLoadFailed => 'Gegenstände konnten nicht geladen werden';

  @override
  String get inventoryNoCollections => 'Keine Sammlungen — im Shop kaufen';

  @override
  String get inventoryNoEmojis => 'Keine Emojis — im Shop kaufen';

  @override
  String get inventoryNoFrames => 'Keine Rahmen — gewinnen Sie 10 Ligaspielen (Erfolge)';

  @override
  String get inventoryNoStakes => 'Keine gekauften Einsätze';

  @override
  String inventoryEmojiLeft(int count) {
    return 'Noch $count';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Einkommen: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Einkommen morgen: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Bereit';

  @override
  String get inventoryIncomeTomorrowLabel => 'Morgen';

  @override
  String inventoryStakeGold(String amount) {
    return 'Sie können $amount Gold setzen';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'Sie können $amount Silber setzen';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'Erhalten +$amount';
  }

  @override
  String get chatsLoadFailed => 'Chats konnten nicht geladen werden';

  @override
  String get chatsLoadListFailed => 'Liste konnte nicht geladen werden';

  @override
  String get chatsBlockedEmpty => 'Liste ist leer';

  @override
  String chatsBlockedAt(String date) {
    return 'Blockiert: $date';
  }

  @override
  String get chatsCreateFailed => 'Chat konnte nicht erstellt werden';

  @override
  String get chatsNeedFriendsFirst => 'Fügen Sie zuerst Freunde hinzu, dann können Sie einen Chat öffnen.';

  @override
  String get chatsFriendsNotFound => 'Keine Freunde gefunden';

  @override
  String get chatsFindFriendHint => 'Freund nach Nickname suchen';

  @override
  String get chatsSelectChat => 'Chat auswählen';

  @override
  String get chatsSelectHint => 'Wählen Sie einen Dialog aus der Liste links';

  @override
  String get chatEditFailed => 'Nachricht konnte nicht bearbeitet werden';

  @override
  String get chatSendFailed => 'Nachricht konnte nicht gesendet werden';

  @override
  String get chatDeleteFailed => 'Nachricht konnte nicht gelöscht werden';

  @override
  String get chatEmojiSendFailed => 'Emoji konnte nicht gesendet werden';

  @override
  String get chatLoadFailed => 'Nachrichten konnten nicht geladen werden';

  @override
  String get chatBackToGame => 'Zurück zum Spiel';

  @override
  String get chatBackToChats => 'Zurück zu den Chats';

  @override
  String get chatActions => 'Chat-Aktionen';

  @override
  String get chatAutoTranslate => 'Auto-Übersetzung';

  @override
  String get chatScrollToEnd => 'Zum Ende der Unterhaltung';

  @override
  String chatReplyingTo(String name) {
    return 'Antwort an $name';
  }

  @override
  String get chatGift => 'Geschenk';

  @override
  String get chatCollection => 'Sammlung';

  @override
  String get chatGiftCollection => 'Geschenk · Sammlung';

  @override
  String get chatThisUser => 'diesen Benutzer';

  @override
  String get gamesLobbyLoadFailed => 'Lobby konnte nicht geladen werden.';

  @override
  String get gamesTapChangeStake => 'Tippen, um den Einsatz zu ändern';

  @override
  String get gamesTapChangeTurnTime => 'Tippen, um die Zugzeit zu ändern';

  @override
  String get gamesTapChangeGrid => 'Tippen, um die Rastergröße zu ändern';

  @override
  String get gamesSwapSidesHint => 'O kann nach dem 1. Zug zu X werden';

  @override
  String get gamesNoCenterHint => 'Erster Zug nicht in die Mitte';

  @override
  String get lobbyInviteSentShort => 'Gesendet';

  @override
  String get lobbyInvitesSentWaiting => 'Einladungen gesendet. Warte auf Antwort.';

  @override
  String get lobbyLinkCopiedHint => 'In einen Chat oder eine Nachricht an einen Freund einfügen';

  @override
  String get lobbyCopyLinkHint => 'Link in die Zwischenablage kopieren';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name lädt Sie zum Spielen ein';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name hat gewonnen';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Zeit abgelaufen. $name hat gewonnen';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String get adminTitle => 'Admin';

  @override
  String get tournamentsTitle => 'Turniere';

  @override
  String get profileAgeInvalid => 'Alter von 1 bis 111 eingeben';

  @override
  String get profileSaveFailed => 'Profil konnte nicht gespeichert werden';

  @override
  String get profileNameHint => 'Lateinische Buchstaben, Ziffern, _ bis 10 Zeichen';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'Von 1 bis 111';

  @override
  String get profileAboutHint => 'Bis 100 Zeichen (optional)';

  @override
  String get profileProcessingPhoto => 'Foto wird verarbeitet…';

  @override
  String get profileCropTitle => 'Avatar-Bereich wählen';

  @override
  String get profileCropHint => 'Foto zoomen und verschieben';

  @override
  String get profileApply => 'Übernehmen';

  @override
  String get profilePreparing => 'Vorbereitung…';

  @override
  String timeSecondsShort(int seconds) {
    return '$seconds s';
  }

  @override
  String get timeOneMin => '1 Min';

  @override
  String get timeTenMin => '10 Min';

  @override
  String rulesIntro(String grid) {
    return 'Tic-Tac-Toe auf einem $grid-Brett. Abwechselnd, X beginnt.';
  }

  @override
  String rulesWin(int n) {
    return 'Sieg: $n in einer Reihe horizontal, vertikal oder diagonal.';
  }

  @override
  String get rulesNoTimeLimit => 'Kein Zeitlimit pro Zug.';

  @override
  String rulesTurnTime(String time) {
    return 'Zeit pro Zug: $time.';
  }

  @override
  String rulesStake(String stake) {
    return 'Einsatz: $stake. Um so viele Münzen geht das Spiel.';
  }

  @override
  String get rulesSwap => 'Seitenwechsel: O kann nach dem ersten Zug von X mit X tauschen.';

  @override
  String get rulesNoCenter => 'Kein Zentrum: X darf im ersten Zug nicht in die Mitte setzen.';

  @override
  String get collectionSetLegends => 'Legenden';

  @override
  String get collectionSetSpace => 'Weltraum';

  @override
  String get collectionSetGems => 'Edelsteine';

  @override
  String get collectionSetParty => 'Feier';

  @override
  String get collectionSetNature => 'Natur';

  @override
  String get collectionSetAdventures => 'Abenteuer';

  @override
  String collectionCardMeta(String amount) {
    return 'Sammlung · Vitrine · Geschenk · Verkauf · +$amount';
  }

  @override
  String get coinsDayOne => 'Tag';

  @override
  String get coinsDayFew => 'Tage';

  @override
  String get coinsDayMany => 'Tage';

  @override
  String get giftFriendTitle => 'Freund beschenken';

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
    return '$count Emojis · je $price';
  }

  @override
  String get chatsExpandPanel => 'Panel ausklappen';

  @override
  String get chatsCollapsePanel => 'Panel einklappen';

  @override
  String get chatReplySourceMissing => 'Originalnachricht nicht gefunden';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Einsatz $n Silber';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Einsatz $n Gold';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Freischalten: $n Silber setzen';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Freischalten: $n Gold setzen';
  }

  @override
  String get chatReplySelf => 'sich selbst';

  @override
  String get chatReplyPeer => 'dem Gesprächspartner';

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
  String get statsLoadFailed => 'Statistik konnte nicht geladen werden';

  @override
  String get statsAllGames => 'Alle Spiele';

  @override
  String get statsEmptyTitle => 'Noch keine Spiele gespielt';

  @override
  String get statsEmptyHint => 'Spiele dein erstes Spiel, damit hier Statistiken erscheinen.';

  @override
  String get statsWins => 'Siege';

  @override
  String get statsDraws => 'Unentschieden';

  @override
  String get statsLosses => 'Niederlagen';

  @override
  String get statsWinRate => 'Siegquote';

  @override
  String get statsTopWon => 'Meiste Siege gegen';

  @override
  String get statsTopDrawn => 'Meiste Unentschieden mit';

  @override
  String get statsTopLost => 'Meiste Niederlagen gegen';

  @override
  String get statsTimePlayed => 'Spielzeit';

  @override
  String get statsYourScore => 'Euer Stand';

  @override
  String get profileShowStats => 'Statistik anzeigen';

  @override
  String get statsDurationZeroMinutes => '0 Min.';

  @override
  String get gameYouWonOpponentForfeit => 'Gegner hat aufgegeben. Du hast gewonnen!';

  @override
  String get lobbyLeaveTitle => 'Lobby verlassen?';

  @override
  String get lobbyLeaveConfirm => 'Die Lobby wird nach dem Verlassen gelöscht. Eingeladene Freunde erhalten eine Absage.';

  @override
  String get lobbyLeave => 'Verlassen';

  @override
  String statsDurationHours(int hours) {
    return '$hours Std.';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'Du hast aufgegeben. $name hat gewonnen';
  }

  @override
  String get supportTitle => 'Support';

  @override
  String get supportUnavailable => 'Support ist nicht verfügbar';

  @override
  String get supportOpenFailed => 'Support-Chat konnte nicht geöffnet werden';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Ihnen wurden $amount Münzen gutgeschrieben';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return '$amount Münzen wurden abgezogen';
  }

  @override
  String get coinsCreditCardTitle => 'Ihnen wurden Münzen gutgeschrieben';

  @override
  String get coinsClaim => 'Abholen';

  @override
  String get durakActionPass => 'Passen';

  @override
  String get durakRoleTook => 'Nimmt';

  @override
  String get durakRoleBeats => 'Schlägt';

  @override
  String get durakRoleThrowIn => 'Nachlegen';

  @override
  String get durakRoleTurn => 'Zug';

  @override
  String get durakRoleDefends => 'Verteidigt';

  @override
  String get durakStatusTaking => 'Nimmt';

  @override
  String get durakHintDefenderTurn => 'Zug des Verteidigers';

  @override
  String get gameYouEliminated => 'Du bist ausgeschieden';

  @override
  String gameYouPlaced(int place) {
    return 'Du bist $place. geworden';
  }

  @override
  String get gameOverNeutral => 'Spiel beendet';

  @override
  String gameTurnOf(String name) {
    return 'Zug von $name';
  }

  @override
  String get chatGroupTooltip => 'Gruppenchat';

  @override
  String get lobbyChatNotReady => 'Lobby-Chat ist noch nicht bereit';

  @override
  String get chatsGroupChat => 'Gruppenchat';

  @override
  String chatsMembersCount(int count) {
    return 'Mitglieder: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count Pers.';
  }

  @override
  String get chatsYouSuffix => '(du)';

  @override
  String get chatTitleDurak3 => 'Durak · 3 Spieler';

  @override
  String get chatTitleDurak4 => 'Durak · 4 Spieler';

  @override
  String get rulesTttUltimate => 'Ultimate: neun 3×3-Mini-Felder. Ein Zug schickt den Gegner auf dieses Mini-Feld. Gewonnen wird mit einer Linie auf dem Meta-Brett.';

  @override
  String get rulesTttMulti3 => '3 Spieler: 3×3-Feld, drei Spieler (X, O, △). Wer eine Linie aus eigenen Zeichen bildet, gewinnt.';

  @override
  String get rulesTttMulti4 => '4 Spieler: 4×4-Feld, vier Spieler (X, O, △, □). Wer eine Linie aus eigenen Zeichen bildet, gewinnt.';
}
