import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';

/// Стик и стрелки только скроллят; любая кнопка закрывает всплывашку.
bool gamepadScrollDismissCloses(GamepadAction action) {
  return !action.isDirection && !action.isScroll;
}

/// Правила / статистика: правый стик листает текст, кнопка закрывает.
class GamepadScrollDismissScope extends StatelessWidget {
  const GamepadScrollDismissScope({
    super.key,
    required this.onClose,
    required this.child,
  });

  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GamepadScope(
      exclusive: true,
      onAction: (action) {
        if (action.isDirection || action.isScroll) {
          handleGamepadUiAction(context, action);
          final back = action == GamepadAction.up ||
              action == GamepadAction.left ||
              action == GamepadAction.scrollUp ||
              action == GamepadAction.scrollLeft;
          scrollGamepadByPage(back ? -1 : 1, context: context);
          return true;
        }
        onClose();
        return true;
      },
      child: child,
    );
  }
}

/// Обернуть диалог: закрытие любой кнопкой, скролл стиком.
Widget wrapGamepadScrollDismissDialog({
  required BuildContext dialogContext,
  required Widget child,
}) {
  return GamepadScrollDismissScope(
    onClose: () {
      final nav = Navigator.of(dialogContext);
      if (nav.canPop()) nav.pop();
    },
    child: child,
  );
}
