import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'ui/app_theme.dart';
import 'src/console_log_stub.dart'
    if (dart.library.html) 'src/console_log_web.dart' as console_log;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

class MultiGamesApp extends ConsumerWidget {
  const MultiGamesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'MultiGames',
      debugShowCheckedModeBanner: false,
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
          filled: true,
          fillColor: AppColors.surfaceCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: BorderSide(color: AppColors.accentSoft),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: const BorderSide(color: AppColors.accentStart, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          focusColor: AppColors.accentStart,
          hoverColor: AppColors.accentSoft,
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
      ),
      routerConfig: router,
    );
  }
}
