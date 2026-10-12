import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/domino/domino_engine.dart';
import 'package:multigames_client/games/domino/domino_offline_session.dart';
import 'package:multigames_client/games/domino/domino_provider.dart';
import 'package:multigames_client/games/domino/domino_repository.dart';
import 'package:multigames_client/games/domino/domino_rules.dart';
import 'package:multigames_client/games/domino/domino_table.dart';
import 'package:multigames_client/games/game_balance_settle.dart';
import 'package:multigames_client/games/game_eliminate.dart';
import 'package:multigames_client/games/game_stake.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException;
import 'package:multigames_client/games/offline_session_hold.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/utils/user_error.dart';

class DominoGameScreen extends ConsumerStatefulWidget {
  const DominoGameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  ConsumerState<DominoGameScreen> createState() => _DominoGameScreenState();
}

class _DominoGameScreenState extends ConsumerState<DominoGameScreen> {
  final GlobalKey _rewardKey = GlobalKey();
  bool _busy = false;
  bool _balanceGainPlayed = false;
  bool _isRematching = false;
  bool _isAcceptingRematch = false;
  bool _isFindingGame = false;
  bool _rematchDeclined = false;
  bool _iDeclinedRematch = false;
  String? _rematchLobbyId;
  Timer? _rematchPollTimer;
  bool _expiredSent = false;

  bool get _isOffline =>
      OfflineDominoRegistry.instance.isOffline(widget.gameId);

  @override
  void dispose() {
    _rematchPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _move(String type, {int? tile, String? end}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(dominoRepositoryProvider).move(
            widget.gameId,
            type: type,
            tile: tile,
            end: end,
          );
      if (!_isOffline) {
        await ref.read(dominoGameProvider(widget.gameId).notifier).reconcile();
      }
    } on GamesException catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          message: formatUserError(error),
          kind: AppSnackKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onClose() async {
    final game = ref.read(dominoGameProvider(widget.gameId)).valueOrNull;
    final gone = game?.iForfeited == true;
    await handleGameScreenClose(
      context: context,
      isActive: game != null && !game.isOver && !gone,
      canLeaveFreely: gone,
      onLeaveFinished: () async {
        if (gone && game != null && !game.isOver && !_isOffline) {
          enterGameObservation(ref, widget.gameId, gameType: 'domino');
        }
        _goToGames();
      },
      onForfeitAndLeave: () async {
        try {
          await ref.read(dominoRepositoryProvider).forfeit(widget.gameId);
        } catch (_) {}
        if (mounted) _goToGames();
      },
    );
  }

  void _goToGames() {
    leaveGamesSession(ref);
    if (mounted) context.go('/games');
  }

  void _onTurnExpired() {
    if (_expiredSent || _isOffline) return;
    _expiredSent = true;
    unawaited(ref.read(dominoGameProvider(widget.gameId).notifier).reconcile());
  }

  void _maybeSettle(DominoGameView game) {
    if (_isOffline || _balanceGainPlayed || !game.isOver) return;
    if (isGameBalanceSettled(ref, widget.gameId)) {
      _balanceGainPlayed = true;
      return;
    }
    _balanceGainPlayed = true;
    if (game.stakeBronze <= 0 || game.isDraw) {
      markGameBalanceSettled(ref, widget.gameId);
      unawaited(ref.read(authStateProvider.notifier).refresh());
      return;
    }
    final net = _netProfit(game);
    final credit = game.iWon ? net + game.stakeBronze : 0;
    final lost = stakeLostOnFinish(
      stakeBronze: game.stakeBronze,
      isDraw: game.isDraw,
      iWon: game.iWon,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(() async {
        markGameBalanceSettled(ref, widget.gameId);
        if (lost > 0 && credit <= 0) {
          await playGameSettledLoss(
            ref: ref,
            context: context,
            lostBronze: lost,
          );
          return;
        }
        await playGameSettledReward(
          ref: ref,
          context: context,
          creditBronze: credit,
          displayRewardBronze: net,
          sourceKey: net > 0 ? _rewardKey : null,
        );
      }());
    });
  }

