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
/// - [maxWidth]: растянуть веер по ширине (моб/планшет).
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
    this.maxWidth,
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

  final ValueChanged<PlayingCard>? onReturnToFan;
  final ValueChanged<PlayingCard?>? onActiveChanged;
  final ValueChanged<Offset?>? onDragPosition;
  final bool faceDown;
  final bool invertFan;
  final double? arc;
  final double? spacing;

  /// Растянуть веер на эту ширину (padding учитывается внутри).
  final double? maxWidth;

  @override
  State<CardFan> createState() => _CardFanState();
}

class _CardFanState extends State<CardFan> with TickerProviderStateMixin {
  static const double _extractPx = 40;

  int? _hoverIndex;
  Offset _panAccum = Offset.zero;
  bool _dropBusy = false;
  bool _docking = false;
  int _gestureGen = 0;

  PlayingCard? _liftedCard;
  Offset? _liftGlobalCenter;
  double _liftScale = 1.0;

  PlayingCard? _peekCard;
  double _peekT = 0;
  double _upTravel = 0;
  OverlayEntry? _overlay;
  bool _pointerDown = false;

  /// Плавная анимация spacing / scale карт.
  late final AnimationController _layoutCtrl;
  double _spacingFrom = 0;
  double _spacingTo = 0;
  double _scaleFrom = 1;
  double _scaleTo = 1;
  int _layoutCardCount = -1;
  bool _layoutExtracting = false;

  double get _peekRaiseY => _displayCardSize.height * 0.30;

  Size get _displayCardSize {
    final t = Curves.easeInOutCubic.transform(_layoutCtrl.value);
    final s = _scaleFrom + (_scaleTo - _scaleFrom) * t;
    return Size(widget.cardSize.width * s, widget.cardSize.height * s);
  }

  double get _displaySpacing {
    final t = Curves.easeInOutCubic.transform(_layoutCtrl.value);
    return _spacingFrom + (_spacingTo - _spacingFrom) * t;
  }

  List<PlayingCard> get _layoutCards {
    final hidden = widget.hiddenCards;
    if (hidden == null || hidden.isEmpty) return widget.cards;
    return widget.cards.where((c) => !hidden.contains(c)).toList();
  }

  List<PlayingCard> get _fanCards => _layoutCards;

  bool get _isExtracting =>
      _liftedCard != null || _peekCard != null || _peekT > 0.04;

