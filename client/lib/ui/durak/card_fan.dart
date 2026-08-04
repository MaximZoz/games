import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';

/// Веер карт игрока.
///
/// - Водить пальцем по вееру — подсвечивается карта под пальцем.
/// - Тянуть вверх — карта фиксируется и следует за пальцем (overlay).
/// - Отпускание на стол: [onDrop]; на веер / мимо — красивый возврат.
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
    this.onActiveChanged,
    this.onDragPosition,
    this.faceDown = false,
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

  /// `true` — карта принята столом (больше не в веере).
  /// `false` — вернуть в веер с анимацией.
  final Future<bool> Function(
    PlayingCard card,
    Offset globalPosition,
    Rect from,
  )? onDrop;
  final ValueChanged<PlayingCard?>? onActiveChanged;

  /// Глобальная позиция пальца во время драга (для выбора цели защиты).
  final ValueChanged<Offset?>? onDragPosition;
  final bool faceDown;
  final double? arc;
  final double? spacing;

  @override
  State<CardFan> createState() => _CardFanState();
}

class _CardFanState extends State<CardFan> with SingleTickerProviderStateMixin {
  int? _hoverIndex;
  Offset _panAccum = Offset.zero;
  bool _dropBusy = false;

  /// Зафиксированная карта на время драга (не меняется при свайпе).
  PlayingCard? _liftedCard;
  Offset? _liftGlobalCenter;
  OverlayEntry? _overlay;
  bool _pointerDown = false;

  late final AnimationController _returnCtrl;

  List<PlayingCard> get _visible {
    final hidden = <PlayingCard>{
      ...?widget.hiddenCards,
      if (_liftedCard != null) _liftedCard!,
    };
    if (hidden.isEmpty) return widget.cards;
    return widget.cards.where((c) => !hidden.contains(c)).toList();
  }

