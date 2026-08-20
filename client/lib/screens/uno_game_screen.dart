import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException;
import 'package:multigames_client/games/uno/uno_card.dart';
import 'package:multigames_client/games/uno/uno_engine.dart';
import 'package:multigames_client/games/uno/uno_offline_session.dart';
import 'package:multigames_client/games/uno/uno_provider.dart';
import 'package:multigames_client/games/uno/uno_repository.dart';
import 'package:multigames_client/games/uno/uno_rules.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/uno/uno_card_fly.dart';
import 'package:multigames_client/ui/uno/uno_card_widget.dart';
import 'package:multigames_client/ui/widgets/game_fly_overlay.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/ui/widgets/uno_game_icon.dart';
import 'package:multigames_client/utils/user_error.dart';

class UnoGameScreen extends ConsumerStatefulWidget {
  const UnoGameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  ConsumerState<UnoGameScreen> createState() => _UnoGameScreenState();
}

class _UnoGameScreenState extends ConsumerState<UnoGameScreen> {
  final GlobalKey _drawPileKey = GlobalKey();
  final GlobalKey _discardKey = GlobalKey();
  final GlobalKey _handKey = GlobalKey();
  final Map<int, GlobalKey> _opponentKeys = {};
  final Map<String, GlobalKey> _cardKeys = {};
  final GlobalKey _rewardKey = GlobalKey();

  bool _busy = false;
  bool _dealAnimated = false;
  bool _colorDialogOpen = false;
  bool _bindingsInitialized = false;
  String? _lastTopId;
  String? _optimisticTopId;