  @override
  void initState() {
    super.initState();
    _layoutCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: 1,
    )..addListener(() {
        if (mounted) setState(() {});
      });
    final n = max(widget.cards.length, 1);
    _spacingTo = _computeSpacing(n, extracting: false);
    _spacingFrom = _spacingTo;
    _scaleTo = _computeSizeScale(n, extracting: false);
    _scaleFrom = _scaleTo;
    _layoutCardCount = n;
  }

  @override
  void didUpdateWidget(covariant CardFan oldWidget) {
    super.didUpdateWidget(oldWidget);
    _retargetLayout();
  }

  @override
  void dispose() {
    _layoutCtrl.dispose();
    _removeOverlay();
    super.dispose();
  }

  double _computeSizeScale(int n, {required bool extracting}) {
    var s = n <= 2
        ? 1.2
        : n <= 4
            ? 1.14
            : n <= 6
                ? 1.08
                : n <= 9
                    ? 1.02
                    : n <= 14
                        ? 0.96
                        : n <= 20
                            ? 0.9
                            : 0.84;
    // Только размер при вытаскивании — жесты не трогаем.
    if (extracting) s *= 1.1;
    return s;
  }

  double _computeSpacing(int n, {required bool extracting}) {
    if (n <= 1) return 0;
    final base = widget.cardSize;
    final scale = _computeSizeScale(n, extracting: extracting);
    final cardW = base.width * scale;

    if (widget.spacing != null && widget.maxWidth == null) {
      return widget.spacing! * (extracting ? 1.14 : 1.0);
    }

    final maxW = widget.maxWidth;
    if (maxW != null && maxW > 40) {
      const pad = 12.0;
      final avail = max(0.0, maxW - pad - cardW);
      var s = avail / (n - 1);
      final minS = cardW * (n > 16 ? 0.16 : n > 10 ? 0.22 : n > 6 ? 0.3 : 0.4);
      // Вытащили карту — растянуть веер на всю ширину экрана.
      final maxS = cardW * (extracting ? 1.35 : 0.78);
      s = s.clamp(minS, maxS);
      return s;
    }

    // Fallback без maxWidth.
    final w = cardW;
    double s;
    if (n > 28) {
      s = w * 0.14;
    } else if (n > 22) {
      s = w * 0.18;
    } else if (n > 16) {
      s = w * 0.24;
    } else if (n > 12) {
      s = w * 0.3;
    } else if (n > 9) {
      s = w * 0.38;
    } else if (n > 7) {
      s = w * 0.48;
    } else if (n > 5) {
      s = w * 0.58;
    } else {
      s = w * 0.7;
    }
    if (extracting) s *= 1.18;
    return s;
  }

  void _retargetLayout() {
    final n = max(_layoutCards.length, 1);
    final extracting = _isExtracting;
    if (n == _layoutCardCount &&
        extracting == _layoutExtracting &&
        _layoutCtrl.isCompleted) {
      // Всё равно пересчитать на случай смены maxWidth/cardSize.
    }
    final nextSpacing = _computeSpacing(n, extracting: extracting);
    final nextScale = _computeSizeScale(n, extracting: extracting);
    final curT = Curves.easeInOutCubic.transform(_layoutCtrl.value);
    final curSpacing = _spacingFrom + (_spacingTo - _spacingFrom) * curT;
    final curScale = _scaleFrom + (_scaleTo - _scaleFrom) * curT;
    if ((nextSpacing - curSpacing).abs() < 0.4 &&
        (nextScale - curScale).abs() < 0.008) {
      _layoutCardCount = n;
      _layoutExtracting = extracting;
      return;
    }
    _spacingFrom = curSpacing;
    _scaleFrom = curScale;
    _spacingTo = nextSpacing;
    _scaleTo = nextScale;
    _layoutCardCount = n;
    _layoutExtracting = extracting;
    _layoutCtrl.forward(from: 0);
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
    final cardSize = _displayCardSize;
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
        final w = cardSize.width * scale;
        final h = cardSize.height * scale;
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
                      ? CardBackWidget(size: cardSize, elevated: true)
                      : PlayingCardWidget(
                          card: card,
                          size: cardSize,
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
    final cardSize = _displayCardSize;
    final from = Rect.fromCenter(
      center: fromCenter,
      width: cardSize.width * beginScale,
      height: cardSize.height * beginScale,
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
              final w = cardSize.width * scale;
              final h = cardSize.height * scale;
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
                          ? CardBackWidget(size: cardSize, elevated: true)
                          : PlayingCardWidget(
                              card: card,
                              size: cardSize,
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
    _retargetLayout();
    if (!keepHover) widget.onActiveChanged?.call(null);
    widget.onDragPosition?.call(null);
  }

  bool _globalOverFan(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    final origin = box.localToGlobal(Offset.zero);
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
    final gen = _gestureGen;
    final beginScale = _liftScale;
    final cardSize = _displayCardSize;
    final slot = _slotGlobalRect(card, baseSpacing, totalW);
    final peekRect = Rect.fromCenter(
      center: Offset(slot.center.dx, slot.center.dy - _peekRaiseY),
      width: cardSize.width,
      height: cardSize.height,
    );

    // 1) Вставить «рукой» — слегка выглядывает.
    await _animateOverlayTo(
      peekRect,
      soft: true,
      beginScale: beginScale,
      ms: 300,
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
    _retargetLayout();

    await _animatePeekTTo(0, ms: 300);
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
      if (!keepPointer) _pointerDown = false;
    });
    _retargetLayout();
    if (keepPointer) {
      _hoverFromGlobal(global, _displaySpacing, _totalWFor(_displaySpacing));
    } else if (idx >= 0) {
      _setHover(idx);
    }
  }

  double _totalWFor(double spacing) {
    final n = max(_fanCards.length, 1);
    return _displayCardSize.width + spacing * max(n - 1, 0);
  }

  void _hoverFromGlobal(Offset global, double baseSpacing, double totalW) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(global);
    final cards = _fanCards;
    if (cards.isEmpty) return;
    final idx = _indexAtLocalX(local.dx, cards.length, baseSpacing, totalW);
    _setHover(idx);
    if (_peekCard != null && idx >= 0 && idx < cards.length) {
      final next = cards[idx];
      if (next != _peekCard) {
        setState(() => _peekCard = next);
      }
    }
  }

  double _arcFor(int n) {
    if (widget.arc != null) return widget.arc!;
    if (n <= 1) return 0;
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

  int _indexAtLocalX(double localX, int n, double baseSpacing, double totalW) {
    if (n <= 0) return 0;
    final center = (n - 1) / 2.0;
    var best = 0;
    var bestDist = double.infinity;
    final cardW = _displayCardSize.width;
    for (var i = 0; i < n; i++) {
      final left = totalW / 2 + (i - center) * baseSpacing + 16;
      final cx = left + cardW / 2;
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
    final cardSize = _displayCardSize;
    if (box == null || !box.hasSize) {
      return Rect.fromLTWH(0, 0, cardSize.width, cardSize.height);
    }
    if (i < 0) {
      final o = box.localToGlobal(Offset.zero);
      return Rect.fromLTWH(
        o.dx + box.size.width / 2 - cardSize.width / 2,
        o.dy + box.size.height - cardSize.height,
        cardSize.width,
        cardSize.height,
      );
    }
    final n = cards.length;
    final center = (n - 1) / 2;
    final offsetX = (i - center) * baseSpacing;
    final curveY = (i - center) * (i - center) * cardSize.height * 0.012;
    final left = totalW / 2 + offsetX + 16;
    final top = box.size.height - cardSize.height - curveY;
    final origin = box.localToGlobal(Offset(left, top));
    return Rect.fromLTWH(origin.dx, origin.dy, cardSize.width, cardSize.height);
  }

  void _ensurePeek(PlayingCard card) {
    if (_peekCard == card) return;
    setState(() => _peekCard = card);
    _emitActiveCard(_isLegal(card) ? card : null);
    _retargetLayout();
  }

  void _setPeekT(double t) {
    final next = t.clamp(0.0, 1.0);
    if ((next - _peekT).abs() < 0.001) return;
    setState(() => _peekT = next);
  }

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
    _liftScale = 1.0;
    _liftGlobalCenter = startCenter;
    _updateLiftVisual(startCenter);
    _updateLiftVisual(fingerGlobal);
    widget.onDragPosition?.call(fingerGlobal);
    _retargetLayout();
  }

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
    _retargetLayout();
    if (t <= 0.02) {
      unawaited(_finishPeekSettle(global));
    }
  }

  Future<void> _finishPeekSettle(Offset global) async {
    final card = _peekCard;
    if (card == null || _docking) return;
    _docking = true;
    final gen = _gestureGen;
    await _animatePeekTTo(0, ms: 280);
    if (!mounted || gen != _gestureGen) {
      _docking = false;
      return;
    }
    widget.onReturnToFan?.call(card);
    final idx = _fanCards.indexOf(card);
    setState(() {
      _peekCard = null;
      _peekT = 0;
      _upTravel = 0;
      _panAccum = Offset.zero;
      _docking = false;
      _pointerDown = false;
      if (idx >= 0) _hoverIndex = idx;
    });
    _retargetLayout();
    if (idx >= 0) _setHover(idx);
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
    final cardSize = _displayCardSize;
    final from = Rect.fromCenter(
      center: _liftGlobalCenter ?? global,
      width: cardSize.width,
      height: cardSize.height,
    );
    final canPlay = widget.enabled && !widget.faceDown && _isLegal(card);
    final flickedUp = _upTravel > _extractPx + 8 || _panAccum.dy < -16;
    final foldDown =
        _globalOverFan(global) && !flickedUp && _upTravel < _extractPx * 0.85;
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
          width: cardSize.width * dragScale,
          height: cardSize.height * dragScale,
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

    final cardSize = _displayCardSize;
    final baseSpacing = _displaySpacing;
    final totalW = _totalWFor(baseSpacing);
    final height = cardSize.height * 1.7 + _peekRaiseY;
    final arc = _arcFor(max(fanCards.length, 1));
    final fanWidth = widget.maxWidth != null
        ? min(widget.maxWidth!, totalW + 32)
        : totalW + 32;

    return SizedBox(
      height: height,
      width: fanWidth,
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
              cardSize,
            ),
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: !widget.enabled || widget.faceDown
                  ? null
                  : (e) {
                      if (_liftedCard == null && (_docking || _dropBusy)) {
                        _gestureGen++;
                        _docking = false;
                        _dropBusy = false;
                        _removeOverlay();
                      }
                      _pointerDown = true;
                      _panAccum = Offset.zero;
                      _upTravel = 0;
                      if (_peekCard != null) {
                        setState(() {
                          _peekCard = null;
                          _peekT = 0;
                        });
                        _retargetLayout();
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
                      _setHover(idx);
                    },
              onPointerMove: !widget.enabled || widget.faceDown
                  ? null
                  : (e) {
                      if (!_pointerDown || _dropBusy) return;
                      if (_docking && _liftedCard == null && _peekCard == null) {
                        _docking = false;
                      }
                      if (_docking) return;
                      _panAccum += e.delta;

                      if (_liftedCard != null) {
                        if (e.delta.dy < 0) {
                          _upTravel += -e.delta.dy;
                        } else if (e.delta.dy > 0) {
                          _upTravel = max(0, _upTravel - e.delta.dy);
                        }
                        if (_globalOverFan(e.position) &&
                            _upTravel < _extractPx) {
                          _demoteFreeToPeek(e.position, baseSpacing, totalW);
                          return;
                        }
                        _updateLiftVisual(e.position);
                        widget.onDragPosition?.call(e.position);
                        return;
                      }

                      _hoverFromGlobal(e.position, baseSpacing, totalW);

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
                      final pullingUp = _upTravel > 2 || _panAccum.dy < -2;
                      if (!pullingUp && _peekCard == null) return;

                      if (_peekCard == null) {
                        _ensurePeek(card);
                      } else if (_peekCard != card && _peekT < 0.55) {
                        _ensurePeek(card);
                      }

                      final t = (_upTravel / _extractPx).clamp(0.0, 1.0);
                      _setPeekT(t);

                      if (t >= 1.0) {
                        _promotePeekToFree(e.position, baseSpacing, totalW);
                        return;
                      }
                      if (t <= 0.02 && e.delta.dy > 0) {
                        unawaited(_finishPeekSettle(e.position));
                      }
                    },
              onPointerUp: !widget.enabled || widget.faceDown
                  ? null
                  : (e) {
                      _pointerDown = false;
                      if (_docking &&
                          _liftedCard == null &&
                          _peekCard == null) {
                        _panAccum = Offset.zero;
                        return;
                      }
                      if (_liftedCard != null || _peekCard != null) {
                        unawaited(
                          _finishDrop(e.position, baseSpacing, totalW),
                        );
                        return;
                      }
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
                  unawaited(_finishPeekSettle(Offset.zero));
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
    Size cardSize,
  ) {
    final center = (n - 1) / 2;
    final offsetX = (i - center) * baseSpacing;
    final signedArc = widget.invertFan ? -arc : arc;
    final angle = n == 1 ? 0.0 : (i - center) * (signedArc / max(n - 1, 1));
    final curveY = (i - center) * (i - center) * cardSize.height * 0.012;

    var extraX = 0.0;
    var extraY = 0.0;
    var scale = 1.0;
    final card = cards[i];
    final isLiftedAway = _liftedCard == card;
    final selected = _isSelected(card);
    final peeking = _peekCard == card && !isLiftedAway;
    final active = (_hoverIndex == i && _liftedCard == null) || peeking;

    if (_hoverIndex != null &&
        !active &&
        _liftedCard == null &&
        !peeking &&
        !isLiftedAway) {
      final dir = i > _hoverIndex! ? 1 : -1;
      final distance = (i - _hoverIndex!).abs();
      extraX = dir * cardSize.width * (0.22 / max(distance, 1));
    }
    if (selected && !isLiftedAway) {
      extraY = cardSize.height * 0.22;
      scale = 1.08;
    }
    if (peeking) {
      extraY = max(extraY, _peekRaiseY * _peekT);
      scale = max(scale, 1.0 + 0.04 * _peekT);
    } else if (active && !selected) {
      extraY = max(extraY, cardSize.height * 0.08);
    }

    final legal = _isLegal(card);
    final isLegalContext = widget.legalCards != null;
    final showLegalGlow = !isLiftedAway &&
        isLegalContext &&
        legal &&
        !selected &&
        !active &&
        widget.enabled;

    Widget child = isLiftedAway
        ? SizedBox(width: cardSize.width, height: cardSize.height)
        : widget.faceDown
            ? CardBackWidget(size: cardSize, elevated: selected || peeking)
            : PlayingCardWidget(
                card: card,
                size: cardSize,
                highlighted: showLegalGlow ||
                    ((active || selected) && (!isLegalContext || legal)),
                dimmed: isLegalContext && !legal,
                elevated: selected || active || peeking,
              );

    child = GestureDetector(
      onLongPress: !widget.enabled || widget.faceDown || !legal
          ? null
          : () => widget.onLongPress?.call(card),
      child: child,
    );

    final edgeLift = widget.invertFan ? curveY : -curveY;
    // Spacing/size уже анимируются контроллером — позиции тоже мягко.
    final animMs = peeking ? 0 : 320;

    return AnimatedPositioned(
      key: ValueKey('fan-${card.rank.value}-${card.suit.name}'),
      duration: Duration(milliseconds: animMs),
      curve: Curves.easeInOutCubic,
      left: totalW / 2 + offsetX + extraX + 16,
      top: widget.invertFan ? extraY + edgeLift : null,
      bottom: widget.invertFan ? null : extraY + edgeLift,
      child: AnimatedScale(
        scale: scale,
        duration: Duration(milliseconds: peeking ? 0 : 280),
        curve: Curves.easeInOutCubic,
        child: Transform.rotate(
          angle: angle,
          alignment:
              widget.invertFan ? Alignment.topCenter : Alignment.bottomCenter,
          child: child,
        ),
      ),
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
