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
  String get settingsLanguageRu => 'Русский';

  @override
  String get settingsLanguageEn => 'English';

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
  String get gamesTitle => 'Games';

  @override
  String get gamesFindMatch => 'Find a game';

  @override
  String get gamesMyTurn => 'Your turn';

  @override
  String get gamesWaiting => 'Waiting';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get chatsEmpty => 'No chats yet.\nTap the icon at the top right to pick a friend and start a conversation.';

  @override
  String get chatsNewChat => 'New chat';

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
  String get profileTitle => 'Profile';

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
  String get sessionExpired => 'Session expired. Sign in again.';
}
