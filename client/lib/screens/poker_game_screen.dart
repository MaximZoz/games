import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_grid.dart';
import 'package:multigames_client/core/gamepad/gamepad_glyph.dart';
import 'package:multigames_client/core/gamepad/gamepad_highlight.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/core/sfx.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/game_balance_settle.dart';
import 'package:multigames_client/games/offline_session_hold.dart';
import 'package:multigames_client/games/game_eliminate.dart';
import 'package:multigames_client/games/game_stake.dart';
import 'package:multigames_client/games/game_turn_action.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/live_game_sync.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException;
import 'package:multigames_client/games/poker/poker_combo_sheet.dart';
import 'package:multigames_client/games/poker/poker_offline_engine.dart'
    show PokerActionType, PokerStreet;
import 'package:multigames_client/games/poker/poker_offline_session.dart';
import 'package:multigames_client/games/poker/poker_provider.dart';
import 'package:multigames_client/games/poker/poker_repository.dart';
import 'package:multigames_client/games/poker/poker_rules.dart';
import 'package:multigames_client/games/poker/poker_seat_layout.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/durak/card_fly.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/game_fly_overlay.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';
import 'package:multigames_client/utils/user_error.dart';

/// Экран партии Texas Hold'em — общий для онлайна и офлайна.
///
/// Стол-овал с местами по кругу, борды и банк в центре, свои карманные карты
/// внизу, панель действий (Фолд / Чек-Колл / Рейз / Ва-банк) в свой ход.
class PokerGameScreen extends ConsumerStatefulWidget {
  const PokerGameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  ConsumerState<PokerGameScreen> createState() => _PokerGameScreenState();
}

