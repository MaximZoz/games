import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// В тестах отключаем оверлей, чтобы не ломать pump-тайминги.
final bootSplashEnabledProvider = Provider<bool>((ref) => true);

/// Полноэкранный boot-splash «Zozu Games» поверх первого кадра приложения.
///
/// Держится, пока [authStateProvider] в loading **и** пока не отыграла
/// intro-анимация (минимум ~1.8s). Затем плавно растворяется.
class BootSplashHost extends ConsumerStatefulWidget {
  const BootSplashHost({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<BootSplashHost> createState() => _BootSplashHostState();
}

class _BootSplashHostState extends ConsumerState<BootSplashHost>
    with SingleTickerProviderStateMixin {
  bool _introDone = false;
  bool _dismissing = false;
  bool _gone = false;
  late final AnimationController _exit;

  @override
  void initState() {
    super.initState();
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void dispose() {
    _exit.dispose();
    super.dispose();
  }

  void _tryDismiss({required bool authReady}) {
    if (_gone || _dismissing || !_introDone || !authReady) return;
    _dismissing = true;
    _exit.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _gone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(bootSplashEnabledProvider);
    final auth = ref.watch(authStateProvider);
    final authReady = !auth.isLoading;

    if (!enabled) {
      return widget.child;
    }

    if (!_gone && authReady && _introDone && !_dismissing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryDismiss(authReady: true);
      });
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_gone)
          FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0).animate(
              CurvedAnimation(parent: _exit, curve: Curves.easeInCubic),
            ),
            child: IgnorePointer(
              child: ZozuBootSplash(
                onIntroComplete: () {
                  if (!mounted) return;
                  setState(() => _introDone = true);
                  _tryDismiss(authReady: !ref.read(authStateProvider).isLoading);
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Сама сцена со буквами — можно переиспользовать для превью.
class ZozuBootSplash extends StatefulWidget {
  const ZozuBootSplash({
    super.key,
    this.onIntroComplete,
  });

  final VoidCallback? onIntroComplete;

  @override
  State<ZozuBootSplash> createState() => _ZozuBootSplashState();
}

class _ZozuBootSplashState extends State<ZozuBootSplash>
    with SingleTickerProviderStateMixin {
  static const _brand = 'Zozu';
  static const _sub = 'Games';

  late final AnimationController _ambient;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat(reverse: true);

    // Intro: staggered letters + line + subtitle ≈ 1.75s, затем hold.
    Future<void>.delayed(const Duration(milliseconds: 1850), () {
      if (!mounted || _notified) return;
      _notified = true;
      widget.onIntroComplete?.call();
    });
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortest = math.min(size.width, size.height);
    final zozuSize = (shortest * 0.168).clamp(42.0, 78.0);
    final gamesSize = (zozuSize * 0.38).clamp(16.0, 28.0);

    return ColoredBox(
      color: AppColors.surfaceUnified,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _ambient,
            builder: (context, _) {
              final t = _ambient.value;
              return CustomPaint(
                painter: _BootAtmospherePainter(t),
                size: Size.infinite,
              );
            },
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StaggeredBrandRow(
                  text: _brand,
                  fontSize: zozuSize,
                  letterSpacing: zozuSize * 0.04,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4F46E5),
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                      Color(0xFFA78BFA),
                    ],
                    stops: [0.0, 0.35, 0.7, 1.0],
                  ),
                ),
                SizedBox(height: zozuSize * 0.22),
                _DrawAccentLine(width: zozuSize * 2.35)
                    .animate()
                    .fadeIn(
                      delay: 420.ms,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .scaleX(
                      begin: 0.15,
                      end: 1,
                      delay: 420.ms,
                      duration: 700.ms,
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.center,
                    ),
                SizedBox(height: zozuSize * 0.2),
                _StaggeredBrandRow(
                  text: _sub,
                  fontSize: gamesSize,
                  letterSpacing: gamesSize * 0.42,
                  delayBase: 620.ms,
                  stagger: 55.ms,
                  weight: FontWeight.w600,
                  color: AppColors.textPrimary.withValues(alpha: 0.78),
                  uppercase: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaggeredBrandRow extends StatelessWidget {
  const _StaggeredBrandRow({
    required this.text,
    required this.fontSize,
    required this.letterSpacing,
    this.delayBase = Duration.zero,
    this.stagger = const Duration(milliseconds: 70),
    this.weight = FontWeight.w800,
    this.gradient,
    this.color,
    this.uppercase = false,
  });

  final String text;
  final double fontSize;
  final double letterSpacing;
  final Duration delayBase;
  final Duration stagger;
  final FontWeight weight;
  final Gradient? gradient;
  final Color? color;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final chars = charactersOf(uppercase ? text.toUpperCase() : text);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < chars.length; i++) ...[
          if (i > 0) SizedBox(width: letterSpacing),
          _LetterGlyph(
            char: chars[i],
            fontSize: fontSize,
            weight: weight,
            gradient: gradient,
            color: color,
          )
              .animate()
              .fadeIn(
                delay: delayBase + stagger * i,
                duration: 480.ms,
                curve: Curves.easeOutCubic,
              )
              .slideY(
                begin: 0.55,
                end: 0,
                delay: delayBase + stagger * i,
                duration: 620.ms,
                curve: Curves.easeOutCubic,
              )
              .scale(
                begin: const Offset(0.72, 0.72),
                end: const Offset(1, 1),
                delay: delayBase + stagger * i,
                duration: 620.ms,
                curve: Curves.easeOutBack,
              )
              .blur(
                begin: const Offset(8, 8),
                end: Offset.zero,
                delay: delayBase + stagger * i,
                duration: 520.ms,
                curve: Curves.easeOut,
              ),
        ],
      ],
    );
  }
}

List<String> charactersOf(String text) => text.characters.toList();

class _LetterGlyph extends StatelessWidget {
  const _LetterGlyph({
    required this.char,
    required this.fontSize,
    required this.weight,
    this.gradient,
    this.color,
  });

  final String char;
  final double fontSize;
  final FontWeight weight;
  final Gradient? gradient;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final wght = switch (weight) {
      FontWeight.w600 => 600.0,
      FontWeight.w700 => 700.0,
      FontWeight.w800 => 800.0,
      _ => 800.0,
    };
    final style = TextStyle(
      fontFamily: 'Syne',
      fontSize: fontSize,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', wght)],
      height: 1.0,
      letterSpacing: 0,
      color: color ?? Colors.white,
      decoration: TextDecoration.none,
    );

    final text = Text(char, style: style);
    if (gradient == null) return text;

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient!.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: text,
    );
  }
}

