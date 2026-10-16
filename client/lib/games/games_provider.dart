import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/offline_disk_cache.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/game_engine/game_engine.dart';
import 'package:multigames_client/games/game_navigation.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/offline_session_hold.dart';
import 'package:multigames_client/games/live_game_sync.dart';
import 'package:multigames_client/games/offline_ttt_session.dart';
import 'package:multigames_client/l10n/display_names.dart';

final gamesRepositoryProvider = Provider<GamesRepository>((ref) {
  return GamesRepository(authRepository: ref.watch(authRepositoryProvider));
});

/// Invite-ссылка, скопированная из лобби — для всплывашки «Вставить» в чате.
final pendingInvitePasteProvider = StateProvider<String?>((ref) => null);

class GameInvite {
  GameInvite({
    required this.lobbyId,
    required this.creatorId,
    required this.creatorName,
    required this.gameType,
    this.turnTimeSec = 0,
    this.variant = variantClassic,
    this.gridSize = 3,
    this.maxPlayers = 2,
    this.swapRule = false,
    this.firstMoveRestriction = false,
    this.creatorAvatarKind = 'letter',
    this.creatorAvatarValue,
    this.stakeBronze = 2,
    this.deckSize = 36,
    this.durakMode = 'podkidnoi',
  });
  final String lobbyId;
  final String creatorId;
  final String creatorName;
  final String gameType;
  final int turnTimeSec;
  final String variant;
  final int gridSize;
  final int maxPlayers;
  final bool swapRule;
  final bool firstMoveRestriction;
  final String creatorAvatarKind;
  final String? creatorAvatarValue;
  final int stakeBronze;

  /// Durak: размер колоды (24/36/52).
  final int deckSize;

  /// Durak: 'podkidnoi' | 'perevodnoi'.
  final String durakMode;

  bool get isDurak => gameType == 'durak';

  bool get isBattleship => gameType == 'battleship';

  bool get isPoker => gameType == 'poker';

  bool get isUno => gameType == 'uno';

  bool get isDomino => gameType == 'domino';

  bool get isNardy => gameType == 'nardy';

  bool get isCheckers => gameType == 'checkers';

  bool get isChess => gameType == 'chess';

  /// Тот же инвайт на экране — не пересоздавать карточку (иначе мигает).
  bool sameVisibleCard(GameInvite other) =>
      lobbyId == other.lobbyId &&
      creatorId == other.creatorId &&
      creatorName == other.creatorName &&
      gameType == other.gameType &&
      stakeBronze == other.stakeBronze &&
      turnTimeSec == other.turnTimeSec &&
      variant == other.variant &&
      maxPlayers == other.maxPlayers &&
      deckSize == other.deckSize &&
      durakMode == other.durakMode;

  /// Подпись режима для карточки приглашения — из реестра игр.
  String get modeLabel => localizedGameModeLabel(
        gameType: gameType,
        variant: variant,
        gameMode: durakMode,
      );
}

/// Список приглашений визуально тот же — не трогать state.
bool gameInviteListsVisuallySame(List<GameInvite> a, List<GameInvite> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!a[i].sameVisibleCard(b[i])) return false;
  }
  return true;
}

/// Сверка с сервером, если WS-кадр приглашения потерялся.
const Duration kGameInvitesReconcileInterval = Duration(seconds: 5);

/// Карточка с WS не стирается сразу, если GET ещё пустой (гонка / SCAN).
const Duration kGameInviteHydrateGrace = Duration(seconds: 20);

/// Сервер — база; локальные инвайты держим, если пришли во время GET
/// или ещё в grace-окне после WS. Отказ важнее и GET, и ссылки.
List<GameInvite> mergeHydratedGameInvites({
  required List<GameInvite> snapshot,
  required List<GameInvite> current,
  required List<GameInvite> fromServer,
  required Map<String, DateTime> localSeenAt,
  required DateTime now,
  Duration grace = kGameInviteHydrateGrace,
  Set<String> heldIds = const {},
  Set<String> dismissedIds = const {},
}) {
  final next = <GameInvite>[
    for (final inv in fromServer)
      if (!dismissedIds.contains(inv.lobbyId)) inv,
  ];
  final serverIds = {for (final inv in next) inv.lobbyId};
  for (final inv in current) {
    if (dismissedIds.contains(inv.lobbyId)) continue;
    if (serverIds.contains(inv.lobbyId)) continue;
    // Ссылка без записи на сервере: карточку держим, пока гость не решит.
    if (heldIds.contains(inv.lobbyId)) {
      next.add(inv);
      continue;
    }
    final wasKnown = snapshot.any((s) => s.lobbyId == inv.lobbyId);
    if (!wasKnown) {
      next.add(inv);
      continue;
    }
    final seen = localSeenAt[inv.lobbyId];
    if (seen != null && now.difference(seen) < grace) {
      next.add(inv);
    }
  }
  return next;
}

