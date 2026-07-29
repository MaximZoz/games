import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'ホーム';

  @override
  String get navProfile => 'プロフィール';

  @override
  String get navFriends => 'フレンド';

  @override
  String get navChats => 'チャット';

  @override
  String get navGames => 'ゲーム';

  @override
  String get navSettings => '設定';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsLanguageSystem => 'システム既定';

  @override
  String get settingsAddBotsTitle => '30秒後にボットを追加';

  @override
  String get settingsAddBotsSubtitle => 'マッチング中：30秒以内に相手が見つからない場合、ボットと対戦を開始します（賭け金はブロンズ1にリセット）';

  @override
  String get settingsFriendsOnlyTitle => 'フレンドからのメッセージのみ';

  @override
  String get settingsFriendsOnlySubtitle => 'フレンド以外は絵文字のみ送信できます。迷惑行為がある場合は一時的にブロックしてください。';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsPushChat => 'チャット';

  @override
  String get settingsPushFriends => 'フレンド';

  @override
  String get settingsPushGames => 'ゲーム';

  @override
  String get settingsPushRewards => '報酬';

  @override
  String get loginTitle => 'ログイン';

  @override
  String get loginSubtitle => 'メールまたはユーザー名とパスワードを入力';

  @override
  String get loginEmailLabel => 'メールまたはユーザー名';

  @override
  String get loginPasswordLabel => 'パスワード';

  @override
  String get loginSubmit => 'ログイン';

  @override
  String get loginNoAccount => 'アカウントがない方は新規登録';

  @override
  String get loginEmailRequired => 'メールまたはユーザー名を入力してください';

  @override
  String get loginPasswordRequired => 'パスワードを入力してください';

  @override
  String get loginTooltip => 'ログイン';

  @override
  String get logoutTooltip => 'ログアウト';

  @override
  String get registerTitle => '新規登録';

  @override
  String get registerSubtitle => 'プレイ用アカウントを作成';

  @override
  String get registerNameLabel => '名前（ユーザー名）';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'パスワード';

  @override
  String get registerSubmit => '登録';

  @override
  String get registerHaveAccount => 'すでにアカウントをお持ちですか？ログイン';

  @override
  String get registerNameRequired => '名前を入力してください';

  @override
  String get registerNameNoSpaces => '名前にスペースは使えません';

  @override
  String get registerNameMax => '最大20文字';

  @override
  String get registerNameHint => '20文字まで';

  @override
  String get registerEmailRequired => 'メールを入力してください';

  @override
  String get registerEmailInvalid => 'メールが無効です';

  @override
  String get registerPasswordHint => '6文字以上';

  @override
  String get registerPasswordMin => 'パスワードは6文字以上必要です';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '削除';

  @override
  String get commonEdit => '編集';

  @override
  String get commonReply => '返信';

  @override
  String get commonSend => '送信';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonLoading => '読み込み中…';

  @override
  String get commonError => 'エラー';

  @override
  String get commonOnline => 'オンライン';

  @override
  String get commonOffline => 'オフライン';

  @override
  String get commonOnlineCap => 'オンライン';

  @override
  String get commonUser => 'ユーザー';

  @override
  String get commonPlayer => 'プレイヤー';

  @override
  String get commonAboutMe => '自己紹介';

  @override
  String get commonBack => '戻る';

  @override
  String get commonAccept => '承認';

  @override
  String get commonDecline => '拒否';

  @override
  String get commonCreating => '作成中…';

  @override
  String get commonSearching => '検索中…';

  @override
  String get commonInsufficientCoins => 'コインが不足しています';

  @override
  String get commonNotFound => '見つかりません';

  @override
  String get commonServerErrorShort => 'サーバーエラー';

  @override
  String get commonForbidden => 'アクセスが拒否されました';

  @override
  String get commonUserBlocked => 'ユーザーはブロックされています';

  @override
  String get commonUserNotFound => 'ユーザーが見つかりません';

  @override
  String get commonGenericError => '問題が発生しました。もう一度お試しください。';

  @override
  String get timeJustNow => 'たった今';

  @override
  String get timeYesterday => '昨日';

  @override
  String timeMinutesAgo(int count) {
    return '$count分前';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count時間前';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count日前';
  }

  @override
  String get timeWeekAgo => '1週間前';

  @override
  String timeWeeksAgo(int count) {
    return '$count週間前';
  }

  @override
  String get timeMonthAgo => '1か月前';

  @override
  String timeMonthsAgo(int count) {
    return '$countか月前';
  }

  @override
  String get timeYearAgo => '1年前';

  @override
  String timeYearsAgo(int count) {
    return '$count年前';
  }

  @override
  String get weekdaySun => '日';

  @override
  String get weekdayMon => '月';

  @override
  String get weekdayTue => '火';

  @override
  String get weekdayWed => '水';

  @override
  String get weekdayThu => '木';

  @override
  String get weekdayFri => '金';

  @override
  String get weekdaySat => '土';

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
  String get homeAchievements => '実績';

  @override
  String get homeAchievementsSubtitle => 'あなたの戦績';

  @override
  String get homeAchievementsRewards => '受け取れる報酬があります';

  @override
  String get homeCoins => 'コイン';

  @override
  String get homeCoinsSubtitle => '残高と報酬';

  @override
  String get homeCoinsDailyReward => 'デイリーログイン報酬を受け取れます';

  @override
  String get homeItems => 'アイテム';

  @override
  String get homeItemsInventory => 'インベントリ';

  @override
  String get homeItemsGifted => 'コレクションが贈られました';

  @override
  String get homeItemsIncome => 'コレクション収益を受け取れます';

  @override
  String get homeShop => 'ショップ';

  @override
  String get homeShopSubtitle => '絵文字、賭け金、コレクション';

  @override
  String get gamesTitle => 'ゲーム';

  @override
  String get gamesFindMatch => '対戦を探す';

  @override
  String get gamesMyTurn => 'あなたの番';

  @override
  String get gamesWaiting => '待機中';

  @override
  String get gamesLobbyTab => 'ロビー';

  @override
  String get gamesTicTacToe => '三目並べ';

  @override
  String get gamesRules => 'ルール';

  @override
  String get gamesRulesTitle => 'ゲームルール';

  @override
  String get gamesCreate => 'ゲームを作成';

  @override
  String get gamesJoin => '参加';

  @override
  String get gamesOpponentTurn => '相手の番';

  @override
  String get gamesCurrentGame => '進行中のゲーム';

  @override
  String get gamesInvitedYou => '招待されました';

  @override
  String get gamesTurnTime => '制限時間';

  @override
  String get gamesGridSize => '盤面サイズ';

  @override
  String get gamesSwapSides => 'サイド交代';

  @override
  String get gamesNoCenter => '中央開始なし';

  @override
  String get lobbyMatchmake => 'ロビー';

  @override
  String get lobbyPrivateGame => 'プライベート対戦';

  @override
  String get lobbySearchingOpponent => '対戦相手を探しています…';

  @override
  String get lobbyWaitingJoin => '誰かが「対戦を探す」または「参加」をタップするまで待機中';

  @override
  String get lobbyInviteTitle => 'ゲーム招待';

  @override
  String get lobbyInvitedToPlay => '対戦に招待されました';

  @override
  String get lobbyEnterGame => 'ゲームに入る';

  @override
  String get lobbyInvite => '招待';

  @override
  String get lobbyInviteSent => '招待を送信しました';

  @override
  String get lobbyCopyLink => 'ゲームリンクを共有';

  @override
  String get lobbyLinkCopied => 'リンクをコピーしました';

  @override
  String get lobbyNoFriendsOnline => 'オンラインのフレンドがいません。上のリンクを共有するか、フレンドのオンラインを待ってください。';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => '相手';

  @override
  String get gameYouWon => '勝ちました！';

  @override
  String get gameYouWonOpponentLeft => '勝ちました — 相手が退出しました';

  @override
  String get gameYouWonOpponentTimeout => '勝ちました — 相手が時間切れです';

  @override
  String get gameDraw => '引き分け';

  @override
  String get gameExitTitle => 'ゲームを退出';

  @override
  String get gameExitConfirm => '退出すると負けになります。それでも退出しますか？';

  @override
  String get gameStay => '残る';

  @override
  String get gameLeave => '退出';

  @override
  String get gameConnecting => 'ゲームに接続中…';

  @override
  String get gameWaitingOpponent => '相手を待っています';

  @override
  String get gameRematchOffer => '相手が再戦を提案しています';

  @override
  String get gameRematchDeclined => '相手が再戦を拒否しました';

  @override
  String get gameRematch => '再戦';

  @override
  String get gameOtherOpponent => '別の相手';

  @override
  String get gameSwapSidesAction => 'サイドを交代';

  @override
  String get gameWriteMessage => 'メッセージを書く';

  @override
  String get chatsTitle => 'チャット';

  @override
  String get chatsEmpty => 'チャットはまだありません。\n右上のアイコンからフレンドを選んで会話を始めましょう。';

  @override
  String get chatsNewChat => '新しいチャット';

  @override
  String get chatsNoMessages => 'メッセージはありません';

  @override
  String get chatsClearTitle => '会話を消去しますか？';

  @override
  String get chatsClearDesc => 'チャットは完全に削除されます。';

  @override
  String get chatsClearConfirm => '消去';

  @override
  String get chatsBlockTitle => 'このユーザーをブロックしますか？';

  @override
  String get chatsBlockDesc => '以降メッセージのやり取りができなくなります。チャットとフレンド関係は削除されます。';

  @override
  String get chatsBlockConfirm => 'ブロック';

  @override
  String get chatsBlockedUsers => 'ブロック中のユーザー';

  @override
  String get chatsUnblock => 'ブロック解除';

  @override
  String get chatDialog => 'チャット';

  @override
  String get chatEmpty => 'メッセージはまだありません。\n最初のメッセージを送りましょう。';

  @override
  String get chatMessageHint => 'メッセージ';

  @override
  String get chatEmoji => '絵文字';

  @override
  String get chatBuyEmojiHint => 'ホーム画面のショップで絵文字を購入';

  @override
  String get chatEditing => '編集中';

  @override
  String get chatToday => '今日';

  @override
  String get chatYesterday => '昨日';

  @override
  String get chatFriendsOnly => 'テキストはフレンドのみ';

  @override
  String get emojiGroupEmotions => '感情';

  @override
  String get emojiGroupGame => 'ゲーム';

  @override
  String get emojiGroupFlags => '旗';

  @override
  String get emojiGroupAnimals => '動物';

  @override
  String get emojiGroupFood => '食べ物';

  @override
  String get emojiGroupTravel => '旅行';

  @override
  String get emojiGroupParty => 'お祝い';

  @override
  String get emojiGroupObjects => '物';

  @override
  String get friendsTitle => 'フレンド';

  @override
  String get friendsTabFriends => 'フレンド';

  @override
  String get friendsTabIncoming => '受信';

  @override
  String get friendsTabOutgoing => '送信';

  @override
  String get friendsAdd => 'フレンド追加';

  @override
  String get friendsRequestSent => 'リクエストを送信しました';

  @override
  String get friendsFindTab => 'フレンドを探す';

  @override
  String get friendsSearchHint => 'ユーザー名で検索';

  @override
  String get friendsSearchPrompt => '検索で新しいフレンドを見つけましょう';

  @override
  String get friendsNothingFound => '見つかりませんでした';

  @override
  String get friendsEmpty => 'まだフレンドがいません';

  @override
  String get friendsNoIncoming => '受信リクエストはありません';

  @override
  String get friendsNoOutgoing => '送信リクエストはありません';

  @override
  String get friendsAlreadyFriends => 'すでにフレンドです';

  @override
  String get friendsRemoveTitle => 'フレンドから削除しますか？';

  @override
  String get friendsRemoved => 'フレンドから削除しました';

  @override
  String get friendsRequestAccepted => 'リクエストを承認しました';

  @override
  String get friendsRequestDeclined => 'リクエストを拒否しました';

  @override
  String get friendsRequestCancelled => 'リクエストをキャンセルしました';

  @override
  String get profileTitle => 'プロフィール';

  @override
  String get profileSignInPrompt => 'アカウントにログイン';

  @override
  String get profileSignInHint => 'プロフィールを設定するには';

  @override
  String get profileEdit => '編集';

  @override
  String get profileCollections => 'コレクション';

  @override
  String get profileAge => '年齢';

  @override
  String get profileGender => '性別';

  @override
  String get profileGenderUnset => '未設定';

  @override
  String get profileGenderMale => '男性';

  @override
  String get profileGenderFemale => '女性';

  @override
  String get profileAvatar => 'アバター';

  @override
  String get profileUploadPhoto => '写真をアップロード';

  @override
  String get profileChangePhoto => '写真を変更';

  @override
  String get shopTitle => 'ショップ';

  @override
  String get shopEmojis => '絵文字';

  @override
  String get shopEmojisSubtitle => 'チャット用のアニメ絵文字';

  @override
  String get shopCollections => 'コレクション';

  @override
  String get shopCollectionsSubtitle => 'プロフィール展示、ギフト、収益';

  @override
  String get shopStakes => '賭け金';

  @override
  String get shopStakesSubtitle => 'シルバー賭け金を解除';

  @override
  String get inventoryTitle => 'アイテム';

  @override
  String get inventoryEmpty => 'まだ何もありません — ショップをチェック';

  @override
  String get inventoryFrames => 'フレーム';

  @override
  String get inventoryClaim => '受け取る';

  @override
  String get inventorySell => '売却';

  @override
  String get inventoryGift => '贈る';

  @override
  String get messageEdited => '編集済み';

  @override
  String get messageDeleted => 'メッセージは削除されました';

  @override
  String get photo => '写真';

  @override
  String get camera => 'カメラ';

  @override
  String get gallery => 'ギャラリー';

  @override
  String get connectionError => 'サーバーに接続できませんでした。';

  @override
  String get serverError => 'サーバーエラーです。しばらくしてからもう一度お試しください。';

  @override
  String get sessionExpired => 'セッションの有効期限が切れました。再度ログインしてください。';

  @override
  String get errNoInternet => 'インターネットに接続されていません。';

  @override
  String get errTimeout => 'リクエストがタイムアウトしました。もう一度お試しください。';

  @override
  String get errGamesUnavailable => 'ゲームは一時的に利用できません';

  @override
  String get errSettingsSaveFailed => '設定を保存できませんでした';

  @override
  String get errPushPermission => 'ブラウザまたはシステム設定で通知を許可してください。';

  @override
  String get balanceTitle => '残高';

  @override
  String get coinBronze => 'ブロンズ';

  @override
  String get coinSilver => 'シルバー';

  @override
  String get coinGold => 'ゴールド';

  @override
  String get coinDiamond => 'ダイヤモンド';

  @override
  String get balanceZeroBronze => 'ブロンズ 0';

  @override
  String balanceBronzes(int count) {
    return 'ブロンズ $count';
  }

  @override
  String balanceSilvers(int count) {
    return 'シルバー $count';
  }

  @override
  String balanceGolds(int count) {
    return 'ゴールド $count';
  }

  @override
  String balanceDiamonds(int count) {
    return 'ダイヤモンド $count';
  }

  @override
  String balancePerDay(String amount) {
    return '1日 $amount';
  }

  @override
  String get balanceAbbrBronze => 'ブ';

  @override
  String get balanceAbbrSilver => 'シ';

  @override
  String get balanceAbbrGold => 'ゴ';

  @override
  String get commonBackHome => 'ホームに戻る';

  @override
  String get commonCopied => 'コピーしました';

  @override
  String get commonClear => 'クリア';

  @override
  String get commonTryLater => '後でもう一度お試しください。';

  @override
  String get commonTryRefresh => 'ページを更新してみてください。';

  @override
  String get coinsTitle => 'コイン';

  @override
  String get coinsLoginReward => 'ログイン報酬';

  @override
  String get coinsLoginAvailableToday => '今日の報酬を受け取れます';

  @override
  String get coinsLoginStreak => '毎日ログイン連続記録';

  @override
  String get coinsFriendReward => 'フレンド報酬';

  @override
  String coinsFriendRewardHint(String amount) {
    return 'あなたのリンクからの登録で +$amount';
  }

  @override
  String get coinsLoadRewardsFailed => '報酬を読み込めませんでした';

  @override
  String get coinsClaimReward => '報酬を受け取る';

  @override
  String get coinsAlreadyClaimed => '受け取り済み';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · 今日';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · あと1日';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · あと $remaining';
  }

  @override
  String get coinsInviteFriend => 'フレンドを招待';

  @override
  String coinsInviteHint(String amount) {
    return 'あなたのリンクで登録した人ごとに +$amount';
  }

  @override
  String get coinsCopyLink => 'リンクをコピー';

  @override
  String get coinsHowItWorks => '仕組み';

  @override
  String get coinsHowStep1 => 'リンクをコピーしてフレンドに送る';

  @override
  String get coinsHowStep2 => 'フレンドがそのリンクから登録する';

  @override
  String coinsHowStep3(String amount) {
    return '$amount が付与されます';
  }

  @override
  String get achievementsTitle => '実績';

  @override
  String achievementsProgress(String progress) {
    return '進捗: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'フレーム獲得';

  @override
  String get achievementsClaimed => '獲得済み';

  @override
  String get achievementsOpenFrame => 'フレームを開く';

  @override
  String friendsRemoveConfirm(String name) {
    return '$name をフレンドから削除しますか？';
  }

  @override
  String get friendsRemoveConfirmAction => '削除';

  @override
  String get friendsRemove => 'フレンドから削除';

  @override
  String get friendsAcceptRequest => 'リクエストを承認';

  @override
  String get friendsDeclineRequest => 'リクエストを拒否';

  @override
  String get friendsCancelRequest => 'リクエストをキャンセル';

  @override
  String get friendsSendRequest => 'フレンドリクエストを送信';

  @override
  String get friendsRequestAlreadySent => 'リクエストは送信済みです';

  @override
  String get friendsIncomingStatus => '受信リクエスト';

  @override
  String get friendsOutgoingStatus => '送信リクエスト';

  @override
  String get friendsNotFriends => 'フレンドではありません';

  @override
  String get friendsCollapseSearch => '検索を閉じる';

  @override
  String get friendsExpandSearch => '検索を表示';

  @override
  String get friendsLoadFailed => 'フレンドを読み込めませんでした';

  @override
  String friendsSince(String date) {
    return 'フレンド開始: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return '受信リクエスト: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return '送信リクエスト: $date';
  }

  @override
  String get userInfoTitle => 'ユーザー情報';

  @override
  String profileAgeYears(int age) {
    return '$age 歳';
  }

  @override
  String get shopBuy => '購入';

  @override
  String get shopBuyTitle => '購入しますか？';

  @override
  String get shopBuyStakeTitle => '賭け金を購入しますか？';

  @override
  String get shopBuyEmojiTitle => '絵文字を購入しますか？';

  @override
  String get shopBuyCollectionTitle => 'コレクションを購入しますか？';

  @override
  String shopPrice(String price) {
    return '価格: $price';
  }

  @override
  String get shopOwned => '購入済み';

  @override
  String get shopEmpty => 'まだ何もありません';

  @override
  String shopPurchased(String title) {
    return '$title を購入しました';
  }

  @override
  String get shopEmojiUses => '取得: 10回分';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10回分';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10回分';
  }

  @override
  String get shopBuyTen => '購入 · 10個';

  @override
  String shopDailyIncome(String amount) {
    return '収入: $amount';
  }

  @override
  String get shopBuyOnce => '一度きりの購入';

  @override
  String get shopSellRefund => '売却すると費用の一部が戻ります';

  @override
  String shopCollectionAdded(String title) {
    return '$title をプロフィールに追加しました';
  }

  @override
  String shopSetBonus(int percent) {
    return 'セットボーナス +$percent%';
  }

  @override
  String get shopSetComplete => '完成';

  @override
  String shopSetProgress(int owned, int total) {
    return '収集済み · $owned/$total';
  }

  @override
  String get inventorySellTitle => '売却しますか？';

  @override
  String inventorySellDesc(String amount) {
    return '$amount を受け取ります';
  }

  @override
  String inventorySold(String amount) {
    return '売却済み: +$amount';
  }

  @override
  String get inventoryNeedFriends => '先にフレンドを追加してください';

  @override
  String get inventoryGiftTitle => 'コレクションを贈りますか？';

  @override
  String inventoryGiftDesc(String title, String name) {
    return '「$title」を $name に贈りますか？';
  }

  @override
  String inventoryGifted(String title) {
    return '贈呈済み: $title';
  }

  @override
  String get inventoryLoadFailed => 'アイテムを読み込めませんでした';

  @override
  String get inventoryNoCollections => 'コレクションがありません — ショップで購入';

  @override
  String get inventoryNoEmojis => '絵文字がありません — ショップで購入';

  @override
  String get inventoryNoFrames => 'フレームがありません — リーグで10勝（実績）';

  @override
  String get inventoryNoStakes => '購入済みの賭け金がありません';

  @override
  String inventoryEmojiLeft(int count) {
    return '残り $count';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return '収入: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return '明日の収入: $amount';
  }

  @override
  String inventoryStakeGold(String amount) {
    return '$amount ゴールドを賭けられます';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return '$amount シルバーを賭けられます';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return '+$amount を受け取りました';
  }

  @override
  String get chatsLoadFailed => 'チャットを読み込めませんでした';

  @override
  String get chatsLoadListFailed => 'リストを読み込めませんでした';

  @override
  String get chatsBlockedEmpty => 'リストは空です';

  @override
  String chatsBlockedAt(String date) {
    return 'ブロック済み: $date';
  }

  @override
  String get chatsCreateFailed => 'チャットを作成できませんでした';

  @override
  String get chatsNeedFriendsFirst => '先にフレンドを追加してからチャットを開けます。';

  @override
  String get chatsFriendsNotFound => 'フレンドが見つかりません';

  @override
  String get chatsFindFriendHint => 'ニックネームでフレンドを探す';

  @override
  String get chatsSelectChat => 'チャットを選択';

  @override
  String get chatsSelectHint => '左のリストから会話を選んでください';

  @override
  String get chatEditFailed => 'メッセージを編集できませんでした';

  @override
  String get chatSendFailed => 'メッセージを送信できませんでした';

  @override
  String get chatDeleteFailed => 'メッセージを削除できませんでした';

  @override
  String get chatEmojiSendFailed => '絵文字を送信できませんでした';

  @override
  String get chatLoadFailed => 'メッセージを読み込めませんでした';

  @override
  String get chatBackToGame => 'ゲームに戻る';

  @override
  String get chatBackToChats => 'チャットに戻る';

  @override
  String get chatActions => 'チャット操作';

  @override
  String get chatScrollToEnd => '会話の末尾へ';

  @override
  String chatReplyingTo(String name) {
    return '$name への返信';
  }

  @override
  String get chatGift => 'ギフト';

  @override
  String get chatCollection => 'コレクション';

  @override
  String get chatGiftCollection => 'ギフト · コレクション';

  @override
  String get chatThisUser => 'このユーザー';

  @override
  String get gamesLobbyLoadFailed => 'ロビーを読み込めませんでした。';

  @override
  String get gamesTapChangeStake => 'タップして賭け金を変更';

  @override
  String get gamesTapChangeTurnTime => 'タップして持ち時間を変更';

  @override
  String get gamesTapChangeGrid => 'タップしてグリッドサイズを変更';

  @override
  String get gamesSwapSidesHint => '1手目の後、OがXになることがあります';

  @override
  String get gamesNoCenterHint => '初手は中央に置けません';

  @override
  String get lobbyInviteSentShort => '送信済み';

  @override
  String get lobbyInvitesSentWaiting => '招待を送信しました。返信を待っています。';

  @override
  String get lobbyLinkCopiedHint => 'チャットやフレンドへのメッセージに貼り付けてください';

  @override
  String get lobbyCopyLinkHint => 'リンクをクリップボードにコピー';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name があなたをゲームに招待しています';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name の勝ち';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return '時間切れ。$name の勝ち';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get adminTitle => '管理画面';

  @override
  String get tournamentsTitle => 'トーナメント';

  @override
  String get profileAgeInvalid => '年齢は1〜111で入力してください';

  @override
  String get profileSaveFailed => 'プロフィールを保存できませんでした';

  @override
  String get profileNameHint => 'ラテン文字、数字、_、最大10文字';

  @override
  String get profileAgeHint => '1〜111';

  @override
  String get profileAboutHint => '最大100文字（任意）';

  @override
  String get profileProcessingPhoto => '写真を処理中…';

  @override
  String get profileCropTitle => 'アバター範囲を選択';

  @override
  String get profileCropHint => '写真を拡大・移動';

  @override
  String get profileApply => '適用';

  @override
  String get profilePreparing => '準備中…';

  @override
  String timeSecondsShort(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get timeOneMin => '1分';

  @override
  String get timeTenMin => '10分';

  @override
  String rulesIntro(String grid) {
    return '$grid の盤で三目並べ。交互に打ち、X が先手。';
  }

  @override
  String rulesWin(int n) {
    return '勝利：縦・横・斜めに $n 個並べます。';
  }

  @override
  String get rulesNoTimeLimit => '一手の制限時間なし。';

  @override
  String rulesTurnTime(String time) {
    return '一手の時間：$time。';
  }

  @override
  String rulesStake(String stake) {
    return '掛け金：$stake。このコイン数で対戦します。';
  }

  @override
  String get rulesSwap => 'サイド交代：X の初手の後、O は X と交代できます。';

  @override
  String get rulesNoCenter => '中央禁止：X は初手で中央に打てません。';

  @override
  String get collectionSetLegends => '伝説';

  @override
  String get collectionSetSpace => '宇宙';

  @override
  String get collectionSetGems => '宝石';

  @override
  String get collectionSetParty => 'パーティー';

  @override
  String get collectionSetNature => '自然';

  @override
  String get collectionSetAdventures => '冒険';

  @override
  String collectionCardMeta(String amount) {
    return 'コレクション · 展示 · ギフト · 売却 · +$amount';
  }

  @override
  String get coinsDayOne => '日';

  @override
  String get coinsDayFew => '日';

  @override
  String get coinsDayMany => '日';

  @override
  String get giftFriendTitle => '友達に贈る';

  @override
  String photoCount(int count) {
    return '写真（$count）';
  }

  @override
  String photoCountWithText(int count, String text) {
    return '写真（$count）：$text';
  }

  @override
  String photoWithText(String text) {
    return '写真：$text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count 個の絵文字 · $price';
  }

  @override
  String get chatsExpandPanel => 'パネルを展開';

  @override
  String get chatsCollapsePanel => 'パネルを折りたたむ';

  @override
  String get chatReplySourceMissing => '元のメッセージが見つかりません';

  @override
  String shopStakeTitleSilver(int n) {
    return 'ベット $n シルバー';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'ベット $n ゴールド';
  }

  @override
  String shopStakeDescSilver(int n) {
    return '$n シルバーのベットを解除';
  }

  @override
  String shopStakeDescGold(int n) {
    return '$n ゴールドのベットを解除';
  }

  @override
  String get chatReplySelf => '自分';

  @override
  String get chatReplyPeer => '相手';
}
