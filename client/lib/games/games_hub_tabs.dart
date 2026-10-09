import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';

/// Анимация TabBarView «Игры ↔ Лобби» — короче дефолтных 300 мс Flutter.
const Duration gamesLobbyTabAnimation = Duration(milliseconds: 150);

/// Сколько строк займёт название игры при данной ширине заголовка.
int gameTitleLineCount({
  required String title,
  required TextStyle style,
  required double maxWidth,
}) {
  if (maxWidth <= 0) return 1;
  final painter = TextPainter(
    text: TextSpan(text: wrapGameTitle(title), style: style),
    textDirection: TextDirection.ltr,
    maxLines: 8,
  )..layout(maxWidth: maxWidth);
  final lines = painter.computeLineMetrics().length;
  painter.dispose();
  return lines < 1 ? 1 : lines;
}

/// Ширина текста названия внутри карточки хаба (иконка, ставка, «i»).
double gamesHubTitleMaxWidth({
  required double tileWidth,
  required bool isDesktop,
  required bool isMedium,
}) {
  final padH = isMedium ? 18.0 : (isDesktop ? 24.0 : 20.0);
  final icon = isDesktop ? 52.0 : 44.0;
  final iconGap = isDesktop ? 20.0 : 12.0;
  const infoButton = 32.0;
  const stakeBlock = 48.0;
  final stakeGap = isMedium ? 8.0 : (isDesktop ? 16.0 : 12.0);
  return (tileWidth - padH * 2 - icon - iconGap - infoButton - stakeBlock - stakeGap)
      .clamp(0.0, tileWidth);
}

TextStyle gamesHubTitleStyle({
  required bool isDesktop,
  required bool isMedium,
  TextStyle? base,
}) {
  return (base ?? const TextStyle()).copyWith(
    fontWeight: FontWeight.w700,
    fontSize: isMedium ? 18 : (isDesktop ? 20 : 18),
    height: 1.15,
    letterSpacing: -0.3,
  );
}

/// Колонки карточек хаба: на телефоне всегда одна, иначе кнопки сжимаются.
/// Если при 3 колонках название уходит в 3 строки — оставляем 2 колонки.
int gamesHubTileColumns({
  required double maxWidth,
  required bool wide,
  List<String> titles = const [],
  TextStyle? titleStyle,
  bool isDesktop = true,
  bool isMedium = false,
}) {
  if (!wide) return 1;
  const gap = 16.0;
  const minTile = 260.0;
  if (maxWidth < minTile * 2 + gap) return 1;
  var cols = (maxWidth / (minTile + gap)).floor().clamp(1, 3);
  if (cols >= 3 && titles.isNotEmpty) {
    final tileW = gamesHubTileWidth(maxWidth: maxWidth, cols: 3);
    final titleW = gamesHubTitleMaxWidth(
      tileWidth: tileW,
      isDesktop: isDesktop,
      isMedium: isMedium,
    );
    final style = titleStyle ??
        gamesHubTitleStyle(isDesktop: isDesktop, isMedium: isMedium);
    final wrapsToThree = titles.any(
      (title) =>
          gameTitleLineCount(title: title, style: style, maxWidth: titleW) >= 3,
    );
    if (wrapsToThree) {
      cols = 2;
    }
  }
  return cols;
}

/// Ширина карточки: одна колонка занимает всю доступную ширину.
double gamesHubTileWidth({
  required double maxWidth,
  required int cols,
}) {
  const gap = 16.0;
  if (cols <= 1) return maxWidth;
  return ((maxWidth - gap * (cols - 1)) / cols).clamp(260.0, 400.0);
}

/// Компактные отступы карточки, если она узкая.
/// Кнопки «Создать» / «Найти» всегда в один ряд.
bool gamesHubStackActions(double cardWidth) => cardWidth < 360;

/// Сетка карточек: все плитки одной высоты (как у самой высокой),
/// кнопки прижаты к нижнему краю каждой карточки.
Widget gamesHubEqualHeightGrid({
  required int cols,
  required double gap,
  required double tileWidth,
  required List<Widget> tiles,
}) {
  if (tiles.isEmpty) return const SizedBox.shrink();
  return _GamesHubEqualHeightGrid(
    cols: cols < 1 ? 1 : cols,
    gap: gap,
    tileWidth: tileWidth,
    children: [
      for (final tile in tiles)
        GameCardLayout(
          cardWidth: tileWidth,
          child: tile,
        ),
    ],
  );
}

