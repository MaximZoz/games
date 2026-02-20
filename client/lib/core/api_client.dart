import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multigames_client/core/api_config.dart';

class ApiClient {
  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    String? operation,
  }) {
    return _request(
      () => http.get(uri, headers: headers),
      uri: uri,
      httpMethod: 'GET',
      headers: headers,
      operation: operation,
    );
  }

  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    String? operation,
  }) {
    return _request(
      () => http.post(uri, headers: headers, body: body),
      uri: uri,
      httpMethod: 'POST',
      headers: headers,
      operation: operation,
    );
  }

  static Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    String? operation,
  }) {
    return _request(
      () => http.put(uri, headers: headers, body: body),
      uri: uri,
      httpMethod: 'PUT',
      headers: headers,
      operation: operation,
    );
  }

  static Future<http.Response> _request(
    Future<http.Response> Function() call, {
    required Uri uri,
    required String httpMethod,
    required Map<String, String>? headers,
    String? operation,
  }) async {
    final startedAt = DateTime.now().toUtc();
    final stopwatch = Stopwatch()..start();
    http.Response? response;
    Object? error;

    try {
      response = await call();
      return response;
    } catch (e) {
      error = e;
      rethrow;
    } finally {
      stopwatch.stop();
      _sendFrontendLog(
        operation: operation ?? '$httpMethod ${uri.path}',
        requestUri: uri,
        httpMethod: httpMethod,
        statusCode: response?.statusCode,
        durationMs: stopwatch.elapsedMilliseconds,
        startedAt: startedAt,
        error: error?.toString(),
        authorizationHeader: headers?['Authorization'],
      );
    }
  }

  static void _sendFrontendLog({
    required String operation,
    required Uri requestUri,
    required String httpMethod,
    required int? statusCode,
    required int durationMs,
    required DateTime startedAt,
    required String? error,
    required String? authorizationHeader,
  }) {
    if (requestUri.path.endsWith('/api/logs/frontend')) return;

    final logUri = Uri.parse('$apiBaseUrl/api/logs/frontend');
    final payload = <String, dynamic>{
      'event_time': startedAt.toIso8601String(),
      'method_name': operation,
      'http_method': httpMethod,
      'path': requestUri.path,
      'status_code': statusCode,
      'duration_ms': durationMs,
      if (error != null && error.isNotEmpty) 'message': error,
      'metadata': <String, dynamic>{
        'url': requestUri.toString(),
      },
    };

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authorizationHeader != null && authorizationHeader.isNotEmpty) {
      headers['Authorization'] = authorizationHeader;
    }

    unawaited(() async {
      try {
        await http
            .post(
              logUri,
              headers: headers,
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 2));
      } catch (_) {}
    }());
  }
}
