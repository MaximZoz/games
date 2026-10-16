import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_grid.dart';
import 'package:multigames_client/core/gamepad/gamepad_glyph.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/game_turn_action.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException;
import 'package:multigames_client/games/nardy/nardy_board_layout.dart';
import 'package:multigames_client/games/nardy/nardy_board_widget.dart';
import 'package:multigames_client/games/nardy/nardy_checker_tracker.dart';
import 'package:multigames_client/games/nardy/nardy_dice_widget.dart';
import 'package:multigames_client/games/nardy/nardy_engine.dart';
import 'package:multigames_client/games/nardy/nardy_layout_toggle.dart';
import 'package:multigames_client/games/nardy/nardy_move_planner.dart';
import 'package:multigames_client/games/nardy/nardy_offline_session.dart';
import 'package:multigames_client/games/nardy/nardy_provider.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';
import 'package:multigames_client/games/nardy/nardy_sfx.dart';
import 'package:multigames_client/games/game_stake.dart';
import 'package:multigames_client/games/offline_session_hold.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';
import 'package:multigames_client/ui/widgets/nardy_game_icon.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';
import 'package:multigames_client/utils/user_error.dart';

class NardyGameScreen extends ConsumerStatefulWidget {
  const NardyGameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  ConsumerState<NardyGameScreen> createState() => _NardyGameScreenState();
}

class _NardyGameScreenState extends ConsumerState<NardyGameScreen> {
  final GameTurnActionLock _turnAction = GameTurnActionLock();
  final GlobalKey _rewardKey = GlobalKey();
  final NardyCheckerTracker _tracker = NardyCheckerTracker();

  int? _selectedTrack;
  int _gamepadSlot = 0;
  bool _busy = false;
  bool _isRematching = false;
  bool _isAcceptingRematch = false;
  bool _isFindingGame = false;
  bool _rematchDeclined = false;
  bool _iDeclinedRematch = false;
  String? _rematchLobbyId;
  String _autoRollKey = '';
  String _autoEndKey = '';
  NardyGameView? _optimisticGame;
  Timer? _rematchPollTimer;
  ProviderSubscription<AsyncValue<Map<String, dynamic>>>? _realtimeSubscription;

  bool get _isOffline => OfflineNardyRegistry.instance.isOffline(widget.gameId);

