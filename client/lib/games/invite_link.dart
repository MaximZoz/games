/// Публичная ссылка на invite-лобби «Своя игра».
String buildInviteLobbyShareUrl({
  required String lobbyId,
  required Uri baseUri,
}) {
  final id = lobbyId.trim();
  final origin = baseUri.origin;
  return '$origin/games/tictactoe/lobby/$id?mode=invite';
}

/// Распарсенная ссылка-приглашение в лобби крестиков-ноликов.
class InviteLobbyLink {
  const InviteLobbyLink({
    required this.lobbyId,
    required this.appPath,
  });

  final String lobbyId;

  /// Путь приложения: `/games/tictactoe/lobby/{id}?mode=invite`.
  final String appPath;
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
  if (segments[0] != 'games' ||
      segments[1] != 'tictactoe' ||
      segments[2] != 'lobby') {
    return null;
  }
  final id = segments[3].trim();
  if (id.isEmpty) return null;
  // UUID или иной id лобби без пробелов/слэшей.
  if (id.contains('/') || id.contains(' ')) return null;

  return InviteLobbyLink(
    lobbyId: id,
    appPath: '/games/tictactoe/lobby/$id?mode=invite',
  );
}

bool isInviteLobbyMessage(String body) =>
    parseInviteLobbyShareUrl(body) != null;
