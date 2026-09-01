import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException;
import 'package:multigames_client/games/live_game_sync.dart';
import 'package:multigames_client/games/uno/uno_offline_session.dart';
import 'package:multigames_client/games/uno/uno_repository.dart';

final unoRepositoryProvider = Provider<UnoRepository>((ref) {
  return UnoRepository(authRepository: ref.watch(authRepositoryProvider));
});

final unoGameProvider = AsyncNotifierProvider.autoDispose
    .family<UnoGameNotifier, UnoGameView, String>(
  UnoGameNotifier.new,
);

class UnoGameNotifier
    extends AutoDisposeFamilyAsyncNotifier<UnoGameView, String> {
  bool _httpInFlight = false;
  int _httpGen = 0;

  @override
  Future<UnoGameView> build(String arg) async {
    if (OfflineUnoRegistry.instance.isOffline(arg)) {
      final session = OfflineUnoRegistry.instance.get(arg);
      if (session == null) throw GamesException(404, 'offline game not found');
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
      hasFullView: hasFullUnoView,
      onFullState: applyWs,
      onReconcile: () => unawaited(reconcile()),
    );
    return _fetchPreferringLive();
  }

  void applyWs(Map<String, dynamic> data) {
    try {
      _commit(UnoGameView.fromJson(data));
    } catch (_) {
      unawaited(reconcile());
    }
  }

  Future<void> reconcile() async {
    if (OfflineUnoRegistry.instance.isOffline(arg) || _httpInFlight) return;
    _httpInFlight = true;
    final gen = ++_httpGen;
    try {
      final fetched = await ref.read(unoRepositoryProvider).getGame(arg);
      if (gen != _httpGen) return;
      _commit(fetched);
    } catch (_) {
    } finally {
      _httpInFlight = false;
    }
  }

  Future<UnoGameView> _fetchPreferringLive() async {
    final fetched = await fetchGameWithRetry(
      () => ref.read(unoRepositoryProvider).getGame(arg),
    );
    final current = state.valueOrNull;
    if (current != null && isOlderUno(fetched, current)) {
      return current;
    }
    return fetched;
  }

  void _commit(UnoGameView incoming) {
    final current = state.valueOrNull;
    if (current != null && isOlderUno(incoming, current)) return;
    state = AsyncData(incoming);
  }
}

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
