import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'router.dart';
import 'ui/app_theme.dart';
import 'ui/widgets/shimmer_animation_scope.dart';
import 'src/console_log_stub.dart'
    if (dart.library.html) 'src/console_log_web.dart' as console_log;
import 'src/telegram_web_app_stub.dart'
    if (dart.library.html) 'src/telegram_web_app_web.dart' as telegram_web_app;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Иначе deep-link вида /games/tictactoe/lobby/:id открывает «Главную»,
  // а в адресной строке остаётся старый path (дефолт — HashUrlStrategy).
  if (kIsWeb) {
    usePathUrlStrategy();
    // Ранний вызов: expand + disableVerticalSwipes (см. client/web/index.html).
    telegram_web_app.configureTelegramWebApp();
  }
  console_log.logToBrowser('main() started');

  runZonedGuarded(() {
    runApp(
      const ProviderScope(
        child: MultiGamesApp(),
      ),
    );
    console_log.logToBrowser('runApp() called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      console_log.logToBrowser('first frame built');
      // Повтор после первого кадра — на части Telegram-клиентов SDK
      // готов чуть позже старта Flutter.
      if (kIsWeb) {
        telegram_web_app.configureTelegramWebApp();
      }
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

/// Без Material-ползунка поверх списков (чат, друзья, поиск и т.д.).
class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();

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
    return ShimmerAnimationScope(
      duration: const Duration(seconds: 28),
      child: MaterialApp.router(
      title: 'MultiGames',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _NoScrollbarBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentStart,
          brightness: Brightness.light,
          primary: AppColors.accentStart,
          surface: Colors.transparent,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
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
      ),
    );
  }
}
