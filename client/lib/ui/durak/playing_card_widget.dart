import 'package:flutter/material.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Отрисовка одной игральной карты.
class PlayingCardWidget extends StatelessWidget {
  const PlayingCardWidget({
    super.key,
    required this.card,
    this.size = const Size(60, 88),
    this.highlighted = false,
    this.dimmed = false,
    this.elevated = false,
  });

  final PlayingCard card;
  final Size size;
  final bool highlighted;
  final bool dimmed;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final color = card.suit.isRed
        ? const Color(0xFFD84A4A)
        : const Color(0xFF1B1B24);
    final border = highlighted
        ? AppColors.accentStart
        : Colors.black.withValues(alpha: 0.08);
    final overlay = dimmed ? Colors.black.withValues(alpha: 0.35) : null;
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size.width * 0.15),
        border: Border.all(
          color: border,
          width: highlighted ? 2 : 1,
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      foregroundDecoration: overlay == null
          ? null
          : BoxDecoration(
              color: overlay,
              borderRadius: BorderRadius.circular(size.width * 0.15),
            ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.08,
          vertical: size.height * 0.06,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              card.rank.label,
              style: TextStyle(
                color: color,
                fontSize: size.height * 0.22,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            Text(
              card.suit.symbol,
              style: TextStyle(
                color: color,
                fontSize: size.height * 0.22,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                card.suit.symbol,
                style: TextStyle(
                  color: color,
                  fontSize: size.height * 0.38,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
            const Spacer(),
            Transform.rotate(
              angle: 3.1415926,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    card.rank.label,
                    style: TextStyle(
                      color: color,
                      fontSize: size.height * 0.22,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  Text(
                    card.suit.symbol,
                    style: TextStyle(
                      color: color,
                      fontSize: size.height * 0.22,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Рубашка карты — для колоды и веера соперника.
class CardBackWidget extends StatelessWidget {
  const CardBackWidget({
    super.key,
    this.size = const Size(60, 88),
    this.elevated = false,
  });

  final Size size;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentStart,
            AppColors.accentEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(size.width * 0.15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
            : const [],
      ),
      child: Center(
        child: Icon(
          Icons.style_rounded,
          color: Colors.white.withValues(alpha: 0.55),
          size: size.height * 0.42,
        ),
      ),
    );
  }
}
