import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/connect4/connect4_offline_session.dart';
import 'package:multigames_client/games/connect4/connect4_repository.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException;
import 'package:multigames_client/games/live_game_sync.dart';

final connect4RepositoryProvider = Provider<Connect4Repository>((ref) {
  return Connect4Repository(authRepository: ref.watch(authRepositoryProvider));
});

final connect4GameProvider = AsyncNotifierProvider.autoDispose
    .family<Connect4GameNotifier, Connect4GameView, String>(
        Connect4GameNotifier.new);

class Connect4GameNotifier
    extends AutoDisposeFamilyAsyncNotifier<Connect4GameView, String> {
  bool _httpInFlight = false;
  int _httpGen = 0;

  @override
  Future<Connect4GameView> build(String arg) async {
    if (OfflineConnect4Registry.instance.isOffline(arg)) {
      final session = OfflineConnect4Registry.instance.get(arg);
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
      hasFullView: hasFullConnect4View,
      onFullState: applyWs,
      onReconcile: () => unawaited(reconcile()),
    );
    return _fetchPreferringLive();
  }

  void applyWs(Map<String, dynamic> data) {
    try {
      _commit(Connect4GameView.fromJson(data));
    } catch (_) {
      unawaited(reconcile());
    }
  }

  Future<void> reconcile() async {
    if (OfflineConnect4Registry.instance.isOffline(arg) || _httpInFlight) {
      return;
    }
    _httpInFlight = true;
    final gen = ++_httpGen;
    try {
      final fetched = await ref.read(connect4RepositoryProvider).getGame(arg);
      if (gen != _httpGen) return;
      _commit(fetched);
    } catch (_) {
    } finally {
      _httpInFlight = false;
    }
  }

  Future<Connect4GameView> _fetchPreferringLive() async {
    final fetched = await fetchGameWithRetry(
      () => ref.read(connect4RepositoryProvider).getGame(arg),
    );
    final current = state.valueOrNull;
    if (current != null && isOlderConnect4(fetched, current)) return current;
    return fetched;
  }

  void _commit(Connect4GameView incoming) {
    final current = state.valueOrNull;
    if (current != null && isOlderConnect4(incoming, current)) return;
    state = AsyncData(incoming);
  }
}

final connect4LobbyProvider = FutureProvider.autoDispose
    .family<Connect4LobbyView, String>((ref, lobbyId) async {
  final repo = ref.watch(connect4RepositoryProvider);
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
