import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/game_navigation.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';

/// Сообщение, когда нельзя войти в другую игру/лобби.
const finishCurrentGameMessage = 'Сначала завершите текущую игру';

/// Канонический ключ ошибки сервера (поле JSON `error`).
const finishCurrentGameErrorKey = 'finish your current game first';

/// Локальный пин живой партии: не сбрасывается при invalidate activeGameProvider.
/// Нужен, когда из чата жмут инвайт, а GetActive ещё/уже пуст.
class BlockingGamePin {
  const BlockingGamePin({
    required this.gameId,
    this.gameType = 'tictactoe',
  });

  final String gameId;
  final String gameType;
}

final blockingGamePinProvider = StateProvider<BlockingGamePin?>((ref) => null);

void pinBlockingGame(
  WidgetRef ref,
  String? gameId, {
  String gameType = 'tictactoe',
}) {
  final id = gameId?.trim() ?? '';
  ref.read(blockingGamePinProvider.notifier).state = id.isEmpty
      ? null
      : BlockingGamePin(
          gameId: id,
          gameType: normalizeGameType(gameType),
        );
}

void clearBlockingGamePin(WidgetRef ref, {String? ifGameId}) {
  final cur = ref.read(blockingGamePinProvider);
  if (cur == null) return;
  final only = ifGameId?.trim() ?? '';
  if (only.isNotEmpty && cur.gameId != only) return;
  ref.read(blockingGamePinProvider.notifier).state = null;
}

bool hasActiveMatch(ActiveGameItem? active) {
  if (active == null || active.type != 'game') return false;
  final id = active.gameId?.trim() ?? '';
  return id.isNotEmpty;
}

/// Партия ещё блокирует новую игру (observation не блокирует).
bool hasBlockingActiveMatch(ActiveGameItem? active) {
  return hasActiveMatch(active);
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
  final gt = normalizeGameType(active.gameType);
  if (hasActiveMatch(active)) {
    context.go(gamePathFor(active.gameId!.trim(), gameType: gt));
    return;
  }
  if (hasActiveLobby(active)) {
    context.go('${lobbyPathFor(active.lobbyId!.trim(), gameType: gt)}?mode=invite');
  }
}

/// gameId из пути `/games/<type>/game/:id` (tictactoe / durak).
String? gameIdFromLocation(String? location) => gameIdFromGamePath(location);

/// Активная сессия для гарда: пин + кэш + путь партии + `?game=` из чата.
/// Observation не считается блокирующей.
ActiveGameItem? resolveActiveForGuard(WidgetRef ref, BuildContext context) {
  final async = ref.read(activeGameProvider);
  final fromProvider = async.asData?.value ?? async.valueOrNull;
  if (hasBlockingActiveMatch(fromProvider) || hasActiveLobby(fromProvider)) {
    return fromProvider;
  }
  final pinned = ref.read(blockingGamePinProvider);
  if (pinned != null && pinned.gameId.isNotEmpty) {
    return ActiveGameItem(
      type: 'game',
      gameId: pinned.gameId,
      gameType: normalizeGameType(pinned.gameType),
    );
  }
  Uri uri;
  try {
    uri = GoRouterState.of(context).uri;
  } catch (_) {
    return fromProvider;
  }
  // Экран партии ИЛИ чат, открытый из партии (`?game=/games/.../game/...`).
  final pathGameId = gameIdFromLocation(uri.toString()) ??
      gameIdFromLocation(uri.queryParameters['game']);
  if (pathGameId != null) {
    // Наблюдение на этой доске — не блокирует новую игру.
    final observing = ref.read(observationGameProvider);
    if (observing?.gameId == pathGameId) {
      return fromProvider;
    }
    final same =
        fromProvider?.type == 'game' && fromProvider?.gameId == pathGameId;
    final pathType = gameTypeFromGamePath(uri.toString()) ??
        gameTypeFromGamePath(uri.queryParameters['game']) ??
        (same ? fromProvider!.gameType : 'tictactoe');
    return ActiveGameItem(
      type: 'game',
      gameId: pathGameId,
      lobbyId: fromProvider?.lobbyId,
      isMyTurn: same ? (fromProvider?.isMyTurn ?? false) : false,
      gameType: normalizeGameType(pathType),
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

/// Асинхронный вариант: сверить с GetActive (протухший пин после конца партии).
Future<bool> blockJoinIfBusyAsync(
  BuildContext context,
  WidgetRef ref, {
  String? targetLobbyId,
  String? targetGameId,
  bool redirectToActive = false,
}) async {
  try {
    await ref.read(activeGameProvider.notifier).refresh();
  } catch (_) {}
  if (!context.mounted) return true;
  // Сервер без active/lobby — пин от оконченной партии больше не блокирует.
  final fresh = ref.read(activeGameProvider).valueOrNull;
  if (!hasBlockingActiveMatch(fresh) && !hasActiveLobby(fresh)) {
    clearBlockingGamePin(ref);
  }
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
