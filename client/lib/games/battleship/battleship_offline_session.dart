import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:multigames_client/games/battleship/battleship_repository.dart';
import 'package:multigames_client/games/battleship/battleship_utils.dart';
import 'package:multigames_client/games/games_repository.dart' show GamesException;

const String kBattleshipOfflineBotId = 'bot:battleship';

/// Попадание в клетку среди кораблей.
bool battleshipIsHit(List<List<int>> ships, int cell) {
  for (final ship in ships) {
    if (ship.contains(cell)) return true;
  }
  return false;
}

/// Все корабли потоплены данными выстрелами.
bool battleshipAllSunk(List<List<int>> ships, List<int> shots) {
  if (ships.isEmpty) return false;
  final hit = shots.toSet();
  for (final ship in ships) {
    for (final c in ship) {
      if (!hit.contains(c)) return false;
    }
  }
  return true;
}

/// Полностью потопленные корабли.
List<List<int>> battleshipCollectSunkShips(
  List<List<int>> ships,
  List<int> shots,
) {
  final hit = shots.toSet();
  return [
    for (final ship in ships)
      if (ship.every(hit.contains)) List<int>.from(ship),
  ];
}

/// Клетки выстрелов, попавшие в корабли.
List<int> battleshipCollectHitCells(
  List<List<int>> ships,
  List<int> shots,
) {
  final out = <int>[
    for (final c in shots)
      if (battleshipIsHit(ships, c)) c,
  ]..sort();
  return out;
}

/// Соседи попаданий (ортогонально), ещё не обстрелянные — как на сервере.
List<int> battleshipBotNeighborCandidates(
  List<List<int>> ships,
  List<int> shots,
) {
  final hitSet = shots.toSet();
  final seen = <int>{};
  final out = <int>[];
  for (final cell in shots) {
    if (!battleshipIsHit(ships, cell)) continue;
    final r = cell ~/ kBattleshipBoardSize;
    final c = cell % kBattleshipBoardSize;
    for (final d in const [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ]) {
      final rr = r + d[0];
      final cc = c + d[1];
      if (rr < 0 ||
          rr >= kBattleshipBoardSize ||
          cc < 0 ||
          cc >= kBattleshipBoardSize) {
        continue;
      }
      final n = rr * kBattleshipBoardSize + cc;
      if (hitSet.contains(n) || !seen.add(n)) continue;
      out.add(n);
    }
  }
  out.sort();
  return out;
}

/// Выбор выстрела бота: соседи попаданий, иначе случайная свободная клетка.
int battleshipBotPickShot(
  List<List<int>> ships,
  List<int> shots,
  Random rng,
) {
  final cands = battleshipBotNeighborCandidates(ships, shots);
  if (cands.isNotEmpty) {
    return cands[rng.nextInt(cands.length)];
  }
  final hitSet = shots.toSet();
  final free = <int>[
    for (var i = 0; i < kBattleshipCellCount; i++)
      if (!hitSet.contains(i)) i,
  ];
  if (free.isEmpty) {
    throw GamesException(400, 'no cells left');
  }
  return free[rng.nextInt(free.length)];
}

/// Локальная партия Морского боя с ботом — тот же [BattleshipGameView], что онлайн.
class OfflineBattleshipSession extends ChangeNotifier {
  OfflineBattleshipSession._({
    required this.gameId,
    required this.humanUserId,
  }) {
    _startFresh();
  }

  final String gameId;
  final String humanUserId;

  static const Duration botDelay = Duration(milliseconds: 700);
  static const Duration botHitContinueDelay = Duration(milliseconds: 1100);

  final Random _rng = Random();
  Timer? _botTimer;
  bool _disposed = false;

  late String _status; // active | over
  late String _phase; // setup | battle
  late List<List<int>> _humanShips;
  late List<List<int>> _botShips;
  late bool _humanReady;
  late bool _botReady;
  late List<int> _humanShots;
  late List<int> _botShots;
  late String _turn; // user id
  String? _winner;
  bool _forfeit = false;
  int _lastShot = -1;
  bool _lastShotHit = false;
  String? _lastShotBy;

  static String newGameId() =>
      'offline:battleship:${DateTime.now().microsecondsSinceEpoch}';

  factory OfflineBattleshipSession.create({
    required String humanUserId,
    String? gameId,
  }) {
    final id = gameId ?? newGameId();
    final session = OfflineBattleshipSession._(
      gameId: id,
      humanUserId: humanUserId.trim().isEmpty ? 'local:player' : humanUserId,
    );
    OfflineBattleshipRegistry.instance.put(session);
    return session;
  }

  void _startFresh() {
    _botTimer?.cancel();
    _status = 'active';
    _phase = 'setup';
    _humanShips = const [];
    _botShips = generateRandomBattleshipShips();
    _humanReady = false;
    _botReady = true;
    _humanShots = [];
    _botShots = [];
    _turn = '';
    _winner = null;
    _forfeit = false;
    _lastShot = -1;
    _lastShotHit = false;
    _lastShotBy = null;
  }

  void restart() {
    _startFresh();
    notifyListeners();
  }

  BattleshipGameView get view => toView();

