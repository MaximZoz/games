import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/games/battleship/battleship_provider.dart';
import 'package:multigames_client/games/battleship/battleship_repository.dart';
import 'package:multigames_client/games/checkers/checkers_provider.dart';
import 'package:multigames_client/games/checkers/checkers_repository.dart';
import 'package:multigames_client/games/durak/durak_provider.dart';
import 'package:multigames_client/games/durak/durak_repository.dart';
import 'package:multigames_client/games/nardy/nardy_provider.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';
import 'package:multigames_client/games/poker/poker_provider.dart';
import 'package:multigames_client/games/poker/poker_repository.dart';
import 'package:multigames_client/games/uno/uno_provider.dart';
import 'package:multigames_client/games/uno/uno_repository.dart';
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
  BattleshipRepository get _battleship =>
      _ref.read(battleshipRepositoryProvider);
  PokerRepository get _poker => _ref.read(pokerRepositoryProvider);
  UnoRepository get _uno => _ref.read(unoRepositoryProvider);
  NardyRepository get _nardy => _ref.read(nardyRepositoryProvider);
  CheckersRepository get _checkers => _ref.read(checkersRepositoryProvider);

  Future<void> leaveLobby(String lobbyId, {required String gameType}) async {
    final gt = gameRegistry.normalizeId(gameType);
    if (gt == 'durak') {
      await _durak.leaveLobby(lobbyId);
      return;
    }
    if (gt == 'battleship') {
      await _battleship.leaveLobby(lobbyId);
      return;
    }
    if (gt == 'poker') {
      await _poker.leaveLobby(lobbyId);
      return;
    }
    if (gt == 'uno') {
      await _uno.leaveLobby(lobbyId);
      return;
    }
    if (gt == 'nardy') {
      await _nardy.leaveLobby(lobbyId);
      return;
    }
    if (gt == 'checkers') {
      await _checkers.leaveLobby(lobbyId);
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
    if (gt == 'battleship') {
      await _battleship.forfeit(gameId);
      return;
    }
    if (gt == 'poker') {
      await _poker.forfeit(gameId);
      return;
    }
    if (gt == 'uno') {
      await _uno.forfeit(gameId);
      return;
    }
    if (gt == 'nardy') {
      await _nardy.forfeit(gameId);
      return;
    }
    if (gt == 'checkers') {
      await _checkers.forfeit(gameId);
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
    if (gt == 'battleship' || gt == 'nardy') {
      // Морской бой и нарды не поддерживают ничью.
      return;
    }
    if (gt == 'checkers') {
      await _checkers.offerDraw(gameId);
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
    if (gt == 'battleship' || gt == 'nardy') {
      return;
    }
    if (gt == 'checkers') {
      await _checkers.acceptDraw(gameId);
      return;
    }
    await _ttt.acceptDraw(gameId);
  }

  /// Проверка, что партия существует и какого она типа (для observation).
  Future<String?> resolveGameType(String gameId) async {
    try {
      await _battleship.getGame(gameId);
      return 'battleship';
    } catch (_) {}
    try {
      await _poker.getGame(gameId);
      return 'poker';
    } catch (_) {}
    try {
      await _uno.getGame(gameId);
      return 'uno';
    } catch (_) {}
    try {
      await _nardy.getGame(gameId);
      return 'nardy';
    } catch (_) {}
    try {
      await _checkers.getGame(gameId);
      return 'checkers';
    } catch (_) {}
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
