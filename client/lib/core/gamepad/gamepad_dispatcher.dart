import 'package:multigames_client/core/gamepad/gamepad_action.dart';

typedef GamepadActionHandler = bool Function(GamepadAction action);

/// Стек обработчиков: партия перехватывает ввод раньше оболочки.
class GamepadDispatcher {
  GamepadDispatcher._();

  static final List<GamepadActionHandler> _stack = [];

  static void push(GamepadActionHandler handler) => _stack.add(handler);

  static void remove(GamepadActionHandler handler) => _stack.remove(handler);

  static bool dispatch(GamepadAction action) {
    for (var i = _stack.length - 1; i >= 0; i--) {
      if (_stack[i](action)) return true;
    }
    return false;
  }

  static void reset() => _stack.clear();
}