/// Серверный список приглашений уже пришёл. До этого пустой список — не «нет инвайтов».
final gameInvitesHydratedProvider = StateProvider<bool>((ref) => false);

final gameInvitesProvider =
    StateNotifierProvider<GameInvitesNotifier, List<GameInvite>>((ref) {
  final notifier = GameInvitesNotifier();

  // Только смена user id (логин/выход). refresh() баланса не должен
  // создавать новый notifier — иначе карточка «Вас пригласили» мигает.
  final userId = ref.watch(authStateProvider.select((s) => s.valueOrNull?.id));
  ref.listen<String?>(
    authStateProvider.select((s) => s.valueOrNull?.id),
    (prev, next) {
      if (next != prev) {
        ref.read(gameInvitesHydratedProvider.notifier).state = false;
      }
    },
  );
  void markInvitesHydrated() {
    final current = ref.read(authStateProvider).valueOrNull?.id;
    if (current == null || current != userId) return;
    ref.read(gameInvitesHydratedProvider.notifier).state = true;
  }

  if (userId != null) {
    unawaited(() async {
      final ok =
          await notifier.hydrateFromServer(ref.read(gamesRepositoryProvider));
      if (ok) markInvitesHydrated();
    }());
    notifier.startPolling(
      () => ref.read(gamesRepositoryProvider),
      onHydrated: markInvitesHydrated,
    );
  }

  ref.listen<AsyncValue<Map<String, dynamic>>>(
    realtimeEventsProvider,
    (_, next) {
      final data = next.valueOrNull;
      if (data == null) return;
      final type = data['type']?.toString() ?? '';
      if (type == 'game_invite') {
        final lobbyId = data['lobby_id']?.toString();
        final creatorId = data['creator_id']?.toString();
        final creatorName = localizeDisplayName(
          data['creator_name']?.toString(),
        );
        final gameType = data['game_type']?.toString() ?? 'tictactoe';
        final turnTimeSec = (data['turn_time_sec'] as num?)?.toInt() ?? 0;
        final legacyGrid = (data['grid_size'] as num?)?.toInt() ?? 3;
        final rawVariant = data['variant']?.toString();
        final variant = rawVariant == null || rawVariant.isEmpty
            ? variantFromLegacyGrid(legacyGrid)
            : parseVariant(rawVariant);
        final cfg = configForVariant(variant);
        final swapRule = data['swap_rule'] == true;
        final firstMoveRestriction = data['first_move_restriction'] == true;
        final creatorAvatarKind =
            data['creator_avatar_kind']?.toString() ?? 'letter';
        final creatorAvatarValue = data['creator_avatar_value']?.toString();
        final stakeBronze = (data['stake_bronze'] as num?)?.toInt() ?? 2;
        if (lobbyId != null && creatorId != null) {
          notifier.add(GameInvite(
            lobbyId: lobbyId,
            creatorId: creatorId,
            creatorName: creatorName,
            gameType: gameType,
            turnTimeSec: turnTimeSec,
            variant: variant,
            gridSize: cfg.gridSize,
            maxPlayers:
                (data['max_players'] as num?)?.toInt() ?? cfg.maxPlayers,
            swapRule: swapRule,
            firstMoveRestriction: firstMoveRestriction,
            creatorAvatarKind: creatorAvatarKind,
            creatorAvatarValue: creatorAvatarValue,
            stakeBronze: stakeBronze,
            deckSize: (data['deck_size'] as num?)?.toInt() ?? 36,
            durakMode: data['game_mode']?.toString() ?? 'podkidnoi',
          ));
        }
        return;
      }
      // Создатель отозвал приглашение — карточка должна исчезнуть.
      if (type == 'invite_cancelled') {
        final lobbyId = data['lobby_id']?.toString();
        if (lobbyId != null && lobbyId.isNotEmpty) {
          // Свой отказ приходит и на другие устройства. Отмена хозяином
          // не должна запретить позвать в этот стол ещё раз.
          if (data['reason']?.toString() == 'declined') {
            notifier.dismiss(lobbyId);
          } else {
            notifier.remove(lobbyId);
          }
        }
        return;
      }
      // После reconnect — восстановить карточки, которые пришли, пока были offline.
      if (type == 'realtime_connected') {
        unawaited(() async {
          final ok = await notifier
              .hydrateFromServer(ref.read(gamesRepositoryProvider));
          if (ok) markInvitesHydrated();
        }());
        return;
      }
      // Приглашение больше не актуально: лобби закрыто, игра началась, или
      // создатель/соперник ушёл.
      if (type == 'lobby_updated' || type == 'game_started') {
        final lobbyId = data['lobby_id']?.toString();
        if (lobbyId == null || lobbyId.isEmpty) return;
        final left = data['left'] == true;
        final closed = data['closed'] == true;
        final gameId = data['game_id']?.toString();
        final gameStarted =
            type == 'game_started' || (gameId != null && gameId.isNotEmpty);
        if (left || closed || gameStarted) {
          notifier.remove(lobbyId);
        }
      }
    },
  );

  return notifier;
});

