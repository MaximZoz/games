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
  String get settingsAddBotsTitle => '30 सेकंड बाद बॉट जोड़ें';

  @override
  String get settingsAddBotsSubtitle => 'मैचमेकिंग में: यदि 30 सेकंड में कोई प्रतिद्वंद्वी नहीं मिलता, तो गेम बॉट के साथ शुरू होता है (दाँव 1 ब्रॉन्ज़ पर रीसेट)';

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
    return 'Версия $version';
  }

  @override
  String get appUpdateTitle => 'Доступно обновление';

  @override
  String get appUpdateBody => 'Вышла новая версия приложения. Обновитесь, чтобы продолжить.';

  @override
  String get appUpdateOk => 'Обновить';

  @override
  String get appUpdateLaterBanner => 'После партии обновим приложение';

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
  String get gameYouWon => 'आप जीत गए!';

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
  String get profileChangePhoto => 'फ़ोटो बदलें';

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
  String get shopSellRefund => 'बेचने पर लागत का 80% वापस मिलता है';

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
    return 'चाल का समय: $time.';
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
}
