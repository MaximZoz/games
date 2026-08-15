import 'package:flutter/material.dart';

/// Куда класть чужие hole cards, чтобы они не уезжали за край экрана.
enum PokerOppHolePlacement {
  /// Справа от профиля (для мест на левой кромке — к центру стола).
  inwardRight,

  /// Слева от профиля (для мест на правой кромке — к центру стола).
  inwardLeft,

  /// Над профилем (нижние боковые места — к центру стола, не в бок).
  above,
}

/// Якоря соперников на кромке фетра.
/// 6-max: два слева и два справа (низ + верх), центр свободен под борд.
List<Alignment> pokerOpponentSeatAnchors(int n) {
  switch (n) {
    case 0:
      return const [];
    case 1:
      return const [Alignment(0, -1.0)];
    case 2:
      return const [Alignment(-0.92, -0.82), Alignment(0.92, -0.82)];
    case 3:
      return const [
        Alignment(-1.0, -0.48),
        Alignment(0, -1.0),
        Alignment(1.0, -0.48),
      ];
    case 4:
      return const [
        Alignment(-0.95, 0.48),
        Alignment(-0.88, -0.82),
        Alignment(0.88, -0.82),
        Alignment(0.95, 0.48),
      ];
    default:
      return const [
        Alignment(-0.95, 0.52),
        Alignment(-0.88, -0.78),
        Alignment(0, -1.0),
        Alignment(0.88, -0.78),
        Alignment(0.95, 0.52),
      ];
  }
}

/// Нижняя половина — карты сверху; боковые — к центру стола, не за край.
PokerOppHolePlacement pokerOppHolePlacement(Alignment align) {
  if (align.y > 0.15) return PokerOppHolePlacement.above;
  if (align.x < -0.05) return PokerOppHolePlacement.inwardRight;
  if (align.x > 0.05) return PokerOppHolePlacement.inwardLeft;
  return PokerOppHolePlacement.inwardRight;
}

/// Смещение hole cards от левого-верхнего угла неймплейта.
Offset pokerOppHoleOffset({
  required Alignment align,
  required double plateWidth,
  required double cardsWidth,
  required double cardsHeight,
  double gap = 4,
}) {
  switch (pokerOppHolePlacement(align)) {
    case PokerOppHolePlacement.above:
      return Offset((plateWidth - cardsWidth) / 2, -cardsHeight - gap);
    case PokerOppHolePlacement.inwardRight:
      return Offset(plateWidth + gap, 0);
    case PokerOppHolePlacement.inwardLeft:
      return Offset(-cardsWidth - gap, 0);
  }
}
