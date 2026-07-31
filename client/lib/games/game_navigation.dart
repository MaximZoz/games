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

  final eventLobbyId = event['lobby_id']?.toString().trim();
  // Watcher конкретного лобби: чужие события не трогаем.
  if (expectedLobbyId != null &&
      eventLobbyId != null &&
      eventLobbyId.isNotEmpty &&
      eventLobbyId != expectedLobbyId) {
    return null;
  }

  final currentLobbyId = _lobbyIdFromPath(currentPath);
  if (currentLobbyId != null &&
      eventLobbyId != null &&
      eventLobbyId.isNotEmpty &&
      eventLobbyId != currentLobbyId) {
    return null;
  }

  final gameId = event['game_id']?.toString().trim();
  return gameId == null || gameId.isEmpty ? null : gameId;
}

/// Авто-вход в партию с любой вкладки (чаты, друзья, главная…),
/// кроме экранов авторизации. Иначе создатель инвайта, ушедший со страницы
/// лобби, не попадает в игру, когда соперник принял приглашение.
bool _allowsAutomaticGameNavigation(
  String currentPath, {
  String? expectedLobbyId,
}) {
  if (_isAuthOrPublicPath(currentPath)) return false;
  // expectedLobbyId ограничивает только совпадение lobby_id в событии
  // (см. realtimeGameIdForNavigation), а не текущий URL — пользователь
  // мог переключить вкладку, пока лобби ещё ждёт.
  return true;
}

bool _isAuthOrPublicPath(String path) {
  return path == '/login' ||
      path == '/register' ||
      path == '/verify-email' ||
      path == '/forgot-password' ||
      path == '/reset-password' ||
      path == '/oauth/callback';
}

String? _lobbyIdFromPath(String currentPath) {
  const prefix = '/games/tictactoe/lobby/';
  if (!currentPath.startsWith(prefix)) return null;
  final lobbyId = currentPath.substring(prefix.length).trim();
  return lobbyId.isEmpty || lobbyId.contains('/') ? null : lobbyId;
}
