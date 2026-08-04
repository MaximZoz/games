import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/game_engine/game_engine.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';
import 'package:multigames_client/router.dart';
import 'package:multigames_client/l10n/l10n.dart';

const List<IconData> _presetAvatarIcons = [
  Icons.face_rounded,
  Icons.face_2_rounded,
  Icons.face_3_rounded,
  Icons.face_4_rounded,
  Icons.face_5_rounded,
  Icons.face_6_rounded,
  Icons.man_rounded,
  Icons.woman_rounded,
  Icons.person_rounded,
];

class TicTacToeGameScreen extends ConsumerStatefulWidget {
  const TicTacToeGameScreen({
    super.key,
    required this.gameId,
  });

  final String gameId;

  @override
  ConsumerState<TicTacToeGameScreen> createState() =>
      _TicTacToeGameScreenState();
}

class _TicTacToeGameScreenState extends ConsumerState<TicTacToeGameScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  bool _isMakingMove = false;
  bool _isRematching = false;
  bool _isAcceptingRematch = false;
  String? _rematchLobbyId;
  bool _rematchDeclined = false;
  bool _iDeclinedRematch = false;
  /// Участники прошлой партии, ответившие на реванш (join или decline).
  final Set<String> _rematchRespondedIds = <String>{};
  bool _isFindingGame = false;
  bool _waitingForBotMove = false;
  Timer? _rematchPollTimer;
  Timer? _syncStateTimer;
  Timer? _timeoutRetryTimer;
  late AnimationController _pulseController;
  String? _prevGameStatus;
  bool _providerBindingsInitialized = false;
  ProviderSubscription<AsyncValue<Map<String, dynamic>>>? _realtimeSubscription;
  final GlobalKey _winRewardKey = GlobalKey();
  bool _balanceGainPlayed = false;
  /// chat_id из GetGame — MakeMove раньше мог не вернуть его (иконка мигала).
  String? _stickyGroupChatId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeProviderBindings();
    final route = ModalRoute.of(context);
    if (route != null) {
      chatsRouteObserver.unsubscribe(this);
      chatsRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    if (mounted) refreshChatsList(ref, force: true);
  }

  @override
  void didUpdateWidget(covariant TicTacToeGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId) {
      _rematchPollTimer?.cancel();
      _prevGameStatus = null;
      _balanceGainPlayed = false;
      _stickyGroupChatId = null;
      ref.invalidate(gameStateProvider(widget.gameId));
      setState(() {
        _rematchLobbyId = null;
        _rematchDeclined = false;
        _iDeclinedRematch = false;
        _rematchRespondedIds.clear();
        _isRematching = false;
        _isAcceptingRematch = false;
        _isFindingGame = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  void _initializeProviderBindings() {
    if (_providerBindingsInitialized) return;
    _providerBindingsInitialized = true;

    ref.invalidate(gameStateProvider(widget.gameId));
    // Нельзя писать в провайдеры из didChangeDependencies/build —
    // Riverpod падает в тестах и может дать неконсистентный UI.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prevActive = ref.read(activeGameProvider).valueOrNull;
      final meId = ref.read(authStateProvider).valueOrNull?.id;
      final knownGame = ref.read(gameStateOverrideProvider(widget.gameId)) ??
          ref.read(gameStateProvider(widget.gameId)).valueOrNull;
      final myMark = knownGame?.markForUser(meId);
      final eliminatedNow = myMark != null &&
          knownGame != null &&
          knownGame.isEliminated(myMark);
      final gameOver = knownGame != null && knownGame.status != 'active';
      final observing =
          ref.read(observationGameProvider)?.gameId == widget.gameId;
      final elim = eliminatedNow || observing;
      if (gameOver) {
        _clearSessionForFinishedGame();
      } else if (elim) {
        clearBlockingGamePin(ref, ifGameId: widget.gameId);
        ref.read(activeGameProvider.notifier).setObservationLocal(
              ObservationItem(
                gameId: widget.gameId,
                lobbyId: prevActive?.lobbyId,
              ),
            );
        if (prevActive?.gameId == widget.gameId) {
          ref.read(activeGameProvider.notifier).clearLocal();
        }
      } else {
        pinBlockingGame(ref, widget.gameId);
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'game',
                gameId: widget.gameId,
                lobbyId: prevActive?.lobbyId,
                isMyTurn: prevActive?.gameId == widget.gameId
                    ? (prevActive?.isMyTurn ?? false)
                    : false,
              ),
            );
      }
      unawaited(ref.read(activeGameProvider.notifier).refresh());
    });
    // Fallback-синк + дожим протухшего хода (сервер применяет timeout на GetGame).
    _syncStateTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted || _waitingForBotMove) return;
      final override = ref.read(gameStateOverrideProvider(widget.gameId));
      final game = override ??
          ref.read(gameStateProvider(widget.gameId)).valueOrNull;
      if (game != null && !game.isActivePvp) return;
      final deadline = game?.turnDeadline;
      if (deadline != null &&
          deadline > 0 &&
          DateTime.now().toUtc().millisecondsSinceEpoch >= deadline * 1000) {
        ref.read(gameStateOverrideProvider(widget.gameId).notifier).state =
            null;
      }
      ref.invalidate(gameStateProvider(widget.gameId));
      unawaited(ref.read(activeGameProvider.notifier).refresh());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) refreshChatsList(ref, force: true);
    });
    // Периодический refresh чатов на экране игры убран — badge/логины
    // обновляются по WS (chat_message / chat_list_changed).
    _realtimeSubscription = ref.listenManual(
      realtimeEventsProvider,
      (_, next) {
        final type = next.valueOrNull?['type']?.toString() ?? '';
        if (type == 'game_state' &&
            next.valueOrNull?['game_id'] == widget.gameId &&
            !_waitingForBotMove) {
          // Не сбрасываем override сразу: иначе на время refetch снова
          // показывается старый AsyncValue («Ваш ход» после своего хода).
          // Listener gameStateProvider сбросит override, когда данные не хуже.
          ref.invalidate(gameStateProvider(widget.gameId));
          unawaited(ref.read(activeGameProvider.notifier).refresh());
        }
        if (type == 'lobby_updated' && _rematchLobbyId != null) {
          final lobbyId = next.valueOrNull?['lobby_id']?.toString();
          final gameId = next.valueOrNull?['game_id']?.toString();
          if (lobbyId == _rematchLobbyId && mounted) {
            final meId = ref.read(authStateProvider).valueOrNull?.id;
            _applyRematchPlayerIds(
              next.valueOrNull?['player_ids'],
              meId: meId,
            );
            if (gameId != null && gameId.isNotEmpty) {
              ref.invalidate(gameStateProvider(gameId));
              unawaited(ref.read(activeGameProvider.notifier).refresh());
              context.go('/games/tictactoe/game/$gameId');
            }
          }
        }
        if (type == 'invite_declined') {
          final lobbyId = next.valueOrNull?['lobby_id']?.toString();
          // Multi: отказ одного не закрывает лобби (closed=false) — ждём остальных.
          final closed = next.valueOrNull?['closed'] != false;
          if (lobbyId == _rematchLobbyId && mounted) {
            final declinedUserId =
                next.valueOrNull?['user_id']?.toString().trim() ?? '';
            if (declinedUserId.isNotEmpty) {
              setState(() => _rematchRespondedIds.add(declinedUserId));
            }
            if (closed) {
              _rematchPollTimer?.cancel();
              setState(() {
                _rematchLobbyId = null;
                _rematchDeclined = true;
                _rematchRespondedIds.clear();
              });
            }
          }
        }
        if (type == 'chat_message' || type == 'chat_list_changed') {
          if (mounted) refreshChatsList(ref, force: true);
        }
      },
    );
  }

  void _applyRematchPlayerIds(dynamic raw, {String? meId}) {
    final ids = <String>[];
    if (raw is List) {
      for (final e in raw) {
        final id = e?.toString().trim() ?? '';
        if (id.isNotEmpty) ids.add(id);
      }
    } else if (raw is String && raw.trim().isNotEmpty) {
      for (final part in raw.split(',')) {
        final id = part.trim();
        if (id.isNotEmpty) ids.add(id);
      }
    }
    if (ids.isEmpty) return;
    final me = meId?.trim() ?? '';
    var changed = false;
    for (final id in ids) {
      if (me.isNotEmpty && id == me) continue;
      if (_rematchRespondedIds.add(id)) changed = true;
    }
    if (changed && mounted) setState(() {});
  }

  void _startRematchPoll() {
    _rematchPollTimer?.cancel();
    if (_rematchLobbyId == null) return;
    _rematchPollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_rematchLobbyId == null || !mounted) return;
      ref.invalidate(activeGameProvider);
      try {
        final lobby =
            await ref.read(gamesRepositoryProvider).getLobby(_rematchLobbyId!);
        if (!mounted) return;
        final meId = ref.read(authStateProvider).valueOrNull?.id;
        _applyRematchPlayerIds(lobby.playerIds, meId: meId);
        if (lobby.gameId != null && lobby.gameId!.isNotEmpty) {
          _rematchPollTimer?.cancel();
          final gameId = lobby.gameId!;
          ref.invalidate(gameStateProvider(gameId));
          context.go('/games/tictactoe/game/$gameId');
        }
      } on GamesException catch (e) {
        if (e.statusCode == 404 && mounted) {
          _rematchPollTimer?.cancel();
          setState(() {
            _rematchLobbyId = null;
            _rematchRespondedIds.clear();
          });
        }
      } catch (_) {}
    });
  }

  void _onTurnTimeExpired() {
    _timeoutRetryTimer?.cancel();
    var attempt = 0;
    void doRefresh() {
      if (!mounted) return;
      // Без сброса override клиент может вечно показывать старый «Ход X» при 0 с.
      ref.read(gameStateOverrideProvider(widget.gameId).notifier).state = null;
      ref.invalidate(gameStateProvider(widget.gameId));
      ref.invalidate(activeGameProvider);
      setState(() {});
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => doRefresh());
    // Сервер применяет timeout на GetGame/GetActive — дожимаем ~8 с.
    _timeoutRetryTimer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      attempt++;
      doRefresh();
      if (attempt >= 10) {
        t.cancel();
        _timeoutRetryTimer = null;
      }
    });
  }

  static int _filledCells(GameStateItem g) =>
      g.board.where((c) => c.isNotEmpty).length;

  @override
  void dispose() {
    chatsRouteObserver.unsubscribe(this);
    _rematchPollTimer?.cancel();
    _syncStateTimer?.cancel();
    _timeoutRetryTimer?.cancel();
    _realtimeSubscription?.close();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final override = ref.watch(gameStateOverrideProvider(widget.gameId));
    final gameAsync = ref.watch(gameStateProvider(widget.gameId));
    // При наличии override (после победного хода) показываем сразу, без ожидания refetch
    final effectiveGameAsync =
        override != null ? AsyncData(override) : gameAsync;
    final currentUser = ref.watch(authStateProvider).valueOrNull;

    ref.listen(gameStateProvider(widget.gameId), (_, next) {
      next.whenOrNull(
        data: (fresh) {
          if (!mounted) return;
          // Во время ожидания хода бота не сбрасываем override — иначе старый fetch может вернуть данные без нашего хода
          if (_waitingForBotMove) return;
          ref
              .read(gameStateInvalidateBlockedProvider(widget.gameId).notifier)
              .state = false;
          final ov = ref.read(gameStateOverrideProvider(widget.gameId));
          if (ov != null) {
            // Stale refetch после своего хода — не откатываем UI.
            if (_filledCells(fresh) < _filledCells(ov)) return;
            if (_filledCells(fresh) == _filledCells(ov) &&
                fresh.turn != ov.turn &&
                (fresh.turnDeadline ?? 0) < (ov.turnDeadline ?? 0)) {
              return;
            }
          }
          if (ov != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref
                    .read(gameStateOverrideProvider(widget.gameId).notifier)
                    .state = null;
              }
            });
          }
        },
        error: (_, __) => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _waitingForBotMove = false;
            ref
                .read(
                    gameStateInvalidateBlockedProvider(widget.gameId).notifier)
                .state = false;
            context.go('/games');
          }
        }),
      );
    });
    ref.listen(activeGameProvider, (_, next) {
      final active = next.valueOrNull;
      if (active == null || active.type != 'game' || active.gameId == null) {
        return;
      }
      if (active.gameId != widget.gameId) {
        if (_rematchLobbyId == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.invalidate(gameStateProvider(active.gameId!));
            context.go('/games/tictactoe/game/${active.gameId}');
          }
        });
        return;
      }
      final game = ref.read(gameStateProvider(widget.gameId)).valueOrNull;
      if (game == null || game.status != 'active') return;
      final isMyTurnFromGame = game.isTurnOf(currentUser?.id);
      if (active.isMyTurn != isMyTurnFromGame) {
        ref.invalidate(gameStateProvider(widget.gameId));
      }
    });
    void goBack() => _handleClose(effectiveGameAsync.valueOrNull);
    final gameForBar = effectiveGameAsync.valueOrNull;
    final gameActive = gameForBar != null && gameForBar.status == 'active';
    final showDrawButton = gameForBar != null &&
        gameForBar.status == 'active' &&
        gameForBar.isActivePvp &&
        gameForBar.maxPlayers <= 2;
    final meId = currentUser?.id;
    final drawOfferBy = gameForBar?.drawOfferBy?.trim();
    final iOfferedDraw =
        drawOfferBy != null && meId != null && drawOfferBy == meId;
    final opponentOfferedDraw = drawOfferBy != null &&
        meId != null &&
        drawOfferBy.isNotEmpty &&
        drawOfferBy != meId;
    // Крестик — в AppBar.leading (нажимается штатно).
    // «Сдаться» и «ничья» — overlay справа сверху, под кнопкой «правила»
    // (правый край AppBar). В углу контент игры их не перекрывает → тапы
    // доходят; кнопки идут вертикально друг под другом.
    final topPad = MediaQuery.paddingOf(context).top;
    // На телефоне доска упирается в левый край: opaque-полоса свайпа
    // перехватывала клетки и иногда открывала «выйти».
    return SwipeBackScope(
      onBack: goBack,
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
            constraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            onPressed: goBack,
            icon: const Icon(Icons.close_rounded),
          ),
          title: Text(context.l10n.gamesTicTacToe),
          actions: [
            // Multi: «сдаться» в AppBar, чтобы не налезала на блок чата/игроков.
            if (gameForBar != null &&
                gameForBar.status == 'active' &&
                gameForBar.maxPlayers > 2 &&
                !(meId != null &&
                    gameForBar.markForUser(meId) != null &&
                    gameForBar.isEliminated(gameForBar.markForUser(meId)!)))
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                iconSize: 22,
                icon: const Icon(Icons.flag_outlined),
                tooltip: context.l10n.gameSurrender,
                onPressed: () => _confirmSurrender(context),
              ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              iconSize: 22,
              icon: const Icon(Icons.rule_rounded),
              tooltip: context.l10n.gamesRulesTitle,
              onPressed: () => _showGameRules(context),
            ),
          ],
        ),
        body: effectiveGameAsync.when(
          data: (game) {
            final isOver = game.status != 'active';
            final isMultiGame = game.maxPlayers > 2;
            final meIdForPeers = currentUser?.id;
            final peerIds = game.playerUserIds
                .where((id) => id.isNotEmpty && id != meIdForPeers)
                .toList(growable: false);
            final opponentId = peerIds.isNotEmpty
                ? peerIds.first
                : (game.xUserId == currentUser?.id
                    ? game.oUserId
                    : game.xUserId);
            final myMark = game.markForUser(currentUser?.id);
            final iWonEarly = isOver &&
                game.status.endsWith('_won') &&
                myMark != null &&
                game.winner == myMark;
            final isDraw = isOver && game.status == 'draw';
            if (isOver &&
                (_prevGameStatus == 'active' || _prevGameStatus == null)) {
              _rematchPollTimer?.cancel();
              _prevGameStatus = game.status;
              if (currentUser != null) {
                for (final peerId in peerIds) {
                  ref
                      .read(gameInvitesProvider.notifier)
                      .removeByCreatorId(peerId);
                }
              }
              // Не трогаем провайдеры баланса из build — только после кадра.
              // Сервер: банк stake*N победителю; чистый плюс к доматчевому = stake*(N-1).
              final playersN = game.playerUserIds.length >= 2
                  ? game.playerUserIds.length
                  : (game.maxPlayers > 2 ? game.maxPlayers : 2);
              final pot = game.stakeBronze * playersN;
              final netProfit = game.stakeBronze * (playersN - 1);
              final settledCredit = iWonEarly
                  ? pot
                  : isDraw
                      ? game.stakeBronze
                      : 0;
              final settledReward = iWonEarly ? netProfit : 0;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                // Партия окончена — снять active/observation/пин, иначе
                // «Создать/Найти» блокируется «завершите текущую игру».
                _clearSessionForFinishedGame();
                setState(() {
                  _rematchLobbyId = null;
                  _rematchDeclined = false;
                  _iDeclinedRematch = false;
                  _rematchRespondedIds.clear();
                  _isRematching = false;
                  _isFindingGame = false;
                });
                unawaited(_onGameSettled(
                  creditBronze: settledCredit,
                  displayRewardBronze: settledReward,
                ));
              });
            } else {
              _prevGameStatus = game.status;
            }
            final eliminatedNow =
                myMark != null && game.isEliminated(myMark);
            // Пин/observation — только после кадра (не в build).
            if (!isOver && !eliminatedNow) {
              final alreadyPinned =
                  ref.read(blockingGamePinProvider) == widget.gameId;
              if (!alreadyPinned) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final g =
                      ref.read(gameStateOverrideProvider(widget.gameId)) ??
                          ref
                              .read(gameStateProvider(widget.gameId))
                              .valueOrNull;
                  if (g == null || g.status != 'active') return;
                  final mark = g.markForUser(
                      ref.read(authStateProvider).valueOrNull?.id);
                  if (mark != null && g.isEliminated(mark)) return;
                  pinBlockingGame(ref, widget.gameId);
                });
              }
            } else if (eliminatedNow && !isOver) {
              final alreadyObs =
                  ref.read(observationGameProvider)?.gameId == widget.gameId;
              if (!alreadyObs) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  clearBlockingGamePin(ref, ifGameId: widget.gameId);
                  final prev = ref.read(activeGameProvider).valueOrNull;
                  ref.read(activeGameProvider.notifier).setObservationLocal(
                        ObservationItem(
                          gameId: widget.gameId,
                          lobbyId: prev?.lobbyId,
                        ),
                      );
                  if (prev?.gameId == widget.gameId) {
                    ref.read(activeGameProvider.notifier).clearLocal();
                  }
                });
              }
            }
            // Полное состояние игры — источник истины для текущего хода.
            final isMyTurn = game.isTurnOf(currentUser?.id) && !eliminatedNow;
            final opponentName = opponentId.startsWith('bot:')
                ? context.l10n.gameBot
                : (game.xUserId == currentUser?.id
                    ? (game.oDisplayName ?? context.l10n.gameOpponent)
                    : (game.xDisplayName ?? context.l10n.gameOpponent));
            final opponentAvatarKind = game.xUserId == currentUser?.id
                ? game.oAvatarKind
                : game.xAvatarKind;
            final opponentAvatarValue = game.xUserId == currentUser?.id
                ? game.oAvatarValue
                : game.xAvatarValue;
            final opponentFrameCode = game.xUserId == currentUser?.id
                ? game.oFrameCode
                : game.xFrameCode;
            final opponentFrameColor = game.xUserId == currentUser?.id
                ? game.oFrameColor
                : game.xFrameColor;

            String statusText = '';
            String? statusMark;
            if (isOver) {
              if (game.status.endsWith('_won')) {
                final iWon = iWonEarly;
                if (isMultiGame) {
                  final winnerName = game.playerMeta(game.winner ?? '')
                          ?.displayName
                          ?.trim() ??
                      opponentName;
                  statusText =
                      iWon ? context.l10n.gameYouWon : 'Победил $winnerName';
                } else {
                  statusText = iWon
                      ? (game.forfeit
                          ? context.l10n.gameYouWonOpponentForfeit
                          : game.timeout
                              ? context.l10n.gameYouWonOpponentTimeout
                              : context.l10n.gameYouWon)
                      : (game.forfeit
                          ? context.l10n.gameYouForfeitOpponentWon(opponentName)
                          : game.timeout
                              ? context.l10n.gameOpponentWonTimeout(opponentName)
                              : context.l10n.gameOpponentWon(opponentName));
                }
              } else if (game.status == 'draw') {
                // В multi значка/режима ничьей нет — нейтральный итог.
                statusText = isMultiGame
                    ? 'Партия окончена'
                    : context.l10n.gameDraw;
              }
            } else if (eliminatedNow) {
              statusText = 'Вы выбыли';
              statusMark = myMark;
            } else if (isMyTurn) {
              statusText = context.l10n.gamesMyTurn;
              statusMark = myMark;
            } else {
              // «Ход {логин}» — чей сейчас ход (не себя).
              // chatsList через read: не пересобираем доску на каждый poll чатов.
              final turnMeta = game.playerMeta(game.turn);
              final fromMeta = turnMeta?.displayName?.trim() ?? '';
              final turnName = fromMeta.isNotEmpty
                  ? fromMeta
                  : _resolvePlayerLogin(
                      turnMeta,
                      chatsList:
                          ref.read(chatsListProvider).valueOrNull ?? const [],
                      chatId: game.chatId,
                    );
              statusText = turnName.isNotEmpty
                  ? 'Ход $turnName'
                  : context.l10n.gamesOpponentTurn;
              statusMark = game.turn.trim().isEmpty ? null : game.turn;
            }

            final iWon = iWonEarly;
            final playersNForReward = game.playerUserIds.length >= 2
                ? game.playerUserIds.length
                : (game.maxPlayers > 2 ? game.maxPlayers : 2);
            final showRewardChip = isOver && iWon && game.stakeBronze > 0;
            // Чистый выигрыш (как меняется баланс относительно до матча).
            final rewardBronze = game.stakeBronze * (playersNForReward - 1);
            final isDesktop = isWide(context);
            final narrow = isNarrow(context);
            final phoneLandscape = isPhoneLandscape(context);
            // Планшет landscape: доска слева (как телефон), иначе низ обрезается.
            final landscapeSideBySide = phoneLandscape ||
                (isTablet(context) &&
                    MediaQuery.sizeOf(context).width >
                        MediaQuery.sizeOf(context).height);
            final contentPadding =
                landscapeSideBySide ? 8.0 : (narrow ? 12.0 : 24.0);
            final verticalSpacing =
                landscapeSideBySide ? 6.0 : (narrow ? 10.0 : 20.0);

            Widget opponentCard() {
              if (isMultiGame) {
                final fromGame = (game.chatId ?? '').trim();
                if (fromGame.isNotEmpty) {
                  _stickyGroupChatId = fromGame;
                }
                final chatId = fromGame.isNotEmpty
                    ? fromGame
                    : (_stickyGroupChatId ?? '').trim();
                final chats = ref.watch(chatsListProvider).valueOrNull;
                final chatStillExists = chatId.isNotEmpty &&
                    (chats?.any((c) => c.chatID == chatId) ?? false);
                // После конца партии чат удаляется — иконка остаётся, но disabled.
                final canOpenChat = !isOver && chatStillExists;
                // Только unread нужного группового чата — не весь список.
                final groupUnread = !canOpenChat
                    ? 0
                    : ref.watch(chatsListProvider.select((async) {
                        final list = async.valueOrNull;
                        if (list == null) return 0;
                        for (final c in list) {
                          if (c.chatID == chatId) return c.unreadCount;
                        }
                        return 0;
                      }));
                return _MultiOpponentsCard(
                  game: game,
                  // Только чужие; без me — пусто (не мелькает «я» / «Соперник»).
                  opponents: game.opponentsOf(currentUser?.id),
                  rematchRespondedIds: _rematchLobbyId == null
                      ? const <String>{}
                      : _rematchRespondedIds,
                  chatsList: chats ?? const [],
                  groupUnread: groupUnread,
                  showGroupChat: chatId.isNotEmpty,
                  onGroupChatTap:
                      canOpenChat ? () => _openGroupChat(context, game) : null,
                  onPlayerTap: (player, login) {
                    if (player.userId.startsWith('bot:')) return;
                    _showOpponentInfo(
                      context,
                      opponentId: player.userId,
                      displayName: login,
                      avatarKind: player.avatarKind,
                      avatarValue: player.avatarValue,
                      frameCode: player.frameCode,
                      frameColor: player.frameColor,
                    );
                  },
                );
              }
              final messageUnread = opponentId.isEmpty
                  ? 0
                  : ref.watch(chatsListProvider.select((async) {
                      final list = async.valueOrNull;
                      if (list == null) return 0;
                      var sum = 0;
                      for (final c in list) {
                        if (c.user.id == opponentId) sum += c.unreadCount;
                      }
                      return sum;
                    }));
              return _OpponentCard(
                opponentId: opponentId,
                displayName: opponentName,
                avatarKind: opponentAvatarKind,
                avatarValue: opponentAvatarValue,
                frameCode: opponentFrameCode,
                frameColor: opponentFrameColor,
                isBot: opponentId.startsWith('bot:'),
                friendsSnapshot:
                    ref.watch(friendsSnapshotProvider).valueOrNull,
                messageUnread: messageUnread,
                onInfoTap: () => _showOpponentInfo(
                  context,
                  opponentId: opponentId,
                  displayName: opponentName,
                  avatarKind: opponentAvatarKind,
                  avatarValue: opponentAvatarValue,
                  frameCode: opponentFrameCode,
                  frameColor: opponentFrameColor,
                ),
                onMessageTap: () =>
                    _openChat(context, opponentId, opponentName),
                onAddFriendTap: (requestId) => _addFriend(
                    context, opponentId, opponentName,
                    requestId: requestId),
              );
            }

            Widget statusBlock() => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusWithReward(
                      statusText: statusText,
                      statusMark: isOver ? null : statusMark,
                      showReward: showRewardChip,
                      rewardBronze: rewardBronze,
                      rewardKey: _winRewardKey,
                      fontSize: narrow ? 15 : null,
                    ),
                    if (!isOver &&
                        game.turnTimeSec > 0 &&
                        game.turnDeadline != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _TurnCountdown(
                          key: ValueKey(
                            '${game.turn}_${game.turnDeadline}',
                          ),
                          turnDeadline: game.turnDeadline!,
                          isMyTurn: isMyTurn,
                          onExpired: _onTurnTimeExpired,
                        ),
                      ),
                    if (isOver) ...[
                      SizedBox(height: verticalSpacing * 0.8),
                      _RematchSection(
                        rematchLobbyId: _rematchLobbyId,
                        rematchDeclined: _rematchDeclined,
                        iDeclinedRematch: _iDeclinedRematch,
                        isRematching: _isRematching,
                        isAcceptingRematch: _isAcceptingRematch,
                        isFindingGame: _isFindingGame,
                        peerIds: peerIds,
                        invites: ref.watch(gameInvitesProvider),
                        onRematch: () => _rematch(context),
                        onAccept: _acceptRematch,
                        onDecline: _declineRematch,
                        onCancelWait: _cancelRematchWait,
                        onFindGame: () => _findGame(context),
                        compact: true,
                      ),
                    ],
                  ],
                );

            Widget board() => Center(
                  child: _GameBoard(
                    game: game,
                    isMyTurn: isMyTurn,
                    isOver: isOver,
                    isMakingMove: _isMakingMove,
                    onMove: _makeMove,
                    // Pulse на 8×8/10×10 — десятки AnimatedBuilder каждый кадр.
                    pulseController:
                        game.gridSize <= 3 ? _pulseController : null,
                    compact: narrow,
                  ),
                );

            // Телефон/планшет landscape: доска слева, статус справа —
            // «Повторить» / «Другой соперник» не обрезаются снизу.
            final Widget bodyLayout;
            if (landscapeSideBySide) {
              bodyLayout = Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: board()),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          opponentCard(),
                          SizedBox(height: verticalSpacing),
                          statusBlock(),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else if (isDesktop) {
              bodyLayout = Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  opponentCard(),
                  SizedBox(height: verticalSpacing),
                  statusBlock(),
                  SizedBox(height: verticalSpacing),
                  Expanded(child: board()),
                ],
              );
            } else {
              // Шапка по контенту — доска забирает всё оставшееся место
              // (раньше Flexible+Expanded делили высоту пополам → пустоты у гомоку).
              bodyLayout = Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  opponentCard(),
                  SizedBox(height: verticalSpacing * 0.6),
                  statusBlock(),
                  SizedBox(height: verticalSpacing * 0.6),
                  Expanded(child: board()),
                ],
              );
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(contentPadding),
                    child: bodyLayout,
                  ),
                ),
                if (iWon)
                  Positioned.fill(
                    child: const GameConfettiOverlay(),
                  ),
                // 1v1: «сдаться»/«ничья» overlay справа сверху.
                // Multi: флаг в AppBar — иначе на мобиле налезает на чат игроков.
                if (gameActive &&
                    !isMultiGame &&
                    !(meId != null &&
                        game.markForUser(meId) != null &&
                        game.isEliminated(game.markForUser(meId)!)))
                  Positioned(
                    right: 4,
                    top: topPad + 4,
                    child: _GameActionsOverlay(
                      canDraw: showDrawButton,
                      iOfferedDraw: iOfferedDraw,
                      opponentOfferedDraw: opponentOfferedDraw,
                      onSurrender: () => _confirmSurrender(context),
                      onDraw: () => opponentOfferedDraw
                          ? _confirmAcceptDraw(context)
                          : _confirmOfferDraw(context),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accentStart,
            ),
          ),
          error: (_, __) => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accentStart,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onGameSettled({
    required int creditBronze,
    required int displayRewardBronze,
  }) async {
    if (_balanceGainPlayed || creditBronze <= 0) {
      unawaited(ref.read(authStateProvider.notifier).refresh());
      return;
    }
    _balanceGainPlayed = true;
    // Общий сценарий начисления — тот же, что у Дурака.
    await playGameSettledReward(
      ref: ref,
      context: context,
      creditBronze: creditBronze,
      displayRewardBronze: displayRewardBronze,
      sourceKey: displayRewardBronze > 0 ? _winRewardKey : null,
    );
  }

  void _confirmSurrender(BuildContext context) {
    final game = ref.read(gameStateProvider(widget.gameId)).valueOrNull;
    if (game == null || game.status != 'active') return;
    final me = ref.read(authStateProvider).valueOrNull?.id;
    final mark = game.markForUser(me);
    if (mark != null && game.isEliminated(mark)) return;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.gameSurrenderTitle),
        content: Text(context.l10n.gameSurrenderConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.gameStay),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentStart,
            ),
            child: Text(context.l10n.gameSurrender),
          ),
        ],
      ),
    ).then((ok) {
      if (ok != true || !mounted || !context.mounted) return;
      final gameId = widget.gameId;
      // Не выходим из игры: после forfeit сервер завершит партию, статус
      // обновится и покажется «Вы сдались» + кнопки «Повторить» / «Другой
      // соперник». clearLocal()/context.go здесь нельзя — иначе игрок не
      // увидит итог сдачи.
      unawaited(() async {
        try {
          clearBlockingGamePin(ref, ifGameId: gameId);
          await ref.read(gamesRepositoryProvider).forfeitGame(gameId);
        } catch (_) {}
        if (!mounted) return;
        // Multi: партия ещё идёт — observation, не active.
        final game = ref.read(gameStateOverrideProvider(gameId)) ??
            ref.read(gameStateProvider(gameId)).valueOrNull;
        final multi = (game?.maxPlayers ?? 0) > 2 ||
            (game?.playerUserIds.length ?? 0) > 2;
        if (multi) {
          final prev = ref.read(activeGameProvider).valueOrNull;
          ref.read(activeGameProvider.notifier).setObservationLocal(
                ObservationItem(
                  gameId: gameId,
                  lobbyId: prev?.lobbyId,
                ),
              );
          if (prev?.gameId == gameId) {
            ref.read(activeGameProvider.notifier).clearLocal();
          }
        }
        ref.read(gameStateOverrideProvider(gameId).notifier).state = null;
        ref.invalidate(gameStateProvider(gameId));
        unawaited(ref.read(activeGameProvider.notifier).refresh());
      }());
    });
  }

  void _confirmOfferDraw(BuildContext context) {
    final game = ref.read(gameStateProvider(widget.gameId)).valueOrNull;
    if (game == null || game.status != 'active' || !game.isActivePvp) return;
    final l10n = context.l10n;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.gameOfferDrawTitle),
        content: Text(l10n.gameOfferDrawConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentStart,
            ),
            child: Text(l10n.gameOfferDraw),
          ),
        ],
      ),
    ).then((ok) async {
      if (ok != true || !mounted) return;
      try {
        await ref.read(gamesRepositoryProvider).offerDraw(widget.gameId);
        if (mounted) ref.invalidate(gameStateProvider(widget.gameId));
      } catch (_) {
        if (!mounted) return;
        showAppSnackBar(
          this.context,
          message: l10n.commonGenericError,
          kind: AppSnackKind.error,
        );
      }
    });
  }

  void _confirmAcceptDraw(BuildContext context) {
    final game = ref.read(gameStateProvider(widget.gameId)).valueOrNull;
    if (game == null || game.status != 'active') return;
    final meId = ref.read(authStateProvider).valueOrNull?.id;
    final offerBy = game.drawOfferBy?.trim();
    if (meId == null || offerBy == null || offerBy.isEmpty || offerBy == meId) {
      return;
    }
    final l10n = context.l10n;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.gameAcceptDrawTitle),
        content: Text(l10n.gameAcceptDrawConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentStart,
            ),
            child: Text(l10n.gameDraw),
          ),
        ],
      ),
    ).then((ok) async {
      if (ok != true || !mounted) return;
      try {
        await ref.read(gamesRepositoryProvider).acceptDraw(widget.gameId);
        if (mounted) {
          ref.invalidate(gameStateProvider(widget.gameId));
          ref.invalidate(activeGameProvider);
        }
      } catch (_) {
        if (!mounted) return;
        showAppSnackBar(
          this.context,
          message: l10n.commonGenericError,
          kind: AppSnackKind.error,
        );
      }
    });
  }

  Future<void> _rematch(BuildContext context) async {
    setState(() => _isRematching = true);
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final result = await repo.rematch(widget.gameId);
      if (!mounted) return;
      ref.invalidate(openLobbiesProvider);
      if (result.matched &&
          result.gameId != null &&
          result.gameId!.isNotEmpty) {
        setState(() => _isRematching = false);
        final gameId = result.gameId!;
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(type: 'game', gameId: gameId),
            );
        pinBlockingGame(ref, gameId);
        ref.invalidate(gameStateProvider(gameId));
        if (!context.mounted) return;
        context.go('/games/tictactoe/game/$gameId');
      } else {
        clearBlockingGamePin(ref);
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(type: 'lobby', lobbyId: result.lobbyId),
            );
        final game = ref.read(gameStateOverrideProvider(widget.gameId)) ??
            ref.read(gameStateProvider(widget.gameId)).valueOrNull;
        final multiRematch = (game?.maxPlayers ?? 0) > 2 ||
            (game?.playerUserIds.length ?? 0) > 2;
        setState(() {
          _rematchLobbyId = result.lobbyId;
          _rematchDeclined = false;
          _iDeclinedRematch = false;
          _rematchRespondedIds.clear();
          _isRematching = false;
        });
        // Multi 3/4: сразу «Своя игра» (лобби), без ожидания на доске прошлой партии.
        if (multiRematch) {
          if (!context.mounted) return;
          context.go(
            '/games/tictactoe/lobby/${result.lobbyId}?mode=invite',
          );
          return;
        }
        _startRematchPoll();
      }
    } catch (e) {
      if (mounted) _redirectToGamesOnError();
      if (mounted) setState(() => _isRematching = false);
    }
  }

  Future<void> _acceptRematch(String lobbyId) async {
    if (_isAcceptingRematch) return;
    setState(() => _isAcceptingRematch = true);
    ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
    try {
      final result = await ref.read(gamesRepositoryProvider).joinLobby(lobbyId);
      if (!context.mounted) return;
      if (result.joined && result.waitingMore) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(type: 'lobby', lobbyId: lobbyId),
            );
        ref.invalidate(lobbyDetailProvider(lobbyId));
        unawaited(refreshChatsList(ref, force: true).catchError((_) {}));
        if (!context.mounted) return;
        // ignore: use_build_context_synchronously
        context.go('/games/tictactoe/lobby/$lobbyId?mode=invite');
        return;
      }
      if (result.joined && result.gameId != null) {
        final gameId = result.gameId!;
        ref.invalidate(gameStateProvider(gameId));
        if (!context.mounted) return;
        // ignore: use_build_context_synchronously
        context.go('/games/tictactoe/game/$gameId');
      }
    } on GamesException catch (e) {
      if (!context.mounted) return;
      // 409 = одновременный реванш: соперник уже принял наше приглашение, игра создана
      if (e.statusCode == 409) {
        ref.invalidate(activeGameProvider);
        final active = await ref.read(activeGameProvider.future);
        if (!context.mounted) return;
        if (active != null &&
            active.type == 'game' &&
            active.gameId != null &&
            active.gameId!.isNotEmpty) {
          // ignore: use_build_context_synchronously
          context.go('/games/tictactoe/game/${active.gameId}');
        } else {
          _redirectToGamesOnError();
        }
      } else {
        _redirectToGamesOnError();
      }
    } catch (_) {
      if (context.mounted) _redirectToGamesOnError();
    } finally {
      if (mounted) setState(() => _isAcceptingRematch = false);
    }
  }

  Future<void> _declineRematch(String lobbyId) async {
    ref.read(gameInvitesProvider.notifier).remove(lobbyId);
    try {
      await ref.read(gamesRepositoryProvider).declineLobby(lobbyId);
    } catch (_) {}
    if (mounted) setState(() => _iDeclinedRematch = true);
  }

  Future<void> _cancelRematchWait() async {
    if (_rematchLobbyId == null) return;
    _rematchPollTimer?.cancel();
    final lobbyId = _rematchLobbyId!;
    setState(() {
      _rematchLobbyId = null;
      _rematchRespondedIds.clear();
    });
    try {
      await ref.read(gamesRepositoryProvider).leaveLobby(lobbyId);
    } catch (_) {}
  }

  Future<void> _findGame(BuildContext context) async {
    setState(() => _isFindingGame = true);
    try {
      // Снять ожидание реванша — иначе старое invite-лобби висит параллельно.
      final rematchId = _rematchLobbyId;
      if (rematchId != null) {
        _rematchPollTimer?.cancel();
        setState(() {
          _rematchLobbyId = null;
          _rematchRespondedIds.clear();
        });
        unawaited(
          ref
              .read(gamesRepositoryProvider)
              .leaveLobby(rematchId)
              .catchError((_) {}),
        );
      }

      final game = ref.read(gameStateOverrideProvider(widget.gameId)) ??
          ref.read(gameStateProvider(widget.gameId)).valueOrNull;
      final variant = game?.variant ?? variantClassic;
      final turnTimeSec = game?.turnTimeSec ?? 0;
      final stakeBronze = game?.stakeBronze ?? 1;
      // Всегда matchmake: multi схлопывается на сервере в одно «Лобби».
      const mode = 'matchmake';
      final repo = ref.read(gamesRepositoryProvider);

      // Присоединиться к такому же открытому лобби, если уже есть.
      try {
        final open = await repo.listLobbies();
        LobbyItem? match;
        for (final lobby in open) {
          if (lobby.variant != variant) continue;
          if (lobby.stakeBronze != stakeBronze) continue;
          if (lobby.turnTimeSec != turnTimeSec) continue;
          if (lobby.playersCount >= lobby.maxPlayers) continue;
          match = lobby;
          break;
        }
        if (match != null) {
          final joined = await repo.joinLobby(match.id);
          if (!context.mounted) return;
          ref.invalidate(openLobbiesProvider);
          if (joined.joined &&
              joined.gameId != null &&
              joined.gameId!.isNotEmpty) {
            ref.read(activeGameProvider.notifier).setLocal(
                  ActiveGameItem(
                    type: 'game',
                    gameId: joined.gameId,
                    lobbyId: match.id,
                  ),
                );
            context.go('/games/tictactoe/game/${joined.gameId}');
            return;
          }
          if (joined.joined) {
            ref.read(activeGameProvider.notifier).setLocal(
                  ActiveGameItem(type: 'lobby', lobbyId: match.id),
                );
            context.go('/games/tictactoe/lobby/${match.id}?mode=$mode');
            return;
          }
        }
      } catch (_) {}

      final result = await repo.createLobby(
        mode: mode,
        turnTimeSec: turnTimeSec,
        variant: variant,
        gridSize: gridSizeForVariant(variant),
        stakeBronze: stakeBronze,
        addBotsAfter30s: false,
      );
      if (!context.mounted) return;
      ref.invalidate(openLobbiesProvider);
      if (result.matched && result.gameId != null) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'game',
                gameId: result.gameId,
                lobbyId: result.lobbyId,
              ),
            );
        context.go('/games/tictactoe/game/${result.gameId}');
      } else {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(type: 'lobby', lobbyId: result.lobbyId),
            );
        context.go(
          '/games/tictactoe/lobby/${result.lobbyId}?mode=$mode',
        );
      }
    } on GamesException catch (e) {
      if (!context.mounted) return;
      if (isFinishCurrentGameError(e)) {
        showAppSnackBar(
          context,
          message: finishCurrentGameMessage,
          kind: AppSnackKind.error,
        );
        return;
      }
      _redirectToGamesOnError();
    } catch (e) {
      if (context.mounted) _redirectToGamesOnError();
    } finally {
      if (mounted) setState(() => _isFindingGame = false);
    }
  }

  void _redirectToGamesOnError() {
    if (mounted) context.go('/games');
  }

  /// Снять сессию оконченной партии: пин, active, observation.
  void _clearSessionForFinishedGame() {
    clearBlockingGamePin(ref, ifGameId: widget.gameId);
    final prev = ref.read(activeGameProvider).valueOrNull;
    if (prev?.gameId == widget.gameId) {
      ref.read(activeGameProvider.notifier).clearLocal();
    }
    ref
        .read(activeGameProvider.notifier)
        .clearObservationLocal(ifGameId: widget.gameId);
  }

  void _handleClose(GameStateItem? game) {
    final isOver = game?.status != 'active';
    final me = ref.read(authStateProvider).valueOrNull?.id;
    final mark = game?.markForUser(me);
    final eliminated =
        mark != null && game != null && game.isEliminated(mark);
    // Выбывший / партия окончена — без предупреждения «проиграете».
    if (isOver || eliminated) {
      final rematchLobbyId = _rematchLobbyId;
      _rematchLobbyId = null;
      _rematchRespondedIds.clear();
      if (eliminated && !isOver) {
        // Партия ещё идёт — observation до закрытия.
        clearBlockingGamePin(ref, ifGameId: widget.gameId);
        final prev = ref.read(activeGameProvider).valueOrNull;
        ref.read(activeGameProvider.notifier).setObservationLocal(
              ObservationItem(
                gameId: widget.gameId,
                lobbyId: prev?.lobbyId,
              ),
            );
        if (prev?.gameId == widget.gameId) {
          ref.read(activeGameProvider.notifier).clearLocal();
        }
      } else {
        _clearSessionForFinishedGame();
      }
      context.go('/games');
      if (rematchLobbyId != null) {
        unawaited(
          ref
              .read(gamesRepositoryProvider)
              .leaveLobby(rematchLobbyId)
              .catchError((_) {}),
        );
      }
      return;
    }
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.gameExitTitle),
        content: Text(
          context.l10n.gameExitConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.gameStay),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentStart,
            ),
            child: Text(context.l10n.gameLeave),
          ),
        ],
      ),
    ).then((exit) async {
      if (exit != true || !mounted) return;
      final gameId = widget.gameId;
      // Сначала forfeit — иначе у остальных партия «зависает» без WS.
      try {
        await ref.read(gamesRepositoryProvider).forfeitGame(gameId);
      } catch (_) {}
      if (!mounted) return;
      clearBlockingGamePin(ref, ifGameId: gameId);
      final game = ref.read(gameStateOverrideProvider(gameId)) ??
          ref.read(gameStateProvider(gameId)).valueOrNull;
      final multi = (game?.maxPlayers ?? 0) > 2 ||
          (game?.playerUserIds.length ?? 0) > 2;
      if (multi && game?.status == 'active') {
        // Multi: observation, пока партия не закончится.
        final prev = ref.read(activeGameProvider).valueOrNull;
        ref.read(activeGameProvider.notifier).setObservationLocal(
              ObservationItem(
                gameId: gameId,
                lobbyId: prev?.lobbyId,
              ),
            );
        if (prev?.gameId == gameId) {
          ref.read(activeGameProvider.notifier).clearLocal();
        }
      } else {
        ref.read(activeGameProvider.notifier).clearLocal();
        ref
            .read(activeGameProvider.notifier)
            .clearObservationLocal(ifGameId: gameId);
      }
      context.go('/games');
      unawaited(ref.read(activeGameProvider.notifier).refresh());
    });
  }

  void _showOpponentInfo(
    BuildContext context, {
    required String opponentId,
    required String displayName,
    required String avatarKind,
    required String? avatarValue,
    String? frameCode,
    String? frameColor,
  }) {
    unawaited(
      showUserProfileDialog(
        context: context,
        ref: ref,
        userId: opponentId,
        displayName: displayName,
        avatarKind: avatarKind,
        avatarValue: avatarValue,
        frameCode: frameCode,
        frameColor: frameColor,
        messageReturnPath: '/games/tictactoe/game/${widget.gameId}',
        messageFrom: 'games',
      ),
    );
  }

  Future<void> _addFriend(
    BuildContext ctx,
    String userId,
    String displayName, {
    String? requestId,
    void Function()? onSuccess,
  }) async {
    try {
      if (requestId != null && requestId.isNotEmpty) {
        await ref.read(friendsRepositoryProvider).acceptRequest(requestId);
        if (!mounted) return;
        onSuccess?.call();
        ref.invalidate(friendsSnapshotProvider);
        if (mounted) {
          showAppSnackBar(
            context,
            message: context.l10n.friendsRequestAccepted,
            kind: AppSnackKind.success,
          );
        }
      } else {
        await ref.read(friendsRepositoryProvider).sendRequest(userId);
        if (!mounted) return;
        onSuccess?.call();
        ref.invalidate(friendsSnapshotProvider);
        if (mounted) {
          showAppSnackBar(
            context,
            message: context.l10n.friendsRequestSent,
            kind: AppSnackKind.success,
          );
        }
      }
    } catch (e) {
      if (mounted) _redirectToGamesOnError();
    }
  }

  void _showGameRules(BuildContext context) {
    final game = ref.read(gameStateProvider(widget.gameId)).valueOrNull;
    if (game == null) return;
    final isDesktop = MediaQuery.sizeOf(context).width >= 700;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 80 : 14,
          vertical: isDesktop ? 40 : 20,
        ),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 380 : double.infinity,
          ),
          child: GradientCard(
            animate: false,
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.gamesRulesTitle,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.commonClose,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  child: buildTictactoeRulesTextWidget(
                    variant: game.variant,
                    gridSize: game.gridSize,
                    turnTimeSec: game.turnTimeSec,
                    swapRule: false,
                    firstMoveRestriction: false,
                    stakeBronze: game.stakeBronze,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openChat(
    BuildContext ctx,
    String userId,
    String displayName, {
    void Function()? onSuccess,
  }) async {
    try {
      final chatId = await ref.read(chatsRepositoryProvider).startChat(userId);
      if (!mounted) return;
      onSuccess?.call();
      if (mounted && chatId.isNotEmpty) {
        final uri = Uri(
          path: '/chats/$chatId',
          queryParameters: {
            'name': displayName,
            'from': 'games',
            'game': '/games/tictactoe/game/${widget.gameId}',
          },
        );
        context.push(uri.toString());
      }
    } catch (e) {
      if (mounted) _redirectToGamesOnError();
    }
  }

  void _openGroupChat(BuildContext ctx, GameStateItem game) {
    final chatId = (game.chatId ?? '').trim();
    if (chatId.isEmpty) return;
    unawaited(refreshChatsList(ref, force: true).catchError((_) {}));
    final uri = Uri(
      path: '/chats/$chatId',
      queryParameters: {
        'name': variantLabel(game.variant),
        'from': 'games',
        'game': '/games/tictactoe/game/${widget.gameId}',
      },
    );
    ctx.push(uri.toString());
  }

  Future<void> _makeMove(int cell) async {
    setState(() => _isMakingMove = true);
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final response = await repo.makeMove(widget.gameId, cell);
      if (!mounted) return;
      final isBotGame =
          response.playerUserIds.any((id) => id.startsWith('bot:'));
      // Для бота: сразу блокируем invalidate, чтобы realtime/другие события не сбросили ход
      if (isBotGame) {
        _waitingForBotMove = true;
        ref
            .read(gameStateInvalidateBlockedProvider(widget.gameId).notifier)
            .state = true;
      }
      // Сразу показываем свой ход (через override)
      ref.read(gameStateOverrideProvider(widget.gameId).notifier).state =
          response;
      setState(() {}); // Принудительный ребилд, чтобы ход отрисовался сразу
      if (response.status != 'active') {
        ref.invalidate(gameStateProvider(widget.gameId));
        ref.invalidate(activeGameProvider);
      } else if (isBotGame) {
        // С ботом: ~1.5 сек задержка (бот ходит ~1 сек), затем запрос хода бота
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          _waitingForBotMove = false;
          ref
              .read(gameStateInvalidateBlockedProvider(widget.gameId).notifier)
              .state = false;
          ref.invalidate(gameStateProvider(widget.gameId));
          ref.invalidate(activeGameProvider);
        });
      } else {
        // PvP: override уже с новым turn/доской. Немедленный invalidate
        // гоняется со старым AsyncValue и снова показывает «Ваш ход».
        // Свежие данные подтянет WS game_state или sync-таймер.
        ref.invalidate(activeGameProvider);
      }
    } catch (e) {
      if (mounted) _redirectToGamesOnError();
    } finally {
      if (mounted) setState(() => _isMakingMove = false);
    }
  }
}

