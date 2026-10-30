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

/// Тег баннера приглашения: тип игры в теге, чтобы iPhone без `url`
/// открыл Уно, а не крестики.
String gameInviteNotificationTag({
  required String gameType,
  required String lobbyId,
}) {
  final id = lobbyId.trim();
  if (id.isEmpty) return 'game_invite';
  final gt = gameType.trim();
  if (!_isPathToken(gt)) return 'game_invite_$id';
  return 'game_invite_$gt:$id';
}

bool _isPathToken(String value) => RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value);

/// Как `pathFromTag` в `push-sw.js`.
String? pathFromTag(String tag) {
  final t = tag.trim();
  if (t.startsWith('chat_')) {
    final id = t.substring('chat_'.length);
    return id.isEmpty ? '/chats' : '/chats/$id';
  }
  if (t == 'friend_request') return '/friends?tab=incoming';
  if (t.startsWith('game_invite_')) {
    final rest = t.substring('game_invite_'.length);
    if (rest.isEmpty) return '/games';
    final colon = rest.indexOf(':');
    if (colon > 0 && colon < rest.length - 1) {
      final gt = rest.substring(0, colon);
      final id = rest.substring(colon + 1);
      if (_isPathToken(gt) && _isPathToken(id)) {
        return '/games/$gt/lobby/$id?mode=invite';
      }
    }
    // Старые баннеры без типа игры — крестики, как раньше.
    return '/games/tictactoe/lobby/$rest';
  }
  if (t.startsWith('game_turn_')) return '/games';
  if (t.startsWith('achievement_')) return '/achievements';
  if (t.startsWith('reward_gift_')) return '/inventory';
  if (t == 'daily_reward') return '/coins/login';
  if (t == 'collection_income') return '/inventory';
  return null;
}

