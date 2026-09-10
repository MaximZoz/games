import 'package:multigames_client/core/gamepad/gamepad_action.dart';

/// Edge + hold-repeat для креста и стика (Gamepad API сам не повторяет).
class GamepadRepeatTracker {
  GamepadRepeatTracker({
    this.initialDelay = const Duration(milliseconds: 280),
    this.repeatEvery = const Duration(milliseconds: 130),
  });

  final Duration initialDelay;
  final Duration repeatEvery;

  GamepadAction? _held;
  DateTime? _heldSince;
  DateTime? _lastEmit;

  /// Возвращает действия, которые нужно отдать в этом кадре.
  List<GamepadAction> tick({
    required Set<GamepadAction> heldDirections,
    required Set<GamepadAction> pressedNow,
    required DateTime now,
  }) {
    final out = <GamepadAction>[];
    for (final action in pressedNow) {
      if (!action.isDirection) {
        out.add(action);
      }
    }

    final current = heldDirections.length == 1 ? heldDirections.single : null;
    if (current == null) {
      _held = null;
      _heldSince = null;
      _lastEmit = null;
      return out;
    }

    if (_held != current) {
      _held = current;
      _heldSince = now;
      _lastEmit = now;
      out.add(current);
      return out;
    }

    final since = _heldSince;
    final last = _lastEmit;
    if (since == null || last == null) return out;
    if (now.difference(since) < initialDelay) return out;
    if (now.difference(last) < repeatEvery) return out;
    _lastEmit = now;
    out.add(current);
    return out;
  }

  void reset() {
    _held = null;
    _heldSince = null;
    _lastEmit = null;
  }
}
