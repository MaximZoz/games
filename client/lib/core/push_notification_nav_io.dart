import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:multigames_client/core/fcm.dart';
import 'package:multigames_client/core/local_notify.dart';
import 'package:multigames_client/core/push_nav_paths.dart';

typedef PushNotificationNavHandler = void Function(String path);

PushNotificationNavHandler? _onNavigate;
String? _pendingPath;
String _lastReportedPath = '';
StreamSubscription<FcmPushMessage>? _openedSub;
StreamSubscription<FcmPushMessage>? _foregroundSub;
var _listeningTaps = false;

bool _phoneNavEnabled() =>
    (Platform.isAndroid || Platform.isIOS) &&
    !Platform.environment.containsKey('FLUTTER_TEST');

void _go(String raw, {String? tag}) {
  final path = normalizeAppPath(raw);
  if (path.isEmpty || path == '/') return;
  if (pathSpecificity(path) >= 2) markPushOpenedRoute();
  if (_onNavigate == null) {
    if (pathSpecificity(path) > pathSpecificity(_pendingPath ?? '')) {
      _pendingPath = path;
    }
    return;
  }
  if (pathSpecificity(path) <= 1 &&
      _pendingPath != null &&
      pathSpecificity(_pendingPath!) > pathSpecificity(path)) {
    final pending = _pendingPath!;
    _pendingPath = null;
    _onNavigate!(pending);
    unawaited(
      cancelLocalNotificationsForPath(
        pending,
        tag: tag ?? tagFromPath(pending),
      ),
    );
    return;
  }
  _onNavigate!(path);
  unawaited(
    cancelLocalNotificationsForPath(path, tag: tag ?? tagFromPath(path)),
  );
}

void _goFromData(Map<String, String> data) {
  final path = pathFromIosTap(data);
  if (path == null || path == '/') return;
  _go(path, tag: data['tag'] ?? tagFromPath(path));
}

void _onLocalPayload(String payload) {
  final path = pathFromNotificationPayload(payload);
  if (path == null) return;
  String? tag = tagFromPath(path);
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map && decoded['tag'] is String) {
      final raw = (decoded['tag'] as String).trim();
      if (raw.isNotEmpty) tag = raw;
    }
  } catch (_) {}
  _go(path, tag: tag);
}

Future<void> _consumePendingLaunches() async {
  final local = await consumeLocalNotificationLaunchPayload();
  if (local != null) _onLocalPayload(local);
  final native = await takeIosNotificationTap();
  if (native != null) _goFromData(native);
  final fcm = await getInitialFcmMessage();
  if (fcm != null) _goFromData(fcm.data);
}

void _ensureTapListeners() {
  if (_listeningTaps || !_phoneNavEnabled()) return;
  _listeningTaps = true;
  setLocalNotificationTapHandler(_onLocalPayload);
  listenIosNotificationTaps(_goFromData);
  _openedSub = fcmOpenedAppMessages().listen((msg) => _goFromData(msg.data));
  _foregroundSub = fcmForegroundMessages().listen((msg) {
    final path = pathFromPushData(msg.data);
    if (path == null) return;
    if (pathsMatch(_lastReportedPath, path)) {
      unawaited(cancelLocalNotificationsForPath(path, tag: msg.data['tag']));
    }
  });
  unawaited(_consumePendingLaunches());
}

/// Слушает тап по FCM / локальному баннеру → `router.go`, как PWA.
void installPushNotificationNavigation(PushNotificationNavHandler onNavigate) {
  if (!_phoneNavEnabled()) return;
  uninstallPushNotificationNavigation();
  _onNavigate = onNavigate;
  _ensureTapListeners();
  if (_pendingPath != null) {
    final pending = _pendingPath!;
    _pendingPath = null;
    _go(pending);
  }
}

void uninstallPushNotificationNavigation() {
  _openedSub?.cancel();
  _foregroundSub?.cancel();
  _openedSub = null;
  _foregroundSub = null;
  _listeningTaps = false;
  setLocalNotificationTapHandler(null);
  _onNavigate = null;
}

/// Открыли чат/матч — снять баннер этого треда, как `active_route` в SW.
void reportPushSwActiveRoute(String path) {
  final normalized = normalizeAppPath(path);
  _lastReportedPath = normalized;
  if (!_phoneNavEnabled()) return;
  final tag = tagFromPath(normalized);
  if (tag == null) return;
  unawaited(cancelLocalNotificationsForPath(normalized, tag: tag));
}

/// Прочитали чат — убрать висящие баннеры диалога из шторки.
void clearPushNotificationsForChat(String chatId) {
  final id = chatId.trim();
  if (id.isEmpty) return;
  unawaited(cancelLocalNotificationsForTag('chat_$id'));
}
