import 'package:flutter/material.dart';
import 'package:multigames_client/games/nardy/nardy_board_layout.dart';
import 'package:multigames_client/games/nardy/nardy_checker_tracker.dart';
import 'package:multigames_client/games/nardy/nardy_engine.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';

const Color _kBoardBg = Color(0xFF241C3B);
const Color _kBoardFrame = Color(0xFF3B2F63);
const Color _kPointLight = Color(0xFF7C68C4);
const Color _kPointDark = Color(0xFF43376F);
const Color _kHomeTint = Color(0xFF9B6BE8);

/// Свои шашки — светлые, чужие — тёплые янтарные: на тёмной доске
/// прежний почти чёрный цвет соперника сливался с пунктами.
const Color _kMyChecker = Color(0xFFF6F1FF);
const Color _kMyCheckerEdge = Color(0xFF9C8FD6);
const Color _kOppChecker = Color(0xFFFF9E45);
const Color _kOppCheckerEdge = Color(0xFFC2560E);

const Color _kSelected = Color(0xFF56E39F);
const Color _kTarget = Color(0xFF56E39F);
const Color _kLastMove = Color(0xFF6EC6FF);

/// Доска нард глазами игрока с плавным переездом шашек.
class NardyBoard extends StatefulWidget {
  const NardyBoard({
    super.key,
    required this.game,
    required this.tracker,
    required this.selectedTrack,
    required this.targetTracks,
    required this.canBearOff,
    required this.undoTracks,
    required this.onTrackTap,
    required this.onBarTap,
    required this.onBearOffTap,
    required this.canDragFrom,
    required this.onDragStart,
    required this.onDragEnd,
    this.dragCancel,
  });

  final NardyGameView game;
  final NardyCheckerTracker tracker;

  /// Выбранный пункт дорожки или [nardyBarTrack]; `null` — ничего не выбрано.
  final int? selectedTrack;

  /// Пункты, куда можно пойти выбранной шашкой.
  final Set<int> targetTracks;

  /// Выбранной шашкой можно выброситься с доски.
  final bool canBearOff;

  /// Пункты, откуда шашку можно вернуть отменой хода.
  final Set<int> undoTracks;

  final void Function(int track) onTrackTap;
  final VoidCallback onBarTap;
  final VoidCallback onBearOffTap;

  /// С этого пункта шашку можно потащить.
  final bool Function(int track) canDragFrom;

  /// Начался перенос шашки с пункта [track] — показать подсветку целей.
  final void Function(int track) onDragStart;

  /// Шашку отпустили: [track] — пункт под пальцем, [nardyPoints] — зона снятия,
  /// `null` — мимо доски.
  final void Function(int? track) onDragEnd;

  /// Перенос отменён (жест прерван).
  final VoidCallback? dragCancel;

  static const Duration moveDuration = Duration(milliseconds: 420);

  @override
  State<NardyBoard> createState() => _NardyBoardState();
}

class _NardyBoardState extends State<NardyBoard> {
  /// Пункт, с которого сейчас тащат шашку.
  int? _dragTrack;
  Offset? _dragPosition;

  NardyGameView get game => widget.game;

  bool get _showBar => !game.isLong;

