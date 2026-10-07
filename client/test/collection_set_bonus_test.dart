import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/shop/collection_widgets.dart';

void main() {
  test('бонус за собранную коллекцию в бронзе/день', () {
    expect(collectionSetBonusBronze('celebration'), 50);
    expect(collectionSetBonusBronze('nature'), 50);
    expect(collectionSetBonusBronze('cosmic'), 100);
    expect(collectionSetBonusBronze('adventure'), 200);
    expect(collectionSetBonusBronze('legends'), 500);
    expect(collectionSetBonusBronze('jewels'), 5000);
    expect(collectionSetBonusBronze('other'), 0);
  });

  test('группы коллекций сортируются по бонусу за сбор', () {
    final sets = [...collectionSetOrder]..sort(
        (a, b) => compareCollectionSetsByDaily(a, b, collectionSetBonusBronze),
      );
    expect(sets, [
      'celebration',
      'nature',
      'cosmic',
      'adventure',
      'legends',
      'jewels',
    ]);
  });
}
