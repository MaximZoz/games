import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/chess/chess_offline_session.dart';
import 'package:multigames_client/games/chess/chess_repository.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException;
import 'package:multigames_client/games/live_game_sync.dart';

final chessRepositoryProvider = Provider<ChessRepository>((ref) {
  return ChessRepository(authRepository: ref.watch(authRepositoryProvider));
});

final chessGameProvider = AsyncNotifierProvider.autoDispose
    .family<ChessGameNotifier, ChessGameView, String>(ChessGameNotifier.new);

class ChessGameNotifier
    extends AutoDisposeFamilyAsyncNotifier<ChessGameView, String> {
  bool _httpInFlight = false;
  int _httpGen = 0;

  @override
  Future<ChessGameView> build(String arg) async {
    if (OfflineChessRegistry.instance.isOffline(arg)) {
      final session = OfflineChessRegistry.instance.get(arg);
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
      hasFullView: hasFullChessView,
      onFullState: applyWs,
      onReconcile: () => unawaited(reconcile()),
    );
    return _fetchPreferringLive();
  }

  void applyWs(Map<String, dynamic> data) {
    try {
      _commit(ChessGameView.fromJson(data));
    } catch (_) {
      unawaited(reconcile());
    }
  }

  Future<void> reconcile() async {
    if (OfflineChessRegistry.instance.isOffline(arg) || _httpInFlight) {
      return;
    }
    _httpInFlight = true;
    final gen = ++_httpGen;
    try {
      final fetched = await ref.read(chessRepositoryProvider).getGame(arg);
      if (gen != _httpGen) return;
      _commit(fetched);
    } catch (_) {
    } finally {
      _httpInFlight = false;
    }
  }

  Future<ChessGameView> _fetchPreferringLive() async {
    final fetched = await fetchGameWithRetry(
      () => ref.read(chessRepositoryProvider).getGame(arg),
    );
    final current = state.valueOrNull;
    if (current != null && isOlderChess(fetched, current)) return current;
    return fetched;
  }

  void _commit(ChessGameView incoming) {
    final current = state.valueOrNull;
    if (current != null && isOlderChess(incoming, current)) return;
    state = AsyncData(incoming);
  }
}

final chessLobbyProvider = FutureProvider.autoDispose
    .family<ChessLobbyView, String>((ref, lobbyId) async {
  final repo = ref.watch(chessRepositoryProvider);
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
