import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/push_nav_paths.dart';
import 'package:multigames_client/games/battleship/battleship_provider.dart';
import 'package:multigames_client/games/checkers/checkers_provider.dart';
import 'package:multigames_client/games/chess/chess_provider.dart';
import 'package:multigames_client/games/domino/domino_provider.dart';
import 'package:multigames_client/games/durak/durak_provider.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/lobby_guest.dart';
import 'package:multigames_client/games/nardy/nardy_provider.dart';
import 'package:multigames_client/games/poker/poker_provider.dart';
import 'package:multigames_client/games/uno/uno_provider.dart';

/// Ссылка `?mode=invite` или карточка из чата. Хозяин стола сюда не попадает:
/// у него тот же query, но он уже в составе.
bool uriOpensGuestInvite(Uri uri) {
  if (lobbyRouteFromPath(uri.toString()) == null) return false;
  if (uri.queryParameters['mode'] == 'invite') return true;
  return (uri.queryParameters['from_message'] ?? '').trim().isNotEmpty;
}

class InviteLobbyPeek {
  const InviteLobbyPeek({required this.isMember, this.invite});

  final bool isMember;
  final GameInvite? invite;
}

/// Куда увести гостя. null — оставить лобби (хозяин, ошибка сети, не ссылка).
Future<String?> redirectGuestInviteLocation({
  required Uri uri,
  required String? userId,
  required Future<InviteLobbyPeek?> Function(PushLobbyRoute route) load,
  void Function(GameInvite invite)? holdInvite,
}) async {
  final id = userId?.trim() ?? '';
  if (id.isEmpty || !uriOpensGuestInvite(uri)) return null;
  final route = lobbyRouteFromPath(uri.toString());
  if (route == null) return null;
  final peek = await load(route);
  if (peek == null || peek.isMember) return null;
  final invite = peek.invite;
  if (invite != null) holdInvite?.call(invite);
  return gamesLobbiesTabLocation();
}

final Map<String, DateTime> _memberLobbyUntil = {};

bool _cachedMember(String key) {
  final until = _memberLobbyUntil[key];
  if (until == null) return false;
  if (DateTime.now().isAfter(until)) {
    _memberLobbyUntil.remove(key);
    return false;
  }
  return true;
}

/// Гость по ссылке не входит в стол: «Игры» → «Лобби» и карточка приглашения.
Future<String?> redirectGuestInviteIfNeeded(Ref ref, Uri uri) async {
  final userId = ref.read(authStateProvider).valueOrNull?.id;
  final route = lobbyRouteFromPath(uri.toString());
  if (userId == null ||
      userId.isEmpty ||
      route == null ||
      !uriOpensGuestInvite(uri)) {
    return null;
  }
  final cacheKey = '$userId|${route.gameType}|${route.lobbyId}';
  if (_cachedMember(cacheKey)) return null;
  final peek = await loadInviteLobbyPeek(ref, route, userId);
  if (peek == null) return null;
  if (peek.isMember) {
    _memberLobbyUntil[cacheKey] =
        DateTime.now().add(const Duration(seconds: 2));
    return null;
  }
  final invite = peek.invite;
  if (invite != null) {
    ref.read(gameInvitesProvider.notifier).hold(invite);
  }
  return gamesLobbiesTabLocation();
}

Future<InviteLobbyPeek?> loadInviteLobbyPeek(
  Ref ref,
  PushLobbyRoute route,
  String userId,
) async {
  try {
    return await _load(ref, route, userId);
  } catch (_) {
    return null;
  }
}