class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final int badge;

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    final btn = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.accentStart,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(size, size),
        fixedSize: const Size(size, size),
      ),
    );
    if (badge <= 0) return SizedBox(width: size, height: size, child: btn);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          btn,
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RematchSection extends StatelessWidget {
  const _RematchSection({
    required this.rematchLobbyId,
    required this.rematchDeclined,
    required this.iDeclinedRematch,
    required this.isRematching,
    required this.isAcceptingRematch,
    required this.isFindingGame,
    required this.peerIds,
    required this.invites,
    required this.onRematch,
    required this.onAccept,
    required this.onDecline,
    required this.onCancelWait,
    required this.onFindGame,
    this.compact = false,
  });

  final String? rematchLobbyId;
  final bool rematchDeclined;
  final bool iDeclinedRematch;
  final bool isRematching;
  final bool isAcceptingRematch;
  final bool isFindingGame;
  /// Все соперники прошлой партии (для multi — несколько).
  final List<String> peerIds;
  final List<GameInvite> invites;
  final VoidCallback onRematch;
  final void Function(String lobbyId) onAccept;
  final void Function(String lobbyId) onDecline;
  final VoidCallback? onCancelWait;
  final VoidCallback onFindGame;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final peerSet = peerIds.toSet();
    // Реванш от любого участника прошлой партии (не только «первого» x/o).
    final rematchOffer =
        invites.where((i) => peerSet.contains(i.creatorId)).firstOrNull;

    // После нажатия «Принять» показываем часики до перехода в игру
    if (isAcceptingRematch) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_empty_rounded,
              size: 20, color: AppColors.accentStart),
          const SizedBox(width: 8),
          Text(
            context.l10n.gameConnecting,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    // Приглашение соперника показываем всегда, даже если ранее отклоняли — новое предложение.
    if (rematchOffer != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.gameRematchOffer,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: compact ? 13 : 14,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => onDecline(rematchOffer.lobbyId),
                child: Text(context.l10n.commonDecline),
              ),
              SizedBox(width: compact ? 8 : 12),
              FilledButton(
                onPressed: () => onAccept(rematchOffer.lobbyId),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentStart,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.l10n.commonAccept),
              ),
            ],
          ),
        ],
      );
    }
    if (iDeclinedRematch) {
      return _buildRematchButtons(
        context,
        isRematching: isRematching,
        isFindingGame: isFindingGame,
        onRematch: onRematch,
        onFindGame: onFindGame,
        compact: compact,
      );
    }
    if (rematchDeclined) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.gameRematchDeclined,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: compact ? 13 : 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: compact ? 8 : 12),
          _buildRematchButtons(
            context,
            isRematching: isRematching,
            isFindingGame: isFindingGame,
            onRematch: onRematch,
            onFindGame: onFindGame,
            compact: compact,
          ),
        ],
      );
    }
    if (rematchLobbyId != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_empty_rounded,
                  size: compact ? 18 : 20, color: AppColors.accentStart),
              SizedBox(width: compact ? 6 : 8),
              Text(
                context.l10n.gameWaitingOpponent,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (onCancelWait != null) ...[
            SizedBox(height: compact ? 8 : 12),
            TextButton(
              onPressed: onCancelWait,
              child: Text(context.l10n.commonCancel),
            ),
          ],
        ],
      );
    }
    return _buildRematchButtons(
      context,
      isRematching: isRematching,
      isFindingGame: isFindingGame,
      onRematch: onRematch,
      onFindGame: onFindGame,
      compact: compact,
    );
  }

  Widget _buildRematchButtons(
    BuildContext context, {
    required bool isRematching,
    required bool isFindingGame,
    required VoidCallback onRematch,
    required VoidCallback onFindGame,
    bool compact = false,
  }) {
    final btnPadding = compact
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: compact ? 8 : 12,
      runSpacing: compact ? 6 : 8,
      children: [
        FilledButton.icon(
          onPressed: isRematching ? null : onRematch,
          icon: isRematching
              ? SizedBox(
                  width: compact ? 16 : 18,
                  height: compact ? 16 : 18,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(Icons.replay_rounded, size: compact ? 18 : 20),
          label: Text(isRematching
              ? context.l10n.commonCreating
              : context.l10n.gameRematch),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentStart,
            foregroundColor: Colors.white,
            padding: btnPadding,
          ),
        ),
        OutlinedButton.icon(
          onPressed: isFindingGame ? null : onFindGame,
          icon: isFindingGame
              ? SizedBox(
                  width: compact ? 16 : 18,
                  height: compact ? 16 : 18,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.search_rounded, size: compact ? 18 : 20),
          label: Text(isFindingGame
              ? context.l10n.commonSearching
              : context.l10n.gameOtherOpponent),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentStart,
            side: BorderSide(color: AppColors.accentStart),
            padding: btnPadding,
          ),
        ),
      ],
    );
  }
}

