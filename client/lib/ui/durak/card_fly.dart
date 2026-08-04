import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';

/// Билет на полёт: после [done] при [keepAtEnd] карта остаётся, пока не [dismiss].
class CardFlyTicket {
  CardFlyTicket._(this._entry);
  final OverlayEntry? _entry;
  bool _dismissed = false;

  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _entry?.remove();
  }
}

/// Плавный полёт карты из [from] в [to] поверх всего UI.
/// [flipToFace] — переворот рубашка→лицо к концу полёта (добор в руку).
/// [beginScale]/[endScale] — размер относительно [cardSize].
/// [arcLift] — высота дуги (0 = прямая траектория без подскока).
Future<CardFlyTicket> playCardFlyAnimation({
  required BuildContext context,
  required PlayingCard card,
  required Size cardSize,
  required Rect from,
  required Rect to,
  Duration duration = const Duration(milliseconds: 420),
  Curve curve = Curves.easeInOutCubic,
  bool faceDown = false,
  bool flipToFace = false,
  double beginAngle = 0,
  double endAngle = 0,
  double beginScale = 1.0,
  double endScale = 1.0,
  double arcLift = 0,
  bool keepAtEnd = false,
}) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return CardFlyTicket._(null);

  final completer = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) {
      return IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: duration,
          curve: curve,
          onEnd: () {
            if (!keepAtEnd) entry.remove();
            if (!completer.isCompleted) completer.complete();
          },
          builder: (context, t, _) {
            final scale = beginScale + (endScale - beginScale) * t;
            final w = cardSize.width * scale;
            final h = cardSize.height * scale;
            final cx = from.center.dx + (to.center.dx - from.center.dx) * t;
            final cy = from.center.dy + (to.center.dy - from.center.dy) * t;
            final angle = beginAngle + (endAngle - beginAngle) * t;
            final midLift =
                arcLift == 0 ? 0.0 : -arcLift * math.sin(math.pi * t);
            Widget face;
            if (flipToFace) {
              final flipT = t < 0.5 ? t * 2 : (1 - t) * 2;
              final showBack = t < 0.5;
              face = Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(flipT * math.pi / 2),
                child: showBack || faceDown
                    ? CardBackWidget(size: cardSize, elevated: true)
                    : PlayingCardWidget(
                        card: card,
                        size: cardSize,
                        elevated: true,
                        highlighted: true,
                      ),
              );
            } else {
              face = faceDown
                  ? CardBackWidget(size: cardSize, elevated: true)
                  : PlayingCardWidget(
                      card: card,
                      size: cardSize,
                      elevated: true,
                      highlighted: t < 0.92,
                    );
            }
            return Stack(
              children: [
                Positioned(
                  left: cx - w / 2,
                  top: cy - h / 2 + midLift,
                  width: w,
                  height: h,
                  child: Transform.rotate(
                    angle: angle,
                    child: FittedBox(fit: BoxFit.fill, child: face),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
  overlay.insert(entry);
  await completer.future;
  return CardFlyTicket._(keepAtEnd ? entry : null);
}

/// Несколько карт летят с небольшим сдвигом по времени.
Future<void> playCardsFlyAnimation({
  required BuildContext context,
  required List<PlayingCard> cards,
  required Size cardSize,
  required List<Rect> froms,
  required List<Rect> tos,
  Duration duration = const Duration(milliseconds: 420),
  Duration stagger = const Duration(milliseconds: 45),
  Curve curve = Curves.easeInOutCubic,
  bool faceDown = false,
  List<double>? endAngles,
  double beginScale = 1.0,
  double endScale = 1.0,
  double arcLift = 0,
  bool keepAtEnd = false,
  void Function(List<CardFlyTicket> tickets)? onTickets,
}) async {
  if (cards.isEmpty) return;
  final tickets = <CardFlyTicket>[];
  final futures = <Future<void>>[];
  for (var i = 0; i < cards.length; i++) {
    final delay = stagger * i;
    futures.add(Future<void>.delayed(delay, () async {
      if (!context.mounted) return;
      final from = froms[i.clamp(0, froms.length - 1)];
      final to = tos[i.clamp(0, tos.length - 1)];
      final endA = endAngles != null && i < endAngles.length ? endAngles[i] : 0.0;
      final ticket = await playCardFlyAnimation(
        context: context,
        card: cards[i],
        cardSize: cardSize,
        from: from,
        to: to,
        duration: duration,
        curve: curve,
        faceDown: faceDown,
        flipToFace: faceDown,
        endAngle: endA,
        beginScale: beginScale,
        endScale: endScale,
        arcLift: arcLift,
        keepAtEnd: keepAtEnd,
      );
      tickets.add(ticket);
    }));
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
