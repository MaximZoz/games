import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:multigames_client/games/domino/domino_engine.dart';
import 'package:multigames_client/games/domino/domino_repository.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/responsive.dart';

const double kDominoLong = 54;
const double kDominoShort = 28;
const double kDominoGap = 3;
const Duration kDominoFlight = Duration(milliseconds: 240);

const List<Offset> _pipGrid = [
  Offset(0.28, 0.28),
  Offset(0.72, 0.28),
  Offset(0.28, 0.50),
  Offset(0.72, 0.50),
  Offset(0.28, 0.72),
  Offset(0.72, 0.72),
  Offset(0.50, 0.50),
];

const List<List<int>> _pipIndex = [
  [],
  [6],
  [0, 5],
  [0, 6, 5],
  [0, 1, 4, 5],
  [0, 1, 6, 4, 5],
  [0, 2, 4, 1, 3, 5],
];

class DominoLayoutSlot {
  const DominoLayoutSlot({
    required this.id,
    required this.rect,
    required this.leadingOnRight,
  });

  final int id;
  final Rect rect;

  /// true, пока ряд идёт вправо: открытый конец кости — справа.
  /// На обратном ряду открытый конец слева, и половины надо поменять местами.
  final bool leadingOnRight;
}

/// Какую половину рисовать слева и справа.
/// [leadingOnRight] — открытый конец (к следующей кости цепи) справа.
({int left, int right}) dominoHalfPips(
  DominoPlaced tile, {
  required bool leadingOnRight,
}) {
  if (tile.isDouble) return (left: tile.lo, right: tile.hi);
  final towardLower = tile.end == 'left' ? tile.outward : tile.inward;
  final towardHigher = tile.end == 'left' ? tile.inward : tile.outward;
  if (leadingOnRight) return (left: towardLower, right: towardHigher);
  return (left: towardHigher, right: towardLower);
}

/// Раскладка цепи: слева направо, с переносом, когда ряд не влезает.
/// Координаты относительно левого верхнего угла цепи, не холста.
List<DominoLayoutSlot> layoutDominoChain(
  List<DominoPlaced> chain,
  double maxWidth,
) {
  if (chain.isEmpty) return const [];
  final width = math.max(maxWidth, kDominoLong + 8);
  final slots = <DominoLayoutSlot>[];
  var x = 0.0;
  var y = 0.0;
  var rowHeight = 0.0;
  var dir = 1;
  for (final tile in chain) {
    final tileWidth = tile.isDouble ? kDominoShort : kDominoLong;
    final tileHeight = tile.isDouble ? kDominoLong : kDominoShort;
    if (slots.isNotEmpty && dir == 1 && x + tileWidth > width) {
      dir = -1;
      y += rowHeight + 10;
      rowHeight = 0;
      x = slots.last.rect.right - tileWidth;
    } else if (slots.isNotEmpty && dir == -1 && x < 0) {
      dir = 1;
      y += rowHeight + 10;
      rowHeight = 0;
      x = 0;
    }
    final rect = Rect.fromLTWH(
      dir == 1 ? x : x,
      y + (kDominoLong - tileHeight) / 2,
      tileWidth,
      tileHeight,
    );
    slots.add(DominoLayoutSlot(
      id: tile.id,
      rect: rect,
      leadingOnRight: dir == 1,
    ));
    rowHeight = math.max(rowHeight, kDominoLong);
    if (dir == 1) {
      x += tileWidth + kDominoGap;
    } else {
      x -= tileWidth + kDominoGap;
    }
  }
  return slots;
}

class DominoTable extends StatefulWidget {
  const DominoTable({
    super.key,
    required this.view,
    required this.onPlay,
    this.busy = false,
  });

  final DominoGameView view;
  final ValueChanged<DominoMove> onPlay;
  final bool busy;

  @override
  State<DominoTable> createState() => _DominoTableState();
}

