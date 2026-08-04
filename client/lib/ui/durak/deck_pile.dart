import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';

/// Колода: козырь боком + стопка рубашек со счётчиком.
/// Общий виджет для онлайн- и офлайн-экрана Дурака.
class DurakDeckPile extends StatelessWidget {
  const DurakDeckPile({
    super.key,
    required this.deckCount,
    required this.trumpCard,
    required this.cardSize,
  });

  final int deckCount;
  final PlayingCard trumpCard;
  final Size cardSize;

  @override
  Widget build(BuildContext context) {
    if (deckCount <= 0) {
      // Козырь остаётся лицом вверх, когда колода кончилась.
      return SizedBox(
        width: cardSize.width + 8,
        height: cardSize.height + 8,
        child: Center(
          child: PlayingCardWidget(
            card: trumpCard,
            size: Size(cardSize.width * 0.85, cardSize.height * 0.85),
          ),
        ),
      );
    }

    final stackN = math.min(deckCount, 5);
    final w = cardSize.width + 36;
    final h = cardSize.height + 28;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Козырь лежит боком под колодой (peek).
          Positioned(
            left: 0,
            top: (h - cardSize.width) / 2,
            child: Transform.rotate(
              angle: math.pi / 2,
              child: PlayingCardWidget(
                card: trumpCard,
                size: cardSize,
                elevated: true,
              ),
            ),
          ),
          // Стопка рубашек со смещением — объём колоды.
          Positioned(
            right: 4,
            top: 4,
            child: SizedBox(
              width: cardSize.width + stackN * 1.6,
              height: cardSize.height + stackN * 1.6,
              child: Stack(
                children: [
                  for (var i = 0; i < stackN; i++)
                    Positioned(
                      left: i * 1.6,
                      top: i * 1.6,
                      child: CardBackWidget(
                        size: cardSize,
                        elevated: i == stackN - 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: _CountBadge(count: deckCount),
          ),
        ],
      ),
    );
  }
}

/// Отбой: веер рубашек со счётчиком.
class DurakBitoPile extends StatelessWidget {
  const DurakBitoPile({
    super.key,
    required this.count,
    required this.cardSize,
  });

  final int count;
  final Size cardSize;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return SizedBox(width: cardSize.width, height: cardSize.height);
    }
    final stackN = math.min(count, 4);
    return SizedBox(
      width: cardSize.width + 16,
      height: cardSize.height + 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < stackN; i++)
            Positioned(
              left: i * 1.4,
              top: i * 1.2,
              child: Transform.rotate(
                angle: 0.1 * (i.isEven ? 1 : -1),
                child: CardBackWidget(
                  size: cardSize,
                  elevated: i == stackN - 1,
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 2,
            child: _CountBadge(count: count),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
