import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Bosh sahifa';

  @override
  String get navProfile => 'Profil';

  @override
  String get navFriends => 'Do‘stlar';

  @override
  String get navChats => 'Chatlar';

  @override
  String get navGames => 'O‘yinlar';

  @override
  String get navSettings => 'Sozlamalar';

  @override
  String get settingsTitle => 'Sozlamalar';

  @override
  String get settingsLanguage => 'Til';

  @override
  String get settingsLanguageSystem => 'Tizim bo‘yicha';

  @override
  String get settingsAddBotsTitle => '30 soniyadan keyin bot qo‘shish';

  @override
  String get settingsAddBotsSubtitle => 'O‘yin qidiruvda: 30 soniya ichida raqib topilmasa, o‘yin bot bilan boshlanadi (stavka 1 bronzaga qaytariladi)';

  @override
  String get settingsFriendsOnlyTitle => 'Faqat do‘stlardan xabarlar';

  @override
  String get settingsFriendsOnlySubtitle => 'Do‘st bo‘lmaganlar faqat emoji yubora oladi. Spam xalaqit bersa, foydalanuvchini vaqtincha bloklang.';

  @override
  String get settingsNotifications => 'Bildirishnomalar';

  @override
  String get settingsPushChat => 'Chat';

  @override
  String get settingsPushFriends => 'Do‘stlar';

  @override
  String get settingsPushGames => 'O‘yinlar';

  @override
  String get settingsPushRewards => 'Mukofotlar';

  @override
  String get loginTitle => 'Kirish';

  @override
  String get loginSubtitle => 'Email yoki login va parolni kiriting';

  @override
  String get loginEmailLabel => 'Email yoki login';

  @override
  String get loginPasswordLabel => 'Parol';

  @override
  String get loginSubmit => 'Kirish';

  @override
  String get loginNoAccount => 'Hisobingiz yo‘qmi? Ro‘yxatdan o‘ting';

  @override
  String get loginEmailRequired => 'Email yoki login kiriting';

  @override
  String get loginPasswordRequired => 'Parolni kiriting';

  @override
  String get loginTooltip => 'Kirish';

  @override
  String get logoutTooltip => 'Chiqish';

  @override
  String get registerTitle => 'Ro‘yxatdan o‘tish';

  @override
  String get registerSubtitle => 'O‘ynash uchun hisob yarating';

  @override
  String get registerNameLabel => 'Ism (login)';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'Parol';

  @override
  String get registerSubmit => 'Ro‘yxatdan o‘tish';

  @override
  String get registerHaveAccount => 'Hisobingiz bormi? Kirish';

  @override
  String get registerNameRequired => 'Ism kiriting';

  @override
  String get registerNameNoSpaces => 'Ismda bo‘sh joy bo‘lmasligi kerak';

  @override
  String get registerNameMax => 'Maksimum 20 belgi';

  @override
  String get registerNameHint => '20 belgigacha';

  @override
  String get registerEmailRequired => 'Email kiriting';

  @override
  String get registerEmailInvalid => 'Noto‘g‘ri email';

  @override
  String get registerPasswordHint => 'Kamida 6 belgi';

  @override
  String get registerPasswordMin => 'Parol kamida 6 belgidan iborat bo‘lishi kerak';

  @override
  String get commonCancel => 'Bekor qilish';

  @override
  String get commonSave => 'Saqlash';

  @override
  String get commonDelete => 'O‘chirish';

  @override
  String get commonEdit => 'Tahrirlash';

  @override
  String get commonReply => 'Javob berish';

  @override
  String get commonSend => 'Yuborish';

  @override
  String get commonClose => 'Yopish';

  @override
  String get commonRetry => 'Qayta urinish';

  @override
  String get commonLoading => 'Yuklanmoqda…';

  @override
  String get commonError => 'Xato';

  @override
  String get commonOnline => 'onlayn';

  @override
  String get commonOffline => 'oflayn';

  @override
  String get commonOnlineCap => 'Onlayn';

  @override
  String get commonUser => 'Foydalanuvchi';

  @override
  String get commonPlayer => 'O‘yinchi';

  @override
  String get commonAboutMe => 'O‘zim haqimda';

  @override
  String get commonBack => 'Orqaga';

  @override
  String get commonAccept => 'Qabul qilish';

  @override
  String get commonDecline => 'Rad etish';

  @override
  String get commonCreating => 'Yaratilmoqda…';

  @override
  String get commonSearching => 'Qidirilmoqda…';

  @override
  String get commonInsufficientCoins => 'Tangalar yetarli emas';

  @override
  String get commonNotFound => 'Topilmadi';

  @override
  String get commonServerErrorShort => 'Server xatosi';

  @override
  String get commonForbidden => 'Ruxsat yo‘q';

  @override
  String get commonUserBlocked => 'Foydalanuvchi bloklangan';

  @override
  String get commonUserNotFound => 'Foydalanuvchi topilmadi';

  @override
  String get commonGenericError => 'Nimadir xato ketdi. Qayta urinib ko‘ring.';

  @override
  String get timeJustNow => 'hozirgina';

  @override
  String get timeYesterday => 'kecha';

  @override
  String timeMinutesAgo(Object count) {
    return '$count daq oldin';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count soat oldin';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count kun oldin';
  }

  @override
  String get timeWeekAgo => 'bir hafta oldin';

  @override
  String timeWeeksAgo(Object count) {
    return '$count hafta oldin';
  }

  @override
  String get timeMonthAgo => 'bir oy oldin';

  @override
  String timeMonthsAgo(Object count) {
    return '$count oy oldin';
  }

  @override
  String get timeYearAgo => 'bir yil oldin';

  @override
  String timeYearsAgo(Object count) {
    return '$count yil oldin';
  }

  @override
  String get weekdaySun => 'Yak';

  @override
  String get weekdayMon => 'Dush';

  @override
  String get weekdayTue => 'Sesh';

  @override
  String get weekdayWed => 'Chor';

  @override
  String get weekdayThu => 'Pay';

  @override
  String get weekdayFri => 'Jum';

  @override
  String get weekdaySat => 'Shan';

  @override
  String get monthJan => 'yan';

  @override
  String get monthFeb => 'fev';

  @override
  String get monthMar => 'mar';

  @override
  String get monthApr => 'apr';

  @override
  String get monthMay => 'may';

  @override
  String get monthJun => 'iyn';

  @override
  String get monthJul => 'iyl';

  @override
  String get monthAug => 'avg';

  @override
  String get monthSep => 'sen';

  @override
  String get monthOct => 'okt';

  @override
  String get monthNov => 'noy';

  @override
  String get monthDec => 'dek';

  @override
  String get homeAchievements => 'Yutuqlar';

  @override
  String get homeAchievementsSubtitle => 'O‘yin natijalaringiz';

  @override
  String get homeAchievementsRewards => 'Olish uchun mukofotlar bor';

  @override
  String get homeCoins => 'Tangalar';

  @override
  String get homeCoinsSubtitle => 'Balans va mukofotlar';

  @override
  String get homeCoinsDailyReward => 'Kirish mukofoti mavjud';

  @override
  String get homeItems => 'Buyumlar';

  @override
  String get homeItemsInventory => 'Inventaringiz';

  @override
  String get homeItemsGifted => 'Sizga kolleksiya sovg‘a qilindi';

  @override
  String get homeItemsIncome => 'Kolleksiya daromadini olish mumkin';

  @override
  String get homeShop => 'Do‘kon';

  @override
  String get homeShopSubtitle => 'Emoji, stavkalar, kolleksiyalar';

  @override
  String get gamesTitle => 'O‘yinlar';

  @override
  String get gamesFindMatch => 'O‘yin topish';

  @override
  String get gamesMyTurn => 'Sizning yurishingiz';

  @override
  String get gamesWaiting => 'Kutilmoqda';

  @override
  String get gamesLobbyTab => 'Lobi';

  @override
  String get gamesTicTacToe => 'X-O';

  @override
  String get gamesRules => 'Qoidalar';

  @override
  String get gamesRulesTitle => 'O‘yin qoidalari';

  @override
  String get gamesCreate => 'O‘yin yaratish';

  @override
  String get gamesJoin => 'Qo‘shilish';

  @override
  String get gamesOpponentTurn => 'Raqib yurishi';

  @override
  String get gamesCurrentGame => 'Joriy o‘yin';

  @override
  String get gamesInvitedYou => 'Sizni taklif qilishdi';

  @override
  String get gamesTurnTime => 'Yurish vaqti';

  @override
  String get gamesGridSize => 'To‘r o‘lchami';

  @override
  String get gamesSwapSides => 'Tomonlarni almashtirish';

  @override
  String get gamesNoCenter => 'Markazdan boshlash yo‘q';

  @override
  String get lobbyMatchmake => 'Lobi';

  @override
  String get lobbyPrivateGame => 'Shaxsiy o‘yin';

  @override
  String get lobbySearchingOpponent => 'Raqib qidirilmoqda…';

  @override
  String get lobbyWaitingJoin => 'Kimdir «O‘yin topish» yoki «Qo‘shilish»ni bosishini kutmoqdamiz';

  @override
  String get lobbyInviteTitle => 'O‘yinga taklif';

  @override
  String get lobbyInvitedToPlay => 'Sizni o‘ynashga taklif qilishdi';

  @override
  String get lobbyEnterGame => 'O‘yinga kirish';

  @override
  String get lobbyInvite => 'Taklif qilish';

  @override
  String get lobbyInviteSent => 'Taklif yuborildi';

  @override
  String get lobbyCopyLink => 'O‘yin havolasini ulashish';

  @override
  String get lobbyLinkCopied => 'Havola nusxalandi';

  @override
  String get lobbyNoFriendsOnline => 'Onlayn do‘stlar yo‘q. Yuqoridagi o‘yin havolasini ulashing yoki do‘stlaringiz onlayn bo‘lishini kuting.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Raqib';

  @override
  String get gameYouWon => 'Siz yutdingiz!';

  @override
  String get gameYouWonOpponentLeft => 'Siz yutdingiz — raqib chiqib ketdi';

  @override
  String get gameYouWonOpponentTimeout => 'Siz yutdingiz — raqib vaqti tugadi';

  @override
  String get gameDraw => 'Durrang';

  @override
  String get gameExitTitle => 'O‘yindan chiqish';

  @override
  String get gameExitConfirm => 'Chiqsangiz, mag‘lub bo‘lasiz. Baribir chiqasizmi?';

  @override
  String get gameStay => 'Qolish';

  @override
  String get gameLeave => 'Chiqish';

  @override
  String get gameConnecting => 'O‘yinga ulanilmoqda…';

  @override
  String get gameWaitingOpponent => 'Raqib kutilmoqda';

  @override
  String get gameRematchOffer => 'Raqib qayta o‘ynashni taklif qilmoqda';

  @override
  String get gameRematchDeclined => 'Raqib qayta o‘ynashni rad etdi';

  @override
  String get gameRematch => 'Qayta o‘ynash';

  @override
  String get gameOtherOpponent => 'Boshqa raqib';

  @override
  String get gameSwapSidesAction => 'Tomonlarni almashtirish';

  @override
  String get gameWriteMessage => 'Xabar yozish';

  @override
  String get chatsTitle => 'Chatlar';

  @override
  String get chatsEmpty => 'Hali chatlar yo‘q.\nYuqori o‘ngdagi belgini bosib, do‘st tanlang va suhbatni boshlang.';

  @override
  String get chatsNewChat => 'Yangi chat';

  @override
  String get chatsNoMessages => 'Xabarlar yo‘q';

  @override
  String get chatsClearTitle => 'Suhbat tozalansinmi?';

  @override
  String get chatsClearDesc => 'Chat butunlay o‘chiriladi.';

  @override
  String get chatsClearConfirm => 'Tozalash';

  @override
  String get chatsBlockTitle => 'Bu foydalanuvchi bloklansinmi?';

  @override
  String get chatsBlockDesc => 'Endi bir-biringizga yoza olmaysiz. Chat va do‘stlik o‘chiriladi.';

  @override
  String get chatsBlockConfirm => 'Bloklash';

  @override
  String get chatsBlockedUsers => 'Bloklangan foydalanuvchilar';

  @override
  String get chatsUnblock => 'Blokdan chiqarish';

  @override
  String get chatDialog => 'Chat';

  @override
  String get chatEmpty => 'Hali xabarlar yo‘q.\nBirinchisini yuboring.';

  @override
  String get chatMessageHint => 'Xabar';

  @override
  String get chatEmoji => 'Emoji';

  @override
  String get chatBuyEmojiHint => 'Bosh ekrandagi do‘kondan emoji sotib oling';

  @override
  String get chatEditing => 'Tahrirlash';

  @override
  String get chatToday => 'Bugun';

  @override
  String get chatYesterday => 'Kecha';

  @override
  String get chatFriendsOnly => 'Matn faqat do‘stlar uchun';

  @override
  String get emojiGroupEmotions => 'Hissiyotlar';

  @override
  String get emojiGroupGame => 'O‘yin';

  @override
  String get emojiGroupFlags => 'Bayroqlar';

  @override
  String get emojiGroupAnimals => 'Hayvonlar';

  @override
  String get emojiGroupFood => 'Ovqat';

  @override
  String get emojiGroupTravel => 'Sayohat';

  @override
  String get emojiGroupParty => 'Bayram';

  @override
  String get emojiGroupObjects => 'Buyumlar';

  @override
  String get friendsTitle => 'Do‘stlar';

  @override
  String get friendsTabFriends => 'Do‘stlar';

  @override
  String get friendsTabIncoming => 'Kiruvchi';

  @override
  String get friendsTabOutgoing => 'Chiquvchi';

  @override
  String get friendsAdd => 'Do‘st qo‘shish';

  @override
  String get friendsRequestSent => 'So‘rov yuborildi';

  @override
  String get friendsFindTab => 'Do‘st topish';

  @override
  String get friendsSearchHint => 'Login bo‘yicha qidirish';

  @override
  String get friendsSearchPrompt => 'Yangi do‘stlar topish uchun qidiruvdan foydalaning';

  @override
  String get friendsNothingFound => 'Hech narsa topilmadi';

  @override
  String get friendsEmpty => 'Hali do‘stlaringiz yo‘q';

  @override
  String get friendsNoIncoming => 'Kiruvchi so‘rovlar yo‘q';

  @override
  String get friendsNoOutgoing => 'Chiquvchi so‘rovlar yo‘q';

  @override
  String get friendsAlreadyFriends => 'Allaqachon do‘stsiz';

  @override
  String get friendsRemoveTitle => 'Do‘stlardan olib tashlansinmi?';

  @override
  String get friendsRemoved => 'Do‘stlardan olib tashlandi';

  @override
  String get friendsRequestAccepted => 'So‘rov qabul qilindi';

  @override
  String get friendsRequestDeclined => 'So‘rov rad etildi';

  @override
  String get friendsRequestCancelled => 'So‘rov bekor qilindi';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSignInPrompt => 'Hisobingizga kiring';

  @override
  String get profileSignInHint => 'Shaxsiy profilingizni sozlash uchun';

  @override
  String get profileEdit => 'Tahrirlash';

  @override
  String get profileCollections => 'Kolleksiyalar';

  @override
  String get profileAge => 'Yosh';

  @override
  String get profileGender => 'Jins';

  @override
  String get profileGenderUnset => 'Ko‘rsatilmagan';

  @override
  String get profileGenderMale => 'Erkak';

  @override
  String get profileGenderFemale => 'Ayol';

  @override
  String get profileAvatar => 'Avatar';

  @override
  String get profileUploadPhoto => 'Foto yuklash';

  @override
  String get profileChangePhoto => 'Fotoni o‘zgartirish';

  @override
  String get shopTitle => 'Do‘kon';

  @override
  String get shopEmojis => 'Emoji';

  @override
  String get shopEmojisSubtitle => 'Chat uchun animatsiyali emoji';

  @override
  String get shopCollections => 'Kolleksiyalar';

  @override
  String get shopCollectionsSubtitle => 'Profil vitrinasi, sovg‘alar va daromad';

  @override
  String get shopStakes => 'Stavkalar';

  @override
  String get shopStakesSubtitle => 'Kumush stavkalarni ochish';

  @override
  String get inventoryTitle => 'Buyumlar';

  @override
  String get inventoryEmpty => 'Hali hech narsa yo‘q — do‘konga qarang';

  @override
  String get inventoryFrames => 'Ramkalar';

  @override
  String get inventoryClaim => 'Olish';

  @override
  String get inventorySell => 'Sotish';

  @override
  String get inventoryGift => 'Sovg‘a qilish';

  @override
  String get messageEdited => 'tahrirlandi';

  @override
  String get messageDeleted => 'Xabar o‘chirildi';

  @override
  String get photo => 'Foto';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galereya';

  @override
  String get connectionError => 'Serverga ulanib bo‘lmadi.';

  @override
  String get serverError => 'Server xatosi. Keyinroq qayta urinib ko‘ring.';

  @override
  String get sessionExpired => 'Sessiya muddati tugadi. Qayta kiring.';

  @override
  String get errNoInternet => 'Internet aloqasi yo‘q.';

  @override
  String get errTimeout => 'So‘rov vaqti tugadi. Qayta urinib ko‘ring.';

  @override
  String get errGamesUnavailable => 'O‘yinlar vaqtincha mavjud emas';

  @override
  String get errSettingsSaveFailed => 'Sozlamani saqlab bo‘lmadi';

  @override
  String get errPushPermission => 'Brauzer yoki tizim sozlamalarida bildirishnomalarga ruxsat bering.';
}
