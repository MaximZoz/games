import 'package:flutter/foundation.dart' show kIsWeb;

/// Для продакшена (Docker/Fly) передаём --dart-define=API_BASE= — тогда берётся origin страницы.
const String _apiBaseUrlRaw =
    String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:8080');

/// Короткий git sha / BUILD_ID, прошитый при сборке (`--dart-define=BUILD_ID=...`).
const String appBuildId =
    String.fromEnvironment('BUILD_ID', defaultValue: 'dev');

/// Человекочитаемая версия для UI (CI: `--dart-define=APP_VERSION=0.1.0-prod.12+10012`).
/// Если не задана — показываем [appBuildId] (web/local → часто `dev`).
const String _appVersionRaw =
    String.fromEnvironment('APP_VERSION', defaultValue: '');

/// Строка «Версия …» в настройках.
String get appVersionLabel {
  final v = _appVersionRaw.trim();
  if (v.isNotEmpty) return v;
  return appBuildId;
}

/// Отправка клиентских логов на /api/logs/frontend (для отладки).
/// По умолчанию отключено.
const bool frontendApiLogsEnabled =
    bool.fromEnvironment('FRONTEND_LOGS_ENABLED', defaultValue: false);

/// Базовый URL API. Если API_BASE пустой (продакшен), на Web используется origin текущей страницы.
String get apiBaseUrl =>
    _apiBaseUrlRaw.isEmpty ? Uri.base.origin : _apiBaseUrlRaw;

/// Custom scheme, которым сервер закрывает системный лист входа (не сайт).
/// Dev и prod — разные схемы, чтобы два установленных приложения не перехватывали друг друга.
String oauthAppReturnSchemeForHost(String host) {
  final name = host.trim().toLowerCase();
  if (name == 'localhost' ||
      name == '127.0.0.1' ||
      name.contains('-dev.')) {
    return 'zozugames-dev';
  }
  return 'zozugames';
}

String get oauthAppReturnScheme => oauthAppReturnSchemeForHost(
      Uri.tryParse(apiBaseUrl)?.host ?? '',
    );

/// Origin для ссылок «поделиться» (реферал, инвайт в лобби).
///
/// На web — `Uri.base`. На Android/iOS `Uri.base` часто `file://…` → битая ссылка
/// и пустой UI; берём origin из [apiBaseUrl] (на Fly web и API на одном хосте).
Uri get shareLinkBaseUri {
  if (kIsWeb) {
    final base = Uri.base;
    if (base.scheme == 'http' || base.scheme == 'https') {
      return base;
    }
  }
  final api = apiBaseUrl.trim();
  if (api.isNotEmpty) {
    final parsed = Uri.tryParse(api);
    if (parsed != null &&
        (parsed.scheme == 'http' || parsed.scheme == 'https')) {
      return parsed;
    }
  }
  return Uri.parse('https://multigameszozu.fly.dev');
}

Uri buildWebSocketUri(
  String path, {
  Map<String, String>? queryParameters,
}) {
  final base = Uri.parse(apiBaseUrl);
  final wsScheme = base.scheme == 'https' ? 'wss' : 'ws';
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  final basePath = base.path == '/' ? '' : base.path;
  return Uri(
    scheme: wsScheme,
    userInfo: base.userInfo,
    host: base.host,
    port: base.hasPort ? base.port : null,
    path: '$basePath$normalizedPath',
    queryParameters: queryParameters,
  );
}
