import 'package:multigames_client/games/games_provider.dart';

/// Стол, с которым сравниваем входящее приглашение.
///
/// Реванш — только та же игра, тот же режим и та же ставка.
/// Другая игра, режим или ставка остаётся обычным приглашением в лобби.
class RematchTable {
  const RematchTable({
    required this.gameType,
    required this.stakeBronze,
    this.gameMode = '',
    this.variant = '',
    this.deckSize = 0,
  });

  final String gameType;
  final int stakeBronze;

  /// Режим партии: шахматы, шашки, нарды, дурак, покер, уно.
  final String gameMode;

  /// Вариант крестиков-ноликов (классика, гомоку и т.д.).
  final String variant;

  /// Колода дурака. 0 — не сравнивать.
  final int deckSize;
}

/// true, если инвайт — реванш этого стола, а не новая партия.
bool inviteIsRematch(
  GameInvite invite,
  RematchTable table,
  Iterable<String> peerIds,
) {
  if (!peerIds.contains(invite.creatorId)) return false;
  if (table.gameType.isEmpty) return true;
  if (invite.gameType != table.gameType) return false;
  if (invite.stakeBronze != table.stakeBronze) return false;
  if (table.gameType == 'tictactoe') {
    return table.variant.isEmpty || invite.variant == table.variant;
  }
  if (table.gameMode.isNotEmpty && invite.durakMode != table.gameMode) {
    return false;
  }
  if (table.gameType == 'durak' &&
      table.deckSize > 0 &&
      invite.deckSize != table.deckSize) {
    return false;
  }
  return true;
}
