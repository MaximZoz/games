import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/game_navigation.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';

// Fallback, если WS game_started/lobby_updated потерян. Не чаще — лишняя нагрузка в multi-лобби.
const lobbyGameRecoveryPollInterval = Duration(seconds: 15);

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
  // Только игра этого лобби — иначе битая invite-ссылка уводила
  // в чужую активную партию / «Свою игру».
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
    this.gameType = 'tictactoe',
  });

  final String lobbyId;
  final Widget child;
  final Duration pollInterval;
  final ValueChanged<Map<String, dynamic>>? onRealtimeEvent;

  /// Тип игры лобби. Используется для роутинга: `/games/<gameType>/game/...`.
  final String gameType;

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
          _navigate(lobby?.gameId, gameType: widget.gameType);
        }
      },
      fireImmediately: true,
    );
    // Сразу проверить active/lobby — не ждать первый тик таймера.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _poll();
    });
    _pollTimer = Timer.periodic(widget.pollInterval, (_) => _poll());
  }

  void _handleRealtimeEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    widget.onRealtimeEvent?.call(event);
    final type = event['type']?.toString();
    final eventLobbyId = event['lobby_id']?.toString().trim();
    if ((type == 'game_started' || type == 'lobby_updated') &&
        eventLobbyId == widget.lobbyId) {
      ref.invalidate(lobbyDetailProvider(widget.lobbyId));
    }
    final router = GoRouter.of(context);
    final currentPath = router.routerDelegate.currentConfiguration.uri.path;
    final nav = realtimeGameNavForEvent(
      event,
      currentPath: currentPath,
      expectedLobbyId: widget.lobbyId,
    );
    if (nav != null && nav.gameId.isNotEmpty) {
      _navigate(nav.gameId, gameType: nav.gameType);
      return;
    }
    // Если lobby_id в событии другой, но у нас уже есть active game — уйти сразу.
    if (type == 'game_started' || type == 'lobby_updated') {
      final raw = event['game_id']?.toString().trim();
      if (raw != null && raw.isNotEmpty) {
        unawaited(_poll());
      }
    }
  }

  Future<void> _poll() async {
    if (!mounted || _pollInFlight) return;
    _pollInFlight = true;
    try {
      ref.invalidate(lobbyGameRecoveryProvider(widget.lobbyId));
      final gameId =
          await ref.read(lobbyGameRecoveryProvider(widget.lobbyId).future);
      if (mounted) _navigate(gameId, gameType: widget.gameType);
    } catch (_) {
      // A later poll retries transient lobby/active-game failures.
    } finally {
      _pollInFlight = false;
    }
  }

  void _navigate(String? gameId, {String gameType = 'tictactoe'}) {
    if (!mounted || gameId == null || gameId.trim().isEmpty) return;
    final router = GoRouter.of(context);
    navigateToGame(
      router,
      ref.read(gameNavigationCoordinatorProvider),
      gameId,
      expectedLobbyId: widget.lobbyId,
      gameType: gameType,
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
