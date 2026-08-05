import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/durak/card_fly.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';

/// Веер карт игрока.
///
/// - Водить пальцем — подсветка карты под пальцем.
/// - Тянуть вверх: сначала чуть выше остальных, затем плавный вылет за пальцем.
/// - Отпускание / вниз: плавно через «слегка выглядывает» → полностью в веере.
/// - Отпустить вне веера — [onDrop] (полёт на цель стола), только легальные.
class CardFan extends StatefulWidget {
  const CardFan({
    super.key,
    required this.cards,
    required this.cardSize,
    this.enabled = true,
    this.legalCards,
    this.selectedCards,
    this.hiddenCards,
    this.onTap,
    this.onLongPress,
    this.onDrop,
    this.onReturnToFan,
    this.onActiveChanged,
    this.onDragPosition,
    this.faceDown = false,
    this.invertFan = false,
    this.arc,
    this.spacing,
    this.animateLayout = true,
    this.fillWidth = false,
  });

  final List<PlayingCard> cards;
  final Size cardSize;
  final bool enabled;
  final Set<PlayingCard>? legalCards;
  final Set<PlayingCard>? selectedCards;
  final Set<PlayingCard>? hiddenCards;
  final ValueChanged<PlayingCard>? onTap;
  final ValueChanged<PlayingCard>? onLongPress;

  /// `true` — карта принята столом. `false` — вернуть в веер.
  final Future<bool> Function(
    PlayingCard card,
    Offset globalPosition,
    Rect from,
  )? onDrop;

  /// Карту отпустили / сложили в веер — родитель может отсортировать руку.
  final ValueChanged<PlayingCard>? onReturnToFan;

  final ValueChanged<PlayingCard?>? onActiveChanged;
  final ValueChanged<Offset?>? onDragPosition;
  final bool faceDown;

  /// Веер «от» соперника: ось сверху, дуга в его сторону.
  final bool invertFan;
  final double? arc;
  final double? spacing;

  /// Плавная перестановка слотов (сортировка). Выкл. — без «плывущего» веера после хода.
  final bool animateLayout;

  /// Карты от левого края на всю ширину (без пустоты слева под крестиком).
  final bool fillWidth;

  @override
  State<CardFan> createState() => _CardFanState();
}

class _CardFanState extends State<CardFan> with TickerProviderStateMixin {
  /// Путь пальца вверх до полного вылета (и обратно до «чуть выше»).
  static const double _extractPx = 40;

  int? _hoverIndex;
  Offset _panAccum = Offset.zero;
  bool _dropBusy = false;
  bool _docking = false;

  /// Инвалидирует незавершённый fold/drop при новом жесте.
  int _gestureGen = 0;

  /// Свободный drag (overlay следует за пальцем).
  PlayingCard? _liftedCard;
  Offset? _liftGlobalCenter;
  double _liftScale = 1.0;

  /// Карта слегка приподнята в веере (фаза вытаскивания / возврата).
  PlayingCard? _peekCard;

  /// 0 = в слоте, 1 = максимально приподнята (порог вылета).
  double _peekT = 0;

  /// Накопленный подъём вверх от старта жеста / после вылета.
  double _upTravel = 0;
  OverlayEntry? _overlay;
  bool _pointerDown = false;

  /// Последняя позиция пальца — чтобы после возврата/сортировки продолжить жест.
  Offset? _lastPointerGlobal;

  double get _peekRaiseY => widget.cardSize.height * 0.30;

  List<PlayingCard> get _layoutCards {
    final hidden = widget.hiddenCards;
    if (hidden == null || hidden.isEmpty) return widget.cards;
    return widget.cards.where((c) => !hidden.contains(c)).toList();
  }

  /// Карты слотов веера (поднятая остаётся «дыркой», чтобы соседние не прыгали).
  List<PlayingCard> get _fanCards => _layoutCards;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _emitActiveCard(PlayingCard? card) {
    final legal = card == null
        ? null
        : (widget.legalCards == null || widget.legalCards!.contains(card)
            ? card
            : null);
    widget.onActiveChanged?.call(legal);
  }

