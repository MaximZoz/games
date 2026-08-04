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

/// Отбой: хаотичная куча рубашек без счётчика. Чем больше карт — тем больше куча.
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
      return SizedBox(
        width: cardSize.width * 1.4,
        height: cardSize.height * 1.25,
      );
    }

    // Показываем до 18 «слоёв» — куча растёт визуально с числом карт.
    final shown = math.min(count, 18);
    final spread = 0.35 + 0.55 * (shown / 18);
    final areaW = cardSize.width * (1.35 + spread * 0.9);
    final areaH = cardSize.height * (1.2 + spread * 0.7);

    return SizedBox(
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
  }

  Widget _scatteredCard({
    required int index,
    required int shown,
    required double areaW,
    required double areaH,
  }) {
    // Стабильный seed на индекс — при росте кучи старые карты не прыгают.
    final rng = math.Random(9001 + index * 9973);
    final angle = (rng.nextDouble() - 0.5) * 1.35;
    final dx = (rng.nextDouble() - 0.5) * (areaW - cardSize.width) * 0.85;
    final dy = (rng.nextDouble() - 0.5) * (areaH - cardSize.height) * 0.75;
    final lift = index / math.max(shown, 1);
    return Positioned(
      left: areaW / 2 - cardSize.width / 2 + dx,
      top: areaH / 2 - cardSize.height / 2 + dy - lift * 4,
      child: Transform.rotate(
        angle: angle,
        child: CardBackWidget(
          size: cardSize,
          elevated: index == shown - 1,
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
