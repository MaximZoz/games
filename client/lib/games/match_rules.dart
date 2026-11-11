import 'package:flutter/material.dart';
import 'package:multigames_client/games/battleship/battleship_rules.dart';
import 'package:multigames_client/games/checkers/checkers_rules.dart';
import 'package:multigames_client/games/chess/chess_rules.dart';
import 'package:multigames_client/games/domino/domino_rules.dart';
import 'package:multigames_client/games/durak/durak_rules.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';
import 'package:multigames_client/games/poker/poker_rules.dart';
import 'package:multigames_client/games/uno/uno_rules.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';

/// Текст правил одной партии — общий для приглашения и открытого лобби.
///
/// Режим шахмат и шашек берётся из [gameMode] (пуля, блиц, …), а не из
/// варианта крестиков-ноликов.
Widget buildMatchRulesBody({
  required AppLocalizations l10n,
  required bool isDurak,
  required bool isBattleship,
  required bool isPoker,
  required bool isUno,
  required bool isDomino,
  required bool isNardy,
  required bool isCheckers,
  required bool isChess,
  required String gameMode,
  required String variant,
  required int maxPlayers,
  required int deckSize,
  required int turnTimeSec,
  required int stakeBronze,
  required int gridSize,
  required bool swapRule,
  required bool firstMoveRestriction,
}) {
  if (isDurak) {
    return rulesTextLines(durakRuleLines(
      mode: gameMode,
      players: maxPlayers,
      deckSize: deckSize,
      turnTimeSec: turnTimeSec,
      stakeBronze: stakeBronze,
    ));
  }
  if (isBattleship) {
    return rulesTextLines(battleshipRuleLines(
      turnTimeSec: turnTimeSec,
      stakeBronze: stakeBronze,
      l10n: l10n,
    ));
  }
  if (isPoker) {
    return rulesTextLines(pokerRuleLines(
      players: maxPlayers,
      turnTimeSec: turnTimeSec,
      stakeBronze: stakeBronze,
      l10n: l10n,
    ));
  }
  if (isUno) {
    return rulesTextLines(unoRuleLines(
      players: maxPlayers,
      turnTimeSec: turnTimeSec,
      stakeBronze: stakeBronze,
      l10n: l10n,
    ));
  }
  if (isDomino) {
    return rulesTextLines(dominoRuleLines(
      players: maxPlayers,
      turnTimeSec: turnTimeSec,
      stakeBronze: stakeBronze,
      mode: gameMode,
      l10n: l10n,
    ));
  }
  if (isNardy) {
    return rulesTextLines(nardyRuleLines(
      gameMode: gameMode,
      turnTimeSec: turnTimeSec,
      stakeBronze: stakeBronze,
      l10n: l10n,
    ));
  }
  if (isCheckers) {
    return rulesTextLines(checkersRuleLines(
      gameMode: gameMode,
      turnTimeSec: turnTimeSec,
      stakeBronze: stakeBronze,
      l10n: l10n,
    ));
  }
  if (isChess) {
    return rulesTextLines(chessRuleLines(
      gameMode: gameMode,
      turnTimeSec: turnTimeSec,
      stakeBronze: stakeBronze,
      l10n: l10n,
    ));
  }
  return buildTictactoeRulesTextWidget(
    variant: variant,
    gridSize: gridSize,
    turnTimeSec: turnTimeSec,
    swapRule: swapRule,
    firstMoveRestriction: firstMoveRestriction,
    stakeBronze: stakeBronze,
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 13,
      height: 1.35,
    ),
  );
}
