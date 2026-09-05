import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:multigames_client/games/connect4/connect4_engine.dart';
import 'package:multigames_client/games/connect4/connect4_repository.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException;

/// Префикс идентификаторов локальных партий «четыре в ряд».
const String kConnect4OfflinePrefix = 'offline:connect4:';

const String connect4BotUserId = 'bot:connect4';

/// Локальная партия с ботом — тот же [Connect4GameView], что онлайн.
class OfflineConnect4Session extends ChangeNotifier {
  OfflineConnect4Session._({
    required this.gameId,
    required this.humanUserId,
    required this.gameMode,
  }) {
    _startFresh();
  }

  final String gameId;
  final String humanUserId;
  final String gameMode;

  static const Duration botStepDelay = Duration(milliseconds: 550);

  Timer? _botTimer;
  bool _disposed = false;
  bool _forfeited = false;

  late Connect4Engine _engine;

  static String newGameId() =>
      '$kConnect4OfflinePrefix${DateTime.now().microsecondsSinceEpoch}';

  factory OfflineConnect4Session.create({
    required String humanUserId,
    required String gameMode,
    String? gameId,
  }) {
    final session = OfflineConnect4Session._(
      gameId: gameId ?? newGameId(),
      humanUserId: humanUserId.trim().isEmpty ? 'local:player' : humanUserId,
      gameMode: Connect4Engine.normalizeMode(gameMode),
    );
    OfflineConnect4Registry.instance.put(session);
    return session;
  }

  void _startFresh() {
    _botTimer?.cancel();
    _forfeited = false;
    _engine = Connect4Engine.newGame(gameMode);
  }

  void restart() {
    _startFresh();
    notifyListeners();
  }

  @visibleForTesting
  Connect4Engine get engine => _engine;

  Connect4GameView get view => toView();

  Connect4GameView toView() {
    final players = [
      Connect4PlayerView(
        userId: humanUserId,
        seat: 0,
        displayName: '',
      ),
      Connect4PlayerView(
        userId: connect4BotUserId,
        seat: 1,
        displayName: 'Bot',
        isBot: true,
        avatarValue: 'B',
      ),
    ];
    final myTurn = !_engine.isOver && _engine.turn == 0;
    return Connect4GameView(
      id: gameId,
      lobbyId: '',
      gameMode: gameMode,
      cols: _engine.cols,
      rows: _engine.rows,
      board: List<int>.from(_engine.board),
      turn: _engine.turn,
      seq: _engine.seq,
      lastCol: _engine.lastCol,
      lastRow: _engine.lastRow,
      players: players,
      playerIds: [humanUserId, connect4BotUserId],
      legalColumns: myTurn ? _engine.legalColumns() : const [],
      myIndex: 0,
      isMyTurn: myTurn,
      turnTimeSec: 0,
      turnDeadline: 0,
      stakeBronze: 0,
      isOver: _engine.isOver,
      winnerIndex: _engine.winner,
      winnerUserId: _engine.winner == 0
          ? humanUserId
          : (_engine.winner == 1 ? connect4BotUserId : ''),
      isDraw: _engine.winner == Connect4Engine.winnerDraw,
      isForfeit: _forfeited,
    );
  }

  void drop(int col) {
    if (_disposed) throw GamesException(404, 'offline game not found');
    if (_engine.isOver) throw GamesException(400, 'game is over');
    try {
      _engine.drop(0, col);
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
    final col = connect4PickColumn(_engine);
    if (col < 0) return;
    try {
      _engine.drop(1, col);
    } catch (_) {
      return;
    }
    notifyListeners();
  }

  @visibleForTesting
  void debugRunBotTurn() {
    _botTimer?.cancel();
    if (_engine.isOver || _engine.turn != 1) return;
    _runBotStep();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _botTimer?.cancel();
    OfflineConnect4Registry.instance.remove(gameId);
    super.dispose();
  }
}

/// Глобальный реестр офлайн-партий «четыре в ряд».
class OfflineConnect4Registry {
  OfflineConnect4Registry._();

  static final OfflineConnect4Registry instance = OfflineConnect4Registry._();

  final Map<String, OfflineConnect4Session> _sessions = {};

  void put(OfflineConnect4Session session) => _sessions[session.gameId] = session;

  OfflineConnect4Session? get(String gameId) => _sessions[gameId];

  OfflineConnect4Session? get current =>
      _sessions.isEmpty ? null : _sessions.values.last;

  void remove(String gameId) => _sessions.remove(gameId);

  void disposeAll() {
    final list = List<OfflineConnect4Session>.of(_sessions.values);
    _sessions.clear();
    for (final session in list) {
      session.dispose();
    }
  }

  bool isOffline(String gameId) => gameId.startsWith(kConnect4OfflinePrefix);
}
