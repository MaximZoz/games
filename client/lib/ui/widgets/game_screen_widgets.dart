import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/games/games_provider.dart' show GameInvite;
import 'package:multigames_client/games/games_repository.dart'
    show formatStakeAmount, stakeCoinType;
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/widgets/balance_gain_animation.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';
import 'package:multigames_client/ui/widgets/gradient_card.dart';

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

const _presetAvatarIcons = <IconData>[
  Icons.face_rounded,
  Icons.face_2_rounded,
  Icons.face_3_rounded,
  Icons.face_4_rounded,
  Icons.face_5_rounded,
  Icons.face_6_rounded,
  Icons.sports_esports_rounded,
  Icons.pets_rounded,
  Icons.rocket_launch_rounded,
  Icons.emoji_emotions_rounded,
];

/// Аватар игрока в рамке — общий для экранов партий.
class GamePlayerAvatar extends StatelessWidget {
  const GamePlayerAvatar({
    super.key,
    required this.displayName,
    required this.avatarKind,
    required this.avatarValue,
    this.frameCode,
    this.frameColor,
    this.compact = false,
  });

  final String displayName;
  final String avatarKind;
  final String? avatarValue;
  final String? frameCode;
  final String? frameColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final r = compact ? 18.0 : 22.0;
    Widget avatar;
    if (avatarKind == 'file' &&
        avatarValue != null &&
        avatarValue!.trim().isNotEmpty) {
      final img = AvatarMemoryCache.fromAvatarValue(avatarValue);
      avatar = img != null
          ? CircleAvatar(radius: r, backgroundImage: img)
          : _letter(r);
    } else if (avatarKind == 'preset' && avatarValue != null) {
      final idx = int.tryParse(avatarValue!);
      avatar = (idx != null && idx >= 0 && idx < _presetAvatarIcons.length)
          ? CircleAvatar(
              radius: r,
              backgroundColor: AppColors.accentSoft,
              child:
                  Icon(_presetAvatarIcons[idx], color: AppColors.accentStart),
            )
          : _letter(r);
    } else {
      avatar = _letter(r);
    }
    return FramedAvatar(
      size: r * 2,
      borderWidth: compact ? 2.4 : 3.0,
      frameCode: frameCode,
      frameColor: frameColor,
      animate: false,
      child: avatar,
    );
  }

  Widget _letter(double r) {
    final letter =
        displayName.trim().isEmpty ? '?' : displayName[0].toUpperCase();
    return CircleAvatar(
      radius: r,
      backgroundColor: AppColors.accentSoft,
      child: Text(
        letter,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 14 : 16,
        ),
      ),
    );
  }
}

/// Иконка-кнопка со счётчиком непрочитанного.
class GameIconWithBadge extends StatelessWidget {
  const GameIconWithBadge({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final int badge;

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    final btn = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.accentStart,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(size, size),
        fixedSize: const Size(size, size),
      ),
    );
    if (badge <= 0) return SizedBox(width: size, height: size, child: btn);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          btn,
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Рамка с соперником: аватар (тап — профиль), имя, чат и «в друзья».
/// Общая для всех игр 1×1 (крестики-нолики, дурак, …).
class GameOpponentCard extends StatelessWidget {
  const GameOpponentCard({
    super.key,
    required this.displayName,
    required this.avatarKind,
    required this.avatarValue,
    this.frameCode,
    this.frameColor,
    this.isBot = false,
    this.messageUnread = 0,
    required this.onInfoTap,
    this.onMessageTap,
    this.infoTooltip = '',
    this.messageTooltip = '',
    this.showAddFriend = false,
    this.addFriendEnabled = true,
    this.addFriendBadge = 0,
    this.addFriendTooltip = '',
    this.onAddFriendTap,
    this.trailing = const <Widget>[],
    this.compact = false,
    this.maxWidth = 400,
    this.align,
    this.borderWidth = 2,
  });

