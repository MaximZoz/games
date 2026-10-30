import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// iOS: UserDefaults через живой messenger (канал в SceneDelegate).
/// Android: отдельный SharedPreferences, не плагин. Плагин на холодном
/// старте иногда молчит дольше двух секунд, и без копии токенов приложение
/// открывает вход, хотя сессия на диске ещё есть.
const _channel = MethodChannel('com.zozugames/session_store');

typedef SessionBackup = ({
  String? accessToken,
  String? refreshToken,
  String? userJson,
});

SessionBackup? _cache;
bool _loaded = false;
Future<void>? _loading;
Future<void> _queue = Future<void>.value();

/// Нативная копия сессии есть на iOS и Android. Web пишет в localStorage.
bool nativeSessionStoreEnabled({required bool ios, required bool android}) =>
    ios || android;

bool get _useNativeStore => nativeSessionStoreEnabled(
      ios: Platform.isIOS,
      android: Platform.isAndroid,
    );

void writeSessionBackup({
  required String accessToken,
  required String refreshToken,
  required String userJson,
}) {
  if (!_useNativeStore) return;
  _cache = (
    accessToken: accessToken,
    refreshToken: refreshToken,
    userJson: userJson,
  );
  _loaded = true;
  _queue = _enqueue(() => _invoke('write', <String, String>{
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'user': userJson,
      }));
}

void clearSessionBackup() {
  if (!_useNativeStore) return;
  _cache = null;
  _loaded = true;
  _queue = _enqueue(() => _invoke('clear', null));
}

SessionBackup? readSessionBackup() {
  if (!_useNativeStore) return null;
  final cache = _cache;
  if (cache == null) return null;
  final access = cache.accessToken;
  final refresh = cache.refreshToken;
  if ((access == null || access.isEmpty) &&
      (refresh == null || refresh.isEmpty)) {
    return null;
  }
  return cache;
}

Future<void> ensureSessionBackupLoaded() {
  if (!_useNativeStore || _loaded) return Future<void>.value();
  return _loading ??= _load();
}

Future<void> flushSessionBackup() async {
  if (!_useNativeStore) return;
  try {
    await _queue;
  } catch (_) {}
}

Future<void> _load() async {
  try {
    final raw = await _invoke('read', null);
    if (_cache != null) return;
    if (raw is! Map) return;
    final access = (raw['access_token'] ?? '').toString();
    final refresh = (raw['refresh_token'] ?? '').toString();
    final user = (raw['user'] ?? '').toString();
    if (access.isEmpty && refresh.isEmpty) return;
    _cache = (
      accessToken: access,
      refreshToken: refresh,
      userJson: user,
    );
  } finally {
    _loaded = true;
    _loading = null;
  }
}

Future<void> _enqueue(Future<dynamic> Function() action) {
  final next = _queue.catchError((_) {}).then((_) async {
    await action();
  });
  return next;
}

Future<dynamic> _invoke(String method, Object? args) async {
  Object? lastError;
  for (var attempt = 0; attempt < 20; attempt++) {
    try {
      return await _channel
          .invokeMethod<dynamic>(method, args)
          .timeout(const Duration(seconds: 2));
    } on TimeoutException {
      return null;
    } on MissingPluginException catch (e) {
      lastError = e;
      await Future<void>.delayed(const Duration(milliseconds: 40));
    } on PlatformException {
      return null;
    }
  }
  if (lastError != null) return null;
  return null;
}
