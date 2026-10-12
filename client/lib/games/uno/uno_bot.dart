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
    final stack = player.hand
        .where((card) => game.canPlay(index, card))
        .toList(growable: false);
    if (stack.isEmpty) {
      return const UnoAction(UnoActionType.draw);
    }
    stack.sort((a, b) => b.points.compareTo(a.points));
    final card = stack.first;
    return UnoAction(
      UnoActionType.play,
      cardId: card.id,
      color: card.isWild ? chooseUnoBotColor(player) : null,
    );
  }
  if (game.status == UnoStatus.awaitingDrawnPlay) {
    UnoCard? drawn;
    for (final card in player.hand) {
      if (card.id == game.drawnCardId) {
        drawn = card;
        break;
      }
    }
    if (drawn == null || !game.canPlay(index, drawn)) {
      return const UnoAction(UnoActionType.keep);
    }
    if (drawn.isWild && player.hand.length > 3 && rng.nextDouble() < 0.2) {
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
    final cmp = _unoCardScore(game, index, b).compareTo(_unoCardScore(game, index, a));
    if (cmp != 0) return cmp;
    return a.id.compareTo(b.id);
  });
  final card = legal.first;
  return UnoAction(
    UnoActionType.play,
    cardId: card.id,
    color: card.isWild ? chooseUnoBotColor(player) : null,
  );
}

int _unoNextHandSize(UnoEngine game, int index) {
  final n = game.players.length;
  var dir = game.direction;
  if (dir == 0) dir = 1;
  for (var step = 1; step <= n; step++) {
    var next = (index + dir * step) % n;
    if (next < 0) next += n;
    if (!game.players[next].forfeited) {
      return game.players[next].hand.length;
    }
  }
  return 7;
}

int _unoCardScore(UnoEngine game, int index, UnoCard card) {
  final next = _unoNextHandSize(game, index);
  final counts = <UnoColor, int>{};
  for (final c in game.players[index].hand) {
    if (c.color.isPlayableColor) {
      counts[c.color] = (counts[c.color] ?? 0) + 1;
    }
  }
  final handLen = game.players[index].hand.length;
  var score = card.points;
  if (next <= 2) score += card.points;
  switch (card.kind) {
    case UnoCardKind.skip:
    case UnoCardKind.reverse:
    case UnoCardKind.drawTwo:
      if (next <= 2) {
        score += 90;
      } else if (next <= 4) {
        score += 35;
      } else {
        score += 6;
      }
    case UnoCardKind.wild:
      score += (next <= 2 || handLen <= 2) ? 50 : -40;
    case UnoCardKind.wildDrawFour:
      score += next <= 2 ? 110 : -70;
    case UnoCardKind.number:
      score += (counts[card.color] ?? 0) * 14;
      if (card.color == game.currentColor) score += 8;
  }
  score += _unoFeedPenalty(game, index, card);
  return score;
}

/// Не отдавать ход игроку с одной картой, если можно ударить его.
int _unoFeedPenalty(UnoEngine game, int index, UnoCard card) {
  final dir = game.direction == 0 ? 1 : game.direction;
  final nextHand = _handSteps(game, index, 1, dir);
  final twoAway = _handSteps(game, index, 2, dir);
  switch (card.kind) {
    case UnoCardKind.number:
    case UnoCardKind.wild:
      if (nextHand == 1) return -40;
    case UnoCardKind.skip:
    case UnoCardKind.drawTwo:
      if (twoAway == 1 && nextHand > 1) return -28;
    case UnoCardKind.reverse:
      final alive = game.players.where((p) => !p.forfeited).length;
      if (alive <= 2) {
        if (twoAway == 1 && nextHand > 1) return -28;
        return 0;
      }
      final recv = _handSteps(game, index, 1, -dir);
      if (recv == 1) return -28;
    case UnoCardKind.wildDrawFour:
      if (twoAway == 1 && nextHand > 1) return -20;
  }
  return 0;
}

int _handSteps(UnoEngine game, int index, int steps, int direction) {
  if (steps <= 0) return 7;
  final dir = direction == 0 ? 1 : direction;
  final n = game.players.length;
  var cursor = index;
  for (var s = 0; s < steps; s++) {
    var found = false;
    for (var step = 1; step <= n; step++) {
      var next = (cursor + dir * step) % n;
      if (next < 0) next += n;
      if (!game.players[next].forfeited) {
        cursor = next;
        found = true;
        break;
      }
    }
    if (!found) return 7;
  }
  return game.players[cursor].hand.length;
}
