import 'package:flutter/material.dart';

/// Язык приложения, привязанный к флагам из магазина смайликов.
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.flagIso,
  });

  /// BCP-47 language code (Locale.languageCode).
  final String code;

  /// Название на этом языке (для списка в настройках).
  final String nativeName;

  final String englishName;

  /// ISO 3166-1 alpha-2 флага из `assets/flags/`.
  final String flagIso;

  Locale get locale => Locale(code);
}

/// Уникальные языки стран, чьи флаги есть в смайликах.
/// Один язык покрывает несколько стран (en → US/GB/AU/…).
const appLanguages = <AppLanguage>[
  AppLanguage(code: 'ar', nativeName: 'العربية', englishName: 'Arabic', flagIso: 'sa'),
  AppLanguage(code: 'be', nativeName: 'Беларуская', englishName: 'Belarusian', flagIso: 'by'),
  AppLanguage(code: 'cs', nativeName: 'Čeština', englishName: 'Czech', flagIso: 'cz'),
  AppLanguage(code: 'da', nativeName: 'Dansk', englishName: 'Danish', flagIso: 'dk'),
  AppLanguage(code: 'de', nativeName: 'Deutsch', englishName: 'German', flagIso: 'de'),
  AppLanguage(code: 'el', nativeName: 'Ελληνικά', englishName: 'Greek', flagIso: 'gr'),
  AppLanguage(code: 'en', nativeName: 'English', englishName: 'English', flagIso: 'gb'),
  AppLanguage(code: 'es', nativeName: 'Español', englishName: 'Spanish', flagIso: 'es'),
  AppLanguage(code: 'fi', nativeName: 'Suomi', englishName: 'Finnish', flagIso: 'fi'),
  AppLanguage(code: 'fr', nativeName: 'Français', englishName: 'French', flagIso: 'fr'),
  AppLanguage(code: 'he', nativeName: 'עברית', englishName: 'Hebrew', flagIso: 'il'),
  AppLanguage(code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi', flagIso: 'in'),
  AppLanguage(code: 'id', nativeName: 'Bahasa Indonesia', englishName: 'Indonesian', flagIso: 'id'),
  AppLanguage(code: 'it', nativeName: 'Italiano', englishName: 'Italian', flagIso: 'it'),
  AppLanguage(code: 'ja', nativeName: '日本語', englishName: 'Japanese', flagIso: 'jp'),
  AppLanguage(code: 'kk', nativeName: 'Қазақша', englishName: 'Kazakh', flagIso: 'kz'),
  AppLanguage(code: 'ko', nativeName: '한국어', englishName: 'Korean', flagIso: 'kr'),
  AppLanguage(code: 'nb', nativeName: 'Norsk', englishName: 'Norwegian', flagIso: 'no'),
  AppLanguage(code: 'nl', nativeName: 'Nederlands', englishName: 'Dutch', flagIso: 'nl'),
  AppLanguage(code: 'pl', nativeName: 'Polski', englishName: 'Polish', flagIso: 'pl'),
  AppLanguage(code: 'pt', nativeName: 'Português', englishName: 'Portuguese', flagIso: 'pt'),
  AppLanguage(code: 'ru', nativeName: 'Русский', englishName: 'Russian', flagIso: 'ru'),
  AppLanguage(code: 'sv', nativeName: 'Svenska', englishName: 'Swedish', flagIso: 'se'),
  AppLanguage(code: 'th', nativeName: 'ไทย', englishName: 'Thai', flagIso: 'th'),
  AppLanguage(code: 'tr', nativeName: 'Türkçe', englishName: 'Turkish', flagIso: 'tr'),
  AppLanguage(code: 'uk', nativeName: 'Українська', englishName: 'Ukrainian', flagIso: 'ua'),
  AppLanguage(code: 'uz', nativeName: 'Oʻzbekcha', englishName: 'Uzbek', flagIso: 'uz'),
  AppLanguage(code: 'vi', nativeName: 'Tiếng Việt', englishName: 'Vietnamese', flagIso: 'vn'),
  AppLanguage(code: 'zh', nativeName: '中文', englishName: 'Chinese', flagIso: 'cn'),
];

const supportedAppLocales = <Locale>[
  Locale('ar'),
  Locale('be'),
  Locale('cs'),
  Locale('da'),
  Locale('de'),
  Locale('el'),
  Locale('en'),
  Locale('es'),
  Locale('fi'),
  Locale('fr'),
  Locale('he'),
  Locale('hi'),
  Locale('id'),
  Locale('it'),
  Locale('ja'),
  Locale('kk'),
  Locale('ko'),
  Locale('nb'),
  Locale('nl'),
  Locale('pl'),
  Locale('pt'),
  Locale('ru'),
  Locale('sv'),
  Locale('th'),
  Locale('tr'),
  Locale('uk'),
  Locale('uz'),
  Locale('vi'),
  Locale('zh'),
];

final _supportedCodes = {
  for (final l in supportedAppLocales) l.languageCode,
};

AppLanguage? appLanguageByCode(String code) {
  final c = code.toLowerCase();
  for (final lang in appLanguages) {
    if (lang.code == c) return lang;
  }
  return null;
}

/// Нормализация системной/браузерной локали → один из поддерживаемых языков.
Locale resolveLocale(Locale locale) {
  var code = locale.languageCode.toLowerCase();
  // Норвегия: no / nn → nb
  if (code == 'no' || code == 'nn') code = 'nb';
  // Китайские варианты
  if (code == 'zh') return const Locale('zh');
  if (_supportedCodes.contains(code)) return Locale(code);
  // Регион без языка: по стране (редко в web, но полезно)
  final country = (locale.countryCode ?? '').toUpperCase();
  const byCountry = <String, String>{
    'RU': 'ru',
    'BY': 'be',
    'UA': 'uk',
    'KZ': 'kk',
    'UZ': 'uz',
    'DE': 'de',
    'AT': 'de',
    'CH': 'de',
    'FR': 'fr',
    'BE': 'fr',
    'IT': 'it',
    'ES': 'es',
    'AR': 'es',
    'MX': 'es',
    'PT': 'pt',
    'BR': 'pt',
    'NL': 'nl',
    'PL': 'pl',
    'TR': 'tr',
    'CN': 'zh',
    'JP': 'ja',
    'KR': 'ko',
    'IN': 'hi',
    'SE': 'sv',
    'NO': 'nb',
    'FI': 'fi',
    'DK': 'da',
    'CZ': 'cs',
    'GR': 'el',
    'IL': 'he',
    'SA': 'ar',
    'AE': 'ar',
    'EG': 'ar',
    'TH': 'th',
    'VN': 'vi',
    'ID': 'id',
    'US': 'en',
    'GB': 'en',
    'AU': 'en',
    'NZ': 'en',
    'CA': 'en',
    'IE': 'en',
    'SG': 'en',
    'ZA': 'en',
    'NG': 'en',
  };
  final fromCountry = byCountry[country];
  if (fromCountry != null) return Locale(fromCountry);
  return const Locale('en');
}