Future<InviteLobbyPeek?> _load(
  Ref ref,
  PushLobbyRoute route,
  String userId,
) async {
  final id = route.lobbyId;
  switch (route.gameType) {
    case 'durak':
      final lobby = await ref.read(durakRepositoryProvider).getLobby(id);
      return _peek(
        userId: userId,
        gameType: 'durak',
        lobbyId: lobby.id.isEmpty ? id : lobby.id,
        creatorId: lobby.creatorId,
        status: lobby.status,
        playerIds: lobby.playerIds,
        players: lobby.players,
        turnTimeSec: lobby.turnTimeSec,
        stakeBronze: lobby.stakeBronze,
        maxPlayers: lobby.maxPlayers,
        deckSize: lobby.deckSize,
        durakMode: lobby.gameMode,
      );
    case 'battleship':
      final lobby = await ref.read(battleshipRepositoryProvider).getLobby(id);
      return _peek(
        userId: userId,
        gameType: 'battleship',
        lobbyId: lobby.id.isEmpty ? id : lobby.id,
        creatorId: lobby.creatorId,
        status: lobby.status,
        playerIds: lobby.playerIds,
        players: lobby.players,
        turnTimeSec: lobby.turnTimeSec,
        stakeBronze: lobby.stakeBronze,
        firstMoveRestriction: lobby.firstMoveRestriction,
      );
    case 'poker':
      final lobby = await ref.read(pokerRepositoryProvider).getLobby(id);
      return _peek(
        userId: userId,
        gameType: 'poker',
        lobbyId: lobby.id.isEmpty ? id : lobby.id,
        creatorId: lobby.creatorId,
        status: lobby.status,
        playerIds: lobby.playerIds,
        players: lobby.players,
        turnTimeSec: lobby.turnTimeSec,
        stakeBronze: lobby.stakeBronze,
        maxPlayers: lobby.maxPlayers,
      );
    case 'uno':
      final lobby = await ref.read(unoRepositoryProvider).getLobby(id);
      return _peek(
        userId: userId,
        gameType: 'uno',
        lobbyId: lobby.id.isEmpty ? id : lobby.id,
        creatorId: lobby.creatorId,
        status: lobby.status,
        playerIds: lobby.playerIds,
        players: lobby.players,
        turnTimeSec: lobby.turnTimeSec,
        stakeBronze: lobby.stakeBronze,
        maxPlayers: lobby.maxPlayers,
      );
    case 'domino':
      final lobby = await ref.read(dominoRepositoryProvider).getLobby(id);
      return _peek(
        userId: userId,
        gameType: 'domino',
        lobbyId: lobby.id.isEmpty ? id : lobby.id,
        creatorId: lobby.creatorId,
        status: lobby.status,
        playerIds: lobby.playerIds,
        players: lobby.players,
        turnTimeSec: lobby.turnTimeSec,
        stakeBronze: lobby.stakeBronze,
        maxPlayers: lobby.maxPlayers,
        durakMode: lobby.gameMode,
      );
    case 'nardy':
      final lobby = await ref.read(nardyRepositoryProvider).getLobby(id);
      return _peek(
        userId: userId,
        gameType: 'nardy',
        lobbyId: lobby.id.isEmpty ? id : lobby.id,
        creatorId: lobby.creatorId,
        status: lobby.status,
        playerIds: lobby.playerIds,
        players: lobby.players,
        turnTimeSec: lobby.turnTimeSec,
        stakeBronze: lobby.stakeBronze,
        durakMode: lobby.gameMode,
      );
    case 'checkers':
      final lobby = await ref.read(checkersRepositoryProvider).getLobby(id);
      return _peek(
        userId: userId,
        gameType: 'checkers',
        lobbyId: lobby.id.isEmpty ? id : lobby.id,
        creatorId: lobby.creatorId,
        status: lobby.status,
        playerIds: lobby.playerIds,
        players: lobby.players,
        turnTimeSec: lobby.turnTimeSec,
        stakeBronze: lobby.stakeBronze,
        durakMode: lobby.gameMode,
      );
    case 'chess':
      final lobby = await ref.read(chessRepositoryProvider).getLobby(id);
      return _peek(
        userId: userId,
        gameType: 'chess',
        lobbyId: lobby.id.isEmpty ? id : lobby.id,
        creatorId: lobby.creatorId,
        status: lobby.status,
        playerIds: lobby.playerIds,
        players: lobby.players,
        turnTimeSec: lobby.turnTimeSec,
        stakeBronze: lobby.stakeBronze,
        durakMode: lobby.gameMode,
      );
    default:
      final lobby = await ref.read(gamesRepositoryProvider).getLobby(id);
      return _peek(
        userId: userId,
        gameType: 'tictactoe',
        lobbyId: lobby.id.isEmpty ? id : lobby.id,
        creatorId: lobby.creatorId,
        creatorName: lobby.creatorName,
        status: lobby.status,
        playerIds: lobby.playerIds,
        players: lobby.players,
        opponentId: lobby.opponentId,
        turnTimeSec: lobby.turnTimeSec,
        stakeBronze: lobby.stakeBronze,
        maxPlayers: lobby.maxPlayers,
        variant: lobby.variant,
        gridSize: lobby.gridSize,
        swapRule: lobby.swapRule,
        firstMoveRestriction: lobby.firstMoveRestriction,
      );
  }
}

