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
  String get settingsAddBotsTitle => 'Přidávat boty po 30 s';

  @override
  String get settingsAddBotsSubtitle => 'Ve vyhledávání hry: pokud se do 30 sekund nenajde soupeř, hra začne s botem (sázka se resetuje na 1 bronz)';

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
  String get timeJustNow => 'právě teď';

  @override
  String get timeYesterday => 'včera';

  @override
  String timeMinutesAgo(Object count) {
    return 'před $count min';
  }

  @override
  String timeHoursAgo(Object count) {
    return 'před $count h';
  }

  @override
  String timeDaysAgo(Object count) {
    return 'před $count d';
  }

  @override
  String get timeWeekAgo => 'před týdnem';

  @override
  String timeWeeksAgo(Object count) {
    return 'před $count týd.';
  }

  @override
  String get timeMonthAgo => 'před měsícem';

  @override
  String timeMonthsAgo(Object count) {
    return 'před $count měs.';
  }

  @override
  String get timeYearAgo => 'před rokem';

  @override
  String timeYearsAgo(Object count) {
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
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Soukromá hra';

  @override
  String get lobbySearchingOpponent => 'Hledání soupeře…';

  @override
  String get lobbyWaitingJoin => 'Čekáme, až někdo stiskne „Najít hru“ nebo „Připojit se“';

  @override
  String get lobbyInviteTitle => 'Pozvánka do hry';

  @override
  String get lobbyInvitedToPlay => 'Byli jste pozváni ke hře';

  @override
  String get lobbyEnterGame => 'Vstoupit do hry';

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
  String get gameYouWon => 'Vyhráli jste!';

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
  String get profileChangePhoto => 'Změnit foto';

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
  String get shopStakesSubtitle => 'Odemkněte stříbrné sázky';

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
}