  /// Пункты дорожки, затронутые прошлым ходом соперника.
  Set<int> get _lastMoveTracks {
    if (game.myIndex < 0 || game.lastTurnSeat < 0) return const {};
    if (game.lastTurnSeat == game.myIndex) return const {};
    final out = <int>{};
    for (final mv in game.lastTurn) {
      for (final point in [mv.fromPoint, mv.toPoint]) {
        if (point < 0) continue;
        final track = nardyBoardToTrack(game.gameMode, game.myIndex, point);
        if (track >= 0) out.add(track);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final geometry = NardyBoardGeometry(size: size, showBar: _showBar);
        final lastMove = _lastMoveTracks;
        final mySeat = game.myIndex < 0 ? 0 : game.myIndex;
        final oppSeat = game.myIndex < 0 ? 1 : game.opponentIndex;
        final diameter = geometry.checkerSize;

        // Работаем с сырыми событиями указателя, а не с GestureDetector:
        // пара «тап + пан» на одном детекторе на вебе отдавала мышь тапу,
        // и перетаскивание не начиналось.
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => _onPointerDown(geometry, event),
          onPointerMove: (event) => _onPointerMove(geometry, event),
          onPointerUp: (event) => _onPointerUp(geometry, event),
          onPointerCancel: (_) => _cancelDrag(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _kBoardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBoardFrame, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BoardPainter(
                      geometry: geometry,
                      selectedTrack: widget.selectedTrack,
                      targetTracks: widget.targetTracks,
                      lastMoveTracks: lastMove,
                      undoTracks: widget.undoTracks,
                      canBearOff: widget.canBearOff,
                      showBar: _showBar,
                    ),
                  ),
                ),
                ..._buildCheckers(geometry, oppSeat, mine: false),
                ..._buildCheckers(geometry, mySeat, mine: true),
                ..._buildTrayLabels(geometry, mySeat, oppSeat),
                if (_dragPosition != null)
                  Positioned(
                    left: _dragPosition!.dx - diameter / 2,
                    top: _dragPosition!.dy - diameter / 2,
                    width: diameter,
                    height: diameter,
                    child: IgnorePointer(
                      child: Transform.scale(
                        scale: 1.15,
                        child: _Checker(mine: true, diameter: diameter),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Сдвиг, после которого касание считается перетаскиванием, а не тапом.
  static const double _dragSlop = 8;

  Offset? _pointerDownAt;
  int? _pointerDownTrack;

  void _onPointerDown(NardyBoardGeometry geometry, PointerDownEvent event) {
    _pointerDownAt = event.localPosition;
    _pointerDownTrack = _trackUnder(geometry, event.localPosition);
  }

  void _onPointerMove(NardyBoardGeometry geometry, PointerMoveEvent event) {
    if (_dragTrack != null) {
      setState(() => _dragPosition = event.localPosition);
      return;
    }
    final start = _pointerDownAt;
    final track = _pointerDownTrack;
    if (start == null || track == null) return;
    if ((event.localPosition - start).distance < _dragSlop) return;
    if (!widget.canDragFrom(track)) {
      _pointerDownTrack = null;
      return;
    }
    setState(() {
      _dragTrack = track;
      _dragPosition = event.localPosition;
    });
    widget.onDragStart(track);
  }

  void _onPointerUp(NardyBoardGeometry geometry, PointerUpEvent event) {
    final dragging = _dragTrack != null;
    final position = _dragPosition ?? event.localPosition;
    _pointerDownAt = null;
    _pointerDownTrack = null;
    if (!dragging) {
      _handleTap(geometry, event.localPosition);
      return;
    }
    setState(() {
      _dragTrack = null;
      _dragPosition = null;
    });
    if (geometry.trayRect.contains(position)) {
      widget.onDragEnd(nardyPoints);
      return;
    }
    widget.onDragEnd(_trackUnder(geometry, position));
  }

  /// Пункт под точкой, включая бар в коротких нардах.
  int? _trackUnder(NardyBoardGeometry geometry, Offset position) {
    if (_showBar && geometry.barRect.contains(position)) return nardyBarTrack;
    return geometry.trackAt(position);
  }

  void _cancelDrag() {
    _pointerDownAt = null;
    _pointerDownTrack = null;
    if (_dragTrack == null && _dragPosition == null) return;
    setState(() {
      _dragTrack = null;
      _dragPosition = null;
    });
    widget.dragCancel?.call();
  }

  List<Widget> _buildCheckers(
    NardyBoardGeometry geometry,
    int seat, {
    required bool mine,
  }) {
    final spots = widget.tracker.spotsFor(game, seat);
    final diameter = geometry.checkerSize;
    return [
      for (final spot in spots)
        if (!_hiddenWhileDragging(spot, mine: mine))
          AnimatedPositioned(
            key: ValueKey('nardy-checker-$seat-${spot.id}'),
            duration: NardyBoard.moveDuration,
            curve: Curves.easeOutCubic,
            left: _centerOf(geometry, spot, mine: mine).dx - diameter / 2,
            top: _centerOf(geometry, spot, mine: mine).dy - diameter / 2,
            width: diameter,
            height: diameter,
            child: IgnorePointer(
              child: _Checker(
                mine: mine,
                diameter: diameter,
                label: _stackLabel(spot),
                dimmed: spot.isOff,
              ),
            ),
          ),
    ];
  }

  /// Верхняя шашка стопки едет за пальцем — из стопки её убираем.
  bool _hiddenWhileDragging(NardyCheckerSpot spot, {required bool mine}) {
    if (!mine || _dragTrack == null) return false;
    if (spot.track != _dragTrack) return false;
    return spot.index == spot.stackSize - 1;
  }

  Offset _centerOf(
    NardyBoardGeometry geometry,
    NardyCheckerSpot spot, {
    required bool mine,
  }) {
    if (spot.onBar) {
      return geometry.barCheckerCenter(mine: mine, index: spot.index);
    }
    if (spot.isOff) {
      return geometry.offCenter(mine: mine, index: spot.index);
    }
    // Дорожка соперника считается в его координатах — переводим в свои,
    // иначе чужие шашки встанут зеркально не на те пункты.
    final track = mine ? spot.track : _toMyTrack(spot.track, mine: mine);
    return geometry.checkerCenter(track, spot.index, spot.stackSize);
  }

  int _toMyTrack(int oppTrack, {required bool mine}) {
    if (mine || game.myIndex < 0) return oppTrack;
    final point = nardyTrackToBoard(game.gameMode, game.opponentIndex, oppTrack);
    final track = nardyBoardToTrack(game.gameMode, game.myIndex, point);
    return track < 0 ? oppTrack : track;
  }

  String? _stackLabel(NardyCheckerSpot spot) {
    if (spot.isOff || spot.onBar) return null;
    final visible = NardyBoardGeometry.visibleInStack(spot.stackSize);
    if (spot.stackSize <= visible) return null;
    return spot.index == visible - 1 ? '${spot.stackSize}' : null;
  }

  List<Widget> _buildTrayLabels(
    NardyBoardGeometry geometry,
    int mySeat,
    int oppSeat,
  ) {
    Widget label(Rect rect, int count, bool mine) {
      return Positioned(
        left: rect.left,
        top: mine ? rect.top : rect.bottom - 18,
        width: rect.width,
        height: 18,
        child: Center(
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: mine ? _kMyChecker : _kOppChecker,
            ),
          ),
        ),
      );
    }

    final myOff = mySeat < game.off.length ? game.off[mySeat] : 0;
    final oppOff = oppSeat < game.off.length ? game.off[oppSeat] : 0;
    return [
      label(geometry.trayHalf(mine: true), myOff, true),
      label(geometry.trayHalf(mine: false), oppOff, false),
    ];
  }

  void _handleTap(NardyBoardGeometry geometry, Offset position) {
    if (geometry.trayRect.contains(position)) {
      widget.onBearOffTap();
      return;
    }
    if (_showBar && geometry.barRect.contains(position)) {
      widget.onBarTap();
      return;
    }
    final track = geometry.trackAt(position);
    if (track != null) widget.onTrackTap(track);
  }
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter({
    required this.geometry,
    required this.selectedTrack,
    required this.targetTracks,
    required this.lastMoveTracks,
    required this.undoTracks,
    required this.canBearOff,
    required this.showBar,
  });

  final NardyBoardGeometry geometry;
  final int? selectedTrack;
  final Set<int> targetTracks;
  final Set<int> lastMoveTracks;
  final Set<int> undoTracks;
  final bool canBearOff;
  final bool showBar;

  @override
  void paint(Canvas canvas, Size size) {
    for (final track in NardyBoardLayout.allTracks) {
      _paintPoint(canvas, track);
    }
    _paintBar(canvas);
    _paintTray(canvas);
  }

  void _paintPoint(Canvas canvas, int track) {
    final rect = geometry.trackRect(track);
    if (rect.isEmpty) return;
    final top = NardyBoardLayout.isTopRow(track);
    final column = NardyBoardLayout.columnOf(track);
    final base = column.isEven ? _kPointLight : _kPointDark;
    var fill = NardyBoardLayout.isHome(track)
        ? Color.alphaBlend(_kHomeTint.withValues(alpha: 0.22), base)
        : base;
    if (targetTracks.contains(track)) {
      fill = Color.alphaBlend(_kTarget.withValues(alpha: 0.5), fill);
    } else if (undoTracks.contains(track)) {
      fill = Color.alphaBlend(_kLastMove.withValues(alpha: 0.3), fill);
    }

    final inset = rect.width * 0.06;
    final path = Path();
    if (top) {
      path
        ..moveTo(rect.left + inset, rect.top)
        ..lineTo(rect.right - inset, rect.top)
        ..lineTo(rect.center.dx, rect.bottom - rect.height * 0.06)
        ..close();
    } else {
      path
        ..moveTo(rect.left + inset, rect.bottom)
        ..lineTo(rect.right - inset, rect.bottom)
        ..lineTo(rect.center.dx, rect.top + rect.height * 0.06)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = fill);

    if (lastMoveTracks.contains(track)) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _kLastMove,
      );
    }
    if (selectedTrack == track) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = _kSelected,
      );
    }
    if (targetTracks.contains(track)) {
      final marker = Offset(
        rect.center.dx,
        top ? rect.top + rect.height * 0.72 : rect.bottom - rect.height * 0.72,
      );
      canvas.drawCircle(marker, rect.width * 0.14, Paint()..color = _kTarget);
    }
  }

  void _paintBar(Canvas canvas) {
    final rect = geometry.barRect;
    final paint = Paint()..color = _kBoardFrame;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      paint,
    );
    if (!showBar) return;
    final selected = selectedTrack == nardyBarTrack;
    if (selected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _kSelected,
      );
    }
  }

  void _paintTray(Canvas canvas) {
    for (final mine in [true, false]) {
      final rect = geometry.trayHalf(mine: mine).deflate(2);
      final highlight = mine && canBearOff;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()
          ..color = highlight
              ? _kTarget.withValues(alpha: 0.28)
              : Colors.black.withValues(alpha: 0.25),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = highlight ? 2 : 1
          ..color = highlight ? _kTarget : _kBoardFrame,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) =>
      old.selectedTrack != selectedTrack ||
      old.canBearOff != canBearOff ||
      old.showBar != showBar ||
      !setEquals(old.targetTracks, targetTracks) ||
      !setEquals(old.lastMoveTracks, lastMoveTracks) ||
      !setEquals(old.undoTracks, undoTracks) ||
      old.geometry.size != geometry.size;

  static bool setEquals(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);
}

