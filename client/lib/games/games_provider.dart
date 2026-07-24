import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/core/runtime_debug.dart';
import 'package:multigames_client/games/games_repository.dart';

final gamesRepositoryProvider = Provider<GamesRepository>((ref) {
  return GamesRepository(authRepository: ref.watch(authRepositoryProvider));
});

class GameInvite {
  GameInvite({
    required this.lobbyId,
    required this.creatorId,
    required this.creatorName,
    required this.gameType,
    this.turnTimeSec = 0,
    this.gridSize = 3,
    this.swapRule = false,
    this.firstMoveRestriction = false,
    this.creatorAvatarKind = 'letter',
    this.creatorAvatarValue,
    this.stakeBronze = 1,
  });
  final String lobbyId;
  final String creatorId;
  final String creatorName;
  final String gameType;
  final int turnTimeSec;
  final int gridSize;
  final bool swapRule;
  final bool firstMoveRestriction;
  final String creatorAvatarKind;
  final String? creatorAvatarValue;
  final int stakeBronze;
}

final gameInvitesProvider =
    StateNotifierProvider<GameInvitesNotifier, List<GameInvite>>((ref) {
  final notifier = GameInvitesNotifier();

  ref.listen<AsyncValue<Map<String, dynamic>>>(
    realtimeEventsProvider,
    (_, next) {
      final data = next.valueOrNull;
      if (data == null) return;
      final type = data['type']?.toString() ?? '';
      if (type == 'game_invite') {
        final lobbyId = data['lobby_id']?.toString();
        final creatorId = data['creator_id']?.toString();
        final creatorName = data['creator_name']?.toString() ?? 'Игрок';
        final gameType = data['game_type']?.toString() ?? 'tictactoe';
        final turnTimeSec = (data['turn_time_sec'] as num?)?.toInt() ?? 0;
        final gridSize = (data['grid_size'] as num?)?.toInt() ?? 3;
        final swapRule = data['swap_rule'] == true;
        final firstMoveRestriction = data['first_move_restriction'] == true;
        final creatorAvatarKind =
            data['creator_avatar_kind']?.toString() ?? 'letter';
        final creatorAvatarValue = data['creator_avatar_value']?.toString();
        final stakeBronze = (data['stake_bronze'] as num?)?.toInt() ?? 1;
        if (lobbyId != null && creatorId != null) {
          notifier.add(GameInvite(
            lobbyId: lobbyId,
            creatorId: creatorId,
            creatorName: creatorName,
            gameType: gameType,
            turnTimeSec: turnTimeSec,
            gridSize: gridSize,
            swapRule: swapRule,
            firstMoveRestriction: firstMoveRestriction,
            creatorAvatarKind: creatorAvatarKind,
            creatorAvatarValue: creatorAvatarValue,
            stakeBronze: stakeBronze,
          ));
        }
      }
      if (type == 'lobby_updated' && data['left'] == true) {
        final lobbyId = data['lobby_id']?.toString();
        if (lobbyId != null) notifier.remove(lobbyId);
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

  void remove(String lobbyId) {
    state = state.where((i) => i.lobbyId != lobbyId).toList();
  }

  void removeByCreatorId(String creatorId) {
    state = state.where((i) => i.creatorId != creatorId).toList();
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
        if (type == 'lobby_updated' || type == 'game_started') {
          ref.invalidate(openLobbiesProvider);
        }
      },
    );

    return lobbies;
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
    final repo = ref.read(gamesRepositoryProvider);
    final game = await repo.getGame(gameId);
    // #region agent log
    appendRuntimeDebugLog(
      ref.read(authRepositoryProvider),
      hypothesisId: 'D',
      location: 'games_provider.dart:gameStateProvider',
      message: 'game state fetch completed',
      data: {
        'gameId': gameId,
        'turn': game.turn,
        'status': game.status,
        'occupiedCells': game.board.where((cell) => cell.isNotEmpty).length,
      },
    );
    // #endregion
    return game;
  },
);

/// Временное состояние после makeMove для немедленного отображения победы/ничьей
/// (до завершения refetch). Сбрасывается при получении свежих данных из gameStateProvider.
final gameStateOverrideProvider = StateProvider.autoDispose
    .family<GameStateItem?, String>((ref, gameId) => null);

/// Блокирует invalidate по game_state (чтобы не перезапрашивать до хода бота).
final gameStateInvalidateBlockedProvider =
    StateProvider.autoDispose.family<bool, String>((ref, gameId) => false);

final activeGameProvider =
    AsyncNotifierProvider.autoDispose<ActiveGameNotifier, ActiveGameItem?>(
        ActiveGameNotifier.new);

class ActiveGameNotifier extends AutoDisposeAsyncNotifier<ActiveGameItem?> {
  @override
  Future<ActiveGameItem?> build() async {
    ref.listen(
      realtimeEventsProvider,
      (_, next) {
        final data = next.valueOrNull;
        if (data == null) return;
        final type = data['type']?.toString() ?? '';
        if (type == 'game_state' ||
            type == 'game_started' ||
            type == 'lobby_updated') {
          final gameId = data['game_id']?.toString();
          final blocked = gameId != null && gameId.isNotEmpty
              ? ref.read(gameStateInvalidateBlockedProvider(gameId))
              : false;
          // #region agent log
          appendRuntimeDebugLog(
            ref.read(authRepositoryProvider),
            hypothesisId: 'D',
            location: 'games_provider.dart:ActiveGameNotifier.realtime',
            message: 'realtime event reached provider invalidation',
            data: {
              'type': type,
              'gameId': gameId,
              'turn': data['turn']?.toString(),
              'blocked': blocked,
            },
          );
          // #endregion
          ref.invalidate(activeGameProvider);
          if (gameId != null && gameId.isNotEmpty) {
            if (!blocked) {
              ref.invalidate(gameStateProvider(gameId));
            }
          }
        }
      },
    );
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return null;
    final repo = ref.read(gamesRepositoryProvider);
    final active = await repo.getActive();
    // #region agent log
    appendRuntimeDebugLog(
      ref.read(authRepositoryProvider),
      hypothesisId: 'E',
      location: 'games_provider.dart:ActiveGameNotifier.build',
      message: 'active game fetch completed',
      data: {
        'type': active?.type,
        'gameId': active?.gameId,
        'isMyTurn': active?.isMyTurn,
      },
    );
    // #endregion
    return active;
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
