import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion/game_motion.dart';

/// Геометрия руки одной полосой — чистая, без виджетов.
///
/// Нужна отдельно от [GameHandStrip]: стол считает по ней, куда прилетит
/// взятая фишка, ещё до того как рука перестроилась.
class GameHandStripMetrics {
  const GameHandStripMetrics({
    required this.viewport,
    required this.itemSize,
    required this.height,
    this.spacing = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  /// Видимая ширина полосы.
  final double viewport;
  final Size itemSize;
  final double height;
  final double spacing;
  final EdgeInsets padding;

  double rowWidth(int count) => count <= 0
      ? 0
      : count * itemSize.width + (count - 1) * spacing;

  /// Рука из [count] фишек шире экрана и листается.
  bool scrollable(int count) =>
      rowWidth(count) + padding.horizontal > viewport + 0.5;

  double maxScroll(int count) =>
      math.max(0.0, rowWidth(count) + padding.horizontal - viewport);

  /// Куда докрутить, чтобы фишка [index] была видна целиком.
  double revealOffset(int index, {required int count, double current = 0}) {
    if (!scrollable(count)) return 0;
    final left = padding.left + index * (itemSize.width + spacing);
    final right = left + itemSize.width;
    var target = current;
    if (left - padding.left < target) target = left - padding.left;
    if (right + padding.right > target + viewport) {
      target = right + padding.right - viewport;
    }
    return target.clamp(0.0, maxScroll(count));
  }

  /// Рамка фишки [index] в координатах полосы.
  Rect itemRect(int index, {required int count, double scroll = 0}) {
    final row = rowWidth(count);
    final free = viewport - padding.horizontal - row;
    final rowLeft = scrollable(count)
        ? padding.left - scroll.clamp(0.0, maxScroll(count))
        : padding.left + math.max(0.0, free) / 2;
    return Rect.fromLTWH(
      rowLeft + index * (itemSize.width + spacing),
      (height - itemSize.height) / 2,
      itemSize.width,
      itemSize.height,
    );
  }
}

/// Рука игрока одной полосой: фишки крупные, с зазором под палец.
///
/// Пока всё помещается — рука по центру. Когда фишек много, полоса листается,
/// а края мягко гаснут, подсказывая, что дальше есть ещё.
class GameHandStrip extends StatefulWidget {
  const GameHandStrip({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.itemSize,
    required this.height,
    this.spacing = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.itemKeyBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// Постоянный ключ фишки (например её id). С ним соседи плавно съезжаются,
  /// когда фишка ушла из руки, и раздвигаются, когда пришла новая.
  final Object Function(int index)? itemKeyBuilder;
  final Size itemSize;
  final double height;

  /// Зазор между фишками.
  final double spacing;
  final EdgeInsets padding;

  @override
  State<GameHandStrip> createState() => GameHandStripState();
}

class GameHandStripState extends State<GameHandStrip>
    with SingleTickerProviderStateMixin {
  final ScrollController _controller = ScrollController();
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: GameMotion.settle,
    value: 1,
  );
  double _viewport = 0;

  /// На сколько каждая фишка стояла левее/правее до перестройки руки.
  Map<Object, double> _shift = const <Object, double>{};

  @override
  void didUpdateWidget(covariant GameHandStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final keyOf = widget.itemKeyBuilder;
    final oldKeyOf = oldWidget.itemKeyBuilder;
    if (keyOf == null || oldKeyOf == null || _viewport <= 0) return;
    if (oldWidget.itemCount == widget.itemCount) return;
    final before = GameHandStripMetrics(
      viewport: _viewport,
      itemSize: oldWidget.itemSize,
      height: oldWidget.height,
      spacing: oldWidget.spacing,
      padding: oldWidget.padding,
    );
    final after = metrics;
    final scroll = scrollOffset;
    final left = <Object, double>{
      for (var i = 0; i < oldWidget.itemCount; i++)
        oldKeyOf(i):
            before.itemRect(i, count: oldWidget.itemCount, scroll: scroll).left,
    };
    final shift = <Object, double>{};
    for (var i = 0; i < widget.itemCount; i++) {
      final key = keyOf(i);
      final was = left[key];
      if (was == null) continue;
      final now =
          after.itemRect(i, count: widget.itemCount, scroll: scroll).left;
      if ((was - now).abs() > 0.5) shift[key] = was - now;
    }
    if (shift.isEmpty) return;
    _shift = shift;
    _settle.forward(from: 0);
  }

  /// Геометрия полосы по последней вёрстке.
  GameHandStripMetrics get metrics => GameHandStripMetrics(
        viewport: _viewport,
        itemSize: widget.itemSize,
        height: widget.height,
        spacing: widget.spacing,
        padding: widget.padding,
      );

  /// Текущая прокрутка руки.
  double get scrollOffset =>
      _controller.hasClients ? _controller.position.pixels : 0;

  /// Плавно докрутить руку до фишки [index].
  void reveal(int index) {
    if (!_controller.hasClients) return;
    final target = metrics.revealOffset(
      index,
      count: widget.itemCount,
      current: scrollOffset,
    );
    if ((target - scrollOffset).abs() < 0.5) return;
    _controller.animateTo(
      target,
      duration: GameMotion.settle,
      curve: GameMotion.settleCurve,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _settle.dispose();
    super.dispose();
  }

  Widget _settled(int index, Widget child) {
    final keyOf = widget.itemKeyBuilder;
    if (keyOf == null) return child;
    final key = keyOf(index);
    return AnimatedBuilder(
      animation: _settle,
      child: child,
      builder: (context, child) {
        // Transform стоит всегда: иначе поддерево фишки пересоздавалось бы
        // в начале и в конце каждого сдвига.
        final shift = _shift[key] ?? 0;
        final left = 1 - GameMotion.settleCurve.transform(_settle.value);
        return Transform.translate(
          offset: Offset(shift * left, 0),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _viewport = constraints.maxWidth;
          final scrollable = metrics.scrollable(widget.itemCount);
          final row = Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.itemCount; i++) ...[
                if (i > 0) SizedBox(width: widget.spacing),
                SizedBox.fromSize(
                  size: widget.itemSize,
                  child: _settled(i, widget.itemBuilder(context, i)),
                ),
              ],
            ],
          );
          final scroll = SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: scrollable
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            clipBehavior: Clip.none,
            padding: widget.padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: math.max(
                  0,
                  constraints.maxWidth - widget.padding.horizontal,
                ),
                minHeight: widget.height,
              ),
              child: Center(child: row),
            ),
          );
          if (!scrollable) return scroll;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final max = metrics.maxScroll(widget.itemCount);
              final pixels = scrollOffset.clamp(0.0, max);
              final fadeLeft = pixels > 1;
              final fadeRight = pixels < max - 1;
              return ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => LinearGradient(
                  colors: [
                    fadeLeft ? Colors.transparent : Colors.white,
                    Colors.white,
                    Colors.white,
                    fadeRight ? Colors.transparent : Colors.white,
                  ],
                  stops: const [0, 0.07, 0.93, 1],
                ).createShader(rect),
                child: child,
              );
            },
            child: scroll,
          );
        },
      ),
    );
  }
}
