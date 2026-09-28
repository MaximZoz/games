import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_keyboard.dart';
import 'package:multigames_client/core/gamepad/gamepad_mapping.dart';
import 'package:multigames_client/core/gamepad/gamepad_native.dart';
import 'package:multigames_client/core/gamepad/gamepad_poller.dart';
import 'package:multigames_client/core/gamepad/gamepad_visibility.dart';

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
  Timer? _nativePoll;
  bool _nativePollScheduled = false;
  AndroidGamepadBridge? _androidBridge;
  GamepadAction? _lastEmitted;
  DateTime? _lastEmittedAt;

  static const recentWindow = Duration(minutes: 10);
  static const keyPadId = 'key-pad';

  /// В виджетах-тестах выключаем, чтобы не оставлять периодический Timer.
  @visibleForTesting
  static bool debugPollNative = true;

  bool get isRunning => _running;

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
    _nativePoll?.cancel();
    _nativePoll = null;
    if (debugPollNative &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      _androidBridge ??= AndroidGamepadBridge(
        onEvent: _emit,
        onDevices: (next) {
          if (next.isNotEmpty) devices.value = List<GamepadDevice>.from(next);
        },
      );
      _androidBridge?.start();
      _nativePoll = Timer.periodic(const Duration(seconds: 2), (_) {
        unawaited(_refreshNativeDevices());
      });
      unawaited(_refreshNativeDevices());
    }
  }

  void stop() {
    if (!_running && !_keyHandlerAttached) return;
    _running = false;
    _nativePoll?.cancel();
    _nativePoll = null;
    _nativePollScheduled = false;
    _androidBridge?.stop();
    _androidBridge = null;
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
    _lastEmitted = null;
    _lastEmittedAt = null;
    debugPollNative = true;
    GamepadKeyboardController.instance.hide();
  }

  void _emit(GamepadActionEvent event) {
    markActive();
    final now = DateTime.now();
    final lastAt = _lastEmittedAt;
    if (lastAt != null &&
        _lastEmitted == event.action &&
        now.difference(lastAt) < const Duration(milliseconds: 28)) {
      return;
    }
    _lastEmitted = event.action;
    _lastEmittedAt = now;
    if (!_events.hasListener) return;
    _events.add(event);
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    final action = gamepadActionFromKey(event.logicalKey);
    if (action == null) return false;
    final shoulder = action == GamepadAction.shoulderL ||
        action == GamepadAction.shoulderR;
    // Плечи всегда листают вкладки — даже если фокус застрял в поле.
    if (!shoulder && isEditableTextFocused()) {
      if (action == GamepadAction.cancel && event is KeyDownEvent) {
        FocusManager.instance.primaryFocus?.unfocus();
        return true;
      }
      return false;
    }
    if (event is KeyRepeatEvent && !action.isDirection) return false;
    unfocusOffstagePrimaryFocus();
    final fromPad = isDedicatedGamepadKey(event.logicalKey);
    // D-pad на Android приходит как стрелки — без этого обводка не вспыхнет.
    if (fromPad || action.isDirection || shoulder) {
      _rememberKeyGamepad();
    }
    if (fromPad) {
      unawaited(_refreshNativeDevices());
    }
    _emit(
      GamepadActionEvent(
        action: action,
        source: fromPad ? 'pad' : 'key',
        deviceName: fromPad ? 'Gamepad' : 'Keyboard',
      ),
    );
    return true;
  }

  void _rememberKeyGamepad() {
    if (devices.value.isNotEmpty) return;
    devices.value = const [
      GamepadDevice(id: keyPadId, name: 'Gamepad', index: 0),
    ];
  }

  Future<void> _refreshNativeDevices() async {
    if (!_running || _nativePollScheduled) return;
    _nativePollScheduled = true;
    try {
      final listed = await listNativeGamepads();
      if (!_running) return;
      if (listed.isNotEmpty) {
        if (!_sameDevices(devices.value, listed)) {
          devices.value = listed;
        }
        return;
      }
      if (kIsWeb) return;
      final current = devices.value;
      if (current.isEmpty) return;
      final onlyKey = current.every((d) => d.id == keyPadId);
      if (onlyKey && isRecentlyActive) return;
      if (onlyKey || current.any((d) => d.id.startsWith('android-'))) {
        devices.value = const [];
      }
    } finally {
      _nativePollScheduled = false;
    }
  }

  static bool _sameDevices(List<GamepadDevice> a, List<GamepadDevice> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Для тестов: кнопка геймпада без полного KeyEvent.
  @visibleForTesting
  void noteDedicatedGamepadKey() {
    _rememberKeyGamepad();
    markActive();
  }
}

bool isEditableTextFocused() {
  final node = FocusManager.instance.primaryFocus;
  final ctx = node?.context;
  if (ctx == null) return false;
  if (!isGamepadContextOnstage(ctx)) return false;
  if (ctx.widget is EditableText) return true;
  return ctx.findAncestorStateOfType<EditableTextState>() != null;
}
