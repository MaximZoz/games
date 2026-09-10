import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:multigames_client/games/checkers/checkers_bot.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';
import 'package:multigames_client/games/checkers/checkers_repository.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException;

/// Префикс идентификаторов локальных партий шашек.
const String kCheckersOfflinePrefix = 'offline:checkers:';

const String checkersBotUserId = 'bot:checkers';

/// Локальная партия с ботом — тот же [CheckersGameView], что онлайн.
class OfflineCheckersSession extends ChangeNotifier {
  OfflineCheckersSession._({
    required this.gameId,
    required this.humanUserId,
    required this.gameMode,
  }) {
    _startFresh();
  }

  final String gameId;
  final String humanUserId;
  final String gameMode;

  static const Duration botStepDelay = Duration(milliseconds: 500);

  Timer? _botTimer;
  bool _disposed = false;
  bool _forfeited = false;

  late CheckersEngine _engine;

  static String newGameId() =>
      '$kCheckersOfflinePrefix${DateTime.now().microsecondsSinceEpoch}';

  factory OfflineCheckersSession.create({
    required String humanUserId,
    required String gameMode,
    String? gameId,
  }) {
    final session = OfflineCheckersSession._(
      gameId: gameId ?? newGameId(),
      humanUserId: humanUserId.trim().isEmpty ? 'local:player' : humanUserId,
      gameMode: CheckersEngine.normalizeMode(gameMode),
    );
    OfflineCheckersRegistry.instance.put(session);
    return session;
  }

  void _startFresh() {
    _botTimer?.cancel();
    _forfeited = false;
    _engine = CheckersEngine.newGame(gameMode);
  }

  void restart() {
    _startFresh();
    notifyListeners();
  }

  @visibleForTesting
  CheckersEngine get engine => _engine;

  CheckersGameView get view => toView();

  CheckersGameView toView() {
    final players = [
      CheckersPlayerView(
        userId: humanUserId,
        seat: 0,
        displayName: '',
      ),
      CheckersPlayerView(
        userId: checkersBotUserId,
        seat: 1,
        displayName: 'Bot',
        isBot: true,
        avatarValue: 'B',
      ),
    ];
    final myTurn = !_engine.isOver && _engine.turn == 0;
    return CheckersGameView(
      id: gameId,
      lobbyId: '',
      gameMode: gameMode,
      board: List<int>.from(_engine.board),
      turn: _engine.turn,
      seq: _engine.seq,
      mustContinue: _engine.mustContinue,
      contR: _engine.contR,
      contC: _engine.contC,
      lastFromR: _engine.lastFromR,
      lastFromC: _engine.lastFromC,
      lastToR: _engine.lastToR,
      lastToC: _engine.lastToC,
      players: players,
      playerIds: [humanUserId, checkersBotUserId],
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
          : (_engine.winner == 1 ? checkersBotUserId : ''),
      isDraw: _engine.winner == CheckersEngine.winnerDraw,
      isForfeit: _forfeited,
    );
  }

  void move(CheckersMove mv) {
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
    final mv = checkersPickMove(_engine);
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
      final mv = checkersPickMove(_engine);
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
    OfflineCheckersRegistry.instance.remove(gameId);
    super.dispose();
  }
}

/// Глобальный реестр офлайн-партий шашек.
class OfflineCheckersRegistry {
  OfflineCheckersRegistry._();

  static final OfflineCheckersRegistry instance = OfflineCheckersRegistry._();

  final Map<String, OfflineCheckersSession> _sessions = {};

  void put(OfflineCheckersSession session) => _sessions[session.gameId] = session;

  OfflineCheckersSession? get(String gameId) => _sessions[gameId];

  OfflineCheckersSession? get current =>
      _sessions.isEmpty ? null : _sessions.values.last;

  void remove(String gameId) => _sessions.remove(gameId);

  void disposeAll() {
    final list = List<OfflineCheckersSession>.of(_sessions.values);
    _sessions.clear();
    for (final session in list) {
      session.dispose();
    }
  }

  bool isOffline(String gameId) => gameId.startsWith(kCheckersOfflinePrefix);
}
