import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/offline_disk_cache.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/game_engine/game_engine.dart';
import 'package:multigames_client/games/durak/durak_rules.dart';
import 'package:multigames_client/games/game_navigation.dart';
import 'package:multigames_client/games/games_repository.dart';
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

  /// Подпись режима для карточки приглашения.
  /// Для покера пусто — NLHE не показываем (есть иконка игры и число игроков).
  String get modeLabel {
    if (isDurak) {
      return durakModeLabel(durakMode);
    }
    if (isBattleship) {
      return '10×10';
    }
    if (isPoker) {
      return '';
    }
    if (isUno) {
      return '';
    }
    return variantLabel(variant);
  }
}

final gameInvitesProvider =
    StateNotifierProvider<GameInvitesNotifier, List<GameInvite>>((ref) {
  final notifier = GameInvitesNotifier();

  // После логина / rebuild — восстановить карточки приглашений с сервера.
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user != null) {
    unawaited(
      notifier.hydrateFromServer(ref.read(gamesRepositoryProvider)),
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
          notifier.remove(lobbyId);
        }
        return;
      }
      // После reconnect — восстановить карточки, которые пришли, пока были offline.
      if (type == 'realtime_connected') {
        unawaited(
          notifier.hydrateFromServer(ref.read(gamesRepositoryProvider)),
        );
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

  void add(GameInvite invite) {
    if (state.any((i) => i.lobbyId == invite.lobbyId)) return;
    state = [...state, invite];
  }

  /// Подтянуть приглашения с сервера (reconnect / F5) — пока лобби ждёт.
  /// Сервер — источник истины для уже известных карточек; WS-инвайты,
  /// пришедшие во время запроса, сохраняем.
  Future<void> hydrateFromServer(GamesRepository repo) async {
    try {
      final snapshot = List<GameInvite>.of(state);
      final raw = await repo.listPendingInvites();
      final next = <GameInvite>[];
      for (final m in raw) {
        final lobbyId = m['lobby_id']?.toString() ?? '';
        if (lobbyId.isEmpty || next.any((i) => i.lobbyId == lobbyId)) {
          continue;
        }
        final gameType = m['game_type']?.toString() ?? 'tictactoe';
        final rawVariant = m['variant']?.toString();
        final legacyGrid = (m['grid_size'] as num?)?.toInt() ?? 3;
        final variant = rawVariant == null || rawVariant.isEmpty
            ? variantFromLegacyGrid(legacyGrid)
            : parseVariant(rawVariant);
        final cfg = configForVariant(variant);
        next.add(GameInvite(
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
      final serverIds = next.map((i) => i.lobbyId).toSet();
      // Инвайты, пришедшие по WS пока шёл GET — не затирать.
      for (final inv in state) {
        final wasKnown = snapshot.any((s) => s.lobbyId == inv.lobbyId);
        if (!wasKnown && !serverIds.contains(inv.lobbyId)) {
          next.add(inv);
        }
      }
      state = next;
    } catch (_) {}
  }

  void remove(String lobbyId) {
    state = state.where((i) => i.lobbyId != lobbyId).toList();
  }

  void removeByCreatorId(String creatorId) {
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
    state = state
        .where((i) => i.lobbyId != lobbyId && i.creatorId != creatorId)
        .toList();
  }

  void clear() {
    state = [];
  }
}

final openLobbiesProvider =
    AsyncNotifierProvider.autoDispose<OpenLobbiesNotifier, List<LobbyItem>>(
        OpenLobbiesNotifier.new);

class OpenLobbiesNotifier extends AutoDisposeAsyncNotifier<List<LobbyItem>> {
  @override
  Future<List<LobbyItem>> build() async {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return [];

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
          ref.invalidate(openLobbiesProvider);
        }
      },
    );

    return lobbies;
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

final gameStateProvider =
    FutureProvider.autoDispose.family<GameStateItem, String>(
  (ref, gameId) async {
    if (OfflineTttRegistry.instance.isOffline(gameId)) {
      final session = OfflineTttRegistry.instance.get(gameId);
      if (session == null) {
        throw GamesException(404, 'offline game not found');
      }
      var alive = true;
      void onChanged() {
        Future.microtask(() {
          if (alive) ref.invalidateSelf();
        });
      }

      session.addListener(onChanged);
      ref.onDispose(() {
        alive = false;
        session.removeListener(onChanged);
      });
      return session.view;
    }
    final repo = ref.read(gamesRepositoryProvider);
    final sub = ref.listen<AsyncValue<Map<String, dynamic>>>(
      realtimeEventsProvider,
      (_, next) {
        final data = next.valueOrNull;
        if (data == null) return;
        final type = data['type']?.toString() ?? '';
        final gid = data['game_id']?.toString();
        if (type == 'realtime_connected' ||
            ((type == 'game_state' || type == 'game_started') &&
                gid == gameId)) {
          if (!ref.read(gameStateInvalidateBlockedProvider(gameId))) {
            ref.invalidateSelf();
          }
        }
      },
    );
    ref.onDispose(sub.close);
    // Poll не блокируем: иначе пропущенный WS = «зависший» ход.
    final poll = Stream<void>.periodic(const Duration(milliseconds: 800)).listen((_) {
      ref.invalidateSelf();
    });
    ref.onDispose(poll.cancel);
    return repo.getGame(gameId);
  },
);

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
    // Не затирать durak/poker→tictactoe дефолтом.
    if (obs != null) {
      final prev = ref.read(observationGameProvider);
      final incoming = normalizeGameType(obs.gameType);
      if (prev != null && prev.gameId == obs.gameId) {
        final prevGt = normalizeGameType(prev.gameType);
        if ((prevGt == 'durak' || prevGt == 'poker') && incoming != prevGt) {
          obs = ObservationItem(
            gameId: obs.gameId,
            lobbyId: obs.lobbyId ?? prev.lobbyId,
            gameType: prevGt,
          );
        } else if (incoming != obs.gameType) {
          obs = ObservationItem(
            gameId: obs.gameId,
            lobbyId: obs.lobbyId,
            gameType: incoming,
          );
        }
      } else if (incoming != obs.gameType) {
        obs = ObservationItem(
          gameId: obs.gameId,
          lobbyId: obs.lobbyId,
          gameType: incoming,
        );
      }
    }
    ref.read(observationGameProvider.notifier).state = obs;
  }

  @override
  Future<ActiveGameItem?> build() async {
    ref.listen(
      realtimeEventsProvider,
      (_, next) {
        final data = next.valueOrNull;
        if (data == null) return;
        final type = data['type']?.toString() ?? '';
        if (type == 'game_state' || type == 'game_started') {
          unawaited(ref.read(activeGameProvider.notifier).refresh());
          final gameId = data['game_id']?.toString();
          if (gameId != null && gameId.isNotEmpty) {
            if (!ref.read(gameStateInvalidateBlockedProvider(gameId))) {
              ref.invalidate(gameStateProvider(gameId));
            }
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
    return session.active;
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
      state = AsyncValue.data(session.active);
      return session.active;
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
