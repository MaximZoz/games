import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/settings_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/utils/relative_time.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/balance_gain_animation.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/router.dart';
import 'package:multigames_client/l10n/l10n.dart';

/// Индексы центральных клеток (запрещены для первого хода при first_move_restriction).
List<int> _centerCellIndices(int gridSize) {
  switch (gridSize) {
    case 3:
      return [4];
    case 4:
      return [5, 6, 9, 10];
    case 5:
      return [12];
    case 6:
      return [14, 15, 20, 21];
    case 7:
      return [24];
    case 8:
      return [27, 28, 35, 36];
    default:
      return [];
  }
}

const List<IconData> _presetAvatarIcons = [
  Icons.face_rounded,
  Icons.face_2_rounded,
  Icons.face_3_rounded,
  Icons.face_4_rounded,
  Icons.face_5_rounded,
  Icons.face_6_rounded,
  Icons.man_rounded,
  Icons.woman_rounded,
  Icons.person_rounded,
];

class TicTacToeGameScreen extends ConsumerStatefulWidget {
  const TicTacToeGameScreen({
    super.key,
    required this.gameId,
  });

  final String gameId;

  @override
  ConsumerState<TicTacToeGameScreen> createState() =>
      _TicTacToeGameScreenState();
}

class _TicTacToeGameScreenState extends ConsumerState<TicTacToeGameScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  bool _isMakingMove = false;
  bool _isSwapping = false;
  bool _isRematching = false;
  bool _isAcceptingRematch = false;
  String? _rematchLobbyId;
  bool _rematchDeclined = false;
  bool _iDeclinedRematch = false;
  bool _isFindingGame = false;
  bool _waitingForBotMove = false;
  Timer? _rematchPollTimer;
  Timer? _syncStateTimer;
  Timer? _chatsRefreshTimer;
  Timer? _timeoutRetryTimer;
  late AnimationController _pulseController;
  String? _prevGameStatus;
  bool _providerBindingsInitialized = false;
  ProviderSubscription<AsyncValue<Map<String, dynamic>>>? _realtimeSubscription;
  final GlobalKey _winRewardKey = GlobalKey();
  bool _balanceGainPlayed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeProviderBindings();
    final route = ModalRoute.of(context);
    if (route != null) {
      chatsRouteObserver.unsubscribe(this);
      chatsRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    if (mounted) refreshChatsList(ref, force: true);
  }

  @override
  void didUpdateWidget(covariant TicTacToeGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId) {
      _rematchPollTimer?.cancel();
      _prevGameStatus = null;
      _balanceGainPlayed = false;
      ref.invalidate(gameStateProvider(widget.gameId));
      setState(() {
        _rematchLobbyId = null;
        _rematchDeclined = false;
        _iDeclinedRematch = false;
        _isRematching = false;
        _isAcceptingRematch = false;
        _isFindingGame = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  void _initializeProviderBindings() {
    if (_providerBindingsInitialized) return;
    _providerBindingsInitialized = true;

    ref.invalidate(gameStateProvider(widget.gameId));
    ref.invalidate(activeGameProvider);
    _syncStateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || _waitingForBotMove) return;
      final game = ref.read(gameStateProvider(widget.gameId)).valueOrNull;
      if (game != null && !game.isActivePvp) return;
      ref.invalidate(gameStateProvider(widget.gameId));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) refreshChatsList(ref, force: true);
    });
    _chatsRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) refreshChatsList(ref, force: true);
    });
    _realtimeSubscription = ref.listenManual(
      realtimeEventsProvider,
      (_, next) {
        final type = next.valueOrNull?['type']?.toString() ?? '';
        if (type == 'game_state' &&
            next.valueOrNull?['game_id'] == widget.gameId &&
            !_waitingForBotMove) {
          ref.invalidate(gameStateProvider(widget.gameId));
        }
        if (type == 'lobby_updated' && _rematchLobbyId != null) {
          final lobbyId = next.valueOrNull?['lobby_id']?.toString();
          final gameId = next.valueOrNull?['game_id']?.toString();
          if (lobbyId == _rematchLobbyId && gameId != null && mounted) {
            ref.invalidate(gameStateProvider(gameId));
            ref.invalidate(activeGameProvider);
            context.go('/games/tictactoe/game/$gameId');
          }
        }
        if (type == 'invite_declined') {
          final lobbyId = next.valueOrNull?['lobby_id']?.toString();
          if (lobbyId == _rematchLobbyId && mounted) {
            _rematchPollTimer?.cancel();
            setState(() {
              _rematchLobbyId = null;
              _rematchDeclined = true;
            });
          }
        }
        if (type == 'chat_message' || type == 'chat_list_changed') {
          if (mounted) refreshChatsList(ref, force: true);
        }
      },
    );
  }

  void _startRematchPoll() {
    _rematchPollTimer?.cancel();
    if (_rematchLobbyId == null) return;
    _rematchPollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_rematchLobbyId == null || !mounted) return;
      ref.invalidate(activeGameProvider);
      try {
        final lobby =
            await ref.read(gamesRepositoryProvider).getLobby(_rematchLobbyId!);
        if (!mounted) return;
        if (lobby.gameId != null && lobby.gameId!.isNotEmpty) {
          _rematchPollTimer?.cancel();
          final gameId = lobby.gameId!;
          ref.invalidate(gameStateProvider(gameId));
          context.go('/games/tictactoe/game/$gameId');
        }
      } on GamesException catch (e) {
        if (e.statusCode == 404 && mounted) {
          _rematchPollTimer?.cancel();
          setState(() => _rematchLobbyId = null);
        }
      } catch (_) {}
    });
  }

  void _onTurnTimeExpired() {
    _timeoutRetryTimer?.cancel();
    void doRefresh() {
      ref.invalidate(gameStateProvider(widget.gameId));
      ref.invalidate(activeGameProvider);
      if (mounted) setState(() {});
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => doRefresh());
    _timeoutRetryTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      doRefresh();
      _timeoutRetryTimer = null;
    });
  }

  @override
  void dispose() {
    chatsRouteObserver.unsubscribe(this);
    _rematchPollTimer?.cancel();
    _syncStateTimer?.cancel();
    _chatsRefreshTimer?.cancel();
    _timeoutRetryTimer?.cancel();
    _realtimeSubscription?.close();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final override = ref.watch(gameStateOverrideProvider(widget.gameId));
    final gameAsync = ref.watch(gameStateProvider(widget.gameId));
    // При наличии override (после победного хода) показываем сразу, без ожидания refetch
    final effectiveGameAsync =
        override != null ? AsyncData(override) : gameAsync;
    final currentUser = ref.watch(authStateProvider).valueOrNull;

    ref.listen(gameStateProvider(widget.gameId), (_, next) {
      next.whenOrNull(
        data: (_) {
          if (!mounted) return;
          // Во время ожидания хода бота не сбрасываем override — иначе старый fetch может вернуть данные без нашего хода
          if (_waitingForBotMove) return;
          ref
              .read(gameStateInvalidateBlockedProvider(widget.gameId).notifier)
              .state = false;
          if (override != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref
                    .read(gameStateOverrideProvider(widget.gameId).notifier)
                    .state = null;
              }
            });
          }
        },
        error: (_, __) => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _waitingForBotMove = false;
            ref
                .read(
                    gameStateInvalidateBlockedProvider(widget.gameId).notifier)
                .state = false;
            context.go('/games');
          }
        }),
      );
    });
    ref.listen(activeGameProvider, (_, next) {
      final active = next.valueOrNull;
      if (active == null || active.type != 'game' || active.gameId == null) {
        return;
      }
      if (active.gameId != widget.gameId) {
        if (_rematchLobbyId == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.invalidate(gameStateProvider(active.gameId!));
            context.go('/games/tictactoe/game/${active.gameId}');
          }
        });
        return;
      }
      final game = ref.read(gameStateProvider(widget.gameId)).valueOrNull;
      if (game == null || game.status != 'active') return;
      final isMyTurnFromGame = game.isTurnOf(currentUser?.id);
      if (active.isMyTurn != isMyTurnFromGame) {
        ref.invalidate(gameStateProvider(widget.gameId));
      }
    });
    void goBack() => _handleClose(effectiveGameAsync.valueOrNull);

    return SwipeBackScope(
      onBack: goBack,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: goBack,
            icon: const Icon(Icons.close_rounded),
          ),
          title: Text(context.l10n.gamesTicTacToe),
          actions: [
            IconButton(
              icon: const Icon(Icons.rule_rounded),
              tooltip: context.l10n.gamesRulesTitle,
              onPressed: () => _showGameRules(context),
            ),
          ],
        ),
        body: effectiveGameAsync.when(
        data: (game) {
          final isOver = game.status != 'active';
          final opponentId =
              game.xUserId == currentUser?.id ? game.oUserId : game.xUserId;
          final iWonEarly = isOver &&
              ((game.status == 'x_won' && game.xUserId == currentUser?.id) ||
                  (game.status == 'o_won' && game.oUserId == currentUser?.id));
          final isDraw = isOver && game.status == 'draw';
          if (isOver &&
              (_prevGameStatus == 'active' || _prevGameStatus == null)) {
            _rematchPollTimer?.cancel();
            _prevGameStatus = game.status;
            if (currentUser != null) {
              ref
                  .read(gameInvitesProvider.notifier)
                  .removeByCreatorId(opponentId);
            }
            unawaited(_onGameSettled(
              gainedCoins: iWonEarly || isDraw,
              rewardBronze: iWonEarly
                  ? game.stakeBronze * 2
                  : isDraw
                      ? game.stakeBronze
                      : 0,
            ));
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _rematchLobbyId = null;
                  _rematchDeclined = false;
                  _iDeclinedRematch = false;
                  _isRematching = false;
                  _isFindingGame = false;
                });
              }
            });
          } else {
            _prevGameStatus = game.status;
          }
          // Полное состояние игры — источник истины для текущего хода.
          final isMyTurn = game.isTurnOf(currentUser?.id);
          final opponentName = opponentId.startsWith('bot:')
              ? context.l10n.gameBot
              : (game.xUserId == currentUser?.id
                  ? (game.oDisplayName ?? context.l10n.gameOpponent)
                  : (game.xDisplayName ?? context.l10n.gameOpponent));
          final opponentAvatarKind = game.xUserId == currentUser?.id
              ? game.oAvatarKind
              : game.xAvatarKind;
          final opponentAvatarValue = game.xUserId == currentUser?.id
              ? game.oAvatarValue
              : game.xAvatarValue;
          final opponentFrameCode = game.xUserId == currentUser?.id
              ? game.oFrameCode
              : game.xFrameCode;
          final opponentFrameColor = game.xUserId == currentUser?.id
              ? game.oFrameColor
              : game.xFrameColor;

          String statusText = '';
          if (isOver) {
            if (game.status == 'x_won') {
              final iWon = game.xUserId == currentUser?.id;
              statusText = iWon
                  ? (game.forfeit
                      ? context.l10n.gameYouWonOpponentLeft
                      : game.timeout
                          ? context.l10n.gameYouWonOpponentTimeout
                          : context.l10n.gameYouWon)
                  : (game.timeout
                      ? context.l10n.gameOpponentWonTimeout(opponentName)
                      : context.l10n.gameOpponentWon(opponentName));
            } else if (game.status == 'o_won') {
              final iWon = game.oUserId == currentUser?.id;
              statusText = iWon
                  ? (game.forfeit
                      ? context.l10n.gameYouWonOpponentLeft
                      : game.timeout
                          ? context.l10n.gameYouWonOpponentTimeout
                          : context.l10n.gameYouWon)
                  : (game.timeout
                      ? context.l10n.gameOpponentWonTimeout(opponentName)
                      : context.l10n.gameOpponentWon(opponentName));
            } else if (game.status == 'draw') {
              statusText = context.l10n.gameDraw;
            }
          } else {
            statusText = isMyTurn ? context.l10n.gamesMyTurn : context.l10n.gamesOpponentTurn;
          }

          final showSwapButton = !isOver &&
              game.canSwap &&
              isMyTurn &&
              !_isSwapping &&
              !_isMakingMove;

          final iWon = iWonEarly;
          final showRewardChip =
              isOver && (iWon || isDraw) && game.stakeBronze > 0;
          final rewardBronze =
              iWon ? game.stakeBronze * 2 : game.stakeBronze;
          final isDesktop = isWide(context);
          final narrow = isNarrow(context);
          final contentPadding = narrow ? 12.0 : 24.0;
          final verticalSpacing = narrow ? 10.0 : 20.0;
          return Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(contentPadding),
                  child: (isDesktop
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _OpponentCard(
                              opponentId: opponentId,
                              displayName: opponentName,
                              avatarKind: opponentAvatarKind,
                              avatarValue: opponentAvatarValue,
                              frameCode: opponentFrameCode,
                              frameColor: opponentFrameColor,
                              isBot: opponentId.startsWith('bot:'),
                              friendsSnapshot: ref
                                  .watch(friendsSnapshotProvider)
                                  .valueOrNull,
                              chatsList:
                                  ref.watch(chatsListProvider).valueOrNull ??
                                      const [],
                              onInfoTap: () => _showOpponentInfo(
                                context,
                                opponentId: opponentId,
                                displayName: opponentName,
                                avatarKind: opponentAvatarKind,
                                avatarValue: opponentAvatarValue,
                              ),
                              onMessageTap: () =>
                                  _openChat(context, opponentId, opponentName),
                              onAddFriendTap: (requestId) => _addFriend(
                                  context, opponentId, opponentName,
                                  requestId: requestId),
                            ),
                            SizedBox(height: verticalSpacing),
                            Text(
                              statusText,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    fontSize: narrow ? 15 : null,
                                  ),
                            ),
                            if (showRewardChip)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: _GameRewardChip(
                                  key: _winRewardKey,
                                  rewardBronze: rewardBronze,
                                ),
                              ),
                            if (showSwapButton)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: OutlinedButton.icon(
                                  onPressed: () => _swapSides(),
                                  icon: const Icon(Icons.swap_horiz_rounded,
                                      size: 18),
                                  label: Text(context.l10n.gameSwapSidesAction),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.accentStart,
                                    side: BorderSide(
                                        color: AppColors.accentStart
                                            .withValues(alpha: 0.6)),
                                  ),
                                ),
                              ),
                            if (!isOver &&
                                game.turnTimeSec > 0 &&
                                game.turnDeadline != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: _TurnCountdown(
                                  turnDeadline: game.turnDeadline!,
                                  isMyTurn: isMyTurn,
                                  onExpired: _onTurnTimeExpired,
                                ),
                              ),
                            if (isOver) ...[
                              SizedBox(height: verticalSpacing * 0.8),
                              _RematchSection(
                                rematchLobbyId: _rematchLobbyId,
                                rematchDeclined: _rematchDeclined,
                                iDeclinedRematch: _iDeclinedRematch,
                                isRematching: _isRematching,
                                isAcceptingRematch: _isAcceptingRematch,
                                isFindingGame: _isFindingGame,
                                opponentId: opponentId,
                                invites: ref.watch(gameInvitesProvider),
                                onRematch: () => _rematch(context),
                                onAccept: _acceptRematch,
                                onDecline: _declineRematch,
                                onCancelWait: _cancelRematchWait,
                                onFindGame: () => _findGame(context),
                                compact: narrow,
                              ),
                            ],
                            SizedBox(height: verticalSpacing),
                            Expanded(
                              child: Center(
                                child: _GameBoard(
                                  game: game,
                                  isMyTurn: isMyTurn,
                                  isOver: isOver,
                                  isMakingMove: _isMakingMove,
                                  onMove: _makeMove,
                                  pulseController: _pulseController,
                                  compact: narrow,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Flexible(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _OpponentCard(
                                      opponentId: opponentId,
                                      displayName: opponentName,
                                      avatarKind: opponentAvatarKind,
                                      avatarValue: opponentAvatarValue,
                                      frameCode: opponentFrameCode,
                                      frameColor: opponentFrameColor,
                                      isBot: opponentId.startsWith('bot:'),
                                      friendsSnapshot: ref
                                          .watch(friendsSnapshotProvider)
                                          .valueOrNull,
                                      chatsList: ref
                                              .watch(chatsListProvider)
                                              .valueOrNull ??
                                          const [],
                                      onInfoTap: () => _showOpponentInfo(
                                        context,
                                        opponentId: opponentId,
                                        displayName: opponentName,
                                        avatarKind: opponentAvatarKind,
                                        avatarValue: opponentAvatarValue,
                                      ),
                                      onMessageTap: () => _openChat(
                                          context, opponentId, opponentName),
                                      onAddFriendTap: (requestId) => _addFriend(
                                          context, opponentId, opponentName,
                                          requestId: requestId),
                                    ),
                                    SizedBox(height: verticalSpacing),
                                    Text(
                                      statusText,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                            fontSize: narrow ? 15 : null,
                                          ),
                                    ),
                                    if (showRewardChip)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: _GameRewardChip(
                                          key: _winRewardKey,
                                          rewardBronze: rewardBronze,
                                        ),
                                      ),
                                    if (showSwapButton)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: OutlinedButton.icon(
                                          onPressed: () => _swapSides(),
                                          icon: const Icon(
                                              Icons.swap_horiz_rounded,
                                              size: 18),
                                          label: Text(context.l10n.gameSwapSidesAction),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                AppColors.accentStart,
                                            side: BorderSide(
                                                color: AppColors.accentStart
                                                    .withValues(alpha: 0.6)),
                                          ),
                                        ),
                                      ),
                                    if (!isOver &&
                                        game.turnTimeSec > 0 &&
                                        game.turnDeadline != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: _TurnCountdown(
                                          turnDeadline: game.turnDeadline!,
                                          isMyTurn: isMyTurn,
                                          onExpired: _onTurnTimeExpired,
                                        ),
                                      ),
                                    if (isOver) ...[
                                      SizedBox(height: verticalSpacing * 0.8),
                                      _RematchSection(
                                        rematchLobbyId: _rematchLobbyId,
                                        rematchDeclined: _rematchDeclined,
                                        iDeclinedRematch: _iDeclinedRematch,
                                        isRematching: _isRematching,
                                        isAcceptingRematch: _isAcceptingRematch,
                                        isFindingGame: _isFindingGame,
                                        opponentId: opponentId,
                                        invites: ref.watch(gameInvitesProvider),
                                        onRematch: () => _rematch(context),
                                        onAccept: _acceptRematch,
                                        onDecline: _declineRematch,
                                        onCancelWait: _cancelRematchWait,
                                        onFindGame: () => _findGame(context),
                                        compact: narrow,
                                      ),
                                    ],
                                    SizedBox(height: verticalSpacing),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: _GameBoard(
                                  game: game,
                                  isMyTurn: isMyTurn,
                                  isOver: isOver,
                                  isMakingMove: _isMakingMove,
                                  onMove: _makeMove,
                                  pulseController: _pulseController,
                                  compact: narrow,
                                ),
                              ),
                            ),
                          ],
                        )),
                ),
              ),
              if (iWon)
                Positioned.fill(
                  child: _ConfettiOverlay(winnerMark: game.winner ?? 'x'),
                ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accentStart,
          ),
        ),
        error: (_, __) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accentStart,
          ),
        ),
        ),
      ),
    );
  }

  Future<void> _onGameSettled({
    required bool gainedCoins,
    required int rewardBronze,
  }) async {
    final fromBalance =
        ref.read(authStateProvider).valueOrNull?.balanceBronze ?? 0;
    await ref.read(authStateProvider.notifier).refresh();
    if (!mounted || _balanceGainPlayed || !gainedCoins || rewardBronze <= 0) {
      return;
    }
    final toBalance =
        ref.read(authStateProvider).valueOrNull?.balanceBronze ?? fromBalance;
    if (toBalance <= fromBalance) return;
    _balanceGainPlayed = true;
    // Дождаться появления чипа награды в дереве.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    await playBalanceGain(
      ref: ref,
      context: context,
      newBalanceBronze: toBalance,
      fromBronze: fromBalance,
      rewardBronze: rewardBronze,
      sourceKey: _winRewardKey,
      skipApply: true,
    );
  }

  Future<void> _rematch(BuildContext context) async {
    setState(() => _isRematching = true);
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final result = await repo.rematch(widget.gameId);
      if (!mounted) return;
      ref.invalidate(openLobbiesProvider);
      if (result.matched &&
          result.gameId != null &&
          result.gameId!.isNotEmpty) {
        setState(() => _isRematching = false);
        final gameId = result.gameId!;
        ref.invalidate(gameStateProvider(gameId));
        if (!context.mounted) return;
        context.go('/games/tictactoe/game/$gameId');
      } else {
        setState(() {
          _rematchLobbyId = result.lobbyId;
          _rematchDeclined = false;
          _iDeclinedRematch = false;
          _isRematching = false;
        });
        _startRematchPoll();
      }
    } catch (e) {
      if (mounted) _redirectToGamesOnError();
      if (mounted) setState(() => _isRematching = false);
    }
  }

  Future<void> _acceptRematch(String lobbyId) async {
    if (_isAcceptingRematch) return;
    setState(() => _isAcceptingRematch = true);
    ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
    try {
      final result = await ref.read(gamesRepositoryProvider).joinLobby(lobbyId);
      if (!context.mounted) return;
      if (result.joined && result.gameId != null) {
        final gameId = result.gameId!;
        ref.invalidate(gameStateProvider(gameId));
        if (!context.mounted) return;
        // ignore: use_build_context_synchronously
        context.go('/games/tictactoe/game/$gameId');
      }
    } on GamesException catch (e) {
      if (!context.mounted) return;
      // 409 = одновременный реванш: соперник уже принял наше приглашение, игра создана
      if (e.statusCode == 409) {
        ref.invalidate(activeGameProvider);
        final active = await ref.read(activeGameProvider.future);
        if (!mounted) return;
        if (active != null &&
            active.type == 'game' &&
            active.gameId != null &&
            active.gameId!.isNotEmpty) {
          context.go('/games/tictactoe/game/${active.gameId}');
        } else {
          _redirectToGamesOnError();
        }
      } else {
        _redirectToGamesOnError();
      }
    } catch (_) {
      if (context.mounted) _redirectToGamesOnError();
    } finally {
      if (mounted) setState(() => _isAcceptingRematch = false);
    }
  }

  Future<void> _declineRematch(String lobbyId) async {
    ref.read(gameInvitesProvider.notifier).remove(lobbyId);
    try {
      await ref.read(gamesRepositoryProvider).declineLobby(lobbyId);
    } catch (_) {}
    if (mounted) setState(() => _iDeclinedRematch = true);
  }

  Future<void> _cancelRematchWait() async {
    if (_rematchLobbyId == null) return;
    _rematchPollTimer?.cancel();
    final lobbyId = _rematchLobbyId!;
    setState(() => _rematchLobbyId = null);
    try {
      await ref.read(gamesRepositoryProvider).leaveLobby(lobbyId);
    } catch (_) {}
  }

  Future<void> _findGame(BuildContext context) async {
    setState(() => _isFindingGame = true);
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final addBotsAfter30s = ref.read(addBotsAfter30sProvider);
      final result = await repo.createLobby(
        mode: 'matchmake',
        addBotsAfter30s: addBotsAfter30s,
      );
      if (!context.mounted) return;
      ref.invalidate(openLobbiesProvider);
      if (result.matched && result.gameId != null) {
        context.go('/games/tictactoe/game/${result.gameId}');
      } else {
        context.go(
          '/games/tictactoe/lobby/${result.lobbyId}?mode=matchmake',
        );
      }
    } catch (e) {
      if (context.mounted) _redirectToGamesOnError();
    } finally {
      if (mounted) setState(() => _isFindingGame = false);
    }
  }

  void _redirectToGamesOnError() {
    if (mounted) context.go('/games');
  }

  void _handleClose(GameStateItem? game) {
    final isOver = game?.status != 'active';
    if (isOver) {
      final rematchLobbyId = _rematchLobbyId;
      _rematchLobbyId = null;
      ref.read(activeGameProvider.notifier).clearLocal();
      context.go('/games');
      if (rematchLobbyId != null) {
        unawaited(
          ref
              .read(gamesRepositoryProvider)
              .leaveLobby(rematchLobbyId)
              .catchError((_) {}),
        );
      }
      return;
    }
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.gameExitTitle),
        content: Text(
          context.l10n.gameExitConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.gameStay),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentStart,
            ),
            child: Text(context.l10n.gameLeave),
          ),
        ],
      ),
    ).then((exit) {
      if (exit != true || !mounted) return;
      final gameId = widget.gameId;
      ref.read(activeGameProvider.notifier).clearLocal();
      context.go('/games');
      unawaited(() async {
        try {
          await ref.read(gamesRepositoryProvider).forfeitGame(gameId);
        } catch (_) {}
      }());
    });
  }

  void _showOpponentInfo(
    BuildContext context, {
    required String opponentId,
    required String displayName,
    required String avatarKind,
    required String? avatarValue,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
          ),
          child: GradientCard(
            animate: false,
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(14),
            child: Consumer(
              builder: (context, ref, _) {
                final friendsSnapshot =
                    ref.watch(friendsSnapshotProvider).valueOrNull;
                final presence =
                    ref.watch(presenceMapProvider).valueOrNull ?? const {};
                final chatsList =
                    ref.watch(chatsListProvider).valueOrNull ?? const [];
                FriendUserItem? friendUser;
                for (final f in friendsSnapshot?.friends ?? []) {
                  if (f.user.id == opponentId) {
                    friendUser = f.user;
                    break;
                  }
                }
                if (friendUser == null) {
                  for (final r in friendsSnapshot?.incoming ?? []) {
                    if (r.user.id == opponentId) {
                      friendUser = r.user;
                      break;
                    }
                  }
                }
                if (friendUser == null) {
                  for (final r in friendsSnapshot?.outgoing ?? []) {
                    if (r.user.id == opponentId) {
                      friendUser = r.user;
                      break;
                    }
                  }
                }
                if (friendUser == null) {
                  for (final chat in chatsList) {
                    if (chat.user.id == opponentId) {
                      friendUser = FriendUserItem(
                        id: chat.user.id,
                        email: '',
                        displayName: chat.user.displayName,
                        avatarKind: chat.user.avatarKind,
                        avatarValue: chat.user.avatarValue,
                        age: chat.user.age,
                        gender: chat.user.gender,
                        about: chat.user.about,
                      );
                      break;
                    }
                  }
                }
                final presenceEntry = presence[opponentId];
                final statusText = presenceEntry == null
                    ? null
                    : (presenceEntry.online
                        ? context.l10n.commonOnlineCap
                        : formatLastSeen(presenceEntry.lastSeenAt));
                final about = friendUser?.about?.trim();
                final genderIcon = _genderIcon(friendUser?.gender);
                final female = _isFemaleGender(friendUser?.gender);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOpponentAvatar(
                          friendUser?.avatarKind ?? avatarKind,
                          friendUser?.avatarValue ?? avatarValue,
                          friendUser?.displayName ?? displayName,
                          22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                friendUser?.displayName?.trim().isNotEmpty ==
                                        true
                                    ? friendUser!.displayName!
                                    : displayName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (statusText != null && statusText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    statusText,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: context.l10n.commonClose,
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    if ((friendUser?.age != null && friendUser!.age! > 0) ||
                        genderIcon != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (friendUser?.age != null && friendUser!.age! > 0)
                            _buildInfoPill(
                              text: context.l10n
                                  .profileAgeYears(friendUser.age!),
                              minWidth: 72,
                            ),
                          if (genderIcon != null)
                            _buildInfoPill(
                              icon: genderIcon,
                              minWidth: 46,
                              backgroundColor: female
                                  ? const Color(0xFFFCE7F3)
                                  : AppColors.accentSoft,
                              foregroundColor: female
                                  ? const Color(0xFFBE185D)
                                  : AppColors.textPrimary,
                            ),
                        ],
                      ),
                    ],
                    if (about != null && about.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.commonAboutMe,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        about,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    PeerCollectionsSection(userId: opponentId),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addFriend(
    BuildContext ctx,
    String userId,
    String displayName, {
    String? requestId,
    void Function()? onSuccess,
  }) async {
    try {
      if (requestId != null && requestId.isNotEmpty) {
        await ref.read(friendsRepositoryProvider).acceptRequest(requestId);
        if (!mounted) return;
        onSuccess?.call();
        ref.invalidate(friendsSnapshotProvider);
        if (mounted) {
          showAppSnackBar(
            context,
            message: context.l10n.friendsRequestAccepted,
            kind: AppSnackKind.success,
          );
        }
      } else {
        await ref.read(friendsRepositoryProvider).sendRequest(userId);
        if (!mounted) return;
        onSuccess?.call();
        ref.invalidate(friendsSnapshotProvider);
        if (mounted) {
          showAppSnackBar(
            context,
            message: context.l10n.friendsRequestSent,
            kind: AppSnackKind.success,
          );
        }
      }
    } catch (e) {
      if (mounted) _redirectToGamesOnError();
    }
  }

  void _showGameRules(BuildContext context) {
    final game = ref.read(gameStateProvider(widget.gameId)).valueOrNull;
    if (game == null) return;
    final rulesText = buildTictactoeRulesText(
      gridSize: game.gridSize,
      turnTimeSec: game.turnTimeSec,
      swapRule: game.swapRule,
      firstMoveRestriction: game.firstMoveRestriction,
      stakeBronze: game.stakeBronze,
    );
    final isDesktop = MediaQuery.sizeOf(context).width >= 700;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 80 : 14,
          vertical: isDesktop ? 40 : 20,
        ),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 380 : double.infinity,
          ),
          child: GradientCard(
            animate: false,
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.gamesRulesTitle,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.commonClose,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  child: Text(
                    rulesText,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openChat(
    BuildContext ctx,
    String userId,
    String displayName, {
    void Function()? onSuccess,
  }) async {
    try {
      final chatId = await ref.read(chatsRepositoryProvider).startChat(userId);
      if (!mounted) return;
      onSuccess?.call();
      if (mounted && chatId.isNotEmpty) {
        final uri = Uri(
          path: '/chats/$chatId',
          queryParameters: {
            'name': displayName,
            'from': 'games',
            'game': '/games/tictactoe/game/${widget.gameId}',
          },
        );
        context.push(uri.toString());
      }
    } catch (e) {
      if (mounted) _redirectToGamesOnError();
    }
  }

  IconData? _genderIcon(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    switch (normalized) {
      case 'male':
      case 'm':
      case 'man':
      case 'м':
      case 'муж':
      case 'мужской':
        return Icons.male_rounded;
      case 'female':
      case 'f':
      case 'woman':
      case 'ж':
      case 'жен':
      case 'женский':
        return Icons.female_rounded;
      default:
        return null;
    }
  }

  bool _isFemaleGender(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == 'female' ||
        normalized == 'f' ||
        normalized == 'woman' ||
        normalized == 'ж' ||
        normalized == 'жен' ||
        normalized == 'женский';
  }

  Widget _buildInfoPill({
    String? text,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    double? minWidth,
  }) {
    final bg = backgroundColor ?? AppColors.accentSoft;
    final fg = foregroundColor ?? AppColors.textPrimary;
    return Container(
      constraints: BoxConstraints(minWidth: minWidth ?? 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: icon != null
          ? Icon(icon, size: 16, color: fg)
          : Text(
              text ?? '',
              style: TextStyle(fontSize: 13, color: fg),
            ),
    );
  }

  Widget _buildOpponentAvatar(
    String avatarKind,
    String? avatarValue,
    String displayName,
    double radius,
  ) {
    if (avatarKind == 'file' &&
        avatarValue != null &&
        avatarValue.trim().isNotEmpty) {
      final img = AvatarMemoryCache.fromAvatarValue(avatarValue);
      if (img != null) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: img,
        );
      }
    }
    if (avatarKind == 'preset' && avatarValue != null) {
      final idx = int.tryParse(avatarValue);
      if (idx != null && idx >= 0 && idx < _presetAvatarIcons.length) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.accentSoft,
          child: Icon(_presetAvatarIcons[idx], color: AppColors.accentStart),
        );
      }
    }
    final letter =
        displayName.trim().isEmpty ? '?' : displayName[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.accentSoft,
      child: Text(
        letter,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
      ),
    );
  }

  Future<void> _makeMove(int cell) async {
    setState(() => _isMakingMove = true);
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final response = await repo.makeMove(widget.gameId, cell);
      if (!mounted) return;
      final isBotGame = response.xUserId.startsWith('bot:') ||
          response.oUserId.startsWith('bot:');
      // Для бота: сразу блокируем invalidate, чтобы realtime/другие события не сбросили ход
      if (isBotGame) {
        _waitingForBotMove = true;
        ref
            .read(gameStateInvalidateBlockedProvider(widget.gameId).notifier)
            .state = true;
      }
      // Сразу показываем свой ход (через override)
      ref.read(gameStateOverrideProvider(widget.gameId).notifier).state =
          response;
      setState(() {}); // Принудительный ребилд, чтобы ход отрисовался сразу
      if (response.status != 'active') {
        ref.invalidate(gameStateProvider(widget.gameId));
        ref.invalidate(activeGameProvider);
      } else if (isBotGame) {
        // С ботом: ~1.5 сек задержка (бот ходит ~1 сек), затем запрос хода бота
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          _waitingForBotMove = false;
          ref
              .read(gameStateInvalidateBlockedProvider(widget.gameId).notifier)
              .state = false;
          ref.invalidate(gameStateProvider(widget.gameId));
          ref.invalidate(activeGameProvider);
        });
      } else {
        ref.invalidate(gameStateProvider(widget.gameId));
        ref.invalidate(activeGameProvider);
      }
    } catch (e) {
      if (mounted) _redirectToGamesOnError();
    } finally {
      if (mounted) setState(() => _isMakingMove = false);
    }
  }

  Future<void> _swapSides() async {
    setState(() => _isSwapping = true);
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final response = await repo.swapSides(widget.gameId);
      if (mounted) {
        ref.read(gameStateOverrideProvider(widget.gameId).notifier).state =
            response;
        ref.invalidate(gameStateProvider(widget.gameId));
        ref.invalidate(activeGameProvider);
      }
    } catch (e) {
      if (mounted) _redirectToGamesOnError();
    } finally {
      if (mounted) setState(() => _isSwapping = false);
    }
  }
}

