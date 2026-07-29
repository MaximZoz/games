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
/// intro-анимация. Затем:
/// - авторизован → стрелки съезжают к тулбару;
/// - гость → стрелки дугами рисуют рамку карточки входа.
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
  BootHandoffMode _handoffMode = BootHandoffMode.toolbar;
  late final AnimationController _exit;

  @override
  void initState() {
    super.initState();
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
    )..addListener(_onExitTick);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(bootSplashEnabledProvider) && !_gone) {
        ref.read(bootToolbarHairlinesOpacityProvider.notifier).state = 0;
      }
    });
  }

  void _onExitTick() {
    if (!mounted) return;
    final v = _exit.value;
    if (_handoffMode == BootHandoffMode.toolbar) {
      final opacity = v <= 0
          ? 0.0
          : ((v - 0.72) / 0.28).clamp(0.0, 1.0);
      final notifier = ref.read(bootToolbarHairlinesOpacityProvider.notifier);
      if ((notifier.state - opacity).abs() > 0.01 ||
          opacity == 0 ||
          opacity == 1) {
        notifier.state = opacity;
      }
    } else {
      // Рамка карточки проявляется в конце обводки.
      final borderOpacity = ((v - 0.82) / 0.18).clamp(0.0, 1.0);
      final borderNotifier =
          ref.read(bootLoginCardBorderOpacityProvider.notifier);
      if ((borderNotifier.state - borderOpacity).abs() > 0.01 ||
          borderOpacity == 0 ||
          borderOpacity == 1) {
        borderNotifier.state = borderOpacity;
      }
      // Тулбар на /login скрыт — сразу полный opacity на всякий случай.
      if (v > 0 && ref.read(bootToolbarHairlinesOpacityProvider) < 1) {
        ref.read(bootToolbarHairlinesOpacityProvider.notifier).state = 1;
      }
    }
  }

  @override
  void dispose() {
    _exit.removeListener(_onExitTick);
    _exit.dispose();
    super.dispose();
  }

  void _tryDismiss({required bool authReady}) {
    if (_gone || _dismissing || !_introDone || !authReady) return;
    _dismissing = true;
    final loggedIn = ref.read(authStateProvider).valueOrNull != null;
    _handoffMode =
        loggedIn ? BootHandoffMode.toolbar : BootHandoffMode.loginFrame;
    _exit.duration = loggedIn
        ? const Duration(milliseconds: 980)
        : const Duration(milliseconds: 1450);
    if (!loggedIn) {
      ref.read(bootLoginCardBorderOpacityProvider.notifier).state = 0;
      ref.read(bootToolbarHairlinesOpacityProvider.notifier).state = 1;
    }
    setState(() {});
    Future<void> runExit() async {
      if (!loggedIn) {
        // Дать router'у открыть /login и измерить карточку.
        await Future<void>.delayed(const Duration(milliseconds: 80));
        if (!mounted) return;
        await WidgetsBinding.instance.endOfFrame;
      }
      if (!mounted) return;
      await _exit.forward();
      if (!mounted) return;
      ref.read(bootToolbarHairlinesOpacityProvider.notifier).state = 1;
      ref.read(bootLoginCardBorderOpacityProvider.notifier).state = 1;
      setState(() => _gone = true);
    }

    runExit();
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
            handoffMode: _handoffMode,
            loginCardKey: ref.read(bootLoginCardKeyProvider),
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
    this.handoffMode = BootHandoffMode.toolbar,
    this.loginCardKey,
  });

  final VoidCallback? onIntroComplete;
  final Animation<double>? exitAnimation;
  final BootHandoffMode handoffMode;
  final GlobalKey? loginCardKey;

  @override
  State<ZozuBootSplash> createState() => _ZozuBootSplashState();
}

