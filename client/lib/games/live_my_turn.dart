import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/games/battleship/battleship_provider.dart';
import 'package:multigames_client/games/checkers/checkers_provider.dart';
import 'package:multigames_client/games/chess/chess_provider.dart';
import 'package:multigames_client/games/domino/domino_provider.dart';
import 'package:multigames_client/games/durak/durak_provider.dart';
import 'package:multigames_client/games/game_navigation.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/nardy/nardy_provider.dart';
import 'package:multigames_client/games/poker/poker_provider.dart';
import 'package:multigames_client/games/uno/uno_provider.dart';

/// Ход с живой доски. `null` — снимок ещё не приехал, берём active.isMyTurn.
///
/// Active обновляется не у каждой игры (у дурака в кадре не было is_my_turn),
/// поэтому бейдж «Игры» смотрит сюда, а не на флаг со старта партии.
bool? watchLiveIsMyTurn(
  WidgetRef ref,
  ActiveGameItem? active, {
  String? meId,
}) {
  if (active == null || active.type != 'game') return null;
  final id = active.gameId?.trim() ?? '';
  if (id.isEmpty) return null;
  switch (normalizeGameType(active.gameType)) {
    case 'durak':
      return ref.watch(durakGameProvider(id)).valueOrNull?.isMyTurn;
    case 'chess':
      final game = ref.watch(chessGameProvider(id)).valueOrNull;
      if (game == null) return null;
      return game.isMyTurn && !game.isOver;
    case 'checkers':
      final game = ref.watch(checkersGameProvider(id)).valueOrNull;
      if (game == null) return null;
      return game.isMyTurn && !game.isOver;
    case 'nardy':
      final game = ref.watch(nardyGameProvider(id)).valueOrNull;
      if (game == null) return null;
      return game.isMyTurn && !game.isOver;
    case 'domino':
      return ref.watch(dominoGameProvider(id)).valueOrNull?.isMyTurn;
    case 'uno':
      return ref.watch(unoGameProvider(id)).valueOrNull?.isMyTurn;
    case 'poker':
      return ref.watch(pokerGameProvider(id)).valueOrNull?.isMyTurn;
    case 'battleship':
      final game = ref.watch(battleshipGameProvider(id)).valueOrNull;
      if (game == null) return null;
      return game.isMyTurn && !game.isOver;
    default:
      final game = ref.watch(gameStateProvider(id)).valueOrNull;
      if (game == null) return null;
      if (game.status != 'active') return false;
      final mark = game.markForUser(meId);
      if (mark == null || game.isEliminated(mark)) return false;
      return game.turn == mark;
  }
}

/// Подтянуть active.isMyTurn к доске, чтобы звук и фон не жили на старом флаге.
void scheduleActiveTurnSync(
  WidgetRef ref,
  ActiveGameItem? active,
  bool? live,
) {
  if (live == null || active == null || active.type != 'game') return;
  if (active.isMyTurn == live) return;
  final id = active.gameId;
  final turn = live;
  Future.microtask(() {
    final cur = ref.read(activeGameProvider).valueOrNull;
    if (cur == null || cur.type != 'game' || cur.gameId != id) return;
    if (cur.isMyTurn == turn) return;
    ref.read(activeGameProvider.notifier).setLocal(cur.copyWith(isMyTurn: turn));
  });
}
