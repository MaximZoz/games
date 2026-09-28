import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';
import 'package:multigames_client/games/checkers/checkers_offline_session.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException, LobbyPlayer, parseLobbyInvited;

class CheckersCreateResult {
  const CheckersCreateResult({
    required this.lobbyId,
    this.gameId,
    this.joined = false,
  });
  final String lobbyId;
  final String? gameId;
  final bool joined;
}

class CheckersLobbyView {
  const CheckersLobbyView({
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

  factory CheckersLobbyView.fromJson(Map<String, dynamic> json) {
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
    return CheckersLobbyView(
      invited: parseLobbyInvited(json['invited']),
      id: (json['lobby_id'] ?? json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      mode: (json['mode'] ?? 'invite').toString(),
      gameMode: CheckersEngine.normalizeMode(json['game_mode']?.toString()),
      creatorId: (json['creator_id'] ?? '').toString(),
      playerIds: ids,
      players: players,
      turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
      stakeBronze: (json['stake_bronze'] as num?)?.toInt() ?? 2,
      gameId: gameId.isEmpty ? null : gameId,
    );
  }
}

class CheckersPlayerView {
  const CheckersPlayerView({
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

  factory CheckersPlayerView.fromJson(Map<String, dynamic> json) {
    final id = (json['user_id'] ?? '').toString();
    return CheckersPlayerView(
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

class CheckersGameView {
  const CheckersGameView({
    required this.id,
    required this.lobbyId,
    required this.gameMode,
    required this.board,
    required this.turn,
    required this.seq,
    required this.mustContinue,
    required this.contR,
    required this.contC,
    required this.lastFromR,
    required this.lastFromC,
    required this.lastToR,
    required this.lastToC,
    required this.players,
    required this.playerIds,
    required this.legalMoves,
    required this.myIndex,
    required this.isMyTurn,
    required this.turnTimeSec,
    required this.turnDeadline,
    required this.stakeBronze,
    required this.isOver,
    required this.winnerIndex,
    required this.winnerUserId,
    required this.isDraw,
    this.drawReason = '',
    this.isForfeit = false,
    this.isTimeout = false,
    this.drawOfferBy,
  });

  final String id;
  final String lobbyId;
  final String gameMode;
  final List<int> board;
  final int turn;
  final int seq;
  final bool mustContinue;
  final int contR;
  final int contC;
  final int lastFromR;
  final int lastFromC;
  final int lastToR;
  final int lastToC;
  final List<CheckersPlayerView> players;
  final List<String> playerIds;
  final List<CheckersMove> legalMoves;
  final int myIndex;
  final bool isMyTurn;
  final int turnTimeSec;
  final int turnDeadline;
  final int stakeBronze;
  final bool isOver;
  final int winnerIndex;
  final String winnerUserId;
  final bool isDraw;
  final String drawReason;
  final bool isForfeit;
  final bool isTimeout;
  final String? drawOfferBy;

  bool get iWon => isOver && !isDraw && myIndex >= 0 && winnerIndex == myIndex;
  bool get hasBotOpponent => playerIds.any((id) => id.startsWith('bot:'));

  CheckersPlayerView? get opponent {
    for (final p in players) {
      if (p.seat != myIndex) return p;
    }
    return null;
  }

  factory CheckersGameView.fromJson(Map<String, dynamic> json) {
    final boardRaw = json['board'];
    final legalRaw = json['legal_moves'];
    final playersRaw = json['players'];
    return CheckersGameView(
      id: (json['id'] ?? json['game_id'] ?? '').toString(),
      lobbyId: (json['lobby_id'] ?? '').toString(),
      gameMode: CheckersEngine.normalizeMode(json['game_mode']?.toString()),
      board: boardRaw is List
          ? boardRaw.map((e) => (e as num).toInt()).toList()
          : const [],
      turn: (json['turn'] as num?)?.toInt() ?? 0,
      seq: (json['seq'] as num?)?.toInt() ?? 0,
      mustContinue: json['must_continue'] == true,
      contR: (json['cont_r'] as num?)?.toInt() ?? -1,
      contC: (json['cont_c'] as num?)?.toInt() ?? -1,
      lastFromR: (json['last_from_r'] as num?)?.toInt() ?? -1,
      lastFromC: (json['last_from_c'] as num?)?.toInt() ?? -1,
      lastToR: (json['last_to_r'] as num?)?.toInt() ?? -1,
      lastToC: (json['last_to_c'] as num?)?.toInt() ?? -1,
      players: playersRaw is List
          ? playersRaw
              .whereType<Map>()
              .map(
                  (e) => CheckersPlayerView.fromJson(e.cast<String, dynamic>()))
              .toList()
          : const [],
      playerIds: json['player_ids'] is List
          ? (json['player_ids'] as List).map((e) => e.toString()).toList()
          : const [],
      legalMoves: legalRaw is List
          ? legalRaw
              .whereType<Map>()
              .map((e) => CheckersMove.fromJson(e.cast<String, dynamic>()))
              .toList()
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
      drawReason: (json['draw_reason'] ?? '').toString(),
      isForfeit: json['is_forfeit'] == true,
      isTimeout: json['is_timeout'] == true,
      drawOfferBy: (json['draw_offer_by'] ?? '').toString().trim().isEmpty
          ? null
          : json['draw_offer_by'].toString(),
    );
  }
}

bool hasFullCheckersView(Map<String, dynamic> data) =>
    data.containsKey('board') && data.containsKey('players');

bool isOlderCheckers(CheckersGameView incoming, CheckersGameView current) =>
    incoming.id == current.id && incoming.seq < current.seq;

class CheckersRepository {
  CheckersRepository({required AuthRepository authRepository})
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

  Future<CheckersCreateResult> createLobby({
    required String mode,
    required String gameMode,
    required int turnTimeSec,
    required int stakeBronze,
    bool vsBot = false,
  }) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/checkers/lobby'),
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
        operation: 'CheckersRepository.createLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final gameId = (j['game_id'] ?? '').toString().trim();
    return CheckersCreateResult(
      lobbyId: (j['lobby_id'] ?? '').toString(),
      gameId: gameId.isEmpty ? null : gameId,
    );
  }

  Future<CheckersLobbyView> getLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/games/checkers/lobby/$lobbyId'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'CheckersRepository.getLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    j.putIfAbsent('lobby_id', () => lobbyId);
    return CheckersLobbyView.fromJson(j);
  }

  Future<CheckersCreateResult> joinLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/checkers/lobby/$lobbyId/join'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'CheckersRepository.joinLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final gameId = (j['game_id'] ?? '').toString().trim();
    return CheckersCreateResult(
      lobbyId: (j['lobby_id'] ?? lobbyId).toString(),
      gameId: gameId.isEmpty ? null : gameId,
      joined: true,
    );
  }

  Future<void> leaveLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/checkers/lobby/$lobbyId/leave'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'CheckersRepository.leaveLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> inviteFriend(String lobbyId, String friendUserId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/checkers/lobby/$lobbyId/invite'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'friend_user_id': friendUserId}),
        operation: 'CheckersRepository.inviteFriend',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> declineLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/checkers/lobby/$lobbyId/decline'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'CheckersRepository.declineLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> startMatchmake(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/checkers/lobby/$lobbyId/matchmake'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'CheckersRepository.startMatchmake',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> cancelInvite(String lobbyId, String friendUserId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse(
            '$apiBaseUrl/api/games/checkers/lobby/$lobbyId/cancel-invite'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'friend_user_id': friendUserId}),
        operation: 'CheckersRepository.cancelInvite',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<CheckersGameView> getGame(String gameId) async {
    final offline = OfflineCheckersRegistry.instance.get(gameId);
    if (offline != null) return offline.view;
    if (OfflineCheckersRegistry.instance.isOffline(gameId)) {
      throw GamesException(404, 'offline game not found');
    }
    final res = await _sendAuth(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/games/checkers/game/$gameId'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'CheckersRepository.getGame',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    return CheckersGameView.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<void> move(String gameId, CheckersMove mv) async {
    if (OfflineCheckersRegistry.instance.isOffline(gameId)) {
      OfflineCheckersRegistry.instance.get(gameId)?.move(mv);
      return;
    }
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/checkers/game/$gameId/move'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(mv.toJson()),
        operation: 'CheckersRepository.move',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> forfeit(String gameId) async {
    if (OfflineCheckersRegistry.instance.isOffline(gameId)) {
      OfflineCheckersRegistry.instance.get(gameId)?.forfeit();
      return;
    }
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/checkers/game/$gameId/forfeit'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'CheckersRepository.forfeit',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> offerDraw(String gameId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/checkers/game/$gameId/draw'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'CheckersRepository.offerDraw',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> acceptDraw(String gameId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/checkers/game/$gameId/accept-draw'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'CheckersRepository.acceptDraw',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<String> rematch(String gameId) async {
    if (OfflineCheckersRegistry.instance.isOffline(gameId)) {
      OfflineCheckersRegistry.instance.get(gameId)?.restart();
      return '';
    }
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/checkers/rematch'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'game_id': gameId}),
        operation: 'CheckersRepository.rematch',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (j['lobby_id'] ?? '').toString();
  }
}
