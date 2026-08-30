import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Accueil';

  @override
  String get navProfile => 'Profil';

  @override
  String get navFriends => 'Amis';

  @override
  String get navChats => 'Discussions';

  @override
  String get navGames => 'Jeux';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Par défaut du système';

  @override
  String get settingsSoundTitle => 'Son';

  @override
  String get settingsSoundSubtitle => 'Actions et animations de jeu';

  @override
  String get settingsOfflineModeTitle => 'Mode réseau';

  @override
  String get settingsOfflineModeSubtitle => 'Hors ligne : jouer immédiatement contre un bot, sans mises ni récompenses, sans chats ni amis. Les achats sont enregistrés et appliqués en mode en ligne. En ligne — lorsqu’il y a Internet ou selon le réglage de l’utilisateur.';

  @override
  String get settingsModeOnline => 'En ligne';

  @override
  String get settingsModeOffline => 'Hors ligne';

  @override
  String get gamesAlternateStartsHint => 'À tour de rôle qui commence la partie';

  @override
  String get rulesAlternateStarts => 'Celui qui commence alterne d’une partie à l’autre.';

  @override
  String get offlineBadgeTooltip => 'Mode hors ligne';

  @override
  String get offlineModePopupTitle => 'Mode hors ligne';

  @override
  String get offlineModePopupBody => 'Le mode hors ligne est activé. Jouez contre un bot sans mises ni récompenses. Chats, amis et lobby sont masqués. Les achats s’appliquent en mode en ligne.';

  @override
  String get offlineModePopupSettings => 'Paramètres';

  @override
  String get gamesPlay => 'Jouer';

  @override
  String get offlineGameTitle => 'Partie contre un bot';

  @override
  String get offlineGameHint => 'Sans mises ni récompenses · hors ligne uniquement';

  @override
  String get offlineBotWon => 'Le bot a gagné';

  @override
  String get offlineBotThinking => 'Le bot réfléchit…';

  @override
  String get offlinePlayAgain => 'Encore';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'Prendre';

  @override
  String get durakActionAll => 'Tout';

  @override
  String get durakActionDone => 'Terminé';

  @override
  String get durakActionBito => 'Battu';

  @override
  String get durakHintDefend => 'Défendez';

  @override
  String get durakHintDefendOrTransfer => 'Défendez ou transférez';

  @override
  String get durakHintOpponentDefends => 'L\'adversaire défend';

  @override
  String get durakHintThrowInFirst => 'Posez des cartes (max. 5 au premier tour)';

  @override
  String get durakHintThrowIn => 'Posez des cartes ou attendez la défense';

  @override
  String get durakHintOpponentThrows => 'L\'adversaire ajoute';

  @override
  String get durakHintTakeFollow => 'Ajoutez après la prise ou touchez « Terminé »';

  @override
  String get durakHintOpponentTakeFollow => 'L\'adversaire peut ajouter après la prise';

  @override
  String get durakHintBito => 'Ajoutez une carte ou dites « Battu »';

  @override
  String get durakHintOpponentBito => 'L\'adversaire ajoute ou dit « Battu »';

  @override
  String get durakHintYourAttack => 'Votre tour — attaquez';

  @override
  String get durakHintOpponentAttack => 'L\'adversaire attaque';

  @override
  String get durakHintYouLost => 'Vous avez perdu — vous êtes le durak';

  @override
  String get durakHintDrawAllOut => 'Égalité — tout le monde est sorti';

  @override
  String get durakHintYouFinished => 'Vous êtes sorti — en attente de la fin';

  @override
  String get durakFirstLeadYou => 'Vous jouez en premier';

  @override
  String get durakFirstLeadOpponent => 'L’adversaire joue en premier';

  @override
  String get durakFirstLeadBot => 'Le bot joue en premier';

  @override
  String durakFirstLeadOf(String name) {
    return '$name joue en premier';
  }

  @override
  String get durakFirstLeadReason => 'Plus petit atout';

  @override
  String get shopPurchaseQueued => 'Achat enregistré — sera appliqué en mode en ligne';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — achat appliqué';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — achat non appliqué : $reason';
  }

  @override
  String get settingsFriendsOnlyTitle => 'Messages des amis uniquement';

  @override
  String get settingsFriendsOnlySubtitle => 'Les non-amis ne peuvent envoyer que des emojis. En cas de spam, bloquez temporairement l’utilisateur.';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPushChat => 'Discussion';

  @override
  String get settingsPushFriends => 'Amis';

  @override
  String get settingsPushGames => 'Jeux';

  @override
  String get settingsPushRewards => 'Récompenses';

  @override
  String settingsAppVersion(String version) {
    return 'Version $version';
  }

  @override
  String get appUpdateTitle => 'Mise à jour disponible';

  @override
  String get appUpdateBody => 'Une nouvelle version de l\'application est disponible. Mettez à jour pour continuer.';

  @override
  String get appUpdateWhatsNew => 'Nouveautés';

  @override
  String get appUpdateOk => 'Mettre à jour';

  @override
  String get appUpdateLaterBanner => 'Nous mettrons l\'application à jour après cette partie';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get loginSubtitle => 'Saisissez l’e-mail ou le pseudo et le mot de passe';

  @override
  String get loginEmailLabel => 'E-mail ou pseudo';

  @override
  String get loginPasswordLabel => 'Mot de passe';

  @override
  String get loginSubmit => 'Se connecter';

  @override
  String get loginNoAccount => 'Pas de compte ? S’inscrire';

  @override
  String get loginEmailRequired => 'Saisissez l’e-mail ou le pseudo';

  @override
  String get loginPasswordRequired => 'Saisissez le mot de passe';

  @override
  String get loginTooltip => 'Se connecter';

  @override
  String get logoutTooltip => 'Se déconnecter';

  @override
  String get registerTitle => 'Inscription';

  @override
  String get registerSubtitle => 'Créez un compte pour jouer';

  @override
  String get registerNameLabel => 'Nom (pseudo)';

  @override
  String get registerEmailLabel => 'E-mail';

  @override
  String get registerPasswordLabel => 'Mot de passe';

  @override
  String get registerSubmit => 'S’inscrire';

  @override
  String get registerHaveAccount => 'Déjà un compte ? Se connecter';

  @override
  String get registerNameRequired => 'Saisissez un nom';

  @override
  String get registerNameNoSpaces => 'Le nom ne peut pas contenir d’espaces';

  @override
  String get registerNameMax => '20 caractères maximum';

  @override
  String get registerNameHint => 'Jusqu’à 20 caractères';

  @override
  String get registerEmailRequired => 'Saisissez l’e-mail';

  @override
  String get registerEmailInvalid => 'E-mail invalide';

  @override
  String get registerPasswordHint => 'Au moins 6 caractères';

  @override
  String get registerPasswordMin => 'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonReply => 'Répondre';

  @override
  String get commonSend => 'Envoyer';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonLoading => 'Chargement…';

  @override
  String get commonError => 'Erreur';

  @override
  String get commonOnline => 'en ligne';

  @override
  String get commonOffline => 'hors ligne';

  @override
  String get commonOnlineCap => 'En ligne';

  @override
  String get commonUser => 'Utilisateur';

  @override
  String get commonPlayer => 'Joueur';

  @override
  String get commonAboutMe => 'À propos de moi';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonAccept => 'Accepter';

  @override
  String get commonDecline => 'Refuser';

  @override
  String get commonCreating => 'Création…';

  @override
  String get commonSearching => 'Recherche…';

  @override
  String get commonInsufficientCoins => 'Pas assez de pièces';

  @override
  String get commonNotFound => 'Introuvable';

  @override
  String get commonServerErrorShort => 'Erreur serveur';

  @override
  String get commonForbidden => 'Accès refusé';

  @override
  String get commonUserBlocked => 'Utilisateur bloqué';

  @override
  String get commonUserNotFound => 'Utilisateur introuvable';

  @override
  String get commonGenericError => 'Une erreur s’est produite. Veuillez réessayer.';

  @override
  String get apiErrWrongGameType => 'Mauvais type de jeu';

  @override
  String get apiErrWrongGameTypeOrState => 'Mauvais type ou état de jeu';

  @override
  String get apiErrLobbyFull => 'Le lobby est plein';

  @override
  String get apiErrBadState => 'État de partie invalide';

  @override
  String get apiErrIllegalMove => 'Coup interdit';

  @override
  String get apiErrUnknownMoveType => 'Type de coup inconnu';

  @override
  String get apiErrNoOpponents => 'Aucun adversaire';

  @override
  String get apiErrNoOpponentsRematch => 'Aucun adversaire pour la revanche';

  @override
  String get apiErrAlreadyInLobby => 'Vous êtes déjà dans ce lobby';

  @override
  String get apiErrGameNotActive => 'La partie n\'est pas active';

  @override
  String get apiErrNotInBattle => 'Pas en phase de combat';

  @override
  String get apiErrNotInSetup => 'Pas en phase de placement';

  @override
  String get apiErrAlreadyReady => 'Vous êtes déjà prêt';

  @override
  String get apiErrAlreadyForfeited => 'Vous avez déjà abandonné';

  @override
  String get apiErrYouHaveForfeited => 'Vous avez abandonné';

  @override
  String get apiErrNoDrawOffer => 'Aucune offre de nul';

  @override
  String get apiErrDrawOnlyPvp => 'Le nul n\'est disponible que contre un joueur';

  @override
  String get apiErrDrawOnly1v1 => 'Le nul n\'est disponible qu\'en 1 contre 1';

  @override
  String get apiErrDrawVsBot => 'Le nul n\'est pas disponible contre un bot';

  @override
  String get apiErrDrawMultiplayer => 'Le nul n\'est pas disponible en multijoueur';

  @override
  String get apiErrDeck24TwoPlayers => 'Le jeu de 24 cartes est réservé à 2 joueurs';

  @override
  String get apiErrDeck52ThreeOrFour => 'Le jeu de 52 cartes nécessite 3 ou 4 joueurs';

  @override
  String get apiErrAccountFrozen => 'Le compte est gelé';

  @override
  String get apiErrTurnTimeInvalid => 'Le temps de tour doit être 0, 20, 60 ou 600 secondes';

  @override
  String get timeJustNow => 'à l’instant';

  @override
  String get timeYesterday => 'hier';

  @override
  String timeMinutesAgo(int count) {
    return 'il y a $count min';
  }

  @override
  String timeHoursAgo(int count) {
    return 'il y a $count h';
  }

  @override
  String timeDaysAgo(int count) {
    return 'il y a $count j';
  }

  @override
  String get timeWeekAgo => 'il y a une semaine';

  @override
  String timeWeeksAgo(int count) {
    return 'il y a $count sem.';
  }

  @override
  String get timeMonthAgo => 'il y a un mois';

  @override
  String timeMonthsAgo(int count) {
    return 'il y a $count mois';
  }

  @override
  String get timeYearAgo => 'il y a un an';

  @override
  String timeYearsAgo(int count) {
    return 'il y a $count ans';
  }

  @override
  String get weekdaySun => 'Dim.';

  @override
  String get weekdayMon => 'Lun.';

  @override
  String get weekdayTue => 'Mar.';

  @override
  String get weekdayWed => 'Mer.';

  @override
  String get weekdayThu => 'Jeu.';

  @override
  String get weekdayFri => 'Ven.';

  @override
  String get weekdaySat => 'Sam.';

  @override
  String get monthJan => 'Janv.';

  @override
  String get monthFeb => 'Févr.';

  @override
  String get monthMar => 'Mars';

  @override
  String get monthApr => 'Avr.';

  @override
  String get monthMay => 'Mai';

  @override
  String get monthJun => 'Juin';

  @override
  String get monthJul => 'Juil.';

  @override
  String get monthAug => 'Août';

  @override
  String get monthSep => 'Sept.';

  @override
  String get monthOct => 'Oct.';

  @override
  String get monthNov => 'Nov.';

  @override
  String get monthDec => 'Déc.';

  @override
  String get homeAchievements => 'Succès';

  @override
  String get homeAchievementsSubtitle => 'Vos résultats de jeu';

  @override
  String get homeAchievementsRewards => 'Récompenses à réclamer';

  @override
  String get homeCoins => 'Pièces';

  @override
  String get homeCoinsSubtitle => 'Solde et récompenses';

  @override
  String get homeCoinsDailyReward => 'Récompense de connexion quotidienne disponible';

  @override
  String get homeItems => 'Objets';

  @override
  String get homeItemsInventory => 'Votre inventaire';

  @override
  String get homeItemsGifted => 'Quelqu’un vous a offert une collection';

  @override
  String get homeItemsIncome => 'Revenus de collection prêts à réclamer';

  @override
  String get homeShop => 'Boutique';

  @override
  String get homeShopSubtitle => 'Emojis, mises, collections';

  @override
  String get gamesTitle => 'Jeux';

  @override
  String get gamesFindMatch => 'Trouver une partie';

  @override
  String get gamesMyTurn => 'À vous';

  @override
  String get gamesWaiting => 'En attente';

  @override
  String get gamesLobbyTab => 'Salon';

  @override
  String get gamesTicTacToe => 'Morpion';

  @override
  String get gamesDurak => 'Durak';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => 'Pivoter';

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
  String get gamesPoker => 'Poker';

  @override
  String get gamesUno => 'Uno';

  @override
  String rulesUnoPlayers(int players) {
    return 'Joueurs : $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'Partie contre un bot, sans limite de temps par tour.';

  @override
  String get rulesUnoIntro => 'Chacun reçoit 7 cartes. Jouez une carte de la même couleur ou du même rang (chiffre ou même action).';

  @override
  String get rulesUnoPlay => 'Passe — le suivant perd son tour. Inversion à deux agit comme Passe. +2 se pose seulement sur +2 et +4 seulement sur +4 : la pénalité s’additionne (deux +2 font piocher 4). On ne peut pas poser +2 sur +4. Celui qui ne répond pas pioche toute la pile et passe. Deux cartes identiques non noires (par ex. deux 8 jaunes) sont défaussées ensemble : jouez-en une, la jumelle part automatiquement.';

  @override
  String get rulesUnoWild => 'Une carte noire fixe une nouvelle couleur. Jouez +4 seulement si vous n’avez aucune carte de la couleur en cours. L’adversaire peut contester : si le +4 était légal, il pioche 6 ; sinon l’auteur du +4 pioche 4 et le contestataire joue.';

  @override
  String get rulesUnoDraw => 'Sans carte jouable, piochez-en une. Si elle convient, jouez-la tout de suite ou gardez-la et passez. On ne pioche pas tant qu’un coup est possible.';

  @override
  String get rulesUnoWin => 'À deux, premier à 100 ; à 3+, premier à 200. Une manche est gagnée en vidant sa main.';

  @override
  String get rulesUnoCall => 'Quand il vous reste une carte, touchez « Uno ! » tout de suite. Les autres ne peuvent vous prendre pour un Uno oublié qu’après une seconde — vous piochez alors 2 cartes.';

  @override
  String get rulesUnoScoring => 'Le premier à vider sa main gagne la manche et marque les cartes des adversaires : chiffres à la valeur, actions 20, noires 50. À deux, premier à 100 ; à 3+, premier à 200.';

  @override
  String get unoColorRed => 'Rouge';

  @override
  String get unoColorYellow => 'Jaune';

  @override
  String get unoColorGreen => 'Vert';

  @override
  String get unoColorBlue => 'Bleu';

  @override
  String get unoDraw => 'Piocher';

  @override
  String get unoKeep => 'Garder';

  @override
  String get unoSayUno => 'Uno !';

  @override
  String get unoChallengeUno => 'Contester Uno';

  @override
  String get unoChallengeWd4 => 'Contester +4';

  @override
  String get unoChooseColor => 'Choisissez une couleur';

  @override
  String get unoDrawPile => 'Pioche';

  @override
  String get unoDiscardPile => 'Défausse';

  @override
  String unoCardsCount(int count) {
    return 'Cartes : $count';
  }

  @override
  String unoScore(int score) {
    return 'Score : $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'Manche $round · objectif $target';
  }

  @override
  String get unoYourTurn => 'À vous';

  @override
  String get unoWaitingTurn => 'Tour de l’adversaire';

  @override
  String get unoChooseColorHint => 'Choisissez une couleur pour le joker';

  @override
  String get unoWd4Hint => 'Piochez 4 cartes ou contestez le Wild +4';

  @override
  String get unoDrawnHint => 'Jouez la carte piochée ou gardez-la';

  @override
  String get unoPlayHint => 'Jouez une couleur ou une valeur correspondante';

  @override
  String get unoDrawHint => 'Aucune carte compatible — piochez';

  @override
  String unoPendingDraw(int count) {
    return '+$count cartes';
  }

  @override
  String get unoYouWon => 'Vous avez gagné la partie !';

  @override
  String get unoYouLost => 'Partie terminée';

  @override
  String get unoYouLostTimeout => 'Vous avez perdu au temps';

  @override
  String unoWinner(String name) {
    return 'Gagnant : $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name gagne la manche';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'Suivant';

  @override
  String get unoRoundScoresTitle => 'Score de la manche';

  @override
  String get unoDirectionClockwise => 'Sens horaire';

  @override
  String get unoDirectionCounterclockwise => 'Sens antihoraire';

  @override
  String get unoErrStackSameOnly => 'Vous ne pouvez jouer +2 que sur +2, et +4 que sur +4. Un +2 ne se pose pas sur un +4.';

  @override
  String get unoErrCatchTooEarly => 'Attendez une seconde — ils peuvent encore dire Uno.';

  @override
  String get unoErrCallTooLate => 'Vous ne pouvez plus dire Uno. Le joueur suivant a déjà joué.';

  @override
  String get gamesInDevelopment => 'En développement';

  @override
  String rulesPokerPlayers(int players) {
    return 'Joueurs : $players.';
  }

  @override
  String get rulesPokerIntro => 'Texas Hold’em. Chaque joueur reçoit 2 cartes privées ; 5 cartes communes sont mises sur la table.';

  @override
  String get rulesPokerPlay => 'Tours de mise : préflop, flop, turn et river. Fold, call, bet ou raise.';

  @override
  String get rulesPokerWin => 'Gagne la meilleure main de cinq cartes (privées + communes), ou le dernier joueur après les folds.';

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
  String get pokerCombinationsTitle => 'Combinaisons';

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
  String get gamesRules => 'Règles';

  @override
  String get gamesRulesTitle => 'Règles du jeu';

  @override
  String get gamesCreate => 'Créer une partie';

  @override
  String get gamesJoin => 'Rejoindre';

  @override
  String get gamesOpponentTurn => 'Tour de l’adversaire';

  @override
  String get gamesCurrentGame => 'Partie en cours';

  @override
  String get gamesInvitedYou => 'Vous avez été invité';

  @override
  String get gamesTurnTime => 'Temps par tour';

  @override
  String get gamesGridSize => 'Taille de la grille';

  @override
  String get gamesSwapSides => 'Échange de côtés';

  @override
  String get gamesNoCenter => 'Pas de départ au centre';

  @override
  String get gamesObservation => 'Spectateur';

  @override
  String get gamesObservationHint => 'Vous pouvez regarder jusqu\'à la fin de la partie';

  @override
  String get gamesFinishCurrentFirst => 'Terminez d\'abord votre partie en cours';

  @override
  String get gamesVariantClassic => 'Classique';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 joueurs';

  @override
  String get gamesVariantMulti4 => '4 joueurs';

  @override
  String get gamesDurakModePodkidnoi => 'Relance';

  @override
  String get gamesDurakModePerevodnoi => 'Transfert';

  @override
  String get gamesDurakDeck24 => '24 cartes';

  @override
  String get gamesDurakDeck36 => '36 cartes';

  @override
  String get gamesDurakDeck52 => '52 cartes';

  @override
  String rulesDurakMode(String mode) {
    return 'Mode : $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'Joueurs : $players. Jeu : $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Jouez contre un bot, sans mise ni limite de temps.';

  @override
  String get rulesDurakAttack => 'L\'attaquant pose des cartes ; le défenseur les bat (même couleur plus haute, ou un atout). Un atout ne se bat que par un atout plus haut.';

  @override
  String get rulesDurakBeat => 'Quand toutes les cartes sont battues, l\'attaquant dit « Battu » et les cartes vont au discard. Sinon le défenseur prend tout sur la table.';

  @override
  String get rulesDurakLoser => 'Le perdant est celui qui a encore des cartes à la fin — le « durak ».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Joueurs $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Salon $name';
  }

  @override
  String get lobbyMatchmake => 'Salon';

  @override
  String get lobbyPrivateGame => 'Partie privée';

  @override
  String get lobbySearchingOpponent => 'Recherche d’un adversaire…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Recherchent cette partie : $count';
  }

  @override
  String get lobbyWaitingJoin => 'En attente que quelqu’un appuie sur « Trouver une partie » ou « Rejoindre »';

  @override
  String get lobbyInviteTitle => 'Invitation à jouer';

  @override
  String get lobbyInvitedToPlay => 'Vous avez été invité à jouer';

  @override
  String get lobbyEnterGame => 'Entrer dans la partie';

  @override
  String get lobbyGone => 'Lobby plus disponible';

  @override
  String get lobbyInvite => 'Inviter';

  @override
  String get lobbyInviteSent => 'Invitation envoyée';

  @override
  String get lobbyCopyLink => 'Partager le lien de la partie';

  @override
  String get lobbyLinkCopied => 'Lien copié';

  @override
  String get lobbyNoFriendsOnline => 'Aucun ami en ligne. Partagez le lien ci-dessus ou attendez que vos amis se connectent.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Adversaire';

  @override
  String get gameYouWon => 'Vous avez gagné !';

  @override
  String get gameYouLost => 'Vous avez perdu';

  @override
  String get gameYouWonOpponentLeft => 'Vous avez gagné — l’adversaire a quitté';

  @override
  String get gameYouWonOpponentTimeout => 'Vous avez gagné — l’adversaire n’a plus de temps';

  @override
  String get gameDraw => 'Match nul';

  @override
  String get gameExitTitle => 'Quitter la partie';

  @override
  String get gameExitConfirm => 'Si vous quittez, vous perdrez. Quitter quand même ?';

  @override
  String get gameStay => 'Rester';

  @override
  String get gameLeave => 'Quitter';

  @override
  String get gameSurrender => 'Abandonner';

  @override
  String get gameSurrenderTitle => 'Abandonner ?';

  @override
  String get gameSurrenderConfirm => 'Vous perdez la partie et les pièces de mise.';

  @override
  String get gameOfferDraw => 'Proposer nulle';

  @override
  String get gameOfferDrawTitle => 'Proposer nulle ?';

  @override
  String get gameOfferDrawConfirm => 'Votre adversaire peut accepter ou refuser la nulle.';

  @override
  String get gameAcceptDrawTitle => 'Accepter la nulle ?';

  @override
  String get gameAcceptDrawConfirm => 'La partie se termine par une nulle.';

  @override
  String get gameDrawOffered => 'L’adversaire propose nulle';

  @override
  String get gameConnecting => 'Connexion à la partie…';

  @override
  String get gameWaitingOpponent => 'En attente de l’adversaire';

  @override
  String get gameRematchOffer => 'L’adversaire propose une revanche';

  @override
  String get gameRematchDeclined => 'L’adversaire a refusé la revanche';

  @override
  String get gameRematch => 'Revanche';

  @override
  String get gameOtherOpponent => 'Autre adversaire';

  @override
  String get gameSwapSidesAction => 'Changer de côté';

  @override
  String get gameWriteMessage => 'Écrire un message';

  @override
  String get chatsTitle => 'Discussions';

  @override
  String get chatsEmpty => 'Aucune discussion pour le moment.\nAppuyez sur l’icône en haut à droite pour choisir un ami et démarrer une conversation.';

  @override
  String get chatsNewChat => 'Nouvelle discussion';

  @override
  String get chatsNoMessages => 'Aucun message';

  @override
  String get chatsClearTitle => 'Effacer la conversation ?';

  @override
  String get chatsClearDesc => 'La discussion sera supprimée définitivement.';

  @override
  String get chatsClearConfirm => 'Effacer';

  @override
  String get chatsBlockTitle => 'Bloquer cet utilisateur ?';

  @override
  String get chatsBlockDesc => 'Vous ne pourrez plus vous écrire. La discussion et l’amitié seront supprimées.';

  @override
  String get chatsBlockConfirm => 'Bloquer';

  @override
  String get chatsBlockedUsers => 'Utilisateurs bloqués';

  @override
  String get chatsUnblock => 'Débloquer';

  @override
  String get chatDialog => 'Discussion';

  @override
  String get chatEmpty => 'Aucun message pour le moment.\nEnvoyez le premier.';

  @override
  String get chatMessageHint => 'Message';

  @override
  String get chatPaste => 'Coller';

  @override
  String get chatEmoji => 'Emojis';

  @override
  String get chatBuyEmojiHint => 'Achetez des emojis dans la boutique sur l’écran d’accueil';

  @override
  String get chatEditing => 'Modification';

  @override
  String get chatToday => 'Aujourd’hui';

  @override
  String get chatYesterday => 'Hier';

  @override
  String get chatFriendsOnly => 'Texte réservé aux amis';

  @override
  String get emojiGroupEmotions => 'Émotions';

  @override
  String get emojiGroupGame => 'Jeux';

  @override
  String get emojiGroupFlags => 'Drapeaux';

  @override
  String get emojiGroupAnimals => 'Animaux';

  @override
  String get emojiGroupFood => 'Nourriture';

  @override
  String get emojiGroupTravel => 'Voyage';

  @override
  String get emojiGroupParty => 'Fête';

  @override
  String get emojiGroupObjects => 'Objets';

  @override
  String get friendsTitle => 'Amis';

  @override
  String get friendsTabFriends => 'Amis';

  @override
  String get friendsTabIncoming => 'Reçues';

  @override
  String get friendsTabOutgoing => 'Envoyées';

  @override
  String get friendsAdd => 'Ajouter un ami';

  @override
  String get friendsRequestSent => 'Demande envoyée';

  @override
  String get friendsFindTab => 'Trouver un ami';

  @override
  String get friendsSearchHint => 'Rechercher par pseudo';

  @override
  String get friendsSearchPrompt => 'Utilisez la recherche pour trouver de nouveaux amis';

  @override
  String get friendsNothingFound => 'Aucun résultat';

  @override
  String get friendsEmpty => 'Vous n’avez pas encore d’amis';

  @override
  String get friendsNoIncoming => 'Aucune demande reçue';

  @override
  String get friendsNoOutgoing => 'Aucune demande envoyée';

  @override
  String get friendsAlreadyFriends => 'Déjà amis';

  @override
  String get friendsRemoveTitle => 'Retirer des amis ?';

  @override
  String get friendsRemoved => 'Retiré des amis';

  @override
  String get friendsRequestAccepted => 'Demande acceptée';

  @override
  String get friendsRequestDeclined => 'Demande refusée';

  @override
  String get friendsRequestCancelled => 'Demande annulée';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSignInPrompt => 'Connectez-vous à votre compte';

  @override
  String get profileSignInHint => 'Pour configurer votre profil personnel';

  @override
  String get profileEdit => 'Modifier';

  @override
  String get profileCollections => 'Collections';

  @override
  String get profileAge => 'Âge';

  @override
  String get profileGender => 'Genre';

  @override
  String get profileGenderUnset => 'Non renseigné';

  @override
  String get profileGenderMale => 'Homme';

  @override
  String get profileGenderFemale => 'Femme';

  @override
  String get profileAvatar => 'Avatar';

  @override
  String get profileUploadPhoto => 'Importer une photo';

  @override
  String get profileChangePhoto => 'Changer l’avatar';

  @override
  String get shopTitle => 'Boutique';

  @override
  String get shopEmojis => 'Emojis';

  @override
  String get shopEmojisSubtitle => 'Emojis animés pour le chat';

  @override
  String get shopCollections => 'Collections';

  @override
  String get shopCollectionsSubtitle => 'Vitrine de profil, cadeaux et revenus';

  @override
  String get shopStakes => 'Mises';

  @override
  String get shopStakesSubtitle => 'Débloquer les mises plus élevées';

  @override
  String get inventoryTitle => 'Objets';

  @override
  String get inventoryEmpty => 'Rien ici pour le moment — consultez la boutique';

  @override
  String get inventoryFrames => 'Cadres';

  @override
  String get inventoryClaim => 'Réclamer';

  @override
  String get inventorySell => 'Vendre';

  @override
  String get inventoryGift => 'Offrir';

  @override
  String get messageEdited => 'modifié';

  @override
  String get messageDeleted => 'Message supprimé';

  @override
  String get photo => 'Photo';

  @override
  String get camera => 'Appareil photo';

  @override
  String get gallery => 'Galerie';

  @override
  String get connectionError => 'Impossible de se connecter au serveur.';

  @override
  String get serverError => 'Erreur serveur. Veuillez réessayer plus tard.';

  @override
  String get sessionExpired => 'Session expirée. Veuillez vous reconnecter.';

  @override
  String get errNoInternet => 'Pas de connexion Internet.';

  @override
  String get errTimeout => 'Délai d’attente dépassé. Veuillez réessayer.';

  @override
  String get errGamesUnavailable => 'Les jeux sont temporairement indisponibles';

  @override
  String get errSettingsSaveFailed => 'Impossible d’enregistrer le paramètre';

  @override
  String get errPushPermission => 'Autorisez les notifications dans les paramètres du navigateur ou du système.';

  @override
  String get balanceTitle => 'Solde';

  @override
  String get coinBronze => 'Bronze';

  @override
  String get coinSilver => 'Argent';

  @override
  String get coinGold => 'Or';

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
    return '$count argent';
  }

  @override
  String balanceGolds(int count) {
    return '$count or';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count diamants';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/jour';
  }

  @override
  String get balanceAbbrBronze => 'br';

  @override
  String get balanceAbbrSilver => 'ar.';

  @override
  String get balanceAbbrGold => 'or';

  @override
  String get commonBackHome => 'Retour à l’accueil';

  @override
  String get commonCopied => 'Copié';

  @override
  String get commonClear => 'Effacer';

  @override
  String get commonTryLater => 'Réessayez plus tard.';

  @override
  String get commonTryRefresh => 'Essayez d’actualiser la page.';

  @override
  String get coinsTitle => 'Pièces';

  @override
  String get coinsLoginReward => 'Récompense de connexion';

  @override
  String get coinsLoginAvailableToday => 'Récompense du jour disponible';

  @override
  String get coinsLoginStreak => 'Série de connexions quotidiennes';

  @override
  String get coinsFriendReward => 'Récompense ami';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount pour une inscription via votre lien';
  }

  @override
  String get coinsLoadRewardsFailed => 'Impossible de charger les récompenses';

  @override
  String get coinsClaimReward => 'Récupérer la récompense';

  @override
  String get coinsAlreadyClaimed => 'Déjà récupéré';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · aujourd’hui';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · encore 1 jour';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · encore $remaining';
  }

  @override
  String get coinsInviteFriend => 'Inviter un ami';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount pour chaque personne qui s’inscrit via votre lien';
  }

  @override
  String get coinsCopyLink => 'Copier le lien';

  @override
  String get coinsHowItWorks => 'Comment ça marche';

  @override
  String get coinsHowStep1 => 'Copiez le lien et envoyez-le à un ami';

  @override
  String get coinsHowStep2 => 'Votre ami s’inscrit via ce lien';

  @override
  String coinsHowStep3(String amount) {
    return 'Vous recevez $amount';
  }

  @override
  String get achievementsTitle => 'Succès';

  @override
  String achievementsProgress(String progress) {
    return 'Progression : $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Cadre obtenu';

  @override
  String get achievementsClaimed => 'Obtenu';

  @override
  String get achievementsOpenFrame => 'Ouvrir le cadre';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Voulez-vous vraiment retirer $name de vos amis ?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Retirer';

  @override
  String get friendsRemove => 'Retirer des amis';

  @override
  String get friendsAcceptRequest => 'Accepter la demande';

  @override
  String get friendsDeclineRequest => 'Refuser la demande';

  @override
  String get friendsCancelRequest => 'Annuler la demande';

  @override
  String get friendsSendRequest => 'Envoyer une demande d’ami';

  @override
  String get friendsRequestAlreadySent => 'Demande déjà envoyée';

  @override
  String get friendsIncomingStatus => 'Demande reçue';

  @override
  String get friendsOutgoingStatus => 'Demande envoyée';

  @override
  String get friendsNotFriends => 'Pas amis';

  @override
  String get friendsCollapseSearch => 'Réduire la recherche';

  @override
  String get friendsExpandSearch => 'Afficher la recherche';

  @override
  String get friendsLoadFailed => 'Impossible de charger les amis';

  @override
  String friendsSince(String date) {
    return 'Amis depuis : $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Demande reçue : $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Demande envoyée : $date';
  }

  @override
  String get userInfoTitle => 'Infos utilisateur';

  @override
  String profileAgeYears(int age) {
    return '$age ans';
  }

  @override
  String get shopBuy => 'Acheter';

  @override
  String get shopBuyTitle => 'Acheter ?';

  @override
  String get shopBuyStakeTitle => 'Acheter la mise ?';

  @override
  String get shopBuyEmojiTitle => 'Acheter l’emoji ?';

  @override
  String get shopBuyCollectionTitle => 'Acheter la collection ?';

  @override
  String shopPrice(String price) {
    return 'Prix : $price';
  }

  @override
  String get shopOwned => 'Acheté';

  @override
  String get shopEmpty => 'Rien pour l’instant';

  @override
  String shopPurchased(String title) {
    return '$title acheté';
  }

  @override
  String get shopEmojiUses => 'Vous obtenez : 10 utilisations';

  @override
  String shopEmojiBought(String title) {
    return '$title : +10 utilisations';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 utilisations';
  }

  @override
  String get shopBuyTen => 'Acheter · 10 pcs';

  @override
  String shopDailyIncome(String amount) {
    return 'Revenu : $amount';
  }

  @override
  String get shopBuyOnce => 'Achat unique';

  @override
  String get shopSellRefund => 'La vente rembourse 80% du prix';

  @override
  String shopCollectionAdded(String title) {
    return '$title ajouté au profil';
  }

  @override
  String shopSetBonus(int percent) {
    return 'bonus de set +$percent%';
  }

  @override
  String get shopSetComplete => 'Complet';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Collecté · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Vendre ?';

  @override
  String inventorySellDesc(String amount) {
    return 'Vous recevrez $amount';
  }

  @override
  String inventorySold(String amount) {
    return 'Vendu : +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Ajoutez d’abord des amis';

  @override
  String get inventoryGiftTitle => 'Offrir la collection ?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'Offrir « $title » à $name ?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Offert : $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'Le joueur possède déjà cet objet';

  @override
  String get inventoryGiftSelf => 'Vous ne pouvez pas vous offrir un cadeau';

  @override
  String get inventoryGiftNotOwned => 'Cet objet n’est pas dans votre inventaire';

  @override
  String get inventoryLoadFailed => 'Impossible de charger les objets';

  @override
  String get inventoryNoCollections => 'Pas de collections — achetez-en dans la boutique';

  @override
  String get inventoryNoEmojis => 'Pas d’emojis — achetez-en dans la boutique';

  @override
  String get inventoryNoFrames => 'Pas de cadres — gagnez 10 parties de ligue (succès)';

  @override
  String get inventoryNoStakes => 'Aucune mise achetée';

  @override
  String inventoryEmojiLeft(int count) {
    return 'Il reste $count';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Revenu : +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Revenu demain : $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Prêt';

  @override
  String get inventoryIncomeTomorrowLabel => 'Demain';

  @override
  String inventoryStakeGold(String amount) {
    return 'Vous pouvez miser $amount d’or';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'Vous pouvez miser $amount d’argent';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'Reçu +$amount';
  }

  @override
  String get chatsLoadFailed => 'Impossible de charger les chats';

  @override
  String get chatsLoadListFailed => 'Impossible de charger la liste';

  @override
  String get chatsBlockedEmpty => 'La liste est vide';

  @override
  String chatsBlockedAt(String date) {
    return 'Bloqué : $date';
  }

  @override
  String get chatsCreateFailed => 'Impossible de créer le chat';

  @override
  String get chatsNeedFriendsFirst => 'Ajoutez d’abord des amis, puis vous pourrez ouvrir un chat.';

  @override
  String get chatsFriendsNotFound => 'Amis introuvables';

  @override
  String get chatsFindFriendHint => 'Trouver un ami par pseudo';

  @override
  String get chatsSelectChat => 'Sélectionnez un chat';

  @override
  String get chatsSelectHint => 'Choisissez une conversation dans la liste de gauche';

  @override
  String get chatEditFailed => 'Impossible de modifier le message';

  @override
  String get chatSendFailed => 'Impossible d’envoyer le message';

  @override
  String get chatDeleteFailed => 'Impossible de supprimer le message';

  @override
  String get chatEmojiSendFailed => 'Impossible d’envoyer l’emoji';

  @override
  String get chatLoadFailed => 'Impossible de charger les messages';

  @override
  String get chatBackToGame => 'Retour au jeu';

  @override
  String get chatBackToChats => 'Retour aux chats';

  @override
  String get chatActions => 'Actions du chat';

  @override
  String get chatAutoTranslate => 'Traduction auto';

  @override
  String get chatScrollToEnd => 'Aller à la fin';

  @override
  String chatReplyingTo(String name) {
    return 'En réponse à $name';
  }

  @override
  String get chatGift => 'Cadeau';

  @override
  String get chatCollection => 'Collection';

  @override
  String get chatGiftCollection => 'Cadeau · collection';

  @override
  String get chatThisUser => 'cet utilisateur';

  @override
  String get gamesLobbyLoadFailed => 'Impossible de charger le lobby.';

  @override
  String get gamesTapChangeStake => 'Appuyez pour changer la mise';

  @override
  String get gamesTapChangeTurnTime => 'Appuyez pour changer le temps de tour';

  @override
  String get gamesTapChangeGrid => 'Appuyez pour changer la taille de la grille';

  @override
  String get gamesSwapSidesHint => 'O peut devenir X après le 1er coup';

  @override
  String get gamesNoCenterHint => 'Le premier coup ne peut pas être au centre';

  @override
  String get lobbyInviteSentShort => 'Envoyé';

  @override
  String get lobbyInvitesSentWaiting => 'Invitations envoyées. En attente de réponse.';

  @override
  String get lobbyLinkCopiedHint => 'Collez-le dans un chat ou un message à un ami';

  @override
  String get lobbyCopyLinkHint => 'Copier le lien dans le presse-papiers';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name vous invite à jouer';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name a gagné';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Temps écoulé. $name a gagné';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String get adminTitle => 'Admin';

  @override
  String get tournamentsTitle => 'Tournois';

  @override
  String get profileAgeInvalid => 'Entrez un âge de 1 à 111';

  @override
  String get profileSaveFailed => 'Impossible d’enregistrer le profil';

  @override
  String get profileNameHint => 'Lettres latines, chiffres, _ jusqu’à 10 caractères';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'De 1 à 111';

  @override
  String get profileAboutHint => 'Jusqu’à 100 caractères (facultatif)';

  @override
  String get profileProcessingPhoto => 'Traitement de la photo…';

  @override
  String get profileCropTitle => 'Choisir la zone de l’avatar';

  @override
  String get profileCropHint => 'Zoomez et déplacez la photo';

  @override
  String get profileApply => 'Appliquer';

  @override
  String get profilePreparing => 'Préparation…';

  @override
  String get profileGalleryTitle => 'Photos';

  @override
  String get profileGalleryAdd => 'Ajouter une photo';

  @override
  String get profileMakePrimary => 'Définir comme principale';

  @override
  String get profilePhotoDelete => 'Supprimer la photo';

  @override
  String get profilePhotosLimit => 'Vous pouvez ajouter jusqu’à 3 photos';

  @override
  String get profilePhotosEmpty => 'Pas encore de photos';

  @override
  String get profilePhotoUploadFailed => 'Impossible d’ajouter la photo';

  @override
  String get profilePhotoDeleteFailed => 'Impossible de supprimer la photo';

  @override
  String get profilePhotoTooLarge => 'La photo est trop volumineuse';

  @override
  String get profileSetPrimaryFailed => 'Impossible de définir comme principale';

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
    return 'Morpion sur un plateau $grid. À tour de rôle, X commence.';
  }

  @override
  String rulesWin(int n) {
    return 'Victoire : alignez $n en ligne horizontale, verticale ou diagonale.';
  }

  @override
  String get rulesNoTimeLimit => 'Pas de limite de temps par coup.';

  @override
  String rulesTurnTime(String time) {
    return 'Temps par coup : $time. Le dépassement de temps est une défaite.';
  }

  @override
  String rulesStake(String stake) {
    return 'Mise : $stake. La partie se joue pour autant de pièces.';
  }

  @override
  String get rulesSwap => 'Échange de côtés : O peut échanger avec X après le premier coup de X.';

  @override
  String get rulesNoCenter => 'Interdiction du centre : X ne peut pas jouer au centre au premier coup.';

  @override
  String get collectionSetLegends => 'Légendes';

  @override
  String get collectionSetSpace => 'Espace';

  @override
  String get collectionSetGems => 'Gemmes';

  @override
  String get collectionSetParty => 'Fête';

  @override
  String get collectionSetNature => 'Nature';

  @override
  String get collectionSetAdventures => 'Aventures';

  @override
  String collectionCardMeta(String amount) {
    return 'Collection · vitrine · cadeau · vente · +$amount';
  }

  @override
  String get coinsDayOne => 'jour';

  @override
  String get coinsDayFew => 'jours';

  @override
  String get coinsDayMany => 'jours';

  @override
  String get giftFriendTitle => 'Offrir à un ami';

  @override
  String photoCount(int count) {
    return 'Photo ($count)';
  }

  @override
  String photoCountWithText(int count, String text) {
    return 'Photo ($count) : $text';
  }

  @override
  String photoWithText(String text) {
    return 'Photo : $text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count emojis · $price pièce';
  }

  @override
  String get chatsExpandPanel => 'Développer le panneau';

  @override
  String get chatsCollapsePanel => 'Réduire le panneau';

  @override
  String get chatReplySourceMissing => 'Message d\'origine introuvable';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Mise $n argent';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Mise $n or';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Débloque la mise de $n argent';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Débloque la mise de $n or';
  }

  @override
  String get chatReplySelf => 'vous-même';

  @override
  String get chatReplyPeer => 'l\'interlocuteur';

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
  String get statsTitle => 'Statistiques';

  @override
  String get statsLoadFailed => 'Impossible de charger les statistiques';

  @override
  String get statsAllGames => 'Tous les jeux';

  @override
  String get statsEmptyTitle => 'Aucune partie jouée pour l’instant';

  @override
  String get statsEmptyHint => 'Jouez votre première partie pour voir les statistiques ici.';

  @override
  String get statsWins => 'Victoires';

  @override
  String get statsDraws => 'Nuls';

  @override
  String get statsLosses => 'Défaites';

  @override
  String get statsWinRate => 'Taux de victoire';

  @override
  String get statsTopWon => 'Plus de victoires contre';

  @override
  String get statsTopDrawn => 'Plus de nuls avec';

  @override
  String get statsTopLost => 'Plus de défaites contre';

  @override
  String get statsTimePlayed => 'Temps de jeu';

  @override
  String get statsYourScore => 'Votre score';

  @override
  String get profileShowStats => 'Afficher les statistiques';

  @override
  String get statsDurationZeroMinutes => '0 min';

  @override
  String get gameYouWonOpponentForfeit => 'L’adversaire a abandonné. Vous avez gagné !';

  @override
  String get lobbyLeaveTitle => 'Quitter le lobby ?';

  @override
  String get lobbyLeaveConfirm => 'Le lobby sera supprimé après votre départ. Les amis invités recevront un refus.';

  @override
  String get lobbyLeave => 'Quitter';

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
    return 'Vous avez abandonné. $name a gagné';
  }

  @override
  String get supportTitle => 'Support';

  @override
  String get supportUnavailable => 'Le support est indisponible';

  @override
  String get supportOpenFailed => 'Impossible d\'ouvrir le chat support';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Vous avez reçu $amount pièces';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return '$amount pièces ont été déduites';
  }

  @override
  String get coinsCreditCardTitle => 'Des pièces vous ont été créditées';

  @override
  String get coinsClaim => 'Récupérer';

  @override
  String get durakActionPass => 'Passer';

  @override
  String get durakRoleTook => 'Prend';

  @override
  String get durakRoleBeats => 'Bat';

  @override
  String get durakRoleThrowIn => 'Renfort';

  @override
  String get durakRoleTurn => 'Tour';

  @override
  String get durakRoleDefends => 'Défend';

  @override
  String get durakStatusTaking => 'Prend';

  @override
  String get durakHintDefenderTurn => 'Tour du défenseur';

  @override
  String get gameYouEliminated => 'Vous êtes éliminé';

  @override
  String gameYouPlaced(int place) {
    return 'Vous êtes ${place}e';
  }

  @override
  String get gameOverNeutral => 'Partie terminée';

  @override
  String gameTurnOf(String name) {
    return 'Tour de $name';
  }

  @override
  String get chatGroupTooltip => 'Chat de groupe';

  @override
  String get lobbyChatNotReady => 'Le chat du lobby n’est pas encore prêt';

  @override
  String get chatsGroupChat => 'Chat de groupe';

  @override
  String chatsMembersCount(int count) {
    return 'Membres : $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count pers.';
  }

  @override
  String get chatsYouSuffix => '(vous)';

  @override
  String get chatTitleDurak3 => 'Durak · 3 joueurs';

  @override
  String get chatTitleDurak4 => 'Durak · 4 joueurs';

  @override
  String get rulesTttUltimate => 'Ultimate : neuf mini-grilles 3×3. Un coup envoie l’adversaire sur cette mini-grille. Gagnez en alignant sur la méta-grille.';

  @override
  String get rulesTttMulti3 => '3 joueurs : grille 3×3, trois joueurs (X, O, △). Alignez vos symboles pour gagner.';

  @override
  String get rulesTttMulti4 => '4 joueurs : grille 4×4, quatre joueurs (X, O, △, □). Alignez vos symboles pour gagner.';
}
