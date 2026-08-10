import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:multigames_client/games/games_repository.dart' show GamesException;
import 'package:multigames_client/games/poker/poker_offline_engine.dart';
import 'package:multigames_client/games/poker/poker_repository.dart';

/// Локальная партия покера с ботами — тот же [PokerGameView], что и онлайн.
class OfflinePokerSession extends ChangeNotifier {
  OfflinePokerSession._({
    required this.gameId,
    required this.humanUserId,
    required this.playerCount,
  }) {
    _startFresh();
  }

  final String gameId;
  final String humanUserId;
  final int playerCount;

  static const int me = 0;
  static const int startingChips = 1000;
  static const int smallBlind = 5;
  static const int bigBlind = 10;
  static const Duration botDelay = Duration(milliseconds: 700);

  late PokerEngine _engine;
  late List<String> _playerIds;
  late List<_PlayerMeta> _players;
  final Random _rng = Random();
  int _dealer = 0;
  Timer? _botTimer;
  bool _disposed = false;
  bool _started = false;

  PokerEngine get engine => _engine;

  static String newGameId() =>
      'offline:poker:${DateTime.now().microsecondsSinceEpoch}';

  factory OfflinePokerSession.create({
    required String humanUserId,
    int playerCount = 2,
    String? gameId,
  }) {
    final id = gameId ?? newGameId();
    final session = OfflinePokerSession._(
      gameId: id,
      humanUserId: humanUserId.trim().isEmpty ? 'local:player' : humanUserId,
      playerCount: playerCount.clamp(2, 6),
    );
    OfflinePokerRegistry.instance.put(session);
    return session;
  }

  void _startFresh() {
    _botTimer?.cancel();
    final n = playerCount.clamp(2, 6);
    _playerIds = [
      humanUserId,
      for (var i = 1; i < n; i++) 'bot:poker:$i',
    ];
    _players = [
      for (var i = 0; i < n; i++)
        _PlayerMeta(
          id: _playerIds[i],
          displayName: i == me ? null : 'Bot $i',
          avatarKind: 'letter',
          avatarValue: i == me ? null : 'B',
        ),
    ];
    _engine = PokerEngine.newGame(
      playerIds: _playerIds,
      startingChips: startingChips,
      smallBlind: smallBlind,
      bigBlind: bigBlind,
      dealerIndex: _dealer,
      rng: _rng,
    );
  }

  void restart() {
    _dealer = (_dealer + 1) % playerCount.clamp(2, 6);
    _startFresh();
    _started = false;
    notifyListeners();
    ensureStarted();
  }

  /// Запустить бота, если он ходит первым (UTG-бот на префлопе).
  void ensureStarted() {
    if (_started) {
      _scheduleBot();
      return;
    }
    _started = true;
    _scheduleBot();
  }

  PokerGameView get view => toView();

