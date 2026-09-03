import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/games/poker/poker_offline_session.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException, LobbyPlayer;

/// Карта покера в JSON API: ранг [2..14], масть — одна буква H/D/C/S.
class PokerApiCard {
  const PokerApiCard(this.rank, this.suit);
  final int rank;
  final String suit; // H/D/C/S

  Map<String, dynamic> toJson() => {'rank': rank, 'suit': suit};

  static PokerApiCard fromJson(Map<String, dynamic> json) => PokerApiCard(
        (json['rank'] as num).toInt(),
        (json['suit'] ?? '').toString(),
      );

  PlayingCard toPlayingCard() {
    final s = switch (suit.toUpperCase().trim()) {
      'H' || '0' => Suit.hearts,
      'D' || '1' => Suit.diamonds,
      'C' || '2' => Suit.clubs,
      'S' || '3' => Suit.spades,
      _ => Suit.spades,
    };
    return PlayingCard(Rank(rank), s);
  }

  static PokerApiCard fromCard(PlayingCard c) {
    final s = switch (c.suit) {
      Suit.hearts => 'H',
      Suit.diamonds => 'D',
      Suit.clubs => 'C',
      Suit.spades => 'S',
    };
    return PokerApiCard(c.rank.value, s);
  }
}

/// Игрок в партии покера (view из GetPokerGame).
class PokerPlayerView {
  const PokerPlayerView({
    required this.id,
    this.displayName,
    this.avatarKind = 'letter',
    this.avatarValue,
    this.frameCode,
    this.frameColor,
    required this.seat,
    required this.chips,
    required this.bet,
    required this.folded,
    required this.allIn,
    required this.isActing,
    this.shown = false,
    this.holeCards,
  });

  final String id;
  final String? displayName;
  final String avatarKind;
  final String? avatarValue;
  final String? frameCode;
  final String? frameColor;
  final int seat;
  final int chips;
  final int bet;
  final bool folded;
  final bool allIn;
  final bool isActing;
  final bool shown;

  /// Карманные карты: свои всегда; чужие — на showdown или после «Показать».
  final List<PokerApiCard>? holeCards;

  bool get isBot => id.startsWith('bot:');

  factory PokerPlayerView.fromJson(Map<String, dynamic> json) {
    final hole = json['hole_cards'];
    return PokerPlayerView(
      id: (json['id'] ?? '').toString(),
      displayName: (json['display_name'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['display_name'] as String).trim(),
      avatarKind: (json['avatar_kind'] ?? 'letter').toString(),
      avatarValue: json['avatar_value']?.toString(),
      frameCode: json['frame_code']?.toString(),
      frameColor: json['frame_color']?.toString(),
      seat: (json['seat'] as num?)?.toInt() ?? 0,
      chips: (json['chips'] as num?)?.toInt() ?? 0,
      bet: (json['bet'] as num?)?.toInt() ?? 0,
      folded: json['folded'] == true,
      allIn: json['all_in'] == true,
      isActing: json['is_acting'] == true,
      shown: json['shown'] == true,
      holeCards: hole is List
          ? hole
              .whereType<Map>()
              .map((e) => PokerApiCard.fromJson(e.cast<String, dynamic>()))
              .toList()
          : null,
    );
  }
}

/// Лучшая комбинация победителя на вскрытии: место, ранг и 5 карт.
class PokerWinnerHand {
  const PokerWinnerHand({
    required this.seat,
    this.rank,
    this.cards = const [],
  });

  final int seat;
  final String? rank;
  final List<PokerApiCard> cards;

