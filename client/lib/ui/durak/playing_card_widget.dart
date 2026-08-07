import 'package:flutter/material.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Отрисовка одной игральной карты.
///
/// Глифы только через [FittedBox] (child с unbounded constraints) — иначе
/// метрики ♠/♥ на web дают layout-overflow (жёлтые полосы), особенно при
/// [Transform.scale] во время вытаскивания из веера.
///
/// Рамок нет: подсказка — только фиолетовая тень ([highlighted] / [dropTarget]).
class PlayingCardWidget extends StatelessWidget {
  const PlayingCardWidget({
    super.key,
    required this.card,
    this.size = const Size(60, 88),
    this.highlighted = false,
    this.dimmed = false,
    this.elevated = false,
    this.dropTarget = false,
    this.animate = true,
  });

  final PlayingCard card;
  final Size size;
  final bool highlighted;
  final bool dimmed;
  final bool elevated;

  /// Фиолетовая тень места, куда можно положить карту.
  final bool dropTarget;

  /// Плавная смена тени (веер). На столе/в fly — выкл., иначе «мигание» при handoff.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final color = card.suit.isRed
        ? const Color(0xFFD84A4A)
        : const Color(0xFF1B1B24);
    final radius = size.width * 0.15;
    final hint = dropTarget || highlighted;

    final decoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        if (hint)
          BoxShadow(
            color: AppColors.accentStart.withValues(alpha: dropTarget ? 0.5 : 0.38),
            blurRadius: dropTarget ? 16 : 12,
            spreadRadius: dropTarget ? 1.5 : 0.8,
          ),
        if (elevated)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          )
        else if (!hint)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
      ],
    );
    final foreground = dimmed
        ? BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(radius),
          )
        : null;

    final face = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          fit: StackFit.expand,
          children: [
            Positioned(
              left: size.width * 0.06,
              top: size.height * 0.035,
              width: size.width * 0.32,
              height: size.height * 0.28,
              child: _CornerMarks(
                rank: card.rank.label,
                suit: card.suit.symbol,
                color: color,
              ),
            ),
            Positioned(
              left: size.width * 0.18,
              right: size.width * 0.18,
              top: size.height * 0.26,
              bottom: size.height * 0.26,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  card.suit.symbol,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 72,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    leadingDistribution: TextLeadingDistribution.even,
                  ),
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                ),
              ),
            ),
            Positioned(
              right: size.width * 0.06,
              bottom: size.height * 0.035,
              width: size.width * 0.32,
              height: size.height * 0.28,
              child: Transform.rotate(
                angle: 3.1415926535,
                child: _CornerMarks(
                  rank: card.rank.label,
                  suit: card.suit.symbol,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Размер снаружи — сразу (не AnimatedContainer width/height).
    final body = animate
        ? AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            decoration: decoration,
            foregroundDecoration: foreground,
            child: face,
          )
        : DecoratedBox(
            decoration: decoration,
            child: foreground == null
                ? face
                : DecoratedBox(decoration: foreground, child: face),
          );

    return SizedBox(
      width: size.width,
      height: size.height,
      child: body,
    );
  }
}

class _CornerMarks extends StatelessWidget {
  const _CornerMarks({
    required this.rank,
    required this.suit,
    required this.color,
  });

  final String rank;
  final String suit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // FittedBox + unbounded child — нет overflow даже для ♠/♥ на web.
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rank,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1,
              leadingDistribution: TextLeadingDistribution.even,
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
          Text(
            suit,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1,
              leadingDistribution: TextLeadingDistribution.even,
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
        ],
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
    this.outlined = false,
  });

  final Size size;
  final bool elevated;

  /// Светлая кромка — плитки в ряду не сливаются в одну полосу.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size.width * 0.15);
    final iconSize = size.shortestSide * 0.42;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentStart,
              AppColors.accentEnd,
            ],
          ),
          borderRadius: radius,
          border: outlined
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.42),
                  width: 1.2,
                )
              : null,
          boxShadow: elevated
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : outlined
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : const [],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Center(
            child: Icon(
              Icons.style_rounded,
              color: Colors.white.withValues(alpha: 0.55),
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}

/// Пустой слот на столе — куда можно подкинуть карту (только тень, без рамки).
class DurakDropSlot extends StatefulWidget {
  const DurakDropSlot({
    super.key,
    required this.size,
    this.active = false,
  });

  final Size size;
  final bool active;

  @override
  State<DurakDropSlot> createState() => _DurakDropSlotState();
}

class _DurakDropSlotState extends State<DurakDropSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    if (widget.active) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant DurakDropSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.active && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const color = AppColors.accentStart;
    final radius = widget.size.width * 0.15;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = widget.active ? _pulse.value : 0.0;
          return Transform.scale(
            scale: widget.active ? 1 + 0.028 * t : 1,
            child: Container(
              width: widget.size.width,
              height: widget.size.height,
              decoration: BoxDecoration(
                color: color.withValues(alpha: widget.active ? 0.1 + 0.08 * t : 0.04),
                borderRadius: BorderRadius.circular(radius),
                boxShadow: widget.active
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.32 + 0.28 * t),
                          blurRadius: 14 + 10 * t,
                          spreadRadius: 1 + t,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        },
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
        boxShadow: [
          BoxShadow(
            color: AppColors.accentStart.withValues(alpha: 0.28),
            blurRadius: 10,
            spreadRadius: 0.5,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Padding(
          padding: EdgeInsets.all(size * 0.18),
          child: Text(
            suit.symbol,
            style: TextStyle(
              color: color,
              fontSize: 48,
              fontWeight: FontWeight.w800,
              height: 1,
              leadingDistribution: TextLeadingDistribution.even,
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
        ),
      ),
    );
  }
}
