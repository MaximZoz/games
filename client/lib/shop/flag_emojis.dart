/// Флаги стран для группы магазина «Флажки».
///
/// В Noto Animated Emoji нет анимаций флагов стран. В UI рисуем PNG с CDN
/// (надежнее unicode-флагов на Flutter Web), unicode — запасной fallback.

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

String countryFlagImageUrl(String iso, {int width = 80}) {
  final w = width.clamp(20, 160);
  return 'https://flagcdn.com/w$w/${iso.toLowerCase()}.png';
}
