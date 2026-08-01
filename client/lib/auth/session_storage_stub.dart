/// Non-web: резервное хранилище сессии не используется.
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
