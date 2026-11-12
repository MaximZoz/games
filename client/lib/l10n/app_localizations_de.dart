import 'package:intl/intl.dart' as intl;

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
  String get settingsSoundTitle => 'Ton';

  @override
  String get settingsSoundSubtitle => 'Spiele und Benachrichtigungen';

  @override
  String get settingsSoundGames => 'Spiele';

  @override
  String get settingsSoundNotifications => 'Benachrichtigungen';

  @override
  String get settingsSoundTurn => 'Zug';

  @override
  String get settingsHapticsTitle => 'Vibration';

  @override
  String get settingsHapticsSubtitle => 'Nur Hinweise: Nachrichten, Anfragen, Ihr Zug und der Timer';

  @override
  String get settingsGamepadTitle => 'Controller';

  @override
  String get settingsGamepadSubtitle => 'Gamepad für Menüs und Partien';

  @override
  String settingsGamepadConnected(String name) {
    return 'Verbunden: $name';
  }

  @override
  String get settingsGamepadDisconnected => 'Kein Gamepad gefunden. Controller anschließen und eine Taste drücken.';

  @override
  String get settingsGamepadGenericName => 'Controller';

  @override
  String get settingsGamepadHelpNavigate => 'Navigation';

  @override
  String get settingsGamepadHelpConfirm => 'Wählen';

  @override
  String get settingsGamepadHelpBack => 'Zurück';

  @override
  String get settingsGamepadHelpTabs => 'Tabs';

  @override
  String get settingsGamepadHelpPlay => 'Feld- und Handcursor: Dame, Tic-Tac-Toe, Schiffe versenken, Durak, Uno, Poker und Backgammon';

  @override
  String get settingsGamepadHelpCards => 'Karten';

  @override
  String get settingsGamepadHelpKeyboard => 'Tastatur';

  @override
  String get settingsGamepadHelpBalance => 'Guthaben';

  @override
  String get settingsGamepadHelpLogout => 'Abmelden';

  @override
  String get settingsGamepadHelpPage => 'Seite';

  @override
  String get settingsGamepadLayoutXbox => 'Xbox-Belegung';

  @override
  String get settingsGamepadLayoutPlayStation => 'PlayStation-Belegung';

  @override
  String get settingsGamepadLayoutNintendo => 'Nintendo-Belegung';

  @override
  String get gamepadKeyboardTitle => 'Tastatur';

  @override
  String get gamepadKeyboardSpace => 'Leer';

  @override
  String get gamepadLegendConfirm => 'Wählen';

  @override
  String get gamepadLegendBack => 'Zurück';

  @override
  String get gamepadLegendTabs => 'Tabs';

  @override
  String get gamepadLegendCycle => 'Ändern';

  @override
  String gamepadConnectedSnack(String name) {
    return 'Controller verbunden: $name';
  }

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
  String get offlineModeOfferBody => 'Kein Internet oder die Verbindung ist sehr langsam. Du kannst den Offline-Modus einschalten und gegen einen Bot spielen.';

  @override
  String get offlineModeOfferAction => 'Offline einschalten';

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
  String get durakFirstLeadYou => 'Sie kommen raus';

  @override
  String get durakFirstLeadOpponent => 'Der Gegner kommt raus';

  @override
  String get durakFirstLeadBot => 'Der Bot kommt raus';

  @override
  String durakFirstLeadOf(String name) {
    return '$name kommt raus';
  }

  @override
  String get durakFirstLeadReason => 'Niedrigster Trumpf';

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
  String get openInApp => 'In der App öffnen';

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
  String get apiErrWrongGameType => 'Falscher Spieltyp';

  @override
  String get apiErrWrongGameTypeOrState => 'Falscher Spieltyp oder Zustand';

  @override
  String get apiErrLobbyFull => 'Lobby ist voll';

  @override
  String get apiErrBadState => 'Ungültiger Spielzustand';

  @override
  String get apiErrIllegalMove => 'Ungültiger Zug';

  @override
  String get apiErrUnknownMoveType => 'Unbekannter Zugtyp';

  @override
  String get apiErrNoOpponents => 'Keine Gegner';

  @override
  String get apiErrNoOpponentsRematch => 'Keine Gegner für ein Rematch';

  @override
  String get apiErrAlreadyInLobby => 'Du bist bereits in dieser Lobby';

  @override
  String get apiErrGameNotActive => 'Das Spiel ist nicht aktiv';

  @override
  String get apiErrNotInBattle => 'Nicht in der Kampfphase';

  @override
  String get apiErrNotInSetup => 'Nicht in der Aufstellungsphase';

  @override
  String get apiErrAlreadyReady => 'Du bist bereits bereit';

  @override
  String get apiErrAlreadyForfeited => 'Du hast bereits aufgegeben';

  @override
  String get apiErrYouHaveForfeited => 'Du hast aufgegeben';

  @override
  String get apiErrNoDrawOffer => 'Kein Remisangebot';

  @override
  String get apiErrDrawOnlyPvp => 'Remis nur gegen einen Spieler';

  @override
  String get apiErrDrawOnly1v1 => 'Remis nur im 1-gegen-1';

  @override
  String get apiErrDrawVsBot => 'Remis gegen einen Bot ist nicht möglich';

  @override
  String get apiErrDrawMultiplayer => 'Remis ist im Mehrspieler nicht verfügbar';

  @override
  String get apiErrDeck24TwoPlayers => '24er-Deck nur für 2 Spieler';

  @override
  String get apiErrDeck52ThreeOrFour => '52er-Deck erfordert 3 oder 4 Spieler';

  @override
  String get apiErrAccountFrozen => 'Konto ist eingefroren';

  @override
  String get apiErrTurnTimeInvalid => 'Zugzeit muss 0, 20, 60 oder 600 Sekunden sein';

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
  String get gamesBattleshipShipsMustNotTouch => 'Ships must not touch';

  @override
  String gamesBattleshipFleetScore(String name, int sunk, int left) {
    return '$name: $sunk versenkt, $left übrig';
  }

  @override
  String get rulesBattleshipTitle => 'Battleship — rules';

  @override
  String get rulesBattleshipPlayers => 'Players: 2.';

  @override
  String rulesBattleshipSetupTime(String time) {
    return 'Setup time: $time.';
  }

  @override
  String get rulesBattleshipIntro => '10×10 grid. Fleet: one 4-deck, two 3-deck, three 2-deck and four 1-deck ships. Ships must not touch, including diagonally.';

  @override
  String get rulesBattleshipSetup => 'If setup time runs out, the current valid placement is kept; if it is invalid, a default layout is used.';

  @override
  String get rulesBattleshipPlay => 'After setup, a random player shoots first. Fire at the opponent’s cells: a hit grants another shot, a miss passes the turn. On your turn you see the opponent’s board; on theirs you see yours.';

  @override
  String get rulesBattleshipWin => 'The first to sink the entire enemy fleet wins.';

  @override
  String get gamesPoker => 'Poker';

  @override
  String get gamesUno => 'Uno';

  @override
  String get gamesNardy => 'Backgammon';

  @override
  String get gamesNardyModeShort => 'Kurz';

  @override
  String get gamesNardyModeLong => 'Lang';

  @override
  String get gamesCheckers => 'Dame';

  @override
  String get gamesCheckersModeRussian => 'Russisch';

  @override
  String get gamesCheckersModeEnglish => 'Englisch';

  @override
  String get gamesCheckersModeGiveaway => 'Verlierdame';

  @override
  String get gamesCheckersModeCorners => 'Ecken';

  @override
  String get gamesChess => 'Schach';

  @override
  String get gamesDomino => 'Domino';

  @override
  String get gamesDominoModeKozel => 'Ziegenbock';

  @override
  String get gamesDominoModeClassic => 'Klassisch';

  @override
  String get gamesDominoModeSea => 'See';

  @override
  String get rulesDominoDeal => 'Jeder erhält 7 Steine. Bei 2 oder 3 Spielern liegt der Rest im Boneyard, bei 4 ist er leer.';

  @override
  String get rulesDominoOpen => 'Die erste Runde beginnt mit dem niedrigsten Doppel von 1-1 bis 6-6, dann 0-0. Gibt es kein Doppel, beginnt der höchste Stein und muss gelegt werden.';

  @override
  String get rulesDominoPlay => 'Ein Stein wird an ein offenes Ende mit derselben Zahl gelegt. Ein Doppel am Ende ändert diese Zahl nicht.';

  @override
  String get rulesDominoDraw => 'Wer nicht legen kann, zieht einzeln, bis ein passender Stein kommt oder der Boneyard leer ist. Der letzte Stein darf genommen werden. Geht es dann immer noch nicht, wird gepasst.';

  @override
  String get rulesDominoScore => 'Am Rundenende zählt jeder die Augen seiner Steine. Wer auslegt, schreibt 0. Bis 101: Wer sie erreicht, ist der Ziegenbock und verliert.';

  @override
  String get rulesDominoFish => 'Fisch: Der Boneyard ist leer und niemand kann legen. Die eindeutig kleinste Augensumme schreibt 0, die anderen ihre Summe. Ist das Minimum gleich, schreiben alle.';

  @override
  String get rulesDominoMatch => 'Überschreiten mehrere in einer Runde 101, ist der höchste Stand der Ziegenbock. Gewinner sind die mit dem niedrigsten Stand. Sind alle gleich, ist es unentschieden.';

  @override
  String get rulesDominoOffline => 'Offline: du und Bots. Der Bot zählt die Zahlen und schaut nicht in verdeckte Hände.';

  @override
  String rulesDominoMode(String mode) {
    return 'Modus: $mode';
  }

  @override
  String get rulesDominoClassicDeal => 'Zwei oder drei Spieler erhalten 7 Steine, vier Spieler 5. Der Rest ist der Markt.';

  @override
  String get rulesDominoClassicOpen => 'Die erste Runde beginnt mit dem Doppel-6, dann der Blanke, dann kleinere Doppel. Ohne Doppel muss der höchste Stein gelegt werden.';

  @override
  String get rulesDominoClassicScore => 'Wer ausgeht, schreibt die Augen der Gegner gut. Wer zuerst 100 erreicht, gewinnt.';

  @override
  String get rulesDominoClassicFish => 'Bei Fisch schreibt die eindeutig leichteste Hand die Differenz zu jeder anderen. Bei Gleichstand gibt es keine Punkte.';

  @override
  String get rulesDominoClassicMatch => 'Wer den höchsten Stand teilt, gewinnt gemeinsam. Sind alle gleich, ist es unentschieden.';

  @override
  String get rulesDominoSeaSame => 'Geben, Eröffnung und Nachziehen wie beim Ziegenbock. Die Kette hat zwei Enden.';

  @override
  String get rulesDominoSeaScore => 'Nur die schwerste Hand schreibt Punkte. Unter 25 wird nichts gutgeschrieben.';

  @override
  String get rulesDominoSeaWipe => 'Haben zwei Spieler 25 oder mehr, schreibt niemand diese Runde.';

  @override
  String get rulesDominoSeaBlank => '0-0 beendet die Runde sofort: der eindeutig schwerste Gegner bekommt 75. Bei Gleichstand niemand.';

  @override
  String get rulesDominoSeaSix => 'Wer mit 6-6 ausgeht, schreibt dem Verlierer 100 und setzt den eigenen Partiestand auf null.';

  @override
  String get rulesDominoSeaMatch => 'Die Partie geht bis 125. Wer sie erreicht, verliert.';

  @override
  String get dominoBoneyard => 'Boneyard';

  @override
  String get dominoChooseEnd => 'Ende wählen';

  @override
  String get dominoFish => 'Fisch';

  @override
  String get dominoYouGoat => 'Du bist der Ziegenbock';

  @override
  String dominoGoatNamed(String name) {
    return 'Ziegenbock — $name';
  }

  @override
  String get dominoLeft => 'Links';

  @override
  String get dominoRight => 'Rechts';

  @override
  String get gamesChessModeClassic => 'Klassisch';

  @override
  String get gamesChessModeRapid => 'Rapid';

  @override
  String get gamesChessModeBlitz => 'Blitz';

  @override
  String get gamesChessModeBullet => 'Bullet';

  @override
  String get chessPieceQueen => 'Dame';

  @override
  String get chessPieceRook => 'Turm';

  @override
  String get chessPieceBishop => 'Läufer';

  @override
  String get chessPieceKnight => 'Springer';

  @override
  String get chessPromotionTitle => 'Bauernumwandlung';

  @override
  String get chessDrawStalemate => 'Remis: Patt';

  @override
  String get chessDrawInsufficient => 'Remis: ungenügendes Material';

  @override
  String get chessDrawRepetition => 'Remis: dreifache Stellungswiederholung';

  @override
  String get chessDrawFiftyMove => 'Remis: 50-Züge-Regel';

  @override
  String get chessCheck => 'Schach';

  @override
  String get rulesCheckersPlayers => 'Spieler: 2.';

  @override
  String rulesCheckersMode(String mode) {
    return 'Modus: $mode.';
  }

  @override
  String rulesCheckersTime(String time) {
    return 'Время на ход: $time. Если время вышло — проигрыш.';
  }

  @override
  String get rulesCheckersIntro => 'Brett 8×8. Zwei Spieler.';

  @override
  String get rulesCheckersPlay => 'Schlagen ist Pflicht. Dame und Stein müssen weiterschlagen, solange vom Landefeld ein weiterer Schlag möglich ist — in der Mitte anhalten ist verboten. Gibt es mehrere Richtungen, darf jede gewählt werden, nicht zwingend die längste. Ein Stein auf der letzten Reihe wird zur Dame.';

  @override
  String get rulesCheckersWin => 'В русских шашках побеждает тот, кто съел все шашки соперника или лишил его хода. В поддавках наоборот: кто не может ходить — выигрывает.';

  @override
  String get rulesCheckersOfflineBot => 'Офлайн: партия против бота.';

  @override
  String get rulesCheckersPlayRussian => 'Russisches Damespiel: je 12 Steine auf dunklen Feldern. Bauern ziehen diagonal vorwärts und schlagen vorwärts und rückwärts. Damen fliegen beliebig weit. Schlagen ist Pflicht: weiterzuschlagen, wenn möglich, aber bei mehreren Richtungen darf jede gewählt werden, nicht zwingend die längste. Es gewinnt, wer alle Steine schlägt oder den Gegner bewegungsunfähig macht.';

  @override
  String get rulesCheckersPlayEnglish => 'Englisches Damespiel: je 12 Steine. Bauern ziehen und schlagen nur diagonal vorwärts. Damen ziehen ein Feld diagonal in jede Richtung. Schlagen ist Pflicht. Es gewinnt, wer alle Steine schlägt oder den Gegner bewegungsunfähig macht.';

  @override
  String get rulesCheckersPlayGiveaway => 'Verlierdame: dieselben Züge wie im russischen Damespiel, aber das Ziel ist umgekehrt — alle eigenen Steine abgeben oder keinen Zug mehr haben. Schlagen bleibt Pflicht.';

  @override
  String get rulesCheckersPlayCorners => 'Ecken: die Steine stehen in gegenüberliegenden Ecken. Ziehe auf ein benachbartes freies Feld waagerecht oder senkrecht oder springe über einen beliebigen Stein, ohne ihn zu schlagen. Ziel ist, alle eigenen Steine in die Ecke des Gegners zu bringen.';

  @override
  String get rulesCheckersPlayCornersNoReturn => 'Ein Stein, der seine Start-Ecke verlassen hat, darf nicht dorthin zurückkehren.';

  @override
  String get rulesCheckersPlayCornersLeaveHome => 'Steine, die das Haus noch nicht verlassen haben, müssen es in den ersten 25 Zügen des Spielers verlassen.';

  @override
  String get rulesCheckersDrawRussian => 'Remis, wenn die Stellung dreimal vorkommt oder 15 Züge jeder Seite keinen Fortschritt bringen: kein Schlagen, kein Steinzug und keine Umwandlung.';

  @override
  String get rulesCheckersDrawEnglish => 'Remis, wenn die Stellung dreimal vorkommt, 40 Züge jeder Seite ohne Schlagen und Steinzug vergehen oder nur noch eine Dame je Seite bleibt.';

  @override
  String get rulesCheckersDrawGiveaway => 'Remis, wenn die Stellung dreimal vorkommt oder 15 Züge jeder Seite im Weggeben keinen Fortschritt bringen: kein Schlagen, kein Steinzug und keine Umwandlung.';

  @override
  String get rulesCheckersDrawCorners => 'Remis, wenn die Stellung dreimal vorkommt oder 25 Züge jeder Seite keinen Stein in die Zielecke bringen.';

  @override
  String get rulesChessPlayers => 'Spieler: 2.';

  @override
  String rulesChessMode(String mode) {
    return 'Modus: $mode.';
  }

  @override
  String get rulesChessPlayClassic => 'Brett 8×8. Jede Seite hat König, Dame, zwei Türme, zwei Läufer, zwei Springer und acht Bauern. Weiß zieht zuerst. Übliche Züge, en passant, Umwandlung und Rochade. Gewinn durch Matt oder Aufgabe.';

  @override
  String get rulesChessDrawClassic => 'Remis bei Patt, dreifacher Wiederholung, 50-Züge-Regel, fehlendem Mattmaterial oder Einigung.';

  @override
  String get rulesChessClockClassic => 'Partieuhr: 60+0 — 60 Minuten für die ganze Partie, ohne Zusatz.';

  @override
  String get rulesChessClockRapid => 'Partieuhr: 10+0 — 10 Minuten für die ganze Partie, ohne Zusatz.';

  @override
  String get rulesChessClockBlitz => 'Partieuhr: 5+0 — 5 Minuten für die ganze Partie, ohne Zusatz.';

  @override
  String get rulesChessClockBullet => 'Partieuhr: 3+2 — 3 Minuten plus 2 Sekunden pro Zug.';

  @override
  String get checkersDrawRepetition => 'Remis — Stellung dreimal wiederholt';

  @override
  String get checkersDrawNoProgress => 'Remis — Züge führen nicht zum Sieg';

  @override
  String get checkersDrawInsufficient => 'Remis — nicht genug Material zum Sieg';

  @override
  String get rulesNardyTitle => 'Backgammon — Regeln';

  @override
  String get rulesNardyPlayers => 'Spieler: 2.';

  @override
  String rulesNardyMode(String mode) {
    return 'Modus: $mode.';
  }

  @override
  String get rulesNardyIntro => 'Brett mit 24 Punkten, je 15 Steine. Zwei Würfel: ein Stein die Summe oder zwei Steine die einzelnen Augen.';

  @override
  String get rulesNardyPlayShort => 'Kurzes Backgammon: ihr zieht aufeinander zu und dürft einzelne Steine schlagen. Ein geschlagener Stein kommt auf die Bar und muss wieder einsetzen. Sind alle Steine im Haus, werdet ihr sie ab.';

  @override
  String get rulesNardyPlayLong => 'Langes Backgammon: beide starten vom selben Kopf und ziehen in dieselbe Richtung. Pro Zug darf nur ein Stein den Kopf verlassen. Schlagen ist verboten. Sind alle im Haus, werdet ihr sie ab.';

  @override
  String get rulesNardyWin => 'Wer zuerst alle Steine abgetragen hat, gewinnt.';

  @override
  String get rulesNardySixPrime => 'Sechs Punkte in Folge darfst du erst sperren, wenn mindestens ein gegnerischer Stein daran vorbei ist.';

  @override
  String get nardyRoll => 'Würfeln';

  @override
  String get nardySkipTurn => 'Zug überspringen';

  @override
  String get nardyUndoMove => 'Zurück';

  @override
  String get nardyDoneTurn => 'Fertig';

  @override
  String get nardyAutoConfirm => 'Auto-Bestätigung';

  @override
  String get nardyAutoConfirmHint => 'Zug nach allen Zügen automatisch übergeben';

  @override
  String get nardyLayoutToggle => 'Aufstellung wechseln';

  @override
  String get nardyNoMoves => 'Kein Zug möglich';

  @override
  String get nardyYourRoll => 'Dein Wurf';

  @override
  String get nardyPipsShort => 'Rest:';

  @override
  String get nardyYouWonMars => 'Gewonnen — Gammon!';

  @override
  String get nardyYouLostMars => 'Verloren — Gammon';

  @override
  String get rulesNardyOfflineBot => 'Offline: Partie gegen den Bot.';

  @override
  String rulesUnoPlayers(int players) {
    return 'Spieler: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'Spiel gegen einen Bot, ohne Zugzeitlimit.';

  @override
  String get rulesUnoIntro => 'Jeder erhält 7 Karten. Spiele eine Karte derselben Farbe oder desselben Rangs (Zahl oder gleiche Aktion).';

  @override
  String get rulesUnoPlay => 'Aussetzen — der Nächste verliert den Zug. Richtungswechsel zu zweit wirkt wie Aussetzen. +2 nur auf +2 und +4 nur auf +4: die Strafe addiert sich (zwei +2 bedeuten 4 ziehen). +2 darf nicht auf +4. Wer nicht stapelt, zieht den ganzen Stapel und setzt aus. Zwei gleiche nicht-schwarze Karten (z. B. zwei gelbe 8) werden zusammen abgelegt: eine spielen — die zweite fliegt automatisch mit.';

  @override
  String get rulesUnoWild => 'Eine schwarze Karte bestimmt eine neue Farbe. +4 nur, wenn du keine Karte der aktuellen Farbe hast. Der Nächste kann anfechten: war +4 legal, zieht er 6; sonst zieht der +4-Spieler 4 und der Anfechtende ist am Zug.';

  @override
  String get rulesUnoDraw => 'Ohne passende Karte ziehe eine vom Stapel. Passt sie, darfst du sie sofort spielen oder behalten und passen. Ziehen ist verboten, solange ein legaler Zug möglich ist.';

  @override
  String get rulesUnoWin => 'Zu zweit bis 100 Punkte, bei drei oder mehr Spielern bis 200. Eine Runde gewinnt, wer alle Karten ablegt.';

  @override
  String get rulesUnoCall => 'Wenn noch eine Karte übrig ist, tippen Sie sofort auf „Uno!“. Gegner können Sie erst nach einer Sekunde wegen vergessenem Uno erwischen — dann ziehen Sie 2 Karten.';

  @override
  String get rulesUnoScoring => 'Wer zuerst alle Karten ablegt, gewinnt die Runde und erhält Punkte für die Hände der Gegner: Zahlen nach Wert, Aktionen 20, Schwarze 50. Zu zweit bis 100, bei drei oder mehr Spielern bis 200.';

  @override
  String get unoColorRed => 'Rot';

  @override
  String get unoColorYellow => 'Gelb';

  @override
  String get unoColorGreen => 'Grün';

  @override
  String get unoColorBlue => 'Blau';

  @override
  String get unoDraw => 'Ziehen';

  @override
  String get unoKeep => 'Behalten';

  @override
  String get unoSayUno => 'Uno!';

  @override
  String get unoChallengeUno => 'Uno anfechten';

  @override
  String get unoChallengeWd4 => '+4 anfechten';

  @override
  String get unoChooseColor => 'Farbe wählen';

  @override
  String get unoDrawPile => 'Ziehstapel';

  @override
  String get unoDiscardPile => 'Ablage';

  @override
  String unoCardsCount(int count) {
    return 'Karten: $count';
  }

  @override
  String unoScore(int score) {
    return 'Punkte: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'Runde $round · bis $target';
  }

  @override
  String get unoYourTurn => 'Du bist dran';

  @override
  String get unoWaitingTurn => 'Gegner ist dran';

  @override
  String get unoChooseColorHint => 'Wähle eine Farbe für die schwarze Karte';

  @override
  String get unoWd4Hint => 'Ziehe 4 Karten oder fechte Wild +4 an';

  @override
  String get unoDrawnHint => 'Spiele die gezogene Karte oder behalte sie';

  @override
  String get unoPlayHint => 'Spiele eine passende Farbe oder einen passenden Wert';

  @override
  String get unoDrawHint => 'Keine passende Karte — ziehe vom Stapel';

  @override
  String unoPendingDraw(int count) {
    return '+$count Karten';
  }

  @override
  String get unoYouWon => 'Du hast das Match gewonnen!';

  @override
  String get unoYouLost => 'Match beendet';

  @override
  String get unoYouLostTimeout => 'Sie haben durch Zeit verloren';

  @override
  String unoWinner(String name) {
    return 'Gewinner: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name gewinnt die Runde';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'Weiter';

  @override
  String get unoRoundScoresTitle => 'Rundenpunkte';

  @override
  String get unoDirectionClockwise => 'Im Uhrzeigersinn';

  @override
  String get unoDirectionCounterclockwise => 'Gegen den Uhrzeigersinn';

  @override
  String get unoErrStackSameOnly => 'Auf +2 darf nur +2, auf +4 nur +4 gelegt werden. +2 auf +4 ist nicht erlaubt.';

  @override
  String get unoErrCatchTooEarly => 'Einen Moment — sie können noch UNO sagen.';

  @override
  String get unoErrCallTooLate => 'UNO sagen geht nicht mehr: der nächste Spieler hat bereits gezogen.';

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
  String get pokerFold => 'Fold';

  @override
  String get pokerCheck => 'Check';

  @override
  String pokerCall(int amount) {
    return 'Call $amount';
  }

  @override
  String get pokerCallShort => 'Call';

  @override
  String get pokerRaise => 'Raise';

  @override
  String pokerRaiseTo(int amount) {
    return 'Raise to $amount';
  }

  @override
  String get pokerRaiseTitle => 'Raise';

  @override
  String get pokerAllIn => 'All-in';

  @override
  String get pokerAllInBadge => 'All-in';

  @override
  String get pokerFolded => 'Folded';

  @override
  String pokerPot(int amount) {
    return 'Pot: $amount';
  }

  @override
  String get pokerYourTurn => 'Your turn';

  @override
  String pokerToAct(String name) {
    return '$name to act';
  }

  @override
  String pokerWinner(String name) {
    return '$name wins';
  }

  @override
  String get pokerYouWonHand => 'You won the pot!';

  @override
  String pokerWinners(String names) {
    return '$names win';
  }

  @override
  String pokerYouWonHandWith(String names) {
    return 'You and $names won the pot!';
  }

  @override
  String get pokerListAnd => 'and';

  @override
  String get pokerHandOver => 'Hand over';

  @override
  String get pokerStreetPreflop => 'Pre-flop';

  @override
  String get pokerStreetFlop => 'Flop';

  @override
  String get pokerStreetTurn => 'Turn';

  @override
  String get pokerStreetRiver => 'River';

  @override
  String get pokerStreetShowdown => 'Showdown';

  @override
  String get pokerHandHighCard => 'High card';

  @override
  String get pokerHandOnePair => 'One pair';

  @override
  String get pokerHandTwoPair => 'Two pair';

  @override
  String get pokerHandThreeOfAKind => 'Three of a kind';

  @override
  String get pokerHandStraight => 'Straight';

  @override
  String get pokerHandFlush => 'Flush';

  @override
  String get pokerHandFullHouse => 'Full house';

  @override
  String get pokerHandFourOfAKind => 'Four of a kind';

  @override
  String get pokerHandStraightFlush => 'Straight flush';

  @override
  String get pokerHandRoyalFlush => 'Royal flush';

  @override
  String get pokerCombinationsTitle => 'Kombinationen';

  @override
  String pokerHandNumber(int n) {
    return 'Hand $n';
  }

  @override
  String pokerBlinds(int sb, int bb) {
    return 'Blinds $sb/$bb';
  }

  @override
  String get pokerTableYouWon => 'You won the table!';

  @override
  String get pokerNextHandSoon => 'Next hand…';

  @override
  String get pokerShowCards => 'Show cards';

  @override
  String get rulesPokerTable => 'The table plays until one player holds all the chips. Blinds rise every 6–8 hands (heads-up 8, 3-max 7, 4-max 6).';

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
  String get gameYou => 'Du';

  @override
  String get gameYouWon => 'Du hast gewonnen!';

  @override
  String get gameYouWonShort => 'Du hast gewonnen';

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
  String get gameFlipBoard => 'Brett drehen';

  @override
  String get gameReviewStart => 'Zum Partiestart';

  @override
  String get gameReviewPrev => 'Zug zurück';

  @override
  String get gameReviewNext => 'Zug vor';

  @override
  String get gameReviewEnd => 'Zur aktuellen Stellung';

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
  String get friendsSearchNoMatches => 'Keine Freunde entsprechen der Suche';

  @override
  String get friendsIncomingSearchNoMatches => 'Keine eingehenden Anfragen zur Suche';

  @override
  String get friendsOutgoingSearchNoMatches => 'Keine ausgehenden Anfragen zur Suche';

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
  String get profileChangePhoto => 'Avatar ändern';

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
  String get shopEmojisHelp => 'Animierte Emojis für den Chat. Kaufe ein Set und sende sie in Nachrichten an Freunde.';

  @override
  String get shopCollectionsHelp => 'Verkaufen kannst du nur eine neue oder Vintage-Sammlung: 80 % des Preises, wenn sie neu ist, und 300 % des Preises, wenn sie Vintage ist. Abgenutzte, müde und schäbige Sammlungen lassen sich nicht verkaufen.\n\nSammle einen Satz Gegenstände: Sie erscheinen in deiner Profilvitrine und können verschenkt werden. Jeder Gegenstand bringt jeden Tag Münzen, und ein vollständiger Satz zusätzlich einen eigenen Bonus.\n\nDas tägliche Einkommen eines Gegenstands hängt vom Zustand ab und ist ein Anteil der üblichen Summe. Neu bringt 100 %. Abgenutzt bringt 60 %. Müde bringt 40 %. Schäbig bringt 100 %. Ein Vintage-Gegenstand bringt 200 %, also doppelt so viel wie üblich.\n\nDer Bonus eines vollständigen Satzes bleibt gleich, bis der Satz selbst Vintage ist. Ein Satz ist Vintage, wenn jeder Gegenstand darin Vintage ist: der Bonus beträgt dann 300 %, das Dreifache des Üblichen.\n\nDer Zustand hängt davon ab, wie lange der Gegenstand bei dir ist. Neu — die ersten 7 Tage. Abgenutzt — vom 8. Tag bis 2 Monate. Müde — von 2 bis 6 Monaten. Schäbig — von 6 Monaten bis 1 Jahr. Vintage — ab 1 Jahr.';

  @override
  String get shopStakesHelp => 'Schalte höhere Einsätze in Spielen frei. Je höher der Einsatz, desto größer sind Pot und Gewinn.';

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
  String loadErrorTimeout(int seconds) {
    return 'Der Server hat innerhalb von $seconds s nicht geantwortet. Prüfen Sie das Internet und tippen Sie auf „Wiederholen“.';
  }

  @override
  String get loadErrorTimeoutUnknown => 'Der Server hat nicht rechtzeitig geantwortet. Prüfen Sie das Internet und tippen Sie auf „Wiederholen“.';

  @override
  String get loadErrorNoConnection => 'Keine Verbindung zum Server. Prüfen Sie das Internet und tippen Sie auf „Wiederholen“.';

  @override
  String get loadErrorUnavailable => 'Der Server ist gerade nicht erreichbar. Warten Sie kurz und tippen Sie auf „Wiederholen“.';

  @override
  String get loadErrorGeneric => 'Die Anfrage wurde nicht ausgeführt. Tippen Sie auf „Wiederholen“. Wenn der Fehler bleibt, prüfen Sie das Internet.';

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
  String get coinsTasks => 'Aufgaben';

  @override
  String get coinsTasksSubtitle => 'Belohnungen für Profil, Freunde und Spiele';

  @override
  String get coinsTasksRewards => 'Belohnungen zum Abholen';

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
  String get shopHave => 'Vorhanden';

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
  String get shopSellRefund => 'Der Verkauf hängt vom Zustand der Sammlung ab';

  @override
  String get collectionConditionNew => 'Neu';

  @override
  String get collectionConditionWorn => 'Abgenutzt';

  @override
  String get collectionConditionTired => 'Müde';

  @override
  String get collectionConditionShabby => 'Schäbig';

  @override
  String get collectionConditionVintage => 'Vintage';

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
  String get inventoryCollectionNotSellable => 'Verkaufen kannst du nur eine neue oder Vintage-Sammlung.';

  @override
  String get inventoryCollectionNotSellableTitle => 'Nicht verkaufbar';

  @override
  String get inventoryCollectionNotSellableHint => 'Verkaufen kannst du nur einen neuen oder Vintage-Gegenstand. Nutze ein Elixier, um den Zustand zu ändern.';

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
  String get lobbySearchShort => 'Suche';

  @override
  String get lobbySearchPlayers => 'Spieler suchen';

  @override
  String get lobbyInviteDeclinedShort => 'Abgelehnt';

  @override
  String get lobbyInvitesSentWaiting => 'Einladungen gesendet. Warte auf Antwort.';

  @override
  String get lobbyLinkCopiedHint => 'In einen Chat oder eine Nachricht an einen Freund einfügen';

  @override
  String get lobbyCopyLinkHint => 'Link in die Zwischenablage kopieren';

  @override
  String lobbyCreatorInvites(String name, String game) {
    return '$name lädt Sie ein, $game zu spielen';
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
  String get profileGalleryTitle => 'Fotos';

  @override
  String get profileGalleryAdd => 'Foto hinzufügen';

  @override
  String get profileMakePrimary => 'Als Hauptbild';

  @override
  String get profilePhotoDelete => 'Foto löschen';

  @override
  String get profilePhotosLimit => 'Maximal 3 Fotos';

  @override
  String get profilePhotosEmpty => 'Noch keine Fotos';

  @override
  String get profilePhotoUploadFailed => 'Foto konnte nicht hochgeladen werden';

  @override
  String get profilePhotoDeleteFailed => 'Foto konnte nicht gelöscht werden';

  @override
  String get profilePhotoTooLarge => 'Foto ist zu groß';

  @override
  String get profileSetPrimaryFailed => 'Konnte nicht als Hauptbild gesetzt werden';

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
    return 'Zeit pro Zug: $time. Zeitüberschreitung bedeutet Niederlage.';
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

  @override
  String get adminUsersTab => 'Nutzer';

  @override
  String get adminSupportTab => 'Support';

  @override
  String get adminSearchHint => 'Suche nach E-Mail oder Namen';

  @override
  String get adminRoleAdmins => 'Admins';

  @override
  String get adminRoleUsers => 'Nutzer';

  @override
  String get adminRoleAll => 'Alle Rollen';

  @override
  String get adminStatusFrozen => 'Eingefroren';

  @override
  String get adminStatusActive => 'Aktiv';

  @override
  String get adminStatusAny => 'Jeder Status';

  @override
  String get adminOrderDesc => 'Absteigend';

  @override
  String get adminOrderAsc => 'Aufsteigend';

  @override
  String adminLoadFailed(String error) {
    return 'Laden fehlgeschlagen: $error';
  }

  @override
  String get adminUsersEmpty => 'Keine Nutzer gefunden';

  @override
  String get adminSortLastSeen => 'Nach letztem Besuch';

  @override
  String get adminSortEmail => 'Nach E-Mail';

  @override
  String get adminSortCreated => 'Nach Registrierung';

  @override
  String adminBronzeBalance(int amount) {
    return '$amount Br.';
  }

  @override
  String get adminRevokeAdmin => 'Admin entfernen';

  @override
  String get adminGrantAdmin => 'Zum Admin machen';

  @override
  String get adminAdminRevoked => 'Adminrechte entfernt';

  @override
  String get adminAdminGranted => 'Adminrechte vergeben';

  @override
  String get adminGrantCoins => 'Münzen gutschreiben';

  @override
  String get adminWriteSupport => 'Als Support schreiben';

  @override
  String get adminUnfreeze => 'Entsperren';

  @override
  String get adminFreeze => 'Einfrieren';

  @override
  String get adminUnfrozen => 'Entsperrt';

  @override
  String get adminFrozenDone => 'Eingefroren';

  @override
  String get adminResetPassword => 'Passwort zurücksetzen';

  @override
  String get adminCoinsAmountHint => 'Betrag (negativ = abziehen)';

  @override
  String get adminReasonOptional => 'Grund (optional)';

  @override
  String get adminGrantSent => 'Karte an den Support-Chat gesendet';

  @override
  String adminCoinsDebited(int amount) {
    return '$amount Bronze abgezogen';
  }

  @override
  String get adminGrantVerb => 'Gutschreiben';

  @override
  String get adminNewPasswordHint => 'Neues Passwort (min. 6)';

  @override
  String get adminPasswordReset => 'Passwort zurückgesetzt';

  @override
  String get adminResetVerb => 'Zurücksetzen';

  @override
  String adminShortError(String error) {
    return 'Fehler: $error';
  }

  @override
  String get adminSupportEmpty => 'Keine Support-Anfragen';

  @override
  String get adminUserFallback => 'Nutzer';

  @override
  String get apiErrTooManyRequests => 'Zu viele Anfragen. Versuche es später.';

  @override
  String get apiErrMoveConflict => 'Zugkonflikt. Bitte wiederholen.';

  @override
  String get shopElixirs => 'Elixiere';

  @override
  String get shopElixirsSubtitle => 'Sammlungen verjüngen, altern oder beschleunigen';

  @override
  String get shopElixirsHelp => 'Drei Regale: Verjüngung, Alterung und Beschleunigung. Auf jedem sechs Elixiere, eines pro Sammlungsset. Ein Elixier wirkt nur auf sein Set.\n\nVerjüngung macht die Sammlung einen Schritt neuer, nie neuer als neu. Alterung einen Schritt älter, nie älter als abgenutzt. Beschleunigung nur für Abgenutztes: noch 3 Monate bis Vintage, einmal. Vintage gibt es nicht durch ein Elixier.\n\nGekaufte Elixiere liegen bei den Gegenständen. Anwenden von der Sammlungskarte oder der Elixierkarte. Jede Anwendung verbraucht eines.';

  @override
  String get elixirGroupRejuvenate => 'Verjüngung';

  @override
  String get elixirGroupAge => 'Alterung';

  @override
  String get elixirGroupAccelerate => 'Beschleunigung';

  @override
  String get elixirEffectRejuvenate => 'Verjüngungs';

  @override
  String get elixirEffectAge => 'Alterungs';

  @override
  String get elixirEffectAccelerate => 'Beschleunigungs';

  @override
  String get elixirAdjCelebration => 'Festliches';

  @override
  String get elixirAdjNature => 'Natürliches';

  @override
  String get elixirAdjLegends => 'Legendäres';

  @override
  String get elixirAdjCosmic => 'Kosmisches';

  @override
  String get elixirAdjAdventure => 'Abenteuer';

  @override
  String get elixirAdjJewels => 'Edelstein';

  @override
  String elixirName(String adjective, String effect) {
    return '$adjective ${effect}elixier';
  }

  @override
  String get elixirHelpRejuvenate => 'Macht die Sammlung einen Schritt neuer. Nicht neuer als neu.';

  @override
  String get elixirHelpAge => 'Macht die Sammlung einen Schritt älter. Nicht älter als abgenutzt.';

  @override
  String get elixirHelpAccelerate => 'Nur für Abgenutztes. Noch 3 Monate bis Vintage, einmal.';

  @override
  String get elixirUseRejuvenate => 'Verjüngen';

  @override
  String get elixirUseAge => 'Altern';

  @override
  String get elixirUseAccelerate => 'Beschleunigen';

  @override
  String get elixirUse => 'Nutzen';

  @override
  String collectionLeftDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '$count Tag',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stunden',
      one: '$count Stunde',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Minuten',
      one: '$count Minute',
    );
    return '$_temp0';
  }

  @override
  String elixirSetOnly(String set) {
    return 'Nur das Set «$set».';
  }

  @override
  String get elixirPickCollection => 'Sammlung wählen';

  @override
  String get elixirNoTarget => 'Keine Sammlung dieses Sets kann dieses Elixier annehmen';

  @override
  String get elixirApplied => 'Elixier angewendet';

  @override
  String get elixirConfirmTitle => 'Elixier anwenden?';

  @override
  String elixirConfirmBody(String elixir, String collection) {
    return '$elixir\n$collection';
  }

  @override
  String get inventoryNoElixirs => 'Keine Elixiere — im Shop kaufen';

  @override
  String get elixirNotApplicable => 'Dieses Elixier wirkt jetzt nicht auf die Sammlung';

  @override
  String get elixirWrongSet => 'Elixier für ein anderes Set';

  @override
  String get elixirNotOwned => 'Dieses Elixier fehlt';

  @override
  String collectionUntil(String state, String left) {
    return 'Bis $state: $left';
  }

  @override
  String get collectionLeftSoon => 'weniger als eine Minute';

  @override
  String get collectionCondGenNew => 'new';

  @override
  String get collectionCondGenWorn => 'worn';

  @override
  String get collectionCondGenTired => 'tired';

  @override
  String get collectionCondGenShabby => 'shabby';

  @override
  String get collectionCondGenVintage => 'vintage';

  @override
  String get statsRecentTitle => 'Letzte Partien';

  @override
  String get statsOutcomeWin => 'Sieg';

  @override
  String get statsOutcomeLoss => 'Niederlage';

  @override
  String get statsOutcomeDraw => 'Remis';

  @override
  String get statsAllModes => 'Alle Modi';

  @override
  String statsDurakChip(int players, String deck) {
    return '$players · $deck';
  }

  @override
  String get statsSelectGame => 'Spiel';

  @override
  String get statsSelectMode => 'Modus';

  @override
  String get statsRecentEmpty => 'Noch keine Partien';
}
