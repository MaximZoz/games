import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:multigames_client/games/domino/domino_bot.dart';
import 'package:multigames_client/games/domino/domino_engine.dart';
import 'package:multigames_client/games/domino/domino_repository.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException;

class OfflineDominoSession extends ChangeNotifier {
  OfflineDominoSession._({
    required this.gameId,
    required this.humanUserId,
    required this.playerCount,
    this.humanDisplayName,
    this.humanAvatarKind = 'letter',
    this.humanAvatarValue,
  }) {
    _startFresh();
  }

  static const Duration botDelay = Duration(milliseconds: 420);
  static const Duration roundPause = Duration(milliseconds: 2200);

  final String gameId;
  final String humanUserId;
  final int playerCount;
  final String? humanDisplayName;
  final String humanAvatarKind;
  final String? humanAvatarValue;

  late DominoGame _engine;
  Timer? _timer;
  bool _disposed = false;
  bool _started = false;

  DominoGame get engine => _engine;
  DominoGameView get view => _toView();

  static String newGameId() =>
      'offline:domino:${DateTime.now().microsecondsSinceEpoch}';

  factory OfflineDominoSession.create({
    required String humanUserId,
    int playerCount = 2,
    String? gameId,
    String? humanDisplayName,
    String? humanAvatarKind,
    String? humanAvatarValue,
  }) {
    final session = OfflineDominoSession._(
      gameId: gameId ?? newGameId(),
      humanUserId:
          humanUserId.trim().isEmpty ? 'local:player' : humanUserId.trim(),
      playerCount: playerCount.clamp(2, 4),
      humanDisplayName: humanDisplayName,
      humanAvatarKind: (humanAvatarKind ?? '').trim().isEmpty
          ? 'letter'
          : humanAvatarKind!.trim(),
      humanAvatarValue: humanAvatarValue,
    );
    OfflineDominoRegistry.instance.put(session);
    return session;
  }

  void _startFresh() {
    _timer?.cancel();
    final ids = <String>[
      humanUserId,
      for (var i = 1; i < playerCount; i++)
        i == 1 ? 'bot:domino' : 'bot:domino:$i',
    ];
    _engine = DominoGame.newGame(ids, DateTime.now().microsecondsSinceEpoch);
  }

  void ensureStarted() {
    _started = true;
    _schedule();
  }

  void restart() {
    _startFresh();
    _started = false;
    notifyListeners();
    ensureStarted();
  }

  DominoGameView _toView() {
    final reveal = _engine.status == dominoStatusRoundEnd || _engine.isOver;
    return DominoGameView(
      id: gameId,
      lobbyId: '',
      players: [
        for (var i = 0; i < _engine.players.length; i++)
          DominoPlayerView(
            id: _engine.players[i].userId,
            seat: i,
            hand: i == 0 || reveal
                ? List<int>.of(_engine.players[i].hand)
                : const [],
            handCount: _engine.players[i].hand.length,
            score: _engine.players[i].score,
            forfeited: _engine.players[i].forfeited,
            roundPips: _engine.players[i].roundPips,
            roundDelta: _engine.players[i].roundDelta,
            displayName: i == 0 ? humanDisplayName : null,
            avatarKind: i == 0 ? humanAvatarKind : 'letter',
            avatarValue: i == 0 ? humanAvatarValue : 'B',
          ),
      ],
      chain: [for (final tile in _engine.chain) tile.copy()],
      leftEnd: _engine.leftEnd,
      rightEnd: _engine.rightEnd,
      boneyardCount: _engine.boneyard.length,
      turn: _engine.turn,
      forcedTile: _engine.forcedTile,
      round: _engine.round,
      status: _engine.status,
      starter: _engine.starter,
      roundKind: _engine.roundKind,
      outSeat: _engine.outSeat,
      goatSeat: _engine.goatSeat,
      winnerUserIds: List<String>.of(_engine.winnerUserIds),
      legal: _engine.turn == 0 ? _engine.legal(0) : const [],
      targetScore: _engine.target,
      lastAction: _engine.lastAction,
      lastTile: _engine.lastAction == dominoActionDraw &&
              _engine.lastActor != 0 &&
              !reveal
          ? -1
          : _engine.lastTile,
      lastEnd: _engine.lastEnd,
      lastActor: _engine.lastActor,
      eventSeq: _engine.eventSeq,
      myIndex: 0,
      isMyTurnFlag: _engine.turn == 0 && _engine.status == dominoStatusPlaying,
    );
  }

  Future<void> applyMove({
    required String type,
    int? tile,
    String? end,
  }) async {
    if (_disposed) return;
    try {
      _engine.apply(DominoAction(
        type: type,
        tile: tile ?? 0,
        end: end ?? '',
        actor: type == dominoActionForfeit ? humanUserId : '',
      ));
    } on StateError catch (error) {
      throw GamesException(400, error.message);
    }
    notifyListeners();
    _schedule();
  }

  Future<void> forfeit() => applyMove(type: dominoActionForfeit);

  bool _botShouldAct() {
    if (_disposed || _engine.isOver) return false;
    if (_engine.status == dominoStatusRoundEnd) return true;
    final index = _engine.turn;
    if (index < 0 || index >= _engine.players.length) return false;
    return _engine.players[index].userId.startsWith('bot:');
  }

  void _schedule() {
    _timer?.cancel();
    if (!_started || !_botShouldAct()) return;
    final pause = _engine.status == dominoStatusRoundEnd;
    _timer = Timer(pause ? roundPause : botDelay, () {
      if (_disposed || !_botShouldAct()) return;
      try {
        if (_engine.status == dominoStatusRoundEnd) {
          _engine.apply(const DominoAction(type: dominoActionNextRound));
        } else {
          _engine.apply(dominoBestAction(_engine, _engine.turn));
        }
      } catch (_) {
        return;
      }
      notifyListeners();
      _schedule();
    });
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

class OfflineDominoRegistry {
  OfflineDominoRegistry._();

  static final OfflineDominoRegistry instance = OfflineDominoRegistry._();

  final Map<String, OfflineDominoSession> _sessions = {};
  OfflineDominoSession? _current;

  OfflineDominoSession? get current => _current;

  bool isOffline(String gameId) => gameId.startsWith('offline:domino:');

  OfflineDominoSession? get(String gameId) => _sessions[gameId];

  void put(OfflineDominoSession session) {
    _sessions[session.gameId] = session;
    _current = session;
  }

  void disposeAll() {
    for (final session in _sessions.values) {
      session.dispose();
    }
    _sessions.clear();
    _current = null;
  }
}
