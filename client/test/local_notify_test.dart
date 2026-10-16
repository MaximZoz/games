import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/local_notify.dart';
import 'package:multigames_client/core/push_notification_nav_io.dart';

void main() {
  test('в flutter test локальные уведомления выключены и не падают', () async {
    expect(localNotificationsSupported(), isFalse);
    await initLocalNotifications();
    setLocalNotifySessionActive(true);
    await showLocalNotification(title: 't', body: 'b', tag: 'chat_x');
    await cancelLocalNotificationsForTag('chat_x');
    await cancelLocalNotificationsForPath('/chats/x');
    await cancelAllLocalNotifications();
    await syncIosNotificationCenter(
      badge: 0,
      applyBadge: true,
      clearChatThreads: true,
      keepChatTags: const ['chat_keep'],
    );
    setLocalNotificationTapHandler((_) {});
    expect(await consumeLocalNotificationLaunchPayload(), isNull);
    expect(await requestLocalNotificationPermission(), isFalse);
  });

  test('Android push-nav в flutter test не трогает плагины', () {
    installPushNotificationNavigation((_) {});
    reportPushSwActiveRoute('/chats/abc');
    clearPushNotificationsForChat('abc');
    uninstallPushNotificationNavigation();
  });
}
