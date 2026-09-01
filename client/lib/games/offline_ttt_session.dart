import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:multigames_client/game_engine/game_engine.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/offline_tictactoe.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyLastHumanStarted = 'offline_ttt_last_human_started';

/// Локальная партия крестиков с ботами — тот же [GameStateItem], что и онлайн.
class OfflineTttSession extends ChangeNotifier {
  OfflineTttSession._({
    required this.gameId,
    required this.humanUserId,
    required this.variant,
    required this.gridSize,
    required this.swapRule,
    required this.firstMoveRestriction,
    required OfflineTicTacToeGame game,
  }) : _game = game;

  final String gameId;
  final String humanUserId;
  final String variant;
  final int gridSize;
  final bool swapRule;
  final bool firstMoveRestriction;

  OfflineTicTacToeGame _game;
  Timer? _botTimer;
  bool _disposed = false;

  static const Duration botDelay = Duration(milliseconds: 400);

  OfflineTicTacToeGame get engine => _game;

  static String newGameId() =>
      'offline:ttt:${DateTime.now().microsecondsSinceEpoch}';

  static Future<OfflineTttSession> create({
    required String humanUserId,
    String variant = variantClassic,
    int? gridSize,
    bool swapRule = true,
    bool firstMoveRestriction = false,
    String? gameId,
  }) async {
    final resolved = parseVariant(variant);
    final cfg = configForVariant(resolved);
    var humanStarts = true;
    final alternate = swapRule && cfg.maxPlayers <= 2;
    if (alternate) {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getBool(_keyLastHumanStarted) ?? false;
      humanStarts = !last;
      await prefs.setBool(_keyLastHumanStarted, humanStarts);
    }
    final me = humanUserId.trim().isEmpty ? 'local:player' : humanUserId;
    final id = gameId ?? newGameId();
    final game = OfflineTicTacToeGame(
      variant: resolved,
      gridSize: gridSize,
      firstMoveRestriction: firstMoveRestriction,
      humanStarts: humanStarts,
    );
    final session = OfflineTttSession._(
      gameId: id,
      humanUserId: me,
      variant: resolved,
      gridSize: game.gridSize,
      swapRule: swapRule,
      firstMoveRestriction: firstMoveRestriction,
      game: game,
    );
    OfflineTttRegistry.instance.put(session);
    session._scheduleBot();
    return session;
  }

  Future<void> restart() async {
    _botTimer?.cancel();
    final cfg = configForVariant(variant);
    var humanStarts = true;
    final alternate = swapRule && cfg.maxPlayers <= 2;
    if (alternate) {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getBool(_keyLastHumanStarted) ?? false;
      humanStarts = !last;
      await prefs.setBool(_keyLastHumanStarted, humanStarts);
    }
    _game = OfflineTicTacToeGame(
      variant: variant,
      gridSize: gridSize,
      firstMoveRestriction: firstMoveRestriction,
      humanStarts: humanStarts,
    );
    notifyListeners();
    _scheduleBot();
  }

  GameStateItem get view => toGameStateItem();

  GameStateItem toGameStateItem() {
    final g = _game;
    final marks = g.marks;
    String botId(int i) => 'bot:ttt:$i';
    String userForMark(String mark) {
      if (mark == g.humanMark) return humanUserId;
      final idx = marks.indexOf(mark);
      return botId(idx < 0 ? 1 : idx);
    }

    String? nameFor(String mark) {
      if (mark == g.humanMark) return null;
      final idx = marks.indexOf(mark);
      return 'Bot ${idx < 0 ? 1 : idx}';
    }

    // Как online: status = active | draw | x_won | o_won | …
    final status = g.isFinished ? g.status : 'active';
    String? winner;
    if (g.status.endsWith('_won')) {
      winner = g.status.replaceAll('_won', '');
    }

    return GameStateItem(
      id: gameId,
      board: List<String>.from(g.board),
      variant: g.variant,
      turn: g.turn,
      winner: winner,
      status: status,
      forfeit: false,
      timeout: false,
      turnTimeSec: 0,
      turnDeadline: null,
      gridSize: g.gridSize,
      maxPlayers: marks.length,
      xUserId: userForMark('x'),
      oUserId: marks.contains('o') ? userForMark('o') : '',
      tUserId: marks.contains('t') ? userForMark('t') : '',
      sUserId: marks.contains('s') ? userForMark('s') : '',
      swapRule: swapRule,
      firstMoveRestriction: firstMoveRestriction,
      canSwap: false,
      stakeBronze: 0,
      xDisplayName: nameFor('x'),
      oDisplayName: marks.contains('o') ? nameFor('o') : null,
      tDisplayName: marks.contains('t') ? nameFor('t') : null,
      sDisplayName: marks.contains('s') ? nameFor('s') : null,
      xAvatarKind: 'letter',
      oAvatarKind: 'letter',
      tAvatarKind: 'letter',
      sAvatarKind: 'letter',
      xAvatarValue: g.humanMark == 'x' ? null : 'B',
      oAvatarValue: g.humanMark == 'o' ? null : 'B',
      tAvatarValue: marks.contains('t')
          ? (g.humanMark == 't' ? null : 'B')
          : null,
      sAvatarValue: marks.contains('s')
          ? (g.humanMark == 's' ? null : 'B')
          : null,
      chatId: null,
      eliminatedMarks: const [],
      winningCells: g.winningCells,
      nextBoard: g.nextBoard,
      metaBoard: List<String>.from(g.metaBoard),
      drawOfferBy: null,
    );
  }

  Future<GameStateItem> makeMove(int cell) async {
    if (_disposed || _game.isFinished) {
      throw GamesException(400, 'game over');
    }
    if (!_game.playHuman(cell)) {
      throw GamesException(400, 'illegal move');
    }
    notifyListeners();
    _scheduleBot();
    return toGameStateItem();
  }

  void _scheduleBot() {
    _botTimer?.cancel();
    if (_disposed || _game.isFinished || _game.isHumanTurn) return;
    _botTimer = Timer(botDelay, () {
      if (_disposed || _game.isFinished || _game.isHumanTurn) return;
      _game.applyBotMove();
      notifyListeners();
      _scheduleBot();
    });
  }

  Future<void> forfeit() async {
    if (_disposed || _game.isFinished) return;
    _botTimer?.cancel();
    // Помечаем победу бота (первый не-человеческий mark).
    final botMark = _game.marks.firstWhere(
      (m) => m != _game.humanMark,
      orElse: () => 'o',
    );
    _game.status = '${botMark}_won';
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _botTimer?.cancel();
    OfflineTttRegistry.instance.remove(gameId);
    super.dispose();
  }
}

class OfflineTttRegistry {
  OfflineTttRegistry._();
  static final OfflineTttRegistry instance = OfflineTttRegistry._();

  final Map<String, OfflineTttSession> _sessions = {};

  void put(OfflineTttSession s) => _sessions[s.gameId] = s;

  OfflineTttSession? get(String gameId) => _sessions[gameId];

  OfflineTttSession? get current =>
      _sessions.isEmpty ? null : _sessions.values.last;

  void remove(String gameId) => _sessions.remove(gameId);

  void disposeAll() {
    final list = List<OfflineTttSession>.of(_sessions.values);
    _sessions.clear();
    for (final s in list) {
      s.dispose();
    }
  }

  bool isOffline(String gameId) => gameId.startsWith('offline:ttt:');
}
