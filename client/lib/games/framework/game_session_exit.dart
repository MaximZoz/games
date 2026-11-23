import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem;
import 'package:multigames_client/games/offline_session_hold.dart';

/// Локальный active всё ещё указывает на партию [gameId].
///
/// Пока это так, вкладка «Игры» считает партию живой и возвращает на её
/// экран — даже если она уже сыграна.
bool activeStillPointsAtGame(ActiveGameItem? active, String gameId) {
  final id = gameId.trim();
  if (active == null || id.isEmpty) return false;
  return active.type == 'game' && (active.gameId?.trim() ?? '') == id;
}

/// Забыть партию перед уходом в каталог «Игры» — общий шаг для всех игр.
///
/// Снимает запомненный путь стола, пин живой партии и локальный active.
/// Без этого крестик с оконченной партии вёл в «Игры», а они тут же
/// открывали тот же стол обратно. Офлайн-партия в active не попадает:
/// для неё достаточно забыть стол.
void forgetGameSession(
  WidgetRef ref, {
  required String gameId,
  bool offline = false,
}) {
  leaveGamesSession(ref);
  if (offline) return;
  clearBlockingGamePin(ref, ifGameId: gameId);
  final active = ref.read(activeGameProvider).valueOrNull;
  if (activeStillPointsAtGame(active, gameId)) {
    ref.read(activeGameProvider.notifier).clearLocal();
  }
}
