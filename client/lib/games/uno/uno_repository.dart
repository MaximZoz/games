import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException, LobbyPlayer;
import 'package:multigames_client/games/uno/uno_card.dart';
import 'package:multigames_client/games/uno/uno_offline_session.dart';

Object? _pick(Map<String, dynamic> json, String snake, [String? camel]) =>
    json[snake] ?? (camel == null ? null : json[camel]);

List<T> _models<T>(
  Object? raw,
  T Function(Map<String, dynamic>) convert,
) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((item) => convert(item.cast<String, dynamic>()))
      .toList();
}

class UnoPlayerView {
  const UnoPlayerView({
    required this.id,
    required this.seat,
    required this.hand,
    required this.handCount,
    required this.score,
    required this.saidUno,
    required this.forfeited,
    this.displayName,
    this.avatarKind = 'letter',
    this.avatarValue,
    this.frameCode,
    this.frameColor,
  });

  final String id;
  final int seat;
  final List<UnoCard> hand;
  final int handCount;
  final int score;
  final bool saidUno;
  final bool forfeited;
  final String? displayName;
  final String avatarKind;
  final String? avatarValue;
  final String? frameCode;
  final String? frameColor;

  bool get isBot => id.startsWith('bot:');

  factory UnoPlayerView.fromJson(Map<String, dynamic> json) {
    final hand = _models(
      json['hand'],
      UnoCard.fromJson,
    );
    return UnoPlayerView(
      id: (_pick(json, 'user_id', 'userId') ?? json['id'] ?? '').toString(),
      seat: (json['seat'] as num?)?.toInt() ?? 0,
      hand: hand,
      handCount: (_pick(json, 'hand_count', 'handCount') as num?)?.toInt() ??
          hand.length,
      score: (json['score'] as num?)?.toInt() ?? 0,
      saidUno: _pick(json, 'said_uno', 'saidUno') == true,
      forfeited: json['forfeited'] == true,
      displayName: _pick(json, 'display_name', 'displayName')?.toString(),
      avatarKind:
          (_pick(json, 'avatar_kind', 'avatarKind') ?? 'letter').toString(),
      avatarValue: _pick(json, 'avatar_value', 'avatarValue')?.toString(),
      frameCode: _pick(json, 'frame_code', 'frameCode')?.toString(),
      frameColor: _pick(json, 'frame_color', 'frameColor')?.toString(),
    );
  }
}

class UnoGameView {
  const UnoGameView({
    required this.id,
    required this.lobbyId,
    required this.players,
    required this.topDiscard,
    required this.drawCount,
    required this.currentColor,
    required this.direction,
    required this.currentIndex,
    required this.currentUserId,
    required this.myIndex,
    required this.status,
    required this.pendingDraw,
    required this.drawnCardId,
    required this.lastPlayedBy,
    required this.roundNumber,
    required this.targetScore,
    required this.winnerUserIds,
    required this.eliminatedOrder,
    required this.canChallengeUno,
    required this.canChallengeWd4,
    required this.mustChooseColor,
    required this.canKeepOrPlayDrawn,
    this.chatId,
    this.turnTimeSec = 0,
    this.turnDeadline = 0,
    this.stakeBronze = 0,
    this.isForfeit = false,
    this.isTimeout = false,
    this.eventSeq = 0,
    this.lastEventType = '',
    this.lastEventActor = '',
    this.lastDrawUserId = '',
    this.lastDrawCount = 0,
    this.lastEventCard,
  });

  final String id;
  final String lobbyId;
  final String? chatId;
  final List<UnoPlayerView> players;
  final UnoCard? topDiscard;
  final int drawCount;
  final UnoColor currentColor;
  final int direction;
  final int currentIndex;
  final String currentUserId;
  final int myIndex;
  final String status;
  final int pendingDraw;
  final String? drawnCardId;
  final String? lastPlayedBy;
  final int roundNumber;
  final int targetScore;
  final List<String> winnerUserIds;
  final List<String> eliminatedOrder;
  final bool canChallengeUno;
  final bool canChallengeWd4;
  final bool mustChooseColor;
  final bool canKeepOrPlayDrawn;
  final int turnTimeSec;
  final int turnDeadline;
  final int stakeBronze;
  final bool isForfeit;
  final bool isTimeout;
  final int eventSeq;
  final String lastEventType;
  final String lastEventActor;
  final String lastDrawUserId;
  final int lastDrawCount;
  final UnoCard? lastEventCard;

