import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException;
import 'package:multigames_client/games/uno/uno_offline_session.dart';
import 'package:multigames_client/games/uno/uno_repository.dart';

final unoRepositoryProvider = Provider<UnoRepository>((ref) {
  return UnoRepository(authRepository: ref.watch(authRepositoryProvider));
});

final unoGameProvider =
    FutureProvider.autoDispose.family<UnoGameView, String>((ref, gameId) async {
  if (OfflineUnoRegistry.instance.isOffline(gameId)) {
    final session = OfflineUnoRegistry.instance.get(gameId);
    if (session == null) throw GamesException(404, 'offline game not found');
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

  final repository = ref.watch(unoRepositoryProvider);
  final subscription = ref.listen<AsyncValue<Map<String, dynamic>>>(
    realtimeEventsProvider,
    (_, next) {
      final event = next.valueOrNull;
      if (event == null) return;
      final type = event['type']?.toString() ?? '';
      final id = event['game_id']?.toString();
      if (type == 'realtime_connected' ||
          ((type == 'game_state' || type == 'game_started') && id == gameId)) {
        ref.invalidateSelf();
      }
    },
  );
  ref.onDispose(subscription.close);

  final poll = Stream<void>.periodic(const Duration(milliseconds: 800)).listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(poll.cancel);
  return repository.getGame(gameId);
});

final unoLobbyProvider =
    FutureProvider.autoDispose.family<UnoLobbyView, String>((ref, lobbyId) {
  ref.listen<AsyncValue<Map<String, dynamic>>>(
    realtimeEventsProvider,
    (_, next) {
      final event = next.valueOrNull;
      if (event == null) return;
      final type = event['type']?.toString() ?? '';
      final id = event['lobby_id']?.toString();
      if ((type == 'lobby_updated' || type == 'game_started') &&
          id == lobbyId) {
        ref.invalidateSelf();
      }
    },
  );
  return ref.watch(unoRepositoryProvider).getLobby(lobbyId);
});

final unoOpenLobbiesProvider =
    FutureProvider.autoDispose<List<UnoLobbySummary>>((ref) {
  return ref.watch(unoRepositoryProvider).listLobbies();
});
