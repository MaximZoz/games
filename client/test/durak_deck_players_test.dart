import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/durak/durak_rules.dart';

void main() {
  test('вдвоём — колоды 24 и 36', () {
    expect(durakDeckSizesForPlayers(2), [24, 36]);
    expect(durakClampDeckForPlayers(2, 24), 24);
    expect(durakClampDeckForPlayers(2, 36), 36);
    expect(durakClampDeckForPlayers(2, 52), 36);
  });

  test('втроём и вчетвером — колоды 36 и 52', () {
    expect(durakDeckSizesForPlayers(3), [36, 52]);
    expect(durakDeckSizesForPlayers(4), [36, 52]);
    expect(durakClampDeckForPlayers(3, 52), 52);
    expect(durakClampDeckForPlayers(4, 24), 36);
  });
}
