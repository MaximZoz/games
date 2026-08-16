import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/cards/suit_asset_cache.dart';

/// Отрисовка одной игральной карты.
///
/// Ранг — [TextPainter]; масть — PNG из [SuitAssetCache] (как флаги),
/// без системного unicode ♥♦♣♠ (на Web часто «квадратики»).
///
/// Рамок нет: подсказка — только фиолетовая тень ([highlighted] / [dropTarget]).
class PlayingCardWidget extends StatefulWidget {
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
  State<PlayingCardWidget> createState() => _PlayingCardWidgetState();
}

class _PlayingCardWidgetState extends State<PlayingCardWidget> {
  ui.Image? _suitImage;

  @override
  void initState() {
    super.initState();
    _suitImage = SuitAssetCache.imageFor(widget.card.suit);
    if (_suitImage == null) {
      unawaited(_ensureSuit());
    }
  }

  @override
  void didUpdateWidget(covariant PlayingCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.suit != widget.card.suit) {
      _suitImage = SuitAssetCache.imageFor(widget.card.suit);
      if (_suitImage == null) {
        unawaited(_ensureSuit());
      }
    }
  }

  Future<void> _ensureSuit() async {
    final img = await SuitAssetCache.load(widget.card.suit);
    if (!mounted) return;
    if (img != _suitImage) {
      setState(() => _suitImage = img);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final size = widget.size;
    final color = card.suit.isRed
        ? const Color(0xFFD84A4A)
        : const Color(0xFF1B1B24);
    final radius = size.width * 0.15;
    final hint = widget.dropTarget || widget.highlighted;

    final decoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        if (hint)
          BoxShadow(
            color: AppColors.accentStart
                .withValues(alpha: widget.dropTarget ? 0.5 : 0.38),
            blurRadius: widget.dropTarget ? 16 : 12,
            spreadRadius: widget.dropTarget ? 1.5 : 0.8,
          ),
        if (widget.elevated)
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
    final foreground = widget.dimmed
        ? BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(radius),
          )
        : null;

    final suitImage = _suitImage ?? SuitAssetCache.imageFor(card.suit);

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
            suit: card.suit,
            suitImage: suitImage,
            color: color,
          ),
        ),
      ),
    );

    // Размер снаружи — сразу (не AnimatedContainer width/height).
    final body = widget.animate
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

/// Доля карты под индекс в углу — крупный ранг и масть для слабого зрения.
const kPlayingCardCornerWidthFactor = 0.44;
const kPlayingCardCornerHeightFactor = 0.42;

/// Рисует ранг/масть в заданных rect без RenderFlex/RenderParagraph overflow.
class _PlayingCardFacePainter extends CustomPainter {
  _PlayingCardFacePainter({
    required this.rank,
    required this.suit,
    required this.suitImage,
    required this.color,
  });

  final String rank;
  final Suit suit;
  final ui.Image? suitImage;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cornerW = size.width * kPlayingCardCornerWidthFactor;
    final cornerH = size.height * kPlayingCardCornerHeightFactor;
    final padX = size.width * 0.04;
    final padY = size.height * 0.022;

    _paintCorner(canvas, Rect.fromLTWH(padX, padY, cornerW, cornerH));

