import 'dart:math';

import 'package:flutter/material.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';

/// Веер карт игрока.
///
/// - Тап / наведение: карта плавно выезжает **вверх** из веера.
/// - Свайп по вееру: под пальцем поднимается текущая карта.
/// - Вертикальный драг вверх + отпускание: карта «сыграна».
class CardFan extends StatefulWidget {
  const CardFan({
    super.key,
    required this.cards,
    required this.cardSize,
    this.enabled = true,
    this.legalCards,
    this.onTap,
    this.onDrag,
    this.onActiveChanged,
    this.faceDown = false,
    this.arc,
    this.spacing,
  });

  final List<PlayingCard> cards;
  final Size cardSize;
  final bool enabled;
  final Set<PlayingCard>? legalCards;
  final ValueChanged<PlayingCard>? onTap;
  final void Function(PlayingCard card, DragEndDetails details)? onDrag;

  /// Какая карта сейчас под пальцем / наведена (для подсветки целей на столе).
  final ValueChanged<PlayingCard?>? onActiveChanged;

  final bool faceDown;

  /// Угол дуги веера (рад на весь веер). Null — подобрать по числу карт.
  final double? arc;
  final double? spacing;

  @override
  State<CardFan> createState() => _CardFanState();
}

class _CardFanState extends State<CardFan> {
  int? _hoverIndex;
  int? _dragIndex;
  double _dragDy = 0;

  void _emitActive(int? index) {
    final card = index == null || index < 0 || index >= widget.cards.length
        ? null
        : widget.cards[index];
    final legal = card == null
        ? null
        : (widget.legalCards == null || widget.legalCards!.contains(card)
            ? card
            : null);
    widget.onActiveChanged?.call(legal);
  }

  void _setHover(int? index) {
    if (_hoverIndex == index) return;
    setState(() => _hoverIndex = index);
    if (_dragIndex == null) _emitActive(index);
  }

  void _clearInteraction() {
    setState(() {
      _dragIndex = null;
      _hoverIndex = null;
      _dragDy = 0;
    });
    widget.onActiveChanged?.call(null);
  }

  double _spacingFor(int n) {
    if (widget.spacing != null) return widget.spacing!;
    if (n <= 1) return 0;
    final w = widget.cardSize.width;
    if (n > 24) return w * 0.16;
    if (n > 18) return w * 0.2;
    if (n > 14) return w * 0.24;
    if (n > 10) return w * 0.3;
    if (n > 7) return w * 0.38;
    return w * 0.52;
  }

  double _arcFor(int n) {
    if (widget.arc != null) return widget.arc!;
    if (n <= 1) return 0;
    if (n > 20) return 0.55;
    if (n > 12) return 0.42;
    if (n > 8) return 0.32;
    return 0.22;
  }

