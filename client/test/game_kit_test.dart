import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_game_kit/multigames_game_kit.dart';

void main() {
  group('scatterSlots', () {
    const area = Size(320, 110);
    const item = Size(20, 38);

    test('россыпь детерминирована и не выходит за поле', () {
      final first = scatterSlots(capacity: 14, area: area, item: item, seed: 7);
      final again = scatterSlots(capacity: 14, area: area, item: item, seed: 7);
      expect(first, hasLength(14));
      for (var i = 0; i < first.length; i++) {
        expect(first[i].center, again[i].center);
        expect(first[i].angle, again[i].angle);
        expect(first[i].center.dx, inInclusiveRange(0, area.width));
        expect(first[i].center.dy, inInclusiveRange(0, area.height));
        expect(first[i].angle.abs(), lessThanOrEqualTo(0.55));
      }
      final other = scatterSlots(capacity: 14, area: area, item: item, seed: 8);
      expect(
        [for (final slot in other) slot.center],
        isNot([for (final slot in first) slot.center]),
      );
    });

    test('фишки действительно разбросаны, а не лежат стопкой', () {
      final slots = scatterSlots(capacity: 14, area: area, item: item);
      final centers = {for (final slot in slots) slot.center};
      expect(centers, hasLength(14));
      expect(slots.any((slot) => slot.angle.abs() > 0.05), isTrue);
    });

    test('пустое поле и нулевая вместимость дают пустую россыпь', () {
      expect(scatterSlots(capacity: 0, area: area, item: item), isEmpty);
      expect(scatterSlots(capacity: 5, area: Size.zero, item: item), isEmpty);
    });
  });

  group('GameHandStripMetrics', () {
    const metrics = GameHandStripMetrics(
      viewport: 300,
      itemSize: Size(40, 76),
      height: 100,
      spacing: 10,
      padding: EdgeInsets.symmetric(horizontal: 14),
    );

    test('пока рука помещается, она по центру и не листается', () {
      expect(metrics.scrollable(5), isFalse);
      final first = metrics.itemRect(0, count: 5);
      final last = metrics.itemRect(4, count: 5);
      expect(first.left, closeTo(300 - last.right, 0.01));
      expect(metrics.itemRect(1, count: 5).left - first.right, 10);
      expect(metrics.revealOffset(4, count: 5), 0);
    });

    test('большая рука листается и докручивается до нужной фишки', () {
      expect(metrics.scrollable(12), isTrue);
      expect(metrics.itemRect(0, count: 12).left, 14);
      final max = metrics.maxScroll(12);
      expect(max, 12 * 40 + 11 * 10 + 28 - 300);
      expect(metrics.revealOffset(11, count: 12), max);
      expect(metrics.revealOffset(0, count: 12, current: max), 0);
      final shown = metrics.itemRect(11, count: 12, scroll: max);
      expect(shown.right, closeTo(300 - 14, 0.01));
    });
  });

  group('GameHandStrip', () {
    Widget strip(List<int> items) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: GameHandStrip(
                  itemCount: items.length,
                  itemSize: const Size(40, 76),
                  height: 100,
                  spacing: 10,
                  itemKeyBuilder: (index) => items[index],
                  itemBuilder: (context, index) => ColoredBox(
                    key: ValueKey('item-${items[index]}'),
                    color: Colors.indigo,
                  ),
                ),
              ),
            ),
          ),
        );

    testWidgets('соседи съезжаются плавно, когда фишка ушла', (tester) async {
      await tester.pumpWidget(strip([1, 2, 3]));
      final before = tester.getRect(find.byKey(const ValueKey('item-3')));
      await tester.pumpWidget(strip([1, 3]));
      await tester.pump();
      final start = tester.getRect(find.byKey(const ValueKey('item-3')));
      expect(start.left, closeTo(before.left, 0.5),
          reason: 'в первом кадре фишка ещё на старом месте');
      await tester.pump(const Duration(milliseconds: 120));
      final mid = tester.getRect(find.byKey(const ValueKey('item-3')));
      await tester.pumpAndSettle();
      final end = tester.getRect(find.byKey(const ValueKey('item-3')));
      expect(mid.left, lessThan(start.left));
      expect(mid.left, greaterThan(end.left));
      expect(end.left, closeTo(before.left - 25, 0.5));
    });
  });

  group('GameFlightController', () {
    testWidgets('фишка летит к месту из живой вёрстки и снимается в конце',
        (tester) async {
      late GameFlightController controller;
      final target = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _FlightHost(
              onReady: (value) => controller = value,
              child: Align(
                alignment: Alignment.bottomRight,
                child: SizedBox(key: target, width: 40, height: 60),
              ),
            ),
          ),
        ),
      );
      final destination = controller.rectOf(target)!;
      expect(destination.size, const Size(40, 60));

      var landed = false;
      controller
          .launch(GameFlight(
            from: const Rect.fromLTWH(10, 10, 20, 30),
            to: const Rect.fromLTWH(10, 10, 20, 30),
            toResolver: () => controller.rectOf(target),
            builder: (_, __) => const ColoredBox(
              key: ValueKey('flying'),
              color: Colors.purple,
            ),
          ))
          .then((_) => landed = true);
      await tester.pump();
      expect(controller.activeCount, 1);
      final flying = find.byKey(const ValueKey('flying'));
      expect(tester.getCenter(flying).dx, closeTo(20, 1));

      await tester.pump(GameMotion.flight * 0.5);
      final mid = tester.getCenter(flying);
      expect(mid.dx, greaterThan(20));
      expect(mid.dx, lessThan(destination.center.dx));

      await tester.pump(GameMotion.flight);
      await tester.pump();
      expect(landed, isTrue);
      expect(controller.activeCount, 0);
      expect(flying, findsNothing);
    });

    testWidgets('clear снимает полёты и завершает их Future', (tester) async {
      late GameFlightController controller;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _FlightHost(
              onReady: (value) => controller = value,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      var done = 0;
      for (var i = 0; i < 3; i++) {
        controller
            .launch(GameFlight(
              from: Rect.zero,
              to: const Rect.fromLTWH(100, 100, 10, 10),
              delay: GameMotion.stagger * i,
              builder: (_, __) => const SizedBox(),
            ))
            .then((_) => done++);
      }
      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.activeCount, 3);
      controller.clear();
      await tester.pump();
      expect(controller.activeCount, 0);
      expect(done, 3);
    });
  });
}

class _FlightHost extends StatefulWidget {
  const _FlightHost({required this.onReady, required this.child});

  final ValueChanged<GameFlightController> onReady;
  final Widget child;

  @override
  State<_FlightHost> createState() => _FlightHostState();
}

class _FlightHostState extends State<_FlightHost>
    with TickerProviderStateMixin {
  late final GameFlightController _controller =
      GameFlightController(vsync: this);

  @override
  void initState() {
    super.initState();
    widget.onReady(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameFlightStage(controller: _controller, child: widget.child);
  }
}
