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
  String get settingsSoundTitle => 'Geluid';

  @override
  String get settingsSoundSubtitle => 'Spellen en meldingen';

  @override
  String get settingsSoundGames => 'Spellen';

  @override
  String get settingsSoundNotifications => 'Meldingen';

  @override
  String get settingsSoundTurn => 'Beurt';

  @override
  String get settingsHapticsTitle => 'Trillen';

  @override
  String get settingsHapticsSubtitle => 'Alleen meldingen: berichten, verzoeken, jouw beurt en de timer';

  @override
  String get settingsGamepadTitle => 'Controller';

  @override
  String get settingsGamepadSubtitle => 'Gamepad voor menu\'s en partijen';

  @override
  String settingsGamepadConnected(String name) {
    return 'Verbonden: $name';
  }

  @override
  String get settingsGamepadDisconnected => 'Geen gamepad. Sluit een controller aan en druk op een knop.';

  @override
  String get settingsGamepadGenericName => 'Controller';

  @override
  String get settingsGamepadHelpNavigate => 'Navigeren';

  @override
  String get settingsGamepadHelpConfirm => 'Kiezen';

  @override
  String get settingsGamepadHelpBack => 'Terug';

  @override
  String get settingsGamepadHelpTabs => 'Tabbladen';

  @override
  String get settingsGamepadHelpPlay => 'Cursor op bord en hand: dammen, boter-kaas-eieren, zeeslag, durak, uno, poker en backgammon';

  @override
  String get settingsGamepadHelpCards => 'Kaarten';

  @override
  String get settingsGamepadHelpKeyboard => 'Toetsenbord';

  @override
  String get settingsGamepadHelpBalance => 'Saldo';

  @override
  String get settingsGamepadHelpLogout => 'Uitloggen';

  @override
  String get settingsGamepadHelpPage => 'Pagina';

  @override
  String get settingsGamepadLayoutXbox => 'Xbox-indeling';

  @override
  String get settingsGamepadLayoutPlayStation => 'PlayStation-indeling';

  @override
  String get settingsGamepadLayoutNintendo => 'Nintendo-indeling';

  @override
  String get gamepadKeyboardTitle => 'Toetsenbord';

  @override
  String get gamepadKeyboardSpace => 'Spatie';

  @override
  String get gamepadLegendConfirm => 'Kiezen';

  @override
  String get gamepadLegendBack => 'Terug';

  @override
  String get gamepadLegendTabs => 'Tabbladen';

  @override
  String get gamepadLegendCycle => 'Wijzigen';

  @override
  String gamepadConnectedSnack(String name) {
    return 'Controller verbonden: $name';
  }

  @override
  String get settingsOfflineModeTitle => 'Netwerkmodus';

  @override
  String get settingsOfflineModeSubtitle => 'Offline: speel meteen tegen een bot, zonder inzetten of beloningen, zonder chats of vrienden. Aankopen worden opgeslagen en toegepast in onlinemodus. Online — als er internet is of via de gebruikersinstelling.';

  @override
  String get settingsModeOnline => 'Online';

  @override
  String get settingsModeOffline => 'Offline';

  @override
  String get gamesAlternateStartsHint => 'Om de beurt wie de partij start';

  @override
  String get rulesAlternateStarts => 'Wie eerst zet wisselt van partij tot partij.';

  @override
  String get offlineBadgeTooltip => 'Offlinemodus';

  @override
  String get offlineModePopupTitle => 'Offlinemodus';

  @override
  String get offlineModePopupBody => 'Offlinemodus is aan. Speel tegen een bot zonder inzetten of beloningen. Chats, vrienden en lobby zijn verborgen. Aankopen worden in onlinemodus toegepast.';

  @override
  String get offlineModePopupSettings => 'Instellingen';

  @override
  String get offlineModeOfferBody => 'Geen internet of de verbinding is erg traag. Je kunt de offlinemodus aanzetten en tegen een bot spelen.';

  @override
  String get offlineModeOfferAction => 'Offline aanzetten';

  @override
  String get gamesPlay => 'Spelen';

  @override
  String get offlineGameTitle => 'Spel tegen bot';

  @override
  String get offlineGameHint => 'Zonder inzetten of beloningen · alleen offline';

  @override
  String get offlineBotWon => 'Bot heeft gewonnen';

  @override
  String get offlineBotThinking => 'Bot denkt na…';

  @override
  String get offlinePlayAgain => 'Opnieuw';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'Neem';

  @override
  String get durakActionAll => 'Alle';

  @override
  String get durakActionDone => 'Klaar';

  @override
  String get durakActionBito => 'Beat';

  @override
  String get durakHintDefend => 'Verdedig';

  @override
  String get durakHintDefendOrTransfer => 'Verdedig of schuif over';

  @override
  String get durakHintOpponentDefends => 'Tegenstander verdedigt';

  @override
  String get durakHintThrowInFirst => 'Kaarten bijleggen (max. 5 in eerste slag)';

  @override
  String get durakHintThrowIn => 'Kaarten bijleggen of wacht op verdediging';

  @override
  String get durakHintOpponentThrows => 'Tegenstander legt bij';

  @override
  String get durakHintTakeFollow => 'Leg bij na nemen of tik «Klaar»';

  @override
  String get durakHintOpponentTakeFollow => 'Tegenstander kan bijleggen na nemen';

  @override
  String get durakHintBito => 'Leg een kaart of zeg «Bito»';

  @override
  String get durakHintOpponentBito => 'Tegenstander legt bij of zegt «Bito»';

  @override
  String get durakHintYourAttack => 'Jouw beurt — val aan';

  @override
  String get durakHintOpponentAttack => 'Tegenstander valt aan';

  @override
  String get durakHintYouLost => 'Je verloor — je bent de dwaas';

  @override
  String get durakHintDrawAllOut => 'Gelijkspel — iedereen is uit';

  @override
  String get durakHintYouFinished => 'Je bent uit — wachten op het einde';

  @override
  String get durakFirstLeadYou => 'Jij komt uit';

  @override
  String get durakFirstLeadOpponent => 'Tegenstander komt uit';

  @override
  String get durakFirstLeadBot => 'Bot komt uit';

  @override
  String durakFirstLeadOf(String name) {
    return '$name komt uit';
  }

  @override
  String get durakFirstLeadReason => 'Laagste troef';

  @override
  String get shopPurchaseQueued => 'Aankoop opgeslagen — wordt toegepast in onlinemodus';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — aankoop toegepast';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — aankoop niet toegepast: $reason';
  }

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
  String settingsAppVersion(String version) {
    return 'Versie $version';
  }

  @override
  String get appUpdateTitle => 'Update beschikbaar';

  @override
  String get appUpdateBody => 'Er is een nieuwe versie van de app. Werk bij om door te gaan.';

  @override
  String get appUpdateWhatsNew => 'Wat is nieuw';

  @override
  String get appUpdateOk => 'Bijwerken';

  @override
  String get appUpdateLaterBanner => 'We werken de app bij na dit spel';

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
  String get apiErrWrongGameType => 'Verkeerd speltype';

  @override
  String get apiErrWrongGameTypeOrState => 'Verkeerd speltype of status';

  @override
  String get apiErrLobbyFull => 'Lobby is vol';

  @override
  String get apiErrBadState => 'Ongeldige spelstatus';

  @override
  String get apiErrIllegalMove => 'Ongeldige zet';

  @override
  String get apiErrUnknownMoveType => 'Onbekend zettype';

  @override
  String get apiErrNoOpponents => 'Geen tegenstanders';

  @override
  String get apiErrNoOpponentsRematch => 'Geen tegenstanders voor een rematch';

  @override
  String get apiErrAlreadyInLobby => 'Je zit al in deze lobby';

  @override
  String get apiErrGameNotActive => 'Het spel is niet actief';

  @override
  String get apiErrNotInBattle => 'Niet in de gevechtsfase';

  @override
  String get apiErrNotInSetup => 'Niet in de opstelfase';

  @override
  String get apiErrAlreadyReady => 'Je bent al klaar';

  @override
  String get apiErrAlreadyForfeited => 'Je hebt al opgegeven';

  @override
  String get apiErrYouHaveForfeited => 'Je hebt opgegeven';

  @override
  String get apiErrNoDrawOffer => 'Geen remise-aanbod';

  @override
  String get apiErrDrawOnlyPvp => 'Remise alleen tegen een speler';

  @override
  String get apiErrDrawOnly1v1 => 'Remise alleen in 1-tegen-1';

  @override
  String get apiErrDrawVsBot => 'Remise is niet beschikbaar tegen een bot';

  @override
  String get apiErrDrawMultiplayer => 'Remise is niet beschikbaar in multiplayer';

  @override
  String get apiErrDeck24TwoPlayers => 'Deck van 24 is alleen voor 2 spelers';

  @override
  String get apiErrDeck52ThreeOrFour => 'Deck van 52 is voor 3 of 4 spelers';

  @override
  String get apiErrAccountFrozen => 'Account is bevroren';

  @override
  String get apiErrTurnTimeInvalid => 'Zettijd moet 0, 20, 60 of 600 seconden zijn';

  @override
  String get timeJustNow => 'zojuist';

  @override
  String get timeYesterday => 'gisteren';

  @override
  String timeMinutesAgo(int count) {
    return '$count min geleden';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count u geleden';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count d geleden';
  }

  @override
  String get timeWeekAgo => 'een week geleden';

  @override
  String timeWeeksAgo(int count) {
    return '$count wkn geleden';
  }

  @override
  String get timeMonthAgo => 'een maand geleden';

  @override
  String timeMonthsAgo(int count) {
    return '$count mnd geleden';
  }

  @override
  String get timeYearAgo => 'een jaar geleden';

  @override
  String timeYearsAgo(int count) {
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
  String get gamesDurak => 'Durak';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => 'Draaien';

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
  String get gamesNardyModeShort => 'Kort';

  @override
  String get gamesNardyModeLong => 'Lang';

  @override
  String get gamesCheckers => 'Dammen';

  @override
  String get gamesCheckersModeRussian => 'Russisch';

  @override
  String get gamesCheckersModeEnglish => 'Engels';

  @override
  String get gamesCheckersModeGiveaway => 'Geefdam';

  @override
  String get gamesCheckersModeCorners => 'Hoeken';

  @override
  String get rulesCheckersPlayers => 'Spelers: 2.';

  @override
  String rulesCheckersMode(String mode) {
    return 'Modus: $mode.';
  }

  @override
  String rulesCheckersTime(String time) {
    return 'Время на ход: $time. Если время вышло — проигрыш.';
  }

  @override
  String get rulesCheckersIntro => 'Bord 8×8. Twee spelers.';

  @override
  String get rulesCheckersPlay => 'Slaan is verplicht. Dam en schijf moeten doorgaan zolang vanaf het landingsveld nog een slag kan — stoppen halverwege mag niet. Bij meerdere richtingen mag je elke kiezen, niet per se de langste. Een schijf op de laatste rij wordt dam.';

  @override
  String get rulesCheckersWin => 'В русских шашках побеждает тот, кто съел все шашки соперника или лишил его хода. В поддавках наоборот: кто не может ходить — выигрывает.';

  @override
  String get rulesCheckersOfflineBot => 'Офлайн: партия против бота.';

  @override
  String get rulesCheckersPlayRussian => 'Russisch dammen: ieder 12 schijven op donkere velden. Mannen lopen schuin vooruit en slaan voor- en achteruit. Dames vliegen willekeurig ver. Slaan is verplicht: doorgaan als het kan, maar bij meerdere richtingen mag je elke kiezen, niet per se de langste. Win door alle schijven te slaan of de tegenstander zonder zetten te laten.';

  @override
  String get rulesCheckersPlayEnglish => 'Engels dammen: ieder 12 schijven. Mannen lopen en slaan alleen schuin vooruit. Dames zetten één veld schuin. Slaan is verplicht. Win door alle schijven te slaan of de tegenstander zonder zetten te laten.';

  @override
  String get rulesCheckersPlayGiveaway => 'Geefdam: dezelfde zetten als Russisch dammen, maar het doel is omgekeerd — al je schijven kwijtraken of geen zet meer hebben. Slaan blijft verplicht.';

  @override
  String get rulesCheckersPlayCorners => 'Hoeken: de schijven starten in tegenoverliggende hoeken. Zet naar een leeg buurveld horizontaal of verticaal, of spring over een willekeurige schijf zonder die te slaan. Het doel is al je schijven naar de hoek van de tegenstander te brengen.';

  @override
  String get rulesCheckersPlayCornersNoReturn => 'Een schijf die zijn start-hoek heeft verlaten, mag daar niet naar terug.';

  @override
  String get rulesCheckersPlayCornersLeaveHome => 'Schijven die nog in huis staan, moeten het binnen de eerste 25 zetten van de speler verlaten.';

  @override
  String get rulesCheckersDrawRussian => 'Remise als dezelfde stelling driemaal voorkomt, of als 15 zetten per kant alleen dammen zonder slaan zijn — ook twee dammen tegen twee.';

  @override
  String get rulesCheckersDrawEnglish => 'Remise bij drievoudige herhaling, 40 zetten zonder slaan of schijfzet, of één dam tegen één dam.';

  @override
  String get rulesCheckersDrawGiveaway => 'Remise bij drievoudige herhaling of 15 damzetten zonder slaan.';

  @override
  String get rulesCheckersDrawCorners => 'Remise bij drievoudige herhaling of 25 zetten per kant zonder extra schijf in de doelhoek.';

  @override
  String get checkersDrawRepetition => 'Remise — stelling driemaal herhaald';

  @override
  String get checkersDrawNoProgress => 'Remise — zetten leiden niet tot winst';

  @override
  String get checkersDrawInsufficient => 'Remise — onvoldoende materiaal voor winst';

  @override
  String get rulesNardyTitle => 'Backgammon — regels';

  @override
  String get rulesNardyPlayers => 'Spelers: 2.';

  @override
  String rulesNardyMode(String mode) {
    return 'Modus: $mode.';
  }

  @override
  String get rulesNardyIntro => 'Bord met 24 punten, ieder 15 schijven. Twee dobbelstenen: één schijf de som of twee schijven de ogen.';

  @override
  String get rulesNardyPlayShort => 'Kort backgammon: jullie trekken naar elkaar toe en mogen enkele schijven slaan. Een geslagen schijf gaat naar de bar en moet opnieuw binnenkomen. Als alle schijven thuis zijn, sla je ze af.';

  @override
  String get rulesNardyPlayLong => 'Lang backgammon: beiden starten vanaf dezelfde kop en gaan dezelfde kant op. Per beurt mag maar één schijf de kop verlaten. Slaan mag niet. Als alle schijven thuis zijn, sla je ze af.';

  @override
  String get rulesNardyWin => 'Wie als eerste alle schijven afspeelt, wint.';

  @override
  String get rulesNardySixPrime => 'Je mag pas zes punten op rij sluiten als minstens één schijf van de tegenstander erlangs is.';

  @override
  String get nardyRoll => 'Gooien';

  @override
  String get nardySkipTurn => 'Beurt overslaan';

  @override
  String get nardyUndoMove => 'Ongedaan';

  @override
  String get nardyDoneTurn => 'Klaar';

  @override
  String get nardyAutoConfirm => 'Auto-bevestigen';

  @override
  String get nardyAutoConfirmHint => 'Geef de beurt automatisch door na alle zetten';

  @override
  String get nardyLayoutToggle => 'Opstelling wisselen';

  @override
  String get nardyNoMoves => 'Geen zetten';

  @override
  String get nardyYourRoll => 'Jouw worp';

  @override
  String get nardyPipsShort => 'Resterend:';

  @override
  String get nardyYouWonMars => 'Gewonnen — gammon!';

  @override
  String get nardyYouLostMars => 'Verloren — gammon';

  @override
  String get rulesNardyOfflineBot => 'Offline: partij tegen de bot.';

  @override
  String rulesUnoPlayers(int players) {
    return 'Spelers: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'Spel tegen een bot, zonder tijdslimiet per beurt.';

  @override
  String get rulesUnoIntro => 'Iedereen krijgt 7 kaarten. Speel een kaart van dezelfde kleur of dezelfde rang (cijfer of dezelfde actie).';

  @override
  String get rulesUnoPlay => 'Overslaan — de volgende mist een beurt. Omkeren met twee spelers werkt als Overslaan. +2 stapelt alleen op +2 en +4 alleen op +4: de straf telt op (twee +2 betekent 4 trekken). +2 mag niet op +4. Wie niet stapelt trekt de hele stapel en slaat over. Twee dezelfde niet-zwarte kaarten (bijv. twee gele 8) gaan samen weg: speel er één en de tweeling gaat automatisch mee.';

  @override
  String get rulesUnoWild => 'Een zwarte kaart kiest een nieuwe kleur. Speel +4 alleen zonder kaart van de huidige kleur. De volgende mag challengen: was +4 legaal, trekt hij 6; zo niet, trekt de +4-speler 4 en de challenger speelt.';

  @override
  String get rulesUnoDraw => 'Zonder legale kaart trek je er één van de stapel. Past die, speel hem nu of houd hem en pas. Trekken mag niet zolang je kunt spelen.';

  @override
  String get rulesUnoWin => 'Met z’n tweeën tot 100, bij 3+ spelers tot 200. Een ronde wint wie de hand leegt.';

  @override
  String get rulesUnoCall => 'Bij één kaart tik je meteen op “Uno!”. Tegenstanders mogen je pas na één seconde pakken voor vergeten Uno — dan trek je 2 kaarten.';

  @override
  String get rulesUnoScoring => 'Wie als eerste leeg is wint de ronde en scoort de kaarten van tegenstanders: cijfers op waarde, acties 20, zwart 50. Met z’n tweeën tot 100, bij 3+ spelers tot 200.';

  @override
  String get unoColorRed => 'Rood';

  @override
  String get unoColorYellow => 'Geel';

  @override
  String get unoColorGreen => 'Groen';

  @override
  String get unoColorBlue => 'Blauw';

  @override
  String get unoDraw => 'Trekken';

  @override
  String get unoKeep => 'Houden';

  @override
  String get unoSayUno => 'Uno!';

  @override
  String get unoChallengeUno => 'Uno uitdagen';

  @override
  String get unoChallengeWd4 => '+4 uitdagen';

  @override
  String get unoChooseColor => 'Kies een kleur';

  @override
  String get unoDrawPile => 'Trekstapel';

  @override
  String get unoDiscardPile => 'Aflegstapel';

  @override
  String unoCardsCount(int count) {
    return 'Kaarten: $count';
  }

  @override
  String unoScore(int score) {
    return 'Score: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'Ronde $round · tot $target';
  }

  @override
  String get unoYourTurn => 'Jouw beurt';

  @override
  String get unoWaitingTurn => 'Beurt van tegenstander';

  @override
  String get unoChooseColorHint => 'Kies een kleur voor de joker';

  @override
  String get unoWd4Hint => 'Trek 4 kaarten of daag Wild +4 uit';

  @override
  String get unoDrawnHint => 'Speel de getrokken kaart of houd hem';

  @override
  String get unoPlayHint => 'Speel dezelfde kleur of waarde';

  @override
  String get unoDrawHint => 'Geen passende kaart — trek van de stapel';

  @override
  String unoPendingDraw(int count) {
    return '+$count kaarten';
  }

  @override
  String get unoYouWon => 'Je hebt de wedstrijd gewonnen!';

  @override
  String get unoYouLost => 'Wedstrijd afgelopen';

  @override
  String get unoYouLostTimeout => 'U hebt op tijd verloren';

  @override
  String unoWinner(String name) {
    return 'Winnaar: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name wint de ronde';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'Verder';

  @override
  String get unoRoundScoresTitle => 'Rondepunten';

  @override
  String get unoDirectionClockwise => 'Met de klok mee';

  @override
  String get unoDirectionCounterclockwise => 'Tegen de klok in';

  @override
  String get unoErrStackSameOnly => 'Op +2 mag alleen +2, op +4 alleen +4. +2 op +4 is niet toegestaan.';

  @override
  String get unoErrCatchTooEarly => 'Wacht even — ze kunnen nog Uno zeggen.';

  @override
  String get unoErrCallTooLate => 'U kunt geen Uno meer zeggen. De volgende speler heeft al gespeeld.';

  @override
  String get gamesInDevelopment => 'In ontwikkeling';

  @override
  String rulesPokerPlayers(int players) {
    return 'Spelers: $players.';
  }

  @override
  String get rulesPokerIntro => 'Texas Hold’em. Iedereen krijgt 2 hole cards; er komen 5 community cards op tafel.';

  @override
  String get rulesPokerPlay => 'Inzetrondes: preflop, flop, turn en river. Fold, call, bet of raise.';

  @override
  String get rulesPokerWin => 'De beste vijfkaartshand (hole + community) wint, of de laatste speler na folds.';

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
  String get pokerCombinationsTitle => 'Combinaties';

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
  String get gamesObservation => 'Toeschouwen';

  @override
  String get gamesObservationHint => 'Je kunt kijken tot het spel eindigt';

  @override
  String get gamesFinishCurrentFirst => 'Voltooi eerst je huidige spel';

  @override
  String get gamesVariantClassic => 'Klassiek';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 spelers';

  @override
  String get gamesVariantMulti4 => '4 spelers';

  @override
  String get gamesDurakModePodkidnoi => 'Bijleggen';

  @override
  String get gamesDurakModePerevodnoi => 'Doorschuiven';

  @override
  String get gamesDurakDeck24 => '24 kaarten';

  @override
  String get gamesDurakDeck36 => '36 kaarten';

  @override
  String get gamesDurakDeck52 => '52 kaarten';

  @override
  String rulesDurakMode(String mode) {
    return 'Modus: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'Spelers: $players. Deck: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Speel tegen een bot, zonder inzet of tijdslimiet.';

  @override
  String get rulesDurakAttack => 'De aanvaller speelt kaarten; de verdediger slaat ze (zelfde kleur hoger, of een troef). Een troef wordt alleen geslagen door een hogere troef.';

  @override
  String get rulesDurakBeat => 'Als alle kaarten geslagen zijn, zegt de aanvaller «Bito» en gaan ze naar de aflegstapel. Anders neemt de verdediger alles van tafel.';

  @override
  String get rulesDurakLoser => 'Verliezer is wie aan het eind nog kaarten heeft — de «dwaas».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Spelers $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Lobby $name';
  }

  @override
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Privéspel';

  @override
  String get lobbySearchingOpponent => 'Tegenstander zoeken…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Zoeken dit spel: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Wachten tot iemand op «Spel zoeken» of «Meedoen» tikt';

  @override
  String get lobbyInviteTitle => 'Speluitnodiging';

  @override
  String get lobbyInvitedToPlay => 'Je bent uitgenodigd om te spelen';

  @override
  String get lobbyEnterGame => 'Spel betreden';

  @override
  String get lobbyGone => 'Lobby niet meer beschikbaar';

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
  String get gameYouLost => 'Je hebt verloren';

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
  String get gameSurrender => 'Opgeven';

  @override
  String get gameSurrenderTitle => 'Opgeven?';

  @override
  String get gameSurrenderConfirm => 'Je verliest de partij en de inzetmunten.';

  @override
  String get gameOfferDraw => 'Remise aanbieden';

  @override
  String get gameOfferDrawTitle => 'Remise aanbieden?';

  @override
  String get gameOfferDrawConfirm => 'Je tegenstander kan de remise accepteren of weigeren.';

  @override
  String get gameAcceptDrawTitle => 'Remise accepteren?';

  @override
  String get gameAcceptDrawConfirm => 'De partij eindigt in remise.';

  @override
  String get gameDrawOffered => 'Tegenstander biedt remise aan';

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
  String get chatPaste => 'Plakken';

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
  String get friendsSearchNoMatches => 'Geen vrienden die aan de zoekopdracht voldoen';

  @override
  String get friendsIncomingSearchNoMatches => 'Geen inkomende verzoeken voor deze zoekopdracht';

  @override
  String get friendsOutgoingSearchNoMatches => 'Geen uitgaande verzoeken voor deze zoekopdracht';

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
  String get profileChangePhoto => 'Avatar wijzigen';

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
  String get shopStakesSubtitle => 'Hogere inzetten ontgrendelen';

  @override
  String get shopEmojisHelp => 'Geanimeerde emoji’s voor de chat. Koop een set en stuur ze naar vrienden.';

  @override
  String get shopCollectionsHelp => 'Verzamel een set items: ze verschijnen in je profielvitrine en kun je cadeau doen of verkopen. Een complete collectie levert elke dag extra munten op.';

  @override
  String get shopStakesHelp => 'Ontgrendel hogere inzetten. Hoe hoger de inzet, hoe groter de pot en de winst.';

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

  @override
  String get balanceTitle => 'Saldo';

  @override
  String get coinBronze => 'Brons';

  @override
  String get coinSilver => 'Zilver';

  @override
  String get coinGold => 'Goud';

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
    return '$count zilver';
  }

  @override
  String balanceGolds(int count) {
    return '$count goud';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count diamanten';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/dag';
  }

  @override
  String get balanceAbbrBronze => 'br';

  @override
  String get balanceAbbrSilver => 'z.';

  @override
  String get balanceAbbrGold => 'g.';

  @override
  String get commonBackHome => 'Terug naar home';

  @override
  String get commonCopied => 'Gekopieerd';

  @override
  String get commonClear => 'Wissen';

  @override
  String get commonTryLater => 'Probeer het later opnieuw.';

  @override
  String get commonTryRefresh => 'Probeer de pagina te vernieuwen.';

  @override
  String get coinsTitle => 'Munten';

  @override
  String get coinsLoginReward => 'Inlogbeloning';

  @override
  String get coinsLoginAvailableToday => 'Beloning van vandaag beschikbaar';

  @override
  String get coinsLoginStreak => 'Dagelijkse inlogreeks';

  @override
  String get coinsFriendReward => 'Vriendenbeloning';

  @override
  String get coinsTasks => 'Taken';

  @override
  String get coinsTasksSubtitle => 'Beloningen voor profiel, vrienden en games';

  @override
  String get coinsTasksRewards => 'Beloningen klaar om te claimen';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount voor registratie via jouw link';
  }

  @override
  String get coinsLoadRewardsFailed => 'Beloningen konden niet worden geladen';

  @override
  String get coinsClaimReward => 'Beloning ophalen';

  @override
  String get coinsAlreadyClaimed => 'Al opgehaald';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · vandaag';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · nog 1 dag';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · nog $remaining';
  }

  @override
  String get coinsInviteFriend => 'Nodig een vriend uit';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount voor iedereen die zich via jouw link registreert';
  }

  @override
  String get coinsCopyLink => 'Link kopiëren';

  @override
  String get coinsHowItWorks => 'Hoe het werkt';

  @override
  String get coinsHowStep1 => 'Kopieer de link en stuur die naar een vriend';

  @override
  String get coinsHowStep2 => 'Je vriend registreert zich via die link';

  @override
  String coinsHowStep3(String amount) {
    return 'Je ontvangt $amount';
  }

  @override
  String get achievementsTitle => 'Prestaties';

  @override
  String achievementsProgress(String progress) {
    return 'Voortgang: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Kader ontvangen';

  @override
  String get achievementsClaimed => 'Ontvangen';

  @override
  String get achievementsOpenFrame => 'Kader openen';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Weet je zeker dat je $name uit vrienden wilt verwijderen?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Verwijderen';

  @override
  String get friendsRemove => 'Uit vrienden verwijderen';

  @override
  String get friendsAcceptRequest => 'Verzoek accepteren';

  @override
  String get friendsDeclineRequest => 'Verzoek weigeren';

  @override
  String get friendsCancelRequest => 'Verzoek annuleren';

  @override
  String get friendsSendRequest => 'Vriendschapsverzoek sturen';

  @override
  String get friendsRequestAlreadySent => 'Verzoek al verzonden';

  @override
  String get friendsIncomingStatus => 'Inkomend verzoek';

  @override
  String get friendsOutgoingStatus => 'Uitgaand verzoek';

  @override
  String get friendsNotFriends => 'Geen vrienden';

  @override
  String get friendsCollapseSearch => 'Zoeken inklappen';

  @override
  String get friendsExpandSearch => 'Zoeken tonen';

  @override
  String get friendsLoadFailed => 'Vrienden konden niet worden geladen';

  @override
  String friendsSince(String date) {
    return 'Vrienden sinds: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Inkomend verzoek: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Uitgaand verzoek: $date';
  }

  @override
  String get userInfoTitle => 'Gebruikersinfo';

  @override
  String profileAgeYears(int age) {
    return '$age jaar';
  }

  @override
  String get shopBuy => 'Kopen';

  @override
  String get shopBuyTitle => 'Kopen?';

  @override
  String get shopBuyStakeTitle => 'Inzet kopen?';

  @override
  String get shopBuyEmojiTitle => 'Emoji kopen?';

  @override
  String get shopBuyCollectionTitle => 'Collectie kopen?';

  @override
  String shopPrice(String price) {
    return 'Prijs: $price';
  }

  @override
  String get shopOwned => 'Gekocht';

  @override
  String get shopHave => 'In bezit';

  @override
  String get shopEmpty => 'Nog leeg';

  @override
  String shopPurchased(String title) {
    return '$title gekocht';
  }

  @override
  String get shopEmojiUses => 'Je krijgt: 10 gebruiken';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 gebruiken';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 gebruiken';
  }

  @override
  String get shopBuyTen => 'Kopen · 10 st.';

  @override
  String shopDailyIncome(String amount) {
    return 'Inkomen: $amount';
  }

  @override
  String get shopBuyOnce => 'Eenmalige aankoop';

  @override
  String get shopSellRefund => 'Verkopen geeft 80% van de prijs terug';

  @override
  String shopCollectionAdded(String title) {
    return '$title toegevoegd aan profiel';
  }

  @override
  String shopSetBonus(int percent) {
    return 'setbonus +$percent%';
  }

  @override
  String get shopSetComplete => 'Compleet';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Verzameld · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Verkopen?';

  @override
  String inventorySellDesc(String amount) {
    return 'Je ontvangt $amount';
  }

  @override
  String inventorySold(String amount) {
    return 'Verkocht: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Voeg eerst vrienden toe';

  @override
  String get inventoryGiftTitle => 'Collectie cadeau doen?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return '“$title” cadeau doen aan $name?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Cadeau gegeven: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'De speler heeft dit item al';

  @override
  String get inventoryGiftSelf => 'Je kunt jezelf niets cadeau doen';

  @override
  String get inventoryGiftNotOwned => 'Dit item zit niet in je inventaris';

  @override
  String get inventoryLoadFailed => 'Items konden niet worden geladen';

  @override
  String get inventoryNoCollections => 'Geen collecties — koop ze in de winkel';

  @override
  String get inventoryNoEmojis => 'Geen emoji’s — koop ze in de winkel';

  @override
  String get inventoryNoFrames => 'Geen kaders — win 10 competitiewedstrijden (prestaties)';

  @override
  String get inventoryNoStakes => 'Geen gekochte inzetten';

  @override
  String inventoryEmojiLeft(int count) {
    return 'Nog $count over';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Inkomen: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Inkomen morgen: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Klaar';

  @override
  String get inventoryIncomeTomorrowLabel => 'Morgen';

  @override
  String inventoryStakeGold(String amount) {
    return 'Je kunt $amount goud inzetten';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'Je kunt $amount zilver inzetten';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'Ontvangen +$amount';
  }

  @override
  String get chatsLoadFailed => 'Chats konden niet worden geladen';

  @override
  String get chatsLoadListFailed => 'Lijst kon niet worden geladen';

  @override
  String get chatsBlockedEmpty => 'Lijst is leeg';

  @override
  String chatsBlockedAt(String date) {
    return 'Geblokkeerd: $date';
  }

  @override
  String get chatsCreateFailed => 'Chat kon niet worden gemaakt';

  @override
  String get chatsNeedFriendsFirst => 'Voeg eerst vrienden toe, dan kun je een chat openen.';

  @override
  String get chatsFriendsNotFound => 'Geen vrienden gevonden';

  @override
  String get chatsFindFriendHint => 'Zoek een vriend op bijnaam';

  @override
  String get chatsSelectChat => 'Selecteer een chat';

  @override
  String get chatsSelectHint => 'Kies een gesprek uit de lijst links';

  @override
  String get chatEditFailed => 'Bericht kon niet worden bewerkt';

  @override
  String get chatSendFailed => 'Bericht kon niet worden verzonden';

  @override
  String get chatDeleteFailed => 'Bericht kon niet worden verwijderd';

  @override
  String get chatEmojiSendFailed => 'Emoji kon niet worden verzonden';

  @override
  String get chatLoadFailed => 'Berichten konden niet worden geladen';

  @override
  String get chatBackToGame => 'Terug naar het spel';

  @override
  String get chatBackToChats => 'Terug naar chats';

  @override
  String get chatActions => 'Chatacties';

  @override
  String get chatAutoTranslate => 'Auto-vertaling';

  @override
  String get chatScrollToEnd => 'Naar het einde';

  @override
  String chatReplyingTo(String name) {
    return 'Antwoord aan $name';
  }

  @override
  String get chatGift => 'Cadeau';

  @override
  String get chatCollection => 'Collectie';

  @override
  String get chatGiftCollection => 'Cadeau · collectie';

  @override
  String get chatThisUser => 'deze gebruiker';

  @override
  String get gamesLobbyLoadFailed => 'Lobby kon niet worden geladen.';

  @override
  String get gamesTapChangeStake => 'Tik om de inzet te wijzigen';

  @override
  String get gamesTapChangeTurnTime => 'Tik om de bedenktijd te wijzigen';

  @override
  String get gamesTapChangeGrid => 'Tik om de rastergrootte te wijzigen';

  @override
  String get gamesSwapSidesHint => 'O kan na de 1e zet X worden';

  @override
  String get gamesNoCenterHint => 'Eerste zet mag niet in het midden';

  @override
  String get lobbyInviteSentShort => 'Verzonden';

  @override
  String get lobbySearchShort => 'Zoeken';

  @override
  String get lobbySearchPlayers => 'Spelers zoeken';

  @override
  String get lobbyInviteDeclinedShort => 'Geweigerd';

  @override
  String get lobbyInvitesSentWaiting => 'Uitnodigingen verzonden. Wachten op antwoord.';

  @override
  String get lobbyLinkCopiedHint => 'Plak hem in een chat of bericht naar een vriend';

  @override
  String get lobbyCopyLinkHint => 'Link naar klembord kopiëren';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name nodigt je uit om te spelen';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name heeft gewonnen';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Tijd is om. $name heeft gewonnen';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String get adminTitle => 'Beheer';

  @override
  String get tournamentsTitle => 'Toernooien';

  @override
  String get profileAgeInvalid => 'Voer een leeftijd van 1 tot 111 in';

  @override
  String get profileSaveFailed => 'Profiel kon niet worden opgeslagen';

  @override
  String get profileNameHint => 'Latijnse letters, cijfers, _ tot 10 tekens';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'Van 1 tot 111';

  @override
  String get profileAboutHint => 'Tot 100 tekens (optioneel)';

  @override
  String get profileProcessingPhoto => 'Foto verwerken…';

  @override
  String get profileCropTitle => 'Kies avatargebied';

  @override
  String get profileCropHint => 'Zoom en verplaats de foto';

  @override
  String get profileApply => 'Toepassen';

  @override
  String get profilePreparing => 'Voorbereiden…';

  @override
  String get profileGalleryTitle => 'Foto’s';

  @override
  String get profileGalleryAdd => 'Foto toevoegen';

  @override
  String get profileMakePrimary => 'Als profielfoto';

  @override
  String get profilePhotoDelete => 'Foto verwijderen';

  @override
  String get profilePhotosLimit => 'Je kunt tot 3 foto’s uploaden';

  @override
  String get profilePhotosEmpty => 'Nog geen foto’s';

  @override
  String get profilePhotoUploadFailed => 'Foto uploaden mislukt';

  @override
  String get profilePhotoDeleteFailed => 'Foto verwijderen mislukt';

  @override
  String get profilePhotoTooLarge => 'Foto is te groot';

  @override
  String get profileSetPrimaryFailed => 'Instellen als profielfoto mislukt';

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
    return 'Boter-kaas-eieren op een $grid-bord. Om de beurt; X begint.';
  }

  @override
  String rulesWin(int n) {
    return 'Winst: zet $n op een rij horizontaal, verticaal of diagonaal.';
  }

  @override
  String get rulesNoTimeLimit => 'Geen tijdslimiet per beurt.';

  @override
  String rulesTurnTime(String time) {
    return 'Tijd per beurt: $time. Tijd overschrijden is verlies.';
  }

  @override
  String rulesStake(String stake) {
    return 'Inzet: $stake. Het spel gaat om zoveel munten.';
  }

  @override
  String get rulesSwap => 'Kant wisselen: O mag met X wisselen na de eerste zet van X.';

  @override
  String get rulesNoCenter => 'Geen midden: X mag niet in het midden beginnen.';

  @override
  String get collectionSetLegends => 'Legendes';

  @override
  String get collectionSetSpace => 'Ruimte';

  @override
  String get collectionSetGems => 'Edelstenen';

  @override
  String get collectionSetParty => 'Feest';

  @override
  String get collectionSetNature => 'Natuur';

  @override
  String get collectionSetAdventures => 'Avonturen';

  @override
  String collectionCardMeta(String amount) {
    return 'Collectie · etalage · cadeau · verkoop · +$amount';
  }

  @override
  String get coinsDayOne => 'dag';

  @override
  String get coinsDayFew => 'dagen';

  @override
  String get coinsDayMany => 'dagen';

  @override
  String get giftFriendTitle => 'Cadeau aan een vriend';

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
    return '$count emoji\'s · $price';
  }

  @override
  String get chatsExpandPanel => 'Paneel uitklappen';

  @override
  String get chatsCollapsePanel => 'Paneel inklappen';

  @override
  String get chatReplySourceMissing => 'Oorspronkelijk bericht niet gevonden';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Inzet $n zilver';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Inzet $n goud';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Ontgrendel inzet van $n zilver';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Ontgrendel inzet van $n goud';
  }

  @override
  String get chatReplySelf => 'jezelf';

  @override
  String get chatReplyPeer => 'de gesprekspartner';

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
  String get statsTitle => 'Statistieken';

  @override
  String get statsLoadFailed => 'Statistieken laden mislukt';

  @override
  String get statsAllGames => 'Alle spellen';

  @override
  String get statsEmptyTitle => 'Nog geen wedstrijden gespeeld';

  @override
  String get statsEmptyHint => 'Speel je eerste wedstrijd om hier statistieken te zien.';

  @override
  String get statsWins => 'Overwinningen';

  @override
  String get statsDraws => 'Gelijkspel';

  @override
  String get statsLosses => 'Nederlagen';

  @override
  String get statsWinRate => 'Winstpercentage';

  @override
  String get statsTopWon => 'Meeste overwinningen tegen';

  @override
  String get statsTopDrawn => 'Meeste gelijkspelen met';

  @override
  String get statsTopLost => 'Meeste nederlagen tegen';

  @override
  String get statsTimePlayed => 'Speeltijd';

  @override
  String get statsYourScore => 'Jouw stand';

  @override
  String get profileShowStats => 'Statistieken tonen';

  @override
  String get statsDurationZeroMinutes => '0 min';

  @override
  String get gameYouWonOpponentForfeit => 'Tegenstander gaf op. Je hebt gewonnen!';

  @override
  String get lobbyLeaveTitle => 'Lobby verlaten?';

  @override
  String get lobbyLeaveConfirm => 'De lobby wordt verwijderd nadat je weggaat. Uitgenodigde vrienden krijgen een afwijzing.';

  @override
  String get lobbyLeave => 'Verlaten';

  @override
  String statsDurationHours(int hours) {
    return '$hours u';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours u $minutes min';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'Je gaf op. $name won';
  }

  @override
  String get supportTitle => 'Support';

  @override
  String get supportUnavailable => 'Support is niet beschikbaar';

  @override
  String get supportOpenFailed => 'Supportchat kon niet worden geopend';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Je hebt $amount munten ontvangen';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return '$amount munten zijn afgetrokken';
  }

  @override
  String get coinsCreditCardTitle => 'Je hebt munten ontvangen';

  @override
  String get coinsClaim => 'Ophalen';

  @override
  String get durakActionPass => 'Passen';

  @override
  String get durakRoleTook => 'Neemt';

  @override
  String get durakRoleBeats => 'Slaat';

  @override
  String get durakRoleThrowIn => 'Bijleggen';

  @override
  String get durakRoleTurn => 'Beurt';

  @override
  String get durakRoleDefends => 'Verdedigt';

  @override
  String get durakStatusTaking => 'Neemt';

  @override
  String get durakHintDefenderTurn => 'Beurt van de verdediger';

  @override
  String get gameYouEliminated => 'Je bent eruit';

  @override
  String gameYouPlaced(int place) {
    return 'Je werd ${place}e';
  }

  @override
  String get gameOverNeutral => 'Spel afgelopen';

  @override
  String gameTurnOf(String name) {
    return 'Beurt van $name';
  }

  @override
  String get chatGroupTooltip => 'Groepschat';

  @override
  String get lobbyChatNotReady => 'Lobbychat is nog niet klaar';

  @override
  String get chatsGroupChat => 'Groepschat';

  @override
  String chatsMembersCount(int count) {
    return 'Leden: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count pers.';
  }

  @override
  String get chatsYouSuffix => '(jij)';

  @override
  String get chatTitleDurak3 => 'Durak · 3 spelers';

  @override
  String get chatTitleDurak4 => 'Durak · 4 spelers';

  @override
  String get rulesTttUltimate => 'Ultimate: negen 3×3-miniborden. Een zet stuurt de tegenstander naar dat minibord. Win met een lijn op het metabord.';

  @override
  String get rulesTttMulti3 => '3 spelers: 3×3-bord, drie spelers (X, O, △). Maak een lijn met je eigen tekens om te winnen.';

  @override
  String get rulesTttMulti4 => '4 spelers: 4×4-bord, vier spelers (X, O, △, □). Maak een lijn met je eigen tekens om te winnen.';

  @override
  String get adminUsersTab => 'Gebruikers';

  @override
  String get adminSupportTab => 'Support';

  @override
  String get adminSearchHint => 'Zoek op e-mail of naam';

  @override
  String get adminRoleAdmins => 'Admins';

  @override
  String get adminRoleUsers => 'Gebruikers';

  @override
  String get adminRoleAll => 'Alle rollen';

  @override
  String get adminStatusFrozen => 'Bevroren';

  @override
  String get adminStatusActive => 'Actief';

  @override
  String get adminStatusAny => 'Elke status';

  @override
  String get adminOrderDesc => 'Aflopend';

  @override
  String get adminOrderAsc => 'Oplopend';

  @override
  String adminLoadFailed(String error) {
    return 'Laden mislukt: $error';
  }

  @override
  String get adminUsersEmpty => 'Geen gebruikers';

  @override
  String get adminSortLastSeen => 'Op laatste bezoek';

  @override
  String get adminSortEmail => 'Op e-mail';

  @override
  String get adminSortCreated => 'Op registratiedatum';

  @override
  String adminBronzeBalance(int amount) {
    return '$amount br.';
  }

  @override
  String get adminRevokeAdmin => 'Admin intrekken';

  @override
  String get adminGrantAdmin => 'Admin maken';

  @override
  String get adminAdminRevoked => 'Adminrechten ingetrokken';

  @override
  String get adminAdminGranted => 'Adminrechten gegeven';

  @override
  String get adminGrantCoins => 'Munten toekennen';

  @override
  String get adminWriteSupport => 'Schrijven als support';

  @override
  String get adminUnfreeze => 'Ontdooien';

  @override
  String get adminFreeze => 'Bevriezen';

  @override
  String get adminUnfrozen => 'Ontdooid';

  @override
  String get adminFrozenDone => 'Bevroren';

  @override
  String get adminResetPassword => 'Wachtwoord resetten';

  @override
  String get adminCoinsAmountHint => 'Aantal (negatief = afschrijven)';

  @override
  String get adminReasonOptional => 'Reden (optioneel)';

  @override
  String get adminGrantSent => 'Kaart naar supportchat gestuurd';

  @override
  String adminCoinsDebited(int amount) {
    return '$amount brons afgeschreven';
  }

  @override
  String get adminGrantVerb => 'Toekennen';

  @override
  String get adminNewPasswordHint => 'Nieuw wachtwoord (min. 6)';

  @override
  String get adminPasswordReset => 'Wachtwoord gereset';

  @override
  String get adminResetVerb => 'Resetten';

  @override
  String adminShortError(String error) {
    return 'Fout: $error';
  }

  @override
  String get adminSupportEmpty => 'Geen supportverzoeken';

  @override
  String get adminUserFallback => 'Gebruiker';

  @override
  String get apiErrTooManyRequests => 'Te veel verzoeken. Probeer later opnieuw.';

  @override
  String get apiErrMoveConflict => 'Zetconflict. Probeer opnieuw.';
}
