import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multigames_client/core/api_config.dart';

void agentDebugLog({
  required String hypothesisId,
  required String location,
  required String message,
  required Map<String, dynamic> data,
}) {
  unawaited(() async {
    try {
      await http
          .post(
            Uri.parse('$apiBaseUrl/api/agent-debug'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'hypothesisId': hypothesisId,
              'location': location,
              'message': message,
              'data': data,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            }),
          )
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }());
}