class _DominoTableState extends State<DominoTable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flight;
  Map<int, Rect> _from = const {};
  Map<int, Rect> _to = const {};
  int? _spawnId;
  String _chainSig = '';
  int? _choosing;
  Set<int> _handBefore = const {};
  Set<int> _newHand = const {};

  @override
  void initState() {
    super.initState();
    _flight = AnimationController(vsync: this, duration: kDominoFlight)
      ..value = 1;
    _chainSig = _sig(widget.view);
    _handBefore = widget.view.me?.hand.toSet() ?? const {};
  }

  @override
  void didUpdateWidget(covariant DominoTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSig = _sig(widget.view);
    final hand = widget.view.me?.hand.toSet() ?? const {};
    _newHand = hand.difference(_handBefore);
    if (nextSig != _chainSig) {
      _from = Map<int, Rect>.of(_to);
      _spawnId = _freshId(oldWidget.view.chain, widget.view.chain);
      _chainSig = nextSig;
      _flight.forward(from: 0);
    } else if (_newHand.isNotEmpty) {
      _from = Map<int, Rect>.of(_to);
      _spawnId = null;
      _flight.forward(from: 0);
    }
    _handBefore = hand;
    if (_choosing != null &&
        !widget.view.legal.any((move) => move.tile == _choosing)) {
      _choosing = null;
    }
  }

  @override
  void dispose() {
    _flight.dispose();
    super.dispose();
  }

  String _sig(DominoGameView view) =>
      view.chain.map((tile) => tile.id).join(',');

  int? _freshId(List<DominoPlaced> before, List<DominoPlaced> after) {
    final known = before.map((tile) => tile.id).toSet();
    for (final tile in after) {
      if (!known.contains(tile.id)) return tile.id;
    }
    return null;
  }

  void _tapHand(int id) {
    if (widget.busy || !widget.view.isMyTurn) return;
    final moves = [
      for (final move in widget.view.legal)
        if (move.tile == id) move,
    ];
    if (moves.isEmpty) return;
    if (moves.length == 1) {
      setState(() => _choosing = null);
      widget.onPlay(moves.first);
      return;
    }
    setState(() => _choosing = id);
  }

  void _tapEnd(String end) {
    final id = _choosing;
    if (id == null || widget.busy) return;
    for (final move in widget.view.legal) {
      if (move.tile == id && move.end == end) {
        setState(() => _choosing = null);
        widget.onPlay(move);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final narrow = isNarrow(context);
    final n = view.players.length;
    final me = view.myIndex;
    final seats = <int, DominoPlayerView>{};
    for (final player in view.players) {
      if (player.seat == me) continue;
      seats[(player.seat - me + n) % n] = player;
    }
    final felt = Expanded(child: _felt(view));
    final hand = _hand(view, narrow);
    if (!narrow && n >= 3) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (seats[n - 1] != null) _sideSeat(seats[n - 1]!, view),
          Expanded(
            child: Column(
              children: [
                if (seats[n == 4 ? 2 : 1] != null && n == 4)
                  _topSeat(seats[2]!, view),
                if (n == 3) const SizedBox(height: 4),
                felt,
                hand,
              ],
            ),
          ),
          if (seats[1] != null && n >= 3) _sideSeat(seats[1]!, view),
        ],
      );
    }
    return Column(
      children: [
        if (seats.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              children: [
                for (final player in seats.values)
                  Expanded(child: _topSeat(player, view)),
              ],
            ),
          ),
        felt,
        hand,
      ],
    );
  }

  Widget _felt(DominoGameView view) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slots = layoutDominoChain(
          view.chain,
          math.max(120, constraints.maxWidth - 28),
        );
        final bounds = _bounds(slots);
        final dx = (constraints.maxWidth - bounds.width) / 2 - bounds.left;
        final dy = (constraints.maxHeight - bounds.height) / 2 - bounds.top;
        final placed = {
          for (final slot in slots) slot.id: slot.rect.shift(Offset(dx, dy)),
        };
        final leading = {
          for (final slot in slots) slot.id: slot.leadingOnRight,
        };
        if (_to.isEmpty) _to = placed;
        final spawn = _spawnRect(constraints.biggest, view);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E3B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF13462C)),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 10,
                top: 8,
                child: _boneyard(view),
              ),
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _flight,
                    builder: (context, _) {
                      final t = Curves.easeOutCubic.transform(_flight.value);
                      final now = <int, Rect>{};
                      for (final entry in placed.entries) {
                        var origin = _from[entry.key] ?? entry.value;
                        if (entry.key == _spawnId &&
                            !_from.containsKey(entry.key)) {
                          origin = spawn;
                        }
                        now[entry.key] =
                            Rect.lerp(origin, entry.value, t) ?? entry.value;
                      }
                      _to = placed;
                      return CustomPaint(
                        painter: _ChainPainter(
                          chain: view.chain,
                          rects: now,
                          leadingOnRight: leading,
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_choosing != null)
                Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(
                        child: _endTap(
                          context.l10n.dominoLeft,
                          () => _tapEnd('left'),
                        ),
                      ),
                      Expanded(
                        child: _endTap(
                          context.l10n.dominoRight,
                          () => _tapEnd('right'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Rect _spawnRect(Size size, DominoGameView view) {
    final mine = view.lastActor == view.myIndex;
    final y = mine ? size.height + 8 : -kDominoLong;
    return Rect.fromCenter(
      center: Offset(size.width / 2, y),
      width: kDominoLong,
      height: kDominoShort,
    );
  }

  Rect _bounds(List<DominoLayoutSlot> slots) {
    if (slots.isEmpty) return Rect.zero;
    var rect = slots.first.rect;
    for (final slot in slots.skip(1)) {
      rect = rect.expandToInclude(slot.rect);
    }
    return rect;
  }

  Widget _boneyard(DominoGameView view) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _backTile(width: 22, height: 34),
        const SizedBox(width: 6),
        Text(
          '${context.l10n.dominoBoneyard} ${view.boneyardCount}',
          style: const TextStyle(
            color: Color(0xFFF4E7C5),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _endTap(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.busy ? null : onTap,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFF4E7C5),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hand(DominoGameView view, bool narrow) {
    final hand = view.me?.hand ?? const <int>[];
    final scale = narrow ? 0.86 : 1.0;
    final width = kDominoShort * scale;
    final height = kDominoLong * scale;
    return SizedBox(
      height: height + 18,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: hand.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final id = hand[index];
          final legal = view.legal.any((move) => move.tile == id);
          final selected = _choosing == id;
          return GestureDetector(
            key: ValueKey('domino-hand-$id'),
            onTap: legal ? () => _tapHand(id) : null,
            child: AnimatedBuilder(
              animation: _flight,
              builder: (context, child) {
                final grow = _newHand.contains(id)
                    ? lerpDouble(0.72, 1, _flight.value)!
                    : 1.0;
                return Opacity(
                  opacity: legal || !view.isMyTurn ? 1 : 0.38,
                  child: Transform.scale(scale: grow, child: child),
                );
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                        selected ? const Color(0xFFFFD54F) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: CustomPaint(
                  size: Size(width, height),
                  painter: DominoFacePainter(
                    lo: dominoPips(id).$1,
                    hi: dominoPips(id).$2,
                    vertical: true,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _topSeat(DominoPlayerView player, DominoGameView view) {
    return _seat(player, view);
  }

  Widget _sideSeat(DominoPlayerView player, DominoGameView view) {
    return SizedBox(
      width: 92,
      child: Align(alignment: Alignment.center, child: _seat(player, view)),
    );
  }

  Widget _seat(DominoPlayerView player, DominoGameView view) {
    final reveal = view.isRoundEnd || view.isOver;
    final name = (player.displayName ?? '').trim().isEmpty
        ? (player.isBot ? context.l10n.gameBot : context.l10n.commonPlayer)
        : player.displayName!.trim();
    final active = view.turn == player.seat && view.isPlaying;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFFFFD54F) : null,
              fontSize: 12,
            ),
          ),
          Text(
            '${player.score}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          if (reveal && player.hand.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                for (final id in player.hand)
                  CustomPaint(
                    size: Size(kDominoShort * 0.55, kDominoLong * 0.55),
                    painter: DominoFacePainter(
                      lo: dominoPips(id).$1,
                      hi: dominoPips(id).$2,
                      vertical: true,
                    ),
                  ),
              ],
            )
          else
            _backStack(player.handCount),
        ],
      ),
    );
  }

  Widget _backStack(int count) {
    return SizedBox(
      width: 36,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (count > 1)
            Transform.translate(
              offset: const Offset(4, -3),
              child: _backTile(width: 18, height: 26),
            ),
          _backTile(width: 18, height: 26),
          Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFFF4E7C5),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _backTile({required double width, required double height}) {
    return CustomPaint(
      size: Size(width, height),
      painter: const _BackPainter(),
    );
  }
}

class DominoFacePainter extends CustomPainter {
  const DominoFacePainter({
    required this.lo,
    required this.hi,
    required this.vertical,
  });

  final int lo;
  final int hi;
  final bool vertical;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(5));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFF7F1E3));
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFD8C7A1),
    );
    final line = Paint()
      ..color = const Color(0xFFC9B48A)
      ..strokeWidth = 1;
    if (vertical) {
      final mid = size.height / 2;
      canvas.drawLine(Offset(4, mid), Offset(size.width - 4, mid), line);
      _pips(canvas, Rect.fromLTWH(0, 0, size.width, mid), lo);
      _pips(canvas, Rect.fromLTWH(0, mid, size.width, mid), hi);
    } else {
      final mid = size.width / 2;
      canvas.drawLine(Offset(mid, 4), Offset(mid, size.height - 4), line);
      _pips(canvas, Rect.fromLTWH(0, 0, mid, size.height), lo);
      _pips(canvas, Rect.fromLTWH(mid, 0, mid, size.height), hi);
    }
  }

  void _pips(Canvas canvas, Rect area, int count) {
    if (count <= 0 || count >= _pipIndex.length) return;
    final paint = Paint()..color = const Color(0xFF243042);
    final radius = math.min(area.width, area.height) * 0.08;
    for (final index in _pipIndex[count]) {
      final spot = _pipGrid[index];
      canvas.drawCircle(
        Offset(
            area.left + area.width * spot.dx, area.top + area.height * spot.dy),
        radius.clamp(1.2, 3.4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DominoFacePainter oldDelegate) =>
      oldDelegate.lo != lo ||
      oldDelegate.hi != hi ||
      oldDelegate.vertical != vertical;
}

class _BackPainter extends CustomPainter {
  const _BackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(4),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF0E3A24));
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFFF4E7C5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChainPainter extends CustomPainter {
  _ChainPainter({
    required this.chain,
    required this.rects,
    required this.leadingOnRight,
  });

  final List<DominoPlaced> chain;
  final Map<int, Rect> rects;
  final Map<int, bool> leadingOnRight;

  @override
  void paint(Canvas canvas, Size size) {
    for (final tile in chain) {
      final rect = rects[tile.id];
      if (rect == null) continue;
      canvas.save();
      canvas.translate(rect.left, rect.top);
      final halves = dominoHalfPips(
        tile,
        leadingOnRight: leadingOnRight[tile.id] ?? true,
      );
      DominoFacePainter(
        lo: halves.left,
        hi: halves.right,
        vertical: tile.isDouble,
      ).paint(canvas, rect.size);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ChainPainter oldDelegate) => true;
}
