import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_config.dart';

void appendRuntimeDebugLog(
  AuthRepository auth, {
  required String hypothesisId,
  required String location,
  required String message,
  required Map<String, dynamic> data,
}) {
  // #region agent log
  unawaited(() async {
    try {
      await auth.sendAuthorized(
        (token) => http
            .post(
              Uri.parse('$apiBaseUrl/api/games/tictactoe/debug-log'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'hypothesisId': hypothesisId,
                'location': location,
                'message': message,
                'data': data,
              }),
            )
            .timeout(const Duration(seconds: 2)),
      );
    } catch (_) {}
  }());
  // #endregion
}
