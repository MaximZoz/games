import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_repository.dart';

void main() {
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
      expect(text, contains('10 бр'));
      expect(text, isNot(contains('Смена сторон')));
      expect(text, isNot(contains('Запрет центра')));
    });

    test('large grid uses 5 in a row', () {
      final text = buildTictactoeRulesText(
        gridSize: 7,
        turnTimeSec: 60,
        swapRule: true,
        firstMoveRestriction: true,
        stakeBronze: 100,
      );
      expect(text, contains('7x7'));
      expect(text, contains('5 в ряд'));
      expect(text, contains('1 мин'));
      expect(text, contains('Смена сторон'));
      expect(text, contains('Запрет центра'));
      expect(text, contains('1 с'));
    });

    test('stake below 1 becomes 1', () {
      final text = buildTictactoeRulesText(
        gridSize: 3,
        turnTimeSec: 10,
        swapRule: false,
        firstMoveRestriction: false,
        stakeBronze: 0,
      );
      expect(text, contains('1 бр'));
      expect(text, contains('10 с'));
    });
  });
}
