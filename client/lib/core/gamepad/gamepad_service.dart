import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_keyboard.dart';
import 'package:multigames_client/core/gamepad/gamepad_mapping.dart';
import 'package:multigames_client/core/gamepad/gamepad_poller.dart';

/// Глобальный ввод с геймпада и клавиш, которые контроллер эмулирует.
class GamepadService {
  GamepadService({GamepadPoller? poller})
      : _poller = poller ?? createGamepadPoller();

  static final GamepadService instance = GamepadService();

  final GamepadPoller _poller;
  final ValueNotifier<List<GamepadDevice>> devices =
      ValueNotifier<List<GamepadDevice>>(const []);
  final ValueNotifier<int> activityTick = ValueNotifier<int>(0);
  final StreamController<GamepadActionEvent> _events =
      StreamController<GamepadActionEvent>.broadcast();

  Stream<GamepadActionEvent> get events => _events.stream;

  DateTime? lastActiveAt;
  bool _running = false;
  bool _keyHandlerAttached = false;

  static const recentWindow = Duration(minutes: 10);

  bool get isRecentlyActive {
    final at = lastActiveAt;
    if (at == null) return false;
    return DateTime.now().difference(at) < recentWindow;
  }

  void start() {
    if (_running) return;
    _running = true;
    _poller.start(
      onEvent: _emit,
      onDevices: (next) => devices.value = List<GamepadDevice>.from(next),
    );
    if (!_keyHandlerAttached) {
      HardwareKeyboard.instance.addHandler(_onKey);
      _keyHandlerAttached = true;
    }
  }

  void stop() {
    if (!_running && !_keyHandlerAttached) return;
    _running = false;
    _poller.stop();
    if (_keyHandlerAttached) {
      HardwareKeyboard.instance.removeHandler(_onKey);
      _keyHandlerAttached = false;
    }
  }

  void markActive() {
    lastActiveAt = DateTime.now();
    activityTick.value++;
  }

  /// Для тестов и отладки.
  @visibleForTesting
  void emit(GamepadAction action, {String source = 'test'}) {
    _emit(GamepadActionEvent(action: action, source: source));
  }

  @visibleForTesting
  void setDevicesForTest(List<GamepadDevice> next) {
    devices.value = List<GamepadDevice>.from(next);
  }

  @visibleForTesting
  void reset() {
    stop();
    devices.value = const [];
    lastActiveAt = null;
    activityTick.value = 0;
    GamepadKeyboardController.instance.hide();
  }

  void _emit(GamepadActionEvent event) {
    markActive();
    if (!_events.hasListener) return;
    _events.add(event);
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    final action = gamepadActionFromKey(event.logicalKey);
    if (action == null) return false;
    if (isEditableTextFocused()) {
      if (action == GamepadAction.cancel && event is KeyDownEvent) {
        FocusManager.instance.primaryFocus?.unfocus();
        return true;
      }
      return false;
    }
    if (event is KeyRepeatEvent && !action.isDirection) return false;
    _emit(
      GamepadActionEvent(
        action: action,
        source: 'key',
        deviceName: 'Keyboard',
      ),
    );
    return true;
  }
}

bool isEditableTextFocused() {
  final node = FocusManager.instance.primaryFocus;
  final ctx = node?.context;
  if (ctx == null) return false;
  if (ctx.widget is EditableText) return true;
  return ctx.findAncestorStateOfType<EditableTextState>() != null;
}