  factory PokerWinnerHand.fromJson(Map<String, dynamic> json) {
    final cards = json['cards'];
    return PokerWinnerHand(
      seat: (json['seat'] as num?)?.toInt() ?? 0,
      rank: (json['rank']?.toString().trim().isEmpty ?? true)
          ? null
          : json['rank'].toString(),
      cards: cards is List
          ? cards
              .whereType<Map>()
              .map((e) => PokerApiCard.fromJson(e.cast<String, dynamic>()))
              .toList()
          : const [],
    );
  }
}

/// Полный view партии покера — GET /api/games/poker/game/:id.
class PokerGameView {
  const PokerGameView({
    required this.id,
    required this.status,
    required this.street,
    required this.lobbyId,
    this.chatId,
    required this.playerIds,
    required this.players,
    required this.community,
    required this.pot,
    required this.currentBet,
    required this.minRaise,
    required this.smallBlind,
    required this.bigBlind,
    required this.dealerIndex,
    required this.actingIndex,
    required this.myIndex,
    required this.legalActions,
    required this.callAmount,
    required this.minRaiseTo,
    required this.maxRaiseTo,
    required this.turnTimeSec,
    required this.turnDeadline,
    required this.stakeBronze,
    required this.winners,
    required this.winnerIds,
    required this.isOver,
    required this.isForfeit,
    required this.isTimeout,
    this.handNumber = 1,
    this.blindLevel = 0,
    this.handsPerLevel = 0,
    this.isHandOver = false,
    this.isTableOver = false,
    this.canShowCards = false,
    this.myPlace = 0,
    this.iAmEliminated = false,
    this.eliminatedOrder = const [],
    this.myHandRank,
    this.myHandCards = const [],
    this.highlightedCards = const [],
    this.winnerHands = const [],
  });

  final String id;
  final String status;
  final String street;
  final String lobbyId;
  final String? chatId;
  final List<String> playerIds;
  final List<PokerPlayerView> players;
  final List<PokerApiCard> community;
  final int pot;
  final int currentBet;
  final int minRaise;
  final int smallBlind;
  final int bigBlind;
  final int dealerIndex;
  final int actingIndex;
  final int myIndex;
  final List<String> legalActions;
  final int callAmount;
  final int minRaiseTo;
  final int maxRaiseTo;
  final int turnTimeSec;
  final int turnDeadline;
  final int stakeBronze;
  final List<int> winners;
  final List<String> winnerIds;
  final bool isOver;
  final bool isForfeit;
  final bool isTimeout;

  // Кэш-стол: прогресс партии, уровни блайндов и подсказки по комбинациям.
  final int handNumber;
  final int blindLevel;
  final int handsPerLevel;
  final bool isHandOver;
  final bool isTableOver;
  /// Победитель фолд-вины может показать карты в паузе перед следующей раздачей.
  final bool canShowCards;
  /// Итоговое место (1 = победитель). 0 — ещё не известно.
  final int myPlace;
  /// Выбыл (0 фишек), стол ещё идёт — режим наблюдателя.
  final bool iAmEliminated;
  final List<String> eliminatedOrder;
  final String? myHandRank;
  final List<PokerApiCard> myHandCards;
  final List<PokerApiCard> highlightedCards;
  final List<PokerWinnerHand> winnerHands;

  /// Свой ход по индексу актёра (кнопки смотрят на [legalActions] отдельно).
  /// Не требуем non-empty legalActions — иначе при рассинхроне оба видят «ход соперника».
  bool get isMyTurn {
    if (isOver ||
        isHandOver ||
        iAmEliminated ||
        myIndex < 0 ||
        myIndex != actingIndex) {
      return false;
    }
    final self = me;
    if (self != null && self.folded) return false;
    return true;
  }

  bool get iWon =>
      myPlace == 1 || (myPlace <= 0 && myIndex >= 0 && winners.contains(myIndex));

  /// Ходы в текущей раздаче завершены (вскрытие/победа), но стол может идти.
  bool get handFinished => isHandOver || isOver;

  /// Contested showdown (полное вскрытие) — не путать с фолд-виной (`street == over`).
  bool get isShowdown => street == 'showdown';

  /// Раздача закончилась без полного вскрытия (все сфолдили).
  bool get isUncontestedWin =>
      isHandOver && street == 'over';