class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final int badge;

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    final btn = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.accentStart,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(size, size),
        fixedSize: const Size(size, size),
      ),
    );
    if (badge <= 0) return SizedBox(width: size, height: size, child: btn);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          btn,
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RematchSection extends StatelessWidget {
  const _RematchSection({
    required this.rematchLobbyId,
    required this.rematchDeclined,
    required this.iDeclinedRematch,
    required this.isRematching,
    required this.isAcceptingRematch,
    required this.isFindingGame,
    required this.opponentId,
    required this.invites,
    required this.onRematch,
    required this.onAccept,
    required this.onDecline,
    required this.onCancelWait,
    required this.onFindGame,
    this.compact = false,
  });

  final String? rematchLobbyId;
  final bool rematchDeclined;
  final bool iDeclinedRematch;
  final bool isRematching;
  final bool isAcceptingRematch;
  final bool isFindingGame;
  final String opponentId;
  final List<GameInvite> invites;
  final VoidCallback onRematch;
  final void Function(String lobbyId) onAccept;
  final void Function(String lobbyId) onDecline;
  final VoidCallback? onCancelWait;
  final VoidCallback onFindGame;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rematchOffer =
        invites.where((i) => i.creatorId == opponentId).firstOrNull;

    // После нажатия «Принять» показываем часики до перехода в игру
    if (isAcceptingRematch) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_empty_rounded,
              size: 20, color: AppColors.accentStart),
          const SizedBox(width: 8),
          Text(
            context.l10n.gameConnecting,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    // Приглашение соперника показываем всегда, даже если ранее отклоняли — новое предложение.
    if (rematchOffer != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.gameRematchOffer,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: compact ? 13 : 14,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => onDecline(rematchOffer.lobbyId),
                child: Text(context.l10n.commonDecline),
              ),
              SizedBox(width: compact ? 8 : 12),
              FilledButton(
                onPressed: () => onAccept(rematchOffer.lobbyId),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentStart,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.l10n.commonAccept),
              ),
            ],
          ),
        ],
      );
    }
    if (iDeclinedRematch) {
      return _buildRematchButtons(
        context,
        isRematching: isRematching,
        isFindingGame: isFindingGame,
        onRematch: onRematch,
        onFindGame: onFindGame,
        compact: compact,
      );
    }
    if (rematchDeclined) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.gameRematchDeclined,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: compact ? 13 : 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: compact ? 8 : 12),
          _buildRematchButtons(
            context,
            isRematching: isRematching,
            isFindingGame: isFindingGame,
            onRematch: onRematch,
            onFindGame: onFindGame,
            compact: compact,
          ),
        ],
      );
    }
    if (rematchLobbyId != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_empty_rounded,
                  size: compact ? 18 : 20, color: AppColors.accentStart),
              SizedBox(width: compact ? 6 : 8),
              Text(
                context.l10n.gameWaitingOpponent,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (onCancelWait != null) ...[
            SizedBox(height: compact ? 8 : 12),
            TextButton(
              onPressed: onCancelWait,
              child: Text(context.l10n.commonCancel),
            ),
          ],
        ],
      );
    }
    return _buildRematchButtons(
      context,
      isRematching: isRematching,
      isFindingGame: isFindingGame,
      onRematch: onRematch,
      onFindGame: onFindGame,
      compact: compact,
    );
  }

  Widget _buildRematchButtons(
    BuildContext context, {
    required bool isRematching,
    required bool isFindingGame,
    required VoidCallback onRematch,
    required VoidCallback onFindGame,
    bool compact = false,
  }) {
    final btnPadding = compact
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: compact ? 8 : 12,
      runSpacing: compact ? 6 : 8,
      children: [
        FilledButton.icon(
          onPressed: isRematching ? null : onRematch,
          icon: isRematching
              ? SizedBox(
                  width: compact ? 16 : 18,
                  height: compact ? 16 : 18,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(Icons.replay_rounded, size: compact ? 18 : 20),
          label: Text(isRematching ? context.l10n.commonCreating : context.l10n.gameRematch),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentStart,
            foregroundColor: Colors.white,
            padding: btnPadding,
          ),
        ),
        OutlinedButton.icon(
          onPressed: isFindingGame ? null : onFindGame,
          icon: isFindingGame
              ? SizedBox(
                  width: compact ? 16 : 18,
                  height: compact ? 16 : 18,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.search_rounded, size: compact ? 18 : 20),
          label: Text(isFindingGame ? context.l10n.commonSearching : context.l10n.gameOtherOpponent),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentStart,
            side: BorderSide(color: AppColors.accentStart),
            padding: btnPadding,
          ),
        ),
      ],
    );
  }
}

