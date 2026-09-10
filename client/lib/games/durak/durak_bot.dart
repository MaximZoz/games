import 'card.dart';
import 'durak_engine.dart';

/// Простой бот «средней» силы для офлайна (2–4 игрока, подкидной/переводной):
/// - атакует младшей не-козырной картой (или минимальным козырем);
/// - защищается минимально; в переводном — переводит дешёвой картой, если выгодно;
/// - подкидывает только некозырные ранги;
/// - «берёт», если не может отбить;
/// - «бито»/«готово» — когда нечего подкинуть.
class DurakBot {
  const DurakBot({required this.index});

  final int index;

  /// Выполнить один шаг за бота. Возвращает [true], если что-то сделано.
  bool step(DurakGame game) {
    if (game.isOver || !game.isAlive(index)) return false;

    if (game.turn == DurakTurn.defender && index == game.defenderIndex) {
      return _stepDefender(game);
    }

    // Подкид / атака / бито / готово — только текущий thrower/attacker.
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
    // Пока защитник бьёт — атакующий может подкинуть.
    if (game.turn == DurakTurn.defender &&
        index == game.attackerIndex &&
        game.canThrowIn(index)) {
      return _tryThrowOne(game);
    }
    return false;
  }

  bool _stepFirstAttack(DurakGame game) {
    if (game.table.isNotEmpty) return false;
    final card = _pickAttackCard(game.hands[index], game.trump);
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
    hand.sort((a, b) {
      final at = a.suit == game.trump ? 1 : 0;
      final bt = b.suit == game.trump ? 1 : 0;
      if (at != bt) return at.compareTo(bt);
      return a.rank.compareTo(b.rank);
    });
    final maxToss = game.maxAttacksThisRound - game.table.length;
    if (maxToss <= 0) return false;
    for (final c in hand) {
      if (!ranks.contains(c.rank.value)) continue;
      final isTrump = c.suit == game.trump;
      if (isTrump && (deckLeft > 6 || defenderCards > 3)) continue;
      if (game.canAttackWith(c, index)) {
        game.attack(c, playerIndex: index);
        return true;
      }
    }
    return false;
  }

  bool _stepDefender(DurakGame game) {
    // Переводной: дешёвый перевод предпочтительнее слабой защиты козырем.
    if (game.isPerevodnoi) {
      final transfers = game.legalTransferCards(index);
      if (transfers.isNotEmpty) {
        final cheap = List<PlayingCard>.from(transfers)
          ..sort((a, b) {
            final at = a.suit == game.trump ? 1 : 0;
            final bt = b.suit == game.trump ? 1 : 0;
            if (at != bt) return at.compareTo(bt);
            return a.rank.compareTo(b.rank);
          });
        final pick = cheap.first;
        // Переводим, если карта не козырь или бить всё равно только козырем.
        final needTrumpToBeat = game.table.any((p) {
          if (p.defense != null) return false;
          return !game.hands[index].any(
            (c) => c.suit != game.trump && c.beats(p.attack, game.trump),
          );
        });
        if (pick.suit != game.trump || needTrumpToBeat) {
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
      if (best == null) {
        best = c;
        continue;
      }
      final bestTrump = best.suit == game.trump;
      final cTrump = c.suit == game.trump;
      if (bestTrump && !cTrump) {
        best = c;
      } else if (bestTrump == cTrump) {
        if (c.rank.value < best.rank.value) best = c;
      }
    }
    if (best != null) {
      game.defend(best, playerIndex: index, pairIndex: undefendedIndex);
      return true;
    }
    if (game.canDefenderTake) {
      game.take();
      return true;
    }
    return false;
  }

  PlayingCard? _pickAttackCard(List<PlayingCard> hand, Suit trump) {
    if (hand.isEmpty) return null;
    final counts = <int, int>{};
    for (final c in hand) {
      counts[c.rank.value] = (counts[c.rank.value] ?? 0) + 1;
    }
    final ranked = List<PlayingCard>.from(hand)
      ..sort((a, b) {
        final at = a.suit == trump ? 1 : 0;
        final bt = b.suit == trump ? 1 : 0;
        if (at != bt) return at.compareTo(bt);
        final ac = counts[a.rank.value] ?? 0;
        final bc = counts[b.rank.value] ?? 0;
        if (ac != bc) return bc.compareTo(ac);
        return a.rank.compareTo(b.rank);
      });
    return ranked.first;
  }
}
