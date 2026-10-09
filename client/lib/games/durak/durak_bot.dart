import 'card.dart';
import 'durak_engine.dart';

/// Сильный офлайн-бот: считает колоду, бережёт козыри, давит на короткого
/// защитника и не отдаёт дорогие карты без нужды.
class DurakBot {
  const DurakBot({required this.index});

  final int index;

  /// Выполнить один шаг за бота. Возвращает [true], если что-то сделано.
  bool step(DurakGame game) {
    if (game.isOver || !game.isAlive(index)) return false;

    if (game.turn == DurakTurn.defender && index == game.defenderIndex) {
      return _stepDefender(game);
    }

    if (game.turn == DurakTurn.attacker && index == game.attackerIndex) {
      return _stepFirstAttack(game);
    }
    if (game.turn == DurakTurn.throwIn && index == game.throwerIndex) {
      return _stepThrowOrPass(game);
    }
    if (game.turn == DurakTurn.attackerFollowUp &&
        index == game.throwerIndex) {
      return _stepThrowOrPass(game);
    }
    if (game.turn == DurakTurn.takeFollowUp && index == game.throwerIndex) {
      return _stepThrowOrPass(game);
    }
    if (game.turn == DurakTurn.defender &&
        index == game.attackerIndex &&
        game.canThrowIn(index)) {
      return _tryThrowOne(game);
    }
    return false;
  }

  bool _stepFirstAttack(DurakGame game) {
    if (game.table.isNotEmpty) return false;
    final card = _pickAttackCard(game);
    if (card == null) return false;
    game.attack(card, playerIndex: index);
    return true;
  }

  bool _stepThrowOrPass(DurakGame game) {
    if (_tryThrowOne(game)) return true;
    if (game.canConfirmThrowAll) {
      game.confirmThrowAll(playerIndex: index);
      return true;
    }
    if (game.canAttackerSayBito) {
      game.sayBito(playerIndex: index);
      return true;
    }
    if (game.canAttackerConfirmTake) {
      game.confirmTake(playerIndex: index);
      return true;
    }
    return false;
  }

  bool _tryThrowOne(DurakGame game) {
    final ranks = game.tableRanks;
    final hand = List<PlayingCard>.from(game.hands[index]);
    final deckLeft = game.deck.cards.length;
    final defenderCards = game.hands[game.defenderIndex].length;
    final dumpingOnTake = game.turn == DurakTurn.takeFollowUp;
    final endgame = deckLeft == 0 || (defenderCards <= 1 && deckLeft <= 4);
    hand.sort((a, b) => _cardCost(a, game.trump).compareTo(_cardCost(b, game.trump)));
    final maxToss = game.maxAttacksThisRound - game.table.length;
    if (maxToss <= 0) return false;
    for (final c in hand) {
      if (!ranks.contains(c.rank.value)) continue;
      final isTrump = c.suit == game.trump;
      if (isTrump && !endgame && !dumpingOnTake) continue;
      if (isTrump && dumpingOnTake && c.rank.value >= Rank.jack.value && deckLeft > 0) {
        continue;
      }
      if (game.canAttackWith(c, index)) {
        game.attack(c, playerIndex: index);
        return true;
      }
    }
    return false;
  }

  bool _stepDefender(DurakGame game) {
    if (game.isPerevodnoi) {
      final transfers = game.legalTransferCards(index);
      if (transfers.isNotEmpty) {
        final cheap = List<PlayingCard>.from(transfers)
          ..sort((a, b) =>
              _cardCost(a, game.trump).compareTo(_cardCost(b, game.trump)));
        final pick = cheap.first;
        final needTrumpToBeat = game.table.any((p) {
          if (p.defense != null) return false;
          return !game.hands[index].any(
            (c) => c.suit != game.trump && c.beats(p.attack, game.trump),
          );
        });
        final nextHasFew = game.hands[_nextAlive(game, game.defenderIndex)].length <= 2;
        if (!nextHasFew && (pick.suit != game.trump || needTrumpToBeat)) {
          game.transfer(pick, playerIndex: index);
          return true;
        }
      }
    }

    final undefendedIndex = game.table.indexWhere((p) => p.defense == null);
    if (undefendedIndex < 0) return false;
    final attack = game.table[undefendedIndex].attack;
    final hand = game.hands[index];

    PlayingCard? best;
    for (final c in hand) {
      if (!c.beats(attack, game.trump)) continue;
      if (best == null || _cardCost(c, game.trump) < _cardCost(best, game.trump)) {
        best = c;
      }
    }
    if (best != null) {
      final expensiveTrump = best.suit == game.trump && best.rank.value >= Rank.queen.value;
      final moreAttacksComing = game.table.length < game.maxAttacksThisRound &&
          game.deck.cards.length > 4 &&
          game.hands[game.attackerIndex].length > 2;
      if (expensiveTrump && moreAttacksComing && game.canDefenderTake) {
        game.take();
        return true;
      }
      game.defend(best, playerIndex: index, pairIndex: undefendedIndex);
      return true;
    }
    if (game.canDefenderTake) {
      game.take();
      return true;
    }
    return false;
  }

  PlayingCard? _pickAttackCard(DurakGame game) {
    final hand = game.hands[index];
    if (hand.isEmpty) return null;
    final counts = <int, int>{};
    for (final c in hand) {
      counts[c.rank.value] = (counts[c.rank.value] ?? 0) + 1;
    }
    final deckLeft = game.deck.cards.length;
    final defenderCards = game.hands[game.defenderIndex].length;
    final ranked = List<PlayingCard>.from(hand)
      ..sort((a, b) {
        final ac = _attackScore(a, game.trump, counts, deckLeft, defenderCards);
        final bc = _attackScore(b, game.trump, counts, deckLeft, defenderCards);
        return ac.compareTo(bc);
      });
    return ranked.first;
  }

  int _attackScore(
    PlayingCard card,
    Suit trump,
    Map<int, int> counts,
    int deckLeft,
    int defenderCards,
  ) {
    var score = _cardCost(card, trump);
    score -= (counts[card.rank.value] ?? 0) * 6;
    if (card.suit == trump && deckLeft > 4 && defenderCards > 2) {
      score += 40;
    }
    if (defenderCards <= 1) {
      score -= card.rank.value;
    }
    return score;
  }

  int _cardCost(PlayingCard card, Suit trump) {
    var cost = card.rank.value;
    if (card.suit == trump) cost += 20;
    return cost;
  }

  int _nextAlive(DurakGame game, int from) {
    final n = game.hands.length;
    for (var step = 1; step <= n; step++) {
      final i = (from + step) % n;
      if (game.isAlive(i)) return i;
    }
    return (from + 1) % n;
  }
}
