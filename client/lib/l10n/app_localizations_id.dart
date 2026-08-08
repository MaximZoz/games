import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Beranda';

  @override
  String get navProfile => 'Profil';

  @override
  String get navFriends => 'Teman';

  @override
  String get navChats => 'Obrolan';

  @override
  String get navGames => 'Game';

  @override
  String get navSettings => 'Pengaturan';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsLanguageSystem => 'Default sistem';

  @override
  String get settingsAddBotsTitle => 'Tambah bot setelah 30 dtk';

  @override
  String get settingsAddBotsSubtitle => 'Saat matchmaking: jika lawan tidak ditemukan dalam 30 detik, game dimulai dengan bot (taruhan direset ke 1 perunggu)';

  @override
  String get settingsOfflineModeTitle => 'Mode jaringan';

  @override
  String get settingsOfflineModeSubtitle => 'Offline: main bot segera, tanpa taruhan dan hadiah, tanpa obrolan dan teman. Pembelian disimpan dan diterapkan di mode online. Online — saat ada internet atau sesuai pengaturan pengguna.';

  @override
  String get settingsModeOnline => 'Online';

  @override
  String get settingsModeOffline => 'Offline';

  @override
  String get gamesAlternateStartsHint => 'Bergiliran siapa yang memulai partai';

  @override
  String get rulesAlternateStarts => 'Siapa yang jalan duluan bergantian tiap partai.';

  @override
  String get offlineBadgeTooltip => 'Mode offline';

  @override
  String get offlineModePopupTitle => 'Mode offline';

  @override
  String get offlineModePopupBody => 'Mode offline aktif. Main bot tanpa taruhan dan hadiah. Obrolan, teman, dan lobi disembunyikan. Pembelian diterapkan di mode online.';

  @override
  String get offlineModePopupSettings => 'Pengaturan';

  @override
  String get gamesPlay => 'Main';

  @override
  String get offlineGameTitle => 'Main lawan bot';

  @override
  String get offlineGameHint => 'Tanpa taruhan dan hadiah · hanya offline';

  @override
  String get offlineBotWon => 'Bot menang';

  @override
  String get offlineBotThinking => 'Bot berpikir…';

  @override
  String get offlinePlayAgain => 'Main lagi';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'Take';

  @override
  String get durakActionAll => 'All';

  @override
  String get durakActionDone => 'Done';

  @override
  String get durakActionBito => 'Beat';

  @override
  String get durakHintDefend => 'Defend';

  @override
  String get durakHintDefendOrTransfer => 'Defend or transfer';

  @override
  String get durakHintOpponentDefends => 'Opponent is defending';

  @override
  String get durakHintThrowInFirst => 'Throw in cards or tap “All” (max 5 on the first beat)';

  @override
  String get durakHintThrowIn => 'Throw in cards or tap “All”';

  @override
  String get durakHintOpponentThrows => 'Opponent is throwing in';

  @override
  String get durakHintTakeFollow => 'Throw in after take or tap “Done”';

  @override
  String get durakHintOpponentTakeFollow => 'Opponent may throw in after take';

  @override
  String get durakHintBito => 'Throw in a card or say “Beat”';

  @override
  String get durakHintOpponentBito => 'Opponent throws in or says “Beat”';

  @override
  String get durakHintYourAttack => 'Your turn — attack';

  @override
  String get durakHintOpponentAttack => 'Opponent is attacking';

  @override
  String get durakHintYouLost => 'You lost — you’re the fool';

  @override
  String get durakHintDrawAllOut => 'Draw — everyone went out';

  @override
  String get durakHintYouFinished => 'You’re out — waiting for the end';

  @override
  String get shopPurchaseQueued => 'Pembelian disimpan — akan diterapkan di mode online';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — pembelian diterapkan';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — pembelian tidak diterapkan: $reason';
  }

  @override
  String get settingsFriendsOnlyTitle => 'Pesan hanya dari teman';

  @override
  String get settingsFriendsOnlySubtitle => 'Non-teman hanya bisa mengirim emoji. Jika spam jadi masalah, blokir pengguna sementara.';

  @override
  String get settingsNotifications => 'Notifikasi';

  @override
  String get settingsPushChat => 'Obrolan';

  @override
  String get settingsPushFriends => 'Teman';

  @override
  String get settingsPushGames => 'Game';

  @override
  String get settingsPushRewards => 'Hadiah';

  @override
  String settingsAppVersion(String version) {
    return 'Version $version';
  }

  @override
  String get appUpdateTitle => 'Update available';

  @override
  String get appUpdateBody => 'A new version of the app is available. Please update to continue.';

  @override
  String get appUpdateWhatsNew => 'What\'s new';

  @override
  String get appUpdateOk => 'Update';

  @override
  String get appUpdateLaterBanner => 'We\'ll update the app after this game';

  @override
  String get loginTitle => 'Masuk';

  @override
  String get loginSubtitle => 'Masukkan email atau nama pengguna dan kata sandi';

  @override
  String get loginEmailLabel => 'Email atau nama pengguna';

  @override
  String get loginPasswordLabel => 'Kata sandi';

  @override
  String get loginSubmit => 'Masuk';

  @override
  String get loginNoAccount => 'Belum punya akun? Daftar';

  @override
  String get loginEmailRequired => 'Masukkan email atau nama pengguna';

  @override
  String get loginPasswordRequired => 'Masukkan kata sandi';

  @override
  String get loginTooltip => 'Masuk';

  @override
  String get logoutTooltip => 'Keluar';

  @override
  String get registerTitle => 'Daftar';

  @override
  String get registerSubtitle => 'Buat akun untuk bermain';

  @override
  String get registerNameLabel => 'Nama (nama pengguna)';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'Kata sandi';

  @override
  String get registerSubmit => 'Daftar';

  @override
  String get registerHaveAccount => 'Sudah punya akun? Masuk';

  @override
  String get registerNameRequired => 'Masukkan nama';

  @override
  String get registerNameNoSpaces => 'Nama tidak boleh berisi spasi';

  @override
  String get registerNameMax => 'Maksimal 20 karakter';

  @override
  String get registerNameHint => 'Hingga 20 karakter';

  @override
  String get registerEmailRequired => 'Masukkan email';

  @override
  String get registerEmailInvalid => 'Email tidak valid';

  @override
  String get registerPasswordHint => 'Minimal 6 karakter';

  @override
  String get registerPasswordMin => 'Kata sandi minimal 6 karakter';

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonSave => 'Simpan';

  @override
  String get commonDelete => 'Hapus';

  @override
  String get commonEdit => 'Ubah';

  @override
  String get commonReply => 'Balas';

  @override
  String get commonSend => 'Kirim';

  @override
  String get commonClose => 'Tutup';

  @override
  String get commonRetry => 'Coba lagi';

  @override
  String get commonLoading => 'Memuat…';

  @override
  String get commonError => 'Kesalahan';

  @override
  String get commonOnline => 'daring';

  @override
  String get commonOffline => 'luring';

  @override
  String get commonOnlineCap => 'Daring';

  @override
  String get commonUser => 'Pengguna';

  @override
  String get commonPlayer => 'Pemain';

  @override
  String get commonAboutMe => 'Tentang saya';

  @override
  String get commonBack => 'Kembali';

  @override
  String get commonAccept => 'Terima';

  @override
  String get commonDecline => 'Tolak';

  @override
  String get commonCreating => 'Membuat…';

  @override
  String get commonSearching => 'Mencari…';

  @override
  String get commonInsufficientCoins => 'Koin tidak cukup';

  @override
  String get commonNotFound => 'Tidak ditemukan';

  @override
  String get commonServerErrorShort => 'Error server';

  @override
  String get commonForbidden => 'Akses ditolak';

  @override
  String get commonUserBlocked => 'Pengguna diblokir';

  @override
  String get commonUserNotFound => 'Pengguna tidak ditemukan';

  @override
  String get commonGenericError => 'Terjadi kesalahan. Silakan coba lagi.';

  @override
  String get timeJustNow => 'baru saja';

  @override
  String get timeYesterday => 'kemarin';

  @override
  String timeMinutesAgo(int count) {
    return '$count mnt lalu';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count jam lalu';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count hr lalu';
  }

  @override
  String get timeWeekAgo => 'seminggu lalu';

  @override
  String timeWeeksAgo(int count) {
    return '$count mgg lalu';
  }

  @override
  String get timeMonthAgo => 'sebulan lalu';

  @override
  String timeMonthsAgo(int count) {
    return '$count bln lalu';
  }

  @override
  String get timeYearAgo => 'setahun lalu';

  @override
  String timeYearsAgo(int count) {
    return '$count thn lalu';
  }

  @override
  String get weekdaySun => 'Min';

  @override
  String get weekdayMon => 'Sen';

  @override
  String get weekdayTue => 'Sel';

  @override
  String get weekdayWed => 'Rab';

  @override
  String get weekdayThu => 'Kam';

  @override
  String get weekdayFri => 'Jum';

  @override
  String get weekdaySat => 'Sab';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'Mei';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Agu';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Okt';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Des';

  @override
  String get homeAchievements => 'Pencapaian';

  @override
  String get homeAchievementsSubtitle => 'Hasil game Anda';

  @override
  String get homeAchievementsRewards => 'Ada hadiah yang bisa diklaim';

  @override
  String get homeCoins => 'Koin';

  @override
  String get homeCoinsSubtitle => 'Saldo dan hadiah';

  @override
  String get homeCoinsDailyReward => 'Hadiah login harian tersedia';

  @override
  String get homeItems => 'Item';

  @override
  String get homeItemsInventory => 'Inventaris Anda';

  @override
  String get homeItemsGifted => 'Seseorang memberi Anda koleksi';

  @override
  String get homeItemsIncome => 'Pendapatan koleksi siap diklaim';

  @override
  String get homeShop => 'Toko';

  @override
  String get homeShopSubtitle => 'Emoji, taruhan, koleksi';

  @override
  String get gamesTitle => 'Game';

  @override
  String get gamesFindMatch => 'Cari game';

  @override
  String get gamesMyTurn => 'Giliran Anda';

  @override
  String get gamesWaiting => 'Menunggu';

  @override
  String get gamesLobbyTab => 'Lobi';

  @override
  String get gamesTicTacToe => 'XOX';

  @override
  String get gamesDurak => 'Durak';

  @override
  String get gamesRules => 'Aturan';

  @override
  String get gamesRulesTitle => 'Aturan game';

  @override
  String get gamesCreate => 'Buat game';

  @override
  String get gamesJoin => 'Gabung';

  @override
  String get gamesOpponentTurn => 'Giliran lawan';

  @override
  String get gamesCurrentGame => 'Game saat ini';

  @override
  String get gamesInvitedYou => 'Anda diundang';

  @override
  String get gamesTurnTime => 'Waktu giliran';

  @override
  String get gamesGridSize => 'Ukuran papan';

  @override
  String get gamesSwapSides => 'Tukar sisi';

  @override
  String get gamesNoCenter => 'Tanpa mulai di tengah';

  @override
  String get gamesObservation => 'Spectating';

  @override
  String get gamesObservationHint => 'You can watch until the game ends';

  @override
  String get gamesFinishCurrentFirst => 'Finish your current game first';

  @override
  String get gamesVariantClassic => 'Classic';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 players';

  @override
  String get gamesVariantMulti4 => '4 players';

  @override
  String get gamesDurakModePodkidnoi => 'Throw-in';

  @override
  String get gamesDurakModePerevodnoi => 'Transfer';

  @override
  String get gamesDurakDeck24 => '24 cards';

  @override
  String get gamesDurakDeck36 => '36 cards';

  @override
  String get gamesDurakDeck52 => '52 cards';

  @override
  String rulesDurakMode(String mode) {
    return 'Mode: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'Players: $players. Deck: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Play against a bot, no stakes or turn timer.';

  @override
  String get rulesDurakAttack => 'The attacker plays cards; the defender beats them (same suit higher, or a trump). A trump is beaten only by a higher trump.';

  @override
  String get rulesDurakBeat => 'When all cards are beaten, the attacker says “Beat” and cards go to the discard. Otherwise the defender takes everything from the table.';

  @override
  String get rulesDurakLoser => 'The loser is the one left with cards at the end — the “fool”.';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Players $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Lobby $name';
  }

  @override
  String get lobbyMatchmake => 'Lobi';

  @override
  String get lobbyPrivateGame => 'Game pribadi';

  @override
  String get lobbySearchingOpponent => 'Mencari lawan…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Mencari permainan ini: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Menunggu seseorang mengetuk “Cari game” atau “Gabung”';

  @override
  String get lobbyInviteTitle => 'Undangan game';

  @override
  String get lobbyInvitedToPlay => 'Anda diundang untuk bermain';

  @override
  String get lobbyEnterGame => 'Masuk game';

  @override
  String get lobbyGone => 'Lobi tidak lagi tersedia';

  @override
  String get lobbyInvite => 'Undang';

  @override
  String get lobbyInviteSent => 'Undangan terkirim';

  @override
  String get lobbyCopyLink => 'Bagikan tautan game';

  @override
  String get lobbyLinkCopied => 'Tautan disalin';

  @override
  String get lobbyNoFriendsOnline => 'Tidak ada teman online. Bagikan tautan game di atas atau tunggu teman online.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Lawan';

  @override
  String get gameYouWon => 'Anda menang!';

  @override
  String get gameYouWonOpponentLeft => 'Anda menang — lawan keluar';

  @override
  String get gameYouWonOpponentTimeout => 'Anda menang — lawan kehabisan waktu';

  @override
  String get gameDraw => 'Seri';

  @override
  String get gameExitTitle => 'Keluar dari game';

  @override
  String get gameExitConfirm => 'Jika keluar, Anda kalah. Tetap keluar?';

  @override
  String get gameStay => 'Tetap';

  @override
  String get gameLeave => 'Keluar';

  @override
  String get gameSurrender => 'Menyerah';

  @override
  String get gameSurrenderTitle => 'Menyerah?';

  @override
  String get gameSurrenderConfirm => 'Anda akan kalah partai dan koin taruhan.';

  @override
  String get gameOfferDraw => 'Tawarkan seri';

  @override
  String get gameOfferDrawTitle => 'Tawarkan seri?';

  @override
  String get gameOfferDrawConfirm => 'Lawan menyerah bisa menerima atau menolak seri.';

  @override
  String get gameAcceptDrawTitle => 'Terima seri?';

  @override
  String get gameAcceptDrawConfirm => 'Partai akan berakhir seri.';

  @override
  String get gameDrawOffered => 'Lawan menawarkan seri';

  @override
  String get gameConnecting => 'Menghubungkan ke game…';

  @override
  String get gameWaitingOpponent => 'Menunggu lawan';

  @override
  String get gameRematchOffer => 'Lawan menawarkan main lagi';

  @override
  String get gameRematchDeclined => 'Lawan menolak main lagi';

  @override
  String get gameRematch => 'Main lagi';

  @override
  String get gameOtherOpponent => 'Lawan lain';

  @override
  String get gameSwapSidesAction => 'Tukar sisi';

  @override
  String get gameWriteMessage => 'Tulis pesan';

  @override
  String get chatsTitle => 'Obrolan';

  @override
  String get chatsEmpty => 'Belum ada obrolan.\nKetuk ikon di kanan atas untuk memilih teman dan mulai percakapan.';

  @override
  String get chatsNewChat => 'Obrolan baru';

  @override
  String get chatsNoMessages => 'Tidak ada pesan';

  @override
  String get chatsClearTitle => 'Hapus percakapan?';

  @override
  String get chatsClearDesc => 'Obrolan akan dihapus permanen.';

  @override
  String get chatsClearConfirm => 'Hapus';

  @override
  String get chatsBlockTitle => 'Blokir pengguna ini?';

  @override
  String get chatsBlockDesc => 'Anda tidak lagi bisa saling mengirim pesan. Obrolan dan pertemanan akan dihapus.';

  @override
  String get chatsBlockConfirm => 'Blokir';

  @override
  String get chatsBlockedUsers => 'Pengguna diblokir';

  @override
  String get chatsUnblock => 'Buka blokir';

  @override
  String get chatDialog => 'Obrolan';

  @override
  String get chatEmpty => 'Belum ada pesan.\nKirim yang pertama.';

  @override
  String get chatMessageHint => 'Pesan';

  @override
  String get chatPaste => 'Tempel';

  @override
  String get chatEmoji => 'Emoji';

  @override
  String get chatBuyEmojiHint => 'Beli emoji di toko di beranda';

  @override
  String get chatEditing => 'Mengedit';

  @override
  String get chatToday => 'Hari ini';

  @override
  String get chatYesterday => 'Kemarin';

  @override
  String get chatFriendsOnly => 'Teks hanya untuk teman';

  @override
  String get emojiGroupEmotions => 'Emosi';

  @override
  String get emojiGroupGame => 'Permainan';

  @override
  String get emojiGroupFlags => 'Bendera';

  @override
  String get emojiGroupAnimals => 'Hewan';

  @override
  String get emojiGroupFood => 'Makanan';

  @override
  String get emojiGroupTravel => 'Perjalanan';

  @override
  String get emojiGroupParty => 'Perayaan';

  @override
  String get emojiGroupObjects => 'Objek';

  @override
  String get friendsTitle => 'Teman';

  @override
  String get friendsTabFriends => 'Teman';

  @override
  String get friendsTabIncoming => 'Masuk';

  @override
  String get friendsTabOutgoing => 'Keluar';

  @override
  String get friendsAdd => 'Tambah teman';

  @override
  String get friendsRequestSent => 'Permintaan terkirim';

  @override
  String get friendsFindTab => 'Cari teman';

  @override
  String get friendsSearchHint => 'Cari berdasarkan nama pengguna';

  @override
  String get friendsSearchPrompt => 'Gunakan pencarian untuk menemukan teman baru';

  @override
  String get friendsNothingFound => 'Tidak ditemukan';

  @override
  String get friendsEmpty => 'Anda belum punya teman';

  @override
  String get friendsNoIncoming => 'Tidak ada permintaan masuk';

  @override
  String get friendsNoOutgoing => 'Tidak ada permintaan keluar';

  @override
  String get friendsAlreadyFriends => 'Sudah berteman';

  @override
  String get friendsRemoveTitle => 'Hapus dari teman?';

  @override
  String get friendsRemoved => 'Dihapus dari teman';

  @override
  String get friendsRequestAccepted => 'Permintaan diterima';

  @override
  String get friendsRequestDeclined => 'Permintaan ditolak';

  @override
  String get friendsRequestCancelled => 'Permintaan dibatalkan';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSignInPrompt => 'Masuk ke akun Anda';

  @override
  String get profileSignInHint => 'Untuk mengatur profil pribadi';

  @override
  String get profileEdit => 'Ubah';

  @override
  String get profileCollections => 'Koleksi';

  @override
  String get profileAge => 'Usia';

  @override
  String get profileGender => 'Jenis kelamin';

  @override
  String get profileGenderUnset => 'Belum diatur';

  @override
  String get profileGenderMale => 'Pria';

  @override
  String get profileGenderFemale => 'Wanita';

  @override
  String get profileAvatar => 'Avatar';

  @override
  String get profileUploadPhoto => 'Unggah foto';

  @override
  String get profileChangePhoto => 'Ganti foto';

  @override
  String get shopTitle => 'Toko';

  @override
  String get shopEmojis => 'Emoji';

  @override
  String get shopEmojisSubtitle => 'Emoji animasi untuk obrolan';

  @override
  String get shopCollections => 'Koleksi';

  @override
  String get shopCollectionsSubtitle => 'Pameran profil, hadiah, dan pendapatan';

  @override
  String get shopStakes => 'Taruhan';

  @override
  String get shopStakesSubtitle => 'Buka taruhan lebih tinggi';

  @override
  String get inventoryTitle => 'Item';

  @override
  String get inventoryEmpty => 'Belum ada apa pun — cek toko';

  @override
  String get inventoryFrames => 'Bingkai';

  @override
  String get inventoryClaim => 'Klaim';

  @override
  String get inventorySell => 'Jual';

  @override
  String get inventoryGift => 'Hadiahkan';

  @override
  String get messageEdited => 'diedit';

  @override
  String get messageDeleted => 'Pesan dihapus';

  @override
  String get photo => 'Foto';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galeri';

  @override
  String get connectionError => 'Tidak dapat terhubung ke server.';

  @override
  String get serverError => 'Error server. Silakan coba lagi nanti.';

  @override
  String get sessionExpired => 'Sesi berakhir. Silakan masuk lagi.';

  @override
  String get errNoInternet => 'Tidak ada koneksi internet.';

  @override
  String get errTimeout => 'Permintaan habis waktu. Silakan coba lagi.';

  @override
  String get errGamesUnavailable => 'Game sementara tidak tersedia';

  @override
  String get errSettingsSaveFailed => 'Tidak dapat menyimpan pengaturan';

  @override
  String get errPushPermission => 'Izinkan notifikasi di browser atau pengaturan sistem.';

  @override
  String get balanceTitle => 'Saldo';

  @override
  String get coinBronze => 'Perunggu';

  @override
  String get coinSilver => 'Perak';

  @override
  String get coinGold => 'Emas';

  @override
  String get coinDiamond => 'Berlian';

  @override
  String get balanceZeroBronze => '0 perunggu';

  @override
  String balanceBronzes(int count) {
    return '$count perunggu';
  }

  @override
  String balanceSilvers(int count) {
    return '$count perak';
  }

  @override
  String balanceGolds(int count) {
    return '$count emas';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count berlian';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/hari';
  }

  @override
  String get balanceAbbrBronze => 'pr';

  @override
  String get balanceAbbrSilver => 'pk.';

  @override
  String get balanceAbbrGold => 'em.';

  @override
  String get commonBackHome => 'Kembali ke beranda';

  @override
  String get commonCopied => 'Disalin';

  @override
  String get commonClear => 'Hapus';

  @override
  String get commonTryLater => 'Coba lagi nanti.';

  @override
  String get commonTryRefresh => 'Coba segarkan halaman.';

  @override
  String get coinsTitle => 'Koin';

  @override
  String get coinsLoginReward => 'Hadiah masuk';

  @override
  String get coinsLoginAvailableToday => 'Hadiah hari ini tersedia';

  @override
  String get coinsLoginStreak => 'Rentetan masuk harian';

  @override
  String get coinsFriendReward => 'Hadiah teman';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount untuk pendaftaran lewat tautan Anda';
  }

  @override
  String get coinsLoadRewardsFailed => 'Gagal memuat hadiah';

  @override
  String get coinsClaimReward => 'Ambil hadiah';

  @override
  String get coinsAlreadyClaimed => 'Sudah diambil';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · hari ini';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · sisa 1 hari';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · sisa $remaining';
  }

  @override
  String get coinsInviteFriend => 'Undang teman';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount untuk setiap orang yang mendaftar lewat tautan Anda';
  }

  @override
  String get coinsCopyLink => 'Salin tautan';

  @override
  String get coinsHowItWorks => 'Cara kerjanya';

  @override
  String get coinsHowStep1 => 'Salin tautan dan kirim ke teman';

  @override
  String get coinsHowStep2 => 'Teman mendaftar lewat tautan itu';

  @override
  String coinsHowStep3(String amount) {
    return 'Anda menerima $amount';
  }

  @override
  String get achievementsTitle => 'Pencapaian';

  @override
  String achievementsProgress(String progress) {
    return 'Progres: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Bingkai diperoleh';

  @override
  String get achievementsClaimed => 'Diperoleh';

  @override
  String get achievementsOpenFrame => 'Buka bingkai';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Yakin ingin menghapus $name dari teman?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Hapus';

  @override
  String get friendsRemove => 'Hapus dari teman';

  @override
  String get friendsAcceptRequest => 'Terima permintaan';

  @override
  String get friendsDeclineRequest => 'Tolak permintaan';

  @override
  String get friendsCancelRequest => 'Batalkan permintaan';

  @override
  String get friendsSendRequest => 'Kirim permintaan pertemanan';

  @override
  String get friendsRequestAlreadySent => 'Permintaan sudah dikirim';

  @override
  String get friendsIncomingStatus => 'Permintaan masuk';

  @override
  String get friendsOutgoingStatus => 'Permintaan keluar';

  @override
  String get friendsNotFriends => 'Bukan teman';

  @override
  String get friendsCollapseSearch => 'Sembunyikan pencarian';

  @override
  String get friendsExpandSearch => 'Tampilkan pencarian';

  @override
  String get friendsLoadFailed => 'Gagal memuat teman';

  @override
  String friendsSince(String date) {
    return 'Berteman sejak: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Permintaan masuk: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Permintaan keluar: $date';
  }

  @override
  String get userInfoTitle => 'Info pengguna';

  @override
  String profileAgeYears(int age) {
    return '$age tahun';
  }

  @override
  String get shopBuy => 'Beli';

  @override
  String get shopBuyTitle => 'Beli?';

  @override
  String get shopBuyStakeTitle => 'Beli taruhan?';

  @override
  String get shopBuyEmojiTitle => 'Beli emoji?';

  @override
  String get shopBuyCollectionTitle => 'Beli koleksi?';

  @override
  String shopPrice(String price) {
    return 'Harga: $price';
  }

  @override
  String get shopOwned => 'Dibeli';

  @override
  String get shopEmpty => 'Masih kosong';

  @override
  String shopPurchased(String title) {
    return '$title dibeli';
  }

  @override
  String get shopEmojiUses => 'Anda mendapat: 10 penggunaan';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 penggunaan';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 penggunaan';
  }

  @override
  String get shopBuyTen => 'Beli · 10 pcs';

  @override
  String shopDailyIncome(String amount) {
    return 'Pendapatan: $amount';
  }

  @override
  String get shopBuyOnce => 'Pembelian sekali';

  @override
  String get shopSellRefund => 'Menjual mengembalikan 80% biaya';

  @override
  String shopCollectionAdded(String title) {
    return '$title ditambahkan ke profil';
  }

  @override
  String shopSetBonus(int percent) {
    return 'bonus set +$percent%';
  }

  @override
  String get shopSetComplete => 'Lengkap';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Terkumpul · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Jual?';

  @override
  String inventorySellDesc(String amount) {
    return 'Anda akan menerima $amount';
  }

  @override
  String inventorySold(String amount) {
    return 'Terjual: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Tambahkan teman dulu';

  @override
  String get inventoryGiftTitle => 'Hadiahkan koleksi?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'Hadiahkan «$title» kepada $name?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Dihadiahkan: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'Pemain sudah memiliki item ini';

  @override
  String get inventoryGiftSelf => 'Anda tidak bisa memberi hadiah ke diri sendiri';

  @override
  String get inventoryGiftNotOwned => 'Item ini tidak ada di inventaris Anda';

  @override
  String get inventoryLoadFailed => 'Gagal memuat item';

  @override
  String get inventoryNoCollections => 'Tidak ada koleksi — beli di toko';

  @override
  String get inventoryNoEmojis => 'Tidak ada emoji — beli di toko';

  @override
  String get inventoryNoFrames => 'Tidak ada bingkai — menangkan 10 pertandingan liga (pencapaian)';

  @override
  String get inventoryNoStakes => 'Tidak ada taruhan yang dibeli';

  @override
  String inventoryEmojiLeft(int count) {
    return 'Sisa $count';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Pendapatan: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Pendapatan besok: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Siap';

  @override
  String get inventoryIncomeTomorrowLabel => 'Besok';

  @override
  String inventoryStakeGold(String amount) {
    return 'Bisa bertaruh $amount emas';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'Bisa bertaruh $amount perak';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'Diterima +$amount';
  }

  @override
  String get chatsLoadFailed => 'Gagal memuat obrolan';

  @override
  String get chatsLoadListFailed => 'Gagal memuat daftar';

  @override
  String get chatsBlockedEmpty => 'Daftar kosong';

  @override
  String chatsBlockedAt(String date) {
    return 'Diblokir: $date';
  }

  @override
  String get chatsCreateFailed => 'Gagal membuat obrolan';

  @override
  String get chatsNeedFriendsFirst => 'Tambahkan teman dulu, baru bisa membuka obrolan.';

  @override
  String get chatsFriendsNotFound => 'Teman tidak ditemukan';

  @override
  String get chatsFindFriendHint => 'Cari teman berdasarkan nama panggilan';

  @override
  String get chatsSelectChat => 'Pilih obrolan';

  @override
  String get chatsSelectHint => 'Pilih percakapan dari daftar di kiri';

  @override
  String get chatEditFailed => 'Gagal mengubah pesan';

  @override
  String get chatSendFailed => 'Gagal mengirim pesan';

  @override
  String get chatDeleteFailed => 'Gagal menghapus pesan';

  @override
  String get chatEmojiSendFailed => 'Gagal mengirim emoji';

  @override
  String get chatLoadFailed => 'Gagal memuat pesan';

  @override
  String get chatBackToGame => 'Kembali ke permainan';

  @override
  String get chatBackToChats => 'Kembali ke obrolan';

  @override
  String get chatActions => 'Tindakan obrolan';

  @override
  String get chatAutoTranslate => 'Auto-translate';

  @override
  String get chatScrollToEnd => 'Ke akhir percakapan';

  @override
  String chatReplyingTo(String name) {
    return 'Membalas $name';
  }

  @override
  String get chatGift => 'Hadiah';

  @override
  String get chatCollection => 'Koleksi';

  @override
  String get chatGiftCollection => 'Hadiah · koleksi';

  @override
  String get chatThisUser => 'pengguna ini';

  @override
  String get gamesLobbyLoadFailed => 'Gagal memuat lobi.';

  @override
  String get gamesTapChangeStake => 'Ketuk untuk mengubah taruhan';

  @override
  String get gamesTapChangeTurnTime => 'Ketuk untuk mengubah waktu giliran';

  @override
  String get gamesTapChangeGrid => 'Ketuk untuk mengubah ukuran grid';

  @override
  String get gamesSwapSidesHint => 'O bisa menjadi X setelah langkah pertama';

  @override
  String get gamesNoCenterHint => 'Langkah pertama tidak boleh di tengah';

  @override
  String get lobbyInviteSentShort => 'Terkirim';

  @override
  String get lobbyInvitesSentWaiting => 'Undangan terkirim. Menunggu respons.';

  @override
  String get lobbyLinkCopiedHint => 'Tempel di obrolan atau pesan ke teman';

  @override
  String get lobbyCopyLinkHint => 'Salin tautan ke papan klip';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name mengundang Anda bermain';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name menang';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Waktu habis. $name menang';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds d';
  }

  @override
  String get adminTitle => 'Admin';

  @override
  String get tournamentsTitle => 'Turnamen';

  @override
  String get profileAgeInvalid => 'Masukkan usia dari 1 hingga 111';

  @override
  String get profileSaveFailed => 'Gagal menyimpan profil';

  @override
  String get profileNameHint => 'Huruf Latin, angka, _ hingga 10 karakter';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'Dari 1 hingga 111';

  @override
  String get profileAboutHint => 'Hingga 100 karakter (opsional)';

  @override
  String get profileProcessingPhoto => 'Memproses foto…';

  @override
  String get profileCropTitle => 'Pilih area avatar';

  @override
  String get profileCropHint => 'Perbesar dan geser foto';

  @override
  String get profileApply => 'Terapkan';

  @override
  String get profilePreparing => 'Menyiapkan…';

  @override
  String timeSecondsShort(int seconds) {
    return '$seconds d';
  }

  @override
  String get timeOneMin => '1 mnt';

  @override
  String get timeTenMin => '10 mnt';

  @override
  String rulesIntro(String grid) {
    return 'Tic-tac-toe di papan $grid. Bergiliran; X duluan.';
  }

  @override
  String rulesWin(int n) {
    return 'Menang: susun $n beruntun horizontal, vertikal, atau diagonal.';
  }

  @override
  String get rulesNoTimeLimit => 'Tanpa batas waktu per giliran.';

  @override
  String rulesTurnTime(String time) {
    return 'Waktu per giliran: $time.';
  }

  @override
  String rulesStake(String stake) {
    return 'Taruhan: $stake. Game ini seharga koin sebanyak itu.';
  }

  @override
  String get rulesSwap => 'Tukar sisi: O boleh bertukar dengan X setelah langkah pertama X.';

  @override
  String get rulesNoCenter => 'Larangan tengah: X tidak boleh main di tengah pada langkah pertama.';

  @override
  String get collectionSetLegends => 'Legenda';

  @override
  String get collectionSetSpace => 'Antariksa';

  @override
  String get collectionSetGems => 'Permata';

  @override
  String get collectionSetParty => 'Pesta';

  @override
  String get collectionSetNature => 'Alam';

  @override
  String get collectionSetAdventures => 'Petualangan';

  @override
  String collectionCardMeta(String amount) {
    return 'Koleksi · etalase · hadiah · jual · +$amount';
  }

  @override
  String get coinsDayOne => 'hari';

  @override
  String get coinsDayFew => 'hari';

  @override
  String get coinsDayMany => 'hari';

  @override
  String get giftFriendTitle => 'Hadiah ke teman';

  @override
  String photoCount(int count) {
    return 'Foto ($count)';
  }

  @override
  String photoCountWithText(int count, String text) {
    return 'Foto ($count): $text';
  }

  @override
  String photoWithText(String text) {
    return 'Foto: $text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count emoji · $price';
  }

  @override
  String get chatsExpandPanel => 'Perluas panel';

  @override
  String get chatsCollapsePanel => 'Ciutkan panel';

  @override
  String get chatReplySourceMissing => 'Pesan asli tidak ditemukan';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Taruhan $n perak';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Taruhan $n emas';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Buka taruhan $n perak';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Buka taruhan $n emas';
  }

  @override
  String get chatReplySelf => 'diri sendiri';

  @override
  String get chatReplyPeer => 'lawan bicara';

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
  String get statsTitle => 'Statistik';

  @override
  String get statsLoadFailed => 'Gagal memuat statistik';

  @override
  String get statsAllGames => 'Semua game';

  @override
  String get statsEmptyTitle => 'Belum ada pertandingan';

  @override
  String get statsEmptyHint => 'Mainkan game pertama agar statistik muncul di sini.';

  @override
  String get statsWins => 'Menang';

  @override
  String get statsDraws => 'Seri';

  @override
  String get statsLosses => 'Kalah';

  @override
  String get statsWinRate => 'Persentase kemenangan';

  @override
  String get statsTopWon => 'Paling sering menang melawan';

  @override
  String get statsTopDrawn => 'Paling sering seri dengan';

  @override
  String get statsTopLost => 'Paling sering kalah melawan';

  @override
  String get statsTimePlayed => 'Waktu bermain';

  @override
  String get statsYourScore => 'Skor Anda';

  @override
  String get profileShowStats => 'Tampilkan statistik';

  @override
  String get statsDurationZeroMinutes => '0 mnt';

  @override
  String get gameYouWonOpponentForfeit => 'Lawan menyerah. Anda menang!';

  @override
  String get lobbyLeaveTitle => 'Tinggalkan lobi?';

  @override
  String get lobbyLeaveConfirm => 'Lobi akan dihapus setelah Anda keluar. Teman yang diundang akan mendapat penolakan.';

  @override
  String get lobbyLeave => 'Keluar';

  @override
  String statsDurationHours(int hours) {
    return '$hours jam';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours jam $minutes mnt';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes mnt';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'Anda menyerah. $name menang';
  }

  @override
  String get supportTitle => 'Dukungan';

  @override
  String get supportUnavailable => 'Dukungan tidak tersedia';

  @override
  String get supportOpenFailed => 'Tidak dapat membuka chat dukungan';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Anda menerima $amount koin';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return '$amount koin dipotong';
  }

  @override
  String get coinsCreditCardTitle => 'Anda menerima koin';

  @override
  String get coinsClaim => 'Ambil';

  @override
  String get durakActionPass => 'Pass';

  @override
  String get durakRoleTook => 'Ambil';

  @override
  String get durakRoleBeats => 'Mengalahkan';

  @override
  String get durakRoleThrowIn => 'Tambah';

  @override
  String get durakRoleTurn => 'Giliran';

  @override
  String get durakRoleDefends => 'Bertahan';

  @override
  String get durakStatusTaking => 'Mengambil';

  @override
  String get durakHintDefenderTurn => 'Giliran bertahan';

  @override
  String get gameYouEliminated => 'Anda tersingkir';

  @override
  String gameYouPlaced(int place) {
    return 'Anda finis ke-$place';
  }

  @override
  String get gameOverNeutral => 'Permainan selesai';

  @override
  String gameTurnOf(String name) {
    return 'Giliran $name';
  }

  @override
  String get chatGroupTooltip => 'Obrolan grup';

  @override
  String get lobbyChatNotReady => 'Obrolan lobi belum siap';

  @override
  String get chatsGroupChat => 'Obrolan grup';

  @override
  String chatsMembersCount(int count) {
    return 'Anggota: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count org';
  }

  @override
  String get chatsYouSuffix => '(Anda)';

  @override
  String get chatTitleDurak3 => 'Durak · 3 pemain';

  @override
  String get chatTitleDurak4 => 'Durak · 4 pemain';

  @override
  String get rulesTttUltimate => 'Ultimate: sembilan papan mini 3×3. Langkah mengirim lawan ke papan itu. Menang dengan garis di meta-papan.';

  @override
  String get rulesTttMulti3 => '3 pemain: papan 3×3, tiga pemain (X, O, △). Menang dengan menyelesaikan garis dari tanda Anda.';

  @override
  String get rulesTttMulti4 => '4 pemain: papan 4×4, empat pemain (X, O, △, □). Menang dengan menyelesaikan garis dari tanda Anda.';
}
