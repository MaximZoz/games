import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navProfile => 'Hồ sơ';

  @override
  String get navFriends => 'Bạn bè';

  @override
  String get navChats => 'Trò chuyện';

  @override
  String get navGames => 'Trò chơi';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsLanguageSystem => 'Theo hệ thống';

  @override
  String get settingsSoundTitle => 'Âm thanh';

  @override
  String get settingsSoundSubtitle => 'Trò chơi và thông báo';

  @override
  String get settingsSoundGames => 'Trò chơi';

  @override
  String get settingsSoundNotifications => 'Thông báo';

  @override
  String get settingsSoundTurn => 'Lượt';

  @override
  String get settingsHapticsTitle => 'Rung';

  @override
  String get settingsHapticsSubtitle => 'Chỉ thông báo: tin nhắn, lời mời, lượt của bạn và đồng hồ';

  @override
  String get settingsGamepadTitle => 'Tay cầm';

  @override
  String get settingsGamepadSubtitle => 'Gamepad cho menu và ván đấu';

  @override
  String settingsGamepadConnected(String name) {
    return 'Đã kết nối: $name';
  }

  @override
  String get settingsGamepadDisconnected => 'Không thấy gamepad. Cắm tay cầm và nhấn nút bất kỳ.';

  @override
  String get settingsGamepadGenericName => 'Tay cầm';

  @override
  String get settingsGamepadHelpNavigate => 'Điều hướng';

  @override
  String get settingsGamepadHelpConfirm => 'Chọn';

  @override
  String get settingsGamepadHelpBack => 'Quay lại';

  @override
  String get settingsGamepadHelpTabs => 'Tab';

  @override
  String get settingsGamepadHelpPlay => 'Con trỏ bàn và bài trên tay: cờ đam, cờ caro, hải chiến, durak, uno, poker và cờ vua ngược';

  @override
  String get settingsGamepadHelpCards => 'Bài';

  @override
  String get settingsGamepadHelpKeyboard => 'Bàn phím';

  @override
  String get settingsGamepadHelpBalance => 'Số dư';

  @override
  String get settingsGamepadHelpLogout => 'Đăng xuất';

  @override
  String get settingsGamepadHelpPage => 'Trang';

  @override
  String get settingsGamepadLayoutXbox => 'Bố cục Xbox';

  @override
  String get settingsGamepadLayoutPlayStation => 'Bố cục PlayStation';

  @override
  String get settingsGamepadLayoutNintendo => 'Bố cục Nintendo';

  @override
  String get gamepadKeyboardTitle => 'Bàn phím';

  @override
  String get gamepadKeyboardSpace => 'Cách';

  @override
  String get gamepadLegendConfirm => 'Chọn';

  @override
  String get gamepadLegendBack => 'Quay lại';

  @override
  String get gamepadLegendTabs => 'Tab';

  @override
  String get gamepadLegendCycle => 'Đổi';

  @override
  String gamepadConnectedSnack(String name) {
    return 'Đã kết nối tay cầm: $name';
  }

  @override
  String get settingsOfflineModeTitle => 'Chế độ mạng';

  @override
  String get settingsOfflineModeSubtitle => 'Ngoại tuyến: chơi bot ngay, không cược và phần thưởng, không chat và bạn bè. Giao dịch được lưu và áp dụng ở chế độ trực tuyến. Trực tuyến — khi có internet hoặc theo cài đặt người dùng.';

  @override
  String get settingsModeOnline => 'Trực tuyến';

  @override
  String get settingsModeOffline => 'Ngoại tuyến';

  @override
  String get gamesAlternateStartsHint => 'Lần lượt ai bắt đầu ván';

  @override
  String get rulesAlternateStarts => 'Người đi trước luân phiên theo từng ván.';

  @override
  String get offlineBadgeTooltip => 'Chế độ ngoại tuyến';

  @override
  String get offlineModePopupTitle => 'Chế độ ngoại tuyến';

  @override
  String get offlineModePopupBody => 'Chế độ ngoại tuyến đang bật. Chơi bot không cược và phần thưởng. Chat, bạn bè và sảnh bị ẩn. Giao dịch áp dụng ở chế độ trực tuyến.';

  @override
  String get offlineModePopupSettings => 'Cài đặt';

  @override
  String get offlineModeOfferBody => 'Không có internet hoặc kết nối rất chậm. Bạn có thể bật chế độ ngoại tuyến và chơi với bot.';

  @override
  String get offlineModeOfferAction => 'Bật ngoại tuyến';

  @override
  String get gamesPlay => 'Chơi';

  @override
  String get offlineGameTitle => 'Chơi với bot';

  @override
  String get offlineGameHint => 'Không cược và thưởng · chỉ ngoại tuyến';

  @override
  String get offlineBotWon => 'Bot thắng';

  @override
  String get offlineBotThinking => 'Bot đang nghĩ…';

  @override
  String get offlinePlayAgain => 'Chơi lại';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'Nhận';

  @override
  String get durakActionAll => 'Tất cả';

  @override
  String get durakActionDone => 'Xong';

  @override
  String get durakActionBito => 'Beat';

  @override
  String get durakHintDefend => 'Chắn';

  @override
  String get durakHintDefendOrTransfer => 'Chắn hoặc chuyển';

  @override
  String get durakHintOpponentDefends => 'Đối thủ đang chắn';

  @override
  String get durakHintThrowInFirst => 'Đánh thêm bài (tối đa 5 ở lượt đầu)';

  @override
  String get durakHintThrowIn => 'Đánh thêm bài hoặc chờ chắn';

  @override
  String get durakHintOpponentThrows => 'Đối thủ đang đánh thêm';

  @override
  String get durakHintTakeFollow => 'Đánh thêm sau khi nhận hoặc nhấn «Xong»';

  @override
  String get durakHintOpponentTakeFollow => 'Đối thủ có thể đánh thêm sau khi nhận';

  @override
  String get durakHintBito => 'Đánh thêm hoặc nói «Bito»';

  @override
  String get durakHintOpponentBito => 'Đối thủ đánh thêm hoặc nói «Bito»';

  @override
  String get durakHintYourAttack => 'Lượt của bạn — tấn công';

  @override
  String get durakHintOpponentAttack => 'Đối thủ đang tấn công';

  @override
  String get durakHintYouLost => 'Bạn thua — bạn là kẻ ngốc';

  @override
  String get durakHintDrawAllOut => 'Hòa — mọi người đã ra';

  @override
  String get durakHintYouFinished => 'Bạn đã ra — chờ kết thúc';

  @override
  String get durakFirstLeadYou => 'Bạn đi trước';

  @override
  String get durakFirstLeadOpponent => 'Đối thủ đi trước';

  @override
  String get durakFirstLeadBot => 'Bot đi trước';

  @override
  String durakFirstLeadOf(String name) {
    return '$name đi trước';
  }

  @override
  String get durakFirstLeadReason => 'Át thấp nhất';

  @override
  String get shopPurchaseQueued => 'Đã lưu giao dịch — sẽ áp dụng ở chế độ trực tuyến';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — đã áp dụng giao dịch';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — không áp dụng giao dịch: $reason';
  }

  @override
  String get settingsFriendsOnlyTitle => 'Chỉ nhận tin từ bạn bè';

  @override
  String get settingsFriendsOnlySubtitle => 'Người không phải bạn bè chỉ gửi được emoji. Nếu bị spam, hãy tạm chặn người đó.';

  @override
  String get settingsNotifications => 'Thông báo';

  @override
  String get settingsPushChat => 'Trò chuyện';

  @override
  String get settingsPushFriends => 'Bạn bè';

  @override
  String get settingsPushGames => 'Trò chơi';

  @override
  String get settingsPushRewards => 'Phần thưởng';

  @override
  String settingsAppVersion(String version) {
    return 'Phiên bản $version';
  }

  @override
  String get appUpdateTitle => 'Có bản cập nhật';

  @override
  String get appUpdateBody => 'Đã có phiên bản mới của ứng dụng. Hãy cập nhật để tiếp tục.';

  @override
  String get appUpdateWhatsNew => 'Có gì mới';

  @override
  String get appUpdateOk => 'Cập nhật';

  @override
  String get appUpdateLaterBanner => 'Chúng tôi sẽ cập nhật ứng dụng sau ván này';

  @override
  String get loginTitle => 'Đăng nhập';

  @override
  String get loginSubtitle => 'Nhập email hoặc tên người dùng và mật khẩu';

  @override
  String get loginEmailLabel => 'Email hoặc tên người dùng';

  @override
  String get loginPasswordLabel => 'Mật khẩu';

  @override
  String get loginSubmit => 'Đăng nhập';

  @override
  String get loginNoAccount => 'Chưa có tài khoản? Đăng ký';

  @override
  String get loginEmailRequired => 'Nhập email hoặc tên người dùng';

  @override
  String get loginPasswordRequired => 'Nhập mật khẩu';

  @override
  String get loginTooltip => 'Đăng nhập';

  @override
  String get logoutTooltip => 'Đăng xuất';

  @override
  String get registerTitle => 'Đăng ký';

  @override
  String get registerSubtitle => 'Tạo tài khoản để chơi';

  @override
  String get registerNameLabel => 'Tên (tên người dùng)';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'Mật khẩu';

  @override
  String get registerSubmit => 'Đăng ký';

  @override
  String get registerHaveAccount => 'Đã có tài khoản? Đăng nhập';

  @override
  String get registerNameRequired => 'Nhập tên';

  @override
  String get registerNameNoSpaces => 'Tên không được chứa khoảng trắng';

  @override
  String get registerNameMax => 'Tối đa 20 ký tự';

  @override
  String get registerNameHint => 'Tối đa 20 ký tự';

  @override
  String get registerEmailRequired => 'Nhập email';

  @override
  String get registerEmailInvalid => 'Email không hợp lệ';

  @override
  String get registerPasswordHint => 'Ít nhất 6 ký tự';

  @override
  String get registerPasswordMin => 'Mật khẩu phải có ít nhất 6 ký tự';

  @override
  String get commonCancel => 'Hủy';

  @override
  String get commonSave => 'Lưu';

  @override
  String get commonDelete => 'Xóa';

  @override
  String get commonEdit => 'Sửa';

  @override
  String get commonReply => 'Trả lời';

  @override
  String get commonSend => 'Gửi';

  @override
  String get commonClose => 'Đóng';

  @override
  String get openInApp => 'Mở trong ứng dụng';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonLoading => 'Đang tải…';

  @override
  String get commonError => 'Lỗi';

  @override
  String get commonOnline => 'trực tuyến';

  @override
  String get commonOffline => 'ngoại tuyến';

  @override
  String get commonOnlineCap => 'Trực tuyến';

  @override
  String get commonUser => 'Người dùng';

  @override
  String get commonPlayer => 'Người chơi';

  @override
  String get commonAboutMe => 'Giới thiệu';

  @override
  String get commonBack => 'Quay lại';

  @override
  String get commonAccept => 'Chấp nhận';

  @override
  String get commonDecline => 'Từ chối';

  @override
  String get commonCreating => 'Đang tạo…';

  @override
  String get commonSearching => 'Đang tìm…';

  @override
  String get commonInsufficientCoins => 'Không đủ xu';

  @override
  String get commonNotFound => 'Không tìm thấy';

  @override
  String get commonServerErrorShort => 'Lỗi máy chủ';

  @override
  String get commonForbidden => 'Truy cập bị từ chối';

  @override
  String get commonUserBlocked => 'Người dùng đã bị chặn';

  @override
  String get commonUserNotFound => 'Không tìm thấy người dùng';

  @override
  String get commonGenericError => 'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String get apiErrWrongGameType => 'Sai loại trò chơi';

  @override
  String get apiErrWrongGameTypeOrState => 'Sai loại hoặc trạng thái trò chơi';

  @override
  String get apiErrLobbyFull => 'Sảnh đã đầy';

  @override
  String get apiErrBadState => 'Trạng thái ván không hợp lệ';

  @override
  String get apiErrIllegalMove => 'Nước đi không hợp lệ';

  @override
  String get apiErrUnknownMoveType => 'Loại nước đi không rõ';

  @override
  String get apiErrNoOpponents => 'Không có đối thủ';

  @override
  String get apiErrNoOpponentsRematch => 'Không có đối thủ để tái đấu';

  @override
  String get apiErrAlreadyInLobby => 'Bạn đã ở trong sảnh này';

  @override
  String get apiErrGameNotActive => 'Ván không còn diễn ra';

  @override
  String get apiErrNotInBattle => 'Không phải giai đoạn chiến đấu';

  @override
  String get apiErrNotInSetup => 'Không phải giai đoạn xếp thuyền';

  @override
  String get apiErrAlreadyReady => 'Bạn đã sẵn sàng';

  @override
  String get apiErrAlreadyForfeited => 'Bạn đã bỏ cuộc';

  @override
  String get apiErrYouHaveForfeited => 'Bạn đã bỏ cuộc';

  @override
  String get apiErrNoDrawOffer => 'Không có đề nghị hòa';

  @override
  String get apiErrDrawOnlyPvp => 'Hòa chỉ có khi đấu người';

  @override
  String get apiErrDrawOnly1v1 => 'Hòa chỉ có trong 1 đấu 1';

  @override
  String get apiErrDrawVsBot => 'Không thể hòa với bot';

  @override
  String get apiErrDrawMultiplayer => 'Không thể hòa trong ván nhiều người';

  @override
  String get apiErrDeck24TwoPlayers => 'Bộ 24 lá chỉ dành cho 2 người';

  @override
  String get apiErrDeck52ThreeOrFour => 'Bộ 52 lá chỉ dành cho 3 hoặc 4 người';

  @override
  String get apiErrAccountFrozen => 'Tài khoản đã bị đóng băng';

  @override
  String get apiErrTurnTimeInvalid => 'Thời gian lượt phải là 0, 20, 60 hoặc 600 giây';

  @override
  String get timeJustNow => 'vừa xong';

  @override
  String get timeYesterday => 'hôm qua';

  @override
  String timeMinutesAgo(int count) {
    return '$count phút trước';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count giờ trước';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count ngày trước';
  }

  @override
  String get timeWeekAgo => 'một tuần trước';

  @override
  String timeWeeksAgo(int count) {
    return '$count tuần trước';
  }

  @override
  String get timeMonthAgo => 'một tháng trước';

  @override
  String timeMonthsAgo(int count) {
    return '$count tháng trước';
  }

  @override
  String get timeYearAgo => 'một năm trước';

  @override
  String timeYearsAgo(int count) {
    return '$count năm trước';
  }

  @override
  String get weekdaySun => 'CN';

  @override
  String get weekdayMon => 'T2';

  @override
  String get weekdayTue => 'T3';

  @override
  String get weekdayWed => 'T4';

  @override
  String get weekdayThu => 'T5';

  @override
  String get weekdayFri => 'T6';

  @override
  String get weekdaySat => 'T7';

  @override
  String get monthJan => 'Th1';

  @override
  String get monthFeb => 'Th2';

  @override
  String get monthMar => 'Th3';

  @override
  String get monthApr => 'Th4';

  @override
  String get monthMay => 'Th5';

  @override
  String get monthJun => 'Th6';

  @override
  String get monthJul => 'Th7';

  @override
  String get monthAug => 'Th8';

  @override
  String get monthSep => 'Th9';

  @override
  String get monthOct => 'Th10';

  @override
  String get monthNov => 'Th11';

  @override
  String get monthDec => 'Th12';

  @override
  String get homeAchievements => 'Thành tích';

  @override
  String get homeAchievementsSubtitle => 'Kết quả trò chơi của bạn';

  @override
  String get homeAchievementsRewards => 'Có phần thưởng để nhận';

  @override
  String get homeCoins => 'Xu';

  @override
  String get homeCoinsSubtitle => 'Số dư và phần thưởng';

  @override
  String get homeCoinsDailyReward => 'Có phần thưởng đăng nhập hàng ngày';

  @override
  String get homeItems => 'Vật phẩm';

  @override
  String get homeItemsInventory => 'Kho đồ của bạn';

  @override
  String get homeItemsGifted => 'Ai đó đã tặng bạn bộ sưu tập';

  @override
  String get homeItemsIncome => 'Thu nhập bộ sưu tập sẵn sàng nhận';

  @override
  String get homeShop => 'Cửa hàng';

  @override
  String get homeShopSubtitle => 'Emoji, cược, bộ sưu tập';

  @override
  String get gamesTitle => 'Trò chơi';

  @override
  String get gamesFindMatch => 'Tìm trận';

  @override
  String get gamesMyTurn => 'Lượt của bạn';

  @override
  String get gamesWaiting => 'Đang chờ';

  @override
  String get gamesLobbyTab => 'Sảnh';

  @override
  String get gamesTicTacToe => 'Cờ caro';

  @override
  String get gamesDurak => 'Durak';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => 'Xoay';

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
  String get gamesNardy => 'Cờ Backgammon';

  @override
  String get gamesNardyModeShort => 'Ngắn';

  @override
  String get gamesNardyModeLong => 'Dài';

  @override
  String get gamesCheckers => 'Cờ đam';

  @override
  String get gamesCheckersModeRussian => 'Nga';

  @override
  String get gamesCheckersModeEnglish => 'Anh';

  @override
  String get gamesCheckersModeGiveaway => 'Nhường';

  @override
  String get gamesCheckersModeCorners => 'Góc';

  @override
  String get gamesChess => 'Cờ vua';

  @override
  String get gamesDomino => 'Domino';

  @override
  String get gamesDominoModeKozel => 'Dê';

  @override
  String get gamesDominoModeClassic => 'Cổ điển';

  @override
  String get gamesDominoModeSea => 'Biển';

  @override
  String get rulesDominoDeal => 'Mỗi người 7 quân. 2 hoặc 3 người thì phần còn lại ở nọc, 4 người thì nọc trống.';

  @override
  String get rulesDominoOpen => 'Ván đầu bắt đầu bằng đôi nhỏ nhất từ 1-1 đến 6-6, rồi 0-0. Không có đôi thì quân lớn nhất, và phải đánh quân đó.';

  @override
  String get rulesDominoPlay => 'Đặt quân vào đầu mở cùng số. Đôi ở đầu không đổi số đó.';

  @override
  String get rulesDominoDraw => 'Không đánh được thì bốc từng quân cho đến khi đánh được hoặc hết nọc. Quân cuối vẫn bốc được. Vẫn không có nước thì bỏ lượt.';

  @override
  String get rulesDominoScore => 'Hết ván mỗi người ghi tổng quân còn lại. Ai hết quân ghi 0. Đến 101: ai chạm là dê và thua.';

  @override
  String get rulesDominoFish => 'Cá: nọc trống và không ai đặt được. Tổng nhỏ nhất duy nhất ghi 0, người khác ghi tổng của mình. Nếu mức nhỏ nhất bằng nhau thì tất cả đều ghi.';

  @override
  String get rulesDominoMatch => 'Nếu nhiều người vượt 101 trong một ván, dê là điểm cao nhất. Người điểm thấp nhất thắng. Tất cả hòa nhau thì hòa.';

  @override
  String get rulesDominoOffline => 'Ngoại tuyến: bạn và bot. Bot đếm số và không nhìn bài úp.';

  @override
  String rulesDominoMode(String mode) {
    return 'Chế độ: $mode';
  }

  @override
  String get rulesDominoClassicDeal => 'Hai hoặc ba người được 7 quân, bốn người được 5. Phần còn lại là kho.';

  @override
  String get rulesDominoClassicOpen => 'Ván đầu mở bằng kép 6, rồi 0-0 và các kép nhỏ hơn. Không có kép thì phải đánh quân lớn nhất.';

  @override
  String get rulesDominoClassicScore => 'Người hết quân ghi tổng điểm đối thủ. Ai tới 100 trước thắng.';

  @override
  String get rulesDominoClassicFish => 'Khi bí, tay nhẹ nhất duy nhất ghi hiệu với từng tay khác. Hòa mức tối thiểu thì không ghi điểm.';

  @override
  String get rulesDominoClassicMatch => 'Cùng điểm cao nhất thì chia thắng. Nếu mọi người bằng nhau là hòa.';

  @override
  String get rulesDominoSeaSame => 'Chia, mở và bốc như Dê. Chuỗi có hai đầu.';

  @override
  String get rulesDominoSeaScore => 'Chỉ tay nặng nhất được ghi điểm. Dưới 25 không ghi.';

  @override
  String get rulesDominoSeaWipe => 'Nếu hai người cùng từ 25 trở lên, ván đó không ai được ghi.';

  @override
  String get rulesDominoSeaBlank => 'Đánh 0-0 kết thúc ván ngay: đối thủ nặng nhất duy nhất bị ghi 75. Hòa thì không ai bị ghi.';

  @override
  String get rulesDominoSeaSix => 'Kết thúc bằng quân 6-6 cuối thì người thua bị ghi 100, điểm trận của người đóng về 0.';

  @override
  String get rulesDominoSeaMatch => 'Trận đến 125. Ai đạt thì thua.';

  @override
  String get dominoBoneyard => 'Nọc';

  @override
  String get dominoChooseEnd => 'Chọn một đầu';

  @override
  String get dominoFish => 'Cá';

  @override
  String get dominoYouGoat => 'Bạn là dê';

  @override
  String dominoGoatNamed(String name) {
    return 'Dê — $name';
  }

  @override
  String get dominoLeft => 'Trái';

  @override
  String get dominoRight => 'Phải';

  @override
  String get gamesChessModeClassic => 'Cổ điển';

  @override
  String get gamesChessModeRapid => 'Cờ nhanh';

  @override
  String get gamesChessModeBlitz => 'Chớp';

  @override
  String get gamesChessModeBullet => 'Đạn';

  @override
  String get chessPieceQueen => 'Hậu';

  @override
  String get chessPieceRook => 'Xe';

  @override
  String get chessPieceBishop => 'Tượng';

  @override
  String get chessPieceKnight => 'Mã';

  @override
  String get chessPromotionTitle => 'Phong cấp tốt';

  @override
  String get chessDrawStalemate => 'Hòa: hết nước đi';

  @override
  String get chessDrawInsufficient => 'Hòa: không đủ quân chiếu hết';

  @override
  String get chessDrawRepetition => 'Hòa: lặp lại ba lần';

  @override
  String get chessDrawFiftyMove => 'Hòa: luật 50 nước';

  @override
  String get chessCheck => 'Chiếu';

  @override
  String get rulesCheckersPlayers => 'Người chơi: 2.';

  @override
  String rulesCheckersMode(String mode) {
    return 'Chế độ: $mode.';
  }

  @override
  String rulesCheckersTime(String time) {
    return 'Время на ход: $time. Если время вышло — проигрыш.';
  }

  @override
  String get rulesCheckersIntro => 'Bàn 8×8. Hai người chơi.';

  @override
  String get rulesCheckersPlay => 'Bắt buộc ăn. Đam và quân thường phải ăn tiếp nếu từ ô đáp còn nhảy được — không được dừng giữa chừng. Có nhiều hướng thì chọn hướng nào cũng được, không bắt buộc đường dài nhất. Quân thường tới hàng cuối thành đam.';

  @override
  String get rulesCheckersWin => 'В русских шашках побеждает тот, кто съел все шашки соперника или лишил его хода. В поддавках наоборот: кто не может ходить — выигрывает.';

  @override
  String get rulesCheckersOfflineBot => 'Офлайн: партия против бота.';

  @override
  String get rulesCheckersPlayRussian => 'Cờ đam Nga: mỗi bên 12 quân trên ô tối. Quân thường đi chéo tiến, ăn tiến hoặc lùi. Đam bay bao nhiêu ô tùy ý. Bắt buộc ăn: còn nhảy được thì không được dừng, nhưng có nhiều hướng thì chọn hướng nào cũng được, không bắt buộc đường dài nhất. Thắng khi ăn hết quân đối thủ hoặc để đối thủ hết nước.';

  @override
  String get rulesCheckersPlayEnglish => 'Cờ đam Anh: mỗi bên 12 quân. Quân thường chỉ đi và ăn chéo tiến. Đam đi một ô chéo. Bắt buộc ăn. Thắng khi ăn hết quân hoặc để đối thủ hết nước.';

  @override
  String get rulesCheckersPlayGiveaway => 'Nhường: nước đi như cờ đam Nga nhưng mục tiêu ngược lại — mất hết quân hoặc hết nước đi. Vẫn bắt buộc ăn.';

  @override
  String get rulesCheckersPlayCorners => 'Góc: quân bắt đầu ở hai góc đối diện. Đi tới ô trống kề ngang hoặc dọc, hoặc nhảy qua quân bất kỳ mà không bắt. Mục tiêu là đưa hết quân mình sang góc đối thủ.';

  @override
  String get rulesCheckersPlayCornersNoReturn => 'Quân đã rời góc xuất phát thì không được quay lại đó.';

  @override
  String get rulesCheckersPlayCornersLeaveHome => 'Các quân còn trong nhà phải rời đi trong 25 nước đầu của người chơi.';

  @override
  String get rulesCheckersDrawRussian => 'Hòa nếu thế cờ lặp ba lần, hoặc 15 nước mỗi bên không tiến triển: không ăn, không đi tốt và không phong cấp.';

  @override
  String get rulesCheckersDrawEnglish => 'Hòa nếu thế cờ lặp ba lần, nếu 40 nước mỗi bên không ăn và không đi tốt, hoặc mỗi bên còn một đam.';

  @override
  String get rulesCheckersDrawGiveaway => 'Hòa nếu thế cờ lặp ba lần, hoặc 15 nước mỗi bên ở chế độ nhường không tiến triển: không ăn, không đi tốt và không phong cấp.';

  @override
  String get rulesCheckersDrawCorners => 'Hòa nếu thế cờ lặp ba lần, hoặc 25 nước mỗi bên không thêm quân vào góc đích.';

  @override
  String get rulesChessPlayers => 'Người chơi: 2.';

  @override
  String rulesChessMode(String mode) {
    return 'Chế độ: $mode.';
  }

  @override
  String get rulesChessPlayClassic => 'Bàn 8×8. Mỗi bên có vua, hậu, hai xe, hai tượng, hai mã và tám tốt. Trắng đi trước. Nước đi thường, bắt tốt qua đường, phong cấp và nhập thành. Thắng bằng chiếu hết hoặc đối thủ đầu hàng.';

  @override
  String get rulesChessDrawClassic => 'Hòa vì hết nước, lặp ba lần, luật 50 nước, thiếu quân hoặc thỏa thuận.';

  @override
  String get rulesChessClockClassic => 'Đồng hồ: 60+0 — 60 phút cho cả ván, không cộng thêm.';

  @override
  String get rulesChessClockRapid => 'Đồng hồ: 10+0 — 10 phút cho cả ván, không cộng thêm.';

  @override
  String get rulesChessClockBlitz => 'Đồng hồ: 5+0 — 5 phút cho cả ván, không cộng thêm.';

  @override
  String get rulesChessClockBullet => 'Đồng hồ: 3+2 — 3 phút cộng 2 giây mỗi nước.';

  @override
  String get checkersDrawRepetition => 'Hòa — thế cờ lặp ba lần';

  @override
  String get checkersDrawNoProgress => 'Hòa — nước đi không dẫn tới thắng';

  @override
  String get checkersDrawInsufficient => 'Hòa — không đủ quân để thắng';

  @override
  String get rulesNardyTitle => 'Cờ Backgammon — luật';

  @override
  String get rulesNardyPlayers => 'Người chơi: 2.';

  @override
  String rulesNardyMode(String mode) {
    return 'Chế độ: $mode.';
  }

  @override
  String get rulesNardyIntro => 'Bàn 24 ô, mỗi bên 15 quân. Hai xúc xắc: một quân tổng hoặc hai quân từng nút.';

  @override
  String get rulesNardyPlayShort => 'Cờ ngắn: đi ngược chiều và có thể ăn quân đơn. Quân bị ăn lên bar và phải vào lại. Khi tất cả về nhà thì gỡ chúng.';

  @override
  String get rulesNardyPlayLong => 'Cờ dài: cả hai xuất phát cùng một đầu và cùng chiều. Mỗi lượt chỉ một quân rời đầu. Không được ăn. Khi tất cả về nhà thì gỡ chúng.';

  @override
  String get rulesNardyWin => 'Ai gỡ hết quân trước sẽ thắng.';

  @override
  String get rulesNardySixPrime => 'Bạn không được khóa sáu điểm liên tiếp khi chưa có quân nào của đối thủ vượt qua.';

  @override
  String get nardyRoll => 'Gieo xúc xắc';

  @override
  String get nardySkipTurn => 'Bỏ lượt';

  @override
  String get nardyUndoMove => 'Hoàn tác';

  @override
  String get nardyDoneTurn => 'Xong';

  @override
  String get nardyAutoConfirm => 'Tự xác nhận';

  @override
  String get nardyAutoConfirmHint => 'Sau mọi nước đi, lượt tự chuyển cho đối thủ';

  @override
  String get nardyLayoutToggle => 'Đổi cách xếp';

  @override
  String get nardyNoMoves => 'Không có nước đi';

  @override
  String get nardyYourRoll => 'Lượt gieo của bạn';

  @override
  String get nardyPipsShort => 'Còn lại:';

  @override
  String get nardyYouWonMars => 'Bạn thắng — gammon!';

  @override
  String get nardyYouLostMars => 'Thua — gammon';

  @override
  String get rulesNardyOfflineBot => 'Ngoại tuyến: chơi với bot.';

  @override
  String rulesUnoPlayers(int players) {
    return 'Người chơi: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'Chơi với bot, không giới hạn thời gian mỗi lượt.';

  @override
  String get rulesUnoIntro => 'Mỗi người được chia 7 lá. Đánh lá cùng màu hoặc cùng hạng (số hoặc cùng loại bài đặc biệt).';

  @override
  String get rulesUnoPlay => 'Bỏ lượt — người kế mất lượt. Đổi chiều khi còn hai người như bỏ lượt. +2 chỉ chồng lên +2, +4 chỉ chồng lên +4: phạt cộng dồn (hai lá +2 thì người kế rút 4). Không được chồng +2 lên +4. Ai không chồng sẽ rút cả chồng và mất lượt.Hai lá giống nhau không phải đen (ví dụ hai quân 8 vàng) bỏ cùng lúc: đánh một lá, lá cặp đi tự động.';

  @override
  String get rulesUnoWild => 'Lá đen chọn màu mới. Chỉ đánh +4 khi không có lá màu hiện tại. Đối thủ có thể thách: nếu +4 hợp lệ họ rút 6; nếu không, người đánh +4 rút 4 và người thách được đánh.';

  @override
  String get rulesUnoDraw => 'Không có lá hợp lệ thì rút một lá từ bộ. Nếu khớp, có thể đánh ngay hoặc giữ và bỏ lượt. Còn nước đi thì không được rút.';

  @override
  String get rulesUnoWin => '1v1 đến 100 điểm, từ 3 người đến 200. Thắng vòng là người hết bài.';

  @override
  String get rulesUnoCall => 'Khi còn một lá, nhấn «Uno!» ngay. Đối thủ chỉ được bắt bạn quên Uno sau một giây — khi đó bạn rút 2 lá.';

  @override
  String get rulesUnoScoring => 'Ai hết bài trước thắng vòng và nhận điểm từ bài đối thủ: số theo mệnh giá, bài hành động 20, đen 50. 1v1 đến 100, từ 3 người đến 200.';

  @override
  String get unoColorRed => 'Đỏ';

  @override
  String get unoColorYellow => 'Vàng';

  @override
  String get unoColorGreen => 'Xanh lá';

  @override
  String get unoColorBlue => 'Xanh dương';

  @override
  String get unoDraw => 'Rút';

  @override
  String get unoKeep => 'Giữ';

  @override
  String get unoSayUno => 'Uno!';

  @override
  String get unoChallengeUno => 'Thách Uno';

  @override
  String get unoChallengeWd4 => 'Thách +4';

  @override
  String get unoChooseColor => 'Chọn màu';

  @override
  String get unoDrawPile => 'Chồng rút';

  @override
  String get unoDiscardPile => 'Chồng bỏ';

  @override
  String unoCardsCount(int count) {
    return 'Bài: $count';
  }

  @override
  String unoScore(int score) {
    return 'Điểm: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'Ván $round · đến $target';
  }

  @override
  String get unoYourTurn => 'Lượt của bạn';

  @override
  String get unoWaitingTurn => 'Lượt đối thủ';

  @override
  String get unoChooseColorHint => 'Chọn màu cho lá đổi màu';

  @override
  String get unoWd4Hint => 'Rút 4 lá hoặc thách Wild +4';

  @override
  String get unoDrawnHint => 'Đánh lá vừa rút hoặc giữ lại';

  @override
  String get unoPlayHint => 'Đánh lá cùng màu hoặc giá trị';

  @override
  String get unoDrawHint => 'Không có lá phù hợp — rút từ chồng';

  @override
  String unoPendingDraw(int count) {
    return '+$count lá';
  }

  @override
  String get unoYouWon => 'Bạn đã thắng trận!';

  @override
  String get unoYouLost => 'Trận đấu kết thúc';

  @override
  String get unoYouLostTimeout => 'Bạn thua vì hết giờ';

  @override
  String unoWinner(String name) {
    return 'Người thắng: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name thắng vòng';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'Tiếp';

  @override
  String get unoRoundScoresTitle => 'Điểm vòng';

  @override
  String get unoDirectionClockwise => 'Theo chiều kim đồng hồ';

  @override
  String get unoDirectionCounterclockwise => 'Ngược chiều kim đồng hồ';

  @override
  String get unoErrStackSameOnly => 'Chỉ được đánh +2 lên +2, hoặc +4 lên +4. Không được xếp +2 lên +4.';

  @override
  String get unoErrCatchTooEarly => 'Đợi một giây — họ vẫn có thể hô Uno.';

  @override
  String get unoErrCallTooLate => 'Không thể hô Uno nữa. Người tiếp theo đã đánh.';

  @override
  String get gamesInDevelopment => 'Đang phát triển';

  @override
  String rulesPokerPlayers(int players) {
    return 'Người chơi: $players.';
  }

  @override
  String get rulesPokerIntro => 'Texas Hold’em. Mỗi người nhận 2 lá bài riêng; bàn có 5 lá bài chung.';

  @override
  String get rulesPokerPlay => 'Vòng cược: preflop, flop, turn và river. Có thể fold, call, bet hoặc raise.';

  @override
  String get rulesPokerWin => 'Thắng bằng bộ năm lá mạnh nhất (riêng + chung), hoặc người còn lại sau khi người khác fold.';

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
  String get gamesRules => 'Luật';

  @override
  String get gamesRulesTitle => 'Luật chơi';

  @override
  String get gamesCreate => 'Tạo trận';

  @override
  String get gamesJoin => 'Tham gia';

  @override
  String get gamesOpponentTurn => 'Lượt đối thủ';

  @override
  String get gamesCurrentGame => 'Trận hiện tại';

  @override
  String get gamesInvitedYou => 'Bạn được mời';

  @override
  String get gamesTurnTime => 'Thời gian lượt';

  @override
  String get gamesGridSize => 'Kích thước bàn';

  @override
  String get gamesSwapSides => 'Đổi bên';

  @override
  String get gamesNoCenter => 'Không bắt đầu ở giữa';

  @override
  String get gamesObservation => 'Đang xem';

  @override
  String get gamesObservationHint => 'Bạn có thể xem đến khi ván kết thúc';

  @override
  String get gamesFinishCurrentFirst => 'Hãy hoàn thành ván hiện tại trước';

  @override
  String get gamesVariantClassic => 'Cổ điển';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 người';

  @override
  String get gamesVariantMulti4 => '4 người';

  @override
  String get gamesDurakModePodkidnoi => 'Đánh thêm';

  @override
  String get gamesDurakModePerevodnoi => 'Chuyển';

  @override
  String get gamesDurakDeck24 => '24 lá';

  @override
  String get gamesDurakDeck36 => '36 lá';

  @override
  String get gamesDurakDeck52 => '52 lá';

  @override
  String rulesDurakMode(String mode) {
    return 'Chế độ: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'Người chơi: $players. Bộ bài: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Chơi với bot, không cược và không giới hạn thời gian.';

  @override
  String get rulesDurakAttack => 'Người tấn đánh bài; người thủ chắn (cùng chất cao hơn, hoặc át). Át chỉ bị chắn bởi át cao hơn.';

  @override
  String get rulesDurakBeat => 'Khi tất cả bài đã bị chắn, người tấn nói «Bito» và bài vào chồng bỏ. Nếu không, người thủ lấy hết bài trên bàn.';

  @override
  String get rulesDurakLoser => 'Người thua là người còn bài lúc kết thúc — «kẻ ngốc».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Người chơi $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Phòng chờ $name';
  }

  @override
  String get lobbyMatchmake => 'Sảnh';

  @override
  String get lobbyPrivateGame => 'Trận riêng';

  @override
  String get lobbySearchingOpponent => 'Đang tìm đối thủ…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Đang tìm trận này: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Đang chờ ai đó nhấn “Tìm trận” hoặc “Tham gia”';

  @override
  String get lobbyInviteTitle => 'Lời mời chơi';

  @override
  String get lobbyInvitedToPlay => 'Bạn được mời chơi';

  @override
  String get lobbyEnterGame => 'Vào trận';

  @override
  String get lobbyGone => 'Sảnh không còn khả dụng';

  @override
  String get lobbyInvite => 'Mời';

  @override
  String get lobbyInviteSent => 'Đã gửi lời mời';

  @override
  String get lobbyCopyLink => 'Chia sẻ liên kết trận';

  @override
  String get lobbyLinkCopied => 'Đã sao chép liên kết';

  @override
  String get lobbyNoFriendsOnline => 'Không có bạn bè đang online. Chia sẻ liên kết phía trên hoặc chờ bạn bè online.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Đối thủ';

  @override
  String get gameYou => 'Bạn';

  @override
  String get gameYouWon => 'Bạn thắng!';

  @override
  String get gameYouWonShort => 'Bạn thắng';

  @override
  String get gameYouLost => 'Bạn thua';

  @override
  String get gameYouWonOpponentLeft => 'Bạn thắng — đối thủ đã rời';

  @override
  String get gameYouWonOpponentTimeout => 'Bạn thắng — đối thủ hết giờ';

  @override
  String get gameDraw => 'Hòa';

  @override
  String get gameExitTitle => 'Rời trận';

  @override
  String get gameExitConfirm => 'Nếu rời đi, bạn sẽ thua. Vẫn rời?';

  @override
  String get gameStay => 'Ở lại';

  @override
  String get gameLeave => 'Rời';

  @override
  String get gameSurrender => 'Đầu hàng';

  @override
  String get gameSurrenderTitle => 'Đầu hàng?';

  @override
  String get gameSurrenderConfirm => 'Bạn sẽ thua ván và xu cược.';

  @override
  String get gameOfferDraw => 'Đề nghị hòa';

  @override
  String get gameFlipBoard => 'Lật bàn cờ';

  @override
  String get gameReviewStart => 'Về đầu ván';

  @override
  String get gameReviewPrev => 'Lùi một nước';

  @override
  String get gameReviewNext => 'Tiến một nước';

  @override
  String get gameReviewEnd => 'Về vị trí hiện tại';

  @override
  String get gameOfferDrawTitle => 'Đề nghị hòa?';

  @override
  String get gameOfferDrawConfirm => 'Đối thủ có thể chấp nhận hoặc từ chối hòa.';

  @override
  String get gameAcceptDrawTitle => 'Chấp nhận hòa?';

  @override
  String get gameAcceptDrawConfirm => 'Ván sẽ kết thúc hòa.';

  @override
  String get gameDrawOffered => 'Đối thủ đề nghị hòa';

  @override
  String get gameConnecting => 'Đang kết nối trận…';

  @override
  String get gameWaitingOpponent => 'Đang chờ đối thủ';

  @override
  String get gameRematchOffer => 'Đối thủ đề nghị tái đấu';

  @override
  String get gameRematchDeclined => 'Đối thủ từ chối tái đấu';

  @override
  String get gameRematch => 'Tái đấu';

  @override
  String get gameOtherOpponent => 'Đối thủ khác';

  @override
  String get gameSwapSidesAction => 'Đổi bên';

  @override
  String get gameWriteMessage => 'Viết tin nhắn';

  @override
  String get chatsTitle => 'Trò chuyện';

  @override
  String get chatsEmpty => 'Chưa có cuộc trò chuyện.\nChạm biểu tượng góc trên bên phải để chọn bạn và bắt đầu.';

  @override
  String get chatsNewChat => 'Trò chuyện mới';

  @override
  String get chatsNoMessages => 'Không có tin nhắn';

  @override
  String get chatsClearTitle => 'Xóa cuộc trò chuyện?';

  @override
  String get chatsClearDesc => 'Cuộc trò chuyện sẽ bị xóa vĩnh viễn.';

  @override
  String get chatsClearConfirm => 'Xóa';

  @override
  String get chatsBlockTitle => 'Chặn người dùng này?';

  @override
  String get chatsBlockDesc => 'Hai bên sẽ không thể nhắn tin cho nhau. Cuộc trò chuyện và tình bạn sẽ bị xóa.';

  @override
  String get chatsBlockConfirm => 'Chặn';

  @override
  String get chatsBlockedUsers => 'Người dùng đã chặn';

  @override
  String get chatsUnblock => 'Bỏ chặn';

  @override
  String get chatDialog => 'Trò chuyện';

  @override
  String get chatEmpty => 'Chưa có tin nhắn.\nHãy gửi tin đầu tiên.';

  @override
  String get chatMessageHint => 'Tin nhắn';

  @override
  String get chatPaste => 'Dán';

  @override
  String get chatEmoji => 'Emoji';

  @override
  String get chatBuyEmojiHint => 'Mua emoji tại cửa hàng trên trang chủ';

  @override
  String get chatEditing => 'Đang sửa';

  @override
  String get chatToday => 'Hôm nay';

  @override
  String get chatYesterday => 'Hôm qua';

  @override
  String get chatFriendsOnly => 'Chữ chỉ dành cho bạn bè';

  @override
  String get emojiGroupEmotions => 'Cảm xúc';

  @override
  String get emojiGroupGame => 'Trò chơi';

  @override
  String get emojiGroupFlags => 'Cờ';

  @override
  String get emojiGroupAnimals => 'Động vật';

  @override
  String get emojiGroupFood => 'Đồ ăn';

  @override
  String get emojiGroupTravel => 'Du lịch';

  @override
  String get emojiGroupParty => 'Lễ hội';

  @override
  String get emojiGroupObjects => 'Đồ vật';

  @override
  String get friendsTitle => 'Bạn bè';

  @override
  String get friendsTabFriends => 'Bạn bè';

  @override
  String get friendsTabIncoming => 'Đến';

  @override
  String get friendsTabOutgoing => 'Đi';

  @override
  String get friendsAdd => 'Thêm bạn';

  @override
  String get friendsRequestSent => 'Đã gửi lời mời';

  @override
  String get friendsFindTab => 'Tìm bạn';

  @override
  String get friendsSearchHint => 'Tìm theo tên người dùng';

  @override
  String get friendsSearchPrompt => 'Dùng tìm kiếm để kết bạn mới';

  @override
  String get friendsNothingFound => 'Không tìm thấy';

  @override
  String get friendsEmpty => 'Bạn chưa có bạn bè';

  @override
  String get friendsSearchNoMatches => 'Không có bạn bè khớp với tìm kiếm';

  @override
  String get friendsIncomingSearchNoMatches => 'Không có lời mời đến khớp với tìm kiếm';

  @override
  String get friendsOutgoingSearchNoMatches => 'Không có lời mời đi khớp với tìm kiếm';

  @override
  String get friendsNoIncoming => 'Không có lời mời đến';

  @override
  String get friendsNoOutgoing => 'Không có lời mời đi';

  @override
  String get friendsAlreadyFriends => 'Đã là bạn bè';

  @override
  String get friendsRemoveTitle => 'Xóa khỏi bạn bè?';

  @override
  String get friendsRemoved => 'Đã xóa khỏi bạn bè';

  @override
  String get friendsRequestAccepted => 'Đã chấp nhận lời mời';

  @override
  String get friendsRequestDeclined => 'Đã từ chối lời mời';

  @override
  String get friendsRequestCancelled => 'Đã hủy lời mời';

  @override
  String get profileTitle => 'Hồ sơ';

  @override
  String get profileSignInPrompt => 'Đăng nhập tài khoản của bạn';

  @override
  String get profileSignInHint => 'Để thiết lập hồ sơ cá nhân';

  @override
  String get profileEdit => 'Sửa';

  @override
  String get profileCollections => 'Bộ sưu tập';

  @override
  String get profileAge => 'Tuổi';

  @override
  String get profileGender => 'Giới tính';

  @override
  String get profileGenderUnset => 'Chưa đặt';

  @override
  String get profileGenderMale => 'Nam';

  @override
  String get profileGenderFemale => 'Nữ';

  @override
  String get profileAvatar => 'Ảnh đại diện';

  @override
  String get profileUploadPhoto => 'Tải ảnh lên';

  @override
  String get profileChangePhoto => 'Đổi ảnh đại diện';

  @override
  String get shopTitle => 'Cửa hàng';

  @override
  String get shopEmojis => 'Emoji';

  @override
  String get shopEmojisSubtitle => 'Emoji động cho trò chuyện';

  @override
  String get shopCollections => 'Bộ sưu tập';

  @override
  String get shopCollectionsSubtitle => 'Trưng bày hồ sơ, quà tặng và thu nhập';

  @override
  String get shopStakes => 'Cược';

  @override
  String get shopStakesSubtitle => 'Mở khóa cược cao hơn';

  @override
  String get shopEmojisHelp => 'Emoji động cho trò chuyện. Mua bộ và gửi cho bạn bè.';

  @override
  String get shopCollectionsHelp => 'Chỉ bán được bộ sưu tập mới hoặc cổ điển: 80% giá khi mới và 300% giá khi cổ điển. Sờn, mệt và cũ nát không bán được.\n\nThu thập bộ vật phẩm: chúng hiện trên tủ trưng bày hồ sơ, có thể tặng. Mỗi vật phẩm mang xu mỗi ngày, và bộ đủ còn thêm một khoản thưởng riêng.\n\nThu nhập hằng ngày của vật phẩm phụ thuộc trạng thái và là một phần của mức thường. Mới mang 100%. Sờn mang 60%. Mệt mang 40%. Cũ nát mang 100%. Vật phẩm cổ điển mang 200%, gấp đôi thu nhập hằng ngày thường.\n\nThưởng của bộ đủ không đổi cho đến khi cả bộ trở thành cổ điển. Bộ là cổ điển khi mọi vật phẩm trong đó đều cổ điển: thưởng khi ấy là 300%, gấp ba mức thường.\n\nTrạng thái phụ thuộc bạn giữ vật phẩm bao lâu. Mới — 7 ngày đầu. Sờn — từ ngày 8 đến 2 tháng. Mệt — từ 2 đến 6 tháng. Cũ nát — từ 6 tháng đến 1 năm. Cổ điển — từ 1 năm.';

  @override
  String get shopStakesHelp => 'Mở khóa mức cược cao hơn. Cược càng cao, pot và phần thắng càng lớn.';

  @override
  String get inventoryTitle => 'Vật phẩm';

  @override
  String get inventoryEmpty => 'Chưa có gì ở đây — xem cửa hàng';

  @override
  String get inventoryFrames => 'Khung';

  @override
  String get inventoryClaim => 'Nhận';

  @override
  String get inventorySell => 'Bán';

  @override
  String get inventoryGift => 'Tặng';

  @override
  String get messageEdited => 'đã sửa';

  @override
  String get messageDeleted => 'Tin nhắn đã bị xóa';

  @override
  String get photo => 'Ảnh';

  @override
  String get camera => 'Máy ảnh';

  @override
  String get gallery => 'Thư viện';

  @override
  String get connectionError => 'Không thể kết nối máy chủ.';

  @override
  String get serverError => 'Lỗi máy chủ. Vui lòng thử lại sau.';

  @override
  String get sessionExpired => 'Phiên đã hết hạn. Vui lòng đăng nhập lại.';

  @override
  String get errNoInternet => 'Không có kết nối internet.';

  @override
  String get errTimeout => 'Hết thời gian chờ. Vui lòng thử lại.';

  @override
  String get errGamesUnavailable => 'Trò chơi tạm thời không khả dụng';

  @override
  String get errSettingsSaveFailed => 'Không thể lưu cài đặt';

  @override
  String get errPushPermission => 'Cho phép thông báo trong trình duyệt hoặc cài đặt hệ thống.';

  @override
  String get balanceTitle => 'Số dư';

  @override
  String get coinBronze => 'Đồng';

  @override
  String get coinSilver => 'Bạc';

  @override
  String get coinGold => 'Vàng';

  @override
  String get coinDiamond => 'Kim cương';

  @override
  String get balanceZeroBronze => '0 đồng';

  @override
  String balanceBronzes(int count) {
    return '$count đồng';
  }

  @override
  String balanceSilvers(int count) {
    return '$count bạc';
  }

  @override
  String balanceGolds(int count) {
    return '$count vàng';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count kim cương';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/ngày';
  }

  @override
  String get balanceAbbrBronze => 'đ';

  @override
  String get balanceAbbrSilver => 'b.';

  @override
  String get balanceAbbrGold => 'v.';

  @override
  String get commonBackHome => 'Về trang chủ';

  @override
  String get commonCopied => 'Đã sao chép';

  @override
  String get commonClear => 'Xóa';

  @override
  String get commonTryLater => 'Vui lòng thử lại sau.';

  @override
  String get commonTryRefresh => 'Hãy thử làm mới trang.';

  @override
  String get coinsTitle => 'Xu';

  @override
  String get coinsLoginReward => 'Thưởng đăng nhập';

  @override
  String get coinsLoginAvailableToday => 'Thưởng hôm nay đã sẵn sàng';

  @override
  String get coinsLoginStreak => 'Chuỗi đăng nhập hàng ngày';

  @override
  String get coinsFriendReward => 'Thưởng bạn bè';

  @override
  String get coinsTasks => 'Nhiệm vụ';

  @override
  String get coinsTasksSubtitle => 'Phần thưởng cho hồ sơ, bạn bè và trận đấu';

  @override
  String get coinsTasksRewards => 'Có phần thưởng để nhận';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount khi đăng ký qua liên kết của bạn';
  }

  @override
  String get coinsLoadRewardsFailed => 'Không thể tải phần thưởng';

  @override
  String get coinsClaimReward => 'Nhận thưởng';

  @override
  String get coinsAlreadyClaimed => 'Đã nhận';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · hôm nay';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · còn 1 ngày';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · còn $remaining';
  }

  @override
  String get coinsInviteFriend => 'Mời bạn';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount cho mỗi người đăng ký qua liên kết của bạn';
  }

  @override
  String get coinsCopyLink => 'Sao chép liên kết';

  @override
  String get coinsHowItWorks => 'Cách hoạt động';

  @override
  String get coinsHowStep1 => 'Sao chép liên kết và gửi cho bạn';

  @override
  String get coinsHowStep2 => 'Bạn đăng ký qua liên kết đó';

  @override
  String coinsHowStep3(String amount) {
    return 'Bạn nhận được $amount';
  }

  @override
  String get achievementsTitle => 'Thành tựu';

  @override
  String achievementsProgress(String progress) {
    return 'Tiến độ: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Đã nhận khung';

  @override
  String get achievementsClaimed => 'Đã nhận';

  @override
  String get achievementsOpenFrame => 'Mở khung';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Bạn có chắc muốn xóa $name khỏi bạn bè?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Xóa';

  @override
  String get friendsRemove => 'Xóa khỏi bạn bè';

  @override
  String get friendsAcceptRequest => 'Chấp nhận lời mời';

  @override
  String get friendsDeclineRequest => 'Từ chối lời mời';

  @override
  String get friendsCancelRequest => 'Hủy lời mời';

  @override
  String get friendsSendRequest => 'Gửi lời mời kết bạn';

  @override
  String get friendsRequestAlreadySent => 'Đã gửi lời mời';

  @override
  String get friendsIncomingStatus => 'Lời mời đến';

  @override
  String get friendsOutgoingStatus => 'Lời mời đi';

  @override
  String get friendsNotFriends => 'Chưa phải bạn bè';

  @override
  String get friendsCollapseSearch => 'Thu gọn tìm kiếm';

  @override
  String get friendsExpandSearch => 'Hiện tìm kiếm';

  @override
  String get friendsLoadFailed => 'Không thể tải bạn bè';

  @override
  String friendsSince(String date) {
    return 'Bạn bè từ: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Lời mời đến: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Lời mời đi: $date';
  }

  @override
  String get userInfoTitle => 'Thông tin người dùng';

  @override
  String profileAgeYears(int age) {
    return '$age tuổi';
  }

  @override
  String get shopBuy => 'Mua';

  @override
  String get shopBuyTitle => 'Mua?';

  @override
  String get shopBuyStakeTitle => 'Mua mức cược?';

  @override
  String get shopBuyEmojiTitle => 'Mua emoji?';

  @override
  String get shopBuyCollectionTitle => 'Mua bộ sưu tập?';

  @override
  String shopPrice(String price) {
    return 'Giá: $price';
  }

  @override
  String get shopOwned => 'Đã mua';

  @override
  String get shopHave => 'Có';

  @override
  String get shopEmpty => 'Vẫn trống';

  @override
  String shopPurchased(String title) {
    return 'Đã mua $title';
  }

  @override
  String get shopEmojiUses => 'Bạn nhận: 10 lượt dùng';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 lượt dùng';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 lượt dùng';
  }

  @override
  String get shopBuyTen => 'Mua · 10 cái';

  @override
  String shopDailyIncome(String amount) {
    return 'Thu nhập: $amount';
  }

  @override
  String get shopBuyOnce => 'Mua một lần';

  @override
  String get shopSellRefund => 'Giá bán phụ thuộc trạng thái bộ sưu tập';

  @override
  String get collectionConditionNew => 'Mới';

  @override
  String get collectionConditionWorn => 'Sờn';

  @override
  String get collectionConditionTired => 'Mệt';

  @override
  String get collectionConditionShabby => 'Cũ nát';

  @override
  String get collectionConditionVintage => 'Cổ điển';

  @override
  String shopCollectionAdded(String title) {
    return 'Đã thêm $title vào hồ sơ';
  }

  @override
  String shopSetBonus(int percent) {
    return 'thưởng bộ +$percent%';
  }

  @override
  String get shopSetComplete => 'Hoàn thành';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Đã thu thập · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Bán?';

  @override
  String inventorySellDesc(String amount) {
    return 'Bạn sẽ nhận $amount';
  }

  @override
  String get inventoryCollectionNotSellable => 'Chỉ bán được bộ sưu tập mới hoặc cổ điển.';

  @override
  String get inventoryCollectionNotSellableTitle => 'Không bán được';

  @override
  String get inventoryCollectionNotSellableHint => 'Chỉ bán được vật phẩm mới hoặc cổ điển. Hãy dùng thuốc tiên để đổi trạng thái.';

  @override
  String inventorySold(String amount) {
    return 'Đã bán: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Hãy thêm bạn trước';

  @override
  String get inventoryGiftTitle => 'Tặng bộ sưu tập?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'Tặng «$title» cho $name?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Đã tặng: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'Người chơi đã sở hữu vật phẩm này';

  @override
  String get inventoryGiftSelf => 'Bạn không thể tặng cho chính mình';

  @override
  String get inventoryGiftNotOwned => 'Vật phẩm này không có trong túi đồ';

  @override
  String get inventoryLoadFailed => 'Không thể tải vật phẩm';

  @override
  String get inventoryNoCollections => 'Không có bộ sưu tập — mua trong cửa hàng';

  @override
  String get inventoryNoEmojis => 'Không có emoji — mua trong cửa hàng';

  @override
  String get inventoryNoFrames => 'Không có khung — thắng 10 trận giải (thành tựu)';

  @override
  String get inventoryNoStakes => 'Không có mức cược đã mua';

  @override
  String inventoryEmojiLeft(int count) {
    return 'Còn $count';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Thu nhập: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Thu nhập ngày mai: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Sẵn sàng';

  @override
  String get inventoryIncomeTomorrowLabel => 'Ngày mai';

  @override
  String inventoryStakeGold(String amount) {
    return 'Có thể cược $amount vàng';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'Có thể cược $amount bạc';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'Đã nhận +$amount';
  }

  @override
  String get chatsLoadFailed => 'Không thể tải chat';

  @override
  String get chatsLoadListFailed => 'Không thể tải danh sách';

  @override
  String get chatsBlockedEmpty => 'Danh sách trống';

  @override
  String chatsBlockedAt(String date) {
    return 'Đã chặn: $date';
  }

  @override
  String get chatsCreateFailed => 'Không thể tạo chat';

  @override
  String get chatsNeedFriendsFirst => 'Hãy thêm bạn trước, rồi mới mở chat.';

  @override
  String get chatsFriendsNotFound => 'Không tìm thấy bạn';

  @override
  String get chatsFindFriendHint => 'Tìm bạn theo biệt danh';

  @override
  String get chatsSelectChat => 'Chọn chat';

  @override
  String get chatsSelectHint => 'Chọn cuộc trò chuyện từ danh sách bên trái';

  @override
  String get chatEditFailed => 'Không thể sửa tin nhắn';

  @override
  String get chatSendFailed => 'Không thể gửi tin nhắn';

  @override
  String get chatDeleteFailed => 'Không thể xóa tin nhắn';

  @override
  String get chatEmojiSendFailed => 'Không thể gửi emoji';

  @override
  String get chatLoadFailed => 'Không thể tải tin nhắn';

  @override
  String get chatBackToGame => 'Quay lại trò chơi';

  @override
  String get chatBackToChats => 'Quay lại chat';

  @override
  String get chatActions => 'Thao tác chat';

  @override
  String get chatAutoTranslate => 'Auto-translate';

  @override
  String get chatScrollToEnd => 'Đến cuối cuộc trò chuyện';

  @override
  String chatReplyingTo(String name) {
    return 'Trả lời $name';
  }

  @override
  String get chatGift => 'Quà';

  @override
  String get chatCollection => 'Bộ sưu tập';

  @override
  String get chatGiftCollection => 'Quà · bộ sưu tập';

  @override
  String get chatThisUser => 'người dùng này';

  @override
  String get gamesLobbyLoadFailed => 'Không thể tải sảnh.';

  @override
  String get gamesTapChangeStake => 'Chạm để đổi mức cược';

  @override
  String get gamesTapChangeTurnTime => 'Chạm để đổi thời gian lượt';

  @override
  String get gamesTapChangeGrid => 'Chạm để đổi kích thước lưới';

  @override
  String get gamesSwapSidesHint => 'O có thể thành X sau nước đầu';

  @override
  String get gamesNoCenterHint => 'Nước đầu không được ở giữa';

  @override
  String get lobbyInviteSentShort => 'Đã gửi';

  @override
  String get lobbySearchShort => 'Tìm';

  @override
  String get lobbySearchPlayers => 'Tìm người chơi';

  @override
  String get lobbyInviteDeclinedShort => 'Đã từ chối';

  @override
  String get lobbyInvitesSentWaiting => 'Đã gửi lời mời. Đang chờ phản hồi.';

  @override
  String get lobbyLinkCopiedHint => 'Dán vào chat hoặc tin nhắn gửi bạn';

  @override
  String get lobbyCopyLinkHint => 'Sao chép liên kết vào bộ nhớ tạm';

  @override
  String lobbyCreatorInvites(String name, String game) {
    return '$name mời bạn chơi $game';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name thắng';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Hết giờ. $name thắng';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds giây';
  }

  @override
  String get adminTitle => 'Quản trị';

  @override
  String get tournamentsTitle => 'Giải đấu';

  @override
  String get profileAgeInvalid => 'Nhập tuổi từ 1 đến 111';

  @override
  String get profileSaveFailed => 'Không thể lưu hồ sơ';

  @override
  String get profileNameHint => 'Chữ Latinh, số, _ tối đa 10 ký tự';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'Từ 1 đến 111';

  @override
  String get profileAboutHint => 'Tối đa 100 ký tự (tùy chọn)';

  @override
  String get profileProcessingPhoto => 'Đang xử lý ảnh…';

  @override
  String get profileCropTitle => 'Chọn vùng ảnh đại diện';

  @override
  String get profileCropHint => 'Phóng to và di chuyển ảnh';

  @override
  String get profileApply => 'Áp dụng';

  @override
  String get profilePreparing => 'Đang chuẩn bị…';

  @override
  String get profileGalleryTitle => 'Ảnh';

  @override
  String get profileGalleryAdd => 'Thêm ảnh';

  @override
  String get profileMakePrimary => 'Đặt làm ảnh chính';

  @override
  String get profilePhotoDelete => 'Xóa ảnh';

  @override
  String get profilePhotosLimit => 'Có thể tải lên tối đa 3 ảnh';

  @override
  String get profilePhotosEmpty => 'Chưa có ảnh';

  @override
  String get profilePhotoUploadFailed => 'Không tải được ảnh';

  @override
  String get profilePhotoDeleteFailed => 'Không xóa được ảnh';

  @override
  String get profilePhotoTooLarge => 'Ảnh quá lớn';

  @override
  String get profileSetPrimaryFailed => 'Không đặt được làm ảnh chính';

  @override
  String timeSecondsShort(int seconds) {
    return '$seconds giây';
  }

  @override
  String get timeOneMin => '1 phút';

  @override
  String get timeTenMin => '10 phút';

  @override
  String rulesIntro(String grid) {
    return 'Cờ caro trên bàn $grid. Đi lần lượt, X đi trước.';
  }

  @override
  String rulesWin(int n) {
    return 'Thắng: xếp $n ô liên tiếp ngang, dọc hoặc chéo.';
  }

  @override
  String get rulesNoTimeLimit => 'Không giới hạn thời gian mỗi lượt.';

  @override
  String rulesTurnTime(String time) {
    return 'Thời gian mỗi lượt: $time. Hết giờ là thua.';
  }

  @override
  String rulesStake(String stake) {
    return 'Cược: $stake. Ván chơi với số xu này.';
  }

  @override
  String get rulesSwap => 'Đổi bên: O có thể đổi chỗ với X sau nước đầu của X.';

  @override
  String get rulesNoCenter => 'Cấm giữa: X không được đánh ô giữa ở nước đầu.';

  @override
  String get collectionSetLegends => 'Huyền thoại';

  @override
  String get collectionSetSpace => 'Không gian';

  @override
  String get collectionSetGems => 'Đá quý';

  @override
  String get collectionSetParty => 'Tiệc';

  @override
  String get collectionSetNature => 'Thiên nhiên';

  @override
  String get collectionSetAdventures => 'Phiêu lưu';

  @override
  String collectionCardMeta(String amount) {
    return 'Bộ sưu tập · trưng bày · quà · bán · +$amount';
  }

  @override
  String get coinsDayOne => 'ngày';

  @override
  String get coinsDayFew => 'ngày';

  @override
  String get coinsDayMany => 'ngày';

  @override
  String get giftFriendTitle => 'Tặng bạn bè';

  @override
  String photoCount(int count) {
    return 'Ảnh ($count)';
  }

  @override
  String photoCountWithText(int count, String text) {
    return 'Ảnh ($count): $text';
  }

  @override
  String photoWithText(String text) {
    return 'Ảnh: $text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count emoji · $price';
  }

  @override
  String get chatsExpandPanel => 'Mở rộng bảng';

  @override
  String get chatsCollapsePanel => 'Thu gọn bảng';

  @override
  String get chatReplySourceMissing => 'Không tìm thấy tin nhắn gốc';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Cược $n bạc';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Cược $n vàng';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Mở khóa cược $n bạc';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Mở khóa cược $n vàng';
  }

  @override
  String get chatReplySelf => 'chính bạn';

  @override
  String get chatReplyPeer => 'đối phương';

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
  String get statsTitle => 'Thống kê';

  @override
  String get statsLoadFailed => 'Không tải được thống kê';

  @override
  String get statsAllGames => 'Tất cả trò chơi';

  @override
  String get statsEmptyTitle => 'Chưa có ván nào';

  @override
  String get statsEmptyHint => 'Chơi ván đầu để thống kê hiện ở đây.';

  @override
  String get statsWins => 'Thắng';

  @override
  String get statsDraws => 'Hòa';

  @override
  String get statsLosses => 'Thua';

  @override
  String get statsWinRate => 'Tỷ lệ thắng';

  @override
  String get statsTopWon => 'Thắng nhiều nhất trước';

  @override
  String get statsTopDrawn => 'Hòa nhiều nhất với';

  @override
  String get statsTopLost => 'Thua nhiều nhất trước';

  @override
  String get statsTimePlayed => 'Thời gian chơi';

  @override
  String get statsYourScore => 'Tỷ số của bạn';

  @override
  String get profileShowStats => 'Hiện thống kê';

  @override
  String get statsDurationZeroMinutes => '0 phút';

  @override
  String get gameYouWonOpponentForfeit => 'Đối thủ đầu hàng. Bạn thắng!';

  @override
  String get lobbyLeaveTitle => 'Rời sảnh?';

  @override
  String get lobbyLeaveConfirm => 'Sảnh sẽ bị xóa sau khi bạn rời. Bạn bè được mời sẽ nhận từ chối.';

  @override
  String get lobbyLeave => 'Rời';

  @override
  String statsDurationHours(int hours) {
    return '$hours giờ';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours giờ $minutes phút';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'Bạn đầu hàng. $name thắng';
  }

  @override
  String get supportTitle => 'Hỗ trợ';

  @override
  String get supportUnavailable => 'Hỗ trợ không khả dụng';

  @override
  String get supportOpenFailed => 'Không thể mở chat hỗ trợ';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Bạn đã được cộng $amount xu';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return 'Đã trừ $amount xu';
  }

  @override
  String get coinsCreditCardTitle => 'Bạn đã được cộng xu';

  @override
  String get coinsClaim => 'Nhận';

  @override
  String get durakActionPass => 'Bỏ';

  @override
  String get durakRoleTook => 'Nhận';

  @override
  String get durakRoleBeats => 'Chắn';

  @override
  String get durakRoleThrowIn => 'Đánh thêm';

  @override
  String get durakRoleTurn => 'Lượt';

  @override
  String get durakRoleDefends => 'Đang chắn';

  @override
  String get durakStatusTaking => 'Đang nhận';

  @override
  String get durakHintDefenderTurn => 'Lượt người chắn';

  @override
  String get gameYouEliminated => 'Bạn đã bị loại';

  @override
  String gameYouPlaced(int place) {
    return 'Bạn xếp hạng $place';
  }

  @override
  String get gameOverNeutral => 'Ván đã kết thúc';

  @override
  String gameTurnOf(String name) {
    return 'Lượt của $name';
  }

  @override
  String get chatGroupTooltip => 'Chat nhóm';

  @override
  String get lobbyChatNotReady => 'Chat sảnh chưa sẵn sàng';

  @override
  String get chatsGroupChat => 'Chat nhóm';

  @override
  String chatsMembersCount(int count) {
    return 'Thành viên: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count ng.';
  }

  @override
  String get chatsYouSuffix => '(bạn)';

  @override
  String get chatTitleDurak3 => 'Durak · 3 người';

  @override
  String get chatTitleDurak4 => 'Durak · 4 người';

  @override
  String get rulesTttUltimate => 'Ultimate: chín bàn 3×3. Một nước đưa đối thủ sang bàn đó. Thắng khi hoàn thành một hàng trên bàn meta.';

  @override
  String get rulesTttMulti3 => '3 người: bàn 3×3, ba người (X, O, △). Thắng khi hoàn thành một hàng bằng ký hiệu của bạn.';

  @override
  String get rulesTttMulti4 => '4 người: bàn 4×4, bốn người (X, O, △, □). Thắng khi hoàn thành một hàng bằng ký hiệu của bạn.';

  @override
  String get adminUsersTab => 'Người dùng';

  @override
  String get adminSupportTab => 'Hỗ trợ';

  @override
  String get adminSearchHint => 'Tìm theo email hoặc biệt danh';

  @override
  String get adminRoleAdmins => 'Quản trị';

  @override
  String get adminRoleUsers => 'Người dùng';

  @override
  String get adminRoleAll => 'Mọi vai trò';

  @override
  String get adminStatusFrozen => 'Đã đóng băng';

  @override
  String get adminStatusActive => 'Đang hoạt động';

  @override
  String get adminStatusAny => 'Mọi trạng thái';

  @override
  String get adminOrderDesc => 'Giảm dần';

  @override
  String get adminOrderAsc => 'Tăng dần';

  @override
  String adminLoadFailed(String error) {
    return 'Không tải được: $error';
  }

  @override
  String get adminUsersEmpty => 'Không có người dùng';

  @override
  String get adminSortLastSeen => 'Theo lần vào gần nhất';

  @override
  String get adminSortEmail => 'Theo email';

  @override
  String get adminSortCreated => 'Theo ngày đăng ký';

  @override
  String adminBronzeBalance(int amount) {
    return '$amount đồng';
  }

  @override
  String get adminRevokeAdmin => 'Gỡ quản trị';

  @override
  String get adminGrantAdmin => 'Đặt làm quản trị';

  @override
  String get adminAdminRevoked => 'Đã gỡ quyền quản trị';

  @override
  String get adminAdminGranted => 'Đã cấp quyền quản trị';

  @override
  String get adminGrantCoins => 'Cấp xu';

  @override
  String get adminWriteSupport => 'Viết với tư cách hỗ trợ';

  @override
  String get adminUnfreeze => 'Bỏ đóng băng';

  @override
  String get adminFreeze => 'Đóng băng';

  @override
  String get adminUnfrozen => 'Đã bỏ đóng băng';

  @override
  String get adminFrozenDone => 'Đã đóng băng';

  @override
  String get adminResetPassword => 'Đặt lại mật khẩu';

  @override
  String get adminCoinsAmountHint => 'Số lượng (âm = trừ)';

  @override
  String get adminReasonOptional => 'Lý do (không bắt buộc)';

  @override
  String get adminGrantSent => 'Đã gửi thẻ vào chat hỗ trợ';

  @override
  String adminCoinsDebited(int amount) {
    return 'Đã trừ $amount đồng';
  }

  @override
  String get adminGrantVerb => 'Cấp';

  @override
  String get adminNewPasswordHint => 'Mật khẩu mới (tối thiểu 6)';

  @override
  String get adminPasswordReset => 'Đã đặt lại mật khẩu';

  @override
  String get adminResetVerb => 'Đặt lại';

  @override
  String adminShortError(String error) {
    return 'Lỗi: $error';
  }

  @override
  String get adminSupportEmpty => 'Không có yêu cầu hỗ trợ';

  @override
  String get adminUserFallback => 'Người dùng';

  @override
  String get apiErrTooManyRequests => 'Quá nhiều yêu cầu. Hãy thử lại sau.';

  @override
  String get apiErrMoveConflict => 'Nước đi bị xung đột. Hãy thử lại.';

  @override
  String get shopElixirs => 'Elixirs';

  @override
  String get shopElixirsSubtitle => 'Rejuvenate, age, or speed up collections';

  @override
  String get shopElixirsHelp => 'Three shelves: rejuvenation, aging, and acceleration. Each has six elixirs, one per collection set. An elixir works only on its own set.\n\nRejuvenation makes a collection one step newer, and never newer than new. Aging makes it one step older, and never older than shabby. Acceleration is only for a shabby item: three months left until vintage, once. An elixir never grants vintage by itself.\n\nA bought elixir stays in Items. Use it from the collection card or from the elixir card. Each use spends one.';

  @override
  String get elixirGroupRejuvenate => 'Trẻ hóa';

  @override
  String get elixirGroupAge => 'Lão hóa';

  @override
  String get elixirGroupAccelerate => 'Tăng tốc';

  @override
  String get elixirEffectRejuvenate => 'trẻ hóa';

  @override
  String get elixirEffectAge => 'lão hóa';

  @override
  String get elixirEffectAccelerate => 'tăng tốc';

  @override
  String get elixirAdjCelebration => 'lễ hội';

  @override
  String get elixirAdjNature => 'thiên nhiên';

  @override
  String get elixirAdjLegends => 'huyền thoại';

  @override
  String get elixirAdjCosmic => 'vũ trụ';

  @override
  String get elixirAdjAdventure => 'phiêu lưu';

  @override
  String get elixirAdjJewels => 'quý';

  @override
  String elixirName(String adjective, String effect) {
    return 'Thuốc $effect $adjective';
  }

  @override
  String get elixirHelpRejuvenate => 'Makes the collection one step newer. Not newer than new.';

  @override
  String get elixirHelpAge => 'Makes the collection one step older. Not older than shabby.';

  @override
  String get elixirHelpAccelerate => 'Shabby only. Three months left until vintage, once.';

  @override
  String get elixirUseRejuvenate => 'Trẻ hóa';

  @override
  String get elixirUseAge => 'Lão hóa';

  @override
  String get elixirUseAccelerate => 'Tăng tốc';

  @override
  String get elixirUse => 'Dùng';

  @override
  String collectionLeftDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày',
      one: '$count ngày',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giờ',
      one: '$count giờ',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phút',
      one: '$count phút',
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
  String get statsRecentTitle => 'Ván gần đây';

  @override
  String get statsOutcomeWin => 'Thắng';

  @override
  String get statsOutcomeLoss => 'Thua';

  @override
  String get statsOutcomeDraw => 'Hòa';

  @override
  String get statsAllModes => 'Mọi chế độ';

  @override
  String statsDurakChip(int players, String deck) {
    return '$players · $deck';
  }

  @override
  String get statsSelectGame => 'Trò chơi';

  @override
  String get statsSelectMode => 'Chế độ';

  @override
  String get statsRecentEmpty => 'Chưa có ván nào';
}
