import 'package:multigames_client/games/durak/card.dart';

/// Сортировка руки как на сервере: не-козыри по масти/рангу, затем козыри.
int compareDurakHandCards(PlayingCard a, PlayingCard b, Suit trump) {
  final at = a.suit == trump ? 1 : 0;
  final bt = b.suit == trump ? 1 : 0;
  if (at != bt) return at.compareTo(bt);
  final s = a.suit.index.compareTo(b.suit.index);
  if (s != 0) return s;
  return a.rank.compareTo(b.rank);
}

void sortDurakHand(List<PlayingCard> hand, Suit trump) {
  hand.sort((a, b) => compareDurakHandCards(a, b, trump));
}

/// Младший козырь в руке — им определяется первый ход.
PlayingCard? lowestTrumpInHand(Iterable<PlayingCard> hand, Suit trump) {
  PlayingCard? best;
  for (final c in hand) {
    if (c.suit != trump) continue;
    if (best == null || c.rank.value < best.rank.value) best = c;
  }
  return best;
}

/// У кого младший козырь среди всех рук; null — козыря ни у кого нет.
int? lowestTrumpOwner(List<List<PlayingCard>> hands, Suit trump) {
  int? owner;
  PlayingCard? best;
  for (var p = 0; p < hands.length; p++) {
    final card = lowestTrumpInHand(hands[p], trump);
    if (card == null) continue;
    if (best == null || card.rank.value < best.rank.value) {
      best = card;
      owner = p;
    }
  }
  return owner;
}

/// Если козыря нет — игроки по кругу берут по одной с верха колоды
/// (открытый козырь в конце не трогаем), пока козырь не появится.
/// Возвращает, у кого младший козырь после добора.
int? drawUntilTrumpAppears({
  required List<List<PlayingCard>> hands,
  required List<PlayingCard> deck,
  required Suit trump,
}) {
  var owner = lowestTrumpOwner(hands, trump);
  if (owner != null) return owner;
  while (owner == null && deck.length > 1) {
    for (var p = 0; p < hands.length; p++) {
      if (deck.length <= 1) break;
      hands[p].add(deck.removeAt(0));
      owner = lowestTrumpOwner(hands, trump);
      if (owner != null) return owner;
    }
  }
  return owner;
}

/// Какие карты ещё не сели в веер во время стартовой раздачи.
///
/// Пока очередь [_pendingDealCards] не пуста — прячем только её. Если очередь
/// опустела, но слоты уже есть в локальном порядке, не подставляем всю руку
/// с сервера: иначе посаженные карты исчезают до конца FX.
Set<PlayingCard> durakOpeningDealPendingSet({
  required bool concealOpeningHand,
  required Set<PlayingCard> pendingDealCards,
  required List<PlayingCard>? handOrder,
  required Iterable<PlayingCard> incomingFanCards,
  required List<PlayingCard> serverHand,
}) {
  if (!concealOpeningHand) return pendingDealCards;
  if (pendingDealCards.isNotEmpty) return pendingDealCards;
  final seated = <PlayingCard>{
    ...?handOrder,
    ...incomingFanCards,
  };
  if (seated.isEmpty) return serverHand.toSet();
  final stillHidden = serverHand.toSet()..removeAll(seated);
  return stillHidden;
}

/// Первый кадр ещё без раздачи: веер не берёт всю руку с сервера.
///
/// Иначе в портрете (твин 380 ms) вспыхивают все карты, и только потом
/// летит колода.
bool durakOpeningDealConcealsFan({
  required bool prevDeckUninitialized,
  required bool shouldAnimateOpening,
}) =>
    prevDeckUninitialized && shouldAnimateOpening;

/// Карты добора, которых ещё нет в веере.
///
/// Уже лежащие карты не становятся «новыми», даже если [expect] раздут.
/// Иначе дама уходит из веера и летит рубашкой с колоды.
List<PlayingCard> durakFreshDealCards({
  required List<PlayingCard> serverHand,
  required List<PlayingCard> handOrder,
  required int expect,
}) {
  if (expect <= 0 || serverHand.isEmpty) return const [];
  final prev = handOrder.toSet();
  final fresh = <PlayingCard>[
    for (final c in serverHand)
      if (!prev.contains(c)) c,
  ];
  if (fresh.isEmpty) return const [];
  if (expect >= fresh.length) return List<PlayingCard>.of(fresh);
  return fresh.sublist(fresh.length - expect);
}

/// Слот в веере до полёта: карта уже в порядке, лицо прячет hidden.
///
/// Иначе foldCardIn целится в центр пустого веера, а вся рука вспыхивает
/// в onHandoff — веер «пропал и появился».
List<PlayingCard> durakReserveDealFanSlot({
  required List<PlayingCard> seated,
  required PlayingCard incoming,
  int Function(PlayingCard a, PlayingCard b)? compare,
}) {
  final next = [
    for (final c in seated)
      if (c != incoming) c,
    incoming,
  ];
  if (compare != null) next.sort(compare);
  return next;
}

/// После одной карты стартовой раздачи freeze веера не отпускаем.
bool durakKeepFanFreezeAfterDealBatch({
  required bool openingDeal,
  required bool manageBusy,
}) =>
    openingDeal || !manageBusy;

