import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_chrome.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Живые [FocusNode] карточек — без `debugLabel` (в релизе его нет).
class GamepadFocusRegistry {
  GamepadFocusRegistry._();

  static final Set<FocusNode> _nodes = <FocusNode>{};

  static List<FocusNode> get nodes => List<FocusNode>.unmodifiable(_nodes);

  static void register(FocusNode node) => _nodes.add(node);

  static void unregister(FocusNode node) => _nodes.remove(node);

  @visibleForTesting
  static void reset() => _nodes.clear();
}

enum GamepadHighlightShape { roundedRect, circle }

/// Карточка/блок, по которому ходит геймпад: одна цель, обводка по рамке.
class GamepadFocusBlock extends StatefulWidget {
  const GamepadFocusBlock({
    super.key,
    required this.child,
    this.onActivate,
    this.radius = 22,
    this.borderWidth = 2,
    this.autofocus = false,
    this.focusable = true,
    this.shape = GamepadHighlightShape.roundedRect,
    this.chrome,
  });

  final Widget child;
  final VoidCallback? onActivate;
  final double radius;
  final double borderWidth;
  final bool autofocus;
  final bool focusable;
  final GamepadHighlightShape shape;
  final GamepadChromeSlot? chrome;

  static GamepadFocusScope? maybeOf(BuildContext context) {
    return context.findAncestorWidgetOfExactType<GamepadFocusScope>();
  }

  @override
  State<GamepadFocusBlock> createState() => _GamepadFocusBlockState();
}

class _GamepadFocusBlockState extends State<GamepadFocusBlock> {
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode(
      debugLabel: 'GamepadFocusBlock',
      canRequestFocus: widget.focusable,
      skipTraversal: !widget.focusable,
      descendantsAreFocusable: false,
      descendantsAreTraversable: false,
    );
    GamepadFocusRegistry.register(_focus);
    final chrome = widget.chrome;
    if (chrome != null) {
      GamepadChromeRegistry.register(chrome, _focus);
    }
  }

  @override
  void didUpdateWidget(GamepadFocusBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _focus.canRequestFocus = widget.focusable;
    _focus.skipTraversal = !widget.focusable;
    if (oldWidget.chrome != widget.chrome) {
      if (oldWidget.chrome != null) {
        GamepadChromeRegistry.unregister(oldWidget.chrome!, _focus);
      }
      if (widget.chrome != null) {
        GamepadChromeRegistry.register(widget.chrome!, _focus);
      }
    }
  }

  @override
  void dispose() {
    if (widget.chrome != null) {
      GamepadChromeRegistry.unregister(widget.chrome!, _focus);
    }
    GamepadFocusRegistry.unregister(_focus);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GamepadFocusScope(
      onActivate: widget.onActivate,
      child: Focus(
        focusNode: _focus,
        autofocus: widget.autofocus,
        canRequestFocus: widget.focusable,
        skipTraversal: !widget.focusable,
        descendantsAreFocusable: false,
        descendantsAreTraversable: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([
            GamepadService.instance.devices,
            GamepadService.instance.activityTick,
            _focus,
          ]),
          builder: (context, _) {
            final show = _focus.hasPrimaryFocus && gamepadConnected();
            return Stack(
              clipBehavior: Clip.none,
              children: [
                widget.child,
                if (show)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _GamepadFocusOutlinePainter(
                          radius: widget.radius,
                          borderWidth: widget.borderWidth,
                          shape: widget.shape,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Обводка по контуру рамки: один RRect, без стыков сторон BoxDecoration.
class _GamepadFocusOutlinePainter extends CustomPainter {
  const _GamepadFocusOutlinePainter({
    required this.radius,
    required this.borderWidth,
    required this.shape,
  });

  final double radius;
  final double borderWidth;
  final GamepadHighlightShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentStart
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final inset = borderWidth / 2;
    if (shape == GamepadHighlightShape.circle) {
      final r = math.max(0.0, math.min(size.width, size.height) / 2 - inset);
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), r, paint);
      return;
    }
    final corner = math.max(0.0, radius - inset);
    final rrect = RRect.fromLTRBR(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
      Radius.circular(corner),
    );
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GamepadFocusOutlinePainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.shape != shape;
  }
}

class GamepadFocusScope extends InheritedWidget {
  const GamepadFocusScope({
    super.key,
    required this.onActivate,
    required super.child,
  });

  final VoidCallback? onActivate;

  @override
  bool updateShouldNotify(GamepadFocusScope oldWidget) {
    return onActivate != oldWidget.onActivate;
  }
}
