import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

void main() {
  testWidgets('SwipeBackScope вызывает onBack сразу при свайпе вправо',
      (tester) async {
    var backCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SwipeBackScope(
          triggerDistance: 28,
          topInset: 0,
          onBack: () => backCount++,
          child: const Scaffold(
            body: SizedBox.expand(child: Text('content')),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(const Offset(8, 200));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();

    expect(backCount, 1);

    await gesture.up();
    await tester.pump();
    expect(backCount, 1);
  });

  testWidgets('SwipeBackScope не срабатывает когда enabled=false',
      (tester) async {
    var backCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SwipeBackScope(
          enabled: false,
          topInset: 0,
          onBack: () => backCount++,
          child: const Scaffold(
            body: SizedBox.expand(child: Text('content')),
          ),
        ),
      ),
    );

    await tester.dragFrom(const Offset(8, 200), const Offset(80, 0));
    await tester.pump();
    expect(backCount, 0);
  });

  testWidgets('Кнопка назад в шапке кликабельна поверх зоны свайпа',
      (tester) async {
    var backFromButton = 0;
    var backFromSwipe = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SwipeBackScope(
          onBack: () => backFromSwipe++,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Назад',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => backFromButton++,
              ),
              title: const Text('Test'),
            ),
            body: const SizedBox.expand(),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Назад'));
    await tester.pump();

    expect(backFromButton, 1);
    expect(backFromSwipe, 0);
  });

  testWidgets('opaqueEdge=false пропускает тап к виджету у левого края',
      (tester) async {
    var taps = 0;
    var backs = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SwipeBackScope(
          opaqueEdge: false,
          edgeWidth: 48,
          topInset: 0,
          onBack: () => backs++,
          child: Scaffold(
            body: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => taps++,
                  child: const ColoredBox(color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(const Offset(12, 300));
    await tester.pump();

    expect(taps, 1);
    expect(backs, 0);
  });

  testWidgets('bottomInset оставляет нижний левый край кликабельным',
      (tester) async {
    var taps = 0;
    var backs = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SwipeBackScope(
          opaqueEdge: false,
          edgeWidth: 16,
          triggerDistance: 44,
          topInset: 0,
          bottomInset: 240,
          onBack: () => backs++,
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomLeft,
              child: SizedBox(
                width: 56,
                height: 80,
                child: GestureDetector(
                  onTap: () => taps++,
                  child: const ColoredBox(color: Colors.blue),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(const Offset(10, 560));
    await tester.pump();

    expect(taps, 1);
    expect(backs, 0);
  });
}
