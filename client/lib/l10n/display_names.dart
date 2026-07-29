import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/app_localizations.dart';

/// Канонические значения пола в API/БД (исторически на русском).
const kGenderMaleApi = 'Мужской';
const kGenderFemaleApi = 'Женский';

/// Локализует служебные имена с сервера (бот / игрок по умолчанию).
String localizeDisplayName(String? name, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  final n = (name ?? '').trim();
  if (n.isEmpty) return t.commonPlayer;
  switch (n.toLowerCase()) {
    case 'бот':
    case 'bot':
      return t.gameBot;
    case 'игрок':
    case 'player':
      return t.commonPlayer;
    default:
      return n;
  }
}

/// Отображаемый пол: API хранит «Мужской»/«Женский», UI — через l10n.
String localizeGender(String? gender, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  final g = (gender ?? '').trim();
  if (g.isEmpty) return t.profileGenderUnset;
  final lower = g.toLowerCase();
  if (lower == 'женский' ||
      lower == 'жен' ||
      lower == 'female' ||
      lower == 'f') {
    return t.profileGenderFemale;
  }
  if (lower == 'мужской' ||
      lower == 'муж' ||
      lower == 'male' ||
      lower == 'm') {
    return t.profileGenderMale;
  }
  return g;
}

bool isFemaleGender(String? gender) {
  final g = (gender ?? '').trim().toLowerCase();
  return g == 'женский' || g == 'жен' || g == 'female' || g == 'f';
}
