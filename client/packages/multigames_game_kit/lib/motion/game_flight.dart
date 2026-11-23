import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'game_motion.dart';

/// Один полёт фишки через стол.
///
/// Координаты — в системе [GameFlightStage]. [from] и [to] задают рамку
/// фишки без поворота; поворот отдельно, чтобы вертикальная кость могла
/// лечь горизонтально, не сплющиваясь по дороге.
class GameFlight {
  const GameFlight({
    required this.from,
    required this.to,
    required this.builder,
    this.fromAngle = 0,
    this.toAngle = 0,
    this.lift = 18,
    this.pop = 0.12,
    this.duration = GameMotion.flight,
    this.delay = Duration.zero,
    this.curve = GameMotion.flightCurve,
  });

  final Rect from;
  final Rect to;

  /// Радианы, по часовой стрелке.
  final double fromAngle;
  final double toAngle;

  /// На сколько пикселей фишка приподнимается в середине пути.
  final double lift;

  /// Насколько она увеличивается в середине пути (0.12 = +12%).
  final double pop;

  final Duration duration;

  /// Сколько фишка ждёт на старте — для очереди из нескольких полётов.
  final Duration delay;
  final Curve curve;

  /// Рисует фишку; `t` идёт 0..1 — по нему можно перевернуть рубашку лицом.
  final Widget Function(BuildContext context, double t) builder;
}

/// Полёты фишек над столом.
///
/// Живёт в State игрового стола. Запускать полёт можно прямо из
/// `didUpdateWidget`, когда пришло новое состояние партии: фишка появится в
/// том же кадре, в котором пропала из руки, без мигания.
class GameFlightController extends ChangeNotifier {
  GameFlightController({required TickerProvider vsync}) : _vsync = vsync;

  final TickerProvider _vsync;
  final List<_ActiveFlight> _flights = <_ActiveFlight>[];
  BuildContext? _stage;
  bool _disposed = false;

  /// Сколько фишек сейчас в воздухе.
  int get activeCount => _flights.length;

  /// Рамка виджета с [key] в координатах сцены.
  ///
  /// Считается от центра, поэтому верна и для повёрнутых фишек: возвращается
  /// рамка неповёрнутой фишки вокруг того же центра. null — виджета или
  /// сцены ещё нет на экране.
  Rect? rectOf(GlobalKey key) {
    final target = key.currentContext?.findRenderObject();
    final stage = _stage?.findRenderObject();
    if (target is! RenderBox || stage is! RenderBox) return null;
    if (!target.attached || !target.hasSize || !stage.attached) return null;
    final center = target.localToGlobal(
      target.size.center(Offset.zero),
      ancestor: stage,
    );
    return Rect.fromCenter(
      center: center,
      width: target.size.width,
      height: target.size.height,
    );
  }

  /// Запустить полёт. Future завершается, когда фишка долетела
  /// (или полёт снят через [clear] / [dispose]).
  Future<void> launch(GameFlight flight) {
    if (_disposed) return Future<void>.value();
    final controller = AnimationController(
      vsync: _vsync,
      duration: flight.delay + flight.duration,
    );
    final active = _ActiveFlight(flight, controller);
    _flights.add(active);
    notifyListeners();
    controller.forward().whenCompleteOrCancel(() {
      if (_disposed) return;
      if (_flights.remove(active)) {
        controller.dispose();
        notifyListeners();
      }
      active.finish();
    });
    return active.done;
  }

  /// Снять все полёты — стол сменился целиком (новый кон).
  void clear() {
    if (_flights.isEmpty) return;
    final dropped = List<_ActiveFlight>.of(_flights);
    _flights.clear();
    for (final flight in dropped) {
      flight.controller.dispose();
      flight.finish();
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final flight in _flights) {
      flight.controller.dispose();
      flight.finish();
    }
    _flights.clear();
    super.dispose();
  }
}

/// Сцена полётов: [child] — стол, поверх него летят фишки [controller].
///
/// Фишки не участвуют в вёрстке стола и не ловят нажатия.
class GameFlightStage extends StatefulWidget {
  const GameFlightStage({
    super.key,
    required this.controller,
    required this.child,
  });

  final GameFlightController controller;
  final Widget child;

  @override
  State<GameFlightStage> createState() => _GameFlightStageState();
}

class _GameFlightStageState extends State<GameFlightStage> {
  @override
  void initState() {
    super.initState();
    widget.controller._stage = context;
  }

  @override
  void didUpdateWidget(covariant GameFlightStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller._stage == context) {
        oldWidget.controller._stage = null;
      }
      widget.controller._stage = context;
    }
  }

  @override
  void dispose() {
    if (widget.controller._stage == context) {
      widget.controller._stage = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final flights = widget.controller._flights;
                if (flights.isEmpty) return const SizedBox.shrink();
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final active in flights)
                      AnimatedBuilder(
                        key: ObjectKey(active),
                        animation: active.controller,
                        builder: (context, _) => _FlightFrame(active: active),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveFlight {
  _ActiveFlight(this.flight, this.controller);

  final GameFlight flight;
  final AnimationController controller;
  final Completer<void> _completer = Completer<void>();

  Future<void> get done => _completer.future;

  void finish() {
    if (!_completer.isCompleted) _completer.complete();
  }

  /// Прогресс самого полёта 0..1, без учёта ожидания на старте.
  double get progress {
    final total = (flight.delay + flight.duration).inMicroseconds;
    final own = flight.duration.inMicroseconds;
    if (total <= 0 || own <= 0) return 1;
    final elapsed = controller.value * total;
    return ((elapsed - flight.delay.inMicroseconds) / own).clamp(0.0, 1.0);
  }
}

class _FlightFrame extends StatelessWidget {
  const _FlightFrame({required this.active});

  final _ActiveFlight active;

  @override
  Widget build(BuildContext context) {
    final flight = active.flight;
    final t = flight.curve.transform(active.progress);
    final arc = math.sin(math.pi * t);
    final center = Offset.lerp(flight.from.center, flight.to.center, t)! -
        Offset(0, flight.lift * arc);
    final width = lerpDouble(flight.from.width, flight.to.width, t)!;
    final height = lerpDouble(flight.from.height, flight.to.height, t)!;
    final angle = lerpDouble(flight.fromAngle, flight.toAngle, t)!;
    return Positioned(
      left: center.dx - width / 2,
      top: center.dy - height / 2,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(
          scale: 1 + flight.pop * arc,
          child: flight.builder(context, t),
        ),
      ),
    );
  }
}
