import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';

/// Веер карт игрока.
///
/// - Водить пальцем по вееру — подсвечивается карта под пальцем.
/// - Тянуть вверх/в сторону — карта вытягивается и следует за пальцем.
/// - Отпускание: [onDrop] или возврат в веер.
/// - Чем больше карт, тем плотнее и сильнее дуга.
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
    this.faceDown = false,
    this.arc,
    this.spacing,
  });

  final List<PlayingCard> cards;
  final Size cardSize;
  final bool enabled;
  final Set<PlayingCard>? legalCards;
  final Set<PlayingCard>? selectedCards;

  /// Карты, которые сейчас летят (не рисуем в веере — без «двойника»).
  final Set<PlayingCard>? hiddenCards;

  final ValueChanged<PlayingCard>? onTap;
  final ValueChanged<PlayingCard>? onLongPress;
  final Future<bool> Function(
    PlayingCard card,
    Offset globalPosition,
    Rect from,
  )? onDrop;
  final ValueChanged<PlayingCard?>? onActiveChanged;
  final bool faceDown;
  final double? arc;
  final double? spacing;

  @override
  State<CardFan> createState() => _CardFanState();
}

class _CardFanState extends State<CardFan> with SingleTickerProviderStateMixin {
  int? _hoverIndex;
  int? _dragIndex;
  Offset _dragOffset = Offset.zero;
  bool _lifted = false;
  bool _dropBusy = false;
  Offset _panAccum = Offset.zero;

  late final AnimationController _returnCtrl;
  Offset _returnFrom = Offset.zero;

  List<PlayingCard> get _visible {
    final hidden = widget.hiddenCards;
    if (hidden == null || hidden.isEmpty) return widget.cards;
    return widget.cards.where((c) => !hidden.contains(c)).toList();
  }

