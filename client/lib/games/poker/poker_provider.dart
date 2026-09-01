import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/games_repository.dart' show GamesException;
import 'package:multigames_client/games/live_game_sync.dart';
import 'package:multigames_client/games/poker/poker_offline_session.dart';
import 'package:multigames_client/games/poker/poker_repository.dart';

final pokerRepositoryProvider = Provider<PokerRepository>((ref) {
  return PokerRepository(authRepository: ref.watch(authRepositoryProvider));
});

/// Кэш view конкретной партии: полный WS сразу, HTTP — сверка.
final pokerGameProvider = AsyncNotifierProvider.autoDispose
    .family<PokerGameNotifier, PokerGameView, String>(
  PokerGameNotifier.new,
);

class PokerGameNotifier
    extends AutoDisposeFamilyAsyncNotifier<PokerGameView, String> {
  bool _httpInFlight = false;
  int _httpGen = 0;

  @override
  Future<PokerGameView> build(String arg) async {
    if (OfflinePokerRegistry.instance.isOffline(arg)) {
      final session = OfflinePokerRegistry.instance.get(arg);
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
      hasFullView: hasFullPokerView,
      onFullState: applyWs,
      onReconcile: () => unawaited(reconcile()),
    );
    return _fetchPreferringLive();
  }

  void applyWs(Map<String, dynamic> data) {
    try {
      _commit(PokerGameView.fromJson(data));
    } catch (_) {
      unawaited(reconcile());
    }
  }

  Future<void> reconcile() async {
    if (OfflinePokerRegistry.instance.isOffline(arg) || _httpInFlight) return;
    _httpInFlight = true;
    final gen = ++_httpGen;
    try {
      final fetched = await ref.read(pokerRepositoryProvider).getGame(arg);
      if (gen != _httpGen) return;
      _commit(fetched);
    } catch (_) {
    } finally {
      _httpInFlight = false;
    }
  }

  Future<PokerGameView> _fetchPreferringLive() async {
    final fetched = await fetchGameWithRetry(
      () => ref.read(pokerRepositoryProvider).getGame(arg),
    );
    final current = state.valueOrNull;
    if (current != null && isOlderPoker(fetched, current)) {
      return current;
    }
    return fetched;
  }

  void _commit(PokerGameView incoming) {
    final current = state.valueOrNull;
    if (current != null && isOlderPoker(incoming, current)) return;
    state = AsyncData(incoming);
  }
}

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
