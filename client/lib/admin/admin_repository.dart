import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
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

class AdminRepository {
  AdminRepository({required AuthRepository authRepository})
      : _auth = authRepository;

  final AuthRepository _auth;

  Future<String?> _token() async {
    await _auth.init();
    return _auth.getAccessToken();
  }

  Future<List<AdminUserItem>> listUsers() async {
    final token = await _token();
    if (token == null) throw AdminException(401, 'Not authenticated');
    final response = await http.get(
      Uri.parse('$apiBaseUrl/api/admin/users'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw AdminException(response.statusCode, response.body);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['users'] as List<dynamic>;
    return list
        .map((e) => AdminUserItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> setAdmin(String userId, bool isAdmin) async {
    final token = await _token();
    if (token == null) throw AdminException(401, 'Not authenticated');
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/admin/users/set-admin'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'user_id': userId, 'is_admin': isAdmin}),
    );
    if (response.statusCode != 204) {
      throw AdminException(response.statusCode, response.body);
    }
  }

  Future<void> resetPassword(String userId, String newPassword) async {
    final token = await _token();
    if (token == null) throw AdminException(401, 'Not authenticated');
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/admin/users/reset-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'user_id': userId, 'new_password': newPassword}),
    );
    if (response.statusCode != 204) {
      throw AdminException(response.statusCode, response.body);
    }
  }

  Future<void> deleteUser(String userId) async {
    final token = await _token();
    if (token == null) throw AdminException(401, 'Not authenticated');
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/admin/users/delete'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'user_id': userId}),
    );
    if (response.statusCode != 204) {
      throw AdminException(response.statusCode, response.body);
    }
  }
}

class AdminException implements Exception {
  final int statusCode;
  final String message;
  AdminException(this.statusCode, this.message);
  @override
  String toString() => message;
}
