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
  String get settingsOfflineModeTitle => 'ネットワークモード';

  @override
  String get settingsOfflineModeSubtitle => 'オフライン：すぐにボットと対戦、賭け金や報酬なし、チャットや友達なし。購入は保存され、オンラインモードで適用されます。オンライン — インターネットがあるとき、またはユーザー設定による。';

  @override
  String get settingsModeOnline => 'オンライン';

  @override
  String get settingsModeOffline => 'オフライン';

  @override
  String get gamesAlternateStartsHint => '交互に誰が対局を開始するか';

  @override
  String get rulesAlternateStarts => '先手は対局ごとに交代します。';

  @override
  String get offlineBadgeTooltip => 'オフラインモード';

  @override
  String get offlineModePopupTitle => 'オフラインモード';

  @override
  String get offlineModePopupBody => 'オフラインモードがオンです。賭け金や報酬なしでボットと対戦できます。チャット、友達、ロビーは非表示です。購入はオンラインモードで適用されます。';

  @override
  String get offlineModePopupSettings => '設定';

  @override
  String get gamesPlay => 'プレイ';

  @override
  String get offlineGameTitle => 'ボット対戦';

  @override
  String get offlineGameHint => '賭け金・報酬なし · オフラインのみ';

  @override
  String get offlineBotWon => 'ボットの勝ち';

  @override
  String get offlineBotThinking => 'ボットの手番…';

  @override
  String get offlinePlayAgain => 'もう一度';

  @override
  String offlineBotName(int n) {
    return 'ボット $n';
  }

  @override
  String get durakActionTake => '取る';

  @override
  String get durakActionAll => 'すべて';

  @override
  String get durakActionDone => '完了';

  @override
  String get durakActionBito => 'ビト';

  @override
  String get durakHintDefend => '防御してください';

  @override
  String get durakHintDefendOrTransfer => '防御するか転送してください';

  @override
  String get durakHintOpponentDefends => '相手が防御中';

  @override
  String get durakHintThrowInFirst => 'カードを追加（最初の回りは最大5枚）';

  @override
  String get durakHintThrowIn => 'カードを追加するか防御を待つ';

  @override
  String get durakHintOpponentThrows => '相手が追加中';

  @override
  String get durakHintTakeFollow => '取った後に追加するか「完了」をタップ';

  @override
  String get durakHintOpponentTakeFollow => '相手は取った後に追加できます';

  @override
  String get durakHintBito => 'カードを出すか「ビト」と言ってください';

  @override
  String get durakHintOpponentBito => '相手が追加するか「ビト」と言います';

  @override
  String get durakHintYourAttack => 'あなたの番 — 攻撃してください';

  @override
  String get durakHintOpponentAttack => '相手が攻撃中';

  @override
  String get durakHintYouLost => '負けました — あなたが愚か者です';

  @override
  String get durakHintDrawAllOut => '引き分け — 全員脱落';

  @override
  String get durakHintYouFinished => '脱落しました — 終了を待っています';

  @override
  String get durakFirstLeadYou => 'あなたの番です';

  @override
  String get durakFirstLeadOpponent => '相手の番です';

  @override
  String get durakFirstLeadBot => 'ボットの番です';

  @override
  String durakFirstLeadOf(String name) {
    return '$name の番です';
  }

  @override
  String get durakFirstLeadReason => '一番弱い切り札';

  @override
  String get shopPurchaseQueued => '購入を保存しました — オンラインモードで適用されます';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — 購入を適用しました';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — 購入を適用できませんでした: $reason';
  }

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
  String settingsAppVersion(String version) {
    return 'バージョン $version';
  }

  @override
  String get appUpdateTitle => 'アップデートがあります';

  @override
  String get appUpdateBody => 'アプリの新しいバージョンがあります。続けるには更新してください。';

  @override
  String get appUpdateWhatsNew => '新着情報';

  @override
  String get appUpdateOk => '更新';

  @override
  String get appUpdateLaterBanner => 'この対局の後にアプリを更新します';

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
  String get gamesDurak => 'ドゥラック';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => '回転';

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
  String get gamesPoker => 'ポーカー';

  @override
  String get gamesUno => 'ウノ';

  @override
  String rulesUnoPlayers(int players) {
    return 'プレイヤー: $players人。';
  }

  @override
  String get rulesUnoOfflineBot => 'ボットとの対戦。ターン制限時間なし。';

  @override
  String get rulesUnoIntro => 'クラシックウノ：全員にカードが配られ、色または数字で出します。';

  @override
  String get rulesUnoPlay => '特殊カード：+2、リバース、スキップ、ワイルド、ワイルド+4。出せなければ山札から引きます。';

  @override
  String get rulesUnoWin => '最初に手札をすべて出し切った人が勝ち。残り1枚のときは「ウノ」と言います。';

  @override
  String get rulesUnoCall => '残り1枚で「ウノ」と宣言します。先に挑戦された場合は2枚引きます。';

  @override
  String get rulesUnoScoring => '数字は額面、アクションは20点、ワイルドは50点です。先に100点へ到達すると勝利です。';

  @override
  String get unoColorRed => '赤';

  @override
  String get unoColorYellow => '黄';

  @override
  String get unoColorGreen => '緑';

  @override
  String get unoColorBlue => '青';

  @override
  String get unoDraw => '引く';

  @override
  String get unoKeep => '保持';

  @override
  String get unoSayUno => 'ウノ！';

  @override
  String get unoChallengeUno => 'ウノを指摘';

  @override
  String get unoChallengeWd4 => '+4に挑戦';

  @override
  String get unoChooseColor => '色を選択';

  @override
  String get unoDrawPile => '山札';

  @override
  String get unoDiscardPile => '捨て札';

  @override
  String unoCardsCount(int count) {
    return 'カード：$count';
  }

  @override
  String unoScore(int score) {
    return '得点：$score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'ラウンド$round · $target点先取';
  }

  @override
  String get unoYourTurn => 'あなたの番';

  @override
  String get unoWaitingTurn => '相手の番';

  @override
  String get unoChooseColorHint => 'ワイルドの色を選んでください';

  @override
  String get unoWd4Hint => '4枚引くかワイルド+4に挑戦します';

  @override
  String get unoDrawnHint => '引いたカードを出すか保持します';

  @override
  String get unoPlayHint => '同じ色または値のカードを出してください';

  @override
  String get unoDrawHint => '出せるカードがありません — 山札から引きます';

  @override
  String unoPendingDraw(int count) {
    return '+$count枚';
  }

  @override
  String get unoYouWon => '勝利しました！';

  @override
  String get unoYouLost => '試合終了';

  @override
  String unoWinner(String name) {
    return '勝者：$name';
  }

  @override
  String get unoDirectionClockwise => '時計回り';

  @override
  String get unoDirectionCounterclockwise => '反時計回り';

  @override
  String get gamesInDevelopment => '開発中';

  @override
  String rulesPokerPlayers(int players) {
    return '人数: $players。';
  }

  @override
  String get rulesPokerIntro => 'テキサスホールデム。各プレイヤーにホールカード2枚、場にコミュニティカード5枚。';

  @override
  String get rulesPokerPlay => 'ベッティングラウンドはプリフロップ・フロップ・ターン・リバー。フォールド、コール、ベット、レイズができます。';

  @override
  String get rulesPokerWin => 'ホール＋コミュニティから作った最強の5枚、またはフォールド後に残った一人が勝ちです。';

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
  String get rulesPokerTable => 'The table plays until one player holds all the chips. Blinds rise every two dealer orbits; 3-max lasts 10 hands, heads-up lasts six orbits.';

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
  String get gamesObservation => '観戦';

  @override
  String get gamesObservationHint => '終了まで観戦できます';

  @override
  String get gamesFinishCurrentFirst => 'まず現在の対局を終えてください';

  @override
  String get gamesVariantClassic => 'クラシック';

  @override
  String get gamesVariantGomoku => '五目並べ';

  @override
  String get gamesVariantUltimate => 'アルティメット';

  @override
  String get gamesVariantMulti3 => '3人';

  @override
  String get gamesVariantMulti4 => '4人';

  @override
  String get gamesDurakModePodkidnoi => '追加出し';

  @override
  String get gamesDurakModePerevodnoi => '転送';

  @override
  String get gamesDurakDeck24 => '24枚';

  @override
  String get gamesDurakDeck36 => '36枚';

  @override
  String get gamesDurakDeck52 => '52枚';

  @override
  String rulesDurakMode(String mode) {
    return 'モード: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return '人数: $players。デッキ: $deck。';
  }

  @override
  String get rulesDurakOfflineBot => 'ボット対戦。賭け金も制限時間もありません。';

  @override
  String get rulesDurakAttack => '攻撃側がカードを出し、守備側が打ちます（同スートのより強い札、または切り札）。切り札はより強い切り札でのみ打てます。';

  @override
  String get rulesDurakBeat => 'すべて打てたら攻撃側が「ビト」と言い、カードは捨て札へ。できなければ守備側が場の札をすべて取ります。';

  @override
  String get rulesDurakLoser => '最後に手札が残った人が負け — 「愚か者」です。';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'プレイヤー $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'ロビー $name';
  }

  @override
  String get lobbyMatchmake => 'ロビー';

  @override
  String get lobbyPrivateGame => 'プライベート対戦';

  @override
  String get lobbySearchingOpponent => '対戦相手を探しています…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'この対局を探しています: $count';
  }

  @override
  String get lobbyWaitingJoin => '誰かが「対戦を探す」または「参加」をタップするまで待機中';

  @override
  String get lobbyInviteTitle => 'ゲーム招待';

  @override
  String get lobbyInvitedToPlay => '対戦に招待されました';

  @override
  String get lobbyEnterGame => 'ゲームに入る';

  @override
  String get lobbyGone => 'ロビーは利用できません';

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
  String get gameYouLost => '負けました';

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
  String get gameSurrender => '降参';

  @override
  String get gameSurrenderTitle => '降参しますか？';

  @override
  String get gameSurrenderConfirm => '対局と賭け金を失います。';

  @override
  String get gameOfferDraw => '引き分けを提案';

  @override
  String get gameOfferDrawTitle => '引き分けを提案しますか？';

  @override
  String get gameOfferDrawConfirm => '相手は引き分けを承諾または拒否できます。';

  @override
  String get gameAcceptDrawTitle => '引き分けを承諾しますか？';

  @override
  String get gameAcceptDrawConfirm => '対局は引き分けで終了します。';

  @override
  String get gameDrawOffered => '相手が引き分けを提案しています';

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
  String get chatPaste => '貼り付け';

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
  String get profileChangePhoto => 'アバターを変更';

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
  String get shopStakesSubtitle => 'より高い賭け金を解除';

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
    return '$amount/日';
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
  String get shopSellRefund => '売却すると費用の80%が戻ります';

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
  String get inventoryGiftAlreadyOwns => 'そのプレイヤーはすでにこのアイテムを持っています';

  @override
  String get inventoryGiftSelf => '自分自身には送れません';

  @override
  String get inventoryGiftNotOwned => 'このアイテムは所持していません';

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
  String get inventoryIncomeReadyLabel => '受取可能';

  @override
  String get inventoryIncomeTomorrowLabel => '明日';

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
  String get chatAutoTranslate => '自動翻訳';

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
  String get profileNameLatinOnly => 'Latin characters only';

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
  String get profileGalleryTitle => '写真';

  @override
  String get profileGalleryAdd => '写真を追加';

  @override
  String get profileMakePrimary => 'メインにする';

  @override
  String get profilePhotoDelete => '写真を削除';

  @override
  String get profilePhotosLimit => '写真は3枚までです';

  @override
  String get profilePhotosEmpty => '写真はまだありません';

  @override
  String get profilePhotoUploadFailed => '写真をアップロードできませんでした';

  @override
  String get profilePhotoDeleteFailed => '写真を削除できませんでした';

  @override
  String get profilePhotoTooLarge => '写真が大きすぎます';

  @override
  String get profileSetPrimaryFailed => 'メインに設定できませんでした';

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
  String get statsTitle => '統計';

  @override
  String get statsLoadFailed => '統計を読み込めませんでした';

  @override
  String get statsAllGames => 'すべてのゲーム';

  @override
  String get statsEmptyTitle => 'まだ対局がありません';

  @override
  String get statsEmptyHint => 'ここに統計を表示するには、最初のゲームをプレイしてください。';

  @override
  String get statsWins => '勝利';

  @override
  String get statsDraws => '引き分け';

  @override
  String get statsLosses => '敗北';

  @override
  String get statsWinRate => '勝率';

  @override
  String get statsTopWon => '最も多く勝った相手';

  @override
  String get statsTopDrawn => '最も引き分けが多い相手';

  @override
  String get statsTopLost => '最も多く負けた相手';

  @override
  String get statsTimePlayed => 'プレイ時間';

  @override
  String get statsYourScore => '対戦成績';

  @override
  String get profileShowStats => '統計を表示';

  @override
  String get statsDurationZeroMinutes => '0分';

  @override
  String get gameYouWonOpponentForfeit => '相手が降参しました。あなたの勝ちです！';

  @override
  String get lobbyLeaveTitle => 'ロビーを退出しますか？';

  @override
  String get lobbyLeaveConfirm => '退出後にロビーは削除されます。招待した友達には拒否が届きます。';

  @override
  String get lobbyLeave => '退出';

  @override
  String statsDurationHours(int hours) {
    return '$hours時間';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return '降参しました。$nameの勝ちです';
  }

  @override
  String get supportTitle => 'サポート';

  @override
  String get supportUnavailable => 'サポートは利用できません';

  @override
  String get supportOpenFailed => 'サポートチャットを開けませんでした';

  @override
  String coinsGrantedTitle(int amount) {
    return '$amount コインが付与されました';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return '$amount コインが差し引かれました';
  }

  @override
  String get coinsCreditCardTitle => 'コインが付与されました';

  @override
  String get coinsClaim => '受け取る';

  @override
  String get durakActionPass => 'パス';

  @override
  String get durakRoleTook => '取り';

  @override
  String get durakRoleBeats => '防御中';

  @override
  String get durakRoleThrowIn => '追加';

  @override
  String get durakRoleTurn => '手番';

  @override
  String get durakRoleDefends => '防御中';

  @override
  String get durakStatusTaking => '取る';

  @override
  String get durakHintDefenderTurn => '守り手の番';

  @override
  String get gameYouEliminated => '脱落しました';

  @override
  String gameYouPlaced(int place) {
    return '$place位でした';
  }

  @override
  String get gameOverNeutral => '対局終了';

  @override
  String gameTurnOf(String name) {
    return '$nameの番';
  }

  @override
  String get chatGroupTooltip => 'グループチャット';

  @override
  String get lobbyChatNotReady => 'ロビーチャットはまだありません';

  @override
  String get chatsGroupChat => 'グループチャット';

  @override
  String chatsMembersCount(int count) {
    return 'メンバー: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count人';
  }

  @override
  String get chatsYouSuffix => '(あなた)';

  @override
  String get chatTitleDurak3 => 'ドゥラック・3人';

  @override
  String get chatTitleDurak4 => 'ドゥラック・4人';

  @override
  String get rulesTttUltimate => 'アルティメット：3×3のミニ盤が9つ。手番で相手をそのミニ盤へ送ります。メタ盤で揃えた方が勝ちです。';

  @override
  String get rulesTttMulti3 => '3人用：3×3盤で3人（X・O・△）。自分の記号で揃えると勝ちです。';

  @override
  String get rulesTttMulti4 => '4人用：4×4盤で4人（X・O・△・□）。自分の記号で揃えると勝ちです。';
}
