import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Контекст на активной вкладке, а не в скрытой ветке `IndexedStack`.
bool isGamepadContextOnstage(BuildContext ctx) {
  if (!ctx.mounted) return false;
  var hidden = false;
  ctx.visitAncestorElements((el) {
    final w = el.widget;
    if (w is Offstage && w.offstage) {
      hidden = true;
      return false;
    }
    if (w is Visibility && !w.visible) {
      hidden = true;
      return false;
    }
    if (w is TickerMode && !w.enabled) {
      hidden = true;
      return false;
    }
    if (w is ExcludeFocus && w.excluding) {
      hidden = true;
      return false;
    }
    if (w is IgnorePointer && w.ignoring) {
      hidden = true;
      return false;
    }
    return true;
  });
  if (hidden) return false;
  final ro = ctx.findRenderObject();
  if (ro == null || !ro.attached) return true;
  var child = ro;
  var parent = ro.parent;
  while (parent != null) {
    if (parent is RenderOffstage && parent.offstage) return false;
    if (parent is RenderIndexedStack &&
        !isIndexedStackChildDisplayed(parent, child)) {
      return false;
    }
    child = parent;
    parent = parent.parent;
  }
  return true;
}

bool isIndexedStackChildDisplayed(
  RenderIndexedStack stack,
  RenderObject child,
) {
  final index = stack.index;
  if (index == null) return false;
  var displayed = stack.firstChild;
  for (var i = 0; i < index && displayed != null; i++) {
    displayed = stack.childAfter(displayed);
  }
  return identical(displayed, child);
}
