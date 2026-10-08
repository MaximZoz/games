import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'בית';

  @override
  String get navProfile => 'פרופיל';

  @override
  String get navFriends => 'חברים';

  @override
  String get navChats => 'צ׳אטים';

  @override
  String get navGames => 'משחקים';

  @override
  String get navSettings => 'הגדרות';

  @override
  String get settingsTitle => 'הגדרות';

  @override
  String get settingsLanguage => 'שפה';

  @override
  String get settingsLanguageSystem => 'ברירת מחדל של המערכת';

  @override
  String get settingsSoundTitle => 'צליל';

  @override
  String get settingsSoundSubtitle => 'משחקים והתראות';

  @override
  String get settingsSoundGames => 'משחקים';

  @override
  String get settingsSoundNotifications => 'התראות';

  @override
  String get settingsSoundTurn => 'תור';

  @override
  String get settingsHapticsTitle => 'רטט';

  @override
  String get settingsHapticsSubtitle => 'התראות בלבד: הודעות, בקשות, התור שלך והטיימר';

  @override
  String get settingsGamepadTitle => 'בקר';

  @override
  String get settingsGamepadSubtitle => 'גיימפד לתפריטים ולמשחקים';

  @override
  String settingsGamepadConnected(String name) {
    return 'מחובר: $name';
  }

  @override
  String get settingsGamepadDisconnected => 'לא נמצא גיימפד. חברו בקר ולחצו על כפתור.';

  @override
  String get settingsGamepadGenericName => 'בקר';

  @override
  String get settingsGamepadHelpNavigate => 'ניווט';

  @override
  String get settingsGamepadHelpConfirm => 'בחירה';

  @override
  String get settingsGamepadHelpBack => 'חזרה';

  @override
  String get settingsGamepadHelpTabs => 'לשוניות';

  @override
  String get settingsGamepadHelpPlay => 'סמן על הלוח וביד: דמקה, איקס-עיגול, קרב אוניות, דוראק, אונו, פוקר ושש-בש';

  @override
  String get settingsGamepadHelpCards => 'קלפים';

  @override
  String get settingsGamepadHelpKeyboard => 'מקלדת';

  @override
  String get settingsGamepadHelpBalance => 'יתרה';

  @override
  String get settingsGamepadHelpLogout => 'יציאה';

  @override
  String get settingsGamepadHelpPage => 'עמוד';

  @override
  String get settingsGamepadLayoutXbox => 'פריסת Xbox';

  @override
  String get settingsGamepadLayoutPlayStation => 'פריסת PlayStation';

  @override
  String get settingsGamepadLayoutNintendo => 'פריסת Nintendo';

  @override
  String get gamepadKeyboardTitle => 'מקלדת';

  @override
  String get gamepadKeyboardSpace => 'רווח';

  @override
  String get gamepadLegendConfirm => 'בחירה';

  @override
  String get gamepadLegendBack => 'חזרה';

  @override
  String get gamepadLegendTabs => 'לשוניות';

  @override
  String get gamepadLegendCycle => 'שינוי';

  @override
  String gamepadConnectedSnack(String name) {
    return 'בקר מחובר: $name';
  }

  @override
  String get settingsOfflineModeTitle => 'מצב רשת';

  @override
  String get settingsOfflineModeSubtitle => 'אופליין: משחק מיידי מול בוט, בלי הימורים ופרסים, בלי צ׳אטים וחברים. רכישות נשמרות ומיושמות במצב אונליין. אונליין — כשיש אינטרנט או לפי הגדרת המשתמש.';

  @override
  String get settingsModeOnline => 'אונליין';

  @override
  String get settingsModeOffline => 'אופליין';

  @override
  String get gamesAlternateStartsHint => 'לסירוגין מי מתחיל את המשחק';

  @override
  String get rulesAlternateStarts => 'מי מתחיל מתחלף ממשחק למשחק.';

  @override
  String get offlineBadgeTooltip => 'מצב אופליין';

  @override
  String get offlineModePopupTitle => 'מצב אופליין';

  @override
  String get offlineModePopupBody => 'מצב אופליין פעיל. שחקו מול בוט בלי הימורים ופרסים. צ׳אטים, חברים ולובי מוסתרים. רכישות יוחלו במצב אונליין.';

  @override
  String get offlineModePopupSettings => 'הגדרות';

  @override
  String get offlineModeOfferBody => 'אין אינטרנט או שהחיבור איטי מאוד. אפשר להפעיל מצב אופליין ולשחק מול בוט.';

  @override
  String get offlineModeOfferAction => 'הפעל אופליין';

  @override
  String get gamesPlay => 'שחק';

  @override
  String get offlineGameTitle => 'משחק מול בוט';

  @override
  String get offlineGameHint => 'בלי הימורים ופרסים · אופליין בלבד';

  @override
  String get offlineBotWon => 'הבוט ניצח';

  @override
  String get offlineBotThinking => 'הבוט חושב…';

  @override
  String get offlinePlayAgain => 'שוב';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'קח';

  @override
  String get durakActionAll => 'הכל';

  @override
  String get durakActionDone => 'סיום';

  @override
  String get durakActionBito => 'Beat';

  @override
  String get durakHintDefend => 'הגן';

  @override
  String get durakHintDefendOrTransfer => 'הגן או העבר';

  @override
  String get durakHintOpponentDefends => 'היריב מתגונן';

  @override
  String get durakHintThrowInFirst => 'הוסיפו קלפים (עד 5 בסיבוב הראשון)';

  @override
  String get durakHintThrowIn => 'הוסיפו קלפים או חכו להגנה';

  @override
  String get durakHintOpponentThrows => 'היריב זורק';

  @override
  String get durakHintTakeFollow => 'זרוק אחרי לקיחה או לחץ «סיום»';

  @override
  String get durakHintOpponentTakeFollow => 'היריב יכול לזרוק אחרי לקיחה';

  @override
  String get durakHintBito => 'זרוק קלף או אמור «ביטו»';

  @override
  String get durakHintOpponentBito => 'היריב זורק או אומר «ביטו»';

  @override
  String get durakHintYourAttack => 'תורך — תקוף';

  @override
  String get durakHintOpponentAttack => 'היריב תוקף';

  @override
  String get durakHintYouLost => 'הפסדת — אתה הטיפש';

  @override
  String get durakHintDrawAllOut => 'שוויון — כולם יצאו';

  @override
  String get durakHintYouFinished => 'יצאת — מחכים לסוף';

  @override
  String get durakFirstLeadYou => 'אתם מתחילים';

  @override
  String get durakFirstLeadOpponent => 'היריב מתחיל';

  @override
  String get durakFirstLeadBot => 'הבוט מתחיל';

  @override
  String durakFirstLeadOf(String name) {
    return '$name מתחיל';
  }

  @override
  String get durakFirstLeadReason => 'הקלף החזק הנמוך';

  @override
  String get shopPurchaseQueued => 'הרכישה נשמרה — תוחל במצב אונליין';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — הרכישה הוחלה';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — הרכישה לא הוחלה: $reason';
  }

  @override
  String get settingsFriendsOnlyTitle => 'הודעות מחברים בלבד';

  @override
  String get settingsFriendsOnlySubtitle => 'מי שאינם חברים יכולים לשלוח רק אימוג׳ים. אם יש ספאם, חסמו את המשתמש זמנית.';

  @override
  String get settingsNotifications => 'התראות';

  @override
  String get settingsPushChat => 'צ׳אט';

  @override
  String get settingsPushFriends => 'חברים';

  @override
  String get settingsPushGames => 'משחקים';

  @override
  String get settingsPushRewards => 'פרסים';

  @override
  String settingsAppVersion(String version) {
    return 'גרסה $version';
  }

  @override
  String get appUpdateTitle => 'עדכון זמין';

  @override
  String get appUpdateBody => 'גרסה חדשה של האפליקציה זמינה. עדכן כדי להמשיך.';

  @override
  String get appUpdateWhatsNew => 'מה חדש';

  @override
  String get appUpdateOk => 'עדכן';

  @override
  String get appUpdateLaterBanner => 'נעדכן האפליקציה אחרי המשחק הזה';

  @override
  String get loginTitle => 'התחברות';

  @override
  String get loginSubtitle => 'הזינו אימייל או שם משתמש וסיסמה';

  @override
  String get loginEmailLabel => 'אימייל או שם משתמש';

  @override
  String get loginPasswordLabel => 'סיסמה';

  @override
  String get loginSubmit => 'התחברות';

  @override
  String get loginNoAccount => 'אין חשבון? הרשמה';

  @override
  String get loginEmailRequired => 'הזינו אימייל או שם משתמש';

  @override
  String get loginPasswordRequired => 'הזינו סיסמה';

  @override
  String get loginTooltip => 'התחברות';

  @override
  String get logoutTooltip => 'התנתקות';

  @override
  String get registerTitle => 'הרשמה';

  @override
  String get registerSubtitle => 'צרו חשבון כדי לשחק';

  @override
  String get registerNameLabel => 'שם (שם משתמש)';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'סיסמה';

  @override
  String get registerSubmit => 'הרשמה';

  @override
  String get registerHaveAccount => 'כבר יש חשבון? התחברות';

  @override
  String get registerNameRequired => 'הזינו שם';

  @override
  String get registerNameNoSpaces => 'השם לא יכול להכיל רווחים';

  @override
  String get registerNameMax => 'עד 20 תווים';

  @override
  String get registerNameHint => 'עד 20 תווים';

  @override
  String get registerEmailRequired => 'הזינו אימייל';

  @override
  String get registerEmailInvalid => 'אימייל לא תקין';

  @override
  String get registerPasswordHint => 'לפחות 6 תווים';

  @override
  String get registerPasswordMin => 'הסיסמה חייבת להיות לפחות 6 תווים';

  @override
  String get commonCancel => 'ביטול';

  @override
  String get commonSave => 'שמירה';

  @override
  String get commonDelete => 'מחיקה';

  @override
  String get commonEdit => 'עריכה';

  @override
  String get commonReply => 'תשובה';

  @override
  String get commonSend => 'שליחה';

  @override
  String get commonClose => 'סגירה';

  @override
  String get commonRetry => 'ניסיון חוזר';

  @override
  String get commonLoading => 'טוען…';

  @override
  String get commonError => 'שגיאה';

  @override
  String get commonOnline => 'מחובר';

  @override
  String get commonOffline => 'לא מחובר';

  @override
  String get commonOnlineCap => 'מחובר';

  @override
  String get commonUser => 'משתמש';

  @override
  String get commonPlayer => 'שחקן';

  @override
  String get commonAboutMe => 'עליי';

  @override
  String get commonBack => 'חזרה';

  @override
  String get commonAccept => 'אישור';

  @override
  String get commonDecline => 'דחייה';

  @override
  String get commonCreating => 'יוצר…';

  @override
  String get commonSearching => 'מחפש…';

  @override
  String get commonInsufficientCoins => 'אין מספיק מטבעות';

  @override
  String get commonNotFound => 'לא נמצא';

  @override
  String get commonServerErrorShort => 'שגיאת שרת';

  @override
  String get commonForbidden => 'הגישה נדחתה';

  @override
  String get commonUserBlocked => 'המשתמש חסום';

  @override
  String get commonUserNotFound => 'המשתמש לא נמצא';

  @override
  String get commonGenericError => 'משהו השתבש. נסו שוב.';

  @override
  String get apiErrWrongGameType => 'סוג משחק שגוי';

  @override
  String get apiErrWrongGameTypeOrState => 'סוג או מצב משחק שגוי';

  @override
  String get apiErrLobbyFull => 'הלובי מלא';

  @override
  String get apiErrBadState => 'מצב משחק לא תקין';

  @override
  String get apiErrIllegalMove => 'מהלך לא חוקי';

  @override
  String get apiErrUnknownMoveType => 'סוג מהלך לא ידוע';

  @override
  String get apiErrNoOpponents => 'אין יריבים';

  @override
  String get apiErrNoOpponentsRematch => 'אין יריבים למשחק חוזר';

  @override
  String get apiErrAlreadyInLobby => 'אתה כבר בלובי הזה';

  @override
  String get apiErrGameNotActive => 'המשחק אינו פעיל';

  @override
  String get apiErrNotInBattle => 'לא בשלב הקרב';

  @override
  String get apiErrNotInSetup => 'לא בשלב הסידור';

  @override
  String get apiErrAlreadyReady => 'אתה כבר מוכן';

  @override
  String get apiErrAlreadyForfeited => 'כבר נכנעת';

  @override
  String get apiErrYouHaveForfeited => 'נכנעת';

  @override
  String get apiErrNoDrawOffer => 'אין הצעת תיקו';

  @override
  String get apiErrDrawOnlyPvp => 'תיקו זמין רק מול שחקן';

  @override
  String get apiErrDrawOnly1v1 => 'תיקו זמין רק במשחק אחד על אחד';

  @override
  String get apiErrDrawVsBot => 'תיקו אינו זמין מול בוט';

  @override
  String get apiErrDrawMultiplayer => 'תיקו אינו זמין במשחק מרובה משתתפים';

  @override
  String get apiErrDeck24TwoPlayers => 'חפיסת 24 מיועדת לשני שחקנים בלבד';

  @override
  String get apiErrDeck52ThreeOrFour => 'חפיסת 52 מיועדת ל־3 או 4 שחקנים';

  @override
  String get apiErrAccountFrozen => 'החשבון הוקפא';

  @override
  String get apiErrTurnTimeInvalid => 'זמן התור חייב להיות 0, 20, 60 או 600 שניות';

  @override
  String get timeJustNow => 'עכשיו';

  @override
  String get timeYesterday => 'אתמול';

  @override
  String timeMinutesAgo(int count) {
    return 'לפני $count דק׳';
  }

  @override
  String timeHoursAgo(int count) {
    return 'לפני $count שע׳';
  }

  @override
  String timeDaysAgo(int count) {
    return 'לפני $count ימ׳';
  }

  @override
  String get timeWeekAgo => 'לפני שבוע';

  @override
  String timeWeeksAgo(int count) {
    return 'לפני $count שב׳';
  }

  @override
  String get timeMonthAgo => 'לפני חודש';

  @override
  String timeMonthsAgo(int count) {
    return 'לפני $count חוד׳';
  }

  @override
  String get timeYearAgo => 'לפני שנה';

  @override
  String timeYearsAgo(int count) {
    return 'לפני $count שנ׳';
  }

  @override
  String get weekdaySun => 'א׳';

  @override
  String get weekdayMon => 'ב׳';

  @override
  String get weekdayTue => 'ג׳';

  @override
  String get weekdayWed => 'ד׳';

  @override
  String get weekdayThu => 'ה׳';

  @override
  String get weekdayFri => 'ו׳';

  @override
  String get weekdaySat => 'ש׳';

  @override
  String get monthJan => 'ינו׳';

  @override
  String get monthFeb => 'פבר׳';

  @override
  String get monthMar => 'מרץ';

  @override
  String get monthApr => 'אפר׳';

  @override
  String get monthMay => 'מאי';

  @override
  String get monthJun => 'יונ׳';

  @override
  String get monthJul => 'יול׳';

  @override
  String get monthAug => 'אוג׳';

  @override
  String get monthSep => 'ספט׳';

  @override
  String get monthOct => 'אוק׳';

  @override
  String get monthNov => 'נוב׳';

  @override
  String get monthDec => 'דצמ׳';

  @override
  String get homeAchievements => 'הישגים';

  @override
  String get homeAchievementsSubtitle => 'תוצאות המשחקים שלכם';

  @override
  String get homeAchievementsRewards => 'יש פרסים לקבל';

  @override
  String get homeCoins => 'מטבעות';

  @override
  String get homeCoinsSubtitle => 'יתרה ופרסים';

  @override
  String get homeCoinsDailyReward => 'פרס התחברות יומי זמין';

  @override
  String get homeItems => 'פריטים';

  @override
  String get homeItemsInventory => 'המלאי שלכם';

  @override
  String get homeItemsGifted => 'מישהו שלח לכם אוסף';

  @override
  String get homeItemsIncome => 'הכנסת אוסף מוכנה לקבלה';

  @override
  String get homeShop => 'חנות';

  @override
  String get homeShopSubtitle => 'אימוג׳ים, הימורים, אוספים';

  @override
  String get gamesTitle => 'משחקים';

  @override
  String get gamesFindMatch => 'חיפוש משחק';

  @override
  String get gamesMyTurn => 'התור שלכם';

  @override
  String get gamesWaiting => 'ממתין';

  @override
  String get gamesLobbyTab => 'לובי';

  @override
  String get gamesTicTacToe => 'איקס־עיגול';

  @override
  String get gamesDurak => 'דוראק';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => 'סובב';

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
  String get gamesPoker => 'פוקר';

  @override
  String get gamesUno => 'אונו';

  @override
  String get gamesNardy => 'שש-בש';

  @override
  String get gamesNardyModeShort => 'קצר';

  @override
  String get gamesNardyModeLong => 'ארוך';

  @override
  String get gamesCheckers => 'דמקה';

  @override
  String get gamesCheckersModeRussian => 'רוסית';

  @override
  String get gamesCheckersModeEnglish => 'אנגלית';

  @override
  String get gamesCheckersModeGiveaway => 'הפוכות';

  @override
  String get gamesCheckersModeCorners => 'פינות';

  @override
  String get gamesChess => 'שחמט';

  @override
  String get gamesChessModeClassic => 'קלאסי';

  @override
  String get gamesChessModeRapid => 'רפיד';

  @override
  String get gamesChessModeBlitz => 'בליץ';

  @override
  String get gamesChessModeBullet => 'כדור';

  @override
  String get chessPieceQueen => 'מלכה';

  @override
  String get chessPieceRook => 'צריח';

  @override
  String get chessPieceBishop => 'רץ';

  @override
  String get chessPieceKnight => 'פרש';

  @override
  String get chessPromotionTitle => 'הכתרת רגלי';

  @override
  String get chessDrawStalemate => 'תיקו: פט';

  @override
  String get chessDrawInsufficient => 'תיקו: חומר לא מספיק';

  @override
  String get chessDrawRepetition => 'תיקו: חזרה משולשת';

  @override
  String get chessDrawFiftyMove => 'תיקו: חוק 50 המסעים';

  @override
  String get chessCheck => 'שח';

  @override
  String get rulesCheckersPlayers => 'שחקנים: 2.';

  @override
  String rulesCheckersMode(String mode) {
    return 'מצב: $mode.';
  }

  @override
  String rulesCheckersTime(String time) {
    return 'Время на ход: $time. Если время вышло — проигрыш.';
  }

  @override
  String get rulesCheckersIntro => 'לוח 8×8. שני שחקנים.';

  @override
  String get rulesCheckersPlay => 'אכילה חובה. מלכה וחייל חייבים להמשיך כל עוד מהמשבצת שנחתו עליה אפשר לאכול שוב — אסור לעצור באמצע. אם יש כמה כיוונים אפשר לבחור כל אחד, לא בהכרח את הארוך. חייל שהגיע לשורה האחרונה הופך למלכה.';

  @override
  String get rulesCheckersWin => 'В русских шашках побеждает тот, кто съел все шашки соперника или лишил его хода. В поддавках наоборот: кто не может ходить — выигрывает.';

  @override
  String get rulesCheckersOfflineBot => 'Офлайн: партия против бота.';

  @override
  String get rulesCheckersPlayRussian => 'דמקה רוסית: 12 חיילים לכל אחד במשבצות כהות. חיילים זזים באלכסון קדימה ואוכלים קדימה ואחורה. מלכות עפות לכל מרחק. אכילה חובה: חייבים להמשיך אם אפשר, אבל אם יש כמה כיוונים אפשר לבחור כל אחד — לא בהכרח את הארוך. מנצח מי שאכל את כל החיילים או השאיר את היריב בלי מהלכים.';

  @override
  String get rulesCheckersPlayEnglish => 'דמקה אנגלית: 12 חיילים לכל אחד. חיילים זזים ואוכלים רק באלכסון קדימה. מלכות זזות משבצת אחת באלכסון. אכילה חובה. מנצח מי שאכל את כל החיילים או השאיר את היריב בלי מהלכים.';

  @override
  String get rulesCheckersPlayGiveaway => 'הפוכות: אותם מהלכים כמו בדמקה רוסית, אבל המטרה הפוכה — למסור את כל החיילים או להישאר בלי מהלכים. אכילה עדיין חובה.';

  @override
  String get rulesCheckersPlayCorners => 'פינות: החיילים מתחילים בפינות נגדיות. זזים למשבצת פנויה סמוכה אופקית או אנכית, או קופצים מעל כל חייל בלי להוריד אותו. המטרה היא להעביר את כל החיילים לפינת היריב.';

  @override
  String get rulesCheckersPlayCornersNoReturn => 'חייל שעזב את פינת הפתיחה שלו אינו רשאי לחזור אליה.';

  @override
  String get rulesCheckersPlayCornersLeaveHome => 'חיילים שעדיין בבית חייבים לצאת ממנו ב־25 המהלכים הראשונים של השחקן.';

  @override
  String get rulesCheckersDrawRussian => 'תיקו אם העמדה חוזרת שלוש פעמים, או אם 15 מהלכים לכל צד הם רק מלכות בלי הכאה — גם שתיים מול שתיים.';

  @override
  String get rulesCheckersDrawEnglish => 'תיקו בחזרה משולשת, אחרי 40 מהלכים בלי הכאה או חייל, או מלכה מול מלכה.';

  @override
  String get rulesCheckersDrawGiveaway => 'תיקו בחזרה משולשת או 15 מהלכי מלכות בלי הכאה.';

  @override
  String get rulesCheckersDrawCorners => 'תיקו בחזרה משולשת או 25 מהלכים לכל צד בלי עוד חייל בפינת היעד.';

  @override
  String get rulesChessPlayers => 'שחקנים: 2.';

  @override
  String rulesChessMode(String mode) {
    return 'מצב: $mode.';
  }

  @override
  String get rulesChessPlayClassic => 'לוח 8×8. לכל צד מלך, מלכה, שני צריחים, שני רצים, שני פרשים ושמונה רגלים. הלבן מתחיל. מהלכים רגילים, הכאה דרך הילוכו, הכתרה והצרחה. ניצחון במט או בפרישה.';

  @override
  String get rulesChessDrawClassic => 'תיקו בפאט, חזרה משולשת, כלל 50 המהלכים, חוסר חומר או הסכמה.';

  @override
  String get rulesChessClockClassic => 'שעון: 60+0 — 60 דקות לכל המשחק, בלי תוספת.';

  @override
  String get rulesChessClockRapid => 'שעון: 10+0 — 10 דקות לכל המשחק, בלי תוספת.';

  @override
  String get rulesChessClockBlitz => 'שעון: 5+0 — 5 דקות לכל המשחק, בלי תוספת.';

  @override
  String get rulesChessClockBullet => 'שעון: 3+2 — 3 דקות ועוד 2 שניות לכל מהלך.';

  @override
  String get checkersDrawRepetition => 'תיקו — העמדה חזרה שלוש פעמים';

  @override
  String get checkersDrawNoProgress => 'תיקו — המהלכים לא מובילים לניצחון';

  @override
  String get checkersDrawInsufficient => 'תיקו — אין מספיק כוח לניצחון';

  @override
  String get rulesNardyTitle => 'שש-בש — חוקים';

  @override
  String get rulesNardyPlayers => 'שחקנים: 2.';

  @override
  String rulesNardyMode(String mode) {
    return 'מצב: $mode.';
  }

  @override
  String get rulesNardyIntro => 'לוח עם 24 נקודות, 15 אבנים לכל אחד. שתי קוביות: אבן אחת לסכום או שתיים לערכי הקוביות.';

  @override
  String get rulesNardyPlayShort => 'שש-בש קצר: נעים זה מול זה ואפשר להכות אבנים בודדות. אבן מוכה עולה לבר וחייבת להיכנס שוב. כשכל האבנים בבית מורידים אותן.';

  @override
  String get rulesNardyPlayLong => 'שש-בש ארוך: שניהם מתחילים מאותו ראש ונעים לאותו כיוון. מהראש יוצאת לכל היותר אבן אחת בתור. אסור להכות. כשכולן בבית מורידים אותן.';

  @override
  String get rulesNardyWin => 'מנצח מי שמוריד ראשון את כל האבנים.';

  @override
  String get rulesNardySixPrime => 'אי אפשר לחסום שש נקודות ברצף כל עוד אף כלי של היריב לא עבר אותן.';

  @override
  String get nardyRoll => 'הטל';

  @override
  String get nardySkipTurn => 'דלג על התור';

  @override
  String get nardyUndoMove => 'בטל';

  @override
  String get nardyDoneTurn => 'סיום';

  @override
  String get nardyAutoConfirm => 'אישור אוטומטי';

  @override
  String get nardyAutoConfirmHint => 'לאחר כל המהלכים התור עובר ליריב';

  @override
  String get nardyLayoutToggle => 'החלפת סידור';

  @override
  String get nardyNoMoves => 'אין מהלכים';

  @override
  String get nardyYourRoll => 'ההטלה שלך';

  @override
  String get nardyPipsShort => 'נותרו:';

  @override
  String get nardyYouWonMars => 'ניצחת — מארס!';

  @override
  String get nardyYouLostMars => 'הפסד — מארס';

  @override
  String get rulesNardyOfflineBot => 'לא מקוון: משחק מול הבוט.';

  @override
  String rulesUnoPlayers(int players) {
    return 'שחקנים: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'משחק נגד בוט ללא מגבלת זמן לתור.';

  @override
  String get rulesUnoIntro => 'כל שחקן מקבל 7 קלפים. שחקו קלף באותו צבע או באותו ערך (מספר או אותה פעולה).';

  @override
  String get rulesUnoPlay => 'דילוג — הבא מפסיד תור. היפוך כיוון בשניים פועל כדילוג. +2 רק על +2 ו-+4 רק על +4: הקנס מצטבר (שתי +2 — הבא שולף 4). אסור לשים +2 על +4. מי שלא מגיב שולף את כל הערימה ומדלג. שתי קלפים זהים שאינם שחורים (למשל שתי 8 צהובות) נזרקים יחד: משחקים אחד והתאום יוצא אוטומטית.';

  @override
  String get rulesUnoWild => 'קלף שחור קובע צבע חדש. משחקים +4 רק בלי קלף בצבע הנוכחי. היריב יכול לערער: אם ה-+4 היה חוקי הוא שולף 6; אחרת משחק ה-+4 שולף 4 והמערער משחק.';

  @override
  String get rulesUnoDraw => 'בלי קלף חוקי — שלפו אחד מהחפיסה. אם הוא מתאים אפשר לשחק אותו מיד או להשאיר ולהעביר תור. אסור לשלוף כשיש מהלך חוקי.';

  @override
  String get rulesUnoWin => 'אחד על אחד עד 100, ב־3+ עד 200. את הסיבוב זוכה מי שמרוקן את היד.';

  @override
  String get rulesUnoCall => 'כשנשאר קלף אחד לחצו מיד «אונו!». יריבים יכולים לתפוס אתכם על שכחת אונו רק אחרי שנייה — ואז שולפים 2 קלפים.';

  @override
  String get rulesUnoScoring => 'מי שמרקין ראשון את היד זוכה בסיבוב ומקבל נקודות על ידי היריבים: מספרים לפי ערך, פעולות 20, שחורים 50. אחד על אחד עד 100, ב־3+ עד 200.';

  @override
  String get unoColorRed => 'אדום';

  @override
  String get unoColorYellow => 'צהוב';

  @override
  String get unoColorGreen => 'ירוק';

  @override
  String get unoColorBlue => 'כחול';

  @override
  String get unoDraw => 'משיכה';

  @override
  String get unoKeep => 'שמירה';

  @override
  String get unoSayUno => 'אונו!';

  @override
  String get unoChallengeUno => 'אתגר אונו';

  @override
  String get unoChallengeWd4 => 'אתגר +4';

  @override
  String get unoChooseColor => 'בחרו צבע';

  @override
  String get unoDrawPile => 'ערימת משיכה';

  @override
  String get unoDiscardPile => 'ערימת השלכה';

  @override
  String unoCardsCount(int count) {
    return 'קלפים: $count';
  }

  @override
  String unoScore(int score) {
    return 'ניקוד: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'סיבוב $round · עד $target';
  }

  @override
  String get unoYourTurn => 'התור שלך';

  @override
  String get unoWaitingTurn => 'תור היריב';

  @override
  String get unoChooseColorHint => 'בחרו צבע לקלף החופשי';

  @override
  String get unoWd4Hint => 'משכו 4 קלפים או אתגרו Wild +4';

  @override
  String get unoDrawnHint => 'שחקו בקלף שנמשך או שמרו אותו';

  @override
  String get unoPlayHint => 'שחקו צבע או ערך תואם';

  @override
  String get unoDrawHint => 'אין קלף מתאים — משכו מהערימה';

  @override
  String unoPendingDraw(int count) {
    return '+$count קלפים';
  }

  @override
  String get unoYouWon => 'ניצחת במשחק!';

  @override
  String get unoYouLost => 'המשחק הסתיים';

  @override
  String get unoYouLostTimeout => 'הפסדת בגלל הזמן';

  @override
  String unoWinner(String name) {
    return 'מנצח: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name זוכה בסיבוב';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'המשך';

  @override
  String get unoRoundScoresTitle => 'ניקוד הסיבוב';

  @override
  String get unoDirectionClockwise => 'עם כיוון השעון';

  @override
  String get unoDirectionCounterclockwise => 'נגד כיוון השעון';

  @override
  String get unoErrStackSameOnly => 'אפשר לשים +2 רק על +2 ו-+4 רק על +4. אי אפשר לשים +2 על +4.';

  @override
  String get unoErrCatchTooEarly => 'חכו שנייה — עדיין אפשר להגיד אונו.';

  @override
  String get unoErrCallTooLate => 'אי אפשר כבר להגיד אונו. השחקן הבא כבר שיחק.';

  @override
  String get gamesInDevelopment => 'בפיתוח';

  @override
  String rulesPokerPlayers(int players) {
    return 'שחקנים: $players.';
  }

  @override
  String get rulesPokerIntro => 'טקסס הולדם. לכל שחקן 2 קלפים פרטיים; על השולחן יוצאים 5 קלפים קהילתיים.';

  @override
  String get rulesPokerPlay => 'סבבי הימורים: פרה-פלופ, פלופ, טרן וריבר. אפשר לקפל, להשוות, להמר או להעלות.';

  @override
  String get rulesPokerWin => 'מנצחת היד הטובה ביותר מחמישה קלפים (פרטיים + קהילתיים), או השחקן האחרון אחרי קיפולים.';

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
  String get gamesRules => 'חוקים';

  @override
  String get gamesRulesTitle => 'חוקי המשחק';

  @override
  String get gamesCreate => 'יצירת משחק';

  @override
  String get gamesJoin => 'הצטרפות';

  @override
  String get gamesOpponentTurn => 'תור היריב';

  @override
  String get gamesCurrentGame => 'משחק נוכחי';

  @override
  String get gamesInvitedYou => 'הוזמנתם';

  @override
  String get gamesTurnTime => 'זמן לתור';

  @override
  String get gamesGridSize => 'גודל לוח';

  @override
  String get gamesSwapSides => 'החלפת צד';

  @override
  String get gamesNoCenter => 'ללא פתיחה במרכז';

  @override
  String get gamesObservation => 'צפייה';

  @override
  String get gamesObservationHint => 'אפשר לצפות עד סוף המשחק';

  @override
  String get gamesFinishCurrentFirst => 'סיים קודם המשחק הנוכחי';

  @override
  String get gamesVariantClassic => 'קלאסי';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 שחקנים';

  @override
  String get gamesVariantMulti4 => '4 שחקנים';

  @override
  String get gamesDurakModePodkidnoi => 'הוספה';

  @override
  String get gamesDurakModePerevodnoi => 'העברה';

  @override
  String get gamesDurakDeck24 => '24 קלפים';

  @override
  String get gamesDurakDeck36 => '36 קלפים';

  @override
  String get gamesDurakDeck52 => '52 קלפים';

  @override
  String rulesDurakMode(String mode) {
    return 'מצב: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'שחקנים: $players. חפיסה: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'שחקו נגד בוט, בלי הימורים ובלי מגבלת זמן.';

  @override
  String get rulesDurakAttack => 'התוקף מניח קלפים; המגן מכסה אותם (אותה סדרה גבוהה יותר, או קלף שליט). שליט מכוסה רק בשליט גבוה יותר.';

  @override
  String get rulesDurakBeat => 'כשכל הקלפים מכוסים, התוקף אומר «ביטו» והקלפים הולכים לערימת הפסילה. אחרת המגן לוקח הכול מהשולחן.';

  @override
  String get rulesDurakLoser => 'המפסיד הוא מי שנשאר עם קלפים בסוף — ה«טיפש».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'שחקנים $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Lobby $name';
  }

  @override
  String get lobbyMatchmake => 'לובי';

  @override
  String get lobbyPrivateGame => 'משחק פרטי';

  @override
  String get lobbySearchingOpponent => 'מחפש יריב…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'מחפשים את המשחק: $count';
  }

  @override
  String get lobbyWaitingJoin => 'ממתין שמישהו ילחץ על ״חיפוש משחק״ או ״הצטרפות״';

  @override
  String get lobbyInviteTitle => 'הזמנה למשחק';

  @override
  String get lobbyInvitedToPlay => 'הוזמנתם לשחק';

  @override
  String get lobbyEnterGame => 'כניסה למשחק';

  @override
  String get lobbyGone => 'הלובי כבר לא זמין';

  @override
  String get lobbyInvite => 'הזמנה';

  @override
  String get lobbyInviteSent => 'ההזמנה נשלחה';

  @override
  String get lobbyCopyLink => 'שיתוף קישור למשחק';

  @override
  String get lobbyLinkCopied => 'הקישור הועתק';

  @override
  String get lobbyNoFriendsOnline => 'אין חברים מחוברים. שתפו את קישור המשחק למעלה או המתינו עד שחברים יתחברו.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'יריב';

  @override
  String get gameYouWon => 'ניצחתם!';

  @override
  String get gameYouLost => 'הפסדת';

  @override
  String get gameYouWonOpponentLeft => 'ניצחתם — היריב עזב';

  @override
  String get gameYouWonOpponentTimeout => 'ניצחתם — ליריב נגמר הזמן';

  @override
  String get gameDraw => 'תיקו';

  @override
  String get gameExitTitle => 'יציאה מהמשחק';

  @override
  String get gameExitConfirm => 'אם תצאו, תפסידו. לצאת בכל זאת?';

  @override
  String get gameStay => 'להישאר';

  @override
  String get gameLeave => 'יציאה';

  @override
  String get gameSurrender => 'הכנע';

  @override
  String get gameSurrenderTitle => 'להיכנע?';

  @override
  String get gameSurrenderConfirm => 'תפסידו את המשחק ואת מטבעות ההימור.';

  @override
  String get gameOfferDraw => 'הצע תיקו';

  @override
  String get gameOfferDrawTitle => 'להציע תיקו?';

  @override
  String get gameOfferDrawConfirm => 'היריב יכול לקבל או לדחות את התיקו.';

  @override
  String get gameAcceptDrawTitle => 'לקבל תיקו?';

  @override
  String get gameAcceptDrawConfirm => 'המשחק יסתיים בתיקו.';

  @override
  String get gameDrawOffered => 'היריב מציע תיקו';

  @override
  String get gameConnecting => 'מתחבר למשחק…';

  @override
  String get gameWaitingOpponent => 'ממתין ליריב';

  @override
  String get gameRematchOffer => 'היריב מציע משחק חוזר';

  @override
  String get gameRematchDeclined => 'היריב דחה משחק חוזר';

  @override
  String get gameRematch => 'משחק חוזר';

  @override
  String get gameOtherOpponent => 'יריב אחר';

  @override
  String get gameSwapSidesAction => 'החלפת צד';

  @override
  String get gameWriteMessage => 'כתבו הודעה';

  @override
  String get chatsTitle => 'צ׳אטים';

  @override
  String get chatsEmpty => 'עדיין אין צ׳אטים.\nלחצו על הסמל בפינה הימנית העליונה כדי לבחור חבר ולהתחיל שיחה.';

  @override
  String get chatsNewChat => 'צ׳אט חדש';

  @override
  String get chatsNoMessages => 'אין הודעות';

  @override
  String get chatsClearTitle => 'לנקות את השיחה?';

  @override
  String get chatsClearDesc => 'הצ׳אט יימחק לצמיתות.';

  @override
  String get chatsClearConfirm => 'ניקוי';

  @override
  String get chatsBlockTitle => 'לחסום משתמש זה?';

  @override
  String get chatsBlockDesc => 'לא תוכלו עוד לשלוח הודעות זה לזה. הצ׳אט והחברות יימחקו.';

  @override
  String get chatsBlockConfirm => 'חסימה';

  @override
  String get chatsBlockedUsers => 'משתמשים חסומים';

  @override
  String get chatsUnblock => 'ביטול חסימה';

  @override
  String get chatDialog => 'צ׳אט';

  @override
  String get chatEmpty => 'עדיין אין הודעות.\nשלחו את הראשונה.';

  @override
  String get chatMessageHint => 'הודעה';

  @override
  String get chatPaste => 'הדבק';

  @override
  String get chatEmoji => 'אימוג׳ים';

  @override
  String get chatBuyEmojiHint => 'קנו אימוג׳ים בחנות במסך הבית';

  @override
  String get chatEditing => 'עריכה';

  @override
  String get chatToday => 'היום';

  @override
  String get chatYesterday => 'אתמול';

  @override
  String get chatFriendsOnly => 'טקסט לחברים בלבד';

  @override
  String get emojiGroupEmotions => 'רגשות';

  @override
  String get emojiGroupGame => 'משחקים';

  @override
  String get emojiGroupFlags => 'דגלים';

  @override
  String get emojiGroupAnimals => 'חיות';

  @override
  String get emojiGroupFood => 'אוכל';

  @override
  String get emojiGroupTravel => 'נסיעות';

  @override
  String get emojiGroupParty => 'חגיגה';

  @override
  String get emojiGroupObjects => 'חפצים';

  @override
  String get friendsTitle => 'חברים';

  @override
  String get friendsTabFriends => 'חברים';

  @override
  String get friendsTabIncoming => 'נכנסות';

  @override
  String get friendsTabOutgoing => 'יוצאות';

  @override
  String get friendsAdd => 'הוספת חבר';

  @override
  String get friendsRequestSent => 'הבקשה נשלחה';

  @override
  String get friendsFindTab => 'חיפוש חבר';

  @override
  String get friendsSearchHint => 'חיפוש לפי שם משתמש';

  @override
  String get friendsSearchPrompt => 'השתמשו בחיפוש כדי למצוא חברים חדשים';

  @override
  String get friendsNothingFound => 'לא נמצא דבר';

  @override
  String get friendsEmpty => 'עדיין אין לכם חברים';

  @override
  String get friendsSearchNoMatches => 'אין חברים שתואמים לחיפוש';

  @override
  String get friendsIncomingSearchNoMatches => 'אין בקשות נכנסות שתואמות לחיפוש';

  @override
  String get friendsOutgoingSearchNoMatches => 'אין בקשות יוצאות שתואמות לחיפוש';

  @override
  String get friendsNoIncoming => 'אין בקשות נכנסות';

  @override
  String get friendsNoOutgoing => 'אין בקשות יוצאות';

  @override
  String get friendsAlreadyFriends => 'כבר חברים';

  @override
  String get friendsRemoveTitle => 'להסיר מהחברים?';

  @override
  String get friendsRemoved => 'הוסר מהחברים';

  @override
  String get friendsRequestAccepted => 'הבקשה אושרה';

  @override
  String get friendsRequestDeclined => 'הבקשה נדחתה';

  @override
  String get friendsRequestCancelled => 'הבקשה בוטלה';

  @override
  String get profileTitle => 'פרופיל';

  @override
  String get profileSignInPrompt => 'התחברו לחשבון שלכם';

  @override
  String get profileSignInHint => 'כדי להגדיר את הפרופיל האישי';

  @override
  String get profileEdit => 'עריכה';

  @override
  String get profileCollections => 'אוספים';

  @override
  String get profileAge => 'גיל';

  @override
  String get profileGender => 'מגדר';

  @override
  String get profileGenderUnset => 'לא הוגדר';

  @override
  String get profileGenderMale => 'זכר';

  @override
  String get profileGenderFemale => 'נקבה';

  @override
  String get profileAvatar => 'אווטאר';

  @override
  String get profileUploadPhoto => 'העלאת תמונה';

  @override
  String get profileChangePhoto => 'החלפת אווטאר';

  @override
  String get shopTitle => 'חנות';

  @override
  String get shopEmojis => 'אימוג׳ים';

  @override
  String get shopEmojisSubtitle => 'אימוג׳ים מונפשים לצ׳אט';

  @override
  String get shopCollections => 'אוספים';

  @override
  String get shopCollectionsSubtitle => 'תצוגת פרופיל, מתנות והכנסה';

  @override
  String get shopStakes => 'הימורים';

  @override
  String get shopStakesSubtitle => 'פתיחת הימורים גבוהים יותר';

  @override
  String get shopEmojisHelp => 'אימוג\'ים מונפשים לצ\'אט. קנו סט ושלחו אותם לחברים.';

  @override
  String get shopCollectionsHelp => 'אפשר למכור רק אוסף חדש או וינטאג׳: 80% מהמחיר אם הוא חדש ו-300% מהמחיר אם הוא וינטאג׳. בלוי, עייף ורעוע אי אפשר למכור.\n\nאספו סט פריטים: הם מופיעים בחלון הראווה של הפרופיל, אפשר לתת במתנה. כל פריט מביא מטבעות בכל יום, וסט מלא מוסיף גם בונוס נפרד.\n\nההכנסה היומית של פריט תלויה במצב והיא חלק מהסכום הרגיל. חדש מביא 100%. בלוי מביא 60%. עייף מביא 40%. רעוע מביא 100%. פריט וינטאג׳ מביא 200%, כלומר פי שניים מההכנסה היומית הרגילה.\n\nבונוס הסט המלא לא משתנה עד שהסט עצמו הופך לווינטאג׳. סט הוא וינטאג׳ כשכל פריט בו הוא וינטאג׳: הבונוס אז הוא 300%, פי שלושה מהרגיל.\n\nהמצב תלוי בכמה זמן הפריט אצלך. חדש — 7 הימים הראשונים. בלוי — מהיום השמיני עד חודשיים. עייף — מחודשיים עד 6 חודשים. רעוע — מ-6 חודשים עד שנה. וינטאג׳ — משנה.';

  @override
  String get shopStakesHelp => 'פתחו הימורים גבוהים יותר. ככל שההימור גבוה יותר, כך הקופה והזכייה גדולים יותר.';

  @override
  String get inventoryTitle => 'פריטים';

  @override
  String get inventoryEmpty => 'עדיין אין כאן כלום — בדקו את החנות';

  @override
  String get inventoryFrames => 'מסגרות';

  @override
  String get inventoryClaim => 'קבלת';

  @override
  String get inventorySell => 'מכירה';

  @override
  String get inventoryGift => 'מתנה';

  @override
  String get messageEdited => 'נערך';

  @override
  String get messageDeleted => 'ההודעה נמחקה';

  @override
  String get photo => 'תמונה';

  @override
  String get camera => 'מצלמה';

  @override
  String get gallery => 'גלריה';

  @override
  String get connectionError => 'לא ניתן להתחבר לשרת.';

  @override
  String get serverError => 'שגיאת שרת. נסו שוב מאוחר יותר.';

  @override
  String get sessionExpired => 'פג תוקף ההפעלה. התחברו שוב.';

  @override
  String get errNoInternet => 'אין חיבור לאינטרנט.';

  @override
  String get errTimeout => 'הבקשה פגה. נסו שוב.';

  @override
  String get errGamesUnavailable => 'המשחקים אינם זמינים כרגע';

  @override
  String get errSettingsSaveFailed => 'לא ניתן לשמור את ההגדרה';

  @override
  String get errPushPermission => 'אפשרו התראות בדפדפן או בהגדרות המערכת.';

  @override
  String get balanceTitle => 'יתרה';

  @override
  String get coinBronze => 'ברונזה';

  @override
  String get coinSilver => 'כסף';

  @override
  String get coinGold => 'זהב';

  @override
  String get coinDiamond => 'יהלום';

  @override
  String get balanceZeroBronze => '0 ברונזה';

  @override
  String balanceBronzes(int count) {
    return '$count ברונזה';
  }

  @override
  String balanceSilvers(int count) {
    return '$count כסף';
  }

  @override
  String balanceGolds(int count) {
    return '$count זהב';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count יהלומים';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/יום';
  }

  @override
  String get balanceAbbrBronze => 'בר';

  @override
  String get balanceAbbrSilver => 'כ.';

  @override
  String get balanceAbbrGold => 'ז.';

  @override
  String get commonBackHome => 'חזרה לדף הבית';

  @override
  String get commonCopied => 'הועתק';

  @override
  String get commonClear => 'נקה';

  @override
  String get commonTryLater => 'נסו שוב מאוחר יותר.';

  @override
  String get commonTryRefresh => 'נסו לרענן את הדף.';

  @override
  String get coinsTitle => 'מטבעות';

  @override
  String get coinsLoginReward => 'פרס התחברות';

  @override
  String get coinsLoginAvailableToday => 'פרס היום זמין';

  @override
  String get coinsLoginStreak => 'רצף התחברויות יומי';

  @override
  String get coinsFriendReward => 'פרס חבר';

  @override
  String get coinsTasks => 'משימות';

  @override
  String get coinsTasksSubtitle => 'פרסים על פרופיל, חברים ומשחקים';

  @override
  String get coinsTasksRewards => 'יש פרסים לקבלה';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount על הרשמה דרך הקישור שלך';
  }

  @override
  String get coinsLoadRewardsFailed => 'לא ניתן לטעון פרסים';

  @override
  String get coinsClaimReward => 'קבלת פרס';

  @override
  String get coinsAlreadyClaimed => 'כבר התקבל';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · היום';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · נותר יום אחד';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · נותרו $remaining';
  }

  @override
  String get coinsInviteFriend => 'הזמנת חבר';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount על כל מי שנרשם דרך הקישור שלך';
  }

  @override
  String get coinsCopyLink => 'העתקת קישור';

  @override
  String get coinsHowItWorks => 'איך זה עובד';

  @override
  String get coinsHowStep1 => 'העתיקו את הקישור ושלחו לחבר';

  @override
  String get coinsHowStep2 => 'החבר נרשם דרך הקישור';

  @override
  String coinsHowStep3(String amount) {
    return 'תקבלו $amount';
  }

  @override
  String get achievementsTitle => 'הישגים';

  @override
  String achievementsProgress(String progress) {
    return 'התקדמות: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'המסגרת התקבלה';

  @override
  String get achievementsClaimed => 'התקבל';

  @override
  String get achievementsOpenFrame => 'פתיחת מסגרת';

  @override
  String friendsRemoveConfirm(String name) {
    return 'האם אתם בטוחים שברצונכם להסיר את $name מהחברים?';
  }

  @override
  String get friendsRemoveConfirmAction => 'הסרה';

  @override
  String get friendsRemove => 'הסרה מהחברים';

  @override
  String get friendsAcceptRequest => 'אישור בקשה';

  @override
  String get friendsDeclineRequest => 'דחיית בקשה';

  @override
  String get friendsCancelRequest => 'ביטול בקשה';

  @override
  String get friendsSendRequest => 'שליחת בקשת חברות';

  @override
  String get friendsRequestAlreadySent => 'הבקשה כבר נשלחה';

  @override
  String get friendsIncomingStatus => 'בקשה נכנסת';

  @override
  String get friendsOutgoingStatus => 'בקשה יוצאת';

  @override
  String get friendsNotFriends => 'לא חברים';

  @override
  String get friendsCollapseSearch => 'כיווץ חיפוש';

  @override
  String get friendsExpandSearch => 'הצגת חיפוש';

  @override
  String get friendsLoadFailed => 'לא ניתן לטעון חברים';

  @override
  String friendsSince(String date) {
    return 'חברים מאז: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'בקשה נכנסת: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'בקשה יוצאת: $date';
  }

  @override
  String get userInfoTitle => 'מידע על המשתמש';

  @override
  String profileAgeYears(int age) {
    return '$age שנים';
  }

  @override
  String get shopBuy => 'קנייה';

  @override
  String get shopBuyTitle => 'לקנות?';

  @override
  String get shopBuyStakeTitle => 'לקנות הימור?';

  @override
  String get shopBuyEmojiTitle => 'לקנות אימוג\'י?';

  @override
  String get shopBuyCollectionTitle => 'לקנות אוסף?';

  @override
  String shopPrice(String price) {
    return 'מחיר: $price';
  }

  @override
  String get shopOwned => 'נרכש';

  @override
  String get shopHave => 'יש';

  @override
  String get shopEmpty => 'עדיין ריק';

  @override
  String shopPurchased(String title) {
    return '$title נרכש';
  }

  @override
  String get shopEmojiUses => 'תקבלו: 10 שימושים';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 שימושים';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 שימושים';
  }

  @override
  String get shopBuyTen => 'קנייה · 10 יח׳';

  @override
  String shopDailyIncome(String amount) {
    return 'הכנסה: $amount';
  }

  @override
  String get shopBuyOnce => 'רכישה חד-פעמית';

  @override
  String get shopSellRefund => 'המכירה תלויה במצב האוסף';

  @override
  String get collectionConditionNew => 'חדש';

  @override
  String get collectionConditionWorn => 'בלוי';

  @override
  String get collectionConditionTired => 'עייף';

  @override
  String get collectionConditionShabby => 'רעוע';

  @override
  String get collectionConditionVintage => 'וינטאג׳';

  @override
  String shopCollectionAdded(String title) {
    return '$title נוסף לפרופיל';
  }

  @override
  String shopSetBonus(int percent) {
    return 'בונוס סט +$percent%';
  }

  @override
  String get shopSetComplete => 'הושלם';

  @override
  String shopSetProgress(int owned, int total) {
    return 'נאסף · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'למכור?';

  @override
  String inventorySellDesc(String amount) {
    return 'תקבלו $amount';
  }

  @override
  String get inventoryCollectionNotSellable => 'אפשר למכור רק אוסף חדש או וינטאג׳.';

  @override
  String get inventoryCollectionNotSellableTitle => 'אי אפשר למכור';

  @override
  String get inventoryCollectionNotSellableHint => 'אפשר למכור רק פריט חדש או וינטאג׳. השתמש בשיקוי כדי לשנות את המצב.';

  @override
  String inventorySold(String amount) {
    return 'נמכר: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'הוסיפו חברים קודם';

  @override
  String get inventoryGiftTitle => 'לתת אוסף במתנה?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'לתת את «$title» ל־$name?';
  }

  @override
  String inventoryGifted(String title) {
    return 'ניתן במתנה: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'לשחקן כבר יש את הפריט הזה';

  @override
  String get inventoryGiftSelf => 'אי אפשר להעניק לעצמך';

  @override
  String get inventoryGiftNotOwned => 'הפריט הזה לא במלאי שלך';

  @override
  String get inventoryLoadFailed => 'לא ניתן לטעון פריטים';

  @override
  String get inventoryNoCollections => 'אין אוספים — קנו בחנות';

  @override
  String get inventoryNoEmojis => 'אין אימוג\'ים — קנו בחנות';

  @override
  String get inventoryNoFrames => 'אין מסגרות — נצחו 10 משחקי ליגה (הישגים)';

  @override
  String get inventoryNoStakes => 'אין הימורים שנרכשו';

  @override
  String inventoryEmojiLeft(int count) {
    return 'נותרו $count';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'הכנסה: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'הכנסה מחר: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'מוכן';

  @override
  String get inventoryIncomeTomorrowLabel => 'מחר';

  @override
  String inventoryStakeGold(String amount) {
    return 'ניתן להמר $amount זהב';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'ניתן להמר $amount כסף';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'התקבל +$amount';
  }

  @override
  String get chatsLoadFailed => 'לא ניתן לטעון צ\'אטים';

  @override
  String get chatsLoadListFailed => 'לא ניתן לטעון את הרשימה';

  @override
  String get chatsBlockedEmpty => 'הרשימה ריקה';

  @override
  String chatsBlockedAt(String date) {
    return 'נחסם: $date';
  }

  @override
  String get chatsCreateFailed => 'לא ניתן ליצור צ\'אט';

  @override
  String get chatsNeedFriendsFirst => 'הוסיפו חברים קודם, ואז תוכלו לפתוח צ\'אט.';

  @override
  String get chatsFriendsNotFound => 'לא נמצאו חברים';

  @override
  String get chatsFindFriendHint => 'מצאו חבר לפי כינוי';

  @override
  String get chatsSelectChat => 'בחרו צ\'אט';

  @override
  String get chatsSelectHint => 'בחרו שיחה מהרשימה משמאל';

  @override
  String get chatEditFailed => 'לא ניתן לערוך את ההודעה';

  @override
  String get chatSendFailed => 'לא ניתן לשלוח את ההודעה';

  @override
  String get chatDeleteFailed => 'לא ניתן למחוק את ההודעה';

  @override
  String get chatEmojiSendFailed => 'לא ניתן לשלוח אימוג\'י';

  @override
  String get chatLoadFailed => 'לא ניתן לטעון הודעות';

  @override
  String get chatBackToGame => 'חזרה למשחק';

  @override
  String get chatBackToChats => 'חזרה לצ\'אטים';

  @override
  String get chatActions => 'פעולות צ\'אט';

  @override
  String get chatAutoTranslate => 'תרגום אוטומטי';

  @override
  String get chatScrollToEnd => 'לסוף השיחה';

  @override
  String chatReplyingTo(String name) {
    return 'תשובה ל־$name';
  }

  @override
  String get chatGift => 'מתנה';

  @override
  String get chatCollection => 'אוסף';

  @override
  String get chatGiftCollection => 'מתנה · אוסף';

  @override
  String get chatThisUser => 'משתמש זה';

  @override
  String get gamesLobbyLoadFailed => 'לא ניתן לטעון את הלובי.';

  @override
  String get gamesTapChangeStake => 'הקישו לשינוי ההימור';

  @override
  String get gamesTapChangeTurnTime => 'הקישו לשינוי זמן מהלך';

  @override
  String get gamesTapChangeGrid => 'הקישו לשינוי גודל הרשת';

  @override
  String get gamesSwapSidesHint => 'O יכול להפוך ל־X אחרי המהלך הראשון';

  @override
  String get gamesNoCenterHint => 'המהלך הראשון לא יכול להיות במרכז';

  @override
  String get lobbyInviteSentShort => 'נשלח';

  @override
  String get lobbySearchShort => 'חיפוש';

  @override
  String get lobbySearchPlayers => 'חיפוש שחקנים';

  @override
  String get lobbyInviteDeclinedShort => 'נדחה';

  @override
  String get lobbyInvitesSentWaiting => 'ההזמנות נשלחו. ממתינים לתשובה.';

  @override
  String get lobbyLinkCopiedHint => 'הדביקו אותו בצ\'אט או בהודעה לחבר';

  @override
  String get lobbyCopyLinkHint => 'העתקת קישור ללוח';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name מזמין אתכם לשחק';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name ניצח';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'הזמן נגמר. $name ניצח';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds שנ׳';
  }

  @override
  String get adminTitle => 'ניהול';

  @override
  String get tournamentsTitle => 'טורנירים';

  @override
  String get profileAgeInvalid => 'הזינו גיל בין 1 ל־111';

  @override
  String get profileSaveFailed => 'לא ניתן לשמור את הפרופיל';

  @override
  String get profileNameHint => 'אותיות לטיניות, ספרות, _ עד 10 תווים';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'מ־1 עד 111';

  @override
  String get profileAboutHint => 'עד 100 תווים (אופציונלי)';

  @override
  String get profileProcessingPhoto => 'מעבד תמונה…';

  @override
  String get profileCropTitle => 'בחרו אזור אווטאר';

  @override
  String get profileCropHint => 'התקרבו והזיזו את התמונה';

  @override
  String get profileApply => 'החלה';

  @override
  String get profilePreparing => 'מכין…';

  @override
  String get profileGalleryTitle => 'תמונות';

  @override
  String get profileGalleryAdd => 'הוספת תמונה';

  @override
  String get profileMakePrimary => 'הגדר כראשית';

  @override
  String get profilePhotoDelete => 'מחק תמונה';

  @override
  String get profilePhotosLimit => 'אפשר להעלות עד 3 תמונות';

  @override
  String get profilePhotosEmpty => 'עדיין אין תמונות';

  @override
  String get profilePhotoUploadFailed => 'לא ניתן להעלות את התמונה';

  @override
  String get profilePhotoDeleteFailed => 'לא ניתן למחוק את התמונה';

  @override
  String get profilePhotoTooLarge => 'התמונה גדולה מדי';

  @override
  String get profileSetPrimaryFailed => 'לא ניתן להגדיר כראשית';

  @override
  String timeSecondsShort(int seconds) {
    return '$seconds שנ׳';
  }

  @override
  String get timeOneMin => '1 דק׳';

  @override
  String get timeTenMin => '10 דק׳';

  @override
  String rulesIntro(String grid) {
    return 'איקס-עיגול על לוח $grid. בתורות; X מתחיל.';
  }

  @override
  String rulesWin(int n) {
    return 'ניצחון: יש לסדר $n ברצף אופקית, אנכית או באלכסון.';
  }

  @override
  String get rulesNoTimeLimit => 'אין מגבלת זמן לכל מהלך.';

  @override
  String rulesTurnTime(String time) {
    return 'זמן למהלך: $time. סיום הזמן הוא הפסד.';
  }

  @override
  String rulesStake(String stake) {
    return 'הימור: $stake. המשחק על מספר מטבעות זה.';
  }

  @override
  String get rulesSwap => 'החלפת צדדים: O יכול להחליף עם X אחרי המהלך הראשון של X.';

  @override
  String get rulesNoCenter => 'איסור מרכז: X לא יכול לשחק במרכז במהלך הראשון.';

  @override
  String get collectionSetLegends => 'אגדות';

  @override
  String get collectionSetSpace => 'חלל';

  @override
  String get collectionSetGems => 'אבני חן';

  @override
  String get collectionSetParty => 'מסיבה';

  @override
  String get collectionSetNature => 'טבע';

  @override
  String get collectionSetAdventures => 'הרפתקאות';

  @override
  String collectionCardMeta(String amount) {
    return 'אוסף · חלון ראווה · מתנה · מכירה · +$amount';
  }

  @override
  String get coinsDayOne => 'יום';

  @override
  String get coinsDayFew => 'ימים';

  @override
  String get coinsDayMany => 'ימים';

  @override
  String get giftFriendTitle => 'מתנה לחבר';

  @override
  String photoCount(int count) {
    return 'תמונה ($count)';
  }

  @override
  String photoCountWithText(int count, String text) {
    return 'תמונה ($count): $text';
  }

  @override
  String photoWithText(String text) {
    return 'תמונה: $text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count אימוג\'ים · $price';
  }

  @override
  String get chatsExpandPanel => 'הרחב לוח';

  @override
  String get chatsCollapsePanel => 'כווץ לוח';

  @override
  String get chatReplySourceMissing => 'ההודעה המקורית לא נמצאה';

  @override
  String shopStakeTitleSilver(int n) {
    return 'הימור $n כסף';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'הימור $n זהב';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'פותח הימור של $n כסף';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'פותח הימור של $n זהב';
  }

  @override
  String get chatReplySelf => 'לעצמך';

  @override
  String get chatReplyPeer => 'לבן השיח';

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
  String get statsTitle => 'סטטיסטיקה';

  @override
  String get statsLoadFailed => 'טעינת הסטטיסטיקה נכשלה';

  @override
  String get statsAllGames => 'כל המשחקים';

  @override
  String get statsEmptyTitle => 'עדיין אין משחקים';

  @override
  String get statsEmptyHint => 'שחקו משחק ראשון כדי לראות כאן סטטיסטיקה.';

  @override
  String get statsWins => 'ניצחונות';

  @override
  String get statsDraws => 'תיקו';

  @override
  String get statsLosses => 'הפסדים';

  @override
  String get statsWinRate => 'אחוז ניצחונות';

  @override
  String get statsTopWon => 'הכי הרבה ניצחונות מול';

  @override
  String get statsTopDrawn => 'הכי הרבה תיקו עם';

  @override
  String get statsTopLost => 'הכי הרבה הפסדים מול';

  @override
  String get statsTimePlayed => 'זמן משחק';

  @override
  String get statsYourScore => 'התוצאה שלך';

  @override
  String get profileShowStats => 'הצג סטטיסטיקה';

  @override
  String get statsDurationZeroMinutes => '0 דק׳';

  @override
  String get gameYouWonOpponentForfeit => 'היריב נכנע. ניצחת!';

  @override
  String get lobbyLeaveTitle => 'לעזוב את הלובי?';

  @override
  String get lobbyLeaveConfirm => 'הלובי יימחק לאחר היציאה. חברים שהוזמנו יקבלו דחייה.';

  @override
  String get lobbyLeave => 'עזוב';

  @override
  String statsDurationHours(int hours) {
    return '$hours שע׳';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours שע׳ $minutes דק׳';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes דק׳';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'נכנעת. $name ניצח';
  }

  @override
  String get supportTitle => 'תמיכה';

  @override
  String get supportUnavailable => 'התמיכה אינה זמינה';

  @override
  String get supportOpenFailed => 'לא ניתן לפתוח את צ\'אט התמיכה';

  @override
  String coinsGrantedTitle(int amount) {
    return 'זוכו לכם $amount מטבעות';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return 'נוכו $amount מטבעות';
  }

  @override
  String get coinsCreditCardTitle => 'זוכו לכם מטבעות';

  @override
  String get coinsClaim => 'לקבל';

  @override
  String get durakActionPass => 'פס';

  @override
  String get durakRoleTook => 'לוקח';

  @override
  String get durakRoleBeats => 'מכסה';

  @override
  String get durakRoleThrowIn => 'תוספת';

  @override
  String get durakRoleTurn => 'תור';

  @override
  String get durakRoleDefends => 'מתגונן';

  @override
  String get durakStatusTaking => 'לוקח';

  @override
  String get durakHintDefenderTurn => 'תור המגן';

  @override
  String get gameYouEliminated => 'הודחת';

  @override
  String gameYouPlaced(int place) {
    return 'סיימת במקום $place';
  }

  @override
  String get gameOverNeutral => 'המשחק נגמר';

  @override
  String gameTurnOf(String name) {
    return 'תור של $name';
  }

  @override
  String get chatGroupTooltip => 'צ\'אט קבוצתי';

  @override
  String get lobbyChatNotReady => 'צ\'אט הלובי עדיין לא מוכן';

  @override
  String get chatsGroupChat => 'צ\'אט קבוצתי';

  @override
  String chatsMembersCount(int count) {
    return 'משתתפים: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count משת\'';
  }

  @override
  String get chatsYouSuffix => '(את/ה)';

  @override
  String get chatTitleDurak3 => 'דוראק · 3 שחקנים';

  @override
  String get chatTitleDurak4 => 'דוראק · 4 שחקנים';

  @override
  String get rulesTttUltimate => 'Ultimate: תשעה לוחות 3×3. מהלך שולח את היריב ללוח הזה. מנצחים עם שורה בלוח העל.';

  @override
  String get rulesTttMulti3 => '3 שחקנים: לוח 3×3, שלושה שחקנים (X, O, △). השלימו שורה בסימנים שלכם כדי לנצח.';

  @override
  String get rulesTttMulti4 => '4 שחקנים: לוח 4×4, ארבעה שחקנים (X, O, △, □). השלימו שורה בסימנים שלכם כדי לנצח.';

  @override
  String get adminUsersTab => 'משתמשים';

  @override
  String get adminSupportTab => 'תמיכה';

  @override
  String get adminSearchHint => 'חיפוש לפי אימייל או כינוי';

  @override
  String get adminRoleAdmins => 'מנהלים';

  @override
  String get adminRoleUsers => 'משתמשים';

  @override
  String get adminRoleAll => 'כל התפקידים';

  @override
  String get adminStatusFrozen => 'מוקפאים';

  @override
  String get adminStatusActive => 'פעילים';

  @override
  String get adminStatusAny => 'כל סטטוס';

  @override
  String get adminOrderDesc => 'יורד';

  @override
  String get adminOrderAsc => 'עולה';

  @override
  String adminLoadFailed(String error) {
    return 'הטעינה נכשלה: $error';
  }

  @override
  String get adminUsersEmpty => 'לא נמצאו משתמשים';

  @override
  String get adminSortLastSeen => 'לפי ביקור אחרון';

  @override
  String get adminSortEmail => 'לפי אימייל';

  @override
  String get adminSortCreated => 'לפי תאריך הרשמה';

  @override
  String adminBronzeBalance(int amount) {
    return '$amount ברונזה';
  }

  @override
  String get adminRevokeAdmin => 'הסר מנהל';

  @override
  String get adminGrantAdmin => 'הפוך למנהל';

  @override
  String get adminAdminRevoked => 'הרשאות מנהל הוסרו';

  @override
  String get adminAdminGranted => 'הרשאות מנהל ניתנו';

  @override
  String get adminGrantCoins => 'הענק מטבעות';

  @override
  String get adminWriteSupport => 'כתוב כתמיכה';

  @override
  String get adminUnfreeze => 'בטל הקפאה';

  @override
  String get adminFreeze => 'הקפא';

  @override
  String get adminUnfrozen => 'ההקפאה בוטלה';

  @override
  String get adminFrozenDone => 'הוקפא';

  @override
  String get adminResetPassword => 'איפוס סיסמה';

  @override
  String get adminCoinsAmountHint => 'כמות (שלילי = חיסור)';

  @override
  String get adminReasonOptional => 'סיבה (לא חובה)';

  @override
  String get adminGrantSent => 'הכרטיס נשלח לצ\'אט התמיכה';

  @override
  String adminCoinsDebited(int amount) {
    return 'הופחתו $amount ברונזה';
  }

  @override
  String get adminGrantVerb => 'הענק';

  @override
  String get adminNewPasswordHint => 'סיסמה חדשה (לפחות 6)';

  @override
  String get adminPasswordReset => 'הסיסמה אופסה';

  @override
  String get adminResetVerb => 'אפס';

  @override
  String adminShortError(String error) {
    return 'שגיאה: $error';
  }

  @override
  String get adminSupportEmpty => 'אין פניות תמיכה';

  @override
  String get adminUserFallback => 'משתמש';

  @override
  String get apiErrTooManyRequests => 'יותר מדי בקשות. נסו שוב מאוחר יותר.';

  @override
  String get apiErrMoveConflict => 'התנגשות מהלך. נסו שוב.';

  @override
  String get shopElixirs => 'Elixirs';

  @override
  String get shopElixirsSubtitle => 'Rejuvenate, age, or speed up collections';

  @override
  String get shopElixirsHelp => 'Three shelves: rejuvenation, aging, and acceleration. Each has six elixirs, one per collection set. An elixir works only on its own set.\n\nRejuvenation makes a collection one step newer, and never newer than new. Aging makes it one step older, and never older than shabby. Acceleration is only for a shabby item: three months left until vintage, once. An elixir never grants vintage by itself.\n\nA bought elixir stays in Items. Use it from the collection card or from the elixir card. Each use spends one.';

  @override
  String get elixirGroupRejuvenate => 'הצערה';

  @override
  String get elixirGroupAge => 'הזדקנות';

  @override
  String get elixirGroupAccelerate => 'האצה';

  @override
  String get elixirEffectRejuvenate => 'הצערה';

  @override
  String get elixirEffectAge => 'הזדקנות';

  @override
  String get elixirEffectAccelerate => 'האצה';

  @override
  String get elixirAdjCelebration => 'חגיגי';

  @override
  String get elixirAdjNature => 'טבעי';

  @override
  String get elixirAdjLegends => 'אגדי';

  @override
  String get elixirAdjCosmic => 'קוסמי';

  @override
  String get elixirAdjAdventure => 'הרפתקה';

  @override
  String get elixirAdjJewels => 'יקר';

  @override
  String elixirName(String adjective, String effect) {
    return 'שיקוי $effect $adjective';
  }

  @override
  String get elixirHelpRejuvenate => 'Makes the collection one step newer. Not newer than new.';

  @override
  String get elixirHelpAge => 'Makes the collection one step older. Not older than shabby.';

  @override
  String get elixirHelpAccelerate => 'Shabby only. Three months left until vintage, once.';

  @override
  String get elixirUseRejuvenate => 'הצעיר';

  @override
  String get elixirUseAge => 'הזדקן';

  @override
  String get elixirUseAccelerate => 'האץ';

  @override
  String get elixirUse => 'השתמש';

  @override
  String collectionLeftDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ימים',
      one: 'יום $count',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count שעות',
      one: 'שעה $count',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count דקות',
      one: 'דקה $count',
    );
    return '$_temp0';
  }

  @override
  String elixirSetOnly(String set) {
    return 'Only the $set set.';
  }

  @override
  String get elixirPickCollection => 'Choose a collection';

  @override
  String get elixirNoTarget => 'No collection in this set can take this elixir';

  @override
  String get elixirApplied => 'Elixir applied';

  @override
  String get elixirConfirmTitle => 'Use this elixir?';

  @override
  String elixirConfirmBody(String elixir, String collection) {
    return '$elixir\n$collection';
  }

  @override
  String get inventoryNoElixirs => 'No elixirs — buy them in the shop';

  @override
  String get elixirNotApplicable => 'This elixir cannot change that collection right now';

  @override
  String get elixirWrongSet => 'This elixir is for another set';

  @override
  String get elixirNotOwned => 'You do not have this elixir';

  @override
  String collectionUntil(String state, String left) {
    return 'Until $state: $left';
  }

  @override
  String get collectionLeftSoon => 'less than a minute';

  @override
  String get collectionCondGenNew => 'new';

  @override
  String get collectionCondGenWorn => 'worn';

  @override
  String get collectionCondGenTired => 'tired';

  @override
  String get collectionCondGenShabby => 'shabby';

  @override
  String get collectionCondGenVintage => 'vintage';
}