  @override
  void initState() {
    super.initState();
    _returnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _returnCtrl.dispose();
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
      final cards = _visible;
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

  void _showOverlayAt(Offset globalCenter) {
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
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: center.dx - widget.cardSize.width / 2,
                top: center.dy - widget.cardSize.height / 2,
                child: Transform.scale(
                  scale: 1.12,
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

  Future<void> _animateOverlayTo(Rect to, {bool arc = false}) async {
    final fromCenter = _liftGlobalCenter;
    final card = _liftedCard;
    if (fromCenter == null || card == null) return;
    final from = Rect.fromCenter(
      center: fromCenter,
      width: widget.cardSize.width,
      height: widget.cardSize.height,
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
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            onEnd: () {
              entry.remove();
              if (!completer.isCompleted) completer.complete();
            },
            builder: (context, t, _) {
              final left = from.left + (to.left - from.left) * t;
              final lift = arc ? -36 * sin(pi * t) : 0.0;
              final top = from.top + (to.top - from.top) * t + lift;
              final scale = 1.12 - 0.12 * t;
              final rot = arc ? (1 - t) * 0.12 : 0.0;
              return Stack(
                children: [
                  Positioned(
                    left: left,
                    top: top,
                    child: Transform.rotate(
                      angle: rot,
                      child: Transform.scale(
                        scale: scale,
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

  void _clearLift({bool keepHover = false}) {
    _removeOverlay();
    setState(() {
      _liftedCard = null;
      _liftGlobalCenter = null;
      _panAccum = Offset.zero;
      _dropBusy = false;
      _pointerDown = false;
      if (!keepHover) _hoverIndex = null;
    });
    if (!keepHover) widget.onActiveChanged?.call(null);
    widget.onDragPosition?.call(null);
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
    final cards = widget.cards
        .where((c) => widget.hiddenCards?.contains(c) != true)
        .toList();
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

  void _tryLift(PlayingCard card, Offset global) {
    if (_liftedCard != null) return;
    if (!_isLegal(card) && widget.legalCards != null) return;
    setState(() {
      _liftedCard = card;
    });
    _emitActiveCard(card);
    widget.onDragPosition?.call(global);
    _showOverlayAt(global);
  }

  Future<void> _finishDrop(
    Offset global,
    double baseSpacing,
    double totalW,
  ) async {
    final card = _liftedCard;
    if (card == null || _dropBusy) return;
    _dropBusy = true;
    final from = Rect.fromCenter(
      center: _liftGlobalCenter ?? global,
      width: widget.cardSize.width,
      height: widget.cardSize.height,
    );
    var accepted = false;
    try {
      // Снять drag-overlay — дальше либо fly на стол, либо анимация возврата.
      _removeOverlay();
      final canPlay =
          widget.enabled && !widget.faceDown && _isLegal(card);
      final drop = widget.onDrop;
      if (drop != null && canPlay) {
        accepted = await drop(card, global, from);
        if (!mounted) return;
        if (accepted) return;
      }
      // Возврат в веер с лёгкой дугой.
      final to = _slotGlobalRect(card, baseSpacing, totalW);
      _liftGlobalCenter = from.center;
      await _animateOverlayTo(to, arc: true);
    } finally {
      if (mounted) {
        _clearLift();
      } else {
        _dropBusy = false;
        _removeOverlay();
        _liftedCard = null;
        _liftGlobalCenter = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = _visible;
    final allForLayout = widget.cards
        .where((c) => widget.hiddenCards?.contains(c) != true)
        .toList();
    // Для ширины веера считаем все не-hidden (включая lifted-слот-пустоту —
    // лучше сжимать веер без lifted карты).
    final layoutCards = cards;
    if (layoutCards.isEmpty && allForLayout.isEmpty) {
      return SizedBox(
        width: widget.cardSize.width,
        height: widget.cardSize.height,
      );
    }
    final baseSpacing = _spacingFor(max(layoutCards.length, 1));
    final totalW = widget.cardSize.width +
        baseSpacing * max(layoutCards.length - 1, 0);
    final height = widget.cardSize.height * 1.7;
    final arc = _arcFor(max(layoutCards.length, 1));

    return SizedBox(
      height: height,
      width: totalW + 32,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          for (int i = 0; i < layoutCards.length; i++)
            _positioned(
              i,
              layoutCards.length,
              layoutCards,
              baseSpacing,
              totalW,
              arc,
            ),
          // Поверх — жесты на весь веер (свайп + lift).
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: !widget.enabled || widget.faceDown
                  ? null
                  : (e) {
                      _pointerDown = true;
                      _panAccum = Offset.zero;
                      final box = context.findRenderObject() as RenderBox?;
                      if (box == null) return;
                      final local = box.globalToLocal(e.position);
                      final idx = _indexAtLocalX(
                        local.dx,
                        layoutCards.length,
                        baseSpacing,
                        totalW,
                      );
                      _setHover(idx);
                    },
              onPointerMove: !widget.enabled || widget.faceDown
                  ? null
                  : (e) {
                      if (!_pointerDown) return;
                      _panAccum += e.delta;
                      if (_liftedCard != null) {
                        _showOverlayAt(e.position);
                        widget.onDragPosition?.call(e.position);
                        return;
                      }
                      final box = context.findRenderObject() as RenderBox?;
                      if (box != null && layoutCards.isNotEmpty) {
                        final local = box.globalToLocal(e.position);
                        final idx = _indexAtLocalX(
                          local.dx,
                          layoutCards.length,
                          baseSpacing,
                          totalW,
                        );
                        _setHover(idx);
                      }
                      final pullUp = _panAccum.dy < -16;
                      final pullOut =
                          _panAccum.distance > 28 && _panAccum.dy < -6;
                      if ((pullUp || pullOut) &&
                          _hoverIndex != null &&
                          _hoverIndex! >= 0 &&
                          _hoverIndex! < layoutCards.length) {
                        final card = layoutCards[_hoverIndex!];
                        if (widget.legalCards == null || _isLegal(card)) {
                          _tryLift(card, e.position);
                        }
                      }
                    },
              onPointerUp: !widget.enabled || widget.faceDown
                  ? null
                  : (e) {
                      _pointerDown = false;
                      if (_liftedCard != null) {
                        unawaited(
                          _finishDrop(e.position, baseSpacing, totalW),
                        );
                        return;
                      }
                      // Короткий тап.
                      if (_panAccum.distance < 12 &&
                          _hoverIndex != null &&
                          _hoverIndex! >= 0 &&
                          _hoverIndex! < layoutCards.length) {
                        final card = layoutCards[_hoverIndex!];
                        if (_isLegal(card) || widget.legalCards == null) {
                          widget.onTap?.call(card);
                        }
                      }
                      _panAccum = Offset.zero;
                    },
              onPointerCancel: (_) {
                _pointerDown = false;
                if (_liftedCard != null) {
                  unawaited(_finishDrop(
                    _liftGlobalCenter ?? Offset.zero,
                    baseSpacing,
                    totalW,
                  ));
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
    final angle = n == 1 ? 0.0 : (i - center) * (arc / max(n - 1, 1));
    final curveY = (i - center) * (i - center) * widget.cardSize.height * 0.012;

    var extraX = 0.0;
    var extraY = 0.0;
    var scale = 1.0;
    final card = cards[i];
    final selected = _isSelected(card);
    final active = _hoverIndex == i && _liftedCard == null;

    if (_hoverIndex != null && !active && _liftedCard == null) {
      final dir = i > _hoverIndex! ? 1 : -1;
      final distance = (i - _hoverIndex!).abs();
      extraX = dir * widget.cardSize.width * (0.28 / max(distance, 1));
    }
    // Подъём только у выбранных; свайп — без подъёма.
    if (selected) {
      extraY = widget.cardSize.height * 0.22;
      scale = 1.08;
    }

    final legal = _isLegal(card);
    final isLegalContext = widget.legalCards != null;
    // Легальные карты чуть «живые» — мягкая подсветка, нелегальные приглушены.
    final showLegalGlow =
        isLegalContext && legal && !selected && !active && widget.enabled;

    Widget child = widget.faceDown
        ? CardBackWidget(size: widget.cardSize, elevated: selected)
        : PlayingCardWidget(
            card: card,
            size: widget.cardSize,
            highlighted:
                showLegalGlow || ((active || selected) && (!isLegalContext || legal)),
            dimmed: isLegalContext && !legal,
            elevated: selected || active,
          );

    // Long-press через GestureDetector без конфликта с Listener.
    child = GestureDetector(
      onLongPress: !widget.enabled || widget.faceDown || !legal
          ? null
          : () => widget.onLongPress?.call(card),
      child: child,
    );

    return AnimatedPositioned(
      key: ValueKey('fan-${card.rank.value}-${card.suit.name}'),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      left: totalW / 2 + offsetX + extraX + 16,
      bottom: extraY - curveY,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: Transform.rotate(
          angle: angle,
          alignment: Alignment.bottomCenter,
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
