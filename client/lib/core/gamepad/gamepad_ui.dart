import 'package:flutter/material.dart';
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
      if (_nudgeFocused(-1)) return true;
      return _moveFocus(TraversalDirection.left);
    case GamepadAction.right:
      if (_nudgeFocused(1)) return true;
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
  if (_toggleSwitchOrCheckbox(ctx)) return true;
  if (Actions.maybeFind<ActivateIntent>(ctx) != null) {
    Actions.maybeInvoke<ActivateIntent>(ctx, const ActivateIntent());
    return true;
  }
  final ink = ctx.findAncestorWidgetOfExactType<InkWell>();
  if (ink?.onTap != null) {
    ink!.onTap!();
    return true;
  }
  final btn = ctx.findAncestorWidgetOfExactType<IconButton>();
  if (btn?.onPressed != null) {
    btn!.onPressed!();
    return true;
  }
  return false;
}

bool _toggleSwitchOrCheckbox(BuildContext ctx) {
  Switch? sw;
  Checkbox? box;
  void pick(Widget w) {
    if (w is Switch && w.onChanged != null) sw = w;
    if (w is Checkbox && w.onChanged != null) box = w;
  }

  pick(ctx.widget);
  ctx.visitAncestorElements((el) {
    pick(el.widget);
    return sw == null && box == null;
  });
  void walk(Element el) {
    if (sw != null || box != null) return;
    pick(el.widget);
    el.visitChildren(walk);
  }

  ctx.visitChildElements(walk);
  final foundSwitch = sw;
  if (foundSwitch != null && foundSwitch.onChanged != null) {
    foundSwitch.onChanged!(!foundSwitch.value);
    return true;
  }
  final foundBox = box;
  if (foundBox != null && foundBox.onChanged != null) {
    foundBox.onChanged!(!(foundBox.value ?? false));
    return true;
  }
  return false;
}

bool _nudgeFocused(int delta) {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return false;
  Slider? slider;
  void pick(Widget w) {
    if (w is Slider && w.onChanged != null) slider = w;
  }

  pick(ctx.widget);
  void walk(Element el) {
    if (slider != null) return;
    pick(el.widget);
    el.visitChildren(walk);
  }

  ctx.visitChildElements(walk);
  ctx.visitAncestorElements((el) {
    pick(el.widget);
    return slider == null;
  });
  final found = slider;
  if (found == null || found.onChanged == null) return false;
  final span = found.max - found.min;
  final step = found.divisions != null && found.divisions! > 0
      ? span / found.divisions!
      : span / 20;
  final next = (found.value + delta * step).clamp(found.min, found.max);
  found.onChanged!(next);
  return true;
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