  bool get isOver => status == 'over';
  bool get isMyTurn =>
      !isOver && myIndex >= 0 && currentIndex == myIndex && !iAmEliminated;
  bool get iAmEliminated => me?.forfeited == true;
  bool get iWon =>
      myIndex >= 0 && winnerUserIds.contains(players[myIndex].id);
  UnoPlayerView? get me =>
      myIndex >= 0 && myIndex < players.length ? players[myIndex] : null;
  List<UnoCard> get myHand => me?.hand ?? const [];

  factory UnoGameView.fromJson(Map<String, dynamic> source) {
    final wrapped = source['game'];
    final json = wrapped is Map
        ? <String, dynamic>{
            ...source,
            ...wrapped.cast<String, dynamic>(),
          }
        : source;
    final players = _models(json['players'], UnoPlayerView.fromJson);
    var myIndex = (_pick(json, 'my_index', 'myIndex') as num?)?.toInt() ?? -1;
    if (myIndex < 0) {
      myIndex = players.indexWhere((player) => player.hand.isNotEmpty);
    }
    final topRaw = _pick(json, 'top_discard', 'topDiscard');
    return UnoGameView(
      id: (json['id'] ?? json['game_id'] ?? source['game_id'] ?? '').toString(),
      lobbyId: (_pick(json, 'lobby_id', 'lobbyId') ?? source['lobby_id'] ?? '')
          .toString(),
      chatId: _pick(json, 'chat_id', 'chatId')?.toString(),
      players: players,
      topDiscard: topRaw is Map
          ? UnoCard.fromJson(topRaw.cast<String, dynamic>())
          : null,
      drawCount: (_pick(json, 'draw_count', 'drawCount') as num?)?.toInt() ?? 0,
      currentColor:
          UnoColor.parse(_pick(json, 'current_color', 'currentColor')),
      direction: (json['direction'] as num?)?.toInt() ?? 1,
      currentIndex:
          (_pick(json, 'current_index', 'currentIndex') as num?)?.toInt() ?? -1,
      currentUserId:
          (_pick(json, 'current_user_id', 'currentUserId') ?? '').toString(),
      myIndex: myIndex,
      status: (json['status'] ?? 'active').toString(),
      pendingDraw:
          (_pick(json, 'pending_draw', 'pendingDraw') as num?)?.toInt() ?? 0,
      drawnCardId: _pick(json, 'drawn_card_id', 'drawnCardId')?.toString(),
      lastPlayedBy: _pick(json, 'last_played_by', 'lastPlayedBy')?.toString(),
      roundNumber:
          (_pick(json, 'round_number', 'roundNumber') as num?)?.toInt() ?? 1,
      targetScore:
          (_pick(json, 'target_score', 'targetScore') as num?)?.toInt() ?? 100,
      winnerUserIds: (_pick(json, 'winner_user_ids', 'winnerUserIds') as List?)
              ?.map((id) => id.toString())
              .toList() ??
          const [],
      eliminatedOrder:
          (_pick(json, 'eliminated_order', 'eliminatedOrder') as List?)
                  ?.map((id) => id.toString())
                  .toList() ??
              const [],
      canChallengeUno:
          _pick(json, 'can_challenge_uno', 'canChallengeUno') == true,
      canChallengeWd4:
          _pick(json, 'can_challenge_wd4', 'canChallengeWd4') == true,
      mustChooseColor:
          _pick(json, 'must_choose_color', 'mustChooseColor') == true,
      canKeepOrPlayDrawn:
          _pick(json, 'can_keep_or_play_drawn', 'canKeepOrPlayDrawn') == true,
      turnTimeSec:
          (_pick(json, 'turn_time_sec', 'turnTimeSec') as num?)?.toInt() ?? 0,
      turnDeadline:
          (_pick(json, 'turn_deadline', 'turnDeadline') as num?)?.toInt() ?? 0,
      stakeBronze:
          (_pick(json, 'stake_bronze', 'stakeBronze') as num?)?.toInt() ?? 0,
      isForfeit: _pick(json, 'is_forfeit', 'isForfeit') == true,
      isTimeout: _pick(json, 'is_timeout', 'isTimeout') == true,
      eventSeq: (_pick(json, 'event_seq', 'eventSeq') as num?)?.toInt() ?? 0,
      lastEventType:
          (_pick(json, 'last_event_type', 'lastEventType') ?? '').toString(),
      lastEventActor:
          (_pick(json, 'last_event_actor', 'lastEventActor') ?? '').toString(),
      lastDrawUserId:
          (_pick(json, 'last_draw_user_id', 'lastDrawUserId') ?? '').toString(),
      lastDrawCount:
          (_pick(json, 'last_draw_count', 'lastDrawCount') as num?)?.toInt() ??
              0,
      lastEventCard: () {
        final raw = _pick(json, 'last_event_card', 'lastEventCard');
        if (raw is Map) {
          return UnoCard.fromJson(raw.cast<String, dynamic>());
        }
        return null;
      }(),
    );
  }
}

