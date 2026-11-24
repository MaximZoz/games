import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:multigames_client/games/domino/domino_chain_layout.dart';
import 'package:multigames_client/games/domino/domino_engine.dart';
import 'package:multigames_client/games/domino/domino_repository.dart';
import 'package:multigames_client/games/domino/domino_tile.dart';
import 'package:multigames_client/games/framework/game_opponent_panel.dart';
import 'package:multigames_client/games/framework/game_screen_scaffold.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/app_button.dart';
import 'package:multigames_game_kit/multigames_game_kit.dart';

export 'package:multigames_client/games/domino/domino_chain_layout.dart';
export 'package:multigames_client/games/domino/domino_tile.dart';

/// Пауза между костями при раздаче.
const Duration _dealStagger = Duration(milliseconds: 55);

/// Высота подписи «Базар N» над россыпью костей.
const double _boneLabelHeight = 20;

/// Стол домино: соперники, базар, цепь и рука.
///
/// Всё движение костей — полёты поверх стола ([GameFlightStage]): кость
/// уходит из руки или из базара и ложится на своё место, а не возникает там.
class DominoTable extends StatefulWidget {
  const DominoTable({
    super.key,
    required this.view,
    required this.onPlay,
    this.onPlayPair,
    this.onDraw,
    this.onPass,
    this.onTurnExpired,
    this.busy = false,
  });

  final DominoGameView view;
  final ValueChanged<DominoMove> onPlay;

  /// Морской режим: положить два дубля одним ходом. Кнопка появляется,
  /// только когда такой ход есть ([DominoGameView.canPair]).
  final VoidCallback? onPlayPair;

  /// Взять кость из базара; null — брать нельзя (зритель).
  final VoidCallback? onDraw;
  final VoidCallback? onPass;

  /// Время хода соперника вышло — экран забирает итог с сервера.
  final VoidCallback? onTurnExpired;
  final bool busy;

  @override
  State<DominoTable> createState() => _DominoTableState();
}

