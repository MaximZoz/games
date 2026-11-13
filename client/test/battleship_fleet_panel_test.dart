import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/battleship/battleship_fleet_panel.dart';
import 'package:multigames_client/l10n/l10n.dart';

const _sunk = <bool>[
  true,
  false,
  false,
  false,
  false,
  false,
  true,
  false,
  false,
  false,
];

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  int wounds = 3,
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
            sunk: _sunk,
            wounds: wounds,
            semanticsLabel: 'Бот: 2 сбито, 8 осталось',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color _deckColor(WidgetTester tester, int ship, int deck) {
  final cell = tester.widget<AnimatedContainer>(
    find.byKey(ValueKey('battleship-deck-$ship-$deck')),
  );
  return (cell.decoration! as BoxDecoration).color!;
}

void main() {
  testWidgets('попадания отдельно от силуэтов, потопленный сплошной',
      (tester) async {
    await _pump(tester, size: const Size(390, 80));

    expect(find.text('Сбито'), findsNothing);
    expect(find.text('Осталось'), findsNothing);
    expect(_deckColor(tester, 0, 0), BattleshipFleetLine.hit);
    expect(_deckColor(tester, 0, 3), BattleshipFleetLine.hit);
    expect(_deckColor(tester, 1, 0), BattleshipFleetLine.afloat);
    expect(_deckColor(tester, 1, 2), BattleshipFleetLine.afloat);
    expect(_deckColor(tester, 6, 0), BattleshipFleetLine.hit);
    expect(_deckColor(tester, 7, 0), BattleshipFleetLine.afloat);
    expect(find.byKey(const ValueKey('battleship-wound-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('battleship-wound-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('battleship-wound-3')), findsNothing);

    final line =
        tester.getSize(find.byKey(const ValueKey('battleship-fleet-line')));
    expect(line.width, greaterThan(300));
    expect(line.height, lessThan(20));
    expect(tester.takeException(), isNull);
  });

  testWidgets('узкая и широкая линия не переполняются', (tester) async {
    for (final size in const [Size(320, 80), Size(900, 80)]) {
      await _pump(tester, size: size, wounds: 8);
      expect(tester.takeException(), isNull);
    }
  });
}
