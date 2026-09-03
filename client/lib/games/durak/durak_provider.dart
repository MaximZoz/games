import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/durak/durak_offline_session.dart';
import 'package:multigames_client/games/durak/durak_repository.dart';
import 'package:multigames_client/games/games_repository.dart' show GamesException;
import 'package:multigames_client/games/live_game_sync.dart';

final durakRepositoryProvider = Provider<DurakRepository>((ref) {
  return DurakRepository(authRepository: ref.watch(authRepositoryProvider));
});

/// Кэш view конкретной партии: полный WS сразу, HTTP — сверка.
final durakGameProvider = AsyncNotifierProvider.autoDispose
    .family<DurakGameNotifier, DurakGameView, String>(
  DurakGameNotifier.new,
);

class DurakGameNotifier
    extends AutoDisposeFamilyAsyncNotifier<DurakGameView, String> {
  bool _httpInFlight = false;
  int _httpGen = 0;

  @override
  Future<DurakGameView> build(String arg) async {
    if (OfflineDurakRegistry.instance.isOffline(arg)) {
      final session = OfflineDurakRegistry.instance.get(arg);
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
      hasFullView: hasFullDurakView,
      onFullState: applyWs,
      onReconcile: () => unawaited(reconcile()),
    );
    return _fetchPreferringLive();
  }

  void applyWs(Map<String, dynamic> data) {
    try {
      _commit(DurakGameView.fromJson(data));
    } catch (_) {
      unawaited(reconcile());
    }
  }

  Future<void> reconcile() async {
    if (OfflineDurakRegistry.instance.isOffline(arg) || _httpInFlight) return;
    _httpInFlight = true;
    final gen = ++_httpGen;
    try {
      final fetched = await ref.read(durakRepositoryProvider).getGame(arg);
      if (gen != _httpGen) return;
      _commit(fetched);
    } catch (_) {
    } finally {
      _httpInFlight = false;
    }
  }

  Future<DurakGameView> _fetchPreferringLive() async {
    final fetched = await fetchGameWithRetry(
      () => ref.read(durakRepositoryProvider).getGame(arg),
    );
    final current = state.valueOrNull;
    if (current != null && isOlderDurak(fetched, current)) {
      return current;
    }
    return fetched;
  }

  void _commit(DurakGameView incoming) {
    final current = state.valueOrNull;
    if (current != null && isOlderDurak(incoming, current)) return;
    state = AsyncData(incoming);
  }
}

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
final durakOpenLobbiesProvider =
    FutureProvider.autoDispose<List<DurakLobbyView>>((ref) async {
  final repo = ref.watch(durakRepositoryProvider);
  return repo.listLobbies();
});
