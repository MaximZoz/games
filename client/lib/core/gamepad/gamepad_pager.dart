import 'package:flutter/foundation.dart';

/// Вертикальные страницы (смайлы), которые листает правый стик.
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
