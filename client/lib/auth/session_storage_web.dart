import 'package:web/web.dart' as web;

/// Резерв в localStorage напрямую — если SharedPreferences на Safari
/// не записал ключи, сессия всё равно переживёт закрытие вкладки.
const _kAccess = 'mg.session.access_token';
const _kRefresh = 'mg.session.refresh_token';
const _kUser = 'mg.session.user';

void writeSessionBackup({
  required String accessToken,
  required String refreshToken,
  required String userJson,
}) {
  try {
    final storage = web.window.localStorage;
    storage.setItem(_kAccess, accessToken);
    storage.setItem(_kRefresh, refreshToken);
    storage.setItem(_kUser, userJson);
  } catch (_) {
    // Private mode / quota — caller увидит ошибку через SharedPreferences.
  }
}

void clearSessionBackup() {
  try {
    final storage = web.window.localStorage;
    storage.removeItem(_kAccess);
    storage.removeItem(_kRefresh);
    storage.removeItem(_kUser);
  } catch (_) {}
}

({String? accessToken, String? refreshToken, String? userJson})?
    readSessionBackup() {
  try {
    final storage = web.window.localStorage;
    final access = storage.getItem(_kAccess);
    final refresh = storage.getItem(_kRefresh);
    final user = storage.getItem(_kUser);
    if ((access == null || access.isEmpty) &&
        (refresh == null || refresh.isEmpty)) {
      return null;
    }
    return (accessToken: access, refreshToken: refresh, userJson: user);
  } catch (_) {
    return null;
  }
}
