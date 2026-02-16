/// Для продакшена (Docker/Fly) передаём --dart-define=API_BASE= — тогда берётся origin страницы.
const String _apiBaseUrlRaw =
    String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:8080');

/// Базовый URL API. Если API_BASE пустой (продакшен), на Web используется origin текущей страницы.
String get apiBaseUrl =>
    _apiBaseUrlRaw.isEmpty ? Uri.base.origin : _apiBaseUrlRaw;
