import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';

/// Колода: стопка рубашек + козырь боком, смотрящий вправо.
/// Когда колода пуста — остаётся только значок козырной масти.
class DurakDeckPile extends StatelessWidget {
  const DurakDeckPile({
    super.key,
    required this.deckCount,
    required this.trumpCard,
    required this.cardSize,
    this.trumpSuit,
  });

  final int deckCount;
  final PlayingCard trumpCard;
  final Size cardSize;

  /// Явная масть козыря (если колода пуста и карта уже ушла в руку).
  final Suit? trumpSuit;

  Suit get _suit => trumpSuit ?? trumpCard.suit;

  @override
  Widget build(BuildContext context) {
    if (deckCount <= 0) {
      return SizedBox(
        width: cardSize.width + 8,
        height: cardSize.height + 8,
        child: Center(
          child: DurakTrumpSuitBadge(
            suit: _suit,
            size: math.min(cardSize.width, cardSize.height) * 0.72,
          ),
        ),
      );
    }

    final stackN = math.min(deckCount, 5);
    final w = cardSize.width + 40;
    final h = cardSize.height + 28;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Козырь справа, лицом вправо (peek из-под колоды).
          Positioned(
            right: 0,
            top: (h - cardSize.width) / 2,
            child: Transform.rotate(
              angle: -math.pi / 2,
              child: PlayingCardWidget(
                card: trumpCard,
                size: cardSize,
                elevated: true,
              ),
            ),
          ),
          // Стопка рубашек слева поверх козыря.
          Positioned(
            left: 4,
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
            left: 0,
            child: _CountBadge(count: deckCount),
          ),
        ],
      ),
    );
  }
}

/// Отбой: едва виднеется справа — компактная хаотичная куча без счётчика.
class DurakBitoPile extends StatelessWidget {
  const DurakBitoPile({
    super.key,
    required this.count,
    required this.cardSize,
    this.peek = true,
  });

  final int count;
  final Size cardSize;

  /// Если true — куча почти за краем, занимает мало места за столом.
  final bool peek;

  @override
  Widget build(BuildContext context) {
    final peekW = peek ? cardSize.width * 0.38 : cardSize.width * 1.35;
    final areaH = cardSize.height * (peek ? 1.05 : 1.25);
    if (count <= 0) {
      return SizedBox(width: peekW, height: areaH);
    }

    final shown = math.min(count, 14);
    final areaW = cardSize.width * (1.15 + 0.4 * (shown / 14));

    final pile = SizedBox(
      width: areaW,
      height: areaH,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < shown; i++)
            _scatteredCard(
              index: i,
              shown: shown,
              areaW: areaW,
              areaH: areaH,
            ),
        ],
      ),
    );

    if (!peek) return pile;

    // Виден только левый край кучи.
    return SizedBox(
      width: peekW,
      height: areaH,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          maxWidth: areaW,
          child: pile,
        ),
      ),
    );
  }

  Widget _scatteredCard({
    required int index,
    required int shown,
    required double areaW,
    required double areaH,
  }) {
    final rng = math.Random(9001 + index * 9973);
    final angle = (rng.nextDouble() - 0.5) * 1.2;
    final dx = (rng.nextDouble() - 0.5) * (areaW - cardSize.width) * 0.7;
    final dy = (rng.nextDouble() - 0.5) * (areaH - cardSize.height) * 0.65;
    final lift = index / math.max(shown, 1);
    return Positioned(
      left: areaW / 2 - cardSize.width / 2 + dx,
      top: areaH / 2 - cardSize.height / 2 + dy - lift * 3,
      child: Transform.rotate(
        angle: angle,
        child: Opacity(
          opacity: 0.92,
          child: CardBackWidget(
            size: Size(cardSize.width * 0.92, cardSize.height * 0.92),
            elevated: index == shown - 1,
          ),
        ),
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
