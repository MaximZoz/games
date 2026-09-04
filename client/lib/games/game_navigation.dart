import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/framework/game_registry.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/shared_lobby.dart';

/// Возвращает префикс пути партии для game_type ('/games/<gt>/game/').
String gamePathPrefixFor(String gameType) {
  final id = gameRegistry.normalizeId(gameType);
  return '/games/$id/game/';
}

/// Префикс лобби для game_type.
String lobbyPathPrefixFor(String gameType) {
  final id = gameRegistry.normalizeId(gameType);
  return '/games/$id/lobby/';
}

/// Нормализованный game_type через реестр игр.
String normalizeGameType(String? gameType) =>
    gameRegistry.normalizeId(gameType);

/// Путь к партии: `/games/<type>/game/<id>`.
String gamePathFor(String gameId, {String gameType = 'tictactoe'}) {
  return gameRegistry.gamePath(gameId, gameType: gameType);
}

/// Путь к лобби: `/games/<type>/lobby/<id>`.
String lobbyPathFor(String lobbyId, {String gameType = 'tictactoe'}) {
  return gameRegistry.lobbyPath(lobbyId, gameType: gameType);
}

/// Экран лобби с query `mode`, чтобы шапка сразу была «Своя игра» / «Лобби».
String lobbyScreenPath(
  String lobbyId, {
  String gameType = 'tictactoe',
  String? mode,
}) {
  final path = lobbyPathFor(lobbyId, gameType: gameType);
  final normalized = normalizeLobbyMode(mode);
  if (normalized.isEmpty) return path;
  return '$path?mode=$normalized';
}

/// gameId из `/games/<type>/game/:id`.
String? gameIdFromGamePath(String? location) =>
    gameRegistry.gameIdFromPath(location);

/// game_type из пути партии/лобби/оффлайна, иначе null.
String? gameTypeFromGamePath(String? location) =>
    gameRegistry.gameTypeFromPath(location);

/// Куда вести вкладку «Игры». `null` — остаться на [currentPath].
///
/// Офлайн (`/games/<type>/offline`) и последняя живая партия важнее
/// каталога: иначе тап по «Игры» с профиля сбрасывает стол.
String? resolveGamesTabPath({
  required String currentPath,
  ActiveGameItem? active,
  String? pinnedLiveGameId,
  String? pinnedLiveGameType,
  String? observingGameId,
  String? lastSessionPath,
}) {
  final pathGameId = gameIdFromGamePath(currentPath);
  final pinned = pinnedLiveGameId?.trim() ?? '';
  final observing = observingGameId?.trim() ?? '';

  String? liveGameId;
  var liveGameType = 'tictactoe';
  if (active != null &&
      active.type == 'game' &&
      (active.gameId?.trim().isNotEmpty ?? false)) {
    liveGameId = active.gameId!.trim();
    liveGameType = normalizeGameType(active.gameType);
  } else if (pinned.isNotEmpty) {
    liveGameId = pinned;
    liveGameType = normalizeGameType(
      pinnedLiveGameType ?? gameTypeFromGamePath(currentPath),
    );
  }
  if (liveGameId != null && liveGameId.isNotEmpty) {
    final dest = gamePathFor(liveGameId, gameType: liveGameType);
    if (currentPath == dest || currentPath.startsWith('$dest/')) return null;
    return dest;
  }

  if (pathGameId != null &&
      observing.isNotEmpty &&
      pathGameId == observing) {
    return currentPath == '/games' ? null : '/games';
  }

  if (pathGameId != null) return null;
  if (gameRegistry.isActiveGamePath(currentPath)) return null;

  final last = lastSessionPath?.trim() ?? '';
  if (last.isNotEmpty && gameRegistry.isActiveGamePath(last)) {
    if (currentPath == last) return null;
    return last;
  }

  if (active != null &&
      active.type == 'lobby' &&
      active.lobbyId != null &&
      active.lobbyId!.isNotEmpty) {
    final dest = lobbyPathFor(
      active.lobbyId!,
      gameType: normalizeGameType(active.gameType),
    );
    if (currentPath == dest || currentPath.startsWith(dest)) return null;
    return lobbyScreenPath(
      active.lobbyId!,
      gameType: normalizeGameType(active.gameType),
      mode: active.mode,
    );
  }
  if (active == null &&
      (currentPath.startsWith('/games/tictactoe/lobby/') ||
          currentPath.startsWith('/games/durak/lobby/'))) {
    return null;
  }
  if (currentPath == '/games') return null;
  return '/games';
}

/// Совместимая константа для legacy-кода. Новый код — [gamePathPrefixFor].
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
    String gameType = 'tictactoe',
  }) {
    final normalizedId = gameId?.trim();
    if (normalizedId == null || normalizedId.isEmpty) return null;
    if (!_allowsAutomaticGameNavigation(
      currentPath,
      expectedLobbyId: expectedLobbyId,
    )) {
      return null;
    }

    final target = gamePathFor(normalizedId, gameType: gameType);
    return currentPath == target ? null : target;
  }
}

bool navigateToGame(
  GoRouter router,
  GameNavigationCoordinator coordinator,
  String? gameId, {
  String? expectedLobbyId,
  String gameType = 'tictactoe',
}) {
  final currentPath = router.routerDelegate.currentConfiguration.uri.path;
  final target = coordinator.targetForGame(
    gameId,
    currentPath: currentPath,
    expectedLobbyId: expectedLobbyId,
    gameType: gameType,
  );
  if (target == null) return false;
  router.go(target);
  return true;
}

/// Разрешение realtime-события в переход на партию: возвращает пару
/// (gameId, gameType) либо null.
class RealtimeGameNavTarget {
  const RealtimeGameNavTarget({
    required this.gameId,
    this.gameType = 'tictactoe',
  });
  final String gameId;
  final String gameType;
}

RealtimeGameNavTarget? realtimeGameNavForEvent(
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
  if (gameId == null || gameId.isEmpty) return null;
  final gt = event['game_type']?.toString().trim();
  return RealtimeGameNavTarget(
    gameId: gameId,
    gameType: normalizeGameType(gt),
  );
}

/// Совместимый API — только gameId. Используется в старом коде.
@Deprecated('Use realtimeGameNavForEvent for full gameType support')
String? realtimeGameIdForNavigation(
  Map<String, dynamic> event, {
  required String currentPath,
  String? expectedLobbyId,
}) {
  return realtimeGameNavForEvent(
    event,
    currentPath: currentPath,
    expectedLobbyId: expectedLobbyId,
  )?.gameId;
}

/// Авто-вход в партию с любой вкладки (чаты, друзья, главная…),
/// кроме экранов авторизации.
bool _allowsAutomaticGameNavigation(
  String currentPath, {
  String? expectedLobbyId,
}) {
  if (_isAuthOrPublicPath(currentPath)) return false;
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
  for (final g in gameRegistry.all) {
    final prefix = '/games/${g.id}/lobby/';
    if (currentPath.startsWith(prefix)) {
      final id = currentPath.substring(prefix.length).trim();
      if (id.isEmpty || id.contains('/')) return null;
      return id;
    }
  }
  return null;
}
