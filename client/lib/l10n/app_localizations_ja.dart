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
  String timeMinutesAgo(Object count) {
    return '$count分前';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count時間前';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count日前';
  }

  @override
  String get timeWeekAgo => '1週間前';

  @override
  String timeWeeksAgo(Object count) {
    return '$count週間前';
  }

  @override
  String get timeMonthAgo => '1か月前';

  @override
  String timeMonthsAgo(Object count) {
    return '$countか月前';
  }

  @override
  String get timeYearAgo => '1年前';

  @override
  String timeYearsAgo(Object count) {
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
}
