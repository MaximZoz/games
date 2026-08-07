import 'card.dart';

/// Кто сейчас должен сделать ход.
enum DurakTurn {
  attacker, // атакующий кладёт первую карту атаки или подкидывает
  defender, // защитник бьёт очередную атаку
  attackerFollowUp, // атакующий может подкинуть или сказать «Бито»
  takeFollowUp, // защитник берёт; атакующий может подкинуть вдогонку
}

/// Пара «атака / защита» на столе. [defense] = null — карта ещё не бита.
class TablePair {
  const TablePair(this.attack, [this.defense]);

  final PlayingCard attack;
  final PlayingCard? defense;

  TablePair withDefense(PlayingCard card) => TablePair(attack, card);

  bool get isBeaten => defense != null;
}

/// Итог хода (для UI / бота).
class DurakStep {
  const DurakStep({required this.type, this.card, this.pair});

  final DurakStepType type;
  final PlayingCard? card;
  final TablePair? pair;
}

enum DurakStepType { attack, defend, take, done, refill, gameOver }

/// Ошибка правил игры (для UI-подсветки/защитного кода).
class DurakRuleError implements Exception {
  const DurakRuleError(this.message);
  final String message;
  @override
  String toString() => 'DurakRuleError: $message';
}

/// Состояние партии «Подкидной дурак» на N игроков (N=2 в MVP).
///
/// Ход всегда: `attackerIndex` атакует `defenderIndex = (attackerIndex+1) % N`.
/// Максимум пар на столе = `maxAttacks` (6, ограничено картами в руке защитника).
class DurakGame {
  DurakGame({
    required this.hands,
    required this.deck,
    required this.trump,
    required this.attackerIndex,
    required this.turn,
    List<TablePair>? table,
    List<PlayingCard>? bito,
    int? maxAttacks,
    int? loserIndex,
  })  : table = table ?? <TablePair>[],
        bito = bito ?? <PlayingCard>[],
        maxAttacks = maxAttacks ?? 6;

  /// Создать партию: перемешать колоду, раздать по 6, определить козырь
  /// и стартового атакующего (у кого младший козырь).
  factory DurakGame.startNew({
    int playerCount = 2,
    int deckSize = 36,
    int handSize = 6,
    int? seed,
  }) {
    assert(playerCount >= 2 && playerCount <= 4);
    final deck = Deck.standard(deckSize, seed: seed);
    // Козырь — последняя карта в колоде, она же открыта в основании.
    // Не убираем её: добор идёт с верха (removeAt(0)), последней уйдёт козырь.
    final trump = deck.cards.last.suit;

    final hands = List.generate(playerCount, (_) => <PlayingCard>[]);
    for (var i = 0; i < handSize; i++) {
      for (var p = 0; p < playerCount; p++) {
        hands[p].add(deck.cards.removeAt(0));
      }
    }

    // Стартовый ход: у кого младший козырь; если ни у кого — первый.
    var starter = 0;
    var bestValue = 100;
    for (var p = 0; p < playerCount; p++) {
      for (final c in hands[p]) {
        if (c.suit == trump && c.rank.value < bestValue) {
          bestValue = c.rank.value;
          starter = p;
        }
      }
    }
    for (final h in hands) {
      _sortHand(h, trump);
    }
    return DurakGame(
      hands: hands,
      deck: deck,
      trump: trump,
      attackerIndex: starter,
      turn: DurakTurn.attacker,
    );
  }

  static void _sortHand(List<PlayingCard> hand, Suit trump) {
    hand.sort((a, b) {
      final at = a.suit == trump ? 1 : 0;
      final bt = b.suit == trump ? 1 : 0;
      if (at != bt) return at.compareTo(bt);
      final s = a.suit.index.compareTo(b.suit.index);
      if (s != 0) return s;
      return a.rank.compareTo(b.rank);
    });
  }

  final List<List<PlayingCard>> hands;
  final Deck deck;
  final Suit trump;
  int attackerIndex;
  DurakTurn turn;
  final List<TablePair> table;
  final List<PlayingCard> bito;
  final int maxAttacks;
  int? loserIndex;

  /// Оба вышли — ничья (колода пуста, карт ни у кого нет).
  bool endedInDraw = false;

  int get playerCount => hands.length;
  int get defenderIndex => (attackerIndex + 1) % playerCount;

  bool get isOver => loserIndex != null || endedInDraw;

  /// Верхняя карта козыря (лежит открытой в основании колоды).
  PlayingCard? get openTrumpCard =>
      deck.isEmpty ? null : deck.cards.last;

  /// Ранги, уже присутствующие на столе (для правил подкидывания).
  Set<int> get tableRanks {
    final s = <int>{};
    for (final p in table) {
      s.add(p.attack.rank.value);
      if (p.defense != null) s.add(p.defense!.rank.value);
    }
    return s;
  }

