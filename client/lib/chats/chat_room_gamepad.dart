import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_glyph.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';

/// Полоса, по которой ходит геймпад в комнате чата.
enum ChatRoomGamepadZone { toolbar, messages, composer }

/// Визуально вверх — к более старым (`index` меньше), вниз — к новым.
int chatRoomMessageIndexAfterMove({
  required int index,
  required int count,
  required GamepadAction action,
}) {
  if (count <= 0) return 0;
  if (action == GamepadAction.up) return index <= 0 ? 0 : index - 1;
  if (action == GamepadAction.down) {
    return index >= count - 1 ? count - 1 : index + 1;
  }
  return index.clamp(0, count - 1);
}

/// Стик вверх/вниз с шапки или композера возвращает в ленту.
bool chatRoomStickReturnsToMessages({
  required ChatRoomGamepadZone zone,
  required GamepadAction action,
}) {
  if (zone == ChatRoomGamepadZone.messages) return false;
  return action == GamepadAction.up ||
      action == GamepadAction.down ||
      action == GamepadAction.scrollUp ||
      action == GamepadAction.scrollDown;
}

bool chatRoomGoesToToolbar(GamepadAction action) =>
    action == GamepadAction.actionY;

bool chatRoomGoesToComposer(GamepadAction action) =>
    action == GamepadAction.actionX;

/// Шаг правого стика: одно окно, индекс не зацикливается.
int chatRoomPageIndex({
  required int index,
  required int count,
  required int step,
  required bool visualUp,
}) {
  if (count <= 0) return 0;
  final delta = visualUp ? -step : step;
  final next = index + delta;
  if (next < 0) return 0;
  if (next >= count) return count - 1;
  return next;
}

int chatRoomPageStep({
  required double viewport,
  required double itemExtent,
}) {
  if (viewport <= 0 || itemExtent <= 0) return 1;
  return (viewport / itemExtent).floor().clamp(1, 20);
}

bool chatRoomHorizontalIsReply(GamepadAction action) {
  return action == GamepadAction.left ||
      action == GamepadAction.right ||
      action == GamepadAction.scrollLeft ||
      action == GamepadAction.scrollRight;
}

/// В меню сообщения стик и A листают/выбирают; любая другая кнопка закрывает.
bool chatRoomActionMenuKeepsOpen(GamepadAction action) {
  return action == GamepadAction.confirm || action.isDirection;
}

const double kChatRoomEmojiSheetCollapsed = 0.14;
const double kChatRoomEmojiSheetMid = 0.55;
const double kChatRoomEmojiSheetMax = 0.92;

/// Правый стик: раскрыть / сузить панель смайлов.
double chatRoomEmojiSheetSizeAfterScroll({
  required double current,
  required bool expand,
}) {
  if (expand) {
    if (current < kChatRoomEmojiSheetMid - 0.04) {
      return kChatRoomEmojiSheetMid;
    }
    return kChatRoomEmojiSheetMax;
  }
  if (current > kChatRoomEmojiSheetMid + 0.04) {
    return kChatRoomEmojiSheetMid;
  }
  return kChatRoomEmojiSheetCollapsed;
}

/// Глиф Y / X (или △ / □) на верхней и нижней панели.
class ChatRoomGamepadLaneHint extends StatelessWidget {
  const ChatRoomGamepadLaneHint({
    super.key,
    required this.action,
    required this.child,
    this.leading = true,
  });

  final GamepadAction action;
  final Widget child;
  final bool leading;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GamepadService.instance.devices,
      builder: (context, _) {
        if (!gamepadConnected()) return child;
        final glyph = Padding(
          padding: leading
              ? const EdgeInsets.only(right: 6)
              : const EdgeInsets.only(left: 6),
          child: GamepadGlyph(action: action, size: 16),
        );
        return Row(
          children: [
            if (leading) glyph,
            Expanded(child: child),
            if (!leading) glyph,
          ],
        );
      },
    );
  }
}
