import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/battleship/battleship_offline_session.dart';
import 'package:multigames_client/games/battleship/battleship_repository.dart';
import 'package:multigames_client/games/games_repository.dart' show GamesException;

final battleshipRepositoryProvider = Provider<BattleshipRepository>((ref) {
  return BattleshipRepository(authRepository: ref.watch(authRepositoryProvider));
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

final battleshipGameProvider = FutureProvider.autoDispose
    .family<BattleshipGameView, String>((ref, gameId) async {
  // Офлайн: локальная сессия + бот, тот же BattleshipGameView.
  if (OfflineBattleshipRegistry.instance.isOffline(gameId)) {
    final session = OfflineBattleshipRegistry.instance.get(gameId);
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

  final repo = ref.watch(battleshipRepositoryProvider);
  final sub = ref.listen<AsyncValue<Map<String, dynamic>>>(
    realtimeEventsProvider,
    (_, next) {
      final data = next.valueOrNull;
      if (data == null) return;
      final type = data['type']?.toString() ?? '';
      final gid = data['game_id']?.toString();
      if (type == 'realtime_connected' ||
          ((type == 'game_state' || type == 'game_started') && gid == gameId)) {
        ref.invalidateSelf();
      }
    },
  );
  ref.onDispose(sub.close);
  final poll = Stream<void>.periodic(const Duration(milliseconds: 800)).listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(poll.cancel);

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

final battleshipLobbyProvider = FutureProvider.autoDispose
    .family<BattleshipLobbyView, String>((ref, lobbyId) async {
  final repo = ref.watch(battleshipRepositoryProvider);
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
