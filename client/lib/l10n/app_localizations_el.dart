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
  String get settingsSoundTitle => 'Ήχος';

  @override
  String get settingsSoundSubtitle => 'Παιχνίδια και ειδοποιήσεις';

  @override
  String get settingsSoundGames => 'Παιχνίδια';

  @override
  String get settingsSoundNotifications => 'Ειδοποιήσεις';

  @override
  String get settingsSoundTurn => 'Σειρά';

  @override
  String get settingsHapticsTitle => 'Δόνηση';

  @override
  String get settingsHapticsSubtitle => 'Μόνο ειδοποιήσεις: μηνύματα, αιτήματα, η σειρά σας και ο χρονομέτρης';

  @override
  String get settingsGamepadTitle => 'Χειριστήριο';

  @override
  String get settingsGamepadSubtitle => 'Gamepad για μενού και παρτίδες';

  @override
  String settingsGamepadConnected(String name) {
    return 'Συνδεδεμένο: $name';
  }

  @override
  String get settingsGamepadDisconnected => 'Δεν βρέθηκε gamepad. Συνδέστε χειριστήριο και πατήστε ένα κουμπί.';

  @override
  String get settingsGamepadGenericName => 'Χειριστήριο';

  @override
  String get settingsGamepadHelpNavigate => 'Πλοήγηση';

  @override
  String get settingsGamepadHelpConfirm => 'Επιλογή';

  @override
  String get settingsGamepadHelpBack => 'Πίσω';

  @override
  String get settingsGamepadHelpTabs => 'Καρτέλες';

  @override
  String get settingsGamepadHelpPlay => 'Δρομέας σε ταμπλό και χέρι: ντάμα, τρίλιζα, ναυμαχία, ντουράκ, ούνο, πόκερ και τάβλι';

  @override
  String get settingsGamepadHelpCards => 'Χαρτιά';

  @override
  String get settingsGamepadHelpKeyboard => 'Πληκτρολόγιο';

  @override
  String get settingsGamepadHelpBalance => 'Υπόλοιπο';

  @override
  String get settingsGamepadHelpLogout => 'Έξοδος';

  @override
  String get settingsGamepadHelpPage => 'Σελίδα';

  @override
  String get settingsGamepadLayoutXbox => 'Διάταξη Xbox';

  @override
  String get settingsGamepadLayoutPlayStation => 'Διάταξη PlayStation';

  @override
  String get settingsGamepadLayoutNintendo => 'Διάταξη Nintendo';

  @override
  String get gamepadKeyboardTitle => 'Πληκτρολόγιο';

  @override
  String get gamepadKeyboardSpace => 'Διάστημα';

  @override
  String get gamepadLegendConfirm => 'Επιλογή';

  @override
  String get gamepadLegendBack => 'Πίσω';

  @override
  String get gamepadLegendTabs => 'Καρτέλες';

  @override
  String get gamepadLegendCycle => 'Αλλαγή';

  @override
  String gamepadConnectedSnack(String name) {
    return 'Συνδέθηκε χειριστήριο: $name';
  }

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
  String get offlineModeOfferBody => 'Δεν υπάρχει διαδίκτυο ή η σύνδεση είναι πολύ αργή. Μπορείτε να ενεργοποιήσετε τη λειτουργία εκτός σύνδεσης και να παίξετε με bot.';

  @override
  String get offlineModeOfferAction => 'Ενεργοποίηση εκτός σύνδεσης';

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
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'Πάρε';

  @override
  String get durakActionAll => 'Όλα';

  @override
  String get durakActionDone => 'Έτοιμο';

  @override
  String get durakActionBito => 'Beat';

  @override
  String get durakHintDefend => 'Άμυνα';

  @override
  String get durakHintDefendOrTransfer => 'Άμυνα ή μεταφορά';

  @override
  String get durakHintOpponentDefends => 'Ο αντίπαλος αμύνεται';

  @override
  String get durakHintThrowInFirst => 'Ρίξτε φύλλα (μέγ. 5 στην πρώτη κάλυψη)';

  @override
  String get durakHintThrowIn => 'Ρίξτε φύλλα ή περιμένετε την άμυνα';

  @override
  String get durakHintOpponentThrows => 'Ο αντίπαλος ρίχνει';

  @override
  String get durakHintTakeFollow => 'Ρίξτε μετά την πάρε ή πατήστε «Έτοιμο»';

  @override
  String get durakHintOpponentTakeFollow => 'Ο αντίπαλος μπορεί να ρίξει μετά την πάρε';

  @override
  String get durakHintBito => 'Ρίξτε κάρτα ή πείτε «Bito»';

  @override
  String get durakHintOpponentBito => 'Ο αντίπαλος ρίχνει ή λέει «Bito»';

  @override
  String get durakHintYourAttack => 'Η σειρά σου — επιτέθηκε';

  @override
  String get durakHintOpponentAttack => 'Ο αντίπαλος επιτίθεται';

  @override
  String get durakHintYouLost => 'Έχασες — είσαι ο κάλπης';

  @override
  String get durakHintDrawAllOut => 'Ισοπαλία — όλοι έφυγαν';

  @override
  String get durakHintYouFinished => 'Έφυγες — περιμένουμε το τέλος';

  @override
  String get durakFirstLeadYou => 'Παίζετε πρώτοι';

  @override
  String get durakFirstLeadOpponent => 'Ο αντίπαλος παίζει πρώτος';

  @override
  String get durakFirstLeadBot => 'Το μποτ παίζει πρώτο';

  @override
  String durakFirstLeadOf(String name) {
    return 'Πρώτος ο $name';
  }

  @override
  String get durakFirstLeadReason => 'Χαμηλότερο ατού';

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
  String settingsAppVersion(String version) {
    return 'Έκδοση $version';
  }

  @override
  String get appUpdateTitle => 'Διαθέσιμη ενημέρωση';

  @override
  String get appUpdateBody => 'Υπάρχει νέα έκδοση της εφαρμογής. Ενημερώστε για να συνεχίσετε.';

  @override
  String get appUpdateWhatsNew => 'Τι νέο υπάρχει';

  @override
  String get appUpdateOk => 'Ενημέρωση';

  @override
  String get appUpdateLaterBanner => 'Θα ενημερώσουμε την εφαρμογή μετά από αυτό το παιχνίδι';

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
  String get apiErrWrongGameType => 'Λάθος τύπος παιχνιδιού';

  @override
  String get apiErrWrongGameTypeOrState => 'Λάθος τύπος ή κατάσταση παιχνιδιού';

  @override
  String get apiErrLobbyFull => 'Το λόμπι είναι γεμάτο';

  @override
  String get apiErrBadState => 'Μη έγκυρη κατάσταση παιχνιδιού';

  @override
  String get apiErrIllegalMove => 'Μη επιτρεπτή κίνηση';

  @override
  String get apiErrUnknownMoveType => 'Άγνωστος τύπος κίνησης';

  @override
  String get apiErrNoOpponents => 'Δεν υπάρχουν αντίπαλοι';

  @override
  String get apiErrNoOpponentsRematch => 'Δεν υπάρχουν αντίπαλοι για ρεβάνς';

  @override
  String get apiErrAlreadyInLobby => 'Είστε ήδη σε αυτό το λόμπι';

  @override
  String get apiErrGameNotActive => 'Το παιχνίδι δεν είναι ενεργό';

  @override
  String get apiErrNotInBattle => 'Δεν είστε στη φάση μάχης';

  @override
  String get apiErrNotInSetup => 'Δεν είστε στη φάση τοποθέτησης';

  @override
  String get apiErrAlreadyReady => 'Είστε ήδη έτοιμοι';

  @override
  String get apiErrAlreadyForfeited => 'Έχετε ήδη εγκαταλείψει';

  @override
  String get apiErrYouHaveForfeited => 'Έχετε εγκαταλείψει';

  @override
  String get apiErrNoDrawOffer => 'Δεν υπάρχει πρόταση ισοπαλίας';

  @override
  String get apiErrDrawOnlyPvp => 'Η ισοπαλία είναι μόνο εναντίον παίκτη';

  @override
  String get apiErrDrawOnly1v1 => 'Η ισοπαλία είναι μόνο στο 1 εναντίον 1';

  @override
  String get apiErrDrawVsBot => 'Η ισοπαλία δεν είναι διαθέσιμη εναντίον bot';

  @override
  String get apiErrDrawMultiplayer => 'Η ισοπαλία δεν είναι διαθέσιμη σε πολλούς παίκτες';

  @override
  String get apiErrDeck24TwoPlayers => 'Η τράπουλα 24 είναι μόνο για 2 παίκτες';

  @override
  String get apiErrDeck52ThreeOrFour => 'Η τράπουλα 52 απαιτεί 3 ή 4 παίκτες';

  @override
  String get apiErrAccountFrozen => 'Ο λογαριασμός είναι παγωμένος';

  @override
  String get apiErrTurnTimeInvalid => 'Ο χρόνος κίνησης πρέπει να είναι 0, 20, 60 ή 600 δευτερόλεπτα';

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
  String get gamesDurak => 'Durak';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => 'Περιστροφή';

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
  String get gamesPoker => 'Πόκερ';

  @override
  String get gamesUno => 'Uno';

  @override
  String get gamesNardy => 'Τάβλι';

  @override
  String get gamesNardyModeShort => 'Κοντό';

  @override
  String get gamesNardyModeLong => 'Μακρύ';

  @override
  String get gamesCheckers => 'Ντάμα';

  @override
  String get gamesCheckersModeRussian => 'Ρωσικά';

  @override
  String get gamesCheckersModeEnglish => 'Αγγλικά';

  @override
  String get gamesCheckersModeGiveaway => 'Παραχώρηση';

  @override
  String get gamesCheckersModeCorners => 'Γωνίες';

  @override
  String get gamesChess => 'Σκάκι';

  @override
  String get gamesChessModeClassic => 'Κλασικό';

  @override
  String get gamesChessMode960 => 'Σκάκι 960';

  @override
  String get gamesChessModeAntichess => 'Αντισκάκι';


  @override
  String get rulesCheckersPlayers => 'Παίκτες: 2.';

  @override
  String rulesCheckersMode(String mode) {
    return 'Λειτουργία: $mode.';
  }

  @override
  String rulesCheckersTime(String time) {
    return 'Время на ход: $time. Если время вышло — проигрыш.';
  }

  @override
  String get rulesCheckersIntro => 'Ταμπλό 8×8. Δύο παίκτες.';

  @override
  String get rulesCheckersPlay => 'Το χτύπημα είναι υποχρεωτικό. Ντάμα και απλό πρέπει να συνεχίζουν όσο από το τετράγωνο άφιξης υπάρχει νέο χτύπημα — δεν σταματούν στη μέση. Αν υπάρχουν πολλές κατευθύνσεις, διαλέγετε όποια θέλετε, όχι υποχρεωτικά τη μεγαλύτερη. Το απλό στην τελευταία γραμμή γίνεται ντάμα.';

  @override
  String get rulesCheckersWin => 'В русских шашках побеждает тот, кто съел все шашки соперника или лишил его хода. В поддавках наоборот: кто не может ходить — выигрывает.';

  @override
  String get rulesCheckersOfflineBot => 'Офлайн: партия против бота.';

  @override
  String get rulesCheckersPlayRussian => 'Ρωσική ντάμα: 12 πούλια ο καθένας στις σκούρες. Οι απλοί προχωρούν διαγώνια και χτυπούν μπρος και πίσω. Οι ντάμες πετούν όσες θέσεις θέλουν. Το χτύπημα είναι υποχρεωτικό: συνεχίζετε αν γίνεται, αλλά αν υπάρχουν πολλές κατευθύνσεις διαλέγετε όποια θέλετε, όχι υποχρεωτικά τη μεγαλύτερη. Κερδίζει όποιος φάει όλα τα πούλια ή αφήσει τον αντίπαλο χωρίς κινήσεις.';

  @override
  String get rulesCheckersPlayEnglish => 'Αγγλική ντάμα: 12 πούλια ο καθένας. Οι απλοί προχωρούν και χτυπούν μόνο διαγώνια μπροστά. Οι ντάμες κινούνται μία θέση διαγώνια. Το χτύπημα είναι υποχρεωτικό. Κερδίζει όποιος φάει όλα τα πούλια ή αφήσει τον αντίπαλο χωρίς κινήσεις.';

  @override
  String get rulesCheckersPlayGiveaway => 'Παραχώρηση: οι ίδιες κινήσεις με τη ρωσική ντάμα, αλλά ο στόχος είναι αντίστροφος — να χάσεις όλα τα πούλια ή να μείνεις χωρίς κίνηση. Το χτύπημα παραμένει υποχρεωτικό.';

  @override
  String get rulesCheckersPlayCorners => 'Γωνίες: τα πούλια ξεκινούν στις απέναντι γωνίες. Πηγαίνετε σε διπλανή ελεύθερη θέση οριζόντια ή κάθετα ή πηδάτε πάνω από οποιοδήποτε πούλι χωρίς να το βγάλετε. Στόχος είναι να μεταφέρετε όλα τα πούλια στη γωνία του αντιπάλου.';

  @override
  String get rulesCheckersPlayCornersNoReturn => 'Πούλι που έχει φύγει από την αρχική του γωνία δεν μπορεί να επιστρέψει εκεί.';

  @override
  String get rulesCheckersPlayCornersLeaveHome => 'Τα πούλια που είναι ακόμα στο σπίτι πρέπει να φύγουν μέσα στις πρώτες 25 κινήσεις του παίκτη.';

  @override
  String get rulesCheckersDrawRussian => 'Ισοπαλία αν η θέση επαναληφθεί τρεις φορές ή αν για 15 κινήσεις ανά πλευρά κινούνται μόνο ντάμες χωρίς πάρσιμο.';

  @override
  String get rulesCheckersDrawEnglish => 'Ισοπαλία σε τριπλή επανάληψη, μετά από 40 κινήσεις χωρίς πάρσιμο ή πιόνι, ή μία ντάμα εναντίον μίας.';

  @override
  String get rulesCheckersDrawGiveaway => 'Ισοπαλία σε τριπλή επανάληψη ή 15 κινήσεις ντάμας χωρίς πάρσιμο.';

  @override
  String get rulesCheckersDrawCorners => 'Ισοπαλία σε τριπλή επανάληψη ή 25 κινήσεις ανά πλευρά χωρίς νέο πούλι στη γωνία-στόχο.';

  @override
  String get rulesChessPlayers => 'Παίκτες: 2.';

  @override
  String rulesChessMode(String mode) {
    return 'Λειτουργία: $mode.';
  }

  @override
  String get rulesChessPlayClassic => 'Κλασικό: σκακιέρα 8×8. Κάθε πλευρά έχει βασιλιά, βασίλισσα, δύο πύργους, δύο αξιωματικούς, δύο ίππους και οκτώ πιόνια. Παίζουν τα λευκά. Συνήθεις κινήσεις, πάρσιμο εν διελεύσει, προαγωγή και ροκέ. Νίκη με ματ ή εγκατάλειψη.';

  @override
  String get rulesChessPlay960 => 'Σκάκι 960: συνήθεις κινήσεις. Η τελευταία γραμμή τυχαία κατά Φίσερ: βασιλιάς ανάμεσα στους πύργους, αξιωματικοί σε διαφορετικά χρώματα. Ροκέ στα c και g. Ματ ή εγκατάλειψη.';

  @override
  String get rulesChessPlayAntichess => 'Αντισκάκι: συνήθεις κινήσεις, το πάρσιμο είναι υποχρεωτικό. Δεν υπάρχει σαχ, ο βασιλιάς πιάνεται. Χωρίς ροκέ. Κερδίζει όποιος χάσει όλα τα κομμάτια ή μείνει χωρίς κίνηση.';

  @override
  String get rulesChessDrawClassic => 'Ισοπαλία σε πατ, τριπλή επανάληψη, κανόνα 50 κινήσεων, έλλειψη υλικού ή συμφωνία.';

  @override
  String get rulesChessDraw960 => 'Ισοπαλία σε πατ, τριπλή επανάληψη, κανόνα 50 κινήσεων, έλλειψη υλικού ή συμφωνία.';

  @override
  String get rulesChessDrawAntichess => 'Ισοπαλία σε τριπλή επανάληψη ή αν μείνουν και οι δύο χωρίς κομμάτια στην ίδια κίνηση.';


  @override
  String get checkersDrawRepetition => 'Ισοπαλία — η θέση επαναλήφθηκε τρεις φορές';

  @override
  String get checkersDrawNoProgress => 'Ισοπαλία — οι κινήσεις δεν οδηγούν σε νίκη';

  @override
  String get checkersDrawInsufficient => 'Ισοπαλία — ανεπαρκές υλικό για νίκη';

  @override
  String get rulesNardyTitle => 'Τάβλι — κανόνες';

  @override
  String get rulesNardyPlayers => 'Παίκτες: 2.';

  @override
  String rulesNardyMode(String mode) {
    return 'Λειτουργία: $mode.';
  }

  @override
  String get rulesNardyIntro => 'Ταμπλό 24 θέσεων, 15 πούλια ο καθένας. Δύο ζάρια: ένα πούλι το άθροισμα ή δύο τα μάτια.';

  @override
  String get rulesNardyPlayShort => 'Κοντό τάβλι: προχωράτε αντίθετα και μπορείτε να χτυπάτε μονά πούλια. Το χτυπημένο πάει στη μπάρα και πρέπει να ξαναμπεί. Όταν όλα είναι στο σπίτι, τα βγάζετε.';

  @override
  String get rulesNardyPlayLong => 'Μακρύ τάβλι: και οι δύο ξεκινούν από το ίδιο κεφάλι και πάνε προς την ίδια κατεύθυνση. Από το κεφάλι βγαίνει το πολύ ένα πούλι ανά σειρά. Δεν επιτρέπεται χτύπημα. Όταν όλα είναι στο σπίτι, τα βγάζετε.';

  @override
  String get rulesNardyWin => 'Νικά όποιος βγάλει πρώτος όλα τα πούλια.';

  @override
  String get rulesNardySixPrime => 'Δεν μπορείτε να κλείσετε έξι συνεχόμενα σημεία όσο κανένα πούλι του αντιπάλου δεν τα έχει προσπεράσει.';

  @override
  String get nardyRoll => 'Ρίξε';

  @override
  String get nardySkipTurn => 'Παράλειψη σειράς';

  @override
  String get nardyUndoMove => 'Αναίρεση';

  @override
  String get nardyDoneTurn => 'Έτοιμο';

  @override
  String get nardyAutoConfirm => 'Αυτόματη επιβεβαίωση';

  @override
  String get nardyAutoConfirmHint => 'Μετά από όλες τις κινήσεις ο γύρος περνά αυτόματα';

  @override
  String get nardyLayoutToggle => 'Αλλαγή διάταξης';

  @override
  String get nardyNoMoves => 'Καμία κίνηση';

  @override
  String get nardyYourRoll => 'Η ζαριά σας';

  @override
  String get nardyPipsShort => 'Απομένουν:';

  @override
  String get nardyYouWonMars => 'Κερδίσατε — μαρς!';

  @override
  String get nardyYouLostMars => 'Ήττα — μαρς';

  @override
  String get rulesNardyOfflineBot => 'Εκτός σύνδεσης: παιχνίδι με το bot.';

  @override
  String rulesUnoPlayers(int players) {
    return 'Παίκτες: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'Παιχνίδι εναντίον bot χωρίς όριο χρόνου ανά γύρο.';

  @override
  String get rulesUnoIntro => 'Ο καθένας παίρνει 7 κάρτες. Παίξτε κάρτα ίδιου χρώματος ή ίδιας αξίας (αριθμός ή ίδια ενέργεια).';

  @override
  String get rulesUnoPlay => 'Παράλειψη — ο επόμενος χάνει τη σειρά. Αντιστροφή με δύο παίκτες λειτουργεί ως παράλειψη. Το +2 στοιβάζεται μόνο σε +2 και το +4 μόνο σε +4: το πέναλτι προστίθεται (δύο +2 κάνουν τον επόμενο να τραβήξει 4). Δεν μπαίνει +2 σε +4. Όποιος δεν απαντήσει τραβά όλη τη στοίβα και χάνει τη σειρά. Δύο ίδια μη μαύρα φύλλα (π.χ. δύο κίτρινα 8) πετιούνται μαζί: παίξτε το ένα και το δίδυμο φεύγει αυτόματα.';

  @override
  String get rulesUnoWild => 'Η μαύρη κάρτα ορίζει νέο χρώμα. Παίξτε +4 μόνο αν δεν έχετε κάρτα του τρέχοντος χρώματος. Ο αντίπαλος μπορεί να αμφισβητήσει: αν το +4 ήταν νόμιμο τραβά 6· αλλιώς ο παίκτης του +4 τραβά 4 και ο αμφισβητίας παίζει.';

  @override
  String get rulesUnoDraw => 'Χωρίς νόμιμη κάρτα, τραβήξτε μία από την τράπουλα. Αν ταιριάζει, παίξτε την τώρα ή κρατήστε την και περάστε. Δεν τραβάτε όσο έχετε νόμιμη κίνηση.';

  @override
  String get rulesUnoWin => 'Στους δύο ως 100, με 3+ ως 200. Τον γύρο κερδίζει όποιος αδειάζει το χέρι.';

  @override
  String get rulesUnoCall => 'Όταν μένει μία κάρτα, πατήστε αμέσως «Uno!». Οι αντίπαλοι μπορούν να σας πιάσουν για ξεχασμένο Uno μόνο μετά από ένα δευτερόλεπτο — τότε τραβάτε 2 κάρτες.';

  @override
  String get rulesUnoScoring => 'Όποιος αδειάσει πρώτος το χέρι κερδίζει τον γύρο και παίρνει πόντους από τα χέρια των αντιπάλων: αριθμοί στην αξία, ενέργειες 20, μαύρες 50. Στους δύο ως 100, με 3+ ως 200.';

  @override
  String get unoColorRed => 'Κόκκινο';

  @override
  String get unoColorYellow => 'Κίτρινο';

  @override
  String get unoColorGreen => 'Πράσινο';

  @override
  String get unoColorBlue => 'Μπλε';

  @override
  String get unoDraw => 'Τράβηγμα';

  @override
  String get unoKeep => 'Κράτημα';

  @override
  String get unoSayUno => 'Uno!';

  @override
  String get unoChallengeUno => 'Πρόκληση Uno';

  @override
  String get unoChallengeWd4 => 'Πρόκληση +4';

  @override
  String get unoChooseColor => 'Επιλέξτε χρώμα';

  @override
  String get unoDrawPile => 'Τράπουλα';

  @override
  String get unoDiscardPile => 'Στοίβα';

  @override
  String unoCardsCount(int count) {
    return 'Κάρτες: $count';
  }

  @override
  String unoScore(int score) {
    return 'Σκορ: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'Γύρος $round · έως $target';
  }

  @override
  String get unoYourTurn => 'Η σειρά σας';

  @override
  String get unoWaitingTurn => 'Σειρά αντιπάλου';

  @override
  String get unoChooseColorHint => 'Επιλέξτε χρώμα για τον μπαλαντέρ';

  @override
  String get unoWd4Hint => 'Τραβήξτε 4 κάρτες ή προκαλέστε το Wild +4';

  @override
  String get unoDrawnHint => 'Παίξτε την κάρτα ή κρατήστε την';

  @override
  String get unoPlayHint => 'Παίξτε ίδιο χρώμα ή αξία';

  @override
  String get unoDrawHint => 'Δεν υπάρχει κάρτα — τραβήξτε από την τράπουλα';

  @override
  String unoPendingDraw(int count) {
    return '+$count κάρτες';
  }

  @override
  String get unoYouWon => 'Κερδίσατε τον αγώνα!';

  @override
  String get unoYouLost => 'Ο αγώνας τελείωσε';

  @override
  String get unoYouLostTimeout => 'Χάσατε λόγω χρόνου';

  @override
  String unoWinner(String name) {
    return 'Νικητής: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return 'Ο/Η $name κερδίζει τον γύρο';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'Επόμενο';

  @override
  String get unoRoundScoresTitle => 'Σκορ γύρου';

  @override
  String get unoDirectionClockwise => 'Δεξιόστροφα';

  @override
  String get unoDirectionCounterclockwise => 'Αριστερόστροφα';

  @override
  String get unoErrStackSameOnly => 'Στο +2 παίζετε μόνο +2, στο +4 μόνο +4. Δεν μπαίνει +2 πάνω σε +4.';

  @override
  String get unoErrCatchTooEarly => 'Περιμένετε ένα δευτερόλεπτο — μπορούν ακόμα να πουν Uno.';

  @override
  String get unoErrCallTooLate => 'Δεν μπορείτε πια να πείτε Uno. Ο επόμενος παίκτης έπαιξε ήδη.';

  @override
  String get gamesInDevelopment => 'Υπό ανάπτυξη';

  @override
  String rulesPokerPlayers(int players) {
    return 'Παίκτες: $players.';
  }

  @override
  String get rulesPokerIntro => 'Texas Hold’em. Κάθε παίκτης παίρνει 2 ιδιωτικά φύλλα· στο τραπέζι βγαίνουν 5 κοινά.';

  @override
  String get rulesPokerPlay => 'Γύροι πονταρίσματος: preflop, flop, turn και river. Fold, call, bet ή raise.';

  @override
  String get rulesPokerWin => 'Κερδίζει ο καλύτερος συνδυασμός πέντε φύλλων (ιδιωτικά + κοινά) ή ο τελευταίος μετά από folds.';

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
  String get gamesObservation => 'Παρακολούθηση';

  @override
  String get gamesObservationHint => 'Μπορείτε να παρακολουθήσετε μέχρι το τέλος';

  @override
  String get gamesFinishCurrentFirst => 'Ολοκληρώστε πρώτα το τρέχον παιχνίδι';

  @override
  String get gamesVariantClassic => 'Κλασικό';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 παίκτες';

  @override
  String get gamesVariantMulti4 => '4 παίκτες';

  @override
  String get gamesDurakModePodkidnoi => 'Προσθήκη';

  @override
  String get gamesDurakModePerevodnoi => 'Μεταφορά';

  @override
  String get gamesDurakDeck24 => '24 φύλλα';

  @override
  String get gamesDurakDeck36 => '36 φύλλα';

  @override
  String get gamesDurakDeck52 => '52 φύλλα';

  @override
  String rulesDurakMode(String mode) {
    return 'Λειτουργία: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'Παίκτες: $players. Τράπουλα: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Παίξτε εναντίον μποτ, χωρίς ποντάρισμα ή όριο χρόνου.';

  @override
  String get rulesDurakAttack => 'Ο επιτιθέμενος παίζει φύλλα· ο αμυνόμενος τα καλύπτει (ίδιο χρώμα πιο δυνατό ή ατού). Το ατού καλύπτεται μόνο με πιο δυνατό ατού.';

  @override
  String get rulesDurakBeat => 'Όταν όλα τα φύλλα καλυφθούν, ο επιτιθέμενος λέει «Bito» και πάνε στην απόρριψη. Αλλιώς ο αμυνόμενος παίρνει όλα από το τραπέζι.';

  @override
  String get rulesDurakLoser => 'Χάνει όποιος έχει φύλλα στο τέλος — ο «κάλπης».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Παίκτες $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Αίθουσα $name';
  }

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
  String get gameYouLost => 'Χάσατε';

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
  String get friendsSearchNoMatches => 'Κανένας φίλος δεν αντιστοιχεί στην αναζήτηση';

  @override
  String get friendsIncomingSearchNoMatches => 'Καμία εισερχόμενη αίτηση για την αναζήτηση';

  @override
  String get friendsOutgoingSearchNoMatches => 'Καμία εξερχόμενη αίτηση για την αναζήτηση';

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
  String get profileChangePhoto => 'Αλλαγή avatar';

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
  String get shopEmojisHelp => 'Κινούμενα emoji για τη συνομιλία. Αγοράστε ένα σετ και στείλτε τα σε φίλους.';

  @override
  String get shopCollectionsHelp => 'Συλλέξτε ένα σετ αντικειμένων: εμφανίζονται στη βιτρίνα προφίλ και μπορούν να χαριστούν ή να πουληθούν. Μια πλήρης συλλογή δίνει επιπλέον νομίσματα κάθε μέρα.\n\nΗ κατάσταση εξαρτάται από το πόσο καιρό έχεις τη συλλογή. Καινούργια — τις πρώτες 7 ημέρες, πώληση 80%. Φθαρμένη — από την 8η ημέρα έως 2 μήνες, πώληση 60%. Κουρασμένη — από 2 έως 6 μήνες, πώληση 40%. Ερειπωμένη — από 6 μήνες έως 1 έτος, πώληση 100%. Vintage — από 1 έτος, πώληση 300%.';

  @override
  String get shopStakesHelp => 'Ξεκλειδώστε υψηλότερα πονταρίσματα. Όσο υψηλότερο το ποντάρισμα, τόσο μεγαλύτερο το pot και το κέρδος.';

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
  String get coinsTasks => 'Αποστολές';

  @override
  String get coinsTasksSubtitle => 'Ανταμοιβές για προφίλ, φίλους και παιχνίδια';

  @override
  String get coinsTasksRewards => 'Διαθέσιμες ανταμοιβές προς διεκδίκηση';

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
  String get shopHave => 'Το έχεις';

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
  String get shopSellRefund => 'Η πώληση εξαρτάται από την κατάσταση της συλλογής';

  @override
  String get shopCollectionConditionInfo => 'Η κατάσταση εξαρτάται από το πόσο καιρό έχεις τη συλλογή. Καινούργια — τις πρώτες 7 ημέρες, πώληση 80%. Φθαρμένη — από την 8η ημέρα έως 2 μήνες, πώληση 60%. Κουρασμένη — από 2 έως 6 μήνες, πώληση 40%. Ερειπωμένη — από 6 μήνες έως 1 έτος, πώληση 100%. Vintage — από 1 έτος, πώληση 300%.';

  @override
  String get collectionConditionNew => 'Καινούργια';

  @override
  String get collectionConditionWorn => 'Φθαρμένη';

  @override
  String get collectionConditionTired => 'Κουρασμένη';

  @override
  String get collectionConditionShabby => 'Ερειπωμένη';

  @override
  String get collectionConditionVintage => 'Vintage';

  @override
  String collectionConditionSell(int percent) {
    return 'Πώληση $percent%';
  }

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
  String get lobbySearchShort => 'Αναζήτηση';

  @override
  String get lobbySearchPlayers => 'Αναζήτηση παικτών';

  @override
  String get lobbyInviteDeclinedShort => 'Απορρίφθηκε';

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
  String get profileGalleryTitle => 'Φωτογραφίες';

  @override
  String get profileGalleryAdd => 'Προσθήκη φωτογραφίας';

  @override
  String get profileMakePrimary => 'Ορισμός ως κύρια';

  @override
  String get profilePhotoDelete => 'Διαγραφή φωτογραφίας';

  @override
  String get profilePhotosLimit => 'Μπορείτε να ανεβάσετε έως 3 φωτογραφίες';

  @override
  String get profilePhotosEmpty => 'Δεν υπάρχουν φωτογραφίες';

  @override
  String get profilePhotoUploadFailed => 'Αποτυχία μεταφόρτωσης';

  @override
  String get profilePhotoDeleteFailed => 'Αποτυχία διαγραφής';

  @override
  String get profilePhotoTooLarge => 'Η φωτογραφία είναι πολύ μεγάλη';

  @override
  String get profileSetPrimaryFailed => 'Αποτυχία ορισμού ως κύρια';

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
    return 'Χρόνος ανά κίνηση: $time. Η λήξη του χρόνου είναι ήττα.';
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

  @override
  String get durakActionPass => 'Πάσο';

  @override
  String get durakRoleTook => 'Παίρνει';

  @override
  String get durakRoleBeats => 'Καλύπτει';

  @override
  String get durakRoleThrowIn => 'Προσθήκη';

  @override
  String get durakRoleTurn => 'Σειρά';

  @override
  String get durakRoleDefends => 'Αμύνεται';

  @override
  String get durakStatusTaking => 'Παίρνει';

  @override
  String get durakHintDefenderTurn => 'Σειρά αμυνόμενου';

  @override
  String get gameYouEliminated => 'Αποκλειστήκατε';

  @override
  String gameYouPlaced(int place) {
    return 'Τερματίσατε $placeοι';
  }

  @override
  String get gameOverNeutral => 'Το παιχνίδι τελείωσε';

  @override
  String gameTurnOf(String name) {
    return 'Σειρά του/της $name';
  }

  @override
  String get chatGroupTooltip => 'Ομαδική συνομιλία';

  @override
  String get lobbyChatNotReady => 'Η συνομιλία του λόμπι δεν είναι έτοιμη ακόμη';

  @override
  String get chatsGroupChat => 'Ομαδική συνομιλία';

  @override
  String chatsMembersCount(int count) {
    return 'Μέλη: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count μέλη';
  }

  @override
  String get chatsYouSuffix => '(εσείς)';

  @override
  String get chatTitleDurak3 => 'Durak · 3 παίκτες';

  @override
  String get chatTitleDurak4 => 'Durak · 4 παίκτες';

  @override
  String get rulesTttUltimate => 'Ultimate: εννέα μίνι-πίνακες 3×3. Μια κίνηση στέλνει τον αντίπαλο σε αυτόν τον πίνακα. Νικάτε με γραμμή στο μετα-πίνακα.';

  @override
  String get rulesTttMulti3 => '3 παίκτες: πίνακας 3×3, τρεις παίκτες (X, O, △). Κερδίζετε με γραμμή από τα σύμβολά σας.';

  @override
  String get rulesTttMulti4 => '4 παίκτες: πίνακας 4×4, τέσσερις παίκτες (X, O, △, □). Κερδίζετε με γραμμή από τα σύμβολά σας.';

  @override
  String get adminUsersTab => 'Χρήστες';

  @override
  String get adminSupportTab => 'Υποστήριξη';

  @override
  String get adminSearchHint => 'Αναζήτηση με email ή όνομα';

  @override
  String get adminRoleAdmins => 'Διαχειριστές';

  @override
  String get adminRoleUsers => 'Χρήστες';

  @override
  String get adminRoleAll => 'Όλοι οι ρόλοι';

  @override
  String get adminStatusFrozen => 'Παγωμένοι';

  @override
  String get adminStatusActive => 'Ενεργοί';

  @override
  String get adminStatusAny => 'Κάθε κατάσταση';

  @override
  String get adminOrderDesc => 'Φθίνουσα';

  @override
  String get adminOrderAsc => 'Αύξουσα';

  @override
  String adminLoadFailed(String error) {
    return 'Αποτυχία φόρτωσης: $error';
  }

  @override
  String get adminUsersEmpty => 'Δεν βρέθηκαν χρήστες';

  @override
  String get adminSortLastSeen => 'Κατά τελευταία επίσκεψη';

  @override
  String get adminSortEmail => 'Κατά email';

  @override
  String get adminSortCreated => 'Κατά ημερομηνία εγγραφής';

  @override
  String adminBronzeBalance(int amount) {
    return '$amount χαλκός';
  }

  @override
  String get adminRevokeAdmin => 'Αφαίρεση διαχειριστή';

  @override
  String get adminGrantAdmin => 'Ορισμός διαχειριστή';

  @override
  String get adminAdminRevoked => 'Τα δικαιώματα διαχειριστή αφαιρέθηκαν';

  @override
  String get adminAdminGranted => 'Τα δικαιώματα διαχειριστή δόθηκαν';

  @override
  String get adminGrantCoins => 'Πίστωση νομισμάτων';

  @override
  String get adminWriteSupport => 'Γράψτε ως υποστήριξη';

  @override
  String get adminUnfreeze => 'Ξεπάγωμα';

  @override
  String get adminFreeze => 'Πάγωμα';

  @override
  String get adminUnfrozen => 'Ξεπαγώθηκε';

  @override
  String get adminFrozenDone => 'Παγώθηκε';

  @override
  String get adminResetPassword => 'Επαναφορά κωδικού';

  @override
  String get adminCoinsAmountHint => 'Ποσό (αρνητικό = αφαίρεση)';

  @override
  String get adminReasonOptional => 'Λόγος (προαιρετικό)';

  @override
  String get adminGrantSent => 'Η κάρτα στάλθηκε στη συνομιλία υποστήριξης';

  @override
  String adminCoinsDebited(int amount) {
    return 'Αφαιρέθηκαν $amount χαλκός';
  }

  @override
  String get adminGrantVerb => 'Πίστωση';

  @override
  String get adminNewPasswordHint => 'Νέος κωδικός (ελάχ. 6)';

  @override
  String get adminPasswordReset => 'Ο κωδικός επαναφέρθηκε';

  @override
  String get adminResetVerb => 'Επαναφορά';

  @override
  String adminShortError(String error) {
    return 'Σφάλμα: $error';
  }

  @override
  String get adminSupportEmpty => 'Δεν υπάρχουν αιτήματα υποστήριξης';

  @override
  String get adminUserFallback => 'Χρήστης';

  @override
  String get apiErrTooManyRequests => 'Πάρα πολλά αιτήματα. Δοκιμάστε αργότερα.';

  @override
  String get apiErrMoveConflict => 'Σύγκρουση κίνησης. Δοκιμάστε ξανά.';
}
