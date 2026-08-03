/// Публичная ссылка на invite-лобби «Своя игра».
String buildInviteLobbyShareUrl({
  required String lobbyId,
  required Uri baseUri,
  String gameType = 'tictactoe',
}) {
  final id = lobbyId.trim();
  final origin = baseUri.origin;
  return '$origin/games/$gameType/lobby/$id?mode=invite';
}

/// Сокращённая форма (без baseUri) — использует относительный путь.
String buildInviteLink(String lobbyId, {String gameType = 'tictactoe'}) {
  final id = lobbyId.trim();
  return '/games/$gameType/lobby/$id?mode=invite';
}

/// Распарсенная ссылка-приглашение в лобби.
class InviteLobbyLink {
  const InviteLobbyLink({
    required this.lobbyId,
    required this.appPath,
    this.gameType = 'tictactoe',
  });

  final String lobbyId;
  final String gameType;

  /// Путь приложения: `/games/{game}/lobby/{id}?mode=invite`.
  final String appPath;

  /// Путь с id сообщения чата — после «Войти в игру» сообщение удалится.
  String appPathFromMessage(String messageId) {
    final id = messageId.trim();
    if (id.isEmpty) return appPath;
    final sep = appPath.contains('?') ? '&' : '?';
    return '$appPath${sep}from_message=${Uri.encodeComponent(id)}';
  }
}

/// Если [raw] — целиком ссылка на invite-лобби (абсолютная или относительная).
InviteLobbyLink? parseInviteLobbyShareUrl(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;

  Uri? uri;
  if (t.startsWith('http://') || t.startsWith('https://')) {
    uri = Uri.tryParse(t);
  } else if (t.startsWith('/games/')) {
    uri = Uri.tryParse('https://local.app$t');
  } else {
    return null;
  }
  if (uri == null) return null;

  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length < 4) return null;
  if (segments[0] != 'games' || segments[2] != 'lobby') return null;
  final gt = segments[1];
  if (gt != 'tictactoe' && gt != 'durak') return null;
  final id = segments[3].trim();
  if (id.isEmpty) return null;
  if (id.contains('/') || id.contains(' ')) return null;

  return InviteLobbyLink(
    lobbyId: id,
    gameType: gt,
    appPath: '/games/$gt/lobby/$id?mode=invite',
  );
}

bool isInviteLobbyMessage(String body) =>
    parseInviteLobbyShareUrl(body) != null;