/// Как `tagFromPath` в `push-sw.js`.
String? tagFromPath(String path) {
  final p = normalizeAppPath(path);
  final chat = RegExp(r'^/chats/([^/?#]+)').firstMatch(p);
  if (chat != null) return 'chat_${chat.group(1)}';
  if (p == '/friends' ||
      p.startsWith('/friends?') ||
      p.startsWith('/friends/')) {
    return 'friend_request';
  }
  final lobby = RegExp(
    r'^/games/([^/?#]+)/lobby/([^/?#]+)',
  ).firstMatch(p);
  if (lobby != null) {
    return gameInviteNotificationTag(
      gameType: lobby.group(1) ?? '',
      lobbyId: lobby.group(2) ?? '',
    );
  }
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

/// Совпадение с учётом query: `/games` ещё не вкладка «Лобби».
bool pushRouteReached(String current, String target) {
  if (!pathsMatch(current, target)) return false;
  final want = _queryOf(target);
  if (want.isEmpty) return true;
  final got = _queryOf(current);
  for (final entry in want.entries) {
    if (got[entry.key] != entry.value) return false;
  }
  return true;
}

Map<String, String> _queryOf(String raw) {
  final normalized = normalizeAppPath(raw);
  if (normalized.isEmpty) return const {};
  final uri = normalized.startsWith('/')
      ? Uri.tryParse('https://local.app$normalized')
      : Uri.tryParse(normalized);
  return uri?.queryParameters ?? const {};
}

/// «Игры» → вкладка «Лобби». `r` различает повторный заход,
/// пока экран игр уже открыт.
String gamesLobbiesTabLocation() {
  final stamp = DateTime.now().microsecondsSinceEpoch;
  return '/games?tab=lobbies&r=$stamp';
}

bool uriWantsGamesLobbiesTab(Uri uri) {
  return uri.path == '/games' && uri.queryParameters['tab'] == 'lobbies';
}

/// Пуш в стол не входит в игру: карточка «Вас пригласили» на вкладке «Лобби».
String notificationOpenPath(String path) {
  if (lobbyRouteFromPath(path) != null) return gamesLobbiesTabLocation();
  return path;
}

DateTime? _pushOpenedAt;

/// Тап по пушу уже выбрал чат или лобби — не уводить в свою «Своя игра».
void markPushOpenedRoute() {
  _pushOpenedAt = DateTime.now();
}

bool pushOpenedRouteRecently() {
  final at = _pushOpenedAt;
  if (at == null) return false;
  // Вход в лобби из пуша ждёт сеть: за это время вкладка «Игры»
  // не должна подменить маршрут своей партией.
  return DateTime.now().difference(at) < const Duration(seconds: 15);
}

/// Лобби из пути пуша. null — это не приглашение в стол.
class PushLobbyRoute {
  const PushLobbyRoute({required this.gameType, required this.lobbyId});

  final String gameType;
  final String lobbyId;
}

PushLobbyRoute? lobbyRouteFromPath(String path) {
  final bare = normalizeAppPath(path).split('?').first;
  final match = RegExp(r'^/games/([^/]+)/lobby/([^/]+)$').firstMatch(bare);
  if (match == null) return null;
  final gameType = match.group(1) ?? '';
  final lobbyId = match.group(2) ?? '';
  if (!_isPathToken(gameType) || !_isPathToken(lobbyId)) return null;
  return PushLobbyRoute(gameType: gameType, lobbyId: lobbyId);
}

/// Куда вёл бы пуш после входа в стол. Сейчас пуш в стол не входит:
/// [notificationOpenPath] открывает вкладку «Лобби».
String pushLobbyDestination({
  required String gameType,
  required String lobbyId,
  String? gameId,
  bool waitingMore = false,
}) {
  final id = (gameId ?? '').trim();
  if (id.isNotEmpty && !waitingMore) {
    return '/games/$gameType/game/$id';
  }
  return '/games/$gameType/lobby/$lobbyId?mode=invite';
}

/// Гость по ссылке: без `mode=invite` шапка лобби — «Своя игра».
String attachLobbyInviteMode(String path) {
  final normalized = normalizeAppPath(path);
  final bare = normalized.split('?').first;
  if (!RegExp(r'^/games/[^/]+/lobby/[^/]+$').hasMatch(bare)) {
    return normalized;
  }
  if (RegExp(r'(^|[?&])mode=').hasMatch(normalized)) return normalized;
  final sep = normalized.contains('?') ? '&' : '?';
  return '$normalized${sep}mode=invite';
}

/// Чат из пуша: имя собеседника в query, чтобы шапка не была «Диалог».
String attachChatPeerName(String path, String? title) {
  final normalized = normalizeAppPath(path);
  final bare = normalized.split('?').first;
  if (!RegExp(r'^/chats/[^/]+$').hasMatch(bare)) return normalized;
  if (RegExp(r'(^|[?&])name=').hasMatch(normalized)) return normalized;
  final name = (title ?? '').trim();
  if (name.isEmpty) return normalized;
  final sep = normalized.contains('?') ? '&' : '?';
  return '$normalized${sep}name=${Uri.encodeQueryComponent(name)}';
}

/// Тап по баннеру iPhone: поля FCM, а если их нет — payload локального баннера.
String? pathFromIosTap(Map<String, String> data) {
  final direct = pathFromPushData(data);
  if (direct != null && direct.isNotEmpty && direct != '/') return direct;
  final payload = data['payload']?.trim() ?? '';
  if (payload.isEmpty) return direct;
  return pathFromNotificationPayload(payload);
}

/// `url` → `chat_id` → `game_type`+`lobby_id` → `tag`, как в iOS PWA.
String? pathFromPushData(Map<String, dynamic> data) {
  final title = data['title']?.toString();
  String? path;
  final url = data['url']?.toString().trim() ?? '';
  if (url.isNotEmpty) {
    path = normalizeAppPath(url);
  } else {
    final chatId = data['chat_id']?.toString().trim() ?? '';
    if (chatId.isNotEmpty && _isPathToken(chatId)) {
      path = '/chats/$chatId';
    } else {
      final gameType = data['game_type']?.toString().trim() ?? '';
      final lobbyId = data['lobby_id']?.toString().trim() ?? '';
      if (_isPathToken(gameType) && _isPathToken(lobbyId)) {
        path = '/games/$gameType/lobby/$lobbyId';
      } else {
        path = pathFromTag(data['tag']?.toString() ?? '');
      }
    }
  }
  if (path == null || path.isEmpty) return null;
  return attachChatPeerName(attachLobbyInviteMode(path), title);
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
