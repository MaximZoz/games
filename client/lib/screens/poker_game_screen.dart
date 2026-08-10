import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException;
import 'package:multigames_client/games/poker/poker_offline_engine.dart'
    show PokerActionType, PokerStreet;
import 'package:multigames_client/games/poker/poker_offline_session.dart';
import 'package:multigames_client/games/poker/poker_provider.dart';
import 'package:multigames_client/games/poker/poker_repository.dart';
import 'package:multigames_client/games/poker/poker_rules.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/utils/user_error.dart';

/// Экран партии Texas Hold'em — общий для онлайна и офлайна.
///
/// Стол-овал с местами по кругу, борды и банк в центре, свои карманные карты
/// внизу, панель действий (Фолд / Чек-Колл / Рейз / Ва-банк) в свой ход.
class PokerGameScreen extends ConsumerStatefulWidget {
  const PokerGameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  ConsumerState<PokerGameScreen> createState() => _PokerGameScreenState();
}

class _PokerGameScreenState extends ConsumerState<PokerGameScreen> {
  bool _busy = false;
  bool _providerBindingsInitialized = false;
  bool _isRematching = false;
  bool _isAcceptingRematch = false;
  String? _rematchLobbyId;
  bool _rematchDeclined = false;
  bool _iDeclinedRematch = false;
  bool _isFindingGame = false;
  bool _prevOver = false;

  bool get _isOffline =>
      OfflinePokerRegistry.instance.isOffline(widget.gameId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeProviderBindings();
  }

