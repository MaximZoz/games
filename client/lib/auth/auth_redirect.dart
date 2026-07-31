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
      value.startsWith('/register?') ||
      value == '/verify-email' ||
      value.startsWith('/verify-email?') ||
      value == '/forgot-password' ||
      value.startsWith('/forgot-password?') ||
      value == '/reset-password' ||
      value.startsWith('/reset-password?') ||
      value == '/oauth/callback' ||
      value.startsWith('/oauth/callback?')) {
    return null;
  }
  return value;
}

/// Добавляет `?redirect=` к [path], если [redirect] безопасен.
String appendRedirectQuery(String path, String? redirect) {
  return appendAuthQuery(path, redirect: redirect);
}

/// Добавляет query (`redirect`, `ref`) к пути логина/регистрации.
String appendAuthQuery(
  String path, {
  String? redirect,
  String? ref,
  String? email,
}) {
  final params = <String, String>{};
  final safe = safeAuthRedirect(redirect);
  if (safe != null) params['redirect'] = safe;
  final referral = (ref ?? '').trim();
  if (referral.isNotEmpty) params['ref'] = referral;
  final mail = (email ?? '').trim();
  if (mail.isNotEmpty) params['email'] = mail;
  if (params.isEmpty) return path;
  return Uri(path: path, queryParameters: params).toString();
}

/// Текущий location (path + query) из [uri] для сохранения в redirect.
String locationFromUri(Uri uri) {
  if (!uri.hasQuery) return uri.path;
  return '${uri.path}?${uri.query}';
}
