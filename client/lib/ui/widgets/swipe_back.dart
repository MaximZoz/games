import 'package:flutter/material.dart';

/// Свайп от левого края вправо — то же действие, что у кнопки «Назад».
///
/// Срабатывает сразу при достаточном смещении пальца (не ждёт отпускания).
/// Крайняя полоса с [HitTestBehavior.opaque] перехватывает жест раньше
/// горизонтальных ListView / TextField (важно для iOS Safari / Flutter Web).
///
/// Сверху оставляем зону под AppBar / стрелку «Назад», иначе opaque-полоса
/// перехватывает тапы по кнопке. Снизу — [bottomInset] под композер / нижние
/// кнопки (иначе тап по смайлику слева «проглатывается»).
class SwipeBackScope extends StatefulWidget {
  const SwipeBackScope({
    super.key,
    required this.onBack,
    required this.child,
    this.enabled = true,
    this.edgeWidth = 48,
    this.triggerDistance = 20,
    this.topInset,
    this.bottomInset = 0,
    this.opaqueEdge = true,
  });

/// Игровой экран: узкая прозрачная полоса и длинный свайп.
///
/// Новые партии подключать только так. Обычный [SwipeBackScope] — непрозрачные
/// 48px: тап по крайней левой кости, карте или клетке не доходит.
/// Поле занимает весь экран, и широкая полоса у левого края съедала тапы
/// вплоть до случайного выхода из партии. Руку у нижнего края вырезают
/// через [bottomInset].
  const SwipeBackScope.gameBoard({
    super.key,
    required this.onBack,
    required this.child,
    this.enabled = true,
    this.topInset,
    this.bottomInset = 0,
  })  : edgeWidth = 16,
        triggerDistance = 44,
        opaqueEdge = false;

  final VoidCallback onBack;
  final Widget child;
  final bool enabled;

  /// Ширина активной зоны у левого края.
  final double edgeWidth;

  /// Насколько нужно провести вправо, чтобы сработало сразу.
  final double triggerDistance;

  /// Отступ сверху под кнопку «Назад» / AppBar.
  /// `null` — автоматически `padding.top + kToolbarHeight`.
  final double? topInset;

  /// Отступ снизу под композер / нижние контролы.
  final double bottomInset;

  /// `true` — зона края всегда в hit-test (удобно против горизонтальных ListView).
  /// `false` — тапы проходят к виджетам под полосой (чекбоксы у левого края).
  final bool opaqueEdge;

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

  void _onDragStart(DragStartDetails _) => _reset();

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || _triggered) return;
    _dx += details.delta.dx;
    if (_dx < 0) _dx = 0;
    if (_dx < widget.triggerDistance) return;
    _triggered = true;
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final excludedTop = widget.topInset ??
        (MediaQuery.paddingOf(context).top + kToolbarHeight);
    final excludedBottom = widget.bottomInset < 0 ? 0.0 : widget.bottomInset;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          left: 0,
          top: excludedTop,
          bottom: excludedBottom,
          width: widget.edgeWidth,
          child: GestureDetector(
            // opaque — перехват до горизонтальных ListView; translucent — тапы
            // доходят до контролов под полосой (чекбокс у левого края формы).
            behavior: widget.opaqueEdge
                ? HitTestBehavior.opaque
                : HitTestBehavior.translucent,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: (_) => _reset(),
            onHorizontalDragCancel: _reset,
          ),
        ),
      ],
    );
  }
}