/// Логин игрока: мета игры → участники группового чата → direct-чат.
/// Пустая строка, если имени нет (не подставляем «Соперник» в список).
String _resolvePlayerLogin(
  GamePlayerMeta? player, {
  required List<ChatPreviewItem> chatsList,
  String? chatId,
}) {
  if (player == null) return '';
  final fromMeta = player.displayName?.trim() ?? '';
  if (fromMeta.isNotEmpty) return fromMeta;
  final userId = player.userId.trim();
  if (userId.isEmpty) return '';
  final groupId = chatId?.trim() ?? '';
  if (groupId.isNotEmpty) {
    for (final chat in chatsList) {
      if (chat.chatID != groupId) continue;
      for (final member in chat.members) {
        if (member.id != userId) continue;
        final name = member.displayName?.trim() ?? '';
        if (name.isNotEmpty) return name;
      }
    }
  }
  for (final chat in chatsList) {
    if (chat.user.id == userId) {
      final name = chat.user.displayName?.trim() ?? '';
      if (name.isNotEmpty) return name;
    }
    for (final member in chat.members) {
      if (member.id != userId) continue;
      final name = member.displayName?.trim() ?? '';
      if (name.isNotEmpty) return name;
    }
  }
  return '';
}

class _MultiOpponentsCard extends StatelessWidget {
  const _MultiOpponentsCard({
    required this.game,
    required this.opponents,
    this.rematchRespondedIds = const <String>{},
    required this.chatsList,
    required this.groupUnread,
    required this.showGroupChat,
    required this.onGroupChatTap,
    this.onPlayerTap,
  });