class _PokerGameScreenState extends ConsumerState<PokerGameScreen>
    with TickerProviderStateMixin {
  bool _busy = false;
  int _gamepadActionIndex = 0;
  /// Ход ушёл на сервер — не возвращать «Фолд», пока снимок не подтвердит.
  bool _hideActionsUntilSync = false;
  final GameTurnActionLock _turnAction = GameTurnActionLock();
  Timer? _busyWatchdog;
  int _busyStuckTicks = 0;
  bool _providerBindingsInitialized = false;
  bool _isRematching = false;
  bool _isAcceptingRematch = false;
  String? _rematchLobbyId;
  bool _rematchDeclined = false;
  bool _iDeclinedRematch = false;
  bool _isFindingGame = false;
  Timer? _rematchPollTimer;
  ProviderSubscription<AsyncValue<Map<String, dynamic>>>? _realtimeSubscription;
  bool _prevOver = false;
  bool _balanceGainPlayed = false;
  bool _lossChipRevealed = false;

  /// Пауза перед итоговым окном — сначала видно карты/борд.
  bool _endDialogReady = false;
  bool _endDialogScheduled = false;
  bool _observeEntered = false;

  /// Повторный вход из «Наблюдение» — без анимации/refresh монет.
  bool _openedAsObserver = false;
  bool _openModeCaptured = false;
  final GlobalKey _winRewardKey = GlobalKey();

  // ---- анимация появления борда + полёт фишек ----
  /// Цель анимации фишек — стопка под общими картами (не бейдж «Банк»).
  final GlobalKey _tableChipsKey = GlobalKey();
  final Map<int, GlobalKey> _seatKeys = {};
  int _shownCommunity = 0; // сколько карт борда уже показано
  int _dealHand = -1; // номер раздачи, чей борд сейчас отслеживаем
  bool _dealing = false;
  bool _disposed = false;
  int _prevHandNumber = -1;
  bool _prevHandOver = false;
  final Map<int, int> _prevBets = {};
  final Map<int, int> _prevChips = {};
  final Map<int, bool> _prevFolded = {};
  int _foldHand = -1;
  final List<AnimationController> _chipControllers = [];

  /// Фолд со ставкой: уже отправили фишки в банк (не дублировать).
  final Set<int> _foldChipFlownSeats = {};

  bool get _isOffline => OfflinePokerRegistry.instance.isOffline(widget.gameId);

  @override
  void dispose() {
    _disposed = true;
    _rematchPollTimer?.cancel();
    _realtimeSubscription?.close();
    _busyWatchdog?.cancel();
    GameFlyOverlay.dismissAll();
    for (final c in _chipControllers) {
      c.dispose();
    }
    _chipControllers.clear();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _captureOpenMode();
    _initializeProviderBindings();
  }

  void _captureOpenMode() {
    if (_openModeCaptured) return;
    _openModeCaptured = true;
    _openedAsObserver = openedAsGameObserver(ref, widget.gameId) ||
        isGameBalanceSettled(ref, widget.gameId);
    if (_openedAsObserver) {
      _observeEntered = true;
      _balanceGainPlayed = true;
    }
  }

  @override
  void didUpdateWidget(covariant PokerGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId) {
      setState(() {
        _rematchLobbyId = null;
        _rematchDeclined = false;
        _iDeclinedRematch = false;
        _isRematching = false;
        _isAcceptingRematch = false;
        _isFindingGame = false;
        _prevOver = false;
        _balanceGainPlayed = false;
        _lossChipRevealed = false;
        _endDialogReady = false;
        _endDialogScheduled = false;
        _observeEntered = false;
        _openedAsObserver = false;
        _openModeCaptured = false;
      });
      _captureOpenMode();
    }
  }

  void _scheduleEndDialog() {
    if (_endDialogScheduled || _endDialogReady) return;
    _endDialogScheduled = true;
    unawaited(() async {
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      if (!mounted) return;
      setState(() => _endDialogReady = true);
    }());
  }

  void _initializeProviderBindings() {
    if (_providerBindingsInitialized) return;
    _providerBindingsInitialized = true;
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
      if (!mounted || _disposed) return;
      if (_busy) {
        _busyStuckTicks++;
        if (_busyStuckTicks >= 3) {
          _busyStuckTicks = 0;
          _turnAction.release();
          setState(() => _busy = false);
          if (!_isOffline) {
            ref.invalidate(pokerGameProvider(widget.gameId));
          }
        }
      } else {
        _busyStuckTicks = 0;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isOffline) return;
      final known = ref.read(pokerGameProvider(widget.gameId)).valueOrNull;
      final observing =
          ref.read(observationGameProvider)?.gameId == widget.gameId;
      final eliminated = known?.iAmEliminated == true;
      if (known != null && known.isOver) {
        _clearSessionForFinishedGame();
      } else if (eliminated || observing || _openedAsObserver) {
        // Наблюдение: не пинить как active и не переводить в «свою игру».
        clearBlockingGamePin(ref, ifGameId: widget.gameId);
        enterGameObservation(ref, widget.gameId, gameType: 'poker');
      } else {
        pinBlockingGame(ref, widget.gameId, gameType: 'poker');
        final prev = ref.read(activeGameProvider).valueOrNull;
        if (prev?.gameId != widget.gameId) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: widget.gameId,
                  lobbyId: prev?.lobbyId,
                  gameType: 'poker',
                ),
              );
        }
      }
      unawaited(ref.read(activeGameProvider.notifier).refresh());
    });
  }

  void _clearSessionForFinishedGame() {
    clearBlockingGamePin(ref, ifGameId: widget.gameId);
    final prev = ref.read(activeGameProvider).valueOrNull;
    if (prev?.gameId == widget.gameId) {
      ref.read(activeGameProvider.notifier).clearLocal();
    }
  }

  // ---- helpers ------------------------------------------------------------

  String _streetLabel(String street) {
    final l10n = context.l10n;
    switch (street) {
      case PokerStreet.preflop:
        return l10n.pokerStreetPreflop;
      case PokerStreet.flop:
        return l10n.pokerStreetFlop;
      case PokerStreet.turn:
        return l10n.pokerStreetTurn;
      case PokerStreet.river:
        return l10n.pokerStreetRiver;
      case PokerStreet.showdown:
        return l10n.pokerStreetShowdown;
      default:
        return '';
    }
  }

  String _playerName(PokerPlayerView p) {
    final n = p.displayName?.trim() ?? '';
    if (n.isNotEmpty) return n;
    final me = ref.read(authStateProvider).valueOrNull;
    if (me != null && p.id == me.id) {
      final mine = (me.displayName ?? '').trim();
      if (mine.isNotEmpty) return mine;
    }
    return p.isBot ? context.l10n.gameBot : context.l10n.gameOpponent;
  }

  /// Свой аватар из профиля, если в партии он не пришёл (офлайн с ботами).
  ({String kind, String? value}) _playerAvatar(PokerPlayerView p) {
    var kind = p.avatarKind;
    var value = p.avatarValue;
    final me = ref.read(authStateProvider).valueOrNull;
    if (me != null && p.id == me.id && (value == null || value.isEmpty)) {
      kind = me.avatarKind;
      value = me.avatarValue;
    }
    return (kind: kind, value: value);
  }

  /// «A и B» / «A, B и C».
  String _joinWinnerNames(List<String> names) {
    final andWord = context.l10n.pokerListAnd;
    if (names.isEmpty) return '';
    if (names.length == 1) return names.first;
    if (names.length == 2) return '${names[0]} $andWord ${names[1]}';
    final head = names.sublist(0, names.length - 1).join(', ');
    return '$head $andWord ${names.last}';
  }

  /// Статус победителей раздачи: один / несколько / вы среди них.
  String _winnersStatus(PokerGameView game) {
    final l10n = context.l10n;
    final me = game.myIndex;
    final names = <String>[];
    var includesMe = false;
    for (final i in game.winners) {
      if (i < 0 || i >= game.players.length) continue;
      if (i == me) {
        includesMe = true;
        continue;
      }
      names.add(_playerName(game.players[i]));
    }
    if (!includesMe && names.isEmpty) return l10n.pokerHandOver;
    if (includesMe && names.isEmpty) return l10n.pokerYouWonHand;
    final joined = _joinWinnerNames(names);
    if (includesMe) return l10n.pokerYouWonHandWith(joined);
    if (names.length == 1) return l10n.pokerWinner(names.first);
    return l10n.pokerWinners(joined);
  }

  String _statusText(PokerGameView game) {
    final l10n = context.l10n;
    final place = game.myPlace;
    final iWon = game.iWon;
    // Весь стол окончен — как в дураке / крестиках.
    if (game.isOver) {
      if (iWon || place == 1) {
        if (game.players.length <= 2) {
          if (game.isForfeit) return l10n.gameYouWonOpponentForfeit;
          if (game.isTimeout) return l10n.gameYouWonOpponentTimeout;
        }
        return l10n.gameYouWon;
      }
      if (place > 1) return l10n.gameYouPlaced(place);
      if (game.isTimeout) return l10n.unoYouLostTimeout;
      if (game.stakeBronze > 0) return l10n.gameYouLost;
      if (game.winners.isNotEmpty) return _winnersStatus(game);
      return l10n.pokerHandOver;
    }
    if (game.iAmEliminated) {
      if (place > 1) return l10n.gameYouPlaced(place);
      return l10n.gameYouEliminated;
    }
    // Раздача завершена, стол продолжается.
    if (game.isHandOver) {
      if (game.winners.isNotEmpty) return _winnersStatus(game);
      return l10n.pokerHandOver;
    }
    // Во время улицы не показываем «Ваш ход» / «Ходит X» — ход виден по
    // рамке таймера у места и кнопкам действий; бейдж съедает место на столе.
    return '';
  }

  int _placeCredit(PokerGameView game) {
    final n = game.players.length.clamp(2, 6);
    final place = game.myPlace > 0
        ? game.myPlace
        : (game.iWon ? 1 : (game.isOver ? n : 0));
    if (place <= 0) return 0;
    return pokerPlaceCredit(
      stake: game.stakeBronze,
      playerCount: n,
      place: place,
    );
  }

  int _placeNet(PokerGameView game) {
    final n = game.players.length.clamp(2, 6);
    final place = game.myPlace > 0
        ? game.myPlace
        : (game.iWon ? 1 : (game.isOver ? n : 0));
    if (place <= 0) return 0;
    return pokerPlaceNetProfit(
      stake: game.stakeBronze,
      playerCount: n,
      place: place,
    );
  }

  int _rewardChipBronze(PokerGameView game) {
    if ((!game.isOver && !game.iAmEliminated) || game.stakeBronze <= 0) {
      return 0;
    }
    final net = _placeNet(game);
    if (net > 0) return net;
    final credit = _placeCredit(game);
    // «Ничего» (возврат ставки) — без чипа ±.
    if (credit >= game.stakeBronze) return 0;
    if (!_lossChipRevealed) return 0;
    return -game.stakeBronze;
  }

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

  void _maybeSettleGame(PokerGameView game) {
    // Итог стола или mid-game выбытие с известным местом.
    final settleNow = game.isOver || (game.iAmEliminated && game.myPlace > 0);
    if (!settleNow) return;
    if (_openedAsObserver || isGameBalanceSettled(ref, widget.gameId)) {
      _balanceGainPlayed = true;
      return;
    }
    if (_balanceGainPlayed || _isOffline) return;
    // Сразу, чтобы повторные build не ставили анимацию в очередь дважды.
    _balanceGainPlayed = true;
    if (game.stakeBronze <= 0) {
      markGameBalanceSettled(ref, widget.gameId);
      unawaited(ref.read(authStateProvider.notifier).refresh());
      return;
    }
    final credit = _placeCredit(game);
    final display = _placeNet(game);
    final lost = (credit < game.stakeBronze && game.stakeBronze > 0)
        ? game.stakeBronze
        : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Сбрасываем флаг: _onGameSettled снова выставит его сам.
      _balanceGainPlayed = false;
      unawaited(_onGameSettled(
        creditBronze: credit,
        displayRewardBronze: display,
        lostBronze: lost,
      ));
    });
  }

  /// Локализованное название комбинации по каноническому имени ранга сервера.
  String? _handRankLabel(String? rank) =>
      pokerHandRankLabel(context.l10n, rank);

  void _openCombinationsSheet(String? currentRank) {
    unawaited(
      showPokerCombinationsSheet(
        context: context,
        currentRank: currentRank,
      ),
    );
  }

  // ---- moves --------------------------------------------------------------

  bool _showPokerActions(PokerGameView game) {
    final meFolded = game.me?.folded ?? false;
    final keepHidden = pokerShouldKeepActionBarHidden(
      hideUntilSync: _hideActionsUntilSync,
      isMyTurn: game.isMyTurn,
      isHandOver: game.isHandOver,
      isOver: game.isOver,
      meFolded: meFolded,
    );
    if (_hideActionsUntilSync && !keepHidden) {
      _hideActionsUntilSync = false;
    }
    return pokerActionBarVisible(
      isOver: game.isOver,
      isHandOver: game.isHandOver,
      isMyTurn: game.isMyTurn,
      hasLegalActions: game.legalActions.isNotEmpty,
      meFolded: meFolded,
      hideUntilSync: _hideActionsUntilSync,
    );
  }

  Future<void> _move(
    String type, {
    int? amount,
    bool acquireLock = true,
  }) async {
    if (acquireLock && !_turnAction.tryAcquire()) return;
    _busy = true;
    if (mounted) setState(() {});
    // Колл/рейз: фишки остаются ставкой у места — в банк НЕ летят.
    // В банк — только сбор улицы (карты открылись) / фолд со ставкой / вскрытие.
    final gameSnap = ref.read(pokerGameProvider(widget.gameId)).valueOrNull ??
        (_isOffline
            ? OfflinePokerRegistry.instance.get(widget.gameId)?.view
            : null);
    final meSnap = gameSnap?.me;
    if (meSnap != null && type == PokerActionType.fold && meSnap.bet > 0) {
      _foldChipFlownSeats.add(meSnap.seat);
      unawaited(
        _flyChips(fromKey: _seatKey(meSnap.seat), toKey: _tableChipsKey),
      );
    }
    if (type == PokerActionType.fold) {
      Sfx.play(SfxId.cardPlay);
    } else if (type == PokerActionType.call ||
        type == PokerActionType.raise ||
        type == PokerActionType.allIn) {
      Sfx.play(SfxId.chip);
    }
    var succeeded = false;
    try {
      await ref
          .read(pokerRepositoryProvider)
          .move(widget.gameId, type: type, amount: amount);
      succeeded = true;
      if (mounted) {
        ref.invalidate(pokerGameProvider(widget.gameId));
        try {
          await ref.read(pokerGameProvider(widget.gameId).future);
        } catch (_) {}
      }
    } on GamesException catch (e) {
      if (mounted &&
          !isStaleNotYourTurnError(e) &&
          !isStaleGameOverError(e)) {
        showAppSnackBar(context,
            message: formatUserError(e), kind: AppSnackKind.error);
      }
    } catch (e) {
      if (mounted &&
          !isStaleNotYourTurnError(e) &&
          !isStaleGameOverError(e)) {
        showAppSnackBar(context,
            message: formatUserError(e), kind: AppSnackKind.error);
      }
    } finally {
      if (acquireLock) _turnAction.release();
      if (mounted) {
        if (succeeded) _hideActionsUntilSync = true;
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _openRaiseSheet(PokerGameView game) async {
    if (!_turnAction.tryAcquire()) return;
    _busy = true;
    if (mounted) setState(() {});
    try {
      final minTo = game.minRaiseTo;
      final maxTo = game.maxRaiseTo;
      if (maxTo <= 0) return;
      if (minTo >= maxTo) {
        // Единственный вариант — ва-банк.
        await _move(PokerActionType.allIn, acquireLock: false);
        return;
      }
      final step = game.bigBlind > 0 ? game.bigBlind : 1;
      var value = minTo;
      final chosen = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (ctx, setSheet) {
              final divisions = math.max(1, ((maxTo - minTo) / step).ceil());
              void nudge(int delta) {
                setSheet(() {
                  value = (value + delta * step).clamp(minTo, maxTo);
                });
              }
              return GamepadScope(
                onAction: (action) {
                  if (action == GamepadAction.shoulderL ||
                      action == GamepadAction.shoulderR) {
                    return false;
                  }
                  if (action == GamepadAction.left ||
                      action == GamepadAction.down) {
                    nudge(-1);
                    return true;
                  }
                  if (action == GamepadAction.right ||
                      action == GamepadAction.up) {
                    nudge(1);
                    return true;
                  }
                  if (action == GamepadAction.confirm) {
                    Navigator.of(ctx).pop(value);
                    return true;
                  }
                  if (action == GamepadAction.cancel) {
                    Navigator.of(ctx).pop();
                    return true;
                  }
                  return true;
                },
                child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GradientCard(
                    animate: false,
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          ctx.l10n.pokerRaiseTitle,
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ctx.l10n.pokerRaiseTo(value),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.accentStart,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Slider(
                          min: minTo.toDouble(),
                          max: maxTo.toDouble(),
                          divisions: divisions,
                          value: value.toDouble().clamp(
                                minTo.toDouble(),
                                maxTo.toDouble(),
                              ),
                          activeColor: AppColors.accentStart,
                          label: '$value',
                          onChanged: (v) => setSheet(() {
                            final snapped = (v / step).round() * step;
                            value = snapped.clamp(minTo, maxTo);
                          }),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$minTo',
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                            Text('$maxTo',
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: Text(ctx.l10n.commonCancel),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => Navigator.of(ctx).pop(value),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.accentStart,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(ctx.l10n.pokerRaise),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              );
            },
          );
        },
      );
      if (chosen == null || !mounted) return;
      if (chosen >= maxTo) {
        await _move(PokerActionType.allIn, acquireLock: false);
      } else {
        await _move(PokerActionType.raise, amount: chosen, acquireLock: false);
      }
    } finally {
      _turnAction.release();
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---- close / surrender / rematch ---------------------------------------

  Future<void> _confirmSurrender() async {
    final game = ref.read(pokerGameProvider(widget.gameId)).valueOrNull;
    if (game == null || game.isOver || game.iAmEliminated) return;
    final ok = await confirmSurrenderDialog(context);
    if (!ok || !mounted) return;
    unawaited(() async {
      try {
        clearBlockingGamePin(ref, ifGameId: widget.gameId);
        await ref.read(pokerRepositoryProvider).forfeit(widget.gameId);
      } catch (_) {}
      if (!mounted) return;
      if (!_isOffline) {
        ref.invalidate(pokerGameProvider(widget.gameId));
        try {
          final next = await ref.read(pokerGameProvider(widget.gameId).future);
          final multi = next.players.length > 2;
          if (multi && !next.isOver) {
            enterGameObservation(ref, widget.gameId, gameType: 'poker');
            _observeEntered = true;
          }
        } catch (_) {}
      }
      unawaited(ref.read(activeGameProvider.notifier).refresh());
    }());
  }

  Future<void> _onClosePressed() async {
    final game = ref.read(pokerGameProvider(widget.gameId)).valueOrNull;
    final eliminated = game?.iAmEliminated == true;
    await handleGameScreenClose(
      context: context,
      isActive: game != null && !game.isOver && !eliminated,
      canLeaveFreely: eliminated,
      onLeaveFinished: () async {
        if (!mounted) return;
        if (eliminated && game != null && !game.isOver) {
          enterGameObservation(ref, widget.gameId, gameType: 'poker');
          _observeEntered = true;
        }
        _navigateToGames(keepObservation: true);
      },
      onForfeitAndLeave: () async {
        if (!mounted) return;
        final multi = (game?.players.length ?? 0) > 2;
        try {
          clearBlockingGamePin(ref, ifGameId: widget.gameId);
          await ref.read(pokerRepositoryProvider).forfeit(widget.gameId);
        } catch (_) {}
        if (!mounted) return;
        if (multi) {
          enterGameObservation(ref, widget.gameId, gameType: 'poker');
          _observeEntered = true;
        }
        _navigateToGames(keepObservation: multi);
        unawaited(ref.read(activeGameProvider.notifier).refresh());
      },
    );
  }

  void _navigateToGames({bool keepObservation = false}) {
    leaveGamesSession(ref);
    final rematchLobbyId = _rematchLobbyId;
    _rematchLobbyId = null;
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
            .read(pokerRepositoryProvider)
            .leaveLobby(rematchLobbyId)
            .catchError((_) {}),
      );
    }
  }

  Future<void> _rematch() async {
    setState(() => _isRematching = true);
    try {
      if (_isOffline) {
        final session = OfflinePokerRegistry.instance.get(widget.gameId);
        if (session != null) {
          session.restart();
          ref.invalidate(pokerGameProvider(widget.gameId));
          if (mounted) setState(() => _isRematching = false);
          return;
        }
      }
      final lobbyId =
          await ref.read(pokerRepositoryProvider).rematch(widget.gameId);
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
              gameType: 'poker',
            ),
          );
      final game = ref.read(pokerGameProvider(widget.gameId)).valueOrNull;
      setState(() {
        _rematchLobbyId = lobbyId;
        _rematchDeclined = false;
        _iDeclinedRematch = false;
        _isRematching = false;
      });
      if (!rematchStayOnGameScreen(playerCount: game?.players.length ?? 2)) {
        if (!mounted) return;
        context.go('/games/poker/lobby/$lobbyId?mode=invite');
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
          await ref.read(pokerRepositoryProvider).leaveLobby(own);
        } catch (_) {}
        if (!mounted) return;
      }
      final result = await ref.read(pokerRepositoryProvider).joinLobby(lobbyId);
      if (!mounted) return;
      clearBlockingGamePin(ref);
      if (result.gameId != null && result.gameId!.isNotEmpty) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'game',
                gameId: result.gameId,
                lobbyId: lobbyId,
                gameType: 'poker',
              ),
            );
        pinBlockingGame(ref, result.gameId, gameType: 'poker');
        context.go('/games/poker/game/${result.gameId}');
      } else {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'lobby',
                lobbyId: lobbyId,
                gameType: 'poker',
              ),
            );
        context.go('/games/poker/lobby/$lobbyId?mode=invite');
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
            await ref.read(pokerRepositoryProvider).getLobby(_rematchLobbyId!);
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
            gameType: 'poker',
          ),
        );
    pinBlockingGame(ref, gameId, gameType: 'poker');
    ref.invalidate(pokerGameProvider(gameId));
    if (!mounted) return;
    context.go('/games/poker/game/$gameId');
  }

  Future<void> _declineRematch(String lobbyId) async {
    ref.read(gameInvitesProvider.notifier).remove(lobbyId);
    try {
      await ref.read(pokerRepositoryProvider).declineLobby(lobbyId);
    } catch (_) {}
    if (mounted) setState(() => _iDeclinedRematch = true);
  }

  Future<void> _cancelRematchWait() async {
    if (_rematchLobbyId == null) return;
    _rematchPollTimer?.cancel();
    final lobbyId = _rematchLobbyId!;
    setState(() => _rematchLobbyId = null);
    try {
      await ref.read(pokerRepositoryProvider).leaveLobby(lobbyId);
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
              .read(pokerRepositoryProvider)
              .leaveLobby(rematchId)
              .catchError((_) {}),
        );
      }
      final game = ref.read(pokerGameProvider(widget.gameId)).valueOrNull;
      final created = await ref.read(pokerRepositoryProvider).createLobby(
            mode: 'matchmake',
            maxPlayers: game?.playerIds.length ?? 2,
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
                gameType: 'poker',
              ),
            );
        pinBlockingGame(ref, created.gameId, gameType: 'poker');
        context.go('/games/poker/game/${created.gameId}');
        return;
      }
      ref.read(activeGameProvider.notifier).setLocal(
            ActiveGameItem(
              type: 'lobby',
              lobbyId: created.lobbyId,
              gameType: 'poker',
            ),
          );
      context.go('/games/poker/lobby/${created.lobbyId}?mode=matchmake');
    } catch (_) {
      if (mounted) context.go('/games');
    } finally {
      if (mounted) setState(() => _isFindingGame = false);
    }
  }

  List<String> _peerIds(PokerGameView game) {
    final me = game.myIndex;
    return [
      for (var i = 0; i < game.players.length; i++)
        if (i != me && !game.players[i].isBot) game.players[i].id,
    ];
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(pokerGameProvider(widget.gameId));
    final narrow = isNarrow(context);

    ref.listen(pokerGameProvider(widget.gameId), (_, next) {
      final game = next.valueOrNull;
      if (game == null) return;
      if (game.iAmEliminated &&
          !_observeEntered &&
          !game.isOver &&
          !_isOffline) {
        _observeEntered = true;
        enterGameObservation(ref, widget.gameId, gameType: 'poker');
        _maybeSettleGame(game);
      }
      if (game.isOver && !_prevOver) {
        _prevOver = true;
        _scheduleEndDialog();
        if (!_isOffline) {
          _clearSessionForFinishedGame();
          // Сеттл после паузы вместе с диалогом — чтобы сначала увидеть карты.
          unawaited(() async {
            await Future<void>.delayed(const Duration(milliseconds: 2200));
            if (!mounted) return;
            _maybeSettleGame(game);
          }());
        }
      } else if (!game.isOver) {
        _prevOver = false;
        // Выбывший наблюдатель: не сбрасывать settle — иначе ±монет снова.
        if (!game.iAmEliminated) {
          _balanceGainPlayed = false;
          _lossChipRevealed = false;
          _endDialogReady = false;
          _endDialogScheduled = false;
        }
      }
    });

    final game = gameAsync.valueOrNull;
    final groupChatId = (game?.chatId ?? '').trim();
    final showGroupChat =
        !_isOffline && game != null && groupChatId.isNotEmpty && !game.isOver;
    final groupUnread = !showGroupChat
        ? 0
        : ref.watch(chatsListProvider.select((async) {
            final list = async.valueOrNull;
            if (list == null) return 0;
            for (final c in list) {
              if (c.chatID == groupChatId) return c.unreadCount;
            }
            return 0;
          }));

    return GamepadScope(
      onAction: (action) {
        final current = ref.read(pokerGameProvider(widget.gameId)).valueOrNull;
        if (current == null) return false;
        return _onGamepad(current, action);
      },
      child: SwipeBackScope.gameBoard(
      onBack: _onClosePressed,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          toolbarHeight: gameToolbarHeight(context),
          leadingWidth: gameAppBarLeadingWidth(withExtra: showGroupChat),
          leading: buildGameAppBarLeading(
            onClose: _onClosePressed,
            extra: showGroupChat
                ? GameIconWithBadge(
                    icon: Icons.chat_bubble_outline_rounded,
                    tooltip: context.l10n.chatGroupTooltip,
                    badge: groupUnread,
                    onPressed: () => _openGroupChat(game),
                  )
                : null,
          ),
          title: Text(context.l10n.gamesPoker),
          centerTitle: true,
          actions: [
            if (gameAsync.valueOrNull != null &&
                !gameAsync.valueOrNull!.isOver &&
                !gameAsync.valueOrNull!.iAmEliminated)
              IconButton(
                tooltip: context.l10n.gameSurrender,
                icon: const Icon(Icons.flag_outlined),
                onPressed: () => unawaited(_confirmSurrender()),
              ),
            IconButton(
              tooltip: context.l10n.gamesRulesTitle,
              icon: const Icon(Icons.rule_rounded),
              onPressed: () {
                final game = gameAsync.valueOrNull;
                showGameRulesDialog(
                  context: context,
                  content: rulesTextLines(pokerRuleLines(
                    players: game?.playerIds.length ?? 2,
                    turnTimeSec: game?.turnTimeSec ?? 0,
                    stakeBronze: game?.stakeBronze ?? 0,
                    offlineBot: _isOffline,
                    l10n: context.l10n,
                  )),
                  closeLabel: context.l10n.commonClose,
                );
              },
            ),
          ],
        ),
        body: GradientBackground(
          child: SafeArea(
            child: gameAsync.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              data: (game) => _buildContent(game, narrow),
              loading: () => const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accentStart),
              ),
              error: (e, _) => Center(
                child: Text(
                  formatUserError(e,
                      fallback: context.l10n.commonServerErrorShort),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  List<String> _gamepadActions(PokerGameView game) {
    return [
      if (game.canDo(PokerActionType.fold)) PokerActionType.fold,
      if (game.canDo(PokerActionType.check)) PokerActionType.check,
      if (game.canDo(PokerActionType.call)) PokerActionType.call,
      if (game.canDo(PokerActionType.raise)) PokerActionType.raise,
      if (game.canDo(PokerActionType.allIn)) PokerActionType.allIn,
    ];
  }

  bool _onGamepad(PokerGameView game, GamepadAction action) {
    if (action == GamepadAction.shoulderL ||
        action == GamepadAction.shoulderR) {
      return false;
    }
    if (game.isOver) return false;
    final actions = _gamepadActions(game);
    if (actions.isNotEmpty) {
      _gamepadActionIndex = _gamepadActionIndex.clamp(0, actions.length - 1);
    }
    if (action.isDirection) {
      if (actions.isEmpty) return true;
      setState(() {
        _gamepadActionIndex =
            cycleIndex(_gamepadActionIndex, actions.length, action);
      });
      return true;
    }
    if (action == GamepadAction.confirm) {
      if (_busy || _turnAction.held || actions.isEmpty || !game.isMyTurn) {
        return true;
      }
      final chosen = actions[_gamepadActionIndex];
      if (chosen == PokerActionType.raise) {
        unawaited(_openRaiseSheet(game));
      } else {
        unawaited(_move(chosen));
      }
      return true;
    }
    return false;
  }

  Widget _buildContent(PokerGameView game, bool narrow) {
    _syncDeal(game);
    _syncChipFx(game);
    _syncFoldFx(game);
    if (game.isOver && !_endDialogScheduled && !_endDialogReady) {
      _scheduleEndDialog();
    }
    final isOver = game.isOver;
    final showEndDialog = isOver && _endDialogReady;
    final status = _statusText(game);
    final rewardBronze = _rewardChipBronze(game);
    final showReward =
        showEndDialog && game.stakeBronze > 0 && rewardBronze != 0;
    final betweenHands = game.isHandOver && !isOver;

    // Телефон в альбоме: под столом ~330 px — нижние слоты ужимаем, иначе
    // hero наезжает на борд.
    final tight = isPhoneLandscape(context);
    final showActions = _showPokerActions(game);
    final showCardsBtn = game.canShowCards && !isOver;
    final iWonHand = game.isHandOver &&
        game.me != null &&
        _winnerSeats(game).contains(game.me!.seat);
    final hasCombo = _handRankLabel(game.myHandRank) != null && !iWonHand;
    final comboSlot = _comboSlotHeight(tight: tight, hasCombo: hasCombo);
    final actionSlot = tight ? 42.0 : 52.0;
    // В альбоме кнопки лежат на самом столе: без отступа они срезаются его
    // бортиком и упираются в нижнюю кромку экрана.
    final bottomPad = tight ? 10.0 : (narrow ? 6.0 : 10.0);
    // Hero выезжает вверх только когда есть кнопки; поле/борд не двигаются.
    final heroLift = showActions || showCardsBtn
        ? comboSlot + (comboSlot > 0 ? 6 : 0) + actionSlot + bottomPad
        : (hasCombo ? comboSlot + bottomPad : bottomPad);

    return LayoutBuilder(
      builder: (context, constraints) {
        final short = constraints.maxHeight < 560;
        final veryShort = constraints.maxHeight < 480;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            MyTurnAlert.stackLeaf(
              isMyTurn: game.isMyTurn && !isOver && !game.isHandOver,
            ),
            Positioned.fill(
              child: _buildTable(
                game,
                narrow,
                short: short,
                veryShort: veryShort,
                tight: tight,
                // Пока ждём итоговое окно — статус на столе, чтобы видеть карты.
                status: showEndDialog ? '' : status,
                showReward: false,
                rewardBronze: rewardBronze,
                betweenHands: betweenHands,
                // Hero отдельно анимируется снизу — стол/борд фиксированы.
                heroBottom: showEndDialog ? 12.0 : heroLift,
              ),
            ),
            // Итог — панелью снизу, без затемнения: плашки соперников видно
            // и после партии, по ним можно открыть профиль, чат и «в друзья».
            if (showEndDialog)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      narrow ? 12 : 24,
                      0,
                      narrow ? 12 : 24,
                      bottomPad + 8,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 360,
                        maxHeight: constraints.maxHeight * 0.56,
                      ),
                      child: GradientCard(
                        animate: false,
                        margin: EdgeInsets.zero,
                        padding: EdgeInsets.fromLTRB(
                          narrow ? 16 : 20,
                          18,
                          narrow ? 16 : 20,
                          16,
                        ),
                        // Статус + награда + реванш — одно окно; в альбоме
                        // высоты мало, поэтому окно ещё и скроллится.
                        child: SingleChildScrollView(
                          child: _buildEndDialog(
                            game,
                            status: status,
                            showReward: showReward,
                            rewardBronze: rewardBronze,
                            narrow: narrow,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomBar(game, narrow, tight: tight),
              ),
          ],
        );
      },
    );
  }

  // ---- появление карт борда (fade/scale, без колоды) ---------------------

  /// Показывает новые общие карты по одной с короткой задержкой.
  void _syncDeal(PokerGameView game) {
    final len = game.community.length;
    if (game.handNumber != _dealHand || len < _shownCommunity) {
      _dealHand = game.handNumber;
      _shownCommunity = 0;
      _dealing = false;
    }
    if (len <= _shownCommunity || _dealing) return;
    _dealing = true;
    unawaited(_revealCommunity(len));
  }

  Future<void> _revealCommunity(int to) async {
    while (_shownCommunity < to) {
      if (!mounted || _disposed) {
        _dealing = false;
        return;
      }
      await Future<void>.delayed(
        Duration(milliseconds: _shownCommunity == 0 ? 30 : 95),
      );
      if (!mounted || _disposed) {
        _dealing = false;
        return;
      }
      setState(() => _shownCommunity++);
      Sfx.play(SfxId.cardPlay);
    }
    _dealing = false;
  }

  void _openGroupChat(PokerGameView game) {
    final chatId = (game.chatId ?? '').trim();
    if (chatId.isEmpty) return;
    final uri = Uri(
      path: '/chats/$chatId',
      queryParameters: {
        'from': 'games',
        'game': '/games/poker/game/${widget.gameId}',
      },
    );
    context.push(uri.toString());
  }

  Future<void> _showPlayerCard(PokerPlayerView p) async {
    if (!mounted) return;
    if (p.isBot) {
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: GradientCard(
              animate: false,
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GamePlayerAvatar(
                    displayName: _playerName(p),
                    avatarKind: p.avatarKind,
                    avatarValue: p.avatarValue,
                    frameCode: p.frameCode,
                    frameColor: p.frameColor,
                    compact: false,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _playerName(p),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${p.chips}',
                    style: const TextStyle(
                      color: AppColors.accentStart,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(context.l10n.commonClose),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }
    await showUserProfileDialog(
      context: context,
      ref: ref,
      userId: p.id,
      displayName: _playerName(p),
      avatarKind: p.avatarKind,
      avatarValue: p.avatarValue,
      frameCode: p.frameCode,
      frameColor: p.frameColor,
      messageFrom: 'games',
      messageReturnPath: '/games/poker/game/${widget.gameId}',
    );
  }

  /// Одно окно конца стола: результат, награда и кнопки реванша.
  Widget _buildEndDialog(
    PokerGameView game, {
    required String status,
    required bool showReward,
    required int rewardBronze,
    required bool narrow,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status.isNotEmpty) ...[
          GameStatusWithReward(
            statusText: status,
            showReward: showReward,
            rewardBronze: rewardBronze,
            rewardKey: _winRewardKey,
            fontSize: narrow ? 15 : 16,
            maxLines: 3,
            wrap: true,
          ),
          const SizedBox(height: 16),
        ],
        if (_isOffline)
          Center(
            child: FilledButton.icon(
              onPressed: _isRematching ? null : () => unawaited(_rematch()),
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: Text(context.l10n.offlinePlayAgain),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentStart,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
              ),
            ),
          )
        else
          GameRematchSection(
            rematchLobbyId: _rematchLobbyId,
            rematchDeclined: _rematchDeclined,
            iDeclinedRematch: _iDeclinedRematch,
            isRematching: _isRematching,
            isAcceptingRematch: _isAcceptingRematch,
            isFindingGame: _isFindingGame,
            peerIds: _peerIds(game),
            invites: ref.watch(gameInvitesProvider),
            onRematch: () => unawaited(_rematch()),
            onAccept: (id) => unawaited(_acceptRematch(id)),
            onDecline: (id) => unawaited(_declineRematch(id)),
            onCancelWait: () => unawaited(_cancelRematchWait()),
            onFindGame: () => unawaited(_findGame()),
            compact: true,
            table: RematchTable(
              gameType: 'poker',
              stakeBronze: game.stakeBronze,
              gameMode: 'holdem',
            ),
          ),
      ],
    );
  }

  /// Овальный стол: аватары на кромке, борд фиксирован; hero выезжает снизу.
  Widget _buildTable(
    PokerGameView game,
    bool narrow, {
    bool short = false,
    bool veryShort = false,
    bool tight = false,
    required String status,
    required bool showReward,
    required int rewardBronze,
    required bool betweenHands,
    required double heroBottom,
  }) {
    final me = game.myIndex;
    final opponents = _opponentsInDisplayOrder(game);
    final oppAnchors = _seatAnchors(opponents.length, landscape: tight);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardSize = _communityCardSize(
          constraints.maxWidth,
          narrow,
          short: short || veryShort,
        );
        final feltPadH = narrow ? 0.0 : 4.0;
        final feltPadV = narrow ? 0.0 : 2.0;
        final radius = narrow
            ? (constraints.maxWidth * 0.22).clamp(28.0, 44.0)
            : (constraints.maxWidth * 0.18).clamp(40.0, 64.0);
        final sidePad = narrow ? 2.0 : 6.0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: feltPadH,
                  vertical: feltPadV,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    gradient: const RadialGradient(
                      colors: [Color(0xFF1F7A4D), Color(0xFF135C39)],
                      radius: 0.95,
                    ),
                    border: Border.all(
                      color: const Color(0xFF0C3D26),
                      width: narrow ? 4 : 6,
                    ),
                  ),
                ),
              ),
            ),
            // Борд + соперники — фиксированная зона (не прыгает с кнопками).
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(sidePad, 4, sidePad, 8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // В альбоме борд центрируем в остатке над своими картами:
                    // фиксированный якорь при такой высоте попадает прямо в них.
                    // Если в остаток не влезает даже сжатая колонка (статус +
                    // борд), FittedBox уменьшает её, а не роняет overflow.
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: tight
                            ? heroBottom +
                                _heroBlockHeight(
                                  game,
                                  narrow,
                                  compact: short || veryShort,
                                )
                            : 0,
                      ),
                      child: Align(
                        alignment: Alignment(
                          0,
                          tight ? 0 : (veryShort ? -0.02 : -0.06),
                        ),
                        child: Builder(
                          builder: (context) {
                            final center = _buildCenter(
                              game,
                              narrow,
                              cardSize,
                              compact: short || veryShort,
                              tight: tight,
                              status: status,
                              showReward: showReward,
                              rewardBronze: rewardBronze,
                              betweenHands: betweenHands,
                            );
                            if (!tight) return center;
                            return FittedBox(
                              fit: BoxFit.scaleDown,
                              child: center,
                            );
                          },
                        ),
                      ),
                    ),
                    // Нижние боковые места в альбоме упираются в ряд кнопок:
                    // он лежит на самом фетре во всю ширину. Отдаём соперникам
                    // только фетр над кнопками.
                    for (var i = 0; i < opponents.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: tight ? heroBottom : 0,
                        ),
                        child: Align(
                          alignment: oppAnchors[i],
                          child: _buildSeat(
                            game,
                            opponents[i],
                            narrow,
                            align: oppAnchors[i],
                            compact: short || veryShort,
                            sideways: tight,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Hero у нижнего края; ставка/D — рядом с профилем (не у края экрана).
            if (me >= 0 && me < game.players.length)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: sidePad,
                right: sidePad,
                bottom: heroBottom,
                child: Center(
                  child: _buildHeroOnTable(
                    game,
                    narrow,
                    compact: short || veryShort,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Размер своих карт: чуть крупнее борда, без гигантского веера.
  Size _heroCardSize(bool narrow, int playerCount, {bool compact = false}) {
    if (compact) {
      if (playerCount <= 2) {
        return narrow ? const Size(48, 68) : const Size(54, 76);
      }
      return narrow ? const Size(40, 56) : const Size(46, 66);
    }
    if (playerCount <= 2) {
      return narrow ? const Size(54, 76) : const Size(62, 88);
    }
    if (playerCount <= 4) {
      return narrow ? const Size(48, 68) : const Size(56, 80);
    }
    return narrow ? const Size(42, 60) : const Size(48, 68);
  }

  PokerWinnerHand? _winnerHandForSeat(PokerGameView game, int seat) {
    for (final wh in game.winnerHands) {
      if (wh.seat == seat) return wh;
    }
    return null;
  }

  /// Соперники по кругу от героя (по часовой): слева снизу → верх → справа снизу.
  /// Так якоря 6-max совпадают с раскладкой «Оппонент 1…5».
  List<PokerPlayerView> _opponentsInDisplayOrder(PokerGameView game) {
    final me = game.myIndex;
    final n = game.players.length;
    if (n == 0) return const [];
    if (me < 0 || me >= n) return List.of(game.players);
    final out = <PokerPlayerView>[];
    for (var k = 1; k < n; k++) {
      out.add(game.players[(me + k) % n]);
    }
    return out;
  }

  List<Alignment> _seatAnchors(int n, {bool landscape = false}) =>
      pokerOpponentSeatAnchors(n, landscape: landscape);

  /// Высота блока героя: карты приподняты над неймплейтом, поэтому колонка
  /// профиля в высоту не попадает. Нужна, чтобы борд встал строго над ней.
  double _heroBlockHeight(
    PokerGameView game,
    bool narrow, {
    required bool compact,
  }) {
    final me = game.me;
    if (me == null) return 0;
    final cards = _heroCardSize(narrow, game.players.length, compact: compact);
    final showBet = me.bet > 0 && !me.folded;
    final isDealer = game.dealerIndex == game.myIndex;
    // namePlateH 34 + avatarPlateGap 3 + блок ставки/дилера.
    final betBlock = (showBet || isDealer) ? 24.0 : 0.0;
    return cards.height + 37 + betBlock;
  }

  /// Размер общей карты: 5 карт в ряд с небольшими зазорами.
  Size _communityCardSize(
    double maxWidth,
    bool narrow, {
    bool short = false,
  }) {
    final maxW = short ? (narrow ? 52.0 : 64.0) : (narrow ? 68.0 : 90.0);
    final minW = short ? 36.0 : 40.0;
    final avail = maxWidth - (narrow ? 12.0 : 40.0);
    var w = (avail - 20.0) / 5;
    if (w > maxW) w = maxW;
    if (w < minW) w = minW;
    return Size(w, w / 0.7);
  }

  /// Подсвечивать карты комбинации: на вскрытии всегда; в раздаче — от пары и выше.
  bool _shouldHighlightCombo(PokerGameView game) {
    if (game.isShowdown) return game.highlightKeys.isNotEmpty;
    final rank = game.myHandRank;
    if (rank == null || rank.isEmpty || rank == 'HighCard') return false;
    return game.highlightKeys.isNotEmpty;
  }

  Widget _buildCenter(
    PokerGameView game,
    bool narrow,
    Size cardSize, {
    bool compact = false,
    bool tight = false,
    required String status,
    required bool showReward,
    required int rewardBronze,
    required bool betweenHands,
  }) {
    final highlightKeys = game.highlightKeys;
    final hasHighlight = _shouldHighlightCombo(game);
    final gap = compact ? 4.0 : 6.0;
    final isOver = game.isOver;

    // Улица + чей ход — в центре, не поверх аватара соперника.
    final streetLabel = Text(
      _streetLabel(game.street),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: compact ? 11 : 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        shadows: const [
          Shadow(color: Color(0x99000000), blurRadius: 6),
        ],
      ),
    );
    // Банк — только уже собранные фишки (без текущих ставок на улице).
    final potRow = Builder(
      builder: (context) {
        final collected = _collectedPot(game);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            KeyedSubtree(
              key: _tableChipsKey,
              child: _TableChipStack(amount: collected),
            ),
            if (collected > 0) ...[
              const SizedBox(width: 6),
              _PotBadge(
                amount: collected,
                label: context.l10n.pokerPot(collected),
              ),
            ],
          ],
        );
      },
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // В альбоме улица и банк идут одной строкой: по вертикали каждый
        // лишний ряд отбирает высоту у борда, а по горизонтали место есть.
        if (tight)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              streetLabel,
              const SizedBox(width: 10),
              potRow,
            ],
          )
        else
          streetLabel,
        if (status.isNotEmpty) ...[
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: narrow ? 260 : 320,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: showReward ? 8 : 12,
                  vertical: showReward ? 5 : 4,
                ),
                child: isOver
                    ? GameStatusWithReward(
                        statusText: status,
                        showReward: showReward,
                        rewardBronze: rewardBronze,
                        rewardKey: _winRewardKey,
                        fontSize: compact ? 14 : 16,
                      )
                    : GameStatusLine(
                        text: status,
                        highlight: game.isMyTurn && !isOver && !game.isHandOver,
                      ),
              ),
            ),
          ),
        ],
        if (betweenHands) ...[
          const SizedBox(height: 4),
          Text(
            context.l10n.pokerNextHandSoon,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(color: Color(0x99000000), blurRadius: 6),
              ],
            ),
          ),
        ],
        if (!tight) ...[
          SizedBox(height: gap),
          potRow,
        ],
        SizedBox(height: gap),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < 5; i++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: narrow ? 2.0 : 3.5),
                child: SizedBox(
                  width: cardSize.width,
                  height: cardSize.height,
                  child: _communitySlot(
                    game,
                    i,
                    cardSize,
                    highlightKeys: highlightKeys,
                    hasHighlight: hasHighlight,
                  ),
                ),
              ),
          ],
        ),
        // В альбоме номер раздачи и блайнды убираем: их строка упирается
        // в свои карты. Всё важное — банк, борд, стек — остаётся.
        if (!tight) ...[
          SizedBox(height: gap),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoBadge(context.l10n.pokerHandNumber(game.handNumber)),
              if (game.smallBlind > 0 || game.bigBlind > 0) ...[
                const SizedBox(width: 6),
                _infoBadge(
                  context.l10n.pokerBlinds(game.smallBlind, game.bigBlind),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _communitySlot(
    PokerGameView game,
    int i,
    Size cardSize, {
    required Set<int> highlightKeys,
    required bool hasHighlight,
  }) {
    if (i >= _shownCommunity || i >= game.community.length) {
      return _emptyCardSlot(cardSize);
    }
    final c = game.community[i];
    final hl =
        hasHighlight && highlightKeys.contains(PokerGameView.cardKeyOf(c));
    final dim = hasHighlight && !hl;
    return _EntranceCard(
      key: ValueKey('board_${game.handNumber}_${i}_${c.rank}_${c.suit}'),
      child: PlayingCardWidget(
        card: c.toPlayingCard(),
        size: cardSize,
        highlighted: hl,
        dimmed: dim,
        animate: false,
      ),
    );
  }

  Widget _infoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _emptyCardSlot(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(size.width * 0.15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
    );
  }

  GlobalKey _seatKey(int seat) => _seatKeys.putIfAbsent(seat, GlobalKey.new);

  /// Собранный банк: без текущих ставок активных игроков.
  /// Ставки фолдов уже «в банке» (бейдж ставки у места скрыт).
  int _collectedPot(PokerGameView game) {
    var street = 0;
    for (final p in game.players) {
      if (!p.folded) street += p.bet;
    }
    final collected = game.pot - street;
    return collected < 0 ? 0 : collected;
  }

  /// Фишки в банк: сбор улицы (открытие карт), фолд со ставкой, вскрытие/выплата.
  /// Колл и рейз — без полёта: ставка остаётся у места.
  void _syncChipFx(PokerGameView game) {
    if (game.handNumber != _prevHandNumber) {
      _prevHandNumber = game.handNumber;
      _prevHandOver = false;
      _foldChipFlownSeats.clear();
      _prevBets
        ..clear()
        ..addEntries(game.players.map((p) => MapEntry(p.seat, p.bet)));
      _prevChips
        ..clear()
        ..addEntries(game.players.map((p) => MapEntry(p.seat, p.chips)));
      // Блайнды остаются ставкой у мест — в банк не летят.
      return;
    }
    if (!game.isHandOver) {
      // Сбор улицы: у кого-то была ставка, теперь у всех bet==0
      // (обычно вместе с флопом/тёрном/ривером).
      final hadStreetBets = _prevBets.values.any((b) => b > 0);
      final streetCleared =
          hadStreetBets && game.players.every((p) => p.bet <= 0);
      if (streetCleared) {
        final donors = <int>{
          for (final e in _prevBets.entries)
            if (e.value > 0 && !_foldChipFlownSeats.contains(e.key)) e.key,
        };
        // Колл в том же кадре, что и сбор: prev bet мог быть 0, но стек упал.
        for (final p in game.players) {
          if (_foldChipFlownSeats.contains(p.seat)) continue;
          final prev = _prevChips[p.seat];
          if (prev != null && p.chips < prev) donors.add(p.seat);
        }
        if (donors.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (final seat in donors.take(4)) {
              unawaited(
                _flyChips(fromKey: _seatKey(seat), toKey: _tableChipsKey),
              );
            }
          });
        }
      }
    }
    // Вскрытие / конец раздачи: оставшиеся ставки → банк → победителю.
    if (game.isHandOver && !_prevHandOver && game.winners.isNotEmpty) {
      final leftover = <int>{
        for (final e in _prevBets.entries)
          if (e.value > 0 && !_foldChipFlownSeats.contains(e.key)) e.key,
      };
      for (final p in game.players) {
        if (_foldChipFlownSeats.contains(p.seat)) continue;
        final prev = _prevChips[p.seat];
        if (prev != null && p.chips < prev) leftover.add(p.seat);
      }
      final seats = _winnerSeats(game);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        for (final seat in leftover.take(4)) {
          unawaited(
            _flyChips(fromKey: _seatKey(seat), toKey: _tableChipsKey),
          );
        }
        if (leftover.isNotEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 280));
        }
        if (!mounted || _disposed) return;
        for (final seat in seats.take(2)) {
          unawaited(_flyChips(
            fromKey: _tableChipsKey,
            toKey: _seatKey(seat),
            count: 5,
            color: const Color(0xFFF5B301),
          ));
        }
      });
    }
    _prevHandOver = game.isHandOver;
    _prevBets
      ..clear()
      ..addEntries(game.players.map((p) => MapEntry(p.seat, p.bet)));
    _prevChips
      ..clear()
      ..addEntries(game.players.map((p) => MapEntry(p.seat, p.chips)));
  }

  /// `winners` в API — индексы игроков; для UI нужны seat-ключи.
  Set<int> _winnerSeats(PokerGameView game) {
    return {
      for (final i in game.winners)
        if (i >= 0 && i < game.players.length) game.players[i].seat,
    };
  }

  Future<void> _flyChips({
    required GlobalKey fromKey,
    required GlobalKey toKey,
    int count = 3,
    Color color = const Color(0xFFE8C547),
  }) async {
    if (!mounted || _disposed) return;
    if (GameFlyOverlay.shouldPlayGameSfx(context: context)) {
      Sfx.play(SfxId.chip);
    }
    if (!GameFlyOverlay.shouldShowFlight(context: context, gameOnly: true)) {
      return;
    }
    final from = globalRectOf(fromKey);
    final to = globalRectOf(toKey);
    if (from == null || to == null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    for (var i = 0; i < count; i++) {
      if (!mounted || _disposed) return;
      final jitter = Offset(
        (i - count / 2) * 6,
        (i % 2 == 0 ? -1 : 1) * 4.0,
      );
      _spawnChipFly(
        overlay: overlay,
        from: from.center.translate(jitter.dx, jitter.dy),
        to: to.center,
        color: color,
        delayMs: i * 55,
      );
    }
  }

  void _spawnChipFly({
    required OverlayState overlay,
    required Offset from,
    required Offset to,
    required Color color,
    required int delayMs,
  }) {
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted ||
          _disposed ||
          !GameFlyOverlay.shouldShowFlight(context: context, gameOnly: true)) {
        return;
      }
      late OverlayEntry entry;
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 520),
      );
      _chipControllers.add(controller);
      final curved =
          CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);
      entry = GameFlyOverlay.insert(
        overlay,
        (_) {
          return IgnorePointer(
            child: AnimatedBuilder(
              animation: curved,
              builder: (context, _) {
                final t = curved.value;
                final x = from.dx + (to.dx - from.dx) * t;
                final y = from.dy +
                    (to.dy - from.dy) * t -
                    28 * math.sin(math.pi * t);
                final s = 1.0 - 0.25 * t;
                return Stack(
                  children: [
                    Positioned(
                      left: x - 9,
                      top: y - 9,
                      child: Opacity(
                        opacity: (1 - t * 0.15).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: s,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color,
                                  Color.lerp(color, Colors.black, 0.25)!,
                                ],
                              ),
                              border:
                                  Border.all(color: Colors.white, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
        host: context,
        gameOnly: true,
      );
      controller.forward().whenComplete(() {
        GameFlyOverlay.remove(entry);
        curved.dispose();
        controller.dispose();
        _chipControllers.remove(controller);
      });
    });
  }

  /// Место соперника: аватар + неймплейт; вскрытие — над/под профилем.
  /// Рамка хода только вокруг неймплейта; ставка рисуется отдельно на фетре.
  Widget _buildSeat(
    PokerGameView game,
    PokerPlayerView p,
    bool narrow, {
    required Alignment align,
    bool compact = false,
    bool sideways = false,
  }) {
    final acting = p.isActing && !game.isOver && !game.isHandOver;
    final isWinner = game.isHandOver && _winnerSeats(game).contains(p.seat);
    final dim = p.folded;

    // Чужие hole_cards приходят только на showdown или после «Показать карты».
    final reveal = !p.folded && p.holeCards != null && p.holeCards!.length >= 2;
    final showCards = reveal;
    final holeSize = compact
        ? (narrow ? const Size(36, 50) : const Size(42, 60))
        : (narrow ? const Size(44, 62) : const Size(52, 74));
    final plateW = compact ? (narrow ? 72.0 : 80.0) : (narrow ? 78.0 : 86.0);
    const borderW = 2.0;

    // Подсветка карт победителя — из его winner_hand, не из моей комбинации.
    final wh = _winnerHandForSeat(game, p.seat);
    final oppHighlight = {
      if (wh != null)
        for (final c in wh.cards) PokerGameView.cardKeyOf(c),
    };
    final hasOppHl = reveal && isWinner && oppHighlight.isNotEmpty;
    final winnerCombo = (reveal && isWinner) ? _handRankLabel(wh?.rank) : null;

    // Непрозрачный фон — иначе на web карты «просвечивают» сквозь неймплейт.
    final namePlate = Container(
      width: plateW,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: dim ? const Color(0xFF2A2A2A) : const Color(0xFF161616),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWinner
              ? const Color(0xFFF5B301)
              : Colors.white.withValues(alpha: 0.08),
          width: isWinner ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _playerName(p),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: dim ? 0.4 : 1),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          Text(
            p.folded
                ? context.l10n.pokerFolded
                : p.allIn
                    ? context.l10n.pokerAllInBadge
                    : '${p.chips}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: dim
                  ? Colors.white38
                  : p.allIn
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFF5D76E),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ],
      ),
    );

    // Только аватар+неймплейт задают размер — Align не прыгает при показе карт.
    final plateColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: dim ? 0.35 : 1,
          child: GestureDetector(
            onTap: () => unawaited(_showPlayerCard(p)),
            behavior: HitTestBehavior.opaque,
            child: GamePlayerAvatar(
              displayName: _playerName(p),
              avatarKind: p.avatarKind,
              avatarValue: p.avatarValue,
              frameCode: p.frameCode,
              frameColor: p.frameColor,
              compact: true,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Рамка только на ход — idle без обводки, padding стабильный.
        GestureDetector(
          onTap: () => unawaited(_showPlayerCard(p)),
          behavior: HitTestBehavior.opaque,
          child: TurnTimerBorder(
            key: ValueKey('poker-seat-${p.seat}-${game.turnDeadline}'),
            active: acting,
            turnDeadline: game.turnDeadline,
            turnTimeSec: game.turnTimeSec,
            borderWidth: borderW,
            radius: 10,
            showIdleBorder: false,
            child: namePlate,
          ),
        ),
      ],
    );

    final cardsWidth = holeSize.width * 1.55;
    final holePlace = pokerOppHolePlacement(align, sideways: sideways);
    final cardsOnLeft = align.x < -0.05;
    final plateH = pokerOppPlateHeight(compact: compact);
    final holeOffset = pokerOppHoleOffset(
      align: align,
      plateWidth: plateW,
      plateHeight: plateH,
      cardsWidth: cardsWidth,
      cardsHeight: holeSize.height,
      sideways: sideways,
    );
    final showBet = p.bet > 0 && !p.folded;
    final isDealer = game.dealerIndex >= 0 &&
        game.dealerIndex < game.players.length &&
        game.players[game.dealerIndex].seat == p.seat;
    // Зазор от неймплейта: на телефоне чуть больше, чтобы ставка не
    // наезжала на рамку профиля.
    final betGap = narrow ? 16.0 : 12.0;

    return KeyedSubtree(
      key: _seatKey(p.seat),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (showCards)
            Positioned(
              left: holeOffset.dx,
              top: holeOffset.dy,
              child: SizedBox(
                width: cardsWidth,
                height: holeSize.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < 2; i++)
                      Positioned(
                        left: i * holeSize.width * 0.55,
                        child: PlayingCardWidget(
                          card: p.holeCards![i].toPlayingCard(),
                          size: holeSize,
                          highlighted: hasOppHl &&
                              oppHighlight.contains(
                                PokerGameView.cardKeyOf(p.holeCards![i]),
                              ),
                          dimmed: hasOppHl &&
                              !oppHighlight.contains(
                                PokerGameView.cardKeyOf(p.holeCards![i]),
                              ),
                          animate: false,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          plateColumn,
          if (showBet || isDealer)
            Positioned(
              // Ставка со стороны центра стола / свободной стороны.
              left: cardsOnLeft ? plateW + betGap : null,
              right: cardsOnLeft ? null : plateW + betGap,
              // На уровне неймплейта — не на круге аватара.
              bottom: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: cardsOnLeft
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  if (showBet) _tableBetLabel(p.bet),
                  if (isDealer) ...[
                    if (showBet) const SizedBox(height: 4),
                    _dealerBadge(size: narrow ? 20 : 24),
                  ],
                ],
              ),
            ),
          if (winnerCombo != null)
            Positioned(
              top: holePlace == PokerOppHolePlacement.below
                  ? plateH + 4 + holeSize.height + 4
                  : null,
              bottom: holePlace == PokerOppHolePlacement.below ? null : -26,
              child: _comboLabel(winnerCombo, highlight: true),
            ),
        ],
      ),
    );
  }

  /// Ставка на столе: мини-стопка + сумма.
  Widget _tableBetLabel(int amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniChipStack(),
        const SizedBox(width: 4),
        Text(
          '$amount',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniChipStack() {
    return SizedBox(
      width: 18,
      height: 14,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          for (var i = 0; i < 3; i++)
            Positioned(
              bottom: i * 2.2,
              child: Container(
                width: 14 - i * 0.4,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(
                          const Color(0xFFE8C547), Colors.white, i * 0.1)!,
                      const Color(0xFFC9A227),
                    ],
                  ),
                  border: Border.all(color: Colors.white, width: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Анимация сброса: рубашки летят от рамки соперника к центру стола.
  void _syncFoldFx(PokerGameView game) {
    if (game.handNumber != _foldHand) {
      _foldHand = game.handNumber;
      _prevFolded
        ..clear()
        ..addEntries(game.players.map((p) => MapEntry(p.seat, p.folded)));
      return;
    }
    for (final p in game.players) {
      final was = _prevFolded[p.seat] ?? false;
      if (p.folded && !was) {
        final seat = p.seat;
        final hadBet = (_prevBets[seat] ?? 0) > 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_throwFoldCards(seat));
          // Соперник (или мы без локального полёта) сбросил со ставкой.
          if (hadBet && !_foldChipFlownSeats.contains(seat)) {
            _foldChipFlownSeats.add(seat);
            unawaited(
              _flyChips(fromKey: _seatKey(seat), toKey: _tableChipsKey),
            );
          }
        });
      }
    }
    _prevFolded
      ..clear()
      ..addEntries(game.players.map((p) => MapEntry(p.seat, p.folded)));
  }

  Future<void> _throwFoldCards(int seat) async {
    if (!mounted || _disposed) return;
    if (GameFlyOverlay.shouldPlayGameSfx(context: context)) {
      Sfx.play(SfxId.cardPlay);
    }
    if (!GameFlyOverlay.shouldShowFlight(context: context, gameOnly: true)) {
      return;
    }
    final from = globalRectOf(_seatKey(seat));
    final to = globalRectOf(_tableChipsKey);
    if (from == null || to == null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    const cardSize = Size(34, 48);
    for (var i = 0; i < 2; i++) {
      if (!mounted || _disposed) return;
      final start = from.center.translate((i == 0 ? -10 : 10).toDouble(), -8);
      final end = to.center.translate((i == 0 ? -14 : 14).toDouble(), -6);
      _spawnFoldCardFly(
        overlay: overlay,
        from: start,
        to: end,
        size: cardSize,
        delayMs: i * 70,
        spin: i == 0 ? -0.55 : 0.7,
      );
    }
  }

  void _spawnFoldCardFly({
    required OverlayState overlay,
    required Offset from,
    required Offset to,
    required Size size,
    required int delayMs,
    required double spin,
  }) {
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted ||
          _disposed ||
          !GameFlyOverlay.shouldShowFlight(context: context, gameOnly: true)) {
        return;
      }
      late OverlayEntry entry;
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      );
      _chipControllers.add(controller);
      final curved =
          CurvedAnimation(parent: controller, curve: Curves.easeInCubic);
      entry = GameFlyOverlay.insert(
        overlay,
        (_) {
          return IgnorePointer(
            child: AnimatedBuilder(
              animation: curved,
              builder: (context, _) {
                final t = curved.value;
                final x = from.dx + (to.dx - from.dx) * t;
                final y = from.dy +
                    (to.dy - from.dy) * t -
                    36 * math.sin(math.pi * t);
                final rot = spin * t;
                final opacity = (1.0 - t * 0.85).clamp(0.0, 1.0);
                final scale = 1.0 - 0.35 * t;
                return Stack(
                  children: [
                    Positioned(
                      left: x - size.width / 2,
                      top: y - size.height / 2,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.rotate(
                          angle: rot,
                          child: Transform.scale(
                            scale: scale,
                            child: CardBackWidget(size: size, outlined: true),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
        host: context,
        gameOnly: true,
      );
      controller.forward().whenComplete(() {
        GameFlyOverlay.remove(entry);
        curved.dispose();
        controller.dispose();
        _chipControllers.remove(controller);
      });
    });
  }

  Widget _dealerBadge({double size = 24}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE082), Color(0xFFF5B301)],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5B301).withValues(alpha: 0.5),
            blurRadius: 6,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Text(
        'D',
        style: TextStyle(
          color: const Color(0xFF5C3B00),
          fontSize: size * 0.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  /// Hero по центру низа: крупный веер выглядывает из-за аватара.
  /// Профиль (аватар+неймплейт) — единственный якорь Align, карты его не сдвигают.
  Widget _buildHeroOnTable(
    PokerGameView game,
    bool narrow, {
    bool compact = false,
  }) {
    final me = game.me;
    if (me == null) return const SizedBox.shrink();
    final heroAvatar = _playerAvatar(me);
    final heroCards = _heroCardSize(
      narrow,
      game.players.length,
      compact: compact,
    );
    final highlightKeys = game.highlightKeys;
    final hasHighlight = _shouldHighlightCombo(game);
    final acting = me.isActing && !game.isOver && !game.isHandOver;
    final isWinner = game.isHandOver && _winnerSeats(game).contains(me.seat);
    final dim = me.folded;
    final plateW = compact ? (narrow ? 72.0 : 80.0) : (narrow ? 78.0 : 86.0);
    const borderW = 2.0;
    // Compact GamePlayerAvatar: FramedAvatar size = 36.
    const avatarSize = 36.0;
    const avatarPlateGap = 3.0;
    // Компактный неймплейт + запас под рамку хода.
    const namePlateH = 34.0;
    final myWinCombo = isWinner
        ? _handRankLabel(_winnerHandForSeat(game, me.seat)?.rank) ??
            _handRankLabel(game.myHandRank)
        : null;

    final namePlate = Container(
      width: plateW,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: dim ? const Color(0xFF2A2A2A) : const Color(0xFF161616),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWinner
              ? const Color(0xFFF5B301)
              : Colors.white.withValues(alpha: 0.08),
          width: isWinner ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _playerName(me),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: dim ? 0.4 : 1),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          Text(
            me.folded
                ? context.l10n.pokerFolded
                : me.allIn
                    ? context.l10n.pokerAllInBadge
                    : '${me.chips}',
            style: TextStyle(
              color: dim
                  ? Colors.white38
                  : me.allIn
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFF5D76E),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ],
      ),
    );

    final isDealer = game.dealerIndex == game.myIndex;
    final showBet = me.bet > 0 && !me.folded;
    // Ставка/D — НАД неймплейтом (к центру стола), не сбоку на строке стека:
    // иначе мини-стопка визуально «вместо баланса» в чёрном блоке.
    const betRowH = 20.0;
    final betBlockH = (showBet || isDealer) ? betRowH + 4.0 : 0.0;
    // Веер чуть выше неймплейта (+ блок ставки), без выноса на борд.
    final cardsBottom = namePlateH + avatarPlateGap + betBlockH;
    final peekOut = heroCards.width * 0.34;

    final betAbove = (showBet || isDealer)
        ? SizedBox(
            height: betRowH,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showBet) _tableBetLabel(me.bet),
                if (showBet && isDealer) const SizedBox(width: 8),
                if (isDealer) _dealerBadge(size: narrow ? 20 : 24),
              ],
            ),
          )
        : null;

    // Неймплейт: только имя + стек (число). Ставка снаружи сверху.
    final plateRow = KeyedSubtree(
      key: _seatKey(me.seat),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: dim ? 0.35 : 1,
            child: GestureDetector(
              onTap: () => unawaited(_showPlayerCard(me)),
              behavior: HitTestBehavior.opaque,
              child: GamePlayerAvatar(
                displayName: _playerName(me),
                avatarKind: heroAvatar.kind,
                avatarValue: heroAvatar.value,
                frameCode: me.frameCode,
                frameColor: me.frameColor,
                compact: true,
              ),
            ),
          ),
          if (betAbove != null) ...[
            const SizedBox(height: 4),
            betAbove,
          ],
          const SizedBox(height: avatarPlateGap),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => unawaited(_showPlayerCard(me)),
                behavior: HitTestBehavior.opaque,
                child: RepaintBoundary(
                  child: TurnTimerBorder(
                    key: ValueKey('poker-hero-${game.turnDeadline}'),
                    active: acting,
                    turnDeadline: game.turnDeadline,
                    turnTimeSec: game.turnTimeSec,
                    borderWidth: borderW,
                    radius: 10,
                    showIdleBorder: false,
                    myTurnClock: true,
                    child: namePlate,
                  ),
                ),
              ),
              if (myWinCombo != null) ...[
                const SizedBox(width: 6),
                _comboLabel(
                  myWinCombo,
                  highlight: true,
                  onTap: () => _openCombinationsSheet(game.myHandRank),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        if (me.holeCards != null)
          Positioned(
            left: -peekOut,
            right: -peekOut,
            bottom: cardsBottom,
            height: heroCards.height,
            child: IgnorePointer(
              child: Opacity(
                opacity: dim ? 0.4 : 1,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < me.holeCards!.length; i++)
                      Transform.translate(
                        // Шире в стороны — аватар не прячется под картами.
                        offset: Offset(
                          (i == 0 ? -1 : 1) * heroCards.width * 0.36,
                          -avatarSize * 0.04,
                        ),
                        child: Transform.rotate(
                          angle: i == 0 ? -0.1 : 0.1,
                          alignment: Alignment.bottomCenter,
                          child: PlayingCardWidget(
                            key: ValueKey(
                              'hero_${game.handNumber}_${me.holeCards![i].rank}_${me.holeCards![i].suit}',
                            ),
                            card: me.holeCards![i].toPlayingCard(),
                            size: heroCards,
                            highlighted: hasHighlight &&
                                highlightKeys.contains(
                                  PokerGameView.cardKeyOf(me.holeCards![i]),
                                ),
                            dimmed: hasHighlight &&
                                !highlightKeys.contains(
                                  PokerGameView.cardKeyOf(me.holeCards![i]),
                                ),
                            animate: false,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        // Аватар + неймплейт + ставка снаружи (как у соперника).
        plateRow,
      ],
    );
  }

  /// Под столом: комбинация + панель действий с фиксированной высотой
  /// (стол не прыгает при появлении/скрытии кнопок).
  /// Слот подсказки комбинации: в альбоме пустой ряд не резервируем.
  double _comboSlotHeight({required bool tight, required bool hasCombo}) {
    if (!tight) return 30;
    return hasCombo ? 30 : 0;
  }

  Widget _buildBottomBar(
    PokerGameView game,
    bool narrow, {
    bool tight = false,
  }) {
    final comboLabel = _handRankLabel(game.myHandRank);
    final iWonHand = game.isHandOver &&
        game.me != null &&
        _winnerSeats(game).contains(game.me!.seat);
    final comboAccent = _shouldHighlightCombo(game) || iWonHand;
    // На вскрытии комбинация уже у неймплейта — не дублировать снизу.
    final showBottomCombo = comboLabel != null && !iWonHand;
    final showActions = _showPokerActions(game);
    final showCardsBtn = game.canShowCards && !game.isOver;

    final comboSlot = _comboSlotHeight(tight: tight, hasCombo: showBottomCombo);
    final actionSlot = tight ? 42.0 : 52.0;
    final bottomPad = tight ? 10.0 : (narrow ? 8.0 : 12.0);

    final showActionRow = showActions || showCardsBtn;
    // Без кнопок не резервируем пустой ряд — hero остаётся у нижнего края.
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 2, 12, bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: comboSlot,
            child: showBottomCombo
                ? Center(
                    child: _comboLabel(
                      comboLabel,
                      highlight: comboAccent,
                      onTap: () => _openCombinationsSheet(game.myHandRank),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (showActionRow) ...[
            if (comboSlot > 0) const SizedBox(height: 6),
            SizedBox(
              height: actionSlot,
              child: showActions
                  ? _buildActionBar(game, buttonHeight: actionSlot)
                  : Center(
                      child: _buildShowCardsButton(height: actionSlot),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShowCardsButton({double height = 48}) {
    return SizedBox(
      height: height,
      child: FilledButton(
        onPressed: (_busy || _turnAction.held)
            ? null
            : () => unawaited(_showCards()),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF3E7CB1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          minimumSize: Size(160, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          context.l10n.pokerShowCards,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  Future<void> _showCards() async {
    if (!_turnAction.tryAcquire()) return;
    _busy = true;
    if (mounted) setState(() {});
    try {
      await ref.read(pokerRepositoryProvider).showCards(widget.gameId);
      if (mounted) {
        ref.invalidate(pokerGameProvider(widget.gameId));
        try {
          await ref.read(pokerGameProvider(widget.gameId).future);
        } catch (_) {}
      }
    } on GamesException catch (e) {
      if (mounted && !isStaleNotYourTurnError(e)) {
        showAppSnackBar(context,
            message: formatUserError(e), kind: AppSnackKind.error);
      }
    } catch (e) {
      if (mounted && !isStaleNotYourTurnError(e)) {
        showAppSnackBar(context,
            message: formatUserError(e), kind: AppSnackKind.error);
      }
    } finally {
      _turnAction.release();
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _comboLabel(
    String text, {
    required bool highlight,
    VoidCallback? onTap,
  }) {
    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.fromLTRB(14, 5, onTap == null ? 14 : 8, 5),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.accentStart.withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.accentStart.withValues(alpha: highlight ? 0.9 : 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 2),
            const Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: Colors.white,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return chip;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: chip,
      ),
    );
  }

  Widget _buildActionBar(PokerGameView game, {double buttonHeight = 48}) {
    final actions = _gamepadActions(game);
    final cursor = GamepadService.instance.isRecentlyActive
        ? _gamepadActionIndex.clamp(0, math.max(0, actions.length - 1))
        : -1;
    final l10n = context.l10n;

    Widget actionAt(String type, Widget button) {
      final i = actions.indexOf(type);
      final highlighted = i >= 0 && i == cursor;
      return GamepadHinted(
        action: GamepadAction.confirm,
        child: wrapGamepadCursor(
          child: button,
          highlighted: highlighted,
        ),
      );
    }

    final buttons = <Widget>[
      if (game.canDo(PokerActionType.fold))
        actionAt(
          PokerActionType.fold,
          _actionButton(
            label: l10n.pokerFold,
            color: const Color(0xFFB0384A),
            height: buttonHeight,
            onTap: (_busy || _turnAction.held)
                ? null
                : () => unawaited(_move(PokerActionType.fold)),
          ),
        ),
      if (game.canDo(PokerActionType.check))
        actionAt(
          PokerActionType.check,
          _actionButton(
            label: l10n.pokerCheck,
            height: buttonHeight,
            color: const Color(0xFF3E7CB1),
            onTap: (_busy || _turnAction.held)
                ? null
                : () => unawaited(_move(PokerActionType.check)),
          ),
        ),
      if (game.canDo(PokerActionType.call))
        actionAt(
          PokerActionType.call,
          _actionButton(
            label: game.callAmount > 0
                ? l10n.pokerCall(game.callAmount)
                : l10n.pokerCallShort,
            height: buttonHeight,
            color: const Color(0xFF3E7CB1),
            onTap: (_busy || _turnAction.held)
                ? null
                : () => unawaited(_move(PokerActionType.call)),
          ),
        ),
      if (game.canDo(PokerActionType.raise))
        actionAt(
          PokerActionType.raise,
          _actionButton(
            label: l10n.pokerRaise,
            height: buttonHeight,
            color: AppColors.accentStart,
            onTap: (_busy || _turnAction.held)
                ? null
                : () => unawaited(_openRaiseSheet(game)),
          ),
        ),
      if (game.canDo(PokerActionType.allIn))
        actionAt(
          PokerActionType.allIn,
          _actionButton(
            label: l10n.pokerAllIn,
            height: buttonHeight,
            color: const Color(0xFFC9782B),
            onTap: (_busy || _turnAction.held)
                ? null
                : () => unawaited(_move(PokerActionType.allIn)),
          ),
        ),
    ];

    // Одна строка фиксированной высоты — без Wrap, чтобы стол не прыгал.
    return Row(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: buttons[i]),
        ],
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback? onTap,
    double height = 48,
  }) {
    return SizedBox(
      height: height,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          minimumSize: Size(0, height),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

/// Бейдж банка: плавный пульс при изменении суммы (акцент на прибавке банка).
class _PotBadge extends StatefulWidget {
  const _PotBadge({required this.amount, required this.label});

  final int amount;
  final String label;

  @override
  State<_PotBadge> createState() => _PotBadgeState();
}

class _PotBadgeState extends State<_PotBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _PotBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amount != oldWidget.amount) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = math.sin(math.pi * _c.value);
        return Transform.scale(scale: 1 + 0.1 * t, child: child);
      },
      // Тот же размер, что «Раздача» / «Блайнды» (_infoBadge).
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

/// Стопка фишек в центре стола под бордом — якорь анимации ставок/банка.
class _TableChipStack extends StatelessWidget {
  const _TableChipStack({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) {
      return const SizedBox(width: 36, height: 18);
    }
    final layers = amount >= 80 ? 4 : (amount >= 30 ? 3 : 2);
    return SizedBox(
      width: 40,
      height: 16.0 + layers * 3.5,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          for (var i = 0; i < layers; i++)
            Positioned(
              bottom: i * 3.2,
              child: Container(
                width: 22 - i * 0.6,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                          const Color(0xFFE8C547), Colors.white, i * 0.08)!,
                      Color.lerp(const Color(0xFFC9A227), Colors.black, 0.2)!,
                    ],
                  ),
                  border: Border.all(color: Colors.white, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Появление карты: плавный «прилёт» (масштаб + прозрачность) при монтировании.
class _EntranceCard extends StatefulWidget {
  const _EntranceCard({super.key, required this.child});

  final Widget child;

  @override
  State<_EntranceCard> createState() => _EntranceCardState();
}

class _EntranceCardState extends State<_EntranceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _anim = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final v = _anim.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Transform.scale(
            scale: 0.7 + 0.3 * v,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
