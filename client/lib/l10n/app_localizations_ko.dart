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
  String timeMinutesAgo(Object count) {
    return '$count분 전';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count시간 전';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count일 전';
  }

  @override
  String get timeWeekAgo => '일주일 전';

  @override
  String timeWeeksAgo(Object count) {
    return '$count주 전';
  }

  @override
  String get timeMonthAgo => '한 달 전';

  @override
  String timeMonthsAgo(Object count) {
    return '$count개월 전';
  }

  @override
  String get timeYearAgo => '1년 전';

  @override
  String timeYearsAgo(Object count) {
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
}
