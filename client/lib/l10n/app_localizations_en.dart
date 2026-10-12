import 'package:intl/intl.dart' as intl;

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
  String get settingsSoundTitle => 'Sound';

  @override
  String get settingsSoundSubtitle => 'Games and notifications';

  @override
  String get settingsSoundGames => 'Games';

  @override
  String get settingsSoundNotifications => 'Notifications';

  @override
  String get settingsSoundTurn => 'Turn';

  @override
  String get settingsHapticsTitle => 'Vibration';

  @override
  String get settingsHapticsSubtitle => 'Alerts only: messages, requests, your turn, and the timer';

  @override
  String get settingsGamepadTitle => 'Controller';

  @override
  String get settingsGamepadSubtitle => 'Gamepad for menus and matches';

  @override
  String settingsGamepadConnected(String name) {
    return 'Connected: $name';
  }

  @override
  String get settingsGamepadDisconnected => 'No gamepad found. Connect a controller and press any button.';

  @override
  String get settingsGamepadGenericName => 'Controller';

  @override
  String get settingsGamepadHelpNavigate => 'Navigate';

  @override
  String get settingsGamepadHelpConfirm => 'Select';

  @override
  String get settingsGamepadHelpBack => 'Back';

  @override
  String get settingsGamepadHelpTabs => 'Tabs';

  @override
  String get settingsGamepadHelpPlay => 'Board and hand cursor: checkers, tic-tac-toe, battleship, durak, uno, poker and backgammon';

  @override
  String get settingsGamepadHelpCards => 'Cards';

  @override
  String get settingsGamepadHelpKeyboard => 'Keyboard';

  @override
  String get settingsGamepadHelpBalance => 'Balance';

  @override
  String get settingsGamepadHelpLogout => 'Log out';

  @override
  String get settingsGamepadHelpPage => 'Page';

  @override
  String get settingsGamepadLayoutXbox => 'Xbox layout';

  @override
  String get settingsGamepadLayoutPlayStation => 'PlayStation layout';

  @override
  String get settingsGamepadLayoutNintendo => 'Nintendo layout';

  @override
  String get gamepadKeyboardTitle => 'Keyboard';

  @override
  String get gamepadKeyboardSpace => 'Space';

  @override
  String get gamepadLegendConfirm => 'Select';

  @override
  String get gamepadLegendBack => 'Back';

  @override
  String get gamepadLegendTabs => 'Tabs';

  @override
  String get gamepadLegendCycle => 'Change';

  @override
  String gamepadConnectedSnack(String name) {
    return 'Controller connected: $name';
  }

  @override
  String get settingsOfflineModeTitle => 'Network mode';

  @override
  String get settingsOfflineModeSubtitle => 'Offline: play a bot immediately, no stakes or rewards, no chats or friends. Purchases are saved and applied in online mode. Online is on when there is internet or by the user setting.';

  @override
  String get settingsModeOnline => 'Online';

  @override
  String get settingsModeOffline => 'Offline';

  @override
  String get gamesAlternateStartsHint => 'Take turns starting each game';

  @override
  String get rulesAlternateStarts => 'Who goes first alternates from game to game.';

  @override
  String get offlineBadgeTooltip => 'Offline mode';

  @override
  String get offlineModePopupTitle => 'Offline mode';

  @override
  String get offlineModePopupBody => 'Offline mode is on. Play a bot with no stakes or rewards. Chats, friends and lobby are hidden. Purchases apply in online mode.';

  @override
  String get offlineModePopupSettings => 'Settings';

  @override
  String get offlineModeOfferBody => 'No internet or the connection is very slow. You can turn on offline mode and play against a bot.';

  @override
  String get offlineModeOfferAction => 'Go offline';

  @override
  String get gamesPlay => 'Play';

  @override
  String get offlineGameTitle => 'Bot game';

  @override
  String get offlineGameHint => 'No stakes or rewards · offline only';

  @override
  String get offlineBotWon => 'Bot won';

  @override
  String get offlineBotThinking => 'Bot is thinking…';

  @override
  String get offlinePlayAgain => 'Play again';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'Take';

  @override
  String get durakActionAll => 'All';

  @override
  String get durakActionDone => 'Done';

  @override
  String get durakActionBito => 'Beat';

  @override
  String get durakHintDefend => 'Defend';

  @override
  String get durakHintDefendOrTransfer => 'Defend or transfer';

  @override
  String get durakHintOpponentDefends => 'Opponent is defending';

  @override
  String get durakHintThrowInFirst => 'Throw in cards (max 5 on the first beat)';

  @override
  String get durakHintThrowIn => 'Throw in cards or wait for the defense';

  @override
  String get durakHintOpponentThrows => 'Opponent is throwing in';

  @override
  String get durakHintTakeFollow => 'Throw in after take or tap “Done”';

  @override
  String get durakHintOpponentTakeFollow => 'Opponent may throw in after take';

  @override
  String get durakHintBito => 'Throw in a card or say “Beat”';

  @override
  String get durakHintOpponentBito => 'Opponent throws in or says “Beat”';

  @override
  String get durakHintYourAttack => 'Your turn — attack';

  @override
  String get durakHintOpponentAttack => 'Opponent is attacking';

  @override
  String get durakHintYouLost => 'You lost — you’re the fool';

  @override
  String get durakHintDrawAllOut => 'Draw — everyone went out';

  @override
  String get durakHintYouFinished => 'You’re out — waiting for the end';

  @override
  String get durakFirstLeadYou => 'You go first';

  @override
  String get durakFirstLeadOpponent => 'Opponent goes first';

  @override
  String get durakFirstLeadBot => 'Bot goes first';

  @override
  String durakFirstLeadOf(String name) {
    return '$name goes first';
  }

  @override
  String get durakFirstLeadReason => 'Lowest trump';

  @override
  String get shopPurchaseQueued => 'Purchase saved — will apply in online mode';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — purchase applied';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — purchase not applied: $reason';
  }

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
  String settingsAppVersion(String version) {
    return 'Version $version';
  }

  @override
  String get appUpdateTitle => 'Update available';

  @override
  String get appUpdateBody => 'A new version of the app is available. Please update to continue.';

  @override
  String get appUpdateWhatsNew => 'What\'s new';

  @override
  String get appUpdateOk => 'Update';

  @override
  String get appUpdateLaterBanner => 'We\'ll update the app after this game';

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
  String get apiErrWrongGameType => 'Wrong game type';

  @override
  String get apiErrWrongGameTypeOrState => 'Wrong game type or state';

  @override
  String get apiErrLobbyFull => 'The lobby is full';

  @override
  String get apiErrBadState => 'Invalid game state';

  @override
  String get apiErrIllegalMove => 'This move is not allowed';

  @override
  String get apiErrUnknownMoveType => 'Unknown move type';

  @override
  String get apiErrNoOpponents => 'No opponents';

  @override
  String get apiErrNoOpponentsRematch => 'No opponents for a rematch';

  @override
  String get apiErrAlreadyInLobby => 'You are already in this lobby';

  @override
  String get apiErrGameNotActive => 'The game is not active';

  @override
  String get apiErrNotInBattle => 'Not in the battle phase';

  @override
  String get apiErrNotInSetup => 'Not in the setup phase';

  @override
  String get apiErrAlreadyReady => 'You are already ready';

  @override
  String get apiErrAlreadyForfeited => 'You have already forfeited';

  @override
  String get apiErrYouHaveForfeited => 'You have forfeited';

  @override
  String get apiErrNoDrawOffer => 'There is no draw offer';

  @override
  String get apiErrDrawOnlyPvp => 'Draw is only available against a player';

  @override
  String get apiErrDrawOnly1v1 => 'Draw is only available in 1v1';

  @override
  String get apiErrDrawVsBot => 'Draw is not available against a bot';

  @override
  String get apiErrDrawMultiplayer => 'Draw is not available in multiplayer';

  @override
  String get apiErrDeck24TwoPlayers => 'The 24-card deck is only for 2 players';

  @override
  String get apiErrDeck52ThreeOrFour => 'The 52-card deck requires 3 or 4 players';

  @override
  String get apiErrAccountFrozen => 'The account is frozen';

  @override
  String get apiErrTurnTimeInvalid => 'Turn time must be 0, 20, 60 or 600 seconds';

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
  String get gamesDurak => 'Durak';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => 'Rotate';

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
  String get gamesPoker => 'Poker';

  @override
  String get gamesUno => 'Uno';

  @override
  String get gamesNardy => 'Backgammon';

  @override
  String get gamesNardyModeShort => 'Short';

  @override
  String get gamesNardyModeLong => 'Long';

  @override
  String get gamesCheckers => 'Checkers';

  @override
  String get gamesCheckersModeRussian => 'Russian';

  @override
  String get gamesCheckersModeEnglish => 'English';

  @override
  String get gamesCheckersModeGiveaway => 'Giveaway';

  @override
  String get gamesCheckersModeCorners => 'Corners';

  @override
  String get gamesChess => 'Chess';

  @override
  String get gamesChessModeClassic => 'Classic';

  @override
  String get gamesChessModeRapid => 'Rapid';

  @override
  String get gamesChessModeBlitz => 'Blitz';

  @override
  String get gamesChessModeBullet => 'Bullet';

  @override
  String get chessPieceQueen => 'Queen';

  @override
  String get chessPieceRook => 'Rook';

  @override
  String get chessPieceBishop => 'Bishop';

  @override
  String get chessPieceKnight => 'Knight';

  @override
  String get chessPromotionTitle => 'Pawn promotion';

  @override
  String get chessDrawStalemate => 'Draw: stalemate';

  @override
  String get chessDrawInsufficient => 'Draw: insufficient material';

  @override
  String get chessDrawRepetition => 'Draw: threefold repetition';

  @override
  String get chessDrawFiftyMove => 'Draw: fifty-move rule';

  @override
  String get chessCheck => 'Check';

  @override
  String get rulesCheckersPlayers => 'Players: 2.';

  @override
  String rulesCheckersMode(String mode) {
    return 'Mode: $mode.';
  }

  @override
  String rulesCheckersTime(String time) {
    return 'Time per move: $time. If time runs out — you lose.';
  }

  @override
  String get rulesCheckersIntro => 'An 8×8 board, 12 pieces each on dark squares. Men move forward diagonally and capture in any direction. Kings fly along the diagonal.';

  @override
  String get rulesCheckersPlay => 'Captures are mandatory. A king or man must keep capturing while a further jump is possible from the landing square — you cannot stop mid-sequence. If several directions are available, you may choose any of them; the longest capture is not required. A man that reaches the last rank becomes a king.';

  @override
  String get rulesCheckersWin => 'In Russian draughts you win by capturing all opposing pieces or leaving the opponent with no move. In giveaway the player who cannot move wins.';

  @override
  String get rulesCheckersOfflineBot => 'Offline: a game against the bot.';

  @override
  String get rulesCheckersPlayRussian => 'Russian draughts: 12 pieces each on dark squares. Men move diagonally forward and capture forward or backward. Kings fly any number of squares. Captures are mandatory: you must continue if another jump is possible, but you may choose any direction — not necessarily the longest. Win by capturing all enemy pieces or leaving the opponent with no moves.';

  @override
  String get rulesCheckersPlayEnglish => 'English draughts: 12 pieces each. Men move and capture only diagonally forward. Kings move one square diagonally in any direction. Captures are mandatory. Win by capturing all enemy pieces or leaving the opponent with no moves.';

  @override
  String get rulesCheckersPlayGiveaway => 'Giveaway: the same moves as Russian draughts, but the goal is reversed — lose all your pieces or be left with no moves. Captures are still mandatory.';

  @override
  String get rulesCheckersPlayCorners => 'Corners: pieces start in opposite corners. Move to an adjacent empty square horizontally or vertically, or jump over any piece without removing it. The goal is to move all your pieces into the opponent’s corner.';

  @override
  String get rulesCheckersPlayCornersNoReturn => 'A piece that has left its starting corner may not return there.';

  @override
  String get rulesCheckersPlayCornersLeaveHome => 'Pieces still in the home corner must leave it within the player’s first 25 moves.';

  @override
  String get rulesCheckersDrawRussian => 'A draw if the position repeats three times, or if 15 moves by each side make no progress: no capture, no man move and no promotion.';

  @override
  String get rulesCheckersDrawEnglish => 'A draw if the position repeats three times, if 40 moves by each side pass with no capture and no man move, or if each side has only one king.';

  @override
  String get rulesCheckersDrawGiveaway => 'A draw if the position repeats three times, or if 15 moves by each side in giveaway make no progress: no capture, no man move and no promotion.';

  @override
  String get rulesCheckersDrawCorners => 'A draw if the position repeats three times, or if 25 moves by each side add no piece to the target corner.';

  @override
  String get rulesChessPlayers => 'Players: 2.';

  @override
  String rulesChessMode(String mode) {
    return 'Mode: $mode.';
  }

  @override
  String get rulesChessPlayClassic => 'An 8×8 board. Each side has a king, queen, two rooks, two bishops, two knights and eight pawns. White moves first. The king moves one square, the queen along ranks, files and diagonals, the rook along ranks and files, the bishop on diagonals, the knight in an L. A pawn steps forward one square (two from its start), captures diagonally; en passant and promotion apply. Castling is allowed if the king and rook have not moved and the path is clear. Win by checkmate or if the opponent resigns.';

  @override
  String get rulesChessDrawClassic => 'A draw on stalemate, threefold repetition, the 50-move rule with no capture or pawn move, insufficient mating material, or by agreement.';

  @override
  String get rulesChessClockClassic => 'Game clock: 60+0 — 60 minutes for the whole game, no increment.';

  @override
  String get rulesChessClockRapid => 'Game clock: 10+0 — 10 minutes for the whole game, no increment.';

  @override
  String get rulesChessClockBlitz => 'Game clock: 5+0 — 5 minutes for the whole game, no increment.';

  @override
  String get rulesChessClockBullet => 'Game clock: 3+2 — 3 minutes plus 2 seconds per move.';

  @override
  String get checkersDrawRepetition => 'Draw — the position repeated three times';

  @override
  String get checkersDrawNoProgress => 'Draw — the moves do not lead to a win';

  @override
  String get checkersDrawInsufficient => 'Draw — not enough material to win';

  @override
  String get rulesNardyTitle => 'Backgammon — rules';

  @override
  String get rulesNardyPlayers => 'Players: 2.';

  @override
  String rulesNardyMode(String mode) {
    return 'Mode: $mode.';
  }

  @override
  String get rulesNardyIntro => 'A 24-point board, 15 checkers each. Roll two dice: move one checker the sum or two checkers the individual pips.';

  @override
  String get rulesNardyPlayShort => 'Short backgammon: you move toward each other and may hit lone opponent checkers. A hit checker goes to the bar and must re-enter. When all checkers are in your home board, bear them off.';

  @override
  String get rulesNardyPlayLong => 'Long backgammon: both start from the same head and move the same way. Only one checker may leave the head per turn. Hitting is not allowed. When all checkers are in the home board, bear them off.';

  @override
  String get rulesNardyWin => 'The first player to bear off all checkers wins.';

  @override
  String get rulesNardySixPrime => 'You may not seal six points in a row until at least one opposing checker has passed them.';

  @override
  String get nardyRoll => 'Roll';

  @override
  String get nardySkipTurn => 'Skip turn';

  @override
  String get nardyUndoMove => 'Undo';

  @override
  String get nardyDoneTurn => 'Done';

  @override
  String get nardyAutoConfirm => 'Auto-confirm';

  @override
  String get nardyAutoConfirmHint => 'Pass the turn automatically after all moves';

  @override
  String get nardyLayoutToggle => 'Change layout';

  @override
  String get nardyNoMoves => 'No moves';

  @override
  String get nardyYourRoll => 'Your roll';

  @override
  String get nardyPipsShort => 'Left:';

  @override
  String get nardyYouWonMars => 'You won — gammon!';

  @override
  String get nardyYouLostMars => 'You lost — gammon';

  @override
  String get rulesNardyOfflineBot => 'Offline: a game against the bot.';

  @override
  String rulesUnoPlayers(int players) {
    return 'Players: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'Play against a bot, no turn time limit.';

  @override
  String get rulesUnoIntro => 'Each player is dealt 7 cards. Play a card of the same color or the same rank (number or matching action).';

  @override
  String get rulesUnoPlay => 'Skip — the next player loses a turn. Reverse with two players acts as Skip. +2 stacks only on +2, and +4 only on +4: the penalty adds up (two +2s make the next player draw 4). A +2 cannot be played on a +4. A player who does not stack draws the whole pile and is skipped. Two identical number cards (for example two yellow 8s) are discarded together: play one and the twin is thrown automatically. Action cards (+2, skip, reverse) and wilds are never dumped as a pair.';

  @override
  String get rulesUnoWild => 'A black card sets a new color. Play +4 only if you have no card of the current color. The next player may challenge: if the +4 was legal they draw 6; if not, the +4 player draws 4 and the challenger plays.';

  @override
  String get rulesUnoDraw => 'If you have no legal card, draw one from the deck. If it matches, you may play it now or keep it and pass. You cannot draw while you still have a legal play.';

  @override
  String get rulesUnoWin => 'Heads-up is first to 100 points; with 3+ players, first to 200. A round is won by emptying your hand.';

  @override
  String get rulesUnoCall => 'When you have one card left, tap “Uno!” immediately. Opponents can catch you for forgetting Uno only after one second — then you draw 2 cards.';

  @override
  String get rulesUnoScoring => 'The first to empty their hand wins the round and scores opponents’ cards: numbers at face value, actions 20, black cards 50. Heads-up is first to 100; with 3+ players, first to 200.';

  @override
  String get unoColorRed => 'Red';

  @override
  String get unoColorYellow => 'Yellow';

  @override
  String get unoColorGreen => 'Green';

  @override
  String get unoColorBlue => 'Blue';

  @override
  String get unoDraw => 'Draw';

  @override
  String get unoKeep => 'Keep';

  @override
  String get unoSayUno => 'Uno!';

  @override
  String get unoChallengeUno => 'Challenge Uno';

  @override
  String get unoChallengeWd4 => 'Challenge +4';

  @override
  String get unoChooseColor => 'Choose a color';

  @override
  String get unoDrawPile => 'Draw pile';

  @override
  String get unoDiscardPile => 'Discard';

  @override
  String unoCardsCount(int count) {
    return 'Cards: $count';
  }

  @override
  String unoScore(int score) {
    return 'Score: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'Round $round · first to $target';
  }

  @override
  String get unoYourTurn => 'Your turn';

  @override
  String get unoWaitingTurn => 'Opponent’s turn';

  @override
  String get unoChooseColorHint => 'Choose a color for the wild card';

  @override
  String get unoWd4Hint => 'Draw 4 cards or challenge the Wild +4';

  @override
  String get unoDrawnHint => 'Play the drawn card or keep it';

  @override
  String get unoPlayHint => 'Play a matching color or value';

  @override
  String get unoDrawHint => 'No matching card — draw from the deck';

  @override
  String unoPendingDraw(int count) {
    return '+$count cards';
  }

  @override
  String get unoYouWon => 'You won the match!';

  @override
  String get unoYouLost => 'Match over';

  @override
  String get unoYouLostTimeout => 'You lost on time';

  @override
  String unoWinner(String name) {
    return 'Winner: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name wins the round';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'Next';

  @override
  String get unoRoundScoresTitle => 'Round score';

  @override
  String get unoDirectionClockwise => 'Clockwise';

  @override
  String get unoDirectionCounterclockwise => 'Counterclockwise';

  @override
  String get unoErrStackSameOnly => 'You can only play +2 on +2, or +4 on +4. A +2 cannot be stacked on +4.';

  @override
  String get unoErrCatchTooEarly => 'Wait a second — they can still say Uno.';

  @override
  String get unoErrCallTooLate => 'You can no longer say Uno. The next player has already moved.';

  @override
  String get gamesInDevelopment => 'In development';

  @override
  String rulesPokerPlayers(int players) {
    return 'Players: $players.';
  }

  @override
  String get rulesPokerIntro => 'Texas Hold’em. Each player gets 2 hole cards; 5 community cards are dealt to the table.';

  @override
  String get rulesPokerPlay => 'Betting rounds: preflop, flop, turn and river. You can fold, call, bet or raise.';

  @override
  String get rulesPokerWin => 'The best five-card hand (hole + community) wins, or the last player left after folds.';

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
  String get rulesPokerTable => 'The table plays until one player holds all the chips. Blinds rise every 6–8 hands (heads-up 8, 3-max 7, 4-max 6). Stake pot is split by place: 3-max 1st takes 2/3 (2nd breaks even); 4-max 1st takes 3/4; 5-max 1st takes 3/5; 6-max 1st takes 4/6.';

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
  String get gamesObservation => 'Spectating';

  @override
  String get gamesObservationHint => 'You can watch until the game ends';

  @override
  String get gamesFinishCurrentFirst => 'Finish your current game first';

  @override
  String get gamesVariantClassic => 'Classic';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 players';

  @override
  String get gamesVariantMulti4 => '4 players';

  @override
  String get gamesDurakModePodkidnoi => 'Throw-in';

  @override
  String get gamesDurakModePerevodnoi => 'Transfer';

  @override
  String get gamesDurakDeck24 => '24 cards';

  @override
  String get gamesDurakDeck36 => '36 cards';

  @override
  String get gamesDurakDeck52 => '52 cards';

  @override
  String rulesDurakMode(String mode) {
    return 'Mode: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'Players: $players. Deck: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Play against a bot, no stakes or turn timer.';

  @override
  String get rulesDurakAttack => 'The attacker plays cards; the defender beats them (same suit higher, or a trump). A trump is beaten only by a higher trump.';

  @override
  String get rulesDurakBeat => 'When all cards are beaten, the attacker says “Beat” and cards go to the discard. Otherwise the defender takes everything from the table.';

  @override
  String get rulesDurakLoser => 'The loser is the one left with cards at the end — the “fool”.';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Players $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Lobby $name';
  }

  @override
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Private game';

  @override
  String get lobbySearchingOpponent => 'Looking for an opponent…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Looking for this game: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Waiting for someone to tap “Find a game” or “Join”';

  @override
  String get lobbyInviteTitle => 'Game invite';

  @override
  String get lobbyInvitedToPlay => 'You were invited to play';

  @override
  String get lobbyEnterGame => 'Enter game';

  @override
  String get lobbyGone => 'This game is no longer available';

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
  String get gameYou => 'You';

  @override
  String get gameYouWon => 'You won!';

  @override
  String get gameYouWonShort => 'You won';

  @override
  String get gameYouLost => 'You lost';

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
  String get gameFlipBoard => 'Flip board';

  @override
  String get gameReviewStart => 'To game start';

  @override
  String get gameReviewPrev => 'Move back';

  @override
  String get gameReviewNext => 'Move forward';

  @override
  String get gameReviewEnd => 'To current position';

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
  String get friendsSearchNoMatches => 'No friends match your search';

  @override
  String get friendsIncomingSearchNoMatches => 'No incoming requests match your search';

  @override
  String get friendsOutgoingSearchNoMatches => 'No outgoing requests match your search';

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
  String get profileChangePhoto => 'Change avatar';

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
  String get shopStakesSubtitle => 'Unlock higher stakes';

  @override
  String get shopEmojisHelp => 'Animated emojis for chat. Buy a set and send them in messages to friends.';

  @override
  String get shopCollectionsHelp => 'You can sell only a new or vintage collection: 80% of the price when it is new, and 300% of the price when it is vintage. Worn, tired and shabby collections cannot be sold.\n\nCollect a set of items: they appear in your profile showcase and can be gifted. Each item pays coins every day, and a complete set also pays a separate bonus.\n\nAn item\'s daily income depends on its condition and is a share of the usual amount. New pays 100%. Worn pays 60%. Tired pays 40%. Shabby pays 100%. A vintage item pays 200%, twice the usual daily income.\n\nThe complete-set bonus stays the same until the set is vintage. A set is vintage when every item in it is vintage: the bonus is then 300%, three times the usual amount.\n\nCondition depends on how long you have owned the item. New — the first 7 days. Worn — from day 8 until 2 months. Tired — from 2 to 6 months. Shabby — from 6 months until 1 year. Vintage — after 1 year.';

  @override
  String get shopStakesHelp => 'Unlock higher stakes in games. The higher the stake, the bigger the pot and the payout.';

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
    return '$amount/day';
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
  String get coinsTasks => 'Tasks';

  @override
  String get coinsTasksSubtitle => 'Rewards for profile, friends and games';

  @override
  String get coinsTasksRewards => 'Rewards available to claim';

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
  String get shopHave => 'Have';

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
  String get shopSellRefund => 'Selling depends on the collection\'s condition';

  @override
  String get collectionConditionNew => 'New';

  @override
  String get collectionConditionWorn => 'Worn';

  @override
  String get collectionConditionTired => 'Tired';

  @override
  String get collectionConditionShabby => 'Shabby';

  @override
  String get collectionConditionVintage => 'Vintage';

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
  String get inventoryCollectionNotSellable => 'You can sell only a new or vintage collection.';

  @override
  String get inventoryCollectionNotSellableTitle => 'Can\'t sell';

  @override
  String get inventoryCollectionNotSellableHint => 'You can sell only a new or vintage item. Use an elixir to change its condition.';

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
  String get chatAutoTranslate => 'Auto-translate';

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
  String get lobbySearchShort => 'Search';

  @override
  String get lobbySearchPlayers => 'Find players';

  @override
  String get lobbyInviteDeclinedShort => 'Declined';

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
  String get profileGalleryTitle => 'Photos';

  @override
  String get profileGalleryAdd => 'Add photo';

  @override
  String get profileMakePrimary => 'Make primary';

  @override
  String get profilePhotoDelete => 'Delete photo';

  @override
  String get profilePhotosLimit => 'You can upload up to 3 photos';

  @override
  String get profilePhotosEmpty => 'No photos yet';

  @override
  String get profilePhotoUploadFailed => 'Could not upload photo';

  @override
  String get profilePhotoDeleteFailed => 'Could not delete photo';

  @override
  String get profilePhotoTooLarge => 'Photo is too large';

  @override
  String get profileSetPrimaryFailed => 'Could not set as primary';

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
    return 'Time per turn: $time. Running out of time is a loss.';
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

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsLoadFailed => 'Failed to load statistics';

  @override
  String get statsAllGames => 'All games';

  @override
  String get statsEmptyTitle => 'No games played yet';

  @override
  String get statsEmptyHint => 'Play your first game to see statistics here.';

  @override
  String get statsWins => 'Wins';

  @override
  String get statsDraws => 'Draws';

  @override
  String get statsLosses => 'Losses';

  @override
  String get statsWinRate => 'Win rate';

  @override
  String get statsTopWon => 'Most wins against';

  @override
  String get statsTopDrawn => 'Most draws with';

  @override
  String get statsTopLost => 'Most losses to';

  @override
  String get statsTimePlayed => 'Time played';

  @override
  String get statsYourScore => 'Your score';

  @override
  String get profileShowStats => 'Show statistics';

  @override
  String get statsDurationZeroMinutes => '0 min';

  @override
  String get gameYouWonOpponentForfeit => 'Opponent surrendered. You won!';

  @override
  String get lobbyLeaveTitle => 'Leave lobby?';

  @override
  String get lobbyLeaveConfirm => 'The lobby will be deleted after you leave. Invited friends will get a decline.';

  @override
  String get lobbyLeave => 'Leave';

  @override
  String statsDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'You surrendered. $name won';
  }

  @override
  String get supportTitle => 'Support';

  @override
  String get supportUnavailable => 'Support is unavailable';

  @override
  String get supportOpenFailed => 'Could not open support chat';

  @override
  String coinsGrantedTitle(int amount) {
    return 'You\'ve been credited $amount coins';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return '$amount coins were deducted';
  }

  @override
  String get coinsCreditCardTitle => 'You\'ve been credited coins';

  @override
  String get coinsClaim => 'Claim';

  @override
  String get durakActionPass => 'Pass';

  @override
  String get durakRoleTook => 'Took';

  @override
  String get durakRoleBeats => 'Beats';

  @override
  String get durakRoleThrowIn => 'Throw-in';

  @override
  String get durakRoleTurn => 'Turn';

  @override
  String get durakRoleDefends => 'Defending';

  @override
  String get durakStatusTaking => 'Taking';

  @override
  String get durakHintDefenderTurn => 'Defender’s turn';

  @override
  String get gameYouEliminated => 'You’re out';

  @override
  String gameYouPlaced(int place) {
    return 'You finished $place';
  }

  @override
  String get gameOverNeutral => 'Game over';

  @override
  String gameTurnOf(String name) {
    return '$name’s turn';
  }

  @override
  String get chatGroupTooltip => 'Group chat';

  @override
  String get lobbyChatNotReady => 'Lobby chat is not ready yet';

  @override
  String get chatsGroupChat => 'Group chat';

  @override
  String chatsMembersCount(int count) {
    return 'Members: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count ppl';
  }

  @override
  String get chatsYouSuffix => '(you)';

  @override
  String get chatTitleDurak3 => 'Durak · 3 players';

  @override
  String get chatTitleDurak4 => 'Durak · 4 players';

  @override
  String get rulesTttUltimate => 'Ultimate: nine 3×3 mini-boards. A move sends the opponent to that mini-board. Win by completing a line on the meta-board.';

  @override
  String get rulesTttMulti3 => '3 players: 3×3 board, three players (X, O, △). Complete a line of your marks to win.';

  @override
  String get rulesTttMulti4 => '4 players: 4×4 board, four players (X, O, △, □). Complete a line of your marks to win.';

  @override
  String get adminUsersTab => 'Users';

  @override
  String get adminSupportTab => 'Support';

  @override
  String get adminSearchHint => 'Search by email or name';

  @override
  String get adminRoleAdmins => 'Admins';

  @override
  String get adminRoleUsers => 'Users';

  @override
  String get adminRoleAll => 'All roles';

  @override
  String get adminStatusFrozen => 'Frozen';

  @override
  String get adminStatusActive => 'Active';

  @override
  String get adminStatusAny => 'Any status';

  @override
  String get adminOrderDesc => 'Descending';

  @override
  String get adminOrderAsc => 'Ascending';

  @override
  String adminLoadFailed(String error) {
    return 'Couldn’t load: $error';
  }

  @override
  String get adminUsersEmpty => 'No users found';

  @override
  String get adminSortLastSeen => 'By last visit';

  @override
  String get adminSortEmail => 'By email';

  @override
  String get adminSortCreated => 'By signup date';

  @override
  String adminBronzeBalance(int amount) {
    return '$amount br.';
  }

  @override
  String get adminRevokeAdmin => 'Remove admin';

  @override
  String get adminGrantAdmin => 'Make admin';

  @override
  String get adminAdminRevoked => 'Admin rights removed';

  @override
  String get adminAdminGranted => 'Admin rights granted';

  @override
  String get adminGrantCoins => 'Grant coins';

  @override
  String get adminWriteSupport => 'Message as support';

  @override
  String get adminUnfreeze => 'Unfreeze';

  @override
  String get adminFreeze => 'Freeze';

  @override
  String get adminUnfrozen => 'Unfrozen';

  @override
  String get adminFrozenDone => 'Frozen';

  @override
  String get adminResetPassword => 'Reset password';

  @override
  String get adminCoinsAmountHint => 'Amount (negative = deduct)';

  @override
  String get adminReasonOptional => 'Reason (optional)';

  @override
  String get adminGrantSent => 'Card sent to the support chat';

  @override
  String adminCoinsDebited(int amount) {
    return 'Deducted $amount bronze';
  }

  @override
  String get adminGrantVerb => 'Grant';

  @override
  String get adminNewPasswordHint => 'New password (min. 6)';

  @override
  String get adminPasswordReset => 'Password reset';

  @override
  String get adminResetVerb => 'Reset';

  @override
  String adminShortError(String error) {
    return 'Error: $error';
  }

  @override
  String get adminSupportEmpty => 'No support requests';

  @override
  String get adminUserFallback => 'User';

  @override
  String get apiErrTooManyRequests => 'Too many requests. Try again later.';

  @override
  String get apiErrMoveConflict => 'That move conflicted. Try again.';

  @override
  String get shopElixirs => 'Elixirs';

  @override
  String get shopElixirsSubtitle => 'Rejuvenate, age, or speed up collections';

  @override
  String get shopElixirsHelp => 'Three shelves: rejuvenation, aging, and acceleration. Each has six elixirs, one per collection set. An elixir works only on its own set.\n\nRejuvenation makes a collection one step newer, and never newer than new. Aging makes it one step older, and never older than shabby. Acceleration is only for a shabby item: three months left until vintage, once. An elixir never grants vintage by itself.\n\nA bought elixir stays in Items. Use it from the collection card or from the elixir card. Each use spends one.';

  @override
  String get elixirGroupRejuvenate => 'Rejuvenation';

  @override
  String get elixirGroupAge => 'Aging';

  @override
  String get elixirGroupAccelerate => 'Acceleration';

  @override
  String get elixirEffectRejuvenate => 'rejuvenation';

  @override
  String get elixirEffectAge => 'aging';

  @override
  String get elixirEffectAccelerate => 'acceleration';

  @override
  String get elixirAdjCelebration => 'Festive';

  @override
  String get elixirAdjNature => 'Natural';

  @override
  String get elixirAdjLegends => 'Legendary';

  @override
  String get elixirAdjCosmic => 'Cosmic';

  @override
  String get elixirAdjAdventure => 'Adventure';

  @override
  String get elixirAdjJewels => 'Precious';

  @override
  String elixirName(String adjective, String effect) {
    return '$adjective $effect elixir';
  }

  @override
  String get elixirHelpRejuvenate => 'Makes the collection one step newer. Not newer than new.';

  @override
  String get elixirHelpAge => 'Makes the collection one step older. Not older than shabby.';

  @override
  String get elixirHelpAccelerate => 'Shabby only. Three months left until vintage, once.';

  @override
  String get elixirUseRejuvenate => 'Rejuvenate';

  @override
  String get elixirUseAge => 'Age';

  @override
  String get elixirUseAccelerate => 'Speed up';

  @override
  String get elixirUse => 'Use';

  @override
  String collectionLeftDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '$count hour',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '$count minute',
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

  @override
  String get statsRecentTitle => 'Recent games';

  @override
  String get statsOutcomeWin => 'Win';

  @override
  String get statsOutcomeLoss => 'Loss';

  @override
  String get statsOutcomeDraw => 'Draw';

  @override
  String get statsAllModes => 'All modes';

  @override
  String statsDurakChip(int players, String deck) {
    return '$players · $deck';
  }

  @override
  String get statsSelectGame => 'Game';

  @override
  String get statsSelectMode => 'Mode';

  @override
  String get statsRecentEmpty => 'No games yet';
}