class _GamesHubEqualHeightGrid extends MultiChildRenderObjectWidget {
  const _GamesHubEqualHeightGrid({
    required this.cols,
    required this.gap,
    required this.tileWidth,
    required super.children,
  });

  final int cols;
  final double gap;
  final double tileWidth;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderGamesHubEqualHeightGrid(
      cols: cols,
      gap: gap,
      tileWidth: tileWidth,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderGamesHubEqualHeightGrid renderObject,
  ) {
    renderObject
      ..cols = cols
      ..gap = gap
      ..tileWidth = tileWidth;
  }
}

class _GamesHubTileParentData extends ContainerBoxParentData<RenderBox> {}

/// Сначала меряет каждую плитку по ширине, затем перекладывает все
/// в высоту самой высокой — перенос чипов больше не выпирает одну карточку.
class _RenderGamesHubEqualHeightGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _GamesHubTileParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _GamesHubTileParentData> {
  _RenderGamesHubEqualHeightGrid({
    required int cols,
    required double gap,
    required double tileWidth,
  })  : _cols = cols,
        _gap = gap,
        _tileWidth = tileWidth;

  int _cols;
  double _gap;
  double _tileWidth;

  int get cols => _cols;
  set cols(int value) {
    if (_cols == value) return;
    _cols = value;
    markNeedsLayout();
  }

  double get gap => _gap;
  set gap(double value) {
    if (_gap == value) return;
    _gap = value;
    markNeedsLayout();
  }

  double get tileWidth => _tileWidth;
  set tileWidth(double value) {
    if (_tileWidth == value) return;
    _tileWidth = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GamesHubTileParentData) {
      child.parentData = _GamesHubTileParentData();
    }
  }

  List<RenderBox> _childList() {
    final out = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      out.add(child);
      child = childAfter(child);
    }
    return out;
  }

  @override
  void performLayout() {
    final children = _childList();
    if (children.isEmpty) {
      size = constraints.smallest;
      return;
    }

    final width = tileWidth.clamp(0.0, constraints.maxWidth);
    final loose = BoxConstraints(
      minWidth: width,
      maxWidth: width,
    );
    var tileHeight = 0.0;
    for (final child in children) {
      child.layout(loose, parentUsesSize: true);
      tileHeight = math.max(tileHeight, child.size.height);
    }

    final tight = BoxConstraints.tightFor(width: width, height: tileHeight);
    for (final child in children) {
      child.layout(tight, parentUsesSize: true);
    }

    final columns = cols < 1 ? 1 : cols;
    final rows = ((children.length + columns - 1) / columns).floor();
    final gridWidth = columns == 1
        ? width
        : width * columns + gap * (columns - 1);
    var y = 0.0;
    for (var r = 0; r < rows; r++) {
      final start = r * columns;
      final end = math.min(start + columns, children.length);
      final count = end - start;
      final rowWidth = width * count + gap * (count - 1);
      var x = (gridWidth - rowWidth) / 2;
      for (var i = start; i < end; i++) {
        final parentData = children[i].parentData! as _GamesHubTileParentData;
        parentData.offset = Offset(x, y);
        x += width + gap;
      }
      y += tileHeight;
      if (r != rows - 1) y += gap;
    }
    size = constraints.constrain(Size(gridWidth, y));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final columns = cols < 1 ? 1 : cols;
    final n = childCount < columns ? childCount : columns;
    if (n <= 0) return 0;
    return tileWidth * n + gap * (n - 1);
  }

  @override
  double computeMaxIntrinsicWidth(double height) =>
      computeMinIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) {
    if (childCount == 0) return 0;
    final columns = cols < 1 ? 1 : cols;
    final rows = ((childCount + columns - 1) / columns).floor();
    var tileHeight = 0.0;
    var child = firstChild;
    while (child != null) {
      tileHeight = math.max(
        tileHeight,
        child.getMinIntrinsicHeight(tileWidth),
      );
      child = childAfter(child);
    }
    return tileHeight * rows + gap * (rows - 1);
  }

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);
}

/// Вкладка хаба по позиции анимации (0 = игры, 1 = лобби).
///
/// Во время свайпа [TabController.index] ещё старый, пока страница не
/// доедет. Берём [animation.value], чтобы переключатель не ждал конца.
int gamesLobbyTabIndexForAnimation(double value) => value >= 0.5 ? 1 : 0;
