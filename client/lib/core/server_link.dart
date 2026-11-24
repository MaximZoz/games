import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Запрос не ушёл в сеть: включён офлайн режим.
class OfflineModeException extends http.ClientException {
  OfflineModeException([Uri? uri]) : super('offline mode', uri);
}

/// Сбой уровня сети: сервер не ответил вовсе (обрыв, таймаут, DNS, TLS).
/// Ответ с любым HTTP-кодом сюда не относится — сервер на связи.
bool isServerUnreachableError(Object? error) {
  if (error == null || error is OfflineModeException) return false;
  if (error is TimeoutException || error is http.ClientException) return true;
  // dart:io на web недоступен, поэтому сокет и TLS узнаём по имени типа.
  final type = error.runtimeType.toString();
  return type.contains('SocketException') ||
      type.contains('HandshakeException') ||
      type.contains('TlsException') ||
      type.contains('HttpException');
}

/// Связь статического [ApiClient] с режимом сети приложения.
///
/// ApiClient не знает про Riverpod, поэтому режим и сбои сети живут здесь:
/// провайдер офлайна пишет [offline], экран слушает [failures].
class ServerLink {
  ServerLink._();

  static final ServerLink instance = ServerLink._();

  /// Офлайн режим: запросы к API сразу падают, без ожидания сети.
  bool offline = false;

  /// Счётчик сбоев сети в запросах к API. Растёт на каждый сбой.
  final ValueNotifier<int> failures = ValueNotifier<int>(0);

  /// Вход и регистрация работают и в офлайн режиме: иначе после сброса
  /// сессии в другой вкладке пользователь не сможет войти заново.
  static bool _isPublicAuth(Uri uri) {
    final path = uri.path;
    return path.contains('/api/auth/') && !path.endsWith('/api/auth/refresh');
  }

  /// Запрос нельзя отправлять: приложение в офлайн режиме.
  bool blocks(Uri uri) => offline && !_isPublicAuth(uri);

  void reportFailure() {
    failures.value = failures.value + 1;
  }

  @visibleForTesting
  void reset() {
    offline = false;
    failures.value = 0;
  }
}
