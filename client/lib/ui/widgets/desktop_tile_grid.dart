import 'package:flutter/material.dart';
import 'package:multigames_client/ui/responsive.dart';

/// Сетка плиток для десктопа/планшета — сверху вниз, к левому краю.
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
    this.maxColumns = 4,
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
    if (!isWide(context)) {
      return mobileBuilder(context);
    }

    return LayoutBuilder(
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
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: contentWidth,
              child: Wrap(
                spacing: gap,
                runSpacing: gap,
                alignment: WrapAlignment.start,
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
    );
  }
}

/// Ограничивает ширину контента и прижимает к верху слева на широких экранах.
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
          alignment: Alignment.topLeft,
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
