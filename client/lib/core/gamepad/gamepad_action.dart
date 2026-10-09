/// Семантические действия геймпада (Xbox / стандартный W3C mapping).
enum GamepadAction {
  up,
  down,
  left,
  right,
  scrollUp,
  scrollDown,
  scrollLeft,
  scrollRight,
  confirm,
  cancel,
  actionX,
  actionY,
  shoulderL,
  shoulderR,
  triggerL,
  triggerR,
  menu,
  select,
}

extension GamepadActionX on GamepadAction {
  bool get isDirection =>
      this == GamepadAction.up ||
      this == GamepadAction.down ||
      this == GamepadAction.left ||
      this == GamepadAction.right;

  bool get isScroll =>
      this == GamepadAction.scrollUp ||
      this == GamepadAction.scrollDown ||
      this == GamepadAction.scrollLeft ||
      this == GamepadAction.scrollRight;
}

/// Событие после антидребезга и repeat.
class GamepadActionEvent {
  const GamepadActionEvent({
    required this.action,
    required this.source,
    this.deviceId = '',
    this.deviceName = '',
  });

  final GamepadAction action;
  final String source;
  final String deviceId;
  final String deviceName;
}

class GamepadDevice {
  const GamepadDevice({
    required this.id,
    required this.name,
    required this.index,
  });

  final String id;
  final String name;
  final int index;

  @override
  bool operator ==(Object other) =>
      other is GamepadDevice &&
      other.id == id &&
      other.name == name &&
      other.index == index;

  @override
  int get hashCode => Object.hash(id, name, index);
}
