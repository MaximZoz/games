import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_keyboard.dart';
import 'package:multigames_client/core/gamepad/gamepad_nav.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/core/gamepad/gamepad_visibility.dart';

/// Навигация по фокусу Material, когда партия не перехватила ввод.
bool handleGamepadUiAction(BuildContext context, GamepadAction action) {
  unfocusOffstagePrimaryFocus();
  if (action == GamepadAction.shoulderL ||
      action == GamepadAction.shoulderR) {
    return _switchTab(action == GamepadAction.shoulderL ? -1 : 1);
  }

  if (isEditableTextFocused() &&
      isGamepadFocusVisible(FocusManager.instance.primaryFocus)) {
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

/// После смены вкладки — первый видимый блок новой страницы.
void scheduleFocusFirstVisibleGamepadTarget() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    focusFirstVisibleGamepadTarget();
  });
}

bool focusFirstVisibleGamepadTarget() {
  final blocks = _visibleGamepadFocusBlocks();
  if (blocks.isNotEmpty) {
    blocks.first.requestFocus();
    _ensureVisible(blocks.first);
    return true;
  }
  FocusNode? first;
  void walk(FocusNode node) {
    if (first != null) return;
    if (node.context != null && isGamepadFocusVisible(node)) {
      first = node;
      return;
    }
    for (final child in List<FocusNode>.from(node.children)) {
      walk(child);
    }
  }

  walk(FocusManager.instance.rootScope);
  if (first == null) return false;
  first!.requestFocus();
  _ensureVisible(first);
  return true;
}

bool isGamepadFocusVisible(FocusNode? node) {
  if (node == null || !node.canRequestFocus) return false;
  if (node == FocusManager.instance.rootScope) return false;
  // FocusScope — контейнер, не карточка: иначе A «нажимает» пустую область,
  // а обводка садится на чужой виджет той же ячейки IndexedStack.
  if (node is FocusScopeNode) return false;
  final ctx = node.context;
  if (ctx == null || !ctx.mounted) return false;
  final ro = ctx.findRenderObject();
  if (ro is! RenderBox || !ro.hasSize || !ro.attached) return false;
  if (ro.size.width < 2 || ro.size.height < 2) return false;
  final label = node.debugLabel;
  if (label == 'Navigator' || label == 'Navigator State') return false;
  final inBlock = GamepadFocusBlock.maybeOf(ctx) != null;
  if (!inBlock) {
    final mq = MediaQuery.maybeOf(ctx);
    if (mq != null &&
        ro.size.width > mq.size.width * 0.94 &&
        ro.size.height > mq.size.height * 0.45) {
      return false;
    }
  }
  return isGamepadContextOnstage(ctx);
}

bool _switchTab(int delta) {
  final tab = GamepadNav.switchTab;
  if (tab == null) return false;
  tab(delta);
  return true;
}

bool _moveFocus(TraversalDirection direction) {
  final start = FocusManager.instance.primaryFocus;
  final root = FocusManager.instance.rootScope;
  final blocks = _visibleGamepadFocusBlocks();
  if (blocks.isNotEmpty && _moveGamepadBlock(direction, blocks)) {
    return true;
  }
  if (start == null || start == root || start.context == null) {
    return focusFirstVisibleGamepadTarget();
  }
  for (var i = 0; i < 40; i++) {
    final node = FocusManager.instance.primaryFocus;
    if (node == null || node == root || node.context == null) {
      return focusFirstVisibleGamepadTarget();
    }
    final stepped = node.focusInDirection(direction) ||
        ((direction == TraversalDirection.down ||
                direction == TraversalDirection.right)
            ? node.nextFocus()
            : node.previousFocus());
    if (!stepped) break;
    final next = FocusManager.instance.primaryFocus;
    if (next == start) break;
    if (isGamepadFocusVisible(next)) {
      _ensureVisible(next);
      return true;
    }
  }
  if (_moveGamepadBlock(direction, _visibleGamepadFocusBlocks())) {
    return true;
  }
  return focusFirstVisibleGamepadTarget();
}

List<FocusNode> _visibleGamepadFocusBlocks() {
  final seen = <FocusNode>{};
  final out = <FocusNode>[];

  void consider(FocusNode node) {
    if (!seen.add(node)) return;
    if (!isGamepadFocusVisible(node)) return;
    final ctx = node.context;
    if (ctx == null) return;
    if (!GamepadFocusRegistry.nodes.contains(node) &&
        GamepadFocusBlock.maybeOf(ctx) == null) {
      return;
    }
    out.add(node);
  }

  for (final node in GamepadFocusRegistry.nodes) {
    consider(node);
  }
  void walk(FocusNode node) {
    consider(node);
    for (final child in List<FocusNode>.from(node.children)) {
      walk(child);
    }
  }

  walk(FocusManager.instance.rootScope);
  out.sort((a, b) {
    final ra = _focusRect(a);
    final rb = _focusRect(b);
    if (ra == null || rb == null) return 0;
    final dy = ra.center.dy - rb.center.dy;
    if (dy.abs() > 8) return dy.compareTo(0);
    return ra.center.dx.compareTo(rb.center.dx);
  });
  return out;
}

