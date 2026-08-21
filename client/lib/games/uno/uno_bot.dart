import 'dart:math';

import 'package:multigames_client/games/uno/uno_card.dart';
import 'package:multigames_client/games/uno/uno_engine.dart';

UnoColor chooseUnoBotColor(UnoPlayer player) {
  final counts = <UnoColor, int>{
    for (final color in UnoColor.values.where((color) => color.isPlayableColor))
      color: 0,
  };
  for (final card in player.hand) {
    if (card.color.isPlayableColor) {
      counts[card.color] = (counts[card.color] ?? 0) + 1;
    }
  }
  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

UnoAction pickUnoBotAction(UnoEngine game, {Random? random}) {
  if (game.status == UnoStatus.betweenRounds) {
    return const UnoAction(UnoActionType.nextRound);
  }
  final chooser = game.colorChooserIndex;
  final index = game.status == UnoStatus.awaitingColor &&
          chooser >= 0 &&
          chooser < game.players.length
      ? chooser
      : game.currentIndex;
  if (index < 0 || index >= game.players.length) {
    return const UnoAction(UnoActionType.draw);
  }
  final player = game.players[index];
  final rng = random ?? Random();

  if (game.status == UnoStatus.awaitingColor) {
    return UnoAction(
      UnoActionType.chooseColor,
      color: chooseUnoBotColor(player),
    );
  }
  if (game.status == UnoStatus.awaitingWd4Challenge) {
    return const UnoAction(UnoActionType.draw);
  }
  if (game.status == UnoStatus.awaitingDrawnPlay) {
    UnoCard? drawn;
    for (final card in player.hand) {
      if (card.id == game.drawnCardId) {
        drawn = card;
        break;
      }
    }
    if (drawn == null || rng.nextDouble() < 0.15) {
      return const UnoAction(UnoActionType.keep);
    }
    return UnoAction(
      UnoActionType.play,
      cardId: drawn.id,
      color: drawn.isWild ? chooseUnoBotColor(player) : null,
    );
  }

  final legal = player.hand
      .where((card) => game.canPlay(index, card))
      .toList(growable: false);
  if (legal.isEmpty) return const UnoAction(UnoActionType.draw);

  legal.sort((a, b) {
    final actionCompare = b.points.compareTo(a.points);
    if (actionCompare != 0) return actionCompare;
    return a.id.compareTo(b.id);
  });
  final card = legal.first;
  return UnoAction(
    UnoActionType.play,
    cardId: card.id,
    color: card.isWild ? chooseUnoBotColor(player) : null,
  );
}
