import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_grid.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/board_move_sfx.dart';
import 'package:multigames_client/games/chess/chess_board.dart';
import 'package:multigames_client/games/chess/chess_engine.dart';
import 'package:multigames_client/games/chess/chess_material.dart';
import 'package:multigames_client/games/chess/chess_optimistic.dart';
import 'package:multigames_client/games/chess/chess_offline_session.dart';
import 'package:multigames_client/games/chess/chess_provider.dart';
import 'package:multigames_client/games/chess/chess_repository.dart';
import 'package:multigames_client/games/chess/chess_rules.dart';
import 'package:multigames_client/games/framework/game_opponent_panel.dart';
import 'package:multigames_client/games/framework/game_screen_scaffold.dart';
import 'package:multigames_client/games/game_turn_action.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException;
import 'package:multigames_client/games/game_balance_settle.dart';
import 'package:multigames_client/games/game_stake.dart';
import 'package:multigames_client/games/offline_session_hold.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/chess_game_icon.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/utils/user_error.dart';
import 'package:multigames_game_kit/multigames_game_kit.dart';

class ChessGameScreen extends ConsumerStatefulWidget {
  const ChessGameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  ConsumerState<ChessGameScreen> createState() => _ChessGameScreenState();
}

class _ChessGameScreenState extends ConsumerState<ChessGameScreen> {
  final GameTurnActionLock _turnAction = GameTurnActionLock();
  final GlobalKey _rewardKey = GlobalKey();

  ChessSquare? _selected;
  ChessSquare _cursor = const ChessSquare(0, 0);
  bool _busy = false;

  /// Оптимистично применённый ход — показываем сразу, не ждём ответа сервера.
  ChessGameView? _optimistic;

  /// Снимки позиций по ходам (авторитетные, от сервера) — для перемотки.
  final List<ChessGameView> _history = [];

  /// Индекс просматриваемой позиции в истории. `null` — следим за текущей.
  int? _reviewIndex;

  /// Переворот доски вручную. `null` — авто (снизу мой цвет).
  bool? _flipOverride;
  bool _isRematching = false;
  bool _isAcceptingRematch = false;
  bool _isFindingGame = false;
  bool _rematchDeclined = false;
  bool _iDeclinedRematch = false;
  String? _rematchLobbyId;
  bool _balanceGainPlayed = false;
  bool _lossChipRevealed = false;
  Future<bool>? _settleFuture;
  Timer? _rematchPollTimer;
  ProviderSubscription<AsyncValue<Map<String, dynamic>>>? _realtimeSubscription;

