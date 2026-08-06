import 'dart:async';
import 'dart:math' as math;

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
  /// Во время полёта держим подсказку/слот как в момент броска (без скачка layout).
  bool _flightLockTable = false;
  /// Цель отбоя на время полёта (подсветка не мигает).
  int? _flightDefendIdx;
  bool _handlingAuthError = false;
  bool _retryScheduled = false;
  PlayingCard? _activeCard;
  /// Только для выбора цели отбоя в момент drop — без setState на каждый move.
  Offset? _dragGlobal;
  /// Заморозка размера карт веера после хода (spacing всегда на всю ширину).
  Size? _frozenFanCardSize;
  int? _frozenFanHandCount;
  /// Кратко выключить AnimatedPositioned после хода/добора.
  bool _suppressFanLayoutAnim = false;
  final Set<PlayingCard> _selected = {};
  /// Карты, скрытые в веере на время полёта/ожидания сервера.
  final Set<PlayingCard> _flyingFromHand = {};
  /// Уже сели в веер локально (взятие), пока сервер не подтвердил руку.
  final Set<PlayingCard> _incomingFanCards = {};
  /// Добор из колоды ещё не вложен в веер — не показывать из server hand.
  final Set<PlayingCard> _pendingDealCards = {};
  /// Оптимистично «приземлившиеся» атаки (пока ждём ответ сервера).
  final List<PlayingCard> _optimisticAttacks = [];
  /// Атаки, которые ещё летят на стол (плейсхолдер скрыт под fly).
  final Set<PlayingCard> _flyingToTable = {};
  /// Оптимистичная защита: индекс пары → карта.
  final Map<int, PlayingCard> _optimisticDefends = {};
  /// Во время взятия разрешить анимацию перестановки веера.
  bool _fanAnimDuringBusy = false;
  /// Стол скрыт на время полёта в биту / при взятии.
  bool _hidingTable = false;
  /// Не запускать повторный FX биты после локального смахивания.
  bool _suppressRemoteBitoFx = false;
  /// После «Взять» не играть добор из колоды — карты уже вставились в веер.
  bool _suppressNextDealFx = false;
  /// Ключи вееров соперников (полёт карты с их руки).
  final Map<int, GlobalKey> _oppFanKeys = {};
  /// Карты стола, скрытые на время remote-полёта.
  final Set<String> _remoteFlyingCardIds = {};
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
  final GlobalKey<CardFanState> _fanKey = GlobalKey<CardFanState>();
  final GlobalKey _defendTargetKey = GlobalKey();
  final Map<int, GlobalKey> _tableAttackKeys = {};
  final GlobalKey _attackSlotKey = GlobalKey();
  /// Слот посадки подкида — в финальном месте стола (не «рядом», потом сдвиг).
  final GlobalKey _pendingAttackLandKey = GlobalKey();
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

  /// Экран партии виден (не чаты / другой таб) — иначе FX не на root overlay.
  bool get _gameUiActive {
    if (!mounted) return false;
    try {
      final path =
          GoRouter.of(context).routeInformationProvider.value.uri.path;
      return path.contains('/games/durak/game/');
    } catch (_) {
      final route = ModalRoute.of(context);
      return route?.isCurrent == true && TickerMode.of(context);
    }
  }


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
    // Ход уже уходит на сервер — не дёргаем GetGame со старым deadline (гонка).
    if (_busy ||
        _optimisticAttacks.isNotEmpty ||
        _optimisticDefends.isNotEmpty ||
        _flyingToTable.isNotEmpty) {
      return;
    }
    _timeoutRetryTimer?.cancel();
    var attempt = 0;
    void doRefresh() {
      if (!mounted) return;
      if (_busy ||
          _optimisticAttacks.isNotEmpty ||
          _optimisticDefends.isNotEmpty ||
          _flyingToTable.isNotEmpty) {
        return;
      }
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

  static String _cardId(PlayingCard c) => '${c.rank.value}-${c.suit.name}';

  bool _shouldShowTablePair(DurakTablePairApi pair, int i) {
    final atk = pair.attack.toPlayingCard();
    // Пока optimistic/fly владеет атакой — серверную пару не рисуем
    // (иначе ранний WS убирает pending-слот и карта «прыгает»).
    if (_optimisticAttacks.contains(atk) || _flyingToTable.contains(atk)) {
      return false;
    }
    final atkId = _cardId(atk);
    if (_remoteFlyingCardIds.contains(atkId) &&
        pair.defense == null &&
        !_optimisticDefends.containsKey(i)) {
      return false;
    }
    return true;
  }

  DurakTablePairApi _tablePairForRender(DurakTablePairApi pair, int i) {
    // Локальный отбой ещё летит — на столе только атака (лицо ведёт fly).
    if (_flightDefendIdx == i && _flightLockTable) {
      return DurakTablePairApi(attack: pair.attack, defense: null);
    }
    final def = pair.defense;
    if (def == null) return pair;
    final defId = _cardId(def.toPlayingCard());
    if (!_remoteFlyingCardIds.contains(defId)) return pair;
    return DurakTablePairApi(attack: pair.attack, defense: null);
  }

  PlayingCard? _visibleOptimisticDefense(int i) {
    if (_flightDefendIdx == i && _flightLockTable) return null;
    final opt = _optimisticDefends[i];
    if (opt == null) return null;
    if (_remoteFlyingCardIds.contains(_cardId(opt))) return null;
    return opt;
  }

  /// Веер: дуга + шаг на всю [maxWidth] (включая зону слева под крестиком).
  ({Size cardSize, double spacing}) _fitHandFan(int n, double maxWidth) {
    if (n <= 0) return (cardSize: _handCardSize, spacing: 0);
    var size = _handCardSize;
    // Чем больше карт — тем сильнее сжимаем (можно до «полосок»).
    if (n > 30) {
      size = Size(_handCardSize.width * 0.42, _handCardSize.height * 0.42);
    } else if (n > 24) {
      size = Size(_handCardSize.width * 0.50, _handCardSize.height * 0.50);
    } else if (n > 20) {
      size = Size(_handCardSize.width * 0.58, _handCardSize.height * 0.58);
    } else if (n > 16) {
      size = Size(_handCardSize.width * 0.68, _handCardSize.height * 0.68);
    } else if (n > 12) {
      size = Size(_handCardSize.width * 0.78, _handCardSize.height * 0.78);
    } else if (n > 10) {
      size = Size(_handCardSize.width * 0.86, _handCardSize.height * 0.86);
    }

    // fillWidth: width = card + spacing*(n-1), без боковых полей.
    const fanPad = 4.0;
    final usable = (maxWidth - fanPad).clamp(72.0, maxWidth);

    double minSpacing(Size s) {
      if (n <= 1) return 0;
      final w = s.width;
      if (n > 30) return w * 0.035;
      if (n > 24) return w * 0.045;
      if (n > 20) return w * 0.06;
      if (n > 16) return w * 0.08;
      if (n > 12) return w * 0.12;
      if (n > 10) return w * 0.16;
      if (n > 7) return w * 0.26;
      if (n > 5) return w * 0.36;
      return w * 0.48;
    }

    for (var step = 0; step < 24; step++) {
      final need = size.width + minSpacing(size) * (n - 1);
      if (need <= usable || size.width <= 18) break;
      final scale = (usable / need).clamp(0.28, 0.96);
      size = Size(size.width * scale, size.height * scale);
    }

    // Растягиваем шаг до краёв доступной ширины.
    final lo = minSpacing(size);
    final hi = size.width * 0.96;
    final fill = n <= 1 ? 0.0 : (usable - size.width) / (n - 1);
    final spacing = n <= 1 ? 0.0 : fill.clamp(lo, hi > lo ? hi : lo);
    return (cardSize: size, spacing: spacing);
  }

  /// Всегда на всю ширину: мало карт — широко, много — сильнее сжаты.
  ({Size cardSize, double spacing, bool fillWidth}) _handFanVisualLayout(
    int n,
    double maxWidth,
  ) {
    if (n <= 0) {
      return (cardSize: _handCardSize, spacing: 0, fillWidth: true);
    }
    // Одна карта — по центру; 2+ — растянуть от края до края.
    if (n == 1) {
      return (cardSize: _handCardSize, spacing: 0, fillWidth: false);
    }
    final fitted = _fitHandFan(n, maxWidth);
    return (
      cardSize: fitted.cardSize,
      spacing: fitted.spacing,
      fillWidth: true,
    );
  }

  /// Сколько ещё атак/подкидов можно положить (учитывает оптимистичные).
  int _attackRoom(DurakGameView view) {
    final def = view.defenderIndex;
    final defCount = (def >= 0 && def < view.hands.length)
        ? view.hands[def].count
        : 6;
    final lim = defCount + view.table.length;
    final capped = lim < 1 ? 1 : lim;
    const maxAttacks = 6;
    final maxPairs = maxAttacks < capped ? maxAttacks : capped;
    final pending = _pendingAttackPlaceholders(view).length;
    return (maxPairs - view.table.length - pending).clamp(0, 52);
  }

  /// Легальные атаки с учётом уже брошенных (ещё не подтверждённых) карт.
  Set<PlayingCard> _legalAttackNow(DurakGameView view) {
    if (!_isAttackPhase(view) || _attackRoom(view) <= 0) return {};
    final pendingSet = {
      ..._optimisticAttacks,
      ..._flyingFromHand,
      ..._flyingToTable,
    };
    final pendingPlaceholders = _pendingAttackPlaceholders(view);
    // Без локальных подкидов — доверяем серверу (attack_follow / лимиты).
    if (pendingPlaceholders.isEmpty) {
      return {
        for (final c in _apiCardsToPlaying(view.legalAttack))
          if (!pendingSet.contains(c)) c,
      };
    }
    final ranks = <Rank>{
      for (final p in view.table) p.attack.toPlayingCard().rank,
      for (final c in pendingPlaceholders) c.rank,
    };
    final hand = _apiCardsToPlaying(
      view.hands.length > view.myIndex && view.myIndex >= 0
          ? (view.hands[view.myIndex].cards ?? const [])
          : const [],
    );
    return {
      for (final c in hand)
        if (!pendingSet.contains(c) &&
            (ranks.isEmpty || ranks.contains(c.rank)))
          c,
    };
  }

  /// Оптимистичные атаки — слоты посадки до handoff (даже если WS уже подтвердил).
  List<PlayingCard> _pendingAttackPlaceholders(DurakGameView view) {
    if (_optimisticAttacks.isEmpty) return const [];
    return List<PlayingCard>.of(_optimisticAttacks);
  }

  int _compareHandCards(PlayingCard a, PlayingCard b, Suit trump) {
    final at = a.suit == trump ? 1 : 0;
    final bt = b.suit == trump ? 1 : 0;
    if (at != bt) return at.compareTo(bt);
    final s = a.suit.index.compareTo(b.suit.index);
    if (s != 0) return s;
    return a.rank.compareTo(b.rank);
  }

  /// Карты, ушедшие из руки (атака/защита). Не путать с взятием:
  /// при take карты в [_handOrder] + [_flyingFromHand] — слоты-дырки в веере.
  Set<PlayingCard> get _locallyGoneFromHand {
    final inFan = _handOrder?.toSet();
    return {
      ..._optimisticAttacks,
      ..._flyingToTable,
      for (final c in _flyingFromHand)
        if (inFan == null || !inFan.contains(c)) c,
    };
  }

  /// Порядок веера: сохраняем локальную сортировку между синками сервера.
  List<PlayingCard> _orderedHand(List<PlayingCard> serverHand, Suit trump) {
    final gone = _locallyGoneFromHand;
    if (_handOrder == null) {
      return [
        for (final c in serverHand)
          if (!gone.contains(c)) c,
      ];
    }
    final remain = serverHand.toSet()..removeAll(gone);
    final out = <PlayingCard>[];
    for (final c in _handOrder!) {
      if (remain.remove(c)) {
        out.add(c);
      } else if (_flyingFromHand.contains(c) || _incomingFanCards.contains(c)) {
        // Взятие: ещё нет на сервере — слот/лицо держим локально.
        out.add(c);
      }
    }
    if (remain.isNotEmpty) {
      final added = remain
          .where((c) => !_pendingDealCards.contains(c))
          .toList()
        ..sort((a, b) => _compareHandCards(a, b, trump));
      out.addAll(added);
    }
    return out;
  }

  void _sortHandInFan(
    List<PlayingCard> hand,
    Suit trump, {
    bool animate = true,
    bool keepFreeze = false,
  }) {
    final sorted = List<PlayingCard>.from(hand)
      ..sort((a, b) => _compareHandCards(a, b, trump));
    if (!keepFreeze) _unfreezeFanLayout();
    setState(() {
      _handOrder = sorted;
      _suppressFanLayoutAnim = !animate;
      if (keepFreeze && _frozenFanCardSize != null) {
        final lay = _fitHandFan(
          sorted.length.clamp(1, 52),
          MediaQuery.sizeOf(context).width,
        );
        _frozenFanCardSize = lay.cardSize;
        _frozenFanHandCount = sorted.length;
      }
    });
    if (!animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_suppressFanLayoutAnim) {
          setState(() => _suppressFanLayoutAnim = false);
        }
      });
    }
  }

  /// После взятия: добор из колоды вставить в порядок, сохраняя уже лежащие.
  void _mergeHandAfterTake(List<PlayingCard> hand, Suit trump) {
    final sorted = List<PlayingCard>.from(hand)
      ..sort((a, b) => _compareHandCards(a, b, trump));
    final prev = _handOrder?.toSet() ?? {};
    final onlyDeal = sorted.where((c) => !prev.contains(c)).toList();
    // Если состав тот же — не трогаем layout (избегаем «перерисовки» веера).
    if (onlyDeal.isEmpty &&
        _handOrder != null &&
        _handOrder!.length == sorted.length &&
        _handOrder!.toSet().containsAll(sorted)) {
      return;
    }
    setState(() {
      _handOrder = sorted;
      // Плавная доводка только для добора; размер уже от _animateTableToFan.
      _suppressFanLayoutAnim = onlyDeal.isEmpty;
      final lay = _handFanVisualLayout(
        sorted.length.clamp(1, 52),
        MediaQuery.sizeOf(context).width,
      );
      _frozenFanCardSize = lay.cardSize;
      _frozenFanHandCount = sorted.length;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _releaseFanLayoutSnap();
    });
  }

  bool _highlightAttackSlot(DurakGameView view) {
    final focus = _activeCard ??
        (_selected.isNotEmpty ? _selected.first : null);
    if (focus == null || _busy || view.isOver) return false;
    if (!_isAttackPhase(view)) return false;
    // Подкид — без подсветки слота; только первая атака на пустой стол.
    if (view.table.isNotEmpty || _optimisticAttacks.isNotEmpty) return false;
    return _legalAttackNow(view).contains(focus);
  }

  /// Неотбитые атаки на столе (индексы).
  List<int> _undefendedIndexes(DurakGameView view) {
    final out = <int>[];
    for (var i = 0; i < view.table.length; i++) {
      final p = view.table[i];
      if (p.defense != null || _optimisticDefends.containsKey(i)) continue;
      out.add(i);
    }
    return out;
  }

  /// Индексы атак, которые бьёт [card].
  Set<int> _defendTargetIndexes(DurakGameView view, PlayingCard? card) {
    if (card == null || !_isDefendPhase(view)) return const {};
    final trump = _suitFromApi(view.trumpSuit);
    final out = <int>{};
    for (final i in _undefendedIndexes(view)) {
      if (card.beats(view.table[i].attack.toPlayingCard(), trump)) {
        out.add(i);
      }
    }
    return out;
  }

  /// Предпочтительная цель полёта — ближайшая к пальцу неотбитая атака.
  int _defendTargetIndex(
    DurakGameView view,
    PlayingCard? card, {
    Offset? pointer,
  }) {
    final candidates = _defendTargetIndexes(view, card).toList()..sort();
    if (candidates.isEmpty) return -1;
    if (candidates.length == 1) return candidates.first;
    final p = pointer ?? _dragGlobal;
    if (p != null) {
      var best = candidates.first;
      var bestDist = double.infinity;
      for (final i in candidates) {
        final key = _tableAttackKeys[i];
        final rect = key != null ? globalRectOf(key) : null;
        if (rect == null) continue;
        final d = (rect.center - p).distanceSquared;
        if (d < bestDist) {
          bestDist = d;
          best = i;
        }
      }
      return best;
    }
    return candidates.first;
  }

  /// Карты веера для подсветки в защите: бьют хотя бы одну неотбитую атаку.
  /// Если карта бьёт все атаки — тоже в наборе (и отдельно заметна glow).
  Set<PlayingCard> _defendLegalFanCards(
    DurakGameView view,
    List<PlayingCard> hand,
  ) {
    if (!_isDefendPhase(view)) {
      return _apiCardsToPlaying(view.legalDefend).toSet();
    }
    final trump = _suitFromApi(view.trumpSuit);
    final undefended = [
      for (final i in _undefendedIndexes(view))
        view.table[i].attack.toPlayingCard(),
    ];
    if (undefended.isEmpty) return {};
    return {
      for (final c in hand)
        if (undefended.any((t) => c.beats(t, trump))) c,
    };
  }

  /// Карты, которыми можно перевести (переводной режим).
  Set<PlayingCard> _transferLegalFanCards(
    DurakGameView view,
    List<PlayingCard> hand,
  ) {
    if (view.mode != 'perevodnoi') return {};
    if (!_isDefendPhase(view)) return {};
    if (view.table.isEmpty) return {};
    if (view.table.any((p) => p.defense != null)) return {};
    if (_optimisticDefends.isNotEmpty) return {};
    final rank = view.table.first.attack.toPlayingCard().rank;
    if (view.table.length + 1 > 6) return {};
    return {
      for (final c in hand)
        if (c.rank == rank) c,
    };
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
    // Мультивыбор long-press — несколько сразу; иначе строго по одной.
    if (_selected.contains(card) && _selected.length > 1) {
      return _selected.toList();
    }
    return [card];
  }

  void _toggleSelect(DurakGameView view, PlayingCard card) {
    final hand = _apiCardsToPlaying(
      view.hands.length > view.myIndex && view.myIndex >= 0
          ? (view.hands[view.myIndex].cards ?? const [])
          : const [],
    );
    final legal = <PlayingCard>{
      ..._legalAttackNow(view),
      ..._defendLegalFanCards(view, hand),
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
    if (_selected.isEmpty &&
        _activeCard == null &&
        _dragGlobal == null &&
        !_flightLockTable) {
      return;
    }
    setState(() {
      _selected.clear();
      _activeCard = null;
      _dragGlobal = null;
    });
  }

  /// Карта вернулась в веер — убрать слот/glow подсказок.
  void _onCardReturnedToFan(PlayingCard _) {
    _clearHandSelection();
  }

  void _freezeFanLayout(Size cardSize, double spacing, int handCount) {
    _frozenFanCardSize = cardSize;
    _frozenFanHandCount = handCount;
  }

  void _unfreezeFanLayout() {
    _frozenFanCardSize = null;
    _frozenFanHandCount = null;
  }

  /// Снять заморозку веера без анимации перестановки (добор / взятие).
  void _releaseFanLayoutSnap() {
    if (!mounted) return;
    setState(() {
      _unfreezeFanLayout();
      _suppressFanLayoutAnim = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_suppressFanLayoutAnim) {
        setState(() => _suppressFanLayoutAnim = false);
      }
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

    final defendTargets = _defendTargetIndexes(view, cards.first);
    final doDefend = isDefend && defendTargets.isNotEmpty;
    final transferLegal = isDefend
        ? _transferLegalFanCards(
            view,
            _apiCardsToPlaying(
              view.hands.length > view.myIndex && view.myIndex >= 0
                  ? (view.hands[view.myIndex].cards ?? const [])
                  : const [],
            ),
          )
        : const <PlayingCard>{};
    final doTransfer = isDefend &&
        !doDefend &&
        transferLegal.contains(cards.first);
    final doAttack = !doDefend &&
        !doTransfer &&
        isAttack &&
        _legalAttackNow(view).contains(cards.first);
    if (!doDefend && !doAttack && !doTransfer) return false;

    // Атака/подкид — по одной, без блокировки веера: сразу можно кинуть ещё.
    if (doAttack) {
      if (_attackRoom(view) < cards.length) return false;
      return _playAttackChain(
        view,
        cards,
        fromOverride: fromOverride,
        pointer: pointer,
      );
    }

    final screen = MediaQuery.sizeOf(context);
    final defendIdx = doDefend
        ? _defendTargetIndex(view, cards.first, pointer: pointer)
        : -1;

    const defendOffset = Offset(10, 14);

    final fallback = cardFanApproxOrigin(
          _fanKey.currentContext ?? context,
          _handCardSize,
        ) ??
        Rect.fromCenter(
          center: screen.center(Offset.zero),
          width: _handCardSize.width,
          height: _handCardSize.height,
        );
    final fromRect = fromOverride ??
        Rect.fromCenter(
          center: fallback.center,
          width: _handCardSize.width,
          height: _handCardSize.height,
        );
    final beginScale = fromOverride != null
        ? (fromOverride.width / _handCardSize.width).clamp(0.9, 1.2)
        : (pointer != null
            ? dragScaleTowardCenter(pointer, screen)
            : 1.0);

    // Полный размер веера — не cards.length (часто 1 при drag).
    final serverHandLen = view.hands.length > view.myIndex && view.myIndex >= 0
        ? (view.hands[view.myIndex].cards?.length ??
            view.hands[view.myIndex].count)
        : 0;
    final nBefore = ((_handOrder?.length ?? 0) > 0
            ? _handOrder!.length
            : serverHandLen)
        .clamp(1, 52);

    // Отбой: карта остаётся слотом-дыркой в веере (hiddenCards), пока летит.
    // Перевод: убираем из порядка — на столе как атака.
    setState(() {
      _activeCard = null;
      _selected.clear();
      _dragGlobal = null;
      _flyingFromHand.addAll(cards);
      _busy = true;
      _flightLockTable = doDefend;
      _flightDefendIdx = doDefend && defendIdx >= 0 ? defendIdx : null;
      if (doTransfer) {
        _optimisticAttacks.addAll(cards);
        _flyingToTable.addAll(cards);
        _removeFromHandOrder(cards, view);
      } else if (_handOrder == null || _handOrder!.isEmpty) {
        // Зафиксировать полный порядок до полёта — иначе веер схлопнется.
        _handOrder = _apiCardsToPlaying(
          view.hands.length > view.myIndex && view.myIndex >= 0
              ? (view.hands[view.myIndex].cards ?? const [])
              : const [],
        );
      }
      if (_frozenFanCardSize == null) {
        final lay = _handFanVisualLayout(
          nBefore,
          MediaQuery.sizeOf(context).width,
        );
        _freezeFanLayout(lay.cardSize, lay.spacing, nBefore);
      }
      _suppressFanLayoutAnim = true;
    });

    // Цель после layout — летим в финальную точку атаки/слота.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return true;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return true;

    // Отбой: ключ уже на позиции защиты; fallback — атака + смещение.
    final Rect to;
    final Size landSize;
    if (doDefend) {
      final defendRect = globalRectOf(_defendTargetKey);
      if (defendRect != null) {
        to = defendRect;
      } else {
        final atkKey = defendIdx >= 0
            ? _tableAttackKeys.putIfAbsent(defendIdx, GlobalKey.new)
            : null;
        final atk = (atkKey != null ? globalRectOf(atkKey) : null) ??
            globalRectOf(_tableKey) ??
            Rect.fromCenter(
              center: Offset(screen.width / 2, screen.height * 0.42),
              width: _tableCardSize.width,
              height: _tableCardSize.height,
            );
        to = Rect.fromLTWH(
          atk.left + defendOffset.dx,
          atk.top + defendOffset.dy,
          _tableCardSize.width,
          _tableCardSize.height,
        );
      }
      landSize = Size(to.width, to.height);
    } else {
      to = globalRectOf(_pendingAttackLandKey) ??
          globalRectOf(_attackSlotKey) ??
          _estimateAttackLandRect(view, screen);
      landSize = Size(_tableCardSize.width, _tableCardSize.height);
    }

    final shrink = landSize.width / _handCardSize.width;
    final froms = [
      for (var i = 0; i < cards.length; i++)
        Rect.fromCenter(
          center: fromRect.center.translate(i * 10.0, i * -6.0),
          width: fromRect.width,
          height: fromRect.height,
        ),
    ];
    final tos = [
      for (var i = 0; i < cards.length; i++)
        Rect.fromCenter(
          center: to.center.translate(i * 14.0, 0),
          width: landSize.width,
          height: landSize.height,
        ),
    ];

    // Как атака: стартуем fly и сразу return true — иначе оверлей веера
    // дублирует карту на всём полёте (onDrop ждёт завершения).
    final firstFly = playCardFlyAnimation(
      context: context,
      card: cards.first,
      cardSize: _handCardSize,
      from: froms.first,
      to: tos.first,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
      beginScale: beginScale,
      endScale: shrink,
      beginAngle: 0,
      endAngle: 0,
      arcLift: 0,
      keepAtEnd: true,
    );

    final repo = ref.read(durakRepositoryProvider);
    final moveFuture = doDefend
        ? repo.move(
            widget.gameId,
            type: 'defend',
            card: cards.first,
            pairIndex: defendIdx >= 0 ? defendIdx : null,
          )
        : repo.move(
            widget.gameId,
            type: 'transfer',
            card: cards.first,
          );

    unawaited(() async {
      final tickets = <CardFlyTicket>[await firstFly];
      for (var i = 1; i < cards.length; i++) {
        await Future<void>.delayed(Duration(milliseconds: 40 * i));
        if (!mounted) break;
        tickets.add(
          await playCardFlyAnimation(
            context: context,
            card: cards[i],
            cardSize: _handCardSize,
            from: froms[i],
            to: tos[i],
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeInOutCubic,
            beginScale: beginScale,
            endScale: shrink,
            beginAngle: 0,
            endAngle: 0,
            arcLift: 0,
            keepAtEnd: true,
          ),
        );
      }
      if (!mounted) {
        for (final t in tickets) {
          t.dismiss();
        }
        return;
      }

      if (doDefend && defendIdx >= 0) {
        setState(() {
          _optimisticDefends[defendIdx] = cards.first;
        });
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) await WidgetsBinding.instance.endOfFrame;
        for (final t in tickets) {
          t.dismiss();
        }
        if (mounted) {
          setState(() {
            _flightLockTable = false;
            _flightDefendIdx = null;
          });
        }
      } else {
        // Перевод: стол под overlay, затем снять fly.
        setState(() {
          _flyingToTable.removeAll(cards);
        });
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) await WidgetsBinding.instance.endOfFrame;
        for (final t in tickets) {
          t.dismiss();
        }
      }

      try {
        await moveFuture;
        ref.invalidate(durakGameProvider(widget.gameId));
        try {
          await ref.read(durakGameProvider(widget.gameId).future);
        } catch (_) {}
        if (!mounted) return;
        final v = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
        if (v != null) {
          _prevTable = List.of(v.table);
          _prevDeckCount = v.deckCount;
          _prevBitoCount = v.bitoCount;
          _prevHandLen = v.hands.length > v.myIndex && v.myIndex >= 0
              ? (v.hands[v.myIndex].cards?.length ?? v.hands[v.myIndex].count)
              : _prevHandLen;
        }
        setState(() {
          _flyingFromHand.removeAll(cards);
          if (doDefend) {
            _removeFromHandOrder(cards, v ?? view);
          }
          for (final c in cards) {
            _optimisticAttacks.remove(c);
            _flyingToTable.remove(c);
          }
          _optimisticDefends.clear();
          _flightLockTable = false;
          _flightDefendIdx = null;
          _busy = false;
          _dragGlobal = null;
          _suppressFanLayoutAnim = false;
        });
        _releaseFanLayoutSnap();
      } on GamesException catch (e) {
        if (!mounted) return;
        showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
        setState(() {
          _flyingFromHand.removeAll(cards);
          for (final c in cards) {
            _optimisticAttacks.remove(c);
            _flyingToTable.remove(c);
          }
          _optimisticDefends.clear();
          _flightLockTable = false;
          _flightDefendIdx = null;
          if (doTransfer && _handOrder != null) {
            _handOrder = [..._handOrder!, ...cards];
          }
          _busy = false;
          _dragGlobal = null;
          _suppressFanLayoutAnim = false;
        });
        _releaseFanLayoutSnap();
      }
    }());

    return true;
  }

  /// Убрать карты из локального порядка веера (создаёт порядок, если его ещё нет).
  void _removeFromHandOrder(List<PlayingCard> cards, DurakGameView view) {
    final base = _handOrder ??
        _apiCardsToPlaying(
          view.hands.length > view.myIndex && view.myIndex >= 0
              ? (view.hands[view.myIndex].cards ?? const [])
              : const [],
        );
    _handOrder = base.where((c) => !cards.contains(c)).toList();
  }

  /// Подкид/атака без `_busy`: одна карта, веер сразу свободен, посадка без мигания.
  Future<bool> _playAttackChain(
    DurakGameView view,
    List<PlayingCard> cards, {
    Rect? fromOverride,
    Offset? pointer,
  }) async {
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
    final fromRect = fromOverride ??
        Rect.fromCenter(
          center: fallback.center,
          width: _handCardSize.width,
          height: _handCardSize.height,
        );
    final beginScale = fromOverride != null
        ? (fromOverride.width / _handCardSize.width).clamp(0.9, 1.2)
        : (pointer != null
            ? dragScaleTowardCenter(pointer, screen)
            : 1.0);

    final nBefore = ((_handOrder?.length ?? 0) > 0
            ? _handOrder!.length
            : (view.hands.length > view.myIndex && view.myIndex >= 0
                ? (view.hands[view.myIndex].cards?.length ?? cards.length)
                : cards.length))
        .clamp(1, 52);

    // Убрать из веера сразу; pending-слот на столе (opacity 0 под fly).
    // Fan-overlay ещё на карте, пока меряем финальный слот.
    setState(() {
      _activeCard = null;
      _selected.clear();
      _dragGlobal = null;
      _removeFromHandOrder(cards, view);
      _flyingFromHand.addAll(cards);
      _optimisticAttacks.addAll(cards);
      _flyingToTable.addAll(cards);
      if (_frozenFanCardSize == null) {
        final lay = _handFanVisualLayout(
          nBefore,
          MediaQuery.sizeOf(context).width,
        );
        _freezeFanLayout(lay.cardSize, lay.spacing, nBefore);
      }
      _suppressFanLayoutAnim = false;
    });

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return true;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return true;

    // Финальная точка: ключ pending (всегда смонтирован) или геометрия ряда.
    final to = globalRectOf(_pendingAttackLandKey) ??
        _estimateAttackLandRect(view, screen);

    final landSize = Size(_tableCardSize.width, _tableCardSize.height);
    final shrink = landSize.width / _handCardSize.width;
    final froms = [
      for (var i = 0; i < cards.length; i++)
        Rect.fromCenter(
          center: fromRect.center.translate(i * 10.0, i * -6.0),
          width: fromRect.width,
          height: fromRect.height,
        ),
    ];
    final tos = [
      for (var i = 0; i < cards.length; i++)
        Rect.fromCenter(
          center: to.center.translate(i * 14.0, 0),
          width: landSize.width,
          height: landSize.height,
        ),
    ];

    final firstFly = playCardFlyAnimation(
      context: context,
      card: cards.first,
      cardSize: _handCardSize,
      from: froms.first,
      to: tos.first,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      beginScale: beginScale,
      endScale: shrink,
      beginAngle: 0,
      endAngle: 0,
      arcLift: 0,
      keepAtEnd: true,
    );

    // Сервер параллельно с полётом — handoff не ждёт сеть (иначе мигание).
    final commitFuture = _commitAttackMove(cards, clearFlying: false);

    unawaited(() async {
      final tickets = <CardFlyTicket>[await firstFly];
      for (var i = 1; i < cards.length; i++) {
        await Future<void>.delayed(Duration(milliseconds: 35 * i));
        if (!mounted) break;
        tickets.add(
          await playCardFlyAnimation(
            context: context,
            card: cards[i],
            cardSize: _handCardSize,
            from: froms[i],
            to: tos[i],
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            beginScale: beginScale,
            endScale: shrink,
            beginAngle: 0,
            endAngle: 0,
            arcLift: 0,
            keepAtEnd: true,
          ),
        );
      }
      if (!mounted) {
        for (final t in tickets) {
          t.dismiss();
        }
        return;
      }
      // Стол под overlay → кадр → снять fly (без ожидания ответа сервера).
      setState(() {
        _flyingToTable.removeAll(cards);
      });
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) await WidgetsBinding.instance.endOfFrame;
      for (final t in tickets) {
        t.dismiss();
      }
      await commitFuture;
      if (!mounted) return;
      setState(() {
        for (final c in cards) {
          _optimisticAttacks.remove(c);
        }
        _flyingFromHand.removeAll(cards);
        _flyingToTable.removeAll(cards);
      });
    }());
    return true;
  }

  /// Геометрия посадки атаки: центр именно карты атаки, не слота пары
  /// (слот шире/выше на +10/+14 под отбой — туда сажать нельзя).
  Rect _estimateAttackLandRect(DurakGameView view, Size screen) {
    final table = globalRectOf(_tableKey);
    final center =
        table?.center ?? Offset(screen.width / 2, screen.height * 0.42);
    // Серверные пары (без тех, что рисует pending) + optimistic.
    final serverVisible = view.table
        .where((p) {
          final a = p.attack.toPlayingCard();
          return !_optimisticAttacks.contains(a) && !_flyingToTable.contains(a);
        })
        .length;
    final n = serverVisible + _optimisticAttacks.length;
    final idx = math.max(n - 1, 0);
    // Как в _AnimatedTablePair: padding 4+4, SizedBox = card + (10, 14).
    final pairW = _tableCardSize.width + 18;
    final pairH = _tableCardSize.height + 14;
    const gap = 10.0;
    final col = idx % 2;
    final row = idx ~/ 2;
    final rowLen = (row * 2 + 2 <= n) ? 2 : (n - row * 2).clamp(1, 2);
    final rowWidth = rowLen * pairW + (rowLen - 1) * gap;
    final rowLeft = center.dx - rowWidth / 2;
    final pairLeft = rowLeft + col * (pairW + gap);
    final rows = (n + 1) ~/ 2;
    final colH = rows * pairH + (rows - 1) * 10;
    final pairTop = center.dy - colH / 2 + row * (pairH + 10);
    // Лицо атаки — левый верх стека (после горизонтального padding).
    return Rect.fromLTWH(
      pairLeft + 4,
      pairTop,
      _tableCardSize.width,
      _tableCardSize.height,
    );
  }

  /// [clearFlying] — сбрасывать визуал сразу (старый путь) или оставить
  /// caller'у handoff fly→стол без мигания.
  Future<void> _commitAttackMove(
    List<PlayingCard> cards, {
    bool clearFlying = true,
  }) async {
    final repo = ref.read(durakRepositoryProvider);
    try {
      await repo.move(widget.gameId, type: 'attack', cards: cards);
      ref.invalidate(durakGameProvider(widget.gameId));
      try {
        await ref.read(durakGameProvider(widget.gameId).future);
      } catch (_) {}
      if (!mounted) return;
      final v = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
      if (v != null) {
        _prevTable = List.of(v.table);
        _prevDeckCount = v.deckCount;
        _prevBitoCount = v.bitoCount;
      }
      if (!clearFlying) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      setState(() {
        for (final c in cards) {
          _optimisticAttacks.remove(c);
        }
        _flyingToTable.removeAll(cards);
        _flyingFromHand.removeAll(cards);
      });
    } on GamesException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
      setState(() {
        for (final c in cards) {
          _optimisticAttacks.remove(c);
        }
        _flyingToTable.removeAll(cards);
        _flyingFromHand.removeAll(cards);
        if (_handOrder != null) {
          _handOrder = [..._handOrder!, ...cards];
        }
      });
      _releaseFanLayoutSnap();
    }
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
    final taken = _flattenTableCards(snapshot);
    // После взятия сервер ещё добирает из колоды — без отдельной анимации колоды.
    _suppressNextDealFx = true;
    setState(() {
      _hidingTable = true;
      _busy = true;
      _fanAnimDuringBusy = true;
      // До ответа сервера: слоты под карты стола, чтобы после sync не вспыхнули в веере.
      if (taken.isNotEmpty) {
        final base = _handOrder ??
            _apiCardsToPlaying(
              view.hands.length > view.myIndex && view.myIndex >= 0
                  ? (view.hands[view.myIndex].cards ?? const [])
                  : const [],
            );
        _handOrder = [...base, ...taken];
        _flyingFromHand.addAll(taken);
        _incomingFanCards.addAll(taken);
      }
    });
    // Сначала ход на сервер — анимация не должна «съесть» последнюю секунду.
    try {
      await ref.read(durakRepositoryProvider).move(widget.gameId, type: 'take');
      ref.invalidate(durakGameProvider(widget.gameId));
      try {
        await ref.read(durakGameProvider(widget.gameId).future);
      } catch (_) {}
      if (!mounted) return;
      if (snapshot.isNotEmpty && _gameUiActive) {
        await _animateTableToFan(snapshot, fromOverrides: froms);
      }
      if (!mounted) return;
      // Карты стола уже в веере; добор из колоды — по одной с переворотом.
      final v = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
      if (v != null) {
        final trump = _suitFromApi(v.trumpSuit);
        final hand = _apiCardsToPlaying(
          v.hands.length > v.myIndex && v.myIndex >= 0
              ? (v.hands[v.myIndex].cards ?? const [])
              : const [],
        );
        _prevDeckCount = v.deckCount;
        _prevBitoCount = v.bitoCount;
        _prevHandLen = hand.length;
        _prevTable = List.of(v.table);
        final already = _handOrder?.toSet() ?? {};
        final dealt = [
          for (final c in hand)
            if (!already.contains(c)) c,
        ];
        if (dealt.isNotEmpty && _gameUiActive) {
          _pendingDealCards.addAll(dealt);
          await _animateDealCardsToFan(dealt);
        } else {
          _mergeHandAfterTake(hand, trump);
        }
      }
    } on GamesException catch (e) {
      _suppressNextDealFx = false;
      if (mounted) {
        showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _hidingTable = false;
          _busy = false;
          _fanAnimDuringBusy = false;
          _flyingFromHand.removeAll(taken);
          _incomingFanCards.removeAll(taken);
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
    final flown = _flattenTableCards(snapshot).length;
    List<CardFlyTicket> tickets = const [];
    if (snapshot.isNotEmpty) {
      setState(() {
        _hidingTable = true;
        _busy = true;
        _suppressRemoteBitoFx = true;
        _bitoCountFreeze = freezeCount;
      });
      if (_gameUiActive) {
        tickets = await _animateTableToBito(
          snapshot,
          fromOverrides: froms,
        );
      }
      // Пока overlay на бите — сразу показать новую кучу, затем снять fly.
      if (mounted) {
        setState(() {
          _bitoCountFreeze = freezeCount + flown;
        });
        await WidgetsBinding.instance.endOfFrame;
      }
      for (final t in tickets) {
        t.dismiss();
      }
      tickets = const [];
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
      for (final t in tickets) {
        t.dismiss();
      }
      if (mounted) {
        setState(() {
          _hidingTable = false;
          _busy = false;
          _bitoCountFreeze = null;
        });
        _releaseFanLayoutSnap();
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
    if (table.isEmpty) return const [];
    final tableRect = globalRectOf(_tableKey);
    final screen = MediaQuery.sizeOf(context);
    final center = tableRect?.center ??
        Offset(screen.width / 2, screen.height * 0.42);
    final pairW = _tableCardSize.width + 18;
    final out = <Rect>[];
    for (var i = 0; i < table.length; i++) {
      final p = table[i];
      final keyRect = globalRectOf(
        _tableAttackKeys.putIfAbsent(i, GlobalKey.new),
      );
      final atk = keyRect ??
          Rect.fromCenter(
            center: Offset(
              center.dx + (i % 3 - 1) * pairW * 0.55,
              center.dy + (i ~/ 3 - 0.3) * (_tableCardSize.height * 0.55),
            ),
            width: _tableCardSize.width,
            height: _tableCardSize.height,
          );
      out.add(atk);
      if (p.defense != null) {
        out.add(Rect.fromLTWH(
          atk.left + 10,
          atk.top + 14,
          atk.width,
          atk.height,
        ));
      }
    }
    return out;
  }

  Future<void> _animateTableToFan(
    List<DurakTablePairApi> table, {
    List<Rect>? fromOverrides,
  }) async {
    if (table.isEmpty || !mounted || !_gameUiActive) return;
    final cards = _flattenTableCards(table);
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    final trump = view != null
        ? _suitFromApi(view.trumpSuit)
        : Suit.spades;
    final currentHand = view != null
        ? _apiCardsToPlaying(
            view.hands.length > view.myIndex && view.myIndex >= 0
                ? (view.hands[view.myIndex].cards ?? const [])
                : const [],
          )
        : <PlayingCard>[];
    final handSet = currentHand.toSet();
    final merged = currentHand.isNotEmpty && cards.every(handSet.contains)
        ? (List<PlayingCard>.from(currentHand)
          ..sort((a, b) => _compareHandCards(a, b, trump)))
        : (<PlayingCard>[...currentHand, ...cards]
          ..sort((a, b) => _compareHandCards(a, b, trump)));
    final nAll = merged.length;
    final maxFanW = MediaQuery.sizeOf(context).width;
    final fanLayout = _handFanVisualLayout(nAll, maxFanW);
    final slotSize = fanLayout.cardSize;
    // Веер сразу в финальном размере; летящие — дырки, посадка как fold в веер.
    if (mounted) {
      setState(() {
        _handOrder = merged;
        _flyingFromHand.addAll(cards);
        _frozenFanCardSize = slotSize;
        _frozenFanHandCount = nAll;
        _suppressFanLayoutAnim = false;
        _fanAnimDuringBusy = true;
      });
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted) return;

    final fan = _fanKey.currentState;
    final beginScale = _tableCardSize.width / slotSize.width;
    for (var i = 0; i < cards.length; i++) {
      if (!mounted) return;
      final card = cards[i];
      final from = fromOverrides != null && i < fromOverrides.length
          ? fromOverrides[i]
          : Rect.fromCenter(
              center: MediaQuery.sizeOf(context).center(Offset.zero).translate(
                    (i - cards.length / 2) * 36,
                    -10,
                  ),
              width: _tableCardSize.width,
              height: _tableCardSize.height,
            );
      final idx = merged.indexOf(card);
      final center = (nAll - 1) / 2.0;
      final angle = nAll <= 1 || idx < 0
          ? 0.0
          : (idx - center) * (0.4 / math.max(nAll - 1, 1));
      if (fan != null) {
        await fan.foldCardIn(
          card: card,
          from: from,
          beginScale: beginScale,
          beginAngle: (i.isEven ? 1 : -1) * 0.1,
          endAngle: angle,
          onHandoff: () {
            if (!mounted) return;
            setState(() {
              _flyingFromHand.remove(card);
              // Держим в веере до синка сервера — иначе карта «пропадает».
              _incomingFanCards.add(card);
            });
          },
        );
      } else if (mounted) {
        setState(() {
          _flyingFromHand.remove(card);
          _incomingFanCards.add(card);
        });
      }
      if (!mounted) return;
    }
    if (mounted) {
      setState(() => _handOrder = merged);
    }
  }

  /// Добор из колоды: по одной, переворот, fold в веер.
  Future<void> _animateDealCardsToFan(List<PlayingCard> cards) async {
    if (cards.isEmpty || !mounted || !_gameUiActive) return;
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    final trump = view != null
        ? _suitFromApi(view.trumpSuit)
        : Suit.spades;
    final from = globalRectOf(_deckKey) ??
        Rect.fromCenter(
          center: MediaQuery.sizeOf(context).center(Offset.zero),
          width: _tableCardSize.width,
          height: _tableCardSize.height,
        );

    var order = List<PlayingCard>.from(
      _handOrder ??
          (view != null
              ? _apiCardsToPlaying(
                  view.hands.length > view.myIndex && view.myIndex >= 0
                      ? (view.hands[view.myIndex].cards ?? const [])
                      : const [],
                ).where((c) => !cards.contains(c))
              : const <PlayingCard>[]),
    );
    // Убрать ещё не добранные из порядка — добавим по одной.
    order = [for (final c in order) if (!cards.contains(c)) c];

    final manageBusy = !_busy;
    setState(() {
      _fanAnimDuringBusy = true;
      _suppressFanLayoutAnim = false;
      if (manageBusy) _busy = true;
    });

    for (var i = 0; i < cards.length; i++) {
      if (!mounted) return;
      final card = cards[i];
      order = [...order, card]
        ..sort((a, b) => _compareHandCards(a, b, trump));
      final lay = _handFanVisualLayout(
        order.length.clamp(1, 52),
        MediaQuery.sizeOf(context).width,
      );
      setState(() {
        _handOrder = order;
        _pendingDealCards.remove(card);
        _flyingFromHand.add(card);
        _frozenFanCardSize = lay.cardSize;
        _frozenFanHandCount = order.length;
      });
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      final fan = _fanKey.currentState;
      final idx = order.indexOf(card);
      final nAll = order.length;
      final center = (nAll - 1) / 2.0;
      final angle = nAll <= 1 || idx < 0
          ? 0.0
          : (idx - center) * (0.4 / math.max(nAll - 1, 1));
      final deckFrom = Rect.fromCenter(
        center: from.center.translate(i * 1.5, i * 1.5),
        width: _tableCardSize.width,
        height: _tableCardSize.height,
      );
      if (fan != null) {
        await fan.foldCardIn(
          card: card,
          from: deckFrom,
          beginScale: _tableCardSize.width / lay.cardSize.width,
          flipToFace: true,
          beginAngle: 0.2,
          endAngle: angle,
          onHandoff: () {
            if (!mounted) return;
            setState(() => _flyingFromHand.remove(card));
          },
        );
      } else if (mounted) {
        setState(() => _flyingFromHand.remove(card));
      }
      if (!mounted) return;
    }

    if (mounted) {
      setState(() {
        if (manageBusy) _busy = false;
        _fanAnimDuringBusy = false;
        _pendingDealCards.removeAll(cards);
      });
      _releaseFanLayoutSnap();
    }
  }

  Future<void> _animateDealToFan(int n) async {
    if (n <= 0 || !mounted || !_gameUiActive) return;
    // Fallback без известных карт — рубашки в центр веера.
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
          center: to.center.translate(
            (i - n / 2) * (_handCardSize.width * 0.26),
            -i * 2.0,
          ),
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

  /// Полёт в биту; tickets остаются на вызывающем — снять после обновления кучи.
  Future<List<CardFlyTicket>> _animateTableToBito(
    List<DurakTablePairApi> table, {
    List<Rect>? fromOverrides,
  }) async {
    if (table.isEmpty || !mounted || !_gameUiActive) return const [];
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
    final baseBito = _bitoCountFreeze ?? _prevBitoCount;
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
      tos.add(rectJitter(bitoRect, _tableCardSize, baseBito + 1, i));
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
    return tickets;
  }

  void _maybeRunTableFx(DurakGameView view) {
    if (_fxScheduled) return;
    if (!_gameUiActive) {
      // Вне экрана игры — только синхронизируем базу, без overlay-анимаций.
      final handLen = view.hands.length > view.myIndex && view.myIndex >= 0
          ? (view.hands[view.myIndex].cards?.length ??
              view.hands[view.myIndex].count)
          : 0;
      _prevDeckCount = view.deckCount;
      _prevBitoCount = view.bitoCount;
      _prevHandLen = handLen;
      _prevTable = List.of(view.table);
      return;
    }
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
      if (_suppressNextDealFx || _busy) {
        // Взятие: добор без полёта — порядок правит _take / _mergeHandAfterTake.
        _suppressNextDealFx = false;
      } else {
        _fxScheduled = true;
        final hand = _apiCardsToPlaying(
          view.hands.length > view.myIndex && view.myIndex >= 0
              ? (view.hands[view.myIndex].cards ?? const [])
              : const [],
        );
        final prevSet = _handOrder?.toSet() ?? {};
        final incoming = [
          for (final c in hand)
            if (!prevSet.contains(c)) c,
        ];
        if (incoming.isNotEmpty) {
          _pendingDealCards.addAll(incoming);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) {
            _pendingDealCards.clear();
            _fxScheduled = false;
            return;
          }
          if (incoming.isNotEmpty) {
            await _animateDealCardsToFan(incoming);
          } else {
            await _animateDealToFan(dealt.clamp(1, 6));
          }
          if (mounted) {
            final trump = _suitFromApi(view.trumpSuit);
            _pendingDealCards.clear();
            // Порядок уже выставлен в _animateDealCardsToFan — без snap-перерисовки.
            final ordered = _handOrder;
            if (ordered == null ||
                ordered.length != hand.length ||
                !ordered.toSet().containsAll(hand)) {
              _sortHandInFan(hand, trump, animate: false);
            }
            _fxScheduled = false;
          }
        });
      }
    } else if (dealt > 0 && deckDropped == 0) {
      if (_suppressNextDealFx || _busy) {
        _suppressNextDealFx = false;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final trump = _suitFromApi(view.trumpSuit);
          final hand = _apiCardsToPlaying(
            view.hands.length > view.myIndex && view.myIndex >= 0
                ? (view.hands[view.myIndex].cards ?? const [])
                : const [],
          );
          _sortHandInFan(hand, trump);
        });
      }
    } else if (bitoGrew &&
        !_busy &&
        !_hidingTable &&
        !_suppressRemoteBitoFx) {
      // Бито от соперника — летят в отбой, куча обновляется без мигания.
      _fxScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final froms = _tableCardGlobalRects(tableSnapshot);
        final flown = _flattenTableCards(tableSnapshot).length;
        setState(() {
          _hidingTable = true;
          _bitoCountFreeze = prevBito;
        });
        final tickets = await _animateTableToBito(
          tableSnapshot,
          fromOverrides: froms,
        );
        if (mounted) {
          setState(() {
            _bitoCountFreeze = prevBito + flown;
          });
          await WidgetsBinding.instance.endOfFrame;
        }
        for (final t in tickets) {
          t.dismiss();
        }
        if (mounted) {
          setState(() {
            _hidingTable = false;
            _bitoCountFreeze = null;
            _fxScheduled = false;
          });
        }
      });
    } else if (!_busy && !_hidingTable && !_fxScheduled) {
      // Ход соперника: карта летит из его веера на стол / в отбой.
      _scheduleRemoteTableFx(tableSnapshot, view);
    }
  }

  void _scheduleRemoteTableFx(
    List<DurakTablePairApi> prev,
    DurakGameView view,
  ) {
    final next = view.table;
    final flights = <_RemoteTableFlight>[];

    // Новые атаки.
    for (var i = 0; i < next.length; i++) {
      final p = next[i];
      final attack = p.attack.toPlayingCard();
      final id = _cardId(attack);
      final existed = prev.any(
        (o) =>
            o.attack.rank == p.attack.rank &&
            o.attack.suit == p.attack.suit,
      );
      if (!existed &&
          !_optimisticAttacks.contains(attack) &&
          !_remoteFlyingCardIds.contains(id)) {
        flights.add(_RemoteTableFlight(
          card: attack,
          pairIndex: i,
          isDefense: false,
          fromPlayer: view.attackerIndex,
        ));
      }
    }

    // Новые защиты.
    for (var i = 0; i < next.length; i++) {
      final p = next[i];
      if (p.defense == null) continue;
      final defense = p.defense!.toPlayingCard();
      final id = _cardId(defense);
      DurakTablePairApi? old;
      for (final o in prev) {
        if (o.attack.rank == p.attack.rank && o.attack.suit == p.attack.suit) {
          old = o;
          break;
        }
      }
      final wasUndefended = old == null || old.defense == null;
      if (wasUndefended &&
          _optimisticDefends[i] != defense &&
          !_remoteFlyingCardIds.contains(id)) {
        // Старая пара без защиты или совсем новая с защитой (редко).
        if (old != null && old.defense == null) {
          flights.add(_RemoteTableFlight(
            card: defense,
            pairIndex: i,
            isDefense: true,
            fromPlayer: view.defenderIndex,
          ));
        }
      }
    }

    if (flights.isEmpty) return;
    // Не анимируем свои ходы (мой индекс).
    flights.removeWhere((f) => f.fromPlayer == view.myIndex);
    if (flights.isEmpty) return;

    _fxScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_gameUiActive) {
        _fxScheduled = false;
        return;
      }
      for (final f in flights) {
        await _animateRemoteCardFlight(f, view);
        if (!mounted) break;
      }
      if (mounted) _fxScheduled = false;
    });
  }

  Future<void> _animateRemoteCardFlight(
    _RemoteTableFlight flight,
    DurakGameView view,
  ) async {
    if (!mounted || !_gameUiActive) return;
    final id = _cardId(flight.card);
    setState(() => _remoteFlyingCardIds.add(id));

    final fromKey = _oppFanKeys[flight.fromPlayer];
    final from = (fromKey != null ? globalRectOf(fromKey) : null) ??
        Rect.fromCenter(
          center: Offset(
            MediaQuery.sizeOf(context).width / 2,
            MediaQuery.sizeOf(context).height * 0.18,
          ),
          width: _tableCardSize.width * 0.5,
          height: _tableCardSize.height * 0.5,
        );

    final screen = MediaQuery.sizeOf(context);
    final tableRect = globalRectOf(_tableKey);
    final tableCenter = tableRect?.center ??
        Offset(screen.width / 2, screen.height * 0.42);
    final pairW = _tableCardSize.width + 18;
    final col = flight.pairIndex % 3;
    final row = flight.pairIndex ~/ 3;
    final pairCenter = Offset(
      tableCenter.dx + (col - 1) * pairW * 0.55,
      tableCenter.dy + (row - 0.3) * (_tableCardSize.height * 0.55),
    );
    final attackRect = globalRectOf(
          _tableAttackKeys.putIfAbsent(flight.pairIndex, GlobalKey.new),
        ) ??
        Rect.fromCenter(
          center: pairCenter,
          width: _tableCardSize.width,
          height: _tableCardSize.height,
        );

    final Rect to;
    if (flight.isDefense) {
      // Сразу в финальный оффсет защиты относительно атаки.
      to = Rect.fromLTWH(
        attackRect.left + 10,
        attackRect.top + 14,
        _tableCardSize.width,
        _tableCardSize.height,
      );
    } else {
      to = attackRect;
    }

    List<CardFlyTicket> tickets = const [];
    final small = Size(_tableCardSize.width * 0.55, _tableCardSize.height * 0.55);
    await playCardsFlyAnimation(
      context: context,
      cards: [flight.card],
      cardSize: small,
      froms: [
        Rect.fromCenter(
          center: from.center,
          width: small.width,
          height: small.height,
        ),
      ],
      tos: [to],
      // Рубашка → лицо (faceDown включает flipToFace в playCardsFlyAnimation).
      faceDown: true,
      duration: const Duration(milliseconds: 520),
      stagger: Duration.zero,
      curve: Curves.easeInOutCubic,
      beginScale: 1.0,
      endScale: _tableCardSize.width / small.width,
      beginAngles: const [0.22],
      endAngles: const [0.0],
      arcLift: 28,
      keepAtEnd: true,
      onTickets: (t) => tickets = t,
    );
    // Сначала карта на столе под overlay, затем dismiss — без «пустого» кадра
    // и без долгого двойного силуэта.
    if (mounted) {
      setState(() => _remoteFlyingCardIds.remove(id));
      await WidgetsBinding.instance.endOfFrame;
    }
    for (final t in tickets) {
      t.dismiss();
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
    // Нижняя зона (веер) исключена — свайп по картам не вызывает выход.
    final swipeBottomExclude = MediaQuery.sizeOf(context).height * 0.42;
    return SwipeBackScope(
        onBack: _confirmLeave,
        opaqueEdge: false,
        edgeWidth: 16,
        triggerDistance: 44,
        bottomInset: swipeBottomExclude,
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
    // Легальность для жестов — полный набор; подсветка веера — только при выборе.
    final legal = <PlayingCard>{
      ..._legalAttackNow(view),
      if (_isDefendPhase(view)) ...[
        ..._defendLegalFanCards(view, myHand),
        ..._transferLegalFanCards(view, myHand),
      ] else
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

    // Полный веер: летящие карты — дырки слотов (hiddenCards), без схлопывания.
    final handForFan = myHand;

    final useFrozenFanSize = _frozenFanCardSize != null &&
        handForFan.length <= (_frozenFanHandCount ?? 0);
    if (!useFrozenFanSize && _frozenFanCardSize != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _frozenFanCardSize != null) _releaseFanLayoutSnap();
      });
    }
    final animateFanLayout = !_suppressFanLayoutAnim &&
        !_flightLockTable &&
        (!_busy || _fanAnimDuringBusy);
    // Высота зоны: веер приподнят — карты не уходят под нижнее меню.
    final fanProbe = _handFanVisualLayout(
      handForFan.length,
      MediaQuery.sizeOf(context).width,
    );
    final fanCardH = useFrozenFanSize
        ? _frozenFanCardSize!.height
        : fanProbe.cardSize.height;
    final nFan = handForFan.length;
    // Мало карт — опускаем (~1/3 скрыта снизу); много — поднимаем весь веер в кадр.
    // seatLift > 0 — подъём; < 0 — уход под нижний край зоны.
    final seatLift = nFan <= 3
        ? -fanCardH * 0.33
        : nFan <= 6
            ? -fanCardH * 0.22
            : nFan <= 9
                ? -fanCardH * 0.06
                : nFan <= 12
                    ? fanCardH * 0.14
                    : nFan <= 16
                        ? fanCardH * 0.32
                        : nFan <= 22
                            ? fanCardH * 0.48
                            : fanCardH * 0.60;
    final raise = seatLift > 0 ? seatLift : 0.0;
    // CardFan ≈ 1.7h + peek; при подъёме зона выше, при tuck — overflow вниз.
    final fanZoneH = fanCardH * 2.05 + raise + 16;

    final showTimer = !view.isOver &&
        view.isMyTurn &&
        view.turnTimeSec > 0 &&
        view.turnDeadline > 0;
    final showTake = _canTake(view);
    final showBito = _canBito(view);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              // Панель соперника по центру; карты — под панелью.
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _opponentsHeader(view),
                    for (final oi in opponents) _opponentFan(view, oi, tableSize),
                  ],
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
                child: _buildBoard(
                  view,
                  tableSize,
                  trumpCard,
                  showTimer: showTimer,
                ),
              ),
              // Место под веер; кнопки — оверлеем, без сдвига layout.
              // left/right -8 — на всю ширину окна, включая зону крестика.
              SizedBox(
                height: fanZoneH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      // Небольшой отступ слева — крайняя карта читается.
                      left: 2,
                      right: -4,
                      // Поднять над низом — низ карт не прячется под меню shell.
                      bottom: seatLift,
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final fitted = _handFanVisualLayout(
                            handForFan.length,
                            c.maxWidth,
                          );
                          final cardSize = useFrozenFanSize
                              ? _frozenFanCardSize!
                              : fitted.cardSize;
                          final spacing = fitted.spacing;
                          final fillWidth = fitted.fillWidth;
                          return Align(
                            alignment: fillWidth
                                ? Alignment.bottomLeft
                                : Alignment.bottomCenter,
                            child: CardFan(
                              key: _fanKey,
                              cards: handForFan,
                              cardSize: cardSize,
                              spacing: spacing,
                              fillWidth: fillWidth,
                              animateLayout: animateFanLayout,
                              // Всегда подсвечиваем, чем бить/подкинуть; иначе всё dim.
                              legalCards: (!view.canAct || legal.isEmpty)
                                  ? const <PlayingCard>{}
                                  : legal,
                              emphasizeLegal: true,
                              selectedCards: _selected,
                              hiddenCards: _flyingFromHand,
                              // Листать веер можно и когда ходить нечем (только dim).
                              enabled: !view.isOver && !_busy && view.canAct,
                              onActiveChanged: (card) {
                                if (_activeCard == card) return;
                                setState(() {
                                  _activeCard = card;
                                  if (card == null) _dragGlobal = null;
                                });
                              },
                              onDragPosition: (p) {
                                // setState — подсветка цели отбоя следует за пальцем.
                                if (p == null) {
                                  if (_dragGlobal == null) return;
                                  setState(() => _dragGlobal = null);
                                  return;
                                }
                                final prev = _dragGlobal;
                                if (prev != null &&
                                    (prev - p).distanceSquared < 36) {
                                  _dragGlobal = p;
                                  return;
                                }
                                setState(() => _dragGlobal = p);
                              },
                              onTap: (_) {
                                if (_selected.isNotEmpty ||
                                    _activeCard != null ||
                                    _dragGlobal != null) {
                                  _clearHandSelection();
                                }
                              },
                              onLongPress: (card) =>
                                  _toggleSelect(view, card),
                              onReturnToFan: _onCardReturnedToFan,
                              onDrop: (card, global, from) =>
                                  _onCardDrop(view, card, global, from),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Слот кнопки всегда зарезервирован — смена хода не двигает экран.
          Positioned(
            left: 0,
            right: 0,
            bottom: fanZoneH - 10,
            child: SizedBox(
              height: 52,
              child: Center(
                child: (showTake || showBito)
                    ? _PulsingActionButton(
                        label: showTake ? 'Взять' : 'Бито',
                        icon: showTake
                            ? Icons.south_rounded
                            : Icons.check_rounded,
                        onPressed: showTake ? _take : _bito,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Шапка с соперником (1×1). Consumer — чаты/друзья не пересобирают стол/биту/веер.
  Widget _opponentsHeader(DurakGameView view) {
    if (view.playerIds.length != 2 || view.myIndex < 0) {
      return const SizedBox.shrink();
    }
    final oppIndex = view.myIndex == 0 ? 1 : 0;
    if (view.playerIds.length <= oppIndex) return const SizedBox.shrink();
    final oppId = view.playerIds[oppIndex];
    final oppTurn = !view.isOver && !view.isMyTurn;
    final isBot = oppId.startsWith('bot:');
    final meta = view.playerMeta(oppId);

    return Consumer(
      builder: (context, ref, _) {
        var name = isBot
            ? context.l10n.gameBot
            : (meta?.displayName?.trim().isNotEmpty == true
                ? meta!.displayName!.trim()
                : context.l10n.gameOpponent);
        var avatarKind = meta?.avatarKind ?? 'letter';
        var avatarValue = meta?.avatarValue;
        var frameCode = meta?.frameCode;
        var frameColor = meta?.frameColor;

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
        final incomingRequestId =
            hasIncoming ? incoming.first.requestId : null;

        // Рамка всегда смонтирована с одним padding — без прыжка layout.
        return TurnTimerBorder(
          key: const ValueKey('opp-timer-border'),
          active: oppTurn && view.turnTimeSec > 0 && view.turnDeadline > 0,
          turnDeadline: view.turnDeadline,
          turnTimeSec: view.turnTimeSec,
          borderWidth: 2.5,
          radius: 22,
          onExpired: _onTurnTimeExpired,
          child: GameOpponentCard(
            displayName: name,
            avatarKind: avatarKind,
            avatarValue: avatarValue,
            frameCode: frameCode,
            frameColor: frameColor,
            isBot: isBot,
            messageUnread: unread,
            infoTooltip: context.l10n.userInfoTitle,
            messageTooltip: context.l10n.gameWriteMessage,
            compact: MediaQuery.sizeOf(context).width < 420,
            maxWidth: 300,
            align: Alignment.center,
            borderWidth: 0,
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
            onMessageTap:
                isBot ? null : () => unawaited(_openChat(oppId, name)),
          ),
        );
      },
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

  /// Карты соперника дугой с кромкой — не сплошная линия, видно каждую.
  Widget _opponentFan(DurakGameView view, int idx, Size cardSize) {
    final count = view.hands.length > idx ? view.hands[idx].count : 0;
    if (count <= 0) return const SizedBox.shrink();
    final maxW = MediaQuery.sizeOf(context).width - 48;
    // Показываем до 16 плиток; при большем числе — плотнее, без бейджа.
    final shown = count > 16 ? 16 : count;
    var tile = Size(
      (cardSize.width * 0.44).clamp(30.0, 52.0),
      (cardSize.height * 0.44).clamp(44.0, 76.0),
    );
    // Минимальная видимая полоска — карты не сливаются.
    var step = tile.width * (shown > 12
        ? 0.42
        : shown > 8
            ? 0.50
            : shown > 4
                ? 0.58
                : 0.70);
    var totalW = tile.width + step * math.max(shown - 1, 0);
    if (totalW > maxW && shown > 1) {
      step = ((maxW - tile.width) / (shown - 1)).clamp(15.0, step);
      totalW = tile.width + step * (shown - 1);
      if (totalW > maxW) {
        final s = (maxW / totalW).clamp(0.55, 1.0);
        tile = Size(tile.width * s, tile.height * s);
        step *= s;
        totalW = tile.width + step * (shown - 1);
      }
    }
    final arcH = tile.height * 0.28;
    final fanH = tile.height + arcH + 6;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: KeyedSubtree(
        key: _oppFanKeys.putIfAbsent(idx, GlobalKey.new),
        child: Center(
          child: SizedBox(
            key: ValueKey('opp-$idx-$count'),
            width: totalW,
            height: fanH,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                for (var i = 0; i < shown; i++)
                  Builder(
                    builder: (_) {
                      final t = shown <= 1
                          ? 0.0
                          : (i / (shown - 1)) * 2 - 1; // -1..1
                      // Середина ниже (к столу), края выше — читаемая дуга.
                      final y = (1 - t * t) * arcH;
                      final angle = t * 0.22;
                      return Positioned(
                        left: i * step,
                        top: y,
                        child: Transform.rotate(
                          angle: angle,
                          alignment: Alignment.topCenter,
                          child: CardBackWidget(
                            size: tile,
                            elevated: i == shown - 1,
                            outlined: true,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoard(
    DurakGameView view,
    Size cardSize,
    PlayingCard trumpCard, {
    bool showTimer = false,
  }) {
    final focus = _activeCard ??
        (_selected.isNotEmpty ? _selected.first : null);
    // Подсказки при подъёме: одна цель — ближайшая к пальцу (лево/центр/право).
    final lifting =
        _flightLockTable || (!_busy && _activeCard != null);
    final highlightAttack = lifting && _highlightAttackSlot(view);
    final int defendPairIndex;
    if (_flightLockTable && _flightDefendIdx != null) {
      defendPairIndex = _flightDefendIdx!;
    } else if (lifting && focus != null) {
      defendPairIndex = _defendTargetIndex(
        view,
        focus,
        pointer: _dragGlobal,
      );
    } else {
      defendPairIndex = -1;
    }
    final defendTargets =
        defendPairIndex >= 0 ? {defendPairIndex} : const <int>{};
    final pendingAttacks = _pendingAttackPlaceholders(view);
    // Слот-подсказка только при подъёме; посадка идёт в плейсхолдер стола.
    final canShowAttackSlot = !view.isOver &&
        view.attackerIndex == view.myIndex &&
        (view.phase == 'attack' ||
            view.phase == 'attack_follow' ||
            view.phase == 'defend') &&
        !_busy &&
        !_flightLockTable &&
        pendingAttacks.isEmpty;
    final showAttackSlot = canShowAttackSlot && highlightAttack;

    // Колода слева — чуть в кадре, не под боковой панелью.
    final deckPeek = KeyedSubtree(
      key: _deckKey,
      child: DurakDeckPile(
        deckCount: view.deckCount,
        trumpCard: trumpCard,
        trumpSuit: _suitFromApi(view.trumpSuit),
        cardSize: cardSize,
      ),
    );

    final bitoPeek = KeyedSubtree(
      key: _bitoKey,
      child: DurakBitoPile(
        count: _bitoCountFreeze ?? view.bitoCount,
        cardSize: cardSize,
        peek: true,
      ),
    );

    // Единый список слотов: серверные пары + оптимистичные атаки.
    // Стабильный key по id карты — без мигания при подтверждении сервером.
    final tableItems = <Widget>[
      if (!_hidingTable) ...[
        for (var i = 0; i < view.table.length; i++)
          if (_shouldShowTablePair(view.table[i], i))
            Opacity(
              key: ValueKey(
                'atk-${_cardId(view.table[i].attack.toPlayingCard())}',
              ),
              // Скрыто на всё время своего полёта (не только _flightLockTable),
              // иначе ранний WS показывает карту под fly → мигание.
              opacity: _flyingToTable.contains(
                    view.table[i].attack.toPlayingCard(),
                  )
                  ? 0.0
                  : 1.0,
              child: _AnimatedTablePair(
                pair: _tablePairForRender(view.table[i], i),
                cardSize: cardSize,
                highlightAttack: defendTargets.contains(i),
                attackKey: _tableAttackKeys.putIfAbsent(i, GlobalKey.new),
                defendTargetKey:
                    i == defendPairIndex ? _defendTargetKey : null,
                optimisticDefense: _visibleOptimisticDefense(i),
              ),
            ),
        for (var i = 0; i < pendingAttacks.length; i++)
          Opacity(
            key: ValueKey('atk-${_cardId(pendingAttacks[i])}'),
            opacity: _flyingToTable.contains(pendingAttacks[i]) ? 0 : 1,
            child: _AnimatedTablePair(
              pair: DurakTablePairApi(
                attack: DurakApiCard.fromCard(pendingAttacks[i]),
              ),
              cardSize: cardSize,
              // Якорь на лице атаки (не на слоте пары +10/+14) — иначе fly
              // садится «в отбой», а потом карта прыгает в позицию атаки.
              attackKey: i == pendingAttacks.length - 1
                  ? _pendingAttackLandKey
                  : null,
            ),
          ),
      ],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final leftReserve = cardSize.width * 0.95;
        final rightReserve = cardSize.width * 0.95;
        final tableMaxW =
            (constraints.maxWidth - leftReserve - rightReserve)
                .clamp(140.0, constraints.maxWidth * 0.68);
        // Якоря Positioned — Align не двигает колоду/биту при смене хода.
        final deckTop = constraints.maxHeight * 0.28;
        final bitoTop = constraints.maxHeight * 0.18;
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
            if (showAttackSlot)
              Center(
                child: Transform.translate(
                  offset: Offset(
                    view.table.length * cardSize.width * 0.22,
                    8,
                  ),
                  child: KeyedSubtree(
                    key: _attackSlotKey,
                    child: IgnorePointer(
                      child: DurakDropSlot(
                        size: cardSize,
                        active: true,
                      ),
                    ),
                  ),
                ),
              ),
            // Колода: видимый козырь в кадре, рубашка чуть за краем.
            Positioned(
              left: 2,
              top: deckTop,
              child: deckPeek,
            ),
            // Таймер над битой — слот всегда занят (Opacity), смена хода без прыжка.
            Positioned(
              right: 2,
              top: bitoTop,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 42,
                    width: 86,
                    // Одно и то же дерево на свой/чужой ход — без прыжка layout.
                    child: (view.turnTimeSec > 0 && view.turnDeadline > 0)
                        ? IgnorePointer(
                            ignoring: !showTimer,
                            child: Opacity(
                              opacity: showTimer ? 1 : 0,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceUnified
                                        .withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    child: Center(
                                      child: GameTurnCountdown(
                                        key: ValueKey(
                                          'turn-clock-${view.turnDeadline}',
                                        ),
                                        turnDeadline: view.turnDeadline,
                                        turnTimeSec: view.turnTimeSec,
                                        isMyTurn: view.isMyTurn,
                                        onExpired: _onTurnTimeExpired,
                                        labelBuilder: (s) =>
                                            context.l10n.gameSecondsLeft(s),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                  RepaintBoundary(child: bitoPeek),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Всегда 2 в ряд; если не влезает — пары наезжают друг на друга.
  Widget _buildTableRows({
    required List<Widget> items,
    required Size cardSize,
    required double maxWidth,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    final n = items.length;
    final pairW = cardSize.width + 18;
    const baseGap = 10.0;

    final rows = <List<Widget>>[
      for (var i = 0; i < n; i += 2)
        items.skip(i).take(2).toList(),
    ];

    final maxRowLen = rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    // Нужная ширина с нормальным зазором.
    final neededW = maxRowLen * pairW + (maxRowLen - 1) * baseGap;
    // Если не влезает — отрицательный gap (одна пара на другую), без scale-прыжка.
    double gap = baseGap;
    if (neededW > maxWidth && maxRowLen > 1) {
      gap = ((maxWidth - maxRowLen * pairW) / (maxRowLen - 1))
          .clamp(-(pairW * 0.55), baseGap);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) SizedBox(height: gap.abs() < 4 ? 8 : 10),
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

class _RemoteTableFlight {
  const _RemoteTableFlight({
    required this.card,
    required this.pairIndex,
    required this.isDefense,
    required this.fromPlayer,
  });

  final PlayingCard card;
  final int pairIndex;
  final bool isDefense;
  final int fromPlayer;
}

/// Пара на столе. Без pop-анимации при оптимистичном приземлении — карта уже
/// прилетела плавно, лишняя «доводка» не нужна.
class _AnimatedTablePair extends StatelessWidget {
  const _AnimatedTablePair({
    required this.pair,
    required this.cardSize,
    this.highlightAttack = false,
    this.attackKey,
    this.defendTargetKey,
    this.optimisticDefense,
  });

  final DurakTablePairApi pair;
  final Size cardSize;
  final bool highlightAttack;
  final GlobalKey? attackKey;
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
          KeyedSubtree(
            key: attackKey,
            child: PlayingCardWidget(
              card: pair.attack.toPlayingCard(),
              size: cardSize,
              elevated: true,
              dropTarget: highlightAttack && defense == null,
              animate: false,
            ),
          ),
          // Цель отбоя — отдельный ключ на позиции защиты, не на атаке.
          if (defendTargetKey != null && defense == null)
            Positioned(
              left: 10,
              top: 14,
              child: KeyedSubtree(
                key: defendTargetKey,
                child: SizedBox(
                  width: cardSize.width,
                  height: cardSize.height,
                ),
              ),
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
                animate: false,
              ),
            ),
        ],
      ),
    );
    // Без pop/scale — карта уже прилетела в финальную позицию.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: pairChild,
    );
  }
}
