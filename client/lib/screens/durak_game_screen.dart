import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/games/durak/durak_provider.dart';
import 'package:multigames_client/games/durak/durak_repository.dart';
import 'package:multigames_client/games/durak/durak_rules.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart' show GamesException;
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/durak/card_fan.dart';
import 'package:multigames_client/ui/durak/card_fly.dart';
import 'package:multigames_client/ui/durak/deck_pile.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';
import 'package:multigames_client/ui/widgets/gradient_background.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';
import 'package:multigames_client/utils/user_error.dart';

class DurakGameScreen extends ConsumerStatefulWidget {
  const DurakGameScreen({super.key, required this.gameId});
  final String gameId;

  @override
  ConsumerState<DurakGameScreen> createState() => _DurakGameScreenState();
}

class _DurakGameScreenState extends ConsumerState<DurakGameScreen> {
  bool _busy = false;
  bool _settled = false;
  bool _handlingAuthError = false;
  bool _retryScheduled = false;
  PlayingCard? _activeCard;
  Timer? _timeoutRetryTimer;
  final GlobalKey _fanKey = GlobalKey();
  final GlobalKey _defendTargetKey = GlobalKey();
  final GlobalKey _attackSlotKey = GlobalKey();

  @override
  void dispose() {
    _timeoutRetryTimer?.cancel();
    super.dispose();
  }

