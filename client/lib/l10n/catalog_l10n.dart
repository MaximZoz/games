import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/l10n/catalog_data.g.dart';

String _lang([AppLocalizations? l10n]) {
  if (l10n != null) return l10n.localeName.split('_').first.toLowerCase();
  return LocaleService.locale.languageCode.toLowerCase();
}

String _pick(Map<String, String>? byLang, String lang, String fallback) {
  if (byLang == null || byLang.isEmpty) return fallback;
  return byLang[lang] ?? byLang['en'] ?? byLang['ru'] ?? fallback;
}

/// Локализованное название предмета магазина / инвентаря по code.
String catalogTitle(
  String code, {
  String? fallback,
  AppLocalizations? l10n,
}) {
  final lang = _lang(l10n);
  final t = l10n ?? LocaleService.l10n;
  final stake = _stakeTitle(code, t);
  if (stake != null) return stake;
  return _pick(kShopTitles[code], lang, fallback?.trim().isNotEmpty == true
      ? fallback!
      : code);
}

/// Описание рамки / ставки; для остального — fallback или пусто.
String catalogDescription(
  String code, {
  String? fallback,
  AppLocalizations? l10n,
}) {
  final lang = _lang(l10n);
  final t = l10n ?? LocaleService.l10n;
  final stake = _stakeDescription(code, t);
  if (stake != null) return stake;
  final frame = kFrameDescriptions[code];
  if (frame != null) {
    return _pick(frame, lang, fallback ?? '');
  }
  // Описания эмодзи/коллекций собираются в UI из шаблонов l10n.
  final fb = fallback?.trim() ?? '';
  if (fb.isEmpty) return '';
  // Не показываем сырой русский текст при другом языке.
  if (lang != 'ru' && _looksRussian(fb)) return '';
  return fb;
}

String achievementTitle(
  String code, {
  String? fallback,
  AppLocalizations? l10n,
}) {
  final lang = _lang(l10n);
  return _pick(
    kAchievementTitles[code],
    lang,
    fallback?.trim().isNotEmpty == true ? fallback! : code,
  );
}

String achievementDescription(
  String code, {
  String? fallback,
  AppLocalizations? l10n,
}) {
  final lang = _lang(l10n);
  return _pick(
    kAchievementDescriptions[code],
    lang,
    fallback?.trim().isNotEmpty == true ? fallback! : '',
  );
}

final _stakeRe = RegExp(r'^stake_(silver|gold)_(\d+)$');

String? _stakeTitle(String code, AppLocalizations t) {
  final m = _stakeRe.firstMatch(code);
  if (m == null) return null;
  final n = int.parse(m.group(2)!);
  return m.group(1) == 'gold' ? t.shopStakeTitleGold(n) : t.shopStakeTitleSilver(n);
}

String? _stakeDescription(String code, AppLocalizations t) {
  final m = _stakeRe.firstMatch(code);
  if (m == null) return null;
  final n = int.parse(m.group(2)!);
  return m.group(1) == 'gold'
      ? t.shopStakeDescGold(n)
      : t.shopStakeDescSilver(n);
}

bool _looksRussian(String s) => RegExp(r'[А-Яа-яЁё]').hasMatch(s);
