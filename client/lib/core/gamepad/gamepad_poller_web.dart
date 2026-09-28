import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_mapping.dart';
import 'package:multigames_client/core/gamepad/gamepad_poller.dart';
import 'package:multigames_client/core/gamepad/gamepad_repeat.dart';

/// Опрос `navigator.getGamepads()` (~60 Гц).
class WebGamepadPoller implements GamepadPoller {
  Timer? _timer;
  final Map<int, List<bool>> _prevButtons = {};
  final Map<int, GamepadRepeatTracker> _repeat = {};
  List<GamepadDevice> _lastDevices = const [];

  @override
  void start({
    required void Function(GamepadActionEvent event) onEvent,
    required void Function(List<GamepadDevice> devices) onDevices,
  }) {
    stop();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _tick(onEvent, onDevices);
    });
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
    _prevButtons.clear();
    _repeat.clear();
  }

  void _tick(
    void Function(GamepadActionEvent event) onEvent,
    void Function(List<GamepadDevice> devices) onDevices,
  ) {
    List<web.Gamepad?> pads;
    try {
      pads = web.window.navigator.getGamepads().toDart;
    } catch (_) {
      return;
    }

    final devices = <GamepadDevice>[];
    final now = DateTime.now();
    for (final pad in pads) {
      if (pad == null || !pad.connected) continue;
      final index = pad.index;
      final name = pad.id.trim().isEmpty ? 'Gamepad ${index + 1}' : pad.id;
      final id = '$index:$name';
      devices.add(GamepadDevice(id: id, name: _shortName(name), index: index));

      final buttons = pad.buttons.toDart;
      final prev = _prevButtons[index] ??
          List<bool>.filled(buttons.length, false, growable: true);
      if (prev.length < buttons.length) {
        prev.addAll(List<bool>.filled(buttons.length - prev.length, false));
      }

      final pressedNow = <GamepadAction>{};
      final heldDirections = <GamepadAction>{};
      for (var i = 0; i < buttons.length; i++) {
        final down = buttons[i].pressed;
        final was = i < prev.length && prev[i];
        final action = gamepadActionFromStandardButton(i);
        if (action != null && down) {
          if (action.isDirection) {
            heldDirections.add(action);
          } else if (!was) {
            pressedNow.add(action);
          }
        }
        if (i < prev.length) prev[i] = down;
      }
      _prevButtons[index] = prev;

      final axes = pad.axes.toDart;
      if (axes.length >= 2) {
        final stick = gamepadActionFromStick(
          x: axes[0].toDartDouble,
          y: axes[1].toDartDouble,
        );
        if (stick != null) heldDirections.add(stick);
      }
      if (axes.length >= 4) {
        final scroll = gamepadScrollFromStick(
          x: axes[2].toDartDouble,
          y: axes[3].toDartDouble,
        );
        if (scroll != null) heldDirections.add(scroll);
      }

      final tracker = _repeat.putIfAbsent(index, GamepadRepeatTracker.new);
      final emits = tracker.tick(
        heldDirections: heldDirections,
        pressedNow: pressedNow,
        now: now,
      );
      for (final action in emits) {
        onEvent(
          GamepadActionEvent(
            action: action,
            source: 'pad',
            deviceId: id,
            deviceName: _shortName(name),
          ),
        );
      }
    }

    if (!_sameDevices(devices, _lastDevices)) {
      _lastDevices = List<GamepadDevice>.from(devices);
      onDevices(_lastDevices);
    }
  }

  static bool _sameDevices(List<GamepadDevice> a, List<GamepadDevice> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static String _shortName(String raw) {
    final cut = raw.split('(').first.trim();
    if (cut.length <= 42) return cut;
    return '${cut.substring(0, 41)}…';
  }
}

GamepadPoller createGamepadPoller() => WebGamepadPoller();
