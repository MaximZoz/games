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

  /// No description provided for @settingsOfflineModeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Режим сети'**
  String get settingsOfflineModeTitle;

  /// No description provided for @settingsOfflineModeSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Офлайн: игра с ботом сразу, без ставок и наград, без чатов и друзей. Покупки сохраняются и применяются в режиме онлайн. Онлайн — когда есть интернет или по настройке пользователя.'**
  String get settingsOfflineModeSubtitle;

  /// No description provided for @settingsModeOnline.
  ///
  /// In ru, this message translates to:
  /// **'Онлайн'**
  String get settingsModeOnline;

  /// No description provided for @settingsModeOffline.
  ///
  /// In ru, this message translates to:
  /// **'Офлайн'**
  String get settingsModeOffline;

  /// No description provided for @gamesAlternateStartsHint.
  ///
  /// In ru, this message translates to:
  /// **'По очереди кто начинает партию'**
  String get gamesAlternateStartsHint;

  /// No description provided for @rulesAlternateStarts.
  ///
  /// In ru, this message translates to:
  /// **'Кто ходит первым чередуется от партии к партии.'**
  String get rulesAlternateStarts;

  /// No description provided for @offlineBadgeTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Офлайн режим'**
  String get offlineBadgeTooltip;

  /// No description provided for @offlineModePopupTitle.
  ///
  /// In ru, this message translates to:
  /// **'Офлайн режим'**
  String get offlineModePopupTitle;

  /// No description provided for @offlineModePopupBody.
  ///
  /// In ru, this message translates to:
  /// **'Включён офлайн режим. Играйте с ботом без ставок и наград. Чаты, друзья и лобби скрыты. Покупки применятся в режиме онлайн.'**
  String get offlineModePopupBody;

  /// No description provided for @offlineModePopupSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get offlineModePopupSettings;

  /// No description provided for @gamesPlay.
  ///
  /// In ru, this message translates to:
  /// **'Играть'**
  String get gamesPlay;

  /// No description provided for @offlineGameTitle.
  ///
  /// In ru, this message translates to:
  /// **'Игра с ботом'**
  String get offlineGameTitle;

  /// No description provided for @offlineGameHint.
  ///
  /// In ru, this message translates to:
  /// **'Без ставок и наград · только офлайн'**
  String get offlineGameHint;

  /// No description provided for @offlineBotWon.
  ///
  /// In ru, this message translates to:
  /// **'Бот победил'**
  String get offlineBotWon;

  /// No description provided for @offlineBotThinking.
  ///
  /// In ru, this message translates to:
  /// **'Ход бота…'**
  String get offlineBotThinking;

  /// No description provided for @offlinePlayAgain.
  ///
  /// In ru, this message translates to:
  /// **'Ещё раз'**
  String get offlinePlayAgain;

  /// No description provided for @offlineBotName.
  ///
  /// In ru, this message translates to:
  /// **'Бот {n}'**
  String offlineBotName(int n);

  /// No description provided for @durakActionTake.
  ///
  /// In ru, this message translates to:
  /// **'Взять'**
  String get durakActionTake;

  /// No description provided for @durakActionAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get durakActionAll;

  /// No description provided for @durakActionDone.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get durakActionDone;

  /// No description provided for @durakActionBito.
  ///
  /// In ru, this message translates to:
  /// **'Бито'**
  String get durakActionBito;

  /// No description provided for @durakHintDefend.
  ///
  /// In ru, this message translates to:
  /// **'Отбивайтесь'**
  String get durakHintDefend;

  /// No description provided for @durakHintDefendOrTransfer.
  ///
  /// In ru, this message translates to:
  /// **'Отбивайтесь или переведите'**
  String get durakHintDefendOrTransfer;

  /// No description provided for @durakHintOpponentDefends.
  ///
  /// In ru, this message translates to:
  /// **'Соперник отбивается'**
  String get durakHintOpponentDefends;

  /// No description provided for @durakHintThrowInFirst.
  ///
  /// In ru, this message translates to:
  /// **'Подкиньте карты или «Все» (макс. 5 в первом отбое)'**
  String get durakHintThrowInFirst;

  /// No description provided for @durakHintThrowIn.
  ///
  /// In ru, this message translates to:
  /// **'Подкиньте карты или нажмите «Все»'**
  String get durakHintThrowIn;

  /// No description provided for @durakHintOpponentThrows.
  ///
  /// In ru, this message translates to:
  /// **'Соперник подкидывает'**
  String get durakHintOpponentThrows;

  /// No description provided for @durakHintTakeFollow.
  ///
  /// In ru, this message translates to:
  /// **'Подкиньте вдогонку или нажмите «Готово»'**
  String get durakHintTakeFollow;

  /// No description provided for @durakHintOpponentTakeFollow.
  ///
  /// In ru, this message translates to:
  /// **'Соперник может подкинуть вдогонку'**
  String get durakHintOpponentTakeFollow;

  /// No description provided for @durakHintBito.
  ///
  /// In ru, this message translates to:
  /// **'Подкиньте карту или скажите «Бито»'**
  String get durakHintBito;

  /// No description provided for @durakHintOpponentBito.
  ///
  /// In ru, this message translates to:
  /// **'Соперник подкидывает или говорит «Бито»'**
  String get durakHintOpponentBito;

  /// No description provided for @durakHintYourAttack.
  ///
  /// In ru, this message translates to:
  /// **'Ваш ход — атакуйте'**
  String get durakHintYourAttack;

  /// No description provided for @durakHintOpponentAttack.
  ///
  /// In ru, this message translates to:
  /// **'Атакует соперник'**
  String get durakHintOpponentAttack;

  /// No description provided for @durakHintYouLost.
  ///
  /// In ru, this message translates to:
  /// **'Вы проиграли — вы дурак'**
  String get durakHintYouLost;

  /// No description provided for @durakHintDrawAllOut.
  ///
  /// In ru, this message translates to:
  /// **'Ничья — все вышли'**
  String get durakHintDrawAllOut;

  /// No description provided for @durakHintYouFinished.
  ///
  /// In ru, this message translates to:
  /// **'Вы вышли — ждём конца партии'**
  String get durakHintYouFinished;

  /// No description provided for @shopPurchaseQueued.
  ///
  /// In ru, this message translates to:
  /// **'Покупка сохранена — применится в режиме онлайн'**
  String get shopPurchaseQueued;

  /// No description provided for @shopPurchaseApplied.
  ///
  /// In ru, this message translates to:
  /// **'{title} — покупка применена'**
  String shopPurchaseApplied(String title);

  /// No description provided for @shopPurchaseRejected.
  ///
  /// In ru, this message translates to:
  /// **'{title} — покупка не применена: {reason}'**
  String shopPurchaseRejected(String title, String reason);

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

  /// No description provided for @settingsAppVersion.
  ///
  /// In ru, this message translates to:
  /// **'Версия {version}'**
  String settingsAppVersion(String version);

  /// No description provided for @appUpdateTitle.
  ///
  /// In ru, this message translates to:
  /// **'Доступно обновление'**
  String get appUpdateTitle;

  /// No description provided for @appUpdateBody.
  ///
  /// In ru, this message translates to:
  /// **'Вышла новая версия приложения. Обновитесь, чтобы продолжить.'**
  String get appUpdateBody;

  /// No description provided for @appUpdateWhatsNew.
  ///
  /// In ru, this message translates to:
  /// **'Что нового'**
  String get appUpdateWhatsNew;

  /// No description provided for @appUpdateOk.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get appUpdateOk;

  /// No description provided for @appUpdateLaterBanner.
  ///
  /// In ru, this message translates to:
  /// **'После партии обновим приложение'**
  String get appUpdateLaterBanner;

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

  /// No description provided for @gamesDurak.
  ///
  /// In ru, this message translates to:
  /// **'Дурак'**
  String get gamesDurak;

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

  /// No description provided for @gamesObservation.
  ///
  /// In ru, this message translates to:
  /// **'Наблюдение'**
  String get gamesObservation;

  /// No description provided for @gamesObservationHint.
  ///
  /// In ru, this message translates to:
  /// **'Можно смотреть до конца партии'**
  String get gamesObservationHint;

  /// No description provided for @gamesFinishCurrentFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала завершите текущую игру'**
  String get gamesFinishCurrentFirst;

  /// No description provided for @gamesVariantClassic.
  ///
  /// In ru, this message translates to:
  /// **'Классика'**
  String get gamesVariantClassic;

  /// No description provided for @gamesVariantGomoku.
  ///
  /// In ru, this message translates to:
  /// **'Гомоку'**
  String get gamesVariantGomoku;

  /// No description provided for @gamesVariantUltimate.
  ///
  /// In ru, this message translates to:
  /// **'Ультимейт'**
  String get gamesVariantUltimate;

  /// No description provided for @gamesVariantMulti3.
  ///
  /// In ru, this message translates to:
  /// **'На троих'**
  String get gamesVariantMulti3;

  /// No description provided for @gamesVariantMulti4.
  ///
  /// In ru, this message translates to:
  /// **'На четверых'**
  String get gamesVariantMulti4;

  /// No description provided for @gamesDurakModePodkidnoi.
  ///
  /// In ru, this message translates to:
  /// **'Подкидной'**
  String get gamesDurakModePodkidnoi;

  /// No description provided for @gamesDurakModePerevodnoi.
  ///
  /// In ru, this message translates to:
  /// **'Переводной'**
  String get gamesDurakModePerevodnoi;

  /// No description provided for @gamesDurakDeck24.
  ///
  /// In ru, this message translates to:
  /// **'24 карты'**
  String get gamesDurakDeck24;

  /// No description provided for @gamesDurakDeck36.
  ///
  /// In ru, this message translates to:
  /// **'36 карт'**
  String get gamesDurakDeck36;

  /// No description provided for @gamesDurakDeck52.
  ///
  /// In ru, this message translates to:
  /// **'52 карты'**
  String get gamesDurakDeck52;

  /// No description provided for @rulesDurakMode.
  ///
  /// In ru, this message translates to:
  /// **'Режим: {mode}'**
  String rulesDurakMode(String mode);

  /// No description provided for @rulesDurakPlayersDeck.
  ///
  /// In ru, this message translates to:
  /// **'Игроки: {players}. Колода: {deck}.'**
  String rulesDurakPlayersDeck(int players, String deck);

  /// No description provided for @rulesDurakOfflineBot.
  ///
  /// In ru, this message translates to:
  /// **'Игра против бота, без ставок и лимита времени.'**
  String get rulesDurakOfflineBot;

  /// No description provided for @rulesDurakAttack.
  ///
  /// In ru, this message translates to:
  /// **'Атакующий кладёт карты, защитник бьёт (той же масти старше или козырем). Козырь бьётся только козырем старше.'**
  String get rulesDurakAttack;

  /// No description provided for @rulesDurakBeat.
  ///
  /// In ru, this message translates to:
  /// **'Когда все карты биты — атакующий говорит «Бито», карты уходят в отбой. Иначе защитник берёт всё со стола.'**
  String get rulesDurakBeat;

  /// No description provided for @rulesDurakLoser.
  ///
  /// In ru, this message translates to:
  /// **'Проигравший — у кого в конце партии остались карты, «дурак».'**
  String get rulesDurakLoser;

  /// No description provided for @lobbyPlayersCount.
  ///
  /// In ru, this message translates to:
  /// **'Игроки {count}/{maxPlayers}'**
  String lobbyPlayersCount(int count, int maxPlayers);

  /// No description provided for @lobbyNamed.
  ///
  /// In ru, this message translates to:
  /// **'Лобби {name}'**
  String lobbyNamed(String name);

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

  /// No description provided for @lobbyPlayersSearching.
  ///
  /// In ru, this message translates to:
  /// **'Ищут эту игру: {count}'**
  String lobbyPlayersSearching(int count);

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

  /// No description provided for @lobbyGone.
  ///
  /// In ru, this message translates to:
  /// **'Этой игры уже нет'**
  String get lobbyGone;

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

  /// No description provided for @gameSurrender.
  ///
  /// In ru, this message translates to:
  /// **'Сдаться'**
  String get gameSurrender;

  /// No description provided for @gameSurrenderTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сдаться?'**
  String get gameSurrenderTitle;

  /// No description provided for @gameSurrenderConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Если вы сдадитесь, вы проиграете. Сдаться?'**
  String get gameSurrenderConfirm;

  /// No description provided for @gameOfferDraw.
  ///
  /// In ru, this message translates to:
  /// **'Предложить ничью'**
  String get gameOfferDraw;

  /// No description provided for @gameOfferDrawTitle.
  ///
  /// In ru, this message translates to:
  /// **'Предложить ничью?'**
  String get gameOfferDrawTitle;

  /// No description provided for @gameOfferDrawConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Отправить сопернику предложение ничьей?'**
  String get gameOfferDrawConfirm;

  /// No description provided for @gameAcceptDrawTitle.
  ///
  /// In ru, this message translates to:
  /// **'Принять ничью?'**
  String get gameAcceptDrawTitle;

  /// No description provided for @gameAcceptDrawConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Соперник предлагает ничью. Принять?'**
  String get gameAcceptDrawConfirm;

  /// No description provided for @gameDrawOffered.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание ответа'**
  String get gameDrawOffered;

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

  /// No description provided for @chatPaste.
  ///
  /// In ru, this message translates to:
  /// **'Вставить'**
  String get chatPaste;

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
  /// **'Разблокировка повышенных ставок'**
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

  /// No description provided for @balanceTitle.
  ///
  /// In ru, this message translates to:
  /// **'Баланс'**
  String get balanceTitle;

  /// No description provided for @coinBronze.
  ///
  /// In ru, this message translates to:
  /// **'Бронза'**
  String get coinBronze;

  /// No description provided for @coinSilver.
  ///
  /// In ru, this message translates to:
  /// **'Серебро'**
  String get coinSilver;

  /// No description provided for @coinGold.
  ///
  /// In ru, this message translates to:
  /// **'Золото'**
  String get coinGold;

  /// No description provided for @coinDiamond.
  ///
  /// In ru, this message translates to:
  /// **'Бриллиант'**
  String get coinDiamond;

  /// No description provided for @balanceZeroBronze.
  ///
  /// In ru, this message translates to:
  /// **'0 бронзовых'**
  String get balanceZeroBronze;

  /// No description provided for @balanceBronzes.
  ///
  /// In ru, this message translates to:
  /// **'{count} бронзовых'**
  String balanceBronzes(int count);

  /// No description provided for @balanceSilvers.
  ///
  /// In ru, this message translates to:
  /// **'{count} серебряных'**
  String balanceSilvers(int count);

  /// No description provided for @balanceGolds.
  ///
  /// In ru, this message translates to:
  /// **'{count} золотых'**
  String balanceGolds(int count);

  /// No description provided for @balanceDiamonds.
  ///
  /// In ru, this message translates to:
  /// **'{count} бриллиантов'**
  String balanceDiamonds(int count);

  /// No description provided for @balancePerDay.
  ///
  /// In ru, this message translates to:
  /// **'{amount}/день'**
  String balancePerDay(String amount);

  /// No description provided for @balanceAbbrBronze.
  ///
  /// In ru, this message translates to:
  /// **'бр'**
  String get balanceAbbrBronze;

  /// No description provided for @balanceAbbrSilver.
  ///
  /// In ru, this message translates to:
  /// **'с.'**
  String get balanceAbbrSilver;

  /// No description provided for @balanceAbbrGold.
  ///
  /// In ru, this message translates to:
  /// **'з.'**
  String get balanceAbbrGold;

  /// No description provided for @commonBackHome.
  ///
  /// In ru, this message translates to:
  /// **'Назад на главную'**
  String get commonBackHome;

  /// No description provided for @commonCopied.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано'**
  String get commonCopied;

  /// No description provided for @commonClear.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get commonClear;

  /// No description provided for @commonTryLater.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте позже.'**
  String get commonTryLater;

  /// No description provided for @commonTryRefresh.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте обновить страницу.'**
  String get commonTryRefresh;

  /// No description provided for @coinsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Монеты'**
  String get coinsTitle;

  /// No description provided for @coinsLoginReward.
  ///
  /// In ru, this message translates to:
  /// **'Монеты за вход'**
  String get coinsLoginReward;

  /// No description provided for @coinsLoginAvailableToday.
  ///
  /// In ru, this message translates to:
  /// **'Доступна награда за сегодня'**
  String get coinsLoginAvailableToday;

  /// No description provided for @coinsLoginStreak.
  ///
  /// In ru, this message translates to:
  /// **'Ежедневная серия входов'**
  String get coinsLoginStreak;

  /// No description provided for @coinsFriendReward.
  ///
  /// In ru, this message translates to:
  /// **'Монеты за друга'**
  String get coinsFriendReward;

  /// No description provided for @coinsFriendRewardHint.
  ///
  /// In ru, this message translates to:
  /// **'+{amount} за регистрацию по ссылке'**
  String coinsFriendRewardHint(String amount);

  /// No description provided for @coinsLoadRewardsFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить награды'**
  String get coinsLoadRewardsFailed;

  /// No description provided for @coinsClaimReward.
  ///
  /// In ru, this message translates to:
  /// **'Забрать награду'**
  String get coinsClaimReward;

  /// No description provided for @coinsAlreadyClaimed.
  ///
  /// In ru, this message translates to:
  /// **'Уже получено'**
  String get coinsAlreadyClaimed;

  /// No description provided for @coinsStreakToday.
  ///
  /// In ru, this message translates to:
  /// **'{done}/{target} · сегодня'**
  String coinsStreakToday(int done, int target);

  /// No description provided for @coinsStreakOneDayLeft.
  ///
  /// In ru, this message translates to:
  /// **'{done}/{target} · ещё 1 день'**
  String coinsStreakOneDayLeft(int done, int target);

  /// No description provided for @coinsStreakDaysLeft.
  ///
  /// In ru, this message translates to:
  /// **'{done}/{target} · ещё {remaining}'**
  String coinsStreakDaysLeft(int done, int target, int remaining);

  /// No description provided for @coinsInviteFriend.
  ///
  /// In ru, this message translates to:
  /// **'Пригласи друга'**
  String get coinsInviteFriend;

  /// No description provided for @coinsInviteHint.
  ///
  /// In ru, this message translates to:
  /// **'+{amount} за каждого, кто зарегистрируется по вашей ссылке'**
  String coinsInviteHint(String amount);

  /// No description provided for @coinsCopyLink.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать ссылку'**
  String get coinsCopyLink;

  /// No description provided for @coinsHowItWorks.
  ///
  /// In ru, this message translates to:
  /// **'Как это работает'**
  String get coinsHowItWorks;

  /// No description provided for @coinsHowStep1.
  ///
  /// In ru, this message translates to:
  /// **'Скопируйте ссылку и отправьте другу'**
  String get coinsHowStep1;

  /// No description provided for @coinsHowStep2.
  ///
  /// In ru, this message translates to:
  /// **'Друг регистрируется по этой ссылке'**
  String get coinsHowStep2;

  /// No description provided for @coinsHowStep3.
  ///
  /// In ru, this message translates to:
  /// **'Вам начисляется {amount}'**
  String coinsHowStep3(String amount);

  /// No description provided for @achievementsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Достижения'**
  String get achievementsTitle;

  /// No description provided for @achievementsProgress.
  ///
  /// In ru, this message translates to:
  /// **'Прогресс: {progress}'**
  String achievementsProgress(String progress);

  /// No description provided for @achievementsFrameClaimed.
  ///
  /// In ru, this message translates to:
  /// **'Рамка получена'**
  String get achievementsFrameClaimed;

  /// No description provided for @achievementsClaimed.
  ///
  /// In ru, this message translates to:
  /// **'Получено'**
  String get achievementsClaimed;

  /// No description provided for @achievementsOpenFrame.
  ///
  /// In ru, this message translates to:
  /// **'Открыть рамку'**
  String get achievementsOpenFrame;

  /// No description provided for @friendsRemoveConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Вы уверены, что хотите удалить {name} из друзей?'**
  String friendsRemoveConfirm(String name);

  /// No description provided for @friendsRemoveConfirmAction.
  ///
  /// In ru, this message translates to:
  /// **'Убрать'**
  String get friendsRemoveConfirmAction;

  /// No description provided for @friendsRemove.
  ///
  /// In ru, this message translates to:
  /// **'Удалить из друзей'**
  String get friendsRemove;

  /// No description provided for @friendsAcceptRequest.
  ///
  /// In ru, this message translates to:
  /// **'Принять заявку'**
  String get friendsAcceptRequest;

  /// No description provided for @friendsDeclineRequest.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить заявку'**
  String get friendsDeclineRequest;

  /// No description provided for @friendsCancelRequest.
  ///
  /// In ru, this message translates to:
  /// **'Отменить заявку'**
  String get friendsCancelRequest;

  /// No description provided for @friendsSendRequest.
  ///
  /// In ru, this message translates to:
  /// **'Отправить заявку в друзья'**
  String get friendsSendRequest;

  /// No description provided for @friendsRequestAlreadySent.
  ///
  /// In ru, this message translates to:
  /// **'Заявка уже отправлена'**
  String get friendsRequestAlreadySent;

  /// No description provided for @friendsIncomingStatus.
  ///
  /// In ru, this message translates to:
  /// **'Входящая заявка'**
  String get friendsIncomingStatus;

  /// No description provided for @friendsOutgoingStatus.
  ///
  /// In ru, this message translates to:
  /// **'Исходящая заявка'**
  String get friendsOutgoingStatus;

  /// No description provided for @friendsNotFriends.
  ///
  /// In ru, this message translates to:
  /// **'Не в друзьях'**
  String get friendsNotFriends;

  /// No description provided for @friendsCollapseSearch.
  ///
  /// In ru, this message translates to:
  /// **'Свернуть поиск'**
  String get friendsCollapseSearch;

  /// No description provided for @friendsExpandSearch.
  ///
  /// In ru, this message translates to:
  /// **'Показать поиск'**
  String get friendsExpandSearch;

  /// No description provided for @friendsLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить друзей'**
  String get friendsLoadFailed;

  /// No description provided for @friendsSince.
  ///
  /// In ru, this message translates to:
  /// **'Дружите с: {date}'**
  String friendsSince(String date);

  /// No description provided for @friendsIncomingAt.
  ///
  /// In ru, this message translates to:
  /// **'Входящая заявка: {date}'**
  String friendsIncomingAt(String date);

  /// No description provided for @friendsOutgoingAt.
  ///
  /// In ru, this message translates to:
  /// **'Исходящая заявка: {date}'**
  String friendsOutgoingAt(String date);

  /// No description provided for @userInfoTitle.
  ///
  /// In ru, this message translates to:
  /// **'Информация о пользователе'**
  String get userInfoTitle;

  /// No description provided for @profileAgeYears.
  ///
  /// In ru, this message translates to:
  /// **'{age} лет'**
  String profileAgeYears(int age);

  /// No description provided for @shopBuy.
  ///
  /// In ru, this message translates to:
  /// **'Купить'**
  String get shopBuy;

  /// No description provided for @shopBuyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Купить?'**
  String get shopBuyTitle;

  /// No description provided for @shopBuyStakeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Купить ставку?'**
  String get shopBuyStakeTitle;

  /// No description provided for @shopBuyEmojiTitle.
  ///
  /// In ru, this message translates to:
  /// **'Купить смайлик?'**
  String get shopBuyEmojiTitle;

  /// No description provided for @shopBuyCollectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Купить коллекцию?'**
  String get shopBuyCollectionTitle;

  /// No description provided for @shopPrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена: {price}'**
  String shopPrice(String price);

  /// No description provided for @shopOwned.
  ///
  /// In ru, this message translates to:
  /// **'Куплено'**
  String get shopOwned;

  /// No description provided for @shopEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока пусто'**
  String get shopEmpty;

  /// No description provided for @shopPurchased.
  ///
  /// In ru, this message translates to:
  /// **'{title} куплен'**
  String shopPurchased(String title);

  /// No description provided for @shopEmojiUses.
  ///
  /// In ru, this message translates to:
  /// **'Получите: 10 использований'**
  String get shopEmojiUses;

  /// No description provided for @shopEmojiBought.
  ///
  /// In ru, this message translates to:
  /// **'{title}: +10 использований'**
  String shopEmojiBought(String title);

  /// No description provided for @shopEmojiPriceUses.
  ///
  /// In ru, this message translates to:
  /// **'{price} · 10 использований'**
  String shopEmojiPriceUses(String price);

  /// No description provided for @shopBuyTen.
  ///
  /// In ru, this message translates to:
  /// **'Купить · 10 шт.'**
  String get shopBuyTen;

  /// No description provided for @shopDailyIncome.
  ///
  /// In ru, this message translates to:
  /// **'Доход: {amount}'**
  String shopDailyIncome(String amount);

  /// No description provided for @shopBuyOnce.
  ///
  /// In ru, this message translates to:
  /// **'Покупка один раз'**
  String get shopBuyOnce;

  /// No description provided for @shopSellRefund.
  ///
  /// In ru, this message translates to:
  /// **'Продажа вернет 80% стоимости'**
  String get shopSellRefund;

  /// No description provided for @shopCollectionAdded.
  ///
  /// In ru, this message translates to:
  /// **'{title} добавлен в профиль'**
  String shopCollectionAdded(String title);

  /// No description provided for @shopSetBonus.
  ///
  /// In ru, this message translates to:
  /// **'бонус группы +{percent}%'**
  String shopSetBonus(int percent);

  /// No description provided for @shopSetComplete.
  ///
  /// In ru, this message translates to:
  /// **'Собрано'**
  String get shopSetComplete;

  /// No description provided for @shopSetProgress.
  ///
  /// In ru, this message translates to:
  /// **'Собрано · {owned}/{total}'**
  String shopSetProgress(int owned, int total);

  /// No description provided for @inventorySellTitle.
  ///
  /// In ru, this message translates to:
  /// **'Продать?'**
  String get inventorySellTitle;

  /// No description provided for @inventorySellDesc.
  ///
  /// In ru, this message translates to:
  /// **'Вы получите {amount}'**
  String inventorySellDesc(String amount);

  /// No description provided for @inventorySold.
  ///
  /// In ru, this message translates to:
  /// **'Продано: +{amount}'**
  String inventorySold(String amount);

  /// No description provided for @inventoryNeedFriends.
  ///
  /// In ru, this message translates to:
  /// **'Сначала добавьте друзей'**
  String get inventoryNeedFriends;

  /// No description provided for @inventoryGiftTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подарить коллекцию?'**
  String get inventoryGiftTitle;

  /// No description provided for @inventoryGiftDesc.
  ///
  /// In ru, this message translates to:
  /// **'Подарить «{title}» пользователю {name}?'**
  String inventoryGiftDesc(String title, String name);

  /// No description provided for @inventoryGifted.
  ///
  /// In ru, this message translates to:
  /// **'Подарено: {title}'**
  String inventoryGifted(String title);

  /// No description provided for @inventoryGiftAlreadyOwns.
  ///
  /// In ru, this message translates to:
  /// **'У этого пользователя уже есть эта коллекция'**
  String get inventoryGiftAlreadyOwns;

  /// No description provided for @inventoryGiftSelf.
  ///
  /// In ru, this message translates to:
  /// **'Нельзя подарить коллекцию самому себе'**
  String get inventoryGiftSelf;

  /// No description provided for @inventoryGiftNotOwned.
  ///
  /// In ru, this message translates to:
  /// **'У вас нет этого предмета'**
  String get inventoryGiftNotOwned;

  /// No description provided for @inventoryLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить предметы'**
  String get inventoryLoadFailed;

  /// No description provided for @inventoryNoCollections.
  ///
  /// In ru, this message translates to:
  /// **'Нет коллекций — купите в магазине'**
  String get inventoryNoCollections;

  /// No description provided for @inventoryNoEmojis.
  ///
  /// In ru, this message translates to:
  /// **'Нет смайликов — купите в магазине'**
  String get inventoryNoEmojis;

  /// No description provided for @inventoryNoFrames.
  ///
  /// In ru, this message translates to:
  /// **'Нет рамок — выиграйте 10 игр в лиге (достижения)'**
  String get inventoryNoFrames;

  /// No description provided for @inventoryNoStakes.
  ///
  /// In ru, this message translates to:
  /// **'Нет купленных ставок'**
  String get inventoryNoStakes;

  /// No description provided for @inventoryEmojiLeft.
  ///
  /// In ru, this message translates to:
  /// **'Осталось {count}'**
  String inventoryEmojiLeft(int count);

  /// No description provided for @inventoryIncomeReady.
  ///
  /// In ru, this message translates to:
  /// **'Доход: +{amount}'**
  String inventoryIncomeReady(String amount);

  /// No description provided for @inventoryIncomeTomorrow.
  ///
  /// In ru, this message translates to:
  /// **'Доход завтра: {amount}'**
  String inventoryIncomeTomorrow(String amount);

  /// No description provided for @inventoryIncomeReadyLabel.
  ///
  /// In ru, this message translates to:
  /// **'Доход:'**
  String get inventoryIncomeReadyLabel;

  /// No description provided for @inventoryIncomeTomorrowLabel.
  ///
  /// In ru, this message translates to:
  /// **'Доход завтра:'**
  String get inventoryIncomeTomorrowLabel;

  /// No description provided for @inventoryStakeGold.
  ///
  /// In ru, this message translates to:
  /// **'Можно ставить {amount} золота'**
  String inventoryStakeGold(String amount);

  /// No description provided for @inventoryStakeSilver.
  ///
  /// In ru, this message translates to:
  /// **'Можно ставить {amount} серебра'**
  String inventoryStakeSilver(String amount);

  /// No description provided for @inventoryClaimedAmount.
  ///
  /// In ru, this message translates to:
  /// **'Получено +{amount}'**
  String inventoryClaimedAmount(String amount);

  /// No description provided for @chatsLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить чаты'**
  String get chatsLoadFailed;

  /// No description provided for @chatsLoadListFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить список'**
  String get chatsLoadListFailed;

  /// No description provided for @chatsBlockedEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Список пуст'**
  String get chatsBlockedEmpty;

  /// No description provided for @chatsBlockedAt.
  ///
  /// In ru, this message translates to:
  /// **'Заблокирован: {date}'**
  String chatsBlockedAt(String date);

  /// No description provided for @chatsCreateFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать чат'**
  String get chatsCreateFailed;

  /// No description provided for @chatsNeedFriendsFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала добавьте друзей, потом можно открыть чат.'**
  String get chatsNeedFriendsFirst;

  /// No description provided for @chatsFriendsNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Друзья не найдены'**
  String get chatsFriendsNotFound;

  /// No description provided for @chatsFindFriendHint.
  ///
  /// In ru, this message translates to:
  /// **'Найти друга по нику'**
  String get chatsFindFriendHint;

  /// No description provided for @chatsSelectChat.
  ///
  /// In ru, this message translates to:
  /// **'Выберите чат'**
  String get chatsSelectChat;

  /// No description provided for @chatsSelectHint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите диалог из списка слева'**
  String get chatsSelectHint;

  /// No description provided for @chatEditFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось изменить сообщение'**
  String get chatEditFailed;

  /// No description provided for @chatSendFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить сообщение'**
  String get chatSendFailed;

  /// No description provided for @chatDeleteFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить сообщение'**
  String get chatDeleteFailed;

  /// No description provided for @chatEmojiSendFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить смайлик'**
  String get chatEmojiSendFailed;

  /// No description provided for @chatLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить сообщения'**
  String get chatLoadFailed;

  /// No description provided for @chatBackToGame.
  ///
  /// In ru, this message translates to:
  /// **'Назад в игру'**
  String get chatBackToGame;

  /// No description provided for @chatBackToChats.
  ///
  /// In ru, this message translates to:
  /// **'Назад к чатам'**
  String get chatBackToChats;

  /// No description provided for @chatActions.
  ///
  /// In ru, this message translates to:
  /// **'Действия с чатом'**
  String get chatActions;

  /// No description provided for @chatAutoTranslate.
  ///
  /// In ru, this message translates to:
  /// **'Автоперевод'**
  String get chatAutoTranslate;

  /// No description provided for @chatScrollToEnd.
  ///
  /// In ru, this message translates to:
  /// **'В конец переписки'**
  String get chatScrollToEnd;

  /// No description provided for @chatReplyingTo.
  ///
  /// In ru, this message translates to:
  /// **'В ответ {name}'**
  String chatReplyingTo(String name);

  /// No description provided for @chatGift.
  ///
  /// In ru, this message translates to:
  /// **'Подарок'**
  String get chatGift;

  /// No description provided for @chatCollection.
  ///
  /// In ru, this message translates to:
  /// **'Коллекция'**
  String get chatCollection;

  /// No description provided for @chatGiftCollection.
  ///
  /// In ru, this message translates to:
  /// **'Подарок · коллекция'**
  String get chatGiftCollection;

  /// No description provided for @chatThisUser.
  ///
  /// In ru, this message translates to:
  /// **'этого пользователя'**
  String get chatThisUser;

  /// No description provided for @gamesLobbyLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить лобби.'**
  String get gamesLobbyLoadFailed;

  /// No description provided for @gamesTapChangeStake.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите для смены ставки'**
  String get gamesTapChangeStake;

  /// No description provided for @gamesTapChangeTurnTime.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите для смены времени на ход'**
  String get gamesTapChangeTurnTime;

  /// No description provided for @gamesTapChangeGrid.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите для смены размера сетки'**
  String get gamesTapChangeGrid;

  /// No description provided for @gamesSwapSidesHint.
  ///
  /// In ru, this message translates to:
  /// **'O может стать X после 1-го хода'**
  String get gamesSwapSidesHint;

  /// No description provided for @gamesNoCenterHint.
  ///
  /// In ru, this message translates to:
  /// **'Первый ход не в центр'**
  String get gamesNoCenterHint;

  /// No description provided for @lobbyInviteSentShort.
  ///
  /// In ru, this message translates to:
  /// **'Отправлено'**
  String get lobbyInviteSentShort;

  /// No description provided for @lobbyInvitesSentWaiting.
  ///
  /// In ru, this message translates to:
  /// **'Приглашения отправлены. Ожидайте ответа.'**
  String get lobbyInvitesSentWaiting;

  /// No description provided for @lobbyLinkCopiedHint.
  ///
  /// In ru, this message translates to:
  /// **'Вставьте её в чат или сообщение другу'**
  String get lobbyLinkCopiedHint;

  /// No description provided for @lobbyCopyLinkHint.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать ссылку в буфер обмена'**
  String get lobbyCopyLinkHint;

  /// No description provided for @lobbyCreatorInvites.
  ///
  /// In ru, this message translates to:
  /// **'{name} приглашает вас сыграть'**
  String lobbyCreatorInvites(String name);

  /// No description provided for @gameOpponentWon.
  ///
  /// In ru, this message translates to:
  /// **'Победил {name}'**
  String gameOpponentWon(String name);

  /// No description provided for @gameOpponentWonTimeout.
  ///
  /// In ru, this message translates to:
  /// **'Время вышло. Победил {name}'**
  String gameOpponentWonTimeout(String name);

  /// No description provided for @gameSecondsLeft.
  ///
  /// In ru, this message translates to:
  /// **'{seconds} с'**
  String gameSecondsLeft(int seconds);

  /// No description provided for @adminTitle.
  ///
  /// In ru, this message translates to:
  /// **'Админка'**
  String get adminTitle;

  /// No description provided for @tournamentsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Турниры'**
  String get tournamentsTitle;

  /// No description provided for @profileAgeInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Введите возраст от 1 до 111'**
  String get profileAgeInvalid;

  /// No description provided for @profileSaveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить профиль'**
  String get profileSaveFailed;

  /// No description provided for @profileNameHint.
  ///
  /// In ru, this message translates to:
  /// **'Латиница, цифры, _ до 10 символов'**
  String get profileNameHint;

  /// No description provided for @profileNameLatinOnly.
  ///
  /// In ru, this message translates to:
  /// **'Только латинские символы'**
  String get profileNameLatinOnly;

  /// No description provided for @profileAgeHint.
  ///
  /// In ru, this message translates to:
  /// **'От 1 до 111'**
  String get profileAgeHint;

  /// No description provided for @profileAboutHint.
  ///
  /// In ru, this message translates to:
  /// **'До 100 символов (по желанию)'**
  String get profileAboutHint;

  /// No description provided for @profileProcessingPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Обработка фото…'**
  String get profileProcessingPhoto;

  /// No description provided for @profileCropTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выбери область аватара'**
  String get profileCropTitle;

  /// No description provided for @profileCropHint.
  ///
  /// In ru, this message translates to:
  /// **'Масштабируй и двигай фото'**
  String get profileCropHint;

  /// No description provided for @profileApply.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get profileApply;

  /// No description provided for @profilePreparing.
  ///
  /// In ru, this message translates to:
  /// **'Подготовка…'**
  String get profilePreparing;

  /// No description provided for @timeSecondsShort.
  ///
  /// In ru, this message translates to:
  /// **'{seconds} с'**
  String timeSecondsShort(int seconds);

  /// No description provided for @timeOneMin.
  ///
  /// In ru, this message translates to:
  /// **'1 мин'**
  String get timeOneMin;

  /// No description provided for @timeTenMin.
  ///
  /// In ru, this message translates to:
  /// **'10 мин'**
  String get timeTenMin;

  /// No description provided for @rulesIntro.
  ///
  /// In ru, this message translates to:
  /// **'Крестики-нолики на поле {grid}. Ходят по очереди, X начинает.'**
  String rulesIntro(String grid);

  /// No description provided for @rulesWin.
  ///
  /// In ru, this message translates to:
  /// **'Победа: нужно выстроить {n} в ряд по горизонтали, вертикали или диагонали.'**
  String rulesWin(int n);

  /// No description provided for @rulesNoTimeLimit.
  ///
  /// In ru, this message translates to:
  /// **'Без ограничения по времени на ход.'**
  String get rulesNoTimeLimit;

  /// No description provided for @rulesTurnTime.
  ///
  /// In ru, this message translates to:
  /// **'Время на ход: {time}.'**
  String rulesTurnTime(String time);

  /// No description provided for @rulesStake.
  ///
  /// In ru, this message translates to:
  /// **'Ставка: {stake}. На столько монет идёт игра.'**
  String rulesStake(String stake);

  /// No description provided for @rulesSwap.
  ///
  /// In ru, this message translates to:
  /// **'Смена сторон: O может поменяться местами с X после первого хода X.'**
  String get rulesSwap;

  /// No description provided for @rulesNoCenter.
  ///
  /// In ru, this message translates to:
  /// **'Запрет центра: X не может ходить в центр первым ходом.'**
  String get rulesNoCenter;

  /// No description provided for @collectionSetLegends.
  ///
  /// In ru, this message translates to:
  /// **'Легенды'**
  String get collectionSetLegends;

  /// No description provided for @collectionSetSpace.
  ///
  /// In ru, this message translates to:
  /// **'Космос'**
  String get collectionSetSpace;

  /// No description provided for @collectionSetGems.
  ///
  /// In ru, this message translates to:
  /// **'Драгоценности'**
  String get collectionSetGems;

  /// No description provided for @collectionSetParty.
  ///
  /// In ru, this message translates to:
  /// **'Праздник'**
  String get collectionSetParty;

  /// No description provided for @collectionSetNature.
  ///
  /// In ru, this message translates to:
  /// **'Природа'**
  String get collectionSetNature;

  /// No description provided for @collectionSetAdventures.
  ///
  /// In ru, this message translates to:
  /// **'Приключения'**
  String get collectionSetAdventures;

  /// No description provided for @collectionCardMeta.
  ///
  /// In ru, this message translates to:
  /// **'Коллекция · витрина · подарок · продажа · +{amount}'**
  String collectionCardMeta(String amount);

  /// No description provided for @coinsDayOne.
  ///
  /// In ru, this message translates to:
  /// **'день'**
  String get coinsDayOne;

  /// No description provided for @coinsDayFew.
  ///
  /// In ru, this message translates to:
  /// **'дня'**
  String get coinsDayFew;

  /// No description provided for @coinsDayMany.
  ///
  /// In ru, this message translates to:
  /// **'дней'**
  String get coinsDayMany;

  /// No description provided for @giftFriendTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подарить другу'**
  String get giftFriendTitle;

  /// No description provided for @photoCount.
  ///
  /// In ru, this message translates to:
  /// **'Фото ({count})'**
  String photoCount(int count);

  /// No description provided for @photoCountWithText.
  ///
  /// In ru, this message translates to:
  /// **'Фото ({count}): {text}'**
  String photoCountWithText(int count, String text);

  /// No description provided for @photoWithText.
  ///
  /// In ru, this message translates to:
  /// **'Фото: {text}'**
  String photoWithText(String text);

  /// No description provided for @shopEmojiGroupMeta.
  ///
  /// In ru, this message translates to:
  /// **'{count} смайликов · по {price}'**
  String shopEmojiGroupMeta(int count, String price);

  /// No description provided for @chatsExpandPanel.
  ///
  /// In ru, this message translates to:
  /// **'Развернуть панель'**
  String get chatsExpandPanel;

  /// No description provided for @chatsCollapsePanel.
  ///
  /// In ru, this message translates to:
  /// **'Свернуть панель'**
  String get chatsCollapsePanel;

  /// No description provided for @chatReplySourceMissing.
  ///
  /// In ru, this message translates to:
  /// **'Исходное сообщение не найдено'**
  String get chatReplySourceMissing;

  /// No description provided for @shopStakeTitleSilver.
  ///
  /// In ru, this message translates to:
  /// **'Ставка {n} серебра'**
  String shopStakeTitleSilver(int n);

  /// No description provided for @shopStakeTitleGold.
  ///
  /// In ru, this message translates to:
  /// **'Ставка {n} золота'**
  String shopStakeTitleGold(int n);

  /// No description provided for @shopStakeDescSilver.
  ///
  /// In ru, this message translates to:
  /// **'Право ставить {n} серебра в играх'**
  String shopStakeDescSilver(int n);

  /// No description provided for @shopStakeDescGold.
  ///
  /// In ru, this message translates to:
  /// **'Право ставить {n} золота в играх'**
  String shopStakeDescGold(int n);

  /// No description provided for @chatReplySelf.
  ///
  /// In ru, this message translates to:
  /// **'себе'**
  String get chatReplySelf;

  /// No description provided for @chatReplyPeer.
  ///
  /// In ru, this message translates to:
  /// **'собеседнику'**
  String get chatReplyPeer;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Мы отправили код на {email}'**
  String verifyEmailSubtitle(String email);

  /// No description provided for @verifyEmailCodeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Код из письма'**
  String get verifyEmailCodeLabel;

  /// No description provided for @verifyEmailCodeRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите код'**
  String get verifyEmailCodeRequired;

  /// No description provided for @verifyEmailSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get verifyEmailSubmit;

  /// No description provided for @verifyEmailResend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код ещё раз'**
  String get verifyEmailResend;

  /// No description provided for @verifyEmailResent.
  ///
  /// In ru, this message translates to:
  /// **'Новый код отправлен'**
  String get verifyEmailResent;

  /// No description provided for @oauthOrContinue.
  ///
  /// In ru, this message translates to:
  /// **'или войти через'**
  String get oauthOrContinue;

  /// No description provided for @oauthGoogle.
  ///
  /// In ru, this message translates to:
  /// **'Google'**
  String get oauthGoogle;

  /// No description provided for @oauthApple.
  ///
  /// In ru, this message translates to:
  /// **'Apple'**
  String get oauthApple;

  /// No description provided for @oauthYandex.
  ///
  /// In ru, this message translates to:
  /// **'Яндекс'**
  String get oauthYandex;

  /// No description provided for @oauthVK.
  ///
  /// In ru, this message translates to:
  /// **'VK'**
  String get oauthVK;

  /// No description provided for @oauthError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти через сервис'**
  String get oauthError;

  /// No description provided for @oauthCallbackTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вход…'**
  String get oauthCallbackTitle;

  /// No description provided for @verifyEmailResendIn.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код ещё раз через {time}'**
  String verifyEmailResendIn(String time);

  /// No description provided for @verifyEmailDevCodeHint.
  ///
  /// In ru, this message translates to:
  /// **'Почта ещё не настроена на сервере. Код для входа: {code}'**
  String verifyEmailDevCodeHint(String code);

  /// No description provided for @loginForgotPassword.
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get loginForgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сброс пароля'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Введите email или логин — пришлём код на почту аккаунта'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код'**
  String get forgotPasswordSubmit;

  /// No description provided for @forgotPasswordSent.
  ///
  /// In ru, this message translates to:
  /// **'Если аккаунт существует, код отправлен на почту'**
  String get forgotPasswordSent;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Код отправлен на {email}'**
  String resetPasswordSubtitle(String email);

  /// No description provided for @resetPasswordCodeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Код из письма'**
  String get resetPasswordCodeLabel;

  /// No description provided for @resetPasswordCodeRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите код'**
  String get resetPasswordCodeRequired;

  /// No description provided for @resetPasswordNewLabel.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get resetPasswordNewLabel;

  /// No description provided for @resetPasswordNewRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите новый пароль'**
  String get resetPasswordNewRequired;

  /// No description provided for @resetPasswordNewShort.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 6 символов'**
  String get resetPasswordNewShort;

  /// No description provided for @resetPasswordConfirmLabel.
  ///
  /// In ru, this message translates to:
  /// **'Повторите пароль'**
  String get resetPasswordConfirmLabel;

  /// No description provided for @resetPasswordConfirmMismatch.
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают'**
  String get resetPasswordConfirmMismatch;

  /// No description provided for @resetPasswordSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить пароль'**
  String get resetPasswordSubmit;

  /// No description provided for @resetPasswordResend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код ещё раз'**
  String get resetPasswordResend;

  /// No description provided for @resetPasswordResent.
  ///
  /// In ru, this message translates to:
  /// **'Новый код отправлен'**
  String get resetPasswordResent;

  /// No description provided for @resetPasswordResendIn.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код ещё раз через {time}'**
  String resetPasswordResendIn(String time);

  /// No description provided for @resetPasswordBackToLogin.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться ко входу'**
  String get resetPasswordBackToLogin;

  /// No description provided for @statsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Статистика'**
  String get statsTitle;

  /// No description provided for @statsLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить статистику'**
  String get statsLoadFailed;

  /// No description provided for @statsAllGames.
  ///
  /// In ru, this message translates to:
  /// **'Все игры'**
  String get statsAllGames;

  /// No description provided for @statsEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет сыгранных партий'**
  String get statsEmptyTitle;

  /// No description provided for @statsEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Сыграйте первую игру, чтобы здесь появилась статистика.'**
  String get statsEmptyHint;

  /// No description provided for @statsWins.
  ///
  /// In ru, this message translates to:
  /// **'Победы'**
  String get statsWins;

  /// No description provided for @statsDraws.
  ///
  /// In ru, this message translates to:
  /// **'Ничьи'**
  String get statsDraws;

  /// No description provided for @statsLosses.
  ///
  /// In ru, this message translates to:
  /// **'Поражения'**
  String get statsLosses;

  /// No description provided for @statsWinRate.
  ///
  /// In ru, this message translates to:
  /// **'Процент побед'**
  String get statsWinRate;

  /// No description provided for @statsTopWon.
  ///
  /// In ru, this message translates to:
  /// **'Больше всего выиграл у'**
  String get statsTopWon;

  /// No description provided for @statsTopDrawn.
  ///
  /// In ru, this message translates to:
  /// **'Больше всего ничьих с'**
  String get statsTopDrawn;

  /// No description provided for @statsTopLost.
  ///
  /// In ru, this message translates to:
  /// **'Больше всего проиграл'**
  String get statsTopLost;

  /// No description provided for @statsTimePlayed.
  ///
  /// In ru, this message translates to:
  /// **'Время в игре'**
  String get statsTimePlayed;

  /// No description provided for @statsYourScore.
  ///
  /// In ru, this message translates to:
  /// **'Ваш счёт'**
  String get statsYourScore;

  /// No description provided for @profileShowStats.
  ///
  /// In ru, this message translates to:
  /// **'Показывать статистику'**
  String get profileShowStats;

  /// No description provided for @statsDurationZeroMinutes.
  ///
  /// In ru, this message translates to:
  /// **'0 мин'**
  String get statsDurationZeroMinutes;

  /// No description provided for @gameYouWonOpponentForfeit.
  ///
  /// In ru, this message translates to:
  /// **'Соперник сдался. Вы победили!'**
  String get gameYouWonOpponentForfeit;

  /// No description provided for @lobbyLeaveTitle.
  ///
  /// In ru, this message translates to:
  /// **'Покинуть лобби?'**
  String get lobbyLeaveTitle;

  /// No description provided for @lobbyLeaveConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Лобби будет удалено после выхода. Приглашённые друзья получат отказ.'**
  String get lobbyLeaveConfirm;

  /// No description provided for @lobbyLeave.
  ///
  /// In ru, this message translates to:
  /// **'Покинуть'**
  String get lobbyLeave;

  /// No description provided for @statsDurationHours.
  ///
  /// In ru, this message translates to:
  /// **'{hours} ч'**
  String statsDurationHours(int hours);

  /// No description provided for @statsDurationHoursMinutes.
  ///
  /// In ru, this message translates to:
  /// **'{hours} ч {minutes} мин'**
  String statsDurationHoursMinutes(int hours, int minutes);

  /// No description provided for @statsDurationMinutes.
  ///
  /// In ru, this message translates to:
  /// **'{minutes} мин'**
  String statsDurationMinutes(int minutes);

  /// No description provided for @gameYouForfeitOpponentWon.
  ///
  /// In ru, this message translates to:
  /// **'Вы сдались. {name} победил'**
  String gameYouForfeitOpponentWon(String name);

  /// No description provided for @supportTitle.
  ///
  /// In ru, this message translates to:
  /// **'Поддержка'**
  String get supportTitle;

  /// No description provided for @supportUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Поддержка недоступна'**
  String get supportUnavailable;

  /// No description provided for @supportOpenFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть чат с поддержкой'**
  String get supportOpenFailed;

  /// No description provided for @coinsGrantedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вам начислено {amount} монет'**
  String coinsGrantedTitle(int amount);

  /// No description provided for @coinsDeductedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Списано {amount} монет'**
  String coinsDeductedTitle(int amount);

  /// No description provided for @coinsCreditCardTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вам начислены монеты'**
  String get coinsCreditCardTitle;

  /// No description provided for @coinsClaim.
  ///
  /// In ru, this message translates to:
  /// **'Забрать'**
  String get coinsClaim;
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