class GameInvitesNotifier extends StateNotifier<List<GameInvite>> {
  GameInvitesNotifier() : super(const []);

  final Map<String, DateTime> _localSeenAt = {};
  final Set<String> _held = {};

  /// Отказ от этого стола. Опрос, опоздавший WS и повторная ссылка
  /// не возвращают карточку, пока не сменится сессия.
  final Set<String> _dismissed = {};
  Timer? _poll;

  void startPolling(
    GamesRepository Function() repo, {
    void Function()? onHydrated,
  }) {
    _poll?.cancel();
    _poll = Timer.periodic(kGameInvitesReconcileInterval, (_) {
      unawaited(() async {
        if (await hydrateFromServer(repo())) onHydrated?.call();
      }());
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void add(GameInvite invite) {
    final id = invite.lobbyId.trim();
    if (id.isEmpty) return;
    // Новый кадр «пригласили» — хозяин зовёт снова. Сам опрос этого не делает.
    _dismissed.remove(id);
    _localSeenAt[id] = DateTime.now();
    if (state.any((i) => i.lobbyId == id)) return;
    state = [...state, invite];
  }

  /// Карточка со ссылки: не стирать следующим опросом, если сервер её не знает.
  /// Уже отказанный стол ссылка не поднимает снова.
  void hold(GameInvite invite) {
    final id = invite.lobbyId.trim();
    if (id.isEmpty || _dismissed.contains(id)) return;
    _held.add(id);
    add(invite);
  }

  /// Подтянуть приглашения с сервера (reconnect / F5) — пока лобби ждёт.
  /// Сервер — источник истины для уже известных карточек; WS-инвайты,
  /// пришедшие во время запроса или в grace-окне, сохраняем.
  Future<bool> hydrateFromServer(GamesRepository repo) async {
    try {
      final snapshot = List<GameInvite>.of(state);
      final raw = await repo.listPendingInvites();
      final fromServer = <GameInvite>[];
      for (final m in raw) {
        final lobbyId = m['lobby_id']?.toString() ?? '';
        if (lobbyId.isEmpty || fromServer.any((i) => i.lobbyId == lobbyId)) {
          continue;
        }
        final gameType = m['game_type']?.toString() ?? 'tictactoe';
        final rawVariant = m['variant']?.toString();
        final legacyGrid = (m['grid_size'] as num?)?.toInt() ?? 3;
        final variant = rawVariant == null || rawVariant.isEmpty
            ? variantFromLegacyGrid(legacyGrid)
            : parseVariant(rawVariant);
        final cfg = configForVariant(variant);
        fromServer.add(GameInvite(
          lobbyId: lobbyId,
          creatorId: m['creator_id']?.toString() ?? '',
          creatorName: localizeDisplayName(m['creator_name']?.toString()),
          gameType: gameType,
          turnTimeSec: (m['turn_time_sec'] as num?)?.toInt() ?? 0,
          variant: variant,
          gridSize: cfg.gridSize,
          maxPlayers: (m['max_players'] as num?)?.toInt() ?? cfg.maxPlayers,
          swapRule: m['swap_rule'] == true,
          firstMoveRestriction: m['first_move_restriction'] == true,
          creatorAvatarKind: m['creator_avatar_kind']?.toString() ?? 'letter',
          creatorAvatarValue: m['creator_avatar_value']?.toString(),
          stakeBronze: (m['stake_bronze'] as num?)?.toInt() ?? 2,
          deckSize: (m['deck_size'] as num?)?.toInt() ?? 36,
          durakMode: m['game_mode']?.toString() ?? 'podkidnoi',
        ));
      }
      final now = DateTime.now();
      for (final inv in fromServer) {
        _localSeenAt.putIfAbsent(inv.lobbyId, () => now);
      }
      final next = mergeHydratedGameInvites(
        snapshot: snapshot,
        current: state,
        fromServer: fromServer,
        localSeenAt: _localSeenAt,
        now: now,
        heldIds: _held,
        dismissedIds: _dismissed,
      );
      if (!gameInviteListsVisuallySame(state, next)) {
        state = next;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void _dropLocal(String lobbyId) {
    final id = lobbyId.trim();
    if (id.isEmpty) return;
    _localSeenAt.remove(id);
    _localSeenAt.remove(lobbyId);
    _held.remove(id);
    _held.remove(lobbyId);
  }

  /// Отказ игрока. Карточка этого стола не возвращается сама.
  void dismiss(String lobbyId) {
    final id = lobbyId.trim();
    if (id.isEmpty) return;
    _dismissed.add(id);
    _dropLocal(lobbyId);
    state =
        state.where((i) => i.lobbyId != id && i.lobbyId != lobbyId).toList();
  }

  void remove(String lobbyId) {
    _dropLocal(lobbyId);
    final id = lobbyId.trim();
    state =
        state.where((i) => i.lobbyId != id && i.lobbyId != lobbyId).toList();
  }

  void removeByCreatorId(String creatorId) {
    for (final inv in state) {
      if (inv.creatorId == creatorId) _dropLocal(inv.lobbyId);
    }
    state = state.where((i) => i.creatorId != creatorId).toList();
  }

  /// Снять карточку приглашения после входа в лобби/игру.
  /// Удаляет и дубликаты от того же создателя (повторный реванш и т.п.).
  void resolveJoined(String lobbyId) {
    final match = state.where((i) => i.lobbyId == lobbyId).toList();
    if (match.isEmpty) {
      remove(lobbyId);
      return;
    }
    final creatorId = match.first.creatorId;
    for (final inv in state) {
      if (inv.lobbyId == lobbyId || inv.creatorId == creatorId) {
        _dropLocal(inv.lobbyId);
      }
    }
    state = state
        .where((i) => i.lobbyId != lobbyId && i.creatorId != creatorId)
        .toList();
  }

  void clear() {
    _localSeenAt.clear();
    _held.clear();
    _dismissed.clear();
    state = [];
  }
}

final openLobbiesProvider =
    AsyncNotifierProvider.autoDispose<OpenLobbiesNotifier, List<LobbyItem>>(
        OpenLobbiesNotifier.new);

class OpenLobbiesNotifier extends AutoDisposeAsyncNotifier<List<LobbyItem>> {
  @override
  Future<List<LobbyItem>> build() async {
    final userId =
        ref.watch(authStateProvider.select((s) => s.valueOrNull?.id));
    if (userId == null) return [];

    final repo = ref.read(gamesRepositoryProvider);
    final lobbies = await repo.listLobbies();

    ref.listen(
      realtimeEventsProvider,
      (_, next) {
        final type = next.valueOrNull?['type']?.toString() ?? '';
        // lobbies_changed — всем онлайн: отмена/старт публичного лобби.
        if (type == 'lobby_updated' ||
            type == 'game_started' ||
            type == 'lobbies_changed') {
          unawaited(reloadQuiet());
        }
      },
    );

    return lobbies;
  }

  /// Обновить список, не сбрасывая его в loading — иначе карточки мигают.
  Future<void> reloadQuiet() async {
    final userId = ref.read(authStateProvider).valueOrNull?.id;
    if (userId == null) {
      state = const AsyncData([]);
      return;
    }
    try {
      final lobbies = await ref.read(gamesRepositoryProvider).listLobbies();
      state = AsyncData(lobbies);
    } catch (e, st) {
      if (!state.hasValue) {
        state = AsyncError(e, st);
      }
    }
  }

  /// Сразу убрать карточку (вход / отмена / старт), не дожидаясь refetch.
  void removeLocal(String lobbyId) {
    final cur = state.valueOrNull;
    if (cur == null || cur.isEmpty) return;
    final next = cur.where((l) => l.id != lobbyId).toList(growable: false);
    if (next.length != cur.length) {
      state = AsyncData(next);
    }
  }
}

final lobbyDetailProvider =
    FutureProvider.autoDispose.family<LobbyItem, String>(
  (ref, lobbyId) async {
    final repo = ref.read(gamesRepositoryProvider);
    return repo.getLobby(lobbyId);
  },
);

final gameStateProvider = AsyncNotifierProvider.autoDispose
    .family<GameStateNotifier, GameStateItem, String>(
  GameStateNotifier.new,
);

class GameStateNotifier
    extends AutoDisposeFamilyAsyncNotifier<GameStateItem, String> {
  bool _httpInFlight = false;
  int _httpGen = 0;

  @override
  Future<GameStateItem> build(String arg) async {
    if (OfflineTttRegistry.instance.isOffline(arg)) {
      final session = OfflineTttRegistry.instance.get(arg);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      var alive = true;
      void onChanged() {
        Future.microtask(() {
          if (alive) state = AsyncData(session.view);
        });
      }

      session.addListener(onChanged);
      ref.onDispose(() {
        alive = false;
        session.removeListener(onChanged);
      });
      return session.view;
    }

    listenLiveGameSync(
      ref: ref,
      gameId: arg,
      hasFullView: hasFullTictactoeView,
      onFullState: applyWs,
      onReconcile: () => unawaited(reconcile()),
    );
    return _fetchPreferringLive();
  }

  void applyWs(Map<String, dynamic> data) {
    try {
      final parsed = GameStateItem.fromJson(data);
      _commit(parsed);
    } catch (_) {
      unawaited(reconcile());
    }
  }

  Future<void> reconcile() async {
    if (OfflineTttRegistry.instance.isOffline(arg) || _httpInFlight) return;
    _httpInFlight = true;
    final gen = ++_httpGen;
    try {
      final fetched = await ref.read(gamesRepositoryProvider).getGame(arg);
      if (gen != _httpGen) return;
      _commit(fetched);
    } catch (_) {
      // Оставляем то, что уже на экране.
    } finally {
      _httpInFlight = false;
    }
  }

  Future<GameStateItem> _fetchPreferringLive() async {
    final fetched = await fetchGameWithRetry(
      () => ref.read(gamesRepositoryProvider).getGame(arg),
    );
    final current = state.valueOrNull;
    if (current != null && isOlderTictactoe(fetched, current)) {
      return current;
    }
    if (current != null) return current.mergePreservingIdentity(fetched);
    return fetched;
  }

  void _commit(GameStateItem incoming) {
    final current = state.valueOrNull;
    final merged =
        current == null ? incoming : current.mergePreservingIdentity(incoming);
    if (current != null && isOlderTictactoe(merged, current)) return;
    state = AsyncData(merged);
  }
}

/// Временное состояние после makeMove для немедленного отображения победы/ничьей
/// (до завершения refetch). Сбрасывается при получении свежих данных из gameStateProvider.
final gameStateOverrideProvider = StateProvider.autoDispose
    .family<GameStateItem?, String>((ref, gameId) => null);

/// Блокирует invalidate по game_state (чтобы не перезапрашивать до хода бота).
final gameStateInvalidateBlockedProvider =
    StateProvider.autoDispose.family<bool, String>((ref, gameId) => false);

/// Наблюдение после выбывания (карточка в «Играх», не блокирует и не авто-роутит).
final observationGameProvider = StateProvider<ObservationItem?>((ref) => null);

final activeGameProvider =
    AsyncNotifierProvider.autoDispose<ActiveGameNotifier, ActiveGameItem?>(
        ActiveGameNotifier.new);

class ActiveGameNotifier extends AutoDisposeAsyncNotifier<ActiveGameItem?> {
  /// Растёт при [clearLocal] — чтобы фоновый resume после тапа «Игры»
  /// не вернул в лобби сразу после выхода.
  int _epoch = 0;
  int get epoch => _epoch;

  void _applyObservation(ObservationItem? obs) {
    // Дефолт tictactoe не затирает тип, который игра уже инжектнула.
    if (obs != null) {
      final prev = ref.read(observationGameProvider);
      final same = prev != null && prev.gameId == obs.gameId;
      final kept = keepInjectedGameType(
        incoming: obs.gameType,
        injected: same ? prev.gameType : null,
      );
      final lobbyId = obs.lobbyId ?? (same ? prev.lobbyId : null);
      if (kept != obs.gameType || lobbyId != obs.lobbyId) {
        obs = ObservationItem(
          gameId: obs.gameId,
          lobbyId: lobbyId,
          gameType: kept,
        );
      }
    }
    ref.read(observationGameProvider.notifier).state = obs;
  }

  ActiveGameItem? _mergeReturn(
      ActiveGameItem? incoming, ActiveGameItem? previous) {
    return mergeActiveReturn(
      incoming: incoming,
      previous: previous,
      sessionPath: ref.read(lastGamesSessionPathProvider),
    );
  }

  @override
  Future<ActiveGameItem?> build() async {
    ref.listen(
      realtimeEventsProvider,
      (_, next) {
        final data = next.valueOrNull;
        if (data == null) return;
        final type = data['type']?.toString() ?? '';
        if (type == 'game_started') {
          unawaited(ref.read(activeGameProvider.notifier).refresh());
          return;
        }
        if (type == 'game_state') {
          final status = data['status']?.toString() ?? '';
          if (status == 'over' ||
              status == 'draw' ||
              status.endsWith('_won') ||
              data['is_over'] == true) {
            unawaited(ref.read(activeGameProvider.notifier).refresh());
            return;
          }
          final current = state.valueOrNull;
          final next = applyActiveGameTurnFromEvent(current, data);
          if (next != null) {
            state = AsyncValue.data(next);
          }
          return;
        }
        // lobby_updated при ожидании игроков не трогаем active — иначе таб
        // «Игры» на мгновение видит null и уводит со экрана лобби.
        if (type == 'lobby_updated') {
          final left = data['left'] == true;
          final gameId = data['game_id']?.toString();
          if (left || (gameId != null && gameId.isNotEmpty)) {
            unawaited(ref.read(activeGameProvider.notifier).refresh());
          }
          if (gameId != null && gameId.isNotEmpty) {
            if (!ref.read(gameStateInvalidateBlockedProvider(gameId))) {
              ref.invalidate(gameStateProvider(gameId));
            }
          }
        }
      },
    );
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      _applyObservation(null);
      return null;
    }
    final session = await ref.read(gamesRepositoryProvider).getActiveSession();
    _applyObservation(session.observation);
    return _mergeReturn(session.active, null);
  }

  /// Обновить с сервера, не обнуляя кэш на время запроса (гард join не «слепнет»).
  Future<ActiveGameItem?> refresh() async {
    final previous = state;
    final previousData = state.asData?.value;
    state =
        const AsyncValue<ActiveGameItem?>.loading().copyWithPrevious(previous);
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) {
        _applyObservation(null);
        state = const AsyncValue.data(null);
        return null;
      }
      final session =
          await ref.read(gamesRepositoryProvider).getActiveSession();
      _applyObservation(session.observation);
      final merged = _mergeReturn(session.active, previousData);
      state = AsyncValue.data(merged);
      return merged;
    } catch (e, st) {
      if (previousData != null) {
        state = AsyncValue.data(previousData);
        return previousData;
      }
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Мгновенно сбросить локально (выход из лобби без ожидания сети).
  void clearLocal() {
    _epoch++;
    state = const AsyncValue.data(null);
  }

  /// Сразу после createLobby — чтобы таб «Игры» открывал «Своя игра».
  void setLocal(ActiveGameItem item) {
    state = AsyncValue.data(item);
  }

  /// Локально включить наблюдение (после сдачи), пока не придёт refresh.
  void setObservationLocal(ObservationItem? item) {
    _applyObservation(item);
  }

  void clearObservationLocal({String? ifGameId}) {
    final cur = ref.read(observationGameProvider);
    if (cur == null) return;
    final only = ifGameId?.trim() ?? '';
    if (only.isNotEmpty && cur.gameId != only) return;
    _applyObservation(null);
  }
}

/// Количество игр, где мой ход (для badge в меню).
final gamesMyTurnCountProvider = Provider.autoDispose<int>((ref) {
  final active = ref.watch(activeGameProvider).valueOrNull;
  if (active == null || active.type != 'game') return 0;
  return active.isMyTurn ? 1 : 0;
});

/// Количество приглашений в игру (для badge в меню).
final gameInvitesCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(gameInvitesProvider).length;
});

/// Ленивая загрузка конфигурации игры из БД (на [gameType]).
final userGameSettingsProvider = AsyncNotifierProvider.family<
    UserGameSettingsNotifier, UserGameSettings, String>(
  UserGameSettingsNotifier.new,
);

class UserGameSettingsNotifier
    extends FamilyAsyncNotifier<UserGameSettings, String> {
  Timer? _saveTimer;
  UserGameSettings? _pending;
  GamesRepository? _repo;

  String get _gameType {
    final gt = arg.trim();
    return gt.isEmpty ? 'tictactoe' : gt;
  }

  @override
  Future<UserGameSettings> build(String arg) async {
    ref.onDispose(() {
      _saveTimer?.cancel();
      final pending = _pending;
      final repo = _repo;
      _pending = null;
      if (pending != null && repo != null) {
        unawaited(repo.saveGameSettings(pending));
      }
    });
    final gameType = _gameType;
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return UserGameSettings.defaultsFor(gameType);
    final offline = ref.watch(isOfflineProvider);
    if (offline) {
      return await OfflineDiskCache.loadGameSettings(user.id,
              gameType: gameType) ??
          UserGameSettings.defaultsFor(gameType);
    }
    try {
      final settings = await ref
          .read(gamesRepositoryProvider)
          .getGameSettings(gameType: gameType);
      await OfflineDiskCache.saveGameSettings(
        user.id,
        settings,
        gameType: gameType,
      );
      return settings;
    } catch (_) {
      return await OfflineDiskCache.loadGameSettings(user.id,
              gameType: gameType) ??
          UserGameSettings.defaultsFor(gameType);
    }
  }

  /// Локально применяет настройки и с задержкой пишет в БД.
  void updateLocal(UserGameSettings next) {
    final withType =
        next.gameType == _gameType ? next : next.copyWith(gameType: _gameType);
    state = AsyncData(withType);
    _pending = withType;
    _repo = ref.read(gamesRepositoryProvider);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      unawaited(OfflineDiskCache.saveGameSettings(
        user.id,
        withType,
        gameType: _gameType,
      ));
    }
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 450), () {
      final toSave = _pending;
      final repo = _repo;
      _pending = null;
      if (toSave == null || repo == null) return;
      unawaited(_persist(repo, toSave));
    });
  }

  Future<void> _persist(GamesRepository repo, UserGameSettings settings) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      final saved = await repo.saveGameSettings(settings);
      final current = state.valueOrNull;
      if (current == null || current == settings || current == saved) {
        state = AsyncData(saved);
      }
    } catch (_) {
      // Оставляем локальное значение; повтор при следующей смене.
    }
  }
}

/// Статистика игрока (W/D/L, win-rate, время, топ соперников).
/// Параметр — userId статистики: null/пусто = своя статистика.
final gameStatsProvider =
    FutureProvider.autoDispose.family<GameStats, String?>((ref, userId) async {
  final repo = ref.watch(gamesRepositoryProvider);
  return repo.getStats(userId: userId);
});

/// Счёт head-to-head между текущим игроком и указанным соперником.
final headToHeadProvider = FutureProvider.autoDispose
    .family<HeadToHead, String>((ref, opponentId) async {
  final repo = ref.watch(gamesRepositoryProvider);
  return repo.getHeadToHead(opponentId);
});
