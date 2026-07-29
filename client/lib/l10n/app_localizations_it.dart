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
  String timeMinutesAgo(Object count) {
    return '$count min fa';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count h fa';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count g fa';
  }

  @override
  String get timeWeekAgo => 'una settimana fa';

  @override
  String timeWeeksAgo(Object count) {
    return '$count sett. fa';
  }

  @override
  String get timeMonthAgo => 'un mese fa';

  @override
  String timeMonthsAgo(Object count) {
    return '$count mesi fa';
  }

  @override
  String get timeYearAgo => 'un anno fa';

  @override
  String timeYearsAgo(Object count) {
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
}
