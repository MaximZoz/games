import 'dart:math';

import 'package:multigames_client/games/durak/card.dart';

/// Движок Texas Hold'em No-Limit для офлайн-режима (порт server/internal/poker).
///
/// Одна раздача = одна «игра»: блайнды, улицы, ставки, сайд-поты, вскрытие.
/// Карты используют общий [PlayingCard] (Rank 2..14, четыре масти).

/// Стадии раздачи.
class PokerStreet {
  static const preflop = 'preflop';
  static const flop = 'flop';
  static const turn = 'turn';
  static const river = 'river';
  static const showdown = 'showdown';
  static const over = 'over';
}

/// Статус партии.
class PokerStatus {
  static const active = 'active';
  static const over = 'over';
}

/// Тип действия игрока.
class PokerActionType {
  static const fold = 'fold';
  static const check = 'check';
  static const call = 'call';
  static const raise = 'raise';
  static const allIn = 'all_in';
}

/// Ход игрока. Для [raise] [amount] задаёт «поднять ДО» (raise-to).
class PokerAction {
  const PokerAction(this.type, {this.amount = 0});
  final String type;
  final int amount;
}

/// Категория покерной комбинации (от старшей карты до роял-флеша).
enum PokerHandRank {
  highCard,
  onePair,
  twoPair,
  threeOfAKind,
  straight,
  flush,
  fullHouse,
  fourOfAKind,
  straightFlush,
  royalFlush,
}

/// Результат оценки руки: категория + тай-брейкеры (по убыванию значимости).
class PokerHandValue {
  const PokerHandValue(this.rank, this.tie);
  final PokerHandRank rank;
  final List<int> tie;

  /// >0 если [this] сильнее [other], <0 если слабее, 0 — равны.
  int compare(PokerHandValue other) {
    if (rank != other.rank) {
      return rank.index > other.rank.index ? 1 : -1;
    }
    for (var i = 0; i < tie.length && i < other.tie.length; i++) {
      if (tie[i] != other.tie[i]) {
        return tie[i] > other.tie[i] ? 1 : -1;
      }
    }
    return 0;
  }
}

/// Оценка лучшей 5-карточной комбинации из 5..7 карт.
PokerHandValue evaluateBestHand(List<PlayingCard> cards) {
  if (cards.length < 5 || cards.length > 7) {
    throw ArgumentError('need 5..7 cards, got ${cards.length}');
  }
  final n = cards.length;
  final idx = [0, 1, 2, 3, 4];
  PokerHandValue? best;
  final combo = List<PlayingCard>.filled(5, cards[0]);
  while (true) {
    for (var i = 0; i < 5; i++) {
      combo[i] = cards[idx[i]];
    }
    final v = _eval5(combo);
    if (best == null || v.compare(best) > 0) {
      best = v;
    }
    var i = 4;
    while (i >= 0 && idx[i] == n - 5 + i) {
      i--;
    }
    if (i < 0) break;
    idx[i]++;
    for (var j = i + 1; j < 5; j++) {
      idx[j] = idx[j - 1] + 1;
    }
  }
  return best;
}

