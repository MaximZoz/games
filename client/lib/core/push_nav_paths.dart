import 'dart:convert';

/// Общие path/tag для PWA SW и Android (Gmail: один баннер на тред).
String normalizeAppPath(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '/';
  if (trimmed.startsWith('/')) return trimmed;
  try {
    final uri = Uri.parse(trimmed);
    if (uri.hasScheme && uri.host.isNotEmpty) {
      final path = uri.path.isEmpty ? '/' : uri.path;
      final q = uri.hasQuery ? '?${uri.query}' : '';
      final f = uri.hasFragment ? '#${uri.fragment}' : '';
      return '$path$q$f';
    }
  } catch (_) {}
  return trimmed.startsWith('/') ? trimmed : '/$trimmed';
}

/// Как `pathFromTag` в `push-sw.js`.
String? pathFromTag(String tag) {
  final t = tag.trim();
  if (t.startsWith('chat_')) {
    final id = t.substring('chat_'.length);
    return id.isEmpty ? '/chats' : '/chats/$id';
  }
  if (t == 'friend_request') return '/friends?tab=incoming';
  if (t.startsWith('game_invite_')) {
    final lobbyId = t.substring('game_invite_'.length);
    return lobbyId.isEmpty ? '/games' : '/games/tictactoe/lobby/$lobbyId';
  }
  if (t.startsWith('game_turn_')) return '/games';
  if (t.startsWith('achievement_')) return '/achievements';
  if (t.startsWith('reward_gift_')) return '/inventory';
  if (t == 'daily_reward') return '/coins/login';
  return null;
}

/// Как `tagFromPath` в `push-sw.js`.
String? tagFromPath(String path) {
  final p = normalizeAppPath(path);
  final chat = RegExp(r'^/chats/([^/?#]+)').firstMatch(p);
  if (chat != null) return 'chat_${chat.group(1)}';
  if (p == '/friends' || p.startsWith('/friends?') || p.startsWith('/friends/')) {
    return 'friend_request';
  }
  final lobby = RegExp(
    r'^/games/([^/?#]+)/lobby/([^/?#]+)',
  ).firstMatch(p);
  if (lobby != null) return 'game_invite_${lobby.group(2)}';
  final game = RegExp(
    r'^/games/([^/?#]+)/game/([^/?#]+)',
  ).firstMatch(p);
  if (game != null) return 'game_turn_${game.group(2)}';
  if (p == '/coins/login' || p.startsWith('/coins/login?')) {
    return 'daily_reward';
  }
  return null;
}

int pathSpecificity(String path) {
  final p = normalizeAppPath(path);
  if (p.isEmpty || p == '/') return 0;
  if (p == '/chats' || p == '/games' || p == '/friends') return 1;
  if (RegExp(r'^/chats/[^/?#]+').hasMatch(p)) return 3;
  if (RegExp(r'^/games/[^/?#]+/(game|lobby)/[^/?#]+').hasMatch(p)) return 3;
  return 2;
}

bool pathsMatch(String current, String target) {
  final a = normalizeAppPath(current).split('?').first;
  final b = normalizeAppPath(target).split('?').first;
  if (a.isEmpty || b.isEmpty || a == '/' || b == '/') return a == b;
  return a == b;
}

/// `url` → `chat_id` → `tag`, как в iOS PWA.
String? pathFromPushData(Map<String, dynamic> data) {
  final url = data['url']?.toString().trim() ?? '';
  if (url.isNotEmpty) return normalizeAppPath(url);
  final chatId = data['chat_id']?.toString().trim() ?? '';
  if (chatId.isNotEmpty) return '/chats/$chatId';
  final tag = data['tag']?.toString() ?? '';
  return pathFromTag(tag);
}

String? pathFromNotificationPayload(String? payload) {
  if (payload == null) return null;
  final raw = payload.trim();
  if (raw.isEmpty) return null;
  if (raw.startsWith('/')) return normalizeAppPath(raw);
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return pathFromPushData(Map<String, dynamic>.from(decoded));
    }
  } catch (_) {}
  return normalizeAppPath(raw);
}

String encodeNotificationPayload({
  required String url,
  required String tag,
  String? chatId,
}) {
  return jsonEncode({
    'url': url,
    'tag': tag,
    if (chatId != null && chatId.isNotEmpty) 'chat_id': chatId,
  });
}

int notificationIdForTag(String tag) => tag.hashCode & 0x7fffffff;
