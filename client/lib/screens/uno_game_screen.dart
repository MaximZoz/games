import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/game_balance_settle.dart';
import 'package:multigames_client/games/game_eliminate.dart';
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
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';
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
  bool _dealing = false;
  bool _dealAnimated = false;
  bool _colorDialogOpen = false;
  bool _bindingsInitialized = false;
  bool _observeEntered = false;
  bool _balanceGainPlayed = false;
  bool _lossChipRevealed = false;
  bool _isRematching = false;
  bool _isAcceptingRematch = false;
  bool _isFindingGame = false;
  bool _rematchDeclined = false;
  bool _iDeclinedRematch = false;
  String? _rematchLobbyId;
  String? _optimisticTopId;
  String? _lastLocalActor;
  String? _lastLocalDrawActor;
  String? _lastLocalPlayCardId;
  final Set<String> _localPlayedIds = {};
  final Set<String> _hiddenHandIds = {};
  final Set<String> _pendingDrawnIds = {};
  final Map<int, int> _pendingOppDraw = {};
  UnoCard? _discardOverride;
  int _seenEventSeq = 0;
  int _dealHeroShown = 0;
  int _seenRoundNumber = 0;
  int _seenLastRoundNumber = 0;
  bool _roundOverlayDismissed = false;
  final Map<int, int> _dealOppShown = {};

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
    if (_seenRoundNumber != 0 &&
        game.roundNumber != _seenRoundNumber &&
        game.status == UnoStatus.active) {
      _dealAnimated = false;
      _discardOverride = null;
      _hiddenHandIds.clear();
      _pendingDrawnIds.clear();
      _pendingOppDraw.clear();
      _localPlayedIds.clear();
    }
    _seenRoundNumber = game.roundNumber;
    if (game.lastRoundNumber != _seenLastRoundNumber) {
      _seenLastRoundNumber = game.lastRoundNumber;
      _roundOverlayDismissed = false;
    }
    final topId = game.topDiscard?.id;
    if (!_dealAnimated) {
      _seenEventSeq = game.eventSeq;
      _dealAnimated = true;
      _dealing = true;
      _dealHeroShown = 0;
      _dealOppShown.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_animateInitialDeal(game));
      });
    } else if (game.eventSeq > _seenEventSeq && !_busy) {
      _seenEventSeq = game.eventSeq;
      final ownCard = game.lastEventCard?.id ?? topId;
      final meId = game.viewerUserId ??
          ref.read(authStateProvider).valueOrNull?.id ??
          _lastLocalActor;
      final skipOwnPlay = game.lastEventType == 'play' &&
          ((ownCard != null &&
                  (_localPlayedIds.contains(ownCard) ||
                      ownCard == _lastLocalPlayCardId ||
                      ownCard == _optimisticTopId)) ||
              (game.lastEventActor.isNotEmpty &&
                  meId != null &&
                  game.lastEventActor == meId));
      if (!skipOwnPlay) {
        if (game.lastDrawCount > 0 &&
            game.lastDrawUserId.isNotEmpty &&
            game.lastDrawUserId != _lastLocalDrawActor) {
          if (meId != null && game.lastDrawUserId == meId) {
            final hide = game.lastDrawCount >= game.myHand.length
                ? game.myHand
                : game.myHand.sublist(game.myHand.length - game.lastDrawCount);
            _pendingDrawnIds.addAll(hide.map((card) => card.id));
          } else if (game.lastDrawUserId != meId) {
            final drawIndex = game.players
                .indexWhere((player) => player.id == game.lastDrawUserId);
            if (drawIndex >= 0 && drawIndex != game.myIndex) {
              _pendingOppDraw[drawIndex] =
                  (_pendingOppDraw[drawIndex] ?? 0) + game.lastDrawCount;
            }
          }
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_handleRemoteEvent(game));
        });
      }
    }

    if (game.mustChooseColor && !_colorDialogOpen && game.isMyTurn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_choosePendingColor());
      });
    }
    if (game.iAmEliminated && !_observeEntered && !game.isOver && !_isOffline) {
      _observeEntered = true;
      enterGameObservation(ref, widget.gameId, gameType: 'uno');
      _maybeSettleGame(game);
    }
    if (game.isOver && !_isOffline) {
      clearBlockingGamePin(ref, ifGameId: widget.gameId);
      final active = ref.read(activeGameProvider).valueOrNull;
      if (active?.gameId == widget.gameId) {
        ref.read(activeGameProvider.notifier).clearLocal();
      }
      _maybeSettleGame(game);
    }
  }

  Future<void> _handleRemoteEvent(UnoGameView game) async {
    final meId = game.viewerUserId ??
        ref.read(authStateProvider).valueOrNull?.id ??
        _lastLocalActor;
    if (shouldAnimateRemoteUnoPlay(
      lastEventType: game.lastEventType,
      lastEventActor: game.lastEventActor,
      viewerUserId: meId,
      myIndex: game.myIndex,
      players: game.players,
      topCardId: game.topDiscard?.id,
      localPlayCardId: _lastLocalPlayCardId ?? _optimisticTopId,
      lastEventCardId: game.lastEventCard?.id,
      localPlayedIds: _localPlayedIds,
    )) {
      final fromIndex =
          game.players.indexWhere((player) => player.id == game.lastEventActor);
      if (fromIndex >= 0 && fromIndex != game.myIndex) {
        await _animateOpponentPlay(game, fromIndex);
      }
    }
    if (game.lastEventType == 'wd4_reveal' && game.lastEventCard != null) {
      await _animateWd4Reveal(game);
    }
    if (game.lastDrawCount > 0 &&
        game.lastDrawUserId.isNotEmpty &&
        game.lastDrawUserId != _lastLocalDrawActor) {
      if (meId != null && game.lastDrawUserId == meId) {
        final hide = game.lastDrawCount >= game.myHand.length
            ? game.myHand
            : game.myHand.sublist(game.myHand.length - game.lastDrawCount);
        await _animateHeroDraw(hide);
      } else {
        await _animateOpponentDraw(
          game,
          game.lastDrawUserId,
          game.lastDrawCount,
        );
      }
    }
  }

  Future<void> _animateHeroDraw(List<UnoCard> cards) async {
    if (cards.isEmpty) return;
    final from = _rectOf(_drawPileKey);
    final to = _rectOf(_handKey);
    if (from == null || to == null || !mounted) {
      if (mounted) {
        setState(() => _pendingDrawnIds.removeAll(cards.map((card) => card.id)));
      }
      return;
    }
    for (final card in cards) {
      if (!mounted) return;
      await playUnoCardFlyAnimation(
        context: context,
        card: card,
        cardSize: _flyCardSize(context),
        from: from,
        to: to,
        faceDown: true,
        flipToFace: true,
        arcLift: 36,
      );
      if (mounted) {
        setState(() => _pendingDrawnIds.remove(card.id));
      }
    }
  }

  Future<void> _animateInitialDeal(UnoGameView game) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    setState(() => _busy = true);
    final from = _rectOf(_drawPileKey);
    if (from == null) {
      if (mounted) {
        setState(() {
          _dealing = false;
          _busy = false;
        });
      }
      return;
    }
    final size = _flyCardSize(context);
    for (var round = 0; round < 7; round++) {
      for (var playerIndex = 0;
          playerIndex < game.players.length;
          playerIndex++) {
        if (!mounted) {
          return;
        }
        if (game.players[playerIndex].forfeited) continue;
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
          duration: const Duration(milliseconds: 220),
          faceDown: !isMe,
          beginScale: 0.85,
          endScale: 1,
          arcLift: 18,
        ));
        if (mounted) {
          setState(() {
            if (isMe) {
              _dealHeroShown++;
            } else {
              _dealOppShown[playerIndex] =
                  (_dealOppShown[playerIndex] ?? 0) + 1;
            }
          });
        }
        await Future<void>.delayed(const Duration(milliseconds: 48));
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() {
      _dealing = false;
      _busy = false;
    });
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

  Future<void> _animateOpponentDraw(
    UnoGameView game,
    String userId,
    int count,
  ) async {
    final playerIndex =
        game.players.indexWhere((player) => player.id == userId);
    if (playerIndex < 0 || playerIndex == game.myIndex) return;
    final from = _rectOf(_drawPileKey);
    final to = _rectOf(_opponentKeys.putIfAbsent(playerIndex, GlobalKey.new));
    if (from == null || to == null || !mounted) return;
    final size = _flyCardSize(context);
    for (var i = 0; i < count; i++) {
      if (!mounted) return;
      await playUnoCardFlyAnimation(
        context: context,
        card: const UnoCard(
          id: 'opp-draw',
          color: UnoColor.wild,
          kind: UnoCardKind.wild,
        ),
        cardSize: size,
        from: from,
        to: to,
        duration: const Duration(milliseconds: 280),
        faceDown: true,
        beginScale: 0.9,
        endScale: 0.72,
        arcLift: 26,
      );
      if (mounted) {
        setState(() {
          final left = (_pendingOppDraw[playerIndex] ?? 1) - 1;
          if (left <= 0) {
            _pendingOppDraw.remove(playerIndex);
          } else {
            _pendingOppDraw[playerIndex] = left;
          }
        });
      }
    }
  }

  Future<void> _animateWd4Reveal(UnoGameView game) async {
    final card = game.lastEventCard;
    if (card == null) return;
    final actorIndex =
        game.players.indexWhere((player) => player.id == game.lastEventActor);
    final from = actorIndex >= 0
        ? _rectOf(_opponentKeys.putIfAbsent(actorIndex, GlobalKey.new))
        : _rectOf(_discardKey);
    final to = _rectOf(_discardKey);
    if (from == null || to == null || !mounted) return;
    final mid = Rect.fromCenter(
      center: Offset(
        (from.center.dx + to.center.dx) / 2,
        (from.center.dy + to.center.dy) / 2 - 36,
      ),
      width: to.width,
      height: to.height,
    );
    final shown = await playUnoCardFlyAnimation(
      context: context,
      card: card,
      cardSize: _flyCardSize(context),
      from: from,
      to: mid,
      faceDown: true,
      flipToFace: true,
      keepAtEnd: true,
      duration: const Duration(milliseconds: 420),
      arcLift: 28,
    );
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    shown.dismiss();
    if (!mounted) return;
    await playUnoCardFlyAnimation(
      context: context,
      card: card,
      cardSize: _flyCardSize(context),
      from: mid,
      to: from,
      duration: const Duration(milliseconds: 320),
      beginScale: 1,
      endScale: 0.7,
      arcLift: 16,
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
    setState(() => _busy = true);
    _lastLocalActor = game.viewerUserId ?? game.me?.id;
    try {
      UnoColor? color;
      if (card.isWild) {
        color = await _showColorPicker();
        if (color == null || !mounted) return;
      }
      final from = _rectOf(_cardKeys.putIfAbsent(card.id, GlobalKey.new));
      final to = _rectOf(_discardKey);
      _lastLocalPlayCardId = card.id;
      _optimisticTopId = card.id;
      _localPlayedIds.add(card.id);
      if (mounted) {
        setState(() {
          _hiddenHandIds.add(card.id);
          _discardOverride = game.topDiscard;
        });
      }
      if (from != null && to != null && mounted) {
        final ticket = await playUnoCardFlyAnimation(
          context: context,
          card: card,
          cardSize: _flyCardSize(context),
          from: from,
          to: to,
          beginAngle: 0.05,
          endAngle: -0.04,
          arcLift: 42,
          keepAtEnd: true,
        );
        if (mounted) {
          setState(() => _discardOverride = card);
        }
        ticket.dismiss();
      } else if (mounted) {
        setState(() => _discardOverride = card);
      }
      await _move(
        UnoActionType.play,
        cardId: card.id,
        color: color,
        manageBusy: false,
      );
      try {
        final after = await ref.read(unoGameProvider(widget.gameId).future);
        if (after.topDiscard?.id == card.id || after.eventSeq > _seenEventSeq) {
          _seenEventSeq = after.eventSeq;
        }
        if (!mounted) return;
        setState(() {
          if (after.topDiscard?.id == card.id) {
            _discardOverride = null;
            _hiddenHandIds.remove(card.id);
          } else if (after.myHand.any((item) => item.id == card.id)) {
            _hiddenHandIds.remove(card.id);
            _discardOverride = null;
            _localPlayedIds.remove(card.id);
            _lastLocalPlayCardId = null;
            _optimisticTopId = null;
          }
        });
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _draw(UnoGameView before) async {
    if (_busy) return;
    _lastLocalDrawActor = before.me?.id;
    final from = _rectOf(_drawPileKey);
    await _move(UnoActionType.draw);
    if (!mounted) return;
    UnoGameView? after;
    try {
      after = await ref.read(unoGameProvider(widget.gameId).future);
    } catch (_) {}
    if (!mounted) return;
    final oldIds = before.myHand.map((card) => card.id).toSet();
    final drawn = after?.myHand
            .where((card) => !oldIds.contains(card.id))
            .toList(growable: false) ??
        const <UnoCard>[];
    if (drawn.isNotEmpty) {
      setState(() => _pendingDrawnIds.addAll(drawn.map((card) => card.id)));
    }
    final to = _rectOf(_handKey);
    if (from == null || to == null) {
      if (mounted && drawn.isNotEmpty) {
        setState(
            () => _pendingDrawnIds.removeAll(drawn.map((card) => card.id)));
      }
      return;
    }
    for (final card in drawn) {
      if (!mounted) return;
      await playUnoCardFlyAnimation(
        context: context,
        card: card,
        cardSize: _flyCardSize(context),
        from: from,
        to: to,
        faceDown: true,
        flipToFace: true,
        arcLift: 36,
      );
      if (mounted) {
        setState(() => _pendingDrawnIds.remove(card.id));
      }
    }
    if (drawn.isEmpty && mounted) {
      await playUnoCardFlyAnimation(
        context: context,
        card: const UnoCard(
          id: 'draw-back',
          color: UnoColor.wild,
          kind: UnoCardKind.wild,
        ),
        cardSize: _flyCardSize(context),
        from: from,
        to: to,
        faceDown: true,
        arcLift: 36,
      );
    }
  }

  Future<void> _move(
    String type, {
    String? cardId,
    UnoColor? color,
    String? targetUserId,
    bool manageBusy = true,
  }) async {
    if (manageBusy) {
      if (_busy) return;
      setState(() => _busy = true);
    }
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
      if (manageBusy && mounted) setState(() => _busy = false);
    }
  }

  bool _canPlayCard(UnoGameView game, UnoCard card) {
    if (!game.isMyTurn || game.topDiscard == null) return false;
    if (game.status == UnoStatus.awaitingDrawnPlay) {
      return card.id == game.drawnCardId;
    }
    if (game.pendingDraw > 0) {
      return card.stacksOn(game.topDiscard!) &&
          (game.status == UnoStatus.active ||
              game.status == UnoStatus.awaitingWd4Challenge);
    }
    if (game.status != UnoStatus.active) return false;
    return card.matches(game.topDiscard!, game.currentColor);
  }

  bool _canTakeFromDeck(UnoGameView game) {
    if (!game.isMyTurn) return false;
    if (game.status == UnoStatus.awaitingWd4Challenge) {
      return game.pendingDraw > 0;
    }
    if (game.status != UnoStatus.active) return false;
    return game.pendingDraw > 0 || !_hasLegalCard(game);
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
    final eliminated = game?.iAmEliminated == true;
    await handleGameScreenClose(
      context: context,
      isActive: game != null && !game.isOver && !eliminated,
      canLeaveFreely: eliminated,
      onLeaveFinished: () async {
        if (eliminated && game != null && !game.isOver && !_isOffline) {
          enterGameObservation(ref, widget.gameId, gameType: 'uno');
          _observeEntered = true;
        }
        _goToGames(keepObservation: eliminated && game != null && !game.isOver);
      },
      onForfeitAndLeave: () async {
        final multi = (game?.players.length ?? 0) > 2;
        try {
          clearBlockingGamePin(ref, ifGameId: widget.gameId);
          await ref.read(unoRepositoryProvider).forfeit(widget.gameId);
        } catch (_) {}
        if (!mounted) return;
        if (multi && !_isOffline) {
          enterGameObservation(ref, widget.gameId, gameType: 'uno');
          _observeEntered = true;
        }
        _goToGames(keepObservation: multi);
        unawaited(ref.read(activeGameProvider.notifier).refresh());
      },
    );
  }

  void _goToGames({bool keepObservation = false}) {
    final rematchLobbyId = _rematchLobbyId;
    _rematchLobbyId = null;
    if (!_isOffline) {
      clearBlockingGamePin(ref, ifGameId: widget.gameId);
      final active = ref.read(activeGameProvider).valueOrNull;
      if (active?.gameId == widget.gameId) {
        ref.read(activeGameProvider.notifier).clearLocal();
      }
    }
    context.go('/games');
    if (!keepObservation && rematchLobbyId != null) {
      unawaited(
        ref
            .read(unoRepositoryProvider)
            .leaveLobby(rematchLobbyId)
            .catchError((_) {}),
      );
    }
  }

  void _onTurnTimeExpired() {
    if (!mounted) return;
    if (_isOffline) {
      unawaited(_move(UnoActionType.forfeit));
      return;
    }
    ref.invalidate(unoGameProvider(widget.gameId));
  }

  bool _showTimer(UnoGameView game) =>
      !game.isOver &&
      game.turnTimeSec > 0 &&
      game.turnDeadline > 0 &&
      !game.iAmEliminated;

  Widget _buildMyTurnTimerChip(UnoGameView game) {
    return TurnTimerBorder(
      key: ValueKey('uno-timer-border-${game.turnDeadline}'),
      active: _showTimer(game),
      turnDeadline: game.turnDeadline,
      turnTimeSec: game.turnTimeSec,
      borderWidth: 2.5,
      radius: 14,
      onExpired: _onTurnTimeExpired,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceUnified.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          width: 82,
          height: 28,
          child: Center(
            child: GameTurnCountdown(
              key: ValueKey('uno-turn-clock-${game.turnDeadline}'),
              turnDeadline: game.turnDeadline,
              turnTimeSec: game.turnTimeSec,
              isMyTurn: game.isMyTurn,
              onExpired: _onTurnTimeExpired,
              labelBuilder: (seconds) => context.l10n.gameSecondsLeft(seconds),
            ),
          ),
        ),
      ),
    );
  }

  void _maybeSettleGame(UnoGameView game) {
    if (_isOffline || _balanceGainPlayed) return;
    if (!game.isOver && !game.iAmEliminated) return;
    if (isGameBalanceSettled(ref, widget.gameId)) {
      _balanceGainPlayed = true;
      return;
    }
    _balanceGainPlayed = true;
    if (game.stakeBronze <= 0) {
      markGameBalanceSettled(ref, widget.gameId);
      unawaited(ref.read(authStateProvider.notifier).refresh());
      return;
    }
    final humans = game.players.where((player) => !player.isBot).length;
    final iWon = game.iWon;
    final credit = iWon ? game.stakeBronze * humans : 0;
    final display = iWon ? game.stakeBronze * (humans > 1 ? humans - 1 : 0) : 0;
    final lost = !iWon && game.stakeBronze > 0 ? game.stakeBronze : 0;
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
          if (mounted) setState(() => _lossChipRevealed = true);
          return;
        }
        await playGameSettledReward(
          ref: ref,
          context: context,
          creditBronze: credit,
          displayRewardBronze: display,
          sourceKey: display > 0 ? _rewardKey : null,
        );
      }());
    });
  }

  List<String> _peerIds(UnoGameView game) => [
        for (final player in game.players)
          if (player.id != game.me?.id && !player.isBot) player.id,
      ];

  Future<void> _rematch() async {
    setState(() => _isRematching = true);
    try {
      if (_isOffline) {
        _restartOffline();
        if (mounted) setState(() => _isRematching = false);
        return;
      }
      final lobbyId =
          await ref.read(unoRepositoryProvider).rematch(widget.gameId);
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
              gameType: 'uno',
            ),
          );
      setState(() {
        _rematchLobbyId = lobbyId;
        _rematchDeclined = false;
        _iDeclinedRematch = false;
        _isRematching = false;
      });
      context.go('/games/uno/lobby/$lobbyId?mode=invite');
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
      final result = await ref.read(unoRepositoryProvider).joinLobby(lobbyId);
      if (!mounted) return;
      clearBlockingGamePin(ref);
      if (result.gameId != null && result.gameId!.isNotEmpty) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'game',
                gameId: result.gameId,
                lobbyId: lobbyId,
                gameType: 'uno',
              ),
            );
        pinBlockingGame(ref, result.gameId, gameType: 'uno');
        context.go('/games/uno/game/${result.gameId}');
      } else {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'lobby',
                lobbyId: lobbyId,
                gameType: 'uno',
              ),
            );
        context.go('/games/uno/lobby/$lobbyId?mode=invite');
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
      await ref.read(unoRepositoryProvider).declineLobby(lobbyId);
    } catch (_) {}
    if (mounted) setState(() => _iDeclinedRematch = true);
  }

  Future<void> _cancelRematchWait() async {
    if (_rematchLobbyId == null) return;
    final lobbyId = _rematchLobbyId!;
    setState(() => _rematchLobbyId = null);
    try {
      await ref.read(unoRepositoryProvider).leaveLobby(lobbyId);
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
              .read(unoRepositoryProvider)
              .leaveLobby(rematchId)
              .catchError((_) {}),
        );
      }
      final game = ref.read(unoGameProvider(widget.gameId)).valueOrNull;
      final created = await ref.read(unoRepositoryProvider).createLobby(
            mode: 'matchmake',
            maxPlayers: game?.players.length ?? 2,
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
                gameType: 'uno',
              ),
            );
        pinBlockingGame(ref, created.gameId, gameType: 'uno');
        context.go('/games/uno/game/${created.gameId}');
        return;
      }
      ref.read(activeGameProvider.notifier).setLocal(
            ActiveGameItem(
              type: 'lobby',
              lobbyId: created.lobbyId,
              gameType: 'uno',
            ),
          );
      context.go('/games/uno/lobby/${created.lobbyId}?mode=matchmake');
    } catch (_) {
      if (mounted) context.go('/games');
    } finally {
      if (mounted) setState(() => _isFindingGame = false);
    }
  }

  void _openGroupChat(UnoGameView game) {
    final chatId = game.chatId?.trim() ?? '';
    if (chatId.isEmpty) return;
    context.push('/chats/$chatId');
  }

  void _restartOffline() {
    final session = OfflineUnoRegistry.instance.get(widget.gameId);
    if (session == null) return;
    setState(() {
      _dealAnimated = false;
      _dealing = false;
      _dealHeroShown = 0;
      _dealOppShown.clear();
      _optimisticTopId = null;
      _discardOverride = null;
      _hiddenHandIds.clear();
      _pendingDrawnIds.clear();
      _pendingOppDraw.clear();
      _seenEventSeq = 0;
      _lastLocalActor = null;
      _lastLocalDrawActor = null;
      _lastLocalPlayCardId = null;
    });
    _seenRoundNumber = 0;
    _seenLastRoundNumber = 0;
    _roundOverlayDismissed = false;
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
    final groupChatId = (game?.chatId ?? '').trim();
    final showGroupChat =
        !_isOffline && game != null && groupChatId.isNotEmpty && !game.isOver;
    final groupUnread = !showGroupChat
        ? 0
        : ref.watch(chatsListProvider.select((async) {
            final list = async.valueOrNull;
            if (list == null) return 0;
            for (final chat in list) {
              if (chat.chatID == groupChatId) return chat.unreadCount;
            }
            return 0;
          }));
    // Нижняя зона (веер) исключена — полоса свайпа/крестика не перехватывает
    // крайнюю левую карту, как в дураке.
    final swipeBottomExclude = MediaQuery.sizeOf(context).height * 0.42;
    return SwipeBackScope(
      onBack: _onClose,
      opaqueEdge: false,
      edgeWidth: 16,
      triggerDistance: 44,
      bottomInset: swipeBottomExclude,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leadingWidth: showGroupChat ? 96 : 48,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: context.l10n.commonBack,
                onPressed: _onClose,
                icon: const Icon(Icons.close_rounded),
              ),
              if (game != null && showGroupChat)
                GameIconWithBadge(
                  icon: Icons.chat_bubble_outline_rounded,
                  tooltip: context.l10n.chatGroupTooltip,
                  badge: groupUnread,
                  onPressed: () => _openGroupChat(game),
                ),
            ],
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
            SizedBox(
              width: 96,
              height: 36,
              child: game != null && _showTimer(game)
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: _buildMyTurnTimerChip(game),
                    )
                  : const SizedBox.shrink(),
            ),
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
        if (!_roundOverlayDismissed &&
            (game.isBetweenRounds || (game.isOver && game.hasRoundResult)))
          Positioned.fill(
            child: _UnoRoundScoreOverlay(
              game: game,
              nameOf: (player, index) => _playerName(player, index),
              onContinue: _busy
                  ? null
                  : () {
                      if (game.isBetweenRounds) {
                        unawaited(_move(UnoActionType.nextRound));
                      } else {
                        setState(() => _roundOverlayDismissed = true);
                      }
                    },
            ),
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
        SizedBox(
          height: 40,
          child: GameStatusWithReward(
            statusText: status,
            showReward: game.isOver &&
                (game.iWon || _lossChipRevealed) &&
                game.stakeBronze > 0,
            rewardBronze: game.iWon
                ? game.stakeBronze *
                    (game.players.where((p) => !p.isBot).length > 1
                        ? game.players.where((p) => !p.isBot).length - 1
                        : 0)
                : -game.stakeBronze,
            rewardKey: _rewardKey,
            maxLines: 2,
          ),
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
    if (game.isBetweenRounds) return context.l10n.unoRoundScoresTitle;
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
          TurnTimerBorder(
            active: !game.isOver &&
                !_dealing &&
                !entry.value.forfeited &&
                game.turnTimeSec > 0 &&
                entry.key == game.currentIndex,
            turnDeadline: game.turnDeadline,
            turnTimeSec: game.turnTimeSec,
            borderWidth: 2.5,
            radius: 16,
            showIdleBorder: !entry.value.forfeited,
            onExpired: _onTurnTimeExpired,
            child: UnoOpponentHand(
              key: _opponentKeys.putIfAbsent(entry.key, GlobalKey.new),
              player: entry.value,
              name: _playerName(entry.value, entry.key),
              active: !game.isOver &&
                  !entry.value.forfeited &&
                  entry.key == game.currentIndex,
              displayCount: entry.value.forfeited
                  ? 0
                  : _dealing
                      ? (_dealOppShown[entry.key] ?? 0)
                      : math.max(
                          0,
                          entry.value.handCount -
                              (_pendingOppDraw[entry.key] ?? 0),
                        ),
              onProfileTap: entry.value.isBot
                  ? null
                  : () => unawaited(_openOpponentProfile(
                        game,
                        entry.value,
                        entry.key,
                      )),
            ),
          ),
      ],
    );
  }

  Future<void> _openOpponentProfile(
    UnoGameView game,
    UnoPlayerView player,
    int index,
  ) async {
    await showUserProfileDialog(
      context: context,
      ref: ref,
      userId: player.id,
      displayName: _playerName(player, index),
      avatarKind: player.avatarKind,
      avatarValue: player.avatarValue,
      frameCode: player.frameCode,
      frameColor: player.frameColor,
      messageFrom: 'games',
      messageReturnPath: '/games/uno/game/${widget.gameId}',
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
    final shownDiscard = unoVisibleDiscard(
      serverTop: game.topDiscard,
      override: _discardOverride,
    );
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
                    onTap: _canTakeFromDeck(game) && !_busy
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
                    child: shownDiscard == null
                        ? SizedBox.fromSize(size: cardSize)
                        : UnoCardWidget(
                            card: shownDiscard,
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
    if (game.isBetweenRounds) {
      return FilledButton.icon(
        onPressed: _busy ? null : () => _move(UnoActionType.nextRound),
        icon: const Icon(Icons.skip_next_rounded),
        label: Text(context.l10n.unoRoundContinue),
      );
    }
    if (game.isOver) {
      return _isOffline
          ? FilledButton.icon(
              onPressed: _restartOffline,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.offlinePlayAgain),
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
              onAccept: (lobbyId) => unawaited(_acceptRematch(lobbyId)),
              onDecline: (lobbyId) => unawaited(_declineRematch(lobbyId)),
              onCancelWait: () => unawaited(_cancelRematchWait()),
              onFindGame: () => unawaited(_findGame()),
              compact: isNarrow(context),
            );
    }
    final me = game.me;
    final challengeTarget = _unoChallengeTarget(game);
    final canDraw = _canTakeFromDeck(game) && !game.canChallengeWd4;
    final canCallUno =
        me != null && me.handCount == 1 && !me.saidUno && !me.forfeited;
    return SizedBox(
      height: 48,
      child: Center(
        child: Wrap(
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
                onPressed:
                    _busy ? null : () => _move(UnoActionType.challengeWd4),
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
        ),
      ),
    );
  }

  Widget _buildHand(UnoGameView game) {
    final narrow = isNarrow(context);
    final cardSize = narrow ? const Size(58, 87) : const Size(72, 108);
    final hand = _dealing
        ? game.myHand.take(_dealHeroShown).toList(growable: false)
        : unoVisibleHand(game.myHand, {..._hiddenHandIds, ..._pendingDrawnIds});
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
              context.l10n.unoCardsCount(
                _dealing
                    ? _dealHeroShown
                    : unoVisibleHand(
                        game.myHand,
                        {..._hiddenHandIds, ..._pendingDrawnIds},
                      ).length,
              ),
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

class UnoOpponentHand extends StatelessWidget {
  const UnoOpponentHand({
    super.key,
    required this.player,
    required this.name,
    required this.active,
    required this.displayCount,
    this.onProfileTap,
  });

  final UnoPlayerView player;
  final String name;
  final bool active;
  final int displayCount;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    final size = narrow ? const Size(28, 42) : const Size(34, 51);
    final left = player.forfeited;
    return Opacity(
      opacity: left ? 0.45 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: narrow ? 8 : 11,
              vertical: narrow ? 5 : 7,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard.withValues(alpha: left ? 0.45 : 0.88),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GamePlayerAvatar(
                  displayName: name,
                  avatarKind: player.avatarKind,
                  avatarValue: player.avatarValue,
                  frameCode: player.frameCode,
                  frameColor: player.frameColor,
                  compact: true,
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: size.width + 10,
                  height: size.height,
                  child: left
                      ? null
                      : Stack(
                          children: [
                            Positioned(
                              left: 8,
                              child:
                                  UnoCardBackWidget(size: size, elevated: false),
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
                        style: TextStyle(
                          color: left
                              ? AppColors.textSecondary
                              : active
                                  ? AppColors.accentStart
                                  : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          decoration:
                              left ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    Text(
                      context.l10n.unoCardsCount(displayCount),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      context.l10n.unoScore(player.score),
                      style: TextStyle(
                        color: left
                            ? AppColors.textSecondary
                            : AppColors.accentStart,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                if (player.saidUno && !left) ...[
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.campaign_rounded,
                    size: 18,
                    color: Color(0xFFE53935),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnoRoundScoreOverlay extends StatelessWidget {
  const _UnoRoundScoreOverlay({
    required this.game,
    required this.nameOf,
    this.onContinue,
  });

  final UnoGameView game;
  final String Function(UnoPlayerView player, int index) nameOf;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final narrow = isNarrow(context);
    final winnerIndex = game.players.indexWhere(
      (player) => player.id == game.lastRoundWinnerUserId,
    );
    final winnerName = winnerIndex >= 0
        ? nameOf(game.players[winnerIndex], winnerIndex)
        : l10n.commonPlayer;
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: narrow ? 340 : 420,
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.fromLTRB(
              narrow ? 16 : 22,
              narrow ? 16 : 22,
              narrow ? 16 : 22,
              narrow ? 14 : 18,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.unoRoundScoresTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.unoRoundWonBy(winnerName),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.accentStart,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.unoRoundPointsAwarded(game.lastRoundPoints),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < game.players.length; i++) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nameOf(game.players[i], i),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: i == winnerIndex
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: game.players[i].forfeited
                                  ? AppColors.textSecondary
                                  : null,
                              decoration: game.players[i].forfeited
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        Text(
                          l10n.unoScore(game.players[i].score),
                          style: TextStyle(
                            color: i == winnerIndex
                                ? AppColors.accentStart
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (i != game.players.length - 1) const SizedBox(height: 6),
                  ],
                  if (onContinue != null) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onContinue,
                      child: Text(l10n.unoRoundContinue),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
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