  void _setHover(int? index) {
    if (_hoverIndex == index) return;
    setState(() => _hoverIndex = index);
    if (_liftedCard == null) {
      final cards = _fanCards;
      final card = index == null || index < 0 || index >= cards.length
          ? null
          : cards[index];
      _emitActiveCard(card);
    }
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _updateLiftVisual(Offset globalCenter) {
    final screen = MediaQuery.sizeOf(context);
    _liftScale = dragScaleTowardCenter(globalCenter, screen);
    _liftGlobalCenter = globalCenter;
    _overlay?.markNeedsBuild();
    if (_overlay != null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _overlay = OverlayEntry(
      builder: (ctx) {
        final card = _liftedCard;
        final center = _liftGlobalCenter;
        if (card == null || center == null) return const SizedBox.shrink();
        final scale = _liftScale;
        final w = widget.cardSize.width * scale;
        final h = widget.cardSize.height * scale;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: center.dx - w / 2,
                top: center.dy - h / 2,
                width: w,
                height: h,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: widget.faceDown
                      ? CardBackWidget(size: widget.cardSize, elevated: true)
                      : PlayingCardWidget(
                          card: card,
                          size: widget.cardSize,
                          elevated: true,
                          highlighted: true,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
    overlay.insert(_overlay!);
  }

  Future<void> _animateOverlayTo(
    Rect to, {
    bool soft = true,
    double beginScale = 1.0,
    int? ms,
  }) async {
    final fromCenter = _liftGlobalCenter;
    final card = _liftedCard;
    if (fromCenter == null || card == null) return;
    final from = Rect.fromCenter(
      center: fromCenter,
      width: widget.cardSize.width * beginScale,
      height: widget.cardSize.height * beginScale,
    );
    _removeOverlay();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final completer = Completer<void>();
    late OverlayEntry entry;
    final duration = Duration(milliseconds: ms ?? (soft ? 300 : 240));
    entry = OverlayEntry(
      builder: (ctx) {
        return IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: duration,
            curve: soft ? Curves.easeInOutCubic : Curves.easeOutCubic,
            onEnd: () {
              entry.remove();
              if (!completer.isCompleted) completer.complete();
            },
            builder: (context, t, _) {
              final scale = beginScale + (1.0 - beginScale) * t;
              final w = widget.cardSize.width * scale;
              final h = widget.cardSize.height * scale;
              final cx = from.center.dx + (to.center.dx - from.center.dx) * t;
              final cy = from.center.dy + (to.center.dy - from.center.dy) * t;
              final lift = soft ? -14.0 * sin(pi * t) : 0.0;
              return Stack(
                children: [
                  Positioned(
                    left: cx - w / 2,
                    top: cy - h / 2 + lift,
                    width: w,
                    height: h,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: widget.faceDown
                          ? CardBackWidget(
                              size: widget.cardSize, elevated: true)
                          : PlayingCardWidget(
                              card: card,
                              size: widget.cardSize,
                              elevated: true,
                              highlighted: t < 0.85,
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    overlay.insert(entry);
    await completer.future;
  }

  Future<void> _animatePeekTTo(double to, {int ms = 300}) async {
    final from = _peekT;
    if ((from - to).abs() < 0.01) {
      _peekT = to;
      return;
    }
    final ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    );
    final anim = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: ctrl, curve: Curves.easeInOutCubic),
    );
    final completer = Completer<void>();
    void tick() {
      if (!mounted) return;
      setState(() => _peekT = anim.value);
    }

    anim.addListener(tick);
    ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
        anim.removeListener(tick);
        ctrl.dispose();
        if (!completer.isCompleted) completer.complete();
      }
    });
    await ctrl.forward();
    await completer.future;
    if (mounted) setState(() => _peekT = to);
  }

  void _clearLift({bool keepPointer = false, bool keepHover = false}) {
    _removeOverlay();
    setState(() {
      _liftedCard = null;
      _liftGlobalCenter = null;
      _liftScale = 1.0;
      _peekCard = null;
      _peekT = 0;
      _upTravel = 0;
      _panAccum = Offset.zero;
      _dropBusy = false;
      _docking = false;
      if (!keepPointer) _pointerDown = false;
      if (!keepHover) _hoverIndex = null;
    });
    if (!keepHover) widget.onActiveChanged?.call(null);
    widget.onDragPosition?.call(null);
  }

  bool _globalOverFan(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    final origin = box.localToGlobal(Offset.zero);
    // Зона «возврата» чуть выше веера — на расстоянии extract.
    final rect = Rect.fromLTWH(
      origin.dx - 16,
      origin.dy - _extractPx - 8,
      box.size.width + 32,
      box.size.height + _extractPx + 24,
    );
    return rect.contains(global);
  }

  /// Возврат в веер: плавно к «чуть выше», затем опускание в слот.
  Future<void> _foldIntoFan(
    Offset global,
    double baseSpacing,
    double totalW, {
    bool keepPointer = false,
  }) async {
    final card = _liftedCard;
    if (card == null || _docking) return;
    _docking = true;
    _upTravel = 0;
    final gen = _gestureGen;
    final beginScale = _liftScale;
    final resume = keepPointer || _pointerDown;
    final slot = _slotGlobalRect(card, baseSpacing, totalW);
    final peekRect = Rect.fromCenter(
      center: Offset(slot.center.dx, slot.center.dy - _peekRaiseY),
      width: widget.cardSize.width,
      height: widget.cardSize.height,
    );

    // 1) Вставить «рукой» — слегка выглядывает.
    await _animateOverlayTo(
      peekRect,
      soft: true,
      beginScale: beginScale,
      ms: 280,
    );
    if (!mounted || gen != _gestureGen) {
      _docking = false;
      return;
    }

    // 2) Передать в peek веера и плавно утопить.
    _removeOverlay();
    final idx = _fanCards.indexOf(card);
    setState(() {
      _liftedCard = null;
      _liftGlobalCenter = null;
      _liftScale = 1.0;
      _peekCard = card;
      _peekT = 1.0;
      _dropBusy = false;
      if (idx >= 0) _hoverIndex = idx;
    });
    _emitActiveCard(_isLegal(card) ? card : null);
    widget.onDragPosition?.call(null);

    await _animatePeekTTo(0, ms: 220);
    if (!mounted || gen != _gestureGen) {
      _docking = false;
      return;
    }
    widget.onReturnToFan?.call(card);
    setState(() {
      _peekCard = null;
      _peekT = 0;
      _upTravel = 0;
      _panAccum = Offset.zero;
      _docking = false;
      if (!resume) _pointerDown = false;
    });
    await Future<void>.delayed(Duration.zero);
    if (!mounted || gen != _gestureGen) return;
    final finger = _lastPointerGlobal ?? global;
    if (resume && _pointerDown) {
      _resumeBrowseAt(finger);
    } else {
      // Карта снова в веере — без hover/подсказок на столе.
      _setHover(null);
      _emitActiveCard(null);
      widget.onDragPosition?.call(null);
    }
  }

  void _hoverFromGlobal(Offset global, double baseSpacing, double totalW) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(global);
    final cards = _fanCards;
    if (cards.isEmpty) return;
    final spacing = _spacingFor(cards.length);
    final w = widget.cardSize.width + spacing * max(cards.length - 1, 0);
    final idx = _indexAtLocalX(local.dx, cards.length, spacing, w);
    _setHover(idx);
    // Листание: peek следует за выбранной картой.
    if (_peekCard != null && idx >= 0 && idx < cards.length) {
      final next = cards[idx];
      if (next != _peekCard) {
        setState(() => _peekCard = next);
      }
    }
  }

  double _spacingFor(int n) {
    if (widget.spacing != null) return widget.spacing!;
    if (n <= 1) return 0;
    final w = widget.cardSize.width;
    if (n > 28) return w * 0.09;
    if (n > 22) return w * 0.11;
    if (n > 16) return w * 0.14;
    if (n > 12) return w * 0.18;
    if (n > 9) return w * 0.24;
    if (n > 7) return w * 0.32;
    if (n > 5) return w * 0.42;
    return w * 0.52;
  }

  double _arcFor(int n) {
    if (widget.arc != null) return widget.arc!;
    if (n <= 1) return 0;
    // Как раньше: заметная дуга, не плоская линия.
    if (n > 20) return 0.85;
    if (n > 14) return 0.68;
    if (n > 10) return 0.52;
    if (n > 6) return 0.4;
    return 0.28;
  }

  bool _isLegal(PlayingCard card) =>
      widget.legalCards == null || widget.legalCards!.contains(card);

  bool _isSelected(PlayingCard card) =>
      widget.selectedCards?.contains(card) == true;

  double _cardLeft(int i, int n, double baseSpacing, double totalW) {
    if (widget.fillWidth) {
      // Небольшой отступ слева — крайняя карта не обрезается краем экрана.
      return 10 + i * baseSpacing;
    }
    final center = (n - 1) / 2.0;
    return totalW / 2 + (i - center) * baseSpacing + 16;
  }

  int _indexAtLocalX(double localX, int n, double baseSpacing, double totalW) {
    if (n <= 0) return 0;
    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < n; i++) {
      final left = _cardLeft(i, n, baseSpacing, totalW);
      final cx = left + widget.cardSize.width / 2;
      final d = (localX - cx).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  Rect _slotGlobalRect(PlayingCard card, double baseSpacing, double totalW) {
    final box = context.findRenderObject() as RenderBox?;
    final cards = _layoutCards;
    final i = cards.indexOf(card);
    if (box == null || !box.hasSize) {
      return Rect.fromLTWH(0, 0, widget.cardSize.width, widget.cardSize.height);
    }
    if (i < 0) {
      final o = box.localToGlobal(Offset.zero);
      return Rect.fromLTWH(
        o.dx + box.size.width / 2 - widget.cardSize.width / 2,
        o.dy + box.size.height - widget.cardSize.height,
        widget.cardSize.width,
        widget.cardSize.height,
      );
    }
    final n = cards.length;
    final center = (n - 1) / 2;
    final curveY = widget.arc == 0
        ? 0.0
        : (i - center) * (i - center) * widget.cardSize.height * 0.012;
    final left = _cardLeft(i, n, baseSpacing, totalW);
    final top = box.size.height - widget.cardSize.height - curveY;
    final origin = box.localToGlobal(Offset(left, top));
    return Rect.fromLTWH(
      origin.dx,
      origin.dy,
      widget.cardSize.width,
      widget.cardSize.height,
    );
  }

  /// Старт фазы «чуть выше» в веере.
  void _ensurePeek(PlayingCard card) {
    if (_peekCard == card) return;
    setState(() {
      _peekCard = card;
    });
    _emitActiveCard(_isLegal(card) ? card : null);
  }

  void _setPeekT(double t) {
    final next = t.clamp(0.0, 1.0);
    if ((next - _peekT).abs() < 0.001) return;
    setState(() => _peekT = next);
  }

  /// Peek → свободный drag без скачка: overlay стартует из приподнятого слота.
  void _promotePeekToFree(
    Offset fingerGlobal,
    double baseSpacing,
    double totalW,
  ) {
    final card = _peekCard;
    if (card == null || _liftedCard != null || _dropBusy) return;
    _gestureGen++;
    _docking = false;
    final slot = _slotGlobalRect(card, baseSpacing, totalW);
    final startCenter = Offset(
      slot.center.dx,
      slot.center.dy - _peekRaiseY,
    );
    setState(() {
      _liftedCard = card;
      _peekCard = null;
      _peekT = 0;
    });
    _upTravel = _extractPx;
    _panAccum = Offset.zero;
    _emitActiveCard(_isLegal(card) ? card : null);
    // Сначала в точке подъёма, затем к пальцу — один непрерывный кадр.
    _liftScale = 1.0;
    _liftGlobalCenter = startCenter;
    _updateLiftVisual(startCenter);
    _updateLiftVisual(fingerGlobal);
    widget.onDragPosition?.call(fingerGlobal);
  }

  /// Свободный drag → снова «чуть выше» в веере (обратный жест).
  void _demoteFreeToPeek(
    Offset global,
    double baseSpacing,
    double totalW,
  ) {
    final card = _liftedCard;
    if (card == null) return;
    final t = (_upTravel / _extractPx).clamp(0.0, 1.0);
    _removeOverlay();
    final idx = _fanCards.indexOf(card);
    setState(() {
      _liftedCard = null;
      _liftGlobalCenter = null;
      _liftScale = 1.0;
      _peekCard = card;
      _peekT = t;
      if (idx >= 0) _hoverIndex = idx;
    });
    widget.onDragPosition?.call(null);
    _emitActiveCard(_isLegal(card) ? card : null);
    if (t <= 0.02) {
      unawaited(_finishPeekSettle(global));
    }
  }

  Future<void> _finishPeekSettle(Offset global) async {
    final card = _peekCard;
    if (card == null || _docking) return;
    _docking = true;
    _upTravel = 0;
    final gen = _gestureGen;
    // Палец ещё на экране — после въезда продолжаем листание тем же касанием.
    final resume = _pointerDown;
    await _animatePeekTTo(0, ms: 220);
    if (!mounted || gen != _gestureGen) {
      _docking = false;
      return;
    }
    widget.onReturnToFan?.call(card);
    setState(() {
      _peekCard = null;
      _peekT = 0;
      _upTravel = 0;
      _panAccum = Offset.zero;
      _docking = false;
      if (!resume) _pointerDown = false;
    });
    // Кадр после сортировки руки — слоты уже на новых местах.
    await Future<void>.delayed(Duration.zero);
    if (!mounted || gen != _gestureGen) return;
    final finger = _lastPointerGlobal ?? global;
    if (resume && _pointerDown) {
      _resumeBrowseAt(finger);
    } else {
      // Отпустили палец — убрать подсказки слота/отбоя.
      _setHover(null);
      _emitActiveCard(null);
      widget.onDragPosition?.call(null);
    }
  }

  double _totalWFor(double spacing) {
    final n = max(_fanCards.length, 1);
    return widget.cardSize.width + spacing * max(n - 1, 0);
  }

  /// После возврата карты в веер — акцент под пальцем, можно сразу листать/тянуть.
  void _resumeBrowseAt(Offset global) {
    final spacing = _spacingFor(max(_fanCards.length, 1));
    final totalW = _totalWFor(spacing);
    _hoverFromGlobal(global, spacing, totalW);
    _panAccum = Offset.zero;
    final t = (_upTravel / _extractPx).clamp(0.0, 1.0);
    if (t <= 0.02) return;
    final cards = _fanCards;
    final idx = _hoverIndex;
    if (idx == null || idx < 0 || idx >= cards.length) return;
    _ensurePeek(cards[idx]);
    _setPeekT(t);
    if (t >= 1.0) {
      _promotePeekToFree(global, spacing, totalW);
    }
  }

  Future<void> _finishDrop(
    Offset global,
    double baseSpacing,
    double totalW,
  ) async {
    if (_liftedCard == null && _peekCard != null) {
      await _finishPeekSettle(global);
      return;
    }

    final card = _liftedCard;
    if (card == null || _dropBusy || _docking) return;
    _dropBusy = true;
    final dragScale = _liftScale;
    final from = Rect.fromCenter(
      center: _liftGlobalCenter ?? global,
      width: widget.cardSize.width,
      height: widget.cardSize.height,
    );
    final canPlay = widget.enabled && !widget.faceDown && _isLegal(card);
    final flickedUp = _upTravel > _extractPx + 8 || _panAccum.dy < -16;
    final foldDown = _globalOverFan(global) && !flickedUp && _upTravel < _extractPx * 0.85;
    try {
      if (foldDown || (!canPlay && _globalOverFan(global))) {
        await _foldIntoFan(global, baseSpacing, totalW);
        return;
      }
      final drop = widget.onDrop;
      if (drop != null && canPlay) {
        _removeOverlay();
        final scaledFrom = Rect.fromCenter(
          center: from.center,
          width: widget.cardSize.width * dragScale,
          height: widget.cardSize.height * dragScale,
        );
        final accepted = await drop(card, global, scaledFrom);
        if (!mounted) return;
        if (accepted) {
          _clearLift();
          return;
        }
      }
      _liftGlobalCenter = from.center;
      _liftScale = dragScale;
      await _foldIntoFan(global, baseSpacing, totalW);
    } finally {
      if (mounted && _liftedCard != null) {
        _clearLift();
      } else if (!mounted) {
        _dropBusy = false;
        _docking = false;
        _removeOverlay();
        _liftedCard = null;
        _liftGlobalCenter = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final layoutCards = _layoutCards;
    final fanCards = _fanCards;
    if (layoutCards.isEmpty) {
      return SizedBox(
        width: widget.cardSize.width,
        height: widget.cardSize.height,
      );
    }
    final baseSpacing = _spacingFor(max(fanCards.length, 1));
    final totalW =
        widget.cardSize.width + baseSpacing * max(fanCards.length - 1, 0);
    // Запас по высоте под приподнятую карту.
    final height = widget.cardSize.height * 1.7 + _peekRaiseY;
    final arc = _arcFor(max(fanCards.length, 1));
    // fillWidth — карты + отступ слева 10; иначе запас по бокам.
    final boxW = widget.fillWidth ? totalW + 10 : totalW + 32;

    return SizedBox(
      height: height,
      width: boxW,
      child: Stack(
        clipBehavior: Clip.none,
        alignment:
            widget.invertFan ? Alignment.topCenter : Alignment.bottomCenter,
        children: [
          for (int i = 0; i < fanCards.length; i++)
            _positioned(
              i,
              fanCards.length,
              fanCards,
              baseSpacing,
              totalW,
              arc,
            ),
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: !widget.enabled || widget.faceDown
                  ? null
                  : (e) {
                      _lastPointerGlobal = e.position;
                      if (_liftedCard == null && (_docking || _dropBusy)) {
                        _gestureGen++;
                        _docking = false;
                        _dropBusy = false;
                        _removeOverlay();
                      }
                      _pointerDown = true;
                      _panAccum = Offset.zero;
                      _upTravel = 0;
                      // Не сбрасываем peek мгновенно при новом касании во время
                      // settle — _gestureGen выше уже отменит анимацию.
                      if (_peekCard != null && !_docking) {
                        setState(() {
                          _peekCard = null;
                          _peekT = 0;
                        });
                      }
                      final box = context.findRenderObject() as RenderBox?;
                      if (box == null) return;
                      final local = box.globalToLocal(e.position);
                      final idx = _indexAtLocalX(
                        local.dx,
                        fanCards.length,
                        baseSpacing,
                        totalW,
                      );
                      // Только акцент под пальцем — без «выезда» по клику.
                      _setHover(idx);
                    },
              onPointerMove: !widget.enabled || widget.faceDown
                  ? null
                  : (e) {
                      _lastPointerGlobal = e.position;
                      if (!_pointerDown || _dropBusy) return;
                      // Во время въезда/сортировки копим жест — продолжим после settle.
                      if (_docking) {
                        if (e.delta.dy < 0) {
                          _upTravel += -e.delta.dy;
                        } else if (e.delta.dy > 0) {
                          _upTravel = max(0.0, _upTravel - e.delta.dy);
                        }
                        return;
                      }
                      _panAccum += e.delta;

                      // ——— Свободный drag ———
                      if (_liftedCard != null) {
                        if (e.delta.dy < 0) {
                          _upTravel += -e.delta.dy;
                        } else if (e.delta.dy > 0) {
                          _upTravel = max(0, _upTravel - e.delta.dy);
                        }
                        // Обратный жест: на пороге extract — снова «чуть выше» в веере.
                        if (_globalOverFan(e.position) &&
                            _upTravel < _extractPx) {
                          _demoteFreeToPeek(e.position, baseSpacing, totalW);
                          return;
                        }
                        _updateLiftVisual(e.position);
                        widget.onDragPosition?.call(e.position);
                        return;
                      }

                      // Листание / выбор карты под пальцем.
                      _hoverFromGlobal(e.position, baseSpacing, totalW);

                      // ——— Фаза peek / вытаскивание ———
                      if (e.delta.dy < 0) {
                        _upTravel += -e.delta.dy;
                      } else if (e.delta.dy > 0 && _peekCard != null) {
                        _upTravel = max(0, _upTravel - e.delta.dy);
                      }

                      final live = _fanCards;
                      if (_hoverIndex == null ||
                          _hoverIndex! < 0 ||
                          _hoverIndex! >= live.length) {
                        return;
                      }
                      final card = live[_hoverIndex!];

                      // Горизонталь без подъёма — только листание (акцент).
                      final pullingUp = _upTravel > 2 || _panAccum.dy < -2;
                      if (!pullingUp && _peekCard == null) return;

                      if (_peekCard == null) {
                        _ensurePeek(card);
                      } else if (_peekCard != card && _peekT < 0.55) {
                        // Листание во время лёгкого подъёма — смена карты.
                        _ensurePeek(card);
                      }

                      final t = (_upTravel / _extractPx).clamp(0.0, 1.0);
                      _setPeekT(t);

                      if (t >= 1.0) {
                        _promotePeekToFree(
                          e.position,
                          baseSpacing,
                          totalW,
                        );
                        return;
                      }

                      if (t <= 0.02 && e.delta.dy > 0) {
                        unawaited(_finishPeekSettle(e.position));
                      }
                    },
              onPointerUp: !widget.enabled || widget.faceDown
                  ? null
                  : (e) {
                      _lastPointerGlobal = e.position;
                      _pointerDown = false;
                      if (_docking && _liftedCard == null && _peekCard == null) {
                        _panAccum = Offset.zero;
                        return;
                      }
                      if (_liftedCard != null || _peekCard != null) {
                        unawaited(
                          _finishDrop(e.position, baseSpacing, totalW),
                        );
                        return;
                      }
                      // Короткий тап — без выбора/выезда карты (только long-press
                      // для мультивыбора атаки). onTap оставляем для совместимости.
                      if (_panAccum.distance < 12 &&
                          _hoverIndex != null &&
                          _hoverIndex! >= 0 &&
                          _hoverIndex! < fanCards.length) {
                        final card = fanCards[_hoverIndex!];
                        if (_isLegal(card) || widget.legalCards == null) {
                          widget.onTap?.call(card);
                        }
                      }
                      _panAccum = Offset.zero;
                      // Снять акцент после отпускания.
                      _setHover(null);
                    },
              onPointerCancel: (_) {
                _pointerDown = false;
                if (_liftedCard != null && !_docking) {
                  unawaited(_finishDrop(
                    _liftGlobalCenter ?? Offset.zero,
                    baseSpacing,
                    totalW,
                  ));
                } else if (_peekCard != null) {
                  unawaited(_finishPeekSettle(
                    _lastPointerGlobal ?? Offset.zero,
                  ));
                } else if (_docking) {
                  _docking = false;
                  _dropBusy = false;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _positioned(
    int i,
    int n,
    List<PlayingCard> cards,
    double baseSpacing,
    double totalW,
    double arc,
  ) {
    final center = (n - 1) / 2;
    // Одинаковый знак угла: у соперника (topCenter) края веера «к нему».
    final angle = n == 1 || arc == 0
        ? 0.0
        : (i - center) * (arc / max(n - 1, 1));
    // arc == 0 — ровный ряд (соперник); иначе парабола краёв как раньше.
    final curveY = arc == 0
        ? 0.0
        : (i - center) * (i - center) * widget.cardSize.height * 0.012;

    var extraX = 0.0;
    var extraY = 0.0;
    var scale = 1.0;
    final card = cards[i];
    final isLiftedAway = _liftedCard == card;
    final selected = _isSelected(card);
    final peeking = _peekCard == card && !isLiftedAway;
    final active =
        (_hoverIndex == i && _liftedCard == null) || peeking;

    if (_hoverIndex != null &&
        !active &&
        _liftedCard == null &&
        !peeking &&
        !isLiftedAway) {
      final dir = i > _hoverIndex! ? 1 : -1;
      final distance = (i - _hoverIndex!).abs();
      extraX = dir * widget.cardSize.width * (0.22 / max(distance, 1));
    }
    // Выезд только при жесте peek/тяги вверх — не по клику/hover/selected.
    if (peeking) {
      extraY = max(extraY, _peekRaiseY * _peekT);
      scale = max(scale, 1.0 + 0.04 * _peekT);
    }

    final legal = _isLegal(card);
    final isLegalContext = widget.legalCards != null;
    // Подсказка — только тень у активной/выбранной; без фиолетовой обводки всех легальных.
    final showHintShadow = !isLiftedAway &&
        ((active || selected) && (!isLegalContext || legal));

    Widget child = isLiftedAway
        ? SizedBox(
            width: widget.cardSize.width,
            height: widget.cardSize.height,
          )
        : widget.faceDown
            ? CardBackWidget(
                size: widget.cardSize, elevated: peeking || active)
            : PlayingCardWidget(
                card: card,
                size: widget.cardSize,
                highlighted: showHintShadow,
                dimmed: isLegalContext && !legal,
                // Selected — только тень (мультивыбор long-press), без подъёма.
                elevated: active || peeking || selected,
              );

    child = GestureDetector(
      onLongPress: !widget.enabled || widget.faceDown || !legal
          ? null
          : () => widget.onLongPress?.call(card),
      child: child,
    );

    // Края веера поднимаются «от стола»: у себя вверх, у соперника к верху экрана.
    final edgeLift = -curveY;

    // Peek — без duration; перестановка после сортировки — плавная.
    final animMs =
        peeking || !widget.animateLayout ? 0 : 380;
    final left = _cardLeft(i, n, baseSpacing, totalW) + extraX;
    final top = widget.invertFan ? extraY + edgeLift : null;
    final bottom = widget.invertFan ? null : extraY + edgeLift;
    final scaled = AnimatedScale(
      scale: scale,
      duration: Duration(milliseconds: peeking || !widget.animateLayout ? 0 : 280),
      curve: Curves.easeInOutCubic,
      child: Transform.rotate(
        angle: angle,
        alignment:
            widget.invertFan ? Alignment.topCenter : Alignment.bottomCenter,
        child: child,
      ),
    );

    if (!widget.animateLayout || peeking) {
      return Positioned(
        key: ValueKey('fan-${card.rank.value}-${card.suit.name}'),
        left: left,
        top: top,
        bottom: bottom,
        child: scaled,
      );
    }

    return AnimatedPositioned(
      key: ValueKey('fan-${card.rank.value}-${card.suit.name}'),
      duration: Duration(milliseconds: animMs),
      curve: Curves.easeInOutCubic,
      left: left,
      top: top,
      bottom: bottom,
      child: scaled,
    );
  }
}

/// Глобальный rect активной/первой карты веера — для анимации полёта.
Rect? cardFanApproxOrigin(BuildContext fanContext, Size cardSize) {
  final box = fanContext.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  final origin = box.localToGlobal(Offset.zero);
  return Rect.fromLTWH(
    origin.dx + box.size.width / 2 - cardSize.width / 2,
    origin.dy + box.size.height - cardSize.height - cardSize.height * 0.22,
    cardSize.width,
    cardSize.height,
  );
}
