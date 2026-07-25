import 'package:flutter/material.dart';

/// Свайп от левого края вправо — то же действие, что у кнопки «Назад».
///
/// Срабатывает сразу при достаточном смещении пальца (не ждёт отпускания).
/// Жест ловится узкой полосой слева, чтобы не мешать TextField и горизонтальным
/// спискам.
class SwipeBackScope extends StatefulWidget {
  const SwipeBackScope({
    super.key,
    required this.onBack,
    required this.child,
    this.enabled = true,
    this.edgeWidth = 32,
    this.triggerDistance = 28,
    this.topInset = 0,
  });

  final VoidCallback onBack;
  final Widget child;
  final bool enabled;

  /// Ширина активной зоны у левого края.
  final double edgeWidth;

  /// Насколько нужно провести вправо, чтобы сработало сразу.
  final double triggerDistance;

  /// Отступ сверху (например, под кастомный header).
  final double topInset;

  @override
  State<SwipeBackScope> createState() => _SwipeBackScopeState();
}

class _SwipeBackScopeState extends State<SwipeBackScope> {
  double _dx = 0;
  bool _triggered = false;

  void _reset() {
    _dx = 0;
    _triggered = false;
  }

  void _maybeTrigger() {
    if (_triggered || !widget.enabled) return;
    if (_dx < widget.triggerDistance) return;
    _triggered = true;
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 0,
          top: widget.topInset,
          bottom: 0,
          width: widget.edgeWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => _reset(),
            onHorizontalDragUpdate: (details) {
              _dx += details.delta.dx;
              if (_dx < 0) _dx = 0;
              _maybeTrigger();
            },
            onHorizontalDragEnd: (_) => _reset(),
            onHorizontalDragCancel: _reset,
          ),
        ),
      ],
    );
  }
}
