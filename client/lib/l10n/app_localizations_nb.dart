import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Hjem';

  @override
  String get navProfile => 'Profil';

  @override
  String get navFriends => 'Venner';

  @override
  String get navChats => 'Chatter';

  @override
  String get navGames => 'Spill';

  @override
  String get navSettings => 'Innstillinger';

  @override
  String get settingsTitle => 'Innstillinger';

  @override
  String get settingsLanguage => 'Språk';

  @override
  String get settingsLanguageSystem => 'Systemstandard';

  @override
  String get settingsSoundTitle => 'Lyd';

  @override
  String get settingsSoundSubtitle => 'Spill og varsler';

  @override
  String get settingsSoundGames => 'Spill';

  @override
  String get settingsSoundNotifications => 'Varsler';

  @override
  String get settingsSoundTurn => 'Tur';

  @override
  String get settingsHapticsTitle => 'Vibrasjon';

  @override
  String get settingsHapticsSubtitle => 'Kun varsler: meldinger, forespørsler, din tur og timeren';

  @override
  String get settingsGamepadTitle => 'Kontroller';

  @override
  String get settingsGamepadSubtitle => 'Gamepad for menyer og partier';

  @override
  String settingsGamepadConnected(String name) {
    return 'Tilkoblet: $name';
  }

  @override
  String get settingsGamepadDisconnected => 'Ingen gamepad. Koble til en kontroller og trykk på en knapp.';

  @override
  String get settingsGamepadGenericName => 'Kontroller';

  @override
  String get settingsGamepadHelpNavigate => 'Navigasjon';

  @override
  String get settingsGamepadHelpConfirm => 'Velg';

  @override
  String get settingsGamepadHelpBack => 'Tilbake';

  @override
  String get settingsGamepadHelpTabs => 'Faner';

  @override
  String get settingsGamepadHelpPlay => 'Markør på brett og hånd: dam, tre på rad, senk skipene, durak, uno, poker og backgammon';

  @override
  String get settingsGamepadHelpCards => 'Kort';

  @override
  String get settingsGamepadHelpKeyboard => 'Tastatur';

  @override
  String get settingsGamepadHelpBalance => 'Saldo';

  @override
  String get settingsGamepadHelpLogout => 'Logg ut';

  @override
  String get settingsGamepadHelpPage => 'Side';

  @override
  String get settingsGamepadLayoutXbox => 'Xbox-oppsett';

  @override
  String get settingsGamepadLayoutPlayStation => 'PlayStation-oppsett';

  @override
  String get settingsGamepadLayoutNintendo => 'Nintendo-oppsett';

  @override
  String get gamepadKeyboardTitle => 'Tastatur';

  @override
  String get gamepadKeyboardSpace => 'Mellomrom';

  @override
  String get gamepadLegendConfirm => 'Velg';

  @override
  String get gamepadLegendBack => 'Tilbake';

  @override
  String get gamepadLegendTabs => 'Faner';

  @override
  String get gamepadLegendCycle => 'Endre';

  @override
  String gamepadConnectedSnack(String name) {
    return 'Kontroller tilkoblet: $name';
  }

  @override
  String get settingsOfflineModeTitle => 'Nettverksmodus';

  @override
  String get settingsOfflineModeSubtitle => 'Offline: spill med en gang mot en bot, uten innsatser og belønninger, uten chatter og venner. Kjøp lagres og brukes i online-modus. Online — når det er internett eller etter brukerinnstillingen.';

  @override
  String get settingsModeOnline => 'Online';

  @override
  String get settingsModeOffline => 'Offline';

  @override
  String get gamesAlternateStartsHint => 'På tur hvem som starter partiet';

  @override
  String get rulesAlternateStarts => 'Hvem som trekker først veksler fra parti til parti.';

  @override
  String get offlineBadgeTooltip => 'Offline-modus';

  @override
  String get offlineModePopupTitle => 'Offline-modus';

  @override
  String get offlineModePopupBody => 'Offline-modus er på. Spill mot en bot uten innsatser og belønninger. Chatter, venner og lobby er skjult. Kjøp brukes i online-modus.';

  @override
  String get offlineModePopupSettings => 'Innstillinger';

  @override
  String get offlineModeOfferBody => 'Ingen internett, eller forbindelsen er veldig treg. Du kan slå på offline-modus og spille mot en bot.';

  @override
  String get offlineModeOfferAction => 'Slå på offline';

  @override
  String get gamesPlay => 'Spill';

  @override
  String get offlineGameTitle => 'Spill mot bot';

  @override
  String get offlineGameHint => 'Uten innsatser og belønninger · kun offline';

  @override
  String get offlineBotWon => 'Boten vant';

  @override
  String get offlineBotThinking => 'Boten tenker…';

  @override
  String get offlinePlayAgain => 'Igjen';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'Ta';

  @override
  String get durakActionAll => 'Alle';

  @override
  String get durakActionDone => 'Ferdig';

  @override
  String get durakActionBito => 'Beat';

  @override
  String get durakHintDefend => 'Forsvar';

  @override
  String get durakHintDefendOrTransfer => 'Forsvar eller overfør';

  @override
  String get durakHintOpponentDefends => 'Motstanderen forsvarer';

  @override
  String get durakHintThrowInFirst => 'Legg kort (max 5 i første slag)';

  @override
  String get durakHintThrowIn => 'Legg kort eller vent på forsvaret';

  @override
  String get durakHintOpponentThrows => 'Motstanderen legger på';

  @override
  String get durakHintTakeFollow => 'Legg på etter ta eller trykk «Ferdig»';

  @override
  String get durakHintOpponentTakeFollow => 'Motstanderen kan legge på etter ta';

  @override
  String get durakHintBito => 'Legg en kort eller si «Bito»';

  @override
  String get durakHintOpponentBito => 'Motstanderen legger på eller sier «Bito»';

  @override
  String get durakHintYourAttack => 'Din tur — angrip';

  @override
  String get durakHintOpponentAttack => 'Motstanderen angriper';

  @override
  String get durakHintYouLost => 'Du tapte — du er narren';

  @override
  String get durakHintDrawAllOut => 'Uavgjort — alle er ute';

  @override
  String get durakHintYouFinished => 'Du er ute — venter på slutten';

  @override
  String get durakFirstLeadYou => 'Du går først';

  @override
  String get durakFirstLeadOpponent => 'Motstanderen går først';

  @override
  String get durakFirstLeadBot => 'Boten går først';

  @override
  String durakFirstLeadOf(String name) {
    return '$name går først';
  }

  @override
  String get durakFirstLeadReason => 'Laveste trumf';

  @override
  String get shopPurchaseQueued => 'Kjøp lagret — brukes i online-modus';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — kjøp brukt';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — kjøp ikke brukt: $reason';
  }

  @override
  String get settingsFriendsOnlyTitle => 'Meldinger kun fra venner';

  @override
  String get settingsFriendsOnlySubtitle => 'Ikke-venner kan bare sende emojier. Ved spam, blokker brukeren midlertidig.';

  @override
  String get settingsNotifications => 'Varsler';

  @override
  String get settingsPushChat => 'Chat';

  @override
  String get settingsPushFriends => 'Venner';

  @override
  String get settingsPushGames => 'Spill';

  @override
  String get settingsPushRewards => 'Belønninger';

  @override
  String settingsAppVersion(String version) {
    return 'Versjon $version';
  }

  @override
  String get appUpdateTitle => 'Oppdatering tilgjengelig';

  @override
  String get appUpdateBody => 'En ny versjon av appen er tilgjengelig. Oppdater for å fortsette.';

  @override
  String get appUpdateWhatsNew => 'Nyheter';

  @override
  String get appUpdateOk => 'Oppdater';

  @override
  String get appUpdateLaterBanner => 'Vi oppdaterer appen etter dette spillet';

  @override
  String get loginTitle => 'Logg inn';

  @override
  String get loginSubtitle => 'Skriv inn e-post eller brukernavn og passord';

  @override
  String get loginEmailLabel => 'E-post eller brukernavn';

  @override
  String get loginPasswordLabel => 'Passord';

  @override
  String get loginSubmit => 'Logg inn';

  @override
  String get loginNoAccount => 'Ingen konto? Registrer deg';

  @override
  String get loginEmailRequired => 'Skriv inn e-post eller brukernavn';

  @override
  String get loginPasswordRequired => 'Skriv inn passord';

  @override
  String get loginTooltip => 'Logg inn';

  @override
  String get logoutTooltip => 'Logg ut';

  @override
  String get registerTitle => 'Registrer deg';

  @override
  String get registerSubtitle => 'Opprett en konto for å spille';

  @override
  String get registerNameLabel => 'Navn (brukernavn)';

  @override
  String get registerEmailLabel => 'E-post';

  @override
  String get registerPasswordLabel => 'Passord';

  @override
  String get registerSubmit => 'Registrer deg';

  @override
  String get registerHaveAccount => 'Har du allerede en konto? Logg inn';

  @override
  String get registerNameRequired => 'Skriv inn et navn';

  @override
  String get registerNameNoSpaces => 'Navnet kan ikke inneholde mellomrom';

  @override
  String get registerNameMax => 'Maksimum 20 tegn';

  @override
  String get registerNameHint => 'Opptil 20 tegn';

  @override
  String get registerEmailRequired => 'Skriv inn e-post';

  @override
  String get registerEmailInvalid => 'Ugyldig e-post';

  @override
  String get registerPasswordHint => 'Minst 6 tegn';

  @override
  String get registerPasswordMin => 'Passordet må være minst 6 tegn';

  @override
  String get commonCancel => 'Avbryt';

  @override
  String get commonSave => 'Lagre';

  @override
  String get commonDelete => 'Slett';

  @override
  String get commonEdit => 'Rediger';

  @override
  String get commonReply => 'Svar';

  @override
  String get commonSend => 'Send';

  @override
  String get commonClose => 'Lukk';

  @override
  String get commonRetry => 'Prøv igjen';

  @override
  String get commonLoading => 'Laster…';

  @override
  String get commonError => 'Feil';

  @override
  String get commonOnline => 'pålogget';

  @override
  String get commonOffline => 'avlogget';

  @override
  String get commonOnlineCap => 'Pålogget';

  @override
  String get commonUser => 'Bruker';

  @override
  String get commonPlayer => 'Spiller';

  @override
  String get commonAboutMe => 'Om meg';

  @override
  String get commonBack => 'Tilbake';

  @override
  String get commonAccept => 'Godta';

  @override
  String get commonDecline => 'Avslå';

  @override
  String get commonCreating => 'Oppretter…';

  @override
  String get commonSearching => 'Søker…';

  @override
  String get commonInsufficientCoins => 'Ikke nok mynter';

  @override
  String get commonNotFound => 'Ikke funnet';

  @override
  String get commonServerErrorShort => 'Serverfeil';

  @override
  String get commonForbidden => 'Tilgang nektet';

  @override
  String get commonUserBlocked => 'Brukeren er blokkert';

  @override
  String get commonUserNotFound => 'Brukeren ble ikke funnet';

  @override
  String get commonGenericError => 'Noe gikk galt. Prøv igjen.';

  @override
  String get apiErrWrongGameType => 'Feil spilltype';

  @override
  String get apiErrWrongGameTypeOrState => 'Feil spilltype eller tilstand';

  @override
  String get apiErrLobbyFull => 'Lobbyen er full';

  @override
  String get apiErrBadState => 'Ugyldig spilltilstand';

  @override
  String get apiErrIllegalMove => 'Ulovlig trekk';

  @override
  String get apiErrUnknownMoveType => 'Ukjent trekktype';

  @override
  String get apiErrNoOpponents => 'Ingen motstandere';

  @override
  String get apiErrNoOpponentsRematch => 'Ingen motstandere til omkamp';

  @override
  String get apiErrAlreadyInLobby => 'Du er allerede i denne lobbyen';

  @override
  String get apiErrGameNotActive => 'Spillet er ikke aktivt';

  @override
  String get apiErrNotInBattle => 'Ikke i kampfasen';

  @override
  String get apiErrNotInSetup => 'Ikke i oppstillingsfasen';

  @override
  String get apiErrAlreadyReady => 'Du er allerede klar';

  @override
  String get apiErrAlreadyForfeited => 'Du har allerede gitt opp';

  @override
  String get apiErrYouHaveForfeited => 'Du har gitt opp';

  @override
  String get apiErrNoDrawOffer => 'Ingen uavgjort-tilbud';

  @override
  String get apiErrDrawOnlyPvp => 'Uavgjort er bare mot en spiller';

  @override
  String get apiErrDrawOnly1v1 => 'Uavgjort er bare i 1 mot 1';

  @override
  String get apiErrDrawVsBot => 'Uavgjort er ikke tilgjengelig mot bot';

  @override
  String get apiErrDrawMultiplayer => 'Uavgjort er ikke tilgjengelig i flerspiller';

  @override
  String get apiErrDeck24TwoPlayers => 'Kortstokk på 24 er bare for 2 spillere';

  @override
  String get apiErrDeck52ThreeOrFour => 'Kortstokk på 52 krever 3 eller 4 spillere';

  @override
  String get apiErrAccountFrozen => 'Kontoen er frosset';

  @override
  String get apiErrTurnTimeInvalid => 'Trekktiden må være 0, 20, 60 eller 600 sekunder';

  @override
  String get timeJustNow => 'akkurat nå';

  @override
  String get timeYesterday => 'i går';

  @override
  String timeMinutesAgo(int count) {
    return '$count min siden';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count t siden';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count d siden';
  }

  @override
  String get timeWeekAgo => 'en uke siden';

  @override
  String timeWeeksAgo(int count) {
    return '$count u siden';
  }

  @override
  String get timeMonthAgo => 'en måned siden';

  @override
  String timeMonthsAgo(int count) {
    return '$count md. siden';
  }

  @override
  String get timeYearAgo => 'et år siden';

  @override
  String timeYearsAgo(int count) {
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
  String get monthDec => 'Des';

  @override
  String get homeAchievements => 'Prestasjoner';

  @override
  String get homeAchievementsSubtitle => 'Dine spillresultater';

  @override
  String get homeAchievementsRewards => 'Belønninger klare til å hentes';

  @override
  String get homeCoins => 'Mynter';

  @override
  String get homeCoinsSubtitle => 'Saldo og belønninger';

  @override
  String get homeCoinsDailyReward => 'Daglig innloggingsbelønning tilgjengelig';

  @override
  String get homeItems => 'Gjenstander';

  @override
  String get homeItemsInventory => 'Din inventar';

  @override
  String get homeItemsGifted => 'Noen ga deg en samling';

  @override
  String get homeItemsIncome => 'Samlinginntekt klar til å hentes';

  @override
  String get homeShop => 'Butikk';

  @override
  String get homeShopSubtitle => 'Emojier, innsatser, samlinger';

  @override
  String get gamesTitle => 'Spill';

  @override
  String get gamesFindMatch => 'Finn et spill';

  @override
  String get gamesMyTurn => 'Din tur';

  @override
  String get gamesWaiting => 'Venter';

  @override
  String get gamesLobbyTab => 'Lobby';

  @override
  String get gamesTicTacToe => 'Tripp-trapp-tresko';

  @override
  String get gamesDurak => 'Durak';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => 'Roter';

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
  String get gamesCheckers => 'Dam';

  @override
  String get gamesCheckersModeRussian => 'Russisk';

  @override
  String get gamesCheckersModeEnglish => 'Engelsk';

  @override
  String get gamesCheckersModeGiveaway => 'Gi-bort';

  @override
  String get gamesCheckersModeCorners => 'Hjørner';

  @override
  String get gamesChess => 'Sjakk';

  @override
  String get gamesChessModeClassic => 'Klassisk';

  @override
  String get gamesChessMode960 => 'Sjakk960';

  @override
  String get gamesChessModeAntichess => 'Antisjakk';


  @override
  String get rulesCheckersPlayers => 'Spillere: 2.';

  @override
  String rulesCheckersMode(String mode) {
    return 'Modus: $mode.';
  }

  @override
  String rulesCheckersTime(String time) {
    return 'Время на ход: $time. Если время вышло — проигрыш.';
  }

  @override
  String get rulesCheckersIntro => 'Brett 8×8. To spillere.';

  @override
  String get rulesCheckersPlay => 'Slag er plikt. Dame og brikke må fortsette så lenge et nytt hopp går fra landingsfeltet — du kan ikke stanse midt i. Finnes flere retninger kan du velge hvilken som helst, ikke nødvendigvis den lengste. En brikke på siste rad blir dame.';

  @override
  String get rulesCheckersWin => 'В русских шашках побеждает тот, кто съел все шашки соперника или лишил его хода. В поддавках наоборот: кто не может ходить — выигрывает.';

  @override
  String get rulesCheckersOfflineBot => 'Офлайн: партия против бота.';

  @override
  String get rulesCheckersPlayRussian => 'Russisk dam: 12 brikker hver på mørke felt. Bønder går skrått frem og slår frem og tilbake. Damer flyr fritt. Slag er plikt: du må fortsette hvis det går, men kan velge hvilken som helst retning — ikke nødvendigvis den lengste. Vinn ved å slå alle brikker eller etterlate motstanderen uten trekk.';

  @override
  String get rulesCheckersPlayEnglish => 'Engelsk dam: 12 brikker hver. Bønder går og slår bare skrått frem. Damer går ett felt skrått i alle retninger. Slag er plikt. Vinn ved å slå alle brikker eller etterlate motstanderen uten trekk.';

  @override
  String get rulesCheckersPlayGiveaway => 'Gi-bort: samme trekk som russisk dam, men målet er omvendt — gi bort alle brikker eller stå uten trekk. Slag er fortsatt plikt.';

  @override
  String get rulesCheckersPlayCorners => 'Hjørner: brikkene starter i motstående hjørner. Gå til et tomt nabo-felt vannrett eller loddrett, eller hopp over en hvilken som helst brikke uten å fjerne den. Målet er å flytte alle brikkene til motstanderens hjørne.';

  @override
  String get rulesCheckersPlayCornersNoReturn => 'En brikke som har forlatt start-hjørnet sitt, kan ikke returnere dit.';

  @override
  String get rulesCheckersPlayCornersLeaveHome => 'Brikker som fortsatt er i hjemmet, må forlate det i spillerens 25 første trekk.';

  @override
  String get rulesCheckersDrawRussian => 'Remis hvis stillingen gjentas tre ganger, eller hvis 15 trekk per side bare er dame-trekk uten slag — også to damer mot to.';

  @override
  String get rulesCheckersDrawEnglish => 'Remis ved tredobbelt gjentakelse, 40 trekk uten slag eller bonde-trekk, eller én dame mot én dame.';

  @override
  String get rulesCheckersDrawGiveaway => 'Remis ved tredobbelt gjentakelse eller 15 dame-trekk uten slag.';

  @override
  String get rulesCheckersDrawCorners => 'Remis ved tredobbelt gjentakelse eller 25 trekk per side uten ekstra brikke i målhjørnet.';

  @override
  String get rulesChessPlayers => 'Spillere: 2.';

  @override
  String rulesChessMode(String mode) {
    return 'Modus: $mode.';
  }

  @override
  String get rulesChessPlayClassic => 'Klassisk: brett 8×8. Hver side har konge, dronning, to tårn, to løpere, to springere og åtte bønder. Hvit starter. Vanlige trekk, en passant, forvandling og rokade. Seier ved matt eller oppgitt.';

  @override
  String get rulesChessPlay960 => 'Sjakk960: vanlige trekk. Siste rad stokkes etter Fischer: kongen mellom tårnene, løpere på ulike farger. Rokade til c og g. Matt eller oppgitt.';

  @override
  String get rulesChessPlayAntichess => 'Antisjakk: vanlige trekk, slå er påbudt. Ingen sjakk — kongen kan slås. Ingen rokade. Den som gir bort alle brikker eller ikke kan trekke vinner.';

  @override
  String get rulesChessDrawClassic => 'Remis ved patt, tredobbelt gjentakelse, 50-trekksregelen, for lite materiell eller avtale.';

  @override
  String get rulesChessDraw960 => 'Remis ved patt, tredobbelt gjentakelse, 50-trekksregelen, for lite materiell eller avtale.';

  @override
  String get rulesChessDrawAntichess => 'Remis ved tredobbelt gjentakelse eller hvis begge blir uten brikker i samme trekk.';


  @override
  String get checkersDrawRepetition => 'Remis — stillingen gjentatt tre ganger';

  @override
  String get checkersDrawNoProgress => 'Remis — trekkene fører ikke til seier';

  @override
  String get checkersDrawInsufficient => 'Remis — ikke nok materiale til seier';

  @override
  String get rulesNardyTitle => 'Backgammon — regler';

  @override
  String get rulesNardyPlayers => 'Spillere: 2.';

  @override
  String rulesNardyMode(String mode) {
    return 'Modus: $mode.';
  }

  @override
  String get rulesNardyIntro => 'Brett med 24 punkter, 15 brikker hver. To terninger: én brik summen eller to brikker øynene.';

  @override
  String get rulesNardyPlayShort => 'Kort backgammon: dere går mot hverandre og kan slå ensomme brikker. En slått brikke går på barren og må inn igjen. Når alle er i hjemmet, tar dere dem av.';

  @override
  String get rulesNardyPlayLong => 'Langt backgammon: begge starter fra samme hode og går samme vei. Høyst én brikke forlater hodet per trekk. Slag er ikke tillatt. Når alle er i hjemmet, tar dere dem av.';

  @override
  String get rulesNardyWin => 'Den som først tar av alle brikker, vinner.';

  @override
  String get rulesNardySixPrime => 'Du kan ikke stenge seks punkter på rad før minst én av motstanderens brikker har passert dem.';

  @override
  String get nardyRoll => 'Kast';

  @override
  String get nardySkipTurn => 'Hopp over turen';

  @override
  String get nardyUndoMove => 'Angre';

  @override
  String get nardyDoneTurn => 'Ferdig';

  @override
  String get nardyAutoConfirm => 'Autobekreft';

  @override
  String get nardyAutoConfirmHint => 'Etter alle trekk går turen automatisk videre';

  @override
  String get nardyLayoutToggle => 'Bytt oppstilling';

  @override
  String get nardyNoMoves => 'Ingen trekk';

  @override
  String get nardyYourRoll => 'Ditt kast';

  @override
  String get nardyPipsShort => 'Igjen:';

  @override
  String get nardyYouWonMars => 'Du vant — gammon!';

  @override
  String get nardyYouLostMars => 'Tap — gammon';

  @override
  String get rulesNardyOfflineBot => 'Offline: parti mot boten.';

  @override
  String rulesUnoPlayers(int players) {
    return 'Spillere: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'Spill mot en bot uten tidsbegrensning per trekk.';

  @override
  String get rulesUnoIntro => 'Hver spiller får 7 kort. Spill et kort i samme farge eller samme rang (tall eller samme handling).';

  @override
  String get rulesUnoPlay => 'Hopp over — neste mister turen. Retningsbytte med to spillere virker som hopp over. +2 stables bare på +2 og +4 bare på +4: straffen summeres (to +2 gjør at neste trekker 4). +2 kan ikke legges på +4. Den som ikke stabler trekker hele bunken og mister turen. To like ikke-svarte kort (f.eks. to gule 8) kastes sammen: spill ett, så følger tvillingen automatisk med.';

  @override
  String get rulesUnoWild => 'Et svart kort setter ny farge. Spill +4 bare hvis du ikke har kort i gjeldende farge. Motstanderen kan utfordre: var +4 lovlig, trekker hen 6; ellers trekker +4-spilleren 4 og utfordreren spiller.';

  @override
  String get rulesUnoDraw => 'Uten lovlig kort, trekk ett fra bunken. Matcher det, kan du spille det med en gang eller beholde det og gi turen videre. Du kan ikke trekke mens du har et lovlig trekk.';

  @override
  String get rulesUnoWin => 'To spillere til 100, 3+ til 200. En runde vinnes ved å tømme hånden.';

  @override
  String get rulesUnoCall => 'Når ett kort gjenstår, trykk «Uno!» med en gang. Motstandere kan ta deg for glemt Uno først etter ett sekund — da trekker du 2 kort.';

  @override
  String get rulesUnoScoring => 'Den som først tømmer hånden vinner runden og får poeng for motstandernes kort: tall etter verdi, handlinger 20, svarte 50. To spillere til 100, 3+ til 200.';

  @override
  String get unoColorRed => 'Rød';

  @override
  String get unoColorYellow => 'Gul';

  @override
  String get unoColorGreen => 'Grønn';

  @override
  String get unoColorBlue => 'Blå';

  @override
  String get unoDraw => 'Trekk';

  @override
  String get unoKeep => 'Behold';

  @override
  String get unoSayUno => 'Uno!';

  @override
  String get unoChallengeUno => 'Utfordre Uno';

  @override
  String get unoChallengeWd4 => 'Utfordre +4';

  @override
  String get unoChooseColor => 'Velg en farge';

  @override
  String get unoDrawPile => 'Trekkbunke';

  @override
  String get unoDiscardPile => 'Kastebunke';

  @override
  String unoCardsCount(int count) {
    return 'Kort: $count';
  }

  @override
  String unoScore(int score) {
    return 'Poeng: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'Runde $round · til $target';
  }

  @override
  String get unoYourTurn => 'Din tur';

  @override
  String get unoWaitingTurn => 'Motspillerens tur';

  @override
  String get unoChooseColorHint => 'Velg en farge for jokeren';

  @override
  String get unoWd4Hint => 'Trekk 4 kort eller utfordre Wild +4';

  @override
  String get unoDrawnHint => 'Spill det trukne kortet eller behold det';

  @override
  String get unoPlayHint => 'Spill en matchende farge eller verdi';

  @override
  String get unoDrawHint => 'Ingen matchende kort — trekk fra bunken';

  @override
  String unoPendingDraw(int count) {
    return '+$count kort';
  }

  @override
  String get unoYouWon => 'Du vant kampen!';

  @override
  String get unoYouLost => 'Kampen er over';

  @override
  String get unoYouLostTimeout => 'Du tapte på tid';

  @override
  String unoWinner(String name) {
    return 'Vinner: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name vinner runden';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'Neste';

  @override
  String get unoRoundScoresTitle => 'Rundepoeng';

  @override
  String get unoDirectionClockwise => 'Med klokken';

  @override
  String get unoDirectionCounterclockwise => 'Mot klokken';

  @override
  String get unoErrStackSameOnly => 'På +2 kan bare +2 legges, på +4 bare +4. +2 på +4 er ikke tillatt.';

  @override
  String get unoErrCatchTooEarly => 'Vent et sekund — de kan fortsatt si Uno.';

  @override
  String get unoErrCallTooLate => 'Du kan ikke lenger si Uno. Neste spiller har allerede spilt.';

  @override
  String get gamesInDevelopment => 'Under utvikling';

  @override
  String rulesPokerPlayers(int players) {
    return 'Spillere: $players.';
  }

  @override
  String get rulesPokerIntro => 'Texas Hold’em. Hver spiller får 2 hullkort; 5 felleskort legges på bordet.';

  @override
  String get rulesPokerPlay => 'Innsatsrunder: preflop, flop, turn og river. Fold, call, bet eller raise.';

  @override
  String get rulesPokerWin => 'Beste femkorts-hånd (hull + felles) vinner, eller siste spiller etter folds.';

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
  String get pokerCombinationsTitle => 'Hand rankings';

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
  String get gamesRules => 'Regler';

  @override
  String get gamesRulesTitle => 'Spillregler';

  @override
  String get gamesCreate => 'Opprett spill';

  @override
  String get gamesJoin => 'Bli med';

  @override
  String get gamesOpponentTurn => 'Motstanderens tur';

  @override
  String get gamesCurrentGame => 'Pågående spill';

  @override
  String get gamesInvitedYou => 'Du ble invitert';

  @override
  String get gamesTurnTime => 'Tid per tur';

  @override
  String get gamesGridSize => 'Rutenettstørrelse';

  @override
  String get gamesSwapSides => 'Sidebytte';

  @override
  String get gamesNoCenter => 'Ingen start i midten';

  @override
  String get gamesObservation => 'Ser med';

  @override
  String get gamesObservationHint => 'Du kan se til spillet er over';

  @override
  String get gamesFinishCurrentFirst => 'Fullfør ditt nåværende spill først';

  @override
  String get gamesVariantClassic => 'Klassisk';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 spillere';

  @override
  String get gamesVariantMulti4 => '4 spillere';

  @override
  String get gamesDurakModePodkidnoi => 'Pålegg';

  @override
  String get gamesDurakModePerevodnoi => 'Overføring';

  @override
  String get gamesDurakDeck24 => '24 kort';

  @override
  String get gamesDurakDeck36 => '36 kort';

  @override
  String get gamesDurakDeck52 => '52 kort';

  @override
  String rulesDurakMode(String mode) {
    return 'Modus: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'Spillere: $players. Kortstokk: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Spill mot en bot, uten innsats eller tid.';

  @override
  String get rulesDurakAttack => 'Angriperen legger kort; forsvareren slår dem (samme farge høyere, eller trumf). Trumf slås bare av høyere trumf.';

  @override
  String get rulesDurakBeat => 'Når alle kort er slått, sier angriperen «Bito», og kortene går i bunken. Ellers tar forsvareren alt fra bordet.';

  @override
  String get rulesDurakLoser => 'Taperen er den som har kort igjen til slutt — «narren».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Spillere $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Lobby $name';
  }

  @override
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Privat spill';

  @override
  String get lobbySearchingOpponent => 'Ser etter motstander…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Søker etter dette spillet: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Venter på at noen trykker «Finn et spill» eller «Bli med»';

  @override
  String get lobbyInviteTitle => 'Spillinvitasjon';

  @override
  String get lobbyInvitedToPlay => 'Du ble invitert til å spille';

  @override
  String get lobbyEnterGame => 'Gå inn i spillet';

  @override
  String get lobbyGone => 'Lobbyen er ikke lenger tilgjengelig';

  @override
  String get lobbyInvite => 'Inviter';

  @override
  String get lobbyInviteSent => 'Invitasjon sendt';

  @override
  String get lobbyCopyLink => 'Del spilllenke';

  @override
  String get lobbyLinkCopied => 'Lenke kopiert';

  @override
  String get lobbyNoFriendsOnline => 'Ingen venner pålogget. Del spilllenken ovenfor eller vent til venner kommer pålogget.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Motstander';

  @override
  String get gameYouWon => 'Du vant!';

  @override
  String get gameYouLost => 'Du tapte';

  @override
  String get gameYouWonOpponentLeft => 'Du vant — motstanderen forlot';

  @override
  String get gameYouWonOpponentTimeout => 'Du vant — motstanderen gikk tom for tid';

  @override
  String get gameDraw => 'Uavgjort';

  @override
  String get gameExitTitle => 'Forlat spillet';

  @override
  String get gameExitConfirm => 'Hvis du går, taper du. Forlate likevel?';

  @override
  String get gameStay => 'Bli';

  @override
  String get gameLeave => 'Forlat';

  @override
  String get gameSurrender => 'Gi opp';

  @override
  String get gameSurrenderTitle => 'Gi opp?';

  @override
  String get gameSurrenderConfirm => 'Du taper partiet og innsatsmyntene.';

  @override
  String get gameOfferDraw => 'Tilby remis';

  @override
  String get gameOfferDrawTitle => 'Tilby remis?';

  @override
  String get gameOfferDrawConfirm => 'Motstanderen din kan godta eller avslå remis.';

  @override
  String get gameAcceptDrawTitle => 'Godta remis?';

  @override
  String get gameAcceptDrawConfirm => 'Partiet ender uavgjort.';

  @override
  String get gameDrawOffered => 'Motstanderen tilbyr remis';

  @override
  String get gameConnecting => 'Kobler til spillet…';

  @override
  String get gameWaitingOpponent => 'Venter på motstander';

  @override
  String get gameRematchOffer => 'Motstanderen tilbyr omkamp';

  @override
  String get gameRematchDeclined => 'Motstanderen avslo omkampen';

  @override
  String get gameRematch => 'Omkamp';

  @override
  String get gameOtherOpponent => 'Annen motstander';

  @override
  String get gameSwapSidesAction => 'Bytt side';

  @override
  String get gameWriteMessage => 'Skriv en melding';

  @override
  String get chatsTitle => 'Chatter';

  @override
  String get chatsEmpty => 'Ingen chatter ennå.\nTrykk på ikonet øverst til høyre for å velge en venn og starte en samtale.';

  @override
  String get chatsNewChat => 'Ny chat';

  @override
  String get chatsNoMessages => 'Ingen meldinger';

  @override
  String get chatsClearTitle => 'Tøm samtalen?';

  @override
  String get chatsClearDesc => 'Chatten slettes permanent.';

  @override
  String get chatsClearConfirm => 'Tøm';

  @override
  String get chatsBlockTitle => 'Blokkere denne brukeren?';

  @override
  String get chatsBlockDesc => 'Dere kan ikke lenger sende meldinger til hverandre. Chatten og vennskapet fjernes.';

  @override
  String get chatsBlockConfirm => 'Blokker';

  @override
  String get chatsBlockedUsers => 'Blokkerte brukere';

  @override
  String get chatsUnblock => 'Opphev blokkering';

  @override
  String get chatDialog => 'Chat';

  @override
  String get chatEmpty => 'Ingen meldinger ennå.\nSend den første.';

  @override
  String get chatMessageHint => 'Melding';

  @override
  String get chatPaste => 'Lim inn';

  @override
  String get chatEmoji => 'Emojier';

  @override
  String get chatBuyEmojiHint => 'Kjøp emojier i butikken på startskjermen';

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
  String get emojiGroupGame => 'Spill';

  @override
  String get emojiGroupFlags => 'Flagg';

  @override
  String get emojiGroupAnimals => 'Dyr';

  @override
  String get emojiGroupFood => 'Mat';

  @override
  String get emojiGroupTravel => 'Reise';

  @override
  String get emojiGroupParty => 'Feiring';

  @override
  String get emojiGroupObjects => 'Objekter';

  @override
  String get friendsTitle => 'Venner';

  @override
  String get friendsTabFriends => 'Venner';

  @override
  String get friendsTabIncoming => 'Innkommende';

  @override
  String get friendsTabOutgoing => 'Utgående';

  @override
  String get friendsAdd => 'Legg til venn';

  @override
  String get friendsRequestSent => 'Forespørsel sendt';

  @override
  String get friendsFindTab => 'Finn venn';

  @override
  String get friendsSearchHint => 'Søk etter brukernavn';

  @override
  String get friendsSearchPrompt => 'Bruk søk for å finne nye venner';

  @override
  String get friendsNothingFound => 'Ingenting funnet';

  @override
  String get friendsEmpty => 'Du har ingen venner ennå';

  @override
  String get friendsSearchNoMatches => 'Ingen venner samsvarer med søket';

  @override
  String get friendsIncomingSearchNoMatches => 'Ingen innkommende forespørsler samsvarer med søket';

  @override
  String get friendsOutgoingSearchNoMatches => 'Ingen utgående forespørsler samsvarer med søket';

  @override
  String get friendsNoIncoming => 'Ingen innkommende forespørsler';

  @override
  String get friendsNoOutgoing => 'Ingen utgående forespørsler';

  @override
  String get friendsAlreadyFriends => 'Allerede venner';

  @override
  String get friendsRemoveTitle => 'Fjerne fra venner?';

  @override
  String get friendsRemoved => 'Fjernet fra venner';

  @override
  String get friendsRequestAccepted => 'Forespørsel godtatt';

  @override
  String get friendsRequestDeclined => 'Forespørsel avslått';

  @override
  String get friendsRequestCancelled => 'Forespørsel avbrutt';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSignInPrompt => 'Logg inn på kontoen din';

  @override
  String get profileSignInHint => 'For å sette opp din personlige profil';

  @override
  String get profileEdit => 'Rediger';

  @override
  String get profileCollections => 'Samlinger';

  @override
  String get profileAge => 'Alder';

  @override
  String get profileGender => 'Kjønn';

  @override
  String get profileGenderUnset => 'Ikke angitt';

  @override
  String get profileGenderMale => 'Mann';

  @override
  String get profileGenderFemale => 'Kvinne';

  @override
  String get profileAvatar => 'Avatar';

  @override
  String get profileUploadPhoto => 'Last opp bilde';

  @override
  String get profileChangePhoto => 'Bytt avatar';

  @override
  String get shopTitle => 'Butikk';

  @override
  String get shopEmojis => 'Emojier';

  @override
  String get shopEmojisSubtitle => 'Animerte emojier for chat';

  @override
  String get shopCollections => 'Samlinger';

  @override
  String get shopCollectionsSubtitle => 'Profilutstilling, gaver og inntekt';

  @override
  String get shopStakes => 'Innsatser';

  @override
  String get shopStakesSubtitle => 'Lås opp høyere innsatser';

  @override
  String get shopEmojisHelp => 'Animerte emojier for chatten. Kjøp et sett og send dem til venner.';

  @override
  String get shopCollectionsHelp => 'Samle et sett gjenstander: de vises i profilens monter og kan gis bort eller selges. En komplett samling gir ekstra mynter hver dag.\n\nTilstanden avhenger av hvor lenge du har hatt samlingen. Ny — de første 7 dagene, salg 80 %. Slitt — fra dag 8 til 2 måneder, salg 60 %. Trett — fra 2 til 6 måneder, salg 40 %. Falleferdig — fra 6 måneder til 1 år, salg 100 %. Vintage — fra 1 år, salg 300 %.';

  @override
  String get shopStakesHelp => 'Lås opp høyere innsatser. Jo høyere innsats, desto større pott og gevinst.';

  @override
  String get inventoryTitle => 'Gjenstander';

  @override
  String get inventoryEmpty => 'Ingenting her ennå — sjekk butikken';

  @override
  String get inventoryFrames => 'Rammer';

  @override
  String get inventoryClaim => 'Hent';

  @override
  String get inventorySell => 'Selg';

  @override
  String get inventoryGift => 'Gi bort';

  @override
  String get messageEdited => 'redigert';

  @override
  String get messageDeleted => 'Melding slettet';

  @override
  String get photo => 'Bilde';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galleri';

  @override
  String get connectionError => 'Kunne ikke koble til serveren.';

  @override
  String get serverError => 'Serverfeil. Prøv igjen senere.';

  @override
  String get sessionExpired => 'Økten er utløpt. Logg inn på nytt.';

  @override
  String get errNoInternet => 'Ingen internettforbindelse.';

  @override
  String get errTimeout => 'Forespørselen tok for lang tid. Prøv igjen.';

  @override
  String get errGamesUnavailable => 'Spill er midlertidig utilgjengelige';

  @override
  String get errSettingsSaveFailed => 'Kunne ikke lagre innstillingen';

  @override
  String get errPushPermission => 'Tillat varsler i nettleser- eller systeminnstillingene.';

  @override
  String get balanceTitle => 'Saldo';

  @override
  String get coinBronze => 'Bronse';

  @override
  String get coinSilver => 'Sølv';

  @override
  String get coinGold => 'Gull';

  @override
  String get coinDiamond => 'Diamant';

  @override
  String get balanceZeroBronze => '0 bronse';

  @override
  String balanceBronzes(int count) {
    return '$count bronse';
  }

  @override
  String balanceSilvers(int count) {
    return '$count sølv';
  }

  @override
  String balanceGolds(int count) {
    return '$count gull';
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
  String get commonBackHome => 'Tilbake til forsiden';

  @override
  String get commonCopied => 'Kopiert';

  @override
  String get commonClear => 'Tøm';

  @override
  String get commonTryLater => 'Prøv igjen senere.';

  @override
  String get commonTryRefresh => 'Prøv å oppdatere siden.';

  @override
  String get coinsTitle => 'Mynter';

  @override
  String get coinsLoginReward => 'Innloggingsbelønning';

  @override
  String get coinsLoginAvailableToday => 'Dagens belønning er tilgjengelig';

  @override
  String get coinsLoginStreak => 'Daglig innloggingsrekke';

  @override
  String get coinsFriendReward => 'Vennebelønning';

  @override
  String get coinsTasks => 'Oppgaver';

  @override
  String get coinsTasksSubtitle => 'Belønninger for profil, venner og spill';

  @override
  String get coinsTasksRewards => 'Belønninger klare til å hentes';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount for registrering via lenken din';
  }

  @override
  String get coinsLoadRewardsFailed => 'Kunne ikke laste belønninger';

  @override
  String get coinsClaimReward => 'Hent belønning';

  @override
  String get coinsAlreadyClaimed => 'Allerede hentet';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · i dag';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · 1 dag igjen';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · $remaining igjen';
  }

  @override
  String get coinsInviteFriend => 'Inviter en venn';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount for hver som registrerer seg via lenken din';
  }

  @override
  String get coinsCopyLink => 'Kopier lenke';

  @override
  String get coinsHowItWorks => 'Slik fungerer det';

  @override
  String get coinsHowStep1 => 'Kopier lenken og send den til en venn';

  @override
  String get coinsHowStep2 => 'Vennen registrerer seg via den lenken';

  @override
  String coinsHowStep3(String amount) {
    return 'Du mottar $amount';
  }

  @override
  String get achievementsTitle => 'Prestasjoner';

  @override
  String achievementsProgress(String progress) {
    return 'Fremdrift: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Ramme hentet';

  @override
  String get achievementsClaimed => 'Hentet';

  @override
  String get achievementsOpenFrame => 'Åpne ramme';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Er du sikker på at du vil fjerne $name fra venner?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Fjern';

  @override
  String get friendsRemove => 'Fjern fra venner';

  @override
  String get friendsAcceptRequest => 'Godta forespørsel';

  @override
  String get friendsDeclineRequest => 'Avslå forespørsel';

  @override
  String get friendsCancelRequest => 'Avbryt forespørsel';

  @override
  String get friendsSendRequest => 'Send venneforespørsel';

  @override
  String get friendsRequestAlreadySent => 'Forespørsel allerede sendt';

  @override
  String get friendsIncomingStatus => 'Innkommende forespørsel';

  @override
  String get friendsOutgoingStatus => 'Utgående forespørsel';

  @override
  String get friendsNotFriends => 'Ikke venner';

  @override
  String get friendsCollapseSearch => 'Skjul søk';

  @override
  String get friendsExpandSearch => 'Vis søk';

  @override
  String get friendsLoadFailed => 'Kunne ikke laste venner';

  @override
  String friendsSince(String date) {
    return 'Venner siden: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Innkommende forespørsel: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Utgående forespørsel: $date';
  }

  @override
  String get userInfoTitle => 'Brukerinfo';

  @override
  String profileAgeYears(int age) {
    return '$age år';
  }

  @override
  String get shopBuy => 'Kjøp';

  @override
  String get shopBuyTitle => 'Kjøpe?';

  @override
  String get shopBuyStakeTitle => 'Kjøpe innsats?';

  @override
  String get shopBuyEmojiTitle => 'Kjøpe emoji?';

  @override
  String get shopBuyCollectionTitle => 'Kjøpe samling?';

  @override
  String shopPrice(String price) {
    return 'Pris: $price';
  }

  @override
  String get shopOwned => 'Kjøpt';

  @override
  String get shopHave => 'Har';

  @override
  String get shopEmpty => 'Tomt foreløpig';

  @override
  String shopPurchased(String title) {
    return '$title kjøpt';
  }

  @override
  String get shopEmojiUses => 'Du får: 10 bruk';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 bruk';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 bruk';
  }

  @override
  String get shopBuyTen => 'Kjøp · 10 stk';

  @override
  String shopDailyIncome(String amount) {
    return 'Inntekt: $amount';
  }

  @override
  String get shopBuyOnce => 'Engangskjøp';

  @override
  String get shopSellRefund => 'Salget avhenger av samlingens tilstand';

  @override
  String get shopCollectionConditionInfo => 'Tilstanden avhenger av hvor lenge du har hatt samlingen. Ny — de første 7 dagene, salg 80 %. Slitt — fra dag 8 til 2 måneder, salg 60 %. Trett — fra 2 til 6 måneder, salg 40 %. Falleferdig — fra 6 måneder til 1 år, salg 100 %. Vintage — fra 1 år, salg 300 %.';

  @override
  String get collectionConditionNew => 'Ny';

  @override
  String get collectionConditionWorn => 'Slitt';

  @override
  String get collectionConditionTired => 'Trett';

  @override
  String get collectionConditionShabby => 'Falleferdig';

  @override
  String get collectionConditionVintage => 'Vintage';

  @override
  String collectionConditionSell(int percent) {
    return 'Salg $percent%';
  }

  @override
  String shopCollectionAdded(String title) {
    return '$title lagt til i profilen';
  }

  @override
  String shopSetBonus(int percent) {
    return 'settbonus +$percent%';
  }

  @override
  String get shopSetComplete => 'Fullført';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Samlet · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Selge?';

  @override
  String inventorySellDesc(String amount) {
    return 'Du får $amount';
  }

  @override
  String inventorySold(String amount) {
    return 'Solgt: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Legg til venner først';

  @override
  String get inventoryGiftTitle => 'Gi samling i gave?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'Gi «$title» til $name?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Gitt: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'Spilleren eier allerede denne gjenstanden';

  @override
  String get inventoryGiftSelf => 'Du kan ikke gi deg selv en gave';

  @override
  String get inventoryGiftNotOwned => 'Denne gjenstanden er ikke i inventaret ditt';

  @override
  String get inventoryLoadFailed => 'Kunne ikke laste gjenstander';

  @override
  String get inventoryNoCollections => 'Ingen samlinger — kjøp i butikken';

  @override
  String get inventoryNoEmojis => 'Ingen emojier — kjøp i butikken';

  @override
  String get inventoryNoFrames => 'Ingen rammer — vinn 10 ligakamper (prestasjoner)';

  @override
  String get inventoryNoStakes => 'Ingen kjøpte innsatser';

  @override
  String inventoryEmojiLeft(int count) {
    return '$count igjen';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Inntekt: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Inntekt i morgen: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Klar';

  @override
  String get inventoryIncomeTomorrowLabel => 'I morgen';

  @override
  String inventoryStakeGold(String amount) {
    return 'Du kan satse $amount gull';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'Du kan satse $amount sølv';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'Hentet +$amount';
  }

  @override
  String get chatsLoadFailed => 'Kunne ikke laste chatter';

  @override
  String get chatsLoadListFailed => 'Kunne ikke laste listen';

  @override
  String get chatsBlockedEmpty => 'Listen er tom';

  @override
  String chatsBlockedAt(String date) {
    return 'Blokkert: $date';
  }

  @override
  String get chatsCreateFailed => 'Kunne ikke opprette chat';

  @override
  String get chatsNeedFriendsFirst => 'Legg til venner først, deretter kan du åpne en chat.';

  @override
  String get chatsFriendsNotFound => 'Fant ingen venner';

  @override
  String get chatsFindFriendHint => 'Finn venn etter kallenavn';

  @override
  String get chatsSelectChat => 'Velg en chat';

  @override
  String get chatsSelectHint => 'Velg en samtale fra listen til venstre';

  @override
  String get chatEditFailed => 'Kunne ikke redigere meldingen';

  @override
  String get chatSendFailed => 'Kunne ikke sende meldingen';

  @override
  String get chatDeleteFailed => 'Kunne ikke slette meldingen';

  @override
  String get chatEmojiSendFailed => 'Kunne ikke sende emoji';

  @override
  String get chatLoadFailed => 'Kunne ikke laste meldinger';

  @override
  String get chatBackToGame => 'Tilbake til spillet';

  @override
  String get chatBackToChats => 'Tilbake til chatter';

  @override
  String get chatActions => 'Chathandlinger';

  @override
  String get chatAutoTranslate => 'Auto-translate';

  @override
  String get chatScrollToEnd => 'Til slutten av samtalen';

  @override
  String chatReplyingTo(String name) {
    return 'Svar til $name';
  }

  @override
  String get chatGift => 'Gave';

  @override
  String get chatCollection => 'Samling';

  @override
  String get chatGiftCollection => 'Gave · samling';

  @override
  String get chatThisUser => 'denne brukeren';

  @override
  String get gamesLobbyLoadFailed => 'Kunne ikke laste lobbyen.';

  @override
  String get gamesTapChangeStake => 'Trykk for å endre innsats';

  @override
  String get gamesTapChangeTurnTime => 'Trykk for å endre tid per trekk';

  @override
  String get gamesTapChangeGrid => 'Trykk for å endre rutenettstørrelse';

  @override
  String get gamesSwapSidesHint => 'O kan bli X etter 1. trekk';

  @override
  String get gamesNoCenterHint => 'Første trekk kan ikke være i midten';

  @override
  String get lobbyInviteSentShort => 'Sendt';

  @override
  String get lobbySearchShort => 'Søk';

  @override
  String get lobbySearchPlayers => 'Finn spillere';

  @override
  String get lobbyInviteDeclinedShort => 'Avslått';

  @override
  String get lobbyInvitesSentWaiting => 'Invitasjoner sendt. Venter på svar.';

  @override
  String get lobbyLinkCopiedHint => 'Lim den inn i en chat eller melding til en venn';

  @override
  String get lobbyCopyLinkHint => 'Kopier lenke til utklippstavlen';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name inviterer deg til å spille';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name vant';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Tiden er ute. $name vant';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String get adminTitle => 'Admin';

  @override
  String get tournamentsTitle => 'Turneringer';

  @override
  String get profileAgeInvalid => 'Skriv inn alder fra 1 til 111';

  @override
  String get profileSaveFailed => 'Kunne ikke lagre profilen';

  @override
  String get profileNameHint => 'Latinske bokstaver, sifre, _ opptil 10 tegn';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'Fra 1 til 111';

  @override
  String get profileAboutHint => 'Opptil 100 tegn (valgfritt)';

  @override
  String get profileProcessingPhoto => 'Behandler bilde…';

  @override
  String get profileCropTitle => 'Velg avatarområde';

  @override
  String get profileCropHint => 'Zoom og flytt bildet';

  @override
  String get profileApply => 'Bruk';

  @override
  String get profilePreparing => 'Forbereder…';

  @override
  String get profileGalleryTitle => 'Bilder';

  @override
  String get profileGalleryAdd => 'Legg til bilde';

  @override
  String get profileMakePrimary => 'Gjør til primær';

  @override
  String get profilePhotoDelete => 'Slett bilde';

  @override
  String get profilePhotosLimit => 'Du kan laste opp opptil 3 bilder';

  @override
  String get profilePhotosEmpty => 'Ingen bilder ennå';

  @override
  String get profilePhotoUploadFailed => 'Kunne ikke laste opp bildet';

  @override
  String get profilePhotoDeleteFailed => 'Kunne ikke slette bildet';

  @override
  String get profilePhotoTooLarge => 'Bildet er for stort';

  @override
  String get profileSetPrimaryFailed => 'Kunne ikke angi som primær';

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
    return 'Tripp-trapp-tresko på $grid-brett. På tur; X starter.';
  }

  @override
  String rulesWin(int n) {
    return 'Seier: få $n på rad horisontalt, vertikalt eller diagonalt.';
  }

  @override
  String get rulesNoTimeLimit => 'Ingen tidsgrense per trekk.';

  @override
  String rulesTurnTime(String time) {
    return 'Tid per trekk: $time. Tiden ute er tap.';
  }

  @override
  String rulesStake(String stake) {
    return 'Innsats: $stake. Spillet gjelder så mange mynter.';
  }

  @override
  String get rulesSwap => 'Sidebytte: O kan bytte med X etter X sitt første trekk.';

  @override
  String get rulesNoCenter => 'Ikke midten: X kan ikke spille i midten på første trekk.';

  @override
  String get collectionSetLegends => 'Legender';

  @override
  String get collectionSetSpace => 'Rommet';

  @override
  String get collectionSetGems => 'Edelstener';

  @override
  String get collectionSetParty => 'Fest';

  @override
  String get collectionSetNature => 'Natur';

  @override
  String get collectionSetAdventures => 'Eventyr';

  @override
  String collectionCardMeta(String amount) {
    return 'Samling · utstilling · gave · salg · +$amount';
  }

  @override
  String get coinsDayOne => 'dag';

  @override
  String get coinsDayFew => 'dager';

  @override
  String get coinsDayMany => 'dager';

  @override
  String get giftFriendTitle => 'Gi til en venn';

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
    return '$count emojier · $price';
  }

  @override
  String get chatsExpandPanel => 'Utvid panel';

  @override
  String get chatsCollapsePanel => 'Skjul panel';

  @override
  String get chatReplySourceMissing => 'Opprinnelig melding ikke funnet';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Innsats $n sølv';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Innsats $n gull';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Låser opp innsats på $n sølv';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Låser opp innsats på $n gull';
  }

  @override
  String get chatReplySelf => 'deg selv';

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
  String get statsTitle => 'Statistikk';

  @override
  String get statsLoadFailed => 'Kunne ikke laste statistikk';

  @override
  String get statsAllGames => 'Alle spill';

  @override
  String get statsEmptyTitle => 'Ingen spill spilt ennå';

  @override
  String get statsEmptyHint => 'Spill ditt første spill for å se statistikk her.';

  @override
  String get statsWins => 'Seire';

  @override
  String get statsDraws => 'Uavgjort';

  @override
  String get statsLosses => 'Tap';

  @override
  String get statsWinRate => 'Seiersprosent';

  @override
  String get statsTopWon => 'Flest seire mot';

  @override
  String get statsTopDrawn => 'Flest uavgjort med';

  @override
  String get statsTopLost => 'Flest tap mot';

  @override
  String get statsTimePlayed => 'Spilletid';

  @override
  String get statsYourScore => 'Din stilling';

  @override
  String get profileShowStats => 'Vis statistikk';

  @override
  String get statsDurationZeroMinutes => '0 min';

  @override
  String get gameYouWonOpponentForfeit => 'Motstanderen ga opp. Du vant!';

  @override
  String get lobbyLeaveTitle => 'Forlate lobby?';

  @override
  String get lobbyLeaveConfirm => 'Lobbyen slettes når du går. Inviterte venner får et avslag.';

  @override
  String get lobbyLeave => 'Forlat';

  @override
  String statsDurationHours(int hours) {
    return '$hours t';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours t $minutes min';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'Du ga opp. $name vant';
  }

  @override
  String get supportTitle => 'Support';

  @override
  String get supportUnavailable => 'Support er utilgjengelig';

  @override
  String get supportOpenFailed => 'Kunne ikke åpne supportchat';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Du har fått $amount mynter';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return '$amount mynter ble trukket';
  }

  @override
  String get coinsCreditCardTitle => 'Du har fått mynter';

  @override
  String get coinsClaim => 'Hent';

  @override
  String get durakActionPass => 'Pass';

  @override
  String get durakRoleTook => 'Tar';

  @override
  String get durakRoleBeats => 'Slår';

  @override
  String get durakRoleThrowIn => 'Pålegg';

  @override
  String get durakRoleTurn => 'Tur';

  @override
  String get durakRoleDefends => 'Forsvarer';

  @override
  String get durakStatusTaking => 'Tar';

  @override
  String get durakHintDefenderTurn => 'Forsvarerens tur';

  @override
  String get gameYouEliminated => 'Du er ute';

  @override
  String gameYouPlaced(int place) {
    return 'Du ble nr. $place';
  }

  @override
  String get gameOverNeutral => 'Spillet er over';

  @override
  String gameTurnOf(String name) {
    return '${name}s tur';
  }

  @override
  String get chatGroupTooltip => 'Gruppechat';

  @override
  String get lobbyChatNotReady => 'Lobbychatten er ikke klar ennå';

  @override
  String get chatsGroupChat => 'Gruppechat';

  @override
  String chatsMembersCount(int count) {
    return 'Medlemmer: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count pers.';
  }

  @override
  String get chatsYouSuffix => '(deg)';

  @override
  String get chatTitleDurak3 => 'Durak · 3 spillere';

  @override
  String get chatTitleDurak4 => 'Durak · 4 spillere';

  @override
  String get rulesTttUltimate => 'Ultimate: ni 3×3-minibrett. Et trekk sender motstanderen til det minibrettet. Vinn med en linje på metabbrettet.';

  @override
  String get rulesTttMulti3 => '3 spillere: 3×3-brett, tre spillere (X, O, △). Lag en linje med dine tegn for å vinne.';

  @override
  String get rulesTttMulti4 => '4 spillere: 4×4-brett, fire spillere (X, O, △, □). Lag en linje med dine tegn for å vinne.';

  @override
  String get adminUsersTab => 'Brukere';

  @override
  String get adminSupportTab => 'Støtte';

  @override
  String get adminSearchHint => 'Søk på e-post eller navn';

  @override
  String get adminRoleAdmins => 'Admins';

  @override
  String get adminRoleUsers => 'Brukere';

  @override
  String get adminRoleAll => 'Alle roller';

  @override
  String get adminStatusFrozen => 'Frosset';

  @override
  String get adminStatusActive => 'Aktive';

  @override
  String get adminStatusAny => 'Alle statuser';

  @override
  String get adminOrderDesc => 'Synkende';

  @override
  String get adminOrderAsc => 'Stigende';

  @override
  String adminLoadFailed(String error) {
    return 'Kunne ikke laste: $error';
  }

  @override
  String get adminUsersEmpty => 'Ingen brukere';

  @override
  String get adminSortLastSeen => 'Etter siste besøk';

  @override
  String get adminSortEmail => 'Etter e-post';

  @override
  String get adminSortCreated => 'Etter registrering';

  @override
  String adminBronzeBalance(int amount) {
    return '$amount br.';
  }

  @override
  String get adminRevokeAdmin => 'Fjern admin';

  @override
  String get adminGrantAdmin => 'Gjør til admin';

  @override
  String get adminAdminRevoked => 'Adminrettigheter fjernet';

  @override
  String get adminAdminGranted => 'Adminrettigheter gitt';

  @override
  String get adminGrantCoins => 'Gi mynter';

  @override
  String get adminWriteSupport => 'Skriv som støtte';

  @override
  String get adminUnfreeze => 'Tin';

  @override
  String get adminFreeze => 'Frys';

  @override
  String get adminUnfrozen => 'Tint';

  @override
  String get adminFrozenDone => 'Frosset';

  @override
  String get adminResetPassword => 'Tilbakestill passord';

  @override
  String get adminCoinsAmountHint => 'Antall (negativt = trekk fra)';

  @override
  String get adminReasonOptional => 'Grunn (valgfritt)';

  @override
  String get adminGrantSent => 'Kortet ble sendt til støttechatten';

  @override
  String adminCoinsDebited(int amount) {
    return 'Trakk $amount bronse';
  }

  @override
  String get adminGrantVerb => 'Gi';

  @override
  String get adminNewPasswordHint => 'Nytt passord (minst 6)';

  @override
  String get adminPasswordReset => 'Passordet er tilbakestilt';

  @override
  String get adminResetVerb => 'Tilbakestill';

  @override
  String adminShortError(String error) {
    return 'Feil: $error';
  }

  @override
  String get adminSupportEmpty => 'Ingen støttehenvendelser';

  @override
  String get adminUserFallback => 'Bruker';

  @override
  String get apiErrTooManyRequests => 'For mange forespørsler. Prøv igjen senere.';

  @override
  String get apiErrMoveConflict => 'Trekkkonflikt. Prøv igjen.';
}
