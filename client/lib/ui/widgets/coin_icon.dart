import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Цвета монет: бронза, серебро, золото, бриллиант.
class CoinColors {
  CoinColors._();

  static const Color bronze = Color(0xFFC47A2C);
  static const Color bronzeLight = Color(0xFFF0B45A);
  static const Color bronzeHighlight = Color(0xFFFFE7B0);
  static const Color bronzeDark = Color(0xFF6E3D14);
  static const Color bronzeRim = Color(0xFF8A4E1A);

  static const Color silver = Color(0xFFB8BEC8);
  static const Color silverLight = Color(0xFFECEFF3);
  static const Color silverHighlight = Color(0xFFFFFFFF);
  static const Color silverDark = Color(0xFF5A6472);
  static const Color silverRim = Color(0xFF7A8494);

  static const Color gold = Color(0xFFE1B12C);
  static const Color goldLight = Color(0xFFFFE066);
  static const Color goldHighlight = Color(0xFFFFF6C2);
  static const Color goldDark = Color(0xFF8A6410);
  static const Color goldRim = Color(0xFFB8860B);

  static const Color diamondWhite = Color(0xFFF2FBFF);
  static const Color diamondLight = Color(0xFF7DE7F5);
  static const Color diamondMid = Color(0xFF35C4F0);
  static const Color diamondBlue = Color(0xFF1E90E0);
  static const Color diamondDark = Color(0xFF0B4F9C);
  static const Color diamondSparkle = Color(0xFFFFFFFF);
  static const Color diamondOutline = Color(0xFF163A7A);
}

/// Иконка монеты / бриллианта. [animate] — периодический блик.
class CoinIcon extends StatelessWidget {
  const CoinIcon({
    super.key,
    required this.coinType,
    this.size = 20,
    this.showBorder = true,
    this.animate = false,
  });

  final CoinType coinType;
  final double size;
  final bool showBorder;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final icon = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: coinType == CoinType.diamond
            ? _DiamondPainter(iconSize: size)
            : _MetalCoinPainter(
                coinType: coinType,
                showBorder: showBorder,
              ),
        size: Size.square(size),
      ),
    );
    if (animate) {
      return _ShimmerIcon(size: size, child: icon);
    }
    return icon;
  }
}

