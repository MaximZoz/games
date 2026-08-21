import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/game_fly_overlay.dart';

void main() {
  tearDown(GameFlyOverlay.dismissAll);

  testWidgets('dismissAll removes a leftover root overlay', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('page'))),
    );
    final overlay = Overlay.of(
      tester.element(find.text('page')),
      rootOverlay: true,
    );
    GameFlyOverlay.insert(
      overlay,
      (_) => const Positioned(
        left: 12,
        top: 12,
        child: Text('stray-fly'),
      ),
    );
    await tester.pump();
    expect(find.text('stray-fly'), findsOneWidget);
    expect(GameFlyOverlay.debugActiveCount, 1);

    GameFlyOverlay.dismissAll();
    await tester.pump();
    expect(find.text('stray-fly'), findsNothing);
    expect(GameFlyOverlay.debugActiveCount, 0);
  });

  test('sameNamedRoute ignores refresh of the same page', () {
    final first = PageRouteBuilder<void>(
      settings: const RouteSettings(name: '/coins/login'),
      pageBuilder: (_, __, ___) => const SizedBox(),
    );
    final second = PageRouteBuilder<void>(
      settings: const RouteSettings(name: '/coins/login'),
      pageBuilder: (_, __, ___) => const SizedBox(),
    );
    final other = PageRouteBuilder<void>(
      settings: const RouteSettings(name: '/coins'),
      pageBuilder: (_, __, ___) => const SizedBox(),
    );
    expect(sameNamedRoute(first, second), isTrue);
    expect(sameNamedRoute(first, other), isFalse);
    expect(sameNamedRoute(first, null), isFalse);
  });

  testWidgets('remove is safe twice', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('page'))),
    );
    final overlay = Overlay.of(
      tester.element(find.text('page')),
      rootOverlay: true,
    );
    final entry = GameFlyOverlay.insert(
      overlay,
      (_) => const Positioned(left: 0, top: 0, child: Text('once')),
    );
    await tester.pump();
    GameFlyOverlay.remove(entry);
    GameFlyOverlay.remove(entry);
    await tester.pump();
    expect(find.text('once'), findsNothing);
    expect(GameFlyOverlay.debugActiveCount, 0);
  });
}
