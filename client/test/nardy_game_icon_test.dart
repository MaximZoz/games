import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/game_type_icon.dart';
import 'package:multigames_client/ui/widgets/nardy_game_icon.dart';

void main() {
  testWidgets('NardyGameIcon рисует без ошибок', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: NardyGameIcon(size: 32, color: Colors.white)),
        ),
      ),
    );
    expect(find.byType(NardyGameIcon), findsOneWidget);
    expect(find.byIcon(Icons.hexagon_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GameTypeIcon для nardy использует NardyGameIcon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: GameTypeIcon(
              gameType: 'nardy',
              size: 26,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(NardyGameIcon), findsOneWidget);
    expect(find.byIcon(Icons.hexagon_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('iconDataOf для nardy не использует hexagon', () {
    expect(GameTypeIcon.iconDataOf('nardy'), NardyGameIcon.iconData);
    expect(GameTypeIcon.iconDataOf('nardy'), isNot(Icons.hexagon_rounded));
  });
}