  /// Набор подсвеченных карт (ранг*100+масть-код) для быстрой проверки.
  Set<int> get highlightKeys {
    final source = highlightedCards.isNotEmpty ? highlightedCards : myHandCards;
    return {for (final c in source) _cardKey(c)};
  }

  static int _cardKey(PokerApiCard c) {
    final s = switch (c.suit.toUpperCase().trim()) {
      'H' => 0,
      'D' => 1,
      'C' => 2,
      'S' => 3,
      _ => 4,
    };
    return c.rank * 10 + s;
  }

  static int cardKeyOf(PokerApiCard c) => _cardKey(c);

  bool canDo(String action) => legalActions.contains(action);

  PokerPlayerView? get me =>
      myIndex >= 0 && myIndex < players.length ? players[myIndex] : null;

  factory PokerGameView.fromJson(Map<String, dynamic> json) {
    final playerIds = (json['player_ids'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final players = (json['players'] as List?)
            ?.whereType<Map>()
            .map((e) => PokerPlayerView.fromJson(e.cast<String, dynamic>()))
            .toList() ??
        const <PokerPlayerView>[];
    return PokerGameView(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      street: (json['street'] ?? 'preflop').toString(),
      lobbyId: (json['lobby_id'] ?? '').toString(),
      chatId: (json['chat_id']?.toString().trim().isEmpty ?? true)
          ? null
          : json['chat_id'].toString(),
      playerIds: playerIds,
      players: players,
      community: (json['community'] as List?)
              ?.whereType<Map>()
              .map((e) => PokerApiCard.fromJson(e.cast<String, dynamic>()))
              .toList() ??
          const [],
      pot: (json['pot'] as num?)?.toInt() ?? 0,
      currentBet: (json['current_bet'] as num?)?.toInt() ?? 0,
      minRaise: (json['min_raise'] as num?)?.toInt() ?? 0,
      smallBlind: (json['small_blind'] as num?)?.toInt() ?? 0,
      bigBlind: (json['big_blind'] as num?)?.toInt() ?? 0,
      dealerIndex: (json['dealer_index'] as num?)?.toInt() ?? 0,
      actingIndex: (json['acting_index'] as num?)?.toInt() ?? -1,
      myIndex: (json['my_index'] as num?)?.toInt() ?? -1,
      legalActions: (json['legal_actions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      callAmount: (json['call_amount'] as num?)?.toInt() ?? 0,
      minRaiseTo: (json['min_raise_to'] as num?)?.toInt() ?? 0,
      maxRaiseTo: (json['max_raise_to'] as num?)?.toInt() ?? 0,
      turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
      turnDeadline: (json['turn_deadline'] as num?)?.toInt() ?? 0,
      stakeBronze: (json['stake_bronze'] as num?)?.toInt() ?? 2,
      winners:
          (json['winners'] as List?)?.map((e) => (e as num).toInt()).toList() ??
              const [],
      winnerIds: (json['winner_ids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      // is_over относится ко ВСЕМУ столу (кэш-стол): статус «over» между
      // раздачами не должен показывать rematch — опираемся на явные флаги.
      isOver: json['is_over'] == true || json['is_table_over'] == true,
      isForfeit: json['is_forfeit'] == true,
      isTimeout: json['is_timeout'] == true,
      handNumber: (json['hand_number'] as num?)?.toInt() ?? 1,
      blindLevel: (json['blind_level'] as num?)?.toInt() ?? 0,
      handsPerLevel: (json['hands_per_level'] as num?)?.toInt() ?? 0,
      isHandOver: json['is_hand_over'] == true,
      isTableOver: json['is_table_over'] == true,
      canShowCards: json['can_show_cards'] == true,
      myPlace: (json['my_place'] as num?)?.toInt() ?? 0,
      iAmEliminated: json['i_am_eliminated'] == true,
      eliminatedOrder: (json['eliminated_order'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      myHandRank: (json['my_hand_rank']?.toString().trim().isEmpty ?? true)
          ? null
          : json['my_hand_rank'].toString(),
      myHandCards: (json['my_hand_cards'] as List?)
              ?.whereType<Map>()
              .map((e) => PokerApiCard.fromJson(e.cast<String, dynamic>()))
              .toList() ??
          const [],
      highlightedCards: (json['highlighted_cards'] as List?)
              ?.whereType<Map>()
              .map((e) => PokerApiCard.fromJson(e.cast<String, dynamic>()))
              .toList() ??
          const [],
      winnerHands: (json['winner_hands'] as List?)
              ?.whereType<Map>()
              .map((e) => PokerWinnerHand.fromJson(e.cast<String, dynamic>()))
              .toList() ??
          const [],
    );
  }
}

class PokerLobbyView {
  const PokerLobbyView({
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

  factory PokerLobbyView.fromJson(Map<String, dynamic> json) {
    final ids = (json['player_ids'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final parsedPlayers = (json['players'] as List?)
            ?.whereType<Map>()
            .map((e) => LobbyPlayer.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <LobbyPlayer>[];
    final players = parsedPlayers.isNotEmpty
        ? parsedPlayers
        : [for (final id in ids) LobbyPlayer(id: id, displayName: 'Player')];
    return PokerLobbyView(
      id: (json['id'] ?? json['lobby_id'] ?? '').toString(),
      creatorId: (json['creator_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      mode: (json['mode'] ?? 'invite').toString(),
      maxPlayers: (json['max_players'] as num?)?.toInt() ?? 2,
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

class PokerLobbySummary {
  const PokerLobbySummary({
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

  factory PokerLobbySummary.fromJson(Map<String, dynamic> json) {
    return PokerLobbySummary(
      lobbyId: (json['lobby_id'] ?? '').toString(),
      creatorId: (json['creator_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      maxPlayers: (json['max_players'] as num?)?.toInt() ?? 2,
      turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
      stakeBronze: (json['stake_bronze'] as num?)?.toInt() ?? 2,
      playersCount: (json['players_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class PokerCreateResult {
  PokerCreateResult({
    required this.lobbyId,
    this.gameId,
    this.status = '',
    this.matched = false,
  });

  final String lobbyId;
  final String? gameId;
  final String status;
  final bool matched;

  factory PokerCreateResult.fromJson(Map<String, dynamic> json) {
    return PokerCreateResult(
      lobbyId: (json['lobby_id'] ?? '').toString().trim(),
      gameId: (json['game_id']?.toString().trim().isEmpty ?? true)
          ? null
          : json['game_id'].toString(),
      status: (json['status'] ?? '').toString(),
      matched: json['matched'] == true,
    );
  }
}

class PokerJoinResult {
  PokerJoinResult({
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

  factory PokerJoinResult.fromJson(Map<String, dynamic> json) {
    return PokerJoinResult(
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

/// Клиент API для покера. Всё под `/api/games/poker/*`.
class PokerRepository {
  PokerRepository({required AuthRepository authRepository})
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

  Future<PokerCreateResult> createLobby({
    required String mode, // 'invite' | 'matchmake'
    required int maxPlayers,
    required int turnTimeSec,
    required int stakeBronze,
  }) async {
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/poker/lobby'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'mode': mode,
            'max_players': maxPlayers,
            'turn_time_sec': turnTimeSec,
            'stake_bronze': stakeBronze,
          }),
          operation: 'PokerRepository.createLobby',
        ));
    if (r.statusCode != 200 && r.statusCode != 201) _fail(r);
    return PokerCreateResult.fromJson(
        jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<List<PokerLobbySummary>> listLobbies() async {
    final r = await _sendAuth((token) => ApiClient.get(
          Uri.parse('$apiBaseUrl/api/games/poker/lobbies'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'PokerRepository.listLobbies',
        ));
    if (r.statusCode != 200) _fail(r);
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (body['lobbies'] as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => PokerLobbySummary.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<PokerLobbyView> getLobby(String lobbyId) async {
    final r = await _sendAuth((token) => ApiClient.get(
          Uri.parse('$apiBaseUrl/api/games/poker/lobby/$lobbyId'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'PokerRepository.getLobby',
        ));
    if (r.statusCode != 200) _fail(r);
    return PokerLobbyView.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<PokerJoinResult> joinLobby(String lobbyId) async {
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/poker/lobby/$lobbyId/join'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'PokerRepository.joinLobby',
        ));
    if (r.statusCode != 200) _fail(r);
    return PokerJoinResult.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<void> leaveLobby(String lobbyId) async {
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/poker/lobby/$lobbyId/leave'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'PokerRepository.leaveLobby',
        ));
    if (r.statusCode != 200) _fail(r);
  }

  Future<void> declineLobby(String lobbyId) async {
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/poker/lobby/$lobbyId/decline'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'PokerRepository.declineLobby',
        ));
    if (r.statusCode != 200) _fail(r);
  }

  Future<void> inviteFriend(String lobbyId, String friendUserId) async {
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/poker/lobby/$lobbyId/invite'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'friend_user_id': friendUserId}),
          operation: 'PokerRepository.inviteFriend',
        ));
    if (r.statusCode != 200) _fail(r);
  }

  Future<void> cancelInvite(String lobbyId, String friendUserId) async {
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse(
              '$apiBaseUrl/api/games/poker/lobby/$lobbyId/cancel-invite'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'friend_user_id': friendUserId}),
          operation: 'PokerRepository.cancelInvite',
        ));
    if (r.statusCode != 200) _fail(r);
  }

  Future<PokerGameView> getGame(String gameId) async {
    if (OfflinePokerRegistry.instance.isOffline(gameId)) {
      final session = OfflinePokerRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      return session.view;
    }
    final r = await _sendAuth((token) => ApiClient.get(
          Uri.parse('$apiBaseUrl/api/games/poker/game/$gameId'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'PokerRepository.getGame',
        ));
    if (r.statusCode != 200) _fail(r);
    return PokerGameView.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<void> move(
    String gameId, {
    required String type,
    int? amount,
  }) async {
    if (OfflinePokerRegistry.instance.isOffline(gameId)) {
      final session = OfflinePokerRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      await session.applyMove(type: type, amount: amount);
      return;
    }
    final body = <String, dynamic>{'type': type};
    if (amount != null) body['amount'] = amount;
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/poker/game/$gameId/move'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
          operation: 'PokerRepository.move',
        ));
    if (r.statusCode != 200) _fail(r);
  }

  /// Показать карты после фолд-вины (пауза перед следующей раздачей).
  Future<void> showCards(String gameId) async {
    if (OfflinePokerRegistry.instance.isOffline(gameId)) {
      final session = OfflinePokerRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      await session.showCards();
      return;
    }
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/poker/game/$gameId/show'),
          headers: {
            'Authorization': 'Bearer $token',
          },
          operation: 'PokerRepository.showCards',
        ));
    if (r.statusCode != 200) _fail(r);
  }

  Future<void> forfeit(String gameId) async {
    if (OfflinePokerRegistry.instance.isOffline(gameId)) {
      final session = OfflinePokerRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      await session.forfeit();
      return;
    }
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/poker/game/$gameId/forfeit'),
          headers: {'Authorization': 'Bearer $token'},
          operation: 'PokerRepository.forfeit',
        ));
    if (r.statusCode != 200) _fail(r);
  }

  Future<String> rematch(String gameId) async {
    if (OfflinePokerRegistry.instance.isOffline(gameId)) {
      final session = OfflinePokerRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      session.restart();
      return '';
    }
    final r = await _sendAuth((token) => ApiClient.post(
          Uri.parse('$apiBaseUrl/api/games/poker/rematch'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'game_id': gameId}),
          operation: 'PokerRepository.rematch',
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
  String toString() => 'PokerRepository';
}

/// Sanity self-check в debug — не даём модели тихо сломаться при рефакторе.
@visibleForTesting
void assertPokerModelsShape() {
  const card = PokerApiCard(14, 'S');
  assert(card.rank == 14);
}