class _OpponentCard extends StatelessWidget {
  const _OpponentCard({
    required this.opponentId,
    required this.displayName,
    required this.avatarKind,
    required this.avatarValue,
    this.frameCode,
    this.frameColor,
    this.isBot = false,
    required this.friendsSnapshot,
    required this.chatsList,
    required this.onInfoTap,
    required this.onMessageTap,
    required this.onAddFriendTap,
  });

  final String opponentId;
  final String displayName;
  final String avatarKind;
  final String? avatarValue;
  final String? frameCode;
  final String? frameColor;
  final bool isBot;
  final FriendsSnapshot? friendsSnapshot;
  final List<ChatPreviewItem> chatsList;
  final VoidCallback onInfoTap;
  final VoidCallback onMessageTap;
  final void Function(String? requestId) onAddFriendTap;

  @override
  Widget build(BuildContext context) {
    final isFriend =
        friendsSnapshot?.friends.any((f) => f.user.id == opponentId) == true;
    final outgoing = friendsSnapshot?.outgoing
            .where((r) => r.user.id == opponentId)
            .toList() ??
        [];
    final incoming = friendsSnapshot?.incoming
            .where((r) => r.user.id == opponentId)
            .toList() ??
        [];
    final hasOutgoing = outgoing.isNotEmpty;
    final hasIncoming = incoming.isNotEmpty;
    final incomingRequestId = hasIncoming ? incoming.first.requestId : null;
    final addFriendEnabled = !hasOutgoing;
    final messageBadge = chatsList
        .where((c) => c.user.id == opponentId)
        .map((c) => c.unreadCount)
        .fold<int>(0, (a, b) => a + b);

    final narrow = isNarrow(context);
    final card = GradientCard(
      padding: EdgeInsets.symmetric(
        horizontal: narrow ? 12 : 16,
        vertical: narrow ? 8 : 12,
      ),
      margin: EdgeInsets.zero,
      animate: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Tooltip(
            message: context.l10n.userInfoTitle,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onInfoTap,
                behavior: HitTestBehavior.opaque,
                child: _OpponentAvatar(
                  displayName: displayName,
                  avatarKind: avatarKind,
                  avatarValue: avatarValue,
                  frameCode: frameCode,
                  frameColor: frameColor,
                  compact: narrow,
                ),
              ),
            ),
          ),
          SizedBox(width: narrow ? 10 : 14),
          Flexible(
            child: Text(
              displayName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: narrow ? 14 : 16,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isBot) ...[
            _IconWithBadge(
              icon: Icons.chat_bubble_outline_rounded,
              badge: messageBadge,
              tooltip: context.l10n.gameWriteMessage,
              onPressed: onMessageTap,
            ),
            if (!isFriend)
              _IconWithBadge(
                icon: Icons.person_add_alt_1_rounded,
                badge: hasIncoming ? 1 : 0,
                tooltip: hasIncoming
                    ? context.l10n.friendsAcceptRequest
                    : (addFriendEnabled
                        ? context.l10n.friendsAdd
                        : context.l10n.friendsRequestSent),
                onPressed: addFriendEnabled
                    ? () =>
                        onAddFriendTap(hasIncoming ? incomingRequestId : null)
                    : null,
              ),
          ],
        ],
      ),
    );
    if (isWide(context)) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: card,
        ),
      );
    }
    return card;
  }
}

