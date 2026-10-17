import 'package:flutter/material.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Полоска вкладок с плашкой, которая едет за пальцем — как нижнее меню.
///
/// Нажатие сразу выбирает вкладку под пальцем. Пока палец едет, плашка
/// следует за ним и вкладка меняется на границе слота. После отпускания
/// плашка доезжает до центра выбранной вкладки.
class SlidingPillBar extends StatefulWidget {
  const SlidingPillBar({
    super.key,
    required this.itemCount,
    required this.selectedIndex,
    required this.onChanged,
    required this.itemBuilder,
    this.progress,
    this.height = 44,
    this.pillKey,
    this.shrinkWrap = false,
  });

  final int itemCount;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Widget Function(BuildContext context, int index, bool selected)
      itemBuilder;

  /// Свайп страницы под полоской: пока палец не на полоске, плашка едет
  /// вместе с этой анимацией.
  final Animation<double>? progress;

  final double height;
  final Key? pillKey;

  /// Вкладки по ширине содержимого, плашка едет от одной к другой.
  /// Нужно, когда полоска не должна растягиваться на весь экран.
  final bool shrinkWrap;

  @override
  State<SlidingPillBar> createState() => _SlidingPillBarState();
}

class _SlidingPillBarState extends State<SlidingPillBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _move;
  double _animFrom = 0;
  double _animTo = 0;
  double _dragCenter = 0;
  var _dragging = false;
  var _dragMoved = false;
  var _followExternal = true;
  int _pressedIndex = 0;
  double _barWidth = 0;
  List<Rect> _rects = const [];
  final List<GlobalKey> _slotKeys = [];

  @override
  void initState() {
    super.initState();
    _pressedIndex = widget.selectedIndex;
    _animFrom = widget.selectedIndex.toDouble();
    _animTo = _animFrom;
    _dragCenter = _animFrom;
    _move = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1,
    )..addStatusListener(_onMoveStatus);
  }

  @override
  void didUpdateWidget(covariant SlidingPillBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex &&
        !_dragging &&
        _followExternal &&
        widget.progress == null) {
      _pressedIndex = widget.selectedIndex;
      _goTo(widget.selectedIndex.toDouble());
    }
  }

  @override
  void dispose() {
    _move.removeStatusListener(_onMoveStatus);
    _move.dispose();
    super.dispose();
  }

  void _onMoveStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_dragging) {
      _followExternal = true;
    }
  }

  double _shownT() {
    final t = Curves.easeOutCubic.transform(_move.value.clamp(0.0, 1.0));
    return _animFrom + (_animTo - _animFrom) * t;
  }

  double _travel(int count) {
    if (_dragging) return _dragCenter;
    if (!_followExternal) return _shownT();
    final external = widget.progress?.value;
    if (external != null) {
      return external.clamp(0.0, (count - 1).toDouble());
    }
    return _shownT();
  }

  void _goTo(double target) {
    final current = _dragging ? _dragCenter : _travel(widget.itemCount);
    _dragging = false;
    _followExternal = false;
    _animFrom = current;
    _animTo = target;
    if ((current - target).abs() < 0.02) {
      _move.value = 1;
      _followExternal = true;
      setState(() {});
      return;
    }
    _move.forward(from: 0);
    setState(() {});
  }

  GlobalKey _slotKey(int index) {
    while (_slotKeys.length <= index) {
      _slotKeys.add(GlobalKey());
    }
    return _slotKeys[index];
  }

  void _measureSlots() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final next = <Rect>[];
    for (var i = 0; i < widget.itemCount; i++) {
      final slot = _slotKey(i).currentContext?.findRenderObject();
      if (slot is! RenderBox || !slot.hasSize) return;
      final Offset origin;
      try {
        origin = slot.localToGlobal(Offset.zero, ancestor: box);
      } catch (_) {
        return;
      }
      next.add(origin & slot.size);
    }
    if (next.length == _rects.length) {
      var same = true;
      for (var i = 0; i < next.length; i++) {
        if ((next[i].left - _rects[i].left).abs() > 0.5 ||
            (next[i].width - _rects[i].width).abs() > 0.5) {
          same = false;
          break;
        }
      }
      if (same) return;
    }
    setState(() => _rects = next);
  }

  int _indexFor(double x, int count) {
    if (widget.shrinkWrap && _rects.length == count) {
      for (var i = 0; i < _rects.length; i++) {
        if (x < _rects[i].right) return i;
      }
      return count - 1;
    }
    final width = _barWidth;
    if (width <= 0 || count <= 0) return 0;
    final slot = width / count;
    return (x / slot).floor().clamp(0, count - 1);
  }

  double _centerFor(double x, int count) {
    if (widget.shrinkWrap && _rects.length == count) {
      for (var i = 0; i < _rects.length; i++) {
        final rect = _rects[i];
        if (x <= rect.right || i == _rects.length - 1) {
          final local = rect.width <= 0
              ? 0.5
              : ((x - rect.left) / rect.width).clamp(0.0, 1.0);
          return (i + local - 0.5).clamp(0.0, (count - 1).toDouble());
        }
      }
    }
    final width = _barWidth;
    if (width <= 0 || count <= 0) return 0;
    final slot = width / count;
    return (x / slot - 0.5).clamp(0.0, (count - 1).toDouble());
  }

  void _pointer(double x, {required bool commit}) {
    final count = widget.itemCount;
    if (count <= 0) return;
    if (!widget.shrinkWrap && _barWidth <= 0) return;
    final index = _indexFor(x, count);
    setState(() {
      _dragging = true;
      _followExternal = false;
      _dragCenter = _centerFor(x, count);
    });
    if (commit || index != _pressedIndex) {
      _pressedIndex = index;
      widget.onChanged(index);
    }
  }

  void _endDrag() {
    if (!_dragging) return;
    _goTo(_pressedIndex.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.itemCount;
    final listen = widget.progress == null
        ? _move
        : Listenable.merge([_move, widget.progress!]);
    return AnimatedBuilder(
      animation: listen,
      builder: (context, _) {
        final safeIndex = widget.selectedIndex.clamp(0, count <= 0 ? 0 : count - 1);
        final active = _dragging ? _pressedIndex.clamp(0, count - 1) : safeIndex;
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            _barWidth = width;
            final travel = _travel(count);
            late final double left;
            late final double pillWidth;
            if (widget.shrinkWrap &&
                _rects.length == count &&
                count > 0) {
              final last = count - 1;
              final t = travel.clamp(0.0, last.toDouble());
              final i = t.floor().clamp(0, last);
              final f = (t - i).clamp(0.0, 1.0);
              final a = _rects[i];
              final b = _rects[i + 1 > last ? last : i + 1];
              left = a.left + (b.left - a.left) * f + 2;
              pillWidth = (a.width + (b.width - a.width) * f - 4)
                  .clamp(0.0, width);
            } else if (widget.shrinkWrap) {
              left = 0;
              pillWidth = 0;
            } else {
              final slot = count == 0 ? width : width / count;
              pillWidth = (slot - 6).clamp(0.0, slot);
              left = travel * slot + (slot - pillWidth) / 2;
            }
            if (widget.shrinkWrap) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _measureSlots();
              });
            }
            final pill = Positioned(
              left: left,
              top: 3,
              width: pillWidth,
              height: widget.height - 6,
              child: DecoratedBox(
                key: widget.pillKey ?? const ValueKey('sliding-pill'),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(
                    (widget.height - 6) / 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentStart.withValues(alpha: 0.16),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            );
            final items = Row(
              mainAxisSize:
                  widget.shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
              children: [
                for (var i = 0; i < count; i++)
                  widget.shrinkWrap
                      ? KeyedSubtree(
                          key: _slotKey(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: widget.itemBuilder(context, i, i == active),
                          ),
                        )
                      : Expanded(
                          child: Center(
                            child: widget.itemBuilder(context, i, i == active),
                          ),
                        ),
              ],
            );
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                _dragMoved = false;
                _pointer(details.localPosition.dx, commit: true);
              },
              onTapUp: (_) => _endDrag(),
              onTapCancel: () {
                if (!_dragMoved) _endDrag();
              },
              onHorizontalDragStart: (details) {
                _dragMoved = true;
                _pointer(details.localPosition.dx, commit: false);
              },
              onHorizontalDragUpdate: (details) {
                _dragMoved = true;
                _pointer(details.localPosition.dx, commit: false);
              },
              onHorizontalDragEnd: (_) => _endDrag(),
              onHorizontalDragCancel: _endDrag,
              child: SizedBox(
                height: widget.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    pill,
                    items,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
