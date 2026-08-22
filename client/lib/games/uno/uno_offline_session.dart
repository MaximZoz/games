import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException;
import 'package:multigames_client/games/uno/uno_bot.dart';
import 'package:multigames_client/games/uno/uno_card.dart';
import 'package:multigames_client/games/uno/uno_engine.dart';
import 'package:multigames_client/games/uno/uno_repository.dart';

class OfflineUnoSession extends ChangeNotifier {
  OfflineUnoSession._({
    required this.gameId,
    required this.humanUserId,
    required this.playerCount,
    this.humanDisplayName,
    this.humanAvatarKind = 'letter',
    this.humanAvatarValue,
  }) {
    _startFresh();
  }

  static const int me = 0;
  static const Duration botDelay = Duration(milliseconds: 650);
  static const Duration roundPause = Duration(milliseconds: 2600);

  final String gameId;
  final String humanUserId;
  final int playerCount;
  final String? humanDisplayName;
  final String humanAvatarKind;
  final String? humanAvatarValue;

  late UnoEngine _engine;
  final Random _random = Random();
  Timer? _botTimer;
  bool _disposed = false;
  bool _started = false;

  UnoEngine get engine => _engine;
  UnoGameView get view => _toView();

  static String newGameId() =>
      'offline:uno:${DateTime.now().microsecondsSinceEpoch}';

