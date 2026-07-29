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
  String timeMinutesAgo(Object count) {
    return '$count min ago';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count h ago';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count d ago';
  }

  @override
  String get timeWeekAgo => 'a week ago';

  @override
  String timeWeeksAgo(Object count) {
    return '$count wk ago';
  }

  @override
  String get timeMonthAgo => 'a month ago';

  @override
  String timeMonthsAgo(Object count) {
    return '$count mo ago';
  }

  @override
  String get timeYearAgo => 'a year ago';

  @override
  String timeYearsAgo(Object count) {
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
}
