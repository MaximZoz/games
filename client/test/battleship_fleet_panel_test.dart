import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/battleship/battleship_fleet_panel.dart';
import 'package:multigames_client/l10n/l10n.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required List<List<int>> sunkShips,
  String semanticsLabel = 'Бот: 2 сбито, 8 осталось',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: BattleshipFleetLine(
            sunkShips: sunkShips,
            semanticsLabel: semanticsLabel,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color _glyphColor(WidgetTester tester, int index) {
  final glyph = find.byKey(ValueKey('battleship-ship-$index'));
  final cell = tester.widget<AnimatedContainer>(
    find.descendant(of: glyph, matching: find.byType(AnimatedContainer)).first,
  );
  return (cell.decoration! as BoxDecoration).color!;
}

void main() {
  testWidgets('линия кораблей без подписей, сбитые красные', (tester) async {
    await _pump(
      tester,
      size: const Size(390, 80),
      sunkShips: const [
        [0, 1, 2, 3],
        [8],
      ],
    );

    expect(find.text('Сбито'), findsNothing);
    expect(find.text('Осталось'), findsNothing);
    expect(find.text('Вы'), findsNothing);
    expect(find.text('Бот'), findsNothing);
    expect(find.byKey(const ValueKey('battleship-fleet-line')), findsOneWidget);
    expect(_glyphColor(tester, 0), BattleshipFleetLine.sunk);
    expect(_glyphColor(tester, 1), BattleshipFleetLine.afloat);
    expect(_glyphColor(tester, 6), BattleshipFleetLine.sunk);
    expect(_glyphColor(tester, 9), BattleshipFleetLine.afloat);
    expect(find.bySemanticsLabel('Бот: 2 сбито, 8 осталось'), findsOneWidget);

    final line =
        tester.getSize(find.byKey(const ValueKey('battleship-fleet-line')));
    expect(line.width, greaterThan(300));
    expect(line.height, lessThan(20));
    expect(tester.takeException(), isNull);
  });

  testWidgets('узкая и широкая линия не переполняются', (tester) async {
    for (final size in const [Size(320, 80), Size(900, 80)]) {
      await _pump(
        tester,
        size: size,
        sunkShips: const [
          [40, 41],
        ],
      );
      expect(tester.takeException(), isNull);
      expect(_glyphColor(tester, 3), BattleshipFleetLine.sunk);
      expect(find.text('Сбито'), findsNothing);
    }
  });
}
