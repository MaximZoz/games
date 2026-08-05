import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';

/// Колода «плиточкой»: рубашки со сдвигом, уголки выглядывают; козырь лицом вправо.
///
/// - `deckCount >= 2` — стопка рубашек + козырь
/// - `deckCount == 1` — только козырь лицом
/// - `deckCount == 0` — только значок масти
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
    final showTrumpFace = deckCount >= 1;
    // Сколько «плиток» показать (уголки должны читаться).
    final stackN = deckCount <= 1 ? 0 : math.min(deckCount, 6);
    final stepX = cardSize.width * 0.085;
    final stepY = cardSize.height * 0.055;
    final badgeSize = math.min(cardSize.width, cardSize.height) * 0.34;

    // Ширина: стопка + выглядывающий козырь.
    final stackW = cardSize.width + stepX * math.max(stackN - 1, 0);
    final layoutW = showTrumpFace
        ? stackW * 0.72 + cardSize.height * 0.78
        : math.max(stackW, badgeSize + 12);
    final h = math.max(
      cardSize.height + stepY * math.max(stackN - 1, 0) + 16,
      cardSize.width + 20,
    );

    return SizedBox(
      width: layoutW,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Козырь под стопкой, повёрнут — выглядывает вправо уголком/лицом.
          if (showTrumpFace)
            Positioned(
              left: stackW * 0.42,
              top: (h - cardSize.width) / 2 + 2,
              child: Transform.rotate(
                angle: -math.pi / 2,
                child: PlayingCardWidget(
                  card: trumpCard,
                  size: cardSize,
                  elevated: true,
                ),
              ),
            )
          else
            Positioned(
              left: 8,
              top: (h - badgeSize) / 2,
              child: DurakTrumpSuitBadge(
                suit: _suit,
                size: badgeSize,
              ),
            ),
          // Плитки рубашек: диагональный сдвиг + лёгкий поворот — видны уголки.
          if (stackN > 0)
            Positioned(
              left: 0,
              top: (h - cardSize.height - stepY * (stackN - 1)) / 2,
              child: SizedBox(
                width: stackW + 8,
                height: cardSize.height + stepY * (stackN - 1) + 8,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < stackN; i++)
                      Positioned(
                        left: i * stepX,
                        top: i * stepY,
                        child: Transform.rotate(
                          angle: -0.10 + i * 0.02,
                          alignment: Alignment.bottomLeft,
                          child: CardBackWidget(
                            size: cardSize,
                            elevated: i == stackN - 1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (deckCount > 1)
            Positioned(
              bottom: 0,
              left: stackW * 0.18,
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
    final peekW = peek ? cardSize.width * 0.62 : cardSize.width * 1.35;
    final areaH = cardSize.height * (peek ? 1.12 : 1.25);
    if (count <= 0) {
      return SizedBox(width: peekW, height: areaH);
    }

    // Одна карта в отбое — просто лежит, без «кучи».
    if (count == 1) {
      final card = Transform.rotate(
        angle: 0.18,
        child: CardBackWidget(
          size: Size(cardSize.width * 0.92, cardSize.height * 0.92),
          elevated: true,
        ),
      );
      if (!peek) {
        return SizedBox(
          width: peekW,
          height: areaH,
          child: Center(child: card),
        );
      }
      return SizedBox(
        width: peekW,
        height: areaH,
        child: Align(
          alignment: Alignment.centerLeft,
          child: card,
        ),
      );
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

    return SizedBox(
      width: peekW,
      height: areaH,
      child: OverflowBox(
        alignment: Alignment.centerLeft,
        maxWidth: areaW,
        child: pile,
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
