import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:multigames_client/l10n/app_localizations.dart';

/// Состояние коллекции по времени владения.
///
/// Первые 7 дней — новое. До 2 месяцев — потрепанное.
/// До 6 месяцев — уставшее. До года — ветхое. Дальше — винтаж.
/// Продать можно только новое (80%) или винтаж (300%).
enum CollectionCondition {
  fresh,
  worn,
  tired,
  shabby,
  vintage,
}

/// Продать можно только новое или винтаж. Пустая дата считается новым.
bool collectionCanSell({
  required String? acquiredAt,
  DateTime? now,
  int conditionShift = 0,
  String? vintageAt,
}) {
  final parsed = parseCollectionAcquiredAt(acquiredAt);
  final condition = parsed == null
      ? CollectionCondition.fresh
      : collectionConditionEffective(
          acquired: parsed,
          now: now ?? DateTime.now(),
          shift: conditionShift,
          vintageAt: parseCollectionAcquiredAt(vintageAt),
        );
  return condition == CollectionCondition.fresh ||
      condition == CollectionCondition.vintage;
}

int collectionSellPercent(CollectionCondition condition) {
  switch (condition) {
    case CollectionCondition.worn:
      return 60;
    case CollectionCondition.tired:
      return 40;
    case CollectionCondition.shabby:
      return 100;
    case CollectionCondition.vintage:
      return 300;
    case CollectionCondition.fresh:
      return 80;
  }
}

DateTime? parseCollectionAcquiredAt(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text)?.toUtc();
}

DateTime _addMonths(DateTime utc, int months) {
  return DateTime.utc(
    utc.year,
    utc.month + months,
    utc.day,
    utc.hour,
    utc.minute,
    utc.second,
    utc.millisecond,
    utc.microsecond,
  );
}

/// [now] и дата покупки сравниваются в UTC.
/// Пустая дата — новое, чтобы неизвестный возраст не продавался как винтаж.
CollectionCondition collectionConditionAt(DateTime acquired, DateTime now) {
  final from = acquired.toUtc();
  final at = now.toUtc();
  if (at.isBefore(from)) return CollectionCondition.fresh;
  if (at.isBefore(from.add(const Duration(days: 7)))) {
    return CollectionCondition.fresh;
  }
  if (at.isBefore(_addMonths(from, 2))) return CollectionCondition.worn;
  if (at.isBefore(_addMonths(from, 6))) return CollectionCondition.tired;
  if (at.isBefore(_addMonths(from, 12))) return CollectionCondition.shabby;
  return CollectionCondition.vintage;
}

CollectionCondition collectionConditionOf(String? acquiredAt, [DateTime? now]) {
  final parsed = parseCollectionAcquiredAt(acquiredAt);
  if (parsed == null) return CollectionCondition.fresh;
  return collectionConditionAt(parsed, now ?? DateTime.now());
}

/// Доля обычного дневного дохода: новое и ветхое 100%, потрепанное 60%,
/// уставшее 40%, винтажный предмет 200%.
int collectionIncomePercent(CollectionCondition condition) {
  switch (condition) {
    case CollectionCondition.worn:
      return 60;
    case CollectionCondition.tired:
      return 40;
    case CollectionCondition.vintage:
      return 200;
    case CollectionCondition.fresh:
    case CollectionCondition.shabby:
      return 100;
  }
}

/// Дневной доход предмета с учётом состояния. Пустая дата — как новое.
int collectionDailyIncomeBronze({
  required int baseBronze,
  required String? acquiredAt,
  DateTime? now,
  int conditionShift = 0,
  String? vintageAt,
}) {
  if (baseBronze <= 0) return 0;
  final parsed = parseCollectionAcquiredAt(acquiredAt);
  final condition = parsed == null
      ? CollectionCondition.fresh
      : collectionConditionEffective(
          acquired: parsed,
          now: now ?? DateTime.now(),
          shift: conditionShift,
          vintageAt: parseCollectionAcquiredAt(vintageAt),
        );
  return baseBronze * collectionIncomePercent(condition) ~/ 100;
}

int collectionRefundBronze({
  required int priceBronze,
  required String? acquiredAt,
  DateTime? now,
  int conditionShift = 0,
  String? vintageAt,
}) {
  if (priceBronze <= 0) return 0;
  final parsed = parseCollectionAcquiredAt(acquiredAt);
  final condition = parsed == null
      ? CollectionCondition.fresh
      : collectionConditionEffective(
          acquired: parsed,
          now: now ?? DateTime.now(),
          shift: conditionShift,
          vintageAt: parseCollectionAcquiredAt(vintageAt),
        );
  return priceBronze * collectionSellPercent(condition) ~/ 100;
}

int _conditionIndex(CollectionCondition condition) {
  switch (condition) {
    case CollectionCondition.worn:
      return 1;
    case CollectionCondition.tired:
      return 2;
    case CollectionCondition.shabby:
      return 3;
    case CollectionCondition.vintage:
      return 4;
    case CollectionCondition.fresh:
      return 0;
  }
}

CollectionCondition _conditionByIndex(int idx) {
  switch (idx) {
    case 1:
      return CollectionCondition.worn;
    case 2:
      return CollectionCondition.tired;
    case 3:
      return CollectionCondition.shabby;
    case 4:
      return CollectionCondition.vintage;
    default:
      return CollectionCondition.fresh;
  }
}

