import 'package:flutter/material.dart';
import 'package:multigames_client/games/battleship/battleship_utils.dart';

/// Длинная линия силуэтов флота под статусом хода.
///
/// Потопленный корабль красный целиком, целый — серый. Попадание, которое
/// ещё не потопило корабль, на линии не показано: по ней нельзя понять,
/// какой силуэт задет.
class BattleshipFleetLine extends StatelessWidget {
  const BattleshipFleetLine({
    super.key,
    required this.sunk,
    required this.semanticsLabel,
  });

  /// Слоты [kBattleshipFleet]: `true` — корабль потоплен.
  final List<bool> sunk;

  /// Озвучка для экрана: кто и сколько кораблей ещё на плаву.
  final String semanticsLabel;

  static const Color sunkColor = Color(0xFFE53935);
  static const Color afloat = Color(0xFF607D8B);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: _ShipLine(
          key: const ValueKey('battleship-fleet-line'),
          sunk: sunk,
        ),
      ),
    );
  }
}

class _ShipLine extends StatelessWidget {
  const _ShipLine({super.key, required this.sunk});

  final List<bool> sunk;

  static const double _maxCell = 13;
  static const double _innerRatio = 0.22;
  static const double _gapRatio = 0.62;

  static double _widthFor(double cell) {
    final inner = cell * _innerRatio;
    final gap = cell * _gapRatio;
    var width = 0.0;
    for (var i = 0; i < kBattleshipFleet.length; i++) {
      if (i > 0) width += gap;
      final len = kBattleshipFleet[i];
      width += len * cell + (len - 1) * inner;
    }
    return width;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        var cell = _maxCell;
        if (maxW.isFinite && maxW > 0) {
          final full = _widthFor(cell);
          if (full > maxW) cell = cell * maxW / full;
        }
        if (cell < 4) cell = 4;
        final inner = cell * _innerRatio;
        final gap = cell * _gapRatio;
        return SizedBox(
          width: double.infinity,
          height: cell,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < kBattleshipFleet.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  _ShipGlyph(
                    key: ValueKey('battleship-ship-$i'),
                    ship: i,
                    length: kBattleshipFleet[i],
                    sunk: i < sunk.length && sunk[i],
                    cell: cell,
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
    required this.ship,
    required this.length,
    required this.sunk,
    required this.cell,
    required this.gap,
  });

  final int ship;
  final int length;
  final bool sunk;
  final double cell;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final color =
        sunk ? BattleshipFleetLine.sunkColor : BattleshipFleetLine.afloat;
    final radius = cell * 0.45;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          AnimatedContainer(
            key: ValueKey('battleship-deck-$ship-$i'),
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
