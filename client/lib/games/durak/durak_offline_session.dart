import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/games/durak/durak_bot.dart';
import 'package:multigames_client/games/durak/durak_engine.dart';
import 'package:multigames_client/games/durak/durak_repository.dart';
import 'package:multigames_client/games/games_repository.dart' show GamesException;

/// Локальная партия Дурака с ботами — тот же [DurakGameView], что и онлайн.
class OfflineDurakSession extends ChangeNotifier {
  OfflineDurakSession._({
    required this.gameId,
    required this.humanUserId,
    required this.deckSize,
    required this.playerCount,
    required this.mode,
  }) {
    _startFresh();
  }

  final String gameId;
  final String humanUserId;
  final int deckSize;
  final int playerCount;
  final String mode;

  static const int me = 0;
  static const Duration botDelay = Duration(milliseconds: 650);
  static const Duration bitoRevealDelay = Duration(milliseconds: 1000);
  static const Duration takeRevealDelay = Duration(milliseconds: 1000);

  /// Как [OpeningDealGrace] на сервере — боты не ходят во время стартовой раздачи.
  static Duration openingDealGrace(int players) {
    final p = players.clamp(2, 4);
    return Duration(milliseconds: 1500 + 6 * p * 280 + 800);
  }

  late DurakGame _game;
  late List<DurakBot> _bots;
  late List<String> _playerIds;
  late List<DurakPlayerMeta> _players;
  Timer? _botTimer;
  Timer? _revealTimer;
  bool _disposed = false;
  bool _lastWasTake = false;
  bool _dealGraceDone = false;
  bool _fxHold = false;
  String? _revealPhase; // bito_reveal | take_reveal

  DurakGame get engine => _game;

  static String newGameId() =>
      'offline:durak:${DateTime.now().microsecondsSinceEpoch}';

  factory OfflineDurakSession.create({
    required String humanUserId,
    int deckSize = 36,
    int playerCount = 2,
    String mode = durakModePodkidnoi,
    String? gameId,
  }) {
    final id = gameId ?? newGameId();
    final session = OfflineDurakSession._(
      gameId: id,
      humanUserId: humanUserId.trim().isEmpty ? 'local:player' : humanUserId,
      deckSize: deckSize,
      playerCount: playerCount.clamp(2, 4),
      mode: mode == durakModePerevodnoi
          ? durakModePerevodnoi
          : durakModePodkidnoi,
    );
    OfflineDurakRegistry.instance.put(session);
    return session;
  }

  void _startFresh() {
    _botTimer?.cancel();
    _revealTimer?.cancel();
    _revealPhase = null;
    _lastWasTake = false;
    _dealGraceDone = false;
    _fxHold = false;
    final n = playerCount.clamp(2, 4);
    _game = DurakGame.startNew(
      playerCount: n,
      deckSize: deckSize,
      mode: mode,
    );
    _bots = [for (var i = 1; i < n; i++) DurakBot(index: i)];
    _playerIds = [
      humanUserId,
      for (var i = 1; i < n; i++) 'bot:durak:$i',
    ];
    _players = [
      for (var i = 0; i < n; i++)
        DurakPlayerMeta(
          id: _playerIds[i],
          displayName: i == me ? null : 'Bot $i',
          avatarKind: 'letter',
          avatarValue: i == me ? null : 'B',
        ),
    ];
  }

  void restart() {
    _startFresh();
    notifyListeners();
    _scheduleBot();
  }

  DurakGameView get view => toView();

  DurakGameView toView() {
    final g = _game;
    final trumpCard = g.openTrumpCard ??
        (g.bito.isNotEmpty
            ? g.bito.last
            : PlayingCard(Rank.ace, g.trump));
    final phase = _revealPhase ?? _phaseOf(g.turn);
    final hands = <DurakHandView>[
      for (var i = 0; i < g.playerCount; i++)
        i == me
            ? DurakHandView(
                count: g.hands[i].length,
                cards: g.hands[i].map(DurakApiCard.fromCard).toList(),
              )
            : DurakHandView(count: g.hands[i].length),
    ];
    final legalAttack = <DurakApiCard>[];
    final legalDefend = <DurakApiCard>[];
    final legalTransfer = <DurakApiCard>[];
    var canThrow = false;
    if (_revealPhase == null && !g.isOver && g.isAlive(me)) {
      for (final c in g.hands[me]) {
        if (g.canAttackWith(c, me)) {
          legalAttack.add(DurakApiCard.fromCard(c));
        }
        if (g.canDefendWith(c, me)) {
          legalDefend.add(DurakApiCard.fromCard(c));
        }
      }
      legalTransfer.addAll(
        g.legalTransferCards(me).map(DurakApiCard.fromCard),
      );
      canThrow = g.canThrowIn(me);
    }
    return DurakGameView(
      id: gameId,
      status: g.isOver ? 'finished' : 'active',
      lobbyId: '',
      chatId: null,
      mode: g.mode,
      deckSize: deckSize,
      playerIds: List.of(_playerIds),
      players: List.of(_players),
      hands: hands,
      deckCount: g.deck.length,
      trumpSuit: _suitLetter(g.trump),
      trumpCard: DurakApiCard.fromCard(trumpCard),
      table: [
        for (final p in g.table)
          DurakTablePairApi(
            attack: DurakApiCard.fromCard(p.attack),
            defense:
                p.defense == null ? null : DurakApiCard.fromCard(p.defense!),
          ),
      ],
      bitoCount: g.bito.length,
      attackerIndex: g.attackerIndex,
      defenderIndex: g.defenderIndex,
      phase: phase,
      myIndex: me,
      legalAttack: legalAttack,
      legalDefend: legalDefend,
      legalTransfer: legalTransfer,
      canThrowIn: canThrow,
      throwerIndex: g.throwerIndex,
      turnActorIdx: _turnActor(g, phase),
      loserIndex: g.loserIndex ?? -1,
      finished: List.of(g.finishedIndices),
      eliminated: const [],
      turnTimeSec: 0,
      turnDeadline: 0,
      stakeBronze: 0,
      isDraw: g.endedInDraw,
      isForfeit: false,
      isTimeout: false,
      drawOfferBy: '',
      lastWasTake: _lastWasTake,
      firstRound: g.firstRound,
      tiedLeaders: 0,
    );
  }

