import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';

class ChatUserItem {
  final String id;
  final String? displayName;
  final String avatarKind;
  final String? avatarValue;
  final int? age;
  final String? gender;
  final String? about;
  final String? frameColor;
  final String? frameCode;
  final bool? isOnline;
  final String? lastSeenAt;

  ChatUserItem({
    required this.id,
    this.displayName,
    this.avatarKind = 'letter',
    this.avatarValue,
    this.age,
    this.gender,
    this.about,
    this.frameColor,
    this.frameCode,
    this.isOnline,
    this.lastSeenAt,
  });

  ChatUserItem copyWith({
    String? id,
    String? displayName,
    String? avatarKind,
    String? avatarValue,
    int? age,
    String? gender,
    String? about,
    String? frameColor,
    String? frameCode,
    bool? isOnline,
    String? lastSeenAt,
  }) {
    return ChatUserItem(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarKind: avatarKind ?? this.avatarKind,
      avatarValue: avatarValue ?? this.avatarValue,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      about: about ?? this.about,
      frameColor: frameColor ?? this.frameColor,
      frameCode: frameCode ?? this.frameCode,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  factory ChatUserItem.fromJson(Map<String, dynamic> json) {
    return ChatUserItem(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String?,
      avatarKind: json['avatar_kind'] as String? ?? 'letter',
      avatarValue: json['avatar_value'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      about: json['about'] as String?,
      frameColor: json['frame_color'] as String?,
      frameCode: json['frame_code'] as String?,
    );
  }
}

class ChatMessageItem {
  final String id;
  final String chatID;
  final String senderUserID;
  final String body;
  final String createdAt;
  final String? deliveredAt;
  final String? readAt;
  final String? editedAt;
  final String? replyToMessageID;
  final bool hasImage;
  final String? replyToBody;
  final bool replyToHasImage;
  final String? replyToSenderID;

  ChatMessageItem({
    required this.id,
    required this.chatID,
    required this.senderUserID,
    required this.body,
    required this.createdAt,
    this.deliveredAt,
    this.readAt,
    this.editedAt,
    this.replyToMessageID,
    this.hasImage = false,
    this.replyToBody,
    this.replyToHasImage = false,
    this.replyToSenderID,
  });

  factory ChatMessageItem.fromJson(Map<String, dynamic> json) {
    return ChatMessageItem(
      id: json['id'] as String? ?? '',
      chatID: json['chat_id'] as String? ?? '',
      senderUserID: json['sender_user_id'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      deliveredAt: json['delivered_at'] as String?,
      readAt: json['read_at'] as String?,
      editedAt: json['edited_at'] as String?,
      replyToMessageID: json['reply_to_message_id'] as String?,
      hasImage: json['has_image'] as bool? ?? false,
      replyToBody: json['reply_to_body'] as String?,
      replyToHasImage: json['reply_to_has_image'] as bool? ?? false,
      replyToSenderID: json['reply_to_sender_id'] as String?,
    );
  }

  ChatMessageItem copyWith({
    String? body,
    String? deliveredAt,
    String? readAt,
    String? editedAt,
    bool clearDeliveredAt = false,
    bool clearReadAt = false,
    bool? hasImage,
    String? replyToMessageID,
    String? replyToBody,
    bool? replyToHasImage,
    String? replyToSenderID,
  }) {
    return ChatMessageItem(
      id: id,
      chatID: chatID,
      senderUserID: senderUserID,
      body: body ?? this.body,
      createdAt: createdAt,
      deliveredAt: clearDeliveredAt ? null : (deliveredAt ?? this.deliveredAt),
      readAt: clearReadAt ? null : (readAt ?? this.readAt),
      editedAt: editedAt ?? this.editedAt,
      replyToMessageID: replyToMessageID ?? this.replyToMessageID,
      hasImage: hasImage ?? this.hasImage,
      replyToBody: replyToBody ?? this.replyToBody,
      replyToHasImage: replyToHasImage ?? this.replyToHasImage,
      replyToSenderID: replyToSenderID ?? this.replyToSenderID,
    );
  }

  String get previewText {
    final t = body.trim();
    if (hasImage && t.isEmpty) return 'Фото';
    if (hasImage) return 'Фото: $t';
    return t;
  }
}

class ChatPreviewItem {
  final String chatID;
  final ChatUserItem user;
  final ChatMessageItem? lastMessage;
  final int unreadCount;
  final String createdAt;
  final String updatedAt;

  ChatPreviewItem({
    required this.chatID,
    required this.user,
    required this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  ChatPreviewItem copyWith({
    ChatMessageItem? lastMessage,
    int? unreadCount,
    String? updatedAt,
  }) {
    return ChatPreviewItem(
      chatID: chatID,
      user: user,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ChatPreviewItem.fromJson(Map<String, dynamic> json) {
    return ChatPreviewItem(
      chatID: json['chat_id'] as String? ?? '',
      user: ChatUserItem.fromJson(Map<String, dynamic>.from((json['user'] ?? const {}) as Map)),
      lastMessage: json['last_message'] == null
          ? null
          : ChatMessageItem.fromJson(
              Map<String, dynamic>.from((json['last_message'] ?? const {}) as Map),
            ),
      unreadCount: json['unread_count'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class BlockedChatUserItem {
  final ChatUserItem user;
  final String blockedAt;

  BlockedChatUserItem({
    required this.user,
    required this.blockedAt,
  });

  factory BlockedChatUserItem.fromJson(Map<String, dynamic> json) {
    return BlockedChatUserItem(
      user: ChatUserItem.fromJson(Map<String, dynamic>.from((json['user'] ?? const {}) as Map)),
      blockedAt: json['blocked_at'] as String? ?? '',
    );
  }
}

class ChatsRepository {
  ChatsRepository({required AuthRepository authRepository})
      : _auth = authRepository;

  final AuthRepository _auth;

  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(String token) request,
  ) async {
    try {
      return await _auth.sendAuthorized(request);
    } on AuthException catch (e) {
      throw ChatException(
        e.statusCode,
        e.statusCode == 401 ? 'Сессия истекла. Войдите заново.' : e.message,
      );
    }
  }

  static String _translateMessage(String msg) {
    final m = msg.toLowerCase().trim();
    if (m.contains('only friends can send text')) {
      return 'Текст только для друзей';
    }
    const Map<String, String> map = {
      'cannot chat with yourself': 'Нельзя написать самому себе',
      'message is empty': 'Сообщение не может быть пустым',
      'message is too long': 'Сообщение слишком длинное',
      'image is too large': 'Изображение слишком большое',
      'unsupported image type': 'Неподдерживаемый тип изображения',
      'invalid reply target': 'Нельзя ответить на это сообщение',
      'cannot edit this message': 'Нельзя изменить это сообщение',
      'cannot delete this message': 'Нельзя удалить это сообщение',
      'cannot block yourself': 'Нельзя заблокировать самого себя',
      'forbidden': 'Недостаточно прав',
      'user is blocked': 'Пользователь заблокирован',
      'user not found': 'Пользователь не найден',
      'message not found': 'Сообщение не найдено',
      'image not found': 'Изображение не найдено',
      'not found': 'Не найдено',
      'server error': 'Ошибка сервера. Попробуйте позже.',
    };
    return map[m] ?? msg;
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
      throw ChatException(401, 'Сессия истекла. Войдите заново.');
    }
    final translated = message.isEmpty ? 'Ошибка сервера' : _translateMessage(message);
    throw ChatException(response.statusCode, translated);
  }

  Future<List<ChatPreviewItem>> listChats({int limit = 100, int offset = 0}) async {
    final query = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
    };
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/chats').replace(queryParameters: query),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ChatsRepository.listChats',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['chats'] as List<dynamic>? ?? const [];
    return list
        .map((e) => ChatPreviewItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<String> startChat(String targetUserID) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/chats/start'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'target_user_id': targetUserID}),
        operation: 'ChatsRepository.startChat',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['chat_id'] as String? ?? '';
  }

  Future<void> clearChat(String chatID) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/chats/clear'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'chat_id': chatID}),
        operation: 'ChatsRepository.clearChat',
      ),
    );
    if (response.statusCode != 204) {
      _throwForErrorResponse(response);
    }
  }

  Future<void> blockUser(String targetUserID) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/chats/block'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'target_user_id': targetUserID}),
        operation: 'ChatsRepository.blockUser',
      ),
    );
    if (response.statusCode != 204) {
      _throwForErrorResponse(response);
    }
  }

  Future<void> unblockUser(String targetUserID) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/chats/unblock'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'target_user_id': targetUserID}),
        operation: 'ChatsRepository.unblockUser',
      ),
    );
    if (response.statusCode != 204) {
      _throwForErrorResponse(response);
    }
  }

  Future<List<BlockedChatUserItem>> listBlockedUsers() async {
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/chats/blocked'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ChatsRepository.listBlockedUsers',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['blocked'] as List<dynamic>? ?? const [];
    return list
        .map((e) => BlockedChatUserItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<ChatMessageItem>> listMessages(
    String chatID, {
    int limit = 20,
    DateTime? before,
  }) async {
    final query = <String, String>{
      'chat_id': chatID,
      'limit': '$limit',
      if (before != null) 'before': before.toUtc().toIso8601String(),
    };

    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/chats/messages').replace(queryParameters: query),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ChatsRepository.listMessages',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['messages'] as List<dynamic>? ?? const [];
    return list
        .map((e) => ChatMessageItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ChatMessageItem> sendMessage(
    String chatID,
    String message, {
    String? replyToMessageID,
    String? imageBase64,
    String? imageMime,
  }) async {
    final payload = <String, dynamic>{
      'chat_id': chatID,
      'body': message,
      if (replyToMessageID != null && replyToMessageID.isNotEmpty)
        'reply_to_message_id': replyToMessageID,
      if (imageBase64 != null && imageBase64.isNotEmpty) ...{
        'image_base64': imageBase64,
        'image_mime': imageMime ?? 'image/jpeg',
      },
    };
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/chats/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
        operation: 'ChatsRepository.sendMessage',
      ),
    );
    if (response.statusCode != 201) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatMessageItem.fromJson(
      Map<String, dynamic>.from((body['message'] ?? const {}) as Map),
    );
  }

  Future<ChatMessageItem> editMessage(String messageID, String message) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/chats/messages/edit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'message_id': messageID, 'body': message}),
        operation: 'ChatsRepository.editMessage',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatMessageItem.fromJson(
      Map<String, dynamic>.from((body['message'] ?? const {}) as Map),
    );
  }

