import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/battleship/battleship_fleet_panel.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required BattleshipFleetFocus focus,
  List<List<int>> mySunk = const [],
  List<List<int>> opponentSunk = const [],
  String opponentLabel = 'Бот',
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
          child: BattleshipFleetPanel(
            opponentLabel: opponentLabel,
            mySunkShips: mySunk,
            opponentSunkShips: opponentSunk,
            focus: focus,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

BoxDecoration _plate(WidgetTester tester, String side) {
  final widget = tester.widget<AnimatedContainer>(
    find.byKey(ValueKey('battleship-fleet-plate-$side')),
  );
  return widget.decoration! as BoxDecoration;
}

Color _glyphColor(WidgetTester tester, String side, int index) {
  final glyph = find.byKey(ValueKey('battleship-ship-$side-$index'));
  final cell = tester.widget<AnimatedContainer>(
    find.descendant(of: glyph, matching: find.byType(AnimatedContainer)).first,
  );
  return (cell.decoration! as BoxDecoration).color!;
}

void main() {
  testWidgets('мой ход подсвечивает флот соперника и считает сбитые',
      (tester) async {
    await _pump(
      tester,
      size: const Size(390, 200),
      focus: BattleshipFleetFocus.opponent,
      mySunk: const [
        [40, 41],
      ],
      opponentSunk: const [
        [0, 1, 2, 3],
        [8],
      ],
    );

    expect(find.text('Вы'), findsOneWidget);
    expect(find.text('Бот'), findsOneWidget);
    expect(find.text('Сбито'), findsNWidgets(2));
    expect(find.text('Осталось'), findsNWidgets(2));
    expect(
      tester
          .widget<Text>(
              find.byKey(const ValueKey('battleship-fleet-mine-sunk')))
          .data,
      '1',
    );
    expect(
      tester
          .widget<Text>(
              find.byKey(const ValueKey('battleship-fleet-mine-left')))
          .data,
      '9',
    );
    expect(
      tester
          .widget<Text>(
              find.byKey(const ValueKey('battleship-fleet-opponent-sunk')))
          .data,
      '2',
    );
    expect(
      tester
          .widget<Text>(
              find.byKey(const ValueKey('battleship-fleet-opponent-left')))
          .data,
      '8',
    );

    final opponent = _plate(tester, 'opponent');
    final mine = _plate(tester, 'mine');
    expect(
      (opponent.border! as Border).top.color,
      AppColors.accentStart,
    );
    expect((mine.border! as Border).top.color, Colors.transparent);
    expect(_glyphColor(tester, 'opponent', 0), const Color(0xFFE53935));
    expect(_glyphColor(tester, 'opponent', 1), const Color(0xFF607D8B));
    expect(_glyphColor(tester, 'opponent', 6), const Color(0xFFE53935));
    expect(_glyphColor(tester, 'mine', 3), const Color(0xFFE53935));
    expect(find.bySemanticsLabel('Бот: 2 сбито, 8 осталось'), findsOneWidget);
    expect(find.bySemanticsLabel('Вы: 1 сбито, 9 осталось'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ход соперника подсвечивает мой флот', (tester) async {
    await _pump(
      tester,
      size: const Size(800, 240),
      focus: BattleshipFleetFocus.mine,
      opponentLabel: 'Анна',
    );

    expect(find.text('Анна'), findsOneWidget);
    final mine = _plate(tester, 'mine');
    final opponent = _plate(tester, 'opponent');
    expect((mine.border! as Border).top.color, const Color(0xFFE53935));
    expect((opponent.border! as Border).top.color, Colors.transparent);
    expect(
      tester
          .widget<Text>(
              find.byKey(const ValueKey('battleship-fleet-opponent-left')))
          .data,
      '10',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('узкий и широкий экран не дают переполнения', (tester) async {
    for (final size in const [Size(320, 180), Size(900, 220)]) {
      await _pump(
        tester,
        size: size,
        focus: BattleshipFleetFocus.none,
        opponentLabel: 'Очень длинное имя соперника',
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Очень длинное имя соперника'), findsOneWidget);
    }
  });
}
