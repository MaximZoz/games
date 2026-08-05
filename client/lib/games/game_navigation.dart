import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Префиксы пути партии по типу игры.
const _gamePathPrefixes = <String, String>{
  'tictactoe': '/games/tictactoe/game/',
  'durak': '/games/durak/game/',
};
const _lobbyPathPrefixes = <String, String>{
  'tictactoe': '/games/tictactoe/lobby/',
  'durak': '/games/durak/lobby/',
};

/// Возвращает префикс пути партии для game_type ('/games/<gt>/game/').
String gamePathPrefixFor(String gameType) {
  return _gamePathPrefixes[gameType] ?? _gamePathPrefixes['tictactoe']!;
}

/// Префикс лобби для game_type.
String lobbyPathPrefixFor(String gameType) {
  return _lobbyPathPrefixes[gameType] ?? _lobbyPathPrefixes['tictactoe']!;
}

/// Нормализованный game_type ('tictactoe' | 'durak').
String normalizeGameType(String? gameType) {
  final gt = gameType?.trim() ?? '';
  if (gt.isEmpty) return 'tictactoe';
  return _gamePathPrefixes.containsKey(gt) ? gt : 'tictactoe';
}

/// Путь к партии: `/games/<type>/game/<id>`.
String gamePathFor(String gameId, {String gameType = 'tictactoe'}) {
  return '${gamePathPrefixFor(normalizeGameType(gameType))}${gameId.trim()}';
}

/// Путь к лобби: `/games/<type>/lobby/<id>`.
String lobbyPathFor(String lobbyId, {String gameType = 'tictactoe'}) {
  return '${lobbyPathPrefixFor(normalizeGameType(gameType))}${lobbyId.trim()}';
}

/// gameId из `/games/<type>/game/:id` (tictactoe / durak).
String? gameIdFromGamePath(String? location) {
  final path = (location ?? '').split('?').first.trim();
  for (final prefix in _gamePathPrefixes.values) {
    if (!path.startsWith(prefix)) continue;
    final id = path.substring(prefix.length).split('/').first.trim();
    if (id.isNotEmpty) return id;
  }
  return null;
}

/// game_type из пути партии, иначе null.
String? gameTypeFromGamePath(String? location) {
  final path = (location ?? '').split('?').first.trim();
  for (final entry in _gamePathPrefixes.entries) {
    if (path.startsWith(entry.value)) return entry.key;
  }
  return null;
}

/// Совместимая константа для legacy-кода. Новый код — используйте
/// [gamePathPrefixFor].
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

    final target = '${gamePathPrefixFor(gameType)}$normalizedId';
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
  const RealtimeGameNavTarget({required this.gameId, this.gameType = 'tictactoe'});
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
    gameType: (gt == null || gt.isEmpty) ? 'tictactoe' : gt,
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
  for (final prefix in _lobbyPathPrefixes.values) {
    if (currentPath.startsWith(prefix)) {
      final id = currentPath.substring(prefix.length).trim();
      if (id.isEmpty || id.contains('/')) return null;
      return id;
    }
  }
  return null;
}
