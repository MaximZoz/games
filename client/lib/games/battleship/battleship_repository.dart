import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException, LobbyPlayer;

/// Результат создания лобби / мгновенного матча.
class BattleshipCreateResult {
  const BattleshipCreateResult({
    required this.lobbyId,
    this.gameId,
    this.joined = false,
  });

  final String lobbyId;
  final String? gameId;
  final bool joined;
}

/// View лобби battleship (совместим с общим GetLobby).
class BattleshipLobbyView {
  const BattleshipLobbyView({
    required this.id,
    required this.status,
    required this.mode,
    required this.creatorId,
    required this.playerIds,
    required this.players,
    required this.turnTimeSec,
    required this.stakeBronze,
    this.gameId,
    this.firstMoveRestriction = false,
  });

  final String id;
  final String status;
  final String mode;
  final String creatorId;
  final List<String> playerIds;
  final List<LobbyPlayer> players;
  final int turnTimeSec;
  final int stakeBronze;
  final String? gameId;
  final bool firstMoveRestriction;

  factory BattleshipLobbyView.fromJson(Map<String, dynamic> json) {
    final playersRaw = json['players'];
    final players = playersRaw is List
        ? playersRaw
            .whereType<Map>()
            .map((e) => LobbyPlayer.fromJson(e.cast<String, dynamic>()))
            .toList()
        : <LobbyPlayer>[];
    final ids = (json['player_ids'] is List)
        ? (json['player_ids'] as List).map((e) => e.toString()).toList()
        : players.map((p) => p.id).toList();
    return BattleshipLobbyView(
      id: (json['lobby_id'] ?? json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      mode: (json['mode'] ?? 'invite').toString(),
      creatorId: (json['creator_id'] ?? '').toString(),
      playerIds: ids,
      players: players,
      turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
      stakeBronze: (json['stake_bronze'] as num?)?.toInt() ?? 2,
      gameId: (json['game_id'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['game_id'] as String).trim(),
      firstMoveRestriction: json['first_move_restriction'] == true,
    );
  }
}

/// Состояние партии Морского боя.
class BattleshipGameView {
  const BattleshipGameView({
    required this.id,
    required this.status,
    required this.phase,
    required this.lobbyId,
    required this.p1UserId,
    required this.p2UserId,
    required this.p1Ready,
    required this.p2Ready,
    required this.myShips,
    required this.myShots,
    required this.opponentShots,
    required this.opponentShipsHit,
    required this.isMyTurn,
    required this.turn,
    required this.turnTimeSec,
    required this.turnDeadline,
    required this.setupDeadline,
    required this.stakeBronze,
    this.winner,
    this.forfeit = false,
    this.lastShot = -1,
    this.p1DisplayName,
    this.p2DisplayName,
    this.p1AvatarKind = 'letter',
    this.p2AvatarKind = 'letter',
    this.p1AvatarValue,
    this.p2AvatarValue,
  });

  final String id;
  final String status; // active | over
  final String phase; // setup | battle
  final String lobbyId;
  final String p1UserId;
  final String p2UserId;
  final bool p1Ready;
  final bool p2Ready;
  final List<List<int>> myShips;
  final List<int> myShots;
  final List<int> opponentShots;
  final List<int> opponentShipsHit;
  final bool isMyTurn;
  final String turn;
  final int turnTimeSec;
  final int turnDeadline;
  final int setupDeadline;
  final int stakeBronze;
  final String? winner;
  final bool forfeit;
  final int lastShot;
  final String? p1DisplayName;
  final String? p2DisplayName;
  final String p1AvatarKind;
  final String p2AvatarKind;
  final String? p1AvatarValue;
  final String? p2AvatarValue;

  bool get isOver => status == 'over';
  bool get isSetup => phase == 'setup';
  bool get isBattle => phase == 'battle';

  factory BattleshipGameView.fromJson(Map<String, dynamic> json) {
    List<List<int>> parseShips(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<List>()
          .map((s) => s.map((e) => (e as num).toInt()).toList())
          .toList();
    }

    List<int> parseInts(dynamic raw) {
      if (raw is! List) return const [];
      return raw.map((e) => (e as num).toInt()).toList();
    }

    return BattleshipGameView(
      id: (json['game_id'] ?? json['id'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      phase: (json['phase'] ?? 'setup').toString(),
      lobbyId: (json['lobby_id'] ?? '').toString(),
      p1UserId: (json['p1_user_id'] ?? '').toString(),
      p2UserId: (json['p2_user_id'] ?? '').toString(),
      p1Ready: json['p1_ready'] == true,
      p2Ready: json['p2_ready'] == true,
      myShips: parseShips(json['my_ships']),
      myShots: parseInts(json['my_shots']),
      opponentShots: parseInts(json['opponent_shots']),
      opponentShipsHit: parseInts(json['opponent_ships_hit']),
      isMyTurn: json['is_my_turn'] == true,
      turn: (json['turn'] ?? '').toString(),
      turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
      turnDeadline: (json['turn_deadline'] as num?)?.toInt() ?? 0,
      setupDeadline: (json['setup_deadline'] as num?)?.toInt() ?? 0,
      stakeBronze: (json['stake_bronze'] as num?)?.toInt() ?? 2,
      winner: (json['winner'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['winner'] as String).trim(),
      forfeit: json['forfeit'] == true,
      lastShot: (json['last_shot'] as num?)?.toInt() ?? -1,
      p1DisplayName: (json['p1_display_name'] as String?)?.trim(),
      p2DisplayName: (json['p2_display_name'] as String?)?.trim(),
      p1AvatarKind: (json['p1_avatar_kind'] ?? 'letter').toString(),
      p2AvatarKind: (json['p2_avatar_kind'] ?? 'letter').toString(),
      p1AvatarValue: json['p1_avatar_value']?.toString(),
      p2AvatarValue: json['p2_avatar_value']?.toString(),
    );
  }
}

class BattleshipRepository {
  BattleshipRepository({required AuthRepository authRepository})
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

  Future<BattleshipCreateResult> createLobby({
    required String mode,
    required int turnTimeSec,
    required int stakeBronze,
    bool firstMoveRestriction = false,
    bool addBotsAfter30s = false,
  }) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/battleship/lobby'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'mode': mode,
          'turn_time_sec': turnTimeSec,
          'stake_bronze': stakeBronze,
          'first_move_restriction': firstMoveRestriction,
          'add_bots_after_30s': addBotsAfter30s,
        }),
        operation: 'BattleshipRepository.createLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return BattleshipCreateResult(
      lobbyId: (j['lobby_id'] ?? '').toString(),
      gameId: (j['game_id'] as String?)?.trim().isEmpty ?? true
          ? null
          : (j['game_id'] as String).trim(),
      joined: j['joined'] == true,
    );
  }

  Future<List<BattleshipLobbyView>> listLobbies() async {
    final res = await _sendAuth(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/games/battleship/lobbies'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'BattleshipRepository.listLobbies',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final list = j['lobbies'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => BattleshipLobbyView.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<BattleshipLobbyView> getLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/games/battleship/lobby/$lobbyId'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'BattleshipRepository.getLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    j.putIfAbsent('lobby_id', () => lobbyId);
    j.putIfAbsent('id', () => lobbyId);
    return BattleshipLobbyView.fromJson(j);
  }

  Future<BattleshipCreateResult> joinLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/battleship/lobby/$lobbyId/join'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'BattleshipRepository.joinLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return BattleshipCreateResult(
      lobbyId: (j['lobby_id'] ?? lobbyId).toString(),
      gameId: (j['game_id'] as String?)?.trim().isEmpty ?? true
          ? null
          : (j['game_id'] as String).trim(),
      joined: true,
    );
  }

  Future<void> leaveLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/battleship/lobby/$lobbyId/leave'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'BattleshipRepository.leaveLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> inviteFriend(String lobbyId, String friendUserId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/battleship/lobby/$lobbyId/invite'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'friend_user_id': friendUserId}),
        operation: 'BattleshipRepository.inviteFriend',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> declineLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/battleship/lobby/$lobbyId/decline'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'BattleshipRepository.declineLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> cancelInvite(String lobbyId, String friendUserId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse(
          '$apiBaseUrl/api/games/battleship/lobby/$lobbyId/cancel-invite',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'friend_user_id': friendUserId}),
        operation: 'BattleshipRepository.cancelInvite',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<BattleshipGameView> getGame(String gameId) async {
    final res = await _sendAuth(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/games/battleship/game/$gameId'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'BattleshipRepository.getGame',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    return BattleshipGameView.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<BattleshipGameView> placeShips(
    String gameId,
    List<List<int>> ships,
  ) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/battleship/game/$gameId/place_ships'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'ships': ships}),
        operation: 'BattleshipRepository.placeShips',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    return BattleshipGameView.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<BattleshipGameView> shoot(String gameId, int cell) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/battleship/game/$gameId/shoot'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'cell': cell}),
        operation: 'BattleshipRepository.shoot',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    return BattleshipGameView.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<BattleshipGameView> forfeit(String gameId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/battleship/game/$gameId/forfeit'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'BattleshipRepository.forfeit',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    return BattleshipGameView.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<String> rematch(String gameId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/battleship/rematch'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'game_id': gameId}),
        operation: 'BattleshipRepository.rematch',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (j['lobby_id'] ?? '').toString();
  }
}
