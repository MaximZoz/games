import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException, LobbyPlayer;
import 'package:multigames_client/games/nardy/nardy_engine.dart';
import 'package:multigames_client/games/nardy/nardy_offline_session.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';

/// Результат создания лобби / мгновенного матча.
class NardyCreateResult {
  const NardyCreateResult({
    required this.lobbyId,
    this.gameId,
    this.joined = false,
  });

  final String lobbyId;
  final String? gameId;
  final bool joined;
}

/// Лобби нард (совместимо с общим GetLobby).
class NardyLobbyView {
  const NardyLobbyView({
    required this.id,
    required this.status,
    required this.mode,
    required this.gameMode,
    required this.creatorId,
    required this.playerIds,
    required this.players,
    required this.turnTimeSec,
    required this.stakeBronze,
    this.gameId,
  });

  final String id;
  final String status;
  final String mode;
  final String gameMode;
  final String creatorId;
  final List<String> playerIds;
  final List<LobbyPlayer> players;
  final int turnTimeSec;
  final int stakeBronze;
  final String? gameId;

  factory NardyLobbyView.fromJson(Map<String, dynamic> json) {
    final playersRaw = json['players'];
    final players = playersRaw is List
        ? playersRaw
            .whereType<Map>()
            .map((e) => LobbyPlayer.fromJson(e.cast<String, dynamic>()))
            .toList()
        : <LobbyPlayer>[];
    final ids = json['player_ids'] is List
        ? (json['player_ids'] as List).map((e) => e.toString()).toList()
        : players.map((p) => p.id).toList();
    final gameId = (json['game_id'] ?? '').toString().trim();
    return NardyLobbyView(
      id: (json['lobby_id'] ?? json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      mode: (json['mode'] ?? 'invite').toString(),
      gameMode: nardyNormalizeMode(json['game_mode']?.toString()),
      creatorId: (json['creator_id'] ?? '').toString(),
      playerIds: ids,
      players: players,
      turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
      stakeBronze: (json['stake_bronze'] as num?)?.toInt() ?? 2,
      gameId: gameId.isEmpty ? null : gameId,
    );
  }
}

/// Одно место за доской.
class NardyPlayerView {
  const NardyPlayerView({
    required this.userId,
    required this.seat,
    required this.displayName,
    required this.off,
    required this.bar,
    required this.pips,
    this.isBot = false,
    this.avatarKind = 'letter',
    this.avatarValue,
    this.frameCode,
    this.frameColor,
  });

  final String userId;
  final int seat;
  final String displayName;
  final int off;
  final int bar;
  final int pips;
  final bool isBot;
  final String avatarKind;
  final String? avatarValue;
  final String? frameCode;
  final String? frameColor;

  factory NardyPlayerView.fromJson(Map<String, dynamic> json) {
    final id = (json['user_id'] ?? '').toString();
    return NardyPlayerView(
      userId: id,
      seat: (json['seat'] as num?)?.toInt() ?? 0,
      displayName: (json['display_name'] ?? '').toString(),
      off: (json['off'] as num?)?.toInt() ?? 0,
      bar: (json['bar'] as num?)?.toInt() ?? 0,
      pips: (json['pips'] as num?)?.toInt() ?? 0,
      isBot: json['is_bot'] == true || id.startsWith('bot:'),
      avatarKind: (json['avatar_kind'] ?? 'letter').toString(),
      avatarValue: json['avatar_value']?.toString(),
      frameCode: json['frame_code']?.toString(),
      frameColor: json['frame_color']?.toString(),
    );
  }
}

/// Состояние партии нард глазами игрока.
class NardyGameView {
  const NardyGameView({
    required this.id,
    required this.lobbyId,
    required this.gameMode,
    required this.board,
    required this.bar,
    required this.off,
    required this.dice,
    required this.rolled,
    required this.turn,
    required this.turnNo,
    required this.headMoved,
    required this.players,
    required this.playerIds,
    required this.legalMoves,
    required this.myIndex,
    required this.isMyTurn,
    required this.needsRoll,
    required this.turnTimeSec,
    required this.turnDeadline,
    required this.stakeBronze,
    required this.isOver,
    required this.winnerIndex,
    required this.winnerUserId,
    required this.winKind,
    this.isForfeit = false,
    this.isTimeout = false,
  });

  final String id;
  final String lobbyId;
  final String gameMode;

  /// Физические пункты: >0 — шашки места 0, <0 — шашки места 1.
  final List<int> board;
  final List<int> bar;
  final List<int> off;
  final List<int> dice;
  final List<int> rolled;
  final int turn;
  final int turnNo;
  final int headMoved;
  final List<NardyPlayerView> players;
  final List<String> playerIds;
  final List<NardyMove> legalMoves;
  final int myIndex;
  final bool isMyTurn;
  final bool needsRoll;
  final int turnTimeSec;
  final int turnDeadline;
  final int stakeBronze;
  final bool isOver;
  final int winnerIndex;
  final String winnerUserId;
  final String winKind;
  final bool isForfeit;
  final bool isTimeout;