  final GameStateItem game;
  final List<GamePlayerMeta> opponents;
  final Set<String> rematchRespondedIds;
  final List<ChatPreviewItem> chatsList;
  final int groupUnread;
  final bool showGroupChat;
  final VoidCallback? onGroupChatTap;
  final void Function(GamePlayerMeta player, String login)? onPlayerTap;

  @override
  Widget build(BuildContext context) {
    final groupBadge = groupUnread;
    final narrow = isNarrow(context);
    final chips = <Widget>[];
    for (final player in opponents) {
      final login = _resolvePlayerLogin(
        player,
        chatsList: chatsList,
        chatId: game.chatId,
      );
      // Без логина не рисуем «Соперник» — пропускаем слот.
      if (login.isEmpty) continue;
      if (chips.isNotEmpty) {
        chips.add(SizedBox(width: narrow ? 8 : 10));
      }
      final responded = rematchRespondedIds.contains(player.userId);
      chips.add(
        _MultiOpponentChip(
          displayName: login,
          player: player,
          eliminated: game.isEliminated(player.mark) || responded,
          compact: true,
          onTap: onPlayerTap == null
              ? null
              : () => onPlayerTap!(player, login),
        ),
      );
    }
    if (chips.isEmpty && !showGroupChat) {
      return const SizedBox.shrink();
    }
    final card = GradientCard(
      padding: EdgeInsets.symmetric(
        horizontal: narrow ? 8 : 12,
        vertical: narrow ? 4 : 6,
      ),
      margin: EdgeInsets.zero,
      animate: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: chips,
              ),
            ),
          ),
          if (showGroupChat)
            _IconWithBadge(
              icon: Icons.forum_rounded,
              badge: groupBadge,
              tooltip: 'Чат группы',
              onPressed: onGroupChatTap,
            ),
        ],
      ),
    );
    if (isWide(context)) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: card,
        ),
      );
    }
    return card;
  }
}