class _OpponentAvatar extends StatelessWidget {
  const _OpponentAvatar({
    required this.displayName,
    required this.avatarKind,
    required this.avatarValue,
    this.frameCode,
    this.frameColor,
    this.compact = false,
  });

  final String displayName;
  final String avatarKind;
  final String? avatarValue;
  final String? frameCode;
  final String? frameColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final r = compact ? 18.0 : 22.0;
    Widget avatar;
    if (avatarKind == 'file' &&
        avatarValue != null &&
        avatarValue!.trim().isNotEmpty) {
      final img = AvatarMemoryCache.fromAvatarValue(avatarValue);
      if (img != null) {
        avatar = CircleAvatar(
          radius: r,
          backgroundImage: img,
        );
      } else {
        avatar = _letter(r);
      }
    } else if (avatarKind == 'preset' && avatarValue != null) {
      final idx = int.tryParse(avatarValue!);
      if (idx != null && idx >= 0 && idx < _presetAvatarIcons.length) {
        avatar = CircleAvatar(
          radius: r,
          backgroundColor: AppColors.accentSoft,
          child: Icon(_presetAvatarIcons[idx], color: AppColors.accentStart),
        );
      } else {
        avatar = _letter(r);
      }
    } else {
      avatar = _letter(r);
    }
    return FramedAvatar(
      size: r * 2,
      borderWidth: compact ? 2.4 : 3.0,
      frameCode: frameCode,
      frameColor: frameColor,
      child: avatar,
    );
  }

  Widget _letter(double r) {
    final letter =
        displayName.trim().isEmpty ? '?' : displayName[0].toUpperCase();
    return CircleAvatar(
      radius: r,
      backgroundColor: AppColors.accentSoft,
      child: Text(
        letter,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 14 : 16,
        ),
      ),
    );
  }
}