class _ShimmerIcon extends StatefulWidget {
  const _ShimmerIcon({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  State<_ShimmerIcon> createState() => _ShimmerIconState();
}

class _ShimmerIconState extends State<_ShimmerIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _shimmerOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.75), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 0.0), weight: 1),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 8),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerOpacity,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            child!,
            if (_shimmerOpacity.value > 0.01)
              IgnorePointer(
                child: ClipOval(
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.35, -0.45),
                        radius: 1.4,
                        colors: [
                          Colors.white.withValues(alpha: _shimmerOpacity.value),
                          Colors.white
                              .withValues(alpha: _shimmerOpacity.value * 0.25),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _MetalCoinPainter extends CustomPainter {
  _MetalCoinPainter({
    required this.coinType,
    required this.showBorder,
  });

  final CoinType coinType;
  final bool showBorder;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);
    final r = s / 2;

    const cyrillic = {'ru', 'uk', 'be', 'kk', 'bg', 'sr', 'mk'};
    final lang = LocaleService.locale.languageCode.toLowerCase();
    final useCyr = cyrillic.contains(lang);
    final palette = switch (coinType) {
      CoinType.bronze => (
          highlight: CoinColors.bronzeHighlight,
          light: CoinColors.bronzeLight,
          mid: CoinColors.bronze,
          dark: CoinColors.bronzeDark,
          rim: CoinColors.bronzeRim,
          glyph: useCyr ? 'Б' : 'B',
        ),
      CoinType.silver => (
          highlight: CoinColors.silverHighlight,
          light: CoinColors.silverLight,
          mid: CoinColors.silver,
          dark: CoinColors.silverDark,
          rim: CoinColors.silverRim,
          glyph: useCyr ? 'С' : 'S',
        ),
      CoinType.gold => (
          highlight: CoinColors.goldHighlight,
          light: CoinColors.goldLight,
          mid: CoinColors.gold,
          dark: CoinColors.goldDark,
          rim: CoinColors.goldRim,
          glyph: useCyr ? 'З' : 'G',
        ),
      CoinType.diamond => (
          highlight: CoinColors.diamondWhite,
          light: CoinColors.diamondLight,
          mid: CoinColors.diamondMid,
          dark: CoinColors.diamondDark,
          rim: CoinColors.diamondOutline,
          glyph: '◆',
        ),
    };

    // Мягкая тень под монетой.
    canvas.drawCircle(
      c.translate(0, s * 0.06),
      r * 0.92,
      Paint()
        ..color = palette.dark.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.08),
    );

    // Внешний обод.
    canvas.drawCircle(
      c,
      r * 0.98,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          colors: [
            palette.highlight,
            palette.light,
            palette.mid,
            palette.dark,
            palette.rim,
            palette.light,
            palette.highlight,
          ],
          stops: const [0.0, 0.18, 0.38, 0.58, 0.78, 0.9, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Внутренний диск.
    final innerR = r * 0.78;
    canvas.drawCircle(
      c,
      innerR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.42),
          radius: 1.05,
          colors: [
            palette.highlight,
            palette.light,
            palette.mid,
            palette.dark,
          ],
          stops: const [0.0, 0.28, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: innerR)),
    );

    // Внутренний кант (гравировка).
    canvas.drawCircle(
      c,
      innerR * 0.86,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.045).clamp(1.0, 2.4)
        ..color = palette.dark.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      c,
      innerR * 0.86,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.02).clamp(0.6, 1.2)
        ..color = palette.highlight.withValues(alpha: 0.55),
    );

    // Блик-дуга сверху слева.
    final highlightPath = Path()
      ..addArc(
        Rect.fromCircle(center: c, radius: innerR * 0.72),
        -math.pi * 0.95,
        math.pi * 0.55,
      );
    canvas.drawPath(
      highlightPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = (s * 0.07).clamp(1.2, 3.5)
        ..color = Colors.white.withValues(alpha: 0.55),
    );

    // Центральный символ.
    final fontSize = s * 0.42;
    final tp = TextPainter(
      text: TextSpan(
        text: palette.glyph,
        style: TextStyle(
          color: palette.dark.withValues(alpha: 0.82),
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1,
          shadows: [
            Shadow(
              color: palette.highlight.withValues(alpha: 0.7),
              offset: Offset(-s * 0.02, -s * 0.02),
              blurRadius: s * 0.04,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(c.dx - tp.width / 2, c.dy - tp.height / 2 - s * 0.02),
    );

    if (showBorder) {
      canvas.drawCircle(
        c,
        r * 0.985,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (s * 0.035).clamp(0.8, 1.8)
          ..color = palette.rim.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MetalCoinPainter oldDelegate) =>
      oldDelegate.coinType != coinType || oldDelegate.showBorder != showBorder;
}

class _DiamondPainter extends CustomPainter {
  _DiamondPainter({required this.iconSize});

  final double iconSize;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s / 2;
    final cy = s / 2;
    // Чуть крупнее, чтобы визуально совпадать с круглыми монетами в одном слоте.
    final r = s * 0.50;

    // Тень.
    final shadow = Path()
      ..moveTo(cx, cy - r * 0.55)
      ..lineTo(cx + r * 0.72, cy - r * 0.08)
      ..lineTo(cx, cy + r * 0.95)
      ..lineTo(cx - r * 0.72, cy - r * 0.08)
      ..close();
    canvas.drawPath(
      shadow.shift(Offset(0, s * 0.05)),
      Paint()
        ..color = CoinColors.diamondDark.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.08),
    );

    final top = Offset(cx, cy - r * 0.58);
    final left = Offset(cx - r * 0.78, cy - r * 0.05);
    final right = Offset(cx + r * 0.78, cy - r * 0.05);
    final midL = Offset(cx - r * 0.42, cy + r * 0.18);
    final midR = Offset(cx + r * 0.42, cy + r * 0.18);
    final bottom = Offset(cx, cy + r * 0.92);
    final tableL = Offset(cx - r * 0.28, cy - r * 0.22);
    final tableR = Offset(cx + r * 0.28, cy - r * 0.22);
    final tableB = Offset(cx, cy - r * 0.02);

    Path tri(Offset a, Offset b, Offset c) => Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..close();

    void fill(Path path, List<Color> colors, Alignment begin, Alignment end) {
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: begin,
            end: end,
            colors: colors,
          ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
    }

    // Корона.
    fill(
      tri(top, tableL, left),
      const [CoinColors.diamondWhite, CoinColors.diamondLight],
      Alignment.topLeft,
      Alignment.bottomRight,
    );
    fill(
      tri(top, right, tableR),
      const [CoinColors.diamondLight, CoinColors.diamondMid],
      Alignment.topRight,
      Alignment.bottomLeft,
    );
    fill(
      tri(top, tableR, tableL),
      const [CoinColors.diamondSparkle, CoinColors.diamondWhite],
      Alignment.topCenter,
      Alignment.bottomCenter,
    );
    fill(
      tri(tableL, tableB, left),
      const [CoinColors.diamondWhite, CoinColors.diamondMid],
      Alignment.centerLeft,
      Alignment.centerRight,
    );
    fill(
      tri(tableR, right, tableB),
      const [CoinColors.diamondMid, CoinColors.diamondBlue],
      Alignment.centerRight,
      Alignment.centerLeft,
    );
    fill(
      tri(tableL, tableR, tableB),
      const [CoinColors.diamondSparkle, CoinColors.diamondLight],
      Alignment.topLeft,
      Alignment.bottomRight,
    );

    // Павильон.
    fill(
      tri(left, midL, bottom),
      const [CoinColors.diamondBlue, CoinColors.diamondDark],
      Alignment.topLeft,
      Alignment.bottomCenter,
    );
    fill(
      tri(right, bottom, midR),
      const [CoinColors.diamondMid, CoinColors.diamondDark],
      Alignment.topRight,
      Alignment.bottomCenter,
    );
    fill(
      tri(midL, tableB, bottom),
      const [CoinColors.diamondLight, CoinColors.diamondBlue],
      Alignment.topCenter,
      Alignment.bottomCenter,
    );
    fill(
      tri(tableB, midR, bottom),
      const [CoinColors.diamondBlue, CoinColors.diamondDark],
      Alignment.topCenter,
      Alignment.bottomCenter,
    );
    fill(
      tri(left, tableB, midL),
      const [CoinColors.diamondLight, CoinColors.diamondBlue],
      Alignment.topLeft,
      Alignment.bottomRight,
    );
    fill(
      tri(right, midR, tableB),
      const [CoinColors.diamondMid, CoinColors.diamondBlue],
      Alignment.topRight,
      Alignment.bottomLeft,
    );

    // Контур.
    final outline = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(midR.dx, midR.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(midL.dx, midL.dy)
      ..lineTo(left.dx, left.dy)
      ..close();
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.035).clamp(0.8, 1.6)
        ..strokeJoin = StrokeJoin.round
        ..color = CoinColors.diamondOutline.withValues(alpha: 0.9),
    );

    // Внутренние фасеты.
    final facetPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.018).clamp(0.5, 1.0)
      ..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawLine(tableL, tableR, facetPaint);
    canvas.drawLine(tableL, tableB, facetPaint);
    canvas.drawLine(tableR, tableB, facetPaint);
    canvas.drawLine(tableB, bottom, facetPaint);
    canvas.drawLine(left, tableB, facetPaint);
    canvas.drawLine(right, tableB, facetPaint);

    // Блик.
    canvas.drawCircle(
      Offset(cx - r * 0.12, cy - r * 0.28),
      r * 0.1,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum CoinType { bronze, silver, gold, diamond }

/// Тип монеты для суммы: старший ненулевой номинал без округления вверх.
CoinType rewardCoinType(int bronze) {
  if (bronze <= 0) return CoinType.bronze;
  final (diamond, gold, silver, bronzeRest) = parseBalance(bronze);
  if (diamond > BigInt.zero) return CoinType.diamond;
  if (gold > BigInt.zero) return CoinType.gold;
  if (silver > BigInt.zero) return CoinType.silver;
  if (bronzeRest > BigInt.zero) return CoinType.bronze;
  return CoinType.bronze;
}

/// Человекочитаемая сумма без округления: 133 бр → «1 серебряных 33 бронзовых».
String formatRewardBronze(int bronze, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  if (bronze <= 0) return t.balanceZeroBronze;
  final (diamond, gold, silver, bronzeRest) = parseBalance(bronze);
  final parts = <String>[];
  if (diamond > BigInt.zero) {
    parts.add(t.balanceDiamonds(diamond.toInt()));
  }
  if (gold > BigInt.zero) {
    parts.add(t.balanceGolds(gold.toInt()));
  }
  if (silver > BigInt.zero) {
    parts.add(t.balanceSilvers(silver.toInt()));
  }
  if (bronzeRest > BigInt.zero) {
    parts.add(t.balanceBronzes(bronzeRest.toInt()));
  }
  if (parts.isEmpty) return t.balanceZeroBronze;
  return parts.join(' ');
}

/// Сумма дохода с явным «в день».
String formatRewardBronzePerDay(int bronze, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  return t.balancePerDay(formatRewardBronze(bronze, t));
}

/// Количество старшего ненулевого номинала (для компактной иконки).
int rewardCoinAmount(int bronze) {
  if (bronze <= 0) return 0;
  final (diamond, gold, silver, bronzeRest) = parseBalance(bronze);
  if (diamond > BigInt.zero) return diamond.toInt();
  if (gold > BigInt.zero) return gold.toInt();
  if (silver > BigInt.zero) return silver.toInt();
  return bronzeRest.toInt();
}

/// Разбивка баланса: 100 бр=1 с, 100 с=1 з, 100 з=1 ◆.
(BigInt, BigInt, BigInt, BigInt) parseBalance(int bronze) {
  final b = BigInt.from(bronze < 0 ? 0 : bronze);
  final diamond = b ~/ BigInt.from(1000000);
  final gold = (b ~/ BigInt.from(10000)) % BigInt.from(100);
  final silver = (b ~/ BigInt.from(100)) % BigInt.from(100);
  final bronzeRest = b % BigInt.from(100);
  return (diamond, gold, silver, bronzeRest);
}

String _coinLabel(CoinType type, AppLocalizations l10n) {
  switch (type) {
    case CoinType.diamond:
      return l10n.coinDiamond;
    case CoinType.gold:
      return l10n.coinGold;
    case CoinType.silver:
      return l10n.coinSilver;
    case CoinType.bronze:
      return l10n.coinBronze;
  }
}

/// Компактный блок баланса для тулбара: капсула с монетой и количеством, по клику — popup со всеми валютами.
class ToolbarBalanceChip extends StatelessWidget {
  const ToolbarBalanceChip({
    super.key,
    required this.bronze,
    this.coinSize = 20,
    this.forceShow = const <CoinType>{},
    this.coinKeys,
  });

  final int bronze;
  final double coinSize;
  final Set<CoinType> forceShow;
  final Map<CoinType, GlobalKey>? coinKeys;

  void _showBalancePopup(BuildContext context, int bronze) {
    final (diamond, gold, silver, bronzeRest) = parseBalance(bronze);
    final items = <_BalancePopupItem>[
      _BalancePopupItem(CoinType.diamond, diamond),
      _BalancePopupItem(CoinType.gold, gold),
      _BalancePopupItem(CoinType.silver, silver),
      _BalancePopupItem(CoinType.bronze, bronzeRest),
    ];
    // Фиксированная ширина колонки чисел — иначе «0» сдвигает иконку/подпись.
    final amountWidth = items
        .map((e) => e.value.toString().length)
        .fold<int>(1, math.max)
        .clamp(2, 8)
        .toDouble() *
        11;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final dialogL10n = ctx.l10n;
        return AlertDialog(
          title: Text(dialogL10n.balanceTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: amountWidth,
                      child: Text(
                        e.value.toString(),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: CoinIcon(
                          coinType: e.type,
                          size: 28,
                          showBorder: true,
                          animate: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _coinLabel(e.type, dialogL10n),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showBalancePopup(context, bronze),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.accentSoft.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.centerLeft,
            child: BalanceDisplay(
              bronze: bronze,
              coinSize: coinSize,
              fontSize: 12,
              spacing: 4,
              fontWeight: FontWeight.w600,
              animate: true,
              forceShow: forceShow,
              coinKeys: coinKeys,
            ),
          ),
        ),
      ),
    );
  }
}

class _BalancePopupItem {
  const _BalancePopupItem(this.type, this.value);
  final CoinType type;
  final BigInt value;
}

/// Сумма монет: `5` + серебро + `4` + бронза (только ненулевые номиналы).
class BalanceDisplay extends StatelessWidget {
  const BalanceDisplay({
    super.key,
    required this.bronze,
    this.coinSize = 18,
    this.fontSize = 14,
    this.spacing = 6,
    this.fontWeight = FontWeight.w600,
    this.prefix,
    this.suffix,
    this.animate = false,
    this.color = AppColors.textPrimary,
    this.opacity = 1,
    this.forceShow = const <CoinType>{},
    this.coinKeys,
  });

  final int bronze;
  final double coinSize;
  final double fontSize;
  final double spacing;
  final FontWeight fontWeight;
  final String? prefix;
  final String? suffix;
  final bool animate;
  final Color color;
  /// 0…1 — для приглушённого бонуса незавершённой коллекции.
  final double opacity;
  /// Показать номинал даже при 0 (вставка новой монеты перед анимацией).
  final Set<CoinType> forceShow;
  final Map<CoinType, GlobalKey>? coinKeys;

  @override
  Widget build(BuildContext context) {
    final (diamond, gold, silver, bronzeRest) = parseBalance(bronze);

    final parts = <Widget>[];
    if (prefix != null && prefix!.isNotEmpty) {
      parts.add(Text(
        prefix!,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ));
    }

    void add(CoinType type, BigInt value) {
      if (value <= BigInt.zero && !forceShow.contains(type)) return;
      if (parts.isNotEmpty) parts.add(SizedBox(width: spacing));
      parts.add(Text(
        value.toString(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        overflow: TextOverflow.clip,
      ));
      parts.add(const SizedBox(width: 3));
      parts.add(KeyedSubtree(
        key: coinKeys?[type],
        child: CoinIcon(
          coinType: type,
          size: coinSize,
          showBorder: true,
          animate: animate,
        ),
      ));
    }

    add(CoinType.diamond, diamond);
    add(CoinType.gold, gold);
    add(CoinType.silver, silver);
    add(CoinType.bronze, bronzeRest);

    if (parts.isEmpty || (prefix != null && parts.length == 1)) {
      if (prefix == null || prefix!.isEmpty) {
        parts.clear();
      }
      parts.add(Text(
        '0',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        overflow: TextOverflow.clip,
      ));
      parts.add(const SizedBox(width: 3));
      parts.add(KeyedSubtree(
        key: coinKeys?[CoinType.bronze],
        child: CoinIcon(
          coinType: CoinType.bronze,
          size: coinSize,
          showBorder: true,
          animate: animate,
        ),
      ));
    }

    if (suffix != null && suffix!.isNotEmpty) {
      parts.add(SizedBox(width: spacing));
      parts.add(Text(
        suffix!,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ));
    }

    final row = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: parts,
      ),
    );
    if (opacity >= 0.999) return row;
    return Opacity(opacity: opacity.clamp(0.0, 1.0), child: row);
  }
}
