import 'package:flutter/material.dart';
import 'package:multigames_client/games/nardy/nardy_board_layout.dart';
import 'package:multigames_client/games/nardy/nardy_engine.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';

const Color _kBoardBg = Color(0xFF2B2141);
const Color _kPointLight = Color(0xFF6D5BA6);
const Color _kPointDark = Color(0xFF3E3268);
const Color _kHomeTint = Color(0xFF7A4DBF);
const Color _kMyChecker = Color(0xFFF3EDFF);
const Color _kOppChecker = Color(0xFF262034);
const Color _kSelected = Color(0xFF4CAF50);
const Color _kTarget = Color(0xFF80D8A0);

/// Доска нард глазами игрока: дом снизу справа, ход против часовой стрелки.
class NardyBoard extends StatelessWidget {
  const NardyBoard({
    super.key,
    required this.game,
    required this.selectedTrack,
    required this.targetTracks,
    required this.canBearOff,
    required this.onTrackTap,
    required this.onBarTap,
    required this.onBearOffTap,
  });

  final NardyGameView game;

  /// Выбранный пункт дорожки или [nardyBarTrack]; `null` — ничего не выбрано.
  final int? selectedTrack;

  /// Пункты, куда можно пойти выбранной шашкой.
  final Set<int> targetTracks;

  /// Выбранной шашкой можно выброситься с доски.
  final bool canBearOff;

  final void Function(int track) onTrackTap;
  final VoidCallback onBarTap;
  final VoidCallback onBearOffTap;

  bool get _showBar => !game.isLong;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final trayWidth = (width * 0.09).clamp(22.0, 44.0);
        final boardWidth = width - trayWidth - 6;
        final columnWidth = boardWidth / 12;
        final pointHeight = (columnWidth * 3.1).clamp(56.0, 190.0);
        final barHeight = _showBar ? 30.0 : 0.0;
        final height = pointHeight * 2 + barHeight + 12;

