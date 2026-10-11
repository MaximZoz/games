import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/app_theme.dart';
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
    expect(text.style?.color, AppColors.textPrimary);
  });

  testWidgets('prominent: цифры красные, пока идут часы', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: GameClock(remainingMs: 300000, running: true, prominent: true),
      ),
    ));
    final text = tester.widget<Text>(find.text('5:00'));
    expect(text.style?.color, const Color(0xFFE53935));
    await tester.pump(const Duration(milliseconds: 300));
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

  test('nextGameClockTick — щелчок только на смене секунды', () {
    expect(
      nextGameClockTick(
        enabled: false,
        running: true,
        displayedSec: 9,
        lastSec: 10,
      ).play,
      isFalse,
    );
    expect(
      nextGameClockTick(
        enabled: true,
        running: false,
        displayedSec: 9,
        lastSec: 10,
      ).sec,
      isNull,
    );
    final armed = nextGameClockTick(
      enabled: true,
      running: true,
      displayedSec: 300,
      lastSec: null,
    );
    expect(armed.play, isFalse);
    expect(armed.sec, 300);
    final started = nextGameClockTick(
      enabled: true,
      running: true,
      displayedSec: 300,
      lastSec: null,
      playOnArm: true,
    );
    expect(started.play, isTrue);
    expect(started.sec, 300);
    final same = nextGameClockTick(
      enabled: true,
      running: true,
      displayedSec: 300,
      lastSec: armed.sec,
    );
    expect(same.play, isFalse);
    final next = nextGameClockTick(
      enabled: true,
      running: true,
      displayedSec: 299,
      lastSec: same.sec,
    );
    expect(next.play, isTrue);
    expect(next.sec, 299);
    final jumped = nextGameClockTick(
      enabled: true,
      running: true,
      displayedSec: 290,
      lastSec: next.sec,
    );
    expect(jumped.play, isTrue);
    expect(jumped.sec, 290);
    expect(clockDisplayedSec(4200), 5);
    expect(clockDisplayedSec(4000), 4);
  });

  testWidgets('tickSound щёлкает раз в показанную секунду и замолкает',
      (tester) async {
    var ticks = 0;
    var elapsed = 0;
    GameClock.debugOnTick = () => ticks++;
    GameClock.debugElapsedMs = () => elapsed;
    addTearDown(() {
      GameClock.debugOnTick = null;
      GameClock.debugElapsedMs = null;
    });

    var running = true;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                GameClock(
                  remainingMs: 10000,
                  running: running,
                  tickSound: true,
                  prominent: true,
                ),
                TextButton(
                  onPressed: () => setState(() => running = false),
                  child: const Text('stop'),
                ),
              ],
            );
          },
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 250));
    expect(ticks, 0);
    elapsed = 1000;
    await tester.pump(const Duration(milliseconds: 250));
    expect(ticks, 1);
    expect(find.text('0:09'), findsOneWidget);
    elapsed = 2000;
    await tester.pump(const Duration(milliseconds: 250));
    expect(ticks, 2);
    await tester.tap(find.text('stop'));
    await tester.pump();
    elapsed = 5000;
    await tester.pump(const Duration(seconds: 2));
    expect(ticks, 2);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: GameClock(remainingMs: 10000, running: true, prominent: true),
      ),
    ));
    elapsed = 3000;
    await tester.pump(const Duration(seconds: 1));
    expect(ticks, 2);
  });

  testWidgets('чужие часы не откатываются, если снимок остался прежним',
      (tester) async {
    var elapsed = 0;
    GameClock.debugElapsedMs = () => elapsed;
    addTearDown(() => GameClock.debugElapsedMs = null);
    Future<void> pumpClock(int remainingMs) {
      return tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GameClock(
            remainingMs: remainingMs,
            running: true,
            prominent: true,
          ),
        ),
      ));
    }

    await pumpClock(10000);
    elapsed = 2000;
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('0:08'), findsOneWidget);
    await pumpClock(10000);
    await tester.pump();
    expect(find.text('0:08'), findsOneWidget);
    elapsed = 3000;
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('0:07'), findsOneWidget);
  });

  testWidgets('tickOnStart щёлкает сразу, когда часы начали идти',
      (tester) async {
    var ticks = 0;
    GameClock.debugOnTick = () => ticks++;
    GameClock.debugElapsedMs = () => 0;
    addTearDown(() {
      GameClock.debugOnTick = null;
      GameClock.debugElapsedMs = null;
    });
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: GameClock(
          remainingMs: 300000,
          running: true,
          prominent: true,
          tickSound: true,
          tickOnStart: true,
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 250));
    expect(ticks, 1);
    await tester.pump(const Duration(milliseconds: 250));
    expect(ticks, 1);
  });
}
