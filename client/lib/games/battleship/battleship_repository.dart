import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/battleship/battleship_offline_session.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException, LobbyPlayer, parseLobbyInvited;

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
    this.invited = const [],
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

  /// Кому уже ушло приглашение и кто ещё не вошёл — виден даже не-друг.
  final List<LobbyPlayer> invited;
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
      invited: parseLobbyInvited(json['invited']),
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
    required this.myHits,
    required this.opponentShots,
    required this.opponentShipsHit,
    required this.opponentSunkShips,
    required this.opponentShips,
    required this.isMyTurn,
    required this.turn,
    required this.turnTimeSec,
    required this.turnDeadline,
    required this.setupDeadline,
    this.setupSecondsLeft = 0,
    required this.stakeBronze,
    this.winner,
    this.forfeit = false,
    this.draw = false,
    this.drawOfferBy,
    this.lastShot = -1,
    this.lastShotHit = false,
    this.lastShotBy,
    this.p1DisplayName,
    this.p2DisplayName,
    this.p1AvatarKind = 'letter',
    this.p2AvatarKind = 'letter',
    this.p1AvatarValue,
    this.p2AvatarValue,
    this.p1FrameCode,
    this.p2FrameCode,
    this.p1FrameColor,
    this.p2FrameColor,
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
  /// Клетки моих выстрелов, попавшие в корабли соперника.
  final List<int> myHits;
  final List<int> opponentShots;
  final List<int> opponentShipsHit;
  /// Потопленные корабли соперника (группы клеток).
  final List<List<int>> opponentSunkShips;
  /// Полный флот соперника — только после конца партии.
  final List<List<int>> opponentShips;
  final bool isMyTurn;
  final String turn;
  final int turnTimeSec;
  final int turnDeadline;
  final int setupDeadline;
  /// Остаток секунд на расстановку с сервера (устойчиво к перекосу часов).
  final int setupSecondsLeft;
  final int stakeBronze;
  final String? winner;
  final bool forfeit;
  final bool draw;
  final String? drawOfferBy;
  final int lastShot;
  final bool lastShotHit;
  final String? lastShotBy;
  final String? p1DisplayName;
  final String? p2DisplayName;
  final String p1AvatarKind;
  final String p2AvatarKind;
  final String? p1AvatarValue;
  final String? p2AvatarValue;
  final String? p1FrameCode;
  final String? p2FrameCode;
  final String? p1FrameColor;
  final String? p2FrameColor;

  bool get isOver => status == 'over';
  bool get isSetup => phase == 'setup';
  bool get isBattle => phase == 'battle';
  bool get isDraw => draw || (isOver && (winner == null || winner!.isEmpty));

  bool isTurnOf(String? userId) {
    if (userId == null || userId.isEmpty) return false;
    if (!isBattle || isOver) return false;
    if (turn.isNotEmpty) return turn == userId;
    return isMyTurn;
  }

  bool get hasBotOpponent =>
      p1UserId.startsWith('bot:') || p2UserId.startsWith('bot:');

  String? displayNameOf(String userId) {
    if (userId == p1UserId) {
      final n = p1DisplayName?.trim() ?? '';
      return n.isEmpty ? null : n;
    }
    if (userId == p2UserId) {
      final n = p2DisplayName?.trim() ?? '';
      return n.isEmpty ? null : n;
    }
    return null;
  }

  Set<int> get opponentSunkCells => {
        for (final ship in opponentSunkShips) ...ship,
      };

  BattleshipGameView copyWith({
    String? id,
    String? status,
    String? phase,
    String? lobbyId,
    String? p1UserId,
    String? p2UserId,
    bool? p1Ready,
    bool? p2Ready,
    List<List<int>>? myShips,
    List<int>? myShots,
    List<int>? myHits,
    List<int>? opponentShots,
    List<int>? opponentShipsHit,
    List<List<int>>? opponentSunkShips,
    List<List<int>>? opponentShips,
    bool? isMyTurn,
    String? turn,
    int? turnTimeSec,
    int? turnDeadline,
    int? setupDeadline,
    int? setupSecondsLeft,
    int? stakeBronze,
    String? winner,
    bool? forfeit,
    bool? draw,
    String? drawOfferBy,
    int? lastShot,
    bool? lastShotHit,
    String? lastShotBy,
    String? p1DisplayName,
    String? p2DisplayName,
    String? p1AvatarKind,
    String? p2AvatarKind,
    String? p1AvatarValue,
    String? p2AvatarValue,
    String? p1FrameCode,
    String? p2FrameCode,
    String? p1FrameColor,
    String? p2FrameColor,
  }) {
    return BattleshipGameView(
      id: id ?? this.id,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      lobbyId: lobbyId ?? this.lobbyId,
      p1UserId: p1UserId ?? this.p1UserId,
      p2UserId: p2UserId ?? this.p2UserId,
      p1Ready: p1Ready ?? this.p1Ready,
      p2Ready: p2Ready ?? this.p2Ready,
      myShips: myShips ?? this.myShips,
      myShots: myShots ?? this.myShots,
      myHits: myHits ?? this.myHits,
      opponentShots: opponentShots ?? this.opponentShots,
      opponentShipsHit: opponentShipsHit ?? this.opponentShipsHit,
      opponentSunkShips: opponentSunkShips ?? this.opponentSunkShips,
      opponentShips: opponentShips ?? this.opponentShips,
      isMyTurn: isMyTurn ?? this.isMyTurn,
      turn: turn ?? this.turn,
      turnTimeSec: turnTimeSec ?? this.turnTimeSec,
      turnDeadline: turnDeadline ?? this.turnDeadline,
      setupDeadline: setupDeadline ?? this.setupDeadline,
      setupSecondsLeft: setupSecondsLeft ?? this.setupSecondsLeft,
      stakeBronze: stakeBronze ?? this.stakeBronze,
      winner: winner ?? this.winner,
      forfeit: forfeit ?? this.forfeit,
      draw: draw ?? this.draw,
      drawOfferBy: drawOfferBy ?? this.drawOfferBy,
      lastShot: lastShot ?? this.lastShot,
      lastShotHit: lastShotHit ?? this.lastShotHit,
      lastShotBy: lastShotBy ?? this.lastShotBy,
      p1DisplayName: p1DisplayName ?? this.p1DisplayName,
      p2DisplayName: p2DisplayName ?? this.p2DisplayName,
      p1AvatarKind: p1AvatarKind ?? this.p1AvatarKind,
      p2AvatarKind: p2AvatarKind ?? this.p2AvatarKind,
      p1AvatarValue: p1AvatarValue ?? this.p1AvatarValue,
      p2AvatarValue: p2AvatarValue ?? this.p2AvatarValue,
      p1FrameCode: p1FrameCode ?? this.p1FrameCode,
      p2FrameCode: p2FrameCode ?? this.p2FrameCode,
      p1FrameColor: p1FrameColor ?? this.p1FrameColor,
      p2FrameColor: p2FrameColor ?? this.p2FrameColor,
    );
  }

  ({String kind, String? value, String? frameCode, String? frameColor})
      avatarOf(String userId) {
    if (userId == p1UserId) {
      return (
        kind: p1AvatarKind,
        value: p1AvatarValue,
        frameCode: p1FrameCode,
        frameColor: p1FrameColor,
      );
    }
    return (
      kind: p2AvatarKind,
      value: p2AvatarValue,
      frameCode: p2FrameCode,
      frameColor: p2FrameColor,
    );
  }

  /// Мои корабли, полностью потопленные выстрелами соперника.
  List<List<int>> get mySunkShips {
    final shots = opponentShots.toSet();
    return myShips.where((s) => s.every(shots.contains)).toList();
  }

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

    final turn = (json['turn'] ?? '').toString();
    final status = (json['status'] ?? 'active').toString();
    final phase = (json['phase'] ?? 'setup').toString();
    final isMyTurnFlag = json['is_my_turn'] == true;

    return BattleshipGameView(
      id: (json['game_id'] ?? json['id'] ?? '').toString(),
      status: status,
      phase: phase,
      lobbyId: (json['lobby_id'] ?? '').toString(),
      p1UserId: (json['p1_user_id'] ?? '').toString(),
      p2UserId: (json['p2_user_id'] ?? '').toString(),
      p1Ready: json['p1_ready'] == true,
      p2Ready: json['p2_ready'] == true,
      myShips: parseShips(json['my_ships']),
      myShots: parseInts(json['my_shots']),
      myHits: parseInts(json['my_hits']),
      opponentShots: parseInts(json['opponent_shots']),
      opponentShipsHit: parseInts(json['opponent_ships_hit']),
      opponentSunkShips: parseShips(json['opponent_sunk_ships']),
      opponentShips: parseShips(json['opponent_ships']),
      isMyTurn: isMyTurnFlag,
      turn: turn,
      turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
      turnDeadline: (json['turn_deadline'] as num?)?.toInt() ?? 0,
      setupDeadline: (json['setup_deadline'] as num?)?.toInt() ?? 0,
      setupSecondsLeft: (json['setup_seconds_left'] as num?)?.toInt() ?? 0,
      stakeBronze: (json['stake_bronze'] as num?)?.toInt() ?? 2,
      winner: (json['winner'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['winner'] as String).trim(),
      forfeit: json['forfeit'] == true,
      draw: json['draw'] == true,
      drawOfferBy: (json['draw_offer_by'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['draw_offer_by'] as String).trim(),
      lastShot: (json['last_shot'] as num?)?.toInt() ?? -1,
      lastShotHit: json['last_shot_hit'] == true,
      lastShotBy: (json['last_shot_by'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['last_shot_by'] as String).trim(),
      p1DisplayName: (json['p1_display_name'] as String?)?.trim(),
      p2DisplayName: (json['p2_display_name'] as String?)?.trim(),
      p1AvatarKind: (json['p1_avatar_kind'] ?? 'letter').toString(),
      p2AvatarKind: (json['p2_avatar_kind'] ?? 'letter').toString(),
      p1AvatarValue: json['p1_avatar_value']?.toString(),
      p2AvatarValue: json['p2_avatar_value']?.toString(),
      p1FrameCode: json['p1_frame_code']?.toString(),
      p2FrameCode: json['p2_frame_code']?.toString(),
      p1FrameColor: json['p1_frame_color']?.toString(),
      p2FrameColor: json['p2_frame_color']?.toString(),
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

  /// Открыть свою игру для поиска соперника — лобби становится публичным.
  Future<void> startMatchmake(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/battleship/lobby/$lobbyId/matchmake'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'BattleshipRepository.startMatchmake',
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
    if (OfflineBattleshipRegistry.instance.isOffline(gameId)) {
      final session = OfflineBattleshipRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      return session.view;
    }
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
    if (OfflineBattleshipRegistry.instance.isOffline(gameId)) {
      final session = OfflineBattleshipRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      return session.placeShips(ships);
    }
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
    if (OfflineBattleshipRegistry.instance.isOffline(gameId)) {
      final session = OfflineBattleshipRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      return session.shoot(cell);
    }
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
    if (OfflineBattleshipRegistry.instance.isOffline(gameId)) {
      final session = OfflineBattleshipRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      return session.forfeit();
    }
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

  Future<void> offerDraw(String gameId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/battleship/game/$gameId/draw-offer'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'BattleshipRepository.offerDraw',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> acceptDraw(String gameId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/battleship/game/$gameId/draw-accept'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'BattleshipRepository.acceptDraw',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<String> rematch(String gameId) async {
    if (OfflineBattleshipRegistry.instance.isOffline(gameId)) {
      final session = OfflineBattleshipRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      session.restart();
      return '';
    }
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
