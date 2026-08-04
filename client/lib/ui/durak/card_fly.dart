import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';

/// Плавный полёт карты из [from] в [to] поверх всего UI.
Future<void> playCardFlyAnimation({
  required BuildContext context,
  required PlayingCard card,
  required Size cardSize,
  required Rect from,
  required Rect to,
  Duration duration = const Duration(milliseconds: 380),
  bool faceDown = false,
  double beginAngle = 0,
  double endAngle = 0,
}) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final completer = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) {
      return IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: duration,
          curve: Curves.easeInOutCubic,
          onEnd: () {
            entry.remove();
            if (!completer.isCompleted) completer.complete();
          },
          builder: (context, t, _) {
            final left = from.left + (to.left - from.left) * t;
            final top = from.top + (to.top - from.top) * t;
            final scale = 1.08 - 0.08 * t;
            final angle = beginAngle + (endAngle - beginAngle) * t;
            // Лёгкая дуга траектории.
            final midLift = -40.0 * math.sin(math.pi * t);
            return Stack(
              children: [
                Positioned(
                  left: left,
                  top: top + midLift,
                  child: Transform.rotate(
                    angle: angle,
                    child: Transform.scale(
                      scale: scale,
                      child: faceDown
                          ? CardBackWidget(size: cardSize, elevated: true)
                          : PlayingCardWidget(
                              card: card,
                              size: cardSize,
                              elevated: true,
                              highlighted: true,
                            ),
                    ),
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
  return completer.future;
}

/// Несколько карт летят с небольшим сдвигом по времени.
Future<void> playCardsFlyAnimation({
  required BuildContext context,
  required List<PlayingCard> cards,
  required Size cardSize,
  required List<Rect> froms,
  required List<Rect> tos,
  Duration duration = const Duration(milliseconds: 380),
  Duration stagger = const Duration(milliseconds: 55),
  bool faceDown = false,
  List<double>? endAngles,
}) async {
  if (cards.isEmpty) return;
  final futures = <Future<void>>[];
  for (var i = 0; i < cards.length; i++) {
    final delay = stagger * i;
    futures.add(Future<void>.delayed(delay, () {
      if (!context.mounted) return Future<void>.value();
      final from = froms[i.clamp(0, froms.length - 1)];
      final to = tos[i.clamp(0, tos.length - 1)];
      final endA = endAngles != null && i < endAngles.length ? endAngles[i] : 0.0;
      return playCardFlyAnimation(
        context: context,
        card: cards[i],
        cardSize: cardSize,
        from: from,
        to: to,
        duration: duration,
        faceDown: faceDown,
        endAngle: endA,
      );
    }));
  }
  await Future.wait(futures);
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
