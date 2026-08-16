import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';
import 'package:multigames_client/ui/widgets/game_fly_overlay.dart';

/// Общая кривая полёта: мягкий разгон и длинное торможение без «щелчка» в конце.
const Curve kDurakFlyCurve = Curves.easeOutQuint;

/// Кривая перестановок UI (веер, зона руки) — без резкого старта.
const Curve kDurakLayoutCurve = Curves.easeInOutCubic;

/// Билет на полёт: после [done] при [keepAtEnd] карта остаётся, пока не [dismiss].
class CardFlyTicket {
  CardFlyTicket._(this._entry, this._controller, this._curved);
  final OverlayEntry? _entry;
  final AnimationController? _controller;
  final CurvedAnimation? _curved;
  bool _dismissed = false;

  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    GameFlyOverlay.remove(_entry);
    _curved?.dispose();
    _controller?.dispose();
  }
}

/// Плавный полёт карты из [from] в [to] поверх всего UI.
/// Координаты — [Positioned] в fullscreen [Stack] (как globalRectOf);
/// поворот/масштаб — [Transform] на самой карте.
Future<CardFlyTicket> playCardFlyAnimation({
  required BuildContext context,
  required PlayingCard card,
  required Size cardSize,
  required Rect from,
  required Rect to,
  Duration duration = const Duration(milliseconds: 360),
  Curve curve = kDurakFlyCurve,
  bool faceDown = false,
  bool flipToFace = false,
  double beginAngle = 0,
  double endAngle = 0,
  double beginScale = 1.0,
  double endScale = 1.0,
  double arcLift = 0,
  bool keepAtEnd = false,
}) async {
  // Не играть поверх чатов/других вкладок shell.
  if (!context.mounted || !TickerMode.of(context)) {
    return CardFlyTicket._(null, null, null);
  }
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return CardFlyTicket._(null, null, null);

  final completer = Completer<void>();
  final controller = AnimationController(vsync: _FlyTicker(), duration: duration);
  final anim = CurvedAnimation(parent: controller, curve: curve);

  late final OverlayEntry entry;
  entry = GameFlyOverlay.insert(overlay, (ctx) {
      return IgnorePointer(
        child: AnimatedBuilder(
          animation: anim,
          builder: (context, child) {
            final t = anim.value;
            final scale = lerpDouble(beginScale, endScale, t)!;
            final cx = lerpDouble(from.center.dx, to.center.dx, t)!;
            final cy = lerpDouble(from.center.dy, to.center.dy, t)!;
            final angle = lerpDouble(beginAngle, endAngle, t)!;
            final midLift =
                arcLift == 0 ? 0.0 : -arcLift * math.sin(math.pi * t);
            final left = cx - cardSize.width / 2;
            final top = cy - cardSize.height / 2 + midLift;
            // Positioned в expand-Stack: те же global-координаты, что у
            // globalRectOf / слота посадки. Transform.translate+Align давал
            // посадку «в центр», потом snap на место.
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: left,
                  top: top,
                  width: cardSize.width,
                  height: cardSize.height,
                  child: RepaintBoundary(
                    child: Transform.rotate(
                      angle: angle,
                      child: Transform.scale(
                        scale: scale,
                        filterQuality: FilterQuality.medium,
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          child: _FlyFace(
            card: card,
            cardSize: cardSize,
            faceDown: faceDown,
            flipToFace: flipToFace,
            animation: anim,
          ),
        ),
      );
    },
  );
  try {
    await controller.forward();
  } catch (_) {
    // ignore dispose races
  }
  if (!keepAtEnd) {
    GameFlyOverlay.remove(entry);
    anim.dispose();
    controller.dispose();
    if (!completer.isCompleted) completer.complete();
    return CardFlyTicket._(null, null, null);
  }
  if (!completer.isCompleted) completer.complete();
  await completer.future;
  return CardFlyTicket._(entry, controller, anim);
}

/// Лицо/рубашка; при [flipToFace] переворот зависит от прогресса анимации.
class _FlyFace extends StatelessWidget {
  const _FlyFace({
    required this.card,
    required this.cardSize,
    required this.faceDown,
    required this.flipToFace,
    required this.animation,
  });

  final PlayingCard card;
  final Size cardSize;
  final bool faceDown;
  final bool flipToFace;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    if (!flipToFace) {
      return faceDown
          ? CardBackWidget(size: cardSize, elevated: true)
          : PlayingCardWidget(
              card: card,
              size: cardSize,
              elevated: true,
              highlighted: false,
              animate: false,
            );
    }
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final flipT = t < 0.5 ? t * 2 : (1 - t) * 2;
        final showBack = t < 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(flipT * math.pi / 2),
          child: showBack
              ? CardBackWidget(size: cardSize, elevated: true)
              : PlayingCardWidget(
                  card: card,
                  size: cardSize,
                  elevated: true,
                  highlighted: false,
                  animate: false,
                ),
        );
      },
    );
  }
}