InviteLobbyPeek _peek({
  required String userId,
  required String gameType,
  required String lobbyId,
  required String creatorId,
  required String status,
  required List<String> playerIds,
  required List<LobbyPlayer> players,
  String? creatorName,
  String? opponentId,
  int turnTimeSec = 0,
  int stakeBronze = 2,
  int maxPlayers = 2,
  String variant = 'classic',
  int gridSize = 3,
  bool swapRule = false,
  bool firstMoveRestriction = false,
  int deckSize = 36,
  String durakMode = 'podkidnoi',
}) {
  final member = lobbyUserIsMember(
    userId: userId,
    creatorId: creatorId,
    playerIds: playerIds,
    players: players,
    opponentId: opponentId,
  );
  return InviteLobbyPeek(
    isMember: member,
    invite: member
        ? null
        : waitingInviteCard(
            lobbyId: lobbyId,
            gameType: gameType,
            status: status,
            creatorId: creatorId,
            creatorName: creatorName ?? '',
            players: players,
            turnTimeSec: turnTimeSec,
            stakeBronze: stakeBronze,
            maxPlayers: maxPlayers,
            variant: variant,
            gridSize: gridSize,
            swapRule: swapRule,
            firstMoveRestriction: firstMoveRestriction,
            deckSize: deckSize,
            durakMode: durakMode,
          ),
  );
}

/// Карточка «Вас пригласили», пока стол ещё ждёт. null — игра уже началась.
GameInvite? waitingInviteCard({
  required String lobbyId,
  required String gameType,
  required String status,
  required String creatorId,
  required String creatorName,
  required List<LobbyPlayer> players,
  int turnTimeSec = 0,
  int stakeBronze = 2,
  int maxPlayers = 2,
  String variant = 'classic',
  int gridSize = 3,
  bool swapRule = false,
  bool firstMoveRestriction = false,
  int deckSize = 36,
  String durakMode = 'podkidnoi',
}) {
  if (status != 'waiting_invite' && status != 'waiting_matchmake') {
    return null;
  }
  final creator = creatorId.trim();
  final id = lobbyId.trim();
  if (creator.isEmpty || id.isEmpty) return null;
  var name = creatorName.trim();
  var avatarKind = 'letter';
  String? avatarValue;
  for (final player in players) {
    if (player.id != creator) continue;
    if (name.isEmpty) name = player.displayName.trim();
    avatarKind = player.avatarKind;
    avatarValue = player.avatarValue;
    break;
  }
  return GameInvite(
    lobbyId: id,
    creatorId: creator,
    creatorName: name,
    gameType: gameType,
    turnTimeSec: turnTimeSec,
    variant: variant,
    gridSize: gridSize,
    maxPlayers: maxPlayers,
    swapRule: swapRule,
    firstMoveRestriction: firstMoveRestriction,
    creatorAvatarKind: avatarKind,
    creatorAvatarValue: avatarValue,
    stakeBronze: stakeBronze,
    deckSize: deckSize,
    durakMode: durakMode,
  );
}