  int _netProfit(DominoGameView game) {
    if (!game.iWon || game.stakeBronze <= 0) return 0;
    final winners = math.max(1, game.winnerUserIds.length);
    return (game.stakeBronze * game.players.length) ~/ winners - game.stakeBronze;
  }

  String _playerName(DominoPlayerView player) {
    final name = (player.displayName ?? '').trim();
    if (name.isNotEmpty) return name;
    if (player.isBot) return context.l10n.gameBot;
    return context.l10n.commonPlayer;
  }

  String _status(DominoGameView game) {
    final l10n = context.l10n;
    if (game.isOver) {
      if (game.isDraw) return l10n.gameDraw;
      if (game.iAmGoat) return l10n.dominoYouGoat;
      if (game.iWon) return l10n.gameYouWonShort;
      if (game.goatSeat >= 0 && game.goatSeat < game.players.length) {
        return l10n.dominoGoatNamed(_playerName(game.players[game.goatSeat]));
      }
      return l10n.gameYouLost;
    }
    if (game.isRoundEnd && game.roundKind == dominoRoundFish) {
      return l10n.dominoFish;
    }
    if (game.isMyTurn || game.canDraw || game.canPass) return l10n.gamesMyTurn;
    return l10n.gamesOpponentTurn;
  }

  List<String> _peerIds(DominoGameView game) => [
        for (final player in game.players)
          if (player.id != game.me?.id && !player.isBot) player.id,
      ];

