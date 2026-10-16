import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:multigames_client/core/push_nav_paths.dart';

var _goTicket = 0;

/// Повтор go: первый редирект на «Игры» иногда приходит позже тапа
/// и возвращает на главную или на прошлый экран.
void deliverPushRoute({
  required void Function(String path) go,
  required String path,
  required bool Function() isAlive,
  required String Function() currentLocation,
}) {
  final ticket = ++_goTicket;
  void attempt() {
    if (!isAlive() || ticket != _goTicket) return;
    markPushOpenedRoute();
    go(path);
  }

  attempt();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!isAlive() || ticket != _goTicket) return;
    if (pushRouteReached(currentLocation(), path)) return;
    attempt();
  });
  for (final delay in const [
    Duration(milliseconds: 350),
    Duration(milliseconds: 1200),
  ]) {
    unawaited(Future<void>.delayed(delay, () {
      if (!isAlive() || ticket != _goTicket) return;
      if (pushRouteReached(currentLocation(), path)) return;
      attempt();
    }));
  }
}

/// Пуш на стол не принимает приглашение: вкладка «Лобби», карточка на виду.
Future<void> followNotificationPath({
  required void Function(String path) go,
  required String path,
  required bool Function() isAlive,
  required String Function() currentLocation,
}) async {
  deliverPushRoute(
    go: go,
    path: notificationOpenPath(path),
    isAlive: isAlive,
    currentLocation: currentLocation,
  );
}