/// Лёгкий TickerProvider без State — для overlay-анимаций вне дерева виджетов.
class _FlyTicker extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

/// Несколько карт летят с небольшим сдвигом по времени.
Future<void> playCardsFlyAnimation({
  required BuildContext context,
  required List<PlayingCard> cards,
  required Size cardSize,
  required List<Rect> froms,
  required List<Rect> tos,
  Duration duration = const Duration(milliseconds: 360),
  Duration stagger = const Duration(milliseconds: 28),
  Curve curve = kDurakFlyCurve,
  bool faceDown = false,
  bool? flipToFace,
  List<double>? beginAngles,
  List<double>? endAngles,
  double beginScale = 1.0,
  double endScale = 1.0,
  double arcLift = 0,
  bool keepAtEnd = false,
  void Function(List<CardFlyTicket> tickets)? onTickets,
  void Function(int index, PlayingCard card)? onCardLaunch,
}) async {
  if (cards.isEmpty) return;
  final tickets = <CardFlyTicket>[];
  final futures = <Future<void>>[];
  final doFlip = flipToFace ?? faceDown;
  for (var i = 0; i < cards.length; i++) {
    final delay = stagger * i;
    Future<void> launch() async {
      if (!context.mounted) return;
      final from = froms[i.clamp(0, froms.length - 1)];
      final to = tos[i.clamp(0, tos.length - 1)];
      final beginA =
          beginAngles != null && i < beginAngles.length ? beginAngles[i] : 0.0;
      final endA = endAngles != null && i < endAngles.length ? endAngles[i] : 0.0;
      onCardLaunch?.call(i, cards[i]);
      final ticket = await playCardFlyAnimation(
        context: context,
        card: cards[i],
        cardSize: cardSize,
        from: from,
        to: to,
        duration: duration,
        curve: curve,
        faceDown: faceDown,
        flipToFace: doFlip,
        beginAngle: beginA,
        endAngle: endA,
        beginScale: beginScale,
        endScale: endScale,
        arcLift: arcLift,
        keepAtEnd: keepAtEnd,
      );
      tickets.add(ticket);
    }

    // Первая карта — сразу (без delayed), иначе кадр без карты после drop.
    futures.add(delay == Duration.zero ? launch() : Future<void>.delayed(delay, launch));
  }
  await Future.wait(futures);
  onTickets?.call(tickets);
  if (!keepAtEnd) {
    for (final t in tickets) {
      t.dismiss();
    }
  }
}

/// Глобальный прямоугольник виджета по [key], если он уже смонтирован.
Rect? globalRectOf(GlobalKey key) {
  final ctx = key.currentContext;
  if (ctx == null) return null;
  final box = ctx.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  final origin = box.localToGlobal(Offset.zero);
  return origin & box.size;
}

/// Точка внутри [rect] со смещением (для хаотичной биты).
Rect rectJitter(Rect base, Size cardSize, int seed, int index) {
  final rng = math.Random(seed * 31 + index * 17);
  final dx = (rng.nextDouble() - 0.5) * base.width * 0.7;
  final dy = (rng.nextDouble() - 0.5) * base.height * 0.55;
  final cx = base.center.dx + dx - cardSize.width / 2;
  final cy = base.center.dy + dy - cardSize.height / 2;
  return Rect.fromLTWH(cx, cy, cardSize.width, cardSize.height);
}

/// Масштаб карты при перетаскивании: чуть больше ближе к центру стола.
double dragScaleTowardCenter(Offset global, Size screenSize) {
  final center = Offset(screenSize.width / 2, screenSize.height * 0.40);
  final maxDist = screenSize.height * 0.48;
  final d = (global - center).distance;
  final t = (1.0 - (d / maxDist)).clamp(0.0, 1.0);
  // Не больше +9% — лёгкий акцент, без «раздувания».
  return 1.0 + 0.09 * Curves.easeOut.transform(t);
}
