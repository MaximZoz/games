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
import 'package:multigames_client/games/game_stake.dart';
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

/// Отбой: лёгкий поворот вправо (~13°), чтобы был виден угол атаки.
const double _kDefendLandAngle = 0.22;

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
  /// Карта вытащена из веера (peek/drag) — прячем кнопку «Взять»/«Бито».
  bool _holdingFanCard = false;
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
  /// Стол скрыт на время полёта в биту.
  bool _hidingTable = false;
  /// Локальный снимок стола на время «Взять» (сервер уже очистил table).
  List<DurakTablePairApi>? _takeTableHold;
  /// Карты, уже улетевшие со стола при взятии (скрыты по одной).
  final Set<PlayingCard> _leftTableCards = {};
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
  /// Заморозить колоду/козырь на время добора (не исчезает до вылета карты).
  int? _deckCountFreeze;
  /// false — козырь ещё не вытащили под колоду (анимация стартовой раздачи).
  bool _trumpFaceVisible = true;
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
  /// Атакующий/защитник до последнего синка — для порядка добора после биты.
  int _prevAttackerIndex = -1;
  int _prevDefenderIndex = -1;
  /// Число карт у соперников на прошлом кадре (для добора из колоды).
  final Map<int, int> _prevOppHandCounts = {};
  /// Сколько карт ещё летит сопернику — скрыты в веере до посадки.
  final Map<int, int> _oppDealPending = {};
  List<DurakTablePairApi> _prevTable = const [];
  bool _fxScheduled = false;
  Offset _tablePanAccum = Offset.zero;

  /// Локальный порядок карт в веере (после ручной сортировки).
  List<PlayingCard>? _handOrder;

  /// Карты в руке — крупные; на столе/колоде — компактнее.
  static const Size _handCardSize = Size(92, 132);
  static const Size _tableCardSize = Size(66, 94);
  /// Пар на столе в одном ряду (дальше — следующий ряд).
  static const int _tableCols = 2;
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
      _prevDeckCount = -1;
      _prevBitoCount = -1;
      _prevHandLen = -1;
      _prevTable = const [];
      _prevAttackerIndex = -1;
      _prevDefenderIndex = -1;
      _prevOppHandCounts.clear();
      _oppDealPending.clear();
      _pendingDealCards.clear();
      _handOrder = null;
      _trumpFaceVisible = true;
      _deckCountFreeze = null;
      _fxScheduled = false;
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
    // Remote-полёт: пару оставляем в дереве (opacity 0) — якорь посадки жив.
    return true;
  }

  bool _isRemoteAttackHidden(DurakTablePairApi pair, int i) {
    final atk = pair.attack.toPlayingCard();
    final atkId = _cardId(atk);
    return _remoteFlyingCardIds.contains(atkId) &&
        pair.defense == null &&
        !_optimisticDefends.containsKey(i);
  }

  /// Во время «Взять»: пара видна, пока на ней есть хотя бы одна не улетевшая карта.
  bool _shouldShowTakeHoldPair(
    DurakTablePairApi pair,
    int i, {
    required bool usingHold,
  }) {
    if (!usingHold) return _shouldShowTablePair(pair, i);
    final atk = pair.attack.toPlayingCard();
    final def = pair.defense?.toPlayingCard();
    final atkGone = _leftTableCards.contains(atk);
    final defGone = def == null || _leftTableCards.contains(def);
    return !(atkGone && defGone);
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

  /// Снимок при взятии: улетевшие карты не рисуем (остальные ещё на столе).
  DurakTablePairApi _tablePairForTakeHold(
    DurakTablePairApi pair,
    int i, {
    required bool usingHold,
  }) {
    if (!usingHold) return _tablePairForRender(pair, i);
    final atk = pair.attack.toPlayingCard();
    final def = pair.defense;
    final atkGone = _leftTableCards.contains(atk);
    final defGone =
        def == null || _leftTableCards.contains(def.toPlayingCard());
    if (atkGone && !defGone) {
      // Атака уже улетела — показываем защиту как «лежащую» атаку на месте.
      return DurakTablePairApi(attack: def, defense: null);
    }
    if (!atkGone && defGone) {
      return DurakTablePairApi(attack: pair.attack, defense: null);
    }
    return pair;
  }

  PlayingCard? _visibleOptimisticDefense(int i) {
    if (_flightDefendIdx == i && _flightLockTable) return null;
    final opt = _optimisticDefends[i];
    if (opt == null) return null;
    if (_remoteFlyingCardIds.contains(_cardId(opt))) return null;
    return opt;
  }

  /// Веер: всегда на всю [maxWidth]; при росте руки сжимаем размер карт
  /// (шаг пересчитывается так, чтобы веер снова растянулся от края до края).
  ({Size cardSize, double spacing}) _fitHandFan(int n, double maxWidth) {
    if (n <= 0) return (cardSize: _handCardSize, spacing: 0);
    var size = _handCardSize;
    // Раньше и сильнее уменьшаем карты — 10–12 уже заметно плотнее.
    if (n > 28) {
      size = Size(_handCardSize.width * 0.40, _handCardSize.height * 0.40);
    } else if (n > 22) {
      size = Size(_handCardSize.width * 0.48, _handCardSize.height * 0.48);
    } else if (n > 18) {
      size = Size(_handCardSize.width * 0.56, _handCardSize.height * 0.56);
    } else if (n > 14) {
      size = Size(_handCardSize.width * 0.66, _handCardSize.height * 0.66);
    } else if (n > 11) {
      size = Size(_handCardSize.width * 0.74, _handCardSize.height * 0.74);
    } else if (n > 9) {
      size = Size(_handCardSize.width * 0.82, _handCardSize.height * 0.82);
    } else if (n > 7) {
      size = Size(_handCardSize.width * 0.90, _handCardSize.height * 0.90);
    }

    const fanPad = 4.0;
    final usable = (maxWidth - fanPad).clamp(72.0, maxWidth);

    /// Минимальный шаг (доля ширины карты), чтобы полоска оставалась читаемой.
    double minSpacing(Size s) {
      if (n <= 1) return 0;
      final w = s.width;
      if (n > 28) return w * 0.05;
      if (n > 22) return w * 0.06;
      if (n > 18) return w * 0.08;
      if (n > 14) return w * 0.10;
      if (n > 11) return w * 0.12;
      if (n > 9) return w * 0.16;
      if (n > 7) return w * 0.22;
      if (n > 5) return w * 0.32;
      return w * 0.42;
    }

    for (var step = 0; step < 28; step++) {
      final need = size.width + minSpacing(size) * (n - 1);
      if (need <= usable || size.width <= 18) break;
      final scale = (usable / need).clamp(0.28, 0.96);
      size = Size(size.width * scale, size.height * scale);
    }

    // Всегда растягиваем шаг на всю доступную ширину.
    if (n <= 1) return (cardSize: size, spacing: 0);
    final lo = minSpacing(size);
    final hi = size.width * 0.96;
    final fill = (usable - size.width) / (n - 1);
    final spacing = fill.clamp(lo, hi > lo ? hi : lo);
    return (cardSize: size, spacing: spacing);
  }

  /// Веер всегда по центру; при многих картах сжимаем размер/шаг под ширину.
  ({Size cardSize, double spacing, bool fillWidth}) _handFanVisualLayout(
    int n,
    double maxWidth,
  ) {
    if (n <= 0) {
      return (cardSize: _handCardSize, spacing: 0, fillWidth: false);
    }
    if (n <= 3) {
      final spacing = n <= 1 ? 0.0 : _handCardSize.width * 0.62;
      return (
        cardSize: _handCardSize,
        spacing: spacing,
        fillWidth: false,
      );
    }
    final fitted = _fitHandFan(n, maxWidth);
    return (
      cardSize: fitted.cardSize,
      spacing: fitted.spacing,
      fillWidth: false,
    );
  }

  /// Сколько ещё атак/подкидов можно положить (учитывает оптимистичные).
  ///
  /// Не больше, чем защитник сможет отбить: рука − неотбитые на столе.
  /// Пример: рука 5, неотбитых 2 → подкид ещё 3.
  int _attackRoom(DurakGameView view) {
    final def = view.defenderIndex;
    final defCount = (def >= 0 && def < view.hands.length)
        ? view.hands[def].count
        : 6;
    var beaten = 0;
    for (var i = 0; i < view.table.length; i++) {
      final p = view.table[i];
      if (p.defense != null || _optimisticDefends.containsKey(i)) {
        beaten++;
      }
    }
    // Макс. пар = отбитые + карты в руке защитника (как на сервере).
    var maxPairs = beaten + defCount;
    if (maxPairs < 1) maxPairs = 1;
    const maxAttacks = 6;
    if (maxAttacks < maxPairs) maxPairs = maxAttacks;
    // Первый отбой — не больше 5 карт на столе (включая первую атаку).
    if (view.firstRound && maxPairs > 5) maxPairs = 5;
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
      // Только карты, явно помеченные как добор из колоды — остальное
      // показываем сразу (иначе после хода веер может опустеть).
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

  /// Подсветка слота перевода при подъёме карты того же ранга.
  bool _highlightTransferSlot(DurakGameView view) {
    final focus = _activeCard ??
        (_selected.isNotEmpty ? _selected.first : null);
    if (focus == null || _busy || view.isOver) return false;
    if (!_isDefendPhase(view)) return false;
    final hand = _apiCardsToPlaying(
      view.hands.length > view.myIndex && view.myIndex >= 0
          ? (view.hands[view.myIndex].cards ?? const [])
          : const [],
    );
    return _transferLegalFanCards(view, hand).contains(focus);
  }

  int _nextAliveAfter(DurakGameView view, int idx) {
    final n = view.hands.length;
    if (n <= 0) return idx;
    final finished = view.finished.toSet();
    for (var i = 1; i <= n; i++) {
      final j = (idx + i) % n;
      if (!finished.contains(j)) return j;
    }
    return idx;
  }

  /// Как на сервере: у следующего защитника хватает карт на весь стол после перевода.
  bool _canTransferToNext(DurakGameView view) {
    if (view.table.isEmpty) return false;
    if (view.table.any((p) => p.defense != null)) return false;
    if (_optimisticDefends.isNotEmpty) return false;
    var cap = 6;
    if (view.firstRound && cap > 5) cap = 5;
    if (view.table.length + 1 > cap) return false;
    final next = _nextAliveAfter(view, view.defenderIndex);
    if (next < 0 || next >= view.hands.length) return false;
    return view.hands[next].count >= view.table.length + 1;
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

  /// Предпочтительная цель полёта — ближайшая к пальцу/карте неотбитая атака
  /// (в т.ч. во 2–3 ряду при раскладке 2 в ряд).
  int _defendTargetIndex(
    DurakGameView view,
    PlayingCard? card, {
    Offset? pointer,
  }) {
    final candidates = _defendTargetIndexes(view, card).toList()..sort();
    if (candidates.isEmpty) return -1;
    if (candidates.length == 1) return candidates.first;
    final p = pointer ?? _dragGlobal;
    if (p == null) return candidates.first;
    var best = candidates.first;
    var bestDist = double.infinity;
    final n = view.table.length;
    for (final i in candidates) {
      final key = _tableAttackKeys[i];
      final rect = key != null ? globalRectOf(key) : null;
      final center = rect?.center ?? _estimatePairCenter(i, n);
      if (center == null) continue;
      final d = (center - p).distanceSquared;
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  /// Оценка центра пары на столе (2 в ряд), если GlobalKey ещё без rect.
  Offset? _estimatePairCenter(int index, int total) {
    final tableRect = globalRectOf(_tableKey);
    if (tableRect == null || total <= 0) return null;
    const cols = _tableCols;
    final pairW = _tableCardSize.width + 18;
    final pairH = _tablePairHeight(_tableCardSize);
    const gap = 10.0;
    final col = index % cols;
    final row = index ~/ cols;
    final rows = (total + cols - 1) ~/ cols;
    final rowLen = (row * cols + cols <= total)
        ? cols
        : (total - row * cols).clamp(1, cols);
    final rowWidth = rowLen * pairW + (rowLen - 1) * gap;
    final rowLeft = tableRect.center.dx - rowWidth / 2;
    final colH = _tableStackHeight(_tableCardSize, rows);
    final top = tableRect.center.dy -
        colH / 2 +
        _tableRowTop(_tableCardSize, row, rows);
    return Offset(
      rowLeft + col * (pairW + gap) + pairW / 2,
      top + pairH / 2,
    );
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
  /// Пусто, если у следующего защитника не хватит карт отбить весь стол.
  Set<PlayingCard> _transferLegalFanCards(
    DurakGameView view,
    List<PlayingCard> hand,
  ) {
    if (view.mode != 'perevodnoi') return {};
    if (!_isDefendPhase(view)) return {};
    if (!_canTransferToNext(view)) return {};
    final rank = view.table.first.attack.toPlayingCard().rank;
    final byRank = {for (final c in hand) if (c.rank == rank) c};
    // Сервер — уточнение; при рассинхроне оставляем локальный ранг.
    final server = _apiCardsToPlaying(view.legalTransfer).toSet();
    if (server.isNotEmpty) {
      final hit = byRank.intersection(server);
      if (hit.isNotEmpty) return hit;
    }
    return byRank;
  }

  /// Выбор отбоя vs перевода: ближе к цели отбоя — бьём, к слоту — переводим.
  bool _preferTransferOverDefend(
    DurakGameView view,
    PlayingCard card, {
    Offset? pointer,
  }) {
    final p = pointer ?? _dragGlobal;
    if (p == null) return false;
    final defendIdx = _defendTargetIndex(view, card, pointer: p);
    if (defendIdx < 0) return true;
    final atkKey = _tableAttackKeys[defendIdx];
    final defendCenter = (atkKey != null ? globalRectOf(atkKey)?.center : null) ??
        _estimatePairCenter(defendIdx, view.table.length);
    // Слот перевода — следующая ячейка сетки (table.length при total+1).
    final slotCenter = globalRectOf(_attackSlotKey)?.center ??
        _estimatePairCenter(view.table.length, view.table.length + 1);
    if (defendCenter == null) return true;
    if (slotCenter == null) return false;
    return (slotCenter - p).distanceSquared <
        (defendCenter - p).distanceSquared;
  }

  bool _isAttackPhase(DurakGameView view) =>
      (view.canThrowIn ||
          view.attackerIndex == view.myIndex ||
          view.legalAttack.isNotEmpty) &&
      (view.phase == 'attack' ||
          view.phase == 'attack_follow' ||
          view.phase == 'defend' ||
          view.phase == 'take_follow');

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
    final canDefend = isDefend && defendTargets.isNotEmpty;
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
    final canTransfer =
        isDefend && transferLegal.contains(cards.first);
    // Козырная девятка на девятку: и отбить, и перевести — выбор по близости.
    var doDefend = false;
    var doTransfer = false;
    if (canDefend && canTransfer) {
      if (_preferTransferOverDefend(
        view,
        cards.first,
        pointer: pointer,
      )) {
        doTransfer = true;
      } else {
        doDefend = true;
      }
    } else if (canDefend) {
      doDefend = true;
    } else if (canTransfer) {
      doTransfer = true;
    }
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

    // Сразу убрать из веера (схлопывание уже на lift). Без «дырки» —
    // иначе после clearLift веер снова растянется до посадки.
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
      }
      _removeFromHandOrder(cards, view);
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

    // Отбой: в полёте крутим до _defendLandAngle — на столе уже повёрнута.
    final landAngle = doDefend ? _kDefendLandAngle : 0.0;

    // Как атака: стартуем fly и сразу return true — иначе оверлей веера
    // дублирует карту на всём полёте (onDrop ждёт завершения).
    final firstFly = playCardFlyAnimation(
      context: context,
      card: cards.first,
      cardSize: _handCardSize,
      from: froms.first,
      to: tos.first,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      beginScale: beginScale,
      endScale: shrink,
      beginAngle: 0,
      endAngle: landAngle,
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
        await Future<void>.delayed(Duration(milliseconds: 28 * i));
        if (!mounted) break;
        tickets.add(
          await playCardFlyAnimation(
            context: context,
            card: cards[i],
            cardSize: _handCardSize,
            from: froms[i],
            to: tos[i],
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            beginScale: beginScale,
            endScale: shrink,
            beginAngle: 0,
            endAngle: landAngle,
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
          // После биты/авто-закрытия раунда не затираем prev — добор сыграет FX.
          _syncPrevAfterMove(v);
          _syncHandOrderFromServer(v);
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
    var base = _handOrder;
    if (base == null || base.isEmpty) {
      base = _apiCardsToPlaying(
        view.hands.length > view.myIndex && view.myIndex >= 0
            ? (view.hands[view.myIndex].cards ?? const [])
            : const [],
      );
    }
    // Не затирать order пустым списком — иначе следующий добор анимирует всю руку.
    if (base.isEmpty) return;
    _handOrder = base.where((c) => !cards.contains(c)).toList();
  }

  /// После своего хода: order = актуальная рука сервера (без добора).
  void _syncHandOrderFromServer(DurakGameView v) {
    final hand = _apiCardsToPlaying(
      v.hands.length > v.myIndex && v.myIndex >= 0
          ? (v.hands[v.myIndex].cards ?? const [])
          : const [],
    );
    if (hand.isEmpty) return;
    final handSet = hand.toSet();
    final prev = _handOrder;
    if (prev == null || prev.isEmpty) {
      _handOrder = List<PlayingCard>.of(hand);
      return;
    }
    final next = <PlayingCard>[for (final c in prev) if (handSet.contains(c)) c];
    for (final c in hand) {
      if (!next.contains(c)) next.add(c);
    }
    _handOrder = next;
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

    // Сразу убрать из веера (схлопывание уже на lift при вытаскивании).
    // Pending-слот на столе (opacity 0 под fly).
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
      _suppressFanLayoutAnim = true;
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
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
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
        await Future<void>.delayed(Duration(milliseconds: 28 * i));
        if (!mounted) break;
        tickets.add(
          await playCardFlyAnimation(
            context: context,
            card: cards[i],
            cardSize: _handCardSize,
            from: froms[i],
            to: tos[i],
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
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
        _suppressFanLayoutAnim = true;
      });
      _releaseFanLayoutSnap();
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
    // Как в _AnimatedTablePair / _buildTableRows.
    final pairW = _tableCardSize.width + 18;
    const gap = 10.0;
    const cols = _tableCols;
    final col = idx % cols;
    final row = idx ~/ cols;
    final rowLen = (row * cols + cols <= n)
        ? cols
        : (n - row * cols).clamp(1, cols);
    final rowWidth = rowLen * pairW + (rowLen - 1) * gap;
    final rowLeft = center.dx - rowWidth / 2;
    final pairLeft = rowLeft + col * (pairW + gap);
    final rows = (n + cols - 1) ~/ cols;
    final colH = _tableStackHeight(_tableCardSize, rows);
    final pairTop = center.dy -
        colH / 2 +
        _tableRowTop(_tableCardSize, row, rows);
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
        _syncPrevAfterMove(v);
        _syncHandOrderFromServer(v);
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

  /// Карта в полёте (атака/отбой) — не показывать «Бито»/«Взять».
  bool get _cardFlightActive =>
      _flyingFromHand.isNotEmpty ||
      _flyingToTable.isNotEmpty ||
      _flightLockTable;

  bool _canTake(DurakGameView view) {
    if (view.isOver ||
        _busy ||
        _cardFlightActive ||
        view.defenderIndex != view.myIndex ||
        view.phase != 'defend' ||
        view.table.isEmpty) {
      return false;
    }
    // Пустая рука — сервер закрывает раунд сам (бита + возврат неотбитых).
    if (view.myIndex >= 0 &&
        view.myIndex < view.hands.length &&
        view.hands[view.myIndex].count == 0) {
      return false;
    }
    return true;
  }

  bool _canBito(DurakGameView view) =>
      !view.isOver &&
      !_busy &&
      !_cardFlightActive &&
      view.attackerIndex == view.myIndex &&
      view.phase == 'attack_follow' &&
      view.table.isNotEmpty &&
      view.table.every((p) => p.defense != null);

  /// Атакующий подтверждает конец подкида вдогонку после «Беру».
  bool _canDone(DurakGameView view) =>
      !view.isOver &&
      !_busy &&
      !_cardFlightActive &&
      view.attackerIndex == view.myIndex &&
      view.phase == 'take_follow' &&
      view.table.isNotEmpty;

  /// Пас подкида (3–4 игрока, не главный атакующий).
  bool _canPass(DurakGameView view) =>
      !view.isOver &&
      !_busy &&
      !_cardFlightActive &&
      view.canThrowIn &&
      view.attackerIndex != view.myIndex &&
      (view.phase == 'attack_follow' || view.phase == 'take_follow') &&
      view.table.isNotEmpty;

  /// Объявить «Беру» — стол остаётся, соперник может подкинуть вдогонку.
  Future<void> _take() async {
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    if (view == null || !_canTake(view)) return;
    try {
      await ref
          .read(durakRepositoryProvider)
          .move(widget.gameId, type: 'take');
      ref.invalidate(durakGameProvider(widget.gameId));
      try {
        await ref.read(durakGameProvider(widget.gameId).future);
      } catch (_) {}
    } on GamesException catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
      }
    }
  }

  /// Закончить подкид вдогонку — защитник забирает стол.
  Future<void> _confirmTakeDone() async {
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    if (view == null || !_canDone(view)) return;
    try {
      await ref
          .read(durakRepositoryProvider)
          .move(widget.gameId, type: 'done');
      ref.invalidate(durakGameProvider(widget.gameId));
      try {
        await ref.read(durakGameProvider(widget.gameId).future);
      } catch (_) {}
    } on GamesException catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
      }
    }
  }

  Future<void> _pass() async {
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    if (view == null || !_canPass(view)) return;
    try {
      await ref
          .read(durakRepositoryProvider)
          .move(widget.gameId, type: 'pass');
      ref.invalidate(durakGameProvider(widget.gameId));
      try {
        await ref.read(durakGameProvider(widget.gameId).future);
      } catch (_) {}
    } on GamesException catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
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
      // Сначала узнаём добор и прячем карты, потом invalidate — без мигания в веере.
      DurakGameView? fresh;
      try {
        fresh =
            await ref.read(durakRepositoryProvider).getGame(widget.gameId);
      } catch (_) {}
      if (!mounted) return;
      if (fresh != null) {
        final hand = _apiCardsToPlaying(
          fresh.hands.length > fresh.myIndex && fresh.myIndex >= 0
              ? (fresh.hands[fresh.myIndex].cards ?? const [])
              : const [],
        );
        // Дельта по длине руки — не «все карты, которых нет в order».
        final prevLen = _prevHandLen >= 0
            ? _prevHandLen
            : (_handOrder?.length ?? 0);
        final dealtN = (hand.length - prevLen).clamp(0, hand.length);
        final dealt = _incomingDealCards(hand, dealtN);
        final deckBefore = _prevDeckCount >= 0 ? _prevDeckCount : fresh.deckCount;
        final oppDeals = _opponentDealDeltas(fresh);
        if (dealt.isNotEmpty) {
          _pendingDealCards.addAll(dealt);
        }
        if (dealt.isNotEmpty || oppDeals.isNotEmpty) {
          _armDeckFreeze(deckBefore);
        }
        ref.invalidate(durakGameProvider(widget.gameId));
        try {
          await ref.read(durakGameProvider(widget.gameId).future);
        } catch (_) {}
        if (!mounted) return;
        final refillAttacker = _prevAttackerIndex >= 0
            ? _prevAttackerIndex
            : fresh.attackerIndex;
        final refillDefender = _prevDefenderIndex >= 0
            ? _prevDefenderIndex
            : fresh.defenderIndex;
        _prevDeckCount = fresh.deckCount;
        _prevBitoCount = fresh.bitoCount;
        _prevHandLen = hand.length;
        _prevTable = List.of(fresh.table);
        _prevAttackerIndex = fresh.attackerIndex;
        _prevDefenderIndex = fresh.defenderIndex;
        _syncPrevOppHandCounts(fresh);
        if (_gameUiActive && (dealt.isNotEmpty || oppDeals.isNotEmpty)) {
          await _animateRefillDeals(
            view: fresh,
            myIncoming: dealt,
            oppDeals: oppDeals,
            refillAttacker: refillAttacker,
            refillDefender: refillDefender,
            deckCountBefore: deckBefore,
          );
        }
      } else {
        ref.invalidate(durakGameProvider(widget.gameId));
        try {
          await ref.read(durakGameProvider(widget.gameId).future);
        } catch (_) {}
      }
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

  /// Сверху вниз: сначала защита, потом атака — при взятии верх улетает первым.
  List<PlayingCard> _flattenTableCardsTopFirst(List<DurakTablePairApi> table) {
    final cards = <PlayingCard>[];
    for (final p in table) {
      if (p.defense != null) cards.add(p.defense!.toPlayingCard());
      cards.add(p.attack.toPlayingCard());
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
              center.dx + (i % _tableCols - (_tableCols - 1) / 2) * pairW * 0.85,
              center.dy + (i ~/ _tableCols - 0.3) * (_tableCardSize.height * 0.62),
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

  List<Rect> _tableCardGlobalRectsTopFirst(List<DurakTablePairApi> table) {
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
              center.dx + (i % _tableCols - (_tableCols - 1) / 2) * pairW * 0.85,
              center.dy + (i ~/ _tableCols - 0.3) * (_tableCardSize.height * 0.62),
            ),
            width: _tableCardSize.width,
            height: _tableCardSize.height,
          );
      if (p.defense != null) {
        out.add(Rect.fromLTWH(
          atk.left + 10,
          atk.top + 14,
          atk.width,
          atk.height,
        ));
      }
      out.add(atk);
    }
    return out;
  }

  Future<void> _animateTableToFan(
    List<DurakTablePairApi> table, {
    List<Rect>? fromOverrides,
    List<PlayingCard>? cardsOverride,
    void Function(PlayingCard card)? onCardLaunch,
    Duration flyDuration = const Duration(milliseconds: 160),
    int settleMs = 90,
  }) async {
    if (table.isEmpty || !mounted || !_gameUiActive) return;
    final cards = cardsOverride ?? _flattenTableCards(table);
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
      // Снять со стола в момент старта полёта — остальные ещё лежат.
      onCardLaunch?.call(card);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
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
          beginAngle: 0,
          endAngle: angle,
          flyDuration: flyDuration,
          settleMs: settleMs,
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
  Future<void> _animateDealCardsToFan(
    List<PlayingCard> cards, {
    Duration flyDuration = const Duration(milliseconds: 320),
    int settleMs = 180,
  }) async {
    if (cards.isEmpty || !mounted || !_gameUiActive) return;
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    final trump = view != null
        ? _suitFromApi(view.trumpSuit)
        : Suit.spades;

    final serverHand = view != null
        ? _apiCardsToPlaying(
            view.hands.length > view.myIndex && view.myIndex >= 0
                ? (view.hands[view.myIndex].cards ?? const [])
                : const [],
          )
        : const <PlayingCard>[];
    final dealSet = cards.toSet();
    // Карты, которые уже должны быть в веере — никогда не убираем перед добором.
    final keepFromServer = [
      for (final c in serverHand)
        if (!dealSet.contains(c)) c,
    ];
    // Не тянуть в веер карты, которые ещё летят (_pendingDealCards) —
    // иначе при стартовой раздаче вспыхнет вся рука сразу.
    final stillFlying = {..._pendingDealCards, ...dealSet};
    var order = <PlayingCard>[
      for (final c in (_handOrder ?? const <PlayingCard>[]))
        if (!dealSet.contains(c) && keepFromServer.contains(c)) c,
    ];
    for (final c in keepFromServer) {
      if (!order.contains(c) && !stillFlying.contains(c)) order.add(c);
    }
    // Сразу зафиксировать веер без добираемых — иначе кадр с пустой рукой.
    _handOrder = List<PlayingCard>.of(order);
    _pendingDealCards.addAll(dealSet);

    final manageBusy = !_busy;
    setState(() {
      _handOrder = order;
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
      // Старт с текущей колоды/козыря, потом уменьшаем freeze.
      final deckFrom = _deckDealFromRect(jitter: i * 1.5);
      _consumeDeckFreezeSlot();
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
      if (fan != null) {
        await fan.foldCardIn(
          card: card,
          from: deckFrom,
          beginScale: _tableCardSize.width / lay.cardSize.width,
          flipToFace: true,
          beginAngle: 0.2,
          endAngle: angle,
          flyDuration: flyDuration,
          settleMs: settleMs,
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
      duration: const Duration(milliseconds: 380),
      stagger: const Duration(milliseconds: 32),
      curve: Curves.easeOutCubic,
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
      _prevAttackerIndex = view.attackerIndex;
      _prevDefenderIndex = view.defenderIndex;
      _syncPrevOppHandCounts(view);
      return;
    }
    final handLen = view.hands.length > view.myIndex && view.myIndex >= 0
        ? (view.hands[view.myIndex].cards?.length ??
            view.hands[view.myIndex].count)
        : 0;
    final deck = view.deckCount;
    final bito = view.bitoCount;

    final hand = _apiCardsToPlaying(
      view.hands.length > view.myIndex && view.myIndex >= 0
          ? (view.hands[view.myIndex].cards ?? const [])
          : const [],
    );

    // Пока свой ход с FX — не трогаем prev (иначе проглотим авто-бито/добор).
    if (_busy) return;

    // Первый кадр: стартовая раздача или просто запомнить базу.
    if (_prevDeckCount < 0) {
      if (_shouldAnimateOpeningDeal(view, handLen)) {
        _scheduleOpeningDeal(view, hand);
        return;
      }
      // Порядок веера обязан быть до любого FX — иначе remain/pending съедают руку.
      if ((_handOrder == null || _handOrder!.isEmpty) &&
          hand.isNotEmpty &&
          _pendingDealCards.isEmpty) {
        _handOrder = List<PlayingCard>.of(hand);
      }
      _prevDeckCount = deck;
      _prevBitoCount = bito;
      _prevHandLen = handLen;
      _prevTable = List.of(view.table);
      _prevAttackerIndex = view.attackerIndex;
      _prevDefenderIndex = view.defenderIndex;
      _syncPrevOppHandCounts(view);
      return;
    }

    // Порядок веера обязан быть до любого FX — иначе remain/pending съедают руку.
    if ((_handOrder == null || _handOrder!.isEmpty) &&
        hand.isNotEmpty &&
        _pendingDealCards.isEmpty &&
        !_fxScheduled) {
      _handOrder = List<PlayingCard>.of(hand);
    }

    final dealt = handLen - _prevHandLen;
    final deckDropped = _prevDeckCount - deck;
    final prevBito = _prevBitoCount;
    final prevDeck = _prevDeckCount;
    final bitoGrew = bito > prevBito && _prevTable.isNotEmpty;
    final tableSnapshot = List<DurakTablePairApi>.of(_prevTable);
    final oppDeals = _opponentDealDeltas(view);
    // Добор на сервере идёт со СТАРЫМ атакующим (до смены хода после биты).
    final refillAttacker =
        _prevAttackerIndex >= 0 ? _prevAttackerIndex : view.attackerIndex;
    final refillDefender =
        _prevDefenderIndex >= 0 ? _prevDefenderIndex : view.defenderIndex;
    final takenN = _flattenTableCards(tableSnapshot).length;
    // Стол забрали (после Done вдогонку): бита не выросла, last_was_take.
    final takeResolved = !_suppressRemoteBitoFx &&
        !_hidingTable &&
        tableSnapshot.isNotEmpty &&
        view.table.isEmpty &&
        !bitoGrew &&
        view.lastWasTake;
    final remoteTake = takeResolved && refillDefender != view.myIndex;
    final localTakeResolved = takeResolved && refillDefender == view.myIndex;

    _prevDeckCount = deck;
    _prevBitoCount = bito;
    _prevHandLen = handLen;
    _prevTable = List.of(view.table);
    _prevAttackerIndex = view.attackerIndex;
    _prevDefenderIndex = view.defenderIndex;
    _syncPrevOppHandCounts(view);

    // Только реальный добор (дельта руки), не «все карты которых нет в order».
    final incoming = _incomingDealCards(hand, dealt);
    final willDealFromDeck = deckDropped > 0 &&
        (incoming.isNotEmpty || oppDeals.isNotEmpty || remoteTake);
    // Сразу в этом же build — иначе колода/козырь мигнут пустыми (view уже 0).
    if (willDealFromDeck || (bitoGrew && prevDeck > deck)) {
      _armDeckFreeze(prevDeck);
    }

    // Соперник «Взял»: стол → его веер, затем добор из колоды.
    if (remoteTake) {
      // Прячем добор до анимации — в этом же кадре, до отрисовки веера.
      if (incoming.isNotEmpty) _pendingDealCards.addAll(incoming);
      _fxScheduled = true;
      final taker = refillDefender;
      // В дельте руки соперника — и взятые со стола, и добор; анимируем раздельно.
      final oppDealsDeck = <int, int>{};
      for (final e in oppDeals.entries) {
        if (e.key == taker) {
          final deckOnly = (e.value - takenN).clamp(0, e.value);
          if (deckOnly > 0) oppDealsDeck[e.key] = deckOnly;
        } else if (e.value > 0) {
          oppDealsDeck[e.key] = e.value;
        }
      }
      setState(() {
        _takeTableHold = tableSnapshot;
        _leftTableCards.clear();
        _oppDealPending[taker] = (_oppDealPending[taker] ?? 0) + takenN;
        _armDeckFreeze(prevDeck);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          _fxScheduled = false;
          return;
        }
        await _animateTableToOpponentFan(tableSnapshot, taker);
        if (!mounted) {
          _fxScheduled = false;
          return;
        }
        setState(() {
          _takeTableHold = null;
          _leftTableCards.clear();
        });
        if (incoming.isNotEmpty || oppDealsDeck.isNotEmpty) {
          await _animateRefillDeals(
            view: view,
            myIncoming: incoming,
            oppDeals: oppDealsDeck,
            refillAttacker: refillAttacker,
            refillDefender: refillDefender,
            deckCountBefore: prevDeck,
          );
        } else {
          _clearDeckCountFreeze();
        }
        if (mounted) _fxScheduled = false;
      });
      return;
    }

    // Я забрал стол (после подкида вдогонку) — карты со стола в мой веер.
    if (localTakeResolved) {
      final taken = _flattenTableCardsTopFirst(tableSnapshot);
      final takenSet = taken.toSet();
      final froms = _tableCardGlobalRectsTopFirst(tableSnapshot);
      // Добор = новые карты руки минус взятые со стола.
      final dealtOnly = [
        for (final c in incoming)
          if (!takenSet.contains(c)) c,
      ];
      if (dealtOnly.isNotEmpty) _pendingDealCards.addAll(dealtOnly);
      _fxScheduled = true;
      setState(() {
        _takeTableHold = tableSnapshot;
        _leftTableCards.clear();
        _suppressNextDealFx = true;
        if (taken.isNotEmpty) {
          final base = _handOrder ??
              [
                for (final c in hand) if (!takenSet.contains(c)) c,
              ];
          _handOrder = [
            ...base.where((c) => !takenSet.contains(c)),
            ...taken,
          ];
          _flyingFromHand.addAll(taken);
          _incomingFanCards.addAll(taken);
        }
        _armDeckFreeze(prevDeck);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          _fxScheduled = false;
          return;
        }
        if (tableSnapshot.isNotEmpty && _gameUiActive) {
          await _animateTableToFan(
            tableSnapshot,
            fromOverrides: froms,
            cardsOverride: taken,
            onCardLaunch: (card) {
              if (!mounted) return;
              setState(() => _leftTableCards.add(card));
            },
          );
        }
        if (!mounted) {
          _fxScheduled = false;
          return;
        }
        setState(() {
          _takeTableHold = null;
          _leftTableCards.clear();
          _flyingFromHand.removeAll(taken);
          _incomingFanCards.removeAll(taken);
        });
        if (dealtOnly.isNotEmpty || oppDeals.isNotEmpty) {
          await _animateRefillDeals(
            view: view,
            myIncoming: dealtOnly,
            oppDeals: oppDeals,
            refillAttacker: refillAttacker,
            refillDefender: refillDefender,
            deckCountBefore: prevDeck,
          );
        } else {
          _clearDeckCountFreeze();
          final trump = _suitFromApi(view.trumpSuit);
          _mergeHandAfterTake(hand, trump);
        }
        if (mounted) {
          _suppressNextDealFx = false;
          _fxScheduled = false;
        }
      });
      return;
    }

    // Сначала бито (в т.ч. авто после пустой руки), потом добор — иначе
    // дельта руки проглотит анимацию стола в отбой.
    if (bitoGrew && !_hidingTable && !_suppressRemoteBitoFx) {
      if (incoming.isNotEmpty) _pendingDealCards.addAll(incoming);
      _fxScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          _pendingDealCards.clear();
          _fxScheduled = false;
          return;
        }
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
          });
          if (incoming.isNotEmpty || oppDeals.isNotEmpty) {
            await _animateRefillDeals(
              view: view,
              myIncoming: incoming,
              oppDeals: oppDeals,
              refillAttacker: refillAttacker,
              refillDefender: refillDefender,
              deckCountBefore: prevDeck,
            );
          } else if (hand.isNotEmpty) {
            final trump = _suitFromApi(view.trumpSuit);
            _sortHandInFan(hand, trump, animate: false);
          }
          _pendingDealCards.clear();
          _fxScheduled = false;
        }
      });
    } else if (dealt > 0 && deckDropped > 0) {
      if (_suppressNextDealFx) {
        _suppressNextDealFx = false;
        // Свой добор уже/будет в take — только соперники, в порядке атаки.
        if (oppDeals.isNotEmpty) {
          _fxScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) {
              _fxScheduled = false;
              return;
            }
            await _animateRefillDeals(
              view: view,
              myIncoming: const [],
              oppDeals: oppDeals,
              refillAttacker: refillAttacker,
              refillDefender: refillDefender,
              skipMyDeal: true,
              deckCountBefore: prevDeck,
            );
            if (mounted) _fxScheduled = false;
          });
        }
      } else {
        if (incoming.isNotEmpty) _pendingDealCards.addAll(incoming);
        _fxScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) {
            _pendingDealCards.clear();
            _fxScheduled = false;
            return;
          }
          await _animateRefillDeals(
            view: view,
            myIncoming: incoming,
            oppDeals: oppDeals,
            refillAttacker: refillAttacker,
            refillDefender: refillDefender,
            deckCountBefore: prevDeck,
          );
          if (mounted) {
            final trump = _suitFromApi(view.trumpSuit);
            _pendingDealCards.clear();
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
      // Карты в руке появились без ухода колоды — не добор (сортировка/синк).
      _pendingDealCards.clear();
      if (_suppressNextDealFx) {
        _suppressNextDealFx = false;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final trump = _suitFromApi(view.trumpSuit);
          _sortHandInFan(hand, trump);
        });
      }
    } else if (deckDropped > 0 &&
        (incoming.isNotEmpty || oppDeals.isNotEmpty)) {
      // Колода уменьшилась — добор после биты/взятия (prev уже мог сдвинуться).
      if (incoming.isNotEmpty) _pendingDealCards.addAll(incoming);
      _fxScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          _pendingDealCards.clear();
          _fxScheduled = false;
          return;
        }
        await _animateRefillDeals(
          view: view,
          myIncoming: incoming,
          oppDeals: oppDeals,
          refillAttacker: refillAttacker,
          refillDefender: refillDefender,
          deckCountBefore: prevDeck,
        );
        if (mounted) {
          _pendingDealCards.clear();
          _fxScheduled = false;
        }
      });
    } else if (!_hidingTable && !_fxScheduled) {
      // Ход соперника: карта летит из его веера на стол / в отбой.
      if (_handOrder == null && hand.isNotEmpty) {
        _handOrder = List<PlayingCard>.of(hand);
      }
      _scheduleRemoteTableFx(tableSnapshot, view);
    }
  }

  Map<int, int> _snapshotOppHandCounts(DurakGameView view) {
    final m = <int, int>{};
    for (var i = 0; i < view.hands.length; i++) {
      if (i == view.myIndex) continue;
      m[i] = view.hands[i].count;
    }
    return m;
  }

  void _syncPrevOppHandCounts(DurakGameView view) {
    _prevOppHandCounts
      ..clear()
      ..addAll(_snapshotOppHandCounts(view));
  }

  /// Сколько карт каждый соперник добрал с прошлого кадра.
  Map<int, int> _opponentDealDeltas(DurakGameView view) {
    final next = _snapshotOppHandCounts(view);
    final deltas = <int, int>{};
    for (final e in next.entries) {
      final prev = _prevOppHandCounts[e.key];
      if (prev == null) continue;
      final d = e.value - prev;
      if (d > 0) deltas[e.key] = d;
    }
    return deltas;
  }

  /// Порядок добора как на сервере: атакующий → остальные по кругу → защитник.
  List<int> _refillDealOrder({
    required int attacker,
    required int defender,
    required int playerCount,
  }) {
    if (playerCount <= 0) return const [];
    final atk = attacker.clamp(0, playerCount - 1);
    final def = defender.clamp(0, playerCount - 1);
    final order = <int>[atk];
    for (var i = 1; i < playerCount - 1; i++) {
      order.add((atk + i) % playerCount);
    }
    if (def != atk) order.add(def);
    return order;
  }

  /// Держать колоду/козырь на экране с числа [before], пока идёт добор.
  void _armDeckFreeze(int before) {
    if (before <= 0) return;
    final cur = _deckCountFreeze;
    if (cur == null || cur < before) {
      _deckCountFreeze = before;
    }
  }

  void _clearDeckCountFreeze() {
    if (_deckCountFreeze == null) return;
    if (mounted) {
      setState(() => _deckCountFreeze = null);
    } else {
      _deckCountFreeze = null;
    }
  }

  /// Уменьшить замороженную колоду на 1 после старта полёта карты.
  void _consumeDeckFreezeSlot() {
    final cur = _deckCountFreeze;
    if (cur == null) return;
    if (!mounted) {
      _deckCountFreeze = cur > 0 ? cur - 1 : 0;
      return;
    }
    setState(() => _deckCountFreeze = cur > 0 ? cur - 1 : 0);
  }

  Rect _deckDealFromRect({double jitter = 0}) {
    final base = globalRectOf(_deckKey) ??
        Rect.fromCenter(
          center: Offset(
            MediaQuery.sizeOf(context).width * 0.12,
            MediaQuery.sizeOf(context).height * 0.42,
          ),
          width: _tableCardSize.width,
          height: _tableCardSize.height,
        );
    if (jitter == 0) return base;
    return Rect.fromCenter(
      center: base.center.translate(jitter, jitter),
      width: _tableCardSize.width,
      height: _tableCardSize.height,
    );
  }

  /// Свежая партия: руки полные, стол пуст, колода после раздачи — крутим FX.
  bool _shouldAnimateOpeningDeal(DurakGameView view, int myHandLen) {
    if (view.isOver || view.table.isNotEmpty || view.bitoCount > 0) {
      return false;
    }
    if (view.myIndex < 0 || myHandLen <= 0) return false;
    final n = view.hands.length;
    if (n < 2) return false;
    const handSize = 6;
    if (myHandLen != handSize) return false;
    for (var i = 0; i < n; i++) {
      if (view.hands[i].count != handSize) return false;
    }
    final expectedDeck = view.deckSize - n * handSize;
    return view.deckCount == expectedDeck && expectedDeck >= 0;
  }

  void _scheduleOpeningDeal(DurakGameView view, List<PlayingCard> myHand) {
    if (_fxScheduled) return;
    _fxScheduled = true;
    final n = view.hands.length;
    const handSize = 6;
    setState(() {
      _busy = true;
      _fanAnimDuringBusy = true;
      _suppressFanLayoutAnim = true;
      _handOrder = <PlayingCard>[];
      _pendingDealCards
        ..clear()
        ..addAll(myHand);
      _oppDealPending.clear();
      for (var i = 0; i < n; i++) {
        if (i != view.myIndex) _oppDealPending[i] = handSize;
      }
      _deckCountFreeze = view.deckSize;
      _trumpFaceVisible = false;
      // База — финальное состояние сервера, чтобы не перезапустить FX.
      _prevDeckCount = view.deckCount;
      _prevBitoCount = view.bitoCount;
      _prevHandLen = myHand.length;
      _prevTable = List.of(view.table);
      _prevAttackerIndex = view.attackerIndex;
      _prevDefenderIndex = view.defenderIndex;
      _syncPrevOppHandCounts(view);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _fxScheduled = false;
        return;
      }
      try {
        await _animateOpeningDeal(view, myHand);
      } finally {
        if (mounted) {
          setState(() {
            _busy = false;
            _fanAnimDuringBusy = false;
            _suppressFanLayoutAnim = false;
            _trumpFaceVisible = true;
            _pendingDealCards.clear();
            _oppDealPending.clear();
            _deckCountFreeze = null;
            if (_handOrder == null || _handOrder!.isEmpty) {
              _handOrder = List<PlayingCard>.of(myHand);
            }
          });
        }
        _fxScheduled = false;
      }
    });
  }

  /// Раздача по одной: с соперника по часовой, затем козырь под колоду.
  Future<void> _animateOpeningDeal(
    DurakGameView view,
    List<PlayingCard> myHand,
  ) async {
    if (!mounted || !_gameUiActive) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final n = view.hands.length;
    const handSize = 6;
    // По часовой начиная с соперника слева от меня (myIndex+1).
    final seatOrder = List<int>.generate(n, (i) => (view.myIndex + 1 + i) % n);
    final myCards = List<PlayingCard>.of(myHand);
    var myIdx = 0;

    // Стартовая раздача — в ~2× быстрее обычного добора.
    const fly = Duration(milliseconds: 160);
    const settle = 90;
    const gap = Duration(milliseconds: 14);

    for (var round = 0; round < handSize; round++) {
      for (final seat in seatOrder) {
        if (!mounted || !_gameUiActive) return;
        if (seat == view.myIndex) {
          if (myIdx >= myCards.length) continue;
          await _animateDealCardsToFan(
            [myCards[myIdx]],
            flyDuration: fly,
            settleMs: settle,
          );
          myIdx++;
        } else {
          await _animateDealToOpponent(seat, 1, flyDuration: fly);
        }
        if (!mounted) return;
        await Future<void>.delayed(gap);
      }
    }

    if (!mounted || !_gameUiActive) return;
    await _animateTrumpReveal(view);
  }

  /// Вытащить козырь из колоды и положить под стопку (поворот лицом).
  Future<void> _animateTrumpReveal(DurakGameView view) async {
    if (!mounted || !_gameUiActive) return;
    final trump = view.trumpCard.toPlayingCard();
    final from = _deckDealFromRect();
    // Куда ляжет в DurakDeckPile: чуть правее стопки, горизонтально.
    final to = Rect.fromCenter(
      center: Offset(
        from.left + _tableCardSize.width * 0.72,
        from.center.dy,
      ),
      width: _tableCardSize.width,
      height: _tableCardSize.height,
    );
    final ticket = await playCardFlyAnimation(
      context: context,
      card: trump,
      cardSize: _tableCardSize,
      from: from,
      to: to,
      duration: const Duration(milliseconds: 210),
      curve: Curves.easeOutCubic,
      faceDown: true,
      flipToFace: true,
      beginScale: 1,
      endScale: 1,
      beginAngle: 0.05,
      endAngle: -math.pi / 2,
      arcLift: 28,
      keepAtEnd: true,
    );
    if (!mounted) {
      ticket.dismiss();
      return;
    }
    setState(() => _trumpFaceVisible = true);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    ticket.dismiss();
  }

  /// Добор всех игроков в порядке атаки (не «сначала я»).
  Future<void> _animateRefillDeals({
    required DurakGameView view,
    required List<PlayingCard> myIncoming,
    required Map<int, int> oppDeals,
    required int refillAttacker,
    required int refillDefender,
    bool skipMyDeal = false,
    int? deckCountBefore,
  }) async {
    final myCards = skipMyDeal ? const <PlayingCard>[] : myIncoming;
    if ((myCards.isEmpty && oppDeals.isEmpty) || !mounted || !_gameUiActive) {
      return;
    }

    final totalDeal = myCards.length +
        oppDeals.values.fold<int>(0, (a, b) => a + b);
    setState(() {
      if (myCards.isNotEmpty) _pendingDealCards.addAll(myCards);
      for (final e in oppDeals.entries) {
        _oppDealPending[e.key] = (_oppDealPending[e.key] ?? 0) + e.value;
      }
      // Козырь/колода остаются видимыми, пока карты не улетят.
      if (totalDeal > 0 && deckCountBefore != null) {
        _armDeckFreeze(deckCountBefore);
      }
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final order = _refillDealOrder(
      attacker: refillAttacker,
      defender: refillDefender,
      playerCount: view.hands.length,
    );
    for (final idx in order) {
      if (!mounted || !_gameUiActive) return;
      if (idx == view.myIndex) {
        if (myCards.isNotEmpty) {
          await _animateDealCardsToFan(myCards);
        }
      } else {
        final n = oppDeals[idx] ?? 0;
        if (n > 0) {
          await _animateDealToOpponent(idx, n);
        }
      }
    }
    if (mounted) {
      _pendingDealCards.removeAll(myCards);
      _clearDeckCountFreeze();
    }
  }

  /// Стол → веер соперника (когда он «взял»).
  Future<void> _animateTableToOpponentFan(
    List<DurakTablePairApi> table,
    int oppIdx,
  ) async {
    if (table.isEmpty || !mounted || !_gameUiActive) return;
    final cards = _flattenTableCardsTopFirst(table);
    final froms = _tableCardGlobalRectsTopFirst(table);
    final screen = MediaQuery.sizeOf(context);

    for (var i = 0; i < cards.length; i++) {
      if (!mounted || !_gameUiActive) return;
      final card = cards[i];
      setState(() => _leftTableCards.add(card));
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      final from = i < froms.length
          ? froms[i]
          : Rect.fromCenter(
              center: screen.center(Offset.zero),
              width: _tableCardSize.width,
              height: _tableCardSize.height,
            );
      final toKey = _oppFanKeys.putIfAbsent(oppIdx, GlobalKey.new);
      final to = globalRectOf(toKey) ??
          Rect.fromCenter(
            center: Offset(screen.width / 2, screen.height * 0.16),
            width: _tableCardSize.width * 0.44,
            height: _tableCardSize.height * 0.44,
          );
      final endSize = Size(
        to.width.clamp(30.0, _tableCardSize.width * 0.55),
        to.height.clamp(44.0, _tableCardSize.height * 0.55),
      );
      final land = Rect.fromCenter(
        center: to.center.translate(i * 2.0, i * 1.2),
        width: endSize.width,
        height: endSize.height,
      );
      final ticket = await playCardFlyAnimation(
        context: context,
        card: card,
        cardSize: _tableCardSize,
        from: from,
        to: land,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        faceDown: false,
        flipToFace: false,
        beginScale: 1,
        endScale: endSize.width / _tableCardSize.width,
        beginAngle: 0,
        endAngle: 0.1,
        arcLift: 22,
        keepAtEnd: true,
      );
      ticket.dismiss();
      if (!mounted) return;
      setState(() {
        final left = (_oppDealPending[oppIdx] ?? 1) - 1;
        if (left <= 0) {
          _oppDealPending.remove(oppIdx);
        } else {
          _oppDealPending[oppIdx] = left;
        }
      });
      if (i + 1 < cards.length) {
        await Future<void>.delayed(const Duration(milliseconds: 32));
      }
    }
  }

  /// Рубашки по одной: колода → веер одного соперника ([_oppDealPending] уже учтён).
  Future<void> _animateDealToOpponent(
    int idx,
    int n, {
    Duration flyDuration = const Duration(milliseconds: 300),
    Duration stagger = const Duration(milliseconds: 32),
  }) async {
    if (n <= 0 || !mounted || !_gameUiActive) return;
    const dummy = PlayingCard(Rank.six, Suit.spades);
    final screen = MediaQuery.sizeOf(context);

    for (var i = 0; i < n; i++) {
      if (!mounted || !_gameUiActive) return;
      // Точка старта — пока колода/козырь ещё на экране (freeze).
      final from = _deckDealFromRect(jitter: i * 1.2);
      _consumeDeckFreezeSlot();
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      final toKey = _oppFanKeys.putIfAbsent(idx, GlobalKey.new);
      final to = globalRectOf(toKey) ??
          Rect.fromCenter(
            center: Offset(screen.width / 2, screen.height * 0.16),
            width: _tableCardSize.width * 0.44,
            height: _tableCardSize.height * 0.44,
          );
      final endSize = Size(
        (to.width).clamp(30.0, _tableCardSize.width * 0.55),
        (to.height).clamp(44.0, _tableCardSize.height * 0.55),
      );
      final land = Rect.fromCenter(
        center: to.center.translate(i * 2.0, i * 1.5),
        width: endSize.width,
        height: endSize.height,
      );
      final ticket = await playCardFlyAnimation(
        context: context,
        card: dummy,
        cardSize: _tableCardSize,
        from: from,
        to: land,
        duration: flyDuration,
        curve: Curves.easeOutCubic,
        faceDown: true,
        flipToFace: false,
        beginScale: 1,
        endScale: endSize.width / _tableCardSize.width,
        beginAngle: 0.12,
        endAngle: 0.08,
        arcLift: 18,
        keepAtEnd: true,
      );
      ticket.dismiss();
      if (!mounted) return;
      setState(() {
        final left = (_oppDealPending[idx] ?? 1) - 1;
        if (left <= 0) {
          _oppDealPending.remove(idx);
        } else {
          _oppDealPending[idx] = left;
        }
      });
      if (i + 1 < n) {
        await Future<void>.delayed(stagger);
      }
    }
  }

  /// Синхронизировать prev после своего хода. Если раунд закрылся (бита/взятие) —
  /// prev не трогаем: [_maybeRunTableFx] должен сыграть биту и добор из колоды.
  void _syncPrevAfterMove(DurakGameView v) {
    final roundEnded = _prevTable.isNotEmpty &&
        v.table.isEmpty &&
        ((_prevBitoCount >= 0 && v.bitoCount > _prevBitoCount) ||
            (_prevDeckCount >= 0 && v.deckCount < _prevDeckCount));
    if (roundEnded) return;
    _prevTable = List.of(v.table);
    _prevDeckCount = v.deckCount;
    _prevBitoCount = v.bitoCount;
    _prevHandLen = v.hands.length > v.myIndex && v.myIndex >= 0
        ? (v.hands[v.myIndex].cards?.length ?? v.hands[v.myIndex].count)
        : _prevHandLen;
  }

  /// Карты для анимации добора: строго не больше [dealt] (дельта длины руки).
  /// Остальные карты сразу остаются в [_handOrder], чтобы веер не опустел
  /// и с колоды не летела вся рука.
  List<PlayingCard> _incomingDealCards(List<PlayingCard> hand, int dealt) {
    final expect = dealt > 0 ? dealt : 0;
    if (hand.isEmpty) return const [];
    if (expect <= 0) {
      if (_handOrder == null || _handOrder!.isEmpty) {
        _handOrder = List<PlayingCard>.of(hand);
      }
      return const [];
    }
    // Добор «всей руки» при пустом/нулевом prev — это первый синк, не анимация.
    if (expect >= hand.length &&
        (_handOrder == null ||
            _handOrder!.isEmpty ||
            _prevHandLen <= 0)) {
      _handOrder = List<PlayingCard>.of(hand);
      return const [];
    }
    return _splitHandForDeal(hand, expect);
  }

  /// Разделить руку на «уже в веере» и «добрать из колоды» (ровно [expect]).
  List<PlayingCard> _splitHandForDeal(List<PlayingCard> hand, int expect) {
    final n = expect.clamp(0, hand.length);
    if (n <= 0) {
      if (_handOrder == null || _handOrder!.isEmpty) {
        _handOrder = List<PlayingCard>.of(hand);
      }
      return const [];
    }
    final keepCount = hand.length - n;
    final prevSet = _handOrder?.toSet() ?? {};
    final keep = <PlayingCard>[];
    final rest = <PlayingCard>[];
    for (final c in hand) {
      if (prevSet.contains(c) && keep.length < keepCount) {
        keep.add(c);
      } else {
        rest.add(c);
      }
    }
    // Не хватает «старых» в order (пустой/устаревший) — оставляем в веере
    // keepCount карт, с колоды анимируем только n.
    while (keep.length < keepCount && rest.isNotEmpty) {
      keep.add(rest.removeAt(0));
    }
    final incoming =
        rest.length > n ? rest.sublist(rest.length - n) : List.of(rest);
    // Лишнее из rest (если вдруг) — тоже в веер, не на анимацию.
    for (final c in rest) {
      if (!incoming.contains(c) && !keep.contains(c)) keep.add(c);
    }
    _handOrder = keep;
    return incoming;
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

    // Скрыть сразу в этом же build — до отрисовки стола (без вспышки карты).
    for (final f in flights) {
      _remoteFlyingCardIds.add(_cardId(f.card));
    }

    _fxScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_gameUiActive) {
        for (final f in flights) {
          _remoteFlyingCardIds.remove(_cardId(f.card));
        }
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
    // Id уже добавлен в _scheduleRemoteTableFx — только убедимся.
    if (!_remoteFlyingCardIds.contains(id)) {
      setState(() => _remoteFlyingCardIds.add(id));
    }

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
    final col = flight.pairIndex % _tableCols;
    final row = flight.pairIndex ~/ _tableCols;
    final pairCenter = Offset(
      tableCenter.dx + (col - (_tableCols - 1) / 2) * pairW * 0.85,
      tableCenter.dy + (row - 0.3) * (_tableCardSize.height * 0.62),
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
    final landAngle = flight.isDefense ? _kDefendLandAngle : 0.0;
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
      duration: const Duration(milliseconds: 340),
      stagger: Duration.zero,
      curve: Curves.easeOutCubic,
      beginScale: 1.0,
      endScale: _tableCardSize.width / small.width,
      beginAngles: const [0.22],
      endAngles: [landAngle],
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

  /// Флажок «сдаться» — остаёмся на экране итога (как в крестиках).
  Future<void> _confirmSurrender() async {
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    if (view == null || view.isOver) return;
    final ok = await confirmGameActionDialog(
      context: context,
      title: context.l10n.gameSurrenderTitle,
      message: context.l10n.gameSurrenderConfirm,
      cancelLabel: context.l10n.gameStay,
      confirmLabel: context.l10n.gameSurrender,
    );
    if (!ok || !mounted) return;
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

  /// Крестик / свайп — общая логика с крестиками-ноликами: диалог → сдача → /games.
  Future<void> _onClosePressed() async {
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    await handleGameScreenClose(
      context: context,
      isActive: view != null && !view.isOver,
      onLeaveFinished: () async {
        if (!mounted) return;
        _navigateToGames();
      },
      onForfeitAndLeave: () async {
        if (!mounted) return;
        try {
          clearBlockingGamePin(ref, ifGameId: widget.gameId);
          await ref.read(durakRepositoryProvider).forfeit(widget.gameId);
        } catch (_) {}
        if (!mounted) return;
        _navigateToGames();
        unawaited(ref.read(activeGameProvider.notifier).refresh());
      },
    );
  }

  void _clearSessionForFinishedGame() {
    clearBlockingGamePin(ref, ifGameId: widget.gameId);
    final prev = ref.read(activeGameProvider).valueOrNull;
    if (prev?.gameId == widget.gameId) {
      ref.read(activeGameProvider.notifier).clearLocal();
    }
  }

  void _navigateToGames() {
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
      // Как в крестиках: банк stake×N, делится между победителями.
      final netProfit = view.isDraw
          ? 0
          : (iWon
              ? stakeWinnerNetProfit(
                  stake: view.stakeBronze,
                  playerCount: playersN,
                  winnerCount: winnersN,
                )
              : 0);
      final credit = view.isDraw
          ? view.stakeBronze
          : (iWon
              ? stakeWinnerCredit(
                  stake: view.stakeBronze,
                  playerCount: playersN,
                  winnerCount: winnersN,
                )
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
    final groupChatId = (view?.chatId ?? '').trim();
    final showGroupChat = isMulti && groupChatId.isNotEmpty;
    // Мой ход — часики в рамке; ход соперника — рамка на аватаре.
    // Нижняя зона (веер) исключена — свайп по картам не вызывает выход.
    final swipeBottomExclude = MediaQuery.sizeOf(context).height * 0.42;
    final groupUnread = () {
      if (!showGroupChat) return 0;
      final chats = ref.watch(chatsListProvider).valueOrNull;
      if (chats == null) return 0;
      for (final c in chats) {
        if (c.chatID == groupChatId) return c.unreadCount;
      }
      return 0;
    }();
    return SwipeBackScope(
        onBack: _onClosePressed,
        opaqueEdge: false,
        edgeWidth: 16,
        triggerDistance: 44,
        bottomInset: swipeBottomExclude,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            toolbarHeight: showGroupChat ? 96 : kToolbarHeight,
            leadingWidth: 48,
            centerTitle: true,
            titleSpacing: 0,
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _busy ? null : _onClosePressed,
                ),
                if (showGroupChat && view != null)
                  GameIconWithBadge(
                    icon: Icons.forum_rounded,
                    badge: groupUnread,
                    tooltip: 'Чат группы',
                    onPressed: () => _openGroupChat(view),
                  ),
              ],
            ),
            title: const Text('Дурак'),
            actions: view == null
                ? const []
                : buildGameAppBarActions(
                    context: context,
                    onSurrender:
                        showSurrender && isMulti ? _confirmSurrender : null,
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
                    onSurrender: _confirmSurrender,
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
    // Непрерывный tuck (без ступеней 3/6/9) — иначе рывок при смене числа карт.
    // seatLift < 0 — чуть уводим под низ зоны.
    final seatT = nFan <= 1 ? 0.0 : ((nFan - 1) / 11).clamp(0.0, 1.0);
    final seatLift = -fanCardH * (0.33 * (1 - seatT) + 0.06 * seatT);
    // CardFan ≈ 1.7h + peek; зона без искусственного подъёма.
    final fanZoneH = fanCardH * 2.05 + 16;
    // Кнопка чуть выше видимых карт веера.
    final actionBtnBottom = -seatLift + fanCardH + 10;

    final showTimer = !view.isOver &&
        view.isMyTurn &&
        view.turnTimeSec > 0 &&
        view.turnDeadline > 0;
    final showTake = _canTake(view);
    final showBito = _canBito(view);
    final showDone = _canDone(view);
    final showPass = _canPass(view);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              // 1×1: карточка соперника; 3–4: аватарки по местам + веера под ними.
              SizedBox(
                width: double.infinity,
                child: view.playerIds.length == 2
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _opponentsHeader(view),
                          for (final oi in opponents)
                            _opponentFan(view, oi, tableSize),
                        ],
                      )
                    : _multiOpponentsArea(view, tableSize),
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
              // Высота зоны, tuck и размер карт — плавно, без рывка экрана.
              TweenAnimationBuilder<double>(
                tween: Tween(end: fanZoneH),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                builder: (context, zoneH, _) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(end: seatLift),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    builder: (context, animLift, _) {
                      return SizedBox(
                        height: zoneH,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 2,
                              right: 2,
                              bottom: animLift,
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
                                  final aspect = cardSize.width > 0
                                      ? cardSize.height / cardSize.width
                                      : 1.4;
                                  return Align(
                                    alignment: fillWidth
                                        ? Alignment.bottomLeft
                                        : Alignment.bottomCenter,
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(end: cardSize.width),
                                      duration: const Duration(
                                        milliseconds: 320,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, animW, _) {
                                        return TweenAnimationBuilder<double>(
                                          tween: Tween(end: spacing),
                                          duration: const Duration(
                                            milliseconds: 320,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          builder: (context, animSp, _) {
                                            final animH = animW * aspect;
                                            return CardFan(
                                              key: _fanKey,
                                              cards: handForFan,
                                              cardSize: Size(animW, animH),
                                              spacing: animSp,
                                              fillWidth: fillWidth,
                                              animateLayout:
                                                  animateFanLayout,
                                          legalCards: (!view.canAct ||
                                                  legal.isEmpty)
                                              ? const <PlayingCard>{}
                                              : legal,
                                          emphasizeLegal: true,
                                          selectedCards: _selected,
                                          hiddenCards: _flyingFromHand,
                                          enabled: !view.isOver &&
                                              !_busy &&
                                              view.canAct,
                                          onActiveChanged: (card) {
                                            if (_activeCard == card) {
                                              return;
                                            }
                                            setState(() {
                                              _activeCard = card;
                                              if (card == null) {
                                                _dragGlobal = null;
                                              }
                                            });
                                          },
                                          onHoldingChanged: (holding) {
                                            if (_holdingFanCard ==
                                                holding) {
                                              return;
                                            }
                                            setState(() =>
                                                _holdingFanCard = holding);
                                          },
                                          onDragPosition: (p) {
                                            if (p == null) {
                                              if (_dragGlobal == null) {
                                                return;
                                              }
                                              setState(() =>
                                                  _dragGlobal = null);
                                              return;
                                            }
                                            final prev = _dragGlobal;
                                            if (prev != null &&
                                                (prev - p)
                                                        .distanceSquared <
                                                    4) {
                                              _dragGlobal = p;
                                              return;
                                            }
                                            setState(
                                                () => _dragGlobal = p);
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
                                          onReturnToFan:
                                              _onCardReturnedToFan,
                                          onDrop: (card, global, from) =>
                                              _onCardDrop(
                                            view,
                                            card,
                                            global,
                                            from,
                                          ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          // Кнопка чуть выше веера; позиция плавно следует за размером карт.
          TweenAnimationBuilder<double>(
            tween: Tween(end: actionBtnBottom),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            builder: (context, btnBottom, _) {
              return Positioned(
                left: 0,
                right: 0,
                bottom: btnBottom,
                child: SizedBox(
                  height: 52,
                  child: Center(
                    child: (showTake ||
                                showBito ||
                                showDone ||
                                showPass) &&
                            !_holdingFanCard &&
                            !_cardFlightActive
                        ? _PulsingActionButton(
                            label: showTake
                                ? 'Взять'
                                : showPass
                                    ? 'Пас'
                                    : (showDone ? 'Готово' : 'Бито'),
                            icon: showTake
                                ? Icons.south_rounded
                                : showPass
                                    ? Icons.skip_next_rounded
                                    : Icons.check_rounded,
                            onPressed: showTake
                                ? _take
                                : showPass
                                    ? _pass
                                    : (showDone ? _confirmTakeDone : _bito),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMyTurnTimerChip(DurakGameView view) {
    final chip = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceUnified.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: SizedBox(
          width: 70,
          height: 28,
          child: Center(
            child: GameTurnCountdown(
              key: ValueKey('turn-clock-${view.turnDeadline}'),
              turnDeadline: view.turnDeadline,
              turnTimeSec: view.turnTimeSec,
              isMyTurn: view.isMyTurn,
              onExpired: _onTurnTimeExpired,
              labelBuilder: (s) => context.l10n.gameSecondsLeft(s),
            ),
          ),
        ),
      ),
    );
    // Как рамка соперника в 1×1 — таймер своего хода в shrinking border.
    return TurnTimerBorder(
      key: ValueKey('my-timer-border-${view.turnDeadline}'),
      active: view.isMyTurn && view.turnTimeSec > 0 && view.turnDeadline > 0,
      turnDeadline: view.turnDeadline,
      turnTimeSec: view.turnTimeSec,
      borderWidth: 2.5,
      radius: 18,
      onExpired: _onTurnTimeExpired,
      child: chip,
    );
  }

  /// Индексы соперников по часовой от меня: сначала справа, затем дальше, слева последним.
  List<int> _opponentSeatOrder(DurakGameView view) {
    final n = view.playerIds.length;
    if (n < 3 || view.myIndex < 0) return const [];
    return [
      for (var i = 1; i < n; i++) (view.myIndex + i) % n,
    ];
  }

  /// 3–4 игрока: аватарки + веера (слева / сверху / справа).
  Widget _multiOpponentsArea(DurakGameView view, Size tableSize) {
    final seats = _opponentSeatOrder(view);
    if (seats.isEmpty) return const SizedBox.shrink();
    Widget seat(int idx) => _opponentSeat(view, idx, tableSize);
    if (seats.length == 2) {
      // Я снизу: seats[0]=справа, seats[1]=слева.
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: seat(seats[1])),
            Expanded(child: seat(seats[0])),
          ],
        ),
      );
    }
    // 4 игрока: top / left / right.
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          seat(seats[1]),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: seat(seats[2])),
              Expanded(child: seat(seats[0])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _opponentSeat(DurakGameView view, int idx, Size tableSize) {
    if (idx < 0 || idx >= view.playerIds.length) {
      return const SizedBox.shrink();
    }
    final oppId = view.playerIds[idx];
    final isBot = oppId.startsWith('bot:');
    final meta = view.playerMeta(oppId);
    final finished = view.finished.contains(idx);
    final theirTurn = !view.isOver &&
        !finished &&
        view.turnActorIdx == idx &&
        view.turnTimeSec > 0 &&
        view.turnDeadline > 0;

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
        if (chats != null) {
          for (final c in chats) {
            if (c.user.id == oppId) {
              final dn = c.user.displayName?.trim();
              if ((name == context.l10n.gameOpponent || name.isEmpty) &&
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
            }
          }
        }

        final chip = TurnTimerBorder(
          key: ValueKey('seat-timer-$idx-${view.turnDeadline}'),
          active: theirTurn,
          turnDeadline: view.turnDeadline,
          turnTimeSec: view.turnTimeSec,
          borderWidth: 2.5,
          radius: 18,
          onExpired: _onTurnTimeExpired,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isBot
                  ? null
                  : () => unawaited(showUserProfileDialog(
                        context: context,
                        ref: ref,
                        userId: oppId,
                        displayName: name,
                        avatarKind: avatarKind,
                        avatarValue: avatarValue,
                        frameCode: frameCode,
                        frameColor: frameColor,
                        messageFrom: 'games',
                        messageReturnPath:
                            '/games/durak/game/${widget.gameId}',
                      )),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: finished ? 0.45 : 1,
                      child: GamePlayerAvatar(
                        displayName: name,
                        avatarKind: avatarKind,
                        avatarValue: avatarValue,
                        frameCode: frameCode,
                        frameColor: frameColor,
                        compact: true,
                      ),
                    ),
                    const SizedBox(height: 2),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 96),
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          decoration:
                              finished ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            chip,
            if (!finished) _opponentFan(view, idx, tableSize),
          ],
        );
      },
    );
  }

  void _openGroupChat(DurakGameView view) {
    final chatId = (view.chatId ?? '').trim();
    if (chatId.isEmpty) return;
    final uri = Uri(
      path: '/chats/$chatId',
      queryParameters: {
        'from': 'games',
        'game': '/games/durak/game/${widget.gameId}',
      },
    );
    context.push(uri.toString());
  }

  /// Шапка с соперником (1×1). Consumer — чаты/друзья не пересобирают стол/биту/веер.
  Widget _opponentsHeader(DurakGameView view) {
    if (view.playerIds.length != 2 || view.myIndex < 0) {
      return const SizedBox.shrink();
    }
    final oppIndex = view.myIndex == 0 ? 1 : 0;
    if (view.playerIds.length <= oppIndex) return const SizedBox.shrink();
    final oppId = view.playerIds[oppIndex];
    final oppTurn = !view.isOver &&
        (view.turnActorIdx >= 0
            ? view.turnActorIdx == oppIndex
            : !view.isMyTurn);
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
  /// Ширина веера не больше трети экрана; при росте руки сжимаем плитки/шаг.
  Widget _opponentFan(DurakGameView view, int idx, Size cardSize) {
    final serverCount = view.hands.length > idx ? view.hands[idx].count : 0;
    final pending = _oppDealPending[idx] ?? 0;
    // Пока карта летит из колоды — в веере ещё не показываем.
    final count = math.max(0, serverCount - pending);
    if (count <= 0 && pending <= 0) return const SizedBox.shrink();
    final maxW = MediaQuery.sizeOf(context).width / 3;
    // Показываем до 20 плиток; дальше — ещё плотнее.
    // pending>0 и count==0 — пустая зона-цель для посадки добора.
    final shown = count <= 0 ? 1 : (count > 20 ? 20 : count);
    final placeholderOnly = count <= 0;
    var tileScale = 0.44;
    if (shown > 16) {
      tileScale = 0.30;
    } else if (shown > 12) {
      tileScale = 0.34;
    } else if (shown > 9) {
      tileScale = 0.38;
    } else if (shown > 6) {
      tileScale = 0.41;
    }
    var tile = Size(
      (cardSize.width * tileScale).clamp(22.0, 52.0),
      (cardSize.height * tileScale).clamp(32.0, 76.0),
    );
    // Минимальный шаг (читаемая кромка); шире ⅓ экрана — сжимаем, не растягиваем.
    double minStepFrac() {
      if (shown > 16) return 0.18;
      if (shown > 12) return 0.22;
      if (shown > 9) return 0.28;
      if (shown > 6) return 0.36;
      if (shown > 4) return 0.46;
      return 0.58;
    }

    var step = tile.width * minStepFrac();
    var totalW = tile.width + step * math.max(shown - 1, 0);
    if (shown > 1 && totalW > maxW) {
      for (var i = 0; i < 24 && totalW > maxW && tile.width > 14; i++) {
        final s = (maxW / totalW).clamp(0.40, 0.96);
        tile = Size(tile.width * s, tile.height * s);
        step = tile.width * minStepFrac();
        totalW = tile.width + step * (shown - 1);
      }
      if (totalW > maxW) {
        step = ((maxW - tile.width) / (shown - 1)).clamp(4.0, step);
        totalW = tile.width + step * (shown - 1);
      }
    }
    // Плотная рука — более плоская дуга, без «подъёма» середины.
    final arcH = tile.height * (shown > 12
        ? 0.10
        : shown > 8
            ? 0.16
            : shown > 4
                ? 0.22
                : 0.28);
    final fanH = tile.height + arcH + 6;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: KeyedSubtree(
        key: _oppFanKeys.putIfAbsent(idx, GlobalKey.new),
        child: Center(
          child: SizedBox(
            key: ValueKey('opp-$idx-$count-$pending'),
            width: totalW,
            height: fanH,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                if (!placeholderOnly)
                  for (var i = 0; i < shown; i++)
                    Builder(
                      builder: (_) {
                        final t = shown <= 1
                            ? 0.0
                            : (i / (shown - 1)) * 2 - 1; // -1..1
                        // Середина ниже (к столу), края выше — читаемая дуга.
                        final y = (1 - t * t) * arcH;
                        final angleMax = shown > 12
                            ? 0.12
                            : shown > 8
                                ? 0.16
                                : 0.22;
                        final angle = t * angleMax;
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
    // Подсказки при подъёме: все бьющиеся атаки + слот перевода в сетке.
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
    // При подъёме светим все цели, которые карта бьёт (не только ближайшую).
    final Set<int> defendTargets;
    if (_flightLockTable && _flightDefendIdx != null) {
      defendTargets = {_flightDefendIdx!};
    } else if (lifting && focus != null) {
      defendTargets = _defendTargetIndexes(view, focus);
    } else {
      defendTargets = const <int>{};
    }
    final pendingAttacks = _pendingAttackPlaceholders(view);
    // Слот-подсказка только при подъёме; в сетке стола — следующая ячейка.
    final canShowAttackSlot = !view.isOver &&
        view.attackerIndex == view.myIndex &&
        (view.phase == 'attack' ||
            view.phase == 'attack_follow' ||
            view.phase == 'defend' ||
            view.phase == 'take_follow') &&
        !_busy &&
        !_flightLockTable &&
        pendingAttacks.isEmpty;
    // Перевод: слот в следующей ячейке (1→ряд1/место2, 2→ряд2/место1, 3→ряд2/место2).
    final showTransferSlot = lifting &&
        !_busy &&
        !_flightLockTable &&
        pendingAttacks.isEmpty &&
        _highlightTransferSlot(view);
    final showTableDropSlot =
        (canShowAttackSlot && highlightAttack) || showTransferSlot;

    // Колода слева — чуть в кадре, не под боковой панелью.
    // Freeze: козырь не исчезает, пока доборные карты не улетели.
    final deckPeek = KeyedSubtree(
      key: _deckKey,
      child: DurakDeckPile(
        deckCount: _deckCountFreeze ?? view.deckCount,
        trumpCard: trumpCard,
        trumpSuit: _suitFromApi(view.trumpSuit),
        cardSize: cardSize,
        showTrumpFace: _trumpFaceVisible,
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

    // При «Взять» рисуем снимок стола — сервер уже пустой, карты улетают по одной.
    final hold = _takeTableHold;
    final sourceTable = hold ?? view.table;
    final tableItems = <Widget>[
      if (!_hidingTable) ...[
        for (var i = 0; i < sourceTable.length; i++)
          if (_shouldShowTakeHoldPair(sourceTable[i], i, usingHold: hold != null))
            Opacity(
              key: ValueKey(
                'atk-${_cardId(sourceTable[i].attack.toPlayingCard())}',
              ),
              opacity: (_flyingToTable.contains(
                        sourceTable[i].attack.toPlayingCard(),
                      ) ||
                      (hold == null &&
                          _isRemoteAttackHidden(sourceTable[i], i)))
                  ? 0.0
                  : 1.0,
              child: _AnimatedTablePair(
                pair: _tablePairForTakeHold(sourceTable[i], i, usingHold: hold != null),
                cardSize: cardSize,
                highlightAttack:
                    hold == null && defendTargets.contains(i),
                attackKey: _tableAttackKeys.putIfAbsent(i, GlobalKey.new),
                defendTargetKey: hold == null && i == defendPairIndex
                    ? _defendTargetKey
                    : null,
                optimisticDefense:
                    hold == null ? _visibleOptimisticDefense(i) : null,
              ),
            ),
        if (hold == null)
          for (var i = 0; i < pendingAttacks.length; i++)
            Opacity(
              key: ValueKey('atk-${_cardId(pendingAttacks[i])}'),
              opacity: _flyingToTable.contains(pendingAttacks[i]) ? 0 : 1,
              child: _AnimatedTablePair(
                pair: DurakTablePairApi(
                  attack: DurakApiCard.fromCard(pendingAttacks[i]),
                ),
                cardSize: cardSize,
                attackKey: i == pendingAttacks.length - 1
                    ? _pendingAttackLandKey
                    : null,
              ),
            ),
        // Слот атаки/перевода — ячейка сетки; topLeft как у атаки в _AnimatedTablePair
        // (не Center — иначе слот ниже карты на ~10px из‑за запаса высоты +20).
        if (hold == null && showTableDropSlot)
          KeyedSubtree(
            key: _attackSlotKey,
            child: SizedBox(
              width: cardSize.width + 18,
              height: cardSize.height + 20,
              child: Align(
                alignment: Alignment.topLeft,
                child: IgnorePointer(
                  child: DurakDropSlot(
                    size: cardSize,
                    active: true,
                  ),
                ),
              ),
            ),
          ),
      ],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Реальная ширина колоды (козырь + стопка) и биты+таймер — стол строго между ними.
        final deckW =
            cardSize.width * 0.55 + cardSize.height * 0.82;
        final leftReserve = deckW + 14;
        final rightReserve = math.max(90.0, cardSize.width * 0.70) + 12;
        final tableMaxW =
            (constraints.maxWidth - leftReserve - rightReserve)
                .clamp(100.0, constraints.maxWidth);
        // Якоря Positioned — Align не двигает колоду/биту при смене хода.
        final deckTop = constraints.maxHeight * 0.28;
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
            // Стол только в коридоре между колодой и битой — без наездов.
            Positioned(
              left: leftReserve,
              right: rightReserve,
              top: 0,
              bottom: 0,
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
            // Колода слева; таймер своего хода — над колодой с козырем.
            // Слот таймера всегда зарезервирован — колода не прыгает при смене хода.
            Positioned(
              left: 2,
              top: (deckTop - 40).clamp(0.0, deckTop),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 34,
                    child: IgnorePointer(
                      ignoring: !showTimer,
                      child: Opacity(
                        opacity: showTimer ? 1 : 0,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _buildMyTurnTimerChip(view),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  deckPeek,
                ],
              ),
            ),
            // Бита справа, на уровне колоды.
            Positioned(
              right: 2,
              top: deckTop,
              child: RepaintBoundary(child: bitoPeek),
            ),
          ],
        );
      },
    );
  }

  /// Высота слота пары на столе (как в [_AnimatedTablePair]).
  double _tablePairHeight(Size cardSize) => cardSize.height + 20;

  /// Обычный вертикальный шаг между рядами (без наезда).
  double _tableNormalRowStep(Size cardSize) => _tablePairHeight(cardSize) + 10;

  /// При 3+ рядах: 2-й ряд слегка наезжает на 1-й (виден ранг+масть);
  /// 3-й и дальше — обычный зазор, без наложения на предыдущий.
  double _tableCompactPeek(Size cardSize) => cardSize.height * 0.40;

  /// Y-координата верха ряда [row] (0-based) при [rowCount] рядах.
  double _tableRowTop(Size cardSize, int row, int rowCount) {
    if (row <= 0) return 0;
    final normal = _tableNormalRowStep(cardSize);
    if (rowCount < 3) return row * normal;
    // Ряд 1 (второй): чуть ниже, чтобы читалась масть у первого ряда.
    if (row == 1) return _tableCompactPeek(cardSize);
    // Ряд 2+ (третий…): как обычно относительно предыдущего полного ряда.
    return _tableCompactPeek(cardSize) + (row - 1) * normal;
  }

  double _tableStackHeight(Size cardSize, int rowCount) {
    if (rowCount <= 0) return 0;
    return _tableRowTop(cardSize, rowCount - 1, rowCount) +
        _tablePairHeight(cardSize);
  }

  /// До 2 пар в ряд; если не влезает — пары наезжают друг на друга.
  /// При 3+ рядах — передние ряды наезжают на задние: виден только угол карты.
  Widget _buildTableRows({
    required List<Widget> items,
    required Size cardSize,
    required double maxWidth,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    final n = items.length;
    final pairW = cardSize.width + 18;
    const baseGap = 10.0;
    const cols = _tableCols;

    final rows = <List<Widget>>[
      for (var i = 0; i < n; i += cols)
        items.skip(i).take(cols).toList(),
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

    Widget rowAt(int r) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < rows[r].length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              rows[r][i],
            ],
          ],
        );

    // 1–2 ряда — обычная колонка с зазором.
    if (rows.length < 3) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) const SizedBox(height: 10),
            rowAt(r),
          ],
        ],
      );
    }

    // 3+ ряда: 2-й наезжает на 1-й (виден ранг+масть); 3-й — обычный зазор.
    final totalH = _tableStackHeight(cardSize, rows.length);
    return SizedBox(
      height: totalH,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var r = 0; r < rows.length; r++)
            Positioned(
              top: _tableRowTop(cardSize, r, rows.length),
              left: 0,
              right: 0,
              child: rowAt(r),
            ),
        ],
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
    final winnersN = (n - 1).clamp(1, n);
    return stakeWinnerNetProfit(
      stake: view.stakeBronze,
      playerCount: n,
      winnerCount: winnersN,
    );
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
    if (view.phase == 'take_follow') {
      if (view.attackerIndex == view.myIndex) {
        return 'Подкиньте вдогонку или нажмите «Готово»';
      }
      return 'Соперник может подкинуть вдогонку';
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
      duration: const Duration(milliseconds: 900),
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
    // Отбитая пара — затемнение как нелегальные карты в веере.
    final beaten = defense != null;
    // Запас под повёрнутый отбой (иначе углы режутся соседними парами).
    final pairChild = SizedBox(
      width: cardSize.width + 18,
      height: cardSize.height + 20,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          KeyedSubtree(
            key: attackKey,
            child: PlayingCardWidget(
              card: pair.attack.toPlayingCard(),
              size: cardSize,
              elevated: true,
              dropTarget: highlightAttack && !beaten,
              dimmed: beaten,
              animate: false,
            ),
          ),
          // Цель отбоя — отдельный ключ на позиции защиты, не на атаке.
          if (defendTargetKey != null && !beaten)
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
              child: Transform.rotate(
                angle: _kDefendLandAngle,
                child: PlayingCardWidget(
                  card: defense,
                  size: cardSize,
                  elevated: true,
                  highlighted: false,
                  dimmed: true,
                  animate: false,
                ),
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