  PokerGameView toView() {
    final g = _engine;
    final isOver = g.isOver;
    final reveal = isOver ||
        g.street == PokerStreet.showdown ||
        g.street == PokerStreet.over;

    final players = <PokerPlayerView>[];
    for (var i = 0; i < g.players.length; i++) {
      final p = g.players[i];
      final meta = _players[i];
      final showHole = i == me || (reveal && !p.folded);
      players.add(PokerPlayerView(
        id: p.userId,
        displayName: meta.displayName,
        avatarKind: meta.avatarKind,
        avatarValue: meta.avatarValue,
        seat: p.seat,
        chips: p.chips,
        bet: p.bet,
        folded: p.folded,
        allIn: p.allIn,
        isActing: g.status == PokerStatus.active && i == g.actingIndex,
        holeCards: showHole
            ? p.hole.map(PokerApiCard.fromCard).toList()
            : null,
      ));
    }

    var legal = const <String>[];
    var callAmount = 0;
    var minRaiseTo = 0;
    var maxRaiseTo = 0;
    if (me >= 0 && me < g.players.length) {
      legal = g.legalActions(me);
      final mp = g.players[me];
      callAmount = g.currentBet - mp.bet;
      if (callAmount < 0) callAmount = 0;
      if (callAmount > mp.chips) callAmount = mp.chips;
      maxRaiseTo = mp.bet + mp.chips;
      minRaiseTo = g.currentBet + g.minRaise;
      if (minRaiseTo > maxRaiseTo) minRaiseTo = maxRaiseTo;
    }

    return PokerGameView(
      id: gameId,
      status: isOver ? PokerStatus.over : PokerStatus.active,
      street: g.street,
      lobbyId: '',
      chatId: null,
      playerIds: List.of(_playerIds),
      players: players,
      community: g.community.map(PokerApiCard.fromCard).toList(),
      pot: g.pot,
      currentBet: g.currentBet,
      minRaise: g.minRaise,
      smallBlind: g.smallBlind,
      bigBlind: g.bigBlind,
      dealerIndex: g.dealerIndex,
      actingIndex: g.actingIndex,
      myIndex: me,
      legalActions: legal,
      callAmount: callAmount,
      minRaiseTo: minRaiseTo,
      maxRaiseTo: maxRaiseTo,
      turnTimeSec: 0,
      turnDeadline: 0,
      stakeBronze: 0,
      winners: List.of(g.winners),
      winnerIds: List.of(g.winnerUserIds),
      isOver: isOver,
      isForfeit: false,
      isTimeout: false,
    );
  }

  Future<void> applyMove({required String type, int? amount}) async {
    if (_disposed) return;
    if (_engine.isOver) throw GamesException(400, 'game is over');
    if (_engine.actingIndex != me) {
      throw GamesException(400, 'not your turn');
    }
    try {
      _engine.apply(me, PokerAction(type, amount: amount ?? 0));
    } on StateError catch (e) {
      throw GamesException(400, e.message);
    }
    notifyListeners();
    _scheduleBot();
  }

  void _scheduleBot() {
    _botTimer?.cancel();
    if (_disposed || _engine.isOver) return;
    final idx = _engine.actingIndex;
    if (idx < 0 || idx >= _engine.players.length) return;
    if (!_engine.players[idx].userId.startsWith('bot:')) return;
    _botTimer = Timer(botDelay, () {
      if (_disposed || _engine.isOver) return;
      final acting = _engine.actingIndex;
      if (acting < 0 || acting >= _engine.players.length) return;
      if (!_engine.players[acting].userId.startsWith('bot:')) return;
      final action = pokerBotAction(_engine);
      try {
        _engine.apply(acting, action);
      } on StateError {
        try {
          _engine.apply(acting, const PokerAction(PokerActionType.fold));
        } catch (_) {}
      }
      notifyListeners();
      _scheduleBot();
    });
  }

  Future<void> forfeit() async {
    if (_disposed || _engine.isOver) return;
    _botTimer?.cancel();
    _engine.forceFold(me);
    notifyListeners();
    _scheduleBot();
  }

  @override
  void dispose() {
    _disposed = true;
    _botTimer?.cancel();
    OfflinePokerRegistry.instance.remove(gameId);
    super.dispose();
  }
}

class _PlayerMeta {
  const _PlayerMeta({
    required this.id,
    this.displayName,
    this.avatarKind = 'letter',
    this.avatarValue,
  });
  final String id;
  final String? displayName;
  final String avatarKind;
  final String? avatarValue;
}

/// Глобальный реестр офлайн-партий покера.
class OfflinePokerRegistry {
  OfflinePokerRegistry._();
  static final OfflinePokerRegistry instance = OfflinePokerRegistry._();

  final Map<String, OfflinePokerSession> _sessions = {};

  void put(OfflinePokerSession s) => _sessions[s.gameId] = s;

  OfflinePokerSession? get(String gameId) => _sessions[gameId];

  void remove(String gameId) => _sessions.remove(gameId);

  bool isOffline(String gameId) => gameId.startsWith('offline:poker:');
}
