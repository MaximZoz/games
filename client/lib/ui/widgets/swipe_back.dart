import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Свайп от левого края вправо — то же действие, что у кнопки «Назад».
///
/// Срабатывает сразу при достаточном смещении пальца (не ждёт отпускания).
/// Жест ловится узкой полосой слева через [Listener] + свой recognizer,
/// чтобы выигрывать у горизонтальных ListView / TextField на iOS Web.
class SwipeBackScope extends StatefulWidget {
  const SwipeBackScope({
    super.key,
    required this.onBack,
    required this.child,
    this.enabled = true,
    this.edgeWidth = 40,
    this.triggerDistance = 24,
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
  HorizontalDragGestureRecognizer? _drag;

  @override
  void initState() {
    super.initState();
    _createRecognizer();
  }

  @override
  void didUpdateWidget(covariant SwipeBackScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.triggerDistance != widget.triggerDistance) {
      _drag?.dispose();
      _createRecognizer();
    }
  }

  void _createRecognizer() {
    _drag = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = (_) {
        _dx = 0;
        _triggered = false;
      }
      ..onUpdate = (details) {
        if (!widget.enabled) return;
        _dx += details.delta.dx;
        if (_dx < 0) _dx = 0;
        if (_triggered) return;
        if (_dx < widget.triggerDistance) return;
        _triggered = true;
        widget.onBack();
      }
      ..onEnd = (_) {
        _dx = 0;
        _triggered = false;
      }
      ..onCancel = () {
        _dx = 0;
        _triggered = false;
      };
  }

  @override
  void dispose() {
    _drag?.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    _drag?.addPointer(event);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          left: 0,
          top: widget.topInset,
          bottom: 0,
          width: widget.edgeWidth,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _handlePointerDown,
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}
