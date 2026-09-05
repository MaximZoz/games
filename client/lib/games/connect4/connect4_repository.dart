import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/connect4/connect4_engine.dart';
import 'package:multigames_client/games/connect4/connect4_offline_session.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException, LobbyPlayer, parseLobbyInvited;

class Connect4CreateResult {
  const Connect4CreateResult({
    required this.lobbyId,
    this.gameId,
    this.joined = false,
  });
  final String lobbyId;
  final String? gameId;
  final bool joined;
}

class Connect4LobbyView {
  const Connect4LobbyView({
    required this.id,
    required this.status,
    required this.mode,
    required this.gameMode,
    required this.creatorId,
    required this.playerIds,
    required this.players,
    this.invited = const [],
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
  final List<LobbyPlayer> invited;
  final int turnTimeSec;
  final int stakeBronze;
  final String? gameId;

  factory Connect4LobbyView.fromJson(Map<String, dynamic> json) {
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
    return Connect4LobbyView(
      invited: parseLobbyInvited(json['invited']),
      id: (json['lobby_id'] ?? json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      mode: (json['mode'] ?? 'invite').toString(),
      gameMode: Connect4Engine.normalizeMode(json['game_mode']?.toString()),
      creatorId: (json['creator_id'] ?? '').toString(),
      playerIds: ids,
      players: players,
      turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
      stakeBronze: (json['stake_bronze'] as num?)?.toInt() ?? 2,
      gameId: gameId.isEmpty ? null : gameId,
    );
  }
}

class Connect4PlayerView {
  const Connect4PlayerView({
    required this.userId,
    required this.seat,
    required this.displayName,
    this.isBot = false,
    this.avatarKind = 'letter',
    this.avatarValue,
    this.frameCode,
    this.frameColor,
  });

  final String userId;
  final int seat;
  final String displayName;
  final bool isBot;
  final String avatarKind;
  final String? avatarValue;
  final String? frameCode;
  final String? frameColor;

  factory Connect4PlayerView.fromJson(Map<String, dynamic> json) {
    final id = (json['user_id'] ?? '').toString();
    return Connect4PlayerView(
      userId: id,
      seat: (json['seat'] as num?)?.toInt() ?? 0,
      displayName: (json['display_name'] ?? '').toString(),
      isBot: json['is_bot'] == true || id.startsWith('bot:'),
      avatarKind: (json['avatar_kind'] ?? 'letter').toString(),
      avatarValue: json['avatar_value']?.toString(),
      frameCode: json['frame_code']?.toString(),
      frameColor: json['frame_color']?.toString(),
    );
  }
}

class Connect4GameView {
  const Connect4GameView({
    required this.id,
    required this.lobbyId,
    required this.gameMode,
    required this.cols,
    required this.rows,
    required this.board,
    required this.turn,
    required this.seq,
    required this.lastCol,
    required this.lastRow,
    required this.players,
    required this.playerIds,
    required this.legalColumns,
    required this.myIndex,
    required this.isMyTurn,
    required this.turnTimeSec,
    required this.turnDeadline,
    required this.stakeBronze,
    required this.isOver,
    required this.winnerIndex,
    required this.winnerUserId,
    required this.isDraw,
    this.isForfeit = false,
    this.isTimeout = false,
    this.drawOfferBy,
  });

  final String id;
  final String lobbyId;
  final String gameMode;
  final int cols;
  final int rows;
  final List<int> board;
  final int turn;
  final int seq;
  final int lastCol;
  final int lastRow;
  final List<Connect4PlayerView> players;
  final List<String> playerIds;
  final List<int> legalColumns;
  final int myIndex;
  final bool isMyTurn;
  final int turnTimeSec;
  final int turnDeadline;
  final int stakeBronze;
  final bool isOver;
  final int winnerIndex;
  final String winnerUserId;
  final bool isDraw;
  final bool isForfeit;
  final bool isTimeout;
  final String? drawOfferBy;

  bool get iWon => isOver && !isDraw && myIndex >= 0 && winnerIndex == myIndex;
  bool get hasBotOpponent => playerIds.any((id) => id.startsWith('bot:'));

  Connect4PlayerView? get opponent {
    for (final p in players) {
      if (p.seat != myIndex) return p;
    }
    return null;
  }

  factory Connect4GameView.fromJson(Map<String, dynamic> json) {
    final boardRaw = json['board'];
    final legalRaw = json['legal_columns'];
    final playersRaw = json['players'];
    return Connect4GameView(
      id: (json['id'] ?? json['game_id'] ?? '').toString(),
      lobbyId: (json['lobby_id'] ?? '').toString(),
      gameMode: Connect4Engine.normalizeMode(json['game_mode']?.toString()),
      cols: (json['cols'] as num?)?.toInt() ?? 7,
      rows: (json['rows'] as num?)?.toInt() ?? 6,
      board: boardRaw is List
          ? boardRaw.map((e) => (e as num).toInt()).toList()
          : const [],
      turn: (json['turn'] as num?)?.toInt() ?? 0,
      seq: (json['seq'] as num?)?.toInt() ?? 0,
      lastCol: (json['last_col'] as num?)?.toInt() ?? -1,
      lastRow: (json['last_row'] as num?)?.toInt() ?? -1,
      players: playersRaw is List
          ? playersRaw
              .whereType<Map>()
              .map((e) =>
                  Connect4PlayerView.fromJson(e.cast<String, dynamic>()))
              .toList()
          : const [],
      playerIds: json['player_ids'] is List
          ? (json['player_ids'] as List).map((e) => e.toString()).toList()
          : const [],
      legalColumns: legalRaw is List
          ? legalRaw.map((e) => (e as num).toInt()).toList()
          : const [],
      myIndex: (json['my_index'] as num?)?.toInt() ?? -1,
      isMyTurn: json['is_my_turn'] == true,
      turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
      turnDeadline: (json['turn_deadline'] as num?)?.toInt() ?? 0,
      stakeBronze: (json['stake_bronze'] as num?)?.toInt() ?? 0,
      isOver: json['is_over'] == true,
      winnerIndex: (json['winner_index'] as num?)?.toInt() ?? -1,
      winnerUserId: (json['winner_user_id'] ?? '').toString(),
      isDraw: json['is_draw'] == true,
      isForfeit: json['is_forfeit'] == true,
      isTimeout: json['is_timeout'] == true,
      drawOfferBy: (json['draw_offer_by'] ?? '').toString().trim().isEmpty
          ? null
          : json['draw_offer_by'].toString(),
    );
  }
}

bool hasFullConnect4View(Map<String, dynamic> data) =>
    data.containsKey('board') && data.containsKey('players');

bool isOlderConnect4(Connect4GameView incoming, Connect4GameView current) =>
    incoming.id == current.id && incoming.seq < current.seq;

class Connect4Repository {
  Connect4Repository({required AuthRepository authRepository})
      : _auth = authRepository;

  final AuthRepository _auth;

  Future<http.Response> _sendAuth(
    Future<http.Response> Function(String token) send,
  ) async {
    try {
      return await _auth.sendAuthorized(send);
    } on AuthException catch (e) {
      throw GamesException(
        e.statusCode,
        e.statusCode == 401 ? LocaleService.l10n.sessionExpired : e.message,
      );
    }
  }

  Never _fail(http.Response res) {
    var msg = res.body.trim();
    var key = '';
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        key = (body['error'] ?? body['code'] ?? '').toString();
        msg = (body['message'] ?? body['error'] ?? msg).toString();
      }
    } catch (_) {}
    if (msg.isEmpty) msg = LocaleService.l10n.commonServerErrorShort;
    throw GamesException(res.statusCode, msg, errorKey: key);
  }

  Future<Connect4CreateResult> createLobby({
    required String mode,
    required String gameMode,
    required int turnTimeSec,
    required int stakeBronze,
    bool vsBot = false,
  }) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/connect4/lobby'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'mode': mode,
          'game_mode': gameMode,
          'turn_time_sec': turnTimeSec,
          'stake_bronze': stakeBronze,
          'vs_bot': vsBot,
        }),
        operation: 'Connect4Repository.createLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final gameId = (j['game_id'] ?? '').toString().trim();
    return Connect4CreateResult(
      lobbyId: (j['lobby_id'] ?? '').toString(),
      gameId: gameId.isEmpty ? null : gameId,
    );
  }

  Future<Connect4LobbyView> getLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/games/connect4/lobby/$lobbyId'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'Connect4Repository.getLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    j.putIfAbsent('lobby_id', () => lobbyId);
    return Connect4LobbyView.fromJson(j);
  }

  Future<Connect4CreateResult> joinLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/connect4/lobby/$lobbyId/join'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'Connect4Repository.joinLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final gameId = (j['game_id'] ?? '').toString().trim();
    return Connect4CreateResult(
      lobbyId: (j['lobby_id'] ?? lobbyId).toString(),
      gameId: gameId.isEmpty ? null : gameId,
      joined: true,
    );
  }

  Future<void> leaveLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/connect4/lobby/$lobbyId/leave'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'Connect4Repository.leaveLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> inviteFriend(String lobbyId, String friendUserId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/connect4/lobby/$lobbyId/invite'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'friend_user_id': friendUserId}),
        operation: 'Connect4Repository.inviteFriend',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> declineLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/connect4/lobby/$lobbyId/decline'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'Connect4Repository.declineLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> startMatchmake(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/connect4/lobby/$lobbyId/matchmake'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'Connect4Repository.startMatchmake',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> cancelInvite(String lobbyId, String friendUserId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse(
            '$apiBaseUrl/api/games/connect4/lobby/$lobbyId/cancel-invite'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'friend_user_id': friendUserId}),
        operation: 'Connect4Repository.cancelInvite',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<Connect4GameView> getGame(String gameId) async {
    final offline = OfflineConnect4Registry.instance.get(gameId);
    if (offline != null) return offline.view;
    if (OfflineConnect4Registry.instance.isOffline(gameId)) {
      throw GamesException(404, 'offline game not found');
    }
    final res = await _sendAuth(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/games/connect4/game/$gameId'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'Connect4Repository.getGame',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    return Connect4GameView.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<void> drop(String gameId, int col) async {
    if (OfflineConnect4Registry.instance.isOffline(gameId)) {
      OfflineConnect4Registry.instance.get(gameId)?.drop(col);
      return;
    }
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/connect4/game/$gameId/move'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'col': col}),
        operation: 'Connect4Repository.drop',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> forfeit(String gameId) async {
    if (OfflineConnect4Registry.instance.isOffline(gameId)) {
      OfflineConnect4Registry.instance.get(gameId)?.forfeit();
      return;
    }
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/connect4/game/$gameId/forfeit'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'Connect4Repository.forfeit',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> offerDraw(String gameId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/connect4/game/$gameId/draw'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'Connect4Repository.offerDraw',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> acceptDraw(String gameId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/connect4/game/$gameId/accept-draw'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'Connect4Repository.acceptDraw',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<String> rematch(String gameId) async {
    if (OfflineConnect4Registry.instance.isOffline(gameId)) {
      OfflineConnect4Registry.instance.get(gameId)?.restart();
      return '';
    }
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/connect4/rematch'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'game_id': gameId}),
        operation: 'Connect4Repository.rematch',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (j['lobby_id'] ?? '').toString();
  }
}
