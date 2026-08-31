import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/sfx.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/battleship/battleship_offline_session.dart';
import 'package:multigames_client/games/battleship/battleship_provider.dart';
import 'package:multigames_client/games/battleship/battleship_repository.dart';
import 'package:multigames_client/games/battleship/battleship_rules.dart';
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
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';
import 'package:multigames_client/utils/user_error.dart';

/// Цвета клеток Морского боя.
const Color _kWater = Color(0xFF90CAF9);
const Color _kPendingWater = Color(0xFFBBDEFB);
const Color _kShip = Color(0xFF607D8B);
const Color _kConflictShip = Color(0xFFE57373);
const Color _kPreviewOk = Color(0xFF81C784);
const Color _kHit = Color(0xFFE53935);
const Color _kMiss = Color(0xFFFFFFFF);
const Color _kSelectedShip = Color(0xFF455A64);
const Color _kSunkShip = Color(0xFF37474F);
const Color _kSunkFrame = Color(0xFF212121);
/// Мои потопленные — красным (в отличие от тёмных кораблей соперника).
const Color _kSunkShipMine = Color(0xFFE53935);
const Color _kSunkFrameMine = Color(0xFFB71C1C);
const Duration _kShotRevealDelay = Duration(milliseconds: 280);

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
  Timer? _busyWatchdog;
  int _busyStuckTicks = 0;
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
  /// Локальный unix-дедлайн расстановки (от setup_seconds_left), без перекоса часов.
  int _setupLocalDeadline = 0;
  int _setupDeadlineKey = 0;

  /// Анимация попадания/промаха + удержание поля 1с перед сменой хода.
  late final AnimationController _hitPulse;
  String _lastFxKey = '';
  bool _fxInProgress = false;
  int? _pulseHitCell;
  bool _fxHit = false;
  /// Во время FX: true = своё поле, false = поле соперника, null = по ходу.
  bool? _fxShowMineBoard;
  /// Сразу после победного выстрела — скрыть таймер, не дожидаясь invalidate.
  bool _hideTimers = false;

  /// Выстрел уже на поле, ждём ответ сервера.
  int? _pendingShotCell;
  /// Монотонный слой клеток: ответ `shoot()` сразу на доске, refetch не откатывает.
  BattleshipClientOverlay _overlay = const BattleshipClientOverlay();
  BattleshipGameView? _optimisticView;

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
      _setupLocalDeadline = 0;
      _setupDeadlineKey = 0;
      _localShips = const [];
      _selectedShipIndex = null;
      _balanceGainPlayed = false;
      _lossChipRevealed = false;
      _prevGameStatus = null;
      _lastFxKey = '';
      _fxInProgress = false;
      _pulseHitCell = null;
      _fxShowMineBoard = null;
      _hideTimers = false;
      _resetClientPaint();
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
    _busyWatchdog?.cancel();
    _realtimeSubscription?.close();
    _hitPulse.dispose();
    super.dispose();
  }

  bool get _isOffline =>
      OfflineBattleshipRegistry.instance.isOffline(widget.gameId);

  void _initializeProviderBindings() {
    if (_providerBindingsInitialized) return;
    _providerBindingsInitialized = true;
    _busyWatchdog?.cancel();
    _busyWatchdog = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      if (_busy || _fxInProgress || _pendingShotCell != null) {
        _busyStuckTicks++;
        if (_busyStuckTicks >= 3) {
          _busyStuckTicks = 0;
          setState(() {
            _busy = false;
            _fxInProgress = false;
            _pendingShotCell = null;
            _overlay = _overlay.clearPending();
          });
          if (!_isOffline) {
            ref.invalidate(battleshipGameProvider(widget.gameId));
          }
        }
      } else {
        _busyStuckTicks = 0;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isOffline) return;
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
      if (game.isDraw) return l10n.gameDraw;
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

  String _fxKey(BattleshipGameView game) =>
      '${game.lastShot}|${game.lastShotBy}|${game.myShots.length}|${game.opponentShots.length}';

  Future<void> _playShotReveal({
    required int cell,
    required bool hit,
    required bool onMyBoard,
    bool sunk = false,
  }) async {
    if (!mounted) return;
    _fxInProgress = true;
    setState(() {
      _pulseHitCell = cell;
      _fxHit = hit;
      _fxShowMineBoard = onMyBoard;
    });
    if (sunk) {
      Sfx.play(SfxId.sink);
    } else {
      Sfx.play(hit ? SfxId.hit : SfxId.miss);
    }
    _hitPulse
      ..stop()
      ..forward(from: 0);
    await Future<void>.delayed(_kShotRevealDelay);
    if (!mounted) return;
    setState(() {
      _pulseHitCell = null;
      _fxShowMineBoard = null;
      _fxInProgress = false;
    });
  }

  void _maybeRevealRemoteShot(BattleshipGameView game, String? me) {
    if (game.lastShot < 0) return;
    if (_fxInProgress) return;
    final key = _fxKey(game);
    if (key == _lastFxKey) return;
    // Свой выстрел проигрывается в _shoot.
    if (me != null && game.lastShotBy == me) {
      _lastFxKey = key;
      return;
    }
    _lastFxKey = key;
    unawaited(_playShotReveal(
      cell: game.lastShot,
      hit: game.lastShotHit,
      onMyBoard: true,
      sunk: game.mySunkShips.any((ship) => ship.contains(game.lastShot)),
    ));
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
    // Офлайн: без ставок и наград — только UI.
    if (_isOffline) return;
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

  /// Синхронизирует локальный дедлайн расстановки с серверным остатком секунд.
  void _syncSetupLocalDeadline(BattleshipGameView game) {
    if (!game.isSetup || game.setupDeadline <= 0) {
      _setupLocalDeadline = 0;
      _setupDeadlineKey = 0;
      return;
    }
    if (game.setupDeadline == _setupDeadlineKey && _setupLocalDeadline > 0) {
      return;
    }
    _setupDeadlineKey = game.setupDeadline;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    // Предпочитаем относительный остаток с сервера — нет мгновенного «0 с»
    // из‑за расхождения часов клиента и сервера.
    var left = game.setupSecondsLeft;
    if (left <= 0 && game.setupDeadline > now) {
      left = game.setupDeadline - now;
    }
    if (left < 0) left = 0;
    if (left > 60) left = 60;
    _setupLocalDeadline = now + left;
  }

  /// Таймаут расстановки: отправляем текущую валидную, иначе дефолтную.
  Future<void> _onSetupExpired() async {
    if (_setupAutoSubmitted || _busy) {
      ref.invalidate(battleshipGameProvider(widget.gameId));
      return;
    }
    final me = ref.read(authStateProvider).valueOrNull?.id;
    // Перепроверяем сервер: не авто-ставим, если у сервера ещё есть время.
    try {
      final fresh = await ref
          .read(battleshipRepositoryProvider)
          .getGame(widget.gameId);
      if (!mounted) return;
      if (!fresh.isSetup || _iAmReady(fresh, me)) {
        ref.invalidate(battleshipGameProvider(widget.gameId));
        return;
      }
      if (fresh.setupSecondsLeft > 0) {
        // Клиентский таймер обогнал сервер — пересинхронизируем, не сдаёмся.
        _syncSetupLocalDeadline(fresh);
        if (mounted) setState(() {});
        ref.invalidate(battleshipGameProvider(widget.gameId));
        return;
      }
    } catch (_) {
      // Нет сети — всё равно попробуем сдать текущую расстановку ниже.
    }
    final game = ref.read(battleshipGameProvider(widget.gameId)).valueOrNull;
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
    Sfx.play(SfxId.place);
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

  void _resetClientPaint() {
    _overlay = const BattleshipClientOverlay();
    _optimisticView = null;
    _pendingShotCell = null;
  }

  BattleshipGameView _displayGame(BattleshipGameView server) {
    return resolveBattleshipClientView(
      server: server,
      optimistic: _optimisticView,
      overlay: _overlay,
    );
  }

  void _beginLocalShot(int cell) {
    setState(() {
      _overlay = _overlay.beginPending(cell);
      _pendingShotCell = cell;
      _pulseHitCell = null;
      _fxHit = false;
      _fxShowMineBoard = false;
      _busy = true;
    });
  }

  void _playLocalShotFx({
    required int cell,
    required bool hit,
    required bool sunk,
  }) {
    if (!mounted) return;
    setState(() {
      _pulseHitCell = cell;
      _fxHit = hit;
    });
    if (sunk) {
      Sfx.play(SfxId.sink);
    } else {
      Sfx.play(hit ? SfxId.hit : SfxId.miss);
    }
    _hitPulse
      ..stop()
      ..forward(from: 0);
    Future<void>.delayed(_kShotRevealDelay, () {
      if (!mounted) return;
      if (_pulseHitCell != cell) return;
      setState(() => _pulseHitCell = null);
    });
  }

  Future<void> _shoot(int cell) async {
    if (_busy || _pendingShotCell != null) return;
    _beginLocalShot(cell);
    try {
      final view =
          await ref.read(battleshipRepositoryProvider).shoot(widget.gameId, cell);
      if (!mounted) return;
      if (view.id != widget.gameId) return;
      // Свой выстрел — [cell]. После промаха бот может уже сходить в этом же ответе.
      final hit = view.myHits.contains(cell);
      final sunkShip = battleshipNewlySunkShip(
        after: view.opponentSunkShips,
        before: _overlay.sunkShips,
        lastShot: cell,
      );
      final sunk = sunkShip != null ||
          view.opponentSunkShips.any((ship) => ship.contains(cell));
      final keepAttacking = battleshipKeepAttacking(view, shotCell: cell);
      _lastFxKey = _fxKey(view);
      setState(() {
        _overlay = _overlay.resolvePending(
          cell: cell,
          hit: hit,
          sunkShip: sunkShip,
        );
        _optimisticView = view;
        _pendingShotCell = null;
        _busy = false;
        if (view.isOver && !_hideTimers) {
          _hideTimers = true;
        }
        // Промах / конец — сразу смена хода, без удержания поля на FX.
        if (!keepAttacking) {
          _fxShowMineBoard = null;
        }
      });
      _playLocalShotFx(
        cell: cell,
        hit: hit,
        sunk: sunk,
      );
      ref.invalidate(battleshipGameProvider(widget.gameId));
    } on GamesException catch (e) {
      if (!mounted) return;
      setState(() {
        _overlay = _overlay.clearPending();
        _pendingShotCell = null;
        _pulseHitCell = null;
        _fxShowMineBoard = null;
        _busy = false;
      });
      showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  Future<void> _confirmOfferDraw() async {
    final game = ref.read(battleshipGameProvider(widget.gameId)).valueOrNull;
    if (game == null || game.isOver || game.hasBotOpponent) return;
    final ok = await confirmGameActionDialog(
      context: context,
      title: context.l10n.gameOfferDrawTitle,
      message: context.l10n.gameOfferDrawConfirm,
      cancelLabel: context.l10n.commonCancel,
      confirmLabel: context.l10n.gameOfferDraw,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(battleshipRepositoryProvider).offerDraw(widget.gameId);
      if (!mounted) return;
      ref.invalidate(battleshipGameProvider(widget.gameId));
    } on GamesException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
    }
  }

  Future<void> _confirmAcceptDraw() async {
    final game = ref.read(battleshipGameProvider(widget.gameId)).valueOrNull;
    final me = ref.read(authStateProvider).valueOrNull?.id;
    final offerBy = game?.drawOfferBy?.trim();
    if (game == null || me == null || offerBy == null || offerBy == me) return;
    final ok = await confirmGameActionDialog(
      context: context,
      title: context.l10n.gameAcceptDrawTitle,
      message: context.l10n.gameAcceptDrawConfirm,
      cancelLabel: context.l10n.commonCancel,
      confirmLabel: context.l10n.gameDraw,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(battleshipRepositoryProvider).acceptDraw(widget.gameId);
      if (!mounted) return;
      ref.invalidate(battleshipGameProvider(widget.gameId));
    } on GamesException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
    }
  }

  Future<void> _addFriend(
    String userId,
    String displayName, {
    String? requestId,
  }) async {
    try {
      final repo = ref.read(friendsRepositoryProvider);
      if (requestId != null && requestId.isNotEmpty) {
        await repo.acceptRequest(requestId);
        if (!mounted) return;
        ref.invalidate(friendsSnapshotProvider);
        showAppSnackBar(
          context,
          message: context.l10n.friendsRequestAccepted,
          kind: AppSnackKind.success,
        );
      } else {
        await repo.sendRequest(userId);
        if (!mounted) return;
        ref.invalidate(friendsSnapshotProvider);
        showAppSnackBar(
          context,
          message: context.l10n.friendsRequestSent,
          kind: AppSnackKind.success,
        );
      }
    } catch (_) {}
  }

  Future<void> _openChat(String userId, String displayName) async {
    try {
      final chatId =
          await ref.read(chatsRepositoryProvider).startChat(userId);
      if (!mounted || chatId.isEmpty) return;
      final uri = Uri(
        path: '/chats/$chatId',
        queryParameters: {
          'name': displayName,
          'from': 'games',
          'game': '/games/battleship/game/${widget.gameId}',
        },
      );
      context.push(uri.toString());
    } catch (_) {
      if (!mounted) return;
      context.push(
        Uri(
          path: '/chats',
          queryParameters: {
            'peer': userId,
            'game': '/games/battleship/game/${widget.gameId}',
          },
        ).toString(),
      );
    }
  }

  Widget _buildOpponentCard(BattleshipGameView game, String? me) {
    final peers = _peerIds(game, me);
    if (peers.isEmpty) return const SizedBox.shrink();
    final oppId = peers.first;
    final name = game.displayNameOf(oppId)?.trim().isNotEmpty == true
        ? game.displayNameOf(oppId)!.trim()
        : context.l10n.gamesOpponentTurn;
    final avatar = game.avatarOf(oppId);
    final isBot = oppId.startsWith('bot:');
    final chats = ref.watch(chatsListProvider).valueOrNull;
    var unread = 0;
    if (chats != null) {
      for (final c in chats) {
        if (c.user.id == oppId) unread += c.unreadCount;
      }
    }
    final friends = ref.watch(friendsSnapshotProvider).valueOrNull;
    final isFriend = friends?.friends.any((f) => f.user.id == oppId) == true;
    final outgoing =
        friends?.outgoing.where((r) => r.user.id == oppId).toList() ??
            const [];
    final incoming =
        friends?.incoming.where((r) => r.user.id == oppId).toList() ??
            const [];
    final hasOutgoing = outgoing.isNotEmpty;
    final hasIncoming = incoming.isNotEmpty;
    final incomingRequestId = hasIncoming ? incoming.first.requestId : null;
    final compact = MediaQuery.sizeOf(context).width < 420;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GameOpponentCard(
        displayName: name,
        avatarKind: avatar.kind,
        avatarValue: avatar.value,
        frameCode: avatar.frameCode,
        frameColor: avatar.frameColor,
        isBot: isBot,
        messageUnread: unread,
        infoTooltip: context.l10n.userInfoTitle,
        messageTooltip: context.l10n.gameWriteMessage,
        compact: compact,
        maxWidth: 300,
        showAddFriend: !isBot && !isFriend,
        addFriendEnabled: !hasOutgoing,
        addFriendBadge: hasIncoming ? 1 : 0,
        addFriendTooltip: hasIncoming
            ? context.l10n.friendsAcceptRequest
            : (hasOutgoing
                ? context.l10n.friendsRequestSent
                : context.l10n.friendsAdd),
        onAddFriendTap: () => unawaited(_addFriend(
              oppId,
              name,
              requestId: hasIncoming ? incomingRequestId : null,
            )),
        onInfoTap: () => unawaited(showUserProfileDialog(
              context: context,
              ref: ref,
              userId: oppId,
              displayName: name,
              avatarKind: avatar.kind,
              avatarValue: avatar.value,
              frameCode: avatar.frameCode,
              frameColor: avatar.frameColor,
              messageFrom: 'games',
              messageReturnPath: '/games/battleship/game/${widget.gameId}',
            )),
        onMessageTap: isBot ? null : () => unawaited(_openChat(oppId, name)),
      ),
    );
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
      if (_isOffline) {
        final session = OfflineBattleshipRegistry.instance.get(widget.gameId);
        if (session != null) {
          _shipsSyncedFromServer = false;
          _setupAutoSubmitted = false;
          _localShips = const [];
          _selectedShipIndex = null;
          _balanceGainPlayed = false;
          _lossChipRevealed = false;
          _prevGameStatus = null;
          _lastFxKey = '';
          _fxInProgress = false;
          _pulseHitCell = null;
          _fxShowMineBoard = null;
          _hideTimers = false;
          _resetClientPaint();
          _hitPulse.stop();
          _hitPulse.reset();
          session.restart();
          ref.invalidate(battleshipGameProvider(widget.gameId));
          if (mounted) setState(() => _isRematching = false);
          return;
        }
      }
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
      final own = rematchLobbyToLeave(_rematchLobbyId, lobbyId);
      if (own != null) {
        _rematchPollTimer?.cancel();
        setState(() => _rematchLobbyId = null);
        try {
          await ref.read(battleshipRepositoryProvider).leaveLobby(own);
        } catch (_) {}
        if (!mounted) return;
      }
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
    var me = ref.watch(authStateProvider).valueOrNull?.id;
    if (_isOffline && (me == null || me.isEmpty)) {
      me = OfflineBattleshipRegistry.instance.get(widget.gameId)?.humanUserId;
    }
    final narrow = isNarrow(context);

    ref.listen(battleshipGameProvider(widget.gameId), (_, next) {
      final game = next.valueOrNull;
      if (game == null) return;
      final absorbed = _overlay.absorbServer(game);
      final pending = _pendingShotCell;
      final pendingDone = pending != null &&
          (game.myShots.contains(pending) || game.myHits.contains(pending));
      final local = _optimisticView;
      final caughtUp = local != null &&
          local.id == game.id &&
          game.myShots.length >= local.myShots.length &&
          game.opponentShots.length >= local.opponentShots.length &&
          (!local.isOver || game.isOver);
      if (!absorbed.sameAs(_overlay) ||
          pendingDone ||
          caughtUp ||
          (game.isOver && !_hideTimers)) {
        setState(() {
          _overlay = absorbed;
          if (pendingDone) _pendingShotCell = null;
          if (caughtUp) _optimisticView = null;
          if (game.isOver && !_hideTimers) _hideTimers = true;
        });
      }
      _syncLocalShips(game);
      final me = ref.read(authStateProvider).valueOrNull?.id;
      _maybeRevealRemoteShot(game, me);
    });

    return SwipeBackScope(
      enabled: true,
      onBack: _onClosePressed,
      opaqueEdge: false,
      edgeWidth: 16,
      triggerDistance: 44,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          toolbarHeight: kToolbarHeight,
          leadingWidth: 48,
          leading: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.close_rounded),
            onPressed: _onClosePressed,
          ),
          title: Text(context.l10n.gamesBattleship),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: context.l10n.gamesRulesTitle,
              icon: const Icon(Icons.rule_rounded),
              onPressed: () {
                final game = gameAsync.valueOrNull;
                showGameRulesDialog(
                  context: context,
                  title: context.l10n.rulesBattleshipTitle,
                  content: rulesTextLines(battleshipRuleLines(
                    turnTimeSec: game?.turnTimeSec ?? 0,
                    stakeBronze: game?.stakeBronze ?? 2,
                    offlineBot: _isOffline,
                    l10n: context.l10n,
                  )),
                  closeLabel: context.l10n.commonClose,
                );
              },
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
                  data: (server) {
                    final game = _displayGame(server);
                    // Сразу при входе в setup — случайная (или серверная) расстановка.
                    _syncLocalShips(game);
                    _syncSetupLocalDeadline(game);
                    final isOver = game.isOver;
                    _maybeSettleGame(game, me);
                    final chip = _rewardChipBronze(game, me);
                    final status = _statusText(game, me);
                    final myTurn = game.isTurnOf(me);
                    final nowSec =
                        DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
                    final setupDeadline = _setupLocalDeadline > 0
                        ? _setupLocalDeadline
                        : game.setupDeadline;
                    final showSetupTimer = !isOver &&
                        !_hideTimers &&
                        game.isSetup &&
                        !_iAmReady(game, me) &&
                        setupDeadline > nowSec;
                    final column = Column(
                      children: [
                        MyTurnAlert(isMyTurn: myTurn && !isOver),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            narrow ? 12 : 20,
                            4,
                            narrow ? 12 : 20,
                            0,
                          ),
                          child: Column(
                            children: [
                              if (!isOver) _buildOpponentCard(game, me),
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
                        if (showSetupTimer)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: GameTurnCountdown(
                              key: ValueKey('setup_${game.setupDeadline}'),
                              turnDeadline: setupDeadline,
                              turnTimeSec: 60,
                              isMyTurn: true,
                              onExpired: () => unawaited(_onSetupExpired()),
                              labelBuilder: (s) =>
                                  context.l10n.gameSecondsLeft(s),
                            ),
                          ),
                        if (!isOver &&
                            !_hideTimers &&
                            game.isBattle &&
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
                          if (_isOffline)
                            FilledButton.icon(
                              onPressed: _isRematching
                                  ? null
                                  : () => unawaited(_rematch()),
                              icon: const Icon(Icons.replay_rounded, size: 18),
                              label: Text(context.l10n.offlinePlayAgain),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accentStart,
                                foregroundColor: Colors.white,
                              ),
                            )
                          else
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
                              onCancelWait: () =>
                                  unawaited(_cancelRematchWait()),
                              onFindGame: () => unawaited(_findGame()),
                              compact: true,
                            ),
                        ],
                        Expanded(
                          child: game.isSetup
                              ? _buildSetup(game, me, narrow)
                              : _buildBattle(game, me, narrow),
                        ),
                      ],
                    );
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        const designH = 640.0;
                        if (constraints.maxHeight >= 520) {
                          return column;
                        }
                        return FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: math.max(constraints.maxWidth, 280),
                            height: designH,
                            child: column,
                          ),
                        );
                      },
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
                  Builder(
                    builder: (context) {
                      final g = gameAsync.valueOrNull!;
                      final offerBy = g.drawOfferBy?.trim();
                      final iOffered = offerBy != null &&
                          me != null &&
                          offerBy == me;
                      final oppOffered = offerBy != null &&
                          me != null &&
                          offerBy.isNotEmpty &&
                          offerBy != me;
                      final canDraw = g.isBattle &&
                          !g.isOver &&
                          !g.hasBotOpponent;
                      return Positioned(
                        right: 4,
                        top: 4,
                        child: GameActionsOverlay(
                          canDraw: canDraw,
                          iOfferedDraw: iOffered,
                          opponentOfferedDraw: oppOffered,
                          onSurrender: () => unawaited(_confirmSurrender()),
                          onDraw: () => oppOffered
                              ? unawaited(_confirmAcceptDraw())
                              : unawaited(_confirmOfferDraw()),
                          surrenderTooltip: context.l10n.gameSurrender,
                          drawTooltip: context.l10n.gameOfferDraw,
                          acceptDrawTooltip:
                              context.l10n.gameAcceptDrawTitle,
                          drawOfferedTooltip: context.l10n.gameDrawOffered,
                        ),
                      );
                    },
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
      padding: EdgeInsets.fromLTRB(
        narrow ? 8 : 20,
        narrow ? 4 : 12,
        narrow ? 8 : 20,
        narrow ? 8 : 16,
      ),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Кнопки уже заняли высоту — клетка из остатка, низ поля не режется.
                final cell = fitBattleshipCellSize(
                  maxWidth: constraints.maxWidth,
                  maxHeight: constraints.maxHeight,
                  maxCell: narrow ? 36 : 40,
                );
                final board = ready
                    ? _BattleshipBoard(
                        cellSize: cell,
                        cellBuilder: (cellIdx) {
                          final occupied = <int>{
                            for (final s in ships) ...s,
                          };
                          return _CellPaint(
                            color: occupied.contains(cellIdx)
                                ? _kShip
                                : _kWater,
                          );
                        },
                      )
                    : _BattleshipSetupBoard(
                        cellSize: cell,
                        ships: ships,
                        selectedShipIndex: selectedIdx,
                        enabled: !_busy,
                        onTapCell: _onSetupCellTap,
                        onShipDropped: _onSetupShipDropped,
                        onShipSelected: (i) =>
                            setState(() => _selectedShipIndex = i),
                      );
                return Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: board,
                  ),
                );
              },
            ),
          ),
          if (!ready) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => unawaited(_randomPlace()),
                    icon: const Icon(Icons.casino_rounded, size: 18),
                    label: Text(
                      context.l10n.gamesBattleshipRandomPlace,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed:
                      _busy || selectedIdx == null ? null : _rotateSelected,
                  tooltip: context.l10n.gamesBattleshipRotate,
                  icon: const Icon(Icons.rotate_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : () => unawaited(_confirmPlace()),
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
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBattle(BattleshipGameView game, String? me, bool narrow) {
    final myTurn = game.isTurnOf(me);
    // Одно поле: мой ход / конец — поле соперника; ход соперника — моё.
    // Во время FX удерживаем поле, куда пришёл выстрел, ещё 1с.
    final showMyBoard = _fxShowMineBoard ?? (!game.isOver && !myTurn);
    final pulseCell = _pulseHitCell;

    return Padding(
      padding: EdgeInsets.all(narrow ? 8 : 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = fitBattleshipCellSize(
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
            maxCell: narrow ? 36 : 40,
          );
          final board = showMyBoard
              ? _buildMyDefenseBoard(
                  game,
                  cellSize: cellSize,
                  pulseCell: pulseCell,
                )
              : _buildOpponentAttackBoard(
                  game,
                  cellSize: cellSize,
                  pulseCell: pulseCell,
                  canShoot: myTurn &&
                      !game.isOver &&
                      !_busy &&
                      _pendingShotCell == null,
                );
          return Center(child: board);
        },
      ),
    );
  }

  Widget _buildMyDefenseBoard(
    BattleshipGameView game, {
    required double cellSize,
    int? pulseCell,
  }) {
    final myOccupied = <int>{for (final s in game.myShips) ...s};
    final oppShots = game.opponentShots.toSet();
    final sunkMap = <int, List<int>>{
      for (final ship in game.mySunkShips)
        for (final c in ship) c: ship,
    };
    return _BattleshipBoard(
      cellSize: cellSize,
      pulseCell: pulseCell,
      pulseHit: _fxHit,
      pulseAnimation: _hitPulse,
      cellBuilder: (cell) {
        final sunkShip = sunkMap[cell];
        if (sunkShip != null) {
          return _SunkShipCell(
            cell: cell,
            shipCells: sunkShip.toSet(),
            fill: _kSunkShipMine,
            frame: _kSunkFrameMine,
          );
        }
        final ship = myOccupied.contains(cell);
        final shot = oppShots.contains(cell) ||
            (pulseCell == cell && _fxShowMineBoard == true);
        if (shot && ship) {
          return const _CellPaint(color: _kHit, mark: _CellMark.hit);
        }
        if (shot && !ship && pulseCell == cell && !_fxHit) {
          return const _CellPaint(color: _kMiss, mark: _CellMark.miss);
        }
        if (shot && !ship) {
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
    final sunkMap = <int, List<int>>{
      for (final ship in game.opponentSunkShips)
        for (final c in ship) c: ship,
    };
    final sunkCells = sunkMap.keys.toSet();
    final revealed = <int>{for (final s in game.opponentShips) ...s};
    return _BattleshipBoard(
      cellSize: cellSize,
      pulseCell: pulseCell,
      pulseHit: _fxHit,
      pulseAnimation: _hitPulse,
      cellBuilder: (cell) {
        final mark = battleshipAttackMark(
          cell: cell,
          myHits: myHits,
          myShots: myShots,
          opponentSunkCells: sunkCells,
          pendingCell: _overlay.pendingCell ?? _pendingShotCell,
        );
        switch (mark) {
          case BattleshipAttackMark.sunk:
            final sunkShip = sunkMap[cell];
            if (sunkShip != null) {
              return _SunkShipCell(cell: cell, shipCells: sunkShip.toSet());
            }
            return const _CellPaint(color: _kSunkShip);
          case BattleshipAttackMark.hit:
            return const _CellPaint(color: _kHit, mark: _CellMark.hit);
          case BattleshipAttackMark.miss:
            return const _CellPaint(color: _kMiss, mark: _CellMark.miss);
          case BattleshipAttackMark.pending:
            return const _CellPaint(
              color: _kPendingWater,
              mark: _CellMark.pending,
            );
          case BattleshipAttackMark.water:
            if (revealed.contains(cell)) {
              return const _CellPaint(color: _kShip);
            }
            return const _CellPaint(color: _kWater);
        }
      },
      onTap: canShoot
          ? (cell) {
              if (battleshipCellSpent(
                cell: cell,
                myShots: myShots,
                myHits: myHits,
                sunkCells: sunkCells,
                pendingCell: _overlay.pendingCell ?? _pendingShotCell,
              )) {
                return;
              }
              unawaited(_shoot(cell));
            }
          : null,
    );
  }
}

enum _CellMark { none, hit, miss, pending }

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
      child: switch (mark) {
        _CellMark.none => const SizedBox.expand(),
        _CellMark.hit => const Center(
            child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
          ),
        _CellMark.miss => Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.textSecondary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        _CellMark.pending => Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.6),
              ),
            ),
          ),
      },
    );
  }
}

