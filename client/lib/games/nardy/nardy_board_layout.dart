import 'package:multigames_client/games/nardy/nardy_engine.dart';

/// Раскладка доски нард на экране в координатах дорожки игрока.
///
/// Классический вид: дом игрока — правый нижний квадрант, движение шашек
/// идёт против часовой стрелки, начиная с правого верхнего угла.
class NardyBoardLayout {
  const NardyBoardLayout._();

  /// Верхний ряд слева направо.
  static const List<int> topRow = [
    11, 10, 9, 8, 7, 6, // левый верхний квадрант
    5, 4, 3, 2, 1, 0, // правый верхний квадрант
  ];

  /// Нижний ряд слева направо.
  static const List<int> bottomRow = [
    12, 13, 14, 15, 16, 17, // левый нижний квадрант
    18, 19, 20, 21, 22, 23, // правый нижний квадрант (дом)
  ];

  /// Сколько пунктов в одном квадранте.
  static const int quadrant = 6;

  /// Пункт дорожки принадлежит дому игрока.
  static bool isHome(int track) => track >= nardyHomeStart;

  /// Пункт стоит справа от бара (для отрисовки разделителя).
  static bool isRightSide(int track) {
    final topIndex = topRow.indexOf(track);
    if (topIndex >= 0) return topIndex >= quadrant;
    final bottomIndex = bottomRow.indexOf(track);
    return bottomIndex >= quadrant;
  }

  /// Все пункты в порядке отрисовки: сначала верхний ряд, затем нижний.
  static List<int> get allTracks => const [...topRow, ...bottomRow];
}

/// Куда встанет шашка с пункта [from] кубиком [die]; `>= 24` — снятие.
int nardyDestinationTrack(int from, int die) {
  if (from == nardyBarTrack) return die - 1;
  return from + die;
}

/// Ход выбрасывает шашку с доски.
bool nardyIsBearOff(int from, int die) =>
    from != nardyBarTrack && from + die >= nardyPoints;
