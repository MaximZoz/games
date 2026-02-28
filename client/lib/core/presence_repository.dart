import 'dart:convert';

import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';

class PresenceEntry {
  final bool online;
  final String? lastSeenAt;

  PresenceEntry({required this.online, this.lastSeenAt});
}

class PresenceRepository {
  PresenceRepository({required AuthRepository authRepository})
      : _auth = authRepository;

  final AuthRepository _auth;

  Future<Map<String, PresenceEntry>> getPresence(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    final ids = userIds.toSet().take(50).join(',');
    final uri = Uri.parse('$apiBaseUrl/api/presence').replace(
      queryParameters: {'user_ids': ids},
    );
    try {
    final response = await _auth.sendAuthorized(
      (token) => ApiClient.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
        operation: 'PresenceRepository.getPresence',
      ),
    );
    if (response.statusCode != 200) {
      return {};
    }
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final users = body['users'] as Map<String, dynamic>? ?? {};
      final result = <String, PresenceEntry>{};
      for (final e in users.entries) {
        final v = e.value as Map<String, dynamic>;
        result[e.key] = PresenceEntry(
          online: v['online'] as bool? ?? false,
          lastSeenAt: v['last_seen_at'] as String?,
        );
      }
      return result;
    } catch (_) {
      return {};
    }
    } on AuthException {
      rethrow;
    }
  }
}
