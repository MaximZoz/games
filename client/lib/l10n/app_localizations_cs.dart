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
  String get gameSurrender => 'Vzdát se';

  @override
  String get gameSurrenderTitle => 'Vzdát se?';

  @override
  String get gameSurrenderConfirm => 'Prohrajete partii a sázkové mince.';

  @override
  String get gameOfferDraw => 'Nabídnout remízu';

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
  String get shopStakesSubtitle => 'Odemknutí vyšších sázek';

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
  String get shopSellRefund => 'Prodej vrátí 80% ceny';

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
    return 'Čas na tah: $time.';
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
}
