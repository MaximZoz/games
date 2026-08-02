// Флаги стран для группы магазина «Флажки».
//
// PNG лежат в client/assets/flags/ (бандл приложения). Unicode — запасной
// fallback, если ассет не найден.

import 'package:flutter/material.dart';
import 'package:multigames_client/core/app_languages.dart';

class CountryFlagInfo {
  const CountryFlagInfo({
    required this.iso,
    required this.unicode,
  });

  final String iso;
  final String unicode;
}

const Map<String, CountryFlagInfo> countryFlagsByName = {
  'flagRu': CountryFlagInfo(iso: 'ru', unicode: '🇷🇺'),
  'flagUs': CountryFlagInfo(iso: 'us', unicode: '🇺🇸'),
  'flagGb': CountryFlagInfo(iso: 'gb', unicode: '🇬🇧'),
  'flagDe': CountryFlagInfo(iso: 'de', unicode: '🇩🇪'),
  'flagFr': CountryFlagInfo(iso: 'fr', unicode: '🇫🇷'),
  'flagIt': CountryFlagInfo(iso: 'it', unicode: '🇮🇹'),
  'flagEs': CountryFlagInfo(iso: 'es', unicode: '🇪🇸'),
  'flagPt': CountryFlagInfo(iso: 'pt', unicode: '🇵🇹'),
  'flagNl': CountryFlagInfo(iso: 'nl', unicode: '🇳🇱'),
  'flagPl': CountryFlagInfo(iso: 'pl', unicode: '🇵🇱'),
  'flagUa': CountryFlagInfo(iso: 'ua', unicode: '🇺🇦'),
  'flagBy': CountryFlagInfo(iso: 'by', unicode: '🇧🇾'),
  'flagKz': CountryFlagInfo(iso: 'kz', unicode: '🇰🇿'),
  'flagUz': CountryFlagInfo(iso: 'uz', unicode: '🇺🇿'),
  'flagTr': CountryFlagInfo(iso: 'tr', unicode: '🇹🇷'),
  'flagCn': CountryFlagInfo(iso: 'cn', unicode: '🇨🇳'),
  'flagJp': CountryFlagInfo(iso: 'jp', unicode: '🇯🇵'),
  'flagKr': CountryFlagInfo(iso: 'kr', unicode: '🇰🇷'),
  'flagIn': CountryFlagInfo(iso: 'in', unicode: '🇮🇳'),
  'flagBr': CountryFlagInfo(iso: 'br', unicode: '🇧🇷'),
  'flagAr': CountryFlagInfo(iso: 'ar', unicode: '🇦🇷'),
  'flagMx': CountryFlagInfo(iso: 'mx', unicode: '🇲🇽'),
  'flagCa': CountryFlagInfo(iso: 'ca', unicode: '🇨🇦'),
  'flagAu': CountryFlagInfo(iso: 'au', unicode: '🇦🇺'),
  'flagNz': CountryFlagInfo(iso: 'nz', unicode: '🇳🇿'),
  'flagSe': CountryFlagInfo(iso: 'se', unicode: '🇸🇪'),
  'flagNo': CountryFlagInfo(iso: 'no', unicode: '🇳🇴'),
  'flagFi': CountryFlagInfo(iso: 'fi', unicode: '🇫🇮'),
  'flagDk': CountryFlagInfo(iso: 'dk', unicode: '🇩🇰'),
  'flagCh': CountryFlagInfo(iso: 'ch', unicode: '🇨🇭'),
  'flagAt': CountryFlagInfo(iso: 'at', unicode: '🇦🇹'),
  'flagBe': CountryFlagInfo(iso: 'be', unicode: '🇧🇪'),
  'flagCz': CountryFlagInfo(iso: 'cz', unicode: '🇨🇿'),
  'flagGr': CountryFlagInfo(iso: 'gr', unicode: '🇬🇷'),
  'flagIe': CountryFlagInfo(iso: 'ie', unicode: '🇮🇪'),
  'flagIl': CountryFlagInfo(iso: 'il', unicode: '🇮🇱'),
  'flagSa': CountryFlagInfo(iso: 'sa', unicode: '🇸🇦'),
  'flagAe': CountryFlagInfo(iso: 'ae', unicode: '🇦🇪'),
  'flagEg': CountryFlagInfo(iso: 'eg', unicode: '🇪🇬'),
  'flagZa': CountryFlagInfo(iso: 'za', unicode: '🇿🇦'),
  'flagNg': CountryFlagInfo(iso: 'ng', unicode: '🇳🇬'),
  'flagTh': CountryFlagInfo(iso: 'th', unicode: '🇹🇭'),
  'flagVn': CountryFlagInfo(iso: 'vn', unicode: '🇻🇳'),
  'flagId': CountryFlagInfo(iso: 'id', unicode: '🇮🇩'),
  'flagSg': CountryFlagInfo(iso: 'sg', unicode: '🇸🇬'),
};

