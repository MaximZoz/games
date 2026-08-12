import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/game_stake.dart';
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
import 'package:multigames_client/ui/durak/card_fly.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';
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

class _PokerGameScreenState extends ConsumerState<PokerGameScreen>
    with TickerProviderStateMixin {
  bool _busy = false;
  bool _providerBindingsInitialized = false;
  bool _isRematching = false;
  bool _isAcceptingRematch = false;
  String? _rematchLobbyId;
  bool _rematchDeclined = false;
  bool _iDeclinedRematch = false;
  bool _isFindingGame = false;
  bool _prevOver = false;
  bool _balanceGainPlayed = false;
  bool _lossChipRevealed = false;
  final GlobalKey _winRewardKey = GlobalKey();

  // ---- анимация появления борда + полёт фишек ----
  /// Цель анимации фишек — стопка под общими картами (не бейдж «Банк»).
  final GlobalKey _tableChipsKey = GlobalKey();
  final Map<int, GlobalKey> _seatKeys = {};
  int _shownCommunity = 0; // сколько карт борда уже показано
  int _dealHand = -1; // номер раздачи, чей борд сейчас отслеживаем
  bool _dealing = false;
  bool _disposed = false;
  int _prevHandNumber = -1;
  bool _prevHandOver = false;
  int _prevPot = -1;
  final Map<int, int> _prevBets = {};
  final Map<int, bool> _prevFolded = {};
  int _foldHand = -1;
  final List<AnimationController> _chipControllers = [];
  /// Места, для которых уже запустили optimistic-полёт фишек (колл/рейз).
  final Set<int> _optimisticChipSeats = {};

  bool get _isOffline =>
      OfflinePokerRegistry.instance.isOffline(widget.gameId);

  @override
  void dispose() {
    _disposed = true;
    for (final c in _chipControllers) {
      c.dispose();
    }
    _chipControllers.clear();
    super.dispose();
  }

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
        _balanceGainPlayed = false;
        _lossChipRevealed = false;
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
    final me = game.myIndex;
    final iWon = me >= 0 && game.winners.contains(me);
    // Весь стол окончен — как в дураке / крестиках.
    if (game.isOver) {
      if (iWon) {
        if (game.isForfeit) return l10n.gameYouWonOpponentForfeit;
        if (game.isTimeout) return l10n.gameYouWonOpponentTimeout;
        return l10n.gameYouWon;
      }
      if (game.stakeBronze > 0) return l10n.gameYouLost;
      if (game.winners.isNotEmpty) {
        final w = game.winners.first;
        if (w >= 0 && w < game.players.length) {
          return l10n.pokerWinner(_playerName(game.players[w]));
        }
      }
      return l10n.pokerHandOver;
    }
    // Раздача завершена, стол продолжается.
    if (game.isHandOver) {
      if (iWon) return l10n.pokerYouWonHand;
      if (game.winners.isNotEmpty) {
        final w = game.winners.first;
        if (w >= 0 && w < game.players.length) {
          return l10n.pokerWinner(_playerName(game.players[w]));
        }
      }
      return l10n.pokerHandOver;
    }
    final acting = game.actingIndex;
    // Свой индекс актёра — всегда «Ваш ход», даже если legalActions ещё пусты.
    if (!game.isOver &&
        !game.isHandOver &&
        game.myIndex >= 0 &&
        acting == game.myIndex) {
      return l10n.pokerYourTurn;
    }
    if (acting >= 0 && acting < game.players.length) {
      return l10n.pokerToAct(_playerName(game.players[acting]));
    }
    return '';
  }

  int _rewardChipBronze(PokerGameView game) {
    if (!game.isOver || game.stakeBronze <= 0) return 0;
    final me = game.myIndex;
    final iWon = me >= 0 && game.winners.contains(me);
    if (iWon) {
      return stakeWinnerNetProfit(
        stake: game.stakeBronze,
        playerCount: game.players.length.clamp(2, 9),
        winnerCount: game.winners.isEmpty ? 1 : game.winners.length,
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

  void _maybeSettleGame(PokerGameView game) {
    if (!game.isOver) return;
    if (_balanceGainPlayed || _isOffline) return;
    // Сразу, чтобы повторные build не ставили анимацию в очередь дважды.
    _balanceGainPlayed = true;
    if (game.stakeBronze <= 0) {
      unawaited(ref.read(authStateProvider.notifier).refresh());
      return;
    }
    final me = game.myIndex;
    final iWon = me >= 0 && game.winners.contains(me);
    final n = game.players.length.clamp(2, 9);
    final winnersN = game.winners.isEmpty ? 1 : game.winners.length;
    final pot = stakeWinnerCredit(
      stake: game.stakeBronze,
      playerCount: n,
      winnerCount: winnersN,
    );
    final net = stakeWinnerNetProfit(
      stake: game.stakeBronze,
      playerCount: n,
      winnerCount: winnersN,
    );
    final credit = iWon ? pot : 0;
    final display = iWon ? net : 0;
    final lost = (!iWon && game.stakeBronze > 0) ? game.stakeBronze : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Сбрасываем флаг: _onGameSettled снова выставит его сам.
      _balanceGainPlayed = false;
      unawaited(_onGameSettled(
        creditBronze: credit,
        displayRewardBronze: display,
        lostBronze: lost,
      ));
    });
  }

  /// Локализованное название комбинации по каноническому имени ранга сервера.
  String? _handRankLabel(String? rank) {
    if (rank == null || rank.isEmpty) return null;
    final l10n = context.l10n;
    switch (rank) {
      case 'HighCard':
        return l10n.pokerHandHighCard;
      case 'OnePair':
        return l10n.pokerHandOnePair;
      case 'TwoPair':
        return l10n.pokerHandTwoPair;
      case 'ThreeOfAKind':
        return l10n.pokerHandThreeOfAKind;
      case 'Straight':
        return l10n.pokerHandStraight;
      case 'Flush':
        return l10n.pokerHandFlush;
      case 'FullHouse':
        return l10n.pokerHandFullHouse;
      case 'FourOfAKind':
        return l10n.pokerHandFourOfAKind;
      case 'StraightFlush':
        return l10n.pokerHandStraightFlush;
      case 'RoyalFlush':
        return l10n.pokerHandRoyalFlush;
      default:
        return null;
    }
  }

  // ---- moves --------------------------------------------------------------

  Future<void> _move(String type, {int? amount}) async {
    if (_busy) return;
    // Сразу «подкидываем» монеты в банк — не ждём ответ (колл часто
    // закрывает улицу и bet в снапшоте уже 0).
    if (type == PokerActionType.call ||
        type == PokerActionType.raise ||
        type == PokerActionType.allIn) {
      final game = ref.read(pokerGameProvider(widget.gameId)).valueOrNull ??
          (_isOffline
              ? OfflinePokerRegistry.instance.get(widget.gameId)?.view
              : null);
      final me = game?.me;
      if (me != null) {
        _optimisticChipSeats.add(me.seat);
        unawaited(
          _flyChips(fromKey: _seatKey(me.seat), toKey: _tableChipsKey),
        );
      }
    }
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
          _maybeSettleGame(game);
        }
      } else if (!game.isOver) {
        _prevOver = false;
        _balanceGainPlayed = false;
        _lossChipRevealed = false;
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
    _syncDeal(game);
    _syncChipFx(game);
    _syncFoldFx(game);
    if (game.isOver && !_balanceGainPlayed && !_isOffline) {
      _maybeSettleGame(game);
    }
    final isOver = game.isOver;
    final status = _statusText(game);
    final rewardBronze = _rewardChipBronze(game);
    final showReward =
        isOver && game.stakeBronze > 0 && rewardBronze != 0;
    final betweenHands = game.isHandOver && !isOver;

    const comboSlot = 30.0;
    const actionSlot = 52.0;
    final bottomPad = narrow ? 6.0 : 10.0;
    final showActions = !isOver &&
        !game.isHandOver &&
        game.isMyTurn &&
        game.legalActions.isNotEmpty;
    final showCardsBtn = game.canShowCards && !isOver;
    final hasCombo = _handRankLabel(game.myHandRank) != null;
    // Hero выезжает вверх только когда есть кнопки; поле/борд не двигаются.
    final heroLift = showActions || showCardsBtn
        ? comboSlot + 6 + actionSlot + bottomPad
        : (hasCombo ? comboSlot + bottomPad : bottomPad);

    return LayoutBuilder(
      builder: (context, constraints) {
        final short = constraints.maxHeight < 560;
        final veryShort = constraints.maxHeight < 480;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _buildTable(
                game,
                narrow,
                short: short,
                veryShort: veryShort,
                status: status,
                showReward: showReward,
                rewardBronze: rewardBronze,
                betweenHands: betweenHands,
                // Hero отдельно анимируется снизу — стол/борд фиксированы.
                heroBottom: isOver ? 12.0 : heroLift,
              ),
            ),
            if (isOver)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.42),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        narrow ? 16 : 28,
                        24,
                        narrow ? 16 : 28,
                        bottomPad + 8,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: GradientCard(
                          animate: false,
                          margin: EdgeInsets.zero,
                          padding: EdgeInsets.fromLTRB(
                            narrow ? 16 : 20,
                            18,
                            narrow ? 16 : 20,
                            16,
                          ),
                          child: _buildEndSection(game),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomBar(game, narrow),
              ),
          ],
        );
      },
    );
  }

  // ---- появление карт борда (fade/scale, без колоды) ---------------------

  /// Показывает новые общие карты по одной с короткой задержкой.
  void _syncDeal(PokerGameView game) {
    final len = game.community.length;
    if (game.handNumber != _dealHand || len < _shownCommunity) {
      _dealHand = game.handNumber;
      _shownCommunity = 0;
      _dealing = false;
    }
    if (len <= _shownCommunity || _dealing) return;
    _dealing = true;
    unawaited(_revealCommunity(len));
  }

  Future<void> _revealCommunity(int to) async {
    while (_shownCommunity < to) {
      if (!mounted || _disposed) {
        _dealing = false;
        return;
      }
      await Future<void>.delayed(
        Duration(milliseconds: _shownCommunity == 0 ? 30 : 95),
      );
      if (!mounted || _disposed) {
        _dealing = false;
        return;
      }
      setState(() => _shownCommunity++);
    }
    _dealing = false;
  }

  Future<void> _showPlayerCard(PokerPlayerView p) async {
    if (!mounted) return;
    if (p.isBot) {
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: GradientCard(
              animate: false,
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GamePlayerAvatar(
                    displayName: _playerName(p),
                    avatarKind: p.avatarKind,
                    avatarValue: p.avatarValue,
                    frameCode: p.frameCode,
                    frameColor: p.frameColor,
                    compact: false,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _playerName(p),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${p.chips}',
                    style: const TextStyle(
                      color: AppColors.accentStart,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(context.l10n.commonClose),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }
    await showUserProfileDialog(
      context: context,
      ref: ref,
      userId: p.id,
      displayName: _playerName(p),
      avatarKind: p.avatarKind,
      avatarValue: p.avatarValue,
      frameCode: p.frameCode,
      frameColor: p.frameColor,
      messageFrom: 'games',
      messageReturnPath: '/games/poker/game/${widget.gameId}',
    );
  }

  Widget _buildEndSection(PokerGameView game) {
    if (_isOffline) {
      return FilledButton.icon(
        onPressed: _isRematching ? null : () => unawaited(_rematch()),
        icon: const Icon(Icons.replay_rounded, size: 18),
        label: Text(context.l10n.offlinePlayAgain),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentStart,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 44),
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
      peerIds: _peerIds(game),
      invites: ref.watch(gameInvitesProvider),
      onRematch: () => unawaited(_rematch()),
      onAccept: (id) => unawaited(_acceptRematch(id)),
      onDecline: (id) => unawaited(_declineRematch(id)),
      onCancelWait: () => unawaited(_cancelRematchWait()),
      onFindGame: () => unawaited(_findGame()),
      compact: true,
    );
  }

  /// Овальный стол: аватары на кромке, борд фиксирован; hero выезжает снизу.
  Widget _buildTable(
    PokerGameView game,
    bool narrow, {
    bool short = false,
    bool veryShort = false,
    required String status,
    required bool showReward,
    required int rewardBronze,
    required bool betweenHands,
    required double heroBottom,
  }) {
    final me = game.myIndex;
    final opponents = <PokerPlayerView>[];
    for (var i = 0; i < game.players.length; i++) {
      if (i == me) continue;
      opponents.add(game.players[i]);
    }
    final oppAnchors = _seatAnchors(opponents.length);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardSize = _communityCardSize(
          constraints.maxWidth,
          narrow,
          short: short || veryShort,
        );
        final dealerSeat = game.dealerIndex >= 0 &&
                game.dealerIndex < game.players.length
            ? game.players[game.dealerIndex].seat
            : -1;
        final feltPadH = narrow ? 0.0 : 4.0;
        final feltPadV = narrow ? 0.0 : 2.0;
        final radius = narrow
            ? (constraints.maxWidth * 0.22).clamp(28.0, 44.0)
            : (constraints.maxWidth * 0.18).clamp(40.0, 64.0);
        final sidePad = narrow ? 2.0 : 6.0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: feltPadH,
                  vertical: feltPadV,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    gradient: const RadialGradient(
                      colors: [Color(0xFF1F7A4D), Color(0xFF135C39)],
                      radius: 0.95,
                    ),
                    border: Border.all(
                      color: const Color(0xFF0C3D26),
                      width: narrow ? 4 : 6,
                    ),
                  ),
                ),
              ),
            ),
            // Борд + соперники — фиксированная зона (не прыгает с кнопками).
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(sidePad, 4, sidePad, 8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Align(
                      alignment: Alignment(0, veryShort ? -0.02 : -0.06),
                      child: _buildCenter(
                        game,
                        narrow,
                        cardSize,
                        compact: short || veryShort,
                        status: status,
                        showReward: showReward,
                        rewardBronze: rewardBronze,
                        betweenHands: betweenHands,
                      ),
                    ),
                    for (var i = 0; i < opponents.length; i++)
                      Align(
                        alignment: oppAnchors[i],
                        child: _buildSeat(
                          game,
                          opponents[i],
                          narrow,
                          cardsOnLeft: oppAnchors[i].x < -0.05,
                          compact: short || veryShort,
                        ),
                      ),
                    for (final p in game.players)
                      if (p.bet > 0 &&
                          !p.folded &&
                          (me < 0 || p.seat != game.players[me].seat))
                        Align(
                          alignment: _betAlignment(
                            seat: p.seat,
                            oppAnchors: oppAnchors,
                            opponents: opponents,
                          ),
                          child: _tableBetLabel(p.bet),
                        ),
                    if (dealerSeat >= 0 &&
                        (me < 0 || game.players[me].seat != dealerSeat))
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 520),
                        curve: Curves.easeInOutCubic,
                        alignment: _dealerAlignment(
                          dealerSeat: dealerSeat,
                          oppAnchors: oppAnchors,
                          opponents: opponents,
                        ),
                        child: _dealerBadge(size: narrow ? 20 : 24),
                      ),
                  ],
                ),
              ),
            ),
            // Hero у нижнего края; при кнопках — выезд вверх, борд на месте.
            if (me >= 0 && me < game.players.length)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: sidePad,
                right: sidePad,
                bottom: heroBottom,
                child: Center(
                  child: _buildHeroOnTable(
                    game,
                    narrow,
                    compact: short || veryShort,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Ставка соперника — сбоку от аватара, ближе к краю стола (не к банку).
  Alignment _betAlignment({
    required int seat,
    required List<Alignment> oppAnchors,
    required List<PokerPlayerView> opponents,
  }) {
    for (var i = 0; i < opponents.length; i++) {
      if (opponents[i].seat == seat) {
        final a = oppAnchors[i];
        if (a.x.abs() >= 0.5) {
          // Боковые места: ещё ближе к боковому краю, чуть ниже/выше аватара.
          return Alignment(
            (a.x * 0.96 + (a.x > 0 ? 0.08 : -0.08)).clamp(-0.98, 0.98),
            a.y,
          );
        }
        // Верх/низ: слева от аватара и ближе к внешнему краю овала.
        final sideX = (a.x - 0.18).clamp(-0.98, 0.98);
        final edgeY = a.y < 0
            ? (a.y * 0.98 - 0.02).clamp(-0.98, 0.0)
            : (a.y * 0.98 + 0.02).clamp(0.0, 0.98);
        return Alignment(sideX, edgeY);
      }
    }
    return Alignment.center;
  }

  /// Дилер — прямо под ставкой у того же края стола.
  Alignment _dealerAlignment({
    required int dealerSeat,
    required List<Alignment> oppAnchors,
    required List<PokerPlayerView> opponents,
  }) {
    final bet = _betAlignment(
      seat: dealerSeat,
      oppAnchors: oppAnchors,
      opponents: opponents,
    );
    // «Под ставкой» на экране = чуть ниже; всё ещё у края, не у банка.
    return Alignment(bet.x, (bet.y + 0.09).clamp(-0.98, 0.98));
  }

  /// Размер своих карт: чуть крупнее борда, без гигантского веера.
  Size _heroCardSize(bool narrow, int playerCount, {bool compact = false}) {
    if (compact) {
      if (playerCount <= 2) {
        return narrow ? const Size(48, 68) : const Size(54, 76);
      }
      return narrow ? const Size(40, 56) : const Size(46, 66);
    }
    if (playerCount <= 2) {
      return narrow ? const Size(54, 76) : const Size(62, 88);
    }
    if (playerCount <= 4) {
      return narrow ? const Size(48, 68) : const Size(56, 80);
    }
    return narrow ? const Size(42, 60) : const Size(48, 68);
  }

  PokerWinnerHand? _winnerHandForSeat(PokerGameView game, int seat) {
    for (final wh in game.winnerHands) {
      if (wh.seat == seat) return wh;
    }
    return null;
  }

  /// Якоря соперников — у самой кромки фетра (как в референсе).
  List<Alignment> _seatAnchors(int n) {
    switch (n) {
      case 0:
        return const [];
      case 1:
        return const [Alignment(0, -1.0)];
      case 2:
        return const [Alignment(-0.92, -0.82), Alignment(0.92, -0.82)];
      case 3:
        return const [
          Alignment(-1.0, -0.05),
          Alignment(0, -1.0),
          Alignment(1.0, -0.05),
        ];
      case 4:
        return const [
          Alignment(-1.0, 0.0),
          Alignment(-0.55, -1.0),
          Alignment(0.55, -1.0),
          Alignment(1.0, 0.0),
        ];
      default:
        return const [
          Alignment(-1.0, 0.08),
          Alignment(-0.72, -0.95),
          Alignment(0, -1.0),
          Alignment(0.72, -0.95),
          Alignment(1.0, 0.08),
        ];
    }
  }

  /// Размер общей карты: 5 карт в ряд с небольшими зазорами.
  Size _communityCardSize(
    double maxWidth,
    bool narrow, {
    bool short = false,
  }) {
    final maxW = short
        ? (narrow ? 52.0 : 64.0)
        : (narrow ? 68.0 : 90.0);
    final minW = short ? 36.0 : 40.0;
    final avail = maxWidth - (narrow ? 12.0 : 40.0);
    var w = (avail - 20.0) / 5;
    if (w > maxW) w = maxW;
    if (w < minW) w = minW;
    return Size(w, w / 0.7);
  }

  /// Подсвечивать карты комбинации: на вскрытии всегда; в раздаче — от пары и выше.
  bool _shouldHighlightCombo(PokerGameView game) {
    if (game.isShowdown) return game.highlightKeys.isNotEmpty;
    final rank = game.myHandRank;
    if (rank == null || rank.isEmpty || rank == 'HighCard') return false;
    return game.highlightKeys.isNotEmpty;
  }

  Widget _buildCenter(
    PokerGameView game,
    bool narrow,
    Size cardSize, {
    bool compact = false,
    required String status,
    required bool showReward,
    required int rewardBronze,
    required bool betweenHands,
  }) {
    final highlightKeys = game.highlightKeys;
    final hasHighlight = _shouldHighlightCombo(game);
    final gap = compact ? 4.0 : 6.0;
    final isOver = game.isOver;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Улица + чей ход — в центре, не поверх аватара соперника.
        Text(
          _streetLabel(game.street),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            shadows: const [
              Shadow(color: Color(0x99000000), blurRadius: 6),
            ],
          ),
        ),
        if (status.isNotEmpty) ...[
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: narrow ? 260 : 320,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: showReward ? 8 : 12,
                  vertical: showReward ? 5 : 4,
                ),
                child: isOver
                    ? GameStatusWithReward(
                        statusText: status,
                        showReward: showReward,
                        rewardBronze: rewardBronze,
                        rewardKey: _winRewardKey,
                        fontSize: compact ? 14 : 16,
                      )
                    : GameStatusLine(
                        text: status,
                        highlight: game.isMyTurn &&
                            !isOver &&
                            !game.isHandOver,
                      ),
              ),
            ),
          ),
        ],
        if (betweenHands) ...[
          const SizedBox(height: 4),
          Text(
            context.l10n.pokerNextHandSoon,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(color: Color(0x99000000), blurRadius: 6),
              ],
            ),
          ),
        ],
        SizedBox(height: gap),
        // Банк = тот же размер, что «Раздача» / «Блайнды».
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            KeyedSubtree(
              key: _tableChipsKey,
              child: _TableChipStack(amount: game.pot),
            ),
            const SizedBox(width: 6),
            _PotBadge(
              amount: game.pot,
              label: context.l10n.pokerPot(game.pot),
            ),
          ],
        ),
        SizedBox(height: gap),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < 5; i++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: narrow ? 2.0 : 3.5),
                child: SizedBox(
                  width: cardSize.width,
                  height: cardSize.height,
                  child: _communitySlot(
                    game,
                    i,
                    cardSize,
                    highlightKeys: highlightKeys,
                    hasHighlight: hasHighlight,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: gap),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoBadge(context.l10n.pokerHandNumber(game.handNumber)),
            if (game.smallBlind > 0 || game.bigBlind > 0) ...[
              const SizedBox(width: 6),
              _infoBadge(
                context.l10n.pokerBlinds(game.smallBlind, game.bigBlind),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _communitySlot(
    PokerGameView game,
    int i,
    Size cardSize, {
    required Set<int> highlightKeys,
    required bool hasHighlight,
  }) {
    if (i >= _shownCommunity || i >= game.community.length) {
      return _emptyCardSlot(cardSize);
    }
    final c = game.community[i];
    final hl = hasHighlight && highlightKeys.contains(PokerGameView.cardKeyOf(c));
    final dim = hasHighlight && !hl;
    return _EntranceCard(
      key: ValueKey('board_${game.handNumber}_${i}_${c.rank}_${c.suit}'),
      child: PlayingCardWidget(
        card: c.toPlayingCard(),
        size: cardSize,
        highlighted: hl,
        dimmed: dim,
        animate: false,
      ),
    );
  }

  Widget _infoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
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

  GlobalKey _seatKey(int seat) =>
      _seatKeys.putIfAbsent(seat, GlobalKey.new);

  /// Фишки: доклады в банк (колл/рейз/блайнды) → стопка у банка;
  /// выигрыш → карточка победителя.
  ///
  /// Колл часто закрывает улицу: в одном апдейте `bet` снова 0, а `pot`
  /// вырос — поэтому смотрим и рост ставки, и рост банка.
  void _syncChipFx(PokerGameView game) {
    if (game.handNumber != _prevHandNumber) {
      _prevHandNumber = game.handNumber;
      _prevHandOver = false;
      _prevPot = game.pot;
      _prevBets
        ..clear()
        ..addEntries(game.players.map((p) => MapEntry(p.seat, p.bet)));
      return;
    }
    if (!game.isHandOver) {
      final growers = <int>[
        for (final p in game.players)
          if (p.bet > (_prevBets[p.seat] ?? 0)) p.seat,
      ];
      // Колл/рейз, закрывшие улицу: ставки сброшены, банк вырос.
      final potGrew = _prevPot >= 0 && game.pot > _prevPot;
      final donors = <int>[
        ...growers,
        if (growers.isEmpty && potGrew)
          for (final e in _prevBets.entries)
            if (e.value > 0) e.key,
      ];
      // Фоллбэк: рост банка без явных доноров — от текущего/прошлого актёра.
      if (donors.isEmpty && potGrew && game.myIndex >= 0) {
        donors.add(game.players[game.myIndex].seat);
      }
      final unique = <int>{...donors};
      // Не дублируем optimistic-полёт после колла/рейза.
      unique.removeAll(_optimisticChipSeats);
      _optimisticChipSeats.clear();
      if (unique.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (final seat in unique.take(4)) {
            unawaited(
              _flyChips(fromKey: _seatKey(seat), toKey: _tableChipsKey),
            );
          }
        });
      } else {
        _optimisticChipSeats.clear();
      }
    }
    // Банк со стола — к карточке победителя.
    if (game.isHandOver && !_prevHandOver && game.winners.isNotEmpty) {
      final seats = _winnerSeats(game);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final seat in seats.take(2)) {
          unawaited(_flyChips(
            fromKey: _tableChipsKey,
            toKey: _seatKey(seat),
            count: 5,
            color: const Color(0xFFF5B301),
          ));
        }
      });
    }
    _prevHandOver = game.isHandOver;
    _prevPot = game.pot;
    _prevBets
      ..clear()
      ..addEntries(game.players.map((p) => MapEntry(p.seat, p.bet)));
  }

  /// `winners` в API — индексы игроков; для UI нужны seat-ключи.
  Set<int> _winnerSeats(PokerGameView game) {
    return {
      for (final i in game.winners)
        if (i >= 0 && i < game.players.length) game.players[i].seat,
    };
  }

  Future<void> _flyChips({
    required GlobalKey fromKey,
    required GlobalKey toKey,
    int count = 3,
    Color color = const Color(0xFFE8C547),
  }) async {
    if (!mounted || _disposed) return;
    final from = globalRectOf(fromKey);
    final to = globalRectOf(toKey);
    if (from == null || to == null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    for (var i = 0; i < count; i++) {
      if (!mounted || _disposed) return;
      final jitter = Offset(
        (i - count / 2) * 6,
        (i % 2 == 0 ? -1 : 1) * 4.0,
      );
      _spawnChipFly(
        overlay: overlay,
        from: from.center.translate(jitter.dx, jitter.dy),
        to: to.center,
        color: color,
        delayMs: i * 55,
      );
    }
  }

  void _spawnChipFly({
    required OverlayState overlay,
    required Offset from,
    required Offset to,
    required Color color,
    required int delayMs,
  }) {
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted || _disposed) return;
      late OverlayEntry entry;
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 520),
      );
      _chipControllers.add(controller);
      final curved = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);
      entry = OverlayEntry(
        builder: (_) {
          return IgnorePointer(
            child: AnimatedBuilder(
              animation: curved,
              builder: (context, _) {
                final t = curved.value;
                final x = from.dx + (to.dx - from.dx) * t;
                final y = from.dy + (to.dy - from.dy) * t -
                    28 * math.sin(math.pi * t);
                final s = 1.0 - 0.25 * t;
                return Stack(
                  children: [
                    Positioned(
                      left: x - 9,
                      top: y - 9,
                      child: Opacity(
                        opacity: (1 - t * 0.15).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: s,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color,
                                  Color.lerp(color, Colors.black, 0.25)!,
                                ],
                              ),
                              border: Border.all(color: Colors.white, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
      overlay.insert(entry);
      controller.forward().whenComplete(() {
        entry.remove();
        curved.dispose();
        controller.dispose();
        _chipControllers.remove(controller);
      });
    });
  }

  /// Место соперника: аватар + неймплейт; карты — сбоку (не сверху).
  /// Рамка хода только вокруг неймплейта; ставка рисуется отдельно на фетре.
  Widget _buildSeat(
    PokerGameView game,
    PokerPlayerView p,
    bool narrow, {
    bool cardsOnLeft = false,
    bool compact = false,
  }) {
    final acting = p.isActing && !game.isOver && !game.isHandOver;
    final isWinner = game.isHandOver && _winnerSeats(game).contains(p.seat);
    final headsUp = game.players.length == 2;
    final dim = p.folded;

    // Чужие hole_cards приходят только на showdown или после «Показать карты».
    final reveal = !p.folded &&
        p.holeCards != null &&
        p.holeCards!.length >= 2;
    final showCards = reveal;
    final holeSize = compact
        ? (narrow ? const Size(36, 50) : const Size(42, 60))
        : (narrow ? const Size(44, 62) : const Size(52, 74));
    final plateW = compact
        ? (narrow ? 88.0 : 100.0)
        : (narrow ? 96.0 : 108.0);
    const borderW = 2.5;

    // Подсветка карт победителя — из его winner_hand, не из моей комбинации.
    final wh = _winnerHandForSeat(game, p.seat);
    final oppHighlight = {
      if (wh != null)
        for (final c in wh.cards) PokerGameView.cardKeyOf(c),
    };
    final hasOppHl = reveal && isWinner && oppHighlight.isNotEmpty;
    final winnerCombo =
        (reveal && isWinner) ? _handRankLabel(wh?.rank) : null;

    // Непрозрачный фон — иначе на web карты «просвечивают» сквозь неймплейт.
    final namePlate = Container(
      width: plateW,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: dim ? const Color(0xFF2A2A2A) : const Color(0xFF161616),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isWinner
              ? const Color(0xFFF5B301)
              : Colors.white.withValues(alpha: 0.08),
          width: isWinner ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _playerName(p),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: dim ? 0.4 : 1),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            p.folded
                ? context.l10n.pokerFolded
                : p.allIn
                    ? context.l10n.pokerAllInBadge
                    : '${p.chips}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: dim
                  ? Colors.white38
                  : p.allIn
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFF5D76E),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    // Только аватар+неймплейт задают размер — Align не прыгает при показе карт.
    final plateColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: dim ? 0.35 : 1,
          child: GestureDetector(
            onTap: headsUp ? () => unawaited(_showPlayerCard(p)) : null,
            behavior: HitTestBehavior.opaque,
            child: GamePlayerAvatar(
              displayName: _playerName(p),
              avatarKind: p.avatarKind,
              avatarValue: p.avatarValue,
              frameCode: p.frameCode,
              frameColor: p.frameColor,
              compact: true,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Рамка только на ход — idle без обводки, padding стабильный.
        TurnTimerBorder(
          key: ValueKey('poker-seat-${p.seat}-${game.turnDeadline}'),
          active: acting,
          turnDeadline: game.turnDeadline,
          turnTimeSec: game.turnTimeSec,
          borderWidth: borderW,
          radius: 12,
          showIdleBorder: false,
          child: namePlate,
        ),
      ],
    );

    final cardsWidth = holeSize.width * 1.55;
    return KeyedSubtree(
      key: _seatKey(p.seat),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (showCards)
            Positioned(
              // Сбоку от профиля, не в Row — карточка профиля остаётся в якоре Align.
              left: cardsOnLeft ? -cardsWidth - 4 : null,
              right: cardsOnLeft ? null : -cardsWidth - 4,
              child: SizedBox(
                width: cardsWidth,
                height: holeSize.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < 2; i++)
                      Positioned(
                        left: i * holeSize.width * 0.55,
                        child: PlayingCardWidget(
                          card: p.holeCards![i].toPlayingCard(),
                          size: holeSize,
                          highlighted: hasOppHl &&
                              oppHighlight.contains(
                                PokerGameView.cardKeyOf(p.holeCards![i]),
                              ),
                          dimmed: hasOppHl &&
                              !oppHighlight.contains(
                                PokerGameView.cardKeyOf(p.holeCards![i]),
                              ),
                          animate: false,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          plateColumn,
          if (winnerCombo != null)
            Positioned(
              bottom: -26,
              child: _comboLabel(winnerCombo, highlight: true),
            ),
        ],
      ),
    );
  }

  /// Ставка на столе: мини-стопка + сумма.
  Widget _tableBetLabel(int amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniChipStack(),
        const SizedBox(width: 4),
        Text(
          '$amount',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniChipStack() {
    return SizedBox(
      width: 18,
      height: 14,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          for (var i = 0; i < 3; i++)
            Positioned(
              bottom: i * 2.2,
              child: Container(
                width: 14 - i * 0.4,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(const Color(0xFFE8C547), Colors.white, i * 0.1)!,
                      const Color(0xFFC9A227),
                    ],
                  ),
                  border: Border.all(color: Colors.white, width: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Анимация сброса: рубашки летят от рамки соперника к центру стола.
  void _syncFoldFx(PokerGameView game) {
    if (game.handNumber != _foldHand) {
      _foldHand = game.handNumber;
      _prevFolded
        ..clear()
        ..addEntries(game.players.map((p) => MapEntry(p.seat, p.folded)));
      return;
    }
    for (final p in game.players) {
      final was = _prevFolded[p.seat] ?? false;
      if (p.folded && !was) {
        final seat = p.seat;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_throwFoldCards(seat));
        });
      }
    }
    _prevFolded
      ..clear()
      ..addEntries(game.players.map((p) => MapEntry(p.seat, p.folded)));
  }

  Future<void> _throwFoldCards(int seat) async {
    if (!mounted || _disposed) return;
    final from = globalRectOf(_seatKey(seat));
    final to = globalRectOf(_tableChipsKey);
    if (from == null || to == null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    const cardSize = Size(34, 48);
    for (var i = 0; i < 2; i++) {
      if (!mounted || _disposed) return;
      final start = from.center.translate((i == 0 ? -10 : 10).toDouble(), -8);
      final end = to.center.translate((i == 0 ? -14 : 14).toDouble(), -6);
      _spawnFoldCardFly(
        overlay: overlay,
        from: start,
        to: end,
        size: cardSize,
        delayMs: i * 70,
        spin: i == 0 ? -0.55 : 0.7,
      );
    }
  }

  void _spawnFoldCardFly({
    required OverlayState overlay,
    required Offset from,
    required Offset to,
    required Size size,
    required int delayMs,
    required double spin,
  }) {
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted || _disposed) return;
      late OverlayEntry entry;
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      );
      _chipControllers.add(controller);
      final curved =
          CurvedAnimation(parent: controller, curve: Curves.easeInCubic);
      entry = OverlayEntry(
        builder: (_) {
          return IgnorePointer(
            child: AnimatedBuilder(
              animation: curved,
              builder: (context, _) {
                final t = curved.value;
                final x = from.dx + (to.dx - from.dx) * t;
                final y = from.dy +
                    (to.dy - from.dy) * t -
                    36 * math.sin(math.pi * t);
                final rot = spin * t;
                final opacity = (1.0 - t * 0.85).clamp(0.0, 1.0);
                final scale = 1.0 - 0.35 * t;
                return Stack(
                  children: [
                    Positioned(
                      left: x - size.width / 2,
                      top: y - size.height / 2,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.rotate(
                          angle: rot,
                          child: Transform.scale(
                            scale: scale,
                            child: CardBackWidget(size: size, outlined: true),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
      overlay.insert(entry);
      controller.forward().whenComplete(() {
        entry.remove();
        curved.dispose();
        controller.dispose();
        _chipControllers.remove(controller);
      });
    });
  }

  Widget _dealerBadge({double size = 24}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE082), Color(0xFFF5B301)],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5B301).withValues(alpha: 0.5),
            blurRadius: 6,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Text(
        'D',
        style: TextStyle(
          color: const Color(0xFF5C3B00),
          fontSize: size * 0.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  /// Hero по центру низа: крупный веер выглядывает из-за аватара.
  /// Профиль (аватар+неймплейт) — единственный якорь Align, карты его не сдвигают.
  Widget _buildHeroOnTable(
    PokerGameView game,
    bool narrow, {
    bool compact = false,
  }) {
    final me = game.me;
    if (me == null) return const SizedBox.shrink();
    final heroCards = _heroCardSize(
      narrow,
      game.players.length,
      compact: compact,
    );
    final highlightKeys = game.highlightKeys;
    final hasHighlight = _shouldHighlightCombo(game);
    final acting = me.isActing && !game.isOver && !game.isHandOver;
    final isWinner = game.isHandOver && _winnerSeats(game).contains(me.seat);
    final dim = me.folded;
    final plateW = compact
        ? (narrow ? 88.0 : 100.0)
        : (narrow ? 96.0 : 108.0);
    const borderW = 2.5;
    // Compact GamePlayerAvatar: FramedAvatar size = 36.
    const avatarSize = 36.0;
    const avatarPlateGap = 3.0;
    // Непрозрачный неймплейт + запас по высоте (padding/строки/рамка хода).
    const namePlateH = 42.0;
    final myWinCombo = isWinner
        ? _handRankLabel(_winnerHandForSeat(game, me.seat)?.rank) ??
            _handRankLabel(game.myHandRank)
        : null;

    final namePlate = Container(
      width: plateW,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: dim ? const Color(0xFF2A2A2A) : const Color(0xFF161616),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isWinner
              ? const Color(0xFFF5B301)
              : Colors.white.withValues(alpha: 0.08),
          width: isWinner ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _playerName(me),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: dim ? 0.4 : 1),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            me.folded
                ? context.l10n.pokerFolded
                : me.allIn
                    ? context.l10n.pokerAllInBadge
                    : '${me.chips}',
            style: TextStyle(
              color: dim
                  ? Colors.white38
                  : me.allIn
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFF5D76E),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    final isDealer = game.dealerIndex == game.myIndex;
    final showBet = me.bet > 0 && !me.folded;
    // Веер чуть выше неймплейта, без сильного выноса вверх (не наезжает на борд).
    const cardsBottom = namePlateH + avatarPlateGap;
    final peekOut = heroCards.width * 0.34;
    // Только этот столбец задаёт размер Stack → Align не прыгает при появлении карт.
    // Live-комбо («Пара») — в нижней панели, не дублируем под аватаром.
    final plateOnly = KeyedSubtree(
      key: _seatKey(me.seat),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: dim ? 0.35 : 1,
            child: GamePlayerAvatar(
              displayName: _playerName(me),
              avatarKind: me.avatarKind,
              avatarValue: me.avatarValue,
              frameCode: me.frameCode,
              frameColor: me.frameColor,
              compact: true,
            ),
          ),
          const SizedBox(height: avatarPlateGap),
          RepaintBoundary(
            child: TurnTimerBorder(
              key: ValueKey('poker-hero-${game.turnDeadline}'),
              active: acting,
              turnDeadline: game.turnDeadline,
              turnTimeSec: game.turnTimeSec,
              borderWidth: borderW,
              radius: 12,
              showIdleBorder: false,
              child: namePlate,
            ),
          ),
        ],
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        if (me.holeCards != null)
          Positioned(
            left: -peekOut,
            right: -peekOut,
            bottom: cardsBottom,
            height: heroCards.height,
            child: IgnorePointer(
              child: Opacity(
                opacity: dim ? 0.4 : 1,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < me.holeCards!.length; i++)
                      Transform.translate(
                        // Шире в стороны — аватар не прячется под картами.
                        offset: Offset(
                          (i == 0 ? -1 : 1) * heroCards.width * 0.36,
                          -avatarSize * 0.04,
                        ),
                        child: Transform.rotate(
                          angle: i == 0 ? -0.1 : 0.1,
                          alignment: Alignment.bottomCenter,
                          child: PlayingCardWidget(
                            key: ValueKey(
                              'hero_${game.handNumber}_${me.holeCards![i].rank}_${me.holeCards![i].suit}',
                            ),
                            card: me.holeCards![i].toPlayingCard(),
                            size: heroCards,
                            highlighted: hasHighlight &&
                                highlightKeys.contains(
                                  PokerGameView.cardKeyOf(me.holeCards![i]),
                                ),
                            dimmed: hasHighlight &&
                                !highlightKeys.contains(
                                  PokerGameView.cardKeyOf(me.holeCards![i]),
                                ),
                            animate: false,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        // Аватар поверх веера — карты выглядывают из-за него, профиль не двигается.
        plateOnly,
        // Ставка и D справа от профиля (выше неймплейта).
        if (showBet || isDealer)
          Positioned(
            left: plateW + 8,
            bottom: namePlateH + avatarPlateGap + 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showBet) _tableBetLabel(me.bet),
                if (isDealer) ...[
                  if (showBet) const SizedBox(height: 4),
                  _dealerBadge(size: narrow ? 22 : 26),
                ],
              ],
            ),
          ),
        // Комбо победителя — сбоку снизу, не поверх неймплейта.
        if (myWinCombo != null)
          Positioned(
            right: plateW + 6,
            bottom: 0,
            child: _comboLabel(myWinCombo, highlight: true),
          ),
      ],
    );
  }

  /// Под столом: комбинация + панель действий с фиксированной высотой
  /// (стол не прыгает при появлении/скрытии кнопок).
  Widget _buildBottomBar(PokerGameView game, bool narrow) {
    final comboLabel = _handRankLabel(game.myHandRank);
    final comboAccent = _shouldHighlightCombo(game) ||
        (game.isHandOver &&
            game.me != null &&
            _winnerSeats(game).contains(game.me!.seat));
    final showActions = !game.isOver &&
        !game.isHandOver &&
        game.isMyTurn &&
        game.legalActions.isNotEmpty;
    final showCardsBtn = game.canShowCards && !game.isOver;

    const comboSlot = 30.0;
    const actionSlot = 52.0;
    final bottomPad = narrow ? 8.0 : 12.0;

    final showActionRow = showActions || showCardsBtn;
    // Без кнопок не резервируем пустой ряд — hero остаётся у нижнего края.
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 2, 12, bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: comboSlot,
            child: comboLabel != null
                ? Center(
                    child: _comboLabel(
                      comboLabel,
                      highlight: comboAccent,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (showActionRow) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: actionSlot,
              child: showActions
                  ? _buildActionBar(game)
                  : Center(child: _buildShowCardsButton()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShowCardsButton() {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: _busy ? null : () => unawaited(_showCards()),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF3E7CB1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          minimumSize: const Size(160, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          context.l10n.pokerShowCards,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  Future<void> _showCards() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(pokerRepositoryProvider).showCards(widget.gameId);
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

  Widget _comboLabel(String text, {required bool highlight}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.accentStart.withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.accentStart.withValues(alpha: highlight ? 0.9 : 0.4),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
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

    // Одна строка фиксированной высоты — без Wrap, чтобы стол не прыгал.
    return Row(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: buttons[i]),
        ],
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          minimumSize: const Size(0, 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

/// Бейдж банка: плавный пульс при изменении суммы (акцент на прибавке банка).
class _PotBadge extends StatefulWidget {
  const _PotBadge({required this.amount, required this.label});

  final int amount;
  final String label;

  @override
  State<_PotBadge> createState() => _PotBadgeState();
}

class _PotBadgeState extends State<_PotBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _PotBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amount != oldWidget.amount) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = math.sin(math.pi * _c.value);
        return Transform.scale(scale: 1 + 0.1 * t, child: child);
      },
      // Тот же размер, что «Раздача» / «Блайнды» (_infoBadge).
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

/// Стопка фишек в центре стола под бордом — якорь анимации ставок/банка.
class _TableChipStack extends StatelessWidget {
  const _TableChipStack({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) {
      return const SizedBox(width: 36, height: 18);
    }
    final layers = amount >= 80 ? 4 : (amount >= 30 ? 3 : 2);
    return SizedBox(
      width: 40,
      height: 16.0 + layers * 3.5,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          for (var i = 0; i < layers; i++)
            Positioned(
              bottom: i * 3.2,
              child: Container(
                width: 22 - i * 0.6,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(const Color(0xFFE8C547), Colors.white, i * 0.08)!,
                      Color.lerp(const Color(0xFFC9A227), Colors.black, 0.2)!,
                    ],
                  ),
                  border: Border.all(color: Colors.white, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Появление карты: плавный «прилёт» (масштаб + прозрачность) при монтировании.
class _EntranceCard extends StatefulWidget {
  const _EntranceCard({super.key, required this.child});

  final Widget child;

  @override
  State<_EntranceCard> createState() => _EntranceCardState();
}

class _EntranceCardState extends State<_EntranceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _anim = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final v = _anim.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Transform.scale(
            scale: 0.7 + 0.3 * v,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
