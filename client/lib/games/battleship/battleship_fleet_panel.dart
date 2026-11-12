import 'package:flutter/material.dart';
import 'package:multigames_client/games/battleship/battleship_utils.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Чей флот сейчас на экране.
///
/// [mine] — ход соперника, видно своё поле.
/// [opponent] — мой ход, видно поле соперника.
enum BattleshipFleetFocus { mine, opponent, none }

/// Две строки флота: силуэты кораблей и числа «сбито / осталось».
///
/// Подсвечена строка того, чьё поле сейчас открыто.
class BattleshipFleetPanel extends StatelessWidget {
  const BattleshipFleetPanel({
    super.key,
    required this.opponentLabel,
    required this.mySunkShips,
    required this.opponentSunkShips,
    required this.focus,
  });

  final String opponentLabel;
  final List<List<int>> mySunkShips;
  final List<List<int>> opponentSunkShips;
  final BattleshipFleetFocus focus;

  static const Color _sunk = Color(0xFFE53935);
  static const Color _afloat = Color(0xFF607D8B);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          key: const ValueKey('battleship-fleet-panel'),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.buttonBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FleetRow(
                  side: 'mine',
                  label: l10n.gameYou,
                  sunkShips: mySunkShips,
                  focused: focus == BattleshipFleetFocus.mine,
                  accent: _sunk,
                  sunkLabel: l10n.gamesBattleshipSunk,
                  remainingLabel: l10n.gamesBattleshipRemaining,
                ),
                const SizedBox(height: 4),
                _FleetRow(
                  side: 'opponent',
                  label: opponentLabel,
                  sunkShips: opponentSunkShips,
                  focused: focus == BattleshipFleetFocus.opponent,
                  accent: AppColors.accentStart,
                  sunkLabel: l10n.gamesBattleshipSunk,
                  remainingLabel: l10n.gamesBattleshipRemaining,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FleetRow extends StatelessWidget {
  const _FleetRow({
    required this.side,
    required this.label,
    required this.sunkShips,
    required this.focused,
    required this.accent,
    required this.sunkLabel,
    required this.remainingLabel,
  });

  final String side;
  final String label;
  final List<List<int>> sunkShips;
  final bool focused;
  final Color accent;
  final String sunkLabel;
  final String remainingLabel;

  @override
  Widget build(BuildContext context) {
    final slots = battleshipFleetSunkSlots(sunkShips);
    final sunk = battleshipFleetSunkCount(sunkShips);
    final left = battleshipFleetRemainingCount(sunkShips);
    final score = context.l10n.gamesBattleshipFleetScore(label, sunk, left);
    final sunkColor = sunk == 0
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : BattleshipFleetPanel._sunk;
    final leftColor =
        left == 0 ? BattleshipFleetPanel._sunk : BattleshipFleetPanel._afloat;

    return Semantics(
      container: true,
      label: score,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          key: ValueKey('battleship-fleet-plate-$side'),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: focused
                ? accent.withValues(alpha: 0.10)
                : const Color(0xFFF4F6FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: focused ? accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final glyphs = _FleetGlyphs(side: side, sunk: slots);
              final counts = [
                _Count(
                  valueKey: 'battleship-fleet-$side-sunk',
                  value: sunk,
                  caption: sunkLabel,
                  color: sunkColor,
                  width: 52,
                ),
                _Count(
                  valueKey: 'battleship-fleet-$side-left',
                  value: left,
                  caption: remainingLabel,
                  color: leftColor,
                  width: 58,
                ),
              ];
              final name = _FleetName(
                label: label,
                accent: accent,
                focused: focused,
              );
              // На узкой колонке силуэты уходят на вторую строку, чтобы
              // корабли не сжимались в точки.
              if (constraints.maxWidth < 340) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: name),
                        ...counts,
                      ],
                    ),
                    const SizedBox(height: 4),
                    glyphs,
                  ],
                );
              }
              return Row(
                children: [
                  SizedBox(width: 72, child: name),
                  const SizedBox(width: 6),
                  Expanded(child: glyphs),
                  const SizedBox(width: 4),
                  ...counts,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FleetName extends StatelessWidget {
  const _FleetName({
    required this.label,
    required this.accent,
    required this.focused,
  });

  final String label;
  final Color accent;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FocusDot(color: accent, on: focused),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _FocusDot extends StatelessWidget {
  const _FocusDot({required this.color, required this.on});

  final Color color;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? color : Colors.transparent,
        border: Border.all(
          color: on ? color : AppColors.textSecondary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    required this.valueKey,
    required this.value,
    required this.caption,
    required this.color,
    required this.width,
  });

  final String valueKey;
  final int value;
  final String caption;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey('$valueKey-$value'),
            tween: Tween(begin: 0.82, end: 1),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: Text(
              '$value',
              key: ValueKey(valueKey),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                height: 1,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FleetGlyphs extends StatelessWidget {
  const _FleetGlyphs({required this.side, required this.sunk});

  final String side;
  final List<bool> sunk;

  static const double _cell = 8;
  static const double _inner = 1.5;
  static const double _shipGap = 3;

  static double _naturalWidth() {
    var width = 0.0;
    for (var i = 0; i < kBattleshipFleet.length; i++) {
      if (i > 0) width += _shipGap;
      final len = kBattleshipFleet[i];
      width += len * _cell + (len - 1) * _inner;
    }
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final natural = _naturalWidth();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final scale =
            maxW.isFinite && maxW > 0 && natural > maxW ? maxW / natural : 1.0;
        final cell = _cell * scale;
        final inner = _inner * scale;
        final shipGap = _shipGap * scale;
        final painted = cell < 3 ? 3.0 : cell;
        return SizedBox(
          width: maxW.isFinite ? maxW : natural,
          height: painted,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < kBattleshipFleet.length; i++) ...[
                  if (i > 0) SizedBox(width: shipGap),
                  _ShipGlyph(
                    key: ValueKey('battleship-ship-$side-$i'),
                    length: kBattleshipFleet[i],
                    sunk: i < sunk.length && sunk[i],
                    cell: painted,
                    gap: inner,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShipGlyph extends StatelessWidget {
  const _ShipGlyph({
    super.key,
    required this.length,
    required this.sunk,
    required this.cell,
    required this.gap,
  });

  final int length;
  final bool sunk;
  final double cell;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final color =
        sunk ? BattleshipFleetPanel._sunk : BattleshipFleetPanel._afloat;
    final radius = cell * 0.45;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: cell,
            height: cell,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(i == 0 ? radius : 0.8),
                right: Radius.circular(i == length - 1 ? radius : 0.8),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
