import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/core/sfx.dart';

/// Корневые [OverlayEntry] полётов (монеты, карты, фишки).
///
/// Вставки идут в root overlay и переживают смену вкладки shell —
/// [IndexedStack] не выключает тикеры скрытой партии, поэтому без
/// проверки видимого маршрута карты остаются в чатах.
class GameFlyOverlay {
  GameFlyOverlay._();

  static final List<OverlayEntry> _entries = <OverlayEntry>[];
  static String _visiblePath = '';

  static int get debugActiveCount => _entries.length;

  @visibleForTesting
  static void debugReset() {
    dismissAll();
    _visiblePath = '';
  }

  static String get visiblePath => _visiblePath;

  /// Партия (онлайн или офлайн), не список игр и не лобби.
  static bool isGamePlayPath(String path) {
    final parts =
        path.split('?').first.split('/').where((part) => part.isNotEmpty);
    final segs = parts.toList();
    if (segs.length < 3 || segs[0] != 'games') return false;
    if (segs[2] == 'offline') return true;
    return segs.length >= 4 && segs[2] == 'game';
  }

  static bool pathsMatch(String visible, String here) {
    if (visible.isEmpty || here.isEmpty) return false;
    return visible == here;
  }

  /// Текущая вкладка/страница shell. Скрытая ветка IndexedStack не совпадёт.
  static void syncVisiblePath(String path) {
    final next = path.trim();
    if (next == _visiblePath) return;
    final leaveGame = isGamePlayPath(_visiblePath) && !isGamePlayPath(next);
    _visiblePath = next;
    if (leaveGame || !isGamePlayPath(next)) {
      dismissAll();
    }
  }

  static bool isVisibleShellRoute(BuildContext context) {
    if (!context.mounted) return false;
    try {
      final here = GoRouterState.of(context).uri.path;
      return pathsMatch(_visiblePath, here);
    } catch (_) {
      return false;
    }
  }

  /// Тики и «ваш ход» не глушим в сообщениях: партия жива в IndexedStack.
  static bool shouldKeepTurnClock(BuildContext context) {
    if (!context.mounted) return false;
    if (isVisibleShellRoute(context)) return true;
    return isMessagesPath(_visiblePath);
  }

  /// Звук полёта/фишки — и на столе, и в сообщениях (без картинки поверх чата).
  static bool shouldPlayGameSfx({BuildContext? context}) {
    if (shouldShowFlight(context: context, gameOnly: true)) return true;
    return isMessagesPath(_visiblePath);
  }

  /// [gameOnly] — карты/фишки партии. Иначе монеты тулбара на любой вкладке,
  /// но только с видимого экрана.
  static bool shouldShowFlight({
    BuildContext? context,
    bool gameOnly = false,
  }) {
    if (gameOnly && !isGamePlayPath(_visiblePath)) return false;
    if (context != null) return isVisibleShellRoute(context);
    return !gameOnly || isGamePlayPath(_visiblePath);
  }

  static OverlayEntry insert(
    OverlayState overlay,
    WidgetBuilder builder, {
    BuildContext? host,
    bool gameOnly = false,
  }) {
    late OverlayEntry entry;
    entry = OverlayEntry(builder: builder);
    if (!shouldShowFlight(context: host, gameOnly: gameOnly)) {
      return entry;
    }
    _entries.add(entry);
    overlay.insert(entry);
    return entry;
  }

  static void remove(OverlayEntry? entry) {
    if (entry == null) return;
    _entries.remove(entry);
    _safeRemove(entry);
  }

  static void dismissAll() {
    if (_entries.isEmpty) return;
    final copy = List<OverlayEntry>.of(_entries);
    _entries.clear();
    for (final e in copy) {
      _safeRemove(e);
    }
  }

  static void _safeRemove(OverlayEntry entry) {
    try {
      if (entry.mounted) {
        entry.remove();
      }
    } catch (_) {}
  }
}

bool sameNamedRoute(Route<dynamic>? a, Route<dynamic>? b) {
  final left = a?.settings.name;
  final right = b?.settings.name;
  return left != null && right != null && left == right;
}

/// Снимает полёты при смене страницы (не диалоги и не refresh того же route).
class GameFlyOverlayObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) return;
    if (sameNamedRoute(route, previousRoute)) return;
    GameFlyOverlay.dismissAll();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    GameFlyOverlay.dismissAll();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (sameNamedRoute(newRoute, oldRoute)) return;
    GameFlyOverlay.dismissAll();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (sameNamedRoute(route, previousRoute)) return;
    GameFlyOverlay.dismissAll();
  }
}