  static String _suitLetter(Suit s) => switch (s) {
        Suit.hearts => 'H',
        Suit.diamonds => 'D',
        Suit.clubs => 'C',
        Suit.spades => 'S',
      };

  static String _phaseOf(DurakTurn t) => switch (t) {
        DurakTurn.attacker => 'attack',
        DurakTurn.defender => 'defend',
        DurakTurn.throwIn => 'throw_in',
        DurakTurn.attackerFollowUp => 'attack_follow',
        DurakTurn.takeFollowUp => 'take_follow',
        DurakTurn.bitoReveal => 'bito_reveal',
        DurakTurn.takeReveal => 'take_reveal',
      };

  static int _turnActor(DurakGame g, String phase) {
    if (phase == 'bito_reveal' || phase == 'take_reveal') return -1;
    if (g.isOver) return -1;
    switch (phase) {
      case 'defend':
        return g.defenderIndex;
      case 'throw_in':
      case 'attack_follow':
      case 'take_follow':
        return g.throwerIndex;
      default:
        return g.attackerIndex;
    }
  }

  Future<void> applyMove({
    required String type,
    PlayingCard? card,
    List<PlayingCard>? cards,
    int? pairIndex,
  }) async {
    if (_disposed) return;
    if (_revealPhase != null) {
      throw GamesException(400, 'wait');
    }
    _dealGraceDone = true;
    try {
      switch (type) {
        case 'attack':
          final batch = (cards != null && cards.isNotEmpty)
              ? cards
              : (card != null ? [card] : <PlayingCard>[]);
          _game.attackMany(batch, playerIndex: me);
          _lastWasTake = false;
        case 'defend':
          if (card == null) {
            throw GamesException(400, 'card required');
          }
          _game.defend(card, playerIndex: me, pairIndex: pairIndex);
          _lastWasTake = false;
        case 'transfer':
          if (card == null) {
            throw GamesException(400, 'card required');
          }
          _game.transfer(card, playerIndex: me);
          _lastWasTake = false;
        case 'take':
          _game.take();
          _lastWasTake = true;
        case 'bito':
          _applyBito(me);
        case 'done':
          if (_game.turn == DurakTurn.throwIn) {
            _game.confirmThrowAll(playerIndex: me);
            _lastWasTake = false;
          } else {
            _applyConfirmTake(me);
          }
        case 'pass':
          throw GamesException(400, 'pass disabled');
        default:
          throw GamesException(400, 'unknown move $type');
      }
    } on DurakRuleError catch (e) {
      throw GamesException(400, e.message);
    }
    _handleEngineReveal();
    notifyListeners();
    if (_revealPhase == null) {
      _scheduleBot();
    }
  }

  void _applyBito(int player) {
    _game.sayBito(playerIndex: player);
    if (_game.turn == DurakTurn.bitoReveal) {
      _beginReveal('bito_reveal', wasTake: false);
    } else {
      _lastWasTake = false;
    }
  }

  void _applyConfirmTake(int player) {
    _game.confirmTake(playerIndex: player);
    if (_game.turn == DurakTurn.takeReveal) {
      _beginReveal('take_reveal', wasTake: true);
    } else {
      _lastWasTake = true;
    }
  }

  void _handleEngineReveal() {
    if (_game.turn == DurakTurn.bitoReveal) {
      _beginReveal('bito_reveal', wasTake: false);
    } else if (_game.turn == DurakTurn.takeReveal) {
      _beginReveal('take_reveal', wasTake: true);
    }
  }

