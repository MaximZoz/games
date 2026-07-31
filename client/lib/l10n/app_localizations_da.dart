import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Hjem';

  @override
  String get navProfile => 'Profil';

  @override
  String get navFriends => 'Venner';

  @override
  String get navChats => 'Chats';

  @override
  String get navGames => 'Spil';

  @override
  String get navSettings => 'Indstillinger';

  @override
  String get settingsTitle => 'Indstillinger';

  @override
  String get settingsLanguage => 'Sprog';

  @override
  String get settingsLanguageSystem => 'Systemstandard';

  @override
  String get settingsAddBotsTitle => 'Tilføj bots efter 30 s';

  @override
  String get settingsAddBotsSubtitle => 'Ved matchmaking: hvis der ikke findes en modstander inden for 30 sekunder, starter spillet med en bot (indsatsen nulstilles til 1 bronze)';

  @override
  String get settingsFriendsOnlyTitle => 'Beskeder kun fra venner';

  @override
  String get settingsFriendsOnlySubtitle => 'Ikke-venner kan kun sende emojis. Ved spam, bloker brugeren midlertidigt.';

  @override
  String get settingsNotifications => 'Notifikationer';

  @override
  String get settingsPushChat => 'Chat';

  @override
  String get settingsPushFriends => 'Venner';

  @override
  String get settingsPushGames => 'Spil';

  @override
  String get settingsPushRewards => 'Belønninger';

  @override
  String get loginTitle => 'Log ind';

  @override
  String get loginSubtitle => 'Indtast e-mail eller brugernavn og adgangskode';

  @override
  String get loginEmailLabel => 'E-mail eller brugernavn';

  @override
  String get loginPasswordLabel => 'Adgangskode';

  @override
  String get loginSubmit => 'Log ind';

  @override
  String get loginNoAccount => 'Ingen konto? Tilmeld dig';

  @override
  String get loginEmailRequired => 'Indtast e-mail eller brugernavn';

  @override
  String get loginPasswordRequired => 'Indtast adgangskode';

  @override
  String get loginTooltip => 'Log ind';

  @override
  String get logoutTooltip => 'Log ud';

  @override
  String get registerTitle => 'Tilmeld dig';

  @override
  String get registerSubtitle => 'Opret en konto for at spille';

  @override
  String get registerNameLabel => 'Navn (brugernavn)';

  @override
  String get registerEmailLabel => 'E-mail';

  @override
  String get registerPasswordLabel => 'Adgangskode';

  @override
  String get registerSubmit => 'Tilmeld dig';

  @override
  String get registerHaveAccount => 'Har du allerede en konto? Log ind';

  @override
  String get registerNameRequired => 'Indtast et navn';

  @override
  String get registerNameNoSpaces => 'Navnet må ikke indeholde mellemrum';

  @override
  String get registerNameMax => 'Maks. 20 tegn';

  @override
  String get registerNameHint => 'Op til 20 tegn';

  @override
  String get registerEmailRequired => 'Indtast e-mail';

  @override
  String get registerEmailInvalid => 'Ugyldig e-mail';

  @override
  String get registerPasswordHint => 'Mindst 6 tegn';

  @override
  String get registerPasswordMin => 'Adgangskoden skal være mindst 6 tegn';

  @override
  String get commonCancel => 'Annuller';

  @override
  String get commonSave => 'Gem';

  @override
  String get commonDelete => 'Slet';

  @override
  String get commonEdit => 'Rediger';

  @override
  String get commonReply => 'Svar';

  @override
  String get commonSend => 'Send';

  @override
  String get commonClose => 'Luk';

  @override
  String get commonRetry => 'Prøv igen';

  @override
  String get commonLoading => 'Indlæser…';

  @override
  String get commonError => 'Fejl';

  @override
  String get commonOnline => 'online';

  @override
  String get commonOffline => 'offline';

  @override
  String get commonOnlineCap => 'Online';

  @override
  String get commonUser => 'Bruger';

  @override
  String get commonPlayer => 'Spiller';

  @override
  String get commonAboutMe => 'Om mig';

  @override
  String get commonBack => 'Tilbage';

  @override
  String get commonAccept => 'Accepter';

  @override
  String get commonDecline => 'Afvis';

  @override
  String get commonCreating => 'Opretter…';

  @override
  String get commonSearching => 'Søger…';

  @override
  String get commonInsufficientCoins => 'Ikke nok mønter';

  @override
  String get commonNotFound => 'Ikke fundet';

  @override
  String get commonServerErrorShort => 'Serverfejl';

  @override
  String get commonForbidden => 'Adgang nægtet';

  @override
  String get commonUserBlocked => 'Brugeren er blokeret';

  @override
  String get commonUserNotFound => 'Brugeren blev ikke fundet';

  @override
  String get commonGenericError => 'Noget gik galt. Prøv igen.';

  @override
  String get timeJustNow => 'lige nu';

  @override
  String get timeYesterday => 'i går';

  @override
  String timeMinutesAgo(int count) {
    return '$count min. siden';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count t. siden';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count d. siden';
  }

  @override
  String get timeWeekAgo => 'en uge siden';

  @override
  String timeWeeksAgo(int count) {
    return '$count ug. siden';
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
  String get homeAchievements => 'Præstationer';

  @override
  String get homeAchievementsSubtitle => 'Dine spilleresultater';

  @override
  String get homeAchievementsRewards => 'Belønninger klar til at hente';

  @override
  String get homeCoins => 'Mønter';

  @override
  String get homeCoinsSubtitle => 'Saldo og belønninger';

  @override
  String get homeCoinsDailyReward => 'Daglig loginbelønning tilgængelig';

  @override
  String get homeItems => 'Genstande';

  @override
  String get homeItemsInventory => 'Dit inventar';

  @override
  String get homeItemsGifted => 'Nogen har givet dig en samling';

  @override
  String get homeItemsIncome => 'Samlingsindtægt klar til at hente';

  @override
  String get homeShop => 'Butik';

  @override
  String get homeShopSubtitle => 'Emojis, indsatser, samlinger';

  @override
  String get gamesTitle => 'Spil';

  @override
  String get gamesFindMatch => 'Find et spil';

  @override
  String get gamesMyTurn => 'Din tur';

  @override
  String get gamesWaiting => 'Venter';

  @override
  String get gamesLobbyTab => 'Lobby';

  @override
  String get gamesTicTacToe => 'Kryds og bolle';

  @override
  String get gamesRules => 'Regler';

  @override
  String get gamesRulesTitle => 'Spilleregler';

  @override
  String get gamesCreate => 'Opret spil';

  @override
  String get gamesJoin => 'Deltag';

  @override
  String get gamesOpponentTurn => 'Modstanderens tur';

  @override
  String get gamesCurrentGame => 'Aktuelt spil';

  @override
  String get gamesInvitedYou => 'Du blev inviteret';

  @override
  String get gamesTurnTime => 'Tid pr. tur';

  @override
  String get gamesGridSize => 'Gitterstørrelse';

  @override
  String get gamesSwapSides => 'Sideskift';

  @override
  String get gamesNoCenter => 'Ingen start i midten';

  @override
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Privat spil';

  @override
  String get lobbySearchingOpponent => 'Leder efter modstander…';

  @override
  String get lobbyWaitingJoin => 'Venter på, at nogen trykker på »Find et spil« eller »Deltag«';

  @override
  String get lobbyInviteTitle => 'Spilinvitation';

  @override
  String get lobbyInvitedToPlay => 'Du blev inviteret til at spille';

  @override
  String get lobbyEnterGame => 'Gå ind i spillet';

  @override
  String get lobbyInvite => 'Inviter';

  @override
  String get lobbyInviteSent => 'Invitation sendt';

  @override
  String get lobbyCopyLink => 'Del spil-link';

  @override
  String get lobbyLinkCopied => 'Link kopieret';

  @override
  String get lobbyNoFriendsOnline => 'Ingen venner online. Del spil-linket ovenfor, eller vent til venner kommer online.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Modstander';

  @override
  String get gameYouWon => 'Du vandt!';

  @override
  String get gameYouWonOpponentLeft => 'Du vandt — modstanderen forlod';

  @override
  String get gameYouWonOpponentTimeout => 'Du vandt — modstanderen løb tør for tid';

  @override
  String get gameDraw => 'Uafgjort';

  @override
  String get gameExitTitle => 'Forlad spillet';

  @override
  String get gameExitConfirm => 'Hvis du forlader, taber du. Forlad alligevel?';

  @override
  String get gameStay => 'Bliv';

  @override
  String get gameLeave => 'Forlad';

  @override
  String get gameSurrender => 'Сдаться';

  @override
  String get gameSurrenderTitle => 'Сдаться?';

  @override
  String get gameSurrenderConfirm => 'Если вы сдадитесь, вы проиграете. Сдаться?';

  @override
  String get gameOfferDraw => 'Предложить ничью';

  @override
  String get gameOfferDrawTitle => 'Предложить ничью?';

  @override
  String get gameOfferDrawConfirm => 'Отправить сопернику предложение ничьей?';

  @override
  String get gameAcceptDrawTitle => 'Принять ничью?';

  @override
  String get gameAcceptDrawConfirm => 'Соперник предлагает ничью. Принять?';

  @override
  String get gameDrawOffered => 'Ожидание ответа';

  @override
  String get gameConnecting => 'Forbinder til spillet…';

  @override
  String get gameWaitingOpponent => 'Venter på modstander';

  @override
  String get gameRematchOffer => 'Modstanderen tilbyder revanche';

  @override
  String get gameRematchDeclined => 'Modstanderen afviste revanchen';

  @override
  String get gameRematch => 'Revanche';

  @override
  String get gameOtherOpponent => 'Anden modstander';

  @override
  String get gameSwapSidesAction => 'Skift side';

  @override
  String get gameWriteMessage => 'Skriv en besked';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get chatsEmpty => 'Ingen chats endnu.\nTryk på ikonet øverst til højre for at vælge en ven og starte en samtale.';

  @override
  String get chatsNewChat => 'Ny chat';

  @override
  String get chatsNoMessages => 'Ingen beskeder';

  @override
  String get chatsClearTitle => 'Ryd samtalen?';

  @override
  String get chatsClearDesc => 'Chatten slettes permanent.';

  @override
  String get chatsClearConfirm => 'Ryd';

  @override
  String get chatsBlockTitle => 'Blokér denne bruger?';

  @override
  String get chatsBlockDesc => 'I kan ikke længere sende beskeder til hinanden. Chat og venskab fjernes.';

  @override
  String get chatsBlockConfirm => 'Blokér';

  @override
  String get chatsBlockedUsers => 'Blokerede brugere';

  @override
  String get chatsUnblock => 'Fjern blokering';

  @override
  String get chatDialog => 'Chat';

  @override
  String get chatEmpty => 'Ingen beskeder endnu.\nSend den første.';

  @override
  String get chatMessageHint => 'Besked';

  @override
  String get chatPaste => 'Вставить';

  @override
  String get chatEmoji => 'Emojis';

  @override
  String get chatBuyEmojiHint => 'Køb emojis i butikken på startskærmen';

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
  String get emojiGroupGame => 'Spil';

  @override
  String get emojiGroupFlags => 'Flag';

  @override
  String get emojiGroupAnimals => 'Dyr';

  @override
  String get emojiGroupFood => 'Mad';

  @override
  String get emojiGroupTravel => 'Rejse';

  @override
  String get emojiGroupParty => 'Fest';

  @override
  String get emojiGroupObjects => 'Objekter';

  @override
  String get friendsTitle => 'Venner';

  @override
  String get friendsTabFriends => 'Venner';

  @override
  String get friendsTabIncoming => 'Indgående';

  @override
  String get friendsTabOutgoing => 'Udgående';

  @override
  String get friendsAdd => 'Tilføj ven';

  @override
  String get friendsRequestSent => 'Anmodning sendt';

  @override
  String get friendsFindTab => 'Find ven';

  @override
  String get friendsSearchHint => 'Søg efter brugernavn';

  @override
  String get friendsSearchPrompt => 'Brug søgning til at finde nye venner';

  @override
  String get friendsNothingFound => 'Intet fundet';

  @override
  String get friendsEmpty => 'Du har ingen venner endnu';

  @override
  String get friendsNoIncoming => 'Ingen indgående anmodninger';

  @override
  String get friendsNoOutgoing => 'Ingen udgående anmodninger';

  @override
  String get friendsAlreadyFriends => 'Allerede venner';

  @override
  String get friendsRemoveTitle => 'Fjern fra venner?';

  @override
  String get friendsRemoved => 'Fjernet fra venner';

  @override
  String get friendsRequestAccepted => 'Anmodning accepteret';

  @override
  String get friendsRequestDeclined => 'Anmodning afvist';

  @override
  String get friendsRequestCancelled => 'Anmodning annulleret';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSignInPrompt => 'Log ind på din konto';

  @override
  String get profileSignInHint => 'For at indstille din personlige profil';

  @override
  String get profileEdit => 'Rediger';

  @override
  String get profileCollections => 'Samlinger';

  @override
  String get profileAge => 'Alder';

  @override
  String get profileGender => 'Køn';

  @override
  String get profileGenderUnset => 'Ikke angivet';

  @override
  String get profileGenderMale => 'Mand';

  @override
  String get profileGenderFemale => 'Kvinde';

  @override
  String get profileAvatar => 'Avatar';

  @override
  String get profileUploadPhoto => 'Upload foto';

  @override
  String get profileChangePhoto => 'Skift foto';

  @override
  String get shopTitle => 'Butik';

  @override
  String get shopEmojis => 'Emojis';

  @override
  String get shopEmojisSubtitle => 'Animerede emojis til chat';

  @override
  String get shopCollections => 'Samlinger';

  @override
  String get shopCollectionsSubtitle => 'Profiludstilling, gaver og indtægt';

  @override
  String get shopStakes => 'Indsatser';

  @override
  String get shopStakesSubtitle => 'Lås sølvindsatser op';

  @override
  String get inventoryTitle => 'Genstande';

  @override
  String get inventoryEmpty => 'Intet her endnu — tjek butikken';

  @override
  String get inventoryFrames => 'Rammer';

  @override
  String get inventoryClaim => 'Hent';

  @override
  String get inventorySell => 'Sælg';

  @override
  String get inventoryGift => 'Giv';

  @override
  String get messageEdited => 'redigeret';

  @override
  String get messageDeleted => 'Besked slettet';

  @override
  String get photo => 'Foto';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galleri';

  @override
  String get connectionError => 'Kunne ikke oprette forbindelse til serveren.';

  @override
  String get serverError => 'Serverfejl. Prøv igen senere.';

  @override
  String get sessionExpired => 'Sessionen er udløbet. Log ind igen.';

  @override
  String get errNoInternet => 'Ingen internetforbindelse.';

  @override
  String get errTimeout => 'Anmodningen fik timeout. Prøv igen.';

  @override
  String get errGamesUnavailable => 'Spil er midlertidigt utilgængelige';

  @override
  String get errSettingsSaveFailed => 'Kunne ikke gemme indstillingen';

  @override
  String get errPushPermission => 'Tillad notifikationer i browser- eller systemindstillingerne.';

  @override
  String get balanceTitle => 'Saldo';

  @override
  String get coinBronze => 'Bronze';

  @override
  String get coinSilver => 'Sølv';

  @override
  String get coinGold => 'Guld';

  @override
  String get coinDiamond => 'Diamant';

  @override
  String get balanceZeroBronze => '0 bronze';

  @override
  String balanceBronzes(int count) {
    return '$count bronze';
  }

  @override
  String balanceSilvers(int count) {
    return '$count sølv';
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
    return '$amount pr. dag';
  }

  @override
  String get balanceAbbrBronze => 'br';

  @override
  String get balanceAbbrSilver => 's.';

  @override
  String get balanceAbbrGold => 'g.';

  @override
  String get commonBackHome => 'Tilbage til forsiden';

  @override
  String get commonCopied => 'Kopieret';

  @override
  String get commonClear => 'Ryd';

  @override
  String get commonTryLater => 'Prøv igen senere.';

  @override
  String get commonTryRefresh => 'Prøv at opdatere siden.';

  @override
  String get coinsTitle => 'Mønter';

  @override
  String get coinsLoginReward => 'Loginbelønning';

  @override
  String get coinsLoginAvailableToday => 'Dagens belønning er tilgængelig';

  @override
  String get coinsLoginStreak => 'Daglig loginstreak';

  @override
  String get coinsFriendReward => 'Ven-belønning';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount for tilmelding via dit link';
  }

  @override
  String get coinsLoadRewardsFailed => 'Kunne ikke indlæse belønninger';

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
    return '$done/$target · 1 dag tilbage';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · $remaining tilbage';
  }

  @override
  String get coinsInviteFriend => 'Inviter en ven';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount for hver, der tilmelder sig via dit link';
  }

  @override
  String get coinsCopyLink => 'Kopiér link';

  @override
  String get coinsHowItWorks => 'Sådan virker det';

  @override
  String get coinsHowStep1 => 'Kopiér linket og send det til en ven';

  @override
  String get coinsHowStep2 => 'Din ven tilmelder sig via det link';

  @override
  String coinsHowStep3(String amount) {
    return 'Du modtager $amount';
  }

  @override
  String get achievementsTitle => 'Præstationer';

  @override
  String achievementsProgress(String progress) {
    return 'Fremskridt: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Ramme hentet';

  @override
  String get achievementsClaimed => 'Hentet';

  @override
  String get achievementsOpenFrame => 'Åbn ramme';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Er du sikker på, at du vil fjerne $name fra venner?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Fjern';

  @override
  String get friendsRemove => 'Fjern fra venner';

  @override
  String get friendsAcceptRequest => 'Acceptér anmodning';

  @override
  String get friendsDeclineRequest => 'Afvis anmodning';

  @override
  String get friendsCancelRequest => 'Annuller anmodning';

  @override
  String get friendsSendRequest => 'Send venneanmodning';

  @override
  String get friendsRequestAlreadySent => 'Anmodning allerede sendt';

  @override
  String get friendsIncomingStatus => 'Indgående anmodning';

  @override
  String get friendsOutgoingStatus => 'Udgående anmodning';

  @override
  String get friendsNotFriends => 'Ikke venner';

  @override
  String get friendsCollapseSearch => 'Skjul søgning';

  @override
  String get friendsExpandSearch => 'Vis søgning';

  @override
  String get friendsLoadFailed => 'Kunne ikke indlæse venner';

  @override
  String friendsSince(String date) {
    return 'Venner siden: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Indgående anmodning: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Udgående anmodning: $date';
  }

  @override
  String get userInfoTitle => 'Brugerinfo';

  @override
  String profileAgeYears(int age) {
    return '$age år';
  }

  @override
  String get shopBuy => 'Køb';

  @override
  String get shopBuyTitle => 'Køb?';

  @override
  String get shopBuyStakeTitle => 'Køb indsats?';

  @override
  String get shopBuyEmojiTitle => 'Køb emoji?';

  @override
  String get shopBuyCollectionTitle => 'Køb samling?';

  @override
  String shopPrice(String price) {
    return 'Pris: $price';
  }

  @override
  String get shopOwned => 'Købt';

  @override
  String get shopEmpty => 'Tomt indtil videre';

  @override
  String shopPurchased(String title) {
    return '$title købt';
  }

  @override
  String get shopEmojiUses => 'Du får: 10 brug';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 brug';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 brug';
  }

  @override
  String get shopBuyTen => 'Køb · 10 stk.';

  @override
  String shopDailyIncome(String amount) {
    return 'Indkomst: $amount';
  }

  @override
  String get shopBuyOnce => 'Engangskøb';

  @override
  String get shopSellRefund => 'Salg returnerer en del af prisen';

  @override
  String shopCollectionAdded(String title) {
    return '$title tilføjet til profilen';
  }

  @override
  String shopSetBonus(int percent) {
    return 'sætbonus +$percent%';
  }

  @override
  String get shopSetComplete => 'Fuldført';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Samlet · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Sælg?';

  @override
  String inventorySellDesc(String amount) {
    return 'Du får $amount';
  }

  @override
  String inventorySold(String amount) {
    return 'Solgt: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Tilføj venner først';

  @override
  String get inventoryGiftTitle => 'Giv samling i gave?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'Giv «$title» til $name?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Givet: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'У этого пользователя уже есть эта коллекция';

  @override
  String get inventoryGiftSelf => 'Нельзя подарить коллекцию самому себе';

  @override
  String get inventoryGiftNotOwned => 'У вас нет этого предмета';

  @override
  String get inventoryLoadFailed => 'Kunne ikke indlæse genstande';

  @override
  String get inventoryNoCollections => 'Ingen samlinger — køb i butikken';

  @override
  String get inventoryNoEmojis => 'Ingen emojis — køb i butikken';

  @override
  String get inventoryNoFrames => 'Ingen rammer — vind 10 ligakampe (præstationer)';

  @override
  String get inventoryNoStakes => 'Ingen købte indsatser';

  @override
  String inventoryEmojiLeft(int count) {
    return '$count tilbage';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Indkomst: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Indkomst i morgen: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Доход:';

  @override
  String get inventoryIncomeTomorrowLabel => 'Доход завтра:';

  @override
  String inventoryStakeGold(String amount) {
    return 'Du kan satse $amount guld';
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
  String get chatsLoadFailed => 'Kunne ikke indlæse chats';

  @override
  String get chatsLoadListFailed => 'Kunne ikke indlæse listen';

  @override
  String get chatsBlockedEmpty => 'Listen er tom';

  @override
  String chatsBlockedAt(String date) {
    return 'Blokeret: $date';
  }

  @override
  String get chatsCreateFailed => 'Kunne ikke oprette chat';

  @override
  String get chatsNeedFriendsFirst => 'Tilføj venner først, så kan du åbne en chat.';

  @override
  String get chatsFriendsNotFound => 'Ingen venner fundet';

  @override
  String get chatsFindFriendHint => 'Find ven efter kaldenavn';

  @override
  String get chatsSelectChat => 'Vælg en chat';

  @override
  String get chatsSelectHint => 'Vælg en samtale fra listen til venstre';

  @override
  String get chatEditFailed => 'Kunne ikke redigere beskeden';

  @override
  String get chatSendFailed => 'Kunne ikke sende beskeden';

  @override
  String get chatDeleteFailed => 'Kunne ikke slette beskeden';

  @override
  String get chatEmojiSendFailed => 'Kunne ikke sende emoji';

  @override
  String get chatLoadFailed => 'Kunne ikke indlæse beskeder';

  @override
  String get chatBackToGame => 'Tilbage til spillet';

  @override
  String get chatBackToChats => 'Tilbage til chats';

  @override
  String get chatActions => 'Chathandlinger';

  @override
  String get chatScrollToEnd => 'Til slutningen af samtalen';

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
  String get chatThisUser => 'denne bruger';

  @override
  String get gamesLobbyLoadFailed => 'Kunne ikke indlæse lobbyen.';

  @override
  String get gamesTapChangeStake => 'Tryk for at ændre indsats';

  @override
  String get gamesTapChangeTurnTime => 'Tryk for at ændre tid pr. træk';

  @override
  String get gamesTapChangeGrid => 'Tryk for at ændre gitterstørrelse';

  @override
  String get gamesSwapSidesHint => 'O kan blive X efter 1. træk';

  @override
  String get gamesNoCenterHint => 'Første træk må ikke være i midten';

  @override
  String get lobbyInviteSentShort => 'Sendt';

  @override
  String get lobbyInvitesSentWaiting => 'Invitationer sendt. Venter på svar.';

  @override
  String get lobbyLinkCopiedHint => 'Indsæt den i en chat eller besked til en ven';

  @override
  String get lobbyCopyLinkHint => 'Kopiér link til udklipsholder';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name inviterer dig til at spille';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name vandt';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Tiden er gået. $name vandt';
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
  String get profileAgeInvalid => 'Indtast en alder fra 1 til 111';

  @override
  String get profileSaveFailed => 'Kunne ikke gemme profilen';

  @override
  String get profileNameHint => 'Latinske bogstaver, cifre, _ op til 10 tegn';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'Fra 1 til 111';

  @override
  String get profileAboutHint => 'Op til 100 tegn (valgfrit)';

  @override
  String get profileProcessingPhoto => 'Behandler foto…';

  @override
  String get profileCropTitle => 'Vælg avatarområde';

  @override
  String get profileCropHint => 'Zoom og flyt fotoet';

  @override
  String get profileApply => 'Anvend';

  @override
  String get profilePreparing => 'Forbereder…';

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
    return 'Kryds og bolle på $grid-bræt. På skift; X starter.';
  }

  @override
  String rulesWin(int n) {
    return 'Sejr: få $n på række vandret, lodret eller diagonalt.';
  }

  @override
  String get rulesNoTimeLimit => 'Ingen tidsgrænse pr. træk.';

  @override
  String rulesTurnTime(String time) {
    return 'Tid pr. træk: $time.';
  }

  @override
  String rulesStake(String stake) {
    return 'Indsats: $stake. Spillet gælder så mange mønter.';
  }

  @override
  String get rulesSwap => 'Sidebyt: O kan bytte med X efter X’s første træk.';

  @override
  String get rulesNoCenter => 'Ingen midte: X må ikke spille i midten på første træk.';

  @override
  String get collectionSetLegends => 'Legender';

  @override
  String get collectionSetSpace => 'Rummet';

  @override
  String get collectionSetGems => 'Ædelsten';

  @override
  String get collectionSetParty => 'Fest';

  @override
  String get collectionSetNature => 'Natur';

  @override
  String get collectionSetAdventures => 'Eventyr';

  @override
  String collectionCardMeta(String amount) {
    return 'Samling · udstilling · gave · salg · +$amount';
  }

  @override
  String get coinsDayOne => 'dag';

  @override
  String get coinsDayFew => 'dage';

  @override
  String get coinsDayMany => 'dage';

  @override
  String get giftFriendTitle => 'Giv til en ven';

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
    return '$count emojis · $price pr.';
  }

  @override
  String get chatsExpandPanel => 'Udvid panel';

  @override
  String get chatsCollapsePanel => 'Skjul panel';

  @override
  String get chatReplySourceMissing => 'Originalbesked ikke fundet';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Indsats $n sølv';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Indsats $n guld';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Låser op for indsats på $n sølv';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Låser op for indsats på $n guld';
  }

  @override
  String get chatReplySelf => 'dig selv';

  @override
  String get chatReplyPeer => 'modparten';

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
