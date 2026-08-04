import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/balance_gain_animation.dart';

/// Салют при победе — общий для всех игр.
class GameConfettiOverlay extends StatefulWidget {
  const GameConfettiOverlay({super.key, this.particleCount = 150});

  final int particleCount;

  @override
  State<GameConfettiOverlay> createState() => _GameConfettiOverlayState();
}

class _GameConfettiOverlayState extends State<GameConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();

    final r = math.Random();
    const colors = [
      AppColors.accentStart,
      AppColors.accentEnd,
      Color(0xFFEC4899),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
    ];
    for (var i = 0; i < widget.particleCount; i++) {
      _particles.add(_ConfettiParticle(
        angle: r.nextDouble() * 2 * math.pi,
        speed: 350 + r.nextDouble() * 450,
        color: colors[r.nextInt(colors.length)],
        size: 4 + r.nextDouble() * 6,
        rotationSpeed: (r.nextDouble() * 2 - 1) * 8,
        gravity: 280 + r.nextDouble() * 120,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.rotationSpeed,
    required this.gravity,
  });

  final double angle;
  final double speed;
  final Color color;
  final double size;
  final double rotationSpeed;
  final double gravity;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});

  final List<_ConfettiParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.35;
    const burstT = 0.12;
    const fadeStart = 0.55;
    final scale = math.min(size.width, size.height) / 400;

    for (final p in particles) {
      if (progress < burstT) {
        final t = progress / burstT;
        _drawParticle(
          canvas,
          centerX + math.cos(p.angle) * p.speed * t * scale,
          centerY + math.sin(p.angle) * p.speed * t * scale,
          p,
          t * 2 * math.pi,
          1,
        );
      } else {
        final fallT = (progress - burstT) / (1 - burstT);
        final burstX = centerX + math.cos(p.angle) * p.speed * scale;
        final burstY = centerY + math.sin(p.angle) * p.speed * scale;
        final alpha =
            1.0 - ((progress - fadeStart) / (1 - fadeStart)).clamp(0.0, 1.0);
        if (alpha > 0.01) {
          _drawParticle(
            canvas,
            burstX + math.sin(fallT * 2) * 20,
            burstY + p.gravity * fallT * fallT * scale * 1.5,
            p,
            fallT * p.rotationSpeed * math.pi,
            alpha,
          );
        }
      }
    }
  }

  void _drawParticle(
    Canvas canvas,
    double x,
    double y,
    _ConfettiParticle p,
    double rotation,
    double alpha,
  ) {
    final paint = Paint()
      ..color = p.color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset.zero, width: p.size, height: p.size * 0.6),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}

/// Строка статуса партии («Ваш ход», «Ход X», «Вы выиграли») со значком.
class GameStatusLine extends StatelessWidget {
  const GameStatusLine({
    super.key,
    required this.text,
    this.leading,
    this.highlight = false,
  });

  final String text;

  /// Значок хода — фигура игрока / масть / что угодно.
  final Widget? leading;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: highlight ? AppColors.accentStart : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

/// Действия в AppBar экрана партии — общий набор для всех игр.
/// Кнопки показываются только если передан соответствующий колбэк.
List<Widget> buildGameAppBarActions({
  required BuildContext context,
  VoidCallback? onSurrender,
  String? surrenderTooltip,
  VoidCallback? onOfferDraw,
  String? drawTooltip,
  required VoidCallback onShowRules,
  required String rulesTooltip,
}) {
  const constraints = BoxConstraints(minWidth: 40, minHeight: 40);
  return [
    if (onSurrender != null)
      IconButton(
        padding: EdgeInsets.zero,
        constraints: constraints,
        iconSize: 22,
        icon: const Icon(Icons.flag_outlined),
        tooltip: surrenderTooltip,
        onPressed: onSurrender,
      ),
    if (onOfferDraw != null)
      IconButton(
        padding: EdgeInsets.zero,
        constraints: constraints,
        iconSize: 22,
        icon: const Icon(Icons.handshake_outlined),
        tooltip: drawTooltip,
        onPressed: onOfferDraw,
      ),
    IconButton(
      padding: EdgeInsets.zero,
      constraints: constraints,
      iconSize: 22,
      icon: const Icon(Icons.rule_rounded),
      tooltip: rulesTooltip,
      onPressed: onShowRules,
    ),
  ];
}

/// Диалог подтверждения (сдаться / выйти / ничья) — общий стиль.
Future<bool> confirmGameActionDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String cancelLabel,
  required String confirmLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.accentStart),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Начисление выигрыша с анимацией баланса — общий сценарий для всех игр.
///
/// [creditBronze] — сколько реально придёт на баланс (банк),
/// [displayRewardBronze] — что показать в «+N» (чистый выигрыш).
/// Возвращает false, если анимация не запускалась.
Future<bool> playGameSettledReward({
  required WidgetRef ref,
  required BuildContext context,
  required int creditBronze,
  required int displayRewardBronze,
  GlobalKey? sourceKey,
}) async {
  if (creditBronze <= 0) {
    unawaited(ref.read(authStateProvider.notifier).refresh());
    return false;
  }
  final fromBalance =
      ref.read(authStateProvider).valueOrNull?.balanceBronze ?? 0;
  final reward = displayRewardBronze > 0 ? displayRewardBronze : creditBronze;
  // Держим тулбар на старом значении до конца анимации.
  lockBalanceDisplay(
    ref: ref,
    fromBronze: fromBalance,
    toBronze: fromBalance + creditBronze,
    rewardBronze: reward,
  );
  try {
    await ref.read(authStateProvider.notifier).refresh();
    if (!context.mounted) return false;
    final toBalance =
        ref.read(authStateProvider).valueOrNull?.balanceBronze ?? fromBalance;
    if (toBalance <= fromBalance) return false;
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) return false;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!context.mounted) return false;
    await playBalanceGain(
      ref: ref,
      context: context,
      newBalanceBronze: toBalance,
      fromBronze: fromBalance,
      rewardBronze: reward,
      sourceKey: sourceKey,
      skipApply: true,
    );
    return true;
  } finally {
    if (ref.read(balanceGainProvider).active) {
      ref.read(balanceGainProvider.notifier).end();
    }
  }
}
