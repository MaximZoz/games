import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/push_nav_paths.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/battleship/battleship_provider.dart';
import 'package:multigames_client/games/checkers/checkers_provider.dart';
import 'package:multigames_client/games/chess/chess_provider.dart';
import 'package:multigames_client/games/domino/domino_provider.dart';
import 'package:multigames_client/games/durak/durak_provider.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/nardy/nardy_provider.dart';
import 'package:multigames_client/games/poker/poker_provider.dart';
import 'package:multigames_client/games/uno/uno_provider.dart';

/// Вход в стол из пуша. [openLobby] — можно открывать комнату, а не
/// экран «вас пригласили».
class PushLobbyJoinResult {
  const PushLobbyJoinResult({
    required this.openLobby,
    this.gameId,
    this.waitingMore = false,
  });

  final bool openLobby;
  final String? gameId;
  final bool waitingMore;

  static const closed = PushLobbyJoinResult(openLobby: false);
}

var _goTicket = 0;

/// Повтор go: первый редирект на «Игры» иногда приходит позже тапа
/// и возвращает на главную или на прошлый экран.
void deliverPushRoute({
  required void Function(String path) go,
  required String path,
  required bool Function() isAlive,
  required String Function() currentLocation,
}) {
  final ticket = ++_goTicket;
  void attempt() {
    if (!isAlive() || ticket != _goTicket) return;
    markPushOpenedRoute();
    go(path);
  }

  attempt();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!isAlive() || ticket != _goTicket) return;
    if (pathsMatch(currentLocation(), path)) return;
    attempt();
  });
  for (final delay in const [
    Duration(milliseconds: 350),
    Duration(milliseconds: 1200),
  ]) {
    unawaited(Future<void>.delayed(delay, () {
      if (!isAlive() || ticket != _goTicket) return;
      if (pathsMatch(currentLocation(), path)) return;
      attempt();
    }));
  }
}

/// Пуш на телефон: входим в лобби и только потом открываем его.
/// Ссылка из чата этот путь не использует.
Future<void> followNotificationPath({
  required Ref ref,
  required void Function(String path) go,
  required String path,
  required bool Function() isAlive,
  required bool joinLobby,
  required String Function() currentLocation,
}) async {
  final target = lobbyRouteFromPath(path);
  if (target == null || !joinLobby) {
    deliverPushRoute(
      go: go,
      path: path,
      isAlive: isAlive,
      currentLocation: currentLocation,
    );
    return;
  }
  final result = await joinLobbyFromNotification(
    ref,
    target,
    isAlive: isAlive,
  );
  if (!isAlive() || !result.openLobby) return;
  deliverPushRoute(
    go: go,
    path: pushLobbyDestination(
      gameType: target.gameType,
      lobbyId: target.lobbyId,
      gameId: result.gameId,
      waitingMore: result.waitingMore,
    ),
    isAlive: isAlive,
    currentLocation: currentLocation,
  );
}

Future<PushLobbyJoinResult> joinLobbyFromNotification(
  Ref ref,
  PushLobbyRoute target, {
  required bool Function() isAlive,
}) async {
  // Токен сессии на холодном старте иногда ещё не готов — без повтора
  // пуш остаётся на «Играх», хотя стол живой.
  for (var attempt = 0; attempt < 3; attempt++) {
    if (attempt > 0) {
      await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      if (!isAlive()) return PushLobbyJoinResult.closed;
    }
    try {
      final result = await _join(ref, target);
      if (!isAlive()) return PushLobbyJoinResult.closed;
      if (result.openLobby) {
        _rememberJoined(ref, target, result);
      }
      return result;
    } on GamesException catch (error) {
      if (!isAlive()) return PushLobbyJoinResult.closed;
      if (_alreadyInside(error)) {
        const inside = PushLobbyJoinResult(openLobby: true);
        _rememberJoined(ref, target, inside);
        return inside;
      }
      final terminal = error.statusCode == 400 ||
          error.statusCode == 404 ||
          error.statusCode == 409;
      if (terminal || attempt == 2) return PushLobbyJoinResult.closed;
    } catch (_) {
      if (!isAlive() || attempt == 2) return PushLobbyJoinResult.closed;
    }
  }
  return PushLobbyJoinResult.closed;
}

