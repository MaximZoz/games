typedef PushNotificationNavHandler = void Function(String path);

void installPushNotificationNavigation(PushNotificationNavHandler onNavigate) {}

void uninstallPushNotificationNavigation() {}

void reportPushSwActiveRoute(String path) {}
