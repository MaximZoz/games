import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/poker/poker_offline_session.dart';
import 'package:multigames_client/games/poker/poker_repository.dart';
import 'package:multigames_client/games/games_repository.dart' show GamesException;

final pokerRepositoryProvider = Provider<PokerRepository>((ref) {
  return PokerRepository(authRepository: ref.watch(authRepositoryProvider));
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
final pokerGameProvider = FutureProvider.autoDispose
    .family<PokerGameView, String>((ref, gameId) async {
  // Офлайн: локальная сессия + боты, тот же PokerGameView.
  if (OfflinePokerRegistry.instance.isOffline(gameId)) {
    final session = OfflinePokerRegistry.instance.get(gameId);
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
    session.ensureStarted();
    return session.view;
  }

  final repo = ref.watch(pokerRepositoryProvider);
  final sub = ref.listen<AsyncValue<Map<String, dynamic>>>(
    realtimeEventsProvider,
    (_, next) {
      final data = next.valueOrNull;
      if (data == null) return;
      final type = data['type']?.toString() ?? '';
      final gid = data['game_id']?.toString();
      // Рефетч по состоянию игры и при реконнекте WS (иначе оба «ждут соперника»).
      if (type == 'realtime_connected' ||
          ((type == 'game_state' || type == 'game_started') && gid == gameId)) {
        ref.invalidateSelf();
      }
    },
  );
  ref.onDispose(sub.close);

  // Лёгкий poll — страховка, если ping game_state потерялся.
  final poll = Stream.periodic(const Duration(seconds: 4)).listen((_) {
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

/// Детальный view лобби.
final pokerLobbyProvider = FutureProvider.autoDispose
    .family<PokerLobbyView, String>((ref, lobbyId) async {
  final repo = ref.watch(pokerRepositoryProvider);
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

/// Открытые лобби покера.
final pokerOpenLobbiesProvider =
    FutureProvider.autoDispose<List<PokerLobbySummary>>((ref) async {
  final repo = ref.watch(pokerRepositoryProvider);
  return repo.listLobbies();
});
