import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Вертикальный список над нижним меню.
///
/// Если карточки почти заполняют экран, свободные пиксели уходят в
/// промежутки (не больше [maxGap]) и последняя карточка садится к меню.
/// Если пустоты намного больше, зазор не раздувается: список остаётся сверху.
/// Длинный список скроллится с зазором [minGap].
class SnugBottomList extends StatelessWidget {
  const SnugBottomList({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 8),
    this.minGap = 10,
    this.maxGap = 24,
  }) : assert(maxGap >= minGap);

  final List<Widget> children;
  final EdgeInsets padding;
  final double minGap;
  final double maxGap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final innerMin = constraints.hasBoundedHeight
            ? math.max(0.0, constraints.maxHeight - padding.vertical)
            : 0.0;
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: innerMin),
            child: _SnugColumn(
              minGap: minGap,
              maxGap: maxGap,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

class _SnugColumn extends MultiChildRenderObjectWidget {
  const _SnugColumn({
    required this.minGap,
    required this.maxGap,
    required super.children,
  });

  final double minGap;
  final double maxGap;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSnugColumn(minGap: minGap, maxGap: maxGap);
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderSnugColumn renderObject) {
    renderObject
      ..minGap = minGap
      ..maxGap = maxGap;
  }
}

class _SnugParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderSnugColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SnugParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SnugParentData> {
  _RenderSnugColumn({required double minGap, required double maxGap})
      : _minGap = minGap,
        _maxGap = maxGap;

  double _minGap;
  double _maxGap;

  set minGap(double value) {
    if (value == _minGap) return;
    _minGap = value;
    markNeedsLayout();
  }

  set maxGap(double value) {
    if (value == _maxGap) return;
    _maxGap = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SnugParentData) {
      child.parentData = _SnugParentData();
    }
  }

  @override
  void performLayout() {
    final childConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
    var sum = 0.0;
    var count = 0;
    var child = firstChild;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      sum += child.size.height;
      count++;
      child = childAfter(child);
    }
    final gaps = count > 1 ? count - 1 : 0;
    final natural = sum + _minGap * gaps;
    final minHeight =
        constraints.minHeight.isFinite ? constraints.minHeight : 0.0;
    final target = math.max(natural, minHeight);
    var gap = _minGap;
    if (gaps > 0 && target > natural) {
      final extraPer = (target - natural) / gaps;
      final room = math.max(0.0, _maxGap - _minGap);
      if (extraPer <= room) {
        gap = _minGap + extraPer;
      } else {
        gap = _maxGap;
      }
    }
    final used = sum + gap * gaps;
    size = constraints
        .constrain(Size(constraints.maxWidth, math.max(used, minHeight)));
    var y = 0.0;
    child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as _SnugParentData;
      parentData.offset = Offset(0, y);
      y += child.size.height;
      final next = childAfter(child);
      if (next != null) y += gap;
      child = next;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}
