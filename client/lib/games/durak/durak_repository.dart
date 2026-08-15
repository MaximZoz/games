import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/games/durak/durak_offline_session.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException, LobbyPlayer;

/// Модель карты в JSON API. Ранг [2..14], масть — одна буква H/D/C/S.
class DurakApiCard {
  const DurakApiCard(this.rank, this.suit);
  final int rank;
  final String suit; // H/D/C/S

  Map<String, dynamic> toJson() => {'rank': rank, 'suit': suit};

  static DurakApiCard fromJson(Map<String, dynamic> json) => DurakApiCard(
        (json['rank'] as num).toInt(),
        (json['suit'] ?? '').toString(),
      );

  PlayingCard toPlayingCard() {
    // Сервер шлёт "H"/"D"/"C"/"S"; legacy мог слать "0".."3".
    final s = switch (suit.toUpperCase().trim()) {
      'H' || '0' => Suit.hearts,
      'D' || '1' => Suit.diamonds,
      'C' || '2' => Suit.clubs,
      'S' || '3' => Suit.spades,
      _ => Suit.spades, // не маскируем ошибку под все ♥
    };
    return PlayingCard(Rank(rank), s);
  }

  static DurakApiCard fromCard(PlayingCard c) {
    final s = switch (c.suit) {
      Suit.hearts => 'H',
      Suit.diamonds => 'D',
      Suit.clubs => 'C',
      Suit.spades => 'S',
    };
    return DurakApiCard(c.rank.value, s);
  }
}

/// Пара на столе: атака + опционально защита.
class DurakTablePairApi {
  const DurakTablePairApi({required this.attack, this.defense});
  final DurakApiCard attack;
  final DurakApiCard? defense;

  factory DurakTablePairApi.fromJson(Map<String, dynamic> json) {
    return DurakTablePairApi(
      attack: DurakApiCard.fromJson(json['attack'] as Map<String, dynamic>),
      defense: json['defense'] == null
          ? null
          : DurakApiCard.fromJson(json['defense'] as Map<String, dynamic>),
    );
  }
}

/// Рука (для себя — карты, для соперников — только count).
class DurakHandView {
  const DurakHandView({required this.count, this.cards});
  final int count;
  final List<DurakApiCard>? cards;

  bool get isMine => cards != null;

  factory DurakHandView.fromJson(Map<String, dynamic> json) {
    final list = json['cards'];
    return DurakHandView(
      count: (json['count'] as num?)?.toInt() ?? 0,
      cards: list is List
          ? list
              .whereType<Map>()
              .map((e) => DurakApiCard.fromJson(e.cast<String, dynamic>()))
              .toList()
          : null,
    );
  }
}

/// Метаданные игрока в партии (имя, аватар, рамка).
class DurakPlayerMeta {
  const DurakPlayerMeta({
    required this.id,
    this.displayName,
    this.avatarKind = 'letter',
    this.avatarValue,
    this.frameCode,
    this.frameColor,
  });

  final String id;
  final String? displayName;
  final String avatarKind;
  final String? avatarValue;
  final String? frameCode;
  final String? frameColor;

  factory DurakPlayerMeta.fromJson(Map<String, dynamic> json) {
    return DurakPlayerMeta(
      id: (json['id'] ?? '').toString(),
      displayName: (json['display_name'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['display_name'] as String).trim(),
      avatarKind: (json['avatar_kind'] ?? 'letter').toString(),
      avatarValue: json['avatar_value']?.toString(),
      frameCode: json['frame_code']?.toString(),
      frameColor: json['frame_color']?.toString(),
    );
  }
}

/// Полный view одного игрока — то что возвращает GET /api/games/durak/game/:id.
class DurakGameView {
  const DurakGameView({
    required this.id,
    required this.status,
    required this.lobbyId,
    required this.chatId,
    required this.mode,
    required this.deckSize,
    required this.playerIds,
    required this.players,
    required this.hands,
    required this.deckCount,
    required this.trumpSuit,
    required this.trumpCard,
    required this.table,
    required this.bitoCount,
    required this.attackerIndex,
    required this.defenderIndex,
    required this.phase,
    required this.myIndex,
    required this.legalAttack,
    required this.legalDefend,
    required this.loserIndex,
    required this.finished,
    this.eliminated = const [],
    required this.turnTimeSec,
    required this.turnDeadline,
    required this.stakeBronze,
    this.legalTransfer = const [],
    this.canThrowIn = false,
    this.throwerIndex = -1,
    this.turnActorIdx = -1,
    this.isDraw = false,
    this.isForfeit = false,
    this.isTimeout = false,
    this.drawOfferBy = '',
    this.lastWasTake = false,
    this.firstRound = false,
    this.tiedLeaders = 0,
    this.leadTrump,
  });

