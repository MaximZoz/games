import 'package:multigames_client/games/nardy/nardy_engine.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';

/// Цель выбранной шашки: куда она может прийти и какими одиночными ходами.
class NardyMoveTarget {
  const NardyMoveTarget({
    required this.track,
    required this.moves,
    this.bearOff = false,
  });

  /// Пункт дорожки. [nardyPoints] означает снятие с доски.
  final int track;
  final List<NardyMove> moves;
  final bool bearOff;
}

/// Все цели, куда может дойти одна выбранная шашка текущими кубиками.
///
/// Важно для дублей: если осталось три четвёрки, игрок должен увидеть поля
/// +4, +8 и +12 для той же шашки, если все промежуточные ходы легальны.
Map<int, NardyMoveTarget> nardyMoveTargetsFor(
  NardyGameView view,
  int from,
) {
  if (!view.isMyTurn || view.isOver || view.myIndex < 0) return const {};
  final engine = NardyEngine.fromSnapshot(
    mode: view.gameMode,
    board: view.board,
    bar: view.bar,
    off: view.off,
    turn: view.myIndex,
    dice: view.dice,
    rolled: view.rolled,
    headMoved: view.headMoved,
    turnNo: view.turnNo,
    winner: view.winnerIndex,
    winKind: view.winKind,
    seq: view.seq,
  );
  final out = <int, NardyMoveTarget>{};
  _collectTargets(engine, from, const <NardyMove>[], out);
  return out;
}

void _collectTargets(
  NardyEngine engine,
  int from,
  List<NardyMove> prefix,
  Map<int, NardyMoveTarget> out,
) {
  if (engine.dice.isEmpty || engine.isOver) return;
  for (final mv in engine.legalMoves()) {
    if (mv.from != from) continue;
    final next = engine.clone();
    if (!next.applyMove(next.turn, mv)) continue;
    final destination = _destinationOf(mv);
    final target = destination >= nardyPoints ? nardyPoints : destination;
    final moves = [...prefix, mv];
    final existing = out[target];
    if (existing == null || moves.length < existing.moves.length) {
      out[target] = NardyMoveTarget(
        track: target,
        moves: moves,
        bearOff: destination >= nardyPoints,
      );
    }
    if (destination < nardyPoints && next.turn == engine.turn) {
      _collectTargets(next, destination, moves, out);
    }
  }
}

int _destinationOf(NardyMove mv) {
  if (mv.from == nardyBarTrack) return mv.die - 1;
  return mv.from + mv.die;
}
