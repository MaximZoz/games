import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_glyph.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/core/gamepad/gamepad_tab_sticks.dart';

/// Попап перехватывает стик: вкладки друзей не листаем.
bool friendsGamepadAllowsTabScroll({
  required bool popupOpen,
  required bool exclusive,
  bool routeCovered = false,
}) {
  return !popupOpen && !exclusive && !routeCovered;
}

/// Правый стик: предыдущая / следующая вкладка друзей.
int friendsTabIndexAfterScroll({
  required int index,
  required int length,
  required GamepadAction action,
}) {
  if (length <= 0) return 0;
  if (length == 1) return 0;
  final prev =
      action == GamepadAction.scrollLeft || action == GamepadAction.scrollUp;
  final next =
      action == GamepadAction.scrollRight || action == GamepadAction.scrollDown;
  if (prev) return (index - 1 + length) % length;
  if (next) return (index + 1) % length;
  return index.clamp(0, length - 1);
}

/// Вверх/вниз по карточкам. В сетке шаг — число колонок.
int friendsCardIndexAfterMove({
  required int index,
  required int count,
  required int columns,
  required GamepadAction action,
}) {
  if (count <= 0) return 0;
  final cols = columns < 1 ? 1 : columns;
  final delta = action == GamepadAction.up
      ? -cols
      : action == GamepadAction.down
          ? cols
          : 0;
  if (delta == 0) return index.clamp(0, count - 1);
  final next = index + delta;
  if (next < 0) return 0;
  if (next >= count) return count - 1;
  return next;
}

/// Влево/вправо по кнопкам карточки. `null` — рамка всей карточки.
int? friendsActionIndexAfterMove({
  required int? current,
  required int actionCount,
  required GamepadAction action,
}) {
  if (actionCount <= 0) return null;
  if (action != GamepadAction.left && action != GamepadAction.right) {
    return current;
  }
  if (current == null) {
    return action == GamepadAction.left ? actionCount - 1 : 0;
  }
  if (action == GamepadAction.right) {
    if (current >= actionCount - 1) return actionCount - 1;
    return current + 1;
  }
  if (current <= 0) return 0;
  return current - 1;
}

/// Правый стик по краям вкладок друзей — как LB/RB у нижнего меню.
class FriendsGamepadTabSticks extends GamepadTabSticks {
  const FriendsGamepadTabSticks({super.key, required super.child});
}

/// LT-подпись у поиска, как глиф у баланса монет.
class FriendsGamepadLtHint extends StatelessWidget {
  const FriendsGamepadLtHint({
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
