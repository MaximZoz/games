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
  String get settingsAddBotsTitle => '30 sn sonra bot ekle';

  @override
  String get settingsAddBotsSubtitle => 'Eşleştirmede: 30 saniye içinde rakip bulunamazsa oyun botla başlar (bahis 1 bronza sıfırlanır)';

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
  String get timeJustNow => 'az önce';

  @override
  String get timeYesterday => 'dün';

  @override
  String timeMinutesAgo(Object count) {
    return '$count dk önce';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count sa önce';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count g önce';
  }

  @override
  String get timeWeekAgo => 'bir hafta önce';

  @override
  String timeWeeksAgo(Object count) {
    return '$count hf önce';
  }

  @override
  String get timeMonthAgo => 'bir ay önce';

  @override
  String timeMonthsAgo(Object count) {
    return '$count ay önce';
  }

  @override
  String get timeYearAgo => 'bir yıl önce';

  @override
  String timeYearsAgo(Object count) {
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
  String get lobbyMatchmake => 'Lobi';

  @override
  String get lobbyPrivateGame => 'Özel oyun';

  @override
  String get lobbySearchingOpponent => 'Rakip aranıyor…';

  @override
  String get lobbyWaitingJoin => 'Birinin «Oyun bul» veya «Katıl»a basması bekleniyor';

  @override
  String get lobbyInviteTitle => 'Oyun daveti';

  @override
  String get lobbyInvitedToPlay => 'Oynamaya davet edildiniz';

  @override
  String get lobbyEnterGame => 'Oyuna gir';

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
  String get profileChangePhoto => 'Fotoğrafı değiştir';

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
  String get shopStakesSubtitle => 'Gümüş bahisleri açın';

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
}
