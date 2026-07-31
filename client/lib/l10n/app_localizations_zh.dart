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
  String timeMinutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get timeWeekAgo => '一周前';

  @override
  String timeWeeksAgo(int count) {
    return '$count 周前';
  }

  @override
  String get timeMonthAgo => '一个月前';

  @override
  String timeMonthsAgo(int count) {
    return '$count 个月前';
  }

  @override
  String get timeYearAgo => '一年前';

  @override
  String timeYearsAgo(int count) {
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
  String get chatPaste => 'Вставить';

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

  @override
  String get balanceTitle => '余额';

  @override
  String get coinBronze => '青铜';

  @override
  String get coinSilver => '白银';

  @override
  String get coinGold => '黄金';

  @override
  String get coinDiamond => '钻石';

  @override
  String get balanceZeroBronze => '0 青铜';

  @override
  String balanceBronzes(int count) {
    return '$count 青铜';
  }

  @override
  String balanceSilvers(int count) {
    return '$count 白银';
  }

  @override
  String balanceGolds(int count) {
    return '$count 黄金';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count 钻石';
  }

  @override
  String balancePerDay(String amount) {
    return '每天 $amount';
  }

  @override
  String get balanceAbbrBronze => '铜';

  @override
  String get balanceAbbrSilver => '银';

  @override
  String get balanceAbbrGold => '金';

  @override
  String get commonBackHome => '返回首页';

  @override
  String get commonCopied => '已复制';

  @override
  String get commonClear => '清除';

  @override
  String get commonTryLater => '请稍后再试。';

  @override
  String get commonTryRefresh => '请尝试刷新页面。';

  @override
  String get coinsTitle => '金币';

  @override
  String get coinsLoginReward => '登录奖励';

  @override
  String get coinsLoginAvailableToday => '今日奖励可领取';

  @override
  String get coinsLoginStreak => '每日登录连续奖励';

  @override
  String get coinsFriendReward => '好友奖励';

  @override
  String coinsFriendRewardHint(String amount) {
    return '通过您的链接注册可获得 +$amount';
  }

  @override
  String get coinsLoadRewardsFailed => '无法加载奖励';

  @override
  String get coinsClaimReward => '领取奖励';

  @override
  String get coinsAlreadyClaimed => '已领取';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · 今天';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · 还剩 1 天';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · 还剩 $remaining';
  }

  @override
  String get coinsInviteFriend => '邀请好友';

  @override
  String coinsInviteHint(String amount) {
    return '每位通过您的链接注册的用户可获得 +$amount';
  }

  @override
  String get coinsCopyLink => '复制链接';

  @override
  String get coinsHowItWorks => '如何运作';

  @override
  String get coinsHowStep1 => '复制链接并发送给好友';

  @override
  String get coinsHowStep2 => '好友通过该链接注册';

  @override
  String coinsHowStep3(String amount) {
    return '您将获得 $amount';
  }

  @override
  String get achievementsTitle => '成就';

  @override
  String achievementsProgress(String progress) {
    return '进度：$progress';
  }

  @override
  String get achievementsFrameClaimed => '已获得边框';

  @override
  String get achievementsClaimed => '已获得';

  @override
  String get achievementsOpenFrame => '打开边框';

  @override
  String friendsRemoveConfirm(String name) {
    return '确定要将 $name 移出好友吗？';
  }

  @override
  String get friendsRemoveConfirmAction => '移除';

  @override
  String get friendsRemove => '移出好友';

  @override
  String get friendsAcceptRequest => '接受请求';

  @override
  String get friendsDeclineRequest => '拒绝请求';

  @override
  String get friendsCancelRequest => '取消请求';

  @override
  String get friendsSendRequest => '发送好友请求';

  @override
  String get friendsRequestAlreadySent => '请求已发送';

  @override
  String get friendsIncomingStatus => '收到的请求';

  @override
  String get friendsOutgoingStatus => '发出的请求';

  @override
  String get friendsNotFriends => '还不是好友';

  @override
  String get friendsCollapseSearch => '收起搜索';

  @override
  String get friendsExpandSearch => '显示搜索';

  @override
  String get friendsLoadFailed => '无法加载好友';

  @override
  String friendsSince(String date) {
    return '成为好友：$date';
  }

  @override
  String friendsIncomingAt(String date) {
    return '收到的请求：$date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return '发出的请求：$date';
  }

  @override
  String get userInfoTitle => '用户信息';

  @override
  String profileAgeYears(int age) {
    return '$age 岁';
  }

  @override
  String get shopBuy => '购买';

  @override
  String get shopBuyTitle => '购买？';

  @override
  String get shopBuyStakeTitle => '购买赌注？';

  @override
  String get shopBuyEmojiTitle => '购买表情？';

  @override
  String get shopBuyCollectionTitle => '购买收藏？';

  @override
  String shopPrice(String price) {
    return '价格：$price';
  }

  @override
  String get shopOwned => '已购买';

  @override
  String get shopEmpty => '暂无内容';

  @override
  String shopPurchased(String title) {
    return '已购买 $title';
  }

  @override
  String get shopEmojiUses => '获得：10 次使用';

  @override
  String shopEmojiBought(String title) {
    return '$title：+10 次使用';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 次使用';
  }

  @override
  String get shopBuyTen => '购买 · 10 个';

  @override
  String shopDailyIncome(String amount) {
    return '收益：$amount';
  }

  @override
  String get shopBuyOnce => '一次性购买';

  @override
  String get shopSellRefund => '出售可返还部分费用';

  @override
  String shopCollectionAdded(String title) {
    return '$title 已添加到个人资料';
  }

  @override
  String shopSetBonus(int percent) {
    return '套装加成 +$percent%';
  }

  @override
  String get shopSetComplete => '已集齐';

  @override
  String shopSetProgress(int owned, int total) {
    return '已收集 · $owned/$total';
  }

  @override
  String get inventorySellTitle => '出售？';

  @override
  String inventorySellDesc(String amount) {
    return '您将获得 $amount';
  }

  @override
  String inventorySold(String amount) {
    return '已出售：+$amount';
  }

  @override
  String get inventoryNeedFriends => '请先添加好友';

  @override
  String get inventoryGiftTitle => '赠送收藏？';

  @override
  String inventoryGiftDesc(String title, String name) {
    return '将「$title」赠送给 $name？';
  }

  @override
  String inventoryGifted(String title) {
    return '已赠送：$title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'У этого пользователя уже есть эта коллекция';

  @override
  String get inventoryGiftSelf => 'Нельзя подарить коллекцию самому себе';

  @override
  String get inventoryGiftNotOwned => 'У вас нет этого предмета';

  @override
  String get inventoryLoadFailed => '无法加载物品';

  @override
  String get inventoryNoCollections => '没有收藏 — 请在商店购买';

  @override
  String get inventoryNoEmojis => '没有表情 — 请在商店购买';

  @override
  String get inventoryNoFrames => '没有边框 — 在联赛中赢 10 场（成就）';

  @override
  String get inventoryNoStakes => '没有已购买的赌注';

  @override
  String inventoryEmojiLeft(int count) {
    return '剩余 $count';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return '收益：+$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return '明日收益：$amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Доход:';

  @override
  String get inventoryIncomeTomorrowLabel => 'Доход завтра:';

  @override
  String inventoryStakeGold(String amount) {
    return '可以下注 $amount 黄金';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return '可以下注 $amount 白银';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return '已领取 +$amount';
  }

  @override
  String get chatsLoadFailed => '无法加载聊天';

  @override
  String get chatsLoadListFailed => '无法加载列表';

  @override
  String get chatsBlockedEmpty => '列表为空';

  @override
  String chatsBlockedAt(String date) {
    return '已屏蔽：$date';
  }

  @override
  String get chatsCreateFailed => '无法创建聊天';

  @override
  String get chatsNeedFriendsFirst => '请先添加好友，然后才能打开聊天。';

  @override
  String get chatsFriendsNotFound => '未找到好友';

  @override
  String get chatsFindFriendHint => '按昵称查找好友';

  @override
  String get chatsSelectChat => '选择聊天';

  @override
  String get chatsSelectHint => '从左侧列表选择对话';

  @override
  String get chatEditFailed => '无法编辑消息';

  @override
  String get chatSendFailed => '无法发送消息';

  @override
  String get chatDeleteFailed => '无法删除消息';

  @override
  String get chatEmojiSendFailed => '无法发送表情';

  @override
  String get chatLoadFailed => '无法加载消息';

  @override
  String get chatBackToGame => '返回游戏';

  @override
  String get chatBackToChats => '返回聊天';

  @override
  String get chatActions => '聊天操作';

  @override
  String get chatScrollToEnd => '转到对话末尾';

  @override
  String chatReplyingTo(String name) {
    return '回复 $name';
  }

  @override
  String get chatGift => '礼物';

  @override
  String get chatCollection => '收藏';

  @override
  String get chatGiftCollection => '礼物 · 收藏';

  @override
  String get chatThisUser => '此用户';

  @override
  String get gamesLobbyLoadFailed => '无法加载大厅。';

  @override
  String get gamesTapChangeStake => '点击更改赌注';

  @override
  String get gamesTapChangeTurnTime => '点击更改回合时间';

  @override
  String get gamesTapChangeGrid => '点击更改网格大小';

  @override
  String get gamesSwapSidesHint => '第一步后 O 可能变成 X';

  @override
  String get gamesNoCenterHint => '第一步不能下在中心';

  @override
  String get lobbyInviteSentShort => '已发送';

  @override
  String get lobbyInvitesSentWaiting => '邀请已发送。等待回复。';

  @override
  String get lobbyLinkCopiedHint => '将其粘贴到聊天或发给好友的消息中';

  @override
  String get lobbyCopyLinkHint => '复制链接到剪贴板';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name 邀请您一起玩';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name 获胜';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return '时间到。$name 获胜';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get adminTitle => '管理后台';

  @override
  String get tournamentsTitle => '锦标赛';

  @override
  String get profileAgeInvalid => '请输入 1 到 111 之间的年龄';

  @override
  String get profileSaveFailed => '无法保存个人资料';

  @override
  String get profileNameHint => '拉丁字母、数字、_，最多 10 个字符';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => '1 到 111';

  @override
  String get profileAboutHint => '最多 100 个字符（可选）';

  @override
  String get profileProcessingPhoto => '正在处理照片…';

  @override
  String get profileCropTitle => '选择头像区域';

  @override
  String get profileCropHint => '缩放并移动照片';

  @override
  String get profileApply => '应用';

  @override
  String get profilePreparing => '准备中…';

  @override
  String timeSecondsShort(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get timeOneMin => '1 分钟';

  @override
  String get timeTenMin => '10 分钟';

  @override
  String rulesIntro(String grid) {
    return '在 $grid 棋盘上玩井字棋。轮流落子，X 先行。';
  }

  @override
  String rulesWin(int n) {
    return '获胜：在横向、纵向或对角线连成 $n 个。';
  }

  @override
  String get rulesNoTimeLimit => '每步不限时。';

  @override
  String rulesTurnTime(String time) {
    return '每步时间：$time。';
  }

  @override
  String rulesStake(String stake) {
    return '赌注：$stake。本局押这么多硬币。';
  }

  @override
  String get rulesSwap => '换边：X 首步之后，O 可与 X 互换。';

  @override
  String get rulesNoCenter => '禁中：X 首步不能下在中心。';

  @override
  String get collectionSetLegends => '传奇';

  @override
  String get collectionSetSpace => '太空';

  @override
  String get collectionSetGems => '宝石';

  @override
  String get collectionSetParty => '派对';

  @override
  String get collectionSetNature => '自然';

  @override
  String get collectionSetAdventures => '冒险';

  @override
  String collectionCardMeta(String amount) {
    return '收藏 · 展示 · 赠送 · 出售 · +$amount';
  }

  @override
  String get coinsDayOne => '天';

  @override
  String get coinsDayFew => '天';

  @override
  String get coinsDayMany => '天';

  @override
  String get giftFriendTitle => '送给好友';

  @override
  String photoCount(int count) {
    return '照片（$count）';
  }

  @override
  String photoCountWithText(int count, String text) {
    return '照片（$count）：$text';
  }

  @override
  String photoWithText(String text) {
    return '照片：$text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count 个表情 · 每个 $price';
  }

  @override
  String get chatsExpandPanel => '展开面板';

  @override
  String get chatsCollapsePanel => '收起面板';

  @override
  String get chatReplySourceMissing => '找不到原消息';

  @override
  String shopStakeTitleSilver(int n) {
    return '赌注 $n 银';
  }

  @override
  String shopStakeTitleGold(int n) {
    return '赌注 $n 金';
  }

  @override
  String shopStakeDescSilver(int n) {
    return '解锁以 $n 银下注';
  }

  @override
  String shopStakeDescGold(int n) {
    return '解锁以 $n 金下注';
  }

  @override
  String get chatReplySelf => '自己';

  @override
  String get chatReplyPeer => '对方';

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
