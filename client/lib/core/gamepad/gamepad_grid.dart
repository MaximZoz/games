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
    var nextRow = row;
    var nextCol = col;
    switch (mapped) {
      case GamepadAction.up:
        nextRow = row - 1;
      case GamepadAction.down:
        nextRow = row + 1;
      case GamepadAction.left:
        nextCol = col - 1;
      case GamepadAction.right:
        nextCol = col + 1;
      default:
        return false;
    }
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
