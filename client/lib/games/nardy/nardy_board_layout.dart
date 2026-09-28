import 'dart:ui' show Offset, Rect, Size;

import 'package:multigames_client/games/nardy/nardy_engine.dart';

/// Раскладка доски нард в координатах дорожки игрока.
///
/// Классическая расстановка коротких нард на экране: слева сверху 2 шашки,
/// справа сверху 5, снизу справа 3, снизу слева 5. Дом игрока — левый нижний
/// квадрант, у соперника всё зеркально по вертикали.
class NardyBoardLayout {
  const NardyBoardLayout._();

  /// Пунктов в квадранте.
  static const int quadrant = 6;

  /// Верхний ряд слева направо: голова (дорожка 0) в левом верхнем углу.
  static const List<int> topRow = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

  /// Нижний ряд слева направо: дом (18..23) в левом нижнем квадранте.
  static const List<int> bottomRow = [
    23, 22, 21, 20, 19, 18, //
    17, 16, 15, 14, 13, 12,
  ];

  static List<int> get allTracks => const [...topRow, ...bottomRow];

  /// Пункт входит в дом игрока.
  static bool isHome(int track) => track >= nardyHomeStart;

  /// Пункт в верхнем ряду (шашки укладываются сверху вниз).
  static bool isTopRow(int track) => topRow.contains(track);

  /// Колонка пункта в своём ряду, 0..11 слева направо.
  static int columnOf(int track) {
    final top = topRow.indexOf(track);
    if (top >= 0) return top;
    return bottomRow.indexOf(track);
  }

  /// Колонок в ряду.
  static const int columns = 12;
}

/// Зеркало раскладки: дом игрока справа внизу, голова — справа сверху.
int nardyVisualColumn(int track, {required bool homeOnRight}) {
  final col = NardyBoardLayout.columnOf(track);
  if (col < 0) return col;
  return homeOnRight ? NardyBoardLayout.columns - 1 - col : col;
}

/// Пункты слева направо, сверху вниз — как на экране.
List<int> nardyVisualTracks({required bool homeOnRight}) {
  if (!homeOnRight) return NardyBoardLayout.allTracks;
  return [
    ...NardyBoardLayout.topRow.reversed,
    ...NardyBoardLayout.bottomRow.reversed,
  ];
}

/// Куда встанет шашка с пункта [from] кубиком [die]; `>= 24` — снятие.
int nardyDestinationTrack(int from, int die) {
  if (from == nardyBarTrack) return die - 1;
  return from + die;
}

/// Ход выбрасывает шашку с доски.
bool nardyIsBearOff(int from, int die) =>
    from != nardyBarTrack && from + die >= nardyPoints;

/// Геометрия доски: где рисовать пункты, шашки, бар и зону снятия.
///
/// Считается один раз на кадр и переиспользуется и для отрисовки, и для
/// анимации — так летящая шашка приходит ровно в свой слот.
class NardyBoardGeometry {
  NardyBoardGeometry({
    required this.size,
    required this.showBar,
    this.homeOnRight = false,
  });

  /// Полный размер виджета доски.
  final Size size;

  /// Показывать центральный бар (только короткие нарды).
  final bool showBar;

  /// Дом игрока справа внизу — зеркальная раскладка фишек.
  final bool homeOnRight;

  /// Доля ширины под зону снятых шашек.
  static const double _trayFraction = 0.075;
  static const double _minTray = 20.0;
  static const double _maxTray = 40.0;
  static const double _barFraction = 0.045;
  static const double _padding = 5.0;

  double get trayWidth =>
      (size.width * _trayFraction).clamp(_minTray, _maxTray).toDouble();

  double get barWidth =>
      showBar ? (size.width * _barFraction).clamp(14.0, 30.0).toDouble() : 3.0;

  /// Ширина игровой части без зоны снятия.
  double get boardWidth => size.width - trayWidth - _padding * 2;

  double get columnWidth => (boardWidth - barWidth) / 12;

  /// Высота одного пункта (половина доски минус отступы).
  double get pointHeight => (size.height - _padding * 2) / 2;

  /// Диаметр шашки.
  double get checkerSize => columnWidth * 0.86;

  /// Прямоугольник пункта дорожки.
  Rect trackRect(int track) {
    final column = nardyVisualColumn(track, homeOnRight: homeOnRight);
    if (column < 0) return Rect.zero;
    final top = NardyBoardLayout.isTopRow(track);
    var x = _padding + column * columnWidth;
    if (column >= NardyBoardLayout.quadrant) x += barWidth;
    final y = top ? _padding : _padding + pointHeight;
    return Rect.fromLTWH(x, y, columnWidth, pointHeight);
  }

