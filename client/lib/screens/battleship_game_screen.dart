import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/battleship/battleship_provider.dart';
import 'package:multigames_client/games/battleship/battleship_repository.dart';
import 'package:multigames_client/games/battleship/battleship_utils.dart';
import 'package:multigames_client/games/game_stake.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException;
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/utils/user_error.dart';

/// Цвета клеток Морского боя.
const Color _kWater = Color(0xFF90CAF9);
const Color _kShip = Color(0xFF607D8B);
const Color _kHit = Color(0xFFE53935);
const Color _kMiss = Color(0xFFFFFFFF);
const Color _kSelectedShip = Color(0xFF455A64);

class BattleshipGameScreen extends ConsumerStatefulWidget {
  const BattleshipGameScreen({super.key, required this.gameId});
  final String gameId;

  @override
  ConsumerState<BattleshipGameScreen> createState() =>
      _BattleshipGameScreenState();
}

class _BattleshipGameScreenState extends ConsumerState<BattleshipGameScreen> {
  bool _busy = false;
  bool _providerBindingsInitialized = false;
  bool _isRematching = false;
  bool _isAcceptingRematch = false;
  String? _rematchLobbyId;
  bool _rematchDeclined = false;
  bool _iDeclinedRematch = false;
  bool _isFindingGame = false;
  Timer? _rematchPollTimer;
  ProviderSubscription<AsyncValue<Map<String, dynamic>>>? _realtimeSubscription;
  final GlobalKey _winRewardKey = GlobalKey();
  bool _balanceGainPlayed = false;
  String? _prevGameStatus;

