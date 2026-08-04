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
  Offset? _dragGlobal;
  final Set<PlayingCard> _selected = {};
  /// Карты, скрытые в веере на время полёта/ожидания сервера.
  final Set<PlayingCard> _flyingFromHand = {};
  /// Оптимистично «приземлившиеся» атаки (пока ждём ответ сервера).
  final List<PlayingCard> _optimisticAttacks = [];
  /// Оптимистичная защита: индекс пары → карта.
  final Map<int, PlayingCard> _optimisticDefends = {};
  /// Стол скрыт на время полёта в биту.
  bool _hidingTable = false;
  Timer? _timeoutRetryTimer;
  final GlobalKey _fanKey = GlobalKey();
  final GlobalKey _defendTargetKey = GlobalKey();
  final GlobalKey _attackSlotKey = GlobalKey();
  final GlobalKey _tableKey = GlobalKey();
  final GlobalKey _deckKey = GlobalKey();
  final GlobalKey _bitoKey = GlobalKey();

  int _prevDeckCount = -1;
  int _prevBitoCount = -1;
  int _prevHandLen = -1;
  List<DurakTablePairApi> _prevTable = const [];
  bool _fxScheduled = false;

  static const Size _cardSize = Size(64, 92);

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

  bool _highlightAttackSlot(DurakGameView view) {
    final focus = _activeCard ??
        (_selected.isNotEmpty ? _selected.first : null);
    if (focus == null || _busy || view.isOver) return false;
    if (!_isAttackPhase(view)) return false;
    return view.legalAttack.any((c) => c.toPlayingCard() == focus);
  }

  /// Индекс неотбитой атаки, которую бьёт [card]; при нескольких — ближе к пальцу.
  int _defendTargetIndex(DurakGameView view, PlayingCard? card) {
    if (card == null || view.phase != 'defend') return -1;
    if (view.defenderIndex != view.myIndex) return -1;
    final trump = _suitFromApi(view.trumpSuit);
    final candidates = <int>[];
    for (var i = 0; i < view.table.length; i++) {
      final p = view.table[i];
      if (p.defense != null || _optimisticDefends.containsKey(i)) continue;
      if (card.beats(p.attack.toPlayingCard(), trump)) {
        candidates.add(i);
      }
    }
    if (candidates.isEmpty) return -1;
    if (candidates.length == 1) return candidates.first;
    final screenW = MediaQuery.sizeOf(context).width;
    final preferLeft = (_dragGlobal?.dx ?? screenW / 2) < screenW / 2;
    return preferLeft ? candidates.first : candidates.last;
  }

  bool _isAttackPhase(DurakGameView view) =>
      view.attackerIndex == view.myIndex &&
      (view.phase == 'attack' ||
          view.phase == 'attack_follow' ||
          view.phase == 'defend');

  bool _isDefendPhase(DurakGameView view) =>
      view.phase == 'defend' && view.defenderIndex == view.myIndex;

  List<PlayingCard> _cardsToPlay(DurakGameView view, PlayingCard card) {
    if (_isDefendPhase(view)) return [card];
    if (!_isAttackPhase(view)) return [card];
    if (_selected.contains(card) && _selected.length > 1) {
      return _selected.toList();
    }
    return [card];
  }

  void _toggleSelect(DurakGameView view, PlayingCard card) {
    final legal = <PlayingCard>{
      ..._apiCardsToPlaying(view.legalAttack),
      ..._apiCardsToPlaying(view.legalDefend),
    };
    if (!legal.contains(card)) return;
    // Мульти-выбор только для атаки/подкида, один ранг.
    if (!_isAttackPhase(view)) return;

    setState(() {
      if (_selected.contains(card)) {
        _selected.remove(card);
      } else if (_selected.isEmpty || _selected.first.rank == card.rank) {
        _selected.add(card);
      } else {
        _selected
          ..clear()
          ..add(card);
      }
      _activeCard = _selected.isEmpty ? null : card;
    });
  }

  Future<bool> _onCardDrop(
    DurakGameView view,
    PlayingCard card,
    Offset global,
    Rect from,
  ) async {
    if (_busy || view.isOver) return false;
    final isDefend = _isDefendPhase(view);
    final isAttack = _isAttackPhase(view);
    if (!isDefend && !isAttack) return false;

    // Вернуть в веер — только если отпустили над веером.
    final fan = globalRectOf(_fanKey);
    if (fan != null && fan.inflate(20).contains(global)) {
      return false;
    }

    // Иначе сразу летим на подсвеченное поле.
    final cards = _cardsToPlay(view, card);
    await _playCards(view, cards, fromOverride: from, pointer: global);
    return true;
  }

  Future<void> _playCards(
    DurakGameView view,
    List<PlayingCard> cards, {
    Rect? fromOverride,
    Offset? pointer,
  }) async {
    if (_busy || view.isOver || cards.isEmpty) return;
    final isDefend = _isDefendPhase(view);
    final isAttack = _isAttackPhase(view);
    if (!isDefend && !isAttack) return;
    final doDefend = isDefend &&
        view.legalDefend.any((c) => c.toPlayingCard() == cards.first);
    if (!doDefend && !isAttack) return;

    final fallback = cardFanApproxOrigin(
          _fanKey.currentContext ?? context,
          _cardSize,
        ) ??
        Rect.fromCenter(
          center: MediaQuery.sizeOf(context).center(Offset.zero),
          width: _cardSize.width,
          height: _cardSize.height,
        );

    final defendIdx = doDefend
        ? _defendTargetIndex(view, cards.first)
        : -1;
    final toKey = doDefend ? _defendTargetKey : _attackSlotKey;
    final to = (doDefend && defendIdx >= 0
            ? globalRectOf(_defendTargetKey)
            : null) ??
        globalRectOf(toKey) ??
        globalRectOf(_tableKey) ??
        Rect.fromCenter(
          center: MediaQuery.sizeOf(context).center(Offset.zero),
          width: _cardSize.width,
          height: _cardSize.height,
        );

    // Сразу убрать из веера — без двойника на время полёта и ответа сервера.
    setState(() {
      _activeCard = null;
      _selected.clear();
      _dragGlobal = pointer;
      _flyingFromHand.addAll(cards);
      _busy = true;
    });

    final froms = <Rect>[];
    final tos = <Rect>[];
    for (var i = 0; i < cards.length; i++) {
      froms.add(
        fromOverride?.shift(Offset(i * 10.0, i * -6.0)) ??
            fallback.shift(Offset(i * 10.0, i * -6.0)),
      );
      tos.add(to.shift(Offset(i * 14.0, 0)));
    }
    await playCardsFlyAnimation(
      context: context,
      cards: cards,
      cardSize: _cardSize,
      froms: froms,
      tos: tos,
    );
    if (!mounted) return;

    // Приземление: сразу рисуем на столе (оптимистично).
    setState(() {
      if (doDefend && defendIdx >= 0) {
        _optimisticDefends[defendIdx] = cards.first;
      } else {
        _optimisticAttacks.addAll(cards);
      }
    });

    final repo = ref.read(durakRepositoryProvider);
    try {
      if (doDefend) {
        await repo.move(widget.gameId, type: 'defend', card: cards.first);
      } else {
        await repo.move(widget.gameId, type: 'attack', cards: cards);
      }
      ref.invalidate(durakGameProvider(widget.gameId));
      // Дождаться нового состояния — иначе карта мигнёт обратно в веер.
      try {
        await ref.read(durakGameProvider(widget.gameId).future);
      } catch (_) {}
    } on GamesException catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _flyingFromHand.removeAll(cards);
          _optimisticAttacks.clear();
          _optimisticDefends.clear();
          _busy = false;
          _dragGlobal = null;
        });
      }
    }
  }

  Future<void> _take() async {
    final repo = ref.read(durakRepositoryProvider);
    await _act(() => repo.move(widget.gameId, type: 'take'));
  }

  Future<void> _bito() async {
    // Сначала анимация стола → бита, потом ход на сервер.
    final snapshot = List<DurakTablePairApi>.of(
      _prevTable.isNotEmpty
          ? _prevTable
          : (ref.read(durakGameProvider(widget.gameId)).valueOrNull?.table ??
              const []),
    );
    _prevTable = const [];
    if (snapshot.isNotEmpty) {
      setState(() => _hidingTable = true);
      await _animateTableToBito(snapshot);
    }
    if (!mounted) return;
    final repo = ref.read(durakRepositoryProvider);
    try {
      await _act(() => repo.move(widget.gameId, type: 'bito'));
    } finally {
      if (mounted) setState(() => _hidingTable = false);
    }
  }

  Future<void> _animateDealToFan(int n) async {
    if (n <= 0 || !mounted) return;
    final from = globalRectOf(_deckKey) ??
        Rect.fromCenter(
          center: MediaQuery.sizeOf(context).center(Offset.zero),
          width: _cardSize.width,
          height: _cardSize.height,
        );
    final to = cardFanApproxOrigin(
          _fanKey.currentContext ?? context,
          _cardSize,
        ) ??
        Rect.fromCenter(
          center: Offset(
            MediaQuery.sizeOf(context).width / 2,
            MediaQuery.sizeOf(context).height * 0.85,
          ),
          width: _cardSize.width,
          height: _cardSize.height,
        );
    final dummy = PlayingCard(Rank.six, Suit.spades);
    await playCardsFlyAnimation(
      context: context,
      cards: List.generate(n, (_) => dummy),
      cardSize: _cardSize,
      froms: List.generate(n, (i) => from.shift(Offset(i * 2.0, i * 2.0))),
      tos: List.generate(n, (i) => to.shift(Offset((i - n / 2) * 12, 0))),
      faceDown: true,
      duration: const Duration(milliseconds: 420),
      stagger: const Duration(milliseconds: 70),
    );
  }

  Future<void> _animateTableToBito(List<DurakTablePairApi> table) async {
    if (table.isEmpty || !mounted) return;
    final bitoRect = globalRectOf(_bitoKey) ??
        Rect.fromCenter(
          center: Offset(
            MediaQuery.sizeOf(context).width * 0.85,
            MediaQuery.sizeOf(context).height * 0.45,
          ),
          width: _cardSize.width,
          height: _cardSize.height,
        );
    final cards = <PlayingCard>[];
    final froms = <Rect>[];
    final tos = <Rect>[];
    final angles = <double>[];
    final center = MediaQuery.sizeOf(context).center(Offset.zero);
    var i = 0;
    for (final p in table) {
      cards.add(p.attack.toPlayingCard());
      froms.add(Rect.fromCenter(
        center: center.translate((i - table.length / 2) * 40, -20),
        width: _cardSize.width,
        height: _cardSize.height,
      ));
      tos.add(rectJitter(bitoRect, _cardSize, _prevBitoCount + 1, i));
      angles.add((i.isEven ? 1 : -1) * (0.25 + i * 0.08));
      i++;
      if (p.defense != null) {
        cards.add(p.defense!.toPlayingCard());
        froms.add(Rect.fromCenter(
          center: center.translate((i - table.length / 2) * 40, 0),
          width: _cardSize.width,
          height: _cardSize.height,
        ));
        tos.add(rectJitter(bitoRect, _cardSize, _prevBitoCount + 1, i));
        angles.add((i.isEven ? 1 : -1) * (0.3 + i * 0.07));
        i++;
      }
    }
    await playCardsFlyAnimation(
      context: context,
      cards: cards,
      cardSize: _cardSize,
      froms: froms,
      tos: tos,
      endAngles: angles,
      duration: const Duration(milliseconds: 450),
      stagger: const Duration(milliseconds: 40),
    );
  }

  void _maybeRunTableFx(DurakGameView view) {
    if (_fxScheduled) return;
    final handLen = view.hands.length > view.myIndex && view.myIndex >= 0
        ? (view.hands[view.myIndex].cards?.length ??
            view.hands[view.myIndex].count)
        : 0;
    final deck = view.deckCount;
    final bito = view.bitoCount;

    // Первый кадр — только запомнить базу.
    if (_prevDeckCount < 0) {
      _prevDeckCount = deck;
      _prevBitoCount = bito;
      _prevHandLen = handLen;
      _prevTable = List.of(view.table);
      return;
    }

    final dealt = handLen - _prevHandLen;
    final deckDropped = _prevDeckCount - deck;
    final bitoGrew = bito > _prevBitoCount && _prevTable.isNotEmpty;
    final tableSnapshot = List<DurakTablePairApi>.of(_prevTable);

    _prevDeckCount = deck;
    _prevBitoCount = bito;
    _prevHandLen = handLen;
    _prevTable = List.of(view.table);

    if (dealt > 0 && deckDropped > 0) {
      _fxScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _animateDealToFan(dealt.clamp(1, 6));
        if (mounted) _fxScheduled = false;
      });
    } else if (bitoGrew && !_busy && !_hidingTable) {
      // Бито от соперника / уже применённое состояние.
      _fxScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        setState(() => _hidingTable = true);
        await _animateTableToBito(tableSnapshot);
        if (mounted) {
          setState(() => _hidingTable = false);
          _fxScheduled = false;
        }
      });
    }
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
          centerTitle: true,
          titleSpacing: 0,
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
              // Горизонтальный shrink-прогресс внизу — мой ход.
              if (view != null && !view.isOver && view.isMyTurn)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 4,
                  child: TurnTimerBottomBar(
                    key: ValueKey('my-bar-${view.turnDeadline}'),
                    active: true,
                    turnDeadline: view.turnDeadline,
                    turnTimeSec: view.turnTimeSec,
                    onExpired: _onTurnTimeExpired,
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
    const cardSize = _cardSize;
    _maybeRunTableFx(view);
    // Сбросить выбор, если карты уже не в руке / нелегальны.
    final myHand = _apiCardsToPlaying(
      view.hands.length > view.myIndex && view.myIndex >= 0
          ? (view.hands[view.myIndex].cards ?? const [])
          : const [],
    );
    final legal = <PlayingCard>{
      ..._apiCardsToPlaying(view.legalAttack),
      ..._apiCardsToPlaying(view.legalDefend),
    };
    if (_selected.isNotEmpty) {
      final stale = _selected
          .where((c) => !myHand.contains(c) || !legal.contains(c))
          .toList();
      if (stale.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _selected.removeAll(stale));
        });
      }
    }
    final trumpCard = view.trumpCard.toPlayingCard();

    // Соперники по кругу (кроме себя).
    final opponents = <int>[];
    for (var i = 0; i < view.hands.length; i++) {
      if (i != view.myIndex) opponents.add(i);
    }

    final handForFan = myHand
        .where((c) => !_flyingFromHand.contains(c))
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 8, 8),
      child: Column(
        children: [
          // Панель соперника справа + веер карт к нему.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _opponentsHeader(view),
                  for (final oi in opponents) _opponentFan(view, oi, cardSize),
                ],
              ),
            ],
          ),
          if (!view.isOver && _opponentOfferedDraw(view))
            Padding(
              padding: const EdgeInsets.only(top: 4),
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
          if (view.isOver)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GameStatusLine(
                text: _turnHint(view),
                highlight: true,
              ),
            ),
          Expanded(
            child: _buildBoard(view, cardSize, trumpCard),
          ),
          SizedBox(
            height: cardSize.height * 1.55,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final n = handForFan.length;
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
                        cards: handForFan,
                        cardSize: cardSize,
                        legalCards: legal,
                        selectedCards: _selected,
                        hiddenCards: _flyingFromHand,
                        enabled: !view.isOver && view.canAct && !_busy,
                        onActiveChanged: (c) {
                          if (_activeCard == c) return;
                          setState(() => _activeCard = c);
                        },
                        onDragPosition: (p) {
                          if (_dragGlobal == p) return;
                          setState(() => _dragGlobal = p);
                        },
                        onTap: (c) {
                          // Тап = поднять в выбор; повторный / мульти — сыграть.
                          if (_selected.contains(c) || _selected.isNotEmpty) {
                            final play = _selected.isNotEmpty &&
                                    _selected.contains(c)
                                ? _selected.toList()
                                : [c];
                            unawaited(_playCards(view, play));
                          } else {
                            setState(() {
                              _selected
                                ..clear()
                                ..add(c);
                              _activeCard = c;
                            });
                          }
                        },
                        onLongPress: (c) => _toggleSelect(view, c),
                        onDrop: (c, global, from) =>
                            _onCardDrop(view, c, global, from),
                      );
                      return Transform.scale(
                        scale: scale,
                        alignment: Alignment.bottomCenter,
                        child: fan,
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 4,
                  child: _sideActionButton(view),
                ),
              ],
            ),
          ),
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

    final oppTurn = !view.isOver && !view.isMyTurn;
    final card = GameOpponentCard(
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
      maxWidth: 280,
      align: Alignment.centerRight,
      borderWidth: oppTurn ? 0 : 2,
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
    if (!oppTurn) return card;
    return TurnTimerBorder(
      key: ValueKey('opp-border-${view.turnDeadline}'),
      active: true,
      turnDeadline: view.turnDeadline,
      turnTimeSec: view.turnTimeSec,
      borderWidth: 2.5,
      radius: 22,
      onExpired: _onTurnTimeExpired,
      child: card,
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
    // Веер «к» панели соперника: перевёрнут, плотнее, ближе.
    return Transform(
      alignment: Alignment.topCenter,
      transform: Matrix4.rotationZ(3.14159265),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        child: CardFan(
          key: ValueKey('opp-$idx-$count'),
          cards: fake,
          cardSize: Size(cardSize.width * 0.42, cardSize.height * 0.42),
          faceDown: true,
          enabled: false,
          arc: 0.35,
          spacing: cardSize.width * 0.18,
        ),
      ),
    );
  }

  Widget _buildBoard(
    DurakGameView view,
    Size cardSize,
    PlayingCard trumpCard,
  ) {
    final highlightAttack = _highlightAttackSlot(view);
    final focus = _activeCard ??
        (_selected.isNotEmpty ? _selected.first : null);
    final defendPairIndex = _defendTargetIndex(view, focus);
    final showAttackSlot = !view.isOver &&
        view.attackerIndex == view.myIndex &&
        (view.phase == 'attack' ||
            view.phase == 'attack_follow' ||
            view.phase == 'defend');

    // Колода: чуть спрятана влево, козырь полностью виден справа от стопки.
    final fullDeckW = cardSize.width + 40;
    final deckPeek = KeyedSubtree(
      key: _deckKey,
      child: SizedBox(
        width: fullDeckW * 0.72,
        height: cardSize.height + 28,
        child: ClipRect(
          child: OverflowBox(
            maxWidth: fullDeckW,
            alignment: Alignment.centerRight,
            child: DurakDeckPile(
              deckCount: view.deckCount,
              trumpCard: trumpCard,
              trumpSuit: _suitFromApi(view.trumpSuit),
              cardSize: cardSize,
            ),
          ),
        ),
      ),
    );

    final bitoPeek = KeyedSubtree(
      key: _bitoKey,
      child: DurakBitoPile(
        count: view.bitoCount,
        cardSize: cardSize,
        peek: true,
      ),
    );

    final tablePairs = <Widget>[
      if (!_hidingTable) ...[
        for (var i = 0; i < view.table.length; i++)
          _AnimatedTablePair(
            key: ValueKey(
              'pair-$i-${view.table[i].attack.rank}'
              '${view.table[i].attack.suit}-'
              '${view.table[i].defense?.rank ?? _optimisticDefends[i]?.rank.value ?? 0}'
              '${view.table[i].defense?.suit ?? _optimisticDefends[i]?.suit.name ?? ''}',
            ),
            pair: view.table[i],
            cardSize: cardSize,
            highlightAttack: i == defendPairIndex,
            defendTargetKey: i == defendPairIndex ? _defendTargetKey : null,
            optimisticDefense: _optimisticDefends[i],
          ),
        for (var i = 0; i < _optimisticAttacks.length; i++)
          Padding(
            key: ValueKey('opt-atk-$i-${_optimisticAttacks[i]}'),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: PlayingCardWidget(
              card: _optimisticAttacks[i],
              size: cardSize,
              elevated: true,
              highlighted: true,
            ),
          ),
      ],
      if (showAttackSlot)
        Padding(
          key: _attackSlotKey,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: DurakDropSlot(
            size: cardSize,
            active: highlightAttack,
          ),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Стол по центру — без видимой рамки «поля».
            Positioned.fill(
              child: Center(
                child: KeyedSubtree(
                  key: _tableKey,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.78,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 8,
                      children: tablePairs,
                    ),
                  ),
                ),
              ),
            ),
            // Колода — вертикальный центр слева.
            Align(
              alignment: Alignment.centerLeft,
              child: deckPeek,
            ),
            // Бита — вертикальный центр справа.
            Align(
              alignment: Alignment.centerRight,
              child: bitoPeek,
            ),
          ],
        );
      },
    );
  }

  /// «Взять» / «Бито» — левый нижний угол.
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
      return const SizedBox.shrink();
    }

    final take = canTake;
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      color: AppColors.accentStart,
      child: InkWell(
        onTap: take ? _take : _bito,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                take ? Icons.file_download_rounded : Icons.check_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                take ? 'Взять' : 'Бито',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
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
    this.optimisticDefense,
  });

  final DurakTablePairApi pair;
  final Size cardSize;
  final bool highlightAttack;
  final GlobalKey? defendTargetKey;
  final PlayingCard? optimisticDefense;

  @override
  Widget build(BuildContext context) {
    final defense = pair.defense?.toPlayingCard() ?? optimisticDefense;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.86, end: 1),
        duration: const Duration(milliseconds: 220),
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
                dropTarget: highlightAttack && defense == null,
              ),
              if (defense != null)
                Positioned(
                  left: 10,
                  top: 14,
                  child: PlayingCardWidget(
                    card: defense,
                    size: cardSize,
                    elevated: true,
                    highlighted: optimisticDefense != null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
