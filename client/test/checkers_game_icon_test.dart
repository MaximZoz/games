import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/checkers_game_icon.dart';
import 'package:multigames_client/ui/widgets/game_type_icon.dart';

void main() {
  testWidgets('CheckersGameIcon рисует без ошибок', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: CheckersGameIcon(size: 32, color: Colors.white)),
        ),
      ),
    );
    expect(find.byType(CheckersGameIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GameTypeIcon для checkers использует CheckersGameIcon',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: GameTypeIcon(
              gameType: 'checkers',
              size: 26,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(CheckersGameIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('iconDataOf для checkers указывает на иконку шашек', () {
    expect(GameTypeIcon.iconDataOf('checkers'), CheckersGameIcon.iconData);
  });
}
