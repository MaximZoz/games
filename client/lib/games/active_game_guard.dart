import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';

/// Сообщение, когда нельзя войти в другую игру/лобби.
const finishCurrentGameMessage = 'Сначала завершите текущую игру';

bool hasActiveMatch(ActiveGameItem? active) {
  if (active == null || active.type != 'game') return false;
  final id = active.gameId?.trim() ?? '';
  return id.isNotEmpty;
}

bool hasActiveLobby(ActiveGameItem? active) {
  if (active == null || active.type != 'lobby') return false;
  final id = active.lobbyId?.trim() ?? '';
  return id.isNotEmpty;
}

/// Есть блокирующая сессия (партия или своё лобби), мешающая входу в [targetLobbyId].
bool isBusyWithOtherSession(
  ActiveGameItem? active, {
  String? targetLobbyId,
  String? targetGameId,
}) {
  if (hasActiveMatch(active)) {
    final gid = active!.gameId!.trim();
    if (targetGameId != null && targetGameId.trim() == gid) return false;
    return true;
  }
  if (hasActiveLobby(active)) {
    final lid = active!.lobbyId!.trim();
    if (targetLobbyId != null && targetLobbyId.trim() == lid) return false;
    return true;
  }
  return false;
}

void goToActiveSession(BuildContext context, ActiveGameItem active) {
  if (!context.mounted) return;
  if (hasActiveMatch(active)) {
    context.go('/games/tictactoe/game/${active.gameId!.trim()}');
    return;
  }
  if (hasActiveLobby(active)) {
    context.go('/games/tictactoe/lobby/${active.lobbyId!.trim()}?mode=invite');
  }
}

/// Если заняты другой партией/лобби — показать всплывашку и вернуть true.
/// При [redirectToActive] уводит обратно в текущую партию/лобби.
bool blockJoinIfBusy(
  BuildContext context,
  WidgetRef ref, {
  String? targetLobbyId,
  String? targetGameId,
  bool redirectToActive = false,
}) {
  final active = ref.read(activeGameProvider).valueOrNull;
  if (!isBusyWithOtherSession(
    active,
    targetLobbyId: targetLobbyId,
    targetGameId: targetGameId,
  )) {
    return false;
  }
  if (context.mounted) {
    showAppSnackBar(
      context,
      message: finishCurrentGameMessage,
      kind: AppSnackKind.error,
    );
    if (redirectToActive && active != null) {
      goToActiveSession(context, active);
    }
  }
  return true;
}