  final String id;
  final String status;
  final String lobbyId;
  final String? chatId;
  final String mode;
  final int deckSize;
  final List<String> playerIds;
  final List<DurakPlayerMeta> players;
  final List<DurakHandView> hands;
  final int deckCount;
  final String trumpSuit;
  final DurakApiCard trumpCard;
  final List<DurakTablePairApi> table;
  final int bitoCount;
  final int attackerIndex;
  final int defenderIndex;
  final String phase;
  final int myIndex;
  final List<DurakApiCard> legalAttack;
  final List<DurakApiCard> legalDefend;

  /// Карты для перевода (переводной); пусто, если у следующего мало карт.
  final List<DurakApiCard> legalTransfer;

  /// Можно подкинуть сейчас (очередь thrower; при 4 — только соседи).
  final bool canThrowIn;

  /// Кто сейчас в очереди подкида / «Бито».
  final int throwerIndex;

  /// Чей таймер хода (рамка на аватаре).
  final int turnActorIdx;
  final int loserIndex;
  final List<int> finished;

  /// Сдались / выбыли (наблюдатели) — без доли банка.
  final List<int> eliminated;
  final int turnTimeSec;
  final int turnDeadline;
  final int stakeBronze;

  /// Последнее действие раунда — «взять» (для FX соперника).
  final bool lastWasTake;

  /// Первый отбой партии — лимит 5 карт на столе.
  final bool firstRound;

  /// Младший козырь атакующего (первый ход), пока стол пуст.
  final DurakApiCard? leadTrump;

  /// Ничья лидеров: банк 1/2/3 мест делится поровну между ними.
  final int tiedLeaders;

  /// Партия завершена соглашением на ничью.
  final bool isDraw;

  /// Партия завершена сдачей.
  final bool isForfeit;

  /// Партия завершена по таймауту хода.
  final bool isTimeout;

  /// user_id того, кто предложил ничью (пусто — предложения нет).
  final String drawOfferBy;

  bool get isOver => status != 'active';

  bool isEliminated(int idx) => eliminated.contains(idx);

  bool get iAmEliminated => myIndex >= 0 && isEliminated(myIndex);

  /// Места победителей по порядку выхода (finished), затем оставшиеся не-дураки.
  /// После сдач последний с картами занимает следующее оплачиваемое место.
  List<int> get winnerPlaceOrder {
    final n = playerIds.length;
    final seen = <int>{};
    final out = <int>[];
    for (final i in finished) {
      if (i < 0 || i >= n) continue;
      if (i == loserIndex || isEliminated(i) || seen.contains(i)) continue;
      seen.add(i);
      out.add(i);
    }
    for (var i = 0; i < n; i++) {
      if (i == loserIndex || isEliminated(i) || seen.contains(i)) continue;
      out.add(i);
      seen.add(i);
    }
    if (eliminated.isNotEmpty &&
        loserIndex >= 0 &&
        loserIndex < n &&
        !isEliminated(loserIndex) &&
        !seen.contains(loserIndex)) {
      out.add(loserIndex);
    }
    return out;
  }

  bool get iAmFinished => myIndex >= 0 && finished.contains(myIndex);

