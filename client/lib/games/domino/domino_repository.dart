import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/domino/domino_engine.dart';
import 'package:multigames_client/games/domino/domino_offline_session.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException, LobbyPlayer, parseLobbyInvited;

int _asInt(Object? value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

List<T> _models<T>(Object? raw, T Function(Map<String, dynamic>) convert) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map) convert(Map<String, dynamic>.from(item)),
  ];
}

class DominoPlayerView {
  const DominoPlayerView({
    required this.id,
    required this.seat,
    required this.hand,
    required this.handCount,
    required this.score,
    required this.forfeited,
    required this.roundPips,
    required this.roundDelta,
    this.displayName,
    this.avatarKind = 'letter',
    this.avatarValue,
    this.frameCode,
    this.frameColor,
  });

  final String id;
  final int seat;
  final List<int> hand;
  final int handCount;
  final int score;
  final bool forfeited;
  final int roundPips;
  final int roundDelta;
  final String? displayName;
  final String avatarKind;
  final String? avatarValue;
  final String? frameCode;
  final String? frameColor;

  bool get isBot => id.startsWith('bot:');

  factory DominoPlayerView.fromJson(Map<String, dynamic> json) {
    final hand = [
      for (final id in (json['hand'] as List? ?? const []))
        if (id is num) id.toInt(),
    ];
    return DominoPlayerView(
      id: (json['user_id'] ?? json['id'] ?? '').toString(),
      seat: _asInt(json['seat']),
      hand: hand,
      handCount: _asInt(json['hand_count'], hand.length),
      score: _asInt(json['score']),
      forfeited: json['forfeited'] == true,
      roundPips: _asInt(json['round_pips']),
      roundDelta: _asInt(json['round_delta']),
      displayName: json['display_name']?.toString(),
      avatarKind: (json['avatar_kind'] ?? 'letter').toString(),
      avatarValue: json['avatar_value']?.toString(),
      frameCode: json['frame_code']?.toString(),
      frameColor: json['frame_color']?.toString(),
    );
  }
}

class DominoGameView {
  const DominoGameView({
    required this.id,
    required this.lobbyId,
    required this.players,
    required this.chain,
    required this.leftEnd,
    required this.rightEnd,
    required this.boneyardCount,
    required this.turn,
    required this.forcedTile,
    required this.round,
    required this.status,
    required this.starter,
    required this.roundKind,
    required this.outSeat,
    required this.goatSeat,
    required this.winnerUserIds,
    required this.legal,
    required this.targetScore,
    required this.lastAction,
    required this.lastTile,
    required this.lastEnd,
    required this.lastActor,
    required this.eventSeq,
    required this.myIndex,
    this.chatId,
    this.turnTimeSec = 0,
    this.turnDeadline = 0,
    this.stakeBronze = 0,
    this.isForfeit = false,
    this.isTimeout = false,
    this.isMyTurnFlag = false,
  });

  final String id;
  final String lobbyId;
  final String? chatId;
  final List<DominoPlayerView> players;
  final List<DominoPlaced> chain;
  final int leftEnd;
  final int rightEnd;
  final int boneyardCount;
  final int turn;
  final int forcedTile;
  final int round;
  final String status;
  final int starter;
  final String roundKind;
  final int outSeat;
  final int goatSeat;
  final List<String> winnerUserIds;
  final List<DominoMove> legal;
  final int targetScore;
  final String lastAction;
  final int lastTile;
  final String lastEnd;
  final int lastActor;
  final int eventSeq;
  final int myIndex;
  final int turnTimeSec;
  final int turnDeadline;
  final int stakeBronze;
  final bool isForfeit;
  final bool isTimeout;
  final bool isMyTurnFlag;

  bool get isOver => status == dominoStatusOver;
  bool get isRoundEnd => status == dominoStatusRoundEnd;
  bool get isPlaying => status == dominoStatusPlaying;

  DominoPlayerView? get me =>
      myIndex >= 0 && myIndex < players.length ? players[myIndex] : null;

  bool get iForfeited => me?.forfeited == true;

  bool get isMyTurn =>
      isPlaying &&
      myIndex >= 0 &&
      myIndex == turn &&
      !iForfeited &&
      !isOver &&
      (isMyTurnFlag || legal.isNotEmpty || canDraw || canPass);

  bool get canDraw =>
      isPlaying && myIndex == turn && legal.isEmpty && boneyardCount > 0;

  bool get canPass =>
      isPlaying && myIndex == turn && legal.isEmpty && boneyardCount == 0;

  bool get iWon => me != null && winnerUserIds.contains(me!.id);

  bool get isDraw => isOver && winnerUserIds.isEmpty;

  bool get iAmGoat => isOver && goatSeat == myIndex && !iForfeited;

