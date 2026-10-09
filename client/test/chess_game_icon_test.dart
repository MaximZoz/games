import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/chess_game_icon.dart';
import 'package:multigames_client/ui/widgets/game_type_icon.dart';

void main() {
  testWidgets('ChessGameIcon рисует без ошибок', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: ChessGameIcon(size: 32, color: Colors.white)),
        ),
      ),
    );
    expect(find.byType(ChessGameIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GameTypeIcon для chess использует ChessGameIcon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: GameTypeIcon(
              gameType: 'chess',
              size: 26,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(ChessGameIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('iconDataOf для chess указывает на иконку шахмат', () {
    expect(GameTypeIcon.iconDataOf('chess'), ChessGameIcon.iconData);
  });
}