class UnoLobbyView {
  const UnoLobbyView({
    required this.id,
    required this.creatorId,
    required this.status,
    required this.mode,
    required this.maxPlayers,
    required this.turnTimeSec,
    required this.stakeBronze,
    required this.playerIds,
    required this.players,
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
  final String? chatId;
  final String? gameId;

  factory UnoLobbyView.fromJson(Map<String, dynamic> json) {
    final ids =
        (json['player_ids'] as List?)?.map((id) => id.toString()).toList() ??
            const <String>[];
    final parsed = _models(
      json['players'],
      (item) => LobbyPlayer.fromJson(item),
    );
    return UnoLobbyView(
      id: (json['id'] ?? json['lobby_id'] ?? '').toString(),
      creatorId: (json['creator_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      mode: (json['mode'] ?? 'invite').toString(),
      maxPlayers: (json['max_players'] as num?)?.toInt() ?? 2,
      turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
      stakeBronze: (json['stake_bronze'] as num?)?.toInt() ?? 2,
      playerIds: ids,
      players: parsed.isNotEmpty
          ? parsed
          : [for (final id in ids) LobbyPlayer(id: id, displayName: '')],
      chatId: json['chat_id']?.toString(),
      gameId: json['game_id']?.toString(),
    );
  }
}

class UnoLobbySummary {
  const UnoLobbySummary({
    required this.lobbyId,
    required this.creatorId,
    required this.status,
    required this.maxPlayers,
    required this.turnTimeSec,
    required this.stakeBronze,
    required this.playersCount,
  });

  final String lobbyId;
  final String creatorId;
  final String status;
  final int maxPlayers;
  final int turnTimeSec;
  final int stakeBronze;
  final int playersCount;

  factory UnoLobbySummary.fromJson(Map<String, dynamic> json) =>
      UnoLobbySummary(
        lobbyId: (json['lobby_id'] ?? '').toString(),
        creatorId: (json['creator_id'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        maxPlayers: (json['max_players'] as num?)?.toInt() ?? 2,
        turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
        stakeBronze: (json['stake_bronze'] as num?)?.toInt() ?? 2,
        playersCount: (json['players_count'] as num?)?.toInt() ?? 0,
      );
}

class UnoCreateResult {
  const UnoCreateResult({
    required this.lobbyId,
    this.gameId,
    this.status = '',
    this.matched = false,
  });

  final String lobbyId;
  final String? gameId;
  final String status;
  final bool matched;

  factory UnoCreateResult.fromJson(Map<String, dynamic> json) =>
      UnoCreateResult(
        lobbyId: (json['lobby_id'] ?? '').toString(),
        gameId: json['game_id']?.toString(),
        status: (json['status'] ?? '').toString(),
        matched: json['matched'] == true,
      );
}

class UnoJoinResult {
  const UnoJoinResult({
    required this.joined,
    this.gameId,
    this.lobbyId,
    this.waitingMore = false,
  });

  final bool joined;
  final String? gameId;
  final String? lobbyId;
  final bool waitingMore;

  factory UnoJoinResult.fromJson(Map<String, dynamic> json) => UnoJoinResult(
        joined: json['joined'] == true,
        gameId: json['game_id']?.toString(),
        lobbyId: json['lobby_id']?.toString(),
        waitingMore: json['waiting_more'] == true,
      );
}

class UnoRepository {
  UnoRepository({required AuthRepository authRepository})
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

  Future<UnoCreateResult> createLobby({
    required String mode,
    required int maxPlayers,
    required int turnTimeSec,
    required int stakeBronze,
    bool addBotsAfter30s = false,
  }) async {
    final response = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/uno/lobby'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'mode': mode,
            'max_players': maxPlayers,
            'turn_time_sec': turnTimeSec,
            'stake_bronze': stakeBronze,
            'add_bots_after_30s': addBotsAfter30s,
          }),
          operation: 'UnoRepository.createLobby',
        ));
    if (response.statusCode != 200 && response.statusCode != 201) {
      _fail(response);
    }
    return UnoCreateResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<UnoLobbySummary>> listLobbies() async {
    final response = await _sendAuth((token) => ApiClient.get(
          Uri.parse('$apiBaseUrl/api/games/uno/lobbies'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'UnoRepository.listLobbies',
        ));
    if (response.statusCode != 200) _fail(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return _models(body['lobbies'], UnoLobbySummary.fromJson);
  }

  Future<UnoLobbyView> getLobby(String lobbyId) async {
    final response = await _sendAuth((token) => ApiClient.get(
          Uri.parse('$apiBaseUrl/api/games/uno/lobby/$lobbyId'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'UnoRepository.getLobby',
        ));
    if (response.statusCode != 200) _fail(response);
    return UnoLobbyView.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<UnoJoinResult> joinLobby(String lobbyId) async {
    final response = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/uno/lobby/$lobbyId/join'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'UnoRepository.joinLobby',
        ));
    if (response.statusCode != 200) _fail(response);
    return UnoJoinResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> leaveLobby(String lobbyId) =>
      _emptyPost('/api/games/uno/lobby/$lobbyId/leave', 'leaveLobby');

  Future<void> declineLobby(String lobbyId) =>
      _emptyPost('/api/games/uno/lobby/$lobbyId/decline', 'declineLobby');

  Future<void> inviteFriend(String lobbyId, String friendUserId) => _jsonPost(
        '/api/games/uno/lobby/$lobbyId/invite',
        {'friend_user_id': friendUserId},
        'inviteFriend',
      );

  Future<void> cancelInvite(String lobbyId, String friendUserId) => _jsonPost(
        '/api/games/uno/lobby/$lobbyId/cancel-invite',
        {'friend_user_id': friendUserId},
        'cancelInvite',
      );

  Future<UnoGameView> getGame(String gameId) async {
    if (OfflineUnoRegistry.instance.isOffline(gameId)) {
      final session = OfflineUnoRegistry.instance.get(gameId);
      if (session == null) throw GamesException(404, 'offline game not found');
      return session.view;
    }
    final response = await _sendAuth((token) => ApiClient.get(
          Uri.parse('$apiBaseUrl/api/games/uno/game/$gameId'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'UnoRepository.getGame',
        ));
    if (response.statusCode != 200) _fail(response);
    return UnoGameView.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> move(
    String gameId, {
    required String type,
    String? cardId,
    UnoColor? color,
    String? targetUserId,
  }) async {
    if (OfflineUnoRegistry.instance.isOffline(gameId)) {
      final session = OfflineUnoRegistry.instance.get(gameId);
      if (session == null) throw GamesException(404, 'offline game not found');
      await session.applyMove(
        type: type,
        cardId: cardId,
        color: color,
        targetUserId: targetUserId,
      );
      return;
    }
    final body = <String, dynamic>{'type': type};
    if (cardId != null) body['cardId'] = cardId;
    if (color != null) body['color'] = color.wireName;
    if (targetUserId != null) body['targetUserId'] = targetUserId;
    await _jsonPost(
      '/api/games/uno/game/$gameId/move',
      body,
      'move',
    );
  }

  Future<String> rematch(String gameId) async {
    if (OfflineUnoRegistry.instance.isOffline(gameId)) {
      final session = OfflineUnoRegistry.instance.get(gameId);
      if (session == null) throw GamesException(404, 'offline game not found');
      session.restart();
      return '';
    }
    final response = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/uno/rematch'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'game_id': gameId}),
          operation: 'UnoRepository.rematch',
        ));
    if (response.statusCode != 200) _fail(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['lobby_id'] ?? '').toString();
  }

  Future<void> forfeit(String gameId) async {
    if (OfflineUnoRegistry.instance.isOffline(gameId)) {
      final session = OfflineUnoRegistry.instance.get(gameId);
      if (session == null) throw GamesException(404, 'offline game not found');
      await session.forfeit();
      return;
    }
    await _emptyPost('/api/games/uno/game/$gameId/forfeit', 'forfeit');
  }

  Future<void> _emptyPost(String path, String operation) async {
    final response = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl$path'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'UnoRepository.$operation',
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
          operation: 'UnoRepository.$operation',
        ));
    if (response.statusCode != 200 && response.statusCode != 204) {
      _fail(response);
    }
  }
}