PokerHandValue _eval5(List<PlayingCard> cards) {
  final c = List<PlayingCard>.from(cards)
    ..sort((a, b) => b.rank.value.compareTo(a.rank.value));

  final flush = c.every((x) => x.suit == c[0].suit);
  final straight = _straightHighCard(c);
  final isStraight = straight != null;

  final counts = <int, int>{};
  for (final card in c) {
    counts.update(card.rank.value, (v) => v + 1, ifAbsent: () => 1);
  }
  final groups = counts.entries
      .map((e) => _RankGroup(e.value, e.key))
      .toList()
    ..sort((a, b) {
      if (a.count != b.count) return b.count.compareTo(a.count);
      return b.rank.compareTo(a.rank);
    });

  final ranksDesc = c.map((x) => x.rank.value).toList()
    ..sort((a, b) => b.compareTo(a));

  if (isStraight && flush) {
    if (straight == 14) {
      return PokerHandValue(PokerHandRank.royalFlush, [straight]);
    }
    return PokerHandValue(PokerHandRank.straightFlush, [straight]);
  }
  if (groups[0].count == 4) {
    return PokerHandValue(
        PokerHandRank.fourOfAKind, [groups[0].rank, groups[1].rank]);
  }
  if (groups[0].count == 3 && groups.length > 1 && groups[1].count == 2) {
    return PokerHandValue(
        PokerHandRank.fullHouse, [groups[0].rank, groups[1].rank]);
  }
  if (flush) {
    return PokerHandValue(PokerHandRank.flush, ranksDesc);
  }
  if (isStraight) {
    return PokerHandValue(PokerHandRank.straight, [straight]);
  }
  if (groups[0].count == 3) {
    return PokerHandValue(PokerHandRank.threeOfAKind,
        [groups[0].rank, groups[1].rank, groups[2].rank]);
  }
  if (groups[0].count == 2 && groups.length > 1 && groups[1].count == 2) {
    return PokerHandValue(PokerHandRank.twoPair,
        [groups[0].rank, groups[1].rank, groups[2].rank]);
  }
  if (groups[0].count == 2) {
    return PokerHandValue(PokerHandRank.onePair, [
      groups[0].rank,
      groups[1].rank,
      groups[2].rank,
      groups[3].rank,
    ]);
  }
  return PokerHandValue(PokerHandRank.highCard, ranksDesc);
}

class _RankGroup {
  _RankGroup(this.count, this.rank);
  final int count;
  final int rank;
}

/// Старшая карта стрита (учитывая «колесо» A-2-3-4-5 → 5) или null.
int? _straightHighCard(List<PlayingCard> c) {
  final uniq = <int>{for (final card in c) card.rank.value};
  if (uniq.length != 5) return null;
  final ranks = uniq.toList()..sort((a, b) => b.compareTo(a));
  if (ranks[0] - ranks[4] == 4) return ranks[0];
  if (ranks[0] == 14 &&
      ranks[1] == 5 &&
      ranks[2] == 4 &&
      ranks[3] == 3 &&
      ranks[4] == 2) {
    return 5;
  }
  return null;
}

/// Состояние игрока в раздаче.
class PokerEnginePlayer {
  PokerEnginePlayer({
    required this.userId,
    required this.chips,
    required this.seat,
  });

  final String userId;
  int chips;
  List<PlayingCard> hole = const [];
  int bet = 0; // ставка на текущей улице
  int totalBet = 0; // суммарный вклад за раздачу
  bool folded = false;
  bool allIn = false;
  final int seat;
  bool hasActed = false; // ходил ли на текущей улице
}

/// Банк (основной или побочный) и места, претендующие на него.
class PokerSidePot {
  PokerSidePot(this.amount, this.eligible);
  int amount;
  List<int> eligible;
}

/// Полное состояние одной раздачи Texas Hold'em.
class PokerEngine {
  PokerEngine._(this._rng);

  final Random _rng;

  late List<PokerEnginePlayer> players;
  List<PlayingCard> community = [];
  late List<PlayingCard> _deck;
  int _deckPos = 0;
  int pot = 0;
  List<PokerSidePot> sidePots = [];

  String street = PokerStreet.preflop;
  String status = PokerStatus.active;

  int dealerIndex = 0;
  int sbIndex = 0;
  int bbIndex = 0;
  int actingIndex = 0;

  int currentBet = 0;
  int minRaise = 0;

  int smallBlind = 0;
  int bigBlind = 0;

  List<int> winners = [];
  List<String> winnerUserIds = [];

  /// Создаёт новую раздачу с блайндами и раздачей карт.
  factory PokerEngine.newGame({
    required List<String> playerIds,
    required int startingChips,
    required int smallBlind,
    required int bigBlind,
    required int dealerIndex,
    Random? rng,
  }) {
    final n = playerIds.length;
    if (n < 2 || n > 6) {
      throw ArgumentError('poker: need 2..6 players, got $n');
    }
    final g = PokerEngine._(rng ?? Random());
    g.smallBlind = smallBlind;
    g.bigBlind = bigBlind;
    g.minRaise = bigBlind;
    g.dealerIndex = dealerIndex % n;
    g.players = [
      for (var i = 0; i < n; i++)
        PokerEnginePlayer(userId: playerIds[i], chips: startingChips, seat: i),
    ];
    g._deck = _freshDeck()..shuffle(g._rng);

    if (n == 2) {
      g.sbIndex = g.dealerIndex;
      g.bbIndex = (g.dealerIndex + 1) % n;
    } else {
      g.sbIndex = (g.dealerIndex + 1) % n;
      g.bbIndex = (g.dealerIndex + 2) % n;
    }

    g._postBet(g.sbIndex, smallBlind);
    g._postBet(g.bbIndex, bigBlind);
    g.currentBet = bigBlind;

    for (var i = 0; i < n; i++) {
      g.players[i].hole = [g._deal(), g._deal()];
    }

    g.actingIndex = g._firstLiveFrom(g.bbIndex + 1);
    g._updatePot();
    return g;
  }

