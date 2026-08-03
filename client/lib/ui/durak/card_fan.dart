import 'dart:math';

import 'package:flutter/material.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';

/// Веер карт игрока. При наведении/касании карта под пальцем «раздвигает»
/// соседние и приподнимается — удобно выбирать в большом веере.
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

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return SizedBox(width: widget.cardSize.width, height: widget.cardSize.height);
    }
    final n = widget.cards.length;
    final baseSpacing = widget.spacing ??
        (n == 1 ? 0 : widget.cardSize.width * (n > 8 ? 0.32 : 0.55));
    final totalW = widget.cardSize.width + baseSpacing * (n - 1);
    final height = widget.cardSize.height * 1.15;

    return SizedBox(
      height: height,
      width: totalW + 32,
      child: Stack(
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
    final hovered = _hoverIndex != null && i == _hoverIndex;
    if (_hoverIndex != null && !hovered) {
      // Соседи раздвигаются, чтобы hovered карта была видна.
      final dir = i > _hoverIndex! ? 1 : -1;
      final distance = (i - _hoverIndex!).abs();
      extraX = dir * widget.cardSize.width * (0.35 / distance);
    }
    if (hovered) {
      extraY = -widget.cardSize.height * 0.18;
      scale = 1.05;
    }

    final card = widget.cards[i];
    final legal = widget.legalCards?.contains(card) ?? true;
    final isLegalContext = widget.legalCards != null;

    Widget child = widget.faceDown
        ? CardBackWidget(size: widget.cardSize, elevated: hovered)
        : PlayingCardWidget(
            card: card,
            size: widget.cardSize,
            highlighted: hovered && (!isLegalContext || legal),
            dimmed: isLegalContext && !legal,
            elevated: hovered,
          );

    child = MouseRegion(
      onEnter: (_) {
        if (!widget.enabled) return;
        setState(() => _hoverIndex = i);
      },
      onExit: (_) {
        if (!widget.enabled) return;
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
                setState(() => _hoverIndex = null);
                if (legal) widget.onTap?.call(card);
              },
        onVerticalDragEnd: !widget.enabled || widget.faceDown
            ? null
            : (details) {
                if (legal) widget.onDrag?.call(card, details);
                setState(() {
                  if (_hoverIndex == i) _hoverIndex = null;
                });
              },
        child: child,
      ),
    );

    return AnimatedPositioned(
      key: ValueKey('fan-$i-${card.toString()}-${widget.faceDown}'),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      left: totalWidth(n, baseSpacing) / 2 + offsetX + extraX,
      bottom: extraY,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: Transform.rotate(
          angle: angle,
          child: child,
        ),
      ),
    );
  }

  double totalWidth(int n, double baseSpacing) {
    return widget.cardSize.width + baseSpacing * (n - 1);
  }
}
