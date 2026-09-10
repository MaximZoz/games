import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_poller.dart';

/// VM / iOS / Android без Gamepad API: кнопки приходят как KeyEvent.
class StubGamepadPoller implements GamepadPoller {
  @override
  void start({
    required void Function(GamepadActionEvent event) onEvent,
    required void Function(List<GamepadDevice> devices) onDevices,
  }) {}

  @override
  void stop() {}
}

GamepadPoller createGamepadPoller() => StubGamepadPoller();
