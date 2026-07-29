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
  String timeMinutesAgo(Object count) {
    return '$count mnt lalu';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count jam lalu';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count hr lalu';
  }

  @override
  String get timeWeekAgo => 'seminggu lalu';

  @override
  String timeWeeksAgo(Object count) {
    return '$count mgg lalu';
  }

  @override
  String get timeMonthAgo => 'sebulan lalu';

  @override
  String timeMonthsAgo(Object count) {
    return '$count bln lalu';
  }

  @override
  String get timeYearAgo => 'setahun lalu';

  @override
  String timeYearsAgo(Object count) {
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
  String get lobbyMatchmake => 'Lobi';

  @override
  String get lobbyPrivateGame => 'Game pribadi';

  @override
  String get lobbySearchingOpponent => 'Mencari lawan…';

  @override
  String get lobbyWaitingJoin => 'Menunggu seseorang mengetuk “Cari game” atau “Gabung”';

  @override
  String get lobbyInviteTitle => 'Undangan game';

  @override
  String get lobbyInvitedToPlay => 'Anda diundang untuk bermain';

  @override
  String get lobbyEnterGame => 'Masuk game';

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
  String get shopStakesSubtitle => 'Buka taruhan perak';

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
}
