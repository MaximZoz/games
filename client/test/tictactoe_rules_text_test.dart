import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_repository.dart';

void main() {
  test('buildTictactoeRulesText includes stake amount', () {
    final text = buildTictactoeRulesText(
      gridSize: 3,
      turnTimeSec: 0,
      swapRule: false,
      firstMoveRestriction: false,
      stakeBronze: 5,
    );

    expect(text, contains('Ставка: 5 бр.'));
    expect(text, contains('На столько монет идёт игра.'));
  });

  test('buildTictactoeRulesText defaults stake to 1 bronze', () {
    final text = buildTictactoeRulesText(
      gridSize: 3,
      turnTimeSec: 30,
      swapRule: true,
      firstMoveRestriction: true,
    );

    expect(text, contains('Ставка: 1 бр.'));
  });
}
