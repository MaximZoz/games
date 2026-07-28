/// Unicode-флаги стран для группы магазина «Флажки».
///
/// В Noto Animated Emoji нет анимаций флагов стран — показываем системный
/// emoji-символ по [animated_name] вида `flagRu`.
const Map<String, String> countryFlagUnicodeByName = {
  'flagRu': '🇷🇺', // Россия
  'flagUs': '🇺🇸', // США
  'flagGb': '🇬🇧', // Великобритания
  'flagDe': '🇩🇪', // Германия
  'flagFr': '🇫🇷', // Франция
  'flagIt': '🇮🇹', // Италия
  'flagEs': '🇪🇸', // Испания
  'flagPt': '🇵🇹', // Португалия
  'flagNl': '🇳🇱', // Нидерланды
  'flagPl': '🇵🇱', // Польша
  'flagUa': '🇺🇦', // Украина
  'flagBy': '🇧🇾', // Беларусь
  'flagKz': '🇰🇿', // Казахстан
  'flagUz': '🇺🇿', // Узбекистан
  'flagTr': '🇹🇷', // Турция
  'flagCn': '🇨🇳', // Китай
  'flagJp': '🇯🇵', // Япония
  'flagKr': '🇰🇷', // Корея
  'flagIn': '🇮🇳', // Индия
  'flagBr': '🇧🇷', // Бразилия
  'flagAr': '🇦🇷', // Аргентина
  'flagMx': '🇲🇽', // Мексика
  'flagCa': '🇨🇦', // Канада
  'flagAu': '🇦🇺', // Австралия
  'flagNz': '🇳🇿', // Новая Зеландия
  'flagSe': '🇸🇪', // Швеция
  'flagNo': '🇳🇴', // Норвегия
  'flagFi': '🇫🇮', // Финляндия
  'flagDk': '🇩🇰', // Дания
  'flagCh': '🇨🇭', // Швейцария
  'flagAt': '🇦🇹', // Австрия
  'flagBe': '🇧🇪', // Бельгия
  'flagCz': '🇨🇿', // Чехия
  'flagGr': '🇬🇷', // Греция
  'flagIe': '🇮🇪', // Ирландия
  'flagIl': '🇮🇱', // Израиль
  'flagSa': '🇸🇦', // Саудовская Аравия
  'flagAe': '🇦🇪', // ОАЭ
  'flagEg': '🇪🇬', // Египет
  'flagZa': '🇿🇦', // ЮАР
  'flagNg': '🇳🇬', // Нигерия
  'flagTh': '🇹🇭', // Таиланд
  'flagVn': '🇻🇳', // Вьетнам
  'flagId': '🇮🇩', // Индонезия
  'flagSg': '🇸🇬', // Сингапур
};

bool isCountryFlagAnimatedName(String name) =>
    countryFlagUnicodeByName.containsKey(name);

String? countryFlagUnicodeFromName(String name) =>
    countryFlagUnicodeByName[name];
