import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Home';

  @override
  String get navProfile => 'Profile';

  @override
  String get navFriends => 'Friends';

  @override
  String get navChats => 'Chats';

  @override
  String get navGames => 'Games';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsAddBotsTitle => 'Add bots after 30s';

  @override
  String get settingsAddBotsSubtitle => 'In matchmaking: if no opponent is found in 30 seconds, the game starts with a bot (stake resets to 1 bronze)';

  @override
  String get settingsFriendsOnlyTitle => 'Messages from friends only';

  @override
  String get settingsFriendsOnlySubtitle => 'Non-friends can only send emojis. If spam is a problem, temporarily block the user.';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPushChat => 'Chat';

  @override
  String get settingsPushFriends => 'Friends';

  @override
  String get settingsPushGames => 'Games';

  @override
  String get settingsPushRewards => 'Rewards';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Enter email or username and password';

  @override
  String get loginEmailLabel => 'Email or username';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginNoAccount => 'No account? Sign up';

  @override
  String get loginEmailRequired => 'Enter email or username';

  @override
  String get loginPasswordRequired => 'Enter password';

  @override
  String get loginTooltip => 'Sign in';

  @override
  String get logoutTooltip => 'Sign out';

  @override
  String get registerTitle => 'Sign up';

  @override
  String get registerSubtitle => 'Create an account to play';

  @override
  String get registerNameLabel => 'Name (username)';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'Password';

  @override
  String get registerSubmit => 'Sign up';

  @override
  String get registerHaveAccount => 'Already have an account? Sign in';

  @override
  String get registerNameRequired => 'Enter a name';

  @override
  String get registerNameNoSpaces => 'Name cannot contain spaces';

  @override
  String get registerNameMax => 'Maximum 20 characters';

  @override
  String get registerNameHint => 'Up to 20 characters';

  @override
  String get registerEmailRequired => 'Enter email';

  @override
  String get registerEmailInvalid => 'Invalid email';

  @override
  String get registerPasswordHint => 'At least 6 characters';

  @override
  String get registerPasswordMin => 'Password must be at least 6 characters';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonReply => 'Reply';

  @override
  String get commonSend => 'Send';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonError => 'Error';

  @override
  String get commonOnline => 'online';

  @override
  String get commonOffline => 'offline';

  @override
  String get commonOnlineCap => 'Online';

  @override
  String get commonUser => 'User';

  @override
  String get commonPlayer => 'Player';

  @override
  String get commonAboutMe => 'About me';

  @override
  String get commonBack => 'Back';

  @override
  String get commonAccept => 'Accept';

  @override
  String get commonDecline => 'Decline';

  @override
  String get commonCreating => 'Creating…';

  @override
  String get commonSearching => 'Searching…';

  @override
  String get commonInsufficientCoins => 'Not enough coins';

  @override
  String get commonNotFound => 'Not found';

  @override
  String get commonServerErrorShort => 'Server error';

  @override
  String get commonForbidden => 'Access denied';

  @override
  String get commonUserBlocked => 'User is blocked';

  @override
  String get commonUserNotFound => 'User not found';

  @override
  String get commonGenericError => 'Something went wrong. Please try again.';

  @override
  String get timeJustNow => 'just now';

  @override
  String get timeYesterday => 'yesterday';

  @override
  String timeMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count d ago';
  }

  @override
  String get timeWeekAgo => 'a week ago';

  @override
  String timeWeeksAgo(int count) {
    return '$count wk ago';
  }

  @override
  String get timeMonthAgo => 'a month ago';

  @override
  String timeMonthsAgo(int count) {
    return '$count mo ago';
  }

  @override
  String get timeYearAgo => 'a year ago';

  @override
  String timeYearsAgo(int count) {
    return '$count yr ago';
  }

  @override
  String get weekdaySun => 'Sun';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get homeAchievements => 'Achievements';

  @override
  String get homeAchievementsSubtitle => 'Your game results';

  @override
  String get homeAchievementsRewards => 'Rewards available to claim';

  @override
  String get homeCoins => 'Coins';

  @override
  String get homeCoinsSubtitle => 'Balance and rewards';

  @override
  String get homeCoinsDailyReward => 'Daily login reward available';

  @override
  String get homeItems => 'Items';

  @override
  String get homeItemsInventory => 'Your inventory';

  @override
  String get homeItemsGifted => 'Someone gifted you a collection';

  @override
  String get homeItemsIncome => 'Collection income ready to claim';

  @override
  String get homeShop => 'Shop';

  @override
  String get homeShopSubtitle => 'Emojis, stakes, collections';

  @override
  String get gamesTitle => 'Games';

  @override
  String get gamesFindMatch => 'Find a game';

  @override
  String get gamesMyTurn => 'Your turn';

  @override
  String get gamesWaiting => 'Waiting';

  @override
  String get gamesLobbyTab => 'Lobby';

  @override
  String get gamesTicTacToe => 'Tic-tac-toe';

  @override
  String get gamesRules => 'Rules';

  @override
  String get gamesRulesTitle => 'Game rules';

  @override
  String get gamesCreate => 'Create game';

  @override
  String get gamesJoin => 'Join';

  @override
  String get gamesOpponentTurn => 'Opponent\'s turn';

  @override
  String get gamesCurrentGame => 'Current game';

  @override
  String get gamesInvitedYou => 'You were invited';

  @override
  String get gamesTurnTime => 'Turn time';

  @override
  String get gamesGridSize => 'Grid size';

  @override
  String get gamesSwapSides => 'Side swap';

  @override
  String get gamesNoCenter => 'No center start';

  @override
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Private game';

  @override
  String get lobbySearchingOpponent => 'Looking for an opponent…';

  @override
  String get lobbyWaitingJoin => 'Waiting for someone to tap “Find a game” or “Join”';

  @override
  String get lobbyInviteTitle => 'Game invite';

  @override
  String get lobbyInvitedToPlay => 'You were invited to play';

  @override
  String get lobbyEnterGame => 'Enter game';

  @override
  String get lobbyInvite => 'Invite';

  @override
  String get lobbyInviteSent => 'Invite sent';

  @override
  String get lobbyCopyLink => 'Share game link';

  @override
  String get lobbyLinkCopied => 'Link copied';

  @override
  String get lobbyNoFriendsOnline => 'No friends online. Share the game link above or wait until friends come online.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Opponent';

  @override
  String get gameYouWon => 'You won!';

  @override
  String get gameYouWonOpponentLeft => 'You won — opponent left';

  @override
  String get gameYouWonOpponentTimeout => 'You won — opponent ran out of time';

  @override
  String get gameDraw => 'Draw';

  @override
  String get gameExitTitle => 'Leave game';

  @override
  String get gameExitConfirm => 'If you leave, you will lose. Leave anyway?';

  @override
  String get gameStay => 'Stay';

  @override
  String get gameLeave => 'Leave';

  @override
  String get gameSurrender => 'Surrender';

  @override
  String get gameSurrenderTitle => 'Surrender?';

  @override
  String get gameSurrenderConfirm => 'If you surrender, you will lose. Surrender?';

  @override
  String get gameOfferDraw => 'Offer draw';

  @override
  String get gameOfferDrawTitle => 'Offer a draw?';

  @override
  String get gameOfferDrawConfirm => 'Send a draw offer to your opponent?';

  @override
  String get gameAcceptDrawTitle => 'Accept draw?';

  @override
  String get gameAcceptDrawConfirm => 'Your opponent offers a draw. Accept?';

  @override
  String get gameDrawOffered => 'Waiting for reply';

  @override
  String get gameConnecting => 'Connecting to game…';

  @override
  String get gameWaitingOpponent => 'Waiting for opponent';

  @override
  String get gameRematchOffer => 'Opponent offers a rematch';

  @override
  String get gameRematchDeclined => 'Opponent declined the rematch';

  @override
  String get gameRematch => 'Rematch';

  @override
  String get gameOtherOpponent => 'Other opponent';

  @override
  String get gameSwapSidesAction => 'Swap sides';

  @override
  String get gameWriteMessage => 'Write a message';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get chatsEmpty => 'No chats yet.\nTap the icon at the top right to pick a friend and start a conversation.';

  @override
  String get chatsNewChat => 'New chat';

  @override
  String get chatsNoMessages => 'No messages';

  @override
  String get chatsClearTitle => 'Clear conversation?';

  @override
  String get chatsClearDesc => 'The chat will be deleted permanently.';

  @override
  String get chatsClearConfirm => 'Clear';

  @override
  String get chatsBlockTitle => 'Block this user?';

  @override
  String get chatsBlockDesc => 'You will no longer be able to message each other. The chat and friendship will be removed.';

  @override
  String get chatsBlockConfirm => 'Block';

  @override
  String get chatsBlockedUsers => 'Blocked users';

  @override
  String get chatsUnblock => 'Unblock';

  @override
  String get chatDialog => 'Chat';

  @override
  String get chatEmpty => 'No messages yet.\nSend the first one.';

  @override
  String get chatMessageHint => 'Message';

  @override
  String get chatPaste => 'Paste';

  @override
  String get chatEmoji => 'Emojis';

  @override
  String get chatBuyEmojiHint => 'Buy emojis in the shop on the home screen';

  @override
  String get chatEditing => 'Editing';

  @override
  String get chatToday => 'Today';

  @override
  String get chatYesterday => 'Yesterday';

  @override
  String get chatFriendsOnly => 'Text for friends only';

  @override
  String get emojiGroupEmotions => 'Emotions';

  @override
  String get emojiGroupGame => 'Gaming';

  @override
  String get emojiGroupFlags => 'Flags';

  @override
  String get emojiGroupAnimals => 'Animals';

  @override
  String get emojiGroupFood => 'Food';

  @override
  String get emojiGroupTravel => 'Travel';

  @override
  String get emojiGroupParty => 'Celebration';

  @override
  String get emojiGroupObjects => 'Objects';

  @override
  String get friendsTitle => 'Friends';

  @override
  String get friendsTabFriends => 'Friends';

  @override
  String get friendsTabIncoming => 'Incoming';

  @override
  String get friendsTabOutgoing => 'Outgoing';

  @override
  String get friendsAdd => 'Add friend';

  @override
  String get friendsRequestSent => 'Request sent';

  @override
  String get friendsFindTab => 'Find friend';

  @override
  String get friendsSearchHint => 'Search by username';

  @override
  String get friendsSearchPrompt => 'Use search to find new friends';

  @override
  String get friendsNothingFound => 'Nothing found';

  @override
  String get friendsEmpty => 'You have no friends yet';

  @override
  String get friendsNoIncoming => 'No incoming requests';

  @override
  String get friendsNoOutgoing => 'No outgoing requests';

  @override
  String get friendsAlreadyFriends => 'Already friends';

  @override
  String get friendsRemoveTitle => 'Remove from friends?';

  @override
  String get friendsRemoved => 'Removed from friends';

  @override
  String get friendsRequestAccepted => 'Request accepted';

  @override
  String get friendsRequestDeclined => 'Request declined';

  @override
  String get friendsRequestCancelled => 'Request cancelled';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSignInPrompt => 'Sign in to your account';

  @override
  String get profileSignInHint => 'To set up your personal profile';

  @override
  String get profileEdit => 'Edit';

  @override
  String get profileCollections => 'Collections';

  @override
  String get profileAge => 'Age';

  @override
  String get profileGender => 'Gender';

  @override
  String get profileGenderUnset => 'Not set';

  @override
  String get profileGenderMale => 'Male';

  @override
  String get profileGenderFemale => 'Female';

  @override
  String get profileAvatar => 'Avatar';

  @override
  String get profileUploadPhoto => 'Upload photo';

  @override
  String get profileChangePhoto => 'Change photo';

  @override
  String get shopTitle => 'Shop';

  @override
  String get shopEmojis => 'Emojis';

  @override
  String get shopEmojisSubtitle => 'Animated emojis for chat';

  @override
  String get shopCollections => 'Collections';

  @override
  String get shopCollectionsSubtitle => 'Profile showcase, gifts and income';

  @override
  String get shopStakes => 'Stakes';

  @override
  String get shopStakesSubtitle => 'Unlock silver stakes';

  @override
  String get inventoryTitle => 'Items';

  @override
  String get inventoryEmpty => 'Nothing here yet — check the shop';

  @override
  String get inventoryFrames => 'Frames';

  @override
  String get inventoryClaim => 'Claim';

  @override
  String get inventorySell => 'Sell';

  @override
  String get inventoryGift => 'Gift';

  @override
  String get messageEdited => 'edited';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get photo => 'Photo';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get connectionError => 'Could not connect to the server.';

  @override
  String get serverError => 'Server error. Please try again later.';

  @override
  String get sessionExpired => 'Session expired. Please sign in again.';

  @override
  String get errNoInternet => 'No internet connection.';

  @override
  String get errTimeout => 'Request timed out. Please try again.';

  @override
  String get errGamesUnavailable => 'Games are temporarily unavailable';

  @override
  String get errSettingsSaveFailed => 'Could not save setting';

  @override
  String get errPushPermission => 'Allow notifications in your browser or system settings.';

  @override
  String get balanceTitle => 'Balance';

  @override
  String get coinBronze => 'Bronze';

  @override
  String get coinSilver => 'Silver';

  @override
  String get coinGold => 'Gold';

  @override
  String get coinDiamond => 'Diamond';

  @override
  String get balanceZeroBronze => '0 bronze';

  @override
  String balanceBronzes(int count) {
    return '$count bronze';
  }

  @override
  String balanceSilvers(int count) {
    return '$count silver';
  }

  @override
  String balanceGolds(int count) {
    return '$count gold';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count diamonds';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount per day';
  }

  @override
  String get balanceAbbrBronze => 'br';

  @override
  String get balanceAbbrSilver => 's.';

  @override
  String get balanceAbbrGold => 'g.';

  @override
  String get commonBackHome => 'Back to home';

  @override
  String get commonCopied => 'Copied';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonTryLater => 'Please try again later.';

  @override
  String get commonTryRefresh => 'Try refreshing the page.';

  @override
  String get coinsTitle => 'Coins';

  @override
  String get coinsLoginReward => 'Login reward';

  @override
  String get coinsLoginAvailableToday => 'Today\'s reward available';

  @override
  String get coinsLoginStreak => 'Daily login streak';

  @override
  String get coinsFriendReward => 'Friend reward';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount for signing up via your link';
  }

  @override
  String get coinsLoadRewardsFailed => 'Could not load rewards';

  @override
  String get coinsClaimReward => 'Claim reward';

  @override
  String get coinsAlreadyClaimed => 'Already claimed';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · today';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · 1 day left';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · $remaining left';
  }

  @override
  String get coinsInviteFriend => 'Invite a friend';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount for each person who signs up via your link';
  }

  @override
  String get coinsCopyLink => 'Copy link';

  @override
  String get coinsHowItWorks => 'How it works';

  @override
  String get coinsHowStep1 => 'Copy the link and send it to a friend';

  @override
  String get coinsHowStep2 => 'Your friend signs up via that link';

  @override
  String coinsHowStep3(String amount) {
    return 'You receive $amount';
  }

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String achievementsProgress(String progress) {
    return 'Progress: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Frame claimed';

  @override
  String get achievementsClaimed => 'Claimed';

  @override
  String get achievementsOpenFrame => 'Open frame';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Are you sure you want to remove $name from friends?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Remove';

  @override
  String get friendsRemove => 'Remove from friends';

  @override
  String get friendsAcceptRequest => 'Accept request';

  @override
  String get friendsDeclineRequest => 'Decline request';

  @override
  String get friendsCancelRequest => 'Cancel request';

  @override
  String get friendsSendRequest => 'Send friend request';

  @override
  String get friendsRequestAlreadySent => 'Request already sent';

  @override
  String get friendsIncomingStatus => 'Incoming request';

  @override
  String get friendsOutgoingStatus => 'Outgoing request';

  @override
  String get friendsNotFriends => 'Not friends';

  @override
  String get friendsCollapseSearch => 'Collapse search';

  @override
  String get friendsExpandSearch => 'Show search';

  @override
  String get friendsLoadFailed => 'Could not load friends';

  @override
  String friendsSince(String date) {
    return 'Friends since: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Incoming request: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Outgoing request: $date';
  }

  @override
  String get userInfoTitle => 'User info';

  @override
  String profileAgeYears(int age) {
    return '$age years';
  }

  @override
  String get shopBuy => 'Buy';

  @override
  String get shopBuyTitle => 'Buy?';

  @override
  String get shopBuyStakeTitle => 'Buy stake?';

  @override
  String get shopBuyEmojiTitle => 'Buy emoji?';

  @override
  String get shopBuyCollectionTitle => 'Buy collection?';

  @override
  String shopPrice(String price) {
    return 'Price: $price';
  }

  @override
  String get shopOwned => 'Owned';

  @override
  String get shopEmpty => 'Nothing here yet';

  @override
  String shopPurchased(String title) {
    return '$title purchased';
  }

  @override
  String get shopEmojiUses => 'You get: 10 uses';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 uses';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 uses';
  }

  @override
  String get shopBuyTen => 'Buy · 10 pcs';

  @override
  String shopDailyIncome(String amount) {
    return 'Income: $amount';
  }

  @override
  String get shopBuyOnce => 'One-time purchase';

  @override
  String get shopSellRefund => 'Selling returns part of the cost';

  @override
  String shopCollectionAdded(String title) {
    return '$title added to profile';
  }

  @override
  String shopSetBonus(int percent) {
    return 'set bonus +$percent%';
  }

  @override
  String get shopSetComplete => 'Complete';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Collected · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Sell?';

  @override
  String inventorySellDesc(String amount) {
    return 'You will receive $amount';
  }

  @override
  String inventorySold(String amount) {
    return 'Sold: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Add friends first';

  @override
  String get inventoryGiftTitle => 'Gift collection?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'Gift “$title” to $name?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Gifted: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'This user already has this collection';

  @override
  String get inventoryGiftSelf => 'You can\'t gift a collection to yourself';

  @override
  String get inventoryGiftNotOwned => 'You don\'t own this item';

  @override
  String get inventoryLoadFailed => 'Could not load items';

  @override
  String get inventoryNoCollections => 'No collections — buy them in the shop';

  @override
  String get inventoryNoEmojis => 'No emojis — buy them in the shop';

  @override
  String get inventoryNoFrames => 'No frames — win 10 league games (achievements)';

  @override
  String get inventoryNoStakes => 'No purchased stakes';

  @override
  String inventoryEmojiLeft(int count) {
    return '$count left';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Income: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Income tomorrow: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Income:';

  @override
  String get inventoryIncomeTomorrowLabel => 'Income tomorrow:';

  @override
  String inventoryStakeGold(String amount) {
    return 'You can bet $amount gold';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'You can bet $amount silver';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'Claimed +$amount';
  }

  @override
  String get chatsLoadFailed => 'Could not load chats';

  @override
  String get chatsLoadListFailed => 'Could not load list';

  @override
  String get chatsBlockedEmpty => 'List is empty';

  @override
  String chatsBlockedAt(String date) {
    return 'Blocked: $date';
  }

  @override
  String get chatsCreateFailed => 'Could not create chat';

  @override
  String get chatsNeedFriendsFirst => 'Add friends first, then you can open a chat.';

  @override
  String get chatsFriendsNotFound => 'Friends not found';

  @override
  String get chatsFindFriendHint => 'Find a friend by username';

  @override
  String get chatsSelectChat => 'Select a chat';

  @override
  String get chatsSelectHint => 'Select a conversation from the list on the left';

  @override
  String get chatEditFailed => 'Could not edit message';

  @override
  String get chatSendFailed => 'Could not send message';

  @override
  String get chatDeleteFailed => 'Could not delete message';

  @override
  String get chatEmojiSendFailed => 'Could not send emoji';

  @override
  String get chatLoadFailed => 'Could not load messages';

  @override
  String get chatBackToGame => 'Back to game';

  @override
  String get chatBackToChats => 'Back to chats';

  @override
  String get chatActions => 'Chat actions';

  @override
  String get chatScrollToEnd => 'Scroll to end';

  @override
  String chatReplyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get chatGift => 'Gift';

  @override
  String get chatCollection => 'Collection';

  @override
  String get chatGiftCollection => 'Gift · collection';

  @override
  String get chatThisUser => 'this user';

  @override
  String get gamesLobbyLoadFailed => 'Could not load lobby.';

  @override
  String get gamesTapChangeStake => 'Tap to change stake';

  @override
  String get gamesTapChangeTurnTime => 'Tap to change turn time';

  @override
  String get gamesTapChangeGrid => 'Tap to change grid size';

  @override
  String get gamesSwapSidesHint => 'O can become X after the 1st move';

  @override
  String get gamesNoCenterHint => 'First move cannot be center';

  @override
  String get lobbyInviteSentShort => 'Sent';

  @override
  String get lobbyInvitesSentWaiting => 'Invites sent. Waiting for a response.';

  @override
  String get lobbyLinkCopiedHint => 'Paste it in a chat or message to a friend';

  @override
  String get lobbyCopyLinkHint => 'Copy link to clipboard';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name invites you to play';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name won';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Time\'s up. $name won';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String get adminTitle => 'Admin';

  @override
  String get tournamentsTitle => 'Tournaments';

  @override
  String get profileAgeInvalid => 'Enter an age from 1 to 111';

  @override
  String get profileSaveFailed => 'Could not save profile';

  @override
  String get profileNameHint => 'Latin letters, digits, _ up to 10 characters';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'From 1 to 111';

  @override
  String get profileAboutHint => 'Up to 100 characters (optional)';

  @override
  String get profileProcessingPhoto => 'Processing photo…';

  @override
  String get profileCropTitle => 'Choose avatar area';

  @override
  String get profileCropHint => 'Zoom and move the photo';

  @override
  String get profileApply => 'Apply';

  @override
  String get profilePreparing => 'Preparing…';

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
    return 'Tic-tac-toe on a $grid board. Players take turns; X goes first.';
  }

  @override
  String rulesWin(int n) {
    return 'Win: get $n in a row horizontally, vertically, or diagonally.';
  }

  @override
  String get rulesNoTimeLimit => 'No time limit per turn.';

  @override
  String rulesTurnTime(String time) {
    return 'Time per turn: $time.';
  }

  @override
  String rulesStake(String stake) {
    return 'Stake: $stake. That’s how many coins the game is for.';
  }

  @override
  String get rulesSwap => 'Side swap: O may swap with X after X’s first move.';

  @override
  String get rulesNoCenter => 'No center: X cannot play in the center on the first move.';

  @override
  String get collectionSetLegends => 'Legends';

  @override
  String get collectionSetSpace => 'Space';

  @override
  String get collectionSetGems => 'Gems';

  @override
  String get collectionSetParty => 'Party';

  @override
  String get collectionSetNature => 'Nature';

  @override
  String get collectionSetAdventures => 'Adventures';

  @override
  String collectionCardMeta(String amount) {
    return 'Collection · showcase · gift · sell · +$amount';
  }

  @override
  String get coinsDayOne => 'day';

  @override
  String get coinsDayFew => 'days';

  @override
  String get coinsDayMany => 'days';

  @override
  String get giftFriendTitle => 'Gift a friend';

  @override
  String photoCount(int count) {
    return 'Photo ($count)';
  }

  @override
  String photoCountWithText(int count, String text) {
    return 'Photo ($count): $text';
  }

  @override
  String photoWithText(String text) {
    return 'Photo: $text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count emojis · $price each';
  }

  @override
  String get chatsExpandPanel => 'Expand panel';

  @override
  String get chatsCollapsePanel => 'Collapse panel';

  @override
  String get chatReplySourceMissing => 'Original message not found';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Stake $n silver';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Stake $n gold';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Unlock betting $n silver in games';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Unlock betting $n gold in games';
  }

  @override
  String get chatReplySelf => 'yourself';

  @override
  String get chatReplyPeer => 'the other person';

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
  String get forgotPasswordSubtitle => 'Enter email or username — we’ll send a code to the account email';

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
}