Future<PushLobbyJoinResult> _join(Ref ref, PushLobbyRoute target) async {
  final id = target.lobbyId;
  switch (target.gameType) {
    case 'durak':
      final res = await ref.read(durakRepositoryProvider).joinLobby(id);
      return _from(res.joined, res.gameId, res.waitingMore);
    case 'battleship':
      final res = await ref.read(battleshipRepositoryProvider).joinLobby(id);
      return _from(res.joined, res.gameId, false);
    case 'poker':
      final res = await ref.read(pokerRepositoryProvider).joinLobby(id);
      return _from(res.joined, res.gameId, res.waitingMore);
    case 'uno':
      final res = await ref.read(unoRepositoryProvider).joinLobby(id);
      return _from(res.joined, res.gameId, res.waitingMore);
    case 'domino':
      final res = await ref.read(dominoRepositoryProvider).joinLobby(id);
      return _from(res.joined, res.gameId, res.waitingMore);
    case 'nardy':
      final res = await ref.read(nardyRepositoryProvider).joinLobby(id);
      return _from(res.joined, res.gameId, false);
    case 'checkers':
      final res = await ref.read(checkersRepositoryProvider).joinLobby(id);
      return _from(res.joined, res.gameId, false);
    case 'chess':
      final res = await ref.read(chessRepositoryProvider).joinLobby(id);
      return _from(res.joined, res.gameId, false);
    default:
      final res = await ref.read(gamesRepositoryProvider).joinLobby(id);
      return _from(res.joined, res.gameId, res.waitingMore);
  }
}

PushLobbyJoinResult _from(bool joined, String? gameId, bool waitingMore) {
  return PushLobbyJoinResult(
    openLobby: joined,
    gameId: gameId,
    waitingMore: waitingMore,
  );
}

void _rememberJoined(Ref ref, PushLobbyRoute target, PushLobbyJoinResult result) {
  ref.read(gameInvitesProvider.notifier).resolveJoined(target.lobbyId);
  final gameId = (result.gameId ?? '').trim();
  final inGame = gameId.isNotEmpty && !result.waitingMore;
  ref.read(activeGameProvider.notifier).setLocal(
        ActiveGameItem(
          type: inGame ? 'game' : 'lobby',
          gameId: inGame ? gameId : null,
          lobbyId: target.lobbyId,
          gameType: target.gameType,
        ),
      );
  if (inGame) {
    ref.read(blockingGamePinProvider.notifier).state = BlockingGamePin(
      gameId: gameId,
      gameType: target.gameType,
    );
  }
  _invalidateLobby(ref, target);
  ref.invalidate(openLobbiesProvider);
}

void _invalidateLobby(Ref ref, PushLobbyRoute target) {
  final id = target.lobbyId;
  switch (target.gameType) {
    case 'durak':
      ref.invalidate(durakLobbyProvider(id));
    case 'battleship':
      ref.invalidate(battleshipLobbyProvider(id));
    case 'poker':
      ref.invalidate(pokerLobbyProvider(id));
    case 'uno':
      ref.invalidate(unoLobbyProvider(id));
    case 'domino':
      ref.invalidate(dominoLobbyProvider(id));
    case 'nardy':
      ref.invalidate(nardyLobbyProvider(id));
    case 'checkers':
      ref.invalidate(checkersLobbyProvider(id));
    case 'chess':
      ref.invalidate(chessLobbyProvider(id));
    default:
      ref.invalidate(lobbyDetailProvider(id));
  }
}

bool _alreadyInside(GamesException error) {
  if (error.statusCode != 400) return false;
  final message = error.message.toLowerCase();
  return message.contains('already in lobby') ||
      message.contains('уже в лобби');
}
