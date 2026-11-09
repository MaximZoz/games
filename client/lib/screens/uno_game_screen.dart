import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_grid.dart';
import 'package:multigames_client/core/gamepad/gamepad_glyph.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/core/sfx.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/game_balance_settle.dart';
import 'package:multigames_client/games/game_stake.dart';
import 'package:multigames_client/games/offline_session_hold.dart';
import 'package:multigames_client/games/game_eliminate.dart';
import 'package:multigames_client/games/game_turn_action.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException;
import 'package:multigames_client/games/uno/uno_card.dart';
import 'package:multigames_client/games/uno/uno_engine.dart';
import 'package:multigames_client/games/uno/uno_offline_session.dart';
import 'package:multigames_client/games/uno/uno_provider.dart';
import 'package:multigames_client/games/uno/uno_repository.dart';
import 'package:multigames_client/games/uno/uno_rules.dart';
import 'package:multigames_client/games/uno/uno_center_table_style.dart';
import 'package:multigames_client/games/uno/uno_seats.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/game_table_fit.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/uno/uno_draw_discard_field.dart';
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
  final GameTurnActionLock _turnAction = GameTurnActionLock();
  bool _dealing = false;
  bool _dealAnimated = false;
  bool _colorDialogOpen = false;
  int _gamepadHandIndex = 0;
  int _gamepadColorIndex = 0;
  bool _bindingsInitialized = false;
  bool _observeEntered = false;
  bool _balanceGainPlayed = false;
  bool _isRematching = false;
  bool _isAcceptingRematch = false;
  bool _isFindingGame = false;
  bool _rematchDeclined = false;
  bool _iDeclinedRematch = false;
  String? _rematchLobbyId;
  Timer? _rematchPollTimer;
  ProviderSubscription<AsyncValue<Map<String, dynamic>>>? _realtimeSubscription;
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
  int _heardUnoCallSeq = 0;
  int _dealHeroShown = 0;
  int _seenRoundNumber = 0;
  int _seenLastRoundNumber = 0;
  bool _roundOverlayDismissed = false;
  final Map<int, int> _dealOppShown = {};
  Timer? _unoCatchTimer;
  Timer? _busyWatchdog;
  int _busyStuckTicks = 0;

  bool get _isOffline => OfflineUnoRegistry.instance.isOffline(widget.gameId);

  @override
  void didUpdateWidget(covariant UnoGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId == widget.gameId) return;
    _rematchPollTimer?.cancel();
    _optimisticTopId = null;
    _discardOverride = null;
    _localPlayedIds.clear();
    _hiddenHandIds.clear();
    _pendingDrawnIds.clear();
    _pendingOppDraw.clear();
    _roundOverlayDismissed = false;
    setState(() {
      _rematchLobbyId = null;
      _rematchDeclined = false;
      _iDeclinedRematch = false;
      _isRematching = false;
      _isAcceptingRematch = false;
      _isFindingGame = false;
    });
    ref.invalidate(unoGameProvider(widget.gameId));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bindingsInitialized) return;
    _bindingsInitialized = true;
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
    _busyWatchdog?.cancel();
    _busyWatchdog = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      if (_busy && !_dealing) {
        _busyStuckTicks++;
        if (_busyStuckTicks >= 3) {
          _busyStuckTicks = 0;
          _turnAction.release();
          setState(() => _busy = false);
          if (!_isOffline) ref.invalidate(unoGameProvider(widget.gameId));
        }
      } else {
        _busyStuckTicks = 0;
      }
    });
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
    _unoCatchTimer?.cancel();
    _rematchPollTimer?.cancel();
    _realtimeSubscription?.close();
    _busyWatchdog?.cancel();
    GameFlyOverlay.dismissAll();
    super.dispose();
  }

  void _armUnoCatchTimer(UnoGameView game) {
    _unoCatchTimer?.cancel();
    final at = game.unoVulnerableAtMs;
    if (at <= 0) return;
    final wait = at - DateTime.now().millisecondsSinceEpoch;
    if (wait <= 0) return;
    _unoCatchTimer = Timer(Duration(milliseconds: wait + 20), () {
      if (mounted) setState(() {});
    });
  }

  Rect? _rectOf(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  /// Высота, на которой стол помещается в полный размер: шапка + стол с
  /// колодой и сбросом + ряд кнопок («Взять», «Уно!», выбор цвета) + рука.
  static const double _tableDesignHeight = 430;

  /// Подгонка под доступную высоту — в альбоме телефона её ~330 px.
  GameTableFit _fit = const GameTableFit(scale: 1, compact: false);

  Size _flyCardSize(BuildContext context) => _fit.scaled(
        isNarrow(context) ? const Size(52, 78) : const Size(62, 93),
      );

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
    final alreadyDealt = _dealAnimated;
    if (alreadyDealt &&
        shouldPlayUnoCallSfx(
          eventSeq: game.eventSeq,
          heardSeq: _heardUnoCallSeq,
          lastEventType: game.lastEventType,
        )) {
      _heardUnoCallSeq = game.eventSeq;
      Sfx.play(SfxId.unoCall);
    }
    if (game.lastRoundNumber != _seenLastRoundNumber) {
      _seenLastRoundNumber = game.lastRoundNumber;
      _roundOverlayDismissed = false;
    }
    final topId = game.topDiscard?.id;
    if (!_dealAnimated) {
      _seenEventSeq = game.eventSeq;
      _heardUnoCallSeq = game.eventSeq;
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
        setState(
            () => _pendingDrawnIds.removeAll(cards.map((card) => card.id)));
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
    Sfx.play(SfxId.cardPlay);
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
          playSfx: false,
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
    final cards = game.lastPlayedCards.isNotEmpty
        ? game.lastPlayedCards
        : [
            if (game.lastEventCard != null) game.lastEventCard!,
            if (game.lastEventCard == null && game.topDiscard != null)
              game.topDiscard!,
          ];
    final from = _rectOf(
      _opponentKeys.putIfAbsent(playerIndex, GlobalKey.new),
    );
    final to = _rectOf(_discardKey);
    if (cards.isEmpty || from == null || to == null || !mounted) return;
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
        arcLift: 34,
      );
    }
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
    _gamepadColorIndex = 0;
    const colors = [
      UnoColor.red,
      UnoColor.yellow,
      UnoColor.green,
      UnoColor.blue,
    ];
    final result = await showDialog<UnoColor>(
      context: context,
      builder: (dialogContext) {
        final compact = MediaQuery.sizeOf(dialogContext).width < 380;
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return GamepadScope(
              onAction: (action) {
                if (action == GamepadAction.shoulderL ||
                    action == GamepadAction.shoulderR) {
                  return false;
                }
                if (action.isDirection) {
                  setSheet(() {
                    _gamepadColorIndex =
                        cycleIndex(_gamepadColorIndex, colors.length, action);
                  });
                  return true;
                }
                if (action == GamepadAction.confirm) {
                  Navigator.of(dialogContext).pop(colors[_gamepadColorIndex]);
                  return true;
                }
                if (action == GamepadAction.cancel) {
                  Navigator.of(dialogContext).pop();
                  return true;
                }
                return true;
              },
              child: AlertDialog(
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
                  for (var i = 0; i < colors.length; i++)
                    Semantics(
                      label: _colorName(colors[i]),
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.of(dialogContext).pop(colors[i]),
                        child: Container(
                          width: compact ? 88 : 112,
                          height: compact ? 58 : 70,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _colorValue(colors[i]),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: i == _gamepadColorIndex
                                  ? Colors.white
                                  : Colors.white70,
                              width: i == _gamepadColorIndex ? 4 : 2,
                            ),
                          ),
                          child: Text(
                            _colorName(colors[i]),
                            style: TextStyle(
                              color: colors[i] == UnoColor.yellow
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
        ),
            );
          },
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
    if (_busy || !game.isMyTurn) return;
    if (!_canPlayCard(game, card)) {
      Sfx.play(SfxId.deny);
      if (mounted && game.stackOpen && game.topDiscard != null) {
        showAppSnackBar(
          context,
          message: context.l10n.unoErrStackSameOnly,
          kind: AppSnackKind.error,
        );
      }
      return;
    }
    if (!_turnAction.tryAcquire()) return;
    _busy = true;
    setState(() {});
    _lastLocalActor = game.viewerUserId ?? game.me?.id;
    try {
      UnoColor? color;
      if (card.isWild) {
        color = await _showColorPicker();
        if (color == null || !mounted) return;
      }
      final from = _rectOf(_cardKeys.putIfAbsent(card.id, GlobalKey.new));
      final to = _rectOf(_discardKey);
      final twin = findUnoTwin(game.myHand, card);
      final thrown = [card, if (twin != null) twin];
      Sfx.play(SfxId.cardPlay);
      _lastLocalPlayCardId = thrown.last.id;
      _optimisticTopId = thrown.last.id;
      _localPlayedIds.addAll(thrown.map((item) => item.id));
      if (mounted) {
        setState(() {
          _hiddenHandIds.addAll(thrown.map((item) => item.id));
          _discardOverride = game.topDiscard;
        });
      }
      for (var i = 0; i < thrown.length; i++) {
        final flying = thrown[i];
        final fromRect = i == 0
            ? from
            : _rectOf(_cardKeys.putIfAbsent(flying.id, GlobalKey.new)) ?? from;
        if (fromRect != null && to != null && mounted) {
          final ticket = await playUnoCardFlyAnimation(
            context: context,
            card: flying,
            cardSize: _flyCardSize(context),
            from: fromRect,
            to: to,
            beginAngle: 0.05,
            endAngle: -0.04,
            arcLift: 42,
            keepAtEnd: true,
            playSfx: i > 0,
          );
          if (mounted) {
            setState(() => _discardOverride = flying);
          }
          ticket.dismiss();
        } else if (mounted) {
          setState(() => _discardOverride = flying);
        }
      }
      await _move(
        UnoActionType.play,
        cardId: card.id,
        color: color,
        manageBusy: false,
      );
      try {
        final after = await ref.read(unoGameProvider(widget.gameId).future);
        final topId = thrown.last.id;
        if (after.topDiscard?.id == topId || after.eventSeq > _seenEventSeq) {
          _seenEventSeq = after.eventSeq;
        }
        if (!mounted) return;
        setState(() {
          if (after.topDiscard?.id == topId ||
              thrown.any((item) => after.topDiscard?.id == item.id)) {
            _discardOverride = null;
            _hiddenHandIds.removeAll(thrown.map((item) => item.id));
          } else if (after.myHand.any((item) => item.id == card.id)) {
            _hiddenHandIds.removeAll(thrown.map((item) => item.id));
            _discardOverride = null;
            _localPlayedIds.removeAll(thrown.map((item) => item.id));
            _lastLocalPlayCardId = null;
            _optimisticTopId = null;
          }
        });
      } catch (_) {}
    } finally {
      _turnAction.release();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _draw(UnoGameView before) async {
    if (!unoDrawControlEnabled(
      busy: _busy,
      canTake: _canTakeFromDeck(before),
    )) {
      return;
    }
    if (!_turnAction.tryAcquire()) return;
    _busy = true;
    setState(() {});
    _lastLocalDrawActor = before.me?.id;
    final from = _rectOf(_drawPileKey);
    final to = _rectOf(_handKey);
    // Рубашка летит сразу, лицо подставляем, когда сервер пришлёт карту.
    final fly = (from != null && to != null)
        ? playUnoCardFlyAnimation(
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
            keepAtEnd: true,
          )
        : null;
    try {
      await _move(UnoActionType.draw, manageBusy: false);
      if (!mounted) {
        final ticket = await fly;
        ticket?.dismiss();
        return;
      }
      UnoGameView? after;
      try {
        after = await ref.read(unoGameProvider(widget.gameId).future);
      } catch (_) {}
      if (!mounted) {
        final ticket = await fly;
        ticket?.dismiss();
        return;
      }
      final oldIds = before.myHand.map((card) => card.id).toSet();
      final drawn = after?.myHand
              .where((card) => !oldIds.contains(card.id))
              .toList(growable: false) ??
          const <UnoCard>[];
      if (drawn.isNotEmpty) {
        setState(() => _pendingDrawnIds.addAll(drawn.map((card) => card.id)));
      }
      final tickets = <UnoCardFlyTicket>[];
      final ticket = await fly;
      if (ticket != null) tickets.add(ticket);
      if (drawn.length > 1 && from != null && to != null && mounted) {
        for (var i = 1; i < drawn.length; i++) {
          if (!mounted) break;
          tickets.add(
            await playUnoCardFlyAnimation(
              context: context,
              card: drawn[i],
              cardSize: _flyCardSize(context),
              from: from,
              to: to,
              faceDown: true,
              arcLift: 28,
              keepAtEnd: true,
              playSfx: false,
            ),
          );
        }
      }
      if (!mounted) {
        for (final t in tickets) {
          t.dismiss();
        }
        return;
      }
      await WidgetsBinding.instance.endOfFrame;
      for (final t in tickets) {
        t.dismiss();
      }
      if (drawn.isNotEmpty && mounted) {
        setState(
            () => _pendingDrawnIds.removeAll(drawn.map((card) => card.id)));
      }
    } finally {
      _turnAction.release();
      if (mounted) setState(() => _busy = false);
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
      if (!_turnAction.tryAcquire()) return;
      _busy = true;
      setState(() {});
    }
    if (type == UnoActionType.chooseColor ||
        type == UnoActionType.challengeUno ||
        type == UnoActionType.challengeWd4) {
      Sfx.play(SfxId.unoSpecial);
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
      if (mounted && !isStaleNotYourTurnError(error)) {
        showAppSnackBar(
          context,
          message: formatUserError(error),
          kind: AppSnackKind.error,
        );
      }
    } catch (error) {
      if (mounted && !isStaleNotYourTurnError(error)) {
        showAppSnackBar(
          context,
          message: formatUserError(error),
          kind: AppSnackKind.error,
        );
      }
    } finally {
      if (manageBusy) {
        _turnAction.release();
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  bool _canPlayCard(UnoGameView game, UnoCard card) {
    if (!game.isMyTurn || game.topDiscard == null) return false;
    if (game.status == UnoStatus.awaitingDrawnPlay) {
      return card.id == game.drawnCardId;
    }
    if (game.stackOpen) {
      return card.stacksOn(game.topDiscard!);
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
        } else if (game != null && game.isOver && !_isOffline) {
          await playHeadToHeadFinish(
            ref: ref,
            context: context,
            gameId: widget.gameId,
            stakeBronze: game.stakeBronze,
            iWon: game.iWon,
            isDraw: game.isDraw,
            playerCount: game.players.length,
          );
        }
        if (!mounted) return;
        _goToGames(keepObservation: eliminated && game != null && !game.isOver);
      },
      onForfeitAndLeave: () async {
        final multi = (game?.players.length ?? 0) > 2;
        var forfeited = false;
        try {
          clearBlockingGamePin(ref, ifGameId: widget.gameId);
          await ref.read(unoRepositoryProvider).forfeit(widget.gameId);
          forfeited = true;
        } catch (_) {}
        if (!mounted) return;
        if (forfeited && game != null && !_isOffline) {
          await playHeadToHeadFinish(
            ref: ref,
            context: context,
            gameId: widget.gameId,
            stakeBronze: game.stakeBronze,
            iWon: false,
            isDraw: false,
            playerCount: game.players.length,
          );
        }
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
    leaveGamesSession(ref);
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
    final lost = stakeLostOnFinish(
      stakeBronze: game.stakeBronze,
      isDraw: game.isDraw,
      iWon: iWon,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(() async {
        if (isGameBalanceSettled(ref, widget.gameId)) return;
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
      final game = ref.read(unoGameProvider(widget.gameId)).valueOrNull;
      setState(() {
        _rematchLobbyId = lobbyId;
        _rematchDeclined = false;
        _iDeclinedRematch = false;
        _isRematching = false;
      });
      if (!rematchStayOnGameScreen(playerCount: game?.players.length ?? 2)) {
        if (!mounted) return;
        context.go('/games/uno/lobby/$lobbyId?mode=invite');
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
          await ref.read(unoRepositoryProvider).leaveLobby(own);
        } catch (_) {}
        if (!mounted) return;
      }
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

  void _startRematchPoll() {
    _rematchPollTimer?.cancel();
    if (_rematchLobbyId == null) return;
    _rematchPollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_rematchLobbyId == null || !mounted) return;
      ref.invalidate(activeGameProvider);
      try {
        final lobby =
            await ref.read(unoRepositoryProvider).getLobby(_rematchLobbyId!);
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
            gameType: 'uno',
          ),
        );
    pinBlockingGame(ref, gameId, gameType: 'uno');
    ref.invalidate(unoGameProvider(gameId));
    if (!mounted) return;
    context.go('/games/uno/game/$gameId');
  }

  Future<void> _declineRematch(String lobbyId) async {
    ref.read(gameInvitesProvider.notifier).dismiss(lobbyId);
    try {
      await ref.read(unoRepositoryProvider).declineLobby(lobbyId);
    } catch (_) {}
    if (mounted) setState(() => _iDeclinedRematch = true);
  }

  Future<void> _cancelRematchWait() async {
    if (_rematchLobbyId == null) return;
    _rematchPollTimer?.cancel();
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
        _rematchPollTimer?.cancel();
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
      _heardUnoCallSeq = 0;
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
    if (game != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _armUnoCatchTimer(game);
      });
    }
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
    return GamepadScope(
      onAction: (action) {
        final current = ref.read(unoGameProvider(widget.gameId)).valueOrNull;
        if (current == null) return false;
        return _onGamepad(current, action);
      },
      child: SwipeBackScope.gameBoard(
      onBack: _onClose,
      bottomInset: swipeBottomExclude,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          toolbarHeight: gameToolbarHeight(context),
          leadingWidth: gameAppBarLeadingWidth(withExtra: showGroupChat),
          leading: buildGameAppBarLeading(
            onClose: _onClose,
            closeTooltip: context.l10n.commonBack,
            extra: game != null && showGroupChat
                ? GameIconWithBadge(
                    icon: Icons.chat_bubble_outline_rounded,
                    tooltip: context.l10n.chatGroupTooltip,
                    badge: groupUnread,
                    onPressed: () => _openGroupChat(game),
                  )
                : null,
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
    ),
    );
  }

  List<UnoCard> _gamepadHand(UnoGameView game) => _dealing
      ? game.myHand.take(_dealHeroShown).toList(growable: false)
      : unoVisibleHand(game.myHand, {..._hiddenHandIds, ..._pendingDrawnIds});

  bool _onGamepad(UnoGameView game, GamepadAction action) {
    if (action == GamepadAction.shoulderL ||
        action == GamepadAction.shoulderR) {
      return false;
    }
    if (game.isOver) return false;
    final hand = _gamepadHand(game);
    if (hand.isNotEmpty) {
      _gamepadHandIndex = _gamepadHandIndex.clamp(0, hand.length - 1);
    }
    if (action.isDirection) {
      if (hand.isEmpty) return true;
      setState(() {
        _gamepadHandIndex = cycleIndex(_gamepadHandIndex, hand.length, action);
      });
      return true;
    }
    if (action == GamepadAction.confirm) {
      if (_busy) return true;
      if (game.mustChooseColor) {
        unawaited(_choosePendingColor());
        return true;
      }
      if (hand.isEmpty || !game.isMyTurn) return true;
      unawaited(_playCard(game, hand[_gamepadHandIndex]));
      return true;
    }
    if (action == GamepadAction.actionY) {
      if (_busy) return true;
      if (game.canKeepOrPlayDrawn) {
        unawaited(_move(UnoActionType.keep));
      } else if (_canTakeFromDeck(game)) {
        unawaited(_draw(game));
      }
      return true;
    }
    if (action == GamepadAction.actionX) {
      if (_busy) return true;
      if (game.unoCallReady) {
        unawaited(_move(UnoActionType.callUno));
      } else if (game.canChallengeWd4) {
        unawaited(_move(UnoActionType.challengeWd4));
      } else if (game.unoCatchReady) {
        final target = _unoChallengeTarget(game);
        if (target != null) {
          unawaited(
            _move(UnoActionType.challengeUno, targetUserId: target),
          );
        }
      }
      return true;
    }
    return false;
  }

  Widget _buildGame(UnoGameView game) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _fit = gameTableFit(
          availableHeight: constraints.maxHeight,
          designHeight: _tableDesignHeight,
          minScale: 0.6,
        );
        return _buildGameBody(game);
      },
    );
  }

  Widget _buildGameBody(UnoGameView game) {
    final narrow = isNarrow(context);
    final seats = unoOpponentSeatOrder(
      myIndex: game.myIndex,
      playerCount: game.players.length,
      direction: game.direction,
    );
    final table = Column(
      children: [
        _buildHeader(game),
        SizedBox(height: narrow ? 4 : 8),
        Expanded(child: _buildTableWithSeats(game, seats)),
        _buildActions(game),
        SizedBox(height: narrow ? 6 : 8),
        _buildHand(game),
      ],
    );
    return Stack(
      children: [
        MyTurnAlert.stackLeaf(
          key: ValueKey('uno-turn-${game.isMyTurn}-${game.currentIndex}'),
          isMyTurn: game.isMyTurn && !game.isOver && !game.iAmEliminated,
        ),
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
              // Партия закончилась — итог панелью снизу, без затемнения:
              // видно, с кем играл, и можно открыть его профиль.
              anchorBottom: game.isOver,
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
    final humans = game.players.where((p) => !p.isBot).length;
    final rewardChip = stakeFinishRewardChip(
      stakeBronze: game.stakeBronze,
      isDraw: game.isDraw,
      iWon: game.iWon,
      netProfit: game.stakeBronze * (humans > 1 ? humans - 1 : 0),
    );
    final status = game.isOver
        ? (game.isDraw
            ? context.l10n.gameDraw
            : game.iWon
                ? (game.isTimeout
                    ? context.l10n.gameYouWonOpponentTimeout
                    : context.l10n.unoYouWon)
                : (game.iLostOnTimeout
                    ? context.l10n.unoYouLostTimeout
                    : context.l10n.unoYouLost))
        : _statusHint(game);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _fit.compact ? 32 : 40,
          child: GameStatusWithReward(
            statusText: status,
            showReward: stakeShowFinishReward(
              stakeBronze: game.stakeBronze,
              isOver: game.isOver,
              isDraw: game.isDraw,
              rewardChip: rewardChip,
            ),
            rewardBronze: rewardChip,
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

  Widget _buildTableWithSeats(UnoGameView game, List<int> seats) {
    // Альбом: соперники уходят на боковые колонки. Любая карточка сверху
    // съедает вертикаль, и овал с колодой и сбросом перестаёт помещаться —
    // подписи вылезают под ряд кнопок.
    if (isPhoneLandscape(context)) {
      final columns = unoLandscapeSideColumns(seats);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          if (columns[0].isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: _sideChipColumn(
                game,
                columns[0],
                alignment: Alignment.centerLeft,
              ),
            ),
          if (columns[1].isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: _sideChipColumn(
                game,
                columns[1],
                alignment: Alignment.centerRight,
              ),
            ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 136),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _buildCenterTable(game, tight: true),
              ),
            ),
          ),
        ],
      );
    }
    if (seats.length <= 1) {
      return Column(
        children: [
          if (seats.isNotEmpty) _opponentChip(game, seats.first),
          SizedBox(height: isNarrow(context) ? 8 : 12),
          Expanded(child: _buildCenterTable(game)),
        ],
      );
    }
    final left = seats.first;
    final right = seats.last;
    final top = seats.length >= 3 ? seats[1] : null;
    final sideAlignY = top == null ? -0.08 : 0.12;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (top != null)
          Align(
            alignment: Alignment.topCenter,
            child: _opponentChip(game, top),
          ),
        Align(
          alignment: Alignment(-1, sideAlignY),
          child: _opponentChip(game, left, vertical: true),
        ),
        Align(
          alignment: Alignment(1, sideAlignY),
          child: _opponentChip(game, right, vertical: true),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            isNarrow(context) ? 78 : 108,
            top != null ? 70 : 8,
            isNarrow(context) ? 78 : 108,
            4,
          ),
          child: _buildCenterTable(game),
        ),
      ],
    );
  }

  /// Колонка карточек соперников у боковой кромки (альбом).
  ///
  /// Карточки горизонтальные: вертикальные вдвое выше и парой в колонку не
  /// встают. [FittedBox] дожимает колонку, если соперников больше, чем
  /// помещается по высоте.
  Widget _sideChipColumn(
    UnoGameView game,
    List<int> seats, {
    required Alignment alignment,
  }) {
    if (seats.isEmpty) return const SizedBox.shrink();
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignment == Alignment.centerLeft
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < seats.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _opponentChip(game, seats[i]),
          ],
        ],
      ),
    );
  }

  Widget _opponentChip(
    UnoGameView game,
    int index, {
    bool vertical = false,
  }) {
    if (index < 0 || index >= game.players.length) {
      return const SizedBox.shrink();
    }
    final player = game.players[index];
    return GameActorHighlight(
      isActing: GameActorHighlight.isActingSeat(
        isCurrentActor: index == game.currentIndex,
        isOver: game.isOver,
        eliminated: player.forfeited,
        paused: _dealing,
      ),
      turnDeadline: game.turnDeadline,
      turnTimeSec: game.turnTimeSec,
      borderWidth: 2.5,
      radius: 16,
      onExpired: _onTurnTimeExpired,
      child: UnoOpponentHand(
        key: _opponentKeys.putIfAbsent(index, GlobalKey.new),
        player: player,
        name: _playerName(player, index),
        active: !game.isOver && !player.forfeited && index == game.currentIndex,
        displayCount: player.forfeited
            ? 0
            : _dealing
                ? (_dealOppShown[index] ?? 0)
                : math.max(
                    0,
                    player.handCount - (_pendingOppDraw[index] ?? 0),
                  ),
        vertical: vertical,
        onProfileTap: player.isBot
            ? null
            : () => unawaited(_openOpponentProfile(game, player, index)),
      ),
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

  Widget _buildCenterTable(UnoGameView game, {bool tight = false}) {
    final style = UnoCenterTableStyle.of(
      narrow: isNarrow(context),
      phoneLandscape: isPhoneLandscape(context),
      scale: _fit.scale,
    );
    final cardSize = style.cardSize;
    final shownDiscard = unoVisibleDiscard(
      serverTop: game.topDiscard,
      override: _discardOverride,
    );
    final field = UnoDrawDiscardField(
      style: style,
      drawLabel: context.l10n.unoDrawPile,
      discardLabel: context.l10n.unoDiscardPile,
      currentColor: _colorValue(game.currentColor),
      pendingDrawLabel: game.pendingDraw > 0
          ? context.l10n.unoPendingDraw(game.pendingDraw)
          : null,
      drawPile: GestureDetector(
        key: _drawPileKey,
        onTap: unoDrawControlEnabled(
          busy: _busy,
          canTake: _canTakeFromDeck(game),
        )
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
      discardPile: Container(
        key: _discardKey,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _colorValue(game.currentColor).withValues(alpha: 0.5),
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
    );
    if (tight) return field;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: field,
      ),
    );
  }

  ButtonStyle _unoActionStyle() {
    final compact = isWide(context);
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    final minimum = compact ? const Size(0, 36) : const Size(0, 40);
    final density = compact ? VisualDensity.compact : VisualDensity.standard;
    final tap = compact
        ? MaterialTapTargetSize.shrinkWrap
        : MaterialTapTargetSize.padded;
    return AppButtonStyles.of(
      padding: padding,
      minimumSize: minimum,
      visualDensity: density,
      tapTargetSize: tap,
    );
  }

  Widget _constrainActions(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide(context) ? 320 : 420),
        child: child,
      ),
    );
  }

  Widget _buildActions(UnoGameView game) {
    if (game.isBetweenRounds) {
      return _constrainActions(
        FilledButton.icon(
          onPressed: _busy ? null : () => _move(UnoActionType.nextRound),
          style: _unoActionStyle(),
          icon: const Icon(Icons.skip_next_rounded),
          label: Text(context.l10n.unoRoundContinue),
        ),
      );
    }
    if (game.isOver) {
      return _constrainActions(
        _isOffline
            ? FilledButton.icon(
                onPressed: _restartOffline,
                style: _unoActionStyle(),
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
                table: RematchTable(
                  gameType: 'uno',
                  stakeBronze: game.stakeBronze,
                  gameMode: 'classic',
                ),
                compact: true,
              ),
      );
    }
    final challengeTarget = _unoChallengeTarget(game);
    final canDraw = _canTakeFromDeck(game) && !game.canChallengeWd4;
    final canCallUno = game.unoCallReady;
    final filled = _unoActionStyle();
    final outlined = _unoActionStyle();
    return SizedBox(
      height: isWide(context) ? 40 : (_fit.compact ? 42 : 48),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 7,
          children: [
            if (canDraw)
              GamepadHinted(
                action: GamepadAction.actionY,
                child: FilledButton.icon(
                onPressed: unoDrawControlEnabled(busy: _busy, canTake: true)
                    ? () => _draw(game)
                    : null,
                style: filled,
                icon: const Icon(Icons.add_card_rounded),
                label: Text(context.l10n.unoDraw),
              ),
              ),
            if (game.canKeepOrPlayDrawn)
              GamepadHinted(
                action: GamepadAction.actionY,
                child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _move(UnoActionType.keep),
                style: outlined,
                icon: const Icon(Icons.pan_tool_alt_rounded),
                label: Text(context.l10n.unoKeep),
              ),
              ),
            if (canCallUno)
              GamepadHinted(
                action: GamepadAction.actionX,
                child: FilledButton.icon(
                onPressed: _busy ? null : () => _move(UnoActionType.callUno),
                style: _unoActionStyle(),
                icon: const Icon(Icons.campaign_rounded),
                label: Text(context.l10n.unoSayUno),
              ),
              ),
            if (game.unoCatchReady && challengeTarget != null)
              GamepadHinted(
                action: GamepadAction.actionX,
                child: OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _move(
                          UnoActionType.challengeUno,
                          targetUserId: challengeTarget,
                        ),
                style: outlined,
                icon: const Icon(Icons.notification_important_rounded),
                label: Text(context.l10n.unoChallengeUno),
              ),
              ),
            if (game.canChallengeWd4) ...[
              GamepadHinted(
                action: GamepadAction.actionX,
                child: OutlinedButton.icon(
                onPressed:
                    _busy ? null : () => _move(UnoActionType.challengeWd4),
                style: outlined,
                icon: const Icon(Icons.gavel_rounded),
                label: Text(context.l10n.unoChallengeWd4),
              ),
              ),
              GamepadHinted(
                action: GamepadAction.actionY,
                child: FilledButton.icon(
                onPressed: unoDrawControlEnabled(
                  busy: _busy,
                  canTake: _canTakeFromDeck(game),
                )
                    ? () => _draw(game)
                    : null,
                style: filled,
                icon: const Icon(Icons.add_card_rounded),
                label: Text(context.l10n.unoDraw),
              ),
              ),
            ],
            if (game.mustChooseColor)
              GamepadHinted(
                action: GamepadAction.confirm,
                child: FilledButton.icon(
                onPressed: _busy ? null : _choosePendingColor,
                style: filled,
                icon: const Icon(Icons.palette_rounded),
                label: Text(context.l10n.unoChooseColor),
              ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHand(UnoGameView game) {
    final narrow = isNarrow(context);
    final cardSize =
        _fit.scaled(narrow ? const Size(58, 87) : const Size(72, 108));
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
                            highlighted: _canPlayCard(game, hand[i]) ||
                                (GamepadService.instance.isRecentlyActive &&
                                    i == _gamepadHandIndex),
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
    this.vertical = false,
    this.onProfileTap,
  });

  final UnoPlayerView player;
  final String name;
  final bool active;
  final int displayCount;
  final bool vertical;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    final size = narrow ? const Size(28, 42) : const Size(32, 48);
    final left = player.forfeited;
    final nameStyle = TextStyle(
      color: left
          ? AppColors.textSecondary
          : active
              ? AppColors.accentStart
              : AppColors.textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 12,
      decoration: left ? TextDecoration.lineThrough : null,
    );
    final avatar = GamePlayerAvatar(
      userId: player.id,
      displayName: name,
      avatarKind: player.avatarKind,
      avatarValue: player.avatarValue,
      frameCode: player.frameCode,
      frameColor: player.frameColor,
      compact: true,
    );
    final backs = left
        ? const SizedBox.shrink()
        : SizedBox(
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
          );
    final stats = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          vertical ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: vertical ? 72 : (narrow ? 84 : 110)),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: vertical ? TextAlign.center : TextAlign.start,
            style: nameStyle,
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
            color: left ? AppColors.textSecondary : AppColors.accentStart,
            fontSize: 10,
          ),
        ),
      ],
    );
    final unoMark = player.saidUno && !left
        ? const Icon(
            Icons.campaign_rounded,
            size: 16,
            color: Color(0xFFE53935),
          )
        : const SizedBox.shrink();
    final body = vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              avatar,
              const SizedBox(height: 4),
              backs,
              const SizedBox(height: 4),
              stats,
              if (player.saidUno && !left) unoMark,
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              avatar,
              const SizedBox(width: 6),
              backs,
              const SizedBox(width: 6),
              stats,
              if (player.saidUno && !left) ...[
                const SizedBox(width: 5),
                unoMark,
              ],
            ],
          );
    return Opacity(
      opacity: left ? 0.45 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: vertical ? 8 : (narrow ? 8 : 10),
              vertical: vertical ? 6 : (narrow ? 5 : 6),
            ),
            decoration: BoxDecoration(
              color:
                  AppColors.surfaceCard.withValues(alpha: left ? 0.45 : 0.88),
              borderRadius: BorderRadius.circular(16),
            ),
            child: body,
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
    this.anchorBottom = false,
  });

  final UnoGameView game;
  final String Function(UnoPlayerView player, int index) nameOf;
  final VoidCallback? onContinue;

  /// Панель снизу без затемнения — плашки игроков остаются видимыми.
  final bool anchorBottom;

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
      color: anchorBottom
          ? Colors.transparent
          : Colors.black.withValues(alpha: 0.55),
      child: Align(
        alignment:
            anchorBottom ? Alignment.bottomCenter : Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: narrow ? 340 : 420,
            maxHeight: MediaQuery.sizeOf(context).height *
                (anchorBottom ? 0.6 : 0.85),
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