  /// Место текущего игрока (1-е, 2-е, …) или 0, если дурак/сдался/не в списке.
  /// После выхода «в ноль» — сразу по порядку finished, не дожидаясь конца партии.
  int get myPlace {
    if (iAmEliminated || myIndex < 0) return 0;
    // Пока партия идёт: место = порядок выхода «в ноль».
    if (!isOver && iAmFinished) {
      final fi = finished.indexOf(myIndex);
      return fi < 0 ? 0 : fi + 1;
    }
    if (!isOver || isDraw) return 0;
    final order = winnerPlaceOrder;
    final idx = order.indexOf(myIndex);
    return idx < 0 ? 0 : idx + 1;
  }

  /// Пауза после полного отбоя, когда подкидывать нечего (стол ещё на экране).
  bool get isBitoReveal => phase == 'bito_reveal';

  /// Пауза перед взятием — стол на экране, затем карты защитнику.
  bool get isTakeReveal => phase == 'take_reveal';

  /// Пауза показа стола (бито или перед взятием).
  bool get isTableReveal => isBitoReveal || isTakeReveal;

  /// Чей сейчас «ход по таймеру» (защитник бьёт / атакующий кладёт / вдогонку).
  bool get isMyTurn {
    if (isOver || iAmEliminated || iAmFinished || isTableReveal) return false;
    if (turnActorIdx >= 0) return turnActorIdx == myIndex;
    if (phase == 'defend') return defenderIndex == myIndex;
    return attackerIndex == myIndex;
  }

  /// Можно ли трогать веер: защита, атака или подкид (в т.ч. сосед при 3–4).
  bool get canAct {
    if (isOver || iAmEliminated || iAmFinished || isTableReveal) return false;
    if (defenderIndex == myIndex && phase == 'defend') return true;
    if (canThrowIn || legalAttack.isNotEmpty) return true;
    if (phase == 'defend') {
      return defenderIndex == myIndex || attackerIndex == myIndex;
    }
    if (phase == 'throw_in') return throwerIndex == myIndex || canThrowIn;
    if (phase == 'take_follow') return attackerIndex == myIndex || canThrowIn;
    return attackerIndex == myIndex;
  }

