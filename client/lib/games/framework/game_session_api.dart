import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/games/durak/durak_provider.dart';
import 'package:multigames_client/games/durak/durak_repository.dart';
import 'package:multigames_client/games/framework/game_registry.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';

/// Общий фасад сессии лобби/партии поверх репозиториев игр.
///
/// Новая игра добавляет ветку здесь (или свой репозиторий с тем же контрактом),
/// а UI лобби/охраны активной партии остаётся общим.
class GameSessionApi {
  GameSessionApi(this._ref);

  final Ref _ref;

  GamesRepository get _ttt => _ref.read(gamesRepositoryProvider);
  DurakRepository get _durak => _ref.read(durakRepositoryProvider);

  Future<void> leaveLobby(String lobbyId, {required String gameType}) async {
    final gt = gameRegistry.normalizeId(gameType);
    // LeaveLobby на сервере общий для всех game_type.
    if (gt == 'durak') {
      await _durak.leaveLobby(lobbyId);
      return;
    }
    await _ttt.leaveLobby(lobbyId);
  }

  Future<ActiveGameItem?> getActive() => _ttt.getActive();

  Future<void> forfeit(String gameId, {required String gameType}) async {
    final gt = gameRegistry.normalizeId(gameType);
    if (gt == 'durak') {
      await _durak.forfeit(gameId);
      return;
    }
    await _ttt.forfeitGame(gameId);
  }

  Future<void> offerDraw(String gameId, {required String gameType}) async {
    final gt = gameRegistry.normalizeId(gameType);
    if (gt == 'durak') {
      await _durak.offerDraw(gameId);
      return;
    }
    await _ttt.offerDraw(gameId);
  }

  Future<void> acceptDraw(String gameId, {required String gameType}) async {
    final gt = gameRegistry.normalizeId(gameType);
    if (gt == 'durak') {
      await _durak.acceptDraw(gameId);
      return;
    }
    await _ttt.acceptDraw(gameId);
  }

  /// Проверка, что партия существует и какого она типа (для observation).
  Future<String?> resolveGameType(String gameId) async {
    try {
      await _durak.getGame(gameId);
      return 'durak';
    } catch (_) {}
    try {
      await _ttt.getGame(gameId);
      return 'tictactoe';
    } catch (_) {}
    return null;
  }
}

final gameSessionApiProvider = Provider<GameSessionApi>((ref) {
  return GameSessionApi(ref);
});
