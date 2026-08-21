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
  String get settingsOfflineModeTitle => 'وضع الشبكة';

  @override
  String get settingsOfflineModeSubtitle => 'غير متصل: العب فورًا ضد بوت، بدون رهانات أو مكافآت، وبدون دردشات أو أصدقاء. تُحفظ المشتريات وتُطبَّق في وضع الاتصال. متصل — عند وجود إنترنت أو حسب إعداد المستخدم.';

  @override
  String get settingsModeOnline => 'متصل';

  @override
  String get settingsModeOffline => 'غير متصل';

  @override
  String get gamesAlternateStartsHint => 'بالتناوب من يبدأ الجولة';

  @override
  String get rulesAlternateStarts => 'من يبدأ بالتناوب من جولة إلى أخرى.';

  @override
  String get offlineBadgeTooltip => 'وضع عدم الاتصال';

  @override
  String get offlineModePopupTitle => 'وضع عدم الاتصال';

  @override
  String get offlineModePopupBody => 'وضع عدم الاتصال مفعّل. العب ضد بوت بدون رهانات أو مكافآت. الدردشات والأصدقاء والردهة مخفية. تُطبَّق المشتريات في وضع الاتصال.';

  @override
  String get offlineModePopupSettings => 'الإعدادات';

  @override
  String get gamesPlay => 'العب';

  @override
  String get offlineGameTitle => 'لعبة ضد بوت';

  @override
  String get offlineGameHint => 'بدون رهانات أو مكافآت · غير متصل فقط';

  @override
  String get offlineBotWon => 'فاز البوت';

  @override
  String get offlineBotThinking => 'البوت يفكر…';

  @override
  String get offlinePlayAgain => 'مرة أخرى';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'خذ';

  @override
  String get durakActionAll => 'الكل';

  @override
  String get durakActionDone => 'تم';

  @override
  String get durakActionBito => 'Beat';

  @override
  String get durakHintDefend => 'دافع';

  @override
  String get durakHintDefendOrTransfer => 'دافع أو انقل';

  @override
  String get durakHintOpponentDefends => 'الخصم يدافع';

  @override
  String get durakHintThrowInFirst => 'أضف أوراقًا (بحد أقصى 5 في أول تغطية)';

  @override
  String get durakHintThrowIn => 'أضف أوراقًا أو انتظر الدفاع';

  @override
  String get durakHintOpponentThrows => 'الخصم يضيف';

  @override
  String get durakHintTakeFollow => 'أضف بعد الأخذ أو اضغط «تم»';

  @override
  String get durakHintOpponentTakeFollow => 'قد يضيف الخصم بعد الأخذ';

  @override
  String get durakHintBito => 'ألقِ ورقة أو قل «بيتو»';

  @override
  String get durakHintOpponentBito => 'الخصم يضيف أو يقول «بيتو»';

  @override
  String get durakHintYourAttack => 'دورك — اهاجم';

  @override
  String get durakHintOpponentAttack => 'الخصم يهاجم';

  @override
  String get durakHintYouLost => 'لقد خسرت — أنت الأحمق';

  @override
  String get durakHintDrawAllOut => 'تعادل — خرج الجميع';

  @override
  String get durakHintYouFinished => 'خرجت — في انتظار النهاية';

  @override
  String get durakFirstLeadYou => 'أنت تبدأ';

  @override
  String get durakFirstLeadOpponent => 'الخصم يبدأ';

  @override
  String get durakFirstLeadBot => 'البوت يبدأ';

  @override
  String durakFirstLeadOf(String name) {
    return 'يبدأ $name';
  }

  @override
  String get durakFirstLeadReason => 'أدنى ورقة رابحة';

  @override
  String get shopPurchaseQueued => 'تم حفظ الشراء — سيُطبَّق في وضع الاتصال';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — تم تطبيق الشراء';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — لم يُطبَّق الشراء: $reason';
  }

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
  String settingsAppVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get appUpdateTitle => 'يتوفر تحديث';

  @override
  String get appUpdateBody => 'يتوفر إصدار جديد من التطبيق. يرجى التحديث للمتابعة.';

  @override
  String get appUpdateWhatsNew => 'ما الجديد';

  @override
  String get appUpdateOk => 'تحديث';

  @override
  String get appUpdateLaterBanner => 'سنحدّث التطبيق بعد هذه اللعبة';

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
  String timeMinutesAgo(int count) {
    return 'منذ $count د';
  }

  @override
  String timeHoursAgo(int count) {
    return 'منذ $count س';
  }

  @override
  String timeDaysAgo(int count) {
    return 'منذ $count ي';
  }

  @override
  String get timeWeekAgo => 'منذ أسبوع';

  @override
  String timeWeeksAgo(int count) {
    return 'منذ $count أسابيع';
  }

  @override
  String get timeMonthAgo => 'منذ شهر';

  @override
  String timeMonthsAgo(int count) {
    return 'منذ $count أشهر';
  }

  @override
  String get timeYearAgo => 'منذ سنة';

  @override
  String timeYearsAgo(int count) {
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
  String get gamesDurak => 'دوراك';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => 'تدوير';

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
  String get gamesPoker => 'بوكر';

  @override
  String get gamesUno => 'أونو';

  @override
  String rulesUnoPlayers(int players) {
    return 'اللاعبون: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'اللعب ضد روبوت بدون حد زمني للدور.';

  @override
  String get rulesUnoIntro => 'يوزَّع على كل لاعب 7 بطاقات. العب بطاقة من نفس اللون أو نفس القيمة (رقم أو نفس الإجراء).';

  @override
  String get rulesUnoPlay => 'التخطي — يفقد التالي دوره. عكس الاتجاه مع لاعبين يعمل كتخطي. تُكدَّس +2 على +2 فقط و+4 على +4 فقط: تتراكم العقوبة (بطاقتا +2 تجعل التالي يسحب 4). لا يجوز وضع +2 على +4. من لا يرد يسحب الكومة كلها ويفقد دوره.';

  @override
  String get rulesUnoWild => 'البطاقة السوداء تختار لونًا جديدًا. العب +4 فقط إن لم تكن لديك بطاقة باللون الحالي. يمكن للخصم الاعتراض: إن كان +4 قانونيًا يسحب 6؛ وإلا يسحب لاعب +4 أربعًا ويلعب المعترض.';

  @override
  String get rulesUnoDraw => 'إن لم توجد بطاقة صالحة فاسحب واحدة من الرزمة. إن ناسبت يمكنك لعبها فورًا أو الاحتفاظ بها وتمرير الدور. لا تسحب طالما لديك حركة قانونية.';

  @override
  String get rulesUnoWin => 'اثنان حتى 100 نقطة، و3+ حتى 300. وتُربَح الجولة بتفريغ اليد.';

  @override
  String get rulesUnoCall => 'عند بقاء بطاقة واحدة اضغط «أونو!». حتى الإجراء التالي يمكن للخصم أن يمسكك بلا أونو — فتسحب بطاقتين.';

  @override
  String get rulesUnoScoring => 'من يفرّغ يده أولًا يفوز بالجولة ويحصل على نقاط بطاقات الخصوم: الأرقام بقيمتها، الإجراءات 20، السوداء 50. اثنان حتى 100، و3+ حتى 300.';

  @override
  String get unoColorRed => 'أحمر';

  @override
  String get unoColorYellow => 'أصفر';

  @override
  String get unoColorGreen => 'أخضر';

  @override
  String get unoColorBlue => 'أزرق';

  @override
  String get unoDraw => 'اسحب';

  @override
  String get unoKeep => 'احتفظ';

  @override
  String get unoSayUno => 'أونو!';

  @override
  String get unoChallengeUno => 'تحدي أونو';

  @override
  String get unoChallengeWd4 => 'تحدي +4';

  @override
  String get unoChooseColor => 'اختر لونًا';

  @override
  String get unoDrawPile => 'كومة السحب';

  @override
  String get unoDiscardPile => 'كومة الرمي';

  @override
  String unoCardsCount(int count) {
    return 'البطاقات: $count';
  }

  @override
  String unoScore(int score) {
    return 'النقاط: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'الجولة $round · حتى $target';
  }

  @override
  String get unoYourTurn => 'دورك';

  @override
  String get unoWaitingTurn => 'دور الخصم';

  @override
  String get unoChooseColorHint => 'اختر لونًا للبطاقة السوداء';

  @override
  String get unoWd4Hint => 'اسحب 4 بطاقات أو تحدَّ Wild +4';

  @override
  String get unoDrawnHint => 'العب البطاقة المسحوبة أو احتفظ بها';

  @override
  String get unoPlayHint => 'العب لونًا أو قيمة مطابقة';

  @override
  String get unoDrawHint => 'لا توجد بطاقة مطابقة — اسحب من الكومة';

  @override
  String unoPendingDraw(int count) {
    return '+$count بطاقات';
  }

  @override
  String get unoYouWon => 'فزت بالمباراة!';

  @override
  String get unoYouLost => 'انتهت المباراة';

  @override
  String unoWinner(String name) {
    return 'الفائز: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name يفوز بالجولة';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'التالي';

  @override
  String get unoRoundScoresTitle => 'نقاط الجولة';

  @override
  String get unoDirectionClockwise => 'مع عقارب الساعة';

  @override
  String get unoDirectionCounterclockwise => 'عكس عقارب الساعة';

  @override
  String get gamesInDevelopment => 'قيد التطوير';

  @override
  String rulesPokerPlayers(int players) {
    return 'اللاعبون: $players.';
  }

  @override
  String get rulesPokerIntro => 'تكساس هولدم. يحصل كل لاعب على ورقتين خاصتين؛ وتُوضع 5 أوراق مشتركة على الطاولة.';

  @override
  String get rulesPokerPlay => 'جولات المراهنة: ما قبل الفلوب، الفلوب، الترن والريفر. يمكنك الطي أو المعادلة أو الرهان أو الرفع.';

  @override
  String get rulesPokerWin => 'يفوز أفضل خمسة أوراق (خاصة + مشتركة) أو آخر لاعب يتبقى بعد الطي.';

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
  String get rulesPokerTable => 'The table plays until one player holds all the chips. Blinds rise every two dealer orbits; 3-max lasts 10 hands, heads-up lasts six orbits.';

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
  String get gamesObservation => 'مشاهدة';

  @override
  String get gamesObservationHint => 'يمكنك المشاهدة حتى نهاية اللعبة';

  @override
  String get gamesFinishCurrentFirst => 'أنهِ لعبتك الحالية أولاً';

  @override
  String get gamesVariantClassic => 'كلاسيكي';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 لاعبين';

  @override
  String get gamesVariantMulti4 => '4 لاعبين';

  @override
  String get gamesDurakModePodkidnoi => 'إضافة';

  @override
  String get gamesDurakModePerevodnoi => 'نقل';

  @override
  String get gamesDurakDeck24 => '24 ورقة';

  @override
  String get gamesDurakDeck36 => '36 ورقة';

  @override
  String get gamesDurakDeck52 => '52 ورقة';

  @override
  String rulesDurakMode(String mode) {
    return 'الوضع: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'اللاعبون: $players. المجموعة: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'العب ضد بوت بلا رهانات ولا مهلة زمنية.';

  @override
  String get rulesDurakAttack => 'المهاجم يلعب أوراقًا؛ والمدافع يرد (نفس النوع أعلى، أو ورقة رابحة). الورقة الرابحة تُرد فقط برابحة أعلى.';

  @override
  String get rulesDurakBeat => 'عندما تُرد كل الأوراق يقول المهاجم «بيتو» وتذهب إلى المهمل. وإلا يأخذ المدافع كل ما على الطاولة.';

  @override
  String get rulesDurakLoser => 'الخاسر من تبقى معه أوراق في النهاية — «الأحمق».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'اللاعبون $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Lobby $name';
  }

  @override
  String get lobbyMatchmake => 'الردهة';

  @override
  String get lobbyPrivateGame => 'لعبة خاصة';

  @override
  String get lobbySearchingOpponent => 'جارٍ البحث عن منافس…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'يبحثون عن هذه اللعبة: $count';
  }

  @override
  String get lobbyWaitingJoin => 'بانتظار أن يضغط أحد «ابحث عن لعبة» أو «انضمام»';

  @override
  String get lobbyInviteTitle => 'دعوة للعبة';

  @override
  String get lobbyInvitedToPlay => 'تمت دعوتك للعب';

  @override
  String get lobbyEnterGame => 'ادخل اللعبة';

  @override
  String get lobbyGone => 'الردهة لم تعد متاحة';

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
  String get gameYouLost => 'لقد خسرت';

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
  String get gameSurrender => 'استسلام';

  @override
  String get gameSurrenderTitle => 'استسلام؟';

  @override
  String get gameSurrenderConfirm => 'ستخسر الجولة وعملات الرهان.';

  @override
  String get gameOfferDraw => 'عرض التعادل';

  @override
  String get gameOfferDrawTitle => 'عرض التعادل؟';

  @override
  String get gameOfferDrawConfirm => 'يمكن لخصمك قبول التعادل أو رفضه.';

  @override
  String get gameAcceptDrawTitle => 'قبول التعادل؟';

  @override
  String get gameAcceptDrawConfirm => 'ستنتهي الجولة بالتعادل.';

  @override
  String get gameDrawOffered => 'الخصم يعرض التعادل';

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
  String get chatPaste => 'لصق';

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
  String get profileChangePhoto => 'تغيير الصورة الرمزية';

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
  String get shopStakesSubtitle => 'فتح رهانات أعلى';

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

  @override
  String get balanceTitle => 'الرصيد';

  @override
  String get coinBronze => 'برونز';

  @override
  String get coinSilver => 'فضة';

  @override
  String get coinGold => 'ذهب';

  @override
  String get coinDiamond => 'ألماس';

  @override
  String get balanceZeroBronze => '0 برونز';

  @override
  String balanceBronzes(int count) {
    return '$count برونز';
  }

  @override
  String balanceSilvers(int count) {
    return '$count فضة';
  }

  @override
  String balanceGolds(int count) {
    return '$count ذهب';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count ألماس';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/يوم';
  }

  @override
  String get balanceAbbrBronze => 'بر';

  @override
  String get balanceAbbrSilver => 'ف.';

  @override
  String get balanceAbbrGold => 'ذ.';

  @override
  String get commonBackHome => 'العودة إلى الرئيسية';

  @override
  String get commonCopied => 'تم النسخ';

  @override
  String get commonClear => 'مسح';

  @override
  String get commonTryLater => 'حاول مرة أخرى لاحقًا.';

  @override
  String get commonTryRefresh => 'جرّب تحديث الصفحة.';

  @override
  String get coinsTitle => 'العملات';

  @override
  String get coinsLoginReward => 'مكافأة تسجيل الدخول';

  @override
  String get coinsLoginAvailableToday => 'مكافأة اليوم متاحة';

  @override
  String get coinsLoginStreak => 'سلسلة تسجيل الدخول اليومية';

  @override
  String get coinsFriendReward => 'مكافأة الصديق';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount للتسجيل عبر رابطك';
  }

  @override
  String get coinsLoadRewardsFailed => 'تعذر تحميل المكافآت';

  @override
  String get coinsClaimReward => 'استلام المكافأة';

  @override
  String get coinsAlreadyClaimed => 'تم الاستلام مسبقًا';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · اليوم';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · يوم واحد متبقٍ';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · متبقٍ $remaining';
  }

  @override
  String get coinsInviteFriend => 'ادعُ صديقًا';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount لكل من يسجّل عبر رابطك';
  }

  @override
  String get coinsCopyLink => 'نسخ الرابط';

  @override
  String get coinsHowItWorks => 'كيف يعمل';

  @override
  String get coinsHowStep1 => 'انسخ الرابط وأرسله إلى صديق';

  @override
  String get coinsHowStep2 => 'يسجّل الصديق عبر هذا الرابط';

  @override
  String coinsHowStep3(String amount) {
    return 'تحصل على $amount';
  }

  @override
  String get achievementsTitle => 'الإنجازات';

  @override
  String achievementsProgress(String progress) {
    return 'التقدم: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'تم الحصول على الإطار';

  @override
  String get achievementsClaimed => 'تم الحصول عليه';

  @override
  String get achievementsOpenFrame => 'فتح الإطار';

  @override
  String friendsRemoveConfirm(String name) {
    return 'هل أنت متأكد أنك تريد إزالة $name من الأصدقاء؟';
  }

  @override
  String get friendsRemoveConfirmAction => 'إزالة';

  @override
  String get friendsRemove => 'إزالة من الأصدقاء';

  @override
  String get friendsAcceptRequest => 'قبول الطلب';

  @override
  String get friendsDeclineRequest => 'رفض الطلب';

  @override
  String get friendsCancelRequest => 'إلغاء الطلب';

  @override
  String get friendsSendRequest => 'إرسال طلب صداقة';

  @override
  String get friendsRequestAlreadySent => 'تم إرسال الطلب مسبقًا';

  @override
  String get friendsIncomingStatus => 'طلب وارد';

  @override
  String get friendsOutgoingStatus => 'طلب صادر';

  @override
  String get friendsNotFriends => 'ليسا صديقين';

  @override
  String get friendsCollapseSearch => 'طي البحث';

  @override
  String get friendsExpandSearch => 'إظهار البحث';

  @override
  String get friendsLoadFailed => 'تعذر تحميل الأصدقاء';

  @override
  String friendsSince(String date) {
    return 'أصدقاء منذ: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'طلب وارد: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'طلب صادر: $date';
  }

  @override
  String get userInfoTitle => 'معلومات المستخدم';

  @override
  String profileAgeYears(int age) {
    return '$age سنة';
  }

  @override
  String get shopBuy => 'شراء';

  @override
  String get shopBuyTitle => 'شراء؟';

  @override
  String get shopBuyStakeTitle => 'شراء الرهان؟';

  @override
  String get shopBuyEmojiTitle => 'شراء الرمز التعبيري؟';

  @override
  String get shopBuyCollectionTitle => 'شراء المجموعة؟';

  @override
  String shopPrice(String price) {
    return 'السعر: $price';
  }

  @override
  String get shopOwned => 'تم الشراء';

  @override
  String get shopEmpty => 'فارغ حتى الآن';

  @override
  String shopPurchased(String title) {
    return 'تم شراء $title';
  }

  @override
  String get shopEmojiUses => 'تحصل على: 10 استخدامات';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 استخدامات';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 استخدامات';
  }

  @override
  String get shopBuyTen => 'شراء · 10 قطع';

  @override
  String shopDailyIncome(String amount) {
    return 'الدخل: $amount';
  }

  @override
  String get shopBuyOnce => 'شراء لمرة واحدة';

  @override
  String get shopSellRefund => 'البيع يعيد 80% من التكلفة';

  @override
  String shopCollectionAdded(String title) {
    return 'أُضيف $title إلى الملف الشخصي';
  }

  @override
  String shopSetBonus(int percent) {
    return 'مكافأة المجموعة +$percent%';
  }

  @override
  String get shopSetComplete => 'مكتمل';

  @override
  String shopSetProgress(int owned, int total) {
    return 'مجموع · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'بيع؟';

  @override
  String inventorySellDesc(String amount) {
    return 'ستحصل على $amount';
  }

  @override
  String inventorySold(String amount) {
    return 'تم البيع: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'أضف أصدقاء أولًا';

  @override
  String get inventoryGiftTitle => 'إهداء المجموعة؟';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'إهداء «$title» إلى $name؟';
  }

  @override
  String inventoryGifted(String title) {
    return 'تم الإهداء: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'اللاعب يمتلك هذا العنصر بالفعل';

  @override
  String get inventoryGiftSelf => 'لا يمكنك إهداء نفسك';

  @override
  String get inventoryGiftNotOwned => 'هذا العنصر ليس في مخزونك';

  @override
  String get inventoryLoadFailed => 'تعذر تحميل العناصر';

  @override
  String get inventoryNoCollections => 'لا توجد مجموعات — اشترِ من المتجر';

  @override
  String get inventoryNoEmojis => 'لا توجد رموز تعبيرية — اشترِ من المتجر';

  @override
  String get inventoryNoFrames => 'لا توجد إطارات — اربح 10 مباريات دوري (إنجازات)';

  @override
  String get inventoryNoStakes => 'لا رهانات مشتراة';

  @override
  String inventoryEmojiLeft(int count) {
    return 'متبقٍ $count';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'الدخل: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'دخل الغد: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'جاهز';

  @override
  String get inventoryIncomeTomorrowLabel => 'غدًا';

  @override
  String inventoryStakeGold(String amount) {
    return 'يمكنك المراهنة بـ $amount ذهب';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'يمكنك المراهنة بـ $amount فضة';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'تم الاستلام +$amount';
  }

  @override
  String get chatsLoadFailed => 'تعذر تحميل المحادثات';

  @override
  String get chatsLoadListFailed => 'تعذر تحميل القائمة';

  @override
  String get chatsBlockedEmpty => 'القائمة فارغة';

  @override
  String chatsBlockedAt(String date) {
    return 'محظور: $date';
  }

  @override
  String get chatsCreateFailed => 'تعذر إنشاء المحادثة';

  @override
  String get chatsNeedFriendsFirst => 'أضف أصدقاء أولًا، ثم يمكنك فتح محادثة.';

  @override
  String get chatsFriendsNotFound => 'لم يُعثر على أصدقاء';

  @override
  String get chatsFindFriendHint => 'ابحث عن صديق بالاسم المستعار';

  @override
  String get chatsSelectChat => 'اختر محادثة';

  @override
  String get chatsSelectHint => 'اختر حوارًا من القائمة على اليسار';

  @override
  String get chatEditFailed => 'تعذر تعديل الرسالة';

  @override
  String get chatSendFailed => 'تعذر إرسال الرسالة';

  @override
  String get chatDeleteFailed => 'تعذر حذف الرسالة';

  @override
  String get chatEmojiSendFailed => 'تعذر إرسال الرمز التعبيري';

  @override
  String get chatLoadFailed => 'تعذر تحميل الرسائل';

  @override
  String get chatBackToGame => 'العودة إلى اللعبة';

  @override
  String get chatBackToChats => 'العودة إلى المحادثات';

  @override
  String get chatActions => 'إجراءات المحادثة';

  @override
  String get chatAutoTranslate => 'ترجمة تلقائية';

  @override
  String get chatScrollToEnd => 'إلى نهاية المحادثة';

  @override
  String chatReplyingTo(String name) {
    return 'رد على $name';
  }

  @override
  String get chatGift => 'هدية';

  @override
  String get chatCollection => 'مجموعة';

  @override
  String get chatGiftCollection => 'هدية · مجموعة';

  @override
  String get chatThisUser => 'هذا المستخدم';

  @override
  String get gamesLobbyLoadFailed => 'تعذر تحميل اللوبي.';

  @override
  String get gamesTapChangeStake => 'اضغط لتغيير الرهان';

  @override
  String get gamesTapChangeTurnTime => 'اضغط لتغيير وقت الدور';

  @override
  String get gamesTapChangeGrid => 'اضغط لتغيير حجم الشبكة';

  @override
  String get gamesSwapSidesHint => 'قد يصبح O حرف X بعد الحركة الأولى';

  @override
  String get gamesNoCenterHint => 'الحركة الأولى لا يمكن أن تكون في الوسط';

  @override
  String get lobbyInviteSentShort => 'تم الإرسال';

  @override
  String get lobbyInvitesSentWaiting => 'تم إرسال الدعوات. بانتظار الرد.';

  @override
  String get lobbyLinkCopiedHint => 'الصقه في محادثة أو رسالة لصديق';

  @override
  String get lobbyCopyLinkHint => 'نسخ الرابط إلى الحافظة';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name يدعوك للعب';
  }

  @override
  String gameOpponentWon(String name) {
    return 'فاز $name';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'انتهى الوقت. فاز $name';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds ث';
  }

  @override
  String get adminTitle => 'الإدارة';

  @override
  String get tournamentsTitle => 'البطولات';

  @override
  String get profileAgeInvalid => 'أدخل عمرًا من 1 إلى 111';

  @override
  String get profileSaveFailed => 'تعذر حفظ الملف الشخصي';

  @override
  String get profileNameHint => 'حروف لاتينية وأرقام و_ حتى 10 أحرف';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'من 1 إلى 111';

  @override
  String get profileAboutHint => 'حتى 100 حرف (اختياري)';

  @override
  String get profileProcessingPhoto => 'جاري معالجة الصورة…';

  @override
  String get profileCropTitle => 'اختر منطقة الصورة الرمزية';

  @override
  String get profileCropHint => 'كبّر وحرّك الصورة';

  @override
  String get profileApply => 'تطبيق';

  @override
  String get profilePreparing => 'جاري التحضير…';

  @override
  String get profileGalleryTitle => 'الصور';

  @override
  String get profileGalleryAdd => 'إضافة صورة';

  @override
  String get profileMakePrimary => 'تعيين كصورة رئيسية';

  @override
  String get profilePhotoDelete => 'حذف الصورة';

  @override
  String get profilePhotosLimit => 'يمكنك رفع 3 صور كحد أقصى';

  @override
  String get profilePhotosEmpty => 'لا توجد صور بعد';

  @override
  String get profilePhotoUploadFailed => 'تعذر رفع الصورة';

  @override
  String get profilePhotoDeleteFailed => 'تعذر حذف الصورة';

  @override
  String get profilePhotoTooLarge => 'الصورة كبيرة جداً';

  @override
  String get profileSetPrimaryFailed => 'تعذر تعيينها كصورة رئيسية';

  @override
  String timeSecondsShort(int seconds) {
    return '$seconds ث';
  }

  @override
  String get timeOneMin => '1 د';

  @override
  String get timeTenMin => '10 د';

  @override
  String rulesIntro(String grid) {
    return 'إكس-أو على لوحة $grid. بالتناوب، ويبدأ X.';
  }

  @override
  String rulesWin(int n) {
    return 'الفوز: صفّ $n أفقياً أو عمودياً أو قطرياً.';
  }

  @override
  String get rulesNoTimeLimit => 'لا يوجد حد زمني لكل نقلة.';

  @override
  String rulesTurnTime(String time) {
    return 'وقت النقلة: $time.';
  }

  @override
  String rulesStake(String stake) {
    return 'الرهان: $stake. اللعبة بهذا العدد من العملات.';
  }

  @override
  String get rulesSwap => 'تبديل الجوانب: يمكن لـ O التبادل مع X بعد أول نقلة لـ X.';

  @override
  String get rulesNoCenter => 'منع الوسط: لا يمكن لـ X اللعب في الوسط في النقلة الأولى.';

  @override
  String get collectionSetLegends => 'أساطير';

  @override
  String get collectionSetSpace => 'الفضاء';

  @override
  String get collectionSetGems => 'جواهر';

  @override
  String get collectionSetParty => 'احتفال';

  @override
  String get collectionSetNature => 'الطبيعة';

  @override
  String get collectionSetAdventures => 'مغامرات';

  @override
  String collectionCardMeta(String amount) {
    return 'مجموعة · واجهة · هدية · بيع · +$amount';
  }

  @override
  String get coinsDayOne => 'يوم';

  @override
  String get coinsDayFew => 'أيام';

  @override
  String get coinsDayMany => 'أيام';

  @override
  String get giftFriendTitle => 'أهدِ صديقاً';

  @override
  String photoCount(int count) {
    return 'صورة ($count)';
  }

  @override
  String photoCountWithText(int count, String text) {
    return 'صورة ($count): $text';
  }

  @override
  String photoWithText(String text) {
    return 'صورة: $text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count رموز · $price';
  }

  @override
  String get chatsExpandPanel => 'توسيع اللوحة';

  @override
  String get chatsCollapsePanel => 'طي اللوحة';

  @override
  String get chatReplySourceMissing => 'لم يتم العثور على الرسالة الأصلية';

  @override
  String shopStakeTitleSilver(int n) {
    return 'رهان $n فضة';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'رهان $n ذهب';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'يفتح الرهان بـ $n فضة';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'يفتح الرهان بـ $n ذهب';
  }

  @override
  String get chatReplySelf => 'لنفسك';

  @override
  String get chatReplyPeer => 'للمحاور';

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
  String get statsTitle => 'الإحصائيات';

  @override
  String get statsLoadFailed => 'تعذر تحميل الإحصائيات';

  @override
  String get statsAllGames => 'كل الألعاب';

  @override
  String get statsEmptyTitle => 'لا توجد مباريات بعد';

  @override
  String get statsEmptyHint => 'العب لعبتك الأولى لترى الإحصائيات هنا.';

  @override
  String get statsWins => 'انتصارات';

  @override
  String get statsDraws => 'تعادل';

  @override
  String get statsLosses => 'هزائم';

  @override
  String get statsWinRate => 'نسبة الفوز';

  @override
  String get statsTopWon => 'أكثر الانتصارات ضد';

  @override
  String get statsTopDrawn => 'أكثر التعادلات مع';

  @override
  String get statsTopLost => 'أكثر الهزائم أمام';

  @override
  String get statsTimePlayed => 'وقت اللعب';

  @override
  String get statsYourScore => 'نتيجتك';

  @override
  String get profileShowStats => 'إظهار الإحصائيات';

  @override
  String get statsDurationZeroMinutes => '0 د';

  @override
  String get gameYouWonOpponentForfeit => 'استسلم الخصم. لقد فزت!';

  @override
  String get lobbyLeaveTitle => 'مغادرة الردهة؟';

  @override
  String get lobbyLeaveConfirm => 'سيتم حذف الردهة بعد المغادرة. سيتلقى الأصدقاء المدعوون رفضًا.';

  @override
  String get lobbyLeave => 'مغادرة';

  @override
  String statsDurationHours(int hours) {
    return '$hours س';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes د';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'استسلمت. فاز $name';
  }

  @override
  String get supportTitle => 'الدعم';

  @override
  String get supportUnavailable => 'الدعم غير متاح';

  @override
  String get supportOpenFailed => 'تعذر فتح محادثة الدعم';

  @override
  String coinsGrantedTitle(int amount) {
    return 'تم إضافة $amount عملة إلى رصيدك';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return 'تم خصم $amount عملة';
  }

  @override
  String get coinsCreditCardTitle => 'تم إضافة عملات إلى رصيدك';

  @override
  String get coinsClaim => 'استلام';

  @override
  String get durakActionPass => 'تمرير';

  @override
  String get durakRoleTook => 'أخذ';

  @override
  String get durakRoleBeats => 'يرد';

  @override
  String get durakRoleThrowIn => 'إضافة';

  @override
  String get durakRoleTurn => 'دور';

  @override
  String get durakRoleDefends => 'يدافع';

  @override
  String get durakStatusTaking => 'آخذ';

  @override
  String get durakHintDefenderTurn => 'دور المدافع';

  @override
  String get gameYouEliminated => 'تم إقصاؤك';

  @override
  String gameYouPlaced(int place) {
    return 'حلت في المركز $place';
  }

  @override
  String get gameOverNeutral => 'انتهت اللعبة';

  @override
  String gameTurnOf(String name) {
    return 'دور $name';
  }

  @override
  String get chatGroupTooltip => 'دردشة المجموعة';

  @override
  String get lobbyChatNotReady => 'دردشة الردهة غير جاهزة بعد';

  @override
  String get chatsGroupChat => 'دردشة جماعية';

  @override
  String chatsMembersCount(int count) {
    return 'الأعضاء: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count أشخاص';
  }

  @override
  String get chatsYouSuffix => '(أنت)';

  @override
  String get chatTitleDurak3 => 'دوراك · 3 لاعبين';

  @override
  String get chatTitleDurak4 => 'دوراك · 4 لاعبين';

  @override
  String get rulesTttUltimate => 'ألتيميت: تسع لوحات 3×3. النقلة ترسل الخصم إلى تلك اللوحة. الفوز بخط على اللوحة الكبرى.';

  @override
  String get rulesTttMulti3 => '3 لاعبين: لوحة 3×3 وثلاثة لاعبين (X، O، △). أكمل خطًا برموزك للفوز.';

  @override
  String get rulesTttMulti4 => '4 لاعبين: لوحة 4×4 وأربعة لاعبين (X، O، △، □). أكمل خطًا برموزك للفوز.';
}