  void _beginReveal(String phase, {required bool wasTake}) {
    if (_revealPhase != null) return;
    _revealPhase = phase;
    _lastWasTake = wasTake;
    _revealTimer?.cancel();
    final delay = wasTake ? takeRevealDelay : bitoRevealDelay;
    _revealTimer = Timer(delay, () {
      if (_disposed) return;
      try {
        _game.completeReveal();
      } catch (_) {}
      _revealPhase = null;
      notifyListeners();
      _scheduleBot();
    });
  }

  int? _actingBotIndex() {
    if (_game.isOver || _revealPhase != null) return null;
    if (_game.turn == DurakTurn.bitoReveal ||
        _game.turn == DurakTurn.takeReveal) {
      return null;
    }
    if (_game.turn == DurakTurn.defender) {
      if (_game.defenderIndex != me && _game.isAlive(_game.defenderIndex)) {
        return _game.defenderIndex;
      }
      if (_game.canThrowIn(_game.attackerIndex) &&
          _game.attackerIndex != me) {
        return _game.attackerIndex;
      }
      return null;
    }
    if (_game.turn == DurakTurn.attacker) {
      return _game.attackerIndex == me ? null : _game.attackerIndex;
    }
    if (_game.turn == DurakTurn.throwIn ||
        _game.turn == DurakTurn.attackerFollowUp ||
        _game.turn == DurakTurn.takeFollowUp) {
      return _game.throwerIndex == me ? null : _game.throwerIndex;
    }
    return null;
  }

  /// Экран крутит раздачу/биту/веер — боты ждут, как онлайн ждёт OpeningDealGrace.
  void setFxHold(bool hold) {
    if (_disposed) return;
    if (_fxHold == hold) return;
    _fxHold = hold;
    if (!hold) _scheduleBot();
  }

  /// Стартовая раздача на клиенте закончилась — можно пускать ботов.
  void markDealReady() {
    if (_disposed) return;
    _dealGraceDone = true;
    _scheduleBot();
  }

  @visibleForTesting
  bool get debugFxHold => _fxHold;

  @visibleForTesting
  bool get debugDealGraceDone => _dealGraceDone;

  @visibleForTesting
  bool get debugBotTimerActive => _botTimer?.isActive == true;

  void _scheduleBot() {
    _botTimer?.cancel();
    if (_disposed || _game.isOver || _revealPhase != null) return;
    if (!_dealGraceDone || _fxHold) return;
    final botIdx = _actingBotIndex();
    if (botIdx == null) return;
    _botTimer = Timer(botDelay, () {
      if (_disposed || _revealPhase != null) return;
      DurakBot? bot;
      for (final b in _bots) {
        if (b.index == botIdx) {
          bot = b;
          break;
        }
      }
      final acted = bot?.step(_game) ?? false;
      if (!acted) {
        if (_game.canConfirmThrowAll && _game.throwerIndex == botIdx) {
          _game.confirmThrowAll(playerIndex: botIdx);
        } else if (_game.canAttackerSayBito &&
            _game.throwerIndex == botIdx) {
          _applyBito(botIdx);
        } else if (_game.canAttackerConfirmTake &&
            _game.throwerIndex == botIdx) {
          _applyConfirmTake(botIdx);
        }
      } else {
        // Bot may have called take/bito/confirm via engine — sync reveal.
        if (_game.turn == DurakTurn.bitoReveal) {
          _beginReveal('bito_reveal', wasTake: false);
        } else if (_game.turn == DurakTurn.takeReveal) {
          _beginReveal('take_reveal', wasTake: true);
        } else if (_game.turn == DurakTurn.takeFollowUp) {
          _lastWasTake = true;
        }
      }
      _handleEngineReveal();
      notifyListeners();
      if (_revealPhase == null) {
        _scheduleBot();
      }
    });
  }

  Future<void> forfeit() async {
    if (_disposed || _game.isOver) return;
    _botTimer?.cancel();
    _revealTimer?.cancel();
    _revealPhase = null;
    // Человек сдаётся — он «дурак».
    _game.loserIndex = me;
    _game.endedInDraw = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _botTimer?.cancel();
    _revealTimer?.cancel();
    OfflineDurakRegistry.instance.remove(gameId);
    super.dispose();
  }

  /// Стартовать ботов после анимации раздачи (как OpeningDealGrace онлайн).
  void ensureStarted() {
    if (_dealGraceDone) {
      _scheduleBot();
      return;
    }
    if (_botTimer?.isActive == true) return;
    _botTimer = Timer(openingDealGrace(playerCount), () {
      if (_disposed) return;
      _dealGraceDone = true;
      _scheduleBot();
    });
  }
}

/// Глобальный реестр офлайн-партий Дурака (без Riverpod в repository).
class OfflineDurakRegistry {
  OfflineDurakRegistry._();
  static final OfflineDurakRegistry instance = OfflineDurakRegistry._();

  final Map<String, OfflineDurakSession> _sessions = {};

  void put(OfflineDurakSession s) => _sessions[s.gameId] = s;

  OfflineDurakSession? get(String gameId) => _sessions[gameId];

  void remove(String gameId) => _sessions.remove(gameId);

  bool isOffline(String gameId) => gameId.startsWith('offline:durak:');
}
