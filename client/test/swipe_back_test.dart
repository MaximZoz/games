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
}