  static List<PlayingCard> _freshDeck() {
    final cards = <PlayingCard>[];
    for (final s in Suit.values) {
      for (var v = 2; v <= 14; v++) {
        cards.add(PlayingCard(Rank(v), s));
      }
    }
    return cards;
  }

  PlayingCard _deal() {
    final c = _deck[_deckPos];
    _deckPos++;
    return c;
  }

  int get deckRemaining => _deck.length - _deckPos;

  int _postBet(int i, int amount) {
    final p = players[i];
    var actual = amount;
    if (actual > p.chips) actual = p.chips;
    p.chips -= actual;
    p.bet += actual;
    p.totalBet += actual;
    if (p.chips == 0) p.allIn = true;
    return actual;
  }

  void _updatePot() {
    var total = 0;
    for (final p in players) {
      total += p.totalBet;
    }
    pot = total;
  }

  int _firstLiveFrom(int start) {
    final n = players.length;
    for (var k = 0; k < n; k++) {
      final i = ((start % n) + n + k) % n;
      final p = players[i];
      if (!p.folded && !p.allIn && p.chips > 0) return i;
    }
    return -1;
  }

  int _liveCount() {
    var c = 0;
    for (final p in players) {
      if (!p.folded && !p.allIn && p.chips > 0) c++;
    }
    return c;
  }

  List<int> _notFolded() {
    final out = <int>[];
    for (var i = 0; i < players.length; i++) {
      if (!players[i].folded) out.add(i);
    }
    return out;
  }

  /// Допустимые действия для игрока [playerIndex].
  List<String> legalActions(int playerIndex) {
    if (status != PokerStatus.active || playerIndex != actingIndex) {
      return const [];
    }
    if (playerIndex < 0 || playerIndex >= players.length) return const [];
    final p = players[playerIndex];
    if (p.folded || p.allIn || p.chips == 0) return const [];
    final acts = <String>[PokerActionType.fold];
    if (p.bet == currentBet) {
      acts.add(PokerActionType.check);
    } else {
      acts.add(PokerActionType.call);
    }
    if (p.bet + p.chips > currentBet) {
      acts.add(PokerActionType.raise);
    }
    if (p.chips > 0) {
      acts.add(PokerActionType.allIn);
    }
    return acts;
  }

  /// Применяет ход игрока и продвигает состояние. Бросает [StateError] при ошибке.
  void apply(int playerIndex, PokerAction action) {
    if (status != PokerStatus.active) {
      throw StateError('poker: game is over');
    }
    if (playerIndex < 0 || playerIndex >= players.length) {
      throw StateError('poker: bad player index');
    }
    if (playerIndex != actingIndex) {
      throw StateError('poker: not your turn');
    }
    final p = players[playerIndex];
    if (p.folded || p.allIn) {
      throw StateError('poker: player cannot act');
    }

    switch (action.type) {
      case PokerActionType.fold:
        p.folded = true;
        p.hasActed = true;
        break;
      case PokerActionType.check:
        if (p.bet != currentBet) {
          throw StateError('poker: cannot check');
        }
        p.hasActed = true;
        break;
      case PokerActionType.call:
        final need = currentBet - p.bet;
        if (need <= 0) throw StateError('poker: nothing to call');
        _postBet(playerIndex, need);
        p.hasActed = true;
        break;
      case PokerActionType.raise:
        final maxTo = p.bet + p.chips;
        if (action.amount <= currentBet) {
          throw StateError('poker: raise must exceed current bet');
        }
        if (action.amount > maxTo) {
          throw StateError('poker: not enough chips to raise');
        }
        final minTo = currentBet + minRaise;
        if (action.amount < minTo && action.amount != maxTo) {
          throw StateError('poker: raise below min-raise');
        }
        _applyRaiseTo(playerIndex, action.amount);
        p.hasActed = true;
        break;
      case PokerActionType.allIn:
        if (p.chips <= 0) throw StateError('poker: no chips for all-in');
        final newBet = p.bet + p.chips;
        if (newBet > currentBet) {
          _applyRaiseTo(playerIndex, newBet);
        } else {
          _postBet(playerIndex, p.chips);
        }
        p.hasActed = true;
        break;
      default:
        throw StateError('poker: unknown action ${action.type}');
    }

    _updatePot();
    _advanceAfterAction();
  }

