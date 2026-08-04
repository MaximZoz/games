import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';

/// Веер карт игрока.
///
/// - Тап: выбор / снятие выбора (для мульти-подкида одного ранга).
/// - Свободный драг в любую сторону; при отпускании — [onDrop] или возврат в веер.
/// - Чем больше карт, тем плотнее и сильнее дуга.
class CardFan extends StatefulWidget {
  const CardFan({
    super.key,
    required this.cards,
    required this.cardSize,
    this.enabled = true,
    this.legalCards,
    this.selectedCards,
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

  /// Выбранные для мульти-подкида карты.
  final Set<PlayingCard>? selectedCards;

  /// Короткий тап по карте.
  final ValueChanged<PlayingCard>? onTap;

  /// Долгое нажатие — мульти-выбор для подкида.
  final ValueChanged<PlayingCard>? onLongPress;

  /// Отпускание после драга. Вернуть `true`, если карта принята (улетела на стол).
  /// [from] — глобальный rect карты в момент отпускания.
  final Future<bool> Function(
    PlayingCard card,
    Offset globalPosition,
    Rect from,
  )? onDrop;

  /// Какая карта сейчас под пальцем / наведена (для подсветки целей на столе).
  final ValueChanged<PlayingCard?>? onActiveChanged;

  final bool faceDown;

  /// Угол дуги веера (рад на весь веер). Null — подобрать по числу карт.
  final double? arc;
  final double? spacing;

  @override
  State<CardFan> createState() => _CardFanState();
}

class _CardFanState extends State<CardFan> with SingleTickerProviderStateMixin {
  int? _hoverIndex;
  int? _dragIndex;
  Offset _dragOffset = Offset.zero;
  bool _dragging = false;
  bool _dropBusy = false;

  late final AnimationController _returnCtrl;
  Offset _returnFrom = Offset.zero;

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
    final card = index == null || index < 0 || index >= widget.cards.length
        ? null
        : widget.cards[index];
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
    if (_dragIndex == null) _emitActive(index);
  }

  void _clearInteraction() {
    setState(() {
      _dragIndex = null;
      _dragging = false;
      _dragOffset = Offset.zero;
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

  Rect _cardGlobalRect(int i, double baseSpacing, double totalW, double arc) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return Rect.fromLTWH(0, 0, widget.cardSize.width, widget.cardSize.height);
    }
    final n = widget.cards.length;
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
    double arc,
    bool canPlay,
  ) {
    if (_dropBusy) return;
    _dropBusy = true;
    final from = _cardGlobalRect(i, baseSpacing, totalW, arc);
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
    if (widget.cards.isEmpty) {
      return SizedBox(
        width: widget.cardSize.width,
        height: widget.cardSize.height,
      );
    }
    final n = widget.cards.length;
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
            _positioned(i, n, baseSpacing, totalW, arc),
        ],
      ),
    );
  }

  Widget _positioned(
    int i,
    int n,
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
    final card = widget.cards[i];
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
      if (_dragIndex == i && _dragging) {
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
        if (!widget.enabled || _dragging) return;
        _setHover(i);
      },
      onExit: (_) {
        if (!widget.enabled || _dragging) return;
        if (_hoverIndex == i) _setHover(null);
      },
      cursor: canPlay ? SystemMouseCursors.grab : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: !canPlay
            ? null
            : () {
                if (_dragging || _dropBusy) return;
                widget.onTap?.call(card);
              },
        onLongPress: !canPlay
            ? null
            : () {
                if (_dragging || _dropBusy) return;
                widget.onLongPress?.call(card);
              },
        onPanStart: !canPlay
            ? null
            : (_) {
                _returnCtrl.stop();
                setState(() {
                  _dragIndex = i;
                  _hoverIndex = i;
                  _dragOffset = Offset.zero;
                  _dragging = true;
                  _dropBusy = false;
                });
                _emitActive(i);
              },
        onPanUpdate: !canPlay
            ? null
            : (details) {
                if (_dragIndex != i) return;
                setState(() {
                  _dragOffset += details.delta;
                });
              },
        onPanEnd: !widget.enabled || widget.faceDown
            ? null
            : (details) {
                if (_dragIndex != i) return;
                // Короткое движение — как тап (иначе pan «съедает» onTap).
                if (_dragOffset.distance < 14) {
                  final tapped = card;
                  _clearInteraction();
                  if (canPlay) widget.onTap?.call(tapped);
                  return;
                }
                _finishDrop(
                  i,
                  card,
                  details.globalPosition,
                  baseSpacing,
                  totalW,
                  arc,
                  canPlay,
                );
              },
        onPanCancel: () {
          if (_dragIndex == i) {
            unawaited(_animateReturn());
          }
        },
        child: child,
      ),
    );

    final dragDx = (_dragIndex == i) ? _dragOffset.dx : 0.0;
    final dragDy = (_dragIndex == i) ? _dragOffset.dy : 0.0;

    return AnimatedPositioned(
      key: ValueKey('fan-$i-${card.rank.value}-${card.suit.name}'),
      duration: _dragIndex == i
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
          angle: active && _dragging ? 0 : angle,
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
