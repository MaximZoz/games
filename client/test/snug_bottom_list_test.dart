import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/snug_bottom_list.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required double height,
    required List<Widget> children,
    EdgeInsets padding = EdgeInsets.zero,
    double minGap = 10,
    double maxGap = 24,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            key: const Key('view'),
            width: 300,
            height: height,
            child: SnugBottomList(
              padding: padding,
              minGap: minGap,
              maxGap: maxGap,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('почти полный список забирает пустоту в зазоры и садится на низ',
      (tester) async {
    await pump(
      tester,
      height: 120,
      children: const [
        SizedBox(key: Key('a'), height: 50),
        SizedBox(key: Key('b'), height: 50),
      ],
    );
    final view = tester.getRect(find.byKey(const Key('view')));
    final a = tester.getRect(find.byKey(const Key('a')));
    final b = tester.getRect(find.byKey(const Key('b')));
    expect(b.bottom, closeTo(view.bottom, 0.1));
    expect(b.top - a.bottom, closeTo(20, 0.1));
  });

  testWidgets('очень короткий список не раздувает зазоры', (tester) async {
    await pump(
      tester,
      height: 400,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      children: const [
        SizedBox(key: Key('a'), height: 50),
        SizedBox(key: Key('b'), height: 50),
      ],
    );
    final view = tester.getRect(find.byKey(const Key('view')));
    final a = tester.getRect(find.byKey(const Key('a')));
    final b = tester.getRect(find.byKey(const Key('b')));
    expect(a.top, closeTo(view.top + 8, 0.1));
    expect(b.top - a.bottom, closeTo(24, 0.1));
    expect(view.bottom - b.bottom, greaterThan(100));
  });

  testWidgets('длинный список скроллится с минимальным зазором',
      (tester) async {
    await pump(
      tester,
      height: 80,
      children: const [
        SizedBox(key: Key('a'), height: 50),
        SizedBox(key: Key('b'), height: 50),
      ],
    );
    final a = tester.getRect(find.byKey(const Key('a')));
    final b = tester.getRect(find.byKey(const Key('b')));
    expect(b.top - a.bottom, closeTo(10, 0.1));
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scroll.position.maxScrollExtent, greaterThan(0));
  });
}
