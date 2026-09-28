import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_mapping.dart';
import 'package:multigames_client/core/gamepad/gamepad_repeat.dart';

const androidGamepadChannel = MethodChannel('zozu/gamepad');

/// Список HID-геймпадов на Android. На вебе и других ОС — пусто.
Future<List<GamepadDevice>> listNativeGamepads() async {
  if (kIsWeb) return const [];
  if (defaultTargetPlatform != TargetPlatform.android) return const [];
  try {
    final raw = await androidGamepadChannel.invokeMethod<List<dynamic>>(
      'listDevices',
    );
    if (raw == null) return const [];
    return [
      for (final row in raw)
        if (row is Map)
          GamepadDevice(
            id: '${row['id'] ?? ''}',
            name: '${row['name'] ?? 'Gamepad'}',
            index: (row['index'] as num?)?.toInt() ?? 0,
          ),
    ].where((d) => d.id.isNotEmpty).toList(growable: false);
  } catch (_) {
    return const [];
  }
}

/// Стики и запасные кнопки с Android [MotionEvent] / [KeyEvent].
class AndroidGamepadBridge {
  AndroidGamepadBridge({
    required this.onEvent,
    required this.onDevices,
  });

  final void Function(GamepadActionEvent event) onEvent;
  final void Function(List<GamepadDevice> devices) onDevices;

  final GamepadRepeatTracker _repeat = GamepadRepeatTracker();
  Timer? _timer;
  double _lx = 0;
  double _ly = 0;
  double _rx = 0;
  double _ry = 0;
  double _hx = 0;
  double _hy = 0;
  double _lt = 0;
  double _rt = 0;
  bool _ltHeld = false;
  bool _rtHeld = false;
  String _id = '';
  String _name = 'Gamepad';
  bool _listening = false;

  void start() {
    if (_listening) return;
    _listening = true;
    androidGamepadChannel.setMethodCallHandler(_onCall);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  void stop() {
    _listening = false;
    _timer?.cancel();
    _timer = null;
    _repeat.reset();
    androidGamepadChannel.setMethodCallHandler(null);
  }

  Future<void> _onCall(MethodCall call) async {
    final args = call.arguments;
    if (args is! Map) return;
    if (call.method == 'motion') {
      _id = '${args['id'] ?? _id}';
      _name = '${args['name'] ?? _name}';
      _lx = (args['lx'] as num?)?.toDouble() ?? 0;
      _ly = (args['ly'] as num?)?.toDouble() ?? 0;
      _rx = (args['rx'] as num?)?.toDouble() ?? 0;
      _ry = (args['ry'] as num?)?.toDouble() ?? 0;
      _hx = (args['hx'] as num?)?.toDouble() ?? 0;
      _hy = (args['hy'] as num?)?.toDouble() ?? 0;
      _lt = (args['lt'] as num?)?.toDouble() ?? 0;
      _rt = (args['rt'] as num?)?.toDouble() ?? 0;
      final devices = <GamepadDevice>[
        GamepadDevice(
          id: _id.isEmpty ? 'android-pad' : _id,
          name: _name,
          index: 0,
        ),
      ];
      onDevices(devices);
      return;
    }
    if (call.method == 'key') {
      final down = args['down'] == true;
      if (!down) return;
      final repeat = (args['repeat'] as num?)?.toInt() ?? 0;
      if (repeat > 0) return;
      final action = gamepadActionFromAndroidKeyCode(
        (args['keyCode'] as num?)?.toInt() ?? 0,
      );
      if (action == null) return;
      onEvent(
        GamepadActionEvent(
          action: action,
          source: 'android',
          deviceId: _id,
          deviceName: _name,
        ),
      );
    }
  }

  void _tick() {
    final held = <GamepadAction>{};
    final pressedNow = <GamepadAction>{};
    final hat = gamepadActionFromStick(x: _hx, y: _hy, deadzone: 0.5);
    if (hat != null) held.add(hat);
    final left = gamepadActionFromStick(x: _lx, y: _ly);
    if (left != null) held.add(left);
    final scroll = gamepadIndependentScroll(
      leftX: _lx,
      leftY: _ly,
      rightX: _rx,
      rightY: _ry,
    );
    if (scroll != null) held.add(scroll);
    final lt = _lt >= 0.55;
    if (lt && !_ltHeld) pressedNow.add(GamepadAction.triggerL);
    _ltHeld = lt;
    final rt = _rt >= 0.55;
    if (rt && !_rtHeld) pressedNow.add(GamepadAction.triggerR);
    _rtHeld = rt;
    final emits = _repeat.tick(
      heldDirections: held,
      pressedNow: pressedNow,
      now: DateTime.now(),
    );
    for (final action in emits) {
      onEvent(
        GamepadActionEvent(
          action: action,
          source: 'android',
          deviceId: _id,
          deviceName: _name,
        ),
      );
    }
  }
}
