import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/durak/durak_repository.dart';
import 'package:multigames_client/games/games_repository.dart' show GamesException;

final durakRepositoryProvider = Provider<DurakRepository>((ref) {
  return DurakRepository(authRepository: ref.watch(authRepositoryProvider));
});

bool _isTransientGamesError(Object e) {
  if (e is GamesException) {
    if (e.statusCode == 502 || e.statusCode == 503) return true;
    final key = e.errorKey.toLowerCase();
    final msg = e.message.toLowerCase();
    return key.contains('temporarily unavailable') ||
        msg.contains('temporarily unavailable') ||
        msg.contains('временно недоступно') ||
        msg.contains('попробуйте позже');
  }
  final s = e.toString().toLowerCase();
  return s.contains('temporarily unavailable') ||
      s.contains('socket') ||
      s.contains('connection');
}

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

  // Деплой/краткий 503: не отдаём ошибку сразу — иначе экран залипает
  // на красном «temporarily unavailable» у обоих игроков.
  Object? lastError;
  for (var attempt = 0; attempt < 4; attempt++) {
    try {
      return await repo.getGame(gameId);
    } catch (e) {
      lastError = e;
      if (!_isTransientGamesError(e) || attempt == 3) rethrow;
      await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
    }
  }
  Error.throwWithStackTrace(lastError!, StackTrace.current);
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