/// Свежая партия: руки полные (6+ добор козыря), стол пуст — крутить раздачу.
bool shouldAnimateDurakOpeningDeal({
  required bool isOver,
  required bool tableIsEmpty,
  required int bitoCount,
  required int myIndex,
  required int myHandLen,
  required List<int> handCounts,
  required int deckSize,
  required int deckCount,
}) {
  if (isOver || !tableIsEmpty || bitoCount > 0) return false;
  if (myIndex < 0 || myHandLen < 6) return false;
  final n = handCounts.length;
  if (n < 2) return false;
  const handSize = 6;
  var total = 0;
  var minH = 1 << 20;
  var maxH = 0;
  for (final c in handCounts) {
    if (c < handSize) return false;
    total += c;
    if (c < minH) minH = c;
    if (c > maxH) maxH = c;
  }
  if (maxH - minH > 1) return false;
  if (myHandLen != handCounts[myIndex]) return false;
  final expectedDeck = deckSize - total;
  return deckCount == expectedDeck && expectedDeck >= 0;
}

/// Карта ушла своим ходом — в веере её нет, пока не вернётся взятием.
///
/// Взятие/добор ([incomingToFan]) — наоборот, слот держим.
bool durakCardLeftHandForPlay({
  required bool markedPlayedAway,
  required bool optimisticAttack,
  required bool flyingToTable,
  required bool flyingFromHand,
  required bool incomingToFan,
  required bool inHandOrder,
}) {
  if (incomingToFan) return false;
  if (markedPlayedAway || optimisticAttack || flyingToTable) return true;
  // Полёт из руки: дырка, только если слота в order уже нет (ход).
  // Взятие держит карту в order — лицо прячет hiddenCards.
  return flyingFromHand && !inHandOrder;
}

/// Сыгранные карты не забываем, пока они снова не сядут в веер.
/// Иначе кадр со старой рукой снова вспыхнет лицом после хода.
Set<PlayingCard> durakRetainPlayedAway({
  required Iterable<PlayingCard> playedAway,
  required Iterable<PlayingCard> incomingFanCards,
  required Iterable<PlayingCard> pendingDealCards,
}) {
  return {
    for (final c in playedAway)
      if (!incomingFanCards.contains(c) && !pendingDealCards.contains(c)) c,
  };
}

/// Карты, которые нельзя снова класть в веер из снимка сервера.
Set<PlayingCard> durakCardsGoneFromFan({
  required Iterable<PlayingCard> playedAway,
  required Iterable<PlayingCard> optimisticAttacks,
  required Iterable<PlayingCard> flyingToTable,
  required Iterable<PlayingCard> flyingFromHand,
  required Iterable<PlayingCard> incomingFanCards,
  Iterable<PlayingCard>? handOrder,
}) {
  final incoming = incomingFanCards.toSet();
  final inFan = handOrder?.toSet();
  return {
    for (final c in playedAway)
      if (!incoming.contains(c)) c,
    ...optimisticAttacks,
    ...flyingToTable,
    for (final c in flyingFromHand)
      if (!incoming.contains(c) && (inFan == null || !inFan.contains(c))) c,
  };
}

/// Дырки веера: слот есть, лица нет (взятие/добор садится).
///
/// Свой ход сразу убирает карту — веер схлопывается вместе с полётом,
/// а не держит пустой слот до посадки.
Set<PlayingCard> durakFanHoleCards({
  required Iterable<PlayingCard> playedAway,
  required Iterable<PlayingCard> flyingFromHand,
  required Iterable<PlayingCard> incomingFanCards,
}) {
  final gone = playedAway.toSet();
  return {
    for (final c in flyingFromHand)
      if (!gone.contains(c)) c,
    ...incomingFanCards,
  };
}

/// Слот остаётся в веере как дырка, пока карта в локальном порядке.
bool durakFanKeepsHoleSlot({
  required bool inLocalOrder,
  required bool incomingToFan,
  required bool markedPlayedAway,
  required bool flyingFromHand,
}) {
  if (incomingToFan) return true;
  // Ход: слот сразу уходит, остальные карты едут одним твином.
  if (markedPlayedAway) return false;
  if (!inLocalOrder) return false;
  return flyingFromHand;
}

/// Порядок веера: дырки своего хода не выкидываем, с сервера их не дописываем.
List<PlayingCard> durakOrderedHandSlots({
  required List<PlayingCard>? prevOrder,
  required List<PlayingCard> serverHand,
  required Set<PlayingCard> pendingDeal,
  required Set<PlayingCard> leavingHand,
  required Set<PlayingCard> holeCards,
  int Function(PlayingCard a, PlayingCard b)? compareNew,
}) {
  if (prevOrder == null) {
    return [
      for (final c in serverHand)
        if (!leavingHand.contains(c) && !pendingDeal.contains(c)) c,
    ];
  }
  final remain = serverHand.toSet()..removeAll(leavingHand);
  final out = <PlayingCard>[];
  for (final c in prevOrder) {
    if (pendingDeal.contains(c)) continue;
    if (remain.remove(c)) {
      out.add(c);
    } else if (holeCards.contains(c)) {
      out.add(c);
    }
  }
  if (remain.isEmpty) return out;
  final added = [
    for (final c in remain)
      if (!pendingDeal.contains(c)) c,
  ];
  if (compareNew != null) {
    added.sort(compareNew);
  }
  out.addAll(added);
  return out;
}

/// После своего хода: дырку в prev оставляем, с сервера уходящую не дописываем.
List<PlayingCard> durakMergeHandOrderAfterMove({
  required List<PlayingCard> prevOrder,
  required List<PlayingCard> serverHand,
  required Set<PlayingCard> pendingDeal,
  required Set<PlayingCard> leavingHand,
}) {
  final handSet = serverHand.toSet();
  final next = <PlayingCard>[
    for (final c in prevOrder)
      if (!pendingDeal.contains(c) &&
          (handSet.contains(c) || leavingHand.contains(c)))
        c,
  ];
  for (final c in serverHand) {
    if (pendingDeal.contains(c) || leavingHand.contains(c)) continue;
    if (!next.contains(c)) next.add(c);
  }
  return next;
}
