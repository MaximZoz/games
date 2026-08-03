import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Αρχική';

  @override
  String get navProfile => 'Προφίλ';

  @override
  String get navFriends => 'Φίλοι';

  @override
  String get navChats => 'Συνομιλίες';

  @override
  String get navGames => 'Παιχνίδια';

  @override
  String get navSettings => 'Ρυθμίσεις';

  @override
  String get settingsTitle => 'Ρυθμίσεις';

  @override
  String get settingsLanguage => 'Γλώσσα';

  @override
  String get settingsLanguageSystem => 'Προεπιλογή συστήματος';

  @override
  String get settingsAddBotsTitle => 'Προσθήκη bot μετά από 30 δευτ.';

  @override
  String get settingsAddBotsSubtitle => 'Στο matchmaking: αν δεν βρεθεί αντίπαλος σε 30 δευτερόλεπτα, το παιχνίδι ξεκινά με bot (το ποντάρισμα επαναφέρεται σε 1 μπρούντζο)';

  @override
  String get settingsOfflineModeTitle => 'Λειτουργία δικτύου';

  @override
  String get settingsOfflineModeSubtitle => 'Εκτός σύνδεσης: παίξτε αμέσως με bot, χωρίς πονταρίσματα και ανταμοιβές, χωρίς συνομιλίες και φίλους. Οι αγορές αποθηκεύονται και εφαρμόζονται σε λειτουργία online. Online — όταν υπάρχει internet ή από τη ρύθμιση χρήστη.';

  @override
  String get settingsModeOnline => 'Σε σύνδεση';

  @override
  String get settingsModeOffline => 'Εκτός σύνδεσης';

  @override
  String get gamesAlternateStartsHint => 'Εναλλάξ ποιος ξεκινά την παρτίδα';

  @override
  String get rulesAlternateStarts => 'Ποιος παίζει πρώτος εναλλάσσεται από παρτίδα σε παρτίδα.';

  @override
  String get offlineBadgeTooltip => 'Λειτουργία εκτός σύνδεσης';

  @override
  String get offlineModePopupTitle => 'Λειτουργία εκτός σύνδεσης';

  @override
  String get offlineModePopupBody => 'Η λειτουργία εκτός σύνδεσης είναι ενεργή. Παίξτε με bot χωρίς πονταρίσματα και ανταμοιβές. Συνομιλίες, φίλοι και λόμπι είναι κρυφά. Οι αγορές εφαρμόζονται σε online λειτουργία.';

  @override
  String get offlineModePopupSettings => 'Ρυθμίσεις';

  @override
  String get gamesPlay => 'Παίξτε';

  @override
  String get offlineGameTitle => 'Παιχνίδι με bot';

  @override
  String get offlineGameHint => 'Χωρίς πονταρίσματα και ανταμοιβές · μόνο εκτός σύνδεσης';

  @override
  String get offlineBotWon => 'Το bot κέρδισε';

  @override
  String get offlineBotThinking => 'Το bot σκέφτεται…';

  @override
  String get offlinePlayAgain => 'Ξανά';

  @override
  String get shopPurchaseQueued => 'Η αγορά αποθηκεύτηκε — θα εφαρμοστεί σε online λειτουργία';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — η αγορά εφαρμόστηκε';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — η αγορά δεν εφαρμόστηκε: $reason';
  }

  @override
  String get settingsFriendsOnlyTitle => 'Μηνύματα μόνο από φίλους';

  @override
  String get settingsFriendsOnlySubtitle => 'Οι μη φίλοι μπορούν να στέλνουν μόνο emoji. Αν υπάρχει spam, αποκλείστε προσωρινά τον χρήστη.';

  @override
  String get settingsNotifications => 'Ειδοποιήσεις';

  @override
  String get settingsPushChat => 'Συνομιλία';

  @override
  String get settingsPushFriends => 'Φίλοι';

  @override
  String get settingsPushGames => 'Παιχνίδια';

  @override
  String get settingsPushRewards => 'Ανταμοιβές';

  @override
  String get loginTitle => 'Σύνδεση';

  @override
  String get loginSubtitle => 'Εισαγάγετε email ή όνομα χρήστη και κωδικό';

  @override
  String get loginEmailLabel => 'Email ή όνομα χρήστη';

  @override
  String get loginPasswordLabel => 'Κωδικός';

  @override
  String get loginSubmit => 'Σύνδεση';

  @override
  String get loginNoAccount => 'Δεν έχετε λογαριασμό; Εγγραφή';

  @override
  String get loginEmailRequired => 'Εισαγάγετε email ή όνομα χρήστη';

  @override
  String get loginPasswordRequired => 'Εισαγάγετε κωδικό';

  @override
  String get loginTooltip => 'Σύνδεση';

  @override
  String get logoutTooltip => 'Αποσύνδεση';

  @override
  String get registerTitle => 'Εγγραφή';

  @override
  String get registerSubtitle => 'Δημιουργήστε λογαριασμό για να παίξετε';

  @override
  String get registerNameLabel => 'Όνομα (όνομα χρήστη)';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'Κωδικός';

  @override
  String get registerSubmit => 'Εγγραφή';

  @override
  String get registerHaveAccount => 'Έχετε ήδη λογαριασμό; Σύνδεση';

  @override
  String get registerNameRequired => 'Εισαγάγετε όνομα';

  @override
  String get registerNameNoSpaces => 'Το όνομα δεν μπορεί να περιέχει κενά';

  @override
  String get registerNameMax => 'Μέγιστο 20 χαρακτήρες';

  @override
  String get registerNameHint => 'Έως 20 χαρακτήρες';

  @override
  String get registerEmailRequired => 'Εισαγάγετε email';

  @override
  String get registerEmailInvalid => 'Μη έγκυρο email';

  @override
  String get registerPasswordHint => 'Τουλάχιστον 6 χαρακτήρες';

  @override
  String get registerPasswordMin => 'Ο κωδικός πρέπει να έχει τουλάχιστον 6 χαρακτήρες';

  @override
  String get commonCancel => 'Ακύρωση';

  @override
  String get commonSave => 'Αποθήκευση';

  @override
  String get commonDelete => 'Διαγραφή';

  @override
  String get commonEdit => 'Επεξεργασία';

  @override
  String get commonReply => 'Απάντηση';

  @override
  String get commonSend => 'Αποστολή';

  @override
  String get commonClose => 'Κλείσιμο';

  @override
  String get commonRetry => 'Επανάληψη';

  @override
  String get commonLoading => 'Φόρτωση…';

  @override
  String get commonError => 'Σφάλμα';

  @override
  String get commonOnline => 'συνδεδεμένος';

  @override
  String get commonOffline => 'εκτός σύνδεσης';

  @override
  String get commonOnlineCap => 'Συνδεδεμένος';

  @override
  String get commonUser => 'Χρήστης';

  @override
  String get commonPlayer => 'Παίκτης';

  @override
  String get commonAboutMe => 'Σχετικά με εμένα';

  @override
  String get commonBack => 'Πίσω';

  @override
  String get commonAccept => 'Αποδοχή';

  @override
  String get commonDecline => 'Απόρριψη';

  @override
  String get commonCreating => 'Δημιουργία…';

  @override
  String get commonSearching => 'Αναζήτηση…';

  @override
  String get commonInsufficientCoins => 'Ανεπαρκή νομίσματα';

  @override
  String get commonNotFound => 'Δεν βρέθηκε';

  @override
  String get commonServerErrorShort => 'Σφάλμα διακομιστή';

  @override
  String get commonForbidden => 'Δεν επιτρέπεται η πρόσβαση';

  @override
  String get commonUserBlocked => 'Ο χρήστης είναι αποκλεισμένος';

  @override
  String get commonUserNotFound => 'Ο χρήστης δεν βρέθηκε';

  @override
  String get commonGenericError => 'Κάτι πήγε στραβά. Δοκιμάστε ξανά.';

  @override
  String get timeJustNow => 'μόλις τώρα';

  @override
  String get timeYesterday => 'χθες';

  @override
  String timeMinutesAgo(int count) {
    return 'πριν $count λεπ.';
  }

  @override
  String timeHoursAgo(int count) {
    return 'πριν $count ώρ.';
  }

  @override
  String timeDaysAgo(int count) {
    return 'πριν $count ημ.';
  }

  @override
  String get timeWeekAgo => 'πριν μία εβδομάδα';

  @override
  String timeWeeksAgo(int count) {
    return 'πριν $count εβδ.';
  }

  @override
  String get timeMonthAgo => 'πριν έναν μήνα';

  @override
  String timeMonthsAgo(int count) {
    return 'πριν $count μήν.';
  }

  @override
  String get timeYearAgo => 'πριν έναν χρόνο';

  @override
  String timeYearsAgo(int count) {
    return 'πριν $count χρ.';
  }

  @override
  String get weekdaySun => 'Κυρ';

  @override
  String get weekdayMon => 'Δευ';

  @override
  String get weekdayTue => 'Τρί';

  @override
  String get weekdayWed => 'Τετ';

  @override
  String get weekdayThu => 'Πέμ';

  @override
  String get weekdayFri => 'Παρ';

  @override
  String get weekdaySat => 'Σάβ';

  @override
  String get monthJan => 'Ιαν';

  @override
  String get monthFeb => 'Φεβ';

  @override
  String get monthMar => 'Μαρ';

  @override
  String get monthApr => 'Απρ';

  @override
  String get monthMay => 'Μάι';

  @override
  String get monthJun => 'Ιούν';

  @override
  String get monthJul => 'Ιούλ';

  @override
  String get monthAug => 'Αύγ';

  @override
  String get monthSep => 'Σεπ';

  @override
  String get monthOct => 'Οκτ';

  @override
  String get monthNov => 'Νοέ';

  @override
  String get monthDec => 'Δεκ';

  @override
  String get homeAchievements => 'Επιτεύγματα';

  @override
  String get homeAchievementsSubtitle => 'Τα αποτελέσματα των παιχνιδιών σας';

  @override
  String get homeAchievementsRewards => 'Διαθέσιμες ανταμοιβές προς διεκδίκηση';

  @override
  String get homeCoins => 'Νομίσματα';

  @override
  String get homeCoinsSubtitle => 'Υπόλοιπο και ανταμοιβές';

  @override
  String get homeCoinsDailyReward => 'Διαθέσιμη ημερήσια ανταμοιβή σύνδεσης';

  @override
  String get homeItems => 'Αντικείμενα';

  @override
  String get homeItemsInventory => 'Το απόθεμά σας';

  @override
  String get homeItemsGifted => 'Κάποιος σας χάρισε μια συλλογή';

  @override
  String get homeItemsIncome => 'Έσοδα συλλογής έτοιμα προς διεκδίκηση';

  @override
  String get homeShop => 'Κατάστημα';

  @override
  String get homeShopSubtitle => 'Emoji, πονταρίσματα, συλλογές';

  @override
  String get gamesTitle => 'Παιχνίδια';

  @override
  String get gamesFindMatch => 'Εύρεση παιχνιδιού';

  @override
  String get gamesMyTurn => 'Η σειρά σας';

  @override
  String get gamesWaiting => 'Αναμονή';

  @override
  String get gamesLobbyTab => 'Λόμπι';

  @override
  String get gamesTicTacToe => 'Τρίλιζα';

  @override
  String get gamesRules => 'Κανόνες';

  @override
  String get gamesRulesTitle => 'Κανόνες παιχνιδιού';

  @override
  String get gamesCreate => 'Δημιουργία παιχνιδιού';

  @override
  String get gamesJoin => 'Συμμετοχή';

  @override
  String get gamesOpponentTurn => 'Σειρά αντιπάλου';

  @override
  String get gamesCurrentGame => 'Τρέχον παιχνίδι';

  @override
  String get gamesInvitedYou => 'Λάβατε πρόσκληση';

  @override
  String get gamesTurnTime => 'Χρόνος σειράς';

  @override
  String get gamesGridSize => 'Μέγεθος πλέγματος';

  @override
  String get gamesSwapSides => 'Αλλαγή πλευράς';

  @override
  String get gamesNoCenter => 'Χωρίς εκκίνηση στο κέντρο';

  @override
  String get lobbyMatchmake => 'Λόμπι';

  @override
  String get lobbyPrivateGame => 'Ιδιωτικό παιχνίδι';

  @override
  String get lobbySearchingOpponent => 'Αναζήτηση αντιπάλου…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Αναζητούν αυτό το παιχνίδι: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Αναμονή να πατήσει κάποιος «Εύρεση παιχνιδιού» ή «Συμμετοχή»';

  @override
  String get lobbyInviteTitle => 'Πρόσκληση παιχνιδιού';

  @override
  String get lobbyInvitedToPlay => 'Σας προσκάλεσαν να παίξετε';

  @override
  String get lobbyEnterGame => 'Είσοδος στο παιχνίδι';

  @override
  String get lobbyGone => 'Το λόμπι δεν είναι πλέον διαθέσιμο';

  @override
  String get lobbyInvite => 'Πρόσκληση';

  @override
  String get lobbyInviteSent => 'Η πρόσκληση στάλθηκε';

  @override
  String get lobbyCopyLink => 'Κοινοποίηση συνδέσμου παιχνιδιού';

  @override
  String get lobbyLinkCopied => 'Ο σύνδεσμος αντιγράφηκε';

  @override
  String get lobbyNoFriendsOnline => 'Κανένας φίλος σε σύνδεση. Κοινοποιήστε τον σύνδεσμο παραπάνω ή περιμένετε να συνδεθούν φίλοι.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Αντίπαλος';

  @override
  String get gameYouWon => 'Κερδίσατε!';

  @override
  String get gameYouWonOpponentLeft => 'Κερδίσατε — ο αντίπαλος αποχώρησε';

  @override
  String get gameYouWonOpponentTimeout => 'Κερδίσατε — έληξε ο χρόνος του αντιπάλου';

  @override
  String get gameDraw => 'Ισοπαλία';

  @override
  String get gameExitTitle => 'Αποχώρηση από το παιχνίδι';

  @override
  String get gameExitConfirm => 'Αν αποχωρήσετε, θα χάσετε. Αποχώρηση ούτως ή άλλως;';

  @override
  String get gameStay => 'Παραμονή';

  @override
  String get gameLeave => 'Αποχώρηση';

  @override
  String get gameSurrender => 'Παράδοση';

  @override
  String get gameSurrenderTitle => 'Παράδοση;';

  @override
  String get gameSurrenderConfirm => 'Χάνετε την παρτίδα και τα νομίσματα του πονταρίσματος.';

  @override
  String get gameOfferDraw => 'Προσφορά ισοπαλίας';

  @override
  String get gameOfferDrawTitle => 'Προσφορά ισοπαλίας;';

  @override
  String get gameOfferDrawConfirm => 'Ο αντίπαλός σας μπορεί να αποδεχτεί ή να απορρίψει την ισοπαλία.';

  @override
  String get gameAcceptDrawTitle => 'Αποδοχή ισοπαλίας;';

  @override
  String get gameAcceptDrawConfirm => 'Η παρτίδα θα τελειώσει ισόπαλη.';

  @override
  String get gameDrawOffered => 'Ο αντίπαλος προσφέρει ισοπαλία';

  @override
  String get gameConnecting => 'Σύνδεση στο παιχνίδι…';

  @override
  String get gameWaitingOpponent => 'Αναμονή αντιπάλου';

  @override
  String get gameRematchOffer => 'Ο αντίπαλος προτείνει ρεβάνς';

  @override
  String get gameRematchDeclined => 'Ο αντίπαλος απέρριψε το ρεβάνς';

  @override
  String get gameRematch => 'Ρεβάνς';

  @override
  String get gameOtherOpponent => 'Άλλος αντίπαλος';

  @override
  String get gameSwapSidesAction => 'Αλλαγή πλευράς';

  @override
  String get gameWriteMessage => 'Γράψτε μήνυμα';

  @override
  String get chatsTitle => 'Συνομιλίες';

  @override
  String get chatsEmpty => 'Δεν υπάρχουν ακόμα συνομιλίες.\nΠατήστε το εικονίδιο πάνω δεξιά για να επιλέξετε φίλο και να ξεκινήσετε.';

  @override
  String get chatsNewChat => 'Νέα συνομιλία';

  @override
  String get chatsNoMessages => 'Χωρίς μηνύματα';

  @override
  String get chatsClearTitle => 'Εκκαθάριση συνομιλίας;';

  @override
  String get chatsClearDesc => 'Η συνομιλία θα διαγραφεί οριστικά.';

  @override
  String get chatsClearConfirm => 'Εκκαθάριση';

  @override
  String get chatsBlockTitle => 'Αποκλεισμός αυτού του χρήστη;';

  @override
  String get chatsBlockDesc => 'Δεν θα μπορείτε πλέον να ανταλλάσσετε μηνύματα. Η συνομιλία και η φιλία θα αφαιρεθούν.';

  @override
  String get chatsBlockConfirm => 'Αποκλεισμός';

  @override
  String get chatsBlockedUsers => 'Αποκλεισμένοι χρήστες';

  @override
  String get chatsUnblock => 'Άρση αποκλεισμού';

  @override
  String get chatDialog => 'Συνομιλία';

  @override
  String get chatEmpty => 'Δεν υπάρχουν ακόμα μηνύματα.\nΣτείλτε το πρώτο.';

  @override
  String get chatMessageHint => 'Μήνυμα';

  @override
  String get chatPaste => 'Επικόλληση';

  @override
  String get chatEmoji => 'Emoji';

  @override
  String get chatBuyEmojiHint => 'Αγοράστε emoji στο κατάστημα της αρχικής οθόνης';

  @override
  String get chatEditing => 'Επεξεργασία';

  @override
  String get chatToday => 'Σήμερα';

  @override
  String get chatYesterday => 'Χθες';

  @override
  String get chatFriendsOnly => 'Κείμενο μόνο για φίλους';

  @override
  String get emojiGroupEmotions => 'Συναισθήματα';

  @override
  String get emojiGroupGame => 'Παιχνίδια';

  @override
  String get emojiGroupFlags => 'Σημαίες';

  @override
  String get emojiGroupAnimals => 'Ζώα';

  @override
  String get emojiGroupFood => 'Φαγητό';

  @override
  String get emojiGroupTravel => 'Ταξίδια';

  @override
  String get emojiGroupParty => 'Γιορτή';

  @override
  String get emojiGroupObjects => 'Αντικείμενα';

  @override
  String get friendsTitle => 'Φίλοι';

  @override
  String get friendsTabFriends => 'Φίλοι';

  @override
  String get friendsTabIncoming => 'Εισερχόμενα';

  @override
  String get friendsTabOutgoing => 'Εξερχόμενα';

  @override
  String get friendsAdd => 'Προσθήκη φίλου';

  @override
  String get friendsRequestSent => 'Το αίτημα στάλθηκε';

  @override
  String get friendsFindTab => 'Εύρεση φίλου';

  @override
  String get friendsSearchHint => 'Αναζήτηση με όνομα χρήστη';

  @override
  String get friendsSearchPrompt => 'Χρησιμοποιήστε την αναζήτηση για νέους φίλους';

  @override
  String get friendsNothingFound => 'Δεν βρέθηκε τίποτα';

  @override
  String get friendsEmpty => 'Δεν έχετε ακόμα φίλους';

  @override
  String get friendsNoIncoming => 'Δεν υπάρχουν εισερχόμενα αιτήματα';

  @override
  String get friendsNoOutgoing => 'Δεν υπάρχουν εξερχόμενα αιτήματα';

  @override
  String get friendsAlreadyFriends => 'Ήδη φίλοι';

  @override
  String get friendsRemoveTitle => 'Αφαίρεση από τους φίλους;';

  @override
  String get friendsRemoved => 'Αφαιρέθηκε από τους φίλους';

  @override
  String get friendsRequestAccepted => 'Το αίτημα έγινε αποδεκτό';

  @override
  String get friendsRequestDeclined => 'Το αίτημα απορρίφθηκε';

  @override
  String get friendsRequestCancelled => 'Το αίτημα ακυρώθηκε';

  @override
  String get profileTitle => 'Προφίλ';

  @override
  String get profileSignInPrompt => 'Συνδεθείτε στον λογαριασμό σας';

  @override
  String get profileSignInHint => 'Για να ρυθμίσετε το προσωπικό σας προφίλ';

  @override
  String get profileEdit => 'Επεξεργασία';

  @override
  String get profileCollections => 'Συλλογές';

  @override
  String get profileAge => 'Ηλικία';

  @override
  String get profileGender => 'Φύλο';

  @override
  String get profileGenderUnset => 'Δεν έχει οριστεί';

  @override
  String get profileGenderMale => 'Άνδρας';

  @override
  String get profileGenderFemale => 'Γυναίκα';

  @override
  String get profileAvatar => 'Άβαταρ';

  @override
  String get profileUploadPhoto => 'Μεταφόρτωση φωτογραφίας';

  @override
  String get profileChangePhoto => 'Αλλαγή φωτογραφίας';

  @override
  String get shopTitle => 'Κατάστημα';

  @override
  String get shopEmojis => 'Emoji';

  @override
  String get shopEmojisSubtitle => 'Κινούμενα emoji για συνομιλία';

  @override
  String get shopCollections => 'Συλλογές';

  @override
  String get shopCollectionsSubtitle => 'Προβολή προφίλ, δώρα και έσοδα';

  @override
  String get shopStakes => 'Πονταρίσματα';

  @override
  String get shopStakesSubtitle => 'Ξεκλείδωμα υψηλότερων πονταρισμάτων';

  @override
  String get inventoryTitle => 'Αντικείμενα';

  @override
  String get inventoryEmpty => 'Δεν υπάρχει τίποτα ακόμα — δείτε το κατάστημα';

  @override
  String get inventoryFrames => 'Πλαίσια';

  @override
  String get inventoryClaim => 'Διεκδίκηση';

  @override
  String get inventorySell => 'Πώληση';

  @override
  String get inventoryGift => 'Δώρο';

  @override
  String get messageEdited => 'επεξεργασμένο';

  @override
  String get messageDeleted => 'Το μήνυμα διαγράφηκε';

  @override
  String get photo => 'Φωτογραφία';

  @override
  String get camera => 'Κάμερα';

  @override
  String get gallery => 'Συλλογή';

  @override
  String get connectionError => 'Αδυναμία σύνδεσης με τον διακομιστή.';

  @override
  String get serverError => 'Σφάλμα διακομιστή. Δοκιμάστε ξανά αργότερα.';

  @override
  String get sessionExpired => 'Η συνεδρία έληξε. Συνδεθείτε ξανά.';

  @override
  String get errNoInternet => 'Δεν υπάρχει σύνδεση στο διαδίκτυο.';

  @override
  String get errTimeout => 'Λήξη χρονικού ορίου αιτήματος. Δοκιμάστε ξανά.';

  @override
  String get errGamesUnavailable => 'Τα παιχνίδια δεν είναι προσωρινά διαθέσιμα';

  @override
  String get errSettingsSaveFailed => 'Αδυναμία αποθήκευσης ρύθμισης';

  @override
  String get errPushPermission => 'Επιτρέψτε τις ειδοποιήσεις στο πρόγραμμα περιήγησης ή στις ρυθμίσεις συστήματος.';

  @override
  String get balanceTitle => 'Υπόλοιπο';

  @override
  String get coinBronze => 'Χαλκός';

  @override
  String get coinSilver => 'Ασήμι';

  @override
  String get coinGold => 'Χρυσός';

  @override
  String get coinDiamond => 'Διαμάντι';

  @override
  String get balanceZeroBronze => '0 χάλκινα';

  @override
  String balanceBronzes(int count) {
    return '$count χάλκινα';
  }

  @override
  String balanceSilvers(int count) {
    return '$count ασημένια';
  }

  @override
  String balanceGolds(int count) {
    return '$count χρυσά';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count διαμάντια';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/ημέρα';
  }

  @override
  String get balanceAbbrBronze => 'χλ';

  @override
  String get balanceAbbrSilver => 'ασ.';

  @override
  String get balanceAbbrGold => 'χρ.';

  @override
  String get commonBackHome => 'Πίσω στην αρχική';

  @override
  String get commonCopied => 'Αντιγράφηκε';

  @override
  String get commonClear => 'Εκκαθάριση';

  @override
  String get commonTryLater => 'Δοκιμάστε ξανά αργότερα.';

  @override
  String get commonTryRefresh => 'Δοκιμάστε να ανανεώσετε τη σελίδα.';

  @override
  String get coinsTitle => 'Νομίσματα';

  @override
  String get coinsLoginReward => 'Ανταμοιβή σύνδεσης';

  @override
  String get coinsLoginAvailableToday => 'Η σημερινή ανταμοιβή είναι διαθέσιμη';

  @override
  String get coinsLoginStreak => 'Καθημερινή σειρά συνδέσεων';

  @override
  String get coinsFriendReward => 'Ανταμοιβή φίλου';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount για εγγραφή μέσω του συνδέσμου σας';
  }

  @override
  String get coinsLoadRewardsFailed => 'Αποτυχία φόρτωσης ανταμοιβών';

  @override
  String get coinsClaimReward => 'Λήψη ανταμοιβής';

  @override
  String get coinsAlreadyClaimed => 'Ήδη λήφθηκε';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · σήμερα';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · απομένει 1 ημέρα';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · απομένουν $remaining';
  }

  @override
  String get coinsInviteFriend => 'Προσκαλέστε φίλο';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount για κάθε άτομο που εγγράφεται μέσω του συνδέσμου σας';
  }

  @override
  String get coinsCopyLink => 'Αντιγραφή συνδέσμου';

  @override
  String get coinsHowItWorks => 'Πώς λειτουργεί';

  @override
  String get coinsHowStep1 => 'Αντιγράψτε τον σύνδεσμο και στείλτε τον σε φίλο';

  @override
  String get coinsHowStep2 => 'Ο φίλος εγγράφεται μέσω αυτού του συνδέσμου';

  @override
  String coinsHowStep3(String amount) {
    return 'Λαμβάνετε $amount';
  }

  @override
  String get achievementsTitle => 'Επιτεύγματα';

  @override
  String achievementsProgress(String progress) {
    return 'Πρόοδος: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Το πλαίσιο ελήφθη';

  @override
  String get achievementsClaimed => 'Ελήφθη';

  @override
  String get achievementsOpenFrame => 'Άνοιγμα πλαισίου';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Είστε σίγουροι ότι θέλετε να αφαιρέσετε τον/την $name από τους φίλους;';
  }

  @override
  String get friendsRemoveConfirmAction => 'Αφαίρεση';

  @override
  String get friendsRemove => 'Αφαίρεση από φίλους';

  @override
  String get friendsAcceptRequest => 'Αποδοχή αιτήματος';

  @override
  String get friendsDeclineRequest => 'Απόρριψη αιτήματος';

  @override
  String get friendsCancelRequest => 'Ακύρωση αιτήματος';

  @override
  String get friendsSendRequest => 'Αποστολή αιτήματος φιλίας';

  @override
  String get friendsRequestAlreadySent => 'Το αίτημα έχει ήδη σταλεί';

  @override
  String get friendsIncomingStatus => 'Εισερχόμενο αίτημα';

  @override
  String get friendsOutgoingStatus => 'Εξερχόμενο αίτημα';

  @override
  String get friendsNotFriends => 'Δεν είστε φίλοι';

  @override
  String get friendsCollapseSearch => 'Σύμπτυξη αναζήτησης';

  @override
  String get friendsExpandSearch => 'Εμφάνιση αναζήτησης';

  @override
  String get friendsLoadFailed => 'Αποτυχία φόρτωσης φίλων';

  @override
  String friendsSince(String date) {
    return 'Φίλοι από: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Εισερχόμενο αίτημα: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Εξερχόμενο αίτημα: $date';
  }

  @override
  String get userInfoTitle => 'Πληροφορίες χρήστη';

  @override
  String profileAgeYears(int age) {
    return '$age ετών';
  }

  @override
  String get shopBuy => 'Αγορά';

  @override
  String get shopBuyTitle => 'Αγορά;';

  @override
  String get shopBuyStakeTitle => 'Αγορά πονταρίσματος;';

  @override
  String get shopBuyEmojiTitle => 'Αγορά emoji;';

  @override
  String get shopBuyCollectionTitle => 'Αγορά συλλογής;';

  @override
  String shopPrice(String price) {
    return 'Τιμή: $price';
  }

  @override
  String get shopOwned => 'Αγορασμένο';

  @override
  String get shopEmpty => 'Ακόμα άδειο';

  @override
  String shopPurchased(String title) {
    return 'Αγοράστηκε το $title';
  }

  @override
  String get shopEmojiUses => 'Λαμβάνετε: 10 χρήσεις';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 χρήσεις';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 χρήσεις';
  }

  @override
  String get shopBuyTen => 'Αγορά · 10 τεμ.';

  @override
  String shopDailyIncome(String amount) {
    return 'Έσοδο: $amount';
  }

  @override
  String get shopBuyOnce => 'Εφάπαξ αγορά';

  @override
  String get shopSellRefund => 'Η πώληση επιστρέφει το 80% του κόστους';

  @override
  String shopCollectionAdded(String title) {
    return 'Το $title προστέθηκε στο προφίλ';
  }

  @override
  String shopSetBonus(int percent) {
    return 'μπόνους σετ +$percent%';
  }

  @override
  String get shopSetComplete => 'Ολοκληρώθηκε';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Συλλέχθηκε · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Πώληση;';

  @override
  String inventorySellDesc(String amount) {
    return 'Θα λάβετε $amount';
  }

  @override
  String inventorySold(String amount) {
    return 'Πουλήθηκε: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Προσθέστε πρώτα φίλους';

  @override
  String get inventoryGiftTitle => 'Δώρο συλλογής;';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'Να δώσετε το «$title» στον/στην $name;';
  }

  @override
  String inventoryGifted(String title) {
    return 'Δωρίστηκε: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'Ο παίκτης έχει ήδη αυτό το αντικείμενο';

  @override
  String get inventoryGiftSelf => 'Δεν μπορείτε να χαρίσετε στον εαυτό σας';

  @override
  String get inventoryGiftNotOwned => 'Αυτό το αντικείμενο δεν είναι στο απόθεμά σας';

  @override
  String get inventoryLoadFailed => 'Αποτυχία φόρτωσης αντικειμένων';

  @override
  String get inventoryNoCollections => 'Δεν υπάρχουν συλλογές — αγοράστε στο κατάστημα';

  @override
  String get inventoryNoEmojis => 'Δεν υπάρχουν emoji — αγοράστε στο κατάστημα';

  @override
  String get inventoryNoFrames => 'Δεν υπάρχουν πλαίσια — κερδίστε 10 παιχνίδια λίγκας (επιτεύγματα)';

  @override
  String get inventoryNoStakes => 'Δεν υπάρχουν αγορασμένα πονταρίσματα';

  @override
  String inventoryEmojiLeft(int count) {
    return 'Απομένουν $count';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Έσοδο: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Έσοδο αύριο: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Έτοιμο';

  @override
  String get inventoryIncomeTomorrowLabel => 'Αύριο';

  @override
  String inventoryStakeGold(String amount) {
    return 'Μπορείτε να ποντάρετε $amount χρυσό';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'Μπορείτε να ποντάρετε $amount ασήμι';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'Ελήφθη +$amount';
  }

  @override
  String get chatsLoadFailed => 'Αποτυχία φόρτωσης συνομιλιών';

  @override
  String get chatsLoadListFailed => 'Αποτυχία φόρτωσης λίστας';

  @override
  String get chatsBlockedEmpty => 'Η λίστα είναι άδεια';

  @override
  String chatsBlockedAt(String date) {
    return 'Αποκλεισμένος: $date';
  }

  @override
  String get chatsCreateFailed => 'Αποτυχία δημιουργίας συνομιλίας';

  @override
  String get chatsNeedFriendsFirst => 'Προσθέστε πρώτα φίλους και μετά μπορείτε να ανοίξετε συνομιλία.';

  @override
  String get chatsFriendsNotFound => 'Δεν βρέθηκαν φίλοι';

  @override
  String get chatsFindFriendHint => 'Βρείτε φίλο με ψευδώνυμο';

  @override
  String get chatsSelectChat => 'Επιλέξτε συνομιλία';

  @override
  String get chatsSelectHint => 'Επιλέξτε διάλογο από τη λίστα αριστερά';

  @override
  String get chatEditFailed => 'Αποτυχία επεξεργασίας μηνύματος';

  @override
  String get chatSendFailed => 'Αποτυχία αποστολής μηνύματος';

  @override
  String get chatDeleteFailed => 'Αποτυχία διαγραφής μηνύματος';

  @override
  String get chatEmojiSendFailed => 'Αποτυχία αποστολής emoji';

  @override
  String get chatLoadFailed => 'Αποτυχία φόρτωσης μηνυμάτων';

  @override
  String get chatBackToGame => 'Πίσω στο παιχνίδι';

  @override
  String get chatBackToChats => 'Πίσω στις συνομιλίες';

  @override
  String get chatActions => 'Ενέργειες συνομιλίας';

  @override
  String get chatAutoTranslate => 'Auto-translate';

  @override
  String get chatScrollToEnd => 'Στο τέλος της συνομιλίας';

  @override
  String chatReplyingTo(String name) {
    return 'Απάντηση στον/στην $name';
  }

  @override
  String get chatGift => 'Δώρο';

  @override
  String get chatCollection => 'Συλλογή';

  @override
  String get chatGiftCollection => 'Δώρο · συλλογή';

  @override
  String get chatThisUser => 'αυτού του χρήστη';

  @override
  String get gamesLobbyLoadFailed => 'Αποτυχία φόρτωσης λόμπι.';

  @override
  String get gamesTapChangeStake => 'Πατήστε για αλλαγή πονταρίσματος';

  @override
  String get gamesTapChangeTurnTime => 'Πατήστε για αλλαγή χρόνου κινήσεων';

  @override
  String get gamesTapChangeGrid => 'Πατήστε για αλλαγή μεγέθους πλέγματος';

  @override
  String get gamesSwapSidesHint => 'Το O μπορεί να γίνει X μετά την 1η κίνηση';

  @override
  String get gamesNoCenterHint => 'Η πρώτη κίνηση δεν μπορεί να είναι στο κέντρο';

  @override
  String get lobbyInviteSentShort => 'Εστάλη';

  @override
  String get lobbyInvitesSentWaiting => 'Οι προσκλήσεις στάλθηκαν. Αναμονή απάντησης.';

  @override
  String get lobbyLinkCopiedHint => 'Επικολλήστε τον σε συνομιλία ή μήνυμα σε φίλο';

  @override
  String get lobbyCopyLinkHint => 'Αντιγραφή συνδέσμου στο πρόχειρο';

  @override
  String lobbyCreatorInvites(String name) {
    return 'Ο/Η $name σας προσκαλεί να παίξετε';
  }

  @override
  String gameOpponentWon(String name) {
    return 'Νίκησε ο/η $name';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Ο χρόνος τελείωσε. Νίκησε ο/η $name';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds δ';
  }

  @override
  String get adminTitle => 'Διαχείριση';

  @override
  String get tournamentsTitle => 'Τουρνουά';

  @override
  String get profileAgeInvalid => 'Εισαγάγετε ηλικία από 1 έως 111';

  @override
  String get profileSaveFailed => 'Αποτυχία αποθήκευσης προφίλ';

  @override
  String get profileNameHint => 'Λατινικά γράμματα, ψηφία, _ έως 10 χαρακτήρες';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'Από 1 έως 111';

  @override
  String get profileAboutHint => 'Έως 100 χαρακτήρες (προαιρετικά)';

  @override
  String get profileProcessingPhoto => 'Επεξεργασία φωτογραφίας…';

  @override
  String get profileCropTitle => 'Επιλέξτε περιοχή avatar';

  @override
  String get profileCropHint => 'Μεγεθύνετε και μετακινήστε τη φωτογραφία';

  @override
  String get profileApply => 'Εφαρμογή';

  @override
  String get profilePreparing => 'Προετοιμασία…';

  @override
  String timeSecondsShort(int seconds) {
    return '$seconds δ';
  }

  @override
  String get timeOneMin => '1 λεπτό';

  @override
  String get timeTenMin => '10 λεπτά';

  @override
  String rulesIntro(String grid) {
    return 'Τρίλιζα σε πίνακα $grid. Εναλλάξ· ξεκινά ο X.';
  }

  @override
  String rulesWin(int n) {
    return 'Νίκη: σχηματίστε $n στη σειρά οριζόντια, κάθετα ή διαγώνια.';
  }

  @override
  String get rulesNoTimeLimit => 'Χωρίς χρονικό όριο ανά κίνηση.';

  @override
  String rulesTurnTime(String time) {
    return 'Χρόνος ανά κίνηση: $time.';
  }

  @override
  String rulesStake(String stake) {
    return 'Ποντάρισμα: $stake. Τόσα νομίσματα παίζονται.';
  }

  @override
  String get rulesSwap => 'Αλλαγή πλευρών: ο O μπορεί να αλλάξει με τον X μετά την πρώτη κίνηση του X.';

  @override
  String get rulesNoCenter => 'Απαγόρευση κέντρου: ο X δεν μπορεί να παίξει στο κέντρο στην πρώτη κίνηση.';

  @override
  String get collectionSetLegends => 'Θρύλοι';

  @override
  String get collectionSetSpace => 'Διάστημα';

  @override
  String get collectionSetGems => 'Πετράδια';

  @override
  String get collectionSetParty => 'Γιορτή';

  @override
  String get collectionSetNature => 'Φύση';

  @override
  String get collectionSetAdventures => 'Περιπέτειες';

  @override
  String collectionCardMeta(String amount) {
    return 'Συλλογή · βιτρίνα · δώρο · πώληση · +$amount';
  }

  @override
  String get coinsDayOne => 'ημέρα';

  @override
  String get coinsDayFew => 'ημέρες';

  @override
  String get coinsDayMany => 'ημέρες';

  @override
  String get giftFriendTitle => 'Δώρο σε φίλο';

  @override
  String photoCount(int count) {
    return 'Φωτο ($count)';
  }

  @override
  String photoCountWithText(int count, String text) {
    return 'Φωτο ($count): $text';
  }

  @override
  String photoWithText(String text) {
    return 'Φωτο: $text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count emoji · $price';
  }

  @override
  String get chatsExpandPanel => 'Ανάπτυξη πίνακα';

  @override
  String get chatsCollapsePanel => 'Σύμπτυξη πίνακα';

  @override
  String get chatReplySourceMissing => 'Το αρχικό μήνυμα δεν βρέθηκε';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Ποντάρισμα $n ασήμι';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Ποντάρισμα $n χρυσό';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Ξεκλειδώνει ποντάρισμα $n ασήμι';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Ξεκλειδώνει ποντάρισμα $n χρυσό';
  }

  @override
  String get chatReplySelf => 'στον εαυτό σας';

  @override
  String get chatReplyPeer => 'στον συνομιλητή';

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
  String get statsTitle => 'Στατιστικά';

  @override
  String get statsLoadFailed => 'Αποτυχία φόρτωσης στατιστικών';

  @override
  String get statsAllGames => 'Όλα τα παιχνίδια';

  @override
  String get statsEmptyTitle => 'Δεν υπάρχουν παιχνίδια ακόμα';

  @override
  String get statsEmptyHint => 'Παίξτε το πρώτο σας παιχνίδι για να δείτε στατιστικά εδώ.';

  @override
  String get statsWins => 'Νίκες';

  @override
  String get statsDraws => 'Ισοπαλίες';

  @override
  String get statsLosses => 'Ήττες';

  @override
  String get statsWinRate => 'Ποσοστό νικών';

  @override
  String get statsTopWon => 'Περισσότερες νίκες εναντίον';

  @override
  String get statsTopDrawn => 'Περισσότερες ισοπαλίες με';

  @override
  String get statsTopLost => 'Περισσότερες ήττες από';

  @override
  String get statsTimePlayed => 'Χρόνος παιχνιδιού';

  @override
  String get statsYourScore => 'Το σκορ σας';

  @override
  String get profileShowStats => 'Εμφάνιση στατιστικών';

  @override
  String get statsDurationZeroMinutes => '0 λεπ';

  @override
  String get gameYouWonOpponentForfeit => 'Ο αντίπαλος παραδόθηκε. Κερδίσατε!';

  @override
  String get lobbyLeaveTitle => 'Αποχώρηση από το λόμπι;';

  @override
  String get lobbyLeaveConfirm => 'Το λόμπι θα διαγραφεί μετά την αποχώρηση. Οι προσκεκλημένοι φίλοι θα λάβουν απόρριψη.';

  @override
  String get lobbyLeave => 'Αποχώρηση';

  @override
  String statsDurationHours(int hours) {
    return '$hours ώ';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours ώ $minutes λεπ';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes λεπ';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'Παραδοθήκατε. Ο/Η $name κέρδισε';
  }

  @override
  String get supportTitle => 'Υποστήριξη';

  @override
  String get supportUnavailable => 'Η υποστήριξη δεν είναι διαθέσιμη';

  @override
  String get supportOpenFailed => 'Αποτυχία ανοίγματος συνομιλίας υποστήριξης';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Σας πιστώθηκαν $amount νομίσματα';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return 'Αφαιρέθηκαν $amount νομίσματα';
  }

  @override
  String get coinsCreditCardTitle => 'Σας πιστώθηκαν νομίσματα';

  @override
  String get coinsClaim => 'Παραλαβή';
}
