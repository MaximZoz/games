/// Безопасный внутренний путь для возврата после логина/регистрации.
///
/// Отклоняет абсолютные URL и циклы на `/login` / `/register`.
String? safeAuthRedirect(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty) return null;
  if (value.contains('://') || value.startsWith('//')) return null;
  if (!value.startsWith('/')) return null;
  if (value == '/login' ||
      value.startsWith('/login?') ||
      value == '/register' ||
      value.startsWith('/register?')) {
    return null;
  }
  return value;
}

/// Добавляет `?redirect=` к [path], если [redirect] безопасен.
String appendRedirectQuery(String path, String? redirect) {
  final safe = safeAuthRedirect(redirect);
  if (safe == null) return path;
  return Uri(path: path, queryParameters: {'redirect': safe}).toString();
}

/// Текущий location (path + query) из [uri] для сохранения в redirect.
String locationFromUri(Uri uri) {
  if (!uri.hasQuery) return uri.path;
  return '${uri.path}?${uri.query}';
}