  bool _isLegal(PlayingCard card) =>
      widget.legalCards == null || widget.legalCards!.contains(card);

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return SizedBox(
        width: widget.cardSize.width,
        height: widget.cardSize.height,
      );
    }
    final n = widget.cards.length;
    final baseSpacing = _spacingFor(n);
    final totalW = widget.cardSize.width + baseSpacing * (n - 1);
    final height = widget.cardSize.height * 1.55;

    return SizedBox(
      height: height,
      width: totalW + 32,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          for (int i = 0; i < n; i++)
            _positioned(i, n, baseSpacing, totalW, _arcFor(n)),
        ],
      ),
    );
  }

  Widget _positioned(
    int i,
    int n,
    double baseSpacing,
    double totalW,
    double arc,
  ) {
    final center = (n - 1) / 2;
    final offsetX = (i - center) * baseSpacing;
    final angle = n == 1 ? 0.0 : (i - center) * (arc / max(n - 1, 1));

    var extraX = 0.0;
    // Положительный bottom = карта выше (выезжает из веера вверх).
    var extraY = 0.0;
    var scale = 1.0;
    final activeIndex = _dragIndex ?? _hoverIndex;
    final active = activeIndex != null && i == activeIndex;
    if (activeIndex != null && !active) {
      final dir = i > activeIndex ? 1 : -1;
      final distance = (i - activeIndex).abs();
      extraX = dir * widget.cardSize.width * (0.32 / max(distance, 1));
    }
    if (active) {
      if (_dragIndex == i) {
        extraY = _dragDy.clamp(0.0, widget.cardSize.height * 1.2).toDouble();
        scale = 1.1;
      } else {
        extraY = widget.cardSize.height * 0.22;
        scale = 1.06;
      }
    }

    final card = widget.cards[i];
    final legal = _isLegal(card);
    final isLegalContext = widget.legalCards != null;
    final canPlay = widget.enabled && !widget.faceDown && legal;

    Widget child = widget.faceDown
        ? CardBackWidget(size: widget.cardSize, elevated: active)
        : PlayingCardWidget(
            card: card,
            size: widget.cardSize,
            highlighted: active && (!isLegalContext || legal),
            dimmed: isLegalContext && !legal,
            elevated: active,
          );

    child = MouseRegion(
      onEnter: (_) {
        if (!widget.enabled || _dragIndex != null) return;
        _setHover(i);
      },
      onExit: (_) {
        if (!widget.enabled || _dragIndex != null) return;
        if (_hoverIndex == i) _setHover(null);
      },
      cursor: canPlay ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled
            ? (_) => _setHover(i)
            : null,
        onTapCancel: widget.enabled
            ? () {
                if (_hoverIndex == i && _dragIndex == null) _setHover(null);
              }
            : null,
        onTap: !canPlay
            ? null
            : () {
                _clearInteraction();
                widget.onTap?.call(card);
              },
        onVerticalDragStart: !canPlay
            ? null
            : (_) {
                setState(() {
                  _dragIndex = i;
                  _hoverIndex = i;
                  _dragDy = 0;
                });
                _emitActive(i);
              },
        onVerticalDragUpdate: !canPlay
            ? null
            : (details) {
                setState(() {
                  // Палец вверх → карта выше (положительный bottom).
                  _dragDy = (_dragDy - details.delta.dy)
                      .clamp(0.0, widget.cardSize.height * 1.25)
                      .toDouble();
                });
              },
        onVerticalDragEnd: !widget.enabled || widget.faceDown
            ? null
            : (details) {
                final played = canPlay &&
                    _dragDy > widget.cardSize.height * 0.28 &&
                    widget.onDrag != null;
                final dragged = card;
                _clearInteraction();
                if (played) widget.onDrag!(dragged, details);
              },
        onVerticalDragCancel: () {
          _clearInteraction();
        },
        // Горизонтальный свайп по вееру — переключаем «поднятую» карту.
        onHorizontalDragUpdate: !widget.enabled || widget.faceDown
            ? null
            : (details) {
                if (_dragIndex != null) return;
                final box = context.findRenderObject() as RenderBox?;
                if (box == null) return;
                final local = box.globalToLocal(details.globalPosition);
                final idx = _indexAtLocalX(
                  local.dx,
                  n,
                  baseSpacing,
                  totalW,
                );
                _setHover(idx);
              },
        child: child,
      ),
    );

    return AnimatedPositioned(
      key: ValueKey('fan-$i-${card.rank.value}-${card.suit.name}'),
      duration: _dragIndex == i
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      left: totalW / 2 + offsetX + extraX,
      bottom: extraY,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: Transform.rotate(
          angle: active && _dragIndex == i ? 0 : angle,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ),
    );
  }

  int _indexAtLocalX(double localX, int n, double baseSpacing, double totalW) {
    if (n <= 0) return 0;
    final center = (n - 1) / 2.0;
    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < n; i++) {
      final left = totalW / 2 + (i - center) * baseSpacing;
      final cx = left + widget.cardSize.width / 2;
      final d = (localX - cx).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }
}

/// Глобальный rect активной/первой карты веера — для анимации полёта.
Rect? cardFanApproxOrigin(BuildContext fanContext, Size cardSize) {
  final box = fanContext.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  final origin = box.localToGlobal(Offset.zero);
  return Rect.fromLTWH(
    origin.dx + box.size.width / 2 - cardSize.width / 2,
    origin.dy + box.size.height - cardSize.height - cardSize.height * 0.22,
    cardSize.width,
    cardSize.height,
  );
}
