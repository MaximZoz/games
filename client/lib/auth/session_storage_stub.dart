import 'dart:async';

/// Заглушка, если нет ни браузера, ни dart:io.
void writeSessionBackup({
  required String accessToken,
  required String refreshToken,
  required String userJson,
}) {}

void clearSessionBackup() {}

({String? accessToken, String? refreshToken, String? userJson})?
    readSessionBackup() {
  return null;
}

Future<void> ensureSessionBackupLoaded() async {}

Future<void> flushSessionBackup() async {}
