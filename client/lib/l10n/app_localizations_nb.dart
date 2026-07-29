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
  String timeMinutesAgo(Object count) {
    return '$count min siden';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count t siden';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count d siden';
  }

  @override
  String get timeWeekAgo => 'en uke siden';

  @override
  String timeWeeksAgo(Object count) {
    return '$count u siden';
  }

  @override
  String get timeMonthAgo => 'en måned siden';

  @override
  String timeMonthsAgo(Object count) {
    return '$count md. siden';
  }

  @override
  String get timeYearAgo => 'et år siden';

  @override
  String timeYearsAgo(Object count) {
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
  String get shopStakesSubtitle => 'Lås opp sølvinnsatser';

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
}
