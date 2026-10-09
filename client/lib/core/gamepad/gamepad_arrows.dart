import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:multigames_client/core/gamepad/gamepad_keyboard.dart';

/// Стрелки, которыми левый стик/крест ходят по экранной клавиатуре.
bool isGamepadTextArrowKey(LogicalKeyboardKey key) {
  return key == LogicalKeyboardKey.arrowLeft ||
      key == LogicalKeyboardKey.arrowRight ||
      key == LogicalKeyboardKey.arrowUp ||
      key == LogicalKeyboardKey.arrowDown;
}

/// Пока открыта клавиатура геймпада, стрелки не двигают каретку в поле.
KeyEventResult handleGamepadFieldArrowKey(FocusNode node, KeyEvent event) {
  if (!GamepadKeyboardController.instance.visible) {
    return KeyEventResult.ignored;
  }
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
    return KeyEventResult.ignored;
  }
  if (!isGamepadTextArrowKey(event.logicalKey)) {
    return KeyEventResult.ignored;
  }
  return KeyEventResult.handled;
}

/// Ближе к [TextField], чем [DefaultTextEditingShortcuts] у [WidgetsApp].
final Map<ShortcutActivator, Intent> gamepadKeyboardTextShortcuts =
    <ShortcutActivator, Intent>{
  const SingleActivator(LogicalKeyboardKey.arrowLeft):
      const DoNothingAndStopPropagationTextIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowRight):
      const DoNothingAndStopPropagationTextIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowUp):
      const DoNothingAndStopPropagationTextIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowDown):
      const DoNothingAndStopPropagationTextIntent(),
};
