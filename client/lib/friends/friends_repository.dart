import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';

class FriendUserItem {
  final String id;
  final String email;
  final String? displayName;
  final String avatarKind;
  final String? avatarValue;
  final int? age;
  final String? gender;
  final String? about;

  FriendUserItem({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarKind = 'letter',
    this.avatarValue,
    this.age,
    this.gender,
    this.about,
  });

  factory FriendUserItem.fromJson(Map<String, dynamic> json) {
    return FriendUserItem(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String?,
      avatarKind: json['avatar_kind'] as String? ?? 'letter',
      avatarValue: json['avatar_value'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      about: json['about'] as String?,
    );
  }
}

class FriendItem {
  final FriendUserItem user;
  final String createdAt;

  FriendItem({
    required this.user,
    required this.createdAt,
  });

  factory FriendItem.fromJson(Map<String, dynamic> json) {
    return FriendItem(
      user: FriendUserItem.fromJson(Map<String, dynamic>.from(json['user'] as Map? ?? {})),
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class FriendRequestItem {
  final String requestId;
  final FriendUserItem user;
  final String createdAt;

  FriendRequestItem({
    required this.requestId,
    required this.user,
    required this.createdAt,
  });

  factory FriendRequestItem.fromJson(Map<String, dynamic> json) {
    return FriendRequestItem(
      requestId: json['request_id'] as String? ?? '',
      user: FriendUserItem.fromJson(Map<String, dynamic>.from(json['user'] as Map? ?? {})),
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class FriendsSnapshot {
  final List<FriendItem> friends;
  final List<FriendRequestItem> incoming;
  final List<FriendRequestItem> outgoing;

  FriendsSnapshot({
    required this.friends,
    required this.incoming,
    required this.outgoing,
  });

  factory FriendsSnapshot.fromJson(Map<String, dynamic> json) {
    final friends = (json['friends'] as List<dynamic>? ?? const [])
        .map((e) => FriendItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final incoming = (json['incoming'] as List<dynamic>? ?? const [])
        .map((e) => FriendRequestItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final outgoing = (json['outgoing'] as List<dynamic>? ?? const [])
        .map((e) => FriendRequestItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return FriendsSnapshot(
      friends: friends,
      incoming: incoming,
      outgoing: outgoing,
    );
  }
}

class FriendSearchItem {
  final FriendUserItem user;
  final String relationStatus;
  final String? requestId;

  FriendSearchItem({
    required this.user,
    required this.relationStatus,
    this.requestId,
  });

  factory FriendSearchItem.fromJson(Map<String, dynamic> json) {
    return FriendSearchItem(
      user: FriendUserItem.fromJson(Map<String, dynamic>.from(json['user'] as Map? ?? {})),
      relationStatus: json['relation_status'] as String? ?? 'none',
      requestId: json['request_id'] as String?,
    );
  }
}

class FriendsRepository {
  FriendsRepository({required AuthRepository authRepository}) : _auth = authRepository;

  final AuthRepository _auth;

  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(String token) request,
  ) async {
    try {
      return await _auth.sendAuthorized(request);
    } on AuthException catch (e) {
      throw FriendsException(
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
      throw FriendsException(401, 'Сессия истекла. Войдите заново.');
    }
    if (response.statusCode == 403 && message.isEmpty) {
      throw FriendsException(403, 'Недостаточно прав для этого действия.');
    }
    if (response.statusCode == 404 && message.isEmpty) {
      throw FriendsException(404, 'Запись не найдена.');
    }
    throw FriendsException(response.statusCode, message.isEmpty ? 'Ошибка сервера' : message);
  }

  Future<FriendsSnapshot> getFriends() async {
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/friends'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'FriendsRepository.getFriends',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return FriendsSnapshot.fromJson(body);
  }

  Future<List<FriendSearchItem>> searchUsers(String query, {int limit = 20}) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/friends/search').replace(
          queryParameters: {'q': q, 'limit': '$limit'},
        ),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'FriendsRepository.searchUsers',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['users'] as List<dynamic>? ?? const [];
    return list
        .map((e) => FriendSearchItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> sendRequest(String targetUserID) async {
    await _postAction(
      endpoint: '/api/friends/request',
      body: {'target_user_id': targetUserID},
      operation: 'FriendsRepository.sendRequest',
      expectedStatusCode: 201,
    );
  }

  Future<void> acceptRequest(String requestID) async {
    await _postAction(
      endpoint: '/api/friends/accept',
      body: {'request_id': requestID},
      operation: 'FriendsRepository.acceptRequest',
      expectedStatusCode: 204,
    );
  }

  Future<void> rejectRequest(String requestID) async {
    await _postAction(
      endpoint: '/api/friends/reject',
      body: {'request_id': requestID},
      operation: 'FriendsRepository.rejectRequest',
      expectedStatusCode: 204,
    );
  }

  Future<void> cancelRequest(String requestID) async {
    await _postAction(
      endpoint: '/api/friends/cancel',
      body: {'request_id': requestID},
      operation: 'FriendsRepository.cancelRequest',
      expectedStatusCode: 204,
    );
  }

  Future<void> removeFriend(String friendUserID) async {
    await _postAction(
      endpoint: '/api/friends/remove',
      body: {'friend_user_id': friendUserID},
      operation: 'FriendsRepository.removeFriend',
      expectedStatusCode: 204,
    );
  }

  Future<void> _postAction({
    required String endpoint,
    required Map<String, dynamic> body,
    required String operation,
    required int expectedStatusCode,
  }) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
        operation: operation,
      ),
    );
    if (response.statusCode != expectedStatusCode) {
      _throwForErrorResponse(response);
    }
  }
}

class FriendsException implements Exception {
  final int statusCode;
  final String message;
  FriendsException(this.statusCode, this.message);

  @override
  String toString() => message;
}
