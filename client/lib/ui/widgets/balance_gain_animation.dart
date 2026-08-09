import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';

/// Глобальные ключи иконок номиналов в тулбаре — цель полёта монеты.
final toolbarCoinKeysProvider = Provider<Map<CoinType, GlobalKey>>((ref) {
  return {
    for (final type in CoinType.values) type: GlobalKey(debugLabel: 'toolbar_$type'),
  };
});

class BalanceGainState {
  const BalanceGainState({
    this.displayBronze,
    this.forceShow = const <CoinType>{},
  });

  /// Пока не null — тулбар рисует этот баланс вместо auth.
  final int? displayBronze;
  final Set<CoinType> forceShow;

  bool get active => displayBronze != null;

  BalanceGainState copyWith({
    int? displayBronze,
    Set<CoinType>? forceShow,
    bool clearDisplay = false,
  }) {
    return BalanceGainState(
      displayBronze: clearDisplay ? null : (displayBronze ?? this.displayBronze),
      forceShow: forceShow ?? this.forceShow,
    );
  }
}

class BalanceGainController extends StateNotifier<BalanceGainState> {
  BalanceGainController() : super(const BalanceGainState());

  Future<void>? _queue;

  Future<void> enqueue(Future<void> Function() job) {
    final previous = _queue;
    final current = () async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {}
      }
      try {
        await job();
      } catch (_) {
        // Не оставляем тулбар залоченным после сбоя анимации.
        end();
        rethrow;
      }
    }();
    _queue = current;
    return current;
  }

  void begin({required int fromBronze, required Set<CoinType> forceShow}) {
    state = BalanceGainState(displayBronze: fromBronze, forceShow: forceShow);
  }

  void setDisplay(int bronze) {
    // Новый state всегда — чтобы Riverpod гарантированно перестроил тулбар.
    state = BalanceGainState(displayBronze: bronze, forceShow: state.forceShow);
  }

  void end() {
    if (state.displayBronze == null && state.forceShow.isEmpty) return;
    state = const BalanceGainState();
  }
}

final balanceGainProvider =
    StateNotifierProvider<BalanceGainController, BalanceGainState>((ref) {
  return BalanceGainController();
});

BigInt denominationOf(CoinType type, int bronze) {
  final (diamond, gold, silver, bronzeRest) = parseBalance(bronze);
  return switch (type) {
    CoinType.diamond => diamond,
    CoinType.gold => gold,
    CoinType.silver => silver,
    CoinType.bronze => bronzeRest,
  };
}

/// Номиналы, которых не было в [fromBronze], но появятся в [toBronze].
Set<CoinType> emergingDenominations(int fromBronze, int toBronze) {
  final out = <CoinType>{};
  for (final type in CoinType.values) {
    if (denominationOf(type, fromBronze) == BigInt.zero &&
        denominationOf(type, toBronze) > BigInt.zero) {
      out.add(type);
    }
  }
  return out;
}

Rect? globalRectOfKey(GlobalKey? key) {
  if (key == null) return null;
  final ctx = key.currentContext;
  if (ctx == null || !ctx.mounted) return null;
  final box = ctx.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize || !box.attached) return null;
  final topLeft = box.localToGlobal(Offset.zero);
  return topLeft & box.size;
}

Offset _centerOf(Rect rect) => rect.center;

/// Зафиксировать отображаемый баланс до обновления auth, чтобы не было скачка.
void lockBalanceDisplay({
  required WidgetRef ref,
  required int fromBronze,
  required int toBronze,
  int? rewardBronze,
}) {
  final delta = rewardBronze ?? (toBronze - fromBronze);
  final flyType = rewardCoinType(delta > 0 ? delta : 1);
  ref.read(balanceGainProvider.notifier).begin(
        fromBronze: fromBronze,
        forceShow: {
          ...emergingDenominations(fromBronze, toBronze),
          if (delta > 0 && denominationOf(flyType, fromBronze) == BigInt.zero)
            flyType,
        },
      );
}

/// Анимация пополнения: полёт монеты из карточки в тулбар + счётчик баланса.
///
/// [skipApply] — если баланс уже обновлён (например, после `refresh()`).
/// Перед [skipApply]/вызовами с обновлением auth вызовите [lockBalanceDisplay].
Future<void> playBalanceGain({
  required WidgetRef ref,
  required BuildContext context,
  required int newBalanceBronze,
  int? fromBronze,
  int? rewardBronze,
  GlobalKey? sourceKey,
  Rect? sourceRect,
  bool skipApply = false,
}) {
  final controller = ref.read(balanceGainProvider.notifier);
  return controller.enqueue(() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final from = fromBronze ??
        ref.read(balanceGainProvider).displayBronze ??
        user.balanceBronze;
    final to = newBalanceBronze;
    if (to <= from) {
      controller.end();
      if (!skipApply) {
        await ref.read(authStateProvider.notifier).applyBalance(to);
      }
      return;
    }

    final delta = rewardBronze ?? (to - from);
    final flyType = rewardCoinType(delta);
    final forceShow = {
      ...emergingDenominations(from, to),
      if (denominationOf(flyType, from) == BigInt.zero) flyType,
    };

    // Всегда держим тулбар на [from], пока не дорисуем счётчик —
    // даже если auth уже обновлён.
    controller.begin(fromBronze: from, forceShow: forceShow);

    try {
      if (!skipApply) {
        await ref.read(authStateProvider.notifier).applyBalance(to);
      }

      // Дать тулбару вставить новую монету и измерить цель.
      await WidgetsBinding.instance.endOfFrame;
      if (!context.mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      if (!context.mounted) return;

      final coinKeys = ref.read(toolbarCoinKeysProvider);
      var targetRect = globalRectOfKey(coinKeys[flyType]);
      // Фоллбек: любая видимая монета / центр чипа.
      if (targetRect == null) {
        for (final type in CoinType.values) {
          targetRect = globalRectOfKey(coinKeys[type]);
          if (targetRect != null) break;
        }
      }

      final startRect = sourceRect ?? globalRectOfKey(sourceKey);
      if (startRect != null && targetRect != null && context.mounted) {
        // Сначала полёт; пересчёт — строго после прилёта (без колбэка в тикере).
        await _flyCoin(
          context: context,
          from: _centerOf(startRect),
          to: _centerOf(targetRect),
          coinType: flyType,
          size: math.max(18, startRect.shortestSide.clamp(16, 28)),
        );
      }
      if (!context.mounted) return;
      await _countBalance(controller: controller, from: from, to: to);
    } finally {
      // Снимаем лок — тулбар показывает актуальный auth-баланс.
      controller.end();
    }
  });
}