  /// Минимальная видимая полоска шашки в стопке (доля диаметра).
  ///
  /// Стопку не обрезаем числом: шашки должны пересчитываться глазами, поэтому
  /// высокие стопки ужимаем нахлёстом, а при нехватке места — и размером.
  static const double _minOverlap = 0.3;

  /// Свободная высота пункта под стопку.
  double get _stackSpan => pointHeight - 2;

  /// Диаметр шашки в стопке: если не влезает даже с нахлёстом — уменьшаем.
  double stackCheckerSize(int stackSize) {
    final base = checkerSize;
    if (stackSize <= 1) return base;
    final slots = 1 + (stackSize - 1) * _minOverlap;
    if (base * slots <= _stackSpan) return base;
    return _stackSpan / slots;
  }

  /// Шаг между центрами соседних шашек стопки.
  double stackStep(int stackSize) {
    if (stackSize <= 1) return 0;
    final diameter = stackCheckerSize(stackSize);
    final spread = (_stackSpan - diameter) / (stackSize - 1);
    return spread.clamp(diameter * _minOverlap, diameter * 0.88);
  }

  /// Центр шашки с номером [index] в стопке на пункте [track].
  Offset checkerCenter(int track, int index, int stackSize) {
    final rect = trackRect(track);
    final top = NardyBoardLayout.isTopRow(track);
    final radius = stackCheckerSize(stackSize) / 2;
    final offset = index * stackStep(stackSize);
    final dy = top ? radius + 1 + offset : pointHeight - radius - 1 - offset;
    return Offset(rect.left + rect.width / 2, rect.top + dy);
  }

  /// Прямоугольник центрального бара.
  Rect get barRect => Rect.fromLTWH(
        _padding + NardyBoardLayout.quadrant * columnWidth,
        _padding,
        barWidth,
        pointHeight * 2,
      );

  /// Центр шашки на баре: свои — снизу, чужие — сверху.
  Offset barCheckerCenter({required bool mine, required int index}) {
    final rect = barRect;
    final radius = checkerSize / 2;
    final step = checkerSize * 0.5;
    final dy = mine
        ? rect.bottom - radius - 4 - index * step
        : rect.top + radius + 4 + index * step;
    return Offset(rect.center.dx, dy);
  }

  /// Зона снятых шашек справа.
  Rect get trayRect => Rect.fromLTWH(
        size.width - trayWidth,
        _padding,
        trayWidth,
        size.height - _padding * 2,
      );

  /// Половина зоны снятия: свои снизу, чужие сверху.
  Rect trayHalf({required bool mine}) {
    final rect = trayRect;
    final half = rect.height / 2;
    return Rect.fromLTWH(
      rect.left,
      mine ? rect.top + half : rect.top,
      rect.width,
      half,
    );
  }

  /// Центр снятой шашки — цель для анимации выброса.
  Offset offCenter({required bool mine, required int index}) {
    final rect = trayHalf(mine: mine);
    final step = (rect.height / 16).clamp(3.0, 9.0);
    final dy = mine
        ? rect.bottom - checkerSize / 3 - index * step
        : rect.top + checkerSize / 3 + index * step;
    return Offset(rect.center.dx, dy);
  }

  /// Пункт дорожки под точкой касания или `null`.
  int? trackAt(Offset position) {
    for (final track in NardyBoardLayout.allTracks) {
      if (trackRect(track).contains(position)) return track;
    }
    return null;
  }
}

/// Соотношение сторон доски (ширина / высота) для вписывания в экран.
const double kNardyBoardAspect = 1.42;

/// Размер доски, вписанный в доступное место с сохранением пропорций.
Size nardyFitBoard(Size available) {
  if (available.width <= 0 || available.height <= 0) return Size.zero;
  var width = available.width;
  var height = width / kNardyBoardAspect;
  if (height > available.height) {
    height = available.height;
    width = height * kNardyBoardAspect;
  }
  return Size(width, height);
}

/// Высота слота под статус, кубики и кнопки в портрете.
///
/// Пока партия идёт — фиксированная, иначе доска прыгает при появлении кнопок.
/// После партии `null`: «Повторить» и «Другой соперник» встают колонкой и в
/// фиксированный слот не помещаются — панель берёт высоту по содержимому.
double? nardyBottomPanelHeight({required bool isOver}) => isOver ? null : 148.0;