  /// Локальная расстановка на фазе setup.
  List<List<int>> _localShips = const [];
  int? _selectedShipIndex;
  bool _shipsSyncedFromServer = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeProviderBindings();
  }

  @override
  void didUpdateWidget(covariant BattleshipGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId) {
      _rematchPollTimer?.cancel();
      _shipsSyncedFromServer = false;
      _localShips = const [];
      _selectedShipIndex = null;
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
  void dispose() {
    _rematchPollTimer?.cancel();
    _realtimeSubscription?.close();
    super.dispose();
  }

  void _initializeProviderBindings() {
    if (_providerBindingsInitialized) return;
    _providerBindingsInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final known = ref.read(battleshipGameProvider(widget.gameId)).valueOrNull;
      if (known != null && known.isOver) {
        _clearSessionForFinishedGame();
      } else {
        pinBlockingGame(ref, widget.gameId, gameType: 'battleship');
        final prev = ref.read(activeGameProvider).valueOrNull;
        if (prev?.gameId != widget.gameId) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: widget.gameId,
                  lobbyId: prev?.lobbyId,
                  gameType: 'battleship',
                ),
              );
        }
      }
      unawaited(ref.read(activeGameProvider.notifier).refresh());
    });
  }

  void _clearSessionForFinishedGame() {
    clearBlockingGamePin(ref, ifGameId: widget.gameId);
    final prev = ref.read(activeGameProvider).valueOrNull;
    if (prev?.gameId == widget.gameId) {
      ref.read(activeGameProvider.notifier).clearLocal();
    }
  }

  bool _iAmReady(BattleshipGameView game, String? me) {
    if (me == null || me.isEmpty) return false;
    if (me == game.p1UserId) return game.p1Ready;
    if (me == game.p2UserId) return game.p2Ready;
    return false;
  }

  bool _isWinner(BattleshipGameView game, String? me) {
    final w = game.winner?.trim() ?? '';
    return me != null && me.isNotEmpty && w == me;
  }

  String _statusText(BattleshipGameView game, String? me) {
    final l10n = context.l10n;
    if (game.isOver) {
      return _isWinner(game, me)
          ? l10n.gamesBattleshipYouWon
          : l10n.gameYouLost;
    }
    if (game.isSetup) {
      if (_iAmReady(game, me)) {
        return l10n.gamesBattleshipWaitingOpponentSetup;
      }
      return '';
    }
    if (game.isMyTurn) return l10n.gamesMyTurn;
    return l10n.gamesOpponentTurn;
  }

  int _rewardChipBronze(BattleshipGameView game, String? me) {
    if (game.stakeBronze <= 0 || !game.isOver) return 0;
    if (_isWinner(game, me)) {
      return stakeWinnerNetProfit(
        stake: game.stakeBronze,
        playerCount: 2,
        winnerCount: 1,
      );
    }
    return -game.stakeBronze;
  }

  Future<void> _onGameSettled({
    required int creditBronze,
    required int displayRewardBronze,
    int lostBronze = 0,
  }) async {
    if (_balanceGainPlayed) {
      unawaited(ref.read(authStateProvider.notifier).refresh());
      return;
    }
    _balanceGainPlayed = true;
    if (lostBronze > 0 && creditBronze <= 0) {
      await playGameSettledLoss(
        ref: ref,
        context: context,
        lostBronze: lostBronze,
        targetKey: _winRewardKey,
      );
      return;
    }
    await playGameSettledReward(
      ref: ref,
      context: context,
      creditBronze: creditBronze,
      displayRewardBronze: displayRewardBronze,
      sourceKey: displayRewardBronze > 0 ? _winRewardKey : null,
    );
  }

  void _maybeSettleGame(BattleshipGameView game, String? me) {
    if (!game.isOver) {
      _prevGameStatus = game.status;
      return;
    }
    if (_prevGameStatus == 'over') return;
    _prevGameStatus = 'over';
    final iWon = _isWinner(game, me);
    final pot = stakeWinnerCredit(
      stake: game.stakeBronze,
      playerCount: 2,
      winnerCount: 1,
    );
    final net = stakeWinnerNetProfit(
      stake: game.stakeBronze,
      playerCount: 2,
      winnerCount: 1,
    );
    final credit = iWon ? pot : 0;
    final display = iWon ? net : 0;
    final lost = (!iWon && game.stakeBronze > 0) ? game.stakeBronze : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _clearSessionForFinishedGame();
      unawaited(_onGameSettled(
        creditBronze: credit,
        displayRewardBronze: display,
        lostBronze: lost,
      ));
    });
  }

  void _syncLocalShips(BattleshipGameView game) {
    if (_shipsSyncedFromServer) return;
    if (game.myShips.isNotEmpty) {
      _localShips = game.myShips.map((s) => List<int>.from(s)).toList();
      _shipsSyncedFromServer = true;
    }
  }

  Future<void> _randomPlace() async {
    setState(() {
      _localShips = generateRandomBattleshipShips();
      _selectedShipIndex = null;
    });
  }

  Future<void> _confirmPlace() async {
    if (_busy || !validateBattleshipShips(_localShips)) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(battleshipRepositoryProvider)
          .placeShips(widget.gameId, _localShips);
      if (!mounted) return;
      ref.invalidate(battleshipGameProvider(widget.gameId));
    } on GamesException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onSetupCellTap(int cell) {
    if (_busy || _localShips.isEmpty) return;
    // Тап по своему кораблю — выделить.
    for (var i = 0; i < _localShips.length; i++) {
      if (_localShips[i].contains(cell)) {
        setState(() => _selectedShipIndex = i);
        return;
      }
    }
    final idx = _selectedShipIndex;
    if (idx == null) return;
    final ship = _localShips[idx];
    final horiz = ship.length <= 1 ||
        ship.every((c) => c ~/ kBattleshipBoardSize == ship.first ~/ kBattleshipBoardSize);
    final next = tryPlaceShip(_localShips, idx, cell, horizontal: horiz);
    if (next == null) return;
    setState(() => _localShips = next);
  }

  void _rotateSelected() {
    final idx = _selectedShipIndex;
    if (idx == null || idx >= _localShips.length) return;
    final rotated = rotateShip(_localShips[idx]);
    if (rotated == null) return;
    final next = _localShips.map((s) => List<int>.from(s)).toList();
    next[idx] = rotated;
    if (!validateBattleshipShips(next)) {
      // Поворот может временно нарушить соседство — пробуем через tryPlaceShip.
      final horiz = rotated.length <= 1 ||
          rotated.every(
            (c) =>
                c ~/ kBattleshipBoardSize ==
                rotated.first ~/ kBattleshipBoardSize,
          );
      final placed =
          tryPlaceShip(_localShips, idx, rotated.first, horizontal: horiz);
      if (placed == null) return;
      setState(() => _localShips = placed);
      return;
    }
    setState(() => _localShips = next);
  }

  Future<void> _shoot(int cell) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(battleshipRepositoryProvider).shoot(widget.gameId, cell);
      if (!mounted) return;
      ref.invalidate(battleshipGameProvider(widget.gameId));
    } on GamesException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmSurrender() async {
    final game = ref.read(battleshipGameProvider(widget.gameId)).valueOrNull;
    if (game == null || game.isOver) return;
    final ok = await confirmGameActionDialog(
      context: context,
      title: context.l10n.gameSurrenderTitle,
      message: context.l10n.gameSurrenderConfirm,
      cancelLabel: context.l10n.gameStay,
      confirmLabel: context.l10n.gameSurrender,
    );
    if (!ok || !mounted) return;
    unawaited(() async {
      try {
        clearBlockingGamePin(ref, ifGameId: widget.gameId);
        await ref.read(battleshipRepositoryProvider).forfeit(widget.gameId);
      } catch (_) {}
      if (!mounted) return;
      ref.invalidate(battleshipGameProvider(widget.gameId));
      unawaited(ref.read(activeGameProvider.notifier).refresh());
    }());
  }

  Future<void> _onClosePressed() async {
    final game = ref.read(battleshipGameProvider(widget.gameId)).valueOrNull;
    await handleGameScreenClose(
      context: context,
      isActive: game != null && !game.isOver,
      onLeaveFinished: () async {
        if (!mounted) return;
        _navigateToGames();
      },
      onForfeitAndLeave: () async {
        if (!mounted) return;
        try {
          clearBlockingGamePin(ref, ifGameId: widget.gameId);
          await ref.read(battleshipRepositoryProvider).forfeit(widget.gameId);
        } catch (_) {}
        if (!mounted) return;
        _navigateToGames();
        unawaited(ref.read(activeGameProvider.notifier).refresh());
      },
    );
  }

  void _navigateToGames() {
    final rematchLobbyId = _rematchLobbyId;
    _rematchLobbyId = null;
    _rematchPollTimer?.cancel();
    _clearSessionForFinishedGame();
    context.go('/games');
    if (rematchLobbyId != null) {
      unawaited(
        ref
            .read(battleshipRepositoryProvider)
            .leaveLobby(rematchLobbyId)
            .catchError((_) {}),
      );
    }
  }

  Future<void> _rematch() async {
    setState(() => _isRematching = true);
    try {
      final lobbyId =
          await ref.read(battleshipRepositoryProvider).rematch(widget.gameId);
      if (!mounted) return;
      clearBlockingGamePin(ref);
      ref.read(activeGameProvider.notifier).setLocal(
            ActiveGameItem(
              type: 'lobby',
              lobbyId: lobbyId,
              gameType: 'battleship',
            ),
          );
      setState(() {
        _rematchLobbyId = lobbyId;
        _rematchDeclined = false;
        _iDeclinedRematch = false;
        _isRematching = false;
      });
      context.go('/games/battleship/lobby/$lobbyId?mode=invite');
    } catch (_) {
      if (mounted) {
        setState(() => _isRematching = false);
        context.go('/games');
      }
    }
  }

  Future<void> _acceptRematch(String lobbyId) async {
    if (_isAcceptingRematch) return;
    setState(() => _isAcceptingRematch = true);
    ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
    try {
      final result =
          await ref.read(battleshipRepositoryProvider).joinLobby(lobbyId);
      if (!mounted) return;
      clearBlockingGamePin(ref);
      if (result.gameId != null && result.gameId!.isNotEmpty) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'game',
                gameId: result.gameId,
                lobbyId: lobbyId,
                gameType: 'battleship',
              ),
            );
        pinBlockingGame(ref, result.gameId, gameType: 'battleship');
        context.go('/games/battleship/game/${result.gameId}');
      } else {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'lobby',
                lobbyId: lobbyId,
                gameType: 'battleship',
              ),
            );
        context.go('/games/battleship/lobby/$lobbyId?mode=invite');
      }
    } catch (_) {
      if (mounted) context.go('/games');
    } finally {
      if (mounted) setState(() => _isAcceptingRematch = false);
    }
  }

  Future<void> _declineRematch(String lobbyId) async {
    ref.read(gameInvitesProvider.notifier).remove(lobbyId);
    try {
      await ref.read(battleshipRepositoryProvider).declineLobby(lobbyId);
    } catch (_) {}
    if (mounted) setState(() => _iDeclinedRematch = true);
  }

  Future<void> _cancelRematchWait() async {
    if (_rematchLobbyId == null) return;
    _rematchPollTimer?.cancel();
    final lobbyId = _rematchLobbyId!;
    setState(() => _rematchLobbyId = null);
    try {
      await ref.read(battleshipRepositoryProvider).leaveLobby(lobbyId);
    } catch (_) {}
  }

  Future<void> _findGame() async {
    setState(() => _isFindingGame = true);
    try {
      final rematchId = _rematchLobbyId;
      if (rematchId != null) {
        _rematchPollTimer?.cancel();
        setState(() => _rematchLobbyId = null);
        unawaited(
          ref
              .read(battleshipRepositoryProvider)
              .leaveLobby(rematchId)
              .catchError((_) {}),
        );
      }
      final game = ref.read(battleshipGameProvider(widget.gameId)).valueOrNull;
      final created = await ref.read(battleshipRepositoryProvider).createLobby(
            mode: 'matchmake',
            turnTimeSec: game?.turnTimeSec ?? 0,
            stakeBronze: game?.stakeBronze ?? 2,
            addBotsAfter30s: true,
          );
      if (!mounted) return;
      clearBlockingGamePin(ref);
      if (created.gameId != null && created.gameId!.isNotEmpty) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'game',
                gameId: created.gameId,
                lobbyId: created.lobbyId,
                gameType: 'battleship',
              ),
            );
        pinBlockingGame(ref, created.gameId, gameType: 'battleship');
        context.go('/games/battleship/game/${created.gameId}');
        return;
      }
      ref.read(activeGameProvider.notifier).setLocal(
            ActiveGameItem(
              type: 'lobby',
              lobbyId: created.lobbyId,
              gameType: 'battleship',
            ),
          );
      context.go('/games/battleship/lobby/${created.lobbyId}?mode=matchmake');
    } catch (_) {
      if (mounted) context.go('/games');
    } finally {
      if (mounted) setState(() => _isFindingGame = false);
    }
  }

  List<String> _peerIds(BattleshipGameView game, String? me) {
    return [
      if (game.p1UserId.isNotEmpty && game.p1UserId != me) game.p1UserId,
      if (game.p2UserId.isNotEmpty && game.p2UserId != me) game.p2UserId,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(battleshipGameProvider(widget.gameId));
    final me = ref.watch(authStateProvider).valueOrNull?.id;
    final narrow = isNarrow(context);

    ref.listen(battleshipGameProvider(widget.gameId), (_, next) {
      final game = next.valueOrNull;
      if (game != null) _syncLocalShips(game);
    });

    return SwipeBackScope(
      enabled: true,
      onBack: _onClosePressed,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _onClosePressed,
          ),
          title: Text(context.l10n.gamesBattleship),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: context.l10n.gamesRulesTitle,
              icon: const Icon(Icons.rule_rounded),
              onPressed: () => showGameRulesDialog(
                context: context,
                title: context.l10n.rulesBattleshipTitle,
                content: Text(context.l10n.rulesBattleshipBody),
                closeLabel: context.l10n.commonClose,
              ),
            ),
          ],
        ),
        body: GradientBackground(
          child: SafeArea(
            child: Stack(
              children: [
                gameAsync.when(
                  skipLoadingOnReload: true,
                  skipLoadingOnRefresh: true,
                  data: (game) {
                    final isOver = game.isOver;
                    final showSurrender = !isOver;
                    _maybeSettleGame(game, me);
                    final chip = _rewardChipBronze(game, me);
                    final status = _statusText(game, me);
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            narrow ? 12 : 20,
                            4,
                            narrow ? 12 : 20,
                            0,
                          ),
                          child: Column(
                            children: [
                              if (!isOver)
                                Text(
                                  game.isSetup
                                      ? context.l10n.gamesBattleshipSetupPhase
                                      : context.l10n.gamesBattleshipBattlePhase,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (status.isNotEmpty)
                                GameStatusWithReward(
                                  statusText: status,
                                  showReward: chip != 0,
                                  rewardBronze: chip,
                                  rewardKey: _winRewardKey,
                                  fontSize: narrow ? 15 : null,
                                ),
                            ],
                          ),
                        ),
                        if (game.isSetup &&
                            !_iAmReady(game, me) &&
                            game.setupDeadline > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: GameTurnCountdown(
                              key: ValueKey('setup_${game.setupDeadline}'),
                              turnDeadline: game.setupDeadline,
                              isMyTurn: true,
                              onExpired: () => ref.invalidate(
                                battleshipGameProvider(widget.gameId),
                              ),
                              labelBuilder: (s) =>
                                  context.l10n.gameSecondsLeft(s),
                            ),
                          ),
                        if (game.isBattle &&
                            !isOver &&
                            game.turnTimeSec > 0 &&
                            game.turnDeadline > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: GameTurnCountdown(
                              key: ValueKey(
                                '${game.turn}_${game.turnDeadline}',
                              ),
                              turnDeadline: game.turnDeadline,
                              isMyTurn: game.isMyTurn,
                              turnTimeSec: game.turnTimeSec,
                              onExpired: () => ref.invalidate(
                                battleshipGameProvider(widget.gameId),
                              ),
                              labelBuilder: (s) =>
                                  context.l10n.gameSecondsLeft(s),
                            ),
                          ),
                        if (isOver) ...[
                          const SizedBox(height: 10),
                          GameRematchSection(
                            rematchLobbyId: _rematchLobbyId,
                            rematchDeclined: _rematchDeclined,
                            iDeclinedRematch: _iDeclinedRematch,
                            isRematching: _isRematching,
                            isAcceptingRematch: _isAcceptingRematch,
                            isFindingGame: _isFindingGame,
                            peerIds: _peerIds(game, me),
                            invites: ref.watch(gameInvitesProvider),
                            onRematch: () => unawaited(_rematch()),
                            onAccept: (id) => unawaited(_acceptRematch(id)),
                            onDecline: (id) => unawaited(_declineRematch(id)),
                            onCancelWait: () => unawaited(_cancelRematchWait()),
                            onFindGame: () => unawaited(_findGame()),
                            compact: true,
                          ),
                        ],
                        Expanded(
                          child: game.isSetup
                              ? _buildSetup(game, me, narrow)
                              : _buildBattle(game, narrow),
                        ),
                        if (showSurrender) const SizedBox(height: 48),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentStart,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatUserError(
                              e,
                              fallback: context.l10n.commonTryLater,
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => ref.invalidate(
                              battleshipGameProvider(widget.gameId),
                            ),
                            child: Text(context.l10n.commonTryRefresh),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (gameAsync.valueOrNull != null &&
                    !gameAsync.valueOrNull!.isOver)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: GameActionsOverlay(
                      canDraw: false,
                      iOfferedDraw: false,
                      opponentOfferedDraw: false,
                      onSurrender: () => unawaited(_confirmSurrender()),
                      onDraw: () {},
                      surrenderTooltip: context.l10n.gameSurrender,
                      drawTooltip: context.l10n.gameOfferDraw,
                      acceptDrawTooltip: context.l10n.gameAcceptDrawTitle,
                      drawOfferedTooltip: context.l10n.gameDrawOffered,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetup(BattleshipGameView game, String? me, bool narrow) {
    final ready = _iAmReady(game, me);
    final ships = ready && game.myShips.isNotEmpty ? game.myShips : _localShips;
    final occupied = <int>{for (final s in ships) ...s};
    final selectedCells = _selectedShipIndex != null &&
            _selectedShipIndex! < ships.length
        ? ships[_selectedShipIndex!].toSet()
        : <int>{};

    return Padding(
      padding: EdgeInsets.all(narrow ? 12 : 20),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: _BattleshipBoard(
                cellSize: narrow ? 28 : 34,
                cellBuilder: (cell) {
                  final isShip = occupied.contains(cell);
                  final selected = selectedCells.contains(cell);
                  return _CellPaint(
                    color: selected
                        ? _kSelectedShip
                        : isShip
                            ? _kShip
                            : _kWater,
                  );
                },
                onTap: ready ? null : _onSetupCellTap,
              ),
            ),
          ),
          if (!ready) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => unawaited(_randomPlace()),
                  icon: const Icon(Icons.casino_rounded, size: 18),
                  label: Text(context.l10n.gamesBattleshipRandomPlace),
                ),
                if (_selectedShipIndex != null)
                  IconButton.outlined(
                    onPressed: _busy ? null : _rotateSelected,
                    tooltip: context.l10n.gamesBattleshipSetupPhase,
                    icon: const Icon(Icons.rotate_right_rounded),
                  ),
                FilledButton(
                  onPressed: _busy || !validateBattleshipShips(_localShips)
                      ? null
                      : () => unawaited(_confirmPlace()),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentStart,
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(context.l10n.gamesBattleshipConfirmPlace),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBattle(BattleshipGameView game, bool narrow) {
    final myOccupied = <int>{for (final s in game.myShips) ...s};
    final oppShots = game.opponentShots.toSet();
    final myShots = game.myShots.toSet();
    final oppHits = game.opponentShipsHit.toSet();

    Widget myBoard() => _BattleshipBoard(
          cellSize: narrow ? 26 : 32,
          cellBuilder: (cell) {
            final ship = myOccupied.contains(cell);
            final shot = oppShots.contains(cell);
            if (shot && ship) {
              return const _CellPaint(color: _kHit, mark: _CellMark.hit);
            }
            if (shot) {
              return const _CellPaint(color: _kMiss, mark: _CellMark.miss);
            }
            if (ship) return const _CellPaint(color: _kShip);
            return const _CellPaint(color: _kWater);
          },
        );

    Widget oppBoard() => _BattleshipBoard(
          cellSize: narrow ? 28 : 34,
          cellBuilder: (cell) {
            final hit = oppHits.contains(cell);
            final shot = myShots.contains(cell);
            if (hit) {
              return const _CellPaint(color: _kHit, mark: _CellMark.hit);
            }
            if (shot) {
              return const _CellPaint(color: _kMiss, mark: _CellMark.miss);
            }
            return const _CellPaint(color: _kWater);
          },
          onTap: (!game.isOver && game.isMyTurn && !_busy)
              ? (cell) {
                  if (myShots.contains(cell) || oppHits.contains(cell)) {
                    return;
                  }
                  unawaited(_shoot(cell));
                }
              : null,
        );

    final boards = narrow
        ? Column(
            children: [
              Flexible(child: Center(child: oppBoard())),
              const SizedBox(height: 12),
              Flexible(child: Center(child: myBoard())),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Center(child: myBoard())),
              const SizedBox(width: 16),
              Expanded(child: Center(child: oppBoard())),
            ],
          );

    return Padding(
      padding: EdgeInsets.all(narrow ? 10 : 16),
      child: boards,
    );
  }
}

enum _CellMark { none, hit, miss }

class _CellPaint extends StatelessWidget {
  const _CellPaint({required this.color, this.mark = _CellMark.none});
  final Color color;
  final _CellMark mark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: AppColors.accentStart.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: mark == _CellMark.none
          ? const SizedBox.expand()
          : Center(
              child: mark == _CellMark.hit
                  ? const Icon(Icons.close_rounded, size: 14, color: Colors.white)
                  : Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
    );
  }
}

class _BattleshipBoard extends StatelessWidget {
  const _BattleshipBoard({
    required this.cellBuilder,
    this.onTap,
    this.cellSize = 32,
  });

  final Widget Function(int cell) cellBuilder;
  final void Function(int cell)? onTap;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final size = cellSize.clamp(28.0, 36.0);
    const gap = 2.0;
    final board = size * kBattleshipBoardSize + gap * (kBattleshipBoardSize - 1);
    return SizedBox(
      width: board,
      height: board,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: kBattleshipBoardSize,
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
        ),
        itemCount: kBattleshipCellCount,
        itemBuilder: (context, index) {
          final child = cellBuilder(index);
          if (onTap == null) return child;
          return GestureDetector(
            onTap: () => onTap!(index),
            child: child,
          );
        },
      ),
    );
  }
}
