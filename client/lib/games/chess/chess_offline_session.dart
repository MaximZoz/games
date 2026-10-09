import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:multigames_client/games/chess/chess_bot.dart';
import 'package:multigames_client/games/chess/chess_engine.dart';
import 'package:multigames_client/games/chess/chess_repository.dart';
import 'package:multigames_client/games/chess/chess_rules.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException;

/// Префикс идентификаторов локальных партий шахмат.
const String kChessOfflinePrefix = 'offline:chess:';

const String chessBotUserId = 'bot:chess';

/// Локальная партия с ботом — тот же [ChessGameView], что и онлайн.
class OfflineChessSession extends ChangeNotifier {
  OfflineChessSession._({
    required this.gameId,
    required this.humanUserId,
    required this.gameMode,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _startFresh();
  }

  final String gameId;
  final String humanUserId;
  final String gameMode;
  final DateTime Function() _now;

  static const Duration botStepDelay = Duration(milliseconds: 450);

  Timer? _botTimer;
  Timer? _clockTimer;
  bool _disposed = false;
  bool _forfeited = false;
  bool _timeout = false;
  int _clock0 = 0;
  int _clock1 = 0;
  int _inc = 0;
  int _running = -1;
  DateTime _anchor = DateTime.fromMillisecondsSinceEpoch(0);

  late ChessEngine _engine;

  static String newGameId() =>
      '$kChessOfflinePrefix${DateTime.now().microsecondsSinceEpoch}';

  factory OfflineChessSession.create({
    required String humanUserId,
    required String gameMode,
    String? gameId,
    DateTime Function()? now,
  }) {
    final session = OfflineChessSession._(
      gameId: gameId ?? newGameId(),
      humanUserId: humanUserId.trim().isEmpty ? 'local:player' : humanUserId,
      gameMode: ChessEngine.normalizeMode(gameMode),
      now: now,
    );
    OfflineChessRegistry.instance.put(session);
    return session;
  }

  void _startFresh() {
    _botTimer?.cancel();
    _clockTimer?.cancel();
    _forfeited = false;
    _timeout = false;
    _engine = ChessEngine.newGame(gameMode);
    final budget = chessClockBudgetMs(gameMode);
    _clock0 = budget.$1;
    _clock1 = budget.$1;
    _inc = budget.$2;
    _running = 0;
    _anchor = _now();
    _armTimeout();
  }

  void restart() {
    _startFresh();
    notifyListeners();
  }

  @visibleForTesting
  ChessEngine get engine => _engine;

  ChessGameView get view => toView();

  ChessGameView toView() {
    final players = [
      ChessPlayerView(
        userId: humanUserId,
        seat: 0,
        displayName: '',
      ),
      const ChessPlayerView(
        userId: chessBotUserId,
        seat: 1,
        displayName: 'Bot',
        isBot: true,
        avatarValue: 'B',
      ),
    ];
    final myTurn = !_engine.isOver && _engine.turn == 0;
    return ChessGameView(
      id: gameId,
      lobbyId: '',
      gameMode: gameMode,
      board: List<int>.from(_engine.board),
      turn: _engine.turn,
      seq: _engine.seq,
      inCheck: _engine.inCheck,
      lastFromR: _engine.lastFromR,
      lastFromC: _engine.lastFromC,
      lastToR: _engine.lastToR,
      lastToC: _engine.lastToC,
      players: players,
      playerIds: [humanUserId, chessBotUserId],
      legalMoves: myTurn ? _engine.legalMoves() : const [],
      myIndex: 0,
      isMyTurn: myTurn,
      turnTimeSec: 0,
      turnDeadline: 0,
      stakeBronze: 0,
      isOver: _engine.isOver,
      winnerIndex: _engine.winner,
      winnerUserId: _engine.winner == 0
          ? humanUserId
          : (_engine.winner == 1 ? chessBotUserId : ''),
      isDraw: _engine.winner == ChessEngine.winnerDraw,
      drawReason: _engine.drawReason,
      isForfeit: _forfeited,
      isTimeout: _timeout,
      hasClock: true,
      clockMs0: _shown(0),
      clockMs1: _shown(1),
      clockIncMs: _inc,
      clockRunning: _engine.isOver ? -1 : _running,
    );
  }

  int _bank(int seat) => seat == 0 ? _clock0 : _clock1;

  int _shown(int seat) {
    var ms = _bank(seat);
    if (_running == seat) {
      ms -= _now().difference(_anchor).inMilliseconds;
    }
    return math.max(0, ms);
  }

  bool _flagged(int seat) => _running == seat && _shown(seat) <= 0;

  void _commitMoveClock(int mover) {
    final elapsed = _now().difference(_anchor).inMilliseconds;
    final next = math.max(0, _bank(mover) - elapsed) + _inc;
    if (mover == 0) {
      _clock0 = next;
    } else {
      _clock1 = next;
    }
    if (_engine.isOver) {
      _running = -1;
      _clockTimer?.cancel();
      return;
    }
    _running = 1 - mover;
    _anchor = _now();
    _armTimeout();
  }

  void _loseOnTime(int seat) {
    if (_engine.isOver) return;
    _clockTimer?.cancel();
    _botTimer?.cancel();
    if (seat == 0) {
      _clock0 = 0;
    } else {
      _clock1 = 0;
    }
    _running = -1;
    _timeout = true;
    _engine.forfeit(seat);
  }

  void _armTimeout() {
    _clockTimer?.cancel();
    if (_disposed || _engine.isOver || _running < 0) return;
    final remain = _shown(_running);
    if (remain <= 0) {
      _loseOnTime(_running);
      return;
    }
    _clockTimer = Timer(Duration(milliseconds: remain), () {
      if (_disposed || _engine.isOver) return;
      _loseOnTime(_running);
      notifyListeners();
    });
  }

  void move(ChessMove mv) {
    if (_disposed) throw GamesException(404, 'offline game not found');
    if (_engine.isOver) throw GamesException(400, 'game is over');
    if (_flagged(0)) {
      _loseOnTime(0);
      notifyListeners();
      return;
    }
    try {
      _engine.apply(0, mv);
    } on StateError catch (e) {
      throw GamesException(400, e.message);
    }
    _commitMoveClock(0);
    notifyListeners();
    _maybeScheduleBot();
  }

  void forfeit() {
    if (_disposed || _engine.isOver) return;
    _botTimer?.cancel();
    _clockTimer?.cancel();
    _running = -1;
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
    if (_flagged(1)) {
      _loseOnTime(1);
      notifyListeners();
      return;
    }
    final mv = chessPickMove(_engine);
    if (mv == null) return;
    try {
      _engine.apply(1, mv);
    } catch (_) {
      return;
    }
    _commitMoveClock(1);
    notifyListeners();
    _maybeScheduleBot();
  }

  @visibleForTesting
  void debugRunBotTurn() {
    _botTimer?.cancel();
    while (!_engine.isOver && _engine.turn == 1) {
      if (_flagged(1)) {
        _loseOnTime(1);
        break;
      }
      final mv = chessPickMove(_engine);
      if (mv == null) break;
      _engine.apply(1, mv);
      _commitMoveClock(1);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _botTimer?.cancel();
    _clockTimer?.cancel();
    OfflineChessRegistry.instance.remove(gameId);
    super.dispose();
  }
}

/// Глобальный реестр офлайн-партий шахмат.
class OfflineChessRegistry {
  OfflineChessRegistry._();

  static final OfflineChessRegistry instance = OfflineChessRegistry._();

  final Map<String, OfflineChessSession> _sessions = {};

  void put(OfflineChessSession session) =>
      _sessions[session.gameId] = session;

  OfflineChessSession? get(String gameId) => _sessions[gameId];

  OfflineChessSession? get current =>
      _sessions.isEmpty ? null : _sessions.values.last;

  void remove(String gameId) => _sessions.remove(gameId);

  void disposeAll() {
    final list = List<OfflineChessSession>.of(_sessions.values);
    _sessions.clear();
    for (final session in list) {
      session.dispose();
    }
  }

  bool isOffline(String gameId) => gameId.startsWith(kChessOfflinePrefix);
}