  void _applyRaiseTo(int i, int total) {
    final p = players[i];
    final add = total - p.bet;
    _postBet(i, add);
    final increment = total - currentBet;
    currentBet = total;
    if (increment >= minRaise) {
      minRaise = increment;
    }
  }

  void _advanceAfterAction() {
    final nf = _notFolded();
    if (nf.length == 1) {
      _awardUncontested(nf[0]);
      return;
    }
    if (_bettingComplete()) {
      _advanceStreet();
      return;
    }
    actingIndex = _firstLiveFrom(actingIndex + 1);
  }

  bool _bettingComplete() {
    for (final p in players) {
      if (p.folded || p.allIn || p.chips == 0) continue;
      if (!p.hasActed || p.bet != currentBet) return false;
    }
    return true;
  }

  void _resetBets() {
    for (final p in players) {
      p.bet = 0;
      p.hasActed = false;
    }
    currentBet = 0;
    minRaise = bigBlind;
  }

  void _advanceStreet() {
    while (true) {
      switch (street) {
        case PokerStreet.preflop:
          _dealCommunity(3);
          street = PokerStreet.flop;
          break;
        case PokerStreet.flop:
          _dealCommunity(1);
          street = PokerStreet.turn;
          break;
        case PokerStreet.turn:
          _dealCommunity(1);
          street = PokerStreet.river;
          break;
        case PokerStreet.river:
          street = PokerStreet.showdown;
          _showdown();
          return;
        default:
          return;
      }
      _resetBets();
      if (_liveCount() >= 2) {
        actingIndex = _firstLiveFrom(dealerIndex + 1);
        return;
      }
      // Иначе (all-in) — продолжаем сдавать карты.
    }
  }

  void _dealCommunity(int n) {
    if (deckRemaining < n) return;
    for (var i = 0; i < n; i++) {
      community.add(_deal());
    }
  }

  void _awardUncontested(int winner) {
    _updatePot();
    players[winner].chips += pot;
    sidePots = [PokerSidePot(pot, [winner])];
    winners = [winner];
    winnerUserIds = [players[winner].userId];
    street = PokerStreet.over;
    status = PokerStatus.over;
  }

  void _showdown() {
    final pots = _buildSidePots();
    sidePots = pots;
    final winnerSet = <int>{};
    for (final p in pots) {
      if (p.eligible.isEmpty || p.amount == 0) continue;
      final best = _bestAmong(p.eligible);
      _distribute(p.amount, best);
      winnerSet.addAll(best);
    }
    final w = winnerSet.toList()..sort();
    winners = w;
    winnerUserIds = [for (final i in w) players[i].userId];
    status = PokerStatus.over;
  }

  List<PokerSidePot> _buildSidePots() {
    final levelsSet = <int>{
      for (final p in players)
        if (p.totalBet > 0) p.totalBet,
    };
    final levels = levelsSet.toList()..sort();
    final pots = <PokerSidePot>[];
    var prev = 0;
    for (final lvl in levels) {
      var amount = 0;
      final eligible = <int>[];
      for (var i = 0; i < players.length; i++) {
        if (players[i].totalBet >= lvl) {
          amount += lvl - prev;
          if (!players[i].folded) eligible.add(i);
        }
      }
      if (amount > 0) pots.add(PokerSidePot(amount, eligible));
      prev = lvl;
    }
    return _mergePots(pots);
  }

