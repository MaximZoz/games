import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_grid.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/games/durak/durak_hand_sort.dart';
import 'package:multigames_client/games/durak/durak_offline_session.dart';
import 'package:multigames_client/games/durak/durak_provider.dart';
import 'package:multigames_client/games/durak/durak_repository.dart';
import 'package:multigames_client/games/durak/durak_rules.dart';
import 'package:multigames_client/games/durak/durak_fx_layout.dart';
import 'package:multigames_client/games/durak/durak_table_layout.dart';
import 'package:multigames_client/games/game_balance_settle.dart';
import 'package:multigames_client/games/offline_session_hold.dart';
import 'package:multigames_client/games/game_eliminate.dart';
import 'package:multigames_client/games/game_stake.dart';
import 'package:multigames_client/games/game_turn_action.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException;
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/game_table_fit.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/durak/card_fan.dart';
import 'package:multigames_client/ui/durak/card_fly.dart';
import 'package:multigames_client/ui/durak/deck_pile.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';
import 'package:multigames_client/ui/widgets/framed_button.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/game_fly_overlay.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';
import 'package:multigames_client/ui/widgets/gradient_background.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';
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

class _DurakGameScreenState extends ConsumerState<DurakGameScreen>
    with WidgetsBindingObserver {
  bool _busy = false;
  final GameTurnActionLock _turnAction = GameTurnActionLock();

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
  int _gamepadHandIndex = 0;

  /// Карты, скрытые в веере на время полёта/ожидания сервера.
  final Set<PlayingCard> _flyingFromHand = {};

  /// Сходили — не возвращать в веер, пока сервер не уберёт из руки.
  final Set<PlayingCard> _playedAwayCards = {};

  /// Уже сели в веер локально (взятие), пока сервер не подтвердил руку.
  final Set<PlayingCard> _incomingFanCards = {};

  /// Добор из колоды ещё не вложен в веер — не показывать из server hand.
  final Set<PlayingCard> _pendingDealCards = {};

  /// Оптимистично «приземлившиеся» атаки (пока ждём ответ сервера).
  final List<PlayingCard> _optimisticAttacks = [];

  /// Атаки, которые ещё летят на стол (плейсхолдер скрыт под fly).
  final Set<PlayingCard> _flyingToTable = {};

  /// Карты, которые уже сидят на столе — их нельзя прятать при переводе.
  final Set<String> _seatedTableCardIds = {};

  /// Карты, которые игрок уже видел на столе. Не гасим их при своём переводе.
  final Set<String> _shownTableCardIds = {};

  /// Оптимистичная защита: индекс пары → карта.
  final Map<int, PlayingCard> _optimisticDefends = {};

  /// Атака, на которую сел оптимистичный отбой. Чужой индекс его не наследует.
  final Map<int, PlayingCard> _optimisticDefendAttack = {};

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

  /// Локальная бита/взятие уже крутит полёт — серверный FX не перебивает.
  bool _localRoundFx = false;

  /// Кнопка «Бито»/«Готово»/«Взять» уже нажата — не ждать сеть, чтобы её спрятать.
  bool _optimisticActionAck = false;

  /// Сразу показать подпись «Бито», пока карты летят в отбой.
  bool _optimisticBitoReveal = false;

  /// Сразу показать «Беру», не дожидаясь фазы take_follow.
  bool _optimisticTake = false;
  bool _actionPressArmed = false;

  /// Свои подкиды, которые нельзя переиграть как чужой полёт при смене хода.
  final Set<String> _localAttackIds = {};

  /// Рука до локальной биты/взятия — новые карты прячем, пока летят с колоды.
  List<PlayingCard>? _optimisticDealBaseline;

  /// Рубашки добора уже в хвосте веера. Лица подменяются без второго полёта.
  int _dealFaceDownTail = 0;

  /// Сколько карт уже село в веер соперника, пока его счётчик ещё старый.
  final Map<int, int> _oppVisualFloor = {};

  /// Локальная бита/взятие уже на экране. Кадр «до хода» не переписывает prev.
  bool _localRoundPrevLock = false;
  int _lockBito = -1;
  int _lockDeck = -1;
  int _lockHand = -1;
  int _lockTable = -1;

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
  Timer? _busyWatchdog;
  Timer? _myTurnIdleTimer;
  bool _showMyTurnIdleHint = false;
  DateTime? _myTurnSince;
  Timer? _opponentTakeHoldTimer;

  /// После «Беру» соперника держим подпись, потом показываем «Готово».
  bool _opponentTakeHold = false;
  bool _opponentTakeArmed = false;

  /// Веер схлопывается одним твином, пока своя карта летит на стол.
  bool _fanCloseAfterPlay = false;

  /// Веер добирает карты одним коротким твином (колода / стол).
  bool _fanOpenAfterIncoming = false;
  int _busyStuckTicks = 0;
  ProviderSubscription<AsyncValue<Map<String, dynamic>>>? _realtimeSubscription;
  ProviderSubscription<String>? _routeResumeSub;
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

  /// Чип «−N» при проигрыше — только после анимации списания.
  bool _lossChipRevealed = false;

  /// Mid-game выход «в ноль»: observation + салют/монеты — один раз.
  bool _midFinishedHandled = false;

  /// Повторный вход из «Наблюдение» — без анимации/refresh монет.
  bool _openedAsObserver = false;
  bool _openModeCaptured = false;

  /// Салют уже запущен — не размонтировать при чужих ходах (стол снова не пуст).
  bool _confettiArmed = false;

  /// Победа/реванш после паузы на последний отбой, не в том же кадре.
  bool _finishChromeReady = false;
  bool _finishHoldScheduled = false;

  /// Ход/кнопки не скачут, пока свой подкид летит или ждём итог.
  String? _frozenTurnHint;
  int? _frozenTurnActorIdx;
  String? _frozenPhase;

  /// Стартовая раздача ещё не легла — веер не берёт всю руку с сервера.
  bool _concealOpeningHand = false;

  /// Зафиксированный итог mid-finish: не менять текст при сдаче остальных.
  bool? _lockedMidDraw;
  int? _lockedMidPlace;
  final GlobalKey _winRewardKey = GlobalKey();
  final GlobalKey<CardFanState> _fanKey = GlobalKey<CardFanState>();
  final GlobalKey _defendTargetKey = GlobalKey();
  final Map<String, GlobalKey> _tableAttackKeys = {};
  final GlobalKey _attackSlotKey = GlobalKey();

  GlobalKey _attackKeyFor(PlayingCard card) =>
      _tableAttackKeys.putIfAbsent(_cardId(card), GlobalKey.new);

  GlobalKey? _attackKeyAt(int index, List<DurakTablePairApi> table) {
    if (index < 0 || index >= table.length) return null;
    return _attackKeyFor(table[index].attack.toPlayingCard());
  }

  /// Слот посадки подкида — в финальном месте стола (не «рядом», потом сдвиг).
  final GlobalKey _pendingAttackLandKey = GlobalKey();
  final GlobalKey _tableKey = GlobalKey();
  final GlobalKey _deckKey = GlobalKey();
  final GlobalKey _bitoKey = GlobalKey();

  int _prevDeckCount = -1;
  int _prevBitoCount = -1;
  bool _prevLastWasTake = false;
  int _prevHandLen = -1;

  /// Атакующий/защитник до последнего синка — для порядка добора после биты.
  int _prevAttackerIndex = -1;
  int _prevDefenderIndex = -1;

  /// Число карт у соперников на прошлом кадре (для добора из колоды).
  final Map<int, int> _prevOppHandCounts = {};

  /// Сколько карт ещё летит сопернику — скрыты в веере до посадки.
  final Map<int, int> _oppDealPending = {};
  List<DurakTablePairApi> _prevTable = const [];

  /// Последний непустой стол (в т.ч. пока `_busy`/`_fxScheduled`) — для авто-биты.
  List<DurakTablePairApi> _lastNonEmptyTable = const [];
  bool _fxScheduled = false;

  /// Пока шёл FX/busy пришёл новый state — переиграть FX после освобождения.
  bool _fxNeedsReplay = false;

  /// Баннер «Вы ходите / Соперник ходит» до первой карты на столе.
  bool _firstLeadVisible = false;

  /// Соперник, у которого сейчас вскрыт младший козырь (одна рубашка скрыта).
  int? _leadRevealHiddenSeat;
  Offset _tablePanAccum = Offset.zero;
  Size? _lastOverlaySpace;

  /// Локальный порядок карт в веере (после ручной сортировки).
  List<PlayingCard>? _handOrder;

  /// Карты в руке — крупные; на столе/колоде — компактнее.
  static const Size _handCardSizeBase = Size(92, 132);
  static const Size _tableCardSizeBase = Size(66, 94);

  /// Высота, на которой стол помещается в полный размер:
  /// шапка соперника + его веер + стол с колодой + зона руки.
  static const double _tableDesignHeight = 545;

  /// Подгонка под доступную высоту — в альбоме телефона её ~300 px.
  /// Пересчитывается в [_buildTable] и держится полем: размеры карт нужны
  /// и полётам (добор, отбой, бита), которые считаются вне build.
  GameTableFit _fit = const GameTableFit(scale: 1, compact: false);

  Size get _handCardSize => _fit.scaled(_handCardSizeBase);

  Size get _tableCardSize => _fit.scaled(_tableCardSizeBase);

  /// Пар на столе в одном ряду (дальше — следующий ряд).
  static const int _tableCols = 2;

  /// Слот под «Бито»/«Беру»: зарезервирован всегда, иначе стол прыгает.
  static const double _durakActionSlotH = 52;

  /// Экран партии виден (не чаты / другой таб) — иначе FX не на root overlay.
  bool get _gameUiActive {
    if (!mounted) return false;
    var ticker = true;
    try {
      ticker = TickerMode.of(context);
    } catch (_) {}
    var here = '';
    try {
      here = GoRouterState.of(context).uri.path;
    } catch (_) {
      try {
        here = GoRouter.of(context).routeInformationProvider.value.uri.path;
      } catch (_) {}
    }
    return durakGameUiActive(
      tickerEnabled: ticker,
      visiblePath: GameFlyOverlay.visiblePath,
      herePath: here,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _captureOpenMode();
    _initializeProviderBindings();
    _rememberOrSnapOverlaySpace();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rememberOrSnapOverlaySpace();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _snapVisualToServer();
      });
    }
  }

  Size get _flyScreen => overlaySpaceSize(context);

  void _rememberOrSnapOverlaySpace() {
    if (!mounted) return;
    final next = overlaySpaceSize(context);
    if (durakShouldSnapOverlaySpace(
      previous: _lastOverlaySpace,
      next: next,
      playInFlight: _cardFlightActive ||
          _busy ||
          _fxScheduled ||
          _holdingFanCard ||
          _playedAwayCards.isNotEmpty,
    )) {
      _snapVisualToServer();
    }
    _lastOverlaySpace = next;
  }

  /// Снять полёты и показать актуальное состояние сервера.
  ///
  /// В альбоме global-rect из прошлого кадра (или из размера вкладки)
  /// оставляет карты и кнопки поверх нового стола.
  void _snapVisualToServer() {
    CardFlyTicket.dismissAll();
    GameFlyOverlay.dismissAll();
    _fanKey.currentState?.cancelActiveGesture();
    if (!mounted) return;
    _turnAction.release();
    setState(() {
      _busy = false;
      _fxScheduled = false;
      _fxNeedsReplay = false;
      durakSnapRevealHiddenFx(_oppDealPending);
      _trumpFaceVisible = true;
      _firstLeadVisible = true;
      _leadRevealHiddenSeat = null;
      _flightLockTable = false;
      _flightDefendIdx = null;
      _hidingTable = false;
      _takeTableHold = null;
      _suppressRemoteBitoFx = false;
      _localRoundFx = false;
      _optimisticActionAck = false;
      _optimisticBitoReveal = false;
      _optimisticTake = false;
      _actionPressArmed = false;
      _localAttackIds.clear();
      _optimisticDealBaseline = null;
      _dealFaceDownTail = 0;
      _oppVisualFloor.clear();
      _localRoundPrevLock = false;
      _leftTableCards.clear();
      _remoteFlyingCardIds.clear();
      _flyingFromHand.clear();
      _flyingToTable.clear();
      _incomingFanCards.clear();
      _pendingDealCards.clear();
      _concealOpeningHand = false;
      // Сыгранные карты не возвращаем: сервер ещё может держать их в руке.
      _optimisticAttacks.clear();
      _clearOptimisticDefends();
      _seatedTableCardIds.clear();
      _shownTableCardIds.clear();
      _fanAnimDuringBusy = false;
      _suppressFanLayoutAnim = true;
      _frozenFanCardSize = null;
      _frozenFanHandCount = null;
      _holdingFanCard = false;
      _activeCard = null;
      _dragGlobal = null;
      _stopMyTurnIdleHint(clearShown: true);
      _myTurnSince = null;
      _deckCountFreeze = null;
      _bitoCountFreeze = null;
      _fanCloseAfterPlay = false;
      _fanOpenAfterIncoming = false;
    });
    final v = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    if (v != null && v.table.isNotEmpty) {
      _seatTablePairs(v.table);
    }
    _syncOfflineFxHold();
  }

  void _captureOpenMode() {
    if (_openModeCaptured) return;
    _openModeCaptured = true;
    _openedAsObserver = openedAsGameObserver(ref, widget.gameId) ||
        isGameBalanceSettled(ref, widget.gameId);
    if (_openedAsObserver) {
      _balanceGainPlayed = true;
      _midFinishedHandled = true;
    }
  }

  @override
  void didUpdateWidget(covariant DurakGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId) {
      _rematchPollTimer?.cancel();
      _prevGameStatus = null;
      _balanceGainPlayed = false;
      _lossChipRevealed = false;
      _midFinishedHandled = false;
      _openedAsObserver = false;
      _openModeCaptured = false;
      _resetTableFxForNewDeal();
      setState(() {
        _rematchLobbyId = null;
        _rematchDeclined = false;
        _iDeclinedRematch = false;
        _rematchRespondedIds.clear();
        _isRematching = false;
        _isAcceptingRematch = false;
        _isFindingGame = false;
      });
      _captureOpenMode();
    }
  }

  bool get _isOffline => OfflineDurakRegistry.instance.isOffline(widget.gameId);

  void _initializeProviderBindings() {
    if (_providerBindingsInitialized) return;
    _providerBindingsInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isOffline) return;
      final known = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
      final gameOver = known != null && known.isOver;
      final observing =
          ref.read(observationGameProvider)?.gameId == widget.gameId;
      final finishedOut = known?.iAmFinished == true;
      final eliminated = known?.iAmEliminated == true;
      if (gameOver) {
        _clearSessionForFinishedGame();
      } else if (finishedOut || eliminated || observing) {
        clearBlockingGamePin(ref, ifGameId: widget.gameId);
        enterGameObservation(ref, widget.gameId, gameType: 'durak');
      } else {
        pinBlockingGame(ref, widget.gameId, gameType: 'durak');
        final prev = ref.read(activeGameProvider).valueOrNull;
        if (prev?.gameId != widget.gameId) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: widget.gameId,
                  lobbyId: prev?.lobbyId,
                  gameType: 'durak',
                ),
              );
        }
      }
      unawaited(ref.read(activeGameProvider.notifier).refresh());
    });
    _routeResumeSub?.close();
    _routeResumeSub = ref.listenManual<String>(
      currentRoutePathProvider,
      (prev, next) {
        if (!mounted) return;
        if (shouldSnapDurakVisualOnResume(
          previousPath: prev,
          nextPath: next,
        )) {
          _snapVisualToServer();
        }
      },
    );
    _busyWatchdog?.cancel();
    _busyWatchdog = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      final stuck = durakVisualLooksStuck(
        busy: _busy,
        fxScheduled: _fxScheduled,
        flightActive: _cardFlightActive,
        hidingTable: _hidingTable || _takeTableHold != null,
        remoteFlightActive: _remoteFlyingCardIds.isNotEmpty,
      );
      if (stuck) {
        _busyStuckTicks++;
        if (_busyStuckTicks >=
            durakStuckSnapTicks(
              compact: _fit.compact,
              openingDeal: _concealOpeningHand,
              // Длинный бюджет только пока карты реально летят.
              // Зависший флаг раунда без полёта не держит короткую руку.
              handDeal: _localRoundFx &&
                  (_fxScheduled ||
                      _cardFlightActive ||
                      _hidingTable ||
                      _takeTableHold != null),
            )) {
          _busyStuckTicks = 0;
          _snapVisualToServer();
          if (!_isOffline) {
            ref.invalidate(durakGameProvider(widget.gameId));
          }
        }
      } else {
        _busyStuckTicks = 0;
      }
    });
    if (_isOffline) return;
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
    WidgetsBinding.instance.removeObserver(this);
    _timeoutRetryTimer?.cancel();
    _rematchPollTimer?.cancel();
    _busyWatchdog?.cancel();
    _myTurnIdleTimer?.cancel();
    _opponentTakeHoldTimer?.cancel();
    _realtimeSubscription?.close();
    _routeResumeSub?.close();
    CardFlyTicket.dismissAll();
    GameFlyOverlay.dismissAll();
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
    if (_busy || !_turnAction.tryAcquire()) return;
    _busy = true;
    setState(() {});
    _syncOfflineFxHold();
    try {
      await action();
      ref.invalidate(durakGameProvider(widget.gameId));
    } on GamesException catch (e) {
      if (!mounted) return;
      if (!isStaleNotYourTurnError(e)) {
        showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
      }
    } finally {
      _turnAction.release();
      if (mounted) {
        setState(() => _busy = false);
        _syncOfflineFxHold();
        _requestFxReplay();
      }
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

  void _seatTableCard(PlayingCard card) {
    final id = _cardId(card);
    _seatedTableCardIds.add(id);
    _shownTableCardIds.add(id);
  }

  void _seatTablePairs(Iterable<DurakTablePairApi> table) {
    for (final pair in table) {
      final attack = pair.attack.toPlayingCard();
      if (durakShouldSeatPrevTableCard(
        remoteFlying: _remoteFlyingCardIds.contains(_cardId(attack)),
        alreadyShown: _wasShownOnTable(attack),
      )) {
        _seatTableCard(attack);
      }
      final defense = pair.defense?.toPlayingCard();
      if (defense != null &&
          durakShouldSeatPrevTableCard(
            remoteFlying: _remoteFlyingCardIds.contains(_cardId(defense)),
            alreadyShown: _wasShownOnTable(defense),
          )) {
        _seatTableCard(defense);
      }
    }
  }

  void _unseatTableCard(PlayingCard card) {
    _seatedTableCardIds.remove(_cardId(card));
  }

  void _markRemoteTableCardFlying(PlayingCard card) {
    if (_optimisticDefends.containsValue(card)) return;
    if (_wasShownOnTable(card) && _isSeatedTableCard(card)) return;
    _remoteFlyingCardIds.add(_cardId(card));
    if (!_wasShownOnTable(card)) {
      _unseatTableCard(card);
    }
  }

  void _clearSeatedTableCards() {
    _seatedTableCardIds.clear();
    _shownTableCardIds.clear();
  }

  bool _isSeatedTableCard(PlayingCard card) =>
      _seatedTableCardIds.contains(_cardId(card));

  bool _wasShownOnTable(PlayingCard card) =>
      _shownTableCardIds.contains(_cardId(card));

  void _pruneShownTableCards(Iterable<DurakTablePairApi> table) {
    final live = <String>{};
    for (final pair in table) {
      live.add(_cardId(pair.attack.toPlayingCard()));
      final defense = pair.defense?.toPlayingCard();
      if (defense != null) live.add(_cardId(defense));
    }
    final optimisticDefenseIds = <String>{
      for (final card in _optimisticDefends.values) _cardId(card),
    };
    _shownTableCardIds.removeWhere(
      (id) => !durakKeepShownTableId(
        onLiveTable: live.contains(id),
        localAttack: _localAttackIds.contains(id),
        optimisticDefense: optimisticDefenseIds.contains(id),
      ),
    );
  }

  /// Свой подкид остаётся в prev, даже если WS ещё не принёс карту.
  void _rememberLocalAttackCards(Iterable<PlayingCard> cards) {
    if (cards.isEmpty) return;
    final extra = <DurakTablePairApi>[];
    final have = <String>{
      for (final p in _prevTable) _cardId(p.attack.toPlayingCard()),
    };
    for (final card in cards) {
      final id = _cardId(card);
      _localAttackIds.add(id);
      if (have.contains(id)) continue;
      extra.add(DurakTablePairApi(attack: DurakApiCard.fromCard(card)));
      have.add(id);
    }
    if (extra.isEmpty) return;
    _prevTable = [..._prevTable, ...extra];
  }

  void _retainLocalAttacksInPrev() {
    if (_localAttackIds.isEmpty &&
        _optimisticAttacks.isEmpty &&
        _flyingToTable.isEmpty) {
      return;
    }
    final have = <String>{
      for (final p in _prevTable) _cardId(p.attack.toPlayingCard()),
    };
    final extra = <DurakTablePairApi>[];
    for (final card in {..._optimisticAttacks, ..._flyingToTable}) {
      final id = _cardId(card);
      if (have.contains(id)) continue;
      extra.add(DurakTablePairApi(attack: DurakApiCard.fromCard(card)));
      have.add(id);
      _localAttackIds.add(id);
    }
    if (extra.isEmpty) return;
    _prevTable = [..._prevTable, ...extra];
  }

  void _forgetFinishedLocalAttacks(DurakGameView view) {
    if (_localAttackIds.isEmpty) return;
    final live = <String>{
      for (final p in view.table) _cardId(p.attack.toPlayingCard()),
      for (final c in _optimisticAttacks) _cardId(c),
      for (final c in _flyingToTable) _cardId(c),
    };
    _localAttackIds.removeWhere((id) => !live.contains(id));
  }

  /// Защиту, которую ещё не показывали, не кладём в prev — иначе она вспыхнет.
  DurakTablePairApi _pairRememberedForPrev(DurakTablePairApi incoming) {
    final defense = incoming.defense?.toPlayingCard();
    final previous = _pairOnTable(_prevTable, incoming);
    final keep = durakKeepDefenseInPrevTable(
      hasDefense: defense != null,
      alreadyVisible: defense != null &&
          (_wasShownOnTable(defense) ||
              _isSeatedTableCard(defense) ||
              _optimisticDefends.containsValue(defense)),
      wasInPrevious: previous?.defense != null,
    );
    if (defense == null || keep) return incoming;
    return DurakTablePairApi(attack: incoming.attack);
  }

  /// Карты, которые уже показывали лицом, больше не прячем как remote.
  void _seatUnhiddenTableCards(Iterable<DurakTablePairApi> table) {
    for (final pair in table) {
      final attack = pair.attack.toPlayingCard();
      if (durakSeatUnhiddenTableCard(
        remoteFlying: _remoteFlyingCardIds.contains(_cardId(attack)),
        localFlying: _flyingToTable.contains(attack),
      )) {
        _seatTableCard(attack);
      }
      final defense = pair.defense?.toPlayingCard();
      if (defense != null &&
          durakSeatUnhiddenTableCard(
            remoteFlying: _remoteFlyingCardIds.contains(_cardId(defense)),
            localFlying: _flyingToTable.contains(defense),
          )) {
        _seatTableCard(defense);
      }
    }
  }

  bool _pairAttackExistedOn(
    Iterable<DurakTablePairApi> table,
    DurakTablePairApi pair,
  ) {
    return table.any(
      (o) =>
          o.attack.rank == pair.attack.rank &&
          o.attack.suit == pair.attack.suit,
    );
  }

  DurakTablePairApi? _pairOnTable(
    Iterable<DurakTablePairApi> table,
    DurakTablePairApi pair,
  ) {
    for (final o in table) {
      if (o.attack.rank == pair.attack.rank &&
          o.attack.suit == pair.attack.suit) {
        return o;
      }
    }
    return null;
  }

  bool _shouldShowTablePair(DurakTablePairApi pair, int _) {
    final atk = pair.attack.toPlayingCard();
    // Пока fly/optimistic — серверную пару не рисуем: лицо ведёт overlay.
    // Remote прячем opacity 0 (якорь посадки должен остаться).
    return durakKeepServerTablePair(
      optimistic: _optimisticAttacks.contains(atk),
      flyingToTable: _flyingToTable.contains(atk),
    );
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
    final def = pair.defense?.toPlayingCard();
    final atk = pair.attack.toPlayingCard();
    if (def == null ||
        def == atk ||
        durakTableDefenseHiddenDuringFlight(
          localDefendLock: _flightDefendIdx == i && _flightLockTable,
          remoteDefenseFlying: _isRemoteTableCardHidden(def),
        )) {
      return DurakTablePairApi(attack: pair.attack, defense: null);
    }
    return pair;
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

  PlayingCard? _visibleOptimisticDefense(int i, PlayingCard attack) {
    if (_flightDefendIdx == i && _flightLockTable) return null;
    final opt = _optimisticDefends[i];
    if (opt == null || opt == attack) return null;
    final remembered = _optimisticDefendAttack[i];
    if (remembered != null && remembered != attack) return null;
    if (_isRemoteTableCardHidden(opt)) return null;
    return opt;
  }

  /// Веер: всегда на всю [maxWidth]; при росте руки сжимаем размер карт
  /// (шаг пересчитывается так, чтобы веер снова растянулся от края до края).
  ({Size cardSize, double spacing}) _fitHandFan(int n, double maxWidth) {
    if (n <= 0) return (cardSize: _handCardSize, spacing: 0);
    // Непрерывная кривая вместо ступенек: одна новая карта сжимает веер
    // чуть-чуть, а не роняет размер сразу на 10%.
    final scale = durakFanScaleFor(n);
    var size = Size(_handCardSize.width * scale, _handCardSize.height * scale);

    const fanPad = 4.0;
    final usable = (maxWidth - fanPad).clamp(72.0, maxWidth);

    /// Минимальный шаг (доля ширины карты), чтобы полоска оставалась читаемой.
    double minSpacing(Size s) {
      if (n <= 1) return 0;
      return s.width * durakFanMinSpacingFrac(n);
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
    if (n == 1) {
      return (cardSize: _handCardSize, spacing: 0, fillWidth: false);
    }
    // 2–3 карты раньше шли мимо общей формулы, и переход «4 → 3» прыгал
    // на полный размер. Теперь та же кривая, просто шаг пошире.
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
    final defCount =
        (def >= 0 && def < view.hands.length) ? view.hands[def].count : 6;
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
    // Первый отбой — не больше 5 карт на столе (бита пуста / флаг с сервера).
    final firstRound = view.firstRound ||
        (view.bitoCount == 0 && !view.lastWasTake && !view.isOver);
    if (firstRound && maxPairs > 5) maxPairs = 5;
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

  /// Optimistic-атаки — слот посадки (opacity 0 под fly), даже если WS уже подтвердил.
  List<PlayingCard> _pendingAttackPlaceholders(DurakGameView view) {
    if (_optimisticAttacks.isEmpty) return const [];
    final seated = {
      for (final p in view.table) p.attack.toPlayingCard(),
    };
    return [
      for (final c in _optimisticAttacks)
        if (durakNeedsPendingAttackSlot(
          attackAlreadyOnTable: seated.contains(c),
          stillFlying: _flyingToTable.contains(c),
        ))
          c,
    ];
  }

  int _compareHandCards(PlayingCard a, PlayingCard b, Suit trump) =>
      compareDurakHandCards(a, b, trump);

  /// Карты, ушедшие из руки (атака/защита). Не путать с взятием:
  /// при take карты в [_handOrder] + [_flyingFromHand] — слоты-дырки в веере.
  Set<PlayingCard> get _locallyGoneFromHand {
    return durakCardsGoneFromFan(
      playedAway: _playedAwayCards,
      optimisticAttacks: _optimisticAttacks,
      flyingToTable: _flyingToTable,
      flyingFromHand: _flyingFromHand,
      incomingFanCards: _incomingFanCards,
      handOrder: _handOrder,
    );
  }

  void _markPlayedAway(Iterable<PlayingCard> cards) {
    _playedAwayCards.addAll(cards);
  }

  void _unmarkPlayedAway(Iterable<PlayingCard> cards) {
    _playedAwayCards.removeAll(cards);
  }

  void _forgetPlayedAwayIfReturning() {
    if (_playedAwayCards.isEmpty) return;
    final keep = durakRetainPlayedAway(
      playedAway: _playedAwayCards,
      incomingFanCards: _incomingFanCards,
      pendingDealCards: _pendingDealCards,
    );
    if (keep.length == _playedAwayCards.length) return;
    _playedAwayCards
      ..clear()
      ..addAll(keep);
  }

  List<PlayingCard> _handWithoutLeaving(List<PlayingCard> hand) {
    final gone = _locallyGoneFromHand;
    if (gone.isEmpty) return List<PlayingCard>.of(hand);
    return [
      for (final c in hand)
        if (!gone.contains(c)) c
    ];
  }

  void _seedHandOrderIfEmpty(List<PlayingCard> hand) {
    if (_handOrder != null && _handOrder!.isNotEmpty) return;
    if (hand.isEmpty) return;
    _handOrder = _handWithoutLeaving(hand);
  }

  /// Порядок веера: сохраняем локальную сортировку между синками сервера.
  ///
  /// Свой ход до посадки — дырка в том же слоте (лицо в hiddenCards).
  /// Иначе clearLift и схлопывание на кадр вспыхивают картой и всем веером.
  List<PlayingCard> _orderedHand(List<PlayingCard> serverHand, Suit trump) {
    _forgetPlayedAwayIfReturning();
    final pending = durakOpeningDealPendingSet(
      concealOpeningHand: _concealOpeningHand,
      pendingDealCards: _pendingDealCards,
      handOrder: _handOrder,
      incomingFanCards: _incomingFanCards,
      serverHand: serverHand,
    );
    return durakOrderedHandSlots(
      prevOrder:
          _concealOpeningHand && (_handOrder == null || _handOrder!.isEmpty)
              ? const <PlayingCard>[]
              : _handOrder,
      serverHand: serverHand,
      pendingDeal: pending,
      leavingHand: _locallyGoneFromHand,
      holeCards: durakFanHoleCards(
        playedAway: _playedAwayCards,
        flyingFromHand: _flyingFromHand,
        incomingFanCards: _incomingFanCards,
      ),
      compareNew: (a, b) => _compareHandCards(a, b, trump),
    );
  }

  void _sortHandInFan(
    List<PlayingCard> hand,
    Suit trump, {
    bool animate = true,
    bool keepFreeze = false,
  }) {
    final sorted = _handWithoutLeaving(hand)
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
      _releaseFanLayoutSmooth();
    });
  }

  bool _highlightAttackSlot(DurakGameView view) {
    final focus =
        _activeCard ?? (_selected.isNotEmpty ? _selected.first : null);
    if (focus == null || _busy || view.isOver) return false;
    if (!_isAttackPhase(view)) return false;
    // Подкид — без подсветки слота; только первая атака на пустой стол.
    if (view.table.isNotEmpty || _optimisticAttacks.isNotEmpty) return false;
    return _legalAttackNow(view).contains(focus);
  }

  /// Подсветка слота перевода при подъёме карты того же ранга.
  bool _highlightTransferSlot(DurakGameView view) {
    final focus =
        _activeCard ?? (_selected.isNotEmpty ? _selected.first : null);
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
    final firstRound = view.firstRound ||
        (view.bitoCount == 0 && !view.lastWasTake && !view.isOver);
    if (firstRound && cap > 5) cap = 5;
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
      final key = _attackKeyAt(i, view.table);
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
    final pairH = durakTablePairHeight(_tableCardSize);
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
    final byRank = {
      for (final c in hand)
        if (c.rank == rank) c
    };
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
    final atkKey = _attackKeyAt(defendIdx, view.table);
    final defendCenter =
        (atkKey != null ? globalRectOf(atkKey)?.center : null) ??
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
          view.phase == 'throw_in' ||
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

  /// Карта вернулась в веер — убрать слот/glow и разложить руку как онлайн.
  void _onCardReturnedToFan(PlayingCard _) {
    _clearHandSelection();
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    if (view == null || view.myIndex < 0 || view.myIndex >= view.hands.length) {
      return;
    }
    final trump = _suitFromApi(view.trumpSuit);
    final hand = _apiCardsToPlaying(view.hands[view.myIndex].cards ?? const []);
    if (hand.length < 2) return;
    final sorted = List<PlayingCard>.from(hand)
      ..sort((a, b) => compareDurakHandCards(a, b, trump));
    final current = _handOrder;
    if (current != null &&
        current.length == sorted.length &&
        _sameCardOrder(current, sorted)) {
      return;
    }
    _sortHandInFan(hand, trump);
  }

  bool _sameCardOrder(List<PlayingCard> a, List<PlayingCard> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _freezeFanLayout(Size cardSize, double spacing, int handCount) {
    _frozenFanCardSize = cardSize;
    _frozenFanHandCount = handCount;
  }

  void _freezeOpeningDealFan(int finalCount) {
    if (!mounted) return;
    final lay = _handFanVisualLayout(
      finalCount.clamp(1, 52),
      MediaQuery.sizeOf(context).width,
    );
    _freezeFanLayout(lay.cardSize, lay.spacing, finalCount.clamp(1, 52));
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
      _fanOpenAfterIncoming = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_suppressFanLayoutAnim) {
        setState(() => _suppressFanLayoutAnim = false);
      }
    });
  }

  /// Снять заморозку одним коротким твином — как после своего хода.
  void _releaseFanLayoutSmooth() {
    if (!mounted || _frozenFanCardSize == null) return;
    setState(() {
      _unfreezeFanLayout();
      _suppressFanLayoutAnim = false;
      _fanOpenAfterIncoming = true;
      _fanAnimDuringBusy = true;
    });
    Future<void>.delayed(kDurakFanIncomingDuration, () {
      if (!mounted) return;
      if (!_fanOpenAfterIncoming) return;
      setState(() {
        _fanOpenAfterIncoming = false;
        if (!_busy) _fanAnimDuringBusy = false;
      });
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
    final canTransfer = isDefend && transferLegal.contains(cards.first);
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

    final screen = _flyScreen;
    final defendIdx =
        doDefend ? _defendTargetIndex(view, cards.first, pointer: pointer) : -1;

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
        : (pointer != null ? dragScaleTowardCenter(pointer, screen) : 1.0);

    _rememberMoveChrome(view);
    final fanCount = math.max(1, _handOrder?.length ?? _myHandOf(view).length);
    final fanLay = _handFanVisualLayout(
      fanCount,
      MediaQuery.sizeOf(context).width,
    );
    // Карту сразу убираем из веера: слоты едут одним коротким твином,
    // пока лицо летит overlay. Дырка до посадки оставляла веер «рваным».
    // Размер веера заморожен, чтобы стол не уехал из-под полёта.
    setState(() {
      _freezeFanLayout(fanLay.cardSize, fanLay.spacing, 52);
      _activeCard = null;
      _selected.clear();
      _dragGlobal = null;
      _flyingFromHand.addAll(cards);
      _markPlayedAway(cards);
      _removeFromHandOrder(cards, view);
      _busy = true;
      _syncOfflineFxHold();
      _flightLockTable = doDefend;
      _flightDefendIdx = doDefend && defendIdx >= 0 ? defendIdx : null;
      if (doTransfer) {
        _optimisticAttacks.addAll(cards);
        _flyingToTable.addAll(cards);
        // Уже лежащие карты остаются seated: WS/replay не гасит стол.
        _seatTablePairs(view.table);
      }
      _fanCloseAfterPlay = true;
      _suppressFanLayoutAnim = false;
    });

    // Цель после layout — летим в финальную точку атаки/слота.
    await awaitDurakFrame();
    if (!mounted) return true;
    await awaitDurakFrame();
    if (!mounted) return true;

    // Отбой: ключ уже на позиции защиты; fallback — атака + смещение.
    final Rect to;
    final Size landSize;
    if (doDefend) {
      final defendRect = globalRectOf(_defendTargetKey);
      if (defendRect != null) {
        to = defendRect;
      } else {
        final atkKey =
            defendIdx >= 0 ? _attackKeyAt(defendIdx, view.table) : null;
        final atk = (atkKey != null ? globalRectOf(atkKey) : null) ??
            globalRectOf(_tableKey) ??
            Rect.fromCenter(
              center: Offset(screen.width / 2, screen.height * 0.42),
              width: _tableCardSize.width,
              height: _tableCardSize.height,
            );
        to = durakEstimateDefenseLandRect(atk);
      }
      landSize = Size(to.width, to.height);
    } else {
      to = _landRectForPendingAttack(view, screen);
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
      curve: kDurakFlyCurve,
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
      final tickets = <CardFlyTicket>[];
      try {
        tickets.add(await firstFly);
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
              curve: kDurakFlyCurve,
              beginScale: beginScale,
              endScale: shrink,
              beginAngle: 0,
              endAngle: landAngle,
              arcLift: 0,
              keepAtEnd: true,
            ),
          );
        }
        if (!mounted) return;

        if (doDefend && defendIdx >= 0) {
          // Слот и снятие замка — в одном кадре, пока overlay ещё лежит сверху.
          // Иначе карта гаснет между dismiss и появлением защиты.
          setState(() {
            _optimisticDefends[defendIdx] = cards.first;
            if (defendIdx < view.table.length) {
              _optimisticDefendAttack[defendIdx] =
                  view.table[defendIdx].attack.toPlayingCard();
            }
            _seatTableCard(cards.first);
            _flightLockTable = false;
            _flightDefendIdx = null;
            _busy = false;
          });
          _rememberOptimisticTableDefense(defendIdx, cards.first);
          _syncOfflineFxHold();
          await awaitDurakFrame();
          if (mounted) await awaitDurakFrame();
          for (final t in tickets) {
            t.dismiss();
          }
          tickets.clear();
          _releaseFanLayoutSmooth();
        } else {
          // Перевод: сначала слот, потом overlay — иначе кадр без карты.
          if (mounted) {
            setState(() {
              _flyingToTable.removeAll(cards);
              for (final card in cards) {
                _seatTableCard(card);
                _rememberLocalAttackCards([card]);
              }
              _busy = false;
            });
            _syncOfflineFxHold();
          }
          await awaitDurakFrame();
          if (mounted) await awaitDurakFrame();
          for (final t in tickets) {
            t.dismiss();
          }
          tickets.clear();
          _releaseFanLayoutSmooth();
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
            for (final c in cards) {
              if (_tableHasAttack(v, c)) {
                _seatTableCard(c);
                _optimisticAttacks.remove(c);
              }
            }
            _retireOptimisticDefenses(v);
            _dragGlobal = null;
            _fanCloseAfterPlay = false;
            _suppressFanLayoutAnim = false;
            _clearMoveChrome(keepForFinish: v != null && v.isOver);
          });
          _syncOfflineFxHold();
          _requestFxReplay();
        } on GamesException catch (e) {
          if (!mounted) return;
          showAppSnackBar(context,
              message: e.message, kind: AppSnackKind.error);
          setState(() {
            for (final c in cards) {
              _optimisticAttacks.remove(c);
            }
            if (doDefend) {
              for (final c in cards) {
                _unseatTableCard(c);
                _shownTableCardIds.remove(_cardId(c));
                _forgetOptimisticDefense(c);
              }
            }
            _clearOptimisticDefends();
            _restoreToHandOrder(cards);
            _unmarkPlayedAway(cards);
            _dragGlobal = null;
            _fanCloseAfterPlay = false;
            _suppressFanLayoutAnim = false;
            _clearMoveChrome(keepForFinish: false);
          });
          _syncOfflineFxHold();
          _requestFxReplay();
        }
      } finally {
        for (final t in tickets) {
          t.dismiss();
        }
        _releaseFanLayoutSmooth();
        _busy = false;
        if (mounted) {
          setState(() {
            _flyingFromHand.removeAll(cards);
            _flyingToTable.removeAll(cards);
            _flightLockTable = false;
            _flightDefendIdx = null;
            _fanCloseAfterPlay = false;
          });
        }
        // После перевода busy держал fxHold — без снятия бот ждёт смены вкладки.
        _syncOfflineFxHold();
        _requestFxReplay();
      }
    }());

    return true;
  }

  /// Вернуть карты в веер после ошибки хода — без дубля, если слот ещё дырка.
  void _restoreToHandOrder(Iterable<PlayingCard> cards) {
    if (_handOrder == null) return;
    final have = _handOrder!.toSet();
    _handOrder = [
      ..._handOrder!,
      for (final c in cards)
        if (!have.contains(c)) c,
    ];
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
  /// Карты из [_pendingDealCards] не подмешиваем — они долетят анимацией.
  void _syncHandOrderFromServer(DurakGameView v) {
    final hand = _apiCardsToPlaying(
      v.hands.length > v.myIndex && v.myIndex >= 0
          ? (v.hands[v.myIndex].cards ?? const [])
          : const [],
    );
    _forgetPlayedAwayIfReturning();
    if (hand.isEmpty) {
      if (_pendingDealCards.isEmpty) _handOrder = [];
      return;
    }
    final prev = _handOrder;
    final pending = _pendingDealCards;
    final leaving = _locallyGoneFromHand;
    if (prev == null || prev.isEmpty) {
      // Не класть в веер то, что ещё должно лететь с колоды.
      _handOrder = [
        for (final c in hand)
          if (!pending.contains(c) && !leaving.contains(c)) c,
      ];
      if (_handOrder!.isEmpty && pending.isEmpty && leaving.isEmpty) {
        _handOrder = List<PlayingCard>.of(hand);
      }
      return;
    }
    _handOrder = durakMergeHandOrderAfterMove(
      prevOrder: prev,
      serverHand: hand,
      pendingDeal: pending,
      leavingHand: leaving,
    );
  }

  /// Подкид/атака без `_busy`: одна карта, веер сразу свободен, посадка без мигания.
  Future<bool> _playAttackChain(
    DurakGameView view,
    List<PlayingCard> cards, {
    Rect? fromOverride,
    Offset? pointer,
  }) async {
    final screen = _flyScreen;
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
        : (pointer != null ? dragScaleTowardCenter(pointer, screen) : 1.0);

    // Ход/кнопки не скачут, пока карта летит и сервер отвечает.
    _rememberMoveChrome(view);
    // Размер веера держим, пока overlay садится: иначе стол сдвигается
    // под летящей картой и на посадке она моргает.
    final fanCount = math.max(1, _handOrder?.length ?? _myHandOf(view).length);
    final fanLay = _handFanVisualLayout(
      fanCount,
      MediaQuery.sizeOf(context).width,
    );
    // Карту сразу убираем из веера — слоты схлопываются вместе с полётом.
    setState(() {
      _freezeFanLayout(fanLay.cardSize, fanLay.spacing, 52);
      _activeCard = null;
      _selected.clear();
      _dragGlobal = null;
      _flyingFromHand.addAll(cards);
      _markPlayedAway(cards);
      _removeFromHandOrder(cards, view);
      _optimisticAttacks.addAll(cards);
      _flyingToTable.addAll(cards);
      _rememberLocalAttackCards(cards);
      _fanCloseAfterPlay = true;
      _suppressFanLayoutAnim = false;
    });
    _syncOfflineFxHold();

    await awaitDurakFrame();
    if (!mounted) return true;
    await awaitDurakFrame();
    if (!mounted) return true;

    // Финальная точка: ключ слота в уже перестроенной сетке.
    // Нельзя брать «центр стола» — потом карта выровняется и будет рывок.
    final to = _landRectForPendingAttack(view, screen);

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
      curve: kDurakFlyCurve,
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
      final tickets = <CardFlyTicket>[];
      try {
        tickets.add(await firstFly);
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
              curve: kDurakFlyCurve,
              beginScale: beginScale,
              endScale: shrink,
              beginAngle: 0,
              endAngle: 0,
              arcLift: 0,
              keepAtEnd: true,
            ),
          );
        }
        if (!mounted) return;
        // Сначала лицо на столе, потом overlay — иначе кадр без карты.
        final seated = {
          for (final p in (ref
                  .read(durakGameProvider(widget.gameId))
                  .valueOrNull
                  ?.table ??
              const <DurakTablePairApi>[]))
            p.attack.toPlayingCard(),
        };
        if (mounted) {
          setState(() {
            for (final c in cards) {
              _seatTableCard(c);
              _rememberLocalAttackCards([c]);
            }
            // Отбой бота в том же снимке не вспыхивает под севшей атакой.
            _concealUnseenDefenses(
              ref.read(durakGameProvider(widget.gameId)).valueOrNull?.table ??
                  const [],
            );
            _flyingToTable.removeAll(cards);
            for (final c in cards) {
              if (seated.contains(c)) _optimisticAttacks.remove(c);
            }
          });
        }
        await awaitDurakFrame();
        if (mounted) await awaitDurakFrame();
        for (final t in tickets) {
          t.dismiss();
        }
        tickets.clear();
        // Стол и карта уже совпали — размер веера можно отпустить плавно.
        _releaseFanLayoutSmooth();
        await commitFuture;
        if (!mounted) return;
        final after = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
        setState(() {
          for (final c in cards) {
            if (_tableHasAttack(after, c)) {
              _seatTableCard(c);
              _optimisticAttacks.remove(c);
            }
          }
          _fanCloseAfterPlay = false;
          _suppressFanLayoutAnim = false;
          _clearMoveChrome(keepForFinish: after != null && after.isOver);
        });
        _syncOfflineFxHold();
        _requestFxReplay();
      } finally {
        for (final t in tickets) {
          t.dismiss();
        }
        _releaseFanLayoutSmooth();
        if (mounted) {
          setState(() {
            _flyingFromHand.removeAll(cards);
            _flyingToTable.removeAll(cards);
            _fanCloseAfterPlay = false;
          });
        }
        _syncOfflineFxHold();
        _requestFxReplay();
      }
    }());
    return true;
  }

  /// Сколько серверных пар уже в сетке (без optimistic/local-fly).
  int _serverPairsInLayout(DurakGameView view) {
    var n = 0;
    for (final p in view.table) {
      final atk = p.attack.toPlayingCard();
      if (!durakKeepServerTablePair(
        optimistic: _optimisticAttacks.contains(atk),
        flyingToTable: _flyingToTable.contains(atk),
      )) {
        continue;
      }
      if (_isSeatedTableCard(atk) ||
          _remoteFlyingCardIds.contains(_cardId(atk))) {
        n++;
      }
    }
    return n;
  }

  /// Посадка своего подкида: ключ слота в уже перестроенной сетке.
  Rect _landRectForPendingAttack(DurakGameView view, Size screen) {
    final pending = _pendingAttackPlaceholders(view);
    final pendingCard = pending.isEmpty ? null : pending.last;
    final idx =
        _serverPairsInLayout(view) + (pending.isEmpty ? 0 : pending.length - 1);
    return (pendingCard != null
            ? globalRectOf(_attackKeyFor(pendingCard))
            : null) ??
        globalRectOf(_pendingAttackLandKey) ??
        globalRectOf(_attackSlotKey) ??
        _estimateAttackLandRect(view, screen, pairIndex: idx);
  }

  /// Геометрия посадки атаки: центр именно карты атаки, не слота пары
  /// (слот шире/выше на +10/+14 под отбой — туда сажать нельзя).
  Rect _estimateAttackLandRect(
    DurakGameView view,
    Size screen, {
    int? pairIndex,
    int? pairCount,
  }) {
    final table = globalRectOf(_tableKey);
    final center =
        table?.center ?? Offset(screen.width / 2, screen.height * 0.42);
    final serverVisible = _serverPairsInLayout(view);
    final n = pairCount ?? (serverVisible + _optimisticAttacks.length);
    final idx = pairIndex ?? (n < 1 ? 0 : n - 1);
    return durakEstimateAttackLandRect(
      tableCenter: center,
      cardSize: _tableCardSize,
      pairIndex: idx,
      pairCount: n,
      compact: _fit.compact,
      cols: _tableCols,
      maxWidth: table?.width,
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
        // Пока карта ещё летит / optimistic — не затираем prev, иначе
        // отбой бота в том же снимке вспыхнет без полёта.
        final stillLanding = cards.any(
          (c) => _flyingToTable.contains(c) || _optimisticAttacks.contains(c),
        );
        if (!stillLanding) _syncPrevAfterMove(v);
        _syncHandOrderFromServer(v);
      }
      if (!clearFlying) return;
      await awaitDurakFrame();
      if (!mounted) return;
      setState(() {
        for (final c in cards) {
          _optimisticAttacks.remove(c);
        }
        _flyingToTable.removeAll(cards);
        _flyingFromHand.removeAll(cards);
        if (v != null) _removeFromHandOrder(cards, v);
      });
    } on GamesException catch (e) {
      if (!mounted) return;
      if (!isStaleNotYourTurnError(e)) {
        showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
      }
      setState(() {
        for (final c in cards) {
          _optimisticAttacks.remove(c);
        }
        _flyingToTable.removeAll(cards);
        _flyingFromHand.removeAll(cards);
        _unmarkPlayedAway(cards);
        _restoreToHandOrder(cards);
      });
      _releaseFanLayoutSnap();
    }
  }

  /// Карта в полёте (атака/отбой) — не показывать «Бито»/«Взять».
  bool get _cardFlightActive =>
      _flyingFromHand.isNotEmpty ||
      _flyingToTable.isNotEmpty ||
      _flightLockTable;

  /// Свой overlay или busy — чужой FX стола ждёт.
  /// Подъём карты из веера не держит FX: соперник должен лететь сразу.
  bool get _tableFxDeferred => durakTableFxDeferred(
        fxScheduled: _fxScheduled,
        busy: _busy,
        localAttackHold: _localAttackHold,
        cardFlightActive: _cardFlightActive,
      );

  bool get _localAttackHold => durakHoldTableFxForLocalAttack(
        optimisticAttack: _optimisticAttacks.isNotEmpty,
        flyingToTable: _flyingToTable.isNotEmpty,
      );

  /// Свой ход/полёт: пустой кадр сервера не должен гасить уже лежащий стол.
  bool get _localPlayActive => _busy || _cardFlightActive || _localAttackHold;

  bool get _freezeMoveChrome =>
      _localAttackHold ||
      _cardFlightActive ||
      (_finishHoldScheduled && !_finishChromeReady);

  void _rememberMoveChrome(DurakGameView view) {
    _frozenTurnHint ??= _liveTurnHint(view, ignoreOver: view.isOver);
    _frozenTurnActorIdx ??=
        view.turnActorIdx >= 0 ? view.turnActorIdx : view.attackerIndex;
    _frozenPhase ??= view.phase;
  }

  void _clearMoveChrome({required bool keepForFinish}) {
    if (keepForFinish) return;
    _frozenTurnHint = null;
    _frozenTurnActorIdx = null;
    _frozenPhase = null;
  }

  void _stopMyTurnIdleHint({required bool clearShown}) {
    _myTurnIdleTimer?.cancel();
    _myTurnIdleTimer = null;
    if (clearShown) {
      _showMyTurnIdleHint = false;
    }
  }

  void _armMyTurnIdleHint(Duration remaining) {
    if (_showMyTurnIdleHint || _myTurnIdleTimer != null) return;
    if (remaining <= Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _showMyTurnIdleHint = true);
      });
      return;
    }
    _myTurnIdleTimer = Timer(remaining, () {
      if (!mounted) return;
      setState(() => _showMyTurnIdleHint = true);
    });
  }

  void _syncMyTurnIdleHint(DurakGameView view) {
    final holding = _holdingFanCard || _activeCard != null;
    final myTurn = !view.isOver && view.isMyTurn && !view.iAmEliminated;
    if (!durakMyTurnIdleClockActive(
      isMyTurn: myTurn,
      gameOver: view.isOver,
      localPlayActive: _localPlayActive,
    )) {
      _myTurnSince = null;
      _stopMyTurnIdleHint(clearShown: true);
      return;
    }
    // Подъём карты прячет надпись, но не сбрасывает 10 с — ход ещё не сделан.
    if (holding) {
      _stopMyTurnIdleHint(clearShown: true);
      return;
    }
    _myTurnSince ??= DateTime.now();
    final elapsed = DateTime.now().difference(_myTurnSince!);
    if (elapsed >= kDurakMyTurnIdleHintDelay) {
      _armMyTurnIdleHint(Duration.zero);
      return;
    }
    _armMyTurnIdleHint(kDurakMyTurnIdleHintDelay - elapsed);
  }

  bool _showMyTurnIdleBanner(DurakGameView view) {
    return durakMyTurnIdleHintVisible(
          isMyTurn: view.isMyTurn && !view.iAmEliminated,
          holdingFanCard: _holdingFanCard || _activeCard != null,
          idleElapsed: _showMyTurnIdleHint,
          gameOver: view.isOver,
        ) &&
        !_showFirstLeadBanner(view);
  }

  /// Жест в веере прячет кнопку; полёт карты — нет (иначе «Бито» мигает).
  bool get _actionPressBlocked =>
      _busy || _cardFlightActive || _localAttackHold;

  bool _canTake(DurakGameView view) {
    if (view.isOver ||
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

  bool _isCurrentThrower(DurakGameView view) {
    if (view.throwerIndex >= 0) return view.throwerIndex == view.myIndex;
    if (view.turnActorIdx >= 0) return view.turnActorIdx == view.myIndex;
    return view.attackerIndex == view.myIndex;
  }

  bool _canBito(DurakGameView view) =>
      !view.isOver &&
      _isCurrentThrower(view) &&
      view.phase == 'attack_follow' &&
      view.table.isNotEmpty &&
      view.table.every((p) => p.defense != null);

  /// Текущий подкидывающий подтверждает конец подкида вдогонку после «Беру».
  bool _canDone(DurakGameView view) =>
      !view.isOver &&
      _isCurrentThrower(view) &&
      view.phase == 'take_follow' &&
      view.table.isNotEmpty;

  /// Пас = то же «Бито»/«Готово» для текущего в очереди (сервер advance).
  bool _canPass(DurakGameView view) => false;

  void _syncOpponentTakeHold(DurakGameView view) {
    final opponentTake = view.phase == 'take_follow' &&
        view.defenderIndex >= 0 &&
        view.defenderIndex != view.myIndex &&
        !view.isOver;
    if (!opponentTake) {
      _opponentTakeHoldTimer?.cancel();
      _opponentTakeHoldTimer = null;
      _opponentTakeHold = false;
      _opponentTakeArmed = false;
      return;
    }
    if (_opponentTakeArmed) return;
    _opponentTakeArmed = true;
    _opponentTakeHold = true;
    _opponentTakeHoldTimer?.cancel();
    _opponentTakeHoldTimer = Timer(kDurakOpponentTakeHold, () {
      if (!mounted) return;
      setState(() => _opponentTakeHold = false);
    });
  }

  List<PlayingCard> _myHandOf(DurakGameView view) {
    if (view.myIndex < 0 || view.myIndex >= view.hands.length) return const [];
    return _apiCardsToPlaying(view.hands[view.myIndex].cards ?? const []);
  }

  bool _seatMayThrow(DurakGameView view, int seat) {
    if (seat < 0 || seat >= view.hands.length) return false;
    if (seat == view.defenderIndex) return false;
    if (view.isEliminated(seat) || view.finished.contains(seat)) return false;
    if (view.hands[seat].count <= 0) return false;
    final living = <int>[
      for (var i = 0; i < view.hands.length; i++)
        if (!view.isEliminated(i) && !view.finished.contains(i)) i,
    ];
    if (living.length < 4) return true;
    final def = view.defenderIndex;
    if (!living.contains(def)) return true;
    final at = living.indexOf(def);
    final next = living[(at + 1) % living.length];
    final prev = living[(at - 1 + living.length) % living.length];
    return seat == next || seat == prev;
  }

  bool _roundEndsIfIPass(DurakGameView view) {
    return durakRoundEndsOnPass(
      actorIndex: view.myIndex,
      playerCount: view.hands.length,
      handCounts: [for (final h in view.hands) h.count],
      canStillThrow: (seat) => _seatMayThrow(view, seat),
    );
  }

  Map<int, int> _predictRefill(DurakGameView view) {
    return _predictRefillCounts(view, [for (final h in view.hands) h.count]);
  }

  /// После «Готово» защитник уже держит стол — добор считаем от новой длины руки.
  Map<int, int> _predictRefillAfterTake(DurakGameView view, int taken) {
    final counts = [for (final h in view.hands) h.count];
    final def = view.defenderIndex;
    if (taken > 0 && def >= 0 && def < counts.length) {
      counts[def] += taken;
    }
    return _predictRefillCounts(view, counts);
  }

  Map<int, int> _predictRefillCounts(DurakGameView view, List<int> handCounts) {
    return durakPredictRefillCounts(
      order: _refillDealOrder(
        attacker: view.attackerIndex,
        defender: view.defenderIndex,
        playerCount: view.hands.length,
      ),
      handCounts: handCounts,
      deckCount: view.deckCount,
      alive: (seat) =>
          seat >= 0 &&
          seat < view.hands.length &&
          !view.isEliminated(seat) &&
          !view.finished.contains(seat),
    );
  }

  void _applyPrevFrom(DurakGameView v) {
    final handLen = v.myIndex >= 0 && v.myIndex < v.hands.length
        ? (v.hands[v.myIndex].cards?.length ?? v.hands[v.myIndex].count)
        : _prevHandLen;
    _prevDeckCount = v.deckCount;
    _prevBitoCount = v.bitoCount;
    _prevLastWasTake = v.lastWasTake;
    _prevHandLen = handLen;
    _prevTable = List.of(v.table);
    _prevAttackerIndex = v.attackerIndex;
    _prevDefenderIndex = v.defenderIndex;
    _syncPrevOppHandCounts(v);
    if (v.table.isEmpty) _lastNonEmptyTable = const [];
    _pendingDealCards.clear();
    _oppDealPending.clear();
    _deckCountFreeze = null;
    _fxNeedsReplay = false;
  }

  /// Ход уже ушёл. Лица добора приезжают после паузы reveal — анимация её не ждёт.
  Future<({DurakGameView? view, bool failed})> _awaitRoundSettled(
    Future<void> moveFuture,
  ) async {
    try {
      await moveFuture;
    } on GamesException catch (e) {
      if (mounted && !isStaleNotYourTurnError(e)) {
        showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
      }
      return (view: null, failed: true);
    } catch (_) {
      return (view: null, failed: true);
    }
    if (!mounted) return (view: null, failed: true);
    if (_isOffline) {
      await _waitOfflineRevealDone();
    }
    DurakGameView? fresh;
    for (var i = 0; i < kDurakRevealSettlePolls; i++) {
      if (!mounted) return (view: fresh, failed: false);
      try {
        fresh = await ref.read(durakRepositoryProvider).getGame(widget.gameId);
      } catch (_) {}
      if (fresh == null) break;
      if (!fresh.isTableReveal) return (view: fresh, failed: false);
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }
    if (mounted && !_isOffline) {
      ref.invalidate(durakGameProvider(widget.gameId));
      try {
        fresh = await ref.read(durakGameProvider(widget.gameId).future);
      } catch (_) {}
    }
    return (view: fresh, failed: false);
  }

  /// Ответ на ход без паузы reveal. Ошибку показывает [_awaitRoundSettled].
  Future<({DurakGameView? view, bool failed})> _awaitMoveAck(
    Future<void> moveFuture,
  ) async {
    try {
      await moveFuture;
    } catch (_) {
      return (view: null, failed: true);
    }
    if (!mounted) return (view: null, failed: true);
    try {
      final fresh =
          await ref.read(durakRepositoryProvider).getGame(widget.gameId);
      return (view: fresh, failed: false);
    } catch (_) {
      return (view: null, failed: false);
    }
  }

  /// Сначала видно, что кнопка нажалась, потом подпись «Бито» / «Беру».
  void _showActionPress({bool bitoReveal = false, bool take = false}) {
    _actionPressArmed = true;
    unawaited(Future<void>.delayed(kDurakActionPressFeedback, () {
      if (!mounted || !_actionPressArmed) return;
      setState(() {
        if (!_actionPressArmed) return;
        _optimisticActionAck = true;
        if (bitoReveal) _optimisticBitoReveal = true;
        if (take) _optimisticTake = true;
      });
    }));
  }

  void _cancelActionPress() {
    _actionPressArmed = false;
  }

  /// Объявить «Беру» — подпись сразу, стол остаётся для подкида вдогонку.
  Future<void> _take() async {
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    if (view == null ||
        !_canTake(view) ||
        _actionPressBlocked ||
        !_turnAction.tryAcquire()) {
      return;
    }
    final snapshot = _currentTableSnapshot(view);
    setState(() => _armTableHold(snapshot));
    _showActionPress(take: true);
    _syncOfflineFxHold();
    try {
      await ref.read(durakRepositoryProvider).move(widget.gameId, type: 'take');
      if (!_isOffline && mounted) {
        ref.invalidate(durakGameProvider(widget.gameId));
        try {
          await ref.read(durakGameProvider(widget.gameId).future);
        } catch (_) {}
      }
    } on GamesException catch (e) {
      _cancelActionPress();
      if (mounted) {
        if (!isStaleNotYourTurnError(e)) {
          showAppSnackBar(context,
              message: e.message, kind: AppSnackKind.error);
        }
        setState(() {
          _takeTableHold = null;
          _optimisticTake = false;
          _optimisticActionAck = false;
        });
      }
    } finally {
      _turnAction.release();
      if (mounted) {
        _syncOfflineFxHold();
        _requestFxReplay();
      }
    }
  }

  /// Закончить подкид вдогонку — защитник забирает стол.
  Future<void> _confirmTakeDone() async {
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    if (view == null || !_canDone(view) || _actionPressBlocked) return;
    await _sendDone();
  }

  Future<void> _sendDone() async {
    if (!_turnAction.tryAcquire()) return;
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    if (view == null) {
      _turnAction.release();
      return;
    }
    final snapshot = _currentTableSnapshot(view);
    final clears = snapshot.isNotEmpty && _roundEndsIfIPass(view);
    final froms = snapshot.isEmpty
        ? const <Rect>[]
        : _tableCardGlobalRectsTopFirst(snapshot);
    final deckBefore = view.deckCount;
    final taken = _flattenTableCards(snapshot).length;
    final plan =
        clears ? _predictRefillAfterTake(view, taken) : const <int, int>{};
    setState(() {
      _busy = true;
      _armTableHold(snapshot);
      if (clears || snapshot.isNotEmpty) {
        _suppressRemoteBitoFx = true;
        _localRoundFx = true;
      }
      if (clears) {
        _optimisticDealBaseline = List<PlayingCard>.of(_myHandOf(view));
      }
    });
    _showActionPress();
    _syncOfflineFxHold();
    final moveFuture =
        ref.read(durakRepositoryProvider).move(widget.gameId, type: 'done');
    final settled = _awaitRoundSettled(moveFuture);
    final ack = _awaitMoveAck(moveFuture);
    var synced = false;
    var playedRound = clears;
    try {
      if (clears) {
        await _playLocalTakeAway(
          view: view,
          snapshot: snapshot,
          froms: froms,
        );
        await _playLocalDeals(
          before: view,
          plan: plan,
          deckBefore: deckBefore,
          settledFuture: settled,
        );
      } else {
        final result = await ack;
        if (!mounted || result.failed) {
          _cancelActionPress();
          return;
        }
        final fresh = result.view;
        final took = fresh != null &&
            snapshot.isNotEmpty &&
            fresh.table.isEmpty &&
            (fresh.lastWasTake ||
                fresh.isTakeReveal ||
                fresh.phase == 'attack');
        if (took) {
          playedRound = true;
          _suppressRemoteBitoFx = true;
          _localRoundFx = true;
          _optimisticDealBaseline ??= List<PlayingCard>.of(_myHandOf(view));
          await _playLocalTakeAway(
            view: view,
            snapshot: snapshot,
            froms: froms,
          );
          if (!fresh.isTableReveal) {
            await _refillFromFresh(view, fresh, deckBefore);
          }
        } else if (mounted) {
          _cancelActionPress();
          setState(() {
            _localRoundFx = false;
            _suppressRemoteBitoFx = false;
            _takeTableHold = null;
            _optimisticActionAck = false;
          });
        }
      }
      final result = await settled;
      if (playedRound &&
          result.view != null &&
          !result.failed &&
          !result.view!.isTableReveal) {
        _applyPrevFrom(result.view!);
        synced = true;
      }
      if (playedRound && !result.failed) {
        _lockLocalRoundPrev(view);
        synced = true;
      }
    } finally {
      _turnAction.release();
      _localRoundFx = false;
      _suppressRemoteBitoFx = false;
      _optimisticDealBaseline = null;
      if (mounted) {
        setState(() {
          _hidingTable = false;
          _takeTableHold = null;
          _busy = false;
          final now = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
          if (now == null || !_canDone(now)) _optimisticActionAck = false;
        });
        _syncOfflineFxHold();
        if (!synced) _requestFxReplay();
      }
    }
  }

  Future<void> _waitOfflineRevealDone() async {
    if (!_isOffline) return;
    final session = OfflineDurakRegistry.instance.get(widget.gameId);
    if (session == null) return;
    await session.waitUntilRevealDone();
  }

  Future<void> _pass() async {
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    if (view == null || !_canPass(view)) return;
    try {
      await ref.read(durakRepositoryProvider).move(widget.gameId, type: 'pass');
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
    if (view == null ||
        !_canBito(view) ||
        _actionPressBlocked ||
        !_turnAction.tryAcquire()) {
      return;
    }
    final snapshot = _tableForBitoHold(_currentTableSnapshot(view));
    final clears = snapshot.isNotEmpty && _roundEndsIfIPass(view);
    // Ректы до любого setState: стол ещё на экране, полёт не из центра.
    final froms =
        snapshot.isEmpty ? const <Rect>[] : _tableCardGlobalRects(snapshot);
    final freezeCount = view.bitoCount;
    final deckBefore = view.deckCount;
    final plan = _predictRefill(view);
    setState(() {
      _busy = true;
      if (snapshot.isNotEmpty) {
        _armTableHold(snapshot, bitoFreeze: freezeCount);
        _suppressRemoteBitoFx = true;
        _localRoundFx = true;
      }
      if (clears) {
        _optimisticDealBaseline = List<PlayingCard>.of(_myHandOf(view));
      }
    });
    // Кнопка сжимается в этом же кадре. Подпись «Бито» — следом, не вместо нажатия.
    _showActionPress(bitoReveal: clears);
    _syncOfflineFxHold();
    final moveFuture =
        ref.read(durakRepositoryProvider).move(widget.gameId, type: 'bito');
    final settled = _awaitRoundSettled(moveFuture);
    final ack = _awaitMoveAck(moveFuture);
    var synced = false;
    var played = clears;
    try {
      if (clears) {
        await _playLocalBitoAndDeals(
          view: view,
          snapshot: snapshot,
          froms: froms,
          freezeCount: freezeCount,
          deckBefore: deckBefore,
          plan: plan,
          settledFuture: settled,
        );
      } else {
        final result = await ack;
        if (!mounted || result.failed) {
          _cancelActionPress();
          return;
        }
        final fresh = result.view;
        final cleared = fresh != null &&
            snapshot.isNotEmpty &&
            (fresh.isBitoReveal ||
                (fresh.table.isEmpty && fresh.bitoCount > freezeCount));
        if (cleared) {
          played = true;
          _optimisticDealBaseline ??= List<PlayingCard>.of(_myHandOf(view));
          if (mounted) setState(() => _optimisticBitoReveal = true);
          await _playLocalBitoAndDeals(
            view: view,
            snapshot: snapshot,
            froms: froms,
            freezeCount: freezeCount,
            deckBefore: deckBefore,
            plan: plan,
            settledFuture: settled,
          );
        } else if (mounted) {
          _cancelActionPress();
          setState(() {
            _localRoundFx = false;
            _suppressRemoteBitoFx = false;
            _takeTableHold = null;
            _bitoCountFreeze = null;
            _optimisticActionAck = false;
            _optimisticBitoReveal = false;
          });
        }
      }
      final result = await settled;
      if (played &&
          result.view != null &&
          !result.failed &&
          !result.view!.isTableReveal) {
        _applyPrevFrom(result.view!);
        synced = true;
      } else if (played && !result.failed) {
        _stampPredictedBitoPrev(
          view: view,
          freezeCount: freezeCount,
          flown: _flattenTableCards(snapshot).length,
          plan: plan.isEmpty ? _predictRefill(view) : plan,
          deckBefore: deckBefore,
        );
        synced = true;
      }
      if (played && !result.failed) {
        _lockLocalRoundPrev(view);
        synced = true;
      }
    } finally {
      _turnAction.release();
      _localRoundFx = false;
      _suppressRemoteBitoFx = false;
      _optimisticDealBaseline = null;
      if (mounted) {
        setState(() {
          _hidingTable = false;
          _takeTableHold = null;
          _busy = false;
          _bitoCountFreeze = null;
          final now = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
          if (now == null || !_canBito(now)) _optimisticActionAck = false;
          if (now != null && (now.isBitoReveal || !_canBito(now))) {
            _optimisticBitoReveal = false;
          }
        });
        _releaseFanLayoutSmooth();
        _syncOfflineFxHold();
        if (!synced) _requestFxReplay();
      }
    }
  }

  void _lockLocalRoundPrev(DurakGameView before) {
    _localRoundPrevLock = true;
    _lockBito = before.bitoCount;
    _lockDeck = before.deckCount;
    _lockHand = _myHandOf(before).length;
    _lockTable = before.table.length;
    _oppDealPending.clear();
    _fxNeedsReplay = false;
  }

  int _handLenOf(DurakGameView view) {
    if (view.myIndex < 0 || view.myIndex >= view.hands.length) return 0;
    return view.hands[view.myIndex].cards?.length ??
        view.hands[view.myIndex].count;
  }

  /// true — кадр обработан, обычный FX стола запускать не нужно.
  bool _holdOrAdoptLocalRound(DurakGameView view) {
    if (!_localRoundPrevLock) return false;
    final behind = durakServerSnapshotBehindLocalRound(
      tableReveal: view.isTableReveal,
      serverBito: view.bitoCount,
      lockedBito: _lockBito,
      serverDeck: view.deckCount,
      lockedDeck: _lockDeck,
      serverHand: _handLenOf(view),
      lockedHand: _lockHand,
      serverTable: view.table.length,
      lockedTable: _lockTable,
    );
    if (behind) return true;
    _localRoundPrevLock = false;
    _dealFaceDownTail = 0;
    final handLen = _handLenOf(view);
    _prevDeckCount = view.deckCount;
    _prevBitoCount = view.bitoCount;
    _prevLastWasTake = view.lastWasTake;
    _prevHandLen = handLen;
    _prevAttackerIndex = view.attackerIndex;
    _prevDefenderIndex = view.defenderIndex;
    _syncPrevOppHandCounts(view);
    _pendingDealCards.clear();
    _oppDealPending.clear();
    _fxNeedsReplay = false;
    _syncHandOrderFromServer(view);
    _incomingFanCards.clear();
    _optimisticDefends.removeWhere(
      (_, card) => !_tableContainsDefense(view.table, card),
    );
    _optimisticDefendAttack.removeWhere(
      (index, _) => !_optimisticDefends.containsKey(index),
    );
    final liveIds = <String>{
      for (final pair in view.table) ...[
        _cardId(pair.attack.toPlayingCard()),
        if (pair.defense != null) _cardId(pair.defense!.toPlayingCard()),
      ],
    };
    _remoteFlyingCardIds.removeWhere((id) => !liveIds.contains(id));
    final settledCount = (_handOrder?.length ?? handLen).clamp(1, 52);
    if (_frozenFanCardSize != null) {
      final lay = _handFanVisualLayout(
        settledCount,
        MediaQuery.sizeOf(context).width,
      );
      _frozenFanCardSize = lay.cardSize;
      _frozenFanHandCount = settledCount;
    }
    // Старый стол раунда не тащим в новый: иначе бита/добор стартуют снова.
    // Пустой стол — тихий догон. Непустой — обычный FX долетит новые карты.
    _prevTable = const [];
    _lastNonEmptyTable = const [];
    return view.table.isEmpty;
  }

  void _stampPredictedBitoPrev({
    required DurakGameView view,
    required int freezeCount,
    required int flown,
    required Map<int, int> plan,
    required int deckBefore,
  }) {
    final dealt = plan.values.fold<int>(0, (sum, n) => sum + n);
    _prevTable = const [];
    _lastNonEmptyTable = const [];
    _prevLastWasTake = false;
    _prevBitoCount = freezeCount + flown;
    _prevDeckCount = (deckBefore - dealt).clamp(0, deckBefore);
    final mine = plan[view.myIndex] ?? 0;
    final base = _optimisticDealBaseline?.length ?? _myHandOf(view).length;
    _prevHandLen = base + mine;
    _prevAttackerIndex = view.defenderIndex;
    _prevDefenderIndex = view.defenderIndex;
    for (final e in plan.entries) {
      if (e.key == view.myIndex) continue;
      final prev = e.key < view.hands.length ? view.hands[e.key].count : 0;
      _prevOppHandCounts[e.key] = prev + e.value;
    }
    _pendingDealCards.clear();
    _oppDealPending.clear();
    _deckCountFreeze = null;
    _fxNeedsReplay = false;
  }

  Future<void> _playLocalBitoAndDeals({
    required DurakGameView view,
    required List<DurakTablePairApi> snapshot,
    required List<Rect> froms,
    required int freezeCount,
    required int deckBefore,
    required Map<int, int> plan,
    required Future<({DurakGameView? view, bool failed})> settledFuture,
  }) async {
    if (snapshot.isNotEmpty && mounted && _gameUiActive) {
      final flown = _flattenTableCards(snapshot).length;
      // setState только помечает кадр. Overlay вставляется до первого await,
      // поэтому стол не пропадает раньше полёта.
      setState(() {
        _hidingTable = true;
        _bitoCountFreeze = freezeCount;
        _takeTableHold = List<DurakTablePairApi>.of(snapshot);
      });
      final tickets = await _animateTableToBito(
        snapshot,
        fromOverrides: froms,
      );
      if (mounted) {
        setState(() => _bitoCountFreeze = freezeCount + flown);
        await awaitDurakFrame();
        if (mounted) await awaitDurakFrame();
      }
      for (final t in tickets) {
        t.dismiss();
      }
    }
    if (!mounted) return;
    await _playLocalDeals(
      before: view,
      plan: plan,
      deckBefore: deckBefore,
      settledFuture: settledFuture,
    );
  }

  Future<void> _playLocalTakeAway({
    required DurakGameView view,
    required List<DurakTablePairApi> snapshot,
    required List<Rect> froms,
  }) async {
    if (snapshot.isEmpty || !mounted || !_gameUiActive) return;
    final taker = view.defenderIndex;
    if (taker == view.myIndex) {
      await _animateTableToFan(
        snapshot,
        fromOverrides: froms,
      );
      return;
    }
    if (taker >= 0) {
      await _animateTableToOpponentFan(snapshot, taker);
    }
  }

  Future<void> _playLocalDeals({
    required DurakGameView before,
    required Map<int, int> plan,
    required int deckBefore,
    required Future<({DurakGameView? view, bool failed})> settledFuture,
  }) async {
    if (plan.isEmpty || !mounted || !_gameUiActive) return;
    ({DurakGameView? view, bool failed})? early;
    var ready = false;
    unawaited(settledFuture.then((value) {
      ready = true;
      early = value;
    }));
    await Future<void>.delayed(Duration.zero);
    final earlyView = _settledDealView(ready: ready, early: early);
    if (earlyView != null) {
      await _refillFromFresh(before, earlyView, deckBefore);
      if (mounted) _clearDeckCountFreeze();
      return;
    }
    _armDeckFreeze(deckBefore);
    final order = _refillDealOrder(
      attacker: before.attackerIndex,
      defender: before.defenderIndex,
      playerCount: before.hands.length,
    );
    final fly = durakDealFlyDuration(compact: _fit.compact);
    var mineAsFaces = false;
    for (final seat in order) {
      if (!mounted || !_gameUiActive) break;
      final n = plan[seat] ?? 0;
      if (n <= 0) continue;
      if (seat == before.myIndex) {
        // Рубашки в свой веер не кладём. Ждём лица и летим из колоды
        // в свой черёд, а не после всех соперников.
        var faces = _settledDealView(ready: ready, early: early);
        if (faces == null) {
          final settled = ready && early != null ? early! : await settledFuture;
          ready = true;
          early = settled;
          faces = _settledDealView(ready: true, early: settled);
        }
        if (faces != null) {
          await _flyMyDealtFaces(before, faces);
          mineAsFaces = true;
        }
        continue;
      }
      await _landBacksOnOpponent(seat, n, fly);
    }
    if (!mounted) return;
    final settled = ready && early != null ? early! : await settledFuture;
    if (!mounted) return;
    if (settled.failed) {
      setState(() {
        _dealFaceDownTail = 0;
        _oppVisualFloor.clear();
      });
    } else if (!mineAsFaces &&
        settled.view != null &&
        !settled.view!.isTableReveal &&
        (plan[before.myIndex] ?? 0) > 0) {
      await _flyMyDealtFaces(before, settled.view!);
    }
    if (mounted) {
      setState(() => _oppDealPending.clear());
      _clearDeckCountFreeze();
    }
  }

  DurakGameView? _settledDealView({
    required bool ready,
    required ({DurakGameView? view, bool failed})? early,
  }) {
    if (!ready || early == null || early.failed || early.view == null) {
      return null;
    }
    if (early.view!.isTableReveal) return null;
    return early.view;
  }

  List<PlayingCard> _incomingAgainstBaseline(
    DurakGameView before,
    DurakGameView fresh,
  ) {
    final hand = _myHandOf(fresh);
    final base = _optimisticDealBaseline ?? _myHandOf(before);
    return [
      for (final card in hand)
        if (!base.contains(card)) card,
    ];
  }

  /// Известные карты добора — лицом из колоды в веер, без рубашки в ожидании.
  Future<void> _flyMyDealtFaces(DurakGameView before, DurakGameView fresh) async {
    final incoming = [
      for (final card in _incomingAgainstBaseline(before, fresh))
        // Со стола уже сели — из колоды их не гоняем второй раз.
        if (!_incomingFanCards.contains(card)) card,
    ];
    if (incoming.isEmpty || !mounted || !_gameUiActive) return;
    await _animateDealCardsToFan(
      incoming,
      flyDuration: durakDealFlyDuration(compact: _fit.compact),
      settleMs: 70,
      keepFanFreeze: true,
      flipToFace: false,
    );
  }

  Future<void> _refillFromFresh(
    DurakGameView before,
    DurakGameView fresh,
    int deckBefore,
  ) async {
    if (!mounted || !_gameUiActive) return;
    final hand = _myHandOf(fresh);
    final base = _optimisticDealBaseline ?? _myHandOf(before);
    final incoming = <PlayingCard>[
      for (final card in hand)
        if (!base.contains(card) && !_incomingFanCards.contains(card)) card,
    ];
    final opp = <int, int>{};
    for (var i = 0; i < fresh.hands.length; i++) {
      if (i == fresh.myIndex) continue;
      final prev = i < before.hands.length ? before.hands[i].count : 0;
      final delta = fresh.hands[i].count - prev;
      if (delta > 0) opp[i] = delta;
    }
    if (incoming.isEmpty && opp.isEmpty) return;
    await _animateRefillDeals(
      view: fresh,
      myIncoming: incoming,
      oppDeals: opp,
      refillAttacker: before.attackerIndex,
      refillDefender: before.defenderIndex,
      deckCountBefore: deckBefore,
    );
  }

  /// Рубашка соперника садится в его веер, не висит до ответа сервера.
  Future<void> _landBacksOnOpponent(int seat, int count, Duration fly) async {
    if (count <= 0 || !mounted || !_gameUiActive) return;
    final toKey = _oppFanKeys.putIfAbsent(seat, GlobalKey.new);
    final endSize =
        durakOpponentFanFlightSize(_tableCardSize, compact: _fit.compact);
    for (var i = 0; i < count; i++) {
      if (!mounted || !_gameUiActive) return;
      final screen = _flyScreen;
      final to = globalRectOf(toKey) ??
          Rect.fromCenter(
            center: Offset(screen.width / 2, screen.height * 0.16),
            width: endSize.width,
            height: endSize.height,
          );
      final land = Rect.fromCenter(
        center: to.center.translate(i * 2.2, i * 1.4),
        width: endSize.width,
        height: endSize.height,
      );
      _consumeDeckFreezeSlot();
      final ticket = await playCardFlyAnimation(
        context: context,
        card: const PlayingCard(Rank.six, Suit.spades),
        cardSize: _tableCardSize,
        from: _deckDealFromRect(jitter: i * 1.8),
        to: land,
        duration: fly,
        curve: kDurakFlyCurve,
        faceDown: true,
        playSfx: false,
        beginScale: 1,
        endScale: endSize.width / _tableCardSize.width,
        beginAngle: 0.12,
        endAngle: 0.08,
        arcLift: 18,
        keepAtEnd: true,
      );
      if (!mounted) {
        ticket.dismiss();
        return;
      }
      setState(() => _raiseOppVisualFloor(seat));
      await awaitDurakFrame();
      ticket.dismiss();
    }
  }

  void _raiseOppVisualFloor(int seat) {
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    final server = view != null && seat >= 0 && seat < view.hands.length
        ? view.hands[seat].count
        : 0;
    final pending = (_oppDealPending[seat] ?? 0).clamp(0, server);
    final base = durakOpponentFanShownCount(
      serverCount: server,
      hidden: pending,
    );
    final floor = _oppVisualFloor[seat] ?? 0;
    final current = base > floor ? base : floor;
    _oppVisualFloor[seat] = current + 1;
  }

  List<DurakTablePairApi> _currentTableSnapshot(DurakGameView view) {
    if (_prevTable.isNotEmpty) return List<DurakTablePairApi>.of(_prevTable);
    if (view.table.isNotEmpty) return List<DurakTablePairApi>.of(view.table);
    if (_lastNonEmptyTable.isNotEmpty) {
      return List<DurakTablePairApi>.of(_lastNonEmptyTable);
    }
    return const [];
  }

  /// Держать стол на экране, пока офлайн-reveal не очистит view.
  void _armTableHold(List<DurakTablePairApi> snapshot, {int? bitoFreeze}) {
    if (snapshot.isEmpty) return;
    _takeTableHold = List<DurakTablePairApi>.of(snapshot);
    if (bitoFreeze != null) _bitoCountFreeze = bitoFreeze;
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
    final screen = _flyScreen;
    final center =
        tableRect?.center ?? Offset(screen.width / 2, screen.height * 0.42);
    final out = <Rect>[];
    for (var i = 0; i < table.length; i++) {
      final p = table[i];
      final keyRect = globalRectOf(
        _attackKeyFor(p.attack.toPlayingCard()),
      );
      final atk = keyRect ??
          durakEstimateAttackLandRect(
            tableCenter: center,
            cardSize: _tableCardSize,
            pairIndex: i,
            pairCount: table.length,
            compact: _fit.compact,
            cols: _tableCols,
          );
      out.add(atk);
      if (p.defense != null) {
        out.add(durakEstimateDefenseLandRect(atk));
      }
    }
    return out;
  }

  List<Rect> _tableCardGlobalRectsTopFirst(List<DurakTablePairApi> table) {
    if (table.isEmpty) return const [];
    final tableRect = globalRectOf(_tableKey);
    final screen = _flyScreen;
    final center =
        tableRect?.center ?? Offset(screen.width / 2, screen.height * 0.42);
    final out = <Rect>[];
    for (var i = 0; i < table.length; i++) {
      final p = table[i];
      final keyRect = globalRectOf(
        _attackKeyFor(p.attack.toPlayingCard()),
      );
      final atk = keyRect ??
          durakEstimateAttackLandRect(
            tableCenter: center,
            cardSize: _tableCardSize,
            pairIndex: i,
            pairCount: table.length,
            compact: _fit.compact,
            cols: _tableCols,
          );
      if (p.defense != null) {
        out.add(durakEstimateDefenseLandRect(atk));
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
    Duration flyDuration = const Duration(milliseconds: 280),
    int settleMs = 100,
  }) async {
    if (table.isEmpty || !mounted || !_gameUiActive) return;
    final cards = cardsOverride ?? _flattenTableCards(table);
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    final trump = view != null ? _suitFromApi(view.trumpSuit) : Suit.spades;
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
      await awaitDurakFrame();
    }
    if (!mounted) return;

    final fan = _fanKey.currentState;
    final beginScale = _tableCardSize.width / slotSize.width;
    for (var i = 0; i < cards.length; i++) {
      if (!mounted) return;
      final card = cards[i];
      // Снять со стола в момент старта полёта — остальные ещё лежат.
      onCardLaunch?.call(card);
      final from = fromOverrides != null && i < fromOverrides.length
          ? fromOverrides[i]
          : Rect.fromCenter(
              center: _flyScreen.center(Offset.zero).translate(
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
        // Не ждём settle — следующая карта стартует сразу после долёта.
        await fan.foldCardIn(
          card: card,
          from: from,
          beginScale: beginScale,
          beginAngle: 0,
          endAngle: angle,
          flyDuration: flyDuration,
          settleMs: settleMs,
          awaitSettle: false,
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
      // Лёгкий overlap: следующая почти сразу после handoff.
      if (i + 1 < cards.length) {
        await Future<void>.delayed(const Duration(milliseconds: 36));
      }
    }
    if (mounted) {
      setState(() => _handOrder = merged);
    }
  }

  /// Добор из колоды: слот в веере до полёта.
  ///
  /// [flipToFace] — стартовая раздача (рубашка, потом лицо). Добор передаёт
  /// false: карта летит уже лицом, рубашку в веере не показываем.
  Future<void> _animateDealCardsToFan(
    List<PlayingCard> cards, {
    Duration flyDuration = const Duration(milliseconds: 300),
    int settleMs = 110,
    bool keepFanFreeze = false,

    /// Стартовая раздача: рубашка переворачивается. Добор — уже лицом.
    bool flipToFace = true,
  }) async {
    if (cards.isEmpty || !mounted || !_gameUiActive) return;
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    final trump = view != null ? _suitFromApi(view.trumpSuit) : Suit.spades;

    final serverHand = view != null
        ? _apiCardsToPlaying(
            view.hands.length > view.myIndex && view.myIndex >= 0
                ? (view.hands[view.myIndex].cards ?? const [])
                : const [],
          )
        : const <PlayingCard>[];
    final dealSet = cards.toSet();
    final keepFromServer = [
      for (final c in serverHand)
        if (!dealSet.contains(c)) c,
    ];
    final stillFlying = {..._pendingDealCards}..removeAll(dealSet);
    var order = <PlayingCard>[
      for (final c in (_handOrder ?? const <PlayingCard>[]))
        if (!dealSet.contains(c) &&
            (keepFromServer.contains(c) || _flyingFromHand.contains(c)))
          c,
    ];
    for (final c in keepFromServer) {
      if (!order.contains(c) && !stillFlying.contains(c)) order.add(c);
    }
    _handOrder = List<PlayingCard>.of(order);
    _pendingDealCards.addAll(dealSet);

    final manageBusy = !_busy;
    final destCount = <PlayingCard>{...order, ...cards}.length.clamp(1, 52);
    if (_frozenFanCardSize == null || destCount > (_frozenFanHandCount ?? 0)) {
      final destLay = _handFanVisualLayout(
        destCount,
        MediaQuery.sizeOf(context).width,
      );
      _frozenFanCardSize = destLay.cardSize;
      _frozenFanHandCount = destCount;
    }
    final keepFreeze = keepFanFreeze || _frozenFanCardSize != null;
    setState(() {
      _handOrder = order;
      _fanAnimDuringBusy = true;
      _suppressFanLayoutAnim = false;
      if (!flipToFace) _fanOpenAfterIncoming = true;
      if (manageBusy) _busy = true;
    });
    if (manageBusy) _syncOfflineFxHold();

    try {
      for (var i = 0; i < cards.length; i++) {
        if (!mounted) return;
        final card = cards[i];
        final nextOrder = durakReserveDealFanSlot(
          seated: order,
          incoming: card,
          compare: (a, b) => _compareHandCards(a, b, trump),
        );
        final lay = _handFanVisualLayout(
          nextOrder.length.clamp(1, 52),
          MediaQuery.sizeOf(context).width,
        );
        final deckFrom = _deckDealFromRect(jitter: i * 1.5);
        _consumeDeckFreezeSlot();
        setState(() {
          order = nextOrder;
          _handOrder = nextOrder;
          _pendingDealCards.remove(card);
          _flyingFromHand.add(card);
          if (!keepFreeze) {
            _frozenFanCardSize = lay.cardSize;
            _frozenFanHandCount = nextOrder.length;
          }
        });
        await awaitDurakFrame();
        if (!mounted) return;
        final fan = _fanKey.currentState;
        final idx = nextOrder.indexOf(card);
        final nAll = nextOrder.length;
        final center = (nAll - 1) / 2.0;
        final angle = nAll <= 1 || idx < 0
            ? 0.0
            : (idx - center) * (0.4 / math.max(nAll - 1, 1));
        final slotSize = keepFreeze && _frozenFanCardSize != null
            ? _frozenFanCardSize!
            : lay.cardSize;

        if (!flipToFace) {
          // Слот должен успеть разложиться. Иначе rect (0,0), полёт не виден,
          // а лицо просто появляется в веере — так и было на «Бито».
          await awaitDurakFrame();
          if (!mounted) return;
          final measured = _fanKey.currentState?.globalRectOfCard(card);
          final land = durakDealLandRect(
            measured: measured,
            slotSize: slotSize,
            fallbackCenter: Offset(
              _flyScreen.width / 2,
              _flyScreen.height * 0.82,
            ),
          );
          final from = _deckDealFromRect(jitter: i * 1.6);
          final ticket = await playCardFlyAnimation(
            context: context,
            card: card,
            cardSize: _tableCardSize,
            from: from,
            to: land,
            duration: flyDuration,
            curve: kDurakFlyCurve,
            faceDown: false,
            flipToFace: false,
            beginScale: 1,
            endScale: (land.width / _tableCardSize.width).clamp(0.35, 1.6),
            beginAngle: 0.16,
            endAngle: angle,
            arcLift: 22,
            keepAtEnd: true,
          );
          if (!mounted) {
            ticket.dismiss();
            return;
          }
          setState(() {
            _flyingFromHand.remove(card);
            _incomingFanCards.add(card);
          });
          await awaitDurakFrame();
          ticket.dismiss();
        } else if (fan != null) {
          await fan.foldCardIn(
            card: card,
            from: deckFrom,
            beginScale: _tableCardSize.width / slotSize.width,
            flipToFace: flipToFace,
            beginAngle: 0.16,
            endAngle: angle,
            flyDuration: flyDuration,
            settleMs: settleMs,
            awaitSettle: false,
            onHandoff: () {
              if (!mounted) return;
              setState(() {
                _flyingFromHand.remove(card);
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
        if (i + 1 < cards.length) {
          await Future<void>.delayed(const Duration(milliseconds: 28));
        }
      }
    } finally {
      _pendingDealCards.removeAll(cards);
      _flyingFromHand.removeAll(cards);
      if (manageBusy) {
        _busy = false;
        if (mounted) {
          _releaseFanLayoutSmooth();
        }
        _syncOfflineFxHold();
      } else if (mounted) {
        setState(() {});
      }
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
            _flyScreen.width * 0.88,
            _flyScreen.height * 0.32,
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
                center: _flyScreen.center(Offset.zero).translate(
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
      duration: const Duration(milliseconds: 400),
      stagger: const Duration(milliseconds: 26),
      curve: kDurakFlyCurve,
      beginScale: 1.0,
      endScale: 0.88,
      arcLift: 16,
      keepAtEnd: true,
      onTickets: (t) => tickets = t,
    );
    return tickets;
  }

  void _requestFxReplay() {
    if (!_fxNeedsReplay || !mounted) return;
    if (_tableFxDeferred) return;
    _fxNeedsReplay = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tableFxDeferred) return;
      final v = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
      if (v != null) _maybeRunTableFx(v);
    });
  }

  void _beginTableFx() {
    _fxScheduled = true;
    _syncOfflineFxHold();
  }

  void _markFxDone() {
    _fxScheduled = false;
    _syncOfflineFxHold();
    _requestFxReplay();
  }

  /// Полный сброс FX перед новой раздачей (реванш с ботом на том же экране).
  void _resetTableFxForNewDeal() {
    CardFlyTicket.dismissAll();
    GameFlyOverlay.dismissAll();
    _fanKey.currentState?.cancelActiveGesture();
    _busy = false;
    _turnAction.release();
    _fxScheduled = false;
    _fxNeedsReplay = false;
    _fanAnimDuringBusy = false;
    _suppressFanLayoutAnim = false;
    _flightLockTable = false;
    _flightDefendIdx = null;
    _hidingTable = false;
    _takeTableHold = null;
    _suppressRemoteBitoFx = false;
    _localRoundFx = false;
    _optimisticActionAck = false;
    _optimisticBitoReveal = false;
    _optimisticTake = false;
    _actionPressArmed = false;
    _localAttackIds.clear();
    _optimisticDealBaseline = null;
    _dealFaceDownTail = 0;
    _oppVisualFloor.clear();
    _localRoundPrevLock = false;
    _suppressNextDealFx = false;
    _trumpFaceVisible = true;
    _firstLeadVisible = false;
    _leadRevealHiddenSeat = null;
    _prevDeckCount = -1;
    _prevBitoCount = -1;
    _prevLastWasTake = false;
    _prevHandLen = -1;
    _prevAttackerIndex = -1;
    _prevDefenderIndex = -1;
    _prevTable = const [];
    _lastNonEmptyTable = const [];
    _prevOppHandCounts.clear();
    _oppDealPending.clear();
    _pendingDealCards.clear();
    _flyingFromHand.clear();
    _incomingFanCards.clear();
    _playedAwayCards.clear();
    _flyingToTable.clear();
    _leftTableCards.clear();
    _remoteFlyingCardIds.clear();
    _optimisticAttacks.clear();
    _clearOptimisticDefends();
    _seatedTableCardIds.clear();
    _shownTableCardIds.clear();
    _selected.clear();
    _stopMyTurnIdleHint(clearShown: true);
    _myTurnSince = null;
    _handOrder = null;
    _deckCountFreeze = null;
    _bitoCountFreeze = null;
    _activeCard = null;
    _holdingFanCard = false;
    _dragGlobal = null;
    _frozenFanCardSize = null;
    _frozenFanHandCount = null;
    _prevGameStatus = null;
    _balanceGainPlayed = false;
    _lossChipRevealed = false;
    _midFinishedHandled = false;
    _confettiArmed = false;
    _finishChromeReady = false;
    _finishHoldScheduled = false;
    _frozenTurnHint = null;
    _frozenTurnActorIdx = null;
    _frozenPhase = null;
    _opponentTakeHoldTimer?.cancel();
    _opponentTakeHoldTimer = null;
    _opponentTakeHold = false;
    _opponentTakeArmed = false;
    _fanCloseAfterPlay = false;
    _fanOpenAfterIncoming = false;
    _concealOpeningHand = false;
    _lockedMidDraw = null;
    _lockedMidPlace = null;
    _syncOfflineFxHold();
  }

  void _syncOfflineFxHold() {
    if (!_isOffline) return;
    OfflineDurakRegistry.instance.get(widget.gameId)?.setFxHold(
          _tableFxDeferred,
        );
  }

  /// Запомнить свой отбой в снимке стола — иначе последняя карта сразу уйдёт в биту.
  void _rememberOptimisticTableDefense(int idx, PlayingCard card) {
    final attack = _attackCardAt(idx);
    if (attack == null) return;
    _prevTable = _tableWithDefense(_prevTable, attack, card);
    _lastNonEmptyTable = _tableWithDefense(_lastNonEmptyTable, attack, card);
  }

  DurakApiCard? _attackCardAt(int idx) {
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    if (view != null && idx >= 0 && idx < view.table.length) {
      return view.table[idx].attack;
    }
    if (idx >= 0 && idx < _prevTable.length) return _prevTable[idx].attack;
    if (idx >= 0 && idx < _lastNonEmptyTable.length) {
      return _lastNonEmptyTable[idx].attack;
    }
    return null;
  }

  List<DurakTablePairApi> _tableWithDefense(
    List<DurakTablePairApi> src,
    DurakApiCard attack,
    PlayingCard defense,
  ) {
    var hit = false;
    final next = <DurakTablePairApi>[];
    for (final p in src) {
      if (p.attack.rank == attack.rank && p.attack.suit == attack.suit) {
        hit = true;
        next.add(
          DurakTablePairApi(
            attack: p.attack,
            defense: DurakApiCard.fromCard(defense),
          ),
        );
      } else {
        next.add(p);
      }
    }
    if (!hit) {
      next.add(
        DurakTablePairApi(
          attack: attack,
          defense: DurakApiCard.fromCard(defense),
        ),
      );
    }
    return next;
  }

  bool _tableContainsDefense(
      Iterable<DurakTablePairApi> table, PlayingCard card) {
    for (final pair in table) {
      if (pair.defense?.toPlayingCard() == card) return true;
    }
    return false;
  }

  void _forgetOptimisticDefense(PlayingCard card) {
    List<DurakTablePairApi> strip(List<DurakTablePairApi> src) => [
          for (final p in src)
            if (p.defense?.toPlayingCard() == card)
              DurakTablePairApi(attack: p.attack)
            else
              p,
        ];
    _prevTable = strip(_prevTable);
    _lastNonEmptyTable = strip(_lastNonEmptyTable);
  }

  void _clearOptimisticDefends() {
    _optimisticDefends.clear();
    _optimisticDefendAttack.clear();
  }

  void _retireOptimisticDefenses(DurakGameView? view) {
    if (view == null) return;
    final hand = _myHandOf(view).toSet();
    final drop = <int>[];
    for (final entry in _optimisticDefends.entries) {
      final inRange = entry.key >= 0 && entry.key < view.table.length;
      final attackNow =
          inRange ? view.table[entry.key].attack.toPlayingCard() : null;
      final remembered = _optimisticDefendAttack[entry.key];
      final open = inRange &&
          (view.table[entry.key].defense == null ||
              view.table[entry.key].defense!.toPlayingCard() == entry.value);
      final retired = durakOptimisticDefenseRetires(
        serverHasDefense: _tableContainsDefense(view.table, entry.value),
        attackStillOpen: open &&
            view.table[entry.key].defense?.toPlayingCard() != entry.value,
      );
      final stillInHand = hand.contains(entry.value) &&
          !_playedAwayCards.contains(entry.value) &&
          !_flyingFromHand.contains(entry.value);
      if (durakDropOptimisticDefense(
        retired: retired,
        attackMatches: remembered != null &&
            attackNow != null &&
            remembered == attackNow,
        cardStillInHand: stillInHand,
      )) {
        drop.add(entry.key);
      }
    }
    for (final i in drop) {
      _optimisticDefends.remove(i);
      _optimisticDefendAttack.remove(i);
    }
  }

  bool _tableHasAttack(DurakGameView? view, PlayingCard card) {
    if (view == null) return false;
    for (final pair in view.table) {
      if (pair.attack.toPlayingCard() == card) return true;
    }
    return false;
  }

  /// Подкид остаётся на столе, пока сервер его не подтвердил.
  void _releaseOptimisticAttacksNowOnTable(DurakGameView view) {
    if (_optimisticAttacks.isEmpty) return;
    final done = <PlayingCard>[
      for (final card in _optimisticAttacks)
        if (_tableHasAttack(view, card)) card,
    ];
    for (final card in done) {
      _seatTableCard(card);
      _optimisticAttacks.remove(card);
      _flyingToTable.remove(card);
    }
  }

  void _pinSeatedDefense(int idx, PlayingCard card) {
    final attack = _attackCardAt(idx);
    if (attack == null) return;
    _prevTable = _tableWithDefense(_prevTable, attack, card);
    if (_lastNonEmptyTable.isNotEmpty || _prevTable.isNotEmpty) {
      _lastNonEmptyTable = _tableWithDefense(
        _lastNonEmptyTable.isEmpty ? _prevTable : _lastNonEmptyTable,
        attack,
        card,
      );
    }
  }

  /// Пустой стол после авто-биты/взятия: держим снимок, пока busy не отдаст FX.
  void _holdClosedRoundTable(DurakGameView view) {
    if (_takeTableHold != null || view.table.isNotEmpty) return;
    if (_lastNonEmptyTable.isEmpty) return;
    final bitoGrew = _prevBitoCount >= 0 && view.bitoCount > _prevBitoCount;
    final takeJust = view.lastWasTake && !_prevLastWasTake;
    if (!bitoGrew && !takeJust) return;
    _takeTableHold = List.of(_lastNonEmptyTable);
  }

  bool _isRemoteTableCardHidden(PlayingCard card) {
    return durakShouldHideRemoteTableCard(
      markedRemoteFlying: _remoteFlyingCardIds.contains(_cardId(card)),
      seated: _isSeatedTableCard(card),
      optimistic: _optimisticAttacks.contains(card) ||
          _optimisticDefends.containsValue(card),
      localFlying: _flyingToTable.contains(card),
      alreadyShown: _wasShownOnTable(card),
    );
  }

  void _seatHiddenRemoteCardsFrom(Iterable<DurakTablePairApi> table) {
    for (final pair in table) {
      final attack = pair.attack.toPlayingCard();
      if (_remoteFlyingCardIds.contains(_cardId(attack))) {
        _seatTableCard(attack);
      }
      final defense = pair.defense?.toPlayingCard();
      if (defense != null && _remoteFlyingCardIds.contains(_cardId(defense))) {
        _seatTableCard(defense);
      }
    }
  }

  /// Если карту прятали как remote, но она уже своя/сидит/была на prev — показать.
  void _reconcileHiddenRemoteTableCards(DurakGameView view) {
    if (_remoteFlyingCardIds.isEmpty) return;
    final reveal = <String>{};
    for (final p in view.table) {
      final attack = p.attack.toPlayingCard();
      if (durakShouldRevealDeferredRemoteCard(
        hiddenAsRemote: _remoteFlyingCardIds.contains(_cardId(attack)),
        seated: _isSeatedTableCard(attack),
        optimistic: _optimisticAttacks.contains(attack),
        localFlying: _flyingToTable.contains(attack),
        alreadyShown: _wasShownOnTable(attack),
      )) {
        reveal.add(_cardId(attack));
        _seatTableCard(attack);
      }
      final def = p.defense?.toPlayingCard();
      if (def == null) continue;
      if (durakShouldRevealDeferredRemoteCard(
        hiddenAsRemote: _remoteFlyingCardIds.contains(_cardId(def)),
        seated: _isSeatedTableCard(def),
        optimistic: _optimisticDefends.containsValue(def),
        localFlying: _flyingToTable.contains(def),
        alreadyShown: _wasShownOnTable(def),
      )) {
        reveal.add(_cardId(def));
        _seatTableCard(def);
      }
    }
    _remoteFlyingCardIds.removeAll(reveal);
  }

  /// Пока локальная бита летит, новые карты с сервера не вспыхивают в веерах.
  void _hideOptimisticIncoming(DurakGameView view) {
    final baseline = _optimisticDealBaseline;
    if (baseline != null &&
        view.myIndex >= 0 &&
        view.myIndex < view.hands.length) {
      final hand =
          _apiCardsToPlaying(view.hands[view.myIndex].cards ?? const []);
      for (final card in hand) {
        if (baseline.contains(card)) continue;
        // Уже села в веер — не прятать и не запускать добор заново.
        if (_incomingFanCards.contains(card)) continue;
        // Уже летит лицом в свой слот — не прятать снова, иначе дырка пропадает.
        if (_flyingFromHand.contains(card)) continue;
        // Даже если карта уже попала в порядок веера: пока не долетела,
        // лицо не показываем. Иначе «Бито» вспыхивает картами без полёта.
        _pendingDealCards.add(card);
      }
    }
    final deltas = _opponentDealDeltas(view);
    if (deltas.isEmpty) return;
    _armOppDealPending(deltas);
    _syncPrevOppHandCounts(view);
  }

  /// Чужой отбой прячем до полёта, чтобы атака не моргнула при смене хода.
  void _concealUnseenDefenses(Iterable<DurakTablePairApi> table) {
    for (final pair in table) {
      final defense = pair.defense?.toPlayingCard();
      if (defense == null) continue;
      if (_wasShownOnTable(defense) || _isSeatedTableCard(defense)) continue;
      if (_optimisticDefends.containsValue(defense)) continue;
      if (_flyingFromHand.contains(defense)) continue;
      if (_remoteFlyingCardIds.contains(_cardId(defense))) continue;
      final previous = _pairOnTable(_prevTable, pair);
      if (previous?.defense != null) continue;
      _markRemoteTableCardFlying(defense);
    }
  }

  /// Новые чужие карты уже в view, а полёт ещё не стартовал — слот opacity 0.
  void _hideNewRemoteTableCards(
    DurakGameView view, {
    List<DurakTablePairApi>? knownTable,
  }) {
    final prev = knownTable ?? _prevTable;
    final remoteAttacker = durakRemoteAttackFromSeat(
      attackerIndex: view.attackerIndex,
      throwerIndex: view.throwerIndex,
    );
    for (final p in view.table) {
      final attack = p.attack.toPlayingCard();
      final existed = _pairAttackExistedOn(prev, p);
      if (remoteAttacker != view.myIndex &&
          durakHideDeferredRemoteAttack(
            existedOnPrevTable: existed,
            optimistic: _optimisticAttacks.contains(attack),
            localFlying: _flyingToTable.contains(attack),
            fxDeferred: true,
            seated: _isSeatedTableCard(attack),
            alreadyShown: _wasShownOnTable(attack),
            locallyCommitted: _localAttackIds.contains(_cardId(attack)),
          )) {
        _remoteFlyingCardIds.add(_cardId(attack));
      }
      final def = p.defense?.toPlayingCard();
      if (def == null) continue;
      final old = _pairOnTable(prev, p);
      final existedDefense = old?.defense != null;
      if (!durakTableCardAlreadyVisible(
            seated: _isSeatedTableCard(def),
            existedOnKnownTable: existedDefense,
            alreadyShown: _wasShownOnTable(def),
          ) &&
          view.defenderIndex != view.myIndex &&
          !_optimisticDefends.containsValue(def) &&
          !_flyingToTable.contains(def)) {
        _remoteFlyingCardIds.add(_cardId(def));
      }
    }
  }

  Future<void> _waitForTableLandings({int timeoutMs = 5000}) async {
    var flyWaitMs = 0;
    while (mounted && flyWaitMs < timeoutMs) {
      if (durakTableReadyForBitoFlight(
        remoteFlying: _remoteFlyingCardIds.isNotEmpty,
        localFlyingToTable: _flyingToTable.isNotEmpty,
        defendLock: _flightLockTable,
        flyingFromHand: _flyingFromHand.isNotEmpty,
      )) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 40));
      flyWaitMs += 40;
    }
    if (_remoteFlyingCardIds.isNotEmpty) {
      _seatHiddenRemoteCardsFrom(_lastNonEmptyTable);
      _remoteFlyingCardIds.clear();
    }
  }

  /// Снимок стола для ухода в биту: предпочитаем вариант с защитами.
  List<DurakTablePairApi> _tableForBitoHold(List<DurakTablePairApi> snapshot) {
    final last = _lastNonEmptyTable;
    if (last.isEmpty) return snapshot;
    if (snapshot.isEmpty) return List.of(last);
    final snapDef = snapshot.where((p) => p.defense != null).length;
    final lastDef = last.where((p) => p.defense != null).length;
    if (lastDef > snapDef) return List.of(last);
    if (last.length > snapshot.length) return List.of(last);
    return snapshot;
  }

  void _maybeRunTableFx(DurakGameView view) {
    _retireOptimisticDefenses(view);
    _releaseOptimisticAttacksNowOnTable(view);
    // Локальная бита/добор уже на экране. Не съедаем prev и не стартуем второй FX.
    if (_suppressRemoteBitoFx || _localRoundFx) {
      _fxNeedsReplay = true;
      _hideOptimisticIncoming(view);
      return;
    }
    if (_holdOrAdoptLocalRound(view)) return;
    final knownTable = _prevTable.isNotEmpty ? _prevTable : _lastNonEmptyTable;
    // Пустой кадр между ходами не должен забывать уже лежащие карты:
    // иначе свой подкид гаснет и прилетает второй раз.
    final bitoGrewNow = _prevBitoCount >= 0 && view.bitoCount > _prevBitoCount;
    // lastWasTake живёт весь следующий заход. Пустой кадр тогда — не взятие.
    final takeJust = view.lastWasTake && !_prevLastWasTake;
    // Снимок «уже показывали» до очистки seated: иначе последний отбой
    // считается невидимым и пауза перед битой удваивается.
    final visibleBefore = <String>{
      ..._shownTableCardIds,
      ..._seatedTableCardIds,
    };
    final keepEmptyTable = view.table.isEmpty &&
        (durakRetainTableAcrossEmptyFrame(
              bitoGrew: bitoGrewNow,
              lastWasTake: takeJust,
              tableReveal: view.isTableReveal,
              hidingTable: _hidingTable,
            ) ||
            durakKeepSeatedAcrossStaleEmpty(
              seatedCount: _seatedTableCardIds.length,
              bitoGrew: bitoGrewNow,
              takeJustResolved: takeJust,
              tableReveal: view.isTableReveal,
              hidingTable: _hidingTable,
            ));
    if (view.table.isNotEmpty) {
      _lastNonEmptyTable = List.of(view.table);
      if (_firstLeadVisible) _firstLeadVisible = false;
      // Уже лежавшие карты помечаем севшими до любого нового полёта.
      _seatTablePairs(knownTable);
      _pruneShownTableCards(view.table);
    } else if (!keepEmptyTable &&
        durakShouldClearSeatedOnEmptyTable(
          hidingTable: _hidingTable,
          takeHold: _takeTableHold != null,
          localPlayActive: _localPlayActive,
        )) {
      _clearSeatedTableCards();
    }
    _reconcileHiddenRemoteTableCards(view);
    // Не глотать отбой/биту во время своего полёта — запомним стол и переиграем.
    if (_tableFxDeferred) {
      _fxNeedsReplay = true;
      // Чужие карты уже в view — прячем до полёта, иначе вспышка на столе.
      _hideNewRemoteTableCards(view, knownTable: knownTable);
      _seatUnhiddenTableCards(view.table);
      _holdClosedRoundTable(view);
      // Уже видимые карты оставляем в prev: иначе свой перевод примет
      // весь стол за новые remote и погасит слоты.
      if (!keepEmptyTable) {
        _prevTable = [
          for (final p in view.table)
            if (durakKeepVisibleCardInPrevTable(
              remoteFlying: _remoteFlyingCardIds.contains(
                _cardId(p.attack.toPlayingCard()),
              ),
              seated: _isSeatedTableCard(p.attack.toPlayingCard()),
              alreadyShown: _wasShownOnTable(p.attack.toPlayingCard()),
            ))
              _pairRememberedForPrev(p),
        ];
        _retainLocalAttacksInPrev();
        _forgetFinishedLocalAttacks(view);
      }
      _dropGhostTableOnFreshAttack(
        view,
        bitoGrew: bitoGrewNow,
        takeJust: takeJust,
      );
      return;
    }
    if (!_gameUiActive) {
      // Вне экрана — не затираем «первый кадр», иначе пропадёт раздача.
      if (_prevDeckCount < 0) {
        if (!view.isOver) {
          final concealHand = _apiCardsToPlaying(
            view.hands.length > view.myIndex && view.myIndex >= 0
                ? (view.hands[view.myIndex].cards ?? const [])
                : const [],
          );
          if (_shouldAnimateOpeningDeal(view, concealHand.length)) {
            _armOpeningDealConceal(view, concealHand);
          }
        }
        return;
      }
      final handLen = view.hands.length > view.myIndex && view.myIndex >= 0
          ? (view.hands[view.myIndex].cards?.length ??
              view.hands[view.myIndex].count)
          : 0;
      _prevDeckCount = view.deckCount;
      _prevBitoCount = view.bitoCount;
      _prevLastWasTake = view.lastWasTake;
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

    // Первый кадр: стартовая раздача или просто запомнить базу.
    // Завершённую партию не считаем «первым кадром» — иначе реванш
    // съедает флаг, пока провайдер ещё отдаёт старый isOver.
    if (_prevDeckCount < 0) {
      if (view.isOver) return;
      if (_shouldAnimateOpeningDeal(view, handLen)) {
        _scheduleOpeningDeal(view, hand);
        return;
      }
      // Порядок веера обязан быть до любого FX — иначе remain/pending съедают руку.
      if (_pendingDealCards.isEmpty) {
        _seedHandOrderIfEmpty(hand);
      }
      _prevDeckCount = deck;
      _prevBitoCount = bito;
      _prevLastWasTake = view.lastWasTake;
      _prevHandLen = handLen;
      _prevTable = List.of(view.table);
      _prevAttackerIndex = view.attackerIndex;
      _prevDefenderIndex = view.defenderIndex;
      _syncPrevOppHandCounts(view);
      _seatTablePairs(view.table);
      if (view.firstRound && view.table.isEmpty && !view.isOver) {
        _firstLeadVisible = true;
      }
      return;
    }

    // Порядок веера обязан быть до любого FX — иначе remain/pending съедают руку.
    if (_pendingDealCards.isEmpty && !_fxScheduled) {
      _seedHandOrderIfEmpty(hand);
    }

    final dealt = handLen - _prevHandLen;
    final deckDropped = _prevDeckCount - deck;
    final prevBito = _prevBitoCount;
    final prevDeck = _prevDeckCount;
    final prevTableSnapshot = List<DurakTablePairApi>.of(_prevTable);
    final bitoGrew = bito > prevBito &&
        (prevTableSnapshot.isNotEmpty || _lastNonEmptyTable.isNotEmpty);
    // Бита: можно обогатить снимок защитами из lastNonEmpty.
    // Take: prev, либо один раз lastNonEmpty (если busy проглотил prev) — потом чистим.
    final List<DurakTablePairApi> tableSnapshot;
    if (bitoGrew) {
      tableSnapshot = _tableForBitoHold(prevTableSnapshot);
    } else if (prevTableSnapshot.isNotEmpty) {
      tableSnapshot = prevTableSnapshot;
    } else if (view.table.isEmpty &&
        takeJust &&
        _lastNonEmptyTable.isNotEmpty) {
      tableSnapshot = List<DurakTablePairApi>.of(_lastNonEmptyTable);
    } else {
      tableSnapshot = const [];
    }
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
        takeJust;
    final remoteTake = takeResolved && refillDefender != view.myIndex;
    final localTakeResolved = takeResolved && refillDefender == view.myIndex;

    _prevDeckCount = deck;
    _prevBitoCount = bito;
    _prevLastWasTake = view.lastWasTake;
    _prevHandLen = handLen;
    // Невидимый отбой не помечаем «уже был» — иначе смена хода его проглотит.
    // Пустой промежуточный кадр стол не затирает: подкид иначе моргает.
    if (!keepEmptyTable) {
      _prevTable = [
        for (final p in view.table) _pairRememberedForPrev(p),
      ];
      _retainLocalAttacksInPrev();
      _forgetFinishedLocalAttacks(view);
    }
    _prevAttackerIndex = view.attackerIndex;
    _prevDefenderIndex = view.defenderIndex;
    _syncPrevOppHandCounts(view);
    // Сразу очистить — иначе _fxNeedsReplay снова увидит «непустой стол» и зациклит take.
    if ((remoteTake || localTakeResolved || bitoGrew) && view.table.isEmpty) {
      _lastNonEmptyTable = const [];
    }
    _dropGhostTableOnFreshAttack(
      view,
      bitoGrew: bitoGrew,
      takeJust: takeJust,
    );

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
      if (incoming.isNotEmpty) {
        _concealDrawnUntilFlight(incoming);
      }
      _beginTableFx();
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
      // Hold синхронно — этот же build ещё рисует стол.
      _takeTableHold = tableSnapshot;
      _leftTableCards.clear();
      // Стол + добор из колоды: оба скрыты, пока не долетят.
      _oppDealPending[taker] = (_oppDealPending[taker] ?? 0) + takenN;
      _armOppDealPending(oppDealsDeck);
      _armDeckFreeze(prevDeck);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          _markFxDone();
          return;
        }
        await _pauseBeforeLastTrickLeaves(
          tableSnapshot,
          view,
          visibleBefore,
        );
        if (!mounted) {
          _markFxDone();
          return;
        }
        await _animateTableToOpponentFan(tableSnapshot, taker);
        if (!mounted) {
          _markFxDone();
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
        if (mounted) _markFxDone();
      });
      return;
    }

    // Я забрал стол (после подкида вдогонку) — карты со стола в мой веер.
    if (localTakeResolved) {
      // Защита, которая всё ещё в веере, — ложный отбой. Её не забираем.
      final fanBefore = <PlayingCard>{...?_handOrder};
      final takeTable = <DurakTablePairApi>[
        for (final pair in tableSnapshot)
          DurakTablePairApi(
            attack: pair.attack,
            defense: pair.defense != null &&
                    fanBefore.contains(pair.defense!.toPlayingCard())
                ? null
                : pair.defense,
          ),
      ];
      final taken = <PlayingCard>[];
      final seenTaken = <PlayingCard>{};
      for (final card in _flattenTableCardsTopFirst(takeTable)) {
        if (fanBefore.contains(card) || !seenTaken.add(card)) continue;
        taken.add(card);
      }
      final takenSet = taken.toSet();
      // Добор = новые карты руки минус взятые со стола.
      final dealtOnly = [
        for (final c in incoming)
          if (!takenSet.contains(c)) c,
      ];
      if (dealtOnly.isNotEmpty) {
        _concealDrawnUntilFlight(dealtOnly);
      }
      _armOppDealPending(oppDeals);
      _beginTableFx();
      // Hold + порядок веера синхронно — без кадра пустого стола.
      _takeTableHold = takeTable;
      _leftTableCards.clear();
      _suppressNextDealFx = true;
      if (taken.isNotEmpty) {
        final base = _handOrder ??
            [
              for (final c in hand)
                if (!takenSet.contains(c)) c,
            ];
        _handOrder = [
          ...base.where((c) => !takenSet.contains(c)),
          ...taken,
        ];
        _flyingFromHand.addAll(taken);
        _incomingFanCards.addAll(taken);
        _unmarkPlayedAway(taken);
      }
      _armDeckFreeze(prevDeck);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          _markFxDone();
          return;
        }
        await _pauseBeforeLastTrickLeaves(
          tableSnapshot,
          view,
          visibleBefore,
        );
        if (!mounted) {
          _markFxDone();
          return;
        }
        // froms после кадра с hold — ключи ещё на месте.
        final froms = _tableCardGlobalRectsTopFirst(takeTable);
        if (takeTable.isNotEmpty && _gameUiActive) {
          await _animateTableToFan(
            takeTable,
            fromOverrides: froms,
            cardsOverride: taken,
            onCardLaunch: (card) {
              if (!mounted) return;
              setState(() => _leftTableCards.add(card));
            },
          );
        }
        if (!mounted) {
          _markFxDone();
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
          _markFxDone();
        }
      });
      return;
    }

    // Сначала бито (в т.ч. авто после пустой руки), потом добор — иначе
    // дельта руки проглотит анимацию стола в отбой.
    if (bitoGrew && !_hidingTable && !_suppressRemoteBitoFx) {
      if (incoming.isNotEmpty) {
        _concealDrawnUntilFlight(incoming);
      }
      // Скрыть добор соперников на время биты — не мелькать до колоды.
      _armOppDealPending(oppDeals);
      _beginTableFx();
      // Держим снимок стола в ЭТОМ кадре — иначе пустой стол до post-frame
      // и полёт стартует из «центра экрана».
      _takeTableHold = tableSnapshot;
      _bitoCountFreeze = prevBito;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          _pendingDealCards.clear();
          _takeTableHold = null;
          _bitoCountFreeze = null;
          _markFxDone();
          return;
        }
        // Дождаться посадки своего и чужого отбоя, затем пауза — видно чем отбились.
        // Таймаут — иначе застрявший id глушит биту и бота навсегда.
        await _waitForTableLandings();
        if (!mounted) {
          _markFxDone();
          return;
        }
        final defensesVisible = tableSnapshot.isEmpty ||
            tableSnapshot.every((p) {
              final defense = p.defense?.toPlayingCard();
              if (defense == null) return true;
              final id = _cardId(defense);
              return visibleBefore.contains(id) ||
                  _wasShownOnTable(defense) ||
                  _isSeatedTableCard(defense);
            });
        await Future<void>.delayed(durakPauseBeforeBitoFlight(
          defensesAlreadyVisible: defensesVisible,
          gameEnding: view.isOver,
        ));
        if (!mounted) {
          _markFxDone();
          return;
        }
        // Ключи ещё живы благодаря hold — снимаем точные from.
        final froms = _tableCardGlobalRects(tableSnapshot);
        final flown = _flattenTableCards(tableSnapshot).length;
        setState(() {
          _hidingTable = true;
        });
        final tickets = await _animateTableToBito(
          tableSnapshot,
          fromOverrides: froms,
        );
        if (mounted) {
          setState(() {
            _bitoCountFreeze = prevBito + flown;
          });
          await awaitDurakFrame();
        }
        for (final t in tickets) {
          t.dismiss();
        }
        if (mounted) {
          setState(() {
            _hidingTable = false;
            _takeTableHold = null;
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
          _markFxDone();
        } else {
          _markFxDone();
        }
      });
    } else if (dealt > 0 && deckDropped > 0) {
      if (_suppressNextDealFx) {
        _suppressNextDealFx = false;
        // Свой добор уже/будет в take — только соперники, в порядке атаки.
        if (oppDeals.isNotEmpty) {
          _armOppDealPending(oppDeals);
          _beginTableFx();
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) {
              _markFxDone();
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
            if (mounted) _markFxDone();
          });
        }
      } else {
        if (incoming.isNotEmpty) {
          _concealDrawnUntilFlight(incoming);
        }
        _armOppDealPending(oppDeals);
        _beginTableFx();
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) {
            _pendingDealCards.clear();
            _markFxDone();
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
            _markFxDone();
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
      if (incoming.isNotEmpty) {
        _concealDrawnUntilFlight(incoming);
      }
      _armOppDealPending(oppDeals);
      _beginTableFx();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          _pendingDealCards.clear();
          _markFxDone();
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
          _markFxDone();
        }
      });
    } else if (!_hidingTable && !_fxScheduled) {
      // Ход соперника: карта летит из его веера на стол / в отбой.
      _seedHandOrderIfEmpty(hand);
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

  /// Скрыть добор в веере соперника до полёта из колоды (тот же build, до paint).
  void _armOppDealPending(Map<int, int> deals) {
    for (final e in deals.entries) {
      if (e.value <= 0) continue;
      _oppDealPending[e.key] = (_oppDealPending[e.key] ?? 0) + e.value;
    }
  }

  /// Подстраховка: pending не меньше ожидаемого добора (без двойного сложения).
  void _ensureOppDealPending(Map<int, int> deals) {
    for (final e in deals.entries) {
      if (e.value <= 0) continue;
      final cur = _oppDealPending[e.key] ?? 0;
      if (cur < e.value) {
        _oppDealPending[e.key] = e.value;
      }
    }
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
    return [
      for (var i = 0; i < playerCount; i++)
        if ((atk + i) % playerCount != def) (atk + i) % playerCount,
      if (def != atk) def,
    ];
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
            _flyScreen.width * 0.12,
            _flyScreen.height * 0.42,
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
    return shouldAnimateDurakOpeningDeal(
      isOver: view.isOver,
      tableIsEmpty: view.table.isEmpty,
      bitoCount: view.bitoCount,
      myIndex: view.myIndex,
      myHandLen: myHandLen,
      handCounts: [for (final h in view.hands) h.count],
      deckSize: view.deckSize,
      deckCount: view.deckCount,
    );
  }

  /// Спрятать стартовую руку до посадки с колоды (и до готовности overlay).
  void _armOpeningDealConceal(DurakGameView view, List<PlayingCard> myHand) {
    _concealOpeningHand = true;
    _handOrder = <PlayingCard>[];
    _pendingDealCards
      ..clear()
      ..addAll(myHand);
    _oppDealPending.clear();
    for (var i = 0; i < view.hands.length; i++) {
      if (i != view.myIndex) {
        _oppDealPending[i] = view.hands[i].count;
      }
    }
    _deckCountFreeze = view.deckSize;
    _trumpFaceVisible = false;
  }

  Future<bool> _waitForGameUiActive({int timeoutMs = 2500}) async {
    var waited = 0;
    while (mounted && !_gameUiActive && waited < timeoutMs) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      waited += 40;
    }
    return mounted && _gameUiActive;
  }

  void _scheduleOpeningDeal(DurakGameView view, List<PlayingCard> myHand) {
    if (_fxScheduled) return;
    _beginTableFx();
    // Без setState: вызываемся из build (_maybeRunTableFx). Поля читает
    // этот же кадр — карты уже скрыты, колода «полная», пока летят.
    _busy = true;
    _fanAnimDuringBusy = true;
    _suppressFanLayoutAnim = false;
    _armOpeningDealConceal(view, myHand);
    _freezeOpeningDealFan(myHand.length);
    // База — финальное состояние сервера, чтобы не перезапустить FX.
    _prevDeckCount = view.deckCount;
    _prevBitoCount = view.bitoCount;
    _prevLastWasTake = view.lastWasTake;
    _prevHandLen = myHand.length;
    _prevTable = List.of(view.table);
    _prevAttackerIndex = view.attackerIndex;
    _prevDefenderIndex = view.defenderIndex;
    _syncPrevOppHandCounts(view);
    _syncOfflineFxHold();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _markFxDone();
        return;
      }
      try {
        await _animateOpeningDeal(view, myHand);
      } finally {
        if (mounted) {
          setState(() {
            _busy = false;
            _fanAnimDuringBusy = false;
            _suppressFanLayoutAnim = true;
            _trumpFaceVisible = true;
            _firstLeadVisible = true;
            _concealOpeningHand = false;
            _pendingDealCards.clear();
            _incomingFanCards.clear();
            _oppDealPending.clear();
            _deckCountFreeze = null;
            if (_handOrder == null || _handOrder!.isEmpty) {
              _handOrder = List<PlayingCard>.of(myHand);
            }
          });
          _releaseFanLayoutSnap();
          OfflineDurakRegistry.instance.get(widget.gameId)?.markDealReady();
        }
        _markFxDone();
      }
    });
  }

  /// Раздача по одной: с соперника по часовой, затем козырь под колоду.
  Future<void> _animateOpeningDeal(
    DurakGameView view,
    List<PlayingCard> myHand,
  ) async {
    if (!mounted) return;
    if (!await _waitForGameUiActive()) return;
    await awaitDurakFrame();
    if (!mounted || !_gameUiActive) return;

    final n = view.hands.length;
    const handSize = 6;
    // По часовой на экране: я снизу → следующий слева (над колодой) → дальше.
    final start = (view.myIndex + 1) % n;
    final seatOrder = List<int>.generate(n, (i) => (start + i) % n);
    final myCards = List<PlayingCard>.of(myHand);
    var myIdx = 0;

    // Стартовая раздача — быстрее обычного добора, в альбоме не короче 220 ms.
    final fly = durakDealFlyDuration(compact: _fit.compact);
    const settle = 70;
    const gap = Duration(milliseconds: 10);

    for (var round = 0; round < handSize; round++) {
      for (final seat in seatOrder) {
        if (!mounted || !_gameUiActive) return;
        if (seat == view.myIndex) {
          if (myIdx >= myCards.length) continue;
          await _animateDealCardsToFan(
            [myCards[myIdx]],
            flyDuration: fly,
            settleMs: settle,
            keepFanFreeze: true,
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
    await _animateTrumpHuntDeals(view, myCards, myIdx);
    if (!mounted || !_gameUiActive) return;
    await _animateTrumpReveal(view);
    if (!mounted || !_gameUiActive) return;
    await _animateFirstLead(view, myHand);
  }

  /// Если после раздачи козыря ни у кого не было — добор по одной из колоды.
  Future<void> _animateTrumpHuntDeals(
    DurakGameView view,
    List<PlayingCard> myCards,
    int myIdx,
  ) async {
    final extras = [
      for (final h in view.hands) (h.count - 6).clamp(0, 99),
    ];
    if (extras.every((e) => e <= 0)) return;
    final fly = durakDealFlyDuration(compact: _fit.compact);
    const settle = 70;
    const gap = Duration(milliseconds: 10);
    while (extras.any((e) => e > 0)) {
      for (var seat = 0; seat < extras.length; seat++) {
        if (extras[seat] <= 0) continue;
        extras[seat]--;
        if (!mounted || !_gameUiActive) return;
        if (seat == view.myIndex) {
          if (myIdx >= myCards.length) continue;
          await _animateDealCardsToFan(
            [myCards[myIdx]],
            flyDuration: fly,
            settleMs: settle,
            keepFanFreeze: true,
          );
          myIdx++;
        } else {
          await _animateDealToOpponent(seat, 1, flyDuration: fly);
        }
        if (!mounted) return;
        await Future<void>.delayed(gap);
      }
    }
  }

  /// Кто ходит первым: вскрыть младший козырь из веера и подпись.
  Future<void> _animateFirstLead(
    DurakGameView view,
    List<PlayingCard> myHand,
  ) async {
    if (!mounted || !_gameUiActive) return;
    final trump = _suitFromApi(view.trumpSuit);
    final lead = view.leadTrump?.toPlayingCard() ??
        (view.attackerIndex == view.myIndex
            ? lowestTrumpInHand(myHand, trump)
            : null);
    final iGo = view.attackerIndex == view.myIndex;
    final oppSeat = iGo ? null : view.attackerIndex;

    setState(() {
      _firstLeadVisible = true;
      _leadRevealHiddenSeat = oppSeat;
      if (iGo && lead != null) _flyingFromHand.add(lead);
    });
    await awaitDurakFrame();
    if (!mounted) return;
    await awaitDurakFrame();
    if (!mounted || !_gameUiActive) return;

    if (lead != null) {
      final from = iGo
          ? (_fanKey.currentState?.globalRectOfCard(lead) ??
              globalRectOf(_fanKey) ??
              Rect.fromCenter(
                center: Offset(
                  _flyScreen.width / 2,
                  _flyScreen.height * 0.78,
                ),
                width: _handCardSize.width,
                height: _handCardSize.height,
              ))
          : (oppSeat != null
                  ? globalRectOf(
                      _oppFanKeys.putIfAbsent(oppSeat, GlobalKey.new),
                    )
                  : null) ??
              Rect.fromCenter(
                center: Offset(
                  _flyScreen.width / 2,
                  _flyScreen.height * 0.18,
                ),
                width: _tableCardSize.width * 0.5,
                height: _tableCardSize.height * 0.5,
              );
      final lift = iGo ? -from.height * 0.62 : from.height * 0.95;
      final to = Rect.fromCenter(
        center: from.center.translate(0, lift),
        width: _tableCardSize.width,
        height: _tableCardSize.height,
      );
      final ticket = await playCardFlyAnimation(
        context: context,
        card: lead,
        cardSize: _tableCardSize,
        from: from,
        to: to,
        duration: const Duration(milliseconds: 420),
        curve: kDurakFlyCurve,
        faceDown: !iGo,
        flipToFace: !iGo,
        beginScale: iGo ? from.width / _tableCardSize.width : 0.7,
        endScale: 1,
        beginAngle: iGo ? 0.08 : 0.18,
        endAngle: 0,
        arcLift: iGo ? 16 : 28,
        keepAtEnd: true,
        playSfx: iGo,
      );
      if (!mounted) {
        ticket.dismiss();
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 700));
      ticket.dismiss();
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 450));
    }

    if (!mounted) return;
    setState(() {
      _leadRevealHiddenSeat = null;
      if (lead != null) _flyingFromHand.remove(lead);
    });
  }

  /// Вытащить козырь из колоды и положить под стопку (поворот лицом).
  Future<void> _animateTrumpReveal(DurakGameView view) async {
    if (!mounted || !_gameUiActive) return;
    final trump = view.trumpCard.toPlayingCard();
    final from = _deckDealFromRect();
    final peek = durakPilesPeekOffEdge(compact: _fit.compact);
    final trumpLeft = durakDeckTrumpLeft(
      cardSize: _tableCardSize,
      peekOffEdge: peek,
    );
    final to = Rect.fromCenter(
      center: Offset(
        from.left + trumpLeft + _tableCardSize.width / 2,
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
      curve: kDurakFlyCurve,
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

  /// Добор после биты/взятия.
  ///
  /// Свои карты летят из колоды лицом. Соперникам по-прежнему летят рубашки.
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
    final oppTotal = oppDeals.values.fold<int>(0, (a, b) => a + b);
    if ((myCards.isEmpty && oppTotal == 0) || !mounted || !_gameUiActive) {
      return;
    }

    // Pending соперников выставляется вызывающим в том же build (до paint),
    // иначе кадр: карты появились → исчезли → летят из колоды.
    _ensureOppDealPending(oppDeals);
    setState(() {
      if (myCards.isNotEmpty) {
        _concealDrawnUntilFlight(myCards);
      }
      if (deckCountBefore != null) {
        _armDeckFreeze(deckCountBefore);
      }
    });

    final order = _refillDealOrder(
      attacker: refillAttacker,
      defender: refillDefender,
      playerCount: view.hands.length,
    );
    var dealtMine = false;
    for (final idx in order) {
      if (!mounted || !_gameUiActive) {
        _pendingDealCards.removeAll(myCards);
        return;
      }
      if (idx == view.myIndex) {
        if (dealtMine || myCards.isEmpty) continue;
        dealtMine = true;
        await awaitDurakFrame();
        if (!mounted || !_gameUiActive) {
          _pendingDealCards.removeAll(myCards);
          return;
        }
        await _animateDealCardsToFan(
          myCards,
          flyDuration: durakDealFlyDuration(compact: _fit.compact),
          settleMs: 70,
          keepFanFreeze: true,
          flipToFace: false,
        );
        continue;
      }
      final n = oppDeals[idx] ?? 0;
      if (n <= 0) continue;
      await _animateDealToOpponent(idx, n);
    }
    if (!dealtMine && myCards.isNotEmpty && mounted && _gameUiActive) {
      await _animateDealCardsToFan(
        myCards,
        flyDuration: durakDealFlyDuration(compact: _fit.compact),
        settleMs: 70,
        keepFanFreeze: true,
        flipToFace: false,
      );
    }
    if (mounted) {
      _pendingDealCards.removeAll(myCards);
      _dealFaceDownTail = 0;
      _clearDeckCountFreeze();
      if (myCards.isNotEmpty) _releaseFanLayoutSmooth();
    }
  }

  /// Стол → веер соперника (когда он «взял»).
  Future<void> _animateTableToOpponentFan(
    List<DurakTablePairApi> table,
    int oppIdx,
  ) async {
    if (table.isEmpty || !mounted || !_gameUiActive) return;
    final cards = _flattenTableCardsTopFirst(table);
    // Геометрию снимаем ДО скрытия карт — иначе полёт из «дырки».
    final froms = _tableCardGlobalRectsTopFirst(table);
    final screen = _flyScreen;
    final toKey = _oppFanKeys.putIfAbsent(oppIdx, GlobalKey.new);
    final endSize =
        durakOpponentFanFlightSize(_tableCardSize, compact: _fit.compact);
    final to = globalRectOf(toKey) ??
        Rect.fromCenter(
          center: Offset(screen.width / 2, screen.height * 0.16),
          width: endSize.width,
          height: endSize.height,
        );
    final endScale = endSize.width / _tableCardSize.width;
    final tos = <Rect>[
      for (var i = 0; i < cards.length; i++)
        Rect.fromCenter(
          center: to.center.translate(i * 2.0, i * 1.2),
          width: endSize.width,
          height: endSize.height,
        ),
    ];
    final safeFroms = <Rect>[
      for (var i = 0; i < cards.length; i++)
        i < froms.length
            ? froms[i]
            : Rect.fromCenter(
                center: screen.center(Offset.zero),
                width: _tableCardSize.width,
                height: _tableCardSize.height,
              ),
    ];
    List<CardFlyTicket> tickets = const [];
    await playCardsFlyAnimation(
      context: context,
      cards: cards,
      cardSize: _tableCardSize,
      froms: safeFroms,
      tos: tos,
      duration: const Duration(milliseconds: 340),
      stagger: const Duration(milliseconds: 24),
      curve: kDurakFlyCurve,
      beginScale: 1,
      endScale: endScale,
      beginAngles: List<double>.filled(cards.length, 0),
      endAngles: List<double>.filled(cards.length, 0.1),
      arcLift: 22,
      keepAtEnd: true,
      playSfx: false,
      onCardLaunch: (_, card) {
        if (!mounted) return;
        setState(() => _leftTableCards.add(card));
      },
      onTickets: (t) => tickets = t,
    );
    for (final t in tickets) {
      t.dismiss();
    }
    if (!mounted) return;
    setState(() {
      final left = (_oppDealPending[oppIdx] ?? cards.length) - cards.length;
      if (left <= 0) {
        _oppDealPending.remove(oppIdx);
      } else {
        _oppDealPending[oppIdx] = left;
      }
    });
  }

  /// Рубашки по одной: колода → веер соперника ([_oppDealPending] уже учтён).
  /// При n>1 — строго последовательно, как свой добор: каждая карта видна отдельно.
  Future<void> _animateDealToOpponent(
    int idx,
    int n, {
    Duration flyDuration = const Duration(milliseconds: 300),
    Duration gap = const Duration(milliseconds: 48),
  }) async {
    if (n <= 0 || !mounted || !_gameUiActive) return;
    const dummy = PlayingCard(Rank.six, Suit.spades);
    final toKey = _oppFanKeys.putIfAbsent(idx, GlobalKey.new);

    for (var i = 0; i < n; i++) {
      if (!mounted || !_gameUiActive) return;
      final screen = _flyScreen;
      final endSize =
          durakOpponentFanFlightSize(_tableCardSize, compact: _fit.compact);
      final to = globalRectOf(toKey) ??
          Rect.fromCenter(
            center: Offset(screen.width / 2, screen.height * 0.16),
            width: endSize.width,
            height: endSize.height,
          );
      final endScale = endSize.width / _tableCardSize.width;
      final from = _deckDealFromRect(jitter: i * 1.8);
      final land = Rect.fromCenter(
        center: to.center.translate(i * 2.4, i * 1.6),
        width: endSize.width,
        height: endSize.height,
      );
      _consumeDeckFreezeSlot();
      final ticket = await playCardFlyAnimation(
        context: context,
        card: dummy,
        cardSize: _tableCardSize,
        from: from,
        to: land,
        duration: flyDuration,
        curve: kDurakFlyCurve,
        faceDown: true,
        flipToFace: false,
        playSfx: false,
        beginScale: 1,
        endScale: endScale,
        beginAngle: 0.12,
        endAngle: 0.08,
        arcLift: 18,
        keepAtEnd: true,
      );
      if (!mounted) {
        ticket.dismiss();
        return;
      }
      // Карта села — сразу в веер, следующая летит отдельно.
      setState(() {
        final left = (_oppDealPending[idx] ?? 1) - 1;
        if (left <= 0) {
          _oppDealPending.remove(idx);
        } else {
          _oppDealPending[idx] = left;
        }
      });
      await awaitDurakFrame();
      ticket.dismiss();
      if (!mounted || !_gameUiActive) return;
      if (i + 1 < n) {
        await Future<void>.delayed(gap);
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
    // Чужой подкид, спрятанный на время своего хода, не кладём в prev —
    // иначе replay увидит «уже была» и стол моргнёт без полёта.
    // Севшие карты оставляем: иначе следующий ход погасит уже лежащий стол.
    _prevTable = [
      for (final p in v.table)
        if (durakKeepVisibleCardInPrevTable(
          remoteFlying:
              _remoteFlyingCardIds.contains(_cardId(p.attack.toPlayingCard())),
          seated: _isSeatedTableCard(p.attack.toPlayingCard()),
          alreadyShown: _wasShownOnTable(p.attack.toPlayingCard()),
        ))
          _pairRememberedForPrev(p),
    ];
    _retainLocalAttacksInPrev();
    _prevDeckCount = v.deckCount;
    _prevBitoCount = v.bitoCount;
    _prevLastWasTake = v.lastWasTake;
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
      _seedHandOrderIfEmpty(hand);
      return const [];
    }
    // Добор «всей руки» при пустом/нулевом prev — это первый синк, не анимация.
    // Стартовую раздачу не сбрасываем в веер: карты долетят по одной.
    if (expect >= hand.length &&
        (_handOrder == null || _handOrder!.isEmpty || _prevHandLen <= 0)) {
      if (_concealOpeningHand || _pendingDealCards.isNotEmpty) {
        return _splitHandForDeal(hand, expect);
      }
      _handOrder = _handWithoutLeaving(hand);
      return const [];
    }
    return _splitHandForDeal(hand, expect);
  }

  /// Разделить руку на «уже в веере» и «добрать из колоды» (ровно [expect]).
  ///
  /// Карты, которые уже лежат в веере, не уходят в добор — даже если дельта
  /// длины руки больше числа новых карт.
  List<PlayingCard> _splitHandForDeal(List<PlayingCard> hand, int expect) {
    final n = expect.clamp(0, hand.length);
    if (n <= 0) {
      _seedHandOrderIfEmpty(hand);
      return const [];
    }
    final prev = _handOrder ?? const <PlayingCard>[];
    final incoming = durakFreshDealCards(
      serverHand: hand,
      handOrder: prev,
      expect: n,
    );
    final incomingSet = incoming.toSet();
    final gone = _locallyGoneFromHand;
    final next = <PlayingCard>[
      for (final c in prev)
        if (hand.contains(c) && !gone.contains(c) && !incomingSet.contains(c))
          c,
    ];
    for (final c in hand) {
      if (incomingSet.contains(c) || gone.contains(c) || next.contains(c)) {
        continue;
      }
      next.add(c);
    }
    _handOrder = next;
    return incoming;
  }

  /// Добор спрятан, а полёт уже кончился — показать карты в веере.
  /// Иначе рука остаётся короткой, пока соперник ходит и колода не пуста.
  void _releaseStuckFanDeals() {
    if (!durakReleaseStuckDealCards(
      pendingDeal: _pendingDealCards.isNotEmpty,
      animatingDeal: _busy ||
          _fxScheduled ||
          _localRoundFx ||
          _suppressRemoteBitoFx ||
          _concealOpeningHand ||
          _cardFlightActive,
    )) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!durakReleaseStuckDealCards(
        pendingDeal: _pendingDealCards.isNotEmpty,
        animatingDeal: _busy ||
            _fxScheduled ||
            _localRoundFx ||
            _suppressRemoteBitoFx ||
            _concealOpeningHand ||
            _cardFlightActive,
      )) {
        return;
      }
      setState(() {
        _pendingDealCards.clear();
        _dealFaceDownTail = 0;
        _deckCountFreeze = null;
        _handOrder = null;
      });
    });
  }

  /// Добор ещё не в веере: слот не показываем, пока карта не полетит лицом.
  void _concealDrawnUntilFlight(List<PlayingCard> cards) {
    if (cards.isEmpty || _concealOpeningHand) return;
    _pendingDealCards.addAll(cards);
    _flyingFromHand.removeAll(cards);
    _dealFaceDownTail = 0;
  }

  void _releaseStuckRemoteCards(
    Iterable<_RemoteTableFlight> flights,
    Iterable<DurakTablePairApi> table,
  ) {
    final flying = <String>{for (final f in flights) _cardId(f.card)};
    for (final pair in table) {
      final cards = <PlayingCard>[
        pair.attack.toPlayingCard(),
        if (pair.defense != null) pair.defense!.toPlayingCard(),
      ];
      for (final card in cards) {
        final id = _cardId(card);
        if (!_remoteFlyingCardIds.contains(id) || flying.contains(id)) {
          continue;
        }
        _remoteFlyingCardIds.remove(id);
        _seatTableCard(card);
      }
    }
  }

  void _scheduleRemoteTableFx(
    List<DurakTablePairApi> prev,
    DurakGameView view,
  ) {
    final next = view.table;
    _reconcileHiddenRemoteTableCards(view);
    final flights = <_RemoteTableFlight>[];

    // Новые атаки. Уже спрятанные (busy/replay) всё равно анимируем.
    for (var i = 0; i < next.length; i++) {
      final p = next[i];
      final attack = p.attack.toPlayingCard();
      final existed = prev.any(
        (o) => o.attack.rank == p.attack.rank && o.attack.suit == p.attack.suit,
      );
      if (durakShouldScheduleRemoteTableFlight(
        existedOnPrevTable: existed,
        seated: _isSeatedTableCard(attack),
        optimistic: _optimisticAttacks.contains(attack),
        localFlying: _flyingToTable.contains(attack),
        alreadyShown: _wasShownOnTable(attack),
        locallyCommitted: _localAttackIds.contains(_cardId(attack)),
      )) {
        flights.add(_RemoteTableFlight(
          card: attack,
          pairIndex: i,
          isDefense: false,
          fromPlayer: durakRemoteAttackFromSeat(
            attackerIndex: view.attackerIndex,
            throwerIndex: view.throwerIndex,
          ),
        ));
      }
    }

    // Новые защиты.
    for (var i = 0; i < next.length; i++) {
      final p = next[i];
      if (p.defense == null) continue;
      final defense = p.defense!.toPlayingCard();
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
          !_isSeatedTableCard(defense) &&
          !_wasShownOnTable(defense)) {
        // old==null: атака+отбой в одном апдейте (пропустили кадр) — всё равно летим.
        flights.add(_RemoteTableFlight(
          card: defense,
          pairIndex: i,
          isDefense: true,
          fromPlayer: view.defenderIndex,
        ));
      }
    }

    if (flights.isEmpty) {
      _releaseStuckRemoteCards(const [], next);
      _seatUnhiddenTableCards(next);
      return;
    }
    // Свой ход уже на столе. Если его выкинуть из полёта и оставить remote-id,
    // слот останется дыркой.
    final own = <_RemoteTableFlight>[
      for (final f in flights)
        if (f.fromPlayer == view.myIndex) f,
    ];
    flights.removeWhere((f) => f.fromPlayer == view.myIndex);
    for (final f in own) {
      _remoteFlyingCardIds.remove(_cardId(f.card));
      _seatTableCard(f.card);
      if (f.isDefense) _pinSeatedDefense(f.pairIndex, f.card);
    }
    _releaseStuckRemoteCards(flights, next);
    if (flights.isEmpty) {
      _seatUnhiddenTableCards(next);
      return;
    }

    // Скрыть сразу в этом же build — до отрисовки стола (без вспышки карты).
    // Снимаем seated: иначе следующий build посадит карту из prev, и слот
    // вспыхнет до посадки overlay.
    for (final f in flights) {
      _markRemoteTableCardFlying(f.card);
    }
    _seatUnhiddenTableCards(next);

    _beginTableFx();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        for (final f in flights) {
          _remoteFlyingCardIds.remove(_cardId(f.card));
        }
        _markFxDone();
        return;
      }
      for (final f in flights) {
        await _animateRemoteCardFlight(f, view);
        if (!mounted) break;
      }
      if (!mounted) {
        _remoteFlyingCardIds.clear();
      }
      _markFxDone();
    });
  }

  Future<void> _animateRemoteCardFlight(
    _RemoteTableFlight flight,
    DurakGameView view,
  ) async {
    final id = _cardId(flight.card);
    if (!mounted) {
      _remoteFlyingCardIds.remove(id);
      return;
    }
    // Id уже добавлен в _scheduleRemoteTableFx — только убедимся.
    if (!_remoteFlyingCardIds.contains(id)) {
      setState(() => _remoteFlyingCardIds.add(id));
    }
    // Слот уже в сетке (reserveForFlight) — два кадра, чтобы ключ сел.
    await awaitDurakFrame();
    if (!mounted) {
      _remoteFlyingCardIds.remove(id);
      return;
    }
    await awaitDurakFrame();
    if (!mounted) {
      _remoteFlyingCardIds.remove(id);
      return;
    }

    final fromKey = _oppFanKeys[flight.fromPlayer];
    final from = (fromKey != null ? globalRectOf(fromKey) : null) ??
        Rect.fromCenter(
          center: Offset(
            _flyScreen.width / 2,
            _flyScreen.height * 0.18,
          ),
          width: _tableCardSize.width * 0.5,
          height: _tableCardSize.height * 0.5,
        );

    final attackCard = flight.isDefense &&
            flight.pairIndex >= 0 &&
            flight.pairIndex < view.table.length
        ? view.table[flight.pairIndex].attack.toPlayingCard()
        : flight.card;
    final attackRect = globalRectOf(_attackKeyFor(attackCard)) ??
        _estimateAttackLandRect(
          view,
          _flyScreen,
          pairIndex: flight.pairIndex,
          pairCount: view.table.length,
        );

    final to = flight.isDefense
        ? durakEstimateDefenseLandRect(attackRect)
        : attackRect;

    List<CardFlyTicket> tickets = const [];
    final small =
        Size(_tableCardSize.width * 0.55, _tableCardSize.height * 0.55);
    final landAngle = flight.isDefense ? _kDefendLandAngle : 0.0;
    try {
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
        curve: kDurakFlyCurve,
        beginScale: 1.0,
        endScale: _tableCardSize.width / small.width,
        beginAngles: const [0.22],
        endAngles: [landAngle],
        arcLift: 28,
        keepAtEnd: true,
        playSfx: false,
        onTickets: (t) => tickets = t,
      );
    } finally {
      if (mounted) {
        setState(() {
          _remoteFlyingCardIds.remove(id);
          _seatTableCard(flight.card);
        });
        if (flight.isDefense) _pinSeatedDefense(flight.pairIndex, flight.card);
        await awaitDurakFrame();
        if (mounted) await awaitDurakFrame();
      } else {
        _remoteFlyingCardIds.remove(id);
      }
      for (final t in tickets) {
        t.dismiss();
      }
    }
  }

  /// Флажок «сдаться» — как в крестиках: при multi → observation, иначе итог.
  Future<void> _confirmSurrender() async {
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    if (view == null || view.isOver || view.iAmEliminated) return;
    final ok = await confirmSurrenderDialog(context);
    if (!ok || !mounted) return;
    unawaited(() async {
      try {
        clearBlockingGamePin(ref, ifGameId: widget.gameId);
        await ref.read(durakRepositoryProvider).forfeit(widget.gameId);
      } catch (_) {}
      if (!mounted) return;
      ref.invalidate(durakGameProvider(widget.gameId));
      try {
        final next = await ref.read(durakGameProvider(widget.gameId).future);
        final multi = next.playerIds.length > 2;
        if (multi && !next.isOver) {
          enterGameObservation(ref, widget.gameId, gameType: 'durak');
        }
      } catch (_) {}
      unawaited(ref.read(activeGameProvider.notifier).refresh());
    }());
  }

  /// Крестик / свайп — общая логика с крестиками-ноликами: диалог → сдача → /games.
  Future<void> _onClosePressed() async {
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    final eliminated = view?.iAmEliminated == true;
    final finishedOut = view?.iAmFinished == true;
    await handleGameScreenClose(
      context: context,
      isActive: view != null && !view.isOver && !eliminated && !finishedOut,
      canLeaveFreely: eliminated || finishedOut,
      onLeaveFinished: () async {
        if (!mounted) return;
        // Уже выбыл / вышел в ноль, партия идёт — observation с типом durak.
        if ((eliminated || finishedOut) && view != null && !view.isOver) {
          enterGameObservation(ref, widget.gameId, gameType: 'durak');
        }
        _navigateToGames(keepObservation: true);
      },
      onForfeitAndLeave: () async {
        if (!mounted) return;
        final multi = (view?.playerIds.length ?? 0) > 2;
        var forfeited = false;
        try {
          clearBlockingGamePin(ref, ifGameId: widget.gameId);
          await ref.read(durakRepositoryProvider).forfeit(widget.gameId);
          forfeited = true;
        } catch (_) {}
        if (!mounted) return;
        if (forfeited && view != null) {
          await playHeadToHeadFinish(
            ref: ref,
            context: context,
            gameId: widget.gameId,
            stakeBronze: view.stakeBronze,
            iWon: false,
            isDraw: false,
            playerCount: view.playerIds.length,
          );
        }
        if (!mounted) return;
        // Сразу локальная observation с типом durak — иначе карточка/роутер
        // могут увести в крестики до refresh GetActive.
        if (multi) {
          enterGameObservation(ref, widget.gameId, gameType: 'durak');
        }
        _navigateToGames(keepObservation: multi);
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
    ref
        .read(activeGameProvider.notifier)
        .clearObservationLocal(ifGameId: widget.gameId);
  }

  bool _isGameGoneError(Object e) {
    if (e is GamesException) {
      if (e.statusCode == 404) return true;
      final key = e.errorKey.toLowerCase();
      final msg = e.message.toLowerCase();
      return key.contains('game not found') ||
          msg.contains('game not found') ||
          msg.contains('игра не найдена');
    }
    final s = e.toString().toLowerCase();
    return s.contains('game not found') || s.contains('игра не найдена');
  }

  void _leaveGoneGame() {
    if (!mounted) return;
    _clearSessionForFinishedGame();
    leaveGamesSession(ref);
    context.go('/games');
  }

  void _navigateToGames({bool keepObservation = false}) {
    leaveGamesSession(ref);
    final rematchLobbyId = _rematchLobbyId;
    _rematchLobbyId = null;
    _rematchRespondedIds.clear();
    _rematchPollTimer?.cancel();
    // При уходе в observation не трогаем карточку наблюдения.
    if (!keepObservation) {
      _clearSessionForFinishedGame();
    } else {
      clearBlockingGamePin(ref, ifGameId: widget.gameId);
      final prev = ref.read(activeGameProvider).valueOrNull;
      if (prev?.gameId == widget.gameId) {
        ref.read(activeGameProvider.notifier).clearLocal();
      }
    }
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
    final ok = await confirmDrawDialog(context);
    if (!ok || !mounted) return;
    await _act(
        () => ref.read(durakRepositoryProvider).offerDraw(widget.gameId));
  }

  Future<void> _acceptDraw() async {
    final ok = await confirmDrawDialog(context, accept: true);
    if (!ok || !mounted) return;
    await _act(
        () => ref.read(durakRepositoryProvider).acceptDraw(widget.gameId));
  }

  void _showRules(DurakGameView view) {
    showGameRulesDialog(
      context: context,
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

  /// Начисление / списание ставки с анимацией — как в крестиках.
  Future<void> _onGameSettled({
    required int creditBronze,
    required int displayRewardBronze,
    int lostBronze = 0,
  }) async {
    // Повторный вход в наблюдение — не трогаем баланс и не крутим ±.
    if (_openedAsObserver || isGameBalanceSettled(ref, widget.gameId)) {
      _balanceGainPlayed = true;
      return;
    }
    if (_balanceGainPlayed) {
      return;
    }
    _balanceGainPlayed = true;
    markGameBalanceSettled(ref, widget.gameId);
    if (lostBronze > 0 && creditBronze <= 0) {
      await playGameSettledLoss(
        ref: ref,
        context: context,
        lostBronze: lostBronze,
      );
      if (mounted) setState(() => _lossChipRevealed = true);
      return;
    }
    await playGameSettledReward(
      ref: ref,
      context: context,
      creditBronze: creditBronze,
      displayRewardBronze: displayRewardBronze,
      sourceKey: displayRewardBronze > 0 ? _winRewardKey : null,
    );
  }

  /// Зафиксировать mid-finish итог один раз (после take/bito, стол пуст).
  void _lockMidFinishOutcome(DurakGameView view) {
    if (_midFinishedHandled) return;
    final place = view.myPlace;
    final sharedFirst =
        view.tiedLeaders >= 2 && place > 0 && place <= view.tiedLeaders;
    _lockedMidDraw = sharedFirst || view.isDraw;
    _lockedMidPlace = sharedFirst ? 1 : (place <= 0 ? 1 : place);
    if (_lockedMidDraw != true && _lockedMidPlace == 1) {
      _confettiArmed = true;
    }
    _midFinishedHandled = true;
  }

  void _maybeHoldFinishChrome(DurakGameView view) {
    if (!view.isOver) {
      if (!_finishHoldScheduled) _finishChromeReady = false;
      return;
    }
    if (_finishChromeReady || _finishHoldScheduled) return;
    if (durakRevealFinishImmediately(
      openedAsObserver: _openedAsObserver,
      firstSnapshotAlreadyOver: _prevGameStatus == null,
      flightActive:
          _cardFlightActive || _busy || _fxScheduled || _localAttackHold,
    )) {
      _finishChromeReady = true;
      return;
    }
    if (!durakFinishHoldNeeded(
      isOver: view.isOver,
      finishReady: _finishChromeReady,
      alreadyScheduled: _finishHoldScheduled,
    )) {
      return;
    }
    _rememberMoveChrome(view);
    _finishHoldScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_revealFinishAfterLastTrick());
    });
  }

  Future<void> _revealFinishAfterLastTrick() async {
    await _waitForTableLandings();
    if (!mounted) return;
    await _waitForClosingTableFx();
    if (!mounted) return;
    await Future<void>.delayed(kDurakFinishAfterLastTrickPause);
    if (!mounted) return;
    setState(() {
      _finishChromeReady = true;
      _clearMoveChrome(keepForFinish: false);
    });
  }

  /// Итог не показываем, пока последний стол ещё лежит или летит.
  Future<void> _waitForClosingTableFx() async {
    var waited = 0;
    const step = 40;
    const cap = 8000;
    while (mounted && waited < cap) {
      if (!durakFinishWaitsForTableFx(
        hidingTable: _hidingTable,
        tableHold: _takeTableHold != null,
        fxScheduled: _fxScheduled,
        flightActive: _cardFlightActive || _localRoundFx,
      )) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: step));
      waited += step;
    }
  }

  /// Стол для отрисовки. Уже лежащие карты не гаснут на пустом кадре,
  /// а своя бита не возвращает стол, пока сервер ещё на паузе.
  /// Новый заход с пустым столом память прошлого раунда не рисует.
  List<DurakTablePairApi> _sourceTableForPaint(DurakGameView view) {
    final hold = _takeTableHold;
    if (hold != null) return hold;
    if (_localRoundPrevLock && view.isTableReveal) return const [];
    if (view.table.isNotEmpty) return view.table;
    final remembered = _prevTable.isNotEmpty ? _prevTable : _lastNonEmptyTable;
    if (remembered.isEmpty) return const [];
    final bitoGrew = _prevBitoCount >= 0 && view.bitoCount > _prevBitoCount;
    final takeJust = view.lastWasTake && !_prevLastWasTake;
    if (durakFreshAttackTableIsEmpty(
      tableEmpty: true,
      phase: view.phase,
      tableReveal: view.isTableReveal,
      bitoGrew: bitoGrew,
      takeJustResolved: takeJust,
      hidingTable: _hidingTable,
      tableHold: false,
    )) {
      return _pendingPairsFrom(remembered);
    }
    if (bitoGrew || takeJust || view.isTableReveal || _hidingTable) {
      return _localPlayActive ? remembered : const [];
    }
    return remembered;
  }

  /// Карта прошлого раунда не должна лежать на пустом столе нового захода.
  void _dropGhostTableOnFreshAttack(
    DurakGameView view, {
    required bool bitoGrew,
    required bool takeJust,
  }) {
    if (!durakFreshAttackTableIsEmpty(
      tableEmpty: view.table.isEmpty,
      phase: view.phase,
      tableReveal: view.isTableReveal,
      bitoGrew: bitoGrew,
      takeJustResolved: takeJust,
      hidingTable: _hidingTable,
      tableHold: _takeTableHold != null,
    )) {
      return;
    }
    final pending = <PlayingCard>{..._optimisticAttacks, ..._flyingToTable};
    if (pending.isEmpty) {
      _prevTable = const [];
      _lastNonEmptyTable = const [];
      _clearSeatedTableCards();
      _localAttackIds.clear();
      _optimisticDefends.clear();
      return;
    }
    final kept = _pendingPairsFrom(_prevTable, pending: pending);
    final keptLast = _pendingPairsFrom(_lastNonEmptyTable, pending: pending);
    _prevTable = kept;
    _lastNonEmptyTable = keptLast;
    final keepIds = pending.map(_cardId).toSet();
    _seatedTableCardIds.removeWhere((id) => !keepIds.contains(id));
    _shownTableCardIds.removeWhere((id) => !keepIds.contains(id));
    _localAttackIds.removeWhere((id) => !keepIds.contains(id));
    _optimisticDefends.removeWhere((_, card) => !pending.contains(card));
  }

  List<DurakTablePairApi> _pendingPairsFrom(
    List<DurakTablePairApi> pairs, {
    Set<PlayingCard>? pending,
  }) {
    final live = pending ?? {..._optimisticAttacks, ..._flyingToTable};
    if (live.isEmpty || pairs.isEmpty) return const [];
    return [
      for (final pair in pairs)
        if (live.contains(pair.attack.toPlayingCard())) pair,
    ];
  }

  /// Последний ход: если карту ещё не показали, стол остаётся на паузе.
  Future<void> _pauseBeforeLastTrickLeaves(
    List<DurakTablePairApi> snapshot,
    DurakGameView view,
    Set<String> visibleBefore,
  ) async {
    final visible = snapshot.isEmpty ||
        snapshot.every((p) {
          if (!visibleBefore.contains(_cardId(p.attack.toPlayingCard()))) {
            return false;
          }
          final defense = p.defense?.toPlayingCard();
          if (defense == null) return true;
          return visibleBefore.contains(_cardId(defense));
        });
    final delay = durakPauseBeforeClosingFlight(
      cardsAlreadyVisible: visible,
      gameEnding: view.isOver,
    );
    if (delay == Duration.zero) return;
    await Future<void>.delayed(delay);
  }

  void _maybeSettleGame(DurakGameView view) {
    _maybeHoldFinishChrome(view);
    if (view.isOver && !_finishChromeReady) return;
    // Офлайн: без observation/монет с сервера — только UI-статус.
    if (_isOffline) {
      // Тот же mid-finish lock, чтобы офлайн не мигал «победой» каждый раз,
      // когда стол снова пуст между ходами ботов.
      if (!view.isOver &&
          view.iAmFinished &&
          !view.iAmEliminated &&
          view.table.isEmpty &&
          !view.isTableReveal) {
        _lockMidFinishOutcome(view);
      } else if (view.isOver &&
          !_confettiArmed &&
          !view.isDraw &&
          view.myPlace == 1) {
        _confettiArmed = true;
      }
      _prevGameStatus = view.status;
      return;
    }
    // Повторный вход из «Наблюдение»: UI-lock без ±монет.
    if (_openedAsObserver || isGameBalanceSettled(ref, widget.gameId)) {
      if (!view.isOver &&
          view.iAmFinished &&
          !view.iAmEliminated &&
          view.table.isEmpty &&
          !view.isTableReveal) {
        _lockMidFinishOutcome(view);
      }
      if (view.isOver && !_confettiArmed && !view.isDraw && view.myPlace == 1) {
        _confettiArmed = true;
      }
      _balanceGainPlayed = true;
      _prevGameStatus = view.status;
      return;
    }
    // Mid-game: вышел «в ноль» — сразу observation/монеты, но только когда
    // стол уже пуст (иначе подкид ещё бьют → возможна ничья).
    if (!view.isOver &&
        view.iAmFinished &&
        !view.iAmEliminated &&
        view.table.isEmpty &&
        !view.isTableReveal) {
      if (_midFinishedHandled) {
        _prevGameStatus = view.status;
        return;
      }
      _lockMidFinishOutcome(view);
      final credit = _rewardCredit(view);
      final displayReward = _rewardBronze(view);
      final lost = stakeLostOnFinish(
        stakeBronze: view.stakeBronze,
        isDraw: view.isDraw,
        iWon: credit > 0,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        clearBlockingGamePin(ref, ifGameId: widget.gameId);
        final curObs = ref.read(observationGameProvider);
        if (curObs?.gameId != widget.gameId || curObs?.gameType != 'durak') {
          enterGameObservation(ref, widget.gameId, gameType: 'durak');
        }
        unawaited(ref.read(activeGameProvider.notifier).refresh());
        // Монеты + анимация пополнения сразу (как в крестиках после выбывания-победы).
        unawaited(_onGameSettled(
          creditBronze: credit,
          displayRewardBronze: displayReward,
          lostBronze: lost,
        ));
      });
      _prevGameStatus = view.status;
      return;
    }
    if (!view.isOver) {
      _prevGameStatus = view.status;
      return;
    }
    if (_prevGameStatus == 'active' || _prevGameStatus == null) {
      _rematchPollTimer?.cancel();
      _prevGameStatus = view.status;
      // Если mid-finish уже был — не перезапускаем салют на финальной сдаче.
      if (!_confettiArmed &&
          !view.isDraw &&
          view.myPlace == 1 &&
          !_midFinishedHandled) {
        _confettiArmed = true;
      }
      for (final peerId in _peerIds(view)) {
        ref.read(gameInvitesProvider.notifier).removeByCreatorId(peerId);
      }
      final credit = _rewardCredit(view);
      // В «+N» — чистый плюс к доматчевому балансу (как в крестиках).
      final displayReward = _rewardBronze(view);
      final lost = stakeLostOnFinish(
        stakeBronze: view.stakeBronze,
        isDraw: view.isDraw,
        iWon: credit > 0,
      );
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
        // Если mid-game уже начислили — только обновить баланс без повторной анимации.
        unawaited(_onGameSettled(
          creditBronze: credit,
          displayRewardBronze: displayReward,
          lostBronze: lost,
        ));
      });
    } else {
      _prevGameStatus = view.status;
    }
  }

  Future<void> _rematch() async {
    setState(() => _isRematching = true);
    try {
      if (_isOffline) {
        final session = OfflineDurakRegistry.instance.get(widget.gameId);
        if (session != null) {
          _resetTableFxForNewDeal();
          session.restart();
          ref.invalidate(durakGameProvider(widget.gameId));
          if (mounted) setState(() => _isRematching = false);
          return;
        }
      }
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
      final own = rematchLobbyToLeave(_rematchLobbyId, lobbyId);
      if (own != null) {
        _rematchPollTimer?.cancel();
        setState(() {
          _rematchLobbyId = null;
          _rematchRespondedIds.clear();
        });
        try {
          await ref.read(durakRepositoryProvider).leaveLobby(own);
        } catch (_) {}
        if (!mounted) return;
      }
      await _joinInviteLobby(lobbyId, leaveCurrentIfBusy: true);
    } catch (_) {
      if (mounted) context.go('/games');
    } finally {
      if (mounted) setState(() => _isAcceptingRematch = false);
    }
  }

  /// Принять инвайт/реванш в лобби — не возвращаться в [widget.gameId].
  Future<void> _joinInviteLobby(
    String lobbyId, {
    bool leaveCurrentIfBusy = false,
  }) async {
    final repo = ref.read(durakRepositoryProvider);
    try {
      final result = await repo.joinLobby(lobbyId);
      if (!mounted) return;
      _navigateJoinedDurakLobby(lobbyId, result);
      return;
    } on GamesException catch (e) {
      if (!mounted) return;
      if (leaveCurrentIfBusy && isFinishCurrentGameError(e)) {
        try {
          clearBlockingGamePin(ref, ifGameId: widget.gameId);
          await repo.forfeit(widget.gameId);
        } catch (_) {}
        if (!mounted) return;
        ref.read(activeGameProvider.notifier).clearLocal();
        final retry = await repo.joinLobby(lobbyId);
        if (!mounted) return;
        _navigateJoinedDurakLobby(lobbyId, retry);
        return;
      }
      if (e.statusCode == 409) {
        try {
          await ref.read(activeGameProvider.notifier).refresh();
        } catch (_) {}
        if (!mounted) return;
        final active = ref.read(activeGameProvider).valueOrNull;
        final gid = active?.gameId?.trim() ?? '';
        if (active?.type == 'game' && gid.isNotEmpty && gid != widget.gameId) {
          context.go('/games/durak/game/$gid');
          return;
        }
        context.go('/games/durak/lobby/$lobbyId?mode=invite');
        return;
      }
      rethrow;
    }
  }

  void _navigateJoinedDurakLobby(String lobbyId, DurakJoinResult result) {
    if (!result.joined) {
      context.go('/games/durak/lobby/$lobbyId?mode=invite');
      return;
    }
    if (result.waitingMore ||
        result.gameId == null ||
        result.gameId!.trim().isEmpty) {
      clearBlockingGamePin(ref, ifGameId: widget.gameId);
      ref.read(activeGameProvider.notifier).setLocal(
            ActiveGameItem(
              type: 'lobby',
              lobbyId: lobbyId,
              gameType: 'durak',
            ),
          );
      context.go('/games/durak/lobby/$lobbyId?mode=invite');
      return;
    }
    final gameId = result.gameId!.trim();
    if (gameId == widget.gameId) {
      context.go('/games/durak/lobby/$lobbyId?mode=invite');
      return;
    }
    pinBlockingGame(ref, gameId, gameType: 'durak');
    ref.read(activeGameProvider.notifier).setLocal(
          ActiveGameItem(type: 'game', gameId: gameId, gameType: 'durak'),
        );
    ref.invalidate(durakGameProvider(gameId));
    context.go('/games/durak/game/$gameId');
  }

  Future<void> _declineRematch(String lobbyId) async {
    ref.read(gameInvitesProvider.notifier).dismiss(lobbyId);
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
    final showSurrender = view != null &&
        !view.isOver &&
        !view.iAmEliminated &&
        !view.iAmFinished;
    final isMulti = (view?.playerIds.length ?? 0) > 2;
    final topPad = MediaQuery.paddingOf(context).top;
    final groupChatId = (view?.chatId ?? '').trim();
    // После конца партии чат скрываем сразу (сервер тоже удаляет group chat).
    final showGroupChat =
        isMulti && groupChatId.isNotEmpty && !(view?.isOver ?? true);
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
    return GamepadScope(
      onAction: (action) {
        final current = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
        if (current == null) return false;
        return _onGamepad(current, action);
      },
      child: SwipeBackScope.gameBoard(
        onBack: _onClosePressed,
        bottomInset: swipeBottomExclude,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            toolbarHeight: gameToolbarHeight(context),
            leadingWidth: gameAppBarLeadingWidth(),
            centerTitle: true,
            titleSpacing: 0,
            // Крестик на одной линии с «правилами» (как в 1×1).
            leading: buildGameAppBarLeading(
              onClose: _busy ? null : _onClosePressed,
            ),
            title: Text(context.l10n.gamesDurak),
            actions: view == null
                ? const []
                : buildGameAppBarActions(
                    context: context,
                    onSurrender: null, // сдача — overlay под правилами
                    onOfferDraw: null,
                    onShowRules: () => _showRules(view),
                    rulesTooltip: context.l10n.gamesRulesTitle,
                  ),
          ),
          body: GradientBackground(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (view != null)
                  MyTurnAlert.stackLeaf(
                    isMyTurn:
                        view.isMyTurn && !view.isOver && !view.iAmEliminated,
                  ),
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
                      if (_isGameGoneError(e)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _leaveGoneGame();
                        });
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentStart,
                          ),
                        );
                      }
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
                // Салют один раз: после arm не снимаем виджет, даже если у
                // наблюдателя на столе снова карты (иначе анимация рестартит).
                if (_confettiArmed)
                  Positioned.fill(
                    child: GameConfettiOverlay(
                      key: ValueKey('durak-confetti-${widget.gameId}'),
                    ),
                  ),
                // Групповой чат — отдельно под крестиком.
                if (showGroupChat && view != null)
                  Positioned(
                    left: 4,
                    top: 0,
                    child: GameIconWithBadge(
                      icon: Icons.forum_rounded,
                      badge: groupUnread,
                      tooltip: context.l10n.chatGroupTooltip,
                      onPressed: () => _openGroupChat(view),
                    ),
                  ),
                // «Сдаться» под «правилами» (1×1 и multi), как в одиночной.
                if (showSurrender)
                  Positioned(
                    right: 4,
                    top: topPad + 4,
                    child: GameActionsOverlay(
                      canDraw: !isMulti &&
                          view.playerIds.length == 2 &&
                          !view.hasBotOpponent,
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
      ),
    );
  }

  List<PlayingCard> _gamepadHand(DurakGameView view) {
    final trump = _suitFromApi(view.trumpSuit);
    final serverHand = _apiCardsToPlaying(
      view.hands.length > view.myIndex && view.myIndex >= 0
          ? (view.hands[view.myIndex].cards ?? const [])
          : const [],
    );
    return _orderedHand(serverHand, trump);
  }

  bool _onGamepad(DurakGameView view, GamepadAction action) {
    if (action == GamepadAction.shoulderL ||
        action == GamepadAction.shoulderR) {
      return false;
    }
    if (view.isOver) return false;
    final hand = _gamepadHand(view);
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
      if (_busy || !view.canAct || hand.isEmpty) return true;
      final card = hand[_gamepadHandIndex];
      unawaited(_playCards(view, _cardsToPlay(view, card)));
      return true;
    }
    if (action == GamepadAction.actionX) {
      if (hand.isEmpty) return true;
      _toggleSelect(view, hand[_gamepadHandIndex]);
      return true;
    }
    if (action == GamepadAction.actionY || action == GamepadAction.menu) {
      if (_busy) return true;
      if (_canTake(view)) {
        unawaited(_take());
      } else if (_canPass(view)) {
        unawaited(_pass());
      } else if (_canDone(view)) {
        unawaited(_confirmTakeDone());
      } else if (_canBito(view)) {
        unawaited(_bito());
      }
      return true;
    }
    if (action == GamepadAction.cancel &&
        (_selected.isNotEmpty || _activeCard != null)) {
      _clearHandSelection();
      return true;
    }
    return false;
  }

  Widget _buildTable(DurakGameView view) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _fit = gameTableFit(
          availableHeight: constraints.maxHeight,
          designHeight: _tableDesignHeight,
          minScale: 0.52,
        );
        return _buildTableBody(view, constraints.maxHeight);
      },
    );
  }

  Widget _buildTableBody(DurakGameView view, double availableHeight) {
    final tableSize = _tableCardSize;
    _maybeRunTableFx(view);
    _syncMyTurnIdleHint(view);
    // Сбросить выбор, если карты уже не в руке / нелегальны.
    final trump = _suitFromApi(view.trumpSuit);
    final serverHand = _apiCardsToPlaying(
      view.hands.length > view.myIndex && view.myIndex >= 0
          ? (view.hands[view.myIndex].cards ?? const [])
          : const [],
    );
    _releaseStuckFanDeals();
    final myHand = _orderedHand(serverHand, trump);
    final hideFinishedHand = durakFinishChromeVisible(
      isOver: view.isOver,
      finishReady: _finishChromeReady,
    );
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
    // После итога рука не остаётся на экране.
    final handForFan = hideFinishedHand ? const <PlayingCard>[] : myHand;

    final fanSlotCount =
        hideFinishedHand ? 0 : handForFan.length + _dealFaceDownTail;
    final useFrozenFanSize = _frozenFanCardSize != null &&
        fanSlotCount <= (_frozenFanHandCount ?? 0);
    if (!useFrozenFanSize && _frozenFanCardSize != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _frozenFanCardSize != null) _releaseFanLayoutSnap();
      });
    }
    final animateFanLayout = !_suppressFanLayoutAnim &&
        (!_busy ||
            _fanAnimDuringBusy ||
            _fanCloseAfterPlay ||
            _fanOpenAfterIncoming);
    // Высота зоны: веер приподнят — карты не уходят под нижнее меню.
    final fanProbe = _handFanVisualLayout(
      fanSlotCount,
      MediaQuery.sizeOf(context).width,
    );
    final fanCardH = useFrozenFanSize
        ? _frozenFanCardSize!.height
        : fanProbe.cardSize.height;
    final nFan = fanSlotCount;
    // Непрерывный tuck (без ступеней 3/6/9) — иначе рывок при смене числа карт.
    // seatLift < 0 — чуть уводим под низ зоны.
    final seatT = nFan <= 1 ? 0.0 : ((nFan - 1) / 11).clamp(0.0, 1.0);
    // Подворот руки под низ экрана рассчитан на портрет с нижним меню.
    // В альбоме меню нет, и карты просто обрезаются краем экрана. Крайние
    // карты веера ещё и опускаются по дуге (edgeLift) и наклоняются, поэтому
    // подъём считаем от высоты карты, а не фиксированным числом.
    final seatLift = _fit.compact
        ? math.max(10.0, fanCardH * 0.24)
        : -fanCardH * (0.33 * (1 - seatT) + 0.06 * seatT);
    // Высота зоны веера всегда по максимальным картам — иначе при сбросе
    // в биту зона сжимается, стол растёт и колода/бита «прыгают».
    // В альбоме запас режем до видимой части веера (подъём + карта): всё,
    // что выше, отнимается у стола, а там и одна пара не помещалась.
    final fanZoneH = _fit.compact
        ? math.min(
            _handCardSize.height * 1.32 + 6,
            availableHeight * 0.38,
          )
        : _handCardSize.height * 2.05 + 16;
    // Кнопка чуть выше видимых карт веера. В альбоме — целиком над веером,
    // иначе «Бито»/«Взять» садится на середину карт.
    final actionBtnBottom = durakActionButtonBottom(
      compact: _fit.compact,
      seatLift: seatLift,
      fanCardH:
          _fit.compact ? math.max(fanCardH, _handCardSize.height) : fanCardH,
    );
    // Слот кнопки лежит поверх стола. В альбоме он поднимается выше зоны
    // веера, и при полном столе пары попадают прямо под «Бито». Отдаём столу
    // только высоту над слотом — слот зарезервирован всегда, чтобы стол не
    // прыгал при появлении кнопки. Запас 10 px — на поворот и тень карты
    // защиты: она рисуется чуть за пределами своего бокса.
    final boardBottomReserve = durakBoardBottomReserve(
      compact: _fit.compact,
      actionBtnBottom: actionBtnBottom,
      actionSlotH: _durakActionSlotH,
      fanZoneH: fanZoneH,
    );

    // Таймер — только после раздачи (_busy) и когда сервер выставил deadline.
    final showTimer = !view.isOver &&
        !_busy &&
        !_cardFlightActive &&
        !_localAttackHold &&
        view.isMyTurn &&
        view.turnTimeSec > 0 &&
        view.turnDeadline > 0;
    _syncOpponentTakeHold(view);
    if (_optimisticTake && view.phase != 'defend') {
      _optimisticTake = false;
    }
    if (_optimisticActionAck &&
        !_canBito(view) &&
        !_canDone(view) &&
        !_canTake(view)) {
      _optimisticActionAck = false;
    }
    if (_optimisticBitoReveal && (view.isBitoReveal || !_canBito(view))) {
      _optimisticBitoReveal = false;
    }
    final showTake =
        _canTake(view) && !_optimisticTake && !_optimisticActionAck;
    final showBito = _canBito(view) && !_optimisticActionAck;
    final showOpponentTakeLabel = durakShowOpponentTakeLabel(
      takeFollow: view.phase == 'take_follow',
      opponentIsDefender:
          view.defenderIndex >= 0 && view.defenderIndex != view.myIndex,
      holdActive: _opponentTakeHold,
    );
    final showDone = durakShowDoneAfterOpponentTake(
          canDone: _canDone(view),
          takeLabelActive: showOpponentTakeLabel,
        ) &&
        !_optimisticActionAck;
    final showPass = _canPass(view);
    // Пауза показа стола — та же «кнопка» в фиксированном слоте 52px.
    final showTakeReveal =
        view.isTakeReveal || showOpponentTakeLabel || _optimisticTake;
    final showBitoReveal = view.isBitoReveal || _optimisticBitoReveal;
    final showActionOrReveal = showTake ||
        showBito ||
        showDone ||
        showPass ||
        showTakeReveal ||
        showBitoReveal;
    final finishedChrome = durakFinishedChrome(
      isOver: durakFinishChromeVisible(
        isOver: view.isOver,
        finishReady: _finishChromeReady,
      ),
      phoneLandscape: isPhoneLandscape(context),
    );
    final layoutTween = durakFanLayoutTweenDuration(
      compact: _fit.compact,
      fastClose: _fanCloseAfterPlay || _fanOpenAfterIncoming,
    );
    final layoutTweenKey = durakLayoutTweenKey(MediaQuery.sizeOf(context));

    Widget statusBlock({double? fontSize}) {
      return GameStatusWithReward(
        statusText: _turnHint(view),
        showReward: _showRewardChip(view),
        rewardBronze: _rewardChipBronze(view),
        rewardKey: _winRewardKey,
        fontSize: fontSize,
      );
    }

    Widget rematchBlock() {
      if (_isOffline) {
        return Center(
          child: FramedButton(
            onPressed: _isRematching ? null : _rematch,
            icon: Icons.replay_rounded,
            label: context.l10n.offlinePlayAgain,
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
        peerIds: _peerIds(view),
        invites: ref.watch(gameInvitesProvider),
        onRematch: _rematch,
        onAccept: _acceptRematch,
        onDecline: _declineRematch,
        onCancelWait: _cancelRematchWait,
        onFindGame: _findGame,
        compact: true,
        table: RematchTable(
          gameType: 'durak',
          stakeBronze: view.stakeBronze,
          gameMode: view.mode,
          deckSize: view.deckSize,
        ),
      );
    }

    if (finishedChrome == DurakFinishedChrome.landscapeRow) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
        child: Column(
          children: [
            Center(
              child: view.playerIds.length == 2
                  ? _opponentsHeader(view)
                  : _multiOpponentsArea(view, tableSize),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  return Center(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: c.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: statusBlock(
                                  fontSize: c.maxWidth < 520 ? 15 : 18,
                                ),
                              ),
                              const SizedBox(width: 16),
                              rematchBlock(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

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
              if (_showFirstLeadBanner(view) &&
                  (isPhoneLandscape(context) || _fit.compact))
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
                  child: _buildFirstLeadBanner(view),
                ),
              // Пауза «Беру»/«Бито» — в слоте кнопки действия (ниже), не здесь:
              // иначе статус в колонке двигает стол и веер.
              // После mid-finish баннер остаётся на экране (не мигает, когда
              // у оставшихся снова карты на столе).
              if (durakFinishChromeVisible(
                    isOver: view.isOver,
                    finishReady: _finishChromeReady,
                  ) ||
                  _midFinishedHandled ||
                  (view.iAmFinished &&
                      view.table.isEmpty &&
                      !view.isTableReveal)) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: statusBlock(
                    fontSize:
                        MediaQuery.sizeOf(context).width < 420 ? 15 : null,
                  ),
                ),
                if (durakFinishChromeVisible(
                  isOver: view.isOver,
                  finishReady: _finishChromeReady,
                )) ...[
                  const SizedBox(height: 10),
                  rematchBlock(),
                ] else
                  const SizedBox(height: 10),
              ],
              Expanded(
                child: _buildBoard(
                  view,
                  tableSize,
                  trumpCard,
                  showTimer: showTimer,
                  bottomReserve: boardBottomReserve,
                ),
              ),
              // Высота зоны, tuck и размер карт — плавно, без рывка экрана.
              // Ключ по размеру окна: после поворота твины начинают с новой
              // геометрии, а не едут из раскладки прошлой ориентации.
              TweenAnimationBuilder<double>(
                key: ValueKey('durak-fan-$layoutTweenKey'),
                tween: Tween(end: fanZoneH),
                duration: layoutTween,
                curve: kDurakLayoutCurve,
                builder: (context, zoneH, _) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(end: seatLift),
                    duration: layoutTween,
                    curve: kDurakLayoutCurve,
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
                                    fanSlotCount,
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
                                      duration: layoutTween,
                                      curve: kDurakLayoutCurve,
                                      builder: (context, animW, _) {
                                        return TweenAnimationBuilder<double>(
                                          tween: Tween(end: spacing),
                                          duration: layoutTween,
                                          curve: kDurakLayoutCurve,
                                          builder: (context, animSp, _) {
                                            final animH = animW * aspect;
                                            return CardFan(
                                              key: _fanKey,
                                              cards: handForFan,
                                              extraFaceDown: hideFinishedHand
                                                  ? 0
                                                  : _dealFaceDownTail,
                                              cardSize: Size(animW, animH),
                                              spacing: animSp,
                                              fillWidth: fillWidth,
                                              cursorCard: GamepadService
                                                          .instance
                                                          .isRecentlyActive &&
                                                      handForFan.isNotEmpty
                                                  ? handForFan[
                                                      _gamepadHandIndex.clamp(
                                                      0,
                                                      handForFan.length - 1,
                                                    )]
                                                  : null,
                                              animateLayout: animateFanLayout,
                                              layoutDuration:
                                                  durakFanLayoutTweenDuration(
                                                compact: _fit.compact,
                                                fastClose: _fanCloseAfterPlay ||
                                                    _fanOpenAfterIncoming,
                                              ),
                                              legalCards: (!view.canAct ||
                                                      legal.isEmpty)
                                                  ? const <PlayingCard>{}
                                                  : legal,
                                              emphasizeLegal: true,
                                              selectedCards: _selected,
                                              hiddenCards: {
                                                ..._flyingFromHand,
                                                ..._pendingDealCards,
                                                ..._playedAwayCards,
                                              },
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
                                                  } else {
                                                    _stopMyTurnIdleHint(
                                                      clearShown: true,
                                                    );
                                                  }
                                                });
                                              },
                                              onHoldingChanged: (holding) {
                                                if (_holdingFanCard ==
                                                    holding) {
                                                  return;
                                                }
                                                setState(() {
                                                  _holdingFanCard = holding;
                                                  if (holding) {
                                                    _stopMyTurnIdleHint(
                                                      clearShown: true,
                                                    );
                                                  }
                                                });
                                                if (!holding) {
                                                  _requestFxReplay();
                                                }
                                              },
                                              onDragPosition: (p) {
                                                if (p == null) {
                                                  if (_dragGlobal == null) {
                                                    return;
                                                  }
                                                  setState(
                                                      () => _dragGlobal = null);
                                                  return;
                                                }
                                                final prev = _dragGlobal;
                                                // Крупнее порог — меньше rebuild всего стола на drag.
                                                if (prev != null &&
                                                    (prev - p).distanceSquared <
                                                        36) {
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
            key: ValueKey('durak-action-$layoutTweenKey'),
            tween: Tween(end: actionBtnBottom),
            duration: layoutTween,
            curve: kDurakLayoutCurve,
            builder: (context, btnBottom, _) {
              final landscapeBtn = _fit.compact || isPhoneLandscape(context);
              return Positioned(
                left: 0,
                right: 0,
                bottom: btnBottom,
                child: SizedBox(
                  height: _durakActionSlotH,
                  child: Align(
                    alignment: Alignment(
                      durakActionButtonAlignX(compact: landscapeBtn),
                      0,
                    ),
                    // «Бито»/«Взять» раньше просто моргали в слоте: появление
                    // и смена подписи шли за один кадр.
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: durakActionChromeVisible(
                        liveCanShow: showActionOrReveal,
                        holdingFanCard: _holdingFanCard,
                      )
                          ? (showTakeReveal || showBitoReveal)
                              // Просто текст (как раньше в статусе), без «кнопки» —
                              // слот 52px уже зарезервирован, стол/веер не прыгают.
                              ? Text(
                                  showTakeReveal
                                      ? context.l10n.durakStatusTaking
                                      : context.l10n.durakActionBito,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                )
                              : _PulsingActionButton(
                                  label: showTake
                                      ? context.l10n.durakActionTake
                                      : showPass
                                          ? context.l10n.durakActionPass
                                          : (showDone
                                              ? context.l10n.durakActionDone
                                              : context.l10n.durakActionBito),
                                  icon: showTake
                                      ? Icons.south_rounded
                                      : showPass
                                          ? Icons.skip_next_rounded
                                          : Icons.check_rounded,
                                  onPressed: showTake
                                      ? _take
                                      : showPass
                                          ? _pass
                                          : (showDone
                                              ? _confirmTakeDone
                                              : _bito),
                                )
                          : const SizedBox.shrink(),
                    ),
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

  /// Индексы соперников по часовой от меня: [следующий, …, предыдущий].
  /// На экране (я снизу): следующий слева → дальше сверху → предыдущий справа.
  List<int> _opponentSeatOrder(DurakGameView view) {
    final n = view.playerIds.length;
    if (n < 3 || view.myIndex < 0) return const [];
    return [
      for (var i = 1; i < n; i++) (view.myIndex + i) % n,
    ];
  }

  /// 3–4 игрока: все соперники в одну линию (как втроём).
  /// Я снизу; слева = следующий по часовой, дальше направо.
  Widget _multiOpponentsArea(DurakGameView view, Size tableSize) {
    final seats = _opponentSeatOrder(view);
    if (seats.isEmpty) return const SizedBox.shrink();
    Widget seat(int idx) => _opponentSeat(view, idx, tableSize);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final idx in seats) Expanded(child: seat(idx)),
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
    final finished =
        view.finished.contains(idx) || view.eliminated.contains(idx);
    final hideRoles = durakFinishChromeVisible(
      isOver: view.isOver,
      finishReady: _finishChromeReady,
    );
    final actor = _freezeMoveChrome && _frozenTurnActorIdx != null
        ? _frozenTurnActorIdx!
        : view.turnActorIdx;
    final phase =
        _freezeMoveChrome && _frozenPhase != null ? _frozenPhase! : view.phase;
    final theirTurn = !hideRoles &&
        !finished &&
        durakActorSeatHighlighted(
          actor: actor,
          seat: idx,
          tableReveal: phase == 'take_reveal' || phase == 'bito_reveal',
        );
    final isDefender = !hideRoles &&
        !finished &&
        view.defenderIndex == idx &&
        view.table.isNotEmpty;
    // После «Беру» у защитника — «Забрал», а не «Отбивается»/«Бьёт».
    final l10n = context.l10n;
    final String? roleLabel;
    if (!hideRoles &&
        !finished &&
        phase == 'take_follow' &&
        view.defenderIndex == idx) {
      roleLabel = l10n.durakRoleTook;
    } else if (theirTurn) {
      if (phase == 'defend' && isDefender) {
        roleLabel = l10n.durakRoleBeats;
      } else if (phase == 'attack_follow' ||
          phase == 'take_follow' ||
          phase == 'throw_in') {
        roleLabel = l10n.durakRoleThrowIn;
      } else {
        roleLabel = l10n.durakRoleTurn;
      }
    } else if (isDefender) {
      roleLabel = l10n.durakRoleDefends;
    } else {
      roleLabel = null;
    }

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

        final body = Material(
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
                      messageReturnPath: '/games/durak/game/${widget.gameId}',
                    )),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: _opponentSeatBody(
                userId: oppId,
                name: name,
                avatarKind: avatarKind,
                avatarValue: avatarValue,
                frameCode: frameCode,
                frameColor: frameColor,
                roleLabel: roleLabel,
                finished: finished,
                theirTurn: theirTurn,
              ),
            ),
          ),
        );

        // Рамка всегда смонтирована (как в 1×1): padding постоянный,
        // обводка только на ходе — layout не прыгает при смене хода/таймера.
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TurnTimerBorder(
              key: ValueKey('seat-timer-$idx'),
              active: theirTurn,
              turnDeadline: view.turnDeadline,
              turnTimeSec: view.turnTimeSec,
              borderWidth: 3,
              radius: 18,
              showIdleBorder: false,
              onExpired: theirTurn ? _onTurnTimeExpired : null,
              child: body,
            ),
            // Слот веера всегда — выход/добор не двигает стол и биту.
            Opacity(
              opacity: finished ? 0 : 1,
              child: _opponentFan(view, idx, tableSize),
            ),
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
    final hideRoles = durakFinishChromeVisible(
      isOver: view.isOver,
      finishReady: _finishChromeReady,
    );
    final actor = _freezeMoveChrome && _frozenTurnActorIdx != null
        ? _frozenTurnActorIdx!
        : view.turnActorIdx;
    final phase =
        _freezeMoveChrome && _frozenPhase != null ? _frozenPhase! : view.phase;
    final oppTurn = !hideRoles &&
        durakActorSeatHighlighted(
          actor: actor,
          seat: oppIndex,
          tableReveal: phase == 'take_reveal' || phase == 'bito_reveal',
        );
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
        final outgoing =
            friends?.outgoing.where((r) => r.user.id == oppId).toList() ??
                const [];
        final incoming =
            friends?.incoming.where((r) => r.user.id == oppId).toList() ??
                const [];
        final hasOutgoing = outgoing.isNotEmpty;
        final hasIncoming = incoming.isNotEmpty;
        final incomingRequestId = hasIncoming ? incoming.first.requestId : null;

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
            userId: oppId,
            displayName: name,
            avatarKind: avatarKind,
            avatarValue: avatarValue,
            frameCode: frameCode,
            frameColor: frameColor,
            isBot: isBot,
            messageUnread: unread,
            infoTooltip: context.l10n.userInfoTitle,
            messageTooltip: context.l10n.gameWriteMessage,
            compact: MediaQuery.sizeOf(context).width < 420 ||
                isPhoneLandscape(context),
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
      final chatId = await ref.read(chatsRepositoryProvider).startChat(userId);
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

  /// Плашка соперника: аватар над именем, а в альбоме — рядом с ним.
  ///
  /// В альбоме под стол остаётся ~60 px, и вертикальная колонка «аватар →
  /// имя → роль» съедает высоту, которой не хватает картам на столе.
  Widget _opponentSeatBody({
    required String userId,
    required String name,
    required String avatarKind,
    required String? avatarValue,
    required String? frameCode,
    required String? frameColor,
    required String? roleLabel,
    required bool finished,
    required bool theirTurn,
  }) {
    final avatar = Opacity(
      opacity: finished ? 0.45 : 1,
      child: GamePlayerAvatar(
        userId: userId,
        displayName: name,
        avatarKind: avatarKind,
        avatarValue: avatarValue,
        frameCode: frameCode,
        frameColor: frameColor,
        compact: true,
      ),
    );
    final nameText = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        decoration: finished ? TextDecoration.lineThrough : null,
      ),
    );
    // Фиксированный слот роли — появление «Бьёт» не двигает веер.
    final roleSlot = SizedBox(
      height: 14,
      child: roleLabel == null
          ? null
          : Text(
              roleLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.0,
                fontWeight: FontWeight.w700,
                color:
                    theirTurn ? AppColors.accentStart : AppColors.textSecondary,
              ),
            ),
    );
    if (isPhoneLandscape(context)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatar,
          const SizedBox(width: 6),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [nameText, roleSlot],
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(height: 2),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 96),
          child: nameText,
        ),
        const SizedBox(height: 2),
        roleSlot,
      ],
    );
  }

  /// Карты соперника дугой с кромкой — не сплошная линия, видно каждую.
  /// В альбоме плитки крупнее, иначе веер сливается в «иконку».
  Widget _opponentFan(DurakGameView view, int idx, Size cardSize) {
    final serverCount = view.hands.length > idx ? view.hands[idx].count : 0;
    final pendingDeal = (_oppDealPending[idx] ?? 0).clamp(0, serverCount);
    final hidden = pendingDeal + (_leadRevealHiddenSeat == idx ? 1 : 0);
    final floor = _oppVisualFloor[idx] ?? 0;
    final shown = durakOpponentFanShownCount(
      serverCount: serverCount,
      hidden: hidden,
      atLeast: floor,
    );
    if (floor > 0 &&
        durakOpponentFanShownCount(
              serverCount: serverCount,
              hidden: hidden,
            ) >=
            floor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if ((_oppVisualFloor[idx] ?? 0) == floor) {
          setState(() => _oppVisualFloor.remove(idx));
        }
      });
    }
    final compact = _fit.compact || isPhoneLandscape(context);
    final maxW = MediaQuery.sizeOf(context).width *
        durakOpponentFanMaxWidthFrac(compact: compact);
    final geo = durakOpponentFanGeometry(
      cardSize: cardSize,
      shown: shown,
      maxWidth: maxW,
      compact: compact,
    );
    final tile = geo.tile;
    final step = geo.step;
    final totalW = geo.totalW;
    final arcH = geo.arcH;
    final reserveH = geo.reserveH;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: SizedBox(
        width: double.infinity,
        height: reserveH,
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            // Ключ на самой стопке — полёт садится в веер, не в всю ширину.
            key: _oppFanKeys.putIfAbsent(idx, GlobalKey.new),
            width: math.max(totalW, tile.width),
            height: reserveH,
            child: shown <= 0
                ? const SizedBox.expand()
                : Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      for (var i = 0; i < shown; i++)
                        Builder(
                          builder: (_) {
                            final t =
                                shown <= 1 ? 0.0 : (i / (shown - 1)) * 2 - 1;
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
    double bottomReserve = 0,
  }) {
    final focus =
        _activeCard ?? (_selected.isNotEmpty ? _selected.first : null);
    // Подсказки при подъёме: все бьющиеся атаки + слот перевода в сетке.
    final lifting = _flightLockTable ||
        (!_busy && (_activeCard != null || _holdingFanCard));
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
            view.phase == 'throw_in' ||
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

    // Слот над колодой под таймер своего хода; такой же пустой — над битой,
    // чтобы колода и бита всегда на одной линии (появление таймера ничего не двигает).
    final pileTimerSlotH = _fit.compact ? 34.0 : 48.0;
    const pileTimerGap = 6.0;

    // Колода слева — чуть в кадре, не под боковой панелью.
    // Freeze: козырь не исчезает, пока доборные карты не улетели.
    final pilesPeek = durakPilesPeekOffEdge(
      compact: _fit.compact || isPhoneLandscape(context),
    );
    final deckPeek = KeyedSubtree(
      key: _deckKey,
      child: DurakDeckPile(
        deckCount: _deckCountFreeze ?? view.deckCount,
        trumpCard: trumpCard,
        trumpSuit: _suitFromApi(view.trumpSuit),
        cardSize: cardSize,
        showTrumpFace: _trumpFaceVisible,
        peekOffEdge: pilesPeek,
      ),
    );

    final bitoCount = _bitoCountFreeze ?? view.bitoCount;
    final bitoPeek = KeyedSubtree(
      key: _bitoKey,
      child: DurakBitoPile(
        count: bitoCount,
        cardSize: cardSize,
        peek: pilesPeek,
      ),
    );

    // При «Взять» рисуем снимок стола — сервер уже пустой, карты улетают по одной.
    // Во время своего хода пустой кадр WS не должен гасить уже лежащие карты.
    final hold = _takeTableHold;
    final sourceTable = _sourceTableForPaint(view);
    final tableItems = <Widget>[
      if (!_hidingTable) ...[
        for (var i = 0; i < sourceTable.length; i++)
          if (_shouldShowTakeHoldPair(sourceTable[i], i,
                  usingHold: hold != null) &&
              (hold != null ||
                  durakSeatedTablePairInLayout(
                    seated: _isSeatedTableCard(
                      sourceTable[i].attack.toPlayingCard(),
                    ),
                    reserveForFlight: _isRemoteTableCardHidden(
                      sourceTable[i].attack.toPlayingCard(),
                    ),
                    keepVisible: true,
                  )))
            KeyedSubtree(
              key: ValueKey(
                'atk-${_cardId(sourceTable[i].attack.toPlayingCard())}',
              ),
              child: _AnimatedTablePair(
                pair: _tablePairForTakeHold(sourceTable[i], i,
                    usingHold: hold != null),
                cardSize: cardSize,
                hideAttack: hold == null &&
                    durakTableSlotBlankUntilLand(
                      seated: _isSeatedTableCard(
                        sourceTable[i].attack.toPlayingCard(),
                      ),
                      inFlight: durakTableAttackSlotInFlight(
                        localFlying: _flyingToTable.contains(
                          sourceTable[i].attack.toPlayingCard(),
                        ),
                        remoteFlying: _isRemoteTableCardHidden(
                          sourceTable[i].attack.toPlayingCard(),
                        ),
                      ),
                    ),
                highlightAttack: hold == null && defendTargets.contains(i),
                attackKey: _attackKeyFor(
                  sourceTable[i].attack.toPlayingCard(),
                ),
                defendTargetKey: hold == null && i == defendPairIndex
                    ? _defendTargetKey
                    : null,
                optimisticDefense: hold == null
                    ? _visibleOptimisticDefense(
                        i,
                        sourceTable[i].attack.toPlayingCard(),
                      )
                    : null,
              ),
            ),
        if (hold == null)
          for (var i = 0; i < pendingAttacks.length; i++)
            Opacity(
              key: ValueKey('atk-${_cardId(pendingAttacks[i])}'),
              opacity: durakTableSlotOpacity(
                inFlight: durakTableAttackSlotInFlight(
                  localFlying: _flyingToTable.contains(pendingAttacks[i]),
                  remoteFlying: _isRemoteTableCardHidden(pendingAttacks[i]),
                ),
              ),
              child: _AnimatedTablePair(
                pair: DurakTablePairApi(
                  attack: DurakApiCard.fromCard(pendingAttacks[i]),
                ),
                cardSize: cardSize,
                attackKey: _attackKeyFor(pendingAttacks[i]),
              ),
            ),
      ],
    ];
    // Подсказка перевода/атаки — оверлей, не ячейка ряда: иначе 2→3→2
    // дёргает лежащие карты влево-вправо и даёт моргание при переводе.
    final dropHint =
        hold == null && showTableDropSlot && !durakDropHintOccupiesPairSlot()
            ? KeyedSubtree(
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
              )
            : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Реальная ширина колоды (козырь + стопка) и биты+таймер — стол строго между ними.
        final leftReserve = durakBoardLeftReserve(
          compact: _fit.compact,
          cardSize: cardSize,
        );
        final rightReserve = durakBoardRightReserve(
          compact: _fit.compact,
          cardSize: cardSize,
          bitoCount: bitoCount,
        );
        final tableMaxW = (constraints.maxWidth - leftReserve - rightReserve)
            .clamp(100.0, constraints.maxWidth);
        // Якорь от верха стола — НЕ от maxHeight: иначе при смене высоты
        // Expanded (веер/статус/рука) колода и бита «прыгают».
        const pileTop = 4.0;
        final pileInset = durakPileEdgeInset(compact: _fit.compact);
        final usedBottom = durakClampedTableBottomReserve(
          reserve: bottomReserve,
          boardHeight: constraints.maxHeight,
          cardSize: cardSize,
        );
        return Stack(
          // hardEdge резал биту и полёты раздачи в альбоме.
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
            // Снизу коридор упирается в слот «Бито»/«Беру»: он лежит поверх
            // стола, и в альбоме пары иначе попадают прямо под кнопку.
            Positioned(
              left: leftReserve,
              right: rightReserve,
              top: 0,
              bottom: usedBottom,
              child: Center(
                child: KeyedSubtree(
                  key: _tableKey,
                  child: SizedBox(
                    width: tableMaxW,
                    child: _buildTableRows(
                      items: tableItems,
                      cardSize: cardSize,
                      maxWidth: tableMaxW,
                      animateSlots: !_suppressFanLayoutAnim &&
                          hold == null &&
                          !_hidingTable,
                      dropHint: dropHint,
                    ),
                  ),
                ),
              ),
            ),
            if (_showFirstLeadBanner(view) &&
                !_fit.compact &&
                !isPhoneLandscape(context))
              Positioned(
                left: leftReserve,
                right: rightReserve,
                top: 0,
                bottom: usedBottom,
                child: IgnorePointer(
                  child: Align(
                    alignment: const Alignment(0, -0.12),
                    child: _buildFirstLeadBanner(view),
                  ),
                ),
              ),
            if (_showMyTurnIdleBanner(view))
              Positioned(
                left: leftReserve,
                right: rightReserve,
                top: 0,
                bottom: usedBottom,
                child: IgnorePointer(
                  child: Align(
                    alignment: const Alignment(0, -0.12),
                    child: _buildMyTurnIdleBanner(),
                  ),
                ),
              ),
            // Колода слева; таймер своего хода — в фиксированном слоте над ней.
            Positioned(
              left: pileInset,
              top: pileTop,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: pileTimerSlotH,
                    width: 96,
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
                  const SizedBox(height: pileTimerGap),
                  deckPeek,
                ],
              ),
            ),
            // Бита справа. Пустую не рисуем — только 1×1 якорь для полёта в отбой.
            if (bitoCount > 0)
              Positioned(
                right: pileInset,
                top: pileTop,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(height: pileTimerSlotH, width: 1),
                    const SizedBox(height: pileTimerGap),
                    RepaintBoundary(child: bitoPeek),
                  ],
                ),
              )
            else
              Positioned(
                right: pileInset,
                top: pileTop + pileTimerSlotH + pileTimerGap,
                child: bitoPeek,
              ),
          ],
        );
      },
    );
  }

  double _tableRowTop(Size cardSize, int row, int rowCount) =>
      durakTableRowTop(cardSize, row, rowCount, compact: _fit.compact);

  double _tableStackHeight(Size cardSize, int rowCount) =>
      durakTableStackHeight(cardSize, rowCount, compact: _fit.compact);

  /// До 2 пар в ряд; если не влезает — пары наезжают друг на друга.
  ///
  /// Сразу финальная сетка: лежащие карты одним твином едут на место,
  /// новая летит в уже правильный слот — без второго рывка после посадки.
  Widget _buildTableRows({
    required List<Widget> items,
    required Size cardSize,
    required double maxWidth,
    bool animateSlots = true,
    Widget? dropHint,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    final n = items.length;
    const cols = _tableCols;
    final rows = (n + cols - 1) ~/ cols;
    final totalH = _tableStackHeight(cardSize, rows);
    final duration =
        animateSlots ? kDurakTablePairSlideDuration : Duration.zero;
    final pairW = durakTablePairSlotWidth(cardSize);
    final pairH = durakTablePairHeight(cardSize);

    final slots = <Widget>[];
    for (var i = 0; i < n; i++) {
      final origin = durakTablePairSlotOrigin(
        maxWidth: maxWidth,
        cardSize: cardSize,
        pairIndex: i,
        pairCount: n,
        compact: _fit.compact,
        cols: cols,
      );
      slots.add(
        AnimatedPositioned(
          key: ValueKey('table-slot-${items[i].key ?? i}'),
          duration: duration,
          curve: kDurakLayoutCurve,
          left: origin.dx,
          top: origin.dy,
          width: pairW,
          height: pairH,
          child: items[i],
        ),
      );
    }
    if (dropHint != null) {
      final hintAt = durakTablePairSlotOrigin(
        maxWidth: maxWidth,
        cardSize: cardSize,
        pairIndex: n,
        pairCount: n + 1,
        compact: _fit.compact,
        cols: cols,
      );
      slots.add(
        Positioned(
          left: hintAt.dx,
          top: hintAt.dy,
          width: pairW,
          height: pairH,
          child: dropHint,
        ),
      );
    }
    return SizedBox(
      width: maxWidth,
      height: totalH,
      child: Stack(
        clipBehavior: Clip.none,
        children: slots,
      ),
    );
  }

  /// Победа из‑за сдачи/таймаута соперника — только в 1×1.
  ///
  /// Втроём/вчетвером флаг forfeit/timeout мог остаться от раннего выбывшего;
  /// «Соперник сдался» показываем, если игра изначально 1×1 либо конец —
  /// сдача/таймаут последнего соперника (он же loser и в eliminated).
  /// Если уже показали mid-finish победу/ничью — не переключаем текст.
  bool _isDecisiveOpponentExitWin(DurakGameView view) {
    if (_midFinishedHandled) return false;
    if (view.myPlace != 1 || view.isDraw) return false;
    if (!view.isForfeit && !view.isTimeout) return false;
    if (view.playerIds.length <= 2) return true;
    final loser = view.loserIndex;
    return loser >= 0 && view.isEliminated(loser);
  }

  bool _showRewardChip(DurakGameView view) {
    if (view.stakeBronze <= 0) return false;
    // Mid-game после выхода «в ноль» (в т.ч. пока наблюдаем чужой стол) или итог.
    if (!view.isOver &&
        !_midFinishedHandled &&
        !(view.iAmFinished && view.table.isEmpty && !view.isTableReveal) &&
        !view.iAmEliminated) {
      return false;
    }
    final delta = _rewardChipBronze(view);
    if (delta == 0) return false;
    // Проигрыш: чип только после списания и анимации.
    if (delta < 0 && !_lossChipRevealed) return false;
    return true;
  }

  /// Дельта для чипа: «+N» при кредите, «−ставка» при проигрыше.
  int _rewardChipBronze(DurakGameView view) {
    if (view.stakeBronze <= 0) return 0;
    if (view.isDraw) return 0;
    if (view.tiedLeaders >= 2 &&
        view.myPlace > 0 &&
        view.myPlace <= view.tiedLeaders) {
      return 0;
    }
    final net = _rewardBronze(view);
    if (net > 0) return net;
    if (view.isOver || view.iAmEliminated) return -view.stakeBronze;
    return 0;
  }

  /// Текст mid-finish, зафиксированный при первом take/bito.
  String? _lockedMidFinishHint(AppLocalizations l10n) {
    if (!_midFinishedHandled || _lockedMidPlace == null) return null;
    if (_lockedMidDraw == true) return l10n.gameDraw;
    if (_lockedMidPlace == 1) return l10n.gameYouWon;
    return l10n.gameYouPlaced(_lockedMidPlace!);
  }

  /// Сколько сервер реально зачислит на баланс (банк / возврат ставки).
  int _rewardCredit(DurakGameView view) {
    if (view.isDraw) return view.stakeBronze;
    if (view.myPlace <= 0) return 0;
    final n = view.playerIds.length >= 2 ? view.playerIds.length : 2;
    final pot = view.stakeBronze * n;
    // Ничья лидеров: весь банк мест делится поровну.
    if (view.tiedLeaders >= 2 && view.myPlace <= view.tiedLeaders) {
      return pot ~/ view.tiedLeaders +
          (view.myPlace == 1 ? pot % view.tiedLeaders : 0);
    }
    // Mid-game: фиксированная доля места (без roll-up) — как CreditForPlace на сервере.
    // В конце партии — с roll-up по реально занятым местам.
    final placesFilled = (!view.isOver && view.iAmFinished)
        ? durakPlaceShareNumerators(n).length.clamp(1, n)
        : view.winnerPlaceOrder.length.clamp(1, n);
    return durakPlaceCredit(
      stake: view.stakeBronze,
      playerCount: n,
      place: view.myPlace,
      placesFilled: placesFilled,
    );
  }

  /// Чистый плюс относительно доматчевого баланса (для чипа «+N»).
  int _rewardBronze(DurakGameView view) {
    if (view.isDraw) return 0;
    final credit = _rewardCredit(view);
    if (credit <= 0) return 0;
    return (credit - view.stakeBronze).clamp(0, credit);
  }

  /// Имя победителя (1-е место) или соперника в 1×1.
  String _winnerName(DurakGameView view) {
    final order = view.winnerPlaceOrder;
    if (order.isNotEmpty) {
      return _playerDisplayName(view, order.first);
    }
    // fallback 1×1
    return _opponentName(view);
  }

  String _playerDisplayName(DurakGameView view, int idx) {
    if (idx < 0 || idx >= view.playerIds.length) {
      return context.l10n.gameOpponent;
    }
    final id = view.playerIds[idx];
    if (id.startsWith('bot:')) return context.l10n.gameBot;
    final meta = view.playerMeta(id);
    final n = meta?.displayName?.trim() ?? '';
    if (n.isNotEmpty) return n;
    // Логин / короткий id, не общее «Соперник».
    if (id.length >= 8) return id.substring(0, 8);
    return id.isNotEmpty ? id : context.l10n.gameOpponent;
  }

  bool _showFirstLeadBanner(DurakGameView view) {
    return durakFirstLeadBannerVisible(
      firstRound: view.firstRound,
      tableEmpty: view.table.isEmpty,
      firstLeadArmed: _firstLeadVisible,
      holdingFanCard: _holdingFanCard || _activeCard != null,
      gameOver: view.isOver,
    );
  }

  String _firstLeadTitle(DurakGameView view) {
    final l10n = context.l10n;
    if (view.attackerIndex == view.myIndex) return l10n.durakFirstLeadYou;
    if (view.playerIds.length == 2) {
      final oppId =
          view.attackerIndex >= 0 && view.attackerIndex < view.playerIds.length
              ? view.playerIds[view.attackerIndex]
              : '';
      if (oppId.startsWith('bot:')) return l10n.durakFirstLeadBot;
      return l10n.durakFirstLeadOpponent;
    }
    return l10n.durakFirstLeadOf(_playerDisplayName(view, view.attackerIndex));
  }

  Widget _buildMyTurnIdleBanner() {
    final compact = isPhoneLandscape(context) || _fit.compact;
    return ConstrainedBox(
      constraints: BoxConstraints(
          maxWidth: compact ? 360 : (isNarrow(context) ? 280 : 340)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.accentStart.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentStart.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : (isNarrow(context) ? 14 : 18),
            vertical: compact ? 6 : (isNarrow(context) ? 8 : 10),
          ),
          child: Text(
            context.l10n.gamesMyTurn,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 14 : (isNarrow(context) ? 16 : 18),
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFirstLeadBanner(DurakGameView view) {
    final compact = isPhoneLandscape(context) || _fit.compact;
    final lead = view.leadTrump?.toPlayingCard();
    final showBannerCard = durakFirstLeadShowsBannerCard(compact: compact);
    final title = Text(
      _firstLeadTitle(view),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: compact ? 14 : (isNarrow(context) ? 16 : 18),
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
    final reason = Text(
      context.l10n.durakFirstLeadReason,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: compact ? 11 : (isNarrow(context) ? 12 : 13),
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
    final texts = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        title,
        const SizedBox(height: 2),
        reason,
      ],
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
          maxWidth: compact ? 360 : (isNarrow(context) ? 280 : 340)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.accentStart.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentStart.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : (isNarrow(context) ? 14 : 18),
            vertical: compact ? 6 : (isNarrow(context) ? 8 : 10),
          ),
          child: showBannerCard && lead != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PlayingCardWidget(
                      card: lead,
                      size: const Size(28, 40),
                      elevated: true,
                      animate: false,
                    ),
                    const SizedBox(width: 10),
                    Flexible(child: texts),
                  ],
                )
              : texts,
        ),
      ),
    );
  }

  /// Статус как в крестиках: «Ваш ход» / «Ход {имя}» / итог со сдачей/таймаутом.
  String _turnHint(DurakGameView view) {
    if (_holdingFanCard || _activeCard != null) {
      return _liveTurnHint(view);
    }
    if (_frozenTurnHint != null &&
        !durakFinishChromeVisible(
          isOver: view.isOver,
          finishReady: _finishChromeReady,
        )) {
      return _frozenTurnHint!;
    }
    return _liveTurnHint(view);
  }

  String _liveTurnHint(DurakGameView view, {bool ignoreOver = false}) {
    final l10n = context.l10n;
    if (!view.isOver && view.iAmEliminated) {
      return l10n.gameYouEliminated;
    }
    // Уже зафиксировали итог при take/bito — один раз, без «Соперник сдался».
    final locked = _lockedMidFinishHint(l10n);
    if (locked != null) return locked;
    // Вышел «в ноль», пока остальные ещё играют — победа/место только
    // когда стол пуст (не во время чужого отбоя ваших последних карт).
    if (!view.isOver &&
        view.iAmFinished &&
        view.table.isEmpty &&
        !view.isTableReveal) {
      final place = view.myPlace;
      // Общий выход одной волной — делим 1 место.
      if (view.tiedLeaders >= 2 && place > 0 && place <= view.tiedLeaders) {
        return l10n.gameDraw;
      }
      if (place <= 1) return l10n.gameYouWon;
      return l10n.gameYouPlaced(place);
    }
    if (view.isOver && !ignoreOver) {
      if (view.isDraw) return l10n.gameDraw;
      // Ничья лидеров по tied_leaders (игра уже over).
      if (view.tiedLeaders >= 2 &&
          view.myPlace > 0 &&
          view.myPlace <= view.tiedLeaders) {
        return l10n.gameDraw;
      }
      final place = view.myPlace;
      final winnerName = _winnerName(view);
      // 1-е место: «соперник сдался/время» только в реальном 1×1
      // (изначально двое или сдался/вылетел последний соперник).
      if (place == 1) {
        if (_isDecisiveOpponentExitWin(view)) {
          if (view.isForfeit) return l10n.gameYouWonOpponentForfeit;
          if (view.isTimeout) return l10n.gameYouWonOpponentTimeout;
        }
        return l10n.gameYouWon;
      }
      // 2-е и дальше — всегда своё место. Не «Время вышло»: флаг timeout
      // на партии может быть от другого игрока, выбывшего раньше.
      if (place > 1) {
        return l10n.gameYouPlaced(place);
      }
      // Нет места: выбыл по времени / сдался / классический дурак.
      if (view.iAmEliminated && view.isTimeout) {
        return l10n.gameOpponentWonTimeout(winnerName);
      }
      if (view.iAmEliminated && view.isForfeit) {
        return l10n.gameYouForfeitOpponentWon(winnerName);
      }
      // Со ставкой — «Вы проиграли» + чип −N (как «Вы победили» + +N).
      if (view.stakeBronze > 0) return l10n.gameYouLost;
      if (view.iAmEliminated) return l10n.gameYouEliminated;
      return l10n.gameOpponentWon(winnerName);
    }
    if (_showFirstLeadBanner(view)) {
      return _firstLeadTitle(view);
    }
    if (view.isBitoReveal) {
      return l10n.durakActionBito;
    }
    if (view.isTakeReveal) {
      return l10n.durakStatusTaking;
    }
    if (view.phase == 'take_follow') {
      if (view.attackerIndex == view.myIndex ||
          view.throwerIndex == view.myIndex) {
        return l10n.durakHintTakeFollow;
      }
      return l10n.durakHintOpponentTakeFollow;
    }
    if (view.phase == 'throw_in') {
      if (view.throwerIndex == view.myIndex) {
        if (view.legalAttack.isEmpty) return l10n.durakHintDefenderTurn;
        return view.firstRound
            ? l10n.durakHintThrowInFirst
            : l10n.durakHintThrowIn;
      }
      return l10n.durakHintOpponentThrows;
    }
    if (view.isMyTurn) {
      if (durakMyTurnIdleHintVisible(
        isMyTurn: true,
        holdingFanCard: _holdingFanCard || _activeCard != null,
        idleElapsed: _showMyTurnIdleHint,
        gameOver: view.isOver,
      )) {
        return l10n.gamesMyTurn;
      }
      return '';
    }
    final turnIdx = view.phase == 'defend'
        ? view.defenderIndex
        : (view.turnActorIdx >= 0 ? view.turnActorIdx : view.attackerIndex);
    final turnId = (turnIdx >= 0 && turnIdx < view.playerIds.length)
        ? view.playerIds[turnIdx]
        : '';
    final meta = view.playerMeta(turnId);
    final fromMeta = meta?.displayName?.trim() ?? '';
    if (fromMeta.isNotEmpty) return l10n.gameTurnOf(fromMeta);
    return l10n.gamesOpponentTurn;
  }

  String _opponentName(DurakGameView view) {
    if (view.myIndex < 0 || view.playerIds.length < 2) {
      return context.l10n.gameOpponent;
    }
    // 1×1 — единственный соперник; multi — первый не-я из списка.
    for (var i = 0; i < view.playerIds.length; i++) {
      if (i == view.myIndex) continue;
      return _playerDisplayName(view, i);
    }
    return context.l10n.gameOpponent;
  }

  List<PlayingCard> _apiCardsToPlaying(List<DurakApiCard> apis) {
    return apis.map((c) => c.toPlayingCard()).toList();
  }
}

