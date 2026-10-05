import 'dart:math' as math;

import 'package:flutter/material.dart';
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

/// Сетка карточек: в ряду одна высота (как у самой высокой, Дурак),
/// кнопки прижаты к нижнему краю каждой карточки.
Widget gamesHubEqualHeightGrid({
  required int cols,
  required double gap,
  required double tileWidth,
  required List<Widget> tiles,
}) {
  Widget tileBox(Widget tile) {
    return SizedBox(
      width: tileWidth,
      child: GameCardLayout(
        cardWidth: tileWidth,
        child: tile,
      ),
    );
  }

  if (tiles.isEmpty) return const SizedBox.shrink();
  if (cols <= 1) {
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          tileBox(tiles[i]),
        ],
      ],
    );
  }
  final rows = <List<Widget>>[];
  for (var i = 0; i < tiles.length; i += cols) {
    rows.add(tiles.sublist(i, math.min(i + cols, tiles.length)));
  }
  return Column(
    children: [
      for (var r = 0; r < rows.length; r++) ...[
        if (r > 0) SizedBox(height: gap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < rows[r].length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              tileBox(rows[r][i]),
            ],
          ],
        ),
      ],
    ],
  );
}

/// Вкладка хаба по позиции анимации (0 = игры, 1 = лобби).
///
/// Во время свайпа [TabController.index] ещё старый, пока страница не
/// доедет. Берём [animation.value], чтобы переключатель не ждал конца.
int gamesLobbyTabIndexForAnimation(double value) => value >= 0.5 ? 1 : 0;