class _DrawAccentLine extends StatelessWidget {
  const _DrawAccentLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2.5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: const LinearGradient(
          colors: [
            Color(0x006366F1),
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0x008B5CF6),
          ],
          stops: [0.0, 0.28, 0.72, 1.0],
        ),
      ),
    );
  }
}

/// Мягкие «орбы» на фоне — атмосфера без неонового glow.
class _BootAtmospherePainter extends CustomPainter {
  _BootAtmospherePainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Лёгкий вертикальный wash.
    final wash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE0E7FF).withValues(alpha: 0.55),
          AppColors.surfaceUnified,
          const Color(0xFFEDE9FE).withValues(alpha: 0.4),
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wash);

    void orb(Offset c, double r, Color color, double a) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: a),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, paint);
    }

    final dx = math.sin(t * math.pi * 2) * w * 0.03;
    final dy = math.cos(t * math.pi * 2) * h * 0.02;

    orb(Offset(w * 0.22 + dx, h * 0.32 + dy), w * 0.42, const Color(0xFFA5B4FC), 0.38);
    orb(Offset(w * 0.78 - dx, h * 0.58 - dy), w * 0.48, const Color(0xFFC4B5FD), 0.34);
    orb(Offset(w * 0.5 + dy, h * 0.78 + dx), w * 0.36, const Color(0xFF93C5FD), 0.22);

    // Тонкая «пыль» точек — глубина, не шум.
    final speck = Paint()..color = const Color(0xFF6366F1).withValues(alpha: 0.07);
    final rnd = math.Random(7);
    for (var i = 0; i < 28; i++) {
      final x = rnd.nextDouble() * w;
      final y = rnd.nextDouble() * h;
      final phase = (t + i / 28) % 1.0;
      final r = 1.0 + (phase * 1.4);
      canvas.drawCircle(Offset(x, y), r, speck);
    }
  }

  @override
  bool shouldRepaint(covariant _BootAtmospherePainter oldDelegate) =>
      oldDelegate.t != t;
}
