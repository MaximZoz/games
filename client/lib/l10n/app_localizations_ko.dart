import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => '홈';

  @override
  String get navProfile => '프로필';

  @override
  String get navFriends => '친구';

  @override
  String get navChats => '채팅';

  @override
  String get navGames => '게임';

  @override
  String get navSettings => '설정';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsLanguageSystem => '시스템 기본값';

  @override
  String get settingsAddBotsTitle => '30초 후 봇 추가';

  @override
  String get settingsAddBotsSubtitle => '매칭 중: 30초 안에 상대를 찾지 못하면 봇과 게임이 시작됩니다(배팅이 브론즈 1로 초기화됨)';

  @override
  String get settingsFriendsOnlyTitle => '친구 메시지만 받기';

  @override
  String get settingsFriendsOnlySubtitle => '친구가 아닌 사용자는 이모지만 보낼 수 있습니다. 스팸이 문제라면 일시적으로 차단하세요.';

  @override
  String get settingsNotifications => '알림';

  @override
  String get settingsPushChat => '채팅';

  @override
  String get settingsPushFriends => '친구';

  @override
  String get settingsPushGames => '게임';

  @override
  String get settingsPushRewards => '보상';

  @override
  String get loginTitle => '로그인';

  @override
  String get loginSubtitle => '이메일 또는 사용자 이름과 비밀번호를 입력하세요';

  @override
  String get loginEmailLabel => '이메일 또는 사용자 이름';

  @override
  String get loginPasswordLabel => '비밀번호';

  @override
  String get loginSubmit => '로그인';

  @override
  String get loginNoAccount => '계정이 없나요? 가입하기';

  @override
  String get loginEmailRequired => '이메일 또는 사용자 이름을 입력하세요';

  @override
  String get loginPasswordRequired => '비밀번호를 입력하세요';

  @override
  String get loginTooltip => '로그인';

  @override
  String get logoutTooltip => '로그아웃';

  @override
  String get registerTitle => '가입하기';

  @override
  String get registerSubtitle => '플레이하려면 계정을 만드세요';

  @override
  String get registerNameLabel => '이름(사용자 이름)';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => '비밀번호';

  @override
  String get registerSubmit => '가입하기';

  @override
  String get registerHaveAccount => '이미 계정이 있나요? 로그인';

  @override
  String get registerNameRequired => '이름을 입력하세요';

  @override
  String get registerNameNoSpaces => '이름에 공백을 포함할 수 없습니다';

  @override
  String get registerNameMax => '최대 20자';

  @override
  String get registerNameHint => '최대 20자';

  @override
  String get registerEmailRequired => '이메일을 입력하세요';

  @override
  String get registerEmailInvalid => '잘못된 이메일입니다';

  @override
  String get registerPasswordHint => '최소 6자';

  @override
  String get registerPasswordMin => '비밀번호는 최소 6자여야 합니다';

  @override
  String get commonCancel => '취소';

  @override
  String get commonSave => '저장';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonEdit => '편집';

  @override
  String get commonReply => '답장';

  @override
  String get commonSend => '보내기';

  @override
  String get commonClose => '닫기';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get commonLoading => '로딩 중…';

  @override
  String get commonError => '오류';

  @override
  String get commonOnline => '온라인';

  @override
  String get commonOffline => '오프라인';

  @override
  String get commonOnlineCap => '온라인';

  @override
  String get commonUser => '사용자';

  @override
  String get commonPlayer => '플레이어';

  @override
  String get commonAboutMe => '소개';

  @override
  String get commonBack => '뒤로';

  @override
  String get commonAccept => '수락';

  @override
  String get commonDecline => '거절';

  @override
  String get commonCreating => '생성 중…';

  @override
  String get commonSearching => '검색 중…';

  @override
  String get commonInsufficientCoins => '코인이 부족합니다';

  @override
  String get commonNotFound => '찾을 수 없음';

  @override
  String get commonServerErrorShort => '서버 오류';

  @override
  String get commonForbidden => '접근이 거부되었습니다';

  @override
  String get commonUserBlocked => '사용자가 차단되었습니다';

  @override
  String get commonUserNotFound => '사용자를 찾을 수 없습니다';

  @override
  String get commonGenericError => '문제가 발생했습니다. 다시 시도해 주세요.';

  @override
  String get timeJustNow => '방금';

  @override
  String get timeYesterday => '어제';

  @override
  String timeMinutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count일 전';
  }

  @override
  String get timeWeekAgo => '일주일 전';

  @override
  String timeWeeksAgo(int count) {
    return '$count주 전';
  }

  @override
  String get timeMonthAgo => '한 달 전';

  @override
  String timeMonthsAgo(int count) {
    return '$count개월 전';
  }

  @override
  String get timeYearAgo => '1년 전';

  @override
  String timeYearsAgo(int count) {
    return '$count년 전';
  }

  @override
  String get weekdaySun => '일';

  @override
  String get weekdayMon => '월';

  @override
  String get weekdayTue => '화';

  @override
  String get weekdayWed => '수';

  @override
  String get weekdayThu => '목';

  @override
  String get weekdayFri => '금';

  @override
  String get weekdaySat => '토';

  @override
  String get monthJan => '1월';

  @override
  String get monthFeb => '2월';

  @override
  String get monthMar => '3월';

  @override
  String get monthApr => '4월';

  @override
  String get monthMay => '5월';

  @override
  String get monthJun => '6월';

  @override
  String get monthJul => '7월';

  @override
  String get monthAug => '8월';

  @override
  String get monthSep => '9월';

  @override
  String get monthOct => '10월';

  @override
  String get monthNov => '11월';

  @override
  String get monthDec => '12월';

  @override
  String get homeAchievements => '업적';

  @override
  String get homeAchievementsSubtitle => '게임 결과';

  @override
  String get homeAchievementsRewards => '받을 수 있는 보상이 있습니다';

  @override
  String get homeCoins => '코인';

  @override
  String get homeCoinsSubtitle => '잔액 및 보상';

  @override
  String get homeCoinsDailyReward => '일일 로그인 보상을 받을 수 있습니다';

  @override
  String get homeItems => '아이템';

  @override
  String get homeItemsInventory => '인벤토리';

  @override
  String get homeItemsGifted => '누군가 컬렉션을 선물했습니다';

  @override
  String get homeItemsIncome => '컬렉션 수익을 받을 수 있습니다';

  @override
  String get homeShop => '상점';

  @override
  String get homeShopSubtitle => '이모지, 배팅, 컬렉션';

  @override
  String get gamesTitle => '게임';

  @override
  String get gamesFindMatch => '게임 찾기';

  @override
  String get gamesMyTurn => '내 차례';

  @override
  String get gamesWaiting => '대기 중';

  @override
  String get gamesLobbyTab => '로비';

  @override
  String get gamesTicTacToe => '틱택토';

  @override
  String get gamesRules => '규칙';

  @override
  String get gamesRulesTitle => '게임 규칙';

  @override
  String get gamesCreate => '게임 만들기';

  @override
  String get gamesJoin => '참가';

  @override
  String get gamesOpponentTurn => '상대 차례';

  @override
  String get gamesCurrentGame => '현재 게임';

  @override
  String get gamesInvitedYou => '초대받았습니다';

  @override
  String get gamesTurnTime => '턴 시간';

  @override
  String get gamesGridSize => '격자 크기';

  @override
  String get gamesSwapSides => '진영 교체';

  @override
  String get gamesNoCenter => '중앙 시작 금지';

  @override
  String get lobbyMatchmake => '로비';

  @override
  String get lobbyPrivateGame => '비공개 게임';

  @override
  String get lobbySearchingOpponent => '상대를 찾는 중…';

  @override
  String get lobbyWaitingJoin => '누군가 「게임 찾기」 또는 「참가」를 누를 때까지 대기 중';

  @override
  String get lobbyInviteTitle => '게임 초대';

  @override
  String get lobbyInvitedToPlay => '게임에 초대되었습니다';

  @override
  String get lobbyEnterGame => '게임 입장';

  @override
  String get lobbyGone => 'Этой игры уже нет';

  @override
  String get lobbyInvite => '초대';

  @override
  String get lobbyInviteSent => '초대를 보냈습니다';

  @override
  String get lobbyCopyLink => '게임 링크 공유';

  @override
  String get lobbyLinkCopied => '링크가 복사되었습니다';

  @override
  String get lobbyNoFriendsOnline => '온라인인 친구가 없습니다. 위 게임 링크를 공유하거나 친구가 접속할 때까지 기다리세요.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => '상대';

  @override
  String get gameYouWon => '이겼습니다!';

  @override
  String get gameYouWonOpponentLeft => '이겼습니다 — 상대가 나갔습니다';

  @override
  String get gameYouWonOpponentTimeout => '이겼습니다 — 상대 시간 초과';

  @override
  String get gameDraw => '무승부';

  @override
  String get gameExitTitle => '게임 나가기';

  @override
  String get gameExitConfirm => '나가면 패배합니다. 그래도 나가시겠습니까?';

  @override
  String get gameStay => '머물기';

  @override
  String get gameLeave => '나가기';

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
  String get gameConnecting => '게임에 연결 중…';

  @override
  String get gameWaitingOpponent => '상대를 기다리는 중';

  @override
  String get gameRematchOffer => '상대가 재경기를 제안합니다';

  @override
  String get gameRematchDeclined => '상대가 재경기를 거절했습니다';

  @override
  String get gameRematch => '재경기';

  @override
  String get gameOtherOpponent => '다른 상대';

  @override
  String get gameSwapSidesAction => '진영 교체';

  @override
  String get gameWriteMessage => '메시지 작성';

  @override
  String get chatsTitle => '채팅';

  @override
  String get chatsEmpty => '아직 채팅이 없습니다.\n오른쪽 위 아이콘을 눌러 친구를 선택하고 대화를 시작하세요.';

  @override
  String get chatsNewChat => '새 채팅';

  @override
  String get chatsNoMessages => '메시지 없음';

  @override
  String get chatsClearTitle => '대화를 지우시겠습니까?';

  @override
  String get chatsClearDesc => '채팅이 영구적으로 삭제됩니다.';

  @override
  String get chatsClearConfirm => '지우기';

  @override
  String get chatsBlockTitle => '이 사용자를 차단하시겠습니까?';

  @override
  String get chatsBlockDesc => '더 이상 메시지를 주고할 수 없습니다. 채팅과 친구 관계가 삭제됩니다.';

  @override
  String get chatsBlockConfirm => '차단';

  @override
  String get chatsBlockedUsers => '차단된 사용자';

  @override
  String get chatsUnblock => '차단 해제';

  @override
  String get chatDialog => '채팅';

  @override
  String get chatEmpty => '아직 메시지가 없습니다.\n첫 메시지를 보내 보세요.';

  @override
  String get chatMessageHint => '메시지';

  @override
  String get chatPaste => 'Вставить';

  @override
  String get chatEmoji => '이모지';

  @override
  String get chatBuyEmojiHint => '홈 화면 상점에서 이모지를 구매하세요';

  @override
  String get chatEditing => '편집 중';

  @override
  String get chatToday => '오늘';

  @override
  String get chatYesterday => '어제';

  @override
  String get chatFriendsOnly => '텍스트는 친구만';

  @override
  String get emojiGroupEmotions => '감정';

  @override
  String get emojiGroupGame => '게임';

  @override
  String get emojiGroupFlags => '국기';

  @override
  String get emojiGroupAnimals => '동물';

  @override
  String get emojiGroupFood => '음식';

  @override
  String get emojiGroupTravel => '여행';

  @override
  String get emojiGroupParty => '축하';

  @override
  String get emojiGroupObjects => '사물';

  @override
  String get friendsTitle => '친구';

  @override
  String get friendsTabFriends => '친구';

  @override
  String get friendsTabIncoming => '받은 요청';

  @override
  String get friendsTabOutgoing => '보낸 요청';

  @override
  String get friendsAdd => '친구 추가';

  @override
  String get friendsRequestSent => '요청을 보냈습니다';

  @override
  String get friendsFindTab => '친구 찾기';

  @override
  String get friendsSearchHint => '사용자 이름으로 검색';

  @override
  String get friendsSearchPrompt => '검색으로 새 친구를 찾아보세요';

  @override
  String get friendsNothingFound => '결과가 없습니다';

  @override
  String get friendsEmpty => '아직 친구가 없습니다';

  @override
  String get friendsNoIncoming => '받은 요청이 없습니다';

  @override
  String get friendsNoOutgoing => '보낸 요청이 없습니다';

  @override
  String get friendsAlreadyFriends => '이미 친구입니다';

  @override
  String get friendsRemoveTitle => '친구에서 삭제하시겠습니까?';

  @override
  String get friendsRemoved => '친구에서 삭제되었습니다';

  @override
  String get friendsRequestAccepted => '요청을 수락했습니다';

  @override
  String get friendsRequestDeclined => '요청을 거절했습니다';

  @override
  String get friendsRequestCancelled => '요청을 취소했습니다';

  @override
  String get profileTitle => '프로필';

  @override
  String get profileSignInPrompt => '계정에 로그인하세요';

  @override
  String get profileSignInHint => '개인 프로필을 설정하려면';

  @override
  String get profileEdit => '편집';

  @override
  String get profileCollections => '컬렉션';

  @override
  String get profileAge => '나이';

  @override
  String get profileGender => '성별';

  @override
  String get profileGenderUnset => '설정 안 됨';

  @override
  String get profileGenderMale => '남성';

  @override
  String get profileGenderFemale => '여성';

  @override
  String get profileAvatar => '아바타';

  @override
  String get profileUploadPhoto => '사진 업로드';

  @override
  String get profileChangePhoto => '사진 변경';

  @override
  String get shopTitle => '상점';

  @override
  String get shopEmojis => '이모지';

  @override
  String get shopEmojisSubtitle => '채팅용 애니메이션 이모지';

  @override
  String get shopCollections => '컬렉션';

  @override
  String get shopCollectionsSubtitle => '프로필 전시, 선물 및 수익';

  @override
  String get shopStakes => '배팅';

  @override
  String get shopStakesSubtitle => '실버 배팅 잠금 해제';

  @override
  String get inventoryTitle => '아이템';

  @override
  String get inventoryEmpty => '아직 아무것도 없습니다 — 상점을 확인해 보세요';

  @override
  String get inventoryFrames => '프레임';

  @override
  String get inventoryClaim => '받기';

  @override
  String get inventorySell => '판매';

  @override
  String get inventoryGift => '선물';

  @override
  String get messageEdited => '수정됨';

  @override
  String get messageDeleted => '메시지가 삭제되었습니다';

  @override
  String get photo => '사진';

  @override
  String get camera => '카메라';

  @override
  String get gallery => '갤러리';

  @override
  String get connectionError => '서버에 연결할 수 없습니다.';

  @override
  String get serverError => '서버 오류입니다. 나중에 다시 시도해 주세요.';

  @override
  String get sessionExpired => '세션이 만료되었습니다. 다시 로그인해 주세요.';

  @override
  String get errNoInternet => '인터넷에 연결되어 있지 않습니다.';

  @override
  String get errTimeout => '요청 시간이 초과되었습니다. 다시 시도해 주세요.';

  @override
  String get errGamesUnavailable => '게임을 일시적으로 이용할 수 없습니다';

  @override
  String get errSettingsSaveFailed => '설정을 저장할 수 없습니다';

  @override
  String get errPushPermission => '브라우저 또는 시스템 설정에서 알림을 허용해 주세요.';

  @override
  String get balanceTitle => '잔액';

  @override
  String get coinBronze => '브론즈';

  @override
  String get coinSilver => '실버';

  @override
  String get coinGold => '골드';

  @override
  String get coinDiamond => '다이아몬드';

  @override
  String get balanceZeroBronze => '브론즈 0';

  @override
  String balanceBronzes(int count) {
    return '브론즈 $count';
  }

  @override
  String balanceSilvers(int count) {
    return '실버 $count';
  }

  @override
  String balanceGolds(int count) {
    return '골드 $count';
  }

  @override
  String balanceDiamonds(int count) {
    return '다이아몬드 $count';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/일';
  }

  @override
  String get balanceAbbrBronze => '브';

  @override
  String get balanceAbbrSilver => '실';

  @override
  String get balanceAbbrGold => '골';

  @override
  String get commonBackHome => '홈으로 돌아가기';

  @override
  String get commonCopied => '복사됨';

  @override
  String get commonClear => '지우기';

  @override
  String get commonTryLater => '나중에 다시 시도하세요.';

  @override
  String get commonTryRefresh => '페이지를 새로고침해 보세요.';

  @override
  String get coinsTitle => '코인';

  @override
  String get coinsLoginReward => '로그인 보상';

  @override
  String get coinsLoginAvailableToday => '오늘의 보상 수령 가능';

  @override
  String get coinsLoginStreak => '일일 로그인 연속';

  @override
  String get coinsFriendReward => '친구 보상';

  @override
  String coinsFriendRewardHint(String amount) {
    return '내 링크로 가입 시 +$amount';
  }

  @override
  String get coinsLoadRewardsFailed => '보상을 불러오지 못했습니다';

  @override
  String get coinsClaimReward => '보상 받기';

  @override
  String get coinsAlreadyClaimed => '이미 받음';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · 오늘';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · 1일 남음';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · $remaining 남음';
  }

  @override
  String get coinsInviteFriend => '친구 초대';

  @override
  String coinsInviteHint(String amount) {
    return '내 링크로 가입하는 사람마다 +$amount';
  }

  @override
  String get coinsCopyLink => '링크 복사';

  @override
  String get coinsHowItWorks => '이용 방법';

  @override
  String get coinsHowStep1 => '링크를 복사해 친구에게 보내세요';

  @override
  String get coinsHowStep2 => '친구가 그 링크로 가입합니다';

  @override
  String coinsHowStep3(String amount) {
    return '$amount을(를) 받습니다';
  }

  @override
  String get achievementsTitle => '업적';

  @override
  String achievementsProgress(String progress) {
    return '진행도: $progress';
  }

  @override
  String get achievementsFrameClaimed => '프레임 획득';

  @override
  String get achievementsClaimed => '획득함';

  @override
  String get achievementsOpenFrame => '프레임 열기';

  @override
  String friendsRemoveConfirm(String name) {
    return '$name님을 친구에서 삭제하시겠습니까?';
  }

  @override
  String get friendsRemoveConfirmAction => '삭제';

  @override
  String get friendsRemove => '친구에서 삭제';

  @override
  String get friendsAcceptRequest => '요청 수락';

  @override
  String get friendsDeclineRequest => '요청 거절';

  @override
  String get friendsCancelRequest => '요청 취소';

  @override
  String get friendsSendRequest => '친구 요청 보내기';

  @override
  String get friendsRequestAlreadySent => '요청이 이미 전송됨';

  @override
  String get friendsIncomingStatus => '받은 요청';

  @override
  String get friendsOutgoingStatus => '보낸 요청';

  @override
  String get friendsNotFriends => '친구가 아님';

  @override
  String get friendsCollapseSearch => '검색 접기';

  @override
  String get friendsExpandSearch => '검색 표시';

  @override
  String get friendsLoadFailed => '친구를 불러오지 못했습니다';

  @override
  String friendsSince(String date) {
    return '친구 시작: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return '받은 요청: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return '보낸 요청: $date';
  }

  @override
  String get userInfoTitle => '사용자 정보';

  @override
  String profileAgeYears(int age) {
    return '$age세';
  }

  @override
  String get shopBuy => '구매';

  @override
  String get shopBuyTitle => '구매할까요?';

  @override
  String get shopBuyStakeTitle => '판돈을 구매할까요?';

  @override
  String get shopBuyEmojiTitle => '이모지를 구매할까요?';

  @override
  String get shopBuyCollectionTitle => '컬렉션을 구매할까요?';

  @override
  String shopPrice(String price) {
    return '가격: $price';
  }

  @override
  String get shopOwned => '구매함';

  @override
  String get shopEmpty => '아직 비어 있음';

  @override
  String shopPurchased(String title) {
    return '$title 구매 완료';
  }

  @override
  String get shopEmojiUses => '획득: 10회 사용';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10회 사용';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10회 사용';
  }

  @override
  String get shopBuyTen => '구매 · 10개';

  @override
  String shopDailyIncome(String amount) {
    return '수익: $amount';
  }

  @override
  String get shopBuyOnce => '일회성 구매';

  @override
  String get shopSellRefund => '판매 시 비용의 일부가 반환됩니다';

  @override
  String shopCollectionAdded(String title) {
    return '$title이(가) 프로필에 추가됨';
  }

  @override
  String shopSetBonus(int percent) {
    return '세트 보너스 +$percent%';
  }

  @override
  String get shopSetComplete => '완성';

  @override
  String shopSetProgress(int owned, int total) {
    return '수집 · $owned/$total';
  }

  @override
  String get inventorySellTitle => '판매할까요?';

  @override
  String inventorySellDesc(String amount) {
    return '$amount을(를) 받습니다';
  }

  @override
  String inventorySold(String amount) {
    return '판매됨: +$amount';
  }

  @override
  String get inventoryNeedFriends => '먼저 친구를 추가하세요';

  @override
  String get inventoryGiftTitle => '컬렉션을 선물할까요?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return '«$title»을(를) $name님에게 선물할까요?';
  }

  @override
  String inventoryGifted(String title) {
    return '선물함: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'У этого пользователя уже есть эта коллекция';

  @override
  String get inventoryGiftSelf => 'Нельзя подарить коллекцию самому себе';

  @override
  String get inventoryGiftNotOwned => 'У вас нет этого предмета';

  @override
  String get inventoryLoadFailed => '아이템을 불러오지 못했습니다';

  @override
  String get inventoryNoCollections => '컬렉션 없음 — 상점에서 구매하세요';

  @override
  String get inventoryNoEmojis => '이모지 없음 — 상점에서 구매하세요';

  @override
  String get inventoryNoFrames => '프레임 없음 — 리그에서 10승 (업적)';

  @override
  String get inventoryNoStakes => '구매한 판돈 없음';

  @override
  String inventoryEmojiLeft(int count) {
    return '$count개 남음';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return '수익: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return '내일 수익: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Доход:';

  @override
  String get inventoryIncomeTomorrowLabel => 'Доход завтра:';

  @override
  String inventoryStakeGold(String amount) {
    return '$amount 골드를 걸 수 있습니다';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return '$amount 실버를 걸 수 있습니다';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return '+$amount 수령';
  }

  @override
  String get chatsLoadFailed => '채팅을 불러오지 못했습니다';

  @override
  String get chatsLoadListFailed => '목록을 불러오지 못했습니다';

  @override
  String get chatsBlockedEmpty => '목록이 비어 있습니다';

  @override
  String chatsBlockedAt(String date) {
    return '차단됨: $date';
  }

  @override
  String get chatsCreateFailed => '채팅을 만들지 못했습니다';

  @override
  String get chatsNeedFriendsFirst => '먼저 친구를 추가한 후 채팅을 열 수 있습니다.';

  @override
  String get chatsFriendsNotFound => '친구를 찾을 수 없습니다';

  @override
  String get chatsFindFriendHint => '닉네임으로 친구 찾기';

  @override
  String get chatsSelectChat => '채팅 선택';

  @override
  String get chatsSelectHint => '왼쪽 목록에서 대화를 선택하세요';

  @override
  String get chatEditFailed => '메시지를 수정하지 못했습니다';

  @override
  String get chatSendFailed => '메시지를 보내지 못했습니다';

  @override
  String get chatDeleteFailed => '메시지를 삭제하지 못했습니다';

  @override
  String get chatEmojiSendFailed => '이모지를 보내지 못했습니다';

  @override
  String get chatLoadFailed => '메시지를 불러오지 못했습니다';

  @override
  String get chatBackToGame => '게임으로 돌아가기';

  @override
  String get chatBackToChats => '채팅으로 돌아가기';

  @override
  String get chatActions => '채팅 작업';

  @override
  String get chatScrollToEnd => '대화 끝으로';

  @override
  String chatReplyingTo(String name) {
    return '$name님에게 답장';
  }

  @override
  String get chatGift => '선물';

  @override
  String get chatCollection => '컬렉션';

  @override
  String get chatGiftCollection => '선물 · 컬렉션';

  @override
  String get chatThisUser => '이 사용자';

  @override
  String get gamesLobbyLoadFailed => '로비를 불러오지 못했습니다.';

  @override
  String get gamesTapChangeStake => '탭하여 판돈 변경';

  @override
  String get gamesTapChangeTurnTime => '탭하여 턴 시간 변경';

  @override
  String get gamesTapChangeGrid => '탭하여 격자 크기 변경';

  @override
  String get gamesSwapSidesHint => '첫 수 후 O가 X가 될 수 있음';

  @override
  String get gamesNoCenterHint => '첫 수는 중앙에 둘 수 없음';

  @override
  String get lobbyInviteSentShort => '보냄';

  @override
  String get lobbyInvitesSentWaiting => '초대가 전송되었습니다. 응답을 기다리는 중.';

  @override
  String get lobbyLinkCopiedHint => '채팅이나 친구에게 보내는 메시지에 붙여넣으세요';

  @override
  String get lobbyCopyLinkHint => '링크를 클립보드에 복사';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name님이 게임에 초대합니다';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name 승리';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return '시간 종료. $name 승리';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds초';
  }

  @override
  String get adminTitle => '관리자';

  @override
  String get tournamentsTitle => '토너먼트';

  @override
  String get profileAgeInvalid => '나이는 1에서 111 사이로 입력하세요';

  @override
  String get profileSaveFailed => '프로필을 저장하지 못했습니다';

  @override
  String get profileNameHint => '라틴 문자, 숫자, _ 최대 10자';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => '1에서 111';

  @override
  String get profileAboutHint => '최대 100자 (선택)';

  @override
  String get profileProcessingPhoto => '사진 처리 중…';

  @override
  String get profileCropTitle => '아바타 영역 선택';

  @override
  String get profileCropHint => '사진을 확대하고 이동하세요';

  @override
  String get profileApply => '적용';

  @override
  String get profilePreparing => '준비 중…';

  @override
  String timeSecondsShort(int seconds) {
    return '$seconds초';
  }

  @override
  String get timeOneMin => '1분';

  @override
  String get timeTenMin => '10분';

  @override
  String rulesIntro(String grid) {
    return '$grid 판에서 틱택토. 번갈아 두며 X가 선공.';
  }

  @override
  String rulesWin(int n) {
    return '승리: 가로, 세로 또는 대각선으로 $n개를 잇습니다.';
  }

  @override
  String get rulesNoTimeLimit => '수당 시간 제한 없음.';

  @override
  String rulesTurnTime(String time) {
    return '수당 시간: $time.';
  }

  @override
  String rulesStake(String stake) {
    return '판돈: $stake. 이만큼의 코인으로 진행됩니다.';
  }

  @override
  String get rulesSwap => '진영 교체: X의 첫 수 이후 O가 X와 자리를 바꿀 수 있습니다.';

  @override
  String get rulesNoCenter => '중앙 금지: X는 첫 수에 중앙에 둘 수 없습니다.';

  @override
  String get collectionSetLegends => '전설';

  @override
  String get collectionSetSpace => '우주';

  @override
  String get collectionSetGems => '보석';

  @override
  String get collectionSetParty => '파티';

  @override
  String get collectionSetNature => '자연';

  @override
  String get collectionSetAdventures => '모험';

  @override
  String collectionCardMeta(String amount) {
    return '컬렉션 · 진열 · 선물 · 판매 · +$amount';
  }

  @override
  String get coinsDayOne => '일';

  @override
  String get coinsDayFew => '일';

  @override
  String get coinsDayMany => '일';

  @override
  String get giftFriendTitle => '친구에게 선물';

  @override
  String photoCount(int count) {
    return '사진 ($count)';
  }

  @override
  String photoCountWithText(int count, String text) {
    return '사진 ($count): $text';
  }

  @override
  String photoWithText(String text) {
    return '사진: $text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '이모지 $count개 · $price';
  }

  @override
  String get chatsExpandPanel => '패널 펼치기';

  @override
  String get chatsCollapsePanel => '패널 접기';

  @override
  String get chatReplySourceMissing => '원본 메시지를 찾을 수 없습니다';

  @override
  String shopStakeTitleSilver(int n) {
    return '판돈 $n 실버';
  }

  @override
  String shopStakeTitleGold(int n) {
    return '판돈 $n 골드';
  }

  @override
  String shopStakeDescSilver(int n) {
    return '$n 실버 판돈 잠금 해제';
  }

  @override
  String shopStakeDescGold(int n) {
    return '$n 골드 판돈 잠금 해제';
  }

  @override
  String get chatReplySelf => '자신';

  @override
  String get chatReplyPeer => '상대방';

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