  bool get isLong => nardyNormalizeMode(gameMode) == nardyModeLong;
  int get opponentIndex => myIndex == 0 ? 1 : 0;
  bool get iWon => isOver && myIndex >= 0 && winnerIndex == myIndex;
  bool get isMars => winKind == 'mars';

  bool get hasBotOpponent => playerIds.any((id) => id.startsWith('bot:'));

  NardyPlayerView? get me =>
      myIndex >= 0 && myIndex < players.length ? players[myIndex] : null;

  NardyPlayerView? get opponent {
    final index = opponentIndex;
    if (index < 0 || index >= players.length) return null;
    return players[index];
  }

  bool isTurnOf(String? userId) {
    if (userId == null || userId.isEmpty || isOver) return false;
    if (turn < 0 || turn >= playerIds.length) return false;
    return playerIds[turn] == userId;
  }

  /// Мои шашки на пункте моей дорожки.
  int myCountAt(int track) => _countFor(myIndex, track);

  /// Шашки соперника на пункте моей дорожки.
  int opponentCountAt(int track) => _countFor(opponentIndex, track);

  int _countFor(int seat, int track) {
    if (seat < 0) return 0;
    final p = nardyTrackToBoard(gameMode, seat, track);
    if (p < 0 || p >= board.length) return 0;
    final v = board[p];
    if (seat == 0) return v > 0 ? v : 0;
    return v < 0 ? -v : 0;
  }

  /// Кубики, которыми можно пойти с этого пункта дорожки.
  List<int> diceFrom(int track) => [
        for (final mv in legalMoves)
          if (mv.from == track) mv.die,
      ];

  /// Пункты дорожки, откуда можно сходить.
  Set<int> get movableTracks => {for (final mv in legalMoves) mv.from};

  factory NardyGameView.fromJson(Map<String, dynamic> json) {
    List<int> parseInts(dynamic raw) {
      if (raw is! List) return const [];
      return raw.map((e) => (e as num).toInt()).toList();
    }

    final rawBoard = parseInts(json['board']);
    final board = rawBoard.length == nardyPoints
        ? rawBoard
        : List<int>.filled(nardyPoints, 0);
    final playersRaw = json['players'];
    final players = playersRaw is List
        ? playersRaw
            .whereType<Map>()
            .map((e) => NardyPlayerView.fromJson(e.cast<String, dynamic>()))
            .toList()
        : <NardyPlayerView>[];
    final movesRaw = json['legal_moves'];
    final moves = movesRaw is List
        ? movesRaw
            .whereType<Map>()
            .map((e) => NardyMove(
                  (e['from'] as num?)?.toInt() ?? 0,
                  (e['die'] as num?)?.toInt() ?? 0,
                ))
            .toList()
        : <NardyMove>[];
    final bar = parseInts(json['bar']);
    final off = parseInts(json['off']);
    return NardyGameView(
      id: (json['game_id'] ?? json['id'] ?? '').toString(),
      lobbyId: (json['lobby_id'] ?? '').toString(),
      gameMode: nardyNormalizeMode(json['game_mode']?.toString()),
      board: board,
      bar: bar.length == 2 ? bar : const [0, 0],
      off: off.length == 2 ? off : const [0, 0],
      dice: parseInts(json['dice']),
      rolled: parseInts(json['rolled']),
      turn: (json['turn'] as num?)?.toInt() ?? 0,
      turnNo: (json['turn_no'] as num?)?.toInt() ?? 0,
      headMoved: (json['head_moved'] as num?)?.toInt() ?? 0,
      players: players,
      playerIds: json['player_ids'] is List
          ? (json['player_ids'] as List).map((e) => e.toString()).toList()
          : players.map((p) => p.userId).toList(),
      legalMoves: moves,
      myIndex: (json['my_index'] as num?)?.toInt() ?? -1,
      isMyTurn: json['is_my_turn'] == true,
      needsRoll: json['needs_roll'] == true,
      turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
      turnDeadline: (json['turn_deadline'] as num?)?.toInt() ?? 0,
      stakeBronze: (json['stake_bronze'] as num?)?.toInt() ?? 2,
      isOver: json['is_over'] == true,
      winnerIndex: (json['winner_index'] as num?)?.toInt() ?? -1,
      winnerUserId: (json['winner_user_id'] ?? '').toString(),
      winKind: (json['win_kind'] ?? '').toString(),
      isForfeit: json['is_forfeit'] == true,
      isTimeout: json['is_timeout'] == true,
    );
  }
}

class NardyRepository {
  NardyRepository({required AuthRepository authRepository})
      : _auth = authRepository;

  final AuthRepository _auth;

