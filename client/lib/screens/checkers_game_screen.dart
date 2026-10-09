import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_grid.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/checkers/checkers_board.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';
import 'package:multigames_client/games/checkers/checkers_material.dart';
import 'package:multigames_client/games/checkers/checkers_offline_session.dart';
import 'package:multigames_client/games/checkers/checkers_provider.dart';
import 'package:multigames_client/games/checkers/checkers_repository.dart';
import 'package:multigames_client/games/checkers/checkers_rules.dart';
import 'package:multigames_client/games/board_move_sfx.dart';
import 'package:multigames_client/games/game_turn_action.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException;
import 'package:multigames_client/games/game_stake.dart';
import 'package:multigames_client/games/offline_session_hold.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/checkers_game_icon.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';
import 'package:multigames_client/utils/user_error.dart';

class CheckersGameScreen extends ConsumerStatefulWidget {
  const CheckersGameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  ConsumerState<CheckersGameScreen> createState() => _CheckersGameScreenState();
}

class _CheckersGameScreenState extends ConsumerState<CheckersGameScreen> {
  final GameTurnActionLock _turnAction = GameTurnActionLock();
  final GlobalKey _rewardKey = GlobalKey();

  CheckersSquare? _selected;
  CheckersSquare _cursor = const CheckersSquare(0, 0);
  bool _busy = false;

  /// Переворот доски вручную. `null` — авто (снизу мои шашки).
  bool? _flipOverride;

  /// Снимки позиции по `seq` — перемотка ходов.
  final List<CheckersGameView> _history = [];
  int? _reviewIndex;
  bool _isRematching = false;
  bool _isAcceptingRematch = false;
  bool _isFindingGame = false;
  bool _rematchDeclined = false;
  bool _iDeclinedRematch = false;
  String? _rematchLobbyId;
  Timer? _rematchPollTimer;
  ProviderSubscription<AsyncValue<Map<String, dynamic>>>? _realtimeSubscription;

  bool get _isOffline =>
      OfflineCheckersRegistry.instance.isOffline(widget.gameId);

