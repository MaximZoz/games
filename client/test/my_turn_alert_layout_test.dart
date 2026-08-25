import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/sfx.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';

void main() {
  tearDown(TurnClockSfx.reset);

  testWidgets(
    'MyTurnAlert в Stack не схлопывает Positioned.fill стол',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 400,
            height: 300,
            child: Stack(
              children: [
                MyTurnAlert(isMyTurn: false),
                Positioned.fill(
                  child: ColoredBox(color: Color(0xFF135C39)),
                ),
              ],
            ),
          ),
        ),
      );
      final loose = tester.getSize(find.byType(ColoredBox));
      expect(loose.width, 0);
      expect(loose.height, 0);

      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 400,
            height: 300,
            child: Stack(
              children: [
                MyTurnAlert.stackLeaf(isMyTurn: false),
                Positioned.fill(
                  child: ColoredBox(color: Color(0xFF135C39)),
                ),
              ],
            ),
          ),
        ),
      );
      final fixed = tester.getSize(find.byType(ColoredBox));
      expect(fixed.width, 400);
      expect(fixed.height, 300);
    },
  );
}