  factory OfflineUnoSession.create({
    required String humanUserId,
    int playerCount = 2,
    String? gameId,
    String? humanDisplayName,
    String? humanAvatarKind,
    String? humanAvatarValue,
  }) {
    final session = OfflineUnoSession._(
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
    OfflineUnoRegistry.instance.put(session);
    return session;
  }

  void _startFresh() {
    _botTimer?.cancel();
    final ids = <String>[
      humanUserId,
      for (var i = 1; i < playerCount; i++) 'bot:uno:$i',
    ];
    _engine = UnoEngine.newGame(
      playerIds: ids,
      seed: DateTime.now().microsecondsSinceEpoch,
    );
  }

  void ensureStarted() {
    if (_started) {
      _scheduleBot();
      return;
    }
    _started = true;
    _scheduleBot();
  }

  void restart() {
    _startFresh();
    _started = false;
    notifyListeners();
    ensureStarted();
  }

  UnoGameView _toView() {
    final game = _engine;
    return UnoGameView(
      id: gameId,
      lobbyId: '',
      players: [
        for (var i = 0; i < game.players.length; i++)
          UnoPlayerView(
            id: game.players[i].userId,
            seat: game.players[i].seat,
            hand: i == me ? List.of(game.players[i].hand) : const [],
            handCount: game.players[i].hand.length,
            score: game.players[i].score,
            saidUno: game.players[i].saidUno,
            forfeited: game.players[i].forfeited,
            displayName: i == me ? humanDisplayName : null,
            avatarKind: i == me ? humanAvatarKind : 'letter',
            avatarValue: i == me ? humanAvatarValue : 'B',
          ),
      ],
      topDiscard: game.topDiscard,
      drawCount: game.drawPile.length,
      currentColor: game.currentColor,
      direction: game.direction,
      currentIndex: game.currentIndex,
      currentUserId:
          game.currentIndex >= 0 ? game.players[game.currentIndex].userId : '',
      myIndex: me,
      status: game.status,
      pendingDraw: game.pendingDraw,
      drawnCardId: game.drawnCardId,
      lastPlayedBy: game.lastPlayedBy,
      roundNumber: game.roundNumber,
      targetScore: game.targetScore,
      winnerUserIds: List.of(game.winnerUserIds),
      eliminatedOrder: List.of(game.eliminatedOrder),
      lastRoundWinnerUserId: game.lastRoundWinnerUserId,
      lastRoundPoints: game.lastRoundPoints,
      lastRoundNumber: game.lastRoundNumber,
      canChallengeUno: game.canChallengeUno(me),
      unoVulnerableAtMs: game.unoVulnerableAtMs,
      canChallengeWd4: game.currentIndex == me &&
          game.status == UnoStatus.awaitingWd4Challenge,
      mustChooseColor: game.colorChooserIndex == me &&
          game.status == UnoStatus.awaitingColor,
      canKeepOrPlayDrawn:
          game.currentIndex == me && game.status == UnoStatus.awaitingDrawnPlay,
      eventSeq: game.eventSeq,
      lastEventType: game.lastEventType,
      lastEventActor: game.lastEventActor,
      lastDrawUserId: game.lastDrawUserId,
      lastDrawCount: game.lastDrawCount,
      lastEventCard: game.lastEventCard,
    );
  }

  Future<void> applyMove({
    required String type,
    String? cardId,
    UnoColor? color,
    String? targetUserId,
  }) async {
    if (_disposed) return;
    try {
      _engine.apply(UnoAction(
        type,
        cardId: cardId,
        color: color,
        targetUserId: targetUserId,
        actorUserId: humanUserId,
      ));
    } on StateError catch (error) {
      throw GamesException(400, error.message);
    }
    notifyListeners();
    _scheduleBot();
  }

  Future<void> forfeit() => applyMove(type: UnoActionType.forfeit);

  bool _botShouldAct() {
    if (_disposed || _engine.isOver) return false;
    if (_engine.status == UnoStatus.betweenRounds) return false;
    if (_engine.status == UnoStatus.awaitingColor) {
      final chooser = _engine.colorChooserIndex;
      return chooser >= 0 &&
          chooser < _engine.players.length &&
          _engine.players[chooser].userId.startsWith('bot:');
    }
    final index = _engine.currentIndex;
    if (index < 0 || index >= _engine.players.length) return false;
    return _engine.players[index].userId.startsWith('bot:');
  }

  void _scheduleBot() {
    _botTimer?.cancel();
    if (_disposed || _engine.isOver) return;
    if (_engine.status == UnoStatus.betweenRounds) {
      _botTimer = Timer(roundPause, _advanceRound);
      return;
    }
    if (!_botShouldAct()) return;
    _botTimer = Timer(botDelay, _runBotTurn);
  }

  void _advanceRound() {
    if (_disposed || _engine.status != UnoStatus.betweenRounds) return;
    try {
      _engine.apply(const UnoAction(UnoActionType.nextRound));
    } on StateError {
      return;
    }
    notifyListeners();
    _scheduleBot();
  }

  void _runBotTurn() {
    if (_disposed || _engine.isOver || !_botShouldAct()) return;
    try {
      _applyBotAction();
      final vulnerable = _engine.unoVulnerableIndex;
      if (vulnerable >= 0 &&
          vulnerable < _engine.players.length &&
          _engine.players[vulnerable].userId.startsWith('bot:')) {
        try {
          _engine.apply(UnoAction(
            UnoActionType.callUno,
            actorUserId: _engine.players[vulnerable].userId,
          ));
        } on StateError {
          // окно Уно уже закрыто
        }
      }
    } on StateError {
      _recoverBotTurn();
    }
    notifyListeners();
    _scheduleBot();
  }

  void _applyBotAction() {
    final index = _engine.currentIndex;
    if (_engine.status == UnoStatus.active &&
        _engine.canChallengeUno(index) &&
        _random.nextDouble() < 0.75) {
      try {
        _engine.apply(UnoAction(
          UnoActionType.challengeUno,
          actorUserId: _engine.players[index].userId,
          targetUserId: _engine.players[_engine.unoVulnerableIndex].userId,
        ));
        return;
      } on StateError {
        // дальше обычный ход
      }
    }
    _engine.apply(pickUnoBotAction(_engine, random: _random));
  }

  void _recoverBotTurn() {
    final chooser = _engine.colorChooserIndex;
    final fallbacks = <UnoAction>[
      if (_engine.status == UnoStatus.awaitingColor &&
          chooser >= 0 &&
          chooser < _engine.players.length)
        UnoAction(
          UnoActionType.chooseColor,
          color: chooseUnoBotColor(_engine.players[chooser]),
        ),
      if (_engine.status == UnoStatus.awaitingDrawnPlay)
        const UnoAction(UnoActionType.keep),
      if (_engine.status == UnoStatus.awaitingWd4Challenge)
        const UnoAction(UnoActionType.draw),
      const UnoAction(UnoActionType.draw),
    ];
    for (final action in fallbacks) {
      try {
        _engine.apply(action);
        return;
      } on StateError {
        continue;
      }
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _botTimer?.cancel();
    OfflineUnoRegistry.instance.remove(gameId);
    super.dispose();
  }
}

class OfflineUnoRegistry {
  OfflineUnoRegistry._();
  static final instance = OfflineUnoRegistry._();

  final Map<String, OfflineUnoSession> _sessions = {};

  void put(OfflineUnoSession session) => _sessions[session.gameId] = session;
  OfflineUnoSession? get(String gameId) => _sessions[gameId];
  void remove(String gameId) => _sessions.remove(gameId);
  bool isOffline(String gameId) => gameId.startsWith('offline:uno:');
}
