import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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
    Locale('en')
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

  /// No description provided for @settingsLanguageRu.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get settingsLanguageRu;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

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
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In ru, this message translates to:
  /// **'{count} ч назад'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In ru, this message translates to:
  /// **'{count} дн. назад'**
  String timeDaysAgo(int count);

  /// No description provided for @timeWeekAgo.
  ///
  /// In ru, this message translates to:
  /// **'неделю назад'**
  String get timeWeekAgo;

  /// No description provided for @timeWeeksAgo.
  ///
  /// In ru, this message translates to:
  /// **'{count} нед. назад'**
  String timeWeeksAgo(int count);

  /// No description provided for @timeMonthAgo.
  ///
  /// In ru, this message translates to:
  /// **'месяц назад'**
  String get timeMonthAgo;

  /// No description provided for @timeMonthsAgo.
  ///
  /// In ru, this message translates to:
  /// **'{count} мес. назад'**
  String timeMonthsAgo(int count);

  /// No description provided for @timeYearAgo.
  ///
  /// In ru, this message translates to:
  /// **'год назад'**
  String get timeYearAgo;

  /// No description provided for @timeYearsAgo.
  ///
  /// In ru, this message translates to:
  /// **'{count} г. назад'**
  String timeYearsAgo(int count);

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

  /// No description provided for @profileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profileTitle;

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
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
