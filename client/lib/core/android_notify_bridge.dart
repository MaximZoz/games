import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/android_notify_map.dart';
import 'package:multigames_client/core/local_notify.dart';
import 'package:multigames_client/core/push_nav_paths.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/core/web_push_provider.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';

/// Локальные уведомления на Android и iPhone, пока приложение в фоне (WS ещё жив).
/// Как PWA: баннер не рисуем в момент открытия приложения.
final androidNotifyBridgeProvider = Provider<void>((ref) {
  if (kIsWeb || !localNotificationsSupported()) return;

  final lifecycle = _NotifyLifecycle();
  WidgetsBinding.instance.addObserver(lifecycle);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(lifecycle));

  void syncSession(AuthUser? user) {
    if (user == null) {
      setLocalNotifySessionActive(false);
      unawaited(cancelAllLocalNotifications());
      return;
    }
    setLocalNotifySessionActive(true);
    if (ref.read(webPushEnabledProvider)) {
      unawaited(requestLocalNotificationPermission());
    }
  }

  syncSession(ref.read(authStateProvider).valueOrNull);
  ref.listen<AsyncValue<AuthUser?>>(authStateProvider, (prev, next) {
    syncSession(next.valueOrNull);
  });
  ref.listen<bool>(webPushEnabledProvider, (prev, next) {
    if (next && ref.read(authStateProvider).valueOrNull != null) {
      unawaited(requestLocalNotificationPermission());
    }
  });

  ref.listen<AsyncValue<Map<String, dynamic>>>(realtimeEventsProvider,
      (_, next) {
    if (!shouldShowPhoneTrayBanner(
      lifecycle.state,
      ios: defaultTargetPlatform == TargetPlatform.iOS,
    )) {
      return;
    }
    if (!ref.read(webPushEnabledProvider)) return;
    final me = ref.read(authStateProvider).valueOrNull;
    if (me == null) return;
    final event = next.valueOrNull;
    if (event == null) return;
    final cats = ref.read(webPushCategoriesProvider);
    final mapped = mapAndroidNotifyEvent(event, meId: me.id, cats: cats);
    if (mapped == null) return;
    if (pathsMatch(ref.read(currentRoutePathProvider), mapped.url)) return;
    showLocalNotification(
      title: mapped.title,
      body: mapped.body,
      tag: mapped.tag,
      id: notificationIdForTag(mapped.tag),
      payload: encodeNotificationPayload(
        url: mapped.url,
        tag: mapped.tag,
        chatId: mapped.chatId,
      ),
    );
  });
});

class _NotifyLifecycle with WidgetsBindingObserver {
  AppLifecycleState state = AppLifecycleState.resumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState next) {
    state = next;
  }
}
