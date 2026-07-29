import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/app_languages.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:multigames_client/core/app_languages.dart'
    show
        AppLanguage,
        appLanguages,
        appLanguageByCode,
        resolveLocale,
        supportedAppLocales;

const _keyAppLocale = 'app_locale';

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
      state = null;
      return;
    }
    final locale = resolveLocale(Locale(raw));
    LocaleService.setLocale(locale);
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
  final locales = PlatformDispatcher.instance.locales;
  for (final loc in locales) {
    final resolved = resolveLocale(loc);
    // resolveLocale всегда что-то вернёт; предпочитаем точное совпадение языка.
    final code = loc.languageCode.toLowerCase();
    final normalized = code == 'no' || code == 'nn' ? 'nb' : code;
    if (normalized == resolved.languageCode) {
      return resolved;
    }
  }
  if (locales.isNotEmpty) {
    return resolveLocale(locales.first);
  }
  return resolveLocale(PlatformDispatcher.instance.locale);
}

/// Эффективная локаль для MaterialApp (никогда null).
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
    final lang = appLanguageByCode(code);
    final region = (lang?.flagIso ?? code).toUpperCase();
    return '$code-$region,$code;q=0.9,en;q=0.5';
  }
}
