import 'dart:io' show Platform;

import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:multigames_client/core/push_nav_paths.dart';

const _pushChannel = MethodChannel('com.zozugames/push');

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
var _ready = false;
var _sessionActive = false;
void Function(String payload)? _tapHandler;
String? _launchPayload;

bool _inFlutterTest() => Platform.environment.containsKey('FLUTTER_TEST');

/// Телефон (Android и iOS). VM-тесты и desktop плагин не регистрируют.
bool localNotificationsSupported() =>
    (Platform.isAndroid || Platform.isIOS) && !_inFlutterTest();

void _handleResponse(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.trim().isEmpty) return;
  final handler = _tapHandler;
  if (handler != null) {
    handler(payload);
  } else {
    _launchPayload = payload;
  }
}

@pragma('vm:entry-point')
void localNotificationTapBackground(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.trim().isEmpty) return;
  _launchPayload = payload;
}

void setLocalNotificationTapHandler(void Function(String payload)? handler) {
  _tapHandler = handler;
}

Future<String?> consumeLocalNotificationLaunchPayload() async {
  final pending = _launchPayload;
  if (pending != null && pending.trim().isNotEmpty) {
    _launchPayload = null;
    return pending;
  }
  if (!localNotificationsSupported()) return null;
  if (!_ready) await initLocalNotifications();
  if (!_ready) return null;
  try {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      return details?.notificationResponse?.payload;
    }
  } catch (_) {}
  return null;
}

Future<void> initLocalNotifications() async {
  if (_ready || !localNotificationsSupported()) return;
  try {
    const android = AndroidInitializationSettings('@drawable/ic_stat_notify');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse: localNotificationTapBackground,
    );
    const channel = AndroidNotificationChannel(
      'zozu_events',
      'Zozu Games',
      description: 'Чаты, друзья, игры и награды',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    _ready = true;
  } catch (_) {
    // Нет platform instance (тесты / desktop) — локальные баннеры пропускаем.
  }
}

Future<bool> requestLocalNotificationPermission() async {
  if (!localNotificationsSupported()) return false;
  await initLocalNotifications();
  if (!_ready) return false;
  try {
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  } catch (_) {
    return false;
  }
}

void setLocalNotifySessionActive(bool active) {
  _sessionActive = active;
}

Future<void> cancelAllLocalNotifications() async {
  if (!localNotificationsSupported()) return;
  if (!_ready) await initLocalNotifications();
  if (!_ready) return;
  try {
    await _plugin.cancelAll();
    await _iosClearDelivered(all: true);
  } catch (_) {}
}

Future<void> cancelLocalNotificationsForTag(String tag) async {
  final t = tag.trim();
  if (t.isEmpty || !localNotificationsSupported()) return;
  if (!_ready) await initLocalNotifications();
  if (!_ready) return;
  final id = notificationIdForTag(t);
  try {
    await _plugin.cancel(id, tag: t);
  } catch (_) {}
  try {
    await _plugin.cancel(0, tag: t);
  } catch (_) {}
  await _iosClearDelivered(tag: t);
}

Future<void> cancelLocalNotificationsForPath(String path, {String? tag}) async {
  final resolved = (tag != null && tag.trim().isNotEmpty)
      ? tag.trim()
      : tagFromPath(path);
  if (resolved == null || resolved.isEmpty) return;
  await cancelLocalNotificationsForTag(resolved);
}

Future<void> showLocalNotification({
  required String title,
  required String body,
  String? payload,
  String? tag,
  int? id,
}) async {
  if (!_sessionActive || !localNotificationsSupported()) return;
  if (!_ready) await initLocalNotifications();
  if (!_ready) return;
  final resolvedTag = (tag != null && tag.trim().isNotEmpty) ? tag.trim() : null;
  final notifyId = id ??
      (resolvedTag != null
          ? notificationIdForTag(resolvedTag)
          : DateTime.now().millisecondsSinceEpoch.remainder(1 << 31));
  final details = NotificationDetails(
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
      presentBadge: true,
      threadIdentifier: resolvedTag,
    ),
    android: AndroidNotificationDetails(
      'zozu_events',
      'Zozu Games',
      channelDescription: 'Чаты, друзья, игры и награды',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_stat_notify',
      color: const Color(0xFF6366F1),
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(body, contentTitle: title),
      tag: resolvedTag,
      autoCancel: true,
    ),
  );
  try {
    await _plugin.show(
      notifyId,
      title,
      body,
      details,
      payload: payload,
    );
  } catch (_) {}
}

Future<void> _iosClearDelivered({
  String? tag,
  String? prefix,
  bool all = false,
  List<String> keep = const [],
  List<String> tags = const [],
}) async {
  if (!Platform.isIOS || !localNotificationsSupported()) return;
  try {
    await _pushChannel.invokeMethod<void>('clearDelivered', {
      'tag': tag ?? '',
      'prefix': prefix ?? '',
      'all': all,
      'keep': keep,
      'tags': tags,
    });
  } catch (_) {}
}

Future<void> _iosSetBadge(int count) async {
  if (!Platform.isIOS || !localNotificationsSupported()) return;
  try {
    await _pushChannel.invokeMethod<void>('setBadge', {
      'count': count < 0 ? 0 : count,
    });
  } catch (_) {}
}

/// Снимает с iPhone баннеры, которых в приложении уже нет, и ставит бейдж.
/// [clearAll] — выход из аккаунта: вся шторка и ноль на иконке.
/// Ноль в [badge] сам по себе шторку не трогает: список чатов мог ещё не прийти.
Future<void> syncIosNotificationCenter({
  required int badge,
  bool applyBadge = false,
  bool clearChatThreads = false,
  List<String> keepChatTags = const [],
  List<String> dropChatTags = const [],
  bool clearFriendRequests = false,
  bool clearGameInvites = false,
  List<String> keepInviteTags = const [],
  bool clearAll = false,
}) async {
  if (!Platform.isIOS || !localNotificationsSupported()) return;
  try {
    if (clearAll) {
      if (_ready) await _plugin.cancelAll();
      await _iosClearDelivered(all: true);
      return;
    }
    if (clearChatThreads) {
      await _iosClearDelivered(prefix: 'chat_', keep: keepChatTags);
    } else if (dropChatTags.isNotEmpty) {
      await _iosClearDelivered(tags: dropChatTags);
    }
    if (clearFriendRequests) {
      await _iosClearDelivered(tag: 'friend_request');
    }
    if (clearGameInvites) {
      await _iosClearDelivered(prefix: 'game_invite', keep: keepInviteTags);
    }
    if (applyBadge) await _iosSetBadge(badge);
  } catch (_) {}
}
