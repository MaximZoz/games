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

/// Каноническое имя ранга (совпадает с сервером: "OnePair", "Flush", …).
/// Используется в [PokerGameView.myHandRank] и подписи комбинации в UI.
String pokerHandRankName(PokerHandRank rank) {
  switch (rank) {
    case PokerHandRank.highCard:
      return 'HighCard';
    case PokerHandRank.onePair:
      return 'OnePair';
    case PokerHandRank.twoPair:
      return 'TwoPair';
    case PokerHandRank.threeOfAKind:
      return 'ThreeOfAKind';
    case PokerHandRank.straight:
      return 'Straight';
    case PokerHandRank.flush:
      return 'Flush';
    case PokerHandRank.fullHouse:
      return 'FullHouse';
    case PokerHandRank.fourOfAKind:
      return 'FourOfAKind';
    case PokerHandRank.straightFlush:
      return 'StraightFlush';
    case PokerHandRank.royalFlush:
      return 'RoyalFlush';
  }
}

/// Результат оценки руки: категория + тай-брейкеры (по убыванию значимости) +
/// сами 5 карт лучшей комбинации (для подсветки в UI).
class PokerHandValue {
  const PokerHandValue(this.rank, this.tie, [this.cards = const []]);
  final PokerHandRank rank;
  final List<int> tie;
  final List<PlayingCard> cards;

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

  PokerHandValue mk(PokerHandRank rank, List<int> tie) =>
      PokerHandValue(rank, tie, c);

  if (isStraight && flush) {
    if (straight == 14) {
      return mk(PokerHandRank.royalFlush, [straight]);
    }
    return mk(PokerHandRank.straightFlush, [straight]);
  }
  if (groups[0].count == 4) {
    return mk(PokerHandRank.fourOfAKind, [groups[0].rank, groups[1].rank]);
  }
  if (groups[0].count == 3 && groups.length > 1 && groups[1].count == 2) {
    return mk(PokerHandRank.fullHouse, [groups[0].rank, groups[1].rank]);
  }
  if (flush) {
    return mk(PokerHandRank.flush, ranksDesc);
  }
  if (isStraight) {
    return mk(PokerHandRank.straight, [straight]);
  }
  if (groups[0].count == 3) {
    return mk(PokerHandRank.threeOfAKind,
        [groups[0].rank, groups[1].rank, groups[2].rank]);
  }
  if (groups[0].count == 2 && groups.length > 1 && groups[1].count == 2) {
    return mk(PokerHandRank.twoPair,
        [groups[0].rank, groups[1].rank, groups[2].rank]);
  }
  if (groups[0].count == 2) {
    return mk(PokerHandRank.onePair, [
      groups[0].rank,
      groups[1].rank,
      groups[2].rank,
      groups[3].rank,
    ]);
  }
  return mk(PokerHandRank.highCard, ranksDesc);
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
  bool shown = false; // добровольно показал карты после фолд-вины
}

/// Банк (основной или побочный) и места, претендующие на него.
class PokerSidePot {
  PokerSidePot(this.amount, this.eligible);
  int amount;
  List<int> eligible;
}

const int _headsUpHandsPerLevel = 8;
const int _threeMaxHandsPerLevel = 7;
const int _fourMaxHandsPerLevel = 6;
const int _fullTableHandsPerLevel = 8;

