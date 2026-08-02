import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_repository.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  group('buildTictactoeRulesText', () {
    test('base text includes grid, win length, stake', () {
      final text = buildTictactoeRulesText(
        gridSize: 3,
        turnTimeSec: 0,
        swapRule: false,
        firstMoveRestriction: false,
        stakeBronze: 10,
      );
      expect(text, contains('3x3'));
      expect(text, contains('3 в ряд'));
      expect(text, contains('Без ограничения'));
      expect(text, contains('10$kTictactoeRulesStakeIconMarker'));
      expect(text, isNot(contains('бр')));
      expect(text, isNot(contains('Смена сторон')));
      expect(text, isNot(contains('Запрет центра')));
    });

    test('gomoku uses 15x15 and 5 in a row', () {
      final text = buildTictactoeRulesText(
        variant: 'gomoku',
        gridSize: 15,
        turnTimeSec: 60,
        swapRule: true,
        firstMoveRestriction: true,
        stakeBronze: 100,
      );
      expect(text, contains('Гомоку'));
      expect(text, contains('15x15'));
      expect(text, contains('5 в ряд'));
      expect(text, contains('1 мин'));
      expect(text, contains('Смена сторон'));
      expect(text, contains('Запрет центра'));
      // 100 бронзы = 1 серебро → «1» + маркер иконки (не «1 с»).
      expect(text, contains('1$kTictactoeRulesStakeIconMarker'));
      expect(text, isNot(contains('1 с')));
    });

    test('ultimate explains sub-boards and forced next board', () {
      final text = buildTictactoeRulesText(
        variant: 'ultimate',
        gridSize: 9,
        turnTimeSec: 0,
        swapRule: false,
        firstMoveRestriction: false,
        stakeBronze: 1,
      );
      expect(text, contains('Ультимейт'));
      expect(text, contains('Девять малых полей'));
      expect(text, contains('обязан ходить соперник'));
      expect(text, contains('три малых поля в ряд'));
      expect(text, isNot(contains('на поле 9x9')));
    });

    test('stake 0 omits stake line (offline)', () {
      final text = buildTictactoeRulesText(
        gridSize: 3,
        turnTimeSec: 10,
        swapRule: false,
        firstMoveRestriction: false,
        stakeBronze: 0,
      );
      expect(text, isNot(contains('Ставка')));
      expect(text, contains('10 с'));
    });

    test('offline bot omits turn time and uses alternate starts', () {
      final text = buildTictactoeRulesText(
        gridSize: 3,
        turnTimeSec: 30,
        swapRule: true,
        firstMoveRestriction: false,
        stakeBronze: 0,
        includeTurnTime: false,
        offlineBot: true,
      );
      expect(text, isNot(contains('Ставка')));
      expect(text, isNot(contains('30 с')));
      expect(text, isNot(contains('Без ограничения')));
      expect(text, contains('чередуется'));
      expect(text, isNot(contains('O может поменяться')));
    });
  });
}
