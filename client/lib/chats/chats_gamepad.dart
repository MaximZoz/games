import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_glyph.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';

/// Вверх/вниз по списку чатов. Влево/вправо не двигают индекс.
int chatsListIndexAfterMove({
  required int index,
  required int count,
  required GamepadAction action,
}) {
  if (count <= 0) return 0;
  final prev = action == GamepadAction.up || action == GamepadAction.scrollUp;
  final next =
      action == GamepadAction.down || action == GamepadAction.scrollDown;
  if (prev) return index <= 0 ? 0 : index - 1;
  if (next) return index >= count - 1 ? count - 1 : index + 1;
  return index.clamp(0, count - 1);
}

bool chatsGamepadIsVertical(GamepadAction action) {
  return action == GamepadAction.up ||
      action == GamepadAction.down ||
      action == GamepadAction.scrollUp ||
      action == GamepadAction.scrollDown;
}

bool chatsGamepadIsHorizontal(GamepadAction action) {
  return action == GamepadAction.left ||
      action == GamepadAction.right ||
      action == GamepadAction.scrollLeft ||
      action == GamepadAction.scrollRight;
}

/// `null` — выделен сам чат; иначе индекс кнопки свайпа.
int? chatsActionIndexAfterMove({
  required int? current,
  required int actionCount,
  required GamepadAction action,
}) {
  if (actionCount <= 0) return null;
  if (!chatsGamepadIsHorizontal(action)) return current;
  final right = action == GamepadAction.right ||
      action == GamepadAction.scrollRight;
  if (current == null) {
    return right ? 0 : actionCount - 1;
  }
  if (right) {
    if (current >= actionCount - 1) return actionCount - 1;
    return current + 1;
  }
  if (current <= 0) return 0;
  return current - 1;
}

int chatsSwipeActionCount({required bool canBlock}) => canBlock ? 2 : 1;

/// LT у кнопки «Новый чат», как глиф у поиска друзей.
class ChatsGamepadLtHint extends StatelessWidget {
  const ChatsGamepadLtHint({
    super.key,
    required this.child,
    this.expandChild = false,
  });

  final Widget child;
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GamepadService.instance.devices,
      builder: (context, _) {
        if (!gamepadConnected()) return child;
        return Row(
          mainAxisSize: expandChild ? MainAxisSize.max : MainAxisSize.min,
          children: [
            const GamepadGlyph(action: GamepadAction.triggerL, size: 16),
            const SizedBox(width: 6),
            if (expandChild) Expanded(child: child) else child,
          ],
        );
      },
    );
  }
}
