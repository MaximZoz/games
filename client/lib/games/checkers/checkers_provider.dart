import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/checkers/checkers_offline_session.dart';
import 'package:multigames_client/games/checkers/checkers_repository.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException;
import 'package:multigames_client/games/live_game_sync.dart';

final checkersRepositoryProvider = Provider<CheckersRepository>((ref) {
  return CheckersRepository(authRepository: ref.watch(authRepositoryProvider));
});

final checkersGameProvider = AsyncNotifierProvider.autoDispose
    .family<CheckersGameNotifier, CheckersGameView, String>(
        CheckersGameNotifier.new);

class CheckersGameNotifier
    extends AutoDisposeFamilyAsyncNotifier<CheckersGameView, String> {
  bool _httpInFlight = false;
  int _httpGen = 0;

  @override
  Future<CheckersGameView> build(String arg) async {
    if (OfflineCheckersRegistry.instance.isOffline(arg)) {
      final session = OfflineCheckersRegistry.instance.get(arg);
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
      hasFullView: hasFullCheckersView,
      onFullState: applyWs,
      onReconcile: () => unawaited(reconcile()),
    );
    return _fetchPreferringLive();
  }

  void applyWs(Map<String, dynamic> data) {
    try {
      _commit(CheckersGameView.fromJson(data));
    } catch (_) {
      unawaited(reconcile());
    }
  }

  Future<void> reconcile() async {
    if (OfflineCheckersRegistry.instance.isOffline(arg) || _httpInFlight) {
      return;
    }
    _httpInFlight = true;
    final gen = ++_httpGen;
    try {
      final fetched = await ref.read(checkersRepositoryProvider).getGame(arg);
      if (gen != _httpGen) return;
      _commit(fetched);
    } catch (_) {
    } finally {
      _httpInFlight = false;
    }
  }

  Future<CheckersGameView> _fetchPreferringLive() async {
    final fetched = await fetchGameWithRetry(
      () => ref.read(checkersRepositoryProvider).getGame(arg),
    );
    final current = state.valueOrNull;
    if (current != null && isOlderCheckers(fetched, current)) return current;
    return fetched;
  }

  void _commit(CheckersGameView incoming) {
    final current = state.valueOrNull;
    if (current != null && isOlderCheckers(incoming, current)) return;
    state = AsyncData(incoming);
  }
}

final checkersLobbyProvider = FutureProvider.autoDispose
    .family<CheckersLobbyView, String>((ref, lobbyId) async {
  final repo = ref.watch(checkersRepositoryProvider);
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
