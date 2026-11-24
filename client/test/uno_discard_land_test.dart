import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/uno/uno_card.dart';
import 'package:multigames_client/games/uno/uno_discard_land.dart';
import 'package:multigames_client/ui/uno/uno_card_fly.dart';
import 'package:multigames_client/ui/uno/uno_card_widget.dart';
import 'package:multigames_client/ui/uno/uno_discard_stack.dart';
import 'package:multigames_client/ui/widgets/game_fly_overlay.dart';

UnoCard _card(String id, UnoColor color, int number) => UnoCard(
      id: id,
      color: color,
      kind: UnoCardKind.number,
      number: number,
    );

void main() {
  test('discard land pose stays tilted and stable for the same card', () {
    final land = unoDiscardLandPose('red-7');
    expect(unoDiscardLandPose('red-7').angle, land.angle);
    expect(land.angle.abs(), inInclusiveRange(0.12, 0.21));
    expect(land.dx.abs(), inInclusiveRange(7, 10));
    expect(land.dy, inInclusiveRange(-2, 2));
    expect((land.tossAngle - land.angle).abs(), closeTo(0.78, 0.001));
    final other = unoDiscardLandPose('blue-3');
    expect(land.angle != other.angle || land.dx != other.dx, isTrue);
    final thrown = unoDiscardThrowOnto(land);
    expect(thrown.angle.sign, isNot(land.angle.sign));
    expect(thrown.dx.sign, isNot(land.dx.sign));
    expect(thrown.angle.abs(), greaterThan(0.13));
  });

  testWidgets('сброс показывает верхнюю карту поверх предыдущей',
      (tester) async {
    const size = Size(62, 93);
    final underLand = unoDiscardLandPose('under-red-5');
    final topLand = unoDiscardThrowOnto(underLand);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0A3E3A),
          body: Center(
            child: RepaintBoundary(
              key: const Key('frame'),
              child: UnoDiscardStack(
                cardSize: size,
                topLand: topLand,
                underLand: underLand,
                top: const UnoCard(
                  id: 'top-blue-9',
                  color: UnoColor.blue,
                  kind: UnoCardKind.number,
                  number: 9,
                ),
                under: const UnoCard(
                  id: 'under-red-5',
                  color: UnoColor.red,
                  kind: UnoCardKind.number,
                  number: 5,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(UnoDiscardStack), findsOneWidget);
    final stack = tester.widget<UnoDiscardStack>(find.byType(UnoDiscardStack));
    expect(stack.top.id, 'top-blue-9');
    expect(stack.under?.id, 'under-red-5');
    expect(tester.getSize(find.byType(UnoDiscardStack)), size);
    await _save(tester, 'uno-discard-stack.png');
  });

  testWidgets('карта долетает на сброс под углом и перекрывает нижнюю',
      (tester) async {
    addTearDown(GameFlyOverlay.debugReset);
    GameFlyOverlay.syncVisiblePath('/games/uno/game/demo');
    const cardSize = Size(62, 93);
    final under = _card('under-red-5', UnoColor.red, 5);
    final top = _card('thrown-yellow-8', UnoColor.yellow, 8);
    final router = GoRouter(
      initialLocation: '/games/uno/game/demo',
      routes: [
        GoRoute(
          path: '/games/uno/game/demo',
          builder: (context, state) => Scaffold(
            backgroundColor: const Color(0xFF125D42),
            body: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(key: Key('hand'), width: 62, height: 93),
                  const SizedBox(width: 120),
                  UnoDiscardStack(
                    key: const Key('pile'),
                    cardSize: cardSize,
                    top: under,
                    topLand: unoDiscardLandPose(under.id),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('frame'),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    final context = tester.element(find.byType(Scaffold));
    final from = tester.getRect(find.byKey(const Key('hand')));
    final pile = tester.getRect(find.byKey(const Key('pile')));
    final land = unoDiscardThrowOnto(unoDiscardLandPose(under.id));
    final flight = playUnoCardFlyAnimation(
      context: context,
      card: top,
      cardSize: cardSize,
      from: from,
      to: pile.shift(Offset(land.dx, land.dy)),
      beginAngle: land.tossAngle,
      endAngle: land.angle,
      beginScale: 1.12,
      endScale: 1,
      arcLift: 68,
      duration: const Duration(milliseconds: 540),
      keepAtEnd: true,
      playSfx: false,
    );
    await tester.pump();
    expect(GameFlyOverlay.debugActiveCount, 1);
    await tester.pump(const Duration(milliseconds: 110));
    await _save(tester, 'uno-discard-throw-mid.png');
    await tester.pump(const Duration(milliseconds: 500));
    final ticket = await flight;
    addTearDown(ticket.dismiss);
    expect(land.angle.abs(), greaterThan(0.1));
    expect(land.dx.abs(), greaterThan(6));
  });

  test('fan angle is flat for one card and opposite for neighbors', () {
    expect(unoHandFanAngle(index: 0, count: 1), 0);
    expect(
      unoHandFanAngle(index: 1, count: 2),
      closeTo(0.0125, 0.000001),
    );
    expect(
      unoHandFanAngle(index: 0, count: 2),
      closeTo(-0.0125, 0.000001),
    );
  });

  testWidgets('бросок с угла веера закрывает карту под собой', (tester) async {
    final spot = await _pumpCoveredHand(tester);
    final context = tester.element(find.byType(Scaffold));
    final from = tester.getRect(find.byKey(const Key('played')));
    final flight = playUnoCardFlyAnimation(
      context: context,
      card: const UnoCard(
        id: 'played',
        color: UnoColor.blue,
        kind: UnoCardKind.number,
        number: 8,
      ),
      cardSize: _handCard,
      from: from,
      to: from.translate(180, -40),
      beginAngle: _fan,
      endAngle: 0.16,
      beginAlignment: Alignment.bottomCenter,
      endAlignment: Alignment.center,
      matchRects: true,
      curve: Curves.easeInOutCubic,
      duration: const Duration(milliseconds: 540),
      playSfx: false,
    );
    await tester.pump();
    expect(GameFlyOverlay.debugActiveCount, 1);
    final covered = await _pixel(tester, spot);
    expect(covered.b, greaterThan(covered.r + 0.15), reason: '$covered');
    await _save(tester, 'uno-throw-covers-under.png');
    await tester.pump(const Duration(milliseconds: 600));
    (await flight).dismiss();
  });

  testWidgets('старт с сильного наклона открывает карту под броском',
      (tester) async {
    final spot = await _pumpCoveredHand(tester);
    final context = tester.element(find.byType(Scaffold));
    final from = tester.getRect(find.byKey(const Key('played')));
    final flight = playUnoCardFlyAnimation(
      context: context,
      card: const UnoCard(
        id: 'played',
        color: UnoColor.blue,
        kind: UnoCardKind.number,
        number: 8,
      ),
      cardSize: const Size(62, 93),
      from: from,
      to: from.translate(180, -40),
      beginAngle: 0.9,
      endAngle: 0.16,
      beginScale: 1.12,
      duration: const Duration(milliseconds: 540),
      playSfx: false,
    );
    await tester.pump();
    final revealed = await _pixel(tester, spot);
    expect(revealed.r, greaterThan(revealed.b + 0.15), reason: '$revealed');
    await _save(tester, 'uno-throw-under-flash.png');
    await tester.pump(const Duration(milliseconds: 600));
    (await flight).dismiss();
  });
}

const Size _handCard = Size(90, 130);
const double _fan = 0.0125;

Future<Offset> _pumpCoveredHand(WidgetTester tester) async {
  addTearDown(GameFlyOverlay.debugReset);
  GameFlyOverlay.syncVisiblePath('/games/uno/game/demo');
  final router = GoRouter(
    initialLocation: '/games/uno/game/demo',
    routes: [
      GoRoute(
        path: '/games/uno/game/demo',
        builder: (context, state) => Scaffold(
          backgroundColor: Color(0xFF125D42),
          body: Padding(
            padding: EdgeInsets.only(left: 80, top: 60),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                UnoCardWidget(
                  card: UnoCard(
                    id: 'under',
                    color: UnoColor.red,
                    kind: UnoCardKind.number,
                    number: 5,
                  ),
                  size: _handCard,
                ),
                Opacity(
                  opacity: 0,
                  child: Transform.rotate(
                    key: Key('played'),
                    alignment: Alignment.bottomCenter,
                    angle: _fan,
                    child: UnoCardWidget(
                      card: UnoCard(
                        id: 'played',
                        color: UnoColor.blue,
                        kind: UnoCardKind.number,
                        number: 8,
                      ),
                      size: _handCard,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('frame'),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  final from = tester.getRect(find.byKey(const Key('played')));
  return from.topLeft + const Offset(20, 120);
}

Future<Color> _pixel(WidgetTester tester, Offset global) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('frame')),
  );
  final local = boundary.globalToLocal(global);
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
  final data = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.rawStraightRgba),
  );
  expect(data, isNotNull);
  final x = local.dx.round().clamp(0, image!.width - 1);
  final y = local.dy.round().clamp(0, image.height - 1);
  final index = (y * image.width + x) * 4;
  return Color.fromARGB(
    data!.getUint8(index + 3),
    data.getUint8(index),
    data.getUint8(index + 1),
    data.getUint8(index + 2),
  );
}

Future<void> _save(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('frame')),
  );
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 2));
  final data = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.png),
  );
  expect(data, isNotNull);
  final dir = Directory('/opt/cursor/artifacts');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  File('${dir.path}/$name').writeAsBytesSync(data!.buffer.asUint8List());
}