  /// Сервер применяет timeout на GetGame — дожимаем несколько раз.
  void _onTurnTimeExpired() {
    _timeoutRetryTimer?.cancel();
    var attempt = 0;
    void doRefresh() {
      if (!mounted) return;
      ref.invalidate(durakGameProvider(widget.gameId));
      ref.invalidate(activeGameProvider);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => doRefresh());
    _timeoutRetryTimer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      attempt++;
      doRefresh();
      if (attempt >= 10) {
        t.cancel();
        _timeoutRetryTimer = null;
      }
    });
  }

  bool _isTransientLoadError(Object e) {
    if (e is GamesException) {
      if (e.statusCode == 502 || e.statusCode == 503) return true;
      final key = e.errorKey.toLowerCase();
      final msg = e.message.toLowerCase();
      return key.contains('temporarily unavailable') ||
          msg.contains('temporarily unavailable') ||
          msg.contains('временно недоступно') ||
          msg.contains('попробуйте позже');
    }
    final s = e.toString().toLowerCase();
    return s.contains('503') ||
        s.contains('502') ||
        s.contains('temporarily unavailable') ||
        s.contains('попробуйте позже') ||
        s.contains('connection') ||
        s.contains('socket');
  }

  bool _isSessionExpired(Object e) {
    final s = e.toString().toLowerCase();
    // 503/«попробуйте позже» — временный сбой, не разлогиниваем.
    if (_isTransientLoadError(e) ||
        s.contains('503') ||
        s.contains('попробуйте позже')) {
      return false;
    }
    return s.contains('401') ||
        s.contains('session expired') ||
        s.contains('сессия истекла');
  }

  void _scheduleTransientRetry() {
    if (_retryScheduled) return;
    _retryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(seconds: 1), () {
        _retryScheduled = false;
        if (!mounted) return;
        ref.invalidate(durakGameProvider(widget.gameId));
      });
    });
  }

  void _handleAuthError(Object e) {
    if (_handlingAuthError || !_isSessionExpired(e)) return;
    _handlingAuthError = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(authStateProvider.notifier).logout();
      if (!mounted) return;
      context.go('/login');
    });
  }

  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(durakGameProvider(widget.gameId));
    } on GamesException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Suit _suitFromApi(String raw) {
    return switch (raw.toUpperCase().trim()) {
      'H' || '0' || 'HEARTS' => Suit.hearts,
      'D' || '1' || 'DIAMONDS' => Suit.diamonds,
      'C' || '2' || 'CLUBS' => Suit.clubs,
      'S' || '3' || 'SPADES' => Suit.spades,
      _ => Suit.spades,
    };
  }

  bool _highlightDefendTargets(DurakGameView view) {
    if (_activeCard == null || _busy || view.isOver) return false;
    if (view.phase != 'defend' || view.defenderIndex != view.myIndex) {
      return false;
    }
    return view.legalDefend
        .any((c) => c.toPlayingCard() == _activeCard);
  }

  bool _highlightAttackSlot(DurakGameView view) {
    if (_activeCard == null || _busy || view.isOver) return false;
    if (view.attackerIndex != view.myIndex) return false;
    if (view.phase != 'attack' && view.phase != 'attack_follow') return false;
    return view.legalAttack
        .any((c) => c.toPlayingCard() == _activeCard);
  }

  Future<void> _playMyCard(DurakGameView view, PlayingCard card) async {
    if (_busy || view.isOver) return;
    final isDefend =
        view.phase == 'defend' && view.defenderIndex == view.myIndex;
    final isAttack = view.attackerIndex == view.myIndex &&
        (view.phase == 'attack' || view.phase == 'attack_follow');
    if (!isDefend && !isAttack) return;

    final from = cardFanApproxOrigin(
          _fanKey.currentContext ?? context,
          const Size(64, 92),
        ) ??
        Rect.fromCenter(
          center: MediaQuery.sizeOf(context).center(Offset.zero),
          width: 64,
          height: 92,
        );
    final toKey = isDefend ? _defendTargetKey : _attackSlotKey;
    final to = globalRectOf(toKey) ??
        Rect.fromCenter(
          center: MediaQuery.sizeOf(context).center(Offset.zero),
          width: 64,
          height: 92,
        );

    setState(() => _activeCard = null);
    await playCardFlyAnimation(
      context: context,
      card: card,
      cardSize: const Size(64, 92),
      from: from,
      to: to,
    );
    if (!mounted) return;

    final repo = ref.read(durakRepositoryProvider);
    if (isDefend) {
      await _act(() => repo.move(widget.gameId, type: 'defend', card: card));
    } else {
      await _act(() => repo.move(widget.gameId, type: 'attack', card: card));
    }
  }

  Future<void> _take() async {
    final repo = ref.read(durakRepositoryProvider);
    await _act(() => repo.move(widget.gameId, type: 'take'));
  }

  Future<void> _bito() async {
    final repo = ref.read(durakRepositoryProvider);
    await _act(() => repo.move(widget.gameId, type: 'bito'));
  }

  /// Сдача/выход — общий диалог подтверждения, как в крестиках-ноликах.
  Future<void> _confirmLeave() async {
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    if (view?.isOver ?? false) {
      _clearSessionAndExit();
      return;
    }
    final leave = await confirmGameActionDialog(
      context: context,
      title: context.l10n.gameSurrenderTitle,
      message: context.l10n.gameSurrenderConfirm,
      cancelLabel: context.l10n.gameStay,
      confirmLabel: context.l10n.gameSurrender,
    );
    if (!leave || !mounted) return;
    try {
      await ref.read(durakRepositoryProvider).forfeit(widget.gameId);
    } catch (_) {}
    if (!mounted) return;
    _clearSessionAndExit();
  }

  void _clearSessionAndExit() {
    clearBlockingGamePin(ref, ifGameId: widget.gameId);
    ref.read(activeGameProvider.notifier).clearLocal();
    context.go('/games');
  }

  bool _iOfferedDraw(DurakGameView view) {
    final me = view.myIndex >= 0 && view.playerIds.length > view.myIndex
        ? view.playerIds[view.myIndex]
        : '';
    return view.drawOfferBy.isNotEmpty && view.drawOfferBy == me;
  }

  bool _opponentOfferedDraw(DurakGameView view) {
    final me = view.myIndex >= 0 && view.playerIds.length > view.myIndex
        ? view.playerIds[view.myIndex]
        : '';
    return view.drawOfferBy.isNotEmpty && view.drawOfferBy != me;
  }

  Future<void> _offerDraw(DurakGameView view) async {
    final ok = await confirmGameActionDialog(
      context: context,
      title: context.l10n.gameOfferDrawTitle,
      message: context.l10n.gameOfferDrawConfirm,
      cancelLabel: context.l10n.commonCancel,
      confirmLabel: context.l10n.gameOfferDrawTitle,
    );
    if (!ok || !mounted) return;
    await _act(() => ref.read(durakRepositoryProvider).offerDraw(widget.gameId));
  }

  Future<void> _acceptDraw() async {
    await _act(
        () => ref.read(durakRepositoryProvider).acceptDraw(widget.gameId));
  }

  void _showRules(DurakGameView view) {
    showGameRulesDialog(
      context: context,
      title: context.l10n.gamesRulesTitle,
      content: rulesTextLines(durakRuleLines(
        mode: view.mode,
        players: view.playerIds.length,
        deckSize: view.deckSize,
        turnTimeSec: view.turnTimeSec,
        stakeBronze: view.stakeBronze,
      )),
      closeLabel: context.l10n.commonClose,
    );
  }

  /// Начисление банка победителю с анимацией — общий сценарий.
  void _onGameOver(DurakGameView view) {
    if (_settled) return;
    _settled = true;
    final iWon = view.loserIndex != view.myIndex && view.loserIndex >= 0;
    if (!iWon || view.stakeBronze <= 0) {
      unawaited(ref.read(activeGameProvider.notifier).refresh());
      return;
    }
    final playersN = view.playerIds.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      clearBlockingGamePin(ref, ifGameId: widget.gameId);
      unawaited(playGameSettledReward(
        ref: ref,
        context: context,
        creditBronze: view.stakeBronze * playersN,
        displayRewardBronze: view.stakeBronze * (playersN - 1),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(durakGameProvider(widget.gameId));
    final view = gameAsync.valueOrNull;
    if (view != null && view.isOver) _onGameOver(view);
    final showSurrender = view != null && !view.isOver;
    final isMulti = (view?.playerIds.length ?? 0) > 2;
    final topPad = MediaQuery.paddingOf(context).top;
    // Как в крестиках: 1×1 — сдаться/ничья overlay справа; multi — флаг в AppBar.
    return SwipeBackScope(
      onBack: _confirmLeave,
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
            onPressed: _busy ? null : _confirmLeave,
          ),
          title: const Text('Дурак'),
          actions: view == null
              ? const []
              : buildGameAppBarActions(
                  context: context,
                  onSurrender: showSurrender && isMulti ? _confirmLeave : null,
                  surrenderTooltip: context.l10n.gameSurrender,
                  onOfferDraw: null,
                  onShowRules: () => _showRules(view),
                  rulesTooltip: context.l10n.gamesRulesTitle,
                ),
        ),
        body: GradientBackground(
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(
                child: gameAsync.when(
                  skipLoadingOnReload: true,
                  skipLoadingOnRefresh: true,
                  data: _buildTable,
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.accentStart),
                  ),
                  error: (e, _) {
                    _handleAuthError(e);
                    if (_isSessionExpired(e) || _isTransientLoadError(e)) {
                      // Как в крестиках: не залипаем на красном тексте —
                      // крутим индикатор и перезапрашиваем партию.
                      if (_isTransientLoadError(e)) {
                        _scheduleTransientRetry();
                      }
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accentStart,
                        ),
                      );
                    }
                    return Center(
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
                                durakGameProvider(widget.gameId),
                              ),
                              child: Text(context.l10n.commonTryRefresh),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (view != null &&
                  view.isOver &&
                  view.loserIndex >= 0 &&
                  view.loserIndex != view.myIndex)
                const Positioned.fill(child: GameConfettiOverlay()),
              if (showSurrender && !isMulti)
                Positioned(
                  right: 4,
                  top: topPad + 4,
                  child: GameActionsOverlay(
                    canDraw: view.playerIds.length == 2,
                    iOfferedDraw: _iOfferedDraw(view),
                    opponentOfferedDraw: _opponentOfferedDraw(view),
                    onSurrender: _confirmLeave,
                    onDraw: () {
                      if (_opponentOfferedDraw(view)) {
                        unawaited(_acceptDraw());
                      } else {
                        unawaited(_offerDraw(view));
                      }
                    },
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
    );
  }

  Widget _buildTable(DurakGameView view) {
    const cardSize = Size(64, 92);
    final myHand = _apiCardsToPlaying(
      view.hands.length > view.myIndex && view.myIndex >= 0
          ? (view.hands[view.myIndex].cards ?? const [])
          : const [],
    );
    final legal = <PlayingCard>{
      ..._apiCardsToPlaying(view.legalAttack),
      ..._apiCardsToPlaying(view.legalDefend),
    };
    final trumpCard = view.trumpCard.toPlayingCard();

    // Соперники по кругу (кроме себя).
    final opponents = <int>[];
    for (var i = 0; i < view.hands.length; i++) {
      if (i != view.myIndex) opponents.add(i);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Рамка соперника; карты — сразу под ней (без дубля логина).
          _opponentsHeader(view),
          const SizedBox(height: 4),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final oi in opponents) _opponentFan(view, oi, cardSize),
            ],
          ),
          const SizedBox(height: 4),
          GameStatusLine(
            text: _turnHint(view),
            highlight: !view.isOver && view.isMyTurn,
          ),
          if (!view.isOver && view.turnTimeSec > 0 && view.turnDeadline > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GameTurnCountdown(
                key: ValueKey('${view.phase}_${view.turnDeadline}'),
                turnDeadline: view.turnDeadline,
                isMyTurn: view.isMyTurn,
                onExpired: _onTurnTimeExpired,
                labelBuilder: (s) => context.l10n.gameSecondsLeft(s),
              ),
            ),
          if (!view.isOver && _opponentOfferedDraw(view))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.gameDrawOffered,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _busy ? null : _acceptDraw,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentStart,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(context.l10n.commonAccept),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          // Колода/стол — сверху Expanded, не по центру экрана.
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: _buildBoard(view, cardSize, trumpCard),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: _sideActionButton(view),
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, constraints) {
              final n = myHand.length;
              final spacing = n <= 1
                  ? 0.0
                  : cardSize.width *
                      (n > 24
                          ? 0.16
                          : n > 18
                              ? 0.2
                              : n > 14
                                  ? 0.24
                                  : n > 10
                                      ? 0.3
                                      : n > 7
                                          ? 0.38
                                          : 0.52);
              final fanW = cardSize.width + spacing * (n - 1) + 32;
              final scale = fanW > constraints.maxWidth
                  ? (constraints.maxWidth / fanW).clamp(0.55, 1.0)
                  : 1.0;
              final fan = CardFan(
                key: _fanKey,
                cards: myHand,
                cardSize: cardSize,
                legalCards: legal,
                enabled: !view.isOver && view.isMyTurn && !_busy,
                onActiveChanged: (c) {
                  if (_activeCard == c) return;
                  setState(() => _activeCard = c);
                },
                onTap: (c) => unawaited(_playMyCard(view, c)),
                onDrag: (c, _) => unawaited(_playMyCard(view, c)),
              );
              return Center(
                child: scale < 1
                    ? Transform.scale(scale: scale, child: fan)
                    : fan,
              );
            },
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  /// Шапка с соперником (1×1) — тот же виджет, что в крестиках-ноликах.
  Widget _opponentsHeader(DurakGameView view) {
    if (view.playerIds.length != 2 || view.myIndex < 0) {
      return const SizedBox.shrink();
    }
    final oppIndex = view.myIndex == 0 ? 1 : 0;
    if (view.playerIds.length <= oppIndex) return const SizedBox.shrink();
    final oppId = view.playerIds[oppIndex];
    final isBot = oppId.startsWith('bot:');
    final meta = view.playerMeta(oppId);
    var name = isBot
        ? context.l10n.gameBot
        : (meta?.displayName?.trim().isNotEmpty == true
            ? meta!.displayName!.trim()
            : context.l10n.gameOpponent);
    var avatarKind = meta?.avatarKind ?? 'letter';
    var avatarValue = meta?.avatarValue;
    var frameCode = meta?.frameCode;
    var frameColor = meta?.frameColor;

    // Дополняем из чатов, если сервер ещё не отдал метаданные.
    final chats = ref.watch(chatsListProvider).valueOrNull;
    var unread = 0;
    if (chats != null) {
      for (final c in chats) {
        if (c.user.id == oppId) {
          final dn = c.user.displayName?.trim();
          if (name == context.l10n.gameOpponent &&
              dn != null &&
              dn.isNotEmpty) {
            name = dn;
          }
          if (avatarValue == null || avatarValue.isEmpty) {
            avatarKind = c.user.avatarKind;
            avatarValue = c.user.avatarValue;
          }
          frameCode ??= c.user.frameCode;
          frameColor ??= c.user.frameColor;
          unread += c.unreadCount;
        }
      }
    }

    final friends = ref.watch(friendsSnapshotProvider).valueOrNull;
    final isFriend =
        friends?.friends.any((f) => f.user.id == oppId) == true;
    final outgoing = friends?.outgoing
            .where((r) => r.user.id == oppId)
            .toList() ??
        const [];
    final incoming = friends?.incoming
            .where((r) => r.user.id == oppId)
            .toList() ??
        const [];
    final hasOutgoing = outgoing.isNotEmpty;
    final hasIncoming = incoming.isNotEmpty;
    final incomingRequestId = hasIncoming ? incoming.first.requestId : null;

    return GameOpponentCard(
      displayName: name,
      avatarKind: avatarKind,
      avatarValue: avatarValue,
      frameCode: frameCode,
      frameColor: frameColor,
      isBot: isBot,
      messageUnread: view.isOver ? 0 : unread,
      infoTooltip: context.l10n.userInfoTitle,
      messageTooltip: context.l10n.gameWriteMessage,
      compact: MediaQuery.sizeOf(context).width < 420,
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
        avatarKind: avatarKind,
        avatarValue: avatarValue,
        frameCode: frameCode,
        frameColor: frameColor,
        messageFrom: 'games',
        messageReturnPath: '/games/durak/game/${widget.gameId}',
      )),
      onMessageTap: view.isOver
          ? null
          : () => unawaited(_openChat(oppId, name)),
    );
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
          'game': '/games/durak/game/${widget.gameId}',
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
            'game': '/games/durak/game/${widget.gameId}',
          },
        ).toString(),
      );
    }
  }

  Widget _opponentFan(DurakGameView view, int idx, Size cardSize) {
    final count = view.hands.length > idx ? view.hands[idx].count : 0;
    final fake = List<PlayingCard>.generate(
      count.clamp(0, 8),
      (i) => PlayingCard(Rank.six, Suit.spades),
    );
    // Имя уже в овальной рамке сверху — здесь только веер + счётчик.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          child: CardFan(
            key: ValueKey('opp-$idx-$count'),
            cards: fake,
            cardSize: Size(cardSize.width * 0.55, cardSize.height * 0.55),
            faceDown: true,
            enabled: false,
            arc: 0.18,
          ),
        ),
        Text(
          'Карт: $count',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildBoard(
    DurakGameView view,
    Size cardSize,
    PlayingCard trumpCard,
  ) {
    final highlightDefend = _highlightDefendTargets(view);
    final highlightAttack = _highlightAttackSlot(view);
    // Первая неотбитая пара — цель защиты.
    var defendPairIndex = -1;
    if (highlightDefend) {
      for (var i = 0; i < view.table.length; i++) {
        if (view.table[i].defense == null) {
          defendPairIndex = i;
          break;
        }
      }
    }

    return Center(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DurakDeckPile(
            deckCount: view.deckCount,
            trumpCard: trumpCard,
            trumpSuit: _suitFromApi(view.trumpSuit),
            cardSize: cardSize,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < view.table.length; i++)
                    _AnimatedTablePair(
                      key: ValueKey(
                        'pair-$i-${view.table[i].attack.rank}'
                        '${view.table[i].attack.suit}-'
                        '${view.table[i].defense?.rank ?? 0}'
                        '${view.table[i].defense?.suit ?? ''}',
                      ),
                      pair: view.table[i],
                      cardSize: cardSize,
                      highlightAttack: i == defendPairIndex,
                      defendTargetKey:
                          i == defendPairIndex ? _defendTargetKey : null,
                    ),
                  if (!view.isOver &&
                      view.attackerIndex == view.myIndex &&
                      (view.phase == 'attack' || view.phase == 'attack_follow'))
                    Padding(
                      key: _attackSlotKey,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: DurakDropSlot(
                        size: cardSize,
                        active: highlightAttack,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          DurakBitoPile(count: view.bitoCount, cardSize: cardSize),
        ],
      ),
    );
  }

  /// Одна кнопка: «Взять» или «Бито» — в левом углу под колодой.
  Widget _sideActionButton(DurakGameView view) {
    final iAmDefender =
        view.defenderIndex == view.myIndex && view.phase == 'defend';
    final iAmAttacker =
        view.attackerIndex == view.myIndex && view.phase == 'attack_follow';
    final canTake =
        !view.isOver && iAmDefender && view.table.isNotEmpty && !_busy;
    final canBito = !view.isOver &&
        iAmAttacker &&
        view.table.isNotEmpty &&
        view.table.every((p) => p.defense != null) &&
        !_busy;

    if (!canTake && !canBito) {
      return const SizedBox(height: 40);
    }

    final take = canTake;
    return SizedBox(
      height: 40,
      child: FilledButton.icon(
        onPressed: take ? _take : _bito,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentStart,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          visualDensity: VisualDensity.compact,
        ),
        icon: Icon(
          take ? Icons.file_download_rounded : Icons.check_rounded,
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          take ? 'Взять' : 'Бито',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// Статус как в крестиках: «Ваш ход» / «Ход {имя}» / итог.
  String _turnHint(DurakGameView view) {
    if (view.isOver) {
      if (view.isDraw) return context.l10n.gameDraw;
      if (view.loserIndex == view.myIndex) {
        return context.l10n.gameOpponentWon(_opponentName(view));
      }
      return context.l10n.gameYouWon;
    }
    if (view.isMyTurn) return context.l10n.gamesMyTurn;
    final turnIdx = view.phase == 'defend'
        ? view.defenderIndex
        : view.attackerIndex;
    final turnId = (turnIdx >= 0 && turnIdx < view.playerIds.length)
        ? view.playerIds[turnIdx]
        : '';
    final meta = view.playerMeta(turnId);
    final fromMeta = meta?.displayName?.trim() ?? '';
    if (fromMeta.isNotEmpty) return 'Ход $fromMeta';
    return context.l10n.gamesOpponentTurn;
  }

  String _opponentName(DurakGameView view) {
    if (view.playerIds.length != 2 || view.myIndex < 0) {
      return context.l10n.gameOpponent;
    }
    final oppIndex = view.myIndex == 0 ? 1 : 0;
    final oppId = view.playerIds[oppIndex];
    if (oppId.startsWith('bot:')) return context.l10n.gameBot;
    final meta = view.playerMeta(oppId);
    final n = meta?.displayName?.trim() ?? '';
    return n.isNotEmpty ? n : context.l10n.gameOpponent;
  }

  List<PlayingCard> _apiCardsToPlaying(List<DurakApiCard> apis) {
    return apis.map((c) => c.toPlayingCard()).toList();
  }
}

/// Пара на столе с появлением scale/fade.
class _AnimatedTablePair extends StatelessWidget {
  const _AnimatedTablePair({
    super.key,
    required this.pair,
    required this.cardSize,
    this.highlightAttack = false,
    this.defendTargetKey,
  });

  final DurakTablePairApi pair;
  final Size cardSize;
  final bool highlightAttack;
  final GlobalKey? defendTargetKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.86, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Opacity(
          opacity: scale.clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: child),
        ),
        child: SizedBox(
          width: cardSize.width + 10,
          height: cardSize.height + 14,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PlayingCardWidget(
                key: defendTargetKey,
                card: pair.attack.toPlayingCard(),
                size: cardSize,
                elevated: true,
                dropTarget: highlightAttack && pair.defense == null,
              ),
              if (pair.defense != null)
                Positioned(
                  left: 10,
                  top: 14,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1),
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutBack,
                    builder: (context, s, child) =>
                        Transform.scale(scale: s, child: child),
                    child: PlayingCardWidget(
                      card: pair.defense!.toPlayingCard(),
                      size: cardSize,
                      elevated: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
