import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/app_localizations.dart';

import 'core/ios_viewport_sync.dart';
import 'core/android_notify_bridge.dart';
import 'core/local_notify.dart';
import 'core/haptics.dart';
import 'core/settings_provider.dart';
import 'core/sfx.dart';
import 'core/push_notification_nav_stub.dart'
    if (dart.library.html) 'core/push_notification_nav_web.dart'
    if (dart.library.io) 'core/push_notification_nav_io.dart'
    as push_nav;
import 'router.dart';
import 'ui/app_theme.dart';
import 'ui/widgets/zozu_boot_splash.dart';
import 'src/console_log_stub.dart'
    if (dart.library.html) 'src/console_log_web.dart' as console_log;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppOverlays.systemUi);
  // Иначе deep-link вида /games/tictactoe/lobby/:id открывает «Главную»,
  // а в адресной строке остаётся старый path (дефолт — HashUrlStrategy).
  if (kIsWeb) {
    usePathUrlStrategy();
    // Иначе клик/трекпад в Chrome/Safari даёт системное «Вставить».
    BrowserContextMenu.disableContextMenu();
    // iOS PWA: сброс visualViewport offset → hit-test совпадает с картинкой.
    installIosViewportSync();
  }
  console_log.logToBrowser('main() started');
  if (localNotificationsSupported()) {
    unawaited(initLocalNotifications());
  }

  runZonedGuarded(() {
    runApp(
      const ProviderScope(
        child: MultiGamesApp(),
      ),
    );
    console_log.logToBrowser('runApp() called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      console_log.logToBrowser('first frame built');
    });
  }, (error, stack) {
    console_log.logErrorToBrowser(error, stack);
    debugPrint('MultiGames error: $error\n$stack');
  });
}

TextTheme _textThemeNoUnderline(TextTheme base) {
  TextStyle noUnderline(TextStyle? s) =>
      (s ?? const TextStyle()).copyWith(decoration: TextDecoration.none);
  return TextTheme(
    displayLarge: noUnderline(base.displayLarge),
    displayMedium: noUnderline(base.displayMedium),
    displaySmall: noUnderline(base.displaySmall),
    headlineLarge: noUnderline(base.headlineLarge),
    headlineMedium: noUnderline(base.headlineMedium),
    headlineSmall: noUnderline(base.headlineSmall),
    titleLarge: noUnderline(base.titleLarge),
    titleMedium: noUnderline(base.titleMedium),
    titleSmall: noUnderline(base.titleSmall),
    bodyLarge: noUnderline(base.bodyLarge),
    bodyMedium: noUnderline(base.bodyMedium),
    bodySmall: noUnderline(base.bodySmall),
    labelLarge: noUnderline(base.labelLarge),
    labelMedium: noUnderline(base.labelMedium),
    labelSmall: noUnderline(base.labelSmall),
  ).apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );
}

/// Клик по push (PWA SW или Android FCM/локальный баннер) → go_router.
final _pushNotificationNavProvider = Provider<void>((ref) {
  final router = ref.watch(goRouterProvider);
  push_nav.installPushNotificationNavigation((path) {
    router.go(path);
  });
  ref.onDispose(push_nav.uninstallPushNotificationNavigation);
});

/// Без Material-ползунка поверх списков (чат, друзья, поиск и т.д.).
/// Мышь/трекпад — как touch: можно тащить горизонтальные полосы (коллекции).
class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class MultiGamesApp extends ConsumerWidget {
  const MultiGamesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final localeChoice = ref.watch(appLocaleProvider);
    final locale = effectiveAppLocale(localeChoice);
    // Клик по push: navigate внутри SPA, без reload и splash.
    ref.watch(_pushNotificationNavProvider);
    ref.watch(androidNotifyBridgeProvider);
    final soundOn = ref.watch(soundEnabledProvider);
    Sfx.setEnabled(soundOn);
    Sfx.instance.setCategories(
      games: ref.watch(soundGamesEnabledProvider),
      notifications: ref.watch(soundNotificationsEnabledProvider),
      turn: ref.watch(soundTurnEnabledProvider),
    );
    Haptics.setEnabled(ref.watch(hapticsEnabledProvider));
    Sfx.instance.warmup(unlock: false);
    return MaterialApp.router(
      title: 'Zozu Games',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      scrollBehavior: const _NoScrollbarBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentStart,
          brightness: Brightness.light,
          primary: AppColors.accentStart,
          surface: AppColors.surfaceUnified,
          surfaceTint: Colors.transparent,
        ),
        useMaterial3: true,
        canvasColor: AppColors.surfaceUnified,
        applyElevationOverlayColor: false,
        scaffoldBackgroundColor: AppColors.surfaceUnified,
        // ZoomPageTransitions (дефолт Android) на кадр рисует предыдущий route.
        // CupertinoPageTransitionsBuilder() не const на Flutter 3.44 / dart2js.
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
        // «Предметы», «Монеты за вход» и все AppBar-заголовки — по центру.
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: AppOverlays.systemUi,
        ),
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: AppColors.accentSoft.withValues(alpha: 0.5),
          cursorColor: AppColors.textPrimary,
          selectionHandleColor: AppColors.accentStart,
        ),
        textTheme: _textThemeNoUnderline(ThemeData.light().textTheme),
        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: const BorderSide(color: AppColors.accentSoft),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: const BorderSide(color: AppColors.accentStart, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.surfaceCard,
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.surfaceCard,
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            side: const BorderSide(color: AppColors.accentSoft),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      routerConfig: router,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppOverlays.systemUi,
          child: SelectionContainer.disabled(
            child: Listener(
              onPointerDown: (_) => Sfx.instance.warmup(),
              child: BootSplashHost(
                // Непрозрачный фон под прозрачными Scaffold: иначе на Android
                // при смене вкладки/экрана мигает предыдущий кадр.
                child: ColoredBox(
                  color: AppColors.surfaceUnified,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
