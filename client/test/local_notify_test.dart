import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/local_notify.dart';

void main() {
  test('в flutter test локальные уведомления выключены и не падают', () async {
    expect(localNotificationsSupported(), isFalse);
    await initLocalNotifications();
    setLocalNotifySessionActive(true);
    await showLocalNotification(title: 't', body: 'b');
    await cancelAllLocalNotifications();
    expect(await requestLocalNotificationPermission(), isFalse);
  });
}