  static List<PokerSidePot> _mergePots(List<PokerSidePot> pots) {
    if (pots.isEmpty) return pots;
    final out = <PokerSidePot>[];
    for (final p in pots) {
      if (out.isNotEmpty && _sameInts(out.last.eligible, p.eligible)) {
        out.last.amount += p.amount;
      } else {
        out.add(PokerSidePot(p.amount, List<int>.from(p.eligible)));
      }
    }
    return out;
  }

  static bool _sameInts(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<int> _bestAmong(List<int> eligible) {
    PokerHandValue? bestVal;
    final best = <int>[];
    for (final i in eligible) {
      final cards = <PlayingCard>[...players[i].hole, ...community];
      if (cards.length < 5) continue;
      final v = evaluateBestHand(cards);
      if (best.isEmpty) {
        bestVal = v;
        best.add(i);
        continue;
      }
      final cmp = v.compare(bestVal!);
      if (cmp > 0) {
        bestVal = v;
        best
          ..clear()
          ..add(i);
      } else if (cmp == 0) {
        best.add(i);
      }
    }
    return best;
  }

  void _distribute(int amount, List<int> winnersList) {
    if (winnersList.isEmpty) return;
    final base = amount ~/ winnersList.length;
    final rem = amount % winnersList.length;
    for (final w in winnersList) {
      players[w].chips += base;
    }
    if (rem > 0) {
      final order = _orderFromDealer(winnersList);
      for (var k = 0; k < rem; k++) {
        players[order[k]].chips++;
      }
    }
  }

  List<int> _orderFromDealer(List<int> seats) {
    final n = players.length;
    final out = List<int>.from(seats)
      ..sort((a, b) {
        final oa = ((a - dealerIndex - 1) + n) % n;
        final ob = ((b - dealerIndex - 1) + n) % n;
        return oa.compareTo(ob);
      });
    return out;
  }

  bool get isOver => status == PokerStatus.over;

  /// Сдача = фолд. Если сейчас ходит другой — форсируем фолд напрямую.
  void forceFold(int idx) {
    if (idx < 0 || idx >= players.length) return;
    if (status != PokerStatus.active) return;
    if (idx == actingIndex && !players[idx].folded && !players[idx].allIn) {
      apply(idx, const PokerAction(PokerActionType.fold));
      return;
    }
    players[idx].folded = true;
    var notFolded = 0;
    var winner = -1;
    for (var i = 0; i < players.length; i++) {
      if (!players[i].folded) {
        notFolded++;
        winner = i;
      }
    }
    if (notFolded == 1 && winner >= 0) {
      players[winner].chips += pot;
      winners = [winner];
      winnerUserIds = [players[winner].userId];
      street = PokerStreet.over;
      status = PokerStatus.over;
    }
  }
}

/// Простая стратегия бота: чек; иначе колл, если дёшево; иногда мин-рейз; иначе фолд.
PokerAction pokerBotAction(PokerEngine g) {
  final idx = g.actingIndex;
  final legal = g.legalActions(idx);
  bool has(String a) => legal.contains(a);
  final p = g.players[idx];
  var callAmount = g.currentBet - p.bet;
  if (callAmount < 0) callAmount = 0;
  final rng = Random();

  if (has(PokerActionType.check)) {
    if (has(PokerActionType.raise) &&
        p.chips > g.bigBlind * 2 &&
        rng.nextInt(4) == 0) {
      final to = g.currentBet + g.minRaise;
      if (to <= p.bet + p.chips) {
        return PokerAction(PokerActionType.raise, amount: to);
      }
    }
    return const PokerAction(PokerActionType.check);
  }
  if (has(PokerActionType.call) && callAmount <= p.chips ~/ 3) {
    if (has(PokerActionType.raise) &&
        p.chips > g.bigBlind * 4 &&
        rng.nextInt(6) == 0) {
      final to = g.currentBet + g.minRaise;
      if (to <= p.bet + p.chips) {
        return PokerAction(PokerActionType.raise, amount: to);
      }
    }
    return const PokerAction(PokerActionType.call);
  }
  return const PokerAction(PokerActionType.fold);
}
