import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';

/// Сообщение, когда нельзя войти в другую игру/лобби.
const finishCurrentGameMessage = 'Сначала завершите текущую игру';

/// Канонический ключ ошибки сервера (поле JSON `error`).
const finishCurrentGameErrorKey = 'finish your current game first';

bool hasActiveMatch(ActiveGameItem? active) {
  if (active == null || active.type != 'game') return false;
  final id = active.gameId?.trim() ?? '';
  return id.isNotEmpty;
}

/// Партия ещё блокирует новую игру (выбывший может только смотреть — не блокирует).
bool hasBlockingActiveMatch(ActiveGameItem? active) {
  return hasActiveMatch(active) && !active!.isEliminated;
}

bool hasActiveLobby(ActiveGameItem? active) {
  if (active == null || active.type != 'lobby') return false;
  final id = active.lobbyId?.trim() ?? '';
  return id.isNotEmpty;
}

/// Есть блокирующая сессия (партия или своё лобби), мешающая входу в [targetLobbyId].
/// Выбывший в multi — партия для него завершена: можно создавать/входить в новую.
bool isBusyWithOtherSession(
  ActiveGameItem? active, {
  String? targetLobbyId,
  String? targetGameId,
}) {
  if (hasBlockingActiveMatch(active)) {
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

/// gameId из пути `/games/tictactoe/game/:id`.
String? gameIdFromLocation(String? location) {
  final path = (location ?? '').split('?').first.trim();
  const prefix = '/games/tictactoe/game/';
  if (!path.startsWith(prefix)) return null;
  final id = path.substring(prefix.length).split('/').first.trim();
  return id.isEmpty ? null : id;
}

/// Активная сессия для гарда: кэш + путь партии + `?game=` при возврате из чата.
ActiveGameItem? resolveActiveForGuard(WidgetRef ref, BuildContext context) {
  final async = ref.read(activeGameProvider);
  final fromProvider = async.asData?.value ?? async.valueOrNull;
  if (hasBlockingActiveMatch(fromProvider) || hasActiveLobby(fromProvider)) {
    return fromProvider;
  }
  Uri uri;
  try {
    uri = GoRouterState.of(context).uri;
  } catch (_) {
    return fromProvider;
  }
  // Экран партии ИЛИ чат, открытый из партии (`?game=/games/tictactoe/game/...`).
  final pathGameId = gameIdFromLocation(uri.toString()) ??
      gameIdFromLocation(uri.queryParameters['game']);
  if (pathGameId != null) {
    final same =
        fromProvider?.type == 'game' && fromProvider?.gameId == pathGameId;
    return ActiveGameItem(
      type: 'game',
      gameId: pathGameId,
      lobbyId: fromProvider?.lobbyId,
      isMyTurn: same ? (fromProvider?.isMyTurn ?? false) : false,
      isEliminated: same ? (fromProvider?.isEliminated ?? false) : false,
    );
  }
  return fromProvider;
}

bool isFinishCurrentGameError(Object error) {
  if (error is! GamesException || error.statusCode != 409) return false;
  if (error.errorKey == finishCurrentGameErrorKey) return true;
  final msg = error.message.toLowerCase();
  return msg.contains('finish your current game') ||
      msg.contains('завершите текущую') ||
      msg.contains('already has an active game') ||
      msg.contains('уже есть активн');
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
  final active = resolveActiveForGuard(ref, context);
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

/// Асинхронный вариант: дождаться GetActive, если кэш пуст/грузится.
Future<bool> blockJoinIfBusyAsync(
  BuildContext context,
  WidgetRef ref, {
  String? targetLobbyId,
  String? targetGameId,
  bool redirectToActive = false,
}) async {
  var active = resolveActiveForGuard(ref, context);
  if (!isBusyWithOtherSession(
    active,
    targetLobbyId: targetLobbyId,
    targetGameId: targetGameId,
  )) {
    try {
      await ref.read(activeGameProvider.notifier).refresh();
    } catch (_) {}
    if (!context.mounted) return true;
    active = resolveActiveForGuard(ref, context);
  }
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