/// Состояние с учётом эликсиров. Положительный сдвиг не создаёт винтаж.
CollectionCondition collectionConditionEffective({
  required DateTime acquired,
  required DateTime now,
  int shift = 0,
  DateTime? vintageAt,
}) {
  final at = now.toUtc();
  final base = _conditionIndex(collectionConditionAt(acquired, at));
  var idx = base + shift;
  if (idx < 0) idx = 0;
  if (idx > 4) idx = 4;
  if (idx >= 4 && base < 4) idx = 3;
  final boost = vintageAt?.toUtc();
  if (boost != null && !at.isBefore(boost) && idx >= 3 && base < 4) {
    return CollectionCondition.vintage;
  }
  return _conditionByIndex(idx);
}

List<DateTime> collectionConditionBoundaries(DateTime acquired) {
  final from = acquired.toUtc();
  return [
    from.add(const Duration(days: 7)),
    _addMonths(from, 2),
    _addMonths(from, 6),
    _addMonths(from, 12),
  ];
}

/// Следующее состояние и момент смены. У винтажа таймера нет.
({CollectionCondition condition, DateTime at})? nextCollectionCondition({
  required DateTime acquired,
  required DateTime now,
  int shift = 0,
  DateTime? vintageAt,
}) {
  final atNow = now.toUtc();
  final current = collectionConditionEffective(
    acquired: acquired,
    now: atNow,
    shift: shift,
    vintageAt: vintageAt,
  );
  if (current == CollectionCondition.vintage) return null;
  final candidates = collectionConditionBoundaries(acquired);
  final boost = vintageAt?.toUtc();
  if (boost != null) candidates.add(boost);
  DateTime? best;
  CollectionCondition? bestCond;
  for (final t in candidates) {
    if (!t.isAfter(atNow)) continue;
    final next = collectionConditionEffective(
      acquired: acquired,
      now: t,
      shift: shift,
      vintageAt: vintageAt,
    );
    if (next == current) continue;
    if (best == null || t.isBefore(best)) {
      best = t;
      bestCond = next;
    }
  }
  if (best == null || bestCond == null) return null;
  return (condition: bestCond, at: best);
}

/// Можно ли применить эффект к текущему состоянию.
bool elixirCanApply({
  required String effect,
  required CollectionCondition condition,
  DateTime? vintageAt,
  required DateTime acquired,
  required DateTime now,
}) {
  switch (effect) {
    case 'rejuvenate':
      return condition != CollectionCondition.fresh;
    case 'age':
      return condition != CollectionCondition.shabby &&
          condition != CollectionCondition.vintage;
    case 'accelerate':
      if (condition != CollectionCondition.shabby || vintageAt != null) {
        return false;
      }
      final until = _addMonths(now.toUtc(), 3);
      final natural = _addMonths(acquired.toUtc(), 12);
      return until.isBefore(natural);
    default:
      return false;
  }
}

String collectionConditionGenitive(
  AppLocalizations l10n,
  CollectionCondition condition,
) {
  switch (condition) {
    case CollectionCondition.fresh:
      return l10n.collectionCondGenNew;
    case CollectionCondition.worn:
      return l10n.collectionCondGenWorn;
    case CollectionCondition.tired:
      return l10n.collectionCondGenTired;
    case CollectionCondition.shabby:
      return l10n.collectionCondGenShabby;
    case CollectionCondition.vintage:
      return l10n.collectionCondGenVintage;
  }
}

String collectionTimeLeft(AppLocalizations l10n, Duration left) {
  if (left.isNegative || left.inSeconds < 60) return l10n.collectionLeftSoon;
  if (left.inDays >= 1) return l10n.collectionLeftDays(left.inDays);
  if (left.inHours >= 1) return l10n.collectionLeftHours(left.inHours);
  return l10n.collectionLeftMinutes(math.max(1, left.inMinutes));
}

String collectionConditionName(
  AppLocalizations l10n,
  CollectionCondition condition,
) {
  switch (condition) {
    case CollectionCondition.fresh:
      return l10n.collectionConditionNew;
    case CollectionCondition.worn:
      return l10n.collectionConditionWorn;
    case CollectionCondition.tired:
      return l10n.collectionConditionTired;
    case CollectionCondition.shabby:
      return l10n.collectionConditionShabby;
    case CollectionCondition.vintage:
      return l10n.collectionConditionVintage;
  }
}

/// Тёмный фон полноэкранного просмотра: оттенок по смыслу состояния.
Color collectionConditionBackground(CollectionCondition condition) {
  switch (condition) {
    case CollectionCondition.fresh:
      return const Color(0xFF071910);
    case CollectionCondition.worn:
      return const Color(0xFF1A120C);
    case CollectionCondition.tired:
      return const Color(0xFF12141C);
    case CollectionCondition.shabby:
      return const Color(0xFF1A1210);
    case CollectionCondition.vintage:
      return const Color(0xFF140E1C);
  }
}

/// Более светлый центр того же оттенка, чтобы фон не был плоским.
Color collectionConditionGlow(CollectionCondition condition) {
  switch (condition) {
    case CollectionCondition.fresh:
      return const Color(0xFF163528);
    case CollectionCondition.worn:
      return const Color(0xFF3A2818);
    case CollectionCondition.tired:
      return const Color(0xFF242A38);
    case CollectionCondition.shabby:
      return const Color(0xFF3A2820);
    case CollectionCondition.vintage:
      return const Color(0xFF2C2040);
  }
}