  int get undefendedCount =>
      table.where((p) => p.defense == null).length;

  int get maxAttacksThisRound {
    // Как на сервере: рука защитника + уже лежащие атаки.
    final lim = hands[defenderIndex].length + table.length;
    final capped = lim < 1 ? 1 : lim;
    return maxAttacks > 0 && maxAttacks < capped ? maxAttacks : capped;
  }

  /// Можно ли [card] использовать как первую атаку (или подкидывание).
  bool canAttackWith(PlayingCard card, int playerIndex) {
    if (isOver) return false;
    if (playerIndex != attackerIndex) return false;
    if (!hands[playerIndex].contains(card)) return false;
    if (table.length >= maxAttacksThisRound) return false;
    // Пока защитник бьёт или берёт — только подкид рангов со стола.
    if (turn == DurakTurn.defender || turn == DurakTurn.takeFollowUp) {
      if (table.isEmpty) return false;
      return tableRanks.contains(card.rank.value);
    }
    if (turn != DurakTurn.attacker && turn != DurakTurn.attackerFollowUp) {
      return false;
    }
    if (table.isEmpty) return true;
    return tableRanks.contains(card.rank.value);
  }

  /// Можно ли [card] бить неотбитую атаку ([pairIndex] или любую).
  bool canDefendWith(PlayingCard card, int playerIndex, {int? pairIndex}) {
    if (isOver) return false;
    if (playerIndex != defenderIndex) return false;
    if (!hands[playerIndex].contains(card)) return false;
    if (pairIndex != null) {
      if (pairIndex < 0 || pairIndex >= table.length) return false;
      final pair = table[pairIndex];
      if (pair.defense != null) return false;
      return card.beats(pair.attack, trump);
    }
    return table.any(
      (p) => p.defense == null && card.beats(p.attack, trump),
    );
  }

  bool get canDefenderTake =>
      turn == DurakTurn.defender &&
      table.isNotEmpty &&
      hands[defenderIndex].isNotEmpty;

  /// Атакующий имеет право сказать «Бито» когда все карты на столе биты.
  bool get canAttackerSayBito =>
      turn == DurakTurn.attackerFollowUp &&
      table.isNotEmpty &&
      table.every((p) => p.isBeaten);

  /// Атакующий подтверждает конец подкида вдогонку.
  bool get canAttackerConfirmTake =>
      turn == DurakTurn.takeFollowUp && table.isNotEmpty;

  /// Положить атаку/подкидывание [card].
  void attack(PlayingCard card, {int? playerIndex}) {
    attackMany([card], playerIndex: playerIndex);
  }

  /// Положить сразу несколько карт атаки/подкида.
  /// Пустой стол — все одного ранга; иначе каждый ранг уже на столе.
  void attackMany(List<PlayingCard> cards, {int? playerIndex}) {
    final pIndex = playerIndex ?? attackerIndex;
    if (cards.isEmpty) {
      throw const DurakRuleError('нельзя атаковать этой картой');
    }
    // Подкид: во время защиты, после отбоя или вдогонку после «Беру».
    if (turn != DurakTurn.attacker &&
        turn != DurakTurn.attackerFollowUp &&
        turn != DurakTurn.defender &&
        turn != DurakTurn.takeFollowUp) {
      throw const DurakRuleError('нельзя атаковать этой картой');
    }
    if ((turn == DurakTurn.defender || turn == DurakTurn.takeFollowUp) &&
        table.isEmpty) {
      throw const DurakRuleError('нельзя атаковать этой картой');
    }
    if (table.length + cards.length > maxAttacksThisRound) {
      throw const DurakRuleError('нельзя атаковать этой картой');
    }
    for (final c in cards) {
      if (!hands[pIndex].contains(c)) {
        throw const DurakRuleError('нельзя атаковать этой картой');
      }
    }
    if (table.isEmpty) {
      final rank = cards.first.rank;
      if (cards.any((c) => c.rank != rank)) {
        throw const DurakRuleError('нельзя атаковать этой картой');
      }
    } else {
      for (final c in cards) {
        if (!tableRanks.contains(c.rank.value)) {
          throw const DurakRuleError('нельзя атаковать этой картой');
        }
      }
    }
    for (final c in cards) {
      hands[pIndex].remove(c);
      table.add(TablePair(c));
    }
    if (turn != DurakTurn.takeFollowUp) {
      turn = DurakTurn.defender;
    }
  }