/// Анимация списания: полёт монеты из тулбара в чип «−N» + счётчик вниз.
///
/// Ставка уже списана на старте партии — [toBronze] = актуальный баланс,
/// [fromBronze] = to + lost (визуально «снимаем» ставку в конце).
Future<void> playBalanceLoss({
  required WidgetRef ref,
  required BuildContext context,
  required int fromBronze,
  required int toBronze,
  int? lostBronze,
  GlobalKey? targetKey,
  Rect? targetRect,
}) {
  final controller = ref.read(balanceGainProvider.notifier);
  return controller.enqueue(() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final from = fromBronze;
    final to = toBronze;
    if (to >= from) {
      controller.end();
      return;
    }

    final delta = (lostBronze ?? (from - to)).abs();
    if (delta <= 0) {
      controller.end();
      return;
    }
    final flyType = rewardCoinType(delta);
    final forceShow = {
      ...emergingDenominations(to, from),
      if (denominationOf(flyType, to) == BigInt.zero) flyType,
    };

    controller.begin(fromBronze: from, forceShow: forceShow);

    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!context.mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      if (!context.mounted) return;

      final coinKeys = ref.read(toolbarCoinKeysProvider);
      var startRect = globalRectOfKey(coinKeys[flyType]);
      if (startRect == null) {
        for (final type in CoinType.values) {
          startRect = globalRectOfKey(coinKeys[type]);
          if (startRect != null) break;
        }
      }

      final endRect = targetRect ?? globalRectOfKey(targetKey);
      if (startRect != null && endRect != null && context.mounted) {
        await _flyCoin(
          context: context,
          from: _centerOf(startRect),
          to: _centerOf(endRect),
          coinType: flyType,
          size: math.max(18, endRect.shortestSide.clamp(16, 28)),
        );
      }
      if (!context.mounted) return;
      await _countBalance(controller: controller, from: from, to: to);
    } finally {
      controller.end();
    }
  });
}

Future<void> _countBalance({
  required BalanceGainController controller,
  required int from,
  required int to,
}) async {
  final delta = to - from;
  final ms = (480 + delta.abs() * 2).clamp(520, 1400);
  final sw = Stopwatch()..start();
  while (sw.elapsedMilliseconds < ms) {
    final t = (sw.elapsedMilliseconds / ms).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(t);
    controller.setDisplay((from + (to - from) * eased).round());
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }
  controller.setDisplay(to);
}

Future<void> _flyCoin({
  required BuildContext context,
  required Offset from,
  required Offset to,
  required CoinType coinType,
  required double size,
  VoidCallback? onArrived,
}) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final completer = Completer<void>();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _FlyingCoinLayer(
      from: from,
      to: to,
      coinType: coinType,
      size: size,
      onArrived: onArrived,
      onDone: () {
        entry.remove();
        if (!completer.isCompleted) completer.complete();
      },
    ),
  );
  overlay.insert(entry);
  return completer.future;
}

class _FlyingCoinLayer extends StatefulWidget {
  const _FlyingCoinLayer({
    required this.from,
    required this.to,
    required this.coinType,
    required this.size,
    required this.onDone,
    this.onArrived,
  });

  final Offset from;
  final Offset to;
  final CoinType coinType;
  final double size;
  final VoidCallback onDone;
  final VoidCallback? onArrived;

  @override
  State<_FlyingCoinLayer> createState() => _FlyingCoinLayerState();
}

class _FlyingCoinLayerState extends State<_FlyingCoinLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool _arrivedNotified = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _t = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.85), weight: 65),
    ]).animate(_t);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 85),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(_t);
    // ~85% — монета у цели, начинается fade; с этого момента пересчёт.
    _controller.addListener(() {
      if (_arrivedNotified || _controller.value < 0.85) return;
      _arrivedNotified = true;
      widget.onArrived?.call();
    });
    _controller.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _t.value;
            // Лёгкая дуга вверх.
            final mid = Offset(
              (widget.from.dx + widget.to.dx) / 2,
              math.min(widget.from.dy, widget.to.dy) - 48,
            );
            final p1 = Offset.lerp(widget.from, mid, t)!;
            final p2 = Offset.lerp(mid, widget.to, t)!;
            final pos = Offset.lerp(p1, p2, t)!;
            return Stack(
              children: [
                Positioned(
                  left: pos.dx - widget.size / 2,
                  top: pos.dy - widget.size / 2,
                  child: Opacity(
                    opacity: _opacity.value,
                    child: Transform.scale(
                      scale: _scale.value,
                      child: child,
                    ),
                  ),
                ),
              ],
            );
          },
          child: CoinIcon(
            coinType: widget.coinType,
            size: widget.size,
            showBorder: true,
            animate: false,
          ),
        ),
      ),
    );
  }
}