class _DominoTableState extends State<DominoTable>
    with TickerProviderStateMixin {
  late final GameFlightController _flights = GameFlightController(vsync: this);
  late final AnimationController _relayout = AnimationController(
    vsync: this,
    duration: GameMotion.settle,
    value: 1,
  );

  final GlobalKey<GameHandStripState> _handStripKey =
      GlobalKey<GameHandStripState>();
  final GlobalKey _chainKey = GlobalKey(debugLabel: 'domino-chain');
  final GlobalKey _boneFieldKey = GlobalKey(debugLabel: 'domino-boneyard');
  final Map<int, GlobalKey> _handKeys = <int, GlobalKey>{};
  final Map<int, GlobalKey> _seatKeys = <int, GlobalKey>{};

  /// Кости цепи, которые ещё летят на своё место.
  final Set<int> _landing = <int>{};

  /// Кости моей руки, которые ещё летят из базара.
  final Set<int> _arriving = <int>{};

  /// Сколько костей ещё летит к сопернику (по месту).
  final Map<int, int> _incoming = <int, int>{};

  /// Меняется с каждым новым коном: полёты прошлого кона не трогают новый.
  int _generation = 0;

  Map<int, Rect> _from = const <int, Rect>{};
  Map<int, Rect> _shown = const <int, Rect>{};
  Map<int, Rect> _placed = const <int, Rect>{};
  Size _chainArea = Size.zero;
  double _chainMaxScale = 1;

  List<ScatterSlot> _boneSlots = const <ScatterSlot>[];
  Size _boneTile = const Size(20, 38);
  int _boneCapacity = 0;
  Size _seatTile = const Size(17, 32);

  int? _choosing;

  @override
  void initState() {
    super.initState();
    final view = widget.view;
    _boneCapacity = view.boneyardCount;
    if (view.isPlaying && view.chain.isEmpty && view.eventSeq == 0) {
      _scheduleDeal(view);
    }
  }

  @override
  void didUpdateWidget(covariant DominoTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.view;
    final after = widget.view;
    if (_choosing != null && !after.legal.any((m) => m.tile == _choosing)) {
      _choosing = null;
    }
    final newTable = after.id != before.id ||
        after.round != before.round ||
        after.chain.length < before.chain.length;
    if (newTable) {
      _resetTable(after);
      if (after.isPlaying && after.chain.isEmpty) _scheduleDeal(after);
      return;
    }
    _boneCapacity = math.max(_boneCapacity, after.boneyardCount);
    if (_chainSig(before) != _chainSig(after)) {
      _from = Map<int, Rect>.of(_shown);
      _relayout.forward(from: 0);
    }
    _launchMoves(before, after);
    final hand = after.me?.hand.toSet() ?? const <int>{};
    _handKeys.removeWhere((id, _) => !hand.contains(id));
  }

  @override
  void dispose() {
    _flights.dispose();
    _relayout.dispose();
    super.dispose();
  }

  String _chainSig(DominoGameView view) =>
      view.chain.map((tile) => tile.id).join(',');

  GlobalKey _handKey(int id) => _handKeys.putIfAbsent(
        id,
        () => GlobalKey(debugLabel: 'domino-hand-$id'),
      );

  GlobalKey _seatKey(int seat) => _seatKeys.putIfAbsent(
        seat,
        () => GlobalKey(debugLabel: 'domino-seat-$seat'),
      );

  void _resetTable(DominoGameView view) {
    _generation++;
    _flights.clear();
    _landing.clear();
    _arriving.clear();
    _incoming.clear();
    _handKeys.clear();
    _from = const <int, Rect>{};
    _shown = const <int, Rect>{};
    _relayout.value = 1;
    _boneCapacity = view.boneyardCount;
    _choosing = null;
  }

  // ---- Полёты ----------------------------------------------------------

  /// Прячет розданные кости и со следующего кадра раздаёт их из базара.
  void _scheduleDeal(DominoGameView view) {
    final hand = view.me?.hand ?? const <int>[];
    _arriving.addAll(hand);
    for (final player in view.players) {
      if (player.seat == view.myIndex) continue;
      _incoming[player.seat] = player.handCount;
    }
    final generation = _generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) return;
      _launchDeal(widget.view);
    });
  }

  void _launchDeal(DominoGameView view) {
    final field = _flights.rectOf(_boneFieldKey);
    if (field == null) {
      setState(() {
        _arriving.clear();
        _incoming.clear();
      });
      return;
    }
    final from = Rect.fromCenter(
      center: field.center,
      width: _boneTile.width,
      height: _boneTile.height,
    );
    final hand = view.me?.hand ?? const <int>[];
    for (var i = 0; i < hand.length; i++) {
      final id = hand[i];
      if (!_arriving.contains(id)) continue;
      _flyToHand(id, from: from, delay: _dealStagger * i);
    }
    for (final player in view.players) {
      if (player.seat == view.myIndex) continue;
      final count = _incoming[player.seat] ?? 0;
      for (var i = 0; i < count; i++) {
        _flyToSeat(
          player.seat,
          from: from,
          delay: _dealStagger * i,
          counted: true,
        );
      }
    }
  }

  /// Сравнивает прошлое и новое состояние и запускает полёты за ход.
  void _launchMoves(DominoGameView before, DominoGameView after) {
    var order = 0;
    Duration nextDelay() => GameMotion.stagger * order++;

    final known = {for (final tile in before.chain) tile.id};
    final mineBefore = before.me?.hand.toSet() ?? const <int>{};
    for (final placed in after.chain) {
      if (known.contains(placed.id)) continue;
      final mine = mineBefore.contains(placed.id);
      Rect? from;
      if (mine) {
        final key = _handKeys[placed.id];
        from = key == null ? null : _flights.rectOf(key);
      } else {
        final seat = _playedSeat(before, after, placed.id);
        from = seat == null ? null : _seatTileRect(seat);
      }
      _flyToChain(placed, after, from: from, faceUp: mine, delay: nextDelay());
    }

    var bone = before.boneyardCount;
    final hand = after.me?.hand ?? const <int>[];
    for (var i = 0; i < hand.length; i++) {
      final id = hand[i];
      if (mineBefore.contains(id)) continue;
      final slot = _boneSlot(--bone);
      if (slot == null) continue;
      _arriving.add(id);
      _flyToHand(
        id,
        from: slot.rect,
        fromAngle: slot.angle,
        delay: nextDelay(),
      );
      final index = i;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handStripKey.currentState?.reveal(index);
      });
    }

    for (final player in after.players) {
      if (player.seat == after.myIndex) continue;
      final was = _handCount(before, player.seat);
      if (was == null) continue;
      for (var i = was; i < player.handCount; i++) {
        final slot = _boneSlot(--bone);
        if (slot == null) continue;
        _flyToSeat(
          player.seat,
          from: slot.rect,
          fromAngle: slot.angle,
          delay: nextDelay(),
        );
      }
    }
  }

  int? _handCount(DominoGameView view, int seat) {
    for (final player in view.players) {
      if (player.seat == seat) return player.handCount;
    }
    return null;
  }

  /// Кто из соперников положил кость [tile].
  int? _playedSeat(DominoGameView before, DominoGameView after, int tile) {
    if (_lastPlayed(after).contains(tile) &&
        after.lastActor >= 0 &&
        after.lastActor != after.myIndex) {
      return after.lastActor;
    }
    for (final player in after.players) {
      if (player.seat == after.myIndex) continue;
      final was = _handCount(before, player.seat);
      if (was != null && player.handCount < was) return player.seat;
    }
    return null;
  }

  /// Кости последнего хода: одна, а после хода двумя дублями — обе.
  Set<int> _lastPlayed(DominoGameView view) => switch (view.lastAction) {
        dominoActionPlay => {view.lastTile},
        dominoActionPlayPair => {view.lastTile, view.lastTile2},
        _ => const <int>{},
      };

  ({Rect rect, double angle})? _boneSlot(int index) {
    final field = _flights.rectOf(_boneFieldKey);
    if (field == null) return null;
    if (index < 0 || index >= _boneSlots.length) {
      return (
        rect: Rect.fromCenter(
          center: field.center,
          width: _boneTile.width,
          height: _boneTile.height,
        ),
        angle: 0,
      );
    }
    final slot = _boneSlots[index];
    return (
      rect: Rect.fromCenter(
        center: field.topLeft + slot.center,
        width: _boneTile.width,
        height: _boneTile.height,
      ),
      angle: slot.angle,
    );
  }

  /// Крайняя кость в ряду рубашек соперника — оттуда и туда летят его кости.
  Rect? _seatTileRect(int seat) {
    final key = _seatKeys[seat];
    if (key == null) return null;
    final row = _flights.rectOf(key);
    if (row == null) return null;
    return Rect.fromLTWH(
      row.right - _seatTile.width,
      row.center.dy - _seatTile.height / 2,
      _seatTile.width,
      _seatTile.height,
    );
  }

  /// Рамка летящей кости над слотом цепи: кость летит «стоя» и доворачивается,
  /// поэтому над лежачим слотом рамка — тот же слот, повёрнутый на 90°.
  Rect _upright(DominoPlaced placed, Rect slot) => placed.isDouble
      ? slot
      : Rect.fromCenter(
          center: slot.center,
          width: slot.height,
          height: slot.width,
        );

  void _flyToChain(
    DominoPlaced placed,
    DominoGameView view, {
    required Rect? from,
    required bool faceUp,
    required Duration delay,
  }) {
    final origin = _flights.rectOf(_chainKey)?.topLeft;
    if (origin == null || _chainArea.isEmpty) return;
    final fit = fitDominoChain(view.chain, _chainArea, maxScale: _chainMaxScale);
    DominoLayoutSlot? slot;
    for (final candidate in fit.slots) {
      if (candidate.id == placed.id) slot = candidate;
    }
    if (slot == null) return;
    final centering = Offset(
      (_chainArea.width - fit.size.width) / 2,
      (_chainArea.height - fit.size.height) / 2,
    );
    final target = _upright(placed, slot.rect.shift(centering + origin));
    final pips = dominoPips(placed.id);
    final halves = dominoHalfPips(placed, leadingOnRight: slot.leadingOnRight);
    // Стоячая кость: меньшее число сверху. Поворот по часовой уводит верх
    // вправо — так кость ложится той половиной, что нужна стыку.
    final angle = placed.isDouble
        ? 0.0
        : (halves.right == pips.$1 ? math.pi / 2 : -math.pi / 2);
    final start = from ??
        Rect.fromCenter(
          center: Offset(target.center.dx, origin.dy - target.height),
          width: target.width,
          height: target.height,
        );
    final id = placed.id;
    final generation = _generation;
    _landing.add(id);
    _flights
        .launch(GameFlight(
      from: start,
      to: target,
      toAngle: angle,
      delay: delay,
      toResolver: () {
        final live = _flights.rectOf(_chainKey)?.topLeft;
        final rect = _placed[id];
        if (live == null || rect == null) return null;
        return _upright(placed, rect.shift(live));
      },
      builder: faceUp
          ? (_, __) => DominoTileFace(tile: id)
          : (_, t) => DominoFlipTile(tile: id, t: t),
    ))
        .then((_) {
      if (!mounted || generation != _generation) return;
      setState(() => _landing.remove(id));
    });
  }

  void _flyToHand(
    int id, {
    required Rect from,
    double fromAngle = 0,
    Duration delay = Duration.zero,
  }) {
    final key = _handKey(id);
    final generation = _generation;
    _flights
        .launch(GameFlight(
      from: from,
      to: from,
      fromAngle: fromAngle,
      delay: delay,
      lift: 26,
      toResolver: () => _flights.rectOf(key),
      builder: (_, t) => DominoFlipTile(tile: id, t: t),
    ))
        .then((_) {
      if (!mounted || generation != _generation) return;
      setState(() => _arriving.remove(id));
    });
  }

  /// [counted] — кость уже учтена в [_incoming] (раздача).
  void _flyToSeat(
    int seat, {
    required Rect from,
    double fromAngle = 0,
    Duration delay = Duration.zero,
    bool counted = false,
  }) {
    if (!counted) _incoming[seat] = (_incoming[seat] ?? 0) + 1;
    final generation = _generation;
    _flights
        .launch(GameFlight(
      from: from,
      to: from,
      fromAngle: fromAngle,
      delay: delay,
      toResolver: () => _seatTileRect(seat),
      builder: (_, __) => const DominoTileBack(),
    ))
        .then((_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        final left = (_incoming[seat] ?? 0) - 1;
        if (left > 0) {
          _incoming[seat] = left;
        } else {
          _incoming.remove(seat);
        }
      });
    });
  }

  // ---- Ходы -------------------------------------------------------------

  void _tapHand(int id) {
    if (widget.busy || !widget.view.isMyTurn) return;
    final moves = [
      for (final move in widget.view.legal)
        if (move.tile == id) move,
    ];
    if (moves.isEmpty) return;
    if (moves.length == 1) {
      setState(() => _choosing = null);
      widget.onPlay(moves.first);
      return;
    }
    setState(() => _choosing = _choosing == id ? null : id);
  }

  void _tapEnd(String end) {
    final id = _choosing;
    if (id == null || widget.busy) return;
    for (final move in widget.view.legal) {
      if (move.tile == id && move.end == end) {
        setState(() => _choosing = null);
        widget.onPlay(move);
        return;
      }
    }
  }

  void _tapPair() {
    if (widget.busy || !widget.view.isMyTurn || !widget.view.canPair) return;
    setState(() => _choosing = null);
    widget.onPlayPair?.call();
  }

  // ---- Вёрстка ----------------------------------------------------------

  List<DominoPlayerView> _others(DominoGameView view) {
    final n = view.players.length;
    final me = view.myIndex;
    final others = [
      for (final player in view.players)
        if (player.seat != me) player,
    ];
    if (n > 0 && me >= 0) {
      others.sort((a, b) =>
          ((a.seat - me + n) % n).compareTo((b.seat - me + n) % n));
    }
    return others;
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    _chainMaxScale = isNarrow(context) ? 1.0 : 1.7;
    return GameFlightStage(
      controller: _flights,
      child: LayoutBuilder(
        builder: (context, box) {
          final others = _others(view);
          final rail = GameChromeScope.railInsetOf(context);
          // Альбом телефона: по высоте стол не помещается под карточкой.
          final short = box.maxHeight < 430;
          final duel = others.length == 1;
          _seatTile =
              duel && !short ? const Size(17, 32) : const Size(13, 25);
          final hand = _hand(view, box.maxWidth, short);
          final table = _table(view);
          if (duel && short && box.maxWidth > box.maxHeight * 1.3) {
            return Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: math.min(240, box.maxWidth * 0.32),
                        child: Center(
                          child: _duelOpponent(
                            view,
                            others.first,
                            rail: 0,
                            compact: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: table),
                      SizedBox(width: rail),
                    ],
                  ),
                ),
                hand,
              ],
            );
          }
          return Column(
            children: [
              if (duel)
                _duelOpponent(view, others.first, rail: rail)
              else if (others.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(right: rail),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final player in others)
                        Expanded(child: _seat(view, player, short: short)),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Expanded(child: table),
              hand,
            ],
          );
        },
      ),
    );
  }

  GameOpponent _opponentOf(DominoPlayerView player) => GameOpponent(
        userId: player.id,
        displayName: player.displayName,
        avatarKind: player.avatarKind,
        avatarValue: player.avatarValue,
        frameCode: player.frameCode,
        frameColor: player.frameColor,
        isBot: player.isBot,
      );

  bool _isTurnOf(DominoGameView view, DominoPlayerView player) =>
      view.isPlaying && view.turn == player.seat && !player.forfeited;

  /// Соперник 1×1: общая карточка партии и ряд его костей под ней.
  Widget _duelOpponent(
    DominoGameView view,
    DominoPlayerView player, {
    required double rail,
    bool? compact,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GameOpponentPanel(
          opponent: _opponentOf(player),
          gameType: 'domino',
          gameId: view.id,
          isTheirTurn: _isTurnOf(view, player),
          turnDeadline: view.turnTimeSec > 0 ? view.turnDeadline : 0,
          turnTimeSec: view.turnTimeSec,
          onTurnExpired: widget.onTurnExpired,
          reserveRail: rail > 0,
          compact: compact,
        ),
        const SizedBox(height: 6),
        // Счёт соперника — у его костей, не в карточке: она у всех игр одна.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: rail),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: _opponentTiles(view, player, maxWidth: 260)),
              const SizedBox(width: 8),
              _ScoreChip(
                key: const ValueKey('domino-opponent-score'),
                score: player.score,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Место за столом на 3–4 игроков. [short] — альбом телефона: кости
  /// встают сбоку от аватара, а не под ним, чтобы столу осталась высота.
  Widget _seat(
    DominoGameView view,
    DominoPlayerView player, {
    required bool short,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Flex(
        direction: short ? Axis.horizontal : Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GameOpponentPanel.seat(
            opponent: _opponentOf(player),
            gameType: 'domino',
            gameId: view.id,
            isTheirTurn: _isTurnOf(view, player),
            turnDeadline: view.turnTimeSec > 0 ? view.turnDeadline : 0,
            turnTimeSec: view.turnTimeSec,
            onTurnExpired: widget.onTurnExpired,
            maxWidth: 140,
            seatBadges: [_ScoreChip(score: player.score, dense: true)],
          ),
          const SizedBox(width: 6, height: 4),
          if (short)
            Flexible(child: _opponentTiles(view, player, maxWidth: 110))
          else
            _opponentTiles(view, player, maxWidth: 140),
        ],
      ),
    );
  }

  Widget _opponentTiles(
    DominoGameView view,
    DominoPlayerView player, {
    required double maxWidth,
  }) {
    final reveal = (view.isRoundEnd || view.isOver) && player.hand.isNotEmpty;
    final flying = _incoming[player.seat] ?? 0;
    return _OpponentTiles(
      rowKey: _seatKey(player.seat),
      count: math.max(0, player.handCount - flying),
      revealed: reveal ? player.hand : const <int>[],
      tile: _seatTile,
      maxWidth: maxWidth,
    );
  }

  Widget _table(DominoGameView view) {
    return GameTableSurface(
      child: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          final capacity = math.max(_boneCapacity, view.boneyardCount);
          final hasBones = capacity > 0;
          final sideways = hasBones && size.width > size.height * 1.5;
          final extent = !hasBones
              ? 34.0
              : sideways
                  ? (size.width * 0.27).clamp(112.0, 220.0)
                  : (size.height * 0.3).clamp(84.0, 150.0);
          final bones = Padding(
            padding: const EdgeInsets.all(6),
            child: _boneyard(view, capacity),
          );
          final chain = Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
            child: _chain(view),
          );
          if (sideways) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: extent, child: bones),
                Expanded(child: chain),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: extent, child: bones),
              Expanded(child: chain),
            ],
          );
        },
      ),
    );
  }

  /// Базар: кости лежат россыпью рубашкой вверх; нажатие берёт кость.
  Widget _boneyard(DominoGameView view, int capacity) {
    final canDraw = view.canDraw && !widget.busy && widget.onDraw != null;
    return GestureDetector(
      key: const ValueKey('domino-boneyard'),
      behavior: HitTestBehavior.opaque,
      onTap: canDraw ? widget.onDraw : null,
      child: AnimatedContainer(
        duration: GameMotion.fade,
        decoration: BoxDecoration(
          color: canDraw
              ? GamePalette.highlightSoft
              : GamePalette.tableInk.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canDraw ? GamePalette.highlight : Colors.transparent,
            width: 1.6,
          ),
        ),
        // Stack, а не Column: в узкой полоске без костей подпись не должна
        // спорить с полем за доли пикселя.
        child: Stack(
          children: [
            Positioned(
              left: 10,
              right: 10,
              top: 2,
              child: Text(
                '${context.l10n.dominoBoneyard} ${view.boneyardCount}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GamePalette.tableInkSoft,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
            Positioned.fill(
              top: _boneLabelHeight,
              child: LayoutBuilder(
                builder: (context, box) {
                  final field = box.biggest;
                  // В тесном поле кости мельче, чтобы россыпь не слиплась.
                  final room = capacity <= 0
                      ? 40.0
                      : math.sqrt(field.width * field.height / capacity) * 0.8;
                  final height =
                      math.min(field.height * 0.6, room).clamp(18.0, 40.0);
                  final tile = Size(height / kDominoAspect, height);
                  final slots = scatterSlots(
                    capacity: capacity,
                    area: field,
                    item: tile,
                    seed: view.round * 131 + capacity,
                  );
                  _boneSlots = slots;
                  _boneTile = tile;
                  final shown = math.min(view.boneyardCount, slots.length);
                  return Stack(
                    key: _boneFieldKey,
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < shown; i++)
                        Positioned(
                          left: slots[i].center.dx - tile.width / 2,
                          top: slots[i].center.dy - tile.height / 2,
                          width: tile.width,
                          height: tile.height,
                          child: Transform.rotate(
                            angle: slots[i].angle,
                            child: const DominoTileBack(),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chain(DominoGameView view) {
    return LayoutBuilder(
      builder: (context, box) {
        final area = box.biggest;
        _chainArea = area;
        final fit = fitDominoChain(view.chain, area, maxScale: _chainMaxScale);
        final centering = Offset(
          (area.width - fit.size.width) / 2,
          (area.height - fit.size.height) / 2,
        );
        final placed = {
          for (final slot in fit.slots) slot.id: slot.rect.shift(centering),
        };
        final leading = {
          for (final slot in fit.slots) slot.id: slot.leadingOnRight,
        };
        _placed = placed;
        final last = view.isPlaying ? _lastPlayed(view) : const <int>{};
        final me = view.me;
        return Stack(
          key: _chainKey,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _relayout,
                  builder: (context, _) {
                    final t =
                        GameMotion.settleCurve.transform(_relayout.value);
                    final now = <int, Rect>{
                      for (final entry in placed.entries)
                        entry.key: Rect.lerp(
                              _from[entry.key] ?? entry.value,
                              entry.value,
                              t,
                            ) ??
                            entry.value,
                    };
                    _shown = now;
                    return CustomPaint(
                      painter: _ChainPainter(
                        chain: view.chain,
                        rects: now,
                        leadingOnRight: leading,
                        hidden: Set<int>.of(_landing),
                        lastTiles: last,
                      ),
                    );
                  },
                ),
              ),
            ),
            if (me != null)
              Positioned(
                left: 0,
                bottom: 0,
                child: _ScoreChip(score: me.score),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(child: _turnAction(view)),
            ),
            if (_choosing != null) Positioned.fill(child: _endChooser()),
          ],
        );
      },
    );
  }

  /// Кнопка хода поверх стола. «Взять» / «Пас» появляются, только когда
  /// ходить нечем; «Два дубля» — когда оба дубля можно положить сразу.
  Widget _turnAction(DominoGameView view) {
    final l10n = context.l10n;
    Widget action = const SizedBox.shrink(key: ValueKey('domino-no-action'));
    if (view.canPair && view.isMyTurn && widget.onPlayPair != null) {
      action = AppButton(
        key: const ValueKey('domino-pair'),
        onPressed: widget.busy ? null : _tapPair,
        label: l10n.dominoPlayPair,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      );
    } else if (view.canDraw && widget.onDraw != null) {
      action = FilledButton.icon(
        key: const ValueKey('domino-draw'),
        onPressed: widget.busy ? null : widget.onDraw,
        icon: const Icon(Icons.style_rounded),
        label: Text(l10n.durakActionTake),
      );
    } else if (view.canPass && widget.onPass != null) {
      action = FilledButton.tonalIcon(
        key: const ValueKey('domino-pass'),
        onPressed: widget.busy ? null : widget.onPass,
        icon: const Icon(Icons.skip_next_rounded),
        label: Text(l10n.durakActionPass),
      );
    }
    return AnimatedSwitcher(
      duration: GameMotion.fade,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: action,
    );
  }

  /// Кость подходит к обоим концам цепи — спрашиваем, куда класть.
  Widget _endChooser() {
    final l10n = context.l10n;
    Widget side(String end, IconData icon, String label) {
      return Expanded(
        child: Center(
          child: FilledButton.icon(
            key: ValueKey('domino-end-$end'),
            onPressed: widget.busy ? null : () => _tapEnd(end),
            icon: Icon(icon),
            label: Text(label),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _choosing = null),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GamePalette.tableTop.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            side('left', Icons.arrow_back_rounded, l10n.dominoLeft),
            side('right', Icons.arrow_forward_rounded, l10n.dominoRight),
          ],
        ),
      ),
    );
  }

  /// Моя рука: кости крупные, с зазором под палец; не влезают — листаются.
  Widget _hand(DominoGameView view, double width, bool short) {
    final hand = view.me?.hand ?? const <int>[];
    const spacing = 14.0;
    const padding = EdgeInsets.symmetric(horizontal: 14);
    // Семь костей раздачи должны помещаться без прокрутки.
    final fit = (width - padding.horizontal - spacing * 6) / 7;
    final tileWidth = short ? 32.0 : fit.clamp(38.0, 54.0);
    final tileHeight = tileWidth * 1.9;
    final lift = tileHeight * 0.16;
    return GameHandStrip(
      key: _handStripKey,
      itemCount: hand.length,
      itemSize: Size(tileWidth, tileHeight),
      height: tileHeight + lift * 2 + 6,
      spacing: spacing,
      padding: padding,
      itemKeyBuilder: (index) => hand[index],
      itemBuilder: (context, index) => _handTile(view, hand[index]),
    );
  }

  Widget _handTile(DominoGameView view, int id) {
    final legal = view.legal.any((move) => move.tile == id);
    final selected = _choosing == id;
    final playable = view.isMyTurn && legal;
    final radius = BorderRadius.circular(9);
    return GestureDetector(
      key: ValueKey('domino-hand-$id'),
      behavior: HitTestBehavior.opaque,
      onTap: legal ? () => _tapHand(id) : null,
      child: AnimatedSlide(
        duration: GameMotion.settle,
        curve: GameMotion.settleCurve,
        offset: Offset(0, selected ? -0.16 : (playable ? -0.05 : 0)),
        child: AnimatedOpacity(
          duration: GameMotion.fade,
          opacity: view.isMyTurn && !legal ? 0.42 : 1,
          child: Opacity(
            // Пока кость летит из базара, её место в руке пустует.
            opacity: _arriving.contains(id) ? 0 : 1,
            child: AnimatedContainer(
              key: _handKey(id),
              duration: GameMotion.fade,
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  if (selected)
                    BoxShadow(
                      color: GamePalette.highlight.withValues(alpha: 0.45),
                      blurRadius: 14,
                    ),
                ],
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: selected
                      ? GamePalette.highlight
                      : (playable
                          ? GamePalette.highlight.withValues(alpha: 0.55)
                          : Colors.transparent),
                  width: selected ? 2.4 : 1.6,
                ),
              ),
              child: DominoTileFace(tile: id),
            ),
          ),
        ),
      ),
    );
  }
}

/// Кости соперника: рубашками, а в конце кона — лицом.
class _OpponentTiles extends StatelessWidget {
  const _OpponentTiles({
    required this.rowKey,
    required this.count,
    required this.revealed,
    required this.tile,
    required this.maxWidth,
  });

  final GlobalKey rowKey;
  final int count;
  final List<int> revealed;
  final Size tile;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = math.min(maxWidth, box.maxWidth);
        if (revealed.isNotEmpty) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width),
            child: Wrap(
              key: rowKey,
              alignment: WrapAlignment.center,
              spacing: 3,
              runSpacing: 3,
              children: [
                for (final id in revealed)
                  SizedBox.fromSize(
                    size: tile,
                    child: DominoTileFace(tile: id),
                  ),
              ],
            ),
          );
        }
        final shown = math.max(count, 1);
        final step = shown <= 1
            ? 0.0
            : math.min(
                tile.width + 3,
                math.max(4.0, (width - tile.width) / (shown - 1)),
              );
        return SizedBox(
          key: rowKey,
          width: tile.width + step * (shown - 1),
          height: tile.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < count; i++)
                Positioned(
                  left: i * step,
                  top: 0,
                  width: tile.width,
                  height: tile.height,
                  child: const DominoTileBack(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({super.key, required this.score, this.dense = false});

  final int score;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l10n.unoScore(score),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 6 : 8,
          vertical: dense ? 1 : 3,
        ),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: dense ? 12 : 14,
              color: AppColors.accentStart,
            ),
            const SizedBox(width: 3),
            Text(
              '$score',
              style: TextStyle(
                color: GamePalette.tableInk,
                fontWeight: FontWeight.w800,
                fontSize: dense ? 11 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChainPainter extends CustomPainter {
  _ChainPainter({
    required this.chain,
    required this.rects,
    required this.leadingOnRight,
    required this.hidden,
    required this.lastTiles,
  });

  final List<DominoPlaced> chain;
  final Map<int, Rect> rects;
  final Map<int, bool> leadingOnRight;

  /// Кости, которые ещё летят: место под них оставлено пустым.
  final Set<int> hidden;

  /// Кости последнего хода — их мягко подсвечиваем.
  final Set<int> lastTiles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final tile in chain) {
      if (hidden.contains(tile.id)) continue;
      final rect = rects[tile.id];
      if (rect == null) continue;
      canvas.save();
      canvas.translate(rect.left, rect.top);
      final halves = dominoHalfPips(
        tile,
        leadingOnRight: leadingOnRight[tile.id] ?? true,
      );
      DominoFacePainter(
        lo: halves.left,
        hi: halves.right,
        vertical: tile.isDouble,
      ).paint(canvas, rect.size);
      canvas.restore();
      if (lastTiles.contains(tile.id)) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.inflate(1.5),
            Radius.circular(rect.shortestSide * 0.2 + 1.5),
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = GamePalette.highlight.withValues(alpha: 0.8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChainPainter oldDelegate) => true;
}
