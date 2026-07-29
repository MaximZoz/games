/// Stub для non-web платформ.
bool browserPushSupported() => false;

bool browserPushStandalone() => false;

String browserNotificationPermission() => 'denied';

Future<String> requestBrowserNotificationPermission() async => 'denied';

class BrowserPushSubscriptionData {
  const BrowserPushSubscriptionData({
    required this.endpoint,
    required this.p256dh,
    required this.auth,
  });

  final String endpoint;
  final String p256dh;
  final String auth;

  bool get isApple => false;
}

Future<BrowserPushSubscriptionData> subscribeBrowserPush({
  required String vapidPublicKey,
  bool forceRefresh = true,
}) async {
  throw UnsupportedError('Web Push только в браузере / PWA');
}

Future<String?> currentBrowserPushEndpoint() async => null;

Future<void> unsubscribeBrowserPush() async {}
