import 'package:flutter/foundation.dart';

/// Вертикальные страницы (смайлы, карточки игр), которые листает правый стик.
class GamepadPagerRegistry {
  GamepadPagerRegistry._();

  static final Set<GamepadPager> _pagers = <GamepadPager>{};

  static void register(GamepadPager pager) => _pagers.add(pager);

  static void unregister(GamepadPager pager) => _pagers.remove(pager);

  static bool page(int delta) {
    for (final pager in List<GamepadPager>.from(_pagers)) {
      if (pager.page(delta)) return true;
    }
    return false;
  }

  @visibleForTesting
  static void reset() => _pagers.clear();
}

abstract class GamepadPager {
  bool page(int delta);
}

/// Следующий offset на целый экран. `null` — уже у края, без круга.
double? gamepadPageOffset({
  required double pixels,
  required double minExtent,
  required double maxExtent,
  required double viewport,
  required int direction,
}) {
  if (viewport <= 0 || direction == 0) return null;
  if (direction > 0 && pixels >= maxExtent - 1) return null;
  if (direction < 0 && pixels <= minExtent + 1) return null;
  final next = (pixels + viewport * direction).clamp(minExtent, maxExtent);
  if ((next - pixels).abs() < 1) return null;
  return next;
}
