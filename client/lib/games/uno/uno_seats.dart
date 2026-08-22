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
