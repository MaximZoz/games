import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/games/durak/durak_provider.dart';
import 'package:multigames_client/games/durak/durak_repository.dart';
import 'package:multigames_client/games/durak/durak_rules.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException;
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
  /// Стол скрыт на время полёта в биту / при взятии.
  bool _hidingTable = false;
  /// Не запускать повторный FX биты после локального смахивания.
  bool _suppressRemoteBitoFx = false;
  /// Заморозить визуальный счётчик биты на время полёта (без «вспышки» новых карт).
  int? _bitoCountFreeze;
  Timer? _timeoutRetryTimer;
  Timer? _rematchPollTimer;
  ProviderSubscription<AsyncValue<Map<String, dynamic>>>? _realtimeSubscription;
  bool _providerBindingsInitialized = false;
  bool _isRematching = false;
  bool _isAcceptingRematch = false;
  String? _rematchLobbyId;
  bool _rematchDeclined = false;
  bool _iDeclinedRematch = false;
  final Set<String> _rematchRespondedIds = <String>{};
  bool _isFindingGame = false;
  String? _prevGameStatus;
  bool _balanceGainPlayed = false;
  final GlobalKey _winRewardKey = GlobalKey();
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
  Offset _tablePanAccum = Offset.zero;

  /// Локальный порядок карт в веере (после ручной сортировки).
  List<PlayingCard>? _handOrder;

  /// Карты в руке — крупные; на столе/колоде — компактнее.
  static const Size _handCardSize = Size(92, 132);
  static const Size _tableCardSize = Size(66, 94);
  static const Size _cardSize = _handCardSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeProviderBindings();
  }

  @override
  void didUpdateWidget(covariant DurakGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId) {
      _rematchPollTimer?.cancel();
      _prevGameStatus = null;
      _balanceGainPlayed = false;
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

  void _initializeProviderBindings() {
    if (_providerBindingsInitialized) return;
    _providerBindingsInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      pinBlockingGame(ref, widget.gameId, gameType: 'durak');
      final prev = ref.read(activeGameProvider).valueOrNull;
      if (prev?.gameId != widget.gameId) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(type: 'game', gameId: widget.gameId),
            );
      }
    });
    _realtimeSubscription = ref.listenManual<AsyncValue<Map<String, dynamic>>>(
      realtimeEventsProvider,
      (_, next) {
        final type = next.valueOrNull?['type']?.toString() ?? '';
        if (type == 'lobby_updated' && _rematchLobbyId != null) {
          final lobbyId = next.valueOrNull?['lobby_id']?.toString();
          final gameId = next.valueOrNull?['game_id']?.toString();
          if (lobbyId == _rematchLobbyId && mounted) {
            if (gameId != null && gameId.isNotEmpty) {
              ref.invalidate(durakGameProvider(gameId));
              unawaited(ref.read(activeGameProvider.notifier).refresh());
              context.go('/games/durak/game/$gameId');
            }
          }
        }
        if (type == 'invite_declined') {
          final lobbyId = next.valueOrNull?['lobby_id']?.toString();
          final closed = next.valueOrNull?['closed'] != false;
          if (lobbyId == _rematchLobbyId && mounted && closed) {
            _rematchPollTimer?.cancel();
            setState(() {
              _rematchLobbyId = null;
              _rematchDeclined = true;
              _rematchRespondedIds.clear();
            });
          }
        }
        if (type == 'chat_message' || type == 'chat_list_changed') {
          if (mounted) refreshChatsList(ref, force: true);
        }
      },
    );
  }

  void _startRematchPoll() {
    _rematchPollTimer?.cancel();
    if (_rematchLobbyId == null) return;
    _rematchPollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_rematchLobbyId == null || !mounted) return;
      ref.invalidate(activeGameProvider);
      try {
        final lobby =
            await ref.read(durakRepositoryProvider).getLobby(_rematchLobbyId!);
        if (!mounted) return;
        if (lobby.gameId != null && lobby.gameId!.isNotEmpty) {
          _rematchPollTimer?.cancel();
          final gameId = lobby.gameId!;
          ref.invalidate(durakGameProvider(gameId));
          context.go('/games/durak/game/$gameId');
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

  @override
  void dispose() {
    _timeoutRetryTimer?.cancel();
    _rematchPollTimer?.cancel();
    _realtimeSubscription?.close();
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

  int _compareHandCards(PlayingCard a, PlayingCard b, Suit trump) {
    final at = a.suit == trump ? 1 : 0;
    final bt = b.suit == trump ? 1 : 0;
    if (at != bt) return at.compareTo(bt);
    final s = a.suit.index.compareTo(b.suit.index);
    if (s != 0) return s;
    return a.rank.compareTo(b.rank);
  }

  /// Порядок веера: сохраняем локальную сортировку между синками сервера.
  List<PlayingCard> _orderedHand(List<PlayingCard> serverHand, Suit trump) {
    if (_handOrder == null) return List<PlayingCard>.from(serverHand);
    final remain = serverHand.toSet();
    final out = <PlayingCard>[];
    for (final c in _handOrder!) {
      if (remain.remove(c)) out.add(c);
    }
    if (remain.isNotEmpty) {
      final added = remain.toList()
        ..sort((a, b) => _compareHandCards(a, b, trump));
      out.addAll(added);
    }
    return out;
  }

  void _sortHandInFan(List<PlayingCard> hand, Suit trump) {
    final sorted = List<PlayingCard>.from(hand)
      ..sort((a, b) => _compareHandCards(a, b, trump));
    setState(() => _handOrder = sorted);
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
    if (_busy || view.isOver) {
      _clearHandSelection();
      return false;
    }
    final isDefend = _isDefendPhase(view);
    final isAttack = _isAttackPhase(view);
    if (!isDefend && !isAttack) {
      _clearHandSelection();
      return false;
    }

    // Отпустили вне веера — сразу летим к подсвеченной цели (без «зоны»).
    final cards = _cardsToPlay(view, card);
    final started = await _playCards(
      view,
      cards,
      fromOverride: from,
      pointer: global,
    );
    if (!started) _clearHandSelection();
    return started;
  }

  void _clearHandSelection() {
    if (_selected.isEmpty && _activeCard == null && _dragGlobal == null) {
      return;
    }
    setState(() {
      _selected.clear();
      _activeCard = null;
      _dragGlobal = null;
    });
  }

  /// `true` — карта ушла в полёт/на стол; `false` — ход не начался.
  Future<bool> _playCards(
    DurakGameView view,
    List<PlayingCard> cards, {
    Rect? fromOverride,
    Offset? pointer,
  }) async {
    if (_busy || view.isOver || cards.isEmpty) return false;
    final isDefend = _isDefendPhase(view);
    final isAttack = _isAttackPhase(view);
    if (!isDefend && !isAttack) return false;
    final doDefend = isDefend &&
        view.legalDefend.any((c) => c.toPlayingCard() == cards.first);
    if (!doDefend && !isAttack) return false;

    final screen = MediaQuery.sizeOf(context);
    final fallback = cardFanApproxOrigin(
          _fanKey.currentContext ?? context,
          _handCardSize,
        ) ??
        Rect.fromCenter(
          center: screen.center(Offset.zero),
          width: _handCardSize.width,
          height: _handCardSize.height,
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
          center: Offset(screen.width / 2, screen.height * 0.42),
          width: _tableCardSize.width,
          height: _tableCardSize.height,
        );

    // Сразу убрать из веера — без двойника на время полёта и ответа сервера.
    setState(() {
      _activeCard = null;
      _selected.clear();
      _dragGlobal = pointer;
      _flyingFromHand.addAll(cards);
      _busy = true;
      if (_handOrder != null) {
        _handOrder = _handOrder!.where((c) => !cards.contains(c)).toList();
      }
    });

    final fromCenter = fromOverride?.center ?? fallback.center;
    final beginScale = fromOverride != null
        ? (fromOverride.width / _handCardSize.width).clamp(0.9, 1.2)
        : (pointer != null
            ? dragScaleTowardCenter(pointer, screen)
            : 1.0);
    final froms = <Rect>[];
    final tos = <Rect>[];
    for (var i = 0; i < cards.length; i++) {
      froms.add(
        Rect.fromCenter(
          center: fromCenter.translate(i * 10.0, i * -6.0),
          width: _handCardSize.width,
          height: _handCardSize.height,
        ),
      );
      tos.add(
        Rect.fromCenter(
          center: to.center.translate(i * 14.0, 0),
          width: _tableCardSize.width,
          height: _tableCardSize.height,
        ),
      );
    }
    // Плавное уменьшение к размеру стола; лёгкий поворот к горизонтали цели.
    final shrink = _tableCardSize.width / _handCardSize.width;
    final beginAngles = <double>[
      for (var i = 0; i < cards.length; i++)
        (i.isEven ? -1 : 1) * (0.12 + i * 0.03),
    ];
    final endAngles = <double>[
      for (var i = 0; i < cards.length; i++)
        doDefend ? (i.isEven ? 0.08 : -0.06) : 0.0,
    ];
    List<CardFlyTicket> tickets = const [];
    await playCardsFlyAnimation(
      context: context,
      cards: cards,
      cardSize: _handCardSize,
      froms: froms,
      tos: tos,
      duration: const Duration(milliseconds: 480),
      stagger: const Duration(milliseconds: 40),
      curve: Curves.easeInOutCubic,
      beginScale: beginScale,
      endScale: shrink,
      beginAngles: beginAngles,
      endAngles: endAngles,
      arcLift: 0,
      keepAtEnd: true,
      onTickets: (t) => tickets = t,
    );
    if (!mounted) {
      for (final t in tickets) {
        t.dismiss();
      }
      return true;
    }

    // Приземление: стол появляется под «застывшей» картой, затем снимаем overlay.
    setState(() {
      if (doDefend && defendIdx >= 0) {
        _optimisticDefends[defendIdx] = cards.first;
      } else {
        _optimisticAttacks.addAll(cards);
      }
    });
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) await Future<void>.delayed(const Duration(milliseconds: 16));
    for (final t in tickets) {
      t.dismiss();
    }

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
    return true;
  }

  bool _canTake(DurakGameView view) =>
      !view.isOver &&
      !_busy &&
      view.defenderIndex == view.myIndex &&
      view.phase == 'defend' &&
      view.table.isNotEmpty;

  bool _canBito(DurakGameView view) =>
      !view.isOver &&
      !_busy &&
      view.attackerIndex == view.myIndex &&
      view.phase == 'attack_follow' &&
      view.table.isNotEmpty &&
      view.table.every((p) => p.defense != null);

  Future<void> _take() async {
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    if (view == null || !_canTake(view)) return;
    final snapshot = List<DurakTablePairApi>.of(view.table);
    _prevTable = const [];
    final froms = _tableCardGlobalRects(snapshot);
    if (snapshot.isNotEmpty) {
      setState(() {
        _hidingTable = true;
        _busy = true;
      });
      await _animateTableToFan(snapshot, fromOverrides: froms);
    }
    if (!mounted) return;
    try {
      await ref.read(durakRepositoryProvider).move(widget.gameId, type: 'take');
      ref.invalidate(durakGameProvider(widget.gameId));
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
          _hidingTable = false;
          _busy = false;
        });
      }
    }
  }

  Future<void> _bito() async {
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    if (view == null || !_canBito(view)) return;
    final snapshot = List<DurakTablePairApi>.of(
      _prevTable.isNotEmpty ? _prevTable : view.table,
    );
    _prevTable = const [];
    final froms = _tableCardGlobalRects(snapshot);
    final freezeCount = view.bitoCount;
    if (snapshot.isNotEmpty) {
      setState(() {
        _hidingTable = true;
        _busy = true;
        _suppressRemoteBitoFx = true;
        _bitoCountFreeze = freezeCount;
      });
      await _animateTableToBito(snapshot, fromOverrides: froms);
    }
    if (!mounted) return;
    try {
      await ref
          .read(durakRepositoryProvider)
          .move(widget.gameId, type: 'bito');
      ref.invalidate(durakGameProvider(widget.gameId));
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
          _hidingTable = false;
          _busy = false;
          _bitoCountFreeze = null;
        });
        Future<void>.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _suppressRemoteBitoFx = false;
        });
      }
    }
  }

  List<PlayingCard> _flattenTableCards(List<DurakTablePairApi> table) {
    final cards = <PlayingCard>[];
    for (final p in table) {
      cards.add(p.attack.toPlayingCard());
      if (p.defense != null) cards.add(p.defense!.toPlayingCard());
    }
    return cards;
  }

  /// Реальные (или близкие) позиции карт стола до скрытия — без «новых» карт.
  List<Rect> _tableCardGlobalRects(List<DurakTablePairApi> table) {
    final cards = _flattenTableCards(table);
    final n = cards.length;
    if (n == 0) return const [];
    final tableRect = globalRectOf(_tableKey);
    final screen = MediaQuery.sizeOf(context);
    final center = tableRect?.center ??
        Offset(screen.width / 2, screen.height * 0.42);
    final pairW = _tableCardSize.width + 18;
    final out = <Rect>[];
    var i = 0;
    for (final p in table) {
      final col = i % 3;
      final row = i ~/ 3;
      final cx = center.dx + (col - 1) * pairW * 0.55;
      final cy = center.dy + (row - 0.3) * (_tableCardSize.height * 0.55);
      out.add(Rect.fromCenter(
        center: Offset(cx, cy),
        width: _tableCardSize.width,
        height: _tableCardSize.height,
      ));
      i++;
      if (p.defense != null) {
        out.add(Rect.fromCenter(
          center: Offset(cx + 10, cy + 14),
          width: _tableCardSize.width,
          height: _tableCardSize.height,
        ));
      }
    }
    return out;
  }

  Future<void> _animateTableToFan(
    List<DurakTablePairApi> table, {
    List<Rect>? fromOverrides,
  }) async {
    if (table.isEmpty || !mounted) return;
    final cards = _flattenTableCards(table);
    final to = cardFanApproxOrigin(
          _fanKey.currentContext ?? context,
          _handCardSize,
        ) ??
        Rect.fromCenter(
          center: Offset(
            MediaQuery.sizeOf(context).width / 2,
            MediaQuery.sizeOf(context).height * 0.85,
          ),
          width: _handCardSize.width,
          height: _handCardSize.height,
        );
    final froms = <Rect>[];
    final tos = <Rect>[];
    final beginAngles = <double>[];
    final endAngles = <double>[];
    final n = cards.length;
    for (var i = 0; i < n; i++) {
      froms.add(
        fromOverrides != null && i < fromOverrides.length
            ? fromOverrides[i]
            : Rect.fromCenter(
                center: MediaQuery.sizeOf(context).center(Offset.zero).translate(
                      (i - n / 2) * 36,
                      -10,
                    ),
                width: _tableCardSize.width,
                height: _tableCardSize.height,
              ),
      );
      // Каждая карта мягко встаёт в свой слот веера — видно по отдельности.
      final slotX = (i - (n - 1) / 2) * (_handCardSize.width * 0.28);
      tos.add(
        Rect.fromCenter(
          center: to.center.translate(slotX, -i * 3.0),
          width: _handCardSize.width,
          height: _handCardSize.height,
        ),
      );
      beginAngles.add((i.isEven ? 1 : -1) * 0.08);
      endAngles.add((i - (n - 1) / 2) * 0.04);
    }
    final grow = _handCardSize.width / _tableCardSize.width;
    await playCardsFlyAnimation(
      context: context,
      cards: cards,
      cardSize: _tableCardSize,
      froms: froms,
      tos: tos,
      duration: const Duration(milliseconds: 520),
      stagger: const Duration(milliseconds: 90),
      curve: Curves.easeOutCubic,
      beginScale: 1.0,
      endScale: grow,
      beginAngles: beginAngles,
      endAngles: endAngles,
      arcLift: 18,
    );
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
      cardSize: _handCardSize,
      froms: List.generate(
        n,
        (i) => Rect.fromCenter(
          center: from.center.translate(i * 2.0, i * 2.0),
          width: _tableCardSize.width,
          height: _tableCardSize.height,
        ),
      ),
      tos: List.generate(
        n,
        (i) => Rect.fromCenter(
          center: to.center.translate((i - n / 2) * (_handCardSize.width * 0.26), -i * 2.0),
          width: _handCardSize.width,
          height: _handCardSize.height,
        ),
      ),
      faceDown: true,
      duration: const Duration(milliseconds: 480),
      stagger: const Duration(milliseconds: 85),
      curve: Curves.easeOutCubic,
      beginScale: _tableCardSize.width / _handCardSize.width,
      endScale: 1.0,
      arcLift: 16,
    );
  }

  Future<void> _animateTableToBito(
    List<DurakTablePairApi> table, {
    List<Rect>? fromOverrides,
  }) async {
    if (table.isEmpty || !mounted) return;
    final cards = _flattenTableCards(table);
    final bitoRect = globalRectOf(_bitoKey) ??
        Rect.fromCenter(
          center: Offset(
            MediaQuery.sizeOf(context).width * 0.88,
            MediaQuery.sizeOf(context).height * 0.32,
          ),
          width: _tableCardSize.width,
          height: _tableCardSize.height,
        );
    final froms = <Rect>[];
    final tos = <Rect>[];
    final beginAngles = <double>[];
    final endAngles = <double>[];
    final n = cards.length;
    for (var i = 0; i < n; i++) {
      froms.add(
        fromOverrides != null && i < fromOverrides.length
            ? fromOverrides[i]
            : Rect.fromCenter(
                center: MediaQuery.sizeOf(context).center(Offset.zero).translate(
                      (i - n / 2) * 36,
                      -8,
                    ),
                width: _tableCardSize.width,
                height: _tableCardSize.height,
              ),
      );
      tos.add(rectJitter(bitoRect, _tableCardSize, _prevBitoCount + 1, i));
      beginAngles.add((i.isEven ? -1 : 1) * 0.06);
      endAngles.add((i.isEven ? 1 : -1) * (0.35 + i * 0.07));
    }
    List<CardFlyTicket> tickets = const [];
    await playCardsFlyAnimation(
      context: context,
      cards: cards,
      cardSize: _tableCardSize,
      froms: froms,
      tos: tos,
      beginAngles: beginAngles,
      endAngles: endAngles,
      duration: const Duration(milliseconds: 560),
      stagger: const Duration(milliseconds: 55),
      curve: Curves.easeInOutCubic,
      beginScale: 1.0,
      endScale: 0.88,
      arcLift: 12,
      keepAtEnd: true,
      onTickets: (t) => tickets = t,
    );
    if (mounted) await WidgetsBinding.instance.endOfFrame;
    for (final t in tickets) {
      t.dismiss();
    }
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
    final prevBito = _prevBitoCount;
    final bitoGrew = bito > prevBito && _prevTable.isNotEmpty;
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
    } else if (bitoGrew &&
        !_busy &&
        !_hidingTable &&
        !_suppressRemoteBitoFx) {
      // Бито от соперника — те же карты стола плавно улетают в отбой.
      _fxScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final froms = _tableCardGlobalRects(tableSnapshot);
        setState(() {
          _hidingTable = true;
          _bitoCountFreeze = prevBito;
        });
        await _animateTableToBito(tableSnapshot, fromOverrides: froms);
        if (mounted) {
          setState(() {
            _hidingTable = false;
            _bitoCountFreeze = null;
            _fxScheduled = false;
          });
        }
      });
    }
  }

  /// Сдача — остаёмся на экране итога (как в крестиках). Закрытие — выход.
  Future<void> _confirmLeave() async {
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    if (view?.isOver ?? false) {
      _handleClose();
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
    // Не выходим: после forfeit покажем итог + «Повторить» / «Другой соперник».
    unawaited(() async {
      try {
        clearBlockingGamePin(ref, ifGameId: widget.gameId);
        await ref.read(durakRepositoryProvider).forfeit(widget.gameId);
      } catch (_) {}
      if (!mounted) return;
      ref.invalidate(durakGameProvider(widget.gameId));
      unawaited(ref.read(activeGameProvider.notifier).refresh());
    }());
  }

  void _clearSessionForFinishedGame() {
    clearBlockingGamePin(ref, ifGameId: widget.gameId);
    final prev = ref.read(activeGameProvider).valueOrNull;
    if (prev?.gameId == widget.gameId) {
      ref.read(activeGameProvider.notifier).clearLocal();
    }
  }

  void _handleClose() {
    final rematchLobbyId = _rematchLobbyId;
    _rematchLobbyId = null;
    _rematchRespondedIds.clear();
    _rematchPollTimer?.cancel();
    _clearSessionForFinishedGame();
    context.go('/games');
    if (rematchLobbyId != null) {
      unawaited(
        ref
            .read(durakRepositoryProvider)
            .leaveLobby(rematchLobbyId)
            .catchError((_) {}),
      );
    }
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
      confirmLabel: context.l10n.gameOfferDraw,
    );
    if (!ok || !mounted) return;
    await _act(() => ref.read(durakRepositoryProvider).offerDraw(widget.gameId));
  }

  Future<void> _acceptDraw() async {
    final ok = await confirmGameActionDialog(
      context: context,
      title: context.l10n.gameAcceptDrawTitle,
      message: context.l10n.gameAcceptDrawConfirm,
      cancelLabel: context.l10n.commonCancel,
      confirmLabel: context.l10n.gameDraw,
    );
    if (!ok || !mounted) return;
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

  List<String> _peerIds(DurakGameView view) {
    final me = view.myIndex >= 0 && view.myIndex < view.playerIds.length
        ? view.playerIds[view.myIndex]
        : '';
    return view.playerIds
        .where((id) => id.isNotEmpty && id != me && !id.startsWith('bot:'))
        .toList();
  }

  /// Начисление банка победителю с анимацией — как в крестиках.
  Future<void> _onGameSettled({
    required int creditBronze,
    required int displayRewardBronze,
  }) async {
    if (_balanceGainPlayed) {
      unawaited(ref.read(authStateProvider.notifier).refresh());
      return;
    }
    _balanceGainPlayed = true;
    await playGameSettledReward(
      ref: ref,
      context: context,
      creditBronze: creditBronze,
      displayRewardBronze: displayRewardBronze,
      sourceKey: displayRewardBronze > 0 ? _winRewardKey : null,
    );
  }

  void _maybeSettleGame(DurakGameView view) {
    if (!view.isOver) {
      _prevGameStatus = view.status;
      return;
    }
    if (_prevGameStatus == 'active' || _prevGameStatus == null) {
      _rematchPollTimer?.cancel();
      _prevGameStatus = view.status;
      for (final peerId in _peerIds(view)) {
        ref.read(gameInvitesProvider.notifier).removeByCreatorId(peerId);
      }
      final iWon = !view.isDraw &&
          view.loserIndex >= 0 &&
          view.loserIndex != view.myIndex;
      final playersN = view.playerIds.length >= 2 ? view.playerIds.length : 2;
      final winnersN = (playersN - 1).clamp(1, playersN);
      // 1×1: банк stake*2 / чистый stake; multi: возврат + доля ставки дурака.
      final netProfit = view.isDraw
          ? 0
          : (iWon
              ? (playersN == 2
                  ? view.stakeBronze
                  : view.stakeBronze ~/ winnersN)
              : 0);
      final credit = view.isDraw
          ? view.stakeBronze
          : (iWon
              ? (playersN == 2
                  ? view.stakeBronze * 2
                  : view.stakeBronze + netProfit)
              : 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
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
          creditBronze: credit,
          displayRewardBronze: netProfit,
        ));
      });
    } else {
      _prevGameStatus = view.status;
    }
  }

  Future<void> _rematch() async {
    setState(() => _isRematching = true);
    try {
      final lobbyId =
          await ref.read(durakRepositoryProvider).rematch(widget.gameId);
      if (!mounted) return;
      ref.invalidate(durakOpenLobbiesProvider);
      clearBlockingGamePin(ref);
      ref.read(activeGameProvider.notifier).setLocal(
            ActiveGameItem(type: 'lobby', lobbyId: lobbyId),
          );
      final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
      final multiRematch = (view?.playerIds.length ?? 0) > 2;
      setState(() {
        _rematchLobbyId = lobbyId;
        _rematchDeclined = false;
        _iDeclinedRematch = false;
        _rematchRespondedIds.clear();
        _isRematching = false;
      });
      if (multiRematch) {
        if (!mounted) return;
        context.go('/games/durak/lobby/$lobbyId?mode=invite');
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
      final result =
          await ref.read(durakRepositoryProvider).joinLobby(lobbyId);
      if (!mounted) return;
      if (result.joined && result.waitingMore) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(type: 'lobby', lobbyId: lobbyId),
            );
        context.go('/games/durak/lobby/$lobbyId?mode=invite');
        return;
      }
      if (result.joined && result.gameId != null) {
        final gameId = result.gameId!;
        ref.invalidate(durakGameProvider(gameId));
        context.go('/games/durak/game/$gameId');
      }
    } on GamesException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        ref.invalidate(activeGameProvider);
        final active = await ref.read(activeGameProvider.future);
        if (!mounted) return;
        if (active != null &&
            active.type == 'game' &&
            active.gameId != null &&
            active.gameId!.isNotEmpty) {
          context.go('/games/durak/game/${active.gameId}');
        } else {
          context.go('/games');
        }
      } else {
        context.go('/games');
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
      await ref.read(durakRepositoryProvider).declineLobby(lobbyId);
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
      await ref.read(durakRepositoryProvider).leaveLobby(lobbyId);
    } catch (_) {}
  }

  Future<void> _findGame() async {
    setState(() => _isFindingGame = true);
    try {
      final rematchId = _rematchLobbyId;
      if (rematchId != null) {
        _rematchPollTimer?.cancel();
        setState(() {
          _rematchLobbyId = null;
          _rematchRespondedIds.clear();
        });
        unawaited(
          ref
              .read(durakRepositoryProvider)
              .leaveLobby(rematchId)
              .catchError((_) {}),
        );
      }

      final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
      final turnTimeSec = view?.turnTimeSec ?? 0;
      final stakeBronze = view?.stakeBronze ?? 1;
      final deckSize = view?.deckSize ?? 36;
      final gameMode = view?.mode ?? 'podkidnoi';
      final maxPlayers = view?.playerIds.length ?? 2;
      final repo = ref.read(durakRepositoryProvider);

      try {
        final open = await repo.listLobbies();
        DurakLobbyView? match;
        for (final lobby in open) {
          if (lobby.gameMode != gameMode) continue;
          if (lobby.deckSize != deckSize) continue;
          if (lobby.stakeBronze != stakeBronze) continue;
          if (lobby.turnTimeSec != turnTimeSec) continue;
          if (lobby.maxPlayers != maxPlayers) continue;
          if (lobby.playerIds.length >= lobby.maxPlayers) continue;
          match = lobby;
          break;
        }
        if (match != null) {
          final joined = await repo.joinLobby(match.id);
          if (!mounted) return;
          ref.invalidate(durakOpenLobbiesProvider);
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
            context.go('/games/durak/game/${joined.gameId}');
            return;
          }
          if (joined.joined) {
            ref.read(activeGameProvider.notifier).setLocal(
                  ActiveGameItem(type: 'lobby', lobbyId: match.id),
                );
            context.go('/games/durak/lobby/${match.id}?mode=matchmake');
            return;
          }
        }
      } catch (_) {}

      final result = await repo.createLobby(
        mode: 'matchmake',
        maxPlayers: maxPlayers.clamp(2, 4),
        deckSize: deckSize,
        gameMode: gameMode,
        turnTimeSec: turnTimeSec,
        stakeBronze: stakeBronze,
      );
      if (!mounted) return;
      ref.invalidate(durakOpenLobbiesProvider);
      if (result.gameId != null && result.gameId!.isNotEmpty) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'game',
                gameId: result.gameId,
                lobbyId: result.lobbyId,
              ),
            );
        context.go('/games/durak/game/${result.gameId}');
      } else {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(type: 'lobby', lobbyId: result.lobbyId),
            );
        context.go('/games/durak/lobby/${result.lobbyId}?mode=matchmake');
      }
    } on GamesException catch (e) {
      if (!mounted) return;
      if (isFinishCurrentGameError(e)) {
        showAppSnackBar(
          context,
          message: finishCurrentGameMessage,
          kind: AppSnackKind.error,
        );
        return;
      }
      context.go('/games');
    } catch (_) {
      if (mounted) context.go('/games');
    } finally {
      if (mounted) setState(() => _isFindingGame = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(durakGameProvider(widget.gameId));
    final view = gameAsync.valueOrNull;
    if (view != null) _maybeSettleGame(view);
    final showSurrender = view != null && !view.isOver;
    final isMulti = (view?.playerIds.length ?? 0) > 2;
    final topPad = MediaQuery.paddingOf(context).top;
    // Мой ход — часики (без рамки экрана); ход соперника — рамка на его карточке.
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
                    onSurrender:
                        showSurrender && isMulti ? _confirmLeave : null,
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
                // bottom: false — веер чуть заезжает под нижнюю панель.
                SafeArea(
                  bottom: false,
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
                if (view != null &&
                    view.isOver &&
                    !view.isDraw &&
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
    const handSize = _handCardSize;
    const tableSize = _tableCardSize;
    _maybeRunTableFx(view);
    // Сбросить выбор, если карты уже не в руке / нелегальны.
    final trump = _suitFromApi(view.trumpSuit);
    final serverHand = _apiCardsToPlaying(
      view.hands.length > view.myIndex && view.myIndex >= 0
          ? (view.hands[view.myIndex].cards ?? const [])
          : const [],
    );
    final myHand = _orderedHand(serverHand, trump);
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

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final fanZoneH = handSize.height * 1.35 + 28;
    final tuckUnderNav = 36.0 + bottomInset * 0.35;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
      child: Column(
        children: [
          // Панель соперника по центру; карты — под панелью.
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _opponentsHeader(view),
              for (final oi in opponents) _opponentFan(view, oi, tableSize),
            ],
          ),
          // Часики только на моём ходе (как в крестиках); у соперника — рамка.
          if (!view.isOver &&
              view.isMyTurn &&
              view.turnTimeSec > 0 &&
              view.turnDeadline > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: GameTurnCountdown(
                key: ValueKey('my-turn-${view.turnDeadline}'),
                turnDeadline: view.turnDeadline,
                isMyTurn: true,
                onExpired: _onTurnTimeExpired,
                labelBuilder: (s) => context.l10n.gameSecondsLeft(s),
              ),
            ),
          if (view.isOver) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: GameStatusWithReward(
                statusText: _turnHint(view),
                showReward: _showRewardChip(view),
                rewardBronze: _rewardBronze(view),
                rewardKey: _winRewardKey,
                fontSize: MediaQuery.sizeOf(context).width < 420 ? 15 : null,
              ),
            ),
            const SizedBox(height: 10),
            GameRematchSection(
              rematchLobbyId: _rematchLobbyId,
              rematchDeclined: _rematchDeclined,
              iDeclinedRematch: _iDeclinedRematch,
              isRematching: _isRematching,
              isAcceptingRematch: _isAcceptingRematch,
              isFindingGame: _isFindingGame,
              peerIds: _peerIds(view),
              invites: ref.watch(gameInvitesProvider),
              onRematch: _rematch,
              onAccept: _acceptRematch,
              onDecline: _declineRematch,
              onCancelWait: _cancelRematchWait,
              onFindGame: _findGame,
              compact: true,
            ),
          ],
          Expanded(
            child: _buildBoard(view, tableSize, trumpCard),
          ),
          // Между колодой/столом и моим веером.
          _buildActionButton(view),
          SizedBox(
            height: fanZoneH,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Веер ниже и чуть прячется под нижнюю панель.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -tuckUnderNav,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final n = handForFan.length;
                      final spacing = n <= 1
                          ? 0.0
                          : handSize.width *
                              (n > 24
                                  ? 0.14
                                  : n > 18
                                      ? 0.18
                                      : n > 14
                                          ? 0.22
                                          : n > 10
                                              ? 0.28
                                              : n > 7
                                                  ? 0.34
                                                  : 0.46);
                      final fanW = handSize.width + spacing * (n - 1) + 32;
                      final scale = fanW > constraints.maxWidth
                          ? (constraints.maxWidth / fanW).clamp(0.5, 1.0)
                          : 1.0;
                      final fan = CardFan(
                        key: _fanKey,
                        cards: handForFan,
                        cardSize: handSize,
                        legalCards: legal,
                        selectedCards: _selected,
                        hiddenCards: _flyingFromHand,
                        enabled: !view.isOver && !_busy,
                        onActiveChanged: (c) {
                          if (_activeCard == c) return;
                          setState(() => _activeCard = c);
                        },
                        onDragPosition: (p) {
                          if (_dragGlobal == p) return;
                          setState(() => _dragGlobal = p);
                        },
                        onTap: (c) {
                          if (!view.canAct) return;
                          if (_selected.contains(c) && _selected.length == 1) {
                            _clearHandSelection();
                            return;
                          }
                          setState(() {
                            _selected
                              ..clear()
                              ..add(c);
                            _activeCard = c;
                          });
                        },
                        onLongPress: (c) => _toggleSelect(view, c),
                        onReturnToFan: (_) {
                          _sortHandInFan(handForFan, trump);
                        },
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
      // Сообщение на карточке профиля не пропадает после конца партии.
      messageUnread: unread,
      infoTooltip: context.l10n.userInfoTitle,
      messageTooltip: context.l10n.gameWriteMessage,
      compact: MediaQuery.sizeOf(context).width < 420,
      maxWidth: 300,
      align: Alignment.center,
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
      onMessageTap: isBot ? null : () => unawaited(_openChat(oppId, name)),
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
    // Веер «в его сторону»: ось сверху, дуга от игрока.
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: anim, child: child),
        ),
        child: CardFan(
          key: ValueKey('opp-$idx-$count'),
          cards: fake,
          cardSize: Size(cardSize.width * 0.42, cardSize.height * 0.42),
          faceDown: true,
          invertFan: true,
          enabled: false,
          arc: 0.36,
          spacing: cardSize.width * 0.15,
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
    // При вытаскивании карты для отбоя стол подъезжает и чуть растёт.
    final tableApproach = !view.isOver &&
        _isDefendPhase(view) &&
        !_busy &&
        (_activeCard != null || _dragGlobal != null);

    // Колода слева: видна примерно половина — больше места столу.
    final deckPeek = KeyedSubtree(
      key: _deckKey,
      child: Transform.translate(
        offset: Offset(-cardSize.width * 0.48, 0),
        child: DurakDeckPile(
          deckCount: view.deckCount,
          trumpCard: trumpCard,
          trumpSuit: _suitFromApi(view.trumpSuit),
          cardSize: cardSize,
        ),
      ),
    );

    final bitoPeek = KeyedSubtree(
      key: _bitoKey,
      child: Transform.translate(
        offset: Offset(cardSize.width * 0.22, 0),
        child: DurakBitoPile(
          count: _bitoCountFreeze ?? view.bitoCount,
          cardSize: cardSize,
          peek: true,
        ),
      ),
    );

    final tableItems = <Widget>[
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
        // Слева колода наполовину спрятана — меньше резерв; справа бита.
        final leftReserve = cardSize.width * 0.42;
        final rightReserve = cardSize.width * 0.95;
        final tableMaxW =
            (constraints.maxWidth - leftReserve - rightReserve)
                .clamp(120.0, constraints.maxWidth * 0.58);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.08),
                      radius: 1.2,
                      colors: [
                        const Color(0xFFC7D2FE).withValues(alpha: 0.42),
                        AppColors.accentSoft.withValues(alpha: 0.22),
                        AppColors.surfaceUnified.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) => _tablePanAccum = Offset.zero,
                onPointerMove: (e) {
                  if (_busy || _activeCard != null) return;
                  _tablePanAccum += e.delta;
                },
                onPointerUp: (_) {
                  if (_busy || _activeCard != null) {
                    _tablePanAccum = Offset.zero;
                    return;
                  }
                  final dx = _tablePanAccum.dx;
                  final dy = _tablePanAccum.dy;
                  _tablePanAccum = Offset.zero;
                  if (dy > 70 && dy.abs() > dx.abs() * 1.1 && _canTake(view)) {
                    unawaited(_take());
                    return;
                  }
                  if (dx > 70 && dx.abs() > dy.abs() * 1.1 && _canBito(view)) {
                    unawaited(_bito());
                  }
                },
              ),
            ),
            Positioned.fill(
              child: Center(
                child: AnimatedSlide(
                  offset: Offset(0, tableApproach ? 0.08 : 0),
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: AnimatedScale(
                    scale: tableApproach ? 1.12 : 1.0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: KeyedSubtree(
                      key: _tableKey,
                      child: SizedBox(
                        width: tableMaxW,
                        child: _buildTableRows(
                          items: tableItems,
                          cardSize: cardSize,
                          maxWidth: tableMaxW,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Колода чуть выше центра — зазор от карт стола.
            Align(
              alignment: const Alignment(-1.0, -0.12),
              child: deckPeek,
            ),
            // Бита выше, чтобы не касалась карт стола.
            Align(
              alignment: const Alignment(1.0, -0.38),
              child: bitoPeek,
            ),
          ],
        );
      },
    );
  }

  /// До 3 сверху + 3 снизу; если не влезает — 2 / 2 / 2. Зазоры — без касаний.
  Widget _buildTableRows({
    required List<Widget> items,
    required Size cardSize,
    required double maxWidth,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    const gap = 12.0;
    final pairW = cardSize.width + 18;
    final canFit3 = maxWidth >= pairW * 3 + gap * 2;
    final n = items.length;

    List<List<Widget>> rows;
    if (!canFit3 && n >= 5) {
      rows = [
        items.take(2).toList(),
        items.skip(2).take(2).toList(),
        items.skip(4).take(2).toList(),
      ].where((r) => r.isNotEmpty).toList();
    } else {
      rows = [
        items.take(3).toList(),
        if (n > 3) items.skip(3).take(3).toList(),
      ].where((r) => r.isNotEmpty).toList();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) SizedBox(height: gap + 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < rows[r].length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                rows[r][i],
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(DurakGameView view) {
    final take = _canTake(view);
    final bito = _canBito(view);
    if (!take && !bito) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: Center(
        child: _PulsingActionButton(
          label: take ? 'Взять' : 'Бито',
          icon: take ? Icons.south_rounded : Icons.check_rounded,
          onPressed: take ? _take : _bito,
        ),
      ),
    );
  }

  bool _iWon(DurakGameView view) =>
      !view.isDraw &&
      view.loserIndex >= 0 &&
      view.loserIndex != view.myIndex;

  bool _showRewardChip(DurakGameView view) =>
      view.isOver && _iWon(view) && view.stakeBronze > 0;

  int _rewardBronze(DurakGameView view) {
    final n = view.playerIds.length >= 2 ? view.playerIds.length : 2;
    if (n == 2) return view.stakeBronze;
    final winnersN = (n - 1).clamp(1, n);
    return view.stakeBronze ~/ winnersN;
  }

  /// Статус как в крестиках: «Ваш ход» / «Ход {имя}» / итог со сдачей/таймаутом.
  String _turnHint(DurakGameView view) {
    if (view.isOver) {
      if (view.isDraw) return context.l10n.gameDraw;
      final isMulti = view.playerIds.length > 2;
      final iWon = _iWon(view);
      if (isMulti) {
        if (iWon) return context.l10n.gameYouWon;
        final loserId = view.loserIndex >= 0 &&
                view.loserIndex < view.playerIds.length
            ? view.playerIds[view.loserIndex]
            : '';
        // В дураке «дурак» проиграл — победитель не один; для чужого итога
        // показываем имя соперника из 1×1-логики / первого не-себя.
        final winnerName = _opponentName(view);
        if (loserId.isNotEmpty && view.loserIndex == view.myIndex) {
          return context.l10n.gameOpponentWon(winnerName);
        }
        return context.l10n.gameOpponentWon(winnerName);
      }
      final opp = _opponentName(view);
      if (iWon) {
        if (view.isForfeit) return context.l10n.gameYouWonOpponentForfeit;
        if (view.isTimeout) return context.l10n.gameYouWonOpponentTimeout;
        return context.l10n.gameYouWon;
      }
      if (view.isForfeit) return context.l10n.gameYouForfeitOpponentWon(opp);
      if (view.isTimeout) return context.l10n.gameOpponentWonTimeout(opp);
      return context.l10n.gameOpponentWon(opp);
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

/// Плавное мигание кнопки «Взять» / «Бито» между колодой и веером.
class _PulsingActionButton extends StatefulWidget {
  const _PulsingActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Future<void> Function() onPressed;

  @override
  State<_PulsingActionButton> createState() => _PulsingActionButtonState();
}

class _PulsingActionButtonState extends State<_PulsingActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        final scale = 1.0 + 0.04 * t;
        final glow = 0.22 + 0.28 * t;
        return Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentStart.withValues(alpha: glow),
                  blurRadius: 14 + 8 * t,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: FilledButton.icon(
        onPressed: _pressed
            ? null
            : () async {
                setState(() => _pressed = true);
                try {
                  await widget.onPressed();
                } finally {
                  if (mounted) setState(() => _pressed = false);
                }
              },
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentStart,
          disabledBackgroundColor: AppColors.accentStart.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: Icon(widget.icon, size: 20),
        label: Text(
          widget.label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

/// Пара на столе. Без pop-анимации при оптимистичном приземлении — карта уже
/// прилетела плавно, лишняя «доводка» не нужна.
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
    final pairChild = SizedBox(
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
                highlighted: false,
              ),
            ),
        ],
      ),
    );
    // Оптимистичная защита уже долетела — без scale/fade.
    if (optimisticDefense != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: pairChild,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        builder: (context, scale, child) => Opacity(
          opacity: ((scale - 0.92) / 0.08).clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: child),
        ),
        child: pairChild,
      ),
    );
  }
}
