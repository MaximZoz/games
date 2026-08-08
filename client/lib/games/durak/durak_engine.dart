import 'card.dart';

/// Режим игры.
const durakModePodkidnoi = 'podkidnoi';
const durakModePerevodnoi = 'perevodnoi';

/// Кто сейчас должен сделать ход.
enum DurakTurn {
  attacker, // атакующий кладёт первую карту атаки
  defender, // защитник бьёт (или переводит)
  throwIn, // пачка подкида до «Все»
  attackerFollowUp, // очередь подкида после полного отбоя / «Бито»
  takeFollowUp, // защитник берёт; очередь подкида вдогонку
  bitoReveal, // пауза показа стола перед уходом в биту (как online)
  takeReveal, // пауза показа стола перед взятием (как online)
}

/// Пара «атака / защита» на столе. [defense] = null — карта ещё не бита.
class TablePair {
  const TablePair(this.attack, [this.defense]);

  final PlayingCard attack;
  final PlayingCard? defense;

  TablePair withDefense(PlayingCard card) => TablePair(attack, card);

  bool get isBeaten => defense != null;
}

/// Ошибка правил игры (для UI-подсветки/защитного кода).
class DurakRuleError implements Exception {
  const DurakRuleError(this.message);
  final String message;
  @override
  String toString() => 'DurakRuleError: $message';
}

/// Состояние партии «Дурак» на 2–4 игроков (подкидной / переводной).
class DurakGame {
  DurakGame({
    required this.hands,
    required this.deck,
    required this.trump,
    required this.attackerIndex,
    required this.turn,
    this.mode = durakModePodkidnoi,
    List<TablePair>? table,
    List<PlayingCard>? bito,
    int? maxAttacks,
    int? throwerIndex,
    Set<int>? passed,
    List<int>? finishedIndices,
    this.loserIndex,
    this.firstRound = false,
  })  : table = table ?? <TablePair>[],
        bito = bito ?? <PlayingCard>[],
        maxAttacks = maxAttacks ?? 6,
        throwerIndex = throwerIndex ?? attackerIndex,
        passed = passed ?? <int>{},
        finishedIndices = finishedIndices ?? <int>[];