  final String displayName;
  final String avatarKind;
  final String? avatarValue;
  final String? frameCode;
  final String? frameColor;
  final bool isBot;
  final int messageUnread;
  final VoidCallback onInfoTap;
  final VoidCallback? onMessageTap;
  final String infoTooltip;
  final String messageTooltip;

  /// Кнопка «добавить в друзья» (как в крестиках-ноликах).
  final bool showAddFriend;
  final bool addFriendEnabled;
  final int addFriendBadge;
  final String addFriendTooltip;
  final VoidCallback? onAddFriendTap;

  /// Доп. кнопки справа.
  final List<Widget> trailing;
  final bool compact;
  final double maxWidth;

  /// Если null — карточка по центру (как раньше). Иначе — Align.
  final Alignment? align;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final card = GradientCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 8 : 12,
      ),
      margin: EdgeInsets.zero,
      animate: false,
      borderWidth: borderWidth,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Tooltip(
            message: infoTooltip,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onInfoTap,
                behavior: HitTestBehavior.opaque,
                child: GamePlayerAvatar(
                  displayName: displayName,
                  avatarKind: avatarKind,
                  avatarValue: avatarValue,
                  frameCode: frameCode,
                  frameColor: frameColor,
                  compact: compact,
                ),
              ),
            ),
          ),
          SizedBox(width: compact ? 10 : 14),
          Flexible(
            child: Text(
              displayName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: compact ? 14 : 16,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isBot && onMessageTap != null)
            GameIconWithBadge(
              icon: Icons.chat_bubble_outline_rounded,
              badge: messageUnread,
              tooltip: messageTooltip,
              onPressed: onMessageTap,
            ),
          if (!isBot && showAddFriend)
            GameIconWithBadge(
              icon: Icons.person_add_alt_1_rounded,
              badge: addFriendBadge,
              tooltip: addFriendTooltip,
              onPressed: addFriendEnabled ? onAddFriendTap : null,
            ),
          ...trailing,
        ],
      ),
    );
    final boxed = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: card,
    );
    // widthFactor/heightFactor — не растягивать Align на всю ширину родителя.
    return Align(
      alignment: align ?? Alignment.center,
      widthFactor: 1,
      heightFactor: 1,
      child: boxed,
    );
  }
}

/// Overlay «сдаться» / «ничья» справа сверху под кнопкой правил.
/// Общий для 1×1 партий (крестики-нолики, дурак).
class GameActionsOverlay extends StatefulWidget {
  const GameActionsOverlay({
    super.key,
    required this.canDraw,
    required this.iOfferedDraw,
    required this.opponentOfferedDraw,
    required this.onSurrender,
    required this.onDraw,
    required this.surrenderTooltip,
    required this.drawTooltip,
    required this.acceptDrawTooltip,
    required this.drawOfferedTooltip,
  });

  final bool canDraw;
  final bool iOfferedDraw;
  final bool opponentOfferedDraw;
  final VoidCallback onSurrender;
  final VoidCallback onDraw;
  final String surrenderTooltip;
  final String drawTooltip;
  final String acceptDrawTooltip;
  final String drawOfferedTooltip;

  @override
  State<GameActionsOverlay> createState() => _GameActionsOverlayState();
}

