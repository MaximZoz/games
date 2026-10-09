import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Domů';

  @override
  String get navProfile => 'Profil';

  @override
  String get navFriends => 'Přátelé';

  @override
  String get navChats => 'Chaty';

  @override
  String get navGames => 'Hry';

  @override
  String get navSettings => 'Nastavení';

  @override
  String get settingsTitle => 'Nastavení';

  @override
  String get settingsLanguage => 'Jazyk';

  @override
  String get settingsLanguageSystem => 'Podle systému';

  @override
  String get settingsSoundTitle => 'Zvuk';

  @override
  String get settingsSoundSubtitle => 'Hry a oznámení';

  @override
  String get settingsSoundGames => 'Hry';

  @override
  String get settingsSoundNotifications => 'Oznámení';

  @override
  String get settingsSoundTurn => 'Tah';

  @override
  String get settingsHapticsTitle => 'Vibrace';

  @override
  String get settingsHapticsSubtitle => 'Pouze upozornění: zprávy, žádosti, váš tah a časovač';

  @override
  String get settingsGamepadTitle => 'Ovladač';

  @override
  String get settingsGamepadSubtitle => 'Gamepad pro menu a partie';

  @override
  String settingsGamepadConnected(String name) {
    return 'Připojeno: $name';
  }

  @override
  String get settingsGamepadDisconnected => 'Gamepad nenalezen. Připojte ovladač a stiskněte libovolné tlačítko.';

  @override
  String get settingsGamepadGenericName => 'Ovladač';

  @override
  String get settingsGamepadHelpNavigate => 'Navigace';

  @override
  String get settingsGamepadHelpConfirm => 'Vybrat';

  @override
  String get settingsGamepadHelpBack => 'Zpět';

  @override
  String get settingsGamepadHelpTabs => 'Karty';

  @override
  String get settingsGamepadHelpPlay => 'Kurzor na desce a v ruce: dáma, piškvorky, lodě, durak, uno, poker a vrhcáby';

  @override
  String get settingsGamepadHelpCards => 'Karty';

  @override
  String get settingsGamepadHelpKeyboard => 'Klávesnice';

  @override
  String get settingsGamepadHelpBalance => 'Zůstatek';

  @override
  String get settingsGamepadHelpLogout => 'Odhlásit';

  @override
  String get settingsGamepadHelpPage => 'Stránka';

  @override
  String get settingsGamepadLayoutXbox => 'Rozložení Xbox';

  @override
  String get settingsGamepadLayoutPlayStation => 'Rozložení PlayStation';

  @override
  String get settingsGamepadLayoutNintendo => 'Rozložení Nintendo';

  @override
  String get gamepadKeyboardTitle => 'Klávesnice';

  @override
  String get gamepadKeyboardSpace => 'Mezera';

  @override
  String get gamepadLegendConfirm => 'Vybrat';

  @override
  String get gamepadLegendBack => 'Zpět';

  @override
  String get gamepadLegendTabs => 'Karty';

  @override
  String get gamepadLegendCycle => 'Změnit';

  @override
  String gamepadConnectedSnack(String name) {
    return 'Ovladač připojen: $name';
  }

  @override
  String get settingsOfflineModeTitle => 'Režim sítě';

  @override
  String get settingsOfflineModeSubtitle => 'Offline: hrajte hned proti botovi, bez sázek a odměn, bez chatů a přátel. Nákupy se uloží a uplatní v online režimu. Online — když je internet nebo podle nastavení uživatele.';

  @override
  String get settingsModeOnline => 'Online';

  @override
  String get settingsModeOffline => 'Offline';

  @override
  String get gamesAlternateStartsHint => 'Střídavě kdo začíná partii';

  @override
  String get rulesAlternateStarts => 'Kdo táhne první se střídá od partie k partii.';

  @override
  String get offlineBadgeTooltip => 'Režim offline';

  @override
  String get offlineModePopupTitle => 'Režim offline';

  @override
  String get offlineModePopupBody => 'Režim offline je zapnutý. Hrajte proti botovi bez sázek a odměn. Chaty, přátelé a lobby jsou skryté. Nákupy se uplatní v online režimu.';

  @override
  String get offlineModePopupSettings => 'Nastavení';

  @override
  String get offlineModeOfferBody => 'Není internet nebo je spojení velmi pomalé. Můžete zapnout režim offline a hrát proti botovi.';

  @override
  String get offlineModeOfferAction => 'Zapnout offline';

  @override
  String get gamesPlay => 'Hrát';

  @override
  String get offlineGameTitle => 'Hra proti botovi';

  @override
  String get offlineGameHint => 'Bez sázek a odměn · pouze offline';

  @override
  String get offlineBotWon => 'Bot vyhrál';

  @override
  String get offlineBotThinking => 'Bot přemýšlí…';

  @override
  String get offlinePlayAgain => 'Znovu';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'Vzít';

  @override
  String get durakActionAll => 'Vše';

  @override
  String get durakActionDone => 'Hotovo';

  @override
  String get durakActionBito => 'Beat';

  @override
  String get durakHintDefend => 'Bránit se';

  @override
  String get durakHintDefendOrTransfer => 'Bránit se nebo převést';

  @override
  String get durakHintOpponentDefends => 'Soupeř se brání';

  @override
  String get durakHintThrowInFirst => 'Přihazujte karty (max. 5 v prvním odbití)';

  @override
  String get durakHintThrowIn => 'Přihazujte karty nebo čekejte na obranu';

  @override
  String get durakHintOpponentThrows => 'Soupeř přihazuje';

  @override
  String get durakHintTakeFollow => 'Přihoďte po vzeti nebo klepněte «Hotovo»';

  @override
  String get durakHintOpponentTakeFollow => 'Soupeř může přihodit po vzeti';

  @override
  String get durakHintBito => 'Přihoďte kartu nebo řekněte «Bito»';

  @override
  String get durakHintOpponentBito => 'Soupeř přihazuje nebo říká «Bito»';

  @override
  String get durakHintYourAttack => 'Vaše tah — útočte';

  @override
  String get durakHintOpponentAttack => 'Soupeř útočí';

  @override
  String get durakHintYouLost => 'Prohráli jste — jste hlupák';

  @override
  String get durakHintDrawAllOut => 'Remíza — všichni jsou venku';

  @override
  String get durakHintYouFinished => 'Jste venku — čekáme na konec';

  @override
  String get durakFirstLeadYou => 'Začínáte vy';

  @override
  String get durakFirstLeadOpponent => 'Začíná soupeř';

  @override
  String get durakFirstLeadBot => 'Začíná bot';

  @override
  String durakFirstLeadOf(String name) {
    return 'Začíná $name';
  }

  @override
  String get durakFirstLeadReason => 'Nejnižší trumf';

  @override
  String get shopPurchaseQueued => 'Nákup uložen — uplatní se v online režimu';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — nákup uplatněn';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — nákup neuplatněn: $reason';
  }

  @override
  String get settingsFriendsOnlyTitle => 'Zprávy jen od přátel';

  @override
  String get settingsFriendsOnlySubtitle => 'Kdo není v přátelích, může posílat jen emoji. Pokud vadí spam, uživatele dočasně zablokujte.';

  @override
  String get settingsNotifications => 'Oznámení';

  @override
  String get settingsPushChat => 'Chat';

  @override
  String get settingsPushFriends => 'Přátelé';

  @override
  String get settingsPushGames => 'Hry';

  @override
  String get settingsPushRewards => 'Odměny';

  @override
  String settingsAppVersion(String version) {
    return 'Verze $version';
  }

  @override
  String get appUpdateTitle => 'Dostupná aktualizace';

  @override
  String get appUpdateBody => 'Je k dispozici nová verze aplikace. Aktualizujte pro pokračování.';

  @override
  String get appUpdateWhatsNew => 'Co je nového';

  @override
  String get appUpdateOk => 'Aktualizovat';

  @override
  String get appUpdateLaterBanner => 'Po partii aplikaci aktualizujeme';

  @override
  String get loginTitle => 'Přihlášení';

  @override
  String get loginSubtitle => 'Zadejte email nebo uživatelské jméno a heslo';

  @override
  String get loginEmailLabel => 'Email nebo uživatelské jméno';

  @override
  String get loginPasswordLabel => 'Heslo';

  @override
  String get loginSubmit => 'Přihlásit se';

  @override
  String get loginNoAccount => 'Nemáte účet? Zaregistrujte se';

  @override
  String get loginEmailRequired => 'Zadejte email nebo uživatelské jméno';

  @override
  String get loginPasswordRequired => 'Zadejte heslo';

  @override
  String get loginTooltip => 'Přihlásit se';

  @override
  String get logoutTooltip => 'Odhlásit se';

  @override
  String get registerTitle => 'Registrace';

  @override
  String get registerSubtitle => 'Vytvořte si účet a hrajte';

  @override
  String get registerNameLabel => 'Jméno (uživatelské jméno)';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'Heslo';

  @override
  String get registerSubmit => 'Zaregistrovat se';

  @override
  String get registerHaveAccount => 'Už máte účet? Přihlaste se';

  @override
  String get registerNameRequired => 'Zadejte jméno';

  @override
  String get registerNameNoSpaces => 'Jméno nesmí obsahovat mezery';

  @override
  String get registerNameMax => 'Maximálně 20 znaků';

  @override
  String get registerNameHint => 'Až 20 znaků';

  @override
  String get registerEmailRequired => 'Zadejte email';

  @override
  String get registerEmailInvalid => 'Neplatný email';

  @override
  String get registerPasswordHint => 'Alespoň 6 znaků';

  @override
  String get registerPasswordMin => 'Heslo musí mít alespoň 6 znaků';

  @override
  String get commonCancel => 'Zrušit';

  @override
  String get commonSave => 'Uložit';

  @override
  String get commonDelete => 'Smazat';

  @override
  String get commonEdit => 'Upravit';

  @override
  String get commonReply => 'Odpovědět';

  @override
  String get commonSend => 'Odeslat';

  @override
  String get commonClose => 'Zavřít';

  @override
  String get commonRetry => 'Zkusit znovu';

  @override
  String get commonLoading => 'Načítání…';

  @override
  String get commonError => 'Chyba';

  @override
  String get commonOnline => 'online';

  @override
  String get commonOffline => 'offline';

  @override
  String get commonOnlineCap => 'Online';

  @override
  String get commonUser => 'Uživatel';

  @override
  String get commonPlayer => 'Hráč';

  @override
  String get commonAboutMe => 'O mně';

  @override
  String get commonBack => 'Zpět';

  @override
  String get commonAccept => 'Přijmout';

  @override
  String get commonDecline => 'Odmítnout';

  @override
  String get commonCreating => 'Vytváření…';

  @override
  String get commonSearching => 'Hledání…';

  @override
  String get commonInsufficientCoins => 'Nedostatek mincí';

  @override
  String get commonNotFound => 'Nenalezeno';

  @override
  String get commonServerErrorShort => 'Chyba serveru';

  @override
  String get commonForbidden => 'Přístup odepřen';

  @override
  String get commonUserBlocked => 'Uživatel je zablokován';

  @override
  String get commonUserNotFound => 'Uživatel nenalezen';

  @override
  String get commonGenericError => 'Něco se pokazilo. Zkuste to znovu.';

  @override
  String get apiErrWrongGameType => 'Špatný typ hry';

  @override
  String get apiErrWrongGameTypeOrState => 'Špatný typ nebo stav hry';

  @override
  String get apiErrLobbyFull => 'Lobby je plné';

  @override
  String get apiErrBadState => 'Neplatný stav hry';

  @override
  String get apiErrIllegalMove => 'Tento tah není povolen';

  @override
  String get apiErrUnknownMoveType => 'Neznámý typ tahu';

  @override
  String get apiErrNoOpponents => 'Žádní soupeři';

  @override
  String get apiErrNoOpponentsRematch => 'Žádní soupeři pro odvetu';

  @override
  String get apiErrAlreadyInLobby => 'Už jste v tomto lobby';

  @override
  String get apiErrGameNotActive => 'Hra není aktivní';

  @override
  String get apiErrNotInBattle => 'Teď není fáze boje';

  @override
  String get apiErrNotInSetup => 'Teď není fáze rozmístění';

  @override
  String get apiErrAlreadyReady => 'Už jste připraveni';

  @override
  String get apiErrAlreadyForfeited => 'Už jste se vzdali';

  @override
  String get apiErrYouHaveForfeited => 'Vzdali jste se';

  @override
  String get apiErrNoDrawOffer => 'Není nabídka remízy';

  @override
  String get apiErrDrawOnlyPvp => 'Remíza je jen proti hráči';

  @override
  String get apiErrDrawOnly1v1 => 'Remíza je jen ve hře 1 na 1';

  @override
  String get apiErrDrawVsBot => 'Remíza není dostupná proti botovi';

  @override
  String get apiErrDrawMultiplayer => 'Remíza není dostupná ve hře více hráčů';

  @override
  String get apiErrDeck24TwoPlayers => 'Balíček 24 je jen pro 2 hráče';

  @override
  String get apiErrDeck52ThreeOrFour => 'Balíček 52 je pro 3 nebo 4 hráče';

  @override
  String get apiErrAccountFrozen => 'Účet je zmrazen';

  @override
  String get apiErrTurnTimeInvalid => 'Čas na tah musí být 0, 20, 60 nebo 600 sekund';

  @override
  String get timeJustNow => 'právě teď';

  @override
  String get timeYesterday => 'včera';

  @override
  String timeMinutesAgo(int count) {
    return 'před $count min';
  }

  @override
  String timeHoursAgo(int count) {
    return 'před $count h';
  }

  @override
  String timeDaysAgo(int count) {
    return 'před $count d';
  }

  @override
  String get timeWeekAgo => 'před týdnem';

  @override
  String timeWeeksAgo(int count) {
    return 'před $count týd.';
  }

  @override
  String get timeMonthAgo => 'před měsícem';

  @override
  String timeMonthsAgo(int count) {
    return 'před $count měs.';
  }

  @override
  String get timeYearAgo => 'před rokem';

  @override
  String timeYearsAgo(int count) {
    return 'před $count r.';
  }

  @override
  String get weekdaySun => 'ne';

  @override
  String get weekdayMon => 'po';

  @override
  String get weekdayTue => 'út';

  @override
  String get weekdayWed => 'st';

  @override
  String get weekdayThu => 'čt';

  @override
  String get weekdayFri => 'pá';

  @override
  String get weekdaySat => 'so';

  @override
  String get monthJan => 'led';

  @override
  String get monthFeb => 'úno';

  @override
  String get monthMar => 'bře';

  @override
  String get monthApr => 'dub';

  @override
  String get monthMay => 'kvě';

  @override
  String get monthJun => 'čvn';

  @override
  String get monthJul => 'čvc';

  @override
  String get monthAug => 'srp';

  @override
  String get monthSep => 'zář';

  @override
  String get monthOct => 'říj';

  @override
  String get monthNov => 'lis';

  @override
  String get monthDec => 'pro';

  @override
  String get homeAchievements => 'Úspěchy';

  @override
  String get homeAchievementsSubtitle => 'Vaše herní výsledky';

  @override
  String get homeAchievementsRewards => 'Dostupné odměny k vyzvednutí';

  @override
  String get homeCoins => 'Mince';

  @override
  String get homeCoinsSubtitle => 'Zůstatek a odměny';

  @override
  String get homeCoinsDailyReward => 'Dostupná odměna za přihlášení';

  @override
  String get homeItems => 'Předměty';

  @override
  String get homeItemsInventory => 'Váš inventář';

  @override
  String get homeItemsGifted => 'Někdo vám daroval kolekci';

  @override
  String get homeItemsIncome => 'Příjem z kolekcí je připraven k vyzvednutí';

  @override
  String get homeShop => 'Obchod';

  @override
  String get homeShopSubtitle => 'Emoji, sázky, kolekce';

  @override
  String get gamesTitle => 'Hry';

  @override
  String get gamesFindMatch => 'Najít hru';

  @override
  String get gamesMyTurn => 'Váš tah';

  @override
  String get gamesWaiting => 'Čekání';

  @override
  String get gamesLobbyTab => 'Lobby';

  @override
  String get gamesTicTacToe => 'Piškvorky';

  @override
  String get gamesDurak => 'Durak';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => 'Otočit';

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
  String get gamesNardy => 'Vrhcáby';

  @override
  String get gamesNardyModeShort => 'Krátké';

  @override
  String get gamesNardyModeLong => 'Dlouhé';

  @override
  String get gamesCheckers => 'Dáma';

  @override
  String get gamesCheckersModeRussian => 'Ruské';

  @override
  String get gamesCheckersModeEnglish => 'Anglické';

  @override
  String get gamesCheckersModeGiveaway => 'Poddávaná';

  @override
  String get gamesCheckersModeCorners => 'Rohy';

  @override
  String get gamesChess => 'Šachy';

  @override
  String get gamesChessModeClassic => 'Klasika';

  @override
  String get gamesChessModeRapid => 'Rapid';

  @override
  String get gamesChessModeBlitz => 'Bleskovka';

  @override
  String get gamesChessModeBullet => 'Kulka';

  @override
  String get chessPieceQueen => 'Dáma';

  @override
  String get chessPieceRook => 'Věž';

  @override
  String get chessPieceBishop => 'Střelec';

  @override
  String get chessPieceKnight => 'Jezdec';

  @override
  String get chessPromotionTitle => 'Proměna pěšce';

  @override
  String get chessDrawStalemate => 'Remíza: pat';

  @override
  String get chessDrawInsufficient => 'Remíza: nedostatek materiálu';

  @override
  String get chessDrawRepetition => 'Remíza: trojí opakování pozice';

  @override
  String get chessDrawFiftyMove => 'Remíza: pravidlo 50 tahů';

  @override
  String get chessCheck => 'Šach';

  @override
  String get rulesCheckersPlayers => 'Hráči: 2.';

  @override
  String rulesCheckersMode(String mode) {
    return 'Režim: $mode.';
  }

  @override
  String rulesCheckersTime(String time) {
    return 'Время на ход: $time. Если время вышло — проигрыш.';
  }

  @override
  String get rulesCheckersIntro => 'Deska 8×8. Dva hráči.';

  @override
  String get rulesCheckersPlay => 'Braní je povinné. Dáma i pěšec musí pokračovat, dokud z pole dopadu lze brát dál — zastavit uprostřed nelze. Při více směrech lze zvolit kterýkoli, ne nutně nejdelší. Pěšec na poslední řadě se stává dámou.';

  @override
  String get rulesCheckersWin => 'В русских шашках побеждает тот, кто съел все шашки соперника или лишил его хода. В поддавках наоборот: кто не может ходить — выигрывает.';

  @override
  String get rulesCheckersOfflineBot => 'Офлайн: партия против бота.';

  @override
  String get rulesCheckersPlayRussian => 'Ruská dáma: po 12 kamenech na tmavých polích. Pěšci táhnou šikmo vpřed a berou vpřed i vzad. Dámy létají libovolně daleko. Braní je povinné: nelze zastavit, pokud lze pokračovat, ale při více směrech zvolíte kterýkoli, ne nutně nejdelší. Vyhrává ten, kdo sebere všechny kameny nebo soupeře zbaví tahů.';

  @override
  String get rulesCheckersPlayEnglish => 'Anglická dáma: po 12 kamenech. Pěšci táhnou a berou jen šikmo vpřed. Dámy jdou o jedno pole šikmo. Braní je povinné. Vyhrává ten, kdo sebere všechny kameny nebo soupeře zbaví tahů.';

  @override
  String get rulesCheckersPlayGiveaway => 'Poddávaná: stejné tahy jako v ruské dámě, ale cíl je opačný — odevzdat všechny kameny nebo zůstat bez tahu. Braní je stále povinné.';

  @override
  String get rulesCheckersPlayCorners => 'Rohy: kameny začínají v protilehlých rozích. Táhne se na sousední volné pole vodorovně nebo svisle, nebo se přeskočí libovolný kámen bez braní. Cíl je převést všechny své kameny do soupeřova rohu.';

  @override
  String get rulesCheckersPlayCornersNoReturn => 'Kámen, který už opustil svůj startovní roh, se do něj nesmí vrátit.';

  @override
  String get rulesCheckersPlayCornersLeaveHome => 'Kameny, které ještě neopustily dům, musí z něj odejít během prvních 25 tahů hráče.';

  @override
  String get rulesCheckersDrawRussian => 'Remíza, pokud se pozice třikrát zopakuje, nebo 15 tahů každé strany nepřinese postup: žádné braní, tah kamenem ani povýšení.';

  @override
  String get rulesCheckersDrawEnglish => 'Remíza, pokud se pozice třikrát zopakuje, pokud 40 tahů každé strany mine bez braní a tahu kamenem, nebo zbude jen jedna dáma na každé straně.';

  @override
  String get rulesCheckersDrawGiveaway => 'Remíza, pokud se pozice třikrát zopakuje, nebo 15 tahů každé strany ve hře na odevzdání nepřinese postup: žádné braní, tah kamenem ani povýšení.';

  @override
  String get rulesCheckersDrawCorners => 'Remíza, pokud se pozice třikrát zopakuje, nebo 25 tahů každé strany nepřidá kámen do cílového rohu.';

  @override
  String get rulesChessPlayers => 'Hráči: 2.';

  @override
  String rulesChessMode(String mode) {
    return 'Režim: $mode.';
  }

  @override
  String get rulesChessPlayClassic => 'Šachovnice 8×8. Každá strana má krále, dámu, dvě věže, dva střelce, dva jezdce a osm pěšců. Bílý začíná. Běžné tahy, braní mimochodem, proměna a rošáda. Výhra matem nebo vzdáním.';

  @override
  String get rulesChessDrawClassic => 'Remíza patem, trojím opakováním, pravidlem 50 tahů, nedostatkem materiálu nebo dohodou.';

  @override
  String get rulesChessClockClassic => 'Čas: 60+0 — 60 minut na celou partii, bez přídavku.';

  @override
  String get rulesChessClockRapid => 'Čas: 10+0 — 10 minut na celou partii, bez přídavku.';

  @override
  String get rulesChessClockBlitz => 'Čas: 5+0 — 5 minut na celou partii, bez přídavku.';

  @override
  String get rulesChessClockBullet => 'Čas: 3+2 — 3 minuty plus 2 sekundy za tah.';

  @override
  String get checkersDrawRepetition => 'Remíza — pozice se třikrát opakovala';

  @override
  String get checkersDrawNoProgress => 'Remíza — tahy nevedou k výhře';

  @override
  String get checkersDrawInsufficient => 'Remíza — málo materiálu k výhře';

  @override
  String get rulesNardyTitle => 'Vrhcáby — pravidla';

  @override
  String get rulesNardyPlayers => 'Hráči: 2.';

  @override
  String rulesNardyMode(String mode) {
    return 'Režim: $mode.';
  }

  @override
  String get rulesNardyIntro => 'Deska o 24 bodech, po 15 kamenech. Dvě kostky: jeden kámen součet, nebo dva kameny jednotlivá oka.';

  @override
  String get rulesNardyPlayShort => 'Krátké vrhcáby: jdete proti sobě a můžete tlouct osamocené kameny. Trefený jde na bar a musí vstoupit znovu. Až jsou všechny v domě, sundáváte je.';

  @override
  String get rulesNardyPlayLong => 'Dlouhé vrhcáby: oba začínají z jedné hlavy a jdou stejným směrem. Z hlavy vyjde za tah nanejvýš jeden kámen. Tlouct se nesmí. Až jsou všechny v domě, sundáváte je.';

  @override
  String get rulesNardyWin => 'Vyhrává ten, kdo první sundá všechny kameny.';

  @override
  String get rulesNardySixPrime => 'Šest polí za sebou nesmíš uzavřít, dokud je nemine alespoň jeden soupeřův kámen.';

  @override
  String get nardyRoll => 'Hodit';

  @override
  String get nardySkipTurn => 'Přeskočit tah';

  @override
  String get nardyUndoMove => 'Vrátit';

  @override
  String get nardyDoneTurn => 'Hotovo';

  @override
  String get nardyAutoConfirm => 'Automaticky';

  @override
  String get nardyAutoConfirmHint => 'Po všech tazích ihned předat tah soupeři';

  @override
  String get nardyLayoutToggle => 'Změnit rozložení';

  @override
  String get nardyNoMoves => 'Žádné tahy';

  @override
  String get nardyYourRoll => 'Váš hod';

  @override
  String get nardyPipsShort => 'Zbývá:';

  @override
  String get nardyYouWonMars => 'Vyhráli jste — gammon!';

  @override
  String get nardyYouLostMars => 'Prohra — gammon';

  @override
  String get rulesNardyOfflineBot => 'Offline: hra proti botovi.';

  @override
  String rulesUnoPlayers(int players) {
    return 'Hráči: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'Hra proti botovi bez časového limitu na tah.';

  @override
  String get rulesUnoIntro => 'Každý dostane 7 karet. Hrajte kartu stejné barvy nebo stejné hodnoty (číslo nebo stejná akce).';

  @override
  String get rulesUnoPlay => 'Přeskočení — další hráč ztrácí tah. Otočení ve dvou funguje jako přeskočení. +2 se klade jen na +2 a +4 jen na +4: trest se sčítá (dvě +2 — další lízne 4). +2 na +4 dát nelze. Kdo neodpoví, lízne celý balíček a ztrácí tah. Dvě stejné nečerné karty (např. dvě žluté 8) se odhodí spolu: zahrajte jednu a dvojče odletí samo.';

  @override
  String get rulesUnoWild => 'Černá karta určí novou barvu. +4 jen když nemáte kartu aktuální barvy. Soupeř může vyzvat: bylo-li +4 legální, lízne 6; jinak autor +4 lízne 4 a vyzývatel hraje.';

  @override
  String get rulesUnoDraw => 'Bez vhodné karty lízněte jednu z balíčku. Pokud sedí, můžete ji ihned zahrát, nebo si ji nechat a předat tah. Nelze lízat, dokud máte tah.';

  @override
  String get rulesUnoWin => 'Ve dvou do 100 bodů, při 3+ hráčích do 200. Kolo vyhraje hráč, který shodí všechny karty.';

  @override
  String get rulesUnoCall => 'Když zbývá jedna karta, hned stiskněte „Uno!“. Soupeři vás mohou chytit za zapomenuté Uno až po jedné sekundě — pak líznete 2 karty.';

  @override
  String get rulesUnoScoring => 'Kdo první shodí všechny karty, vyhraje kolo a získá body za soupeřovy karty: čísla podle hodnoty, akce 20, černé 50. Ve dvou do 100, při 3+ hráčích do 200.';

  @override
  String get unoColorRed => 'Červená';

  @override
  String get unoColorYellow => 'Žlutá';

  @override
  String get unoColorGreen => 'Zelená';

  @override
  String get unoColorBlue => 'Modrá';

  @override
  String get unoDraw => 'Líznout';

  @override
  String get unoKeep => 'Ponechat';

  @override
  String get unoSayUno => 'Uno!';

  @override
  String get unoChallengeUno => 'Vyzvat Uno';

  @override
  String get unoChallengeWd4 => 'Vyzvat +4';

  @override
  String get unoChooseColor => 'Vyberte barvu';

  @override
  String get unoDrawPile => 'Balíček';

  @override
  String get unoDiscardPile => 'Odkládací hromádka';

  @override
  String unoCardsCount(int count) {
    return 'Karty: $count';
  }

  @override
  String unoScore(int score) {
    return 'Skóre: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'Kolo $round · do $target';
  }

  @override
  String get unoYourTurn => 'Váš tah';

  @override
  String get unoWaitingTurn => 'Tah soupeře';

  @override
  String get unoChooseColorHint => 'Vyberte barvu pro žolíka';

  @override
  String get unoWd4Hint => 'Lízněte 4 karty nebo vyzvěte Wild +4';

  @override
  String get unoDrawnHint => 'Zahrajte líznutou kartu nebo si ji ponechte';

  @override
  String get unoPlayHint => 'Zahrajte shodnou barvu nebo hodnotu';

  @override
  String get unoDrawHint => 'Žádná shodná karta — lízněte si';

  @override
  String unoPendingDraw(int count) {
    return '+$count karet';
  }

  @override
  String get unoYouWon => 'Vyhráli jste zápas!';

  @override
  String get unoYouLost => 'Zápas skončil';

  @override
  String get unoYouLostTimeout => 'Prohráli jste na čas';

  @override
  String unoWinner(String name) {
    return 'Vítěz: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name vyhrává kolo';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'Další';

  @override
  String get unoRoundScoresTitle => 'Skóre kola';

  @override
  String get unoDirectionClockwise => 'Po směru hodin';

  @override
  String get unoDirectionCounterclockwise => 'Proti směru hodin';

  @override
  String get unoErrStackSameOnly => 'Na +2 smíte dát jen +2, na +4 jen +4. +2 na +4 dát nelze.';

  @override
  String get unoErrCatchTooEarly => 'Počkejte vteřinu — ještě můžou říct Uno.';

  @override
  String get unoErrCallTooLate => 'Uno už říct nelze. Další hráč už táhl.';

  @override
  String get gamesInDevelopment => 'Ve vývoji';

  @override
  String rulesPokerPlayers(int players) {
    return 'Hráči: $players.';
  }

  @override
  String get rulesPokerIntro => 'Texas Hold’em. Každý dostane 2 soukromé karty; na stůl přijde 5 společných karet.';

  @override
  String get rulesPokerPlay => 'Sázková kola: preflop, flop, turn a river. Fold, call, bet nebo raise.';

  @override
  String get rulesPokerWin => 'Vyhrává nejlepší pětikombinace (soukromé + společné), nebo poslední po foldech.';

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
  String get pokerCombinationsTitle => 'Kombinace';

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
  String get gamesRules => 'Pravidla';

  @override
  String get gamesRulesTitle => 'Herní pravidla';

  @override
  String get gamesCreate => 'Vytvořit hru';

  @override
  String get gamesJoin => 'Připojit se';

  @override
  String get gamesOpponentTurn => 'Tah soupeře';

  @override
  String get gamesCurrentGame => 'Aktuální hra';

  @override
  String get gamesInvitedYou => 'Byli jste pozváni';

  @override
  String get gamesTurnTime => 'Čas na tah';

  @override
  String get gamesGridSize => 'Velikost mřížky';

  @override
  String get gamesSwapSides => 'Výměna stran';

  @override
  String get gamesNoCenter => 'Bez startu ve středu';

  @override
  String get gamesObservation => 'Sledování';

  @override
  String get gamesObservationHint => 'Můžete sledovat až do konce partie';

  @override
  String get gamesFinishCurrentFirst => 'Nejdříve dokončete aktuální hru';

  @override
  String get gamesVariantClassic => 'Klasický';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 hráči';

  @override
  String get gamesVariantMulti4 => '4 hráči';

  @override
  String get gamesDurakModePodkidnoi => 'Přihazovaný';

  @override
  String get gamesDurakModePerevodnoi => 'Převáděný';

  @override
  String get gamesDurakDeck24 => '24 karet';

  @override
  String get gamesDurakDeck36 => '36 karet';

  @override
  String get gamesDurakDeck52 => '52 karet';

  @override
  String rulesDurakMode(String mode) {
    return 'Režim: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'Hráči: $players. Balíček: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Hra proti botovi, bez sázek a limitu času.';

  @override
  String get rulesDurakAttack => 'Útočník pokládá karty; obránce je bije (stejná barva vyšší, nebo trumf). Trumf se bije jen vyšším trumfem.';

  @override
  String get rulesDurakBeat => 'Když jsou všechny karty bity, útočník řekne «Bito» a karty jdou do odhozu. Jinak si obránce vezme všechno ze stolu.';

  @override
  String get rulesDurakLoser => 'Prohrává ten, komu na konci zůstanou karty — «hlupák».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Hráči $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Lobby $name';
  }

  @override
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Soukromá hra';

  @override
  String get lobbySearchingOpponent => 'Hledání soupeře…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Hledají tuto hru: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Čekáme, až někdo stiskne „Najít hru“ nebo „Připojit se“';

  @override
  String get lobbyInviteTitle => 'Pozvánka do hry';

  @override
  String get lobbyInvitedToPlay => 'Byli jste pozváni ke hře';

  @override
  String get lobbyEnterGame => 'Vstoupit do hry';

  @override
  String get lobbyGone => 'Lobby již není dostupné';

  @override
  String get lobbyInvite => 'Pozvat';

  @override
  String get lobbyInviteSent => 'Pozvánka odeslána';

  @override
  String get lobbyCopyLink => 'Sdílet odkaz na hru';

  @override
  String get lobbyLinkCopied => 'Odkaz zkopírován';

  @override
  String get lobbyNoFriendsOnline => 'Žádní přátelé online. Sdílejte odkaz na hru výše nebo počkejte, až budou přátelé online.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Soupeř';

  @override
  String get gameYou => 'Vy';

  @override
  String get gameYouWon => 'Vyhráli jste!';

  @override
  String get gameYouLost => 'Prohráli jste';

  @override
  String get gameYouWonOpponentLeft => 'Vyhráli jste — soupeř odešel';

  @override
  String get gameYouWonOpponentTimeout => 'Vyhráli jste — soupeři vypršel čas';

  @override
  String get gameDraw => 'Remíza';

  @override
  String get gameExitTitle => 'Opustit hru';

  @override
  String get gameExitConfirm => 'Pokud odejdete, prohrajete. Přesto odejít?';

  @override
  String get gameStay => 'Zůstat';

  @override
  String get gameLeave => 'Odejít';

  @override
  String get gameSurrender => 'Vzdát se';

  @override
  String get gameSurrenderTitle => 'Vzdát se?';

  @override
  String get gameSurrenderConfirm => 'Prohrajete partii a sázkové mince.';

  @override
  String get gameOfferDraw => 'Nabídnout remízu';

  @override
  String get gameFlipBoard => 'Otočit šachovnici';

  @override
  String get gameReviewStart => 'Na začátek partie';

  @override
  String get gameReviewPrev => 'O tah zpět';

  @override
  String get gameReviewNext => 'O tah vpřed';

  @override
  String get gameReviewEnd => 'Na aktuální pozici';

  @override
  String get gameOfferDrawTitle => 'Nabídnout remízu?';

  @override
  String get gameOfferDrawConfirm => 'Soupeř může remízu přijmout nebo odmítnout.';

  @override
  String get gameAcceptDrawTitle => 'Přijmout remízu?';

  @override
  String get gameAcceptDrawConfirm => 'Partie skončí remízou.';

  @override
  String get gameDrawOffered => 'Soupeř nabízí remízu';

  @override
  String get gameConnecting => 'Připojování ke hře…';

  @override
  String get gameWaitingOpponent => 'Čekání na soupeře';

  @override
  String get gameRematchOffer => 'Soupeř nabízí odvetu';

  @override
  String get gameRematchDeclined => 'Soupeř odvetu odmítl';

  @override
  String get gameRematch => 'Odveta';

  @override
  String get gameOtherOpponent => 'Jiný soupeř';

  @override
  String get gameSwapSidesAction => 'Vyměnit strany';

  @override
  String get gameWriteMessage => 'Napsat zprávu';

  @override
  String get chatsTitle => 'Chaty';

  @override
  String get chatsEmpty => 'Zatím žádné chaty.\nKlepněte na ikonu vpravo nahoře, vyberte přítele a začněte konverzaci.';

  @override
  String get chatsNewChat => 'Nový chat';

  @override
  String get chatsNoMessages => 'Žádné zprávy';

  @override
  String get chatsClearTitle => 'Vymazat konverzaci?';

  @override
  String get chatsClearDesc => 'Chat bude trvale smazán.';

  @override
  String get chatsClearConfirm => 'Vymazat';

  @override
  String get chatsBlockTitle => 'Zablokovat tohoto uživatele?';

  @override
  String get chatsBlockDesc => 'Už si nebudete moci psát. Chat a přátelství budou odstraněny.';

  @override
  String get chatsBlockConfirm => 'Zablokovat';

  @override
  String get chatsBlockedUsers => 'Zablokovaní uživatelé';

  @override
  String get chatsUnblock => 'Odblokovat';

  @override
  String get chatDialog => 'Chat';

  @override
  String get chatEmpty => 'Zatím žádné zprávy.\nPošlete první.';

  @override
  String get chatMessageHint => 'Zpráva';

  @override
  String get chatPaste => 'Vložit';

  @override
  String get chatEmoji => 'Emoji';

  @override
  String get chatBuyEmojiHint => 'Kupte emoji v obchodě na úvodní obrazovce';

  @override
  String get chatEditing => 'Úpravy';

  @override
  String get chatToday => 'Dnes';

  @override
  String get chatYesterday => 'Včera';

  @override
  String get chatFriendsOnly => 'Text jen pro přátele';

  @override
  String get emojiGroupEmotions => 'Emoce';

  @override
  String get emojiGroupGame => 'Herní';

  @override
  String get emojiGroupFlags => 'Vlajky';

  @override
  String get emojiGroupAnimals => 'Zvířata';

  @override
  String get emojiGroupFood => 'Jídlo';

  @override
  String get emojiGroupTravel => 'Cestování';

  @override
  String get emojiGroupParty => 'Oslava';

  @override
  String get emojiGroupObjects => 'Předměty';

  @override
  String get friendsTitle => 'Přátelé';

  @override
  String get friendsTabFriends => 'Přátelé';

  @override
  String get friendsTabIncoming => 'Příchozí';

  @override
  String get friendsTabOutgoing => 'Odchozí';

  @override
  String get friendsAdd => 'Přidat přítele';

  @override
  String get friendsRequestSent => 'Žádost odeslána';

  @override
  String get friendsFindTab => 'Najít přítele';

  @override
  String get friendsSearchHint => 'Hledat podle uživatelského jména';

  @override
  String get friendsSearchPrompt => 'Použijte hledání a najděte nové přátele';

  @override
  String get friendsNothingFound => 'Nic nenalezeno';

  @override
  String get friendsEmpty => 'Zatím nemáte žádné přátele';

  @override
  String get friendsSearchNoMatches => 'Žádní přátelé nevyhovují hledání';

  @override
  String get friendsIncomingSearchNoMatches => 'Žádné příchozí žádosti pro hledání';

  @override
  String get friendsOutgoingSearchNoMatches => 'Žádné odchozí žádosti pro hledání';

  @override
  String get friendsNoIncoming => 'Žádné příchozí žádosti';

  @override
  String get friendsNoOutgoing => 'Žádné odchozí žádosti';

  @override
  String get friendsAlreadyFriends => 'Už jste přátelé';

  @override
  String get friendsRemoveTitle => 'Odebrat z přátel?';

  @override
  String get friendsRemoved => 'Odebráno z přátel';

  @override
  String get friendsRequestAccepted => 'Žádost přijata';

  @override
  String get friendsRequestDeclined => 'Žádost odmítnuta';

  @override
  String get friendsRequestCancelled => 'Žádost zrušena';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSignInPrompt => 'Přihlaste se ke svému účtu';

  @override
  String get profileSignInHint => 'Pro nastavení osobního profilu';

  @override
  String get profileEdit => 'Upravit';

  @override
  String get profileCollections => 'Kolekce';

  @override
  String get profileAge => 'Věk';

  @override
  String get profileGender => 'Pohlaví';

  @override
  String get profileGenderUnset => 'Neuvedeno';

  @override
  String get profileGenderMale => 'Muž';

  @override
  String get profileGenderFemale => 'Žena';

  @override
  String get profileAvatar => 'Avatar';

  @override
  String get profileUploadPhoto => 'Nahrát foto';

  @override
  String get profileChangePhoto => 'Změnit avatar';

  @override
  String get shopTitle => 'Obchod';

  @override
  String get shopEmojis => 'Emoji';

  @override
  String get shopEmojisSubtitle => 'Animované emoji do chatu';

  @override
  String get shopCollections => 'Kolekce';

  @override
  String get shopCollectionsSubtitle => 'Výloha profilu, dárky a příjem';

  @override
  String get shopStakes => 'Sázky';

  @override
  String get shopStakesSubtitle => 'Odemknutí vyšších sázek';

  @override
  String get shopEmojisHelp => 'Animované smajlíky do chatu. Kupte sadu a posílejte je přátelům.';

  @override
  String get shopCollectionsHelp => 'Prodat lze jen novou nebo vintage kolekci: 80 % ceny, když je nová, a 300 % ceny, když je vintage. Ohmatanou, unavenou a zchátralou prodat nelze.\n\nSesbírejte sadu předmětů: objeví se ve výloze profilu, lze je darovat. Každý předmět denně přináší mince a kompletní sada ještě samostatný bonus.\n\nDenní příjem předmětu záleží na stavu a počítá se z obvyklé částky. Nová přináší 100 %. Ohmataná 60 %. Unavená 40 %. Zchátralá 100 %. Vintage předmět přináší 200 %, tedy dvojnásobek obvyklého příjmu.\n\nBonus kompletní sady se nemění, dokud se sada sama nestane vintage. Sada je vintage, když je vintage každý její předmět: bonus je pak 300 %, trojnásobek obvyklého.\n\nStav záleží na tom, jak dlouho předmět máte. Nová — prvních 7 dní. Ohmataná — od 8. dne do 2 měsíců. Unavená — od 2 do 6 měsíců. Zchátralá — od 6 měsíců do roku. Vintage — od roku.';

  @override
  String get shopStakesHelp => 'Odemkněte vyšší sázky. Čím vyšší sázka, tím větší pot a výhra.';

  @override
  String get inventoryTitle => 'Předměty';

  @override
  String get inventoryEmpty => 'Zatím tu nic není — podívejte se do obchodu';

  @override
  String get inventoryFrames => 'Rámečky';

  @override
  String get inventoryClaim => 'Vyzvednout';

  @override
  String get inventorySell => 'Prodat';

  @override
  String get inventoryGift => 'Darovat';

  @override
  String get messageEdited => 'upraveno';

  @override
  String get messageDeleted => 'Zpráva smazána';

  @override
  String get photo => 'Foto';

  @override
  String get camera => 'Fotoaparát';

  @override
  String get gallery => 'Galerie';

  @override
  String get connectionError => 'Nepodařilo se připojit k serveru.';

  @override
  String get serverError => 'Chyba serveru. Zkuste to později.';

  @override
  String get sessionExpired => 'Relace vypršela. Přihlaste se znovu.';

  @override
  String get errNoInternet => 'Žádné připojení k internetu.';

  @override
  String get errTimeout => 'Vypršel časový limit. Zkuste to znovu.';

  @override
  String get errGamesUnavailable => 'Hry jsou dočasně nedostupné';

  @override
  String get errSettingsSaveFailed => 'Nepodařilo se uložit nastavení';

  @override
  String get errPushPermission => 'Povolte oznámení v nastavení prohlížeče nebo systému.';

  @override
  String get balanceTitle => 'Zůstatek';

  @override
  String get coinBronze => 'Bronz';

  @override
  String get coinSilver => 'Stříbro';

  @override
  String get coinGold => 'Zlato';

  @override
  String get coinDiamond => 'Diamant';

  @override
  String get balanceZeroBronze => '0 bronzových';

  @override
  String balanceBronzes(int count) {
    return '$count bronzových';
  }

  @override
  String balanceSilvers(int count) {
    return '$count stříbrných';
  }

  @override
  String balanceGolds(int count) {
    return '$count zlatých';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count diamantů';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/den';
  }

  @override
  String get balanceAbbrBronze => 'br';

  @override
  String get balanceAbbrSilver => 'st.';

  @override
  String get balanceAbbrGold => 'zl.';

  @override
  String get commonBackHome => 'Zpět na hlavní';

  @override
  String get commonCopied => 'Zkopírováno';

  @override
  String get commonClear => 'Vymazat';

  @override
  String get commonTryLater => 'Zkuste to později.';

  @override
  String get commonTryRefresh => 'Zkuste obnovit stránku.';

  @override
  String get coinsTitle => 'Mince';

  @override
  String get coinsLoginReward => 'Odměna za přihlášení';

  @override
  String get coinsLoginAvailableToday => 'Dnešní odměna je k dispozici';

  @override
  String get coinsLoginStreak => 'Denní série přihlášení';

  @override
  String get coinsFriendReward => 'Odměna za přítele';

  @override
  String get coinsTasks => 'Úkoly';

  @override
  String get coinsTasksSubtitle => 'Odměny za profil, přátele a hry';

  @override
  String get coinsTasksRewards => 'Dostupné odměny k vyzvednutí';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount za registraci přes váš odkaz';
  }

  @override
  String get coinsLoadRewardsFailed => 'Nepodařilo se načíst odměny';

  @override
  String get coinsClaimReward => 'Vyzvednout odměnu';

  @override
  String get coinsAlreadyClaimed => 'Již vyzvednuto';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · dnes';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · zbývá 1 den';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · zbývá $remaining';
  }

  @override
  String get coinsInviteFriend => 'Pozvěte přítele';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount za každého, kdo se zaregistruje přes váš odkaz';
  }

  @override
  String get coinsCopyLink => 'Kopírovat odkaz';

  @override
  String get coinsHowItWorks => 'Jak to funguje';

  @override
  String get coinsHowStep1 => 'Zkopírujte odkaz a pošlete ho příteli';

  @override
  String get coinsHowStep2 => 'Přítel se zaregistruje přes tento odkaz';

  @override
  String coinsHowStep3(String amount) {
    return 'Obdržíte $amount';
  }

  @override
  String get achievementsTitle => 'Úspěchy';

  @override
  String achievementsProgress(String progress) {
    return 'Postup: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Rámeček získán';

  @override
  String get achievementsClaimed => 'Získáno';

  @override
  String get achievementsOpenFrame => 'Otevřít rámeček';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Opravdu chcete odstranit $name z přátel?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Odebrat';

  @override
  String get friendsRemove => 'Odebrat z přátel';

  @override
  String get friendsAcceptRequest => 'Přijmout žádost';

  @override
  String get friendsDeclineRequest => 'Odmítnout žádost';

  @override
  String get friendsCancelRequest => 'Zrušit žádost';

  @override
  String get friendsSendRequest => 'Poslat žádost o přátelství';

  @override
  String get friendsRequestAlreadySent => 'Žádost už byla odeslána';

  @override
  String get friendsIncomingStatus => 'Příchozí žádost';

  @override
  String get friendsOutgoingStatus => 'Odchozí žádost';

  @override
  String get friendsNotFriends => 'Nejsou přátelé';

  @override
  String get friendsCollapseSearch => 'Sbalit hledání';

  @override
  String get friendsExpandSearch => 'Zobrazit hledání';

  @override
  String get friendsLoadFailed => 'Nepodařilo se načíst přátele';

  @override
  String friendsSince(String date) {
    return 'Přátelé od: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Příchozí žádost: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Odchozí žádost: $date';
  }

  @override
  String get userInfoTitle => 'Informace o uživateli';

  @override
  String profileAgeYears(int age) {
    return '$age let';
  }

  @override
  String get shopBuy => 'Koupit';

  @override
  String get shopBuyTitle => 'Koupit?';

  @override
  String get shopBuyStakeTitle => 'Koupit sázku?';

  @override
  String get shopBuyEmojiTitle => 'Koupit emoji?';

  @override
  String get shopBuyCollectionTitle => 'Koupit kolekci?';

  @override
  String shopPrice(String price) {
    return 'Cena: $price';
  }

  @override
  String get shopOwned => 'Zakoupeno';

  @override
  String get shopHave => 'Máš';

  @override
  String get shopEmpty => 'Zatím prázdné';

  @override
  String shopPurchased(String title) {
    return '$title zakoupeno';
  }

  @override
  String get shopEmojiUses => 'Získáte: 10 použití';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 použití';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 použití';
  }

  @override
  String get shopBuyTen => 'Koupit · 10 ks';

  @override
  String shopDailyIncome(String amount) {
    return 'Příjem: $amount';
  }

  @override
  String get shopBuyOnce => 'Jednorázový nákup';

  @override
  String get shopSellRefund => 'Prodej závisí na stavu kolekce';

  @override
  String get collectionConditionNew => 'Nová';

  @override
  String get collectionConditionWorn => 'Ohmataná';

  @override
  String get collectionConditionTired => 'Unavená';

  @override
  String get collectionConditionShabby => 'Zchátralá';

  @override
  String get collectionConditionVintage => 'Vintage';

  @override
  String shopCollectionAdded(String title) {
    return '$title přidáno do profilu';
  }

  @override
  String shopSetBonus(int percent) {
    return 'bonus sady +$percent%';
  }

  @override
  String get shopSetComplete => 'Kompletní';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Sebráno · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Prodat?';

  @override
  String inventorySellDesc(String amount) {
    return 'Získáte $amount';
  }

  @override
  String get inventoryCollectionNotSellable => 'Prodat lze jen novou nebo vintage kolekci.';

  @override
  String get inventoryCollectionNotSellableTitle => 'Nelze prodat';

  @override
  String get inventoryCollectionNotSellableHint => 'Prodat lze jen nový nebo vintage předmět. Použijte elixír a změňte stav.';

  @override
  String inventorySold(String amount) {
    return 'Prodáno: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Nejprve přidejte přátele';

  @override
  String get inventoryGiftTitle => 'Darovat kolekci?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'Darovat „$title“ uživateli $name?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Darováno: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'Hráč už tento předmět vlastní';

  @override
  String get inventoryGiftSelf => 'Nemůžete darovat sami sobě';

  @override
  String get inventoryGiftNotOwned => 'Tento předmět nemáte v inventáři';

  @override
  String get inventoryLoadFailed => 'Nepodařilo se načíst předměty';

  @override
  String get inventoryNoCollections => 'Žádné kolekce — kupte je v obchodě';

  @override
  String get inventoryNoEmojis => 'Žádná emoji — kupte je v obchodě';

  @override
  String get inventoryNoFrames => 'Žádné rámečky — vyhrajte 10 ligových her (úspěchy)';

  @override
  String get inventoryNoStakes => 'Žádné zakoupené sázky';

  @override
  String inventoryEmojiLeft(int count) {
    return 'Zbývá $count';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Příjem: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Příjem zítra: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Připraveno';

  @override
  String get inventoryIncomeTomorrowLabel => 'Zítra';

  @override
  String inventoryStakeGold(String amount) {
    return 'Můžete vsadit $amount zlata';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'Můžete vsadit $amount stříbra';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'Získáno +$amount';
  }

  @override
  String get chatsLoadFailed => 'Nepodařilo se načíst chaty';

  @override
  String get chatsLoadListFailed => 'Nepodařilo se načíst seznam';

  @override
  String get chatsBlockedEmpty => 'Seznam je prázdný';

  @override
  String chatsBlockedAt(String date) {
    return 'Zablokováno: $date';
  }

  @override
  String get chatsCreateFailed => 'Nepodařilo se vytvořit chat';

  @override
  String get chatsNeedFriendsFirst => 'Nejprve přidejte přátele, pak můžete otevřít chat.';

  @override
  String get chatsFriendsNotFound => 'Přátelé nenalezeni';

  @override
  String get chatsFindFriendHint => 'Najít přítele podle přezdívky';

  @override
  String get chatsSelectChat => 'Vyberte chat';

  @override
  String get chatsSelectHint => 'Vyberte konverzaci ze seznamu vlevo';

  @override
  String get chatEditFailed => 'Nepodařilo se upravit zprávu';

  @override
  String get chatSendFailed => 'Nepodařilo se odeslat zprávu';

  @override
  String get chatDeleteFailed => 'Nepodařilo se smazat zprávu';

  @override
  String get chatEmojiSendFailed => 'Nepodařilo se odeslat emoji';

  @override
  String get chatLoadFailed => 'Nepodařilo se načíst zprávy';

  @override
  String get chatBackToGame => 'Zpět do hry';

  @override
  String get chatBackToChats => 'Zpět k chatům';

  @override
  String get chatActions => 'Akce chatu';

  @override
  String get chatAutoTranslate => 'Auto-translate';

  @override
  String get chatScrollToEnd => 'Na konec konverzace';

  @override
  String chatReplyingTo(String name) {
    return 'Odpověď pro $name';
  }

  @override
  String get chatGift => 'Dárek';

  @override
  String get chatCollection => 'Kolekce';

  @override
  String get chatGiftCollection => 'Dárek · kolekce';

  @override
  String get chatThisUser => 'tohoto uživatele';

  @override
  String get gamesLobbyLoadFailed => 'Nepodařilo se načíst lobby.';

  @override
  String get gamesTapChangeStake => 'Klepněte pro změnu sázky';

  @override
  String get gamesTapChangeTurnTime => 'Klepněte pro změnu času na tah';

  @override
  String get gamesTapChangeGrid => 'Klepněte pro změnu velikosti mřížky';

  @override
  String get gamesSwapSidesHint => 'O se může stát X po 1. tahu';

  @override
  String get gamesNoCenterHint => 'První tah nesmí být na střed';

  @override
  String get lobbyInviteSentShort => 'Odesláno';

  @override
  String get lobbySearchShort => 'Hledat';

  @override
  String get lobbySearchPlayers => 'Hledat hráče';

  @override
  String get lobbyInviteDeclinedShort => 'Odmítnuto';

  @override
  String get lobbyInvitesSentWaiting => 'Pozvánky odeslány. Čekejte na odpověď.';

  @override
  String get lobbyLinkCopiedHint => 'Vložte ji do chatu nebo zprávy příteli';

  @override
  String get lobbyCopyLinkHint => 'Kopírovat odkaz do schránky';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name vás zve ke hře';
  }

  @override
  String gameOpponentWon(String name) {
    return 'Vyhrál $name';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Čas vypršel. Vyhrál $name';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String get adminTitle => 'Administrace';

  @override
  String get tournamentsTitle => 'Turnaje';

  @override
  String get profileAgeInvalid => 'Zadejte věk od 1 do 111';

  @override
  String get profileSaveFailed => 'Nepodařilo se uložit profil';

  @override
  String get profileNameHint => 'Latinka, číslice, _ do 10 znaků';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'Od 1 do 111';

  @override
  String get profileAboutHint => 'Až 100 znaků (volitelné)';

  @override
  String get profileProcessingPhoto => 'Zpracování fotky…';

  @override
  String get profileCropTitle => 'Vyberte oblast avataru';

  @override
  String get profileCropHint => 'Přibližte a posuňte fotku';

  @override
  String get profileApply => 'Použít';

  @override
  String get profilePreparing => 'Příprava…';

  @override
  String get profileGalleryTitle => 'Fotky';

  @override
  String get profileGalleryAdd => 'Přidat fotku';

  @override
  String get profileMakePrimary => 'Nastavit jako hlavní';

  @override
  String get profilePhotoDelete => 'Smazat fotku';

  @override
  String get profilePhotosLimit => 'Můžete nahrát nejvýše 3 fotky';

  @override
  String get profilePhotosEmpty => 'Zatím žádné fotky';

  @override
  String get profilePhotoUploadFailed => 'Fotku se nepodařilo nahrát';

  @override
  String get profilePhotoDeleteFailed => 'Fotku se nepodařilo smazat';

  @override
  String get profilePhotoTooLarge => 'Fotka je příliš velká';

  @override
  String get profileSetPrimaryFailed => 'Nepodařilo se nastavit jako hlavní';

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
    return 'Piškvorky na poli $grid. Střídavě; začíná X.';
  }

  @override
  String rulesWin(int n) {
    return 'Výhra: sestavte $n v řadě vodorovně, svisle nebo úhlopříčně.';
  }

  @override
  String get rulesNoTimeLimit => 'Bez časového limitu na tah.';

  @override
  String rulesTurnTime(String time) {
    return 'Čas na tah: $time. Vypršení času znamená prohru.';
  }

  @override
  String rulesStake(String stake) {
    return 'Sázka: $stake. O tolik mincí se hraje.';
  }

  @override
  String get rulesSwap => 'Výměna stran: O se může prohodit s X po prvním tahu X.';

  @override
  String get rulesNoCenter => 'Zákaz středu: X nesmí v prvním tahu hrát do středu.';

  @override
  String get collectionSetLegends => 'Legendy';

  @override
  String get collectionSetSpace => 'Vesmír';

  @override
  String get collectionSetGems => 'Drahokamy';

  @override
  String get collectionSetParty => 'Oslava';

  @override
  String get collectionSetNature => 'Příroda';

  @override
  String get collectionSetAdventures => 'Dobrodružství';

  @override
  String collectionCardMeta(String amount) {
    return 'Kolekce · výloha · dárek · prodej · +$amount';
  }

  @override
  String get coinsDayOne => 'den';

  @override
  String get coinsDayFew => 'dny';

  @override
  String get coinsDayMany => 'dní';

  @override
  String get giftFriendTitle => 'Darovat příteli';

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
    return '$count emoji · po $price';
  }

  @override
  String get chatsExpandPanel => 'Rozbalit panel';

  @override
  String get chatsCollapsePanel => 'Sbalit panel';

  @override
  String get chatReplySourceMissing => 'Původní zpráva nenalezena';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Sázka $n stříbra';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Sázka $n zlata';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Odemkne sázku $n stříbra';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Odemkne sázku $n zlata';
  }

  @override
  String get chatReplySelf => 'sobě';

  @override
  String get chatReplyPeer => 'protějšku';

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
  String get statsTitle => 'Statistiky';

  @override
  String get statsLoadFailed => 'Nepodařilo se načíst statistiky';

  @override
  String get statsAllGames => 'Všechny hry';

  @override
  String get statsEmptyTitle => 'Zatím žádné odehrané partie';

  @override
  String get statsEmptyHint => 'Odehrajte první hru, aby se zde zobrazily statistiky.';

  @override
  String get statsWins => 'Výhry';

  @override
  String get statsDraws => 'Remízy';

  @override
  String get statsLosses => 'Prohry';

  @override
  String get statsWinRate => 'Procento výher';

  @override
  String get statsTopWon => 'Nejvíce výher proti';

  @override
  String get statsTopDrawn => 'Nejvíce remíz s';

  @override
  String get statsTopLost => 'Nejvíce proher proti';

  @override
  String get statsTimePlayed => 'Čas ve hře';

  @override
  String get statsYourScore => 'Vaše skóre';

  @override
  String get profileShowStats => 'Zobrazit statistiky';

  @override
  String get statsDurationZeroMinutes => '0 min';

  @override
  String get gameYouWonOpponentForfeit => 'Soupeř se vzdal. Vyhráli jste!';

  @override
  String get lobbyLeaveTitle => 'Opustit lobby?';

  @override
  String get lobbyLeaveConfirm => 'Lobby bude po odchodu smazáno. Pozvaní přátelé dostanou odmítnutí.';

  @override
  String get lobbyLeave => 'Opustit';

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
    return 'Vzdali jste se. $name vyhrál';
  }

  @override
  String get supportTitle => 'Podpora';

  @override
  String get supportUnavailable => 'Podpora není dostupná';

  @override
  String get supportOpenFailed => 'Nepodařilo se otevřít chat s podporou';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Bylo vám připsáno $amount mincí';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return 'Bylo odečteno $amount mincí';
  }

  @override
  String get coinsCreditCardTitle => 'Byly vám připsány mince';

  @override
  String get coinsClaim => 'Vyzvednout';

  @override
  String get durakActionPass => 'Pas';

  @override
  String get durakRoleTook => 'Bere';

  @override
  String get durakRoleBeats => 'Přebíjí';

  @override
  String get durakRoleThrowIn => 'Přihaz';

  @override
  String get durakRoleTurn => 'Tah';

  @override
  String get durakRoleDefends => 'Brání';

  @override
  String get durakStatusTaking => 'Bere';

  @override
  String get durakHintDefenderTurn => 'Tah obránce';

  @override
  String get gameYouEliminated => 'Jste venku';

  @override
  String gameYouPlaced(int place) {
    return 'Umístili jste se na $place. místě';
  }

  @override
  String get gameOverNeutral => 'Hra skončila';

  @override
  String gameTurnOf(String name) {
    return 'Tah hráče $name';
  }

  @override
  String get chatGroupTooltip => 'Skupinový chat';

  @override
  String get lobbyChatNotReady => 'Chat lobby ještě není připraven';

  @override
  String get chatsGroupChat => 'Skupinový chat';

  @override
  String chatsMembersCount(int count) {
    return 'Členové: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count os.';
  }

  @override
  String get chatsYouSuffix => '(ty)';

  @override
  String get chatTitleDurak3 => 'Durak · 3 hráči';

  @override
  String get chatTitleDurak4 => 'Durak · 4 hráči';

  @override
  String get rulesTttUltimate => 'Ultimate: devět miniplanů 3×3. Tah pošle soupeře na daný miniplán. Vyhrává linie na meta-plánu.';

  @override
  String get rulesTttMulti3 => '3 hráči: plán 3×3, tři hráči (X, O, △). Vyhrajte řadou vlastních znaků.';

  @override
  String get rulesTttMulti4 => '4 hráči: plán 4×4, čtyři hráči (X, O, △, □). Vyhrajte řadou vlastních znaků.';

  @override
  String get adminUsersTab => 'Uživatelé';

  @override
  String get adminSupportTab => 'Podpora';

  @override
  String get adminSearchHint => 'Hledat podle e-mailu nebo jména';

  @override
  String get adminRoleAdmins => 'Admini';

  @override
  String get adminRoleUsers => 'Uživatelé';

  @override
  String get adminRoleAll => 'Všechny role';

  @override
  String get adminStatusFrozen => 'Zmrazení';

  @override
  String get adminStatusActive => 'Aktivní';

  @override
  String get adminStatusAny => 'Libovolný stav';

  @override
  String get adminOrderDesc => 'Sestupně';

  @override
  String get adminOrderAsc => 'Vzestupně';

  @override
  String adminLoadFailed(String error) {
    return 'Načtení selhalo: $error';
  }

  @override
  String get adminUsersEmpty => 'Žádní uživatelé';

  @override
  String get adminSortLastSeen => 'Podle poslední návštěvy';

  @override
  String get adminSortEmail => 'Podle e-mailu';

  @override
  String get adminSortCreated => 'Podle data registrace';

  @override
  String adminBronzeBalance(int amount) {
    return '$amount br.';
  }

  @override
  String get adminRevokeAdmin => 'Odebrat admina';

  @override
  String get adminGrantAdmin => 'Udělat adminem';

  @override
  String get adminAdminRevoked => 'Práva admina odebrána';

  @override
  String get adminAdminGranted => 'Práva admina udělena';

  @override
  String get adminGrantCoins => 'Připsat mince';

  @override
  String get adminWriteSupport => 'Psát jako podpora';

  @override
  String get adminUnfreeze => 'Odmrazit';

  @override
  String get adminFreeze => 'Zmrazit';

  @override
  String get adminUnfrozen => 'Odmrazeno';

  @override
  String get adminFrozenDone => 'Zmrazeno';

  @override
  String get adminResetPassword => 'Obnovit heslo';

  @override
  String get adminCoinsAmountHint => 'Částka (záporná = odečet)';

  @override
  String get adminReasonOptional => 'Důvod (volitelné)';

  @override
  String get adminGrantSent => 'Karta odeslána do chatu podpory';

  @override
  String adminCoinsDebited(int amount) {
    return 'Odečteno $amount bronzu';
  }

  @override
  String get adminGrantVerb => 'Připsat';

  @override
  String get adminNewPasswordHint => 'Nové heslo (min. 6)';

  @override
  String get adminPasswordReset => 'Heslo obnoveno';

  @override
  String get adminResetVerb => 'Obnovit';

  @override
  String adminShortError(String error) {
    return 'Chyba: $error';
  }

  @override
  String get adminSupportEmpty => 'Žádné požadavky podpory';

  @override
  String get adminUserFallback => 'Uživatel';

  @override
  String get apiErrTooManyRequests => 'Příliš mnoho požadavků. Zkuste to později.';

  @override
  String get apiErrMoveConflict => 'Konflikt tahu. Zkuste to znovu.';

  @override
  String get shopElixirs => 'Elixirs';

  @override
  String get shopElixirsSubtitle => 'Rejuvenate, age, or speed up collections';

  @override
  String get shopElixirsHelp => 'Three shelves: rejuvenation, aging, and acceleration. Each has six elixirs, one per collection set. An elixir works only on its own set.\n\nRejuvenation makes a collection one step newer, and never newer than new. Aging makes it one step older, and never older than shabby. Acceleration is only for a shabby item: three months left until vintage, once. An elixir never grants vintage by itself.\n\nA bought elixir stays in Items. Use it from the collection card or from the elixir card. Each use spends one.';

  @override
  String get elixirGroupRejuvenate => 'Omlazení';

  @override
  String get elixirGroupAge => 'Stárnutí';

  @override
  String get elixirGroupAccelerate => 'Zrychlení';

  @override
  String get elixirEffectRejuvenate => 'omlazení';

  @override
  String get elixirEffectAge => 'stárnutí';

  @override
  String get elixirEffectAccelerate => 'zrychlení';

  @override
  String get elixirAdjCelebration => 'Slavnostní';

  @override
  String get elixirAdjNature => 'Přírodní';

  @override
  String get elixirAdjLegends => 'Legendární';

  @override
  String get elixirAdjCosmic => 'Kosmický';

  @override
  String get elixirAdjAdventure => 'Dobrodružný';

  @override
  String get elixirAdjJewels => 'Drahocenný';

  @override
  String elixirName(String adjective, String effect) {
    return '$adjective elixír $effect';
  }

  @override
  String get elixirHelpRejuvenate => 'Makes the collection one step newer. Not newer than new.';

  @override
  String get elixirHelpAge => 'Makes the collection one step older. Not older than shabby.';

  @override
  String get elixirHelpAccelerate => 'Shabby only. Three months left until vintage, once.';

  @override
  String get elixirUseRejuvenate => 'Omladit';

  @override
  String get elixirUseAge => 'Zestárnout';

  @override
  String get elixirUseAccelerate => 'Zrychlit';

  @override
  String get elixirUse => 'Použít';

  @override
  String collectionLeftDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dní',
      few: '$count dny',
      one: '$count den',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hodin',
      few: '$count hodiny',
      one: '$count hodina',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minut',
      few: '$count minuty',
      one: '$count minuta',
    );
    return '$_temp0';
  }

  @override
  String elixirSetOnly(String set) {
    return 'Only the $set set.';
  }

  @override
  String get elixirPickCollection => 'Choose a collection';

  @override
  String get elixirNoTarget => 'No collection in this set can take this elixir';

  @override
  String get elixirApplied => 'Elixir applied';

  @override
  String get elixirConfirmTitle => 'Use this elixir?';

  @override
  String elixirConfirmBody(String elixir, String collection) {
    return '$elixir\n$collection';
  }

  @override
  String get inventoryNoElixirs => 'No elixirs — buy them in the shop';

  @override
  String get elixirNotApplicable => 'This elixir cannot change that collection right now';

  @override
  String get elixirWrongSet => 'This elixir is for another set';

  @override
  String get elixirNotOwned => 'You do not have this elixir';

  @override
  String collectionUntil(String state, String left) {
    return 'Until $state: $left';
  }

  @override
  String get collectionLeftSoon => 'less than a minute';

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
}
