import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:multigames_client/ui/app_theme.dart';

const Color _kDieFace = Color(0xFFF7F3FF);
const Color _kDiePip = Color(0xFF241E38);
const Color _kDieUsedFace = Color(0x33FFFFFF);
const Color _kDieUsedPip = Color(0x66FFFFFF);

/// Кубики хода: бросок прокручивается, потраченные гаснут.
class NardyDiceRow extends StatefulWidget {
  const NardyDiceRow({
    super.key,
    required this.rolled,
    required this.remaining,
    required this.rollKey,
    this.size = 40,
    this.highlight = false,
  });

  /// Выпавшие значения (2 или 4 при дубле).
  final List<int> rolled;

  /// Ещё не сыгранные кубики.
  final List<int> remaining;

  /// Меняется при новом броске — по нему запускается прокрутка.
  final Object rollKey;

  final double size;

  /// Подсветить рамкой — сейчас ходит владелец кубиков.
  final bool highlight;

  @override
  State<NardyDiceRow> createState() => _NardyDiceRowState();
}

class _NardyDiceRowState extends State<NardyDiceRow>
    with SingleTickerProviderStateMixin {
  static const Duration _rollDuration = Duration(milliseconds: 900);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _rollDuration,
  );
  final math.Random _rng = math.Random();
  Object? _seenRollKey;

  @override
  void initState() {
    super.initState();
    _seenRollKey = widget.rollKey;
    // Первый бросок партии приходит уже сделанным — всё равно прокручиваем,
    // иначе кубики просто возникают на экране.
    if (widget.rolled.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward(from: 0);
      });
    }
  }

  @override
  void didUpdateWidget(covariant NardyDiceRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rolled.isEmpty) {
      _seenRollKey = widget.rollKey;
      return;
    }
    if (widget.rollKey != _seenRollKey) {
      _seenRollKey = widget.rollKey;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rolled.isEmpty) return const SizedBox.shrink();
    final faces = nardyDiceFaces(widget.rolled);
    final used = nardyDiceUsed(widget.rolled, widget.remaining);
    final movesLeft = widget.remaining.length;
    final isDouble = nardyIsDoubleRoll(widget.rolled);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final rolling = _controller.isAnimating;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < faces.length; i++) ...[
              if (i > 0) SizedBox(width: widget.size * 0.18),
              _AnimatedDie(
                value: faces[i],
                used: used[i] && !rolling,
                size: widget.size,
                progress: rolling ? _dieProgress(t, i, faces.length) : 1,
                rng: _rng,
                highlight: widget.highlight,
              ),
            ],
            // Дубль играется четырьмя ходами, но кубиков на столе всё равно два.
            if (isDouble && movesLeft > 0 && !rolling) ...[
              SizedBox(width: widget.size * 0.22),
              _MovesLeftBadge(count: movesLeft, size: widget.size),
            ],
          ],
        );
      },
    );
  }

  /// Кубики останавливаются по очереди — бросок выглядит живее.
  double _dieProgress(double t, int index, int count) {
    final end = 0.55 + 0.45 * ((index + 1) / math.max(count, 1));
    if (end <= 0) return 1;
    return (t / end).clamp(0.0, 1.0);
  }
}

/// Бросок дубля: движок раскладывает его на четыре хода одним значением.
bool nardyIsDoubleRoll(List<int> rolled) =>
    rolled.length > 2 && rolled.toSet().length == 1;

/// Грани на столе — всегда два кубика, даже когда ходов четыре.
List<int> nardyDiceFaces(List<int> rolled) {
  if (rolled.isEmpty) return const [];
  if (nardyIsDoubleRoll(rolled)) return [rolled.first, rolled.first];
  return rolled.length <= 2 ? List<int>.of(rolled) : rolled.sublist(0, 2);
}

/// Какие из двух кубиков уже отыграны.
List<bool> nardyDiceUsed(List<int> rolled, List<int> remaining) {
  final faces = nardyDiceFaces(rolled);
  if (faces.isEmpty) return const [];
  if (nardyIsDoubleRoll(rolled)) {
    final left = remaining.length;
    // Гасим по одному кубику на каждую пару сыгранных ходов.
    return [left < 1, left < 3];
  }
  final left = List<int>.of(remaining);
  return [for (final face in faces) !left.remove(face)];
}

class _MovesLeftBadge extends StatelessWidget {
  const _MovesLeftBadge({required this.count, required this.size});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.2,
        vertical: size * 0.1,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentStart.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(color: AppColors.accentStart, width: 1.2),
      ),
      child: Text(
        '×$count',
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _AnimatedDie extends StatelessWidget {
  const _AnimatedDie({
    required this.value,
    required this.used,
    required this.size,
    required this.progress,
    required this.rng,
    required this.highlight,
  });

  final int value;
  final bool used;
  final double size;

  /// 0 — кубик крутится, 1 — показывает финальное значение.
  final double progress;
  final math.Random rng;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final settled = progress >= 1;
    // Пока крутится — быстро меняем грань, к концу замедляемся.
    final shown = settled
        ? value
        : 1 + ((progress * 30).floor() * 7 + value) % 6;
    final tilt = settled ? 0.0 : math.sin(progress * math.pi * 4) * (1 - progress) * 1.6;
    final lift = settled ? 0.0 : -math.sin(progress * math.pi) * size * 0.7;
    final scale = settled ? 1.0 : 0.78 + 0.22 * progress;

    return Transform.translate(
      offset: Offset(0, lift),
      child: Transform.rotate(
        angle: tilt,
        child: Transform.scale(
          scale: scale,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: used ? 0.55 : 1,
            child: _DieFace(
              value: shown,
              used: used,
              size: size,
              highlight: highlight && !used,
            ),
          ),
        ),
      ),
    );
  }
}

class _DieFace extends StatelessWidget {
  const _DieFace({
    required this.value,
    required this.used,
    required this.size,
    required this.highlight,
  });

  final int value;
  final bool used;
  final double size;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: used ? _kDieUsedFace : _kDieFace,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(
          color: highlight ? AppColors.accentStart : Colors.white24,
          width: highlight ? 2 : 1,
        ),
        boxShadow: used
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: CustomPaint(
        painter: _DiePipsPainter(
          value: value,
          color: used ? _kDieUsedPip : _kDiePip,
        ),
      ),
    );
  }
}

class _DiePipsPainter extends CustomPainter {
  const _DiePipsPainter({required this.value, required this.color});

  final int value;
  final Color color;

  static const Map<int, List<(double, double)>> _layout = {
    1: [(0.5, 0.5)],
    2: [(0.28, 0.28), (0.72, 0.72)],
    3: [(0.26, 0.26), (0.5, 0.5), (0.74, 0.74)],
    4: [(0.29, 0.29), (0.71, 0.29), (0.29, 0.71), (0.71, 0.71)],
    5: [
      (0.28, 0.28),
      (0.72, 0.28),
      (0.5, 0.5),
      (0.28, 0.72),
      (0.72, 0.72),
    ],
    6: [
      (0.3, 0.24),
      (0.7, 0.24),
      (0.3, 0.5),
      (0.7, 0.5),
      (0.3, 0.76),
      (0.7, 0.76),
    ],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final pips = _layout[value.clamp(1, 6)] ?? const [(0.5, 0.5)];
    final radius = size.shortestSide * 0.088;
    final paint = Paint()..color = color;
    for (final (fx, fy) in pips) {
      canvas.drawCircle(
        Offset(size.width * fx, size.height * fy),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiePipsPainter old) =>
      old.value != value || old.color != color;
}
