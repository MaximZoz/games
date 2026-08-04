import 'package:flutter/material.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Отрисовка одной игральной карты.
/// Углы через [Stack] + [ClipRRect] — без overflow перевёрнутых рангов снизу.
class PlayingCardWidget extends StatelessWidget {
  const PlayingCardWidget({
    super.key,
    required this.card,
    this.size = const Size(60, 88),
    this.highlighted = false,
    this.dimmed = false,
    this.elevated = false,
    this.dropTarget = false,
  });

  final PlayingCard card;
  final Size size;
  final bool highlighted;
  final bool dimmed;
  final bool elevated;

  /// Фиолетовая подсветка места, куда можно положить карту.
  final bool dropTarget;

  @override
  Widget build(BuildContext context) {
    final color = card.suit.isRed
        ? const Color(0xFFD84A4A)
        : const Color(0xFF1B1B24);
    final radius = size.width * 0.15;
    final borderColor = dropTarget
        ? AppColors.accentStart
        : highlighted
            ? AppColors.accentStart
            : Colors.black.withValues(alpha: 0.08);
    final borderWidth = dropTarget || highlighted ? 2.5 : 1.0;
    final corner = size.height * 0.155;
    final padH = size.width * 0.1;
    final padV = size.height * 0.055;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          if (dropTarget)
            BoxShadow(
              color: AppColors.accentStart.withValues(alpha: 0.45),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          if (elevated)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 14,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      foregroundDecoration: dimmed
          ? BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(radius),
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 0.5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (dropTarget)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.accentStart.withValues(alpha: 0.12),
                      AppColors.accentEnd.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: padH,
              top: padV,
              child: _CornerMarks(
                rank: card.rank.label,
                suit: card.suit.symbol,
                color: color,
                fontSize: corner,
              ),
            ),
            Center(
              child: Text(
                card.suit.symbol,
                style: TextStyle(
                  color: color,
                  fontSize: size.height * 0.34,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              right: padH,
              bottom: padV,
              child: Transform.rotate(
                angle: 3.1415926535,
                child: _CornerMarks(
                  rank: card.rank.label,
                  suit: card.suit.symbol,
                  color: color,
                  fontSize: corner,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerMarks extends StatelessWidget {
  const _CornerMarks({
    required this.rank,
    required this.suit,
    required this.color,
    required this.fontSize,
  });

  final String rank;
  final String suit;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          rank,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        Text(
          suit,
          style: TextStyle(
            color: color,
            fontSize: fontSize * 0.95,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ],
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

/// Пустой слот на столе — куда можно подкинуть карту.
class DurakDropSlot extends StatelessWidget {
  const DurakDropSlot({
    super.key,
    required this.size,
    this.active = false,
  });

  final Size size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.accentStart;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: active
            ? color.withValues(alpha: 0.18)
            : color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(size.width * 0.15),
        border: Border.all(
          color: active ? color : color.withValues(alpha: 0.35),
          width: active ? 2.5 : 1.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

/// Значок козырной масти, когда колода пуста.
class DurakTrumpSuitBadge extends StatelessWidget {
  const DurakTrumpSuitBadge({
    super.key,
    required this.suit,
    this.size = 48,
  });

  final Suit suit;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = suit.isRed ? const Color(0xFFD84A4A) : const Color(0xFF1B1B24);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accentStart.withValues(alpha: 0.55),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        suit.symbol,
        style: TextStyle(
          color: color,
          fontSize: size * 0.55,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
