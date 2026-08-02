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
  String get settingsAddBotsTitle => 'Legg til boter etter 30 s';

  @override
  String get settingsAddBotsSubtitle => 'Ved matchmaking: hvis ingen motstander finnes innen 30 sekunder, starter spillet med en bot (innsatsen settes tilbake til 1 bronse)';

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
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Privat spill';

  @override
  String get lobbySearchingOpponent => 'Ser etter motstander…';

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
  String get profileChangePhoto => 'Bytt bilde';

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
  String get shopSellRefund => 'Salg returnerer 80% av kostnaden';

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
    return 'Tid per trekk: $time.';
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
}