/// Потопленный корабль: без крестиков, заливка и рамка по контуру.
class _SunkShipCell extends StatelessWidget {
  const _SunkShipCell({
    required this.cell,
    required this.shipCells,
    this.fill = _kSunkShip,
    this.frame = _kSunkFrame,
  });
  final int cell;
  final Set<int> shipCells;
  final Color fill;
  final Color frame;

  @override
  Widget build(BuildContext context) {
    final r = cell ~/ kBattleshipBoardSize;
    final c = cell % kBattleshipBoardSize;
    bool has(int dr, int dc) {
      final nr = r + dr;
      final nc = c + dc;
      if (nr < 0 ||
          nr >= kBattleshipBoardSize ||
          nc < 0 ||
          nc >= kBattleshipBoardSize) {
        return false;
      }
      return shipCells.contains(nr * kBattleshipBoardSize + nc);
    }

    const w = 2.5;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        border: Border(
          top: BorderSide(color: frame, width: has(-1, 0) ? 0 : w),
          bottom: BorderSide(color: frame, width: has(1, 0) ? 0 : w),
          left: BorderSide(color: frame, width: has(0, -1) ? 0 : w),
          right: BorderSide(color: frame, width: has(0, 1) ? 0 : w),
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _BattleshipBoard extends StatelessWidget {
  const _BattleshipBoard({
    required this.cellBuilder,
    this.onTap,
    this.cellSize = 32,
    this.pulseCell,
    this.pulseHit = true,
    this.pulseAnimation,
  });

  final Widget Function(int cell) cellBuilder;
  final void Function(int cell)? onTap;
  final double cellSize;
  final int? pulseCell;
  final bool pulseHit;
  final Animation<double>? pulseAnimation;

  @override
  Widget build(BuildContext context) {
    final size = cellSize.clamp(11.0, 44.0);
    const gap = 2.0;
    final board = size * kBattleshipBoardSize + gap * (kBattleshipBoardSize - 1);
    final glow = pulseHit ? _kHit : const Color(0xFF90A4AE);
    return SizedBox(
      width: board,
      height: board,
      child: Column(
        children: [
          for (var row = 0; row < kBattleshipBoardSize; row++) ...[
            if (row > 0) const SizedBox(height: gap),
            SizedBox(
              height: size,
              child: Row(
                children: [
                  for (var col = 0; col < kBattleshipBoardSize; col++) ...[
                    if (col > 0) const SizedBox(width: gap),
                    SizedBox(
                      width: size,
                      height: size,
                      child: _boardCell(
                        index: row * kBattleshipBoardSize + col,
                        glow: glow,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _boardCell({required int index, required Color glow}) {
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
                    color: glow.withValues(alpha: 0.55 * (1 - t)),
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
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onTap!(index),
      child: child,
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

  double get _size => widget.cellSize.clamp(11.0, 44.0);

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

  Color _setupCellColor(
    int index, {
    required Set<int> preview,
    required bool previewOk,
    required Set<int> draggingShip,
    required Set<int> conflictCells,
    required Set<int> selected,
    required Set<int> occupied,
  }) {
    if (preview.contains(index)) {
      return previewOk ? _kPreviewOk : _kConflictShip;
    }
    if (_didDrag && draggingShip.contains(index)) {
      return _kShip.withValues(alpha: 0.35);
    }
    if (conflictCells.contains(index)) return _kConflictShip;
    if (selected.contains(index)) return _kSelectedShip;
    if (occupied.contains(index)) return _kShip;
    return _kWater;
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
        child: Column(
          children: [
            for (var row = 0; row < kBattleshipBoardSize; row++) ...[
              if (row > 0) const SizedBox(height: _gap),
              SizedBox(
                height: size,
                child: Row(
                  children: [
                    for (var col = 0; col < kBattleshipBoardSize; col++) ...[
                      if (col > 0) const SizedBox(width: _gap),
                      SizedBox(
                        width: size,
                        height: size,
                        child: _CellPaint(
                          color: _setupCellColor(
                            row * kBattleshipBoardSize + col,
                            preview: preview,
                            previewOk: previewOk,
                            draggingShip: draggingShip,
                            conflictCells: conflictCells,
                            selected: selected,
                            occupied: occupied,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
