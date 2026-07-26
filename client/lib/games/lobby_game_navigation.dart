import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/game_navigation.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';

const lobbyGameRecoveryPollInterval = Duration(seconds: 10);

/// Тихий опрос: читает lobby/active через репозиторий, не инвалидируя
/// [lobbyDetailProvider] / [activeGameProvider] (иначе UI лобби мигает спиннером).
final lobbyGameRecoveryProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, lobbyId) async {
  final repo = ref.read(gamesRepositoryProvider);

  LobbyItem? lobby;
  ActiveGameItem? active;
  await Future.wait<void>([
    repo
        .getLobby(lobbyId)
        .then<void>((value) => lobby = value)
        .catchError((_) {}),
    repo.getActive().then<void>((value) => active = value).catchError((_) {}),
  ]);

  final lobbyGameId = lobby?.gameId?.trim();
  if (lobby?.id == lobbyId && lobbyGameId != null && lobbyGameId.isNotEmpty) {
    return lobbyGameId;
  }

  final activeGameId = active?.gameId?.trim();
  if (active?.type == 'game' &&
      active?.lobbyId == lobbyId &&
      activeGameId != null &&
      activeGameId.isNotEmpty) {
    return activeGameId;
  }
  return null;
});

class LobbyGameNavigationWatcher extends ConsumerStatefulWidget {
  const LobbyGameNavigationWatcher({
    super.key,
    required this.lobbyId,
    required this.child,
    this.pollInterval = lobbyGameRecoveryPollInterval,
    this.onRealtimeEvent,
  });

  final String lobbyId;
  final Widget child;
  final Duration pollInterval;
  final ValueChanged<Map<String, dynamic>>? onRealtimeEvent;

  @override
  ConsumerState<LobbyGameNavigationWatcher> createState() =>
      _LobbyGameNavigationWatcherState();
}

class _LobbyGameNavigationWatcherState
    extends ConsumerState<LobbyGameNavigationWatcher> {
  ProviderSubscription<AsyncValue<Map<String, dynamic>>>? _realtimeSubscription;
  ProviderSubscription<AsyncValue<LobbyItem>>? _lobbySubscription;
  Timer? _pollTimer;
  bool _pollInFlight = false;

  @override
  void initState() {
    super.initState();
    _realtimeSubscription = ref.listenManual(
      realtimeEventsProvider,
      (_, next) => next.whenData(_handleRealtimeEvent),
    );
    _lobbySubscription = ref.listenManual(
      lobbyDetailProvider(widget.lobbyId),
      (_, next) {
        final lobby = next.valueOrNull;
        if (lobby?.id == widget.lobbyId) {
          _navigate(lobby?.gameId);
        }
      },
      fireImmediately: true,
    );
    _pollTimer = Timer.periodic(widget.pollInterval, (_) => _poll());
  }

  void _handleRealtimeEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    widget.onRealtimeEvent?.call(event);
    final router = GoRouter.of(context);
    final currentPath = router.routerDelegate.currentConfiguration.uri.path;
    final gameId = realtimeGameIdForNavigation(
      event,
      currentPath: currentPath,
      expectedLobbyId: widget.lobbyId,
    );
    _navigate(gameId);
  }

  Future<void> _poll() async {
    if (!mounted || _pollInFlight) return;
    _pollInFlight = true;
    try {
      ref.invalidate(lobbyGameRecoveryProvider(widget.lobbyId));
      final gameId =
          await ref.read(lobbyGameRecoveryProvider(widget.lobbyId).future);
      if (mounted) _navigate(gameId);
    } catch (_) {
      // A later poll retries transient lobby/active-game failures.
    } finally {
      _pollInFlight = false;
    }
  }

  void _navigate(String? gameId) {
    if (!mounted || gameId == null || gameId.trim().isEmpty) return;
    final router = GoRouter.of(context);
    navigateToGame(
      router,
      ref.read(gameNavigationCoordinatorProvider),
      gameId,
      expectedLobbyId: widget.lobbyId,
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _realtimeSubscription?.close();
    _lobbySubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
