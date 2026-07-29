import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get navFriends => 'الأصدقاء';

  @override
  String get navChats => 'المحادثات';

  @override
  String get navGames => 'الألعاب';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageSystem => 'افتراضي النظام';

  @override
  String get settingsAddBotsTitle => 'إضافة بوت بعد 30 ثانية';

  @override
  String get settingsAddBotsSubtitle => 'في البحث عن مباراة: إذا لم يُعثر على منافس خلال 30 ثانية، تبدأ اللعبة مع بوت (تُعاد قيمة الرهان إلى 1 برونز)';

  @override
  String get settingsFriendsOnlyTitle => 'رسائل من الأصدقاء فقط';

  @override
  String get settingsFriendsOnlySubtitle => 'غير الأصدقاء يمكنهم إرسال الرموز التعبيرية فقط. عند الإزعاج، احظر المستخدم مؤقتًا.';

  @override
  String get settingsNotifications => 'الإشعارات';

  @override
  String get settingsPushChat => 'المحادثة';

  @override
  String get settingsPushFriends => 'الأصدقاء';

  @override
  String get settingsPushGames => 'الألعاب';

  @override
  String get settingsPushRewards => 'المكافآت';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginSubtitle => 'أدخل البريد الإلكتروني أو اسم المستخدم وكلمة المرور';

  @override
  String get loginEmailLabel => 'البريد الإلكتروني أو اسم المستخدم';

  @override
  String get loginPasswordLabel => 'كلمة المرور';

  @override
  String get loginSubmit => 'تسجيل الدخول';

  @override
  String get loginNoAccount => 'ليس لديك حساب؟ سجّل الآن';

  @override
  String get loginEmailRequired => 'أدخل البريد الإلكتروني أو اسم المستخدم';

  @override
  String get loginPasswordRequired => 'أدخل كلمة المرور';

  @override
  String get loginTooltip => 'تسجيل الدخول';

  @override
  String get logoutTooltip => 'تسجيل الخروج';

  @override
  String get registerTitle => 'إنشاء حساب';

  @override
  String get registerSubtitle => 'أنشئ حسابًا للعب';

  @override
  String get registerNameLabel => 'الاسم (اسم المستخدم)';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'كلمة المرور';

  @override
  String get registerSubmit => 'إنشاء حساب';

  @override
  String get registerHaveAccount => 'لديك حساب بالفعل؟ سجّل الدخول';

  @override
  String get registerNameRequired => 'أدخل الاسم';

  @override
  String get registerNameNoSpaces => 'لا يمكن أن يحتوي الاسم على مسافات';

  @override
  String get registerNameMax => 'الحد الأقصى 20 حرفًا';

  @override
  String get registerNameHint => 'حتى 20 حرفًا';

  @override
  String get registerEmailRequired => 'أدخل البريد الإلكتروني';

  @override
  String get registerEmailInvalid => 'بريد إلكتروني غير صالح';

  @override
  String get registerPasswordHint => '6 أحرف على الأقل';

  @override
  String get registerPasswordMin => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonEdit => 'تعديل';

  @override
  String get commonReply => 'رد';

  @override
  String get commonSend => 'إرسال';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonLoading => 'جارٍ التحميل…';

  @override
  String get commonError => 'خطأ';

  @override
  String get commonOnline => 'متصل';

  @override
  String get commonOffline => 'غير متصل';

  @override
  String get commonOnlineCap => 'متصل';

  @override
  String get commonUser => 'مستخدم';

  @override
  String get commonPlayer => 'لاعب';

  @override
  String get commonAboutMe => 'نبذة عني';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonAccept => 'قبول';

  @override
  String get commonDecline => 'رفض';

  @override
  String get commonCreating => 'جارٍ الإنشاء…';

  @override
  String get commonSearching => 'جارٍ البحث…';

  @override
  String get commonInsufficientCoins => 'عملات غير كافية';

  @override
  String get commonNotFound => 'غير موجود';

  @override
  String get commonServerErrorShort => 'خطأ في الخادم';

  @override
  String get commonForbidden => 'تم رفض الوصول';

  @override
  String get commonUserBlocked => 'المستخدم محظور';

  @override
  String get commonUserNotFound => 'المستخدم غير موجود';

  @override
  String get commonGenericError => 'حدث خطأ ما. يُرجى المحاولة مرة أخرى.';

  @override
  String get timeJustNow => 'الآن';

  @override
  String get timeYesterday => 'أمس';

  @override
  String timeMinutesAgo(Object count) {
    return 'منذ $count د';
  }

  @override
  String timeHoursAgo(Object count) {
    return 'منذ $count س';
  }

  @override
  String timeDaysAgo(Object count) {
    return 'منذ $count ي';
  }

  @override
  String get timeWeekAgo => 'منذ أسبوع';

  @override
  String timeWeeksAgo(Object count) {
    return 'منذ $count أسابيع';
  }

  @override
  String get timeMonthAgo => 'منذ شهر';

  @override
  String timeMonthsAgo(Object count) {
    return 'منذ $count أشهر';
  }

  @override
  String get timeYearAgo => 'منذ سنة';

  @override
  String timeYearsAgo(Object count) {
    return 'منذ $count سنوات';
  }

  @override
  String get weekdaySun => 'أحد';

  @override
  String get weekdayMon => 'إثن';

  @override
  String get weekdayTue => 'ثلا';

  @override
  String get weekdayWed => 'أرب';

  @override
  String get weekdayThu => 'خمي';

  @override
  String get weekdayFri => 'جمع';

  @override
  String get weekdaySat => 'سبت';

  @override
  String get monthJan => 'ينا';

  @override
  String get monthFeb => 'فبر';

  @override
  String get monthMar => 'مار';

  @override
  String get monthApr => 'أبر';

  @override
  String get monthMay => 'ماي';

  @override
  String get monthJun => 'يون';

  @override
  String get monthJul => 'يول';

  @override
  String get monthAug => 'أغس';

  @override
  String get monthSep => 'سبت';

  @override
  String get monthOct => 'أكت';

  @override
  String get monthNov => 'نوف';

  @override
  String get monthDec => 'ديس';

  @override
  String get homeAchievements => 'الإنجازات';

  @override
  String get homeAchievementsSubtitle => 'نتائج ألعابك';

  @override
  String get homeAchievementsRewards => 'مكافآت متاحة للاستلام';

  @override
  String get homeCoins => 'العملات';

  @override
  String get homeCoinsSubtitle => 'الرصيد والمكافآت';

  @override
  String get homeCoinsDailyReward => 'مكافأة تسجيل الدخول اليومي متاحة';

  @override
  String get homeItems => 'العناصر';

  @override
  String get homeItemsInventory => 'مخزونك';

  @override
  String get homeItemsGifted => 'أرسل لك أحدهم مجموعة';

  @override
  String get homeItemsIncome => 'دخل المجموعة جاهز للاستلام';

  @override
  String get homeShop => 'المتجر';

  @override
  String get homeShopSubtitle => 'رموز تعبيرية، رهانات، مجموعات';

  @override
  String get gamesTitle => 'الألعاب';

  @override
  String get gamesFindMatch => 'ابحث عن لعبة';

  @override
  String get gamesMyTurn => 'دورك';

  @override
  String get gamesWaiting => 'في الانتظار';

  @override
  String get gamesLobbyTab => 'الردهة';

  @override
  String get gamesTicTacToe => 'إكس-أو';

  @override
  String get gamesRules => 'القواعد';

  @override
  String get gamesRulesTitle => 'قواعد اللعبة';

  @override
  String get gamesCreate => 'إنشاء لعبة';

  @override
  String get gamesJoin => 'انضمام';

  @override
  String get gamesOpponentTurn => 'دور المنافس';

  @override
  String get gamesCurrentGame => 'اللعبة الحالية';

  @override
  String get gamesInvitedYou => 'تمت دعوتك';

  @override
  String get gamesTurnTime => 'وقت الدور';

  @override
  String get gamesGridSize => 'حجم اللوحة';

  @override
  String get gamesSwapSides => 'تبديل الجانب';

  @override
  String get gamesNoCenter => 'بدون بداية من الوسط';

  @override
  String get lobbyMatchmake => 'الردهة';

  @override
  String get lobbyPrivateGame => 'لعبة خاصة';

  @override
  String get lobbySearchingOpponent => 'جارٍ البحث عن منافس…';

  @override
  String get lobbyWaitingJoin => 'بانتظار أن يضغط أحد «ابحث عن لعبة» أو «انضمام»';

  @override
  String get lobbyInviteTitle => 'دعوة للعبة';

  @override
  String get lobbyInvitedToPlay => 'تمت دعوتك للعب';

  @override
  String get lobbyEnterGame => 'ادخل اللعبة';

  @override
  String get lobbyInvite => 'دعوة';

  @override
  String get lobbyInviteSent => 'تم إرسال الدعوة';

  @override
  String get lobbyCopyLink => 'مشاركة رابط اللعبة';

  @override
  String get lobbyLinkCopied => 'تم نسخ الرابط';

  @override
  String get lobbyNoFriendsOnline => 'لا يوجد أصدقاء متصلون. شارك رابط اللعبة أعلاه أو انتظر حتى يتصل الأصدقاء.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'المنافس';

  @override
  String get gameYouWon => 'لقد فزت!';

  @override
  String get gameYouWonOpponentLeft => 'لقد فزت — غادر المنافس';

  @override
  String get gameYouWonOpponentTimeout => 'لقد فزت — انتهى وقت المنافس';

  @override
  String get gameDraw => 'تعادل';

  @override
  String get gameExitTitle => 'مغادرة اللعبة';

  @override
  String get gameExitConfirm => 'إذا غادرت، ستخسر. هل تريد المغادرة؟';

  @override
  String get gameStay => 'البقاء';

  @override
  String get gameLeave => 'مغادرة';

  @override
  String get gameConnecting => 'جارٍ الاتصال باللعبة…';

  @override
  String get gameWaitingOpponent => 'بانتظار المنافس';

  @override
  String get gameRematchOffer => 'المنافس يعرض إعادة المباراة';

  @override
  String get gameRematchDeclined => 'رفض المنافس إعادة المباراة';

  @override
  String get gameRematch => 'إعادة المباراة';

  @override
  String get gameOtherOpponent => 'منافس آخر';

  @override
  String get gameSwapSidesAction => 'تبديل الجانب';

  @override
  String get gameWriteMessage => 'اكتب رسالة';

  @override
  String get chatsTitle => 'المحادثات';

  @override
  String get chatsEmpty => 'لا توجد محادثات بعد.\nاضغط الأيقونة أعلى اليمين لاختيار صديق وبدء محادثة.';

  @override
  String get chatsNewChat => 'محادثة جديدة';

  @override
  String get chatsNoMessages => 'لا توجد رسائل';

  @override
  String get chatsClearTitle => 'مسح المحادثة؟';

  @override
  String get chatsClearDesc => 'سيتم حذف المحادثة نهائيًا.';

  @override
  String get chatsClearConfirm => 'مسح';

  @override
  String get chatsBlockTitle => 'حظر هذا المستخدم؟';

  @override
  String get chatsBlockDesc => 'لن تتمكنا من مراسلة بعضكما. ستُحذف المحادثة والصداقة.';

  @override
  String get chatsBlockConfirm => 'حظر';

  @override
  String get chatsBlockedUsers => 'المستخدمون المحظورون';

  @override
  String get chatsUnblock => 'إلغاء الحظر';

  @override
  String get chatDialog => 'محادثة';

  @override
  String get chatEmpty => 'لا توجد رسائل بعد.\nأرسل الأولى.';

  @override
  String get chatMessageHint => 'رسالة';

  @override
  String get chatEmoji => 'رموز تعبيرية';

  @override
  String get chatBuyEmojiHint => 'اشترِ الرموز التعبيرية من المتجر في الشاشة الرئيسية';

  @override
  String get chatEditing => 'جارٍ التعديل';

  @override
  String get chatToday => 'اليوم';

  @override
  String get chatYesterday => 'أمس';

  @override
  String get chatFriendsOnly => 'النص للأصدقاء فقط';

  @override
  String get emojiGroupEmotions => 'مشاعر';

  @override
  String get emojiGroupGame => 'ألعاب';

  @override
  String get emojiGroupFlags => 'أعلام';

  @override
  String get emojiGroupAnimals => 'حيوانات';

  @override
  String get emojiGroupFood => 'طعام';

  @override
  String get emojiGroupTravel => 'سفر';

  @override
  String get emojiGroupParty => 'احتفال';

  @override
  String get emojiGroupObjects => 'أشياء';

  @override
  String get friendsTitle => 'الأصدقاء';

  @override
  String get friendsTabFriends => 'الأصدقاء';

  @override
  String get friendsTabIncoming => 'الواردة';

  @override
  String get friendsTabOutgoing => 'الصادرة';

  @override
  String get friendsAdd => 'إضافة صديق';

  @override
  String get friendsRequestSent => 'تم إرسال الطلب';

  @override
  String get friendsFindTab => 'البحث عن صديق';

  @override
  String get friendsSearchHint => 'البحث باسم المستخدم';

  @override
  String get friendsSearchPrompt => 'استخدم البحث للعثور على أصدقاء جدد';

  @override
  String get friendsNothingFound => 'لم يُعثر على شيء';

  @override
  String get friendsEmpty => 'ليس لديك أصدقاء بعد';

  @override
  String get friendsNoIncoming => 'لا توجد طلبات واردة';

  @override
  String get friendsNoOutgoing => 'لا توجد طلبات صادرة';

  @override
  String get friendsAlreadyFriends => 'أنتما صديقان بالفعل';

  @override
  String get friendsRemoveTitle => 'إزالة من الأصدقاء؟';

  @override
  String get friendsRemoved => 'تمت الإزالة من الأصدقاء';

  @override
  String get friendsRequestAccepted => 'تم قبول الطلب';

  @override
  String get friendsRequestDeclined => 'تم رفض الطلب';

  @override
  String get friendsRequestCancelled => 'تم إلغاء الطلب';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get profileSignInPrompt => 'سجّل الدخول إلى حسابك';

  @override
  String get profileSignInHint => 'لإعداد ملفك الشخصي';

  @override
  String get profileEdit => 'تعديل';

  @override
  String get profileCollections => 'المجموعات';

  @override
  String get profileAge => 'العمر';

  @override
  String get profileGender => 'الجنس';

  @override
  String get profileGenderUnset => 'غير محدد';

  @override
  String get profileGenderMale => 'ذكر';

  @override
  String get profileGenderFemale => 'أنثى';

  @override
  String get profileAvatar => 'الصورة الرمزية';

  @override
  String get profileUploadPhoto => 'رفع صورة';

  @override
  String get profileChangePhoto => 'تغيير الصورة';

  @override
  String get shopTitle => 'المتجر';

  @override
  String get shopEmojis => 'رموز تعبيرية';

  @override
  String get shopEmojisSubtitle => 'رموز تعبيرية متحركة للمحادثة';

  @override
  String get shopCollections => 'المجموعات';

  @override
  String get shopCollectionsSubtitle => 'عرض الملف، الهدايا والدخل';

  @override
  String get shopStakes => 'الرهانات';

  @override
  String get shopStakesSubtitle => 'فتح رهانات الفضة';

  @override
  String get inventoryTitle => 'العناصر';

  @override
  String get inventoryEmpty => 'لا شيء هنا بعد — تصفّح المتجر';

  @override
  String get inventoryFrames => 'إطارات';

  @override
  String get inventoryClaim => 'استلام';

  @override
  String get inventorySell => 'بيع';

  @override
  String get inventoryGift => 'إهداء';

  @override
  String get messageEdited => 'معدّلة';

  @override
  String get messageDeleted => 'تم حذف الرسالة';

  @override
  String get photo => 'صورة';

  @override
  String get camera => 'الكاميرا';

  @override
  String get gallery => 'المعرض';

  @override
  String get connectionError => 'تعذّر الاتصال بالخادم.';

  @override
  String get serverError => 'خطأ في الخادم. يُرجى المحاولة لاحقًا.';

  @override
  String get sessionExpired => 'انتهت الجلسة. يُرجى تسجيل الدخول مجددًا.';

  @override
  String get errNoInternet => 'لا يوجد اتصال بالإنترنت.';

  @override
  String get errTimeout => 'انتهت مهلة الطلب. يُرجى المحاولة مرة أخرى.';

  @override
  String get errGamesUnavailable => 'الألعاب غير متاحة مؤقتًا';

  @override
  String get errSettingsSaveFailed => 'تعذّر حفظ الإعداد';

  @override
  String get errPushPermission => 'اسمح بالإشعارات في المتصفح أو إعدادات النظام.';
}
