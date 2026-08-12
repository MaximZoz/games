import 'package:flutter/material.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Отрисовка одной игральной карты.
///
/// Лицо рисуется [CustomPainter] + [TextPainter] (не через [Text]/[Column]):
/// на Flutter Web глифы ♠/♥ дают layout-overflow (жёлтые полосы), особенно
/// при [Transform.scale] / [AnimatedScale] при вытаскивании из веера.
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

    // MediaQuery textScaler не должен раздувать глифы на web/a11y.
    final face = MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.noScaling,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.hardEdge,
        child: CustomPaint(
          size: size,
          painter: _PlayingCardFacePainter(
            rank: card.rank.label,
            suit: card.suit.symbol,
            color: color,
          ),
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

/// Рисует ранг/масть в заданных rect без RenderFlex/RenderParagraph overflow.
class _PlayingCardFacePainter extends CustomPainter {
  _PlayingCardFacePainter({
    required this.rank,
    required this.suit,
    required this.color,
  });

  final String rank;
  final String suit;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cornerW = size.width * 0.32;
    final cornerH = size.height * 0.28;
    final padX = size.width * 0.06;
    final padY = size.height * 0.035;

    _paintCorner(canvas, Rect.fromLTWH(padX, padY, cornerW, cornerH));

    final center = Rect.fromLTRB(
      size.width * 0.18,
      size.height * 0.26,
      size.width * 0.82,
      size.height * 0.74,
    );
    _paintFittedText(
      canvas,
      center,
      suit,
      fontSize: size.height * 0.42,
      weight: FontWeight.w800,
    );

    canvas.save();
    final br = Rect.fromLTWH(
      size.width - padX - cornerW,
      size.height - padY - cornerH,
      cornerW,
      cornerH,
    );
    canvas.translate(br.center.dx, br.center.dy);
    canvas.rotate(3.1415926535);
    canvas.translate(-br.center.dx, -br.center.dy);
    _paintCorner(canvas, br);
    canvas.restore();
  }

  void _paintCorner(Canvas canvas, Rect box) {
    final rankBox = Rect.fromLTWH(
      box.left,
      box.top,
      box.width,
      box.height * 0.52,
    );
    final suitBox = Rect.fromLTWH(
      box.left,
      box.top + box.height * 0.48,
      box.width,
      box.height * 0.52,
    );
    _paintFittedText(
      canvas,
      rankBox,
      rank,
      fontSize: box.height * 0.48,
      weight: FontWeight.w800,
    );
    _paintFittedText(
      canvas,
      suitBox,
      suit,
      fontSize: box.height * 0.44,
      weight: FontWeight.w700,
    );
  }

  void _paintFittedText(
    Canvas canvas,
    Rect box,
    String text, {
    required double fontSize,
    required FontWeight weight,
  }) {
    if (box.width <= 0 || box.height <= 0 || text.isEmpty) return;

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          height: 1,
          leadingDistribution: TextLeadingDistribution.even,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    )..layout();

    final tw = tp.width;
    final th = tp.height;
    if (tw <= 0 || th <= 0) return;

    // Запас 4% — метрики web-шрифтов иногда чуть больше layout-box.
    final sx = (box.width * 0.96) / tw;
    final sy = (box.height * 0.96) / th;
    final scale = sx < sy ? sx : sy;
    if (scale <= 0) return;

    final dx = box.left + (box.width - tw * scale) / 2;
    final dy = box.top + (box.height - th * scale) / 2;

    canvas.save();
    canvas.clipRect(box);
    canvas.translate(dx, dy);
    canvas.scale(scale);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlayingCardFacePainter oldDelegate) {
    return oldDelegate.rank != rank ||
        oldDelegate.suit != suit ||
        oldDelegate.color != color;
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
            child: Transform.flip(
              flipX: true,
              child: Icon(
                Icons.style_rounded,
                color: Colors.white.withValues(alpha: 0.55),
                size: iconSize,
              ),
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
      child: CustomPaint(
        size: Size.square(size * 0.64),
        painter: _SuitGlyphPainter(symbol: suit.symbol, color: color),
      ),
    );
  }
}

class _SuitGlyphPainter extends CustomPainter {
  _SuitGlyphPainter({required this.symbol, required this.color});

  final String symbol;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          color: color,
          fontSize: size.shortestSide,
          fontWeight: FontWeight.w800,
          height: 1,
          leadingDistribution: TextLeadingDistribution.even,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    )..layout();
    final tw = tp.width;
    final th = tp.height;
    if (tw <= 0 || th <= 0) return;
    final scale = (size.shortestSide * 0.92) / (tw > th ? tw : th);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(
      (size.width - tw * scale) / 2,
      (size.height - th * scale) / 2,
    );
    canvas.scale(scale);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SuitGlyphPainter oldDelegate) {
    return oldDelegate.symbol != symbol || oldDelegate.color != color;
  }
}
