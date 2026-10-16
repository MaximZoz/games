import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'หน้าหลัก';

  @override
  String get navProfile => 'โปรไฟล์';

  @override
  String get navFriends => 'เพื่อน';

  @override
  String get navChats => 'แชท';

  @override
  String get navGames => 'เกม';

  @override
  String get navSettings => 'การตั้งค่า';

  @override
  String get settingsTitle => 'การตั้งค่า';

  @override
  String get settingsLanguage => 'ภาษา';

  @override
  String get settingsLanguageSystem => 'ตามระบบ';

  @override
  String get settingsSoundTitle => 'เสียง';

  @override
  String get settingsSoundSubtitle => 'เกมและการแจ้งเตือน';

  @override
  String get settingsSoundGames => 'เกม';

  @override
  String get settingsSoundNotifications => 'การแจ้งเตือน';

  @override
  String get settingsSoundTurn => 'ตา';

  @override
  String get settingsHapticsTitle => 'การสั่น';

  @override
  String get settingsHapticsSubtitle => 'เฉพาะการแจ้งเตือน: ข้อความ คำขอ ตาของคุณ และตัวจับเวลา';

  @override
  String get settingsGamepadTitle => 'คอนโทรลเลอร์';

  @override
  String get settingsGamepadSubtitle => 'เกมแพดสำหรับเมนูและเกม';

  @override
  String settingsGamepadConnected(String name) {
    return 'เชื่อมต่อแล้ว: $name';
  }

  @override
  String get settingsGamepadDisconnected => 'ไม่พบเกมแพด เชื่อมต่อคอนโทรลเลอร์แล้วกดปุ่มใดก็ได้';

  @override
  String get settingsGamepadGenericName => 'คอนโทรลเลอร์';

  @override
  String get settingsGamepadHelpNavigate => 'นำทาง';

  @override
  String get settingsGamepadHelpConfirm => 'เลือก';

  @override
  String get settingsGamepadHelpBack => 'กลับ';

  @override
  String get settingsGamepadHelpTabs => 'แท็บ';

  @override
  String get settingsGamepadHelpPlay => 'เคอร์เซอร์บนกระดานและไพ่ในมือ: หมากฮอส โอเอกซ์ เรือรบ ดูรัก อุโน โป๊กเกอร์ และแบ็กแกมมอน';

  @override
  String get settingsGamepadHelpCards => 'ไพ่';

  @override
  String get settingsGamepadHelpKeyboard => 'คีย์บอร์ด';

  @override
  String get settingsGamepadHelpBalance => 'ยอดเงิน';

  @override
  String get settingsGamepadHelpLogout => 'ออก';

  @override
  String get settingsGamepadHelpPage => 'หน้า';

  @override
  String get settingsGamepadLayoutXbox => 'ปุ่ม Xbox';

  @override
  String get settingsGamepadLayoutPlayStation => 'ปุ่ม PlayStation';

  @override
  String get settingsGamepadLayoutNintendo => 'ปุ่ม Nintendo';

  @override
  String get gamepadKeyboardTitle => 'คีย์บอร์ด';

  @override
  String get gamepadKeyboardSpace => 'เว้นวรรค';

  @override
  String get gamepadLegendConfirm => 'เลือก';

  @override
  String get gamepadLegendBack => 'กลับ';

  @override
  String get gamepadLegendTabs => 'แท็บ';

  @override
  String get gamepadLegendCycle => 'เปลี่ยน';

  @override
  String gamepadConnectedSnack(String name) {
    return 'เชื่อมต่อคอนโทรลเลอร์แล้ว: $name';
  }

  @override
  String get settingsOfflineModeTitle => 'โหมดเครือข่าย';

  @override
  String get settingsOfflineModeSubtitle => 'ออฟไลน์: เล่นกับบอททันที ไม่มีเดิมพันและรางวัล ไม่มีแชทและเพื่อน การซื้อจะถูกบันทึกและใช้ในโหมดออนไลน์ ออนไลน์ — เมื่อมีอินเทอร์เน็ตหรือตามการตั้งค่าของผู้ใช้';

  @override
  String get settingsModeOnline => 'ออนไลน์';

  @override
  String get settingsModeOffline => 'ออฟไลน์';

  @override
  String get gamesAlternateStartsHint => 'สลับกันว่าใครเริ่มเกม';

  @override
  String get rulesAlternateStarts => 'ผู้เริ่มก่อนจะสลับกันในแต่ละเกม';

  @override
  String get offlineBadgeTooltip => 'โหมดออฟไลน์';

  @override
  String get offlineModePopupTitle => 'โหมดออฟไลน์';

  @override
  String get offlineModePopupBody => 'โหมดออฟไลน์เปิดอยู่ เล่นกับบอทโดยไม่มีเดิมพันและรางวัล แชท เพื่อน และล็อบบี้ถูกซ่อน การซื้อจะใช้ในโหมดออนไลน์';

  @override
  String get offlineModePopupSettings => 'การตั้งค่า';

  @override
  String get offlineModeOfferBody => 'ไม่มีอินเทอร์เน็ตหรือการเชื่อมต่อช้ามาก คุณสามารถเปิดโหมดออฟไลน์แล้วเล่นกับบอทได้';

  @override
  String get offlineModeOfferAction => 'เปิดออฟไลน์';

  @override
  String get gamesPlay => 'เล่น';

  @override
  String get offlineGameTitle => 'เล่นกับบอท';

  @override
  String get offlineGameHint => 'ไม่มีเดิมพันและรางวัล · ออฟไลน์เท่านั้น';

  @override
  String get offlineBotWon => 'บอทชนะ';

  @override
  String get offlineBotThinking => 'บอทกำลังคิด…';

  @override
  String get offlinePlayAgain => 'อีกครั้ง';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'รับ';

  @override
  String get durakActionAll => 'ทั้งหมด';

  @override
  String get durakActionDone => 'เสร็จ';

  @override
  String get durakActionBito => 'Beat';

  @override
  String get durakHintDefend => 'ป้องกัน';

  @override
  String get durakHintDefendOrTransfer => 'ป้องกันหรือส่งต่อ';

  @override
  String get durakHintOpponentDefends => 'คู่แข่งป้องกัน';

  @override
  String get durakHintThrowInFirst => 'ทิ้งไพ่เพิ่ม (สูงสุด 5 ในตาแรก)';

  @override
  String get durakHintThrowIn => 'ทิ้งไพ่เพิ่มหรือรอการป้องกัน';

  @override
  String get durakHintOpponentThrows => 'คู่แข่งทิ้งเพิ่ม';

  @override
  String get durakHintTakeFollow => 'ทิ้งเพิ่มหลังรับหรือกด «เสร็จ»';

  @override
  String get durakHintOpponentTakeFollow => 'คู่แข่งทิ้งเพิ่มหลังรับได้';

  @override
  String get durakHintBito => 'ทิ้งการ์ดหรือพูด «บิโต»';

  @override
  String get durakHintOpponentBito => 'คู่แข่งทิ้งเพิ่มหรือพูด «บิโต»';

  @override
  String get durakHintYourAttack => 'ตาคุณ — โจมตี';

  @override
  String get durakHintOpponentAttack => 'คู่แข่งโจมตี';

  @override
  String get durakHintYouLost => 'คุณแพ้ — คุณคือคนโง่';

  @override
  String get durakHintDrawAllOut => 'เสมอ — ทุกคนออก';

  @override
  String get durakHintYouFinished => 'คุณออกแล้ว — รอจบเกม';

  @override
  String get durakFirstLeadYou => 'คุณออกก่อน';

  @override
  String get durakFirstLeadOpponent => 'ฝ่ายตรงข้ามออกก่อน';

  @override
  String get durakFirstLeadBot => 'บอทออกก่อน';

  @override
  String durakFirstLeadOf(String name) {
    return '$name ออกก่อน';
  }

  @override
  String get durakFirstLeadReason => 'ไพ่ทรัมป์ต่ำสุด';

  @override
  String get shopPurchaseQueued => 'บันทึกการซื้อแล้ว — จะใช้ในโหมดออนไลน์';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — ใช้การซื้อแล้ว';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — ไม่ได้ใช้การซื้อ: $reason';
  }

  @override
  String get settingsFriendsOnlyTitle => 'ข้อความจากเพื่อนเท่านั้น';

  @override
  String get settingsFriendsOnlySubtitle => 'ผู้ที่ไม่ใช่เพื่อนส่งได้เฉพาะอีโมจิ หากถูกรบกวน ให้บล็อกผู้ใช้นั้นชั่วคราว';

  @override
  String get settingsNotifications => 'การแจ้งเตือน';

  @override
  String get settingsPushChat => 'แชท';

  @override
  String get settingsPushFriends => 'เพื่อน';

  @override
  String get settingsPushGames => 'เกม';

  @override
  String get settingsPushRewards => 'รางวัล';

  @override
  String settingsAppVersion(String version) {
    return 'เวอร์ชัน $version';
  }

  @override
  String get appUpdateTitle => 'มีอัปเดต';

  @override
  String get appUpdateBody => 'มีเวอร์ชันใหม่ของแอป อัปเดตเพื่อดำเนินการต่อ';

  @override
  String get appUpdateWhatsNew => 'มีอะไรใหม่';

  @override
  String get appUpdateOk => 'อัปเดต';

  @override
  String get appUpdateLaterBanner => 'เราจะอัปเดตแอปหลังเกมนี้';

  @override
  String get loginTitle => 'เข้าสู่ระบบ';

  @override
  String get loginSubtitle => 'ใส่อีเมลหรือชื่อผู้ใช้และรหัสผ่าน';

  @override
  String get loginEmailLabel => 'อีเมลหรือชื่อผู้ใช้';

  @override
  String get loginPasswordLabel => 'รหัสผ่าน';

  @override
  String get loginSubmit => 'เข้าสู่ระบบ';

  @override
  String get loginNoAccount => 'ยังไม่มีบัญชี? สมัครสมาชิก';

  @override
  String get loginEmailRequired => 'ใส่อีเมลหรือชื่อผู้ใช้';

  @override
  String get loginPasswordRequired => 'ใส่รหัสผ่าน';

  @override
  String get loginTooltip => 'เข้าสู่ระบบ';

  @override
  String get logoutTooltip => 'ออกจากระบบ';

  @override
  String get registerTitle => 'สมัครสมาชิก';

  @override
  String get registerSubtitle => 'สร้างบัญชีเพื่อเล่น';

  @override
  String get registerNameLabel => 'ชื่อ (ชื่อผู้ใช้)';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'รหัสผ่าน';

  @override
  String get registerSubmit => 'สมัครสมาชิก';

  @override
  String get registerHaveAccount => 'มีบัญชีแล้ว? เข้าสู่ระบบ';

  @override
  String get registerNameRequired => 'ใส่ชื่อ';

  @override
  String get registerNameNoSpaces => 'ชื่อต้องไม่มีช่องว่าง';

  @override
  String get registerNameMax => 'สูงสุด 20 ตัวอักษร';

  @override
  String get registerNameHint => 'ไม่เกิน 20 ตัวอักษร';

  @override
  String get registerEmailRequired => 'ใส่อีเมล';

  @override
  String get registerEmailInvalid => 'อีเมลไม่ถูกต้อง';

  @override
  String get registerPasswordHint => 'อย่างน้อย 6 ตัวอักษร';

  @override
  String get registerPasswordMin => 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';

  @override
  String get commonCancel => 'ยกเลิก';

  @override
  String get commonSave => 'บันทึก';

  @override
  String get commonDelete => 'ลบ';

  @override
  String get commonEdit => 'แก้ไข';

  @override
  String get commonReply => 'ตอบกลับ';

  @override
  String get commonSend => 'ส่ง';

  @override
  String get commonClose => 'ปิด';

  @override
  String get openInApp => 'เปิดในแอป';

  @override
  String get commonRetry => 'ลองอีกครั้ง';

  @override
  String get commonLoading => 'กำลังโหลด…';

  @override
  String get commonError => 'ข้อผิดพลาด';

  @override
  String get commonOnline => 'ออนไลน์';

  @override
  String get commonOffline => 'ออฟไลน์';

  @override
  String get commonOnlineCap => 'ออนไลน์';

  @override
  String get commonUser => 'ผู้ใช้';

  @override
  String get commonPlayer => 'ผู้เล่น';

  @override
  String get commonAboutMe => 'เกี่ยวกับฉัน';

  @override
  String get commonBack => 'กลับ';

  @override
  String get commonAccept => 'ยอมรับ';

  @override
  String get commonDecline => 'ปฏิเสธ';

  @override
  String get commonCreating => 'กำลังสร้าง…';

  @override
  String get commonSearching => 'กำลังค้นหา…';

  @override
  String get commonInsufficientCoins => 'เหรียญไม่พอ';

  @override
  String get commonNotFound => 'ไม่พบ';

  @override
  String get commonServerErrorShort => 'เซิร์ฟเวอร์ผิดพลาด';

  @override
  String get commonForbidden => 'ไม่มีสิทธิ์เข้าถึง';

  @override
  String get commonUserBlocked => 'ผู้ใช้ถูกบล็อก';

  @override
  String get commonUserNotFound => 'ไม่พบผู้ใช้';

  @override
  String get commonGenericError => 'เกิดข้อผิดพลาด โปรดลองอีกครั้ง';

  @override
  String get apiErrWrongGameType => 'ประเภทเกมไม่ถูกต้อง';

  @override
  String get apiErrWrongGameTypeOrState => 'ประเภทหรือสถานะเกมไม่ถูกต้อง';

  @override
  String get apiErrLobbyFull => 'ล็อบบี้เต็มแล้ว';

  @override
  String get apiErrBadState => 'สถานะเกมไม่ถูกต้อง';

  @override
  String get apiErrIllegalMove => 'ตาเดินนี้ทำไม่ได้';

  @override
  String get apiErrUnknownMoveType => 'ไม่รู้จักชนิดตาเดิน';

  @override
  String get apiErrNoOpponents => 'ไม่มีคู่แข่ง';

  @override
  String get apiErrNoOpponentsRematch => 'ไม่มีคู่แข่งสำหรับรีแมตช์';

  @override
  String get apiErrAlreadyInLobby => 'คุณอยู่ในล็อบบี้นี้แล้ว';

  @override
  String get apiErrGameNotActive => 'เกมไม่ได้ดำเนินอยู่';

  @override
  String get apiErrNotInBattle => 'ไม่ได้อยู่ช่วงต่อสู้';

  @override
  String get apiErrNotInSetup => 'ไม่ได้อยู่ช่วงจัดวาง';

  @override
  String get apiErrAlreadyReady => 'คุณพร้อมแล้ว';

  @override
  String get apiErrAlreadyForfeited => 'คุณยอมแพ้ไปแล้ว';

  @override
  String get apiErrYouHaveForfeited => 'คุณยอมแพ้แล้ว';

  @override
  String get apiErrNoDrawOffer => 'ไม่มีข้อเสนอเสมอ';

  @override
  String get apiErrDrawOnlyPvp => 'เสนอเสมอได้เฉพาะกับผู้เล่น';

  @override
  String get apiErrDrawOnly1v1 => 'เสนอเสมอได้เฉพาะ 1 ต่อ 1';

  @override
  String get apiErrDrawVsBot => 'เสนอเสมอกับบอทไม่ได้';

  @override
  String get apiErrDrawMultiplayer => 'เสนอเสมอไม่ได้ในโหมดหลายคน';

  @override
  String get apiErrDeck24TwoPlayers => 'สำรับ 24 ใบสำหรับ 2 คนเท่านั้น';

  @override
  String get apiErrDeck52ThreeOrFour => 'สำรับ 52 ใบต้องมี 3 หรือ 4 คน';

  @override
  String get apiErrAccountFrozen => 'บัญชีถูกระงับ';

  @override
  String get apiErrTurnTimeInvalid => 'เวลาต่อตาต้องเป็น 0, 20, 60 หรือ 600 วินาที';

  @override
  String get timeJustNow => 'เมื่อสักครู่';

  @override
  String get timeYesterday => 'เมื่อวาน';

  @override
  String timeMinutesAgo(int count) {
    return '$count นาทีที่แล้ว';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count ชม. ที่แล้ว';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count วันที่แล้ว';
  }

  @override
  String get timeWeekAgo => 'หนึ่งสัปดาห์ที่แล้ว';

  @override
  String timeWeeksAgo(int count) {
    return '$count สัปดาห์ที่แล้ว';
  }

  @override
  String get timeMonthAgo => 'หนึ่งเดือนที่แล้ว';

  @override
  String timeMonthsAgo(int count) {
    return '$count เดือนที่แล้ว';
  }

  @override
  String get timeYearAgo => 'หนึ่งปีที่แล้ว';

  @override
  String timeYearsAgo(int count) {
    return '$count ปีที่แล้ว';
  }

  @override
  String get weekdaySun => 'อา.';

  @override
  String get weekdayMon => 'จ.';

  @override
  String get weekdayTue => 'อ.';

  @override
  String get weekdayWed => 'พ.';

  @override
  String get weekdayThu => 'พฤ.';

  @override
  String get weekdayFri => 'ศ.';

  @override
  String get weekdaySat => 'ส.';

  @override
  String get monthJan => 'ม.ค.';

  @override
  String get monthFeb => 'ก.พ.';

  @override
  String get monthMar => 'มี.ค.';

  @override
  String get monthApr => 'เม.ย.';

  @override
  String get monthMay => 'พ.ค.';

  @override
  String get monthJun => 'มิ.ย.';

  @override
  String get monthJul => 'ก.ค.';

  @override
  String get monthAug => 'ส.ค.';

  @override
  String get monthSep => 'ก.ย.';

  @override
  String get monthOct => 'ต.ค.';

  @override
  String get monthNov => 'พ.ย.';

  @override
  String get monthDec => 'ธ.ค.';

  @override
  String get homeAchievements => 'ความสำเร็จ';

  @override
  String get homeAchievementsSubtitle => 'ผลการเล่นของคุณ';

  @override
  String get homeAchievementsRewards => 'มีรางวัลพร้อมรับ';

  @override
  String get homeCoins => 'เหรียญ';

  @override
  String get homeCoinsSubtitle => 'ยอดคงเหลือและรางวัล';

  @override
  String get homeCoinsDailyReward => 'มีรางวัลล็อกอินรายวันพร้อมรับ';

  @override
  String get homeItems => 'ไอเท็ม';

  @override
  String get homeItemsInventory => 'คลังของคุณ';

  @override
  String get homeItemsGifted => 'มีคนมอบคอลเลกชันให้คุณ';

  @override
  String get homeItemsIncome => 'รายได้จากคอลเลกชันพร้อมรับ';

  @override
  String get homeShop => 'ร้านค้า';

  @override
  String get homeShopSubtitle => 'อีโมจิ เดิมพัน คอลเลกชัน';

  @override
  String get gamesTitle => 'เกม';

  @override
  String get gamesFindMatch => 'หาเกม';

  @override
  String get gamesMyTurn => 'ตาคุณ';

  @override
  String get gamesWaiting => 'กำลังรอ';

  @override
  String get gamesLobbyTab => 'ล็อบบี้';

  @override
  String get gamesTicTacToe => 'โอเอกซ์';

  @override
  String get gamesDurak => 'ดูรัก';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => 'หมุน';

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
  String get gamesPoker => 'โป๊กเกอร์';

  @override
  String get gamesUno => 'อูโน่';

  @override
  String get gamesNardy => 'แบ็กแกมมอน';

  @override
  String get gamesNardyModeShort => 'สั้น';

  @override
  String get gamesNardyModeLong => 'ยาว';

  @override
  String get gamesCheckers => 'หมากฮอส';

  @override
  String get gamesCheckersModeRussian => 'รัสเซีย';

  @override
  String get gamesCheckersModeEnglish => 'อังกฤษ';

  @override
  String get gamesCheckersModeGiveaway => 'กิฟอะเวย์';

  @override
  String get gamesCheckersModeCorners => 'มุม';

  @override
  String get gamesChess => 'หมากรุก';

  @override
  String get gamesDomino => 'โดมิโน';

  @override
  String get gamesDominoModeKozel => 'แพะ';

  @override
  String get gamesDominoModeClassic => 'คลาสสิก';

  @override
  String get gamesDominoModeSea => 'ทะเล';

  @override
  String get rulesDominoDeal => 'แต่ละคนได้ 7 ตัว ถ้า 2 หรือ 3 คน ที่เหลืออยู่ในกอง ถ้า 4 คน กองว่าง';

  @override
  String get rulesDominoOpen => 'ตาแรกเริ่มด้วยคู่ที่น้อยสุดจาก 1-1 ถึง 6-6 แล้วจึง 0-0 ถ้าไม่มีคู่ ให้เริ่มด้วยตัวที่มากสุด และต้องลงตัวนั้น';

  @override
  String get rulesDominoPlay => 'วางตัวที่ปลายเปิดที่มีเลขเดียวกัน คู่ที่ปลายไม่เปลี่ยนเลขนั้น';

  @override
  String get rulesDominoDraw => 'ถ้าลงไม่ได้ จั่วทีละใบจนกว่าจะลงได้หรือกองหมด ใบสุดท้ายจั่วได้ ถ้ายังลงไม่ได้ ให้ผ่าน';

  @override
  String get rulesDominoScore => 'จบตา แต่ละคนจดผลรวมของตัวที่เหลือ คนที่หมดจด 0 เล่นถึง 101 คนที่ถึงคือแพะและแพ้';

  @override
  String get rulesDominoFish => 'ปลา: กองว่างและไม่มีใครลงได้ ผลรวมน้อยสุดเพียงคนเดียวได้ 0 ที่เหลือจดของตน ถ้าน้อยสุดเท่ากันทุกคนจด';

  @override
  String get rulesDominoMatch => 'ถ้าหลายคนข้าม 101 ในตาเดียวกัน แพะคือคะแนนสูงสุด ผู้ชนะคือคะแนนต่ำสุด ถ้าเท่ากันทั้งหมดคือเสมอ';

  @override
  String get rulesDominoOffline => 'ออฟไลน์: คุณกับบอต บอตนับเลขและไม่แอบดูมือที่ซ่อน';

  @override
  String rulesDominoMode(String mode) {
    return 'โหมด: $mode';
  }

  @override
  String get rulesDominoClassicDeal => 'สองหรือสามคนได้คนละ 7 ชิ้น สี่คนได้คนละ 5 ที่เหลือคือกองกลาง';

  @override
  String get rulesDominoClassicOpen => 'มือแรกเปิดด้วยเบิ้ล 6 แล้ว 0-0 แล้วเบิ้ลที่น้อยลง ถ้าไม่มีเบิ้ลต้องลงตัวสูงสุด';

  @override
  String get rulesDominoClassicScore => 'คนที่หมดมือได้แต้มของคู่แข่ง คนแรกถึง 100 ชนะ';

  @override
  String get rulesDominoClassicFish => 'เมื่อบล็อก คนที่แต้มน้อยที่สุดคนเดียวได้ส่วนต่างจากแต่ละมือ ถ้าเสมอกันไม่มีใครได้แต้ม';

  @override
  String get rulesDominoClassicMatch => 'คะแนนสูงสุดเท่ากันแบ่งชัย ถ้าทุกคนเท่ากันคือเสมอ';

  @override
  String get rulesDominoSeaSame => 'แจก เปิด และจั่วเหมือนแพะ สายมีสองปลาย';

  @override
  String get rulesDominoSeaScore => 'คนที่แต้มในมือมากที่สุดคนเดียวได้บันทึก น้อยกว่า 25 ไม่บันทึก';

  @override
  String get rulesDominoSeaWipe => 'ถ้าสองคนมี 25 ขึ้นไปพร้อมกัน มือนี้ไม่มีใครได้บันทึก';

  @override
  String get rulesDominoSeaBlank => 'ลง 0-0 จบมือทันที คนที่หนักที่สุดคนเดียวได้ 75 ถ้าเสมอกันไม่มีใครได้';

  @override
  String get rulesDominoSeaSix => 'ปิดมือด้วย 6-6 ใบสุดท้าย คนแพ้ได้ 100 และคะแนนแมตช์ของผู้ปิดถูกล้าง';

  @override
  String get rulesDominoSeaMatch => 'แมตช์ถึง 125 คนที่ถึงแพ้';

  @override
  String get dominoBoneyard => 'กอง';

  @override
  String get dominoChooseEnd => 'เลือกปลาย';

  @override
  String get dominoFish => 'ปลา';

  @override
  String get dominoYouGoat => 'คุณคือแพะ';

  @override
  String dominoGoatNamed(String name) {
    return 'แพะ — $name';
  }

  @override
  String get dominoLeft => 'ซ้าย';

  @override
  String get dominoRight => 'ขวา';

  @override
  String get gamesChessModeClassic => 'คลาสสิก';

  @override
  String get gamesChessModeRapid => 'ราปิด';

  @override
  String get gamesChessModeBlitz => 'บลิทซ์';

  @override
  String get gamesChessModeBullet => 'กระสุน';

  @override
  String get chessPieceQueen => 'ควีน';

  @override
  String get chessPieceRook => 'เรือ';

  @override
  String get chessPieceBishop => 'บิชอป';

  @override
  String get chessPieceKnight => 'อัศวิน';

  @override
  String get chessPromotionTitle => 'การเลื่อนขั้นเบี้ย';

  @override
  String get chessDrawStalemate => 'เสมอ: อับ';

  @override
  String get chessDrawInsufficient => 'เสมอ: หมากไม่พอรุกจน';

  @override
  String get chessDrawRepetition => 'เสมอ: ตำแหน่งซ้ำสามครั้ง';

  @override
  String get chessDrawFiftyMove => 'เสมอ: กฎ 50 ตา';

  @override
  String get chessCheck => 'รุก';

  @override
  String get rulesCheckersPlayers => 'ผู้เล่น: 2';

  @override
  String rulesCheckersMode(String mode) {
    return 'โหมด: $mode';
  }

  @override
  String rulesCheckersTime(String time) {
    return 'Время на ход: $time. Если время вышло — проигрыш.';
  }

  @override
  String get rulesCheckersIntro => 'กระดาน 8×8 สองผู้เล่น';

  @override
  String get rulesCheckersPlay => 'ต้องกิน หากดามก้าหรือตัวธรรมดาลงช่องแล้วยังกินต่อได้ ห้ามหยุดกลางทาง ถ้ามีหลายทิศทางเลือกทิศใดก็ได้ ไม่บังคับทางที่กินมากสุด ตัวธรรมดาถึงแถวสุดท้ายเป็นดามก้า';

  @override
  String get rulesCheckersWin => 'В русских шашках побеждает тот, кто съел все шашки соперника или лишил его хода. В поддавках наоборот: кто не может ходить — выигрывает.';

  @override
  String get rulesCheckersOfflineBot => 'Офлайн: партия против бота.';

  @override
  String get rulesCheckersPlayRussian => 'หมากฮอสรัสเซีย: คนละ 12 ตัวบนช่องเข้ม ตัวธรรมดาเดินทแยงไปข้างหน้าและกินไปข้างหน้าหรือถอยหลัง ดामก้าบินได้ทุกช่อง ต้องกิน: ถ้ากินต่อได้ห้ามหยุด แต่ถ้ามีหลายทิศทางเลือกทิศใดก็ได้ ไม่บังคับทางที่ยาวสุด ชนะเมื่อกินหมดหรือคู่ต่อสู้เดินไม่ได้';

  @override
  String get rulesCheckersPlayEnglish => 'หมากฮอสอังกฤษ: คนละ 12 ตัว ตัวธรรมดาเดินและกินทแยงไปข้างหน้าเท่านั้น ดามก้าเดินทแยงหนึ่งช่อง ต้องกิน ชนะเมื่อกินหมดหรือคู่ต่อสู้เดินไม่ได้';

  @override
  String get rulesCheckersPlayGiveaway => 'กิฟอะเวย์: เดินแบบหมากฮอสรัสเซีย แต่เป้าหมายกลับกัน คือยอมเสียหมากทั้งหมดหรือเดินไม่ได้ การกินยังบังคับ';

  @override
  String get rulesCheckersPlayCorners => 'มุม: หมากเริ่มที่มุมตรงข้าม เดินไปช่องว่างข้างเคียงในแนวตั้งหรือแนวนอน หรือกระโดดข้ามหมากใดก็ได้โดยไม่กิน เป้าหมายคือย้ายหมากทั้งหมดไปมุมฝ่ายตรงข้าม';

  @override
  String get rulesCheckersPlayCornersNoReturn => 'หมากที่ออกจากมุมเริ่มต้นแล้วห้ามกลับเข้าไป';

  @override
  String get rulesCheckersPlayCornersLeaveHome => 'หมากที่ยังอยู่ในบ้านต้องออกภายใน 25 ตาแรกของผู้เล่น';

  @override
  String get rulesCheckersDrawRussian => 'เสมอหากตำแหน่งซ้ำสามครั้ง หรือ 15 ตาต่อฝ่ายไม่มีความคืบหน้า: ไม่กิน ไม่เดินหมากธรรมดา และไม่เลื่อนเป็นคิง';

  @override
  String get rulesCheckersDrawEnglish => 'เสมอหากตำแหน่งซ้ำสามครั้ง หาก 40 ตาต่อฝ่ายผ่านไปโดยไม่กินและไม่เดินหมากธรรมดา หรือเหลือคิงฝ่ายละตัว';

  @override
  String get rulesCheckersDrawGiveaway => 'เสมอหากตำแหน่งซ้ำสามครั้ง หรือ 15 ตาต่อฝ่ายในโหมดยกให้ไม่มีความคืบหน้า: ไม่กิน ไม่เดินหมากธรรมดา และไม่เลื่อนเป็นคิง';

  @override
  String get rulesCheckersDrawCorners => 'เสมอหากตำแหน่งซ้ำสามครั้ง หรือ 25 ตาต่อฝ่ายไม่ได้เพิ่มหมากในมุมเป้าหมาย';

  @override
  String get rulesChessPlayers => 'ผู้เล่น: 2.';

  @override
  String rulesChessMode(String mode) {
    return 'โหมด: $mode.';
  }

  @override
  String get rulesChessPlayClassic => 'กระดาน 8×8 แต่ละฝ่ายมีคิง ควีน เรือ 2 บิชอป 2 ม้า 2 และเบี้ย 8 ขาวเดินก่อน เดินตามปกติ มีการกินผ่าน โปรโมต และเข้าปราสาท ชนะด้วยรุกฆาตหรือคู่ต่อสู้ยอมแพ้';

  @override
  String get rulesChessDrawClassic => 'เสมอเมื่อแพต ซ้ำสามครั้ง กติกา 50 ตา หมากไม่พอรุกฆาต หรือตกลงกัน';

  @override
  String get rulesChessClockClassic => 'นาฬิกา: 60+0 — 60 นาทีทั้งเกม ไม่มีบวกเวลา';

  @override
  String get rulesChessClockRapid => 'นาฬิกา: 10+0 — 10 นาทีทั้งเกม ไม่มีบวกเวลา';

  @override
  String get rulesChessClockBlitz => 'นาฬิกา: 5+0 — 5 นาทีทั้งเกม ไม่มีบวกเวลา';

  @override
  String get rulesChessClockBullet => 'นาฬิกา: 3+2 — 3 นาที บวก 2 วินาทีต่อตา';

  @override
  String get checkersDrawRepetition => 'เสมอ — ตำแหน่งซ้ำสามครั้ง';

  @override
  String get checkersDrawNoProgress => 'เสมอ — หมากไม่นำไปสู่ชัยชนะ';

  @override
  String get checkersDrawInsufficient => 'เสมอ — หมากไม่พอสำหรับชนะ';

  @override
  String get rulesNardyTitle => 'แบ็กแกมมอน — กติกา';

  @override
  String get rulesNardyPlayers => 'ผู้เล่น: 2 คน';

  @override
  String rulesNardyMode(String mode) {
    return 'โหมด: $mode';
  }

  @override
  String get rulesNardyIntro => 'กระดาน 24 จุด คนละ 15 ตัว ลูกเต๋า 2 ลูก: ตัวเดียวตามผลรวม หรือสองตัวตามแต้ม';

  @override
  String get rulesNardyPlayShort => 'สั้น: เดินสวนทางและตีตัวเดี่ยวได้ ตัวที่ถูกตีขึ้นบาร์แล้วต้องเข้าใหม่ เมื่อทั้งหมดอยู่บ้านให้นำออก';

  @override
  String get rulesNardyPlayLong => 'ยาว: ทั้งคู่เริ่มจากหัวเดียวกันและไปทางเดียวกัน จากหัวออกได้ไม่เกินหนึ่งตัวต่อตา ห้ามตี เมื่อทั้งหมดอยู่บ้านให้นำออก';

  @override
  String get rulesNardyWin => 'ผู้ที่นำหมากออกครบก่อนชนะ';

  @override
  String get rulesNardySixPrime => 'ห้ามปิดหกช่องติดกันจนกว่าหมากของคู่แข่งอย่างน้อยหนึ่งตัวจะผ่านไปแล้ว';

  @override
  String get nardyRoll => 'ทอยลูกเต๋า';

  @override
  String get nardySkipTurn => 'ข้ามตา';

  @override
  String get nardyUndoMove => 'ย้อนกลับ';

  @override
  String get nardyDoneTurn => 'เสร็จ';

  @override
  String get nardyAutoConfirm => 'ยืนยันอัตโนมัติ';

  @override
  String get nardyAutoConfirmHint => 'เมื่อเดินครบทุกตา จะส่งตาให้อีกฝ่ายทันที';

  @override
  String get nardyLayoutToggle => 'เปลี่ยนการจัดเรียง';

  @override
  String get nardyNoMoves => 'ไม่มีตาเดิน';

  @override
  String get nardyYourRoll => 'การทอยของคุณ';

  @override
  String get nardyPipsShort => 'เหลือ:';

  @override
  String get nardyYouWonMars => 'คุณชนะ — แกมมอน!';

  @override
  String get nardyYouLostMars => 'แพ้ — แกมมอน';

  @override
  String get rulesNardyOfflineBot => 'ออฟไลน์: เล่นกับบอท';

  @override
  String rulesUnoPlayers(int players) {
    return 'ผู้เล่น: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'เล่นกับบอท ไม่จำกัดเวลาต่อตา';

  @override
  String get rulesUnoIntro => 'แจกคนละ 7 ใบ ลงไพ่สีเดียวกันหรือค่าเดียวกัน (ตัวเลขหรือไพ่พิเศษชนิดเดียวกัน)';

  @override
  String get rulesUnoPlay => 'ข้าม — คนถัดไปเสียตา กลับทางเมื่อเล่นสองคนทำงานเหมือนข้าม +2 ซ้อนได้เฉพาะบน +2 และ +4 เฉพาะบน +4 โทษรวมกัน (สองใบ +2 คนถัดไปจั่ว 4) ห้ามวาง +2 บน +4 ใครไม่ซ้อนต้องจั่วทั้งกองและเสียตาไพ่ธรรมดาที่เหมือนกันสองใบ (เช่น 8 เหลืองสองใบ) ทิ้งพร้อมกัน เล่นใบหนึ่ง อีกใบออกอัตโนมัติ';

  @override
  String get rulesUnoWild => 'ไพ่ดำกำหนดสีใหม่ ลง +4 ได้เมื่อไม่มีไพ่สีปัจจุบัน คู่แข่งท้าได้: ถ้า +4 ถูกกติกา ผู้ท้าจั่ว 6 ถ้าไม่ถูก ผู้ลง +4 จั่ว 4 และผู้ท้าได้ลงไพ่';

  @override
  String get rulesUnoDraw => 'ไม่มีไพ่ที่ลงได้ ให้จั่วหนึ่งใบจากกอง ถ้าเข้ากันได้ลงทันทีหรือเก็บแล้วส่งตา ห้ามจั่วถ้ายังมีไพ่ที่ลงได้';

  @override
  String get rulesUnoWin => 'เดี่ยวถึง 100 แต้ม ตั้งแต่ 3 คนถึง 200 ชนะรอบคือผู้ลงไพ่หมดมือ';

  @override
  String get rulesUnoCall => 'เหลือใบเดียวให้กด «อูโน่!» ทันที คู่แข่งจับที่ลืมอุโนได้หลังหนึ่งวินาที — แล้วคุณจั่ว 2 ใบ';

  @override
  String get rulesUnoScoring => 'ใครลงหมดก่อนชนะรอบและได้แต้มจากมือคู่แข่ง: ตัวเลขตามหน้าไพ่ พิเศษ 20 ดำ 50 เดี่ยวถึง 100 ตั้งแต่ 3 คนถึง 200';

  @override
  String get unoColorRed => 'แดง';

  @override
  String get unoColorYellow => 'เหลือง';

  @override
  String get unoColorGreen => 'เขียว';

  @override
  String get unoColorBlue => 'น้ำเงิน';

  @override
  String get unoDraw => 'จั่ว';

  @override
  String get unoKeep => 'เก็บ';

  @override
  String get unoSayUno => 'อูโน่!';

  @override
  String get unoChallengeUno => 'ท้าอูโน่';

  @override
  String get unoChallengeWd4 => 'ท้า +4';

  @override
  String get unoChooseColor => 'เลือกสี';

  @override
  String get unoDrawPile => 'กองจั่ว';

  @override
  String get unoDiscardPile => 'กองทิ้ง';

  @override
  String unoCardsCount(int count) {
    return 'ไพ่: $count';
  }

  @override
  String unoScore(int score) {
    return 'คะแนน: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'รอบ $round · ถึง $target';
  }

  @override
  String get unoYourTurn => 'ตาของคุณ';

  @override
  String get unoWaitingTurn => 'ตาของคู่แข่ง';

  @override
  String get unoChooseColorHint => 'เลือกสีสำหรับไพ่เปลี่ยนสี';

  @override
  String get unoWd4Hint => 'จั่ว 4 ใบหรือท้า Wild +4';

  @override
  String get unoDrawnHint => 'ลงไพ่ที่จั่วหรือเก็บไว้';

  @override
  String get unoPlayHint => 'ลงไพ่สีหรือค่าเดียวกัน';

  @override
  String get unoDrawHint => 'ไม่มีไพ่ที่ลงได้ — จั่วจากกอง';

  @override
  String unoPendingDraw(int count) {
    return '+$count ใบ';
  }

  @override
  String get unoYouWon => 'คุณชนะเกม!';

  @override
  String get unoYouLost => 'เกมจบแล้ว';

  @override
  String get unoYouLostTimeout => 'คุณแพ้เพราะหมดเวลา';

  @override
  String unoWinner(String name) {
    return 'ผู้ชนะ: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name ชนะรอบ';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'ต่อไป';

  @override
  String get unoRoundScoresTitle => 'คะแนนรอบ';

  @override
  String get unoDirectionClockwise => 'ตามเข็มนาฬิกา';

  @override
  String get unoDirectionCounterclockwise => 'ทวนเข็มนาฬิกา';

  @override
  String get unoErrStackSameOnly => 'เล่น +2 ทับ +2 หรือ +4 ทับ +4 เท่านั้น ห้ามวาง +2 ทับ +4';

  @override
  String get unoErrCatchTooEarly => 'รอหนึ่งวินาที — พวกเขายังพูดอุโนได้';

  @override
  String get unoErrCallTooLate => 'พูดอุโนไม่ได้อีกแล้ว ผู้เล่นถัดไปเดินไปแล้ว';

  @override
  String get gamesInDevelopment => 'กำลังพัฒนา';

  @override
  String rulesPokerPlayers(int players) {
    return 'ผู้เล่น: $players.';
  }

  @override
  String get rulesPokerIntro => 'เท็กซัสโฮลเด็ม ผู้เล่นได้ไพ่ส่วนตัว 2 ใบ และไพ่กลาง 5 ใบบนโต๊ะ';

  @override
  String get rulesPokerPlay => 'รอบเดิมพัน: พรีฟล็อป ฟล็อป เทิร์น และริเวอร์ โฟลด คอล เบท หรือเรสได้';

  @override
  String get rulesPokerWin => 'มือห้าใบที่ดีที่สุด (ส่วนตัว+กลาง) ชนะ หรือผู้ที่เหลือคนเดียวหลังโฟลด';

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
  String get gamesRules => 'กติกา';

  @override
  String get gamesRulesTitle => 'กติกาเกม';

  @override
  String get gamesCreate => 'สร้างเกม';

  @override
  String get gamesJoin => 'เข้าร่วม';

  @override
  String get gamesOpponentTurn => 'ตาคู่แข่ง';

  @override
  String get gamesCurrentGame => 'เกมปัจจุบัน';

  @override
  String get gamesInvitedYou => 'คุณได้รับคำเชิญ';

  @override
  String get gamesTurnTime => 'เวลาต่อตา';

  @override
  String get gamesGridSize => 'ขนาดตาราง';

  @override
  String get gamesSwapSides => 'สลับฝ่าย';

  @override
  String get gamesNoCenter => 'ห้ามเริ่มกลางกระดาน';

  @override
  String get gamesObservation => 'ดูอยู่';

  @override
  String get gamesObservationHint => 'ดูได้จนจบเกม';

  @override
  String get gamesFinishCurrentFirst => 'จบเกมปัจจุบันก่อน';

  @override
  String get gamesVariantClassic => 'คลาสสิก';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 คน';

  @override
  String get gamesVariantMulti4 => '4 คน';

  @override
  String get gamesDurakModePodkidnoi => 'ทิ้งเพิ่ม';

  @override
  String get gamesDurakModePerevodnoi => 'ส่งต่อ';

  @override
  String get gamesDurakDeck24 => '24 ใบ';

  @override
  String get gamesDurakDeck36 => '36 ใบ';

  @override
  String get gamesDurakDeck52 => '52 ใบ';

  @override
  String rulesDurakMode(String mode) {
    return 'โหมด: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'ผู้เล่น: $players. สำรับ: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'เล่นกับบอท ไม่มีเดิมพันและไม่จำกัดเวลา';

  @override
  String get rulesDurakAttack => 'ฝ่ายรุกออกไพ่ ฝ่ายรับต้องทับ (ดอกเดียวกันที่สูงกว่า หรือไพ่ตาย) ไพ่ตายทับได้ด้วยไพ่ตายที่สูงกว่าเท่านั้น';

  @override
  String get rulesDurakBeat => 'เมื่อทับครบแล้วฝ่ายรุกพูด «บิโต» ไพ่ไปกองทิ้ง ไม่เช่นนั้นฝ่ายรับรับไพ่ทั้งหมดบนโต๊ะ';

  @override
  String get rulesDurakLoser => 'ผู้แพ้คือคนที่ยังมีไพ่ตอนจบ — «คนโง่»';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'ผู้เล่น $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'ล็อบบี้ $name';
  }

  @override
  String get lobbyMatchmake => 'ล็อบบี้';

  @override
  String get lobbyPrivateGame => 'เกมส่วนตัว';

  @override
  String get lobbySearchingOpponent => 'กำลังหาคู่แข่ง…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'กำลังหาแมตช์นี้: $count';
  }

  @override
  String get lobbyWaitingJoin => 'รอให้ใครสักคนแตะ “หาเกม” หรือ “เข้าร่วม”';

  @override
  String get lobbyInviteTitle => 'คำเชิญเล่นเกม';

  @override
  String get lobbyInvitedToPlay => 'คุณได้รับเชิญให้เล่น';

  @override
  String get lobbyEnterGame => 'เข้าเกม';

  @override
  String get lobbyGone => 'ล็อบบี้ใช้ไม่ได้อีกต่อไป';

  @override
  String get lobbyInvite => 'เชิญ';

  @override
  String get lobbyInviteSent => 'ส่งคำเชิญแล้ว';

  @override
  String get lobbyCopyLink => 'แชร์ลิงก์เกม';

  @override
  String get lobbyLinkCopied => 'คัดลอกลิงก์แล้ว';

  @override
  String get lobbyNoFriendsOnline => 'ไม่มีเพื่อนออนไลน์ แชร์ลิงก์ด้านบน หรือรอให้เพื่อนออนไลน์';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'คู่แข่ง';

  @override
  String get gameYou => 'คุณ';

  @override
  String get gameYouWon => 'คุณชนะ!';

  @override
  String get gameYouWonShort => 'คุณชนะ';

  @override
  String get gameYouLost => 'คุณแพ้';

  @override
  String get gameYouWonOpponentLeft => 'คุณชนะ — คู่แข่งออกไปแล้ว';

  @override
  String get gameYouWonOpponentTimeout => 'คุณชนะ — คู่แข่งหมดเวลา';

  @override
  String get gameDraw => 'เสมอ';

  @override
  String get gameExitTitle => 'ออกจากเกม';

  @override
  String get gameExitConfirm => 'หากออก คุณจะแพ้ ยังต้องการออกไหม?';

  @override
  String get gameStay => 'อยู่ต่อ';

  @override
  String get gameLeave => 'ออก';

  @override
  String get gameSurrender => 'ยอมแพ้';

  @override
  String get gameSurrenderTitle => 'ยอมแพ้?';

  @override
  String get gameSurrenderConfirm => 'คุณจะแพ้เกมและเหรียญเดิมพัน';

  @override
  String get gameOfferDraw => 'เสนอเสมอ';

  @override
  String get gameFlipBoard => 'พลิกกระดาน';

  @override
  String get gameReviewStart => 'ไปที่จุดเริ่มเกม';

  @override
  String get gameReviewPrev => 'ย้อนกลับหนึ่งตา';

  @override
  String get gameReviewNext => 'เดินหน้าหนึ่งตา';

  @override
  String get gameReviewEnd => 'ไปที่ตำแหน่งปัจจุบัน';

  @override
  String get gameOfferDrawTitle => 'เสนอเสมอ?';

  @override
  String get gameOfferDrawConfirm => 'คู่แข่งสามารถยอมรับหรือปฏิเสธการเสมอได้';

  @override
  String get gameAcceptDrawTitle => 'ยอมรับเสมอ?';

  @override
  String get gameAcceptDrawConfirm => 'เกมจะจบด้วยการเสมอ';

  @override
  String get gameDrawOffered => 'คู่แข่งเสนอเสมอ';

  @override
  String get gameConnecting => 'กำลังเชื่อมต่อเกม…';

  @override
  String get gameWaitingOpponent => 'รอคู่แข่ง';

  @override
  String get gameRematchOffer => 'คู่แข่งขอเล่นอีกครั้ง';

  @override
  String get gameRematchDeclined => 'คู่แข่งปฏิเสธการเล่นอีกครั้ง';

  @override
  String get gameRematch => 'เล่นอีกครั้ง';

  @override
  String get gameOtherOpponent => 'คู่แข่งอื่น';

  @override
  String get gameSwapSidesAction => 'สลับฝ่าย';

  @override
  String get gameWriteMessage => 'เขียนข้อความ';

  @override
  String get chatsTitle => 'แชท';

  @override
  String get chatsEmpty => 'ยังไม่มีแชท\nแตะไอคอนมุมขวาบนเพื่อเลือกเพื่อนและเริ่มสนทนา';

  @override
  String get chatsNewChat => 'แชทใหม่';

  @override
  String get chatsNoMessages => 'ไม่มีข้อความ';

  @override
  String get chatsClearTitle => 'ล้างบทสนทนา?';

  @override
  String get chatsClearDesc => 'แชทจะถูกลบถาวร';

  @override
  String get chatsClearConfirm => 'ล้าง';

  @override
  String get chatsBlockTitle => 'บล็อกผู้ใช้นี้?';

  @override
  String get chatsBlockDesc => 'คุณจะส่งข้อความถึงกันไม่ได้อีก แชทและมิตรภาพจะถูกลบ';

  @override
  String get chatsBlockConfirm => 'บล็อก';

  @override
  String get chatsBlockedUsers => 'ผู้ใช้ที่ถูกบล็อก';

  @override
  String get chatsUnblock => 'เลิกบล็อก';

  @override
  String get chatDialog => 'แชท';

  @override
  String get chatEmpty => 'ยังไม่มีข้อความ\nส่งข้อความแรกเลย';

  @override
  String get chatMessageHint => 'ข้อความ';

  @override
  String get chatPaste => 'วาง';

  @override
  String get chatEmoji => 'อีโมจิ';

  @override
  String get chatBuyEmojiHint => 'ซื้ออีโมจิในร้านค้าบนหน้าหลัก';

  @override
  String get chatEditing => 'กำลังแก้ไข';

  @override
  String get chatToday => 'วันนี้';

  @override
  String get chatYesterday => 'เมื่อวาน';

  @override
  String get chatFriendsOnly => 'ข้อความสำหรับเพื่อนเท่านั้น';

  @override
  String get emojiGroupEmotions => 'อารมณ์';

  @override
  String get emojiGroupGame => 'เกม';

  @override
  String get emojiGroupFlags => 'ธง';

  @override
  String get emojiGroupAnimals => 'สัตว์';

  @override
  String get emojiGroupFood => 'อาหาร';

  @override
  String get emojiGroupTravel => 'ท่องเที่ยว';

  @override
  String get emojiGroupParty => 'ฉลอง';

  @override
  String get emojiGroupObjects => 'สิ่งของ';

  @override
  String get friendsTitle => 'เพื่อน';

  @override
  String get friendsTabFriends => 'เพื่อน';

  @override
  String get friendsTabIncoming => 'ขาเข้า';

  @override
  String get friendsTabOutgoing => 'ขาออก';

  @override
  String get friendsAdd => 'เพิ่มเพื่อน';

  @override
  String get friendsRequestSent => 'ส่งคำขอแล้ว';

  @override
  String get friendsFindTab => 'หาเพื่อน';

  @override
  String get friendsSearchHint => 'ค้นหาด้วยชื่อผู้ใช้';

  @override
  String get friendsSearchPrompt => 'ใช้การค้นหาเพื่อหาเพื่อนใหม่';

  @override
  String get friendsNothingFound => 'ไม่พบผลลัพธ์';

  @override
  String get friendsEmpty => 'คุณยังไม่มีเพื่อน';

  @override
  String get friendsSearchNoMatches => 'ไม่มีเพื่อนที่ตรงกับการค้นหา';

  @override
  String get friendsIncomingSearchNoMatches => 'ไม่มีคำขอเข้าที่ตรงกับการค้นหา';

  @override
  String get friendsOutgoingSearchNoMatches => 'ไม่มีคำขอออกที่ตรงกับการค้นหา';

  @override
  String get friendsNoIncoming => 'ไม่มีคำขอเข้า';

  @override
  String get friendsNoOutgoing => 'ไม่มีคำขอออก';

  @override
  String get friendsAlreadyFriends => 'เป็นเพื่อนกันแล้ว';

  @override
  String get friendsRemoveTitle => 'ลบออกจากเพื่อน?';

  @override
  String get friendsRemoved => 'ลบออกจากเพื่อนแล้ว';

  @override
  String get friendsRequestAccepted => 'ยอมรับคำขอแล้ว';

  @override
  String get friendsRequestDeclined => 'ปฏิเสธคำขอแล้ว';

  @override
  String get friendsRequestCancelled => 'ยกเลิกคำขอแล้ว';

  @override
  String get profileTitle => 'โปรไฟล์';

  @override
  String get profileSignInPrompt => 'เข้าสู่ระบบบัญชีของคุณ';

  @override
  String get profileSignInHint => 'เพื่อตั้งค่าโปรไฟล์ส่วนตัว';

  @override
  String get profileEdit => 'แก้ไข';

  @override
  String get profileCollections => 'คอลเลกชัน';

  @override
  String get profileAge => 'อายุ';

  @override
  String get profileGender => 'เพศ';

  @override
  String get profileGenderUnset => 'ยังไม่ตั้งค่า';

  @override
  String get profileGenderMale => 'ชาย';

  @override
  String get profileGenderFemale => 'หญิง';

  @override
  String get profileAvatar => 'อวาตาร์';

  @override
  String get profileUploadPhoto => 'อัปโหลดรูป';

  @override
  String get profileChangePhoto => 'เปลี่ยนอวาตาร์';

  @override
  String get shopTitle => 'ร้านค้า';

  @override
  String get shopEmojis => 'อีโมจิ';

  @override
  String get shopEmojisSubtitle => 'อีโมจิเคลื่อนไหวสำหรับแชท';

  @override
  String get shopCollections => 'คอลเลกชัน';

  @override
  String get shopCollectionsSubtitle => 'โชว์โปรไฟล์ ของขวัญ และรายได้';

  @override
  String get shopStakes => 'เดิมพัน';

  @override
  String get shopStakesSubtitle => 'ปลดล็อกเดิมพันที่สูงขึ้น';

  @override
  String get shopEmojisHelp => 'อิโมจิเคลื่อนไหวสำหรับแชท ซื้อชุดแล้วส่งให้เพื่อนได้';

  @override
  String get shopCollectionsHelp => 'ขายได้เฉพาะคอลเลกชันใหม่หรือวินเทจ: ใหม่ขาย 80% ของราคา และวินเทจขาย 300% ของราคา ของเก่า ของเหนื่อย และของชำรุดขายไม่ได้\n\nสะสมชุดไอเท็ม: แสดงในตู้โปรไฟล์ ให้เป็นของขวัญได้ แต่ละชิ้นให้เหรียญทุกวัน และชุดที่ครบยังให้โบนัสแยกต่างหาก\n\nรายได้รายวันของไอเท็มขึ้นกับสภาพ และคิดจากจำนวนปกติ ใหม่ให้ 100% เก่าให้ 60% เหนื่อยให้ 40% ชำรุดให้ 100% ไอเท็มวินเทจให้ 200% คือสองเท่าของรายได้ปกติ\n\nโบนัสของชุดที่ครบไม่เปลี่ยน จนกว่าชุดนั้นจะเป็นวินเทจ ชุดเป็นวินเทจเมื่อทุกชิ้นในชุดเป็นวินเทจ: โบนัสจะเป็น 300% คือสามเท่าของปกติ\n\nสภาพขึ้นกับว่าคุณมีไอเท็มมานานแค่ไหน ใหม่ — 7 วันแรก เก่า — ตั้งแต่วันที่ 8 ถึง 2 เดือน เหนื่อย — 2 ถึง 6 เดือน ชำรุด — 6 เดือนถึง 1 ปี วินเทจ — ตั้งแต่ 1 ปี';

  @override
  String get shopStakesHelp => 'ปลดล็อกเดิมพันที่สูงขึ้น เดิมพันยิ่งสูง เงินกองกลางและรางวัลยิ่งใหญ่';

  @override
  String get inventoryTitle => 'ไอเท็ม';

  @override
  String get inventoryEmpty => 'ยังไม่มีอะไรที่นี่ — ไปดูที่ร้านค้า';

  @override
  String get inventoryFrames => 'กรอบ';

  @override
  String get inventoryClaim => 'รับ';

  @override
  String get inventorySell => 'ขาย';

  @override
  String get inventoryGift => 'มอบ';

  @override
  String get messageEdited => 'แก้ไขแล้ว';

  @override
  String get messageDeleted => 'ลบข้อความแล้ว';

  @override
  String get photo => 'รูปภาพ';

  @override
  String get camera => 'กล้อง';

  @override
  String get gallery => 'แกลเลอรี';

  @override
  String get connectionError => 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้';

  @override
  String get serverError => 'เซิร์ฟเวอร์ผิดพลาด โปรดลองใหม่ภายหลัง';

  @override
  String get sessionExpired => 'เซสชันหมดอายุ โปรดเข้าสู่ระบบอีกครั้ง';

  @override
  String get errNoInternet => 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';

  @override
  String get errTimeout => 'คำขอหมดเวลา โปรดลองอีกครั้ง';

  @override
  String get errGamesUnavailable => 'เกมไม่พร้อมใช้งานชั่วคราว';

  @override
  String get errSettingsSaveFailed => 'บันทึกการตั้งค่าไม่ได้';

  @override
  String get errPushPermission => 'อนุญาตการแจ้งเตือนในการตั้งค่าเบราว์เซอร์หรือระบบ';

  @override
  String get balanceTitle => 'ยอดคงเหลือ';

  @override
  String get coinBronze => 'บรอนซ์';

  @override
  String get coinSilver => 'เงิน';

  @override
  String get coinGold => 'ทอง';

  @override
  String get coinDiamond => 'เพชร';

  @override
  String get balanceZeroBronze => '0 บรอนซ์';

  @override
  String balanceBronzes(int count) {
    return '$count บรอนซ์';
  }

  @override
  String balanceSilvers(int count) {
    return '$count เงิน';
  }

  @override
  String balanceGolds(int count) {
    return '$count ทอง';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count เพชร';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/วัน';
  }

  @override
  String get balanceAbbrBronze => 'บร';

  @override
  String get balanceAbbrSilver => 'ง.';

  @override
  String get balanceAbbrGold => 'ท.';

  @override
  String get commonBackHome => 'กลับหน้าหลัก';

  @override
  String get commonCopied => 'คัดลอกแล้ว';

  @override
  String get commonClear => 'ล้าง';

  @override
  String get commonTryLater => 'โปรดลองอีกครั้งในภายหลัง';

  @override
  String get commonTryRefresh => 'ลองรีเฟรชหน้า';

  @override
  String get coinsTitle => 'เหรียญ';

  @override
  String get coinsLoginReward => 'รางวัลเข้าสู่ระบบ';

  @override
  String get coinsLoginAvailableToday => 'รางวัลวันนี้พร้อมรับ';

  @override
  String get coinsLoginStreak => 'เข้าสู่ระบบต่อเนื่องรายวัน';

  @override
  String get coinsFriendReward => 'รางวัลเพื่อน';

  @override
  String get coinsTasks => 'ภารกิจ';

  @override
  String get coinsTasksSubtitle => 'รางวัลสำหรับโปรไฟล์ เพื่อน และเกม';

  @override
  String get coinsTasksRewards => 'มีรางวัลพร้อมรับ';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount สำหรับการสมัครผ่านลิงก์ของคุณ';
  }

  @override
  String get coinsLoadRewardsFailed => 'โหลดรางวัลไม่สำเร็จ';

  @override
  String get coinsClaimReward => 'รับรางวัล';

  @override
  String get coinsAlreadyClaimed => 'รับแล้ว';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · วันนี้';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · เหลืออีก 1 วัน';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · เหลืออีก $remaining';
  }

  @override
  String get coinsInviteFriend => 'เชิญเพื่อน';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount สำหรับทุกคนที่สมัครผ่านลิงก์ของคุณ';
  }

  @override
  String get coinsCopyLink => 'คัดลอกลิงก์';

  @override
  String get coinsHowItWorks => 'วิธีใช้งาน';

  @override
  String get coinsHowStep1 => 'คัดลอกลิงก์แล้วส่งให้เพื่อน';

  @override
  String get coinsHowStep2 => 'เพื่อนสมัครผ่านลิงก์นั้น';

  @override
  String coinsHowStep3(String amount) {
    return 'คุณได้รับ $amount';
  }

  @override
  String get achievementsTitle => 'ความสำเร็จ';

  @override
  String achievementsProgress(String progress) {
    return 'ความคืบหน้า: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'ได้รับกรอบแล้ว';

  @override
  String get achievementsClaimed => 'ได้รับแล้ว';

  @override
  String get achievementsOpenFrame => 'เปิดกรอบ';

  @override
  String friendsRemoveConfirm(String name) {
    return 'แน่ใจหรือไม่ว่าต้องการลบ $name ออกจากเพื่อน?';
  }

  @override
  String get friendsRemoveConfirmAction => 'ลบ';

  @override
  String get friendsRemove => 'ลบออกจากเพื่อน';

  @override
  String get friendsAcceptRequest => 'ยอมรับคำขอ';

  @override
  String get friendsDeclineRequest => 'ปฏิเสธคำขอ';

  @override
  String get friendsCancelRequest => 'ยกเลิกคำขอ';

  @override
  String get friendsSendRequest => 'ส่งคำขอเป็นเพื่อน';

  @override
  String get friendsRequestAlreadySent => 'ส่งคำขอแล้ว';

  @override
  String get friendsIncomingStatus => 'คำขอขาเข้า';

  @override
  String get friendsOutgoingStatus => 'คำขอขาออก';

  @override
  String get friendsNotFriends => 'ยังไม่เป็นเพื่อน';

  @override
  String get friendsCollapseSearch => 'ยุบการค้นหา';

  @override
  String get friendsExpandSearch => 'แสดงการค้นหา';

  @override
  String get friendsLoadFailed => 'โหลดเพื่อนไม่สำเร็จ';

  @override
  String friendsSince(String date) {
    return 'เป็นเพื่อนตั้งแต่: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'คำขอขาเข้า: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'คำขอขาออก: $date';
  }

  @override
  String get userInfoTitle => 'ข้อมูลผู้ใช้';

  @override
  String profileAgeYears(int age) {
    return '$age ปี';
  }

  @override
  String get shopBuy => 'ซื้อ';

  @override
  String get shopBuyTitle => 'ซื้อ?';

  @override
  String get shopBuyStakeTitle => 'ซื้อเดิมพัน?';

  @override
  String get shopBuyEmojiTitle => 'ซื้ออีโมจิ?';

  @override
  String get shopBuyCollectionTitle => 'ซื้อคอลเลกชัน?';

  @override
  String shopPrice(String price) {
    return 'ราคา: $price';
  }

  @override
  String get shopOwned => 'ซื้อแล้ว';

  @override
  String get shopHave => 'มีแล้ว';

  @override
  String get shopEmpty => 'ยังว่างอยู่';

  @override
  String shopPurchased(String title) {
    return 'ซื้อ $title แล้ว';
  }

  @override
  String get shopEmojiUses => 'คุณได้รับ: 10 ครั้ง';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 ครั้ง';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 ครั้ง';
  }

  @override
  String get shopBuyTen => 'ซื้อ · 10 ชิ้น';

  @override
  String shopDailyIncome(String amount) {
    return 'รายได้: $amount';
  }

  @override
  String get shopBuyOnce => 'ซื้อครั้งเดียว';

  @override
  String get shopSellRefund => 'การขายขึ้นกับสภาพคอลเลกชัน';

  @override
  String get collectionConditionNew => 'ใหม่';

  @override
  String get collectionConditionWorn => 'เก่า';

  @override
  String get collectionConditionTired => 'เหนื่อย';

  @override
  String get collectionConditionShabby => 'ชำรุด';

  @override
  String get collectionConditionVintage => 'วินเทจ';

  @override
  String shopCollectionAdded(String title) {
    return 'เพิ่ม $title ในโปรไฟล์แล้ว';
  }

  @override
  String shopSetBonus(int percent) {
    return 'โบนัสชุด +$percent%';
  }

  @override
  String get shopSetComplete => 'ครบแล้ว';

  @override
  String shopSetProgress(int owned, int total) {
    return 'เก็บแล้ว · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'ขาย?';

  @override
  String inventorySellDesc(String amount) {
    return 'คุณจะได้รับ $amount';
  }

  @override
  String get inventoryCollectionNotSellable => 'ขายได้เฉพาะคอลเลกชันใหม่หรือวินเทจ';

  @override
  String get inventoryCollectionNotSellableTitle => 'ขายไม่ได้';

  @override
  String get inventoryCollectionNotSellableHint => 'ขายได้เฉพาะของใหม่หรือวินเทจ ใช้ elixir เพื่อเปลี่ยนสภาพ';

  @override
  String inventorySold(String amount) {
    return 'ขายแล้ว: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'เพิ่มเพื่อนก่อน';

  @override
  String get inventoryGiftTitle => 'มอบคอลเลกชัน?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'มอบ «$title» ให้ $name?';
  }

  @override
  String inventoryGifted(String title) {
    return 'มอบแล้ว: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'ผู้เล่นมีไอเท็มนี้อยู่แล้ว';

  @override
  String get inventoryGiftSelf => 'คุณไม่สามารถมอบของขวัญให้ตัวเองได้';

  @override
  String get inventoryGiftNotOwned => 'ไอเท็มนี้ไม่มีในคลังของคุณ';

  @override
  String get inventoryLoadFailed => 'โหลดไอเท็มไม่สำเร็จ';

  @override
  String get inventoryNoCollections => 'ไม่มีคอลเลกชัน — ซื้อในร้านค้า';

  @override
  String get inventoryNoEmojis => 'ไม่มีอีโมจิ — ซื้อในร้านค้า';

  @override
  String get inventoryNoFrames => 'ไม่มีกรอบ — ชนะ 10 เกมลีก (ความสำเร็จ)';

  @override
  String get inventoryNoStakes => 'ไม่มีเดิมพันที่ซื้อ';

  @override
  String inventoryEmojiLeft(int count) {
    return 'เหลือ $count';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'รายได้: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'รายได้พรุ่งนี้: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'พร้อม';

  @override
  String get inventoryIncomeTomorrowLabel => 'พรุ่งนี้';

  @override
  String inventoryStakeGold(String amount) {
    return 'สามารถเดิมพันทอง $amount';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'สามารถเดิมพันเงิน $amount';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'ได้รับ +$amount';
  }

  @override
  String get chatsLoadFailed => 'โหลดแชทไม่สำเร็จ';

  @override
  String get chatsLoadListFailed => 'โหลดรายการไม่สำเร็จ';

  @override
  String get chatsBlockedEmpty => 'รายการว่างเปล่า';

  @override
  String chatsBlockedAt(String date) {
    return 'บล็อกเมื่อ: $date';
  }

  @override
  String get chatsCreateFailed => 'สร้างแชทไม่สำเร็จ';

  @override
  String get chatsNeedFriendsFirst => 'เพิ่มเพื่อนก่อน แล้วจึงเปิดแชทได้';

  @override
  String get chatsFriendsNotFound => 'ไม่พบเพื่อน';

  @override
  String get chatsFindFriendHint => 'ค้นหาเพื่อนด้วยชื่อเล่น';

  @override
  String get chatsSelectChat => 'เลือกแชท';

  @override
  String get chatsSelectHint => 'เลือกบทสนทนาจากรายการด้านซ้าย';

  @override
  String get chatEditFailed => 'แก้ไขข้อความไม่สำเร็จ';

  @override
  String get chatSendFailed => 'ส่งข้อความไม่สำเร็จ';

  @override
  String get chatDeleteFailed => 'ลบข้อความไม่สำเร็จ';

  @override
  String get chatEmojiSendFailed => 'ส่งอีโมจิไม่สำเร็จ';

  @override
  String get chatLoadFailed => 'โหลดข้อความไม่สำเร็จ';

  @override
  String get chatBackToGame => 'กลับไปเกม';

  @override
  String get chatBackToChats => 'กลับไปแชท';

  @override
  String get chatActions => 'การดำเนินการแชท';

  @override
  String get chatAutoTranslate => 'Auto-translate';

  @override
  String get chatScrollToEnd => 'ไปท้ายบทสนทนา';

  @override
  String chatReplyingTo(String name) {
    return 'ตอบกลับ $name';
  }

  @override
  String get chatGift => 'ของขวัญ';

  @override
  String get chatCollection => 'คอลเลกชัน';

  @override
  String get chatGiftCollection => 'ของขวัญ · คอลเลกชัน';

  @override
  String get chatThisUser => 'ผู้ใช้นี้';

  @override
  String get gamesLobbyLoadFailed => 'โหลดล็อบบี้ไม่สำเร็จ';

  @override
  String get gamesTapChangeStake => 'แตะเพื่อเปลี่ยนเดิมพัน';

  @override
  String get gamesTapChangeTurnTime => 'แตะเพื่อเปลี่ยนเวลาก่อนเดิน';

  @override
  String get gamesTapChangeGrid => 'แตะเพื่อเปลี่ยนขนาดตาราง';

  @override
  String get gamesSwapSidesHint => 'O อาจกลายเป็น X หลังตาแรก';

  @override
  String get gamesNoCenterHint => 'ตาแรกห้ามลงกลาง';

  @override
  String get lobbyInviteSentShort => 'ส่งแล้ว';

  @override
  String get lobbySearchShort => 'ค้นหา';

  @override
  String get lobbySearchPlayers => 'ค้นหาผู้เล่น';

  @override
  String get lobbyInviteDeclinedShort => 'ปฏิเสธ';

  @override
  String get lobbyInvitesSentWaiting => 'ส่งคำเชิญแล้ว รอการตอบกลับ';

  @override
  String get lobbyLinkCopiedHint => 'วางในแชทหรือข้อความถึงเพื่อน';

  @override
  String get lobbyCopyLinkHint => 'คัดลอกลิงก์ไปยังคลิปบอร์ด';

  @override
  String lobbyCreatorInvites(String name, String game) {
    return '$name เชิญคุณมาเล่น $game';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name ชนะ';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'หมดเวลา $name ชนะ';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds วิ';
  }

  @override
  String get adminTitle => 'แอดมิน';

  @override
  String get tournamentsTitle => 'ทัวร์นาเมนต์';

  @override
  String get profileAgeInvalid => 'กรอกอายุระหว่าง 1 ถึง 111';

  @override
  String get profileSaveFailed => 'บันทึกโปรไฟล์ไม่สำเร็จ';

  @override
  String get profileNameHint => 'ตัวอักษรละติน ตัวเลข _ ไม่เกิน 10 ตัว';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'ตั้งแต่ 1 ถึง 111';

  @override
  String get profileAboutHint => 'ไม่เกิน 100 ตัวอักษร (ไม่บังคับ)';

  @override
  String get profileProcessingPhoto => 'กำลังประมวลผลรูป…';

  @override
  String get profileCropTitle => 'เลือกพื้นที่อวาตาร์';

  @override
  String get profileCropHint => 'ซูมและเลื่อนรูป';

  @override
  String get profileApply => 'ใช้';

  @override
  String get profilePreparing => 'กำลังเตรียม…';

  @override
  String get profileGalleryTitle => 'รูปภาพ';

  @override
  String get profileGalleryAdd => 'เพิ่มรูป';

  @override
  String get profileMakePrimary => 'ตั้งเป็นรูปหลัก';

  @override
  String get profilePhotoDelete => 'ลบรูป';

  @override
  String get profilePhotosLimit => 'อัปโหลดได้สูงสุด 3 รูป';

  @override
  String get profilePhotosEmpty => 'ยังไม่มีรูป';

  @override
  String get profilePhotoUploadFailed => 'อัปโหลดรูปไม่สำเร็จ';

  @override
  String get profilePhotoDeleteFailed => 'ลบรูปไม่สำเร็จ';

  @override
  String get profilePhotoTooLarge => 'รูปใหญ่เกินไป';

  @override
  String get profileSetPrimaryFailed => 'ตั้งเป็นรูปหลักไม่สำเร็จ';

  @override
  String timeSecondsShort(int seconds) {
    return '$seconds วิ';
  }

  @override
  String get timeOneMin => '1 นาที';

  @override
  String get timeTenMin => '10 นาที';

  @override
  String rulesIntro(String grid) {
    return 'XO บนกระดาน $grid สลับกันเดิน X เริ่มก่อน';
  }

  @override
  String rulesWin(int n) {
    return 'ชนะ: เรียง $n แนวตั้ง แนวนอน หรือแนวทแยง';
  }

  @override
  String get rulesNoTimeLimit => 'ไม่จำกัดเวลาต่อตา';

  @override
  String rulesTurnTime(String time) {
    return 'เวลาต่อตา: $time หมดเวลาถือว่าแพ้';
  }

  @override
  String rulesStake(String stake) {
    return 'เดิมพัน: $stake เกมนี้เล่นด้วยเหรียญจำนวนนี้';
  }

  @override
  String get rulesSwap => 'สลับฝ่าย: O สลับกับ X ได้หลังตาแรกของ X';

  @override
  String get rulesNoCenter => 'ห้ามกลาง: X ห้ามลงกลางในตาแรก';

  @override
  String get collectionSetLegends => 'ตำนาน';

  @override
  String get collectionSetSpace => 'อวกาศ';

  @override
  String get collectionSetGems => 'อัญมณี';

  @override
  String get collectionSetParty => 'ปาร์ตี้';

  @override
  String get collectionSetNature => 'ธรรมชาติ';

  @override
  String get collectionSetAdventures => 'ผจญภัย';

  @override
  String collectionCardMeta(String amount) {
    return 'คอลเลกชัน · โชว์เคส · ของขวัญ · ขาย · +$amount';
  }

  @override
  String get coinsDayOne => 'วัน';

  @override
  String get coinsDayFew => 'วัน';

  @override
  String get coinsDayMany => 'วัน';

  @override
  String get giftFriendTitle => 'มอบให้เพื่อน';

  @override
  String photoCount(int count) {
    return 'รูป ($count)';
  }

  @override
  String photoCountWithText(int count, String text) {
    return 'รูป ($count): $text';
  }

  @override
  String photoWithText(String text) {
    return 'รูป: $text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count อีโมจิ · $price';
  }

  @override
  String get chatsExpandPanel => 'ขยายแผง';

  @override
  String get chatsCollapsePanel => 'ย่อแผง';

  @override
  String get chatReplySourceMissing => 'ไม่พบข้อความต้นฉบับ';

  @override
  String shopStakeTitleSilver(int n) {
    return 'เดิมพัน $n เงิน';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'เดิมพัน $n ทอง';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'ปลดล็อกเดิมพัน $n เงิน';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'ปลดล็อกเดิมพัน $n ทอง';
  }

  @override
  String get chatReplySelf => 'ตัวคุณ';

  @override
  String get chatReplyPeer => 'อีกฝ่าย';

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
  String get statsTitle => 'สถิติ';

  @override
  String get statsLoadFailed => 'โหลดสถิติไม่สำเร็จ';

  @override
  String get statsAllGames => 'เกมทั้งหมด';

  @override
  String get statsEmptyTitle => 'ยังไม่มีเกมที่เล่น';

  @override
  String get statsEmptyHint => 'เล่นเกมแรกเพื่อดูสถิติที่นี่';

  @override
  String get statsWins => 'ชนะ';

  @override
  String get statsDraws => 'เสมอ';

  @override
  String get statsLosses => 'แพ้';

  @override
  String get statsWinRate => 'อัตราชนะ';

  @override
  String get statsTopWon => 'ชนะมากที่สุดกับ';

  @override
  String get statsTopDrawn => 'เสมอมากที่สุดกับ';

  @override
  String get statsTopLost => 'แพ้มากที่สุดกับ';

  @override
  String get statsTimePlayed => 'เวลาที่เล่น';

  @override
  String get statsYourScore => 'สกอร์ของคุณ';

  @override
  String get profileShowStats => 'แสดงสถิติ';

  @override
  String get statsDurationZeroMinutes => '0 นาที';

  @override
  String get gameYouWonOpponentForfeit => 'คู่แข่งยอมแพ้ คุณชนะ!';

  @override
  String get lobbyLeaveTitle => 'ออกจากล็อบบี้?';

  @override
  String get lobbyLeaveConfirm => 'ล็อบบี้จะถูกลบหลังออก เพื่อนที่ถูกเชิญจะได้รับการปฏิเสธ';

  @override
  String get lobbyLeave => 'ออก';

  @override
  String statsDurationHours(int hours) {
    return '$hours ชม.';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours ชม. $minutes นาที';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes นาที';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'คุณยอมแพ้ $name ชนะ';
  }

  @override
  String get supportTitle => 'ฝ่ายสนับสนุน';

  @override
  String get supportUnavailable => 'ฝ่ายสนับสนุนไม่พร้อมใช้งาน';

  @override
  String get supportOpenFailed => 'ไม่สามารถเปิดแชทฝ่ายสนับสนุนได้';

  @override
  String coinsGrantedTitle(int amount) {
    return 'คุณได้รับ $amount เหรียญ';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return 'หัก $amount เหรียญแล้ว';
  }

  @override
  String get coinsCreditCardTitle => 'คุณได้รับเหรียญ';

  @override
  String get coinsClaim => 'รับ';

  @override
  String get durakActionPass => 'ผ่าน';

  @override
  String get durakRoleTook => 'รับไป';

  @override
  String get durakRoleBeats => 'ป้องกัน';

  @override
  String get durakRoleThrowIn => 'ทิ้งเพิ่ม';

  @override
  String get durakRoleTurn => 'ตา';

  @override
  String get durakRoleDefends => 'กำลังป้องกัน';

  @override
  String get durakStatusTaking => 'กำลังรับ';

  @override
  String get durakHintDefenderTurn => 'ตาของผู้ป้องกัน';

  @override
  String get gameYouEliminated => 'คุณตกรอบแล้ว';

  @override
  String gameYouPlaced(int place) {
    return 'คุณได้อันดับ $place';
  }

  @override
  String get gameOverNeutral => 'จบเกมแล้ว';

  @override
  String gameTurnOf(String name) {
    return 'ตาของ $name';
  }

  @override
  String get chatGroupTooltip => 'แชทกลุ่ม';

  @override
  String get lobbyChatNotReady => 'แชทล็อบบี้ยังไม่พร้อม';

  @override
  String get chatsGroupChat => 'แชทกลุ่ม';

  @override
  String chatsMembersCount(int count) {
    return 'สมาชิก: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count คน';
  }

  @override
  String get chatsYouSuffix => '(คุณ)';

  @override
  String get chatTitleDurak3 => 'ดูรัก · 3 คน';

  @override
  String get chatTitleDurak4 => 'ดูรัก · 4 คน';

  @override
  String get rulesTttUltimate => 'อัลติเมต: มินิบอร์ด 3×3 จำนวนเก้าบอร์ด ตาเดินส่งคู่แข่งไปบอร์ดนั้น ชนะด้วยเส้นบนเมตาบอร์ด';

  @override
  String get rulesTttMulti3 => '3 คน: กระดาน 3×3 ผู้เล่นสามคน (X, O, △) ชนะด้วยเส้นจากสัญลักษณ์ของคุณ';

  @override
  String get rulesTttMulti4 => '4 คน: กระดาน 4×4 ผู้เล่นสี่คน (X, O, △, □) ชนะด้วยเส้นจากสัญลักษณ์ของคุณ';

  @override
  String get adminUsersTab => 'ผู้ใช้';

  @override
  String get adminSupportTab => 'ซัพพอร์ต';

  @override
  String get adminSearchHint => 'ค้นหาด้วยอีเมลหรือชื่อ';

  @override
  String get adminRoleAdmins => 'แอดมิน';

  @override
  String get adminRoleUsers => 'ผู้ใช้';

  @override
  String get adminRoleAll => 'ทุกบทบาท';

  @override
  String get adminStatusFrozen => 'ถูกระงับ';

  @override
  String get adminStatusActive => 'ใช้งานอยู่';

  @override
  String get adminStatusAny => 'ทุกสถานะ';

  @override
  String get adminOrderDesc => 'มากไปน้อย';

  @override
  String get adminOrderAsc => 'น้อยไปมาก';

  @override
  String adminLoadFailed(String error) {
    return 'โหลดไม่สำเร็จ: $error';
  }

  @override
  String get adminUsersEmpty => 'ไม่พบผู้ใช้';

  @override
  String get adminSortLastSeen => 'ตามการเข้าล่าสุด';

  @override
  String get adminSortEmail => 'ตามอีเมล';

  @override
  String get adminSortCreated => 'ตามวันสมัคร';

  @override
  String adminBronzeBalance(int amount) {
    return '$amount ทองแดง';
  }

  @override
  String get adminRevokeAdmin => 'ถอดแอดมิน';

  @override
  String get adminGrantAdmin => 'ตั้งเป็นแอดมิน';

  @override
  String get adminAdminRevoked => 'ถอดสิทธิ์แอดมินแล้ว';

  @override
  String get adminAdminGranted => 'ให้สิทธิ์แอดมินแล้ว';

  @override
  String get adminGrantCoins => 'ให้เหรียญ';

  @override
  String get adminWriteSupport => 'เขียนในฐานะซัพพอร์ต';

  @override
  String get adminUnfreeze => 'ปลดระงับ';

  @override
  String get adminFreeze => 'ระงับ';

  @override
  String get adminUnfrozen => 'ปลดระงับแล้ว';

  @override
  String get adminFrozenDone => 'ระงับแล้ว';

  @override
  String get adminResetPassword => 'รีเซ็ตรหัสผ่าน';

  @override
  String get adminCoinsAmountHint => 'จำนวน (ค่าลบ = หัก)';

  @override
  String get adminReasonOptional => 'เหตุผล (ไม่บังคับ)';

  @override
  String get adminGrantSent => 'ส่งการ์ดไปแชทซัพพอร์ตแล้ว';

  @override
  String adminCoinsDebited(int amount) {
    return 'หักทองแดง $amount';
  }

  @override
  String get adminGrantVerb => 'ให้';

  @override
  String get adminNewPasswordHint => 'รหัสผ่านใหม่ (อย่างน้อย 6)';

  @override
  String get adminPasswordReset => 'รีเซ็ตรหัสผ่านแล้ว';

  @override
  String get adminResetVerb => 'รีเซ็ต';

  @override
  String adminShortError(String error) {
    return 'ข้อผิดพลาด: $error';
  }

  @override
  String get adminSupportEmpty => 'ไม่มีคำขอซัพพอร์ต';

  @override
  String get adminUserFallback => 'ผู้ใช้';

  @override
  String get apiErrTooManyRequests => 'มีคำขอมากเกินไป ลองใหม่ภายหลัง';

  @override
  String get apiErrMoveConflict => 'การเดินชนกัน ลองอีกครั้ง';

  @override
  String get shopElixirs => 'Elixirs';

  @override
  String get shopElixirsSubtitle => 'Rejuvenate, age, or speed up collections';

  @override
  String get shopElixirsHelp => 'Three shelves: rejuvenation, aging, and acceleration. Each has six elixirs, one per collection set. An elixir works only on its own set.\n\nRejuvenation makes a collection one step newer, and never newer than new. Aging makes it one step older, and never older than shabby. Acceleration is only for a shabby item: three months left until vintage, once. An elixir never grants vintage by itself.\n\nA bought elixir stays in Items. Use it from the collection card or from the elixir card. Each use spends one.';

  @override
  String get elixirGroupRejuvenate => 'ฟื้นวัย';

  @override
  String get elixirGroupAge => 'ชรา';

  @override
  String get elixirGroupAccelerate => 'เร่ง';

  @override
  String get elixirEffectRejuvenate => 'ฟื้นวัย';

  @override
  String get elixirEffectAge => 'ชรา';

  @override
  String get elixirEffectAccelerate => 'เร่ง';

  @override
  String get elixirAdjCelebration => 'เทศกาล';

  @override
  String get elixirAdjNature => 'ธรรมชาติ';

  @override
  String get elixirAdjLegends => 'ตำนาน';

  @override
  String get elixirAdjCosmic => 'อวกาศ';

  @override
  String get elixirAdjAdventure => 'ผจญภัย';

  @override
  String get elixirAdjJewels => 'อัญมณี';

  @override
  String elixirName(String adjective, String effect) {
    return 'ยา$effect$adjective';
  }

  @override
  String get elixirHelpRejuvenate => 'Makes the collection one step newer. Not newer than new.';

  @override
  String get elixirHelpAge => 'Makes the collection one step older. Not older than shabby.';

  @override
  String get elixirHelpAccelerate => 'Shabby only. Three months left until vintage, once.';

  @override
  String get elixirUseRejuvenate => 'ฟื้นวัย';

  @override
  String get elixirUseAge => 'ทำให้ชรา';

  @override
  String get elixirUseAccelerate => 'เร่ง';

  @override
  String get elixirUse => 'ใช้';

  @override
  String collectionLeftDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count วัน',
      one: '$count วัน',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ชม.',
      one: '$count ชม.',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count นาที',
      one: '$count นาที',
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
  String get statsRecentTitle => 'เกมล่าสุด';

  @override
  String get statsOutcomeWin => 'ชนะ';

  @override
  String get statsOutcomeLoss => 'แพ้';

  @override
  String get statsOutcomeDraw => 'เสมอ';

  @override
  String get statsAllModes => 'ทุกโหมด';

  @override
  String statsDurakChip(int players, String deck) {
    return '$players · $deck';
  }

  @override
  String get statsSelectGame => 'เกม';

  @override
  String get statsSelectMode => 'โหมด';

  @override
  String get statsRecentEmpty => 'ยังไม่มีเกม';
}
