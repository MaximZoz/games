import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Ana sayfa';

  @override
  String get navProfile => 'Profil';

  @override
  String get navFriends => 'Arkadaşlar';

  @override
  String get navChats => 'Sohbetler';

  @override
  String get navGames => 'Oyunlar';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsLanguageSystem => 'Sistem varsayılanı';

  @override
  String get settingsSoundTitle => 'Ses';

  @override
  String get settingsSoundSubtitle => 'Oyunlar ve bildirimler';

  @override
  String get settingsSoundGames => 'Oyunlar';

  @override
  String get settingsSoundNotifications => 'Bildirimler';

  @override
  String get settingsSoundTurn => 'Sıra';

  @override
  String get settingsHapticsTitle => 'Titreşim';

  @override
  String get settingsHapticsSubtitle => 'Yalnızca uyarılar: mesajlar, istekler, sıra ve süre';

  @override
  String get settingsOfflineModeTitle => 'Ağ modu';

  @override
  String get settingsOfflineModeSubtitle => 'Çevrimdışı: hemen botla oyna, bahis ve ödül yok, sohbet ve arkadaş yok. Satın alımlar kaydedilir ve çevrimiçi modda uygulanır. Çevrimiçi — internet varken veya kullanıcı ayarına göre.';

  @override
  String get settingsModeOnline => 'Çevrimiçi';

  @override
  String get settingsModeOffline => 'Çevrimdışı';

  @override
  String get gamesAlternateStartsHint => 'Sırayla kim partiyi başlatır';

  @override
  String get rulesAlternateStarts => 'İlk hamleyi kim yapacağı partiden partiye değişir.';

  @override
  String get offlineBadgeTooltip => 'Çevrimdışı mod';

  @override
  String get offlineModePopupTitle => 'Çevrimdışı mod';

  @override
  String get offlineModePopupBody => 'Çevrimdışı mod açık. Bahis ve ödül olmadan botla oynayın. Sohbetler, arkadaşlar ve lobi gizlidir. Satın alımlar çevrimiçi modda uygulanır.';

  @override
  String get offlineModePopupSettings => 'Ayarlar';

  @override
  String get gamesPlay => 'Oyna';

  @override
  String get offlineGameTitle => 'Bota karşı oyun';

  @override
  String get offlineGameHint => 'Bahis ve ödül yok · yalnızca çevrimdışı';

  @override
  String get offlineBotWon => 'Bot kazandı';

  @override
  String get offlineBotThinking => 'Bot düşünüyor…';

  @override
  String get offlinePlayAgain => 'Tekrar';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'Al';

  @override
  String get durakActionAll => 'Tümü';

  @override
  String get durakActionDone => 'Bitti';

  @override
  String get durakActionBito => 'Beat';

  @override
  String get durakHintDefend => 'Savun';

  @override
  String get durakHintDefendOrTransfer => 'Savun veya aktar';

  @override
  String get durakHintOpponentDefends => 'Rakip savunuyor';

  @override
  String get durakHintThrowInFirst => 'Kart atın (ilk turda en fazla 5)';

  @override
  String get durakHintThrowIn => 'Kart atın veya savunmayı bekleyin';

  @override
  String get durakHintOpponentThrows => 'Rakip atıyor';

  @override
  String get durakHintTakeFollow => 'Aldıktan sonra atın veya «Bitti»ye dokunun';

  @override
  String get durakHintOpponentTakeFollow => 'Rakip aldıktan sonra atabilir';

  @override
  String get durakHintBito => 'Kart atın veya «Bito» deyin';

  @override
  String get durakHintOpponentBito => 'Rakip atıyor veya «Bito» diyor';

  @override
  String get durakHintYourAttack => 'Sizin sıra — saldırın';

  @override
  String get durakHintOpponentAttack => 'Rakip saldırıyor';

  @override
  String get durakHintYouLost => 'Kaybettiniz — siz duraksınız';

  @override
  String get durakHintDrawAllOut => 'Berabere — herkes çıktı';

  @override
  String get durakHintYouFinished => 'Çıktınız — sonu bekleniyor';

  @override
  String get durakFirstLeadYou => 'Siz başlıyorsunuz';

  @override
  String get durakFirstLeadOpponent => 'Rakip başlıyor';

  @override
  String get durakFirstLeadBot => 'Bot başlıyor';

  @override
  String durakFirstLeadOf(String name) {
    return '$name başlıyor';
  }

  @override
  String get durakFirstLeadReason => 'En düşük koz';

  @override
  String get shopPurchaseQueued => 'Satın alma kaydedildi — çevrimiçi modda uygulanacak';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — satın alma uygulandı';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — satın alma uygulanmadı: $reason';
  }

  @override
  String get settingsFriendsOnlyTitle => 'Yalnızca arkadaşlardan mesaj';

  @override
  String get settingsFriendsOnlySubtitle => 'Arkadaş olmayanlar yalnızca emoji gönderebilir. Spam sorunsa kullanıcıyı geçici olarak engelleyin.';

  @override
  String get settingsNotifications => 'Bildirimler';

  @override
  String get settingsPushChat => 'Sohbet';

  @override
  String get settingsPushFriends => 'Arkadaşlar';

  @override
  String get settingsPushGames => 'Oyunlar';

  @override
  String get settingsPushRewards => 'Ödüller';

  @override
  String settingsAppVersion(String version) {
    return 'Sürüm $version';
  }

  @override
  String get appUpdateTitle => 'Güncelleme mevcut';

  @override
  String get appUpdateBody => 'Uygulamanın yeni bir sürümü mevcut. Devam etmek için güncelleyin.';

  @override
  String get appUpdateWhatsNew => 'Yenilikler';

  @override
  String get appUpdateOk => 'Güncelle';

  @override
  String get appUpdateLaterBanner => 'Bu oyundan sonra uygulamayı güncelleyeceğiz';

  @override
  String get loginTitle => 'Giriş yap';

  @override
  String get loginSubtitle => 'E-posta veya kullanıcı adı ve şifre girin';

  @override
  String get loginEmailLabel => 'E-posta veya kullanıcı adı';

  @override
  String get loginPasswordLabel => 'Şifre';

  @override
  String get loginSubmit => 'Giriş yap';

  @override
  String get loginNoAccount => 'Hesabınız yok mu? Kaydolun';

  @override
  String get loginEmailRequired => 'E-posta veya kullanıcı adı girin';

  @override
  String get loginPasswordRequired => 'Şifre girin';

  @override
  String get loginTooltip => 'Giriş yap';

  @override
  String get logoutTooltip => 'Çıkış yap';

  @override
  String get registerTitle => 'Kaydol';

  @override
  String get registerSubtitle => 'Oynamak için hesap oluşturun';

  @override
  String get registerNameLabel => 'Ad (kullanıcı adı)';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'Şifre';

  @override
  String get registerSubmit => 'Kaydol';

  @override
  String get registerHaveAccount => 'Zaten hesabınız var mı? Giriş yapın';

  @override
  String get registerNameRequired => 'Ad girin';

  @override
  String get registerNameNoSpaces => 'Ad boşluk içeremez';

  @override
  String get registerNameMax => 'En fazla 20 karakter';

  @override
  String get registerNameHint => 'En fazla 20 karakter';

  @override
  String get registerEmailRequired => 'E-posta girin';

  @override
  String get registerEmailInvalid => 'Geçersiz e-posta';

  @override
  String get registerPasswordHint => 'En az 6 karakter';

  @override
  String get registerPasswordMin => 'Şifre en az 6 karakter olmalı';

  @override
  String get commonCancel => 'İptal';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonEdit => 'Düzenle';

  @override
  String get commonReply => 'Yanıtla';

  @override
  String get commonSend => 'Gönder';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonRetry => 'Yeniden dene';

  @override
  String get commonLoading => 'Yükleniyor…';

  @override
  String get commonError => 'Hata';

  @override
  String get commonOnline => 'çevrimiçi';

  @override
  String get commonOffline => 'çevrimdışı';

  @override
  String get commonOnlineCap => 'Çevrimiçi';

  @override
  String get commonUser => 'Kullanıcı';

  @override
  String get commonPlayer => 'Oyuncu';

  @override
  String get commonAboutMe => 'Hakkımda';

  @override
  String get commonBack => 'Geri';

  @override
  String get commonAccept => 'Kabul et';

  @override
  String get commonDecline => 'Reddet';

  @override
  String get commonCreating => 'Oluşturuluyor…';

  @override
  String get commonSearching => 'Aranıyor…';

  @override
  String get commonInsufficientCoins => 'Yeterli jeton yok';

  @override
  String get commonNotFound => 'Bulunamadı';

  @override
  String get commonServerErrorShort => 'Sunucu hatası';

  @override
  String get commonForbidden => 'Erişim reddedildi';

  @override
  String get commonUserBlocked => 'Kullanıcı engellendi';

  @override
  String get commonUserNotFound => 'Kullanıcı bulunamadı';

  @override
  String get commonGenericError => 'Bir şeyler ters gitti. Lütfen tekrar deneyin.';

  @override
  String get apiErrWrongGameType => 'Yanlış oyun türü';

  @override
  String get apiErrWrongGameTypeOrState => 'Yanlış oyun türü veya durumu';

  @override
  String get apiErrLobbyFull => 'Lobi dolu';

  @override
  String get apiErrBadState => 'Geçersiz oyun durumu';

  @override
  String get apiErrIllegalMove => 'Geçersiz hamle';

  @override
  String get apiErrUnknownMoveType => 'Bilinmeyen hamle türü';

  @override
  String get apiErrNoOpponents => 'Rakip yok';

  @override
  String get apiErrNoOpponentsRematch => 'Rövanş için rakip yok';

  @override
  String get apiErrAlreadyInLobby => 'Zaten bu lobidesiniz';

  @override
  String get apiErrGameNotActive => 'Oyun aktif değil';

  @override
  String get apiErrNotInBattle => 'Savaş evresinde değilsiniz';

  @override
  String get apiErrNotInSetup => 'Yerleştirme evresinde değilsiniz';

  @override
  String get apiErrAlreadyReady => 'Zaten hazırsınız';

  @override
  String get apiErrAlreadyForfeited => 'Zaten pes ettiniz';

  @override
  String get apiErrYouHaveForfeited => 'Pes ettiniz';

  @override
  String get apiErrNoDrawOffer => 'Beraberlik teklifi yok';

  @override
  String get apiErrDrawOnlyPvp => 'Beraberlik yalnızca oyuncuya karşı';

  @override
  String get apiErrDrawOnly1v1 => 'Beraberlik yalnızca 1v1’de';

  @override
  String get apiErrDrawVsBot => 'Bota karşı beraberlik yok';

  @override
  String get apiErrDrawMultiplayer => 'Çok oyunculuda beraberlik yok';

  @override
  String get apiErrDeck24TwoPlayers => '24’lük deste yalnızca 2 oyuncu içindir';

  @override
  String get apiErrDeck52ThreeOrFour => '52’lik deste 3 veya 4 oyuncu ister';

  @override
  String get apiErrAccountFrozen => 'Hesap donduruldu';

  @override
  String get apiErrTurnTimeInvalid => 'Tur süresi 0, 20, 60 veya 600 saniye olmalı';

  @override
  String get timeJustNow => 'az önce';

  @override
  String get timeYesterday => 'dün';

  @override
  String timeMinutesAgo(int count) {
    return '$count dk önce';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count sa önce';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count g önce';
  }

  @override
  String get timeWeekAgo => 'bir hafta önce';

  @override
  String timeWeeksAgo(int count) {
    return '$count hf önce';
  }

  @override
  String get timeMonthAgo => 'bir ay önce';

  @override
  String timeMonthsAgo(int count) {
    return '$count ay önce';
  }

  @override
  String get timeYearAgo => 'bir yıl önce';

  @override
  String timeYearsAgo(int count) {
    return '$count yıl önce';
  }

  @override
  String get weekdaySun => 'Paz';

  @override
  String get weekdayMon => 'Pzt';

  @override
  String get weekdayTue => 'Sal';

  @override
  String get weekdayWed => 'Çar';

  @override
  String get weekdayThu => 'Per';

  @override
  String get weekdayFri => 'Cum';

  @override
  String get weekdaySat => 'Cmt';

  @override
  String get monthJan => 'Oca';

  @override
  String get monthFeb => 'Şub';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Nis';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Haz';

  @override
  String get monthJul => 'Tem';

  @override
  String get monthAug => 'Ağu';

  @override
  String get monthSep => 'Eyl';

  @override
  String get monthOct => 'Eki';

  @override
  String get monthNov => 'Kas';

  @override
  String get monthDec => 'Ara';

  @override
  String get homeAchievements => 'Başarımlar';

  @override
  String get homeAchievementsSubtitle => 'Oyun sonuçlarınız';

  @override
  String get homeAchievementsRewards => 'Alınabilir ödüller var';

  @override
  String get homeCoins => 'Jetonlar';

  @override
  String get homeCoinsSubtitle => 'Bakiye ve ödüller';

  @override
  String get homeCoinsDailyReward => 'Günlük giriş ödülü hazır';

  @override
  String get homeItems => 'Eşyalar';

  @override
  String get homeItemsInventory => 'Envanteriniz';

  @override
  String get homeItemsGifted => 'Birisi size koleksiyon hediye etti';

  @override
  String get homeItemsIncome => 'Koleksiyon geliri alınmaya hazır';

  @override
  String get homeShop => 'Mağaza';

  @override
  String get homeShopSubtitle => 'Emoji, bahisler, koleksiyonlar';

  @override
  String get gamesTitle => 'Oyunlar';

  @override
  String get gamesFindMatch => 'Oyun bul';

  @override
  String get gamesMyTurn => 'Sıra sizde';

  @override
  String get gamesWaiting => 'Bekleniyor';

  @override
  String get gamesLobbyTab => 'Lobi';

  @override
  String get gamesTicTacToe => 'XOX';

  @override
  String get gamesDurak => 'Durak';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => 'Döndür';

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
  String get gamesPoker => 'Poker';

  @override
  String get gamesUno => 'Uno';

  @override
  String get gamesNardy => 'Tavla';

  @override
  String get gamesNardyModeShort => 'Kısa';

  @override
  String get gamesNardyModeLong => 'Uzun';

  @override
  String get rulesNardyTitle => 'Tavla — kurallar';

  @override
  String get rulesNardyPlayers => 'Oyuncular: 2.';

  @override
  String rulesNardyMode(String mode) {
    return 'Mod: $mode.';
  }

  @override
  String get rulesNardyIntro => '24 pul yeri, her birinde 15 pul. İki zar: bir pul toplam veya iki pul ayrı değerler.';

  @override
  String get rulesNardyPlayShort => 'Kısa tavla: birbirinize doğru ilerlersiniz ve yalnız pulları vurabilirsiniz. Vurulan pul bara gider ve yeniden girmelidir. Hepsi evdeyken pulları kaldırırsınız.';

  @override
  String get rulesNardyPlayLong => 'Uzun tavla: ikisi de aynı baştan başlar ve aynı yöne gider. Baştan turda en fazla bir pul çıkar. Vurmak yoktur. Hepsi evdeyken pulları kaldırırsınız.';

  @override
  String get rulesNardyWin => 'Tüm pullarını ilk kaldıran kazanır.';

  @override
  String get nardyRoll => 'Zar at';

  @override
  String get nardySkipTurn => 'Sırayı geç';

  @override
  String get nardyUndoMove => 'Geri al';

  @override
  String get nardyDoneTurn => 'Bitti';

  @override
  String get nardyNoMoves => 'Hamle yok — sırayı geçin';

  @override
  String get nardyYourRoll => 'Zarınız';

  @override
  String get nardyPipsShort => 'Kalan:';

  @override
  String get nardyYouWonMars => 'Kazandınız — mars!';

  @override
  String get nardyYouLostMars => 'Kaybettiniz — mars';

  @override
  String get rulesNardyOfflineBot => 'Çevrimdışı: bota karşı oyun.';

  @override
  String rulesUnoPlayers(int players) {
    return 'Oyuncular: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'Bota karşı oyun, tur süresi sınırı yok.';

  @override
  String get rulesUnoIntro => 'Herkese 7 kart dağıtılır. Aynı renk veya aynı değerde (sayı ya da aynı özel kart) bir kart oynayın.';

  @override
  String get rulesUnoPlay => 'Atla — sıradaki turunu kaybeder. İki kişide yön değiştirme Atla gibi çalışır. +2 yalnızca +2 üzerine, +4 yalnızca +4 üzerine konur: ceza toplanır (iki +2 sonraki 4 kart çeker). +2, +4 üzerine oynanamaz. Cevap vermeyen tüm yığını çeker ve turunu kaybeder. Aynı iki siyah olmayan kart (ör. iki sarı 8) birlikte atılır: birini oynayın, ikizi otomatik gider.';

  @override
  String get rulesUnoWild => 'Siyah kart yeni renk seçer. +4 yalnızca elde mevcut renk yoksa oynanır. Rakip itiraz edebilir: +4 yasal ise 6 çeker; değilse +4 oynayan 4 çeker ve itiraz eden oynar.';

  @override
  String get rulesUnoDraw => 'Uygun kart yoksa desteden bir kart çekin. Uyuyorsa hemen oynayabilir veya tutup sırayı geçebilirsiniz. Elde hamle varken çekilemez.';

  @override
  String get rulesUnoWin => 'İkişer 100, 3+ oyuncuda 200. Turu elini bitiren kazanır.';

  @override
  String get rulesUnoCall => 'Bir kart kaldığında hemen «Uno!»ya basın. Rakipler Unoyu unuttuğunuz için sizi ancak bir saniye sonra yakalayabilir — o zaman 2 kart çekersiniz.';

  @override
  String get rulesUnoScoring => 'Kartlarını ilk bitiren turu kazanır ve rakiplerin ellerinden puan alır: sayılar nominal, özel kartlar 20, siyahlar 50. İkişer 100, 3+ oyuncuda 200.';

  @override
  String get unoColorRed => 'Kırmızı';

  @override
  String get unoColorYellow => 'Sarı';

  @override
  String get unoColorGreen => 'Yeşil';

  @override
  String get unoColorBlue => 'Mavi';

  @override
  String get unoDraw => 'Çek';

  @override
  String get unoKeep => 'Tut';

  @override
  String get unoSayUno => 'Uno!';

  @override
  String get unoChallengeUno => 'Uno itirazı';

  @override
  String get unoChallengeWd4 => '+4 itirazı';

  @override
  String get unoChooseColor => 'Renk seç';

  @override
  String get unoDrawPile => 'Çekme destesi';

  @override
  String get unoDiscardPile => 'Atılanlar';

  @override
  String unoCardsCount(int count) {
    return 'Kart: $count';
  }

  @override
  String unoScore(int score) {
    return 'Puan: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'Tur $round · hedef $target';
  }

  @override
  String get unoYourTurn => 'Sıra sizde';

  @override
  String get unoWaitingTurn => 'Rakibin sırası';

  @override
  String get unoChooseColorHint => 'Joker için bir renk seçin';

  @override
  String get unoWd4Hint => '4 kart çekin veya Wild +4’e itiraz edin';

  @override
  String get unoDrawnHint => 'Çekilen kartı oynayın veya tutun';

  @override
  String get unoPlayHint => 'Eşleşen renk veya değeri oynayın';

  @override
  String get unoDrawHint => 'Eşleşen kart yok — desteden çekin';

  @override
  String unoPendingDraw(int count) {
    return '+$count kart';
  }

  @override
  String get unoYouWon => 'Maçı kazandınız!';

  @override
  String get unoYouLost => 'Maç bitti';

  @override
  String get unoYouLostTimeout => 'Süre dolduğu için kaybettiniz';

  @override
  String unoWinner(String name) {
    return 'Kazanan: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name turu kazanır';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'İleri';

  @override
  String get unoRoundScoresTitle => 'Tur puanı';

  @override
  String get unoDirectionClockwise => 'Saat yönünde';

  @override
  String get unoDirectionCounterclockwise => 'Saat yönünün tersine';

  @override
  String get unoErrStackSameOnly => '+2 üzerine yalnızca +2, +4 üzerine yalnızca +4 konur. +2, +4 üzerine atılamaz.';

  @override
  String get unoErrCatchTooEarly => 'Bir saniye bekleyin — hâlâ Uno diyebilirler.';

  @override
  String get unoErrCallTooLate => 'Artık Uno diyemezsiniz. Sıradaki oyuncu zaten oynadı.';

  @override
  String get gamesInDevelopment => 'Geliştiriliyor';

  @override
  String rulesPokerPlayers(int players) {
    return 'Oyuncular: $players.';
  }

  @override
  String get rulesPokerIntro => 'Texas Hold’em. Her oyuncuya 2 kapalı kart verilir; masaya 5 ortak kart gelir.';

  @override
  String get rulesPokerPlay => 'Bahis turları: preflop, flop, turn ve river. Fold, call, bet veya raise yapabilirsiniz.';

  @override
  String get rulesPokerWin => 'En iyi beş kartlık el (kapalı + ortak) veya foldlardan sonra kalan son oyuncu kazanır.';

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
  String get pokerCombinationsTitle => 'Kombinasyonlar';

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
  String get gamesRules => 'Kurallar';

  @override
  String get gamesRulesTitle => 'Oyun kuralları';

  @override
  String get gamesCreate => 'Oyun oluştur';

  @override
  String get gamesJoin => 'Katıl';

  @override
  String get gamesOpponentTurn => 'Rakibin sırası';

  @override
  String get gamesCurrentGame => 'Güncel oyun';

  @override
  String get gamesInvitedYou => 'Davet edildiniz';

  @override
  String get gamesTurnTime => 'Hamle süresi';

  @override
  String get gamesGridSize => 'Izgara boyutu';

  @override
  String get gamesSwapSides => 'Taraf değişimi';

  @override
  String get gamesNoCenter => 'Merkezden başlama yok';

  @override
  String get gamesObservation => 'İzleme';

  @override
  String get gamesObservationHint => 'Oyun bitene kadar izleyebilirsiniz';

  @override
  String get gamesFinishCurrentFirst => 'Önce mevcut oyununuzu bitirin';

  @override
  String get gamesVariantClassic => 'Klasik';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 oyuncu';

  @override
  String get gamesVariantMulti4 => '4 oyuncu';

  @override
  String get gamesDurakModePodkidnoi => 'Atışlı';

  @override
  String get gamesDurakModePerevodnoi => 'Aktarmalı';

  @override
  String get gamesDurakDeck24 => '24 kart';

  @override
  String get gamesDurakDeck36 => '36 kart';

  @override
  String get gamesDurakDeck52 => '52 kart';

  @override
  String rulesDurakMode(String mode) {
    return 'Mod: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'Oyuncular: $players. Deste: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Bot’a karşı oynayın; bahis ve süre sınırı yok.';

  @override
  String get rulesDurakAttack => 'Saldıran kart koyar; savunan onları döver (aynı renk daha yüksek veya koz). Koz yalnızca daha yüksek kozla dövülür.';

  @override
  String get rulesDurakBeat => 'Tüm kartlar dövülünce saldıran «Bito» der ve kartlar atığa gider. Yoksa savunan masadaki her şeyi alır.';

  @override
  String get rulesDurakLoser => 'Kaybeden, sonda kartı kalan kişidir — «durak».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Oyuncular $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Lobi $name';
  }

  @override
  String get lobbyMatchmake => 'Lobi';

  @override
  String get lobbyPrivateGame => 'Özel oyun';

  @override
  String get lobbySearchingOpponent => 'Rakip aranıyor…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Bu oyunu arıyor: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Birinin «Oyun bul» veya «Katıl»a basması bekleniyor';

  @override
  String get lobbyInviteTitle => 'Oyun daveti';

  @override
  String get lobbyInvitedToPlay => 'Oynamaya davet edildiniz';

  @override
  String get lobbyEnterGame => 'Oyuna gir';

  @override
  String get lobbyGone => 'Lobi artık mevcut değil';

  @override
  String get lobbyInvite => 'Davet et';

  @override
  String get lobbyInviteSent => 'Davet gönderildi';

  @override
  String get lobbyCopyLink => 'Oyun bağlantısını paylaş';

  @override
  String get lobbyLinkCopied => 'Bağlantı kopyalandı';

  @override
  String get lobbyNoFriendsOnline => 'Çevrimiçi arkadaş yok. Yukarıdaki oyun bağlantısını paylaşın veya arkadaşlarınızın çevrimiçi olmasını bekleyin.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Rakip';

  @override
  String get gameYouWon => 'Kazandınız!';

  @override
  String get gameYouLost => 'Kaybettiniz';

  @override
  String get gameYouWonOpponentLeft => 'Kazandınız — rakip ayrıldı';

  @override
  String get gameYouWonOpponentTimeout => 'Kazandınız — rakibin süresi doldu';

  @override
  String get gameDraw => 'Berabere';

  @override
  String get gameExitTitle => 'Oyundan çık';

  @override
  String get gameExitConfirm => 'Çıkarsanız kaybedersiniz. Yine de çıkılsın mı?';

  @override
  String get gameStay => 'Kal';

  @override
  String get gameLeave => 'Çık';

  @override
  String get gameSurrender => 'Teslim ol';

  @override
  String get gameSurrenderTitle => 'Teslim olunsun mu?';

  @override
  String get gameSurrenderConfirm => 'Partiyi ve bahis jetonlarını kaybedersiniz.';

  @override
  String get gameOfferDraw => 'Beraberlik teklif et';

  @override
  String get gameOfferDrawTitle => 'Beraberlik teklif edilsin mi?';

  @override
  String get gameOfferDrawConfirm => 'Rakibiniz beraberliği kabul veya reddedebilir.';

  @override
  String get gameAcceptDrawTitle => 'Beraberlik kabul edilsin mi?';

  @override
  String get gameAcceptDrawConfirm => 'Parti beraberlikle biter.';

  @override
  String get gameDrawOffered => 'Rakip beraberlik teklif ediyor';

  @override
  String get gameConnecting => 'Oyuna bağlanılıyor…';

  @override
  String get gameWaitingOpponent => 'Rakip bekleniyor';

  @override
  String get gameRematchOffer => 'Rakip rövanş teklif ediyor';

  @override
  String get gameRematchDeclined => 'Rakip rövanşı reddetti';

  @override
  String get gameRematch => 'Rövanş';

  @override
  String get gameOtherOpponent => 'Başka rakip';

  @override
  String get gameSwapSidesAction => 'Tarafları değiştir';

  @override
  String get gameWriteMessage => 'Mesaj yaz';

  @override
  String get chatsTitle => 'Sohbetler';

  @override
  String get chatsEmpty => 'Henüz sohbet yok.\nSağ üstteki simgeye dokunup bir arkadaş seçerek konuşmaya başlayın.';

  @override
  String get chatsNewChat => 'Yeni sohbet';

  @override
  String get chatsNoMessages => 'Mesaj yok';

  @override
  String get chatsClearTitle => 'Sohbet temizlensin mi?';

  @override
  String get chatsClearDesc => 'Sohbet kalıcı olarak silinecek.';

  @override
  String get chatsClearConfirm => 'Temizle';

  @override
  String get chatsBlockTitle => 'Bu kullanıcı engellensin mi?';

  @override
  String get chatsBlockDesc => 'Artık birbirinize mesaj yazamayacaksınız. Sohbet ve arkadaşlık kaldırılacak.';

  @override
  String get chatsBlockConfirm => 'Engelle';

  @override
  String get chatsBlockedUsers => 'Engellenen kullanıcılar';

  @override
  String get chatsUnblock => 'Engeli kaldır';

  @override
  String get chatDialog => 'Sohbet';

  @override
  String get chatEmpty => 'Henüz mesaj yok.\nİlkini gönderin.';

  @override
  String get chatMessageHint => 'Mesaj';

  @override
  String get chatPaste => 'Yapıştır';

  @override
  String get chatEmoji => 'Emojiler';

  @override
  String get chatBuyEmojiHint => 'Ana ekrandaki mağazadan emoji alın';

  @override
  String get chatEditing => 'Düzenleniyor';

  @override
  String get chatToday => 'Bugün';

  @override
  String get chatYesterday => 'Dün';

  @override
  String get chatFriendsOnly => 'Metin yalnızca arkadaşlara';

  @override
  String get emojiGroupEmotions => 'Duygular';

  @override
  String get emojiGroupGame => 'Oyun';

  @override
  String get emojiGroupFlags => 'Bayraklar';

  @override
  String get emojiGroupAnimals => 'Hayvanlar';

  @override
  String get emojiGroupFood => 'Yiyecek';

  @override
  String get emojiGroupTravel => 'Seyahat';

  @override
  String get emojiGroupParty => 'Kutlama';

  @override
  String get emojiGroupObjects => 'Nesneler';

  @override
  String get friendsTitle => 'Arkadaşlar';

  @override
  String get friendsTabFriends => 'Arkadaşlar';

  @override
  String get friendsTabIncoming => 'Gelen';

  @override
  String get friendsTabOutgoing => 'Giden';

  @override
  String get friendsAdd => 'Arkadaş ekle';

  @override
  String get friendsRequestSent => 'İstek gönderildi';

  @override
  String get friendsFindTab => 'Arkadaş bul';

  @override
  String get friendsSearchHint => 'Kullanıcı adına göre ara';

  @override
  String get friendsSearchPrompt => 'Yeni arkadaş bulmak için aramayı kullanın';

  @override
  String get friendsNothingFound => 'Sonuç bulunamadı';

  @override
  String get friendsEmpty => 'Henüz arkadaşınız yok';

  @override
  String get friendsSearchNoMatches => 'Aramanızla eşleşen arkadaş yok';

  @override
  String get friendsIncomingSearchNoMatches => 'Aramanızla eşleşen gelen istek yok';

  @override
  String get friendsOutgoingSearchNoMatches => 'Aramanızla eşleşen giden istek yok';

  @override
  String get friendsNoIncoming => 'Gelen istek yok';

  @override
  String get friendsNoOutgoing => 'Giden istek yok';

  @override
  String get friendsAlreadyFriends => 'Zaten arkadaşsınız';

  @override
  String get friendsRemoveTitle => 'Arkadaşlardan çıkarılsın mı?';

  @override
  String get friendsRemoved => 'Arkadaşlardan çıkarıldı';

  @override
  String get friendsRequestAccepted => 'İstek kabul edildi';

  @override
  String get friendsRequestDeclined => 'İstek reddedildi';

  @override
  String get friendsRequestCancelled => 'İstek iptal edildi';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSignInPrompt => 'Hesabınıza giriş yapın';

  @override
  String get profileSignInHint => 'Kişisel profilinizi ayarlamak için';

  @override
  String get profileEdit => 'Düzenle';

  @override
  String get profileCollections => 'Koleksiyonlar';

  @override
  String get profileAge => 'Yaş';

  @override
  String get profileGender => 'Cinsiyet';

  @override
  String get profileGenderUnset => 'Belirtilmedi';

  @override
  String get profileGenderMale => 'Erkek';

  @override
  String get profileGenderFemale => 'Kadın';

  @override
  String get profileAvatar => 'Avatar';

  @override
  String get profileUploadPhoto => 'Fotoğraf yükle';

  @override
  String get profileChangePhoto => 'Avatarı değiştir';

  @override
  String get shopTitle => 'Mağaza';

  @override
  String get shopEmojis => 'Emojiler';

  @override
  String get shopEmojisSubtitle => 'Sohbet için animasyonlu emojiler';

  @override
  String get shopCollections => 'Koleksiyonlar';

  @override
  String get shopCollectionsSubtitle => 'Profil vitrini, hediyeler ve gelir';

  @override
  String get shopStakes => 'Bahisler';

  @override
  String get shopStakesSubtitle => 'Daha yüksek bahisleri açın';

  @override
  String get inventoryTitle => 'Eşyalar';

  @override
  String get inventoryEmpty => 'Henüz bir şey yok — mağazaya bakın';

  @override
  String get inventoryFrames => 'Çerçeveler';

  @override
  String get inventoryClaim => 'Al';

  @override
  String get inventorySell => 'Sat';

  @override
  String get inventoryGift => 'Hediye et';

  @override
  String get messageEdited => 'düzenlendi';

  @override
  String get messageDeleted => 'Mesaj silindi';

  @override
  String get photo => 'Fotoğraf';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galeri';

  @override
  String get connectionError => 'Sunucuya bağlanılamadı.';

  @override
  String get serverError => 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';

  @override
  String get sessionExpired => 'Oturum süresi doldu. Lütfen tekrar giriş yapın.';

  @override
  String get errNoInternet => 'İnternet bağlantısı yok.';

  @override
  String get errTimeout => 'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.';

  @override
  String get errGamesUnavailable => 'Oyunlar geçici olarak kullanılamıyor';

  @override
  String get errSettingsSaveFailed => 'Ayar kaydedilemedi';

  @override
  String get errPushPermission => 'Tarayıcı veya sistem ayarlarından bildirimlere izin verin.';

  @override
  String get balanceTitle => 'Bakiye';

  @override
  String get coinBronze => 'Bronz';

  @override
  String get coinSilver => 'Gümüş';

  @override
  String get coinGold => 'Altın';

  @override
  String get coinDiamond => 'Elmas';

  @override
  String get balanceZeroBronze => '0 bronz';

  @override
  String balanceBronzes(int count) {
    return '$count bronz';
  }

  @override
  String balanceSilvers(int count) {
    return '$count gümüş';
  }

  @override
  String balanceGolds(int count) {
    return '$count altın';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count elmas';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/gün';
  }

  @override
  String get balanceAbbrBronze => 'br';

  @override
  String get balanceAbbrSilver => 'g.';

  @override
  String get balanceAbbrGold => 'a.';

  @override
  String get commonBackHome => 'Ana sayfaya dön';

  @override
  String get commonCopied => 'Kopyalandı';

  @override
  String get commonClear => 'Temizle';

  @override
  String get commonTryLater => 'Daha sonra tekrar deneyin.';

  @override
  String get commonTryRefresh => 'Sayfayı yenilemeyi deneyin.';

  @override
  String get coinsTitle => 'Jetonlar';

  @override
  String get coinsLoginReward => 'Giriş ödülü';

  @override
  String get coinsLoginAvailableToday => 'Bugünün ödülü hazır';

  @override
  String get coinsLoginStreak => 'Günlük giriş serisi';

  @override
  String get coinsFriendReward => 'Arkadaş ödülü';

  @override
  String coinsFriendRewardHint(String amount) {
    return 'Bağlantınızla kayıt için +$amount';
  }

  @override
  String get coinsLoadRewardsFailed => 'Ödüller yüklenemedi';

  @override
  String get coinsClaimReward => 'Ödülü al';

  @override
  String get coinsAlreadyClaimed => 'Zaten alındı';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · bugün';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · 1 gün kaldı';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · $remaining kaldı';
  }

  @override
  String get coinsInviteFriend => 'Arkadaş davet et';

  @override
  String coinsInviteHint(String amount) {
    return 'Bağlantınızla kaydolan herkes için +$amount';
  }

  @override
  String get coinsCopyLink => 'Bağlantıyı kopyala';

  @override
  String get coinsHowItWorks => 'Nasıl çalışır';

  @override
  String get coinsHowStep1 => 'Bağlantıyı kopyalayıp arkadaşına gönder';

  @override
  String get coinsHowStep2 => 'Arkadaşın bu bağlantıyla kaydolur';

  @override
  String coinsHowStep3(String amount) {
    return '$amount kazanırsın';
  }

  @override
  String get achievementsTitle => 'Başarımlar';

  @override
  String achievementsProgress(String progress) {
    return 'İlerleme: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Çerçeve alındı';

  @override
  String get achievementsClaimed => 'Alındı';

  @override
  String get achievementsOpenFrame => 'Çerçeveyi aç';

  @override
  String friendsRemoveConfirm(String name) {
    return '$name adlı kişiyi arkadaşlardan kaldırmak istediğine emin misin?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Kaldır';

  @override
  String get friendsRemove => 'Arkadaşlardan kaldır';

  @override
  String get friendsAcceptRequest => 'İsteği kabul et';

  @override
  String get friendsDeclineRequest => 'İsteği reddet';

  @override
  String get friendsCancelRequest => 'İsteği iptal et';

  @override
  String get friendsSendRequest => 'Arkadaşlık isteği gönder';

  @override
  String get friendsRequestAlreadySent => 'İstek zaten gönderildi';

  @override
  String get friendsIncomingStatus => 'Gelen istek';

  @override
  String get friendsOutgoingStatus => 'Giden istek';

  @override
  String get friendsNotFriends => 'Arkadaş değilsiniz';

  @override
  String get friendsCollapseSearch => 'Aramayı gizle';

  @override
  String get friendsExpandSearch => 'Aramayı göster';

  @override
  String get friendsLoadFailed => 'Arkadaşlar yüklenemedi';

  @override
  String friendsSince(String date) {
    return 'Arkadaşlık tarihi: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Gelen istek: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Giden istek: $date';
  }

  @override
  String get userInfoTitle => 'Kullanıcı bilgisi';

  @override
  String profileAgeYears(int age) {
    return '$age yaş';
  }

  @override
  String get shopBuy => 'Satın al';

  @override
  String get shopBuyTitle => 'Satın al?';

  @override
  String get shopBuyStakeTitle => 'Bahis satın al?';

  @override
  String get shopBuyEmojiTitle => 'Emoji satın al?';

  @override
  String get shopBuyCollectionTitle => 'Koleksiyon satın al?';

  @override
  String shopPrice(String price) {
    return 'Fiyat: $price';
  }

  @override
  String get shopOwned => 'Satın alındı';

  @override
  String get shopEmpty => 'Henüz boş';

  @override
  String shopPurchased(String title) {
    return '$title satın alındı';
  }

  @override
  String get shopEmojiUses => 'Alırsınız: 10 kullanım';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 kullanım';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 kullanım';
  }

  @override
  String get shopBuyTen => 'Satın al · 10 adet';

  @override
  String shopDailyIncome(String amount) {
    return 'Gelir: $amount';
  }

  @override
  String get shopBuyOnce => 'Tek seferlik satın alma';

  @override
  String get shopSellRefund => 'Satış maliyetin %80\'ini iade eder';

  @override
  String shopCollectionAdded(String title) {
    return '$title profile eklendi';
  }

  @override
  String shopSetBonus(int percent) {
    return 'set bonusu +%$percent';
  }

  @override
  String get shopSetComplete => 'Tamamlandı';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Toplandı · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Sat?';

  @override
  String inventorySellDesc(String amount) {
    return '$amount alacaksınız';
  }

  @override
  String inventorySold(String amount) {
    return 'Satıldı: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Önce arkadaş ekleyin';

  @override
  String get inventoryGiftTitle => 'Koleksiyon hediye et?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return '«$title» koleksiyonunu $name kullanıcısına hediye et?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Hediye edildi: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'Oyuncu bu öğeye zaten sahip';

  @override
  String get inventoryGiftSelf => 'Kendinize hediye veremezsiniz';

  @override
  String get inventoryGiftNotOwned => 'Bu öğe envanterinizde yok';

  @override
  String get inventoryLoadFailed => 'Öğeler yüklenemedi';

  @override
  String get inventoryNoCollections => 'Koleksiyon yok — mağazadan satın alın';

  @override
  String get inventoryNoEmojis => 'Emoji yok — mağazadan satın alın';

  @override
  String get inventoryNoFrames => 'Çerçeve yok — ligde 10 oyun kazanın (başarımlar)';

  @override
  String get inventoryNoStakes => 'Satın alınmış bahis yok';

  @override
  String inventoryEmojiLeft(int count) {
    return '$count kaldı';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Gelir: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Yarınki gelir: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Hazır';

  @override
  String get inventoryIncomeTomorrowLabel => 'Yarın';

  @override
  String inventoryStakeGold(String amount) {
    return '$amount altın bahis koyabilirsiniz';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return '$amount gümüş bahis koyabilirsiniz';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return '+$amount alındı';
  }

  @override
  String get chatsLoadFailed => 'Sohbetler yüklenemedi';

  @override
  String get chatsLoadListFailed => 'Liste yüklenemedi';

  @override
  String get chatsBlockedEmpty => 'Liste boş';

  @override
  String chatsBlockedAt(String date) {
    return 'Engellendi: $date';
  }

  @override
  String get chatsCreateFailed => 'Sohbet oluşturulamadı';

  @override
  String get chatsNeedFriendsFirst => 'Önce arkadaş ekleyin, sonra sohbet açabilirsiniz.';

  @override
  String get chatsFriendsNotFound => 'Arkadaş bulunamadı';

  @override
  String get chatsFindFriendHint => 'Takma ada göre arkadaş bul';

  @override
  String get chatsSelectChat => 'Bir sohbet seçin';

  @override
  String get chatsSelectHint => 'Soldaki listeden bir konuşma seçin';

  @override
  String get chatEditFailed => 'Mesaj düzenlenemedi';

  @override
  String get chatSendFailed => 'Mesaj gönderilemedi';

  @override
  String get chatDeleteFailed => 'Mesaj silinemedi';

  @override
  String get chatEmojiSendFailed => 'Emoji gönderilemedi';

  @override
  String get chatLoadFailed => 'Mesajlar yüklenemedi';

  @override
  String get chatBackToGame => 'Oyuna dön';

  @override
  String get chatBackToChats => 'Sohbetlere dön';

  @override
  String get chatActions => 'Sohbet işlemleri';

  @override
  String get chatAutoTranslate => 'Otomatik çeviri';

  @override
  String get chatScrollToEnd => 'Konuşmanın sonuna git';

  @override
  String chatReplyingTo(String name) {
    return '$name yanıtlanıyor';
  }

  @override
  String get chatGift => 'Hediye';

  @override
  String get chatCollection => 'Koleksiyon';

  @override
  String get chatGiftCollection => 'Hediye · koleksiyon';

  @override
  String get chatThisUser => 'bu kullanıcı';

  @override
  String get gamesLobbyLoadFailed => 'Lobi yüklenemedi.';

  @override
  String get gamesTapChangeStake => 'Bahisi değiştirmek için dokunun';

  @override
  String get gamesTapChangeTurnTime => 'Hamle süresini değiştirmek için dokunun';

  @override
  String get gamesTapChangeGrid => 'Izgara boyutunu değiştirmek için dokunun';

  @override
  String get gamesSwapSidesHint => 'O, 1. hamleden sonra X olabilir';

  @override
  String get gamesNoCenterHint => 'İlk hamle ortada olamaz';

  @override
  String get lobbyInviteSentShort => 'Gönderildi';

  @override
  String get lobbyInvitesSentWaiting => 'Davetler gönderildi. Yanıt bekleniyor.';

  @override
  String get lobbyLinkCopiedHint => 'Bir sohbete veya arkadaş mesajına yapıştırın';

  @override
  String get lobbyCopyLinkHint => 'Bağlantıyı panoya kopyala';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name sizi oynamaya davet ediyor';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name kazandı';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Süre doldu. $name kazandı';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds sn';
  }

  @override
  String get adminTitle => 'Yönetim';

  @override
  String get tournamentsTitle => 'Turnuvalar';

  @override
  String get profileAgeInvalid => '1 ile 111 arasında bir yaş girin';

  @override
  String get profileSaveFailed => 'Profil kaydedilemedi';

  @override
  String get profileNameHint => 'Latin harfler, rakamlar, _ en fazla 10 karakter';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => '1 ile 111 arası';

  @override
  String get profileAboutHint => 'En fazla 100 karakter (isteğe bağlı)';

  @override
  String get profileProcessingPhoto => 'Fotoğraf işleniyor…';

  @override
  String get profileCropTitle => 'Avatar alanını seç';

  @override
  String get profileCropHint => 'Fotoğrafı yakınlaştır ve taşı';

  @override
  String get profileApply => 'Uygula';

  @override
  String get profilePreparing => 'Hazırlanıyor…';

  @override
  String get profileGalleryTitle => 'Fotoğraflar';

  @override
  String get profileGalleryAdd => 'Fotoğraf ekle';

  @override
  String get profileMakePrimary => 'Ana fotoğraf yap';

  @override
  String get profilePhotoDelete => 'Fotoğrafı sil';

  @override
  String get profilePhotosLimit => 'En fazla 3 fotoğraf yükleyebilirsiniz';

  @override
  String get profilePhotosEmpty => 'Henüz fotoğraf yok';

  @override
  String get profilePhotoUploadFailed => 'Fotoğraf yüklenemedi';

  @override
  String get profilePhotoDeleteFailed => 'Fotoğraf silinemedi';

  @override
  String get profilePhotoTooLarge => 'Fotoğraf çok büyük';

  @override
  String get profileSetPrimaryFailed => 'Ana fotoğraf yapılamadı';

  @override
  String timeSecondsShort(int seconds) {
    return '$seconds sn';
  }

  @override
  String get timeOneMin => '1 dk';

  @override
  String get timeTenMin => '10 dk';

  @override
  String rulesIntro(String grid) {
    return '$grid tahtasında XOX. Sırayla oynanır; X başlar.';
  }

  @override
  String rulesWin(int n) {
    return 'Zafer: yatay, dikey veya çapraz $n’yi sıraya dizin.';
  }

  @override
  String get rulesNoTimeLimit => 'Hamle başına süre sınırı yok.';

  @override
  String rulesTurnTime(String time) {
    return 'Hamle süresi: $time. Süre dolarsa yenilirsiniz.';
  }

  @override
  String rulesStake(String stake) {
    return 'Bahis: $stake. Oyun bu kadar jeton içindir.';
  }

  @override
  String get rulesSwap => 'Taraf değişimi: X’in ilk hamlesinden sonra O, X ile yer değiştirebilir.';

  @override
  String get rulesNoCenter => 'Merkez yasağı: X ilk hamlede merkeze oynayamaz.';

  @override
  String get collectionSetLegends => 'Efsaneler';

  @override
  String get collectionSetSpace => 'Uzay';

  @override
  String get collectionSetGems => 'Mücevherler';

  @override
  String get collectionSetParty => 'Parti';

  @override
  String get collectionSetNature => 'Doğa';

  @override
  String get collectionSetAdventures => 'Maceralar';

  @override
  String collectionCardMeta(String amount) {
    return 'Koleksiyon · vitrin · hediye · satış · +$amount';
  }

  @override
  String get coinsDayOne => 'gün';

  @override
  String get coinsDayFew => 'gün';

  @override
  String get coinsDayMany => 'gün';

  @override
  String get giftFriendTitle => 'Arkadaşa hediye et';

  @override
  String photoCount(int count) {
    return 'Fotoğraf ($count)';
  }

  @override
  String photoCountWithText(int count, String text) {
    return 'Fotoğraf ($count): $text';
  }

  @override
  String photoWithText(String text) {
    return 'Fotoğraf: $text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count emoji · $price';
  }

  @override
  String get chatsExpandPanel => 'Paneli genişlet';

  @override
  String get chatsCollapsePanel => 'Paneli daralt';

  @override
  String get chatReplySourceMissing => 'Orijinal mesaj bulunamadı';

  @override
  String shopStakeTitleSilver(int n) {
    return '$n gümüş bahis';
  }

  @override
  String shopStakeTitleGold(int n) {
    return '$n altın bahis';
  }

  @override
  String shopStakeDescSilver(int n) {
    return '$n gümüş bahis hakkını açar';
  }

  @override
  String shopStakeDescGold(int n) {
    return '$n altın bahis hakkını açar';
  }

  @override
  String get chatReplySelf => 'kendine';

  @override
  String get chatReplyPeer => 'karşı tarafa';

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
  String get statsTitle => 'İstatistikler';

  @override
  String get statsLoadFailed => 'İstatistikler yüklenemedi';

  @override
  String get statsAllGames => 'Tüm oyunlar';

  @override
  String get statsEmptyTitle => 'Henüz oynanan maç yok';

  @override
  String get statsEmptyHint => 'İstatistikleri burada görmek için ilk oyununuzu oynayın.';

  @override
  String get statsWins => 'Galibiyetler';

  @override
  String get statsDraws => 'Beraberlikler';

  @override
  String get statsLosses => 'Mağlubiyetler';

  @override
  String get statsWinRate => 'Galibiyet oranı';

  @override
  String get statsTopWon => 'En çok galibiyet alınan';

  @override
  String get statsTopDrawn => 'En çok beraberlik';

  @override
  String get statsTopLost => 'En çok mağlubiyet alınan';

  @override
  String get statsTimePlayed => 'Oyun süresi';

  @override
  String get statsYourScore => 'Skorunuz';

  @override
  String get profileShowStats => 'İstatistikleri göster';

  @override
  String get statsDurationZeroMinutes => '0 dk';

  @override
  String get gameYouWonOpponentForfeit => 'Rakip teslim oldu. Kazandınız!';

  @override
  String get lobbyLeaveTitle => 'Lobiden çıkılsın mı?';

  @override
  String get lobbyLeaveConfirm => 'Çıktıktan sonra lobi silinecek. Davet edilen arkadaşlar red alacak.';

  @override
  String get lobbyLeave => 'Ayrıl';

  @override
  String statsDurationHours(int hours) {
    return '$hours sa';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes dk';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'Teslim oldunuz. $name kazandı';
  }

  @override
  String get supportTitle => 'Destek';

  @override
  String get supportUnavailable => 'Destek kullanılamıyor';

  @override
  String get supportOpenFailed => 'Destek sohbeti açılamadı';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Hesabınıza $amount jeton eklendi';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return '$amount jeton düşüldü';
  }

  @override
  String get coinsCreditCardTitle => 'Hesabınıza jeton eklendi';

  @override
  String get coinsClaim => 'Al';

  @override
  String get durakActionPass => 'Pas';

  @override
  String get durakRoleTook => 'Aldı';

  @override
  String get durakRoleBeats => 'Vuruyor';

  @override
  String get durakRoleThrowIn => 'Atış';

  @override
  String get durakRoleTurn => 'Sıra';

  @override
  String get durakRoleDefends => 'Savunuyor';

  @override
  String get durakStatusTaking => 'Alıyor';

  @override
  String get durakHintDefenderTurn => 'Savunanın sırası';

  @override
  String get gameYouEliminated => 'Elendiniz';

  @override
  String gameYouPlaced(int place) {
    return '$place. oldunuz';
  }

  @override
  String get gameOverNeutral => 'Oyun bitti';

  @override
  String gameTurnOf(String name) {
    return '$name sırası';
  }

  @override
  String get chatGroupTooltip => 'Grup sohbeti';

  @override
  String get lobbyChatNotReady => 'Lobi sohbeti henüz hazır değil';

  @override
  String get chatsGroupChat => 'Grup sohbeti';

  @override
  String chatsMembersCount(int count) {
    return 'Üyeler: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count kişi';
  }

  @override
  String get chatsYouSuffix => '(sen)';

  @override
  String get chatTitleDurak3 => 'Durak · 3 oyuncu';

  @override
  String get chatTitleDurak4 => 'Durak · 4 oyuncu';

  @override
  String get rulesTttUltimate => 'Ultimate: dokuz 3×3 mini tahta. Hamle rakibi o mini tahtaya gönderir. Meta tahtada çizgi tamamlayan kazanır.';

  @override
  String get rulesTttMulti3 => '3 oyuncu: 3×3 tahta, üç oyuncu (X, O, △). Kendi işaretlerinizle çizgi tamamlayın.';

  @override
  String get rulesTttMulti4 => '4 oyuncu: 4×4 tahta, dört oyuncu (X, O, △, □). Kendi işaretlerinizle çizgi tamamlayın.';
}
