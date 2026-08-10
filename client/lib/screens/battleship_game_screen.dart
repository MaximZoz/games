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
const Color _kConflictShip = Color(0xFFE57373);
const Color _kPreviewOk = Color(0xFF81C784);
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

class _BattleshipGameScreenState extends ConsumerState<BattleshipGameScreen>
    with SingleTickerProviderStateMixin {
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
  /// Чип «−N» при проигрыше — только после анимации списания.
  bool _lossChipRevealed = false;
  String? _prevGameStatus;

  /// Локальная расстановка на фазе setup.
  List<List<int>> _localShips = const [];
  int? _selectedShipIndex;
  bool _shipsSyncedFromServer = false;
  bool _setupAutoSubmitted = false;

  /// Анимация попадания по клетке [lastShot].
  late final AnimationController _hitPulse;
  int _lastAnimatedShotKey = -1;
  int? _pulseHitCell;

  @override
  void initState() {
    super.initState();
    _hitPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

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
      _setupAutoSubmitted = false;
      _localShips = const [];
      _selectedShipIndex = null;
      _balanceGainPlayed = false;
      _lossChipRevealed = false;
      _prevGameStatus = null;
      _lastAnimatedShotKey = -1;
      _pulseHitCell = null;
      _hitPulse.stop();
      _hitPulse.reset();
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
    _hitPulse.dispose();
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
    if (game.isTurnOf(me)) return l10n.gamesMyTurn;
    // Как в крестиках: «Ход {логин}».
    final turnName = game.displayNameOf(game.turn)?.trim() ?? '';
    return turnName.isNotEmpty
        ? l10n.gameTurnOf(turnName)
        : l10n.gamesOpponentTurn;
  }

  void _maybePulseHit(BattleshipGameView game) {
    if (!game.lastShotHit || game.lastShot < 0) return;
    final key = game.lastShot + 1000 * (game.lastShotBy?.hashCode ?? 0);
    if (key == _lastAnimatedShotKey) return;
    _lastAnimatedShotKey = key;
    _pulseHitCell = game.lastShot;
    _hitPulse
      ..stop()
      ..forward(from: 0).whenComplete(() {
        if (!mounted) return;
        if (_pulseHitCell == game.lastShot) {
          setState(() => _pulseHitCell = null);
        }
      });
    if (mounted) setState(() {});
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
    if (!_lossChipRevealed) return 0;
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
      );
      if (mounted) setState(() => _lossChipRevealed = true);
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
    if (!game.isSetup) return;
    // Сразу показываем расстановку: с сервера (если уже есть) или случайную.
    if (game.myShips.isNotEmpty) {
      _localShips = game.myShips.map((s) => List<int>.from(s)).toList();
    } else {
      _localShips = generateRandomBattleshipShips();
    }
    _shipsSyncedFromServer = true;
  }

  Future<void> _randomPlace() async {
    setState(() {
      _localShips = generateRandomBattleshipShips();
      _selectedShipIndex = null;
    });
  }

  Future<void> _confirmPlace() async {
    if (_busy) return;
    if (!validateBattleshipShips(_localShips)) {
      showAppSnackBar(
        context,
        message: context.l10n.gamesBattleshipShipsMustNotTouch,
        kind: AppSnackKind.error,
      );
      return;
    }
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

  /// Таймаут расстановки: отправляем текущую валидную, иначе дефолтную.
  Future<void> _onSetupExpired() async {
    if (_setupAutoSubmitted || _busy) {
      ref.invalidate(battleshipGameProvider(widget.gameId));
      return;
    }
    final game = ref.read(battleshipGameProvider(widget.gameId)).valueOrNull;
    final me = ref.read(authStateProvider).valueOrNull?.id;
    if (game == null || !game.isSetup || _iAmReady(game, me)) {
      ref.invalidate(battleshipGameProvider(widget.gameId));
      return;
    }
    _setupAutoSubmitted = true;
    var ships = _localShips;
    if (!validateBattleshipShips(ships)) {
      ships = defaultBattleshipShips();
    }
    setState(() {
      _localShips = ships;
      _busy = true;
    });
    try {
      await ref
          .read(battleshipRepositoryProvider)
          .placeShips(widget.gameId, ships);
    } catch (_) {
      // Сервер мог уже дожать таймаут — просто обновим состояние.
    } finally {
      if (mounted) setState(() => _busy = false);
      ref.invalidate(battleshipGameProvider(widget.gameId));
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
    // Разрешаем поставить даже с касанием — UI подсветит конфликт красным.
    final next = placeShipAllowTouch(
      _localShips,
      idx,
      cell,
      horizontal: isShipHorizontal(ship),
    );
    if (next == null) return;
    setState(() => _localShips = next);
  }

  void _onSetupShipDropped({
    required int shipIndex,
    required int grabOffset,
    required int dropCell,
  }) {
    if (_busy) return;
    // Оставляем корабль на новой позиции даже при касании/пересечении.
    final next = moveShipFromGrabAllowTouch(
      _localShips,
      shipIndex,
      grabOffset,
      dropCell,
    );
    if (next == null) return;
    setState(() {
      _localShips = next;
      _selectedShipIndex = shipIndex;
    });
  }

  void _rotateSelected() {
    final idx = _selectedShipIndex;
    if (idx == null || idx >= _localShips.length) return;
    final rotated = rotateShip(_localShips[idx]);
    if (rotated == null) return;
    final next = _localShips.map((s) => List<int>.from(s)).toList();
    next[idx] = rotated;
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
      if (game == null) return;
      _syncLocalShips(game);
      _maybePulseHit(game);
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
                    // Сразу при входе в setup — случайная (или серверная) расстановка.
                    _syncLocalShips(game);
                    final isOver = game.isOver;
                    final showSurrender = !isOver;
                    _maybeSettleGame(game, me);
                    final chip = _rewardChipBronze(game, me);
                    final status = _statusText(game, me);
                    final myTurn = game.isTurnOf(me);
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
                              onExpired: () => unawaited(_onSetupExpired()),
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
                              isMyTurn: myTurn,
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
                              : _buildBattle(game, me, narrow),
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
    final selectedIdx = _selectedShipIndex;

    return Padding(
      padding: EdgeInsets.all(narrow ? 12 : 20),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ready
                  ? _BattleshipBoard(
                      cellSize: narrow ? 28 : 34,
                      cellBuilder: (cell) {
                        final occupied = <int>{for (final s in ships) ...s};
                        return _CellPaint(
                          color: occupied.contains(cell) ? _kShip : _kWater,
                        );
                      },
                    )
                  : _BattleshipSetupBoard(
                      cellSize: narrow ? 28 : 34,
                      ships: ships,
                      selectedShipIndex: selectedIdx,
                      enabled: !_busy,
                      onTapCell: _onSetupCellTap,
                      onShipDropped: _onSetupShipDropped,
                      onShipSelected: (i) =>
                          setState(() => _selectedShipIndex = i),
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
                IconButton.outlined(
                  onPressed: _busy || selectedIdx == null
                      ? null
                      : _rotateSelected,
                  tooltip: context.l10n.gamesBattleshipRotate,
                  icon: const Icon(Icons.rotate_right_rounded),
                ),
                FilledButton(
                  onPressed:
                      _busy ? null : () => unawaited(_confirmPlace()),
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

  Widget _buildBattle(BattleshipGameView game, String? me, bool narrow) {
    final myTurn = game.isTurnOf(me);
    // Одно поле: мой ход / конец — поле соперника; ход соперника — моё поле.
    final showMyBoard = !game.isOver && !myTurn;
    final cellSize = narrow ? 30.0 : 36.0;
    final pulseCell = game.lastShotHit ? _pulseHitCell : null;

    final board = showMyBoard
        ? _buildMyDefenseBoard(game, cellSize: cellSize, pulseCell: pulseCell)
        : _buildOpponentAttackBoard(
            game,
            cellSize: cellSize,
            pulseCell: pulseCell,
            canShoot: myTurn && !game.isOver && !_busy,
          );

    return Padding(
      padding: EdgeInsets.all(narrow ? 10 : 16),
      child: Center(child: board),
    );
  }

  Widget _buildMyDefenseBoard(
    BattleshipGameView game, {
    required double cellSize,
    int? pulseCell,
  }) {
    final myOccupied = <int>{for (final s in game.myShips) ...s};
    final oppShots = game.opponentShots.toSet();
    return _BattleshipBoard(
      cellSize: cellSize,
      pulseCell: pulseCell,
      pulseAnimation: _hitPulse,
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
  }

  Widget _buildOpponentAttackBoard(
    BattleshipGameView game, {
    required double cellSize,
    int? pulseCell,
    required bool canShoot,
  }) {
    final myShots = game.myShots.toSet();
    final myHits = game.myHits.toSet();
    final sunk = game.opponentShipsHit.toSet();
    final revealed = <int>{for (final s in game.opponentShips) ...s};
    return _BattleshipBoard(
      cellSize: cellSize,
      pulseCell: pulseCell,
      pulseAnimation: _hitPulse,
      cellBuilder: (cell) {
        if (sunk.contains(cell) || myHits.contains(cell)) {
          return const _CellPaint(color: _kHit, mark: _CellMark.hit);
        }
        if (myShots.contains(cell)) {
          return const _CellPaint(color: _kMiss, mark: _CellMark.miss);
        }
        if (revealed.contains(cell)) {
          return const _CellPaint(color: _kShip);
        }
        return const _CellPaint(color: _kWater);
      },
      onTap: canShoot
          ? (cell) {
              if (myShots.contains(cell)) return;
              unawaited(_shoot(cell));
            }
          : null,
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
    this.pulseCell,
    this.pulseAnimation,
  });

  final Widget Function(int cell) cellBuilder;
  final void Function(int cell)? onTap;
  final double cellSize;
  final int? pulseCell;
  final Animation<double>? pulseAnimation;

  @override
  Widget build(BuildContext context) {
    final size = cellSize.clamp(28.0, 40.0);
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
          Widget child = cellBuilder(index);
          if (pulseCell == index && pulseAnimation != null) {
            child = AnimatedBuilder(
              animation: pulseAnimation!,
              builder: (context, c) {
                final t = pulseAnimation!.value;
                final scale = 1.0 + 0.35 * (1 - (2 * t - 1).abs());
                return Transform.scale(
                  scale: scale,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: _kHit.withValues(alpha: 0.55 * (1 - t)),
                          blurRadius: 10 * (1 - t),
                          spreadRadius: 2 * (1 - t),
                        ),
                      ],
                    ),
                    child: c,
                  ),
                );
              },
              child: child,
            );
          }
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

/// Доска расстановки: drag-and-drop кораблей + превью валидности.
class _BattleshipSetupBoard extends StatefulWidget {
  const _BattleshipSetupBoard({
    required this.ships,
    required this.selectedShipIndex,
    required this.enabled,
    required this.onTapCell,
    required this.onShipDropped,
    required this.onShipSelected,
    this.cellSize = 32,
  });

  final List<List<int>> ships;
  final int? selectedShipIndex;
  final bool enabled;
  final void Function(int cell) onTapCell;
  final void Function({
    required int shipIndex,
    required int grabOffset,
    required int dropCell,
  }) onShipDropped;
  final void Function(int shipIndex) onShipSelected;
  final double cellSize;

  @override
  State<_BattleshipSetupBoard> createState() => _BattleshipSetupBoardState();
}

class _BattleshipSetupBoardState extends State<_BattleshipSetupBoard> {
  static const double _gap = 2;

  int? _dragShipIndex;
  int? _grabOffset;
  int? _hoverCell;
  Offset? _panStart;
  bool _didDrag = false;

  double get _size => widget.cellSize.clamp(28.0, 36.0);

  int? _cellAt(Offset local) {
    final step = _size + _gap;
    final col = (local.dx / step).floor();
    final row = (local.dy / step).floor();
    if (col < 0 ||
        col >= kBattleshipBoardSize ||
        row < 0 ||
        row >= kBattleshipBoardSize) {
      return null;
    }
    // Учитывать зазор: тап в gap — ближайшая клетка.
    final inCellX = local.dx - col * step;
    final inCellY = local.dy - row * step;
    if (inCellX > _size || inCellY > _size) return null;
    return row * kBattleshipBoardSize + col;
  }

  int? _shipIndexAt(int cell) {
    for (var i = 0; i < widget.ships.length; i++) {
      if (widget.ships[i].contains(cell)) return i;
    }
    return null;
  }

  Set<int> get _previewCells {
    final shipIdx = _dragShipIndex;
    final grab = _grabOffset;
    final hover = _hoverCell;
    if (shipIdx == null || grab == null || hover == null) return const {};
    if (shipIdx >= widget.ships.length) return const {};
    // Превью всегда по геометрии — даже при касании/пересечении.
    // Если не влезает в поле — оставляем исходную позицию (корабль не «пропадает»).
    final cells = previewMoveShipCells(widget.ships[shipIdx], grab, hover);
    if (cells != null) return cells.toSet();
    return widget.ships[shipIdx].toSet();
  }

  bool get _previewValid {
    final shipIdx = _dragShipIndex;
    final grab = _grabOffset;
    final hover = _hoverCell;
    if (shipIdx == null || grab == null || hover == null) return false;
    return tryMoveShipFromGrab(widget.ships, shipIdx, grab, hover) != null;
  }

  void _onPanStart(DragStartDetails d) {
    if (!widget.enabled) return;
    final cell = _cellAt(d.localPosition);
    if (cell == null) return;
    final shipIdx = _shipIndexAt(cell);
    if (shipIdx == null) return;
    final offset = widget.ships[shipIdx].indexOf(cell);
    setState(() {
      _dragShipIndex = shipIdx;
      _grabOffset = offset;
      _hoverCell = cell;
      _panStart = d.localPosition;
      _didDrag = false;
    });
    widget.onShipSelected(shipIdx);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_dragShipIndex == null) return;
    final start = _panStart;
    if (start != null && !_didDrag) {
      final dist = (d.localPosition - start).distance;
      if (dist > 6) _didDrag = true;
    }
    final cell = _cellAt(d.localPosition);
    // Вне поля — сохраняем последнюю клетку, чтобы превью/корабль не исчезали.
    if (cell == null || cell == _hoverCell) return;
    setState(() => _hoverCell = cell);
  }

  void _onPanEnd(DragEndDetails _) {
    final shipIdx = _dragShipIndex;
    final grab = _grabOffset;
    final hover = _hoverCell;
    final dragged = _didDrag;
    setState(() {
      _dragShipIndex = null;
      _grabOffset = null;
      _hoverCell = null;
      _panStart = null;
      _didDrag = false;
    });
    if (shipIdx == null || grab == null) return;
    if (!dragged) {
      // Короткий жест — обычный тап.
      final cell = hover;
      if (cell != null) widget.onTapCell(cell);
      return;
    }
    if (hover == null) return;
    widget.onShipDropped(
      shipIndex: shipIdx,
      grabOffset: grab,
      dropCell: hover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = _size;
    final board =
        size * kBattleshipBoardSize + _gap * (kBattleshipBoardSize - 1);
    final occupied = <int>{for (final s in widget.ships) ...s};
    final conflictIdx = conflictingShipIndices(widget.ships);
    final conflictCells = <int>{
      for (final i in conflictIdx)
        if (i >= 0 && i < widget.ships.length) ...widget.ships[i],
    };
    final selected = widget.selectedShipIndex != null &&
            widget.selectedShipIndex! < widget.ships.length
        ? widget.ships[widget.selectedShipIndex!].toSet()
        : <int>{};
    final preview = _previewCells;
    final previewOk = _previewValid;
    final draggingShip = _dragShipIndex != null &&
            _dragShipIndex! < widget.ships.length
        ? widget.ships[_dragShipIndex!].toSet()
        : <int>{};

    return SizedBox(
      width: board,
      height: board,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTapUp: widget.enabled
            ? (d) {
                // Тап по воде / кораблю без drag (если pan не сработал).
                if (_dragShipIndex != null) return;
                final cell = _cellAt(d.localPosition);
                if (cell != null) widget.onTapCell(cell);
              }
            : null,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: kBattleshipBoardSize,
            mainAxisSpacing: _gap,
            crossAxisSpacing: _gap,
          ),
          itemCount: kBattleshipCellCount,
          itemBuilder: (context, index) {
            Color color = _kWater;
            if (preview.contains(index)) {
              color = previewOk ? _kPreviewOk : _kConflictShip;
            } else if (_didDrag && draggingShip.contains(index)) {
              color = _kShip.withValues(alpha: 0.35);
            } else if (conflictCells.contains(index)) {
              color = _kConflictShip;
            } else if (selected.contains(index)) {
              color = _kSelectedShip;
            } else if (occupied.contains(index)) {
              color = _kShip;
            }
            return _CellPaint(color: color);
          },
        ),
      ),
    );
  }
}
