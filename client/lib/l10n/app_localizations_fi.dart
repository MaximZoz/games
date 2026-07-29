import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Koti';

  @override
  String get navProfile => 'Profiili';

  @override
  String get navFriends => 'Kaverit';

  @override
  String get navChats => 'Keskustelut';

  @override
  String get navGames => 'Pelit';

  @override
  String get navSettings => 'Asetukset';

  @override
  String get settingsTitle => 'Asetukset';

  @override
  String get settingsLanguage => 'Kieli';

  @override
  String get settingsLanguageSystem => 'Järjestelmän oletus';

  @override
  String get settingsAddBotsTitle => 'Lisää botteja 30 s jälkeen';

  @override
  String get settingsAddBotsSubtitle => 'Matchmakingissa: jos vastustajaa ei löydy 30 sekunnissa, peli alkaa botin kanssa (panos palautuu 1 pronssiin)';

  @override
  String get settingsFriendsOnlyTitle => 'Viestit vain kavereilta';

  @override
  String get settingsFriendsOnlySubtitle => 'Muut kuin kaverit voivat lähettää vain emojeja. Jos spam häiritsee, estä käyttäjä tilapäisesti.';

  @override
  String get settingsNotifications => 'Ilmoitukset';

  @override
  String get settingsPushChat => 'Keskustelu';

  @override
  String get settingsPushFriends => 'Kaverit';

  @override
  String get settingsPushGames => 'Pelit';

  @override
  String get settingsPushRewards => 'Palkinnot';

  @override
  String get loginTitle => 'Kirjaudu sisään';

  @override
  String get loginSubtitle => 'Syötä sähköposti tai käyttäjänimi ja salasana';

  @override
  String get loginEmailLabel => 'Sähköposti tai käyttäjänimi';

  @override
  String get loginPasswordLabel => 'Salasana';

  @override
  String get loginSubmit => 'Kirjaudu sisään';

  @override
  String get loginNoAccount => 'Ei tiliä? Rekisteröidy';

  @override
  String get loginEmailRequired => 'Syötä sähköposti tai käyttäjänimi';

  @override
  String get loginPasswordRequired => 'Syötä salasana';

  @override
  String get loginTooltip => 'Kirjaudu sisään';

  @override
  String get logoutTooltip => 'Kirjaudu ulos';

  @override
  String get registerTitle => 'Rekisteröidy';

  @override
  String get registerSubtitle => 'Luo tili pelataksesi';

  @override
  String get registerNameLabel => 'Nimi (käyttäjänimi)';

  @override
  String get registerEmailLabel => 'Sähköposti';

  @override
  String get registerPasswordLabel => 'Salasana';

  @override
  String get registerSubmit => 'Rekisteröidy';

  @override
  String get registerHaveAccount => 'Onko sinulla jo tili? Kirjaudu sisään';

  @override
  String get registerNameRequired => 'Syötä nimi';

  @override
  String get registerNameNoSpaces => 'Nimi ei voi sisältää välilyöntejä';

  @override
  String get registerNameMax => 'Enintään 20 merkkiä';

  @override
  String get registerNameHint => 'Enintään 20 merkkiä';

  @override
  String get registerEmailRequired => 'Syötä sähköposti';

  @override
  String get registerEmailInvalid => 'Virheellinen sähköposti';

  @override
  String get registerPasswordHint => 'Vähintään 6 merkkiä';

  @override
  String get registerPasswordMin => 'Salasanan on oltava vähintään 6 merkkiä';

  @override
  String get commonCancel => 'Peruuta';

  @override
  String get commonSave => 'Tallenna';

  @override
  String get commonDelete => 'Poista';

  @override
  String get commonEdit => 'Muokkaa';

  @override
  String get commonReply => 'Vastaa';

  @override
  String get commonSend => 'Lähetä';

  @override
  String get commonClose => 'Sulje';

  @override
  String get commonRetry => 'Yritä uudelleen';

  @override
  String get commonLoading => 'Ladataan…';

  @override
  String get commonError => 'Virhe';

  @override
  String get commonOnline => 'paikalla';

  @override
  String get commonOffline => 'poissa';

  @override
  String get commonOnlineCap => 'Paikalla';

  @override
  String get commonUser => 'Käyttäjä';

  @override
  String get commonPlayer => 'Pelaaja';

  @override
  String get commonAboutMe => 'Tietoja minusta';

  @override
  String get commonBack => 'Takaisin';

  @override
  String get commonAccept => 'Hyväksy';

  @override
  String get commonDecline => 'Hylkää';

  @override
  String get commonCreating => 'Luodaan…';

  @override
  String get commonSearching => 'Haetaan…';

  @override
  String get commonInsufficientCoins => 'Ei tarpeeksi kolikoita';

  @override
  String get commonNotFound => 'Ei löytynyt';

  @override
  String get commonServerErrorShort => 'Palvelinvirhe';

  @override
  String get commonForbidden => 'Pääsy kielletty';

  @override
  String get commonUserBlocked => 'Käyttäjä on estetty';

  @override
  String get commonUserNotFound => 'Käyttäjää ei löytynyt';

  @override
  String get commonGenericError => 'Jotain meni pieleen. Yritä uudelleen.';

  @override
  String get timeJustNow => 'juuri nyt';

  @override
  String get timeYesterday => 'eilen';

  @override
  String timeMinutesAgo(Object count) {
    return '$count min sitten';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count t sitten';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count pv sitten';
  }

  @override
  String get timeWeekAgo => 'viikko sitten';

  @override
  String timeWeeksAgo(Object count) {
    return '$count vk sitten';
  }

  @override
  String get timeMonthAgo => 'kuukausi sitten';

  @override
  String timeMonthsAgo(Object count) {
    return '$count kk sitten';
  }

  @override
  String get timeYearAgo => 'vuosi sitten';

  @override
  String timeYearsAgo(Object count) {
    return '$count v sitten';
  }

  @override
  String get weekdaySun => 'Su';

  @override
  String get weekdayMon => 'Ma';

  @override
  String get weekdayTue => 'Ti';

  @override
  String get weekdayWed => 'Ke';

  @override
  String get weekdayThu => 'To';

  @override
  String get weekdayFri => 'Pe';

  @override
  String get weekdaySat => 'La';

  @override
  String get monthJan => 'Tammi';

  @override
  String get monthFeb => 'Helmi';

  @override
  String get monthMar => 'Maalis';

  @override
  String get monthApr => 'Huhti';

  @override
  String get monthMay => 'Touko';

  @override
  String get monthJun => 'Kesä';

  @override
  String get monthJul => 'Heinä';

  @override
  String get monthAug => 'Elo';

  @override
  String get monthSep => 'Syys';

  @override
  String get monthOct => 'Loka';

  @override
  String get monthNov => 'Marras';

  @override
  String get monthDec => 'Joulu';

  @override
  String get homeAchievements => 'Saavutukset';

  @override
  String get homeAchievementsSubtitle => 'Pelituloksesi';

  @override
  String get homeAchievementsRewards => 'Noudettavissa olevia palkintoja';

  @override
  String get homeCoins => 'Kolikot';

  @override
  String get homeCoinsSubtitle => 'Saldo ja palkinnot';

  @override
  String get homeCoinsDailyReward => 'Päivittäinen kirjautumispalkinto saatavilla';

  @override
  String get homeItems => 'Esineet';

  @override
  String get homeItemsInventory => 'Inventaariosi';

  @override
  String get homeItemsGifted => 'Joku lahjoitti sinulle kokoelman';

  @override
  String get homeItemsIncome => 'Kokoelmatulo valmis noudettavaksi';

  @override
  String get homeShop => 'Kauppa';

  @override
  String get homeShopSubtitle => 'Emojit, panokset, kokoelmat';

  @override
  String get gamesTitle => 'Pelit';

  @override
  String get gamesFindMatch => 'Etsi peli';

  @override
  String get gamesMyTurn => 'Sinun vuorosi';

  @override
  String get gamesWaiting => 'Odottaa';

  @override
  String get gamesLobbyTab => 'Aula';

  @override
  String get gamesTicTacToe => 'Ristinolla';

  @override
  String get gamesRules => 'Säännöt';

  @override
  String get gamesRulesTitle => 'Pelin säännöt';

  @override
  String get gamesCreate => 'Luo peli';

  @override
  String get gamesJoin => 'Liity';

  @override
  String get gamesOpponentTurn => 'Vastustajan vuoro';

  @override
  String get gamesCurrentGame => 'Nykyinen peli';

  @override
  String get gamesInvitedYou => 'Sinut kutsuttiin';

  @override
  String get gamesTurnTime => 'Vuoron aika';

  @override
  String get gamesGridSize => 'Ruudukon koko';

  @override
  String get gamesSwapSides => 'Puolen vaihto';

  @override
  String get gamesNoCenter => 'Ei aloitusta keskeltä';

  @override
  String get lobbyMatchmake => 'Aula';

  @override
  String get lobbyPrivateGame => 'Yksityispeli';

  @override
  String get lobbySearchingOpponent => 'Etsitään vastustajaa…';

  @override
  String get lobbyWaitingJoin => 'Odotetaan, että joku napauttaa ”Etsi peli” tai ”Liity”';

  @override
  String get lobbyInviteTitle => 'Pelikutsu';

  @override
  String get lobbyInvitedToPlay => 'Sinut kutsuttiin pelaamaan';

  @override
  String get lobbyEnterGame => 'Siirry peliin';

  @override
  String get lobbyInvite => 'Kutsu';

  @override
  String get lobbyInviteSent => 'Kutsu lähetetty';

  @override
  String get lobbyCopyLink => 'Jaa pelilinkki';

  @override
  String get lobbyLinkCopied => 'Linkki kopioitu';

  @override
  String get lobbyNoFriendsOnline => 'Ei kavereita paikalla. Jaa yllä oleva pelilinkki tai odota, että kaverit tulevat paikalle.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Vastustaja';

  @override
  String get gameYouWon => 'Voitit!';

  @override
  String get gameYouWonOpponentLeft => 'Voitit — vastustaja lähti';

  @override
  String get gameYouWonOpponentTimeout => 'Voitit — vastustajan aika loppui';

  @override
  String get gameDraw => 'Tasapeli';

  @override
  String get gameExitTitle => 'Poistu pelistä';

  @override
  String get gameExitConfirm => 'Jos poistut, häviät. Poistutaanko silti?';

  @override
  String get gameStay => 'Jää';

  @override
  String get gameLeave => 'Poistu';

  @override
  String get gameConnecting => 'Yhdistetään peliin…';

  @override
  String get gameWaitingOpponent => 'Odotetaan vastustajaa';

  @override
  String get gameRematchOffer => 'Vastustaja tarjoaa uusintaottelua';

  @override
  String get gameRematchDeclined => 'Vastustaja hylkäsi uusintaottelun';

  @override
  String get gameRematch => 'Uusinta';

  @override
  String get gameOtherOpponent => 'Toinen vastustaja';

  @override
  String get gameSwapSidesAction => 'Vaihda puolta';

  @override
  String get gameWriteMessage => 'Kirjoita viesti';

  @override
  String get chatsTitle => 'Keskustelut';

  @override
  String get chatsEmpty => 'Ei vielä keskusteluja.\nNapauta oikean yläkulman kuvaketta valitaksesi kaverin ja aloittaaksesi keskustelun.';

  @override
  String get chatsNewChat => 'Uusi keskustelu';

  @override
  String get chatsNoMessages => 'Ei viestejä';

  @override
  String get chatsClearTitle => 'Tyhjennetäänkö keskustelu?';

  @override
  String get chatsClearDesc => 'Keskustelu poistetaan pysyvästi.';

  @override
  String get chatsClearConfirm => 'Tyhjennä';

  @override
  String get chatsBlockTitle => 'Estetäänkö tämä käyttäjä?';

  @override
  String get chatsBlockDesc => 'Ette voi enää lähettää viestejä toisillenne. Keskustelu ja kaveruus poistetaan.';

  @override
  String get chatsBlockConfirm => 'Estä';

  @override
  String get chatsBlockedUsers => 'Estetyt käyttäjät';

  @override
  String get chatsUnblock => 'Poista esto';

  @override
  String get chatDialog => 'Keskustelu';

  @override
  String get chatEmpty => 'Ei vielä viestejä.\nLähetä ensimmäinen.';

  @override
  String get chatMessageHint => 'Viesti';

  @override
  String get chatEmoji => 'Emojit';

  @override
  String get chatBuyEmojiHint => 'Osta emojeja kaupasta kotinäytöllä';

  @override
  String get chatEditing => 'Muokataan';

  @override
  String get chatToday => 'Tänään';

  @override
  String get chatYesterday => 'Eilen';

  @override
  String get chatFriendsOnly => 'Teksti vain kavereille';

  @override
  String get emojiGroupEmotions => 'Tunteet';

  @override
  String get emojiGroupGame => 'Pelaaminen';

  @override
  String get emojiGroupFlags => 'Liput';

  @override
  String get emojiGroupAnimals => 'Eläimet';

  @override
  String get emojiGroupFood => 'Ruoka';

  @override
  String get emojiGroupTravel => 'Matkailu';

  @override
  String get emojiGroupParty => 'Juhla';

  @override
  String get emojiGroupObjects => 'Esineet';

  @override
  String get friendsTitle => 'Kaverit';

  @override
  String get friendsTabFriends => 'Kaverit';

  @override
  String get friendsTabIncoming => 'Saapuneet';

  @override
  String get friendsTabOutgoing => 'Lähetetyt';

  @override
  String get friendsAdd => 'Lisää kaveri';

  @override
  String get friendsRequestSent => 'Pyyntö lähetetty';

  @override
  String get friendsFindTab => 'Etsi kaveri';

  @override
  String get friendsSearchHint => 'Hae käyttäjänimellä';

  @override
  String get friendsSearchPrompt => 'Käytä hakua löytääksesi uusia kavereita';

  @override
  String get friendsNothingFound => 'Ei tuloksia';

  @override
  String get friendsEmpty => 'Sinulla ei ole vielä kavereita';

  @override
  String get friendsNoIncoming => 'Ei saapuneita pyyntöjä';

  @override
  String get friendsNoOutgoing => 'Ei lähetettyjä pyyntöjä';

  @override
  String get friendsAlreadyFriends => 'Jo kavereita';

  @override
  String get friendsRemoveTitle => 'Poistetaanko kavereista?';

  @override
  String get friendsRemoved => 'Poistettu kavereista';

  @override
  String get friendsRequestAccepted => 'Pyyntö hyväksytty';

  @override
  String get friendsRequestDeclined => 'Pyyntö hylätty';

  @override
  String get friendsRequestCancelled => 'Pyyntö peruutettu';

  @override
  String get profileTitle => 'Profiili';

  @override
  String get profileSignInPrompt => 'Kirjaudu tilillesi';

  @override
  String get profileSignInHint => 'Henkilökohtaisen profiilin määrittämiseksi';

  @override
  String get profileEdit => 'Muokkaa';

  @override
  String get profileCollections => 'Kokoelmat';

  @override
  String get profileAge => 'Ikä';

  @override
  String get profileGender => 'Sukupuoli';

  @override
  String get profileGenderUnset => 'Ei asetettu';

  @override
  String get profileGenderMale => 'Mies';

  @override
  String get profileGenderFemale => 'Nainen';

  @override
  String get profileAvatar => 'Avatar';

  @override
  String get profileUploadPhoto => 'Lataa kuva';

  @override
  String get profileChangePhoto => 'Vaihda kuva';

  @override
  String get shopTitle => 'Kauppa';

  @override
  String get shopEmojis => 'Emojit';

  @override
  String get shopEmojisSubtitle => 'Animoidut emojit keskusteluun';

  @override
  String get shopCollections => 'Kokoelmat';

  @override
  String get shopCollectionsSubtitle => 'Profiilinäyttö, lahjat ja tulot';

  @override
  String get shopStakes => 'Panokset';

  @override
  String get shopStakesSubtitle => 'Avaa hopeapanokset';

  @override
  String get inventoryTitle => 'Esineet';

  @override
  String get inventoryEmpty => 'Täällä ei ole vielä mitään — katso kauppaa';

  @override
  String get inventoryFrames => 'Kehykset';

  @override
  String get inventoryClaim => 'Nouda';

  @override
  String get inventorySell => 'Myy';

  @override
  String get inventoryGift => 'Lahjoita';

  @override
  String get messageEdited => 'muokattu';

  @override
  String get messageDeleted => 'Viesti poistettu';

  @override
  String get photo => 'Kuva';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galleria';

  @override
  String get connectionError => 'Yhteyttä palvelimeen ei voitu muodostaa.';

  @override
  String get serverError => 'Palvelinvirhe. Yritä myöhemmin uudelleen.';

  @override
  String get sessionExpired => 'Istunto vanhentui. Kirjaudu sisään uudelleen.';

  @override
  String get errNoInternet => 'Ei internetyhteyttä.';

  @override
  String get errTimeout => 'Pyyntö aikakatkaistiin. Yritä uudelleen.';

  @override
  String get errGamesUnavailable => 'Pelit eivät ole tilapäisesti saatavilla';

  @override
  String get errSettingsSaveFailed => 'Asetusta ei voitu tallentaa';

  @override
  String get errPushPermission => 'Salli ilmoitukset selaimen tai järjestelmän asetuksissa.';
}
