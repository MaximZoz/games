import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';

/// Стик и стрелки листают фото; любая кнопка закрывает, как крестик.
int profileGalleryIndexAfterMove({
  required int index,
  required int count,
  required GamepadAction action,
}) {
  if (count <= 1) return 0;
  final back = action == GamepadAction.left ||
      action == GamepadAction.up ||
      action == GamepadAction.scrollLeft ||
      action == GamepadAction.scrollUp;
  final forward = action == GamepadAction.right ||
      action == GamepadAction.down ||
      action == GamepadAction.scrollRight ||
      action == GamepadAction.scrollDown;
  if (back) return (index - 1).clamp(0, count - 1);
  if (forward) return (index + 1).clamp(0, count - 1);
  return index.clamp(0, count - 1);
}

bool profileGalleryActionCloses(GamepadAction action) {
  return !action.isDirection && !action.isScroll;
}

/// Галерея забирает ввод: стик листает, кнопки вызывают крестик.
class ProfileGalleryGamepadScope extends StatelessWidget {
  const ProfileGalleryGamepadScope({
    super.key,
    required this.onClose,
    required this.onStep,
    required this.child,
  });

  final VoidCallback onClose;
  final ValueChanged<int> onStep;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GamepadScope(
      exclusive: true,
      onAction: (action) {
        if (action.isDirection || action.isScroll) {
          final back = action == GamepadAction.left ||
              action == GamepadAction.up ||
              action == GamepadAction.scrollLeft ||
              action == GamepadAction.scrollUp;
          onStep(back ? -1 : 1);
          return true;
        }
        onClose();
        return true;
      },
      child: child,
    );
  }
}