/// Сколько раздач держать текущие блайнды:
/// вдвоём 8, втроём 7, вчетвером 6, за большим столом 8.
int handsPerBlindLevel(int livePlayers) {
  final live = livePlayers < 2 ? 2 : livePlayers;
  if (live == 2) return _headsUpHandsPerLevel;
  if (live == 3) return _threeMaxHandsPerLevel;
  if (live == 4) return _fourMaxHandsPerLevel;
  return _fullTableHandsPerLevel;
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

  // Кэш-стол: партия = много раздач, пока фишки не соберутся у одного игрока.
  int handNumber = 1; // номер текущей раздачи, с 1
  int blindLevel = 0; // уровень блайндов, с 0
  int handsPerLevel = 12; // раздач на текущий уровень (заморожено до повышения)
  int handsThisLevel = 0; // завершённых раздач на текущем уровне
  int baseSmallBlind = 0; // стартовый малый блайнд
  int baseBigBlind = 0; // стартовый большой блайнд
  bool tableOver = false; // весь стол окончен (фишки у одного)
  bool handOver = false; // текущая раздача завершена, стол — нет

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
    g.baseSmallBlind = smallBlind;
    g.baseBigBlind = bigBlind;
    g.minRaise = bigBlind;
    g.handNumber = 1;
    g.blindLevel = 0;
    g.handsPerLevel = handsPerBlindLevel(n);
    g.handsThisLevel = 0;
    g.tableOver = false;
    g.handOver = false;
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
    _markHandOver();
  }

  /// Завершает текущую раздачу: статус «over» (гвард в [apply]) и [handOver].
  /// Если фишки остались максимум у одного игрока — весь стол окончен.
  void _markHandOver() {
    status = PokerStatus.over;
    handOver = true;
    var withChips = 0;
    for (final p in players) {
      if (p.chips > 0) withChips++;
    }
    tableOver = withChips <= 1;
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
    _markHandOver();
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

  int _livePlayerCount() {
    var n = 0;
    for (final p in players) {
      if (p.chips > 0) n++;
    }
    return n;
  }

  /// Первое место с фишками (>0), начиная с [start] по кругу; -1 если таких нет.
  int _nextSeatWithChips(int start) {
    final n = players.length;
    for (var k = 0; k < n; k++) {
      final i = ((start % n) + n + k) % n;
      if (players[i].chips > 0) return i;
    }
    return -1;
  }

  /// Начинает следующую раздачу за столом: сохраняет фишки, вращает дилера,
  /// при необходимости поднимает блайнды, тасует колоду и раздаёт карты.
  /// Выбывшие (0 фишек) остаются на местах, но пропускают раздачу.
  void startNextHand(Random rng) {
    if (!handOver || tableOver) {
      throw StateError(
          'poker: cannot start next hand (handOver=$handOver tableOver=$tableOver)');
    }

    final nextDealer = _nextSeatWithChips(dealerIndex + 1);
    if (nextDealer < 0) {
      throw StateError('poker: no players with chips');
    }
    dealerIndex = nextDealer;

    handNumber++;
    handsThisLevel++;
    // Уровень держится handsPerLevel раздач (HU 8, втроём 7, вчетвером 6, иначе 8).
    // Длину текущего уровня не ужимаем, если кто-то выбыл посреди него.
    if (handsPerLevel > 0 && handsThisLevel >= handsPerLevel) {
      blindLevel++;
      handsThisLevel = 0;
      handsPerLevel = handsPerBlindLevel(_livePlayerCount());
    }
    // Блайнды удваиваются на каждом уровне: BB = base << level, SB = BB/2.
    final bb = baseBigBlind << blindLevel;
    var sb = bb ~/ 2;
    if (sb < 1) sb = 1;
    bigBlind = bb;
    smallBlind = sb;
    minRaise = bb;

    _deck = _freshDeck()..shuffle(_rng);
    _deckPos = 0;
    community = [];
    sidePots = [];
    winners = [];
    winnerUserIds = [];
    pot = 0;
    currentBet = 0;

    final liveSeats = <int>[];
    for (final p in players) {
      p.bet = 0;
      p.totalBet = 0;
      p.allIn = false;
      p.hasActed = false;
      p.shown = false;
      p.hole = const [];
      if (p.chips > 0) {
        p.folded = false;
        liveSeats.add(p.seat);
      } else {
        p.folded = true;
      }
    }
    if (liveSeats.length < 2) {
      throw StateError('poker: need at least 2 players with chips');
    }

    if (liveSeats.length == 2) {
      sbIndex = dealerIndex;
      bbIndex = _nextSeatWithChips(dealerIndex + 1);
    } else {
      sbIndex = _nextSeatWithChips(dealerIndex + 1);
      bbIndex = _nextSeatWithChips(sbIndex + 1);
    }
    _postBet(sbIndex, smallBlind);
    _postBet(bbIndex, bigBlind);
    currentBet = bigBlind;

    for (var i = 0; i < players.length; i++) {
      if (players[i].folded) continue;
      players[i].hole = [_deal(), _deal()];
    }

    street = PokerStreet.preflop;
    status = PokerStatus.active;
    handOver = false;

    actingIndex = _firstLiveFrom(bbIndex + 1);
    _updatePot();
    // Если ходить некому (все живые уже all-in из-за блайндов) — докрутить борд.
    if (actingIndex < 0) {
      _advanceStreet();
    }
  }

  /// Добровольно показать карты после фолд-вины (пауза перед следующей раздачей).
  void showCards(int playerIndex) {
    if (playerIndex < 0 || playerIndex >= players.length) {
      throw StateError('poker: bad player index $playerIndex');
    }
    if (!handOver || tableOver) {
      throw StateError('poker: cannot show cards now');
    }
    if (street != PokerStreet.over) {
      throw StateError('poker: cards already shown at showdown');
    }
    final p = players[playerIndex];
    if (p.folded) {
      throw StateError('poker: folded player cannot show');
    }
    if (!winners.contains(playerIndex)) {
      throw StateError('poker: only winner can show');
    }
    p.shown = true;
  }

  /// Можно ли нажать «Показать карты» в паузе перед следующей раздачей.
  bool canShowCards(int playerIndex) {
    if (playerIndex < 0 || playerIndex >= players.length) return false;
    if (!handOver || tableOver || street != PokerStreet.over) return false;
    final p = players[playerIndex];
    if (p.folded || p.shown) return false;
    return winners.contains(playerIndex);
  }

  /// Лучшая 5-карточная комбинация игрока по его картам и борду (минимум 5 карт).
  PokerHandValue? bestHandFor(int playerIndex) {
    if (playerIndex < 0 || playerIndex >= players.length) return null;
    final p = players[playerIndex];
    final cards = <PlayingCard>[...p.hole, ...community];
    if (cards.length < 5) return null;
    return evaluateBestHand(cards);
  }

  /// Убирает игрока со стола (сдача/выход): обнуляет фишки и сбрасывает карты.
  /// Если это завершает текущую раздачу или весь стол — состояние обновится.
  void forfeitPlayer(int idx) {
    if (idx < 0 || idx >= players.length) return;

    if (status == PokerStatus.active) {
      // Обнуляем фишки ДО фолда, чтобы корректно посчитать tableOver.
      players[idx].chips = 0;
      players[idx].folded = true;
      players[idx].hasActed = true;

      final nf = _notFolded();
      if (nf.length == 1) {
        _awardUncontested(nf[0]);
        return;
      }
      if (actingIndex == idx) {
        actingIndex = _firstLiveFrom(idx + 1);
        if (actingIndex < 0 || _bettingComplete()) {
          _advanceStreet();
        }
      }
      return;
    }

    // Раздача не активна (пауза между раздачами) — просто убираем со стола.
    players[idx].chips = 0;
    players[idx].folded = true;
    final withChips = <int>[];
    for (var i = 0; i < players.length; i++) {
      if (players[i].chips > 0) withChips.add(i);
    }
    if (withChips.length <= 1) {
      tableOver = true;
      handOver = true;
      status = PokerStatus.over;
      if (withChips.length == 1) {
        winners = [withChips[0]];
        winnerUserIds = [players[withChips[0]].userId];
      }
    }
  }

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
      _awardUncontested(winner);
    }
  }
}

