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

/// Оптимистичный снимок после локально выбранных ходов.
///
/// Нужен, чтобы анимация шашки стартовала сразу после клика по цели, а не
/// после HTTP/WS-подтверждения. Сервер всё равно остаётся источником истины:
/// как только придёт свежий снимок с `seq`, экран заменит оптимистичный view.
NardyGameView nardyViewAfterMoves(
  NardyGameView view,
  List<NardyMove> moves,
) {
  if (moves.isEmpty || !view.isMyTurn || view.myIndex < 0) return view;
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
  final played = <NardyPlayedMove>[];
  for (final mv in moves) {
    final destination = _destinationOf(mv);
    if (!engine.applyMove(view.myIndex, mv)) return view;
    played.add(NardyPlayedMove(
      from: mv.from,
      to: destination >= nardyPoints ? nardyPoints : destination,
      die: mv.die,
      boreOff: destination >= nardyPoints,
    ));
  }
  final currentTurn = [...view.currentTurn, ...played];
  return NardyGameView(
    id: view.id,
    lobbyId: view.lobbyId,
    gameMode: view.gameMode,
    board: engine.board,
    bar: engine.bar,
    off: engine.off,
    dice: engine.dice,
    rolled: engine.rolled,
    turn: engine.turn,
    turnNo: engine.turnNo,
    seq: view.seq + played.length,
    headMoved: engine.headMoved,
    players: [
      for (final player in view.players)
        if (player.seat >= 0 && player.seat < 2)
          NardyPlayerView(
            userId: player.userId,
            seat: player.seat,
            displayName: player.displayName,
            off: engine.off[player.seat],
            bar: engine.bar[player.seat],
            pips: engine.pips(player.seat),
            isBot: player.isBot,
            avatarKind: player.avatarKind,
            avatarValue: player.avatarValue,
            frameCode: player.frameCode,
            frameColor: player.frameColor,
          )
        else
          player,
    ],
    playerIds: view.playerIds,
    legalMoves: engine.turn == view.myIndex ? engine.legalMoves() : const [],
    myIndex: view.myIndex,
    isMyTurn: engine.turn == view.myIndex && !engine.isOver,
    needsRoll: engine.turn == view.myIndex &&
        !engine.isOver &&
        engine.dice.isEmpty &&
        currentTurn.isEmpty,
    canUndo: currentTurn.isNotEmpty && !engine.isOver,
    turnComplete:
        engine.turn == view.myIndex && !engine.isOver && engine.dice.isEmpty,
    currentTurn: currentTurn,
    lastTurn: view.lastTurn,
    lastTurnSeat: view.lastTurnSeat,
    turnTimeSec: view.turnTimeSec,
    turnDeadline: view.turnDeadline,
    stakeBronze: view.stakeBronze,
    isOver: engine.isOver,
    winnerIndex: engine.winner,
    winnerUserId: view.winnerUserId,
    winKind: engine.winKind,
    isForfeit: view.isForfeit,
    isTimeout: view.isTimeout,
  );
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
