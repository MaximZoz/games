import 'package:multigames_client/games/game_stake.dart';
import 'package:multigames_client/games/games_repository.dart';

/// Общая логика карточки игры: ставки из capabilities + clamp по балансу.
///
/// Новая игра переиспользует эти хелперы вместо копипасты с крестиков/дурака.
class GameCardStakeHelper {
  const GameCardStakeHelper._();

  /// Разблокированные и посильные ставки; fallback — freeStakeOptions.
  static List<int> availableStakes({
    required int balanceBronze,
    required List<int> unlockedOrEmpty,
  }) {
    final unlocked =
        unlockedOrEmpty.isEmpty ? freeStakeOptions : unlockedOrEmpty;
    final affordable = affordableStakeOptions(balanceBronze, unlocked);
    return affordable.isNotEmpty ? affordable : unlocked;
  }

  /// Если текущая ставка недоступна — ближайшая посильная.
  static int clampOrKeep({
    required int stakeBronze,
    required int balanceBronze,
    required List<int> available,
  }) {
    if (available.contains(stakeBronze)) return stakeBronze;
    if (available.isEmpty) return stakeBronze;
    return clampStakeToAffordable(stakeBronze, balanceBronze, available);
  }
}

/// Собрать [UserGameSettings] для сохранения карточки (кеш + БД).
UserGameSettings gameCardSettings({
  required String gameType,
  required int turnTimeSec,
  required int stakeBronze,
  String variant = 'classic',
  int maxPlayers = 2,
  int deckSize = 36,
  String gameMode = 'podkidnoi',
  bool firstMoveRestriction = false,
}) {
  switch (gameType) {
    case 'durak':
      return UserGameSettings(
        gameType: 'durak',
        turnTimeSec: turnTimeSec,
        variant: gameMode,
        stakeBronze: stakeBronze,
        deckSize: deckSize,
        maxPlayers: maxPlayers,
        gameMode: gameMode,
      );
    case 'poker':
      return UserGameSettings(
        gameType: 'poker',
        turnTimeSec: turnTimeSec,
        variant: 'holdem',
        stakeBronze: stakeBronze,
        deckSize: 52,
        maxPlayers: maxPlayers,
        gameMode: 'holdem',
      );
    case 'uno':
      return UserGameSettings(
        gameType: 'uno',
        turnTimeSec: turnTimeSec,
        variant: 'classic',
        stakeBronze: stakeBronze,
        deckSize: 108,
        maxPlayers: maxPlayers,
        gameMode: 'classic',
      );
    case 'battleship':
      return UserGameSettings(
        gameType: 'battleship',
        turnTimeSec: turnTimeSec,
        variant: 'classic',
        gridSize: 10,
        stakeBronze: stakeBronze,
        firstMoveRestriction: firstMoveRestriction,
        maxPlayers: 2,
      );
    default:
      return UserGameSettings(
        gameType: gameType,
        turnTimeSec: turnTimeSec,
        variant: variant,
        stakeBronze: stakeBronze,
        maxPlayers: maxPlayers,
      );
  }
}