        return SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _kBoardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accentStart.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      children: [
                        SizedBox(
                          height: pointHeight,
                          child: _buildRow(
                            NardyBoardLayout.topRow,
                            pointsDown: true,
                          ),
                        ),
                        if (_showBar)
                          SizedBox(height: barHeight, child: _buildBar(context)),
                        SizedBox(
                          height: pointHeight,
                          child: _buildRow(
                            NardyBoardLayout.bottomRow,
                            pointsDown: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(width: trayWidth, child: _buildOffTray(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(List<int> tracks, {required bool pointsDown}) {
    return Row(
      children: [
        for (var i = 0; i < tracks.length; i++) ...[
          if (i == NardyBoardLayout.quadrant)
            Container(
              width: 3,
              margin: const EdgeInsets.symmetric(vertical: 2),
              color: AppColors.accentStart.withValues(alpha: 0.25),
            ),
          Expanded(
            child: _NardyPoint(
              track: tracks[i],
              pointsDown: pointsDown,
              light: i.isEven,
              game: game,
              selected: selectedTrack == tracks[i],
              target: targetTracks.contains(tracks[i]),
              onTap: () => onTrackTap(tracks[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBar(BuildContext context) {
    final myBar = game.myIndex >= 0 ? game.bar[game.myIndex] : 0;
    final oppBar =
        game.myIndex >= 0 ? game.bar[game.opponentIndex] : 0;
    final selected = selectedTrack == nardyBarTrack;
    return GestureDetector(
      onTap: myBar > 0 ? onBarTap : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: selected
              ? _kSelected.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? _kSelected
                : AppColors.accentStart.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _barBadge(oppBar, mine: false),
            const SizedBox(width: 14),
            const Icon(Icons.horizontal_rule_rounded,
                size: 14, color: Colors.white54),
            const SizedBox(width: 14),
            _barBadge(myBar, mine: true),
          ],
        ),
      ),
    );
  }

  Widget _barBadge(int count, {required bool mine}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: mine ? _kMyChecker : _kOppChecker,
            border: Border.all(color: Colors.white24),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: count > 0 ? Colors.white : Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _buildOffTray(BuildContext context) {
    final myOff = game.myIndex >= 0 ? game.off[game.myIndex] : 0;
    final oppOff = game.myIndex >= 0 ? game.off[game.opponentIndex] : 0;
    return GestureDetector(
      onTap: canBearOff ? onBearOffTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: canBearOff
              ? _kTarget.withValues(alpha: 0.28)
              : Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canBearOff
                ? _kTarget
                : AppColors.accentStart.withValues(alpha: 0.25),
            width: canBearOff ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _offBadge(oppOff, mine: false),
            _offBadge(myOff, mine: true),
          ],
        ),
      ),
    );
  }

  Widget _offBadge(int count, {required bool mine}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 8,
            decoration: BoxDecoration(
              color: mine ? _kMyChecker : _kOppChecker,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.white24),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _NardyPoint extends StatelessWidget {
  const _NardyPoint({
    required this.track,
    required this.pointsDown,
    required this.light,
    required this.game,
    required this.selected,
    required this.target,
    required this.onTap,
  });

  final int track;
  final bool pointsDown;
  final bool light;
  final NardyGameView game;
  final bool selected;
  final bool target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mine = game.myCountAt(track);
    final theirs = game.opponentCountAt(track);
    final count = mine > 0 ? mine : theirs;
    final isMine = mine > 0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _TrianglePainter(
                pointsDown: pointsDown,
                color: light ? _kPointLight : _kPointDark,
                home: NardyBoardLayout.isHome(track),
                selected: selected,
                target: target,
              ),
            ),
          ),
          if (count > 0)
            Positioned.fill(
              child: _CheckerStack(
                count: count,
                mine: isMine,
                fromTop: pointsDown,
              ),
            ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({
    required this.pointsDown,
    required this.color,
    required this.home,
    required this.selected,
    required this.target,
  });

  final bool pointsDown;
  final Color color;
  final bool home;
  final bool selected;
  final bool target;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointsDown) {
      path
        ..moveTo(1, 0)
        ..lineTo(size.width - 1, 0)
        ..lineTo(size.width / 2, size.height * 0.92)
        ..close();
    } else {
      path
        ..moveTo(1, size.height)
        ..lineTo(size.width - 1, size.height)
        ..lineTo(size.width / 2, size.height * 0.08)
        ..close();
    }
    var fill = color;
    if (home) fill = Color.alphaBlend(_kHomeTint.withValues(alpha: 0.2), color);
    if (target) fill = Color.alphaBlend(_kTarget.withValues(alpha: 0.55), fill);
    canvas.drawPath(path, Paint()..color = fill);
    if (selected || target) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = selected ? _kSelected : _kTarget,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) =>
      old.color != color ||
      old.pointsDown != pointsDown ||
      old.home != home ||
      old.selected != selected ||
      old.target != target;
}

class _CheckerStack extends StatelessWidget {
  const _CheckerStack({
    required this.count,
    required this.mine,
    required this.fromTop,
  });

  final int count;
  final bool mine;
  final bool fromTop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter =
            (constraints.maxWidth * 0.82).clamp(10.0, constraints.maxHeight / 3);
        // Больше пяти шашек не рисуем — вместо них счётчик на верхней.
        final shown = count > 5 ? 5 : count;
        final step = shown <= 1
            ? 0.0
            : ((constraints.maxHeight - diameter) / (shown - 1))
                .clamp(0.0, diameter * 0.92);
        final children = <Widget>[];
        for (var i = 0; i < shown; i++) {
          final offset = i * step;
          children.add(
            Positioned(
              top: fromTop ? offset : null,
              bottom: fromTop ? null : offset,
              left: (constraints.maxWidth - diameter) / 2,
              child: _Checker(
                diameter: diameter,
                mine: mine,
                label: i == shown - 1 && count > shown ? '$count' : null,
              ),
            ),
          );
        }
        return Stack(children: children);
      },
    );
  }
}

class _Checker extends StatelessWidget {
  const _Checker({
    required this.diameter,
    required this.mine,
    this.label,
  });

  final double diameter;
  final bool mine;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: mine ? _kMyChecker : _kOppChecker,
        border: Border.all(
          color: mine ? Colors.white : Colors.white38,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: label == null
          ? null
          : Text(
              label!,
              style: TextStyle(
                fontSize: diameter * 0.46,
                fontWeight: FontWeight.w900,
                color: mine ? _kOppChecker : _kMyChecker,
              ),
            ),
    );
  }
}

/// Кубики текущего хода: неиспользованные — яркие, потраченные — тусклые.
class NardyDiceRow extends StatelessWidget {
  const NardyDiceRow({
    super.key,
    required this.rolled,
    required this.remaining,
    this.size = 34,
  });

  final List<int> rolled;
  final List<int> remaining;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (rolled.isEmpty) return const SizedBox.shrink();
    final left = List<int>.of(remaining);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final die in rolled) ...[
          _Die(value: die, used: !left.remove(die), size: size),
          const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _Die extends StatelessWidget {
  const _Die({required this.value, required this.used, required this.size});

  final int value;
  final bool used;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: used ? Colors.white24 : Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(
          color: used ? Colors.white24 : AppColors.accentStart,
          width: 1.5,
        ),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          fontSize: size * 0.5,
          fontWeight: FontWeight.w900,
          color: used ? Colors.white54 : _kOppChecker,
        ),
      ),
    );
  }
}
