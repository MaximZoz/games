import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException;
import 'package:multigames_client/games/nardy/nardy_bot.dart';
import 'package:multigames_client/games/nardy/nardy_engine.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';

/// Префикс идентификаторов локальных партий нард.
const String kNardyOfflinePrefix = 'offline:nardy:';

/// Локальная партия нард с ботом — тот же [NardyGameView], что онлайн.
class OfflineNardySession extends ChangeNotifier {
  OfflineNardySession._({
    required this.gameId,
    required this.humanUserId,
    required this.gameMode,
  }) {
    _startFresh();
  }

  final String gameId;
  final String humanUserId;
  final String gameMode;

  /// Пауза между шагами бота: бросок и каждая шашка видны отдельно.
  static const Duration botStepDelay = Duration(milliseconds: 750);

  final Random _rng = Random();
  Timer? _botTimer;
  bool _disposed = false;
  bool _forfeited = false;

  late NardyEngine _engine;

  static String newGameId() =>
      '$kNardyOfflinePrefix${DateTime.now().microsecondsSinceEpoch}';

  factory OfflineNardySession.create({
    required String humanUserId,
    required String gameMode,
    String? gameId,
  }) {
    final session = OfflineNardySession._(
      gameId: gameId ?? newGameId(),
      humanUserId: humanUserId.trim().isEmpty ? 'local:player' : humanUserId,
      gameMode: nardyNormalizeMode(gameMode),
    );
    OfflineNardyRegistry.instance.put(session);
    return session;
  }

  void _startFresh() {
    _botTimer?.cancel();
    _forfeited = false;
    _engine = NardyEngine.newGame(gameMode);
    _engine.roll(_rng);
    _maybeScheduleBot();
  }

  void restart() {
    _startFresh();
    notifyListeners();
  }

  @visibleForTesting
  NardyEngine get engine => _engine;

  NardyGameView get view => toView();

  NardyGameView toView() {
    final players = [
      NardyPlayerView(
        userId: humanUserId,
        seat: 0,
        displayName: '',
        off: _engine.off[0],
        bar: _engine.bar[0],
        pips: _engine.pips(0),
      ),
      NardyPlayerView(
        userId: nardyBotUserId,
        seat: 1,
        displayName: 'Bot',
        off: _engine.off[1],
        bar: _engine.bar[1],
        pips: _engine.pips(1),
        isBot: true,
        avatarValue: 'B',
      ),
    ];
    final myTurn = !_engine.isOver && _engine.turn == 0;
    return NardyGameView(
      id: gameId,
      lobbyId: '',
      gameMode: gameMode,
      board: _engine.board,
      bar: _engine.bar,
      off: _engine.off,
      dice: _engine.dice,
      rolled: _engine.rolled,
      turn: _engine.turn,
      turnNo: _engine.turnNo,
      seq: _engine.seq,
      headMoved: _engine.headMoved,
      players: players,
      playerIds: [humanUserId, nardyBotUserId],
      legalMoves: myTurn ? _engine.legalMoves() : const [],
      myIndex: 0,
      isMyTurn: myTurn,
      needsRoll: myTurn && _engine.dice.isEmpty && !_engine.canUndo,
      canUndo: myTurn && _engine.canUndo,
      turnComplete: myTurn && _engine.turnComplete,
      currentTurn: myTurn ? _engine.currentTurn : const [],
      lastTurn: _engine.lastTurn,
      lastTurnSeat: _engine.lastTurnSeat,
      turnTimeSec: 0,
      turnDeadline: 0,
      stakeBronze: 0,
      isOver: _engine.isOver,
      winnerIndex: _engine.winner,
      winnerUserId: _engine.winner == 0
          ? humanUserId
          : (_engine.winner == 1 ? nardyBotUserId : ''),
      winKind: _engine.winKind,
      isForfeit: _forfeited,
    );
  }

  /// Действие игрока в том же формате, что уходит на сервер.
  void applyLocalAction(Map<String, dynamic> body) {
    if (_disposed) throw GamesException(404, 'offline game not found');
    if (_engine.isOver) throw GamesException(400, 'game is over');
    final action = (body['action'] ?? 'move').toString();
    switch (action) {
      case 'roll':
        if (_engine.turn != 0) throw GamesException(400, 'not your turn');
        if (!_engine.roll(_rng)) throw GamesException(400, 'dice already rolled');
      case 'move':
        final mv = NardyMove(
          (body['from'] as num?)?.toInt() ?? 0,
          (body['die'] as num?)?.toInt() ?? 0,
        );
        if (!_engine.applyMove(0, mv)) {
          throw GamesException(400, 'illegal move');
        }
      case 'undo':
        if (!_engine.undo(0)) throw GamesException(400, 'nothing to undo');
      case 'end_turn':
        if (_engine.turn != 0) throw GamesException(400, 'not your turn');
        if (_engine.hasLegalMove) {
          throw GamesException(400, 'moves are still available');
        }
        _engine.endTurn();
      default:
        throw GamesException(400, 'unknown action');
    }
    notifyListeners();
    _maybeScheduleBot();
  }

  void forfeit() {
    if (_disposed || _engine.isOver) return;
    _botTimer?.cancel();
    _forfeited = true;
    _engine.forfeit(0);
    notifyListeners();
  }

  void _maybeScheduleBot() {
    _botTimer?.cancel();
    if (_disposed || _engine.isOver || _engine.turn != 1) return;
    _botTimer = Timer(botStepDelay, _runBotStep);
  }

  void _runBotStep() {
    if (_disposed || _engine.isOver || _engine.turn != 1) return;
    nardyPlayBotStep(_engine, _rng);
    notifyListeners();
    _maybeScheduleBot();
  }

  /// Доиграть ход бота немедленно (тесты — без ожидания таймеров).
  @visibleForTesting
  void debugRunBotTurn() {
    _botTimer?.cancel();
    if (_engine.isOver || _engine.turn != 1) return;
    nardyPlayBotTurn(_engine, _rng);
    notifyListeners();
  }

  /// Один шаг бота без таймера (тесты).
  @visibleForTesting
  bool debugRunBotStep() {
    _botTimer?.cancel();
    if (_engine.isOver || _engine.turn != 1) return true;
    final done = nardyPlayBotStep(_engine, _rng);
    notifyListeners();
    return done;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _botTimer?.cancel();
    OfflineNardyRegistry.instance.remove(gameId);
    super.dispose();
  }
}

/// Глобальный реестр офлайн-партий нард.
class OfflineNardyRegistry {
  OfflineNardyRegistry._();

  static final OfflineNardyRegistry instance = OfflineNardyRegistry._();

  final Map<String, OfflineNardySession> _sessions = {};

  void put(OfflineNardySession session) => _sessions[session.gameId] = session;

  OfflineNardySession? get(String gameId) => _sessions[gameId];

  OfflineNardySession? get current =>
      _sessions.isEmpty ? null : _sessions.values.last;

  void remove(String gameId) => _sessions.remove(gameId);

  void disposeAll() {
    final list = List<OfflineNardySession>.of(_sessions.values);
    _sessions.clear();
    for (final session in list) {
      session.dispose();
    }
  }

  bool isOffline(String gameId) => gameId.startsWith(kNardyOfflinePrefix);
}
