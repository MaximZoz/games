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
  final bool isSupport;
  final bool isFrozen;
  final String? frozenAt;
  final String createdAt;
  final String? lastSeenAt;
  final int balanceBronze;
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
    this.isSupport = false,
    this.isFrozen = false,
    this.frozenAt,
    required this.createdAt,
    this.lastSeenAt,
    this.balanceBronze = 0,
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
      isSupport: json['is_support'] as bool? ?? false,
      isFrozen: json['is_frozen'] as bool? ?? false,
      frozenAt: json['frozen_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      lastSeenAt: json['last_seen_at'] as String?,
      balanceBronze: (json['balance_bronze'] as num?)?.toInt() ?? 0,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      about: json['about'] as String?,
      avatarKind: json['avatar_kind'] as String? ?? 'letter',
      avatarValue: json['avatar_value'] as String?,
    );
  }
}

/// Параметры поиска/сортировки/пагинации пользователей админкой.
class AdminUsersQuery {
  const AdminUsersQuery({
    this.q = '',
    this.sort = 'created_at',
    this.order = 'desc',
    this.adminFilter = 'all',
    this.frozenFilter = 'all',
    this.limit = 20,
    this.offset = 0,
  });

  final String q;
  final String sort; // created_at | last_seen | email
  final String order; // asc | desc
  final String adminFilter; // all | admin | user
  final String frozenFilter; // all | frozen | active
  final int limit;
  final int offset;

  AdminUsersQuery copyWith({
    String? q,
    String? sort,
    String? order,
    String? adminFilter,
    String? frozenFilter,
    int? limit,
    int? offset,
  }) {
    return AdminUsersQuery(
      q: q ?? this.q,
      sort: sort ?? this.sort,
      order: order ?? this.order,
      adminFilter: adminFilter ?? this.adminFilter,
      frozenFilter: frozenFilter ?? this.frozenFilter,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  Map<String, String> toQueryParams() {
    return {
      if (q.trim().isNotEmpty) 'q': q.trim(),
      'sort': sort,
      'order': order,
      'admin': adminFilter,
      'frozen': frozenFilter,
      'limit': '$limit',
      'offset': '$offset',
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUsersQuery &&
          q == other.q &&
          sort == other.sort &&
          order == other.order &&
          adminFilter == other.adminFilter &&
          frozenFilter == other.frozenFilter &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(
      q, sort, order, adminFilter, frozenFilter, limit, offset);
}

/// Страница списка пользователей.
class AdminUsersPage {
  final List<AdminUserItem> users;
  final int total;

  const AdminUsersPage({required this.users, required this.total});
}

/// Превью диалога поддержки.
class SupportChatItem {
  final String chatId;
  final String peerId;
  final String? peerName;
  final String? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;
  final String? avatarKind;
  final String? avatarValue;

  const SupportChatItem({
    required this.chatId,
    required this.peerId,
    this.peerName,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.avatarKind,
    this.avatarValue,
  });

  factory SupportChatItem.fromJson(Map<String, dynamic> json) {
    return SupportChatItem(
      chatId: json['id'] as String? ?? '',
      peerId: json['peer_id'] as String? ?? json['user_id'] as String? ?? '',
      peerName: json['peer_name'] as String? ?? json['display_name'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] as String? ?? json['created_at'] as String?,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      avatarKind: json['avatar_kind'] as String?,
      avatarValue: json['avatar_value'] as String?,
    );
  }
}

/// Сообщение поддержки (переиспользует формат чата).
class SupportMessageItem {
  final String id;
  final String body;
  final String createdAt;
  final bool isMine; // true — от поддержки (админ)

  const SupportMessageItem({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.isMine,
  });

  factory SupportMessageItem.fromJson(Map<String, dynamic> json, String myUserId) {
    return SupportMessageItem(
      id: json['id'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      isMine: (json['sender_user_id'] as String?) == myUserId,
    );
  }
}

/// Контакт аккаунта поддержки (для обычного пользователя).
class SupportContact {
  final String id;
  final String displayName;

  const SupportContact({required this.id, required this.displayName});

  factory SupportContact.fromJson(Map<String, dynamic> json) {
    return SupportContact(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Поддержка',
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
    final translated = message.isEmpty ? 'Ошибка сервера' : _translateMessage(message);
    throw AdminException(response.statusCode, translated);
  }

  static String _translateMessage(String msg) {
    final m = msg.toLowerCase().trim();
    const Map<String, String> map = {
      'server error': 'Ошибка сервера. Попробуйте позже.',
      'admin only': 'Только для администраторов',
    };
    return map[m] ?? msg;
  }

  Future<AdminUsersPage> listUsers(AdminUsersQuery query) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/admin/users')
            .replace(queryParameters: query.toQueryParams()),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'AdminRepository.listUsers',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['users'] as List<dynamic>? ?? const [];
    final users = list
        .map((e) => AdminUserItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return AdminUsersPage(
      users: users,
      total: (body['total'] as num?)?.toInt() ?? users.length,
    );
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

  Future<void> freezeUser(String userId, bool frozen) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/admin/users/freeze'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': userId, 'frozen': frozen}),
        operation: 'AdminRepository.freezeUser',
      ),
    );
    if (response.statusCode != 204) {
      _throwForErrorResponse(response);
    }
  }

  Future<int> grantCoins(String userId, int amountBronze, {String reason = ''}) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/admin/users/grant-coins'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'amount_bronze': amountBronze,
          'reason': reason,
        }),
        operation: 'AdminRepository.grantCoins',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['balance_bronze'] as num?)?.toInt() ?? 0;
  }

  Future<List<SupportChatItem>> listSupportChats() async {
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/admin/support/chats'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'AdminRepository.listSupportChats',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['chats'] as List<dynamic>? ?? const [];
    return list
        .map((e) => SupportChatItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<SupportMessageItem>> listSupportMessages(
    String userId,
    String myUserId,
  ) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/admin/support/chats/$userId/messages'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'AdminRepository.listSupportMessages',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['messages'] as List<dynamic>? ?? const [];
    return list
        .map((e) => SupportMessageItem.fromJson(
              Map<String, dynamic>.from(e as Map),
              myUserId,
            ))
        .toList();
  }

  Future<void> sendSupportMessage(String userId, String body) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/admin/support/chats/$userId/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'body': body}),
        operation: 'AdminRepository.sendSupportMessage',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
  }

  Future<SupportContact?> getSupportUser() async {
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/support-user'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'AdminRepository.getSupportUser',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body.isEmpty) return null;
    return SupportContact.fromJson(body);
  }
}

class AdminException implements Exception {
  final int statusCode;
  final String message;
  AdminException(this.statusCode, this.message);
  @override
  String toString() => message;
}
