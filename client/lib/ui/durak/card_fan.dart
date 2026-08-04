import 'dart:math';

import 'package:flutter/material.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';

/// Веер карт игрока.
///
/// - Тап / удержание: карта плавно выезжает **вверх** из веера.
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
  int? _pointer;
  double _pointerUpAccum = 0;
  final Map<int, GlobalKey> _cardKeys = {};

  GlobalKey _keyFor(int i) => _cardKeys.putIfAbsent(i, GlobalKey.new);

  @override
  void didUpdateWidget(covariant CardFan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cards.length != widget.cards.length) {
      _cardKeys.clear();
    }
  }

  void _setActive(int? index) {
    if (_hoverIndex == index && _dragIndex == null) return;
    setState(() => _hoverIndex = index);
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

  void _clearDrag() {
    setState(() {
      _dragIndex = null;
      _hoverIndex = null;
      _dragDy = 0;
      _pointerUpAccum = 0;
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
    // Запас сверху: карта выезжает вверх из веера.
    final height = widget.cardSize.height * 1.55;

    return SizedBox(
      height: height,
      width: totalW + 32,
      child: Listener(
        onPointerDown: !widget.enabled
            ? null
            : (e) {
                _pointer = e.pointer;
                _pointerUpAccum = 0;
                final idx = _indexAtLocalX(
                  e.localPosition.dx,
                  n,
                  baseSpacing,
                  totalW,
                );
                _setActive(idx);
              },
        onPointerMove: !widget.enabled
            ? null
            : (e) {
                if (_pointer != e.pointer) return;
                if (_dragIndex != null) {
                  setState(() {
                    _dragDy = (_dragDy - e.delta.dy)
                        .clamp(0.0, widget.cardSize.height * 1.25)
                        .toDouble();
                  });
                  return;
                }
                // Свайп по вееру — поднимаем карту под пальцем.
                if (e.delta.dy.abs() <= e.delta.dx.abs() + 0.5) {
                  final idx = _indexAtLocalX(
                    e.localPosition.dx,
                    n,
                    baseSpacing,
                    totalW,
                  );
                  _setActive(idx);
                }
                _pointerUpAccum += -e.delta.dy;
                // Набрали достаточно «вверх» — вытягиваем карту из веера.
                if (_pointerUpAccum > widget.cardSize.height * 0.12 &&
                    _hoverIndex != null) {
                  final card = widget.cards[_hoverIndex!];
                  if (_isLegal(card) && !widget.faceDown) {
                    setState(() {
                      _dragIndex = _hoverIndex;
                      _dragDy = _pointerUpAccum
                          .clamp(0.0, widget.cardSize.height * 1.25)
                          .toDouble();
                    });
                  }
                }
              },
        onPointerUp: !widget.enabled
            ? null
            : (e) {
                if (_pointer != e.pointer) return;
                _pointer = null;
                final dragIdx = _dragIndex;
                final hoverIdx = _hoverIndex;
                final dy = _dragDy;
                final playedByDrag = dragIdx != null &&
                    !widget.faceDown &&
                    dy > widget.cardSize.height * 0.28 &&
                    _isLegal(widget.cards[dragIdx]);

                if (playedByDrag) {
                  final card = widget.cards[dragIdx];
                  _clearDrag();
                  widget.onDrag?.call(card, DragEndDetails());
                  return;
                }

                // Короткий тап по легальной карте.
                final tapIdx = dragIdx ?? hoverIdx;
                final wasTap = tapIdx != null &&
                    !widget.faceDown &&
                    dy < widget.cardSize.height * 0.2 &&
                    _pointerUpAccum < widget.cardSize.height * 0.2 &&
                    _isLegal(widget.cards[tapIdx]);
                if (wasTap) {
                  final card = widget.cards[tapIdx];
                  _clearDrag();
                  widget.onTap?.call(card);
                  return;
                }
                _clearDrag();
              },
        onPointerCancel: (_) {
          _pointer = null;
          _clearDrag();
        },
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            for (int i = 0; i < n; i++)
              _positioned(i, n, baseSpacing, totalW, _arcFor(n)),
          ],
        ),
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

    Widget child = widget.faceDown
        ? CardBackWidget(size: widget.cardSize, elevated: active)
        : PlayingCardWidget(
            key: _keyFor(i),
            card: card,
            size: widget.cardSize,
            highlighted: active && (!isLegalContext || legal),
            dimmed: isLegalContext && !legal,
            elevated: active,
          );

    // Карты в веере не ловят жесты сами — Listener на Stack.
    child = IgnorePointer(child: child);

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
}

/// Глобальный rect активной/первой карты веера — для анимации полёта.
Rect? cardFanApproxOrigin(BuildContext fanContext, Size cardSize) {
  final box = fanContext.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  final origin = box.localToGlobal(Offset.zero);
  // Центр нижней зоны веера.
  return Rect.fromLTWH(
    origin.dx + box.size.width / 2 - cardSize.width / 2,
    origin.dy + box.size.height - cardSize.height - cardSize.height * 0.22,
    cardSize.width,
    cardSize.height,
  );
}
