import 'dart:math';

import 'package:flutter/material.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';

/// Веер карт игрока. При наведении/касании карта под пальцем «раздвигает»
/// соседние и приподнимается; при вертикальном драге следует за пальцем.
class CardFan extends StatefulWidget {
  const CardFan({
    super.key,
    required this.cards,
    required this.cardSize,
    this.enabled = true,
    this.legalCards,
    this.onTap,
    this.onDrag,
    this.faceDown = false,
    this.arc = 0.25,
    this.spacing,
  });

  final List<PlayingCard> cards;
  final Size cardSize;
  final bool enabled;
  final Set<PlayingCard>? legalCards;
  final ValueChanged<PlayingCard>? onTap;
  final void Function(PlayingCard card, DragEndDetails details)? onDrag;
  final bool faceDown;
  final double arc;
  final double? spacing;

  @override
  State<CardFan> createState() => _CardFanState();
}

class _CardFanState extends State<CardFan> {
  int? _hoverIndex;
  int? _dragIndex;
  double _dragDy = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return SizedBox(
          width: widget.cardSize.width, height: widget.cardSize.height);
    }
    final n = widget.cards.length;
    final baseSpacing = widget.spacing ??
        (n == 1 ? 0 : widget.cardSize.width * (n > 8 ? 0.32 : 0.55));
    final totalW = widget.cardSize.width + baseSpacing * (n - 1);
    final height = widget.cardSize.height * 1.45;

    return SizedBox(
      height: height,
      width: totalW + 32,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          for (int i = 0; i < n; i++) _positioned(i, n, baseSpacing),
        ],
      ),
    );
  }

  Widget _positioned(int i, int n, double baseSpacing) {
    final center = (n - 1) / 2;
    final offsetX = (i - center) * baseSpacing;
    final angle = n == 1 ? 0.0 : (i - center) * (widget.arc / max(n - 1, 1));

    var extraX = 0.0;
    var extraY = 0.0;
    var scale = 1.0;
    final activeIndex = _dragIndex ?? _hoverIndex;
    final active = activeIndex != null && i == activeIndex;
    if (activeIndex != null && !active) {
      final dir = i > activeIndex ? 1 : -1;
      final distance = (i - activeIndex).abs();
      extraX = dir * widget.cardSize.width * (0.38 / distance);
    }
    if (active) {
      if (_dragIndex == i) {
        extraY =
            -_dragDy.clamp(0.0, widget.cardSize.height * 1.1).toDouble();
        scale = 1.08;
      } else {
        extraY = -widget.cardSize.height * 0.2;
        scale = 1.06;
      }
    }

    final card = widget.cards[i];
    final legal = widget.legalCards?.contains(card) ?? true;
    final isLegalContext = widget.legalCards != null;

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
        setState(() => _hoverIndex = i);
      },
      onExit: (_) {
        if (!widget.enabled || _dragIndex != null) return;
        setState(() {
          if (_hoverIndex == i) _hoverIndex = null;
        });
      },
      cursor: widget.enabled && legal
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (!widget.enabled) return;
          setState(() => _hoverIndex = i);
        },
        onTapCancel: () {
          if (!widget.enabled) return;
          setState(() {
            if (_hoverIndex == i) _hoverIndex = null;
          });
        },
        onTap: !widget.enabled || widget.faceDown
            ? null
            : () {
                setState(() {
                  _hoverIndex = null;
                  _dragIndex = null;
                  _dragDy = 0;
                });
                if (legal) widget.onTap?.call(card);
              },
        onVerticalDragStart: !widget.enabled || widget.faceDown || !legal
            ? null
            : (_) {
                setState(() {
                  _dragIndex = i;
                  _hoverIndex = i;
                  _dragDy = 0;
                });
              },
        onVerticalDragUpdate: !widget.enabled || widget.faceDown || !legal
            ? null
            : (details) {
                setState(() {
                  // Тянем вверх — отрицательный delta.dy.
                  _dragDy = (_dragDy - details.delta.dy)
                      .clamp(0.0, widget.cardSize.height * 1.2)
                      .toDouble();
                });
              },
        onVerticalDragEnd: !widget.enabled || widget.faceDown
            ? null
            : (details) {
                final played = legal &&
                    _dragDy > widget.cardSize.height * 0.35 &&
                    widget.onDrag != null;
                final draggedCard = card;
                setState(() {
                  _dragIndex = null;
                  _hoverIndex = null;
                  _dragDy = 0;
                });
                if (played) {
                  widget.onDrag!(draggedCard, details);
                }
              },
        onVerticalDragCancel: () {
          setState(() {
            _dragIndex = null;
            _hoverIndex = null;
            _dragDy = 0;
          });
        },
        child: child,
      ),
    );

    return AnimatedPositioned(
      key: ValueKey('fan-$i-${card.toString()}-${widget.faceDown}'),
      duration: _dragIndex == i
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      left: totalWidth(n, baseSpacing) / 2 + offsetX + extraX,
      bottom: extraY,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: Transform.rotate(
          angle: active && _dragIndex == i ? 0 : angle,
          child: child,
        ),
      ),
    );
  }

  double totalWidth(int n, double baseSpacing) {
    return widget.cardSize.width + baseSpacing * (n - 1);
  }
}
