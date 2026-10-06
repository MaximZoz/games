import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_chrome.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_keyboard.dart';
import 'package:multigames_client/core/gamepad/gamepad_nav.dart';
import 'package:multigames_client/core/gamepad/gamepad_pager.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/core/gamepad/gamepad_text.dart';
import 'package:multigames_client/core/gamepad/gamepad_visibility.dart';

/// Скрыть клавиатуру геймпада и вернуть фокус на рамку поля.
void dismissGamepadKeyboard() {
  GamepadKeyboardController.instance.hide();
  final primary = FocusManager.instance.primaryFocus;
  final ctx = primary?.context;
  if (ctx == null || !isEditableTextFocused()) return;
  final scope = GamepadFocusBlock.maybeOf(ctx);
  primary!.unfocus();
  scope?.focusNode.requestFocus();
}

/// Правый стик / статистика: страница скролла.
///
/// [context] — искать скролл сначала рядом с попапом, не у фона (друзья).
bool scrollGamepadByPage(int direction, {BuildContext? context}) =>
    _scrollPage(direction, context: context);

/// Правый стик: горизонтальная полоса (счёт, коллекции, смайлы).
bool scrollGamepadHorizontalStrip(
  GamepadAction action, {
  BuildContext? context,
}) {
  if (!action.isScroll) return false;
  final left = action == GamepadAction.scrollLeft ||
      action == GamepadAction.scrollUp;
  final position = _horizontalScrollPosition(context);
  if (position == null ||
      !position.hasPixels ||
      !position.hasContentDimensions) {
    return false;
  }
  final viewport = position.viewportDimension;
  if (viewport <= 0) return false;
  final direction = left ? -1.0 : 1.0;
  final delta = math.max(56.0, viewport * 0.55) * direction;
  final next = (position.pixels + delta).clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
  if ((next - position.pixels).abs() < 1) return false;
  position.animateTo(
    next,
    duration: const Duration(milliseconds: 160),
    curve: Curves.easeOut,
  );
  return true;
}

/// Поле ввода при живом геймпаде — только экранная клавиатура контроллера.
void syncGamepadKeyboardForFocus() {
  if (!gamepadHintsWanted()) return;
  if (isEditableTextFocused()) {
    GamepadKeyboardController.instance.show();
    return;
  }
  final ctx = FocusManager.instance.primaryFocus?.context;
  final block = ctx?.findAncestorWidgetOfExactType<GamepadFocusBlock>();
  if (block != null && block.attachKeyboard) return;
  GamepadKeyboardController.instance.hide();
}

