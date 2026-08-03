import 'card.dart';
import 'durak_engine.dart';

/// Простой бот «средней» силы:
/// - атакует младшей не-козырной картой (или минимальным козырем, если нет);
/// - защищается минимально старшей той же масти, козырь — только если нет
///   альтернатив;
/// - подкидывает только некозырные ранги, если такие есть на столе;
/// - «берёт», если не может отбить любую из неотбитых пар;
/// - «бито» — как только все карты отбиты.
class DurakBot {
  const DurakBot({required this.index});

  final int index;

  /// Выполнить один шаг за бота. Возвращает [true], если что-то сделано.
  bool step(DurakGame game) {
    if (game.isOver) return false;
    if (index == game.attackerIndex) {
      return _stepAttacker(game);
    }
    if (index == game.defenderIndex && game.turn == DurakTurn.defender) {
      return _stepDefender(game);
    }
    return false;
  }

  bool _stepAttacker(DurakGame game) {
    if (game.turn == DurakTurn.attacker && game.table.isEmpty) {
      final card = _pickAttackCard(game.hands[index], game.trump);
      if (card == null) return false;
      game.attack(card, playerIndex: index);
      return true;
    }
    if (game.turn == DurakTurn.attackerFollowUp) {
      // Подкидывать: только если у нас есть некозырь с рангом на столе.
      final ranks = game.tableRanks;
      final hand = List<PlayingCard>.from(game.hands[index]);
      hand.sort((a, b) {
        final at = a.suit == game.trump ? 1 : 0;
        final bt = b.suit == game.trump ? 1 : 0;
        if (at != bt) return at.compareTo(bt);
        return a.rank.compareTo(b.rank);
      });
      final maxToss = game.maxAttacksThisRound - game.table.length;
      if (maxToss <= 0) {
        if (game.canAttackerSayBito) game.sayBito();
        return true;
      }
      for (final c in hand) {
        if (!ranks.contains(c.rank.value)) continue;
        if (c.suit == game.trump) continue; // не разбрасываем козыри
        if (game.canAttackWith(c, index)) {
          game.attack(c, playerIndex: index);
          return true;
        }
      }
      if (game.canAttackerSayBito) {
        game.sayBito();
        return true;
      }
    }
    return false;
  }

  bool _stepDefender(DurakGame game) {
    final undefendedIndex =
        game.table.indexWhere((p) => p.defense == null);
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
      // Некозырь всегда лучше козыря (экономим козыри).
      if (bestTrump && !cTrump) {
        best = c;
      } else if (bestTrump == cTrump) {
        if (c.rank.value < best.rank.value) best = c;
      }
    }
    if (best != null) {
      game.defend(best, playerIndex: index);
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
    final nonTrump = hand.where((c) => c.suit != trump).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
    if (nonTrump.isNotEmpty) return nonTrump.first;
    final trumps = List<PlayingCard>.from(hand)
      ..sort((a, b) => a.rank.compareTo(b.rank));
    return trumps.first;
  }
}
