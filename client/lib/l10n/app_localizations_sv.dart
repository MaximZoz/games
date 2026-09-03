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
  String get settingsSoundTitle => 'Ljud';

  @override
  String get settingsSoundSubtitle => 'Spel och aviseringar';

  @override
  String get settingsSoundGames => 'Spel';

  @override
  String get settingsSoundNotifications => 'Aviseringar';

  @override
  String get settingsSoundTurn => 'Tur';

  @override
  String get settingsHapticsTitle => 'Vibration';

  @override
  String get settingsHapticsSubtitle => 'Endast aviseringar: meddelanden, förfrågningar, din tur och timern';

  @override
  String get settingsOfflineModeTitle => 'Nätverksläge';

  @override
  String get settingsOfflineModeSubtitle => 'Offline: spela genast mot en bot, utan insatser och belöningar, utan chattar och vänner. Köp sparas och tillämpas i online-läge. Online — när det finns internet eller enligt användarinställningen.';

  @override
  String get settingsModeOnline => 'Online';

  @override
  String get settingsModeOffline => 'Offline';

  @override
  String get gamesAlternateStartsHint => 'Turordning för vem som börjar partiet';

  @override
  String get rulesAlternateStarts => 'Vem som börjar växlar från parti till parti.';

  @override
  String get offlineBadgeTooltip => 'Offline-läge';

  @override
  String get offlineModePopupTitle => 'Offline-läge';

  @override
  String get offlineModePopupBody => 'Offline-läge är på. Spela mot en bot utan insatser och belöningar. Chattar, vänner och lobby är dolda. Köp tillämpas i online-läge.';

  @override
  String get offlineModePopupSettings => 'Inställningar';

  @override
  String get gamesPlay => 'Spela';

  @override
  String get offlineGameTitle => 'Spel mot bot';

  @override
  String get offlineGameHint => 'Utan insatser och belöningar · endast offline';

  @override
  String get offlineBotWon => 'Boten vann';

  @override
  String get offlineBotThinking => 'Boten tänker…';

  @override
  String get offlinePlayAgain => 'Igen';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'Ta';

  @override
  String get durakActionAll => 'Alla';

  @override
  String get durakActionDone => 'Klart';

  @override
  String get durakActionBito => 'Beat';

  @override
  String get durakHintDefend => 'Försvara';

  @override
  String get durakHintDefendOrTransfer => 'Försvara eller överför';

  @override
  String get durakHintOpponentDefends => 'Motståndaren försvarar';

  @override
  String get durakHintThrowInFirst => 'Lägg kort (max 5 i första slaget)';

  @override
  String get durakHintThrowIn => 'Lägg kort eller vänta på försvaret';

  @override
  String get durakHintOpponentThrows => 'Motståndaren lägger på';

  @override
  String get durakHintTakeFollow => 'Lägg på efter ta eller tryck «Klart»';

  @override
  String get durakHintOpponentTakeFollow => 'Motståndaren kan lägga på efter ta';

  @override
  String get durakHintBito => 'Lägg ett kort eller säg «Bito»';

  @override
  String get durakHintOpponentBito => 'Motståndaren lägger på eller säger «Bito»';

  @override
  String get durakHintYourAttack => 'Din tur — attackera';

  @override
  String get durakHintOpponentAttack => 'Motståndaren attackerar';

  @override
  String get durakHintYouLost => 'Du förlorade — du är dåren';

  @override
  String get durakHintDrawAllOut => 'Oavgjort — alla är ute';

  @override
  String get durakHintYouFinished => 'Du är ute — väntar på slutet';

  @override
  String get durakFirstLeadYou => 'Du går först';

  @override
  String get durakFirstLeadOpponent => 'Motståndaren går först';

  @override
  String get durakFirstLeadBot => 'Botten går först';

  @override
  String durakFirstLeadOf(String name) {
    return '$name går först';
  }

  @override
  String get durakFirstLeadReason => 'Lägsta trumf';

  @override
  String get shopPurchaseQueued => 'Köp sparat — tillämpas i online-läge';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — köp tillämpat';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — köp inte tillämpat: $reason';
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
  String settingsAppVersion(String version) {
    return 'Version $version';
  }

  @override
  String get appUpdateTitle => 'Uppdatering tillgänglig';

  @override
  String get appUpdateBody => 'En ny version av appen finns. Uppdatera för att fortsätta.';

  @override
  String get appUpdateWhatsNew => 'Nyheter';

  @override
  String get appUpdateOk => 'Uppdatera';

  @override
  String get appUpdateLaterBanner => 'Vi uppdaterar appen efter detta spel';

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
  String get apiErrWrongGameType => 'Fel speltyp';

  @override
  String get apiErrWrongGameTypeOrState => 'Fel speltyp eller status';

  @override
  String get apiErrLobbyFull => 'Lobryn är full';

  @override
  String get apiErrBadState => 'Ogiltigt spelläge';

  @override
  String get apiErrIllegalMove => 'Otillåtet drag';

  @override
  String get apiErrUnknownMoveType => 'Okänd dragtyp';

  @override
  String get apiErrNoOpponents => 'Inga motståndare';

  @override
  String get apiErrNoOpponentsRematch => 'Inga motståndare för returmatch';

  @override
  String get apiErrAlreadyInLobby => 'Du är redan i den här lobbyn';

  @override
  String get apiErrGameNotActive => 'Spelet är inte aktivt';

  @override
  String get apiErrNotInBattle => 'Inte i stridsfasen';

  @override
  String get apiErrNotInSetup => 'Inte i uppställningsfasen';

  @override
  String get apiErrAlreadyReady => 'Du är redan redo';

  @override
  String get apiErrAlreadyForfeited => 'Du har redan gett upp';

  @override
  String get apiErrYouHaveForfeited => 'Du har gett upp';

  @override
  String get apiErrNoDrawOffer => 'Inget oavgjort-erbjudande';

  @override
  String get apiErrDrawOnlyPvp => 'Oavgjort bara mot en spelare';

  @override
  String get apiErrDrawOnly1v1 => 'Oavgjort bara i 1 mot 1';

  @override
  String get apiErrDrawVsBot => 'Oavgjort är inte tillgängligt mot en bot';

  @override
  String get apiErrDrawMultiplayer => 'Oavgjort är inte tillgängligt i flerspelarläge';

  @override
  String get apiErrDeck24TwoPlayers => 'Kortlek med 24 kort är bara för 2 spelare';

  @override
  String get apiErrDeck52ThreeOrFour => 'Kortlek med 52 kort kräver 3 eller 4 spelare';

  @override
  String get apiErrAccountFrozen => 'Kontot är fryst';

  @override
  String get apiErrTurnTimeInvalid => 'Dragetiden måste vara 0, 20, 60 eller 600 sekunder';

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
  String get gamesDurak => 'Durak';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => 'Rotera';

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
  String get gamesNardyModeLong => 'Lång';

  @override
  String get rulesNardyTitle => 'Backgammon — regler';

  @override
  String get rulesNardyPlayers => 'Spelare: 2.';

  @override
  String rulesNardyMode(String mode) {
    return 'Läge: $mode.';
  }

  @override
  String get rulesNardyIntro => 'Bräde med 24 punkter, 15 brickor var. Två tärningar: en bricka summan eller två brickor ögonen.';

  @override
  String get rulesNardyPlayShort => 'Kort backgammon: ni går mot varandra och får slå ensamma brickor. En slagen bricka hamnar på barren och måste in igen. När alla är i hemmet bär ni av dem.';

  @override
  String get rulesNardyPlayLong => 'Långt backgammon: båda startar från samma huvud och går åt samma håll. Högst en bricka lämnar huvudet per drag. Slag är inte tillåtet. När alla är i hemmet bär ni av dem.';

  @override
  String get rulesNardyWin => 'Den som först bär av alla brickor vinner.';

  @override
  String get nardyRoll => 'Slå';

  @override
  String get nardySkipTurn => 'Hoppa över turen';

  @override
  String get nardyUndoMove => 'Ångra';

  @override
  String get nardyDoneTurn => 'Klar';

  @override
  String get nardyNoMoves => 'Inga drag — hoppa över turen';

  @override
  String get nardyYourRoll => 'Ditt slag';

  @override
  String get nardyPipsShort => 'Kvar:';

  @override
  String get nardyYouWonMars => 'Du vann — gammon!';

  @override
  String get nardyYouLostMars => 'Förlust — gammon';

  @override
  String get rulesNardyOfflineBot => 'Offline: parti mot boten.';

  @override
  String rulesUnoPlayers(int players) {
    return 'Spelare: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'Spela mot en bot utan tidsgräns per drag.';

  @override
  String get rulesUnoIntro => 'Varje spelare får 7 kort. Spela ett kort i samma färg eller samma rang (siffra eller samma åtgärd).';

  @override
  String get rulesUnoPlay => 'Hoppa över — nästa mister turen. Vänd med två spelare fungerar som hoppa över. +2 staplas bara på +2 och +4 bara på +4: straffet adderas (två +2 gör att nästa drar 4). +2 får inte läggas på +4. Den som inte staplar drar hela högen och mister turen. Två identiska icke-svarta kort (t.ex. två gula 8) slängs tillsammans: spela ett så följer tvillingen med automatiskt.';

  @override
  String get rulesUnoWild => 'Ett svart kort sätter en ny färg. Spela +4 bara om du saknar kort i aktuell färg. Motståndaren kan utmana: var +4 lagligt drar hen 6; annars drar +4-spelaren 4 och utmanaren spelar.';

  @override
  String get rulesUnoDraw => 'Utan lagligt kort, dra ett från högen. Passar det kan du spela det direkt eller behålla det och passa. Du får inte dra medan du har ett lagligt drag.';

  @override
  String get rulesUnoWin => 'Två spelare till 100, 3+ till 200. En rond vinns genom att tömma handen.';

  @override
  String get rulesUnoCall => 'När ett kort återstår, tryck genast på ”Uno!”. Motståndare kan ta dig för glömt Uno först efter en sekund — då drar du 2 kort.';

  @override
  String get rulesUnoScoring => 'Den som först töms på kort vinner ronden och får poäng för motståndarnas händer: siffror efter värde, action 20, svarta 50. Två spelare till 100, 3+ till 200.';

  @override
  String get unoColorRed => 'Röd';

  @override
  String get unoColorYellow => 'Gul';

  @override
  String get unoColorGreen => 'Grön';

  @override
  String get unoColorBlue => 'Blå';

  @override
  String get unoDraw => 'Dra';

  @override
  String get unoKeep => 'Behåll';

  @override
  String get unoSayUno => 'Uno!';

  @override
  String get unoChallengeUno => 'Utmana Uno';

  @override
  String get unoChallengeWd4 => 'Utmana +4';

  @override
  String get unoChooseColor => 'Välj en färg';

  @override
  String get unoDrawPile => 'Draghög';

  @override
  String get unoDiscardPile => 'Kasthög';

  @override
  String unoCardsCount(int count) {
    return 'Kort: $count';
  }

  @override
  String unoScore(int score) {
    return 'Poäng: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'Runda $round · till $target';
  }

  @override
  String get unoYourTurn => 'Din tur';

  @override
  String get unoWaitingTurn => 'Motståndarens tur';

  @override
  String get unoChooseColorHint => 'Välj en färg för jokern';

  @override
  String get unoWd4Hint => 'Dra 4 kort eller utmana Wild +4';

  @override
  String get unoDrawnHint => 'Spela det dragna kortet eller behåll det';

  @override
  String get unoPlayHint => 'Spela matchande färg eller värde';

  @override
  String get unoDrawHint => 'Inget matchande kort — dra från högen';

  @override
  String unoPendingDraw(int count) {
    return '+$count kort';
  }

  @override
  String get unoYouWon => 'Du vann matchen!';

  @override
  String get unoYouLost => 'Matchen är slut';

  @override
  String get unoYouLostTimeout => 'Du förlorade på tid';

  @override
  String unoWinner(String name) {
    return 'Vinnare: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name vinner ronden';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'Nästa';

  @override
  String get unoRoundScoresTitle => 'Rondpoäng';

  @override
  String get unoDirectionClockwise => 'Medurs';

  @override
  String get unoDirectionCounterclockwise => 'Moturs';

  @override
  String get unoErrStackSameOnly => 'På +2 får bara +2 läggas, på +4 bara +4. +2 på +4 är inte tillåtet.';

  @override
  String get unoErrCatchTooEarly => 'Vänta en sekund — de kan fortfarande säga Uno.';

  @override
  String get unoErrCallTooLate => 'Du kan inte längre säga Uno. Nästa spelare har redan spelat.';

  @override
  String get gamesInDevelopment => 'Under utveckling';

  @override
  String rulesPokerPlayers(int players) {
    return 'Spelare: $players.';
  }

  @override
  String get rulesPokerIntro => 'Texas Hold’em. Varje spelare får 2 hålkort; 5 gemensamma kort läggs på bordet.';

  @override
  String get rulesPokerPlay => 'Insatserundor: preflop, flop, turn och river. Fold, call, bet eller raise.';

  @override
  String get rulesPokerWin => 'Bästa femkorts-handen (hål + gemensamma) vinner, eller den siste efter folds.';

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
  String get gamesObservation => 'Tittar';

  @override
  String get gamesObservationHint => 'Du kan titta tills spelet slutar';

  @override
  String get gamesFinishCurrentFirst => 'Slutför ditt nuvarande spel först';

  @override
  String get gamesVariantClassic => 'Klassisk';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 spelare';

  @override
  String get gamesVariantMulti4 => '4 spelare';

  @override
  String get gamesDurakModePodkidnoi => 'Pålägg';

  @override
  String get gamesDurakModePerevodnoi => 'Överföring';

  @override
  String get gamesDurakDeck24 => '24 kort';

  @override
  String get gamesDurakDeck36 => '36 kort';

  @override
  String get gamesDurakDeck52 => '52 kort';

  @override
  String rulesDurakMode(String mode) {
    return 'Läge: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'Spelare: $players. Kortlek: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Spela mot en bot, utan insatser eller tid.';

  @override
  String get rulesDurakAttack => 'Anfallaren lägger kort; försvararen slår dem (samma färg högre, eller trumf). Trumf slås bara av högre trumf.';

  @override
  String get rulesDurakBeat => 'När alla kort är slagna säger anfallaren «Bito» och korten går till högen. Annars tar försvararen allt från bordet.';

  @override
  String get rulesDurakLoser => 'Förloraren är den som har kort kvar i slutet — «dåren».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Spelare $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Lobby $name';
  }

  @override
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Privat spel';

  @override
  String get lobbySearchingOpponent => 'Söker motståndare…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Söker detta spel: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Väntar på att någon trycker på ”Hitta ett spel” eller ”Gå med”';

  @override
  String get lobbyInviteTitle => 'Spelinbjudan';

  @override
  String get lobbyInvitedToPlay => 'Du har blivit inbjuden att spela';

  @override
  String get lobbyEnterGame => 'Gå in i spelet';

  @override
  String get lobbyGone => 'Lobbyn är inte längre tillgänglig';

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
  String get gameYouLost => 'Du förlorade';

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
  String get gameSurrender => 'Ge upp';

  @override
  String get gameSurrenderTitle => 'Ge upp?';

  @override
  String get gameSurrenderConfirm => 'Du förlorar partiet och insatsmynten.';

  @override
  String get gameOfferDraw => 'Erbjud remi';

  @override
  String get gameOfferDrawTitle => 'Erbjud remi?';

  @override
  String get gameOfferDrawConfirm => 'Din motståndare kan acceptera eller avvisa remi.';

  @override
  String get gameAcceptDrawTitle => 'Acceptera remi?';

  @override
  String get gameAcceptDrawConfirm => 'Partiet slutar oavgjort.';

  @override
  String get gameDrawOffered => 'Motståndaren erbjuder remi';

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
  String get chatPaste => 'Klistra in';

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
  String get friendsSearchNoMatches => 'Inga vänner matchar sökningen';

  @override
  String get friendsIncomingSearchNoMatches => 'Inga inkommande förfrågningar matchar sökningen';

  @override
  String get friendsOutgoingSearchNoMatches => 'Inga utgående förfrågningar matchar sökningen';

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
  String get profileChangePhoto => 'Byt avatar';

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
  String get inventoryGiftAlreadyOwns => 'Spelaren äger redan detta föremål';

  @override
  String get inventoryGiftSelf => 'Du kan inte ge dig själv en present';

  @override
  String get inventoryGiftNotOwned => 'Det här föremålet finns inte i din inventarie';

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
  String get inventoryIncomeReadyLabel => 'Klar';

  @override
  String get inventoryIncomeTomorrowLabel => 'Imorgon';

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
  String get chatAutoTranslate => 'Auto-translate';

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
  String get profileGalleryTitle => 'Foton';

  @override
  String get profileGalleryAdd => 'Lägg till foto';

  @override
  String get profileMakePrimary => 'Gör till primär';

  @override
  String get profilePhotoDelete => 'Ta bort foto';

  @override
  String get profilePhotosLimit => 'Du kan ladda upp högst 3 foton';

  @override
  String get profilePhotosEmpty => 'Inga foton ännu';

  @override
  String get profilePhotoUploadFailed => 'Kunde inte ladda upp fotot';

  @override
  String get profilePhotoDeleteFailed => 'Kunde inte ta bort fotot';

  @override
  String get profilePhotoTooLarge => 'Fotot är för stort';

  @override
  String get profileSetPrimaryFailed => 'Kunde inte ange som primär';

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
    return 'Tid per drag: $time. Tidsgränsen innebär förlust.';
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

  @override
  String get supportTitle => 'Support';

  @override
  String get supportUnavailable => 'Support är inte tillgängligt';

  @override
  String get supportOpenFailed => 'Kunde inte öppna supportchatten';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Du har fått $amount mynt';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return '$amount mynt drogs av';
  }

  @override
  String get coinsCreditCardTitle => 'Du har fått mynt';

  @override
  String get coinsClaim => 'Hämta';

  @override
  String get durakActionPass => 'Passa';

  @override
  String get durakRoleTook => 'Tar';

  @override
  String get durakRoleBeats => 'Slår';

  @override
  String get durakRoleThrowIn => 'Pålägg';

  @override
  String get durakRoleTurn => 'Tur';

  @override
  String get durakRoleDefends => 'Försvarar';

  @override
  String get durakStatusTaking => 'Tar';

  @override
  String get durakHintDefenderTurn => 'Försvararens tur';

  @override
  String get gameYouEliminated => 'Du är ute';

  @override
  String gameYouPlaced(int place) {
    return 'Du kom $place:a';
  }

  @override
  String get gameOverNeutral => 'Matchen är slut';

  @override
  String gameTurnOf(String name) {
    return '${name}s tur';
  }

  @override
  String get chatGroupTooltip => 'Gruppchatt';

  @override
  String get lobbyChatNotReady => 'Lobbychatten är inte redo än';

  @override
  String get chatsGroupChat => 'Gruppchatt';

  @override
  String chatsMembersCount(int count) {
    return 'Medlemmar: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count pers.';
  }

  @override
  String get chatsYouSuffix => '(du)';

  @override
  String get chatTitleDurak3 => 'Durak · 3 spelare';

  @override
  String get chatTitleDurak4 => 'Durak · 4 spelare';

  @override
  String get rulesTttUltimate => 'Ultimate: nio 3×3-minibräden. Ett drag skickar motståndaren till det minibrädet. Vinn med en linje på metabrädet.';

  @override
  String get rulesTttMulti3 => '3 spelare: 3×3-bräde, tre spelare (X, O, △). Gör en linje med dina tecken för att vinna.';

  @override
  String get rulesTttMulti4 => '4 spelare: 4×4-bräde, fyra spelare (X, O, △, □). Gör en linje med dina tecken för att vinna.';
}
