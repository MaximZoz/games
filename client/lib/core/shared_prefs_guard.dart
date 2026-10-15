import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сколько ждать первый ответ SharedPreferences.
///
/// На iOS UIScene плагин может не ответить. `getInstance` тогда оставляет
/// статичный completer, и каждый следующий вызов ждёт тот же future.
const Duration sharedPrefsTimeout = Duration(seconds: 2);

bool _prefsUnusable = false;
Future<SharedPreferences?>? _guarded;

@visibleForTesting
Future<SharedPreferences> Function() loadSharedPreferences =
    SharedPreferences.getInstance;

@visibleForTesting
void resetSharedPrefsGuard() {
  _prefsUnusable = false;
  _guarded = null;
  loadSharedPreferences = SharedPreferences.getInstance;
}

/// null — prefs недоступны. После таймаута повторно не ждём.
Future<SharedPreferences?> sharedPreferencesOrNull({
  Duration timeout = sharedPrefsTimeout,
}) {
  if (_prefsUnusable) return Future<SharedPreferences?>.value(null);
  return _guarded ??= _load(timeout);
}

Future<SharedPreferences?> _load(Duration timeout) async {
  try {
    return await loadSharedPreferences().timeout(timeout);
  } on TimeoutException {
    _prefsUnusable = true;
    return null;
  } catch (_) {
    return null;
  } finally {
    if (!_prefsUnusable) _guarded = null;
  }
}