bool _moveGamepadBlock(
  TraversalDirection direction,
  List<FocusNode> blocks,
) {
  if (blocks.isEmpty) return false;
  final current = FocusManager.instance.primaryFocus;
  final index = _indexOfGamepadBlock(blocks, current);
  final FocusNode next;
  if (index < 0) {
    next = (direction == TraversalDirection.up ||
            direction == TraversalDirection.left)
        ? blocks.last
        : blocks.first;
  } else {
    next = _neighborGamepadBlock(blocks, index, direction);
  }
  next.requestFocus();
  _ensureVisible(next);
  return true;
}

int _indexOfGamepadBlock(List<FocusNode> blocks, FocusNode? current) {
  if (current == null) return -1;
  final direct = blocks.indexOf(current);
  if (direct >= 0) return direct;
  final ctx = current.context;
  if (ctx == null) return -1;
  final scope = GamepadFocusBlock.maybeOf(ctx);
  if (scope == null) return -1;
  return blocks.indexWhere((node) {
    final nodeCtx = node.context;
    return nodeCtx != null &&
        identical(GamepadFocusBlock.maybeOf(nodeCtx), scope);
  });
}

FocusNode _neighborGamepadBlock(
  List<FocusNode> blocks,
  int index,
  TraversalDirection direction,
) {
  final current = blocks[index];
  final curRect = _focusRect(current);
  if (curRect != null) {
    FocusNode? best;
    var bestScore = double.infinity;
    for (final node in blocks) {
      if (identical(node, current)) continue;
      final rect = _focusRect(node);
      if (rect == null) continue;
      final dx = rect.center.dx - curRect.center.dx;
      final dy = rect.center.dy - curRect.center.dy;
      final ok = switch (direction) {
        TraversalDirection.down => dy > 8,
        TraversalDirection.up => dy < -8,
        TraversalDirection.right => dx > 8,
        TraversalDirection.left => dx < -8,
      };
      if (!ok) continue;
      final primary = direction == TraversalDirection.down ||
              direction == TraversalDirection.up
          ? dy.abs()
          : dx.abs();
      final secondary = direction == TraversalDirection.down ||
              direction == TraversalDirection.up
          ? dx.abs()
          : dy.abs();
      final score = secondary * 3 + primary;
      if (score < bestScore) {
        bestScore = score;
        best = node;
      }
    }
    if (best != null) return best;
  }
  final delta = direction == TraversalDirection.down ||
          direction == TraversalDirection.right
      ? 1
      : -1;
  return blocks[(index + delta) % blocks.length];
}

Rect? _focusRect(FocusNode node) {
  final ctx = node.context;
  if (ctx == null) return null;
  final ro = ctx.findRenderObject();
  if (ro is! RenderBox || !ro.hasSize || !ro.attached) return null;
  return ro.localToGlobal(Offset.zero) & ro.size;
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
  final node = FocusManager.instance.primaryFocus;
  if (!isGamepadFocusVisible(node)) {
    return focusFirstVisibleGamepadTarget();
  }
  final ctx = node!.context;
  if (ctx == null) {
    return focusFirstVisibleGamepadTarget();
  }
  if (isEditableTextFocused()) {
    GamepadKeyboardController.instance.show();
    return true;
  }
  final block = GamepadFocusBlock.maybeOf(ctx);
  if (block?.onActivate != null) {
    block!.onActivate!();
    return true;
  }
  if (_toggleSwitchOrCheckbox(ctx)) return true;
  if (Actions.maybeFind<ActivateIntent>(ctx) != null) {
    Actions.maybeInvoke<ActivateIntent>(ctx, const ActivateIntent());
    return true;
  }
  final ink = _inkWellInBlock(ctx);
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

/// Только InkWell текущего блока, не родитель из другой карточки.
InkWell? _inkWellInBlock(BuildContext ctx) {
  if (ctx.widget is InkWell) {
    return ctx.widget as InkWell;
  }
  InkWell? found;
  var depth = 0;
  ctx.visitAncestorElements((el) {
    depth++;
    if (depth > 8) return false;
    final w = el.widget;
    if (w is Offstage || w is Scaffold || w is Navigator) return false;
    if (w is InkWell) {
      found = w;
      return false;
    }
    return true;
  });
  return found;
}

bool _toggleSwitchOrCheckbox(BuildContext ctx) {
  Switch? sw;
  Checkbox? box;
  void pick(Widget w) {
    if (w is Switch && w.onChanged != null) sw = w;
    if (w is Checkbox && w.onChanged != null) box = w;
  }

  pick(ctx.widget);
  var depth = 0;
  ctx.visitAncestorElements((el) {
    depth++;
    if (depth > 6) return false;
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
  final nav = _navigatorForGamepad(context);
  if (nav != null && nav.canPop()) {
    nav.maybePop();
    return true;
  }
  return false;
}

/// GamepadHost сидит в `MaterialApp.builder` — предка-Navigator нет.
NavigatorState? _navigatorForGamepad(BuildContext hostContext) {
  final focusCtx = FocusManager.instance.primaryFocus?.context;
  if (focusCtx != null && focusCtx.mounted) {
    final nav = Navigator.maybeOf(focusCtx);
    if (nav != null) return nav;
  }
  NavigatorState? best;
  void visit(Element el) {
    if (el is StatefulElement && el.state is NavigatorState) {
      final nav = el.state as NavigatorState;
      if (nav.mounted && nav.canPop()) {
        best = nav;
      }
    }
    el.visitChildren(visit);
  }

  hostContext.visitChildElements(visit);
  if (best != null) return best;
  return Navigator.maybeOf(hostContext);
}
