import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_poller_stub.dart'
    if (dart.library.html) 'package:multigames_client/core/gamepad/gamepad_poller_web.dart'
    as impl;

/// Опрос физических геймпадов (на вебе — Gamepad API).
abstract class GamepadPoller {
  void start({
    required void Function(GamepadActionEvent event) onEvent,
    required void Function(List<GamepadDevice> devices) onDevices,
  });

  void stop();
}

GamepadPoller createGamepadPoller() => impl.createGamepadPoller();
