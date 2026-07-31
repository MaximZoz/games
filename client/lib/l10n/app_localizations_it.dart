import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Inizio';

  @override
  String get navProfile => 'Profilo';

  @override
  String get navFriends => 'Amici';

  @override
  String get navChats => 'Chat';

  @override
  String get navGames => 'Giochi';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLanguageSystem => 'Predefinita di sistema';

  @override
  String get settingsAddBotsTitle => 'Aggiungi bot dopo 30 s';

  @override
  String get settingsAddBotsSubtitle => 'In matchmaking: se non trovi un avversario in 30 secondi, la partita inizia con un bot (puntata riportata a 1 bronzo)';

  @override
  String get settingsFriendsOnlyTitle => 'Messaggi solo dagli amici';

  @override
  String get settingsFriendsOnlySubtitle => 'Chi non è amico può inviare solo emoji. Se c’è spam, blocca temporaneamente l’utente.';

  @override
  String get settingsNotifications => 'Notifiche';

  @override
  String get settingsPushChat => 'Chat';

  @override
  String get settingsPushFriends => 'Amici';

  @override
  String get settingsPushGames => 'Giochi';

  @override
  String get settingsPushRewards => 'Ricompense';

  @override
  String get loginTitle => 'Accedi';

  @override
  String get loginSubtitle => 'Inserisci e-mail o nome utente e password';

  @override
  String get loginEmailLabel => 'E-mail o nome utente';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginSubmit => 'Accedi';

  @override
  String get loginNoAccount => 'Non hai un account? Registrati';

  @override
  String get loginEmailRequired => 'Inserisci e-mail o nome utente';

  @override
  String get loginPasswordRequired => 'Inserisci la password';

  @override
  String get loginTooltip => 'Accedi';

  @override
  String get logoutTooltip => 'Esci';

  @override
  String get registerTitle => 'Registrati';

  @override
  String get registerSubtitle => 'Crea un account per giocare';

  @override
  String get registerNameLabel => 'Nome (username)';

  @override
  String get registerEmailLabel => 'E-mail';

  @override
  String get registerPasswordLabel => 'Password';

  @override
  String get registerSubmit => 'Registrati';

  @override
  String get registerHaveAccount => 'Hai già un account? Accedi';

  @override
  String get registerNameRequired => 'Inserisci un nome';

  @override
  String get registerNameNoSpaces => 'Il nome non può contenere spazi';

  @override
  String get registerNameMax => 'Massimo 20 caratteri';

  @override
  String get registerNameHint => 'Fino a 20 caratteri';

  @override
  String get registerEmailRequired => 'Inserisci l’e-mail';

  @override
  String get registerEmailInvalid => 'E-mail non valida';

  @override
  String get registerPasswordHint => 'Almeno 6 caratteri';

  @override
  String get registerPasswordMin => 'La password deve avere almeno 6 caratteri';

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonSave => 'Salva';

  @override
  String get commonDelete => 'Elimina';

  @override
  String get commonEdit => 'Modifica';

  @override
  String get commonReply => 'Rispondi';

  @override
  String get commonSend => 'Invia';

  @override
  String get commonClose => 'Chiudi';

  @override
  String get commonRetry => 'Riprova';

  @override
  String get commonLoading => 'Caricamento…';

  @override
  String get commonError => 'Errore';

  @override
  String get commonOnline => 'in linea';

  @override
  String get commonOffline => 'non in linea';

  @override
  String get commonOnlineCap => 'In linea';

  @override
  String get commonUser => 'Utente';

  @override
  String get commonPlayer => 'Giocatore';

  @override
  String get commonAboutMe => 'Su di me';

  @override
  String get commonBack => 'Indietro';

  @override
  String get commonAccept => 'Accetta';

  @override
  String get commonDecline => 'Rifiuta';

  @override
  String get commonCreating => 'Creazione…';

  @override
  String get commonSearching => 'Ricerca…';

  @override
  String get commonInsufficientCoins => 'Monete insufficienti';

  @override
  String get commonNotFound => 'Non trovato';

  @override
  String get commonServerErrorShort => 'Errore del server';

  @override
  String get commonForbidden => 'Accesso negato';

  @override
  String get commonUserBlocked => 'Utente bloccato';

  @override
  String get commonUserNotFound => 'Utente non trovato';

  @override
  String get commonGenericError => 'Qualcosa è andato storto. Riprova.';

  @override
  String get timeJustNow => 'adesso';

  @override
  String get timeYesterday => 'ieri';

  @override
  String timeMinutesAgo(int count) {
    return '$count min fa';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count h fa';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count g fa';
  }

  @override
  String get timeWeekAgo => 'una settimana fa';

  @override
  String timeWeeksAgo(int count) {
    return '$count sett. fa';
  }

  @override
  String get timeMonthAgo => 'un mese fa';

  @override
  String timeMonthsAgo(int count) {
    return '$count mesi fa';
  }

  @override
  String get timeYearAgo => 'un anno fa';

  @override
  String timeYearsAgo(int count) {
    return '$count anni fa';
  }

  @override
  String get weekdaySun => 'Dom';

  @override
  String get weekdayMon => 'Lun';

  @override
  String get weekdayTue => 'Mar';

  @override
  String get weekdayWed => 'Mer';

  @override
  String get weekdayThu => 'Gio';

  @override
  String get weekdayFri => 'Ven';

  @override
  String get weekdaySat => 'Sab';

  @override
  String get monthJan => 'Gen';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'Mag';

  @override
  String get monthJun => 'Giu';

  @override
  String get monthJul => 'Lug';

  @override
  String get monthAug => 'Ago';

  @override
  String get monthSep => 'Set';

  @override
  String get monthOct => 'Ott';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dic';

  @override
  String get homeAchievements => 'Obiettivi';

  @override
  String get homeAchievementsSubtitle => 'I tuoi risultati di gioco';

  @override
  String get homeAchievementsRewards => 'Ricompense da riscattare';

  @override
  String get homeCoins => 'Monete';

  @override
  String get homeCoinsSubtitle => 'Saldo e ricompense';

  @override
  String get homeCoinsDailyReward => 'Ricompensa giornaliera di accesso disponibile';

  @override
  String get homeItems => 'Oggetti';

  @override
  String get homeItemsInventory => 'Il tuo inventario';

  @override
  String get homeItemsGifted => 'Qualcuno ti ha regalato una collezione';

  @override
  String get homeItemsIncome => 'Entrate della collezione da riscattare';

  @override
  String get homeShop => 'Negozio';

  @override
  String get homeShopSubtitle => 'Emoji, puntate, collezioni';

  @override
  String get gamesTitle => 'Giochi';

  @override
  String get gamesFindMatch => 'Trova una partita';

  @override
  String get gamesMyTurn => 'Il tuo turno';

  @override
  String get gamesWaiting => 'In attesa';

  @override
  String get gamesLobbyTab => 'Lobby';

  @override
  String get gamesTicTacToe => 'Tris';

  @override
  String get gamesRules => 'Regole';

  @override
  String get gamesRulesTitle => 'Regole del gioco';

  @override
  String get gamesCreate => 'Crea partita';

  @override
  String get gamesJoin => 'Unisciti';

  @override
  String get gamesOpponentTurn => 'Turno dell’avversario';

  @override
  String get gamesCurrentGame => 'Partita in corso';

  @override
  String get gamesInvitedYou => 'Sei stato invitato';

  @override
  String get gamesTurnTime => 'Tempo per turno';

  @override
  String get gamesGridSize => 'Dimensione griglia';

  @override
  String get gamesSwapSides => 'Scambio di lato';

  @override
  String get gamesNoCenter => 'Niente partenza al centro';

  @override
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Partita privata';

  @override
  String get lobbySearchingOpponent => 'Ricerca di un avversario…';

  @override
  String get lobbyWaitingJoin => 'In attesa che qualcuno tocchi «Trova una partita» o «Unisciti»';

  @override
  String get lobbyInviteTitle => 'Invito a giocare';

  @override
  String get lobbyInvitedToPlay => 'Sei stato invitato a giocare';

  @override
  String get lobbyEnterGame => 'Entra nella partita';

  @override
  String get lobbyInvite => 'Invita';

  @override
  String get lobbyInviteSent => 'Invito inviato';

  @override
  String get lobbyCopyLink => 'Condividi link della partita';

  @override
  String get lobbyLinkCopied => 'Link copiato';

  @override
  String get lobbyNoFriendsOnline => 'Nessun amico online. Condividi il link sopra o aspetta che gli amici si colleghino.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Avversario';

  @override
  String get gameYouWon => 'Hai vinto!';

  @override
  String get gameYouWonOpponentLeft => 'Hai vinto — l’avversario ha lasciato';

  @override
  String get gameYouWonOpponentTimeout => 'Hai vinto — all’avversario è scaduto il tempo';

  @override
  String get gameDraw => 'Pareggio';

  @override
  String get gameExitTitle => 'Lascia la partita';

  @override
  String get gameExitConfirm => 'Se esci, perderai. Uscire comunque?';

  @override
  String get gameStay => 'Resta';

  @override
  String get gameLeave => 'Esci';

  @override
  String get gameConnecting => 'Connessione alla partita…';

  @override
  String get gameWaitingOpponent => 'In attesa dell’avversario';

  @override
  String get gameRematchOffer => 'L’avversario propone una rivincita';

  @override
  String get gameRematchDeclined => 'L’avversario ha rifiutato la rivincita';

  @override
  String get gameRematch => 'Rivincita';

  @override
  String get gameOtherOpponent => 'Altro avversario';

  @override
  String get gameSwapSidesAction => 'Cambia lato';

  @override
  String get gameWriteMessage => 'Scrivi un messaggio';

  @override
  String get chatsTitle => 'Chat';

  @override
  String get chatsEmpty => 'Nessuna chat ancora.\nTocca l’icona in alto a destra per scegliere un amico e iniziare a chattare.';

  @override
  String get chatsNewChat => 'Nuova chat';

  @override
  String get chatsNoMessages => 'Nessun messaggio';

  @override
  String get chatsClearTitle => 'Cancellare la conversazione?';

  @override
  String get chatsClearDesc => 'La chat verrà eliminata definitivamente.';

  @override
  String get chatsClearConfirm => 'Cancella';

  @override
  String get chatsBlockTitle => 'Bloccare questo utente?';

  @override
  String get chatsBlockDesc => 'Non potrete più scrivervi. Chat e amicizia verranno rimosse.';

  @override
  String get chatsBlockConfirm => 'Blocca';

  @override
  String get chatsBlockedUsers => 'Utenti bloccati';

  @override
  String get chatsUnblock => 'Sblocca';

  @override
  String get chatDialog => 'Chat';

  @override
  String get chatEmpty => 'Nessun messaggio ancora.\nInvia il primo.';

  @override
  String get chatMessageHint => 'Messaggio';

  @override
  String get chatEmoji => 'Emoji';

  @override
  String get chatBuyEmojiHint => 'Compra emoji nel negozio nella schermata iniziale';

  @override
  String get chatEditing => 'Modifica';

  @override
  String get chatToday => 'Oggi';

  @override
  String get chatYesterday => 'Ieri';

  @override
  String get chatFriendsOnly => 'Testo solo per gli amici';

  @override
  String get emojiGroupEmotions => 'Emozioni';

  @override
  String get emojiGroupGame => 'Giochi';

  @override
  String get emojiGroupFlags => 'Bandiere';

  @override
  String get emojiGroupAnimals => 'Animali';

  @override
  String get emojiGroupFood => 'Cibo';

  @override
  String get emojiGroupTravel => 'Viaggi';

  @override
  String get emojiGroupParty => 'Festa';

  @override
  String get emojiGroupObjects => 'Oggetti';

  @override
  String get friendsTitle => 'Amici';

  @override
  String get friendsTabFriends => 'Amici';

  @override
  String get friendsTabIncoming => 'In arrivo';

  @override
  String get friendsTabOutgoing => 'In uscita';

  @override
  String get friendsAdd => 'Aggiungi amico';

  @override
  String get friendsRequestSent => 'Richiesta inviata';

  @override
  String get friendsFindTab => 'Trova amico';

  @override
  String get friendsSearchHint => 'Cerca per nome utente';

  @override
  String get friendsSearchPrompt => 'Usa la ricerca per trovare nuovi amici';

  @override
  String get friendsNothingFound => 'Nessun risultato';

  @override
  String get friendsEmpty => 'Non hai ancora amici';

  @override
  String get friendsNoIncoming => 'Nessuna richiesta in arrivo';

  @override
  String get friendsNoOutgoing => 'Nessuna richiesta in uscita';

  @override
  String get friendsAlreadyFriends => 'Già amici';

  @override
  String get friendsRemoveTitle => 'Rimuovere dagli amici?';

  @override
  String get friendsRemoved => 'Rimosso dagli amici';

  @override
  String get friendsRequestAccepted => 'Richiesta accettata';

  @override
  String get friendsRequestDeclined => 'Richiesta rifiutata';

  @override
  String get friendsRequestCancelled => 'Richiesta annullata';

  @override
  String get profileTitle => 'Profilo';

  @override
  String get profileSignInPrompt => 'Accedi al tuo account';

  @override
  String get profileSignInHint => 'Per configurare il tuo profilo personale';

  @override
  String get profileEdit => 'Modifica';

  @override
  String get profileCollections => 'Collezioni';

  @override
  String get profileAge => 'Età';

  @override
  String get profileGender => 'Genere';

  @override
  String get profileGenderUnset => 'Non impostato';

  @override
  String get profileGenderMale => 'Uomo';

  @override
  String get profileGenderFemale => 'Donna';

  @override
  String get profileAvatar => 'Avatar';

  @override
  String get profileUploadPhoto => 'Carica foto';

  @override
  String get profileChangePhoto => 'Cambia foto';

  @override
  String get shopTitle => 'Negozio';

  @override
  String get shopEmojis => 'Emoji';

  @override
  String get shopEmojisSubtitle => 'Emoji animate per la chat';

  @override
  String get shopCollections => 'Collezioni';

  @override
  String get shopCollectionsSubtitle => 'Vetrina del profilo, regali e entrate';

  @override
  String get shopStakes => 'Puntate';

  @override
  String get shopStakesSubtitle => 'Sblocca le puntate d’argento';

  @override
  String get inventoryTitle => 'Oggetti';

  @override
  String get inventoryEmpty => 'Ancora niente qui — dai un’occhiata al negozio';

  @override
  String get inventoryFrames => 'Cornici';

  @override
  String get inventoryClaim => 'Riscatta';

  @override
  String get inventorySell => 'Vendi';

  @override
  String get inventoryGift => 'Regala';

  @override
  String get messageEdited => 'modificato';

  @override
  String get messageDeleted => 'Messaggio eliminato';

  @override
  String get photo => 'Foto';

  @override
  String get camera => 'Fotocamera';

  @override
  String get gallery => 'Galleria';

  @override
  String get connectionError => 'Impossibile connettersi al server.';

  @override
  String get serverError => 'Errore del server. Riprova più tardi.';

  @override
  String get sessionExpired => 'Sessione scaduta. Accedi di nuovo.';

  @override
  String get errNoInternet => 'Nessuna connessione Internet.';

  @override
  String get errTimeout => 'Tempo scaduto. Riprova.';

  @override
  String get errGamesUnavailable => 'I giochi non sono temporaneamente disponibili';

  @override
  String get errSettingsSaveFailed => 'Impossibile salvare l’impostazione';

  @override
  String get errPushPermission => 'Consenti le notifiche nelle impostazioni del browser o del sistema.';

  @override
  String get balanceTitle => 'Saldo';

  @override
  String get coinBronze => 'Bronzo';

  @override
  String get coinSilver => 'Argento';

  @override
  String get coinGold => 'Oro';

  @override
  String get coinDiamond => 'Diamante';

  @override
  String get balanceZeroBronze => '0 bronzo';

  @override
  String balanceBronzes(int count) {
    return '$count bronzo';
  }

  @override
  String balanceSilvers(int count) {
    return '$count argento';
  }

  @override
  String balanceGolds(int count) {
    return '$count oro';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count diamanti';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount al giorno';
  }

  @override
  String get balanceAbbrBronze => 'br';

  @override
  String get balanceAbbrSilver => 'ar.';

  @override
  String get balanceAbbrGold => 'oro';

  @override
  String get commonBackHome => 'Torna alla home';

  @override
  String get commonCopied => 'Copiato';

  @override
  String get commonClear => 'Cancella';

  @override
  String get commonTryLater => 'Riprova più tardi.';

  @override
  String get commonTryRefresh => 'Prova ad aggiornare la pagina.';

  @override
  String get coinsTitle => 'Monete';

  @override
  String get coinsLoginReward => 'Ricompensa di accesso';

  @override
  String get coinsLoginAvailableToday => 'Ricompensa di oggi disponibile';

  @override
  String get coinsLoginStreak => 'Serie di accessi giornalieri';

  @override
  String get coinsFriendReward => 'Ricompensa amico';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount per la registrazione tramite il tuo link';
  }

  @override
  String get coinsLoadRewardsFailed => 'Impossibile caricare le ricompense';

  @override
  String get coinsClaimReward => 'Ritira ricompensa';

  @override
  String get coinsAlreadyClaimed => 'Già ritirata';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · oggi';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · ancora 1 giorno';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · ancora $remaining';
  }

  @override
  String get coinsInviteFriend => 'Invita un amico';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount per ognuno che si registra con il tuo link';
  }

  @override
  String get coinsCopyLink => 'Copia link';

  @override
  String get coinsHowItWorks => 'Come funziona';

  @override
  String get coinsHowStep1 => 'Copia il link e invialo a un amico';

  @override
  String get coinsHowStep2 => 'L’amico si registra con quel link';

  @override
  String coinsHowStep3(String amount) {
    return 'Ricevi $amount';
  }

  @override
  String get achievementsTitle => 'Obiettivi';

  @override
  String achievementsProgress(String progress) {
    return 'Progresso: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Cornice ottenuta';

  @override
  String get achievementsClaimed => 'Ottenuto';

  @override
  String get achievementsOpenFrame => 'Apri cornice';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Sei sicuro di voler rimuovere $name dagli amici?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Rimuovi';

  @override
  String get friendsRemove => 'Rimuovi dagli amici';

  @override
  String get friendsAcceptRequest => 'Accetta richiesta';

  @override
  String get friendsDeclineRequest => 'Rifiuta richiesta';

  @override
  String get friendsCancelRequest => 'Annulla richiesta';

  @override
  String get friendsSendRequest => 'Invia richiesta di amicizia';

  @override
  String get friendsRequestAlreadySent => 'Richiesta già inviata';

  @override
  String get friendsIncomingStatus => 'Richiesta in arrivo';

  @override
  String get friendsOutgoingStatus => 'Richiesta inviata';

  @override
  String get friendsNotFriends => 'Non amici';

  @override
  String get friendsCollapseSearch => 'Comprimi ricerca';

  @override
  String get friendsExpandSearch => 'Mostra ricerca';

  @override
  String get friendsLoadFailed => 'Impossibile caricare gli amici';

  @override
  String friendsSince(String date) {
    return 'Amici dal: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Richiesta in arrivo: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Richiesta inviata: $date';
  }

  @override
  String get userInfoTitle => 'Info utente';

  @override
  String profileAgeYears(int age) {
    return '$age anni';
  }

  @override
  String get shopBuy => 'Compra';

  @override
  String get shopBuyTitle => 'Comprare?';

  @override
  String get shopBuyStakeTitle => 'Comprare la puntata?';

  @override
  String get shopBuyEmojiTitle => 'Comprare l’emoji?';

  @override
  String get shopBuyCollectionTitle => 'Comprare la collezione?';

  @override
  String shopPrice(String price) {
    return 'Prezzo: $price';
  }

  @override
  String get shopOwned => 'Acquistato';

  @override
  String get shopEmpty => 'Ancora vuoto';

  @override
  String shopPurchased(String title) {
    return '$title acquistato';
  }

  @override
  String get shopEmojiUses => 'Ottieni: 10 utilizzi';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 utilizzi';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 utilizzi';
  }

  @override
  String get shopBuyTen => 'Compra · 10 pz';

  @override
  String shopDailyIncome(String amount) {
    return 'Rendita: $amount';
  }

  @override
  String get shopBuyOnce => 'Acquisto una tantum';

  @override
  String get shopSellRefund => 'La vendita rimborsa parte del costo';

  @override
  String shopCollectionAdded(String title) {
    return '$title aggiunto al profilo';
  }

  @override
  String shopSetBonus(int percent) {
    return 'bonus set +$percent%';
  }

  @override
  String get shopSetComplete => 'Completo';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Raccolto · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Vendere?';

  @override
  String inventorySellDesc(String amount) {
    return 'Riceverai $amount';
  }

  @override
  String inventorySold(String amount) {
    return 'Venduto: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Aggiungi prima degli amici';

  @override
  String get inventoryGiftTitle => 'Regalare la collezione?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'Regalare «$title» a $name?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Regalato: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'У этого пользователя уже есть эта коллекция';

  @override
  String get inventoryGiftSelf => 'Нельзя подарить коллекцию самому себе';

  @override
  String get inventoryGiftNotOwned => 'У вас нет этого предмета';

  @override
  String get inventoryLoadFailed => 'Impossibile caricare gli oggetti';

  @override
  String get inventoryNoCollections => 'Nessuna collezione — acquistale nel negozio';

  @override
  String get inventoryNoEmojis => 'Nessuna emoji — acquistale nel negozio';

  @override
  String get inventoryNoFrames => 'Nessuna cornice — vinci 10 partite di lega (obiettivi)';

  @override
  String get inventoryNoStakes => 'Nessuna puntata acquistata';

  @override
  String inventoryEmojiLeft(int count) {
    return 'Ne restano $count';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Rendita: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Rendita domani: $amount';
  }

  @override
  String inventoryStakeGold(String amount) {
    return 'Puoi puntare $amount oro';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'Puoi puntare $amount argento';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'Ricevuto +$amount';
  }

  @override
  String get chatsLoadFailed => 'Impossibile caricare le chat';

  @override
  String get chatsLoadListFailed => 'Impossibile caricare l’elenco';

  @override
  String get chatsBlockedEmpty => 'L’elenco è vuoto';

  @override
  String chatsBlockedAt(String date) {
    return 'Bloccato: $date';
  }

  @override
  String get chatsCreateFailed => 'Impossibile creare la chat';

  @override
  String get chatsNeedFriendsFirst => 'Aggiungi prima degli amici, poi potrai aprire una chat.';

  @override
  String get chatsFriendsNotFound => 'Amici non trovati';

  @override
  String get chatsFindFriendHint => 'Trova un amico per nickname';

  @override
  String get chatsSelectChat => 'Seleziona una chat';

  @override
  String get chatsSelectHint => 'Scegli una conversazione dall’elenco a sinistra';

  @override
  String get chatEditFailed => 'Impossibile modificare il messaggio';

  @override
  String get chatSendFailed => 'Impossibile inviare il messaggio';

  @override
  String get chatDeleteFailed => 'Impossibile eliminare il messaggio';

  @override
  String get chatEmojiSendFailed => 'Impossibile inviare l’emoji';

  @override
  String get chatLoadFailed => 'Impossibile caricare i messaggi';

  @override
  String get chatBackToGame => 'Torna alla partita';

  @override
  String get chatBackToChats => 'Torna alle chat';

  @override
  String get chatActions => 'Azioni chat';

  @override
  String get chatScrollToEnd => 'Vai alla fine';

  @override
  String chatReplyingTo(String name) {
    return 'In risposta a $name';
  }

  @override
  String get chatGift => 'Regalo';

  @override
  String get chatCollection => 'Collezione';

  @override
  String get chatGiftCollection => 'Regalo · collezione';

  @override
  String get chatThisUser => 'questo utente';

  @override
  String get gamesLobbyLoadFailed => 'Impossibile caricare la lobby.';

  @override
  String get gamesTapChangeStake => 'Tocca per cambiare la puntata';

  @override
  String get gamesTapChangeTurnTime => 'Tocca per cambiare il tempo per mossa';

  @override
  String get gamesTapChangeGrid => 'Tocca per cambiare la dimensione della griglia';

  @override
  String get gamesSwapSidesHint => 'O può diventare X dopo la 1ª mossa';

  @override
  String get gamesNoCenterHint => 'La prima mossa non può essere al centro';

  @override
  String get lobbyInviteSentShort => 'Inviato';

  @override
  String get lobbyInvitesSentWaiting => 'Inviti inviati. In attesa di risposta.';

  @override
  String get lobbyLinkCopiedHint => 'Incollalo in una chat o messaggio a un amico';

  @override
  String get lobbyCopyLinkHint => 'Copia il link negli appunti';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name ti invita a giocare';
  }

  @override
  String gameOpponentWon(String name) {
    return 'Ha vinto $name';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Tempo scaduto. Ha vinto $name';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String get adminTitle => 'Admin';

  @override
  String get tournamentsTitle => 'Tornei';

  @override
  String get profileAgeInvalid => 'Inserisci un’età da 1 a 111';

  @override
  String get profileSaveFailed => 'Impossibile salvare il profilo';

  @override
  String get profileNameHint => 'Lettere latine, cifre, _ fino a 10 caratteri';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'Da 1 a 111';

  @override
  String get profileAboutHint => 'Fino a 100 caratteri (facoltativo)';

  @override
  String get profileProcessingPhoto => 'Elaborazione foto…';

  @override
  String get profileCropTitle => 'Scegli l’area dell’avatar';

  @override
  String get profileCropHint => 'Ingrandisci e sposta la foto';

  @override
  String get profileApply => 'Applica';

  @override
  String get profilePreparing => 'Preparazione…';

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
    return 'Tris su una griglia $grid. Si gioca a turno; inizia X.';
  }

  @override
  String rulesWin(int n) {
    return 'Vittoria: allinea $n in fila in orizzontale, verticale o diagonale.';
  }

  @override
  String get rulesNoTimeLimit => 'Nessun limite di tempo per mossa.';

  @override
  String rulesTurnTime(String time) {
    return 'Tempo per mossa: $time.';
  }

  @override
  String rulesStake(String stake) {
    return 'Puntata: $stake. La partita vale così tante monete.';
  }

  @override
  String get rulesSwap => 'Scambio lati: O può scambiarsi con X dopo la prima mossa di X.';

  @override
  String get rulesNoCenter => 'Niente centro: X non può giocare al centro alla prima mossa.';

  @override
  String get collectionSetLegends => 'Leggende';

  @override
  String get collectionSetSpace => 'Spazio';

  @override
  String get collectionSetGems => 'Gemme';

  @override
  String get collectionSetParty => 'Festa';

  @override
  String get collectionSetNature => 'Natura';

  @override
  String get collectionSetAdventures => 'Avventure';

  @override
  String collectionCardMeta(String amount) {
    return 'Collezione · vetrina · regalo · vendita · +$amount';
  }

  @override
  String get coinsDayOne => 'giorno';

  @override
  String get coinsDayFew => 'giorni';

  @override
  String get coinsDayMany => 'giorni';

  @override
  String get giftFriendTitle => 'Regala a un amico';

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
    return '$count emoji · $price cad.';
  }

  @override
  String get chatsExpandPanel => 'Espandi pannello';

  @override
  String get chatsCollapsePanel => 'Comprimi pannello';

  @override
  String get chatReplySourceMissing => 'Messaggio originale non trovato';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Puntata $n argento';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Puntata $n oro';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Sblocca puntate da $n argento';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Sblocca puntate da $n oro';
  }

  @override
  String get chatReplySelf => 'te stesso';

  @override
  String get chatReplyPeer => 'all\'interlocutore';

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
