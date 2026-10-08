import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:multigames_client/games/chess/chess_bot.dart';
import 'package:multigames_client/games/chess/chess_engine.dart';
import 'package:multigames_client/games/chess/chess_repository.dart';
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
  }) {
    _startFresh();
  }

  final String gameId;
  final String humanUserId;
  final String gameMode;

  static const Duration botStepDelay = Duration(milliseconds: 450);

  Timer? _botTimer;
  bool _disposed = false;
  bool _forfeited = false;

  late ChessEngine _engine;

  static String newGameId() =>
      '$kChessOfflinePrefix${DateTime.now().microsecondsSinceEpoch}';

  factory OfflineChessSession.create({
    required String humanUserId,
    required String gameMode,
    String? gameId,
  }) {
    final session = OfflineChessSession._(
      gameId: gameId ?? newGameId(),
      humanUserId: humanUserId.trim().isEmpty ? 'local:player' : humanUserId,
      gameMode: ChessEngine.normalizeMode(gameMode),
    );
    OfflineChessRegistry.instance.put(session);
    return session;
  }

  void _startFresh() {
    _botTimer?.cancel();
    _forfeited = false;
    _engine = ChessEngine.newGame(gameMode);
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
    );
  }

  void move(ChessMove mv) {
    if (_disposed) throw GamesException(404, 'offline game not found');
    if (_engine.isOver) throw GamesException(400, 'game is over');
    try {
      _engine.apply(0, mv);
    } on StateError catch (e) {
      throw GamesException(400, e.message);
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
    final mv = chessPickMove(_engine);
    if (mv == null) return;
    try {
      _engine.apply(1, mv);
    } catch (_) {
      return;
    }
    notifyListeners();
    _maybeScheduleBot();
  }

  @visibleForTesting
  void debugRunBotTurn() {
    _botTimer?.cancel();
    while (!_engine.isOver && _engine.turn == 1) {
      final mv = chessPickMove(_engine);
      if (mv == null) break;
      _engine.apply(1, mv);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _botTimer?.cancel();
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