  BattleshipGameView toView() {
    const p2 = kBattleshipOfflineBotId;
    final myShips = _humanReady || _phase != 'setup'
        ? _humanShips.map((s) => List<int>.from(s)).toList()
        : const <List<int>>[];
    final myShots = List<int>.from(_humanShots);
    final oppShots = List<int>.from(_botShots);
    final myHits = battleshipCollectHitCells(_botShips, _humanShots);
    final oppHit = battleshipCollectHitCells(_humanShips, _botShots);
    final oppSunk = battleshipCollectSunkShips(_botShips, _humanShots);
    final showOppFleet = _status == 'over'
        ? _botShips.map((s) => List<int>.from(s)).toList()
        : const <List<int>>[];
    final isMyTurn =
        _phase == 'battle' && _status == 'active' && _turn == humanUserId;

    return BattleshipGameView(
      id: gameId,
      status: _status,
      phase: _phase,
      lobbyId: '',
      p1UserId: humanUserId,
      p2UserId: p2,
      p1Ready: _humanReady,
      p2Ready: _botReady,
      myShips: myShips,
      myShots: myShots,
      myHits: myHits,
      opponentShots: oppShots,
      opponentShipsHit: oppHit,
      opponentSunkShips: oppSunk,
      opponentShips: showOppFleet,
      isMyTurn: isMyTurn,
      turn: _turn,
      turnTimeSec: 0,
      turnDeadline: 0,
      setupDeadline: 0,
      stakeBronze: 0,
      winner: _winner,
      forfeit: _forfeit,
      draw: false,
      lastShot: _lastShot,
      lastShotHit: _lastShotHit,
      lastShotBy: _lastShotBy,
      p1DisplayName: null,
      p2DisplayName: 'Bot',
      p1AvatarKind: 'letter',
      p2AvatarKind: 'letter',
      p2AvatarValue: 'B',
    );
  }

  void _beginBattle() {
    _phase = 'battle';
    // Как онлайн: случайный первый ход.
    _turn = _rng.nextBool() ? humanUserId : kBattleshipOfflineBotId;
    if (_turn == kBattleshipOfflineBotId) {
      _scheduleBot();
    }
  }

  Future<BattleshipGameView> placeShips(List<List<int>> ships) async {
    if (_disposed) throw GamesException(404, 'offline game not found');
    if (_status != 'active' || _phase != 'setup') {
      throw GamesException(400, 'not in setup');
    }
    if (_humanReady) {
      throw GamesException(400, 'already ready');
    }
    if (!validateBattleshipShips(ships)) {
      throw GamesException(400, 'invalid ships');
    }
    _humanShips = ships.map((s) => List<int>.from(s)).toList();
    _humanReady = true;
    if (_botReady) {
      _beginBattle();
    }
    notifyListeners();
    return view;
  }

  Future<BattleshipGameView> shoot(int cell) async {
    if (_disposed) throw GamesException(404, 'offline game not found');
    if (_status != 'active' || _phase != 'battle') {
      throw GamesException(400, 'not in battle');
    }
    if (_turn != humanUserId) {
      throw GamesException(400, 'not your turn');
    }
    if (cell < 0 || cell >= kBattleshipCellCount) {
      throw GamesException(400, 'invalid cell');
    }
    if (_humanShots.contains(cell)) {
      throw GamesException(400, 'already shot');
    }
    _applyShot(
      shooter: humanUserId,
      targetShips: _botShips,
      shots: _humanShots,
      cell: cell,
    );
    notifyListeners();
    if (_status == 'active' && _turn == kBattleshipOfflineBotId) {
      _scheduleBot();
    }
    return view;
  }

  void _applyShot({
    required String shooter,
    required List<List<int>> targetShips,
    required List<int> shots,
    required int cell,
  }) {
    shots.add(cell);
    final hit = battleshipIsHit(targetShips, cell);
    _lastShot = cell;
    _lastShotHit = hit;
    _lastShotBy = shooter;
    if (battleshipAllSunk(targetShips, shots)) {
      _status = 'over';
      _winner = shooter;
      _turn = '';
      _botTimer?.cancel();
      return;
    }
    if (hit) {
      // Попадание — ещё один ход того же игрока.
      _turn = shooter;
    } else {
      _turn = shooter == humanUserId
          ? kBattleshipOfflineBotId
          : humanUserId;
    }
  }

  void _scheduleBot() {
    _botTimer?.cancel();
    if (_disposed || _status != 'active' || _phase != 'battle') return;
    if (_turn != kBattleshipOfflineBotId) return;
    final delay = _lastShotBy == kBattleshipOfflineBotId && _lastShotHit
        ? botHitContinueDelay
        : botDelay;
    _botTimer = Timer(delay, () {
      if (_disposed || _status != 'active') return;
      if (_turn != kBattleshipOfflineBotId) return;
      try {
        final cell = battleshipBotPickShot(_humanShips, _botShots, _rng);
        _applyShot(
          shooter: kBattleshipOfflineBotId,
          targetShips: _humanShips,
          shots: _botShots,
          cell: cell,
        );
      } catch (_) {
        return;
      }
      notifyListeners();
      if (_status == 'active' && _turn == kBattleshipOfflineBotId) {
        _scheduleBot();
      }
    });
  }

  Future<BattleshipGameView> forfeit() async {
    if (_disposed) throw GamesException(404, 'offline game not found');
    if (_status == 'over') return view;
    _botTimer?.cancel();
    _status = 'over';
    _forfeit = true;
    _winner = kBattleshipOfflineBotId;
    _turn = '';
    notifyListeners();
    return view;
  }

  @override
  void dispose() {
    _disposed = true;
    _botTimer?.cancel();
    OfflineBattleshipRegistry.instance.remove(gameId);
    super.dispose();
  }
}

/// Глобальный реестр офлайн-партий Морского боя.
class OfflineBattleshipRegistry {
  OfflineBattleshipRegistry._();
  static final OfflineBattleshipRegistry instance = OfflineBattleshipRegistry._();

  final Map<String, OfflineBattleshipSession> _sessions = {};

  void put(OfflineBattleshipSession s) => _sessions[s.gameId] = s;

  OfflineBattleshipSession? get(String gameId) => _sessions[gameId];

  void remove(String gameId) => _sessions.remove(gameId);

  bool isOffline(String gameId) => gameId.startsWith('offline:battleship:');
}