  /// Бить пару [pairIndex] картой [card]. Если индекс не задан — первая, которую
  /// карта реально бьёт.
  void defend(PlayingCard card, {int? playerIndex, int? pairIndex}) {
    final pIndex = playerIndex ?? defenderIndex;
    if (!canDefendWith(card, pIndex, pairIndex: pairIndex)) {
      throw const DurakRuleError('нельзя отбить этой картой');
    }
    final idx = pairIndex ??
        table.indexWhere(
          (p) => p.defense == null && card.beats(p.attack, trump),
        );
    if (idx < 0) {
      throw const DurakRuleError('нельзя отбить этой картой');
    }
    hands[pIndex].remove(card);
    table[idx] = table[idx].withDefense(card);
    // Рука пуста: отбитое — в биту, неотбитое — обратно атакующему.
    if (hands[pIndex].isEmpty) {
      _resolveDefenderEmpty();
      return;
    }
    // Если все побиты — ждём подкидывания или «бито».
    if (table.every((p) => p.isBeaten)) {
      turn = DurakTurn.attackerFollowUp;
      // Атакующий без карт — сразу бито.
      if (hands[attackerIndex].isEmpty) {
        sayBito();
      }
    }
  }

  /// У защитника кончились карты: отбитые пары в отбой, неотбитые атаки —
  /// атакующему; ход — бывшему защитнику.
  void _resolveDefenderEmpty() {
    if (isOver || table.isEmpty) return;
    if (hands[defenderIndex].isNotEmpty) return;
    final atk = attackerIndex;
    for (final p in table) {
      if (p.defense != null) {
        bito.add(p.attack);
        bito.add(p.defense!);
      } else {
        hands[atk].add(p.attack);
      }
    }
    _sortHand(hands[atk], trump);
    table.clear();
    _refillHands();
    attackerIndex = (atk + 1) % playerCount;
    _checkGameOver();
    turn = DurakTurn.attacker;
  }

  /// Защитник объявляет «Беру» — атакующий может подкинуть вдогонку.
  void take() {
    if (turn != DurakTurn.defender || table.isEmpty) {
      throw const DurakRuleError('брать сейчас нельзя');
    }
    // Пустая рука — закрытие раунда, не «взять».
    if (hands[defenderIndex].isEmpty) {
      _resolveDefenderEmpty();
      return;
    }
    turn = DurakTurn.takeFollowUp;
    // Нечего подкинуть — сразу забираем.
    if (!_hasThrowIn(attackerIndex)) {
      confirmTake();
    }
  }

  bool _hasThrowIn(int playerIndex) {
    if (table.isEmpty) return false;
    if (table.length >= maxAttacksThisRound) return false;
    final ranks = tableRanks;
    return hands[playerIndex].any((c) => ranks.contains(c.rank.value));
  }

  /// Атакующий закончил подкид вдогонку — защитник забирает стол.
  void confirmTake() {
    if (turn != DurakTurn.takeFollowUp || table.isEmpty) {
      throw const DurakRuleError('подтвердить взятие сейчас нельзя');
    }
    final di = defenderIndex;
    for (final p in table) {
      hands[di].add(p.attack);
      if (p.defense != null) hands[di].add(p.defense!);
    }
    table.clear();
    _sortHand(hands[di], trump);
    _refillHands();
    attackerIndex = (di + 1) % playerCount;
    _checkGameOver();
    turn = DurakTurn.attacker;
  }

  /// Атакующий говорит «Бито».
  void sayBito() {
    if (!canAttackerSayBito) {
      throw const DurakRuleError('нельзя сказать «Бито»');
    }
    for (final p in table) {
      bito.add(p.attack);
      if (p.defense != null) bito.add(p.defense!);
    }
    table.clear();
    _refillHands();
    attackerIndex = defenderIndex; // ход переходит к бывшему защитнику
    _checkGameOver();
    turn = isOver ? DurakTurn.attacker : DurakTurn.attacker;
  }

  /// Добор карт по кругу: атакующий, подкидывающие, защитник — по 6.
  void _refillHands() {
    final order = <int>[];
    order.add(attackerIndex);
    for (var i = 1; i < playerCount - 1; i++) {
      order.add((attackerIndex + i) % playerCount);
    }
    if (defenderIndex != attackerIndex) order.add(defenderIndex);
    for (final p in order) {
      final need = 6 - hands[p].length;
      if (need <= 0) continue;
      final drawnAll = deck.length; // включая козырь
      final maxDraw = drawnAll < need ? drawnAll : need;
      for (var i = 0; i < maxDraw; i++) {
        // Берём с верха, козырь-карта остаётся в конце и уйдёт последней.
        hands[p].add(deck.cards.removeAt(0));
      }
      _sortHand(hands[p], trump);
    }
  }

  void _checkGameOver() {
    if (deck.isNotEmpty) return;
    final withCards =
        List.generate(playerCount, (i) => i).where((i) => hands[i].isNotEmpty);
    if (withCards.length <= 1) {
      if (withCards.isEmpty) {
        endedInDraw = true;
        loserIndex = null;
      } else {
        endedInDraw = false;
        loserIndex = withCards.first;
      }
    }
  }
}
