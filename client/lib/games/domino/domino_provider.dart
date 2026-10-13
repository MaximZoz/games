import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/domino/domino_offline_session.dart';
import 'package:multigames_client/games/domino/domino_repository.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException;
import 'package:multigames_client/games/live_game_sync.dart';

final dominoRepositoryProvider = Provider<DominoRepository>((ref) {
  return DominoRepository(authRepository: ref.watch(authRepositoryProvider));
});

final dominoGameProvider = AsyncNotifierProvider.autoDispose
    .family<DominoGameNotifier, DominoGameView, String>(
  DominoGameNotifier.new,
);

class DominoGameNotifier
    extends AutoDisposeFamilyAsyncNotifier<DominoGameView, String> {
  bool _httpInFlight = false;
  int _httpGen = 0;

  @override
  Future<DominoGameView> build(String arg) async {
    if (OfflineDominoRegistry.instance.isOffline(arg)) {
      final session = OfflineDominoRegistry.instance.get(arg);
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
      session.ensureStarted();
      return session.view;
    }

    listenLiveGameSync(
      ref: ref,
      gameId: arg,
      hasFullView: hasFullDominoView,
      onFullState: applyWs,
      onReconcile: () => unawaited(reconcile()),
    );
    return _fetchPreferringLive();
  }

  void applyWs(Map<String, dynamic> data) {
    try {
      _commit(DominoGameView.fromJson(data));
    } catch (_) {
      unawaited(reconcile());
    }
  }

  Future<void> reconcile() async {
    if (OfflineDominoRegistry.instance.isOffline(arg) || _httpInFlight) return;
    _httpInFlight = true;
    final gen = ++_httpGen;
    try {
      final fetched = await ref.read(dominoRepositoryProvider).getGame(arg);
      if (gen != _httpGen) return;
      _commit(fetched);
    } catch (_) {
    } finally {
      _httpInFlight = false;
    }
  }

  Future<DominoGameView> _fetchPreferringLive() async {
    final fetched = await fetchGameWithRetry(
      () => ref.read(dominoRepositoryProvider).getGame(arg),
    );
    final current = state.valueOrNull;
    if (current != null && isOlderDomino(fetched, current)) return current;
    return fetched;
  }

  void _commit(DominoGameView incoming) {
    final current = state.valueOrNull;
    if (current != null && isOlderDomino(incoming, current)) return;
    state = AsyncData(incoming);
  }
}

final dominoLobbyProvider =
    FutureProvider.autoDispose.family<DominoLobbyView, String>((ref, lobbyId) {
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
  return ref.watch(dominoRepositoryProvider).getLobby(lobbyId);
});
