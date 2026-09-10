import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/games/battleship/battleship_offline_session.dart';
import 'package:multigames_client/games/checkers/checkers_offline_session.dart';
import 'package:multigames_client/games/durak/durak_offline_session.dart';
import 'package:multigames_client/games/framework/game_registry.dart';
import 'package:multigames_client/games/nardy/nardy_offline_session.dart';
import 'package:multigames_client/games/offline_ttt_session.dart';
import 'package:multigames_client/games/poker/poker_offline_session.dart';
import 'package:multigames_client/games/uno/uno_offline_session.dart';

/// Последний путь живой партии (онлайн `/game/:id` или `/offline`).
///
/// Нужен, чтобы тап по «Игры» с другой вкладки вернул к столу, а не в каталог.
final lastGamesSessionPathProvider = StateProvider<String?>((ref) => null);

void rememberGamesSessionPath(WidgetRef ref, String path) {
  final next = nextRememberedGamesSessionPath(
    path,
    ref.read(lastGamesSessionPathProvider),
  );
  if (next != ref.read(lastGamesSessionPathProvider)) {
    ref.read(lastGamesSessionPathProvider.notifier).state = next;
  }
}

/// Крестик / сдача — забыть стол и снести локальных ботов.
///
/// Каталог `/games` сам по себе этого не делает: при смене вкладки путь
/// на миг становится `/games`, и иначе партия пропадала.
void leaveGamesSession(WidgetRef ref) {
  if (ref.read(lastGamesSessionPathProvider) != null) {
    ref.read(lastGamesSessionPathProvider.notifier).state = null;
  }
  disposeAllOfflineGameSessions();
}

String? nextRememberedGamesSessionPath(String path, String? previous) {
  if (gameRegistry.isActiveGamePath(path)) return path;
  return previous;
}

/// Снести локальные бот-партии — каталог «Играть» начинает новую.
void disposeAllOfflineGameSessions() {
  OfflineDurakRegistry.instance.disposeAll();
  OfflineBattleshipRegistry.instance.disposeAll();
  OfflineUnoRegistry.instance.disposeAll();
  OfflinePokerRegistry.instance.disposeAll();
  OfflineTttRegistry.instance.disposeAll();
  OfflineNardyRegistry.instance.disposeAll();
  OfflineCheckersRegistry.instance.disposeAll();
}