  Future<http.Response> _sendAuth(
    Future<http.Response> Function(String token) fn,
  ) async {
    try {
      return await _auth.sendAuthorized(fn);
    } on AuthException catch (e) {
      throw GamesException(
        e.statusCode,
        e.statusCode == 401 ? LocaleService.l10n.sessionExpired : e.message,
      );
    }
  }

  Never _fail(http.Response r) {
    var msg = r.body.trim();
    var key = '';
    try {
      final body = jsonDecode(r.body);
      if (body is Map) {
        key = (body['error'] ?? body['code'] ?? '').toString();
        msg = (body['message'] ?? body['error'] ?? msg).toString();
      }
    } catch (_) {}
    if (msg.isEmpty) msg = LocaleService.l10n.commonServerErrorShort;
    throw GamesException(r.statusCode, msg, errorKey: key);
  }

  Future<NardyCreateResult> createLobby({
    required String mode,
    required String gameMode,
    required int turnTimeSec,
    required int stakeBronze,
    bool vsBot = false,
  }) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/nardy/lobby'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'mode': mode,
          'game_mode': nardyNormalizeMode(gameMode),
          'turn_time_sec': turnTimeSec,
          'stake_bronze': stakeBronze,
          'vs_bot': vsBot,
        }),
        operation: 'NardyRepository.createLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final gameId = (j['game_id'] ?? '').toString().trim();
    return NardyCreateResult(
      lobbyId: (j['lobby_id'] ?? '').toString(),
      gameId: gameId.isEmpty ? null : gameId,
      joined: j['joined'] == true,
    );
  }

  Future<List<NardyLobbyView>> listLobbies() async {
    final res = await _sendAuth(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/games/nardy/lobbies'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'NardyRepository.listLobbies',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final list = j['lobbies'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => NardyLobbyView.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<NardyLobbyView> getLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/games/nardy/lobby/$lobbyId'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'NardyRepository.getLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    j.putIfAbsent('lobby_id', () => lobbyId);
    j.putIfAbsent('id', () => lobbyId);
    return NardyLobbyView.fromJson(j);
  }

  Future<NardyCreateResult> joinLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/nardy/lobby/$lobbyId/join'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'NardyRepository.joinLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final gameId = (j['game_id'] ?? '').toString().trim();
    return NardyCreateResult(
      lobbyId: (j['lobby_id'] ?? lobbyId).toString(),
      gameId: gameId.isEmpty ? null : gameId,
      joined: true,
    );
  }

  Future<void> leaveLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/nardy/lobby/$lobbyId/leave'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'NardyRepository.leaveLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> inviteFriend(String lobbyId, String friendUserId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/nardy/lobby/$lobbyId/invite'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'friend_user_id': friendUserId}),
        operation: 'NardyRepository.inviteFriend',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> declineLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/nardy/lobby/$lobbyId/decline'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'NardyRepository.declineLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> cancelInvite(String lobbyId, String friendUserId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/nardy/lobby/$lobbyId/cancel-invite'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'friend_user_id': friendUserId}),
        operation: 'NardyRepository.cancelInvite',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<NardyGameView> getGame(String gameId) async {
    final offline = OfflineNardyRegistry.instance.get(gameId);
    if (offline != null) return offline.view;
    if (OfflineNardyRegistry.instance.isOffline(gameId)) {
      throw GamesException(404, 'offline game not found');
    }
    final res = await _sendAuth(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/games/nardy/game/$gameId'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'NardyRepository.getGame',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    return NardyGameView.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<void> roll(String gameId) => _move(gameId, {'action': 'roll'});

  Future<void> move(String gameId, NardyMove mv) => _move(gameId, {
        'action': 'move',
        'from': mv.from,
        'die': mv.die,
      });

  Future<void> endTurn(String gameId) => _move(gameId, {'action': 'end_turn'});

  Future<void> _move(String gameId, Map<String, dynamic> body) async {
    if (OfflineNardyRegistry.instance.isOffline(gameId)) {
      final session = OfflineNardyRegistry.instance.get(gameId);
      if (session == null) throw GamesException(404, 'offline game not found');
      session.applyLocalAction(body);
      return;
    }
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/nardy/game/$gameId/move'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
        operation: 'NardyRepository.move',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> forfeit(String gameId) async {
    if (OfflineNardyRegistry.instance.isOffline(gameId)) {
      final session = OfflineNardyRegistry.instance.get(gameId);
      if (session == null) throw GamesException(404, 'offline game not found');
      session.forfeit();
      return;
    }
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/nardy/game/$gameId/forfeit'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'NardyRepository.forfeit',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<String> rematch(String gameId) async {
    if (OfflineNardyRegistry.instance.isOffline(gameId)) {
      OfflineNardyRegistry.instance.get(gameId)?.restart();
      return '';
    }
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/nardy/rematch'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'game_id': gameId}),
        operation: 'NardyRepository.rematch',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (j['lobby_id'] ?? '').toString();
  }
}