class _MultiOpponentChip extends StatelessWidget {
  const _MultiOpponentChip({
    required this.displayName,
    required this.player,
    required this.eliminated,
    this.compact = false,
    this.onTap,
  });

  final String displayName;
  final GamePlayerMeta player;
  final bool eliminated;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _OpponentAvatar(
          displayName: displayName,
          avatarKind: player.avatarKind,
          avatarValue: player.avatarValue,
          frameCode: player.frameCode,
          frameColor: player.frameColor,
          compact: compact,
        ),
        SizedBox(width: compact ? 5 : 8),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 78 : 120),
          child: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 13 : 15,
              decoration: eliminated ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ],
    );
    final chip = Opacity(
      opacity: eliminated ? 0.45 : 1,
      child: content,
    );
    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: chip,
        ),
      ),
    );
  }
}

class _OpponentCard extends StatelessWidget {
  const _OpponentCard({
    required this.opponentId,
    required this.displayName,
    required this.avatarKind,
    required this.avatarValue,
    this.frameCode,
    this.frameColor,
    this.isBot = false,
    required this.friendsSnapshot,
    required this.messageUnread,
    required this.onInfoTap,
    required this.onMessageTap,
    required this.onAddFriendTap,
  });

  final String opponentId;
  final String displayName;
  final String avatarKind;
  final String? avatarValue;
  final String? frameCode;
  final String? frameColor;
  final bool isBot;
  final FriendsSnapshot? friendsSnapshot;
  final int messageUnread;
  final VoidCallback onInfoTap;
  final VoidCallback onMessageTap;
  final void Function(String? requestId) onAddFriendTap;