/// Плавное мигание кнопки «Взять» / «Бито» между колодой и веером.
/// Пульс только свечением — без scale, чтобы слот 52px не «дышал».
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
        final glow = 0.22 + 0.28 * t;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.buttonBorder.withValues(alpha: glow),
                blurRadius: 14 + 8 * t,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: FramedButton(
          gamepadAction: GamepadAction.actionY,
          onPressed: () async {
            if (_pressed) return;
            setState(() => _pressed = true);
            try {
              await widget.onPressed();
            } finally {
              if (mounted) setState(() => _pressed = false);
            }
          },
          icon: widget.icon,
          label: widget.label,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
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
    this.hideAttack = false,
    this.attackKey,
    this.defendTargetKey,
    this.optimisticDefense,
  });

  final DurakTablePairApi pair;
  final Size cardSize;
  final bool highlightAttack;
  final bool hideAttack;
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
            child: Opacity(
              opacity: hideAttack ? 0 : 1,
              child: PlayingCardWidget(
                card: pair.attack.toPlayingCard(),
                size: cardSize,
                elevated: true,
                dropTarget: highlightAttack && !beaten,
                dimmed: beaten,
                animate: false,
              ),
            ),
          ),
          // Цель отбоя — отдельный ключ на позиции защиты, не на атаке.
          if (defendTargetKey != null && !beaten)
            Positioned(
              left: kDurakDefendOffset.dx,
              top: kDurakDefendOffset.dy,
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
              left: kDurakDefendOffset.dx,
              top: kDurakDefendOffset.dy,
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
