import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';

void main() {
  test('formatClockMs форматирует M:SS и H:MM:SS', () {
    expect(formatClockMs(0), '0:00');
    expect(formatClockMs(5000), '0:05');
    expect(formatClockMs(65000), '1:05');
    expect(formatClockMs(600000), '10:00');
    expect(formatClockMs(3600000), '60:00');
    expect(formatClockMs(100 * 60 * 1000), '1:40:00');
    // Округление вверх: 4.2с -> 5с (пока не истекло, показываем «5»).
    expect(formatClockMs(4200), '0:05');
    // Отрицательное значение не уходит в минус.
    expect(formatClockMs(-100), '0:00');
  });

  testWidgets('GameClock показывает остаток и подпись', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: GameClock(remainingMs: 185000, running: false, label: 'Вы'),
      ),
    ));
    expect(find.text('3:05'), findsOneWidget);
    expect(find.text('Вы'), findsOneWidget);
  });

  testWidgets('GameClock prominent — крупная плашка без подписи',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: GameClock(remainingMs: 3600000, running: false, prominent: true),
      ),
    ));
    expect(find.text('60:00'), findsOneWidget);
    final text = tester.widget<Text>(find.text('60:00'));
    expect(text.style?.fontSize, 20);
  });

  testWidgets('GameClock активного игрока показывает идущее время',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: GameClock(remainingMs: 185000, running: true),
      ),
    ));
    // На старте активные часы показывают исходный остаток и строят виджет.
    expect(find.text('3:05'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(GameClock), findsOneWidget);
  });
}
