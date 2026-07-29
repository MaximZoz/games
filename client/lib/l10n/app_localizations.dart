import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_be.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_he.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nb.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_uz.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ru'),
    Locale('en'),
    Locale('uk'),
    Locale('be'),
    Locale('kk'),
    Locale('uz'),
    Locale('de'),
    Locale('fr'),
    Locale('es'),
    Locale('it'),
    Locale('pt'),
    Locale('pl'),
    Locale('nl'),
    Locale('tr'),
    Locale('zh'),
    Locale('ja'),
    Locale('ko'),
    Locale('hi'),
    Locale('ar'),
    Locale('he'),
    Locale('th'),
    Locale('vi'),
    Locale('id'),
    Locale('cs'),
    Locale('el'),
    Locale('sv'),
    Locale('nb'),
    Locale('da'),
    Locale('fi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Zozu Games'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get navHome;

  /// No description provided for @navProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get navProfile;

  /// No description provided for @navFriends.
  ///
  /// In ru, this message translates to:
  /// **'Друзья'**
  String get navFriends;

  /// No description provided for @navChats.
  ///
  /// In ru, this message translates to:
  /// **'Чаты'**
  String get navChats;

  /// No description provided for @navGames.
  ///
  /// In ru, this message translates to:
  /// **'Игры'**
  String get navGames;

  /// No description provided for @navSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In ru, this message translates to:
  /// **'Как в системе'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsAddBotsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Добавлять ботов через 30 с'**
  String get settingsAddBotsTitle;

  /// No description provided for @settingsAddBotsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'В режиме «поиск игры»: если соперник не найден за 30 секунд, игра начинается с ботом (цена игры сбрасывается до 1-й бронзы)'**
  String get settingsAddBotsSubtitle;

  /// No description provided for @settingsFriendsOnlyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сообщения только от друзей'**
  String get settingsFriendsOnlyTitle;

  /// No description provided for @settingsFriendsOnlySubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Кто не в друзьях, сможет отправлять только смайлики. Если мешает спам — временно заблокируйте пользователя.'**
  String get settingsFriendsOnlySubtitle;

  /// No description provided for @settingsNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get settingsNotifications;

  /// No description provided for @settingsPushChat.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get settingsPushChat;

  /// No description provided for @settingsPushFriends.
  ///
  /// In ru, this message translates to:
  /// **'Друзья'**
  String get settingsPushFriends;

  /// No description provided for @settingsPushGames.
  ///
  /// In ru, this message translates to:
  /// **'Игры'**
  String get settingsPushGames;

  /// No description provided for @settingsPushRewards.
  ///
  /// In ru, this message translates to:
  /// **'Награды'**
  String get settingsPushRewards;

  /// No description provided for @loginTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Введите email или логин и пароль'**
  String get loginSubtitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In ru, this message translates to:
  /// **'Email или логин'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get loginPasswordLabel;

  /// No description provided for @loginSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get loginSubmit;

  /// No description provided for @loginNoAccount.
  ///
  /// In ru, this message translates to:
  /// **'Нет аккаунта? Зарегистрироваться'**
  String get loginNoAccount;

  /// No description provided for @loginEmailRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите email или логин'**
  String get loginEmailRequired;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите пароль'**
  String get loginPasswordRequired;

  /// No description provided for @loginTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get loginTooltip;

  /// No description provided for @logoutTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get logoutTooltip;

  /// No description provided for @registerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Создайте аккаунт для игры'**
  String get registerSubtitle;

  /// No description provided for @registerNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Имя (логин)'**
  String get registerNameLabel;

  /// No description provided for @registerEmailLabel.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get registerEmailLabel;

  /// No description provided for @registerPasswordLabel.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get registerPasswordLabel;

  /// No description provided for @registerSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрироваться'**
  String get registerSubmit;

  /// No description provided for @registerHaveAccount.
  ///
  /// In ru, this message translates to:
  /// **'Уже есть аккаунт? Войти'**
  String get registerHaveAccount;

  /// No description provided for @registerNameRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите имя'**
  String get registerNameRequired;

  /// No description provided for @registerNameNoSpaces.
  ///
  /// In ru, this message translates to:
  /// **'Имя без пробелов'**
  String get registerNameNoSpaces;

  /// No description provided for @registerNameMax.
  ///
  /// In ru, this message translates to:
  /// **'Максимум 20 символов'**
  String get registerNameMax;

  /// No description provided for @registerNameHint.
  ///
  /// In ru, this message translates to:
  /// **'До 20 символов'**
  String get registerNameHint;

  /// No description provided for @registerEmailRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите email'**
  String get registerEmailRequired;

  /// No description provided for @registerEmailInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный email'**
  String get registerEmailInvalid;

  /// No description provided for @registerPasswordHint.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 6 символов'**
  String get registerPasswordHint;

  /// No description provided for @registerPasswordMin.
  ///
  /// In ru, this message translates to:
  /// **'Пароль не короче 6 символов'**
  String get registerPasswordMin;

  /// No description provided for @commonCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get commonEdit;

  /// No description provided for @commonReply.
  ///
  /// In ru, this message translates to:
  /// **'Ответить'**
  String get commonReply;

  /// No description provided for @commonSend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get commonSend;

  /// No description provided for @commonClose.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка…'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get commonError;

  /// No description provided for @commonOnline.
  ///
  /// In ru, this message translates to:
  /// **'в сети'**
  String get commonOnline;

  /// No description provided for @commonOffline.
  ///
  /// In ru, this message translates to:
  /// **'не в сети'**
  String get commonOffline;

  /// No description provided for @commonOnlineCap.
  ///
  /// In ru, this message translates to:
  /// **'Онлайн'**
  String get commonOnlineCap;

  /// No description provided for @commonUser.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get commonUser;

  /// No description provided for @commonPlayer.
  ///
  /// In ru, this message translates to:
  /// **'Игрок'**
  String get commonPlayer;

  /// No description provided for @commonAboutMe.
  ///
  /// In ru, this message translates to:
  /// **'О себе'**
  String get commonAboutMe;

  /// No description provided for @commonBack.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get commonBack;

  /// No description provided for @commonAccept.
  ///
  /// In ru, this message translates to:
  /// **'Принять'**
  String get commonAccept;

  /// No description provided for @commonDecline.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get commonDecline;

  /// No description provided for @commonCreating.
  ///
  /// In ru, this message translates to:
  /// **'Создание…'**
  String get commonCreating;

  /// No description provided for @commonSearching.
  ///
  /// In ru, this message translates to:
  /// **'Поиск…'**
  String get commonSearching;

  /// No description provided for @commonInsufficientCoins.
  ///
  /// In ru, this message translates to:
  /// **'Недостаточно монет'**
  String get commonInsufficientCoins;

  /// No description provided for @commonNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Не найдено'**
  String get commonNotFound;

  /// No description provided for @commonServerErrorShort.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сервера'**
  String get commonServerErrorShort;

  /// No description provided for @commonForbidden.
  ///
  /// In ru, this message translates to:
  /// **'Недостаточно прав'**
  String get commonForbidden;

  /// No description provided for @commonUserBlocked.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь заблокирован'**
  String get commonUserBlocked;

  /// No description provided for @commonUserNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь не найден'**
  String get commonUserNotFound;

  /// No description provided for @commonGenericError.
  ///
  /// In ru, this message translates to:
  /// **'Произошла ошибка. Попробуйте ещё раз.'**
  String get commonGenericError;

  /// No description provided for @timeJustNow.
  ///
  /// In ru, this message translates to:
  /// **'только что'**
  String get timeJustNow;

  /// No description provided for @timeYesterday.
  ///
  /// In ru, this message translates to:
  /// **'вчера'**
  String get timeYesterday;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In ru, this message translates to:
  /// **'{count} мин назад'**
  String timeMinutesAgo(Object count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In ru, this message translates to:
  /// **'{count} ч назад'**
  String timeHoursAgo(Object count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In ru, this message translates to:
  /// **'{count} дн. назад'**
  String timeDaysAgo(Object count);

  /// No description provided for @timeWeekAgo.
  ///
  /// In ru, this message translates to:
  /// **'неделю назад'**
  String get timeWeekAgo;

  /// No description provided for @timeWeeksAgo.
  ///
  /// In ru, this message translates to:
  /// **'{count} нед. назад'**
  String timeWeeksAgo(Object count);

  /// No description provided for @timeMonthAgo.
  ///
  /// In ru, this message translates to:
  /// **'месяц назад'**
  String get timeMonthAgo;

  /// No description provided for @timeMonthsAgo.
  ///
  /// In ru, this message translates to:
  /// **'{count} мес. назад'**
  String timeMonthsAgo(Object count);

  /// No description provided for @timeYearAgo.
  ///
  /// In ru, this message translates to:
  /// **'год назад'**
  String get timeYearAgo;

  /// No description provided for @timeYearsAgo.
  ///
  /// In ru, this message translates to:
  /// **'{count} г. назад'**
  String timeYearsAgo(Object count);

  /// No description provided for @weekdaySun.
  ///
  /// In ru, this message translates to:
  /// **'вс'**
  String get weekdaySun;

  /// No description provided for @weekdayMon.
  ///
  /// In ru, this message translates to:
  /// **'пн'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In ru, this message translates to:
  /// **'вт'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In ru, this message translates to:
  /// **'ср'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In ru, this message translates to:
  /// **'чт'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In ru, this message translates to:
  /// **'пт'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In ru, this message translates to:
  /// **'сб'**
  String get weekdaySat;

  /// No description provided for @monthJan.
  ///
  /// In ru, this message translates to:
  /// **'янв'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In ru, this message translates to:
  /// **'фев'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In ru, this message translates to:
  /// **'мар'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In ru, this message translates to:
  /// **'апр'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In ru, this message translates to:
  /// **'май'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In ru, this message translates to:
  /// **'июн'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In ru, this message translates to:
  /// **'июл'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In ru, this message translates to:
  /// **'авг'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In ru, this message translates to:
  /// **'сен'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In ru, this message translates to:
  /// **'окт'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In ru, this message translates to:
  /// **'ноя'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In ru, this message translates to:
  /// **'дек'**
  String get monthDec;

  /// No description provided for @homeAchievements.
  ///
  /// In ru, this message translates to:
  /// **'Достижения'**
  String get homeAchievements;

  /// No description provided for @homeAchievementsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Ваши игровые результаты'**
  String get homeAchievementsSubtitle;

  /// No description provided for @homeAchievementsRewards.
  ///
  /// In ru, this message translates to:
  /// **'Есть награды к получению'**
  String get homeAchievementsRewards;

  /// No description provided for @homeCoins.
  ///
  /// In ru, this message translates to:
  /// **'Монеты'**
  String get homeCoins;

  /// No description provided for @homeCoinsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Баланс и награды'**
  String get homeCoinsSubtitle;

  /// No description provided for @homeCoinsDailyReward.
  ///
  /// In ru, this message translates to:
  /// **'Доступна награда за вход'**
  String get homeCoinsDailyReward;

  /// No description provided for @homeItems.
  ///
  /// In ru, this message translates to:
  /// **'Предметы'**
  String get homeItems;

  /// No description provided for @homeItemsInventory.
  ///
  /// In ru, this message translates to:
  /// **'Ваш инвентарь'**
  String get homeItemsInventory;

  /// No description provided for @homeItemsGifted.
  ///
  /// In ru, this message translates to:
  /// **'Вам подарили коллекцию'**
  String get homeItemsGifted;

  /// No description provided for @homeItemsIncome.
  ///
  /// In ru, this message translates to:
  /// **'Можно забрать доход коллекций'**
  String get homeItemsIncome;

  /// No description provided for @homeShop.
  ///
  /// In ru, this message translates to:
  /// **'Магазин'**
  String get homeShop;

  /// No description provided for @homeShopSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Смайлы, ставки, коллекции'**
  String get homeShopSubtitle;

  /// No description provided for @gamesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Игры'**
  String get gamesTitle;

  /// No description provided for @gamesFindMatch.
  ///
  /// In ru, this message translates to:
  /// **'Найти игру'**
  String get gamesFindMatch;

  /// No description provided for @gamesMyTurn.
  ///
  /// In ru, this message translates to:
  /// **'Ваш ход'**
  String get gamesMyTurn;

  /// No description provided for @gamesWaiting.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание'**
  String get gamesWaiting;

  /// No description provided for @gamesLobbyTab.
  ///
  /// In ru, this message translates to:
  /// **'Лобби'**
  String get gamesLobbyTab;

  /// No description provided for @gamesTicTacToe.
  ///
  /// In ru, this message translates to:
  /// **'Крестики-нолики'**
  String get gamesTicTacToe;

  /// No description provided for @gamesRules.
  ///
  /// In ru, this message translates to:
  /// **'Правила'**
  String get gamesRules;

  /// No description provided for @gamesRulesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Правила игры'**
  String get gamesRulesTitle;

  /// No description provided for @gamesCreate.
  ///
  /// In ru, this message translates to:
  /// **'Создать игру'**
  String get gamesCreate;

  /// No description provided for @gamesJoin.
  ///
  /// In ru, this message translates to:
  /// **'Присоединиться'**
  String get gamesJoin;

  /// No description provided for @gamesOpponentTurn.
  ///
  /// In ru, this message translates to:
  /// **'Ход соперника'**
  String get gamesOpponentTurn;

  /// No description provided for @gamesCurrentGame.
  ///
  /// In ru, this message translates to:
  /// **'Текущая игра'**
  String get gamesCurrentGame;

  /// No description provided for @gamesInvitedYou.
  ///
  /// In ru, this message translates to:
  /// **'Вас пригласили'**
  String get gamesInvitedYou;

  /// No description provided for @gamesTurnTime.
  ///
  /// In ru, this message translates to:
  /// **'Время на ход'**
  String get gamesTurnTime;

  /// No description provided for @gamesGridSize.
  ///
  /// In ru, this message translates to:
  /// **'Размер сетки'**
  String get gamesGridSize;

  /// No description provided for @gamesSwapSides.
  ///
  /// In ru, this message translates to:
  /// **'Смена сторон'**
  String get gamesSwapSides;

  /// No description provided for @gamesNoCenter.
  ///
  /// In ru, this message translates to:
  /// **'Запрет центра'**
  String get gamesNoCenter;

  /// No description provided for @lobbyMatchmake.
  ///
  /// In ru, this message translates to:
  /// **'Лобби'**
  String get lobbyMatchmake;

  /// No description provided for @lobbyPrivateGame.
  ///
  /// In ru, this message translates to:
  /// **'Своя игра'**
  String get lobbyPrivateGame;

  /// No description provided for @lobbySearchingOpponent.
  ///
  /// In ru, this message translates to:
  /// **'Поиск соперника…'**
  String get lobbySearchingOpponent;

  /// No description provided for @lobbyWaitingJoin.
  ///
  /// In ru, this message translates to:
  /// **'Ждём, пока кто-то нажмёт «Найти игру» или «Присоединиться»'**
  String get lobbyWaitingJoin;

  /// No description provided for @lobbyInviteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение в игру'**
  String get lobbyInviteTitle;

  /// No description provided for @lobbyInvitedToPlay.
  ///
  /// In ru, this message translates to:
  /// **'Вас пригласили сыграть'**
  String get lobbyInvitedToPlay;

  /// No description provided for @lobbyEnterGame.
  ///
  /// In ru, this message translates to:
  /// **'Войти в игру'**
  String get lobbyEnterGame;

  /// No description provided for @lobbyInvite.
  ///
  /// In ru, this message translates to:
  /// **'Пригласить'**
  String get lobbyInvite;

  /// No description provided for @lobbyInviteSent.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение отправлено'**
  String get lobbyInviteSent;

  /// No description provided for @lobbyCopyLink.
  ///
  /// In ru, this message translates to:
  /// **'Отправить ссылку на игру'**
  String get lobbyCopyLink;

  /// No description provided for @lobbyLinkCopied.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка скопирована'**
  String get lobbyLinkCopied;

  /// No description provided for @lobbyNoFriendsOnline.
  ///
  /// In ru, this message translates to:
  /// **'Нет друзей онлайн. Отправьте ссылку на игру выше или дождитесь, пока друзья появятся в сети.'**
  String get lobbyNoFriendsOnline;

  /// No description provided for @gameBot.
  ///
  /// In ru, this message translates to:
  /// **'Бот'**
  String get gameBot;

  /// No description provided for @gameOpponent.
  ///
  /// In ru, this message translates to:
  /// **'Соперник'**
  String get gameOpponent;

  /// No description provided for @gameYouWon.
  ///
  /// In ru, this message translates to:
  /// **'Вы победили!'**
  String get gameYouWon;

  /// No description provided for @gameYouWonOpponentLeft.
  ///
  /// In ru, this message translates to:
  /// **'Вы победили, соперник вышел'**
  String get gameYouWonOpponentLeft;

  /// No description provided for @gameYouWonOpponentTimeout.
  ///
  /// In ru, this message translates to:
  /// **'Вы победили, время соперника вышло'**
  String get gameYouWonOpponentTimeout;

  /// No description provided for @gameDraw.
  ///
  /// In ru, this message translates to:
  /// **'Ничья'**
  String get gameDraw;

  /// No description provided for @gameExitTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выход из игры'**
  String get gameExitTitle;

  /// No description provided for @gameExitConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Если вы выйдете, то вы проиграете. Выйти?'**
  String get gameExitConfirm;

  /// No description provided for @gameStay.
  ///
  /// In ru, this message translates to:
  /// **'Остаться'**
  String get gameStay;

  /// No description provided for @gameLeave.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get gameLeave;

  /// No description provided for @gameConnecting.
  ///
  /// In ru, this message translates to:
  /// **'Подключение к игре…'**
  String get gameConnecting;

  /// No description provided for @gameWaitingOpponent.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание соперника'**
  String get gameWaitingOpponent;

  /// No description provided for @gameRematchOffer.
  ///
  /// In ru, this message translates to:
  /// **'Соперник предлагает реванш'**
  String get gameRematchOffer;

  /// No description provided for @gameRematchDeclined.
  ///
  /// In ru, this message translates to:
  /// **'Соперник отклонил предложение поиграть'**
  String get gameRematchDeclined;

  /// No description provided for @gameRematch.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get gameRematch;

  /// No description provided for @gameOtherOpponent.
  ///
  /// In ru, this message translates to:
  /// **'Другой соперник'**
  String get gameOtherOpponent;

  /// No description provided for @gameSwapSidesAction.
  ///
  /// In ru, this message translates to:
  /// **'Сменить стороны'**
  String get gameSwapSidesAction;

  /// No description provided for @gameWriteMessage.
  ///
  /// In ru, this message translates to:
  /// **'Написать сообщение'**
  String get gameWriteMessage;

  /// No description provided for @chatsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Чаты'**
  String get chatsTitle;

  /// No description provided for @chatsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет чатов.\nНажмите на иконку справа сверху, чтобы выбрать друга и начать диалог.'**
  String get chatsEmpty;

  /// No description provided for @chatsNewChat.
  ///
  /// In ru, this message translates to:
  /// **'Новый чат'**
  String get chatsNewChat;

  /// No description provided for @chatsNoMessages.
  ///
  /// In ru, this message translates to:
  /// **'Нет сообщений'**
  String get chatsNoMessages;

  /// No description provided for @chatsClearTitle.
  ///
  /// In ru, this message translates to:
  /// **'Очистить переписку?'**
  String get chatsClearTitle;

  /// No description provided for @chatsClearDesc.
  ///
  /// In ru, this message translates to:
  /// **'Диалог будет удалён без возможности восстановления.'**
  String get chatsClearDesc;

  /// No description provided for @chatsClearConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get chatsClearConfirm;

  /// No description provided for @chatsBlockTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировать пользователя?'**
  String get chatsBlockTitle;

  /// No description provided for @chatsBlockDesc.
  ///
  /// In ru, this message translates to:
  /// **'Вы больше не сможете писать друг другу. Диалог и дружба будут удалены.'**
  String get chatsBlockDesc;

  /// No description provided for @chatsBlockConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировать'**
  String get chatsBlockConfirm;

  /// No description provided for @chatsBlockedUsers.
  ///
  /// In ru, this message translates to:
  /// **'Заблокированные пользователи'**
  String get chatsBlockedUsers;

  /// No description provided for @chatsUnblock.
  ///
  /// In ru, this message translates to:
  /// **'Разблокировать'**
  String get chatsUnblock;

  /// No description provided for @chatDialog.
  ///
  /// In ru, this message translates to:
  /// **'Диалог'**
  String get chatDialog;

  /// No description provided for @chatEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Сообщений пока нет.\nНапишите первое сообщение.'**
  String get chatEmpty;

  /// No description provided for @chatMessageHint.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get chatMessageHint;

  /// No description provided for @chatEmoji.
  ///
  /// In ru, this message translates to:
  /// **'Смайлики'**
  String get chatEmoji;

  /// No description provided for @chatBuyEmojiHint.
  ///
  /// In ru, this message translates to:
  /// **'Купите смайлики в магазине на главной'**
  String get chatBuyEmojiHint;

  /// No description provided for @chatEditing.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование'**
  String get chatEditing;

  /// No description provided for @chatToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get chatToday;

  /// No description provided for @chatYesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get chatYesterday;

  /// No description provided for @chatFriendsOnly.
  ///
  /// In ru, this message translates to:
  /// **'Текст только для друзей'**
  String get chatFriendsOnly;

  /// No description provided for @emojiGroupEmotions.
  ///
  /// In ru, this message translates to:
  /// **'Эмоции'**
  String get emojiGroupEmotions;

  /// No description provided for @emojiGroupGame.
  ///
  /// In ru, this message translates to:
  /// **'Игровые'**
  String get emojiGroupGame;

  /// No description provided for @emojiGroupFlags.
  ///
  /// In ru, this message translates to:
  /// **'Флажки'**
  String get emojiGroupFlags;

  /// No description provided for @emojiGroupAnimals.
  ///
  /// In ru, this message translates to:
  /// **'Животные'**
  String get emojiGroupAnimals;

  /// No description provided for @emojiGroupFood.
  ///
  /// In ru, this message translates to:
  /// **'Еда'**
  String get emojiGroupFood;

  /// No description provided for @emojiGroupTravel.
  ///
  /// In ru, this message translates to:
  /// **'Путешествия'**
  String get emojiGroupTravel;

  /// No description provided for @emojiGroupParty.
  ///
  /// In ru, this message translates to:
  /// **'Праздник'**
  String get emojiGroupParty;

  /// No description provided for @emojiGroupObjects.
  ///
  /// In ru, this message translates to:
  /// **'Предметы'**
  String get emojiGroupObjects;

  /// No description provided for @friendsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Друзья'**
  String get friendsTitle;

  /// No description provided for @friendsTabFriends.
  ///
  /// In ru, this message translates to:
  /// **'Друзья'**
  String get friendsTabFriends;

  /// No description provided for @friendsTabIncoming.
  ///
  /// In ru, this message translates to:
  /// **'Входящие'**
  String get friendsTabIncoming;

  /// No description provided for @friendsTabOutgoing.
  ///
  /// In ru, this message translates to:
  /// **'Исходящие'**
  String get friendsTabOutgoing;

  /// No description provided for @friendsAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в друзья'**
  String get friendsAdd;

  /// No description provided for @friendsRequestSent.
  ///
  /// In ru, this message translates to:
  /// **'Заявка отправлена'**
  String get friendsRequestSent;

  /// No description provided for @friendsFindTab.
  ///
  /// In ru, this message translates to:
  /// **'Найти друга'**
  String get friendsFindTab;

  /// No description provided for @friendsSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по нику'**
  String get friendsSearchHint;

  /// No description provided for @friendsSearchPrompt.
  ///
  /// In ru, this message translates to:
  /// **'Используйте поиск, чтобы найти новых друзей'**
  String get friendsSearchPrompt;

  /// No description provided for @friendsNothingFound.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get friendsNothingFound;

  /// No description provided for @friendsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'У вас пока нет друзей'**
  String get friendsEmpty;

  /// No description provided for @friendsNoIncoming.
  ///
  /// In ru, this message translates to:
  /// **'Нет входящих заявок'**
  String get friendsNoIncoming;

  /// No description provided for @friendsNoOutgoing.
  ///
  /// In ru, this message translates to:
  /// **'Нет исходящих заявок'**
  String get friendsNoOutgoing;

  /// No description provided for @friendsAlreadyFriends.
  ///
  /// In ru, this message translates to:
  /// **'Уже в друзьях'**
  String get friendsAlreadyFriends;

  /// No description provided for @friendsRemoveTitle.
  ///
  /// In ru, this message translates to:
  /// **'Убрать из друзей?'**
  String get friendsRemoveTitle;

  /// No description provided for @friendsRemoved.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь удалён из друзей'**
  String get friendsRemoved;

  /// No description provided for @friendsRequestAccepted.
  ///
  /// In ru, this message translates to:
  /// **'Заявка принята'**
  String get friendsRequestAccepted;

  /// No description provided for @friendsRequestDeclined.
  ///
  /// In ru, this message translates to:
  /// **'Заявка отклонена'**
  String get friendsRequestDeclined;

  /// No description provided for @friendsRequestCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Заявка отменена'**
  String get friendsRequestCancelled;

  /// No description provided for @profileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profileTitle;

  /// No description provided for @profileSignInPrompt.
  ///
  /// In ru, this message translates to:
  /// **'Войдите в аккаунт'**
  String get profileSignInPrompt;

  /// No description provided for @profileSignInHint.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы настроить личный профиль'**
  String get profileSignInHint;

  /// No description provided for @profileEdit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get profileEdit;

  /// No description provided for @profileCollections.
  ///
  /// In ru, this message translates to:
  /// **'Коллекции'**
  String get profileCollections;

  /// No description provided for @profileAge.
  ///
  /// In ru, this message translates to:
  /// **'Возраст'**
  String get profileAge;

  /// No description provided for @profileGender.
  ///
  /// In ru, this message translates to:
  /// **'Пол'**
  String get profileGender;

  /// No description provided for @profileGenderUnset.
  ///
  /// In ru, this message translates to:
  /// **'Не указан'**
  String get profileGenderUnset;

  /// No description provided for @profileGenderMale.
  ///
  /// In ru, this message translates to:
  /// **'Мужской'**
  String get profileGenderMale;

  /// No description provided for @profileGenderFemale.
  ///
  /// In ru, this message translates to:
  /// **'Женский'**
  String get profileGenderFemale;

  /// No description provided for @profileAvatar.
  ///
  /// In ru, this message translates to:
  /// **'Аватар'**
  String get profileAvatar;

  /// No description provided for @profileUploadPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Загрузить фото'**
  String get profileUploadPhoto;

  /// No description provided for @profileChangePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Поменять фото'**
  String get profileChangePhoto;

  /// No description provided for @shopTitle.
  ///
  /// In ru, this message translates to:
  /// **'Магазин'**
  String get shopTitle;

  /// No description provided for @shopEmojis.
  ///
  /// In ru, this message translates to:
  /// **'Смайлики'**
  String get shopEmojis;

  /// No description provided for @shopEmojisSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Анимированные эмодзи для чата'**
  String get shopEmojisSubtitle;

  /// No description provided for @shopCollections.
  ///
  /// In ru, this message translates to:
  /// **'Коллекции'**
  String get shopCollections;

  /// No description provided for @shopCollectionsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Витрина профиля, подарки и доход'**
  String get shopCollectionsSubtitle;

  /// No description provided for @shopStakes.
  ///
  /// In ru, this message translates to:
  /// **'Ставки'**
  String get shopStakes;

  /// No description provided for @shopStakesSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Разблокировка серебряных ставок'**
  String get shopStakesSubtitle;

  /// No description provided for @inventoryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Предметы'**
  String get inventoryTitle;

  /// No description provided for @inventoryEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока ничего нет — загляните в магазин'**
  String get inventoryEmpty;

  /// No description provided for @inventoryFrames.
  ///
  /// In ru, this message translates to:
  /// **'Рамки'**
  String get inventoryFrames;

  /// No description provided for @inventoryClaim.
  ///
  /// In ru, this message translates to:
  /// **'Забрать'**
  String get inventoryClaim;

  /// No description provided for @inventorySell.
  ///
  /// In ru, this message translates to:
  /// **'Продать'**
  String get inventorySell;

  /// No description provided for @inventoryGift.
  ///
  /// In ru, this message translates to:
  /// **'Подарить'**
  String get inventoryGift;

  /// No description provided for @messageEdited.
  ///
  /// In ru, this message translates to:
  /// **'изменено'**
  String get messageEdited;

  /// No description provided for @messageDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение удалено'**
  String get messageDeleted;

  /// No description provided for @photo.
  ///
  /// In ru, this message translates to:
  /// **'Фото'**
  String get photo;

  /// No description provided for @camera.
  ///
  /// In ru, this message translates to:
  /// **'Камера'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In ru, this message translates to:
  /// **'Галерея'**
  String get gallery;

  /// No description provided for @connectionError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подключиться к серверу.'**
  String get connectionError;

  /// No description provided for @serverError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сервера. Попробуйте позже.'**
  String get serverError;

  /// No description provided for @sessionExpired.
  ///
  /// In ru, this message translates to:
  /// **'Сессия истекла. Войдите заново.'**
  String get sessionExpired;

  /// No description provided for @errNoInternet.
  ///
  /// In ru, this message translates to:
  /// **'Нет подключения к интернету.'**
  String get errNoInternet;

  /// No description provided for @errTimeout.
  ///
  /// In ru, this message translates to:
  /// **'Превышено время ожидания. Попробуйте ещё раз.'**
  String get errTimeout;

  /// No description provided for @errGamesUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Игры временно недоступны'**
  String get errGamesUnavailable;

  /// No description provided for @errSettingsSaveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить настройку'**
  String get errSettingsSaveFailed;

  /// No description provided for @errPushPermission.
  ///
  /// In ru, this message translates to:
  /// **'Разрешите уведомления в настройках браузера или системы.'**
  String get errPushPermission;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'be', 'cs', 'da', 'de', 'el', 'en', 'es', 'fi', 'fr', 'he', 'hi', 'id', 'it', 'ja', 'kk', 'ko', 'nb', 'nl', 'pl', 'pt', 'ru', 'sv', 'th', 'tr', 'uk', 'uz', 'vi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'be': return AppLocalizationsBe();
    case 'cs': return AppLocalizationsCs();
    case 'da': return AppLocalizationsDa();
    case 'de': return AppLocalizationsDe();
    case 'el': return AppLocalizationsEl();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fi': return AppLocalizationsFi();
    case 'fr': return AppLocalizationsFr();
    case 'he': return AppLocalizationsHe();
    case 'hi': return AppLocalizationsHi();
    case 'id': return AppLocalizationsId();
    case 'it': return AppLocalizationsIt();
    case 'ja': return AppLocalizationsJa();
    case 'kk': return AppLocalizationsKk();
    case 'ko': return AppLocalizationsKo();
    case 'nb': return AppLocalizationsNb();
    case 'nl': return AppLocalizationsNl();
    case 'pl': return AppLocalizationsPl();
    case 'pt': return AppLocalizationsPt();
    case 'ru': return AppLocalizationsRu();
    case 'sv': return AppLocalizationsSv();
    case 'th': return AppLocalizationsTh();
    case 'tr': return AppLocalizationsTr();
    case 'uk': return AppLocalizationsUk();
    case 'uz': return AppLocalizationsUz();
    case 'vi': return AppLocalizationsVi();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
