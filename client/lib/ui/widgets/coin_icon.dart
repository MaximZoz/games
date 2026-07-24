import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Цвета монет: бронза, серебро, золото, бриллиант.
class CoinColors {
  CoinColors._();

  // Монеты — контрастные оттенки
  static const Color bronze = Color(0xFFB87333);
  static const Color bronzeLight = Color(0xFFE8A84A);
  static const Color bronzeHighlight = Color(0xFFFFE4A3);
  static const Color bronzeDark = Color(0xFF6B4423);
  static const Color silver = Color(0xFFA0A0A0);
  static const Color silverLight = Color(0xFFE8E8E8);
  static const Color silverHighlight = Color(0xFFFFFFFF);
  static const Color silverDark = Color(0xFF505050);
  static const Color gold = Color(0xFFD4A600);
  static const Color goldLight = Color(0xFFFFE55C);
  static const Color goldHighlight = Color(0xFFFFFACD);
  static const Color goldDark = Color(0xFF8B6914);
  // Бриллиант — яркий голубой (топаз/аквамарин)
  static const Color diamondWhite = Color(0xFFE8F7FF);
  static const Color diamondLight = Color(0xFF4DD0E1);
  static const Color diamondMid = Color(0xFF29B6F6);
  static const Color diamondBlue = Color(0xFF0288D1);
  static const Color diamondDark = Color(0xFF01579B);
  static const Color diamondSparkle = Color(0xFFFFFFFF);
  static const Color diamondOutline = Color(0xFF1A237E);
}

/// Иконка монеты в своём цвете — с рельефом и бликом. [animate] включает периодический блеск.
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
    Widget icon;
    if (coinType == CoinType.diamond) {
      icon = _DiamondIcon(size: size);
    } else {
      icon = _MetalCoinIcon(coinType: coinType, size: size, showBorder: showBorder);
    }
    if (animate) {
      return _ShimmerIcon(size: size, child: icon);
    }
    return icon;
  }
}

/// Оборачивает иконку периодической анимацией блеска.
class _ShimmerIcon extends StatefulWidget {
  const _ShimmerIcon({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  State<_ShimmerIcon> createState() => _ShimmerIconState();
}

class _ShimmerIconState extends State<_ShimmerIcon> with SingleTickerProviderStateMixin {
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
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.7), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.0), weight: 1),
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
                        center: const Alignment(-0.4, -0.5),
                        radius: 1.5,
                        colors: [
                          Colors.white.withValues(alpha: _shimmerOpacity.value),
                          Colors.white.withValues(alpha: _shimmerOpacity.value * 0.3),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.4, 1.0],
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

/// Металлическая монета с объёмом: рельефная середина, кант, блик.
class _MetalCoinIcon extends StatelessWidget {
  const _MetalCoinIcon({
    required this.coinType,
    required this.size,
    required this.showBorder,
  });

  final CoinType coinType;
  final double size;
  final bool showBorder;

