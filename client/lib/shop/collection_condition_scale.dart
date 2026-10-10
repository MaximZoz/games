import 'package:flutter/material.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/shop/collection_condition.dart';

/// Пять цветных состояний в ряд. [marker] — доля 0..1, где сейчас предмет.
class CollectionConditionScale extends StatelessWidget {
  const CollectionConditionScale({
    super.key,
    this.current,
    this.marker,
    this.onDark = false,
  });

  final CollectionCondition? current;
  final double? marker;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const states = CollectionCondition.values;
    final next = current == null || current == CollectionCondition.vintage
        ? null
        : states[current!.index + 1];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 22,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final spot = marker;
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Row(
                    children: [
                      for (final state in states)
                        Expanded(
                          child: Container(
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: _segmentColor(state, next),
                              borderRadius: BorderRadius.circular(4),
                              border: state == current
                                  ? Border.all(
                                      color: onDark
                                          ? Colors.white
                                          : const Color(0xFF1A1A1A),
                                      width: 1.4,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (spot != null && width > 0)
                    Positioned(
                      key: const Key('condition-scale-marker'),
                      left: (width * spot.clamp(0.0, 1.0))
                              .clamp(7.0, width - 7.0) -
                          7,
                      top: 4,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color:
                              onDark ? Colors.white : const Color(0xFF1A1A1A),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: collectionConditionColor(
                              current ?? CollectionCondition.fresh,
                            ),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final state in states)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      collectionConditionName(l10n, state),
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.1,
                        fontWeight: state == current
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: _labelColor(state),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Color _segmentColor(CollectionCondition state, CollectionCondition? next) {
    final color = collectionConditionColor(state);
    if (current == null || state == current) return color;
    if (state == next) return color.withValues(alpha: 0.82);
    return color.withValues(alpha: onDark ? 0.38 : 0.45);
  }

  Color _labelColor(CollectionCondition state) {
    if (current == null) {
      return onDark
          ? Colors.white.withValues(alpha: 0.9)
          : const Color(0xFF333333);
    }
    if (state == current) return collectionConditionColor(state);
    return onDark
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF333333);
  }
}