  DurakPlayerMeta? playerMeta(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  factory DurakGameView.fromJson(Map<String, dynamic> json) {
    List<T> pList<T>(dynamic v, T Function(Map<String, dynamic>) fn) {
      if (v is! List) return const [];
      return v.whereType<Map>().map((e) => fn(e.cast<String, dynamic>())).toList();
    }

    final playerIds = (json['player_ids'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    var players = pList<DurakPlayerMeta>(json['players'], DurakPlayerMeta.fromJson);
    if (players.isEmpty && playerIds.isNotEmpty) {
      players = playerIds.map((id) => DurakPlayerMeta(id: id)).toList();
    }

    final status = (json['status'] ?? 'active').toString();
    final loserIdx = (json['loser_index'] as num?)?.toInt() ?? -1;
    final isForfeit = json['forfeit'] == true;
    final isTimeout = json['timeout'] == true;
    // Ничья: флаг draw или оба вышли (нет дурака).
    final isDraw = json['draw'] == true ||
        (status != 'active' && !isForfeit && !isTimeout && loserIdx < 0);

    return DurakGameView(
      id: (json['id'] ?? '').toString(),
      status: status,
      lobbyId: (json['lobby_id'] ?? '').toString(),
      chatId: (json['chat_id']?.toString().trim().isEmpty ?? true)
          ? null
          : json['chat_id'].toString(),
      mode: (json['mode'] ?? 'podkidnoi').toString(),
      deckSize: (json['deck_size'] as num?)?.toInt() ?? 36,
      playerIds: playerIds,
      players: players,
      hands: pList<DurakHandView>(json['hands'], DurakHandView.fromJson),
      deckCount: (json['deck_count'] as num?)?.toInt() ?? 0,
      trumpSuit: (json['trump'] ?? 'H').toString(),
      trumpCard: DurakApiCard.fromJson(
          (json['trump_card'] as Map).cast<String, dynamic>()),
      table: pList<DurakTablePairApi>(json['table'], DurakTablePairApi.fromJson),
      bitoCount: (json['bito_count'] as num?)?.toInt() ?? 0,
      attackerIndex: (json['attacker_index'] as num?)?.toInt() ?? 0,
      defenderIndex: (json['defender_index'] as num?)?.toInt() ?? 0,
      phase: (json['phase'] ?? 'attack').toString(),
      myIndex: (json['my_index'] as num?)?.toInt() ?? -1,
      legalAttack: (json['legal_attack'] as List?)
              ?.whereType<Map>()
              .map((e) => DurakApiCard.fromJson(e.cast<String, dynamic>()))
              .toList() ??
          const [],
      legalDefend: (json['legal_defend'] as List?)
              ?.whereType<Map>()
              .map((e) => DurakApiCard.fromJson(e.cast<String, dynamic>()))
              .toList() ??
          const [],
      legalTransfer: (json['legal_transfer'] as List?)
              ?.whereType<Map>()
              .map((e) => DurakApiCard.fromJson(e.cast<String, dynamic>()))
              .toList() ??
          const [],
      canThrowIn: json['can_throw_in'] == true,
      throwerIndex: (json['thrower_index'] as num?)?.toInt() ?? -1,
      turnActorIdx: (json['turn_actor_idx'] as num?)?.toInt() ?? -1,
      loserIndex: loserIdx,
      finished: (json['finished'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      eliminated: (json['eliminated'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      tiedLeaders: (json['tied_leaders'] as num?)?.toInt() ?? 0,
      turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
      turnDeadline: (json['turn_deadline'] as num?)?.toInt() ?? 0,
      stakeBronze: (json['stake_bronze'] as num?)?.toInt() ?? 2,
      isDraw: isDraw,
      isForfeit: isForfeit,
      isTimeout: isTimeout,
      drawOfferBy: (json['draw_offer_by'] ?? '').toString(),
      lastWasTake: json['last_was_take'] == true,
      firstRound: json['first_round'] == true,
      leadTrump: json['lead_trump'] is Map
          ? DurakApiCard.fromJson(
              (json['lead_trump'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }
}

class DurakLobbyView {
  const DurakLobbyView({
    required this.id,
    required this.creatorId,
    required this.status,
    required this.mode,
    required this.maxPlayers,
    required this.deckSize,
    required this.gameMode,
    required this.turnTimeSec,
    required this.stakeBronze,
    required this.playerIds,
    required this.players,
    required this.chatId,
    this.gameId,
  });

  final String id;
  final String creatorId;
  final String status;
  final String mode;
  final int maxPlayers;
  final int deckSize;
  final String gameMode;
  final int turnTimeSec;
  final int stakeBronze;
  final List<String> playerIds;

  /// Мета участников (аватар/имя) — как в крестиках-ноликах.
  final List<LobbyPlayer> players;
  final String? chatId;
  final String? gameId;

  factory DurakLobbyView.fromJson(Map<String, dynamic> json) {
    final ids = (json['player_ids'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final parsedPlayers = (json['players'] as List?)
            ?.whereType<Map>()
            .map((e) => LobbyPlayer.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <LobbyPlayer>[];
    // Fallback: только id, если сервер не прислал metas.
    final players = parsedPlayers.isNotEmpty
        ? parsedPlayers
        : [
            for (final id in ids)
              LobbyPlayer(id: id, displayName: 'Player'),
          ];
    return DurakLobbyView(
      id: (json['id'] ?? json['lobby_id'] ?? '').toString(),
      creatorId: (json['creator_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      mode: (json['mode'] ?? 'invite').toString(),
      maxPlayers: (json['max_players'] as num?)?.toInt() ?? 2,
      deckSize: (json['deck_size'] as num?)?.toInt() ?? 36,
      gameMode: (json['game_mode'] ?? 'podkidnoi').toString(),
      turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
      stakeBronze: (json['stake_bronze'] as num?)?.toInt() ?? 2,
      playerIds: ids,
      players: players,
      chatId: (json['chat_id']?.toString().trim().isEmpty ?? true)
          ? null
          : json['chat_id'].toString(),
      gameId: (json['game_id']?.toString().trim().isEmpty ?? true)
          ? null
          : json['game_id'].toString(),
    );
  }
}

class DurakCreateLobbyResult {
  DurakCreateLobbyResult({
    required this.lobbyId,
    this.gameId,
    this.status = '',
  });

  /// Может быть пустым, если сервер сразу подключил к чужому лобби и вернул
  /// только `game_id` — тогда роутим в партию.
  final String lobbyId;
  final String? gameId;
  final String status;

  factory DurakCreateLobbyResult.fromJson(Map<String, dynamic> json) {
    return DurakCreateLobbyResult(
      lobbyId: (json['lobby_id'] ?? '').toString().trim(),
      gameId: (json['game_id']?.toString().trim().isEmpty ?? true)
          ? null
          : json['game_id'].toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class DurakJoinResult {
  DurakJoinResult({
    required this.joined,
    this.gameId,
    this.lobbyId,
    this.waitingMore = false,
    this.playersCount = 0,
    this.maxPlayers = 0,
  });
  final bool joined;
  final String? gameId;
  final String? lobbyId;
  final bool waitingMore;
  final int playersCount;
  final int maxPlayers;

  factory DurakJoinResult.fromJson(Map<String, dynamic> json) {
    return DurakJoinResult(
      joined: json['joined'] == true,
      gameId: (json['game_id']?.toString().trim().isEmpty ?? true)
          ? null
          : json['game_id'].toString(),
      lobbyId: (json['lobby_id']?.toString().trim().isEmpty ?? true)
          ? null
          : json['lobby_id'].toString(),
      waitingMore: json['waiting_more'] == true,
      playersCount: (json['players_count'] as num?)?.toInt() ?? 0,
      maxPlayers: (json['max_players'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Клиент API для «Дурака». Всё под `/api/games/durak/*`.
class DurakRepository {
  DurakRepository({required AuthRepository authRepository})
      : _auth = authRepository;

  final AuthRepository _auth;

  Future<http.Response> _sendAuth(
      Future<http.Response> Function(String token) fn) async {
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
    final l10n = LocaleService.l10n;
    final keyLower = key.toLowerCase();
    final msgLower = msg.toLowerCase();
    if (r.statusCode == 402) {
      throw GamesException(
        402,
        msg.trim().isEmpty ? l10n.commonInsufficientCoins : msg.trim(),
        errorKey: key,
      );
    }
    if (r.statusCode == 502 ||
        r.statusCode == 503 ||
        keyLower.contains('temporarily unavailable') ||
        msgLower.contains('temporarily unavailable')) {
      throw GamesException(
        r.statusCode == 0 ? 503 : r.statusCode,
        l10n.commonTryLater,
        errorKey: key.isEmpty ? 'temporarily unavailable' : key,
      );
    }
    if (msg.isEmpty) msg = l10n.commonServerErrorShort;
    throw GamesException(r.statusCode, msg, errorKey: key);
  }

  Future<DurakCreateLobbyResult> createLobby({
    required String mode, // 'invite' | 'matchmake'
    required int maxPlayers,
    required int deckSize,
    required String gameMode,
    required int turnTimeSec,
    required int stakeBronze,
  }) async {
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/durak/lobby'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'mode': mode,
            'max_players': maxPlayers,
            'deck_size': deckSize,
            'game_mode': gameMode,
            'turn_time_sec': turnTimeSec,
            'stake_bronze': stakeBronze,
          }),
          operation: 'DurakRepository.createLobby',
        ));
    if (r.statusCode != 200 && r.statusCode != 201) _fail(r);
    return DurakCreateLobbyResult.fromJson(
        jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<List<DurakLobbyView>> listLobbies() async {
    final r = await _sendAuth((token) => ApiClient.get(
          Uri.parse('$apiBaseUrl/api/games/durak/lobbies'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'DurakRepository.listLobbies',
        ));
    if (r.statusCode != 200) _fail(r);
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (body['lobbies'] as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => DurakLobbyView.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<DurakLobbyView> getLobby(String lobbyId) async {
    final r = await _sendAuth((token) => ApiClient.get(
          Uri.parse('$apiBaseUrl/api/games/durak/lobby/$lobbyId'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'DurakRepository.getLobby',
        ));
    if (r.statusCode != 200) _fail(r);
    return DurakLobbyView.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<DurakJoinResult> joinLobby(String lobbyId) async {
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/durak/lobby/$lobbyId/join'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'DurakRepository.joinLobby',
        ));
    if (r.statusCode != 200) _fail(r);
    return DurakJoinResult.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<void> leaveLobby(String lobbyId) async {
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/durak/lobby/$lobbyId/leave'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'DurakRepository.leaveLobby',
        ));
    if (r.statusCode != 200) _fail(r);
  }

  Future<void> declineLobby(String lobbyId) async {
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/durak/lobby/$lobbyId/decline'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'DurakRepository.declineLobby',
        ));
    if (r.statusCode != 200) _fail(r);
  }

  Future<void> inviteFriend(String lobbyId, String friendUserId) async {
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/durak/lobby/$lobbyId/invite'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'friend_user_id': friendUserId}),
          operation: 'DurakRepository.inviteFriend',
        ));
    if (r.statusCode != 200) _fail(r);
  }

  Future<void> cancelInvite(String lobbyId, String friendUserId) async {
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse(
              '$apiBaseUrl/api/games/durak/lobby/$lobbyId/cancel-invite'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'friend_user_id': friendUserId}),
          operation: 'DurakRepository.cancelInvite',
        ));
    if (r.statusCode != 200) _fail(r);
  }

  Future<DurakGameView> getGame(String gameId) async {
    if (OfflineDurakRegistry.instance.isOffline(gameId)) {
      final session = OfflineDurakRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      return session.view;
    }
    final r = await _sendAuth((token) => ApiClient.get(
          Uri.parse('$apiBaseUrl/api/games/durak/game/$gameId'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'DurakRepository.getGame',
        ));
    if (r.statusCode != 200) _fail(r);
    return DurakGameView.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<void> move(
    String gameId, {
    required String type,
    PlayingCard? card,
    List<PlayingCard>? cards,
    int? pairIndex,
  }) async {
    if (OfflineDurakRegistry.instance.isOffline(gameId)) {
      final session = OfflineDurakRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      await session.applyMove(
        type: type,
        card: card,
        cards: cards,
        pairIndex: pairIndex,
      );
      return;
    }
    final body = <String, dynamic>{'type': type};
    if (cards != null && cards.isNotEmpty) {
      body['cards'] =
          cards.map((c) => DurakApiCard.fromCard(c).toJson()).toList();
    } else if (card != null) {
      body['card'] = DurakApiCard.fromCard(card).toJson();
    }
    if (pairIndex != null) {
      body['pair_index'] = pairIndex;
    }
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/durak/game/$gameId/move'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
          operation: 'DurakRepository.move',
        ));
    if (r.statusCode != 200) _fail(r);
  }

  Future<void> offerDraw(String gameId) async {
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/durak/game/$gameId/draw-offer'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'DurakRepository.offerDraw',
        ));
    if (r.statusCode != 200) _fail(r);
  }

  Future<void> acceptDraw(String gameId) async {
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/durak/game/$gameId/draw-accept'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'DurakRepository.acceptDraw',
        ));
    if (r.statusCode != 200) _fail(r);
  }

  Future<void> forfeit(String gameId) async {
    if (OfflineDurakRegistry.instance.isOffline(gameId)) {
      final session = OfflineDurakRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      await session.forfeit();
      return;
    }
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/durak/game/$gameId/forfeit'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'DurakRepository.forfeit',
        ));
    if (r.statusCode != 200) _fail(r);
  }

  Future<String> rematch(String gameId) async {
    if (OfflineDurakRegistry.instance.isOffline(gameId)) {
      final session = OfflineDurakRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      session.restart();
      return '';
    }
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/durak/rematch'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'game_id': gameId}),
          operation: 'DurakRepository.rematch',
        ));
    if (r.statusCode != 200) _fail(r);
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return (data['lobby_id'] ?? '').toString();
  }

  @override
  int get hashCode => identityHashCode(this);
  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  String toString() => 'DurakRepository';
}

/// Sanity self-check в debug — не даём модели тихо сломаться при рефакторе.
@visibleForTesting
void assertDurakModelsShape() {
  const view = DurakApiCard(6, 'H');
  assert(view.rank == 6);
}
