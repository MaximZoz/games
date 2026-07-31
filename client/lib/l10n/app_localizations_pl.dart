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
  String get gameSurrender => 'Сдаться';

  @override
  String get gameSurrenderTitle => 'Сдаться?';

  @override
  String get gameSurrenderConfirm => 'Если вы сдадитесь, вы проиграете. Сдаться?';

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
    return '$amount dziennie';
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
  String get shopSellRefund => 'Sprzedaż zwraca część kosztów';

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
  String get inventoryGiftAlreadyOwns => 'У этого пользователя уже есть эта коллекция';

  @override
  String get inventoryGiftSelf => 'Нельзя подарить коллекцию самому себе';

  @override
  String get inventoryGiftNotOwned => 'У вас нет этого предмета';

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
    return 'Czas na ruch: $time.';
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
}