  @override
  Widget build(BuildContext context) {
    final isFriend =
        friendsSnapshot?.friends.any((f) => f.user.id == opponentId) == true;
    final outgoing = friendsSnapshot?.outgoing
            .where((r) => r.user.id == opponentId)
            .toList() ??
        [];
    final incoming = friendsSnapshot?.incoming
            .where((r) => r.user.id == opponentId)
            .toList() ??
        [];
    final hasOutgoing = outgoing.isNotEmpty;
    final hasIncoming = incoming.isNotEmpty;
    final incomingRequestId = hasIncoming ? incoming.first.requestId : null;
    final addFriendEnabled = !hasOutgoing;
    final messageBadge = messageUnread;

    final narrow = isNarrow(context);
    final card = GradientCard(
      padding: EdgeInsets.symmetric(
        horizontal: narrow ? 12 : 16,
        vertical: narrow ? 8 : 12,
      ),
      margin: EdgeInsets.zero,
      animate: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Tooltip(
            message: context.l10n.userInfoTitle,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onInfoTap,
                behavior: HitTestBehavior.opaque,
                child: _OpponentAvatar(
                  displayName: displayName,
                  avatarKind: avatarKind,
                  avatarValue: avatarValue,
                  frameCode: frameCode,
                  frameColor: frameColor,
                  compact: narrow,
                ),
              ),
            ),
          ),
          SizedBox(width: narrow ? 10 : 14),
          Flexible(
            child: Text(
              displayName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: narrow ? 14 : 16,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isBot) ...[
            _IconWithBadge(
              icon: Icons.chat_bubble_outline_rounded,
              badge: messageBadge,
              tooltip: context.l10n.gameWriteMessage,
              onPressed: onMessageTap,
            ),
            if (!isFriend)
              _IconWithBadge(
                icon: Icons.person_add_alt_1_rounded,
                badge: hasIncoming ? 1 : 0,
                tooltip: hasIncoming
                    ? context.l10n.friendsAcceptRequest
                    : (addFriendEnabled
                        ? context.l10n.friendsAdd
                        : context.l10n.friendsRequestSent),
                onPressed: addFriendEnabled
                    ? () =>
                        onAddFriendTap(hasIncoming ? incomingRequestId : null)
                    : null,
              ),
          ],
        ],
      ),
    );
    if (isWide(context)) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: card,
        ),
      );
    }
    return card;
  }
}

class _OpponentAvatar extends StatelessWidget {
  const _OpponentAvatar({
    required this.displayName,
    required this.avatarKind,
    required this.avatarValue,
    this.frameCode,
    this.frameColor,
    this.compact = false,
  });

  final String displayName;
  final String avatarKind;
  final String? avatarValue;
  final String? frameCode;
  final String? frameColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final r = compact ? 18.0 : 22.0;
    Widget avatar;
    if (avatarKind == 'file' &&
        avatarValue != null &&
        avatarValue!.trim().isNotEmpty) {
      final img = AvatarMemoryCache.fromAvatarValue(avatarValue);
      if (img != null) {
        avatar = CircleAvatar(
          radius: r,
          backgroundImage: img,
        );
      } else {
        avatar = _letter(r);
      }
    } else if (avatarKind == 'preset' && avatarValue != null) {
      final idx = int.tryParse(avatarValue!);
      if (idx != null && idx >= 0 && idx < _presetAvatarIcons.length) {
        avatar = CircleAvatar(
          radius: r,
          backgroundColor: AppColors.accentSoft,
          child: Icon(_presetAvatarIcons[idx], color: AppColors.accentStart),
        );
      } else {
        avatar = _letter(r);
      }
    } else {
      avatar = _letter(r);
    }
    return FramedAvatar(
      size: r * 2,
      borderWidth: compact ? 2.4 : 3.0,
      frameCode: frameCode,
      frameColor: frameColor,
      animate: false,
      child: avatar,
    );
  }

  Widget _letter(double r) {
    final letter =
        displayName.trim().isEmpty ? '?' : displayName[0].toUpperCase();
    return CircleAvatar(
      radius: r,
      backgroundColor: AppColors.accentSoft,
      child: Text(
        letter,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 14 : 16,
        ),
      ),
    );
  }
}