  /// Создать партию: перемешать колоду, раздать по 6, определить козырь
  /// и стартового атакующего (у кого младший козырь).
  factory DurakGame.startNew({
    int playerCount = 2,
    int deckSize = 36,
    String mode = durakModePodkidnoi,
    int handSize = 6,
    int? seed,
  }) {
    assert(playerCount >= 2 && playerCount <= 4);
    final normalizedMode =
        mode == durakModePerevodnoi ? durakModePerevodnoi : durakModePodkidnoi;
    final deck = Deck.standard(deckSize, seed: seed);
    // Козырь — последняя карта в колоде, она же открыта в основании.
    final trump = deck.cards.last.suit;

    final hands = List.generate(playerCount, (_) => <PlayingCard>[]);
    for (var i = 0; i < handSize; i++) {
      for (var p = 0; p < playerCount; p++) {
        hands[p].add(deck.cards.removeAt(0));
      }
    }

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
      throwerIndex: starter,
      turn: DurakTurn.attacker,
      mode: normalizedMode,
      firstRound: true,
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
  final String mode;
  int attackerIndex;
  int throwerIndex;
  DurakTurn turn;
  final List<TablePair> table;
  final List<PlayingCard> bito;
  final int maxAttacks;
  final Set<int> passed;
  final List<int> finishedIndices;
  int? loserIndex;

  /// Первый отбой: не больше 5 карт на столе.
  bool firstRound;

  /// Оба вышли — ничья (колода пуста, карт ни у кого нет).
  bool endedInDraw = false;

  int get playerCount => hands.length;
  int get defenderIndex => nextAliveAfter(attackerIndex);

  bool get isPerevodnoi => mode == durakModePerevodnoi;
  bool get isOver => loserIndex != null || endedInDraw;

  /// Верхняя карта козыря (лежит открытой в основании колоды).
  PlayingCard? get openTrumpCard =>
      deck.isEmpty ? null : deck.cards.last;

  bool isFinished(int idx) => finishedIndices.contains(idx);

  bool isAlive(int idx) {
    if (idx < 0 || idx >= hands.length) return false;
    return !isFinished(idx);
  }

  int aliveCount() {
    var n = 0;
    for (var i = 0; i < hands.length; i++) {
      if (isAlive(i)) n++;
    }
    return n;
  }

  int nextAliveAfter(int idx) {
    final n = hands.length;
    for (var i = 1; i <= n; i++) {
      final j = (idx + i) % n;
      if (isAlive(j)) return j;
    }
    return idx;
  }

  int prevAliveBefore(int idx) {
    final n = hands.length;
    for (var i = 1; i <= n; i++) {
      final j = (idx - i + n) % n;
      if (isAlive(j)) return j;
    }
    return idx;
  }

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

  bool get isFirstRoundActive =>
      !isOver && bito.isEmpty && firstRound;

  int get maxAttacksThisRound {
    final beaten = table.where((p) => p.isBeaten).length;
    var lim = beaten + hands[defenderIndex].length;
    if (lim < 1) lim = 1;
    if (maxAttacks > 0 && maxAttacks < lim) lim = maxAttacks;
    if (isFirstRoundActive && lim > 5) lim = 5;
    return lim;
  }

  int get transferAttackCap {
    var cap = maxAttacks;
    if (cap <= 0) cap = 6;
    if (isFirstRoundActive && cap > 5) cap = 5;
    return cap;
  }

  bool canThrowInSeat(int playerIndex) {
    if (!isAlive(playerIndex)) return false;
    if (hands[playerIndex].isEmpty) return false;
    if (playerIndex == defenderIndex) return false;
    if (aliveCount() >= 4) {
      final left = prevAliveBefore(defenderIndex);
      final right = nextAliveAfter(defenderIndex);
      return playerIndex == left || playerIndex == right;
    }
    return true;
  }

  List<PlayingCard> legalThrowInCards(int idx) {
    if (table.isEmpty || table.length >= maxAttacksThisRound) {
      return const [];
    }
    final ranks = tableRanks;
    final room = maxAttacksThisRound - table.length;
    if (room <= 0) return const [];
    return hands[idx]
        .where((c) => ranks.contains(c.rank.value))
        .toList(growable: false);
  }

  bool canThrowIn(int idx) {
    if (isOver) return false;
    if (turn == DurakTurn.bitoReveal || turn == DurakTurn.takeReveal) {
      return false;
    }
    if (table.isEmpty) {
      return idx == attackerIndex &&
          (turn == DurakTurn.attacker || turn == DurakTurn.attackerFollowUp);
    }
    if (!canThrowInSeat(idx) || passed.contains(idx)) return false;
    switch (turn) {
      case DurakTurn.defender:
        // Пока защитник бьёт — подкид начинает атакующий.
        return idx == attackerIndex && legalThrowInCards(idx).isNotEmpty;
      case DurakTurn.throwIn:
      case DurakTurn.attackerFollowUp:
      case DurakTurn.takeFollowUp:
        return idx == throwerIndex && legalThrowInCards(idx).isNotEmpty;
      case DurakTurn.attacker:
      case DurakTurn.bitoReveal:
      case DurakTurn.takeReveal:
        return false;
    }
  }

  /// Можно ли [card] использовать как первую атаку (или подкидывание).
  bool canAttackWith(PlayingCard card, int playerIndex) {
    if (isOver) return false;
    if (!hands[playerIndex].contains(card)) return false;
    if (table.length >= maxAttacksThisRound) return false;
    if (table.isEmpty) {
      if (playerIndex != attackerIndex) return false;
      if (turn != DurakTurn.attacker && turn != DurakTurn.attackerFollowUp) {
        return false;
      }
      return true;
    }
    if (!canThrowIn(playerIndex)) return false;
    return tableRanks.contains(card.rank.value);
  }

  /// Можно ли [card] бить неотбитую атаку ([pairIndex] или любую).
  bool canDefendWith(PlayingCard card, int playerIndex, {int? pairIndex}) {
    if (isOver) return false;
    if (turn != DurakTurn.defender) return false;
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

  bool canTransferWith(PlayingCard card, int playerIndex) {
    return legalTransferCards(playerIndex).contains(card);
  }

  List<PlayingCard> legalTransferCards(int idx) {
    if (isOver || !isPerevodnoi) return const [];
    if (turn != DurakTurn.defender || idx != defenderIndex) return const [];
    if (table.isEmpty) return const [];
    for (final p in table) {
      if (p.defense != null) return const [];
    }
    if (table.length + 1 > transferAttackCap) return const [];
    final next = nextAliveAfter(idx);
    if (!isAlive(next)) return const [];
    if (hands[next].length < table.length + 1) return const [];
    final rank = table.first.attack.rank;
    return hands[idx]
        .where((c) => c.rank == rank)
        .toList(growable: false);
  }

  bool get canDefenderTake =>
      turn == DurakTurn.defender &&
      table.isNotEmpty &&
      hands[defenderIndex].isNotEmpty;

  /// Текущий подкидывающий может сказать «Бито» (всё на столе бито).
  bool get canAttackerSayBito =>
      turn == DurakTurn.attackerFollowUp &&
      table.isNotEmpty &&
      table.every((p) => p.isBeaten) &&
      isAlive(throwerIndex);

  /// Текущий подкидывающий подтверждает конец подкида вдогонку.
  bool get canAttackerConfirmTake =>
      turn == DurakTurn.takeFollowUp &&
      table.isNotEmpty &&
      isAlive(throwerIndex);

  /// Положить атаку/подкидывание [card].
  void attack(PlayingCard card, {int? playerIndex}) {
    attackMany([card], playerIndex: playerIndex);
  }

  /// Положить сразу несколько карт атаки/подкида.
  void attackMany(List<PlayingCard> cards, {int? playerIndex}) {
    final pIndex = playerIndex ??
        (table.isEmpty ? attackerIndex : throwerIndex);
    if (cards.isEmpty) {
      throw const DurakRuleError('нельзя атаковать этой картой');
    }
    for (final c in cards) {
      if (!canAttackWith(c, pIndex)) {
        throw const DurakRuleError('нельзя атаковать этой картой');
      }
    }
    if (table.length + cards.length > maxAttacksThisRound) {
      throw const DurakRuleError('нельзя атаковать этой картой');
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
    if (turn == DurakTurn.takeFollowUp) {
      throwerIndex = pIndex;
      return;
    }
    // После каждой атаки/подкида — сразу защитнику (без кнопки «Все»).
    // Доп. подкид возможен в фазе defender.
    throwerIndex = pIndex;
    _finishThrowIn();
  }

  bool _canThrowMore(int playerIndex) {
    if (table.length >= maxAttacksThisRound) return false;
    final ranks = tableRanks;
    return hands[playerIndex].any((c) => ranks.contains(c.rank.value));
  }

  void _finishThrowIn() {
    passed.clear();
    if (table.isEmpty) {
      turn = DurakTurn.attacker;
      throwerIndex = attackerIndex;
      return;
    }
    turn = DurakTurn.defender;
    throwerIndex = attackerIndex;
  }

  /// «Все» — закончить пачку подкида текущего игрока → защитнику.
  void confirmThrowAll({int? playerIndex}) {
    final pIndex = playerIndex ?? throwerIndex;
    if (turn != DurakTurn.throwIn || pIndex != throwerIndex) {
      throw const DurakRuleError('нельзя подтвердить подкид');
    }
    _finishThrowIn();
  }

  /// Кнопка «Все» — только если ещё есть что подкинуть (иначе авто-отбой).
  bool get canConfirmThrowAll =>
      turn == DurakTurn.throwIn &&
      table.isNotEmpty &&
      isAlive(throwerIndex) &&
      _canThrowMore(throwerIndex);

  /// Бить пару [pairIndex] картой [card].
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
    if (hands[pIndex].isEmpty) {
      _resolveDefenderEmpty();
      return;
    }
    if (table.every((p) => p.isBeaten)) {
      turn = DurakTurn.attackerFollowUp;
      throwerIndex = attackerIndex;
      passed.clear();
      _skipThrowersWithoutCards();
    }
  }

  /// Переводной: защитник кладёт карту того же ранга — атака на следующего.
  void transfer(PlayingCard card, {int? playerIndex}) {
    final pIndex = playerIndex ?? defenderIndex;
    if (!canTransferWith(card, pIndex)) {
      throw const DurakRuleError('нельзя перевести этой картой');
    }
    hands[pIndex].remove(card);
    table.add(TablePair(card));
    attackerIndex = pIndex;
    throwerIndex = pIndex;
    passed.clear();
    turn = DurakTurn.defender;
  }

  void _resolveDefenderEmpty() {
    if (isOver || table.isEmpty) return;
    if (hands[defenderIndex].isNotEmpty) return;
    final atk = attackerIndex;
    final def = defenderIndex;
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
    passed.clear();
    _refillHands();
    firstRound = false;
    _checkGameOver();
    if (isOver) return;
    attackerIndex = isAlive(def) ? def : nextAliveAfter(def);
    throwerIndex = attackerIndex;
    turn = DurakTurn.attacker;
  }

  /// Защитник объявляет «Беру» — очередь подкида вдогонку.
  void take() {
    if (turn != DurakTurn.defender || table.isEmpty) {
      throw const DurakRuleError('брать сейчас нельзя');
    }
    if (hands[defenderIndex].isEmpty) {
      _resolveDefenderEmpty();
      return;
    }
    turn = DurakTurn.takeFollowUp;
    throwerIndex = attackerIndex;
    passed.clear();
    _skipThrowersWithoutCards();
  }

  /// Атакующий/подкидывающий закончил подкид вдогонку — пас или забор стола.
  void confirmTake({int? playerIndex}) {
    final pIndex = playerIndex ?? throwerIndex;
    if (turn != DurakTurn.takeFollowUp || table.isEmpty) {
      throw const DurakRuleError('подтвердить взятие сейчас нельзя');
    }
    if (pIndex != throwerIndex) {
      throw const DurakRuleError('подтвердить взятие сейчас нельзя');
    }
    passed.add(pIndex);
    final next = _nextThrowerAfter(pIndex);
    if (next < 0) {
      turn = DurakTurn.takeReveal;
      return;
    }
    throwerIndex = next;
    _skipThrowersWithoutCards();
  }

  void _resolveTake() {
    final di = defenderIndex;
    for (final p in table) {
      hands[di].add(p.attack);
      if (p.defense != null) hands[di].add(p.defense!);
    }
    table.clear();
    passed.clear();
    _sortHand(hands[di], trump);
    _refillHands();
    firstRound = false;
    _checkGameOver();
    if (isOver) return;
    attackerIndex = nextAliveAfter(di);
    // Как на сервере: ход следующему после защитника.
    // При take attacker становится next after defender (skipped defender).
    // Server: AttackerIndex = nextAliveAfter(defender)
    throwerIndex = attackerIndex;
    turn = DurakTurn.attacker;
  }

  /// Текущий подкидывающий говорит «Бито» (пас очереди).
  void sayBito({int? playerIndex}) {
    final pIndex = playerIndex ?? throwerIndex;
    if (!canAttackerSayBito || pIndex != throwerIndex) {
      throw const DurakRuleError('нельзя сказать «Бито»');
    }
    passed.add(pIndex);
    final next = _nextThrowerAfter(pIndex);
    if (next < 0) {
      turn = DurakTurn.bitoReveal;
      return;
    }
    throwerIndex = next;
    _skipThrowersWithoutCards();
  }

  void _resolveBito() {
    for (final p in table) {
      bito.add(p.attack);
      if (p.defense != null) bito.add(p.defense!);
    }
    table.clear();
    passed.clear();
    final def = defenderIndex;
    _refillHands();
    firstRound = false;
    _checkGameOver();
    if (isOver) return;
    attackerIndex = isAlive(def) ? def : nextAliveAfter(def);
    throwerIndex = attackerIndex;
    turn = DurakTurn.attacker;
  }

  /// Завершить паузу показа стола (бито / взятие) — как online reveal.
  void completeReveal() {
    if (turn == DurakTurn.bitoReveal) {
      _resolveBito();
      return;
    }
    if (turn == DurakTurn.takeReveal) {
      _resolveTake();
      return;
    }
  }

  int _nextThrowerAfter(int idx) {
    final n = hands.length;
    for (var i = 1; i <= n; i++) {
      final j = (idx + i) % n;
      if (!canThrowInSeat(j)) continue;
      if (passed.contains(j)) continue;
      return j;
    }
    return -1;
  }

  void _skipThrowersWithoutCards() {
    for (var hops = 0; hops <= hands.length; hops++) {
      if (turn != DurakTurn.attackerFollowUp &&
          turn != DurakTurn.takeFollowUp) {
        return;
      }
      final eligible = canThrowInSeat(throwerIndex);
      final hasCards =
          eligible && legalThrowInCards(throwerIndex).isNotEmpty;
      if (hasCards) return;
      if (eligible) passed.add(throwerIndex);
      final next = _nextThrowerAfter(throwerIndex);
      if (next < 0) {
        if (turn == DurakTurn.takeFollowUp) {
          turn = DurakTurn.takeReveal;
        } else {
          turn = DurakTurn.bitoReveal;
        }
        return;
      }
      throwerIndex = next;
    }
    if (turn == DurakTurn.takeFollowUp) {
      turn = DurakTurn.takeReveal;
    } else if (turn == DurakTurn.attackerFollowUp) {
      turn = DurakTurn.bitoReveal;
    }
  }

  /// Добор: атакующий → остальные по часовой (кроме защитника) → защитник.
  void _refillHands() {
    final def = defenderIndex;
    final order = <int>[
      for (var i = 0; i < playerCount; i++)
        if ((attackerIndex + i) % playerCount != def)
          (attackerIndex + i) % playerCount,
      if (def >= 0 && def < playerCount) def,
    ];
    for (final p in order) {
      if (!isAlive(p)) continue;
      final need = 6 - hands[p].length;
      if (need <= 0) continue;
      final drawnAll = deck.length;
      final maxDraw = drawnAll < need ? drawnAll : need;
      for (var i = 0; i < maxDraw; i++) {
        hands[p].add(deck.cards.removeAt(0));
      }
      _sortHand(hands[p], trump);
    }
  }

  void _markFinishedIfEmpty(int idx) {
    if (idx < 0 || idx >= hands.length) return;
    if (hands[idx].isNotEmpty) return;
    if (isFinished(idx)) return;
    finishedIndices.add(idx);
  }

  void _checkGameOver() {
    if (deck.isNotEmpty) return;
    // Пока стол не разобран — не «finished» (последние карты ещё могут отбить → ничья).
    if (table.isNotEmpty) return;
    for (var i = 0; i < hands.length; i++) {
      _markFinishedIfEmpty(i);
    }
    final withCards = <int>[];
    for (var i = 0; i < hands.length; i++) {
      if (isFinished(i)) continue;
      if (hands[i].isNotEmpty) {
        withCards.add(i);
      } else {
        _markFinishedIfEmpty(i);
      }
    }
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
