import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'होम';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get navFriends => 'मित्र';

  @override
  String get navChats => 'चैट';

  @override
  String get navGames => 'गेम';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsLanguage => 'भाषा';

  @override
  String get settingsLanguageSystem => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get settingsSoundTitle => 'ध्वनि';

  @override
  String get settingsSoundSubtitle => 'गेम और सूचनाएँ';

  @override
  String get settingsSoundGames => 'गेम';

  @override
  String get settingsSoundNotifications => 'सूचनाएँ';

  @override
  String get settingsSoundTurn => 'चाल';

  @override
  String get settingsHapticsTitle => 'कंपन';

  @override
  String get settingsHapticsSubtitle => 'केवल सूचनाएँ: संदेश, अनुरोध, आपकी बारी और टाइमर';

  @override
  String get settingsGamepadTitle => 'कंट्रोलर';

  @override
  String get settingsGamepadSubtitle => 'मेनू और मैच के लिए गेमपैड';

  @override
  String settingsGamepadConnected(String name) {
    return 'जुड़ा: $name';
  }

  @override
  String get settingsGamepadDisconnected => 'गेमपैड नहीं मिला। कंट्रोलर जोड़ें और कोई भी बटन दबाएँ।';

  @override
  String get settingsGamepadGenericName => 'कंट्रोलर';

  @override
  String get settingsGamepadHelpNavigate => 'नेविगेट';

  @override
  String get settingsGamepadHelpConfirm => 'चुनें';

  @override
  String get settingsGamepadHelpBack => 'वापस';

  @override
  String get settingsGamepadHelpTabs => 'टैब';

  @override
  String get settingsGamepadHelpPlay => 'बोर्ड और हाथ कर्सर: चेकर्स, टिक-टैक-टो, बैटलशिप, दुराक, ऊनो, पोकर और बैकगैमन';

  @override
  String get settingsGamepadHelpCards => 'पत्ते';

  @override
  String get settingsGamepadHelpKeyboard => 'कीबोर्ड';

  @override
  String get settingsGamepadHelpBalance => 'बैलेंस';

  @override
  String get settingsGamepadHelpLogout => 'लॉग आउट';

  @override
  String get settingsGamepadHelpPage => 'पेज';

  @override
  String get settingsGamepadLayoutXbox => 'Xbox लेआउट';

  @override
  String get settingsGamepadLayoutPlayStation => 'PlayStation लेआउट';

  @override
  String get settingsGamepadLayoutNintendo => 'Nintendo लेआउट';

  @override
  String get gamepadKeyboardTitle => 'कीबोर्ड';

  @override
  String get gamepadKeyboardSpace => 'स्पेस';

  @override
  String get gamepadLegendConfirm => 'चुनें';

  @override
  String get gamepadLegendBack => 'वापस';

  @override
  String get gamepadLegendTabs => 'टैब';

  @override
  String get gamepadLegendCycle => 'बदलें';

  @override
  String gamepadConnectedSnack(String name) {
    return 'कंट्रोलर जुड़ा: $name';
  }

  @override
  String get settingsOfflineModeTitle => 'नेटवर्क मोड';

  @override
  String get settingsOfflineModeSubtitle => 'ऑफ़लाइन: तुरंत बॉट से खेलें, बिना दांव और पुरस्कार, बिना चैट और मित्र। खरीदारी सहेजी जाती है और ऑनलाइन मोड में लागू होती है। ऑनलाइन — जब इंटरनेट हो या उपयोगकर्ता सेटिंग के अनुसार।';

  @override
  String get settingsModeOnline => 'ऑनलाइन';

  @override
  String get settingsModeOffline => 'ऑफ़लाइन';

  @override
  String get gamesAlternateStartsHint => 'बारी-बारी से कौन पार्टी शुरू करता है';

  @override
  String get rulesAlternateStarts => 'कौन पहले चलता है, वह पार्टी दर पार्टी बदलता है।';

  @override
  String get offlineBadgeTooltip => 'ऑफ़लाइन मोड';

  @override
  String get offlineModePopupTitle => 'ऑफ़लाइन मोड';

  @override
  String get offlineModePopupBody => 'ऑफ़लाइन मोड चालू है। बिना दांव और पुरस्कार के बॉट से खेलें। चैट, मित्र और लॉबी छिपे हैं। खरीदारी ऑनलाइन मोड में लागू होगी।';

  @override
  String get offlineModePopupSettings => 'सेटिंग्स';

  @override
  String get offlineModeOfferBody => 'इंटरनेट नहीं है या कनेक्शन बहुत धीमा है। आप ऑफ़लाइन मोड चालू करके बॉट से खेल सकते हैं।';

  @override
  String get offlineModeOfferAction => 'ऑफ़लाइन चालू करें';

  @override
  String get gamesPlay => 'खेलें';

  @override
  String get offlineGameTitle => 'बॉट के साथ खेल';

  @override
  String get offlineGameHint => 'बिना दांव और पुरस्कार · केवल ऑफ़लाइन';

  @override
  String get offlineBotWon => 'बॉट जीत गया';

  @override
  String get offlineBotThinking => 'बॉट सोच रहा है…';

  @override
  String get offlinePlayAgain => 'फिर से';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'लो';

  @override
  String get durakActionAll => 'सभी';

  @override
  String get durakActionDone => 'पूर्ण';

  @override
  String get durakActionBito => 'Beat';

  @override
  String get durakHintDefend => 'बचाव करें';

  @override
  String get durakHintDefendOrTransfer => 'बचाव करें या ट्रांसफर करें';

  @override
  String get durakHintOpponentDefends => 'प्रतिद्वंद्वी बचाव कर रहा है';

  @override
  String get durakHintThrowInFirst => 'पत्ते फेंकें (पहले बचाव में अधिकतम 5)';

  @override
  String get durakHintThrowIn => 'पत्ते फेंकें या बचाव की प्रतीक्षा करें';

  @override
  String get durakHintOpponentThrows => 'प्रतिद्वंद्वी फेंक रहा है';

  @override
  String get durakHintTakeFollow => 'लेने के बाद फेंकें या «पूर्ण» दबाएँ';

  @override
  String get durakHintOpponentTakeFollow => 'प्रतिद्वंद्वी लेने के बाद फेंक सकता है';

  @override
  String get durakHintBito => 'कार्ड फेंकें या «बीटो» कहें';

  @override
  String get durakHintOpponentBito => 'प्रतिद्वंद्वी फेंकता है या «बीटो» कहता है';

  @override
  String get durakHintYourAttack => 'आपकी बारी — हमला करें';

  @override
  String get durakHintOpponentAttack => 'प्रतिद्वंद्वी हमला कर रहा है';

  @override
  String get durakHintYouLost => 'आप हारे — आप मूर्ख हैं';

  @override
  String get durakHintDrawAllOut => 'ड्रॉ — सभी बाहर';

  @override
  String get durakHintYouFinished => 'आप बाहर — अंत की प्रतीक्षा';

  @override
  String get durakFirstLeadYou => 'आप पहले चलते हैं';

  @override
  String get durakFirstLeadOpponent => 'प्रतिद्वंद्वी पहले चलता है';

  @override
  String get durakFirstLeadBot => 'बॉट पहले चलता है';

  @override
  String durakFirstLeadOf(String name) {
    return '$name पहले चलता है';
  }

  @override
  String get durakFirstLeadReason => 'सबसे छोटा ट्रम्प';

  @override
  String get shopPurchaseQueued => 'खरीदारी सहेजी गई — ऑनलाइन मोड में लागू होगी';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — खरीदारी लागू';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — खरीदारी लागू नहीं: $reason';
  }

  @override
  String get settingsFriendsOnlyTitle => 'केवल मित्रों के संदेश';

  @override
  String get settingsFriendsOnlySubtitle => 'गैर-मित्र केवल इमोजी भेज सकते हैं। यदि स्पैम हो, तो उपयोगकर्ता को अस्थायी रूप से ब्लॉक करें।';

  @override
  String get settingsNotifications => 'सूचनाएँ';

  @override
  String get settingsPushChat => 'चैट';

  @override
  String get settingsPushFriends => 'मित्र';

  @override
  String get settingsPushGames => 'गेम';

  @override
  String get settingsPushRewards => 'इनाम';

  @override
  String settingsAppVersion(String version) {
    return 'संस्करण $version';
  }

  @override
  String get appUpdateTitle => 'अपडेट उपलब्ध';

  @override
  String get appUpdateBody => 'ऐप का नया संस्करण उपलब्ध है। जारी रखने के लिए अपडेट करें।';

  @override
  String get appUpdateWhatsNew => 'नया क्या है';

  @override
  String get appUpdateOk => 'अपडेट';

  @override
  String get appUpdateLaterBanner => 'इस गेम के बाद हम ऐप अपडेट करेंगे';

  @override
  String get loginTitle => 'साइन इन';

  @override
  String get loginSubtitle => 'ईमेल या उपयोगकर्ता नाम और पासवर्ड दर्ज करें';

  @override
  String get loginEmailLabel => 'ईमेल या उपयोगकर्ता नाम';

  @override
  String get loginPasswordLabel => 'पासवर्ड';

  @override
  String get loginSubmit => 'साइन इन';

  @override
  String get loginNoAccount => 'खाता नहीं है? साइन अप करें';

  @override
  String get loginEmailRequired => 'ईमेल या उपयोगकर्ता नाम दर्ज करें';

  @override
  String get loginPasswordRequired => 'पासवर्ड दर्ज करें';

  @override
  String get loginTooltip => 'साइन इन';

  @override
  String get logoutTooltip => 'साइन आउट';

  @override
  String get registerTitle => 'साइन अप';

  @override
  String get registerSubtitle => 'खेलने के लिए खाता बनाएँ';

  @override
  String get registerNameLabel => 'नाम (उपयोगकर्ता नाम)';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'पासवर्ड';

  @override
  String get registerSubmit => 'साइन अप';

  @override
  String get registerHaveAccount => 'पहले से खाता है? साइन इन करें';

  @override
  String get registerNameRequired => 'नाम दर्ज करें';

  @override
  String get registerNameNoSpaces => 'नाम में स्पेस नहीं हो सकते';

  @override
  String get registerNameMax => 'अधिकतम 20 अक्षर';

  @override
  String get registerNameHint => '20 अक्षर तक';

  @override
  String get registerEmailRequired => 'ईमेल दर्ज करें';

  @override
  String get registerEmailInvalid => 'अमान्य ईमेल';

  @override
  String get registerPasswordHint => 'कम से कम 6 अक्षर';

  @override
  String get registerPasswordMin => 'पासवर्ड कम से कम 6 अक्षर का होना चाहिए';

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonSave => 'सहेजें';

  @override
  String get commonDelete => 'हटाएँ';

  @override
  String get commonEdit => 'संपादित करें';

  @override
  String get commonReply => 'उत्तर दें';

  @override
  String get commonSend => 'भेजें';

  @override
  String get commonClose => 'बंद करें';

  @override
  String get commonRetry => 'फिर से कोशिश करें';

  @override
  String get commonLoading => 'लोड हो रहा है…';

  @override
  String get commonError => 'त्रुटि';

  @override
  String get commonOnline => 'ऑनलाइन';

  @override
  String get commonOffline => 'ऑफ़लाइन';

  @override
  String get commonOnlineCap => 'ऑनलाइन';

  @override
  String get commonUser => 'उपयोगकर्ता';

  @override
  String get commonPlayer => 'खिलाड़ी';

  @override
  String get commonAboutMe => 'मेरे बारे में';

  @override
  String get commonBack => 'वापस';

  @override
  String get commonAccept => 'स्वीकार करें';

  @override
  String get commonDecline => 'अस्वीकार करें';

  @override
  String get commonCreating => 'बनाया जा रहा है…';

  @override
  String get commonSearching => 'खोज रहे हैं…';

  @override
  String get commonInsufficientCoins => 'पर्याप्त सिक्के नहीं';

  @override
  String get commonNotFound => 'नहीं मिला';

  @override
  String get commonServerErrorShort => 'सर्वर त्रुटि';

  @override
  String get commonForbidden => 'पहुँच अस्वीकृत';

  @override
  String get commonUserBlocked => 'उपयोगकर्ता ब्लॉक है';

  @override
  String get commonUserNotFound => 'उपयोगकर्ता नहीं मिला';

  @override
  String get commonGenericError => 'कुछ गलत हुआ। कृपया फिर से कोशिश करें।';

  @override
  String get apiErrWrongGameType => 'गलत गेम प्रकार';

  @override
  String get apiErrWrongGameTypeOrState => 'गलत गेम प्रकार या स्थिति';

  @override
  String get apiErrLobbyFull => 'लॉबी भरी हुई है';

  @override
  String get apiErrBadState => 'गेम की स्थिति अमान्य है';

  @override
  String get apiErrIllegalMove => 'अवैध चाल';

  @override
  String get apiErrUnknownMoveType => 'अज्ञात चाल प्रकार';

  @override
  String get apiErrNoOpponents => 'कोई प्रतिद्वंद्वी नहीं';

  @override
  String get apiErrNoOpponentsRematch => 'रेमैच के लिए कोई प्रतिद्वंद्वी नहीं';

  @override
  String get apiErrAlreadyInLobby => 'आप पहले से इस लॉबी में हैं';

  @override
  String get apiErrGameNotActive => 'गेम सक्रिय नहीं है';

  @override
  String get apiErrNotInBattle => 'अभी युद्ध चरण नहीं है';

  @override
  String get apiErrNotInSetup => 'अभी सेटअप चरण नहीं है';

  @override
  String get apiErrAlreadyReady => 'आप पहले से तैयार हैं';

  @override
  String get apiErrAlreadyForfeited => 'आप पहले ही हार मान चुके हैं';

  @override
  String get apiErrYouHaveForfeited => 'आप हार मान चुके हैं';

  @override
  String get apiErrNoDrawOffer => 'कोई ड्रॉ पेशकश नहीं';

  @override
  String get apiErrDrawOnlyPvp => 'ड्रॉ केवल खिलाड़ी के खिलाफ';

  @override
  String get apiErrDrawOnly1v1 => 'ड्रॉ केवल 1 बनाम 1 में';

  @override
  String get apiErrDrawVsBot => 'बॉट के खिलाफ ड्रॉ उपलब्ध नहीं';

  @override
  String get apiErrDrawMultiplayer => 'मल्टीप्लेयर में ड्रॉ उपलब्ध नहीं';

  @override
  String get apiErrDeck24TwoPlayers => '24 पत्तों की गड्डी सिर्फ़ 2 खिलाड़ियों के लिए';

  @override
  String get apiErrDeck52ThreeOrFour => '52 पत्तों की गड्डी 3 या 4 खिलाड़ियों के लिए';

  @override
  String get apiErrAccountFrozen => 'खाता फ़्रीज़ है';

  @override
  String get apiErrTurnTimeInvalid => 'चाल का समय 0, 20, 60 या 600 सेकंड होना चाहिए';

  @override
  String get timeJustNow => 'अभी';

  @override
  String get timeYesterday => 'कल';

  @override
  String timeMinutesAgo(int count) {
    return '$count मि पहले';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count घं पहले';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count दि पहले';
  }

  @override
  String get timeWeekAgo => 'एक सप्ताह पहले';

  @override
  String timeWeeksAgo(int count) {
    return '$count सप्ताह पहले';
  }

  @override
  String get timeMonthAgo => 'एक महीना पहले';

  @override
  String timeMonthsAgo(int count) {
    return '$count माह पहले';
  }

  @override
  String get timeYearAgo => 'एक वर्ष पहले';

  @override
  String timeYearsAgo(int count) {
    return '$count वर्ष पहले';
  }

  @override
  String get weekdaySun => 'रवि';

  @override
  String get weekdayMon => 'सोम';

  @override
  String get weekdayTue => 'मंगल';

  @override
  String get weekdayWed => 'बुध';

  @override
  String get weekdayThu => 'गुरु';

  @override
  String get weekdayFri => 'शुक्र';

  @override
  String get weekdaySat => 'शनि';

  @override
  String get monthJan => 'जन';

  @override
  String get monthFeb => 'फर';

  @override
  String get monthMar => 'मार्च';

  @override
  String get monthApr => 'अप्रै';

  @override
  String get monthMay => 'मई';

  @override
  String get monthJun => 'जून';

  @override
  String get monthJul => 'जुल';

  @override
  String get monthAug => 'अग';

  @override
  String get monthSep => 'सित';

  @override
  String get monthOct => 'अक्टू';

  @override
  String get monthNov => 'नव';

  @override
  String get monthDec => 'दिस';

  @override
  String get homeAchievements => 'उपलब्धियाँ';

  @override
  String get homeAchievementsSubtitle => 'आपके गेम परिणाम';

  @override
  String get homeAchievementsRewards => 'दावा करने योग्य इनाम उपलब्ध';

  @override
  String get homeCoins => 'सिक्के';

  @override
  String get homeCoinsSubtitle => 'शेष राशि और इनाम';

  @override
  String get homeCoinsDailyReward => 'दैनिक लॉगिन इनाम उपलब्ध';

  @override
  String get homeItems => 'आइटम';

  @override
  String get homeItemsInventory => 'आपकी इन्वेंटरी';

  @override
  String get homeItemsGifted => 'किसी ने आपको कलेक्शन उपहार में दिया';

  @override
  String get homeItemsIncome => 'कलेक्शन आय लेने के लिए तैयार';

  @override
  String get homeShop => 'दुकान';

  @override
  String get homeShopSubtitle => 'इमोजी, दाँव, कलेक्शन';

  @override
  String get gamesTitle => 'गेम';

  @override
  String get gamesFindMatch => 'गेम खोजें';

  @override
  String get gamesMyTurn => 'आपकी बारी';

  @override
  String get gamesWaiting => 'प्रतीक्षा';

  @override
  String get gamesLobbyTab => 'लॉबी';

  @override
  String get gamesTicTacToe => 'टिक-टैक-टो';

  @override
  String get gamesDurak => 'दुरक';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => 'घुमाएँ';

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
  String get gamesPoker => 'पोकर';

  @override
  String get gamesUno => 'ऊनो';

  @override
  String get gamesNardy => 'बैकगैमन';

  @override
  String get gamesNardyModeShort => 'छोटा';

  @override
  String get gamesNardyModeLong => 'लंबा';

  @override
  String get gamesCheckers => 'चेकर्स';

  @override
  String get gamesCheckersModeRussian => 'रूसी';

  @override
  String get gamesCheckersModeEnglish => 'अंग्रेज़ी';

  @override
  String get gamesCheckersModeGiveaway => 'गिवअवे';

  @override
  String get gamesCheckersModeCorners => 'कॉर्नर';

  @override
  String get gamesChess => 'शतरंज';

  @override
  String get gamesDomino => 'डोमिनो';

  @override
  String get gamesDominoModeKozel => 'बकरा';

  @override
  String get gamesDominoModeClassic => 'क्लासिक';

  @override
  String get gamesDominoModeSea => 'समुद्री';

  @override
  String get rulesDominoDeal => 'हर खिलाड़ी को 7 टाइल। 2 या 3 में बाकी भंडार में, 4 में भंडार खाली।';

  @override
  String get rulesDominoOpen => 'पहला दाँव 1-1 से 6-6 तक सबसे छोटे डबल से, फिर 0-0। डबल न हो तो सबसे बड़ी टाइल से शुरू, और वही खेलनी है।';

  @override
  String get rulesDominoPlay => 'टाइल खुले सिरे पर उसी अंक से लगाएँ। सिरे पर डबल उस अंक को नहीं बदलता।';

  @override
  String get rulesDominoDraw => 'चाल न हो तो एक-एक करके तब तक खींचें जब तक चाल बने या भंडार खत्म हो। आखिरी टाइल ली जा सकती है। फिर भी न हो तो पास।';

  @override
  String get rulesDominoScore => 'दाँव के अंत में हर कोई बची टाइलों का योग लिखता है। जो निकल गया — 0। 101 तक: जो पहुँचे वह बकरा और हार।';

  @override
  String get rulesDominoFish => 'मछली: भंडार खाली और कोई नहीं लगा सकता। सबसे कम योग अकेला हो तो 0, बाकी अपना योग। न्यूनतम सबका बराबर हो तो सब लिखते हैं।';

  @override
  String get rulesDominoMatch => 'एक ही दाँव में कई 101 पार करें तो सबसे बड़ा स्कोर बकरा है। सबसे कम स्कोर जीतते हैं। सब बराबर हों तो ड्रॉ।';

  @override
  String get rulesDominoOffline => 'ऑफ़लाइन: आप और बॉट। बॉट अंक गिनता है और छुपे हाथ नहीं देखता।';

  @override
  String rulesDominoMode(String mode) {
    return 'मोड: $mode';
  }

  @override
  String get rulesDominoClassicDeal => 'दो या तीन को 7, चार को 5 टाइल। बाकी बाज़ार।';

  @override
  String get rulesDominoClassicOpen => 'पहला दाँव डबल 6 से, फिर 0-0 और छोटे डबल। डबल न हो तो सबसे बड़ा टाइल रखना होगा।';

  @override
  String get rulesDominoClassicScore => 'जो खाली हाथ निकले, वह विरोधियों के पिप लिखता है। 100 तक पहले पहुँचने वाला जीतता है।';

  @override
  String get rulesDominoClassicFish => 'ब्लॉक पर सबसे हल्के अद्वितीय हाथ को हर दूसरे हाथ से अंतर मिलता है। बराबरी पर कुछ नहीं लिखा जाता।';

  @override
  String get rulesDominoClassicMatch => 'समान सबसे ऊँचा स्कोर जीत बाँटता है। सब बराबर हों तो ड्रॉ।';

  @override
  String get rulesDominoSeaSame => 'बाँटना, पहली चाल और खींचना बकरा जैसा। श्रृंखला के दो सिरे।';

  @override
  String get rulesDominoSeaScore => 'अंक केवल सबसे भारी हाथ लिखता है। 25 से कम नहीं लिखा जाता।';

  @override
  String get rulesDominoSeaWipe => 'यदि दो के पास 25 या अधिक हों, तो यह दाँव किसी को नहीं लिखा जाता।';

  @override
  String get rulesDominoSeaBlank => '0-0 डालते ही दाँव खत्म: सबसे भारी विरोधी अकेला हो तो 75। बराबरी पर किसी को नहीं।';

  @override
  String get rulesDominoSeaSix => 'अंतिम 6-6 से बंद होने पर हारने वाले को 100, बंद करने वाले का मैच स्कोर शून्य।';

  @override
  String get rulesDominoSeaMatch => 'मैच 125 तक। जो पहुँचे वह हारा।';

  @override
  String get dominoBoneyard => 'भंडार';

  @override
  String get dominoChooseEnd => 'सिरा चुनें';

  @override
  String get dominoFish => 'मछली';

  @override
  String get dominoYouGoat => 'आप बकरा हैं';

  @override
  String dominoGoatNamed(String name) {
    return 'बकरा — $name';
  }

  @override
  String get dominoLeft => 'बाएँ';

  @override
  String get dominoRight => 'दाएँ';

  @override
  String get gamesChessModeClassic => 'क्लासिक';

  @override
  String get gamesChessModeRapid => 'रैपिड';

  @override
  String get gamesChessModeBlitz => 'ब्लिट्ज';

  @override
  String get gamesChessModeBullet => 'बुलेट';

  @override
  String get chessPieceQueen => 'वज़ीर';

  @override
  String get chessPieceRook => 'हाथी';

  @override
  String get chessPieceBishop => 'ऊँट';

  @override
  String get chessPieceKnight => 'घोड़ा';

  @override
  String get chessPromotionTitle => 'प्यादे का प्रमोशन';

  @override
  String get chessDrawStalemate => 'ड्रॉ: गतिरोध';

  @override
  String get chessDrawInsufficient => 'ड्रॉ: अपर्याप्त सामग्री';

  @override
  String get chessDrawRepetition => 'ड्रॉ: तीन बार पुनरावृत्ति';

  @override
  String get chessDrawFiftyMove => 'ड्रॉ: 50-चाल नियम';

  @override
  String get chessCheck => 'शह';

  @override
  String get rulesCheckersPlayers => 'खिलाड़ी: 2.';

  @override
  String rulesCheckersMode(String mode) {
    return 'मोड: $mode.';
  }

  @override
  String rulesCheckersTime(String time) {
    return 'Время на ход: $time. Если время вышло — проигрыш.';
  }

  @override
  String get rulesCheckersIntro => 'बोर्ड 8×8. दो खिलाड़ी.';

  @override
  String get rulesCheckersPlay => 'मारना अनिवार्य है। रानी या मोहरा यदि आगे मार सकते हों तो बीच में नहीं रुक सकते। कई दिशाएँ हों तो कोई भी चुन सकते हैं, सबसे लंबी ज़रूरी नहीं। आख़िरी पंक्ति तक पहुँचा मोहरा रानी बन जाता है।';

  @override
  String get rulesCheckersWin => 'В русских шашках побеждает тот, кто съел все шашки соперника или лишил его хода. В поддавках наоборот: кто не может ходить — выигрывает.';

  @override
  String get rulesCheckersOfflineBot => 'Офлайн: партия против бота.';

  @override
  String get rulesCheckersPlayRussian => 'रूसी चेकर्स: प्रत्येक के 12 मोहरे गहरे घरों पर। साधारण मोहरे तिरछे आगे चलते हैं और आगे-पीछे मारते हैं। रानी किसी भी दूरी तक उड़ती है। मारना अनिवार्य है: आगे मार सकें तो बीच में नहीं रुक सकते, लेकिन कई दिशाएँ हों तो कोई भी चुन सकते हैं — सबसे लंबी ज़रूरी नहीं। जीत तब जब सारे मोहरे खा लिए जाएँ या विरोधी के पास चाल न हो।';

  @override
  String get rulesCheckersPlayEnglish => 'अंग्रेज़ी चेकर्स: प्रत्येक के 12 मोहरे। साधारण मोहरे केवल तिरछे आगे चलते और मारते हैं। रानी किसी भी दिशा में एक घर चलती है। मारना अनिवार्य है। जीत तब जब सारे मोहरे खा लिए जाएँ या विरोधी के पास चाल न हो।';

  @override
  String get rulesCheckersPlayGiveaway => 'गिवअवे: चालें रूसी चेकर्स जैसी हैं, पर लक्ष्य उलटा है — अपने सारे मोहरे दे देना या बिना चाल के रह जाना। मारना फिर भी अनिवार्य है।';

  @override
  String get rulesCheckersPlayCorners => 'कॉर्नर: मोहरे आमने-सामने के कोनों में शुरू होते हैं। क्षैतिज या ऊर्ध्व खाली पड़ोसी घर पर चलें, या किसी भी मोहरे के ऊपर कूदें बिना उसे हटाए। लक्ष्य अपने सारे मोहरे विरोधी के कोने में पहुँचाना है।';

  @override
  String get rulesCheckersPlayCornersNoReturn => 'जो मोहरा अपने शुरुआती कोने से निकल चुका है, वह वहाँ वापस नहीं जा सकता।';

  @override
  String get rulesCheckersPlayCornersLeaveHome => 'जो मोहरे अभी घर में हैं, उन्हें खिलाड़ी के पहले 25 चालों में घर छोड़ना होगा।';

  @override
  String get rulesCheckersDrawRussian => 'ड्रॉ यदि स्थिति तीन बार दोहराई जाए, या प्रत्येक पक्ष के 15 चालों में प्रगति न हो: न कब्जा, न साधारण चाल, न बादशाह बनना।';

  @override
  String get rulesCheckersDrawEnglish => 'ड्रॉ यदि स्थिति तीन बार दोहराई जाए, प्रत्येक पक्ष के 40 चाल बिना कब्जे और साधारण चाल के हों, या प्रत्येक पक्ष के पास एक ही बादशाह बचे।';

  @override
  String get rulesCheckersDrawGiveaway => 'ड्रॉ यदि स्थिति तीन बार दोहराई जाए, या गिवअवे में प्रत्येक पक्ष के 15 चालों में प्रगति न हो: न कब्जा, न साधारण चाल, न बादशाह बनना।';

  @override
  String get rulesCheckersDrawCorners => 'ड्रॉ यदि स्थिति तीन बार दोहराई जाए, या प्रत्येक पक्ष के 25 चाल लक्ष्य कोने में गोटी न जोड़ें।';

  @override
  String get rulesChessPlayers => 'खिलाड़ी: 2.';

  @override
  String rulesChessMode(String mode) {
    return 'मोड: $mode.';
  }

  @override
  String get rulesChessPlayClassic => 'बोर्ड 8×8. प्रत्येक पक्ष के पास राजा, वज़ीर, दो हाथी, दो ऊँट, दो घोड़े और आठ प्यादे। सफ़ेद पहले चलता है। सामान्य चालें, एन पासॉं, प्रमोशन और कैसलिंग। मात या हार मानना जीत है।';

  @override
  String get rulesChessDrawClassic => 'ड्रॉ: स्टेलमेट, तीन बार दोहराव, 50 चाल, मात के लिए मोहरे कम, या सहमति।';

  @override
  String get rulesChessClockClassic => 'घड़ी: 60+0 — पूरी पार्टी के लिए 60 मिनट, कोई जोड़ नहीं.';

  @override
  String get rulesChessClockRapid => 'घड़ी: 10+0 — पूरी पार्टी के लिए 10 मिनट, कोई जोड़ नहीं.';

  @override
  String get rulesChessClockBlitz => 'घड़ी: 5+0 — पूरी पार्टी के लिए 5 मिनट, कोई जोड़ नहीं.';

  @override
  String get rulesChessClockBullet => 'घड़ी: 3+2 — 3 मिनट और हर चाल पर 2 सेकंड.';

  @override
  String get checkersDrawRepetition => 'ड्रॉ — स्थिति तीन बार दोहराई गई';

  @override
  String get checkersDrawNoProgress => 'ड्रॉ — चालें जीत तक नहीं पहुँचतीं';

  @override
  String get checkersDrawInsufficient => 'ड्रॉ — जीत के लिए पर्याप्त मोहरे नहीं';

  @override
  String get rulesNardyTitle => 'बैकगैमन — नियम';

  @override
  String get rulesNardyPlayers => 'खिलाड़ी: 2.';

  @override
  String rulesNardyMode(String mode) {
    return 'मोड: $mode.';
  }

  @override
  String get rulesNardyIntro => '24 बिंदुओं का बोर्ड, प्रत्येक के 15 मोहरे। दो पासे: एक मोहरा योग या दो मोहरे अंक।';

  @override
  String get rulesNardyPlayShort => 'छोटा: एक-दूसरे की ओर चलते हैं और अकेले मोहरे मार सकते हैं। मारा गया मोहरा बार पर जाता है और फिर घुसना होता है। सब घर में हों तो उतारें।';

  @override
  String get rulesNardyPlayLong => 'लंबा: दोनों एक ही सिरे से एक दिशा में चलते हैं। सिरे से एक चाल में एक ही मोहरा निकलता है। मारना मना है। सब घर में हों तो उतारें।';

  @override
  String get rulesNardyWin => 'जो पहले सारे मोहरे उतार ले, वही जीते।';

  @override
  String get rulesNardySixPrime => 'जब तक विरोधी की कोई गोटी उन्हें पार न कर ले, लगातार छह बिंदु बंद नहीं किए जा सकते।';

  @override
  String get nardyRoll => 'पासा फेंकें';

  @override
  String get nardySkipTurn => 'बारी छोड़ें';

  @override
  String get nardyUndoMove => 'वापस लें';

  @override
  String get nardyDoneTurn => 'हो गया';

  @override
  String get nardyAutoConfirm => 'स्वतः पुष्टि';

  @override
  String get nardyAutoConfirmHint => 'सभी चालों के बाद बारी अपने आप चली जाएगी';

  @override
  String get nardyLayoutToggle => 'खांचे बदलें';

  @override
  String get nardyNoMoves => 'कोई चाल नहीं';

  @override
  String get nardyYourRoll => 'आपका पासा';

  @override
  String get nardyPipsShort => 'शेष:';

  @override
  String get nardyYouWonMars => 'आप जीते — गैमन!';

  @override
  String get nardyYouLostMars => 'हार — गैमन';

  @override
  String get rulesNardyOfflineBot => 'ऑफ़लाइन: बॉट के साथ खेल।';

  @override
  String rulesUnoPlayers(int players) {
    return 'खिलाड़ी: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'बॉट के खिलाफ खेल, चाल की समय सीमा नहीं।';

  @override
  String get rulesUnoIntro => 'हर खिलाड़ी को 7 पत्ते मिलते हैं। उसी रंग या उसी मान (अंक या वही क्रिया) का पत्ता खेलें।';

  @override
  String get rulesUnoPlay => 'छोड़ो — अगला अपनी बारी खोता है। दो खिलाड़ियों में दिशा बदलना छोड़ने जैसा है। +2 केवल +2 पर और +4 केवल +4 पर रखा जा सकता है: जुर्माना जुड़ता है (दो +2 पर अगला 4 उठाता है)। +2 को +4 पर नहीं रखा जा सकता। जो जवाब नहीं देता, पूरी गड्डी उठाता है और बारी खोता है। दो एक जैसी गैर-काली पत्तियाँ (जैसे दो पीले 8) साथ फेंकी जाती हैं: एक चलाएँ तो जोड़ी अपने आप जाएगी।';

  @override
  String get rulesUnoWild => 'काला पत्ता नया रंग तय करता है। +4 तभी जब वर्तमान रंग का पत्ता न हो। विरोधी चुनौती दे सकता है: +4 वैध हो तो वह 6 उठाए; नहीं तो +4 वाला 4 उठाए और चुनौती देने वाला खेले।';

  @override
  String get rulesUnoDraw => 'कोई वैध पत्ता न हो तो डेक से एक उठाएँ। मेल खाए तो तुरंत खेलें या रख कर बारी दें। वैध चाल रहते उठाना मना है।';

  @override
  String get rulesUnoWin => 'आमने-सामने 100 अंक, 3+ खिलाड़ियों में 200। राउंड हाथ खाली करने वाला जीते।';

  @override
  String get rulesUnoCall => 'एक पत्ता बचने पर तुरंत «ऊनो!» दबाएँ। विरोधी ऊनो भूलने पर आपको एक सेकंड बाद ही पकड़ सकते हैं — तब आप 2 पत्ते उठाएँगे।';

  @override
  String get rulesUnoScoring => 'जो पहले हाथ खाली करे वह राउंड जीते और विरोधियों के पत्तों के अंक पाए: अंक अपने मान, क्रिया 20, काले 50। आमने-सामने 100, 3+ खिलाड़ियों में 200।';

  @override
  String get unoColorRed => 'लाल';

  @override
  String get unoColorYellow => 'पीला';

  @override
  String get unoColorGreen => 'हरा';

  @override
  String get unoColorBlue => 'नीला';

  @override
  String get unoDraw => 'उठाएँ';

  @override
  String get unoKeep => 'रखें';

  @override
  String get unoSayUno => 'ऊनो!';

  @override
  String get unoChallengeUno => 'ऊनो चुनौती';

  @override
  String get unoChallengeWd4 => '+4 चुनौती';

  @override
  String get unoChooseColor => 'रंग चुनें';

  @override
  String get unoDrawPile => 'ड्रॉ ढेर';

  @override
  String get unoDiscardPile => 'डिस्कार्ड';

  @override
  String unoCardsCount(int count) {
    return 'पत्ते: $count';
  }

  @override
  String unoScore(int score) {
    return 'अंक: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'राउंड $round · $target तक';
  }

  @override
  String get unoYourTurn => 'आपकी बारी';

  @override
  String get unoWaitingTurn => 'विरोधी की बारी';

  @override
  String get unoChooseColorHint => 'वाइल्ड पत्ते के लिए रंग चुनें';

  @override
  String get unoWd4Hint => '4 पत्ते उठाएँ या Wild +4 को चुनौती दें';

  @override
  String get unoDrawnHint => 'उठाया पत्ता खेलें या रखें';

  @override
  String get unoPlayHint => 'मिलता रंग या मूल्य खेलें';

  @override
  String get unoDrawHint => 'कोई मिलता पत्ता नहीं — ढेर से उठाएँ';

  @override
  String unoPendingDraw(int count) {
    return '+$count पत्ते';
  }

  @override
  String get unoYouWon => 'आप मैच जीत गए!';

  @override
  String get unoYouLost => 'मैच समाप्त';

  @override
  String get unoYouLostTimeout => 'आप समय खत्म होने पर हारे';

  @override
  String unoWinner(String name) {
    return 'विजेता: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name राउंड जीतते हैं';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'आगे';

  @override
  String get unoRoundScoresTitle => 'राउंड अंक';

  @override
  String get unoDirectionClockwise => 'घड़ी की दिशा';

  @override
  String get unoDirectionCounterclockwise => 'घड़ी की उलटी दिशा';

  @override
  String get unoErrStackSameOnly => '+2 केवल +2 पर और +4 केवल +4 पर चलाया जा सकता है। +2 को +4 पर नहीं रखा जा सकता।';

  @override
  String get unoErrCatchTooEarly => 'एक सेकंड रुकें — वे अभी ऊनो कह सकते हैं।';

  @override
  String get unoErrCallTooLate => 'अब उनो नहीं कहा जा सकता। अगला खिलाड़ी पहले ही चल चुका है।';

  @override
  String get gamesInDevelopment => 'विकास में';

  @override
  String rulesPokerPlayers(int players) {
    return 'खिलाड़ी: $players.';
  }

  @override
  String get rulesPokerIntro => 'टेक्सास होल्ड’एम। हर खिलाड़ी को 2 होल कार्ड मिलते हैं; टेबल पर 5 कम्युनिटी कार्ड आते हैं।';

  @override
  String get rulesPokerPlay => 'बेटिंग राउंड: प्रीफ्लॉप, फ्लॉप, टर्न और रिवर। फोल्ड, कॉल, बेट या रेज़ कर सकते हैं।';

  @override
  String get rulesPokerWin => 'सबसे अच्छा पाँच-पत्तों का हाथ (होल + कम्युनिटी) जीतता है, या फोल्ड के बाद बचा आखिरी खिलाड़ी।';

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
  String get gamesRules => 'नियम';

  @override
  String get gamesRulesTitle => 'गेम के नियम';

  @override
  String get gamesCreate => 'गेम बनाएँ';

  @override
  String get gamesJoin => 'शामिल हों';

  @override
  String get gamesOpponentTurn => 'प्रतिद्वंद्वी की बारी';

  @override
  String get gamesCurrentGame => 'वर्तमान गेम';

  @override
  String get gamesInvitedYou => 'आपको आमंत्रित किया गया';

  @override
  String get gamesTurnTime => 'बारी का समय';

  @override
  String get gamesGridSize => 'ग्रिड आकार';

  @override
  String get gamesSwapSides => 'पक्ष बदलें';

  @override
  String get gamesNoCenter => 'केंद्र से शुरुआत नहीं';

  @override
  String get gamesObservation => 'देखना';

  @override
  String get gamesObservationHint => 'गेम के अंत तक देख सकते हैं';

  @override
  String get gamesFinishCurrentFirst => 'पहले अपना वर्तमान गेम पूरा करें';

  @override
  String get gamesVariantClassic => 'क्लासिक';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 खिलाड़ी';

  @override
  String get gamesVariantMulti4 => '4 खिलाड़ी';

  @override
  String get gamesDurakModePodkidnoi => 'फेंक वाला';

  @override
  String get gamesDurakModePerevodnoi => 'ट्रांसफर';

  @override
  String get gamesDurakDeck24 => '24 पत्ते';

  @override
  String get gamesDurakDeck36 => '36 पत्ते';

  @override
  String get gamesDurakDeck52 => '52 पत्ते';

  @override
  String rulesDurakMode(String mode) {
    return 'मोड: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'खिलाड़ी: $players. डेक: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'बॉट के खिलाफ खेलें, बिना दांव और समय सीमा के।';

  @override
  String get rulesDurakAttack => 'आक्रमणकारी पत्ते खेलता है; रक्षक उन्हें काटता है (उसी सूट का ऊँचा, या ट्रंप)। ट्रंप केवल ऊँचे ट्रंप से कटता है।';

  @override
  String get rulesDurakBeat => 'जब सभी पत्ते कट जाएँ, आक्रमणकारी «बीटो» कहता है और पत्ते डिसकार्ड में जाते हैं। वरना रक्षक मेज़ से सब ले लेता है।';

  @override
  String get rulesDurakLoser => 'हारने वाला वही है जिसके पास अंत में पत्ते रह जाएँ — «मूर्ख».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'खिलाड़ी $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Lobby $name';
  }

  @override
  String get lobbyMatchmake => 'लॉबी';

  @override
  String get lobbyPrivateGame => 'निजी गेम';

  @override
  String get lobbySearchingOpponent => 'प्रतिद्वंद्वी खोज रहे हैं…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'इस गेम की खोज: $count';
  }

  @override
  String get lobbyWaitingJoin => 'किसी के “गेम खोजें” या “शामिल हों” टैप करने की प्रतीक्षा';

  @override
  String get lobbyInviteTitle => 'गेम आमंत्रण';

  @override
  String get lobbyInvitedToPlay => 'आपको खेलने के लिए आमंत्रित किया गया';

  @override
  String get lobbyEnterGame => 'गेम में प्रवेश करें';

  @override
  String get lobbyGone => 'लॉबी अब उपलब्ध नहीं';

  @override
  String get lobbyInvite => 'आमंत्रित करें';

  @override
  String get lobbyInviteSent => 'आमंत्रण भेजा गया';

  @override
  String get lobbyCopyLink => 'गेम लिंक साझा करें';

  @override
  String get lobbyLinkCopied => 'लिंक कॉपी हो गया';

  @override
  String get lobbyNoFriendsOnline => 'कोई मित्र ऑनलाइन नहीं। ऊपर गेम लिंक साझा करें या मित्रों के ऑनलाइन होने तक प्रतीक्षा करें।';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'प्रतिद्वंद्वी';

  @override
  String get gameYou => 'आप';

  @override
  String get gameYouWon => 'आप जीत गए!';

  @override
  String get gameYouWonShort => 'आप जीत गए';

  @override
  String get gameYouLost => 'आप हारे';

  @override
  String get gameYouWonOpponentLeft => 'आप जीत गए — प्रतिद्वंद्वी चला गया';

  @override
  String get gameYouWonOpponentTimeout => 'आप जीत गए — प्रतिद्वंद्वी का समय समाप्त';

  @override
  String get gameDraw => 'ड्रॉ';

  @override
  String get gameExitTitle => 'गेम छोड़ें';

  @override
  String get gameExitConfirm => 'यदि आप छोड़ते हैं, तो हार जाएँगे। फिर भी छोड़ें?';

  @override
  String get gameStay => 'रुकें';

  @override
  String get gameLeave => 'छोड़ें';

  @override
  String get gameSurrender => 'हार मानें';

  @override
  String get gameSurrenderTitle => 'हार मानें?';

  @override
  String get gameSurrenderConfirm => 'आप पार्टी और दांव के सिक्के हार जाएंगे।';

  @override
  String get gameOfferDraw => 'ड्रॉ का प्रस्ताव';

  @override
  String get gameFlipBoard => 'बोर्ड पलटें';

  @override
  String get gameReviewStart => 'खेल की शुरुआत में';

  @override
  String get gameReviewPrev => 'एक चाल पीछे';

  @override
  String get gameReviewNext => 'एक चाल आगे';

  @override
  String get gameReviewEnd => 'वर्तमान स्थिति पर';

  @override
  String get gameOfferDrawTitle => 'ड्रॉ का प्रस्ताव दें?';

  @override
  String get gameOfferDrawConfirm => 'आपका प्रतिद्वंद्वी ड्रॉ स्वीकार या अस्वीकार कर सकता है।';

  @override
  String get gameAcceptDrawTitle => 'ड्रॉ स्वीकार करें?';

  @override
  String get gameAcceptDrawConfirm => 'पार्टी ड्रॉ पर समाप्त होगी।';

  @override
  String get gameDrawOffered => 'प्रतिद्वंद्वी ड्रॉ का प्रस्ताव दे रहा है';

  @override
  String get gameConnecting => 'गेम से कनेक्ट हो रहा है…';

  @override
  String get gameWaitingOpponent => 'प्रतिद्वंद्वी की प्रतीक्षा';

  @override
  String get gameRematchOffer => 'प्रतिद्वंद्वी रीमैच का प्रस्ताव देता है';

  @override
  String get gameRematchDeclined => 'प्रतिद्वंद्वी ने रीमैच अस्वीकार कर दिया';

  @override
  String get gameRematch => 'रीमैच';

  @override
  String get gameOtherOpponent => 'अन्य प्रतिद्वंद्वी';

  @override
  String get gameSwapSidesAction => 'पक्ष बदलें';

  @override
  String get gameWriteMessage => 'संदेश लिखें';

  @override
  String get chatsTitle => 'चैट';

  @override
  String get chatsEmpty => 'अभी कोई चैट नहीं।\nबातचीत शुरू करने के लिए ऊपर दाएँ आइकन पर टैप करके मित्र चुनें।';

  @override
  String get chatsNewChat => 'नई चैट';

  @override
  String get chatsNoMessages => 'कोई संदेश नहीं';

  @override
  String get chatsClearTitle => 'बातचीत साफ़ करें?';

  @override
  String get chatsClearDesc => 'चैट स्थायी रूप से हटा दी जाएगी।';

  @override
  String get chatsClearConfirm => 'साफ़ करें';

  @override
  String get chatsBlockTitle => 'इस उपयोगकर्ता को ब्लॉक करें?';

  @override
  String get chatsBlockDesc => 'आप अब एक-दूसरे को संदेश नहीं भेज सकेंगे। चैट और मित्रता हटा दी जाएगी।';

  @override
  String get chatsBlockConfirm => 'ब्लॉक करें';

  @override
  String get chatsBlockedUsers => 'ब्लॉक किए गए उपयोगकर्ता';

  @override
  String get chatsUnblock => 'अनब्लॉक';

  @override
  String get chatDialog => 'चैट';

  @override
  String get chatEmpty => 'अभी कोई संदेश नहीं।\nपहला संदेश भेजें।';

  @override
  String get chatMessageHint => 'संदेश';

  @override
  String get chatPaste => 'चिपकाएँ';

  @override
  String get chatEmoji => 'इमोजी';

  @override
  String get chatBuyEmojiHint => 'होम स्क्रीन की दुकान से इमोजी खरीदें';

  @override
  String get chatEditing => 'संपादन';

  @override
  String get chatToday => 'आज';

  @override
  String get chatYesterday => 'कल';

  @override
  String get chatFriendsOnly => 'टेक्स्ट केवल मित्रों के लिए';

  @override
  String get emojiGroupEmotions => 'भावनाएँ';

  @override
  String get emojiGroupGame => 'गेमिंग';

  @override
  String get emojiGroupFlags => 'झंडे';

  @override
  String get emojiGroupAnimals => 'जानवर';

  @override
  String get emojiGroupFood => 'भोजन';

  @override
  String get emojiGroupTravel => 'यात्रा';

  @override
  String get emojiGroupParty => 'उत्सव';

  @override
  String get emojiGroupObjects => 'वस्तुएँ';

  @override
  String get friendsTitle => 'मित्र';

  @override
  String get friendsTabFriends => 'मित्र';

  @override
  String get friendsTabIncoming => 'आने वाले';

  @override
  String get friendsTabOutgoing => 'भेजे गए';

  @override
  String get friendsAdd => 'मित्र जोड़ें';

  @override
  String get friendsRequestSent => 'अनुरोध भेजा गया';

  @override
  String get friendsFindTab => 'मित्र खोजें';

  @override
  String get friendsSearchHint => 'उपयोगकर्ता नाम से खोजें';

  @override
  String get friendsSearchPrompt => 'नए मित्र खोजने के लिए खोज का उपयोग करें';

  @override
  String get friendsNothingFound => 'कुछ नहीं मिला';

  @override
  String get friendsEmpty => 'आपके अभी कोई मित्र नहीं हैं';

  @override
  String get friendsSearchNoMatches => 'खोज से कोई मित्र मेल नहीं खाता';

  @override
  String get friendsIncomingSearchNoMatches => 'खोज से कोई आने वाला अनुरोध मेल नहीं खाता';

  @override
  String get friendsOutgoingSearchNoMatches => 'खोज से कोई भेजा गया अनुरोध मेल नहीं खाता';

  @override
  String get friendsNoIncoming => 'कोई आने वाला अनुरोध नहीं';

  @override
  String get friendsNoOutgoing => 'कोई भेजा गया अनुरोध नहीं';

  @override
  String get friendsAlreadyFriends => 'पहले से मित्र हैं';

  @override
  String get friendsRemoveTitle => 'मित्रों से हटाएँ?';

  @override
  String get friendsRemoved => 'मित्रों से हटा दिया गया';

  @override
  String get friendsRequestAccepted => 'अनुरोध स्वीकार किया गया';

  @override
  String get friendsRequestDeclined => 'अनुरोध अस्वीकार किया गया';

  @override
  String get friendsRequestCancelled => 'अनुरोध रद्द किया गया';

  @override
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get profileSignInPrompt => 'अपने खाते में साइन इन करें';

  @override
  String get profileSignInHint => 'अपनी व्यक्तिगत प्रोफ़ाइल सेट करने के लिए';

  @override
  String get profileEdit => 'संपादित करें';

  @override
  String get profileCollections => 'कलेक्शन';

  @override
  String get profileAge => 'उम्र';

  @override
  String get profileGender => 'लिंग';

  @override
  String get profileGenderUnset => 'सेट नहीं';

  @override
  String get profileGenderMale => 'पुरुष';

  @override
  String get profileGenderFemale => 'महिला';

  @override
  String get profileAvatar => 'अवतार';

  @override
  String get profileUploadPhoto => 'फ़ोटो अपलोड करें';

  @override
  String get profileChangePhoto => 'अवतार बदलें';

  @override
  String get shopTitle => 'दुकान';

  @override
  String get shopEmojis => 'इमोजी';

  @override
  String get shopEmojisSubtitle => 'चैट के लिए एनिमेटेड इमोजी';

  @override
  String get shopCollections => 'कलेक्शन';

  @override
  String get shopCollectionsSubtitle => 'प्रोफ़ाइल प्रदर्शन, उपहार और आय';

  @override
  String get shopStakes => 'दाँव';

  @override
  String get shopStakesSubtitle => 'उच्च दाँव अनलॉक करें';

  @override
  String get shopEmojisHelp => 'चैट के लिए एनिमेटेड इमोजी। सेट खरीदें और दोस्तों को भेजें।';

  @override
  String get shopCollectionsHelp => 'केवल नया या विंटेज संग्रह बेचा जा सकता है: नया कीमत का 80% और विंटेज कीमत का 300%। घिसा, थका और जर्जर नहीं बेचे जा सकते।\n\nवस्तुओं का सेट इकट्ठा करें: वे प्रोफ़ाइल शोकेस में दिखती हैं, उपहार दी जा सकती हैं। हर वस्तु हर दिन सिक्के देती है, और पूरा सेट अलग बोनस भी देता है।\n\nवस्तु की दैनिक आय स्थिति पर निर्भर है और सामान्य राशि का हिस्सा है। नया 100% देता है। घिसा 60% देता है। थका 40% देता है। जर्जर 100% देता है। विंटेज वस्तु 200% देती है, यानी सामान्य दैनिक आय से दोगुना।\n\nपूरे सेट का बोनस तब तक वही रहता है जब तक सेट खुद विंटेज न हो जाए। सेट तब विंटेज है जब उसकी हर वस्तु विंटेज हो: बोनस तब 300% होता है, सामान्य से तीन गुना।\n\nस्थिति इस पर निर्भर करती है कि वस्तु आपके पास कब से है। नया — पहले 7 दिन। घिसा — 8वें दिन से 2 महीने। थका — 2 से 6 महीने। जर्जर — 6 महीने से 1 साल। विंटेज — 1 साल के बाद।';

  @override
  String get shopStakesHelp => 'ऊँची बाज़ियाँ अनलॉक करें। बाज़ी जितनी बड़ी, पॉट और जीत उतनी बड़ी।';

  @override
  String get inventoryTitle => 'आइटम';

  @override
  String get inventoryEmpty => 'यहाँ अभी कुछ नहीं — दुकान देखें';

  @override
  String get inventoryFrames => 'फ़्रेम';

  @override
  String get inventoryClaim => 'दावा करें';

  @override
  String get inventorySell => 'बेचें';

  @override
  String get inventoryGift => 'उपहार';

  @override
  String get messageEdited => 'संपादित';

  @override
  String get messageDeleted => 'संदेश हटा दिया गया';

  @override
  String get photo => 'फ़ोटो';

  @override
  String get camera => 'कैमरा';

  @override
  String get gallery => 'गैलरी';

  @override
  String get connectionError => 'सर्वर से कनेक्ट नहीं हो सका।';

  @override
  String get serverError => 'सर्वर त्रुटि। कृपया बाद में फिर कोशिश करें।';

  @override
  String get sessionExpired => 'सत्र समाप्त हो गया। कृपया फिर से साइन इन करें।';

  @override
  String get errNoInternet => 'इंटरनेट कनेक्शन नहीं है।';

  @override
  String get errTimeout => 'अनुरोध का समय समाप्त। कृपया फिर कोशिश करें।';

  @override
  String get errGamesUnavailable => 'गेम अस्थायी रूप से अनुपलब्ध हैं';

  @override
  String get errSettingsSaveFailed => 'सेटिंग सहेजी नहीं जा सकी';

  @override
  String get errPushPermission => 'अपने ब्राउज़र या सिस्टम सेटिंग्स में सूचनाएँ अनुमति दें।';

  @override
  String get balanceTitle => 'बैलेंस';

  @override
  String get coinBronze => 'ब्रॉन्ज़';

  @override
  String get coinSilver => 'सिल्वर';

  @override
  String get coinGold => 'गोल्ड';

  @override
  String get coinDiamond => 'डायमंड';

  @override
  String get balanceZeroBronze => '0 ब्रॉन्ज़';

  @override
  String balanceBronzes(int count) {
    return '$count ब्रॉन्ज़';
  }

  @override
  String balanceSilvers(int count) {
    return '$count सिल्वर';
  }

  @override
  String balanceGolds(int count) {
    return '$count गोल्ड';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count डायमंड';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/दिन';
  }

  @override
  String get balanceAbbrBronze => 'ब्रॉ';

  @override
  String get balanceAbbrSilver => 'सि.';

  @override
  String get balanceAbbrGold => 'गो.';

  @override
  String get commonBackHome => 'होम पर वापस';

  @override
  String get commonCopied => 'कॉपी हो गया';

  @override
  String get commonClear => 'साफ़ करें';

  @override
  String get commonTryLater => 'बाद में फिर कोशिश करें।';

  @override
  String get commonTryRefresh => 'पेज रीफ़्रेश करके देखें।';

  @override
  String get coinsTitle => 'सिक्के';

  @override
  String get coinsLoginReward => 'लॉगिन इनाम';

  @override
  String get coinsLoginAvailableToday => 'आज का इनाम उपलब्ध है';

  @override
  String get coinsLoginStreak => 'दैनिक लॉगिन स्ट्रीक';

  @override
  String get coinsFriendReward => 'मित्र इनाम';

  @override
  String get coinsTasks => 'कार्य';

  @override
  String get coinsTasksSubtitle => 'प्रोफ़ाइल, मित्रों और खेलों के इनाम';

  @override
  String get coinsTasksRewards => 'दावा करने योग्य इनाम उपलब्ध';

  @override
  String coinsFriendRewardHint(String amount) {
    return 'आपके लिंक से रजिस्टर करने पर +$amount';
  }

  @override
  String get coinsLoadRewardsFailed => 'इनाम लोड नहीं हो सके';

  @override
  String get coinsClaimReward => 'इनाम लें';

  @override
  String get coinsAlreadyClaimed => 'पहले ही ले लिया';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · आज';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · 1 दिन बाकी';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · $remaining बाकी';
  }

  @override
  String get coinsInviteFriend => 'मित्र को आमंत्रित करें';

  @override
  String coinsInviteHint(String amount) {
    return 'आपके लिंक से रजिस्टर करने वाले प्रत्येक के लिए +$amount';
  }

  @override
  String get coinsCopyLink => 'लिंक कॉपी करें';

  @override
  String get coinsHowItWorks => 'यह कैसे काम करता है';

  @override
  String get coinsHowStep1 => 'लिंक कॉपी करें और मित्र को भेजें';

  @override
  String get coinsHowStep2 => 'मित्र उस लिंक से रजिस्टर करता है';

  @override
  String coinsHowStep3(String amount) {
    return 'आपको $amount मिलता है';
  }

  @override
  String get achievementsTitle => 'उपलब्धियाँ';

  @override
  String achievementsProgress(String progress) {
    return 'प्रगति: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'फ़्रेम प्राप्त';

  @override
  String get achievementsClaimed => 'प्राप्त';

  @override
  String get achievementsOpenFrame => 'फ़्रेम खोलें';

  @override
  String friendsRemoveConfirm(String name) {
    return 'क्या आप वाकई $name को मित्रों से हटाना चाहते हैं?';
  }

  @override
  String get friendsRemoveConfirmAction => 'हटाएँ';

  @override
  String get friendsRemove => 'मित्रों से हटाएँ';

  @override
  String get friendsAcceptRequest => 'अनुरोध स्वीकार करें';

  @override
  String get friendsDeclineRequest => 'अनुरोध अस्वीकार करें';

  @override
  String get friendsCancelRequest => 'अनुरोध रद्द करें';

  @override
  String get friendsSendRequest => 'मित्र अनुरोध भेजें';

  @override
  String get friendsRequestAlreadySent => 'अनुरोध पहले ही भेजा जा चुका है';

  @override
  String get friendsIncomingStatus => 'आने वाला अनुरोध';

  @override
  String get friendsOutgoingStatus => 'भेजा गया अनुरोध';

  @override
  String get friendsNotFriends => 'मित्र नहीं';

  @override
  String get friendsCollapseSearch => 'खोज छिपाएँ';

  @override
  String get friendsExpandSearch => 'खोज दिखाएँ';

  @override
  String get friendsLoadFailed => 'मित्र लोड नहीं हो सके';

  @override
  String friendsSince(String date) {
    return 'मित्रता शुरू: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'आने वाला अनुरोध: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'भेजा गया अनुरोध: $date';
  }

  @override
  String get userInfoTitle => 'उपयोगकर्ता जानकारी';

  @override
  String profileAgeYears(int age) {
    return '$age वर्ष';
  }

  @override
  String get shopBuy => 'खरीदें';

  @override
  String get shopBuyTitle => 'खरीदें?';

  @override
  String get shopBuyStakeTitle => 'दाँव खरीदें?';

  @override
  String get shopBuyEmojiTitle => 'इमोजी खरीदें?';

  @override
  String get shopBuyCollectionTitle => 'संग्रह खरीदें?';

  @override
  String shopPrice(String price) {
    return 'कीमत: $price';
  }

  @override
  String get shopOwned => 'खरीदा गया';

  @override
  String get shopHave => 'है';

  @override
  String get shopEmpty => 'अभी खाली';

  @override
  String shopPurchased(String title) {
    return '$title खरीदा गया';
  }

  @override
  String get shopEmojiUses => 'आपको मिलेंगे: 10 उपयोग';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 उपयोग';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 उपयोग';
  }

  @override
  String get shopBuyTen => 'खरीदें · 10 पीस';

  @override
  String shopDailyIncome(String amount) {
    return 'आय: $amount';
  }

  @override
  String get shopBuyOnce => 'एक बार की खरीद';

  @override
  String get shopSellRefund => 'बिक्री संग्रह की स्थिति पर निर्भर करती है';

  @override
  String get collectionConditionNew => 'नया';

  @override
  String get collectionConditionWorn => 'घिसा';

  @override
  String get collectionConditionTired => 'थका';

  @override
  String get collectionConditionShabby => 'जर्जर';

  @override
  String get collectionConditionVintage => 'विंटेज';

  @override
  String shopCollectionAdded(String title) {
    return '$title प्रोफ़ाइल में जोड़ा गया';
  }

  @override
  String shopSetBonus(int percent) {
    return 'सेट बोनस +$percent%';
  }

  @override
  String get shopSetComplete => 'पूरा';

  @override
  String shopSetProgress(int owned, int total) {
    return 'एकत्र · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'बेचें?';

  @override
  String inventorySellDesc(String amount) {
    return 'आपको $amount मिलेगा';
  }

  @override
  String get inventoryCollectionNotSellable => 'केवल नया या विंटेज संग्रह बेचा जा सकता है।';

  @override
  String get inventoryCollectionNotSellableTitle => 'बेचा नहीं जा सकता';

  @override
  String get inventoryCollectionNotSellableHint => 'केवल नया या विंटेज आइटम बेचा जा सकता है। अवस्था बदलने के लिए अमृत का उपयोग करें।';

  @override
  String inventorySold(String amount) {
    return 'बेचा गया: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'पहले मित्र जोड़ें';

  @override
  String get inventoryGiftTitle => 'संग्रह उपहार दें?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return '«$title» को $name को उपहार दें?';
  }

  @override
  String inventoryGifted(String title) {
    return 'उपहार दिया: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'खिलाड़ी के पास पहले से यह वस्तु है';

  @override
  String get inventoryGiftSelf => 'आप खुद को उपहार नहीं दे सकते';

  @override
  String get inventoryGiftNotOwned => 'यह वस्तु आपके इन्वेंटरी में नहीं है';

  @override
  String get inventoryLoadFailed => 'वस्तुएँ लोड नहीं हो सकीं';

  @override
  String get inventoryNoCollections => 'कोई संग्रह नहीं — दुकान से खरीदें';

  @override
  String get inventoryNoEmojis => 'कोई इमोजी नहीं — दुकान से खरीदें';

  @override
  String get inventoryNoFrames => 'कोई फ़्रेम नहीं — लीग में 10 खेल जीतें (उपलब्धियाँ)';

  @override
  String get inventoryNoStakes => 'कोई खरीदे गए दाँव नहीं';

  @override
  String inventoryEmojiLeft(int count) {
    return '$count बाकी';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'आय: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'कल की आय: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'तैयार';

  @override
  String get inventoryIncomeTomorrowLabel => 'कल';

  @override
  String inventoryStakeGold(String amount) {
    return 'आप $amount गोल्ड लगा सकते हैं';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'आप $amount सिल्वर लगा सकते हैं';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return '+$amount प्राप्त';
  }

  @override
  String get chatsLoadFailed => 'चैट लोड नहीं हो सकीं';

  @override
  String get chatsLoadListFailed => 'सूची लोड नहीं हो सकी';

  @override
  String get chatsBlockedEmpty => 'सूची खाली है';

  @override
  String chatsBlockedAt(String date) {
    return 'ब्लॉक किया: $date';
  }

  @override
  String get chatsCreateFailed => 'चैट नहीं बनाई जा सकी';

  @override
  String get chatsNeedFriendsFirst => 'पहले मित्र जोड़ें, फिर चैट खोल सकते हैं।';

  @override
  String get chatsFriendsNotFound => 'मित्र नहीं मिले';

  @override
  String get chatsFindFriendHint => 'उपनाम से मित्र खोजें';

  @override
  String get chatsSelectChat => 'चैट चुनें';

  @override
  String get chatsSelectHint => 'बाएँ सूची से बातचीत चुनें';

  @override
  String get chatEditFailed => 'संदेश संपादित नहीं हो सका';

  @override
  String get chatSendFailed => 'संदेश भेजा नहीं जा सका';

  @override
  String get chatDeleteFailed => 'संदेश हटाया नहीं जा सका';

  @override
  String get chatEmojiSendFailed => 'इमोजी भेजा नहीं जा सका';

  @override
  String get chatLoadFailed => 'संदेश लोड नहीं हो सके';

  @override
  String get chatBackToGame => 'खेल पर वापस';

  @override
  String get chatBackToChats => 'चैट पर वापस';

  @override
  String get chatActions => 'चैट क्रियाएँ';

  @override
  String get chatAutoTranslate => 'Auto-translate';

  @override
  String get chatScrollToEnd => 'बातचीत के अंत तक';

  @override
  String chatReplyingTo(String name) {
    return '$name को उत्तर';
  }

  @override
  String get chatGift => 'उपहार';

  @override
  String get chatCollection => 'संग्रह';

  @override
  String get chatGiftCollection => 'उपहार · संग्रह';

  @override
  String get chatThisUser => 'इस उपयोगकर्ता';

  @override
  String get gamesLobbyLoadFailed => 'लॉबी लोड नहीं हो सकी।';

  @override
  String get gamesTapChangeStake => 'दाँव बदलने के लिए टैप करें';

  @override
  String get gamesTapChangeTurnTime => 'चाल का समय बदलने के लिए टैप करें';

  @override
  String get gamesTapChangeGrid => 'ग्रिड आकार बदलने के लिए टैप करें';

  @override
  String get gamesSwapSidesHint => 'पहली चाल के बाद O, X बन सकता है';

  @override
  String get gamesNoCenterHint => 'पहली चाल केंद्र में नहीं हो सकती';

  @override
  String get lobbyInviteSentShort => 'भेजा गया';

  @override
  String get lobbySearchShort => 'खोज';

  @override
  String get lobbySearchPlayers => 'खिलाड़ी खोजें';

  @override
  String get lobbyInviteDeclinedShort => 'अस्वीकृत';

  @override
  String get lobbyInvitesSentWaiting => 'निमंत्रण भेजे गए। उत्तर की प्रतीक्षा।';

  @override
  String get lobbyLinkCopiedHint => 'इसे चैट या मित्र के संदेश में चिपकाएँ';

  @override
  String get lobbyCopyLinkHint => 'लिंक क्लिपबोर्ड पर कॉपी करें';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name आपको खेलने के लिए आमंत्रित करता है';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name जीत गया';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'समय समाप्त। $name जीत गया';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds से';
  }

  @override
  String get adminTitle => 'एडमिन';

  @override
  String get tournamentsTitle => 'टूर्नामेंट';

  @override
  String get profileAgeInvalid => '1 से 111 तक आयु दर्ज करें';

  @override
  String get profileSaveFailed => 'प्रोफ़ाइल सहेजी नहीं जा सकी';

  @override
  String get profileNameHint => 'लैटिन अक्षर, अंक, _ अधिकतम 10 वर्ण';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => '1 से 111';

  @override
  String get profileAboutHint => 'अधिकतम 100 वर्ण (वैकल्पिक)';

  @override
  String get profileProcessingPhoto => 'फ़ोटो प्रोसेस हो रही है…';

  @override
  String get profileCropTitle => 'अवतार क्षेत्र चुनें';

  @override
  String get profileCropHint => 'फ़ोटो ज़ूम करें और घुमाएँ';

  @override
  String get profileApply => 'लागू करें';

  @override
  String get profilePreparing => 'तैयारी…';

  @override
  String get profileGalleryTitle => 'फ़ोटो';

  @override
  String get profileGalleryAdd => 'फ़ोटो जोड़ें';

  @override
  String get profileMakePrimary => 'मुख्य बनाएँ';

  @override
  String get profilePhotoDelete => 'फ़ोटो हटाएँ';

  @override
  String get profilePhotosLimit => 'अधिकतम 3 फ़ोटो अपलोड कर सकते हैं';

  @override
  String get profilePhotosEmpty => 'अभी कोई फ़ोटो नहीं';

  @override
  String get profilePhotoUploadFailed => 'फ़ोटो अपलोड नहीं हो सकी';

  @override
  String get profilePhotoDeleteFailed => 'फ़ोटो हटाई नहीं जा सकी';

  @override
  String get profilePhotoTooLarge => 'फ़ोटो बहुत बड़ी है';

  @override
  String get profileSetPrimaryFailed => 'मुख्य नहीं बनाई जा सकी';

  @override
  String timeSecondsShort(int seconds) {
    return '$seconds से';
  }

  @override
  String get timeOneMin => '1 मि';

  @override
  String get timeTenMin => '10 मि';

  @override
  String rulesIntro(String grid) {
    return '$grid बोर्ड पर टिक-टैक-टो। बारी-बारी से; X पहले।';
  }

  @override
  String rulesWin(int n) {
    return 'जीत: क्षैतिज, लंबवत या तिरछे $n एक पंक्ति में लगाएँ।';
  }

  @override
  String get rulesNoTimeLimit => 'चाल पर समय सीमा नहीं।';

  @override
  String rulesTurnTime(String time) {
    return 'चाल का समय: $time. समय खत्म होना हार है।';
  }

  @override
  String rulesStake(String stake) {
    return 'दाँव: $stake. इतने सिक्कों पर खेल है।';
  }

  @override
  String get rulesSwap => 'पक्ष बदल: X की पहली चाल के बाद O, X से स्थान बदल सकता है।';

  @override
  String get rulesNoCenter => 'केंद्र वर्जित: X पहली चाल में केंद्र में नहीं खेल सकता।';

  @override
  String get collectionSetLegends => 'किंवदंतियाँ';

  @override
  String get collectionSetSpace => 'अंतरिक्ष';

  @override
  String get collectionSetGems => 'रत्न';

  @override
  String get collectionSetParty => 'पार्टी';

  @override
  String get collectionSetNature => 'प्रकृति';

  @override
  String get collectionSetAdventures => 'साहसिक';

  @override
  String collectionCardMeta(String amount) {
    return 'संग्रह · प्रदर्शन · उपहार · बिक्री · +$amount';
  }

  @override
  String get coinsDayOne => 'दिन';

  @override
  String get coinsDayFew => 'दिन';

  @override
  String get coinsDayMany => 'दिन';

  @override
  String get giftFriendTitle => 'मित्र को उपहार दें';

  @override
  String photoCount(int count) {
    return 'फ़ोटो ($count)';
  }

  @override
  String photoCountWithText(int count, String text) {
    return 'फ़ोटो ($count): $text';
  }

  @override
  String photoWithText(String text) {
    return 'फ़ोटो: $text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count इमोजी · $price';
  }

  @override
  String get chatsExpandPanel => 'पैनल फैलाएँ';

  @override
  String get chatsCollapsePanel => 'पैनल समेटें';

  @override
  String get chatReplySourceMissing => 'मूल संदेश नहीं मिला';

  @override
  String shopStakeTitleSilver(int n) {
    return 'दांव $n सिल्वर';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'दांव $n गोल्ड';
  }

  @override
  String shopStakeDescSilver(int n) {
    return '$n सिल्वर दांव अनलॉक करें';
  }

  @override
  String shopStakeDescGold(int n) {
    return '$n गोल्ड दांव अनलॉक करें';
  }

  @override
  String get chatReplySelf => 'स्वयं';

  @override
  String get chatReplyPeer => 'दूसरे व्यक्ति';

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
  String get statsTitle => 'आँकड़े';

  @override
  String get statsLoadFailed => 'आँकड़े लोड नहीं हो सके';

  @override
  String get statsAllGames => 'सभी खेल';

  @override
  String get statsEmptyTitle => 'अभी कोई मैच नहीं खेला गया';

  @override
  String get statsEmptyHint => 'यहाँ आँकड़े देखने के लिए अपना पहला गेम खेलें।';

  @override
  String get statsWins => 'जीत';

  @override
  String get statsDraws => 'ड्रॉ';

  @override
  String get statsLosses => 'हार';

  @override
  String get statsWinRate => 'जीत दर';

  @override
  String get statsTopWon => 'सबसे अधिक जीत के विरुद्ध';

  @override
  String get statsTopDrawn => 'सबसे अधिक ड्रॉ के साथ';

  @override
  String get statsTopLost => 'सबसे अधिक हार के विरुद्ध';

  @override
  String get statsTimePlayed => 'खेल का समय';

  @override
  String get statsYourScore => 'आपका स्कोर';

  @override
  String get profileShowStats => 'आँकड़े दिखाएँ';

  @override
  String get statsDurationZeroMinutes => '0 मि';

  @override
  String get gameYouWonOpponentForfeit => 'प्रतिद्वंद्वी हार मान गया। आप जीत गए!';

  @override
  String get lobbyLeaveTitle => 'लॉबी छोड़ें?';

  @override
  String get lobbyLeaveConfirm => 'बाहर निकलने के बाद लॉबी हटा दी जाएगी। आमंत्रित मित्रों को अस्वीकृति मिलेगी।';

  @override
  String get lobbyLeave => 'छोड़ें';

  @override
  String statsDurationHours(int hours) {
    return '$hours घं';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours घं $minutes मि';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes मि';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'आपने हार मान ली। $name जीत गया';
  }

  @override
  String get supportTitle => 'सहायता';

  @override
  String get supportUnavailable => 'सहायता उपलब्ध नहीं है';

  @override
  String get supportOpenFailed => 'सहायता चैट नहीं खुल सकी';

  @override
  String coinsGrantedTitle(int amount) {
    return 'आपको $amount सिक्के जमा किए गए';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return '$amount सिक्के काटे गए';
  }

  @override
  String get coinsCreditCardTitle => 'आपको सिक्के जमा किए गए';

  @override
  String get coinsClaim => 'प्राप्त करें';

  @override
  String get durakActionPass => 'पास';

  @override
  String get durakRoleTook => 'ले लिया';

  @override
  String get durakRoleBeats => 'काटता है';

  @override
  String get durakRoleThrowIn => 'फेंकना';

  @override
  String get durakRoleTurn => 'चाल';

  @override
  String get durakRoleDefends => 'बचाव';

  @override
  String get durakStatusTaking => 'ले रहा हूँ';

  @override
  String get durakHintDefenderTurn => 'रक्षक की बारी';

  @override
  String get gameYouEliminated => 'आप बाहर हो गए';

  @override
  String gameYouPlaced(int place) {
    return 'आपका स्थान $place';
  }

  @override
  String get gameOverNeutral => 'खेल समाप्त';

  @override
  String gameTurnOf(String name) {
    return '$name की बारी';
  }

  @override
  String get chatGroupTooltip => 'समूह चैट';

  @override
  String get lobbyChatNotReady => 'लॉबी चैट अभी तैयार नहीं';

  @override
  String get chatsGroupChat => 'समूह चैट';

  @override
  String chatsMembersCount(int count) {
    return 'सदस्य: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count लोग';
  }

  @override
  String get chatsYouSuffix => '(आप)';

  @override
  String get chatTitleDurak3 => 'दुरक · 3 खिलाड़ी';

  @override
  String get chatTitleDurak4 => 'दुरक · 4 खिलाड़ी';

  @override
  String get rulesTttUltimate => 'अल्टीमेट: नौ 3×3 मिनी-बोर्ड। चाल विरोधी को उस मिनी-बोर्ड पर भेजती है। मेटा-बोर्ड पर रेखा पूरी करें।';

  @override
  String get rulesTttMulti3 => '3 खिलाड़ी: 3×3 बोर्ड, तीन खिलाड़ी (X, O, △)। अपनी चिह्नों की रेखा पूरी करें।';

  @override
  String get rulesTttMulti4 => '4 खिलाड़ी: 4×4 बोर्ड, चार खिलाड़ी (X, O, △, □)। अपनी चिह्नों की रेखा पूरी करें।';

  @override
  String get adminUsersTab => 'उपयोगकर्ता';

  @override
  String get adminSupportTab => 'सहायता';

  @override
  String get adminSearchHint => 'ईमेल या नाम से खोजें';

  @override
  String get adminRoleAdmins => 'एडमिन';

  @override
  String get adminRoleUsers => 'उपयोगकर्ता';

  @override
  String get adminRoleAll => 'सभी भूमिकाएँ';

  @override
  String get adminStatusFrozen => 'जमे हुए';

  @override
  String get adminStatusActive => 'सक्रिय';

  @override
  String get adminStatusAny => 'कोई भी स्थिति';

  @override
  String get adminOrderDesc => 'घटते क्रम';

  @override
  String get adminOrderAsc => 'बढ़ते क्रम';

  @override
  String adminLoadFailed(String error) {
    return 'लोड नहीं हो सका: $error';
  }

  @override
  String get adminUsersEmpty => 'कोई उपयोगकर्ता नहीं';

  @override
  String get adminSortLastSeen => 'अंतिम विज़िट के अनुसार';

  @override
  String get adminSortEmail => 'ईमेल के अनुसार';

  @override
  String get adminSortCreated => 'पंजीकरण तिथि के अनुसार';

  @override
  String adminBronzeBalance(int amount) {
    return '$amount कांस्य';
  }

  @override
  String get adminRevokeAdmin => 'एडमिन हटाएँ';

  @override
  String get adminGrantAdmin => 'एडमिन बनाएँ';

  @override
  String get adminAdminRevoked => 'एडमिन अधिकार हटाए गए';

  @override
  String get adminAdminGranted => 'एडमिन अधिकार दिए गए';

  @override
  String get adminGrantCoins => 'सिक्के दें';

  @override
  String get adminWriteSupport => 'सहायता के रूप में लिखें';

  @override
  String get adminUnfreeze => 'अनफ़्रीज़';

  @override
  String get adminFreeze => 'फ़्रीज़';

  @override
  String get adminUnfrozen => 'अनफ़्रीज़ हो गया';

  @override
  String get adminFrozenDone => 'फ़्रीज़ हो गया';

  @override
  String get adminResetPassword => 'पासवर्ड रीसेट';

  @override
  String get adminCoinsAmountHint => 'मात्रा (ऋण = कटौती)';

  @override
  String get adminReasonOptional => 'कारण (वैकल्पिक)';

  @override
  String get adminGrantSent => 'कार्ड सहायता चैट में भेजा गया';

  @override
  String adminCoinsDebited(int amount) {
    return '$amount कांस्य काटे गए';
  }

  @override
  String get adminGrantVerb => 'दें';

  @override
  String get adminNewPasswordHint => 'नया पासवर्ड (कम से कम 6)';

  @override
  String get adminPasswordReset => 'पासवर्ड रीसेट हो गया';

  @override
  String get adminResetVerb => 'रीसेट';

  @override
  String adminShortError(String error) {
    return 'त्रुटि: $error';
  }

  @override
  String get adminSupportEmpty => 'कोई सहायता अनुरोध नहीं';

  @override
  String get adminUserFallback => 'उपयोगकर्ता';

  @override
  String get apiErrTooManyRequests => 'बहुत अधिक अनुरोध। बाद में कोशिश करें।';

  @override
  String get apiErrMoveConflict => 'चाल का टकराव। फिर कोशिश करें।';

  @override
  String get shopElixirs => 'Elixirs';

  @override
  String get shopElixirsSubtitle => 'Rejuvenate, age, or speed up collections';

  @override
  String get shopElixirsHelp => 'Three shelves: rejuvenation, aging, and acceleration. Each has six elixirs, one per collection set. An elixir works only on its own set.\n\nRejuvenation makes a collection one step newer, and never newer than new. Aging makes it one step older, and never older than shabby. Acceleration is only for a shabby item: three months left until vintage, once. An elixir never grants vintage by itself.\n\nA bought elixir stays in Items. Use it from the collection card or from the elixir card. Each use spends one.';

  @override
  String get elixirGroupRejuvenate => 'यौवन';

  @override
  String get elixirGroupAge => 'बुढ़ापा';

  @override
  String get elixirGroupAccelerate => 'त्वरण';

  @override
  String get elixirEffectRejuvenate => 'यौवन';

  @override
  String get elixirEffectAge => 'बुढ़ापा';

  @override
  String get elixirEffectAccelerate => 'त्वरण';

  @override
  String get elixirAdjCelebration => 'उत्सव';

  @override
  String get elixirAdjNature => 'प्राकृतिक';

  @override
  String get elixirAdjLegends => 'पौराणिक';

  @override
  String get elixirAdjCosmic => 'ब्रह्मांडीय';

  @override
  String get elixirAdjAdventure => 'रोमांच';

  @override
  String get elixirAdjJewels => 'कीमती';

  @override
  String elixirName(String adjective, String effect) {
    return '$adjective $effect अमृत';
  }

  @override
  String get elixirHelpRejuvenate => 'Makes the collection one step newer. Not newer than new.';

  @override
  String get elixirHelpAge => 'Makes the collection one step older. Not older than shabby.';

  @override
  String get elixirHelpAccelerate => 'Shabby only. Three months left until vintage, once.';

  @override
  String get elixirUseRejuvenate => 'जवान करें';

  @override
  String get elixirUseAge => 'बूढ़ा करें';

  @override
  String get elixirUseAccelerate => 'तेज़ करें';

  @override
  String get elixirUse => 'उपयोग करें';

  @override
  String collectionLeftDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन',
      one: '$count दिन',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count घंटे',
      one: '$count घंटा',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मिनट',
      one: '$count मिनट',
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