class _GameBoard extends StatefulWidget {
  const _GameBoard({
    required this.game,
    required this.isMyTurn,
    required this.isOver,
    required this.isMakingMove,
    required this.onMove,
    required this.pulseController,
    this.compact = false,
  });

  final GameStateItem game;
  final bool isMyTurn;
  final bool isOver;
  final bool isMakingMove;
  final ValueChanged<int> onMove;
  final AnimationController? pulseController;
  final bool compact;

  @override
  State<_GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<_GameBoard>
    with SingleTickerProviderStateMixin {
  final TransformationController _transform = TransformationController();
  AnimationController? _resetController;
  Animation<Matrix4>? _resetAnimation;

  bool get _zoomableVariant {
    final v = widget.game.variant;
    return v == variantGomoku || v == variantUltimate;
  }

  bool get _interactionEnabled =>
      _zoomableVariant &&
      widget.isMyTurn &&
      !widget.isOver &&
      !widget.isMakingMove;

  @override
  void didUpdateWidget(covariant _GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Чужой ход / конец партии — только «во весь экран», без зума.
    if ((oldWidget.isMyTurn && !widget.isMyTurn) ||
        (!oldWidget.isOver && widget.isOver) ||
        (oldWidget.isMakingMove && !widget.isMakingMove && !widget.isMyTurn)) {
      _snapToFit(animate: true);
    }
  }

  @override
  void dispose() {
    _resetController?.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _snapToFit({bool animate = true}) {
    final current = _transform.value.clone();
    if (_isNearIdentity(current)) {
      _transform.value = Matrix4.identity();
      return;
    }
    if (!animate || !mounted) {
      _transform.value = Matrix4.identity();
      return;
    }
    _resetController?.dispose();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _resetAnimation = Matrix4Tween(
      begin: current,
      end: Matrix4.identity(),
    ).animate(CurvedAnimation(
      parent: _resetController!,
      curve: Curves.easeOutCubic,
    ));
    void tick() {
      if (!mounted || _resetAnimation == null) return;
      _transform.value = _resetAnimation!.value;
    }

    _resetController!
      ..addListener(tick)
      ..forward().whenCompleteOrCancel(() {
        if (!mounted) return;
        _transform.value = Matrix4.identity();
        _resetController?.removeListener(tick);
      });
  }

  bool _isNearIdentity(Matrix4 m) {
    final scale = m.getMaxScaleOnAxis();
    final t = m.getTranslation();
    return scale <= 1.02 && t.x.abs() < 1.5 && t.y.abs() < 1.5;
  }

  void _onInteractionEnd(ScaleEndDetails _) {
    if (!_zoomableVariant) return;
    final scale = _transform.value.getMaxScaleOnAxis();
    // Максимальное отдаление = ровно «во весь экран».
    if (scale <= 1.05) {
      _snapToFit(animate: true);
    }
  }

  void _handleMove(int cell) {
    // После хода сразу возвращаем доску в кадр.
    _snapToFit(animate: true);
    widget.onMove(cell);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final isMyTurn = widget.isMyTurn;
    final isOver = widget.isOver;
    final isMakingMove = widget.isMakingMove;
    final pulseController = widget.pulseController;
    final compact = widget.compact;

    final gridSize = game.gridSize;
    final isUltimate = game.variant == variantUltimate;
    final n = game.board.length;
    final engine = newEngine(game.variant);
    final legalCells = isMyTurn && !isOver && !isMakingMove
        ? engine
            .legalCells(
              GameEngineState(
                board: game.board,
                turn: game.turn,
                status: game.status,
                winner: game.winner ?? '',
                nextBoard: game.nextBoard ?? -1,
                metaBoard: game.metaBoard,
              ),
            )
            .toSet()
        : const <int>{};
    return LayoutBuilder(
      builder: (context, constraints) {
        var maxW = constraints.maxWidth;
        var maxH = constraints.maxHeight;
        if (!maxW.isFinite || maxW <= 0) maxW = 400;
        if (!maxH.isFinite || maxH <= 0) maxH = 400;
        final minBoard = compact ? 140.0 : 180.0;
        final viewportSize =
            (maxW < maxH ? maxW : maxH).clamp(minBoard, 2000.0).toDouble();
        final boardSize = viewportSize;
        final board = Container(
          width: boardSize,
          height: boardSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  compact
                      ? (gridSize >= 10 ? 4.0 : 6.0)
                      : (gridSize >= 10
                          ? 6.0
                          : (boardSize > 280 ? 12.0 : 8.0)),
                ),
                child: _WinningLineOverlay(
                  winningCells: game.effectiveWinningCells,
                  gridSize: gridSize,
                  child: CustomPaint(
                    painter: _GridPainter(
                      gridSize: gridSize,
                      ultimate: isUltimate,
                    ),
                    child: LayoutBuilder(
                      builder: (context, innerConstraints) {
                        final cellW = innerConstraints.maxWidth / gridSize;
                        final cellH = innerConstraints.maxHeight / gridSize;
                        final gap = gridSize >= 10
                            ? 1.0
                            : (boardSize > 280
                                ? (gridSize >= 8 ? 1.5 : 4.0)
                                : 2.0);
                        final cells = List.generate(n, (visualIndex) {
                          final cellIndex = isUltimate
                              ? _ultimateCellFromVisualIndex(visualIndex)
                              : visualIndex;
                          final row = visualIndex ~/ gridSize;
                          final col = visualIndex % gridSize;
                          final cell = cellIndex < game.board.length
                              ? game.board[cellIndex]
                              : '';
                          final sub = isUltimate ? cellIndex ~/ 9 : -1;
                          final meta = isUltimate && sub >= 0
                              ? (sub < game.metaBoard.length
                                  ? game.metaBoard[sub]
                                  : '')
                              : '';
                          final cellCanTap =
                              cell.isEmpty && legalCells.contains(cellIndex);
                          return Positioned(
                            left: col * cellW + gap,
                            top: row * cellH + gap,
                            width: cellW - gap * 2,
                            height: cellH - gap * 2,
                            child: _AnimatedGameCell(
                              symbol: cell,
                              isMyTurn: isMyTurn && !isOver && !isMakingMove,
                              canTap: cellCanTap,
                              isForbidden: cell.isEmpty &&
                                  isMyTurn &&
                                  !isOver &&
                                  !isMakingMove &&
                                  !cellCanTap,
                              isActiveBoard: isUltimate &&
                                  game.nextBoard != null &&
                                  game.nextBoard == sub,
                              isClosedBoard: meta.isNotEmpty,
                              onTap:
                                  cellCanTap ? () => _handleMove(cellIndex) : null,
                              pulse: cellCanTap ? pulseController : null,
                            ),
                          );
                        });
                        return Stack(
                          children: [
                            ...cells,
                            if (isUltimate)
                              _UltimateMetaOverlay(metaBoard: game.metaBoard),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        return Center(
          child: SizedBox.square(
            dimension: viewportSize,
            child: _zoomableVariant
                ? InteractiveViewer(
                    transformationController: _transform,
                    // scale=1: доска = viewport → с boundaryMargin=0 пан
                    // невозможен; при зуме край доски не уезжает за кадр.
                    boundaryMargin: EdgeInsets.zero,
                    minScale: 1,
                    maxScale: 3.5,
                    // Зум/пан только на своём ходе.
                    scaleEnabled: _interactionEnabled,
                    panEnabled: _interactionEnabled,
                    clipBehavior: Clip.hardEdge,
                    onInteractionEnd: _onInteractionEnd,
                    child: board,
                  )
                : board,
          ),
        );
      },
    );
  }
}

int _ultimateCellFromVisualIndex(int visualIndex) {
  final visualRow = visualIndex ~/ 9;
  final visualCol = visualIndex % 9;
  final subRow = visualRow ~/ 3;
  final subCol = visualCol ~/ 3;
  final localRow = visualRow % 3;
  final localCol = visualCol % 3;
  return (subRow * 3 + subCol) * 9 + localRow * 3 + localCol;
}

class _UltimateMetaOverlay extends StatelessWidget {
  const _UltimateMetaOverlay({required this.metaBoard});

  final List<String> metaBoard;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final subW = constraints.maxWidth / 3;
          final subH = constraints.maxHeight / 3;
          return Stack(
            children: List.generate(9, (sub) {
              final mark = sub < metaBoard.length ? metaBoard[sub] : '';
              if (mark.isEmpty) return const SizedBox.shrink();
              final row = sub ~/ 3;
              final col = sub % 3;
              return Positioned(
                left: col * subW,
                top: row * subH,
                width: subW,
                height: subH,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: mark == 'd'
                        ? Colors.black.withValues(alpha: 0.06)
                        : AppColors.accentSoft.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: mark == 'd'
                      ? const Center(
                          child: Text(
                            '=',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : Center(
                          child: Opacity(
                            opacity: 0.38,
                            child: SizedBox.square(
                              dimension: math.min(subW, subH) * 0.48,
                              child: CustomPaint(
                                painter: _SymbolPainter(
                                  symbol: mark,
                                  color: _symbolColor(mark),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _WinningLineOverlay extends StatefulWidget {
  const _WinningLineOverlay({
    required this.winningCells,
    required this.gridSize,
    required this.child,
  });

  final List<int>? winningCells;
  final int gridSize;
  final Widget child;

  @override
  State<_WinningLineOverlay> createState() => _WinningLineOverlayState();
}

class _WinningLineOverlayState extends State<_WinningLineOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wc = widget.winningCells;
    if (wc == null || wc.length < 3) {
      return widget.child;
    }
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return CustomPaint(
                  painter: _WinningLinePainter(
                    winningCells: wc,
                    gridSize: widget.gridSize,
                    progress: _animation.value,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _WinningLinePainter extends CustomPainter {
  _WinningLinePainter({
    required this.winningCells,
    required this.gridSize,
    required this.progress,
  });

  final List<int> winningCells;
  final int gridSize;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (winningCells.length < 3 || size.width <= 0 || size.height <= 0) {
      return;
    }
    final cellW = size.width / gridSize;
    final cellH = size.height / gridSize;
    final points = winningCells.map((i) {
      final row = i ~/ gridSize;
      final col = i % gridSize;
      return Offset(
        (col + 0.5) * cellW,
        (row + 0.5) * cellH,
      );
    }).toList();

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final pathMetrics = path.computeMetrics();
    final totalLength = pathMetrics.isEmpty ? 0.0 : pathMetrics.first.length;
    final drawLength = totalLength * progress;

    final lineWidth = gridSize <= 3 ? 6.0 : (gridSize == 4 ? 5.0 : 4.0);
    final glowPaint = Paint()
      ..color = AppColors.accentStart.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth + 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final strokePaint = Paint()
      ..color = AppColors.accentStart
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (drawLength > 0 && pathMetrics.isNotEmpty) {
      final extractPath = pathMetrics.first.extractPath(0.0, drawLength);
      canvas.drawPath(extractPath, glowPaint);
      canvas.drawPath(extractPath, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WinningLinePainter old) =>
      old.progress != progress ||
      old.winningCells != winningCells ||
      old.gridSize != gridSize;
}

/// Статус партии и награда в одной строке.
class _StatusWithReward extends StatelessWidget {
  const _StatusWithReward({
    required this.statusText,
    required this.showReward,
    required this.rewardBronze,
    required this.rewardKey,
    this.statusMark,
    this.fontSize,
  });

  final String statusText;
  final String? statusMark;
  final bool showReward;
  final int rewardBronze;
  final GlobalKey rewardKey;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          fontSize: fontSize,
        );
    final mark = (statusMark ?? '').trim().toLowerCase();
    final markSize = fontSize != null ? 22.0 : 26.0;
    final markWidget = mark.isEmpty
        ? null
        : SizedBox(
            width: markSize,
            height: markSize,
            child: _SymbolWidget(symbol: mark),
          );
    // Обычный вес, перенос строк разрешён (длинные статусы вроде
    // «Вы победили, время соперника вышло» переносятся на вторую строку).
    if (!showReward && markWidget == null) {
      return Text(
        statusText,
        textAlign: TextAlign.center,
        style: style,
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (markWidget != null) ...[
          markWidget,
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            statusText,
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
        if (showReward) ...[
          const SizedBox(width: 8),
          _GameRewardChip(
            key: rewardKey,
            rewardBronze: rewardBronze,
          ),
        ],
      ],
    );
  }
}

/// Чип чистого выигрыша (= stake*(N-1)) — источник полёта монеты в баланс.
class _GameRewardChip extends StatelessWidget {
  const _GameRewardChip({
    super.key,
    required this.rewardBronze,
  });

  final int rewardBronze;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.accentSoft.withValues(alpha: 0.9),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+${formatStakeAmount(rewardBronze)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 5),
          CoinIcon(
            coinType: stakeCoinType(rewardBronze),
            size: 20,
            showBorder: true,
          ),
        ],
      ),
    );
  }
}

/// Overlay «сдаться» и «ничья» справа сверху под кнопкой «правила».
/// Кнопки идут вертикально. Когда соперник предложил ничью, иконка ничьи
/// у принимающего мигает фиолетовый↔чёрный (анимация ColorTween).
class _GameActionsOverlay extends StatefulWidget {
  const _GameActionsOverlay({
    required this.canDraw,
    required this.iOfferedDraw,
    required this.opponentOfferedDraw,
    required this.onSurrender,
    required this.onDraw,
  });

  final bool canDraw;
  final bool iOfferedDraw;
  final bool opponentOfferedDraw;
  final VoidCallback onSurrender;
  final VoidCallback onDraw;

  @override
  State<_GameActionsOverlay> createState() => _GameActionsOverlayState();
}

class _GameActionsOverlayState extends State<_GameActionsOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;
  late final Animation<Color?> _color;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _color = ColorTween(
      begin: AppColors.accentStart,
      end: AppColors.textPrimary,
    ).animate(_blink);
    _applyBlink();
  }

  @override
  void didUpdateWidget(covariant _GameActionsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.opponentOfferedDraw != widget.opponentOfferedDraw) {
      _applyBlink();
    }
  }

  void _applyBlink() {
    if (widget.opponentOfferedDraw) {
      _blink.repeat(reverse: true);
    } else {
      _blink.stop();
      _blink.value = 0;
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          iconSize: 22,
          icon: const Icon(Icons.flag_outlined),
          tooltip: context.l10n.gameSurrender,
          onPressed: widget.onSurrender,
        ),
        if (widget.canDraw) ...[
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _color,
            builder: (_, child) => child!,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              iconSize: 22,
              icon: Icon(
                widget.opponentOfferedDraw
                    ? Icons.handshake_rounded
                    : Icons.handshake_outlined,
                color: widget.opponentOfferedDraw
                    ? _color.value
                    : (widget.iOfferedDraw
                        ? AppColors.accentStart.withValues(alpha: 0.45)
                        : null),
              ),
              tooltip: widget.opponentOfferedDraw
                  ? context.l10n.gameAcceptDrawTitle
                  : (widget.iOfferedDraw
                      ? context.l10n.gameDrawOffered
                      : context.l10n.gameOfferDraw),
              onPressed: widget.iOfferedDraw ? null : widget.onDraw,
            ),
          ),
        ],
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.gridSize, this.ultimate = false});
  final int gridSize;
  final bool ultimate;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentSoft.withValues(alpha: 0.8)
      ..strokeWidth = gridSize <= 3 ? 3 : (gridSize == 4 ? 2.5 : 2)
      ..style = PaintingStyle.stroke;
    final thickPaint = Paint()
      ..color = AppColors.accentStart.withValues(alpha: 0.45)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final cellW = w / gridSize;
    final cellH = h / gridSize;

    for (var i = 1; i < gridSize; i++) {
      canvas.drawLine(
        Offset(cellW * i, 0),
        Offset(cellW * i, h),
        ultimate && i % 3 == 0 ? thickPaint : paint,
      );
      canvas.drawLine(
        Offset(0, cellH * i),
        Offset(w, cellH * i),
        ultimate && i % 3 == 0 ? thickPaint : paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.gridSize != gridSize || old.ultimate != ultimate;
}

class _TurnCountdown extends StatefulWidget {
  const _TurnCountdown({
    super.key,
    required this.turnDeadline,
    required this.isMyTurn,
    required this.onExpired,
  });

  final int turnDeadline; // Unix sec
  final bool isMyTurn;
  final VoidCallback onExpired;

  @override
  State<_TurnCountdown> createState() => _TurnCountdownState();
}

class _TurnCountdownState extends State<_TurnCountdown> {
  Timer? _timer;
  int _remaining = 0;
  bool _expiredFired = false;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _TurnCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.turnDeadline != widget.turnDeadline) {
      _expiredFired = false;
      _timer?.cancel();
      _updateRemaining();
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
      if (_remaining <= 0 && !_expiredFired) {
        _expiredFired = true;
        widget.onExpired();
      }
    });
  }

  void _updateRemaining() {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final r = widget.turnDeadline - now;
    if (r != _remaining && mounted) {
      setState(() => _remaining = r.clamp(0, 999));
    } else if (r <= 0 && _remaining != 0 && mounted) {
      setState(() => _remaining = 0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _remaining <= 5 && widget.isMyTurn
        ? Colors.red
        : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          context.l10n.gameSecondsLeft(_remaining),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _AnimatedGameCell extends StatelessWidget {
  const _AnimatedGameCell({
    required this.symbol,
    required this.isMyTurn,
    required this.canTap,
    this.isForbidden = false,
    this.isActiveBoard = false,
    this.isClosedBoard = false,
    this.onTap,
    this.pulse,
  });

  final String symbol;
  final bool isMyTurn;
  final bool canTap;
  final bool isForbidden;
  final bool isActiveBoard;
  final bool isClosedBoard;
  final VoidCallback? onTap;
  final AnimationController? pulse;

  @override
  Widget build(BuildContext context) {
    final cell = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isForbidden
                ? Colors.grey.withValues(alpha: 0.15)
                : isClosedBoard
                    ? AppColors.textSecondary.withValues(alpha: 0.06)
                    : isActiveBoard
                        ? AppColors.accentStart.withValues(alpha: 0.14)
                        : canTap && isMyTurn
                            ? AppColors.accentSoft.withValues(alpha: 0.25)
                            : Colors.transparent,
          ),
          child: pulse != null && canTap && isMyTurn
              ? AnimatedBuilder(
                  animation: pulse!,
                  builder: (context, _) {
                    final alpha = 0.2 +
                        0.12 * (0.5 + 0.5 * (pulse!.value * 2 - 1).abs());
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: AppColors.accentStart.withValues(alpha: alpha),
                      ),
                      child: Center(
                        child: _SymbolWidget(symbol: symbol),
                      ),
                    );
                  },
                )
              : Center(
                  child: _SymbolWidget(symbol: symbol),
                ),
        ),
      ),
    );
    // Пустые клетки без pulse — без TweenAnimationBuilder (критично для 8×8/10×10).
    if (symbol.isEmpty) return cell;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.short,
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        return Transform.scale(scale: t, child: child);
      },
      child: cell,
    );
  }
}

class _SymbolWidget extends StatelessWidget {
  const _SymbolWidget({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    if (symbol.isEmpty) return const SizedBox.shrink();
    final color = _symbolColor(symbol);
    return FittedBox(
      fit: BoxFit.contain,
      child: AnimatedSwitcher(
        duration: AppDurations.short,
        child: CustomPaint(
          key: ValueKey(symbol),
          size: const Size.square(42),
          painter: _SymbolPainter(symbol: symbol, color: color),
        ),
      ),
    );
  }
}

Color _symbolColor(String symbol) {
  switch (symbol) {
    case 'x':
      return AppColors.accentStart;
    case 'o':
      return AppColors.accentEnd;
    case 't':
      return Colors.orange;
    case 's':
      return Colors.teal;
    default:
      return AppColors.textSecondary;
  }
}

/// Рисует X/O/T/S через Canvas — без шрифтов, чтобы не было placeholder.
class _SymbolPainter extends CustomPainter {
  _SymbolPainter({required this.symbol, required this.color});

  final String symbol;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.12;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (symbol == 'x') {
      final padding = size.width * 0.15;
      canvas.drawLine(
        Offset(padding, padding),
        Offset(size.width - padding, size.height - padding),
        paint,
      );
      canvas.drawLine(
        Offset(size.width - padding, padding),
        Offset(padding, size.height - padding),
        paint,
      );
    } else if (symbol == 'o') {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        (size.width - strokeWidth) / 2,
        paint,
      );
    } else if (symbol == 't') {
      final padding = size.width * 0.14;
      final path = Path()
        ..moveTo(size.width / 2, padding)
        ..lineTo(size.width - padding, size.height - padding)
        ..lineTo(padding, size.height - padding)
        ..close();
      canvas.drawPath(path, paint);
    } else if (symbol == 's') {
      final padding = size.width * 0.18;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            padding,
            padding,
            size.width - padding * 2,
            size.height - padding * 2,
          ),
          Radius.circular(size.width * 0.08),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SymbolPainter old) =>
      old.symbol != symbol || old.color != color;
}