class _GameActionsOverlayState extends State<GameActionsOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;
  late final Animation<Color?> _color;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _color = ColorTween(
      begin: AppColors.accentStart,
      end: AppColors.textPrimary,
    ).animate(_blink);
    _applyBlink();
  }

  @override
  void didUpdateWidget(covariant GameActionsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.opponentOfferedDraw != widget.opponentOfferedDraw) {
      _applyBlink();
    }
  }

  void _applyBlink() {
    if (widget.opponentOfferedDraw) {
      _blink.repeat(reverse: true);
    } else {
      _blink.stop();
      _blink.value = 0;
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          iconSize: 22,
          icon: const Icon(Icons.flag_outlined),
          tooltip: widget.surrenderTooltip,
          onPressed: widget.onSurrender,
        ),
        if (widget.canDraw) ...[
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _color,
            builder: (_, child) => child!,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              iconSize: 22,
              icon: Icon(
                widget.opponentOfferedDraw
                    ? Icons.handshake_rounded
                    : Icons.handshake_outlined,
                color: widget.opponentOfferedDraw
                    ? _color.value
                    : (widget.iOfferedDraw
                        ? AppColors.accentStart.withValues(alpha: 0.45)
                        : null),
              ),
              tooltip: widget.opponentOfferedDraw
                  ? widget.acceptDrawTooltip
                  : (widget.iOfferedDraw
                      ? widget.drawOfferedTooltip
                      : widget.drawTooltip),
              onPressed: widget.iOfferedDraw ? null : widget.onDraw,
            ),
          ),
        ],
      ],
    );
  }
}

/// Обратный отсчёт до конца хода — общий для всех игр.
/// [onExpired] вызывается один раз, когда время вышло.
class GameTurnCountdown extends StatefulWidget {
  const GameTurnCountdown({
    super.key,
    required this.turnDeadline,
    required this.isMyTurn,
    required this.onExpired,
    required this.labelBuilder,
    this.turnTimeSec = 0,
  });

  /// Unix-время (сек) окончания хода.
  final int turnDeadline;
  final bool isMyTurn;
  final VoidCallback onExpired;

  /// Полная длительность хода (сек) — для зелёный→оранжевый→красный.
  final int turnTimeSec;

  /// Локализованная подпись, например `(s) => l10n.gameSecondsLeft(s)`.
  final String Function(int secondsLeft) labelBuilder;

  @override
  State<GameTurnCountdown> createState() => _GameTurnCountdownState();
}

