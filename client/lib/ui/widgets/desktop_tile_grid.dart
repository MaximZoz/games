import 'package:flutter/material.dart';
import 'package:multigames_client/ui/responsive.dart';

/// Сетка плиток для десктопа/планшета — сверху по центру.
///
/// На узких экранах ([isNarrow]) возвращает [mobileBuilder] без изменений.
class DesktopTileGrid extends StatelessWidget {
  const DesktopTileGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.mobileBuilder,
    this.maxCellWidth = 320,
    this.maxContentWidth = 1100,
    this.gap = 12,
    this.padding = const EdgeInsets.all(16),
    this.maxColumns = 3,
    this.physics = const AlwaysScrollableScrollPhysics(
      parent: ClampingScrollPhysics(),
    ),
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Widget Function(BuildContext context) mobileBuilder;
  final double maxCellWidth;
  final double maxContentWidth;
  final double gap;
  final EdgeInsets padding;
  final int maxColumns;
  final ScrollPhysics physics;

  @override
  Widget build(BuildContext context) {
    if (!useDesktopTiles(context)) {
      return mobileBuilder(context);
    }

    return FocusScope(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = (constraints.maxWidth - padding.horizontal)
              .clamp(0.0, maxContentWidth);
          final crossAxisCount =
              (contentWidth / (maxCellWidth + gap)).floor().clamp(1, maxColumns);
          final itemWidth =
              (contentWidth - gap * (crossAxisCount - 1)) / crossAxisCount;

          return SingleChildScrollView(
            padding: padding,
            physics: physics,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: contentWidth,
                child: Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var i = 0; i < itemCount; i++)
                      SizedBox(
                        width: itemWidth,
                        child: itemBuilder(context, i),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Ограничивает ширину контента и держит его сверху по центру на широких экранах.
class DesktopContentFrame extends StatelessWidget {
  const DesktopContentFrame({
    super.key,
    required this.child,
    this.maxWidth = 960,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (!useDesktopTiles(context)) return child;
    // Задаём ширину явно: иначе Align+maxWidth сжимает ListView/Wrap
    // до intrinsic-ширины и группы карточек «плывут» вбок.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(0.0, maxWidth).toDouble()
            : maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: padding,
            child: SizedBox(
              width: width,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Сетка на всю доступную высоту: [rows] одинаковых рядов без обрезки.
class ShopFillGrid extends StatelessWidget {
  const ShopFillGrid({
    super.key,
    required this.columns,
    required this.rows,
    required this.itemCount,
    required this.itemBuilder,
    this.gap = 8,
  });

  final int columns;
  final int rows;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final cols = columns.clamp(1, 12);
    final rowCount = rows.clamp(1, 6);
    return Column(
      children: [
        for (var r = 0; r < rowCount; r++) ...[
          if (r > 0) SizedBox(height: gap),
          Expanded(
            child: Row(
              children: [
                for (var c = 0; c < cols; c++) ...[
                  if (c > 0) SizedBox(width: gap),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final index = r * cols + c;
                        if (index >= itemCount) {
                          return const SizedBox.shrink();
                        }
                        return ClipRect(
                          child: itemBuilder(context, index),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
