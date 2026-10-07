import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Główna';

  @override
  String get navProfile => 'Profil';

  @override
  String get navFriends => 'Znajomi';

  @override
  String get navChats => 'Czaty';

  @override
  String get navGames => 'Gry';

  @override
  String get navSettings => 'Ustawienia';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsLanguage => 'Język';

  @override
  String get settingsLanguageSystem => 'Jak w systemie';

  @override
  String get settingsSoundTitle => 'Dźwięk';

  @override
  String get settingsSoundSubtitle => 'Gry i powiadomienia';

  @override
  String get settingsSoundGames => 'Gry';

  @override
  String get settingsSoundNotifications => 'Powiadomienia';

  @override
  String get settingsSoundTurn => 'Tura';

  @override
  String get settingsHapticsTitle => 'Wibracje';

  @override
  String get settingsHapticsSubtitle => 'Tylko powiadomienia: wiadomości, zaproszenia, twoja tura i timer';

  @override
  String get settingsGamepadTitle => 'Kontroler';

  @override
  String get settingsGamepadSubtitle => 'Gamepad do menu i partii';

  @override
  String settingsGamepadConnected(String name) {
    return 'Połączono: $name';
  }

  @override
  String get settingsGamepadDisconnected => 'Nie znaleziono gamepada. Podłącz kontroler i naciśnij dowolny przycisk.';

  @override
  String get settingsGamepadGenericName => 'Kontroler';

  @override
  String get settingsGamepadHelpNavigate => 'Nawigacja';

  @override
  String get settingsGamepadHelpConfirm => 'Wybierz';

  @override
  String get settingsGamepadHelpBack => 'Wstecz';

  @override
  String get settingsGamepadHelpTabs => 'Karty';

  @override
  String get settingsGamepadHelpPlay => 'Kursor na planszy i w ręce: warcaby, kółko i krzyżyk, statki, durak, uno, poker i tryktrak';

  @override
  String get settingsGamepadHelpCards => 'Karty';

  @override
  String get settingsGamepadHelpKeyboard => 'Klawiatura';

  @override
  String get settingsGamepadHelpBalance => 'Saldo';

  @override
  String get settingsGamepadHelpLogout => 'Wyloguj';

  @override
  String get settingsGamepadHelpPage => 'Strona';

  @override
  String get settingsGamepadLayoutXbox => 'Układ Xbox';

  @override
  String get settingsGamepadLayoutPlayStation => 'Układ PlayStation';

  @override
  String get settingsGamepadLayoutNintendo => 'Układ Nintendo';

  @override
  String get gamepadKeyboardTitle => 'Klawiatura';

  @override
  String get gamepadKeyboardSpace => 'Spacja';

  @override
  String get gamepadLegendConfirm => 'Wybierz';

  @override
  String get gamepadLegendBack => 'Wstecz';

  @override
  String get gamepadLegendTabs => 'Karty';

  @override
  String get gamepadLegendCycle => 'Zmień';

  @override
  String gamepadConnectedSnack(String name) {
    return 'Kontroler połączony: $name';
  }

  @override
  String get settingsOfflineModeTitle => 'Tryb sieci';

  @override
  String get settingsOfflineModeSubtitle => 'Offline: graj od razu z botem, bez stawek i nagród, bez czatów i znajomych. Zakupy są zapisywane i stosowane w trybie online. Online — gdy jest internet lub według ustawienia użytkownika.';

  @override
  String get settingsModeOnline => 'Online';

  @override
  String get settingsModeOffline => 'Offline';

  @override
  String get gamesAlternateStartsHint => 'Na przemian kto zaczyna partię';

  @override
  String get rulesAlternateStarts => 'Kto zaczyna zmienia się z partii na partię.';

  @override
  String get offlineBadgeTooltip => 'Tryb offline';

  @override
  String get offlineModePopupTitle => 'Tryb offline';

  @override
  String get offlineModePopupBody => 'Tryb offline jest włączony. Graj z botem bez stawek i nagród. Czaty, znajomi i lobby są ukryte. Zakupy zostaną zastosowane w trybie online.';

  @override
  String get offlineModePopupSettings => 'Ustawienia';

  @override
  String get offlineModeOfferBody => 'Brak internetu albo połączenie jest bardzo wolne. Możesz włączyć tryb offline i zagrać z botem.';

  @override
  String get offlineModeOfferAction => 'Włącz offline';

  @override
  String get gamesPlay => 'Graj';

  @override
  String get offlineGameTitle => 'Gra z botem';

  @override
  String get offlineGameHint => 'Bez stawek i nagród · tylko offline';

  @override
  String get offlineBotWon => 'Bot wygrał';

  @override
  String get offlineBotThinking => 'Bot myśli…';

  @override
  String get offlinePlayAgain => 'Jeszcze raz';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'Weź';

  @override
  String get durakActionAll => 'Wszystkie';

  @override
  String get durakActionDone => 'Gotowe';

  @override
  String get durakActionBito => 'Bito';

  @override
  String get durakHintDefend => 'Broń się';

  @override
  String get durakHintDefendOrTransfer => 'Broń się lub przerzuć';

  @override
  String get durakHintOpponentDefends => 'Przeciwnik broni się';

  @override
  String get durakHintThrowInFirst => 'Dokładaj karty (maks. 5 w pierwszym zbiciu)';

  @override
  String get durakHintThrowIn => 'Dokładaj karty lub czekaj na obronę';

  @override
  String get durakHintOpponentThrows => 'Przeciwnik dorzuca';

  @override
  String get durakHintTakeFollow => 'Dorzuć po wzięciu lub dotknij «Gotowe»';

  @override
  String get durakHintOpponentTakeFollow => 'Przeciwnik może dorzucić po wzięciu';

  @override
  String get durakHintBito => 'Dorzuć kartę lub powiedz «Bito»';

  @override
  String get durakHintOpponentBito => 'Przeciwnik dorzuca lub mówi «Bito»';

  @override
  String get durakHintYourAttack => 'Twoja tura — atakuj';

  @override
  String get durakHintOpponentAttack => 'Przeciwnik atakuje';

  @override
  String get durakHintYouLost => 'Przegrałeś — jesteś durniem';

  @override
  String get durakHintDrawAllOut => 'Remis — wszyscy wyszli';

  @override
  String get durakHintYouFinished => 'Wyszedłeś — czekamy na koniec';

  @override
  String get durakFirstLeadYou => 'Ty wychodzisz';

  @override
  String get durakFirstLeadOpponent => 'Przeciwnik wychodzi';

  @override
  String get durakFirstLeadBot => 'Bot wychodzi';

  @override
  String durakFirstLeadOf(String name) {
    return 'Wychodzi $name';
  }

  @override
  String get durakFirstLeadReason => 'Najniższy atut';

  @override
  String get shopPurchaseQueued => 'Zakup zapisany — zostanie zastosowany w trybie online';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — zakup zastosowany';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — zakup nie zastosowany: $reason';
  }

  @override
  String get settingsFriendsOnlyTitle => 'Wiadomości tylko od znajomych';

  @override
  String get settingsFriendsOnlySubtitle => 'Osoby spoza znajomych mogą wysyłać tylko emoji. Jeśli przeszkadza spam, tymczasowo zablokuj użytkownika.';

  @override
  String get settingsNotifications => 'Powiadomienia';

  @override
  String get settingsPushChat => 'Czat';

  @override
  String get settingsPushFriends => 'Znajomi';

  @override
  String get settingsPushGames => 'Gry';

  @override
  String get settingsPushRewards => 'Nagrody';

  @override
  String settingsAppVersion(String version) {
    return 'Wersja $version';
  }

  @override
  String get appUpdateTitle => 'Dostępna aktualizacja';

  @override
  String get appUpdateBody => 'Dostępna jest nowa wersja aplikacji. Zaktualizuj, aby kontynuować.';

  @override
  String get appUpdateWhatsNew => 'Co nowego';

  @override
  String get appUpdateOk => 'Aktualizuj';

  @override
  String get appUpdateLaterBanner => 'Zaktualizujemy aplikację po tej partii';

  @override
  String get loginTitle => 'Logowanie';

  @override
  String get loginSubtitle => 'Wpisz email lub nazwę użytkownika i hasło';

  @override
  String get loginEmailLabel => 'Email lub nazwa użytkownika';

  @override
  String get loginPasswordLabel => 'Hasło';

  @override
  String get loginSubmit => 'Zaloguj się';

  @override
  String get loginNoAccount => 'Nie masz konta? Zarejestruj się';

  @override
  String get loginEmailRequired => 'Wpisz email lub nazwę użytkownika';

  @override
  String get loginPasswordRequired => 'Wpisz hasło';

  @override
  String get loginTooltip => 'Zaloguj się';

  @override
  String get logoutTooltip => 'Wyloguj się';

  @override
  String get registerTitle => 'Rejestracja';

  @override
  String get registerSubtitle => 'Utwórz konto, aby grać';

  @override
  String get registerNameLabel => 'Nazwa (login)';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'Hasło';

  @override
  String get registerSubmit => 'Zarejestruj się';

  @override
  String get registerHaveAccount => 'Masz już konto? Zaloguj się';

  @override
  String get registerNameRequired => 'Wpisz nazwę';

  @override
  String get registerNameNoSpaces => 'Nazwa nie może zawierać spacji';

  @override
  String get registerNameMax => 'Maksymalnie 20 znaków';

  @override
  String get registerNameHint => 'Do 20 znaków';

  @override
  String get registerEmailRequired => 'Wpisz email';

  @override
  String get registerEmailInvalid => 'Nieprawidłowy email';

  @override
  String get registerPasswordHint => 'Minimum 6 znaków';

  @override
  String get registerPasswordMin => 'Hasło musi mieć co najmniej 6 znaków';

  @override
  String get commonCancel => 'Anuluj';

  @override
  String get commonSave => 'Zapisz';

  @override
  String get commonDelete => 'Usuń';

  @override
  String get commonEdit => 'Edytuj';

  @override
  String get commonReply => 'Odpowiedz';

  @override
  String get commonSend => 'Wyślij';

  @override
  String get commonClose => 'Zamknij';

  @override
  String get commonRetry => 'Ponów';

  @override
  String get commonLoading => 'Ładowanie…';

  @override
  String get commonError => 'Błąd';

  @override
  String get commonOnline => 'online';

  @override
  String get commonOffline => 'offline';

  @override
  String get commonOnlineCap => 'Online';

  @override
  String get commonUser => 'Użytkownik';

  @override
  String get commonPlayer => 'Gracz';

  @override
  String get commonAboutMe => 'O mnie';

  @override
  String get commonBack => 'Wstecz';

  @override
  String get commonAccept => 'Akceptuj';

  @override
  String get commonDecline => 'Odrzuć';

  @override
  String get commonCreating => 'Tworzenie…';

  @override
  String get commonSearching => 'Szukanie…';

  @override
  String get commonInsufficientCoins => 'Za mało monet';

  @override
  String get commonNotFound => 'Nie znaleziono';

  @override
  String get commonServerErrorShort => 'Błąd serwera';

  @override
  String get commonForbidden => 'Brak dostępu';

  @override
  String get commonUserBlocked => 'Użytkownik zablokowany';

  @override
  String get commonUserNotFound => 'Nie znaleziono użytkownika';

  @override
  String get commonGenericError => 'Coś poszło nie tak. Spróbuj ponownie.';

  @override
  String get apiErrWrongGameType => 'Nieprawidłowy typ gry';

  @override
  String get apiErrWrongGameTypeOrState => 'Nieprawidłowy typ lub stan gry';

  @override
  String get apiErrLobbyFull => 'Lobby jest pełne';

  @override
  String get apiErrBadState => 'Nieprawidłowy stan gry';

  @override
  String get apiErrIllegalMove => 'Niedozwolony ruch';

  @override
  String get apiErrUnknownMoveType => 'Nieznany typ ruchu';

  @override
  String get apiErrNoOpponents => 'Brak przeciwników';

  @override
  String get apiErrNoOpponentsRematch => 'Brak przeciwników do rewanżu';

  @override
  String get apiErrAlreadyInLobby => 'Już jesteś w tym lobby';

  @override
  String get apiErrGameNotActive => 'Gra nie jest aktywna';

  @override
  String get apiErrNotInBattle => 'To nie jest faza walki';

  @override
  String get apiErrNotInSetup => 'To nie jest faza ustawiania';

  @override
  String get apiErrAlreadyReady => 'Już jesteś gotowy';

  @override
  String get apiErrAlreadyForfeited => 'Już się poddałeś';

  @override
  String get apiErrYouHaveForfeited => 'Poddałeś się';

  @override
  String get apiErrNoDrawOffer => 'Brak oferty remisu';

  @override
  String get apiErrDrawOnlyPvp => 'Remis tylko przeciwko graczowi';

  @override
  String get apiErrDrawOnly1v1 => 'Remis tylko w 1 na 1';

  @override
  String get apiErrDrawVsBot => 'Remis niedostępny przeciwko botowi';

  @override
  String get apiErrDrawMultiplayer => 'Remis niedostępny w trybie wielu graczy';

  @override
  String get apiErrDeck24TwoPlayers => 'Talia 24 jest tylko dla 2 graczy';

  @override
  String get apiErrDeck52ThreeOrFour => 'Talia 52 jest dla 3 lub 4 graczy';

  @override
  String get apiErrAccountFrozen => 'Konto jest zamrożone';

  @override
  String get apiErrTurnTimeInvalid => 'Czas na ruch musi wynosić 0, 20, 60 lub 600 sekund';

  @override
  String get timeJustNow => 'przed chwilą';

  @override
  String get timeYesterday => 'wczoraj';

  @override
  String timeMinutesAgo(int count) {
    return '$count min temu';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count godz. temu';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count dn. temu';
  }

  @override
  String get timeWeekAgo => 'tydzień temu';

  @override
  String timeWeeksAgo(int count) {
    return '$count tyg. temu';
  }

  @override
  String get timeMonthAgo => 'miesiąc temu';

  @override
  String timeMonthsAgo(int count) {
    return '$count mies. temu';
  }

  @override
  String get timeYearAgo => 'rok temu';

  @override
  String timeYearsAgo(int count) {
    return '$count lat temu';
  }

  @override
  String get weekdaySun => 'niedz.';

  @override
  String get weekdayMon => 'pon.';

  @override
  String get weekdayTue => 'wt.';

  @override
  String get weekdayWed => 'śr.';

  @override
  String get weekdayThu => 'czw.';

  @override
  String get weekdayFri => 'pt.';

  @override
  String get weekdaySat => 'sob.';

  @override
  String get monthJan => 'sty';

  @override
  String get monthFeb => 'lut';

  @override
  String get monthMar => 'mar';

  @override
  String get monthApr => 'kwi';

  @override
  String get monthMay => 'maj';

  @override
  String get monthJun => 'cze';

  @override
  String get monthJul => 'lip';

  @override
  String get monthAug => 'sie';

  @override
  String get monthSep => 'wrz';

  @override
  String get monthOct => 'paź';

  @override
  String get monthNov => 'lis';

  @override
  String get monthDec => 'gru';

  @override
  String get homeAchievements => 'Osiągnięcia';

  @override
  String get homeAchievementsSubtitle => 'Twoje wyniki w grach';

  @override
  String get homeAchievementsRewards => 'Dostępne nagrody do odebrania';

  @override
  String get homeCoins => 'Monety';

  @override
  String get homeCoinsSubtitle => 'Saldo i nagrody';

  @override
  String get homeCoinsDailyReward => 'Dostępna nagroda za logowanie';

  @override
  String get homeItems => 'Przedmioty';

  @override
  String get homeItemsInventory => 'Twój ekwipunek';

  @override
  String get homeItemsGifted => 'Ktoś podarował Ci kolekcję';

  @override
  String get homeItemsIncome => 'Dochód z kolekcji gotowy do odebrania';

  @override
  String get homeShop => 'Sklep';

  @override
  String get homeShopSubtitle => 'Emoji, stawki, kolekcje';

  @override
  String get gamesTitle => 'Gry';

  @override
  String get gamesFindMatch => 'Znajdź grę';

  @override
  String get gamesMyTurn => 'Twoja tura';

  @override
  String get gamesWaiting => 'Oczekiwanie';

  @override
  String get gamesLobbyTab => 'Lobby';

  @override
  String get gamesTicTacToe => 'Kółko i krzyżyk';

  @override
  String get gamesDurak => 'Durak';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => 'Obróć';

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
  String get gamesNardy => 'Nardy';

  @override
  String get gamesNardyModeShort => 'Krótkie';

  @override
  String get gamesNardyModeLong => 'Długie';

  @override
  String get gamesCheckers => 'Warcaby';

  @override
  String get gamesCheckersModeRussian => 'Rosyjskie';

  @override
  String get gamesCheckersModeEnglish => 'Angielskie';

  @override
  String get gamesCheckersModeGiveaway => 'Poddawki';

  @override
  String get gamesCheckersModeCorners => 'Kąciki';

  @override
  String get rulesCheckersPlayers => 'Gracze: 2.';

  @override
  String rulesCheckersMode(String mode) {
    return 'Tryb: $mode.';
  }

  @override
  String rulesCheckersTime(String time) {
    return 'Время на ход: $time. Если время вышло — проигрыш.';
  }

  @override
  String get rulesCheckersIntro => 'Plansza 8×8. Dwóch graczy.';

  @override
  String get rulesCheckersPlay => 'Bicie jest obowiązkowe. Damka i pion muszą kontynuować bój, dopóki z pola lądowania można bić dalej — nie wolno stanąć w połowie. Przy kilku kierunkach można wybrać dowolny, niekoniecznie najdłuższy. Pion na ostatniej linii staje się damką.';

  @override
  String get rulesCheckersWin => 'В русских шашках побеждает тот, кто съел все шашки соперника или лишил его хода. В поддавках наоборот: кто не может ходить — выигрывает.';

  @override
  String get rulesCheckersOfflineBot => 'Офлайн: партия против бота.';

  @override
  String get rulesCheckersPlayRussian => 'Warcaby rosyjskie: po 12 pionów na ciemnych polach. Piony chodzą po skosie do przodu, a bicie jest do przodu i do tyłu. Damki latają na dowolną liczbę pól. Bicie jest obowiązkowe: nie wolno przerwać, jeśli można kontynuować, ale przy kilku kierunkach wybierasz dowolny, niekoniecznie najdłuższy. Wygrywa ten, kto zbije wszystkie piony albo pozbawi przeciwnika ruchów.';

  @override
  String get rulesCheckersPlayEnglish => 'Warcaby angielskie: po 12 pionów. Piony chodzą i biją tylko do przodu po skosie. Damki chodzą o jedno pole w dowolną stronę. Bicie jest obowiązkowe. Wygrywa ten, kto zbije wszystkie piony albo pozbawi przeciwnika ruchów.';

  @override
  String get rulesCheckersPlayGiveaway => 'Poddawki: te same ruchy co w warcabach rosyjskich, ale cel jest odwrotny — oddać wszystkie piony albo zostać bez ruchu. Bicie nadal jest obowiązkowe.';

  @override
  String get rulesCheckersPlayCorners => 'Kąciki: piony stoją w przeciwległych rogach. Chodzą na sąsiednie puste pole w poziomie lub pionie albo przeskakują dowolny pion, nie zbijając go. Cel to przenieść wszystkie swoje piony do rogu przeciwnika.';

  @override
  String get rulesCheckersPlayCornersNoReturn => 'Pion, który opuścił swój róg startowy, nie może do niego wrócić.';

  @override
  String get rulesCheckersPlayCornersLeaveHome => 'Piony, które jeszcze nie wyszły z domu, muszą go opuścić w ciągu pierwszych 25 ruchów gracza.';

  @override
  String get rulesCheckersDrawRussian => 'Remis, gdy pozycja powtórzy się trzykrotnie albo przez 15 ruchów każdej strony chodzą tylko damki bez bicia — także 2 na 2.';

  @override
  String get rulesCheckersDrawEnglish => 'Remis przy trzykrotnym powtórzeniu, po 40 ruchach bez bicia i ruchu piona albo przy jednej damce na damkę.';

  @override
  String get rulesCheckersDrawGiveaway => 'Remis przy trzykrotnym powtórzeniu albo 15 ruchach damkami bez bicia.';

  @override
  String get rulesCheckersDrawCorners => 'Remis przy trzykrotnym powtórzeniu albo 25 ruchach każdej strony bez nowej figury w docelowym rogu.';

  @override
  String get checkersDrawRepetition => 'Remis — pozycja powtórzyła się trzykrotnie';

  @override
  String get checkersDrawNoProgress => 'Remis — ruchy nie prowadzą do zwycięstwa';

  @override
  String get checkersDrawInsufficient => 'Remis — za mało sił do zwycięstwa';

  @override
  String get rulesNardyTitle => 'Nardy — zasady';

  @override
  String get rulesNardyPlayers => 'Gracze: 2.';

  @override
  String rulesNardyMode(String mode) {
    return 'Tryb: $mode.';
  }

  @override
  String get rulesNardyIntro => 'Plansza z 24 pól, po 15 pionków. Dwie kości: wszystkie oczka jednym pionkiem albo każdą kością osobno.';

  @override
  String get rulesNardyPlayShort => 'Krótkie nardy: idziecie naprzeciw i możecie zbijać samotne pionki. zbity idzie na bar i musi wejść ponownie. Gdy wszystkie są w domu, zdejmujecie je.';

  @override
  String get rulesNardyPlayLong => 'Długie nardy: obaj startują z jednej głowy i idą w tę samą stronę. Z głowy w turze wychodzi najwyżej jeden pionek. Zbijać nie wolno. Gdy wszystkie są w domu, zdejmujecie je.';

  @override
  String get rulesNardyWin => 'Wygrywa ten, kto pierwszy zdejmie wszystkie pionki.';

  @override
  String get rulesNardySixPrime => 'Nie możesz zamknąć sześciu pól z rzędu, dopóki nie minie ich żaden pionek przeciwnika.';

  @override
  String get nardyRoll => 'Rzuć';

  @override
  String get nardySkipTurn => 'Pomiń turę';

  @override
  String get nardyUndoMove => 'Cofnij';

  @override
  String get nardyDoneTurn => 'Gotowe';

  @override
  String get nardyAutoConfirm => 'Autopotwierdzenie';

  @override
  String get nardyAutoConfirmHint => 'Po wszystkich ruchach tura przechodzi automatycznie';

  @override
  String get nardyLayoutToggle => 'Zmień układ';

  @override
  String get nardyNoMoves => 'Brak ruchów';

  @override
  String get nardyYourRoll => 'Twój rzut';

  @override
  String get nardyPipsShort => 'Zostało:';

  @override
  String get nardyYouWonMars => 'Wygrana — gammon!';

  @override
  String get nardyYouLostMars => 'Porażka — gammon';

  @override
  String get rulesNardyOfflineBot => 'Offline: gra z botem.';

  @override
  String rulesUnoPlayers(int players) {
    return 'Gracze: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'Gra przeciwko botowi, bez limitu czasu na ruch.';

  @override
  String get rulesUnoIntro => 'Każdy dostaje 7 kart. Zagraj kartę tego samego koloru lub tej samej wartości (cyfra albo ta sama akcja).';

  @override
  String get rulesUnoPlay => 'Pominięcie — następny traci turę. Zmiana kierunku we dwójkę działa jak pominięcie. +2 kładzie się tylko na +2, a +4 tylko na +4: kara się sumuje (dwa +2 — następny dobiera 4). +2 na +4 kłaść nie wolno. Kto nie odpowie, dobiera cały stos i traci turę. Dwie takie same niedzika karty (np. dwie żółte 8) zrzuca się razem: zagraj jedną — druga leci automatycznie.';

  @override
  String get rulesUnoWild => 'Czarna karta ustala nowy kolor. +4 tylko gdy nie masz karty bieżącego koloru. Przeciwnik może zakwestionować: jeśli +4 było legalne, dobiera 6; jeśli nie — autor +4 dobiera 4, a kwestionujący gra.';

  @override
  String get rulesUnoDraw => 'Bez pasującej karty dobierz jedną z talii. Jeśli pasuje, zagraj ją od razu albo zatrzymaj i oddaj turę. Nie dobierasz, gdy masz legalny ruch.';

  @override
  String get rulesUnoWin => 'We dwóch do 100 punktów, przy 3+ graczach do 200. Rundę wygrywa gracz, który zrzuci wszystkie karty.';

  @override
  String get rulesUnoCall => 'Gdy zostaje jedna karta, od razu naciśnij „Uno!”. Przeciwnicy mogą złapać cię za zapomniane Uno dopiero po sekundzie — wtedy dobierasz 2 karty.';

  @override
  String get rulesUnoScoring => 'Kto pierwszy zrzuci wszystkie karty, wygrywa rundę i dostaje punkty za ręce przeciwników: cyfry według wartości, akcje 20, czarne 50. We dwóch do 100, przy 3+ graczach do 200.';

  @override
  String get unoColorRed => 'Czerwony';

  @override
  String get unoColorYellow => 'Żółty';

  @override
  String get unoColorGreen => 'Zielony';

  @override
  String get unoColorBlue => 'Niebieski';

  @override
  String get unoDraw => 'Dobierz';

  @override
  String get unoKeep => 'Zatrzymaj';

  @override
  String get unoSayUno => 'Uno!';

  @override
  String get unoChallengeUno => 'Rzuć wyzwanie Uno';

  @override
  String get unoChallengeWd4 => 'Rzuć wyzwanie +4';

  @override
  String get unoChooseColor => 'Wybierz kolor';

  @override
  String get unoDrawPile => 'Stos dobierania';

  @override
  String get unoDiscardPile => 'Stos kart';

  @override
  String unoCardsCount(int count) {
    return 'Karty: $count';
  }

  @override
  String unoScore(int score) {
    return 'Punkty: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'Runda $round · do $target';
  }

  @override
  String get unoYourTurn => 'Twój ruch';

  @override
  String get unoWaitingTurn => 'Ruch przeciwnika';

  @override
  String get unoChooseColorHint => 'Wybierz kolor dla jokera';

  @override
  String get unoWd4Hint => 'Dobierz 4 karty albo podważ Wild +4';

  @override
  String get unoDrawnHint => 'Zagraj dobraną kartę albo ją zatrzymaj';

  @override
  String get unoPlayHint => 'Zagraj pasujący kolor lub wartość';

  @override
  String get unoDrawHint => 'Brak pasującej karty — dobierz ze stosu';

  @override
  String unoPendingDraw(int count) {
    return '+$count kart';
  }

  @override
  String get unoYouWon => 'Wygrywasz mecz!';

  @override
  String get unoYouLost => 'Mecz zakończony';

  @override
  String get unoYouLostTimeout => 'Przegrałeś przez czas';

  @override
  String unoWinner(String name) {
    return 'Zwycięzca: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name wygrywa rundę';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'Dalej';

  @override
  String get unoRoundScoresTitle => 'Punkty rundy';

  @override
  String get unoDirectionClockwise => 'Zgodnie z ruchem wskazówek';

  @override
  String get unoDirectionCounterclockwise => 'Przeciwnie do ruchu wskazówek';

  @override
  String get unoErrStackSameOnly => 'Na +2 można położyć tylko +2, na +4 tylko +4. +2 na +4 jest zabronione.';

  @override
  String get unoErrCatchTooEarly => 'Poczekaj sekundę — wciąż mogą powiedzieć „Uno”.';

  @override
  String get unoErrCallTooLate => 'Nie można już powiedzieć „Uno”. Następny gracz już wykonał ruch.';

  @override
  String get gamesInDevelopment => 'W trakcie tworzenia';

  @override
  String rulesPokerPlayers(int players) {
    return 'Gracze: $players.';
  }

  @override
  String get rulesPokerIntro => 'Texas Hold’em. Każdy dostaje 2 karty własne; na stół wychodzi 5 kart wspólnych.';

  @override
  String get rulesPokerPlay => 'Rundy obstawiania: preflop, flop, turn i river. Fold, call, bet lub raise.';

  @override
  String get rulesPokerWin => 'Wygrywa najlepszy układ z pięciu kart (własne + wspólne) albo ostatni po foldach.';

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
  String get pokerCombinationsTitle => 'Układy';

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
  String get gamesRules => 'Zasady';

  @override
  String get gamesRulesTitle => 'Zasady gry';

  @override
  String get gamesCreate => 'Utwórz grę';

  @override
  String get gamesJoin => 'Dołącz';

  @override
  String get gamesOpponentTurn => 'Tura przeciwnika';

  @override
  String get gamesCurrentGame => 'Bieżąca gra';

  @override
  String get gamesInvitedYou => 'Zaproszono Cię';

  @override
  String get gamesTurnTime => 'Czas na ruch';

  @override
  String get gamesGridSize => 'Rozmiar planszy';

  @override
  String get gamesSwapSides => 'Zmiana stron';

  @override
  String get gamesNoCenter => 'Bez startu na środku';

  @override
  String get gamesObservation => 'Obserwacja';

  @override
  String get gamesObservationHint => 'Możesz oglądać do końca partii';

  @override
  String get gamesFinishCurrentFirst => 'Najpierw dokończ bieżącą grę';

  @override
  String get gamesVariantClassic => 'Klasyczny';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 graczy';

  @override
  String get gamesVariantMulti4 => '4 graczy';

  @override
  String get gamesDurakModePodkidnoi => 'Dokładany';

  @override
  String get gamesDurakModePerevodnoi => 'Przerzutowy';

  @override
  String get gamesDurakDeck24 => '24 karty';

  @override
  String get gamesDurakDeck36 => '36 kart';

  @override
  String get gamesDurakDeck52 => '52 karty';

  @override
  String rulesDurakMode(String mode) {
    return 'Tryb: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'Gracze: $players. Talia: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Gra przeciwko botowi, bez stawek i limitu czasu.';

  @override
  String get rulesDurakAttack => 'Atakujący kładzie karty; obrońca je bije (tym samym kolorem wyższą lub atutem). Atut bije tylko wyższy atut.';

  @override
  String get rulesDurakBeat => 'Gdy wszystkie karty są bite, atakujący mówi «Bito», a karty idą na stos. W przeciwnym razie obrońca bierze wszystko ze stołu.';

  @override
  String get rulesDurakLoser => 'Przegrywa ten, kto na końcu ma karty — «dureń».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Gracze $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Lobby $name';
  }

  @override
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Gra prywatna';

  @override
  String get lobbySearchingOpponent => 'Szukanie przeciwnika…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Szukają tej gry: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Czekamy, aż ktoś naciśnie „Znajdź grę” lub „Dołącz”';

  @override
  String get lobbyInviteTitle => 'Zaproszenie do gry';

  @override
  String get lobbyInvitedToPlay => 'Zaproszono Cię do gry';

  @override
  String get lobbyEnterGame => 'Wejdź do gry';

  @override
  String get lobbyGone => 'Lobby już niedostępne';

  @override
  String get lobbyInvite => 'Zaproś';

  @override
  String get lobbyInviteSent => 'Zaproszenie wysłane';

  @override
  String get lobbyCopyLink => 'Udostępnij link do gry';

  @override
  String get lobbyLinkCopied => 'Link skopiowany';

  @override
  String get lobbyNoFriendsOnline => 'Brak znajomych online. Udostępnij link do gry powyżej lub poczekaj, aż znajomi będą w sieci.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Przeciwnik';

  @override
  String get gameYouWon => 'Wygrana!';

  @override
  String get gameYouLost => 'Przegrałeś';

  @override
  String get gameYouWonOpponentLeft => 'Wygrana — przeciwnik wyszedł';

  @override
  String get gameYouWonOpponentTimeout => 'Wygrana — przeciwnikowi skończył się czas';

  @override
  String get gameDraw => 'Remis';

  @override
  String get gameExitTitle => 'Wyjdź z gry';

  @override
  String get gameExitConfirm => 'Jeśli wyjdziesz, przegrasz. Wyjść mimo to?';

  @override
  String get gameStay => 'Zostań';

  @override
  String get gameLeave => 'Wyjdź';

  @override
  String get gameSurrender => 'Poddaj się';

  @override
  String get gameSurrenderTitle => 'Poddać się?';

  @override
  String get gameSurrenderConfirm => 'Przegrasz partię i monety stawki.';

  @override
  String get gameOfferDraw => 'Zaproponuj remis';

  @override
  String get gameOfferDrawTitle => 'Zaproponować remis?';

  @override
  String get gameOfferDrawConfirm => 'Przeciwnik może przyjąć lub odrzucić remis.';

  @override
  String get gameAcceptDrawTitle => 'Przyjąć remis?';

  @override
  String get gameAcceptDrawConfirm => 'Partia zakończy się remisem.';

  @override
  String get gameDrawOffered => 'Przeciwnik proponuje remis';

  @override
  String get gameConnecting => 'Łączenie z grą…';

  @override
  String get gameWaitingOpponent => 'Oczekiwanie na przeciwnika';

  @override
  String get gameRematchOffer => 'Przeciwnik proponuje rewanż';

  @override
  String get gameRematchDeclined => 'Przeciwnik odrzucił rewanż';

  @override
  String get gameRematch => 'Rewanż';

  @override
  String get gameOtherOpponent => 'Inny przeciwnik';

  @override
  String get gameSwapSidesAction => 'Zmień strony';

  @override
  String get gameWriteMessage => 'Napisz wiadomość';

  @override
  String get chatsTitle => 'Czaty';

  @override
  String get chatsEmpty => 'Brak czatów.\nNaciśnij ikonę u góry po prawej, aby wybrać znajomego i rozpocząć rozmowę.';

  @override
  String get chatsNewChat => 'Nowy czat';

  @override
  String get chatsNoMessages => 'Brak wiadomości';

  @override
  String get chatsClearTitle => 'Wyczyścić rozmowę?';

  @override
  String get chatsClearDesc => 'Czat zostanie trwale usunięty.';

  @override
  String get chatsClearConfirm => 'Wyczyść';

  @override
  String get chatsBlockTitle => 'Zablokować tego użytkownika?';

  @override
  String get chatsBlockDesc => 'Nie będziecie już mogli pisać do siebie. Czat i znajomość zostaną usunięte.';

  @override
  String get chatsBlockConfirm => 'Zablokuj';

  @override
  String get chatsBlockedUsers => 'Zablokowani użytkownicy';

  @override
  String get chatsUnblock => 'Odblokuj';

  @override
  String get chatDialog => 'Czat';

  @override
  String get chatEmpty => 'Brak wiadomości.\nWyślij pierwszą.';

  @override
  String get chatMessageHint => 'Wiadomość';

  @override
  String get chatPaste => 'Wklej';

  @override
  String get chatEmoji => 'Emoji';

  @override
  String get chatBuyEmojiHint => 'Kup emoji w sklepie na ekranie głównym';

  @override
  String get chatEditing => 'Edycja';

  @override
  String get chatToday => 'Dzisiaj';

  @override
  String get chatYesterday => 'Wczoraj';

  @override
  String get chatFriendsOnly => 'Tekst tylko dla znajomych';

  @override
  String get emojiGroupEmotions => 'Emocje';

  @override
  String get emojiGroupGame => 'Gry';

  @override
  String get emojiGroupFlags => 'Flagi';

  @override
  String get emojiGroupAnimals => 'Zwierzęta';

  @override
  String get emojiGroupFood => 'Jedzenie';

  @override
  String get emojiGroupTravel => 'Podróże';

  @override
  String get emojiGroupParty => 'Świętowanie';

  @override
  String get emojiGroupObjects => 'Przedmioty';

  @override
  String get friendsTitle => 'Znajomi';

  @override
  String get friendsTabFriends => 'Znajomi';

  @override
  String get friendsTabIncoming => 'Przychodzące';

  @override
  String get friendsTabOutgoing => 'Wychodzące';

  @override
  String get friendsAdd => 'Dodaj znajomego';

  @override
  String get friendsRequestSent => 'Zaproszenie wysłane';

  @override
  String get friendsFindTab => 'Znajdź znajomego';

  @override
  String get friendsSearchHint => 'Szukaj po nazwie użytkownika';

  @override
  String get friendsSearchPrompt => 'Użyj wyszukiwania, aby znaleźć nowych znajomych';

  @override
  String get friendsNothingFound => 'Nic nie znaleziono';

  @override
  String get friendsEmpty => 'Nie masz jeszcze znajomych';

  @override
  String get friendsSearchNoMatches => 'Brak znajomych pasujących do wyszukiwania';

  @override
  String get friendsIncomingSearchNoMatches => 'Brak zaproszeń przychodzących dla zapytania';

  @override
  String get friendsOutgoingSearchNoMatches => 'Brak zaproszeń wychodzących dla zapytania';

  @override
  String get friendsNoIncoming => 'Brak przychodzących zaproszeń';

  @override
  String get friendsNoOutgoing => 'Brak wychodzących zaproszeń';

  @override
  String get friendsAlreadyFriends => 'Już jesteście znajomymi';

  @override
  String get friendsRemoveTitle => 'Usunąć ze znajomych?';

  @override
  String get friendsRemoved => 'Usunięto ze znajomych';

  @override
  String get friendsRequestAccepted => 'Zaproszenie zaakceptowane';

  @override
  String get friendsRequestDeclined => 'Zaproszenie odrzucone';

  @override
  String get friendsRequestCancelled => 'Zaproszenie anulowane';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSignInPrompt => 'Zaloguj się na konto';

  @override
  String get profileSignInHint => 'Aby skonfigurować profil osobisty';

  @override
  String get profileEdit => 'Edytuj';

  @override
  String get profileCollections => 'Kolekcje';

  @override
  String get profileAge => 'Wiek';

  @override
  String get profileGender => 'Płeć';

  @override
  String get profileGenderUnset => 'Nie ustawiono';

  @override
  String get profileGenderMale => 'Mężczyzna';

  @override
  String get profileGenderFemale => 'Kobieta';

  @override
  String get profileAvatar => 'Awatar';

  @override
  String get profileUploadPhoto => 'Prześlij zdjęcie';

  @override
  String get profileChangePhoto => 'Zmień avatar';

  @override
  String get shopTitle => 'Sklep';

  @override
  String get shopEmojis => 'Emoji';

  @override
  String get shopEmojisSubtitle => 'Animowane emoji do czatu';

  @override
  String get shopCollections => 'Kolekcje';

  @override
  String get shopCollectionsSubtitle => 'Witryna profilu, prezenty i dochód';

  @override
  String get shopStakes => 'Stawki';

  @override
  String get shopStakesSubtitle => 'Odblokuj wyższe stawki';

  @override
  String get shopEmojisHelp => 'Animowane emotikony do czatu. Kup zestaw i wysyłaj je znajomym.';

  @override
  String get shopCollectionsHelp => 'Zbierz zestaw przedmiotów: pojawiają się w witrynie profilu, można je dawać i sprzedawać. Kompletna kolekcja codziennie daje dodatkowe monety.';

  @override
  String get shopStakesHelp => 'Odblokuj wyższe stawki. Im wyższa stawka, tym większa pula i wygrana.';

  @override
  String get inventoryTitle => 'Przedmioty';

  @override
  String get inventoryEmpty => 'Na razie pusto — zajrzyj do sklepu';

  @override
  String get inventoryFrames => 'Ramki';

  @override
  String get inventoryClaim => 'Odbierz';

  @override
  String get inventorySell => 'Sprzedaj';

  @override
  String get inventoryGift => 'Podaruj';

  @override
  String get messageEdited => 'edytowano';

  @override
  String get messageDeleted => 'Wiadomość usunięta';

  @override
  String get photo => 'Zdjęcie';

  @override
  String get camera => 'Aparat';

  @override
  String get gallery => 'Galeria';

  @override
  String get connectionError => 'Nie udało się połączyć z serwerem.';

  @override
  String get serverError => 'Błąd serwera. Spróbuj ponownie później.';

  @override
  String get sessionExpired => 'Sesja wygasła. Zaloguj się ponownie.';

  @override
  String get errNoInternet => 'Brak połączenia z internetem.';

  @override
  String get errTimeout => 'Przekroczono limit czasu. Spróbuj ponownie.';

  @override
  String get errGamesUnavailable => 'Gry są chwilowo niedostępne';

  @override
  String get errSettingsSaveFailed => 'Nie udało się zapisać ustawienia';

  @override
  String get errPushPermission => 'Zezwól na powiadomienia w ustawieniach przeglądarki lub systemu.';

  @override
  String get balanceTitle => 'Saldo';

  @override
  String get coinBronze => 'Brąz';

  @override
  String get coinSilver => 'Srebro';

  @override
  String get coinGold => 'Złoto';

  @override
  String get coinDiamond => 'Diament';

  @override
  String get balanceZeroBronze => '0 brązowych';

  @override
  String balanceBronzes(int count) {
    return '$count brązowych';
  }

  @override
  String balanceSilvers(int count) {
    return '$count srebrnych';
  }

  @override
  String balanceGolds(int count) {
    return '$count złotych';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count diamentów';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/dzień';
  }

  @override
  String get balanceAbbrBronze => 'br';

  @override
  String get balanceAbbrSilver => 'sr.';

  @override
  String get balanceAbbrGold => 'zł.';

  @override
  String get commonBackHome => 'Wróć do strony głównej';

  @override
  String get commonCopied => 'Skopiowano';

  @override
  String get commonClear => 'Wyczyść';

  @override
  String get commonTryLater => 'Spróbuj ponownie później.';

  @override
  String get commonTryRefresh => 'Spróbuj odświeżyć stronę.';

  @override
  String get coinsTitle => 'Monety';

  @override
  String get coinsLoginReward => 'Nagroda za logowanie';

  @override
  String get coinsLoginAvailableToday => 'Dzisiejsza nagroda dostępna';

  @override
  String get coinsLoginStreak => 'Codzienna seria logowań';

  @override
  String get coinsFriendReward => 'Nagroda za znajomego';

  @override
  String get coinsTasks => 'Zadania';

  @override
  String get coinsTasksSubtitle => 'Nagrody za profil, znajomych i gry';

  @override
  String get coinsTasksRewards => 'Dostępne nagrody do odebrania';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount za rejestrację przez Twój link';
  }

  @override
  String get coinsLoadRewardsFailed => 'Nie udało się wczytać nagród';

  @override
  String get coinsClaimReward => 'Odbierz nagrodę';

  @override
  String get coinsAlreadyClaimed => 'Już odebrano';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · dziś';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · jeszcze 1 dzień';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · jeszcze $remaining';
  }

  @override
  String get coinsInviteFriend => 'Zaproś znajomego';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount za każdego, kto zarejestruje się przez Twój link';
  }

  @override
  String get coinsCopyLink => 'Kopiuj link';

  @override
  String get coinsHowItWorks => 'Jak to działa';

  @override
  String get coinsHowStep1 => 'Skopiuj link i wyślij znajomemu';

  @override
  String get coinsHowStep2 => 'Znajomy rejestruje się przez ten link';

  @override
  String coinsHowStep3(String amount) {
    return 'Otrzymujesz $amount';
  }

  @override
  String get achievementsTitle => 'Osiągnięcia';

  @override
  String achievementsProgress(String progress) {
    return 'Postęp: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Ramka otrzymana';

  @override
  String get achievementsClaimed => 'Otrzymano';

  @override
  String get achievementsOpenFrame => 'Otwórz ramkę';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Czy na pewno chcesz usunąć $name ze znajomych?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Usuń';

  @override
  String get friendsRemove => 'Usuń ze znajomych';

  @override
  String get friendsAcceptRequest => 'Zaakceptuj zaproszenie';

  @override
  String get friendsDeclineRequest => 'Odrzuć zaproszenie';

  @override
  String get friendsCancelRequest => 'Anuluj zaproszenie';

  @override
  String get friendsSendRequest => 'Wyślij zaproszenie do znajomych';

  @override
  String get friendsRequestAlreadySent => 'Zaproszenie już wysłane';

  @override
  String get friendsIncomingStatus => 'Zaproszenie przychodzące';

  @override
  String get friendsOutgoingStatus => 'Zaproszenie wychodzące';

  @override
  String get friendsNotFriends => 'Nie jesteście znajomymi';

  @override
  String get friendsCollapseSearch => 'Zwiń wyszukiwanie';

  @override
  String get friendsExpandSearch => 'Pokaż wyszukiwanie';

  @override
  String get friendsLoadFailed => 'Nie udało się wczytać znajomych';

  @override
  String friendsSince(String date) {
    return 'Znajomi od: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Zaproszenie przychodzące: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Zaproszenie wychodzące: $date';
  }

  @override
  String get userInfoTitle => 'Informacje o użytkowniku';

  @override
  String profileAgeYears(int age) {
    return '$age lat';
  }

  @override
  String get shopBuy => 'Kup';

  @override
  String get shopBuyTitle => 'Kupić?';

  @override
  String get shopBuyStakeTitle => 'Kupić stawkę?';

  @override
  String get shopBuyEmojiTitle => 'Kupić emoji?';

  @override
  String get shopBuyCollectionTitle => 'Kupić kolekcję?';

  @override
  String shopPrice(String price) {
    return 'Cena: $price';
  }

  @override
  String get shopOwned => 'Kupione';

  @override
  String get shopHave => 'Masz';

  @override
  String get shopEmpty => 'Na razie pusto';

  @override
  String shopPurchased(String title) {
    return 'Kupiono $title';
  }

  @override
  String get shopEmojiUses => 'Otrzymasz: 10 użyć';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 użyć';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 użyć';
  }

  @override
  String get shopBuyTen => 'Kup · 10 szt.';

  @override
  String shopDailyIncome(String amount) {
    return 'Dochód: $amount';
  }

  @override
  String get shopBuyOnce => 'Zakup jednorazowy';

  @override
  String get shopSellRefund => 'Sprzedaż zwraca 80% kosztów';

  @override
  String shopCollectionAdded(String title) {
    return '$title dodano do profilu';
  }

  @override
  String shopSetBonus(int percent) {
    return 'bonus zestawu +$percent%';
  }

  @override
  String get shopSetComplete => 'Ukończono';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Zebrano · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Sprzedać?';

  @override
  String inventorySellDesc(String amount) {
    return 'Otrzymasz $amount';
  }

  @override
  String inventorySold(String amount) {
    return 'Sprzedano: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Najpierw dodaj znajomych';

  @override
  String get inventoryGiftTitle => 'Podarować kolekcję?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'Podarować „$title” użytkownikowi $name?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Podarowano: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'Gracz już posiada ten przedmiot';

  @override
  String get inventoryGiftSelf => 'Nie możesz podarować sobie';

  @override
  String get inventoryGiftNotOwned => 'Tego przedmiotu nie ma w twoim ekwipunku';

  @override
  String get inventoryLoadFailed => 'Nie udało się wczytać przedmiotów';

  @override
  String get inventoryNoCollections => 'Brak kolekcji — kup w sklepie';

  @override
  String get inventoryNoEmojis => 'Brak emoji — kup w sklepie';

  @override
  String get inventoryNoFrames => 'Brak ramek — wygraj 10 gier w lidze (osiągnięcia)';

  @override
  String get inventoryNoStakes => 'Brak kupionych stawek';

  @override
  String inventoryEmojiLeft(int count) {
    return 'Pozostało $count';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Dochód: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Dochód jutro: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Gotowe';

  @override
  String get inventoryIncomeTomorrowLabel => 'Jutro';

  @override
  String inventoryStakeGold(String amount) {
    return 'Możesz stawiać $amount złota';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'Możesz stawiać $amount srebra';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'Otrzymano +$amount';
  }

  @override
  String get chatsLoadFailed => 'Nie udało się wczytać czatów';

  @override
  String get chatsLoadListFailed => 'Nie udało się wczytać listy';

  @override
  String get chatsBlockedEmpty => 'Lista jest pusta';

  @override
  String chatsBlockedAt(String date) {
    return 'Zablokowano: $date';
  }

  @override
  String get chatsCreateFailed => 'Nie udało się utworzyć czatu';

  @override
  String get chatsNeedFriendsFirst => 'Najpierw dodaj znajomych, potem możesz otworzyć czat.';

  @override
  String get chatsFriendsNotFound => 'Nie znaleziono znajomych';

  @override
  String get chatsFindFriendHint => 'Znajdź znajomego po nicku';

  @override
  String get chatsSelectChat => 'Wybierz czat';

  @override
  String get chatsSelectHint => 'Wybierz rozmowę z listy po lewej';

  @override
  String get chatEditFailed => 'Nie udało się edytować wiadomości';

  @override
  String get chatSendFailed => 'Nie udało się wysłać wiadomości';

  @override
  String get chatDeleteFailed => 'Nie udało się usunąć wiadomości';

  @override
  String get chatEmojiSendFailed => 'Nie udało się wysłać emoji';

  @override
  String get chatLoadFailed => 'Nie udało się wczytać wiadomości';

  @override
  String get chatBackToGame => 'Wróć do gry';

  @override
  String get chatBackToChats => 'Wróć do czatów';

  @override
  String get chatActions => 'Akcje czatu';

  @override
  String get chatAutoTranslate => 'Auto-tłumaczenie';

  @override
  String get chatScrollToEnd => 'Do końca rozmowy';

  @override
  String chatReplyingTo(String name) {
    return 'Odpowiedź do $name';
  }

  @override
  String get chatGift => 'Prezent';

  @override
  String get chatCollection => 'Kolekcja';

  @override
  String get chatGiftCollection => 'Prezent · kolekcja';

  @override
  String get chatThisUser => 'tego użytkownika';

  @override
  String get gamesLobbyLoadFailed => 'Nie udało się wczytać lobby.';

  @override
  String get gamesTapChangeStake => 'Dotknij, aby zmienić stawkę';

  @override
  String get gamesTapChangeTurnTime => 'Dotknij, aby zmienić czas na ruch';

  @override
  String get gamesTapChangeGrid => 'Dotknij, aby zmienić rozmiar siatki';

  @override
  String get gamesSwapSidesHint => 'O może stać się X po 1. ruchu';

  @override
  String get gamesNoCenterHint => 'Pierwszy ruch nie może być na środku';

  @override
  String get lobbyInviteSentShort => 'Wysłano';

  @override
  String get lobbySearchShort => 'Szukaj';

  @override
  String get lobbySearchPlayers => 'Szukaj graczy';

  @override
  String get lobbyInviteDeclinedShort => 'Odrzucono';

  @override
  String get lobbyInvitesSentWaiting => 'Zaproszenia wysłane. Czekaj na odpowiedź.';

  @override
  String get lobbyLinkCopiedHint => 'Wklej go na czacie lub w wiadomości do znajomego';

  @override
  String get lobbyCopyLinkHint => 'Kopiuj link do schowka';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name zaprasza Cię do gry';
  }

  @override
  String gameOpponentWon(String name) {
    return 'Wygrał $name';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Czas minął. Wygrał $name';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String get adminTitle => 'Panel admina';

  @override
  String get tournamentsTitle => 'Turnieje';

  @override
  String get profileAgeInvalid => 'Podaj wiek od 1 do 111';

  @override
  String get profileSaveFailed => 'Nie udało się zapisać profilu';

  @override
  String get profileNameHint => 'Litery łacińskie, cyfry, _ do 10 znaków';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'Od 1 do 111';

  @override
  String get profileAboutHint => 'Do 100 znaków (opcjonalnie)';

  @override
  String get profileProcessingPhoto => 'Przetwarzanie zdjęcia…';

  @override
  String get profileCropTitle => 'Wybierz obszar awatara';

  @override
  String get profileCropHint => 'Powiększ i przesuń zdjęcie';

  @override
  String get profileApply => 'Zastosuj';

  @override
  String get profilePreparing => 'Przygotowanie…';

  @override
  String get profileGalleryTitle => 'Zdjęcia';

  @override
  String get profileGalleryAdd => 'Dodaj zdjęcie';

  @override
  String get profileMakePrimary => 'Ustaw jako główne';

  @override
  String get profilePhotoDelete => 'Usuń zdjęcie';

  @override
  String get profilePhotosLimit => 'Można dodać maksymalnie 3 zdjęcia';

  @override
  String get profilePhotosEmpty => 'Brak zdjęć';

  @override
  String get profilePhotoUploadFailed => 'Nie udało się dodać zdjęcia';

  @override
  String get profilePhotoDeleteFailed => 'Nie udało się usunąć zdjęcia';

  @override
  String get profilePhotoTooLarge => 'Zdjęcie jest za duże';

  @override
  String get profileSetPrimaryFailed => 'Nie udało się ustawić jako główne';

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
    return 'Kółko i krzyżyk na planszy $grid. Na przemian; zaczyna X.';
  }

  @override
  String rulesWin(int n) {
    return 'Wygrana: ułóż $n w rzędzie w poziomie, pionie lub po przekątnej.';
  }

  @override
  String get rulesNoTimeLimit => 'Bez limitu czasu na ruch.';

  @override
  String rulesTurnTime(String time) {
    return 'Czas na ruch: $time. Koniec czasu oznacza przegraną.';
  }

  @override
  String rulesStake(String stake) {
    return 'Stawka: $stake. Tyle monet stoi na grze.';
  }

  @override
  String get rulesSwap => 'Zmiana stron: O może zamienić się z X po pierwszym ruchu X.';

  @override
  String get rulesNoCenter => 'Zakaz środka: X nie może zagrać w środek pierwszym ruchem.';

  @override
  String get collectionSetLegends => 'Legendy';

  @override
  String get collectionSetSpace => 'Kosmos';

  @override
  String get collectionSetGems => 'Klejnoty';

  @override
  String get collectionSetParty => 'Święto';

  @override
  String get collectionSetNature => 'Natura';

  @override
  String get collectionSetAdventures => 'Przygody';

  @override
  String collectionCardMeta(String amount) {
    return 'Kolekcja · wystawa · prezent · sprzedaż · +$amount';
  }

  @override
  String get coinsDayOne => 'dzień';

  @override
  String get coinsDayFew => 'dni';

  @override
  String get coinsDayMany => 'dni';

  @override
  String get giftFriendTitle => 'Podaruj przyjacielowi';

  @override
  String photoCount(int count) {
    return 'Zdjęcie ($count)';
  }

  @override
  String photoCountWithText(int count, String text) {
    return 'Zdjęcie ($count): $text';
  }

  @override
  String photoWithText(String text) {
    return 'Zdjęcie: $text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count emoji · po $price';
  }

  @override
  String get chatsExpandPanel => 'Rozwiń panel';

  @override
  String get chatsCollapsePanel => 'Zwiń panel';

  @override
  String get chatReplySourceMissing => 'Nie znaleziono oryginalnej wiadomości';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Stawka $n srebra';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Stawka $n złota';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Odblokowuje stawkę $n srebra';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Odblokowuje stawkę $n złota';
  }

  @override
  String get chatReplySelf => 'sobie';

  @override
  String get chatReplyPeer => 'rozmówcy';

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
  String get statsTitle => 'Statystyki';

  @override
  String get statsLoadFailed => 'Nie udało się wczytać statystyk';

  @override
  String get statsAllGames => 'Wszystkie gry';

  @override
  String get statsEmptyTitle => 'Brak rozegranych partii';

  @override
  String get statsEmptyHint => 'Zagraj pierwszą grę, aby zobaczyć tu statystyki.';

  @override
  String get statsWins => 'Zwycięstwa';

  @override
  String get statsDraws => 'Remisy';

  @override
  String get statsLosses => 'Porażki';

  @override
  String get statsWinRate => 'Procent zwycięstw';

  @override
  String get statsTopWon => 'Najwięcej wygranych z';

  @override
  String get statsTopDrawn => 'Najwięcej remisów z';

  @override
  String get statsTopLost => 'Najwięcej przegranych z';

  @override
  String get statsTimePlayed => 'Czas w grze';

  @override
  String get statsYourScore => 'Twój wynik';

  @override
  String get profileShowStats => 'Pokaż statystyki';

  @override
  String get statsDurationZeroMinutes => '0 min';

  @override
  String get gameYouWonOpponentForfeit => 'Przeciwnik się poddał. Wygrałeś!';

  @override
  String get lobbyLeaveTitle => 'Opuścić lobby?';

  @override
  String get lobbyLeaveConfirm => 'Lobby zostanie usunięte po wyjściu. Zaproszeni znajomi dostaną odmowę.';

  @override
  String get lobbyLeave => 'Opuść';

  @override
  String statsDurationHours(int hours) {
    return '$hours godz.';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours godz. $minutes min';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'Poddałeś się. $name wygrał';
  }

  @override
  String get supportTitle => 'Wsparcie';

  @override
  String get supportUnavailable => 'Wsparcie jest niedostępne';

  @override
  String get supportOpenFailed => 'Nie udało się otworzyć czatu wsparcia';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Przyznano Ci $amount monet';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return 'Odjęto $amount monet';
  }

  @override
  String get coinsCreditCardTitle => 'Przyznano Ci monety';

  @override
  String get coinsClaim => 'Odbierz';

  @override
  String get durakActionPass => 'Pas';

  @override
  String get durakRoleTook => 'Bierze';

  @override
  String get durakRoleBeats => 'Bije';

  @override
  String get durakRoleThrowIn => 'Dokładka';

  @override
  String get durakRoleTurn => 'Tura';

  @override
  String get durakRoleDefends => 'Broni';

  @override
  String get durakStatusTaking => 'Bierze';

  @override
  String get durakHintDefenderTurn => 'Tura obrońcy';

  @override
  String get gameYouEliminated => 'Odpadasz';

  @override
  String gameYouPlaced(int place) {
    return 'Zająłeś $place. miejsce';
  }

  @override
  String get gameOverNeutral => 'Gra zakończona';

  @override
  String gameTurnOf(String name) {
    return 'Tura: $name';
  }

  @override
  String get chatGroupTooltip => 'Czat grupowy';

  @override
  String get lobbyChatNotReady => 'Czat lobby nie jest jeszcze gotowy';

  @override
  String get chatsGroupChat => 'Czat grupowy';

  @override
  String chatsMembersCount(int count) {
    return 'Uczestnicy: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count os.';
  }

  @override
  String get chatsYouSuffix => '(ty)';

  @override
  String get chatTitleDurak3 => 'Durak · 3 graczy';

  @override
  String get chatTitleDurak4 => 'Durak · 4 graczy';

  @override
  String get rulesTttUltimate => 'Ultimate: dziewięć mini-plansz 3×3. Ruch wysyła przeciwnika na daną mini-planszę. Wygrywa linia na meta-planszy.';

  @override
  String get rulesTttMulti3 => '3 graczy: plansza 3×3, trzej gracze (X, O, △). Ułóż linię ze swoich znaków, aby wygrać.';

  @override
  String get rulesTttMulti4 => '4 graczy: plansza 4×4, czterej gracze (X, O, △, □). Ułóż linię ze swoich znaków, aby wygrać.';

  @override
  String get adminUsersTab => 'Użytkownicy';

  @override
  String get adminSupportTab => 'Wsparcie';

  @override
  String get adminSearchHint => 'Szukaj po e-mailu lub nicku';

  @override
  String get adminRoleAdmins => 'Admini';

  @override
  String get adminRoleUsers => 'Użytkownicy';

  @override
  String get adminRoleAll => 'Wszystkie role';

  @override
  String get adminStatusFrozen => 'Zamrożeni';

  @override
  String get adminStatusActive => 'Aktywni';

  @override
  String get adminStatusAny => 'Dowolny status';

  @override
  String get adminOrderDesc => 'Malejąco';

  @override
  String get adminOrderAsc => 'Rosnąco';

  @override
  String adminLoadFailed(String error) {
    return 'Błąd wczytywania: $error';
  }

  @override
  String get adminUsersEmpty => 'Nie znaleziono użytkowników';

  @override
  String get adminSortLastSeen => 'Według ostatniej wizyty';

  @override
  String get adminSortEmail => 'Według e-maila';

  @override
  String get adminSortCreated => 'Według daty rejestracji';

  @override
  String adminBronzeBalance(int amount) {
    return '$amount br.';
  }

  @override
  String get adminRevokeAdmin => 'Usuń admina';

  @override
  String get adminGrantAdmin => 'Nadaj admina';

  @override
  String get adminAdminRevoked => 'Uprawnienia admina odebrane';

  @override
  String get adminAdminGranted => 'Uprawnienia admina nadane';

  @override
  String get adminGrantCoins => 'Przyznaj monety';

  @override
  String get adminWriteSupport => 'Napisz jako wsparcie';

  @override
  String get adminUnfreeze => 'Odmroź';

  @override
  String get adminFreeze => 'Zamroź';

  @override
  String get adminUnfrozen => 'Odmrożono';

  @override
  String get adminFrozenDone => 'Zamrożono';

  @override
  String get adminResetPassword => 'Resetuj hasło';

  @override
  String get adminCoinsAmountHint => 'Kwota (ujemna = odjęcie)';

  @override
  String get adminReasonOptional => 'Powód (opcjonalnie)';

  @override
  String get adminGrantSent => 'Karta wysłana na czat wsparcia';

  @override
  String adminCoinsDebited(int amount) {
    return 'Odjęto $amount brązu';
  }

  @override
  String get adminGrantVerb => 'Przyznaj';

  @override
  String get adminNewPasswordHint => 'Nowe hasło (min. 6)';

  @override
  String get adminPasswordReset => 'Hasło zresetowane';

  @override
  String get adminResetVerb => 'Resetuj';

  @override
  String adminShortError(String error) {
    return 'Błąd: $error';
  }

  @override
  String get adminSupportEmpty => 'Brak zgłoszeń do wsparcia';

  @override
  String get adminUserFallback => 'Użytkownik';

  @override
  String get apiErrTooManyRequests => 'Zbyt wiele żądań. Spróbuj później.';

  @override
  String get apiErrMoveConflict => 'Konflikt ruchu. Spróbuj ponownie.';
}