/// Совместимость со старым API.
Map<String, String> get countryFlagUnicodeByName => {
      for (final e in countryFlagsByName.entries) e.key: e.value.unicode,
    };

bool isCountryFlagAnimatedName(String name) =>
    countryFlagsByName.containsKey(name);

String? countryFlagUnicodeFromName(String name) =>
    countryFlagsByName[name]?.unicode;

String? countryFlagIsoFromName(String name) => countryFlagsByName[name]?.iso;

String countryFlagAssetPath(String iso) =>
    'assets/flags/${iso.toLowerCase()}.png';

/// ISO флага, соответствующий языку приложения (настройки / локаль).
String? preferredFlagIsoForLocale(Locale locale) {
  final lang = appLanguageByCode(resolveLocale(locale).languageCode);
  return lang?.flagIso.toLowerCase();
}

/// ISO из `emoji_flag_xx` / `flagXx` / сырого `xx`.
String? flagIsoFromShopCodeOrName(String? code, String? animatedName) {
  final fromName = animatedName == null || animatedName.isEmpty
      ? null
      : countryFlagIsoFromName(animatedName);
  if (fromName != null && fromName.isNotEmpty) {
    return fromName.toLowerCase();
  }
  final c = (code ?? '').trim().toLowerCase();
  if (c.startsWith('emoji_flag_') && c.length > 'emoji_flag_'.length) {
    return c.substring('emoji_flag_'.length);
  }
  if (c.length == 2) return c;
  return null;
}

/// Ставит флаг [preferredIso] первым, остальной порядок сохраняет.
void preferFlagIsoFirst<T>(
  List<T> items, {
  required String? preferredIso,
  required String? Function(T item) codeOf,
  required String? Function(T item) animatedNameOf,
}) {
  preferFlagIsoFirstInMixedList<T>(
    items,
    preferredIso: preferredIso,
    isFlag: (_) => true,
    codeOf: codeOf,
    animatedNameOf: animatedNameOf,
  );
}

/// В смешанном списке (эмоции + флаги) ставит нужный флаг на место первого флага.
void preferFlagIsoFirstInMixedList<T>(
  List<T> items, {
  required String? preferredIso,
  required bool Function(T item) isFlag,
  required String? Function(T item) codeOf,
  required String? Function(T item) animatedNameOf,
}) {
  final pref = preferredIso?.trim().toLowerCase();
  if (pref == null || pref.isEmpty || items.length < 2) return;
  int? firstFlagIdx;
  int? preferredIdx;
  for (var i = 0; i < items.length; i++) {
    if (!isFlag(items[i])) continue;
    firstFlagIdx ??= i;
    final iso = flagIsoFromShopCodeOrName(codeOf(items[i]), animatedNameOf(items[i]));
    if (iso == pref) {
      preferredIdx = i;
      break;
    }
  }
  if (firstFlagIdx == null ||
      preferredIdx == null ||
      preferredIdx == firstFlagIdx) {
    return;
  }
  final item = items.removeAt(preferredIdx);
  items.insert(firstFlagIdx, item);
}

