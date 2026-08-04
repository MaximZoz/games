import 'dart:async';

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
            return Stack(
              children: [
                Positioned(
                  left: left,
                  top: top,
                  child: Transform.scale(
                    scale: scale,
                    child: PlayingCardWidget(
                      card: card,
                      size: cardSize,
                      elevated: true,
                      highlighted: true,
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

/// Глобальный прямоугольник виджета по [key], если он уже смонтирован.
Rect? globalRectOf(GlobalKey key) {
  final ctx = key.currentContext;
  if (ctx == null) return null;
  final box = ctx.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  final origin = box.localToGlobal(Offset.zero);
  return origin & box.size;
}