class _ZozuBootSplashState extends State<ZozuBootSplash>
    with SingleTickerProviderStateMixin {
  static const _brand = 'Zozu';
  static const _sub = 'Games';

  late final AnimationController _ambient;
  final GlobalKey _leftLineKey = GlobalKey();
  final GlobalKey _rightLineKey = GlobalKey();
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat(reverse: true);

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

  Rect? _globalRectOf(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  Rect _estimateLoginCard(Size screen) {
    final maxW = math.min(screen.width - 48, 420.0);
    final h = math.min(screen.height * 0.55, 460.0);
    final left = (screen.width - maxW) / 2;
    final top = (screen.height - h) / 2;
    return Rect.fromLTWH(left, top, maxW, h);
  }

  Widget _flankingLine({
    required Key key,
    required double width,
    required BrandAccentHairlineSide side,
    required Alignment scaleAlign,
    required Duration delay,
    required bool playIntro,
  }) {
    Widget line = BrandAccentHairline(
      width: width,
      height: 2.5,
      side: side,
    );
    if (playIntro) {
      line = line
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
    return KeyedSubtree(key: key, child: line);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final shortest = math.min(size.width, size.height);
    final zozuSize = (shortest * 0.168).clamp(42.0, 78.0);
    final gamesSize = (zozuSize * 0.38).clamp(16.0, 28.0);
    final lineWidth = (gamesSize * 2.15).clamp(28.0, 56.0);

    final exitListenable =
        widget.exitAnimation ?? const AlwaysStoppedAnimation(0.0);

    return AnimatedBuilder(
      animation: Listenable.merge([_ambient, exitListenable]),
      builder: (context, _) {
        final exitT = widget.exitAnimation?.value ?? 0.0;
        final toLogin = widget.handoffMode == BootHandoffMode.loginFrame;
        final brandFade = (1.0 -
            Curves.easeInCubic.transform((exitT / 0.34).clamp(0.0, 1.0)));
        final playIntro = exitT == 0;

        // --- Toolbar handoff ---
        final handoffT = ((exitT - 0.18) / 0.62).clamp(0.0, 1.0);
        final handoff = Curves.easeInOutCubic.transform(handoffT);
        final linesFadeToolbar = exitT < 0.78
            ? 1.0
            : (1.0 -
                Curves.easeIn
                    .transform(((exitT - 0.78) / 0.22).clamp(0.0, 1.0)));
        final slideY = handoff * (size.height * 0.5 - bottomInset - 54);
        final gap = lerpDouble(gamesSize * 0.55, 10, handoff)!;
        final w = lerpDouble(lineWidth, 33.0, handoff)!;
        final centerSlot = lerpDouble(gamesSize * 5.2, 52, handoff)!;

        // --- Login frame handoff ---
        final linesFadeLogin = exitT == 0
            ? 1.0
            : (1.0 -
                Curves.easeIn.transform((exitT / 0.18).clamp(0.0, 1.0)));
        final drawProgress = Curves.easeInOutCubic
            .transform(((exitT - 0.08) / 0.84).clamp(0.0, 1.0));
        final paintFade = exitT < 0.88
            ? 1.0
            : (1.0 -
                Curves.easeIn
                    .transform(((exitT - 0.88) / 0.12).clamp(0.0, 1.0)));

        final leftRect = _globalRectOf(_leftLineKey);
        final rightRect = _globalRectOf(_rightLineKey);
        final cardKey = widget.loginCardKey;
        final cardRect = (cardKey != null ? _globalRectOf(cardKey) : null) ??
            _estimateLoginCard(size);
        final leftStart = leftRect?.center ??
            Offset(size.width * 0.28, size.height * 0.48);
        final rightStart = rightRect?.center ??
            Offset(size.width * 0.72, size.height * 0.48);

        final showToolbarLines = !toLogin || exitT == 0;
        final toolbarLinesOpacity = toLogin ? linesFadeLogin : linesFadeToolbar;
        final toolbarSlide = toLogin ? 0.0 : slideY;
        final toolbarHandoff = toLogin ? 0.0 : handoff;
        final toolbarW = toLogin ? lineWidth : w;
        final toolbarGap = toLogin ? gamesSize * 0.55 : gap;
        final toolbarSlot = toLogin ? gamesSize * 5.2 : centerSlot;

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
                if (toLogin && exitT > 0.02)
                  Opacity(
                    opacity: paintFade,
                    child: CustomPaint(
                      painter: _LoginFrameDrawPainter(
                        progress: drawProgress,
                        leftStart: leftStart,
                        rightStart: rightStart,
                        card: RRect.fromRectAndRadius(
                          cardRect,
                          const Radius.circular(AppRadius.card + 2),
                        ),
                        strokeWidth: 2.5,
                      ),
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
                          if (showToolbarLines || toolbarLinesOpacity > 0.01)
                            Transform.translate(
                              offset: Offset(0, toolbarSlide),
                              child: Opacity(
                                opacity: toolbarLinesOpacity,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Transform.translate(
                                      offset: Offset(
                                        0,
                                        -gamesSize *
                                            0.06 *
                                            (1 - toolbarHandoff),
                                      ),
                                      child: _flankingLine(
                                        key: _leftLineKey,
                                        width: toolbarW,
                                        side: BrandAccentHairlineSide
                                            .fadeOutsideLeft,
                                        scaleAlign: Alignment.centerRight,
                                        delay: 560.ms,
                                        playIntro: playIntro,
                                      ),
                                    ),
                                    SizedBox(width: toolbarGap),
                                    SizedBox(width: toolbarSlot),
                                    SizedBox(width: toolbarGap),
                                    Transform.translate(
                                      offset: Offset(
                                        0,
                                        -gamesSize *
                                            0.06 *
                                            (1 - toolbarHandoff),
                                      ),
                                      child: _flankingLine(
                                        key: _rightLineKey,
                                        width: toolbarW,
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

/// Две стрелки: дуга к верху карточки, затем половина рамки каждая.
class _LoginFrameDrawPainter extends CustomPainter {
  _LoginFrameDrawPainter({
    required this.progress,
    required this.leftStart,
    required this.rightStart,
    required this.card,
    required this.strokeWidth,
  });

  final double progress;
  final Offset leftStart;
  final Offset rightStart;
  final RRect card;
  final double strokeWidth;

  static const _approachEnd = 0.32;

  Path _approachPath(Offset start, Offset end, {required bool left}) {
    final dx = left ? -math.max(36.0, (start.dx - end.dx).abs() * 0.35) : math.max(36.0, (end.dx - start.dx).abs() * 0.35);
    final control = Offset(
      (start.dx + end.dx) / 2 + dx,
      (start.dy + end.dy) / 2 - 12,
    );
    return Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
  }

  Path _leftHalfFrame(RRect r) {
    final rect = r.outerRect;
    final rad = r.tlRadiusX;
    final topCenter = Offset(rect.center.dx, rect.top);
    final path = Path()..moveTo(topCenter.dx, topCenter.dy);
    path.lineTo(rect.left + rad, rect.top);
    path.arcToPoint(
      Offset(rect.left, rect.top + rad),
      radius: Radius.circular(rad),
      clockwise: false,
    );
    path.lineTo(rect.left, rect.bottom - rad);
    path.arcToPoint(
      Offset(rect.left + rad, rect.bottom),
      radius: Radius.circular(rad),
      clockwise: false,
    );
    path.lineTo(rect.center.dx, rect.bottom);
    return path;
  }

  Path _rightHalfFrame(RRect r) {
    final rect = r.outerRect;
    final rad = r.trRadiusX;
    final topCenter = Offset(rect.center.dx, rect.top);
    final path = Path()..moveTo(topCenter.dx, topCenter.dy);
    path.lineTo(rect.right - rad, rect.top);
    path.arcToPoint(
      Offset(rect.right, rect.top + rad),
      radius: Radius.circular(rad),
      clockwise: true,
    );
    path.lineTo(rect.right, rect.bottom - rad);
    path.arcToPoint(
      Offset(rect.right - rad, rect.bottom),
      radius: Radius.circular(rad),
      clockwise: true,
    );
    path.lineTo(rect.center.dx, rect.bottom);
    return path;
  }

  Path _trim(Path path, double t) {
    if (t <= 0) return Path();
    if (t >= 1) return path;
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return Path();
    final total = metrics.fold<double>(0, (s, m) => s + m.length);
    var remain = total * t;
    final out = Path();
    for (final m in metrics) {
      if (remain <= 0) break;
      final take = math.min(m.length, remain);
      out.addPath(m.extractPath(0, take), Offset.zero);
      remain -= take;
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    if (t <= 0) return;

    final topCenter = Offset(card.outerRect.center.dx, card.outerRect.top);
    final approachLeft = _approachPath(leftStart, topCenter, left: true);
    final approachRight = _approachPath(rightStart, topCenter, left: false);
    final leftFrame = _leftHalfFrame(card);
    final rightFrame = _rightHalfFrame(card);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      ).createShader(card.outerRect);

    if (t <= _approachEnd) {
      final local = Curves.easeOutCubic.transform(t / _approachEnd);
      canvas.drawPath(_trim(approachLeft, local), paint);
      canvas.drawPath(_trim(approachRight, local), paint);
      return;
    }

    // Полные дуги подхода + половинки рамки.
    canvas.drawPath(approachLeft, paint);
    canvas.drawPath(approachRight, paint);
    final frameT = Curves.easeInOutCubic
        .transform(((t - _approachEnd) / (1 - _approachEnd)).clamp(0.0, 1.0));
    canvas.drawPath(_trim(leftFrame, frameT), paint);
    canvas.drawPath(_trim(rightFrame, frameT), paint);
  }

  @override
  bool shouldRepaint(covariant _LoginFrameDrawPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.leftStart != leftStart ||
      oldDelegate.rightStart != rightStart ||
      oldDelegate.card != card;
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
