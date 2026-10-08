import 'package:intl/intl.dart' as intl;

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
  String get settingsSoundTitle => '소리';

  @override
  String get settingsSoundSubtitle => '게임과 알림';

  @override
  String get settingsSoundGames => '게임';

  @override
  String get settingsSoundNotifications => '알림';

  @override
  String get settingsSoundTurn => '차례';

  @override
  String get settingsHapticsTitle => '진동';

  @override
  String get settingsHapticsSubtitle => '알림만: 메시지, 요청, 내 차례, 타이머';

  @override
  String get settingsGamepadTitle => '컨트롤러';

  @override
  String get settingsGamepadSubtitle => '메뉴와 대국용 게임패드';

  @override
  String settingsGamepadConnected(String name) {
    return '연결됨: $name';
  }

  @override
  String get settingsGamepadDisconnected => '게임패드가 없습니다. 컨트롤러를 연결하고 아무 버튼이나 누르세요.';

  @override
  String get settingsGamepadGenericName => '컨트롤러';

  @override
  String get settingsGamepadHelpNavigate => '이동';

  @override
  String get settingsGamepadHelpConfirm => '선택';

  @override
  String get settingsGamepadHelpBack => '뒤로';

  @override
  String get settingsGamepadHelpTabs => '탭';

  @override
  String get settingsGamepadHelpPlay => '보드와 손패 커서: 체커, 틱택토, 배틀십, 두락, 우노, 포커, 주사위 놀이';

  @override
  String get settingsGamepadHelpCards => '카드';

  @override
  String get settingsGamepadHelpKeyboard => '키보드';

  @override
  String get settingsGamepadHelpBalance => '잔액';

  @override
  String get settingsGamepadHelpLogout => '로그아웃';

  @override
  String get settingsGamepadHelpPage => '페이지';

  @override
  String get settingsGamepadLayoutXbox => 'Xbox 배치';

  @override
  String get settingsGamepadLayoutPlayStation => 'PlayStation 배치';

  @override
  String get settingsGamepadLayoutNintendo => 'Nintendo 배치';

  @override
  String get gamepadKeyboardTitle => '키보드';

  @override
  String get gamepadKeyboardSpace => '스페이스';

  @override
  String get gamepadLegendConfirm => '선택';

  @override
  String get gamepadLegendBack => '뒤로';

  @override
  String get gamepadLegendTabs => '탭';

  @override
  String get gamepadLegendCycle => '변경';

  @override
  String gamepadConnectedSnack(String name) {
    return '컨트롤러 연결됨: $name';
  }

  @override
  String get settingsOfflineModeTitle => '네트워크 모드';

  @override
  String get settingsOfflineModeSubtitle => '오프라인: 즉시 봇과 플레이, 배팅·보상 없음, 채팅·친구 없음. 구매는 저장되며 온라인 모드에서 적용됩니다. 온라인 — 인터넷이 있거나 사용자 설정에 따라.';

  @override
  String get settingsModeOnline => '온라인';

  @override
  String get settingsModeOffline => '오프라인';

  @override
  String get gamesAlternateStartsHint => '번갈아 누가 대국을 시작하는지';

  @override
  String get rulesAlternateStarts => '선공은 대국마다 번갈아 바뀝니다.';

  @override
  String get offlineBadgeTooltip => '오프라인 모드';

  @override
  String get offlineModePopupTitle => '오프라인 모드';

  @override
  String get offlineModePopupBody => '오프라인 모드가 켜져 있습니다. 배팅과 보상 없이 봇과 플레이하세요. 채팅, 친구, 로비는 숨겨집니다. 구매는 온라인 모드에서 적용됩니다.';

  @override
  String get offlineModePopupSettings => '설정';

  @override
  String get offlineModeOfferBody => '인터넷이 없거나 연결이 매우 느립니다. 오프라인 모드를 켜고 봇과 플레이할 수 있습니다.';

  @override
  String get offlineModeOfferAction => '오프라인 켜기';

  @override
  String get gamesPlay => '플레이';

  @override
  String get offlineGameTitle => '봇과 대국';

  @override
  String get offlineGameHint => '배팅·보상 없음 · 오프라인 전용';

  @override
  String get offlineBotWon => '봇 승리';

  @override
  String get offlineBotThinking => '봇이 생각 중…';

  @override
  String get offlinePlayAgain => '다시';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => '가져가기';

  @override
  String get durakActionAll => '전체';

  @override
  String get durakActionDone => '완료';

  @override
  String get durakActionBito => 'Beat';

  @override
  String get durakHintDefend => '방어하세요';

  @override
  String get durakHintDefendOrTransfer => '방어하거나 넘기세요';

  @override
  String get durakHintOpponentDefends => '상대가 방어합니다';

  @override
  String get durakHintThrowInFirst => '카드를 추가하세요 (첫 방어 최대 5장)';

  @override
  String get durakHintThrowIn => '카드를 추가하거나 방어를 기다리세요';

  @override
  String get durakHintOpponentThrows => '상대가 추가합니다';

  @override
  String get durakHintTakeFollow => '가져간 후 추가하거나 «완료»를 누르세요';

  @override
  String get durakHintOpponentTakeFollow => '상대는 가져간 후 추가할 수 있습니다';

  @override
  String get durakHintBito => '카드를 내거나 «비토»라고 하세요';

  @override
  String get durakHintOpponentBito => '상대가 추가하거나 «비토»라고 합니다';

  @override
  String get durakHintYourAttack => '당신 차례 — 공격하세요';

  @override
  String get durakHintOpponentAttack => '상대가 공격합니다';

  @override
  String get durakHintYouLost => '패배했습니다 — 당신이 바보입니다';

  @override
  String get durakHintDrawAllOut => '무승부 — 모두 탈락';

  @override
  String get durakHintYouFinished => '탈락했습니다 — 종료를 기다립니다';

  @override
  String get durakFirstLeadYou => '당신이 먼저입니다';

  @override
  String get durakFirstLeadOpponent => '상대가 먼저입니다';

  @override
  String get durakFirstLeadBot => '봇이 먼저입니다';

  @override
  String durakFirstLeadOf(String name) {
    return '$name이(가) 먼저입니다';
  }

  @override
  String get durakFirstLeadReason => '가장 낮은 트럼프';

  @override
  String get shopPurchaseQueued => '구매가 저장됨 — 온라인 모드에서 적용됩니다';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — 구매 적용됨';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — 구매 미적용: $reason';
  }

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
  String settingsAppVersion(String version) {
    return '버전 $version';
  }

  @override
  String get appUpdateTitle => '업데이트 가능';

  @override
  String get appUpdateBody => '앱의 새 버전을 사용할 수 있습니다. 계속하려면 업데이트하세요.';

  @override
  String get appUpdateWhatsNew => '새로운 기능';

  @override
  String get appUpdateOk => '업데이트';

  @override
  String get appUpdateLaterBanner => '이 게임 후 앱을 업데이트합니다';

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
  String get apiErrWrongGameType => '잘못된 게임 유형입니다';

  @override
  String get apiErrWrongGameTypeOrState => '잘못된 게임 유형 또는 상태입니다';

  @override
  String get apiErrLobbyFull => '로비가 가득 찼습니다';

  @override
  String get apiErrBadState => '잘못된 게임 상태입니다';

  @override
  String get apiErrIllegalMove => '둘 수 없는 수입니다';

  @override
  String get apiErrUnknownMoveType => '알 수 없는 수 유형입니다';

  @override
  String get apiErrNoOpponents => '상대가 없습니다';

  @override
  String get apiErrNoOpponentsRematch => '재대결할 상대가 없습니다';

  @override
  String get apiErrAlreadyInLobby => '이미 이 로비에 있습니다';

  @override
  String get apiErrGameNotActive => '게임이 활성 상태가 아닙니다';

  @override
  String get apiErrNotInBattle => '전투 단계가 아닙니다';

  @override
  String get apiErrNotInSetup => '배치 단계가 아닙니다';

  @override
  String get apiErrAlreadyReady => '이미 준비되었습니다';

  @override
  String get apiErrAlreadyForfeited => '이미 기권했습니다';

  @override
  String get apiErrYouHaveForfeited => '기권했습니다';

  @override
  String get apiErrNoDrawOffer => '무승부 제안이 없습니다';

  @override
  String get apiErrDrawOnlyPvp => '무승부는 플레이어전에서만 가능합니다';

  @override
  String get apiErrDrawOnly1v1 => '무승부는 1대1에서만 가능합니다';

  @override
  String get apiErrDrawVsBot => '봇과는 무승부를 할 수 없습니다';

  @override
  String get apiErrDrawMultiplayer => '멀티플레이에서는 무승부를 할 수 없습니다';

  @override
  String get apiErrDeck24TwoPlayers => '24장 덱은 2인용만 가능합니다';

  @override
  String get apiErrDeck52ThreeOrFour => '52장 덱은 3명 또는 4명만 가능합니다';

  @override
  String get apiErrAccountFrozen => '계정이 동결되었습니다';

  @override
  String get apiErrTurnTimeInvalid => '턴 시간은 0, 20, 60 또는 600초여야 합니다';

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
  String get gamesDurak => '두라크';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => '회전';

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
  String get gamesPoker => '포커';

  @override
  String get gamesUno => '우노';

  @override
  String get gamesNardy => '백개먼';

  @override
  String get gamesNardyModeShort => '숏';

  @override
  String get gamesNardyModeLong => '롱';

  @override
  String get gamesCheckers => '체커';

  @override
  String get gamesCheckersModeRussian => '러시아';

  @override
  String get gamesCheckersModeEnglish => '영국식';

  @override
  String get gamesCheckersModeGiveaway => '기브어웨이';

  @override
  String get gamesCheckersModeCorners => '코너';

  @override
  String get gamesChess => '체스';

  @override
  String get gamesChessModeClassic => '클래식';

  @override
  String get gamesChessModeRapid => '래피드';

  @override
  String get gamesChessModeBlitz => '블리츠';

  @override
  String get gamesChessModeBullet => '불릿';

  @override
  String get chessPieceQueen => '퀸';

  @override
  String get chessPieceRook => '룩';

  @override
  String get chessPieceBishop => '비숍';

  @override
  String get chessPieceKnight => '나이트';

  @override
  String get chessPromotionTitle => '폰 승격';

  @override
  String get chessDrawStalemate => '무승부: 스테일메이트';

  @override
  String get chessDrawInsufficient => '무승부: 기물 부족';

  @override
  String get chessDrawRepetition => '무승부: 3회 동형 반복';

  @override
  String get chessDrawFiftyMove => '무승부: 50수 규칙';

  @override
  String get chessCheck => '체크';

  @override
  String get rulesCheckersPlayers => '플레이어: 2.';

  @override
  String rulesCheckersMode(String mode) {
    return '모드: $mode.';
  }

  @override
  String rulesCheckersTime(String time) {
    return 'Время на ход: $time. Если время вышло — проигрыш.';
  }

  @override
  String get rulesCheckersIntro => '보드 8×8. 2인 대전.';

  @override
  String get rulesCheckersPlay => '잡기는 필수입니다. 킹과 졸은 착지한 칸에서 더 잡을 수 있으면 반드시 이어가야 하며 중간에 멈출 수 없습니다. 방향이 여러 개면 아무거나 골라도 되고 가장 긴 경로일 필요는 없습니다. 마지막 줄에 오른 졸은 킹이 됩니다.';

  @override
  String get rulesCheckersWin => 'В русских шашках побеждает тот, кто съел все шашки соперника или лишил его хода. В поддавках наоборот: кто не может ходить — выигрывает.';

  @override
  String get rulesCheckersOfflineBot => 'Офлайн: партия против бота.';

  @override
  String get rulesCheckersPlayRussian => '러시아 체커: 각자 어두운 칸에 12개. 졸은 대각선 앞으로 움직이고 앞뒤로 잡습니다. 킹은 원하는 칸만큼 날아갑니다. 잡기는 필수입니다. 더 잡을 수 있으면 멈춰서는 안 되지만, 방향이 여러 개면 아무거나 골라도 되고 가장 긴 경로일 필요는 없습니다. 상대 말을 모두 잡거나 상대가 둘 곳이 없으면 승리합니다.';

  @override
  String get rulesCheckersPlayEnglish => '영국식 체커: 각자 12개. 졸은 대각선 앞으로만 움직이고 잡습니다. 킹은 대각선 한 칸입니다. 잡기는 필수입니다. 상대 말을 모두 잡거나 상대가 둘 곳이 없으면 승리합니다.';

  @override
  String get rulesCheckersPlayGiveaway => '기브어웨이: 수는 러시아 체커와 같지만 목표는 반대입니다. 자기 말을 모두 잃거나 둘 곳이 없으면 이깁니다. 잡기는 여전히 필수입니다.';

  @override
  String get rulesCheckersPlayCorners => '코너: 말은 맞은편 모서리에서 시작합니다. 가로 또는 세로로 빈 칸으로 가거나, 어떤 말이든 넘기만 하고 잡지는 않습니다. 목표는 자기 말을 모두 상대 모서리로 옮기는 것입니다.';

  @override
  String get rulesCheckersPlayCornersNoReturn => '시작 모서리를 떠난 말은 그곳으로 돌아갈 수 없습니다.';

  @override
  String get rulesCheckersPlayCornersLeaveHome => '아직 집에 있는 말은 해당 플레이어의 처음 25수 안에 집을 떠나야 합니다.';

  @override
  String get rulesCheckersDrawRussian => '같은 국면이 세 번이거나, 양쪽 15수가 킹만 움직이고 잡기가 없으면(2대2 포함) 무승부.';

  @override
  String get rulesCheckersDrawEnglish => '같은 국면 3회, 40수 동안 잡기나 졸 이동이 없거나 킹 1대1이면 무승부.';

  @override
  String get rulesCheckersDrawGiveaway => '같은 국면 3회 또는 양쪽 15수가 킹만이고 잡기가 없으면 무승부.';

  @override
  String get rulesCheckersDrawCorners => '같은 국면 3회이거나 양쪽 25수 동안 목표 구석에 말이 늘지 않으면 무승부.';

  @override
  String get rulesChessPlayers => '플레이어: 2.';

  @override
  String rulesChessMode(String mode) {
    return '모드: $mode.';
  }

  @override
  String get rulesChessPlayClassic => '보드 8×8. 각 진영에 킹, 퀸, 룩 2, 비숍 2, 나이트 2, 폰 8. 백이 선공. 일반 수, 앙파상, 승진, 캐슬링. 체크메이트나 기권으로 승리.';

  @override
  String get rulesChessDrawClassic => '무승부: 스테일메이트, 3회 반복, 50수, 부족한 전력 또는 합의.';

  @override
  String get rulesChessClockClassic => '대국 시계: 60+0 — 대국 전체 60분, 추가 시간 없음.';

  @override
  String get rulesChessClockRapid => '대국 시계: 10+0 — 대국 전체 10분, 추가 시간 없음.';

  @override
  String get rulesChessClockBlitz => '대국 시계: 5+0 — 대국 전체 5분, 추가 시간 없음.';

  @override
  String get rulesChessClockBullet => '대국 시계: 3+2 — 3분에 수마다 2초 추가.';

  @override
  String get checkersDrawRepetition => '무승부 — 같은 국면이 세 번';

  @override
  String get checkersDrawNoProgress => '무승부 — 승리로 이어지지 않는 수';

  @override
  String get checkersDrawInsufficient => '무승부 — 이길 전력이 부족함';

  @override
  String get rulesNardyTitle => '백개먼 — 규칙';

  @override
  String get rulesNardyPlayers => '플레이어: 2명.';

  @override
  String rulesNardyMode(String mode) {
    return '모드: $mode.';
  }

  @override
  String get rulesNardyIntro => '24포인트 보드, 각자 15개 말. 주사위 2개: 한 말로 합 또는 두 말로 각 눈.';

  @override
  String get rulesNardyPlayShort => '숏 백개먼: 서로를 향해 가고 홀로 있는 말을 칠 수 있습니다. 맞은 말은 바로 가서 다시 들어와야 합니다. 모두 홈에 있으면 보드에서 뺍니다.';

  @override
  String get rulesNardyPlayLong => '롱 백개먼: 둘 다 같은 헤드에서 같은 방향으로 갑니다. 헤드에서는 한 턴에 말 하나만 나옵니다. 치기는 불가. 모두 홈에 있으면 뺍니다.';

  @override
  String get rulesNardyWin => '모든 말을 먼저 뺀 사람이 이깁니다.';

  @override
  String get rulesNardySixPrime => '상대 말이 하나도 지나가지 않은 상태에서는 여섯 칸을 연속으로 막을 수 없습니다.';

  @override
  String get nardyRoll => '주사위 굴리기';

  @override
  String get nardySkipTurn => '차례 넘기기';

  @override
  String get nardyUndoMove => '되돌리기';

  @override
  String get nardyDoneTurn => '완료';

  @override
  String get nardyAutoConfirm => '자동 확인';

  @override
  String get nardyAutoConfirmHint => '모든 수를 두면 차례가 자동으로 넘어갑니다';

  @override
  String get nardyLayoutToggle => '배치 바꾸기';

  @override
  String get nardyNoMoves => '둘 수 없음';

  @override
  String get nardyYourRoll => '당신의 주사위';

  @override
  String get nardyPipsShort => '남음:';

  @override
  String get nardyYouWonMars => '승리 — 개먼!';

  @override
  String get nardyYouLostMars => '패배 — 개먼';

  @override
  String get rulesNardyOfflineBot => '오프라인: 봇과의 대국.';

  @override
  String rulesUnoPlayers(int players) {
    return '플레이어: $players명.';
  }

  @override
  String get rulesUnoOfflineBot => '봇과 대결, 턴 시간 제한 없음.';

  @override
  String get rulesUnoIntro => '각 플레이어에게 카드 7장을 나눠 줍니다. 같은 색 또는 같은 등급(숫자나 같은 특수) 카드를 냅니다.';

  @override
  String get rulesUnoPlay => '스킵 — 다음 사람은 턴을 잃습니다. 2인일 때 리버스는 스킵과 같습니다. +2는 +2 위에만, +4는 +4 위에만 겹칩니다. 벌칙이 더해집니다(+2 두 장이면 다음 사람은 4장). +2를 +4 위에 올릴 수 없습니다. 겹치지 않으면 더미 전체를 뽑고 턴을 건너뜁니다.같은 색깔·숫자의 일반 카드 두 장(예: 노란 8 두 장)은 함께 버립니다. 한 장만 내면 짝이 자동으로 나갑니다.';

  @override
  String get rulesUnoWild => '검은 카드는 새 색을 정합니다. +4는 현재 색 카드가 없을 때만 냅니다. 상대가 도전할 수 있습니다. +4가 합법이면 도전자가 6장, 아니면 +4를 낸 사람이 4장을 뽑고 도전자가 냅니다.';

  @override
  String get rulesUnoDraw => '낼 카드가 없으면 덱에서 한 장 뽑습니다. 맞으면 바로 내거나 들고 턴을 넘길 수 있습니다. 낼 수 있는 카드가 있으면 뽑을 수 없습니다.';

  @override
  String get rulesUnoWin => '1대1은 100점, 3인 이상은 200점. 라운드는 손을 비운 사람이 이깁니다.';

  @override
  String get rulesUnoCall => '한 장 남으면 바로 «우노!»를 누르세요. 상대는 1초 후에만 우노를 잊었다고 잡을 수 있고, 그때 2장을 뽑습니다.';

  @override
  String get rulesUnoScoring => '먼저 손을 비운 사람이 라운드를 이기고 상대 손패 점수를 받습니다. 숫자는 액면, 특수 20, 검정 50. 1대1은 100점, 3인 이상은 200점.';

  @override
  String get unoColorRed => '빨강';

  @override
  String get unoColorYellow => '노랑';

  @override
  String get unoColorGreen => '초록';

  @override
  String get unoColorBlue => '파랑';

  @override
  String get unoDraw => '뽑기';

  @override
  String get unoKeep => '보관';

  @override
  String get unoSayUno => '우노!';

  @override
  String get unoChallengeUno => '우노 도전';

  @override
  String get unoChallengeWd4 => '+4 도전';

  @override
  String get unoChooseColor => '색상 선택';

  @override
  String get unoDrawPile => '뽑기 더미';

  @override
  String get unoDiscardPile => '버린 더미';

  @override
  String unoCardsCount(int count) {
    return '카드: $count';
  }

  @override
  String unoScore(int score) {
    return '점수: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return '$round라운드 · $target점 선취';
  }

  @override
  String get unoYourTurn => '내 차례';

  @override
  String get unoWaitingTurn => '상대 차례';

  @override
  String get unoChooseColorHint => '와일드 카드의 색상을 선택하세요';

  @override
  String get unoWd4Hint => '4장을 뽑거나 와일드 +4에 도전하세요';

  @override
  String get unoDrawnHint => '뽑은 카드를 내거나 보관하세요';

  @override
  String get unoPlayHint => '같은 색상이나 값을 내세요';

  @override
  String get unoDrawHint => '낼 카드가 없습니다 — 더미에서 뽑으세요';

  @override
  String unoPendingDraw(int count) {
    return '+$count장';
  }

  @override
  String get unoYouWon => '매치에서 승리했습니다!';

  @override
  String get unoYouLost => '매치 종료';

  @override
  String get unoYouLostTimeout => '시간 초과로 패배했습니다';

  @override
  String unoWinner(String name) {
    return '승자: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name 님이 라운드 승리';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => '다음';

  @override
  String get unoRoundScoresTitle => '라운드 점수';

  @override
  String get unoDirectionClockwise => '시계 방향';

  @override
  String get unoDirectionCounterclockwise => '반시계 방향';

  @override
  String get unoErrStackSameOnly => '+2 위에는 +2만, +4 위에는 +4만 낼 수 있습니다. +2를 +4 위에 올릴 수 없습니다.';

  @override
  String get unoErrCatchTooEarly => '잠시만요. 아직 우노를 외칠 수 있습니다.';

  @override
  String get unoErrCallTooLate => '이제 우노를 외칠 수 없습니다. 다음 플레이어가 이미 냈습니다.';

  @override
  String get gamesInDevelopment => '개발 중';

  @override
  String rulesPokerPlayers(int players) {
    return '인원: $players.';
  }

  @override
  String get rulesPokerIntro => '텍사스 홀덤. 각 플레이어는 홀 카드 2장, 테이블에 커뮤니티 카드 5장이 나옵니다.';

  @override
  String get rulesPokerPlay => '베팅 라운드: 프리플롭, 플롭, 턴, 리버. 폴드, 콜, 벳, 레이즈를 할 수 있습니다.';

  @override
  String get rulesPokerWin => '홀+커뮤니티로 만든 최강 5장 핸드, 또는 폴드 후 남은 한 명이 승리합니다.';

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
  String get gamesObservation => '관전';

  @override
  String get gamesObservationHint => '게임 종료까지 관전할 수 있습니다';

  @override
  String get gamesFinishCurrentFirst => '먼저 현재 게임을 마치세요';

  @override
  String get gamesVariantClassic => '클래식';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3인';

  @override
  String get gamesVariantMulti4 => '4인';

  @override
  String get gamesDurakModePodkidnoi => '추가';

  @override
  String get gamesDurakModePerevodnoi => '전달';

  @override
  String get gamesDurakDeck24 => '24장';

  @override
  String get gamesDurakDeck36 => '36장';

  @override
  String get gamesDurakDeck52 => '52장';

  @override
  String rulesDurakMode(String mode) {
    return '모드: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return '인원: $players. 덱: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => '봇과 플레이합니다. 판돈과 시간 제한이 없습니다.';

  @override
  String get rulesDurakAttack => '공격자가 카드를 내고, 수비자가 막습니다(같은 무늬의 더 높은 카드 또는 트럼프). 트럼프는 더 높은 트럼프로만 막습니다.';

  @override
  String get rulesDurakBeat => '모든 카드가 막히면 공격자가 «비토»를 말하고 카드는 버림 더미로 갑니다. 아니면 수비자가 테이블의 카드를 모두 가져갑니다.';

  @override
  String get rulesDurakLoser => '마지막에 카드가 남은 사람이 패배 — «바보»입니다.';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return '플레이어 $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return '로비 $name';
  }

  @override
  String get lobbyMatchmake => '로비';

  @override
  String get lobbyPrivateGame => '비공개 게임';

  @override
  String get lobbySearchingOpponent => '상대를 찾는 중…';

  @override
  String lobbyPlayersSearching(int count) {
    return '이 게임 찾는 중: $count';
  }

  @override
  String get lobbyWaitingJoin => '누군가 「게임 찾기」 또는 「참가」를 누를 때까지 대기 중';

  @override
  String get lobbyInviteTitle => '게임 초대';

  @override
  String get lobbyInvitedToPlay => '게임에 초대되었습니다';

  @override
  String get lobbyEnterGame => '게임 입장';

  @override
  String get lobbyGone => '로비를 더 이상 사용할 수 없습니다';

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
  String get gameYou => '나';

  @override
  String get gameYouWon => '이겼습니다!';

  @override
  String get gameYouLost => '패배했습니다';

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
  String get gameSurrender => '기권';

  @override
  String get gameSurrenderTitle => '기권하시겠습니까?';

  @override
  String get gameSurrenderConfirm => '대국과 배팅 코인을 잃습니다.';

  @override
  String get gameOfferDraw => '무승부 제안';

  @override
  String get gameFlipBoard => '보드 뒤집기';

  @override
  String get gameReviewStart => '게임 시작으로';

  @override
  String get gameReviewPrev => '한 수 뒤로';

  @override
  String get gameReviewNext => '한 수 앞으로';

  @override
  String get gameReviewEnd => '현재 위치로';

  @override
  String get gameOfferDrawTitle => '무승부를 제안하시겠습니까?';

  @override
  String get gameOfferDrawConfirm => '상대가 무승부를 수락하거나 거절할 수 있습니다.';

  @override
  String get gameAcceptDrawTitle => '무승부를 수락하시겠습니까?';

  @override
  String get gameAcceptDrawConfirm => '대국이 무승부로 끝납니다.';

  @override
  String get gameDrawOffered => '상대가 무승부를 제안했습니다';

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
  String get chatPaste => '붙여넣기';

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
  String get friendsSearchNoMatches => '검색과 일치하는 친구가 없습니다';

  @override
  String get friendsIncomingSearchNoMatches => '검색과 일치하는 받은 요청이 없습니다';

  @override
  String get friendsOutgoingSearchNoMatches => '검색과 일치하는 보낸 요청이 없습니다';

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
  String get profileChangePhoto => '아바타 변경';

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
  String get shopStakesSubtitle => '더 높은 배팅 잠금 해제';

  @override
  String get shopEmojisHelp => '채팅용 애니메이션 이모지. 세트를 사서 친구에게 보내세요.';

  @override
  String get shopCollectionsHelp => '새것이나 빈티지 컬렉션만 팔 수 있습니다. 새것은 가격의 80%, 빈티지는 가격의 300%입니다. 해진 것, 지친 것, 낡은 것은 팔 수 없습니다.\n\n아이템 세트를 모으세요. 프로필 진열장에 나타나며 선물할 수 있습니다. 각 아이템은 매일 코인을 주고, 세트를 완성하면 별도의 보너스도 받습니다.\n\n아이템의 일일 수입은 상태에 따라 달라지며 평소 금액의 비율입니다. 새것은 100%입니다. 해진 것은 60%입니다. 지친 것은 40%입니다. 낡은 것은 100%입니다. 빈티지 아이템은 200%로, 평소 일일 수입의 두 배입니다.\n\n완성 세트 보너스는 세트 자체가 빈티지가 될 때까지 그대로입니다. 세트의 모든 아이템이 빈티지일 때 그 세트는 빈티지이며, 보너스는 300%, 평소의 세 배가 됩니다.\n\n상태는 아이템을 가진 기간에 따라 달라집니다. 새것 — 처음 7일. 해진 것 — 8일째부터 2개월. 지친 것 — 2개월부터 6개월. 낡은 것 — 6개월부터 1년. 빈티지 — 1년부터.';

  @override
  String get shopStakesHelp => '더 높은 판돈을 잠금 해제하세요. 판돈이 클수록 팟과 배당이 커집니다.';

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
  String get coinsTasks => '과제';

  @override
  String get coinsTasksSubtitle => '프로필, 친구, 게임 보상';

  @override
  String get coinsTasksRewards => '받을 수 있는 보상이 있습니다';

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
  String get shopHave => '보유';

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
  String get shopSellRefund => '판매는 컬렉션 상태에 따라 달라집니다';

  @override
  String get collectionConditionNew => '새것';

  @override
  String get collectionConditionWorn => '해진 것';

  @override
  String get collectionConditionTired => '지친 것';

  @override
  String get collectionConditionShabby => '낡은 것';

  @override
  String get collectionConditionVintage => '빈티지';

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
  String get inventoryCollectionNotSellable => '새것이나 빈티지 컬렉션만 팔 수 있습니다.';

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
  String get inventoryGiftAlreadyOwns => '상대가 이미 이 아이템을 보유하고 있습니다';

  @override
  String get inventoryGiftSelf => '자기 자신에게는 선물할 수 없습니다';

  @override
  String get inventoryGiftNotOwned => '이 아이템은 인벤토리에 없습니다';

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
  String get inventoryIncomeReadyLabel => '수령 가능';

  @override
  String get inventoryIncomeTomorrowLabel => '내일';

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
  String get chatAutoTranslate => '자동 번역';

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
  String get lobbySearchShort => '검색';

  @override
  String get lobbySearchPlayers => '플레이어 찾기';

  @override
  String get lobbyInviteDeclinedShort => '거절함';

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
  String get profileGalleryTitle => '사진';

  @override
  String get profileGalleryAdd => '사진 추가';

  @override
  String get profileMakePrimary => '대표 사진으로';

  @override
  String get profilePhotoDelete => '사진 삭제';

  @override
  String get profilePhotosLimit => '사진은 최대 3장까지 올릴 수 있습니다';

  @override
  String get profilePhotosEmpty => '아직 사진이 없습니다';

  @override
  String get profilePhotoUploadFailed => '사진을 올리지 못했습니다';

  @override
  String get profilePhotoDeleteFailed => '사진을 삭제하지 못했습니다';

  @override
  String get profilePhotoTooLarge => '사진이 너무 큽니다';

  @override
  String get profileSetPrimaryFailed => '대표 사진으로 설정하지 못했습니다';

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
    return '수당 시간: $time. 시간 초과는 패배입니다.';
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

  @override
  String get statsTitle => '통계';

  @override
  String get statsLoadFailed => '통계를 불러오지 못했습니다';

  @override
  String get statsAllGames => '모든 게임';

  @override
  String get statsEmptyTitle => '아직 플레이한 경기가 없습니다';

  @override
  String get statsEmptyHint => '여기에 통계를 보려면 첫 게임을 플레이하세요.';

  @override
  String get statsWins => '승리';

  @override
  String get statsDraws => '무승부';

  @override
  String get statsLosses => '패배';

  @override
  String get statsWinRate => '승률';

  @override
  String get statsTopWon => '가장 많이 이긴 상대';

  @override
  String get statsTopDrawn => '가장 많이 비긴 상대';

  @override
  String get statsTopLost => '가장 많이 진 상대';

  @override
  String get statsTimePlayed => '플레이 시간';

  @override
  String get statsYourScore => '상대 전적';

  @override
  String get profileShowStats => '통계 표시';

  @override
  String get statsDurationZeroMinutes => '0분';

  @override
  String get gameYouWonOpponentForfeit => '상대가 기권했습니다. 당신이 이겼습니다!';

  @override
  String get lobbyLeaveTitle => '로비를 나가시겠습니까?';

  @override
  String get lobbyLeaveConfirm => '나가면 로비가 삭제됩니다. 초대된 친구는 거절 알림을 받습니다.';

  @override
  String get lobbyLeave => '나가기';

  @override
  String statsDurationHours(int hours) {
    return '$hours시간';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return '기권했습니다. $name 님이 이겼습니다';
  }

  @override
  String get supportTitle => '고객지원';

  @override
  String get supportUnavailable => '고객지원을 사용할 수 없습니다';

  @override
  String get supportOpenFailed => '고객지원 채팅을 열 수 없습니다';

  @override
  String coinsGrantedTitle(int amount) {
    return '$amount코인이 지급되었습니다';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return '$amount코인이 차감되었습니다';
  }

  @override
  String get coinsCreditCardTitle => '코인이 지급되었습니다';

  @override
  String get coinsClaim => '받기';

  @override
  String get durakActionPass => '패스';

  @override
  String get durakRoleTook => '가져감';

  @override
  String get durakRoleBeats => '막는 중';

  @override
  String get durakRoleThrowIn => '추가';

  @override
  String get durakRoleTurn => '차례';

  @override
  String get durakRoleDefends => '방어 중';

  @override
  String get durakStatusTaking => '가져가는 중';

  @override
  String get durakHintDefenderTurn => '수비 차례';

  @override
  String get gameYouEliminated => '탈락했습니다';

  @override
  String gameYouPlaced(int place) {
    return '$place위를 했습니다';
  }

  @override
  String get gameOverNeutral => '게임 종료';

  @override
  String gameTurnOf(String name) {
    return '$name 차례';
  }

  @override
  String get chatGroupTooltip => '그룹 채팅';

  @override
  String get lobbyChatNotReady => '로비 채팅이 아직 없습니다';

  @override
  String get chatsGroupChat => '그룹 채팅';

  @override
  String chatsMembersCount(int count) {
    return '멤버: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count명';
  }

  @override
  String get chatsYouSuffix => '(나)';

  @override
  String get chatTitleDurak3 => '두라크 · 3인';

  @override
  String get chatTitleDurak4 => '두라크 · 4인';

  @override
  String get rulesTttUltimate => '얼티밋: 3×3 미니보드 9개. 수가 상대를 해당 미니보드로 보냅니다. 메타보드에서 줄을 완성하면 승리합니다.';

  @override
  String get rulesTttMulti3 => '3인: 3×3 보드, 세 명(X, O, △). 자신의 기호로 줄을 완성하면 승리합니다.';

  @override
  String get rulesTttMulti4 => '4인: 4×4 보드, 네 명(X, O, △, □). 자신의 기호로 줄을 완성하면 승리합니다.';

  @override
  String get adminUsersTab => '사용자';

  @override
  String get adminSupportTab => '지원';

  @override
  String get adminSearchHint => '이메일 또는 닉네임 검색';

  @override
  String get adminRoleAdmins => '관리자';

  @override
  String get adminRoleUsers => '사용자';

  @override
  String get adminRoleAll => '모든 역할';

  @override
  String get adminStatusFrozen => '정지됨';

  @override
  String get adminStatusActive => '활성';

  @override
  String get adminStatusAny => '모든 상태';

  @override
  String get adminOrderDesc => '내림차순';

  @override
  String get adminOrderAsc => '오름차순';

  @override
  String adminLoadFailed(String error) {
    return '불러오기 실패: $error';
  }

  @override
  String get adminUsersEmpty => '사용자가 없습니다';

  @override
  String get adminSortLastSeen => '최근 방문순';

  @override
  String get adminSortEmail => '이메일순';

  @override
  String get adminSortCreated => '가입일순';

  @override
  String adminBronzeBalance(int amount) {
    return '$amount 브론즈';
  }

  @override
  String get adminRevokeAdmin => '관리자 해제';

  @override
  String get adminGrantAdmin => '관리자로 지정';

  @override
  String get adminAdminRevoked => '관리자 권한을 해제했습니다';

  @override
  String get adminAdminGranted => '관리자 권한을 부여했습니다';

  @override
  String get adminGrantCoins => '코인 지급';

  @override
  String get adminWriteSupport => '지원으로 메시지';

  @override
  String get adminUnfreeze => '정지 해제';

  @override
  String get adminFreeze => '정지';

  @override
  String get adminUnfrozen => '정지를 해제했습니다';

  @override
  String get adminFrozenDone => '정지했습니다';

  @override
  String get adminResetPassword => '비밀번호 재설정';

  @override
  String get adminCoinsAmountHint => '수량(음수 = 차감)';

  @override
  String get adminReasonOptional => '사유(선택)';

  @override
  String get adminGrantSent => '카드를 지원 채팅으로 보냈습니다';

  @override
  String adminCoinsDebited(int amount) {
    return '브론즈 $amount을 차감했습니다';
  }

  @override
  String get adminGrantVerb => '지급';

  @override
  String get adminNewPasswordHint => '새 비밀번호(최소 6자)';

  @override
  String get adminPasswordReset => '비밀번호를 재설정했습니다';

  @override
  String get adminResetVerb => '재설정';

  @override
  String adminShortError(String error) {
    return '오류: $error';
  }

  @override
  String get adminSupportEmpty => '지원 요청이 없습니다';

  @override
  String get adminUserFallback => '사용자';

  @override
  String get apiErrTooManyRequests => '요청이 너무 많습니다. 나중에 다시 시도하세요.';

  @override
  String get apiErrMoveConflict => '수가 충돌했습니다. 다시 시도하세요.';

  @override
  String get shopElixirs => '엘릭서';

  @override
  String get shopElixirsSubtitle => '컬렉션을 회춘, 노화 또는 가속';

  @override
  String get shopElixirsHelp => '선반 세 개: 회춘, 노화, 가속. 각 선반에 여섯 병, 컬렉션 세트마다 하나. 엘릭서는 자기 세트에만 작용합니다.\n\n회춘은 한 단계 새롭게 하고 새것보다 새로워지지 않습니다. 노화는 한 단계 낡게 하고 낡은 것보다 더 낡지 않습니다. 가속은 낡은 것만: 빈티지까지 3개월, 한 번. 엘릭서만으로 빈티지가 되지는 않습니다.\n\n산 엘릭서는 아이템에 있습니다. 컬렉션 카드나 엘릭서 카드에서 사용합니다. 쓸 때마다 하나 소모됩니다.';

  @override
  String get elixirGroupRejuvenate => '회춘';

  @override
  String get elixirGroupAge => '노화';

  @override
  String get elixirGroupAccelerate => '가속';

  @override
  String get elixirEffectRejuvenate => '회춘';

  @override
  String get elixirEffectAge => '노화';

  @override
  String get elixirEffectAccelerate => '가속';

  @override
  String get elixirAdjCelebration => '축제';

  @override
  String get elixirAdjNature => '자연';

  @override
  String get elixirAdjLegends => '전설';

  @override
  String get elixirAdjCosmic => '우주';

  @override
  String get elixirAdjAdventure => '모험';

  @override
  String get elixirAdjJewels => '보석';

  @override
  String elixirName(String adjective, String effect) {
    return '$adjective $effect 엘릭서';
  }

  @override
  String get elixirHelpRejuvenate => '한 단계 새롭게 합니다. 새것보다 새로워지지 않습니다.';

  @override
  String get elixirHelpAge => '한 단계 낡게 합니다. 낡은 것보다 더 낡지 않습니다.';

  @override
  String get elixirHelpAccelerate => '낡은 것만. 빈티지까지 3개월, 한 번.';

  @override
  String get elixirUseRejuvenate => '회춘';

  @override
  String get elixirUseAge => '노화';

  @override
  String get elixirUseAccelerate => '가속';

  @override
  String get elixirUse => '사용';

  @override
  String collectionLeftDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일',
      one: '$count일',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count시간',
      one: '$count시간',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count분',
      one: '$count분',
    );
    return '$_temp0';
  }

  @override
  String elixirSetOnly(String set) {
    return '「$set」세트만.';
  }

  @override
  String get elixirPickCollection => '컬렉션 선택';

  @override
  String get elixirNoTarget => '이 세트에서 이 엘릭서를 쓸 컬렉션이 없습니다';

  @override
  String get elixirApplied => '엘릭서를 사용했습니다';

  @override
  String get elixirConfirmTitle => '이 엘릭서를 사용할까요?';

  @override
  String elixirConfirmBody(String elixir, String collection) {
    return '$elixir\n$collection';
  }

  @override
  String get inventoryNoElixirs => '엘릭서가 없습니다 — 상점에서 구매하세요';

  @override
  String get elixirNotApplicable => '지금은 이 컬렉션에 쓸 수 없습니다';

  @override
  String get elixirWrongSet => '다른 세트용 엘릭서입니다';

  @override
  String get elixirNotOwned => '이 엘릭서가 없습니다';

  @override
  String collectionUntil(String state, String left) {
    return '$state까지 $left';
  }

  @override
  String get collectionLeftSoon => '1분 미만';

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
}
