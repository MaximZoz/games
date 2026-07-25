import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const tictactoeGamePathPrefix = '/games/tictactoe/game/';

final gameNavigationCoordinatorProvider =
    Provider<GameNavigationCoordinator>((ref) {
  return GameNavigationCoordinator();
});

class GameNavigationCoordinator {
  String? targetForGame(
    String? gameId, {
    required String currentPath,
    String? expectedLobbyId,
  }) {
    final normalizedId = gameId?.trim();
    if (normalizedId == null || normalizedId.isEmpty) return null;
    if (!_allowsAutomaticGameNavigation(
      currentPath,
      expectedLobbyId: expectedLobbyId,
    )) {
      return null;
    }

    final target = '$tictactoeGamePathPrefix$normalizedId';
    return currentPath == target ? null : target;
  }
}

bool navigateToGame(
  GoRouter router,
  GameNavigationCoordinator coordinator,
  String? gameId, {
  String? expectedLobbyId,
}) {
  final currentPath = router.routerDelegate.currentConfiguration.uri.path;
  final target = coordinator.targetForGame(
    gameId,
    currentPath: currentPath,
    expectedLobbyId: expectedLobbyId,
  );
  if (target == null) return false;
  router.go(target);
  return true;
}

String? realtimeGameIdForNavigation(
  Map<String, dynamic> event, {
  required String currentPath,
  String? expectedLobbyId,
}) {
  final type = event['type']?.toString();
  if (type != 'game_started' && type != 'lobby_updated') return null;
  if (!_allowsAutomaticGameNavigation(
    currentPath,
    expectedLobbyId: expectedLobbyId,
  )) {
    return null;
  }

  final currentLobbyId = _lobbyIdFromPath(currentPath);
  if (currentLobbyId != null &&
      event['lobby_id']?.toString().trim() != currentLobbyId) {
    return null;
  }

  final gameId = event['game_id']?.toString().trim();
  return gameId == null || gameId.isEmpty ? null : gameId;
}

bool _allowsAutomaticGameNavigation(
  String currentPath, {
  String? expectedLobbyId,
}) {
  if (expectedLobbyId != null) {
    return currentPath == '/games/tictactoe/lobby/$expectedLobbyId';
  }
  return currentPath == '/games' ||
      currentPath.startsWith('/games/tictactoe/lobby/');
}

String? _lobbyIdFromPath(String currentPath) {
  const prefix = '/games/tictactoe/lobby/';
  if (!currentPath.startsWith(prefix)) return null;
  final lobbyId = currentPath.substring(prefix.length).trim();
  return lobbyId.isEmpty || lobbyId.contains('/') ? null : lobbyId;
}
