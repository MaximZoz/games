import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/shop/collection_condition.dart';

void main() {
  final acquired = DateTime.utc(2024, 1, 15, 12);

  test('состояние коллекции по возрасту владения', () {
    expect(
      collectionConditionAt(acquired, acquired),
      CollectionCondition.fresh,
    );
    expect(
      collectionConditionAt(acquired, acquired.add(const Duration(days: 6))),
      CollectionCondition.fresh,
    );
    expect(
      collectionConditionAt(acquired, acquired.add(const Duration(days: 7))),
      CollectionCondition.worn,
    );
    expect(
      collectionConditionAt(acquired, DateTime.utc(2024, 2, 15, 12)),
      CollectionCondition.worn,
    );
    expect(
      collectionConditionAt(acquired, DateTime.utc(2024, 3, 15, 12)),
      CollectionCondition.tired,
    );
    expect(
      collectionConditionAt(acquired, DateTime.utc(2024, 7, 15, 12)),
      CollectionCondition.shabby,
    );
    expect(
      collectionConditionAt(acquired, DateTime.utc(2025, 1, 15, 12)),
      CollectionCondition.vintage,
    );
  });

  test('эликсир двигает состояние и не выдаёт винтаж', () {
    final acquired = DateTime.utc(2024, 1, 15, 12);
    final fresh = acquired.add(const Duration(days: 1));
    expect(
      collectionConditionEffective(acquired: acquired, now: fresh, shift: 1),
      CollectionCondition.worn,
    );
    final shabby = DateTime.utc(2024, 9, 15, 12);
    expect(
      collectionConditionEffective(acquired: acquired, now: shabby, shift: 1),
      CollectionCondition.shabby,
    );
    final boost = DateTime.utc(2024, 12, 15, 12);
    expect(
      collectionConditionEffective(
        acquired: acquired,
        now: shabby,
        vintageAt: boost,
      ),
      CollectionCondition.shabby,
    );
    expect(
      collectionConditionEffective(
        acquired: acquired,
        now: boost,
        vintageAt: boost,
      ),
      CollectionCondition.vintage,
    );
    final next = nextCollectionCondition(
      acquired: acquired,
      now: fresh,
      shift: 0,
    );
    expect(next?.condition, CollectionCondition.worn);
    expect(next?.at, acquired.add(const Duration(days: 7)));
    expect(
      nextCollectionCondition(
        acquired: acquired,
        now: DateTime.utc(2026, 1, 15, 12),
      ),
      isNull,
    );
    expect(
      collectionRefundBronze(
        priceBronze: 1000,
        acquiredAt: acquired.toIso8601String(),
        now: DateTime.utc(2024, 4, 15, 12),
        conditionShift: 1,
      ),
      1000,
    );
  });

  test('пустая дата не становится винтажем', () {
    expect(collectionConditionOf(null), CollectionCondition.fresh);
    expect(collectionConditionOf(''), CollectionCondition.fresh);
  });

  test('выкуп: 80, 60, 40, 100 и 300 процентов', () {
    int refund(DateTime at) => collectionRefundBronze(
          priceBronze: 1000,
          acquiredAt: acquired.toIso8601String(),
          now: at,
        );
    expect(refund(acquired.add(const Duration(days: 1))), 800);
    expect(refund(acquired.add(const Duration(days: 20))), 600);
    expect(refund(DateTime.utc(2024, 4, 15)), 400);
    expect(refund(DateTime.utc(2024, 9, 15)), 1000);
    expect(refund(DateTime.utc(2025, 2, 15)), 3000);
    expect(
      collectionRefundBronze(priceBronze: 0, acquiredAt: null),
      0,
    );
  });

  test('подписи состояний на русском', () {
    final l10n = lookupAppLocalizations(const Locale('ru'));
    expect(
      collectionConditionName(l10n, CollectionCondition.fresh),
      'Новое',
    );
    expect(
      collectionConditionName(l10n, CollectionCondition.worn),
      'Потрепанное',
    );
    expect(
      collectionConditionName(l10n, CollectionCondition.tired),
      'Уставшее',
    );
    expect(
      collectionConditionName(l10n, CollectionCondition.shabby),
      'Ветхое',
    );
    expect(
      collectionConditionName(l10n, CollectionCondition.vintage),
      'Винтаж',
    );
    expect(l10n.shopCollectionsHelp, contains('продажа 80% от стоимости'));
    expect(l10n.shopCollectionsHelp, contains('продажа 300% от стоимости'));
    expect(l10n.shopCollectionsHelp, contains('Винтаж'));
  });
}