class _GameBoard extends StatelessWidget {
  const _GameBoard({
    required this.game,
    required this.isMyTurn,
    required this.isOver,
    required this.isMakingMove,
    required this.onMove,
    required this.pulseController,
    this.compact = false,
  });

  final GameStateItem game;
  final bool isMyTurn;
  final bool isOver;
  final bool isMakingMove;
  final ValueChanged<int> onMove;
  final AnimationController pulseController;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final gridSize = game.gridSize;
    final n = gridSize * gridSize;
    return LayoutBuilder(
      builder: (context, constraints) {
        var maxW = constraints.maxWidth;
        var maxH = constraints.maxHeight;
        if (!maxW.isFinite) maxW = 400;
        if (!maxH.isFinite) maxH = 400;
        final minBoard = compact ? 140.0 : 200.0;
        final maxBoard = compact ? 380.0 : 420.0;
        final maxSide = (maxW > maxH ? maxH : maxW).clamp(minBoard, maxBoard);
        final boardSize = maxSide;
        final boardMargin = compact ? 8.0 : 12.0;
        return Center(
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 16,
              vertical: boardMargin,
            ),
            width: boardSize,
            height: boardSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(
                    compact ? 6 : (boardSize > 280 ? 12 : 8),
                  ),
                  child: _WinningLineOverlay(
                    winningCells: game.effectiveWinningCells,
                    gridSize: gridSize,
                    child: CustomPaint(
                      painter: _GridPainter(gridSize: gridSize),
                      child: LayoutBuilder(
                        builder: (context, innerConstraints) {
                          final cellW = innerConstraints.maxWidth / gridSize;
                          final cellH = innerConstraints.maxHeight / gridSize;
                          final gap = boardSize > 280 ? 4.0 : 2.0;
                          final isFirstMoveX = game.turn == 'x' &&
                              game.board.every((c) => c.isEmpty);
                          final forbiddenCenters =
                              game.firstMoveRestriction && isFirstMoveX
                                  ? _centerCellIndices(gridSize)
                                  : <int>[];
                          return Stack(
                            children: List.generate(n, (i) {
                              final row = i ~/ gridSize;
                              final col = i % gridSize;
                              final cell =
                                  i < game.board.length ? game.board[i] : '';
                              final isForbiddenCenter =
                                  cell.isEmpty && forbiddenCenters.contains(i);
                              final cellCanTap = cell.isEmpty &&
                                  !isForbiddenCenter &&
                                  isMyTurn &&
                                  !isOver &&
                                  !isMakingMove;
                              return Positioned(
                                left: col * cellW + gap,
                                top: row * cellH + gap,
                                width: cellW - gap * 2,
                                height: cellH - gap * 2,
                                child: _AnimatedGameCell(
                                  symbol: cell,
                                  isMyTurn:
                                      isMyTurn && !isOver && !isMakingMove,
                                  canTap: cellCanTap,
                                  isForbidden: isForbiddenCenter,
                                  onTap: cellCanTap ? () => onMove(i) : null,
                                  pulse: cellCanTap ? pulseController : null,
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WinningLineOverlay extends StatefulWidget {
  const _WinningLineOverlay({
    required this.winningCells,
    required this.gridSize,
    required this.child,
  });

  final List<int>? winningCells;
  final int gridSize;
  final Widget child;

  @override
  State<_WinningLineOverlay> createState() => _WinningLineOverlayState();
}

class _WinningLineOverlayState extends State<_WinningLineOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wc = widget.winningCells;
    if (wc == null || wc.length < 3) {
      return widget.child;
    }
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return CustomPaint(
                  painter: _WinningLinePainter(
                    winningCells: wc,
                    gridSize: widget.gridSize,
                    progress: _animation.value,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _WinningLinePainter extends CustomPainter {
  _WinningLinePainter({
    required this.winningCells,
    required this.gridSize,
    required this.progress,
  });

  final List<int> winningCells;
  final int gridSize;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (winningCells.length < 3 || size.width <= 0 || size.height <= 0) {
      return;
    }
    final cellW = size.width / gridSize;
    final cellH = size.height / gridSize;
    final points = winningCells.map((i) {
      final row = i ~/ gridSize;
      final col = i % gridSize;
      return Offset(
        (col + 0.5) * cellW,
        (row + 0.5) * cellH,
      );
    }).toList();

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final pathMetrics = path.computeMetrics();
    final totalLength = pathMetrics.isEmpty ? 0.0 : pathMetrics.first.length;
    final drawLength = totalLength * progress;

    final lineWidth = gridSize <= 3 ? 6.0 : (gridSize == 4 ? 5.0 : 4.0);
    final glowPaint = Paint()
      ..color = AppColors.accentStart.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth + 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final strokePaint = Paint()
      ..color = AppColors.accentStart
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (drawLength > 0 && pathMetrics.isNotEmpty) {
      final extractPath = pathMetrics.first.extractPath(0.0, drawLength);
      canvas.drawPath(extractPath, glowPaint);
      canvas.drawPath(extractPath, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WinningLinePainter old) =>
      old.progress != progress ||
      old.winningCells != winningCells ||
      old.gridSize != gridSize;
}

/// Чип награды после победы / ничьей — источник полёта монеты в баланс.
class _GameRewardChip extends StatelessWidget {
  const _GameRewardChip({
    super.key,
    required this.rewardBronze,
  });

  final int rewardBronze;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.accentSoft.withValues(alpha: 0.9),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+${formatStakeAmount(rewardBronze)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          CoinIcon(
            coinType: stakeCoinType(rewardBronze),
            size: 22,
            showBorder: true,
          ),
        ],
      ),
    );
  }
}

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay({required this.winnerMark});

  final String winnerMark;

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  static const _particleCount = 150;
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();

    final r = math.Random();
    final colors = [
      AppColors.accentStart,
      AppColors.accentEnd,
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
    ];
    for (var i = 0; i < _particleCount; i++) {
      final angle = r.nextDouble() * 2 * math.pi;
      final speed = 350 + r.nextDouble() * 450;
      _particles.add(_ConfettiParticle(
        startX: 0.5,
        startY: 0.9,
        angle: angle,
        speed: speed,
        color: colors[r.nextInt(colors.length)],
        size: 4 + r.nextDouble() * 6,
        rotationSpeed: (r.nextDouble() * 2 - 1) * 8,
        gravity: 280 + r.nextDouble() * 120,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiParticle {
  _ConfettiParticle({
    required this.startX,
    required this.startY,
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.rotationSpeed,
    required this.gravity,
  });

  final double startX;
  final double startY;
  final double angle;
  final double speed;
  final Color color;
  final double size;
  final double rotationSpeed;
  final double gravity;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  final List<_ConfettiParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.35;
    const burstT = 0.12;
    const fadeStart = 0.55;
    final minDim = math.min(size.width, size.height);
    final scale = minDim / 400;

    for (final p in particles) {
      double t = progress;
      if (t < burstT) {
        t = t / burstT;
        final x = centerX + math.cos(p.angle) * p.speed * t * scale;
        final y = centerY + math.sin(p.angle) * p.speed * t * scale;
        const alpha = 1.0;
        _drawParticle(canvas, x, y, p, t * 2 * math.pi, alpha);
      } else {
        final fallT = (progress - burstT) / (1 - burstT);
        final burstX = centerX + math.cos(p.angle) * p.speed * scale;
        final burstY = centerY + math.sin(p.angle) * p.speed * scale;
        final x = burstX + math.sin(fallT * 2) * 20;
        final y = burstY + p.gravity * fallT * fallT * scale * 1.5;
        final rot = fallT * p.rotationSpeed * math.pi;
        final alpha =
            1.0 - ((progress - fadeStart) / (1 - fadeStart)).clamp(0.0, 1.0);
        if (alpha > 0.01) {
          _drawParticle(canvas, x, y, p, rot, alpha);
        }
      }
    }
  }

  void _drawParticle(
    Canvas canvas,
    double x,
    double y,
    _ConfettiParticle p,
    double rotation,
    double alpha,
  ) {
    final paint = Paint()
      ..color = p.color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: p.size,
        height: p.size * 0.6,
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.gridSize});
  final int gridSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentSoft.withValues(alpha: 0.8)
      ..strokeWidth = gridSize <= 3 ? 3 : (gridSize == 4 ? 2.5 : 2)
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final cellW = w / gridSize;
    final cellH = h / gridSize;

    for (var i = 1; i < gridSize; i++) {
      canvas.drawLine(
        Offset(cellW * i, 0),
        Offset(cellW * i, h),
        paint,
      );
      canvas.drawLine(
        Offset(0, cellH * i),
        Offset(w, cellH * i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.gridSize != gridSize;
}

class _TurnCountdown extends StatefulWidget {
  const _TurnCountdown({
    required this.turnDeadline,
    required this.isMyTurn,
    required this.onExpired,
  });

  final int turnDeadline; // Unix sec
  final bool isMyTurn;
  final VoidCallback onExpired;

  @override
  State<_TurnCountdown> createState() => _TurnCountdownState();
}

class _TurnCountdownState extends State<_TurnCountdown> {
  Timer? _timer;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
      if (_remaining <= 0) {
        _timer?.cancel();
        widget.onExpired();
      }
    });
  }

  void _updateRemaining() {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final r = widget.turnDeadline - now;
    if (r != _remaining && mounted) {
      setState(() => _remaining = r.clamp(0, 999));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _remaining <= 5 && widget.isMyTurn
        ? Colors.red
        : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          context.l10n.gameSecondsLeft(_remaining),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _AnimatedGameCell extends StatelessWidget {
  const _AnimatedGameCell({
    required this.symbol,
    required this.isMyTurn,
    required this.canTap,
    this.isForbidden = false,
    this.onTap,
    this.pulse,
  });

  final String symbol;
  final bool isMyTurn;
  final bool canTap;
  final bool isForbidden;
  final VoidCallback? onTap;
  final AnimationController? pulse;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.short,
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        return Transform.scale(
          scale: symbol.isNotEmpty ? t : 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isForbidden
                      ? Colors.grey.withValues(alpha: 0.15)
                      : canTap && isMyTurn
                          ? AppColors.accentSoft.withValues(alpha: 0.25)
                          : Colors.transparent,
                ),
                child: pulse != null && canTap && isMyTurn
                    ? AnimatedBuilder(
                        animation: pulse!,
                        builder: (context, _) {
                          final alpha = 0.2 +
                              0.12 * (0.5 + 0.5 * (pulse!.value * 2 - 1).abs());
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: AppColors.accentStart
                                  .withValues(alpha: alpha),
                            ),
                            child: Center(
                              child: _SymbolWidget(symbol: symbol),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: _SymbolWidget(symbol: symbol),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SymbolWidget extends StatelessWidget {
  const _SymbolWidget({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    if (symbol.isEmpty) return const SizedBox.shrink();
    final isX = symbol == 'x';
    final color = isX ? AppColors.accentStart : AppColors.accentEnd;
    return FittedBox(
      fit: BoxFit.contain,
      child: AnimatedSwitcher(
        duration: AppDurations.short,
        child: CustomPaint(
          key: ValueKey(symbol),
          size: const Size.square(42),
          painter: _SymbolPainter(isX: isX, color: color),
        ),
      ),
    );
  }
}

/// Рисует X и O через Canvas — без шрифтов, чтобы не было placeholder при загрузке.
class _SymbolPainter extends CustomPainter {
  _SymbolPainter({required this.isX, required this.color});

  final bool isX;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.12;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (isX) {
      final padding = size.width * 0.15;
      canvas.drawLine(
        Offset(padding, padding),
        Offset(size.width - padding, size.height - padding),
        paint,
      );
      canvas.drawLine(
        Offset(size.width - padding, padding),
        Offset(padding, size.height - padding),
        paint,
      );
    } else {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        (size.width - strokeWidth) / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SymbolPainter old) =>
      old.isX != isX || old.color != color;
}