  bool get _isOffline => OfflineUnoRegistry.instance.isOffline(widget.gameId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bindingsInitialized) return;
    _bindingsInitialized = true;
    if (!_isOffline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        pinBlockingGame(ref, widget.gameId, gameType: 'uno');
        final active = ref.read(activeGameProvider).valueOrNull;
        if (active?.gameId != widget.gameId) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: widget.gameId,
                  lobbyId: active?.lobbyId,
                  gameType: 'uno',
                ),
              );
        }
      });
    }
  }

  @override
  void dispose() {
    GameFlyOverlay.dismissAll();
    super.dispose();
  }

  Rect? _rectOf(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  Size _flyCardSize(BuildContext context) =>
      isNarrow(context) ? const Size(52, 78) : const Size(62, 93);

  void _observeView(UnoGameView game) {
    final topId = game.topDiscard?.id;
    if (!_dealAnimated) {
      _lastTopId = topId;
      _dealAnimated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_animateInitialDeal(game));
      });
    } else if (topId != null &&
        _lastTopId != null &&
        topId != _lastTopId &&
        topId != _optimisticTopId) {
      final fromIndex =
          game.players.indexWhere((player) => player.id == game.lastPlayedBy);
      _lastTopId = topId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && fromIndex >= 0 && fromIndex != game.myIndex) {
          unawaited(_animateOpponentPlay(game, fromIndex));
        }
      });
    } else {
      _lastTopId = topId;
    }

    if (game.mustChooseColor && !_colorDialogOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_choosePendingColor());
      });
    }
    if (game.isOver && !_isOffline) {
      clearBlockingGamePin(ref, ifGameId: widget.gameId);
      final active = ref.read(activeGameProvider).valueOrNull;
      if (active?.gameId == widget.gameId) {
        ref.read(activeGameProvider.notifier).clearLocal();
      }
    }
  }

  Future<void> _animateInitialDeal(UnoGameView game) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final from = _rectOf(_drawPileKey);
    if (from == null) return;
    final size = _flyCardSize(context);
    for (var round = 0; round < 7; round++) {
      for (var playerIndex = 0;
          playerIndex < game.players.length;
          playerIndex++) {
        if (!mounted) return;
        final isMe = playerIndex == game.myIndex;
        final target = isMe
            ? _rectOf(_handKey)
            : _rectOf(_opponentKeys.putIfAbsent(
                playerIndex,
                GlobalKey.new,
              ));
        if (target == null) continue;
        final card = isMe && round < game.myHand.length
            ? game.myHand[round]
            : const UnoCard(
                id: 'deal-back',
                color: UnoColor.wild,
                kind: UnoCardKind.wild,
              );
        unawaited(playUnoCardFlyAnimation(
          context: context,
          card: card,
          cardSize: size,
          from: from,
          to: target,
          duration: const Duration(milliseconds: 260),
          faceDown: !isMe,
          beginScale: 0.85,
          endScale: 1,
          arcLift: 18,
        ));
        await Future<void>.delayed(const Duration(milliseconds: 32));
      }
    }
  }

  Future<void> _animateOpponentPlay(UnoGameView game, int playerIndex) async {
    final card = game.topDiscard;
    final from = _rectOf(
      _opponentKeys.putIfAbsent(playerIndex, GlobalKey.new),
    );
    final to = _rectOf(_discardKey);
    if (card == null || from == null || to == null || !mounted) return;
    await playUnoCardFlyAnimation(
      context: context,
      card: card,
      cardSize: _flyCardSize(context),
      from: from,
      to: to,
      faceDown: true,
      flipToFace: true,
      arcLift: 34,
    );
  }

  Future<UnoColor?> _showColorPicker() async {
    _colorDialogOpen = true;
    final result = await showDialog<UnoColor>(
      context: context,
      builder: (dialogContext) {
        final compact = MediaQuery.sizeOf(dialogContext).width < 380;
        return AlertDialog(
          title: Text(dialogContext.l10n.unoChooseColor),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.85,
            ),
            child: SizedBox(
              width: compact ? 230 : 300,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final color in const [
                    UnoColor.red,
                    UnoColor.yellow,
                    UnoColor.green,
                    UnoColor.blue,
                  ])
                    Semantics(
                      label: _colorName(color),
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.of(dialogContext).pop(color),
                        child: Container(
                          width: compact ? 88 : 112,
                          height: compact ? 58 : 70,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _colorValue(color),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white70, width: 2),
                          ),
                          child: Text(
                            _colorName(color),
                            style: TextStyle(
                              color: color == UnoColor.yellow
                                  ? Colors.black
                                  : Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dialogContext.l10n.commonCancel),
            ),
          ],
        );
      },
    );
    _colorDialogOpen = false;
    return result;
  }

  Future<void> _choosePendingColor() async {
    final color = await _showColorPicker();
    if (color == null || !mounted) return;
    await _move(UnoActionType.chooseColor, color: color);
  }

  String _colorName(UnoColor color) => switch (color) {
        UnoColor.red => context.l10n.unoColorRed,
        UnoColor.yellow => context.l10n.unoColorYellow,
        UnoColor.green => context.l10n.unoColorGreen,
        UnoColor.blue => context.l10n.unoColorBlue,
        UnoColor.wild => context.l10n.unoChooseColor,
      };

  Color _colorValue(UnoColor color) => switch (color) {
        UnoColor.red => const Color(0xFFE53935),
        UnoColor.yellow => const Color(0xFFFBC02D),
        UnoColor.green => const Color(0xFF2EAD62),
        UnoColor.blue => const Color(0xFF2583E8),
        UnoColor.wild => const Color(0xFF181B22),
      };

  Future<void> _playCard(UnoGameView game, UnoCard card) async {
    if (_busy || !game.isMyTurn || !_canPlayCard(game, card)) return;
    UnoColor? color;
    if (card.isWild) {
      color = await _showColorPicker();
      if (color == null || !mounted) return;
    }
    final from = _rectOf(_cardKeys.putIfAbsent(card.id, GlobalKey.new));
    final to = _rectOf(_discardKey);
    if (from != null && to != null && mounted) {
      await playUnoCardFlyAnimation(
        context: context,
        card: card,
        cardSize: _flyCardSize(context),
        from: from,
        to: to,
        beginAngle: 0.05,
        endAngle: -0.04,
        arcLift: 42,
      );
    }
    _optimisticTopId = card.id;
    _lastTopId = card.id;
    await _move(
      UnoActionType.play,
      cardId: card.id,
      color: color,
    );
    _optimisticTopId = null;
  }

  Future<void> _draw(UnoGameView before) async {
    if (_busy) return;
    final from = _rectOf(_drawPileKey);
    await _move(UnoActionType.draw);
    if (!mounted || from == null) return;
    UnoGameView? after;
    try {
      after = await ref.read(unoGameProvider(widget.gameId).future);
    } catch (_) {}
    if (!mounted) return;
    final oldIds = before.myHand.map((card) => card.id).toSet();
    final drawn = after?.myHand
        .where((card) => !oldIds.contains(card.id))
        .toList(growable: false);
    final card = drawn != null && drawn.isNotEmpty
        ? drawn.last
        : const UnoCard(
            id: 'draw-back',
            color: UnoColor.wild,
            kind: UnoCardKind.wild,
          );
    final to = _rectOf(_handKey);
    if (to == null) return;
    await playUnoCardFlyAnimation(
      context: context,
      card: card,
      cardSize: _flyCardSize(context),
      from: from,
      to: to,
      faceDown: drawn == null || drawn.isEmpty,
      flipToFace: drawn != null && drawn.isNotEmpty,
      arcLift: 36,
    );
  }

  Future<void> _move(
    String type, {
    String? cardId,
    UnoColor? color,
    String? targetUserId,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(unoRepositoryProvider).move(
            widget.gameId,
            type: type,
            cardId: cardId,
            color: color,
            targetUserId: targetUserId,
          );
      if (!_isOffline && mounted) {
        ref.invalidate(unoGameProvider(widget.gameId));
      }
    } on GamesException catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          message: formatUserError(error),
          kind: AppSnackKind.error,
        );
      }
    } catch (error) {
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

  bool _canPlayCard(UnoGameView game, UnoCard card) {
    if (!game.isMyTurn || game.topDiscard == null) return false;
    if (game.status == UnoStatus.awaitingDrawnPlay) {
      return card.id == game.drawnCardId;
    }
    if (game.status != UnoStatus.active) return false;
    return card.matches(game.topDiscard!, game.currentColor);
  }

  bool _hasLegalCard(UnoGameView game) =>
      game.myHand.any((card) => _canPlayCard(game, card));

  String? _unoChallengeTarget(UnoGameView game) {
    for (final player in game.players) {
      if (player.id != game.me?.id &&
          player.handCount == 1 &&
          !player.saidUno &&
          !player.forfeited) {
        return player.id;
      }
    }
    return null;
  }

  Future<void> _onClose() async {
    final game = ref.read(unoGameProvider(widget.gameId)).valueOrNull;
    await handleGameScreenClose(
      context: context,
      isActive: game != null && !game.isOver,
      onLeaveFinished: () async => _goToGames(),
      onForfeitAndLeave: () async {
        try {
          await ref.read(unoRepositoryProvider).forfeit(widget.gameId);
        } catch (_) {}
        if (mounted) _goToGames();
      },
    );
  }

  void _goToGames() {
    if (!_isOffline) {
      clearBlockingGamePin(ref, ifGameId: widget.gameId);
      final active = ref.read(activeGameProvider).valueOrNull;
      if (active?.gameId == widget.gameId) {
        ref.read(activeGameProvider.notifier).clearLocal();
      }
    }
    context.go('/games');
  }

  void _restartOffline() {
    final session = OfflineUnoRegistry.instance.get(widget.gameId);
    if (session == null) return;
    setState(() {
      _dealAnimated = false;
      _lastTopId = null;
      _optimisticTopId = null;
    });
    session.restart();
  }

  void _showRules(UnoGameView? game) {
    showGameRulesDialog(
      context: context,
      title: context.l10n.gamesRulesTitle,
      content: rulesTextLines(unoRuleLines(
        players: game?.players.length ?? 2,
        turnTimeSec: game?.turnTimeSec ?? 0,
        stakeBronze: game?.stakeBronze ?? 0,
        offlineBot: _isOffline,
        l10n: context.l10n,
      )),
      closeLabel: context.l10n.commonClose,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(unoGameProvider(widget.gameId));
    final game = gameAsync.valueOrNull;
    return SwipeBackScope(
      onBack: _onClose,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            tooltip: context.l10n.commonBack,
            onPressed: _onClose,
            icon: const Icon(Icons.close_rounded),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const UnoGameIcon(size: 23),
              const SizedBox(width: 8),
              Text(context.l10n.gamesUno),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: context.l10n.gamesRulesTitle,
              onPressed: () => _showRules(game),
              icon: const Icon(Icons.rule_rounded),
            ),
          ],
        ),
        body: GradientBackground(
          child: SafeArea(
            top: false,
            child: gameAsync.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              data: (value) {
                _observeView(value);
                return _buildGame(value);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentStart,
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatUserError(error),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(unoGameProvider(widget.gameId)),
                        child: Text(context.l10n.commonRetry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGame(UnoGameView game) {
    final narrow = isNarrow(context);
    final opponents = [
      for (var i = 0; i < game.players.length; i++)
        if (i != game.myIndex) MapEntry(i, game.players[i]),
    ];
    final table = Column(
      children: [
        _buildHeader(game),
        SizedBox(height: narrow ? 6 : 12),
        _buildOpponents(game, opponents),
        SizedBox(height: narrow ? 8 : 18),
        Expanded(child: _buildCenterTable(game)),
        _buildActions(game),
        SizedBox(height: narrow ? 6 : 10),
        _buildHand(game),
      ],
    );
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            narrow ? 8 : 20,
            narrow ? 4 : 10,
            narrow ? 8 : 20,
            narrow ? 8 : 16,
          ),
          child: table,
        ),
        if (game.isOver && game.iWon)
          const Positioned.fill(child: GameConfettiOverlay()),
      ],
    );
  }

  Widget _buildHeader(UnoGameView game) {
    final status = game.isOver
        ? (game.iWon ? context.l10n.unoYouWon : context.l10n.unoYouLost)
        : _statusHint(game);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GameStatusWithReward(
          statusText: status,
          showReward: false,
          rewardBronze: 0,
          rewardKey: _rewardKey,
          maxLines: 2,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.unoRoundProgress(
                game.roundNumber,
                game.targetScore,
              ),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              game.direction > 0
                  ? Icons.rotate_right_rounded
                  : Icons.rotate_left_rounded,
              size: 16,
              color: AppColors.accentStart,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                game.direction > 0
                    ? context.l10n.unoDirectionClockwise
                    : context.l10n.unoDirectionCounterclockwise,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _statusHint(UnoGameView game) {
    if (game.mustChooseColor) return context.l10n.unoChooseColorHint;
    if (game.canChallengeWd4) return context.l10n.unoWd4Hint;
    if (game.canKeepOrPlayDrawn) return context.l10n.unoDrawnHint;
    if (!game.isMyTurn) return context.l10n.unoWaitingTurn;
    return _hasLegalCard(game)
        ? context.l10n.unoPlayHint
        : context.l10n.unoDrawHint;
  }

  Widget _buildOpponents(
    UnoGameView game,
    List<MapEntry<int, UnoPlayerView>> opponents,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 7,
      children: [
        for (final entry in opponents)
          _OpponentHand(
            key: _opponentKeys.putIfAbsent(entry.key, GlobalKey.new),
            player: entry.value,
            name: _playerName(entry.value, entry.key),
            active: !game.isOver && entry.key == game.currentIndex,
          ),
      ],
    );
  }

  String _playerName(UnoPlayerView player, int index) {
    if (player.isBot) return context.l10n.offlineBotName(index);
    final displayName = player.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;
    return context.l10n.gameOpponent;
  }

  Widget _buildCenterTable(UnoGameView game) {
    final narrow = isNarrow(context);
    final cardSize = narrow ? const Size(62, 93) : const Size(78, 117);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF125D42).withValues(alpha: 0.92),
                const Color(0xFF0A3E3A).withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(narrow ? 54 : 90),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: narrow ? 22 : 48,
            vertical: narrow ? 15 : 24,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    key: _drawPileKey,
                    onTap: game.isMyTurn &&
                            !_hasLegalCard(game) &&
                            game.status == UnoStatus.active
                        ? () => _draw(game)
                        : null,
                    child: Stack(
                      children: [
                        Transform.translate(
                          offset: const Offset(4, -4),
                          child: UnoCardBackWidget(size: cardSize),
                        ),
                        UnoCardBackWidget(size: cardSize),
                        Positioned(
                          right: 6,
                          bottom: 5,
                          child: _CountBadge(count: game.drawCount),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    context.l10n.unoDrawPile,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              SizedBox(width: narrow ? 16 : 30),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    key: _discardKey,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _colorValue(game.currentColor)
                              .withValues(alpha: 0.5),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: game.topDiscard == null
                        ? SizedBox.fromSize(size: cardSize)
                        : UnoCardWidget(
                            card: game.topDiscard!,
                            size: cardSize,
                          ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: _colorValue(game.currentColor),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.unoDiscardPile,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (game.pendingDraw > 0) ...[
                SizedBox(width: narrow ? 10 : 18),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    context.l10n.unoPendingDraw(game.pendingDraw),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(UnoGameView game) {
    if (game.isOver) {
      return _isOffline
          ? FilledButton.icon(
              onPressed: _restartOffline,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.offlinePlayAgain),
            )
          : const SizedBox.shrink();
    }
    final me = game.me;
    final challengeTarget = _unoChallengeTarget(game);
    final canDraw = game.isMyTurn &&
        game.status == UnoStatus.active &&
        !_hasLegalCard(game);
    final canCallUno =
        me != null && me.handCount == 1 && !me.saidUno && !me.forfeited;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 7,
      children: [
        if (canDraw)
          FilledButton.icon(
            onPressed: _busy ? null : () => _draw(game),
            icon: const Icon(Icons.add_card_rounded),
            label: Text(context.l10n.unoDraw),
          ),
        if (game.canKeepOrPlayDrawn)
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _move(UnoActionType.keep),
            icon: const Icon(Icons.pan_tool_alt_rounded),
            label: Text(context.l10n.unoKeep),
          ),
        if (canCallUno)
          FilledButton.icon(
            onPressed: _busy ? null : () => _move(UnoActionType.callUno),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.campaign_rounded),
            label: Text(context.l10n.unoSayUno),
          ),
        if (game.canChallengeUno && challengeTarget != null)
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _move(
                      UnoActionType.challengeUno,
                      targetUserId: challengeTarget,
                    ),
            icon: const Icon(Icons.notification_important_rounded),
            label: Text(context.l10n.unoChallengeUno),
          ),
        if (game.canChallengeWd4) ...[
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _move(UnoActionType.challengeWd4),
            icon: const Icon(Icons.gavel_rounded),
            label: Text(context.l10n.unoChallengeWd4),
          ),
          FilledButton.icon(
            onPressed: _busy ? null : () => _draw(game),
            icon: const Icon(Icons.add_card_rounded),
            label: Text(context.l10n.unoDraw),
          ),
        ],
        if (game.mustChooseColor)
          FilledButton.icon(
            onPressed: _busy ? null : _choosePendingColor,
            icon: const Icon(Icons.palette_rounded),
            label: Text(context.l10n.unoChooseColor),
          ),
      ],
    );
  }

  Widget _buildHand(UnoGameView game) {
    final narrow = isNarrow(context);
    final cardSize = narrow ? const Size(58, 87) : const Size(72, 108);
    final hand = game.myHand;
    final spacing =
        hand.length > 10 ? (narrow ? 28.0 : 36.0) : (narrow ? 39.0 : 49.0);
    final width = hand.isEmpty
        ? cardSize.width
        : spacing * (hand.length - 1) + cardSize.width;
    return Column(
      key: _handKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.l10n.unoCardsCount(game.me?.handCount ?? 0),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              context.l10n.unoScore(game.me?.score ?? 0),
              style: const TextStyle(
                color: AppColors.accentStart,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: cardSize.height + (narrow ? 14 : 20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: math.max(width, MediaQuery.sizeOf(context).width - 24),
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < hand.length; i++)
                    Positioned(
                      left: math.max(
                            0,
                            (MediaQuery.sizeOf(context).width - 24 - width) / 2,
                          ) +
                          i * spacing,
                      bottom: 0,
                      child: Transform.rotate(
                        angle: hand.length <= 1
                            ? 0
                            : (i - (hand.length - 1) / 2) * 0.025,
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          key: _cardKeys.putIfAbsent(
                            hand[i].id,
                            GlobalKey.new,
                          ),
                          onTap: _canPlayCard(game, hand[i]) && !_busy
                              ? () => _playCard(game, hand[i])
                              : null,
                          child: UnoCardWidget(
                            card: hand[i],
                            size: cardSize,
                            highlighted: _canPlayCard(game, hand[i]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OpponentHand extends StatelessWidget {
  const _OpponentHand({
    super.key,
    required this.player,
    required this.name,
    required this.active,
  });

  final UnoPlayerView player;
  final String name;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    final size = narrow ? const Size(28, 42) : const Size(34, 51);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.symmetric(
        horizontal: narrow ? 8 : 11,
        vertical: narrow ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.accentStart : Colors.white12,
          width: active ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size.width + 10,
            height: size.height,
            child: Stack(
              children: [
                Positioned(
                  left: 8,
                  child: UnoCardBackWidget(size: size, elevated: false),
                ),
                UnoCardBackWidget(size: size, elevated: false),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: narrow ? 84 : 120),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                context.l10n.unoCardsCount(player.handCount),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              Text(
                context.l10n.unoScore(player.score),
                style: const TextStyle(
                  color: AppColors.accentStart,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          if (player.saidUno) ...[
            const SizedBox(width: 5),
            const Icon(
              Icons.campaign_rounded,
              size: 18,
              color: Color(0xFFE53935),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white70),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}