class _GameTurnCountdownState extends State<GameTurnCountdown> {
  Timer? _timer;
  int _remaining = 0;
  bool _expiredFired = false;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant GameTurnCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.turnDeadline != widget.turnDeadline) {
      _expiredFired = false;
      _timer?.cancel();
      _updateRemaining();
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
      if (_remaining <= 0 && !_expiredFired) {
        _expiredFired = true;
        widget.onExpired();
      }
    });
  }

  void _updateRemaining() {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final r = widget.turnDeadline - now;
    if (r != _remaining && mounted) {
      setState(() => _remaining = r.clamp(0, 999));
    } else if (r <= 0 && _remaining != 0 && mounted) {
      setState(() => _remaining = 0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.turnTimeSec > 0 ? widget.turnTimeSec : 60;
    final fraction = (_remaining / total).clamp(0.0, 1.0);
    final color = widget.isMyTurn
        ? TurnTimerStyle.colorsFor(hasTimer: true, fraction: fraction).first
        : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          widget.labelBuilder(_remaining),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

/// Цвет/градиент таймера хода: много времени — зелёный, мало — красный;
/// без лимита — мягкий фиолетовый.
class TurnTimerStyle {
  TurnTimerStyle._();

  static const Color noTimerA = Color(0xFF8B5CF6);
  static const Color noTimerB = Color(0xFFA78BFA);
  static const Color green = Color(0xFF34D399);
  static const Color orange = Color(0xFFFBBF24);
  static const Color red = Color(0xFFF87171);

  /// [fraction] = оставшаяся доля времени 0..1.
  static List<Color> colorsFor({
    required bool hasTimer,
    required double fraction,
  }) {
    if (!hasTimer) return const [noTimerA, noTimerB];
    final t = fraction.clamp(0.0, 1.0);
    if (t > 0.45) {
      final k = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
      return [
        Color.lerp(orange, green, k)!,
        Color.lerp(orange.withValues(alpha: 0.75), green.withValues(alpha: 0.85), k)!,
      ];
    }
    if (t > 0.18) {
      final k = ((t - 0.18) / 0.27).clamp(0.0, 1.0);
      return [
        Color.lerp(red, orange, k)!,
        Color.lerp(red.withValues(alpha: 0.8), orange.withValues(alpha: 0.75), k)!,
      ];
    }
    return [red, red.withValues(alpha: 0.7)];
  }
}

/// Мягкий бордер-прогресс вокруг [child]: линия по периметру укорачивается.
class TurnTimerBorder extends StatefulWidget {
  const TurnTimerBorder({
    super.key,
    required this.child,
    required this.active,
    this.turnDeadline = 0,
    this.turnTimeSec = 0,
    this.borderWidth = 2.5,
    this.radius = 22,
    this.onExpired,
  });

  final Widget child;
  final bool active;
  final int turnDeadline;
  final int turnTimeSec;
  final double borderWidth;
  final double radius;
  final VoidCallback? onExpired;

  @override
  State<TurnTimerBorder> createState() => _TurnTimerBorderState();
}

class _TurnTimerBorderState extends State<TurnTimerBorder> {
  Timer? _timer;
  double _fraction = 1;
  bool _expiredFired = false;

  bool get _hasTimer => widget.turnTimeSec > 0 && widget.turnDeadline > 0;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant TurnTimerBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.turnDeadline != widget.turnDeadline) {
      _expiredFired = false;
      _tick();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!widget.active) return;
    if (!_hasTimer) {
      if (_fraction != 1 && mounted) setState(() => _fraction = 1);
      return;
    }
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final leftMs = widget.turnDeadline * 1000 - nowMs;
    final f = (leftMs / (widget.turnTimeSec * 1000)).clamp(0.0, 1.0);
    if ((f - _fraction).abs() > 0.002 && mounted) {
      setState(() => _fraction = f);
    }
    if (leftMs <= 0 && !_expiredFired) {
      _expiredFired = true;
      widget.onExpired?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    final colors = TurnTimerStyle.colorsFor(
      hasTimer: _hasTimer,
      fraction: _fraction,
    );
    return CustomPaint(
      foregroundPainter: _ShrinkingBorderPainter(
        // Без лимита — полный «таймерный» цвет; с лимитом — укорачивается,
        // а под ним всегда базовая фиолетовая рамка на том же месте.
        fraction: _hasTimer ? _fraction : 1,
        colors: colors,
        strokeWidth: widget.borderWidth,
        radius: widget.radius,
        baseColors: const [
          AppColors.accentStart,
          AppColors.accentEnd,
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(widget.borderWidth),
        child: widget.child,
      ),
    );
  }
}

class _ShrinkingBorderPainter extends CustomPainter {
  _ShrinkingBorderPainter({
    required this.fraction,
    required this.colors,
    required this.strokeWidth,
    required this.radius,
    this.baseColors = const [AppColors.accentStart, AppColors.accentEnd],
  });

  final double fraction;
  final List<Color> colors;
  final double strokeWidth;
  final double radius;

  /// Полная фиолетовая рамка — остаётся, когда таймер исчезает.
  final List<Color> baseColors;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    // 1) Базовая фиолетовая рамка на всём периметре.
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(colors: baseColors).createShader(rect);
    canvas.drawRRect(rrect, basePaint);

    // 2) Поверх — укорачивающийся таймер (зелёный→оранжевый→красный).
    final f = fraction.clamp(0.0, 1.0);
    if (f <= 0.001) return;
    for (final metric in path.computeMetrics()) {
      final len = metric.length * f;
      final extract = metric.extractPath(0, len);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: colors).createShader(rect);
      canvas.drawPath(extract, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShrinkingBorderPainter old) =>
      old.fraction != fraction ||
      old.strokeWidth != strokeWidth ||
      old.colors != colors ||
      old.baseColors != baseColors;
}

/// Рамка по границе всего приложения: время «съедается» сверху вниз симметрично.
///
/// Рисуется поверх [child] (обычно весь экран). При [fraction]=1 — полный контур;
/// по мере убывания верх пропадает, стороны укорачиваются сверху одинаково.
class TurnTimerAppFrame extends StatefulWidget {
  const TurnTimerAppFrame({
    super.key,
    required this.child,
    required this.active,
    this.turnDeadline = 0,
    this.turnTimeSec = 0,
    this.borderWidth = 3.0,
    this.radius = 28,
    this.onExpired,
  });

  final Widget child;
  final bool active;
  final int turnDeadline;
  final int turnTimeSec;
  final double borderWidth;
  final double radius;
  final VoidCallback? onExpired;

  @override
  State<TurnTimerAppFrame> createState() => _TurnTimerAppFrameState();
}

class _TurnTimerAppFrameState extends State<TurnTimerAppFrame> {
  Timer? _timer;
  double _fraction = 1;
  bool _expiredFired = false;

  bool get _hasTimer => widget.turnTimeSec > 0 && widget.turnDeadline > 0;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant TurnTimerAppFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.turnDeadline != widget.turnDeadline ||
        oldWidget.active != widget.active) {
      _expiredFired = false;
      _tick();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!widget.active) return;
    if (!_hasTimer) {
      if (_fraction != 1 && mounted) setState(() => _fraction = 1);
      return;
    }
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final leftMs = widget.turnDeadline * 1000 - nowMs;
    final f = (leftMs / (widget.turnTimeSec * 1000)).clamp(0.0, 1.0);
    if ((f - _fraction).abs() > 0.002 && mounted) {
      setState(() => _fraction = f);
    }
    if (leftMs <= 0 && !_expiredFired) {
      _expiredFired = true;
      widget.onExpired?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Всегда Stack на весь экран — рамка по краю приложения, не блока игры.
    final colors = TurnTimerStyle.colorsFor(
      hasTimer: _hasTimer,
      fraction: _hasTimer ? _fraction : 1,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (widget.active)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TopDownFramePainter(
                  fraction: _hasTimer ? _fraction : 1,
                  colors: colors,
                  strokeWidth: widget.borderWidth,
                  radius: widget.radius,
                  baseColors: const [
                    AppColors.accentStart,
                    AppColors.accentEnd,
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TopDownFramePainter extends CustomPainter {
  _TopDownFramePainter({
    required this.fraction,
    required this.colors,
    required this.strokeWidth,
    required this.radius,
    this.baseColors = const [AppColors.accentStart, AppColors.accentEnd],
  });

  final double fraction;
  final List<Color> colors;
  final double strokeWidth;
  final double radius;
  final List<Color> baseColors;

  void _strokeFrame(Canvas canvas, Rect rect, double f, Paint paint) {
    final left = rect.left;
    final right = rect.right;
    final top = rect.top;
    final bottom = rect.bottom;
    final h = rect.height;
    final w = rect.width;
    final rad = radius.clamp(0.0, math.min(w, h) / 2);

    if (f >= 0.995) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rad)),
        paint,
      );
      return;
    }

    // Симметрия: обе стороны укорачиваются сверху одинаково.
    final yCut = top + h * (1.0 - f);

    final u = Path();
    if (yCut < bottom - rad) {
      u.moveTo(left, yCut);
      u.lineTo(left, bottom - rad);
      u.arcToPoint(
        Offset(left + rad, bottom),
        radius: Radius.circular(rad),
        clockwise: false,
      );
      u.lineTo(right - rad, bottom);
      u.arcToPoint(
        Offset(right, bottom - rad),
        radius: Radius.circular(rad),
        clockwise: false,
      );
      u.lineTo(right, yCut);
    } else if (yCut < bottom) {
      // Почти только нижняя грань.
      final t = ((bottom - yCut) / rad).clamp(0.0, 1.0);
      final insetX = rad * (1 - t);
      u.moveTo(left + insetX, bottom);
      u.lineTo(right - insetX, bottom);
    }
    canvas.drawPath(u, paint);

    // Верх: сужается от краёв к центру в конце полного цикла (f → 1).
    if (f > 0.78) {
      final topT = ((f - 0.78) / 0.22).clamp(0.0, 1.0);
      final half = (w / 2 - rad) * topT + rad * topT;
      final mid = (left + right) / 2;
      canvas.drawLine(
        Offset(mid - half, top),
        Offset(mid + half, top),
        paint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // По самому краю экрана приложения.
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final f = fraction.clamp(0.0, 1.0);
    if (f <= 0.001) return;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.85
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(colors: baseColors).createShader(rect);
    _strokeFrame(canvas, rect, f, basePaint);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(colors: colors).createShader(rect);
    _strokeFrame(canvas, rect, f, paint);
  }

  @override
  bool shouldRepaint(covariant _TopDownFramePainter old) =>
      old.fraction != fraction ||
      old.strokeWidth != strokeWidth ||
      old.colors != colors ||
      old.baseColors != baseColors ||
      old.radius != radius;
}

/// Тонкая горизонтальная линия-прогресс внизу: укорачивается со временем.
class TurnTimerBottomBar extends StatefulWidget {
  const TurnTimerBottomBar({
    super.key,
    required this.active,
    this.turnDeadline = 0,
    this.turnTimeSec = 0,
    this.onExpired,
    this.height = 3,
  });

  final bool active;
  final int turnDeadline;
  final int turnTimeSec;
  final VoidCallback? onExpired;
  final double height;

  @override
  State<TurnTimerBottomBar> createState() => _TurnTimerBottomBarState();
}

class _TurnTimerBottomBarState extends State<TurnTimerBottomBar> {
  Timer? _timer;
  double _fraction = 1;
  bool _expiredFired = false;

  bool get _hasTimer => widget.turnTimeSec > 0 && widget.turnDeadline > 0;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant TurnTimerBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.turnDeadline != widget.turnDeadline ||
        oldWidget.active != widget.active) {
      _expiredFired = false;
      _tick();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!widget.active) return;
    if (!_hasTimer) {
      if (_fraction != 1 && mounted) setState(() => _fraction = 1);
      return;
    }
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final leftMs = widget.turnDeadline * 1000 - nowMs;
    final f = (leftMs / (widget.turnTimeSec * 1000)).clamp(0.0, 1.0);
    if ((f - _fraction).abs() > 0.002 && mounted) {
      setState(() => _fraction = f);
    }
    if (leftMs <= 0 && !_expiredFired) {
      _expiredFired = true;
      widget.onExpired?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();
    final colors = TurnTimerStyle.colorsFor(
      hasTimer: _hasTimer,
      fraction: _hasTimer ? _fraction : 1,
    );
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth * (_hasTimer ? _fraction : 1);
          return Align(
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.linear,
              width: w.clamp(0.0, constraints.maxWidth),
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(colors: colors),
                boxShadow: [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 0.2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
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

/// Статус партии и чип награды «+N» в одной строке (крестики / дурак).
class GameStatusWithReward extends StatelessWidget {
  const GameStatusWithReward({
    super.key,
    required this.statusText,
    required this.showReward,
    required this.rewardBronze,
    required this.rewardKey,
    this.fontSize,
  });

  final String statusText;
  final bool showReward;
  final int rewardBronze;
  final GlobalKey rewardKey;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          fontSize: fontSize,
        );
    if (!showReward) {
      return Text(
        statusText,
        textAlign: TextAlign.center,
        style: style,
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            statusText,
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
        const SizedBox(width: 8),
        GameRewardChip(
          key: rewardKey,
          rewardBronze: rewardBronze,
        ),
      ],
    );
  }
}

/// Чип чистого выигрыша — источник полёта монеты в баланс.
class GameRewardChip extends StatelessWidget {
  const GameRewardChip({
    super.key,
    required this.rewardBronze,
  });

  final int rewardBronze;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.accentSoft.withValues(alpha: 0.9),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+${formatStakeAmount(rewardBronze)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 5),
          CoinIcon(
            coinType: stakeCoinType(rewardBronze),
            size: 20,
            showBorder: true,
          ),
        ],
      ),
    );
  }
}

/// Блок «Повторить» / «Другой соперник» и принятие реванша — общий для игр.
class GameRematchSection extends StatelessWidget {
  const GameRematchSection({
    super.key,
    required this.rematchLobbyId,
    required this.rematchDeclined,
    required this.iDeclinedRematch,
    required this.isRematching,
    required this.isAcceptingRematch,
    required this.isFindingGame,
    required this.peerIds,
    required this.invites,
    required this.onRematch,
    required this.onAccept,
    required this.onDecline,
    required this.onCancelWait,
    required this.onFindGame,
    this.compact = false,
  });

  final String? rematchLobbyId;
  final bool rematchDeclined;
  final bool iDeclinedRematch;
  final bool isRematching;
  final bool isAcceptingRematch;
  final bool isFindingGame;
  final List<String> peerIds;
  final List<GameInvite> invites;
  final VoidCallback onRematch;
  final void Function(String lobbyId) onAccept;
  final void Function(String lobbyId) onDecline;
  final VoidCallback? onCancelWait;
  final VoidCallback onFindGame;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final peerSet = peerIds.toSet();
    final rematchOffer =
        invites.where((i) => peerSet.contains(i.creatorId)).firstOrNull;

    if (isAcceptingRematch) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_empty_rounded,
              size: 20, color: AppColors.accentStart),
          const SizedBox(width: 8),
          Text(
            context.l10n.gameConnecting,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    if (rematchOffer != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.gameRematchOffer,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: compact ? 13 : 14,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => onDecline(rematchOffer.lobbyId),
                child: Text(context.l10n.commonDecline),
              ),
              SizedBox(width: compact ? 8 : 12),
              FilledButton(
                onPressed: () => onAccept(rematchOffer.lobbyId),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentStart,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.l10n.commonAccept),
              ),
            ],
          ),
        ],
      );
    }
    if (iDeclinedRematch) {
      return _buildRematchButtons(context);
    }
    if (rematchDeclined) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.gameRematchDeclined,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: compact ? 13 : 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: compact ? 8 : 12),
          _buildRematchButtons(context),
        ],
      );
    }
    if (rematchLobbyId != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_empty_rounded,
                  size: compact ? 18 : 20, color: AppColors.accentStart),
              SizedBox(width: compact ? 6 : 8),
              Text(
                context.l10n.gameWaitingOpponent,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (onCancelWait != null) ...[
            SizedBox(height: compact ? 8 : 12),
            TextButton(
              onPressed: onCancelWait,
              child: Text(context.l10n.commonCancel),
            ),
          ],
        ],
      );
    }
    return _buildRematchButtons(context);
  }

  Widget _buildRematchButtons(BuildContext context) {
    final btnPadding = compact
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: compact ? 8 : 12,
      runSpacing: compact ? 6 : 8,
      children: [
        FilledButton.icon(
          onPressed: isRematching ? null : onRematch,
          icon: isRematching
              ? SizedBox(
                  width: compact ? 16 : 18,
                  height: compact ? 16 : 18,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(Icons.replay_rounded, size: compact ? 18 : 20),
          label: Text(isRematching
              ? context.l10n.commonCreating
              : context.l10n.gameRematch),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentStart,
            foregroundColor: Colors.white,
            padding: btnPadding,
          ),
        ),
        OutlinedButton.icon(
          onPressed: isFindingGame ? null : onFindGame,
          icon: isFindingGame
              ? SizedBox(
                  width: compact ? 16 : 18,
                  height: compact ? 16 : 18,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.search_rounded, size: compact ? 18 : 20),
          label: Text(isFindingGame
              ? context.l10n.commonSearching
              : context.l10n.gameOtherOpponent),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentStart,
            side: const BorderSide(color: AppColors.accentStart),
            padding: btnPadding,
          ),
        ),
      ],
    );
  }
}