  Future<void> _rematch() async {
    setState(() => _isRematching = true);
    try {
      final created =
          await ref.read(dominoRepositoryProvider).rematch(widget.gameId);
      if (!mounted) return;
      final gameId = created.gameId?.trim() ?? '';
      if (gameId.isNotEmpty) {
        clearBlockingGamePin(ref);
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'game',
                gameId: gameId,
                lobbyId: created.lobbyId,
                gameType: 'domino',
              ),
            );
        pinBlockingGame(ref, gameId, gameType: 'domino');
        context.go('/games/domino/game/$gameId');
        return;
      }
      if (_isOffline || created.lobbyId.isEmpty) {
        setState(() => _isRematching = false);
        return;
      }
      clearBlockingGamePin(ref);
      ref.read(activeGameProvider.notifier).setLocal(
            ActiveGameItem(
              type: 'lobby',
              lobbyId: created.lobbyId,
              gameType: 'domino',
            ),
          );
      final game = ref.read(dominoGameProvider(widget.gameId)).valueOrNull;
      setState(() {
        _rematchLobbyId = created.lobbyId;
        _rematchDeclined = false;
        _iDeclinedRematch = false;
        _isRematching = false;
      });
      if (!rematchStayOnGameScreen(playerCount: game?.players.length ?? 2)) {
        context.go('/games/domino/lobby/${created.lobbyId}?mode=invite');
        return;
      }
      _startRematchPoll();
    } catch (_) {
      if (mounted) {
        setState(() => _isRematching = false);
        context.go('/games');
      }
    }
  }

  void _startRematchPoll() {
    _rematchPollTimer?.cancel();
    final lobbyId = _rematchLobbyId;
    if (lobbyId == null) return;
    _rematchPollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        final lobby =
            await ref.read(dominoRepositoryProvider).getLobby(lobbyId);
        final gameId = lobby.gameId?.trim() ?? '';
        if (gameId.isNotEmpty && mounted) _openRematch(gameId, lobbyId);
      } on GamesException catch (error) {
        if (error.statusCode == 404 && mounted) {
          _rematchPollTimer?.cancel();
          setState(() => _rematchLobbyId = null);
        }
      } catch (_) {}
    });
  }

  void _openRematch(String gameId, String lobbyId) {
    _rematchPollTimer?.cancel();
    ref.read(activeGameProvider.notifier).setLocal(
          ActiveGameItem(
            type: 'game',
            gameId: gameId,
            lobbyId: lobbyId,
            gameType: 'domino',
          ),
        );
    pinBlockingGame(ref, gameId, gameType: 'domino');
    if (mounted) context.go('/games/domino/game/$gameId');
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
          await ref.read(dominoRepositoryProvider).leaveLobby(own);
        } catch (_) {}
      }
      final result = await ref.read(dominoRepositoryProvider).joinLobby(lobbyId);
      if (!mounted) return;
      clearBlockingGamePin(ref);
      final gameId = result.gameId?.trim() ?? '';
      if (result.joined && gameId.isNotEmpty) {
        _openRematch(gameId, lobbyId);
        return;
      }
      if (result.joined) {
        context.go('/games/domino/lobby/$lobbyId?mode=invite');
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
      await ref.read(dominoRepositoryProvider).declineLobby(lobbyId);
    } catch (_) {}
    if (mounted) setState(() => _iDeclinedRematch = true);
  }

  Future<void> _cancelRematchWait() async {
    final lobbyId = _rematchLobbyId;
    _rematchPollTimer?.cancel();
    setState(() => _rematchLobbyId = null);
    if (lobbyId == null) return;
    try {
      await ref.read(dominoRepositoryProvider).leaveLobby(lobbyId);
    } catch (_) {}
  }

  Future<void> _findGame() async {
    setState(() => _isFindingGame = true);
    try {
      final waiting = _rematchLobbyId;
      if (waiting != null) {
        _rematchPollTimer?.cancel();
        setState(() => _rematchLobbyId = null);
        unawaited(
          ref
              .read(dominoRepositoryProvider)
              .leaveLobby(waiting)
              .catchError((_) {}),
        );
      }
      final game = ref.read(dominoGameProvider(widget.gameId)).valueOrNull;
      final created = await ref.read(dominoRepositoryProvider).createLobby(
            mode: 'matchmake',
            maxPlayers: game?.players.length ?? 2,
            turnTimeSec: game?.turnTimeSec ?? 60,
            stakeBronze: game?.stakeBronze ?? 2,
          );
      if (!mounted) return;
      clearBlockingGamePin(ref);
      final gameId = created.gameId?.trim() ?? '';
      if (gameId.isNotEmpty) {
        _openRematch(gameId, created.lobbyId);
        return;
      }
      context.go('/games/domino/lobby/${created.lobbyId}?mode=matchmake');
    } catch (_) {
      if (mounted) context.go('/games');
    } finally {
      if (mounted) setState(() => _isFindingGame = false);
    }
  }

  void _showRules(DominoGameView? game) {
    showGameRulesDialog(
      context: context,
      content: rulesTextLines(dominoRuleLines(
        players: game?.players.length ?? 2,
        turnTimeSec: game?.turnTimeSec ?? 0,
        stakeBronze: _isOffline ? 0 : (game?.stakeBronze ?? 0),
        offlineBot: _isOffline,
        l10n: context.l10n,
      )),
      closeLabel: context.l10n.commonClose,
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncGame = ref.watch(dominoGameProvider(widget.gameId));
    ref.listen(dominoGameProvider(widget.gameId), (_, next) {
      final game = next.valueOrNull;
      if (game != null) _maybeSettle(game);
    });
    final game = asyncGame.valueOrNull;
    if (game != null && game.turnDeadline > 0 && game.isMyTurn) {
      _expiredSent = false;
    }
    final narrow = isNarrow(context);
    final reward = game == null ? 0 : _netProfit(game);
    final showReward = game != null &&
        stakeShowFinishReward(
          stakeBronze: _isOffline ? 0 : game.stakeBronze,
          isOver: game.isOver,
          isDraw: game.isDraw,
          rewardChip: game.iWon
              ? reward
              : stakeFinishRewardChip(
                  stakeBronze: game.stakeBronze,
                  isDraw: game.isDraw,
                  iWon: false,
                ),
        );
    final chip = game == null
        ? 0
        : game.iWon
            ? reward
            : stakeFinishRewardChip(
                stakeBronze: _isOffline ? 0 : game.stakeBronze,
                isDraw: game.isDraw,
                iWon: false,
              );
    return SwipeBackScope(
      onBack: _onClose,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          toolbarHeight: gameToolbarHeight(context),
          leading: IconButton(
            tooltip: context.l10n.commonClose,
            onPressed: _onClose,
            icon: const Icon(Icons.close_rounded),
          ),
          title: game == null
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    GameStatusWithReward(
                      statusText: _status(game),
                      showReward: showReward,
                      rewardBronze: chip,
                      rewardKey: _rewardKey,
                      fontSize: narrow ? 15 : 17,
                    ),
                    Text(
                      context.l10n.unoRoundProgress(game.round, game.targetScore),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
          actions: [
            if (game != null && game.turnDeadline > 0 && game.isPlaying)
              GameTurnCountdown(
                turnDeadline: game.turnDeadline,
                isMyTurn: game.isMyTurn,
                turnTimeSec: game.turnTimeSec,
                onExpired: _onTurnExpired,
                labelBuilder: context.l10n.gameSecondsLeft,
              ),
            IconButton(
              tooltip: context.l10n.gamesRulesTitle,
              onPressed: () => _showRules(game),
              icon: const Icon(Icons.rule_rounded),
            ),
            if (game != null && !_isOffline && !game.isOver)
              GameActionsOverlay(
                canDraw: false,
                iOfferedDraw: false,
                opponentOfferedDraw: false,
                onSurrender: () => unawaited(_move(dominoActionForfeit)),
                onDraw: () {},
                surrenderTooltip: context.l10n.gameSurrender,
                drawTooltip: '',
                acceptDrawTooltip: '',
                drawOfferedTooltip: '',
              ),
          ],
        ),
        body: GradientBackground(
          child: asyncGame.when(
            skipLoadingOnReload: true,
            data: (value) => _body(value),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accentStart),
            ),
            error: (error, _) => Center(
              child: Text(
                formatUserError(error),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(DominoGameView game) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(isNarrow(context) ? 8 : 16, 0, isNarrow(context) ? 8 : 16, 8),
          child: Column(
            children: [
              Expanded(
                child: DominoTable(
                  view: game,
                  busy: _busy,
                  onPlay: (move) => unawaited(
                    _move(dominoActionPlay, tile: move.tile, end: move.end),
                  ),
                ),
              ),
              _actions(game),
            ],
          ),
        ),
        if (game.iWon) const Positioned.fill(child: GameConfettiOverlay()),
      ],
    );
  }

  Widget _actions(DominoGameView game) {
    if (game.isOver) {
      if (_isOffline) {
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FilledButton.icon(
            onPressed: () {
              OfflineDominoRegistry.instance.get(widget.gameId)?.restart();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.offlinePlayAgain),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: GameRematchSection(
          rematchLobbyId: _rematchLobbyId,
          rematchDeclined: _rematchDeclined,
          iDeclinedRematch: _iDeclinedRematch,
          isRematching: _isRematching,
          isAcceptingRematch: _isAcceptingRematch,
          isFindingGame: _isFindingGame,
          peerIds: _peerIds(game),
          invites: ref.watch(gameInvitesProvider),
          onRematch: () => unawaited(_rematch()),
          onAccept: (lobbyId) => unawaited(_acceptRematch(lobbyId)),
          onDecline: (lobbyId) => unawaited(_declineRematch(lobbyId)),
          onCancelWait: () => unawaited(_cancelRematchWait()),
          onFindGame: () => unawaited(_findGame()),
          compact: true,
          table: RematchTable(
            gameType: 'domino',
            stakeBronze: game.stakeBronze,
            gameMode: 'kozel',
          ),
        ),
      );
    }
    if (!game.canDraw && !game.canPass) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          if (game.canDraw)
            FilledButton.icon(
              onPressed: _busy ? null : () => unawaited(_move(dominoActionDraw)),
              icon: const Icon(Icons.style_rounded),
              label: Text(context.l10n.durakActionTake),
            ),
          if (game.canPass)
            OutlinedButton.icon(
              onPressed: _busy ? null : () => unawaited(_move(dominoActionPass)),
              icon: const Icon(Icons.skip_next_rounded),
              label: Text(context.l10n.durakActionPass),
            ),
        ],
      ),
    );
  }
}
