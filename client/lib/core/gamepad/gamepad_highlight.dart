import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';

/// Обводка курсора геймпада вокруг кнопки, чата или карты.
/// Та же рамка, что у [GamepadFocusBlock] на главной: появляется сразу,
/// когда контроллер в списке устройств.
Widget wrapGamepadCursor({
  required Widget child,
  required bool highlighted,
  double radius = 12,
  double borderWidth = 2.2,
  GamepadHighlightShape shape = GamepadHighlightShape.roundedRect,
}) {
  return ListenableBuilder(
    listenable: GamepadService.instance.devices,
    builder: (context, _) {
      if (!highlighted || !gamepadConnected()) return child;
      return GamepadCursorOutline(
        radius: radius,
        borderWidth: borderWidth,
        shape: shape,
        child: child,
      );
    },
  );
}

/// Фиолетовая обводка со свечением — общая с [GamepadFocusBlock].
class GamepadCursorOutline extends StatelessWidget {
  const GamepadCursorOutline({
    super.key,
    required this.child,
    this.radius = 12,
    this.borderWidth = 2.2,
    this.shape = GamepadHighlightShape.roundedRect,
  });

  final Widget child;
  final double radius;
  final double borderWidth;
  final GamepadHighlightShape shape;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: GamepadFocusOutlinePainter(
                radius: radius,
                borderWidth: borderWidth,
                shape: shape,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
