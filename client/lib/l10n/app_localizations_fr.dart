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
  String get settingsAddBotsTitle => 'Ajouter des bots après 30 s';

  @override
  String get settingsAddBotsSubtitle => 'En matchmaking : si aucun adversaire n’est trouvé en 30 secondes, la partie commence avec un bot (mise remise à 1 bronze)';

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
  String get timeJustNow => 'à l’instant';

  @override
  String get timeYesterday => 'hier';

  @override
  String timeMinutesAgo(Object count) {
    return 'il y a $count min';
  }

  @override
  String timeHoursAgo(Object count) {
    return 'il y a $count h';
  }

  @override
  String timeDaysAgo(Object count) {
    return 'il y a $count j';
  }

  @override
  String get timeWeekAgo => 'il y a une semaine';

  @override
  String timeWeeksAgo(Object count) {
    return 'il y a $count sem.';
  }

  @override
  String get timeMonthAgo => 'il y a un mois';

  @override
  String timeMonthsAgo(Object count) {
    return 'il y a $count mois';
  }

  @override
  String get timeYearAgo => 'il y a un an';

  @override
  String timeYearsAgo(Object count) {
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
  String get lobbyMatchmake => 'Salon';

  @override
  String get lobbyPrivateGame => 'Partie privée';

  @override
  String get lobbySearchingOpponent => 'Recherche d’un adversaire…';

  @override
  String get lobbyWaitingJoin => 'En attente que quelqu’un appuie sur « Trouver une partie » ou « Rejoindre »';

  @override
  String get lobbyInviteTitle => 'Invitation à jouer';

  @override
  String get lobbyInvitedToPlay => 'Vous avez été invité à jouer';

  @override
  String get lobbyEnterGame => 'Entrer dans la partie';

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
  String get profileChangePhoto => 'Changer la photo';

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
  String get shopStakesSubtitle => 'Débloquer les mises en argent';

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
}
