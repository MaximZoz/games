import 'package:multigames_client/core/gamepad/gamepad_action.dart';

/// Курсор по сетке: крестики-нолики, морской бой, шашки.
class GamepadGridCursor {
  GamepadGridCursor({
    required this.columns,
    required this.count,
    int index = 0,
  }) : index = count <= 0 ? 0 : index.clamp(0, count - 1);

  int columns;
  int count;
  int index;

  void configure({required int columns, required int count}) {
    this.columns = columns;
    this.count = count;
    if (count <= 0) {
      index = 0;
      return;
    }
    index = index.clamp(0, count - 1);
  }

  bool move(GamepadAction action, {bool flip = false}) {
    if (count <= 0 || columns <= 0) return false;
    final mapped = flip ? _flip(action) : action;
    if (!mapped.isDirection) return false;
    final row = index ~/ columns;
    final col = index % columns;
    final rows = (count + columns - 1) ~/ columns;
    final nextRow = switch (mapped) {
      GamepadAction.up => row - 1,
      GamepadAction.down => row + 1,
      _ => row,
    };
    final nextCol = switch (mapped) {
      GamepadAction.left => col - 1,
      GamepadAction.right => col + 1,
      _ => col,
    };
    if (nextRow < 0 ||
        nextCol < 0 ||
        nextRow >= rows ||
        nextCol >= columns) {
      return false;
    }
    final next = nextRow * columns + nextCol;
    if (next < 0 || next >= count || next == index) return false;
    index = next;
    return true;
  }

  static GamepadAction _flip(GamepadAction action) {
    switch (action) {
      case GamepadAction.up:
        return GamepadAction.down;
      case GamepadAction.down:
        return GamepadAction.up;
      case GamepadAction.left:
        return GamepadAction.right;
      case GamepadAction.right:
        return GamepadAction.left;
      default:
        return action;
    }
  }
}

/// Цикл по списку (рука карт, кнопки покера).
int cycleIndex(int index, int count, GamepadAction action) {
  if (count <= 0) return 0;
  if (action == GamepadAction.left || action == GamepadAction.up) {
    return (index - 1 + count) % count;
  }
  if (action == GamepadAction.right || action == GamepadAction.down) {
    return (index + 1) % count;
  }
  return index.clamp(0, count - 1);
}
