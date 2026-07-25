/// Публичная ссылка на invite-лобби «Своя игра».
String buildInviteLobbyShareUrl({
  required String lobbyId,
  required Uri baseUri,
}) {
  final id = lobbyId.trim();
  final origin = baseUri.origin;
  return '$origin/games/tictactoe/lobby/$id?mode=invite';
}
