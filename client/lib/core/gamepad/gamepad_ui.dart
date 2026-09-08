import 'package:flutter/widgets.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_keyboard.dart';
import 'package:multigames_client/core/gamepad/gamepad_nav.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';

/// Навигация по фокусу Material, когда партия не перехватила ввод.
bool handleGamepadUiAction(BuildContext context, GamepadAction action) {
  if (action == GamepadAction.shoulderL ||
      action == GamepadAction.shoulderR) {
    return _switchTab(action == GamepadAction.shoulderL ? -1 : 1);
  }

  if (isEditableTextFocused()) {
    if (action == GamepadAction.cancel) {
      if (GamepadKeyboardController.instance.visible) {
        GamepadKeyboardController.instance.hide();
        return true;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      return true;
    }
    if (!GamepadKeyboardController.instance.visible) {
      GamepadKeyboardController.instance.show();
    }
    return GamepadKeyboardController.instance.visible;
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
    case GamepadAction.menu:
      if (isEditableTextFocused() || _focusTextField()) {
        GamepadKeyboardController.instance.show();
        return true;
      }
      return false;
    case GamepadAction.actionX:
    case GamepadAction.actionY:
    case GamepadAction.shoulderL:
    case GamepadAction.shoulderR:
    case GamepadAction.select:
      return false;
  }
}

bool _switchTab(int delta) {
  final tab = GamepadNav.switchTab;
  if (tab == null) return false;
  tab(delta);
  return true;
}

bool _moveFocus(TraversalDirection direction) {
  final node = FocusManager.instance.primaryFocus;
  final root = FocusManager.instance.rootScope;
  if (node == null || node == root || node.context == null) {
    return root.nextFocus();
  }
  if (node.focusInDirection(direction)) {
    _ensureVisible(FocusManager.instance.primaryFocus);
    return true;
  }
  final fallback = direction == TraversalDirection.down ||
          direction == TraversalDirection.right
      ? node.nextFocus()
      : node.previousFocus();
  if (fallback) {
    _ensureVisible(FocusManager.instance.primaryFocus);
    return true;
  }
  return root.nextFocus();
}

void _ensureVisible(FocusNode? node) {
  final ctx = node?.context;
  if (ctx == null) return;
  Scrollable.ensureVisible(
    ctx,
    alignment: 0.45,
    duration: const Duration(milliseconds: 120),
    curve: Curves.easeOut,
    alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
  );
}

bool _activateFocused() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) {
    return FocusManager.instance.rootScope.nextFocus();
  }
  if (isEditableTextFocused()) {
    GamepadKeyboardController.instance.show();
    return true;
  }
  final invoked = Actions.maybeInvoke<ActivateIntent>(
    ctx,
    const ActivateIntent(),
  );
  return invoked != null;
}

bool _focusTextField() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return false;
  return ctx.findAncestorStateOfType<EditableTextState>() != null;
}

bool _popRoute(BuildContext context) {
  final nav = Navigator.maybeOf(context);
  if (nav != null && nav.canPop()) {
    nav.maybePop();
    return true;
  }
  return false;
}
