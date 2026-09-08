import 'package:flutter/widgets.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_nav.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';

/// Навигация по фокусу Material, когда партия не перехватила ввод.
bool handleGamepadUiAction(BuildContext context, GamepadAction action) {
  if (isEditableTextFocused()) {
    if (action == GamepadAction.cancel) {
      FocusManager.instance.primaryFocus?.unfocus();
      return true;
    }
    return false;
  }

  switch (action) {
    case GamepadAction.up:
      return _moveFocus(TraversalDirection.up);
    case GamepadAction.down:
      return _moveFocus(TraversalDirection.down);
    case GamepadAction.left:
      return _moveFocus(TraversalDirection.left);
    case GamepadAction.right:
      return _moveFocus(TraversalDirection.right);
    case GamepadAction.confirm:
      return _activateFocused();
    case GamepadAction.cancel:
      return _popRoute(context);
    case GamepadAction.shoulderL:
      final tab = GamepadNav.switchTab;
      if (tab == null) return false;
      tab(-1);
      return true;
    case GamepadAction.shoulderR:
      final tab = GamepadNav.switchTab;
      if (tab == null) return false;
      tab(1);
      return true;
    case GamepadAction.actionX:
    case GamepadAction.actionY:
    case GamepadAction.menu:
    case GamepadAction.select:
      return false;
  }
}

bool _moveFocus(TraversalDirection direction) {
  final node = FocusManager.instance.primaryFocus;
  if (node == null || node.context == null) {
    return FocusManager.instance.rootScope.nextFocus();
  }
  return node.focusInDirection(direction);
}

bool _activateFocused() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) {
    return FocusManager.instance.rootScope.nextFocus();
  }
  final invoked = Actions.maybeInvoke<ActivateIntent>(
    ctx,
    const ActivateIntent(),
  );
  return invoked != null;
}

bool _popRoute(BuildContext context) {
  final nav = Navigator.maybeOf(context);
  if (nav != null && nav.canPop()) {
    nav.maybePop();
    return true;
  }
  return false;
}
