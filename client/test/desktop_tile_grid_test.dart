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
}
