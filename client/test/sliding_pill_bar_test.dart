import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/sliding_pill_bar.dart';

void main() {
  testWidgets('плашка едет за пальцем и встаёт на вкладку', (tester) async {
    final selected = ValueNotifier<int>(0);
    addTearDown(selected.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 300,
              child: ValueListenableBuilder<int>(
                valueListenable: selected,
                builder: (context, index, _) {
                  return SlidingPillBar(
                    itemCount: 3,
                    selectedIndex: index,
                    onChanged: (next) => selected.value = next,
                    itemBuilder: (context, i, isSelected) {
                      return Text(isSelected ? 'on-$i' : 'off-$i');
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    final bar = tester.getRect(find.byType(SlidingPillBar));
    final slot = bar.width / 3;
    final gesture = await tester.startGesture(
      Offset(bar.left + 12, bar.center.dy),
    );
    await gesture.moveTo(Offset(bar.left + slot + slot / 2, bar.center.dy));
    await tester.pump();

    expect(selected.value, 1);
    final mid = tester.getCenter(find.byKey(const ValueKey('sliding-pill')));
    expect(mid.dx, greaterThan(bar.left + slot));
    expect(mid.dx, lessThan(bar.left + slot * 2));

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    final pill = tester.getCenter(find.byKey(const ValueKey('sliding-pill')));
    final label = tester.getCenter(find.text('on-1'));
    expect((pill.dx - label.dx).abs(), lessThan(12));
  });
}
