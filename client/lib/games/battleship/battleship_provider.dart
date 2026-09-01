import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/battleship/battleship_offline_session.dart';
import 'package:multigames_client/games/battleship/battleship_repository.dart';
import 'package:multigames_client/games/games_repository.dart' show GamesException;
import 'package:multigames_client/games/live_game_sync.dart';

final battleshipRepositoryProvider = Provider<BattleshipRepository>((ref) {
  return BattleshipRepository(authRepository: ref.watch(authRepositoryProvider));
});

final battleshipGameProvider = AsyncNotifierProvider.autoDispose
    .family<BattleshipGameNotifier, BattleshipGameView, String>(
  BattleshipGameNotifier.new,
);

class BattleshipGameNotifier
    extends AutoDisposeFamilyAsyncNotifier<BattleshipGameView, String> {
  bool _httpInFlight = false;
  int _httpGen = 0;

  @override
  Future<BattleshipGameView> build(String arg) async {
    if (OfflineBattleshipRegistry.instance.isOffline(arg)) {
      final session = OfflineBattleshipRegistry.instance.get(arg);
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
      hasFullView: hasFullBattleshipView,
      onFullState: applyWs,
      onReconcile: () => unawaited(reconcile()),
    );
    return _fetchPreferringLive();
  }

  void applyWs(Map<String, dynamic> data) {
    try {
      _commit(BattleshipGameView.fromJson(data));
    } catch (_) {
      unawaited(reconcile());
    }
  }

  Future<void> reconcile() async {
    if (OfflineBattleshipRegistry.instance.isOffline(arg) || _httpInFlight) {
      return;
    }
    _httpInFlight = true;
    final gen = ++_httpGen;
    try {
      final fetched = await ref.read(battleshipRepositoryProvider).getGame(arg);
      if (gen != _httpGen) return;
      _commit(fetched);
    } catch (_) {
    } finally {
      _httpInFlight = false;
    }
  }

  Future<BattleshipGameView> _fetchPreferringLive() async {
    final fetched = await fetchGameWithRetry(
      () => ref.read(battleshipRepositoryProvider).getGame(arg),
    );
    final current = state.valueOrNull;
    if (current != null && isOlderBattleship(fetched, current)) {
      return current;
    }
    return mergeBattleshipMeta(current, fetched);
  }

  void _commit(BattleshipGameView incoming) {
    final current = state.valueOrNull;
    final merged = mergeBattleshipMeta(current, incoming);
    if (current != null && isOlderBattleship(merged, current)) return;
    state = AsyncData(merged);
  }
}

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