/// Есть ли у бота «сильная» карта: карманная пара, валет+, или уже пара+ по борду.
bool pokerBotHasCallStrength(PokerEngine g, PokerEnginePlayer p) {
  if (p.hole.length < 2) return false;
  final first = p.hole[0];
  final second = p.hole[1];
  if (first.rank.value == second.rank.value) return true;
  if (first.rank.value >= 11 || second.rank.value >= 11) return true;
  if (g.community.length >= 3) {
    final best = evaluateBestHand([...p.hole, ...g.community]);
    if (best.rank.index >= PokerHandRank.onePair.index) return true;
  }
  return false;
}

int pokerBotStrength(PokerEngine g, PokerEnginePlayer p) {
  if (g.community.length >= 3 && p.hole.length >= 2) {
    final best = evaluateBestHand([...p.hole, ...g.community]);
    final kick = best.tie.isEmpty ? 0 : best.tie.first;
    return best.rank.index * 16 + kick;
  }
  if (p.hole.length < 2) return 0;
  var a = p.hole[0].rank.value;
  var b = p.hole[1].rank.value;
  if (a < b) {
    final t = a;
    a = b;
    b = t;
  }
  var score = a + b;
  if (a == b) score += 42;
  if (p.hole[0].suit == p.hole[1].suit) score += 8;
  if (a - b <= 2) score += 6;
  return score;
}

/// Сила руки: чек/рейз, колл по силе, олл-ин только с сильной картой.
PokerAction pokerBotAction(PokerEngine g) {
  final idx = g.actingIndex;
  final legal = g.legalActions(idx);
  bool has(String a) => legal.contains(a);
  final p = g.players[idx];
  var callAmount = g.currentBet - p.bet;
  if (callAmount < 0) callAmount = 0;
  final rng = Random();
  final facingAllIn = callAmount >= p.chips ||
      g.players.any((other) =>
          other.seat != p.seat && !other.folded && other.allIn);
  final strength = pokerBotStrength(g, p);
  final wantRaise = strength >= 58 &&
      has(PokerActionType.raise) &&
      p.chips > g.bigBlind * 2;

  if (has(PokerActionType.check)) {
    if (wantRaise && rng.nextInt(3) != 0) {
      var to = g.currentBet + g.minRaise;
      if (strength >= 80 && p.chips > g.minRaise * 3) {
        to = g.currentBet + g.minRaise * 2;
      }
      if (to <= p.bet + p.chips) {
        return PokerAction(PokerActionType.raise, amount: to);
      }
    }
    return const PokerAction(PokerActionType.check);
  }
  final cheapCall = callAmount > 0 &&
      callAmount < p.chips &&
      callAmount <= p.chips ~/ 3 &&
      !facingAllIn;
  if (has(PokerActionType.call) && cheapCall && strength >= 24) {
    if (wantRaise && strength >= 70 && p.chips > g.bigBlind * 4) {
      final to = g.currentBet + g.minRaise;
      if (to <= p.bet + p.chips) {
        return PokerAction(PokerActionType.raise, amount: to);
      }
    }
    return const PokerAction(PokerActionType.call);
  }
  if ((has(PokerActionType.call) || has(PokerActionType.allIn)) &&
      callAmount > 0 &&
      pokerBotHasCallStrength(g, p)) {
    if (has(PokerActionType.call) && callAmount < p.chips) {
      return const PokerAction(PokerActionType.call);
    }
    if (has(PokerActionType.allIn)) {
      return const PokerAction(PokerActionType.allIn);
    }
    return const PokerAction(PokerActionType.call);
  }
  return const PokerAction(PokerActionType.fold);
}
