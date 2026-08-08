/// Для продакшена (Docker/Fly) передаём --dart-define=API_BASE= — тогда берётся origin страницы.
const String _apiBaseUrlRaw =
    String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:8080');

/// Короткий git sha / BUILD_ID, прошитый при сборке (`--dart-define=BUILD_ID=...`).
const String appBuildId =
    String.fromEnvironment('BUILD_ID', defaultValue: 'dev');

/// Отправка клиентских логов на /api/logs/frontend (для отладки).
/// По умолчанию отключено.
const bool frontendApiLogsEnabled =
    bool.fromEnvironment('FRONTEND_LOGS_ENABLED', defaultValue: false);

/// Базовый URL API. Если API_BASE пустой (продакшен), на Web используется origin текущей страницы.
String get apiBaseUrl =>
    _apiBaseUrlRaw.isEmpty ? Uri.base.origin : _apiBaseUrlRaw;

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
