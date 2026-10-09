import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/chess/chess_engine.dart';
import 'package:multigames_client/games/chess/chess_offline_session.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException, LobbyPlayer, parseLobbyInvited;

class ChessCreateResult {
  const ChessCreateResult({
    required this.lobbyId,
    this.gameId,
    this.joined = false,
  });
  final String lobbyId;
  final String? gameId;
  final bool joined;
}

class ChessLobbyView {
  const ChessLobbyView({
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

  factory ChessLobbyView.fromJson(Map<String, dynamic> json) {
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
    return ChessLobbyView(
      invited: parseLobbyInvited(json['invited']),
      id: (json['lobby_id'] ?? json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      mode: (json['mode'] ?? 'invite').toString(),
      gameMode: ChessEngine.normalizeMode(json['game_mode']?.toString()),
      creatorId: (json['creator_id'] ?? '').toString(),
      playerIds: ids,
      players: players,
      turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
      stakeBronze: (json['stake_bronze'] as num?)?.toInt() ?? 2,
      gameId: gameId.isEmpty ? null : gameId,
    );
  }
}

class ChessPlayerView {
  const ChessPlayerView({
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

  factory ChessPlayerView.fromJson(Map<String, dynamic> json) {
    final id = (json['user_id'] ?? '').toString();
    return ChessPlayerView(
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

class ChessGameView {
  const ChessGameView({
    required this.id,
    required this.lobbyId,
    required this.gameMode,
    required this.board,
    required this.turn,
    required this.seq,
    required this.inCheck,
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
    this.hasClock = false,
    this.clockMs0 = 0,
    this.clockMs1 = 0,
    this.clockIncMs = 0,
    this.clockRunning = -1,
  });

  final String id;
  final String lobbyId;
  final String gameMode;
  final List<int> board;
  final int turn;
  final int seq;
  final bool inCheck;
  final int lastFromR;
  final int lastFromC;
  final int lastToR;
  final int lastToC;
  final List<ChessPlayerView> players;
  final List<String> playerIds;
  final List<ChessMove> legalMoves;
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

  /// Включены ли шахматные часы (общее время партии по режиму).
  final bool hasClock;

  /// Остаток общего времени на игрока, мс (на момент снимка сервера).
  final int clockMs0;
  final int clockMs1;

  /// Прибавка на ход, мс.
  final int clockIncMs;

  /// Чей таймер сейчас идёт (0/1), или -1 если партия окончена/часов нет.
  final int clockRunning;

  bool get iWon => isOver && !isDraw && myIndex >= 0 && winnerIndex == myIndex;
  bool get hasBotOpponent => playerIds.any((id) => id.startsWith('bot:'));

  ChessPlayerView? get opponent {
    for (final p in players) {
      if (p.seat != myIndex) return p;
    }
    return null;
  }

  factory ChessGameView.fromJson(Map<String, dynamic> json) {
    final boardRaw = json['board'];
    final legalRaw = json['legal_moves'];
    final playersRaw = json['players'];
    return ChessGameView(
      id: (json['id'] ?? json['game_id'] ?? '').toString(),
      lobbyId: (json['lobby_id'] ?? '').toString(),
      gameMode: ChessEngine.normalizeMode(json['game_mode']?.toString()),
      board: boardRaw is List
          ? boardRaw.map((e) => (e as num).toInt()).toList()
          : const [],
      turn: (json['turn'] as num?)?.toInt() ?? 0,
      seq: (json['seq'] as num?)?.toInt() ?? 0,
      inCheck: json['in_check'] == true,
      lastFromR: (json['last_from_r'] as num?)?.toInt() ?? -1,
      lastFromC: (json['last_from_c'] as num?)?.toInt() ?? -1,
      lastToR: (json['last_to_r'] as num?)?.toInt() ?? -1,
      lastToC: (json['last_to_c'] as num?)?.toInt() ?? -1,
      players: playersRaw is List
          ? playersRaw
              .whereType<Map>()
              .map((e) => ChessPlayerView.fromJson(e.cast<String, dynamic>()))
              .toList()
          : const [],
      playerIds: json['player_ids'] is List
          ? (json['player_ids'] as List).map((e) => e.toString()).toList()
          : const [],
      legalMoves: legalRaw is List
          ? legalRaw
              .whereType<Map>()
              .map((e) => ChessMove.fromJson(e.cast<String, dynamic>()))
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
      hasClock: json['has_clock'] == true,
      clockMs0: (json['clock_ms_0'] as num?)?.toInt() ?? 0,
      clockMs1: (json['clock_ms_1'] as num?)?.toInt() ?? 0,
      clockIncMs: (json['clock_inc_ms'] as num?)?.toInt() ?? 0,
      clockRunning: (json['clock_running'] as num?)?.toInt() ?? -1,
    );
  }
}

bool hasFullChessView(Map<String, dynamic> data) =>
    data.containsKey('board') && data.containsKey('players');

bool isOlderChess(ChessGameView incoming, ChessGameView current) =>
    incoming.id == current.id && incoming.seq < current.seq;

class ChessRepository {
  ChessRepository({required AuthRepository authRepository})
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

  Future<ChessCreateResult> createLobby({
    required String mode,
    required String gameMode,
    required int turnTimeSec,
    required int stakeBronze,
    bool vsBot = false,
  }) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/chess/lobby'),
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
        operation: 'ChessRepository.createLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final gameId = (j['game_id'] ?? '').toString().trim();
    return ChessCreateResult(
      lobbyId: (j['lobby_id'] ?? '').toString(),
      gameId: gameId.isEmpty ? null : gameId,
    );
  }

  Future<ChessLobbyView> getLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/games/chess/lobby/$lobbyId'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ChessRepository.getLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    j.putIfAbsent('lobby_id', () => lobbyId);
    return ChessLobbyView.fromJson(j);
  }

  Future<ChessCreateResult> joinLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/chess/lobby/$lobbyId/join'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ChessRepository.joinLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final gameId = (j['game_id'] ?? '').toString().trim();
    return ChessCreateResult(
      lobbyId: (j['lobby_id'] ?? lobbyId).toString(),
      gameId: gameId.isEmpty ? null : gameId,
      joined: true,
    );
  }

  Future<void> leaveLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/chess/lobby/$lobbyId/leave'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ChessRepository.leaveLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> inviteFriend(String lobbyId, String friendUserId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/chess/lobby/$lobbyId/invite'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'friend_user_id': friendUserId}),
        operation: 'ChessRepository.inviteFriend',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> declineLobby(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/chess/lobby/$lobbyId/decline'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ChessRepository.declineLobby',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> startMatchmake(String lobbyId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/chess/lobby/$lobbyId/matchmake'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ChessRepository.startMatchmake',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> cancelInvite(String lobbyId, String friendUserId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/chess/lobby/$lobbyId/cancel-invite'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'friend_user_id': friendUserId}),
        operation: 'ChessRepository.cancelInvite',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<ChessGameView> getGame(String gameId) async {
    final offline = OfflineChessRegistry.instance.get(gameId);
    if (offline != null) return offline.view;
    if (OfflineChessRegistry.instance.isOffline(gameId)) {
      throw GamesException(404, 'offline game not found');
    }
    final res = await _sendAuth(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/games/chess/game/$gameId'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ChessRepository.getGame',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    return ChessGameView.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<void> move(String gameId, ChessMove mv) async {
    if (OfflineChessRegistry.instance.isOffline(gameId)) {
      OfflineChessRegistry.instance.get(gameId)?.move(mv);
      return;
    }
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/chess/game/$gameId/move'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(mv.toJson()),
        operation: 'ChessRepository.move',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> forfeit(String gameId) async {
    if (OfflineChessRegistry.instance.isOffline(gameId)) {
      OfflineChessRegistry.instance.get(gameId)?.forfeit();
      return;
    }
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/chess/game/$gameId/forfeit'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ChessRepository.forfeit',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> offerDraw(String gameId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/chess/game/$gameId/draw'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ChessRepository.offerDraw',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<void> acceptDraw(String gameId) async {
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/chess/game/$gameId/accept-draw'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ChessRepository.acceptDraw',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
  }

  Future<String> rematch(String gameId) async {
    if (OfflineChessRegistry.instance.isOffline(gameId)) {
      OfflineChessRegistry.instance.get(gameId)?.restart();
      return '';
    }
    final res = await _sendAuth(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/chess/rematch'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'game_id': gameId}),
        operation: 'ChessRepository.rematch',
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (j['lobby_id'] ?? '').toString();
  }
}
