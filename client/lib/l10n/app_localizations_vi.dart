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
  String get lobbyGone => 'Этой игры уже нет';

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
  String get gameSurrender => 'Сдаться';

  @override
  String get gameSurrenderTitle => 'Сдаться?';

  @override
  String get gameSurrenderConfirm => 'Если вы сдадитесь, вы проиграете. Сдаться?';

  @override
  String get gameOfferDraw => 'Предложить ничью';

  @override
  String get gameOfferDrawTitle => 'Предложить ничью?';

  @override
  String get gameOfferDrawConfirm => 'Отправить сопернику предложение ничьей?';

  @override
  String get gameAcceptDrawTitle => 'Принять ничью?';

  @override
  String get gameAcceptDrawConfirm => 'Соперник предлагает ничью. Принять?';

  @override
  String get gameDrawOffered => 'Ожидание ответа';

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
  String get chatPaste => 'Вставить';

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
  String get shopSellRefund => 'Bán sẽ hoàn lại một phần chi phí';

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
  String get inventoryGiftAlreadyOwns => 'У этого пользователя уже есть эта коллекция';

  @override
  String get inventoryGiftSelf => 'Нельзя подарить коллекцию самому себе';

  @override
  String get inventoryGiftNotOwned => 'У вас нет этого предмета';

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
  String get inventoryIncomeReadyLabel => 'Доход:';

  @override
  String get inventoryIncomeTomorrowLabel => 'Доход завтра:';

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
  String get lobbyInvitesSentWaiting => 'Đã gửi lời mời. Đang chờ phản hồi.';

  @override
  String get lobbyLinkCopiedHint => 'Dán vào chat hoặc tin nhắn gửi bạn';

  @override
  String get lobbyCopyLinkHint => 'Sao chép liên kết vào bộ nhớ tạm';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name mời bạn chơi';
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
    return 'Thời gian mỗi lượt: $time.';
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
}
