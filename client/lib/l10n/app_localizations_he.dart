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
  String get settingsAddBotsTitle => 'הוספת בוטים אחרי 30 שנ׳';

  @override
  String get settingsAddBotsSubtitle => 'בשידוך: אם לא נמצא יריב תוך 30 שניות, המשחק מתחיל עם בוט (ההימור מתאפס ל־1 ברונזה)';

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
  String get lobbyMatchmake => 'לובי';

  @override
  String get lobbyPrivateGame => 'משחק פרטי';

  @override
  String get lobbySearchingOpponent => 'מחפש יריב…';

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
  String get profileChangePhoto => 'החלפת תמונה';

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
  String get shopSellRefund => 'מכירה מחזירה 80% מהעלות';

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
    return 'זמן למהלך: $time.';
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
}
