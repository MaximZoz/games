import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/brand_accent_hairline.dart';

/// В тестах отключаем оверлей, чтобы не ломать pump-тайминги.
final bootSplashEnabledProvider = Provider<bool>((ref) => true);

/// Полноэкранный boot-splash «Zozu Games» поверх первого кадра приложения.
///
/// Держится, пока [authStateProvider] в loading **и** пока не отыграла
/// intro-анимация. Затем стрелки съезжают к тулбару, фон растворяется.
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
      // Дольше обычного fade: успеть «провезти» стрелки вниз к тулбару.
      duration: const Duration(milliseconds: 980),
    )..addListener(_syncToolbarHairlines);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(bootSplashEnabledProvider) && !_gone) {
        ref.read(bootToolbarHairlinesOpacityProvider.notifier).state = 0;
      }
    });
  }

  void _syncToolbarHairlines() {
    if (!mounted) return;
    final v = _exit.value;
    // Стрелки тулбара проявляются в конце handoff (когда splash-линии «садятся»).
    final opacity = v <= 0
        ? 0.0
        : ((v - 0.72) / 0.28).clamp(0.0, 1.0);
    final notifier = ref.read(bootToolbarHairlinesOpacityProvider.notifier);
    if ((notifier.state - opacity).abs() > 0.01 || opacity == 0 || opacity == 1) {
      notifier.state = opacity;
    }
  }

  @override
  void dispose() {
    _exit.removeListener(_syncToolbarHairlines);
    _exit.dispose();
    super.dispose();
  }

  void _tryDismiss({required bool authReady}) {
    if (_gone || _dismissing || !_introDone || !authReady) return;
    _dismissing = true;
    _exit.forward().whenComplete(() {
      if (!mounted) return;
      ref.read(bootToolbarHairlinesOpacityProvider.notifier).state = 1;
      setState(() => _gone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(bootSplashEnabledProvider);
    final auth = ref.watch(authStateProvider);
    final authReady = !auth.isLoading;

    if (!enabled || _gone) {
      return widget.child;
    }

    if (authReady && _introDone && !_dismissing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryDismiss(authReady: true);
      });
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: ZozuBootSplash(
            exitAnimation: _exit,
            onIntroComplete: () {
              if (!mounted) return;
              setState(() => _introDone = true);
              _tryDismiss(authReady: !ref.read(authStateProvider).isLoading);
            },
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
    this.exitAnimation,
  });

  final VoidCallback? onIntroComplete;
  final Animation<double>? exitAnimation;

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

    // Intro: staggered letters + flanking lines ≈ 1.85s, затем hold.
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

  Widget _flankingLine({
    required double width,
    required BrandAccentHairlineSide side,
    required Alignment scaleAlign,
    required Duration delay,
    required bool playIntro,
  }) {
    final line = BrandAccentHairline(
      width: width,
      height: 2.5,
      side: side,
    );
    if (!playIntro) return line;
    return line
        .animate()
        .fadeIn(
          delay: delay,
          duration: 520.ms,
          curve: Curves.easeOutCubic,
        )
        .scaleX(
          begin: 0.08,
          end: 1,
          delay: delay,
          duration: 780.ms,
          curve: Curves.easeOutCubic,
          alignment: scaleAlign,
        )
        .moveX(
          begin: scaleAlign == Alignment.centerRight ? 10 : -10,
          end: 0,
          delay: delay,
          duration: 780.ms,
          curve: Curves.easeOutCubic,
        );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final shortest = math.min(size.width, size.height);
    final zozuSize = (shortest * 0.168).clamp(42.0, 78.0);
    final gamesSize = (zozuSize * 0.38).clamp(16.0, 28.0);
    final lineWidth = (gamesSize * 2.15).clamp(28.0, 56.0);

    final exitListenable = widget.exitAnimation ?? const AlwaysStoppedAnimation(0.0);

    return AnimatedBuilder(
      animation: Listenable.merge([_ambient, exitListenable]),
      builder: (context, _) {
        final exitT = widget.exitAnimation?.value ?? 0.0;
        // Фон + бренд уходят раньше; стрелки едут вниз.
        final brandFade =
            (1.0 - Curves.easeInCubic.transform((exitT / 0.38).clamp(0.0, 1.0)));
        final handoffT = ((exitT - 0.18) / 0.62).clamp(0.0, 1.0);
        final handoff = Curves.easeInOutCubic.transform(handoffT);
        final linesFade = exitT < 0.78
            ? 1.0
            : (1.0 -
                Curves.easeIn.transform(((exitT - 0.78) / 0.22).clamp(0.0, 1.0)));

        // От центра экрана к подписи нижнего тулбара.
        final slideY = handoff * (size.height * 0.5 - bottomInset - 54);
        final gap = lerpDouble(gamesSize * 0.55, 10, handoff)!;
        final w = lerpDouble(lineWidth, 33.0, handoff)!;
        // Ширина слота подписи: от «GAMES» к короткой подписи таба.
        final centerSlot = lerpDouble(gamesSize * 5.2, 52, handoff)!;
        final playIntro = exitT == 0;

        return Opacity(
          opacity: exitT >= 0.995 ? 0 : 1,
          child: ColoredBox(
            color: AppColors.surfaceUnified.withValues(alpha: brandFade),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: brandFade,
                  child: CustomPaint(
                    painter: _BootAtmospherePainter(_ambient.value),
                    size: Size.infinite,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: brandFade,
                        child: _StaggeredBrandRow(
                          text: _brand,
                          fontSize: zozuSize,
                          letterSpacing: zozuSize * 0.04,
                          animate: playIntro,
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
                      ),
                      SizedBox(height: zozuSize * 0.28),
                      // GAMES остаётся на месте и гаснет; стрелки съезжают вниз.
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Opacity(
                            opacity: brandFade,
                            child: _StaggeredBrandRow(
                              text: _sub,
                              fontSize: gamesSize,
                              letterSpacing: gamesSize * 0.42,
                              delayBase: 620.ms,
                              stagger: 55.ms,
                              weight: FontWeight.w600,
                              color: AppColors.textPrimary
                                  .withValues(alpha: 0.78),
                              uppercase: true,
                              animate: playIntro,
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(0, slideY),
                            child: Opacity(
                              opacity: linesFade,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Transform.translate(
                                    offset: Offset(
                                      0,
                                      -gamesSize * 0.06 * (1 - handoff),
                                    ),
                                    child: _flankingLine(
                                      width: w,
                                      side: BrandAccentHairlineSide
                                          .fadeOutsideLeft,
                                      scaleAlign: Alignment.centerRight,
                                      delay: 560.ms,
                                      playIntro: playIntro,
                                    ),
                                  ),
                                  SizedBox(width: gap),
                                  SizedBox(width: centerSlot),
                                  SizedBox(width: gap),
                                  Transform.translate(
                                    offset: Offset(
                                      0,
                                      -gamesSize * 0.06 * (1 - handoff),
                                    ),
                                    child: _flankingLine(
                                      width: w,
                                      side: BrandAccentHairlineSide
                                          .fadeOutsideRight,
                                      scaleAlign: Alignment.centerLeft,
                                      delay: 640.ms,
                                      playIntro: playIntro,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    this.animate = true,
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
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final chars = charactersOf(uppercase ? text.toUpperCase() : text);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < chars.length; i++) ...[
          if (i > 0) SizedBox(width: letterSpacing),
          Builder(
            builder: (context) {
              final glyph = _LetterGlyph(
                char: chars[i],
                fontSize: fontSize,
                weight: weight,
                gradient: gradient,
                color: color,
              );
              if (!animate) return glyph;
              return glyph
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
                  );
            },
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

/// Мягкие «орбы» на фоне — атмосфера без неонового glow.
class _BootAtmospherePainter extends CustomPainter {
  _BootAtmospherePainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

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
