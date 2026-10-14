import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';
import 'package:multigames_client/utils/user_error.dart';

/// Участник лобби: создатель, соперник или кто уже в составе.
bool lobbyUserIsMember({
  required String? userId,
  required String creatorId,
  required Iterable<String> playerIds,
  Iterable<LobbyPlayer> players = const [],
  String? opponentId,
}) {
  final id = userId?.trim() ?? '';
  if (id.isEmpty) return false;
  if (creatorId.trim() == id) return true;
  if ((opponentId ?? '').trim() == id) return true;
  if (playerIds.contains(id)) return true;
  for (final player in players) {
    if (player.id == id) return true;
  }
  return false;
}

/// Имя хозяина стола для подписи «приглашает вас сыграть».
String lobbyCreatorDisplayName({
  required String creatorId,
  required Iterable<LobbyPlayer> players,
}) {
  for (final player in players) {
    if (player.id == creatorId) return player.displayName.trim();
  }
  return '';
}

/// Гость по ссылке ещё не в лобби: назад просто уходит с экрана.
void exitLobbyGuest(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go('/games');
}

/// Результат входа в чужое лобби.
class LobbyJoinOutcome {
  const LobbyJoinOutcome({
    required this.joined,
    this.gameId,
    this.waitingMore = false,
  });

  final bool joined;
  final String? gameId;
  final bool waitingMore;
}

/// Вход по ссылке: в партию, если стол собрался, иначе остаёмся в лобби.
Future<void> runLobbyJoin({
  required BuildContext context,
  required WidgetRef ref,
  required String lobbyId,
  required String gameType,
  required Future<LobbyJoinOutcome> Function() join,
  required VoidCallback invalidateLobby,
  required void Function(bool joining) setJoining,
}) async {
  if (blockJoinIfBusy(
    context,
    ref,
    targetLobbyId: lobbyId,
    redirectToActive: true,
  )) {
    return;
  }
  setJoining(true);
  try {
    final result = await join();
    if (!context.mounted) return;
    if (!result.joined) {
      showAppSnackBar(
        context,
        message: context.l10n.lobbyGone,
        kind: AppSnackKind.error,
      );
      return;
    }
    final gameId = (result.gameId ?? '').trim();
    ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
    if (gameId.isNotEmpty && !result.waitingMore) {
      ref.read(activeGameProvider.notifier).setLocal(
            ActiveGameItem(
              type: 'game',
              gameId: gameId,
              lobbyId: lobbyId,
              gameType: gameType,
            ),
          );
      pinBlockingGame(ref, gameId, gameType: gameType);
      context.go('/games/$gameType/game/$gameId');
      return;
    }
    ref.read(activeGameProvider.notifier).setLocal(
          ActiveGameItem(
            type: 'lobby',
            lobbyId: lobbyId,
            gameType: gameType,
          ),
        );
    ref.invalidate(openLobbiesProvider);
    invalidateLobby();
  } on GamesException catch (error) {
    if (!context.mounted) return;
    if (_alreadyInLobby(error)) {
      ref.read(activeGameProvider.notifier).setLocal(
            ActiveGameItem(
              type: 'lobby',
              lobbyId: lobbyId,
              gameType: gameType,
            ),
          );
      invalidateLobby();
      return;
    }
    if (isFinishCurrentGameError(error)) {
      showAppSnackBar(
        context,
        message: finishCurrentGameMessage,
        kind: AppSnackKind.error,
      );
      final active = resolveActiveForGuard(ref, context);
      if (active != null) goToActiveSession(context, active);
      return;
    }
    final gone = error.statusCode == 404 || error.statusCode == 409;
    showAppSnackBar(
      context,
      message: gone
          ? context.l10n.lobbyGone
          : formatUserError(error, fallback: context.l10n.lobbyGone),
      kind: AppSnackKind.error,
    );
    if (gone) context.go('/games');
  } catch (error) {
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      message: formatUserError(error, fallback: context.l10n.lobbyGone),
      kind: AppSnackKind.error,
    );
  } finally {
    setJoining(false);
  }
}

bool _alreadyInLobby(GamesException error) {
  if (error.statusCode != 400) return false;
  final message = error.message.toLowerCase();
  return message.contains('already in lobby') ||
      message.contains('уже в лобби');
}