  @override
  void didUpdateWidget(covariant CheckersGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId == widget.gameId) return;
    _rematchPollTimer?.cancel();
    _history.clear();
    _reviewIndex = null;
    _selected = null;
    _flipOverride = null;
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
    ref.invalidate(checkersGameProvider(widget.gameId));
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
        rememberGamesSessionPath(ref, '/games/checkers/offline');
        return;
      }
      final known = ref.read(checkersGameProvider(widget.gameId)).valueOrNull;
      if (known != null && known.isOver) {
        _clearSessionForFinishedGame();
      } else {
        pinBlockingGame(ref, widget.gameId, gameType: 'checkers');
        final prev = ref.read(activeGameProvider).valueOrNull;
        if (prev?.gameId != widget.gameId) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: widget.gameId,
                  lobbyId: prev?.lobbyId,
                  gameType: 'checkers',
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

  CheckersRepository get _repo => ref.read(checkersRepositoryProvider);

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || !_turnAction.tryAcquire()) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      if (!_isOffline) ref.invalidate(checkersGameProvider(widget.gameId));
    } on GamesException catch (e) {
      if (!mounted) return;
      if (!isStaleNotYourTurnError(e) && !isStaleGameOverError(e)) {
        showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
      }
      if (!_isOffline) ref.invalidate(checkersGameProvider(widget.gameId));
    } finally {
      _turnAction.release();
      if (mounted) setState(() => _busy = false);
    }
  }

  void _syncSelection(CheckersGameView game) {
    if (!game.isMyTurn || game.isOver) {
      if (_selected != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selected = null);
        });
      }
      return;
    }
    if (game.mustContinue && game.contR >= 0) {
      final forced = CheckersSquare(game.contR, game.contC);
      if (_selected != forced) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selected = forced);
        });
      }
    }
  }

  void _reconcile(CheckersGameView server) {
    if (_history.isNotEmpty &&
        (server.id != _history.last.id || server.seq < _history.last.seq)) {
      _history.clear();
      _reviewIndex = null;
    }
    if (_history.isEmpty || server.seq > _history.last.seq) {
      _history.add(server);
    } else if (server.seq == _history.last.seq) {
      _history[_history.length - 1] = server;
    }
  }

  bool get _isReviewing =>
      _reviewIndex != null && _reviewIndex! < _history.length - 1;

  void _reviewFirst() {
    if (_history.isEmpty) return;
    setState(() {
      _reviewIndex = 0;
      _selected = null;
    });
  }

  void _reviewPrev() {
    if (_history.isEmpty) return;
    final cur = _reviewIndex ?? _history.length - 1;
    if (cur <= 0) return;
    setState(() {
      _reviewIndex = cur - 1;
      _selected = null;
    });
  }

  void _reviewNext() {
    if (_reviewIndex == null) return;
    final next = _reviewIndex! + 1;
    setState(() {
      _reviewIndex = next >= _history.length - 1 ? null : next;
      _selected = null;
    });
  }

  void _reviewLast() {
    setState(() {
      _reviewIndex = null;
      _selected = null;
    });
  }

  Future<void> _onSquareTap(CheckersGameView game, int r, int c) async {
    if (_busy || !game.isMyTurn || game.isOver || _isReviewing) return;
    final sq = CheckersSquare(r, c);
    final fromHere = game.legalMoves.where((m) => m.from == sq).toList();
    final selected = _selected;
    if (selected == null) {
      if (fromHere.isEmpty) return;
      setState(() => _selected = sq);
      return;
    }
    if (selected == sq && !game.mustContinue) {
      setState(() => _selected = null);
      return;
    }
    final dests = game.legalMoves.where((m) => m.from == selected).toList();
    CheckersMove? chosen;
    for (final m in dests) {
      if (m.to == sq) {
        chosen = m;
        break;
      }
    }
    if (chosen == null) {
      if (fromHere.isNotEmpty && !game.mustContinue) {
        setState(() => _selected = sq);
      }
      return;
    }
    setState(() => _selected = null);
    await _run(() => _repo.move(widget.gameId, chosen!));
  }

  String _statusText(CheckersGameView game) {
    final l10n = context.l10n;
    if (game.isOver) {
      if (game.isDraw) {
        switch (game.drawReason) {
          case CheckersEngine.drawReasonRepetition:
            return l10n.checkersDrawRepetition;
          case CheckersEngine.drawReasonNoProgress:
            return l10n.checkersDrawNoProgress;
          case CheckersEngine.drawReasonInsufficient:
            return l10n.checkersDrawInsufficient;
          default:
            return l10n.gameDraw;
        }
      }
      if (game.myIndex < 0) return l10n.gameOverNeutral;
      if (game.iWon) {
        if (game.isForfeit) return l10n.gameYouWonOpponentForfeit;
        if (game.isTimeout) return l10n.gameYouWonOpponentTimeout;
        return l10n.gameYouWon;
      }
      return l10n.gameYouLost;
    }
    return game.isMyTurn ? l10n.gamesMyTurn : l10n.gamesOpponentTurn;
  }

  List<String> _peerIds(CheckersGameView game, String? me) => [
        for (final id in game.playerIds)
          if (id.isNotEmpty && id != me) id,
      ];

  Future<void> _confirmSurrender() async {
    final game = ref.read(checkersGameProvider(widget.gameId)).valueOrNull;
    if (game == null || game.isOver) return;
    final ok = await confirmSurrenderDialog(context);
    if (!ok || !mounted) return;
    unawaited(() async {
      try {
        clearBlockingGamePin(ref, ifGameId: widget.gameId);
        await _repo.forfeit(widget.gameId);
      } catch (_) {}
      if (!mounted) return;
      ref.invalidate(checkersGameProvider(widget.gameId));
      unawaited(ref.read(activeGameProvider.notifier).refresh());
    }());
  }

  Future<void> _confirmDraw() async {
    final game = ref.read(checkersGameProvider(widget.gameId)).valueOrNull;
    if (game == null || game.isOver || game.hasBotOpponent) return;
    final me = ref.read(authStateProvider).valueOrNull?.id;
    final offerBy = game.drawOfferBy;
    final accept = offerBy != null && offerBy.isNotEmpty && offerBy != me;
    final ok = await confirmDrawDialog(context, accept: accept);
    if (!ok || !mounted) return;
    try {
      if (accept) {
        await _repo.acceptDraw(widget.gameId);
      } else {
        await _repo.offerDraw(widget.gameId);
      }
      if (!mounted) return;
      ref.invalidate(checkersGameProvider(widget.gameId));
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: context.l10n.commonGenericError,
        kind: AppSnackKind.error,
      );
    }
  }

  Future<void> _onClosePressed() async {
    final game = ref.read(checkersGameProvider(widget.gameId)).valueOrNull;
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
      OfflineCheckersRegistry.instance.get(widget.gameId)?.dispose();
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
        OfflineCheckersRegistry.instance.get(widget.gameId)?.restart();
        ref.invalidate(checkersGameProvider(widget.gameId));
        if (mounted) {
          setState(() {
            _isRematching = false;
            _selected = null;
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
              gameType: 'checkers',
            ),
          );
      setState(() {
        _rematchLobbyId = lobbyId;
        _rematchDeclined = false;
        _iDeclinedRematch = false;
        _isRematching = false;
        _selected = null;
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
                gameType: 'checkers',
              ),
            );
        pinBlockingGame(ref, gameId, gameType: 'checkers');
        context.go('/games/checkers/game/$gameId');
      } else {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'lobby',
                lobbyId: lobbyId,
                gameType: 'checkers',
              ),
            );
        context.go('/games/checkers/lobby/$lobbyId?mode=invite');
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
            gameType: 'checkers',
          ),
        );
    pinBlockingGame(ref, gameId, gameType: 'checkers');
    ref.invalidate(checkersGameProvider(gameId));
    if (!mounted) return;
    context.go('/games/checkers/game/$gameId');
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
      final game = ref.read(checkersGameProvider(widget.gameId)).valueOrNull;
      final created = await _repo.createLobby(
        mode: 'matchmake',
        gameMode: game?.gameMode ?? CheckersEngine.modeRussian,
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
                gameType: 'checkers',
              ),
            );
        pinBlockingGame(ref, gameId, gameType: 'checkers');
        context.go('/games/checkers/game/$gameId');
        return;
      }
      ref.read(activeGameProvider.notifier).setLocal(
            ActiveGameItem(
              type: 'lobby',
              lobbyId: created.lobbyId,
              gameType: 'checkers',
            ),
          );
      context.go('/games/checkers/lobby/${created.lobbyId}?mode=matchmake');
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
            'game': '/games/checkers/game/${widget.gameId}',
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
            'game': '/games/checkers/game/${widget.gameId}',
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

  Widget _buildOpponentCard(CheckersGameView game, String? me) {
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
      addFriendEnabled: outgoing.isEmpty,
      addFriendBadge: incoming.isNotEmpty ? 1 : 0,
      addFriendTooltip: incoming.isNotEmpty
          ? context.l10n.friendsAcceptRequest
          : (outgoing.isNotEmpty
              ? context.l10n.friendsRequestSent
              : context.l10n.friendsAdd),
      onAddFriendTap: () => unawaited(_addFriend(
        oppId,
        requestId: incoming.isNotEmpty ? incoming.first.requestId : null,
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
        messageReturnPath: '/games/checkers/game/${widget.gameId}',
      )),
      onMessageTap: isBot ? null : () => unawaited(_openChat(oppId, name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(checkersGameProvider(widget.gameId));
    var me = ref.watch(authStateProvider).valueOrNull?.id;
    if (_isOffline && (me == null || me.isEmpty)) {
      me = OfflineCheckersRegistry.instance.get(widget.gameId)?.humanUserId;
    }
    final narrow = isNarrow(context);
    final game = gameAsync.valueOrNull;
    final draw = drawOfferFlags(game?.drawOfferBy, me);
    final canDraw = game != null && !game.isOver && !game.hasBotOpponent;

    return SwipeBackScope.gameBoard(
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
              CheckersGameIcon(
                size: narrow ? 20 : 22,
                color: AppColors.accentStart,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.l10n.gamesCheckers,
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
            onOfferDraw: canDraw ? () => unawaited(_confirmDraw()) : null,
            drawTooltip: context.l10n.gameOfferDraw,
            iOfferedDraw: draw.iOffered,
            opponentOfferedDraw: draw.opponentOffered,
            acceptDrawTooltip: context.l10n.gameAcceptDrawTitle,
            drawOfferedTooltip: context.l10n.gameDrawOffered,
            onShowRules: () => showGameRulesDialog(
              context: context,
              content: rulesTextLines(checkersRuleLines(
                gameMode: game?.gameMode ?? CheckersEngine.modeRussian,
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
              data: (game) {
                _syncSelection(game);
                return _buildGame(game, me);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentStart,
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  formatUserError(e, fallback: context.l10n.commonGenericError),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGame(CheckersGameView server, String? me) {
    _reconcile(server);
    final display = _isReviewing
        ? _history[_reviewIndex!.clamp(0, _history.length - 1)]
        : server;
    final myTurn = server.isMyTurn && !server.isOver && !_isReviewing;
    final landscape = isPhoneLandscape(context) ||
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    return BoardChangeSfx(
      signature: '${server.id}:${server.seq}',
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 2, 0, 6),
            child: landscape
                ? _buildLandscape(server, display, me, myTurn)
                : _buildPortrait(server, display, me, myTurn),
          ),
          if (server.isOver && server.iWon)
            Positioned.fill(
              child: GameConfettiOverlay(
                key: ValueKey('checkers-confetti-${widget.gameId}'),
              ),
            ),
          MyTurnAlert.stackLeaf(isMyTurn: myTurn),
        ],
      ),
    );
  }

  Widget _buildPortrait(
    CheckersGameView live,
    CheckersGameView display,
    String? me,
    bool myTurn,
  ) {
    return Column(
      children: [
        _buildOpponentCard(live, me),
        const SizedBox(height: 6),
        _buildStatusLine(live, myTurn),
        const SizedBox(height: 6),
        Expanded(child: _buildBoardColumn(live, display)),
        if (live.isOver) ...[
          const SizedBox(height: 8),
          _buildFinishRow(live, me),
        ],
      ],
    );
  }

  Widget _buildLandscape(
    CheckersGameView live,
    CheckersGameView display,
    String? me,
    bool myTurn,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 7,
          child: _buildBoardColumn(live, display),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 220,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOpponentCard(live, me),
                const SizedBox(height: 8),
                _buildStatusLine(live, myTurn),
                if (live.isOver) ...[
                  const SizedBox(height: 10),
                  _buildFinishRow(live, me),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoardColumn(CheckersGameView live, CheckersGameView display) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mine = live.myIndex >= 0;
        const edge = 40.0;
        final rows = mine ? 2 : 1;
        final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
        final maxH =
            constraints.maxHeight.isFinite ? constraints.maxHeight : maxW;
        final avail = maxH.isFinite
            ? (maxH - edge * rows).clamp(0.0, maxH).toDouble()
            : maxW;
        final side = avail < maxW ? avail : maxW;
        final oppSeat = live.myIndex == 0 ? 1 : 0;
        final top = mine
            ? _chromeRow(
                material: CheckersMaterialLine(
                  board: display.board,
                  seat: oppSeat,
                ),
              )
            : null;
        final bottom = _chromeRow(
          material: mine
              ? CheckersMaterialLine(board: display.board, seat: live.myIndex)
              : const SizedBox.shrink(),
          trailing: _buildReviewBar(live),
        );
        final board = SizedBox(
          width: side,
          height: side,
          child: _buildBoard(live, display),
        );
        return Column(
          children: [
            if (top != null) top,
            Expanded(child: Center(child: board)),
            bottom,
          ],
        );
      },
    );
  }

  Widget _chromeRow({Widget? trailing, required Widget material}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: material,
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  bool _viewChanged(CheckersGameView game) {
    final fallback = game.myIndex != 1;
    return (_flipOverride ?? fallback) != fallback;
  }

  Widget _buildReviewBar(CheckersGameView game) {
    final cur = _reviewIndex ?? (_history.isEmpty ? 0 : _history.length - 1);
    final canBack = _history.length > 1 && cur > 0;
    final canFwd = _reviewIndex != null;
    return GameReviewBar(
      onFlip: () => setState(
        () => _flipOverride = !(_flipOverride ?? (game.myIndex != 1)),
      ),
      flipTooltip: context.l10n.gameFlipBoard,
      reviewing: _isReviewing,
      flipped: _viewChanged(game),
      onFirst: canBack ? _reviewFirst : null,
      onPrev: canBack ? _reviewPrev : null,
      onNext: canFwd ? _reviewNext : null,
      onLast: canFwd ? _reviewLast : null,
    );
  }

  Widget _buildStatusLine(CheckersGameView game, bool myTurn) {
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
              onExpired: () =>
                  ref.invalidate(checkersGameProvider(widget.gameId)),
              labelBuilder: (s) => context.l10n.gameSecondsLeft(s),
            ),
          ),
      ],
    );
  }

  Widget _buildBoard(CheckersGameView live, CheckersGameView display) {
    final flip = _flipOverride ?? (live.myIndex != 1);
    final interactive = !_isReviewing;
    return GamepadScope(
      onAction: (action) => _onGamepad(live, action, flip: flip),
      child: CheckersBoard(
        game: display,
        selected: interactive ? _selected : null,
        cursor: interactive && GamepadService.instance.isRecentlyActive
            ? _cursor
            : null,
        flip: flip,
        onSquareTap: interactive
            ? (r, c) => unawaited(_onSquareTap(live, r, c))
            : (_, __) {},
      ),
    );
  }

  bool _onGamepad(
    CheckersGameView game,
    GamepadAction action, {
    required bool flip,
  }) {
    if (game.isOver || _isReviewing) return false;
    if (action.isDirection) {
      final cursor = GamepadGridCursor(
        columns: CheckersEngine.size,
        count: CheckersEngine.size * CheckersEngine.size,
        index: _cursor.r * CheckersEngine.size + _cursor.c,
      );
      if (cursor.move(action, flip: flip)) {
        setState(() {
          _cursor = CheckersSquare(
            cursor.index ~/ CheckersEngine.size,
            cursor.index % CheckersEngine.size,
          );
        });
      }
      return true;
    }
    if (action == GamepadAction.confirm) {
      if (!game.isMyTurn || _busy) return true;
      unawaited(_onSquareTap(game, _cursor.r, _cursor.c));
      return true;
    }
    if (action == GamepadAction.cancel && _selected != null) {
      setState(() => _selected = null);
      return true;
    }
    return false;
  }

  Widget _buildFinishRow(CheckersGameView game, String? me) {
    if (_isOffline) {
      return Center(
        child: FilledButton.icon(
          onPressed: _isRematching ? null : () => unawaited(_rematch()),
          icon: const Icon(Icons.replay_rounded, size: 18),
          label: Text(context.l10n.offlinePlayAgain),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentStart,
            foregroundColor: Colors.white,
          ),
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
        gameType: 'checkers',
        stakeBronze: game.stakeBronze,
        gameMode: game.gameMode,
      ),
    );
  }
}
