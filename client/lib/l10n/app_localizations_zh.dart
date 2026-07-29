import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => '首页';

  @override
  String get navProfile => '个人资料';

  @override
  String get navFriends => '好友';

  @override
  String get navChats => '聊天';

  @override
  String get navGames => '游戏';

  @override
  String get navSettings => '设置';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsAddBotsTitle => '30 秒后加入机器人';

  @override
  String get settingsAddBotsSubtitle => '匹配中：若 30 秒内未找到对手，将与机器人开始对局（赌注重置为 1 青铜）';

  @override
  String get settingsFriendsOnlyTitle => '仅接收好友消息';

  @override
  String get settingsFriendsOnlySubtitle => '非好友只能发送表情。如遇骚扰，可暂时屏蔽该用户。';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsPushChat => '聊天';

  @override
  String get settingsPushFriends => '好友';

  @override
  String get settingsPushGames => '游戏';

  @override
  String get settingsPushRewards => '奖励';

  @override
  String get loginTitle => '登录';

  @override
  String get loginSubtitle => '输入邮箱或用户名和密码';

  @override
  String get loginEmailLabel => '邮箱或用户名';

  @override
  String get loginPasswordLabel => '密码';

  @override
  String get loginSubmit => '登录';

  @override
  String get loginNoAccount => '没有账号？注册';

  @override
  String get loginEmailRequired => '请输入邮箱或用户名';

  @override
  String get loginPasswordRequired => '请输入密码';

  @override
  String get loginTooltip => '登录';

  @override
  String get logoutTooltip => '退出登录';

  @override
  String get registerTitle => '注册';

  @override
  String get registerSubtitle => '创建账号开始游戏';

  @override
  String get registerNameLabel => '名称（用户名）';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => '密码';

  @override
  String get registerSubmit => '注册';

  @override
  String get registerHaveAccount => '已有账号？登录';

  @override
  String get registerNameRequired => '请输入名称';

  @override
  String get registerNameNoSpaces => '名称不能包含空格';

  @override
  String get registerNameMax => '最多 20 个字符';

  @override
  String get registerNameHint => '最多 20 个字符';

  @override
  String get registerEmailRequired => '请输入邮箱';

  @override
  String get registerEmailInvalid => '邮箱格式无效';

  @override
  String get registerPasswordHint => '至少 6 个字符';

  @override
  String get registerPasswordMin => '密码至少需要 6 个字符';

  @override
  String get commonCancel => '取消';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '删除';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonReply => '回复';

  @override
  String get commonSend => '发送';

  @override
  String get commonClose => '关闭';

  @override
  String get commonRetry => '重试';

  @override
  String get commonLoading => '加载中…';

  @override
  String get commonError => '错误';

  @override
  String get commonOnline => '在线';

  @override
  String get commonOffline => '离线';

  @override
  String get commonOnlineCap => '在线';

  @override
  String get commonUser => '用户';

  @override
  String get commonPlayer => '玩家';

  @override
  String get commonAboutMe => '关于我';

  @override
  String get commonBack => '返回';

  @override
  String get commonAccept => '接受';

  @override
  String get commonDecline => '拒绝';

  @override
  String get commonCreating => '创建中…';

  @override
  String get commonSearching => '搜索中…';

  @override
  String get commonInsufficientCoins => '金币不足';

  @override
  String get commonNotFound => '未找到';

  @override
  String get commonServerErrorShort => '服务器错误';

  @override
  String get commonForbidden => '无权访问';

  @override
  String get commonUserBlocked => '用户已被屏蔽';

  @override
  String get commonUserNotFound => '未找到用户';

  @override
  String get commonGenericError => '出了点问题，请重试。';

  @override
  String get timeJustNow => '刚刚';

  @override
  String get timeYesterday => '昨天';

  @override
  String timeMinutesAgo(Object count) {
    return '$count 分钟前';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count 小时前';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count 天前';
  }

  @override
  String get timeWeekAgo => '一周前';

  @override
  String timeWeeksAgo(Object count) {
    return '$count 周前';
  }

  @override
  String get timeMonthAgo => '一个月前';

  @override
  String timeMonthsAgo(Object count) {
    return '$count 个月前';
  }

  @override
  String get timeYearAgo => '一年前';

  @override
  String timeYearsAgo(Object count) {
    return '$count 年前';
  }

  @override
  String get weekdaySun => '日';

  @override
  String get weekdayMon => '一';

  @override
  String get weekdayTue => '二';

  @override
  String get weekdayWed => '三';

  @override
  String get weekdayThu => '四';

  @override
  String get weekdayFri => '五';

  @override
  String get weekdaySat => '六';

  @override
  String get monthJan => '1月';

  @override
  String get monthFeb => '2月';

  @override
  String get monthMar => '3月';

  @override
  String get monthApr => '4月';

  @override
  String get monthMay => '5月';

  @override
  String get monthJun => '6月';

  @override
  String get monthJul => '7月';

  @override
  String get monthAug => '8月';

  @override
  String get monthSep => '9月';

  @override
  String get monthOct => '10月';

  @override
  String get monthNov => '11月';

  @override
  String get monthDec => '12月';

  @override
  String get homeAchievements => '成就';

  @override
  String get homeAchievementsSubtitle => '你的游戏战绩';

  @override
  String get homeAchievementsRewards => '有可领取的奖励';

  @override
  String get homeCoins => '金币';

  @override
  String get homeCoinsSubtitle => '余额与奖励';

  @override
  String get homeCoinsDailyReward => '可领取每日登录奖励';

  @override
  String get homeItems => '物品';

  @override
  String get homeItemsInventory => '你的背包';

  @override
  String get homeItemsGifted => '有人赠送了你一套收藏';

  @override
  String get homeItemsIncome => '收藏收益可领取';

  @override
  String get homeShop => '商店';

  @override
  String get homeShopSubtitle => '表情、赌注、收藏';

  @override
  String get gamesTitle => '游戏';

  @override
  String get gamesFindMatch => '寻找对局';

  @override
  String get gamesMyTurn => '轮到你了';

  @override
  String get gamesWaiting => '等待中';

  @override
  String get gamesLobbyTab => '大厅';

  @override
  String get gamesTicTacToe => '井字棋';

  @override
  String get gamesRules => '规则';

  @override
  String get gamesRulesTitle => '游戏规则';

  @override
  String get gamesCreate => '创建对局';

  @override
  String get gamesJoin => '加入';

  @override
  String get gamesOpponentTurn => '对手回合';

  @override
  String get gamesCurrentGame => '当前对局';

  @override
  String get gamesInvitedYou => '你收到了邀请';

  @override
  String get gamesTurnTime => '回合时限';

  @override
  String get gamesGridSize => '棋盘大小';

  @override
  String get gamesSwapSides => '交换阵营';

  @override
  String get gamesNoCenter => '禁止中心开局';

  @override
  String get lobbyMatchmake => '大厅';

  @override
  String get lobbyPrivateGame => '私人对局';

  @override
  String get lobbySearchingOpponent => '正在寻找对手…';

  @override
  String get lobbyWaitingJoin => '等待他人点击“寻找对局”或“加入”';

  @override
  String get lobbyInviteTitle => '对局邀请';

  @override
  String get lobbyInvitedToPlay => '你被邀请参加对局';

  @override
  String get lobbyEnterGame => '进入对局';

  @override
  String get lobbyInvite => '邀请';

  @override
  String get lobbyInviteSent => '邀请已发送';

  @override
  String get lobbyCopyLink => '分享对局链接';

  @override
  String get lobbyLinkCopied => '链接已复制';

  @override
  String get lobbyNoFriendsOnline => '暂无好友在线。可分享上方对局链接，或等待好友上线。';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => '对手';

  @override
  String get gameYouWon => '你赢了！';

  @override
  String get gameYouWonOpponentLeft => '你赢了 — 对手已离开';

  @override
  String get gameYouWonOpponentTimeout => '你赢了 — 对手超时';

  @override
  String get gameDraw => '平局';

  @override
  String get gameExitTitle => '离开对局';

  @override
  String get gameExitConfirm => '离开将判定为失败。确定离开吗？';

  @override
  String get gameStay => '留下';

  @override
  String get gameLeave => '离开';

  @override
  String get gameConnecting => '正在连接对局…';

  @override
  String get gameWaitingOpponent => '等待对手';

  @override
  String get gameRematchOffer => '对手请求再来一局';

  @override
  String get gameRematchDeclined => '对手拒绝了再战';

  @override
  String get gameRematch => '再来一局';

  @override
  String get gameOtherOpponent => '换对手';

  @override
  String get gameSwapSidesAction => '交换阵营';

  @override
  String get gameWriteMessage => '写一条消息';

  @override
  String get chatsTitle => '聊天';

  @override
  String get chatsEmpty => '暂无聊天。\n点击右上角图标选择好友开始对话。';

  @override
  String get chatsNewChat => '新聊天';

  @override
  String get chatsNoMessages => '暂无消息';

  @override
  String get chatsClearTitle => '清空对话？';

  @override
  String get chatsClearDesc => '聊天将永久删除。';

  @override
  String get chatsClearConfirm => '清空';

  @override
  String get chatsBlockTitle => '屏蔽此用户？';

  @override
  String get chatsBlockDesc => '之后将无法互相发消息。聊天和好友关系将被移除。';

  @override
  String get chatsBlockConfirm => '屏蔽';

  @override
  String get chatsBlockedUsers => '已屏蔽用户';

  @override
  String get chatsUnblock => '取消屏蔽';

  @override
  String get chatDialog => '聊天';

  @override
  String get chatEmpty => '暂无消息。\n发送第一条吧。';

  @override
  String get chatMessageHint => '消息';

  @override
  String get chatEmoji => '表情';

  @override
  String get chatBuyEmojiHint => '可在首页商店购买表情';

  @override
  String get chatEditing => '编辑中';

  @override
  String get chatToday => '今天';

  @override
  String get chatYesterday => '昨天';

  @override
  String get chatFriendsOnly => '仅好友可发文字';

  @override
  String get emojiGroupEmotions => '表情';

  @override
  String get emojiGroupGame => '游戏';

  @override
  String get emojiGroupFlags => '旗帜';

  @override
  String get emojiGroupAnimals => '动物';

  @override
  String get emojiGroupFood => '食物';

  @override
  String get emojiGroupTravel => '旅行';

  @override
  String get emojiGroupParty => '庆祝';

  @override
  String get emojiGroupObjects => '物品';

  @override
  String get friendsTitle => '好友';

  @override
  String get friendsTabFriends => '好友';

  @override
  String get friendsTabIncoming => '收到的';

  @override
  String get friendsTabOutgoing => '发出的';

  @override
  String get friendsAdd => '添加好友';

  @override
  String get friendsRequestSent => '请求已发送';

  @override
  String get friendsFindTab => '查找好友';

  @override
  String get friendsSearchHint => '按用户名搜索';

  @override
  String get friendsSearchPrompt => '使用搜索寻找新好友';

  @override
  String get friendsNothingFound => '未找到结果';

  @override
  String get friendsEmpty => '你还没有好友';

  @override
  String get friendsNoIncoming => '暂无收到的请求';

  @override
  String get friendsNoOutgoing => '暂无发出的请求';

  @override
  String get friendsAlreadyFriends => '已是好友';

  @override
  String get friendsRemoveTitle => '从好友中移除？';

  @override
  String get friendsRemoved => '已从好友中移除';

  @override
  String get friendsRequestAccepted => '已接受请求';

  @override
  String get friendsRequestDeclined => '已拒绝请求';

  @override
  String get friendsRequestCancelled => '已取消请求';

  @override
  String get profileTitle => '个人资料';

  @override
  String get profileSignInPrompt => '登录你的账号';

  @override
  String get profileSignInHint => '以设置个人资料';

  @override
  String get profileEdit => '编辑';

  @override
  String get profileCollections => '收藏';

  @override
  String get profileAge => '年龄';

  @override
  String get profileGender => '性别';

  @override
  String get profileGenderUnset => '未设置';

  @override
  String get profileGenderMale => '男';

  @override
  String get profileGenderFemale => '女';

  @override
  String get profileAvatar => '头像';

  @override
  String get profileUploadPhoto => '上传照片';

  @override
  String get profileChangePhoto => '更换照片';

  @override
  String get shopTitle => '商店';

  @override
  String get shopEmojis => '表情';

  @override
  String get shopEmojisSubtitle => '聊天用动态表情';

  @override
  String get shopCollections => '收藏';

  @override
  String get shopCollectionsSubtitle => '资料展示、礼物与收益';

  @override
  String get shopStakes => '赌注';

  @override
  String get shopStakesSubtitle => '解锁白银赌注';

  @override
  String get inventoryTitle => '物品';

  @override
  String get inventoryEmpty => '这里还是空的 — 去商店看看吧';

  @override
  String get inventoryFrames => '边框';

  @override
  String get inventoryClaim => '领取';

  @override
  String get inventorySell => '出售';

  @override
  String get inventoryGift => '赠送';

  @override
  String get messageEdited => '已编辑';

  @override
  String get messageDeleted => '消息已删除';

  @override
  String get photo => '照片';

  @override
  String get camera => '相机';

  @override
  String get gallery => '相册';

  @override
  String get connectionError => '无法连接服务器。';

  @override
  String get serverError => '服务器错误，请稍后再试。';

  @override
  String get sessionExpired => '会话已过期，请重新登录。';

  @override
  String get errNoInternet => '无网络连接。';

  @override
  String get errTimeout => '请求超时，请重试。';

  @override
  String get errGamesUnavailable => '游戏暂时不可用';

  @override
  String get errSettingsSaveFailed => '无法保存设置';

  @override
  String get errPushPermission => '请在浏览器或系统设置中允许通知。';
}
