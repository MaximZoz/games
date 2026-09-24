import 'package:multigames_client/core/gamepad/gamepad_action.dart';

typedef GamepadActionHandler = bool Function(GamepadAction action);

class _GamepadHandler {
  const _GamepadHandler(this.fn, {required this.exclusive});

  final GamepadActionHandler fn;
  final bool exclusive;
}

/// Стек обработчиков: партия перехватывает ввод раньше оболочки.
class GamepadDispatcher {
  GamepadDispatcher._();

  static final List<_GamepadHandler> _stack = [];

  static void push(GamepadActionHandler handler, {bool exclusive = false}) {
    _stack.add(_GamepadHandler(handler, exclusive: exclusive));
  }

  static void remove(GamepadActionHandler handler) {
    _stack.removeWhere((entry) => identical(entry.fn, handler));
  }

  static bool get hasExclusive => _stack.any((entry) => entry.exclusive);

  static bool dispatch(GamepadAction action) {
    for (var i = _stack.length - 1; i >= 0; i--) {
      if (_stack[i].fn(action)) return true;
    }
    return false;
  }

  static void reset() => _stack.clear();
}
