import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyAppLocale = 'app_locale';

/// Поддерживаемые языки приложения.
const supportedAppLocales = <Locale>[
  Locale('ru'),
  Locale('en'),
];

/// null = следовать системе (первый запуск / «Как в системе»).
final appLocaleProvider =
    StateNotifierProvider<AppLocaleNotifier, Locale?>((ref) {
  return AppLocaleNotifier();
});

class AppLocaleNotifier extends StateNotifier<Locale?> {
  AppLocaleNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyAppLocale);
    if (raw == null || raw.isEmpty || raw == 'system') {
      final detected = detectSystemLocale();
      LocaleService.setLocale(detected);
      state = null; // UI: «Как в системе», фактически detected
      return;
    }
    final locale = Locale(raw);
    LocaleService.setLocale(resolveLocale(locale));
    state = locale;
  }

  /// Явный выбор в настройках. [locale] == null → снова система.
  Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.setString(_keyAppLocale, 'system');
      final detected = detectSystemLocale();
      LocaleService.setLocale(detected);
      state = null;
      return;
    }
    final resolved = resolveLocale(locale);
    await prefs.setString(_keyAppLocale, resolved.languageCode);
    LocaleService.setLocale(resolved);
    state = resolved;
  }
}

Locale detectSystemLocale() {
  final sys = PlatformDispatcher.instance.locale;
  return resolveLocale(sys);
}

Locale resolveLocale(Locale locale) {
  if (locale.languageCode.toLowerCase() == 'ru') {
    return const Locale('ru');
  }
  return const Locale('en');
}

/// Эффективная локаль для MaterialApp (никогда null).
/// При «Как в системе» берём [LocaleService] (уже выставлен из PlatformDispatcher /
/// SharedPreferences / тестов).
Locale effectiveAppLocale(Locale? userChoice) {
  if (userChoice != null) return resolveLocale(userChoice);
  return LocaleService.locale;
}

/// Доступ к l10n без BuildContext (репозитории, утилиты).
class LocaleService {
  static Locale _locale = detectSystemLocale();

  static Locale get locale => _locale;

  static void setLocale(Locale locale) {
    _locale = resolveLocale(locale);
  }

  static AppLocalizations get l10n => lookupAppLocalizations(_locale);

  static String get acceptLanguageHeader {
    final code = _locale.languageCode;
    if (code == 'ru') return 'ru-RU,ru;q=0.9,en;q=0.5';
    return 'en-US,en;q=0.9';
  }
}