  @override
  void didUpdateWidget(covariant PokerGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId) {
      setState(() {
        _rematchLobbyId = null;
        _rematchDeclined = false;
        _iDeclinedRematch = false;
        _isRematching = false;
        _isAcceptingRematch = false;
        _isFindingGame = false;
        _prevOver = false;
      });
    }
  }

  void _initializeProviderBindings() {
    if (_providerBindingsInitialized) return;
    _providerBindingsInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isOffline) return;
      final known = ref.read(pokerGameProvider(widget.gameId)).valueOrNull;
      if (known != null && known.isOver) {
        _clearSessionForFinishedGame();
      } else {
        pinBlockingGame(ref, widget.gameId, gameType: 'poker');
        final prev = ref.read(activeGameProvider).valueOrNull;
        if (prev?.gameId != widget.gameId) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: widget.gameId,
                  lobbyId: prev?.lobbyId,
                  gameType: 'poker',
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

  // ---- helpers ------------------------------------------------------------

  String _streetLabel(String street) {
    final l10n = context.l10n;
    switch (street) {
      case PokerStreet.preflop:
        return l10n.pokerStreetPreflop;
      case PokerStreet.flop:
        return l10n.pokerStreetFlop;
      case PokerStreet.turn:
        return l10n.pokerStreetTurn;
      case PokerStreet.river:
        return l10n.pokerStreetRiver;
      case PokerStreet.showdown:
        return l10n.pokerStreetShowdown;
      default:
        return '';
    }
  }

  String _playerName(PokerPlayerView p) {
    final n = p.displayName?.trim() ?? '';
    if (n.isNotEmpty) return n;
    return p.isBot ? context.l10n.gameBot : context.l10n.gameOpponent;
  }

  String _statusText(PokerGameView game) {
    final l10n = context.l10n;
    if (game.isOver) {
      final me = game.myIndex;
      if (me >= 0 && game.winners.contains(me)) return l10n.pokerYouWonHand;
      if (game.winners.isNotEmpty) {
        final w = game.winners.first;
        if (w >= 0 && w < game.players.length) {
          return l10n.pokerWinner(_playerName(game.players[w]));
        }
      }
      return l10n.pokerHandOver;
    }
    if (game.isMyTurn) return l10n.pokerYourTurn;
    final acting = game.actingIndex;
    if (acting >= 0 && acting < game.players.length) {
      return l10n.pokerToAct(_playerName(game.players[acting]));
    }
    return '';
  }

  // ---- moves --------------------------------------------------------------

  Future<void> _move(String type, {int? amount}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(pokerRepositoryProvider)
          .move(widget.gameId, type: type, amount: amount);
      if (!_isOffline && mounted) {
        ref.invalidate(pokerGameProvider(widget.gameId));
      }
    } on GamesException catch (e) {
      if (mounted) {
        showAppSnackBar(context,
            message: formatUserError(e), kind: AppSnackKind.error);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context,
            message: formatUserError(e), kind: AppSnackKind.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openRaiseSheet(PokerGameView game) async {
    final minTo = game.minRaiseTo;
    final maxTo = game.maxRaiseTo;
    if (maxTo <= 0) return;
    if (minTo >= maxTo) {
      // Единственный вариант — ва-банк.
      await _move(PokerActionType.allIn);
      return;
    }
    final step = game.bigBlind > 0 ? game.bigBlind : 1;
    var value = minTo;
    final chosen = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final divisions = math.max(1, ((maxTo - minTo) / step).ceil());
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GradientCard(
                  animate: false,
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        ctx.l10n.pokerRaiseTitle,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ctx.l10n.pokerRaiseTo(value),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.accentStart,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Slider(
                        min: minTo.toDouble(),
                        max: maxTo.toDouble(),
                        divisions: divisions,
                        value: value.toDouble().clamp(
                              minTo.toDouble(),
                              maxTo.toDouble(),
                            ),
                        activeColor: AppColors.accentStart,
                        label: '$value',
                        onChanged: (v) => setSheet(() {
                          final snapped = (v / step).round() * step;
                          value = snapped.clamp(minTo, maxTo);
                        }),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$minTo',
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                          Text('$maxTo',
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: Text(ctx.l10n.commonCancel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(value),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accentStart,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(ctx.l10n.pokerRaise),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (chosen == null || !mounted) return;
    if (chosen >= maxTo) {
      await _move(PokerActionType.allIn);
    } else {
      await _move(PokerActionType.raise, amount: chosen);
    }
  }

  // ---- close / surrender / rematch ---------------------------------------

  Future<void> _confirmSurrender() async {
    final game = ref.read(pokerGameProvider(widget.gameId)).valueOrNull;
    if (game == null || game.isOver) return;
    final ok = await confirmGameActionDialog(
      context: context,
      title: context.l10n.gameSurrenderTitle,
      message: context.l10n.gameSurrenderConfirm,
      cancelLabel: context.l10n.gameStay,
      confirmLabel: context.l10n.gameSurrender,
    );
    if (!ok || !mounted) return;
    try {
      clearBlockingGamePin(ref, ifGameId: widget.gameId);
      await ref.read(pokerRepositoryProvider).forfeit(widget.gameId);
    } catch (_) {}
    if (!mounted) return;
    if (!_isOffline) ref.invalidate(pokerGameProvider(widget.gameId));
    unawaited(ref.read(activeGameProvider.notifier).refresh());
  }

  Future<void> _onClosePressed() async {
    final game = ref.read(pokerGameProvider(widget.gameId)).valueOrNull;
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
          await ref.read(pokerRepositoryProvider).forfeit(widget.gameId);
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
    _clearSessionForFinishedGame();
    context.go('/games');
    if (rematchLobbyId != null) {
      unawaited(
        ref
            .read(pokerRepositoryProvider)
            .leaveLobby(rematchLobbyId)
            .catchError((_) {}),
      );
    }
  }

  Future<void> _rematch() async {
    setState(() => _isRematching = true);
    try {
      if (_isOffline) {
        final session = OfflinePokerRegistry.instance.get(widget.gameId);
        if (session != null) {
          session.restart();
          ref.invalidate(pokerGameProvider(widget.gameId));
          if (mounted) setState(() => _isRematching = false);
          return;
        }
      }
      final lobbyId =
          await ref.read(pokerRepositoryProvider).rematch(widget.gameId);
      if (!mounted) return;
      clearBlockingGamePin(ref);
      if (lobbyId.isEmpty) {
        setState(() => _isRematching = false);
        return;
      }
      ref.read(activeGameProvider.notifier).setLocal(
            ActiveGameItem(
              type: 'lobby',
              lobbyId: lobbyId,
              gameType: 'poker',
            ),
          );
      setState(() {
        _rematchLobbyId = lobbyId;
        _rematchDeclined = false;
        _iDeclinedRematch = false;
        _isRematching = false;
      });
      context.go('/games/poker/lobby/$lobbyId?mode=invite');
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
          await ref.read(pokerRepositoryProvider).joinLobby(lobbyId);
      if (!mounted) return;
      clearBlockingGamePin(ref);
      if (result.gameId != null && result.gameId!.isNotEmpty) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'game',
                gameId: result.gameId,
                lobbyId: lobbyId,
                gameType: 'poker',
              ),
            );
        pinBlockingGame(ref, result.gameId, gameType: 'poker');
        context.go('/games/poker/game/${result.gameId}');
      } else {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'lobby',
                lobbyId: lobbyId,
                gameType: 'poker',
              ),
            );
        context.go('/games/poker/lobby/$lobbyId?mode=invite');
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
      await ref.read(pokerRepositoryProvider).declineLobby(lobbyId);
    } catch (_) {}
    if (mounted) setState(() => _iDeclinedRematch = true);
  }

  Future<void> _cancelRematchWait() async {
    if (_rematchLobbyId == null) return;
    final lobbyId = _rematchLobbyId!;
    setState(() => _rematchLobbyId = null);
    try {
      await ref.read(pokerRepositoryProvider).leaveLobby(lobbyId);
    } catch (_) {}
  }

  Future<void> _findGame() async {
    setState(() => _isFindingGame = true);
    try {
      final rematchId = _rematchLobbyId;
      if (rematchId != null) {
        setState(() => _rematchLobbyId = null);
        unawaited(
          ref
              .read(pokerRepositoryProvider)
              .leaveLobby(rematchId)
              .catchError((_) {}),
        );
      }
      final game = ref.read(pokerGameProvider(widget.gameId)).valueOrNull;
      final created = await ref.read(pokerRepositoryProvider).createLobby(
            mode: 'matchmake',
            maxPlayers: game?.playerIds.length ?? 2,
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
                gameType: 'poker',
              ),
            );
        pinBlockingGame(ref, created.gameId, gameType: 'poker');
        context.go('/games/poker/game/${created.gameId}');
        return;
      }
      ref.read(activeGameProvider.notifier).setLocal(
            ActiveGameItem(
              type: 'lobby',
              lobbyId: created.lobbyId,
              gameType: 'poker',
            ),
          );
      context.go('/games/poker/lobby/${created.lobbyId}?mode=matchmake');
    } catch (_) {
      if (mounted) context.go('/games');
    } finally {
      if (mounted) setState(() => _isFindingGame = false);
    }
  }

  List<String> _peerIds(PokerGameView game) {
    final me = game.myIndex;
    return [
      for (var i = 0; i < game.players.length; i++)
        if (i != me && !game.players[i].isBot) game.players[i].id,
    ];
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(pokerGameProvider(widget.gameId));
    final narrow = isNarrow(context);

    ref.listen(pokerGameProvider(widget.gameId), (_, next) {
      final game = next.valueOrNull;
      if (game == null) return;
      if (game.isOver && !_prevOver) {
        _prevOver = true;
        if (!_isOffline) {
          _clearSessionForFinishedGame();
          unawaited(ref.read(authStateProvider.notifier).refresh());
        }
      } else if (!game.isOver) {
        _prevOver = false;
      }
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
          title: Text(context.l10n.gamesPoker),
          centerTitle: true,
          actions: [
            if (gameAsync.valueOrNull != null &&
                !gameAsync.valueOrNull!.isOver)
              IconButton(
                tooltip: context.l10n.gameSurrender,
                icon: const Icon(Icons.flag_outlined),
                onPressed: () => unawaited(_confirmSurrender()),
              ),
            IconButton(
              tooltip: context.l10n.gamesRulesTitle,
              icon: const Icon(Icons.rule_rounded),
              onPressed: () {
                final game = gameAsync.valueOrNull;
                showGameRulesDialog(
                  context: context,
                  title: context.l10n.gamesRulesTitle,
                  content: rulesTextLines(pokerRuleLines(
                    players: game?.playerIds.length ?? 2,
                    turnTimeSec: game?.turnTimeSec ?? 0,
                    stakeBronze: game?.stakeBronze ?? 0,
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
            child: gameAsync.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              data: (game) => _buildContent(game, narrow),
              loading: () => const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accentStart),
              ),
              error: (e, _) => Center(
                child: Text(
                  formatUserError(e, fallback: context.l10n.commonServerErrorShort),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(PokerGameView game, bool narrow) {
    final isOver = game.isOver;
    final status = _statusText(game);
    final showTimer = !isOver &&
        game.isMyTurn &&
        game.turnTimeSec > 0 &&
        game.turnDeadline > 0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 4, narrow ? 12 : 20, 0),
          child: Column(
            children: [
              Text(
                _streetLabel(game.street),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              if (status.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: GameStatusLine(
                    text: status,
                    highlight: game.isMyTurn && !isOver,
                  ),
                ),
              if (showTimer)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: GameTurnCountdown(
                    key: ValueKey('${game.actingIndex}_${game.turnDeadline}'),
                    turnDeadline: game.turnDeadline,
                    isMyTurn: game.isMyTurn,
                    turnTimeSec: game.turnTimeSec,
                    onExpired: () {
                      if (!_isOffline) {
                        ref.invalidate(pokerGameProvider(widget.gameId));
                      }
                    },
                    labelBuilder: (s) => context.l10n.gameSecondsLeft(s),
                  ),
                ),
            ],
          ),
        ),
        if (isOver) _buildEndSection(game),
        Expanded(child: _buildTable(game, narrow)),
        _buildHeroArea(game, narrow),
      ],
    );
  }

  Widget _buildEndSection(PokerGameView game) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _isOffline
          ? FilledButton.icon(
              onPressed: _isRematching ? null : () => unawaited(_rematch()),
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: Text(context.l10n.offlinePlayAgain),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentStart,
                foregroundColor: Colors.white,
              ),
            )
          : GameRematchSection(
              rematchLobbyId: _rematchLobbyId,
              rematchDeclined: _rematchDeclined,
              iDeclinedRematch: _iDeclinedRematch,
              isRematching: _isRematching,
              isAcceptingRematch: _isAcceptingRematch,
              isFindingGame: _isFindingGame,
              peerIds: _peerIds(game),
              invites: ref.watch(gameInvitesProvider),
              onRematch: () => unawaited(_rematch()),
              onAccept: (id) => unawaited(_acceptRematch(id)),
              onDecline: (id) => unawaited(_declineRematch(id)),
              onCancelWait: () => unawaited(_cancelRematchWait()),
              onFindGame: () => unawaited(_findGame()),
              compact: true,
            ),
    );
  }

  /// Овальный стол: соперники по дуге сверху, банк и борд в центре.
  Widget _buildTable(PokerGameView game, bool narrow) {
    final me = game.myIndex;
    final opponents = <PokerPlayerView>[];
    for (var i = 0; i < game.players.length; i++) {
      if (i == me) continue;
      opponents.add(game.players[i]);
    }
    final anchors = _seatAnchors(opponents.length);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Фетр-стол.
            Center(
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: narrow ? 14 : 40,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(160),
                  gradient: const RadialGradient(
                    colors: [Color(0xFF1F7A4D), Color(0xFF135C39)],
                    radius: 0.9,
                  ),
                  border: Border.all(
                    color: const Color(0xFF0C3D26),
                    width: 6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
            ),
            // Банк + борд по центру.
            Align(
              alignment: const Alignment(0, 0.05),
              child: _buildCenter(game, narrow),
            ),
            // Соперники.
            for (var i = 0; i < opponents.length; i++)
              Align(
                alignment: anchors[i],
                child: _buildSeat(game, opponents[i], narrow),
              ),
          ],
        );
      },
    );
  }

  List<Alignment> _seatAnchors(int n) {
    switch (n) {
      case 0:
        return const [];
      case 1:
        return const [Alignment(0, -1)];
      case 2:
        return const [Alignment(-0.8, -0.85), Alignment(0.8, -0.85)];
      case 3:
        return const [
          Alignment(-0.98, -0.15),
          Alignment(0, -1),
          Alignment(0.98, -0.15),
        ];
      case 4:
        return const [
          Alignment(-0.98, -0.1),
          Alignment(-0.6, -1),
          Alignment(0.6, -1),
          Alignment(0.98, -0.1),
        ];
      default:
        return const [
          Alignment(-0.98, -0.05),
          Alignment(-0.7, -1),
          Alignment(0, -1),
          Alignment(0.7, -1),
          Alignment(0.98, -0.05),
        ];
    }
  }

  Widget _buildCenter(PokerGameView game, bool narrow) {
    final cardSize = narrow ? const Size(34, 50) : const Size(44, 64);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            context.l10n.pokerPot(game.pot),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: i < game.community.length
                    ? PlayingCardWidget(
                        card: game.community[i].toPlayingCard(),
                        size: cardSize,
                        animate: false,
                      )
                    : _emptyCardSlot(cardSize),
              ),
          ],
        ),
      ],
    );
  }

  Widget _emptyCardSlot(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(size.width * 0.15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
    );
  }

  Widget _buildSeat(PokerGameView game, PokerPlayerView p, bool narrow) {
    final isDealer = p.seat == game.dealerIndex;
    final acting = p.isActing && !game.isOver;
    final cardSize = narrow ? const Size(26, 38) : const Size(30, 44);
    final showHole = p.holeCards != null && p.holeCards!.isNotEmpty;

    return Container(
      width: narrow ? 120 : 138,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: acting ? 0.5 : 0.32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: acting
              ? AppColors.accentStart
              : Colors.white.withValues(alpha: 0.08),
          width: acting ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Карманные карты соперника (рубашки или вскрытые).
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 2; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: p.folded
                      ? Opacity(
                          opacity: 0.35,
                          child: CardBackWidget(size: cardSize, outlined: true),
                        )
                      : showHole
                          ? PlayingCardWidget(
                              card: p.holeCards![i].toPlayingCard(),
                              size: cardSize,
                              animate: false,
                            )
                          : CardBackWidget(size: cardSize, outlined: true),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GamePlayerAvatar(
                displayName: _playerName(p),
                avatarKind: p.avatarKind,
                avatarValue: p.avatarValue,
                frameCode: p.frameCode,
                frameColor: p.frameColor,
                compact: true,
              ),
              if (isDealer) ...[
                const SizedBox(width: 4),
                _dealerBadge(),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _playerName(p),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            p.folded
                ? context.l10n.pokerFolded
                : p.allIn
                    ? context.l10n.pokerAllInBadge
                    : '${p.chips}',
            style: TextStyle(
              color: p.allIn
                  ? const Color(0xFFFBBF24)
                  : Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (p.bet > 0) _betChip(p.bet),
        ],
      ),
    );
  }

  Widget _dealerBadge() {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Text(
        'D',
        style: TextStyle(
          color: Color(0xFF135C39),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _betChip(int amount) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.accentStart.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$amount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// Свои карты + панель действий.
  Widget _buildHeroArea(PokerGameView game, bool narrow) {
    final me = game.me;
    final heroCards = narrow ? const Size(54, 78) : const Size(64, 92);
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 4, 12, narrow ? 8 : 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (me != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (me.holeCards != null)
                  for (final c in me.holeCards!)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: PlayingCardWidget(
                        card: c.toPlayingCard(),
                        size: heroCards,
                        animate: false,
                      ),
                    ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _dealerHeroBadge(game),
                        Text(
                          '${me.chips}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    if (me.bet > 0)
                      Text(
                        '+${me.bet}',
                        style: const TextStyle(
                          color: AppColors.accentStart,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (!game.isOver && game.isMyTurn) _buildActionBar(game),
        ],
      ),
    );
  }

  Widget _dealerHeroBadge(PokerGameView game) {
    final me = game.myIndex;
    if (me < 0 || me >= game.players.length) return const SizedBox.shrink();
    if (game.players[me].seat != game.dealerIndex) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: _dealerBadge(),
    );
  }

  Widget _buildActionBar(PokerGameView game) {
    final canFold = game.canDo(PokerActionType.fold);
    final canCheck = game.canDo(PokerActionType.check);
    final canCall = game.canDo(PokerActionType.call);
    final canRaise = game.canDo(PokerActionType.raise);
    final canAllIn = game.canDo(PokerActionType.allIn);
    final l10n = context.l10n;

    final buttons = <Widget>[
      if (canFold)
        _actionButton(
          label: l10n.pokerFold,
          color: const Color(0xFFB0384A),
          onTap: _busy ? null : () => unawaited(_move(PokerActionType.fold)),
        ),
      if (canCheck)
        _actionButton(
          label: l10n.pokerCheck,
          color: const Color(0xFF3E7CB1),
          onTap: _busy ? null : () => unawaited(_move(PokerActionType.check)),
        ),
      if (canCall)
        _actionButton(
          label: game.callAmount > 0
              ? l10n.pokerCall(game.callAmount)
              : l10n.pokerCallShort,
          color: const Color(0xFF3E7CB1),
          onTap: _busy ? null : () => unawaited(_move(PokerActionType.call)),
        ),
      if (canRaise)
        _actionButton(
          label: l10n.pokerRaise,
          color: AppColors.accentStart,
          onTap: _busy ? null : () => unawaited(_openRaiseSheet(game)),
        ),
      if (canAllIn)
        _actionButton(
          label: l10n.pokerAllIn,
          color: const Color(0xFFC9782B),
          onTap: _busy ? null : () => unawaited(_move(PokerActionType.allIn)),
        ),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: buttons,
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}