    // Центр чуть меньше — крупные углы не наезжают на пип.
    final center = Rect.fromLTRB(
      size.width * 0.22,
      size.height * 0.34,
      size.width * 0.78,
      size.height * 0.66,
    );
    _paintSuit(canvas, center);

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
    final rankH = box.height * 0.58;
    final rankBox = Rect.fromLTWH(box.left, box.top, box.width, rankH);
    final suitW = box.width * 0.86;
    final suitH = box.height * 0.40;
    final suitBox = Rect.fromLTWH(
      box.left,
      box.top + rankH * 0.94,
      suitW,
      suitH,
    );
    _paintFittedText(
      canvas,
      rankBox,
      rank,
      fontSize: rankH,
      weight: FontWeight.w900,
      align: Alignment.topLeft,
    );
    _paintSuit(canvas, suitBox, align: Alignment.topLeft);
  }

  void _paintSuit(
    Canvas canvas,
    Rect box, {
    Alignment align = Alignment.center,
  }) {
    if (box.width <= 0 || box.height <= 0) return;
    final img = suitImage;
    if (img == null) return;

    final iw = img.width.toDouble();
    final ih = img.height.toDouble();
    if (iw <= 0 || ih <= 0) return;

    final sx = box.width / iw;
    final sy = box.height / ih;
    final scale = sx < sy ? sx : sy;
    final dw = iw * scale;
    final dh = ih * scale;
    final dx = box.left + (box.width - dw) * (align.x + 1) / 2;
    final dy = box.top + (box.height - dh) * (align.y + 1) / 2;
    final dst = Rect.fromLTWH(dx, dy, dw, dh);
    final src = Rect.fromLTWH(0, 0, iw, ih);
    canvas.drawImageRect(img, src, dst, Paint()..filterQuality = FilterQuality.medium);
  }

  void _paintFittedText(
    Canvas canvas,
    Rect box,
    String text, {
    required double fontSize,
    required FontWeight weight,
    Alignment align = Alignment.center,
  }) {
    if (box.width <= 0 || box.height <= 0 || text.isEmpty) return;

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          height: 0.92,
          letterSpacing: text.length > 1 ? -fontSize * 0.06 : 0,
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

    // Запас 3% — метрики web-шрифтов иногда чуть больше layout-box.
    final sx = (box.width * 0.97) / tw;
    final sy = (box.height * 0.97) / th;
    final scale = sx < sy ? sx : sy;
    if (scale <= 0) return;

    final dx = box.left + (box.width - tw * scale) * (align.x + 1) / 2;
    final dy = box.top + (box.height - th * scale) * (align.y + 1) / 2;

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
        oldDelegate.suitImage != suitImage ||
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
                color: color.withValues(
                    alpha: widget.active ? 0.1 + 0.08 * t : 0.04),
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
class DurakTrumpSuitBadge extends StatefulWidget {
  const DurakTrumpSuitBadge({
    super.key,
    required this.suit,
    this.size = 48,
  });

  final Suit suit;
  final double size;

  @override
  State<DurakTrumpSuitBadge> createState() => _DurakTrumpSuitBadgeState();
}

class _DurakTrumpSuitBadgeState extends State<DurakTrumpSuitBadge> {
  ui.Image? _suitImage;

  @override
  void initState() {
    super.initState();
    _suitImage = SuitAssetCache.imageFor(widget.suit);
    if (_suitImage == null) {
      unawaited(_ensureSuit());
    }
  }

  @override
  void didUpdateWidget(covariant DurakTrumpSuitBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.suit != widget.suit) {
      _suitImage = SuitAssetCache.imageFor(widget.suit);
      if (_suitImage == null) {
        unawaited(_ensureSuit());
      }
    }
  }

  Future<void> _ensureSuit() async {
    final img = await SuitAssetCache.load(widget.suit);
    if (!mounted) return;
    if (img != _suitImage) {
      setState(() => _suitImage = img);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suitImage = _suitImage ?? SuitAssetCache.imageFor(widget.suit);
    return Container(
      width: widget.size,
      height: widget.size,
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
      child: suitImage == null
          ? const SizedBox.shrink()
          : CustomPaint(
              size: Size.square(widget.size * 0.64),
              painter: _SuitAssetPainter(image: suitImage),
            ),
    );
  }
}

class _SuitAssetPainter extends CustomPainter {
  _SuitAssetPainter({required this.image});

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    if (iw <= 0 || ih <= 0) return;
    final scale = size.shortestSide / (iw > ih ? iw : ih);
    final dw = iw * scale;
    final dh = ih * scale;
    final dst = Rect.fromLTWH(
      (size.width - dw) / 2,
      (size.height - dh) / 2,
      dw,
      dh,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, iw, ih),
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _SuitAssetPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