class _Checker extends StatelessWidget {
  const _Checker({
    required this.mine,
    required this.diameter,
    this.label,
    this.dimmed = false,
  });

  final bool mine;
  final double diameter;
  final String? label;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final face = mine ? _kMyChecker : _kOppChecker;
    final edge = mine ? _kMyCheckerEdge : _kOppCheckerEdge;
    return Opacity(
      opacity: dimmed ? 0.85 : 1,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.4),
            radius: 0.95,
            colors: [
              Color.alphaBlend(Colors.white.withValues(alpha: 0.35), face),
              face,
              edge,
            ],
            stops: const [0, 0.62, 1],
          ),
          border: Border.all(color: edge, width: diameter * 0.06),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: diameter * 0.14,
              offset: Offset(0, diameter * 0.06),
            ),
          ],
        ),
        child: label == null
            ? null
            : Text(
                label!,
                style: TextStyle(
                  fontSize: diameter * 0.44,
                  fontWeight: FontWeight.w900,
                  color: mine ? _kOppCheckerEdge : Colors.white,
                ),
              ),
      ),
    );
  }
}

/// Полоска «сколько шашек в доме и снято» под доской.
class NardyProgressBar extends StatelessWidget {
  const NardyProgressBar({
    super.key,
    required this.label,
    required this.pips,
    required this.off,
    required this.mine,
    required this.active,
  });

  final String label;
  final int pips;
  final int off;
  final bool mine;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = mine ? _kMyChecker : _kOppChecker;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? AppColors.accentStart : Colors.white12,
          width: active ? 1.6 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: mine ? _kMyCheckerEdge : _kOppCheckerEdge,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label $pips',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          if (off > 0) ...[
            const SizedBox(width: 6),
            Icon(Icons.outbound_rounded, size: 12, color: color),
            const SizedBox(width: 2),
            Text(
              '$off',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