  factory DominoGameView.fromJson(Map<String, dynamic> json) {
    final players = _models(json['players'], DominoPlayerView.fromJson);
    return DominoGameView(
      id: (json['id'] ?? json['game_id'] ?? '').toString(),
      lobbyId: (json['lobby_id'] ?? '').toString(),
      chatId: json['chat_id']?.toString(),
      players: players,
      chain: _models(json['chain'], DominoPlaced.fromJson),
      leftEnd: _asInt(json['left_end'], -1),
      rightEnd: _asInt(json['right_end'], -1),
      boneyardCount: _asInt(json['boneyard_count']),
      turn: _asInt(json['turn']),
      forcedTile: _asInt(json['forced_tile'], -1),
      round: _asInt(json['round'], 1),
      status: (json['status'] ?? '').toString(),
      starter: _asInt(json['starter']),
      roundKind: (json['round_kind'] ?? '').toString(),
      outSeat: _asInt(json['out_seat'], -1),
      goatSeat: _asInt(json['goat_seat'], -1),
      winnerUserIds: [
        for (final id in (json['winner_user_ids'] as List? ?? const []))
          id.toString(),
      ],
      legal: _models(json['legal'], DominoMove.fromJson),
      targetScore: _asInt(json['target_score'], dominoGoatScore),
      lastAction: (json['last_action'] ?? '').toString(),
      lastTile: _asInt(json['last_tile'], -1),
      lastEnd: (json['last_end'] ?? '').toString(),
      lastActor: _asInt(json['last_actor'], -1),
      eventSeq: _asInt(json['event_seq']),
      myIndex: _asInt(json['my_index'], -1),
      turnTimeSec: _asInt(json['turn_time_sec']),
      turnDeadline: _asInt(json['turn_deadline']),
      stakeBronze: _asInt(json['stake_bronze']),
      isForfeit: json['is_forfeit'] == true,
      isTimeout: json['is_timeout'] == true,
      isMyTurnFlag: json['is_my_turn'] == true,
    );
  }
}

class DominoLobbyView {
  const DominoLobbyView({
    required this.id,
    required this.creatorId,
    required this.status,
    required this.mode,
    required this.maxPlayers,
    required this.turnTimeSec,
    required this.stakeBronze,
    required this.playerIds,
    required this.players,
    this.invited = const [],
    this.chatId,
    this.gameId,
  });

  final String id;
  final String creatorId;
  final String status;
  final String mode;
  final int maxPlayers;
  final int turnTimeSec;
  final int stakeBronze;
  final List<String> playerIds;
  final List<LobbyPlayer> players;
  final List<LobbyPlayer> invited;
  final String? chatId;
  final String? gameId;

  factory DominoLobbyView.fromJson(Map<String, dynamic> json) {
    final ids =
        (json['player_ids'] as List?)?.map((id) => id.toString()).toList() ??
            const <String>[];
    final parsed = _models(json['players'], LobbyPlayer.fromJson);
    return DominoLobbyView(
      invited: parseLobbyInvited(json['invited']),
      id: (json['id'] ?? json['lobby_id'] ?? '').toString(),
      creatorId: (json['creator_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      mode: (json['mode'] ?? 'invite').toString(),
      maxPlayers: _asInt(json['max_players'], 2),
      turnTimeSec: _asInt(json['turn_time_sec']),
      stakeBronze: _asInt(json['stake_bronze'], 2),
      playerIds: ids,
      players: parsed.isNotEmpty
          ? parsed
          : [for (final id in ids) LobbyPlayer(id: id, displayName: '')],
      chatId: json['chat_id']?.toString(),
      gameId: json['game_id']?.toString(),
    );
  }
}

class DominoCreateResult {
  const DominoCreateResult({
    required this.lobbyId,
    this.gameId,
    this.matched = false,
  });

  final String lobbyId;
  final String? gameId;
  final bool matched;

  factory DominoCreateResult.fromJson(Map<String, dynamic> json) =>
      DominoCreateResult(
        lobbyId: (json['lobby_id'] ?? '').toString(),
        gameId: json['game_id']?.toString(),
        matched: json['matched'] == true,
      );
}

class DominoJoinResult {
  const DominoJoinResult({
    required this.joined,
    this.gameId,
    this.lobbyId,
  });

  final bool joined;
  final String? gameId;
  final String? lobbyId;

  factory DominoJoinResult.fromJson(Map<String, dynamic> json) =>
      DominoJoinResult(
        joined: json['joined'] == true,
        gameId: json['game_id']?.toString(),
        lobbyId: json['lobby_id']?.toString(),
      );
}

class DominoRepository {
  DominoRepository({required AuthRepository authRepository})
      : _auth = authRepository;

  final AuthRepository _auth;

  Future<http.Response> _sendAuth(
    Future<http.Response> Function(String token) send,
  ) async {
    try {
      return await _auth.sendAuthorized(send);
    } on AuthException catch (error) {
      throw GamesException(
        error.statusCode,
        error.statusCode == 401
            ? LocaleService.l10n.sessionExpired
            : error.message,
      );
    }
  }

  Never _fail(http.Response response) {
    var message = response.body.trim();
    var key = '';
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        key = (body['error'] ?? body['code'] ?? '').toString();
        message = (body['message'] ?? body['error'] ?? message).toString();
      }
    } catch (_) {}
    if (message.isEmpty) message = LocaleService.l10n.commonServerErrorShort;
    throw GamesException(response.statusCode, message, errorKey: key);
  }

