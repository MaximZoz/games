import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/core/settings_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException;
import 'package:multigames_client/games/live_game_sync.dart';
import 'package:multigames_client/games/nardy/nardy_offline_session.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';

final nardyRepositoryProvider = Provider<NardyRepository>((ref) {
  return NardyRepository(authRepository: ref.watch(authRepositoryProvider));
});

const _keyNardyAutoConfirm = 'nardy_auto_confirm';

/// Локально: после всех ходов сразу передать ход, без кнопки «Готово».
final nardyAutoConfirmProvider =
    StateNotifierProvider<PrefBoolNotifier, bool>((ref) {
  return PrefBoolNotifier(_keyNardyAutoConfirm, defaultValue: false);
});

final nardyGameProvider = AsyncNotifierProvider.autoDispose
    .family<NardyGameNotifier, NardyGameView, String>(NardyGameNotifier.new);

class NardyGameNotifier
    extends AutoDisposeFamilyAsyncNotifier<NardyGameView, String> {
  bool _httpInFlight = false;
  int _httpGen = 0;

  @override
  Future<NardyGameView> build(String arg) async {
    if (OfflineNardyRegistry.instance.isOffline(arg)) {
      final session = OfflineNardyRegistry.instance.get(arg);
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
      hasFullView: hasFullNardyView,
      onFullState: applyWs,
      onReconcile: () => unawaited(reconcile()),
    );
    return _fetchPreferringLive();
  }

  void applyWs(Map<String, dynamic> data) {
    try {
      _commit(NardyGameView.fromJson(data));
    } catch (_) {
      unawaited(reconcile());
    }
  }

  Future<void> reconcile() async {
    if (OfflineNardyRegistry.instance.isOffline(arg) || _httpInFlight) return;
    _httpInFlight = true;
    final gen = ++_httpGen;
    try {
      final fetched = await ref.read(nardyRepositoryProvider).getGame(arg);
      if (gen != _httpGen) return;
      _commit(fetched);
    } catch (_) {
    } finally {
      _httpInFlight = false;
    }
  }

  Future<NardyGameView> _fetchPreferringLive() async {
    final fetched = await fetchGameWithRetry(
      () => ref.read(nardyRepositoryProvider).getGame(arg),
    );
    final current = state.valueOrNull;
    if (current != null && isOlderNardy(fetched, current)) return current;
    return fetched;
  }

  void _commit(NardyGameView incoming) {
    final current = state.valueOrNull;
    if (current != null && isOlderNardy(incoming, current)) return;
    state = AsyncData(incoming);
  }
}

final nardyLobbyProvider = FutureProvider.autoDispose
    .family<NardyLobbyView, String>((ref, lobbyId) async {
  final repo = ref.watch(nardyRepositoryProvider);
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
