import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/durak/card_fly.dart';
import 'package:multigames_client/ui/widgets/game_fly_overlay.dart';

void main() {
  tearDown(GameFlyOverlay.debugReset);

  test('isGamePlayPath только партия, не список и не лобби', () {
    expect(GameFlyOverlay.isGamePlayPath('/games/durak/game/abc'), isTrue);
    expect(GameFlyOverlay.isGamePlayPath('/games/uno/offline'), isTrue);
    expect(GameFlyOverlay.isGamePlayPath('/games'), isFalse);
    expect(GameFlyOverlay.isGamePlayPath('/games/uno/lobby/l1'), isFalse);
    expect(GameFlyOverlay.isGamePlayPath('/chats'), isFalse);
  });

  test('syncVisiblePath снимает полёты при уходе с партии', () {
    GameFlyOverlay.syncVisiblePath('/games/durak/game/g1');
    expect(GameFlyOverlay.shouldShowFlight(gameOnly: true), isTrue);
    GameFlyOverlay.syncVisiblePath('/chats');
    expect(GameFlyOverlay.shouldShowFlight(gameOnly: true), isFalse);
    expect(GameFlyOverlay.visiblePath, '/chats');
  });

  test('shouldShowFlight не пускает игровые полёты с чатов', () {
    GameFlyOverlay.syncVisiblePath('/chats');
    expect(GameFlyOverlay.shouldShowFlight(gameOnly: true), isFalse);
    expect(GameFlyOverlay.shouldShowFlight(), isTrue);
  });

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

  testWidgets('overlaySpaceSize берёт корневой overlay, не коробку вкладки',
      (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 200,
            child: Text('box'),
          ),
        ),
      ),
    );
    final ctx = tester.element(find.text('box'));
    final space = overlaySpaceSize(ctx);
    expect(space.width, greaterThanOrEqualTo(800));
    expect(space.height, greaterThanOrEqualTo(360));
  });

  testWidgets('CardFlyTicket.dismissAll снимает зависший полёт', (tester) async {
    CardFlyTicket.debugReset();
    GameFlyOverlay.debugReset();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('page'))),
    );
    final overlay = Overlay.of(
      tester.element(find.text('page')),
      rootOverlay: true,
    );
    final entry = GameFlyOverlay.insert(
      overlay,
      (_) => const Positioned(left: 8, top: 8, child: Text('stuck-fly')),
    );
    CardFlyTicket.debugAttach(entry);
    await tester.pump();
    expect(find.text('stuck-fly'), findsOneWidget);
    expect(CardFlyTicket.debugLiveCount, 1);

    CardFlyTicket.dismissAll();
    await tester.pump();
    expect(find.text('stuck-fly'), findsNothing);
    expect(CardFlyTicket.debugLiveCount, 0);
  });
}
