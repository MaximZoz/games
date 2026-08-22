import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/durak_game_icon.dart';
import 'package:multigames_client/ui/widgets/poker_game_icon.dart';

void main() {
  testWidgets('DurakGameIcon рисует без ошибок', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: DurakGameIcon(size: 32)),
        ),
      ),
    );
    expect(find.byType(DurakGameIcon), findsOneWidget);
    expect(find.byIcon(DurakGameIcon.iconData), findsOneWidget);
    expect(find.byIcon(Icons.style_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PokerGameIcon рисует без ошибок', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: PokerGameIcon(size: 32)),
        ),
      ),
    );
    expect(find.byType(PokerGameIcon), findsOneWidget);
    expect(find.byIcon(PokerGameIcon.iconData), findsOneWidget);
    expect(find.byIcon(Icons.casino_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