  bool get _isOffline => OfflineChessRegistry.instance.isOffline(widget.gameId);

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
        rememberGamesSessionPath(ref, '/games/chess/offline');
        return;
      }
      final known = ref.read(chessGameProvider(widget.gameId)).valueOrNull;
      if (known != null && known.isOver) {
        _clearSessionForFinishedGame();
      } else {
        pinBlockingGame(ref, widget.gameId, gameType: 'chess');
        final prev = ref.read(activeGameProvider).valueOrNull;
        if (prev?.gameId != widget.gameId) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: widget.gameId,
                  lobbyId: prev?.lobbyId,
                  gameType: 'chess',
                ),
              );
        }
      }
      unawaited(ref.read(activeGameProvider.notifier).refresh());
    });
  }

  @override
  void didUpdateWidget(covariant ChessGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId == widget.gameId) return;
    // Страница партии одна на все gameId: без сброса «ожидание соперника»
    // с прошлого реванша остаётся на новой доске.
    _rematchPollTimer?.cancel();
    _history.clear();
    _reviewIndex = null;
    _selected = null;
    _optimistic = null;
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
    ref.invalidate(chessGameProvider(widget.gameId));
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

  ChessRepository get _repo => ref.read(chessRepositoryProvider);

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || !_turnAction.tryAcquire()) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      if (!_isOffline) ref.invalidate(chessGameProvider(widget.gameId));
    } on GamesException catch (e) {
      if (!mounted) return;
      if (!isStaleNotYourTurnError(e) && !isStaleGameOverError(e)) {
        showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
      }
      if (!_isOffline) ref.invalidate(chessGameProvider(widget.gameId));
    } finally {
      _turnAction.release();
      if (mounted) setState(() => _busy = false);
    }
  }

  void _syncSelection(ChessGameView game) {
    if ((!game.isMyTurn || game.isOver) && _selected != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selected = null);
      });
    }
  }

  /// Живая позиция: оптимистичная, если она новее серверной, иначе серверная.
  ChessGameView _liveGame(ChessGameView server) {
    final opt = _optimistic;
    if (opt != null && opt.seq > server.seq && opt.id == server.id) return opt;
    return server;
  }

  /// Пишем серверные снимки в историю и сбрасываем оптимизм, когда сервер
  /// догнал. Вызывается из билда — только идемпотентные операции + отложенный
  /// `setState`, чтобы не менять состояние во время построения дерева.
  void _reconcile(ChessGameView server) {
    // Новая партия / реванш (seq откатился) — чистим историю.
    if (_history.isNotEmpty &&
        (server.id != _history.last.id || server.seq < _history.last.seq)) {
      _history.clear();
    }
    if (_history.isEmpty || server.seq > _history.last.seq) {
      _history.add(server);
    } else if (server.seq == _history.last.seq) {
      _history[_history.length - 1] = server;
    }
    final opt = _optimistic;
    if (opt != null && (server.seq >= opt.seq || server.id != opt.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final o = _optimistic;
        final s = ref.read(chessGameProvider(widget.gameId)).valueOrNull;
        if (o != null && s != null && (s.seq >= o.seq || s.id != o.id)) {
          setState(() => _optimistic = null);
        }
      });
    }
  }

  bool _resolvedFlip(ChessGameView game) =>
      _flipOverride ?? (game.myIndex == 1);

  /// Вид отличается от «мои фигуры снизу» — кнопка переворота фиолетовая.
  bool _viewChanged(ChessGameView game) =>
      _resolvedFlip(game) != (game.myIndex == 1);

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

  void _toggleFlip(ChessGameView game) {
    setState(() {
      _flipOverride = !_resolvedFlip(game);
    });
  }

  Future<void> _onSquareTap(ChessGameView game, int r, int c) async {
    if (_busy || !game.isMyTurn || game.isOver || _isReviewing) return;
    final sq = ChessSquare(r, c);
    final fromHere = game.legalMoves.where((m) => m.from == sq).toList();
    final selected = _selected;
    if (selected == null) {
      if (fromHere.isEmpty) return;
      setState(() => _selected = sq);
      return;
    }
    if (selected == sq) {
      setState(() => _selected = null);
      return;
    }
    final dests = game.legalMoves.where((m) => m.from == selected).toList();
    final matching = dests.where((m) => m.to == sq).toList();
    if (matching.isEmpty) {
      if (fromHere.isNotEmpty) {
        setState(() => _selected = sq);
      } else {
        setState(() => _selected = null);
      }
      return;
    }
    setState(() => _selected = null);
    ChessMove chosen = matching.first;
    if (matching.length > 1) {
      // Превращение пешки — спрашиваем фигуру.
      final promo = await _askPromotion(game.turn);
      if (promo == null || !mounted) return;
      chosen = matching.firstWhere(
        (m) => m.promo == promo,
        orElse: () => matching.first,
      );
    }
    // Оптимистично применяем ход — доска реагирует мгновенно.
    setState(() {
      _optimistic = chessViewAfterMove(game, chosen);
      _reviewIndex = null;
    });
    await _run(() => _repo.move(widget.gameId, chosen));
  }

  Future<int?> _askPromotion(int seat) async {
    final l10n = context.l10n;
    final options = <int, String>{
      ChessEngine.whiteQueen: l10n.chessPieceQueen,
      ChessEngine.whiteRook: l10n.chessPieceRook,
      ChessEngine.whiteBishop: l10n.chessPieceBishop,
      ChessEngine.whiteKnight: l10n.chessPieceKnight,
    };
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(l10n.chessPromotionTitle),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in options.entries)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(entry.key),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _kPromoBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ChessPieceGlyph(piece: entry.key + seat * 6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const Color _kPromoBg = GamePalette.boardDark;

  String _statusText(ChessGameView game) {
    final l10n = context.l10n;
    if (game.isOver) {
      if (game.isDraw) {
        switch (game.drawReason) {
          case ChessEngine.drawReasonStalemate:
            return l10n.chessDrawStalemate;
          case ChessEngine.drawReasonInsufficient:
            return l10n.chessDrawInsufficient;
          case ChessEngine.drawReasonRepetition:
            return l10n.chessDrawRepetition;
          case ChessEngine.drawReasonFiftyMove:
            return l10n.chessDrawFiftyMove;
          default:
            return l10n.gameDraw;
        }
      }
      if (game.myIndex < 0) return l10n.gameOverNeutral;
      if (game.iWon) return l10n.gameYouWonShort;
      return l10n.gameYouLost;
    }
    return game.isMyTurn ? l10n.gamesMyTurn : l10n.gamesOpponentTurn;
  }

  List<String> _peerIds(ChessGameView game, String? me) => [
        for (final id in game.playerIds)
          if (id.isNotEmpty && id != me) id,
      ];

  Future<void> _confirmSurrender() async {
    final game = ref.read(chessGameProvider(widget.gameId)).valueOrNull;
    if (game == null || game.isOver) return;
    final ok = await confirmSurrenderDialog(context);
    if (!ok || !mounted) return;
    unawaited(() async {
      try {
        clearBlockingGamePin(ref, ifGameId: widget.gameId);
        await _repo.forfeit(widget.gameId);
      } catch (_) {}
      if (!mounted) return;
      ref.invalidate(chessGameProvider(widget.gameId));
      unawaited(ref.read(activeGameProvider.notifier).refresh());
    }());
  }

  Future<void> _confirmDraw() async {
    final game = ref.read(chessGameProvider(widget.gameId)).valueOrNull;
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
      ref.invalidate(chessGameProvider(widget.gameId));
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
    final game = ref.read(chessGameProvider(widget.gameId)).valueOrNull;
    await handleGameScreenClose(
      context: context,
      isActive: game != null && !game.isOver,
      canLeaveFreely: _isOffline,
      onLeaveFinished: () async {
        if (!mounted) return;
        final settled = ref.read(chessGameProvider(widget.gameId)).valueOrNull ??
            game;
        if (!_isOffline && settled != null && settled.isOver) {
          await _runHeadToHeadSettle(settled);
        }
        if (!mounted) return;
        _navigateToGames();
      },
      onForfeitAndLeave: () async {
        if (!mounted) return;
        var forfeited = false;
        try {
          clearBlockingGamePin(ref, ifGameId: widget.gameId);
          await _repo.forfeit(widget.gameId);
          forfeited = true;
        } catch (_) {}
        if (!mounted) return;
        if (forfeited && !_isOffline && game != null) {
          await _runHeadToHeadSettle(game, forceLoss: true);
        }
        if (!mounted) return;
        _navigateToGames();
        unawaited(ref.read(activeGameProvider.notifier).refresh());
      },
    );
  }

  void _navigateToGames() {
    if (_isOffline) {
      leaveGamesSession(ref);
      OfflineChessRegistry.instance.get(widget.gameId)?.dispose();
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
        OfflineChessRegistry.instance.get(widget.gameId)?.restart();
        ref.invalidate(chessGameProvider(widget.gameId));
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
              gameType: 'chess',
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
                gameType: 'chess',
              ),
            );
        pinBlockingGame(ref, gameId, gameType: 'chess');
        context.go('/games/chess/game/$gameId');
      } else {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'lobby',
                lobbyId: lobbyId,
                gameType: 'chess',
              ),
            );
        context.go('/games/chess/lobby/$lobbyId?mode=invite');
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
            gameType: 'chess',
          ),
        );
    pinBlockingGame(ref, gameId, gameType: 'chess');
    ref.invalidate(chessGameProvider(gameId));
    if (!mounted) return;
    context.go('/games/chess/game/$gameId');
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
      final game = ref.read(chessGameProvider(widget.gameId)).valueOrNull;
      final created = await _repo.createLobby(
        mode: 'matchmake',
        gameMode: game?.gameMode ?? ChessEngine.modeClassic,
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
                gameType: 'chess',
              ),
            );
        pinBlockingGame(ref, gameId, gameType: 'chess');
        context.go('/games/chess/game/$gameId');
        return;
      }
      ref.read(activeGameProvider.notifier).setLocal(
            ActiveGameItem(
              type: 'lobby',
              lobbyId: created.lobbyId,
              gameType: 'chess',
            ),
          );
      context.go('/games/chess/lobby/${created.lobbyId}?mode=matchmake');
    } catch (_) {
      if (mounted) context.go('/games');
    } finally {
      if (mounted) setState(() => _isFindingGame = false);
    }
  }

  /// Время хода вышло (моё или соперника) — забрать с сервера итог.
  void _onTurnExpired() => ref.invalidate(chessGameProvider(widget.gameId));

  /// [reserveRail] — карточка стоит по центру под шапкой и сама отступает
  /// от столбика «сдаться / ничья»; в боковой колонке место даёт колонка.
  Widget _buildOpponentCard(
    ChessGameView game,
    String? me, {
    bool reserveRail = true,
  }) {
    final peers = _peerIds(game, me);
    if (peers.isEmpty) return const SizedBox.shrink();
    final opp = game.opponent;
    return GameOpponentPanel(
      opponent: GameOpponent(
        userId: peers.first,
        displayName: opp?.displayName,
        avatarKind: opp?.avatarKind ?? 'letter',
        avatarValue: opp?.avatarValue,
        frameCode: opp?.frameCode,
        frameColor: opp?.frameColor,
        isBot: opp?.isBot ?? false,
      ),
      gameType: 'chess',
      gameId: widget.gameId,
      isTheirTurn: !game.isOver && game.myIndex >= 0 && !game.isMyTurn,
      turnDeadline: game.turnTimeSec > 0 ? game.turnDeadline : 0,
      turnTimeSec: game.turnTimeSec,
      onTurnExpired: _onTurnExpired,
      reserveRail: reserveRail,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(chessGameProvider(widget.gameId));
    var me = ref.watch(authStateProvider).valueOrNull?.id;
    if (_isOffline && (me == null || me.isEmpty)) {
      me = OfflineChessRegistry.instance.get(widget.gameId)?.humanUserId;
    }
    final narrow = isNarrow(context);
    final game = gameAsync.valueOrNull;
    final draw = (game != null && !game.isOver)
        ? drawOfferFlags(game.drawOfferBy, me)
        : const DrawOfferFlags();
    final canDraw = game != null && !game.isOver && !game.hasBotOpponent;
    final showDraw = canDraw || draw.iOffered || draw.opponentOffered;
    final body = gameAsync.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      data: (game) {
        _syncSelection(game);
        return _buildGame(game, me, drawInRail: showDraw);
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
          style: const TextStyle(color: GamePalette.danger),
        ),
      ),
    );
    // Строго после тела: _reconcile дописывает историю, а от неё зависит
    // _isReviewing — шапка и доска должны видеть один и тот же «мой ход».
    final live = game == null ? null : _liveGame(game);

    return SwipeBackScope.gameBoard(
      onBack: _onClosePressed,
      child: GameScreenScaffold(
        chrome: GameChrome(
          onClose: _busy ? null : () => unawaited(_onClosePressed()),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChessGameIcon(
                size: narrow ? 20 : 22,
                color: AppColors.accentStart,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.l10n.gamesChess,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          centerTitle: true,
          onShowRules: () => showGameRulesDialog(
            context: context,
            content: rulesTextLines(chessRuleLines(
              gameMode: game?.gameMode ?? ChessEngine.modeClassic,
              turnTimeSec: game?.turnTimeSec ?? 0,
              stakeBronze: game?.stakeBronze ?? 0,
              offline: _isOffline,
              l10n: context.l10n,
            )),
            closeLabel: context.l10n.commonClose,
          ),
          turn: live == null || live.isOver
              ? const GameTurnClock.idle()
              : GameTurnClock(
                  isMyTurn: live.isMyTurn && !_isReviewing,
                  deadline: live.turnTimeSec > 0 ? live.turnDeadline : 0,
                  turnTimeSec: live.turnTimeSec,
                  onExpired: _onTurnExpired,
                ),
          onSurrender: game == null || game.isOver
              ? null
              : () => unawaited(_confirmSurrender()),
          draw: showDraw
              ? GameDrawOffer(
                  onPressed: () => unawaited(_confirmDraw()),
                  flags: draw,
                )
              : null,
        ),
        body: SafeArea(child: body),
      ),
    );
  }

  void _scheduleHeadToHeadSettle(ChessGameView server) {
    if (_isOffline || !server.isOver) return;
    if (isGameBalanceSettled(ref, widget.gameId)) {
      _balanceGainPlayed = true;
      if (_lossChipRevealed) return;
      final lost = stakeLostOnFinish(
        stakeBronze: server.stakeBronze,
        isDraw: server.isDraw,
        iWon: server.iWon,
      );
      if (lost <= 0) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _lossChipRevealed = true);
      });
      return;
    }
    if (_balanceGainPlayed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _balanceGainPlayed) return;
      unawaited(_runHeadToHeadSettle(server));
    });
  }

  Future<bool> _runHeadToHeadSettle(
    ChessGameView game, {
    bool forceLoss = false,
  }) {
    final existing = _settleFuture;
    if (existing != null) return existing;
    _balanceGainPlayed = true;
    final players = game.playerIds.length >= 2 ? game.playerIds.length : 2;
    final future = playHeadToHeadFinish(
      ref: ref,
      context: context,
      gameId: widget.gameId,
      stakeBronze: game.stakeBronze,
      iWon: forceLoss ? false : game.iWon,
      isDraw: forceLoss ? false : game.isDraw,
      playerCount: players,
      sourceKey: _rewardKey,
    );
    _settleFuture = future;
    return future.then((loss) {
      if (loss && mounted) setState(() => _lossChipRevealed = true);
      return loss;
    });
  }

  /// [drawInRail] — в столбике хрома под флагом стоит ещё и ничья.
  Widget _buildGame(
    ChessGameView server,
    String? me, {
    required bool drawInRail,
  }) {
    _scheduleHeadToHeadSettle(server);
    _reconcile(server);
    final live = _liveGame(server);
    final display = _isReviewing
        ? _history[_reviewIndex!.clamp(0, _history.length - 1)]
        : live;
    final landscape = isPhoneLandscape(context) ||
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    return BoardChangeSfx(
      signature: '${live.id}:${live.seq}',
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 2, 0, 6),
            // Builder: ширину столбика хрома видно только ниже каркаса.
            child: Builder(
              builder: (context) {
                final rail = GameChromeScope.railInsetOf(context);
                return landscape
                    ? _buildLandscape(live, display, me, rail: rail)
                    : _buildPortrait(
                        live,
                        display,
                        me,
                        // Флаг кончается выше низа карточки соперника; под
                        // неё, к строке часов, спускается только ничья.
                        clockRowInset: drawInRail ? rail : 0,
                      );
              },
            ),
          ),
          if (live.isOver && live.iWon)
            Positioned.fill(
              child: GameConfettiOverlay(
                key: ValueKey('chess-confetti-${widget.gameId}'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPortrait(
    ChessGameView live,
    ChessGameView display,
    String? me, {
    required double clockRowInset,
  }) {
    return Column(
      children: [
        _buildOpponentCard(live, me),
        const SizedBox(height: 4),
        Expanded(
          child: _buildBoardColumn(
            live,
            display,
            me,
            clockRowInset: clockRowInset,
          ),
        ),
      ],
    );
  }

  Widget _buildLandscape(
    ChessGameView live,
    ChessGameView display,
    String? me, {
    required double rail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 7,
          child: _buildBoardColumn(live, display, me),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 220,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOpponentCard(live, me, reserveRail: false),
              ],
            ),
          ),
        ),
        // Колонка с карточкой встаёт левее столбика «сдаться / ничья».
        SizedBox(width: rail),
      ],
    );
  }

  Widget _buildReviewBar(ChessGameView game) {
    final cur = _reviewIndex ?? (_history.isEmpty ? 0 : _history.length - 1);
    final canBack = _history.length > 1 && cur > 0;
    final canFwd = _reviewIndex != null;
    return GameReviewBar(
      onFlip: () => _toggleFlip(game),
      flipTooltip: context.l10n.gameFlipBoard,
      reviewing: _isReviewing,
      flipped: _viewChanged(game),
      onFirst: canBack ? _reviewFirst : null,
      onPrev: canBack ? _reviewPrev : null,
      onNext: canFwd ? _reviewNext : null,
      onLast: canFwd ? _reviewLast : null,
    );
  }

  int _clockMsFor(ChessGameView g, int seat) =>
      seat == 0 ? g.clockMs0 : g.clockMs1;

  /// Доска на всю ширину. Сверху: фигуры соперника, статус и его часы.
  /// Снизу: мои фигуры слева, перемотка у правого края рядом с моими часами.
  /// После партии итог и кнопки — над доской, доска ужимается под них.
  Widget _buildBoardColumn(
    ChessGameView live,
    ChessGameView display,
    String? me, {
    double clockRowInset = 0,
  }) {
    return Column(
      children: [
        if (live.isOver) _buildResultHeader(live, me),
        Expanded(
          child: _buildBoardArea(live, display, clockRowInset: clockRowInset),
        ),
      ],
    );
  }

  Widget _buildBoardArea(
    ChessGameView live,
    ChessGameView display, {
    required double clockRowInset,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mine = live.myIndex >= 0;
        const rowH = 40.0;
        const topPad = 6.0;
        const chrome = topPad + rowH * 2;
        final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
        final maxH =
            constraints.maxHeight.isFinite ? constraints.maxHeight : maxW;
        final avail = maxH.isFinite
            ? (maxH - chrome).clamp(0.0, maxH).toDouble()
            : maxW;
        final side = avail < maxW ? avail : maxW;
        final oppSeat = live.myIndex == 0 ? 1 : 0;
        final board = SizedBox(
          width: side,
          height: side,
          child: _buildBoard(live, display),
        );
        return Column(
          children: [
            _topChrome(
              material: mine
                  ? _materialLine(chessMaterialFor(display.board, oppSeat))
                  : const SizedBox.shrink(),
              clock: mine ? _clock(live, oppSeat) : null,
              status: live.isOver ? null : _buildStatusInline(live),
              endInset: clockRowInset,
            ),
            Expanded(child: Center(child: board)),
            _bottomChrome(
              material: mine
                  ? _materialLine(
                      chessMaterialFor(display.board, live.myIndex),
                    )
                  : const SizedBox.shrink(),
              review: _buildReviewBar(live),
              clock: mine ? _clock(live, live.myIndex) : null,
            ),
          ],
        );
      },
    );
  }

  /// Фигуры слева, статус по центру, часы соперника справа — одна линия.
  /// Небольшой отступ сверху, слева и справа. [endInset] — место справа под
  /// столбик «сдаться / ничья», когда строка стоит на его высоте.
  Widget _topChrome({
    required Widget material,
    required Widget? clock,
    required Widget? status,
    double endInset = 0,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 6, 8 + endInset, 0),
      child: SizedBox(
        height: 40,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side =
                (constraints.maxWidth * 0.34).clamp(72.0, 160.0).toDouble();
            return Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: side,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: material,
                      ),
                    ),
                    const Spacer(),
                    if (clock != null) clock,
                  ],
                ),
                if (status != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: side),
                    // Рядом со столбиком хрома строка уже: статус ужимаем,
                    // а не обрезаем многоточием.
                    child: FittedBox(fit: BoxFit.scaleDown, child: status),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bottomChrome({
    required Widget material,
    required Widget review,
    required Widget? clock,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
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
            review,
            if (clock != null) ...[
              const SizedBox(width: 4),
              clock,
            ],
          ],
        ),
      ),
    );
  }

  Widget? _clock(ChessGameView game, int seat) {
    if (!game.hasClock || seat < 0) return null;
    final mine = seat == game.myIndex;
    // Таймер на ход и часы партии вместе: звук только у таймера на ход.
    final audible = chessGameClockAudible(
      mine: mine,
      mode: game.gameMode,
      turnTimeSec: game.turnTimeSec,
      turnDeadline: game.turnDeadline,
    );
    return GameClock(
      remainingMs: _clockMsFor(game, seat),
      running: !game.isOver && game.clockRunning == seat,
      prominent: true,
      tickSound: audible,
      tickOnStart: audible,
    );
  }

  /// Съеденные фигуры и перевес (`+N`), как на lichess.
  Widget _materialLine(ChessMaterial material) {
    return SizedBox(
      height: 18,
      child: Row(
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final piece in material.captured)
                    SizedBox(
                      width: 16,
                      height: 18,
                      child: ChessPieceGlyph(piece: piece),
                    ),
                ],
              ),
            ),
          ),
          if (material.advantage > 0) ...[
            const SizedBox(width: 4),
            Text(
              '+${material.advantage}',
              style: const TextStyle(
                color: GamePalette.tableInkSoft,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Итог партии целиком, без ужатия в строку часов. Доска ниже становится меньше.
  Widget _buildResultHeader(ChessGameView game, String? me) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusInline(game, fontSize: 16, maxLines: 2),
          const SizedBox(height: 8),
          _buildFinishRow(game, me),
        ],
      ),
    );
  }

  Widget _buildStatusInline(
    ChessGameView game, {
    double fontSize = 14,
    int maxLines = 1,
  }) {
    final rawChip = stakeFinishRewardChip(
      stakeBronze: game.stakeBronze,
      isDraw: game.isDraw,
      iWon: game.iWon,
    );
    final rewardChip = rawChip < 0 && !_lossChipRevealed ? 0 : rawChip;
    return GameStatusWithReward(
      statusText: _statusText(game),
      showReward: stakeShowFinishReward(
        stakeBronze: game.stakeBronze,
        isOver: game.isOver,
        isDraw: game.isDraw,
        rewardChip: rewardChip,
      ),
      rewardBronze: rewardChip,
      rewardKey: _rewardKey,
      fontSize: fontSize,
      maxLines: maxLines,
      wrap: false,
    );
  }

  Widget _buildBoard(ChessGameView live, ChessGameView display) {
    final flip = _resolvedFlip(live);
    final interactive = !_isReviewing;
    return GamepadScope(
      onAction: (action) => _onGamepad(live, action, flip: flip),
      child: ChessBoard(
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
    ChessGameView game,
    GamepadAction action, {
    required bool flip,
  }) {
    if (game.isOver || _isReviewing) return false;
    if (action.isDirection) {
      final cursor = GamepadGridCursor(
        columns: ChessEngine.size,
        count: ChessEngine.size * ChessEngine.size,
        index: _cursor.r * ChessEngine.size + _cursor.c,
      );
      if (cursor.move(action, flip: flip)) {
        setState(() {
          _cursor = ChessSquare(
            cursor.index ~/ ChessEngine.size,
            cursor.index % ChessEngine.size,
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

  Widget _buildFinishRow(ChessGameView game, String? me) {
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
        gameType: 'chess',
        stakeBronze: game.stakeBronze,
        gameMode: game.gameMode,
      ),
    );
  }
}
