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
import 'package:multigames_client/games/board_move_sfx.dart';
import 'package:multigames_client/games/chess/chess_board.dart';
import 'package:multigames_client/games/chess/chess_engine.dart';
import 'package:multigames_client/games/chess/chess_material.dart';
import 'package:multigames_client/games/chess/chess_optimistic.dart';
import 'package:multigames_client/games/chess/chess_offline_session.dart';
import 'package:multigames_client/games/chess/chess_provider.dart';
import 'package:multigames_client/games/chess/chess_repository.dart';
import 'package:multigames_client/games/chess/chess_rules.dart';
import 'package:multigames_client/games/game_turn_action.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException;
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
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';
import 'package:multigames_client/utils/user_error.dart';

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

  static const Color _kPromoBg = Color(0xFF739552);

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
      if (game.isTimeout) {
        if (game.iWon) return l10n.gameYouWonOpponentTimeout;
        final name = game.opponent?.displayName.trim() ?? '';
        if (name.isNotEmpty) return l10n.gameOpponentWonTimeout(name);
      }
      if (game.iWon) {
        if (game.isForfeit) return l10n.gameYouWonOpponentForfeit;
        if (game.isTimeout) return l10n.gameYouWonOpponentTimeout;
        return l10n.gameYouWon;
      }
      return l10n.gameYouLost;
    }
    final me = ref.read(authStateProvider).valueOrNull?.id;
    final offer = game.drawOfferBy;
    if (offer != null && offer.isNotEmpty) {
      if (offer == me) return l10n.gameDrawOffered;
      return l10n.gameAcceptDrawTitle;
    }
    if (game.inCheck) return l10n.chessCheck;
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
            'game': '/games/chess/game/${widget.gameId}',
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
            'game': '/games/chess/game/${widget.gameId}',
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

  Widget _buildOpponentCard(ChessGameView game, String? me) {
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
        messageReturnPath: '/games/chess/game/${widget.gameId}',
      )),
      onMessageTap: isBot ? null : () => unawaited(_openChat(oppId, name)),
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
              content: rulesTextLines(chessRuleLines(
                gameMode: game?.gameMode ?? ChessEngine.modeClassic,
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

  Widget _buildGame(ChessGameView server, String? me) {
    _reconcile(server);
    final live = _liveGame(server);
    final display = _isReviewing
        ? _history[_reviewIndex!.clamp(0, _history.length - 1)]
        : live;
    final myTurn = live.isMyTurn && !live.isOver && !_isReviewing;
    final landscape = isPhoneLandscape(context) ||
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    return BoardChangeSfx(
      signature: '${live.id}:${live.seq}',
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 2, 0, 6),
            child: landscape
                ? _buildLandscape(live, display, me)
                : _buildPortrait(live, display, me),
          ),
          MyTurnAlert.stackLeaf(isMyTurn: myTurn),
        ],
      ),
    );
  }

  Widget _buildPortrait(
    ChessGameView live,
    ChessGameView display,
    String? me,
  ) {
    return Column(
      children: [
        _buildOpponentCard(live, me),
        const SizedBox(height: 4),
        Expanded(child: _buildBoardColumn(live, display)),
        if (live.isOver) ...[
          const SizedBox(height: 8),
          _buildFinishRow(live, me),
        ],
      ],
    );
  }

  Widget _buildLandscape(
    ChessGameView live,
    ChessGameView display,
    String? me,
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
  Widget _buildBoardColumn(ChessGameView live, ChessGameView display) {
    final myTurn = live.isMyTurn && !live.isOver && !_isReviewing;
    return LayoutBuilder(
      builder: (context, constraints) {
        final mine = live.myIndex >= 0;
        const rowH = 40.0;
        const topPad = 6.0;
        final hasTurnTimer =
            !live.isOver && live.turnTimeSec > 0 && live.turnDeadline > 0;
        const timerH = 28.0;
        final chrome = topPad + rowH * 2 + (hasTurnTimer ? timerH : 0);
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
              live,
              material: mine
                  ? _materialLine(chessMaterialFor(display.board, oppSeat))
                  : const SizedBox.shrink(),
              clock: mine ? _clock(live, oppSeat) : null,
            ),
            if (hasTurnTimer)
              SizedBox(
                height: timerH,
                child: Center(
                  child: GameTurnCountdown(
                    key: ValueKey('${live.turn}_${live.turnDeadline}'),
                    turnDeadline: live.turnDeadline,
                    isMyTurn: myTurn,
                    turnTimeSec: live.turnTimeSec,
                    onExpired: () =>
                        ref.invalidate(chessGameProvider(widget.gameId)),
                    labelBuilder: (s) => context.l10n.gameSecondsLeft(s),
                  ),
                ),
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
  /// Небольшой отступ сверху, слева и справа.
  Widget _topChrome(
    ChessGameView live, {
    required Widget material,
    required Widget? clock,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: side),
                  child: _buildStatusInline(live),
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
    return GameClock(
      remainingMs: _clockMsFor(game, seat),
      running: !game.isOver && game.clockRunning == seat,
      prominent: true,
      // Щелчок блица — от часов партии, даже если лимита на ход нет.
      tickSound: mine && chessBlitzClockAudible(game.gameMode),
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
                color: Color(0xFF5C6770),
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

  Widget _buildStatusInline(ChessGameView game) {
    final rewardChip = stakeFinishRewardChip(
      stakeBronze: game.stakeBronze,
      isDraw: game.isDraw,
      iWon: game.iWon,
    );
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
      fontSize: 14,
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
