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
/// - Тянуть вниз к вееру: на том же расстоянии — снова чуть выше, потом в веер
///   с подсветкой; влево/вправо — листание веера.
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

  @override
  State<CardFan> createState() => _CardFanState();
}

class _CardFanState extends State<CardFan> {
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
    entry = OverlayEntry(
      builder: (ctx) {
        return IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: soft ? 260 : 220),
            curve: soft ? Curves.easeOutCubic : Curves.easeInOutCubic,
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
              final lift = soft ? -10.0 * sin(pi * t) : 0.0;
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
                              highlighted: t < 0.8,
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

  /// Аккуратно сложить карту в веер (отпустили над веером).
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
    final to = _slotGlobalRect(card, baseSpacing, totalW);
    await _animateOverlayTo(to, soft: true, beginScale: beginScale);
    if (!mounted || gen != _gestureGen) {
      _docking = false;
      return;
    }
    widget.onReturnToFan?.call(card);
    _clearLift(keepPointer: keepPointer, keepHover: keepPointer);
    if (keepPointer) {
      _hoverFromGlobal(global, baseSpacing, totalW);
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
    if (n > 28) return w * 0.12;
    if (n > 22) return w * 0.15;
    if (n > 16) return w * 0.2;
    if (n > 12) return w * 0.26;
    if (n > 9) return w * 0.32;
    if (n > 7) return w * 0.4;
    if (n > 5) return w * 0.48;
    return w * 0.56;
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
    for (var i = 0; i < n; i++) {
      final left = totalW / 2 + (i - center) * baseSpacing + 16;
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
    final offsetX = (i - center) * baseSpacing;
    final curveY = (i - center) * (i - center) * widget.cardSize.height * 0.012;
    final left = totalW / 2 + offsetX + 16;
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
      _settlePeekIntoFan(global, baseSpacing, totalW);
    }
  }

  /// Полностью убрать peek — карта в веере с подсветкой, можно листать.
  void _settlePeekIntoFan(
    Offset global,
    double baseSpacing,
    double totalW,
  ) {
    final card = _peekCard;
    if (card == null) return;
    widget.onReturnToFan?.call(card);
    setState(() {
      _peekCard = null;
      _peekT = 0;
      _upTravel = 0;
      _panAccum = Offset.zero;
    });
    _hoverFromGlobal(global, baseSpacing, totalW);
  }

  Future<void> _finishDrop(
    Offset global,
    double baseSpacing,
    double totalW,
  ) async {
    // Если ещё в peek — просто оставить в веере с подсветкой.
    if (_liftedCard == null && _peekCard != null) {
      if (_peekT < 0.35) {
        _settlePeekIntoFan(global, baseSpacing, totalW);
      } else {
        // Отпустили на полуподъёме — дотянуть в слот с подсветкой.
        _settlePeekIntoFan(global, baseSpacing, totalW);
      }
      _pointerDown = false;
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
        await _foldIntoFan(global, baseSpacing, totalW, keepPointer: false);
        // После fold — подсветить карту в веере.
        if (!mounted) return;
        final cards = _layoutCards;
        final idx = cards.indexOf(card);
        if (idx >= 0) _setHover(idx);
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
        if (accepted) return;
      }
      _liftGlobalCenter = from.center;
      _liftScale = dragScale;
      await _foldIntoFan(global, baseSpacing, totalW);
      if (!mounted) return;
      final cards = _layoutCards;
      final idx = cards.indexOf(card);
      if (idx >= 0) _setHover(idx);
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

    return SizedBox(
      height: height,
      width: totalW + 32,
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
                      if (_liftedCard == null && (_docking || _dropBusy)) {
                        _gestureGen++;
                        _docking = false;
                        _dropBusy = false;
                        _removeOverlay();
                      }
                      _pointerDown = true;
                      _panAccum = Offset.zero;
                      _upTravel = 0;
                      _peekT = 0;
                      _peekCard = null;
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
                      if (_docking && _liftedCard == null) {
                        _docking = false;
                      }
                      if (_docking) return;
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

                      // Горизонталь без подъёма — только листание.
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
                        // Полностью опустили обратно — подсветка + листание.
                        _settlePeekIntoFan(e.position, baseSpacing, totalW);
                      }
                    },
              onPointerUp: !widget.enabled || widget.faceDown
                  ? null
                  : (e) {
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
                  _settlePeekIntoFan(
                    _liftGlobalCenter ?? Offset.zero,
                    baseSpacing,
                    totalW,
                  );
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
    final offsetX = (i - center) * baseSpacing;
    final signedArc = widget.invertFan ? -arc : arc;
    final angle = n == 1 ? 0.0 : (i - center) * (signedArc / max(n - 1, 1));
    final curveY = (i - center) * (i - center) * widget.cardSize.height * 0.012;

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
      extraX = dir * widget.cardSize.width * (0.28 / max(distance, 1));
    }
    if (selected && !isLiftedAway) {
      extraY = widget.cardSize.height * 0.22;
      scale = 1.08;
    }
    // Плавный подъём «чуть выше» — без AnimatedPositioned-лага на этой оси.
    if (peeking) {
      extraY = max(extraY, _peekRaiseY * _peekT);
      scale = max(scale, 1.0 + 0.04 * _peekT);
    } else if (active && !selected) {
      extraY = max(extraY, widget.cardSize.height * 0.08);
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
        ? SizedBox(
            width: widget.cardSize.width,
            height: widget.cardSize.height,
          )
        : widget.faceDown
            ? CardBackWidget(
                size: widget.cardSize, elevated: selected || peeking)
            : PlayingCardWidget(
                card: card,
                size: widget.cardSize,
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

    // Peek двигаем без duration — иначе ступор при вытаскивании.
    final animMs = peeking ? 0 : 140;

    return AnimatedPositioned(
      key: ValueKey('fan-${card.rank.value}-${card.suit.name}'),
      duration: Duration(milliseconds: animMs),
      curve: Curves.easeOutCubic,
      left: totalW / 2 + offsetX + extraX + 16,
      top: widget.invertFan ? extraY + edgeLift : null,
      bottom: widget.invertFan ? null : extraY + edgeLift,
      child: AnimatedScale(
        scale: scale,
        duration: Duration(milliseconds: peeking ? 0 : 120),
        curve: Curves.easeOutCubic,
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
