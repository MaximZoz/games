import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';

class AdminUserItem {
  final String id;
  final String email;
  final String? displayName;
  final bool isAdmin;
  final String createdAt;
  final int? age;
  final String? gender;
  final String? about;
  final String avatarKind;
  final String? avatarValue;

  AdminUserItem({
    required this.id,
    required this.email,
    this.displayName,
    required this.isAdmin,
    required this.createdAt,
    this.age,
    this.gender,
    this.about,
    this.avatarKind = 'letter',
    this.avatarValue,
  });

  factory AdminUserItem.fromJson(Map<String, dynamic> json) {
    return AdminUserItem(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      about: json['about'] as String?,
      avatarKind: json['avatar_kind'] as String? ?? 'letter',
      avatarValue: json['avatar_value'] as String?,
    );
  }
}

class AdminLogItem {
  final String eventId;
  final String eventTime;
  final String source;
  final String methodName;
  final String? httpMethod;
  final String? path;
  final int? statusCode;
  final int? durationMs;
  final String? userId;
  final String? ip;
  final String? userAgent;
  final String level;
  final String? message;
  final Map<String, dynamic>? metadata;

  AdminLogItem({
    required this.eventId,
    required this.eventTime,
    required this.source,
    required this.methodName,
    this.httpMethod,
    this.path,
    this.statusCode,
    this.durationMs,
    this.userId,
    this.ip,
    this.userAgent,
    required this.level,
    this.message,
    this.metadata,
  });

  factory AdminLogItem.fromJson(Map<String, dynamic> json) {
    return AdminLogItem(
      eventId: json['event_id'] as String? ?? '',
      eventTime: json['event_time'] as String? ?? '',
      source: json['source'] as String? ?? '',
      methodName: json['method_name'] as String? ?? '',
      httpMethod: json['http_method'] as String?,
      path: json['path'] as String?,
      statusCode: json['status_code'] as int?,
      durationMs: json['duration_ms'] as int?,
      userId: json['user_id'] as String?,
      ip: json['ip'] as String?,
      userAgent: json['user_agent'] as String?,
      level: json['level'] as String? ?? 'info',
      message: json['message'] as String?,
      metadata: json['metadata'] == null
          ? null
          : Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }
}

class AdminRepository {
  AdminRepository({required AuthRepository authRepository})
      : _auth = authRepository;

  final AuthRepository _auth;

  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(String token) request,
  ) async {
    try {
      return await _auth.sendAuthorized(request);
    } on AuthException catch (e) {
      throw AdminException(
        e.statusCode,
        e.statusCode == 401 ? 'Сессия истекла. Войдите заново.' : e.message,
      );
    }
  }

  Never _throwForErrorResponse(http.Response response) {
    var message = response.body.trim();
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        message = (body['message'] ?? body['error'] ?? message).toString();
      }
    } catch (_) {}

    if (response.statusCode == 401) {
      throw AdminException(401, 'Сессия истекла. Войдите заново.');
    }
    if (response.statusCode == 403 && message.isEmpty) {
      throw AdminException(403, 'Недостаточно прав для этого действия.');
    }
    throw AdminException(response.statusCode, message.isEmpty ? 'Ошибка сервера' : message);
  }

  Future<List<AdminUserItem>> listUsers() async {
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/admin/users'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'AdminRepository.listUsers',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['users'] as List<dynamic>;
    return list
        .map((e) => AdminUserItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> setAdmin(String userId, bool isAdmin) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/admin/users/set-admin'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': userId, 'is_admin': isAdmin}),
        operation: 'AdminRepository.setAdmin',
      ),
    );
    if (response.statusCode != 204) {
      _throwForErrorResponse(response);
    }
  }

  Future<void> resetPassword(String userId, String newPassword) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/admin/users/reset-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': userId, 'new_password': newPassword}),
        operation: 'AdminRepository.resetPassword',
      ),
    );
    if (response.statusCode != 204) {
      _throwForErrorResponse(response);
    }
  }

  Future<void> deleteUser(String userId) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/admin/users/delete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': userId}),
        operation: 'AdminRepository.deleteUser',
      ),
    );
    if (response.statusCode != 204) {
      _throwForErrorResponse(response);
    }
  }

  Future<List<AdminLogItem>> listLogs({
    int limit = 100,
    int offset = 0,
    String? userId,
    String? source,
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      if (source != null && source.isNotEmpty) 'source': source,
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    };
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/admin/logs').replace(queryParameters: query),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'AdminRepository.listLogs',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['logs'] as List<dynamic>? ?? const [];
    return list
        .map((e) => AdminLogItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

class AdminException implements Exception {
  final int statusCode;
  final String message;
  AdminException(this.statusCode, this.message);
  @override
  String toString() => message;
}
