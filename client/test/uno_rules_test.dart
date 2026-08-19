import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/uno/uno_rules.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  test('unoRuleLines includes players, turn time and win line', () {
    final lines = unoRuleLines(players: 3, turnTimeSec: 60);
    expect(lines.first, 'Игроки: 3.');
    expect(lines.any((l) => l.contains('1 мин')), isTrue);
    expect(lines.any((l) => l.contains('Уно')), isTrue);
    expect(lines.last, contains('Побеждает'));
  });

  test('unoRuleLines offline bot hides turn time', () {
    final lines = unoRuleLines(
      players: 2,
      turnTimeSec: 60,
      offlineBot: true,
    );
    expect(lines.first, 'Игроки: 2.');
    expect(lines, contains('Игра против бота, без лимита времени на ход.'));
    expect(lines, isNot(contains('1 мин')));
  });
}
