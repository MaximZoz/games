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
  String get settingsAddBotsTitle => 'Dodawaj boty po 30 s';

  @override
  String get settingsAddBotsSubtitle => 'W trybie wyszukiwania: jeśli nie znaleziono przeciwnika w 30 sekund, gra zaczyna się z botem (stawka wraca do 1 brązu)';

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
  String get timeJustNow => 'przed chwilą';

  @override
  String get timeYesterday => 'wczoraj';

  @override
  String timeMinutesAgo(Object count) {
    return '$count min temu';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count godz. temu';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count dn. temu';
  }

  @override
  String get timeWeekAgo => 'tydzień temu';

  @override
  String timeWeeksAgo(Object count) {
    return '$count tyg. temu';
  }

  @override
  String get timeMonthAgo => 'miesiąc temu';

  @override
  String timeMonthsAgo(Object count) {
    return '$count mies. temu';
  }

  @override
  String get timeYearAgo => 'rok temu';

  @override
  String timeYearsAgo(Object count) {
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
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Gra prywatna';

  @override
  String get lobbySearchingOpponent => 'Szukanie przeciwnika…';

  @override
  String get lobbyWaitingJoin => 'Czekamy, aż ktoś naciśnie „Znajdź grę” lub „Dołącz”';

  @override
  String get lobbyInviteTitle => 'Zaproszenie do gry';

  @override
  String get lobbyInvitedToPlay => 'Zaproszono Cię do gry';

  @override
  String get lobbyEnterGame => 'Wejdź do gry';

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
  String get profileChangePhoto => 'Zmień zdjęcie';

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
  String get shopStakesSubtitle => 'Odblokuj srebrne stawki';

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
}
