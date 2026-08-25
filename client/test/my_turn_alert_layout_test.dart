import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/sfx.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';

void main() {
  tearDown(TurnClockSfx.reset);

  testWidgets(
    'MyTurnAlert.stackLeaf не схлопывает стол в Column+Stack',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      MyTurnAlert(isMyTurn: false),
                      Positioned.fill(
                        child: ColoredBox(color: Color(0xFF135C39)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      // Expanded даёт tight-ограничения — стол жив даже с loose MyTurnAlert.
      expect(tester.getSize(find.byType(ColoredBox)).height, greaterThan(100));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Stack(
                  children: [
                    MyTurnAlert(isMyTurn: false),
                    Positioned.fill(
                      child: ColoredBox(color: Color(0xFF135C39)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(ColoredBox)).height, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      MyTurnAlert.stackLeaf(isMyTurn: false),
                      const Positioned.fill(
                        child: ColoredBox(color: Color(0xFF135C39)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(ColoredBox)).height, greaterThan(100));
    },
  );
}
