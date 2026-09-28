import 'package:multigames_client/core/gamepad/gamepad_action.dart';

typedef GamepadActionHandler = bool Function(GamepadAction action);

class _GamepadHandler {
  _GamepadHandler(this.fn, {required this.exclusive}) : id = _nextId++;

  static int _nextId = 1;

  final int id;
  final GamepadActionHandler fn;
  final bool exclusive;
}

/// Стек обработчиков: партия перехватывает ввод раньше оболочки.
class GamepadDispatcher {
  GamepadDispatcher._();

  static final List<_GamepadHandler> _stack = [];

  /// Возвращает токен для [remove] — tear-off метода сравнивать нельзя.
  static int push(GamepadActionHandler handler, {bool exclusive = false}) {
    final entry = _GamepadHandler(handler, exclusive: exclusive);
    _stack.add(entry);
    return entry.id;
  }

  static void remove(int id) {
    _stack.removeWhere((entry) => entry.id == id);
  }

  static bool get hasExclusive => _stack.any((entry) => entry.exclusive);

  static bool dispatch(GamepadAction action) {
    final snapshot = List<_GamepadHandler>.from(_stack);
    for (var i = snapshot.length - 1; i >= 0; i--) {
      if (snapshot[i].fn(action)) return true;
    }
    return false;
  }

  static void reset() {
    _stack.clear();
    _GamepadHandler._nextId = 1;
  }
}