  @override
  void initState() {
    super.initState();
    _returnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
        final t = Curves.easeOutCubic.transform(_returnCtrl.value);
        setState(() {
          _dragOffset = Offset.lerp(_returnFrom, Offset.zero, t)!;
        });
      });
  }

  @override
  void dispose() {
    _returnCtrl.dispose();
    super.dispose();
  }

  void _emitActive(int? index) {
    final cards = _visible;
    final card = index == null || index < 0 || index >= cards.length
        ? null
        : cards[index];
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
    if (!_lifted) _emitActive(index);
  }

  void _clearInteraction() {
    setState(() {
      _dragIndex = null;
      _lifted = false;
      _dragOffset = Offset.zero;
      _panAccum = Offset.zero;
      _hoverIndex = null;
      _dropBusy = false;
    });
    widget.onActiveChanged?.call(null);
  }

  Future<void> _animateReturn() async {
    _returnFrom = _dragOffset;
    await _returnCtrl.forward(from: 0);
    if (!mounted) return;
    _clearInteraction();
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

  Rect _cardGlobalRect(int i, double baseSpacing, double totalW) {
    final box = context.findRenderObject() as RenderBox?;
    final cards = _visible;
    if (box == null || !box.hasSize || i < 0 || i >= cards.length) {
      return Rect.fromLTWH(0, 0, widget.cardSize.width, widget.cardSize.height);
    }
    final n = cards.length;
    final center = (n - 1) / 2;
    final offsetX = (i - center) * baseSpacing;
    final curveY = (i - center) * (i - center) * widget.cardSize.height * 0.012;
    final left = totalW / 2 + offsetX + 16 + _dragOffset.dx;
    final top =
        box.size.height - widget.cardSize.height - curveY + _dragOffset.dy;
    final origin = box.localToGlobal(Offset(left, top));
    return Rect.fromLTWH(
      origin.dx,
      origin.dy,
      widget.cardSize.width,
      widget.cardSize.height,
    );
  }

  void _finishDrop(
    int i,
    PlayingCard card,
    Offset global,
    double baseSpacing,
    double totalW,
    bool canPlay,
  ) {
    if (_dropBusy) return;
    _dropBusy = true;
    final from = _cardGlobalRect(i, baseSpacing, totalW);
    final drop = widget.onDrop;
    if (drop != null && canPlay) {
      unawaited(drop(card, global, from).then((accepted) async {
        if (!mounted) return;
        if (accepted) {
          _clearInteraction();
        } else {
          await _animateReturn();
        }
      }));
    } else {
      unawaited(_animateReturn());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = _visible;
    if (cards.isEmpty) {
      return SizedBox(
        width: widget.cardSize.width,
        height: widget.cardSize.height,
      );
    }
    final n = cards.length;
    final baseSpacing = _spacingFor(n);
    final totalW = widget.cardSize.width + baseSpacing * (n - 1);
    final height = widget.cardSize.height * 1.7;
    final arc = _arcFor(n);

    return SizedBox(
      height: height,
      width: totalW + 32,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          for (int i = 0; i < n; i++)
            _positioned(i, n, cards, baseSpacing, totalW, arc),
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
    final activeIndex = _dragIndex ?? _hoverIndex;
    final active = activeIndex != null && i == activeIndex;

    if (activeIndex != null && !active) {
      final dir = i > activeIndex ? 1 : -1;
      final distance = (i - activeIndex).abs();
      extraX = dir * widget.cardSize.width * (0.28 / max(distance, 1));
    }
    if (selected && !active) {
      extraY = widget.cardSize.height * 0.18;
      scale = 1.05;
    }
    if (active) {
      if (_lifted && _dragIndex == i) {
        extraY = 0;
        scale = 1.12;
      } else {
        extraY = widget.cardSize.height * 0.22;
        scale = 1.06;
      }
    }

    final legal = _isLegal(card);
    final isLegalContext = widget.legalCards != null;
    final canPlay = widget.enabled && !widget.faceDown && legal;

    Widget child = widget.faceDown
        ? CardBackWidget(size: widget.cardSize, elevated: active || selected)
        : PlayingCardWidget(
            card: card,
            size: widget.cardSize,
            highlighted: (active || selected) && (!isLegalContext || legal),
            dimmed: isLegalContext && !legal,
            elevated: active || selected,
          );

    child = MouseRegion(
      onEnter: (_) {
        if (!widget.enabled || _lifted) return;
        _setHover(i);
      },
      onExit: (_) {
        if (!widget.enabled || _lifted) return;
        if (_hoverIndex == i) _setHover(null);
      },
      cursor: canPlay ? SystemMouseCursors.grab : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: !canPlay
            ? null
            : () {
                if (_lifted || _dropBusy) return;
                widget.onTap?.call(card);
              },
        onLongPress: !canPlay
            ? null
            : () {
                if (_lifted || _dropBusy) return;
                widget.onLongPress?.call(card);
              },
        onPanStart: !widget.enabled || widget.faceDown
            ? null
            : (_) {
                _returnCtrl.stop();
                setState(() {
                  _dragIndex = i;
                  _hoverIndex = i;
                  _dragOffset = Offset.zero;
                  _panAccum = Offset.zero;
                  _lifted = false;
                  _dropBusy = false;
                });
                _emitActive(i);
              },
        onPanUpdate: !widget.enabled || widget.faceDown
            ? null
            : (details) {
                if (_dragIndex == null && _hoverIndex == null) return;
                _panAccum += details.delta;

                if (!_lifted) {
                  // Свайп по вееру — выбираем карту под пальцем.
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null) {
                    final local = box.globalToLocal(details.globalPosition);
                    final idx = _indexAtLocalX(
                      local.dx,
                      n,
                      baseSpacing,
                      totalW,
                    );
                    if (idx != _hoverIndex || idx != _dragIndex) {
                      setState(() {
                        _hoverIndex = idx;
                        _dragIndex = idx;
                      });
                      _emitActive(idx);
                    }
                  }
                  // Тянем вверх/наружу — фиксируем карту и свободный драг.
                  final pullUp = _panAccum.dy < -18;
                  final pullOut = _panAccum.distance > 36 &&
                      _panAccum.dy < -8;
                  if (pullUp || pullOut) {
                    setState(() {
                      _lifted = true;
                      _dragOffset = _panAccum;
                    });
                  }
                  return;
                }

                setState(() {
                  _dragOffset += details.delta;
                });
              },
        onPanEnd: !widget.enabled || widget.faceDown
            ? null
            : (details) {
                final idx = _dragIndex ?? _hoverIndex;
                if (idx == null || idx < 0 || idx >= cards.length) {
                  _clearInteraction();
                  return;
                }
                final dragged = cards[idx];
                final can = widget.enabled &&
                    !widget.faceDown &&
                    _isLegal(dragged);

                if (!_lifted || _dragOffset.distance < 14) {
                  final tapped = dragged;
                  _clearInteraction();
                  if (can) widget.onTap?.call(tapped);
                  return;
                }
                _finishDrop(
                  idx,
                  dragged,
                  details.globalPosition,
                  baseSpacing,
                  totalW,
                  can,
                );
              },
        onPanCancel: () {
          if (_lifted) {
            unawaited(_animateReturn());
          } else {
            _clearInteraction();
          }
        },
        child: child,
      ),
    );

    final dragDx = (_lifted && _dragIndex == i) ? _dragOffset.dx : 0.0;
    final dragDy = (_lifted && _dragIndex == i) ? _dragOffset.dy : 0.0;

    return AnimatedPositioned(
      key: ValueKey('fan-$i-${card.rank.value}-${card.suit.name}'),
      duration: (_lifted && _dragIndex == i)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      left: totalW / 2 + offsetX + extraX + 16 + dragDx,
      bottom: extraY - curveY - dragDy,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: Transform.rotate(
          angle: active && _lifted ? 0 : angle,
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
