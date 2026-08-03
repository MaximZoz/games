import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/durak/durak_repository.dart';

final durakRepositoryProvider = Provider<DurakRepository>((ref) {
  return DurakRepository(authRepository: ref.watch(authRepositoryProvider));
});

/// Кэш view конкретной партии, с обновлением по WS `game_state`.
final durakGameProvider = FutureProvider.autoDispose
    .family<DurakGameView, String>((ref, gameId) async {
  final repo = ref.watch(durakRepositoryProvider);
  final sub = ref.listen<AsyncValue<Map<String, dynamic>>>(
    realtimeEventsProvider,
    (_, next) {
      final data = next.valueOrNull;
      if (data == null) return;
      final type = data['type']?.toString() ?? '';
      final gid = data['game_id']?.toString();
      if ((type == 'game_state' || type == 'game_started') && gid == gameId) {
        ref.invalidateSelf();
      }
    },
  );
  ref.onDispose(sub.close);
  return repo.getGame(gameId);
});

/// Детальный view лобби.
final durakLobbyProvider =
    FutureProvider.autoDispose.family<DurakLobbyView, String>((ref, lobbyId) async {
  final repo = ref.watch(durakRepositoryProvider);
  ref.listen(realtimeEventsProvider, (_, next) {
    final data = next.valueOrNull;
    if (data == null) return;
    final type = data['type']?.toString() ?? '';
    final lid = data['lobby_id']?.toString();
    if ((type == 'lobby_updated' || type == 'game_started') && lid == lobbyId) {
      ref.invalidateSelf();
    }
  });
  return repo.getLobby(lobbyId);
});

/// Открытые лобби Durak.
final durakOpenLobbiesProvider = FutureProvider.autoDispose<List<DurakLobbyView>>((ref) async {
  final repo = ref.watch(durakRepositoryProvider);
  return repo.listLobbies();
});