  static const Map<CoinType, List<Color>> _gradients = {
    CoinType.bronze: [
      CoinColors.bronzeHighlight,
      CoinColors.bronzeLight,
      CoinColors.bronze,
      CoinColors.bronzeDark,
    ],
    CoinType.silver: [
      CoinColors.silverHighlight,
      CoinColors.silverLight,
      CoinColors.silver,
      CoinColors.silverDark,
    ],
    CoinType.gold: [
      CoinColors.goldHighlight,
      CoinColors.goldLight,
      CoinColors.gold,
      CoinColors.goldDark,
    ],
  };

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[coinType] ?? _gradients[CoinType.bronze]!;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors[3].withValues(alpha: 0.6),
                blurRadius: size * 0.12,
                offset: Offset(0, size * 0.05),
              ),
              BoxShadow(
                color: colors[0].withValues(alpha: 0.7),
                blurRadius: size * 0.08,
                offset: Offset(-size * 0.06, -size * 0.06),
              ),
            ],
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              radius: 1.2,
              colors: [
                colors[0],
                colors[1],
                colors[2],
                colors[3],
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
            border: showBorder
                ? Border.all(
                    color: colors[1].withValues(alpha: 0.95),
                    width: size * 0.03,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Фасетный бриллиант — огранка «круглый бриллиант».
class _DiamondIcon extends StatelessWidget {
  const _DiamondIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DiamondPainter(iconSize: size),
        size: Size(size, size),
      ),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  _DiamondPainter({required this.iconSize});

  final double iconSize;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s / 2;
    final cy = s / 2;
    final r = s * 0.48;
    final strokeW = (s * 0.02).clamp(0.8, 1.5);
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: s * 2, height: s * 2);

    // Широкий сверху, плоский стол, остриё внизу (wider than tall)
    final tl = Offset(cx - r * 0.55, cy - r * 0.38);
    final tr = Offset(cx + r * 0.55, cy - r * 0.38);
    final gl = Offset(cx - r * 0.48, cy + r * 0.12);
    final gr = Offset(cx + r * 0.48, cy + r * 0.12);
    final bottom = Offset(cx, cy + r);

    // === ПАВИЛЬОН (низ) — тёмные градиенты ===
    canvas.drawPath(
      Path()
        ..moveTo(cx - r * 0.2, cy + r * 0.08)
        ..lineTo(cx + r * 0.2, cy + r * 0.08)
        ..lineTo(bottom.dx, bottom.dy)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [CoinColors.diamondBlue, CoinColors.diamondDark],
        ).createShader(rect),
    );

    canvas.drawPath(
      Path()
        ..moveTo(gl.dx, gl.dy)
        ..lineTo(cx - r * 0.2, cy + r * 0.08)
        ..lineTo(bottom.dx, bottom.dy)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [CoinColors.diamondDark, CoinColors.diamondBlue],
        ).createShader(rect),
    );

    canvas.drawPath(
      Path()
        ..moveTo(gr.dx, gr.dy)
        ..lineTo(bottom.dx, bottom.dy)
        ..lineTo(cx + r * 0.2, cy + r * 0.08)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: const [CoinColors.diamondDark, CoinColors.diamondBlue],
        ).createShader(rect),
    );

    // === КОРОНА — левая светлая (почти белая), правая средне-синяя ===
    final kiteT = Offset(cx, cy - r * 0.3);
    final kiteR = Offset(cx + r * 0.18, cy - r * 0.12);
    final kiteB = Offset(cx, cy + r * 0.02);
    final kiteL = Offset(cx - r * 0.18, cy - r * 0.12);

    canvas.drawPath(
      Path()..moveTo(tl.dx, tl.dy)..lineTo(kiteT.dx, kiteT.dy)..lineTo(kiteL.dx, kiteL.dy)..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [CoinColors.diamondWhite, CoinColors.diamondLight],
        ).createShader(rect),
    );
    canvas.drawPath(
      Path()..moveTo(tr.dx, tr.dy)..lineTo(kiteR.dx, kiteR.dy)..lineTo(kiteT.dx, kiteT.dy)..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: const [CoinColors.diamondLight, CoinColors.diamondMid],
        ).createShader(rect),
    );
    canvas.drawPath(
      Path()..moveTo(kiteL.dx, kiteL.dy)..lineTo(kiteB.dx, kiteB.dy)..lineTo(gl.dx, gl.dy)..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [CoinColors.diamondWhite, CoinColors.diamondLight],
        ).createShader(rect),
    );
    canvas.drawPath(
      Path()..moveTo(kiteR.dx, kiteR.dy)..lineTo(gr.dx, gr.dy)..lineTo(kiteB.dx, kiteB.dy)..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: const [CoinColors.diamondLight, CoinColors.diamondMid],
        ).createShader(rect),
    );

    // === Центральный ромб (стол) — яркий светлый ===
    canvas.drawPath(
      Path()
        ..moveTo(kiteT.dx, kiteT.dy)
        ..lineTo(kiteR.dx, kiteR.dy)
        ..lineTo(kiteB.dx, kiteB.dy)
        ..lineTo(kiteL.dx, kiteL.dy)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [CoinColors.diamondSparkle, CoinColors.diamondWhite],
        ).createShader(rect),
    );

    // === Starburst (8 лучей) — верхний правый угол ===
    _drawStarburst(canvas, cx + r * 0.2, cy - r * 0.28, r * 0.2);

    // === Контур ===
    final outline = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(gr.dx, gr.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(gl.dx, gl.dy)
      ..close();
    canvas.drawPath(
      outline,
      Paint()
        ..color = CoinColors.diamondOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  void _drawStarburst(Canvas canvas, double cx, double cy, double r) {
    final path = Path();
    const points = 8;
    final outerR = r;
    final innerR = r * 0.35;
    for (var i = 0; i < points; i++) {
      final angle = (i * 2 * math.pi / points) - math.pi / 2;
      final rad = i.isEven ? outerR : innerR;
      final x = cx + rad * math.cos(angle);
      final y = cy + rad * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = CoinColors.diamondSparkle);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum CoinType { bronze, silver, gold, diamond }

/// Разбивка баланса: 100 бр=1 с, 100 с=1 з, 100 з=1 ◆.
(BigInt, BigInt, BigInt, BigInt) parseBalance(int bronze) {
  final b = BigInt.from(bronze);
  final diamond = b ~/ BigInt.from(1000000);
  final gold = (b ~/ BigInt.from(10000)) % BigInt.from(100);
  final silver = (b ~/ BigInt.from(100)) % BigInt.from(100);
  final bronzeRest = b % BigInt.from(100);
  return (diamond, gold, silver, bronzeRest);
}

const Map<CoinType, String> _coinLabels = {
  CoinType.diamond: 'Бриллиант',
  CoinType.gold: 'Золото',
  CoinType.silver: 'Серебро',
  CoinType.bronze: 'Бронза',
};

/// Компактный блок баланса для тулбара: капсула с монетой и количеством, по клику — popup со всеми валютами.
class ToolbarBalanceChip extends StatelessWidget {
  const ToolbarBalanceChip({
    super.key,
    required this.bronze,
    this.coinSize = 20,
  });

  final int bronze;
  final double coinSize;

  void _showBalancePopup(BuildContext context, int bronze) {
    final (diamond, gold, silver, bronzeRest) = parseBalance(bronze);
    final items = <_BalancePopupItem>[
      _BalancePopupItem(CoinType.diamond, diamond),
      _BalancePopupItem(CoinType.gold, gold),
      _BalancePopupItem(CoinType.silver, silver),
      _BalancePopupItem(CoinType.bronze, bronzeRest),
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Баланс'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  CoinIcon(coinType: e.type, size: 28, showBorder: true, animate: true),
                  const SizedBox(width: 12),
                  Text(
                    _coinLabels[e.type] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    e.value.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (diamond, gold, silver, bronzeRest) = parseBalance(bronze);
    final parts = <Widget>[];
    void add(CoinType type, BigInt value) {
      if (value > BigInt.zero) {
        if (parts.isNotEmpty) parts.add(const SizedBox(width: 8));
        parts.add(CoinIcon(coinType: type, size: coinSize, showBorder: true, animate: true));
        parts.add(const SizedBox(width: 4));
        parts.add(Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ));
      }
    }
    add(CoinType.diamond, diamond);
    add(CoinType.gold, gold);
    add(CoinType.silver, silver);
    add(CoinType.bronze, bronzeRest);
    if (parts.isEmpty) {
      parts.add(CoinIcon(coinType: CoinType.bronze, size: coinSize, showBorder: true, animate: true));
      parts.add(const SizedBox(width: 4));
      parts.add(const Text('0', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)));
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showBalancePopup(context, bronze),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.accentSoft.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: parts,
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

/// Виджет баланса: число + монета для каждого номинала (только ненулевые).
class BalanceDisplay extends StatelessWidget {
  const BalanceDisplay({
    super.key,
    required this.bronze,
    this.coinSize = 18,
    this.fontSize = 14,
    this.spacing = 6,
  });

  final int bronze;
  final double coinSize;
  final double fontSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final (diamond, gold, silver, bronzeRest) = parseBalance(bronze);

    final parts = <Widget>[];

    void add(CoinType type, BigInt value) {
      if (value > BigInt.zero) {
        if (parts.isNotEmpty) parts.add(SizedBox(width: spacing));
        parts.add(CoinIcon(coinType: type, size: coinSize, showBorder: true));
        parts.add(SizedBox(width: 4));
        parts.add(Text(
          value.toString(),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
          overflow: TextOverflow.clip,
        ));
      }
    }

    add(CoinType.diamond, diamond);
    add(CoinType.gold, gold);
    add(CoinType.silver, silver);
    add(CoinType.bronze, bronzeRest);

    if (parts.isEmpty) {
      parts.add(CoinIcon(coinType: CoinType.bronze, size: coinSize, showBorder: true));
      parts.add(SizedBox(width: 4));
      parts.add(Text(
        '0',
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        overflow: TextOverflow.clip,
      ));
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: parts,
      ),
    );
  }
}
