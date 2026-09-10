import 'package:flutter/widgets.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_dispatcher.dart';

/// Экран партии: верните `true`, если действие обработано.
class GamepadScope extends StatefulWidget {
  const GamepadScope({
    super.key,
    required this.onAction,
    required this.child,
  });

  final GamepadActionHandler onAction;
  final Widget child;

  @override
  State<GamepadScope> createState() => _GamepadScopeState();
}

class _GamepadScopeState extends State<GamepadScope> {
  @override
  void initState() {
    super.initState();
    GamepadDispatcher.push(_handle);
  }

  @override
  void dispose() {
    GamepadDispatcher.remove(_handle);
    super.dispose();
  }

  bool _handle(GamepadAction action) => widget.onAction(action);

  @override
  Widget build(BuildContext context) => widget.child;
}
