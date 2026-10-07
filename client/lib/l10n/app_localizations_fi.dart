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
  String get settingsSoundTitle => 'Ääni';

  @override
  String get settingsSoundSubtitle => 'Pelit ja ilmoitukset';

  @override
  String get settingsSoundGames => 'Pelit';

  @override
  String get settingsSoundNotifications => 'Ilmoitukset';

  @override
  String get settingsSoundTurn => 'Vuoro';

  @override
  String get settingsHapticsTitle => 'Tärinä';

  @override
  String get settingsHapticsSubtitle => 'Vain ilmoitukset: viestit, pyynnöt, vuorosi ja ajastin';

  @override
  String get settingsGamepadTitle => 'Ohjain';

  @override
  String get settingsGamepadSubtitle => 'Gamepad valikoille ja peleille';

  @override
  String settingsGamepadConnected(String name) {
    return 'Yhdistetty: $name';
  }

  @override
  String get settingsGamepadDisconnected => 'Ei gamepadia. Liitä ohjain ja paina mitä tahansa painiketta.';

  @override
  String get settingsGamepadGenericName => 'Ohjain';

  @override
  String get settingsGamepadHelpNavigate => 'Navigointi';

  @override
  String get settingsGamepadHelpConfirm => 'Valitse';

  @override
  String get settingsGamepadHelpBack => 'Takaisin';

  @override
  String get settingsGamepadHelpTabs => 'Välilehdet';

  @override
  String get settingsGamepadHelpPlay => 'Kursori laudalla ja kädessä: tammi, ristinolla, laivanupotus, durak, uno, pokeri ja backgammon';

  @override
  String get settingsGamepadHelpCards => 'Kortit';

  @override
  String get settingsGamepadHelpKeyboard => 'Näppäimistö';

  @override
  String get settingsGamepadHelpBalance => 'Saldo';

  @override
  String get settingsGamepadHelpLogout => 'Kirjaudu ulos';

  @override
  String get settingsGamepadHelpPage => 'Sivu';

  @override
  String get settingsGamepadLayoutXbox => 'Xbox-asettelu';

  @override
  String get settingsGamepadLayoutPlayStation => 'PlayStation-asettelu';

  @override
  String get settingsGamepadLayoutNintendo => 'Nintendo-asettelu';

  @override
  String get gamepadKeyboardTitle => 'Näppäimistö';

  @override
  String get gamepadKeyboardSpace => 'Välilyönti';

  @override
  String get gamepadLegendConfirm => 'Valitse';

  @override
  String get gamepadLegendBack => 'Takaisin';

  @override
  String get gamepadLegendTabs => 'Välilehdet';

  @override
  String get gamepadLegendCycle => 'Vaihda';

  @override
  String gamepadConnectedSnack(String name) {
    return 'Ohjain yhdistetty: $name';
  }

  @override
  String get settingsOfflineModeTitle => 'Verkkotila';

  @override
  String get settingsOfflineModeSubtitle => 'Offline: pelaa heti bottia vastaan ilman panoksia ja palkintoja, ilman chatteja ja ystäviä. Ostokset tallentuvat ja otetaan käyttöön online-tilassa. Online — kun internet on käytettävissä tai käyttäjän asetuksen mukaan.';

  @override
  String get settingsModeOnline => 'Online';

  @override
  String get settingsModeOffline => 'Offline';

  @override
  String get gamesAlternateStartsHint => 'Vuorotellen kuka aloittaa pelin';

  @override
  String get rulesAlternateStarts => 'Kuka aloittaa vuorottelee peleistä toiseen.';

  @override
  String get offlineBadgeTooltip => 'Offline-tila';

  @override
  String get offlineModePopupTitle => 'Offline-tila';

  @override
  String get offlineModePopupBody => 'Offline-tila on päällä. Pelaa botia vastaan ilman panoksia ja palkintoja. Chatit, ystävät ja lobby on piilotettu. Ostokset otetaan käyttöön online-tilassa.';

  @override
  String get offlineModePopupSettings => 'Asetukset';

  @override
  String get offlineModeOfferBody => 'Ei internetiä tai yhteys on hyvin hidas. Voit ottaa offline-tilan käyttöön ja pelata bottia vastaan.';

  @override
  String get offlineModeOfferAction => 'Siirry offlineen';

  @override
  String get gamesPlay => 'Pelaa';

  @override
  String get offlineGameTitle => 'Peli bottia vastaan';

  @override
  String get offlineGameHint => 'Ilman panoksia ja palkintoja · vain offline';

  @override
  String get offlineBotWon => 'Botti voitti';

  @override
  String get offlineBotThinking => 'Botti miettii…';

  @override
  String get offlinePlayAgain => 'Uudelleen';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'Ota';

  @override
  String get durakActionAll => 'Kaikki';

  @override
  String get durakActionDone => 'Valmis';

  @override
  String get durakActionBito => 'Beat';

  @override
  String get durakHintDefend => 'Puolusta';

  @override
  String get durakHintDefendOrTransfer => 'Puolusta tai siirrä';

  @override
  String get durakHintOpponentDefends => 'Vastustaja puolustaa';

  @override
  String get durakHintThrowInFirst => 'Lisää kortteja (max 5 ensimmäisessä kierroksessa)';

  @override
  String get durakHintThrowIn => 'Lisää kortteja tai odota puolustusta';

  @override
  String get durakHintOpponentThrows => 'Vastustaja heittää';

  @override
  String get durakHintTakeFollow => 'Heitä oton jälkeen tai paina «Valmis»';

  @override
  String get durakHintOpponentTakeFollow => 'Vastustaja voit heittää oton jälkeen';

  @override
  String get durakHintBito => 'Heitä kortti tai sano «Bito»';

  @override
  String get durakHintOpponentBito => 'Vastustaja heittää tai sanoo «Bito»';

  @override
  String get durakHintYourAttack => 'Sinun vuoro — hyökkää';

  @override
  String get durakHintOpponentAttack => 'Vastustaja hyökkää';

  @override
  String get durakHintYouLost => 'Hävisit — olet durak';

  @override
  String get durakHintDrawAllOut => 'Tasapeli — kaikki ulos';

  @override
  String get durakHintYouFinished => 'Olet ulos — odotetaan loppua';

  @override
  String get durakFirstLeadYou => 'Aloitat sinä';

  @override
  String get durakFirstLeadOpponent => 'Vastustaja aloittaa';

  @override
  String get durakFirstLeadBot => 'Botti aloittaa';

  @override
  String durakFirstLeadOf(String name) {
    return '$name aloittaa';
  }

  @override
  String get durakFirstLeadReason => 'Matalin valtti';

  @override
  String get shopPurchaseQueued => 'Ostos tallennettu — otetaan käyttöön online-tilassa';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — ostos otettu käyttöön';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — ostosta ei otettu käyttöön: $reason';
  }

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
  String settingsAppVersion(String version) {
    return 'Versio $version';
  }

  @override
  String get appUpdateTitle => 'Päivitys saatavilla';

  @override
  String get appUpdateBody => 'Uusi versio sovelluksesta on saatavilla. Päivitä jatkaaksesi.';

  @override
  String get appUpdateWhatsNew => 'Uutta';

  @override
  String get appUpdateOk => 'Päivitä';

  @override
  String get appUpdateLaterBanner => 'Päivitämme sovelluksen tämän pelin jälkeen';

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
  String get apiErrWrongGameType => 'Väärä pelityyppi';

  @override
  String get apiErrWrongGameTypeOrState => 'Väärä pelityyppi tai -tila';

  @override
  String get apiErrLobbyFull => 'Lobby on täynnä';

  @override
  String get apiErrBadState => 'Virheellinen pelitila';

  @override
  String get apiErrIllegalMove => 'Laiton siirto';

  @override
  String get apiErrUnknownMoveType => 'Tuntematon siirtotyyppi';

  @override
  String get apiErrNoOpponents => 'Ei vastustajia';

  @override
  String get apiErrNoOpponentsRematch => 'Ei vastustajia uusintaotteluun';

  @override
  String get apiErrAlreadyInLobby => 'Olet jo tässä lobbyissa';

  @override
  String get apiErrGameNotActive => 'Peli ei ole käynnissä';

  @override
  String get apiErrNotInBattle => 'Ei taisteluvaiheessa';

  @override
  String get apiErrNotInSetup => 'Ei sijoitteluvaiheessa';

  @override
  String get apiErrAlreadyReady => 'Olet jo valmis';

  @override
  String get apiErrAlreadyForfeited => 'Olet jo luovuttanut';

  @override
  String get apiErrYouHaveForfeited => 'Olet luovuttanut';

  @override
  String get apiErrNoDrawOffer => 'Ei tasapelitarjousta';

  @override
  String get apiErrDrawOnlyPvp => 'Tasapeli vain pelaajaa vastaan';

  @override
  String get apiErrDrawOnly1v1 => 'Tasapeli vain 1v1-pelissä';

  @override
  String get apiErrDrawVsBot => 'Tasapeli ei ole käytössä bottia vastaan';

  @override
  String get apiErrDrawMultiplayer => 'Tasapeli ei ole käytössä moninpelissä';

  @override
  String get apiErrDeck24TwoPlayers => '24 kortin pakka vain kahdelle';

  @override
  String get apiErrDeck52ThreeOrFour => '52 kortin pakka vaatii 3 tai 4 pelaajaa';

  @override
  String get apiErrAccountFrozen => 'Tili on jäädytetty';

  @override
  String get apiErrTurnTimeInvalid => 'Siirtoajan on oltava 0, 20, 60 tai 600 sekuntia';

  @override
  String get timeJustNow => 'juuri nyt';

  @override
  String get timeYesterday => 'eilen';

  @override
  String timeMinutesAgo(int count) {
    return '$count min sitten';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count t sitten';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count pv sitten';
  }

  @override
  String get timeWeekAgo => 'viikko sitten';

  @override
  String timeWeeksAgo(int count) {
    return '$count vk sitten';
  }

  @override
  String get timeMonthAgo => 'kuukausi sitten';

  @override
  String timeMonthsAgo(int count) {
    return '$count kk sitten';
  }

  @override
  String get timeYearAgo => 'vuosi sitten';

  @override
  String timeYearsAgo(int count) {
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
  String get gamesDurak => 'Durak';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => 'Kierrä';

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
  String get gamesPoker => 'Pokeri';

  @override
  String get gamesUno => 'Uno';

  @override
  String get gamesNardy => 'Backgammon';

  @override
  String get gamesNardyModeShort => 'Lyhyt';

  @override
  String get gamesNardyModeLong => 'Pitkä';

  @override
  String get gamesCheckers => 'Tammi';

  @override
  String get gamesCheckersModeRussian => 'Venäläinen';

  @override
  String get gamesCheckersModeEnglish => 'Englantilainen';

  @override
  String get gamesCheckersModeGiveaway => 'Antodami';

  @override
  String get gamesCheckersModeCorners => 'Kulmat';

  @override
  String get rulesCheckersPlayers => 'Pelaajat: 2.';

  @override
  String rulesCheckersMode(String mode) {
    return 'Tila: $mode.';
  }

  @override
  String rulesCheckersTime(String time) {
    return 'Время на ход: $time. Если время вышло — проигрыш.';
  }

  @override
  String get rulesCheckersIntro => 'Lauta 8×8. Kaksi pelaajaa.';

  @override
  String get rulesCheckersPlay => 'Lyöminen on pakollista. Dama ja nappula jatkavat, jos laskeutumiruudusta voi lyödä lisää — kesken ei saa pysähtyä. Jos suuntia on useita, saa valita minkä tahansa, ei välttämättä pisintä. Viimeiselle riville päässyt nappula muuttuu damaksi.';

  @override
  String get rulesCheckersWin => 'В русских шашках побеждает тот, кто съел все шашки соперника или лишил его хода. В поддавках наоборот: кто не может ходить — выигрывает.';

  @override
  String get rulesCheckersOfflineBot => 'Офлайн: партия против бота.';

  @override
  String get rulesCheckersPlayRussian => 'Venäläinen tammi: kummallakin 12 nappulaa tummilla ruuduilla. Sotilaat kulkevat vinottain eteen ja lyövät eteen ja taakse. Damat lentävät vapaasti. Lyöminen on pakollista: jatka jos mahdollista, mutta suuntia voi olla useita ja saat valita minkä tahansa, ei välttämättä pisintä. Voitto tulee, kun vastustajan nappulat on lyöty tai hänellä ei ole siirtoja.';

  @override
  String get rulesCheckersPlayEnglish => 'Englantilainen tammi: kummallakin 12 nappulaa. Sotilaat kulkevat ja lyövät vain vinottain eteen. Damat siirtyvät yhden ruudun vinottain. Lyöminen on pakollista. Voitto tulee, kun vastustajan nappulat on lyöty tai hänellä ei ole siirtoja.';

  @override
  String get rulesCheckersPlayGiveaway => 'Antodami: samat siirrot kuin venäläisessä tammessa, mutta tavoite on päinvastainen — luovuttaa kaikki nappulat tai jäädä ilman siirtoja. Lyöminen on silti pakollista.';

  @override
  String get rulesCheckersPlayCorners => 'Kulmat: nappulat alkavat vastakkaisista kulmista. Siirry viereiseen tyhjään ruutuun vaaka- tai pystysuoraan tai hyppää minkä tahansa nappulan yli poistamatta sitä. Tavoite on viedä kaikki omat nappulat vastustajan kulmaan.';

  @override
  String get rulesCheckersPlayCornersNoReturn => 'Nappula, joka on lähtenyt aloituskulmastaan, ei saa palata sinne.';

  @override
  String get rulesCheckersPlayCornersLeaveHome => 'Nappuloiden, jotka ovat vielä kotona, on poistuttava pelaajan 25 ensimmäisen siirron aikana.';

  @override
  String get rulesCheckersDrawRussian => 'Tasapeli, jos asema toistuu kolmesti tai 15 siirtoa kummaltakin on vain kuningattaria ilman lyöntiä — myös 2 vs 2.';

  @override
  String get rulesCheckersDrawEnglish => 'Tasapeli kolminkertaisesta toistosta, 40 siirrosta ilman lyöntiä tai sotilasta, tai kuningatar vastaan kuningatar.';

  @override
  String get rulesCheckersDrawGiveaway => 'Tasapeli kolminkertaisesta toistosta tai 15 kuningatarsiirrosta ilman lyöntiä.';

  @override
  String get rulesCheckersDrawCorners => 'Tasapeli kolminkertaisesta toistosta tai jos 25 siirtoa kummaltakin ei lisää nappuloita maalikulmaan.';

  @override
  String get checkersDrawRepetition => 'Tasapeli — asema toistui kolmesti';

  @override
  String get checkersDrawNoProgress => 'Tasapeli — siirrot eivät johda voittoon';

  @override
  String get checkersDrawInsufficient => 'Tasapeli — voittoon ei ole tarpeeksi voimaa';

  @override
  String get rulesNardyTitle => 'Backgammon — säännöt';

  @override
  String get rulesNardyPlayers => 'Pelaajat: 2.';

  @override
  String rulesNardyMode(String mode) {
    return 'Tila: $mode.';
  }

  @override
  String get rulesNardyIntro => 'Lautalla 24 pistettä, kummallakin 15 nappulaa. Kaksi noppaa: yksi nappula summaan tai kaksi nappulaa silmälukuihin.';

  @override
  String get rulesNardyPlayShort => 'Lyhyt backgammon: liikutte toisianne kohti ja voitte lyödä yksinäisiä nappuloita. Lyöty nappula menee barille ja sen on tultava uudestaan sisään. Kun kaikki ovat kotona, poistat ne laudalta.';

  @override
  String get rulesNardyPlayLong => 'Pitkä backgammon: molemmat lähtevät samasta päästä samaan suuntaan. Päästä lähtee vuorossa enintään yksi nappula. Lyöminen ei ole sallittua. Kun kaikki ovat kotona, poistat ne.';

  @override
  String get rulesNardyWin => 'Voittaa se, joka ensimmäisenä poistaa kaikki nappulat.';

  @override
  String get rulesNardySixPrime => 'Kuutta peräkkäistä pistettä ei saa sulkea ennen kuin vähintään yksi vastustajan nappula on ohittanut ne.';

  @override
  String get nardyRoll => 'Heitä';

  @override
  String get nardySkipTurn => 'Ohita vuoro';

  @override
  String get nardyUndoMove => 'Kumoa';

  @override
  String get nardyDoneTurn => 'Valmis';

  @override
  String get nardyAutoConfirm => 'Autovahvistus';

  @override
  String get nardyAutoConfirmHint => 'Siirron jälkeen vuoro siirtyy automaattisesti';

  @override
  String get nardyLayoutToggle => 'Vaihda asettelu';

  @override
  String get nardyNoMoves => 'Ei siirtoja';

  @override
  String get nardyYourRoll => 'Sinun heittosi';

  @override
  String get nardyPipsShort => 'Jäljellä:';

  @override
  String get nardyYouWonMars => 'Voitit — gammon!';

  @override
  String get nardyYouLostMars => 'Tappio — gammon';

  @override
  String get rulesNardyOfflineBot => 'Offline: peli bottia vastaan.';

  @override
  String rulesUnoPlayers(int players) {
    return 'Pelaajat: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'Peli bottia vastaan ilman vuoron aikarajaa.';

  @override
  String get rulesUnoIntro => 'Jokainen saa 7 korttia. Pelaa saman värin tai saman arvon kortti (numero tai sama toiminto).';

  @override
  String get rulesUnoPlay => 'Ohitus — seuraava menettää vuoron. Suunnanvaihto kahdella toimii ohituksena. +2 pinotaan vain +2:n päälle ja +4 vain +4:n päälle: rangaistus kertyy (kaksi +2:ta, seuraava nostaa 4). +2:ta ei saa laittaa +4:n päälle. Joka ei pinoa, nostaa koko pinon ja menettää vuoron. Kaksi samaa ei-mustaa korttia (esim. kaksi keltaista 8) hylätään yhdessä: pelaa yksi, kaksonen lähtee automaattisesti.';

  @override
  String get rulesUnoWild => 'Musta kortti asettaa uuden värin. Pelaa +4 vain, jos sinulla ei ole nykyisen värin korttia. Vastustaja voi haastaa: jos +4 oli laillinen, hän nostaa 6; muuten +4:n pelaaja nostaa 4 ja haastaja pelaa.';

  @override
  String get rulesUnoDraw => 'Ilman laillista korttia nosta yksi pakasta. Jos se sopii, voit pelata sen heti tai pitää ja luovuttaa vuoron. Et saa nostaa, jos sinulla on laillinen siirto.';

  @override
  String get rulesUnoWin => 'Kaksin 100 pisteeseen, 3+ pelaajalla 200. Erän voittaa se, joka tyhjentää kätensä.';

  @override
  String get rulesUnoCall => 'Kun yksi kortti on jäljellä, paina heti ”Uno!”. Vastustaja voi napata sinut Uno-unohduksesta vasta sekunnin kuluttua — silloin nostat 2 korttia.';

  @override
  String get rulesUnoScoring => 'Joka ensimmäisenä tyhjentää kätensä, voittaa erän ja saa pisteet vastustajien korteista: numerot arvosta, toiminnot 20, mustat 50. Kaksin 100:een, 3+ pelaajalla 200:een.';

  @override
  String get unoColorRed => 'Punainen';

  @override
  String get unoColorYellow => 'Keltainen';

  @override
  String get unoColorGreen => 'Vihreä';

  @override
  String get unoColorBlue => 'Sininen';

  @override
  String get unoDraw => 'Nosta';

  @override
  String get unoKeep => 'Pidä';

  @override
  String get unoSayUno => 'Uno!';

  @override
  String get unoChallengeUno => 'Haasta Uno';

  @override
  String get unoChallengeWd4 => 'Haasta +4';

  @override
  String get unoChooseColor => 'Valitse väri';

  @override
  String get unoDrawPile => 'Nostopakka';

  @override
  String get unoDiscardPile => 'Poistopakka';

  @override
  String unoCardsCount(int count) {
    return 'Kortteja: $count';
  }

  @override
  String unoScore(int score) {
    return 'Pisteet: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'Kierros $round · tavoite $target';
  }

  @override
  String get unoYourTurn => 'Sinun vuorosi';

  @override
  String get unoWaitingTurn => 'Vastustajan vuoro';

  @override
  String get unoChooseColorHint => 'Valitse jokerille väri';

  @override
  String get unoWd4Hint => 'Nosta 4 korttia tai haasta Wild +4';

  @override
  String get unoDrawnHint => 'Pelaa nostettu kortti tai pidä se';

  @override
  String get unoPlayHint => 'Pelaa sopiva väri tai arvo';

  @override
  String get unoDrawHint => 'Ei sopivaa korttia — nosta pakasta';

  @override
  String unoPendingDraw(int count) {
    return '+$count korttia';
  }

  @override
  String get unoYouWon => 'Voitit ottelun!';

  @override
  String get unoYouLost => 'Ottelu päättyi';

  @override
  String get unoYouLostTimeout => 'Hävisit ajan loppumiseen';

  @override
  String unoWinner(String name) {
    return 'Voittaja: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name voittaa erän';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'Seuraava';

  @override
  String get unoRoundScoresTitle => 'Erän pisteet';

  @override
  String get unoDirectionClockwise => 'Myötäpäivään';

  @override
  String get unoDirectionCounterclockwise => 'Vastapäivään';

  @override
  String get unoErrStackSameOnly => '+2:n päälle saa vain +2, +4:n päälle vain +4. +2 ei käy +4:n päälle.';

  @override
  String get unoErrCatchTooEarly => 'Odota sekunti — he ehtivät vielä sanoa Unon.';

  @override
  String get unoErrCallTooLate => 'Unoa ei voi enää sanoa. Seuraava pelaaja on jo pelannut.';

  @override
  String get gamesInDevelopment => 'Kehityksessä';

  @override
  String rulesPokerPlayers(int players) {
    return 'Pelaajat: $players.';
  }

  @override
  String get rulesPokerIntro => 'Texas Hold’em. Jokainen saa 2 taskukorttia; pöytään jaetaan 5 yhteistä korttia.';

  @override
  String get rulesPokerPlay => 'Panoskierrokset: preflop, flop, turn ja river. Fold, call, bet tai raise.';

  @override
  String get rulesPokerWin => 'Paras viiden kortin käsi (tasku + yhteiset) voittaa, tai viimeinen foldien jälkeen.';

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
  String get pokerCombinationsTitle => 'Hand rankings';

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
  String get gamesObservation => 'Katsele';

  @override
  String get gamesObservationHint => 'Voit katsoa pelin loppuun';

  @override
  String get gamesFinishCurrentFirst => 'Viimeistele ensin nykyinen peli';

  @override
  String get gamesVariantClassic => 'Klassinen';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 pelaajaa';

  @override
  String get gamesVariantMulti4 => '4 pelaajaa';

  @override
  String get gamesDurakModePodkidnoi => 'Lisäys';

  @override
  String get gamesDurakModePerevodnoi => 'Siirto';

  @override
  String get gamesDurakDeck24 => '24 korttia';

  @override
  String get gamesDurakDeck36 => '36 korttia';

  @override
  String get gamesDurakDeck52 => '52 korttia';

  @override
  String rulesDurakMode(String mode) {
    return 'Tila: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'Pelaajat: $players. Pakka: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Pelaa bottia vastaan ilman panoksia ja aikarajaa.';

  @override
  String get rulesDurakAttack => 'Hyökkääjä laittaa kortteja; puolustaja lyö ne (samaa maata korkeammalla tai valttilla). Valtti lyödään vain korkeammalla valttilla.';

  @override
  String get rulesDurakBeat => 'Kun kaikki kortit on lyöty, hyökkääjä sanoo «Bito» ja kortit menevät poistopakkaan. Muuten puolustaja ottaa kaiken pöydästä.';

  @override
  String get rulesDurakLoser => 'Häviäjä on se, jolla on kortteja lopussa — «durak».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Pelaajat $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Aula $name';
  }

  @override
  String get lobbyMatchmake => 'Aula';

  @override
  String get lobbyPrivateGame => 'Yksityispeli';

  @override
  String get lobbySearchingOpponent => 'Etsitään vastustajaa…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Etsivät tätä peliä: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Odotetaan, että joku napauttaa ”Etsi peli” tai ”Liity”';

  @override
  String get lobbyInviteTitle => 'Pelikutsu';

  @override
  String get lobbyInvitedToPlay => 'Sinut kutsuttiin pelaamaan';

  @override
  String get lobbyEnterGame => 'Siirry peliin';

  @override
  String get lobbyGone => 'Lobby ei ole enää saatavilla';

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
  String get gameYouLost => 'Hävisit';

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
  String get gameSurrender => 'Luovuta';

  @override
  String get gameSurrenderTitle => 'Luovuta?';

  @override
  String get gameSurrenderConfirm => 'Häviät pelin ja panoskolikot.';

  @override
  String get gameOfferDraw => 'Tarjoa tasapeliä';

  @override
  String get gameOfferDrawTitle => 'Tarjoa tasapeliä?';

  @override
  String get gameOfferDrawConfirm => 'Vastustaja voi hyväksyä tai hylätä tasapelin.';

  @override
  String get gameAcceptDrawTitle => 'Hyväksy tasapeli?';

  @override
  String get gameAcceptDrawConfirm => 'Peli päättyy tasapeliin.';

  @override
  String get gameDrawOffered => 'Vastustaja tarjoaa tasapeliä';

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
  String get chatPaste => 'Liitä';

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
  String get friendsSearchNoMatches => 'Ei kavereita, jotka vastaavat hakua';

  @override
  String get friendsIncomingSearchNoMatches => 'Ei hakuun sopivia saapuvia pyyntöjä';

  @override
  String get friendsOutgoingSearchNoMatches => 'Ei hakuun sopivia lähteneitä pyyntöjä';

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
  String get profileChangePhoto => 'Vaihda avatar';

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
  String get shopStakesSubtitle => 'Avaa korkeammat panokset';

  @override
  String get shopEmojisHelp => 'Animoidut emojit chattiin. Osta setti ja lähetä niitä ystäville.';

  @override
  String get shopCollectionsHelp => 'Kerää esineiden setti: ne näkyvät profiilin vitriinissä, niitä voi lahjoittaa ja myydä. Täysi kokoelma tuo lisäkolikoita joka päivä.\n\nTila riippuu siitä, kuinka kauan kokoelma on ollut sinulla. Uusi — ensimmäiset 7 päivää, myynti 80 % hinnasta. Kulunut — 8. päivästä 2 kuukauteen, myynti 60 % hinnasta. Väsynyt — 2–6 kuukautta, myynti 40 % hinnasta. Rähjäinen — 6 kuukaudesta vuoteen, myynti 100 % hinnasta. Vintage — vuodesta eteenpäin, myynti 300 % hinnasta.';

  @override
  String get shopStakesHelp => 'Avaa korkeammat panokset. Mitä korkeampi panos, sitä suurempi potti ja voitto.';

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

  @override
  String get balanceTitle => 'Saldo';

  @override
  String get coinBronze => 'Pronssi';

  @override
  String get coinSilver => 'Hopea';

  @override
  String get coinGold => 'Kulta';

  @override
  String get coinDiamond => 'Timantti';

  @override
  String get balanceZeroBronze => '0 pronssia';

  @override
  String balanceBronzes(int count) {
    return '$count pronssia';
  }

  @override
  String balanceSilvers(int count) {
    return '$count hopeaa';
  }

  @override
  String balanceGolds(int count) {
    return '$count kultaa';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count timanttia';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/pv';
  }

  @override
  String get balanceAbbrBronze => 'pr';

  @override
  String get balanceAbbrSilver => 'h.';

  @override
  String get balanceAbbrGold => 'k.';

  @override
  String get commonBackHome => 'Takaisin etusivulle';

  @override
  String get commonCopied => 'Kopioitu';

  @override
  String get commonClear => 'Tyhjennä';

  @override
  String get commonTryLater => 'Yritä myöhemmin uudelleen.';

  @override
  String get commonTryRefresh => 'Kokeile päivittää sivu.';

  @override
  String get coinsTitle => 'Kolikot';

  @override
  String get coinsLoginReward => 'Kirjautumispalkinto';

  @override
  String get coinsLoginAvailableToday => 'Päivän palkinto saatavilla';

  @override
  String get coinsLoginStreak => 'Päivittäinen kirjautumisputki';

  @override
  String get coinsFriendReward => 'Kaveripalkinto';

  @override
  String get coinsTasks => 'Tehtävät';

  @override
  String get coinsTasksSubtitle => 'Palkinnot profiilista, kavereista ja peleistä';

  @override
  String get coinsTasksRewards => 'Noudettavissa olevia palkintoja';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount rekisteröitymisestä linkkisi kautta';
  }

  @override
  String get coinsLoadRewardsFailed => 'Palkintoja ei voitu ladata';

  @override
  String get coinsClaimReward => 'Nouda palkinto';

  @override
  String get coinsAlreadyClaimed => 'Jo noudettu';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · tänään';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · 1 päivä jäljellä';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · $remaining jäljellä';
  }

  @override
  String get coinsInviteFriend => 'Kutsu kaveri';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount jokaisesta, joka rekisteröityy linkkisi kautta';
  }

  @override
  String get coinsCopyLink => 'Kopioi linkki';

  @override
  String get coinsHowItWorks => 'Miten se toimii';

  @override
  String get coinsHowStep1 => 'Kopioi linkki ja lähetä se kaverille';

  @override
  String get coinsHowStep2 => 'Kaveri rekisteröityy linkin kautta';

  @override
  String coinsHowStep3(String amount) {
    return 'Saat $amount';
  }

  @override
  String get achievementsTitle => 'Saavutukset';

  @override
  String achievementsProgress(String progress) {
    return 'Edistyminen: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Kehys noudettu';

  @override
  String get achievementsClaimed => 'Noudettu';

  @override
  String get achievementsOpenFrame => 'Avaa kehys';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Haluatko varmasti poistaa käyttäjän $name kavereista?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Poista';

  @override
  String get friendsRemove => 'Poista kavereista';

  @override
  String get friendsAcceptRequest => 'Hyväksy pyyntö';

  @override
  String get friendsDeclineRequest => 'Hylkää pyyntö';

  @override
  String get friendsCancelRequest => 'Peruuta pyyntö';

  @override
  String get friendsSendRequest => 'Lähetä kaveripyyntö';

  @override
  String get friendsRequestAlreadySent => 'Pyyntö on jo lähetetty';

  @override
  String get friendsIncomingStatus => 'Saapuva pyyntö';

  @override
  String get friendsOutgoingStatus => 'Lähtevä pyyntö';

  @override
  String get friendsNotFriends => 'Ei kavereita';

  @override
  String get friendsCollapseSearch => 'Piilota haku';

  @override
  String get friendsExpandSearch => 'Näytä haku';

  @override
  String get friendsLoadFailed => 'Kavereita ei voitu ladata';

  @override
  String friendsSince(String date) {
    return 'Kavereita alkaen: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Saapuva pyyntö: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Lähtevä pyyntö: $date';
  }

  @override
  String get userInfoTitle => 'Käyttäjätiedot';

  @override
  String profileAgeYears(int age) {
    return '$age vuotta';
  }

  @override
  String get shopBuy => 'Osta';

  @override
  String get shopBuyTitle => 'Ostetaanko?';

  @override
  String get shopBuyStakeTitle => 'Ostetaanko panos?';

  @override
  String get shopBuyEmojiTitle => 'Ostetaanko emoji?';

  @override
  String get shopBuyCollectionTitle => 'Ostetaanko kokoelma?';

  @override
  String shopPrice(String price) {
    return 'Hinta: $price';
  }

  @override
  String get shopOwned => 'Ostettu';

  @override
  String get shopHave => 'On';

  @override
  String get shopEmpty => 'Vielä tyhjä';

  @override
  String shopPurchased(String title) {
    return '$title ostettu';
  }

  @override
  String get shopEmojiUses => 'Saat: 10 käyttöä';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 käyttöä';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 käyttöä';
  }

  @override
  String get shopBuyTen => 'Osta · 10 kpl';

  @override
  String shopDailyIncome(String amount) {
    return 'Tulo: $amount';
  }

  @override
  String get shopBuyOnce => 'Kertaluonteinen osto';

  @override
  String get shopSellRefund => 'Myynti riippuu kokoelman tilasta';

  @override
  String get collectionConditionNew => 'Uusi';

  @override
  String get collectionConditionWorn => 'Kulunut';

  @override
  String get collectionConditionTired => 'Väsynyt';

  @override
  String get collectionConditionShabby => 'Rähjäinen';

  @override
  String get collectionConditionVintage => 'Vintage';

  @override
  String shopCollectionAdded(String title) {
    return '$title lisätty profiiliin';
  }

  @override
  String shopSetBonus(int percent) {
    return 'settibonus +$percent%';
  }

  @override
  String get shopSetComplete => 'Valmis';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Kerätty · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Myydäänkö?';

  @override
  String inventorySellDesc(String amount) {
    return 'Saat $amount';
  }

  @override
  String inventorySold(String amount) {
    return 'Myyty: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Lisää ensin kavereita';

  @override
  String get inventoryGiftTitle => 'Lahjoitetaanko kokoelma?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'Lahjoitetaanko «$title» käyttäjälle $name?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Lahjoitettu: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'Pelaajalla on jo tämä esine';

  @override
  String get inventoryGiftSelf => 'Et voi antaa itsellesi lahjaa';

  @override
  String get inventoryGiftNotOwned => 'Tätä esinettä ei ole inventaariossasi';

  @override
  String get inventoryLoadFailed => 'Esineitä ei voitu ladata';

  @override
  String get inventoryNoCollections => 'Ei kokoelmia — osta kaupasta';

  @override
  String get inventoryNoEmojis => 'Ei emojeja — osta kaupasta';

  @override
  String get inventoryNoFrames => 'Ei kehyksiä — voita 10 liigaottelua (saavutukset)';

  @override
  String get inventoryNoStakes => 'Ei ostettuja panoksia';

  @override
  String inventoryEmojiLeft(int count) {
    return '$count jäljellä';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Tulo: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Tulo huomenna: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Valmis';

  @override
  String get inventoryIncomeTomorrowLabel => 'Huomenna';

  @override
  String inventoryStakeGold(String amount) {
    return 'Voit panostaa $amount kultaa';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'Voit panostaa $amount hopeaa';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'Noudettu +$amount';
  }

  @override
  String get chatsLoadFailed => 'Chatteja ei voitu ladata';

  @override
  String get chatsLoadListFailed => 'Listaa ei voitu ladata';

  @override
  String get chatsBlockedEmpty => 'Lista on tyhjä';

  @override
  String chatsBlockedAt(String date) {
    return 'Estetty: $date';
  }

  @override
  String get chatsCreateFailed => 'Chattia ei voitu luoda';

  @override
  String get chatsNeedFriendsFirst => 'Lisää ensin kavereita, sitten voit avata chatin.';

  @override
  String get chatsFriendsNotFound => 'Kavereita ei löytynyt';

  @override
  String get chatsFindFriendHint => 'Etsi kaveria nimimerkillä';

  @override
  String get chatsSelectChat => 'Valitse chat';

  @override
  String get chatsSelectHint => 'Valitse keskustelu vasemmalla olevasta listasta';

  @override
  String get chatEditFailed => 'Viestiä ei voitu muokata';

  @override
  String get chatSendFailed => 'Viestiä ei voitu lähettää';

  @override
  String get chatDeleteFailed => 'Viestiä ei voitu poistaa';

  @override
  String get chatEmojiSendFailed => 'Emojia ei voitu lähettää';

  @override
  String get chatLoadFailed => 'Viestejä ei voitu ladata';

  @override
  String get chatBackToGame => 'Takaisin peliin';

  @override
  String get chatBackToChats => 'Takaisin chatteihin';

  @override
  String get chatActions => 'Chatin toiminnot';

  @override
  String get chatAutoTranslate => 'Auto-translate';

  @override
  String get chatScrollToEnd => 'Keskustelun loppuun';

  @override
  String chatReplyingTo(String name) {
    return 'Vastaus käyttäjälle $name';
  }

  @override
  String get chatGift => 'Lahja';

  @override
  String get chatCollection => 'Kokoelma';

  @override
  String get chatGiftCollection => 'Lahja · kokoelma';

  @override
  String get chatThisUser => 'tätä käyttäjää';

  @override
  String get gamesLobbyLoadFailed => 'Aulaa ei voitu ladata.';

  @override
  String get gamesTapChangeStake => 'Napauta vaihtaaksesi panoksen';

  @override
  String get gamesTapChangeTurnTime => 'Napauta vaihtaaksesi vuoron ajan';

  @override
  String get gamesTapChangeGrid => 'Napauta vaihtaaksesi ruudukon koon';

  @override
  String get gamesSwapSidesHint => 'O voi muuttua X:ksi 1. siirron jälkeen';

  @override
  String get gamesNoCenterHint => 'Ensimmäinen siirto ei voi olla keskelle';

  @override
  String get lobbyInviteSentShort => 'Lähetetty';

  @override
  String get lobbySearchShort => 'Haku';

  @override
  String get lobbySearchPlayers => 'Etsi pelaajia';

  @override
  String get lobbyInviteDeclinedShort => 'Hylätty';

  @override
  String get lobbyInvitesSentWaiting => 'Kutsut lähetetty. Odotetaan vastausta.';

  @override
  String get lobbyLinkCopiedHint => 'Liitä se chattiin tai viestiin kaverille';

  @override
  String get lobbyCopyLinkHint => 'Kopioi linkki leikepöydälle';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name kutsuu sinut pelaamaan';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name voitti';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Aika loppui. $name voitti';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String get adminTitle => 'Hallinta';

  @override
  String get tournamentsTitle => 'Turnaukset';

  @override
  String get profileAgeInvalid => 'Anna ikä välillä 1–111';

  @override
  String get profileSaveFailed => 'Profiilia ei voitu tallentaa';

  @override
  String get profileNameHint => 'Latinalaiset kirjaimet, numerot, _ enintään 10 merkkiä';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => '1–111';

  @override
  String get profileAboutHint => 'Enintään 100 merkkiä (valinnainen)';

  @override
  String get profileProcessingPhoto => 'Käsitellään kuvaa…';

  @override
  String get profileCropTitle => 'Valitse avatarin alue';

  @override
  String get profileCropHint => 'Zoomaa ja siirrä kuvaa';

  @override
  String get profileApply => 'Käytä';

  @override
  String get profilePreparing => 'Valmistellaan…';

  @override
  String get profileGalleryTitle => 'Kuvat';

  @override
  String get profileGalleryAdd => 'Lisää kuva';

  @override
  String get profileMakePrimary => 'Aseta pääkuvaksi';

  @override
  String get profilePhotoDelete => 'Poista kuva';

  @override
  String get profilePhotosLimit => 'Voit ladata enintään 3 kuvaa';

  @override
  String get profilePhotosEmpty => 'Ei kuvia vielä';

  @override
  String get profilePhotoUploadFailed => 'Kuvan lataus epäonnistui';

  @override
  String get profilePhotoDeleteFailed => 'Kuvan poisto epäonnistui';

  @override
  String get profilePhotoTooLarge => 'Kuva on liian suuri';

  @override
  String get profileSetPrimaryFailed => 'Pääkuvaksi asettaminen epäonnistui';

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
    return 'Ristinolla $grid-laudalla. Vuorotellen; X aloittaa.';
  }

  @override
  String rulesWin(int n) {
    return 'Voitto: saa $n putkeen vaaka-, pysty- tai vinorivissä.';
  }

  @override
  String get rulesNoTimeLimit => 'Ei aikarajaa siirrolle.';

  @override
  String rulesTurnTime(String time) {
    return 'Aika per siirto: $time. Ajan loppuminen on tappio.';
  }

  @override
  String rulesStake(String stake) {
    return 'Panos: $stake. Peli käydään näillä kolikoilla.';
  }

  @override
  String get rulesSwap => 'Puolenvaihto: O voi vaihtaa X:n kanssa X:n ensimmäisen siirron jälkeen.';

  @override
  String get rulesNoCenter => 'Kielto keskelle: X ei saa pelata keskelle ensimmäisellä siirrolla.';

  @override
  String get collectionSetLegends => 'Legendat';

  @override
  String get collectionSetSpace => 'Avaruus';

  @override
  String get collectionSetGems => 'Jalokivet';

  @override
  String get collectionSetParty => 'Juhla';

  @override
  String get collectionSetNature => 'Luonto';

  @override
  String get collectionSetAdventures => 'Seikkailut';

  @override
  String collectionCardMeta(String amount) {
    return 'Kokoelma · näyteikkuna · lahja · myynti · +$amount';
  }

  @override
  String get coinsDayOne => 'päivä';

  @override
  String get coinsDayFew => 'päivää';

  @override
  String get coinsDayMany => 'päivää';

  @override
  String get giftFriendTitle => 'Anna kaverille';

  @override
  String photoCount(int count) {
    return 'Kuva ($count)';
  }

  @override
  String photoCountWithText(int count, String text) {
    return 'Kuva ($count): $text';
  }

  @override
  String photoWithText(String text) {
    return 'Kuva: $text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count emojia · $price';
  }

  @override
  String get chatsExpandPanel => 'Laajenna paneeli';

  @override
  String get chatsCollapsePanel => 'Pienennä paneeli';

  @override
  String get chatReplySourceMissing => 'Alkuperäistä viestiä ei löydy';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Panos $n hopeaa';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Panos $n kultaa';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Avaa panoksen $n hopeaa';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Avaa panoksen $n kultaa';
  }

  @override
  String get chatReplySelf => 'itsellesi';

  @override
  String get chatReplyPeer => 'keskustelukumppanille';

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
  String get statsTitle => 'Tilastot';

  @override
  String get statsLoadFailed => 'Tilastojen lataus epäonnistui';

  @override
  String get statsAllGames => 'Kaikki pelit';

  @override
  String get statsEmptyTitle => 'Ei vielä pelattuja pelejä';

  @override
  String get statsEmptyHint => 'Pelaa ensimmäinen pelisi nähdäksesi tilastot täällä.';

  @override
  String get statsWins => 'Voitot';

  @override
  String get statsDraws => 'Tasapelit';

  @override
  String get statsLosses => 'Tappiot';

  @override
  String get statsWinRate => 'Voittoprosentti';

  @override
  String get statsTopWon => 'Eniten voittoja vastaan';

  @override
  String get statsTopDrawn => 'Eniten tasapelejä kanssa';

  @override
  String get statsTopLost => 'Eniten tappioita vastaan';

  @override
  String get statsTimePlayed => 'Peliaika';

  @override
  String get statsYourScore => 'Tilanteesi';

  @override
  String get profileShowStats => 'Näytä tilastot';

  @override
  String get statsDurationZeroMinutes => '0 min';

  @override
  String get gameYouWonOpponentForfeit => 'Vastustaja luovutti. Voitit!';

  @override
  String get lobbyLeaveTitle => 'Poistu lobbysta?';

  @override
  String get lobbyLeaveConfirm => 'Lobbyn poistetaan poistumisen jälkeen. Kutsutut ystävät saavat hylkäyksen.';

  @override
  String get lobbyLeave => 'Poistu';

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
    return 'Luovutit. $name voitti';
  }

  @override
  String get supportTitle => 'Tuki';

  @override
  String get supportUnavailable => 'Tuki ei ole käytettävissä';

  @override
  String get supportOpenFailed => 'Tukichatin avaaminen epäonnistui';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Sinulle on hyvitetty $amount kolikkoa';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return '$amount kolikkoa vähennetty';
  }

  @override
  String get coinsCreditCardTitle => 'Sinulle on hyvitetty kolikoita';

  @override
  String get coinsClaim => 'Nouda';

  @override
  String get durakActionPass => 'Passaa';

  @override
  String get durakRoleTook => 'Ottaa';

  @override
  String get durakRoleBeats => 'Lyö';

  @override
  String get durakRoleThrowIn => 'Lisäys';

  @override
  String get durakRoleTurn => 'Vuoro';

  @override
  String get durakRoleDefends => 'Puolustaa';

  @override
  String get durakStatusTaking => 'Ottaa';

  @override
  String get durakHintDefenderTurn => 'Puolustajan vuoro';

  @override
  String get gameYouEliminated => 'Pudotit';

  @override
  String gameYouPlaced(int place) {
    return 'Sijoituksesi: $place';
  }

  @override
  String get gameOverNeutral => 'Peli päättyi';

  @override
  String gameTurnOf(String name) {
    return 'Vuoro: $name';
  }

  @override
  String get chatGroupTooltip => 'Ryhmächat';

  @override
  String get lobbyChatNotReady => 'Aulan chat ei ole vielä valmis';

  @override
  String get chatsGroupChat => 'Ryhmächat';

  @override
  String chatsMembersCount(int count) {
    return 'Jäsenet: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count hlö';
  }

  @override
  String get chatsYouSuffix => '(sinä)';

  @override
  String get chatTitleDurak3 => 'Durak · 3 pelaajaa';

  @override
  String get chatTitleDurak4 => 'Durak · 4 pelaajaa';

  @override
  String get rulesTttUltimate => 'Ultimate: yhdeksän 3×3-minilautaa. Siirto lähettää vastustajan kyseiselle minilaudalle. Voita meta-laudan viivalla.';

  @override
  String get rulesTttMulti3 => '3 pelaajaa: 3×3-lauta, kolme pelaajaa (X, O, △). Voita omien merkkien rivillä.';

  @override
  String get rulesTttMulti4 => '4 pelaajaa: 4×4-lauta, neljä pelaajaa (X, O, △, □). Voita omien merkkien rivillä.';

  @override
  String get adminUsersTab => 'Käyttäjät';

  @override
  String get adminSupportTab => 'Tuki';

  @override
  String get adminSearchHint => 'Hae sähköpostilla tai nimellä';

  @override
  String get adminRoleAdmins => 'Ylläpitäjät';

  @override
  String get adminRoleUsers => 'Käyttäjät';

  @override
  String get adminRoleAll => 'Kaikki roolit';

  @override
  String get adminStatusFrozen => 'Jäädytetyt';

  @override
  String get adminStatusActive => 'Aktiiviset';

  @override
  String get adminStatusAny => 'Mikä tahansa tila';

  @override
  String get adminOrderDesc => 'Laskeva';

  @override
  String get adminOrderAsc => 'Nouseva';

  @override
  String adminLoadFailed(String error) {
    return 'Lataus epäonnistui: $error';
  }

  @override
  String get adminUsersEmpty => 'Ei käyttäjiä';

  @override
  String get adminSortLastSeen => 'Viimeisen käynnin mukaan';

  @override
  String get adminSortEmail => 'Sähköpostin mukaan';

  @override
  String get adminSortCreated => 'Rekisteröintipäivän mukaan';

  @override
  String adminBronzeBalance(int amount) {
    return '$amount pr.';
  }

  @override
  String get adminRevokeAdmin => 'Poista ylläpito';

  @override
  String get adminGrantAdmin => 'Tee ylläpitäjäksi';

  @override
  String get adminAdminRevoked => 'Ylläpito-oikeudet poistettu';

  @override
  String get adminAdminGranted => 'Ylläpito-oikeudet annettu';

  @override
  String get adminGrantCoins => 'Anna kolikoita';

  @override
  String get adminWriteSupport => 'Kirjoita tukena';

  @override
  String get adminUnfreeze => 'Poista jäädytys';

  @override
  String get adminFreeze => 'Jäädytä';

  @override
  String get adminUnfrozen => 'Jäädytys poistettu';

  @override
  String get adminFrozenDone => 'Jäädytetty';

  @override
  String get adminResetPassword => 'Nollaa salasana';

  @override
  String get adminCoinsAmountHint => 'Määrä (negatiivinen = vähennys)';

  @override
  String get adminReasonOptional => 'Syy (valinnainen)';

  @override
  String get adminGrantSent => 'Kortti lähetettiin tukichattiin';

  @override
  String adminCoinsDebited(int amount) {
    return 'Vähennettiin $amount pronssia';
  }

  @override
  String get adminGrantVerb => 'Anna';

  @override
  String get adminNewPasswordHint => 'Uusi salasana (väh. 6)';

  @override
  String get adminPasswordReset => 'Salasana nollattu';

  @override
  String get adminResetVerb => 'Nollaa';

  @override
  String adminShortError(String error) {
    return 'Virhe: $error';
  }

  @override
  String get adminSupportEmpty => 'Ei tukipyyntöjä';

  @override
  String get adminUserFallback => 'Käyttäjä';

  @override
  String get apiErrTooManyRequests => 'Liian monta pyyntöä. Yritä myöhemmin.';

  @override
  String get apiErrMoveConflict => 'Siirto ristiriidassa. Yritä uudelleen.';
}
