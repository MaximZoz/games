/// Места соперников относительно героя (снизу стола).
///
/// Как в дураке: следующий по направлению хода слева, предыдущий справа,
/// третий (на четверых) сверху. [direction] > 0 — по часовой.
List<int> unoOpponentSeatOrder({
  required int myIndex,
  required int playerCount,
  int direction = 1,
}) {
  if (playerCount < 2 || myIndex < 0 || myIndex >= playerCount) {
    return const [];
  }
  final clockwise = [
    for (var i = 1; i < playerCount; i++) (myIndex + i) % playerCount,
  ];
  if (direction >= 0) return clockwise;
  return clockwise.reversed.toList(growable: false);
}

/// Соперники по боковым колонкам (телефон в альбоме).
///
/// Под столом остаётся ~150 px по высоте: карточка сверху съедает её целиком,
/// и овал с колодой и сбросом перестаёт помещаться. Поэтому все соперники
/// уходят на кромки — первая половина списка слева, остаток справа.
///
/// Возвращает `[левая колонка, правая колонка]`.
List<List<int>> unoLandscapeSideColumns(List<int> seats) {
  if (seats.isEmpty) return const [[], []];
  final leftCount = (seats.length / 2).ceil();
  return [
    seats.take(leftCount).toList(growable: false),
    seats.skip(leftCount).toList(growable: false),
  ];
}