  Future<void> deleteMessage(String messageID) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/chats/messages/delete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'message_id': messageID}),
        operation: 'ChatsRepository.deleteMessage',
      ),
    );
    if (response.statusCode != 204) {
      _throwForErrorResponse(response);
    }
  }

  Future<List<int>> fetchMessageImageBytes(String messageID) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/chats/messages/image').replace(
          queryParameters: {'message_id': messageID},
        ),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ChatsRepository.fetchMessageImageBytes',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    return response.bodyBytes;
  }

  Future<int> markRead(String chatID) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/chats/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'chat_id': chatID}),
        operation: 'ChatsRepository.markRead',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['updated'] as int? ?? 0;
  }

  Future<int> markDelivered(String chatID) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/chats/delivered'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'chat_id': chatID}),
        operation: 'ChatsRepository.markDelivered',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['updated'] as int? ?? 0;
  }

  /// Возможности отправки в чат (учитывает «сообщения только от друзей» у собеседника).
  Future<ChatCapabilities> getCapabilities(String chatID) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/chats/capabilities').replace(
          queryParameters: {'chat_id': chatID},
        ),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ChatsRepository.getCapabilities',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatCapabilities.fromJson(body);
  }
}

class ChatCapabilities {
  final bool canSendText;
  final bool emojiOnly;

  const ChatCapabilities({
    this.canSendText = true,
    this.emojiOnly = false,
  });

  factory ChatCapabilities.fromJson(Map<String, dynamic> json) {
    final emojiOnly = json['emoji_only'] as bool? ?? false;
    final canSendText = json['can_send_text'] as bool? ?? !emojiOnly;
    return ChatCapabilities(
      canSendText: canSendText,
      emojiOnly: emojiOnly,
    );
  }
}

class ChatException implements Exception {
  final int statusCode;
  final String message;
  ChatException(this.statusCode, this.message);

  @override
  String toString() => message;
}
