import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/desktop_tile_grid.dart';

void main() {
  testWidgets('DesktopTileGrid uses mobile builder on narrow screens',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: DesktopTileGrid(
            itemCount: 2,
            itemBuilder: (_, __) => const Text('tile'),
            mobileBuilder: (_) => const Text('mobile-list'),
          ),
        ),
      ),
    );
    expect(find.text('mobile-list'), findsOneWidget);
    expect(find.text('tile'), findsNothing);
  });

  testWidgets('DesktopTileGrid builds tiles on wide screens', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1200, 800)),
          child: DesktopTileGrid(
            itemCount: 2,
            itemBuilder: (_, i) => Text('tile-$i'),
            mobileBuilder: (_) => const Text('mobile-list'),
          ),
        ),
      ),
    );
    expect(find.text('mobile-list'), findsNothing);
    expect(find.text('tile-0'), findsOneWidget);
    expect(find.text('tile-1'), findsOneWidget);
  });

  testWidgets('DesktopContentFrame forces width on wide screens', (tester) async {
    late double childWidth;
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesktopContentFrame(
            maxWidth: 960,
            child: LayoutBuilder(
              builder: (context, constraints) {
                childWidth = constraints.maxWidth;
                return const SizedBox(height: 10);
              },
            ),
          ),
        ),
      ),
    );
    expect(childWidth, 960);
  });
}
