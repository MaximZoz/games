import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сколько ждать первый ответ SharedPreferences.
///
/// На iOS UIScene и на холодном старте Android плагин может не ответить.
/// `getInstance` тогда оставляет статичный completer, и каждый следующий
/// вызов ждёт тот же future. Повторно его не ждём, но если ответ всё же
/// придёт позже — сессию из него ещё можно прочитать.
const Duration sharedPrefsTimeout = Duration(seconds: 2);

bool _prefsUnusable = false;
bool _prefsSawTimeout = false;
SharedPreferences? _ready;
Future<SharedPreferences?>? _guarded;

@visibleForTesting
Future<SharedPreferences> Function() loadSharedPreferences =
    SharedPreferences.getInstance;

@visibleForTesting
void resetSharedPrefsGuard() {
  _prefsUnusable = false;
  _prefsSawTimeout = false;
  _ready = null;
  _guarded = null;
  loadSharedPreferences = SharedPreferences.getInstance;
}

/// Был таймаут в этом процессе. Вход не показываем, пока не перечитаем prefs.
bool get sharedPrefsNeedsSessionRetry => _prefsSawTimeout;

/// Плагин уже ответил, в том числе после таймаута.
bool get sharedPrefsReady => _ready != null;

/// null — prefs ещё недоступны. Зависший future второй раз не ждём.
Future<SharedPreferences?> sharedPreferencesOrNull({
  Duration timeout = sharedPrefsTimeout,
}) {
  final ready = _ready;
  if (ready != null) return Future<SharedPreferences?>.value(ready);
  if (_prefsUnusable) return Future<SharedPreferences?>.value(null);
  return _guarded ??= _load(timeout);
}

Future<SharedPreferences?> _load(Duration timeout) {
  final pending = loadSharedPreferences();
  unawaited(() async {
    try {
      final prefs = await pending;
      _ready = prefs;
      _prefsUnusable = false;
    } catch (_) {}
  }());
  return _finish(pending, timeout);
}

Future<SharedPreferences?> _finish(
  Future<SharedPreferences> pending,
  Duration timeout,
) async {
  try {
    final prefs = await pending.timeout(timeout);
    _ready = prefs;
    _prefsUnusable = false;
    return prefs;
  } on TimeoutException {
    _prefsUnusable = true;
    _prefsSawTimeout = true;
    return null;
  } catch (_) {
    return null;
  } finally {
    if (!_prefsUnusable) _guarded = null;
  }
}