  Future<DominoCreateResult> createLobby({
    required String mode,
    required int maxPlayers,
    required int turnTimeSec,
    required int stakeBronze,
  }) async {
    final response = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/domino/lobby'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'mode': mode,
            'max_players': maxPlayers,
            'turn_time_sec': turnTimeSec,
            'stake_bronze': stakeBronze,
            'game_mode': 'kozel',
          }),
          operation: 'DominoRepository.createLobby',
        ));
    if (response.statusCode != 200 && response.statusCode != 201) {
      _fail(response);
    }
    return DominoCreateResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<DominoLobbyView> getLobby(String lobbyId) async {
    final response = await _sendAuth((token) => ApiClient.get(
          Uri.parse('$apiBaseUrl/api/games/domino/lobby/$lobbyId'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'DominoRepository.getLobby',
        ));
    if (response.statusCode != 200) _fail(response);
    return DominoLobbyView.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<DominoJoinResult> joinLobby(String lobbyId) async {
    final response = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/domino/lobby/$lobbyId/join'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'DominoRepository.joinLobby',
        ));
    if (response.statusCode != 200) _fail(response);
    return DominoJoinResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> leaveLobby(String lobbyId) =>
      _emptyPost('/api/games/domino/lobby/$lobbyId/leave', 'leaveLobby');

  Future<void> declineLobby(String lobbyId) =>
      _emptyPost('/api/games/domino/lobby/$lobbyId/decline', 'declineLobby');

  Future<void> inviteFriend(String lobbyId, String friendUserId) => _jsonPost(
        '/api/games/domino/lobby/$lobbyId/invite',
        {'friend_user_id': friendUserId},
        'inviteFriend',
      );

  Future<void> startMatchmake(String lobbyId) => _emptyPost(
        '/api/games/domino/lobby/$lobbyId/matchmake',
        'startMatchmake',
      );

  Future<void> cancelInvite(String lobbyId, String friendUserId) => _jsonPost(
        '/api/games/domino/lobby/$lobbyId/cancel-invite',
        {'friend_user_id': friendUserId},
        'cancelInvite',
      );

  Future<DominoGameView> getGame(String gameId) async {
    if (OfflineDominoRegistry.instance.isOffline(gameId)) {
      final session = OfflineDominoRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      return session.view;
    }
    final response = await _sendAuth((token) => ApiClient.get(
          Uri.parse('$apiBaseUrl/api/games/domino/game/$gameId'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'DominoRepository.getGame',
        ));
    if (response.statusCode != 200) _fail(response);
    return DominoGameView.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> move(
    String gameId, {
    required String type,
    int? tile,
    String? end,
  }) async {
    if (OfflineDominoRegistry.instance.isOffline(gameId)) {
      final session = OfflineDominoRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      await session.applyMove(type: type, tile: tile, end: end);
      return;
    }
    final body = <String, dynamic>{'type': type};
    if (tile != null) body['tile'] = tile;
    if (end != null && end.isNotEmpty) body['end'] = end;
    await _jsonPost('/api/games/domino/game/$gameId/move', body, 'move');
  }

  Future<DominoCreateResult> rematch(String gameId) async {
    if (OfflineDominoRegistry.instance.isOffline(gameId)) {
      final session = OfflineDominoRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      session.restart();
      return const DominoCreateResult(lobbyId: '');
    }
    final response = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/domino/rematch'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'game_id': gameId}),
          operation: 'DominoRepository.rematch',
        ));
    if (response.statusCode != 200) _fail(response);
    return DominoCreateResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> forfeit(String gameId) async {
    if (OfflineDominoRegistry.instance.isOffline(gameId)) {
      final session = OfflineDominoRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      await session.forfeit();
      return;
    }
    await _emptyPost('/api/games/domino/game/$gameId/forfeit', 'forfeit');
  }

  Future<void> _emptyPost(String path, String operation) async {
    final response = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl$path'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'DominoRepository.$operation',
        ));
    if (response.statusCode != 200 && response.statusCode != 204) {
      _fail(response);
    }
  }

  Future<void> _jsonPost(
    String path,
    Map<String, dynamic> body,
    String operation,
  ) async {
    final response = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl$path'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
          operation: 'DominoRepository.$operation',
        ));
    if (response.statusCode != 200 && response.statusCode != 204) {
      _fail(response);
    }
  }
}
