import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:multigames_client/core/sfx.dart';
import 'package:multigames_client/games/uno/uno_card.dart';
import 'package:multigames_client/ui/uno/uno_card_widget.dart';
import 'package:multigames_client/ui/widgets/game_fly_overlay.dart';

const Curve kUnoFlyCurve = Curves.easeOutQuint;

class UnoCardFlyTicket {
  UnoCardFlyTicket._(this._entry, this._controller, this._animation);

  final OverlayEntry? _entry;
  final AnimationController? _controller;
  final CurvedAnimation? _animation;
  bool _dismissed = false;

  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    GameFlyOverlay.remove(_entry);
    _animation?.dispose();
    _controller?.dispose();
  }
}

Future<UnoCardFlyTicket> playUnoCardFlyAnimation({
  required BuildContext context,
  required UnoCard card,
  required Size cardSize,
  required Rect from,
  required Rect to,
  Duration duration = const Duration(milliseconds: 390),
  Curve curve = kUnoFlyCurve,
  bool faceDown = false,
  bool flipToFace = false,
  double beginAngle = 0,
  double endAngle = 0,
  double beginScale = 1,
  double endScale = 1,
  double arcLift = 0,
  bool keepAtEnd = false,
}) async {
  if (!context.mounted || !TickerMode.of(context)) {
    return UnoCardFlyTicket._(null, null, null);
  }
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return UnoCardFlyTicket._(null, null, null);
  Sfx.play(
    faceDown
        ? SfxId.cardDraw
        : (card.kind == UnoCardKind.number ? SfxId.cardPlay : SfxId.cardSpecial),
  );

  final controller = AnimationController(
    vsync: _UnoFlyTicker(),
    duration: duration,
  );
  final animation = CurvedAnimation(parent: controller, curve: curve);
  late final OverlayEntry entry;
  entry = GameFlyOverlay.insert(overlay, (_) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        child: _UnoFlyFace(
          card: card,
          cardSize: cardSize,
          faceDown: faceDown,
          flipToFace: flipToFace,
          animation: animation,
        ),
        builder: (_, child) {
          final t = animation.value;
          final center = Offset(
            lerpDouble(from.center.dx, to.center.dx, t)!,
            lerpDouble(from.center.dy, to.center.dy, t)! -
                arcLift * math.sin(math.pi * t),
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: center.dx - cardSize.width / 2,
                top: center.dy - cardSize.height / 2,
                width: cardSize.width,
                height: cardSize.height,
                child: Transform.rotate(
                  angle: lerpDouble(beginAngle, endAngle, t)!,
                  child: Transform.scale(
                    scale: lerpDouble(beginScale, endScale, t)!,
                    filterQuality: FilterQuality.medium,
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  });

  try {
    await controller.forward();
  } catch (_) {}
  if (!keepAtEnd) {
    GameFlyOverlay.remove(entry);
    animation.dispose();
    controller.dispose();
    return UnoCardFlyTicket._(null, null, null);
  }
  return UnoCardFlyTicket._(entry, controller, animation);
}

class _UnoFlyFace extends StatelessWidget {
  const _UnoFlyFace({
    required this.card,
    required this.cardSize,
    required this.faceDown,
    required this.flipToFace,
    required this.animation,
  });

  final UnoCard card;
  final Size cardSize;
  final bool faceDown;
  final bool flipToFace;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    if (!flipToFace) {
      return UnoCardWidget(
        card: card,
        size: cardSize,
        faceDown: faceDown,
      );
    }
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = animation.value;
        final flip = t < 0.5 ? t * 2 : (1 - t) * 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(flip * math.pi / 2),
          child: UnoCardWidget(
            card: card,
            size: cardSize,
            faceDown: t < 0.5,
          ),
        );
      },
    );
  }
}

class _UnoFlyTicker extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
