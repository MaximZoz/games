import 'package:flutter/material.dart';

/// Корневые [OverlayEntry] полётов (монеты, карты, фишки).
///
/// Вставки идут в root overlay и переживают смену вкладки shell —
/// без реестра иконка остаётся на другой странице.
class GameFlyOverlay {
  GameFlyOverlay._();

  static final List<OverlayEntry> _entries = <OverlayEntry>[];

  static int get debugActiveCount => _entries.length;

  static OverlayEntry insert(OverlayState overlay, WidgetBuilder builder) {
    late OverlayEntry entry;
    entry = OverlayEntry(builder: builder);
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