/// Навигация по фокусу Material, когда партия не перехватила ввод.
bool handleGamepadUiAction(BuildContext context, GamepadAction action) {
  unfocusOffstagePrimaryFocus();
  if (action == GamepadAction.shoulderL ||
      action == GamepadAction.shoulderR) {
    return _switchTab(action == GamepadAction.shoulderL ? -1 : 1);
  }
  if (action.isScroll) {
    if (GamepadKeyboardController.instance.visible ||
        isEditableTextFocused()) {
      return GamepadTextEditing.moveByScroll(action);
    }
    if (action == GamepadAction.scrollLeft ||
        action == GamepadAction.scrollRight) {
      return false;
    }
    return _scrollPage(action == GamepadAction.scrollUp ? -1 : 1);
  }
  if (action == GamepadAction.triggerL) {
    return GamepadChromeRegistry.focus(GamepadChromeSlot.balance);
  }
  if (action == GamepadAction.triggerR) {
    return GamepadChromeRegistry.focus(GamepadChromeSlot.logout);
  }

  if (isEditableTextFocused() &&
      isGamepadFocusVisible(FocusManager.instance.primaryFocus)) {
    if (action == GamepadAction.cancel) {
      if (GamepadKeyboardController.instance.visible) {
        dismissGamepadKeyboard();
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
    case GamepadAction.triggerL:
    case GamepadAction.triggerR:
    case GamepadAction.scrollUp:
    case GamepadAction.scrollDown:
    case GamepadAction.scrollLeft:
    case GamepadAction.scrollRight:
    case GamepadAction.select:
      return false;
  }
}

/// После смены вкладки — первый видимый блок новой страницы.
void scheduleFocusFirstVisibleGamepadTarget() {
  scheduleFocusEdgeGamepadTarget(last: false);
}

/// После перелистывания страницы — первый или последний видимый блок.
void scheduleFocusEdgeGamepadTarget({required bool last}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final blocks = _visibleGamepadFocusBlocks();
    if (blocks.isEmpty) {
      focusFirstVisibleGamepadTarget();
      return;
    }
    final node = last ? blocks.last : blocks.first;
    node.requestFocus();
    _ensureVisible(node);
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

/// Карточка входа с рейлом не занимает 94% ширины, но это всё равно весь блок.
bool isGamepadFormCardBox(Size box, Size screen) {
  if (box.width > screen.width * 0.94 && box.height > screen.height * 0.45) {
    return true;
  }
  return box.width > screen.width * 0.55 && box.height > screen.height * 0.32;
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
    if (mq != null && isGamepadFormCardBox(ro.size, mq.size)) {
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

bool _scrollPage(int direction, {BuildContext? context}) {
  if (GamepadPagerRegistry.page(direction)) return true;
  final local = _verticalScrollPositionNear(context);
  if (local != null && _animateScrollPage(local, direction)) return true;
  final ctx = FocusManager.instance.primaryFocus?.context;
  final pos = ctx == null ? null : Scrollable.maybeOf(ctx)?.position;
  final focused = (pos != null &&
          pos.axis == Axis.vertical &&
          pos.hasPixels &&
          pos.hasContentDimensions)
      ? pos
      : null;
  if (focused != null && _animateScrollPage(focused, direction)) return true;
  final fallback = _nearestScrollPosition();
  if (fallback != null && _animateScrollPage(fallback, direction)) return true;
  return false;
}

bool _animateScrollPage(ScrollPosition position, int direction) {
  if (!position.hasPixels || !position.hasContentDimensions) {
    return false;
  }
  final viewport = position.viewportDimension;
  if (viewport <= 0) return false;
  final delta = viewport * 0.72 * direction;
  final next = (position.pixels + delta).clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
  if ((next - position.pixels).abs() < 1) return false;
  position.animateTo(
    next,
    duration: const Duration(milliseconds: 160),
    curve: Curves.easeOut,
  );
  scheduleFocusEdgeGamepadTarget(last: direction < 0);
  return true;
}

ScrollPosition? _verticalScrollPositionNear(BuildContext? context) {
  if (context == null || !context.mounted) return null;
  var scrollable = Scrollable.maybeOf(context);
  while (scrollable != null) {
    final pos = scrollable.position;
    if (pos.axis == Axis.vertical &&
        pos.hasContentDimensions &&
        pos.maxScrollExtent > pos.minScrollExtent) {
      return pos;
    }
    final parentCtx = scrollable.context;
    scrollable = parentCtx.mounted ? Scrollable.maybeOf(parentCtx) : null;
    if (identical(scrollable?.context, parentCtx)) break;
  }
  ScrollPosition? found;
  void walk(Element el) {
    if (found != null) return;
    if (el is StatefulElement && el.state is ScrollableState) {
      final pos = (el.state as ScrollableState).position;
      if (pos.axis == Axis.vertical &&
          pos.hasContentDimensions &&
          pos.maxScrollExtent > pos.minScrollExtent) {
        found = pos;
        return;
      }
    }
    el.visitChildren(walk);
  }

  context.visitChildElements(walk);
  return found;
}

ScrollPosition? _nearestScrollPosition() {
  ScrollPosition? found;
  void walk(Element el) {
    if (found != null) return;
    final ro = el.renderObject;
    if (ro is RenderBox && ro.hasSize && ro.attached) {
      final ctx = el;
      if (isGamepadContextOnstage(ctx)) {
        final pos = Scrollable.maybeOf(ctx)?.position;
        if (pos != null && pos.maxScrollExtent > pos.minScrollExtent) {
          found = pos;
          return;
        }
      }
    }
    el.visitChildren(walk);
  }

  final root = WidgetsBinding.instance.rootElement;
  root?.visitChildren(walk);
  return found;
}

bool _moveFocus(TraversalDirection direction) {
  final start = FocusManager.instance.primaryFocus;
  final root = FocusManager.instance.rootScope;
  // С шапки стик/крест уводят в контент, а не на соседний LT/RT.
  if (GamepadChromeRegistry.isChrome(start)) {
    return focusFirstVisibleGamepadTarget();
  }
  final blocks = _visibleGamepadFocusBlocks();
  if (blocks.isNotEmpty && _moveGamepadBlock(direction, blocks)) {
    return true;
  }
  if (start == null || start == root || start.context == null) {
    return focusFirstVisibleGamepadTarget();
  }
  // У края списка остаёмся на месте, не прыгаем на первый элемент.
  if (_indexOfGamepadBlock(blocks, start) >= 0) {
    return true;
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
    if (GamepadChromeRegistry.isChrome(next)) continue;
    if (isGamepadFocusVisible(next)) {
      _ensureVisible(next);
      return true;
    }
  }
  if (_moveGamepadBlock(direction, _visibleGamepadFocusBlocks())) {
    return true;
  }
  return blocks.isEmpty ? focusFirstVisibleGamepadTarget() : true;
}

List<FocusNode> _visibleGamepadFocusBlocks() {
  final seen = <FocusNode>{};
  final out = <FocusNode>[];

  void consider(FocusNode node) {
    if (!seen.add(node)) return;
    if (GamepadChromeRegistry.isChrome(node)) return;
    if (!isGamepadFocusVisible(node)) return;
    final ctx = node.context;
    if (ctx == null) return;
    // Только рамка блока, не глаз пароля и не внутренний TextField.
    if (!GamepadFocusRegistry.nodes.contains(node)) {
      return;
    }
    if (!_isFocusInView(node) && !_isSameFormScrollable(node)) return;
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
  if (GamepadFocusRegistry.nodes.any(gamepadNodeInPopup)) {
    out.removeWhere((node) => !gamepadNodeInPopup(node));
    if (out.isEmpty) {
      for (final node in GamepadFocusRegistry.nodes) {
        if (!gamepadNodeInPopup(node) || !isGamepadFocusVisible(node)) {
          continue;
        }
        if (out.contains(node)) continue;
        out.add(node);
      }
    }
  }
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
  final horizontal = direction == TraversalDirection.left ||
      direction == TraversalDirection.right;
  final groupBlocks = _navGroupBlocks(current, direction);
  if (groupBlocks != null) {
    if (groupBlocks.isEmpty) return true;
    final groupIndex = _indexOfGamepadBlock(groupBlocks, current);
    if (groupIndex < 0) {
      groupBlocks.first.requestFocus();
      _ensureVisible(
        groupBlocks.first,
        axis: horizontal ? Axis.horizontal : Axis.vertical,
      );
      return true;
    }
    final groupNeighbor =
        _neighborGamepadBlock(groupBlocks, groupIndex, direction);
    if (groupNeighbor != null) {
      groupNeighbor.requestFocus();
      _ensureVisible(
        groupNeighbor,
        axis: horizontal ? Axis.horizontal : Axis.vertical,
      );
    }
    return true;
  }
  final index = _indexOfGamepadBlock(blocks, current);
  if (index < 0) {
    final popupBlocks = [
      for (final node in blocks)
        if (gamepadNodeInPopup(node)) node,
    ];
    if (popupBlocks.isNotEmpty) {
      final neighbor = _neighborGamepadBlock(popupBlocks, 0, direction);
      final next = neighbor ?? popupBlocks.first;
      next.requestFocus();
      _ensureVisible(next);
      return true;
    }
    // Сфокусированный блок мог выпасть из «видимых» — не прыгаем на первый.
    if (_isContentGamepadBlock(current)) return true;
    final next = (direction == TraversalDirection.up ||
            direction == TraversalDirection.left)
        ? blocks.last
        : blocks.first;
    next.requestFocus();
    _ensureVisible(next);
    return true;
  }
  final neighbor = _neighborGamepadBlock(blocks, index, direction);
  if (neighbor != null) {
    neighbor.requestFocus();
    _ensureVisible(
      neighbor,
      axis: horizontal ? Axis.horizontal : Axis.vertical,
    );
    return true;
  }
  final pageDelta = switch (direction) {
    TraversalDirection.down || TraversalDirection.right => 1,
    TraversalDirection.up || TraversalDirection.left => -1,
  };
  if (GamepadPagerRegistry.page(pageDelta)) return true;
  return true;
}

/// Влево/вправо в группе (смайлы, фото) — только её члены, без «Назад»/«Сохранить».
List<FocusNode>? _navGroupBlocks(
  FocusNode? current,
  TraversalDirection direction,
) {
  if (current == null) return null;
  final nearest = GamepadNavGroup.ofNode(current);
  final exclusive = GamepadNavGroup.exclusiveOfNode(current);
  final horizontal = direction == TraversalDirection.left ||
      direction == TraversalDirection.right;
  if (nearest != null && !nearest.exclusive && horizontal) {
    return _sortedGroupMembers(
      (node) => identical(GamepadNavGroup.ofNode(node), nearest),
    );
  }
  if (exclusive != null) {
    return _sortedGroupMembers(
      (node) => identical(GamepadNavGroup.exclusiveOfNode(node), exclusive),
    );
  }
  if (nearest == null) return null;
  if (!horizontal && !nearest.exclusive) return null;
  return _sortedGroupMembers(
    (node) => identical(GamepadNavGroup.ofNode(node), nearest),
  );
}

List<FocusNode> _sortedGroupMembers(bool Function(FocusNode node) match) {
  final members = <FocusNode>[];
  for (final node in GamepadFocusRegistry.nodes) {
    if (!match(node)) continue;
    if (!isGamepadFocusVisible(node)) continue;
    members.add(node);
  }
  members.sort((a, b) {
    final ra = _focusRect(a);
    final rb = _focusRect(b);
    if (ra == null || rb == null) return 0;
    final dy = ra.center.dy - rb.center.dy;
    if (dy.abs() > 8) return dy.compareTo(0);
    return ra.center.dx.compareTo(rb.center.dx);
  });
  return members;
}

bool _isContentGamepadBlock(FocusNode? node) {
  if (node == null || GamepadChromeRegistry.isChrome(node)) return false;
  if (GamepadFocusRegistry.nodes.contains(node)) return true;
  final ctx = node.context;
  return ctx != null && GamepadFocusBlock.maybeOf(ctx) != null;
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

FocusNode? _neighborGamepadBlock(
  List<FocusNode> blocks,
  int index,
  TraversalDirection direction,
) {
  final current = blocks[index];
  final curRect = _focusRect(current);
  if (curRect == null) return null;
  FocusNode? best;
  var bestScore = double.infinity;
  for (final node in blocks) {
    if (identical(node, current)) continue;
    final rect = _focusRect(node);
    if (rect == null) continue;
    final dx = rect.center.dx - curRect.center.dx;
    final dy = rect.center.dy - curRect.center.dy;
    final horizontal = direction == TraversalDirection.left ||
        direction == TraversalDirection.right;
    final currentGroup = GamepadNavGroup.ofNode(current);
    final currentExclusive = GamepadNavGroup.exclusiveOfNode(current);
    if (currentGroup != null && !currentGroup.exclusive && horizontal) {
      if (!identical(GamepadNavGroup.ofNode(node), currentGroup)) continue;
    } else if (currentExclusive != null) {
      if (!identical(GamepadNavGroup.exclusiveOfNode(node), currentExclusive)) {
        continue;
      }
    } else if (horizontal) {
      final currentStrip = _horizontalScrollable(current);
      if (currentStrip != null) {
        if (!identical(_horizontalScrollable(node), currentStrip)) continue;
      } else if (!gamepadSameRow(curRect, rect)) {
        continue;
      }
    }
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
    // Ближе по направлению важнее выравнивания: иначе «Забыли пароль?»
    // справа пропускается в пользу «Войти» по центру.
    final score = primary + secondary * 0.35;
    if (score < bestScore) {
      bestScore = score;
      best = node;
    }
  }
  return best;
}

/// Диалог / exclusive-группа: стик не уходит на поля под всплывашкой.
@visibleForTesting
bool gamepadNodeInPopup(FocusNode node) {
  if (!_gamepadRouteIsCurrent(node)) return false;
  if (GamepadNavGroup.ofNode(node)?.exclusive == true) return true;
  return gamepadNodeOnPopupRoute(node);
}

@visibleForTesting
bool gamepadNodeOnPopupRoute(FocusNode node) {
  final ctx = node.context;
  if (ctx == null || !ctx.mounted) return false;
  try {
    final route = ModalRoute.of(ctx);
    return route is PopupRoute && route.isCurrent;
  } catch (_) {
    return false;
  }
}

bool _gamepadRouteIsCurrent(FocusNode node) {
  final ctx = node.context;
  if (ctx == null || !ctx.mounted) return false;
  try {
    return ModalRoute.of(ctx)?.isCurrent == true;
  } catch (_) {
    return false;
  }
}

/// Влево/вправо остаются в одной визуальной строке: не спрыгивать на поле ниже.
@visibleForTesting
bool gamepadSameRow(Rect a, Rect b) {
  final overlap = math.min(a.bottom, b.bottom) - math.max(a.top, b.top);
  if (overlap >= 8) return true;
  final slack = math.max(24.0, math.max(a.height, b.height) * 0.45);
  return (a.center.dy - b.center.dy).abs() <= slack;
}

ScrollableState? _horizontalScrollable(FocusNode node) {
  final ctx = node.context;
  if (ctx == null) return null;
  final scrollable = Scrollable.maybeOf(ctx);
  if (scrollable == null || scrollable.position.axis != Axis.horizontal) {
    return null;
  }
  return scrollable;
}

bool _isContentHorizontalStrip(ScrollPosition pos) {
  if (pos.axis != Axis.horizontal) return false;
  if (!pos.hasContentDimensions) return false;
  if (pos.maxScrollExtent <= pos.minScrollExtent) return false;
  // TabBarView / PageView — переключение вкладок, не полоса счёта.
  if (pos is PageMetrics) return false;
  return true;
}

bool _isTabPagerElement(Element el) {
  var pager = false;
  void check(Widget w) {
    if (w is TabBarView || w is PageView) pager = true;
  }

  check(el.widget);
  el.visitAncestorElements((ancestor) {
    check(ancestor.widget);
    return !pager;
  });
  return pager;
}

bool _isDescendantContext(BuildContext ancestor, BuildContext child) {
  if (!ancestor.mounted || !child.mounted) return false;
  if (identical(ancestor, child)) return true;
  var found = false;
  child.visitAncestorElements((el) {
    if (identical(el, ancestor)) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

ScrollPosition? _horizontalPositionOf(BuildContext ctx) {
  var scrollable = Scrollable.maybeOf(ctx);
  while (scrollable != null) {
    final pos = scrollable.position;
    if (_isContentHorizontalStrip(pos)) return pos;
    final parentCtx = scrollable.context;
    scrollable = parentCtx.mounted ? Scrollable.maybeOf(parentCtx) : null;
    if (identical(scrollable?.context, parentCtx)) break;
  }
  return null;
}

/// Полоса счёта / смайлов. С [context] не трогаем TabBarView и фон за попапом.
ScrollPosition? _horizontalScrollPosition(BuildContext? context) {
  final scoped = context != null && context.mounted;
  final focusCtx = FocusManager.instance.primaryFocus?.context;
  if (focusCtx != null && (!scoped || _isDescendantContext(context, focusCtx))) {
    final focused = _horizontalPositionOf(focusCtx);
    if (focused != null) return focused;
  }
  ScrollPosition? found;
  void walk(Element el) {
    if (found != null) return;
    if (_isTabPagerElement(el)) return;
    if (el is StatefulElement && el.state is ScrollableState) {
      final pos = (el.state as ScrollableState).position;
      if (_isContentHorizontalStrip(pos)) {
        found = pos;
        return;
      }
    }
    el.visitChildren(walk);
  }

  if (scoped) {
    context.visitChildElements(walk);
    return found;
  }
  WidgetsBinding.instance.rootElement?.visitChildren(walk);
  return found;
}

bool _isSameFormScrollable(FocusNode node) {
  final current = FocusManager.instance.primaryFocus;
  final aCtx = current?.context;
  final bCtx = node.context;
  if (aCtx == null || bCtx == null) return false;
  final a = Scrollable.maybeOf(aCtx);
  final b = Scrollable.maybeOf(bCtx);
  if (a == null || !identical(a, b)) return false;
  if (a.position is PageMetrics) return false;
  return true;
}

bool _isFocusInView(FocusNode node) {
  if (identical(node, FocusManager.instance.primaryFocus)) return true;
  final rect = _focusRect(node);
  if (rect == null) return false;
  final ctx = node.context;
  if (ctx == null) return false;
  final scrollable = Scrollable.maybeOf(ctx);
  final box = scrollable?.context.findRenderObject();
  if (box is RenderBox && box.hasSize && box.attached) {
    final view = box.localToGlobal(Offset.zero) & box.size;
    return rect.overlaps(view.deflate(2));
  }
  final mq = MediaQuery.maybeOf(ctx);
  if (mq == null) return true;
  return rect.overlaps(Offset.zero & mq.size);
}

Rect? _focusRect(FocusNode node) {
  final ctx = node.context;
  if (ctx == null) return null;
  final ro = ctx.findRenderObject();
  if (ro is! RenderBox || !ro.hasSize || !ro.attached) return null;
  return ro.localToGlobal(Offset.zero) & ro.size;
}

void _ensureVisible(FocusNode? node, {Axis? axis}) {
  if (node == null || gamepadFocusAlreadyVisible(node)) return;
  final ctx = node.context;
  if (ctx == null) return;
  var scrollable = Scrollable.maybeOf(ctx);
  while (scrollable != null &&
      axis != null &&
      scrollable.position.axis != axis) {
    scrollable = Scrollable.maybeOf(scrollable.context);
  }
  scrollable ??= Scrollable.maybeOf(ctx);
  if (scrollable == null) return;
  final ro = ctx.findRenderObject();
  if (ro == null || !ro.attached) return;
  scrollable.position.ensureVisible(
    ro,
    alignment: 0.15,
    duration: const Duration(milliseconds: 80),
    curve: Curves.easeOut,
    alignmentPolicy: gamepadEnsureVisiblePolicy(
      focus: _focusRect(node),
      view: _scrollableView(scrollable),
      axis: scrollable.position.axis,
    ),
  );
}

/// Влево/вверх — к началу вьюпорта, вправо/вниз — к концу.
/// `keepVisibleAtEnd` не двигает горизонтальный список, если цель слева.
@visibleForTesting
ScrollPositionAlignmentPolicy gamepadEnsureVisiblePolicy({
  required Rect? focus,
  required Rect? view,
  required Axis? axis,
}) {
  if (focus == null || view == null || axis == null) {
    return ScrollPositionAlignmentPolicy.keepVisibleAtEnd;
  }
  final clippedStart = axis == Axis.horizontal
      ? focus.left < view.left - 0.5
      : focus.top < view.top - 0.5;
  return clippedStart
      ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
      : ScrollPositionAlignmentPolicy.keepVisibleAtEnd;
}

Rect? _scrollableView(ScrollableState? scrollable) {
  final box = scrollable?.context.findRenderObject();
  if (box is RenderBox && box.hasSize && box.attached) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  return null;
}

/// Не скроллить, если плитка уже в кадре: иначе PageView эмоций в альбоме дёргается.
@visibleForTesting
bool gamepadFocusAlreadyVisible(FocusNode node) {
  final rect = _focusRect(node);
  final ctx = node.context;
  if (rect == null || ctx == null) return false;
  final scrollable = Scrollable.maybeOf(ctx);
  if (scrollable != null && scrollable.position is PageMetrics) {
    return true;
  }
  final box = scrollable?.context.findRenderObject();
  final Rect view;
  if (box is RenderBox && box.hasSize && box.attached) {
    view = box.localToGlobal(Offset.zero) & box.size;
  } else {
    final mq = MediaQuery.maybeOf(ctx);
    if (mq == null) return true;
    view = Offset.zero & mq.size;
  }
  final visible = rect.intersect(view.deflate(1));
  if (visible.isEmpty) return false;
  final area = rect.width * rect.height;
  if (area <= 0) return true;
  return visible.width * visible.height >= area * 0.9;
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
  if (dismissGamepadPopup(context)) return true;
  final nav = _navigatorForGamepad(context);
  if (nav != null && nav.canPop()) {
    nav.maybePop();
    return true;
  }
  return false;
}

/// Сверху диалог / меню, а не страница магазина или партии.
bool isGamepadPopupOpen(BuildContext context) {
  final nav = _navigatorForGamepad(context);
  if (nav == null || !nav.canPop()) return false;
  var popup = false;
  nav.popUntil((route) {
    popup = route is PopupRoute;
    return true;
  });
  return popup;
}

/// Закрывает один попап. Страницы стека не трогает.
bool dismissGamepadPopup(BuildContext context) {
  final nav = _navigatorForGamepad(context);
  if (nav == null || !nav.canPop()) return false;
  var dismissed = false;
  nav.popUntil((route) {
    if (dismissed) return true;
    if (route is PopupRoute) {
      dismissed = true;
      return false;
    }
    return true;
  });
  if (dismissed) {
    scheduleFocusFirstVisibleGamepadTarget();
  }
  return dismissed;
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
