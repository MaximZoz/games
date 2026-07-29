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
  String get settingsAddBotsTitle => 'Thêm bot sau 30 giây';

  @override
  String get settingsAddBotsSubtitle => 'Khi ghép trận: nếu không tìm thấy đối thủ trong 30 giây, trận sẽ bắt đầu với bot (cược đặt lại thành 1 đồng bronze)';

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
  String get timeJustNow => 'vừa xong';

  @override
  String get timeYesterday => 'hôm qua';

  @override
  String timeMinutesAgo(Object count) {
    return '$count phút trước';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count giờ trước';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count ngày trước';
  }

  @override
  String get timeWeekAgo => 'một tuần trước';

  @override
  String timeWeeksAgo(Object count) {
    return '$count tuần trước';
  }

  @override
  String get timeMonthAgo => 'một tháng trước';

  @override
  String timeMonthsAgo(Object count) {
    return '$count tháng trước';
  }

  @override
  String get timeYearAgo => 'một năm trước';

  @override
  String timeYearsAgo(Object count) {
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
  String get lobbyMatchmake => 'Sảnh';

  @override
  String get lobbyPrivateGame => 'Trận riêng';

  @override
  String get lobbySearchingOpponent => 'Đang tìm đối thủ…';

  @override
  String get lobbyWaitingJoin => 'Đang chờ ai đó nhấn “Tìm trận” hoặc “Tham gia”';

  @override
  String get lobbyInviteTitle => 'Lời mời chơi';

  @override
  String get lobbyInvitedToPlay => 'Bạn được mời chơi';

  @override
  String get lobbyEnterGame => 'Vào trận';

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
  String get gameYouWon => 'Bạn thắng!';

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
  String get profileChangePhoto => 'Đổi ảnh';

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
  String get shopStakesSubtitle => 'Mở khóa cược bạc';

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
}
