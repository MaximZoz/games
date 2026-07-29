import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/app_localizations.dart';

List<String> _weekdayShort(AppLocalizations l10n) => [
      l10n.weekdaySun,
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
    ];

List<String> _monthShort(AppLocalizations l10n) => [
      l10n.monthJan,
      l10n.monthFeb,
      l10n.monthMar,
      l10n.monthApr,
      l10n.monthMay,
      l10n.monthJun,
      l10n.monthJul,
      l10n.monthAug,
      l10n.monthSep,
      l10n.monthOct,
      l10n.monthNov,
      l10n.monthDec,
    ];

/// Компактный формат даты/времени для списка чатов: сегодня — только время,
/// вчера — «вчера», на неделе — день, иначе краткая дата.
String formatChatListDateTime(String? raw) {
  final l10n = LocaleService.l10n;
  final dt = DateTime.tryParse(raw ?? '');
  if (dt == null) return '';
  final local = dt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final msgDay = DateTime(local.year, local.month, local.day);

  if (msgDay == today) {
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
  final yesterday = today.subtract(const Duration(days: 1));
  if (msgDay == yesterday) {
    return l10n.timeYesterday;
  }
  final diffDays = today.difference(msgDay).inDays;
  if (diffDays < 7) {
    return _weekdayShort(l10n)[local.weekday % 7];
  }
  if (local.year == now.year) {
    return '${local.day} ${_monthShort(l10n)[local.month - 1]}';
  }
  return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year % 100}';
}

/// Форматирует "последний раз в сети" для отображения пользователю.
String formatLastSeen(String? lastSeenAt) {
  if (lastSeenAt == null || lastSeenAt.isEmpty) return '';
  final dt = DateTime.tryParse(lastSeenAt);
  if (dt == null) return '';
  return formatLastSeenFromDateTime(dt);
}

/// Форматирует дату относительно текущего времени.
String formatLastSeenFromDateTime(DateTime dt) {
  final l10n = LocaleService.l10n;
  final now = DateTime.now();
  final diff = now.difference(dt.toLocal());

  if (diff.inSeconds < 60) {
    return l10n.timeJustNow;
  }
  if (diff.inMinutes < 60) {
    return l10n.timeMinutesAgo(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return l10n.timeHoursAgo(diff.inHours);
  }
  if (diff.inDays == 1) {
    return l10n.timeYesterday;
  }
  if (diff.inDays < 7) {
    return l10n.timeDaysAgo(diff.inDays);
  }
  if (diff.inDays < 30) {
    final w = (diff.inDays / 7).floor();
    if (w == 1) return l10n.timeWeekAgo;
    if (w < 5) return l10n.timeWeeksAgo(w);
    return l10n.timeMonthAgo;
  }
  if (diff.inDays < 365) {
    final m = (diff.inDays / 30).floor();
    if (m == 1) return l10n.timeMonthAgo;
    if (m < 12) return l10n.timeMonthsAgo(m);
    return l10n.timeYearAgo;
  }
  final y = (diff.inDays / 365).floor();
  if (y == 1) return l10n.timeYearAgo;
  return l10n.timeYearsAgo(y);
}
