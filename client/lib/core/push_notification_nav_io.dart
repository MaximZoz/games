import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
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
String? _lastNavKey;
DateTime? _lastNavAt;

bool _isDuplicatePushNav(String path) {
  final key = path.split('?').first;
  final now = DateTime.now();
  // Повтор native-тапа (холодный старт шлёт его несколько раз) не должен
  // второй раз сбрасывать экран. Окно длиннее, чем пауза перед replay.
  if (_lastNavKey == key &&
      _lastNavAt != null &&
      now.difference(_lastNavAt!) < const Duration(seconds: 5)) {
    return true;
  }
  _lastNavKey = key;
  _lastNavAt = now;
  return false;
}

bool _phoneNavEnabled() =>
    (Platform.isAndroid || Platform.isIOS) &&
    !Platform.environment.containsKey('FLUTTER_TEST');

void _go(String raw, {String? tag}) {
  final path = normalizeAppPath(raw);
  if (path.isEmpty || path == '/') return;
  if (pathSpecificity(path) >= 2) markPushOpenedRoute();
  if (_onNavigate == null) {
    // Не занимаем слот дедупа, пока навигации ещё нет: иначе первый
    // настоящий go через 300 мс считается повтором и чат не открывается.
    if (pathSpecificity(path) > pathSpecificity(_pendingPath ?? '')) {
      _pendingPath = path;
    }
    return;
  }
  if (_isDuplicatePushNav(path)) return;
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

Future<void> _retryIosTaps() async {
  if (!Platform.isIOS) return;
  // Канал storyboard-engine и обработчик Dart появляются позже тапа.
  // Без повтора холодный старт и возврат из фона остаются на «Играх».
  const delays = <Duration>[
    Duration.zero,
    Duration(milliseconds: 300),
    Duration(milliseconds: 1000),
    Duration(milliseconds: 2500),
  ];
  for (final delay in delays) {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (!_listeningTaps && _onNavigate == null) return;
    final native = await takeIosNotificationTap();
    if (native != null) {
      _goFromData(native);
      return;
    }
  }
}

class _PushResumeObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_retryIosTaps());
    }
  }
}

final _resumeObserver = _PushResumeObserver();
var _observingResume = false;

void _ensureResumeObserver() {
  if (_observingResume) return;
  _observingResume = true;
  WidgetsBinding.instance.addObserver(_resumeObserver);
}

Future<void> _consumePendingLaunches() async {
  final local = await consumeLocalNotificationLaunchPayload();
  if (local != null) _onLocalPayload(local);
  await _retryIosTaps();
  final fcm = await getInitialFcmMessage();
  if (fcm != null) _goFromData(fcm.data);
}

void _ensureTapListeners() {
  if (_listeningTaps || !_phoneNavEnabled()) return;
  _listeningTaps = true;
  _ensureResumeObserver();
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