  @override
  void didUpdateWidget(covariant NardyGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId == widget.gameId) return;
    _rematchPollTimer?.cancel();
    _selectedTrack = null;
    _optimisticGame = null;
    _autoRollKey = '';
    _autoEndKey = '';
    _busy = false;
    _turnAction.release();
    setState(() {
      _rematchLobbyId = null;
      _rematchDeclined = false;
      _iDeclinedRematch = false;
      _isRematching = false;
      _isAcceptingRematch = false;
      _isFindingGame = false;
    });
    ref.invalidate(nardyGameProvider(widget.gameId));
  }

  @override
  void initState() {
    super.initState();
    _realtimeSubscription = ref.listenManual(
      realtimeEventsProvider,
      (_, next) {
        final event = next.valueOrNull;
        if (event == null) return;
        final update = rematchRealtimeUpdate(
          event: event,
          rematchLobbyId: _rematchLobbyId,
        );
        if (update == null || !mounted) return;
        if ((update.startedGameId ?? '').isNotEmpty) {
          _openRematchGame(update.startedGameId!);
        } else if (update.declined) {
          _rematchPollTimer?.cancel();
          setState(() {
            _rematchLobbyId = null;
            _rematchDeclined = true;
          });
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isOffline) {
        rememberGamesSessionPath(ref, '/games/nardy/offline');
        return;
      }
      final known = ref.read(nardyGameProvider(widget.gameId)).valueOrNull;
      if (known != null && known.isOver) {
        _clearSessionForFinishedGame();
      } else {
        pinBlockingGame(ref, widget.gameId, gameType: 'nardy');
        final prev = ref.read(activeGameProvider).valueOrNull;
        if (prev?.gameId != widget.gameId) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: widget.gameId,
                  lobbyId: prev?.lobbyId,
                  gameType: 'nardy',
                ),
              );
        }
      }
      unawaited(ref.read(activeGameProvider.notifier).refresh());
    });
  }

  @override
  void dispose() {
    _rematchPollTimer?.cancel();
    _realtimeSubscription?.close();
    _turnAction.release();
    super.dispose();
  }

  void _clearSessionForFinishedGame() {
    clearBlockingGamePin(ref, ifGameId: widget.gameId);
    final prev = ref.read(activeGameProvider).valueOrNull;
    if (prev?.gameId == widget.gameId) {
      ref.read(activeGameProvider.notifier).clearLocal();
    }
  }

  NardyRepository get _repo => ref.read(nardyRepositoryProvider);

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || !_turnAction.tryAcquire()) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      if (!_isOffline) ref.invalidate(nardyGameProvider(widget.gameId));
    } on GamesException catch (e) {
      if (!mounted) return;
      if (!isStaleNotYourTurnError(e) && !isStaleGameOverError(e)) {
        showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
      }
      if (!_isOffline) ref.invalidate(nardyGameProvider(widget.gameId));
    } finally {
      _turnAction.release();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _roll() => _run(() => _repo.roll(widget.gameId));

  void _scheduleAutoRoll(NardyGameView game) {
    if (!game.isMyTurn || !game.needsRoll || game.isOver || _busy) return;
    final key = '${game.id}:${game.seq}:${game.turn}:${game.turnNo}';
    if (_autoRollKey == key) return;
    _autoRollKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final latest = ref.read(nardyGameProvider(widget.gameId)).valueOrNull;
      if (latest == null ||
          latest.isOver ||
          !latest.isMyTurn ||
          !latest.needsRoll ||
          _busy) {
        return;
      }
      unawaited(_roll());
    });
  }

  void _scheduleAutoEndTurn(NardyGameView game) {
    final autoConfirm = ref.read(nardyAutoConfirmProvider);
    if (_busy ||
        !nardyShouldAutoEndTurn(
          autoConfirm: autoConfirm,
          isMyTurn: game.isMyTurn,
          isOver: game.isOver,
          needsRoll: game.needsRoll,
          hasLegalMoves: game.legalMoves.isNotEmpty,
        )) {
      return;
    }
    final key = '${game.id}:${game.seq}:${game.turn}:${game.turnNo}';
    if (_autoEndKey == key) return;
    _autoEndKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _busy) return;
      final latest = _optimisticGame ??
          ref.read(nardyGameProvider(widget.gameId)).valueOrNull;
      if (latest == null) return;
      if (!nardyShouldAutoEndTurn(
        autoConfirm: ref.read(nardyAutoConfirmProvider),
        isMyTurn: latest.isMyTurn,
        isOver: latest.isOver,
        needsRoll: latest.needsRoll,
        hasLegalMoves: latest.legalMoves.isNotEmpty,
      )) {
        return;
      }
      unawaited(_endTurn());
    });
  }

  Future<void> _endTurn() {
    setState(() => _selectedTrack = null);
    return _run(() => _repo.endTurn(widget.gameId));
  }

  Future<void> _undo() {
    setState(() => _selectedTrack = null);
    return _run(() => _repo.undo(widget.gameId));
  }

  Future<void> _applyMoves(List<NardyMove> moves) async {
    if (moves.isEmpty) return;
    if (_busy || !_turnAction.tryAcquire()) return;
    final base = _optimisticGame ??
        ref.read(nardyGameProvider(widget.gameId)).valueOrNull;
    if (base == null) {
      _turnAction.release();
      return;
    }
    setState(() {
      _selectedTrack = null;
      _busy = true;
    });
    try {
      for (var i = 0; i < moves.length; i++) {
        final current = _optimisticGame ??
            ref.read(nardyGameProvider(widget.gameId)).valueOrNull ??
            base;
        final optimistic = nardyViewAfterMoves(current, [moves[i]]);
        setState(() => _optimisticGame = optimistic);
        await _repo.move(widget.gameId, moves[i]);
        if (i + 1 < moves.length) {
          await Future<void>.delayed(
            NardyBoard.moveDuration + const Duration(milliseconds: 80),
          );
        }
      }
      if (!mounted) return;
      if (!_isOffline) ref.invalidate(nardyGameProvider(widget.gameId));
    } on GamesException catch (e) {
      if (!mounted) return;
      setState(() => _optimisticGame = null);
      if (!isStaleNotYourTurnError(e) && !isStaleGameOverError(e)) {
        showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
      }
      if (!_isOffline) ref.invalidate(nardyGameProvider(widget.gameId));
    } finally {
      _turnAction.release();
      if (mounted) {
        setState(() => _busy = false);
        final latest = _optimisticGame ??
            ref.read(nardyGameProvider(widget.gameId)).valueOrNull;
        if (latest != null) _scheduleAutoEndTurn(latest);
      }
    }
  }

  void _onTrackTap(NardyGameView game, int track) {
    if (_busy || !game.isMyTurn) return;
    final selected = _selectedTrack;

    // Промах: выбрал сходившую шашку и ткнул туда, откуда она пришла.
    final played = game.lastPlayed;
    if (played != null &&
        selected != null &&
        selected == played.to &&
        track == played.from) {
      unawaited(_undo());
      return;
    }

    if (selected != null) {
      final target = _targetTo(game, selected, track);
      if (target != null) {
        unawaited(_applyMoves(target.moves));
        return;
      }
    }

    // Выбрать можно и только что сходившую шашку — чтобы вернуть её назад.
    final canSelect = nardyMoveTargetsFor(game, track).isNotEmpty ||
        (played != null && played.to == track);
    if (!canSelect) {
      if (selected != null) setState(() => _selectedTrack = null);
      return;
    }
    // Ходим только вторым касанием: первое всегда показывает, куда можно.
    setState(() => _selectedTrack = selected == track ? null : track);
  }

  void _onBarTap(NardyGameView game) {
    if (_busy || !game.isMyTurn || game.dice.isEmpty) return;
    if (!game.movableTracks.contains(nardyBarTrack)) return;
    setState(() => _selectedTrack =
        _selectedTrack == nardyBarTrack ? null : nardyBarTrack);
  }

  /// Шашку с этого пункта можно потащить.
  bool _canDragFrom(NardyGameView game, int track) {
    if (_busy || !game.isMyTurn || game.dice.isEmpty) return false;
    return nardyMoveTargetsFor(game, track).isNotEmpty;
  }

  /// Шашку отпустили: [track] — пункт, [nardyPoints] — зона снятия.
  void _onDropOn(NardyGameView game, int? track) {
    final from = _selectedTrack;
    if (from == null) return;
    if (track == null) {
      setState(() => _selectedTrack = null);
      return;
    }
    if (track >= nardyPoints) {
      final target = _targetTo(game, from, nardyPoints);
      if (target != null) {
        unawaited(_applyMoves(target.moves));
        return;
      }
      setState(() => _selectedTrack = null);
      return;
    }
    final target = _targetTo(game, from, track);
    if (target != null) {
      unawaited(_applyMoves(target.moves));
      return;
    }
    // Бросили мимо — оставляем шашку выбранной, подсветка целей уже видна.
    if (track != from) setState(() => _selectedTrack = from);
  }

  /// Пункты, подсвеченные как «вернуть шашку сюда».
  Set<int> _undoTargets(NardyGameView game) {
    final played = game.lastPlayed;
    if (played == null || !game.isMyTurn) return const {};
    if (_selectedTrack != played.to) return const {};
    if (played.from == nardyBarTrack) return const {};
    return {played.from};
  }

  void _onBearOffTap(NardyGameView game) {
    final selected = _selectedTrack;
    if (selected == null || selected == nardyBarTrack) return;
    final target = _targetTo(game, selected, nardyPoints);
    if (target == null) return;
    unawaited(_applyMoves(target.moves));
  }

  NardyMoveTarget? _targetTo(NardyGameView game, int from, int track) =>
      nardyMoveTargetsFor(game, from)[track];

  Set<int> _targetsFor(NardyGameView game) {
    final from = _selectedTrack;
    if (from == null) return const {};
    final targets = nardyMoveTargetsFor(game, from);
    return targets.keys.where((track) => track < nardyPoints).toSet();
  }

  String _statusText(NardyGameView game) {
    final l10n = context.l10n;
    if (game.isOver) {
      if (game.isDraw) return l10n.gameDraw;
      if (game.myIndex < 0) return l10n.gameOverNeutral;
      if (game.iWon) {
        if (game.isForfeit) return l10n.gameYouWonOpponentForfeit;
        if (game.isTimeout) return l10n.gameYouWonOpponentTimeout;
        return game.isMars ? l10n.nardyYouWonMars : l10n.gameYouWon;
      }
      if (game.isTimeout) return l10n.gameYouLost;
      return game.isMars ? l10n.nardyYouLostMars : l10n.gameYouLost;
    }
    if (game.isMyTurn) {
      if (game.needsRoll) return l10n.nardyYourRoll;
      if (game.legalMoves.isEmpty) return l10n.nardyNoMoves;
      return l10n.gamesMyTurn;
    }
    return l10n.gamesOpponentTurn;
  }

  List<String> _peerIds(NardyGameView game, String? me) => [
        for (final id in game.playerIds)
          if (id.isNotEmpty && id != me) id,
      ];

  Future<void> _confirmSurrender() async {
    final game = ref.read(nardyGameProvider(widget.gameId)).valueOrNull;
    if (game == null || game.isOver) return;
    final ok = await confirmSurrenderDialog(context);
    if (!ok || !mounted) return;
    unawaited(() async {
      try {
        clearBlockingGamePin(ref, ifGameId: widget.gameId);
        await _repo.forfeit(widget.gameId);
      } catch (_) {}
      if (!mounted) return;
      ref.invalidate(nardyGameProvider(widget.gameId));
      unawaited(ref.read(activeGameProvider.notifier).refresh());
    }());
  }

  Future<void> _onClosePressed() async {
    final game = ref.read(nardyGameProvider(widget.gameId)).valueOrNull;
    await handleGameScreenClose(
      context: context,
      isActive: game != null && !game.isOver,
      canLeaveFreely: _isOffline,
      onLeaveFinished: () async {
        if (!mounted) return;
        _navigateToGames();
      },
      onForfeitAndLeave: () async {
        if (!mounted) return;
        try {
          clearBlockingGamePin(ref, ifGameId: widget.gameId);
          await _repo.forfeit(widget.gameId);
        } catch (_) {}
        if (!mounted) return;
        _navigateToGames();
        unawaited(ref.read(activeGameProvider.notifier).refresh());
      },
    );
  }

  void _navigateToGames() {
    if (_isOffline) {
      leaveGamesSession(ref);
      OfflineNardyRegistry.instance.get(widget.gameId)?.dispose();
      context.go('/games');
      return;
    }
    leaveGamesSession(ref);
    final rematchLobbyId = _rematchLobbyId;
    _rematchLobbyId = null;
    _rematchPollTimer?.cancel();
    _clearSessionForFinishedGame();
    context.go('/games');
    if (rematchLobbyId != null) {
      unawaited(_repo.leaveLobby(rematchLobbyId).catchError((_) {}));
    }
  }

  Future<void> _rematch() async {
    setState(() => _isRematching = true);
    try {
      if (_isOffline) {
        _tracker.reset();
        OfflineNardyRegistry.instance.get(widget.gameId)?.restart();
        ref.invalidate(nardyGameProvider(widget.gameId));
        if (mounted) {
          setState(() {
            _isRematching = false;
            _selectedTrack = null;
          });
        }
        return;
      }
      final lobbyId = await _repo.rematch(widget.gameId);
      if (!mounted) return;
      clearBlockingGamePin(ref);
      ref.read(activeGameProvider.notifier).setLocal(
            ActiveGameItem(
              type: 'lobby',
              lobbyId: lobbyId,
              gameType: 'nardy',
            ),
          );
      setState(() {
        _rematchLobbyId = lobbyId;
        _rematchDeclined = false;
        _iDeclinedRematch = false;
        _isRematching = false;
      });
      _startRematchPoll();
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
          await _repo.leaveLobby(own);
        } catch (_) {}
        if (!mounted) return;
      }
      final result = await _repo.joinLobby(lobbyId);
      if (!mounted) return;
      clearBlockingGamePin(ref);
      final gameId = result.gameId ?? '';
      if (gameId.isNotEmpty) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'game',
                gameId: gameId,
                lobbyId: lobbyId,
                gameType: 'nardy',
              ),
            );
        pinBlockingGame(ref, gameId, gameType: 'nardy');
        context.go('/games/nardy/game/$gameId');
      } else {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'lobby',
                lobbyId: lobbyId,
                gameType: 'nardy',
              ),
            );
        context.go('/games/nardy/lobby/$lobbyId?mode=invite');
      }
    } catch (_) {
      if (mounted) context.go('/games');
    } finally {
      if (mounted) setState(() => _isAcceptingRematch = false);
    }
  }

  Future<void> _declineRematch(String lobbyId) async {
    ref.read(gameInvitesProvider.notifier).dismiss(lobbyId);
    try {
      await _repo.declineLobby(lobbyId);
    } catch (_) {}
    if (mounted) setState(() => _iDeclinedRematch = true);
  }

  void _startRematchPoll() {
    _rematchPollTimer?.cancel();
    if (_rematchLobbyId == null) return;
    _rematchPollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_rematchLobbyId == null || !mounted) return;
      ref.invalidate(activeGameProvider);
      try {
        final lobby = await _repo.getLobby(_rematchLobbyId!);
        if (!mounted) return;
        final gameId = lobby.gameId ?? '';
        if (gameId.isNotEmpty) _openRematchGame(gameId);
      } on GamesException catch (e) {
        if (e.statusCode == 404 && mounted) {
          _rematchPollTimer?.cancel();
          setState(() => _rematchLobbyId = null);
        }
      } catch (_) {}
    });
  }

  void _openRematchGame(String gameId) {
    _rematchPollTimer?.cancel();
    ref.read(activeGameProvider.notifier).setLocal(
          ActiveGameItem(
            type: 'game',
            gameId: gameId,
            lobbyId: _rematchLobbyId,
            gameType: 'nardy',
          ),
        );
    pinBlockingGame(ref, gameId, gameType: 'nardy');
    ref.invalidate(nardyGameProvider(gameId));
    if (!mounted) return;
    context.go('/games/nardy/game/$gameId');
  }

  Future<void> _cancelRematchWait() async {
    final lobbyId = _rematchLobbyId;
    if (lobbyId == null) return;
    _rematchPollTimer?.cancel();
    setState(() => _rematchLobbyId = null);
    try {
      await _repo.leaveLobby(lobbyId);
    } catch (_) {}
  }

  Future<void> _findGame() async {
    setState(() => _isFindingGame = true);
    try {
      final rematchId = _rematchLobbyId;
      if (rematchId != null) {
        _rematchPollTimer?.cancel();
        setState(() => _rematchLobbyId = null);
        unawaited(_repo.leaveLobby(rematchId).catchError((_) {}));
      }
      final game = ref.read(nardyGameProvider(widget.gameId)).valueOrNull;
      final created = await _repo.createLobby(
        mode: 'matchmake',
        gameMode: game?.gameMode ?? nardyModeShort,
        turnTimeSec: game?.turnTimeSec ?? 0,
        stakeBronze: game?.stakeBronze ?? 2,
      );
      if (!mounted) return;
      clearBlockingGamePin(ref);
      final gameId = created.gameId ?? '';
      if (gameId.isNotEmpty) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'game',
                gameId: gameId,
                lobbyId: created.lobbyId,
                gameType: 'nardy',
              ),
            );
        pinBlockingGame(ref, gameId, gameType: 'nardy');
        context.go('/games/nardy/game/$gameId');
        return;
      }
      ref.read(activeGameProvider.notifier).setLocal(
            ActiveGameItem(
              type: 'lobby',
              lobbyId: created.lobbyId,
              gameType: 'nardy',
            ),
          );
      context.go('/games/nardy/lobby/${created.lobbyId}?mode=matchmake');
    } catch (_) {
      if (mounted) context.go('/games');
    } finally {
      if (mounted) setState(() => _isFindingGame = false);
    }
  }

  Future<void> _openChat(String userId, String displayName) async {
    try {
      final chatId = await ref.read(chatsRepositoryProvider).startChat(userId);
      if (!mounted || chatId.isEmpty) return;
      context.push(
        Uri(
          path: '/chats/$chatId',
          queryParameters: {
            'name': displayName,
            'from': 'games',
            'game': '/games/nardy/game/${widget.gameId}',
          },
        ).toString(),
      );
    } catch (_) {
      if (!mounted) return;
      context.push(
        Uri(
          path: '/chats',
          queryParameters: {
            'peer': userId,
            'game': '/games/nardy/game/${widget.gameId}',
          },
        ).toString(),
      );
    }
  }

  Future<void> _addFriend(String userId, {String? requestId}) async {
    final repo = ref.read(friendsRepositoryProvider);
    try {
      if (requestId != null) {
        await repo.acceptRequest(requestId);
      } else {
        await repo.sendRequest(userId);
      }
      if (!mounted) return;
      ref.invalidate(friendsSnapshotProvider);
      showAppSnackBar(
        context,
        message: requestId != null
            ? context.l10n.friendsAcceptRequest
            : context.l10n.friendsRequestSent,
        kind: AppSnackKind.success,
      );
    } catch (_) {}
  }

  Widget _buildOpponentCard(NardyGameView game, String? me) {
    final peers = _peerIds(game, me);
    if (peers.isEmpty) return const SizedBox.shrink();
    final oppId = peers.first;
    final opp = game.opponent;
    final isBot = oppId.startsWith('bot:');
    final name = (opp?.displayName.trim().isNotEmpty ?? false)
        ? opp!.displayName.trim()
        : (isBot ? context.l10n.gameBot : context.l10n.gameOpponent);
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
        friends?.outgoing.where((r) => r.user.id == oppId).toList() ?? const [];
    final incoming =
        friends?.incoming.where((r) => r.user.id == oppId).toList() ?? const [];
    final hasOutgoing = outgoing.isNotEmpty;
    final hasIncoming = incoming.isNotEmpty;
    final compact = MediaQuery.sizeOf(context).width < 420;

    return GameOpponentCard(
      displayName: name,
      avatarKind: opp?.avatarKind ?? 'letter',
      avatarValue: opp?.avatarValue,
      frameCode: opp?.frameCode,
      frameColor: opp?.frameColor,
      isBot: isBot,
      messageUnread: unread,
      infoTooltip: context.l10n.userInfoTitle,
      messageTooltip: context.l10n.gameWriteMessage,
      compact: compact,
      maxWidth: 320,
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
        requestId: hasIncoming ? incoming.first.requestId : null,
      )),
      onInfoTap: () => unawaited(showUserProfileDialog(
        context: context,
        ref: ref,
        userId: oppId,
        displayName: name,
        avatarKind: opp?.avatarKind ?? 'letter',
        avatarValue: opp?.avatarValue,
        frameCode: opp?.frameCode,
        frameColor: opp?.frameColor,
        messageFrom: 'games',
        messageReturnPath: '/games/nardy/game/${widget.gameId}',
      )),
      onMessageTap: isBot ? null : () => unawaited(_openChat(oppId, name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(nardyGameProvider(widget.gameId));
    var me = ref.watch(authStateProvider).valueOrNull?.id;
    if (_isOffline && (me == null || me.isEmpty)) {
      me = OfflineNardyRegistry.instance.get(widget.gameId)?.humanUserId;
    }
    final narrow = isNarrow(context);

    ref.listen(nardyGameProvider(widget.gameId), (previous, next) {
      final before = previous?.valueOrNull;
      final after = next.valueOrNull;
      if (after == null) return;
      final optimistic = _optimisticGame;
      if (optimistic != null &&
          optimistic.id == after.id &&
          (after.seq >= optimistic.seq || after.isOver)) {
        setState(() => _optimisticGame = null);
      }
      for (final cue in nardySfxCues(before, after)) {
        switch (cue) {
          case NardySfxCue.roll:
            NardySfx.roll();
          case NardySfxCue.move:
            NardySfx.move();
          case NardySfxCue.hit:
            NardySfx.hit();
        }
      }
    });

    final rawGame = gameAsync.valueOrNull;
    final game = _optimisticGame?.id == rawGame?.id ? _optimisticGame : rawGame;
    return GamepadScope(
      onAction: (action) {
        final raw = ref.read(nardyGameProvider(widget.gameId)).valueOrNull;
        final current = _optimisticGame?.id == raw?.id ? _optimisticGame : raw;
        if (current == null) return false;
        return _onGamepad(current, action);
      },
      child: SwipeBackScope.gameBoard(
        onBack: _onClosePressed,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            toolbarHeight: gameToolbarHeight(context),
            leadingWidth: gameAppBarLeadingWidth(),
            leading: buildGameAppBarLeading(
              onClose: _busy ? null : () => unawaited(_onClosePressed()),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NardyGameIcon(
                  size: narrow ? 20 : 22,
                  color: AppColors.accentStart,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    context.l10n.gamesNardy,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: buildGameAppBarActions(
              context: context,
              onSurrender: game == null || game.isOver
                  ? null
                  : () => unawaited(_confirmSurrender()),
              surrenderTooltip: context.l10n.gameSurrender,
              onShowRules: () => showGameRulesDialog(
                context: context,
                content: rulesTextLines(nardyRuleLines(
                  gameMode: game?.gameMode ?? nardyModeShort,
                  turnTimeSec: game?.turnTimeSec ?? 0,
                  stakeBronze: game?.stakeBronze ?? 0,
                  offline: _isOffline,
                  l10n: context.l10n,
                )),
                closeLabel: context.l10n.commonClose,
              ),
              rulesTooltip: context.l10n.gamesRulesTitle,
            ),
          ),
          body: GradientBackground(
            child: SafeArea(
              child: gameAsync.when(
                skipLoadingOnReload: true,
                skipLoadingOnRefresh: true,
                data: (game) => _buildGame(
                  _optimisticGame?.id == game.id ? _optimisticGame! : game,
                  me,
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accentStart,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    formatUserError(e,
                        fallback: context.l10n.commonGenericError),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<int> _gamepadTracks(NardyGameView game) => [
        ...nardyVisualTracks(
          homeOnRight: ref.read(nardyHomeOnRightProvider),
        ),
        if (!game.isLong) nardyBarTrack,
        nardyPoints,
      ];

  bool _onGamepad(NardyGameView game, GamepadAction action) {
    if (action == GamepadAction.shoulderL ||
        action == GamepadAction.shoulderR) {
      return false;
    }
    if (game.isOver) return false;
    final tracks = _gamepadTracks(game);
    _gamepadSlot = _gamepadSlot.clamp(0, tracks.length - 1);
    if (action.isDirection) {
      final cursor = GamepadGridCursor(
        columns: 12,
        count: tracks.length,
        index: _gamepadSlot,
      );
      if (cursor.move(action)) {
        setState(() => _gamepadSlot = cursor.index);
      }
      return true;
    }
    if (action == GamepadAction.confirm) {
      if (_busy || !game.isMyTurn) return true;
      final track = tracks[_gamepadSlot];
      if (track == nardyBarTrack) {
        _onBarTap(game);
      } else if (track == nardyPoints) {
        _onBearOffTap(game);
      } else {
        _onTrackTap(game, track);
      }
      return true;
    }
    if (action == GamepadAction.cancel && _selectedTrack != null) {
      setState(() => _selectedTrack = null);
      return true;
    }
    if (action == GamepadAction.actionX) {
      if (!_busy && game.isMyTurn && game.canUndo) {
        unawaited(_undo());
      }
      return true;
    }
    if (action == GamepadAction.actionY || action == GamepadAction.menu) {
      if (_busy || !game.isMyTurn) return true;
      if (game.needsRoll) {
        unawaited(_roll());
      } else {
        unawaited(_endTurn());
      }
      return true;
    }
    return false;
  }

  Widget _buildGame(NardyGameView game, String? me) {
    _scheduleAutoRoll(game);
    _scheduleAutoEndTurn(game);
    final myTurn = game.isMyTurn && !game.isOver;
    final landscape = isPhoneLandscape(context) ||
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
          child: landscape
              ? _buildLandscape(game, me, myTurn)
              : _buildPortrait(game, me, myTurn),
        ),
        if (game.isOver && game.iWon)
          Positioned.fill(
            child: GameConfettiOverlay(
              key: ValueKey('nardy-confetti-${widget.gameId}'),
            ),
          ),
        MyTurnAlert.stackLeaf(isMyTurn: myTurn),
      ],
    );
  }

  /// Доска занимает всю доступную высоту, полоса «осталось» — её ширину.
  Widget _buildBoard(NardyGameView game) {
    final selected = _selectedTrack;
    final canBearOff =
        selected != null && _targetTo(game, selected, nardyPoints) != null;
    final homeOnRight = ref.watch(nardyHomeOnRightProvider);
    final mySeat = game.myIndex < 0 ? 0 : game.myIndex;
    // Моя шашка сбита на бар и сейчас мой ход — подсветить бар (её надо ввести).
    final highlightBar = game.isMyTurn &&
        !game.isOver &&
        selected != nardyBarTrack &&
        mySeat < game.bar.length &&
        game.bar[mySeat] > 0;
    const barHeight = 26.0;
    const barGap = 6.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = nardyFitBoard(Size(
          constraints.maxWidth,
          constraints.maxHeight - barHeight - barGap,
        ));
        if (size.isEmpty) return const SizedBox.shrink();
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPipsBar(game, size.width),
            const SizedBox(height: barGap),
            SizedBox(
              width: size.width,
              height: size.height,
              child: NardyBoard(
                game: game,
                tracker: _tracker,
                selectedTrack: selected,
                homeOnRight: homeOnRight,
                highlightBar: highlightBar,
                cursorTrack: GamepadService.instance.isRecentlyActive
                    ? _gamepadTracks(game)[_gamepadSlot.clamp(
                        0,
                        _gamepadTracks(game).length - 1,
                      )]
                    : null,
                targetTracks: _targetsFor(game),
                canBearOff: canBearOff,
                undoTracks: _undoTargets(game),
                onTrackTap: (track) => _onTrackTap(game, track),
                onBarTap: () => _onBarTap(game),
                onBearOffTap: () => _onBearOffTap(game),
                canDragFrom: (track) => _canDragFrom(game, track),
                onDragStart: (track) => setState(() => _selectedTrack = track),
                onDragEnd: (track) => _onDropOn(game, track),
                dragCancel: () => setState(() => _selectedTrack = null),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPortrait(NardyGameView game, String? me, bool myTurn) {
    final panelHeight = nardyBottomPanelHeight(isOver: game.isOver);
    final panel = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusLine(game, myTurn),
        const SizedBox(height: 6),
        _buildControls(game, myTurn),
        if (game.isOver) ...[
          const SizedBox(height: 8),
          _buildFinishRow(game, me),
        ],
      ],
    );
    return Column(
      children: [
        _buildOpponentRow(game, me),
        const SizedBox(height: 6),
        Expanded(child: _buildBoard(game)),
        const SizedBox(height: 6),
        if (panelHeight == null)
          panel
        else
          SizedBox(height: panelHeight, child: panel),
      ],
    );
  }

  Widget _buildLandscape(NardyGameView game, String? me, bool myTurn) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 7, child: _buildBoard(game)),
        const SizedBox(width: 10),
        SizedBox(
          width: 210,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOpponentRow(game, me),
                const SizedBox(height: 8),
                _buildStatusLine(game, myTurn),
                const SizedBox(height: 8),
                _buildControls(game, myTurn),
                if (game.isOver) ...[
                  const SizedBox(height: 10),
                  _buildFinishRow(game, me),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpponentRow(NardyGameView game, String? me) =>
      _buildOpponentCard(game, me);

  /// Полоса «осталось» на двоих — по ширине доски.
  Widget _buildPipsBar(NardyGameView game, double width) {
    final mine = game.me;
    final opp = game.opponent;
    if (mine == null || opp == null) return const SizedBox.shrink();
    const toggleGap = 6.0;
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Expanded(
            child: NardyPipsBar(
              myPips: mine.pips,
              oppPips: opp.pips,
              myTurn: game.isMyTurn,
              isOver: game.isOver,
            ),
          ),
          const SizedBox(width: toggleGap),
          const NardyLayoutToggleButton(),
        ],
      ),
    );
  }

  Widget _buildStatusLine(NardyGameView game, bool myTurn) {
    final rewardChip = stakeFinishRewardChip(
      stakeBronze: game.stakeBronze,
      isDraw: game.isDraw,
      iWon: game.iWon,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GameStatusWithReward(
          statusText: _statusText(game),
          showReward: stakeShowFinishReward(
            stakeBronze: game.stakeBronze,
            isOver: game.isOver,
            isDraw: game.isDraw,
            rewardChip: rewardChip,
          ),
          rewardBronze: rewardChip,
          rewardKey: _rewardKey,
          fontSize: 14,
          wrap: true,
        ),
        if (!game.isOver && game.turnTimeSec > 0 && game.turnDeadline > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GameTurnCountdown(
              key: ValueKey('${game.turn}_${game.turnDeadline}'),
              turnDeadline: game.turnDeadline,
              isMyTurn: myTurn,
              turnTimeSec: game.turnTimeSec,
              onExpired: () => ref.invalidate(nardyGameProvider(widget.gameId)),
              labelBuilder: (s) => context.l10n.gameSecondsLeft(s),
            ),
          ),
      ],
    );
  }

  Widget _buildControls(NardyGameView game, bool myTurn) {
    final l10n = context.l10n;
    final autoConfirm = ref.watch(nardyAutoConfirmProvider);
    final canEnd = nardyCanEndTurn(
      isMyTurn: myTurn,
      isOver: game.isOver,
      needsRoll: game.needsRoll,
      hasLegalMoves: game.legalMoves.isNotEmpty,
    );
    final showEndTurn = nardyShouldShowEndTurn(
      autoConfirm: autoConfirm,
      isMyTurn: myTurn,
      isOver: game.isOver,
      needsRoll: game.needsRoll,
      hasLegalMoves: game.legalMoves.isNotEmpty,
    );
    final noMoves = canEnd && game.currentTurn.isEmpty;
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        NardyDiceRow(
          rolled: game.rolled,
          remaining: game.dice,
          rollKey: '${game.turnNo}_${game.rolled.join(",")}',
          highlight: myTurn,
          size: 38,
        ),
        if (nardyShouldShowAutoConfirm(isMyTurn: myTurn, isOver: game.isOver))
          _buildAutoConfirmCheck(autoConfirm),
        if (myTurn && game.canUndo)
          FramedButton(
            gamepadAction: GamepadAction.actionX,
            onPressed: _busy ? null : () => unawaited(_undo()),
            icon: Icons.undo_rounded,
            label: l10n.nardyUndoMove,
          ),
        if (showEndTurn)
          FramedButton(
            gamepadAction: GamepadAction.actionY,
            onPressed: _busy ? null : () => unawaited(_endTurn()),
            icon: noMoves ? Icons.skip_next_rounded : Icons.check_rounded,
            label: noMoves ? l10n.nardySkipTurn : l10n.nardyDoneTurn,
          ),
      ],
    );
  }

  Widget _buildAutoConfirmCheck(bool value) {
    final l10n = context.l10n;
    return Tooltip(
      message: l10n.nardyAutoConfirmHint,
      child: GamepadHinted(
        action: GamepadAction.confirm,
        child: InkWell(
          onTap: () => unawaited(
              ref.read(nardyAutoConfirmProvider.notifier).set(!value)),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: IgnorePointer(
                  child: Checkbox(
                    value: value,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    activeColor: AppColors.accentStart,
                    onChanged: (v) => unawaited(
                      ref
                          .read(nardyAutoConfirmProvider.notifier)
                          .set(v ?? false),
                    ),
                  ),
                ),
              ),
              Text(
                l10n.nardyAutoConfirm,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinishRow(NardyGameView game, String? me) {
    if (_isOffline) {
      return Center(
        child: FramedButton(
          onPressed: _isRematching ? null : () => unawaited(_rematch()),
          icon: Icons.replay_rounded,
          label: context.l10n.offlinePlayAgain,
        ),
      );
    }
    return GameRematchSection(
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
      table: RematchTable(
        gameType: 'nardy',
        stakeBronze: game.stakeBronze,
        gameMode: game.gameMode,
      ),
    );
  }
}
