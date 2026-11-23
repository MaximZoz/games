import 'package:flutter/material.dart';
import 'package:multigames_client/games/uno/uno_card.dart';
import 'package:multigames_client/games/uno/uno_discard_land.dart';
import 'package:multigames_client/ui/uno/uno_card_widget.dart';

/// Сброс из двух карт: нижняя остаётся видна, верхняя лежит поверх под углом.
class UnoDiscardStack extends StatelessWidget {
  const UnoDiscardStack({
    super.key,
    required this.top,
    required this.cardSize,
    this.under,
    this.topLand,
    this.underLand,
  });

  final UnoCard top;
  final UnoCard? under;
  final Size cardSize;
  final UnoDiscardLand? topLand;
  final UnoDiscardLand? underLand;

  @override
  Widget build(BuildContext context) {
    final topPose = topLand ?? unoDiscardLandPose(top.id);
    final showUnder = under != null && under!.id != top.id;
    final underPose =
        showUnder ? (underLand ?? unoDiscardLandPose(under!.id)) : null;
    return SizedBox.fromSize(
      size: cardSize,
      child: OverflowBox(
        alignment: Alignment.center,
        minWidth: cardSize.width,
        maxWidth: cardSize.width + 36,
        minHeight: cardSize.height,
        maxHeight: cardSize.height + 36,
        child: SizedBox.fromSize(
          size: cardSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (showUnder && underPose != null)
                Transform.translate(
                  offset: Offset(underPose.dx, underPose.dy),
                  child: Transform.rotate(
                    angle: underPose.angle,
                    child: UnoCardWidget(card: under!, size: cardSize),
                  ),
                ),
              Transform.translate(
                offset: Offset(topPose.dx, topPose.dy),
                child: Transform.rotate(
                  angle: topPose.angle,
                  child: UnoCardWidget(card: top, size: cardSize),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
