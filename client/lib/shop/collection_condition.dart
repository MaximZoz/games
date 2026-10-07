import 'package:flutter/material.dart';
import 'package:multigames_client/l10n/app_localizations.dart';

/// Состояние коллекции по времени владения.
///
/// Первые 7 дней — новое (80%). До 2 месяцев — потрепанное (60%).
/// До 6 месяцев — уставшее (40%). До года — ветхое (100%).
/// Дальше — винтаж (300%). Месяц после покупки попадает в потрепанное.
enum CollectionCondition {
  fresh,
  worn,
  tired,
  shabby,
  vintage,
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

int collectionRefundBronze({
  required int priceBronze,
  required String? acquiredAt,
  DateTime? now,
}) {
  if (priceBronze <= 0) return 0;
  final condition = collectionConditionOf(acquiredAt, now);
  return priceBronze * collectionSellPercent(condition) ~/ 100;
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
